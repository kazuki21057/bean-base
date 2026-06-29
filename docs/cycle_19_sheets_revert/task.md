# Cycle 19 タスクリスト — Phase 0: データ基盤を Sheets に戻す

最終更新: 2026-06-28

| ID | タスク | 状態 |
|---|---|---|
| T0-1 | `SheetsService` 現状調査・再有効化方針決定（抽象 `DataService` 採用） | ✅ |
| T0-2 | `data_providers.dart` の読み取りを Firestore→Sheets に切替 | ✅ |
| T0-3 | 各CRUD書込（records/beans/grinders/drippers/filters/methods/pouringSteps）を Sheets に戻す | ✅ |
| T0-4 | 画像保存先の方針決定（**Google Drive 保存**に決定） | ✅ |
| T0-4b | Drive 画像保存の実装（GAS拡張方式・別タスク） | ✅ |
| T0-5 | `analyze`/`test` で確認（✅） / `run` で Sheets 接続確認 | 🟦（run はユーザーがローカルで実施） |

## T0-4 決定: Google Drive 保存（実装方針メモ）
画像実体は Google Drive に保存し、Sheets には公開URLを記録する。

**推奨実装アプローチ（GAS拡張方式）:**
- クライアントから直接 Drive API を叩くと OAuth2 認証が重い。代わりに **既存の GAS Web App（`kGoogleSheetsApiUrl`）を拡張**する。
- GAS はユーザー権限で実行されるため Drive へ追加認証なしでアクセス可能 → Sheets 基盤と認証を共通化できる。
- フロー: `ImageService.uploadImage()` が画像を base64 で GAS に POST → GAS が指定 Drive フォルダに保存し、共有可能URL（`https://drive.google.com/uc?id=...` 等）を返す → そのURLを Sheets に保存。
- `ImageService` の Firebase Storage 依存を Drive アップロードに差し替え。Web/モバイル両対応（bytes/path）。
- 留意: Drive 画像の公開URLは直リンク表示形式に注意（`uc?export=view&id=` 形式）。GAS 側でファイルの共有設定を「リンクを知っている全員が閲覧可」にする必要あり。

## 完了メモ
- `flutter analyze`: 新規エラー/警告なし（`annotate_overrides` も解消）。残 issues は全て既存。
- `flutter test`: 17件全パス（`SheetsService` の日本語キー処理テスト含む）。
- バックエンド切替は `dataServiceProvider`（`lib/services/data_service.dart`）の1行で完結する構成に。

## 残課題
- **T0-4**: 画像保存先（Google Drive 保存 or 端末ローカル）の決定。`ImageService` は現状 Firebase Storage 前提のため要再設計。
- **T0-5(run)**: GAS エンドポイント（`kGoogleSheetsApiUrl`）が現在も有効か、ローカル `flutter run` で一覧/登録/編集/削除の疎通確認。
