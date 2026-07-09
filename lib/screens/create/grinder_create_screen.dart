import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/equipment_masters.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/data_service.dart';
import '../../widgets/image_upload_field.dart';
import 'create_form_widgets.dart';

/// 024 新規グラインダー / 023 詳細からの編集フォーム。
///
/// Cycle 20 T1-5c: UIモック(見た目のみ)から DataService に接続した本実装へ
/// 置き換え。[editData] を渡すと編集モードになる。
class GrinderCreateScreen extends ConsumerStatefulWidget {
  final GrinderMaster? editData;

  const GrinderCreateScreen({super.key, this.editData});

  @override
  ConsumerState<GrinderCreateScreen> createState() => _GrinderCreateScreenState();
}

class _GrinderCreateScreenState extends ConsumerState<GrinderCreateScreen> {
  final _nameController = TextEditingController();
  final _rangeController = TextEditingController();
  final _descController = TextEditingController();
  String? _imageUrl;
  bool _isSaving = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;
    _nameController.text = edit?.name ?? '';
    _rangeController.text = edit?.grindRange ?? '';
    _descController.text = edit?.description ?? '';
    _imageUrl = edit?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rangeController.dispose();
    _descController.dispose();
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

    final grinder = GrinderMaster(
      id: _isEdit ? widget.editData!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      grindRange: _rangeController.text.trim(),
      description: _descController.text.trim(),
      imageUrl: _imageUrl,
    );

    try {
      final service = ref.read(dataServiceProvider);
      if (_isEdit) {
        await service.updateGrinder(grinder);
        debugPrint('[Antigravity] Action: グラインダー更新 (id=${grinder.id})');
      } else {
        await service.addGrinder(grinder);
        debugPrint('[Antigravity] Action: グラインダー登録 (id=${grinder.id})');
      }
      ref.invalidate(grinderMasterProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'グラインダーを更新しました' : 'グラインダーを登録しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: グラインダー保存に失敗 $e');
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
      screen: AppScreen.grinderNew,
      title: _isEdit ? 'グラインダー編集' : null,
      saveLabel: _isEdit ? 'グラインダーを更新する' : 'グラインダーを登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        FormSection(
          icon: Icons.settings_input_component_outlined,
          title: '基本情報',
          children: [
            MockTextField(
              label: '名前',
              hint: '例: コマンダンテ C40',
              required: true,
              controller: _nameController,
            ),
            MockTextField(
              label: '挽き目レンジ',
              hint: '例: 15〜25クリック(ペーパードリップ)',
              controller: _rangeController,
            ),
            MockTextField(
              label: '説明・メモ',
              hint: '手入れ方法や癖などを記録',
              maxLines: 3,
              controller: _descController,
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
