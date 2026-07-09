import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_masters.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../utils/image_utils.dart';
import 'create/dripper_create_screen.dart';
import 'master_template.dart';

/// 014 ドリッパー詳細。
///
/// Cycle 20 T1-5a: 汎用マスターテンプレート(MasterDetailTemplate)を
/// 適用した最初の本実装。UIモック(DripperDetailMockScreen)を置き換える。
class DripperDetailScreen extends ConsumerWidget {
  final DripperMaster dripper;

  const DripperDetailScreen({super.key, required this.dripper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MasterDetailTemplate(
      screen: AppScreen.dripperDetail,
      icon: Icons.filter_alt_outlined,
      title: dripper.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(dripper.imageUrl),
      fields: [
        ('名前', dripper.name),
        ('素材', dripper.material ?? '-'),
        ('形状', dripper.shape ?? '-'),
      ],
      relatedLogFilter: (log) => log.dripperId == dripper.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: ドリッパー詳細014から編集画面へ遷移 (id=${dripper.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DripperCreateScreen(editData: dripper)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: ドリッパー削除 (id=${dripper.id})');
        try {
          if (dripper.imageUrl != null && dripper.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(dripper.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteDripper(dripper.id);
          ref.invalidate(dripperMasterProvider);
        } catch (e) {
          debugPrint('[Antigravity] Error: ドリッパー削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
