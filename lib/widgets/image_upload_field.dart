import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_service.dart';
import 'bean_image.dart';

class ImageUploadField extends ConsumerStatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<String?> onImageUploaded;

  const ImageUploadField({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
  });

  @override
  ConsumerState<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends ConsumerState<ImageUploadField> {
  late TextEditingController _urlController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialImageUrl ?? '');
  }

  @override
  void didUpdateWidget(covariant ImageUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImageUrl != oldWidget.initialImageUrl) {
      _urlController.text = widget.initialImageUrl ?? '';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for Web
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          _isUploading = true;
        });

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uploading image...')),
            );
        }

        final service = ref.read(imageServiceProvider);
        final url = await service.saveImage(file);
        
        setState(() {
          _isUploading = false;
        });

        if (url != null) {
          _urlController.text = url;
          widget.onImageUploaded(url);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                onChanged: (value) => widget.onImageUploaded(value),
              ),
            ),
            const SizedBox(width: 8),
            _isUploading 
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  tooltip: 'Upload Image',
                  onPressed: _pickImage,
                ),
          ],
        ),
        if (_urlController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              height: 100,
              child: BeanImage(imagePath: _urlController.text),
            ),
          ),
      ],
    );
  }
}
