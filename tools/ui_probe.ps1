#requires -Version 5.1
<#
.SYNOPSIS
  ui_verifier エージェント専用の Android エミュレータ操作ツール(Windows版)。
  対応する Ubuntu/Bash 版は作らない(Windows専用。理由は設計書§Aの決定6)。

.DESCRIPTION
  9個のサブコマンド(-Prepare/-Shot/-Tap/-Swipe/-Back/-Log/-Dump/-Net/-Info/-Alive)を
  スイッチパラメータで切り替える。各サブコマンドは標準出力に1行のJSONだけを返す
  (進捗メッセージは Write-Host ではなく標準エラーへ)。ui_verifier エージェントは
  この1行だけを読む。

  エミュレータ本体の起動/停止は tools/emulator.ps1 を呼び出す。ここでは再実装しない。

  仕様の正本: docs/android_release/検証強化設計.md §5-2a・§5-2b D-3
  (implementer はこのファイルの実装にあたり両節を読んだ。仕様変更時は先にそちらを直すこと)

  T5-A32(§5-2b D-3)で、エミュレータのクラッシュ/ハングを安く・速く検知できるよう
  以下を実装した:
  - `Invoke-Prepare` の手順順序を「①ビルド→②エミュレータ確認/起動→③install以降」に変更
    (ビルド中にエミュレータを走らせて qemu が不安定化する仮説への対処)。
  - 全 adb 呼び出しを `Invoke-Adb`/`Invoke-TimedProcess` 経由のタイムアウト付き実行にし、
    終了コードを確認する(`| Out-Null` での握り潰しをやめる)。
  - `Assert-DeviceAlive` で `adb get-state` の応答性を確認する。**プロセスの生死
    (`$process.HasExited`)だけでは、プロセスは生きているが adb が無応答なハング
    (T5-A31検証時に観測、WERにAPPCRASH記録なし)を検知できない**ため、
    タイムアウト付きコマンド実行で判定する。
  - `-Prepare -Retry`(既定1)で `device_lost`/`emulator_start_failed` 時のみ
    1回だけ自動再試行する。

  T5-A36: `-SkipBuild` を使うと `--dart-define=flutter.inspector.structuredErrors=false`
  付きでビルドされたAPKかどうかを保証できない。`-Log` のoverflow/exception検出を
  根拠にする検証では `-SkipBuild` を使わない。

.PARAMETER Prepare
  debug APKビルド(既定) → エミュレータ確認/起動 → インストール → ライト固定・
  アニメ無効化 → アプリ起動 → セッションディレクトリ作成、を一括実行する。

.PARAMETER Retry
  -Prepare が `device_lost`/`emulator_start_failed` で失敗した場合に自動再試行する回数。
  既定1(=最大2回試行して、2回目も失敗したら諦める)。

.PARAMETER Alive
  現在のエミュレータの生死・応答性を安く確認する(`{"ok":true,"alive":true/false,...}`)。

.PARAMETER Shot
  スクリーンショットを1枚撮る。-Name が必須。

.PARAMETER Tap
  比率座標(0.0〜1.0)でタップする。-X -Y が必須。

.PARAMETER Swipe
  比率座標でスワイプする。-X -Y -X2 -Y2 が必須。

.PARAMETER Back
  戻るキー(keyevent 4)を送る。

.PARAMETER Log
  logcat を取得し、既知パターンに一致した行を抽出する。

.PARAMETER Dump
  uiautomator dump を実行し semantics ノード数を数える。-Name(画面ID)が必須。

.PARAMETER Net
  ネットワークのon/offを切り替える。-State on|off が必須。

.PARAMETER Info
  画面サイズ・密度・フォーカス中のActivityを返す。

.EXAMPLE
  .\tools\ui_probe.ps1 -Prepare
.EXAMPLE
  .\tools\ui_probe.ps1 -Shot -Name 090_initial
.EXAMPLE
  .\tools\ui_probe.ps1 -Tap -X 0.5 -Y 0.965
#>

param(
    [switch]$Prepare,
    [switch]$Shot,
    [switch]$Tap,
    [switch]$Swipe,
    [switch]$Back,
    [switch]$Log,
    [switch]$Dump,
    [switch]$Net,
    [switch]$Info,
    [switch]$Alive,

    # -Prepare 用
    [switch]$SkipBuild,
    [switch]$ClearData,
    [string]$AvdName = "beanbase_ui",
    [int]$Retry = 1,

    # -Shot / -Dump 共通
    [string]$Name,
    [string]$Session,

    # -Shot 用
    [double]$DelaySec = 2.5,

    # -Tap / -Swipe 用(比率 0.0〜1.0)
    [double]$X,
    [double]$Y,
    [double]$X2,
    [double]$Y2,
    [int]$DurationMs = 300,

    # -Net 用
    [string]$State
)

