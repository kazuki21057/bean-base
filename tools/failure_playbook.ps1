#requires -Version 5.1
<#
    tools/failure_playbook.ps1 — 失敗プレイブック(T5-A61、骨格)

    正本: docs/failure_playbook.md(§2 全体構成、§3 既知障害の一覧、§7 T5-A61行)。
    無人夜間ループ(tools/night_loop.ps1)の既知障害を検知し、安全な範囲でのみ
    自動対処する。設計判断は docs/failure_playbook.md で確定済みのため、本スクリプトは
    その記述どおりに実装する。

    このスクリプト(T5-A61時点)で実装済みのルール:
      -Mode Preflight のみ、かつ次の3ルールのみ
        - FP-01-FILELOCK(シグネチャA・Bのみ。Cの孤児プロセス列挙はT5-A61の対象外)
        - FP-02-BOM(シグネチャB・Cのみ。AはPostToolUseフック側なので対象外)
        - FP-07-MISSINGBIN(表の全行)
      -Mode Watchdog / Postmortem / Check は引数としては受け付けるが、対応するルールが
      まだ無いため検知0件のまま正常終了する(後続タスクT5-A62〜A66で実装する)。

    標準出力は1行JSONのみ(§2-3)。人間向けメッセージは Write-Host ではなく
    [Console]::Error へ出す(進捗の可視化用、契約はstdoutの1行JSONのみ)。

    終了コード(§2-3):
      0  検知なし、または自動対処が成功した
      1  検知したが続行可能(warn / 人間への申し送りあり)
      2  続行不可(FP-07の必須バイナリ不在・ディスク空き不足のみ。他ルールは絶対にabortしない)

    フェイルオープン(P1): このスクリプト自身の例外でループを止めてはならない。
    トップレベルを try/catch で包み、catch では failure_events.tsv に
    ruleId=FP-INTERNAL を1行書いて exit 0 する。

    使い方:
      powershell -File tools\failure_playbook.ps1 -Mode Preflight
      powershell -File tools\failure_playbook.ps1 -Mode Preflight -Unattended
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Preflight', 'Watchdog', 'Postmortem', 'Check')]
    [string]$Mode,
    [int]$WrapperPid = $PID,
    [string]$StreamLogPath = '',
    [string]$ErrLogPath = '',
    [int]$ClaudeExitCode = 0,
    [int]$StallMinutes = 20,
    [int]$HardCapMinutes = 90,
    [switch]$Unattended,
    [string]$ConfigPath = ''
)

# 標準出力にJSON以外の文字が混じらないよう、進捗メッセージは全て[Console]::Errorへ出す。
# 日本語を含む出力の文字化けを防ぐため、コンソール出力エンコーディングをUTF-8に固定する
# (tools/antigravity_delegate.ps1 と同じ対処)。
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = 'Stop'

function Write-Progress2 {
    param([string]$Message)
    [Console]::Error.WriteLine("[failure_playbook.ps1] $Message")
}

# --- 基本パス ---
$RepoRoot = Split-Path -Parent $PSScriptRoot
$LoopIoPath = Join-Path $PSScriptRoot 'lib\loop_io.ps1'

# tools/lib/loop_io.ps1 専用の最小限のBOM事前チェック・修復(ドットソースより前)。
# 背景: FP-02-BOMルール本体(下記ルールエンジン)はこのドットソースの後でしか動かないため、
# loop_io.ps1自身がBOMを喪失するとドットソース時点でパースエラーとなりフェイルオープン経路
# (直後のcatch)へ落ち、最も重要なはずのこのファイルへの自動修復が機能しない。そのため
# FP-02-BOMのRepairロジックと同じ処理(内容は1バイトも変えずBOM 0xEF,0xBB,0xBFを先頭に付与)を
# ここで単独実行する。Write-LineWithRetry等はまだ読み込まれていないため、failure_events.tsvへの
# 正式な記録は行わず[Console]::Errorへの1行メッセージのみとする(通常のFP-02-BOM検知・記録の
# 仕組みとは別経路のブートストラップ処理)。
if (Test-Path $LoopIoPath) {
    try {
        $loopIoBytes = [System.IO.File]::ReadAllBytes($LoopIoPath)
        $loopIoHasBom = ($loopIoBytes.Length -ge 3 -and $loopIoBytes[0] -eq 0xEF -and $loopIoBytes[1] -eq 0xBB -and $loopIoBytes[2] -eq 0xBF)
        if (-not $loopIoHasBom) {
            [System.IO.File]::WriteAllBytes($LoopIoPath, (@(0xEF, 0xBB, 0xBF) + $loopIoBytes))
            [Console]::Error.WriteLine("[failure_playbook.ps1] tools/lib/loop_io.ps1 のBOM喪失を検知し、ドットソース前に自己修復しました。")
        }
    } catch {
        # 事前修復に失敗しても後続のドットソース用try/catch(フェイルオープン)に処理を委ねる
    }
}

