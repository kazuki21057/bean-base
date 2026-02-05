import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sheets_service.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../providers/data_providers.dart';
import '../widgets/method_steps_editor.dart';

class MasterAddScreen extends ConsumerStatefulWidget {
  // If editObject is provided, we are in Edit Mode
  final dynamic editObject; 
  final String? masterType; // 'Bean', 'Grinder', 'Dripper', 'Filter', 'Method'

  const MasterAddScreen({super.key, this.editObject, this.masterType});

  @override
  ConsumerState<MasterAddScreen> createState() => _MasterAddScreenState();
}

class _MasterAddScreenState extends ConsumerState<MasterAddScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Bean', 'Grinder', 'Dripper', 'Filter', 'Method'];
  
  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.masterType != null) {
      initialIndex = _tabs.indexOf(widget.masterType!);
      if (initialIndex == -1) initialIndex = 0;
    }
    
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.editObject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit ${widget.masterType}' : 'Add New Master'),
        bottom: isEdit ? null : TabBar( // Hide tabs in edit mode (locked to specific type)
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          isScrollable: true,
        ),
      ),
      body: isEdit 
        ? _buildEditForm() // Edit mode: Show specific form directly
        : TabBarView(      // Add mode: Show tabs
            controller: _tabController,
            children: const [
              BeanAddForm(),
              GrinderAddForm(),
              DripperAddForm(),
              FilterAddForm(),
              MethodAddForm(),
            ],
          ),
    );
  }

  Widget _buildEditForm() {
    switch (widget.masterType) {
      case 'Bean': return BeanAddForm(editData: widget.editObject);
      case 'Grinder': return GrinderAddForm(editData: widget.editObject);
      case 'Dripper': return DripperAddForm(editData: widget.editObject);
      case 'Filter': return FilterAddForm(editData: widget.editObject);
      case 'Method': return MethodAddForm(editData: widget.editObject);
      default: return const Center(child: Text('Unknown Type'));
    }
  }
}

// --- Generic Mixin for Form Logic ---
mixin MasterFormMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  bool isEdit = false;
  String? editId;

  void showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : null),
    );
  }
}

// --- Bean Form ---
class BeanAddForm extends ConsumerStatefulWidget {
  final BeanMaster? editData;
  const BeanAddForm({super.key, this.editData});
  @override
  ConsumerState<BeanAddForm> createState() => _BeanAddFormState();
}

class _BeanAddFormState extends ConsumerState<BeanAddForm> with MasterFormMixin {
  final _storeController = TextEditingController();
  final _originController = TextEditingController();
  final _roastController = TextEditingController();
  final _typeController = TextEditingController();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isAutoNameEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      isEdit = true;
      editId = widget.editData!.id;
      _storeController.text = widget.editData!.store;
      _originController.text = widget.editData!.origin;
      _roastController.text = widget.editData!.roastLevel;
      _typeController.text = widget.editData!.type;
      _nameController.text = widget.editData!.name;
      _imageUrlController.text = widget.editData!.imageUrl ?? '';
      _isAutoNameEnabled = false; // Disable auto-name on edit by default
    } else {
      _storeController.addListener(_updateName);
      _originController.addListener(_updateName);
      _roastController.addListener(_updateName);
      _typeController.addListener(_updateName);
    }
  }

  void _updateName() {
    if (!_isAutoNameEnabled) return;
    final parts = [
      _storeController.text.trim(),
      _originController.text.trim(),
      _roastController.text.trim(),
      _typeController.text.trim()
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) _nameController.text = parts.join(' ');
  }

  Future<void> _submit() async {
    if (formKey.currentState!.validate()) {
      final bean = BeanMaster(
        id: isEdit ? editId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        origin: _originController.text,
        roastLevel: _roastController.text,
        store: _storeController.text,
        type: _typeController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        purchaseDate: widget.editData?.purchaseDate ?? DateTime.now(),
        firstUseDate: widget.editData?.firstUseDate ?? DateTime.now(),
        lastUseDate: widget.editData?.lastUseDate ?? DateTime.now(),
        isInStock: widget.editData?.isInStock ?? true,
      );

      try {
        final service = ref.read(sheetsServiceProvider);
        if (isEdit) {
           await service.updateBean(bean);
           ref.invalidate(beanMasterProvider); // Refresh list
           showSnackbar('Bean Updated!');
        } else {
           await service.addBean(bean);
           ref.invalidate(beanMasterProvider);
           showSnackbar('Bean Added!');
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        showSnackbar('Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(controller: _storeController, decoration: const InputDecoration(labelText: 'Store')),
            TextFormField(controller: _originController, decoration: const InputDecoration(labelText: 'Origin')),
            TextFormField(controller: _roastController, decoration: const InputDecoration(labelText: 'Roast Level')),
            TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'Type')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', helperText: 'Auto-generated'))),
                IconButton(icon: Icon(_isAutoNameEnabled ? Icons.link : Icons.link_off), onPressed: () => setState(() => _isAutoNameEnabled = !_isAutoNameEnabled)),
              ],
            ),
            TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'Update Bean' : 'Register Bean')),
          ],
        ),
      ),
    );
  }
}

