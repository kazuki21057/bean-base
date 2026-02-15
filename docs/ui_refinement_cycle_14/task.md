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
- [x] **APIチェックツール作成**: `tools/check_gemini.ps1` (PowerShell/curl) を作成し、接続テスト環境を整備。
  - 現状: APIキーは有効だがモデルアクセス権なし (404) を確認済み。
- [x] **モデル名変更**: `gemini-1.5-flash` を優先し、`gemini-pro` へフォールバックするロジックを実装。

## 3. Web/Mobile 対応 (追加)
- [x] **インポート方式変更**: `getDirectoryPath` (PC専用) から `pickFiles` (Web/Mobile対応) へ変更。
- [x] **Web対応**: `kIsWeb` フラグによる保存処理のスキップ（シミュレーションモード）実装。
