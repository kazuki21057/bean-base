# デバッグと修正計画 (Debugging & Fixes Plan)

## 1. サイドバーナビゲーションエラー
**問題**: `MainLayout` が `Navigator` をラップしているため、その内部での `Navigator.of(context)` が機能しない。
**修正**:
- `main.dart`（またはアクセス可能な場所）でグローバルな `final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();` を定義する。
- このキーを `MaterialApp(navigatorKey: navigatorKey)` に渡す。
- `MainLayout` 内で、`Navigator.of(context)` の代わりに `navigatorKey.currentState!.pushAndRemoveUntil(...)` を使用する。

## 2. サイドバーの重複
**問題**: `HomeScreen` が明示的に `NavigationRail` を含む `Row` を構築している。
**修正**:
- `HomeScreen` をリファクタリングし、`Row` と `NavigationRail` を削除する。
- `_buildInventorySection` と `_buildRecentLogsSection` は維持するが、メインビュー（`SingleChildScrollView`）内に直接配置し直す。

## 3. 計算機のUI更新
**問題**: ステップの湯量に使用される `TextFormField` は、`initialValue` が一度しか読み込まれないため、`beanWeight`（豆量）が変更されても更新されない。
**修正**:
- `CalculatorScreen` 内の `TextFormField` に `key: ValueKey(currentTotal)` を追加する。これにより計算後の合計値が変更されるたびにウィジェットが再構築（および `initialValue` の再読み込み）されるようになる。

## 4. 保存機能 (コーヒーログ)
**問題**: `CalculatorScreen` の `_logThisBrew` メソッドがスタブ（ログ出力のみ）である。
**修正**:
- `_logThisBrew` を以下のように更新する:
  1. 現在の状態から `CoffeeRecord` オブジェクトを作成する。
  2. 新しいID（例: `REC-${DateTime.now().millisecondsSinceEpoch}`）を生成する。
  3. `ref.read(sheetsServiceProvider).addCoffeeRecord(record)` を呼び出す。
  4. 成功のSnackbarを表示し、任意でログ一覧画面へ遷移する。
