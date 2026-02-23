# データ可視化改善計画 (Cycle 12)

## 目的
Stats画面のデータ可視化を改善する。
1. **Radar Chart**: スケールを0-10に固定する。
2.  **PCA Scatter Plot**: スコアを視覚的特徴（色、サイズ）に反映させる。

## 変更内容
### `lib/widgets/statistics/radar_chart_widget.dart`
- [MODIFY] `dataEntries` がすべて `10.0` のダミー `RadarDataSet`（色は透明）を追加する。
  - これにより、チャートの最大スケールが強制的に10になる。
- [MODIFY] `tickCount` を 5 に設定する（2, 4, 6, 8, 10に対応）。

### `lib/widgets/statistics/pca_scatter_plot.dart`
- [MODIFY] `build` メソッド内で、`PcaPoint.metadata` から `score` を取得する。
- [NEW] スタイル計算用のヘルパーメソッドを実装:
  - `Color _getScoreColor(double score)`: `Colors.lightBlueAccent`（低）から `Colors.red`（高, >8.0）へのグラデーション。
    - 例: `Color.lerp(Colors.lightBlueAccent, Colors.red, (score - 5) / 5)` (範囲制限付き)。
  - `double _getScoreRadius(double score)`: 4.0（低）〜 10.0（高）の間でスケール。
- [MODIFY] `ScatterSpot` コンストラクタを更新し、上記の動的な色と半径を使用する。
- [NEW] スコアの凡例またはスケールインジケータ（"Low Score -> High Score" のグラデーションバー）を追加する。

## 検証計画
1. **Radar Chart**: 外枠が10.0を表し、グリッド線が正しい間隔であることを確認。
2. **PCA Plot**: 
   - 点の色とサイズがスコアに応じて変化しているか確認。
   - 高得点の豆（例：スコア8-9）が大きく赤く表示されること。
   - 低得点の豆（例：スコア5-6）が小さく青く表示されること。
