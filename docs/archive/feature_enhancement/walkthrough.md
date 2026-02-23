# 機能改善 (Walkthrough) - Cycle 5

## 概要
Dashboardの在庫管理、ログ詳細の改善、Calculatorの機能拡張など、ユーザー体験を向上させるための包括的なアップデートを行いました。

## 実施した変更

### 1. Dashboard (Home)
- **Inventory Section**: 「在庫あり」の豆を表示するセクションを追加しました。購入日、開封日、最終使用日が表示されます。
    - *注*: データを表示するには、スプレッドシートへの列追加が必要です（後述）。
- **Recent Brews**: 
    - 不完全なデータ（詳細なし）を除外し、有効なログのみを表示するようにしました。
    - 右側に **Score** を表示し、一目で評価がわかるようにしました。
    - 豆の名前解決（IDではなく名称表示）を行いました。

### 2. All Coffee Logs
- **リスト改善**:
    - ID (`method001`など) ではなく、マスタ名称 (`V60 Standard`など) を表示するようにしました。
    - **Swipe to Copy**: リスト項目を **左にスワイプ** すると、「Copy Recipe」アクションが表示され、そのレシピ（メソッドと豆の量）を適用して **Brewing Calculator** に遷移・コピーできるようになりました。
- **Log Detail**:
    - 評価スコア (Fragrance, Overall等) が 0 の場合でも、データがあれば表示するように修正しました。
    - Water Temp, Total Time (mm:ss表記) の表示を修正・改善しました。

### 3. Brewing Calculator
- **Proportional Update**: 豆の量 (`Bean Weight`) を変更すると、メソッドの各ステップの注湯量 (`Water`) が現在の重さに合わせて **自動的に比例計算** されるようになりました。
- **Timer**: 画面中央にストップウォッチ機能を追加しました（Start/Stop/Reset）。
- **UI改善**: Add Step / Save ボタンを表の右下に配置し、操作性を向上させました。

### 4. Masters
- **Beans**: 名称が `-` のダミーデータを非表示にしました。
- **Filters**: Material / Size 情報をリストに表示しました。
- **Method Detail**: 各ステップの時間を `mm:ss` 表記にし、テーブル下部に **Total Time / Total Water** の合計値を表示するようにしました。

## ユーザー対応が必要な作業（スプレッドシート）

在庫機能を使用するには、Googleスプレッドシートへの修正が必要です。
詳細は `docs/feature_enhancement/sheet_instructions.md` を参照してください。

## 検証結果
- **自動テスト**: `flutter test` にてロジック検証完了。
- **実機確認**: `flutter run` にて起動およびデータ読み込み（API通信）が正常に行われることを確認しました。
    - 現時点ではスプレッドシートに新カラムがないため「在庫」は表示されませんが、カラム追加後に自動的に反映されます。
