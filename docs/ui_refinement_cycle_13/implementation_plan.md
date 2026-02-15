# チャート改善とAI連携計画 (Cycle 13)

## 目的
Stats画面のチャート表現をより明確にし、主成分分析(PCA)にAIによる解釈機能を追加する。

## 変更内容
### `lib/widgets/statistics/radar_chart_widget.dart`
- [MODIFY] **Scoreを頂点（12時方向）に**:
  - タイトルとデータエントリの順序を変更する: `['Score', 'Fragrance', ...]`。
- [MODIFY] **数値描画 (2, 4, 6, 8, 10)**:
  - `ticksTextStyle` の色を濃く、サイズを調整して視認性を高める。
  - `tickCount` が適切か再確認する。

### `lib/widgets/statistics/pca_scatter_plot.dart`
- [MODIFY] **凡例レイアウト**:
  - サイズ凡例: `小丸` `Text("Low")` ... `Text("High")` `大丸` の順に配置し、大小の意味を明確化。
- [NEW] **Gemini連携**:
  - 「AI分析」ボタンを追加（**自動実行はしない**）。
  - ボタンを押した時のみ `AiAnalysisService.analyzeComponents(components)` を呼び出し、結果をダイアログ表示。
  - 結果は一時的にキャッシュ（状態保持）し、同じ画面を開いている間は再通信しないようにする。
  - ※APIキー未設定時は設定画面へ誘導。

### `lib/services/ai_analysis_service.dart` (新規)
- [FIX] **Gemini Model Name**:
  - エラー回避のため、モデル名を `gemini-1.5-flash` から `gemini-pro` に変更する。
- [NEW] Google Gemini API と連携するサービスの作成。
  - 依存: `google_generative_ai` パッケージ。
  - メソッド: `Future<String> analyzeComponents(List<PcaComponent> components)`
  - ロジック:
    - プロンプト構築: 「コーヒーフレーバーデータの主成分(PC1, PC2)の構成比は以下の通り... PC1は酸味と苦味に相関があり... これらが表す意味を1-2文で解説して」
    - API呼び出し結果を返す。

## アプリケーションロジック
- **APIキー管理**:
  - 簡易的に `shared_preferences` に保存。
  - `StatisticsScreen` に設定アイコンを追加し、入力用ダイアログを実装。

## 検証
- レーダーチャートが7軸（Score含む）であること。
- 各軸の目盛りが確認できる（または明確な代替表示がある）こと。
- PCA凡例が修正されていること。
- Gemini分析が動作すること（キーがある場合）。
