# タスクリスト: レイアウトと機能追加

- [x] **データサービスの基盤**
  - [x] `SheetsService`: `addPouringStep` と `updatePouringStep` メソッドを追加。
  - [x] `SheetsService`: `deletePouringStepsForMethod`（または単純に `update`）を追加。
  - [x] `_reverseMapPouringStep` の実装。

- [x] **メソッドステップの実装**
  - [x] **MethodStepsEditor ウィジェット**: `MethodDetailScreen` から編集ロジックを抽出して再利用可能なウィジェット化。
  - [x] **MethodDetailScreen**: `MethodStepsEditor` を使用するようにリファクタリングし、`SheetsService` を介した**実際の保存機能**を実装。
  - [x] **MasterAddScreen**: `MethodAddForm` を更新して `MethodStepsEditor` を含める。
    - [x] メソッド作成後のステップ保存処理の実装（メソッドIDが必要）。

- [x] **レイアウトとサイドバー**
  - [x] **MainScaffold**: 常設の `NavigationRail` (サイドバー) と `Row` レイアウトを持つ新しいScaffoldを作成。
  - [x] **メインナビゲーション**: `MyApp` と `Home` をリファクタリングし、`MainScaffold` をシェルとして使用。
  - [x] 「サイドバーを常に表示する」要件の達成（`MaterialApp.builder` またはトップレベル画面のラップを使用）。

- [x] **Drive連携**
  - [x] すべての画面で `ImageUtils` の使用を確認（Master/Homeは概ね完了済み）。
  - [x] `LogDetailScreen` でログ画像に `ImageUtils` を使用することを確認。

- [x] **検証**
  - [x] `flutter test` の実行。
  - [x] 手動検証（サイドバーの表示、ステップ付きメソッドの作成）。

- [x] **デバッグと修正 (今回)**
  - [x] **サイドバー**: `GlobalKey<NavigatorState>` を使用して `Navigator` コンテキストエラーを修正。
  - [x] **サイドバーの重複**: `HomeScreen` から不要な `NavigationRail` を削除。
  - [x] **計算機**: 豆の量を変更した際に、ステップの湯量（UI表示）が更新されない問題を修正。
  - [x] **保存処理**: `CalculatorScreen` に実際の `addCoffeeRecord` 実装を追加し保存可能にする。
  - [x] **GASスクリプト更新**: サーバーサイド (`Code.gs`) に `doPost` を実装し、CORS対応と書き込み処理を追加する。