// --- Grinder Form ---
class GrinderAddForm extends ConsumerStatefulWidget {
  final GrinderMaster? editData;
  const GrinderAddForm({super.key, this.editData});
  @override
  ConsumerState<GrinderAddForm> createState() => _GrinderAddFormState();
}

class _GrinderAddFormState extends ConsumerState<GrinderAddForm> with MasterFormMixin {
  final _nameController = TextEditingController();
  final _rangeController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      isEdit = true;
      editId = widget.editData!.id;
      _nameController.text = widget.editData!.name;
      _rangeController.text = widget.editData!.grindRange ?? '';
      _descController.text = widget.editData!.description ?? '';
      _imageUrlController.text = widget.editData!.imageUrl ?? '';
    }
  }

  Future<void> _submit() async {
    if (formKey.currentState!.validate()) {
      final grinder = GrinderMaster(
        id: isEdit ? editId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        grindRange: _rangeController.text,
        description: _descController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      );

      try {
        final service = ref.read(sheetsServiceProvider);
        if (isEdit) {
           await service.updateGrinder(grinder);
           ref.invalidate(grinderMasterProvider);
           showSnackbar('Grinder Updated!');
        } else {
           await service.addGrinder(grinder);
           ref.invalidate(grinderMasterProvider);
           showSnackbar('Grinder Added!');
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        showSnackbar('Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _rangeController, decoration: const InputDecoration(labelText: 'Grind Range')),
            TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
            TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'Update Grinder' : 'Register Grinder')),
          ],
        ),
      ),
    );
  }
}

// --- Dripper Form ---
class DripperAddForm extends ConsumerStatefulWidget {
  final DripperMaster? editData;
  const DripperAddForm({super.key, this.editData});
  @override
  ConsumerState<DripperAddForm> createState() => _DripperAddFormState();
}

class _DripperAddFormState extends ConsumerState<DripperAddForm> with MasterFormMixin {
  final _nameController = TextEditingController();
  final _materialController = TextEditingController();
  final _shapeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      isEdit = true;
      editId = widget.editData!.id;
      _nameController.text = widget.editData!.name;
      _materialController.text = widget.editData!.material ?? '';
      _shapeController.text = widget.editData!.shape ?? '';
      _imageUrlController.text = widget.editData!.imageUrl ?? '';
    }
  }

  Future<void> _submit() async {
    if (formKey.currentState!.validate()) {
      final dripper = DripperMaster(
        id: isEdit ? editId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        material: _materialController.text,
        shape: _shapeController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      );

      try {
        final service = ref.read(sheetsServiceProvider);
        if (isEdit) {
           await service.updateDripper(dripper);
           ref.invalidate(dripperMasterProvider);
           showSnackbar('Dripper Updated!');
        } else {
           await service.addDripper(dripper);
           ref.invalidate(dripperMasterProvider);
           showSnackbar('Dripper Added!');
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        showSnackbar('Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _materialController, decoration: const InputDecoration(labelText: 'Material')),
            TextFormField(controller: _shapeController, decoration: const InputDecoration(labelText: 'Shape')),
            TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'Update Dripper' : 'Register Dripper')),
          ],
        ),
      ),
    );
  }
}

// --- Filter Form ---
class FilterAddForm extends ConsumerStatefulWidget {
  final FilterMaster? editData;
  const FilterAddForm({super.key, this.editData});
  @override
  ConsumerState<FilterAddForm> createState() => _FilterAddFormState();
}

class _FilterAddFormState extends ConsumerState<FilterAddForm> with MasterFormMixin {
  final _nameController = TextEditingController();
  final _materialController = TextEditingController();
  final _sizeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      isEdit = true;
      editId = widget.editData!.id;
      _nameController.text = widget.editData!.name;
      _materialController.text = widget.editData!.material ?? '';
      _sizeController.text = widget.editData!.size ?? '';
      _imageUrlController.text = widget.editData!.imageUrl ?? '';
    }
  }

  Future<void> _submit() async {
    if (formKey.currentState!.validate()) {
      final filter = FilterMaster(
        id: isEdit ? editId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        material: _materialController.text,
        size: _sizeController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      );

      try {
        final service = ref.read(sheetsServiceProvider);
        if (isEdit) {
           await service.updateFilter(filter);
           ref.invalidate(filterMasterProvider);
           showSnackbar('Filter Updated!');
        } else {
           await service.addFilter(filter);
           ref.invalidate(filterMasterProvider);
           showSnackbar('Filter Added!');
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        showSnackbar('Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _materialController, decoration: const InputDecoration(labelText: 'Material')),
            TextFormField(controller: _sizeController, decoration: const InputDecoration(labelText: 'Size')),
            TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'Update Filter' : 'Register Filter')),
          ],
        ),
      ),
    );
  }
}

