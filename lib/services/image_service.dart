import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../models/bean_master.dart';
import '../services/sheets_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageService {
  final Ref ref;

  ImageService(this.ref);

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String?> uploadImage(PlatformFile file) async {
    try {
      // Check if Firebase is initialized properly
      if (Firebase.apps.isEmpty) {
        debugPrint("Firebase not initialized. Falling back to local/original path.");
        return kIsWeb ? file.name : file.path;
      }

      final storageRef = FirebaseStorage.instance.ref();
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final imageRef = storageRef.child('bean_images/$filename');

      if (kIsWeb) {
        if (file.bytes == null) return null;
        await imageRef.putData(file.bytes!, SettableMetadata(contentType: 'image/jpeg')); // Assume jpeg/png
      } else {
        if (file.path == null) return null;
        final File ioFile = File(file.path!);
        await imageRef.putFile(ioFile);
      }

      final downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  /// Imports images from a list of selected files.
  /// Matches filenames to Master IDs (Bean, Grinder, Dripper, Filter).
  /// Copies matched images to app's local storage or uploads to Firebase (Web) and updates Master data.
  /// Returns a summary string.
  Future<String> importMasterImages(List<PlatformFile> files) async {
    final beanMaster = ref.read(beanMasterProvider).value ?? [];
    final grinderMaster = ref.read(grinderMasterProvider).value ?? [];
    final dripperMaster = ref.read(dripperMasterProvider).value ?? [];
    final filterMaster = ref.read(filterMasterProvider).value ?? [];

    if (beanMaster.isEmpty && grinderMaster.isEmpty && dripperMaster.isEmpty && filterMaster.isEmpty) {
      return "Error: No master data loaded.";
    }

    // Prepare destination directory if NOT on web (and we want local copy)
    // For this implementation, we will prefer Firebase for Web.
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

    final beanMap = {for (var b in beanMaster) b.id: b};
    final grinderMap = {for (var g in grinderMaster) g.id: g};
    final dripperMap = {for (var d in dripperMaster) d.id: d};
    final filterMap = {for (var f in filterMaster) f.id: f};

    for (final file in files) {
      final filename = file.name;
      final lowerFilename = filename.toLowerCase();
      String? matchedId;
      String? matchedType;

      // Find matching ID (case-insensitive and trimmed)
      for (var id in beanMap.keys) {
        if (lowerFilename.startsWith(id.trim().toLowerCase())) { matchedId = id; matchedType = 'bean'; break; }
      }
      if (matchedId == null) {
        for (var id in grinderMap.keys) {
          if (lowerFilename.startsWith(id.trim().toLowerCase())) { matchedId = id; matchedType = 'grinder'; break; }
        }
      }
      if (matchedId == null) {
        for (var id in dripperMap.keys) {
          if (lowerFilename.startsWith(id.trim().toLowerCase())) { matchedId = id; matchedType = 'dripper'; break; }
        }
      }
      if (matchedId == null) {
        for (var id in filterMap.keys) {
          if (lowerFilename.startsWith(id.trim().toLowerCase())) { matchedId = id; matchedType = 'filter'; break; }
        }
      }

      if (matchedId != null) {
        try {
          String? newImageUrl;
          
          if (kIsWeb) {
            // Web: Upload to Firebase
            debugPrint("Uploading $filename to Firebase...");
            newImageUrl = await uploadImage(file);
            if (newImageUrl == null) {
               errors.add("Failed to upload $filename");
               failCount++;
               continue;
            }
          } else {
            // Mobile/Desktop: Copy file locally (Default behavior for now, can switch to Firebase too if desired)
            // User requested Firebase to be used. Let's try to use Firebase if possible, otherwise local.
            // But for now, let's keep local for Mobile/Desktop to be safe and offline-capable unless explicitly asked to force cloud only.
            // Actually, the user asked "I want to use it on smartphone". Authentication might be tricky if we enforce Firebase rules.
            // But let's assume public read/write for now (Test Mode).
            // Let's SUPPORT basic upload for all if we want.
            // However, to keep it simple and consistent with previous logic:
            // Web -> Must use Firebase.
            // Mobile -> Can use Local (faster, offline). 
            // PROPOSAL: Let's stick to Local for Mobile/Desktop for now to avoid breaking existing workflow, 
            // BUT verify Firebase works on Web.
            // (If user wants synchronization across devices, we MUST use Firebase everywhere. 
            //  The user said "Finally I want to use it on smartphone", implying syncing data from PC to Phone?
            //  If so, we need Firebase for ALL.
            //  Let's enabling upload for ALL platforms then.)
            
            // Uploading to Firebase for ALL platforms to support multi-device sync.
            final url = await uploadImage(file); 
             if (url != null) {
                newImageUrl = url;
             } else {
                // Fallback to local if upload fails?
                if (file.path != null) {
                   final newPath = p.join(imagesDir!.path, filename);
                   await File(file.path!).copy(newPath);
                   newImageUrl = newPath; 
                }
             }
          }

          if (newImageUrl != null) {
             final sheets = ref.read(sheetsServiceProvider);
             if (matchedType == 'bean') {
               final updated = beanMap[matchedId]!.copyWith(imageUrl: newImageUrl);
               await sheets.updateBean(updated);
             } else if (matchedType == 'grinder') {
               final updated = grinderMap[matchedId]!.copyWith(imageUrl: newImageUrl);
               await sheets.updateGrinder(updated);
             } else if (matchedType == 'dripper') {
               final updated = dripperMap[matchedId]!.copyWith(imageUrl: newImageUrl);
               await sheets.updateDripper(updated);
             } else if (matchedType == 'filter') {
               final updated = filterMap[matchedId]!.copyWith(imageUrl: newImageUrl);
               await sheets.updateFilter(updated);
             }
             successCount++;
          } else {
             failCount++;
             errors.add("Could not get image URL/Path for $filename");
          }

        } catch (e) {
          failCount++;
          errors.add("Failed to process $filename: $e");
        }
      } else {
        skippedCount++;
      }
    }

    String result = "Import Complete.\nSuccess: $successCount\nFailed: $failCount\nSkipped: $skippedCount";
    if (errors.isNotEmpty) {
      result += "\nErrors:\n${errors.join('\n')}";
    }
    return result;
  }
  
  /// Helper to save a single image (e.g. from picker/camera)
  /// Returns the path (local) or URL (firebase).
  Future<String?> saveImage(PlatformFile file) async {
    // Prefer Firebase Upload
    final url = await uploadImage(file);
    if (url != null) return url;
    
    // Fallback to local
    if (!kIsWeb && file.path != null) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory(p.join(appDocDir.path, 'bean_images'));
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          final filename = p.basename(file.path!);
          final newFilename = '${DateTime.now().millisecondsSinceEpoch}_$filename';
          final newPath = p.join(imagesDir.path, newFilename);
          await File(file.path!).copy(newPath);
          return newPath;
        } catch (e) {
           debugPrint("Error saving local: $e");
        }
    }
    return null;
  }
}

final imageServiceProvider = Provider<ImageService>((ref) => ImageService(ref));
