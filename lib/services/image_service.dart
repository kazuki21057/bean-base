import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/data_providers.dart';
import '../services/data_service.dart';
import '../services/sheets_service.dart';

String _mimeTypeFromName(String filename) {
  final ext = p.extension(filename).toLowerCase();
  switch (ext) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}

class ImageService {
  final Ref ref;

  ImageService(this.ref);

  /// Uploads a file to Google Drive via GAS and returns the shareable URL.
  Future<String?> uploadImage(PlatformFile file) async {
    try {
      final Uint8List? bytes;
      if (kIsWeb) {
        bytes = file.bytes;
      } else {
        if (file.path == null) return null;
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) return null;

      final base64Data = base64Encode(bytes);
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final mimeType = _mimeTypeFromName(file.name);

      final body = jsonEncode({
        'action': 'uploadImage',
        'filename': filename,
        'mimeType': mimeType,
        'data': base64Data,
      });

      debugPrint('[Antigravity] Action: Uploading image to Drive via GAS: $filename');
      final response = await http.post(
        Uri.parse(kGoogleSheetsApiUrl),
        // text/plain を使うことで CORS プリフライト(OPTIONS)を回避する。
        // GAS の doPost は Content-Type に関わらず postData.contents を
        // JSON.parse するため、送信側は text/plain のままで問題ない
        // (sheets_service.dart の _postData と同じ対策)。
        headers: {'Content-Type': 'text/plain'},
        body: body,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          final url = result['url'] as String?;
          debugPrint('[Antigravity] Action: Image uploaded. URL: $url');
          return url;
        } else {
          debugPrint('[Antigravity] Error: GAS upload failed: ${result['error']}');
          return null;
        }
      } else {
        debugPrint('[Antigravity] Error: GAS responded ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: uploadImage failed: $e');
      return null;
    }
  }

  /// Imports images from a list of selected files.
  /// Matches filenames to Master IDs (Bean, Grinder, Dripper, Filter).
  /// Uploads to Google Drive via GAS and updates Master data.
  /// Returns a summary string.
  Future<String> importMasterImages(List<PlatformFile> files) async {
    // ref.read(xxxProvider).value は、そのProviderが一度もfetch完了していない場合
    // (例: 設定画面に直接遷移し、豆/グラインダー/ドリッパー/フィルター一覧画面を
    // 一度も開いていない場合)nullのまま返ってしまい、該当マスターの画像が
    // 常にスキップされる不具合があった。.future で確実にデータ取得を待つ。
    final beanMaster = await ref.read(beanMasterProvider.future);
    final grinderMaster = await ref.read(grinderMasterProvider.future);
    final dripperMaster = await ref.read(dripperMasterProvider.future);
    final filterMaster = await ref.read(filterMasterProvider.future);

    if (beanMaster.isEmpty && grinderMaster.isEmpty && dripperMaster.isEmpty && filterMaster.isEmpty) {
      return 'Error: No master data loaded.';
    }

    final beanMap = {for (var b in beanMaster) b.id: b};
    final grinderMap = {for (var g in grinderMaster) g.id: g};
    final dripperMap = {for (var d in dripperMaster) d.id: d};
    final filterMap = {for (var f in filterMaster) f.id: f};

    int successCount = 0;
    int failCount = 0;
    int skippedCount = 0;
    final List<String> errors = [];

    for (final file in files) {
      final lowerFilename = file.name.toLowerCase();
      String? matchedId;
      String? matchedType;

      for (var id in beanMap.keys) {
        if (lowerFilename.startsWith(id.trim().toLowerCase())) {
          matchedId = id; matchedType = 'bean'; break;
        }
      }
      if (matchedId == null) {
        for (var id in grinderMap.keys) {
          if (lowerFilename.startsWith(id.trim().toLowerCase())) {
            matchedId = id; matchedType = 'grinder'; break;
          }
        }
      }
      if (matchedId == null) {
        for (var id in dripperMap.keys) {
          if (lowerFilename.startsWith(id.trim().toLowerCase())) {
            matchedId = id; matchedType = 'dripper'; break;
          }
        }
      }
      if (matchedId == null) {
        for (var id in filterMap.keys) {
          if (lowerFilename.startsWith(id.trim().toLowerCase())) {
            matchedId = id; matchedType = 'filter'; break;
          }
        }
      }

      if (matchedId != null) {
        try {
          final newImageUrl = await uploadImage(file);
          if (newImageUrl == null) {
            errors.add('Failed to upload ${file.name}');
            failCount++;
            continue;
          }

          final service = ref.read(dataServiceProvider);
          if (matchedType == 'bean') {
            await service.updateBean(beanMap[matchedId]!.copyWith(imageUrl: newImageUrl));
          } else if (matchedType == 'grinder') {
            await service.updateGrinder(grinderMap[matchedId]!.copyWith(imageUrl: newImageUrl));
          } else if (matchedType == 'dripper') {
            await service.updateDripper(dripperMap[matchedId]!.copyWith(imageUrl: newImageUrl));
          } else if (matchedType == 'filter') {
            await service.updateFilter(filterMap[matchedId]!.copyWith(imageUrl: newImageUrl));
          }
          successCount++;
        } catch (e) {
          failCount++;
          errors.add('Failed to process ${file.name}: $e');
        }
      } else {
        skippedCount++;
      }
    }

    String result = 'Import Complete.\nSuccess: $successCount\nFailed: $failCount\nSkipped: $skippedCount';
    if (errors.isNotEmpty) {
      result += '\nErrors:\n${errors.join('\n')}';
    }
    return result;
  }

  /// Saves a single image (e.g. from picker) to Google Drive via GAS.
  Future<String?> saveImage(PlatformFile file) async {
    return uploadImage(file);
  }

  /// Requests GAS to delete the Drive file identified by the URL.
  /// Only attempts deletion for Drive URLs; no-op for other URLs.
  Future<void> deleteImage(String imageUrl) async {
    try {
      final fileId = _driveFileId(imageUrl);
      if (fileId == null) {
        debugPrint('[Antigravity] Action: deleteImage skipped (not a Drive URL): $imageUrl');
        return;
      }

      final body = jsonEncode({'action': 'deleteImage', 'fileId': fileId});
      final response = await http.post(
        Uri.parse(kGoogleSheetsApiUrl),
        headers: {'Content-Type': 'text/plain'},
        body: body,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          debugPrint('[Antigravity] Action: Deleted Drive image: $fileId');
        } else {
          debugPrint('[Antigravity] Error: GAS deleteImage failed: ${result['error']}');
        }
      } else {
        debugPrint('[Antigravity] Error: GAS deleteImage responded ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: deleteImage failed: $e');
    }
  }

  /// Extracts the Google Drive file ID from a Drive URL, or returns null.
  String? _driveFileId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('drive.google.com')) {
      return uri.queryParameters['id'];
    }
    return null;
  }
}

final imageServiceProvider = Provider<ImageService>((ref) => ImageService(ref));
