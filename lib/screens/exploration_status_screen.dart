import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/bean_master.dart';
import '../models/coffee_record.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/exploration_status_service.dart';
import '../services/gp_service.dart';
import '../services/math/encoding.dart';
import '../widgets/brew/gp_heatmap.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';
import 'stats_theory_screen.dart';

/// 045 探索の検証状況(T3-53、設計書 `docs/exploration_status_design.md`)。
///
/// 030(レシピ探索セクション)が担う「これから試すべき条件」に対し、本画面は
/// 「これまで何をどれだけ試したか」「探索空間のどこが手つかずか」「もう十分
/// 探索できたと言えるか」の振り返りを1画面にまとめる。数値計算は
/// [ExplorationStatusService]/[GpService] に委譲し、本ウィジェットは表示のみ
/// を担う(CLAUDE.md絶対規則: 計算はDartローカル)。
class ExplorationStatusScreen extends ConsumerStatefulWidget {
  /// 遷移元で選択中だった豆(011からは必ず指定、030からも指定)。
  /// nullまたは解決できないIDの場合は既定値ルールで決める。
  final String? initialBeanId;

  /// 遷移元で選択中だったミル。nullなら既定値ルール。
  final String? initialGrinderId;

  /// 遷移元で選択中だったメソッド。nullなら既定値ルール。
  final String? initialMethodId;

  const ExplorationStatusScreen({
    super.key,
    this.initialBeanId,
    this.initialGrinderId,
    this.initialMethodId,
  });

  @override
  ConsumerState<ExplorationStatusScreen> createState() => _ExplorationStatusScreenState();
}

class _MethodCandidate {
  final MethodMaster method;
  final GpModel model;
  final GpPrediction coarseBest;

  _MethodCandidate({
    required this.method,
    required this.model,
    required this.coarseBest,
  });
}

/// [GpService.optimize] の戻り値の型(設計書§12-3: 表示中メソッドで1回だけ
/// 呼び、EIカード・分布セクションの両方でこの結果を使い回す)。
typedef _OptimizeResult = ({GpPrediction best, GpPoint bestX, GpPrediction explore, GpPoint exploreX});

class _ExplorationStatusScreenState extends ConsumerState<ExplorationStatusScreen> {
  String? _selectedBeanId;
  String? _selectedGrinderId;
  String? _selectedMethodId;

  @override
  void initState() {
    super.initState();
    _selectedBeanId = widget.initialBeanId;
    _selectedGrinderId = widget.initialGrinderId;
    _selectedMethodId = widget.initialMethodId;
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);
    final grindersAsync = ref.watch(grinderMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);

    final loading = recordsAsync.isLoading ||
        beansAsync.isLoading ||
        grindersAsync.isLoading ||
        methodsAsync.isLoading;
    final hasError = recordsAsync.hasError ||
        beansAsync.hasError ||
        grindersAsync.hasError ||
        methodsAsync.hasError;

    return MockScreenScaffold(
      screen: AppScreen.explorationStatus,
      showSettingsAction: false,
      maxWidth: 720,
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'データの読み込みエラー: '
              '${recordsAsync.error ?? beansAsync.error ?? grindersAsync.error ?? methodsAsync.error}',
              style: const TextStyle(color: kMocha, fontSize: 12),
            ),
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
    // 豆(設計書§7.1、030と同一の選択条件・並び順)。
    final candidateBeans = beans.where((b) => b.originId.isNotEmpty).toList();
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

    // ミル(030と同一の選択条件)。
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

    // 既定値ルール(§7.1): initialXxxが選択肢にあればそれ、無ければフォールバック。
    if (!selectableBeans.any((b) => b.id == _selectedBeanId)) {
      _selectedBeanId = selectableBeans.first.id;
    }
    if (!selectableGrinders.any((g) => g.id == _selectedGrinderId)) {
      final usage = <String, int>{};
      for (final r in records) {
        if (r.grinderId.isEmpty) continue;
        usage[r.grinderId] = (usage[r.grinderId] ?? 0) + 1;
      }
      final usageCandidates = selectableGrinders.where((g) => usage.containsKey(g.id)).toList()
        ..sort((a, b) => (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0));
      _selectedGrinderId = usageCandidates.isNotEmpty ? usageCandidates.first.id : selectableGrinders.first.id;
    }

    final bean = selectableBeans.firstWhere((b) => b.id == _selectedBeanId);
    final roastOrdinal = roastOrdinalMap[bean.roastLevel]!;

