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
    // T3-72d: 編集→保存→pop直後も最新値を表示するため、コンストラクタ引数
    // (遷移時点のスナップショット)ではなくdripperMasterProviderの最新値を使う。
    final drippers = ref.watch(dripperMasterProvider).value;
    final currentDripper = drippers?.firstWhere((d) => d.id == dripper.id, orElse: () => dripper) ?? dripper;

    return MasterDetailTemplate(
      screen: AppScreen.dripperDetail,
      icon: Icons.filter_alt_outlined,
      title: currentDripper.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(currentDripper.imageUrl),
      fields: [
        ('名前', currentDripper.name),
        ('素材', currentDripper.material ?? '-'),
        ('形状', currentDripper.shape ?? '-'),
      ],
      relatedLogFilter: (log) => log.dripperId == currentDripper.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: ドリッパー詳細014から編集画面へ遷移 (id=${currentDripper.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DripperCreateScreen(editData: currentDripper)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: ドリッパー削除 (id=${currentDripper.id})');
        try {
          if (currentDripper.imageUrl != null && currentDripper.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(currentDripper.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteDripper(currentDripper.id);
          ref.read(dripperMasterProvider.notifier).removeOptimistic(currentDripper.id);
        } catch (e) {
          debugPrint('[Antigravity] Error: ドリッパー削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
