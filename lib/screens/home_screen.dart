import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import 'coffee_log_list_screen.dart';
import 'master_list_screen.dart';
import 'calculator_screen.dart';
import 'statistics_screen.dart';
import 'master_detail_screen.dart';
import 'log_detail_screen.dart';

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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (int index) {
              if (index == 0) return; // Already here
              if (index == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeLogListScreen()));
              } else if (index == 2) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterListScreen()));
              } else if (index == 3) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen()));
              } else if (index == 4) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
              }
            },
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list),
                label: Text('Logs'),
              ),
              NavigationRailDestination(
                 icon: Icon(Icons.dataset),
                 label: Text('Masters'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calculate),
                label: Text('Calculator'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('Stats'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: SingleChildScrollView(
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
          ),
        ],
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stockBeans.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bean = stockBeans[index];
                  
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

                  return ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.brown),
                    title: Text(bean.name),
                    subtitle: Text(
                      'Purchased: ${dateFormat(bean.purchaseDate)}\n'
                      'Opened: ${dateFormat(bean.firstUseDate)}\n'
                      'Last Brewed: ${dateFormat(lastUse)}',
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                        title: bean.name,
                        data: bean.toJson(),
                        imageUrl: bean.imageUrl,
                      )));
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => const SizedBox.shrink(),
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
                    leading: CircleAvatar(
                      radius: bubbleRadius > 28 ? 28 : bubbleRadius, // Cap size
                      backgroundColor: Colors.orange,
                      child: Text(
                        '${log.scoreOverall}', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                    title: Text(beanName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${log.brewedAt.year}/${log.brewedAt.month}/${log.brewedAt.day}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.replay, color: Colors.blue),
                      tooltip: 'Reuse Recipe',
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => CalculatorScreen(
                           initialMethodId: log.methodId,
                           initialBeanWeight: log.beanWeight,
                         )));
                      },
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
