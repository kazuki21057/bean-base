import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/equipment_masters.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/data_service.dart';
import '../../widgets/image_upload_field.dart';
import 'create_form_widgets.dart';

/// 018 新規フィルター / 017 詳細からの編集フォーム。
///
/// Cycle 20 T1-5b: UIモック(見た目のみ)から DataService に接続した本実装へ
/// 置き換え。[editData] を渡すと編集モードになる。
class FilterCreateScreen extends ConsumerStatefulWidget {
  final FilterMaster? editData;

  const FilterCreateScreen({super.key, this.editData});

  @override
  ConsumerState<FilterCreateScreen> createState() => _FilterCreateScreenState();
}

class _FilterCreateScreenState extends ConsumerState<FilterCreateScreen> {
  static const _materialOptions = ['ペーパー(漂白)', 'ペーパー(無漂白)', '金属', '布(ネル)'];
  static const _sizeOptions = ['01', '02', '03', 'その他'];

  final _nameController = TextEditingController();
  late List<String> _materialChoices;
  late List<String> _sizeChoices;
  String? _material;
  String? _size;
  String? _imageUrl;
  bool _isSaving = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;
    _nameController.text = edit?.name ?? '';
    _material = edit?.material;
    _size = edit?.size;
    _imageUrl = edit?.imageUrl;
    _materialChoices = _withCurrentValue(_materialOptions, _material);
    _sizeChoices = _withCurrentValue(_sizeOptions, _size);
  }

  static List<String> _withCurrentValue(List<String> base, String? current) {
    if (current == null || current.isEmpty || base.contains(current)) return base;
    return [current, ...base];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final filter = FilterMaster(
      id: _isEdit ? widget.editData!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      material: _material,
      size: _size,
      imageUrl: _imageUrl,
    );

    try {
      final service = ref.read(dataServiceProvider);
      if (_isEdit) {
        await service.updateFilter(filter);
        debugPrint('[Antigravity] Action: フィルター更新 (id=${filter.id})');
      } else {
        await service.addFilter(filter);
        debugPrint('[Antigravity] Action: フィルター登録 (id=${filter.id})');
      }
      ref.invalidate(filterMasterProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'フィルターを更新しました' : 'フィルターを登録しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: フィルター保存に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.filterNew,
      title: _isEdit ? 'フィルター編集' : null,
      saveLabel: _isEdit ? 'フィルターを更新する' : 'フィルターを登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        FormSection(
          icon: Icons.layers_outlined,
          title: '基本情報',
          children: [
            MockTextField(
              label: '名前',
              hint: '例: HARIO V60ペーパーフィルター',
              required: true,
              controller: _nameController,
            ),
            MockChoiceChips(
              label: '素材',
              options: _materialChoices,
              initialValue: _material,
              onChanged: (v) => _material = v,
            ),
            MockChoiceChips(
              label: 'サイズ',
              options: _sizeChoices,
              initialValue: _size,
              onChanged: (v) => _size = v,
            ),
          ],
        ),
        FormSection(
          icon: Icons.photo_camera_outlined,
          title: '画像',
          children: [
            ImageUploadField(
              initialImageUrl: _imageUrl,
              onImageUploaded: (url) => _imageUrl = url,
            ),
          ],
        ),
      ],
    );
  }
}
