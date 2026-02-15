# UI改善 (Cycle 10)

## 概要
レーダーチャートとPCAプロットの視認性と解釈性を向上させる。

## タスクリスト

- [x] **Phase 1: Radar Chart の改善**
    - [x] `RadarChartWidget` の文字サイズを大きくする。
    - [x] 軸に数値（得点）を表示する。

- [x] **Phase 2: PCA Plot の改善**
    - [x] `StatisticsService` が固有ベクトル (eigenvectors) を返すように修正。
    - [x] `PcaScatterPlot` に主要成分（PC1, PC2）の寄与率が高い評価項目（Fragranceなど）を表示するUIを追加。
    - [x] ツールチップに「豆名」「抽出方法」「スコア」などを表示するように修正。

- [x] **Phase 3: スマホ対応 (Responsive Design)**
    - [x] 画面サイズに応じたUI調整（特にDashboard, Log List）。
    - [x] `flutter build web` によるデプロイ準備（またはAPKビルド手順の確認）。

- [x] **Phase 4: Master詳細へのログ表示**
    - [x] `CoffeeLogListScreen` からリストアイテムを `CoffeeLogCard` としてウィジェット切り出し。
    - [x] `MasterDetailScreen` (Bean/Equipment) に関連ログリストを追加。
    - [x] `MethodDetailScreen` に関連ログリストを追加。

- [x] **Phase 5: 検証**
    - [x] 実機での表示確認 (Desktop & Mobile Simulation)。
    - [x] Master詳細からログへ遷移できるか確認。
    - [x] `Walkthrough` 作成。
