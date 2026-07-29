import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../models/store_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../utils/image_utils.dart';
import 'bean_detail_screen.dart';
import 'create/create_form_widgets.dart';
import 'create/store_create_screen.dart';
import 'master_template.dart';
import 'mock/mock_scaffold.dart';

/// 027 購入店詳細。
///
/// T3-68: `docs/store_master_design.md`§5.3のとおり実装。
/// `bean_purchases`(T3-62)は未実装のため「この店の購入履歴」セクションは
/// 作らず、統計はこの店の豆の件数・初期購入量合計で代用する
/// (設計書の指示どおり、T3-69/T3-62完了後に切り替える)。
class StoreDetailScreen extends ConsumerWidget {
  final StoreMaster store;

  const StoreDetailScreen({super.key, required this.store});

  /// 旧表記「明暮焙煎研」は`明暮焙煎所`の誤記(設計書§3.2)。
  /// `BeanMaster.storeId`はT3-69未完了のため、店名の文字列一致で代用する。
  bool _matchesBean(BeanMaster b) {
    if (b.store == store.name) return true;
    if (store.name == '明暮焙煎所' && b.store == '明暮焙煎研') return true;
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beansAsync = ref.watch(beanMasterProvider);
    final logsAsync = ref.watch(coffeeRecordsProvider);

    final matchedBeans = beansAsync.value?.where(_matchesBean).toList() ?? const <BeanMaster>[];
    final matchedBeanIds = matchedBeans.map((b) => b.id).toSet();

    final scores = (logsAsync.value ?? const [])
        .where((log) => matchedBeanIds.contains(log.beanId))
        .map((log) => log.scoreOverall)
        .toList();
    final avgScore = scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
    final totalGrams = matchedBeans.fold<double>(
        0, (sum, b) => sum + (b.initialQuantityGrams ?? 0));

    return MasterDetailTemplate(
      screen: AppScreen.storeDetail,
      icon: Icons.storefront_outlined,
      title: store.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(store.imageUrl),
      fields: [
        ('店名', store.name),
        ('正式名称', _orDash(store.formalName)),
        ('URL', _orDash(store.url)),
        ('都道府県', _orDash(store.prefecture)),
        ('住所', _orDash(store.address)),
        ('業態', _businessTypeSummary(store)),
        ('取扱豆の傾向', _orDash(store.beanTendency)),
        ('メモ', _orDash(store.memo)),
        ('SNS', _orDash(store.snsUrl)),
        ('営業時間', _orDash(store.businessHours)),
        ('定休日', _orDash(store.closedDays)),
        ('電話番号', _orDash(store.phone)),
        ('開業年', _orDash(store.openedYear)),
      ],
      extraSections: [
        FormSection(
          icon: Icons.coffee,
          title: 'この店で買った豆',
          children: [
            if (matchedBeans.isEmpty)
              const Text('この店で買った豆はまだ登録されていません')
            else
              Column(
                children: [
                  for (final b in matchedBeans)
                    MockListRow(
                      icon: Icons.coffee,
                      imageUrl: ImageUtils.getOptimizedImageUrl(b.imageUrl),
                      title: b.name,
                      subtitle: _formatDate(b.purchaseDate),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BeanDetailScreen(bean: b)),
                      ),
                    ),
                ],
              ),
          ],
        ),
        FormSection(
          icon: Icons.insights_outlined,
          title: '統計',
          children: [
            MockInfoRow(label: '購入回数', value: '${matchedBeans.length}回'),
            MockInfoRow(label: '総購入量', value: '${totalGrams.toStringAsFixed(0)}g'),
            MockInfoRow(
              label: '平均評価',
              value: avgScore == null ? '-' : avgScore.toStringAsFixed(1),
            ),
          ],
        ),
      ],
      relatedLogFilter: (log) => matchedBeanIds.contains(log.beanId),
      onEdit: () {
        debugPrint('[Antigravity] Action: 購入店詳細027から編集画面へ遷移 (id=${store.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoreCreateScreen(editData: store)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: 購入店削除 (id=${store.id})');
        try {
          if (store.imageUrl != null && store.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(store.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteStore(store.id);
          ref.read(storeMasterProvider.notifier).removeOptimistic(store.id);
        } catch (e) {
          debugPrint('[Antigravity] Error: 購入店削除に失敗 $e');
          rethrow;
        }
      },
    );
  }

  static String _orDash(String value) => value.isEmpty ? '-' : value;

  static String _businessTypeSummary(StoreMaster s) {
    final labels = <String>[
      if (s.hasOnlineShop) 'オンライン販売',
      if (s.hasPhysicalStore) '実店舗',
      if (s.hasRoastery) '焙煎所併設',
    ];
    return labels.isEmpty ? '-' : labels.join(' ・ ');
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '購入日未設定';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }
}
