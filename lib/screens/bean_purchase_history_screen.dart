import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/bean_master.dart';
import '../models/bean_purchase.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'bean_detail_screen.dart';
import 'mock/mock_scaffold.dart';

/// 025 購入履歴(閲覧専用)。
///
/// T3-64(`docs/bean_purchase_design.md`§6.1〜§6.3)でリスト形式、
/// T3-65(同書§6.2・§6.4)でカレンダー形式を実装。
enum _PurchaseViewMode { list, calendar }

/// カレンダーのイベントキー正規化(T3-65 地雷(b)対策)。
/// `DateTime`の等価比較は時刻まで含むため、`purchasedAt`をそのままキーにすると
/// `eventLoader`が絶対に一致しない。作る時も引く時も必ずこの関数を通すこと。
DateTime purchaseDayKey(DateTime d) => DateTime.utc(d.year, d.month, d.day);

class BeanPurchaseHistoryScreen extends ConsumerStatefulWidget {
  const BeanPurchaseHistoryScreen({super.key});

  @override
  ConsumerState<BeanPurchaseHistoryScreen> createState() =>
      _BeanPurchaseHistoryScreenState();
}

class _BeanPurchaseHistoryScreenState
    extends ConsumerState<BeanPurchaseHistoryScreen> {
  _PurchaseViewMode _mode = _PurchaseViewMode.list;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedDay = DateTime.utc(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
  }

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
              ButtonSegment(
                value: _PurchaseViewMode.calendar,
                icon: Icon(Icons.calendar_month),
                label: Text('カレンダー'),
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
            return _mode == _PurchaseViewMode.list
                ? _buildList(purchases, beans)
                : _buildCalendar(purchases, beans);
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

  Widget _buildList(List<BeanPurchase> purchases, List<BeanMaster> beans) {
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
  }

  Widget _buildCalendar(List<BeanPurchase> purchases, List<BeanMaster> beans) {
    final byDay = <DateTime, List<BeanPurchase>>{};
    DateTime? earliest;
    for (final purchase in purchases) {
      final date = purchase.purchasedAt;
      if (date == null) continue;
      final key = purchaseDayKey(date);
      byDay.putIfAbsent(key, () => []).add(purchase);
      if (earliest == null || key.isBefore(earliest)) earliest = key;
    }
    final today = DateTime.now();
    final firstDay = earliest ?? DateTime.utc(today.year - 1, 1, 1);
    final lastDay = DateTime.utc(today.year + 1, today.month, today.day);

    final selectedKey = _selectedDay;
    final selectedPurchases = selectedKey == null
        ? const <BeanPurchase>[]
        : (byDay[purchaseDayKey(selectedKey)] ?? const <BeanPurchase>[]);
    final sortedSelected = [...selectedPurchases]
      ..sort((a, b) {
        final ad = a.purchasedAt;
        final bd = b.purchasedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

    return Column(
      children: [
        TableCalendar<BeanPurchase>(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: _focusedDay,
          locale: 'ja_JP',
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: '月'},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: (day) =>
              byDay[purchaseDayKey(day)] ?? const <BeanPurchase>[],
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            selectedKey == null
                ? '購入内訳'
                : '${_PurchaseRow._formatDate(selectedKey)} の購入',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (sortedSelected.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('この日の購入はありません')),
          )
        else
          Column(
            children: [
              for (final purchase in sortedSelected)
                _PurchaseRow(
                  purchase: purchase,
                  bean: _findBean(beans, purchase.beanId),
                ),
            ],
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
