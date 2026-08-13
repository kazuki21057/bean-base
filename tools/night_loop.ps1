<#
    night_loop.ps1 — 夜間無人実行ラッパー (T5-A10 / T5-A18)

    正本: docs/android_release/開発運用基盤設計.md §2(2-1〜2-5)・§4-4・§7
    Windows タスクスケジューラ(23:00 / 04:10 / 09:20 予定)から起動される。
    判断できることはすべてここ(PowerShell)で行い、LLM(claude)には
    「どのタスクを実装しどう直すか」だけを委ねる。

    使い方:
      powershell -File tools\night_loop.ps1               通常起動
      powershell -File tools\night_loop.ps1 -DryRun        claudeを起動せず予定コマンドと
                                                             環境変数伝搬だけを確認する
      powershell -File tools\night_loop.ps1 -Force         有人セッション活動チェック・
                                                             作業ツリー汚れガード・
                                                             週次予算ガードをスキップする
                                                             (有人監視下試走用、多重起動
                                                             ガード・slug解決・
                                                             settings.night.json存在チェック・
                                                             git pullはスキップしない。
                                                             Proプラン使用率ログの記録は
                                                             2026-08-13にゲートから記録専用
                                                             へ変更したためスキップ対象では
                                                             なく、-Force指定時も記録する)
      powershell -File tools\night_loop.ps1 -ConfigPath X  既定は tools\night_loop.config.json

    tools/night_loop.config.json のキー(JSONにコメントを書けないためここに説明を置く):
      weeklyRunLimit          週次予算ガードの上限回数(既定15、2026-08-13に12→15へ変更)。
                              直近7日の.claude/night_runs.log の行数がこれ以上ならスキップする。
      activeSessionMinutes    有人セッション活動チェックの窓の長さ(分、既定45)。
                              プロジェクトのtranscript(*.jsonl)から抽出した最新の会話
                              エントリのtimestampからこの分数未満ならスキップする
                              (2026-08-13、T5-A12。旧sessionWindowHoursのmtime方式は
                              アイドル中セッションのmtime書き換え周期と判定窓が一致し
                              恒久スキップを起こしたため廃止)。
      usageLogEnabled         Proプラン使用率記録の有効/無効(既定true)。2026-08-13、
                              ユーザー判断によりゲート(スキップ判定)を撤廃し記録専用に
                              変更(旧usageGuardEnabledから改名、値は
                              .claude/night_usage_log.tsvに追記する)。
      usageGuardUrl           使用率取得先URL(既定 http://localhost:3000/)。
      usageGuardTimeoutSec    使用率取得のタイムアウト秒数(既定3)。
      worktreeGuardEnabled    作業ツリー汚れガードの有効/無効(既定true)。
      staleLockHours          多重起動ガードのロックファイルをstale(放棄済み)とみなす
                              経過時間(既定3)。PIDが実在してもこの時間を超えていれば
                              奪取する。
      model                   claude起動時の --model(既定 "sonnet")。
      maxBudgetUsd            claude起動時の --max-budget-usd(既定20、2026-08-13に8→20へ
                              変更、設計書§5の夜間コスト上限$20に対応)。旧 maxTurns キーは
                              廃止(--max-turnsはclaude CLIに実在しないオプションのため
                              2026-08-08に置き換えた)。
      settingsPath            claude起動時の --settings に渡すパス
                              (既定 ".claude\settings.night.json")。
      projectSlug             ~/.claude/projects/ 配下のプロジェクトslugを明示指定したい
                              場合に設定する(既定 null = 自動解決)。指定時は存在確認し、
                              無ければエラー終了する。
      (廃止キー) usageSessionMaxPercent / usageWeekMaxPercent — 2026-08-13、使用率ガードの
                              ゲート撤廃に伴い廃止。設定ファイルに残っていてもWARNログを
                              出すのみで無視される(sessionWindowHoursと同じ非推奨パターン)。

    終了コード:
      0  正常終了 / 正常スキップ(多重起動中・有人セッション活動中・
         作業ツリー汚れあり・週次上限到達)
      2  エラー終了(設定ファイルJSON不正・プリフライトチェック失敗・claude未検出・
         slug解決失敗・settings.night.json不在/JSON不正・git pull失敗)
      3  claude が異常終了した(claudeの終了コードが非0)
#>

param(
    [switch]$DryRun,
    [switch]$Force,
    [string]$ConfigPath = ''
)

# --- 基本パス ---
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $ConfigPath) {
    $ConfigPath = Join-Path $RepoRoot 'tools\night_loop.config.json'
}

