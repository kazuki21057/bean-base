# GAS Web App デプロイ手順 (T4-1c1/c2)

このディレクトリはBeanBaseのGoogle Apps Script (GAS) Web Appのソースを
リポジトリ管理するためのもの(設計書`statistics_feature_design.md`§3.4.2、
運用方針§12③④)。**初回のみユーザー作業**、以降のコード変更・反映・デプロイは
すべてClaude Codeが`clasp`経由で行う。

## 初回セットアップ (ユーザー作業)

1. `npm i -g @google/clasp` (未導入の場合)
2. `clasp login` — ブラウザでGoogleアカウントの認可を行う。OAuthフローのため
   Claude Codeは代行できない。**この工程だけはスマホ単体では完了できない**
   (Node.js/npmが動くPC、またはAndroidのTermux等が必要)。
3. 対象のGoogle Apps Scriptプロジェクト(「履歴一覧」スプレッドシートに
   紐づくスクリプト、`kGoogleSheetsApiUrl`のデプロイ元)のscriptIdを確認し、
   `gas/.clasp.json`の`"scriptId"`を実際の値に書き換える。
   - scriptIdはGASエディタのURL(`https://script.google.com/.../d/<scriptId>/edit`)
     または「プロジェクトの設定」画面で確認できる。

上記が完了すれば、以降はClaude Codeが以下を実行して反映する。

## 反映手順 (以降はClaude Codeが実行)

```bash
cd gas
clasp push                              # gas/Code.gs 等をGASプロジェクトへ反映
clasp deploy --deploymentId <既存デプロイID>   # 既存デプロイを更新(URLは変わらない)
```

- `<既存デプロイID>`は`clasp deployments`で確認できる、現在`kGoogleSheetsApiUrl`が
  指しているデプロイのID。
- URLを変えずに更新するため、Flutter側の`kGoogleSheetsApiUrl`
  (`lib/services/sheets_service.dart`)は変更不要。
- GASエディタを開いての手動デプロイ操作は不要になる。

## 構成

- `Code.gs` — 本体。既存の汎用処理(`?sheet=<name>`で任意シートを読み書き)に加え、
  `ALLOWED_SHEETS`ホワイトリスト(既存7シート+新規3シート)と、新規3シート
  (`origin_master`/`analysis_history`/`recipe_suggestions`)を初回アクセス時に
  ヘッダー行付きで自動生成する`ensureSheet_`ヘルパーを追加している。
- `appsscript.json` — マニフェスト(タイムゾーン`Asia/Tokyo`、Web App実行設定)。
- `.clasp.json` — clasp設定。`scriptId`はユーザーが記入(上記手順3)。

## 初期データ投入 (origin_master)

`clasp push`後、`origin_master`シートは自動生成されるがヘッダー行のみで
データ行は入らない。初期15件(設計書§3.1、`lib/models/origin_master.dart`の
`kInitialOriginMasters`)は`tools/seed_origin_masters.dart`を一度だけ実行して
投入する。
