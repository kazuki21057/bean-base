import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/method_master.dart';
import '../providers/data_providers.dart';

class MethodDetailScreen extends ConsumerWidget {
  final MethodMaster method;

  const MethodDetailScreen({super.key, required this.method});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(pouringStepsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(method.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard('Description', method.description),
            _buildInfoCard('Author', method.author),
            _buildInfoCard('Base Bean Weight', '${method.baseBeanWeight}g'),
            _buildInfoCard('Base Water Amount', '${method.baseWaterAmount}ml'),
            _buildInfoCard('Recommended Equipment', method.recommendedEquipment),
            const SizedBox(height: 24),
            Text('Pouring Steps', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            stepsAsync.when(
              data: (allSteps) {
                final steps = allSteps.where((s) => s.methodId == method.id).toList();
                steps.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
                
                if (steps.isEmpty) {
                  return const Text('No steps defined.');
                }

                // Calculate cumulative values
                int cumulativeTime = 0;
                double cumulativeWater = 0;
                
                final rows = <DataRow>[];
                for (var s in steps) {
                  cumulativeTime += s.duration;
                  
                  double amount = 0;
                  if (s.waterRatio != null && s.waterRatio! > 0) {
                     amount = s.waterRatio! * method.baseBeanWeight;
                  } else {
                     amount = s.waterAmount;
                  }
                  cumulativeWater += amount;
                  
                  rows.add(DataRow(cells: [
                     DataCell(Text(s.stepOrder.toString())),
                     DataCell(Text(_formatTime(cumulativeTime))),
                     DataCell(Text('${cumulativeWater.toStringAsFixed(1)}ml')),
                     DataCell(Text(s.description)),
                  ]));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       DataTable(
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Time')),
                          DataColumn(label: Text('Total Water')),
                          DataColumn(label: Text('Description')),
                        ],
                        rows: rows,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Total Time: ${_formatTime(cumulativeTime)} / Total Water: ${cumulativeWater.toStringAsFixed(1)}ml',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading steps: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    if (value.isEmpty || value == '-' || value == '0.0g' || value == '0.0ml' || value == '0' || value == '0.0') return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
