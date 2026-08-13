<#
  check_encoding.ps1
  PostToolUse(Edit|Write)フック: 編集/作成された .ps1 ファイルのUTF-8 BOM有無を検査する。

  背景: agy(外部AIツール)による .ps1 編集でBOMが失われ、日本語コメント入りの
  スクリプトがPowerShell 5.1で構文エラーになる事故が過去2回発生した(教訓L127・L142)。
  再発防止のため、Edit/Write直後にBOM有無を記録する。

  方針:
  - 対象は .ps1 拡張子のみ。それ以外は何もせず終了。
  - BOM無しを検知しても処理は止めない(誤検知でユーザー作業を止めないため)。
    .claude/encoding_warnings.log に日時・パス・警告内容を1行追記するのみ。
  - 例外・エラーで停止させない。常に exit 0。
#>

$ErrorActionPreference = 'Stop'

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        exit 0
    }

    $payload = $raw | ConvertFrom-Json

    # tool_input.file_path (Edit/Write標準) を優先し、無ければ path を見る
    $filePath = $null
    if ($payload.tool_input) {
        if ($payload.tool_input.file_path) {
            $filePath = $payload.tool_input.file_path
        } elseif ($payload.tool_input.path) {
            $filePath = $payload.tool_input.path
        }
    }

    if (-not $filePath) {
        exit 0
    }

    if ([System.IO.Path]::GetExtension($filePath) -ne '.ps1') {
        exit 0
    }

    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
        exit 0
    }

    # 先頭3バイトを読みBOM(EF BB BF)有無を判定
    $stream = [System.IO.File]::OpenRead($filePath)
    try {
        $buf = New-Object byte[] 3
        $readCount = $stream.Read($buf, 0, 3)
    } finally {
        $stream.Close()
    }

    $hasBom = ($readCount -eq 3) -and ($buf[0] -eq 0xEF) -and ($buf[1] -eq 0xBB) -and ($buf[2] -eq 0xBF)

    if (-not $hasBom) {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $logPath = Join-Path $repoRoot '.claude\encoding_warnings.log'
        $logDir = Split-Path -Parent $logPath
        if (-not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        $line = "$timestamp`t$filePath`tUTF-8 BOMなし(日本語コメントがある場合PowerShell 5.1で構文エラーの恐れ)"
        Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    }
} catch {
    # non-blockingフックのため、何が起きても処理を止めない
}

exit 0
