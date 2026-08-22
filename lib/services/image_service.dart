// ignore_for_file: always_use_package_imports, avoid_catches_without_on_clauses
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_edition.dart';
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

/// 画像の保存先を抽象化するサービス。
///
/// T5-B14: personal(web)版はGoogle Drive([DriveImageService])、public(Android)版は
/// 端末ローカル([LocalImageService])に切り替える(imageServiceProvider参照)。
abstract class ImageService {
  final Ref ref;

  ImageService(this.ref);

  /// 画像をアップロード(または保存)し、参照用のパス/URLを返す。
  Future<String?> uploadImage(PlatformFile file);

  /// 単一画像を保存する(pickerからの利用を想定)。
  Future<String?> saveImage(PlatformFile file);

  /// 指定した画像を削除する。
  Future<void> deleteImage(String imageUrl);

  /// 選択されたファイル群をファイル名でマスタとマッチングし、一括登録する。
  Future<String> importMasterImages(List<PlatformFile> files);
}

/// マスタ画像インポートのマッチングロジック(ファイル名の先頭一致でBean/Grinder/
/// Dripper/Filterマスタと突合)を共通化するためのmixin。
/// アップロード部分(uploadImage呼び出し)だけを実装側で差し替える。
mixin _MasterImageImportMixin on ImageService {
  Future<String> importMasterImagesImpl(List<PlatformFile> files) async {
    // ref.read(xxxProvider).value は、そのProviderが一度もfetch完了していない場合
    // (例: 設定画面に直接遷移し、豆/グラインダー/ドリッパー/フィルター一覧画面を
    // 一度も開いていない場合)nullのまま返ってしまい、該当マスターの画像が
    // 常にスキップされる不具合があった。.future で確実にデータ取得を待つ。
    final beanMaster = await ref.read(beanMasterProvider.future);
    final grinderMaster = await ref.read(grinderMasterProvider.future);
    final dripperMaster = await ref.read(dripperMasterProvider.future);
    final filterMaster = await ref.read(filterMasterProvider.future);

    if (beanMaster.isEmpty && grinderMaster.isEmpty && dripperMaster.isEmpty && filterMaster.isEmpty) {
      return 'エラー: マスターデータが読み込まれていません。';
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
            errors.add('${file.name} のアップロードに失敗');
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
          errors.add('${file.name} の処理に失敗: $e');
        }
      } else {
        skippedCount++;
      }
    }

    String result = 'インポート完了。\n成功: $successCount\n失敗: $failCount\nスキップ: $skippedCount';
    if (errors.isNotEmpty) {
      result += '\nエラー:\n${errors.join('\n')}';
    }
    return result;
  }
}

/// personal(web)版: GAS経由でGoogle Driveへ画像をアップロードする実装。
class DriveImageService extends ImageService with _MasterImageImportMixin {
  DriveImageService(super.ref);

  /// Uploads a file to Google Drive via GAS and returns the shareable URL.
  @override
  Future<String?> uploadImage(PlatformFile file) async {
    try {
      final Uint8List? bytes;
      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        bytes = null;
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

      debugPrint('[Antigravity] Action: GAS経由でGoogle Driveへ画像をアップロード開始: $filename');
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
          debugPrint('[Antigravity] Action: 画像をアップロードしました。URL: $url');
          return url;
        } else {
          debugPrint('[Antigravity] Error: GASアップロード失敗: ${result['error']}');
          return null;
        }
      } else {
        debugPrint('[Antigravity] Error: GASが${response.statusCode}を返却: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: uploadImage失敗: $e');
      return null;
    }
  }

  /// Imports images from a list of selected files.
  /// Matches filenames to Master IDs (Bean, Grinder, Dripper, Filter).
  /// Uploads to Google Drive via GAS and updates Master data.
  /// Returns a summary string.
  @override
  Future<String> importMasterImages(List<PlatformFile> files) => importMasterImagesImpl(files);

  /// Saves a single image (e.g. from picker) to Google Drive via GAS.
  @override
  Future<String?> saveImage(PlatformFile file) async {
    return uploadImage(file);
  }

  /// Requests GAS to delete the Drive file identified by the URL.
  /// Only attempts deletion for Drive URLs; no-op for other URLs.
  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      final fileId = _driveFileId(imageUrl);
      if (fileId == null) {
        debugPrint('[Antigravity] Action: deleteImageをスキップ(Drive URLではない): $imageUrl');
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
          debugPrint('[Antigravity] Action: Drive画像を削除: $fileId');
        } else {
          debugPrint('[Antigravity] Error: GAS deleteImage失敗: ${result['error']}');
        }
      } else {
        debugPrint('[Antigravity] Error: GAS deleteImageが${response.statusCode}を返却');
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: deleteImage失敗: $e');
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

/// public(Android)版: 端末ローカルの`ApplicationDocumentsDirectory/bean_images/`
/// 配下に画像を保存する実装。Webでの利用は想定しない(public版はAndroid限定)。
class LocalImageService extends ImageService with _MasterImageImportMixin {
  LocalImageService(super.ref);

  /// bean_images ディレクトリ(無ければ作成)の[Directory]を返す。
  Future<Directory> _imagesDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'bean_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// ファイルを端末ローカルへ保存し、絶対パスを返す。
  @override
  Future<String?> uploadImage(PlatformFile file) async {
    try {
      final Uint8List? bytes;
      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        bytes = null;
      }
      if (bytes == null) return null;

      final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      debugPrint('[Antigravity] Action: 端末ローカルへ画像を保存開始: $filename');

      final dir = await _imagesDir();
      final savedFile = File(p.join(dir.path, filename));
      await savedFile.writeAsBytes(bytes);

      debugPrint('[Antigravity] Action: 画像をローカル保存しました。パス: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('[Antigravity] Error: uploadImage(ローカル)失敗: $e');
      return null;
    }
  }

  /// Imports images from a list of selected files, saving them locally.
  @override
  Future<String> importMasterImages(List<PlatformFile> files) => importMasterImagesImpl(files);

  /// Saves a single image (e.g. from picker) to the local device.
  @override
  Future<String?> saveImage(PlatformFile file) async {
    return uploadImage(file);
  }

  /// ローカルパスのファイルを削除する。Drive URL(http/https)はno-op。
  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        debugPrint('[Antigravity] Action: deleteImageをスキップ(ローカルパスではない): $imageUrl');
        return;
      }

      final file = File(imageUrl);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[Antigravity] Action: ローカル画像を削除: $imageUrl');
      } else {
        debugPrint('[Antigravity] Action: deleteImageをスキップ(ファイルが存在しない): $imageUrl');
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: deleteImage(ローカル)失敗: $e');
    }
  }
}

final imageServiceProvider = Provider<ImageService>((ref) {
  final edition = ref.watch(appEditionProvider);
  if (edition.useLocalImages) {
    return LocalImageService(ref);
  }
  return DriveImageService(ref);
});
