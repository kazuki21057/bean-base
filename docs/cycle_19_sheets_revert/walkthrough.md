# Cycle 19 修正内容の確認（walkthrough）

最終更新: 2026-06-28

## 概要
データ基盤を **Firestore → Google Sheets** に差し戻した（Phase 0 / T0-1〜T0-3、および T0-5 の analyze/test）。アプリのデータアクセスを抽象インターフェース `DataService` に集約し、実体を `SheetsService` に切り替えた。

## 変更点

### 1. 抽象インターフェース新設 `lib/services/data_service.dart`
- 全CRUD（records/beans/methods/pouringSteps/grinders/drippers/filters）を宣言する `abstract class DataService`。
- `dataServiceProvider`（`Provider<DataService>`）を定義し、現在は `SheetsService()` を返す。**バックエンド切替はこの1行のみ**。

### 2. 両サービスがインターフェースを実装
- `SheetsService implements DataService`、`FirestoreService implements DataService`。
- 全オーバーライドメソッドに `@override` を付与（`annotate_overrides` lint を解消）。
- `FirestoreService` 自体は削除せず温存（将来戻せる）。

### 3. 読み取りの切替（T0-2）
- `lib/providers/data_providers.dart` の7つの `FutureProvider` を `firestoreServiceProvider` → `dataServiceProvider` に変更。

### 4. 書込/更新/削除の切替（T0-3）
以下9箇所を `ref.read(firestoreServiceProvider)` → `ref.read(dataServiceProvider)` に変更（import も `data_service.dart` へ）:
- `calculator_screen.dart`（addCoffeeRecord）
- `master_add_screen.dart`（5箇所: 各マスタ追加）
- `log_edit_screen.dart`（updateCoffeeRecord）
- `method_detail_screen.dart`（method/pouringStep 操作）
- `master_detail_screen.dart`（削除/更新）
- `image_service.dart`（画像URL更新時の updateBean/Grinder/Dripper/Filter）

## 検証結果
| 項目 | 結果 |
|---|---|
| `flutter analyze` | 新規エラー/警告なし。`annotate_overrides` 解消。残 issues は全て既存（avoid_print 等） |
| `flutter test` | **17件全パス**（`SheetsService` 日本語キー処理テスト含む） |
| `flutter run` | サンドボックスは外部通信不可。GAS 接続確認は**ユーザーがローカルで実施**（T0-5 後半） |

## 未対応（次回）
- **T0-4 画像保存先の決定**（Drive or ローカル）。`ImageService` は Firebase Storage 前提のため要再設計。
- `home_screen` の移行ボタン（Sheets→Firestore）は Phase 0 では現状維持。
