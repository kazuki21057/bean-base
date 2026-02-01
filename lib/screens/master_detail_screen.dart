import 'package:flutter/material.dart';

class MasterDetailScreen extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final String? imageUrl;

  const MasterDetailScreen({
    super.key,
    required this.title,
    required this.data,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
