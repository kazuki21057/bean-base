import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/coffee_record.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/ai_analysis_service.dart';
import '../../services/statistics_service.dart';

/// F2拡張: PCA全成分の詳細パネル (設計書§6.2、T4-3b)。
/// 既存の `pca_scatter_plot.dart`(PC1/PC2散布図+簡易AI分析)の下に追加する。
///
/// 設計書§6.2の3項目:
///   1. 寄与率バー: PC1〜PC6の寄与率・累積寄与率+Kaiser基準線(固有値1⇔1/m)
///   2. 負荷量テーブル: 6軸×PC1/PC2、|L|≥0.5を強調表示
///   3. 「AIで深掘り解釈」ボタン(§8.2 `analyzeComponentsDeep`)
///
/// 数値計算(相関行列化・固有値分解)は`StatisticsService.calculatePca()`に
/// 委譲済み(T4-3a)。本ウィジェットは表示とAI呼び出し用の要約生成のみ担う。
class PcaDetailPanel extends ConsumerWidget {
  final List<CoffeeRecord> records;
  const PcaDetailPanel({super.key, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(statisticsServiceProvider);
    final result = service.calculatePca(records);

    // pca_scatter_plot.dart側で案内文を表示済みのため、ここでは何も出さない。
    if (result.components.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(color: kLatte),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'v1.1: 分析方法を相関行列ベースに改善しました',
            style: TextStyle(fontSize: 11, color: kMocha, fontStyle: FontStyle.italic),
          ),
        ),
        if (result.excludedFeatures.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '除外された軸(全件同値のため計算不可): ${result.excludedFeatures.join('、')}',
              style: const TextStyle(fontSize: 11, color: kMocha),
            ),
          ),
        const Text('寄与率', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kEspresso)),
        const SizedBox(height: 8),
        _contributionBars(result.components),
        const SizedBox(height: 20),
        const Text(
          '負荷量 (PC1/PC2、|L|≥0.5を強調)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kEspresso),
        ),
        const SizedBox(height: 8),
        _loadingsTable(result.components),
        const SizedBox(height: 20),
        _PcaDeepAiSection(records: records, result: result),
      ],
    );
  }

  // --- 1. 寄与率バー ---

  Widget _contributionBars(List<PcaComponent> components) {
    final kaiserRatio = (1 / components.length).clamp(0.0, 1.0);
    return Column(
      children: components.map((c) {
        final ratio = c.contributionRatio.clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(c.name, style: const TextStyle(fontSize: 11, color: kEspresso)),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: kLatte.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    // Kaiser基準線 (固有値1 ⇔ 寄与率1/m)
                    FractionallySizedBox(
                      widthFactor: kaiserRatio,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(width: 1.5, height: 14, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: Text(
                  '${(c.contributionRatio * 100).toStringAsFixed(1)}% (累積${(c.cumulativeRatio * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 10, color: kMocha),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 2. 負荷量テーブル ---

  Widget _loadingsTable(List<PcaComponent> components) {
    final pc1 = components[0];
    final pc2 = components[1];
    final axes = pc1.contributions.keys.toList();

    return Table(
      border: TableBorder.all(color: kLatte, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(children: [
          _cell('変数', bold: true),
          _cell('PC1', bold: true),
          _cell('PC2', bold: true),
        ]),
        ...axes.map((axis) {
          final l1 = pc1.contributions[axis] ?? 0.0;
          final l2 = pc2.contributions[axis] ?? 0.0;
          return TableRow(children: [
            _cell(axis),
            _cell(l1.toStringAsFixed(2), highlight: l1.abs() >= 0.5),
            _cell(l2.toStringAsFixed(2), highlight: l2.abs() >= 0.5),
          ]);
        }),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold || highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? kAccent : kEspresso,
          ),
        ),
      );
}

/// PC1スコア上位/下位5件の産地/焙煎度/湯温を要約する (設計書§8.2の`topPc1Summary`実体)。
/// [records]と[result.points]は`calculatePca`内で同一順序で構築されるためindexで対応させる。
String _summarizePc1Extremes(List<CoffeeRecord> records, List<PcaPoint> points, {required bool top}) {
  final indices = List<int>.generate(records.length, (i) => i)
    ..sort((a, b) =>
        top ? points[b].x.compareTo(points[a].x) : points[a].x.compareTo(points[b].x));

  return indices.take(5).map((i) {
    final r = records[i];
    final origin = r.origin.isEmpty ? '不明' : r.origin;
    final roast = r.roastLevel.isEmpty ? '不明' : r.roastLevel;
    return '$origin/$roast/${r.temperature.toStringAsFixed(0)}℃';
  }).join('、');
}

/// 設計書§6.2項目3: PCA深掘り解釈(T4-3b)。§8.2の`analyzeComponentsDeep`で
/// Geminiを呼ぶ。既存回帰セクションのAI解釈(`_RegressionAiSection`)と同じ操作感。
class _PcaDeepAiSection extends ConsumerStatefulWidget {
  final List<CoffeeRecord> records;
  final PcaResult result;
  const _PcaDeepAiSection({required this.records, required this.result});

  @override
  ConsumerState<_PcaDeepAiSection> createState() => _PcaDeepAiSectionState();
}

class _PcaDeepAiSectionState extends ConsumerState<_PcaDeepAiSection> {
  bool _loading = false;
  String? _result;

  Future<void> _run() async {
    final prefs = await SharedPreferences.getInstance();
    var apiKey = prefs.getString('gemini_api_key');
    if ((apiKey == null || apiKey.isEmpty) && mounted) {
      apiKey = await _askApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        await prefs.setString('gemini_api_key', apiKey);
      }
    }
    if (apiKey == null || apiKey.isEmpty) return;

    setState(() => _loading = true);
    try {
      final pc1 = widget.result.components[0];
      final pc2 = widget.result.components[1];
      final topSummary = _summarizePc1Extremes(widget.records, widget.result.points, top: true);
      final bottomSummary = _summarizePc1Extremes(widget.records, widget.result.points, top: false);
      debugPrint('[Antigravity] Action: PCA深掘り解釈を要求');
      final text = await ref.read(aiAnalysisServiceProvider).analyzeComponentsDeep(
            pc1: pc1,
            pc2: pc2,
            topPc1Summary: topSummary,
            bottomPc1Summary: bottomSummary,
            apiKey: apiKey,
          );
      if (mounted) setState(() => _result = text);
    } catch (e) {
      debugPrint('[Antigravity] Error: analyzeComponentsDeep 失敗: $e');
      if (mounted) setState(() => _result = 'エラー: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askApiKey() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini APIキーを入力'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'APIキー',
            hintText: 'Google Gemini のAPIキー',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('保存')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_result != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    Text('AI深掘り解釈',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_result!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        Center(
          child: ElevatedButton.icon(
            onPressed: _run,
            icon: const Icon(Icons.psychology),
            label: Text(_result == null ? 'AIで深掘り解釈する' : '再解釈する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade50,
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ),
      ],
    );
  }
}
