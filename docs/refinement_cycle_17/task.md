# 改善サイクル17: UI/UX改善とコンポーネントの共通化、統計機能の検証

今回は以下の3つのタスクを計画通りに実施します。

## Phase 1: 画像の最適化・削除処理 (Storage Management)
- [ ] **ImageServiceの改修:** `image_service.dart` に `deleteImage` メソッドを追加する。
    - Firebase StorageのURL（`firebasestorage.googleapis.com`）かローカルパスかを判定。
    - Firebaseであればストレージから画像を削除。
    - ローカルパスであれば `dart:io` を使ってローカルファイルを削除。
- [ ] **SheetsServiceの改修:** スプレッドシート側のデータ削除処理（`deleteBean`, `deleteGrinder`, etc.）に画像削除処理を連携させる。
    - 各データの削除時に保存されている `imageUrl` を取得し、`ImageService.deleteImage` を呼び出す。

## Phase 2: 画像アップロードコンポーネントの共通化 (Refactoring)
- [ ] **新規カスタムウィジェット:** `lib/widgets/image_upload_field.dart` を作成する。
    - 現行の「画像ファイルの選択」→「プレビューの表示」→「アップロード処理」を全て内包する汎用的なウィジェットにする。
- [ ] **フォーム画面の改修:** `lib/screens/master_add_screen.dart` の各フォームから重複する処理を削除し、新規ウィジェットを組み込む。
    - [ ] BeanAddForm（豆）
    - [ ] GrinderAddForm（ミル）
    - [ ] DripperAddForm（ドリッパー）
    - [ ] FilterAddForm（フィルター）

## Phase 3: 検証作業 (Verification)
- [ ] **テストの実行:** `flutter test` を実行し、既存のテスト（`calculator_test.dart` や `screen_transition_test.dart`）が全てパスすることを確認。
- [ ] **動作の視覚的検証:** `browser_subagent` を使って（`flutter run -d web-server` 上）以下の動作をチェックする。
    - [ ] 新共通コンポーネントでの新しい画像アップロードが機能するか。
    - [ ] データ削除時に、関連する画像も正しく削除処理が走っているか（ログやエラーの有無を確認）。
- [ ] **統計画面の動作とモバイル表示確認:** 
    - [ ] 最新データにおける PCA散布図（主成分分析）や KPI カードが正しく表示されるかの確認。
    - [ ] モバイルサイズのブラウザ画面（開発者ツール等）で統計画面を表示し、レイアウト崩れ`Overflow`がないかを確認。
- [x] 画像削除・コード共通化対応と検証完了
