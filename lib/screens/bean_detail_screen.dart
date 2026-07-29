import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../models/bean_purchase.dart';
import '../models/store_master.dart';
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
    // T3-63: ダイアログを開いた時点でstoreMasterProviderの非同期取得が未完了だと
    // 既定店の一致判定ができないため、buildで先にwatchして解決させておく。
    final stores = ref.watch(storeMasterProvider).value ?? const <StoreMaster>[];

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
        ('保存場所', currentBean.storageLocation.isEmpty ? '-' : currentBean.storageLocation),
        ('購入日', _formatDate(currentBean.purchaseDate)),
        ('初期購入量', currentBean.initialQuantityGrams == null ? '未設定' : '${currentBean.initialQuantityGrams!.toStringAsFixed(1)}g'),
        ('残量', percent > 0 ? '$percent% (在庫あり)' : '0% (在庫なし)'),
        ('最適条件を探索するか', _seekOptimalLabel(currentBean.seekOptimalConditions)),
      ],
      extraSections: [
        FormSection(
          icon: Icons.inventory_2_outlined,
          title: '在庫・購入',
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('現在の残量: ${remainingGrams.toStringAsFixed(1)}g'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: () => _showAddPurchaseDialog(context, ref, currentBean, remainingGrams, stores),
                      child: const Text('追加購入'),
                    ),
                    OutlinedButton(
                      onPressed: () => _showAdjustStockDialog(context, ref, currentBean, remainingGrams),
                      child: const Text('残量を調整'),
                    ),
                  ],
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

  /// T3-63(`docs/bean_purchase_design.md`§3・§4): 追加購入。
  /// 必ず「①`addBeanPurchase`(履歴追記) → ②`updateBean`(豆マスタ更新)」の順で
  /// 行う。①が失敗した場合は何も変更せず中断、①成功・②失敗の場合はその旨を
  /// 明示する(在庫基準点を絶対値で書くため②のリトライは二重加算にならない)。
  Future<void> _showAddPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    BeanMaster currentBean,
    double currentRemainingGrams,
    List<StoreMaster> stores,
  ) async {
    final result = await showDialog<_AddPurchaseResult>(
      context: context,
      builder: (context) => _AddPurchaseDialog(
        currentRemainingGrams: currentRemainingGrams,
        stores: stores,
        currentStoreName: currentBean.store,
      ),
    );

    if (result == null || !context.mounted) return;

    final purchase = BeanPurchase(
      id: 'bp_${DateTime.now().millisecondsSinceEpoch}',
      beanId: currentBean.id,
      purchasedAt: result.purchasedAt,
      roastDate: result.roastDate,
      quantityGrams: result.quantityGrams,
      storeId: result.storeId,
      storeName: result.storeName,
      memo: result.memo,
      createdAt: DateTime.now(),
    );

    debugPrint(
      '[Antigravity] Action: 追加購入を記録 (豆ID=${currentBean.id}, 購入量=${result.quantityGrams}g, 購入店=${result.storeName})',
    );
    try {
      await ref.read(dataServiceProvider).addBeanPurchase(purchase);
      ref.read(beanPurchasesProvider.notifier).addOptimistic(purchase);
    } catch (e) {
      debugPrint('[Antigravity] Error: 購入履歴の記録に失敗 (豆ID=${currentBean.id}) $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('購入履歴の記録に失敗しました。もう一度お試しください'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
      return;
    }

    try {
      final updated = currentBean.copyWith(
        purchaseDate: result.purchasedAt,
        roastDate: result.roastDate,
        stockBaselineGrams: currentRemainingGrams + result.quantityGrams,
        stockBaselineAt: DateTime.now(),
        isInStock: true,
        store: result.storeName.isNotEmpty ? result.storeName : null,
      );
      await ref.read(dataServiceProvider).updateBean(updated);
      ref.read(beanMasterProvider.notifier).updateOptimistic(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('追加購入を記録しました'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '[Antigravity] Error: 追加購入の豆マスタ更新に失敗 (豆ID=${currentBean.id}, 購入日=${result.purchasedAt}, 購入量=${result.quantityGrams}g) $e',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('購入履歴は記録しましたが、豆の残量・購入日の更新に失敗しました。もう一度お試しください'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    }
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

  /// T3-50: `bool?`(未回答/探索する/探索しない)の表示ラベル。
  static String _seekOptimalLabel(bool? v) {
    if (v == true) return '探索する';
    if (v == false) return '探索しない';
    return '未回答';
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

/// T3-63: 追加購入ダイアログの保存結果(§4.2)。
class _AddPurchaseResult {
  final DateTime purchasedAt;
  final DateTime? roastDate;
  final double quantityGrams;
  final String storeId;
  final String storeName;
  final String memo;

  _AddPurchaseResult({
    required this.purchasedAt,
    this.roastDate,
    required this.quantityGrams,
    required this.storeId,
    required this.storeName,
    required this.memo,
  });
}

/// T3-63(`docs/bean_purchase_design.md`§4.2): 追加購入ダイアログの本体。
/// `_AdjustStockDialog`と同様、`TextEditingController`のライフサイクルは
/// このウィジェット自身に持たせる(関数内`showDialog`直後のdisposeは
/// T3-60で踏んだ既知の不具合)。
class _AddPurchaseDialog extends StatefulWidget {
  final double currentRemainingGrams;
  final List<StoreMaster> stores;
  final String currentStoreName;

  const _AddPurchaseDialog({
    required this.currentRemainingGrams,
    required this.stores,
    required this.currentStoreName,
  });

  @override
  State<_AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<_AddPurchaseDialog> {
  late DateTime _purchasedAt;
  DateTime? _roastDate;
  late final TextEditingController _quantityController;
  late final TextEditingController _memoController;
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _purchasedAt = DateTime.now();
    _quantityController = TextEditingController();
    _memoController = TextEditingController();
    final match = widget.stores.where((s) => s.name == widget.currentStoreName);
    _selectedStoreId = match.isNotEmpty ? match.first.id : null;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  double get _quantity => double.tryParse(_quantityController.text.trim()) ?? 0;

  void _save() {
    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showError('購入量を正しく入力してください');
      return;
    }
    if (_roastDate != null && _dateOnly(_roastDate!).isAfter(_dateOnly(_purchasedAt))) {
      _showError('焙煎日は購入日より前の日付にしてください');
      return;
    }
    final store = widget.stores.where((s) => s.id == _selectedStoreId);
    Navigator.pop(
      context,
      _AddPurchaseResult(
        purchasedAt: _purchasedAt,
        roastDate: _roastDate,
        quantityGrams: quantity,
        storeId: store.isNotEmpty ? store.first.id : '',
        storeName: store.isNotEmpty ? store.first.name : '',
        memo: _memoController.text.trim(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final newTotal = widget.currentRemainingGrams + _quantity;
    return AlertDialog(
      title: const Text('追加購入'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MockDateField(
              label: '購入日',
              initialValue: _purchasedAt,
              onChanged: (v) => setState(() => _purchasedAt = v ?? _purchasedAt),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MockDateField(
                    key: ValueKey('roastDate_$_roastDate'),
                    label: '焙煎日(任意)',
                    initialValue: _roastDate,
                    onChanged: (v) => setState(() => _roastDate = v),
                  ),
                ),
                if (_roastDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: '焙煎日をクリア',
                    onPressed: () => setState(() => _roastDate = null),
                  ),
              ],
            ),
            MockTextField(
              label: '購入量(g)',
              hint: '例: 200',
              suffix: 'g',
              required: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: _quantityController,
              onChanged: (_) => setState(() {}),
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedStoreId,
              decoration: const InputDecoration(labelText: '購入店'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('(選択しない)')),
                for (final s in widget.stores) DropdownMenuItem<String>(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _selectedStoreId = v),
            ),
            const SizedBox(height: 14),
            MockTextField(
              label: 'メモ',
              controller: _memoController,
            ),
            Text(
              '現在の残量 ${widget.currentRemainingGrams.toStringAsFixed(1)}g → ${newTotal.toStringAsFixed(1)}g',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
