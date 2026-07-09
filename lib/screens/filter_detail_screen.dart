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
    return MasterDetailTemplate(
      screen: AppScreen.filterDetail,
      icon: Icons.layers_outlined,
      title: filter.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(filter.imageUrl),
      fields: [
        ('名前', filter.name),
        ('素材', filter.material ?? '-'),
        ('サイズ', filter.size ?? '-'),
      ],
      relatedLogFilter: (log) => log.filterId == filter.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: フィルター詳細017から編集画面へ遷移 (id=${filter.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FilterCreateScreen(editData: filter)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: フィルター削除 (id=${filter.id})');
        try {
          if (filter.imageUrl != null && filter.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(filter.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteFilter(filter.id);
          ref.invalidate(filterMasterProvider);
        } catch (e) {
          debugPrint('[Antigravity] Error: フィルター削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
