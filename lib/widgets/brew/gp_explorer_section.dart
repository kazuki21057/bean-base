import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coffee_record.dart';
import '../../models/origin_master.dart';
import '../../providers/data_providers.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/gp_service.dart';
import '../../services/math/encoding.dart';

/// F4: レシピ探索セクション (設計書§7.5、T4-6b)。抽出画面(030)に配置する。
///
/// 産地×焙煎度を選ぶと、その属性の GP モデル(§7.5)を全記録から重み付き学習し、
/// 湯温×比率の予測スコアヒートマップ(粗グリッド 4×5、時間はグリッド上の μ 最大値で
/// 固定)を表示する。数値計算(fit/predict/optimize)はすべて`GpService`に委譲し、
/// 本ウィジェットは表示のみを担う(CLAUDE.md絶対規則: 計算はDartローカル)。
///
/// ヒートマップは fl_chart に該当チャートが無いため、設計書§7.5の指示どおり
/// `Table` + 色付き `Container` で実装する(湯温4値×比率5値の粗グリッド)。
class GpExplorerSection extends ConsumerStatefulWidget {
  const GpExplorerSection({super.key});

  @override
  ConsumerState<GpExplorerSection> createState() => _GpExplorerSectionState();
}

class _GpExplorerSectionState extends ConsumerState<GpExplorerSection> {
  String? _selectedOriginId;
  String _selectedRoast = '中煎り';

  /// 粗グリッド (設計書§7.5「5℃×1.0比率の粗グリッド 4×5」)。
  static const _gridTemps = <double>[80, 85, 90, 95];
  static const _gridRatios = <double>[14, 15, 16, 17, 18];

  /// 焙煎度の代表5水準 (encoding.dart の roastOrdinalMap の各順序値に対応)。
  static const _roastOptions = <(String, double)>[
    ('浅煎り', 1.0),
    ('中浅煎り', 2.0),
    ('中煎り', 3.0),
    ('中深煎り', 4.0),
    ('深煎り', 5.0),
  ];

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(coffeeRecordsProvider);
    final originsAsync = ref.watch(originMasterProvider);

