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
    // T3-72d: 編集→保存→pop直後も最新値を表示するため、コンストラクタ引数
    // (遷移時点のスナップショット)ではなくgrinderMasterProviderの最新値を使う。
    final grinders = ref.watch(grinderMasterProvider).value;
    final currentGrinder = grinders?.firstWhere((g) => g.id == grinder.id, orElse: () => grinder) ?? grinder;

    return MasterDetailTemplate(
      screen: AppScreen.grinderDetail,
      icon: Icons.settings_input_component_outlined,
      title: currentGrinder.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(currentGrinder.imageUrl),
      fields: [
        ('名前', currentGrinder.name),
        ('挽き目レンジ', currentGrinder.grindRange ?? '-'),
        ('説明・メモ', currentGrinder.description ?? '-'),
      ],
      relatedLogFilter: (log) => log.grinderId == currentGrinder.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: グラインダー詳細023から編集画面へ遷移 (id=${currentGrinder.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GrinderCreateScreen(editData: currentGrinder)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: グラインダー削除 (id=${currentGrinder.id})');
        try {
          if (currentGrinder.imageUrl != null && currentGrinder.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(currentGrinder.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteGrinder(currentGrinder.id);
          ref.read(grinderMasterProvider.notifier).removeOptimistic(currentGrinder.id);
        } catch (e) {
          debugPrint('[Antigravity] Error: グラインダー削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
