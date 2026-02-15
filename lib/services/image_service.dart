import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../models/bean_master.dart';
import '../services/sheets_service.dart';

class ImageService {
  final Ref ref;

  ImageService(this.ref);

  import 'package:file_picker/file_picker.dart';

  /// Imports images from a list of selected files.
  /// Matches filenames (e.g., "01a78ca6.jpg") to Bean IDs.
  /// Copies matched images to app's local storage and updates Bean data.
  /// Returns a summary string.
  Future<String> importBeanImages(List<PlatformFile> files) async {
    final beanMaster = ref.read(beanMasterProvider).value;
    if (beanMaster == null || beanMaster.isEmpty) {
      return "Error: No bean master data loaded.";
    }

    // Prepare destination directory if NOT on web
    Directory? imagesDir;
    if (!kIsWeb) {
      final appDocDir = await getApplicationDocumentsDirectory();
      imagesDir = Directory(p.join(appDocDir.path, 'bean_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
    }

    int successCount = 0;
    int failCount = 0;
    int skippedCount = 0;
    List<String> errors = [];

    // Map Bean ID to Bean for quick lookup. 
    // Optimization: Check if filename *contains* ID, or vice versa?
    // Current logic: Filename starts with ID.
    final beanMap = {for (var b in beanMaster) b.id: b};

    for (final file in files) {
      final filename = file.name;
      String? matchedId;

      // Find matching ID
      for (var id in beanMap.keys) {
        // Match if filename starts with ID (case insensitive somewhat safe for UUIDs/IDs)
        if (filename.startsWith(id)) {
          matchedId = id;
          break;
        }
      }

      if (matchedId != null) {
        try {
          String newImageUrl;
          
          if (kIsWeb) {
            // Web: Cannot save to local storage. 
            // We can't really persist the image for reload unless uploaded.
            // For now, we will just log success and update with a placeholder or data URI if small.
            // But data URI is heavy. Let's just warn and SKIP updating the bean with a useless path.
            // Or, we could use the blob URL if we had it, but that expires.
            // Compromise: Update with original filename as "reference" but show warning.
            
            // Actually, user wants to verify "Import" works. 
            // We will increment success count but NOT change the URL to something broken.
            // Or maybe set it to "web_imported_placeholder" to show it touched the bean?
            // Let's just log it.
            debugPrint("Simulating import for Web: $filename -> $matchedId");
            successCount++;
            continue; 
          } else {
            // Mobile/Desktop: Copy file
            if (file.path == null) {
              errors.add("Failed to get path for $filename");
              failCount++;
              continue;
            }
            final newPath = p.join(imagesDir!.path, filename);
            // On some platforms pickFiles gives cached path, we copy it to our permanent dir
            await File(file.path!).copy(newPath);
            newImageUrl = newPath;
          }

          // Update Bean (Only on non-web where we have a valid path)
          final bean = beanMap[matchedId]!;
          final updatedBean = bean.copyWith(imageUrl: newImageUrl);
          
          // Helper to find index and update list in provider? 
          // Actually sheetsServiceProvider.updateBean handles backend, but we need to refresh UI?
          // The provider watcher should handle it if we invalidate or update state.
          await ref.read(sheetsServiceProvider).updateBean(updatedBean);
          
          successCount++;
        } catch (e) {
          failCount++;
          errors.add("Failed to process $filename: $e");
        }
      } else {
        skippedCount++;
      }
    }

    String result = "Import Complete.\nSuccess: $successCount\nFailed: $failCount\nSkipped: $skippedCount";
    if (kIsWeb && successCount > 0) {
      result += "\n(Note: Web import is simulation only. Files not saved locally.)";
    }
    if (errors.isNotEmpty) {
      result += "\nErrors:\n${errors.join('\n')}";
    }
    return result;
  }
  
  /// Helper to save a single image (e.g. from picker/camera)
  Future<String?> saveImage(File sourceFile) async {
    if (kIsWeb) return null; // Not supported on web
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDocDir.path, 'bean_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final filename = p.basename(sourceFile.path);
      final newFilename = '${DateTime.now().millisecondsSinceEpoch}_$filename';
      final newPath = p.join(imagesDir.path, newFilename);
      
      await sourceFile.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint("Error saving image: $e");
      return null;
    }
  }
}

final imageServiceProvider = Provider<ImageService>((ref) => ImageService(ref));
