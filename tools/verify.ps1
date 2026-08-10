#requires -Version 5.1
<#
.SYNOPSIS
  tools/verify.sh の Windows PowerShell 5.1 版。
  決定論的な検証項目(analyze/test/build等)をまとめて実行し、結果を JSON 1つで
  標準出力へ返す。検証エージェント(verifier)が `flutter analyze`/`flutter test` の
  生出力(1回7k〜13k文字、以後の全リクエストに課金され続ける)を直接読まずに済むよう
  にすることが目的。詳細ログは .claude/verify_logs/<timestamp>_<項目名>.log へ書く。

  夜間自動実行(T5-A10 tools/night_loop.ps1)が PowerShell 前提のため、Windows では
  こちらが本命の実行系。tools/verify.sh(Bash版)と完全に同じ8項目・同じJSONスキーマを
  出力する。jq には依存せず、PowerShell 標準の ConvertTo-Json だけで組み立てる。

  使い方: powershell -File tools/verify.ps1 [-Edition personal|public]

  仕様の正本: docs/android_release/検証強化設計.md §3-2
  対応する Bash 用スクリプト: tools/verify.sh(同一ロジック)
#>

param(
    [string]$Edition = "public"
)

# 標準出力にJSON以外の文字が混じらないよう、進捗メッセージは全てstderrへ出す。
# また、Get-Content/Out-File とプロセス出力の文字化け(Japanese文字を含むため)を
# 防ぐため、コンソールの出力エンコーディングをUTF-8に固定する。
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = "Continue"

function Write-Progress2([string]$Message) {
    [Console]::Error.WriteLine("[verify.ps1] $Message")
}

Write-Progress2 "edition=$Edition"

# 注: 現時点では lib/main_public.dart(公開版エントリポイント、E-1未着手)が
# 存在しないため、edition による分岐は build_apk_release のスキップ判定
# (main_public.dart有無の確認)以外に無い。将来 main_public.dart 追加時に拡張する。

# --- 準備 -------------------------------------------------------------
$RepoRootRaw = (& git rev-parse --show-toplevel 2>$null)
if (-not $RepoRootRaw) {
    Write-Output '{"ok":false,"error":"repo_root_not_found","message":"gitリポジトリのルートが取得できませんでした。"}'
    exit 1
}
Set-Location -Path $RepoRootRaw.Trim()
$RepoRoot = (Get-Location).Path

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $RepoRoot ".claude\verify_logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Get-LogPath([string]$Name) {
    return Join-Path $LogDir "${Timestamp}_${Name}.log"
}

function Get-RelativePath([string]$FullPath) {
    $rel = $FullPath.Substring($RepoRoot.Length)
    $rel = $rel.TrimStart('\', '/')
    return $rel.Replace('\', '/')
}

# 外部コマンド(flutter/dart)を実行し、stdout+stderrを1つのログファイルへ書き出す。
# ネイティブexeに対する `2>&1` はPowerShell 5.1ではエラーレコード化され $? を壊すため使わず、
# Start-Process の -RedirectStandardOutput/-RedirectStandardError でファイルへ直接吐かせる。
function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$LogPath,
        [int]$TimeoutMs = 0
    )

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()
    $timedOut = $false
    $exitCode = -1

    try {
        $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
        # PowerShell 5.1 の既知の癖: Start-Process の戻り値は Handle に一度アクセスして
        # おかないと WaitForExit/ExitCode が正しく機能しないことがある。
        $null = $proc.Handle

        if ($TimeoutMs -gt 0) {
            $finished = $proc.WaitForExit($TimeoutMs)
            if (-not $finished) {
                $timedOut = $true
                try {
                    # .NET Framework の Process.Kill() は子プロセスを道連れにしないため、
                    # プロセスツリーごと確実に止める目的で taskkill /T を使う。
                    & taskkill /PID $proc.Id /T /F 2>$null | Out-Null
                } catch {}
                try { $proc.WaitForExit(5000) } catch {}
            } else {
                $exitCode = $proc.ExitCode
            }
        } else {
            $proc.WaitForExit()
            $exitCode = $proc.ExitCode
        }
    } catch {
        "コマンド実行エラー: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Encoding utf8
        Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue
        return @{ ExitCode = -1; TimedOut = $false }
    }

    $content = New-Object System.Collections.Generic.List[string]
    if (Test-Path $stdoutFile) {
        $t = Get-Content -Raw -Encoding UTF8 -Path $stdoutFile -ErrorAction SilentlyContinue
        if ($t) { $content.Add($t) }
    }
    if (Test-Path $stderrFile) {
        $t = Get-Content -Raw -Encoding UTF8 -Path $stderrFile -ErrorAction SilentlyContinue
        if ($t) { $content.Add($t) }
    }
    ($content -join "`n") | Out-File -FilePath $LogPath -Encoding utf8
    Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue

    return @{ ExitCode = $exitCode; TimedOut = $timedOut }
}

