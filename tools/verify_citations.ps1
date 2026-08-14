#requires -Version 5.1
<#
.SYNOPSIS
  調査レポート(Markdown)末尾の「## 出典一覧」表を機械的に検証するツール。
  各行のURLを実際に取得し、(1)URLが実在し2xxで到達できるか、(2)申告された
  「裏付け引用」がそのページ本文に実在するか、を判定する。researcher役(agy/Claude)が
  実在しないURLを書く・裏付けない主張を帰属させる、の2種の失敗を機械的に検知する目的。

  仕様の正本: T5-A79 実装仕様(親が確定)。

  標準出力(stdout)は -Json 指定時は1行JSONのみ(Write-Output)。進捗・警告は
  すべて [Console]::Error(stderr) へ出す(tools/antigravity_delegate.ps1と同じ流儀)。

  使い方:
    powershell -File tools/verify_citations.ps1 -ReportPath <path> [-TimeoutSec 30] `
      [-MaxUrls 20] [-Json]
#>

param(
    [string]$ReportPath = "",
    [int]$TimeoutSec = 30,
    [int]$MaxUrls = 20,
    [switch]$Json
)

# 標準出力にJSON以外の文字が混じらないよう、進捗メッセージは全てstderrへ出す。
# 日本語を含む出力の文字化けを防ぐため、コンソールの出力エンコーディングをUTF-8に固定する
# (tools/antigravity_delegate.ps1と同じ対処)。
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = "Continue"

function Write-Progress2([string]$Message) {
    [Console]::Error.WriteLine("[verify_citations.ps1] $Message")
}

# --- 出力(すべての終了パスがこの1つの関数を通る) --------------------------------------
function Write-ResultAndExit {
    param(
        [bool]$Ok,
        [int]$ExitCode,
        [string]$Status,
        [string]$ReportRel = $null,
        [int]$Checked = 0,
        [int]$Passed = 0,
        [int]$Failed = 0,
        [int]$Unverifiable = 0,
        [int]$Skipped = 0,
        [array]$Rows = @(),
        [string[]]$UnlistedUrls = @(),
        [string[]]$OverusedUrls = @(),
        [string]$ErrorMessage = $null
    )

    $obj = [ordered]@{
        ok            = $Ok
        report        = $ReportRel
        checked       = $Checked
        passed        = $Passed
        failed        = $Failed
        unverifiable  = $Unverifiable
        skipped       = $Skipped
        rows          = @($Rows)
        unlisted_urls = @($UnlistedUrls)
        overused_urls = @($OverusedUrls)
        exit_code     = $ExitCode
        status        = $Status
    }
    if ($ErrorMessage) { $obj["error"] = $ErrorMessage }

    if ($Json) {
        ($obj | ConvertTo-Json -Compress -Depth 10) | Write-Output
    } else {
        Write-Output "出典検証結果: $Status (report=$ReportRel checked=$Checked passed=$Passed failed=$Failed unverifiable=$Unverifiable skipped=$Skipped)"
        if (@($Rows).Count -gt 0) {
            Write-Output ""
            Write-Output "#`t主張ID`tURL(60字)`t実測`t引用照合`t備考"
            foreach ($r in $Rows) {
                $urlShort = $r.url
                if ($urlShort -and $urlShort.Length -gt 60) { $urlShort = $urlShort.Substring(0, 60) }
                $note = ""
                if ($r.error) { $note = $r.error }
                elseif ($r.status_mismatch) { $note = "申告ステータスと不一致(申告=$($r.declared_status))" }
                Write-Output "$($r.n)`t$($r.claim_id)`t$urlShort`t$($r.http_status)`t$($r.quote_ok)`t$note"
            }
        }
        if (@($UnlistedUrls).Count -gt 0) {
            Write-Output ""
            Write-Output "警告: 出典一覧に無いURLが本文中にあります:"
            foreach ($u in $UnlistedUrls) { Write-Output "  - $u" }
        }
        if (@($OverusedUrls).Count -gt 0) {
            Write-Output ""
            Write-Output "警告: 同一URLが3行以上で使われています:"
            foreach ($u in $OverusedUrls) { Write-Output "  - $u" }
        }
        if ($ErrorMessage) {
            Write-Output ""
            Write-Output "エラー: $ErrorMessage"
        }
    }
    exit $ExitCode
}

