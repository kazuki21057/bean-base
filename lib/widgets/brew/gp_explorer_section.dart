import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bean_master.dart';
import '../../models/coffee_record.dart';
import '../../models/equipment_masters.dart';
import '../../models/method_master.dart';
import '../../providers/data_providers.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../screens/stats_theory_screen.dart';
import '../../services/gp_service.dart';
import '../../services/math/encoding.dart';
import 'gp_heatmap.dart';

/// F4: レシピ探索セクション (設計書§7.5、T3-52で4次元化+メソッド別GP)。
/// 抽出画面(030)に配置する。
///
/// 豆(→産地・焙煎度)とミルを選ぶと、メソッドごとに別々のGPをフィットし、
/// 予測スコア降順でランキング表示する(gp_multidim_design.md §4・§6)。
/// 数値計算(fit/predict/optimize)はすべて`GpService`に委譲し、本ウィジェットは
/// 表示のみを担う(CLAUDE.md絶対規則: 計算はDartローカル)。
class GpExplorerSection extends ConsumerStatefulWidget {
  const GpExplorerSection({super.key});

  @override
  ConsumerState<GpExplorerSection> createState() => _GpExplorerSectionState();
}

class _MethodRanking {
  final MethodMaster method;
  final GpModel model;
  final GpPrediction coarseBest;
  final GpPoint coarseBestX;

  _MethodRanking({
    required this.method,
    required this.model,
    required this.coarseBest,
    required this.coarseBestX,
  });
}