function Get-ErrorSummary([string]$Text) {
    if (-not $Text) { return "" }
    $lines = $Text -split "`r?`n" | Where-Object { $_ -match "(?i)(error|failure|exception)" }
    $last5 = $lines | Select-Object -Last 5
    return ($last5 -join " ")
}

# コミット前の全変更ファイル(追跡ファイルの差分 + 新規未追跡ファイル)
$diffFiles = @(& git diff --name-only HEAD 2>$null)
$untrackedFiles = @(& git ls-files --others --exclude-standard 2>$null)
$ChangedFiles = @($diffFiles + $untrackedFiles) | Where-Object { $_ } | Sort-Object -Unique

# --- 各検査項目 -------------------------------------------------------------

# 1. analyze: 既存issue件数(.claude/analyze_baseline.txt、BOM付きの可能性あり)と比較
function Invoke-CheckAnalyze {
    $log = Get-LogPath "analyze"
    Invoke-LoggedCommand -FilePath "flutter" -ArgumentList @("analyze") -LogPath $log | Out-Null
    $logText = ""
    if (Test-Path $log) { $logText = Get-Content -Raw -Encoding UTF8 -Path $log -ErrorAction SilentlyContinue }
    if (-not $logText) { $logText = "" }

    $baselinePath = Join-Path $RepoRoot ".claude\analyze_baseline.txt"
    $baselineRaw = ""
    if (Test-Path $baselinePath) {
        $baselineRaw = Get-Content -Raw -Encoding UTF8 -Path $baselinePath -ErrorAction SilentlyContinue
    }
    $baselineDigits = ($baselineRaw -replace '[^0-9]', '')
    $baseline = 0
    if ($baselineDigits) { $baseline = [int]$baselineDigits }

    $current = 0
    if ($logText -notmatch "No issues found") {
        $m = [regex]::Matches($logText, '(\d+) issues? found')
        if ($m.Count -gt 0) {
            $current = [int]$m[$m.Count - 1].Groups[1].Value
        }
    }

    $ok = ($current -le $baseline)
    if ($ok) {
        return [ordered]@{ ok = $true; baseline = $baseline; current = $current }
    } else {
        return [ordered]@{ ok = $false; baseline = $baseline; current = $current; log = $log }
    }
}

# 2. test: 全パスを確認
function Invoke-CheckTest {
    $log = Get-LogPath "test"
    $result = Invoke-LoggedCommand -FilePath "flutter" -ArgumentList @("test") -LogPath $log
    $logText = ""
    if (Test-Path $log) { $logText = Get-Content -Raw -Encoding UTF8 -Path $log -ErrorAction SilentlyContinue }
    if (-not $logText) { $logText = "" }

    $passed = 0
    $failed = 0
    $m = [regex]::Matches($logText, '\+\d+(?:\s+[~-]\d+)*:')
    if ($m.Count -gt 0) {
        $lastLine = $m[$m.Count - 1].Value
        if ($lastLine -match '\+(\d+)') { $passed = [int]$Matches[1] }
        if ($lastLine -match '-(\d+)')  { $failed = [int]$Matches[1] }
    }

    $ok = ($result.ExitCode -eq 0) -and ($failed -eq 0) -and (-not $result.TimedOut)
    if ($ok) {
        return [ordered]@{ ok = $true; passed = $passed; failed = $failed }
    } else {
        return [ordered]@{ ok = $false; passed = $passed; failed = $failed; log = $log }
    }
}

