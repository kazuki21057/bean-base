import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import '../widgets/bean_image.dart';
import 'bean_detail_screen.dart';
import 'create/bean_create_screen.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';

/// 010 豆管理(カード)。
///
/// Cycle 20 T1-6a: 焙煎所/豆名/煎り度/画像/残量をカード形式の実データで表示する。
/// 残量%の算出(抽出履歴からの計算)は Phase 2 T2-2b の担当のため、現時点では
/// BeanMaster.isInStock を 100%/0% とみなして扱う(0%表示切替もこれに連動)。
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
            final visible = beans
                .where((b) => b.name != '-' && b.name.isNotEmpty)
                .where((b) => _showEmpty || b.isInStock)
                .toList();
            if (visible.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('登録されていません')),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final bean in visible) _BeanCard(bean: bean),
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
}

class _BeanCard extends StatelessWidget {
  final BeanMaster bean;

  const _BeanCard({required this.bean});

  @override
  Widget build(BuildContext context) {
    final percent = bean.isInStock ? 100 : 0;
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
        width: 220,
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
