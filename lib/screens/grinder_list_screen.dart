import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_masters.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'create/grinder_create_screen.dart';
import 'grinder_detail_screen.dart';
import 'master_template.dart';

/// 022 グラインダー管理(リスト)。
///
/// Cycle 20 T1-5c: 汎用マスターテンプレート(MasterListTemplate)を
/// T1-5a/bのドリッパー/フィルター実装から流用した本実装。UIモックを置き換える。
class GrinderListScreen extends ConsumerWidget {
  const GrinderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grindersAsync = ref.watch(grinderMasterProvider);

    return MasterListTemplate<GrinderMaster>(
      screen: AppScreen.grinderList,
      icon: Icons.settings_input_component_outlined,
      itemsAsync: grindersAsync,
      filter: (g) => g.name != '-' && g.name.isNotEmpty,
      nameOf: (g) => g.name,
      subtitleOf: (g) => (g.grindRange?.isNotEmpty ?? false) ? g.grindRange! : (g.description ?? ''),
      imageUrlOf: (g) => ImageUtils.getOptimizedImageUrl(g.imageUrl),
      onTapItem: (context, g) {
        debugPrint('[Antigravity] Action: グラインダー一覧022から詳細023へ遷移 (id=${g.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GrinderDetailScreen(grinder: g)),
        );
      },
      createScreenBuilder: () => const GrinderCreateScreen(),
    );
  }
}
