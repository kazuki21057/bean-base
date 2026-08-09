#requires -Version 5.1
<#
.SYNOPSIS
  Claude Codeサブエージェント(implementer/adversary/researcher)の一部を
  Google Antigravity CLI(agy、Geminiバックエンド)へヘッドレス委譲するラッパー。
  Claude Pro/Maxプランの利用枠(週次・5時間)を節約する目的で、Geminiバケット側の
  枠が余っているタスクをagyへ逃がす。

  仕様の正本: docs/antigravity_delegation_design.md §9(9.1〜9.7)。
  実装時に判断が必要だった箇所はコード内コメントに "判断:" として明記した。

  対応する Bash/Git Bash 用スクリプト: tools/antigravity_delegate.sh(同一I/F)

  標準出力(stdout)は必ず1行JSONのみ(親が読む唯一の契約)。進捗メッセージは
  すべてstderrへ出す(tools/verify.ps1と同じ流儀)。

  使い方:
    powershell -File tools/antigravity_delegate.ps1 -Role implementer -TaskFile <path> `
      [-Files "a.md,b.md"] [-DoneWhen "..."] [-TaskId T5-A38] [-Model gemini-3.6-flash-high] `
      [-Effort medium] [-TimeoutSec 600] [-WorkDir <path>] [-OutDir .claude\agy_logs] `
      [-SkipQuotaCheck] [-DryRun]
#>

param(
    [string]$Role = "",
    [string]$TaskFile = "",
    [string]$Files = "",
    [string]$DoneWhen = "",
    [string]$TaskId = "",
    [string]$Model = "gemini-3.6-flash-high",
    [string]$Effort = "",
    [int]$TimeoutSec = 600,
    [string]$WorkDir = "",
    [string]$OutDir = ".claude/agy_logs",
    [switch]$SkipQuotaCheck,
    [switch]$DryRun
)

# 標準出力にJSON以外の文字が混じらないよう、進捗メッセージは全てstderrへ出す。
# 日本語(Japanese)を含む出力の文字化けを防ぐため、コンソールの出力エンコーディングを
# UTF-8に固定する(tools/verify.ps1と同じ対処)。
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = "Continue"

function Write-Progress2([string]$Message) {
    [Console]::Error.WriteLine("[antigravity_delegate.ps1] $Message")
}

# --- 準備 -------------------------------------------------------------
$RepoRootRaw = (& git rev-parse --show-toplevel 2>$null)
if (-not $RepoRootRaw) {
    Write-Output '{"ok":false,"exit_code":2,"status":"ARG_ERROR","error":"repo_root_not_found","fallback":false,"fallback_reason":null}'
    exit 2
}
$RepoRoot = $RepoRootRaw.Trim()

function Get-RelativePath([string]$FullPath) {
    $rel = $FullPath
    if ($rel.StartsWith($RepoRoot)) {
        $rel = $rel.Substring($RepoRoot.Length)
    }
    $rel = $rel.TrimStart('\', '/')
    return $rel.Replace('\', '/')
}

# 最終出力(すべての終了パスがこの1つの関数を通る。契約を1箇所に集約する)。
function Write-ResultAndExit {
    param(
        [bool]$Ok,
        [int]$ExitCode,
        [string]$Status,
        [Nullable[double]]$DurationSec = $null,
        [string]$ResponseHead = $null,
        [int]$ResponseChars = 0,
        [string]$ResponseLog = $null,
        [string]$PromptLog = $null,
        [string]$RawLog = $null,
        [string[]]$ChangedFiles = @(),
        $Quota = $null,
        $Tokens = $null,
        [bool]$Fallback = $false,
        [string]$FallbackReason = $null,
        [string]$ErrorMessage = $null
    )

    $obj = [ordered]@{
        ok                 = $Ok
        role               = $Role
        task_id            = $TaskId
        model              = $Model
        exit_code          = $ExitCode
        status             = $Status
        duration_sec       = $DurationSec
        response_chars     = $ResponseChars
        response_head      = $ResponseHead
        response_log       = $ResponseLog
        prompt_log         = $PromptLog
        raw_log            = $RawLog
        changed_files      = @($ChangedFiles)
        changed_file_count = @($ChangedFiles).Count
        quota              = $Quota
        tokens             = $Tokens
        fallback           = $Fallback
        fallback_reason    = $FallbackReason
    }
    if ($ErrorMessage) { $obj["error"] = $ErrorMessage }

    ($obj | ConvertTo-Json -Compress -Depth 10) | Write-Output
    exit $ExitCode
}

# --- 引数バリデーション(exit 2) -------------------------------------------
$AllowedRoles = @('implementer', 'adversary', 'researcher')
if ($AllowedRoles -notcontains $Role) {
    Write-ResultAndExit -Ok $false -ExitCode 2 -Status "ARG_ERROR" `
        -ErrorMessage "-Role は implementer/adversary/researcher のいずれかを指定してください(指定値: '$Role')" `
        -Fallback $false
}

if (-not $TaskFile) {
    Write-ResultAndExit -Ok $false -ExitCode 2 -Status "ARG_ERROR" `
        -ErrorMessage "-TaskFile は必須です" -Fallback $false
}

