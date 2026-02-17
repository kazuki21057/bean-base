import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/image_service.dart';

class FirebaseTestScreen extends ConsumerStatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  ConsumerState<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends ConsumerState<FirebaseTestScreen> {
  String? _uploadedUrl;
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickAndUpload() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _uploadedUrl = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Needed for Web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final service = ref.read(imageServiceProvider);
        
        // Use the uploadImage method directly
        final url = await service.uploadImage(file);
        
        if (url != null) {
          setState(() {
            _uploadedUrl = url;
          });
        } else {
          setState(() {
            _errorMessage = 'Upload returned null (Check console)';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Storage Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Pick & Upload Image'),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const Text('Uploading...'),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            if (_uploadedUrl != null) ...[
              const SizedBox(height: 20),
              const Text('Upload Success!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              SelectableText(_uploadedUrl!),
              const SizedBox(height: 20),
              Expanded(
                child: Image.network(
                  _uploadedUrl!,
                  loadingBuilder: (ctx, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (ctx, error, stackTrace) => const Text('Failed to load image'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
