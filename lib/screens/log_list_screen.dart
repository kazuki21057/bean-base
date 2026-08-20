// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../models/coffee_record.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pending_brew_info.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import 'create/brew_evaluation_screen.dart';
import 'create/create_form_widgets.dart';
import 'log_detail_screen.dart';
import 'mock/mock_scaffold.dart';

/// 002 抽出履歴(リスト)。
///
/// Cycle 20 T1-4a: UIモック(LogListMockScreen)の骨格に実データ(Sheets)を
/// 接続した本実装。行タップは既存の LogDetailScreen(003本実装はT1-4b)へ。
/// Cycle 20 T1-4c: 行を左にスワイプすると、そのログの抽出情報・評価値を
/// 引き継いだ 031(評価画面)を開ける(スワイプでの削除は行わない)。
/// Cycle 20 T3-14: 各行左側のアイコンを、該当する豆のマスター画像(未設定なら
/// プレースホルダアイコン)に変更した。`MockListRow`が既に対応していた
/// `imageUrl`引数を渡すだけで実現できた。
/// Phase 3 T3-77: 豆・メソッド・期間で絞り込めるフィルタ行を追加。
/// ローカル状態(setState)のみで、画面を離れると条件はリセットされる。
class LogListScreen extends ConsumerStatefulWidget {
  const LogListScreen({super.key});

