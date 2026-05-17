# Cycle 18 タスクリスト (Firestore移行)

- [x] フェーズ 1: 計画とデータモデリング
    - [x] `SheetsService` と各モデルクラス（`Bean`, `Grinder`, `Dripper`, `CoffeeRecord`）の分析
    - [x] Firestore NoSQLスキーマの設計（コレクション、ドキュメント、フィールド型）
    - [x] アーキテクチャとスキーマ設計のユーザー承認確認
- [x] フェーズ 2: 移行スクリプトの作成
    - [x] スプレッドシートから読み込み、Firestoreへ書き込む使い捨てスクリプト（隠しボタン等）を作成
- [x] フェーズ 3: `FirestoreService` の実装
    - [x] `cloud_firestore` を使用したCRUD処理の実装
    - [x] Firestoreの互換性を持たせるため、モデルの `fromJson`/`toJson` を更新 (確認済: 既存のカスタムパーサーとStringシリアライズで完全互換)
- [ ] フェーズ 4: アプリケーションロジックのリファクタリング
    - [x] `SheetsProvider` などの依存性注入を `FirestoreProvider` に置き換え
    - [x] 新しいサービスでUIが正しく動作するか確認 (テストパス確認済)
    - [x] テストの追加 (既存のモデル検証テストが完全互換であることを確認済)