$ClaudeDir = Join-Path $RepoRoot '.claude'
$NightLogsDir = Join-Path $ClaudeDir 'night_logs'
if (-not (Test-Path $NightLogsDir)) {
    New-Item -ItemType Directory -Path $NightLogsDir -Force | Out-Null
}
# wrapper.log は日次ローテーション(2026-08-12 障害対応)。単一の追記ファイルを誰かが
# tail -f 等で開き続けると、その瞬間から書き込み不能になり続ける実害が起きたため、
# 日次分割にして被害を当日限りに抑える。
$WrapperLogPath = Join-Path $NightLogsDir ('wrapper-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))
$LockPath = Join-Path $ClaudeDir 'night_loop.lock'
$RunsLogPath = Join-Path $ClaudeDir 'night_runs.log'
$RunCountPath = Join-Path $ClaudeDir 'night_loop_run_count.txt'
$NightReportPath = Join-Path $RepoRoot 'night_report.md'
$ProjectsRoot = Join-Path $HOME '.claude\projects'
# 障害対応(ロック競合等でwrapper.logへの記録が無音で失われる問題への対策):
# 直近1回の起動結果を必ず上書き記録するファイルと、5時間枠スキップの専用ログ。
$LastRunPath = Join-Path $ClaudeDir 'night_loop_last_run.json'
$NightSkipsLogPath = Join-Path $ClaudeDir 'night_skips.log'
# Proプラン使用率の記録専用ログ(T5-A60、2026-08-13。ゲートは撤廃したが値の記録は継続する)。
$NightUsageLogPath = Join-Path $ClaudeDir 'night_usage_log.tsv'

$ScriptStart = Get-Date

# --- トリガー時刻の判定(T5-A60、2026-08-13新設) ---
# 23:00/04:10/09:20のどの発火枠かを判定し、claude子プロセスへ環境変数で伝搬する
# (04:10/09:20枠では承認待ちタスクの準備を優先するため、/night_loopスキル側で使う)。
# 日付境界をまたぐ23:00枠があるため「その日の00:00からの経過分数」で比較する。
function Get-NightTriggerLabel {
    param([datetime]$Timestamp)
    $minutesOfDay = $Timestamp.Hour * 60 + $Timestamp.Minute
    # 深夜〜早朝枠(23:00): 21:30〜23:59(1290〜1439分)、および00:00〜01:00(0〜60分)
    if (($minutesOfDay -ge 1290) -or ($minutesOfDay -le 60)) {
        return '2300'
    }
    # 早朝枠(04:10): 03:00〜05:30(180〜330分)
    if ($minutesOfDay -ge 180 -and $minutesOfDay -le 330) {
        return '0410'
    }
    # 朝枠(09:20): 08:00〜10:30(480〜630分)
    if ($minutesOfDay -ge 480 -and $minutesOfDay -le 630) {
        return '0920'
    }
    return 'manual'
}
$TriggerLabel = Get-NightTriggerLabel -Timestamp $ScriptStart

$script:LockAcquired = $false

# --- 多層防御: --disallowedTools に渡す一覧(設計書§4-4 denyの全項目をミラー) ---
$DisallowedToolsList = @(
    # デプロイ(本番反映は無人では一切させない)
    'Bash(firebase deploy*)',
    'Bash(npx firebase deploy*)',
    'Bash(npx -y firebase-tools* deploy*)',
    'PowerShell(firebase deploy*)',
    'PowerShell(npx firebase deploy*)',
    'Bash(clasp push*)',
    'Bash(clasp deploy*)',
    'Bash(clasp redeploy*)',
    'PowerShell(clasp push*)',
    'PowerShell(clasp deploy*)',
    'PowerShell(clasp redeploy*)',
    # 自分のPRを自分でマージ・リリースさせない
    'Bash(gh pr merge*)',
    'PowerShell(gh pr merge*)',
    'Bash(gh release*)',
    'PowerShell(gh release*)',
    # force push
    # 注意: denyのパターンはワイルドカード前方一致で判定されるため、
    # 'git push * -f *' のような中間一致形は 'git push -f origin main' のような
    # 最も自然な書き方を捕まえられない(adversaryの実測: PowerShellの-likeで
    # 'git push -f origin main' -like 'git push * -f *' は False)。
    # -f系は前方一致形を中心に列挙する。
    'Bash(git push * --force*)',
    'Bash(git push --force*)',
    'Bash(git push * -f *)',
    'Bash(git push -f*)',
    'Bash(git push * -f)',
    'PowerShell(git push * --force*)',
    'PowerShell(git push --force*)',
    'PowerShell(git push * -f *)',
    'PowerShell(git push -f*)',
    'PowerShell(git push * -f)',
    # 履歴・ブランチの破壊的操作
    'Bash(git reset --hard*)',
    'Bash(git clean -f*)',
    'Bash(git branch -D*)',
    'Bash(git rebase*)',
    'PowerShell(git reset --hard*)',
    'PowerShell(git clean -f*)',
    'PowerShell(git branch -D*)',
    'PowerShell(git rebase*)',
    # ファイルの破壊的削除
    'Bash(rm -rf*)',
    'Bash(rm -fr*)',
    'PowerShell(Remove-Item *-Recurse*)',
    'PowerShell(rmdir *)',
    # 認証情報・git設定の書き換え
    'Bash(gh auth*)',
    'Bash(firebase login*)',
    'Bash(git config*)',
    'PowerShell(gh auth*)',
    'PowerShell(firebase login*)',
    'PowerShell(git config*)'
)

# ============================== ログ・通知 ==============================

# ロック耐性のある1行追記ヘルパー Write-LineWithRetry は tools/lib/loop_io.ps1 へ
# 移設した(T5-A61、docs/failure_playbook.md §1-3・§7)。tools/failure_playbook.ps1
# からも同じ実装を共有するため。関数名・シグネチャは変更していないので、以下の
# 呼び出し箇所は無変更で動く。
. (Join-Path $PSScriptRoot 'lib\loop_io.ps1')

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    # Write-Output ではなく Write-Host を使う: Write-Log は Get-NightLoopConfig /
    # Invoke-NightLoop など戻り値を持つ関数の内部からも呼ばれるため、成功出力
    # ストリームに書くと戻り値(ハッシュテーブル/終了コード)に混ざってしまう。
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line
    $fallbackPath = Join-Path $NightLogsDir ('wrapper.fallback-{0}.log' -f $PID)
    $result = Write-LineWithRetry -Path $WrapperLogPath -Line $line -FallbackPath $fallbackPath
    if (-not $result.Success) {
        Write-Host ('[{0}] [WARN] wrapper.log への書き込みに失敗しました: {1}(フォールバック先: {2})' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $result.ErrorMessage, $fallbackPath)
    }
}

function Send-ToastNotification {
    param(
        [string]$Title,
        [string]$Text
    )
    try {
        if (Get-Module -ListAvailable -Name BurntToast) {
            Import-Module BurntToast -ErrorAction Stop
            New-BurntToastNotification -Text $Title, $Text | Out-Null
            Write-Log 'INFO' 'BurntToast でトースト通知を送信しました。'
        } else {
            Write-Log 'INFO' 'BurntToast モジュールが無いためトースト通知はスキップします。'
        }
    } catch {
        Write-Log 'WARN' ('BurntToast 通知に失敗しました: {0}' -f $_.Exception.Message)
    }
}

# エラー終了・スキップ通知用の共通フォールバック(night_report.md 上書き + トースト)。
# .claude/skills/night_loop/SKILL.md の「失敗・中断時」テンプレートに準じる。
function Send-NightNotification {
    param(
        [string]$ResultLine,
        [string]$Detail
    )
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $body = @(
        ('# 夜間ループ報告 {0}' -f $stamp),
        '',
        '- **タスク**: (未選定 — night_loop.ps1 のガードで中止したため claude を起動していない)',
        ('- **結果**: {0}' -f $ResultLine),
        '- **検証**: 未実施(claude起動前にラッパースクリプトが中止)',
        ('- **人がやること**: {0}' -f $Detail),
        '- **次のタスク**: 次回のスケジュール発火時に同じ内容で再試行'
    ) -join "`n"
    try {
        Set-Content -Path $NightReportPath -Value $body -Encoding utf8
        Write-Log 'INFO' 'night_report.md を更新しました。'
    } catch {
        Write-Log 'WARN' ('night_report.md の更新に失敗しました: {0}' -f $_.Exception.Message)
    }
    Send-ToastNotification -Title 'BeanBase 夜間ループ' -Text $ResultLine
}