  @override
  ConsumerState<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends ConsumerState<LogListScreen> {
  String? _filterBeanId;
  String? _filterMethodId;
  DateTimeRange? _filterDateRange;

  int get _activeFilterCount =>
      (_filterBeanId != null ? 1 : 0) +
      (_filterMethodId != null ? 1 : 0) +
      (_filterDateRange != null ? 1 : 0);

  void _resetFilters() {
    setState(() {
      _filterBeanId = null;
      _filterMethodId = null;
      _filterDateRange = null;
    });
  }

  bool _matchesFilter(CoffeeRecord log) {
    if (_filterBeanId != null && log.beanId != _filterBeanId) return false;
    if (_filterMethodId != null && log.methodId != _filterMethodId) return false;
    if (_filterDateRange != null) {
      final start = DateTime(_filterDateRange!.start.year, _filterDateRange!.start.month, _filterDateRange!.start.day);
      final end = DateTime(_filterDateRange!.end.year, _filterDateRange!.end.month, _filterDateRange!.end.day, 23, 59, 59);
      if (log.brewedAt.isBefore(start) || log.brewedAt.isAfter(end)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);
    final grindersAsync = ref.watch(grinderMasterProvider);
    final drippersAsync = ref.watch(dripperMasterProvider);
    final filtersAsync = ref.watch(filterMasterProvider);

    return MockScreenScaffold(
      screen: AppScreen.logList,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kLatte.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '← 行を左にスワイプすると評価を引き継いで再抽出できます',
            style: TextStyle(fontSize: 12, color: kMocha),
          ),
        ),
        _buildFilterBar(beansAsync.valueOrNull, methodsAsync.valueOrNull),
        logsAsync.when(
          data: (logs) {
            final validLogs = logs.where((l) => l.methodId.isNotEmpty && l.totalTime > 0).toList();
            validLogs.sort((a, b) => b.brewedAt.compareTo(a.brewedAt));

            if (validLogs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('抽出履歴がありません')),
              );
            }

            final filteredLogs = validLogs.where(_matchesFilter).toList();

            if (filteredLogs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('条件に一致する記録がありません'),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _resetFilters, child: const Text('フィルタをリセット')),
                    ],
                  ),
                ),
              );
            }

            final beanNames = <String, String>{};
            final beanImages = <String, String?>{};
            beansAsync.whenData((beans) {
              for (final b in beans) {
                beanNames[b.id] = b.name;
                beanImages[b.id] = b.imageUrl;
              }
            });
            final methodNames = <String, String>{};
            methodsAsync.whenData((methods) {
              for (final m in methods) {
                methodNames[m.id] = m.name;
              }
            });

            return Column(
              children: [
                for (final log in filteredLogs)
                  Dismissible(
                    key: ValueKey('log_${log.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _inheritEvaluation(
                      context,
                      log,
                      methods: methodsAsync.valueOrNull,
                      beans: beansAsync.valueOrNull,
                      grinders: grindersAsync.valueOrNull,
                      drippers: drippersAsync.valueOrNull,
                      filters: filtersAsync.valueOrNull,
                    ),
                    background: Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay, color: Colors.white),
                          SizedBox(width: 8),
                          Text('評価を継承', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    child: MockListRow(
                      icon: Icons.coffee,
                      imageUrl: beanImages[log.beanId],
                      title: beanNames[log.beanId] ?? log.beanId,
                      subtitle: '${_formatDateTime(log.brewedAt)} ・ ${methodNames[log.methodId] ?? log.methodId}',
                      trailing: MockScoreBadge(score: log.scoreOverall),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('読み込みエラー: $e')),
          ),
        ),
      ],
    );
  }

  /// フィルタ行(豆・メソッド・期間)。選択中の件数をバッジ表示し、
  /// 1件でも選択中ならリセットボタンを出す。
  Widget _buildFilterBar(List<BeanMaster>? beans, List<MethodMaster>? methods) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLatte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 18, color: kMocha),
              const SizedBox(width: 6),
              const Text('絞り込み', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kEspresso)),
              if (_activeFilterCount > 0) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 9,
                  backgroundColor: kAccent,
                  child: Text('$_activeFilterCount', style: const TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ],
              const Spacer(),
              if (_activeFilterCount > 0)
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('リセット'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDropdownChip<String>(
                value: _filterBeanId,
                selected: _filterBeanId != null,
                items: [
                  const DropdownMenuItem(value: null, child: Text('豆: すべて')),
                  for (final b in beans ?? const <BeanMaster>[])
                    DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _filterBeanId = v),
              ),
              _buildDropdownChip<String>(
                value: _filterMethodId,
                selected: _filterMethodId != null,
                items: [
                  const DropdownMenuItem(value: null, child: Text('メソッド: すべて')),
                  for (final m in methods ?? const <MethodMaster>[])
                    DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _filterMethodId = v),
              ),
              _buildDateRangeChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownChip<T>({
    required T? value,
    required bool selected,
    required List<DropdownMenuItem<T?>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? kAccent.withValues(alpha: 0.15) : kCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? kAccent : kLatte),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: kMocha),
          style: TextStyle(fontSize: 13, color: selected ? kEspresso : kMocha),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateRangeChip() {
    final selected = _filterDateRange != null;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _filterDateRange,
        );
        if (picked != null) setState(() => _filterDateRange = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.15) : kCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kAccent : kLatte),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: selected ? kEspresso : kMocha),
            const SizedBox(width: 6),
            Text(
              selected
                  ? '${_formatDate(_filterDateRange!.start)}〜${_formatDate(_filterDateRange!.end)}'
                  : '期間: すべて',
              style: TextStyle(fontSize: 13, color: selected ? kEspresso : kMocha),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => setState(() => _filterDateRange = null),
                child: const Icon(Icons.close, size: 14, color: kMocha),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// スワイプされたログの抽出情報・評価値を [PendingBrewInfo] に詰めて
  /// 031(評価画面)へ遷移する。リストからは削除しないため常に false を返す。
  Future<bool> _inheritEvaluation(
    BuildContext context,
    CoffeeRecord log, {
    required List<MethodMaster>? methods,
    required List<BeanMaster>? beans,
    required List<GrinderMaster>? grinders,
    required List<DripperMaster>? drippers,
    required List<FilterMaster>? filters,
  }) async {
    final method = _findById<MethodMaster>(methods, log.methodId);
    if (method == null) {
      debugPrint('[Antigravity] Action: 評価継承に失敗(メソッド未検出 id=${log.methodId})');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メソッドが見つからないため評価を継承できません')),
      );
      return false;
    }

    final info = PendingBrewInfo(
      brewedAt: DateTime.now(),
      method: method,
      bean: _findById<BeanMaster>(beans, log.beanId),
      grinder: _findById<GrinderMaster>(grinders, log.grinderId),
      dripper: _findById<DripperMaster>(drippers, log.dripperId),
      filter: _findById<FilterMaster>(filters, log.filterId),
      beanWeight: log.beanWeight,
      totalWater: log.totalWater,
      totalTime: log.totalTime,
      bloomingWater: log.bloomingWater,
      bloomingTime: log.bloomingTime,
      scoreFragrance: log.scoreFragrance,
      scoreAcidity: log.scoreAcidity,
      scoreBitterness: log.scoreBitterness,
      scoreSweetness: log.scoreSweetness,
      scoreComplexity: log.scoreComplexity,
      scoreFlavor: log.scoreFlavor,
      scoreOverall: log.scoreOverall,
      taste: log.taste,
      concentration: log.concentration,
      comment: log.comment,
    );

    debugPrint('[Antigravity] Action: 002のスワイプで評価継承→031へ遷移 (id=${log.id})');
    if (context.mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => BrewEvaluationScreen(info: info)));
    }
    return false;
  }

  V? _findById<V>(List<V>? list, String id) {
    if (list == null || id.isEmpty) return null;
    for (final item in list) {
      if ((item as dynamic).id == id) return item;
    }
    return null;
  }

  String _formatDateTime(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}/$m/$day $h:$min';
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }
}
