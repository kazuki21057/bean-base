import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';

import 'master_detail_screen.dart';
import 'method_detail_screen.dart';
import 'master_add_screen.dart';

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
              icon: const Icon(Icons.add),
              tooltip: 'Add New',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterAddScreen()));
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
        return ListView.builder(
          itemCount: visibleBeans.length,
          itemBuilder: (context, index) {
            final bean = visibleBeans[index];
            return ListTile(
              leading: bean.imageUrl != null ? Image.network(bean.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.coffee)) : const Icon(Icons.coffee),
              title: Text(bean.name),
              subtitle: Text('${bean.roastLevel} - ${bean.origin}'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                  title: bean.name,
                  data: bean.toJson(),
                  imageUrl: bean.imageUrl,
                )));
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class MethodMasterList extends ConsumerWidget {
  const MethodMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(methodMasterProvider);
    return methodsAsync.when(
      data: (methods) => ListView.builder(
        itemCount: methods.length,
        itemBuilder: (context, index) {
          final method = methods[index];
          return ListTile(
            title: Text(method.name),
            subtitle: Text(method.description),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => MethodDetailScreen(
                method: method,
              )));
            },
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
      data: (grinders) => ListView.builder(
        itemCount: grinders.length,
        itemBuilder: (context, index) {
          final grinder = grinders[index];
          return ListTile(
            leading: grinder.imageUrl != null ? Image.network(grinder.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.build)) : const Icon(Icons.build),
            title: Text(grinder.name),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                title: grinder.name,
                data: grinder.toJson(),
                imageUrl: grinder.imageUrl,
              )));
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class DripperMasterList extends ConsumerWidget {
  const DripperMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drippersAsync = ref.watch(dripperMasterProvider);
    return drippersAsync.when(
      data: (drippers) => ListView.builder(
        itemCount: drippers.length,
        itemBuilder: (context, index) {
           final dripper = drippers[index];
           return ListTile(
            leading: dripper.imageUrl != null ? Image.network(dripper.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.filter_alt)) : const Icon(Icons.filter_alt),
            title: Text(dripper.name),
            subtitle: Text(dripper.shape ?? ''),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                title: dripper.name,
                data: dripper.toJson(),
                imageUrl: dripper.imageUrl,
              )));
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class FilterMasterList extends ConsumerWidget {
  const FilterMasterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersAsync = ref.watch(filterMasterProvider);
    return filtersAsync.when(
      data: (filters) => ListView.builder(
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return ListTile(
            leading: filter.imageUrl != null ? Image.network(filter.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.coffee_maker)) : const Icon(Icons.coffee_maker),
            title: Text(filter.name),
            subtitle: Text('Material: ${filter.material ?? '-'} / Size: ${filter.size ?? '-'}'),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDetailScreen(
                title: filter.name,
                data: filter.toJson(),
                imageUrl: filter.imageUrl,
              )));
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
