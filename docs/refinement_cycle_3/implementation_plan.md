# 実装計画: 修正と改善 (Cycle 3)

## 目的
CalculatorのTime累積表示、スプレッドシート実データの正確な読み込み、詳細画面の表示整理を行う。

## 変更内容

### 1. CalculatorScreen (`lib/screens/calculator_screen.dart`)
- `Time (s)` 列の表示を、各ステップの `duration` ではなく、前のステップまでの合計 `startTime` + 現在の `duration`（または開始時点）に変更する。
- ユーザー要望は「Timeも加算表示」なので、そのステップが終了する累積時間を表示するか、開始時間を表示するか検討。通常は「到達時間」を示すため、累積時間を表示する。
- 入力値は `duration` (区間時間) のまま維持し、表示のみ累積とする（編集時は区間時間を入力）。

### 2. データ読み込み修正 (`lib/models/coffee_record.dart`, `lib/services/sheets_service.dart`)
- **日付パース**: `2025/04/14 7:39` のような形式に対応するため、`/` を `-` に置換してからパースする、あるいは `intl` パッケージを使用する処理を追加。
- **キーマッピング**: 画像から読み取ったヘッダー名とコード内のマッピング定義を照合・修正する。
    - 液温 -> `temperature`
    - 蒸らし湯量 -> `bloomingWater` (ml) ?
    - 湯量 -> `totalWater` (ml) ?
    - 蒸らし時間 -> `bloomingTime` (秒)
    - 抽出時間 -> `totalTime` (秒)
- **ID連携**: Coffeeデータ内の `抽出方法` (method001...) が `MethodMaster` のIDと一致しているか、あるいは名前で紐付けているか確認し、不一致なら変換ロジックを入れる。

### 3. 詳細画面 (`lib/screens/*_detail_screen.dart`)
- 項目ビルド時に `value == null || value == '' || value == '0' || value == 0` の場合、ウィジェットを生成せず `SizedBox.shrink()` を返すように修正。

## 検証計画
- `test/verification_test.dart` に、スプレッドシート画像から読み取った実データ（日本語ヘッダー、スラッシュ区切り日付）を用いたテストケースを追加し、パース成功を確認する。
- `flutter run` で実機確認を行う際の手順を明記する。
