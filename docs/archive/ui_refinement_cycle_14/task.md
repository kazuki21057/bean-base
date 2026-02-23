# Bean Master 画像取り込み (Cycle 14)

## 1. Master 画像のインポート
- [x] **画像選択機能**:
  - [x] `file_picker` パッケージを導入する。
  - [x] ユーザーにローカルフォルダ（Google Drive同期フォルダ等）を選択させる。
- [x] **画像マッチングと保存**:
  - [x] 指定ディレクトリ内の画像ファイル (`.jpg`, `.png` 等) をリストアップ。
  - [x] ファイル名からID抽出 (正規表現: `^([a-f0-9]+)\..*$`)。
  - [x] `BeanMasterProvider` を参照し、IDが一致するBeanを特定。
  - [x] 画像を `ApplicationDocumentsDirectory/bean_images/` にコピー。
  - [x] Beanデータの `imagePath` 更新する (`SheetsService.updateBean` 使用)。
  - [x] インポート結果（成功数、失敗数）を返す。
- [x] **UI更新**:
  - [x] Master画面に「画像インポート」ボタンを追加する。
  - [x] インポート結果（成功件数、失敗件数）を表示する。

## 2. Gemini API 修正 (Cycle 14)
- [x] **APIチェックツール作成**: `tools/check_gemini.ps1` (PowerShell) を改善し `gemini-2.5-flash` での接続を確認。
- [x] **モデル名変更**: アプリ本体 (`AiAnalysisService`) を `gemini-2.5-flash` 優先に変更。(`2.0-flash-lite`, `1.5-flash` をフォールバック)

## 3. Web/Mobile 対応 (追加)
- [x] **インポート方式変更**: `getDirectoryPath` (PC専用) から `pickFiles` (Web/Mobile対応) へ変更。
## 4. AI & UI 連携 (追加)
- [x] **日本語化対応**: プロンプトに日本語での回答を指示。
- [x] **結果の埋め込み**: 分析結果をダイアログではなくPCAチャートの下部に表示するように変更。
- [x] **状態保持**: アプリ実行中は分析結果を保持するよう `StateProvider` を導入。
