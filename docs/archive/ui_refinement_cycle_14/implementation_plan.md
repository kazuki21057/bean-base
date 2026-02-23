# Bean Master 画像取り込み (Cycle 14) 実装計画

## 概要
Google Drive等から同期されたローカルフォルダを選択し、ファイル名に含まれるBeanIDを基に、Bean Masterデータに画像を紐付ける機能を実装する。
また、Cycle 13で発生したGemini APIエラーとRadar Chartの軸問題を解決する。

## ユーザーレビュー必須事項
- **Gemini API**: `gemini-pro` もエラーとなったため、`gemini-1.5-flash` を再度採用しつつ、エラーハンドリングを強化する方向で進める。
- **画像取り込み**:
  - `file_picker` を使用してフォルダ選択を行う（Desktop環境）。
  - 画像はアプリのローカルストレージにコピーする（推奨）。元の場所へのリンクのみだと、元ファイル移動時にリンク切れするため。

## 変更内容

### 1. 依存関係の追加
- `pubspec.yaml`:
  - `file_picker`: ^6.0.0 (フォルダ選択用)
  - `path`: (標準ライブラリだが念のため確認)
  - `path_provider`: (保存先取得用、既存)

### 2. Master画面 (`lib/screens/master_list_screen.dart` or `bean_list_view.dart`)
- [UI追加] **画像インポートボタン**:
  - `AppBar` または `FloatingActionButton` の近くに配置。
  - アイコン: `Icons.folder_open` または `Icons.add_photo_alternate`。

### 3. ロジック実装 (`lib/services/image_service.dart` 新規作成推奨)
- [NEW] `importBeanImages(String directoryPath)`: **画像一括インポート機能**
  1. 指定ディレクトリ内の画像ファイル (`.jpg`, `.png` 等) をリストアップ。
  2. ファイル名からID抽出 (正規表現: `^([a-f0-9]+)\..*$`)。
  3. `BeanMasterProvider` を参照し、IDが一致するBeanを特定。
  4. 画像を `ApplicationDocumentsDirectory/bean_images/` にコピー。
  5. Beanデータの `imagePath` を更新して保存 (`BeanService.updateBean`)。
  6. インポート結果（成功数、失敗数）を返す。

### 4. Cycle 13 修正
#### `lib/widgets/statistics/radar_chart_widget.dart`
- [FIX] **軸スケール固定**:
  - 全データ0のダミーデータセットを追加済み。正しく0-10の範囲で描画されるか確認。

#### `lib/services/ai_analysis_service.dart`
- [FIX] **モデル指定**:
  - `gemini-1.5-flash` に戻し、エラーキャッチ時に `gemini-1.0-pro` 等へのフォールバックを検討、または明確なエラーメッセージ（「APIキーを確認してください」等）を表示。

## 検証計画
### 自動テスト
- `ImageService` のロジックテスト（ファイル名解析、IDマッチング）。
- `RadarChart` のデータ確認テスト（既存）。

### 手動検証
- **画像インポート**:
  - ダミーの画像ファイルを用意し、IDを含んだファイル名にする。
  - インポート実行後、リスト画面で画像が表示されるか確認。
  - アプリ再起動後も画像が保持されているか確認。
- **Radar Chart**:
  - 軸が 0, 2, 4, 6, 8, 10 のメモリで表示されているか（グリッド線が5本あるか）。
- **AI Analysis**:
  - ボタン押下で分析結果が表示されるか。エラー時は適切なメッセージが出るか。
