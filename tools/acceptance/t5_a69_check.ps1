#requires -Version 5.1
<#
.SYNOPSIS
  受け入れスクリプト: T5-A69
.DESCRIPTION
  完了条件(docs/改修マスタープラン.md より):
  「docs/acceptance_harness_design.md記載のスクリプト規約(exit code 0/1/2/3以上、
  stdout1行JSON)どおり動作し、3ケースのフォールトインジェクションが全て期待どおりの
  判定になることを確認」

  検証する3ケース(docs/acceptance_harness_design.md §7.2 の Invoke-CheckAcceptance 仕様):
    (a) 存在しないタスクIDを -Task に渡すと reason:"acceptance_missing" でトップレベル ok:false になる
    (b) わざと exit 1 を返すダミー .ps1 を置くと ok:false になる
    (c) exit 2 のダミーは skipped 扱いで ok:true のまま

  実装方法: tools/verify.ps1 から Get-LogPath/Get-RelativePath/Invoke-LoggedCommand/
  ConvertTo-AcceptanceTaskId/Invoke-CheckAcceptance の実定義をそのまま抽出し、
  $env:TEMP 配下に作った偽の受け入れディレクトリを $RepoRoot として与えて呼び出すことで、
  実コードのロジックそのものを検証する(再実装のロジック二重化を避ける)。
  読み取り専用。本番Sheets/Drive/GASへはアクセスせず、リポジトリのファイルも書き換えない。

  仕様の正本: docs/acceptance_harness_design.md §3.3・§7.2
#>

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = "Continue"

function Write-AcceptanceLog([string]$Message) {
    [Console]::Error.WriteLine("[acceptance] $Message")
}

