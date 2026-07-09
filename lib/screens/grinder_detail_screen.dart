import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_masters.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../utils/image_utils.dart';
import 'create/grinder_create_screen.dart';
import 'master_template.dart';

/// 023 グラインダー詳細。
///
/// Cycle 20 T1-5c: 汎用マスターテンプレート(MasterDetailTemplate)を
/// T1-5a/bのドリッパー/フィルター実装から流用した本実装。UIモックを置き換える。
class GrinderDetailScreen extends ConsumerWidget {
  final GrinderMaster grinder;

  const GrinderDetailScreen({super.key, required this.grinder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MasterDetailTemplate(
      screen: AppScreen.grinderDetail,
      icon: Icons.settings_input_component_outlined,
      title: grinder.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(grinder.imageUrl),
      fields: [
        ('名前', grinder.name),
        ('挽き目レンジ', grinder.grindRange ?? '-'),
        ('説明・メモ', grinder.description ?? '-'),
      ],
      relatedLogFilter: (log) => log.grinderId == grinder.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: グラインダー詳細023から編集画面へ遷移 (id=${grinder.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GrinderCreateScreen(editData: grinder)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: グラインダー削除 (id=${grinder.id})');
        try {
          if (grinder.imageUrl != null && grinder.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(grinder.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteGrinder(grinder.id);
          ref.invalidate(grinderMasterProvider);
        } catch (e) {
          debugPrint('[Antigravity] Error: グラインダー削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