# --- 引数バリデーション(exit 2) -------------------------------------------------------
if (-not $ReportPath) {
    Write-ResultAndExit -Ok $false -ExitCode 2 -Status "ARG_ERROR" `
        -ErrorMessage "-ReportPath は必須です"
}

$RepoRootRaw = (& git rev-parse --show-toplevel 2>$null)
$RepoRoot = $null
if ($RepoRootRaw) { $RepoRoot = $RepoRootRaw.Trim() }

$ReportResolved = $null
$candidates = @($ReportPath)
if ($RepoRoot) { $candidates += (Join-Path $RepoRoot $ReportPath) }
foreach ($candidate in $candidates) {
    if (Test-Path $candidate) { $ReportResolved = (Resolve-Path $candidate).Path; break }
}
if (-not $ReportResolved) {
    Write-ResultAndExit -Ok $false -ExitCode 2 -Status "ARG_ERROR" `
        -ErrorMessage "-ReportPath が見つかりません: $ReportPath"
}

function Get-RelativePath([string]$FullPath) {
    if (-not $RepoRoot) { return $FullPath }
    $rel = $FullPath
    if ($rel.StartsWith($RepoRoot)) { $rel = $rel.Substring($RepoRoot.Length) }
    $rel = $rel.TrimStart('\', '/')
    return $rel.Replace('\', '/')
}
$ReportRel = Get-RelativePath $ReportResolved

Write-Progress2 "report=$ReportRel timeout_sec=$TimeoutSec max_urls=$MaxUrls"

$ReportText = Get-Content -Raw -Encoding UTF8 -Path $ReportResolved

# --- 出典一覧テーブルの検出 ------------------------------------------------------------
# 「## 出典一覧」見出し以降にある最初のMarkdownテーブルを対象とする。見出し行の列名で
# 列位置を特定する(列順が違っても動くようにする)。
$SectionMatch = [regex]::Match($ReportText, '(?ms)^##\s*出典一覧\s*$(.*)$')
if (-not $SectionMatch.Success) {
    Write-ResultAndExit -Ok $false -ExitCode 3 -Status "NO_CITATION_TABLE" -ReportRel $ReportRel `
        -ErrorMessage "「## 出典一覧」見出しが見つかりません"
}
$SectionText = $SectionMatch.Groups[1].Value

$TableLines = New-Object System.Collections.Generic.List[string]
foreach ($line in ($SectionText -split "`r?`n")) {
    $trimmed = $line.Trim()
    if ($trimmed.StartsWith('|')) {
        $TableLines.Add($trimmed)
    } elseif ($TableLines.Count -gt 0) {
        # テーブル開始後、テーブル以外の行が来たら終了。
        break
    }
}

if ($TableLines.Count -lt 2) {
    Write-ResultAndExit -Ok $false -ExitCode 3 -Status "NO_CITATION_TABLE" -ReportRel $ReportRel `
        -ErrorMessage "出典一覧の表(見出し行+区切り行)が見つかりません"
}

function Split-TableRow([string]$Line) {
    $body = $Line.Trim()
    if ($body.StartsWith('|')) { $body = $body.Substring(1) }
    if ($body.EndsWith('|')) { $body = $body.Substring(0, $body.Length - 1) }
    return @($body -split '\|' | ForEach-Object { $_.Trim() })
}

$HeaderCols = Split-TableRow $TableLines[0]

function Find-ColumnIndex([string[]]$Headers, [string[]]$Keywords) {
    for ($i = 0; $i -lt $Headers.Count; $i++) {
        foreach ($kw in $Keywords) {
            if ($Headers[$i] -like "*$kw*") { return $i }
        }
    }
    return -1
}

$IdxN = Find-ColumnIndex $HeaderCols @('#')
$IdxClaim = Find-ColumnIndex $HeaderCols @('主張ID', '主張')
$IdxUrl = Find-ColumnIndex $HeaderCols @('URL')
$IdxStatus = Find-ColumnIndex $HeaderCols @('HTTPステータス', 'ステータス')
$IdxDate = Find-ColumnIndex $HeaderCols @('取得日')
$IdxQuote = Find-ColumnIndex $HeaderCols @('裏付け引用', '引用')

if ($IdxUrl -lt 0) {
    Write-ResultAndExit -Ok $false -ExitCode 3 -Status "NO_CITATION_TABLE" -ReportRel $ReportRel `
        -ErrorMessage "出典一覧の表に「URL」列が見つかりません"
}

# 2行目は区切り行(---)、3行目以降がデータ行。区切り行判定は「---」等のみで構成される行。
$DataRows = New-Object System.Collections.Generic.List[string[]]
for ($i = 1; $i -lt $TableLines.Count; $i++) {
    $cols = Split-TableRow $TableLines[$i]
    $isSeparator = $true
    foreach ($c in $cols) {
        if ($c -notmatch '^:?-+:?$') { $isSeparator = $false; break }
    }
    if ($isSeparator) { continue }
    $DataRows.Add($cols)
}

if ($DataRows.Count -eq 0) {
    Write-ResultAndExit -Ok $false -ExitCode 3 -Status "NO_CITATIONS" -ReportRel $ReportRel `
        -ErrorMessage "出典一覧の表に行が0件です"
}

function Get-Col([string[]]$Cols, [int]$Idx) {
    if ($Idx -lt 0 -or $Idx -ge $Cols.Count) { return "" }
    return $Cols[$Idx]
}

# --- 引用照合用の正規化 ---------------------------------------------------------------
function Get-NormalizedSymbols([string]$Text) {
    # 空白文字(半角/全角スペース・タブ・改行)を全て除去し、引用符・三点リーダーを除去。
    # 大小文字はToLowerInvariant()で無視する。
    $t = [regex]::Replace($Text, '[\s　]+', '')
    $t = $t -replace '[「」『』""'']', ''
    $t = $t -replace '…', ''
    $t = $t.ToLowerInvariant()
    return $t
}

function Get-NormalizedText([string]$Text) {
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $t = [System.Net.WebUtility]::HtmlDecode($Text)
    return Get-NormalizedSymbols $t
}

# 判断: 引用文(Get-NormalizedQuote)にだけ、HtmlDecode後もタグ状の文字列
# ("<strong>"・"<br>"等)が残るケースへの追加処理を行う。実測で、
# (a) 複数行の原文をMarkdown表の1セルに収めるため"<br>"でつないで書かれる、
# (b) 引用文が"&lt;strong&gt;...&lt;/strong&gt;"のようにタグをエンティティの
#     ままコピーして書かれる、の2パターンが確認された。いずれもページ側では
#     実タグとして除去される箇所なので、引用側も同じ規則でタグ状の文字列を
#     除去する。この処理はページ本文(Get-NormalizedText)には適用しない
#     ——ページ本文はコード例に含まれるジェネリクス表記(例:
#     "&lt;Breakpoint, T&gt;")等がHtmlDecode後に"<...>"へ戻ってしまい、
#     本来のタグではないのに誤って本文ごと除去される事故が実測で発生した
#     ため、ページ側は元のGet-PageText(タグ除去は実タグのみに限定)の
#     結果をそのまま正規化する。
function Get-NormalizedQuote([string]$Text) {
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $t = [System.Net.WebUtility]::HtmlDecode($Text)
    $t = [regex]::Replace($t, '(?s)<[^>]+>', ' ')
    return Get-NormalizedSymbols $t
}

function Get-PageText([string]$Html) {
    if ([string]::IsNullOrEmpty($Html)) { return "" }
    $t = $Html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?s)<[^>]+>', ' ')
    return $t
}

# 判断: <meta name="description">/<meta property="og:description">等の説明文は、
# タグ本文とは別に取得する。理由: 実測でHTML本文(<p>タグ内)がmeta説明文の
# 語順を変えた言い換えである一方、researcherの引用はmeta説明文の方と一字一句
# 一致するケースがあった(引用そのものは正しくページに実在する情報の裏付けに
# なっているため、これをfailにするのは過検知)。ただし本文抽出可否(200文字
# 未満=SPA判定)の基準にはmeta説明文を含めない(SPAページのmeta説明文だけで
# 200文字を超え、本来unverifiableとすべき行が誤ってpass/fail判定されるのを
# 防ぐため)。
function Get-MetaDescriptionText([string]$Html) {
    if ([string]::IsNullOrEmpty($Html)) { return "" }
    $metaTexts = New-Object System.Collections.Generic.List[string]
    $metaMatches = [regex]::Matches($Html, '(?is)<meta\b[^>]*>')
    foreach ($mm in $metaMatches) {
        $tag = $mm.Value
        if ($tag -notmatch '(?is)(?:name|property)\s*=\s*["'']?(?:description|og:description|twitter:description)["'']?') { continue }
        $cm = [regex]::Match($tag, '(?is)content\s*=\s*"([^"]*)"')
        if (-not $cm.Success) { $cm = [regex]::Match($tag, "(?is)content\s*=\s*'([^']*)'") }
        if ($cm.Success -and $cm.Groups[1].Value) { $metaTexts.Add($cm.Groups[1].Value) }
    }
    return ($metaTexts -join ' ')
}

# --- 各行の検証 -------------------------------------------------------------------
$Rows = New-Object System.Collections.Generic.List[object]
$Checked = 0
$Passed = 0
$Failed = 0
$Unverifiable = 0
$Skipped = 0

$RowIndex = 0
foreach ($cols in $DataRows) {
    $RowIndex++
    $nRaw = Get-Col $cols $IdxN
    $n = $RowIndex
    if ($nRaw -and ($nRaw -as [int])) { $n = [int]$nRaw }
    $claimId = Get-Col $cols $IdxClaim
    $url = Get-Col $cols $IdxUrl
    $declaredStatus = Get-Col $cols $IdxStatus
    $quote = Get-Col $cols $IdxQuote

    if ($Checked -ge $MaxUrls) {
        $Skipped++
        $Rows.Add([ordered]@{
            n               = $n
            claim_id        = $claimId
            url             = $url
            declared_status = $declaredStatus
            http_status     = $null
            url_ok          = $null
            quote_ok        = $null
            status_mismatch = $false
            reason          = "skipped_max_urls"
            error           = $null
        })
        continue
    }

    $Checked++
    Write-Progress2 "[$n] 取得中: $url"

    $httpStatus = $null
    $urlOk = $false
    $errMsg = $null
    $body = $null

    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $TimeoutSec -MaximumRedirection 5
        $httpStatus = [int]$resp.StatusCode
        $body = $resp.Content
        if ($httpStatus -ge 200 -and $httpStatus -lt 300) { $urlOk = $true }
    } catch {
        $exResp = $null
        try { $exResp = $_.Exception.Response } catch {}
        if ($exResp) {
            try { $httpStatus = [int]$exResp.StatusCode } catch {}
        }
        $msg = $_.Exception.Message
        if ($msg.Length -gt 200) { $msg = $msg.Substring(0, 200) }
        $errMsg = $msg
        $urlOk = $false
    }

    $statusMismatch = $false
    if ($declaredStatus -and $httpStatus -and ("$declaredStatus" -ne "$httpStatus")) {
        $statusMismatch = $true
    }

    $quoteOk = $false
    $reason = $null

    if (-not $urlOk) {
        $reason = "url_unreachable"
    } elseif ([string]::IsNullOrWhiteSpace($quote)) {
        $reason = "quote_missing"
    } else {
        $pageText = Get-PageText $body
        $normalizedPage = Get-NormalizedText $pageText
        $normalizedQuote = Get-NormalizedQuote $quote
        if ($normalizedPage.Length -lt 200) {
            # SPA判定はタグ除去後の本文のみで行う(meta説明文で嵩増しさせない)。
            $reason = "page_not_text_extractable"
        } else {
            $normalizedMeta = Get-NormalizedText (Get-MetaDescriptionText $body)
            if ($normalizedQuote -and $normalizedPage.Contains($normalizedQuote)) {
                $quoteOk = $true
            } elseif ($normalizedQuote -and $normalizedMeta -and $normalizedMeta.Contains($normalizedQuote)) {
                $quoteOk = $true
            } else {
                $reason = "quote_not_found"
            }
        }
    }

    # 行の3値判定: pass / fail / unverifiable。
    if ($reason -eq "page_not_text_extractable") {
        $Unverifiable++
        $rowStatus = "unverifiable"
    } elseif ($urlOk -and $quoteOk) {
        $Passed++
        $rowStatus = "pass"
    } else {
        $Failed++
        $rowStatus = "fail"
    }

    Write-Progress2 "[$n] $rowStatus (url_ok=$urlOk quote_ok=$quoteOk reason=$reason)"

    $quoteOkForRow = $quoteOk
    if ($reason -eq "page_not_text_extractable") { $quoteOkForRow = $null }

    $Rows.Add([ordered]@{
        n               = $n
        claim_id        = $claimId
        url             = $url
        declared_status = $declaredStatus
        http_status     = $httpStatus
        url_ok          = $urlOk
        quote_ok        = $quoteOkForRow
        status_mismatch = $statusMismatch
        reason          = $reason
        row_status      = $rowStatus
        error           = $errMsg
    })
}

