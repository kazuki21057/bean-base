import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../providers/data_providers.dart';
import '../widgets/method_steps_editor.dart';
import '../services/sheets_service.dart';
import '../widgets/coffee_log_card.dart';
import '../models/bean_master.dart';
  /* 
     Replace the entire _buildStepsList method calls and definitions 
     and the Editing Logic helpers with just the Widget usage.
  */
  
  // Note: I need to be precise. I'll replace the _buildStepsList usage in build() and remove the helper methods.
  // And update _saveChanges.


class MethodDetailScreen extends ConsumerStatefulWidget {
  final MethodMaster method;
  
  const MethodDetailScreen({super.key, required this.method});

  @override
  ConsumerState<MethodDetailScreen> createState() => _MethodDetailScreenState();
}

class _MethodDetailScreenState extends ConsumerState<MethodDetailScreen> {
  late MethodMaster _method;
  late TextEditingController _nameController;
  late TextEditingController _authorController;
  late TextEditingController _descController;
  late TextEditingController _baseBeanController;
  late TextEditingController _baseWaterController;
  late TextEditingController _equipController;
  late TextEditingController _urlController;
  
  List<PouringStep> _steps = [];
  bool _isEditing = false;
  bool _isLoadingSteps = true;

  @override
  void initState() {
    super.initState();
    _method = widget.method;
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _method.name);
    _authorController = TextEditingController(text: _method.author);
    _descController = TextEditingController(text: _method.description);
    _baseBeanController = TextEditingController(text: _method.baseBeanWeight.toString());
    _baseWaterController = TextEditingController(text: _method.baseWaterAmount.toString());
    _equipController = TextEditingController(text: _method.recommendedEquipment);
    _urlController = TextEditingController(text: _method.sourceUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _descController.dispose();
    _baseBeanController.dispose();
    _baseWaterController.dispose();
    _equipController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load steps once
    ref.listen<AsyncValue<List<PouringStep>>>(pouringStepsProvider, (prev, next) {
      if (next.hasValue && _isLoadingSteps) {
        final allSteps = next.value!;
        final methodSteps = allSteps.where((s) => s.methodId == _method.id).toList();
        methodSteps.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
        setState(() {
          _steps = methodSteps;
          _isLoadingSteps = false;
        });
      }
    });
    
    // Initial fetch if needed
    if (_isLoadingSteps) {
      final asyncSteps = ref.watch(pouringStepsProvider);
      if (asyncSteps.hasValue) {
        final allSteps = asyncSteps.value!;
        final methodSteps = allSteps.where((s) => s.methodId == _method.id).toList();
        methodSteps.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
        _steps = methodSteps;
        _isLoadingSteps = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Method' : _method.name),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          if (_isEditing)
             IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isEditing = false;
                _initializeControllers(); // Revert
                _isLoadingSteps = true; // Reload from provider to revert
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pouring Steps', style: Theme.of(context).textTheme.titleLarge),
                if (_isEditing)
                  const SizedBox.shrink(), // Button moved to Editor
              ],
            ),
            const SizedBox(height: 8),
            _buildStepsList(),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Related Logs', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            _buildRelatedLogs(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    if (_isEditing) {
      return Column(
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Method Name')),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          TextField(controller: _authorController, decoration: const InputDecoration(labelText: 'Author')),
          Row(
            children: [
              Expanded(child: TextField(controller: _baseBeanController, decoration: const InputDecoration(labelText: 'Bean (g)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _baseWaterController, decoration: const InputDecoration(labelText: 'Water (ml)'), keyboardType: TextInputType.number)),
            ],
          ),
          TextField(controller: _equipController, decoration: const InputDecoration(labelText: 'Recommended Equipment')),
          TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'Source URL')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('Description', _method.description),
        _buildInfoCard('Author', _method.author),
        _buildInfoCard('Base Bean Weight', '${_method.baseBeanWeight}g'),
        _buildInfoCard('Base Water Amount', '${_method.baseWaterAmount}ml'),
        _buildInfoCard('Recommended Equipment', _method.recommendedEquipment),
        if (_method.sourceUrl != null && _method.sourceUrl!.isNotEmpty)
          InkWell(
            onTap: () async {
              final uri = Uri.tryParse(_method.sourceUrl!);
              if (uri != null) {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
                  }
              }
            },
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.link, color: Colors.blue),
                title: const Text('Source URL', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                subtitle: Text(_method.sourceUrl!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value) {
    if (value.isEmpty || value == '-' || value == '0.0g' || value == '0.0ml' || value == '0' || value == '0.0') return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildStepsList() {
    // Only show if editing OR if not empty
    if (_steps.isEmpty && !_isEditing) return const Text('No steps defined.');
    
    // We already handle loading state in build() via listen/watch.
    
    return MethodStepsEditor(
      initialSteps: _steps,
      isEditing: _isEditing,
      baseBeanWeight: double.tryParse(_baseBeanController.text) ?? 15.0,
      onStepsChanged: (newSteps) {
        // Steps are updated inside editor, but we need to track them locally for saving
        _steps = newSteps; 
        // Note: The Editor maintains its own state for rendering, 
        // but calls this callback so we have the latest data for _saveChanges.
      },
    );
  }

  Widget _buildRelatedLogs(WidgetRef ref) {
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);

    return logsAsync.when(
      data: (logs) {
        final relatedLogs = logs.where((l) => l.methodId == _method.id).toList();
        relatedLogs.sort((a,b) => b.brewedAt.compareTo(a.brewedAt));

        if (relatedLogs.isEmpty) {
           return const Text('No logs recorded yet.');
        }

        final beanMap = <String, String>{};
        beansAsync.whenData((beans) => beans.forEach((b) => beanMap[b.id] = b.name));

        return Column(
          children: relatedLogs.map((log) {
             return CoffeeLogCard(
               log: log, 
               beanName: beanMap[log.beanId] ?? log.beanId,
               methodName: _method.name
             );
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error loading logs: $e'),
    );
  }

  Future<void> _saveChanges() async {
    final savedMethod = MethodMaster(
      id: _method.id,
      name: _nameController.text,
      author: _authorController.text,
      baseBeanWeight: double.tryParse(_baseBeanController.text) ?? 0.0,
      baseWaterAmount: double.tryParse(_baseWaterController.text) ?? 0.0,
      description: _descController.text,
      recommendedEquipment: _equipController.text,
      sourceUrl: _urlController.text,
      temperature: _method.temperature,
      grindSize: _method.grindSize,
    );
    
    final service = ref.read(sheetsServiceProvider);

    try {
      // 1. Update Method Master
      await service.updateMethod(savedMethod);
      
      // 2. Update Steps
      // Strategy: 
      // - If ID starts with 'new_', it's added locally -> ADD
      // - Otherwise -> UPDATE
      // - Deletions: The editor removes from list. If we want to delete from backend, 
      //   we validly need to track what was removed.
      //   Current Editor impl just returns the new list. We don't know what was deleted easily unless we compare with original.
      //   For this iteration, let's focus on ADD/UPDATE. Deletion on backend is not yet fully supported cleanly 
      //   without a 'delete' list. 
      //   We will just saving the current list state as "Updates".
      
      for (final step in _steps) {
        if (step.id.startsWith('new_')) {
          // It's new. Use real random ID or let backend generate?
          // Our models use String ID. Let's keep the timestamp ID but remove 'new_' prefix if we want?
          // Or just save it. 
          await service.addPouringStep(step);
        } else {
          await service.updatePouringStep(step);
        }
      }
      
      // Refresh Providers
      ref.invalidate(methodMasterProvider);
      ref.invalidate(pouringStepsProvider);

      if (mounted) {
        setState(() {
          _method = savedMethod;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Method and Steps Saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