# 3. test_coverage_delta: 変更したlib/ファイルに対応するテストファイルの有無(warningのみ、failにしない)
function Invoke-CheckCoverageDelta {
    $missing = New-Object System.Collections.Generic.List[string]
    $testDir = Join-Path $RepoRoot "test"

    foreach ($f in $ChangedFiles) {
        if (-not $f) { continue }
        if ($f -notlike "lib/*.dart") { continue }
        if ($f -like "*.g.dart") { continue }
        $fullPath = Join-Path $RepoRoot $f
        if (-not (Test-Path $fullPath)) { continue }
        $base = [System.IO.Path]::GetFileNameWithoutExtension($f)
        $found = $null
        if (Test-Path $testDir) {
            $found = Get-ChildItem -Path $testDir -Recurse -Filter "${base}_test.dart" -ErrorAction SilentlyContinue
        }
        if (-not $found) {
            $missing.Add($f)
        }
    }

    if ($missing.Count -eq 0) {
        return [ordered]@{ ok = $true }
    } else {
        $msg = ($missing | ForEach-Object { "$_ に対応テストなし" }) -join "; "
        return [ordered]@{ ok = $true; warning = $msg }
    }
}

# Android SDK が検出できるかどうかを判定する。
# ANDROID_HOME/ANDROID_SDK_ROOT が実在ディレクトリを指していれば有りとみなす。
# どちらも無ければ flutter doctor の出力で判定する(明示的な未検出メッセージが
# あれば無し、Android toolchain にチェックが付いていれば有り、それ以外は安全側で無し扱い)。
function Test-AndroidSdkAvailable {
    if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) { return $true }
    if ($env:ANDROID_SDK_ROOT -and (Test-Path $env:ANDROID_SDK_ROOT)) { return $true }

    $doctorLog = Join-Path $LogDir "${Timestamp}_doctor_check.log"
    Invoke-LoggedCommand -FilePath "flutter" -ArgumentList @("doctor") -LogPath $doctorLog | Out-Null
    $doctorText = ""
    if (Test-Path $doctorLog) { $doctorText = Get-Content -Raw -Encoding UTF8 -Path $doctorLog -ErrorAction SilentlyContinue }
    Remove-Item $doctorLog -ErrorAction SilentlyContinue

    if (-not $doctorText) { return $false }
    if ($doctorText -match "Unable to locate Android SDK") { return $false }
    if ($doctorText -match "\[.\] Android toolchain") { return $true }
    return $false
}

# 4. build_apk_release: lib/main_public.dart 未作成、または Android SDK 未検出の場合は
#    「環境・前提が未整備」としてスキップ扱い(ok:true, skipped:true, note)にする。
#    黙って通さないよう skipped/note を必ず含める。それ以外の理由での失敗は従来どおり fail。
function Invoke-CheckBuildApkRelease {
    $target = "lib/main_public.dart"
    if (-not (Test-Path (Join-Path $RepoRoot $target))) {
        return [ordered]@{ ok = $true; skipped = $true; note = "lib/main_public.dart 未作成のためスキップ" }
    }

    if (-not (Test-AndroidSdkAvailable)) {
        return [ordered]@{ ok = $true; skipped = $true; note = "Android SDK 未検出のためスキップ" }
    }

    $log = Get-LogPath "build_apk_release"
    $result = Invoke-LoggedCommand -FilePath "flutter" -ArgumentList @("build", "apk", "--release", "-t", $target) -LogPath $log

    if (($result.ExitCode -eq 0) -and (-not $result.TimedOut)) {
        return [ordered]@{ ok = $true }
    } else {
        $logText = ""
        if (Test-Path $log) { $logText = Get-Content -Raw -Encoding UTF8 -Path $log -ErrorAction SilentlyContinue }
        $summary = Get-ErrorSummary -Text $logText
        return [ordered]@{ ok = $false; summary = $summary; log = $log }
    }
}

# 5. build_web_release
function Invoke-CheckBuildWebRelease {
    $log = Get-LogPath "build_web_release"
    $result = Invoke-LoggedCommand -FilePath "flutter" -ArgumentList @("build", "web", "--release") -LogPath $log

    if (($result.ExitCode -eq 0) -and (-not $result.TimedOut)) {
        return [ordered]@{ ok = $true }
    } else {
        $logText = ""
        if (Test-Path $log) { $logText = Get-Content -Raw -Encoding UTF8 -Path $log -ErrorAction SilentlyContinue }
        $summary = Get-ErrorSummary -Text $logText
        return [ordered]@{ ok = $false; summary = $summary; log = $log }
    }
}