# 標準出力にJSON以外の文字が混じらないよう、進捗メッセージは全て標準エラーへ出す。
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
# 注: "Stop" にすると、adb等ネイティブexeのstderr出力がPowerShell 5.1でErrorRecord化された際に
# 即座に終了エラーとなり、adbの一時的なstderr出力(起動直後の"device offline"等)だけで
# スクリプト全体が落ちてしまう(tools/verify.ps1 と同じ理由で "Continue" を使う)。
$ErrorActionPreference = "Continue"

$PackageName = "com.example.bean_base"
$MainActivity = "$PackageName/.MainActivity"

# -Prepare の内部リトライで使う。Invoke-Prepare の catch がここを読み、
# エラーコードを保った上でリトライ可否を判断する(Send-Failure 参照)。
$script:PendingErrorCode = $null

function Write-Verbose2([string]$Message) {
    [Console]::Error.WriteLine("[ui_probe.ps1] $Message")
}

function Write-ResultObject($Obj) {
    ($Obj | ConvertTo-Json -Compress -Depth 10)
}

function Write-ErrorResult([string]$Code, [string]$Message) {
    $obj = [ordered]@{ ok = $false; error = $Code; message = $Message }
    ($obj | ConvertTo-Json -Compress -Depth 5)
    exit 1
}

# -Prepare のリトライループ用。Write-ErrorResult と違い即座に exit せず、
# 呼び出し元(Invoke-Prepare)の try/catch まで例外として伝搬させる。
# $script:PendingErrorCode にエラーコードを載せてから throw する。
function Send-Failure([string]$Code, [string]$Message) {
    $script:PendingErrorCode = $Code
    throw $Message
}

# --- 準備 -------------------------------------------------------------

$RepoRootRaw = (& git rev-parse --show-toplevel 2>$null)
if (-not $RepoRootRaw) {
    Write-ErrorResult "repo_root_not_found" "gitリポジトリのルートが取得できませんでした。"
}
Set-Location -Path $RepoRootRaw.Trim()
$RepoRoot = (Get-Location).Path

function Get-RelativePath([string]$FullPath) {
    $rel = $FullPath.Substring($RepoRoot.Length)
    $rel = $rel.TrimStart('\', '/')
    return $rel.Replace('\', '/')
}

function Get-AndroidSdkRoot {
    if ($env:ANDROID_SDK_ROOT) { return $env:ANDROID_SDK_ROOT }
    if ($env:ANDROID_HOME) { return $env:ANDROID_HOME }
    return "$env:LOCALAPPDATA\Android\Sdk"
}

$sdkRoot = Get-AndroidSdkRoot
$adbExe = Join-Path $sdkRoot "platform-tools\adb.exe"
$emulatorScript = Join-Path $PSScriptRoot "emulator.ps1"

function Assert-Adb {
    if (-not (Test-Path $adbExe)) {
        Write-ErrorResult "adb_not_found" "adbが見つかりません: $adbExe (ANDROID_SDK_ROOT=$sdkRoot)。Android SDKのセットアップ(T5-A6手順)を確認してください。"
    }
}

# 外部コマンドをタイムアウト付きで実行する(flutter build / adb 呼び出し全般で使う)。
# verify.ps1 の Invoke-LoggedCommand と同じ Start-Process パターン(PowerShell 5.1 では
# ネイティブexeへの 2>&1 がエラーレコード化するため使わない)。
# プロセスの生死(HasExited)だけでは「プロセスは生きているがadbが無応答」なハングを
# 検知できないため、adb呼び出しは必ずこの関数でタイムアウトを掛けて実行する。
function Invoke-TimedProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
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
        $null = $proc.Handle

        if ($TimeoutMs -gt 0) {
            $finished = $proc.WaitForExit($TimeoutMs)
            if (-not $finished) {
                $timedOut = $true
                try { & taskkill /PID $proc.Id /T /F 2>$null | Out-Null } catch {}
                try { $proc.WaitForExit(5000) } catch {}
            } else {
                $exitCode = $proc.ExitCode
            }
        } else {
            $proc.WaitForExit()
            $exitCode = $proc.ExitCode
        }
    } catch {
        return @{ ExitCode = -1; TimedOut = $false; Tail = "コマンド実行エラー: $($_.Exception.Message)"; Out = ""; OutLines = @() }
    }

    $outText = ""
    if (Test-Path $stdoutFile) {
        $t = Get-Content -Raw -Encoding UTF8 -Path $stdoutFile -ErrorAction SilentlyContinue
        if ($t) { $outText = $t }
    }
    $errText = ""
    if (Test-Path $stderrFile) {
        $t = Get-Content -Raw -Encoding UTF8 -Path $stderrFile -ErrorAction SilentlyContinue
        if ($t) { $errText = $t }
    }
    Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue

    $combined = "$outText`n$errText"
    $tailLines = ($combined -split "`r?`n") | Select-Object -Last 15
    $tail = ($tailLines -join " / ")
    $outLines = @($outText -split "`r?`n")

    return @{ ExitCode = $exitCode; TimedOut = $timedOut; Tail = $tail; Out = $outText; OutLines = $outLines }
}

