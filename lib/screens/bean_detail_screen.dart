import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../utils/bean_stock_calculator.dart';
import '../utils/image_utils.dart';
import 'create/bean_create_screen.dart';
import 'master_template.dart';

/// 011 豆管理(詳細)。
///
/// Cycle 20 T1-6b: 汎用マスターテンプレート(MasterDetailTemplate)を
/// 適用した本実装。UIモック(BeanDetailMockScreen)を置き換える。
/// Cycle 20 T2-2b: 残量%を `calculateBeanRemainingPercent`(抽出履歴からの算出)
/// に接続。「初期購入量(g)」未設定の豆(既存データ含む)は0%になる。
class BeanDetailScreen extends ConsumerWidget {
  final BeanMaster bean;

  const BeanDetailScreen({super.key, required this.bean});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(coffeeRecordsProvider).value ?? const [];
    final percent = calculateBeanRemainingPercent(bean, logs);

    return MasterDetailTemplate(
      screen: AppScreen.beanDetail,
      icon: Icons.coffee,
      title: bean.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(bean.imageUrl),
      fields: [
        ('豆名', bean.name),
        ('焙煎所', bean.store.isEmpty ? '-' : bean.store),
        ('産地', bean.origin.isEmpty ? '-' : bean.origin),
        ('品種・精製', bean.type.isEmpty ? '-' : bean.type),
        ('煎り度', bean.roastLevel.isEmpty ? '-' : bean.roastLevel),
        ('購入日', _formatDate(bean.purchaseDate)),
        ('初期購入量', bean.initialQuantityGrams == null ? '未設定' : '${bean.initialQuantityGrams!.toStringAsFixed(0)}g'),
        ('残量', percent > 0 ? '$percent% (在庫あり)' : '0% (在庫なし)'),
      ],
      relatedLogFilter: (log) => log.beanId == bean.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: 豆詳細011から編集画面へ遷移 (id=${bean.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BeanCreateScreen(editData: bean)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: 豆削除 (id=${bean.id})');
        try {
          if (bean.imageUrl != null && bean.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(bean.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteBean(bean.id);
          ref.invalidate(beanMasterProvider);
        } catch (e) {
          debugPrint('[Antigravity] Error: 豆削除に失敗 $e');
          rethrow;
        }
      },
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '未設定';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }
}
