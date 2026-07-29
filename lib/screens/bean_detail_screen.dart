import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../utils/bean_stock_calculator.dart';
import '../utils/image_utils.dart';
import '../widgets/bean_image.dart';
import 'create/bean_create_screen.dart';
import 'create/create_form_widgets.dart';
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
    // T3-60: 残量調整はこの画面を離れずに保存されるため、`bean`(コンストラクタ引数、
    // 遷移時点のスナップショット)ではなく`beanMasterProvider`の最新値を使い、
    // 保存直後に瓶表示・残量表示がこの画面上でも即座に更新されるようにする。
    final beans = ref.watch(beanMasterProvider).value;
    final currentBean = beans?.firstWhere((b) => b.id == bean.id, orElse: () => bean) ?? bean;
    final percent = calculateBeanRemainingPercent(currentBean, logs);
    final remainingGrams = calculateBeanRemainingGrams(currentBean, logs);

    return MasterDetailTemplate(
      screen: AppScreen.beanDetail,
      icon: Icons.coffee,
      title: currentBean.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(currentBean.imageUrl),
      fields: [
        ('豆名', currentBean.name),
        ('焙煎所', currentBean.store.isEmpty ? '-' : currentBean.store),
        ('産地', currentBean.origin.isEmpty ? '-' : currentBean.origin),
        ('品種・精製', currentBean.type.isEmpty ? '-' : currentBean.type),
        ('煎り度', currentBean.roastLevel.isEmpty ? '-' : currentBean.roastLevel),
        ('購入日', _formatDate(currentBean.purchaseDate)),
        ('初期購入量', currentBean.initialQuantityGrams == null ? '未設定' : '${currentBean.initialQuantityGrams!.toStringAsFixed(1)}g'),
        ('残量', percent > 0 ? '$percent% (在庫あり)' : '0% (在庫なし)'),
      ],
      extraSections: [
        FormSection(
          icon: Icons.scale_outlined,
          title: '残量調整',
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('現在の残量: ${remainingGrams.toStringAsFixed(1)}g'),
                ),
                OutlinedButton(
                  onPressed: () => _showAdjustStockDialog(context, ref, currentBean, remainingGrams),
                  child: const Text('残量を調整'),
                ),
              ],
            ),
          ],
        ),
        FormSection(
          icon: Icons.photo_library_outlined,
          title: '豆画像・情報画像',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _labeledImage('豆画像', currentBean.beanImageUrl, Icons.coffee)),
                const SizedBox(width: 12),
                Expanded(child: _labeledImage('情報画像', currentBean.infoImageUrl, Icons.description_outlined)),
              ],
            ),
          ],
        ),
      ],
      relatedLogFilter: (log) => log.beanId == currentBean.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: 豆詳細011から編集画面へ遷移 (id=${currentBean.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BeanCreateScreen(editData: currentBean)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: 豆削除 (id=${currentBean.id})');
        try {
          final imageService = ref.read(imageServiceProvider);
          for (final url in [currentBean.imageUrl, currentBean.beanImageUrl, currentBean.infoImageUrl]) {
            if (url != null && url.isNotEmpty) {
              await imageService.deleteImage(url);
            }
          }
          await ref.read(dataServiceProvider).deleteBean(currentBean.id);
          ref.read(beanMasterProvider.notifier).removeOptimistic(currentBean.id);
        } catch (e) {
          debugPrint('[Antigravity] Error: 豆削除に失敗 $e');
          rethrow;
        }
      },
    );
  }

  Future<void> _showAdjustStockDialog(
    BuildContext context,
    WidgetRef ref,
    BeanMaster currentBean,
    double currentRemainingGrams,
  ) async {
    final newValue = await showDialog<double>(
      context: context,
      builder: (context) => _AdjustStockDialog(initialGrams: currentRemainingGrams),
    );

    if (newValue == null || newValue < 0 || !context.mounted) return;

    debugPrint('[Antigravity] Action: 豆の残量を手動調整 (id=${currentBean.id}, 新残量=${newValue}g)');
    try {
      final updated = currentBean.copyWith(
        stockBaselineGrams: newValue,
        stockBaselineAt: DateTime.now(),
      );
      await ref.read(dataServiceProvider).updateBean(updated);
      ref.read(beanMasterProvider.notifier).updateOptimistic(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('残量を更新しました'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: 残量の手動調整に失敗 $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('残量の更新に失敗しました'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    }
  }

  static Widget _labeledImage(String label, String? imageUrl, IconData placeholderIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BeanImage(
            imagePath: ImageUtils.getOptimizedImageUrl(imageUrl),
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholderIcon: placeholderIcon,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '未設定';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }
}

/// T3-60: 残量調整ダイアログの本体。`TextEditingController`のライフサイクルを
/// このウィジェット自身に持たせ、ダイアログを閉じるアニメーション中に
/// controllerが破棄されて例外になる不具合(関数内で`showDialog`直後に
/// 手動disposeしていたことが原因)を避ける。
class _AdjustStockDialog extends StatefulWidget {
  final double initialGrams;

  const _AdjustStockDialog({required this.initialGrams});

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGrams.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('残量を調整'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: '現在の残量(g)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            final parsed = double.tryParse(_controller.text.trim());
            Navigator.pop(context, parsed);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
