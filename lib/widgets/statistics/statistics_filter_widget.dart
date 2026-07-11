import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/statistics_service.dart';

/// Cycle 20 T2-6: 見た目をPhase2共通パレット(コーヒートーン)・日本語ラベルへ
/// 統一。フィルタリングロジック自体は変更なし。
class StatisticsFilterWidget extends ConsumerWidget {
  final StatisticsFilter filter;

  const StatisticsFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = filter.dateRange;

    String dateText = '全期間';
    if (dateRange != null) {
      dateText = '${_formatDate(dateRange.start)} 〜 ${_formatDate(dateRange.end)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLatte),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: kMocha),
          const SizedBox(width: 8),
          Text(dateText, style: const TextStyle(fontSize: 13, color: kEspresso)),
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kAccent),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: dateRange != null ? DateTimeRange(start: dateRange.start, end: dateRange.end) : null,
              );
              if (picked != null) {
                ref.read(statisticsFilterProvider.notifier).state =
                    filter.copyWith(dateRange: DateTimePair(picked.start, picked.end));
              }
            },
            child: const Text('期間を変更'),
          ),
          if (dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: kMocha, size: 20),
              tooltip: '期間指定を解除',
              onPressed: () {
                ref.read(statisticsFilterProvider.notifier).state =
                    filter.copyWith(dateRange: null);
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month}/${d.day}';
  }
}
