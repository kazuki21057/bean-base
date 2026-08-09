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
      powershell -File tools\night_loop.ps1 -Force         5時間枠チェックと週次予算ガードを
                                                             スキップする(有人監視下試走用、
                                                             多重起動ガード・slug解決・
                                                             settings.night.json存在チェック・
                                                             git pullはスキップしない)
      powershell -File tools\night_loop.ps1 -ConfigPath X  既定は tools\night_loop.config.json

    tools/night_loop.config.json のキー(JSONにコメントを書けないためここに説明を置く):
      weeklyRunLimit     週次予算ガードの上限回数(既定12)。直近7日の .claude/night_runs.log
                         の行数がこれ以上ならスキップする。
      sessionWindowHours 5時間枠チェックの窓の長さ(既定5)。プロジェクトのtranscript
                         (*.jsonl)の最新更新時刻からこの時間未満ならスキップする。
      staleLockHours     多重起動ガードのロックファイルをstale(放棄済み)とみなす経過時間
                         (既定3)。PIDが実在してもこの時間を超えていれば奪取する。
      model              claude起動時の --model(既定 "sonnet")。
      maxBudgetUsd       claude起動時の --max-budget-usd(既定8、設計書§5の夜間コスト上限
                         $8に対応)。旧 maxTurns キーは廃止(--max-turnsはclaude CLIに
                         実在しないオプションのため2026-08-08に置き換えた)。
      settingsPath       claude起動時の --settings に渡すパス
                         (既定 ".claude\settings.night.json")。
      projectSlug        ~/.claude/projects/ 配下のプロジェクトslugを明示指定したい場合に
                         設定する(既定 null = 自動解決)。指定時は存在確認し、無ければ
                         エラー終了する。

    終了コード:
      0  正常終了 / 正常スキップ(多重起動中・5時間枠内・週次上限到達)
      2  エラー終了(設定ファイルJSON不正・claude未検出・slug解決失敗・
         settings.night.json不在/JSON不正・git pull失敗)
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
$WrapperLogPath = Join-Path $NightLogsDir 'wrapper.log'
$LockPath = Join-Path $ClaudeDir 'night_loop.lock'
$RunsLogPath = Join-Path $ClaudeDir 'night_runs.log'
$NightReportPath = Join-Path $ClaudeDir 'night_report.md'
$ProjectsRoot = Join-Path $HOME '.claude\projects'

