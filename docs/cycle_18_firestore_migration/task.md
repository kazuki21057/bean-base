# Cycle 18 タスクリスト (Firestore移行)

- [x] フェーズ 1: 計画とデータモデリング
    - [x] `SheetsService` と各モデルクラス（`Bean`, `Grinder`, `Dripper`, `CoffeeRecord`）の分析
    - [x] Firestore NoSQLスキーマの設計（コレクション、ドキュメント、フィールド型）
    - [x] アーキテクチャとスキーマ設計のユーザー承認確認
- [ ] フェーズ 2: 移行スクリプトの作成
    - [ ] スプレッドシートから読み込み、Firestoreへ書き込む使い捨てスクリプト（隠しボタン等）を作成
- [ ] フェーズ 3: `FirestoreService` の実装
    - [ ] `cloud_firestore` を使用したCRUD処理の実装
    - [ ] Firestoreの互換性を持たせるため、モデルの `fromJson`/`toJson` を更新
- [ ] フェーズ 4: アプリケーションロジックのリファクタリング
    - [ ] `SheetsProvider` などの依存性注入を `FirestoreProvider` に置き換え
    - [ ] 新しいサービスでUIが正しく動作するか確認
    - [ ] テストの追加
