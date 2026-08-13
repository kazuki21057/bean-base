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
