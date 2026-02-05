import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart'; // Add
import '../providers/data_providers.dart';
import 'log_edit_screen.dart'; // Add

import '../utils/image_utils.dart';

class LogDetailScreen extends ConsumerWidget {
  final CoffeeRecord log;

  const LogDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch masters for name resolution
    final beansAsync = ref.watch(beanMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);
    final grindersAsync = ref.watch(grinderMasterProvider);
    final drippersAsync = ref.watch(dripperMasterProvider);
    final filtersAsync = ref.watch(filterMasterProvider);

    // Resolution helpers
    String resolve(String id, AsyncValue<List<dynamic>> asyncValue) {
      if (id.isEmpty) return '-';
      return asyncValue.maybeWhen(
        data: (list) {
          for (final item in list) {
            if (item.id == id) return item.name;
          }
          return id;
        },
        orElse: () => id,
      );
    }
    
    final beanName = resolve(log.beanId, beansAsync);
    final methodName = resolve(log.methodId, methodsAsync);
    final grinderName = resolve(log.grinderId, grindersAsync);
    final dripperName = resolve(log.dripperId, drippersAsync);
    final filterName = resolve(log.filterId, filtersAsync);

    // Resolve Image URL
    String? imageUrl = log.beanImageUrl;
    if ((imageUrl == null || imageUrl.isEmpty) && log.beanId.isNotEmpty) {
      beansAsync.whenData((beans) {
        final bean = beans.firstWhere((b) => b.id == log.beanId, orElse: () => BeanMaster(id: '', name: '', roastLevel: '', origin: '', store: '', type: '', purchaseDate: DateTime.now(), firstUseDate: DateTime.now(), lastUseDate: DateTime.now(), isInStock: false));
        if (bean.id.isNotEmpty) {
           imageUrl = bean.imageUrl;
        }
      });
    }
    final optimizedImageUrl = ImageUtils.getOptimizedImageUrl(imageUrl);

    return Scaffold(
        appBar: AppBar(
          title: Text('$beanName - ${_formatDate(log.brewedAt)}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LogEditScreen(log: log)));
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (optimizedImageUrl != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(optimizedImageUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                ),
                
              _buildSection(context, 'Basic Info', [
                _buildRow('Brewed At', log.brewedAt.toString().split('.')[0]),
                _buildRow('Bean', beanName),
                _buildRow('Method', methodName),
                _buildRow('Grinder', grinderName),
                _buildRow('Dripper', dripperName),
                _buildRow('Filter', filterName),
              ]),
              _buildSection(context, 'Parameters', [
                _buildRow('Bean Weight', '${log.beanWeight}g'),
                _buildRow('Water Temp', '${log.temperature}°C'),
                _buildRow('Total Water', '${log.totalWater}ml'),
                _buildRow('Total Time', _formatTime(log.totalTime)),
                _buildRow('Grind Size', log.grindSize),
              ]),
              _buildSection(context, 'Evaluation', [
                _buildRow('Fragrance', '${log.scoreFragrance}', allowZero: true),
                _buildRow('Acidity', '${log.scoreAcidity}', allowZero: true),
                _buildRow('Bitterness', '${log.scoreBitterness}', allowZero: true),
                _buildRow('Sweetness', '${log.scoreSweetness}', allowZero: true),
                _buildRow('Complexity', '${log.scoreComplexity}', allowZero: true),
                _buildRow('Flavor', '${log.scoreFlavor}', allowZero: true),
                _buildRow('Overall', '${log.scoreOverall}', allowZero: true),
              ]),
              _buildSection(context, 'Notes', [
                Text(log.comment.isEmpty ? 'No comments' : log.comment),
                const SizedBox(height: 8),
                Text('Taste: ${log.taste}'),
                Text('Concentration: ${log.concentration}'),
              ]),
            ],
          ),
        ),
      );
  }

  String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    // Filter out empty children (SizedBox.shrink)
    // Actually, Column handles them fine, but if all are empty, maybe hide section?
    // For now, consistent spacing.
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool allowZero = false}) {
    if (value.isEmpty || value == '-' || value == 'null') {
      return const SizedBox.shrink();
    }
    if (!allowZero && (value == '0' || value == '0.0')) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
