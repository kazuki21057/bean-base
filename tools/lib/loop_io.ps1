<#
    tools/lib/loop_io.ps1 — 夜間ループ共有I/Oヘルパー (T5-A61)

    正本: docs/failure_playbook.md §1-3(既存の仕組みとの関係)・§7 T5-A61行。
    tools/night_loop.ps1 に定義されていた Write-LineWithRetry をここへ切り出した
    (2026-08-12のファイルロック事故対応、commit 77d6094)。tools/night_loop.ps1と
    tools/failure_playbook.ps1 の両方からドットソースして使う共有ヘルパーであり、
    関数名・シグネチャは移設前と一切変更していない(呼び出し側は無変更で動く)。

    使い方(呼び出し元スクリプトの先頭付近で):
      . (Join-Path $PSScriptRoot 'lib\loop_io.ps1')
#>

# ロック耐性のある1行追記ヘルパー。孤児化した tail -f 等がファイルを掴んでいる場合、
# Add-Content の失敗は「非終端エラー」でありtry/catchで捕捉されないケースがある
# (実際に3日間wrapper.logへの記録が無音で失われた障害が発生した)ため、
# -ErrorAction Stop で強制的に終端エラー化してから捕捉する。
function Write-LineWithRetry {
    param(
        [string]$Path,
        [string]$Line,
        [string]$FallbackPath
    )
    $maxAttempts = 3
    $lastError = $null
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            Add-Content -Path $Path -Value $Line -Encoding utf8 -ErrorAction Stop
            return [pscustomobject]@{ Success = $true; ErrorMessage = $null }
        } catch {
            $lastError = $_.Exception.Message
            if ($i -lt $maxAttempts) {
                Start-Sleep -Milliseconds 100
            }
        }
    }
    # 3回とも失敗 → Add-Content と違い一時的な共有違反に強い AppendAllText で
    # フォールバックファイルへ書き込む。
    try {
        [System.IO.File]::AppendAllText($FallbackPath, ($Line + [Environment]::NewLine), [System.Text.Encoding]::UTF8)
    } catch {
        # フォールバックすら失敗した場合は諦める(呼び出し元がWrite-Hostで警告する)。
    }
    return [pscustomobject]@{ Success = $false; ErrorMessage = $lastError }
}

# 外部プロセスをタイムアウト付きで実行する共通ヘルパー (T5-A90)。
#
# 背景: tools/failure_playbook.ps1 のPreflightが、外部プロセス呼び出し(adb/emulator.ps1等)を
# タイムアウト無しで同期実行していたため2026-08-15に約9時間ハングし夜間ループが機能不全になった。
# ReadToEnd()+WaitForExit(ms) の組み合わせはパイプバッファ満杯時にデッドロックしうるため使わず、
# 非同期読み取り(OutputDataReceived/ErrorDataReceived + BeginOutputReadLine/BeginErrorReadLine)で
# stdout/stderrを蓄積する。タイムアウト時は taskkill /T /F でプロセスツリーごと終了する
# (adbはデーモンを孫プロセスとして残すため、$proc.Kill() 単体では取り逃す)。
#
# フェイルオープン(P1): 本関数は例外を投げない。起動失敗・kill失敗もすべて戻り値に載せる。
function Invoke-ProcessWithTimeout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string]$Arguments = '',
        [Parameter(Mandatory = $true)]
        [int]$TimeoutSec,
        [string]$WorkingDirectory = '',
        # 子プロセスの標準出力/標準エラーを読むエンコーディング(省略時は.NET既定に委ねる)。
        # 呼び出し元が対象スクリプトの実際の出力エンコーディングを把握している場合のみ指定する
        # (例: [Console]::OutputEncoding を自前でUTF-8に上書きしているスクリプトへは
        #  [System.Text.Encoding]::UTF8、それ以外の素の子コンソールプロセス〈日本語Windowsの既定は
        #  OEMコードページ〉へは対応するエンコーディングを指定する。実機確認済み、詳細は
        #  呼び出し元コメント参照)。
        [System.Text.Encoding]$Encoding = $null
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $stdOutBuilder = New-Object System.Text.StringBuilder
    $stdErrBuilder = New-Object System.Text.StringBuilder
    $proc = $null
    $timedOut = $false
    $exitCode = -1
    $stdErrExtra = $null

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = $Arguments
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        if ($Encoding) {
            $psi.StandardOutputEncoding = $Encoding
            $psi.StandardErrorEncoding = $Encoding
        }
        if ($WorkingDirectory) {
            $psi.WorkingDirectory = $WorkingDirectory
        }

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi

        $outEvent = Register-ObjectEvent -InputObject $proc -EventName 'OutputDataReceived' -Action {
            if ($null -ne $EventArgs.Data) {
                $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null
            }
        } -MessageData $stdOutBuilder

        $errEvent = Register-ObjectEvent -InputObject $proc -EventName 'ErrorDataReceived' -Action {
            if ($null -ne $EventArgs.Data) {
                $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null
            }
        } -MessageData $stdErrBuilder

        try {
            [void]$proc.Start()
            $proc.BeginOutputReadLine()
            $proc.BeginErrorReadLine()

            $exited = $proc.WaitForExit($TimeoutSec * 1000)
            if (-not $exited) {
                $timedOut = $true
                try {
                    & taskkill /PID $proc.Id /T /F *> $null
                } catch {
                    # taskkill自体の失敗もfail-open(戻り値のTimedOutで呼び出し元へ伝える)
                }
                # taskkill後の後始末を待つ(無期限待機は避ける、短いタイムアウトで十分)。
                $null = $proc.WaitForExit(5000)
            } else {
                try { $exitCode = $proc.ExitCode } catch { $exitCode = -1 }
            }
        } finally {
            if ($outEvent) { Unregister-Event -SourceIdentifier $outEvent.Name -ErrorAction SilentlyContinue }
            if ($errEvent) { Unregister-Event -SourceIdentifier $errEvent.Name -ErrorAction SilentlyContinue }
            if ($outEvent) { Remove-Job -Id $outEvent.Id -Force -ErrorAction SilentlyContinue }
            if ($errEvent) { Remove-Job -Id $errEvent.Id -Force -ErrorAction SilentlyContinue }
        }
    } catch {
        $stdErrExtra = $_.Exception.Message
        $exitCode = -1
    } finally {
        if ($proc) {
            try { $proc.Dispose() } catch {}
        }
    }

    $stopwatch.Stop()

    $stdErrText = $stdErrBuilder.ToString()
    if ($stdErrExtra) {
        if ($stdErrText) { $stdErrText = $stdErrText + [Environment]::NewLine + $stdErrExtra } else { $stdErrText = $stdErrExtra }
    }

    return [pscustomobject]@{
        TimedOut    = $timedOut
        ExitCode    = if ($timedOut) { -2 } else { $exitCode }
        StdOut      = $stdOutBuilder.ToString()
        StdErr      = $stdErrText
        ElapsedSec  = $stopwatch.Elapsed.TotalSeconds
    }
}
