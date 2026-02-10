import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/statistics_service.dart';

class StatisticsFilterWidget extends ConsumerWidget {
  final StatisticsFilter filter;

  const StatisticsFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateRange = filter.dateRange;

    String dateText = 'All Time';
    if (dateRange != null) {
      dateText = '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(dateText, style: theme.textTheme.bodyMedium),
            const Spacer(),
            TextButton(
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
              child: const Text('Change'),
            ),
            if (dateRange != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  ref.read(statisticsFilterProvider.notifier).state = 
                      filter.copyWith(dateRange: null);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month}/${d.day}';
  }
}
