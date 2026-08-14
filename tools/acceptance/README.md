# tools/acceptance/

タスク固有の**受け入れ資産**(PowerShell受け入れスクリプト)を置くディレクトリです。

規約の正本: `docs/acceptance_harness_design.md` §3.3・§7.2

- 命名: `<id>_check.ps1`(`<id>` はタスクIDを小文字化し `-` を `_` に置換したもの。例: `T5-A69` → `t5_a69`)
- `tools/verify.ps1` / `tools/verify.sh` がこのディレクトリの `*_check.ps1` を毎回全件回帰実行します(ゴールデンループ)。
- 各スクリプトは `#requires -Version 5.1`・BOM付きUTF-8・進捗メッセージは全てstderr・stdout最終行にJSON1行、を満たす必要があります(詳細は設計書§3.3)。