# tools/night_loop.ps1 と共有するロック耐性I/Oヘルパー(Write-LineWithRetry)。
# T5-A61でtools/night_loop.ps1からここへ移設した(docs/failure_playbook.md §1-3・§7)。
# フェイルオープン(P1): このドットソース自体をtry/catchで包む。トップレベルのtry(下記)の
# 外側にあるため、ここで例外を捕まえないとlib\loop_io.ps1の不在・読み込み失敗が未捕捉例外と
# なりスクリプトが異常終了してしまう。catch側ではloop_io.ps1側の関数(Write-LineWithRetry等)に
# まだ依存できないため、[Console]::Errorへの警告出力と自己完結した1行JSONの出力のみで exit 0 する。
try {
    . $LoopIoPath
} catch {
    $loopIoErrorMessage = $_.Exception.Message
    [Console]::Error.WriteLine("[failure_playbook.ps1] tools/lib/loop_io.ps1 の読み込みに失敗しました。fail-openの方針によりexit 0で終了します: $loopIoErrorMessage")
    $loopIoFallbackObj = [ordered]@{
        ok            = $true
        phase         = $Mode.ToLower()
        detected      = @()
        escalate      = $false
        escalations   = @()
        internalError = "loop_io.ps1の読み込みに失敗: $loopIoErrorMessage"
    }
    ($loopIoFallbackObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
    exit 0
}

$ClaudeDir = Join-Path $RepoRoot '.claude'
$NightLogsDir = Join-Path $ClaudeDir 'night_logs'
$EventsPath = Join-Path $ClaudeDir 'failure_events.tsv'
$StatePath = Join-Path $ClaudeDir 'failure_state.json'
$ReportsDir = Join-Path $ClaudeDir 'failure_reports'

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $RepoRoot 'tools\failure_playbook.config.json'
}

$PhaseLower = $Mode.ToLower()

# ============================== 設定読み込み(§2-2) ==============================
# tools/night_loop.config.json と同じ方針: 無ければ既定値で続行する。
function Get-PlaybookConfig {
    param([string]$Path)
    $defaults = @{
        autoKillLockHolders = $false
    }
    if (Test-Path $Path) {
        try {
            $loaded = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($prop in $loaded.PSObject.Properties) {
                $defaults[$prop.Name] = $prop.Value
            }
        } catch {
            Write-Progress2 "設定ファイル $Path の読み込みに失敗したため既定値を使用します: $($_.Exception.Message)"
        }
    }
    return $defaults
}
$Config = Get-PlaybookConfig -Path $ConfigPath

# ============================== 記録層(§2-4) ==============================

function Ensure-Dirs {
    if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }
    if (-not (Test-Path $NightLogsDir)) { New-Item -ItemType Directory -Path $NightLogsDir -Force | Out-Null }
    if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
}

function Ensure-EventsFile {
    Ensure-Dirs
    if (-not (Test-Path $EventsPath)) {
        $header = "timestamp`tphase`truleId`tseverity`taction`tresult`tdetail"
        $fallback = Join-Path $NightLogsDir ('failure_events.fallback-{0}.tsv' -f $PID)
        Write-LineWithRetry -Path $EventsPath -Line $header -FallbackPath $fallback | Out-Null
    }
}

function Write-FailureEvent {
    param(
        [string]$Phase,
        [string]$RuleId,
        [string]$Severity,
        [string]$Action,
        [string]$Result,
        [string]$Detail
    )
    Ensure-EventsFile
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    # タブ・改行がdetailに混入するとTSVの列がずれるため置換する。
    $safeDetail = ($Detail -replace "[`t`r`n]", ' ')
    $line = "$ts`t$Phase`t$RuleId`t$Severity`t$Action`t$Result`t$safeDetail"
    $fallback = Join-Path $NightLogsDir ('failure_events.fallback-{0}.tsv' -f $PID)
    Write-LineWithRetry -Path $EventsPath -Line $line -FallbackPath $fallback | Out-Null
}

