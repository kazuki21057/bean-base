# 実装計画: 改善サイクル17

ユーザーの要望に基づいて以下の3項目を実施・検証します。
1. **画像の最適化・削除処理**: マスターを削除したタイミングで Firebase Storage (またはローカル) の画像を削除。
2. **リファクタリング**: 複数ファイルに散らばっている画像の選択・プレビュー・アップロードのロジックを汎用化。
3. **統計画面・モバイルUI表示の確認**: 既存及び今回追加された機能のレイアウト確認と、データの視覚的検証。

## 変更内容の詳細

### 1. Storage 画像削除 (Delete Logic)
- **`lib/services/image_service.dart`**
  - 新規メソッド `Future<void> deleteImage(String imageUrl)` を定義。
  - Firebase用 URL の場合： `FirebaseStorage.instance.refFromURL(imageUrl).delete()` で削除。
  - ローカルパスの場合： `File(imageUrl).delete()`。
- **`lib/services/sheets_service.dart`**
  - 既存の `delete{Target}` メソッド（例：`deleteBean`, `deleteGrinder`）を更新し、リストから対象のデータを検索して画像の存在確認を行い、画像があれば `ImageService` 側の削除処理を呼び出す。

### 2. 画像コンポーネント汎用化 (Image Upload Field)
- **`lib/widgets/image_upload_field.dart`** を新規作成。
  - プロパティ: `String? initialImageUrl`, `Function(String) onImageUploaded` など。
  - 状態管理として `FilePicker` を呼び出し、進行中のロードUI、プレビュー用の `BeanImage` ウィジェットをラップする。
- **`lib/screens/master_add_screen.dart`**
  - Bean, Grinder, Dripper, Filter 用の全てのフォームから、`_pickImage` メソッドや冗長な `Row` 周りのUIを削り、代わりに `ImageUploadField` のみ配置するように修正。コードの重複を大幅に削減。

---

## 検証フロー (Verification Flow)

`verification.md` のルールに則り、以下のテストと視覚的検証を行います。

1. `flutter analyze` による静的解析。
2. `flutter test` でユニットテスト・UIテストの回帰確認。
3. `flutter run -d web-server` と `browser_subagent` によるブラウザ検証。
   - 作成した各フォームで「画像付きのマスターデータが正常に投稿・更新・削除できるか」を確認。
   - `Statistics` 画面に遷移し、PCA 散布図と KPI カードが新しいデータを含めてクラッシュせずに描画されるかを確認。
   - モバイル画面サイズのエミュレーションで Responsive デザインに問題がないか視覚的にチェック。
