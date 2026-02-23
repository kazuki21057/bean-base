# 実装計画: Firestore移行

## 目的
アプリのデータベースアーキテクチャをGoogle Sheets APIからFirebase Firestoreへ完全に移行します。これにより、強力なオフラインキャッシュ機能の利用、複雑なクエリの高速化、Google Sheets APIの制限（Quota）の解除が可能となり、将来的なアプリの一般公開に向けた基盤が整います。

## 確認事項 (承認済み)
> **スキーマ設計方針**
> 将来的なユーザー認証機能（複数ユーザー対応）を見据え、マルチテナント構造を採用します。各データは以下の階層で保存されます：
> - `users/{userId}/beans/{beanId}`
> - `users/{userId}/grinders/{grinderId}`
> - `users/{userId}/drippers/{dripperId}`
> - `users/{userId}/filters/{filterId}`
> - `users/{userId}/records/{recordId}`
> 
> ※現状はFirebase Authenticationを利用していないため、移行段階では一時的に固定の `userId` (例: `'default_user'`) を使用します。将来的に実際のユーザーIDへ簡単に置き換えることが可能です。

## 提案する変更内容

### フェーズ 1: 計画とスキーマ設計
- 完了（上記の確認事項に基づく設計を採用）。

### フェーズ 2: ワンタイム移行スクリプトの作成
- [NEW] `lib/utils/firestore_migrator.dart`
  - 現在の `SheetsService.dart` を経由して全データを読み込み、`FirebaseFirestore.instance.batch()` などを利用してFirestoreの各コレクションへ一括保存するユーティリティクラスを作成します。
  - `main.dart` 起動時の直接呼び出し、または一時的な隠しUIボタンから実行します。

### フェーズ 3: FirestoreService の実装
- [NEW] `lib/services/firestore_service.dart`
  - `SheetsService` を代替します。`fetchBeans()`, `addBean()`, `updateBean()`, `deleteBean()` といった全マスターおよび抽出記録(`CoffeeRecord`)のCRUD処理を実装します。
  - 後続処理（UI側）に影響を与えないよう、返り値の構造（`List<BeanMaster>`など）は完全に同一に保ちます。

### フェーズ 4: アプリ内ロジックのリファクタリング
- [MODIFY] `lib/providers/sheets_provider.dart` (または上位のプロバイダー)
  - 依存性注入の先を `SheetsService` から `FirestoreService` に変更します。
  - Google Sheetsに依存しない名称（`DataProvider` や `AppProvider` など）への変更も検討しますが、第一段階では安全のため内部のサービス参照のみを入れ替えます。

## 検証計画 (Verification Plan)
### 自動テスト
- 既存の `flutter test` を実行し、モデルの整合性が保たれていることを確認します。
- `Test` ファイル内でサービスの注入が適切に行われているか検証します。

### 手動検証
- ワンタイム移行スクリプトの実行後、Firebase Consoleを開き、スプレッドシートの全レコードがFirestoreの対象コレクションに正常に同期されているか目視確認します。
- `flutter run -d chrome` を実行し、豆、グラインダー、ドリッパー、フィルター、抽出記録の全画面で、CRUD操作（作成・読み込み・更新・削除）が新しいFirestore接続で完全動作するかテストします。Firebase Storageへの画像アップロードおよび画像表示も問題ないかも確認します。
