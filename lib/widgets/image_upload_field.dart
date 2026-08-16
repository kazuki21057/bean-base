// ignore_for_file: always_use_package_imports, avoid_catches_without_on_clauses
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' as picker;
import '../services/image_service.dart';
import 'bean_image.dart';

/// T5-B0b: 画像を送信・保存する前に長辺1024pxへ縮小する上限値。
/// AI抽出(`extractBeanInfoFromImage`)とDrive保存(`ImageService.saveImage`)の
/// 両方の原価/容量を抑えるため、`pickImageFile()`の戻り値をここで縮小する。
const int _kMaxImageDimension = 1024;

/// ファイル選択で取得したバイト列を、長辺が[_kMaxImageDimension]を超える場合のみ
/// アスペクト比を保って縮小し、元の拡張子に応じて再エンコードする。
/// デコードに失敗した場合はリサイズをスキップし、元のバイト列をそのまま返す。
Uint8List _resizeImageBytesIfNeeded(Uint8List bytes, String fileName) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    debugPrint('[Antigravity] 画像のデコードに失敗したためリサイズをスキップ (name=$fileName)');
    return bytes;
  }
  if (decoded.width <= _kMaxImageDimension && decoded.height <= _kMaxImageDimension) {
    return bytes;
  }

  final resized = decoded.width >= decoded.height
      ? img.copyResize(decoded, width: _kMaxImageDimension)
      : img.copyResize(decoded, height: _kMaxImageDimension);

  final isPng = fileName.toLowerCase().endsWith('.png');
  final resizedBytes = isPng
      ? Uint8List.fromList(img.encodePng(resized))
      : Uint8List.fromList(img.encodeJpg(resized, quality: 85));

  debugPrint(
    '[Antigravity] Action: 画像を長辺1024pxへ縮小 '
    '(元: ${decoded.width}x${decoded.height} → 新: ${resized.width}x${resized.height})',
  );
  return resizedBytes;
}

/// T3-41: 画像を取得した経路(ファイル選択/カメラ撮影)。呼び出し元が
/// 撮影画像だけ特別扱いしたい場合(例: 豆情報読取AIの情報画像保存、T3-35)に使う。
enum ImagePickSource { file, camera }

/// T3-35でbean_create_screen.dartにローカル実装していた「ファイルから選択/
/// カメラで撮影」の選択ダイアログをT3-41で共通化したもの。[ImageUploadField]
/// (豆/ドリッパー/フィルター/グラインダーの全画像欄が経由する共通部品)と
/// bean_create_screen.dartの豆情報読取AIの両方から呼ばれる。
Future<ImagePickSource?> showImageSourceDialog(BuildContext context) {
  return showDialog<ImagePickSource>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('画像の取得方法'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, ImagePickSource.file),
          child: const Row(
            children: [
              Icon(Icons.photo_library_outlined),
              SizedBox(width: 12),
              Text('ファイルから選択'),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, ImagePickSource.camera),
          child: const Row(
            children: [
              Icon(Icons.photo_camera_outlined),
              SizedBox(width: 12),
              Text('カメラで撮影'),
            ],
          ),
        ),
      ],
    ),
  );
}

/// ダイアログでの選択に応じて`FilePicker`または`image_picker`(カメラ)から
/// 画像を取得し、共通の`PlatformFile`として返す(呼び出し側はソースを問わず
/// 同じ形で扱える)。キャンセル時はnull。[source]には実際に使われた取得元が
/// 入るため、カメラ撮影時だけ追加処理をしたい呼び出し元はこれを見て分岐できる。
Future<({PlatformFile file, ImagePickSource source})?> pickImageFile(
  BuildContext context,
) async {
  final source = await showImageSourceDialog(context);
  if (source == null || !context.mounted) return null;

  if (source == ImagePickSource.file) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.first;
    final originalBytes = picked.bytes;
    if (originalBytes == null) return (file: picked, source: source);

    final resizedBytes = _resizeImageBytesIfNeeded(originalBytes, picked.name);
    if (identical(resizedBytes, originalBytes)) {
      return (file: picked, source: source);
    }
    return (
      file: PlatformFile(name: picked.name, size: resizedBytes.length, bytes: resizedBytes),
      source: source,
    );
  }

  final photo = await picker.ImagePicker().pickImage(
    source: picker.ImageSource.camera,
    imageQuality: 85,
    maxWidth: 1024,
    maxHeight: 1024,
  );
  if (photo == null) return null;
  final bytes = await photo.readAsBytes();
  final name = photo.name.isNotEmpty
      ? photo.name
      : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
  return (
    file: PlatformFile(name: name, size: bytes.length, bytes: bytes),
    source: source,
  );
}

class ImageUploadField extends ConsumerStatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<String?> onImageUploaded;

  /// T3-34: 豆マスターのように1画面に複数のアップロード欄を並べる場合の
  /// 見出しラベル(任意)。未指定なら従来どおり見出し無しで描画される。
  final String? label;

  const ImageUploadField({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
    this.label,
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

  // T3-44: 画面下部固定の登録ボタン(CreateFormScaffold)にSnackBarが重なり
  // タップを奪う不具合の対策として、floating+マージンでボタン領域を避ける。
  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await pickImageFile(context);

      if (picked != null) {
        final file = picked.file;

        setState(() {
          _isUploading = true;
        });

        _showSnack('画像をアップロード中...');

        final service = ref.read(imageServiceProvider);
        final url = await service.saveImage(file);

        setState(() {
          _isUploading = false;
        });

        if (url != null) {
          _urlController.text = url;
          widget.onImageUploaded(url);
          _showSnack('画像をアップロードしました');
        } else {
          _showSnack('画像のアップロードに失敗しました', backgroundColor: Colors.red);
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnack('画像の取得に失敗しました: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(widget.label!, style: Theme.of(context).textTheme.labelLarge),
          ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: '画像URL'),
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
                  tooltip: '画像をアップロード',
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
