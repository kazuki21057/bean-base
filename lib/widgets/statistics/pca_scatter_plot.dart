import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/statistics_service.dart';
import '../../models/coffee_record.dart';

class PcaScatterPlot extends ConsumerWidget {
  final List<CoffeeRecord> records;

  const PcaScatterPlot({super.key, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(statisticsServiceProvider);
    final points = service.calculatePca(records);

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

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ScatterChart(
          ScatterChartData(
            scatterSpots: points.map((p) => ScatterSpot(
              p.x, 
              p.y,
              dotPainter: FlDotCirclePainter(
                radius: 6,
                color: Colors.brown.withOpacity(0.7),
                strokeWidth: 1,
                strokeColor: Colors.black,
              ),
            )).toList(),
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
            titlesData: FlTitlesData(show: false), // Hide axis for PCA
            scatterTouchData: ScatterTouchData(
              enabled: true,
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipItems: (ScatterSpot spot) {
                  // Find point by x/y (roughly)
                  final p = points.firstWhere((pt) => (pt.x - spot.x).abs() < 0.001 && (pt.y - spot.y).abs() < 0.001, orElse: () => points.first);
                  return ScatterTooltipItem(
                    '${p.label}\nExtracts: ${p.metadata['count']}',
                    textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    bottomMargin: 10,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
