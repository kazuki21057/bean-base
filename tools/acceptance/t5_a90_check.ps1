#requires -Version 5.1
<#
.SYNOPSIS
  受け入れスクリプト: T5-A90
.DESCRIPTION
  完了条件(docs/改修マスタープラン.md より):
  「tools/failure_playbook.ps1 のPreflight実行ループが外部プロセス呼び出しをタイムアウト無しで
  同期実行しハングする事故の再発防止として、(1)共通ヘルパー Invoke-ProcessWithTimeout
  (tools/lib/loop_io.ps1)が単体・子孫プロセスとも確実にタイムアウト・強制終了すること、
  (2)night_loop.ps1側の外側タイムアウト(playbookPreflightTimeoutSec)が実地で機能し、
  タイムアウト時に判定不能として記録した上で続行すること、(3)正常系の
  tools/failure_playbook.ps1 -Mode Check が既存どおり動作すること、を確認する」

  検証する4項目:
    1. 単体タイムアウト: 60秒スリープするプロセスを3秒でタイムアウトさせ、
       TimedOut=true・ElapsedSec<10・戻り直後にそのプロセスが存在しないことを確認
    2. 子孫kill確認: 孫プロセスを起こしてから自身もスリープする親を3秒でタイムアウトさせ、
       5秒以内に親・孫とも消えていることを確認(taskkill /T の実効確認)
    3. フェーズ上限の実地確認: playbookPreflightTimeoutSec=10 の一時configと
       BEANBASE_FP_TEST_HANG_SEC=60、BEANBASE_NL_TEST_LOCK_PATH(一時ロック)、
       BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT=1 で tools/night_loop.ps1 -DryRun -Force を
       実行し、9〜30秒以内にexit 0で戻る・wrapper.logに新規のタイムアウトWARNが出る・
       .claude/failure_events.tsv に新規のFP-INTERNAL/timeout_preflight行が出る・
       起動前から存在したプロセス(夜間ループの常駐Watchdog等)を除いて
       failure_playbook.ps1 を含むpowershellプロセスが新規に残らないことを確認
       (差分判定、T5-A97でフレーク対策のため書き換え)
    4. 回帰(正常系): 環境変数なしで tools/failure_playbook.ps1 -Mode Check を実行し、
       60秒以内に終了・stdout最終行がJSONとしてパース可能・exit 0または1であることを確認

  仕様の正本: docs/failure_playbook.md §2-2(設定キー)・§3 FP-03(訂正注記)・§8-3(リスク9)
  実装方法の参考: tools/acceptance/t5_a69_check.ps1 と同じ体裁(BOM付きUTF-8、進捗はstderr、
  stdout最終行に1行JSON)。3番目のケースのみ実際に night_loop.ps1 / failure_playbook.ps1 を
  子プロセスとして起動する(このリポジトリの .claude/night_logs / .claude/failure_events.tsv
  に実書き込みが発生する。テスト用の一時config・BEANBASE_FP_TEST_HANG_SEC・
  BEANBASE_NL_TEST_LOCK_PATH・BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT以外はリポジトリの
  ファイルを書き換えない。実行後に一時ファイル・環境変数を必ず片付ける)。
#>

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = "Continue"

function Write-AcceptanceLog([string]$Message) {
    [Console]::Error.WriteLine("[acceptance] $Message")
}