function Get-FailureState {
    if (Test-Path $StatePath) {
        try {
            return (Get-Content -Path $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json)
        } catch {
            Write-Progress2 "状態ファイルの読み込みに失敗したため新規作成します: $($_.Exception.Message)"
        }
    }
    return [pscustomobject]@{}
}

function Save-FailureState {
    param($State)
    Ensure-Dirs
    try {
        ($State | ConvertTo-Json -Depth 10) | Set-Content -Path $StatePath -Encoding utf8
    } catch {
        Write-Progress2 "状態ファイルの保存に失敗しました: $($_.Exception.Message)"
    }
}

# ルールごとの連続回数・最終状態を更新する(§2-4のfailure_state.jsonスキーマ)。
function Update-RuleState {
    param(
        $State,
        [string]$RuleId,
        [bool]$Triggered,
        [string]$LastAction,
        [string]$LastResult,
        [int]$MaxAutoAttempts
    )
    $now = (Get-Date).ToString('s')
    if (-not ($State.PSObject.Properties.Name -contains $RuleId)) {
        $entry = [pscustomobject]@{
            consecutive = 0
            lastAt      = $null
            lastAction  = $null
            lastResult  = $null
            escalated   = $false
        }
        $State | Add-Member -NotePropertyName $RuleId -NotePropertyValue $entry -Force
    }
    $entry = $State.$RuleId
    if ($Triggered) {
        $entry.consecutive = [int]$entry.consecutive + 1
        $entry.lastAt = $now
        $entry.lastAction = $LastAction
        $entry.lastResult = $LastResult
        if ($MaxAutoAttempts -gt 0 -and $entry.consecutive -gt $MaxAutoAttempts) {
            $entry.escalated = $true
        }
    } else {
        $entry.consecutive = 0
        $entry.escalated = $false
    }
}

