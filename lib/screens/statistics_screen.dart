import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../services/statistics_service.dart';
import '../widgets/statistics/statistics_filter_widget.dart';
import '../widgets/statistics/kpi_cards.dart';
import '../widgets/statistics/radar_chart_widget.dart';
import '../widgets/statistics/pca_scatter_plot.dart';
import '../widgets/statistics/ranking_list.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(coffeeRecordsProvider);
    final filter = ref.watch(statisticsFilterProvider);
    final service = ref.watch(statisticsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(coffeeRecordsProvider),
          ),
        ],
      ),
      body: asyncRecords.when(
        data: (records) {
          // 1. Filter Records
          final filteredRecords = service.filterRecords(records, filter);
          
          // 2. Calculate KPI
          final kpi = service.calculateKPI(filteredRecords);

          if (filteredRecords.isEmpty) {
            return Column(
              children: [
                StatisticsFilterWidget(filter: filter),
                const Expanded(child: Center(child: Text("No records found for the selected period."))),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter
                StatisticsFilterWidget(filter: filter),
                const SizedBox(height: 16),

                // KPI
                KpiCards(kpi: kpi),
                const SizedBox(height: 24),

                // Radar Chart
                Text('Flavor Profile', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                RadarChartWidget(
                  filteredRecords: filteredRecords,
                  allRecords: records, // For global average comparison
                  filter: filter,
                ),
                const SizedBox(height: 24),

                // PCA Scatter
                Text('Flavor Analysis (PCA)', style: Theme.of(context).textTheme.titleLarge),
                const Text('Visualizing flavor similarity (2D Projection)', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: PcaScatterPlot(records: filteredRecords),
                ),
                const SizedBox(height: 24),

                // Ranking
                Text('Rankings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                RankingList(records: filteredRecords),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
