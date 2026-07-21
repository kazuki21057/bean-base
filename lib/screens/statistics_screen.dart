import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/statistics_service.dart';
import '../widgets/statistics/statistics_filter_widget.dart';
import '../widgets/statistics/kpi_cards.dart';
import '../widgets/statistics/radar_chart_widget.dart';
import '../widgets/statistics/pca_scatter_plot.dart';
import '../widgets/statistics/ranking_list.dart';
import '../widgets/statistics/regression_section.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';

/// 040 スタッツ(統計情報)画面。
///
/// フィルター・KPI・レーダーチャート・PCA散布図・ランキングの実データ接続
/// ロジック自体は以前から動作していた(グラフ計算は`StatisticsService`に
/// 分離済み)。
/// Cycle 20 T2-6: 見た目をPhase2共通ウィジェット(MockScreenScaffold/
/// FormSection)に統一し、各サブウィジェットのラベル・配色を日本語・
/// コーヒートーンパレットへ置き換えた。グラフの計算ロジック(PCA/レーダー/
/// KPI集計)自体は変更していない。
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(coffeeRecordsProvider);
    final filter = ref.watch(statisticsFilterProvider);
    final service = ref.watch(statisticsServiceProvider);

    return MockScreenScaffold(
      screen: AppScreen.statistics,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '更新',
          onPressed: () => ref.refresh(coffeeRecordsProvider),
        ),
      ],
      children: [
        asyncRecords.when(
          data: (records) {
            final filteredRecords = service.filterRecords(records, filter);
            final kpi = service.calculateKPI(filteredRecords);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatisticsFilterWidget(filter: filter),
                const SizedBox(height: 16),
                if (filteredRecords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('選択した期間の抽出履歴がありません', style: TextStyle(color: kMocha)),
                    ),
                  )
                else ...[
                  KpiCards(kpi: kpi),
                  const SizedBox(height: 8),
                  FormSection(
                    icon: Icons.radar_outlined,
                    title: '味プロファイル',
                    children: [
                      RadarChartWidget(
                        filteredRecords: filteredRecords,
                        allRecords: records,
                        filter: filter,
                      ),
                    ],
                  ),
                  FormSection(
                    icon: Icons.scatter_plot_outlined,
                    title: '味の傾向マップ (PCA)',
                    children: [
                      const Text(
                        '抽出記録の味の近さを2次元に可視化します',
                        style: TextStyle(fontSize: 12, color: kMocha),
                      ),
                      const SizedBox(height: 8),
                      PcaScatterPlot(records: filteredRecords),
                    ],
                  ),
                  FormSection(
                    icon: Icons.emoji_events_outlined,
                    title: 'ランキング',
                    children: [
                      RankingList(records: filteredRecords),
                    ],
                  ),
                  FormSection(
                    icon: Icons.insights_outlined,
                    title: '回帰分析: 何が総合評価を動かすか',
                    children: [
                      RegressionSection(records: filteredRecords),
                    ],
                  ),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('読み込みエラー: $err')),
          ),
        ),
      ],
    );
  }
}