    return FormSection(
      icon: Icons.insights_outlined,
      title: 'レシピ探索 (実験的)',
      children: [
        const Text(
          '産地と焙煎度を選ぶと、過去の記録から予測される総合評価を湯温×比率のマップで表示します。',
          style: TextStyle(fontSize: 12, color: kMocha),
        ),
        const SizedBox(height: 12),
        if (recordsAsync.isLoading || originsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recordsAsync.hasError || originsAsync.hasError)
          Text(
            'データの読み込みエラー: ${recordsAsync.error ?? originsAsync.error}',
            style: const TextStyle(color: kMocha, fontSize: 12),
          )
        else
          _buildContent(
            recordsAsync.value ?? const <CoffeeRecord>[],
            originsAsync.value ?? const <OriginMaster>[],
          ),
      ],
    );
  }

  Widget _buildContent(List<CoffeeRecord> records, List<OriginMaster> origins) {
    final originById = {for (final o in origins) o.id: o};
    // 記録が実際に存在する産地に絞る(選んでも計算できない産地を減らす)。
    final usedOriginIds = records.map((r) => r.originId).where((id) => id.isNotEmpty).toSet();
    final selectableOrigins = origins.where((o) => usedOriginIds.contains(o.id)).toList()
      ..sort((a, b) => a.nameJa.compareTo(b.nameJa));

    if (selectableOrigins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '産地が紐付いた抽出記録がまだありません(記録に産地を登録すると探索できます)。',
          style: TextStyle(fontSize: 12, color: kMocha),
        ),
      );
    }

    _selectedOriginId ??= selectableOrigins.first.id;
    final roastOrdinal = roastOrdinalMap[_selectedRoast] ?? 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedOriginId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '産地', border: OutlineInputBorder()),
                items: [
                  for (final o in selectableOrigins)
                    DropdownMenuItem(value: o.id, child: Text(o.nameJa, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _selectedOriginId = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRoast,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '焙煎度', border: OutlineInputBorder()),
                items: [
                  for (final r in _roastOptions)
                    DropdownMenuItem(value: r.$1, child: Text(r.$1)),
                ],
                onChanged: (v) => setState(() => _selectedRoast = v ?? '中煎り'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildHeatmap(records, originById, _selectedOriginId!, roastOrdinal),
      ],
    );
  }

  Widget _buildHeatmap(
    List<CoffeeRecord> records,
    Map<String, OriginMaster> originById,
    String originId,
    double roastOrdinal,
  ) {
    final service = GpService();
    final model = service.fit(records, originId, roastOrdinal, originById);
    if (model == null) {
      // 設計書§1.3 F4 の最小データ条件(n_eff < 10)を満たさない場合の固定案内。
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'この属性の推薦にはデータが不足しています(この産地×焙煎度に近い記録が10件相当に達していません)。',
          style: TextStyle(fontSize: 12, color: kMocha),
        ),
      );
    }

    final opt = service.optimize(model);
    final fixedTime = opt.bestX.s; // 時間はグリッド上の μ 最大値で固定(設計書§7.5)。

    // 粗グリッドの μ を全点計算し、色スケール用の min/max を求める。
    final grid = <List<double>>[];
    var muMin = double.infinity;
    var muMax = double.negativeInfinity;
    for (final t in _gridTemps) {
      final row = <double>[];
      for (final r in _gridRatios) {
        final mu = service.predict(model, t, r, fixedTime).mean;
        row.add(mu);
        muMin = math.min(muMin, mu);
        muMax = math.max(muMax, mu);
      }
      grid.add(row);
    }

    // 粗グリッド上の μ 最大セル(強調表示用)。
    var bestI = 0, bestJ = 0;
    for (var i = 0; i < grid.length; i++) {
      for (var j = 0; j < grid[i].length; j++) {
        if (grid[i][j] > grid[bestI][bestJ]) {
          bestI = i;
          bestJ = j;
        }
      }
    }

    // 推薦点(細グリッドの μ 最大)の予測スコア+95%予測区間(設計書§2.5:
    // √(sd²+σ_n²) を使い潜在関数の不確実性に観測ノイズを足す)。
    final best = opt.best;
    final totalSd = math.sqrt(best.sd * best.sd + model.sigmaN * model.sigmaN);
    final lower = (best.mean - 1.96 * totalSd).clamp(0.0, 10.0);
    final upper = (best.mean + 1.96 * totalSd).clamp(0.0, 10.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '予測総合評価マップ (時間 ${_formatTime(fixedTime)} 固定)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso),
        ),
        const SizedBox(height: 8),
        _heatmapTable(grid, muMin, muMax, bestI, bestJ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kAccent.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('おすすめの条件', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso)),
              const SizedBox(height: 6),
              Text(
                '湯温 ${opt.bestX.t.toStringAsFixed(0)}℃ / 湯:豆 1:${opt.bestX.r.toStringAsFixed(1)} / 時間 ${_formatTime(opt.bestX.s)}',
                style: const TextStyle(fontSize: 13, color: kEspresso),
              ),
              const SizedBox(height: 4),
              Text(
                '予測スコア ${best.mean.toStringAsFixed(1)} [${lower.toStringAsFixed(1)}, ${upper.toStringAsFixed(1)}] (95%予測区間)',
                style: const TextStyle(fontSize: 12, color: kMocha),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heatmapTable(List<List<double>> grid, double muMin, double muMax, int bestI, int bestJ) {
    final range = (muMax - muMin).abs() < 1e-9 ? 1.0 : (muMax - muMin);
    return Table(
      defaultColumnWidth: const FlexColumnWidth(1),
      children: [
        // ヘッダ行: 左上ラベル + 比率ラベル。
        TableRow(
          children: [
            _labelCell('湯温\\比率', bold: true),
            for (final r in _gridRatios) _labelCell('1:${r.toStringAsFixed(0)}', bold: true),
          ],
        ),
        for (var i = 0; i < _gridTemps.length; i++)
          TableRow(
            children: [
              _labelCell('${_gridTemps[i].toStringAsFixed(0)}℃', bold: true),
              for (var j = 0; j < _gridRatios.length; j++)
                _valueCell(grid[i][j], (grid[i][j] - muMin) / range, highlighted: i == bestI && j == bestJ),
            ],
          ),
      ],
    );
  }

  Widget _labelCell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: kEspresso,
          ),
        ),
      );

  Widget _valueCell(double mu, double t, {bool highlighted = false}) {
    final bg = Color.lerp(kCream, kAccent, t.clamp(0.0, 1.0)) ?? kCream;
    final textColor = t > 0.55 ? Colors.white : kEspresso;
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: highlighted ? Border.all(color: kEspresso, width: 2) : null,
      ),
      child: Text(
        mu.toStringAsFixed(1),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: textColor, fontWeight: highlighted ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
