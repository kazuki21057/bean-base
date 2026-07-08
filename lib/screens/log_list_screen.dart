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
class LogListScreen extends ConsumerWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            final beanNames = <String, String>{};
            beansAsync.whenData((beans) {
              for (final b in beans) {
                beanNames[b.id] = b.name;
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
                for (final log in validLogs)
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
}
