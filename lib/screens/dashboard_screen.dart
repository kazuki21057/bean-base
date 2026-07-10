import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../routing/screen_registry.dart';
import 'create/create_form_widgets.dart';
import 'bean_list_screen.dart';
import 'log_detail_screen.dart';
import 'log_list_screen.dart';
import 'mock/mock_scaffold.dart';
import 'settings_screen.dart';

/// 001 ダッシュボード。
///
/// Cycle 20 T1-3: UIモック(DashboardMockScreen)の骨組みに実データを一部接続。
/// 「直近の抽出5件」は実データ(003へ遷移)。「残豆量」は残量%の算出ロジックが
/// Phase 2(T2-2b)実装のため、豆名は実データを使いつつ残量表示自体はプレース
/// ホルダのまま(011へは仮遷移)。010(在庫一覧)・002(履歴一覧)への遷移も接続。
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beansAsync = ref.watch(beanMasterProvider);
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final methodsAsync = ref.watch(methodMasterProvider);

    return MockScreenScaffold(
      screen: AppScreen.dashboard,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: '設定',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
      ],
      children: [
        // 黒板風ウェルカムボード(本テーマ化はT2-1a/T2-1bで実装)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2F3E33),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8D6E63), width: 6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's BeanBase ☕",
                style: TextStyle(
                  color: Color(0xFFF5F0E1),
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '今日も一杯、丁寧に。',
                style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
        FormSection(
          icon: Icons.inventory_2_outlined,
          title: '残豆量',
          children: [
            beansAsync.when(
              data: (beans) {
                final stockBeans = beans.where((b) => b.isInStock).toList();
                if (stockBeans.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('在庫中の豆はありません', style: TextStyle(color: kMocha)),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final bean in stockBeans)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => buildScreenWidget(AppScreen.beanDetail)),
                            ),
                            // 残量%の算出(T2-2b)まではプレースホルダ値を表示
                            child: MockBeanJar(name: bean.name, percent: 50),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Text('読み込みエラー: $e'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BeanListScreen()));
                },
                icon: const Icon(Icons.list, size: 18),
                label: const Text('在庫一覧を見る'),
              ),
            ),
          ],
        ),
        FormSection(
          icon: Icons.history,
          title: '直近の抽出 5件',
          children: [
            logsAsync.when(
              data: (logs) {
                final validLogs = logs.where((l) => l.methodId.isNotEmpty && l.totalTime > 0).toList();
                if (validLogs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('抽出履歴がありません', style: TextStyle(color: kMocha)),
                  );
                }
                validLogs.sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
                final recentLogs = validLogs.take(5).toList();

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
                    for (final log in recentLogs)
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
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Text('読み込みエラー: $e'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LogListScreen()));
                },
                child: const Text('すべての履歴を見る'),
              ),
            ),
          ],
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
