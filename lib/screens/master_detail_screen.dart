import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../providers/data_providers.dart';
import '../widgets/coffee_log_card.dart';
import '../widgets/bean_image.dart';
import 'master_add_screen.dart';
import '../services/sheets_service.dart';
import '../services/image_service.dart';

class MasterDetailScreen extends ConsumerWidget {
  final String title;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String masterType;

  const MasterDetailScreen({
    super.key,
    required this.title,
    required this.data,
    required this.masterType,
    this.imageUrl,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting...')));
      try {
        if (imageUrl != null && imageUrl!.isNotEmpty) {
           await ref.read(imageServiceProvider).deleteImage(imageUrl!);
        }
        
        final service = ref.read(sheetsServiceProvider);
        final id = data['id'].toString();
        
        if (masterType == 'Bean') {
          await service.deleteBean(id);
          ref.invalidate(beanMasterProvider);
        } else if (masterType == 'Grinder') {
          await service.deleteGrinder(id);
          ref.invalidate(grinderMasterProvider);
        } else if (masterType == 'Dripper') {
          await service.deleteDripper(id);
          ref.invalidate(dripperMasterProvider);
        } else if (masterType == 'Filter') {
          await service.deleteFilter(id);
          ref.invalidate(filterMasterProvider);
        }
        
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
           Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final methodsAsync = ref.watch(methodMasterProvider);
    final beansAsync = ref.watch(beanMasterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              dynamic obj;
              try {
                if (masterType == 'Bean') {
                   obj = BeanMaster.fromJson(data);
                } else if (masterType == 'Grinder') {
                   obj = GrinderMaster.fromJson(data);
                } else if (masterType == 'Dripper') {
                   obj = DripperMaster.fromJson(data);
                } else if (masterType == 'Filter') {
                   obj = FilterMaster.fromJson(data);
                }
              } catch (e) {
                print('Error reconstructing object: $e');
              }

              if (obj != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MasterAddScreen(
                  masterType: masterType,
                  editObject: obj,
                )));
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot edit this item (parsing failed)')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Hero(
                  tag: '${masterType.toLowerCase()}-${data['id']}',
                  child: BeanImage(
                    imagePath: imageUrl,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.broken_image,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...data.entries.map((e) {
                    if (e.key == 'imageUrl' || e.key == 'id') return const SizedBox.shrink();
                    
                    String displayValue = e.value?.toString() ?? '-';
                    if ((e.key.contains('Date') || e.key.contains('日')) && displayValue.contains('T')) {
                       try {
                          final dt = DateTime.parse(displayValue);
                          displayValue = '${dt.year}/${dt.month}/${dt.day}';
                       } catch (_) {}
                    }

                    return Card(
                      child: ListTile(
                        title: Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(displayValue),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                  Text('Related Logs', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),

                  logsAsync.when(
                    data: (logs) {
                      final id = data['id'].toString();
                      final relatedLogs = logs.where((l) {
                        if (masterType == 'Bean') return l.beanId == id;
                        if (masterType == 'Grinder') return l.grinderId == id;
                        if (masterType == 'Dripper') return l.dripperId == id;
                        if (masterType == 'Filter') return l.filterId == id;
                        return false;
                      }).toList();
                      
                      // Sort by date desc
                      relatedLogs.sort((a,b) => b.brewedAt.compareTo(a.brewedAt));

                      if (relatedLogs.isEmpty) {
                         return const Text('No logs recorded yet.');
                      }

                      // We need maps for names
                      final methodMap = <String, String>{};
                      methodsAsync.whenData((methods) => methods.forEach((m) => methodMap[m.id] = m.name));
                      final beanMap = <String, String>{};
                      beansAsync.whenData((beans) => beans.forEach((b) => beanMap[b.id] = b.name));

                      return Column(
                        children: relatedLogs.map((log) {
                           return CoffeeLogCard(
                             log: log, 
                             beanName: beanMap[log.beanId] ?? log.beanId, // Use map for Bean
                             methodName: methodMap[log.methodId] ?? log.methodId
                           );
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('Error loading logs: $e'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
