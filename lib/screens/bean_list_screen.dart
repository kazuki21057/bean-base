import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/bean_stock_calculator.dart';
import '../utils/image_utils.dart';
import '../widgets/bean_image.dart';
import 'bean_detail_screen.dart';
import 'create/bean_create_screen.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';

/// 010 豆管理(カード)。
///
/// Cycle 20 T1-6a: 焙煎所/豆名/煎り度/画像/残量をカード形式の実データで表示する。
/// Cycle 20 T2-2b: 残量%を `calculateBeanRemainingPercent`(抽出履歴からの算出)
/// に接続。「初期購入量(g)」未設定の豆(既存データ含む)は0%になる。
class BeanListScreen extends ConsumerStatefulWidget {
  const BeanListScreen({super.key});

  @override
  ConsumerState<BeanListScreen> createState() => _BeanListScreenState();
}

class _BeanListScreenState extends ConsumerState<BeanListScreen> {
  bool _showEmpty = false;

  @override
  Widget build(BuildContext context) {
    final beansAsync = ref.watch(beanMasterProvider);
    final logsAsync = ref.watch(coffeeRecordsProvider);

    return MockScreenScaffold(
      screen: AppScreen.beanList,
      floatingActionButton: MockAddFab(
        tooltip: '新規豆追加(012)へ',
        destinationBuilder: () => const BeanCreateScreen(),
      ),
      children: [
        MockSwitchTile(
          label: '残量0%の豆も表示する',
          initialValue: _showEmpty,
          onChanged: (v) => setState(() => _showEmpty = v),
        ),
        const SizedBox(height: 4),
        beansAsync.when(
          data: (beans) {
            final logs = logsAsync.value ?? const [];
            final named = beans.where((b) => b.name != '-' && b.name.isNotEmpty);
            final withPercent = [
              for (final bean in named) (bean, calculateBeanRemainingPercent(bean, logs)),
            ];
            final visible = withPercent.where((e) => _showEmpty || e.$2 > 0).toList();
            if (visible.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('登録されていません')),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                // モバイル幅では220px固定だと1列しか入らないため、
                // 狭い画面では2列に収まる幅を算出する(広い画面は220px固定のまま多列)。
                final cardWidth = constraints.maxWidth < 460
                    ? (constraints.maxWidth - spacing) / 2
                    : 220.0;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final (bean, percent) in visible)
                      _BeanCard(bean: bean, percent: percent, width: cardWidth),
                  ],
                );
              },
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
}

class _BeanCard extends StatelessWidget {
  final BeanMaster bean;
  final int percent;
  final double width;

  const _BeanCard({required this.bean, required this.percent, required this.width});

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUtils.getOptimizedImageUrl(bean.imageUrl);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        debugPrint('[Antigravity] Action: 豆一覧010から詳細011へ遷移 (id=${bean.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BeanDetailScreen(bean: bean)),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLatte),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kLatte),
              ),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? BeanImage(
                      imagePath: imageUrl,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.coffee,
                    )
                  : const Icon(Icons.coffee, size: 36, color: kMocha),
            ),
            const SizedBox(height: 8),
            Text(bean.store, style: const TextStyle(fontSize: 11, color: kMocha)),
            Text(
              bean.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(bean.roastLevel,
                      style: const TextStyle(fontSize: 11, color: kEspresso)),
                ),
                const Spacer(),
                Text('残 $percent%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kEspresso)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 6,
                backgroundColor: kCream,
                color: kMocha,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
