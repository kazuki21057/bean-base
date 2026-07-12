import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bean_master.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/data_service.dart';
import '../../widgets/image_upload_field.dart';
import 'create_form_widgets.dart';

/// 012 新規豆追加 / 011 詳細からの編集フォーム。
///
/// Cycle 20 T1-6b: UIモック(見た目のみ)から DataService に接続した本実装へ
/// 置き換え。[editData] を渡すと編集モードになる。
class BeanCreateScreen extends ConsumerStatefulWidget {
  final BeanMaster? editData;

  const BeanCreateScreen({super.key, this.editData});

  @override
  ConsumerState<BeanCreateScreen> createState() => _BeanCreateScreenState();
}

class _BeanCreateScreenState extends ConsumerState<BeanCreateScreen> {
  static const _roastOptions = ['浅煎り', '中煎り', '中深煎り', '深煎り'];

  final _nameController = TextEditingController();
  final _storeController = TextEditingController();
  final _originController = TextEditingController();
  final _typeController = TextEditingController();
  final _initialQuantityController = TextEditingController();
  late List<String> _roastChoices;
  String? _roastLevel;
  DateTime? _purchaseDate;
  bool _isInStock = true;
  String? _imageUrl;
  bool _isSaving = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;
    _nameController.text = edit?.name ?? '';
    _storeController.text = edit?.store ?? '';
    _originController.text = edit?.origin ?? '';
    _typeController.text = edit?.type ?? '';
    _initialQuantityController.text = edit?.initialQuantityGrams?.toStringAsFixed(1) ?? '';
    _roastLevel = (edit?.roastLevel.isNotEmpty ?? false) ? edit!.roastLevel : null;
    _purchaseDate = edit?.purchaseDate;
    _isInStock = edit?.isInStock ?? true;
    _imageUrl = edit?.imageUrl;
    _roastChoices = _withCurrentValue(_roastOptions, _roastLevel);
  }

  static List<String> _withCurrentValue(List<String> base, String? current) {
    if (current == null || current.isEmpty || base.contains(current)) return base;
    return [current, ...base];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeController.dispose();
    _originController.dispose();
    _typeController.dispose();
    _initialQuantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('豆の名前を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final edit = widget.editData;
    final bean = BeanMaster(
      id: _isEdit ? edit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      roastLevel: _roastLevel ?? '',
      origin: _originController.text.trim(),
      store: _storeController.text.trim(),
      type: _typeController.text.trim(),
      imageUrl: _imageUrl,
      purchaseDate: _purchaseDate,
      firstUseDate: edit?.firstUseDate,
      lastUseDate: edit?.lastUseDate,
      isInStock: _isInStock,
      initialQuantityGrams: double.tryParse(_initialQuantityController.text.trim()),
    );

    try {
      final service = ref.read(dataServiceProvider);
      if (_isEdit) {
        await service.updateBean(bean);
        debugPrint('[Antigravity] Action: 豆更新 (id=${bean.id})');
      } else {
        await service.addBean(bean);
        debugPrint('[Antigravity] Action: 豆登録 (id=${bean.id})');
      }
      ref.invalidate(beanMasterProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? '豆を更新しました' : '豆を登録しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: 豆保存に失敗 $e');
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
      screen: AppScreen.beanNew,
      title: _isEdit ? '豆編集' : null,
      saveLabel: _isEdit ? '豆を更新する' : '豆を登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        FormSection(
          icon: Icons.coffee,
          title: '基本情報',
          children: [
            MockTextField(
              label: '豆の名前',
              hint: '例: エチオピア イルガチェフェ',
              required: true,
              controller: _nameController,
            ),
            MockTextField(
              label: '焙煎所 / 購入店',
              hint: '例: 〇〇コーヒーロースターズ',
              controller: _storeController,
            ),
            MockTextField(
              label: '産地',
              hint: '例: エチオピア',
              controller: _originController,
            ),
            MockTextField(
              label: '品種・精製',
              hint: '例: ウォッシュド',
              controller: _typeController,
            ),
            MockChoiceChips(
              label: '煎り度',
              options: _roastChoices,
              initialValue: _roastLevel,
              onChanged: (v) => _roastLevel = v,
            ),
          ],
        ),
        FormSection(
          icon: Icons.inventory_2_outlined,
          title: '在庫・購入情報',
          children: [
            MockDateField(
              label: '購入日',
              initialValue: _purchaseDate,
              onChanged: (v) => _purchaseDate = v,
            ),
            MockTextField(
              label: '初期購入量(g)',
              hint: '例: 200',
              suffix: 'g',
              keyboardType: TextInputType.number,
              controller: _initialQuantityController,
            ),
            MockSwitchTile(
              label: '在庫あり(瓶に表示する)',
              initialValue: _isInStock,
              onChanged: (v) => setState(() => _isInStock = v),
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
