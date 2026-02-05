import 'package:flutter/material.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import 'master_add_screen.dart';

class MasterDetailScreen extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String masterType; // Added to identify type for editing

  const MasterDetailScreen({
    super.key,
    required this.title,
    required this.data,
    required this.masterType, // Required now
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Reconstruct object from Map? 
              // Ideally validation should be done, but we can pass the map or reconstruct object.
              // MasterAddScreen expects an Object (BeanMaster etc.) for editing.
              // So we need to reconstruct it here or pass the raw map and let MasterAddScreen handle it?
              // MasterAddScreen currently expects Objects (BeanMaster etc.) in `editData`.
              // So we must reconstruct.
              
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
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image, size: 50));
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: data.entries.map((e) {
                  if (e.key == 'imageUrl' || e.key == 'id') return const SizedBox.shrink(); // Skip internal or already shown
                  
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
