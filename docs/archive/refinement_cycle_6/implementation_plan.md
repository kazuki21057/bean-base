# 実装計画: Refinement Cycle 6

## 目的
データ読み込み不具合の解消と、Brewing Calculatorの入力機能強化。

## 変更内容

### 1. Data Parsing Fixes
- **`lib/services/sheets_service.dart`**
    - `getCoffeeRecords`: Evaluation系のキーマッピングを以下のように修正する。
        - `'香り' -> '香り(1-10)'`
        - `'酸味' -> '酸味(1-10)'`
        - ... 他 (`苦味`, `甘み`, `コク`, `フレーバー`, `総合評価`) も同様。
- **`lib/models/equipment_masters.dart`**
    - `FilterMaster`: `size` フィールドに `@JsonKey(fromJson: _parseString)` を適用（`CoffeeRecord` から `_parseString` をコピーまたは共通化）。
        - *Note*: `equipment_masters.dart` 内に `_parseString` を定義する必要がある。

### 2. Log Detail Fix
- データ読み込みが治ればエラーも解消する可能性が高いが、`LogDetailScreen` で `null` のスコアデータにアクセスする箇所があれば保護する（前回 `allowZero` 対応済みなので概ね大丈夫なはず）。

### 3. Calculator UI Expansion (`lib/screens/calculator_screen.dart`)
- **State Changes**:
    - 選択された `Grinder`, `Dripper`, `Filter` を保持する変数を追加。
    - `Notes` 用の `TextEditingController` を追加。
    - `Scores` (7項目) を保持する Map または個別の変数を追加。
- **UI Structure**:
    - Tableの下に `ExpansionTile` または `Card` で区切って以下を追加：
        - "Equipment": Dropdowns for Grinder/Dripper/Filter.
        - "Evaluation": Sliders (0-10) for each score.
        - "Notes": TextArea.
- **Save Log Logic**:
    - "Save Log" ボタンを追加。
    - 押下時、現在の状態（Method, Steps, Bean, Equipment, Scores, Notes）から `CoffeeRecord` オブジェクトを構築し、コンソールに出力（将来的なAPI Saveへの準備）。

### 4. Method Save Logic (Calculator)
- `_save` メソッドのロジック確認:
    - 現行: `_workingSteps` をそのまま保存。
    - 修正: `waterRatio` の再計算。
        - Bean Weight を変更した場合 (`factor != 1.0`):
        - 保存される各ステップについて:
            - `newRatio = workingStep.waterAmount / currentBeanWeight`
            - `baseBeanWeight` (Method) = `currentBeanWeight` (or keep original?) -> User wants "Ratio Only".
            - Best approach: Update Method's `baseBeanWeight` to `currentBeanWeight`, and recalculate `waterRatio` for each step based on the *actual* amount in the table.
            - `WaterReference` (normalized to 15g)? Maybe kept as calculated property.
            - ユーザー要望: "豆の量を変更し、Pouring Stepsのお湯の量を変更しなければ、上書きしても元データは変わらない"
                - これを実現するには、`MethodMaster` の `baseBeanWeight` は変更せず、`waterRatio` も変更しないのが正解？
                - しかし `Bean Weight` を変更した時点で、アプリ上の `waterAmount` は `factor` 倍されている。
                - もしユーザーが `waterAmount` を手動でいじっていなければ、`Amount / CurrentWeight` は元の `Ratio` と同じはず。
                - したがって、常に `Ratio = Amount / CurrentWeight` を再計算して保存すれば、もし変更なければ同じ値になり、変更あれば新しいRatioになる。これでOK。

## 検証方法
- `flutter run` で Evaluation が読まれているかログ確認。
- `FilterMaster` の `size` が読まれているかログ確認。
- Calculator で値をいじって "Overwrite" した際、ログに出力されるステップ情報が期待通り（Ratioが維持または更新）か確認。