# ============================== ルール登録簿(§2-5) ==============================
# 別JSONに切り出さず、スクリプト内のPowerShell配列として持つ(シグネチャと対処コードを
# 離さない)。T5-A61ではPreflight向けの3ルールのみ実装する。
$Rules = @(
    @{
        Id              = 'FP-01-FILELOCK'
        Title           = 'ログファイルのロック(孤児プロセスによる共有違反)'
        Phase           = @('Preflight')
        Severity        = 'auto'
        # シグネチャAの切替のみ自動、Bは記録のみ。連続回数による自動escalateは
        # 本ルールでは使わない(切替失敗時に即escalateする個別ロジックを持つため)。
        MaxAutoAttempts = 999
        Detect          = {
            $findings = @()
            # シグネチャA: 排他ロックの実測(docs/failure_playbook.md §3 FP-01表)
            $targets = @(
                (Join-Path $NightLogsDir ('wrapper-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))),
                (Join-Path $ClaudeDir 'night_runs.log'),
                (Join-Path $ClaudeDir 'night_skips.log'),
                (Join-Path $ClaudeDir 'night_usage_log.tsv'),
                (Join-Path $ClaudeDir 'night_outcomes.log'),
                (Join-Path $ClaudeDir 'night_loop_last_run.json'),
                (Join-Path $RepoRoot 'night_report.md')
            )
            foreach ($t in $targets) {
                if (-not (Test-Path $t)) { continue }
                try {
                    $stream = [System.IO.File]::Open($t, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
                    $stream.Close()
                } catch [System.IO.IOException] {
                    $hr = $_.Exception.HResult -band 0xFFFF
                    if ($hr -eq 32 -or $hr -eq 33) {
                        $findings += "A|$t|共有違反を検知しました(HResult下位16bit=$hr)"
                    }
                } catch {
                    # IOException以外は本ルールの対象外(fail-open、見逃す)
                }
            }
            # シグネチャB: フォールバックログの存在(直近24時間以内=前回発火で回避が発動した痕跡)
            $fallbackPatterns = @('wrapper.fallback-*.log', 'night_skips.fallback-*.log', 'night_usage_log.fallback-*.log')
            foreach ($pattern in $fallbackPatterns) {
                $fbFiles = Get-ChildItem -Path $NightLogsDir -Filter $pattern -ErrorAction SilentlyContinue
                foreach ($fb in $fbFiles) {
                    if ($fb.LastWriteTime -ge (Get-Date).AddHours(-24)) {
                        $findings += "B|$($fb.FullName)|フォールバックログが直近24時間以内に生成されています(前回の発火でロック回避が発動した痕跡)"
                    }
                }
            }
            $findings
        }
        Repair          = {
            param($detail)
            $parts = $detail -split '\|', 3
            $kind = $parts[0]; $path = $parts[1]; $msg = $parts[2]
            if ($kind -eq 'A') {
                # 連番サフィックス付き新規パスへ書き込み先を切替する(冪等・非破壊・
                # 誤爆時は「ログが1本増えるだけ」なので4条件を満たす、§3 FP-01)。
                $dir = Split-Path -Parent $path
                $base = [System.IO.Path]::GetFileNameWithoutExtension($path)
                $ext = [System.IO.Path]::GetExtension($path)
                $newPath = $null
                for ($n = 2; $n -le 50; $n++) {
                    $candidate = Join-Path $dir ('{0}-{1}{2}' -f $base, $n, $ext)
                    if (-not (Test-Path $candidate)) { $newPath = $candidate; break }
                }
                if (-not $newPath) {
                    return @{ Action = 'switch_failed'; Result = 'escalate'; Detail = "$path の切替候補パスが50件とも既に存在します" }
                }
                try {
                    New-Item -ItemType File -Path $newPath -Force | Out-Null
                    return @{ Action = 'switched'; Result = 'ok'; Detail = "$path はロックされているため $newPath へ書き込み先の切替を記録しました。$msg" }
                } catch {
                    # 切替先にも書けない = その場でescalate(自動リトライ0回、§3 FP-01)
                    return @{ Action = 'switch_failed'; Result = 'escalate'; Detail = "$path の切替に失敗しました: $($_.Exception.Message)" }
                }
            } else {
                # シグネチャB: kill等の自動対処はしない。記録のみ(§3 FP-01)。
                return @{ Action = 'none'; Result = 'warned'; Detail = "$path — $msg(自動対処なし、記録のみ)" }
            }
        }
    },
    @{
        Id              = 'FP-02-BOM'
        Title           = '.ps1 の UTF-8 BOM 喪失'
        Phase           = @('Preflight')
        Severity        = 'auto'
        MaxAutoAttempts = 1
        Detect          = {
            $findings = @()
            if ($Mode -eq 'Preflight') {
                $targetFiles = @()
                $toolsDir = Join-Path $RepoRoot 'tools'
                if (Test-Path $toolsDir) {
                    $targetFiles += Get-ChildItem -Path $toolsDir -Filter '*.ps1' -File -Recurse -ErrorAction SilentlyContinue
                }
                $hooksDir = Join-Path $ClaudeDir 'hooks'
                if (Test-Path $hooksDir) {
                    $targetFiles += Get-ChildItem -Path $hooksDir -Filter '*.ps1' -File -ErrorAction SilentlyContinue
                }
            } else {
                # Postmortem/Check(git diff起点の対象抽出)はT5-A61の対象外。
                $targetFiles = @()
            }
            foreach ($f in $targetFiles) {
                $path = $f.FullName
                try {
                    $bytes = [System.IO.File]::ReadAllBytes($path)
                } catch {
                    continue
                }
                $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
                if (-not $hasBom) {
                    # シグネチャB: BOM喪失
                    $findings += "BOM|$path|BOMが付与されていません"
                } else {
                    # シグネチャC: BOMはあるが構文エラーが残っている(BOM以外の破損)
                    $errs = $null; $tokens = $null
                    [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errs)
                    if ($errs -and $errs.Count -gt 0) {
                        $findings += "PARSEERR|$path|BOMは付与済みですがParseFileエラーが$($errs.Count)件あります"
                    }
                }
            }
            $findings
        }
        Repair          = {
            param($detail)
            $parts = $detail -split '\|', 3
            $kind = $parts[0]; $path = $parts[1]; $msg = $parts[2]
            if ($kind -eq 'BOM') {
                try {
                    $bytes = [System.IO.File]::ReadAllBytes($path)
                    $bomBytes = [byte[]](0xEF, 0xBB, 0xBF)
                    # 内容は1バイトも変更せず、先頭にBOMを付与して書き戻す(§3 FP-02)。
                    [System.IO.File]::WriteAllBytes($path, ($bomBytes + $bytes))
                    $errs = $null; $tokens = $null
                    [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errs)
                    if ($errs -and $errs.Count -gt 0) {
                        # 修復後もParseFileエラーが残る場合はBOM以外の破損。修復を打ち切りescalate
                        # (該当ファイルはこれ以上触らない、§3 FP-02)。
                        return @{ Action = 'repaired_bom_only'; Result = 'escalate'; Detail = "$path にBOMを再付与しましたがParseFileエラーが$($errs.Count)件残っています(BOM以外の破損の疑い)" }
                    }
                    return @{ Action = 'repaired'; Result = 'ok'; Detail = "$path にBOMを再付与し、ParseFileエラー0件を確認しました" }
                } catch {
                    return @{ Action = 'repair_failed'; Result = 'escalate'; Detail = "$path のBOM修復に失敗しました: $($_.Exception.Message)" }
                }
            } else {
                # PARSEERR単独(BOMは既にある)はBOM修復では直せないため即escalate
                return @{ Action = 'none'; Result = 'escalate'; Detail = "$path — $msg" }
            }
        }
    },
    @{
        Id              = 'FP-07-MISSINGBIN'
        Title           = '必須バイナリ不在・ディスク空き不足'
        Phase           = @('Preflight')
        Severity        = 'auto'
        MaxAutoAttempts = 999
        Detect          = {
            $findings = @()
            # claude/git/flutter/dart 不在 → exit 2(abort、§3 FP-07表)
            $abortBins = @('claude', 'git', 'flutter', 'dart')
            foreach ($b in $abortBins) {
                if (-not (Get-Command $b -ErrorAction SilentlyContinue)) {
                    $findings += "ABORT|$b|必須バイナリ $b がPATH上に見つかりません"
                }
            }
            # node/adb/emulator 不在 → exit 1(warn、Android検証やFP-03の自動対処が無効化される)
            $warnBins = @('node', 'adb', 'emulator')
            foreach ($b in $warnBins) {
                if (-not (Get-Command $b -ErrorAction SilentlyContinue)) {
                    $findings += "WARN|$b|バイナリ $b がPATH上に見つかりません"
                }
            }
            # agy 不在 → exit 0 + auto(委譲先をClaude固定にする旨を記録するだけの無害な縮退)
            if (-not (Get-Command 'agy' -ErrorAction SilentlyContinue)) {
                $findings += 'AUTOAGY|agy|agy がPATH上に見つかりません'
            }
            # ディスク空き2GB未満 → exit 2(abort)
            try {
                $rootItem = Get-Item -LiteralPath $RepoRoot -ErrorAction Stop
                $driveName = $rootItem.PSDrive.Name
                if ($driveName) {
                    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($driveName):'" -ErrorAction SilentlyContinue
                    if ($disk -and $disk.FreeSpace) {
                        $freeGb = [math]::Round(($disk.FreeSpace / 1GB), 2)
                        if ($freeGb -lt 2) {
                            $findings += "ABORT|diskfree|ディスク空きが${freeGb}GBしかありません(2GB未満)"
                        }
                    }
                }
            } catch {
                # ディスク情報が取得できない場合はfail-openで見逃す(検知しない)
            }
            # .claude/settings.night.json の存在・JSON妥当性チェックは既存実装
            # (tools/night_loop.ps1 手順7)をそのまま使い、ここでは重複検査しない(§3 FP-07表)。
            $findings
        }
        Repair          = {
            param($detail)
            $parts = $detail -split '\|', 3
            $kind = $parts[0]; $name = $parts[1]; $msg = $parts[2]
            switch ($kind) {
                'ABORT' { return @{ Action = 'none'; Result = 'abort'; Detail = $msg } }
                'WARN' { return @{ Action = 'none'; Result = 'warned'; Detail = $msg } }
                'AUTOAGY' { return @{ Action = 'fallback_claude_fixed'; Result = 'ok'; Detail = "$msg 。委譲先をClaude固定として記録しました(agy不在時の無害な縮退)" } }
                default { return @{ Action = 'none'; Result = 'warned'; Detail = $detail } }
            }
        }
    }
)

# ============================== メイン処理 ==============================
try {
    Write-Progress2 "モード=$Mode で開始します。"
    Ensure-EventsFile
    $State = Get-FailureState

    $detected = @()
    $escalations = @()
    $abort = $false
    $anyUnresolved = $false

    foreach ($rule in $Rules) {
        if ($rule.Phase -notcontains $Mode) { continue }

        $findings = @()
        try {
            $findings = @(& $rule.Detect)
        } catch {
            Write-Progress2 "ルール $($rule.Id) の検知処理で例外が発生したためスキップします: $($_.Exception.Message)"
            continue
        }

        $triggered = ($findings.Count -gt 0)
        $lastAction = $null
        $lastResult = $null

        foreach ($f in $findings) {
            $outcome = @{ Action = 'none'; Result = 'warned'; Detail = $f }
            if ($rule.Severity -eq 'auto') {
                try {
                    $r = & $rule.Repair $f
                    if ($r) { $outcome = $r }
                } catch {
                    $outcome = @{ Action = 'repair_error'; Result = 'escalate'; Detail = "対処中に例外が発生しました: $($_.Exception.Message)" }
                }
            }

            $effSeverity = switch ($outcome.Result) {
                'ok' { 'auto' }
                'abort' { 'escalate' }
                'escalate' { 'escalate' }
                default { 'warn' }
            }

            Write-FailureEvent -Phase $PhaseLower -RuleId $rule.Id -Severity $effSeverity -Action $outcome.Action -Result $outcome.Result -Detail $outcome.Detail
            $detected += [ordered]@{
                ruleId   = $rule.Id
                severity = $effSeverity
                action   = $outcome.Action
                result   = $outcome.Result
                detail   = $outcome.Detail
            }

            if ($outcome.Result -eq 'abort' -and $rule.Id -eq 'FP-07-MISSINGBIN') {
                # exit 2 を返してよいのはFP-07の必須バイナリ不在・ディスク空き不足だけ(P1・§2-3)。
                $abort = $true
            }
            if ($outcome.Result -ne 'ok') {
                $anyUnresolved = $true
            }
            if ($effSeverity -eq 'escalate') {
                $escalations += [ordered]@{ ruleId = $rule.Id; detail = $outcome.Detail }
            }

            $lastAction = $outcome.Action
            $lastResult = $outcome.Result
        }

        Update-RuleState -State $State -RuleId $rule.Id -Triggered $triggered -LastAction $lastAction -LastResult $lastResult -MaxAutoAttempts $rule.MaxAutoAttempts
    }

    $State | Add-Member -NotePropertyName 'updatedAt' -NotePropertyValue ((Get-Date).ToString('s')) -Force
    Save-FailureState -State $State

    $exitCode = 0
    if ($abort) {
        $exitCode = 2
    } elseif ($anyUnresolved) {
        $exitCode = 1
    }

    $resultObj = [ordered]@{
        ok          = (-not $abort)
        phase       = $PhaseLower
        detected    = $detected
        escalate    = ($escalations.Count -gt 0)
        escalations = $escalations
    }
    ($resultObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
    Write-Progress2 "モード=$Mode 終了(検知件数=$($detected.Count)、終了コード=$exitCode)。"
    exit $exitCode
} catch {
    # フェイルオープン(P1): プレイブック自身の例外でループを止めない。
    # 記録だけ残してexit 0する。
    try {
        Ensure-EventsFile
        Write-FailureEvent -Phase $PhaseLower -RuleId 'FP-INTERNAL' -Severity 'warn' -Action 'none' -Result 'internal_error' -Detail $_.Exception.Message
    } catch {
        # 記録すら失敗した場合は諦める(Write-Progress2で警告するのみ)。
    }
    Write-Progress2 "内部エラーが発生しましたが、fail-openの方針によりexit 0で終了します: $($_.Exception.Message)"
    $fallbackObj = [ordered]@{
        ok          = $true
        phase       = $PhaseLower
        detected    = @()
        escalate    = $false
        escalations = @()
        internalError = $_.Exception.Message
    }
    ($fallbackObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
    exit 0
}
