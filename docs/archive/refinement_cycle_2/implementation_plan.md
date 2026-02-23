# 実装計画: 修正と改善 (Cycle 2)

## 目的
Calculatorの表示をユーザー要望に合わせ、データ読み込みの信頼性を向上させ、詳細画面の情報を拡充する。

## 変更内容

### 1. CalculatorScreen (`lib/screens/calculator_screen.dart`)
- **テーブル列変更**: `Water (ml)` (加算量) と `Target (ml)` を廃止または統合し、`Total Weight` (累積総量) カラムを表示する。
- **計算ロジック**: 各行の `waterAmount` (加算量) を積み上げて累積値を表示する。編集時は「加算量」を編集し、即座に「合計」が再計算されるようにする。

### 2. データ読み込み修正 (`lib/models/*.dart`, `lib/services/sheets_service.dart`)
- **Unknown排除**: 各モデルの `@JsonKey(defaultValue: 'Unknown ...')` を `''` (空文字) または `'-'` に変更する。
- **CoffeeRecord読み込み修正**: 
    - 必須フィールドが欠けている場合にパースエラーになっている可能性があるため、`CoffeeRecord` のフィールドを可能な限り Nullable に変更するか、デフォルト値を強化する。
    - 特に `brewedAt` や数値フィールドのパース失敗を徹底的に防ぐ。

### 3. 詳細画面の拡張
- **MethodDetailScreen**: `MethodMaster` を表示する際、関連する `PouringStep` を取得して表示するロジックを追加する（または専用画面を作成）。
- **LogDetailScreen**: `CoffeeLogListScreen` から遷移する詳細画面を作成する。

## 検証方法
- `flutter test` にて計算ロジックとデータパースのテストを実行。
- `test/verification_test.dart` にログ読み込みの実データに近いケースを追加。
- `flutter run`で表示を確認。元データと差異があれば修正をする。

