import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import 'log_detail_screen.dart';

import 'calculator_screen.dart';
import '../widgets/coffee_log_card.dart';


class CoffeeLogListScreen extends ConsumerWidget {
  const CoffeeLogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Coffee Logs'),
      ),
      body: logsAsync.when(
        data: (logs) {
          // Filter logs with minimal valid data
          final validLogs = logs.where((l) => l.methodId.isNotEmpty && l.totalTime > 0).toList();
          
          // Sort desc
          validLogs.sort((a,b) => b.brewedAt.compareTo(a.brewedAt));

          if (validLogs.isEmpty) {
            return const Center(child: Text('No logs available.'));
          }

          // Prepare Maps for lookup
          final beanMap = <String, String>{};
          beansAsync.whenData((beans) {
            for (var b in beans) beanMap[b.id] = b.name;
          });
          
          final methodMap = <String, String>{};
          methodsAsync.whenData((methods) {
            for (var m in methods) methodMap[m.id] = m.name;
          });

          return ListView.builder(
            itemCount: validLogs.length,
            itemBuilder: (context, index) {
              final log = validLogs[index];
              final beanName = beanMap[log.beanId] ?? log.beanId;
              final methodName = methodMap[log.methodId] ?? log.methodId;

              return Dismissible(
                key: Key(log.id),
                direction: DismissDirection.endToStart, // Swipe Left
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Copy Recipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.copy, color: Colors.white),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  // Navigate to Calculator with params
                  await Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => CalculatorScreen(
                        initialMethodId: log.methodId,
                        initialBeanWeight: log.beanWeight,
                      )
                    )
                  );
                  // Return false to prevent item being removed from list
                  return false;
                },
                child: CoffeeLogCard(
                  log: log,
                  beanName: beanName,
                  methodName: methodName,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }


}
