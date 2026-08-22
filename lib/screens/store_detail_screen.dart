// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../models/bean_purchase.dart';
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
/// T3-68: `docs/store_master_design.md`§5.3のとおり実装。T3-69で
/// `BeanMaster.storeId`が導入されたため、「この店で買った豆」の突合は
/// `store`文字列フォールバックを廃し`storeId`一致のみに単純化し、
/// 「この店の購入履歴」セクションを追加した(設計書の指示どおり)。
class StoreDetailScreen extends ConsumerWidget {
  final StoreMaster store;

  const StoreDetailScreen({super.key, required this.store});

  bool _matchesBean(BeanMaster b) => b.storeId == store.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beansAsync = ref.watch(beanMasterProvider);
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final purchasesAsync = ref.watch(beanPurchasesProvider);
    // T3-72d: 編集→保存→pop直後も最新値を表示するため、コンストラクタ引数
    // (遷移時点のスナップショット)ではなくstoreMasterProviderの最新値を使う。
    // T5-A104: AsyncErrorの場合`.value`は例外を投げるため`.valueOrNull`を使う。
    final storesAsync = ref.watch(storeMasterProvider);
    final stores = storesAsync.valueOrNull;
    final currentStore = stores?.firstWhere((s) => s.id == store.id, orElse: () => store) ?? store;
    // T5-A104 Major#3: 通信失敗を無言でデータ0件扱いにせず、ユーザーに伝える。
    final hasError =
        beansAsync.hasError || logsAsync.hasError || purchasesAsync.hasError || storesAsync.hasError;

    final matchedBeans = beansAsync.valueOrNull?.where(_matchesBean).toList() ?? const <BeanMaster>[];
    final matchedBeanIds = matchedBeans.map((b) => b.id).toSet();

    final storePurchases = (purchasesAsync.valueOrNull ?? const <BeanPurchase>[])
        .where((p) => p.storeId == currentStore.id)
        .toList()
      ..sort((a, b) {
        final ad = a.purchasedAt;
        final bd = b.purchasedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

    final scores = (logsAsync.valueOrNull ?? const [])
        .where((log) => matchedBeanIds.contains(log.beanId))
        .map((log) => log.scoreOverall)
        .toList();
    final avgScore = scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
    final totalGrams = matchedBeans.fold<double>(
        0, (sum, b) => sum + (b.initialQuantityGrams ?? 0));

    return MasterDetailTemplate(
      screen: AppScreen.storeDetail,
      icon: Icons.storefront_outlined,
      title: currentStore.name,
      imageUrl: ImageUtils.getOptimizedImageUrl(currentStore.imageUrl),
      fields: [
        ('店名', currentStore.name),
        ('正式名称', _orDash(currentStore.formalName)),
        ('URL', _orDash(currentStore.url)),
        ('都道府県', _orDash(currentStore.prefecture)),
        ('住所', _orDash(currentStore.address)),
        ('業態', _businessTypeSummary(currentStore)),
        ('取扱豆の傾向', _orDash(currentStore.beanTendency)),
        ('メモ', _orDash(currentStore.memo)),
        ('SNS', _orDash(currentStore.snsUrl)),
        ('営業時間', _orDash(currentStore.businessHours)),
        ('定休日', _orDash(currentStore.closedDays)),
        ('電話番号', _orDash(currentStore.phone)),
        ('開業年', _orDash(currentStore.openedYear)),
      ],
      extraSections: [
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'データの読み込みに失敗した項目があります。表示中の内容が最新でない可能性があります。',
              style: TextStyle(color: kMocha, fontSize: 12),
            ),
          ),
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
          icon: Icons.receipt_long_outlined,
          title: 'この店の購入履歴',
          children: [
            if (storePurchases.isEmpty)
              const Text('この店の購入履歴はまだありません')
            else
              Column(
                children: [
                  for (final p in storePurchases)
                    MockListRow(
                      icon: Icons.coffee,
                      imageUrl: ImageUtils.getOptimizedImageUrl(
                        _findBean(beansAsync.valueOrNull ?? const [], p.beanId)?.imageUrl,
                      ),
                      title: _findBean(beansAsync.valueOrNull ?? const [], p.beanId)?.name ?? '(削除された豆)',
                      subtitle: _formatPurchaseSubtitle(p),
                      onTap: () {
                        final b = _findBean(beansAsync.valueOrNull ?? const [], p.beanId);
                        if (b == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BeanDetailScreen(bean: b)),
                        );
                      },
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
        debugPrint('[Antigravity] Action: 購入店詳細027から編集画面へ遷移 (id=${currentStore.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoreCreateScreen(editData: currentStore)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: 購入店削除 (id=${currentStore.id})');
        try {
          if (currentStore.imageUrl != null && currentStore.imageUrl!.isNotEmpty) {
            await ref.read(imageServiceProvider).deleteImage(currentStore.imageUrl!);
          }
          await ref.read(dataServiceProvider).deleteStore(currentStore.id);
          ref.read(storeMasterProvider.notifier).removeOptimistic(currentStore.id);
        } catch (e) {
          debugPrint('[Antigravity] Error: 購入店削除に失敗 $e');
          rethrow;
        }
      },
    );
  }

  static BeanMaster? _findBean(List<BeanMaster> beans, String beanId) {
    for (final b in beans) {
      if (b.id == beanId) return b;
    }
    return null;
  }

  static String _formatPurchaseSubtitle(BeanPurchase p) {
    final parts = <String>[
      p.purchasedAt == null ? '' : _formatDate(p.purchasedAt),
      p.quantityGrams == null ? '' : '${_formatGrams(p.quantityGrams!)}g',
    ];
    return parts.where((e) => e.isNotEmpty).join(' · ');
  }

  static String _formatGrams(double grams) {
    if (grams == grams.roundToDouble()) return grams.toStringAsFixed(1);
    return grams.toString();
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
