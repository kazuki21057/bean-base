# 次回のアクション (Cycle 14 残課題まとめ)

## 現状のステータス
- **画像インポート機能**: Windows環境構築不可のため、**Web/Mobile互換の「複数ファイル選択方式」** に変更しました。
  - Web版 (`flutter run -d chrome`) では、セキュリティ制約によりファイルの永続保存はできず、動作確認（シミュレーション）のみとなります。
  - 本番運用で画像を保存するには、スマホ（Android/iOS）または PC（Windows/Mac）でのビルドが必要です。
- **Gemini AI**: APIキーは有効ですが、**モデルへのアクセス権がありません** (`404 Not Found`)。

## 次回行うべきこと

### 1. APIキーの再作成 (Google AI Studio)
- **問題**: 現在のAPIキーでは `gemini-1.5-flash` 等のモデルが使用できません。
- **対策**:
  1. [Google AI Studio](https://aistudio.google.com/app/apikey) にアクセス。
  2. 左上の **「Create API Key」** -> **「Create API key in new project」** を選択。
  3. 新しいキーを取得し、`lib/main.dart` (または `.env`) の `apiKey` を更新してください。
  4. `tools/check_gemini.ps1` で動作確認を行ってください。

### 2. インポート機能の確認
- アプリを `flutter run -d chrome` で起動し、「Import Images」ボタンから複数画像を選択して、エラーが出ないことを確認してください。

### 3. (将来的) Windows環境の構築
- 本格的にPCで管理する場合、Visual Studio (C++) のインストールを行い、`flutter run -d windows` が動くようにすることを推奨します。

---
**コマンドメモ**
- APIチェック: `powershell -ExecutionPolicy Bypass -File tools/check_gemini.ps1 "YOUR_API_KEY"`
- アプリ起動: `flutter run -d chrome`