# adb呼び出しの共通ラッパー。タイムアウト・終了コードを必ず確認し、失敗時は
# -Throw 指定時は Send-Failure(-Prepare のリトライループが catch する)、
# 未指定時は Write-ErrorResult(即座に exit、他のサブコマンドはこちら)で終了する。
# タイムアウト(=応答なし)は常に "device_lost" として扱う(ハング検知の本体)。
function Invoke-Adb {
    param(
        [Parameter(Mandatory = $true)][string]$Serial,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$StepName,
        [int]$TimeoutSec = 20,
        [string]$ErrorCode = "adb_failed",
        [switch]$Throw
    )
    Assert-Adb
    $result = Invoke-TimedProcess -FilePath $adbExe -ArgumentList (@("-s", $Serial) + $Arguments) -TimeoutMs ($TimeoutSec * 1000)

    if ($result.TimedOut) {
        $msg = "adbコマンドが${TimeoutSec}秒応答しませんでした($StepName): adb -s $Serial $($Arguments -join ' ')"
        if ($Throw) { Send-Failure "device_lost" $msg } else { Write-ErrorResult "device_lost" $msg }
    }
    if ($result.ExitCode -ne 0) {
        $msg = "$StepName が失敗しました(exit=$($result.ExitCode)): $($result.Tail)"
        if ($Throw) { Send-Failure $ErrorCode $msg } else { Write-ErrorResult $ErrorCode $msg }
    }
    return $result
}

# adb devices の一覧からエミュレータのシリアルを探す。タイムアウト(15秒)した場合は
# 「adbサーバ自体が無応答」= デバイスなしとして扱い、呼び出し元の分岐に委ねる
# (ここで即エラーにすると -Alive 等の生存確認用途で使えなくなるため)。
function Get-DeviceSerial {
    Assert-Adb
    $result = Invoke-TimedProcess -FilePath $adbExe -ArgumentList @("devices") -TimeoutMs 15000
    if ($result.TimedOut) {
        Write-Verbose2 "adb devices が15秒応答しませんでした。デバイスなしとして扱います。"
        return $null
    }
    foreach ($line in $result.OutLines) {
        if ($line -match "^(emulator-\S+)\s+device\s*$") {
            return $Matches[1]
        }
    }
    return $null
}

function Assert-Serial {
    $serial = Get-DeviceSerial
    if (-not $serial) {
        Write-ErrorResult "device_not_found" "adbデバイスが見つかりません。先に -Prepare を実行してエミュレータを起動してください。"
    }
    return $serial
}

# デバイスの応答性を確認する(死活監視の本体)。$process.HasExited のようなプロセス生死の
# 確認だけでは、「qemuプロセスは生きているがadbが無応答」なハング(T5-A31検証時に観測、
# WERにAPPCRASH記録なし、adb devicesは空)を検知できない。そのため adb get-state を
# タイムアウト付きで実行し、"device" が返るかどうかで独立に判定する。
function Assert-DeviceAlive {
    param(
        [Parameter(Mandatory = $true)][string]$Serial,
        [int]$TimeoutSec = 5
    )
    $result = Invoke-TimedProcess -FilePath $adbExe -ArgumentList @("-s", $Serial, "get-state") -TimeoutMs ($TimeoutSec * 1000)
    if ($result.TimedOut) { return $false }
    if ($result.ExitCode -ne 0) { return $false }
    return (($result.Out).Trim() -eq "device")
}

# wm size / wm density から解像度・密度・48dp相当pxを取得する。
# ブート直後は adb shell が一時的に "device offline" を返すことがあるため、
# width/height が取れない場合は間隔を空けて最大3回リトライする。
# 各adb呼び出しは8秒でタイムアウトさせる(無応答のまま無期限に待たない)。
function Get-DeviceInfo([string]$Serial) {
    $width = 0
    $height = 0
    $density = 160

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $sizeResult = Invoke-TimedProcess -FilePath $adbExe -ArgumentList @("-s", $Serial, "shell", "wm", "size") -TimeoutMs 8000
        $densityResult = Invoke-TimedProcess -FilePath $adbExe -ArgumentList @("-s", $Serial, "shell", "wm", "density") -TimeoutMs 8000
        $sizeLines = if ($sizeResult.TimedOut) { @() } else { $sizeResult.OutLines }
        $densityLines = if ($densityResult.TimedOut) { @() } else { $densityResult.OutLines }

        $overrideSize = $sizeLines | Where-Object { $_ -match "Override size:\s*(\d+)x(\d+)" }
        $physicalSize = $sizeLines | Where-Object { $_ -match "Physical size:\s*(\d+)x(\d+)" }
        $sizeTarget = if ($overrideSize) { $overrideSize } else { $physicalSize }
        if ($sizeTarget -and ($sizeTarget -match "(\d+)x(\d+)")) {
            $width = [int]$Matches[1]
            $height = [int]$Matches[2]
        }

        $overrideDensity = $densityLines | Where-Object { $_ -match "Override density:\s*(\d+)" }
        $physicalDensity = $densityLines | Where-Object { $_ -match "Physical density:\s*(\d+)" }
        $densityTarget = if ($overrideDensity) { $overrideDensity } else { $physicalDensity }
        if ($densityTarget -and ($densityTarget -match "(\d+)")) {
            $density = [int]$Matches[1]
        }

        if ($width -gt 0 -and $height -gt 0) { break }
        Write-Verbose2 "wm size/density が空でした(試行 $attempt/3)。2秒待って再試行します。"
        Start-Sleep -Seconds 2
    }

    $tap48dpPx = [int][Math]::Round(48.0 * $density / 160.0)

    return [ordered]@{
        Width      = $width
        Height     = $height
        Density    = $density
        Tap48dpPx  = $tap48dpPx
    }
}

