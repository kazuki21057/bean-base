# 実装計画: Refinement Cycle 8

## 目的
ユーザーフィードバックに基づく機能改善とバグ修正。

## 変更内容

### 1. Data Parsing Fixes (`lib/services/sheets_service.dart`)
- **Water Temp**: `temperature` のキーマッピングを確認・修正。
    - ログでは `湯温(℃)` となっているが、前回 `SheetsService` のマッピングに含まれていないか、キー名が間違っている可能性。
    - `湯温(℃)` -> `temperature` にマッピングを追加/修正。

### 2. Calculator Enhancements (`lib/screens/calculator_screen.dart`)
- **Inputs**: 以下のフィールドを追加。
    - `Temperature` (num input, suffix °C)
    - `Grind Size` (Text input or Slider if numeric? usually text like "Fine", "Medium")
    - `Taste` (String? or Slider?) -> Log has `taste` column. Text or ENUM? User said "Register items managed in log". I will utilize `TextEditingController` for flexibility.
    - `Concentration` (Text/Slider).
- **Highlight Logic**:
    - 現在のハイライト条 `elapsed >= prev && elapsed < cur` を変更。
    - リクエスト: 「現在の行の1つ上」。
    - 変更後: `elapsed` が `Step N` の区間にある時、`Step N-1` をハイライトする。
        - `index > 0` の場合のみ。`Step 1` の時はハイライトなし、または `Step 0` (Pre-wetting?) があればそれ？
        - おそらく「抽出中」のステップの「前の完了したステップ」ではなく、「次にやるべきこと」の視認性が問題？
        - ユーザー指示通り `index - 1` をハイライト対象とする（Step 1実行時はハイライトなし）。
- **Reuse Feature**:
    - `CalculatorScreen` のコンストラクタ引数を拡張: `CoffeeRecord? reuseLog` または全フィールド個別引数。
    - `reuseLog` が渡された場合、`initState` で全フィールド (`Method`, `BeanWeight`, `Equipment`, `Scores`, `Notes`, `Temp`, `Grind`, etc.) を初期値としてセット。

### 3. Dashboard / Log List UI (`lib/screens/home_screen.dart`, `lib/screens/coffee_log_list_screen.dart`)
- **Score Bubble**:
    - デザイン変更:
        - 配置: `Trailing` の右端（IconButtonの左）。`Row` で配置。
        - サイズ: `minRadius + (score * factor)`.
        - 文字サイズ: `fontSize = score * factor`.
- **Log List**:
    - Dashboardと同じデザインを適用。

### 4. Masters (`lib/screens/master_list_screen.dart`, `lib/models/bean_master.dart`)
- **Add Button**: `MasterListScreen` のAppBarに `+` ボタン追加。
    - タップ時、各マスタに応じた新規登録画面 (`MasterAddScreen` which wraps `_BeanAddForm`, `_GrinderAddForm` etc.) へ遷移。
- **Bean Master Update**:
    - **Model**: `BeanMaster` に `store` (購入店舗) と `type` (豆の種類) フィールドを追加。
    - **Service**: `SheetsService` で `購入店舗` -> `store`, `豆の種類` -> `type` のマッピングを追加。
- **Bean Registration Screen**:
    - **Input Fields**: Store, Origin, Roast, Type.
    - **Auto-Name Logic**: 4つのフィールドが変更されるたびに、Nameフィールドを自動更新 (`"$Store $Origin $Roast $Type"`).
    - **Validation**: 必須項目のチェック。

### 5. Sheets Service Fix
- **Water Temp**: `temperature` キーマッピング修正（`湯温(℃)`）。
- **New Bean Columns**: 上記 `store`, `type` の追加。

## 検証方法
- `flutter run` でハイライトが1行上にズレているか確認。
- Reuseボタンで全データがCalculatorに入力されるか確認。
- ログリストのスコアバブルの視認性確認。
- 豆登録時の名前自動生成確認。
