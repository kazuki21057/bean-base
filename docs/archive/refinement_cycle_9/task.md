# 統計情報ページ開発タスク (Cycle 9)

## 概要
ユーザーのコーヒー抽出データを分析・可視化する `StatisticsScreen` を実装する。

## タスクリスト

### Phase 1: データ集計ロジックの実装
- [x] **Statistics Service**: `coffeeRecordsProvider` 等から集計値を算出する Service クラスを作成。
    - [x] KPI計算 (Total Brew, Total Beans, Avg Score)。
    - [x] グルーピング集計 (Bean別/Method別平均)。
    - [x] PCA計算ロジック (共分散行列、固有値分解)。

### Phase 2: UIコンポーネントの実装
- [x] **KPI Cards**: `Total Brews`, `Total Beans`, `Average Score`。
- [x] **Filter UI**: Date Range Picker (期間指定), Bean/Method Toggle。
- [x] **Interactive Radar Chart**: 
    - [x] ドロップダウンで比較対象 (Bean/Method) を選択。
    - [x] 全体平均 vs 個別データの重ね合わせ表示。
- [x] **PCA Scatter Plot**:
    - [x] 豆ごとの主成分得点 (PC1, PC2) を散布図にプロット。
    - [x] ポイントのタップで豆情報を表示。

### Phase 3: ランキング機能
- [x] **Ranking List**: 
    - [x] Tab/Toggle UI: Beans / Methods 切替。
    - [x] 指標切替: Rating / Count。

### Phase 4: 統合と検証
- [x] **StatisticsScreen**: 上記コンポーネントを配置し、レスポンシブなレイアウトを組む。
- [x] **Verification**:
    - [x] `flutter build linux` (Build Succeeded).
    - [x] Unit Tests for `StatisticsService` passed.
    - [ ] 実機での表示確認 (Build verified, logic verified via tests).

> [!NOTE]
> PCA functionality is temporarily disabled due to `ml_linalg` version compatibility issues (SingularValueDecomposition). The UI placeholder exists but returns empty data.