# --- 追加チェック(表の外) --------------------------------------------------------------
# 本文中(表より前)に現れるURLのうち、出典一覧に1つも現れないものを収集する。
$BodyBeforeTable = $ReportText.Substring(0, $SectionMatch.Index)
$AllTableUrls = New-Object System.Collections.Generic.HashSet[string]
foreach ($cols in $DataRows) {
    $u = Get-Col $cols $IdxUrl
    if ($u) { [void]$AllTableUrls.Add($u) }
}

$BodyUrlMatches = [regex]::Matches($BodyBeforeTable, 'https?://[^\s\)\]"''<>]+')
$UnlistedUrls = New-Object System.Collections.Generic.List[string]
$SeenUnlisted = New-Object System.Collections.Generic.HashSet[string]
foreach ($m in $BodyUrlMatches) {
    $u = $m.Value.TrimEnd('.', ',', ')', ']')
    if (-not $AllTableUrls.Contains($u) -and -not $SeenUnlisted.Contains($u)) {
        [void]$SeenUnlisted.Add($u)
        $UnlistedUrls.Add($u)
    }
}

# 同一URLが3行以上で使われている場合の警告。
$UrlCounts = @{}
foreach ($cols in $DataRows) {
    $u = Get-Col $cols $IdxUrl
    if (-not $u) { continue }
    if ($UrlCounts.ContainsKey($u)) { $UrlCounts[$u]++ } else { $UrlCounts[$u] = 1 }
}
$OverusedUrls = New-Object System.Collections.Generic.List[string]
foreach ($key in $UrlCounts.Keys) {
    if ($UrlCounts[$key] -ge 3) { $OverusedUrls.Add($key) }
}

# --- 終了コード判定 ---------------------------------------------------------------------
if ($Failed -gt 0) {
    Write-ResultAndExit -Ok $false -ExitCode 1 -Status "CITATION_FAILED" -ReportRel $ReportRel `
        -Checked $Checked -Passed $Passed -Failed $Failed -Unverifiable $Unverifiable -Skipped $Skipped `
        -Rows $Rows -UnlistedUrls $UnlistedUrls -OverusedUrls $OverusedUrls
} else {
    Write-ResultAndExit -Ok $true -ExitCode 0 -Status "OK" -ReportRel $ReportRel `
        -Checked $Checked -Passed $Passed -Failed $Failed -Unverifiable $Unverifiable -Skipped $Skipped `
        -Rows $Rows -UnlistedUrls $UnlistedUrls -OverusedUrls $OverusedUrls
}