    // GP候補メソッド(§7.1: fitForMethodが非nullを返したメソッドのみ、μ降順)。
    final gpService = GpService();
    final candidates = <_MethodCandidate>[];
    for (final m in methods) {
      final model = gpService.fitForMethod(
        records,
        methodId: m.id,
        originId: bean.originId,
        roastOrdinal: roastOrdinal,
        targetGrinderId: _selectedGrinderId!,
        grindStepsByGrinderId: grindStepsByGrinderId,
      );
      if (model == null) continue;
      final coarse = gpService.optimize(model, refine: false);
      candidates.add(_MethodCandidate(method: m, model: model, coarseBest: coarse.best));
    }
    // 設計書§7.1: gp_multidim_design.md §4.4と同じ並び(μ降順、差0.05未満はn_eff降順)。
    candidates.sort((a, b) {
      final diff = b.coarseBest.mean - a.coarseBest.mean;
      if (diff.abs() < 0.05) return b.model.nEff.compareTo(a.model.nEff);
      return diff > 0 ? 1 : -1;
    });

    _MethodCandidate? selected;
    if (candidates.isNotEmpty) {
      if (!candidates.any((c) => c.method.id == _selectedMethodId)) {
        _selectedMethodId = candidates.first.method.id;
      }
      selected = candidates.firstWhere((c) => c.method.id == _selectedMethodId);
    } else {
      _selectedMethodId = null;
    }

    final statusService = ExplorationStatusService();
    final summary = statusService.summarize(
      records,
      beanId: bean.id,
      grindStepsByGrinderId: grindStepsByGrinderId,
    );

    final grinder = selectableGrinders.firstWhere((g) => g.id == _selectedGrinderId);