# 直近1回の起動結果を必ず上書き記録する(スキップ経路も含め、何をしたか/しなかったかを
# 常にファイルとして残す。wrapper.logがロック等で書けない状況でも、この関数自体が
# 独立したSet-Content呼び出しのため影響を受けにくい)。
function Save-NightLoopLastRun {
    param(
        [string]$Outcome,
        [string]$Reason,
        [int]$ExitCode
    )
    $data = [ordered]@{
        startedAt  = $ScriptStart.ToString('o')
        finishedAt = (Get-Date).ToString('o')
        outcome    = $Outcome
        reason     = $Reason
        exitCode   = $ExitCode
        dryRun     = [bool]$DryRun.IsPresent
        force      = [bool]$Force.IsPresent
    } | ConvertTo-Json -Compress
    try {
        Set-Content -Path $LastRunPath -Value $data -Encoding utf8 -ErrorAction Stop
    } catch {
        Write-Log 'WARN' ('{0} の書き込みに失敗しました: {1}' -f $LastRunPath, $_.Exception.Message)
    }
}

# 有人セッション活動チェック用ヘルパー(2026-08-13、T5-A12)。
# transcript(*.jsonl)の「最終更新時刻(mtime)」は、開いたままのセッションが会話が無くても
# 周期的に書き換えることが実測で確認されており(旧方式は判定窓5時間と書き換え周期5時間が
# 一致し恒久スキップを起こした)、代理指標として成立しない。会話エントリ自体のtimestampを
# 見る方式に切り替える。
function Get-LastConversationActivity {
    param([string]$TranscriptDir)

    $jsonlFiles = @(Get-ChildItem -Path $TranscriptDir -Filter '*.jsonl' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 5)

    $latest = $null
    $pattern = '"timestamp":"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z)"'
    foreach ($file in $jsonlFiles) {
        $lines = Get-Content -Path $file.FullName -Tail 200 -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            $matches = [regex]::Matches($line, $pattern)
            foreach ($m in $matches) {
                $ts = $null
                try {
                    $ts = [datetime]::Parse($m.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind).ToLocalTime()
                } catch {
                    continue
                }
                if ($null -eq $latest -or $ts -gt $latest) {
                    $latest = $ts
                }
            }
        }
    }
    return $latest
}