$TaskFileResolved = $null
foreach ($candidate in @($TaskFile, (Join-Path $RepoRoot $TaskFile))) {
    if (Test-Path $candidate) { $TaskFileResolved = (Resolve-Path $candidate).Path; break }
}
if (-not $TaskFileResolved) {
    Write-ResultAndExit -Ok $false -ExitCode 2 -Status "ARG_ERROR" `
        -ErrorMessage "-TaskFile が見つかりません: $TaskFile" -Fallback $false
}

if (-not $WorkDir) { $WorkDir = $RepoRoot }
if (-not (Test-Path $OutDir)) {
    $OutDirFull = Join-Path $RepoRoot $OutDir
} elseif ([System.IO.Path]::IsPathRooted($OutDir)) {
    $OutDirFull = $OutDir
} else {
    $OutDirFull = Join-Path $RepoRoot $OutDir
}
New-Item -ItemType Directory -Force -Path $OutDirFull | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Progress2 "role=$Role task_id=$TaskId model=$Model dry_run=$($DryRun.IsPresent)"

# --- 台帳(ledger.tsv)への追記 -------------------------------------------
function Add-LedgerRow {
    param(
        [double]$DurationSec = 0,
        [int]$ResponseChars = 0,
        [int]$ChangedFileCount = 0,
        $Quota5hPct = $null
    )
    $ledgerPath = Join-Path $OutDirFull "ledger.tsv"
    if (-not (Test-Path $ledgerPath)) {
        "timestamp`ttask_id`trole`tmodel`texit_code`tduration_sec`tresponse_chars`tchanged_file_count`tquota_5h_pct`tverdict" |
            Out-File -FilePath $ledgerPath -Encoding utf8
    }
    $quotaStr = ""
    if ($null -ne $Quota5hPct) { $quotaStr = "$Quota5hPct" }
    # verdict(ok/ng/fallback)は起動時点では空欄。採否確定後に親が埋める(§9.2)。
    $line = "$Timestamp`t$TaskId`t$Role`t$Model`t$script:ExitCodeForLedger`t$DurationSec`t$ResponseChars`t$ChangedFileCount`t$quotaStr`t"
    Add-Content -Path $ledgerPath -Value $line -Encoding utf8
}

# --- 層2: .claude/agents/<role>.md からYAMLフロントマターを除去して本文を取得 --------
function Get-RoleBody([string]$RoleName) {
    $path = Join-Path $RepoRoot ".claude/agents/$RoleName.md"
    if (-not (Test-Path $path)) { return "" }
    $text = Get-Content -Raw -Encoding UTF8 -Path $path
    if ($text -match '(?s)^---\r?\n.*?\r?\n---\r?\n') {
        $text = $text.Substring($Matches[0].Length)
    }
    return $text.TrimStart("`r", "`n")
}

# --- 層1と層2の間に挟む「agy固有の制約ブロック」(docs/antigravity_delegation_design.md §9.3、文面確定済み・改変しない) ---
$OverrideBlock = @'
## この実行環境での上書き規則(このあとに続く役割定義より優先する)

