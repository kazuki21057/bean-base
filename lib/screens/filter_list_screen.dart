import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_masters.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'create/filter_create_screen.dart';
import 'filter_detail_screen.dart';
import 'master_template.dart';

/// 016 フィルター管理(リスト)。
///
/// Cycle 20 T1-5b: 汎用マスターテンプレート(MasterListTemplate)を
/// T1-5aのドリッパー実装から流用した本実装。UIモックを置き換える。
class FilterListScreen extends ConsumerWidget {
  const FilterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersAsync = ref.watch(filterMasterProvider);

    return MasterListTemplate<FilterMaster>(
      screen: AppScreen.filterList,
      icon: Icons.layers_outlined,
      itemsAsync: filtersAsync,
      filter: (f) => f.name != '-' && f.name.isNotEmpty,
      nameOf: (f) => f.name,
      subtitleOf: (f) =>
          [f.material, f.size].whereType<String>().where((s) => s.isNotEmpty).join(' ・ '),
      imageUrlOf: (f) => ImageUtils.getOptimizedImageUrl(f.imageUrl),
      onTapItem: (context, f) {
        debugPrint('[Antigravity] Action: フィルター一覧016から詳細017へ遷移 (id=${f.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FilterDetailScreen(filter: f)),
        );
      },
      createScreenBuilder: () => const FilterCreateScreen(),
    );
  }
}
