# 次回開発再開時の手順書 (Next Session Handover)

現在は **サイクル18 (Firestore移行)** のフェーズ1（計画およびスキーマ設計のマルチテナント化対応）が完了し、フェーズ2へ移行する直前の状態です。
また、`Gemini.md` のルール（ドキュメント保存先の変更と日本語翻訳）への完全適応を完了したため、今後は本ルールに沿って運用されます。

## 1. 現状のステータス
- **完了**:
    - `docs/` 配下の古いファイル群の `docs/archive/` へのアーカイブ化。
    - Firestore移行のスキーマ設計（`users/{userId}/...` マルチテナント階層）。
    - 実装計画（`docs/cycle_18_firestore_migration/implementation_plan.md`）およびタスクリストの英→日翻訳および所定のディレクトリへの保存。
- **保留中 (次回着手)**:
    - フェーズ 2: Google Sheets から Firestore ヘのワンタイムデータ移行スクリプト作成。

## 2. 次回、ユーザー (あなた) がやること

### A. 環境復帰
1. VS Code で `Antigravity/bean-base` を開く。
2. ターミナルを開く。

### B. Firebase プロジェクトの確認
次回からFirestoreのデータベースを使用するための実装に入ります。Firebase Console上でFirestore Databaseの作成（プロビジョニング）と、ローカルからの接続を許可するための仮のセキュリティルール（`allow read, write: if true;`）が設定されているか確認してください。

## 3. 次回、Antigravity (私) がやること

### サイクル 18: Firestoreへのデータ移行（フェーズ2）
次回チャット開始時に、以下のタスクを指示してください。

1. **ワンタイム移行スクリプトの実装**:
    - `lib/utils/firestore_migrator.dart` 等を作成。
    - 現在の `SheetsService` を経由して読み込んだ全データ（豆、グラインダー等）を、`FirebaseFirestore.instance.batch()` を用いてFirestoreに書き込む一時的なロジックを構築します。
2. **移行用の一時的なUI追加（隠しボタン等）**:
    - デバッグ画面等に「Firestoreへ移行」ボタンを設置し、ユーザーが手動で一度だけ実行できるようにします。

## 4. 開発再開時のプロンプト例
次回、Antigravity を起動した際に以下のように話しかけてください：

> 「前回はCycle 18のスキーマ設計まで完了しました。\start コマンドを実行し、NEXT_SESSION.md を確認して、フェーズ2のワンタイム移行スクリプトの作成に進んでください。」

それでは、また次回！お疲れ様でした。
