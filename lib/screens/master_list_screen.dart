import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';

import 'master_detail_screen.dart';
import 'method_detail_screen.dart';
import 'master_add_screen.dart';

import '../utils/image_utils.dart';
import 'package:file_picker/file_picker.dart';
import '../services/image_service.dart';
import '../widgets/bean_image.dart';

Future<void> _handleImageImport(BuildContext context, WidgetRef ref) async {
  debugPrint("MASTER_SCREEN: Import button pressed (Web/Mobile Compatible Mode)");
  try {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true, 
      type: FileType.image,
    );
    
    if (result == null || result.files.isEmpty) {
      debugPrint("MASTER_SCREEN: Import canceled by user or no files selected.");
      return;
    }
    
    debugPrint("MASTER_SCREEN: Selected ${result.files.length} files.");

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final imageService = ref.read(imageServiceProvider);
    // Pass list of PlatformFile directly to service
    final summary = await imageService.importBeanImages(result.files);

    // Close loading
    if (context.mounted) Navigator.of(context).pop();

    // Show result
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Result'),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
     // Refresh the list - Riverpod FutureProvider should auto-refresh if we invalidate or if the service updates the source.
     // Since SheetsService doesn't use a Stream, we might need to invalidate the provider.
     ref.invalidate(beanMasterProvider);

  } catch (e) {
    debugPrint("MASTER_SCREEN: Error picking files: $e");
    // Close loading if open (tricky to check exact state, but try safely)
    // Usually user sees nothing if pick fails before dialog. 
    // If dialog is open, we should close it, but `context` might be unstable.
    // For now just show error.
    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class MasterListScreen extends ConsumerWidget {
  const MasterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Masters'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              tooltip: 'Import Images (Bulk)',
              onPressed: () async {
                 await _handleImageImport(context, ref);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add New',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MasterAddScreen()));
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Beans'),
              Tab(text: 'Methods'),
              Tab(text: 'Grinders'),
              Tab(text: 'Drippers'),
              Tab(text: 'Filters'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BeanMasterList(),
            MethodMasterList(),
            GrinderMasterList(),
            DripperMasterList(),
            FilterMasterList(),
          ],
        ),
      ),
    );
  }
}

class BeanMasterList extends ConsumerWidget {
  const BeanMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beansAsync = ref.watch(beanMasterProvider);
    return beansAsync.when(
      data: (beans) {
        final visibleBeans = beans.where((b) => b.name != '-' && b.name.isNotEmpty).toList();
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: visibleBeans.length,
          itemBuilder: (context, index) {
            final bean = visibleBeans[index];
            final imageUrl = ImageUtils.getOptimizedImageUrl(bean.imageUrl);
            
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                    title: bean.name,
                    data: bean.toJson(),
                    imageUrl: imageUrl, // Pass optimized URL
                    masterType: 'Bean',
                  )));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'bean-${bean.id}',
                        child: BeanImage(
                          imagePath: imageUrl,
                          placeholderIcon: Icons.coffee,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bean.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('${bean.roastLevel} - ${bean.origin}', style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.brown[50], // Light brown background
      child: Icon(icon, size: 40, color: Colors.brown[300]),
    );
  }
}

class MethodMasterList extends ConsumerWidget {
  const MethodMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(methodMasterProvider);
    return methodsAsync.when(
      data: (methods) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
        ),
        itemCount: methods.length,
        itemBuilder: (context, index) {
          final method = methods[index];
          return Card(
            child: InkWell(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => MethodDetailScreen(
                  method: method,
                )));
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 40, color: Colors.brown),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(method.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class GrinderMasterList extends ConsumerWidget {
  const GrinderMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grindersAsync = ref.watch(grinderMasterProvider);
    return grindersAsync.when(
      data: (grinders) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
        ),
        itemCount: grinders.length,
        itemBuilder: (context, index) {
          final grinder = grinders[index];
          final imageUrl = ImageUtils.getOptimizedImageUrl(grinder.imageUrl);
          
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                  title: grinder.name,
                  data: grinder.toJson(),
                  imageUrl: imageUrl, // Pass optimized URL
                  masterType: 'Grinder',
                )));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'grinder-${grinder.id}',
                      child: BeanImage(
                        imagePath: imageUrl,
                        placeholderIcon: Icons.inventory,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(grinder.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.blueGrey[50], 
      child: Icon(icon, size: 40, color: Colors.blueGrey[300]),
    );
  }
}

class DripperMasterList extends ConsumerWidget {
  const DripperMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drippersAsync = ref.watch(dripperMasterProvider);
    return drippersAsync.when(
      data: (drippers) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
        ),
        itemCount: drippers.length,
        itemBuilder: (context, index) {
           final dripper = drippers[index];
           final imageUrl = ImageUtils.getOptimizedImageUrl(dripper.imageUrl);
           
           return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                  title: dripper.name,
                  data: dripper.toJson(),
                  imageUrl: imageUrl, // Pass optimized URL
                  masterType: 'Dripper',
                )));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'dripper-${dripper.id}',
                      child: BeanImage(
                        imagePath: imageUrl,
                        placeholderIcon: Icons.filter_alt,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dripper.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (dripper.shape != null)
                             Text(dripper.shape!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.orange[50], 
      child: Icon(icon, size: 40, color: Colors.orange[300]),
    );
  }
}

class FilterMasterList extends ConsumerWidget {
  const FilterMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersAsync = ref.watch(filterMasterProvider);
    return filtersAsync.when(
      data: (filters) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
        ),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final imageUrl = ImageUtils.getOptimizedImageUrl(filter.imageUrl);
          
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                  title: filter.name,
                  data: filter.toJson(),
                  imageUrl: imageUrl, // Pass optimized URL
                  masterType: 'Filter',
                )));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Expanded(
                    child: Hero(
                      tag: 'filter-${filter.id}',
                      child: BeanImage(
                        imagePath: imageUrl,
                        placeholderIcon: Icons.coffee_maker,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(filter.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.blue[50], 
      child: Icon(icon, size: 40, color: Colors.blue[300]),
    );
  }
}
