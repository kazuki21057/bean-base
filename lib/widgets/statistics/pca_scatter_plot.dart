import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/statistics_service.dart';
import '../../models/coffee_record.dart';
import '../../providers/data_providers.dart';

class PcaScatterPlot extends ConsumerWidget {
  final List<CoffeeRecord> records;

  const PcaScatterPlot({super.key, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(statisticsServiceProvider);
    final result = service.calculatePca(records);
    final points = result.points;

    if (points.isEmpty) {
      return const Center(child: Text("Not enough data for PCA (need at least 3 distinct beans)."));
    }

    // Determine bounds
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (var p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    // Add padding
    final rangeX = (maxX - minX).abs();
    final rangeY = (maxY - minY).abs();
    final paddingX = rangeX * 0.1 + 0.1;
    final paddingY = rangeY * 0.1 + 0.1;
    
    final beanMaster = ref.watch(beanMasterProvider);
    final Map<String, String> beanNames = {};
    if (beanMaster.hasValue) {
      for (var b in beanMaster.value!) {
        beanNames[b.id] = b.name;
      }
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: points.map((p) {
                    final score = (p.metadata['score'] as num?)?.toDouble() ?? 5.0;
                    return ScatterSpot(
                      p.x, 
                      p.y,
                      dotPainter: FlDotCirclePainter(
                        radius: _getScoreRadius(score),
                        color: _getScoreColor(score).withOpacity(0.8),
                        strokeWidth: 1,
                        strokeColor: Colors.black45,
                      ),
                    );
                  }).toList(),
                  minX: minX - paddingX,
                  maxX: maxX + paddingX,
                  minY: minY - paddingY,
                  maxY: maxY + paddingY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.5))),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => const SizedBox.shrink(), reservedSize: 20), axisNameWidget: const Text("PC1", style: TextStyle(fontSize: 10))),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => const SizedBox.shrink(), reservedSize: 20), axisNameWidget: const Text("PC2", style: TextStyle(fontSize: 10))),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ), 
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipItems: (ScatterSpot spot) {
                        // Find point by x/y (roughly)
                        final p = points.firstWhere((pt) => (pt.x - spot.x).abs() < 0.001 && (pt.y - spot.y).abs() < 0.001, orElse: () => points.first);
                        final beanName = beanNames[p.label] ?? p.label;
                        final score = (p.metadata['score'] as num?)?.toDouble() ?? 5.0;
                        return ScatterTooltipItem(
                          '$beanName\nScore: $score',
                          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          bottomMargin: 10,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildScoreLegend(),
            const Divider(),
            _buildComponentInfo(result.components),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    // 0-10 map to Blue -> Red
    // Center at 5 (Grey/Purple?) or just linear Lerp
    // Let's use blue for low, red for high
    if (score < 0) score = 0;
    if (score > 10) score = 10;
    return Color.lerp(Colors.lightBlueAccent, Colors.redAccent, score / 10.0)!;
  }

  double _getScoreRadius(double score) {
     if (score < 0) score = 0;
     if (score > 10) score = 10;
     // Map 0-10 to 4-10
     return 4.0 + (score / 10.0) * 6.0; 
  }

  Widget _buildScoreLegend() {
    return Row(
      children: [
        const Text("Score:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 8),
        Text("Low", style: TextStyle(fontSize: 10, color: _getScoreColor(0))),
        Expanded(
          child: Container(
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getScoreColor(0),
                  _getScoreColor(5),
                  _getScoreColor(10),
                ],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Text("High", style: TextStyle(fontSize: 10, color: _getScoreColor(10))),
        const SizedBox(width: 8),
        // Size Reference
        Container(width: _getScoreRadius(2)*2, height: _getScoreRadius(2)*2, decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
        const SizedBox(width: 2),
        Container(width: _getScoreRadius(10)*2, height: _getScoreRadius(10)*2, decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
      ],
    );
  }

  Widget _buildComponentInfo(List<PcaComponent> components) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: components.map((c) {
        // Sort contributions by absolute value
        final sortedEntries = c.contributions.entries.toList()
          ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
        
        // Take top 3
        final top3 = sortedEntries.take(3).map((e) => '${e.key}(${e.value.toStringAsFixed(1)})').join(', ');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text('${c.name}: $top3', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        );
      }).toList(),
    );
  }
}
