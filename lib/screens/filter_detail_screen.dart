// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_masters.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../utils/image_utils.dart';
import 'create/filter_create_screen.dart';
import 'master_template.dart';

/// 017 フィルター詳細。
///
/// Cycle 20 T1-5b: 汎用マスターテンプレート(MasterDetailTemplate)を
/// T1-5aのドリッパー実装から流用した本実装。UIモックを置き換える。
class FilterDetailScreen extends ConsumerWidget {
  final FilterMaster filter;

  const FilterDetailScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // T3-72d: 編集→保存→pop直後も最新値を表示するため、コンストラクタ引数
    // (遷移時点のスナップショット)ではなくfilterMasterProviderの最新値を使う。
    final filters = ref.watch(filterMasterProvider).value;
    final currentFilter = filters?.firstWhere((f) => f.id == filter.id, orElse: () => filter) ?? filter;

    return MasterDetailTemplate(
      screen: AppScreen.filterDetail,
      icon: Icons.layers_outlined,
      title: currentFilter.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(currentFilter.imageUrl),
      fields: [
        ('名前', currentFilter.name),
        ('素材', currentFilter.material ?? '-'),
        ('サイズ', currentFilter.size ?? '-'),
      ],
      relatedLogFilter: (log) => log.filterId == currentFilter.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: フィルター詳細017から編集画面へ遷移 (id=${currentFilter.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FilterCreateScreen(editData: currentFilter)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: フィルター削除 (id=${currentFilter.id})');
        try {
          if (currentFilter.imageUrl != null && currentFilter.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(currentFilter.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteFilter(currentFilter.id);
          ref.read(filterMasterProvider.notifier).removeOptimistic(currentFilter.id);
        } catch (e) {
          debugPrint('[Antigravity] Error: フィルター削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