# --disallowedTools を含む起動予定コマンドを組み立てる(設計書§2-4の改訂版がベース。
# ただしstdout/stderrの扱いはadversary指摘M3対応でTee-Object単独+stderr個別ファイルに
# 変更しているため、実際にInvoke-NightLoopが実行する内容と一致させて表示する)。
function Format-PlannedCommand {
    param(
        [hashtable]$Config,
        [string]$LogFileName,
        [string]$ErrLogFileName
    )
    $toolsPart = ($DisallowedToolsList | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $lines = @(
        'claude -p "/night_loop" `',
        ('  --model {0} `' -f $Config.model),
        ('  --settings "{0}" `' -f $Config.settingsPath),
        '  --permission-mode dontAsk `',
        ('  --max-budget-usd {0} `' -f $Config.maxBudgetUsd),
        '  --output-format stream-json --verbose `',
        ('  --disallowedTools {0} `' -f $toolsPart),
        ('  2> ".claude\night_logs\{0}" | Tee-Object -FilePath ".claude\night_logs\{1}" | Out-Host' -f $ErrLogFileName, $LogFileName)
    )
    return ($lines -join "`n")
}

# ============================== 設定読み込み ==============================

function Get-NightLoopConfig {
    param([string]$Path)

    $config = @{
        weeklyRunLimit         = 15
        activeSessionMinutes   = 45
        usageLogEnabled        = $true
        usageGuardUrl          = 'http://localhost:3000/'
        usageGuardTimeoutSec   = 3
        worktreeGuardEnabled   = $true
        staleLockHours         = 3
        model                  = 'sonnet'
        maxBudgetUsd           = 20
        settingsPath           = '.claude\settings.night.json'
        projectSlug            = $null
    }

    if (-not (Test-Path $Path)) {
        # 設定ファイル自体が存在しないのはエラーにしない(既定値で続行)。
        Write-Log 'INFO' ('設定ファイルが見つからないため既定値で続行します: {0}' -f $Path)
        return $config
    }

    # ファイルは存在するがJSONとして不正な場合は、既定値へ静かにフォールバックしない
    # (projectSlug等のユーザー指定が黙って失われるのを防ぐ、adversary指摘M2対応)。
    # 呼び出し元は $null を「設定ファイル不正、エラー終了すべき」の合図として扱う。
    try {
        $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
        $json = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Log 'ERROR' ('設定ファイルのJSONパースに失敗しました: {0} ({1})' -f $Path, $_.Exception.Message)
        return $null
    }

    foreach ($key in @('weeklyRunLimit', 'activeSessionMinutes', 'usageLogEnabled', 'usageGuardUrl', 'usageGuardTimeoutSec', 'worktreeGuardEnabled', 'staleLockHours', 'model', 'maxBudgetUsd', 'settingsPath', 'projectSlug')) {
        if ($json.PSObject.Properties.Name -contains $key -and $null -ne $json.$key) {
            $config[$key] = $json.$key
        }
    }
    if ($json.PSObject.Properties.Name -contains 'sessionWindowHours') {
        Write-Log 'WARN' '設定の sessionWindowHours は廃止されました(activeSessionMinutes に置き換え)。この値は無視されます。'
    }
    if ($json.PSObject.Properties.Name -contains 'usageSessionMaxPercent' -or $json.PSObject.Properties.Name -contains 'usageWeekMaxPercent') {
        Write-Log 'WARN' '設定の usageSessionMaxPercent / usageWeekMaxPercent は廃止されました(2026-08-13、使用率ガードはゲートではなく記録専用に変更)。これらの値は無視されます。'
    }
    Write-Log 'INFO' ('設定ファイルを読み込みました: {0}' -f $Path)
    return $config
}

# ============================== 本体 ==============================

function Invoke-NightLoop {
    param([hashtable]$Config)

    # --- 2. 多重起動ガード ---
    # PIDだけでの「実在確認」は、無関係な別プロセスへのPID再割当を誤検知する
    # (adversary指摘C2)。ロックにプロセス開始時刻(pidStartTime)も記録し、
    # Get-Process の実際の StartTime と秒単位で一致するかまで確認する。
    if (Test-Path $LockPath) {
        $existingLock = $null
        try {
            $existingLock = Get-Content -Path $LockPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-Log 'WARN' ('既存ロックファイルの読み取りに失敗しました: {0}' -f $_.Exception.Message)
        }

        $isRunning = $false
        if ($existingLock -and $existingLock.pid) {
            $existingProcess = Get-Process -Id $existingLock.pid -ErrorAction SilentlyContinue
            if ($existingProcess) {
                if (-not $existingLock.pidStartTime) {
                    Write-Log 'WARN' ('ロック(PID {0})は開始時刻情報を持たない旧形式のため stale とみなして奪取します。' -f $existingLock.pid)
                } else {
                    $recordedStart = [DateTime]::MinValue
                    $parsedOk = [DateTime]::TryParse([string]$existingLock.pidStartTime, [ref]$recordedStart)
                    $actualStart = $existingProcess.StartTime
                    if ($parsedOk -and [Math]::Abs(($actualStart - $recordedStart).TotalSeconds) -lt 1) {
                        # 同一プロセスであることを確認できた → ロック作成時刻でstale判定
                        $ageHours = [double]::MaxValue
                        $lockCreated = [DateTime]::MinValue
                        if ($existingLock.startedAt -and [DateTime]::TryParse([string]$existingLock.startedAt, [ref]$lockCreated)) {
                            $ageHours = ((Get-Date) - $lockCreated).TotalHours
                        }
                        if ($ageHours -lt [double]$Config.staleLockHours) {
                            $isRunning = $true
                        } else {
                            Write-Log 'WARN' ('ロック(PID {0})は {1} 時間経過しており stale とみなして奪取します。' -f $existingLock.pid, [math]::Round($ageHours, 2))
                        }
                    } else {
                        Write-Log 'WARN' ('ロックのPID {0} は実在しますがプロセス開始時刻が記録と一致しないため(PID再割当の可能性)stale とみなして奪取します。' -f $existingLock.pid)
                    }
                }
            } else {
                Write-Log 'WARN' ('ロックのPID {0} は実在しないため stale とみなして奪取します。' -f $existingLock.pid)
            }
        } else {
            Write-Log 'WARN' 'ロックファイルの内容を解釈できないため stale とみなして奪取します。'
        }

        if ($isRunning) {
            Write-Log 'INFO' ('既に実行中です(PID {0})。今回の起動をスキップします(通知なし)。' -f $existingLock.pid)
            Save-NightLoopLastRun -Outcome 'skipped_lock' -Reason ('既に実行中のためスキップしました(PID {0})' -f $existingLock.pid) -ExitCode 0
            return 0
        }
        Remove-Item -Path $LockPath -Force -ErrorAction SilentlyContinue
    }

    $currentProcessInfo = Get-Process -Id $PID
    $lockData = (@{
        pid           = $PID
        startedAt     = (Get-Date).ToString('o')
        pidStartTime  = $currentProcessInfo.StartTime.ToString('o')
    } | ConvertTo-Json -Compress)
    Set-Content -Path $LockPath -Value $lockData -Encoding utf8
    $script:LockAcquired = $true
    Write-Log 'INFO' ('ロックを取得しました(PID {0})。' -f $PID)

    # --- 2.5. プリフライトチェック(T5-A53) ---
    # 孤児プロセスによるログファイルロック事故(2026-08-12対応、commit 77d6094)や
    # agyのPATH不在事故のような環境異常を、claude起動前の軽量チェックで早期検知する。
    # git pullと同様、native exe(powershell.exe)のstderrをPowerShellのErrorRecordに
    # ラップさせないため cmd /c でストリームを統合してから受け取る。
    Write-Log 'INFO' 'プリフライトチェック(tools/preflight.ps1)を実行します。'
    Push-Location $RepoRoot
    try {
        $preflightOutput = & cmd /c 'powershell -NoProfile -File "tools\preflight.ps1" 2>&1'
        $preflightExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    foreach ($l in $preflightOutput) {
        if ($l) { Write-Log 'INFO' ('[preflight] {0}' -f $l) }
    }
    if ($preflightExit -ne 0) {
        Write-Log 'ERROR' ('プリフライトチェックが失敗しました(終了コード {0})。claudeは起動しません。' -f $preflightExit)
        Send-NightNotification -ResultLine '⛔ エラー終了(プリフライトチェック失敗、環境異常の可能性)' -Detail 'wrapper.log の [preflight] 行を確認し、ログファイルのロック・PATH不備・書き込み権限を調査してください。'
        Save-NightLoopLastRun -Outcome 'error_preflight_failed' -Reason ('プリフライトチェックが失敗しました(終了コード {0})' -f $preflightExit) -ExitCode 2
        return 2
    }
    Write-Log 'INFO' 'プリフライトチェックに合格しました。'

    # --- 3. claude CLI の解決 ---
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claudeCmd) {
        Write-Log 'ERROR' 'claude コマンドが見つかりません(PATHを確認してください)。'
        Send-NightNotification -ResultLine '⛔ エラー終了(claude コマンドが見つからない)' -Detail 'claude CLIがPATH上にあるか確認してください。'
        Save-NightLoopLastRun -Outcome 'error_claude_not_found' -Reason 'claude コマンドが見つかりません(PATHを確認してください)' -ExitCode 2
        return 2
    }
    Write-Log 'INFO' ('claude CLI を検出しました: {0}' -f $claudeCmd.Source)

    # --- 4. プロジェクトslugの解決 ---
    $slug = $null
    if ($Config.projectSlug) {
        $candidate = Join-Path $ProjectsRoot $Config.projectSlug
        if (Test-Path $candidate) {
            $slug = $Config.projectSlug
            Write-Log 'INFO' ('config指定のプロジェクトslugを使用します: {0}' -f $slug)
        } else {
            Write-Log 'ERROR' ('config指定のprojectSlug "{0}" が {1} 配下に存在しません。' -f $Config.projectSlug, $ProjectsRoot)
            Send-NightNotification -ResultLine '⛔ エラー終了(config指定のprojectSlugが存在しない)' -Detail 'tools/night_loop.config.json の projectSlug を確認してください。'
            Save-NightLoopLastRun -Outcome 'error_slug_resolution' -Reason ('config指定のprojectSlug "{0}" が存在しません' -f $Config.projectSlug) -ExitCode 2
            return 2
        }
    } else {
        $expectedSlug = ($RepoRoot -replace '[^A-Za-z0-9]', '-')
        $candidate = Join-Path $ProjectsRoot $expectedSlug
        if (Test-Path $candidate) {
            $slug = $expectedSlug
            Write-Log 'INFO' ('プロジェクトslugを既定規則で解決しました: {0}' -f $slug)
        } else {
            $repoFolderName = Split-Path -Leaf $RepoRoot
            $fallbackCandidates = @()
            if (Test-Path $ProjectsRoot) {
                $fallbackCandidates = @(Get-ChildItem -Path $ProjectsRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like ('*' + $repoFolderName) })
            }
            if ($fallbackCandidates.Count -eq 1) {
                $slug = $fallbackCandidates[0].Name
                Write-Log 'WARN' ('既定規則で解決できなかったためフォールバック(末尾一致)で解決しました: {0}' -f $slug)
            } else {
                Write-Log 'ERROR' ('プロジェクトslugを解決できませんでした(既定規則候補: {0} / フォールバック候補 {1} 件)。' -f $expectedSlug, $fallbackCandidates.Count)
                Send-NightNotification -ResultLine '⛔ エラー終了(プロジェクトslugを解決できない)' -Detail ('~/.claude/projects/ 配下を確認し、必要なら tools/night_loop.config.json の projectSlug を明示指定してください。')
                Save-NightLoopLastRun -Outcome 'error_slug_resolution' -Reason 'プロジェクトslugを解決できませんでした' -ExitCode 2
                return 2
            }
        }
    }
    $TranscriptDir = Join-Path $ProjectsRoot $slug

    # --- 5. 有人セッション活動チェック ---
    if ($Force) {
        Write-Log 'INFO' '-Force指定のため有人セッション活動チェックをスキップします。'
    } else {
        $lastActivity = Get-LastConversationActivity -TranscriptDir $TranscriptDir
        if ($null -eq $lastActivity) {
            Write-Log 'INFO' 'transcriptに会話エントリが見つからないため、有人セッション活動チェックを通過とみなします。'
        } else {
            $elapsedMinutes = ((Get-Date) - $lastActivity).TotalMinutes
            if ($elapsedMinutes -lt [double]$Config.activeSessionMinutes) {
                Write-Log 'INFO' ('直近{0}分以内に有人セッションの会話活動があるため(最終会話{1}、経過{2}分)、今回の発火をスキップします。' -f $Config.activeSessionMinutes, $lastActivity, [math]::Round($elapsedMinutes, 1))
                $skipReason = ('直近{0}分以内に有人セッションの会話活動があるため(最終会話{1}、経過{2}分)' -f $Config.activeSessionMinutes, $lastActivity, [math]::Round($elapsedMinutes, 1))
                $skipFallback = Join-Path $NightLogsDir ('night_skips.fallback-{0}.log' -f $PID)
                $skipLine = "{0}`t{1}`t{2}" -f (Get-Date).ToString('o'), 'skipped_active_session', $skipReason
                $null = Write-LineWithRetry -Path $NightSkipsLogPath -Line $skipLine -FallbackPath $skipFallback
                Save-NightLoopLastRun -Outcome 'skipped_active_session' -Reason $skipReason -ExitCode 0
                return 0
            }
            Write-Log 'INFO' ('直近の会話活動: {0}(経過{1}分)。有人セッション活動チェックを通過しました。' -f $lastActivity, [math]::Round($elapsedMinutes, 1))
        }
    }

    # --- 5.5. Proプラン使用率ログ(2026-08-13、T5-A60でゲートから記録専用へ変更) ---
    # ユーザー判断によりスキップ判定は撤廃した。5時間枠/週次の値はAPI障害時の傾向分析
    # 目的で.claude/night_usage_log.tsvへ記録するのみで、処理は継続する。もはや実行を
    # 止める「ガード」ではないため、-Force指定時も(有人試走モードであっても)記録は
    # 行う(-Forceが免除するのは実行を止めうるガードのみ)。
    if ($Config.usageLogEnabled -ne $true) {
        Write-Log 'INFO' 'Proプラン使用率ログは設定で無効化されているため記録しません。'
    } else {
        $usageSession = $null
        $usageWeek = $null
        $usageFailOpen = $false
        try {
            $usageResponse = Invoke-WebRequest -Uri $Config.usageGuardUrl -TimeoutSec $Config.usageGuardTimeoutSec -UseBasicParsing
            $usageContent = $usageResponse.Content
            $sessionMatch = [regex]::Match($usageContent, 'Current session:\s*(\d+)%', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($sessionMatch.Success) {
                $usageSession = [int]$sessionMatch.Groups[1].Value
            } else {
                Write-Log 'WARN' '使用率APIのレスポンスから5時間枠の値を取得できませんでした。'
            }
            $weekMatch = [regex]::Match($usageContent, 'Current week[^:]*:\s*(\d+)%', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($weekMatch.Success) {
                $usageWeek = [int]$weekMatch.Groups[1].Value
            } else {
                Write-Log 'WARN' '使用率APIのレスポンスから週次の値を取得できませんでした。'
            }
        } catch {
            $usageFailOpen = $true
            Write-Log 'WARN' ('使用率APIに接続できないため使用率ログの記録をスキップします(fail-open): {0}' -f $_.Exception.Message)
        }

        if (-not $usageFailOpen) {
            $sessionText = '未取得'
            if ($null -ne $usageSession) { $sessionText = '{0}%' -f $usageSession }
            $weekText = '未取得'
            if ($null -ne $usageWeek) { $weekText = '{0}%' -f $usageWeek }
            Write-Log 'INFO' ('Proプラン使用率: 5時間枠{0} / 週次{1}。night_usage_log.tsv に記録します(ゲートではないため処理を継続します)。' -f $sessionText, $weekText)

            $usageSessionField = ''
            if ($null -ne $usageSession) { $usageSessionField = [string]$usageSession }
            $usageWeekField = ''
            if ($null -ne $usageWeek) { $usageWeekField = [string]$usageWeek }
            $usageLine = "{0}`t{1}`t{2}" -f (Get-Date).ToString('o'), $usageSessionField, $usageWeekField
            $usageFallback = Join-Path $NightLogsDir ('night_usage_log.fallback-{0}.log' -f $PID)
            $null = Write-LineWithRetry -Path $NightUsageLogPath -Line $usageLine -FallbackPath $usageFallback
        }
    }

    # --- 6. 週次予算ガード ---
    if ($Force) {
        Write-Log 'INFO' '-Force指定のため週次予算ガードをスキップします。'
    } else {
        $recentCount = 0
        $unparsedCount = 0
        if (Test-Path $RunsLogPath) {
            $cutoff = (Get-Date).AddDays(-7)
            foreach ($line in (Get-Content -Path $RunsLogPath -ErrorAction SilentlyContinue)) {
                $t = $line.Trim()
                if (-not $t) { continue }
                $ts = [DateTime]::MinValue
                if ([DateTime]::TryParse($t, [ref]$ts)) {
                    if ($ts -ge $cutoff) { $recentCount++ }
                } else {
                    $unparsedCount++
                }
            }
        }
        if ($unparsedCount -gt 0) {
            Write-Log 'WARN' ('.claude/night_runs.log に日付をパースできない行が {0} 件あったため週次カウントから除外しました。' -f $unparsedCount)
        }
        Write-Log 'INFO' ('直近7日間の実行回数: {0} / 上限 {1}' -f $recentCount, $Config.weeklyRunLimit)
        if ($recentCount -ge [int]$Config.weeklyRunLimit) {
            Write-Log 'INFO' '週次実行上限に達しているため今回の発火をスキップします。'
            Send-NightNotification -ResultLine ('⚠️ スキップ(週次実行上限 {0} 回に到達)' -f $Config.weeklyRunLimit) -Detail 'そのまま待つか、必要なら tools/night_loop.config.json の weeklyRunLimit を見直してください。'
            Save-NightLoopLastRun -Outcome 'skipped_weekly_limit' -Reason ('週次実行上限{0}回に到達しました(直近7日間{1}回)' -f $Config.weeklyRunLimit, $recentCount) -ExitCode 0
            return 0
        }
    }

    # --- 7. .claude/settings.night.json の存在・JSON妥当性チェック ---
    # `claude --print` はJSON検証に失敗したsettingsファイルをエラー無しで黙って無視する
    # (claude --helpの記載どおり実測)。存在するだけでは不十分で、denyが実際に効く形か
    # どうか(=有効なJSONか)まで起動前に確認する(adversary新規指摘対応)。
    $settingsNightPath = Join-Path $RepoRoot $Config.settingsPath
    $settingsProblem = $null
    if (-not (Test-Path $settingsNightPath)) {
        $settingsProblem = 'missing'
        Write-Log 'ERROR' ('{0} が存在しません。' -f $Config.settingsPath)
    } else {
        try {
            $null = Get-Content -Path $settingsNightPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            Write-Log 'INFO' ('{0} の存在とJSON妥当性を確認しました。' -f $Config.settingsPath)
        } catch {
            $settingsProblem = 'invalid'
            Write-Log 'ERROR' ('{0} のJSONパースに失敗しました: {1}' -f $Config.settingsPath, $_.Exception.Message)
        }
    }

    if ($settingsProblem) {
        if ($DryRun) {
            if ($settingsProblem -eq 'missing') {
                Write-Log 'WARN' ('{0} が存在しませんが、-DryRun のため手順8へ進みます。' -f $Config.settingsPath)
            } else {
                Write-Log 'WARN' ('{0} のJSONが不正ですが、-DryRun のため手順8へ進みます。' -f $Config.settingsPath)
            }
        } else {
            $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
            if ($settingsProblem -eq 'missing') {
                $resultLine = '⛔ 中止(T5-A17「.claude/settings.night.json」の設置、ユーザー実施、が未完了のため無人実行を中止した)'
                $humanTodo = 'T5-A17(.claude/settings.night.json の設置)を行ってください'
                $toastText = '.claude/settings.night.json が未設置のため中止しました'
            } else {
                $resultLine = '⛔ 中止(.claude/settings.night.json の内容がJSONとして不正なため無人実行を中止した)'
                $humanTodo = '.claude/settings.night.json の内容を確認し正しいJSONに修正してください(claude --print はJSON検証に失敗したsettingsファイルをエラー無しで無視し、denyが無効化されたまま起動してしまうため)'
                $toastText = '.claude/settings.night.json のJSONが不正なため中止しました'
            }
            $body = @(
                ('# 夜間ループ報告 {0}' -f $stamp),
                '',
                '- **タスク**: (未選定 — night_loop.ps1 のガードで中止したため claude を起動していない)',
                ('- **結果**: {0}' -f $resultLine),
                '- **検証**: 未実施',
                ('- **人がやること**: {0}' -f $humanTodo),
                '- **次のタスク**: 次回のスケジュール発火時に同じ内容で再試行'
            ) -join "`n"
            try {
                Set-Content -Path $NightReportPath -Value $body -Encoding utf8
                Write-Log 'INFO' 'night_report.md を更新しました。'
            } catch {
                Write-Log 'WARN' ('night_report.md の更新に失敗しました: {0}' -f $_.Exception.Message)
            }
            Send-ToastNotification -Title 'BeanBase 夜間ループ' -Text $toastText
            Save-NightLoopLastRun -Outcome 'error_settings' -Reason $resultLine -ExitCode 2
            return 2
        }
    }

    # --- 7.5. 作業ツリー汚れガード ---
    if ($Force) {
        Write-Log 'INFO' '-Force指定のため作業ツリー汚れガードをスキップします。'
    } elseif ($Config.worktreeGuardEnabled -ne $true) {
        Write-Log 'INFO' '作業ツリー汚れガードは設定で無効化されているためスキップします。'
    } else {
        Push-Location $RepoRoot
        try {
            $statusOutput = & cmd /c 'git status --porcelain 2>&1'
            $statusExit = $LASTEXITCODE
        } finally {
            Pop-Location
        }
        if ($statusExit -ne 0) {
            Write-Log 'WARN' ('git status --porcelain が失敗しました(終了コード {0})。作業ツリー汚れガードは通過とみなします(直後の git pull が同じ異常を捕まえます)。' -f $statusExit)
        } else {
            $dirtyLines = @($statusOutput | Where-Object { $_ -and $_.Trim() })
            if ($dirtyLines.Count -gt 0) {
                $dirtyCount = $dirtyLines.Count
                $firstLine = $dirtyLines[0]
                Write-Log 'INFO' ('作業ツリーに未コミットの変更が{0}件あるため(先頭: {1})、今回の発火をスキップします。' -f $dirtyCount, $firstLine)
                $skipReason = ('作業ツリーに未コミットの変更が{0}件あるため(先頭: {1})' -f $dirtyCount, $firstLine)
                $skipFallback = Join-Path $NightLogsDir ('night_skips.fallback-{0}.log' -f $PID)
                $skipLine = "{0}`t{1}`t{2}" -f (Get-Date).ToString('o'), 'skipped_dirty_worktree', $skipReason
                $null = Write-LineWithRetry -Path $NightSkipsLogPath -Line $skipLine -FallbackPath $skipFallback
                Send-NightNotification -ResultLine '⚠️ スキップ(作業ツリーに未コミットの変更あり)' -Detail 'git status を確認し、コミットまたは退避してから次回の発火を待ってください。'
                Save-NightLoopLastRun -Outcome 'skipped_dirty_worktree' -Reason $skipReason -ExitCode 0
                return 0
            }
            Write-Log 'INFO' '作業ツリーはクリーンです。'
        }
    }

    # --- 8. git pull --ff-only ---
    Write-Log 'INFO' 'git pull --ff-only を実行します。'
    Push-Location $RepoRoot
    try {
        # native exe の stderr を PowerShell の ErrorRecord にラップさせず、
        # cmd.exe 側でストリームを統合してから受け取る(2>&1直付けの落とし穴を回避)。
        $pullOutput = & cmd /c 'git pull --ff-only 2>&1'
        $pullExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    foreach ($l in $pullOutput) {
        if ($l) { Write-Log 'INFO' ('git pull: {0}' -f $l) }
    }
    if ($pullExit -ne 0) {
        Write-Log 'ERROR' ('git pull --ff-only が失敗しました(終了コード {0})。claudeは起動しません。' -f $pullExit)
        Send-NightNotification -ResultLine '⛔ エラー終了(git pull --ff-only 失敗、コンフリクトの可能性)' -Detail 'リポジトリの状態を確認し、手動でpull/コンフリクト解消してください。'
        Save-NightLoopLastRun -Outcome 'error_git_pull' -Reason ('git pull --ff-only が失敗しました(終了コード {0})' -f $pullExit) -ExitCode 2
        return 2
    }
    Write-Log 'INFO' 'git pull --ff-only が完了しました。'

    # --- 9. 起動 ---
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $logFileName = "$stamp.jsonl"
    $errLogFileName = "$stamp.err.log"
    $logPath = Join-Path $NightLogsDir $logFileName
    $errLogPath = Join-Path $NightLogsDir $errLogFileName
    $plannedCommand = Format-PlannedCommand -Config $Config -LogFileName $logFileName -ErrLogFileName $errLogFileName

    if ($DryRun) {
        Write-Log 'INFO' ("[DryRun] 実行予定コマンド:`n" + $plannedCommand)

        Write-Log 'INFO' '[DryRun] BEANBASE_NIGHT_LOOP / BEANBASE_NIGHT_TRIGGER の子プロセスへの伝搬を実測します。'
        # 実行前の値を保存し、プローブ後に必ず復元する(ドットソース実行時に
        # 呼び出し元シェルへ値が残留し有人試走を誤って無人モード判定させる経路を防ぐ、
        # adversary指摘N2対応。BEANBASE_NIGHT_TRIGGERもT5-A60で同じパターンを踏襲する)。
        $previousNightLoopEnv = $env:BEANBASE_NIGHT_LOOP
        $previousNightTriggerEnv = $env:BEANBASE_NIGHT_TRIGGER
        try {
            $env:BEANBASE_NIGHT_LOOP = '1'
            $env:BEANBASE_NIGHT_TRIGGER = $TriggerLabel
            $probeOutput = & powershell -NoProfile -Command 'Write-Output "BEANBASE_NIGHT_LOOP=$env:BEANBASE_NIGHT_LOOP"; Write-Output "BEANBASE_NIGHT_TRIGGER=$env:BEANBASE_NIGHT_TRIGGER"'
            foreach ($l in $probeOutput) {
                if ($l) { Write-Log 'INFO' ('[DryRun probe] {0}' -f $l) }
            }
        } finally {
            if ($null -eq $previousNightLoopEnv) {
                Remove-Item Env:\BEANBASE_NIGHT_LOOP -ErrorAction SilentlyContinue
            } else {
                $env:BEANBASE_NIGHT_LOOP = $previousNightLoopEnv
            }
            if ($null -eq $previousNightTriggerEnv) {
                Remove-Item Env:\BEANBASE_NIGHT_TRIGGER -ErrorAction SilentlyContinue
            } else {
                $env:BEANBASE_NIGHT_TRIGGER = $previousNightTriggerEnv
            }
            Write-Log 'INFO' '[DryRun] BEANBASE_NIGHT_LOOP / BEANBASE_NIGHT_TRIGGER を実行前の状態に復元しました。'
        }

        if (Test-Path $RunCountPath) {
            $currentCount = Get-Content -Path $RunCountPath -Raw -ErrorAction SilentlyContinue
            Write-Log 'INFO' ('[DryRun] 現在の起動回数カウンタ: {0}' -f $currentCount.Trim())
        }
        Write-Log 'INFO' '[DryRun] claudeは起動しません。.claude/night_runs.log への追記も行いません。'
        Save-NightLoopLastRun -Outcome 'completed' -Reason 'DryRunのためclaudeは起動していません(ガードはすべて通過しました)' -ExitCode 0
        return 0
    }

    Add-Content -Path $RunsLogPath -Value (Get-Date -Format 'o') -Encoding utf8
    Write-Log 'INFO' '.claude/night_runs.log に実行記録を追記しました。'

    $runCount = 0
    if (Test-Path $RunCountPath) {
        $rawCount = Get-Content -Path $RunCountPath -Raw -ErrorAction SilentlyContinue
        if ($rawCount -and [int]::TryParse($rawCount.Trim(), [ref]$runCount)) {
            # 正常にパース
        } else {
            $runCount = 0
        }
    }
    $runCount++
    Set-Content -Path $RunCountPath -Value $runCount.ToString() -Encoding utf8
    Write-Log 'INFO' ('.claude/night_loop_run_count.txt をインクリメントしました(現在の起動回数: {0})。' -f $runCount)
    if ($runCount % 10 -eq 0) {
        Write-Log 'INFO' ('10の倍数回目({0}回目)の起動です。/code-review(medium)の実行対象となります。' -f $runCount)
    }

    $env:BEANBASE_NIGHT_LOOP = '1'
    $env:BEANBASE_NIGHT_TRIGGER = $TriggerLabel
    Write-Log 'INFO' ("claude を起動します(ログ: {0} / stderr: {1}):`n{2}" -f $logPath, $errLogPath, $plannedCommand)

    $claudeArgs = @(
        '-p', '/night_loop',
        '--model', $Config.model,
        '--settings', $Config.settingsPath,
        '--permission-mode', 'dontAsk',
        '--max-budget-usd', "$($Config.maxBudgetUsd)",
        '--output-format', 'stream-json',
        '--verbose',
        '--disallowedTools'
    ) + $DisallowedToolsList

    Push-Location $RepoRoot
    try {
        # stdout(--output-format stream-jsonの出力)だけをTee-Objectでファイル+コンソールへ
        # 流す。stderrは2>&1で成功ストリームへ混ぜず、ファイルへ直接リダイレクトする。
        # 2>&1で統合するとPowerShellがstderrの各行をNativeCommandErrorにラップし、
        # .jsonlがJSON以外の行で汚染される実機不具合を確認したため(adversary指摘M3)、
        # git pullで使ったcmd /c統合ではなく、この「ストリーム分離」方式を採用した
        # (--disallowedToolsのパターン文字列に ( ) * を含み、cmd /c経由のクォートが
        #  安全に組み立てられないと判断したため)。Out-Hostで成功出力ストリームからも
        # 切り離し、Invoke-NightLoopの戻り値(終了コード)に混ざらないようにする。
        & claude @claudeArgs 2> $errLogPath | Tee-Object -FilePath $logPath | Out-Host
        $claudeExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    # --- 10. 終了処理 ---
    # stderrが1バイトも出なかった場合、0バイトの.err.logがローテーションされずに
    # 発火のたびに溜まり続けるため削除する(Minor-1指摘対応。削除できなくても
    # スクリプトは失敗させない)。
    try {
        if ((Test-Path $errLogPath) -and ((Get-Item $errLogPath).Length -eq 0)) {
            Remove-Item -Path $errLogPath -Force -ErrorAction Stop
            Write-Log 'INFO' ('空の.err.logを削除しました: {0}' -f $errLogPath)
        }
    } catch {
        Write-Log 'WARN' ('空の.err.logの削除に失敗しました(無視して続行): {0}' -f $_.Exception.Message)
    }

    Write-Log 'INFO' ('claude の終了コード: {0}' -f $claudeExit)
    if ($claudeExit -ne 0) {
        Write-Log 'ERROR' ('claude が異常終了しました(終了コード {0})。' -f $claudeExit)
        Send-NightNotification -ResultLine ('⛔ claude が異常終了しました(終了コード {0})' -f $claudeExit) -Detail ('ログを確認してください: {0} / {1}' -f $logPath, $errLogPath)
        Save-NightLoopLastRun -Outcome 'error_claude_exit' -Reason ('claude が異常終了しました(終了コード {0})' -f $claudeExit) -ExitCode 3
        return 3
    }

    $elapsedMinutes = [math]::Round(((Get-Date) - $ScriptStart).TotalMinutes, 1)
    Write-Log 'INFO' ('night_loop.ps1 が正常に終了しました(所要時間 {0}分)。' -f $elapsedMinutes)
    Save-NightLoopLastRun -Outcome 'completed' -Reason ('正常終了しました(所要時間 {0}分)' -f $elapsedMinutes) -ExitCode 0
    return 0
}

# ============================== エントリポイント ==============================

Write-Log 'INFO' ('night_loop.ps1 起動(DryRun={0}, Force={1}, ConfigPath={2})' -f $DryRun.IsPresent, $Force.IsPresent, $ConfigPath)
Write-Log 'INFO' ('トリガー時刻を判定しました: {0}' -f $TriggerLabel)

$night_config = Get-NightLoopConfig -Path $ConfigPath

if ($null -eq $night_config) {
    # 設定ファイルがJSONとして不正(ファイル自体が無いのは正常系で既定値続行するため
    # ここには来ない)。ロックは未取得のためfinallyでの解放は不要。
    Send-NightNotification -ResultLine ('⛔ エラー終了(設定ファイルのJSONが不正: {0})' -f $ConfigPath) -Detail ('{0} の内容を確認し正しいJSONに修正してください。' -f $ConfigPath)
    Write-Log 'INFO' 'night_loop.ps1 終了(終了コード 2)。'
    Save-NightLoopLastRun -Outcome 'error_config' -Reason ('設定ファイルのJSONが不正です: {0}' -f $ConfigPath) -ExitCode 2
    exit 2
}

try {
    $exitCode = Invoke-NightLoop -Config $night_config
} catch {
    Write-Log 'ERROR' ('予期しない例外が発生しました: {0}' -f $_.Exception.Message)
    Send-NightNotification -ResultLine ('⛔ エラー終了(予期しない例外: {0})' -f $_.Exception.Message) -Detail 'wrapper.log を確認してください。'
    Save-NightLoopLastRun -Outcome 'error_exception' -Reason ('予期しない例外が発生しました: {0}' -f $_.Exception.Message) -ExitCode 2
    $exitCode = 2
} finally {
    if ($script:LockAcquired -and (Test-Path $LockPath)) {
        Remove-Item -Path $LockPath -Force -ErrorAction SilentlyContinue
        Write-Log 'INFO' 'ロックを解放しました。'
    }
}

$elapsedTotalMinutes = [math]::Round(((Get-Date) - $ScriptStart).TotalMinutes, 1)
Write-Log 'INFO' ('night_loop.ps1 終了(終了コード {0}、所要時間 {1}分)。' -f $exitCode, $elapsedTotalMinutes)
exit $exitCode
