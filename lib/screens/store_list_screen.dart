import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'create/store_create_screen.dart';
import 'master_template.dart';
import 'store_detail_screen.dart';

/// 026 購入店管理(リスト)。
///
/// T3-68: `docs/store_master_design.md`§5.2のとおり、汎用マスターテンプレート
/// (MasterListTemplate)を適用。絞り込みは実装しない(登録数が少ないため)。
class StoreListScreen extends ConsumerWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storeMasterProvider);

    return MasterListTemplate<StoreMaster>(
      screen: AppScreen.storeList,
      icon: Icons.storefront_outlined,
      itemsAsync: storesAsync,
      nameOf: (s) => s.name,
      subtitleOf: (s) => [s.prefecture, _businessTypeLabel(s)]
          .where((e) => e.isNotEmpty)
          .join(' ・ '),
      imageUrlOf: (s) => ImageUtils.getOptimizedImageUrl(s.imageUrl),
      onTapItem: (context, s) {
        debugPrint('[Antigravity] Action: 購入店一覧026から詳細027へ遷移 (id=${s.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoreDetailScreen(store: s)),
        );
      },
      createScreenBuilder: () => const StoreCreateScreen(),
    );
  }

  static String _businessTypeLabel(StoreMaster s) {
    if (s.hasRoastery) return '自家焙煎';
    if (s.hasOnlineShop && !s.hasPhysicalStore) return 'オンラインのみ';
    return '';
  }
}