$taskId = "T5-A90"
$checks = New-Object System.Collections.Generic.List[object]
$originalLocation = (Get-Location).Path
$tempConfigPath = $null
$hangEnvWasSet = $false
$hangEnvOriginal = $null
$nlLockEnvWasSet = $false
$nlLockEnvOriginal = $null
$tempLockPath = $null
$nlStopEnvWasSet = $false
$nlStopEnvOriginal = $null

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
    $loopIoPath = Join-Path $repoRoot "tools\lib\loop_io.ps1"
    $nightLoopPath = Join-Path $repoRoot "tools\night_loop.ps1"
    $failurePlaybookPath = Join-Path $repoRoot "tools\failure_playbook.ps1"
    $nightLoopConfigPath = Join-Path $repoRoot "tools\night_loop.config.json"
    foreach ($p in @($loopIoPath, $nightLoopPath, $failurePlaybookPath)) {
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

    # --- チェック1: 単体タイムアウト ---------------------------------------
    Write-AcceptanceLog "チェック1: 単体タイムアウトを検証中..."
    $marker1 = "t5a90c1_" + [guid]::NewGuid().ToString("N")
    $args1 = '-NoProfile -NonInteractive -Command "Start-Sleep -Seconds 60 # {0}"' -f $marker1
    $r1 = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $args1 -TimeoutSec 3
    Start-Sleep -Milliseconds 300
    $leftover1 = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -match [regex]::Escape($marker1) })
    $ok1 = ([bool]$r1.TimedOut) -and ($r1.ElapsedSec -lt 10) -and ($leftover1.Count -eq 0)
    $checks.Add([ordered]@{
        name   = "単体タイムアウト: TimedOut=true・ElapsedSec<10秒・戻り直後にプロセスが存在しない"
        ok     = [bool]$ok1
        detail = "TimedOut=$($r1.TimedOut), ElapsedSec=$($r1.ElapsedSec), 残存プロセス数=$($leftover1.Count)"
    })

    # --- チェック2: 子孫kill確認 ---------------------------------------------
    Write-AcceptanceLog "チェック2: 子孫プロセスのkillを検証中..."
    $baseSec = Get-Random -Minimum 21000 -Maximum 28000
    $childSec = $baseSec + 1
    $parentSec = $baseSec + 2
    $childInnerArgs = "-NoProfile -NonInteractive -Command Start-Sleep -Seconds $childSec"
    $args2 = '-NoProfile -NonInteractive -Command "Start-Process powershell -ArgumentList ''{0}'' -WindowStyle Hidden; Start-Sleep -Seconds {1}"' -f $childInnerArgs, $parentSec
    $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
    $r2 = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $args2 -TimeoutSec 3
    $sw2.Stop()
    Start-Sleep -Milliseconds 300
    $leftover2 = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and (($_.CommandLine -match "Seconds $childSec") -or ($_.CommandLine -match "Seconds $parentSec")) })
    $ok2 = ([bool]$r2.TimedOut) -and ($leftover2.Count -eq 0) -and ($sw2.Elapsed.TotalSeconds -le 5)
    $checks.Add([ordered]@{
        name   = "子孫kill確認: 親を3秒でタイムアウトさせると5秒以内に親・孫とも消える"
        ok     = [bool]$ok2
        detail = "TimedOut=$($r2.TimedOut), 経過秒=$([math]::Round($sw2.Elapsed.TotalSeconds, 2)), 残存プロセス数=$($leftover2.Count)"
    })

    # --- チェック3: フェーズ上限の実地確認 ------------------------------------
    Write-AcceptanceLog "チェック3: night_loop.ps1側の外側タイムアウトを実地確認中..."
    $tempConfigObj = [ordered]@{}
    if (Test-Path $nightLoopConfigPath) {
        try {
            $existing = Get-Content -Path $nightLoopConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($prop in $existing.PSObject.Properties) { $tempConfigObj[$prop.Name] = $prop.Value }
        } catch {
            Write-AcceptanceLog "既存configの読み込みに失敗したため既定値のみで一時configを作成します: $($_.Exception.Message)"
        }
    }
    $tempConfigObj['playbookPreflightTimeoutSec'] = 10

    $tempConfigPath = Join-Path $env:TEMP ("bb_t5a90_config_" + [guid]::NewGuid().ToString("N") + ".json")
    ($tempConfigObj | ConvertTo-Json -Compress) | Out-File -FilePath $tempConfigPath -Encoding utf8

    $hangEnvOriginal = $env:BEANBASE_FP_TEST_HANG_SEC
    $env:BEANBASE_FP_TEST_HANG_SEC = '60'
    $hangEnvWasSet = $true

    # T5-A97: 多重起動ロックを他プロセスと共有しないよう一時パスへ差し替え、Preflight
    # 完了直後に終了するテストシームを有効化する(いずれもnight_loop.ps1側のテスト専用
    # 環境変数、未設定時は無効)。
    $nlLockEnvOriginal = $env:BEANBASE_NL_TEST_LOCK_PATH
    $tempLockPath = Join-Path $env:TEMP ("bb_t5a90_lock_" + [guid]::NewGuid().ToString("N") + ".lock")
    $env:BEANBASE_NL_TEST_LOCK_PATH = $tempLockPath
    $nlLockEnvWasSet = $true

    $nlStopEnvOriginal = $env:BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT
    $env:BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT = '1'
    $nlStopEnvWasSet = $true

    $todayStamp = Get-Date -Format 'yyyyMMdd'
    $wrapperLogPath = Join-Path $repoRoot (".claude\night_logs\wrapper-{0}.log" -f $todayStamp)
    $eventsPath = Join-Path $repoRoot ".claude\failure_events.tsv"

    # ベースライン取得(差分判定): 夜間ループの常駐Watchdog等、この検証の起動より前から
    # 存在するプロセス・ログ行を新規発生と誤検知しないため、起動前の状態を記録しておく
    # (T5-A97、フレーク対策)。
    $baselinePids = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -match 'failure_playbook\.ps1' } |
        ForEach-Object { $_.ProcessId })
    $wrapperLineCountBefore = 0
    if (Test-Path $wrapperLogPath) {
        $wrapperLineCountBefore = @(Get-Content -Path $wrapperLogPath -ErrorAction SilentlyContinue).Count
    }
    $eventsLineCountBefore = 0
    if (Test-Path $eventsPath) {
        $eventsLineCountBefore = @(Get-Content -Path $eventsPath -ErrorAction SilentlyContinue).Count
    }

    $nightLoopArgs = '-NoProfile -NonInteractive -File "tools\night_loop.ps1" -DryRun -Force -ConfigPath "{0}"' -f $tempConfigPath
    $sw3 = [System.Diagnostics.Stopwatch]::StartNew()
    $r3 = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $nightLoopArgs -TimeoutSec 45 -WorkingDirectory $repoRoot
    $sw3.Stop()

    Remove-Item Env:\BEANBASE_FP_TEST_HANG_SEC -ErrorAction SilentlyContinue
    $hangEnvWasSet = $false
    if ($null -ne $hangEnvOriginal) { $env:BEANBASE_FP_TEST_HANG_SEC = $hangEnvOriginal }

    Remove-Item Env:\BEANBASE_NL_TEST_LOCK_PATH -ErrorAction SilentlyContinue
    $nlLockEnvWasSet = $false
    if ($null -ne $nlLockEnvOriginal) { $env:BEANBASE_NL_TEST_LOCK_PATH = $nlLockEnvOriginal }
    if (Test-Path $tempLockPath) { Remove-Item -Path $tempLockPath -Force -ErrorAction SilentlyContinue }

    Remove-Item Env:\BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT -ErrorAction SilentlyContinue
    $nlStopEnvWasSet = $false
    if ($null -ne $nlStopEnvOriginal) { $env:BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT = $nlStopEnvOriginal }

    $elapsedSec3 = $sw3.Elapsed.TotalSeconds
    # 下限9秒: playbookPreflightTimeoutSec=10 の外側タイムアウトを実際に踏んだことの証拠。
    # これを満たさない場合、多重起動ロック競合等で即終了しただけの偽陽性を拾ってしまう。
    $withinTime3 = ($elapsedSec3 -ge 9) -and ($elapsedSec3 -le 30)
    $exitOk3 = (-not $r3.TimedOut) -and ($r3.ExitCode -eq 0)

    $wrapperHasWarn = $false
    if (Test-Path $wrapperLogPath) {
        $wrapperNewLines = @(Get-Content -Path $wrapperLogPath -ErrorAction SilentlyContinue | Select-Object -Skip $wrapperLineCountBefore)
        $wrapperHasWarn = [bool]($wrapperNewLines | Where-Object {
            $_ -match '10秒以内に終了しなかったため' -and $_ -match '判定不能\(タイムアウト\)'
        })
    }

    $eventsHasLine = $false
    if (Test-Path $eventsPath) {
        $eventsNewLines = @(Get-Content -Path $eventsPath -ErrorAction SilentlyContinue | Select-Object -Skip $eventsLineCountBefore)
        $eventsHasLine = [bool]($eventsNewLines | Where-Object { $_ -match 'FP-INTERNAL' -and $_ -match 'timeout_preflight' })
    }

    # 残存プロセス判定: ベースラインに無い(=今回の起動で新規に生まれた)PIDのみを対象にし、
    # -Mode Watchdog の常駐プロセス(night_loop.ps1:601と同じ除外パターン)は対象外とする
    # (T5-A97)。強制終了の完了を待つため500ms間隔で最大10回ポーリングする。
    $leftover3 = @()
    for ($i = 0; $i -lt 10; $i++) {
        $currentProcs = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -and $_.CommandLine -match 'failure_playbook\.ps1' })
        $leftover3 = @($currentProcs | Where-Object {
            ($baselinePids -notcontains $_.ProcessId) -and ($_.CommandLine -notmatch '-Mode\s+Watchdog')
        })
        if ($leftover3.Count -eq 0) { break }
        Start-Sleep -Milliseconds 500
    }
    $noLeftover3 = ($leftover3.Count -eq 0)

    $ok3 = $withinTime3 -and $exitOk3 -and $wrapperHasWarn -and $eventsHasLine -and $noLeftover3
    $leftoverDetail3 = ""
    if (-not $noLeftover3) {
        $leftoverDetail3 = " 残存詳細=[" + (($leftover3 | ForEach-Object {
            $cmdShort = if ($_.CommandLine.Length -gt 120) { $_.CommandLine.Substring(0, 120) } else { $_.CommandLine }
            "PID=$($_.ProcessId) CMD=$cmdShort"
        }) -join "; ") + "]"
    }
    $checks.Add([ordered]@{
        name   = "フェーズ上限の実地確認: 9〜30秒以内にexit0で戻り、タイムアウトWARN・TSV記録(新規分)があり、新規残存プロセスなし"
        ok     = [bool]$ok3
        detail = ("経過秒={0}, exitOk={1}, wrapperWARN={2}, eventsTSV={3}, 新規残存プロセス数={4}{5}" -f `
            [math]::Round($elapsedSec3, 1), $exitOk3, $wrapperHasWarn, $eventsHasLine, $leftover3.Count, $leftoverDetail3)
    })

    # --- チェック4: 回帰(正常系) ----------------------------------------------
    Write-AcceptanceLog "チェック4: failure_playbook.ps1 -Mode Check の正常系回帰を検証中..."
    $checkArgs = '-NoProfile -NonInteractive -File "tools\failure_playbook.ps1" -Mode Check'
    $sw4 = [System.Diagnostics.Stopwatch]::StartNew()
    $r4 = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $checkArgs -TimeoutSec 60 -WorkingDirectory $repoRoot -Encoding (New-Object System.Text.UTF8Encoding $false)
    $sw4.Stop()
    $withinTime4 = ($sw4.Elapsed.TotalSeconds -le 60) -and (-not $r4.TimedOut)
    $lastLine4 = ((@($r4.StdOut -split "`r?`n" | Where-Object { $_ -and $_.Trim() })) | Select-Object -Last 1)
    $parsedOk4 = $false
    if ($lastLine4) {
        try { $null = $lastLine4 | ConvertFrom-Json -ErrorAction Stop; $parsedOk4 = $true } catch { $parsedOk4 = $false }
    }
    $exitOk4 = ($r4.ExitCode -eq 0) -or ($r4.ExitCode -eq 1)
    $ok4 = $withinTime4 -and $parsedOk4 -and $exitOk4
    $checks.Add([ordered]@{
        name   = "回帰(正常系): -Mode Check が60秒以内・stdout最終行がJSONとしてパース可能・exit 0または1"
        ok     = [bool]$ok4
        detail = "経過秒=$([math]::Round($sw4.Elapsed.TotalSeconds, 1)), ExitCode=$($r4.ExitCode), JSONパース可否=$parsedOk4"
    })

    Set-Location -Path $originalLocation

    # 注意: この環境のPowerShell 5.1では `@($genericListInstance)` をそのまま式として
    # 評価すると「Argument types do not match」で例外になるため(実測で確認済み)、
    # List[object]は直接パイプへ渡すか .ToArray() で明示変換してから使う。
    $failedChecks = @($checks | Where-Object { -not $_.ok })
    $overallOk = ($failedChecks.Count -eq 0)
    $final = [ordered]@{
        task    = $taskId
        ok      = [bool]$overallOk
        skipped = $false
        reason  = ""
        checks  = $checks.ToArray()
    }
    if (-not $overallOk) {
        $failedNames = ($failedChecks | ForEach-Object { $_.name }) -join "; "
        $final.reason = "不合格の項目: $failedNames"
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
    if ($hangEnvWasSet) {
        Remove-Item Env:\BEANBASE_FP_TEST_HANG_SEC -ErrorAction SilentlyContinue
        if ($null -ne $hangEnvOriginal) { $env:BEANBASE_FP_TEST_HANG_SEC = $hangEnvOriginal }
    }
    if ($nlLockEnvWasSet) {
        Remove-Item Env:\BEANBASE_NL_TEST_LOCK_PATH -ErrorAction SilentlyContinue
        if ($null -ne $nlLockEnvOriginal) { $env:BEANBASE_NL_TEST_LOCK_PATH = $nlLockEnvOriginal }
    }
    if ($tempLockPath -and (Test-Path $tempLockPath)) {
        Remove-Item -Path $tempLockPath -Force -ErrorAction SilentlyContinue
    }
    if ($nlStopEnvWasSet) {
        Remove-Item Env:\BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT -ErrorAction SilentlyContinue
        if ($null -ne $nlStopEnvOriginal) { $env:BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT = $nlStopEnvOriginal }
    }
    if ($tempConfigPath -and (Test-Path $tempConfigPath)) {
        Remove-Item -Path $tempConfigPath -Force -ErrorAction SilentlyContinue
    }
}