    // 地雷対策(設計書§12-3): optimize(refine:true)は表示中メソッドで1回だけ
    // 呼び、EIカード・分布セクションの両方でこの結果を使い回す。
    final _OptimizeResult? refined = selected == null ? null : gpService.optimize(selected.model);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSelectors(selectableBeans, selectableGrinders, candidates),
        const SizedBox(height: 16),
        _buildSummarySection(summary, selected, refined, statusService, grinder),
        if (summary.trials.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildScoreTrendSection(summary),
        ],
        if (summary.trials.isNotEmpty && selected != null && refined != null) ...[
          const SizedBox(height: 16),
          _buildDistributionSection(selected, refined, summary, grinder),
        ],
        if (summary.trials.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTrialListSection(summary, methods, grinder),
        ],
      ],
    );
  }

  Widget _buildSelectors(
    List<BeanMaster> selectableBeans,
    List<GrinderMaster> selectableGrinders,
    List<_MethodCandidate> candidates,
  ) {
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
        const SizedBox(height: 12),
        if (candidates.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _selectedMethodId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'メソッド', border: OutlineInputBorder()),
            items: [
              for (final c in candidates)
                DropdownMenuItem(value: c.method.id, child: Text(c.method.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _selectedMethodId = v),
          )
        else
          const Text(
            'まだ判定できません(この豆に近い記録が十分に集まっているメソッドがまだありません)。',
            style: TextStyle(fontSize: 12, color: kMocha),
          ),
        const SizedBox(height: 4),
        const Text(
          '★ = 最適条件探索の対象に設定した豆',
          style: TextStyle(fontSize: 11, color: kMocha),
        ),
      ],
    );
  }

  Widget _buildSummarySection(
    ExplorationSummary summary,
    _MethodCandidate? selected,
    _OptimizeResult? refined,
    ExplorationStatusService statusService,
    GrinderMaster grinder,
  ) {
    return FormSection(
      icon: Icons.explore_outlined,
      title: '探索サマリ',
      trailing: const StatsTheoryLink(section: StatsTheorySection.gp),
      children: [
        if (summary.trials.isEmpty)
          const Text(
            'この豆の抽出記録がまだありません。抽出して評価を登録すると、ここに検証状況が表示されます。',
            style: TextStyle(fontSize: 12, color: kMocha),
          )
        else ...[
          Text(
            '試行 ${summary.trials.length} 回 / 条件の種類 ${summary.uniqueConditionCount} 通り',
            style: const TextStyle(fontSize: 13, color: kEspresso),
          ),
          const SizedBox(height: 4),
          Text(_bestTrialLine(summary), style: const TextStyle(fontSize: 13, color: kEspresso)),
          const SizedBox(height: 4),
          Text(
            '平均スコア ${summary.meanScore.toStringAsFixed(1)} 点 / 最終試行 ${_formatDate(summary.lastTriedAt)}',
            style: const TextStyle(fontSize: 13, color: kEspresso),
          ),
          if (summary.unscoredCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '評価が未入力の${summary.unscoredCount}件は集計から除外しました。',
              style: const TextStyle(fontSize: 11, color: kMocha),
            ),
          ],
          if (summary.conditionIncompleteCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '条件(湯温・比率・時間・粒度)の一部が未記録の${summary.conditionIncompleteCount}件は条件の分布に表示できません。',
              style: const TextStyle(fontSize: 11, color: kMocha),
            ),
          ],
        ],
        if (selected != null && refined != null) ...[
          const SizedBox(height: 12),
          _buildNextConditionCard(selected, refined, statusService, grinder),
        ],
      ],
    );
  }

  String _bestTrialLine(ExplorationSummary summary) {
    final best = summary.bestTrial!;
    final date = _formatDate(best.record.brewedAt);
    if (!best.hasFullCondition) {
      return '最高スコア ${best.record.scoreOverall} 点($date、条件の一部が未記録)';
    }
    final brewRatio = best.brewRatio!;
    return '最高スコア ${best.record.scoreOverall} 点'
        '($date、湯温 ${best.record.temperature.toStringAsFixed(0)}℃ / '
        '湯:豆 1:${brewRatio.toStringAsFixed(1)} / 時間 ${_formatTime(best.record.totalTime)} / '
        '粒度 ${best.record.grindSize} クリック)';
  }

  Widget _buildNextConditionCard(
    _MethodCandidate selected,
    _OptimizeResult refined,
    ExplorationStatusService statusService,
    GrinderMaster grinder,
  ) {
    final exploreX = refined.exploreX;
    final explore = refined.explore;

    final totalSd = math.sqrt(explore.sd * explore.sd + selected.model.sigmaN * selected.model.sigmaN);
    final lower = (explore.mean - 1.96 * totalSd).clamp(0.0, 10.0);
    final upper = (explore.mean + 1.96 * totalSd).clamp(0.0, 10.0);

    final grindSteps = grinder.grindSteps;
    final grindLabel = grindSteps == null
        ? ''
        : '粒度 ${(exploreX.g * grindSteps).round()} クリック (${grinder.name}・$grindSteps段階中)';

    final progress = statusService.judgeProgress(explore.ei);

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
                '次に試すと良い条件 — ${selected.method.name}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso),
              ),
              const SizedBox(height: 6),
              Text(
                '湯温 ${exploreX.t.toStringAsFixed(0)}℃ / 湯:豆 1:${exploreX.r.toStringAsFixed(1)} / '
                '時間 ${_formatTime(exploreX.s)} / $grindLabel',
                style: const TextStyle(fontSize: 13, color: kEspresso),
              ),
              const SizedBox(height: 4),
              Text(
                '予測スコア ${explore.mean.toStringAsFixed(1)} [${lower.toStringAsFixed(1)}, ${upper.toStringAsFixed(1)}] '
                '(95%予測区間) / 期待改善量 ${explore.ei.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: kMocha),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 探索の進み具合(設計書§6、タスク定義④)。
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCream.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _progressLabel(progress.level),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.gauge,
                  minHeight: 6,
                  backgroundColor: kLatte,
                  color: kAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '目安(期待改善量 ${explore.ei.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 11, color: kMocha),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _progressLabel(ExplorationProgress level) {
    switch (level) {
      case ExplorationProgress.early:
        return 'まだ試す価値のある条件が残っています';
      case ExplorationProgress.midway:
        return 'かなり探索できています(あと少し)';
      case ExplorationProgress.converged:
        return 'ほぼ探索し尽くしました';
    }
  }

  Widget _buildScoreTrendSection(ExplorationSummary summary) {
    return FormSection(
      icon: Icons.show_chart,
      title: 'スコアの推移',
      children: [
        if (summary.trials.length < 2)
          const Text(
            '記録が2件以上になるとスコアの推移を表示します。',
            style: TextStyle(fontSize: 12, color: kMocha),
          )
        else ...[
          SizedBox(height: 220, child: _scoreTrendChart(summary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(kAccent),
              const SizedBox(width: 4),
              const Text('実測', style: TextStyle(fontSize: 11, color: kMocha)),
              const SizedBox(width: 16),
              _legendDot(kMocha),
              const SizedBox(width: 4),
              const Text('これまでの最高', style: TextStyle(fontSize: 11, color: kMocha)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _scoreTrendChart(ExplorationSummary summary) {
    final trials = summary.trials;
    final n = trials.length;
    final actualSpots = [for (final t in trials) FlSpot(t.index.toDouble(), t.record.scoreOverall.toDouble())];
    final bestSpots = [for (final t in trials) FlSpot(t.index.toDouble(), t.bestSoFar.toDouble())];
    final labelInterval = n <= 10 ? 1.0 : (n / 5).ceil().toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 10,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: true, border: Border.all(color: kLatte)),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 2),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: labelInterval,
              getTitlesWidget: (value, meta) {
                return Text(value.round().toString(), style: const TextStyle(fontSize: 9, color: kMocha));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: actualSpots,
            isCurved: false,
            color: kAccent,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: bestSpots,
            isCurved: false,
            color: kMocha,
            barWidth: 2,
            dashArray: const [4, 3],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection(
    _MethodCandidate selected,
    _OptimizeResult refined,
    ExplorationSummary summary,
    GrinderMaster grinder,
  ) {
    final bestX = refined.bestX;
    final grindSteps = grinder.grindSteps;
    final fixedGrindLabel = grindSteps == null ? '' : '粒度 ${(bestX.g * grindSteps).round()} クリック';

    final points = [
      for (final t in summary.trials)
        if (t.hasFullCondition)
          GpHeatmapPoint(temperature: t.record.temperature, brewRatio: t.brewRatio!, score: t.record.scoreOverall),
    ];

    var occupiedCells = 0;
    for (final temp in GpHeatmap.temps) {
      for (final ratio in GpHeatmap.ratios) {
        final hit = points.any((p) => (p.temperature - temp).abs() <= 2.5 && (p.brewRatio - ratio).abs() <= 0.5);
        if (hit) occupiedCells++;
      }
    }

    return FormSection(
      icon: Icons.grid_on_outlined,
      title: '試した条件の分布',
      children: [
        Text(
          '予測総合評価マップ (${selected.method.name} / 時間 ${_formatTime(bestX.s)}・$fixedGrindLabel 固定)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso),
        ),
        const SizedBox(height: 8),
        GpHeatmap(model: selected.model, fixedTime: bestX.s, fixedGrind: bestX.g, overlay: points),
        const SizedBox(height: 8),
        const Text(
          '●n = その条件付近で試した回数(この豆の記録のみ)',
          style: TextStyle(fontSize: 11, color: kMocha),
        ),
        Text(
          '湯温×比率の20マス中、実測があるのは$occupiedCellsマスです。',
          style: const TextStyle(fontSize: 11, color: kMocha),
        ),
        const SizedBox(height: 4),
        const Text(
          '色は予測値です。産地・焙煎度が近い他の豆の記録も学習に使っているため、●が無いマスにも予測値が出ます。',
          style: TextStyle(fontSize: 11, color: kMocha),
        ),
      ],
    );
  }

  Widget _buildTrialListSection(ExplorationSummary summary, List<MethodMaster> methods, GrinderMaster grinder) {
    final sorted = summary.trials.reversed.toList(); // 新しい順(index降順)
    final visible = sorted.take(10).toList();
    final rest = sorted.length > 10 ? sorted.skip(10).toList() : const <ExplorationTrial>[];

    return FormSection(
      icon: Icons.list_alt_outlined,
      title: '試行の一覧',
      children: [
        _trialTable(visible, methods, grinder),
        if (rest.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'すべての試行を表示 (${sorted.length}件)',
              style: const TextStyle(fontSize: 12, color: kMocha),
            ),
            children: [_trialTable(sorted, methods, grinder)],
          ),
      ],
    );
  }

  Widget _trialTable(List<ExplorationTrial> trials, List<MethodMaster> methods, GrinderMaster grinder) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.4),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(2.2),
        3: FlexColumnWidth(0.8),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: kCream),
          children: [
            _tableHeaderCell('日付'),
            _tableHeaderCell('メソッド'),
            _tableHeaderCell('条件'),
            _tableHeaderCell('点'),
          ],
        ),
        for (final t in trials) _trialRow(t, methods, grinder),
      ],
    );
  }

  TableRow _trialRow(ExplorationTrial t, List<MethodMaster> methods, GrinderMaster grinder) {
    final r = t.record;
    final method = methods.where((m) => m.id == r.methodId).firstOrNull;
    final isOtherGrinder = r.grinderId != grinder.id;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  DateFormat('yyyy/MM/dd').format(r.brewedAt),
                  style: const TextStyle(fontSize: 11, color: kEspresso),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOtherGrinder)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: kLatte, borderRadius: BorderRadius.circular(4)),
                  child: const Text('別ミル', style: TextStyle(fontSize: 9, color: kMocha)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            method?.name ?? '-',
            style: const TextStyle(fontSize: 11, color: kEspresso),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            _conditionLine(r),
            style: const TextStyle(fontSize: 11, color: kEspresso),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('${r.scoreOverall}', style: const TextStyle(fontSize: 11, color: kEspresso)),
        ),
      ],
    );
  }

  String _conditionLine(CoffeeRecord r) {
    final temp = r.temperature > 0 ? '${r.temperature.toStringAsFixed(0)}℃' : '-';
    final ratio = r.brewRatio != null ? '1:${r.brewRatio!.toStringAsFixed(1)}' : '-';
    final time = r.totalTime > 0 ? _formatTime(r.totalTime) : '-';
    final clicks = double.tryParse(r.grindSize.trim());
    final grind = (clicks != null && clicks > 0) ? '${clicks.round()}cl' : '-';
    return '$temp / $ratio / $time / $grind';
  }

  Widget _tableHeaderCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kEspresso)),
      );

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('yyyy/MM/dd').format(d);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
