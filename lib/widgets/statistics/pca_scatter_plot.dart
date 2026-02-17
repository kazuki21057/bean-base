import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/statistics_service.dart';
import '../../models/coffee_record.dart';
import '../../providers/data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ai_analysis_service.dart';

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
            SizedBox(
              height: 300,
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
            const SizedBox(height: 16),
            _buildAiAnalysisSection(context, ref, result.components, ref.watch(aiAnalysisLoadingProvider), ref.watch(aiAnalysisResultProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAnalysisSection(BuildContext context, WidgetRef ref, List<PcaComponent> components, bool isLoading, String? result) {
    if (isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    }

    return Column(
      children: [
        if (result != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text("AI Analysis", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(result, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _handleAiAnalysis(context, ref, components),
            icon: const Icon(Icons.psychology),
            label: Text(result == null ? "AI Analyze Components" : "Re-Analyze"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade50,
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ),
      ],
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
        // Low
        Container(width: _getScoreRadius(0)*2, height: _getScoreRadius(0)*2, decoration: BoxDecoration(color: _getScoreColor(0), shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text("Low", style: TextStyle(fontSize: 10, color: _getScoreColor(0))),
        // Bar
        Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getScoreColor(0),
                  _getScoreColor(5),
                  _getScoreColor(10),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        // High
        Text("High", style: TextStyle(fontSize: 10, color: _getScoreColor(10))),
        const SizedBox(width: 4),
        Container(width: _getScoreRadius(10)*2, height: _getScoreRadius(10)*2, decoration: BoxDecoration(color: _getScoreColor(10), shape: BoxShape.circle)),
      ],
    );
  }

  Future<void> _handleAiAnalysis(BuildContext context, WidgetRef ref, List<PcaComponent> components) async {
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('gemini_api_key');

    if (apiKey == null || apiKey.isEmpty) {
      if (context.mounted) {
        apiKey = await _showApiKeyDialog(context);
        if (apiKey != null && apiKey.isNotEmpty) {
          await prefs.setString('gemini_api_key', apiKey);
        } else {
          return; // Cancelled
        }
      }
    }

    if (apiKey == null || apiKey.isEmpty) return;

    // Start Analysis
    ref.read(aiAnalysisLoadingProvider.notifier).state = true;
    try {
      final result = await ref.read(aiAnalysisServiceProvider).analyzeComponents(components, apiKey);
      ref.read(aiAnalysisResultProvider.notifier).state = result;
    } catch (e) {
      ref.read(aiAnalysisResultProvider.notifier).state = "Error: $e";
    } finally {
      ref.read(aiAnalysisLoadingProvider.notifier).state = false;
    }
  }

  Future<String?> _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Gemini API Key"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "API Key",
            hintText: "Enter your Google Gemini API Key",
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
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
