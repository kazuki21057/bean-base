# 統計情報ページの基本設計

## 1. 概要
- `StatisticsScreen` にユーザーの抽出活動の統計情報を表示する。
- データの可視化を通じて、コーヒーの楽しみを深め、改善点を発見できるようにする。

## 2. 実装項目

### 2.1 summary (KPI) カード
画面上部に主要な指標をカード形式で表示する。
- **Total Brews**: 総抽出回数
- **Total Beans Used**: 総使用豆量 (kg または g)
- **Average Score**: 平均総合評価 (Overall Score)

### 2.2 チャート
`fl_chart` パッケージを使用してデータを可視化する。

#### A. Taste Profile (Radar Chart) [Interactive]
- **選択式**: デフォルトは「全体平均」。ドロップダウンで「特定の豆」または「特定の抽出レシピ(Method)」を選択可能にする。
- プロファイル: Fragrance, Acidity, Bitterness, Sweetness, Complexity, Flavor の6軸。
- 比較表示: 選択した対象 vs 全体平均 を重ねて表示。

#### B. Score Distribution (Pie/Bar Chart)
- スコア (1-10) の分布。

### 2.3 ランキング (List) [Toggle]
- **Tabs/Toggle**: 「Beans」と「Methods」を切り替え可能。
- **指標**: 平均スコア順 (Best Rated) / 抽出回数順 (Most Used)。

### 2.4 Advanced Analysis (統計解析)
ユーザー要望に基づき、より高度な分析機能を提供する。

#### A. Principal Component Analysis (PCA) Scatter Plot
- フレーバー6項目 (Fragrance~Flavor) を主成分分析し、2次元(PC1, PC2)に圧縮して散布図を描画。
- 目的: 「似ている豆」や「味の傾向」を視覚的にグループ化する。
- ライブラリ: `ml_linalg` 等の導入、または簡易的な行列計算を実装。

#### B. Correlation Matrix (Heatmap)
- 各評価項目間（例: 酸味 vs 甘味）の相関係数をヒートマップで表示。
- 目的: 「酸味が強いと甘味を感じにくい」などの個人の味覚傾向を発見する。
- ※ 今回はPCAを優先実装。

## 3. 技術的仕様

### 3.1 データソース
- `coffeeRecordsProvider` を監視。
- `StatisticsService` クラスを作成し、以下の計算ロジックを集約:
    - 基本KPI (Count, Avg)
    - グルーピング集計 (By Bean, By Method)
    - PCA計算ロジック (共分散行列 -> 固有値分解/特異値分解)

### 3.2 UI構成
- **Filter Section**: 期間指定 (Date Range Picker), 豆/メソッド切り替え。
- **Summary Section**: KPI Cards.
- **Charts Section**: Radar, PCA Scatter.
- **Ranking Section**: List.

### 3.3 依存関係
- `fl_chart`: グラフ描画。
- `ml_linalg` (新規追加検討): 行列演算用。

## 4. 開発ステップ
1. **データ集計ロジックの実装**: `StatisticsService` または `ViewModel` 的なクラス/メソッドを作成し、生データから統計数値を計算する。
2. **KPIカード UI実装**: 数値を表示。
3. **チャート UI実装**: `fl_chart` の組み込み。
4. **ランキング UI実装**: リスト表示。
5. **統合と検証**: `StatisticsScreen` への配置。

## 5. ユーザーレビュー事項
- 表示したい期間（全期間 or 直近？）→ Default: 全期間、選べるようにしたい
- チャートの色味やデザインの方向性（既存の茶色ベースに合わせる）
