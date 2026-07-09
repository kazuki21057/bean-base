import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/equipment_masters.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/data_service.dart';
import '../../widgets/image_upload_field.dart';
import 'create_form_widgets.dart';

/// 015 新規ドリッパー / 014 詳細からの編集フォーム。
///
/// Cycle 20 T1-5a: UIモック(見た目のみ)から DataService に接続した本実装へ
/// 置き換え。[editData] を渡すと編集モードになる。
class DripperCreateScreen extends ConsumerStatefulWidget {
  final DripperMaster? editData;

  const DripperCreateScreen({super.key, this.editData});

  @override
  ConsumerState<DripperCreateScreen> createState() => _DripperCreateScreenState();
}

class _DripperCreateScreenState extends ConsumerState<DripperCreateScreen> {
  static const _materialOptions = ['セラミック', 'プラスチック', '金属', 'ガラス'];
  static const _shapeOptions = ['円錐', '台形', '平底(ウェーブ)'];

  final _nameController = TextEditingController();
  late List<String> _materialChoices;
  late List<String> _shapeChoices;
  String? _material;
  String? _shape;
  String? _imageUrl;
  bool _isSaving = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;
    _nameController.text = edit?.name ?? '';
    _material = edit?.material;
    _shape = edit?.shape;
    _imageUrl = edit?.imageUrl;
    _materialChoices = _withCurrentValue(_materialOptions, _material);
    _shapeChoices = _withCurrentValue(_shapeOptions, _shape);
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

    final dripper = DripperMaster(
      id: _isEdit ? widget.editData!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      material: _material,
      shape: _shape,
      imageUrl: _imageUrl,
    );

    try {
      final service = ref.read(dataServiceProvider);
      if (_isEdit) {
        await service.updateDripper(dripper);
        debugPrint('[Antigravity] Action: ドリッパー更新 (id=${dripper.id})');
      } else {
        await service.addDripper(dripper);
        debugPrint('[Antigravity] Action: ドリッパー登録 (id=${dripper.id})');
      }
      ref.invalidate(dripperMasterProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'ドリッパーを更新しました' : 'ドリッパーを登録しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: ドリッパー保存に失敗 $e');
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
      screen: AppScreen.dripperNew,
      title: _isEdit ? 'ドリッパー編集' : null,
      saveLabel: _isEdit ? 'ドリッパーを更新する' : 'ドリッパーを登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        FormSection(
          icon: Icons.filter_alt_outlined,
          title: '基本情報',
          children: [
            MockTextField(
              label: '名前',
              hint: '例: HARIO V60 02',
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
              label: '形状',
              options: _shapeChoices,
              initialValue: _shape,
              onChanged: (v) => _shape = v,
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
