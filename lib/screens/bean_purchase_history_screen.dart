import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../models/bean_purchase.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'bean_detail_screen.dart';
import 'mock/mock_scaffold.dart';

/// 025 購入履歴(閲覧専用)。
///
/// T3-64(`docs/bean_purchase_design.md`§6.1〜§6.3): リスト形式のみを実装する。
/// カレンダー形式はT3-65で追加するため、`_PurchaseViewMode`は現時点では
/// `list`の1件のみとし、`SegmentedButton`はこの時点で置いておく
/// (§9「セグメントはT3-65で2つに増やす」)。
enum _PurchaseViewMode { list }

class BeanPurchaseHistoryScreen extends ConsumerStatefulWidget {
  const BeanPurchaseHistoryScreen({super.key});

  @override
  ConsumerState<BeanPurchaseHistoryScreen> createState() =>
      _BeanPurchaseHistoryScreenState();
}

class _BeanPurchaseHistoryScreenState
    extends ConsumerState<BeanPurchaseHistoryScreen> {
  _PurchaseViewMode _mode = _PurchaseViewMode.list;

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(beanPurchasesProvider);
    final beansAsync = ref.watch(beanMasterProvider);

    return MockScreenScaffold(
      screen: AppScreen.beanPurchaseHistory,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_PurchaseViewMode>(
            segments: const [
              ButtonSegment(
                value: _PurchaseViewMode.list,
                icon: Icon(Icons.list),
                label: Text('リスト'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ),
        const SizedBox(height: 12),
        purchasesAsync.when(
          data: (purchases) {
            final beans = beansAsync.value ?? const <BeanMaster>[];
            final sorted = [...purchases]..sort((a, b) {
                final ad = a.purchasedAt;
                final bd = b.purchasedAt;
                if (ad == null && bd == null) return 0;
                if (ad == null) return 1;
                if (bd == null) return -1;
                return bd.compareTo(ad);
              });
            if (sorted.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('購入履歴がありません')),
              );
            }
            return Column(
              children: [
                for (final purchase in sorted)
                  _PurchaseRow(
                    purchase: purchase,
                    bean: _findBean(beans, purchase.beanId),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('読み込みに失敗しました: $e')),
          ),
        ),
      ],
    );
  }

  static BeanMaster? _findBean(List<BeanMaster> beans, String beanId) {
    for (final bean in beans) {
      if (bean.id == beanId) return bean;
    }
    return null;
  }
}

class _PurchaseRow extends StatelessWidget {
  final BeanPurchase purchase;
  final BeanMaster? bean;

  const _PurchaseRow({required this.purchase, required this.bean});

  @override
  Widget build(BuildContext context) {
    final resolvedBean = bean;
    return MockListRow(
      icon: Icons.coffee,
      imageUrl: resolvedBean == null
          ? null
          : ImageUtils.getOptimizedImageUrl(resolvedBean.imageUrl),
      title: resolvedBean?.name ?? '(削除された豆)',
      subtitle: _subtitle(),
      onTap: resolvedBean == null
          ? null
          : () {
              debugPrint(
                  '[Antigravity] Action: 購入履歴025から豆詳細011へ遷移 (豆ID=${resolvedBean.id})');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BeanDetailScreen(bean: resolvedBean),
                ),
              );
            },
    );
  }

  String _subtitle() {
    final parts = <String>[
      purchase.purchasedAt == null ? '' : _formatDate(purchase.purchasedAt!),
      purchase.storeName,
      purchase.quantityGrams == null
          ? ''
          : '${_formatGrams(purchase.quantityGrams!)}g',
      purchase.roastDate == null ? '' : '焙煎 ${_formatMonthDay(purchase.roastDate!)}',
    ];
    return parts.where((e) => e.isNotEmpty).join(' · ');
  }

  static String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }

  static String _formatMonthDay(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m/$day';
  }

  static String _formatGrams(double grams) {
    if (grams == grams.roundToDouble()) return grams.toStringAsFixed(1);
    return grams.toString();
  }
}
