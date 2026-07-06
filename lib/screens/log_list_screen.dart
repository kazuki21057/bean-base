import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import 'log_detail_screen.dart';
import 'mock/mock_scaffold.dart';

/// 002 抽出履歴(リスト)。
///
/// Cycle 20 T1-4a: UIモック(LogListMockScreen)の骨格に実データ(Sheets)を
/// 接続した本実装。行タップは既存の LogDetailScreen(003本実装はT1-4b)へ。
/// スワイプでの評価継承(T1-4c)は未実装。
class LogListScreen extends ConsumerWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);

    return MockScreenScaffold(
      screen: AppScreen.logList,
      children: [
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
                  MockListRow(
                    icon: Icons.coffee,
                    title: beanNames[log.beanId] ?? log.beanId,
                    subtitle: '${_formatDateTime(log.brewedAt)} ・ ${methodNames[log.methodId] ?? log.methodId}',
                    trailing: MockScoreBadge(score: log.scoreOverall),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)),
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

  String _formatDateTime(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}/$m/$day $h:$min';
  }
}
