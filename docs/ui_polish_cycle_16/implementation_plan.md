# 実装計画 - サイクル16: Firebase Storage & 設定画面

## 目標
1.  **Firebase Storage**: 画像をクラウドに保存し、Web/Mobile問わず参照可能にする。
2.  **設定**: APIキーの管理画面を追加。
3.  **検証**: アップロード機能の動作確認用画面を作成する。

## ユーザーレビュー事項 (Firebase 設定)
> [!IMPORTANT]
> **Firebase プロジェクトのセットアップが必要です**
> 実装を進めるにあたり、Google Cloud / Firebase コンソールでのプロジェクト作成と、ローカルでの紐付け作業 (`flutterfire configure`) が必要になります。これらは認証を伴うため、ユーザー自身での操作が必要です。

## 提案する変更

### 1. Firebase Storage 導入

#### [DEPENDENCY] `pubspec.yaml`
- `firebase_core`
- `firebase_storage`

#### [MODIFY] `lib/main.dart`
- `Firebase.initializeApp()` を呼び出す (`DefaultFirebaseOptions` を使用)。

#### [MODIFY] `lib/services/image_service.dart`
- **変更**:
  - `uploadImage(File/Uint8List file, String filename)` メソッドを追加。
  - Firebase Storage の `bean_images` フォルダにアップロード。
  - ダウンロードURLを返す。
  - `importBeanImages` を更新し、アップロード処理を組み込む。

#### [NEW] `lib/screens/debug/firebase_test_screen.dart`
- **検証用画面**:
  - 「画像を選択」ボタン。
  - アップロード進捗バー。
  - 取得したURLの表示。
  - 画像のプレビュー表示 (ネットワーク経由)。

### 2. 設定画面 & その他

#### [NEW] `lib/screens/settings_screen.dart`
- Gemini APIキー設定。
- (オプション) Firebase検証画面へのリンク（デバッグ用）。

#### [MODIFY] `lib/screens/home_screen.dart`
- 設定ボタン追加。

## 検証計画

### 手動検証
1.  **Firebase Test Screen**:
    -   画像をアップロードし、エラーが出ないこと。
    -   表示されたURLにアクセスできること。
2.  **Master Add/Edit**:
    -   新しい豆の画像を登録し、保存後、リスト画面で正しく表示されること。
    -   Web版でリロードしても画像が表示されること。
