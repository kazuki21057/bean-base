#requires -Version 5.1
<#
.SYNOPSIS
  受け入れスクリプト: T5-A68
.DESCRIPTION
  完了条件(親からの委譲指示より):
  「docs/failure_playbook.md のFP-01〜FP-07の各ルールが、tools/failure_playbook.ps1・
  tools/night_loop.ps1 への実装(T5-A61〜A66)どおりに実地で動くことを、意図的な障害注入に
  よって確認する。7パターン全てで検知・自動対処・エスカレーション判定結果が設計書の記載と
  一致することを実地確認できること」

  検証する7パターン(すべて docs/failure_playbook.md §3 の記載どおりの判定基準を使う):
    FP-01-FILELOCK   : フォールバックログ(シグネチャB)を模擬生成 → severity=warn/
                        action=none/result=warned(kill等の自動対処はしない)
    FP-02-BOM        : 追跡外のBOM無し .ps1 を新規作成 → -Mode Check で自動修復
                        (action=repaired/result=ok)
    FP-03-EMULATOR   : ANDROID_SDK_ROOTを子プロセスのみ差し替えてadb.exe不在を模擬
                        (シグネチャA) → 有人時のため自動再起動せず action=none/result=warned
    FP-04-PERMISSION : 隔離した一時ディレクトリのダミーjsonlに拒否文字列(シグネチャA)を
                        仕込む → 即escalate(action=none/result=escalate)
    FP-05-HANG-AGY   : .claude/agy_logs/ledger.tsv に同一task_idでexit_code=11の行を2件
                        注入 → 1件目はresult=ok(記録のみ)、2件目(2回連続)はresult=escalate
    FP-06-SILENTSTALL: .claude/night_outcomes.log に同一outcomeを3行追記 → 自動対処なし、
                        result=escalate
    FP-07-MISSINGBIN : 子プロセスのみのPATHからadb.exeのディレクトリを除去 → exit1(warn)、
                        result=warned(abortにはならない)

  実装方針: tools/failure_playbook.ps1 を実際に子プロセスとして起動し(tools/lib/loop_io.ps1
  の Invoke-ProcessWithTimeout を使用)、本物の検知・対処ロジックをそのまま検証する
  (ロジックの再実装・二重化はしない)。環境変数(ANDROID_SDK_ROOT/PATH)の差し替えは
  Invoke-ProcessWithTimeout が子プロセス起動時に現在の環境を引き継ぐ性質を利用し、
  この受け入れスクリプト自身のプロセス内でのみ一時的に上書き・即座に復元する
  (他プロセス・他セッションには一切影響しない)。

  リポジトリの実ファイルへ触れる箇所と復元方法:
    - .claude/night_logs/wrapper.fallback-<guid>.log … 新規作成のみ。終了後に削除する。
    - tools/_t5a68_dummy_bom.ps1(追跡外) … 新規作成のみ。終了後に削除する
      (自動修復でBOMが付与されても削除するため、リポジトリには残らない)。
    - .claude/night_outcomes.log … 追記前の内容をバイト列で退避し、終了後に完全復元する。
    - .claude/agy_logs/ledger.tsv … 追記前の内容をバイト列で退避し、終了後に完全復元する。
  FP-04用のダミーjsonlは $env:TEMP 配下にのみ作成し、リポジトリには一切触れない。
  本番Sheets/Drive/GASへはアクセスしない。

  仕様の正本: docs/failure_playbook.md §3(FP-01〜FP-07の各節)。
  実装体裁の参考: tools/acceptance/t5_a69_check.ps1・t5_a90_check.ps1 と同じ体裁
  (BOM付きUTF-8、進捗はstderr、stdout最終行に1行JSON)。
#>

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = "Continue"

function Write-AcceptanceLog([string]$Message) {
    [Console]::Error.WriteLine("[acceptance] $Message")
}