$taskId = "T5-A69"
$checks = New-Object System.Collections.Generic.List[object]
$originalLocation = (Get-Location).Path
$tempRoot = $null

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
    $verifyPath = Join-Path $repoRoot "tools\verify.ps1"
    if (-not (Test-Path $verifyPath)) {
        $result = [ordered]@{
            task = $taskId; ok = $false; skipped = $true
            reason = "tools/verify.ps1 が見つかりません"; checks = @()
        }
        Write-Output ($result | ConvertTo-Json -Compress -Depth 6)
        exit 2
    }

    Write-AcceptanceLog "tools/verify.ps1 から Invoke-CheckAcceptance の実定義を抽出中..."
    $allLines = Get-Content -Encoding UTF8 -Path $verifyPath
    $startMatch = ($allLines | Select-String -Pattern '^function Get-LogPath' | Select-Object -First 1)
    $endMatch = ($allLines | Select-String -Pattern '^# --- 実行' | Select-Object -First 1)
    if ((-not $startMatch) -or (-not $endMatch) -or ($endMatch.LineNumber -le $startMatch.LineNumber)) {
        $result = [ordered]@{
            task = $taskId; ok = $false; skipped = $true
            reason = "tools/verify.ps1 から関数抽出マーカーが見つかりません(スクリプト構造が変更された可能性)"
            checks = @()
        }
        Write-Output ($result | ConvertTo-Json -Compress -Depth 6)
        exit 2
    }
    $libLines = $allLines[($startMatch.LineNumber - 1)..($endMatch.LineNumber - 2)]

    $tempRoot = Join-Path $env:TEMP ("bb_t5a69_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $libPath = Join-Path $tempRoot "_verify_lib.ps1"
    ($libLines -join "`r`n") | Out-File -FilePath $libPath -Encoding utf8

    Write-AcceptanceLog "抽出した関数定義を読み込み中(dot-source)..."
    . $libPath

    function New-CaseRoot([string]$Name) {
        $p = Join-Path $tempRoot $Name
        New-Item -ItemType Directory -Force -Path (Join-Path $p "tools\acceptance") | Out-Null
        return (Resolve-Path $p).Path
    }

    function Set-AcceptanceContext([string]$CaseRoot) {
        Set-Location -Path $CaseRoot
        $script:RepoRoot = $CaseRoot
        $script:Timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
        $script:LogDir = Join-Path $CaseRoot ".claude\verify_logs"
        New-Item -ItemType Directory -Force -Path $script:LogDir | Out-Null
    }

    # --- ケースA: 存在しないタスクIDを -Task 相当で渡す ---------------------
    Write-AcceptanceLog "ケースA: 存在しないタスクIDを検証中..."
    $caseARoot = New-CaseRoot "case_a"
    Set-AcceptanceContext -CaseRoot $caseARoot
    $resultA = Invoke-CheckAcceptance -TaskId "T5-ZZZ-NOEXIST"
    $okA = ((-not $resultA.ok)) -and ($resultA.reason -eq "acceptance_missing")
    $checks.Add([ordered]@{
        name   = "存在しないタスクIDを渡すとacceptance_missingでok:falseになる"
        ok     = [bool]$okA
        detail = "ok=$($resultA.ok), reason=$($resultA.reason)"
    })

    # --- ケースB: exit 1 を返すダミー .ps1 -----------------------------------
    Write-AcceptanceLog "ケースB: exit1のダミースクリプトを検証中..."
    $caseBRoot = New-CaseRoot "case_b"
    $dummyIdB = "t5_zzz_fail"
    $dummyPathB = Join-Path $caseBRoot "tools\acceptance\${dummyIdB}_check.ps1"
    @'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$r = [ordered]@{
    task = "T5-ZZZ-FAIL"; ok = $false; skipped = $false
    reason = "意図的な失敗(フォールトインジェクション)"
    checks = @(@{ name = "ダミー失敗チェック"; ok = $false; detail = "意図的にfalseを返す" })
}
Write-Output ($r | ConvertTo-Json -Compress -Depth 6)
exit 1
'@ | Out-File -FilePath $dummyPathB -Encoding utf8
    Set-AcceptanceContext -CaseRoot $caseBRoot
    $resultB = Invoke-CheckAcceptance -TaskId ""
    $entryB = $resultB.scripts | Where-Object { $_.name -eq "${dummyIdB}_check.ps1" } | Select-Object -First 1
    $okB = ((-not $resultB.ok)) -and ($null -ne $entryB) -and (-not $entryB.ok) -and ($entryB.exit -eq 1)
    $checks.Add([ordered]@{
        name   = "exit1を返すダミースクリプトがあるとok:falseになる"
        ok     = [bool]$okB
        detail = "overall.ok=$($resultB.ok), script.exit=$($entryB.exit), script.ok=$($entryB.ok)"
    })

    # --- ケースC: exit 2 を返すダミー .ps1(判定不能=skip) --------------------
    Write-AcceptanceLog "ケースC: exit2のダミースクリプトを検証中..."
    $caseCRoot = New-CaseRoot "case_c"
    $dummyIdC = "t5_zzz_skip"
    $dummyPathC = Join-Path $caseCRoot "tools\acceptance\${dummyIdC}_check.ps1"
    @'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$r = [ordered]@{
    task = "T5-ZZZ-SKIP"; ok = $true; skipped = $true
    reason = "判定不能・前提不足(フォールトインジェクション)"
    checks = @()
}
Write-Output ($r | ConvertTo-Json -Compress -Depth 6)
exit 2
'@ | Out-File -FilePath $dummyPathC -Encoding utf8
    Set-AcceptanceContext -CaseRoot $caseCRoot
    $resultC = Invoke-CheckAcceptance -TaskId ""
    $entryC = $resultC.scripts | Where-Object { $_.name -eq "${dummyIdC}_check.ps1" } | Select-Object -First 1
    $okC = ([bool]$resultC.ok) -and ($null -ne $entryC) -and ([bool]$entryC.skipped) -and ([bool]$entryC.ok) -and ($entryC.exit -eq 2)
    $checks.Add([ordered]@{
        name   = "exit2を返すダミースクリプトはskipped扱いでok:trueのまま"
        ok     = [bool]$okC
        detail = "overall.ok=$($resultC.ok), script.exit=$($entryC.exit), script.skipped=$($entryC.skipped)"
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
    if ($tempRoot -and (Test-Path $tempRoot)) {
        Remove-Item -Recurse -Force -Path $tempRoot -ErrorAction SilentlyContinue
    }
}
