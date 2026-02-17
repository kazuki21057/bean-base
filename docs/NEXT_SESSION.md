# 次回開発再開時の手順書 (Next Session Handover)

PCのシャットダウン後、次回開発をスムーズに再開するためのメモです。
現在は **サイクル16 (Firebase統合 & UI調整)** が完了し、**サイクル17** に移行する直前の状態です。

## 1. 現状のステータス
- **完了**:
    - Firebase Storage の統合 (画像アップロード機能)。
    - 設定画面 (`SettingsScreen`) の実装 (Gemini APIキー保存)。
    - ホーム画面 UI の微調整。
    - ドキュメント翻訳 (日本語化)。
- **保留中 (ユーザー作業待ち)**:
    - Firebase プロジェクトの実際の作成と設定 (`firebase login`, `flutterfire configure`)。

## 2. 次回、ユーザー (あなた) がやること

### A. 環境復帰
1.  VS Code で `c:\src\Antigravity\BeanBase2.0` を開く。
2.  ターミナルを開く。

### B. Firebase 設定 (未完了の場合)
`docs/ui_polish_cycle_16/firebase_setup.md` を参照して以下を実行してください。
1.  `firebase login`
2.  `flutterfire configure` (Webを選択)
3.  Firebase Console で Storage を有効化。

### C. アプリ起動確認
1.  `flutter run -d chrome` を実行。
2.  設定画面から API キーを入力。
3.  「Master Add -> Bean」で画像アップロードを試す。

## 3. 次回、Antigravity (私) がやること

### サイクル 17: AI分析の深化と高度な機能
次回チャット開始時に、以下のタスクを指示してください。

1.  **AI分析の改善**:
    - 現在の単純なテキスト生成から、より構造化されたデータ分析へ。
    - 過去のログデータを活用した「おすすめレシピ」の提案機能。
2.  **データ管理の強化**:
    - インポート/エクスポート機能 (JSON/CSV)。
    - バックアップ機能。
3.  **UIの洗練**:
    - モバイルレイアウトの最適化 (レスポンシブ対応の確認)。

## 4. 開発再開時のプロンプト例
次回、Antigravity を起動した際に以下のように話しかけてください：

> 「前回はサイクル16まで完了しました。docs/NEXT_SESSION.md を確認して、サイクル17（AI分析の強化）の計画から始めてください。」

それでは、また次回！お疲れ様でした。