# Get-DeviceInfo を呼び出し、3回リトライしても width/height が取得できなかった場合は
# ここで終了する。-Throw 指定時は -Prepare のリトライループへ device_lost として伝える。
function Get-DeviceInfoOrFail {
    param([string]$Serial, [switch]$Throw)
    $info = Get-DeviceInfo -Serial $Serial
    if ($info.Width -le 0 -or $info.Height -le 0) {
        $msg = "画面サイズ(wm size/wm density)の取得に失敗しました(width=$($info.Width) height=$($info.Height))。エミュレータがクラッシュ/オフラインになっている可能性があります。"
        if ($Throw) { Send-Failure "device_lost" $msg } else { Write-ErrorResult "device_info_failed" $msg }
    }
    return $info
}

# -Session 省略時は .claude/ui_verify 配下の更新日時が最新のディレクトリを使う。
function Resolve-SessionDir([string]$SessionArg) {
    $uiVerifyRoot = Join-Path $RepoRoot ".claude\ui_verify"

    if ($SessionArg) {
        $candidate = $SessionArg
        if (-not [System.IO.Path]::IsPathRooted($candidate)) {
            $candidate = Join-Path $RepoRoot $SessionArg
        }
        if (-not (Test-Path $candidate)) {
            Write-ErrorResult "session_not_found" "指定されたセッションディレクトリが見つかりません: $SessionArg"
        }
        return (Resolve-Path $candidate).Path
    }

    if (-not (Test-Path $uiVerifyRoot)) {
        Write-ErrorResult "no_session" "セッションディレクトリがまだありません。先に -Prepare を実行してください。"
    }
    $latest = Get-ChildItem -Path $uiVerifyRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-ErrorResult "no_session" "セッションディレクトリがまだありません。先に -Prepare を実行してください。"
    }
    return $latest.FullName
}

# セッションディレクトリ内の既存 *.png 数 + 1 を2桁ゼロ埋めで採番する。
function Get-NextSeq([string]$SessionDir) {
    $count = (Get-ChildItem -Path $SessionDir -Filter "*.png" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    return "{0:D2}" -f ($count + 1)
}

# 直近の emulator.ps1 起動ログ(.claude/emu_logs/*_emu_err.log)のうち最新のものを返す。
# ui_verifier が「環境要因」と判断する材料にする(検証強化設計 §5-2b D-3 #5)。
function Get-LatestEmuLog {
    $emuLogDir = Join-Path $RepoRoot ".claude\emu_logs"
    if (-not (Test-Path $emuLogDir)) { return $null }
    $latest = Get-ChildItem -Path $emuLogDir -Filter "*_emu_err.log" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) { return (Get-RelativePath $latest.FullName) }
    return $null
}

# 直近N分の qemu-system-x86_64.exe の WER APPCRASH(Application ログ ID 1000)件数。
# emulator.ps1 -Doctor と同じ判定ロジック。
function Get-RecentCrashCount([int]$Minutes = 5) {
    try {
        $since = (Get-Date).AddMinutes(-$Minutes)
        $events = Get-WinEvent -FilterHashtable @{LogName = 'Application'; Id = 1000; StartTime = $since } -ErrorAction SilentlyContinue
        if ($events) {
            return ($events | Where-Object { $_.Message -match "qemu-system-x86_64\.exe" }).Count
        }
    } catch {}
    return 0
}

