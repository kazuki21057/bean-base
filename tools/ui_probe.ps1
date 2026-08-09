#requires -Version 5.1
<#
.SYNOPSIS
  ui_verifier エージェント専用の Android エミュレータ操作ツール(Windows版)。
  対応する Ubuntu/Bash 版は作らない(Windows専用。理由は設計書§Aの決定6)。

.DESCRIPTION
  9個のサブコマンド(-Prepare/-Shot/-Tap/-Swipe/-Back/-Log/-Dump/-Net/-Info)を
  スイッチパラメータで切り替える。各サブコマンドは標準出力に1行のJSONだけを返す
  (進捗メッセージは Write-Host ではなく標準エラーへ)。ui_verifier エージェントは
  この1行だけを読む。

  エミュレータ本体の起動/停止は tools/emulator.ps1 を呼び出す。ここでは再実装しない。

  仕様の正本: docs/android_release/検証強化設計.md §5-2a
  (implementer はこのファイルの実装にあたり §5-2a を読んだ。仕様変更時は同節を先に直すこと)

.PARAMETER Prepare
  エミュレータ確認/起動 → debug APKビルド(既定) → インストール → ライト固定・
  アニメ無効化 → アプリ起動 → セッションディレクトリ作成、を一括実行する。

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

    # -Prepare 用
    [switch]$SkipBuild,
    [switch]$ClearData,
    [string]$AvdName = "beanbase_test",

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

