import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import 'coffee_log_list_screen.dart';

import '../screens/calculator_screen.dart';
import 'master_detail_screen.dart';
import 'log_detail_screen.dart';

import '../utils/image_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentLogsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BeanBase 2.0'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(coffeeRecordsProvider);
              ref.refresh(beanMasterProvider);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildInventorySection(context, beansAsync, recentLogsAsync),
            const SizedBox(height: 16),
            _buildRecentLogsSection(context, recentLogsAsync, beansAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(
      BuildContext context, AsyncValue<List<dynamic>> beansAsync, AsyncValue<List<dynamic>> logsAsync) {
    return beansAsync.when(
      data: (beans) {
        // Filter in-stock beans
        final stockBeans = beans.where((b) => b.isInStock).toList();
        
        if (stockBeans.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Inventory (Beans in Stock)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: stockBeans.length,
                itemBuilder: (context, index) {
                  final bean = stockBeans[index];
                  final imageUrl = ImageUtils.getOptimizedImageUrl(bean.imageUrl);
                  
                  // Calculate Last Use Date
                  DateTime? lastUse;
                  if (logsAsync.hasValue) {
                     final logs = logsAsync.value!;
                     final beanLogs = logs.where((l) => l.beanId == bean.id).toList();
                     if (beanLogs.isNotEmpty) {
                       beanLogs.sort((a,b) => b.brewedAt.compareTo(a.brewedAt));
                       lastUse = beanLogs.first.brewedAt;
                     }
                  }
                  
                  final dateFormat = (DateTime? d) => d != null ? '${d.year}/${d.month}/${d.day}' : '-';

                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                          title: bean.name,
                          data: bean.toJson(),
                          imageUrl: imageUrl, // Pass optimized
                          masterType: 'Bean',
                        )));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: imageUrl != null 
                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.brown[50], child: Icon(Icons.coffee, color: Colors.brown[300])))
                                : Container(color: Colors.brown[50], child: Icon(Icons.coffee, color: Colors.brown[300])),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bean.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Last: ${dateFormat(lastUse)}', style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.brown[50], 
      child: Icon(icon, size: 40, color: Colors.brown[300]),
    );
  }

  Widget _buildRecentLogsSection(
      BuildContext context, AsyncValue<List<dynamic>> logsAsync, AsyncValue<List<dynamic>> beansAsync) {
    return logsAsync.when(
      data: (logs) {
        // Filter invalid logs
        final validLogs = logs.where((l) {
             return l.methodId.isNotEmpty && l.totalTime > 0 && l.beanId.isNotEmpty;
        }).toList();

        if (validLogs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent brews found.'),
            ),
          );
        }
        
        validLogs.sort((a,b) => b.brewedAt.compareTo(a.brewedAt));
        final recentLogs = validLogs.take(5).toList();

        final Map<String, String> beanNames = {};
        if (beansAsync.hasValue) {
           for(var b in beansAsync.value!) {
              beanNames[b.id] = b.name;
           }
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recent Brews',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLogs.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final log = recentLogs[index];
                  final beanName = beanNames[log.beanId] ?? log.beanId;
                  
                  final double bubbleRadius = 12.0 + (log.scoreOverall * 1.5);
                  
                  return ListTile(
                    leading: null,
                    title: Text(beanName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${log.brewedAt.year}/${log.brewedAt.month}/${log.brewedAt.day} ${log.brewedAt.hour}:${log.brewedAt.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${log.scoreOverall}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay, color: Colors.blue),
                          tooltip: 'Reuse Recipe',
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => CalculatorScreen(
                               initialMethodId: log.methodId,
                               initialBeanWeight: log.beanWeight,
                             )));
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)));
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoffeeLogListScreen()));
                  },
                  child: const Text('View All Logs'),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
