# UI改善計画 (Cycle 10)

## Goal Description
ユーザーフィードバックに基づき、統計画面の視認性と情報の解釈しやすさを向上させる。具体的には、レーダーチャートの文字サイズ・軸表示、PCAプロットの成分表示およびツールチップ改善を行う。

## User Review Required
特になし

## Proposed Changes

### Statistics Layer
#### [MODIFY] [statistics_service.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/services/statistics_service.dart)
- `calculatePca` の戻り値を `List<PcaPoint>` から `PcaResult` クラスに変更。
- `PcaResult` は `List<PcaPoint>` と `List<PcaComponent>` (PC1, PC2の各特徴量への寄与度) を保持する。

### UI Layer
#### [MODIFY] [radar_chart_widget.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/widgets/statistics/radar_chart_widget.dart)
- `radarChartTitle` のフォントサイズを大きくし、色を `Colors.brown` 等で見やすくする。
- `ticks` のテキストスタイルを可視化し、得点（例: 2, 4, 6...）を表示する。

#### [MODIFY] [pca_scatter_plot.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/widgets/statistics/pca_scatter_plot.dart)
- `StatisticsService` からの新リターンタイプに対応。
- PC1, PC2 の軸の意味（主要な寄与要素）を表示するテキストまたは表を追加。
  - 例: "PC1: 酸味 (+0.6), 甘味 (+0.5)"
- `ScatterTouchTooltipData` を `PcaPoint` の `metadata` (`beanId`/`methodId`) を用いて、`beanMasterProvider` 等から名称を取得し表示するように変更。

### Mobile Support
- レスポンシブ対応の確認。
  - `LayoutBuilder` を活用し、画面幅が狭い場合（スマホ）はサイドバーをドロワーに変更、または `BottomNavigationBar` を検討（今回はドロワー案が有力）。
  - `RadarChart` や `PcaScatterPlot` のアスペクト比を調整。

### Master Log Integration
- **Refactoring**: `CoffeeLogListScreen` のリストアイテム部分を `widgets/coffee_log_card.dart` として抽出。
- **Detail Screens Modification**:
  - `MasterDetailScreen`: `ConsumerWidget` に変更。`coffeeRecordsProvider` を watch し、該当するマスターID (`beanId`, `methodId` 等) を持つログをフィルタリングして下部に表示。
  - `MethodDetailScreen`: 同様に `coffeeRecordsProvider` を watch し、`methodId` が一致するログを表示。

## Verification Plan
### Manual Verification
- `flutter run -d chrome` (Mobile size emulation)
    - 画面幅を縮めてレイアウトが崩れないか確認。
- `flutter run` で統計画面を確認。
    - レーダーチャートの文字が見やすいか。
    - PCAプロットで点にカーソルを合わせると豆の名前が表示されるか。
- `Master/Method List` から詳細画面へ遷移し、下部に関連ログが表示されているか確認。
    - タップして詳細ログへ遷移できるか確認。
    - PC1/PC2 の成分説明が妥当か（例: 酸味が高い豆が酸味成分の高い方向に位置しているか）。