# -Prepare のリトライ前に残存プロセス・ロックファイルを片付ける
# (tools/emulator.ps1 の Clear-StaleEmulator 相当。emulator.ps1 内の非公開関数は
# 外部から呼べないため、同等の処理をここに複製する)。
function Invoke-CleanupStaleEmulator {
    Write-Verbose2 "残存エミュレータプロセス・ロックファイルを片付けています(AVD: $AvdName)。"
    Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    $avdHome = if ($env:ANDROID_AVD_HOME) { $env:ANDROID_AVD_HOME } else { Join-Path $env:USERPROFILE ".android\avd" }
    $avdDir = Join-Path $avdHome "$AvdName.avd"
    foreach ($lockName in @("hardware-qemu.ini.lock", "multiinstance.lock")) {
        $lockPath = Join-Path $avdDir $lockName
        if (Test-Path $lockPath) {
            Remove-Item -Path $lockPath -Force -Recurse -ErrorAction SilentlyContinue
            Write-Verbose2 "ロックファイルを削除しました: $lockPath"
        }
    }
    Start-Sleep -Seconds 2
}

# --- サブコマンド実装 ---------------------------------------------------

# -Prepare 本体。$Retry(既定1)回まで、device_lost / emulator_start_failed の
# 場合のみ自動再試行する(検証強化設計 §5-2b D-3 #4)。実処理は Invoke-PrepareAttempt。
function Invoke-Prepare {
    $maxAttempts = $Retry + 1
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $script:PendingErrorCode = $null
        try {
            Invoke-PrepareAttempt -Attempt $attempt
            return
        } catch {
            $code = $script:PendingErrorCode
            if (-not $code) { $code = "unhandled_exception" }
            $message = $_.Exception.Message
            $retryable = ($code -eq "device_lost" -or $code -eq "emulator_start_failed")

            if ($retryable -and $attempt -lt $maxAttempts) {
                Write-Verbose2 "試行 $attempt/$maxAttempts が失敗しました($code`: $message)。エミュレータを片付けて1回だけ自動再試行します。"
                Invoke-CleanupStaleEmulator
                continue
            }

            $obj = [ordered]@{
                ok             = $false
                error          = $code
                message        = $message
                attempts       = $attempt
                emu_log        = (Get-LatestEmuLog)
                crash_detected = (Get-RecentCrashCount -Minutes 5)
            }
            ($obj | ConvertTo-Json -Compress -Depth 5)
            exit 1
        }
    }
}