$ScriptStart = Get-Date
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
    try {
        Add-Content -Path $WrapperLogPath -Value $line -Encoding utf8
    } catch {
        Write-Host ('[{0}] [WARN] wrapper.log への書き込みに失敗しました: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $_.Exception.Message)
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
        Write-Log 'INFO' '.claude/night_report.md を更新しました。'
    } catch {
        Write-Log 'WARN' ('night_report.md の更新に失敗しました: {0}' -f $_.Exception.Message)
    }
    Send-ToastNotification -Title 'BeanBase 夜間ループ' -Text $ResultLine
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
        weeklyRunLimit     = 12
        sessionWindowHours = 5
        staleLockHours     = 3
        model              = 'sonnet'
        maxBudgetUsd       = 8
        settingsPath       = '.claude\settings.night.json'
        projectSlug        = $null
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

    foreach ($key in @('weeklyRunLimit', 'sessionWindowHours', 'staleLockHours', 'model', 'maxBudgetUsd', 'settingsPath', 'projectSlug')) {
        if ($json.PSObject.Properties.Name -contains $key -and $null -ne $json.$key) {
            $config[$key] = $json.$key
        }
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

    # --- 3. claude CLI の解決 ---
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claudeCmd) {
        Write-Log 'ERROR' 'claude コマンドが見つかりません(PATHを確認してください)。'
        Send-NightNotification -ResultLine '⛔ エラー終了(claude コマンドが見つからない)' -Detail 'claude CLIがPATH上にあるか確認してください。'
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
                return 2
            }
        }
    }
    $TranscriptDir = Join-Path $ProjectsRoot $slug

    # --- 5. 5時間枠チェック ---
    if ($Force) {
        Write-Log 'INFO' '-Force指定のため5時間枠チェックをスキップします。'
    } else {
        $jsonlFiles = @(Get-ChildItem -Path $TranscriptDir -Filter '*.jsonl' -ErrorAction SilentlyContinue)
        if ($jsonlFiles.Count -gt 0) {
            $last = ($jsonlFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
            $elapsedHours = ((Get-Date) - $last).TotalHours
            if ($elapsedHours -lt [double]$Config.sessionWindowHours) {
                Write-Log 'INFO' ('直近{0}時間以内にセッション活動があるため({1}、経過{2}時間)、今回の発火をスキップします。' -f $Config.sessionWindowHours, $last, [math]::Round($elapsedHours, 2))
                return 0
            }
            Write-Log 'INFO' ('直近のセッション活動: {0}(経過{1}時間)。5時間枠チェックを通過しました。' -f $last, [math]::Round($elapsedHours, 2))
        } else {
            Write-Log 'INFO' 'transcriptファイルが1件も見つからないため、5時間枠チェックを通過とみなします。'
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
                Write-Log 'INFO' '.claude/night_report.md を更新しました。'
            } catch {
                Write-Log 'WARN' ('night_report.md の更新に失敗しました: {0}' -f $_.Exception.Message)
            }
            Send-ToastNotification -Title 'BeanBase 夜間ループ' -Text $toastText
            return 2
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

        Write-Log 'INFO' '[DryRun] BEANBASE_NIGHT_LOOP の子プロセスへの伝搬を実測します。'
        # 実行前の値を保存し、プローブ後に必ず復元する(ドットソース実行時に
        # 呼び出し元シェルへ1が残留し有人試走を誤って無人モード判定させる経路を防ぐ、
        # adversary指摘N2対応)。
        $previousNightLoopEnv = $env:BEANBASE_NIGHT_LOOP
        try {
            $env:BEANBASE_NIGHT_LOOP = '1'
            $probeOutput = & powershell -NoProfile -Command 'Write-Output "BEANBASE_NIGHT_LOOP=$env:BEANBASE_NIGHT_LOOP"'
            foreach ($l in $probeOutput) {
                if ($l) { Write-Log 'INFO' ('[DryRun probe] {0}' -f $l) }
            }
        } finally {
            if ($null -eq $previousNightLoopEnv) {
                Remove-Item Env:\BEANBASE_NIGHT_LOOP -ErrorAction SilentlyContinue
            } else {
                $env:BEANBASE_NIGHT_LOOP = $previousNightLoopEnv
            }
            Write-Log 'INFO' '[DryRun] BEANBASE_NIGHT_LOOP を実行前の状態に復元しました。'
        }

        Write-Log 'INFO' '[DryRun] claudeは起動しません。.claude/night_runs.log への追記も行いません。'
        return 0
    }

    Add-Content -Path $RunsLogPath -Value (Get-Date -Format 'o') -Encoding utf8
    Write-Log 'INFO' '.claude/night_runs.log に実行記録を追記しました。'

    $env:BEANBASE_NIGHT_LOOP = '1'
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
        return 3
    }

    $elapsedMinutes = [math]::Round(((Get-Date) - $ScriptStart).TotalMinutes, 1)
    Write-Log 'INFO' ('night_loop.ps1 が正常に終了しました(所要時間 {0}分)。' -f $elapsedMinutes)
    return 0
}

# ============================== エントリポイント ==============================

Write-Log 'INFO' ('night_loop.ps1 起動(DryRun={0}, Force={1}, ConfigPath={2})' -f $DryRun.IsPresent, $Force.IsPresent, $ConfigPath)

$night_config = Get-NightLoopConfig -Path $ConfigPath

if ($null -eq $night_config) {
    # 設定ファイルがJSONとして不正(ファイル自体が無いのは正常系で既定値続行するため
    # ここには来ない)。ロックは未取得のためfinallyでの解放は不要。
    Send-NightNotification -ResultLine ('⛔ エラー終了(設定ファイルのJSONが不正: {0})' -f $ConfigPath) -Detail ('{0} の内容を確認し正しいJSONに修正してください。' -f $ConfigPath)
    Write-Log 'INFO' 'night_loop.ps1 終了(終了コード 2)。'
    exit 2
}

try {
    $exitCode = Invoke-NightLoop -Config $night_config
} catch {
    Write-Log 'ERROR' ('予期しない例外が発生しました: {0}' -f $_.Exception.Message)
    Send-NightNotification -ResultLine ('⛔ エラー終了(予期しない例外: {0})' -f $_.Exception.Message) -Detail 'wrapper.log を確認してください。'
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
