import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sheets_service.dart';
import '../models/bean_master.dart';

class MasterAddScreen extends ConsumerStatefulWidget {
  const MasterAddScreen({super.key});

  @override
  ConsumerState<MasterAddScreen> createState() => _MasterAddScreenState();
}

class _MasterAddScreenState extends ConsumerState<MasterAddScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Bean', 'Grinder', 'Dripper', 'Filter']; // Method is usually fixed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Master'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BeanAddForm(),
          Center(child: Text('Grinder Registration - Coming Soon')),
          Center(child: Text('Dripper Registration - Coming Soon')),
          Center(child: Text('Filter Registration - Coming Soon')),
        ],
      ),
    );
  }
}

class BeanAddForm extends ConsumerStatefulWidget {
  const BeanAddForm({super.key});

  @override
  ConsumerState<BeanAddForm> createState() => _BeanAddFormState();
}

class _BeanAddFormState extends ConsumerState<BeanAddForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _storeController = TextEditingController();
  final _originController = TextEditingController();
  final _roastController = TextEditingController(); // Could be dropdown
  final _typeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isAutoNameEnabled = true;

  @override
  void initState() {
    super.initState();
    // Add listeners for auto-naming
    _storeController.addListener(_updateName);
    _originController.addListener(_updateName);
    _roastController.addListener(_updateName);
    _typeController.addListener(_updateName);
  }

  void _updateName() {
    if (!_isAutoNameEnabled) return;
    
    final store = _storeController.text.trim();
    final origin = _originController.text.trim();
    final roast = _roastController.text.trim();
    final type = _typeController.text.trim();

    final parts = [store, origin, roast, type].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      _nameController.text = parts.join(' ');
    }
  }

  @override
  void dispose() {
    _storeController.dispose();
    _originController.dispose();
    _roastController.dispose();
    _typeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Create Bean Object
      final newBean = BeanMaster(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID generation
        name: _nameController.text,
        origin: _originController.text,
        roastLevel: _roastController.text,
        store: _storeController.text,
        type: _typeController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        purchaseDate: DateTime.now(), // Default to today
        firstUseDate: DateTime.now(),
        lastUseDate: DateTime.now(),
        isInStock: true,
      );

      // Call Service
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registering...')),
        );
        
        await ref.read(sheetsServiceProvider).addBean(newBean);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bean Registered Successfully!')),
          );
          Navigator.pop(context); // Close screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Basic Info'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _storeController,
              decoration: const InputDecoration(labelText: 'Store (e.g. Blue Bottle)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _originController,
                    decoration: const InputDecoration(labelText: 'Origin (e.g. Ethiopia)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _roastController,
                    decoration: const InputDecoration(labelText: 'Roast (e.g. Light)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type (e.g. Yirgacheffe G1)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            
            _buildSectionHeader('Generated Name'),
            const SizedBox(height: 5),
             Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bean Name',
                      border: OutlineInputBorder(),
                      helperText: 'Auto-generated from above fields',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                ),
                IconButton(
                  icon: Icon(_isAutoNameEnabled ? Icons.link : Icons.link_off),
                  onPressed: () {
                    setState(() {
                      _isAutoNameEnabled = !_isAutoNameEnabled;
                    });
                  },
                  tooltip: 'Toggle Auto-Naming',
                )
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionHeader('Optional'),
            const SizedBox(height: 10),
             TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Register Bean'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        const Icon(Icons.coffee, size: 20, color: Colors.brown),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
        const Expanded(child: Divider(indent: 10, thickness: 1)),
      ],
    );
  }
}