function Invoke-PrepareAttempt {
    param([int]$Attempt)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Assert-Adb

    # ① flutter build apk --debug(タイムアウト900秒)を先に実行する。
    # エミュレータを起動したまま並行してビルドすると、Gradle/Kotlinデーモンの高負荷と
    # 完全ソフトウェアGPU(lavapipe/SwiftShaderのJIT)が競合し qemu が不安定になりうる
    # (検証強化設計 §5-2b B の仮説1への対処)。-SkipBuild 時は②から開始する。
    if (-not $SkipBuild) {
        Write-Verbose2 "flutter build apk --debug --dart-define=flutter.inspector.structuredErrors=false を実行します(タイムアウト900秒)。"
        # --dart-define=flutter.inspector.structuredErrors=false は必須。既定(true)だと
        # FlutterError はVM Serviceの Flutter.Error 拡張イベントに送られ、flutter run で
        # アタッチしていない単独起動ではlogcatに一切出ない。T5-A36。
        $buildResult = Invoke-TimedProcess -FilePath "flutter" -ArgumentList @("build", "apk", "--debug", "--dart-define=flutter.inspector.structuredErrors=false") -TimeoutMs 900000
        if ($buildResult.TimedOut) {
            Send-Failure "build_timeout" "flutter build apk --debug --dart-define=flutter.inspector.structuredErrors=false がタイムアウトしました(900秒)。"
        }
        if ($buildResult.ExitCode -ne 0) {
            Send-Failure "build_failed" "flutter build apk --debug --dart-define=flutter.inspector.structuredErrors=false が失敗しました(exit=$($buildResult.ExitCode))。末尾: $($buildResult.Tail)"
        }
    } else {
        Write-Verbose2 "-SkipBuild 指定のためビルドをスキップします。"
    }

    # ② エミュレータ確認/起動
    $serial = Get-DeviceSerial
    if (-not $serial) {
        Write-Verbose2 "AVD '$AvdName' が未起動のため tools/emulator.ps1 -Start を呼び出します。"
        try {
            & $emulatorScript -Start -AvdName $AvdName 6>&1 | ForEach-Object { Write-Verbose2 "$_" }
        } catch {
            Send-Failure "emulator_start_failed" "tools/emulator.ps1 -Start が失敗しました: $($_.Exception.Message)"
        }
        $serial = Get-DeviceSerial
        if (-not $serial) {
            Send-Failure "emulator_start_failed" "AVD '$AvdName' の起動後もadbデバイスが見つかりませんでした。"
        }
    } else {
        Write-Verbose2 "AVD '$AvdName' は起動中です(シリアル: $serial)。"
    }

    # 死活監視: adb devices に載っていても実際には無応答(ハング)なことがあるため、
    # get-state で独立に応答性を確認する(検証強化設計 §5-2b D-3 #3)。
    if (-not (Assert-DeviceAlive -Serial $serial -TimeoutSec 5)) {
        Send-Failure "device_lost" "エミュレータ(serial=$serial)が応答しません(adb get-stateがタイムアウトまたは異常終了)。"
    }

    # ③ install(以降、失敗は全てdevice_lostとして扱う。この時点でデバイスの生存は
    #    確認済みのため、以降のadb失敗はデバイスが途中で失われたと解釈するのが妥当)
    $apkPath = Join-Path $RepoRoot "build\app\outputs\flutter-apk\app-debug.apk"
    if (-not (Test-Path $apkPath)) {
        Send-Failure "apk_not_found" "APKが見つかりません: $apkPath"
    }
    Invoke-Adb -Serial $serial -Arguments @("install", "-r", $apkPath) -StepName "APKインストール" -TimeoutSec 90 -ErrorCode "device_lost" -Throw | Out-Null

    # ④ ダークモード無効化(ライト固定)
    Invoke-Adb -Serial $serial -Arguments @("shell", "cmd", "uimode", "night", "no") -StepName "ダークモード無効化" -TimeoutSec 10 -ErrorCode "device_lost" -Throw | Out-Null

    # ⑤ アニメ無効化
    foreach ($settingArgs in @(
            @("shell", "settings", "put", "global", "window_animation_scale", "0"),
            @("shell", "settings", "put", "global", "transition_animation_scale", "0"),
            @("shell", "settings", "put", "global", "animator_duration_scale", "0")
        )) {
        Invoke-Adb -Serial $serial -Arguments $settingArgs -StepName "アニメ無効化" -TimeoutSec 10 -ErrorCode "device_lost" -Throw | Out-Null
    }

    # ⑥ -ClearData 指定時のみアプリデータ削除
    if ($ClearData) {
        Invoke-Adb -Serial $serial -Arguments @("shell", "pm", "clear", $PackageName) -StepName "アプリデータ削除" -TimeoutSec 15 -ErrorCode "device_lost" -Throw | Out-Null
    }

    # ⑦ logcatクリア
    Invoke-Adb -Serial $serial -Arguments @("logcat", "-c") -StepName "logcatクリア" -TimeoutSec 10 -ErrorCode "device_lost" -Throw | Out-Null

    # ⑧ 強制停止
    Invoke-Adb -Serial $serial -Arguments @("shell", "am", "force-stop", $PackageName) -StepName "強制停止" -TimeoutSec 10 -ErrorCode "device_lost" -Throw | Out-Null

    # ⑨ 起動
    Invoke-Adb -Serial $serial -Arguments @("shell", "am", "start", "-W", "-n", $MainActivity) -StepName "アプリ起動" -TimeoutSec 30 -ErrorCode "device_lost" -Throw | Out-Null

    if (-not (Assert-DeviceAlive -Serial $serial -TimeoutSec 5)) {
        Send-Failure "device_lost" "アプリ起動直後にデバイス(serial=$serial)が応答しなくなりました。"
    }

    # ⑩ 起動待機。旧実装は Start-Sleep 6秒の固定待機で、途中でクラッシュ/ハングしても
    # 気付けなかった。1秒×6回のポーリングに変え、毎回死活監視する
    # (落ちてから最大10秒程度で device_lost を返せるようにする)。
    for ($i = 1; $i -le 6; $i++) {
        Start-Sleep -Seconds 1
        if (-not (Assert-DeviceAlive -Serial $serial -TimeoutSec 5)) {
            Send-Failure "device_lost" "アプリ起動待機中(${i}秒経過)にデバイス(serial=$serial)が応答しなくなりました。"
        }
    }

    # ⑪ セッションディレクトリ作成
    $sessionName = Get-Date -Format "yyyyMMdd_HHmmss"
    $sessionRel = ".claude/ui_verify/$sessionName"
    $sessionDirFull = Join-Path $RepoRoot ".claude\ui_verify\$sessionName"
    New-Item -ItemType Directory -Force -Path $sessionDirFull | Out-Null

    $info = Get-DeviceInfoOrFail -Serial $serial -Throw
    $sw.Stop()

    $deviceJson = [ordered]@{
        ok             = $true
        session        = $sessionRel
        serial         = $serial
        width          = $info.Width
        height         = $info.Height
        density        = $info.Density
        tap48dp_px     = $info.Tap48dpPx
        launch_ms      = [int]$sw.Elapsed.TotalMilliseconds
        attempts       = $Attempt
        emu_log        = (Get-LatestEmuLog)
        crash_detected = (Get-RecentCrashCount -Minutes 5)
    }

    $deviceJsonPath = Join-Path $sessionDirFull "device.json"
    ($deviceJson | ConvertTo-Json -Depth 5) | Out-File -FilePath $deviceJsonPath -Encoding utf8

    Write-ResultObject $deviceJson
}

