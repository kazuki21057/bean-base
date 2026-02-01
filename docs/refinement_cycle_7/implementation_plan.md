# 実装計画: Refinement Cycle 7

## 目的
クラッシュバグの修正、Calculatorの表示・操作性改善、DashboardのUX向上。

## 変更内容

### 1. Log Detail Fix (`lib/screens/log_detail_screen.dart`)
- `resolve` 関数の `orElse` を修正。
    - `orElse: () => null` は `AsyncValue.data` の型 `List<T>` 要素が Non-nullable の場合に型不一致を起こす。
    - `collection` パッケージの `firstWhereOrNull` を使用するか、`cast<dynamic>()` で回避するか、単純な `for` ループ検索に変更する。
    - 最も安全な `for` ループ検索に変更する。

### 2. Calculator Fix & Enhancements (`lib/screens/calculator_screen.dart`)
- **Overflow Fix**: `body` 全体を `SingleChildScrollView` でラップ（Cycle 6で対応済みか確認、調整）。
- **Step Reordering**: `Action` カラムに `Up` / `Down` アイコンボタンを追加。
    - `_moveStep(index, direction)` メソッド実装。
- **Highlighting**:
    - `_TimerWidget` を廃止し、タイマーロジックを `_CalculatorScreenState` に移動（Hoist）。
    - 現在の経過時間に基づき、該当行をハイライト。
- **Collapsible Table**:
    - Pouring Steps のテーブルを `ExpansionTile` (または `Visibility` + Toggle Button) でラップ。
    - 初期状態は **Closed (Hide)** とする（ユーザー要望）。

### 3. Dashboard Enhancements (`lib/screens/home_screen.dart`)
- **Recent Brews**:
    - **Layout**:
        - Leading: `Score` Circle (Radius = Score * constant).
        - Title: Bean Name.
        - Subtitle: Date.
        - Trailing: `Reuse` IconButton (`Icons.replay`).
    - **Reuse Logic**: `Navigator.push` -> `CalculatorScreen(initialMethodId, initialBeanWeight)`.
- **Inventory**:
    - `onTap`: `MasterDetailScreen` へ遷移。

### 4. Master Detail (`lib/screens/master_detail_screen.dart`)
- `Date` 表示フォーマットを `yyyy/MM/dd` に変更 (`intl` DateFormat または文字列操作)。

## 検証計画
- **Log Detail**: 詳細画面を開いてもクラッシュしないこと。
- **Calculator**:
    - 画面がスクロールでき、下部が切れないこと。
    - ステップの入れ替えが動作すること。
    - タイマー開始後、進行に合わせて行がハイライトされること。
- **Dashboard**:
    - ReuseボタンでCalculatorに遷移し、値がセットされていること。
