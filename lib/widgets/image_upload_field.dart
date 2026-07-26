import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as picker;
import '../services/image_service.dart';
import 'bean_image.dart';

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
    return (file: result.files.first, source: source);
  }

  final photo = await picker.ImagePicker().pickImage(
    source: picker.ImageSource.camera,
    imageQuality: 85,
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
