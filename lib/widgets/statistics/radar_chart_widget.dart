import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/statistics_service.dart';
import '../../providers/data_providers.dart';
import '../../models/coffee_record.dart';

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

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Controls
            Row(
              children: [
                const Text('Compare: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: filter.comparisonTargetType,
                  hint: const Text('None'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(value: 'Bean', child: Text('Bean')),
                    DropdownMenuItem(value: 'Method', child: Text('Method')),
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
                      hint: Text('Select ${filter.comparisonTargetType}'),
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
            AspectRatio(
              aspectRatio: 1.3,
              child: RadarChart(
                RadarChartData(
                  radarTouchData: RadarTouchData(enabled: false), // Disable touch for simplicity
                  dataSets: [
                     // Dummy Data for Scale (0-10)
                     RadarDataSet(
                       fillColor: Colors.transparent,
                       borderColor: Colors.transparent,
                       entryRadius: 0,
                       dataEntries: List.filled(6, const RadarEntry(value: 10.0)),
                       borderWidth: 0,
                     ),
                     // Global Average (Always show)
                     RadarDataSet(
                       fillColor: Colors.grey.withOpacity(0.2),
                       borderColor: Colors.grey,
                       entryRadius: 2,
                       dataEntries: _mapToEntries(radarData.average),
                       borderWidth: 2,
                     ),
                     // Target (If selected)
                     if (radarData.target != null)
                       RadarDataSet(
                         fillColor: Colors.blue.withOpacity(0.4),
                         borderColor: Colors.blue,
                         entryRadius: 3,
                         dataEntries: _mapToEntries(radarData.target!),
                         borderWidth: 3,
                       ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: const TextStyle(color: Colors.brown, fontSize: 13, fontWeight: FontWeight.bold),
                  tickCount: 5, // 2, 4, 6, 8, 10
                  ticksTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  gridBorderData: BorderSide(color: Colors.brown.withOpacity(0.2), width: 1),
                  getTitle: (index, angle) {
                    const titles = ['Fragrance', 'Acidity', 'Bitterness', 'Sweetness', 'Complexity', 'Flavor'];
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
                _legendItem('Avg', Colors.grey),
                if (radarData.target != null) ...[
                  const SizedBox(width: 16),
                  _legendItem('Selected', Colors.blue),
                ]
              ],
            )
          ],
        ),
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
    // Expected order: Fragrance, Acidity, Bitterness, Sweetness, Complexity, Flavor
    const keys = ['Fragrance', 'Acidity', 'Bitterness', 'Sweetness', 'Complexity', 'Flavor'];
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