function Get-LastJsonLine([string]$StdOut) {
    $lines = @($StdOut -split "`r?`n" | Where-Object { $_ -and $_.Trim().StartsWith('{') })
    if ($lines.Count -eq 0) { return $null }
    try {
        return ($lines[-1] | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        return $null
    }
}

$taskId = "T5-A68"
$checks = New-Object System.Collections.Generic.List[object]
$originalLocation = (Get-Location).Path

# クリーンアップは finally で必ず実行する(LIFOで積む)。
$cleanupActions = New-Object System.Collections.Generic.List[scriptblock]
function Add-Cleanup([scriptblock]$Action) {
    $script:cleanupActions.Add($Action) | Out-Null
}
function Invoke-AllCleanups {
    for ($i = $script:cleanupActions.Count - 1; $i -ge 0; $i--) {
        try { & $script:cleanupActions[$i] } catch {
            Write-AcceptanceLog "クリーンアップ処理でエラーが発生しましたが続行します: $($_.Exception.Message)"
        }
    }
}

try {
    Write-AcceptanceLog "リポジトリルートを検出中..."
    $repoRootRaw = (& git rev-parse --show-toplevel 2>$null)
    if (-not $repoRootRaw) {
        $result = [ordered]@{
            task = $taskId; ok = $false; skipped = $true
            reason = "gitリポジトリルートが取得できませんでした"; checks = @()
        }
        Write-Output ($result | ConvertTo-Json -Compress -Depth 6)
        exit 2
    }
    $repoRoot = (Resolve-Path $repoRootRaw.Trim()).Path
    $fpPath = Join-Path $repoRoot "tools\failure_playbook.ps1"
    $loopIoPath = Join-Path $repoRoot "tools\lib\loop_io.ps1"
    foreach ($p in @($fpPath, $loopIoPath)) {
        if (-not (Test-Path $p)) {
            $result = [ordered]@{
                task = $taskId; ok = $false; skipped = $true
                reason = "必要なファイルが見つかりません: $p"; checks = @()
            }
            Write-Output ($result | ConvertTo-Json -Compress -Depth 6)
            exit 2
        }
    }

    Write-AcceptanceLog "tools/lib/loop_io.ps1 を読み込み中(dot-source)..."
    . $loopIoPath

    $claudeDir = Join-Path $repoRoot ".claude"
    $nightLogsDir = Join-Path $claudeDir "night_logs"
    $outcomesLogPath = Join-Path $claudeDir "night_outcomes.log"
    $ledgerPath = Join-Path $claudeDir "agy_logs\ledger.tsv"
    $toolsDir = Join-Path $repoRoot "tools"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false

    # ========================================================================
    # 準備1: FP-01-FILELOCK シグネチャB(フォールバックログの存在)を模擬生成
    # ========================================================================
    Write-AcceptanceLog "FP-01用: フォールバックログのダミーを生成中..."
    if (-not (Test-Path $nightLogsDir)) { New-Item -ItemType Directory -Path $nightLogsDir -Force | Out-Null }
    $fp01FileName = "wrapper.fallback-t5a68test" + [guid]::NewGuid().ToString("N").Substring(0, 8) + ".log"
    $fp01FilePath = Join-Path $nightLogsDir $fp01FileName
    "T5-A68 acceptance test dummy fallback log" | Out-File -FilePath $fp01FilePath -Encoding utf8
    Add-Cleanup { if (Test-Path $fp01FilePath) { Remove-Item -Path $fp01FilePath -Force -ErrorAction SilentlyContinue } }

    # ========================================================================
    # 準備2: FP-06-SILENTSTALL(同一outcomeが3回連続)を模擬生成
    # ========================================================================
    Write-AcceptanceLog "FP-06用: night_outcomes.log を退避し、同一outcomeを3行追記中..."
    $outcomesExisted = Test-Path $outcomesLogPath
    $outcomesBackupBytes = if ($outcomesExisted) { [System.IO.File]::ReadAllBytes($outcomesLogPath) } else { $null }
    Add-Cleanup {
        if ($outcomesExisted) {
            [System.IO.File]::WriteAllBytes($outcomesLogPath, $outcomesBackupBytes)
        } elseif (Test-Path $outcomesLogPath) {
            Remove-Item -Path $outcomesLogPath -Force -ErrorAction SilentlyContinue
        }
    }
    $fp06Outcome = "error_t5a68_test_injection"
    for ($i = 1; $i -le 3; $i++) {
        $ts = (Get-Date).ToString('o')
        $line = "$ts`t$fp06Outcome`t受け入れテストT5-A68によるフォールトインジェクション($i/3)"
        Add-Content -Path $outcomesLogPath -Value $line -Encoding utf8
    }

    # ========================================================================
    # 準備3: FP-03-EMULATOR シグネチャA(adb.exe不在)を模擬(子プロセスのみ)
    # ========================================================================
    Write-AcceptanceLog "FP-03用: ANDROID_SDK_ROOT を子プロセスのみで一時的に差し替え中..."
    $originalAndroidSdkRoot = $env:ANDROID_SDK_ROOT
    $hadAndroidSdkRoot = [bool]$env:ANDROID_SDK_ROOT
    $bogusAndroidSdkRoot = Join-Path $env:TEMP ("bb_t5a68_noandroid_" + [guid]::NewGuid().ToString("N"))
    $env:ANDROID_SDK_ROOT = $bogusAndroidSdkRoot
    Add-Cleanup {
        if ($hadAndroidSdkRoot) { $env:ANDROID_SDK_ROOT = $originalAndroidSdkRoot }
        else { Remove-Item Env:\ANDROID_SDK_ROOT -ErrorAction SilentlyContinue }
    }

    # ========================================================================
    # 準備4: FP-07-MISSINGBIN(adbがPATH上に無い)を模擬(子プロセスのみ)
    # ========================================================================
    Write-AcceptanceLog "FP-07用: PATH から adb.exe のディレクトリのみを一時的に除外中..."
    $originalPath = $env:PATH
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    $adbDirRemoved = $false
    if ($adbCmd) {
        $adbDir = (Split-Path -Parent $adbCmd.Source).TrimEnd('\')
        $filteredEntries = @($originalPath -split ';' | Where-Object { $_ -and (($_.TrimEnd('\')) -ne $adbDir) })
        $env:PATH = ($filteredEntries -join ';')
        $adbDirRemoved = $true
        Add-Cleanup { $env:PATH = $originalPath }
    } else {
        Write-AcceptanceLog "adb が元々PATH上に見つからないため、PATH差し替えは行わず自然な不在状態のまま検証します。"
    }

    # ========================================================================
    # 実行1: -Mode Preflight (FP-01 / FP-03 / FP-06 / FP-07 を同時に検証)
    # ========================================================================
    Write-AcceptanceLog "-Mode Preflight を実行中(FP-01/FP-03/FP-06/FP-07)..."
    $argsPreflight = '-NoProfile -NonInteractive -File "tools\failure_playbook.ps1" -Mode Preflight'
    $rPreflight = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $argsPreflight -TimeoutSec 170 -WorkingDirectory $repoRoot -Encoding $utf8NoBom
    $respPreflight = Get-LastJsonLine -StdOut $rPreflight.StdOut

    if (-not $respPreflight) {
        $checks.Add([ordered]@{ name = "FP-01-FILELOCK: 検知・対処がdocs記載どおり(warn/kill禁止)"; ok = $false; detail = "Preflightの出力からJSONを取得できませんでした(TimedOut=$($rPreflight.TimedOut), ExitCode=$($rPreflight.ExitCode))" })
        $checks.Add([ordered]@{ name = "FP-03-EMULATOR: 検知・対処がdocs記載どおり(有人時は自動再起動しない)"; ok = $false; detail = "同上" })
        $checks.Add([ordered]@{ name = "FP-06-SILENTSTALL: 検知・対処がdocs記載どおり(自動対処なし・escalate)"; ok = $false; detail = "同上" })
        $checks.Add([ordered]@{ name = "FP-07-MISSINGBIN: 検知・対処がdocs記載どおり(adb不在はexit1/warn)"; ok = $false; detail = "同上" })
    } else {
        $detected = @($respPreflight.detected)

        # --- FP-01-FILELOCK 判定 ---
        $entry01 = $detected | Where-Object { $_.ruleId -eq 'FP-01-FILELOCK' -and $_.detail -match [regex]::Escape($fp01FileName) } | Select-Object -First 1
        $ok01 = ($null -ne $entry01) -and ($entry01.severity -eq 'warn') -and ($entry01.action -eq 'none') -and ($entry01.result -eq 'warned')
        $checks.Add([ordered]@{
            name   = "FP-01-FILELOCK: フォールバックログ検知はwarnのみでkill等の自動対処をしない(docs §3 FP-01)"
            ok     = [bool]$ok01
            detail = if ($entry01) { "severity=$($entry01.severity), action=$($entry01.action), result=$($entry01.result)" } else { "FP-01-FILELOCKの検知が見つかりませんでした" }
        })

        # --- FP-03-EMULATOR 判定 ---
        $entry03 = $detected | Where-Object { $_.ruleId -eq 'FP-03-EMULATOR' } | Select-Object -First 1
        $ok03 = ($null -ne $entry03) -and ($entry03.severity -eq 'warn') -and ($entry03.action -eq 'none') -and ($entry03.result -eq 'warned')
        $checks.Add([ordered]@{
            name   = "FP-03-EMULATOR: adb.exe不在(シグネチャA)を検知し、有人時のため自動再起動しない(docs §3 FP-03・§3-2)"
            ok     = [bool]$ok03
            detail = if ($entry03) { "severity=$($entry03.severity), action=$($entry03.action), result=$($entry03.result), detail=$($entry03.detail)" } else { "FP-03-EMULATORの検知が見つかりませんでした" }
        })

        # --- FP-06-SILENTSTALL 判定 ---
        $entry06 = $detected | Where-Object { $_.ruleId -eq 'FP-06-SILENTSTALL' } | Select-Object -First 1
        $ok06 = ($null -ne $entry06) -and ($entry06.severity -eq 'escalate') -and ($entry06.action -eq 'none') -and ($entry06.result -eq 'escalate')
        $checks.Add([ordered]@{
            name   = "FP-06-SILENTSTALL: 同一outcome3行連続で自動対処なし・即escalateする(docs §3 FP-06)"
            ok     = [bool]$ok06
            detail = if ($entry06) { "severity=$($entry06.severity), action=$($entry06.action), result=$($entry06.result)" } else { "FP-06-SILENTSTALLの検知が見つかりませんでした" }
        })

        # --- FP-07-MISSINGBIN 判定 ---
        $entry07 = $detected | Where-Object { $_.ruleId -eq 'FP-07-MISSINGBIN' -and $_.detail -match 'adb' } | Select-Object -First 1
        $ok07 = ($null -ne $entry07) -and ($entry07.severity -eq 'warn') -and ($entry07.action -eq 'none') -and ($entry07.result -eq 'warned') -and ($rPreflight.ExitCode -ne 2)
        $checks.Add([ordered]@{
            name   = "FP-07-MISSINGBIN: adb不在はabortにせずexit1(warn)扱いにする(docs §3 FP-07)"
            ok     = [bool]$ok07
            detail = if ($entry07) { "severity=$($entry07.severity), action=$($entry07.action), result=$($entry07.result), PreflightExitCode=$($rPreflight.ExitCode)" } else { "FP-07-MISSINGBIN(adb)の検知が見つかりませんでした。PreflightExitCode=$($rPreflight.ExitCode)" }
        })
    }

    # ここでPreflight用に差し替えた環境変数(ANDROID_SDK_ROOT/PATH)は用済みのため、
    # 後続のCheck/Postmortem実行に影響しないよう先に復元しておく。
    if ($hadAndroidSdkRoot) { $env:ANDROID_SDK_ROOT = $originalAndroidSdkRoot } else { Remove-Item Env:\ANDROID_SDK_ROOT -ErrorAction SilentlyContinue }
    if ($adbDirRemoved) { $env:PATH = $originalPath }

    # ========================================================================
    # 準備5: FP-02-BOM(BOM無しの追跡外.ps1)を模擬生成
    # ========================================================================
    Write-AcceptanceLog "FP-02用: BOM無しの追跡外ダミー.ps1を生成中..."
    $fp02FileName = "_t5a68_dummy_bom.ps1"
    $fp02FilePath = Join-Path $toolsDir $fp02FileName
    $fp02Content = "# T5-A68 acceptance test dummy file (no BOM originally)`r`nWrite-Output 'dummy'`r`n"
    [System.IO.File]::WriteAllText($fp02FilePath, $fp02Content, $utf8NoBom)
    Add-Cleanup { if (Test-Path $fp02FilePath) { Remove-Item -Path $fp02FilePath -Force -ErrorAction SilentlyContinue } }

    # ========================================================================
    # 実行2: -Mode Check (FP-02 のみが対象フェーズ)
    # ========================================================================
    Write-AcceptanceLog "-Mode Check を実行中(FP-02)..."
    $argsCheck = '-NoProfile -NonInteractive -File "tools\failure_playbook.ps1" -Mode Check'
    $rCheck = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $argsCheck -TimeoutSec 60 -WorkingDirectory $repoRoot -Encoding $utf8NoBom
    $respCheck = Get-LastJsonLine -StdOut $rCheck.StdOut

    if (-not $respCheck) {
        $checks.Add([ordered]@{ name = "FP-02-BOM: BOM喪失を自動修復する(docs §3 FP-02)"; ok = $false; detail = "Checkの出力からJSONを取得できませんでした(TimedOut=$($rCheck.TimedOut), ExitCode=$($rCheck.ExitCode))" })
    } else {
        $detected02 = @($respCheck.detected)
        $entry02 = $detected02 | Where-Object { $_.ruleId -eq 'FP-02-BOM' -and $_.detail -match [regex]::Escape($fp02FileName) } | Select-Object -First 1
        $bomNowPresent = $false
        if (Test-Path $fp02FilePath) {
            $bytesNow = [System.IO.File]::ReadAllBytes($fp02FilePath)
            $bomNowPresent = ($bytesNow.Length -ge 3 -and $bytesNow[0] -eq 0xEF -and $bytesNow[1] -eq 0xBB -and $bytesNow[2] -eq 0xBF)
        }
        $ok02 = ($null -ne $entry02) -and ($entry02.action -eq 'repaired') -and ($entry02.result -eq 'ok') -and ($entry02.severity -eq 'auto') -and $bomNowPresent
        $checks.Add([ordered]@{
            name   = "FP-02-BOM: 追跡外のBOM無し.ps1をCheckモードで検知し自動修復する(docs §3 FP-02)"
            ok     = [bool]$ok02
            detail = if ($entry02) { "severity=$($entry02.severity), action=$($entry02.action), result=$($entry02.result), 修復後BOM有無=$bomNowPresent" } else { "FP-02-BOMの検知が見つかりませんでした" }
        })
    }

    # ========================================================================
    # 準備6: FP-04-PERMISSION(拒否文字列を含むダミーjsonl、$env:TEMP内で完全隔離)
    # ========================================================================
    Write-AcceptanceLog "FP-04用: 隔離した一時ディレクトリに拒否文字列入りダミーjsonlを生成中..."
    $tempDir = Join-Path $env:TEMP ("bb_t5a68_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Add-Cleanup { if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue } }
    $fp04JsonlPath = Join-Path $tempDir "dummy_stream.jsonl"
    'Permission to use Bash has been denied for this request.' | Out-File -FilePath $fp04JsonlPath -Encoding utf8

    # ========================================================================
    # 準備7: FP-05-HANG-AGY(同一task_idでexit_code=11を2件連続、ledger.tsvへ注入)
    # ========================================================================
    Write-AcceptanceLog "FP-05用: ledger.tsv を退避し、同一task_idでexit_code=11の行を2件追記中..."
    if (-not (Test-Path $ledgerPath)) {
        $checks.Add([ordered]@{ name = "FP-05-HANG-AGY: 1件目はresult=ok(記録のみ)・2件目(2回連続)はresult=escalate(docs §3 FP-05(a))"; ok = $false; detail = ".claude/agy_logs/ledger.tsv が見つからないため注入できませんでした(前提不足)" })
        $skipFp05 = $true
    } else {
        $skipFp05 = $false
        $ledgerBackupBytes = [System.IO.File]::ReadAllBytes($ledgerPath)
        Add-Cleanup { [System.IO.File]::WriteAllBytes($ledgerPath, $ledgerBackupBytes) }
        $fp05TaskId = "T5-ZZZTEST-A68-" + (Get-Random -Minimum 100000 -Maximum 999999)
        $fp05Timestamps = New-Object System.Collections.Generic.List[string]
        for ($i = 1; $i -le 2; $i++) {
            $tsLedger = (Get-Date).ToString('yyyyMMdd_HHmmss')
            $fp05Timestamps.Add($tsLedger) | Out-Null
            $rowCols = @($tsLedger, $fp05TaskId, 'test', 'test-model', '11', '1', '1', '0', '100', 'T5-A68受け入れテスト用ダミー行')
            Add-Content -Path $ledgerPath -Value ($rowCols -join "`t") -Encoding utf8
        }
    }

    # ========================================================================
    # 実行3: -Mode Postmortem (FP-04 / FP-05-HANG-AGY を同時に検証)
    # ========================================================================
    Write-AcceptanceLog "-Mode Postmortem を実行中(FP-04/FP-05)..."
    $argsPostmortem = '-NoProfile -NonInteractive -File "tools\failure_playbook.ps1" -Mode Postmortem -StreamLogPath "{0}"' -f $fp04JsonlPath
    $rPostmortem = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $argsPostmortem -TimeoutSec 60 -WorkingDirectory $repoRoot -Encoding $utf8NoBom
    $respPostmortem = Get-LastJsonLine -StdOut $rPostmortem.StdOut

    if (-not $respPostmortem) {
        $checks.Add([ordered]@{ name = "FP-04-PERMISSION: 拒否文字列検知は自動対処せず即escalateする(docs §3 FP-04)"; ok = $false; detail = "Postmortemの出力からJSONを取得できませんでした(TimedOut=$($rPostmortem.TimedOut), ExitCode=$($rPostmortem.ExitCode))" })
        if (-not $skipFp05) {
            $checks.Add([ordered]@{ name = "FP-05-HANG-AGY: 1件目はresult=ok(記録のみ)・2件目(2回連続)はresult=escalate(docs §3 FP-05(a))"; ok = $false; detail = "同上" })
        }
    } else {
        $detectedPm = @($respPostmortem.detected)

        # --- FP-04-PERMISSION 判定 ---
        $entry04 = $detectedPm | Where-Object { $_.ruleId -eq 'FP-04-PERMISSION' -and $_.detail -match 'Bash' } | Select-Object -First 1
        $ok04 = ($null -ne $entry04) -and ($entry04.severity -eq 'escalate') -and ($entry04.action -eq 'none') -and ($entry04.result -eq 'escalate')
        $checks.Add([ordered]@{
            name   = "FP-04-PERMISSION: 拒否文字列検知は自動対処せず即escalateする(docs §3 FP-04、settings*.jsonは書き換えない)"
            ok     = [bool]$ok04
            detail = if ($entry04) { "severity=$($entry04.severity), action=$($entry04.action), result=$($entry04.result)" } else { "FP-04-PERMISSIONの検知が見つかりませんでした" }
        })

        # --- FP-05-HANG-AGY 判定 ---
        # 注意: Repairの'ok'(記録のみ)分岐はDetailにtask_id文字列を含めない実装のため
        # (2回連続時のescalate分岐のみtask_idを含む)、task_idではなく注入した
        # timestamp(=$rowTsが両分岐のDetailに必ず残る)で一致判定する。
        if (-not $skipFp05) {
            $tsPatternParts = @($fp05Timestamps | Select-Object -Unique | ForEach-Object { [regex]::Escape($_) })
            $tsPattern = $tsPatternParts -join '|'
            $matches05 = @($detectedPm | Where-Object { $_.ruleId -eq 'FP-05-HANG-AGY' -and ($tsPattern -and $_.detail -match $tsPattern) })
            $ok05 = ($matches05.Count -eq 2) -and
                    ($matches05[0].result -eq 'ok') -and ($matches05[0].severity -eq 'auto') -and ($matches05[0].action -eq 'none') -and
                    ($matches05[1].result -eq 'escalate') -and ($matches05[1].severity -eq 'escalate') -and ($matches05[1].action -eq 'none')
            $checks.Add([ordered]@{
                name   = "FP-05-HANG-AGY: 1件目はresult=ok(既存フォールバック挙動を変えず記録のみ)・同一task_idが2回連続でresult=escalate(docs §3 FP-05(a))"
                ok     = [bool]$ok05
                detail = "検知件数=$($matches05.Count)" + $(if ($matches05.Count -eq 2) { ", 1件目: severity=$($matches05[0].severity)/action=$($matches05[0].action)/result=$($matches05[0].result) / 2件目: severity=$($matches05[1].severity)/action=$($matches05[1].action)/result=$($matches05[1].result)" } else { "" })
            })
        }
    }

    Set-Location -Path $originalLocation

    # 注意: この環境のPowerShell 5.1では `@($genericListInstance)` をそのまま式として
    # 評価すると「Argument types do not match」で例外になるため(実測で確認済み)、
    # List[object]は直接パイプへ渡すか .ToArray() で明示変換してから使う。
    $failedChecks = @($checks | Where-Object { -not $_.ok })
    $overallOk = ($failedChecks.Count -eq 0) -and ($checks.Count -eq 7)
    $final = [ordered]@{
        task    = $taskId
        ok      = [bool]$overallOk
        skipped = $false
        reason  = ""
        checks  = $checks.ToArray()
    }
    if (-not $overallOk) {
        $failedNames = ($failedChecks | ForEach-Object { $_.name }) -join "; "
        if ($checks.Count -ne 7) {
            $final.reason = "checksが7件そろっていません(実際: $($checks.Count)件)。不合格の項目: $failedNames"
        } else {
            $final.reason = "不合格の項目: $failedNames"
        }
    }

    Write-Output ($final | ConvertTo-Json -Compress -Depth 6)
    if ($overallOk) { exit 0 } else { exit 1 }
} catch {
    $err = [ordered]@{
        task = $taskId; ok = $false; skipped = $false
        reason = "例外: $($_.Exception.Message)"
        checks = $checks.ToArray()
    }
    Write-Output ($err | ConvertTo-Json -Compress -Depth 6)
    exit 3
} finally {
    try { Set-Location -Path $originalLocation } catch {}
    Invoke-AllCleanups
}
