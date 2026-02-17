# サイクル16: Firebase Storage & 設定画面

## 1. Firebase Storage 導入
- [ ] **プロジェクト設定 (ユーザー作業)**:
  - [ ] Firebase プロジェクトの作成。 (未実施)
  - [ ] `flutterfire configure` の実行 (APIキー/AppIDの生成)。 (未実施)
- [x] **依存関係の追加**:
  - [x] `firebase_core`, `firebase_storage` パッケージの追加。
  - [x] `main.dart` での `Firebase.initializeApp()` 実装。
- [x] **画像アップロード機能**:
  - [x] `ImageService` の更新:
    - [x] 選択された画像を Firebase Storage (`bean_images/`) にアップロード。
    - [x] アップロード後の「ダウンロードURL」を取得して返す。
  - [x] `MasterAddScreen` / `SettingsScreen` (インポート機能) の更新:
    - [x] 画像選択時にアップロード処理を呼び出し、URLを取得して保存。
- [x] **検証プログラム (Verification)**:
  - [x] `lib/screens/debug/firebase_test_screen.dart` を作成。
    - [x] 画像選択 -> アップロード -> URL表示 -> 画像表示 の一連の流れをテストできる画面。

## 2. 設定ページ (APIキー & 管理)
- [x] **設定画面 (Settings Screen)**:
  - [x] `lib/screens/settings_screen.dart` を作成。
  - [x] Gemini APIキー入力・保存 (`shared_preferences`).
  - [x] ナビゲーション (`HomeScreen` AppBar) に追加。

## 3. UIの微調整 & クリーンアップ
- [x] **リンクボタン**: ツールチップ追加。
- [x] **不要コード削除**: `flutter analyze` 対応。

## 4. デプロイ準備
- [ ] ビルド確認。
