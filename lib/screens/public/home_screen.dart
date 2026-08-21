// T5-B23: 公開版(Android) P100 ホーム画面。
//
// 正本は docs/android_monetization/デザイン方針.md §9.4「P100 ホーム」行・
// §10「ホーム 0件」行。記録が1件以上ある場合は①最後の抽出②今日/今週の
// 統計3つ③インサイト要約カード④最近の記録3行を、0件の場合は`BbEmptyState`
// のみを表示する(挨拶行は置かない)。
//
// データソースは既存の`coffeeRecordsProvider`/`beanMasterProvider`
// (lib/providers/data_providers.dart)をそのまま再利用する(新規取得ロジックは
// 作らない)。本タスクの範囲では他画面・他タブへの導線は未配線のため、
// カード・ボタン・行のタップはすべてno-op(ログのみ出す)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/theme/public/bb_theme.dart';
import 'package:bean_base/theme/public/bb_tokens.dart';
import 'package:bean_base/widgets/public/bb_card.dart';
import 'package:bean_base/widgets/public/bb_buttons.dart';
import 'package:bean_base/widgets/public/bb_empty_state.dart';
import 'package:bean_base/widgets/public/bb_error_view.dart';
import 'package:bean_base/widgets/public/bb_extraction_ring.dart';
import 'package:bean_base/widgets/public/bb_list_row.dart';
import 'package:bean_base/widgets/public/bb_loading.dart';
import 'package:bean_base/widgets/public/bb_section_header.dart';
import 'package:bean_base/widgets/public/bb_stat_tile.dart';

/// 週次集計(「今週」判定)の基準時刻を返す関数。既定は実時刻(`DateTime.now()`)。
///
/// 通常のRiverpod `Provider`にすると初回`watch`時の結果がキャッシュされ、
/// `PublicShell`の`IndexedStack`にホーム画面が保持されたまま週境界
/// (月曜0時)をまたいでも「今週」判定が古いままになってしまう
/// (T5-B23 adversaryレビューMajor-2対応)。そのため通常のプロバイダではなく
/// 差し替え可能なトップレベル関数変数とし、本番では`build()`のたびに
/// `DateTime.now()`を呼び直す。テストでは`homeScreenClock`を固定時刻を返す
/// 関数に差し替え、`addTearDown`で必ず`DateTime.now`へ戻す。
DateTime Function() homeScreenClock = DateTime.now;

/// P100 ホーム画面本体。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(coffeeRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: SafeArea(
        child: recordsAsync.when(
          data: (records) => _HomeBody(records: records),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: BbSpace.xxl),
            child: BbLoadingSkeleton(lineCount: 5),
          ),
          error: (error, stack) {
            debugPrint('[Antigravity] HomeScreen: 抽出記録の読み込みに失敗 error=$error');
            return BbErrorView(
              title: '記録を読み込めませんでした。',
              description: '通信状況を確認して、もう一度お試しください。',
              onRetry: () {
                debugPrint('[Antigravity] HomeScreen: 再試行タップ');
                ref.invalidate(coffeeRecordsProvider);
              },
            );
          },
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.records});

  final List<CoffeeRecord> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: BbEmptyState(
            icon: Icons.local_cafe_outlined,
            title: 'まだ記録がありません',
            description: '1杯淹れると、味の傾向が見えはじめます。',
            actionLabel: 'はじめての抽出を記録する',
            onActionTap: () {
              debugPrint('[Antigravity] HomeScreen: はじめての抽出を記録するタップ(no-op)');
            },
          ),
        ),
      );
    }

    final beans = ref.watch(beanMasterProvider).valueOrNull ?? const <BeanMaster>[];
    final beanNames = <String, String>{
      for (final bean in beans) bean.id: bean.name,
    };

    final sorted = [...records]..sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
    final latest = sorted.first;
    final recentThree = sorted.take(3).toList();

    final now = homeScreenClock();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weeklyRecords =
        sorted.where((r) => !r.brewedAt.isBefore(weekStart)).toList();
    final extractionCount = weeklyRecords.length;
    final averageOverall = weeklyRecords.isEmpty
        ? null
        : weeklyRecords.map((r) => r.scoreOverall).reduce((a, b) => a + b) /
            weeklyRecords.length;
    final currentBeanName = beanNames[latest.beanId] ?? latest.beanId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: BbLayout.screenPaddingH,
        vertical: BbSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LastBrewCard(
            record: latest,
            beanName: beanNames[latest.beanId] ?? latest.beanId,
          ),
          const SizedBox(height: BbLayout.sectionGap),
          Row(
            children: [
              Expanded(
                child: BbStatTile(
                  label: '抽出回数(今週)',
                  value: extractionCount.toString(),
                  unit: '回',
                ),
              ),
              const SizedBox(width: BbSpace.lg),
              Expanded(
                child: BbStatTile(
                  label: '平均総合評価(今週)',
                  value:
                      averageOverall == null ? '-' : averageOverall.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: BbSpace.lg),
              Expanded(
                child: BbStatTile(
                  label: '使用中の豆',
                  value: currentBeanName,
                ),
              ),
            ],
          ),
          const SizedBox(height: BbLayout.sectionGap),
          BbCard(
            onTap: () {
              debugPrint('[Antigravity] HomeScreen: インサイト要約カードタップ(no-op)');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('インサイト', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: BbSpace.xs),
                Text(
                  'インサイトは準備中です',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          BbSectionHeader(
            eyebrow: '最近の記録',
            title: '履歴',
            actionLabel: 'すべて見る',
            onActionTap: () {
              debugPrint('[Antigravity] HomeScreen: すべて見るタップ(no-op)');
            },
          ),
          for (var i = 0; i < recentThree.length; i++)
            BbListRow(
              title: beanNames[recentThree[i].beanId] ?? recentThree[i].beanId,
              subtitle: _formatDateTime(recentThree[i].brewedAt),
              value: recentThree[i].scoreOverall.toString(),
              showDivider: i != recentThree.length - 1,
              onTap: () {
                debugPrint('[Antigravity] HomeScreen: 最近の記録行タップ(no-op)');
              },
            ),
        ],
      ),
    );
  }
}

class _LastBrewCard extends StatelessWidget {
  const _LastBrewCard({required this.record, required this.beanName});

  final CoffeeRecord record;
  final String beanName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bbType = context.bbType;
    final totalSeconds = record.totalTime.toDouble();
    final steps = (record.bloomingTime > 0 && record.bloomingTime < record.totalTime)
        ? [record.bloomingTime.toDouble()]
        : const <double>[];

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BbExtractionRing(
                steps: steps,
                totalSeconds: totalSeconds,
                elapsedSeconds: totalSeconds,
                diameter: 96,
                mode: BbExtractionRingMode.staticMode,
              ),
              const SizedBox(width: BbSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      beanName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BbSpace.xs),
                    Row(
                      children: [
                        Text(
                          '総合評価',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: BbSpace.xs),
                        Text(record.scoreOverall.toString(), style: bbType.numeralL),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BbSpace.lg),
          BbPrimaryButton(
            label: 'もう一度淹れる',
            onPressed: () {
              debugPrint('[Antigravity] HomeScreen: もう一度淹れるタップ(no-op)');
            },
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  final month = dt.month.toString();
  final day = dt.day.toString();
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}
