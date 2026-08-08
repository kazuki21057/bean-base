<#
.SYNOPSIS
  Android実機代わりのAVD「beanbase_test」を起動/停止するスクリプト(Windows版)。
  対となる Ubuntu/Bash 版は tools/emulator.sh。

.DESCRIPTION
  T5-A6(改修マスタープラン)で整備したAndroidエミュレータ環境を、
  非対話・自動化しやすい形で起動/停止するためのラッパー。
  ヘッドレスではなく通常のGUIウィンドウでエミュレータを起動する。

.PARAMETER Start
  AVDを起動し、ブート完了(sys.boot_completed=1)まで待機する。

.PARAMETER Stop
  起動中のAVDをadb経由で正常終了させる。

.PARAMETER Status
  AVDの起動状態を表示する。

.PARAMETER AvdName
  対象AVD名。既定値は beanbase_test。

.PARAMETER TimeoutSec
  起動待機・終了待機のタイムアウト秒数。既定値は 180 秒。

.EXAMPLE
  .\tools\emulator.ps1 -Start
.EXAMPLE
  .\tools\emulator.ps1 -Stop
#>

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [string]$AvdName = "beanbase_test",
    [int]$TimeoutSec = 180
)

$ErrorActionPreference = "Stop"

function Get-AndroidSdkRoot {
    if ($env:ANDROID_SDK_ROOT) { return $env:ANDROID_SDK_ROOT }
    if ($env:ANDROID_HOME) { return $env:ANDROID_HOME }
    return "$env:LOCALAPPDATA\Android\Sdk"
}

$sdkRoot = Get-AndroidSdkRoot
$emulatorExe = Join-Path $sdkRoot "emulator\emulator.exe"
$adbExe = Join-Path $sdkRoot "platform-tools\adb.exe"

function Assert-Tooling {
    if (-not (Test-Path $emulatorExe)) {
        Write-Error "エミュレータ本体が見つかりません: $emulatorExe`n(Android SDKのセットアップ(T5-A6手順)を先に実施してください。ANDROID_SDK_ROOT=$sdkRoot)"
    }
    if (-not (Test-Path $adbExe)) {
        Write-Error "adbが見つかりません: $adbExe`n(platform-toolsのインストールを確認してください。ANDROID_SDK_ROOT=$sdkRoot)"
    }
}

function Get-RunningAvdSerial {
    param([string]$Name)
    $devicesOutput = & $adbExe devices 2>$null
    foreach ($line in $devicesOutput) {
        if ($line -match "^(emulator-\d+)\s+device") {
            $serial = $Matches[1]
            $avdNameOnDeviceRaw = & $adbExe -s $serial emu avd name 2>$null | Select-Object -First 1
            if ($avdNameOnDeviceRaw) {
                $avdNameOnDevice = $avdNameOnDeviceRaw.Trim()
                if ($avdNameOnDevice -eq $Name) {
                    return $serial
                }
            }
        }
    }
    return $null
}

function Start-Avd {
    Assert-Tooling

    $existing = Get-RunningAvdSerial -Name $AvdName
    if ($existing) {
        Write-Host "AVD '$AvdName' は既に起動しています(シリアル: $existing)。"
        return
    }

    $availableAvds = & $emulatorExe -list-avds
    if ($availableAvds -notcontains $AvdName) {
        Write-Error "AVD '$AvdName' が見つかりません。作成済みAVD一覧: $($availableAvds -join ', ')"
    }

    Write-Host "AVD '$AvdName' を起動しています(通常ウィンドウ表示)..."
    $process = Start-Process -FilePath $emulatorExe `
        -ArgumentList @("-avd", $AvdName, "-netdelay", "none", "-netspeed", "full") `
        -PassThru
    Write-Host "エミュレータプロセスを起動しました(PID: $($process.Id))。ブート完了を待機します..."

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $serial = $null
    while ((Get-Date) -lt $deadline) {
        $serial = Get-RunningAvdSerial -Name $AvdName
        if ($serial) { break }
        Start-Sleep -Seconds 3
    }

    if (-not $serial) {
        Write-Error "タイムアウト($TimeoutSec 秒)までにAVD '$AvdName' がadbデバイス一覧に現れませんでした。"
    }

    & $adbExe -s $serial wait-for-device | Out-Null

    $booted = $false
    while ((Get-Date) -lt $deadline) {
        $bootCompleted = (& $adbExe -s $serial shell getprop sys.boot_completed 2>$null | Select-Object -First 1).Trim()
        if ($bootCompleted -eq "1") {
            $booted = $true
            break
        }
        Start-Sleep -Seconds 3
    }

    if (-not $booted) {
        Write-Error "タイムアウト($TimeoutSec 秒)までにAVD '$AvdName' のブートが完了しませんでした(シリアル: $serial)。"
    }

    Write-Host "AVD '$AvdName' の起動が完了しました(シリアル: $serial)。'flutter devices' で確認できます。"
}

function Stop-Avd {
    Assert-Tooling

    $serial = Get-RunningAvdSerial -Name $AvdName
    if (-not $serial) {
        Write-Host "AVD '$AvdName' は起動していません。"
        return
    }

    Write-Host "AVD '$AvdName' を終了しています(シリアル: $serial)..."
    & $adbExe -s $serial emu kill | Out-Null

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (-not (Get-RunningAvdSerial -Name $AvdName)) {
            Write-Host "AVD '$AvdName' を終了しました。"
            return
        }
        Start-Sleep -Seconds 2
    }

    Write-Warning "タイムアウト($TimeoutSec 秒)までにAVD '$AvdName' の終了を確認できませんでした。タスクマネージャーでの確認を推奨します。"
}

function Show-Status {
    Assert-Tooling
    $serial = Get-RunningAvdSerial -Name $AvdName
    if ($serial) {
        Write-Host "AVD '$AvdName' は起動中です(シリアル: $serial)。"
    } else {
        Write-Host "AVD '$AvdName' は停止しています。"
    }
}

if ($Start) {
    Start-Avd
} elseif ($Stop) {
    Stop-Avd
} elseif ($Status) {
    Show-Status
} else {
    Write-Host "使い方: .\tools\emulator.ps1 -Start | -Stop | -Status [-AvdName <name>] [-TimeoutSec <sec>]"
}
