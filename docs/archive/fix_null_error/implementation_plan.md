# 実装計画: 広範な不具合の修正と原因分析

## 原因分析 (再検討結果)

### 1. クラッシュの原因
- **Grinders画面**: `_JsonMap is not subtype of List`
  - API (Google Sheets) が期待するデータリスト `[]` ではなく、エラーメッセージ等のオブジェクト `{}` を返しています。
- **Methods画面**: `Null is not subtype of num`
  - `MethodMaster` の数値フィールド (`baseBeanWeight` 等) が必須なのに、データが無い(Null)ためクラッシュしています。

### 2. データが表示されない("Unknown", "0")の原因
- アプリは `name` や `scoreOverall` というキーでJSONから値を探しています。
- これらが全てデフォルト値("Unknown" や 0) になっているということは、**Google Sheets の 1行目（ヘッダー）の名前が、コードと一致していない** 可能性が極めて高いです。
  - 例: コードは `name` を期待しているが、シートのヘッダーが `名前` や `Name` になっている、など。

## Proposed Changes

まずは「アプリが落ちる」状態を脱却し、どんなデータが来ても画面が表示されるようにします。

### Service Layer

#### [MODIFY] [sheets_service.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/services/sheets_service.dart)
- **非リストレスポンスのハンドリング**: `json.decode` の結果が `List` でなければ、空リストを返し、エラーにならにようにします。
- **個別レコードの防御**: `map((e) => ...)` の中で `try-catch` を行い、パースに失敗した行があっても、その1行だけを無視して残りのデータを表示するようにします。

### Models

#### [MODIFY] [method_master.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/models/method_master.dart)
- `baseBeanWeight`, `baseWaterAmount` に `@JsonKey(defaultValue: 0.0)` を追加。

## Verification Plan

### Manual Verification
1. アプリを再起動。
2. "Masters > Grinders" を開き、エラー画面ではなく（データが取れなければ）空のリストが表示されることを確認。
3. "Masters > Methods" を開き、クラッシュしないことを確認。
4. "Unknown" が続く場合、シートのヘッダー名を確認する必要がある旨をユーザーに伝える。
