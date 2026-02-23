# Refinement Cycle 7: Fixes & Feature Enhancements

## 概要
 `LogDetailScreen` のクラッシュ修正、Calculatorの大幅なユーザビリティ改善、Dashboardの機能強化、および日付表示のフォーマット修正を行いました。

## 変更内容

### 1. Log Detail Fix
- **Crash Fix**: 詳細画面遷移時に発生していた `TypeError` (firstWhere orElse) を修正しました。これで安全に詳細画面を開けます。

### 2. Calculator Enhancements
- **Collapsible Table**: "Pouring Steps" のテーブルを折りたたみ可能 (`ExpansionTile`) にし、デフォルトで「閉じた状態」にしました。これにより、タイマーやログ入力が見やすくなりました。
- **Reordering**: ステップの入れ替え機能 (↑ ↓ ボタン) を追加しました。
- **Active Highlight**: タイマー動作中、現在の時間に対応するステップ行がハイライト（黄色）されるようになりました。
- **Timer Hoisting**: タイマーの状態管理を画面全体に持ち上げ、ハイライト機能との連動を実現しました。

### 3. Dashboard Enhancements
- **Recent Brews**:
    - **Score Bubble**: スコアに応じた大きさの円形アイコンを表示するようにデザインを変更しました。
    - **Reuse Button**: 各ログに「再利用 (Reuse)」ボタンを追加しました。押すとそのログのメソッドと豆量を引き継いで `Calculator` 画面が開きます（テーブルはデフォルトで閉じており、ログ入力に集中できます）。
- **Inventory Nav**: インベントリの在庫をクリックすると、その豆の詳細画面 (`MasterDetailScreen`) に遷移するようにしました。

### 4. Masters
- **Date Format**: 豆詳細画面などの日付表示から時刻を削除し、`yyyy/MM/dd` 形式に統一しました。

## 検証結果
- `flutter run` にてビルドおよび起動を確認。
- 各画面遷移（Dashboard -> Calculator, Dashboard -> LogDetail, Dashboard -> BeanDetail）のコードパスが正しいことを確認済み。
