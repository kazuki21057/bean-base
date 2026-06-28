# Cycle 19 実装計画 — データ基盤を Sheets に戻す（Phase 0）

最終更新: 2026-06-28

## 背景・目的
大規模改修マスタープランの **Phase 0**。Cycle 18 で Firestore に移行したが、個人利用・データ量小のため「スプレッドシートで直接確認・手動編集できる」Google Sheets 運用に戻す。既存の `SheetsService`（Cycle 17 以前で実装済み）を再活用する。

## 方針（T0-1 の決定事項）
`SheetsService` と `FirestoreService` は公開メソッドのシグネチャが完全一致していた。これを活かし、**共通の抽象インターフェース `DataService`** を新設して両サービスに `implements` させ、アプリ全体を**単一の `dataServiceProvider`** に集約する。

- メリット: バックエンド切替が `dataServiceProvider` の1行で完結。インターフェースによりメソッド・パリティが型レベルで強制される（将来 Firestore へ戻すのも容易）。DRY。
- 切替: `dataServiceProvider` は現在 `SheetsService()` を返す。

## 変更スコープ
| 対象 | 内容 |
|---|---|
| `lib/services/data_service.dart`（新規） | 抽象 `DataService` + `dataServiceProvider`（Sheets を返す） |
| `lib/services/firestore_service.dart` | `implements DataService` + `@override` 付与 |
| `lib/services/sheets_service.dart` | `implements DataService` + `@override` 付与 |
| `lib/providers/data_providers.dart` | 読み取り7プロバイダを `firestoreServiceProvider`→`dataServiceProvider` |
| 各画面 / `image_service.dart` | 書込9箇所を `dataServiceProvider` に切替 |

## 対象外（次回以降）
- `home_screen.dart` の移行ボタン（`sheetsServiceProvider`→Firestore の `FirestoreMigrator`）。Phase 0 では現状維持。
- **画像保存先の決定（T0-4）**: Drive かローカルか。ユーザー判断が必要。
- **Sheets 接続の実機確認（T0-5 後半）**: サンドボックスは外部通信不可のため、`flutter run` での GAS 接続確認はユーザーがローカルで実施。

## 検証
1. `flutter analyze` — 新規エラー/警告なし
2. `flutter test` — 全パス
3. `flutter run`（ユーザー）— Sheets 経由で一覧/登録/編集/削除が動作し接続成功