function Get-DeviceSerial {
    Assert-Adb
    $lines = & $adbExe devices
    foreach ($line in $lines) {
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

# wm size / wm density から解像度・密度・48dp相当pxを取得する。
# ブート直後は adb shell が一時的に "device offline" を返すことがあるため、
# width/height が取れない場合は間隔を空けて最大3回リトライする。
function Get-DeviceInfo([string]$Serial) {
    $width = 0
    $height = 0
    $density = 160

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        # 注: 2>$null 等でネイティブexeのstderrを明示リダイレクトすると、PowerShell 5.1は
        # 各行をErrorRecord化してしまい、$ErrorActionPreference="Stop"下では即座に
        # 終了エラーとして送出される(stderrは元々PowerShellの管理下にないため、
        # リダイレクトせずそのまま流す)。
        $sizeLines = & $adbExe -s $Serial shell wm size
        $densityLines = & $adbExe -s $Serial shell wm density

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
# (エミュレータがクラッシュ/オフラインになっている等)ここで ok:false を返して終了する。
# 呼び出し元で個別にチェックする必要をなくすためのラッパー。
function Get-DeviceInfoOrFail([string]$Serial) {
    $info = Get-DeviceInfo -Serial $Serial
    if ($info.Width -le 0 -or $info.Height -le 0) {
        Write-ErrorResult "device_info_failed" "画面サイズ(wm size/wm density)の取得に失敗しました(width=$($info.Width) height=$($info.Height))。エミュレータがクラッシュ/オフラインになっている可能性があります。"
    }
    return $info
}

# 外部コマンドをタイムアウト付きで実行する(flutter build 用)。verify.ps1 の
# Invoke-LoggedCommand と同じ Start-Process パターン(PowerShell 5.1 では
# ネイティブexeへの 2>&1 がエラーレコード化するため使わない)。
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
        return @{ ExitCode = -1; TimedOut = $false; Tail = "コマンド実行エラー: $($_.Exception.Message)" }
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

    return @{ ExitCode = $exitCode; TimedOut = $timedOut; Tail = $tail }
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

# --- サブコマンド実装 ---------------------------------------------------

function Invoke-Prepare {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Assert-Adb

    # ① tools/emulator.ps1 -Status で起動確認、未起動なら -Start
    $serial = Get-DeviceSerial
    if (-not $serial) {
        Write-Verbose2 "AVD '$AvdName' が未起動のため tools/emulator.ps1 -Start を呼び出します。"
        try {
            & $emulatorScript -Start -AvdName $AvdName 6>&1 | ForEach-Object { Write-Verbose2 "$_" }
        } catch {
            Write-ErrorResult "emulator_start_failed" "tools/emulator.ps1 -Start が失敗しました: $($_.Exception.Message)"
        }
        $serial = Get-DeviceSerial
        if (-not $serial) {
            Write-ErrorResult "emulator_start_failed" "AVD '$AvdName' の起動後もadbデバイスが見つかりませんでした。"
        }
    } else {
        Write-Verbose2 "AVD '$AvdName' は起動中です(シリアル: $serial)。"
    }

    # ② flutter build apk --debug(タイムアウト900秒)
    if (-not $SkipBuild) {
        Write-Verbose2 "flutter build apk --debug を実行します(タイムアウト900秒)。"
        $buildResult = Invoke-TimedProcess -FilePath "flutter" -ArgumentList @("build", "apk", "--debug") -TimeoutMs 900000
        if ($buildResult.TimedOut) {
            Write-ErrorResult "build_timeout" "flutter build apk --debug がタイムアウトしました(900秒)。"
        }
        if ($buildResult.ExitCode -ne 0) {
            Write-ErrorResult "build_failed" "flutter build apk --debug が失敗しました(exit=$($buildResult.ExitCode))。末尾: $($buildResult.Tail)"
        }
    } else {
        Write-Verbose2 "-SkipBuild 指定のためビルドをスキップします。"
    }

    # ③ install
    $apkPath = Join-Path $RepoRoot "build\app\outputs\flutter-apk\app-debug.apk"
    if (-not (Test-Path $apkPath)) {
        Write-ErrorResult "apk_not_found" "APKが見つかりません: $apkPath"
    }
    & $adbExe -s $serial install -r $apkPath | Out-Null

    # ④ ダークモード無効化(ライト固定)
    & $adbExe -s $serial shell cmd uimode night no | Out-Null

    # ⑤ アニメ無効化
    & $adbExe -s $serial shell settings put global window_animation_scale 0 | Out-Null
    & $adbExe -s $serial shell settings put global transition_animation_scale 0 | Out-Null
    & $adbExe -s $serial shell settings put global animator_duration_scale 0 | Out-Null

    # ⑥ -ClearData 指定時のみアプリデータ削除
    if ($ClearData) {
        & $adbExe -s $serial shell pm clear $PackageName | Out-Null
    }

    # ⑦ logcatクリア
    & $adbExe -s $serial logcat -c

    # ⑧ 強制停止
    & $adbExe -s $serial shell am force-stop $PackageName | Out-Null

    # ⑨ 起動
    & $adbExe -s $serial shell am start -W -n $MainActivity | Out-Null

    # ⑩ 6秒待機
    Start-Sleep -Seconds 6

    # ⑪ セッションディレクトリ作成
    $sessionName = Get-Date -Format "yyyyMMdd_HHmmss"
    $sessionRel = ".claude/ui_verify/$sessionName"
    $sessionDirFull = Join-Path $RepoRoot ".claude\ui_verify\$sessionName"
    New-Item -ItemType Directory -Force -Path $sessionDirFull | Out-Null

    $info = Get-DeviceInfoOrFail -Serial $serial
    $sw.Stop()

    $deviceJson = [ordered]@{
        ok         = $true
        session    = $sessionRel
        serial     = $serial
        width      = $info.Width
        height     = $info.Height
        density    = $info.Density
        tap48dp_px = $info.Tap48dpPx
        launch_ms  = [int]$sw.Elapsed.TotalMilliseconds
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
    & $adbExe -s $serial shell screencap -p $remotePath | Out-Null

    $seq = Get-NextSeq -SessionDir $sessionDir
    $fileName = "${seq}_${Name}.png"
    $localPath = Join-Path $sessionDir $fileName

    & $adbExe -s $serial pull $remotePath $localPath | Out-Null
    & $adbExe -s $serial shell rm $remotePath | Out-Null

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

    & $adbExe -s $serial shell input tap $px $py | Out-Null
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

    & $adbExe -s $serial shell input swipe $px $py $px2 $py2 $DurationMs | Out-Null
    Start-Sleep -Milliseconds 1000

    Write-ResultObject ([ordered]@{ ok = $true; from = @($px, $py); to = @($px2, $py2) })
}

function Invoke-Back {
    $serial = Assert-Serial
    & $adbExe -s $serial shell input keyevent 4 | Out-Null
    Start-Sleep -Milliseconds 1000
    Write-ResultObject ([ordered]@{ ok = $true })
}

function Invoke-Log {
    $serial = Assert-Serial
    $sessionDir = Resolve-SessionDir -SessionArg $Session

    $rawLines = & $adbExe -s $serial logcat -d -v brief
    $rawText = ($rawLines -join "`n")

    $logPath = Join-Path $sessionDir "logcat_flutter.txt"
    $rawText | Out-File -FilePath $logPath -Encoding utf8

    # 抽出パターン(§C、大文字小文字を区別しない)
    $patterns = [ordered]@{
        overflow          = 'A RenderFlex overflowed'
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
    & $adbExe -s $serial shell uiautomator dump $remotePath | Out-Null

    $localPath = Join-Path $sessionDir "dump_${Name}.xml"
    & $adbExe -s $serial pull $remotePath $localPath | Out-Null
    & $adbExe -s $serial shell rm $remotePath | Out-Null

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
        & $adbExe -s $serial shell svc wifi disable | Out-Null
        & $adbExe -s $serial shell svc data disable | Out-Null
    } else {
        & $adbExe -s $serial shell svc wifi enable | Out-Null
        & $adbExe -s $serial shell svc data enable | Out-Null
    }

    Write-ResultObject ([ordered]@{ ok = $true; state = $State })
}

function Invoke-Info {
    $serial = Assert-Serial
    $info = Get-DeviceInfoOrFail -Serial $serial

    $windowLines = & $adbExe -s $serial shell dumpsys window
    $focusLine = $windowLines | Where-Object { $_ -match "mCurrentFocus" } | Select-Object -First 1
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
    } else {
        Write-Verbose2 "使い方: .\tools\ui_probe.ps1 -Prepare | -Shot -Name <名前> | -Tap -X <0..1> -Y <0..1> | -Swipe -X -Y -X2 -Y2 | -Back | -Log | -Dump -Name <画面ID> | -Net -State on|off | -Info"
        Write-ErrorResult "no_subcommand" "サブコマンドが指定されていません。"
    }
} catch {
    Write-ErrorResult "unhandled_exception" "予期しないエラー: $($_.Exception.Message)"
}