function Invoke-Shot {
    if (-not $Name) {
        Write-ErrorResult "missing_name" "-Shot には -Name が必須です。"
    }
    $serial = Assert-Serial
    $sessionDir = Resolve-SessionDir -SessionArg $Session

    if ($DelaySec -gt 0) {
        Start-Sleep -Seconds $DelaySec
    }

    $remotePath = "/sdcard/uiv.png"
    Invoke-Adb -Serial $serial -Arguments @("shell", "screencap", "-p", $remotePath) -StepName "スクリーンショット撮影" -TimeoutSec 15 | Out-Null

    $seq = Get-NextSeq -SessionDir $sessionDir
    $fileName = "${seq}_${Name}.png"
    $localPath = Join-Path $sessionDir $fileName

    Invoke-Adb -Serial $serial -Arguments @("pull", $remotePath, $localPath) -StepName "スクリーンショット転送" -TimeoutSec 20 | Out-Null
    Invoke-Adb -Serial $serial -Arguments @("shell", "rm", $remotePath) -StepName "端末側一時ファイル削除" -TimeoutSec 10 | Out-Null

    if (-not (Test-Path $localPath)) {
        Write-ErrorResult "pull_failed" "スクリーンショットの取得に失敗しました: $remotePath"
    }

    Write-ResultObject ([ordered]@{ ok = $true; file = (Get-RelativePath $localPath) })
}

function Invoke-Tap {
    $serial = Assert-Serial
    $info = Get-DeviceInfoOrFail -Serial $serial
    $px = [int][Math]::Round($X * $info.Width)
    $py = [int][Math]::Round($Y * $info.Height)

    Invoke-Adb -Serial $serial -Arguments @("shell", "input", "tap", $px, $py) -StepName "タップ" -TimeoutSec 10 | Out-Null
    Start-Sleep -Milliseconds 1200

    Write-ResultObject ([ordered]@{ ok = $true; px = $px; py = $py })
}

function Invoke-Swipe {
    $serial = Assert-Serial
    $info = Get-DeviceInfoOrFail -Serial $serial
    $px = [int][Math]::Round($X * $info.Width)
    $py = [int][Math]::Round($Y * $info.Height)
    $px2 = [int][Math]::Round($X2 * $info.Width)
    $py2 = [int][Math]::Round($Y2 * $info.Height)

    Invoke-Adb -Serial $serial -Arguments @("shell", "input", "swipe", $px, $py, $px2, $py2, $DurationMs) -StepName "スワイプ" -TimeoutSec 10 | Out-Null
    Start-Sleep -Milliseconds 1000

    Write-ResultObject ([ordered]@{ ok = $true; from = @($px, $py); to = @($px2, $py2) })
}

function Invoke-Back {
    $serial = Assert-Serial
    Invoke-Adb -Serial $serial -Arguments @("shell", "input", "keyevent", "4") -StepName "戻るキー送信" -TimeoutSec 10 | Out-Null
    Start-Sleep -Milliseconds 1000
    Write-ResultObject ([ordered]@{ ok = $true })
}

function Invoke-Log {
    $serial = Assert-Serial
    $sessionDir = Resolve-SessionDir -SessionArg $Session

    $result = Invoke-Adb -Serial $serial -Arguments @("logcat", "-d", "-v", "time") -StepName "logcat取得" -TimeoutSec 30
    $rawLines = $result.OutLines
    $rawText = $result.Out

    $logPath = Join-Path $sessionDir "logcat_flutter.txt"
    $rawText | Out-File -FilePath $logPath -Encoding utf8

    # 抽出パターン(§C、大文字小文字を区別しない)
    $patterns = [ordered]@{
        overflow          = 'A Render\w+ overflowed by'
        exception         = '(EXCEPTION CAUGHT BY|Unhandled Exception|is not a subtype of type)'
        antigravity_error = '\[Antigravity\].*(エラー|失敗|Error|Exception)'
        image             = '(NetworkImageLoadException|HttpException|SocketException|FormatException)'
    }

    $hits = [ordered]@{
        overflow          = 0
        exception          = 0
        antigravity_error = 0
        image              = 0
    }
    $matchedLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $rawLines) {
        $matchedAny = $false
        foreach ($key in $patterns.Keys) {
            if ($line -imatch $patterns[$key]) {
                $hits[$key] = $hits[$key] + 1
                $matchedAny = $true
            }
        }
        if ($matchedAny -and $matchedLines.Count -lt 20) {
            $matchedLines.Add(($line.Trim()))
        }
    }

    Write-ResultObject ([ordered]@{
        ok    = $true
        file  = (Get-RelativePath $logPath)
        hits  = $hits
        lines = @($matchedLines)
    })
}