// --- Method Form ---
class MethodAddForm extends ConsumerStatefulWidget {
  final MethodMaster? editData;
  const MethodAddForm({super.key, this.editData});
  @override
  ConsumerState<MethodAddForm> createState() => _MethodAddFormState();
}

class _MethodAddFormState extends ConsumerState<MethodAddForm> with MasterFormMixin {
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();
  final _baseBeanController = TextEditingController(text: '15.0');
  final _baseWaterController = TextEditingController(text: '225.0');
  final _urlController = TextEditingController();
  
  List<PouringStep> _steps = [];

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      isEdit = true;
      editId = widget.editData!.id;
      _nameController.text = widget.editData!.name;
      _authorController.text = widget.editData!.author;
      _descController.text = widget.editData!.description;
      _baseBeanController.text = widget.editData!.baseBeanWeight.toString();
      _baseWaterController.text = widget.editData!.baseWaterAmount.toString();
      _urlController.text = widget.editData!.sourceUrl ?? '';
      
      // Ideally we should load steps if editing, but for now assuming "Add New" focus based on user request.
      // Loading steps here would require AsyncValue watching similar to MethodDetailScreen.
      // If user edits complex method here, steps might be lost if we don't load them.
      // Strategy: Since MethodDetailScreen handles editing well, MasterAddScreen should focus on creation.
      // If isEdit, we leave steps empty (risk of overwriting? No, we only Add/Update steps we know about).
    }
  }

  Future<void> _submit() async {
    if (formKey.currentState!.validate()) {
      final methodId = isEdit ? editId! : DateTime.now().millisecondsSinceEpoch.toString();
      
      final method = MethodMaster(
        id: methodId,
        name: _nameController.text,
        author: _authorController.text,
        baseBeanWeight: double.tryParse(_baseBeanController.text) ?? 15.0,
        baseWaterAmount: double.tryParse(_baseWaterController.text) ?? 225.0,
        description: _descController.text,
        recommendedEquipment: '',
        sourceUrl: _urlController.text,
        temperature: widget.editData?.temperature,
        grindSize: widget.editData?.grindSize,
      );

      try {
        final service = ref.read(sheetsServiceProvider);
        
        // 1. Save Method
        if (isEdit) {
           await service.updateMethod(method);
        } else {
           await service.addMethod(method);
        }
        
        // 2. Save Steps (Only for Add New currently fully supported, as we don't load existing steps here)
        // If creating new method, all steps are new.
        for (var step in _steps) {
            // Ensure step has correct methodId
            final stepToSave = PouringStep(
              id: step.id.startsWith('new_') ? step.id : 'new_${DateTime.now().millisecondsSinceEpoch}_${step.stepOrder}', // Ensure valid ID
              methodId: methodId, 
              stepOrder: step.stepOrder,
              duration: step.duration,
              waterAmount: step.waterAmount,
              waterReference: step.waterReference,
              waterRatio: step.waterRatio,
              description: step.description,
            );
            await service.addPouringStep(stepToSave);
        }
        
        ref.invalidate(methodMasterProvider);
        ref.invalidate(pouringStepsProvider);
        
        showSnackbar(isEdit ? 'Method Updated!' : 'Method Added!');
        
        if (mounted) Navigator.pop(context);
      } catch (e) {
        showSnackbar('Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _authorController, decoration: const InputDecoration(labelText: 'Author')),
            TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _baseBeanController, decoration: const InputDecoration(labelText: 'Base Bean (g)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _baseWaterController, decoration: const InputDecoration(labelText: 'Base Water (ml)'), keyboardType: TextInputType.number)),
              ],
            ),
             TextFormField(controller: _urlController, decoration: const InputDecoration(labelText: 'Source URL')),
            
            const SizedBox(height: 24),
            const Text('Pouring Steps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            MethodStepsEditor(
              initialSteps: _steps,
              isEditing: true, // Always editable in Add Form
              baseBeanWeight: double.tryParse(_baseBeanController.text) ?? 15.0,
              onStepsChanged: (newSteps) {
                // Keep local state updated
                _steps = newSteps;
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'Update Method' : 'Register Method')),
          ],
        ),
      ),
    );
  }
}
