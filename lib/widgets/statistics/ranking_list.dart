import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';
import '../../models/coffee_record.dart';

class RankingList extends ConsumerStatefulWidget {
  final List<CoffeeRecord> records;

  const RankingList({super.key, required this.records});

  @override
  ConsumerState<RankingList> createState() => _RankingListState();
}

class _RankingListState extends ConsumerState<RankingList> {
  String _targetType = 'Bean'; // 'Bean' or 'Method'
  String _metric = 'Rating'; // 'Rating' or 'Count'

  @override
  Widget build(BuildContext context) {
    // 1. Group and Calculate
    final items = _processData();

    return Column(
      children: [
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTypeToggle(),
            const SizedBox(width: 16),
            _buildMetricToggle(),
          ],
        ),
        const SizedBox(height: 8),
        
        // List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRankColor(index),
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(item.name, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text(
                     _metric == 'Rating' ? item.avgScore.toStringAsFixed(1) : '${item.count} brews',
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   ),
                   if (_metric == 'Rating')
                     Text('${item.count} brews', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                   if (_metric == 'Count')
                     Text('Avg: ${item.avgScore.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return ToggleButtons(
      isSelected: [_targetType == 'Bean', _targetType == 'Method'],
      onPressed: (index) {
        setState(() {
          _targetType = index == 0 ? 'Bean' : 'Method';
        });
      },
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Beans')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Methods')),
      ],
    );
  }

  Widget _buildMetricToggle() {
    return ToggleButtons(
      isSelected: [_metric == 'Rating', _metric == 'Count'],
      onPressed: (index) {
        setState(() {
          _metric = index == 0 ? 'Rating' : 'Count';
        });
      },
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.star, size: 20)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.bar_chart, size: 20)),
      ],
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey;
    if (index == 2) return Colors.brown.shade300;
    return Colors.blueGrey;
  }

  List<_RankItem> _processData() {
    final Map<String, List<CoffeeRecord>> groups = {};
    for (var r in widget.records) {
      final key = _targetType == 'Bean' ? r.beanId : r.methodId;
      if (key.isNotEmpty) {
        groups.putIfAbsent(key, () => []).add(r);
      }
    }

    final beans = ref.watch(beanMasterProvider).asData?.value ?? [];
    final methods = ref.watch(methodMasterProvider).asData?.value ?? [];

    String getName(String id) {
       if (_targetType == 'Bean') {
         // dynamic beans
         try {
           final b = beans.firstWhere((e) => e.id == id);
           return b.name;
         } catch (_) {
           return id;
         }
       } else {
         try {
           final m = methods.firstWhere((e) => e.id == id);
           return m.name;
         } catch (_) {
           return id;
         }
       }
    }

    final List<_RankItem> rankItems = [];
    groups.forEach((id, list) {
       final count = list.length;
       final avg = list.fold(0.0, (s, r) => s + r.scoreOverall) / count;
       rankItems.add(_RankItem(id, getName(id), count, avg));
    });

    // Sort
    if (_metric == 'Rating') {
       // Primary: Avg Score (Desc), Secondary: Count (Desc)
       rankItems.sort((a, b) {
          int cmp = b.avgScore.compareTo(a.avgScore);
          if (cmp != 0) return cmp;
          return b.count.compareTo(a.count);
       });
    } else {
       // Primary: Count (Desc), Secondary: Avg Score (Desc)
       rankItems.sort((a, b) {
          int cmp = b.count.compareTo(a.count);
          if (cmp != 0) return cmp;
          return b.avgScore.compareTo(a.avgScore);
       });
    }
    
    // Take Top 5
    return rankItems.take(5).toList();
  }
}

class _RankItem {
  final String id;
  final String name;
  final int count;
  final double avgScore;

  _RankItem(this.id, this.name, this.count, this.avgScore);
}
