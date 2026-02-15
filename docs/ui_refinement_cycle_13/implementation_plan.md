# チャート改善とAI連携計画 (Cycle 13)

## 目的
Stats画面のチャート表現をより明確にし、主成分分析(PCA)にAIによる解釈機能を追加する。

## 変更内容
### `lib/widgets/statistics/radar_chart_widget.dart`
- [MODIFY] **'Score' 軸の追加**:
  - `StatisticsService.calculateRadarData` で `scoreOverall` の計算を追加。
  - タイトルリストとデータマップに「Score」を追加。
- [MODIFY] **全軸への数値表示**:
  - `fl_chart` の RadarChart は通常1軸にのみ目盛りを表示する仕様。
  - **対応策**:
    - **軸タイトルへの数値付記**: 例「Fragrance (0-10)」や、最大値「(10)」をタイトルに含めることで、直感的なスケールを示す。
    - **独自描画の検討**: `ScatterChart` 等を重ねて描画する方法は複雑性が高いため、まずは「グリッド線の意味（2点刻み）」を明確にする凡例や説明を追加する方向で検討。
    - ※ユーザー要望の「デバッグ強化」として、ライブラリのプロパティ(`ticksTextStyle`等)が他の軸にも適用可能か詳細調査を行う。

### `lib/widgets/statistics/pca_scatter_plot.dart`
- [MODIFY] **凡例レイアウト**:
  - サイズ凡例: `小丸` `Text("Low")` ... `Text("High")` `大丸` の順に配置し、大小の意味を明確化。
- [NEW] **Gemini連携**:
  - 「AI分析」ボタンを追加（**自動実行はしない**）。
  - ボタンを押した時のみ `AiAnalysisService.analyzeComponents(components)` を呼び出し、結果をダイアログ表示。
  - 結果は一時的にキャッシュ（状態保持）し、同じ画面を開いている間は再通信しないようにする。
  - ※APIキー未設定時は設定画面へ誘導。

### `lib/services/ai_analysis_service.dart` (新規)
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