function Invoke-Dump {
    if (-not $Name) {
        Write-ErrorResult "missing_name" "-Dump には -Name(画面ID)が必須です。"
    }
    $serial = Assert-Serial
    $sessionDir = Resolve-SessionDir -SessionArg $Session

    $remotePath = "/sdcard/ui.xml"
    Invoke-Adb -Serial $serial -Arguments @("shell", "uiautomator", "dump", $remotePath) -StepName "uiautomator dump" -TimeoutSec 20 | Out-Null

    $localPath = Join-Path $sessionDir "dump_${Name}.xml"
    Invoke-Adb -Serial $serial -Arguments @("pull", $remotePath, $localPath) -StepName "dump転送" -TimeoutSec 20 | Out-Null
    Invoke-Adb -Serial $serial -Arguments @("shell", "rm", $remotePath) -StepName "端末側dumpファイル削除" -TimeoutSec 10 | Out-Null

    $nodeCount = 0
    if (Test-Path $localPath) {
        $content = Get-Content -Raw -Encoding UTF8 -Path $localPath -ErrorAction SilentlyContinue
        if ($content) {
            $nodeCount = ([regex]::Matches($content, '<node ')).Count
        }
    }
    $usable = $nodeCount -gt 2

    Write-ResultObject ([ordered]@{
        ok     = $true
        nodes  = $nodeCount
        file   = (Get-RelativePath $localPath)
        usable = $usable
    })
}

function Invoke-Net {
    if ($State -ne "on" -and $State -ne "off") {
        Write-ErrorResult "invalid_state" "-Net には -State on または -State off が必須です(指定値: '$State')。"
    }
    $serial = Assert-Serial

    if ($State -eq "off") {
        Invoke-Adb -Serial $serial -Arguments @("shell", "svc", "wifi", "disable") -StepName "wifi無効化" -TimeoutSec 10 | Out-Null
        Invoke-Adb -Serial $serial -Arguments @("shell", "svc", "data", "disable") -StepName "モバイルデータ無効化" -TimeoutSec 10 | Out-Null
    } else {
        Invoke-Adb -Serial $serial -Arguments @("shell", "svc", "wifi", "enable") -StepName "wifi有効化" -TimeoutSec 10 | Out-Null
        Invoke-Adb -Serial $serial -Arguments @("shell", "svc", "data", "enable") -StepName "モバイルデータ有効化" -TimeoutSec 10 | Out-Null
    }

    Write-ResultObject ([ordered]@{ ok = $true; state = $State })
}

function Invoke-Info {
    $serial = Assert-Serial
    $info = Get-DeviceInfoOrFail -Serial $serial

    $result = Invoke-Adb -Serial $serial -Arguments @("shell", "dumpsys", "window") -StepName "dumpsys window取得" -TimeoutSec 15
    $focusLine = $result.OutLines | Where-Object { $_ -match "mCurrentFocus" } | Select-Object -First 1
    $focus = ""
    if ($focusLine -and ($focusLine -match '([\w\.]+/[\w\.\$]+)')) {
        $focus = $Matches[1]
    }

    Write-ResultObject ([ordered]@{
        ok      = $true
        width   = $info.Width
        height  = $info.Height
        density = $info.Density
        focus   = $focus
    })
}

# 生存確認だけを安く行う(検証強化設計 §5-2b D-3 #6)。デバイスが見つからない/
# 無応答でも ok は true のまま(呼び出し自体は成功)、alive で判定結果を返す。
function Invoke-Alive {
    $serial = Get-DeviceSerial
    if (-not $serial) {
        Write-ResultObject ([ordered]@{ ok = $true; alive = $false })
        return
    }
    $isAlive = Assert-DeviceAlive -Serial $serial -TimeoutSec 5
    Write-ResultObject ([ordered]@{ ok = $true; alive = $isAlive; serial = $serial })
}

# --- ディスパッチ -------------------------------------------------------

try {
    if ($Prepare) {
        Invoke-Prepare
    } elseif ($Shot) {
        Invoke-Shot
    } elseif ($Tap) {
        Invoke-Tap
    } elseif ($Swipe) {
        Invoke-Swipe
    } elseif ($Back) {
        Invoke-Back
    } elseif ($Log) {
        Invoke-Log
    } elseif ($Dump) {
        Invoke-Dump
    } elseif ($Net) {
        Invoke-Net
    } elseif ($Info) {
        Invoke-Info
    } elseif ($Alive) {
        Invoke-Alive
    } else {
        Write-Verbose2 "使い方: .\tools\ui_probe.ps1 -Prepare [-Retry <n>] | -Shot -Name <名前> | -Tap -X <0..1> -Y <0..1> | -Swipe -X -Y -X2 -Y2 | -Back | -Log | -Dump -Name <画面ID> | -Net -State on|off | -Info | -Alive"
        Write-ErrorResult "no_subcommand" "サブコマンドが指定されていません。"
    }
} catch {
    Write-ErrorResult "unhandled_exception" "予期しないエラー: $($_.Exception.Message)"
}
