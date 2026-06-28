# Cycle 19 タスクリスト — Phase 0: データ基盤を Sheets に戻す

最終更新: 2026-06-28

| ID | タスク | 状態 |
|---|---|---|
| T0-1 | `SheetsService` 現状調査・再有効化方針決定（抽象 `DataService` 採用） | ✅ |
| T0-2 | `data_providers.dart` の読み取りを Firestore→Sheets に切替 | ✅ |
| T0-3 | 各CRUD書込（records/beans/grinders/drippers/filters/methods/pouringSteps）を Sheets に戻す | ✅ |
| T0-4 | 画像保存先の方針決定（Drive or ローカル） | ⬜（ユーザー判断待ち） |
| T0-5 | `analyze`/`test` で確認（✅） / `run` で Sheets 接続確認 | 🟦（run はユーザーがローカルで実施） |

## 完了メモ
- `flutter analyze`: 新規エラー/警告なし（`annotate_overrides` も解消）。残 issues は全て既存。
- `flutter test`: 17件全パス（`SheetsService` の日本語キー処理テスト含む）。
- バックエンド切替は `dataServiceProvider`（`lib/services/data_service.dart`）の1行で完結する構成に。

## 残課題
- **T0-4**: 画像保存先（Google Drive 保存 or 端末ローカル）の決定。`ImageService` は現状 Firebase Storage 前提のため要再設計。
- **T0-5(run)**: GAS エンドポイント（`kGoogleSheetsApiUrl`）が現在も有効か、ローカル `flutter run` で一覧/登録/編集/削除の疎通確認。
