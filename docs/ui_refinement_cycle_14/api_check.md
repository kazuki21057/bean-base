# Google Gemini API 接続確認用スクリプト

APIキーの検証を行うためのスクリプトです。
APIキーをチャットに送信せず、ローカル環境で安全に確認するために使用します。

## 実行方法

Dart/Flutterの依存関係エラーを回避するため、PowerShellスクリプトを使用します。
以下のコマンドをターミナルで実行してください（`YOUR_API_KEY` の部分を取得したAPIキーに置き換えてください）。

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_gemini.ps1 "YOUR_API_KEY"
```

## 結果確認

コマンド実行後、ターミナルに表示されるパス（通常はカレントディレクトリの **`api_check_result.txt`**）を確認してください。
`C:\src\Antigravity\BeanBase2.0\api_check_result.txt` などに出力されます。

このファイルを開き、各モデルの `SUCCESS` / `FAILED` の状況を確認してください。

エラー詳細が記載されているため、失敗原因の特定に役立ちます。
