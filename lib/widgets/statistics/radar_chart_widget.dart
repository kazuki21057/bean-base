import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/statistics_service.dart';
import '../../providers/data_providers.dart';
import '../../models/coffee_record.dart';
import '../../screens/create/create_form_widgets.dart';

/// Cycle 20 T2-6: 見た目をPhase2共通パレット(コーヒートーン)・日本語ラベルへ
/// 統一。レーダーチャートの集計ロジック自体は変更なし。
class RadarChartWidget extends ConsumerWidget {
  final List<CoffeeRecord> filteredRecords;
  final List<CoffeeRecord> allRecords;
  final StatisticsFilter filter;

  const RadarChartWidget({
    super.key,
    required this.filteredRecords,
    required this.allRecords,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(statisticsServiceProvider);
    final radarData = service.calculateRadarData(allRecords, filter);
    
    final beanMaster = ref.watch(beanMasterProvider);
    final methodMaster = ref.watch(methodMasterProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Controls
          Row(
            children: [
              const Text('比較対象:', style: TextStyle(fontSize: 13, color: kMocha)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: filter.comparisonTargetType,
                hint: const Text('なし'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('なし')),
                  DropdownMenuItem(value: 'Bean', child: Text('豆')),
                  DropdownMenuItem(value: 'Method', child: Text('メソッド')),
                ],
                onChanged: (val) {
                  ref.read(statisticsFilterProvider.notifier).state =
                      filter.copyWith(comparisonTargetType: val, comparisonTargetId: null); // Reset ID
                },
              ),
              const SizedBox(width: 16),
              if (filter.comparisonTargetType != null)
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: filter.comparisonTargetId,
                    hint: Text(filter.comparisonTargetType == 'Bean' ? '豆を選択' : 'メソッドを選択'),
                    items: _buildDropdownItems(filter.comparisonTargetType!, beanMaster, methodMaster),
                    onChanged: (val) {
                       ref.read(statisticsFilterProvider.notifier).state =
                          filter.copyWith(comparisonTargetId: val);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          const Text('目盛り: 0〜10 (2刻み)', style: TextStyle(fontSize: 10, color: kMocha)),
          const SizedBox(height: 4),
            AspectRatio(
              aspectRatio: 1.3,
              child: RadarChart(
                RadarChartData(
                  radarTouchData: RadarTouchData(enabled: false), // Disable touch for simplicity
                   dataSets: [
                     // Dummy Data for Scale Min (0) - Force visual minimum
                     RadarDataSet(
                       fillColor: Colors.transparent,
                       borderColor: Colors.transparent,
                       entryRadius: 0,
                       dataEntries: List.filled(7, const RadarEntry(value: 0.0)),
                       borderWidth: 0,
                     ),
                     // Dummy Data for Scale Max (10)
                     RadarDataSet(
                       fillColor: Colors.transparent,
                       borderColor: Colors.transparent,
                       entryRadius: 0,
                       dataEntries: List.filled(7, const RadarEntry(value: 10.0)),
                       borderWidth: 0,
                     ),
                     // Global Average (Always show)
                     RadarDataSet(
                       fillColor: kLatte.withValues(alpha: 0.3),
                       borderColor: kMocha,
                       entryRadius: 2,
                       dataEntries: _mapToEntries(radarData.average),
                       borderWidth: 2,
                     ),
                     // Target (If selected)
                     if (radarData.target != null)
                       RadarDataSet(
                         fillColor: kAccent.withValues(alpha: 0.4),
                         borderColor: kAccent,
                         entryRadius: 3,
                         dataEntries: _mapToEntries(radarData.target!),
                         borderWidth: 3,
                       ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: const TextStyle(color: kEspresso, fontSize: 13, fontWeight: FontWeight.bold),
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(color: kMocha, fontSize: 10), // Visible ticks
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  gridBorderData: BorderSide(color: kLatte, width: 1),
                  getTitle: (index, angle) {
                    const titles = ['総合', '香り', '酸味', '苦味', '甘み', '複雑さ', '風味'];
                    if (index < titles.length) {
                       return RadarChartTitle(text: titles[index], angle: angle);
                    }
                    return const RadarChartTitle(text: '');
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('平均', kMocha),
              if (radarData.target != null) ...[
                const SizedBox(width: 16),
                _legendItem('選択中', kAccent),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<RadarEntry> _mapToEntries(Map<String, double> data) {
    // Expected order: Score (Top/12 o'clock), Fragrance, Acidity, Bitterness, Sweetness, Complexity, Flavor
    const keys = ['Score', 'Fragrance', 'Acidity', 'Bitterness', 'Sweetness', 'Complexity', 'Flavor'];
    return keys.map((k) => RadarEntry(value: data[k] ?? 0)).toList();
  }

  List<DropdownMenuItem<String>>? _buildDropdownItems(
    String type, 
    AsyncValue<List<dynamic>> beans, 
    AsyncValue<List<dynamic>> methods
  ) {
    if (type == 'Bean' && beans.hasValue) {
       return beans.value!.map((b) => DropdownMenuItem(value: b.id.toString(), child: Text(b.name, overflow: TextOverflow.ellipsis))).toList();
    } else if (type == 'Method' && methods.hasValue) {
       return methods.value!.map((m) => DropdownMenuItem(value: m.id.toString(), child: Text(m.name, overflow: TextOverflow.ellipsis))).toList();
    }
    return [];
  }
}
