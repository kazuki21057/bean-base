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
  対象AVD名。既定値は beanbase_ui(実機相当解像度 1080x2400/density420、T5-A30で作成)。

.PARAMETER TimeoutSec
  起動待機・終了待機のタイムアウト秒数。既定値は 180 秒。

.PARAMETER Doctor
  AVD名/config.iniの主要値/emulator -accel-checkの可否/直近30分のqemu-system-x86_64.exeの
  WER APPCRASH件数を1行のJSONで返す(診断用、状態変更なし)。

.EXAMPLE
  .\tools\emulator.ps1 -Start
.EXAMPLE
  .\tools\emulator.ps1 -Stop
.EXAMPLE
  .\tools\emulator.ps1 -Doctor
#>

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Doctor,
    [string]$AvdName = "beanbase_ui",
    [int]$TimeoutSec = 180
)

$ErrorActionPreference = "Stop"

function Get-AndroidSdkRoot {
    if ($env:ANDROID_SDK_ROOT) { return $env:ANDROID_SDK_ROOT }
    if ($env:ANDROID_HOME) { return $env:ANDROID_HOME }
    return "$env:LOCALAPPDATA\Android\Sdk"
}

function Get-AvdHome {
    if ($env:ANDROID_AVD_HOME) { return $env:ANDROID_AVD_HOME }
    return (Join-Path $env:USERPROFILE ".android\avd")
}

$sdkRoot = Get-AndroidSdkRoot
$emulatorExe = Join-Path $sdkRoot "emulator\emulator.exe"
$adbExe = Join-Path $sdkRoot "platform-tools\adb.exe"
$repoRoot = Split-Path -Parent $PSScriptRoot
$emuLogDir = Join-Path $repoRoot ".claude\emu_logs"

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

function Clear-StaleEmulator {
    Write-Host "残存エミュレータプロセス・ロックファイルを片付けています(AVD: $AvdName)..."

    $staleProcesses = Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue
    if ($staleProcesses) {
        $staleProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "残存プロセスを終了しました(PID: $($staleProcesses.Id -join ', '))。"
    }

    $avdDir = Join-Path (Get-AvdHome) "$AvdName.avd"
    foreach ($lockName in @("hardware-qemu.ini.lock", "multiinstance.lock")) {
        $lockPath = Join-Path $avdDir $lockName
        if (Test-Path $lockPath) {
            Remove-Item -Path $lockPath -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "ロックファイルを削除しました: $lockPath"
        }
    }
}

function Start-Avd {
    Assert-Tooling

    $existing = Get-RunningAvdSerial -Name $AvdName
    if ($existing) {
        Write-Host "AVD '$AvdName' は既に起動しています(シリアル: $existing)。"
        return
    }

    Clear-StaleEmulator

    $availableAvds = & $emulatorExe -list-avds
    if ($availableAvds -notcontains $AvdName) {
        Write-Error "AVD '$AvdName' が見つかりません。作成済みAVD一覧: $($availableAvds -join ', ')"
    }

    if (-not (Test-Path $emuLogDir)) {
        New-Item -ItemType Directory -Path $emuLogDir -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outLog = Join-Path $emuLogDir "${timestamp}_emu_out.log"
    $errLog = Join-Path $emuLogDir "${timestamp}_emu_err.log"

    Write-Host "AVD '$AvdName' を起動しています(通常ウィンドウ表示)。ログ出力先: $outLog / $errLog"
    $process = Start-Process -FilePath $emulatorExe `
        -ArgumentList @("-avd", $AvdName, "-netdelay", "none", "-netspeed", "full", "-no-snapshot", "-no-audio", "-no-boot-anim") `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError $errLog `
        -PassThru
    Write-Host "エミュレータプロセスを起動しました(PID: $($process.Id))。ブート完了を待機します..."

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $serial = $null
    while ((Get-Date) -lt $deadline) {
        if ($process.HasExited) {
            Clear-StaleEmulator
            Write-Error "エミュレータプロセスが起動待機中に終了しました(ExitCode=$($process.ExitCode), ログ=$outLog / $errLog)"
        }
        $serial = Get-RunningAvdSerial -Name $AvdName
        if ($serial) { break }
        Start-Sleep -Seconds 3
    }

    if (-not $serial) {
        Clear-StaleEmulator
        Write-Error "タイムアウト($TimeoutSec 秒)までにAVD '$AvdName' がadbデバイス一覧に現れませんでした。"
    }

    & $adbExe -s $serial wait-for-device | Out-Null

    $booted = $false
    while ((Get-Date) -lt $deadline) {
        if ($process.HasExited) {
            Clear-StaleEmulator
            Write-Error "エミュレータプロセスが起動待機中に終了しました(ExitCode=$($process.ExitCode), ログ=$outLog / $errLog)"
        }
        $bootCompleted = (& $adbExe -s $serial shell getprop sys.boot_completed 2>$null | Select-Object -First 1).Trim()
        if ($bootCompleted -eq "1") {
            $booted = $true
            break
        }
        Start-Sleep -Seconds 3
    }

    if (-not $booted) {
        Clear-StaleEmulator
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

function Invoke-Doctor {
    $result = [ordered]@{
        avdName = $AvdName
        configIni = $null
        accelCheckOutput = $null
        accelCheckOk = $false
        werCrashCount30min = 0
        checkedAt = (Get-Date).ToString("o")
    }

    $configPath = Join-Path (Get-AvdHome) "$AvdName.avd\config.ini"
    if (Test-Path $configPath) {
        $targetKeys = @("hw.lcd.width", "hw.lcd.height", "hw.lcd.density", "hw.device.name", "hw.ramSize", "hw.cpu.ncore", "abi.type")
        $configMap = [ordered]@{}
        foreach ($line in (Get-Content $configPath -ErrorAction SilentlyContinue)) {
            $parts = $line -split "=", 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                if ($targetKeys -contains $key) {
                    $configMap[$key] = $parts[1].Trim()
                }
            }
        }
        $result.configIni = $configMap
    }

    if (Test-Path $emulatorExe) {
        try {
            $accelOutput = & $emulatorExe -accel-check 2>&1 | Out-String
            $result.accelCheckOutput = $accelOutput.Trim()
            $result.accelCheckOk = ($LASTEXITCODE -eq 0)
        } catch {
            $result.accelCheckOutput = "実行エラー: $($_.Exception.Message)"
            $result.accelCheckOk = $false
        }
    } else {
        $result.accelCheckOutput = "emulator.exeが見つかりません: $emulatorExe"
    }

    try {
        $since = (Get-Date).AddMinutes(-30)
        $events = Get-WinEvent -FilterHashtable @{LogName = 'Application'; Id = 1000; StartTime = $since } -ErrorAction SilentlyContinue
        if ($events) {
            $result.werCrashCount30min = ($events | Where-Object { $_.Message -match "qemu-system-x86_64\.exe" }).Count
        }
    } catch {
        $result.werCrashCount30min = 0
    }

    $result | ConvertTo-Json -Compress -Depth 5
}

if ($Start) {
    Start-Avd
} elseif ($Stop) {
    Stop-Avd
} elseif ($Status) {
    Show-Status
} elseif ($Doctor) {
    Invoke-Doctor
} else {
    Write-Host "使い方: .\tools\emulator.ps1 -Start | -Stop | -Status | -Doctor [-AvdName <name>] [-TimeoutSec <sec>]"
}