- あなたはGoogle Antigravity CLI(ヘッドレス)として動いています。ブラウザ操作ツール(claude-in-chrome)は使えません。
- **シェルコマンドの実行は許可されていません。1回も試みないでください。** 後述の役割定義に「セルフチェックを必ず実施」等の指示があっても、`flutter analyze`/`flutter test`/`flutter build`を含め、いかなるシェルコマンドも**実行を試みないでください**(拒否されると応答全体が失敗扱いで打ち切られるため、「試して拒否される」ことすら避ける必要があります)。報告には「シェルコマンドが使えないため未実施」と書くだけにしてください。検証は別のエージェントが行います。
- `git commit`/`git push`/`firebase deploy`/`clasp push`/本番データの削除は**絶対に実行しないでください**。
- 指示された対象ファイル以外を編集しないでください。
- 報告は**日本語**で、**1,200文字以内**にしてください。長い引用・生ログの貼り付けは不要です。
- 報告の最後に、次の3見出しを必ずこの形式で付けてください。

  ```
  ## 変更ファイル
  - <相対パス> (新規|変更)
  ## 保留した判断
  - <指示に無くて決められなかった点。無ければ「なし」>
  ## 未実施
  - <できなかったこと・理由。無ければ「なし」>
  ```
'@

# --- 層3: タスク本文 + Files + DoneWhen + TaskId をプロンプト末尾へ追記 -----------------
# 判断: 見出し構成(## タスク/## 対象ファイル/## 完了条件/## タスクID)は設計書に
# 文面指定が無いため、読みやすさ優先で機械的に組み立てた(ラッパーの実装詳細であり、
# 「フィールド名・画面ID等の仕様」には当たらない判断として実装)。
$FilesList = @()
if ($Files) {
    $FilesList = @($Files -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
$TaskBodyRaw = Get-Content -Raw -Encoding UTF8 -Path $TaskFileResolved

$TaskSectionLines = New-Object System.Collections.Generic.List[string]
$TaskSectionLines.Add("## タスク")
$TaskSectionLines.Add("")
$TaskSectionLines.Add($TaskBodyRaw.TrimEnd())
if ($FilesList.Count -gt 0) {
    $TaskSectionLines.Add("")
    $TaskSectionLines.Add("## 対象ファイル")
    foreach ($f in $FilesList) { $TaskSectionLines.Add("- $f") }
}
if ($DoneWhen) {
    $TaskSectionLines.Add("")
    $TaskSectionLines.Add("## 完了条件")
    $TaskSectionLines.Add($DoneWhen)
}
if ($TaskId) {
    $TaskSectionLines.Add("")
    $TaskSectionLines.Add("## タスクID")
    $TaskSectionLines.Add($TaskId)
}
$TaskSection = ($TaskSectionLines -join "`n")

$RoleBody = Get-RoleBody -RoleName $Role
$FullPrompt = $OverrideBlock + "`n`n" + $RoleBody + "`n`n" + $TaskSection

# プロンプトは常に全文をログへ書く(直接渡す/参照渡しに関わらず、response_logと同様に
# 監査・T5-A41比較用に残す。§9.2「実装上の地雷」)。
$PromptLogPath = Join-Path $OutDirFull "${Timestamp}_${Role}_prompt.md"
$FullPrompt | Out-File -FilePath $PromptLogPath -Encoding utf8
$PromptLogRel = Get-RelativePath $PromptLogPath

# 8,000文字を超える場合はファイル参照渡しに切り替える(§9.2実装上の地雷)。
if ($FullPrompt.Length -le 8000) {
    $PromptArg = $FullPrompt
} else {
    $PromptArg = "${PromptLogRel} を読んで、その指示に従って作業してください。"
    Write-Progress2 "プロンプトが8000文字を超えたため($($FullPrompt.Length)文字)、ファイル参照渡しに切り替えました: $PromptLogRel"
}

# --- DryRun: agyを起動せずプロンプトだけ組み立てて終了 -------------------------------
# 判断: DryRun時の出力スキーマ(status="DRY_RUN"、exit 0固定)は設計書に明記が無いため、
# 「起動しない」という要件を満たす最小の実装として追加した。
if ($DryRun) {
    Write-Progress2 "-DryRun のためagyを起動せずプロンプトのみ出力しました: $PromptLogRel"
    $script:ExitCodeForLedger = 0
    Write-ResultAndExit -Ok $true -ExitCode 0 -Status "DRY_RUN" -DurationSec 0 `
        -ResponseChars 0 -ResponseHead "" -PromptLog $PromptLogRel -Fallback $false
}

# --- agy実行ファイルの探索(agy → agy.exe の順。両方無ければexit 10) -------------------
$AgyCmd = Get-Command agy -ErrorAction SilentlyContinue
if (-not $AgyCmd) { $AgyCmd = Get-Command agy.exe -ErrorAction SilentlyContinue }
if (-not $AgyCmd) {
    Write-Progress2 "agy/agy.exe がPATH上に見つかりません"
    $script:ExitCodeForLedger = 10
    Add-LedgerRow -DurationSec 0 -ResponseChars 0 -ChangedFileCount 0
    Write-ResultAndExit -Ok $false -ExitCode 10 -Status "AGY_NOT_FOUND" -DurationSec 0 `
        -PromptLog $PromptLogRel -Fallback $true `
        -FallbackReason "agy/agy.exeがPATH上に見つかりません。Claude側サブエージェントへ委譲してください。"
}
$AgyExePath = $AgyCmd.Source
Write-Progress2 "agy実行ファイル: $AgyExePath"

# 地雷回避: このPC(Windows PowerShell 5.1.26100.8875)では
# [System.Diagnostics.ProcessStartInfo].GetProperty('ArgumentList') が空を返す、
# つまり .NET 4.6.1+/PowerShell 6+ 向けの `ArgumentList`(コレクション型API)が
# この環境には存在しない。`$psi.ArgumentList.Add($a)` は $psi.ArgumentList が $null
# のまま呼ばれ、$ErrorActionPreference="Continue" のため例外にならず延々とエラーを
# 吐き続けるだけで、結果として agy.exe に引数が1つも渡らずハングし外側タイムアウトに
# 至っていた(T5-A38実地テストで確認)。そのため `$psi.Arguments`(単一文字列プロパティ、
# PowerShell 5.1でも確実に存在)を使い、Windowsのコマンドライン引数解釈規則
# (CommandLineToArgvW互換のバックスラッシュ/ダブルクォートエスケープ)に従って
# 自前でクオートした文字列を組み立てる方式に変更した。
function ConvertTo-ProcessArgumentString {
    param([string[]]$ArgumentList)

    $parts = foreach ($arg in $ArgumentList) {
        if ($null -eq $arg) { $arg = "" }
        if ($arg.Length -eq 0 -or $arg -match '[\s"]') {
            $sb = New-Object System.Text.StringBuilder
            [void]$sb.Append('"')
            $chars = $arg.ToCharArray()
            $i = 0
            while ($i -lt $chars.Length) {
                $numBackslashes = 0
                while ($i -lt $chars.Length -and $chars[$i] -eq '\') {
                    $numBackslashes++
                    $i++
                }
                if ($i -eq $chars.Length) {
                    # 末尾のバックスラッシュは、閉じるダブルクォートの前なので2倍にする。
                    [void]$sb.Append('\', ($numBackslashes * 2))
                    break
                } elseif ($chars[$i] -eq '"') {
                    # ダブルクォートの前のバックスラッシュは2倍+1にしてクォートをエスケープする。
                    [void]$sb.Append('\', ($numBackslashes * 2 + 1))
                    [void]$sb.Append('"')
                    $i++
                } else {
                    [void]$sb.Append('\', $numBackslashes)
                    [void]$sb.Append($chars[$i])
                    $i++
                }
            }
            [void]$sb.Append('"')
            $sb.ToString()
        } else {
            $arg
        }
    }
    return ($parts -join ' ')
}

# 地雷回避: PowerShell 5.1で `2>&1` によるネイティブコマンドのstderr取り込みをしない
# (各行がErrorRecordに包まれ$?が壊れるため)。System.Diagnostics.Processで
# RedirectStandardOutput/RedirectStandardErrorを個別に取り、非同期読み取り
# (BeginOutputReadLine/BeginErrorReadLine)でデッドロックを避ける。
function Invoke-AgyProcess {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        [int]$TimeoutMs
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = ConvertTo-ProcessArgumentString -ArgumentList $ArgumentList
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $stdoutSb = New-Object System.Text.StringBuilder
    $stderrSb = New-Object System.Text.StringBuilder
    $outEvent = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action {
        if ($null -ne $EventArgs.Data) { [void]$Event.MessageData.AppendLine($EventArgs.Data) }
    } -MessageData $stdoutSb
    $errEvent = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action {
        if ($null -ne $EventArgs.Data) { [void]$Event.MessageData.AppendLine($EventArgs.Data) }
    } -MessageData $stderrSb

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $timedOut = $false
    $exitCode = -1
    try {
        $proc.Start() | Out-Null
        $proc.BeginOutputReadLine()
        $proc.BeginErrorReadLine()
        $finished = $proc.WaitForExit($TimeoutMs)
        if (-not $finished) {
            $timedOut = $true
            try { & taskkill /PID $proc.Id /T /F 2>$null | Out-Null } catch {}
            try { $proc.WaitForExit(5000) } catch {}
        } else {
            try { $exitCode = $proc.ExitCode } catch { $exitCode = -1 }
        }
    } catch {
        Write-Progress2 "agyプロセス起動エラー: $($_.Exception.Message)"
    } finally {
        $sw.Stop()
        try { Unregister-Event -SourceIdentifier $outEvent.Name -ErrorAction SilentlyContinue } catch {}
        try { Unregister-Event -SourceIdentifier $errEvent.Name -ErrorAction SilentlyContinue } catch {}
    }

    return [ordered]@{
        ExitCode    = $exitCode
        TimedOut    = $timedOut
        Stdout      = $stdoutSb.ToString()
        Stderr      = $stderrSb.ToString()
        DurationSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    }
}

# --- クォータ事前チェック(§9.2、消費ゼロ) ---------------------------------------------
# 判断: `agy -p "/usage" --output-format json` のJSONスキーマは未確認(§9.7-1)。
# キー名を確定できないため、生テキストに対する緩い正規表現で「weekly」「5h/five hour」
# 近傍の数値を拾うベストエフォート実装とし、見つからなければnull(推測値を書かない)。
# T5-A40のWindows実地確認で生出力を確認したうえで、必要なら厳密なJSONパスに置き換える。
function Get-QuotaPctFromText([string]$Text, [string]$Pattern) {
    $m = [regex]::Match($Text, $Pattern)
    if ($m.Success) { return [double]$m.Groups[1].Value }
    return $null
}

function Invoke-QuotaPreflight {
    $result = Invoke-AgyProcess -FilePath $AgyExePath `
        -ArgumentList @('-p', '/usage', '--output-format', 'json', '--print-timeout', '1m0s') `
        -TimeoutMs 90000
    $quotaRawLogPath = Join-Path $OutDirFull "${Timestamp}_quota_raw.json"
    $result.Stdout | Out-File -FilePath $quotaRawLogPath -Encoding utf8

    if ($result.TimedOut -or $result.ExitCode -ne 0 -or -not $result.Stdout) {
        Write-Progress2 "クォータ事前チェックが取得できませんでした(exit=$($result.ExitCode) timeout=$($result.TimedOut))"
        return [ordered]@{ gemini_weekly_remaining_pct = $null; gemini_5h_remaining_pct = $null; source = "preflight_unavailable" }
    }

    $weekly = Get-QuotaPctFromText -Text $result.Stdout -Pattern '(?i)weekly[^0-9\-]{0,40}(\d+(?:\.\d+)?)'
    $fiveHour = Get-QuotaPctFromText -Text $result.Stdout -Pattern '(?i)(?:5h|5[_ -]?hour|five[_ -]?hour)[^0-9\-]{0,40}(\d+(?:\.\d+)?)'

    if (($null -eq $weekly) -and ($null -eq $fiveHour)) {
        return [ordered]@{ gemini_weekly_remaining_pct = $null; gemini_5h_remaining_pct = $null; source = "preflight_unavailable" }
    }
    return [ordered]@{ gemini_weekly_remaining_pct = $weekly; gemini_5h_remaining_pct = $fiveHour; source = "preflight" }
}

$Quota = $null
if (-not $SkipQuotaCheck) {
    Write-Progress2 "クォータ事前チェック中..."
    $Quota = Invoke-QuotaPreflight
    if (($null -ne $Quota.gemini_weekly_remaining_pct -and $Quota.gemini_weekly_remaining_pct -lt 10) -or
        ($null -ne $Quota.gemini_5h_remaining_pct -and $Quota.gemini_5h_remaining_pct -lt 10)) {
        Write-Progress2 "Geminiクォータが10%未満のため中断します"
        $script:ExitCodeForLedger = 13
        Add-LedgerRow -DurationSec 0 -ResponseChars 0 -ChangedFileCount 0 -Quota5hPct $Quota.gemini_5h_remaining_pct
        Write-ResultAndExit -Ok $false -ExitCode 13 -Status "QUOTA_INSUFFICIENT" -DurationSec 0 `
            -PromptLog $PromptLogRel -Quota $Quota -Fallback $true `
            -FallbackReason "Geminiクォータの週次残または5時間残が10%未満です。Claude側サブエージェントへ委譲してください。"
    }
}

# --- モデル/エフォート/モード ---------------------------------------------------------
# §9.2: モデルIDが -high/-medium/-low で終わる場合は --effort を渡さない(二重指定回避)。
# それ以外のときだけ既定 medium を渡す。ユーザーが明示的に -Effort を指定した場合はそれを尊重する。
$EffortToPass = $null
if ($PSBoundParameters.ContainsKey('Effort') -and $Effort) {
    $EffortToPass = $Effort
} elseif ($Model -notmatch '-(high|medium|low)$') {
    $EffortToPass = "medium"
}

$ModeByRole = @{ implementer = "accept-edits"; adversary = "plan"; researcher = "plan" }
$Mode = $ModeByRole[$Role]

$TimeoutMin = [int][math]::Floor($TimeoutSec / 60)
$TimeoutRemSec = $TimeoutSec % 60
$PrintTimeoutStr = "${TimeoutMin}m${TimeoutRemSec}s"
$OuterTimeoutMs = ($TimeoutSec + 60) * 1000

# --- 実行前のgit status(exit 17判定・changed_files算出用) ----------------------------
$BeforeStatusLines = @(& git -C $RepoRoot status --porcelain 2>$null)

# --- agy本体呼び出し(固定引数: --output-format json / --mode / -p。--dangerously-skip-permissions は絶対に渡さない) ---
$MainArgs = @('-p', $PromptArg, '--output-format', 'json', '--mode', $Mode, '--model', $Model)
if ($EffortToPass) { $MainArgs += @('--effort', $EffortToPass) }
$MainArgs += @('--add-dir', $WorkDir, '--print-timeout', $PrintTimeoutStr)

Write-Progress2 "agy呼び出し開始 mode=$Mode model=$Model effort=$EffortToPass timeout=$PrintTimeoutStr"
$Run = Invoke-AgyProcess -FilePath $AgyExePath -ArgumentList $MainArgs -TimeoutMs $OuterTimeoutMs
Write-Progress2 "agy呼び出し終了 exit=$($Run.ExitCode) timeout=$($Run.TimedOut) duration=$($Run.DurationSec)s"

$RawLogPath = Join-Path $OutDirFull "${Timestamp}_${Role}_raw.json"
$Run.Stdout | Out-File -FilePath $RawLogPath -Encoding utf8
$RawLogRel = Get-RelativePath $RawLogPath

# --- 実行後のgit status差分からchanged_filesを機械的に求める(agyの自己申告を使わない) ---
function Get-ChangedFiles([string[]]$Before, [string[]]$After) {
    $beforeSet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($l in $Before) { if ($l) { [void]$beforeSet.Add($l) } }
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($l in $After) {
        if (-not $l) { continue }
        if ($beforeSet.Contains($l)) { continue }
        if ($l.Length -lt 4) { continue }
        $pathPart = $l.Substring(3)
        if ($pathPart -match '^(.*) -> (.*)$') { $pathPart = $Matches[2] }
        $pathPart = $pathPart.Trim('"')
        $result.Add($pathPart.Replace('\', '/'))
    }
    return @($result | Sort-Object -Unique)
}

$AfterStatusLines = @(& git -C $RepoRoot status --porcelain 2>$null)
$ChangedFiles = Get-ChangedFiles -Before $BeforeStatusLines -After $AfterStatusLines
$ChangedFileCount = @($ChangedFiles).Count

# --- 終了コード判定(§9.4) ------------------------------------------------------------
$ResponseText = $null
$StatusText = $null
$ResponseLogRel = $null

if ($Run.TimedOut) {
    $ExitCode = 11
    $Status = "TIMEOUT"
    $FallbackReason = "agy呼び出しがタイムアウトしました(${TimeoutSec}秒+60秒の外側タイムアウトを超過)"
} else {
    $Parsed = $null
    try { $Parsed = $Run.Stdout | ConvertFrom-Json -ErrorAction Stop } catch {}
    $hasResponseKey = $false
    if ($Parsed) {
        $hasResponseKey = @($Parsed.PSObject.Properties.Name) -contains 'response'
    }

    if (-not $Parsed -or -not $hasResponseKey) {
        $ExitCode = 14
        $Status = "JSON_PARSE_FAILED"
        $FallbackReason = "agyの標準出力がJSONとして解析できない、またはresponseキーがありません"
    } else {
        $StatusText = "$($Parsed.status)"
        $ResponseText = "$($Parsed.response)"
        if ($null -eq $Parsed.response) { $ResponseText = "" }

        $permissionDenied = $false
        if ($Run.Stderr -match [regex]::Escape('permission that headless mode cannot prompt for')) { $permissionDenied = $true }
        if (($StatusText -eq 'SUCCESS') -and [string]::IsNullOrEmpty($ResponseText)) { $permissionDenied = $true }

        if ($permissionDenied) {
            $ExitCode = 12
            $Status = "PERMISSION_DENIED"
            $FallbackReason = "シェルコマンド等の実行がヘッドレスで自動拒否された可能性があります(settings.jsonのpermissions.allow未整備)。ルーティング違反の疑いとして台帳に記録してください。"
        } elseif ($Run.ExitCode -ne 0) {
            $ExitCode = 15
            $Status = "AGY_NONZERO_EXIT"
            $FallbackReason = "agyがゼロ以外の終了コード($($Run.ExitCode))を返しました"
        } elseif (($Role -eq 'implementer') -and ($ChangedFileCount -eq 0)) {
            $ExitCode = 16
            $Status = "NO_CHANGES"
            $FallbackReason = "応答はありましたが変更ファイルが0件でした"
        } elseif ((@('adversary', 'researcher') -contains $Role) -and ($ChangedFileCount -gt 0)) {
            $ExitCode = 17
            $Status = "READONLY_ROLE_CHANGED_FILES"
            $FallbackReason = "読み取り専用役(${Role})のはずが${ChangedFileCount}件のファイル変更が発生しました。自動では復元しません。"
        } else {
            $ExitCode = 0
            $Status = $StatusText
            $FallbackReason = $null
        }
    }
}

# --- 応答本文のログ保存(response_head は800文字で必ず切る) -----------------------------
if ($null -ne $ResponseText) {
    $ResponseLogPath = Join-Path $OutDirFull "${Timestamp}_${Role}_response.md"
    $ResponseText | Out-File -FilePath $ResponseLogPath -Encoding utf8
    $ResponseLogRel = Get-RelativePath $ResponseLogPath
}
$ResponseChars = 0
$ResponseHead = ""
if ($ResponseText) {
    $ResponseChars = $ResponseText.Length
    if ($ResponseChars -gt 800) {
        $ResponseHead = $ResponseText.Substring(0, 800)
    } else {
        $ResponseHead = $ResponseText
    }
}

# --- tokens: agyのJSONに使用量フィールドがあれば拾う。無ければnull(推測値を書かない、§9.2) ---
$Tokens = [ordered]@{ input = $null; output = $null; source = "unavailable" }
if ($Parsed) {
    foreach ($candidate in @('usage', 'tokens', 'token_usage')) {
        $u = $Parsed.$candidate
        if ($u) {
            $inTok = $null; $outTok = $null
            foreach ($k in @('input', 'input_tokens', 'prompt_tokens')) { if ($null -ne $u.$k) { $inTok = $u.$k; break } }
            foreach ($k in @('output', 'output_tokens', 'completion_tokens')) { if ($null -ne $u.$k) { $outTok = $u.$k; break } }
            if (($null -ne $inTok) -or ($null -ne $outTok)) {
                $Tokens = [ordered]@{ input = $inTok; output = $outTok; source = "agy_json" }
            }
            break
        }
    }
}

$Fallback = ($ExitCode -ne 0)
$Ok = ($ExitCode -eq 0)

$script:ExitCodeForLedger = $ExitCode
$Quota5hForLedger = $null
if ($Quota) { $Quota5hForLedger = $Quota.gemini_5h_remaining_pct }
Add-LedgerRow -DurationSec $Run.DurationSec -ResponseChars $ResponseChars -ChangedFileCount $ChangedFileCount -Quota5hPct $Quota5hForLedger

Write-ResultAndExit -Ok $Ok -ExitCode $ExitCode -Status $Status -DurationSec $Run.DurationSec `
    -ResponseChars $ResponseChars -ResponseHead $ResponseHead -ResponseLog $ResponseLogRel `
    -PromptLog $PromptLogRel -RawLog $RawLogRel -ChangedFiles $ChangedFiles -Quota $Quota -Tokens $Tokens `
    -Fallback $Fallback -FallbackReason $FallbackReason
