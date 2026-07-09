import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_masters.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'create/dripper_create_screen.dart';
import 'dripper_detail_screen.dart';
import 'master_template.dart';

/// 013 ドリッパー管理(リスト)。
///
/// Cycle 20 T1-5a: 汎用マスターテンプレート(MasterListTemplate)を
/// 適用した最初の本実装。UIモック(DripperListMockScreen)を置き換える。
class DripperListScreen extends ConsumerWidget {
  const DripperListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drippersAsync = ref.watch(dripperMasterProvider);

    return MasterListTemplate<DripperMaster>(
      screen: AppScreen.dripperList,
      icon: Icons.filter_alt_outlined,
      itemsAsync: drippersAsync,
      filter: (d) => d.name != '-' && d.name.isNotEmpty,
      nameOf: (d) => d.name,
      subtitleOf: (d) =>
          [d.material, d.shape].whereType<String>().where((s) => s.isNotEmpty).join(' ・ '),
      imageUrlOf: (d) => ImageUtils.getOptimizedImageUrl(d.imageUrl),
      onTapItem: (context, d) {
        debugPrint('[Antigravity] Action: ドリッパー一覧013から詳細014へ遷移 (id=${d.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DripperDetailScreen(dripper: d)),
        );
      },
      createScreenBuilder: () => const DripperCreateScreen(),
    );
  }
}