class _GpExplorerSectionState extends ConsumerState<GpExplorerSection> {
  String? _selectedBeanId;
  String? _selectedGrinderId;
  String? _selectedMethodId;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);
    final grindersAsync = ref.watch(grinderMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);

    return FormSection(
      icon: Icons.insights_outlined,
      title: 'レシピ探索 (実験的)',
      trailing: const StatsTheoryLink(section: StatsTheorySection.gp),
      children: [
        const Text(
          '豆とミルを選ぶと、過去の記録から予測される総合評価をメソッドごとに比較表示します。',
          style: TextStyle(fontSize: 12, color: kMocha),
        ),
        const SizedBox(height: 12),
        if (recordsAsync.isLoading ||
            beansAsync.isLoading ||
            grindersAsync.isLoading ||
            methodsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recordsAsync.hasError ||
            beansAsync.hasError ||
            grindersAsync.hasError ||
            methodsAsync.hasError)
          Text(
            'データの読み込みエラー: '
            '${recordsAsync.error ?? beansAsync.error ?? grindersAsync.error ?? methodsAsync.error}',
            style: const TextStyle(color: kMocha, fontSize: 12),
          )
        else
          _buildContent(
            recordsAsync.value ?? const <CoffeeRecord>[],
            beansAsync.value ?? const <BeanMaster>[],
            grindersAsync.value ?? const <GrinderMaster>[],
            methodsAsync.value ?? const <MethodMaster>[],
          ),
      ],
    );
  }

  Widget _buildContent(
    List<CoffeeRecord> records,
    List<BeanMaster> beans,
    List<GrinderMaster> grinders,
    List<MethodMaster> methods,
  ) {
    // 豆: originIdが空でなく、roastLevelがroastOrdinalMapで解決できるもののみ。
    final candidateBeans = beans.where((b) => b.originId.isNotEmpty).toList();
    final roastMissingCount =
        candidateBeans.where((b) => !roastOrdinalMap.containsKey(b.roastLevel)).length;
    final selectableBeans = candidateBeans
        .where((b) => roastOrdinalMap.containsKey(b.roastLevel))
        .toList()
      ..sort((a, b) {
        final aStar = a.seekOptimalConditions == true;
        final bStar = b.seekOptimalConditions == true;
        if (aStar != bStar) return aStar ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    if (selectableBeans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '産地・焙煎度が登録された豆がまだありません(豆マスタで産地と焙煎度を登録すると探索できます)。',
          style: TextStyle(fontSize: 12, color: kMocha),
        ),
      );
    }

    // ミル: grindSteps != null (ドリップバッグ等を除外)。
    final selectableGrinders = grinders.where((g) => g.grindSteps != null).toList();
    if (selectableGrinders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '挽き目調整段階が登録されたミルがまだありません(ミルマスタで登録すると探索できます)。',
          style: TextStyle(fontSize: 12, color: kMocha),
        ),
      );
    }
    final grindStepsByGrinderId = {
      for (final g in selectableGrinders) g.id: g.grindSteps!,
    };

    if (!selectableBeans.any((b) => b.id == _selectedBeanId)) {
      _selectedBeanId = selectableBeans.first.id;
    }
    if (!selectableGrinders.any((g) => g.id == _selectedGrinderId)) {
      // 既定値: 抽出記録での使用回数が最も多いミル(§6.1)。
      final usage = <String, int>{};
      for (final r in records) {
        if (r.grinderId.isEmpty) continue;
        usage[r.grinderId] = (usage[r.grinderId] ?? 0) + 1;
      }
      final candidates = selectableGrinders
          .where((g) => usage.containsKey(g.id))
          .toList()
        ..sort((a, b) => (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0));
      _selectedGrinderId = candidates.isNotEmpty ? candidates.first.id : selectableGrinders.first.id;
    }

    final bean = selectableBeans.firstWhere((b) => b.id == _selectedBeanId);
    final roastOrdinal = roastOrdinalMap[bean.roastLevel]!;

    // 除外件数(設計書§6.5): 粒度またはミルが未記録の記録数(全体、豆非依存)。
    final excludedCount = records.where((r) {
      final clicks = double.tryParse(r.grindSize.trim());
      final grindOk = clicks != null && clicks > 0;
      final grinderOk = grindStepsByGrinderId.containsKey(r.grinderId);
      return !grindOk || !grinderOk;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBeanId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '豆', border: OutlineInputBorder()),
                items: [
                  for (final b in selectableBeans)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text(
                        '${b.seekOptimalConditions == true ? '★ ' : ''}${b.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _selectedBeanId = v;
                  _selectedMethodId = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedGrinderId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'ミル', border: OutlineInputBorder()),
                items: [
                  for (final g in selectableGrinders)
                    DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() {
                  _selectedGrinderId = v;
                  _selectedMethodId = null;
                }),
              ),
            ),
          ],
        ),
        if (roastMissingCount > 0) ...[
          const SizedBox(height: 4),
          Text(
            '★ = 最適条件探索の対象に設定した豆 / 焙煎度が未設定の豆は$roastMissingCount件除外しています。',
            style: const TextStyle(fontSize: 11, color: kMocha),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '★ = 最適条件探索の対象に設定した豆',
              style: TextStyle(fontSize: 11, color: kMocha),
            ),
          ),
        const SizedBox(height: 16),
        _buildMethodComparison(
          records,
          methods,
          bean.originId,
          roastOrdinal,
          _selectedGrinderId!,
          grindStepsByGrinderId,
        ),
        if (excludedCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '粒度またはミルが未記録の$excludedCount件は計算から除外しました。',
            style: const TextStyle(fontSize: 11, color: kMocha),
          ),
        ],
      ],
    );
  }

  Widget _buildMethodComparison(
    List<CoffeeRecord> records,
    List<MethodMaster> methods,
    String originId,
    double roastOrdinal,
    String targetGrinderId,
    Map<String, int> grindStepsByGrinderId,
  ) {
    final service = GpService();
    final rankings = <_MethodRanking>[];
    final insufficientMethods = <MethodMaster>[];

    for (final method in methods) {
      final model = service.fitForMethod(
        records,
        methodId: method.id,
        originId: originId,
        roastOrdinal: roastOrdinal,
        targetGrinderId: targetGrinderId,
        grindStepsByGrinderId: grindStepsByGrinderId,
      );
      if (model == null) {
        insufficientMethods.add(method);
        continue;
      }
      final coarse = service.optimize(model, refine: false);
      rankings.add(_MethodRanking(
        method: method,
        model: model,
        coarseBest: coarse.best,
        coarseBestX: coarse.bestX,
      ));
    }

    if (rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'この豆に近い記録が十分に集まっているメソッドがまだありません。',
          style: TextStyle(fontSize: 12, color: kMocha),
        ),
      );
    }

    // 設計書§4.4: μ降順。差0.05未満はn_eff降順で同点タイブレーク。
    rankings.sort((a, b) {
      final diff = b.coarseBest.mean - a.coarseBest.mean;
      if (diff.abs() < 0.05) return b.model.nEff.compareTo(a.model.nEff);
      return diff > 0 ? 1 : -1;
    });

    if (!rankings.any((r) => r.method.id == _selectedMethodId)) {
      _selectedMethodId = rankings.first.method.id;
    }
    final selected = rankings.firstWhere((r) => r.method.id == _selectedMethodId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kAccent.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2.2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: kCream),
                children: [
                  _headerCell('メソッド'),
                  _headerCell('予測スコア'),
                  _headerCell('確信度'),
                  _headerCell('n'),
                ],
              ),
              for (var i = 0; i < rankings.length; i++)
                _methodRow(rankings[i], isTop: i == 0, isSelected: rankings[i].method.id == _selectedMethodId),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildRecommendation(selected),
        if (insufficientMethods.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'データ不足のメソッド (${insufficientMethods.length}件)',
              style: const TextStyle(fontSize: 12, color: kMocha),
            ),
            children: [
              for (final m in insufficientMethods)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${m.name}(${_reasonFor(records, m, originId, roastOrdinal, targetGrinderId, grindStepsByGrinderId)})',
                    style: const TextStyle(fontSize: 11, color: kMocha),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _reasonFor(
    List<CoffeeRecord> records,
    MethodMaster method,
    String originId,
    double roastOrdinal,
    String targetGrinderId,
    Map<String, int> grindStepsByGrinderId,
  ) {
    var nRows = 0;
    var nEff = 0.0;
    for (final r in records) {
      if (r.methodId != method.id) continue;
      final ratio = r.brewRatio;
      if (r.scoreOverall <= 0 || ratio == null || r.temperature <= 0 || r.totalTime <= 0) continue;
      final clicks = double.tryParse(r.grindSize.trim());
      if (clicks == null || clicks <= 0) continue;
      final grindSteps = grindStepsByGrinderId[r.grinderId];
      if (grindSteps == null) continue;
      nRows++;
      final recordRoastOrdinal = roastOrdinalMap[r.roastLevel];
      double wOriginRoast;
      if (r.originId == originId && recordRoastOrdinal == roastOrdinal) {
        wOriginRoast = 1.0;
      } else if (r.originId == originId &&
          recordRoastOrdinal != null &&
          (recordRoastOrdinal - roastOrdinal).abs() <= 1) {
        wOriginRoast = 0.5;
      } else {
        wOriginRoast = 0.2;
      }
      nEff += wOriginRoast * (r.grinderId == targetGrinderId ? 1.0 : 0.5);
    }
    return '記録$nRows件 / n_eff ${nEff.toStringAsFixed(1)}';
  }

  TableRow _methodRow(_MethodRanking r, {required bool isTop, required bool isSelected}) {
    final totalSd = math.sqrt(r.coarseBest.sd * r.coarseBest.sd + r.model.sigmaN * r.model.sigmaN);
    final lower = (r.coarseBest.mean - 1.96 * totalSd).clamp(0.0, 10.0);
    final upper = (r.coarseBest.mean + 1.96 * totalSd).clamp(0.0, 10.0);
    final badge = _confidenceBadge(r.model.nEff);

    return TableRow(
      decoration: BoxDecoration(color: isSelected ? kAccent.withValues(alpha: 0.12) : null),
      children: [
        InkWell(
          onTap: () => setState(() => _selectedMethodId = r.method.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                if (isTop)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.star, size: 14, color: kAccent),
                  ),
                Flexible(
                  child: Text(
                    r.method.name,
                    style: const TextStyle(fontSize: 12, color: kEspresso),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => setState(() => _selectedMethodId = r.method.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              '${r.coarseBest.mean.toStringAsFixed(1)} [${lower.toStringAsFixed(1)}, ${upper.toStringAsFixed(1)}]',
              style: const TextStyle(fontSize: 12, color: kEspresso),
            ),
          ),
        ),
        InkWell(
          onTap: () => setState(() => _selectedMethodId = r.method.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              badge.$1,
              style: TextStyle(fontSize: 11, color: badge.$2, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        InkWell(
          onTap: () => setState(() => _selectedMethodId = r.method.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(r.model.nEff.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: kMocha)),
          ),
        ),
      ],
    );
  }

  /// (バッジ文言, 色) (設計書§4.3)。
  (String, Color) _confidenceBadge(double nEff) {
    if (nEff >= 12.0) return ('確信度: 高', kAccent);
    if (nEff >= 8.0) return ('確信度: 中', kMocha);
    return ('確信度: 低', kMocha.withValues(alpha: 0.6));
  }

  Widget _buildRecommendation(_MethodRanking selected) {
    final grinders = ref.watch(grinderMasterProvider).value ?? const <GrinderMaster>[];
    final grinder = grinders.where((g) => g.id == _selectedGrinderId).firstOrNull;
    final grindSteps = grinder?.grindSteps;

    final service = GpService();
    final refined = service.optimize(selected.model);
    final best = refined.best;
    final bestX = refined.bestX;
    final exploreX = refined.exploreX;

    final totalSd = math.sqrt(best.sd * best.sd + selected.model.sigmaN * selected.model.sigmaN);
    final lower = (best.mean - 1.96 * totalSd).clamp(0.0, 10.0);
    final upper = (best.mean + 1.96 * totalSd).clamp(0.0, 10.0);

    String formatGrind(double gNorm) {
      if (grindSteps == null) return '';
      final clicks = (gNorm * grindSteps).round();
      return '粒度 $clicks クリック (${grinder?.name ?? ''}・$grindSteps段階中)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              Text(
                'おすすめの条件 — ${selected.method.name}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso),
              ),
              const SizedBox(height: 6),
              Text(
                '湯温 ${bestX.t.toStringAsFixed(0)}℃ / 湯:豆 1:${bestX.r.toStringAsFixed(1)} / '
                '時間 ${_formatTime(bestX.s)} / ${formatGrind(bestX.g)}',
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCream.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('試してみる価値がある条件 (EI最大)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kMocha)),
              const SizedBox(height: 4),
              Text(
                '湯温 ${exploreX.t.toStringAsFixed(0)}℃ / 湯:豆 1:${exploreX.r.toStringAsFixed(1)} / '
                '時間 ${_formatTime(exploreX.s)} / ${formatGrind(exploreX.g)}',
                style: const TextStyle(fontSize: 12, color: kEspresso),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '予測総合評価マップ (${selected.method.name} / 時間 ${_formatTime(bestX.s)}・${formatGrind(bestX.g)} 固定)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso),
        ),
        const SizedBox(height: 8),
        GpHeatmap(model: selected.model, fixedTime: bestX.s, fixedGrind: bestX.g),
      ],
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kEspresso),
        ),
      );

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
