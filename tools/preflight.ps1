<#
    preflight.ps1 — ループ起動前の60秒プリフライトチェック (T5-A53)

    正本: CLAUDE.md §日次改修ループ運用ルール、docs/改修マスタープラン.md T5-A53
    夜間無人ループ(tools/night_loop.ps1)や有人ループ(full_loopスキル)の冒頭で
    軽く実行し、孤児プロセスによるログファイルロック事故(2026-08-12対応、
    commit 77d6094)やagyのPATH不在事故のような環境異常を早期検知する。
    独立した軽量スクリプトであり、BeanBaseアプリ本体のログ規約
    (debugPrint('[Antigravity] ...'))の対象外。

    確認する3項目:
      1. ファイルロック確認: night_loop.ps1 が書き込む主要ログファイルが
         排他ロックされていないか
      2. PATH上の必須バイナリ確認: git / flutter / node / claude (agyは任意)
      3. 書き込み権限確認: リポジトリルート・.claude/ への一時ファイル作成/削除

    使い方:
      powershell -File tools\preflight.ps1

    終了コード:
      0  全項目OK
      1  いずれかの項目が失敗(標準エラー出力に詳細を出す)
#>

param()

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ClaudeDir = Join-Path $RepoRoot '.claude'
$NightLogsDir = Join-Path $ClaudeDir 'night_logs'

$failures = @()

# 書き込みロックを取得できるかどうかで判定する。取得できた場合は即座に閉じて解放する。
function Test-FileNotLocked {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        # 存在しないファイルはロック判定の対象外(未作成なだけで正常)。
        return $true
    }
    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $stream.Close()
        return $true
    } catch {
        return $false
    }
}

Write-Host '=== プリフライトチェック開始 ==='

# --- 1. ファイルロック確認 ---
# wrapper.log は日次ローテーション済み(2026-08-12対応)のため、今日分のファイル名で確認する。
$todayWrapperLog = Join-Path $NightLogsDir ('wrapper-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))
$lockTargets = @(
    $todayWrapperLog,
    (Join-Path $ClaudeDir 'loop_state.md'),
    (Join-Path $ClaudeDir 'night_loop_last_run.json'),
    (Join-Path $ClaudeDir 'night_skips.log'),
    (Join-Path $ClaudeDir 'night_usage_log.tsv')
)
$lockOk = $true
foreach ($target in $lockTargets) {
    if (-not (Test-Path $target)) {
        Write-Host ('  [SKIP] ファイルロック確認: {0}(未作成のため対象外)' -f $target)
        continue
    }
    if (Test-FileNotLocked -Path $target) {
        Write-Host ('  [OK] ファイルロック確認: {0}' -f $target)
    } else {
        Write-Host ('  [NG] ファイルロック確認: {0}(排他ロックを取得できません)' -f $target)
        $lockOk = $false
        $failures += ('ファイルロック確認: {0} が排他ロックされています' -f $target)
    }
}
if ($lockOk) {
    Write-Host '[OK] 1. ファイルロック確認'
} else {
    Write-Host '[NG] 1. ファイルロック確認'
}

# --- 2. PATH上の必須バイナリ確認 ---
$requiredBinaries = @('git', 'flutter', 'node', 'claude')
$binOk = $true
foreach ($bin in $requiredBinaries) {
    $cmd = Get-Command $bin -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ('  [OK] 必須バイナリ確認: {0} -> {1}' -f $bin, $cmd.Source)
    } else {
        Write-Host ('  [NG] 必須バイナリ確認: {0} がPATH上に見つかりません' -f $bin)
        $binOk = $false
        $failures += ('必須バイナリ確認: {0} がPATH上に見つかりません' -f $bin)
    }
}
# agy(Antigravity CLI)は任意。無くても致命的エラーにはしない。
$agyCmd = Get-Command agy -ErrorAction SilentlyContinue
if ($agyCmd) {
    Write-Host ('  [OK] 任意バイナリ確認: agy -> {0}' -f $agyCmd.Source)
} else {
    Write-Host '  [INFO] 任意バイナリ確認: agy がPATH上に見つかりません(致命的エラーにはしません)'
}
if ($binOk) {
    Write-Host '[OK] 2. PATH上の必須バイナリ確認'
} else {
    Write-Host '[NG] 2. PATH上の必須バイナリ確認'
}

# --- 3. 書き込み権限確認 ---
$writeOk = $true
$writeTargets = @($RepoRoot, $ClaudeDir)
foreach ($dir in $writeTargets) {
    $probePath = Join-Path $dir ('.preflight_probe_{0}.tmp' -f $PID)
    try {
        Set-Content -Path $probePath -Value 'preflight' -Encoding utf8 -ErrorAction Stop
        Remove-Item -Path $probePath -Force -ErrorAction Stop
        Write-Host ('  [OK] 書き込み権限確認: {0}' -f $dir)
    } catch {
        Write-Host ('  [NG] 書き込み権限確認: {0}({1})' -f $dir, $_.Exception.Message)
        $writeOk = $false
        $failures += ('書き込み権限確認: {0} に書き込めません({1})' -f $dir, $_.Exception.Message)
        if (Test-Path $probePath) {
            Remove-Item -Path $probePath -Force -ErrorAction SilentlyContinue
        }
    }
}
if ($writeOk) {
    Write-Host '[OK] 3. 書き込み権限確認'
} else {
    Write-Host '[NG] 3. 書き込み権限確認'
}

$stopwatch.Stop()
$elapsedSec = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
Write-Host ('=== プリフライトチェック終了(所要時間 {0}秒) ===' -f $elapsedSec)
if ($elapsedSec -gt 60) {
    Write-Host ('[WARN] 想定の60秒を超過しました({0}秒)' -f $elapsedSec)
}

if ($failures.Count -eq 0) {
    Write-Host '[OK] 全項目OK'
    exit 0
} else {
    [Console]::Error.WriteLine('プリフライトチェックで以下の項目が失敗しました:')
    foreach ($f in $failures) {
        [Console]::Error.WriteLine('  - ' + $f)
    }
    exit 1
}
