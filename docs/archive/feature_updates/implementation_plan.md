# 実装計画: UI Refinements

ユーザーからのフィードバックに基づき、以下のUI改善を実施する。

## 1. Coffee Log Edit Screen
**File:** `lib/screens/log_edit_screen.dart`
- **変更点**: `_buildSection('Scores', [...])` 内のリストの順序を変更する。
- **詳細**: `_buildScoreSlider('Overall', ...)` をリストの最後に移動する。

## 2. Method Steps Edit
**File:** `lib/screens/method_detail_screen.dart`
- **変更点**: `_buildStepsList` 内の `TextFormField` (Time) の処理を変更する。
- **実装詳細**:
  - `initialValue`: 秒数 (`int`) を `mm:ss` 形式の文字列に変換して表示する関数作成 (e.g., `_formatTimeInput(int seconds)`).
  - `onChanged`: 入力された `mm:ss` 文字列を解析して秒数 (`int`) に変換するロジックを追加 (e.g., `_parseTimeInput(String value)`).
  - バリデーション: 不正なフォーマットの場合は入力を無視するかエラーを出す（今回は簡易的にパース成功時のみ反映）。

## 3. Master Grid Images
**File:** `lib/screens/master_list_screen.dart`, `lib/screens/home_screen.dart`
- **変更点**: 画像表示ロジックの見直し。
- **現状の疑念**: `imageUrl` が存在していても、何らかの理由（nullチェックの不備、Widgetの構成ミス）でプレースホルダーが表示されている可能性がある。
- **修正方針**:
  - `Image.network` の `errorBuilder` を正しく設定し、URLが有効な場合は確実に画像を表示するようにする。
  - 画像データ（URL）が実際に渡ってきているか確認する。

## 検証計画
- `flutter run` で実機確認。
  - ログ編集画面でOverallが一番下にあるか。
  - メソッドステップ編集で `1:30` のように入力して正しく秒数(90秒)として保存・計算されるか。
  - マスタ一覧で、画像URLが設定されているアイテムが正しく画像表示されるか。