# 6. golden: goldenテストが0件なら差分ゼロ扱い。ベースラインはWindows生成(T5-A8)。
function Invoke-CheckGolden {
    $testDir = Join-Path $RepoRoot "test"
    $goldenFiles = @()
    if (Test-Path $testDir) {
        # matchesGoldenFile( を含むだけのヘルパー(main()を持たない)を除外する。
        # golden_test_helper.dart を flutter test に渡すと「Undefined name 'main'」で必ず失敗するため。
        $goldenFiles = Get-ChildItem -Path $testDir -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Where-Object {
            $t = Get-Content -Raw -Encoding UTF8 -Path $_.FullName -ErrorAction SilentlyContinue
            $t -and ($t -match [regex]::Escape("matchesGoldenFile(")) -and
                ($t -match '(?m)^\s*(?:void|Future<void>)\s+main\s*\(')
        } | ForEach-Object { Get-RelativePath $_.FullName }
    }

    if (-not $goldenFiles -or $goldenFiles.Count -eq 0) {
        return [ordered]@{ ok = $true; diff_count = 0 }
    }

    $log = Get-LogPath "golden"
    $argList = @("test") + $goldenFiles
    $result = Invoke-LoggedCommand -FilePath "flutter" -ArgumentList $argList -LogPath $log
    $logText = ""
    if (Test-Path $log) { $logText = Get-Content -Raw -Encoding UTF8 -Path $log -ErrorAction SilentlyContinue }
    if (-not $logText) { $logText = "" }

    $diffCount = 0
    $m = [regex]::Matches($logText, '\+\d+(?:\s+[~-]\d+)*:')
    if ($m.Count -gt 0) {
        $lastLine = $m[$m.Count - 1].Value
        if ($lastLine -match '-(\d+)')  { $diffCount = [int]$Matches[1] }
    }

    $ok = ($result.ExitCode -eq 0) -and ($diffCount -eq 0) -and (-not $result.TimedOut)
    if ($ok) {
        return [ordered]@{ ok = $true; diff_count = $diffCount }
    } else {
        return [ordered]@{ ok = $false; diff_count = $diffCount; log = $log }
    }
}

