#requires -Version 5.1
<#
    tools/failure_playbook.ps1 — 失敗プレイブック(T5-A61、骨格)

    正本: docs/failure_playbook.md(§2 全体構成、§3 既知障害の一覧、§7 T5-A61行)。
    無人夜間ループ(tools/night_loop.ps1)の既知障害を検知し、安全な範囲でのみ
    自動対処する。設計判断は docs/failure_playbook.md で確定済みのため、本スクリプトは
    その記述どおりに実装する。

    このスクリプト(T5-A64時点)で実装済みのルール:
      - FP-01-FILELOCK: -Mode Preflight のみ。シグネチャA(排他ロック実測)・
        B(フォールバックログ存在)・C(孤児容疑プロセスの列挙、warn固定・
        autoKillLockHolders=true時のみ例外的にkill)の全シグネチャ実装済み。
      - FP-02-BOM: -Mode Preflight / Postmortem / Check の全モードに対応。
        シグネチャB(BOM欠落)・C(BOMはあるがParseFileエラー)。対象ファイルは
        Preflightでは tools/*.ps1 + .claude/hooks/*.ps1 の全件、Postmortem/Checkでは
        `git diff --name-only` + `git ls-files --others --exclude-standard` の *.ps1。
        (シグネチャAはPostToolUseフック側〈tools/check_encoding.ps1〉なので対象外)
      - FP-03-EMULATOR: -Mode Preflight のみ。シグネチャA(死亡)・B(ハング、
        Preflightでは10秒タイムアウトの軽量版)・C(残骸ロックファイル)・
        D(直近30分のWERクラッシュ痕跡)を実装。対象AVDは beanbase_ui に固定。
        自動再起動(tools/emulator.ps1 -Stop → -Start、-Startが内部でClear-StaleEmulator
        を実行する)は -Unattended 指定時のみ、最大1回(合計2回試行)。有人時は
        検知内容の提示のみで再起動しない。2回目も失敗した場合はescalateするが
        ループは中断しない(abortにしない)。
      - FP-04-PERMISSION: -Mode Postmortem のみ。シグネチャA(権限拒否メッセージ、
        tool名を捕捉)・B(dontAskモード拒否)・C(agyのheadlessモード拒否文字列)・
        D(.claude/agy_logs/ledger.tsvのexit_code=12)の全シグネチャ実装済み。
        1件でも検知したら即escalate、自動対処は一切行わない(.claude/settings*.json
        のallow/denyを書き換えることは絶対に禁止、P3)。night_reportの「人がやること」に
        allowへ追加する候補行をDetailとして出力する。
      - FP-06-SILENTSTALL: -Mode Preflight のみ。.claude/night_outcomes.log(TSV、
        Save-NightLoopLastRunからの追記はT5-A66で配線予定、ファイル不在時は検知0件で
        fail-open)を読み、直近3回/5回同一outcome(completed以外)・直近72時間completed
        なし・直近5回中error_*が3件以上、のいずれかで即escalate。5回連続のときは
        Detailに"SEVERE"種別を含め、後続タスク(T5-A66のnight_report見出し変更)が
        判別できるようにする。自動対処なし(検知・通知のみ)。
      - FP-05-HANG-AGY(FP-05(a)): -Mode Postmortem のみ。.claude/agy_logs/ledger.tsvの
        当ループ境界以降でexit_code=11(agy委譲の外側タイムアウトによるkill)を検知する。
        自動対処は「記録するだけで挙動を変えない」(既存のagy→Claudeフォールバックは不変、
        .claude/loop_failures.txtの連続失敗にも数えない)。同一task_idで2回連続exit_code=11を
        検知した場合のみescalateする(failure_state.jsonの本ルールエントリへ
        lastTaskId/taskConsecutiveを追加して判定、T5-A65で確定したスキーマ)。
      - FP-05(c)(Watchdog、claude本体の無応答): -Mode Watchdog を単独プロセスとして起動すると、
        30秒間隔で-StreamLogPathの.jsonlのLength/LastWriteTimeを監視する。-StallMinutes
        (既定20分)無成長で警告のみ、その2倍(既定40分)またはhardcap(既定90分)到達で
        Get-CimInstance Win32_Processにより-WrapperPidから深さ5まで再帰的に子孫プロセスを
        列挙し、Name=claude.exe/node.exeかつCommandLineにnight_loopを含むものだけを対象に
        子孫から順にStop-Process -Forceする(対象0件なら停止せずescalateのみ、誤爆回避)。
        -Unattended未指定(有人時)は停止せず検知のみ。停止・escalate時はGenerate-EvidenceBundle
        で証拠束(§5)を生成する。.claude/night_watchdog.stopの存在または-WrapperPidの消滅を
        検知すると自ら終了する(孤児化防止)。

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
    # 設計(docs/failure_playbook.md §2-2)ではintと記載されているが、テスト運用(§8・T5-A65)で
    # 0.02分のような分数分の指定が必須なためdoubleへ変更する(既定値20/90自体は変わらず、
    # 算術・文字列展開とも互換。intのままだとPowerShellのバインド時に小数が丸められ0になり、
    # 分数指定でのテストが意図通り機能しない実害があったため、T5-A65実装中に確定した判断)。
    [double]$StallMinutes = 20,
    [double]$HardCapMinutes = 90,
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

# FP-03-EMULATOR用のパス(tools/emulator.ps1 と同じ既定値の解決ロジックを踏襲。
# emulator.ps1自体は呼び出す形で使い、パス解決のみ最小限をここで持つ)。
$EmulatorScriptPath = Join-Path $RepoRoot 'tools\emulator.ps1'
$AvdHomePath = if ($env:ANDROID_AVD_HOME) { $env:ANDROID_AVD_HOME } else { Join-Path $env:USERPROFILE '.android\avd' }
$AndroidSdkRootPath = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$AdbExePath = Join-Path $AndroidSdkRootPath 'platform-tools\adb.exe'

# tools/emulator.ps1 は自身の[Console]::OutputEncodingを上書きしないため、非対話・
# ウィンドウ無しの子プロセスとして起動すると日本語出力がOS既定のOEMコードページ
# (日本語Windowsでは通常932/Shift_JIS)で書き出される。Invoke-ProcessWithTimeoutの
# 既定(.NET既定エンコーディング)のまま読むと文字化けし「シリアル: emulator-XXXX」
# 「停止しています」等の正規表現照合が失敗するため、明示的にこのエンコーディングで読む
# (T5-A90実装中に実機で発見。tools/emulator.ps1自体は変更しないスコープのためこちらで対処)。
try {
    $EmulatorChildEncoding = [System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
} catch {
    $EmulatorChildEncoding = $null
}

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $RepoRoot 'tools\failure_playbook.config.json'
}

$PhaseLower = $Mode.ToLower()

# ============================== 設定読み込み(§2-2) ==============================
# tools/night_loop.config.json と同じ方針: 無ければ既定値で続行する。
function Get-PlaybookConfig {
    param([string]$Path)
    $defaults = @{
        autoKillLockHolders     = $false
        detectBudgetSec         = 120
        slowDetectWarnSec       = 30
        adbTimeoutSec           = 15
        emulatorStatusTimeoutSec  = 30
        emulatorControlTimeoutSec = 150
        wmiTimeoutSec           = 20
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

# 「当ループ境界」以降かどうかの判定に使う共通ヘルパー(FP-04シグネチャD・FP-04の
# .jsonl/.err.logフォールバック走査で使用)。.claude/loop_boundary.txt はloop_guard.jsが
# 書く既存ファイルで、先頭トークンがISO8601タイムスタンプ。読めない・存在しない場合は
# $null を返し、呼び出し側はフィルタせず全件を対象にする(fail-open、境界不明なら
# 見逃すより多めに拾う方を優先する)。
function Get-LoopBoundaryTime {
    $path = Join-Path $ClaudeDir 'loop_boundary.txt'
    if (-not (Test-Path $path)) { return $null }
    try {
        $raw = (Get-Content -Path $path -Raw -Encoding UTF8 -ErrorAction Stop).Trim()
        if (-not $raw) { return $null }
        $tsToken = ($raw -split '\s+')[0]
        return [datetime]::Parse($tsToken, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
    } catch {
        return $null
    }
}

# ============================== ルール登録簿(§2-5) ==============================
# 別JSONに切り出さず、スクリプト内のPowerShell配列として持つ(シグネチャと対処コードを
# 離さない)。T5-A65時点でFP-01(シグネチャA/B/C)・FP-02(Preflight/Postmortem/Check)・
# FP-03(シグネチャA〜D)・FP-04(シグネチャA〜D)・FP-05-HANG-AGY(FP-05(a))・
# FP-06(3条件)・FP-07(表の全行)を実装済み。FP-05(c)(Watchdogモード)はこの配列の外
# (メイン処理の手前)で単独処理として実装している(下記参照)。
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
            # シグネチャC: 容疑プロセスの孤児検知(§3 FP-01表)。CommandLineに night_logs/wrapper-
            # を含み、名前がtail.exe/more.com/powershell.exe/pwsh.exeのいずれかで、かつ
            # ParentProcessIdが指すプロセスが存在しない(孤児)ものを検知する。
            # Get-CimInstanceが権限不足等で失敗する場合は「容疑者不明」として記録するだけに
            # 留め、検知はしない(fail-open、§8リスク表)。
            try {
                $suspectProcs = Get-CimInstance -ClassName Win32_Process -OperationTimeoutSec $Config.wmiTimeoutSec -ErrorAction Stop | Where-Object {
                    $_.CommandLine -and
                    ($_.CommandLine -match 'night_logs' -or $_.CommandLine -match 'wrapper-') -and
                    ($_.Name -in @('tail.exe', 'more.com', 'powershell.exe', 'pwsh.exe'))
                }
                foreach ($proc in $suspectProcs) {
                    $parentExists = $false
                    if ($proc.ParentProcessId) {
                        $parentExists = [bool](Get-Process -Id $proc.ParentProcessId -ErrorAction SilentlyContinue)
                    }
                    if (-not $parentExists) {
                        $findings += "C|$($proc.ProcessId)|プロセス名=$($proc.Name) コマンドライン=$($proc.CommandLine)"
                    }
                }
            } catch {
                # Get-CimInstance自体が失敗した場合は「容疑者不明」として記録するのみ(検知0件、fail-open)。
                Write-Progress2 "FP-01-FILELOCK シグネチャC: Get-CimInstance Win32_Process の実行に失敗したため容疑プロセスの列挙をスキップしました(容疑者不明): $($_.Exception.Message)"
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
            } elseif ($kind -eq 'C') {
                # シグネチャC: 孤児容疑プロセス。原則warn(kill禁止)。例外は
                # autoKillLockHolders=true かつ 孤児 かつ 名前がtail.exe/more.com かつ
                # -Unattended指定時の3条件を全て満たす場合のみ自動終了する(§3 FP-01)。
                $suspectPid = $path
                $procName = $null
                if ($msg -match 'プロセス名=(\S+)') { $procName = $Matches[1] }
                $isKillableName = ($procName -in @('tail.exe', 'more.com'))
                if ($Config.autoKillLockHolders -eq $true -and $isKillableName -and $Unattended) {
                    try {
                        Stop-Process -Id ([int]$suspectPid) -Force -ErrorAction Stop
                        return @{ Action = 'killed'; Result = 'ok'; Detail = "PID=$suspectPid($procName)を自動終了しました。$msg" }
                    } catch {
                        return @{ Action = 'kill_failed'; Result = 'warned'; Detail = "PID=$suspectPid の自動終了に失敗しました: $($_.Exception.Message)。終了すべきPID=$suspectPid — $msg" }
                    }
                } else {
                    return @{ Action = 'none'; Result = 'warned'; Detail = "終了すべきPID=$suspectPid — $msg(自動対処なし、記録のみ)" }
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
        Phase           = @('Preflight', 'Postmortem', 'Check')
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
                # Postmortem/Check: git diff --name-only + git ls-files --others --exclude-standard
                # の *.ps1 のみを対象にする(§3 FP-02表)。$RepoRootをカレントディレクトリとして
                # 実行するため `git -C` を使う。gitコマンド自体が失敗してもfail-openで検知0件とする。
                $targetFiles = @()
                $diffFiles = @()
                $untrackedFiles = @()
                try {
                    $diffFiles = @(& git -C $RepoRoot diff --name-only 2>$null)
                } catch {
                    $diffFiles = @()
                }
                try {
                    $untrackedFiles = @(& git -C $RepoRoot ls-files --others --exclude-standard 2>$null)
                } catch {
                    $untrackedFiles = @()
                }
                $candidateRelPaths = @($diffFiles) + @($untrackedFiles)
                foreach ($rel in $candidateRelPaths) {
                    if (-not $rel) { continue }
                    if ($rel -notmatch '\.ps1$') { continue }
                    $full = Join-Path $RepoRoot $rel
                    if (Test-Path $full) {
                        $targetFiles += Get-Item -Path $full -ErrorAction SilentlyContinue
                    }
                }
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
        Id              = 'FP-03-EMULATOR'
        Title           = 'Android エミュレータのクラッシュ / ハング'
        Phase           = @('Preflight')
        Severity        = 'auto'
        # Repair内で「2回目の起動も失敗→escalate」を1回のDetect/Repair呼び出し内で
        # 完結させるため、連続ループ回数によるUpdate-RuleStateの自動escalateは使わない。
        MaxAutoAttempts = 999
        Detect          = {
            $evidence = @()
            $targetAvd = 'beanbase_ui'
            $serial = $null
            $isRunning = $false

            # シグネチャA(死亡): tools/emulator.ps1 -Status の判定結果をそのまま使う。
            # Show-Status内部で「adb devices + AVD名一致」を突き合わせているため、
            # 「-Statusが実行中AVDを返さない」「adb devicesにシリアルが出ない」を
            # 二重実装せずこの1回の呼び出しで両方判定する(§3 FP-03表A、車輪の再発明回避)。
            if (-not (Test-Path $AdbExePath)) {
                $evidence += "A|adb.exeが見つかりません($AdbExePath)のためエミュレータの状態確認ができません"
            } elseif (-not (Test-Path $EmulatorScriptPath)) {
                $evidence += 'A|tools/emulator.ps1 が見つかりません'
            } else {
                # adbデーモン未起動状態でtools/emulator.ps1内部の `adb devices` を呼ぶと、
                # adb.exeが標準エラーへ出す "daemon not running; starting now" 行が
                # $ErrorActionPreference='Stop' 下でNativeCommandErrorとして終了例外化し、
                # AVDが実際には正常なのに死亡と誤検知する(実機で再現確認済み)。
                # Start-Processはパイプライン経由でエラーストリームを扱わないため、
                # 事前にこちらでデーモンを起動しておくことでこの誤検知を避ける
                # (emulator.ps1自体は変更しない、失敗しても致命的ではないためfail-open)。
                try {
                    Invoke-ProcessWithTimeout -FilePath $AdbExePath -Arguments 'start-server' -TimeoutSec $Config.adbTimeoutSec | Out-Null
                } catch {
                    # 事前起動に失敗しても後続の-Status判定に委ねる(fail-open)
                }
                $statusText = ''
                $statusTimedOut = $false
                try {
                    $statusArgs = '-NoProfile -NonInteractive -File "{0}" -Status -AvdName {1}' -f $EmulatorScriptPath, $targetAvd
                    $r = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $statusArgs -TimeoutSec $Config.emulatorStatusTimeoutSec -WorkingDirectory $RepoRoot -Encoding $EmulatorChildEncoding
                    $statusText = $r.StdOut + "`n" + $r.StdErr
                    $statusTimedOut = $r.TimedOut
                } catch {
                    $evidence += "A|tools/emulator.ps1 -Status の実行時に例外が発生しました: $($_.Exception.Message)"
                }
                if ($statusTimedOut) {
                    # -Statusがタイムアウトした場合は新シグネチャTとして扱い、A/B/Cの判定は行わない。
                    return @("T|tools/emulator.ps1 -Status が$($Config.emulatorStatusTimeoutSec)秒以内に応答しなかったためプロセスツリーを強制終了しました(adb/エミュレータの応答不能の疑い、判定不能)")
                } elseif ($statusText -match 'シリアル:\s*(emulator-\d+)') {
                    $serial = $Matches[1]
                    $isRunning = $true
                } elseif ($statusText -match '停止しています') {
                    $evidence += "A|tools/emulator.ps1 -Status がAVD '$targetAvd' の停止を報告しました"
                } elseif ($statusText.Trim()) {
                    $evidence += "A|tools/emulator.ps1 -Status の出力から起動状態を判定できませんでした: $($statusText.Trim())"
                }
            }

            # シグネチャB(ハング、Preflight向け軽量版): 厳密な120秒監視はWatchdogモード
            # (後続タスク)の領分のため、Preflightではadbコマンドの単発応答有無(10秒タイムアウト)
            # での簡易判定に留める(§3 FP-03表Bの注記どおり)。
            if ($isRunning -and $serial -and (Test-Path $AdbExePath)) {
                try {
                    $r = Invoke-ProcessWithTimeout -FilePath $AdbExePath -Arguments "-s $serial get-state" -TimeoutSec 10
                    if ($r.TimedOut) {
                        $evidence += "B|adb -s $serial get-state が10秒以内に応答しませんでした(ハングの疑い)"
                    } else {
                        $stateOut = $r.StdOut.Trim()
                        if ($stateOut -match 'offline') {
                            $evidence += "B|adb -s $serial get-state が device offline を返しました"
                        } elseif ($stateOut -ne 'device') {
                            $evidence += "B|adb -s $serial get-state の応答が想定外です: $stateOut"
                        }
                    }
                } catch {
                    $evidence += "B|adb -s $serial get-state の実行に失敗しました: $($_.Exception.Message)"
                }
            }

            # シグネチャC(残骸): ロックファイルが残存しているのにadb devicesに現れない
            # (=シグネチャAで停止と判定された場合のみ意味を持つ)。
            $avdDir = Join-Path $AvdHomePath "$targetAvd.avd"
            $lockFiles = @('hardware-qemu.ini.lock', 'multiinstance.lock') |
                ForEach-Object { Join-Path $avdDir $_ } | Where-Object { Test-Path $_ }
            if ($lockFiles.Count -gt 0 -and -not $isRunning) {
                $evidence += "C|ロックファイルが残存しています($($lockFiles -join ', '))が adb devices に '$targetAvd' が現れません"
            }

            # シグネチャD(クラッシュ痕跡): 直近30分のWindowsエラー報告にqemu-system-x86_64を
            # 含むイベント(T5-A30 / tools/emulator.ps1 の Invoke-Doctor と同じ確認手法・同じ
            # 既定ウィンドウ幅を踏襲。本スクリプトはループ開始時刻を引数で受け取っていないため、
            # 直近30分を「ループ開始時刻」の代替として扱う。設計に無い箇所の解釈、完了報告に明記)。
            try {
                $since = (Get-Date).AddMinutes(-30)
                $werEvents = Get-WinEvent -FilterHashtable @{LogName = 'Application'; ProviderName = 'Windows Error Reporting'; StartTime = $since } -MaxEvents 200 -ErrorAction SilentlyContinue
                if ($werEvents) {
                    $crashEvents = $werEvents | Where-Object { $_.Message -match 'qemu-system-x86_64' }
                    if ($crashEvents) {
                        $evidence += "D|直近30分にqemu-system-x86_64を含むWindowsエラー報告イベントが$($crashEvents.Count)件あります"
                    }
                }
            } catch {
                # WER取得失敗はfail-openで見逃す(検知しない)
            }

            if ($evidence.Count -eq 0) {
                @()
            } else {
                # 複数シグネチャが同時発火しても対処(再起動)は1イベントにつき1回にまとめる
                # (§3 FP-03「最大1回(合計2回試行)」はDetect1回あたりの回数であり、
                # シグネチャごとの多重実行を避けるため単一のfindingにまとめて返す)。
                @(($evidence -join ' / '))
            }
        }
        Repair          = {
            param($detail)
            $targetAvd = 'beanbase_ui'
            if ($detail -like 'T|*') {
                # -Statusがタイムアウトした場合(新シグネチャT)は、同じadb経路で再び刺さる
                # おそれがあるため自動再起動を行わない(§3 FP-03訂正注記)。
                return @{ Action = 'none'; Result = 'warned'; Detail = "検知内容: $detail (adbが応答不能のため自動再起動は行いません。Android検証は未実施として扱ってください)" }
            }
            if (-not $Unattended) {
                # 有人時はFP-03の自動再起動を行わない(§3 FP-03・§3-2「有人時の縮退」)。
                return @{ Action = 'none'; Result = 'warned'; Detail = "検知内容: $detail (有人時のため自動再起動は行いません)" }
            }
            # adbデーモン未起動時の誤例外化を避けるため、Detect側と同じ事前起動を行う
            # (詳細はDetectのコメント参照)。
            try {
                Invoke-ProcessWithTimeout -FilePath $AdbExePath -Arguments 'start-server' -TimeoutSec $Config.adbTimeoutSec | Out-Null
            } catch {
                # 失敗しても後続の-Stop/-Start判定に委ねる(fail-open)
            }
            $success = $false
            $attemptLog = @()
            for ($attempt = 1; $attempt -le 2; $attempt++) {
                try {
                    $stopArgs = '-NoProfile -NonInteractive -File "{0}" -Stop -AvdName {1} -TimeoutSec {2}' -f $EmulatorScriptPath, $targetAvd, $Config.emulatorControlTimeoutSec
                    $rStop = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $stopArgs -TimeoutSec ($Config.emulatorControlTimeoutSec + 30) -WorkingDirectory $RepoRoot -Encoding $EmulatorChildEncoding
                    if ($rStop.TimedOut) {
                        $attemptLog += "試行${attempt}: -Stop が上限時間内に応答しなかったため強制終了しました"
                    }
                } catch {
                    $attemptLog += "試行${attempt}: -Stop で例外が発生しました: $($_.Exception.Message)"
                }
                # -Startは内部でClear-StaleEmulatorを実行してから起動する(tools/emulator.ps1の
                # Start-Avd実装)ため、「-Stop → Clear-StaleEmulator → -Start」の3段階(§3 FP-03)は
                # -Stop に続けて -Start を呼ぶだけで満たされる(車輪の再発明回避)。
                try {
                    $startArgs = '-NoProfile -NonInteractive -File "{0}" -Start -AvdName {1} -TimeoutSec {2}' -f $EmulatorScriptPath, $targetAvd, $Config.emulatorControlTimeoutSec
                    $rStart = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $startArgs -TimeoutSec ($Config.emulatorControlTimeoutSec + 30) -WorkingDirectory $RepoRoot -Encoding $EmulatorChildEncoding
                    if ($rStart.TimedOut) {
                        $attemptLog += "試行${attempt}: -Start が上限時間内に応答しなかったため強制終了しました"
                        continue
                    }
                    $statusArgs = '-NoProfile -NonInteractive -File "{0}" -Status -AvdName {1}' -f $EmulatorScriptPath, $targetAvd
                    $rCheck = Invoke-ProcessWithTimeout -FilePath 'powershell' -Arguments $statusArgs -TimeoutSec $Config.emulatorStatusTimeoutSec -WorkingDirectory $RepoRoot -Encoding $EmulatorChildEncoding
                    if ($rCheck.TimedOut) {
                        $attemptLog += "試行${attempt}: -Status が上限時間内に応答しなかったため強制終了しました"
                        continue
                    }
                    $checkText = $rCheck.StdOut + $rCheck.StdErr
                    if ($checkText -match 'シリアル:\s*(emulator-\d+)') {
                        $success = $true
                        $attemptLog += "試行${attempt}: 起動成功(シリアル: $($Matches[1]))"
                        break
                    } else {
                        $attemptLog += "試行${attempt}: -Start 後もAVD '$targetAvd' の起動を確認できませんでした"
                    }
                } catch {
                    $attemptLog += "試行${attempt}: -Start で例外が発生しました: $($_.Exception.Message)"
                }
            }
            $summary = "検知内容: $detail 。対処ログ: $($attemptLog -join ' | ')"
            if ($success) {
                return @{ Action = 'restarted'; Result = 'ok'; Detail = $summary }
            } else {
                # 2回目の起動も失敗→escalate。ただしループ自体は中断しない(abortにしない、
                # abortが許されるのはFP-07のみ、§2-3・§3 FP-03)。
                return @{ Action = 'restart_failed'; Result = 'escalate'; Detail = "$summary 。2回目の起動も失敗したためescalateします(ループは中断しません。Android検証は未実施として扱ってください)" }
            }
        }
    },
    @{
        Id              = 'FP-04-PERMISSION'
        Title           = 'dontAskモードによる権限拒否'
        Phase           = @('Postmortem')
        Severity        = 'auto'
        # 1件でも検知したら即escalateする方式(§3 FP-04)のため連続回数は使わない。
        # switch文の中で常にResult='escalate'を返すのでこの値自体は判定に効かない。
        MaxAutoAttempts = 0
        Detect          = {
            $findings = @()
            $targets = @()
            if ($StreamLogPath -and (Test-Path $StreamLogPath)) {
                $targets += Get-Item -Path $StreamLogPath -ErrorAction SilentlyContinue
            }
            if ($ErrLogPath -and (Test-Path $ErrLogPath)) {
                $targets += Get-Item -Path $ErrLogPath -ErrorAction SilentlyContinue
            }
            if ($targets.Count -eq 0) {
                # -StreamLogPath/-ErrLogPathが未指定の場合(手動実行・テスト等)のフォールバック:
                # 当ループ境界(.claude/loop_boundary.txt)以降に更新された .jsonl / .err.log を
                # night_logs配下から拾う(境界不明ならfail-openで全件対象、FP-01シグネチャBの
                # 24時間フォールバックと同じ考え方)。night_loop.ps1からの正規呼び出しでは
                # 常に-StreamLogPath/-ErrLogPathが渡されるため、この分岐は主にテスト用。
                $boundaryTime = Get-LoopBoundaryTime
                if (Test-Path $NightLogsDir) {
                    $candidates = @(Get-ChildItem -Path $NightLogsDir -Include '*.jsonl', '*.err.log' -File -Recurse -ErrorAction SilentlyContinue)
                    foreach ($c in $candidates) {
                        if (-not $boundaryTime -or $c.LastWriteTime -ge $boundaryTime) {
                            $targets += $c
                        }
                    }
                }
            }
            $sigA = [regex]::new('Permission to use (?<tool>[A-Za-z_]+) has been denied', 'IgnoreCase')
            $sigB = [regex]::new("running in don'?t ask mode", 'IgnoreCase')
            $sigC = [regex]::new('permission that headless mode cannot prompt for', 'IgnoreCase')
            foreach ($t in $targets) {
                if (-not $t) { continue }
                $text = $null
                try {
                    $text = Get-Content -Path $t.FullName -Raw -ErrorAction Stop
                } catch {
                    continue
                }
                if (-not $text) { continue }
                foreach ($m in $sigA.Matches($text)) {
                    $tool = $m.Groups['tool'].Value
                    $findings += "A|$tool|$($t.FullName) で権限拒否を検知しました(`"$($m.Value)`")"
                }
                if ($sigB.IsMatch($text)) {
                    $findings += "B|$($t.FullName)|$($t.FullName) に don't ask mode での拒否を示す文字列がありました"
                }
                if ($sigC.IsMatch($text)) {
                    $findings += "C|$($t.FullName)|$($t.FullName) に agy(headless mode)の権限拒否文字列がありました"
                }
            }
            # シグネチャD: .claude/agy_logs/ledger.tsv の当ループ境界以降でexit_code=12の行
            # (docs/antigravity_delegation_design.md §9.4の headless権限拒否と同一の終了コード)。
            $ledgerPath = Join-Path $ClaudeDir 'agy_logs\ledger.tsv'
            if (Test-Path $ledgerPath) {
                $boundaryTime = Get-LoopBoundaryTime
                try {
                    $ledgerLines = @(Get-Content -Path $ledgerPath -Encoding UTF8 -ErrorAction Stop)
                    for ($i = 1; $i -lt $ledgerLines.Count; $i++) {
                        if (-not $ledgerLines[$i]) { continue }
                        $cols = $ledgerLines[$i] -split "`t"
                        if ($cols.Count -lt 5) { continue }
                        $rowTs = $cols[0]; $rowTaskId = $cols[1]; $rowExitCode = $cols[4]
                        if ($rowExitCode -ne '12') { continue }
                        $rowTime = $null
                        try { $rowTime = [datetime]::ParseExact($rowTs, 'yyyyMMdd_HHmmss', $null) } catch { $rowTime = $null }
                        if ($boundaryTime -and $rowTime -and $rowTime -lt $boundaryTime) { continue }
                        $findings += "D|$rowTaskId|.claude/agy_logs/ledger.tsv の行(timestamp=$rowTs)でexit_code=12(agyのheadlessモード権限拒否)を検知しました"
                    }
                } catch {
                    # ledger.tsvが読めない場合はfail-openで見逃す
                }
            }
            $findings
        }
        Repair          = {
            param($detail)
            # 自動対処は禁止(P3)。.claude/settings*.json のallow/denyは絶対に書き換えない。
            # 代わりにallowへ追加すべき候補行を人がそのまま貼れる形でDetailに生成する(§3 FP-04)。
            $parts = $detail -split '\|', 3
            $kind = $parts[0]; $target = $parts[1]; $msg = $parts[2]
            switch ($kind) {
                'A' {
                    $allowLine = '"' + $target + '(*)"'
                    $advice = "人がやること: .claude/settings.night.json の permissions.allow に次の1行を追加候補として検討してください(実際に必要なコマンドパターンに応じて調整): $allowLine"
                    return @{ Action = 'none'; Result = 'escalate'; Detail = "$msg 。$advice" }
                }
                'B' {
                    return @{ Action = 'none'; Result = 'escalate'; Detail = "$msg 。人がやること: 直近のログを確認し、.claude/settings.night.json の permissions.allow に不足しているツールが無いか確認してください" }
                }
                'C' {
                    return @{ Action = 'none'; Result = 'escalate'; Detail = "$msg 。人がやること: agy(headless mode)側の権限不足です。docs/antigravity_delegation_design.md §9.4 を参照してください" }
                }
                'D' {
                    return @{ Action = 'none'; Result = 'escalate'; Detail = "$msg (task_id=$target) 。人がやること: agy委譲がheadless権限不足で失敗しています。ledger.tsvのverdict列を確認してください" }
                }
                default {
                    return @{ Action = 'none'; Result = 'escalate'; Detail = $detail }
                }
            }
        }
    },
    @{
        Id              = 'FP-05-HANG-AGY'
        Title           = 'agy委譲のハング(外側タイムアウトによるkill)'
        Phase           = @('Postmortem')
        Severity        = 'auto'
        # 記録するだけで挙動を変えない(§3 FP-05(a))。連続回数の判定はタスクID単位で
        # Repair内が$Stateを直接読み書きして行うため、ルール単位のMaxAutoAttemptsは使わない。
        MaxAutoAttempts = 999
        Detect          = {
            $findings = @()
            $ledgerPath = Join-Path $ClaudeDir 'agy_logs\ledger.tsv'
            if (Test-Path $ledgerPath) {
                $boundaryTime = Get-LoopBoundaryTime
                try {
                    $ledgerLines = @(Get-Content -Path $ledgerPath -Encoding UTF8 -ErrorAction Stop)
                    for ($i = 1; $i -lt $ledgerLines.Count; $i++) {
                        if (-not $ledgerLines[$i]) { continue }
                        $cols = $ledgerLines[$i] -split "`t"
                        if ($cols.Count -lt 5) { continue }
                        $rowTs = $cols[0]; $rowTaskId = $cols[1]; $rowExitCode = $cols[4]
                        if ($rowExitCode -ne '11') { continue }
                        $rowTime = $null
                        try { $rowTime = [datetime]::ParseExact($rowTs, 'yyyyMMdd_HHmmss', $null) } catch { $rowTime = $null }
                        if ($boundaryTime -and $rowTime -and $rowTime -lt $boundaryTime) { continue }
                        $findings += "AGY|$rowTaskId|.claude/agy_logs/ledger.tsv の行(timestamp=$rowTs)でexit_code=11(agy委譲の外側タイムアウトによるkill、docs/antigravity_delegation_design.md §9.4)を検知しました"
                    }
                } catch {
                    # ledger.tsvが読めない場合はfail-openで見逃す
                }
            }
            $findings
        }
        Repair          = {
            param($detail)
            # 設計判断(T5-A65、docs/failure_playbook.md §3 FP-05(a)には「同一タスクで2回連続
            # exit 11→escalate」としか書かれておらずスキーマは未確定だったため、本スクリプトで
            # failure_state.jsonの本ルールエントリへ lastTaskId / taskConsecutive を追加して
            # 確定する。既存のUpdate-RuleStateはルール単位の連続回数のみを扱うため、ここでは
            # Repair内で直接$Stateを読み書きする(他ルールのUpdate-RuleState呼び出しとは独立)。
            $parts = $detail -split '\|', 3
            $kind = $parts[0]; $taskId = $parts[1]; $msg = $parts[2]
            $ruleId = 'FP-05-HANG-AGY'
            if (-not ($State.PSObject.Properties.Name -contains $ruleId)) {
                $newEntry = [pscustomobject]@{ consecutive = 0; lastAt = $null; lastAction = $null; lastResult = $null; escalated = $false }
                $State | Add-Member -NotePropertyName $ruleId -NotePropertyValue $newEntry -Force
            }
            $entry = $State.$ruleId
            if (-not ($entry.PSObject.Properties.Name -contains 'lastTaskId')) {
                $entry | Add-Member -NotePropertyName 'lastTaskId' -NotePropertyValue $null -Force
            }
            if (-not ($entry.PSObject.Properties.Name -contains 'taskConsecutive')) {
                $entry | Add-Member -NotePropertyName 'taskConsecutive' -NotePropertyValue 0 -Force
            }
            if ($entry.lastTaskId -eq $taskId -and $taskId) {
                $entry.taskConsecutive = [int]$entry.taskConsecutive + 1
            } else {
                $entry.lastTaskId = $taskId
                $entry.taskConsecutive = 1
            }
            if ($entry.taskConsecutive -ge 2) {
                return @{ Action = 'none'; Result = 'escalate'; Detail = "$msg (task_id=$taskId が2回連続でexit_code=11)。人がやること: agy側の恒常的な問題を疑い、docs/antigravity_delegation_design.md の委譲判断を見直してください" }
            }
            return @{ Action = 'none'; Result = 'ok'; Detail = "$msg (記録のみ。既存のagy→Claudeフォールバック挙動は変更しません。.claude/loop_failures.txtの連続失敗にも数えません)" }
        }
    },
    @{
        Id              = 'FP-06-SILENTSTALL'
        Title           = '同一スキップ/エラーの連続(サイレントスタール)'
        Phase           = @('Preflight')
        Severity        = 'auto'
        # 検知した時点で常にescalateを返すため連続回数による自動escalate判定は使わない。
        MaxAutoAttempts = 0
        Detect          = {
            $findings = @()
            $outcomesLogPath = Join-Path $ClaudeDir 'night_outcomes.log'
            if (-not (Test-Path $outcomesLogPath)) {
                # データ源(Save-NightLoopLastRunからの追記)がまだ配線されていない場合を含め、
                # ファイル不在時は検知0件として扱う(fail-open、§3 FP-06)。
                return $findings
            }
            $rawLines = @()
            try {
                $rawLines = @(Get-Content -Path $outcomesLogPath -Encoding UTF8 -ErrorAction Stop)
            } catch {
                return $findings
            }
            $rows = @()
            foreach ($line in $rawLines) {
                if (-not $line) { continue }
                $cols = $line -split "`t"
                if ($cols.Count -lt 2) { continue }
                $rowTs = $cols[0]
                $rowOutcome = $cols[1]
                $rowReason = if ($cols.Count -ge 3) { $cols[2] } else { '' }
                $parsedTs = $null
                try {
                    $parsedTs = [datetime]::Parse($rowTs, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
                } catch {
                    try { $parsedTs = [datetime]$rowTs } catch { $parsedTs = $null }
                }
                $rows += [pscustomobject]@{ Timestamp = $rowTs; ParsedTimestamp = $parsedTs; Outcome = $rowOutcome; Reason = $rowReason }
            }
            if ($rows.Count -eq 0) { return $findings }

            function Test-SameNonCompletedStreak {
                param($Set)
                if (-not $Set -or $Set.Count -eq 0) { return $false }
                $first = $Set[0].Outcome
                if ($first -eq 'completed') { return $false }
                foreach ($r in $Set) { if ($r.Outcome -ne $first) { return $false } }
                return $true
            }

            $last5 = @($rows | Select-Object -Last 5)
            $last3 = @($rows | Select-Object -Last 3)

            # 条件1派生: 直近5回連続で同一outcome(completed以外)ならSEVERE、
            # そうでなく直近3回連続なら通常のSTREAK3として扱う(重複計上を避ける)。
            if ($last5.Count -eq 5 -and (Test-SameNonCompletedStreak $last5)) {
                $lastRow = $last5[-1]
                $findings += "SEVERE|$($lastRow.Outcome)|直近5回連続でoutcome=$($lastRow.Outcome)です(理由: $($lastRow.Reason))"
            } elseif ($last3.Count -eq 3 -and (Test-SameNonCompletedStreak $last3)) {
                $lastRow = $last3[-1]
                $findings += "STREAK3|$($lastRow.Outcome)|直近3回連続でoutcome=$($lastRow.Outcome)です(理由: $($lastRow.Reason))"
            }

            # 条件2: 直近72時間にoutcome=completedが1件も無い
            $cutoff = (Get-Date).AddHours(-72)
            $hasCompletedRecent = (@($rows | Where-Object { $_.ParsedTimestamp -and $_.ParsedTimestamp -ge $cutoff -and $_.Outcome -eq 'completed' })).Count -gt 0
            if (-not $hasCompletedRecent) {
                $findings += 'NOCOMPLETE72H|completed|直近72時間にoutcome=completedの記録がありません'
            }

            # 条件3: 直近5回にerror_*(前方一致)が3件以上含まれる
            if ($last5.Count -gt 0) {
                $errorCount = (@($last5 | Where-Object { $_.Outcome -like 'error_*' })).Count
                if ($errorCount -ge 3) {
                    $findings += "ERRORBURST|error_*|直近$($last5.Count)件中$($errorCount)件がerror_*系のoutcomeです"
                }
            }

            $findings
        }
        Repair          = {
            param($detail)
            # 自動対処なし(検知・通知のみ)。全条件をescalateとして扱う(§3 FP-06、
            # 3回連続/72時間/5回中3件はいずれも同等の扱いでよいと確定済み)。
            $parts = $detail -split '\|', 3
            $kind = $parts[0]; $outcome = $parts[1]; $msg = $parts[2]
            if ($kind -eq 'SEVERE') {
                # 5回連続はより深刻な扱い。後続タスク(night_report見出し変更)が判別できるよう
                # Detail先頭に"SEVERE"種別を残す(§3 FP-06「5回連続」の扱い)。
                return @{ Action = 'none'; Result = 'escalate'; Detail = "SEVERE|$msg(5回連続。night_reportの見出しを「# ⛔ 夜間ループが停止しています(outcome=$outcome が5回連続)」相当に変更してください)" }
            }
            return @{ Action = 'none'; Result = 'escalate'; Detail = $msg }
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
                    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($driveName):'" -OperationTimeoutSec 10 -ErrorAction SilentlyContinue
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

# ============================== 証拠束生成(§5、T5-A65) ==============================
# night_loop.ps1 / claude が読むだけの人間向けMarkdownを固定フォーマットで生成する。
# Watchdog(FP-05(c))が停止処理を行った際に呼ぶ。将来的に未知障害(§4)からも呼べるよう
# 汎用の引数構成にしているが、配線は本タスク(T5-A65)のスコープ外(呼び出しはWatchdogのみ)。
function Get-TailTextSafe {
    param([string]$Path, [int]$Lines, [string]$EmptyMessage)
    if (-not $Path -or -not (Test-Path $Path)) { return $EmptyMessage }
    try {
        $content = @(Get-Content -Path $Path -Tail $Lines -Encoding UTF8 -ErrorAction Stop)
        if ($content.Count -eq 0) { return $EmptyMessage }
        return ($content -join [Environment]::NewLine)
    } catch {
        return "$EmptyMessage(読み取りに失敗: $($_.Exception.Message))"
    }
}

function Generate-EvidenceBundle {
    param(
        [string]$RuleId = 'unknown',
        [string]$Outcome = '',
        $ClaudeExitCodeValue = $null,
        [string]$Trigger = '',
        [string]$DurationText = '',
        [string]$WrapperLogPathOverride = '',
        [string]$ErrLogPathOverride = '',
        [string]$StreamLogPathOverride = ''
    )
    Ensure-Dirs
    $now = Get-Date
    $titleStamp = $now.ToString('yyyy-MM-dd HH:mm:ss')
    $fileStamp = $now.ToString('yyyyMMdd-HHmmss')
    $reportPath = Join-Path $ReportsDir ("{0}-{1}.md" -f $fileStamp, $RuleId)

    $wrapperLogPath = if ($WrapperLogPathOverride) { $WrapperLogPathOverride } else { Join-Path $NightLogsDir ('wrapper-{0}.log' -f (Get-Date -Format 'yyyyMMdd')) }
    $errLogPathResolved = if ($ErrLogPathOverride) { $ErrLogPathOverride } else { $ErrLogPath }
    $streamLogPathResolved = if ($StreamLogPathOverride) { $StreamLogPathOverride } else { $StreamLogPath }

    $wrapperTail = Get-TailTextSafe -Path $wrapperLogPath -Lines 40 -EmptyMessage '(wrapperログが見つかりません)'
    $errTail = Get-TailTextSafe -Path $errLogPathResolved -Lines 40 -EmptyMessage 'stderr は出力されていません'

    $jsonlTail = '(stream-jsonログが見つかりません)'
    if ($streamLogPathResolved -and (Test-Path $streamLogPathResolved)) {
        try {
            $jlines = @(Get-Content -Path $streamLogPathResolved -Tail 3 -Encoding UTF8 -ErrorAction Stop)
            if ($jlines.Count -gt 0) {
                $truncated = $jlines | ForEach-Object {
                    if ($_.Length -gt 500) { $_.Substring(0, 500) + '...(truncated)' } else { $_ }
                }
                $jsonlTail = ($truncated -join [Environment]::NewLine)
            } else {
                $jsonlTail = '(stream-jsonログは空です)'
            }
        } catch {
            $jsonlTail = "(stream-jsonログの読み取りに失敗しました: $($_.Exception.Message))"
        }
    }

    $gitStatusText = 'クリーン'
    try {
        $gitLines = @(& git -C $RepoRoot status --porcelain 2>$null)
        $gitLines = @($gitLines | Where-Object { $_ })
        if ($gitLines.Count -gt 0) { $gitStatusText = ($gitLines -join [Environment]::NewLine) }
    } catch {
        $gitStatusText = "(git status の取得に失敗しました: $($_.Exception.Message))"
    }

    $outcomesTail = Get-TailTextSafe -Path (Join-Path $ClaudeDir 'night_outcomes.log') -Lines 5 -EmptyMessage '(night_outcomes.log が見つかりません、または記録がありません)'

    # 既知シグネチャとの照合結果: $Rules配列の各ルールのDetectを(Repairは呼ばず)安全に呼び出す。
    # 例外は「判定不能」として扱いfail-openにする(§5)。
    $sigLines = @()
    foreach ($r in $Rules) {
        try {
            $f = @(& $r.Detect)
            if ($f.Count -gt 0) {
                $sigLines += "- $($r.Id): 一致"
            } else {
                $sigLines += "- $($r.Id): 不一致"
            }
        } catch {
            $sigLines += "- $($r.Id): 判定不能($($_.Exception.Message))"
        }
    }

    $exitCodeText = if ($null -ne $ClaudeExitCodeValue) { $ClaudeExitCodeValue.ToString() } else { '(不明)' }

    $lines = @()
    $lines += "# 障害レポート $titleStamp — $RuleId"
    $lines += ''
    $lines += "- **phase**: $PhaseLower"
    $lines += "- **outcome**: $Outcome"
    $lines += "- **claude 終了コード**: $exitCodeText"
    $lines += "- **トリガー**: $Trigger"
    $lines += "- **所要時間**: $DurationText"
    $lines += ''
    $lines += '## 直近の wrapper ログ(末尾40行)'
    $lines += '```'
    $lines += $wrapperTail
    $lines += '```'
    $lines += ''
    $lines += '## stderr(末尾40行)'
    $lines += '```'
    $lines += $errTail
    $lines += '```'
    $lines += ''
    $lines += '## stream-json の最終3イベント'
    $lines += '```'
    $lines += $jsonlTail
    $lines += '```'
    $lines += ''
    $lines += '## 作業ツリーの状態'
    $lines += '```'
    $lines += $gitStatusText
    $lines += '```'
    $lines += ''
    $lines += '## 直近5回の発火結果'
    $lines += '```'
    $lines += $outcomesTail
    $lines += '```'
    $lines += ''
    $lines += '## 既知シグネチャとの照合結果'
    $lines += $sigLines

    $md = ($lines -join [Environment]::NewLine)
    try {
        Set-Content -Path $reportPath -Value $md -Encoding utf8
        return $reportPath
    } catch {
        Write-Progress2 "証拠束の書き込みに失敗しました: $($_.Exception.Message)"
        return $null
    }
}

# ============================== Watchdogモード(FP-05(c)、T5-A65) ==============================
# night_loop.ps1 の手順9で別プロセスとして起動される想定(§2-1)。既存のPreflight/Postmortem/
# Checkのメイン処理(ルール配列を1回ずつ回す)とは別建てで、内部にポーリングループを持つ。

# 監視対象プロセスの特定(§3 FP-05(c))。$RootPidから深さ5まで再帰的に子孫プロセスを列挙し、
# Name=claude.exe/node.exe かつ CommandLineに night_loop を含むものだけを対象にする。
# 名前一致の総当たりkillを避けるための厳密な特定手順(誤爆回避)。
function Get-WatchdogTargets {
    param([int]$RootPid)
    $maxDepth = 5
    $currentPids = @($RootPid)
    $allDescendants = @()
    for ($d = 1; $d -le $maxDepth; $d++) {
        if ($currentPids.Count -eq 0) { break }
        $children = @()
        foreach ($p in $currentPids) {
            try {
                $kids = @(Get-CimInstance -ClassName Win32_Process -Filter "ParentProcessId=$p" -ErrorAction Stop)
                foreach ($k in $kids) { $children += $k }
            } catch {
                # 取得失敗はfail-open(その系統の探索はここで打ち切るのみ、全体は継続)
            }
        }
        if ($children.Count -eq 0) { break }
        $allDescendants += $children
        $currentPids = $children | ForEach-Object { $_.ProcessId }
    }
    $targets = @($allDescendants | Where-Object {
            $_.Name -in @('claude.exe', 'node.exe') -and $_.CommandLine -and ($_.CommandLine -match 'night_loop')
        })
    # $allDescendantsは深さの浅い順に追加されているため、フィルタ後に反転すると
    # 深い(=子孫側)ものが先頭に来る。「子孫から順に」停止するための近似的な順序付け。
    [array]::Reverse($targets)
    return $targets
}

if ($Mode -eq 'Watchdog') {
    try {
        Write-Progress2 "Watchdogモードを開始します(WrapperPid=$WrapperPid, StallMinutes=$StallMinutes, HardCapMinutes=$HardCapMinutes, Unattended=$($Unattended.IsPresent))。"
        Ensure-EventsFile
        $watchdogStart = Get-Date
        $stopFlagPath = Join-Path $ClaudeDir 'night_watchdog.stop'
        $pollIntervalSec = 30
        $warnedStall = $false
        $lastLen = $null
        $lastWrite = $null
        $noGrowthSinceUtc = $null

        while ($true) {
            # Watchdog自身の自己終了条件(孤児化防止、毎ポーリングで確認、§3 FP-05(c))。
            if (Test-Path $stopFlagPath) {
                Write-Progress2 "停止フラグ($stopFlagPath)を検知したため終了します。"
                $selfStopObj = [ordered]@{ ok = $true; phase = 'watchdog'; detected = @(); escalate = $false; escalations = @() }
                ($selfStopObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
                exit 0
            }
            $wrapperAlive = [bool](Get-Process -Id $WrapperPid -ErrorAction SilentlyContinue)
            if (-not $wrapperAlive) {
                Write-Progress2 "WrapperPid=$WrapperPid が既に存在しないため終了します。"
                $selfStopObj = [ordered]@{ ok = $true; phase = 'watchdog'; detected = @(); escalate = $false; escalations = @() }
                ($selfStopObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
                exit 0
            }

            $elapsedMin = ((Get-Date) - $watchdogStart).TotalMinutes
            $hardcapHit = ($elapsedMin -ge $HardCapMinutes)

            # stall判定: -StreamLogPathの.jsonlのLength/LastWriteTimeを都度取得するのみで、
            # ファイルハンドルは保持しない(§3 FP-05(c)、Watchdog自身がFP-01の原因になるのを防ぐ)。
            $curLen = $null
            $curWrite = $null
            if ($StreamLogPath -and (Test-Path $StreamLogPath)) {
                try {
                    $item = Get-Item -LiteralPath $StreamLogPath -ErrorAction Stop
                    $curLen = $item.Length
                    $curWrite = $item.LastWriteTime
                } catch {
                    # 取得失敗はfail-open(stall扱いにしない)
                }
            }

            if (($null -ne $curLen) -and ($null -ne $lastLen) -and ($curLen -eq $lastLen) -and ($curWrite -eq $lastWrite)) {
                if (-not $noGrowthSinceUtc) { $noGrowthSinceUtc = Get-Date }
            } else {
                $noGrowthSinceUtc = $null
                $warnedStall = $false
            }
            $lastLen = $curLen
            $lastWrite = $curWrite

            $noGrowthMin = if ($noGrowthSinceUtc) { ((Get-Date) - $noGrowthSinceUtc).TotalMinutes } else { 0 }
            $stallHit = ($noGrowthMin -ge $StallMinutes)
            $doubleStallHit = ($noGrowthMin -ge ($StallMinutes * 2))

            if ($hardcapHit -or $doubleStallHit) {
                $triggerReason = if ($hardcapHit) { "hardcap到達(起動から$([math]::Round($elapsedMin,1))分、上限${HardCapMinutes}分)" } else { "stream-jsonが$([math]::Round($noGrowthMin,1))分間無成長(閾値$($StallMinutes * 2)分)" }
                $durationText = "{0:N1}分" -f $elapsedMin
                $triggerText = "$($watchdogStart.ToString('HHmm')) / $(if ($Unattended) { '無人モード' } else { '有人モード' })"

                if (-not $Unattended) {
                    # 有人時の縮退(§3-2): 停止処理は行わず検知のみ(FP-03と同じ扱い)。
                    Write-FailureEvent -Phase 'watchdog' -RuleId 'FP-05-HANG-WATCHDOG' -Severity 'escalate' -Action 'none' -Result 'escalate' -Detail "$triggerReason を検知しましたが有人モードのため停止処理は行わず検知のみとします。"
                    $reportPath = Generate-EvidenceBundle -RuleId 'FP-05-HANG-WATCHDOG' -Outcome 'error_watchdog_stall' -Trigger $triggerText -DurationText $durationText
                    $stopObj = [ordered]@{ ok = $false; phase = 'watchdog'; detected = @(@{ ruleId = 'FP-05-HANG-WATCHDOG'; severity = 'escalate'; action = 'none'; result = 'escalate'; detail = $triggerReason }); escalate = $true; escalations = @(@{ ruleId = 'FP-05-HANG-WATCHDOG'; detail = $triggerReason }); reportPath = $reportPath }
                    ($stopObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
                    Write-Progress2 "$triggerReason (有人時のため停止処理なし。証拠束: $reportPath)"
                    # exit 2はFP-07の必須バイナリ不在・ディスク空き不足専用(P1・§2-3)。
                    # スタール/hardcap検知は絶対にabortしないため、ここは「検知したが続行可能」の
                    # exit 1とする(JSONのok:false/escalate:true/escalationsで検知内容は伝える)。
                    exit 1
                }

                $targets = Get-WatchdogTargets -RootPid $WrapperPid
                if ($targets.Count -eq 0) {
                    # 対象0件なら停止処理を行わずescalateのみ(誤爆回避、§3-2の唯一の例外条件)。
                    Write-FailureEvent -Phase 'watchdog' -RuleId 'FP-05-HANG-WATCHDOG' -Severity 'escalate' -Action 'none' -Result 'escalate' -Detail "$triggerReason を検知しましたが、対象プロセス(WrapperPid=$WrapperPid の子孫でName=claude.exe/node.exeかつCommandLineにnight_loopを含むもの)が0件のため停止処理は行わずescalateのみとします。"
                    $reportPath = Generate-EvidenceBundle -RuleId 'FP-05-HANG-WATCHDOG' -Outcome 'error_watchdog_stall' -Trigger $triggerText -DurationText $durationText
                    $stopObj = [ordered]@{ ok = $false; phase = 'watchdog'; detected = @(@{ ruleId = 'FP-05-HANG-WATCHDOG'; severity = 'escalate'; action = 'none'; result = 'escalate'; detail = $triggerReason }); escalate = $true; escalations = @(@{ ruleId = 'FP-05-HANG-WATCHDOG'; detail = $triggerReason }); reportPath = $reportPath }
                    ($stopObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
                    Write-Progress2 "$triggerReason (対象0件のため停止処理なし。証拠束: $reportPath)"
                    # exit 2はFP-07専用(P1・§2-3)。対象0件の誤爆回避時もexit 1とする。
                    exit 1
                }

                # 子孫から順にStop-Process -Force(§3 FP-05(c)。作業ツリーには一切触れない)。
                $stoppedList = @()
                foreach ($t in $targets) {
                    try {
                        Stop-Process -Id $t.ProcessId -Force -ErrorAction Stop
                        $stoppedList += "PID=$($t.ProcessId)($($t.Name))"
                    } catch {
                        $stoppedList += "PID=$($t.ProcessId)($($t.Name)) 停止失敗: $($_.Exception.Message)"
                    }
                }
                $stopDetail = "$triggerReason を検知し、対象プロセスを停止しました: $($stoppedList -join ', ')"
                Write-FailureEvent -Phase 'watchdog' -RuleId 'FP-05-HANG-WATCHDOG' -Severity 'escalate' -Action 'stopped_process' -Result 'escalate' -Detail $stopDetail
                $reportPath = Generate-EvidenceBundle -RuleId 'FP-05-HANG-WATCHDOG' -Outcome 'error_watchdog_stall' -Trigger $triggerText -DurationText $durationText
                $stopObj = [ordered]@{ ok = $false; phase = 'watchdog'; detected = @(@{ ruleId = 'FP-05-HANG-WATCHDOG'; severity = 'escalate'; action = 'stopped_process'; result = 'escalate'; detail = $stopDetail }); escalate = $true; escalations = @(@{ ruleId = 'FP-05-HANG-WATCHDOG'; detail = $stopDetail }); reportPath = $reportPath }
                ($stopObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
                Write-Progress2 "$stopDetail (証拠束: $reportPath)"
                # exit 2はFP-07専用(P1・§2-3)。プロセス停止を実施した場合もexit 1とする。
                exit 1
            } elseif ($stallHit -and -not $warnedStall) {
                Write-FailureEvent -Phase 'watchdog' -RuleId 'FP-05-HANG-WATCHDOG' -Severity 'warn' -Action 'none' -Result 'warned' -Detail "stream-jsonが${StallMinutes}分間変化していません(StreamLogPath=$StreamLogPath)。監視を継続します(1段目、警告のみ)。"
                $warnedStall = $true
            }

            Start-Sleep -Seconds $pollIntervalSec
        }
    } catch {
        # フェイルオープン(P1): Watchdog自身の例外でループを止めない。記録だけ残してexit 0する。
        try {
            Write-FailureEvent -Phase 'watchdog' -RuleId 'FP-INTERNAL' -Severity 'warn' -Action 'none' -Result 'internal_error' -Detail $_.Exception.Message
        } catch {
            # 記録すら失敗した場合は諦める
        }
        Write-Progress2 "Watchdog内部エラーが発生しましたが、fail-openの方針によりexit 0で終了します: $($_.Exception.Message)"
        $fallbackObj = [ordered]@{ ok = $true; phase = 'watchdog'; detected = @(); escalate = $false; escalations = @(); internalError = $_.Exception.Message }
        ($fallbackObj | ConvertTo-Json -Compress -Depth 10) | Write-Output
        exit 0
    }
}

# ============================== メイン処理 ==============================
try {
    Write-Progress2 "モード=$Mode で開始します。"
    $testHangSec = $env:BEANBASE_FP_TEST_HANG_SEC
    if ($testHangSec) { Write-Progress2 "テスト用ハングフック(BEANBASE_FP_TEST_HANG_SEC=$testHangSec)により${testHangSec}秒待機します。"; Start-Sleep -Seconds ([int]$testHangSec) }
    Ensure-EventsFile
    $State = Get-FailureState

    $detected = @()
    $escalations = @()
    $abort = $false
    $anyUnresolved = $false
    $detectElapsedTotalSec = 0.0

    foreach ($rule in $Rules) {
        if ($rule.Phase -notcontains $Mode) { continue }

        if ($detectElapsedTotalSec -ge $Config.detectBudgetSec) {
            # Detectの累積所要が予算を超えた場合、本ルールは実行せず「判定不能(タイムアウト)」
            # として記録するだけに留める(fail-open、ループ自体は中断しない、§8リスク表)。
            $skipDetail = "Detectの累積所要が予算$($Config.detectBudgetSec)秒を超えたため、本ルールは判定不能(タイムアウト)として実行をスキップしました。"
            Write-FailureEvent -Phase $PhaseLower -RuleId $rule.Id -Severity 'escalate' -Action 'none' -Result 'skipped_timeout' -Detail $skipDetail
            $detected += [ordered]@{
                ruleId   = $rule.Id
                severity = 'escalate'
                action   = 'none'
                result   = 'skipped_timeout'
                detail   = $skipDetail
            }
            $escalations += [ordered]@{ ruleId = $rule.Id; detail = $skipDetail }
            $anyUnresolved = $true
            continue
        }

        $findings = @()
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $findings = @(& $rule.Detect)
            $sw.Stop()
            $detectSec = $sw.Elapsed.TotalSeconds
            $detectElapsedTotalSec += $detectSec
            if ($detectSec -gt $Config.slowDetectWarnSec) {
                Write-FailureEvent -Phase $PhaseLower -RuleId $rule.Id -Severity 'warn' -Action 'none' -Result 'slow_detect' -Detail "Detectに$([math]::Round($detectSec, 1))秒かかりました(警告閾値$($Config.slowDetectWarnSec)秒)。"
            }
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