# 7. codegen_clean: build_runner再生成後にlib/**/*.g.dartへ差分が出ないか。
#    git checkout等は使わず、生成物(*.g.dart)だけをバックアップ→復元することで、
#    作業ツリー上の他の未コミット変更(WIP)を一切壊さずに済ませる。
#    改行コード(CRLF/LF)だけの差分は「意味的な差分なし」として無視する
#    (core.autocrlf=true環境でCRLF/LF差だけの誤検知を防ぐ)。
function Invoke-CheckCodegenClean {
    $log = Get-LogPath "codegen_clean"
    $diffLog = $log -replace '\.log$', '_diff.log'
    $libDir = Join-Path $RepoRoot "lib"

    $backupDir = Join-Path $env:TEMP ("verify_ps_" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $backupDir | Out-Null

    $genFilesBefore = @(Get-ChildItem -Path $libDir -Recurse -Filter "*.g.dart" -ErrorAction SilentlyContinue |
        ForEach-Object { Get-RelativePath $_.FullName } | Sort-Object)

    foreach ($f in $genFilesBefore) {
        $destPath = Join-Path $backupDir $f.Replace('/', '\')
        New-Item -ItemType Directory -Force -Path (Split-Path $destPath) | Out-Null
        Copy-Item -Path (Join-Path $RepoRoot $f) -Destination $destPath -Force
    }

    # build_runner 2.15.1 で --delete-conflicting-outputs は廃止(指定すると警告して無視)。
    # また、clean を挟まないとインクリメンタルビルドが .g.dart の手編集ドリフトを検出しない。
    # --force-jit: path_provider_foundation→objective_c の build hook により
    #              Dart 3.10 系では builders の AOT コンパイルが失敗するため JIT を強制する。
    # タイムアウト600秒: 依存バージョン不整合時にアナライザが復帰不能な再帰に入る事故への保険
    #                    (rules/lessons_archive.md L116)。実測の全再生成時間は約40秒。
    $cleanLog = "$log.clean.tmp"
    $buildLog = "$log.build.tmp"
    Invoke-LoggedCommand -FilePath "dart" -ArgumentList @("run", "build_runner", "clean") -LogPath $cleanLog -TimeoutMs 120000 | Out-Null
    $buildResult = Invoke-LoggedCommand -FilePath "dart" -ArgumentList @("run", "build_runner", "build", "--force-jit") -LogPath $buildLog -TimeoutMs 600000

    $cleanText = ""
    $buildText = ""
    if (Test-Path $cleanLog) { $cleanText = Get-Content -Raw -Encoding UTF8 -Path $cleanLog -ErrorAction SilentlyContinue }
    if (Test-Path $buildLog) { $buildText = Get-Content -Raw -Encoding UTF8 -Path $buildLog -ErrorAction SilentlyContinue }
    (@($cleanText, $buildText) -join "`n") | Out-File -FilePath $log -Encoding utf8
    Remove-Item $cleanLog, $buildLog -ErrorAction SilentlyContinue

    $genFilesAfter = @(Get-ChildItem -Path $libDir -Recurse -Filter "*.g.dart" -ErrorAction SilentlyContinue |
        ForEach-Object { Get-RelativePath $_.FullName } | Sort-Object)

    $diffFound = $false
    $diffLines = New-Object System.Collections.Generic.List[string]

    foreach ($f in $genFilesBefore) {
        $curPath = Join-Path $RepoRoot $f
        $backupPath = Join-Path $backupDir $f.Replace('/', '\')
        if (-not (Test-Path $curPath)) {
            $diffFound = $true
            $diffLines.Add("[削除] $f")
            continue
        }
        $backupContent = (Get-Content -Raw -Encoding UTF8 -Path $backupPath) -replace "`r", ""
        $curContent = (Get-Content -Raw -Encoding UTF8 -Path $curPath) -replace "`r", ""
        if ($backupContent -ne $curContent) {
            $diffFound = $true
            $diffLines.Add("[変更] $f")
            $backupLines = $backupContent -split "`n"
            $curLines = $curContent -split "`n"
            $cmp = Compare-Object -ReferenceObject $backupLines -DifferenceObject $curLines -SyncWindow 0 -ErrorAction SilentlyContinue
            foreach ($c in $cmp) {
                $prefix = "+"
                if ($c.SideIndicator -eq "<=") { $prefix = "-" }
                $diffLines.Add("$prefix $($c.InputObject)")
            }
        }
    }
    foreach ($f in $genFilesAfter) {
        $backupPath = Join-Path $backupDir $f.Replace('/', '\')
        if (-not (Test-Path $backupPath)) {
            $diffFound = $true
            $diffLines.Add("[新規] $f")
        }
    }

    # 復元: build_runner実行前の状態へ厳密に戻す
    foreach ($f in $genFilesAfter) {
        $backupPath = Join-Path $backupDir $f.Replace('/', '\')
        if (-not (Test-Path $backupPath)) {
            Remove-Item (Join-Path $RepoRoot $f) -Force -ErrorAction SilentlyContinue
        }
    }
    foreach ($f in $genFilesBefore) {
        $destPath = Join-Path $RepoRoot $f
        New-Item -ItemType Directory -Force -Path (Split-Path $destPath) | Out-Null
        Copy-Item -Path (Join-Path $backupDir $f.Replace('/', '\')) -Destination $destPath -Force
    }
    Remove-Item -Recurse -Force $backupDir -ErrorAction SilentlyContinue

    $ok = $true
    $timedOut = $false
    if ($buildResult.TimedOut) {
        $ok = $false
        $timedOut = $true
        $diffLines.Add("[build_runnerタイムアウト] 600秒以内に完了しませんでした。analyzerとDart SDKのバージョン不整合の可能性があります(rules/lessons_archive.md L116参照)。pubspec.lockのanalyzerバージョンを確認してください。")
    } elseif ($buildResult.ExitCode -ne 0) {
        $ok = $false
        $diffLines.Add("[build_runner失敗] exit=$($buildResult.ExitCode)")
    }
    if ($diffFound) { $ok = $false }

    ($diffLines -join "`n") | Out-File -FilePath $diffLog -Encoding utf8

    if ($ok) {
        return [ordered]@{ ok = $true }
    } elseif ($timedOut) {
        return [ordered]@{ ok = $false; reason = "timeout"; log = $diffLog }
    } else {
        return [ordered]@{ ok = $false; log = $diffLog }
    }
}

# 8. secret_scan: ステージ済み差分(git diff --cached)のみを対象。
#    'gemini_api_key' はSharedPreferencesのキー名として正規に多数出現するため、
#    キー名そのものではなく実際の秘密情報の"値"の形を検出する。
function Invoke-CheckSecretScan {
    $log = Get-LogPath "secret_scan"

    $stagedLines = @(& git diff --cached 2>$null)
    $addedLines = $stagedLines | Where-Object { $_ -match '^\+[^+]' }

    $hit = $false
    $sections = New-Object System.Collections.Generic.List[string]

    $aizaHits = New-Object System.Collections.Generic.List[string]
    foreach ($line in $addedLines) {
        $m = [regex]::Matches($line, 'AIza[0-9A-Za-z_-]{35}')
        foreach ($mm in $m) { $aizaHits.Add($mm.Value) }
    }
    if ($aizaHits.Count -gt 0) {
        $hit = $true
        $sections.Add("[Google/Gemini APIキー形式(AIza...)を検出]")
        foreach ($h in $aizaHits) { $sections.Add($h) }
    }

    $genericPattern = '(?i)(api[_-]?key|secret|token|password)[''"]?\s*[:=]\s*[''"][A-Za-z0-9+/=_-]{20,}[''"]'
    $genericHits = New-Object System.Collections.Generic.List[string]
    foreach ($line in $addedLines) {
        if ($line -match "gemini_api_key") { continue }
        if ($line -match $genericPattern) {
            $genericHits.Add($line)
        }
    }
    if ($genericHits.Count -gt 0) {
        $hit = $true
        $sections.Add("[秘密情報らしきリテラル代入を検出]")
        foreach ($h in $genericHits) { $sections.Add($h) }
    }

    ($sections -join "`n") | Out-File -FilePath $log -Encoding utf8

    if (-not $hit) {
        return [ordered]@{ ok = $true }
    } else {
        return [ordered]@{ ok = $false; log = $log }
    }
}

# --- 実行 -------------------------------------------------------------------
# 軽い検査から順に実行する(重いビルドは最後)。
Write-Progress2 "analyze 実行中..."
$resultAnalyze = Invoke-CheckAnalyze
Write-Progress2 "test 実行中..."
$resultTest = Invoke-CheckTest
Write-Progress2 "test_coverage_delta 判定中..."
$resultCoverage = Invoke-CheckCoverageDelta
Write-Progress2 "secret_scan 実行中..."
$resultSecret = Invoke-CheckSecretScan
Write-Progress2 "codegen_clean 実行中..."
$resultCodegen = Invoke-CheckCodegenClean
Write-Progress2 "golden 実行中..."
$resultGolden = Invoke-CheckGolden
Write-Progress2 "build_web_release 実行中..."
$resultWeb = Invoke-CheckBuildWebRelease
Write-Progress2 "build_apk_release 判定中..."
$resultApk = Invoke-CheckBuildApkRelease

$checks = [ordered]@{
    analyze              = $resultAnalyze
    test                 = $resultTest
    test_coverage_delta  = $resultCoverage
    build_apk_release    = $resultApk
    build_web_release    = $resultWeb
    golden               = $resultGolden
    codegen_clean        = $resultCodegen
    secret_scan          = $resultSecret
}

$overallOk = $resultAnalyze.ok -and $resultTest.ok -and $resultApk.ok -and `
    $resultWeb.ok -and $resultGolden.ok -and $resultCodegen.ok -and $resultSecret.ok

$final = [ordered]@{
    ok     = [bool]$overallOk
    checks = $checks
}

Write-Progress2 "完了。JSONを出力します。"
$final | ConvertTo-Json -Depth 10
