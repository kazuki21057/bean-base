import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/store_master.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/data_service.dart';
import '../../widgets/image_upload_field.dart';
import 'create_form_widgets.dart';

/// 028 新規購入店 / 027 詳細からの編集フォーム。
///
/// T3-68: `docs/store_master_design.md`§5.4のとおり実装。
/// dripper_create_screen.dart と同型の構成(FormSection + TextFormField +
/// 保存ボタン)。[editData] を渡すと編集モードになる。
class StoreCreateScreen extends ConsumerStatefulWidget {
  final StoreMaster? editData;

  const StoreCreateScreen({super.key, this.editData});

  @override
  ConsumerState<StoreCreateScreen> createState() => _StoreCreateScreenState();
}

class _StoreCreateScreenState extends ConsumerState<StoreCreateScreen> {
  final _nameController = TextEditingController();
  final _formalNameController = TextEditingController();
  final _urlController = TextEditingController();
  final _prefectureController = TextEditingController();
  final _addressController = TextEditingController();
  final _beanTendencyController = TextEditingController();
  final _memoController = TextEditingController();
  final _snsUrlController = TextEditingController();
  final _businessHoursController = TextEditingController();
  final _closedDaysController = TextEditingController();
  final _phoneController = TextEditingController();
  final _openedYearController = TextEditingController();

  bool _hasOnlineShop = false;
  bool _hasPhysicalStore = false;
  bool _hasRoastery = false;
  String? _imageUrl;
  bool _isSaving = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;
    _nameController.text = edit?.name ?? '';
    _formalNameController.text = edit?.formalName ?? '';
    _urlController.text = edit?.url ?? '';
    _prefectureController.text = edit?.prefecture ?? '';
    _addressController.text = edit?.address ?? '';
    _beanTendencyController.text = edit?.beanTendency ?? '';
    _memoController.text = edit?.memo ?? '';
    _snsUrlController.text = edit?.snsUrl ?? '';
    _businessHoursController.text = edit?.businessHours ?? '';
    _closedDaysController.text = edit?.closedDays ?? '';
    _phoneController.text = edit?.phone ?? '';
    _openedYearController.text = edit?.openedYear ?? '';
    _hasOnlineShop = edit?.hasOnlineShop ?? false;
    _hasPhysicalStore = edit?.hasPhysicalStore ?? false;
    _hasRoastery = edit?.hasRoastery ?? false;
    _imageUrl = edit?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formalNameController.dispose();
    _urlController.dispose();
    _prefectureController.dispose();
    _addressController.dispose();
    _beanTendencyController.dispose();
    _memoController.dispose();
    _snsUrlController.dispose();
    _businessHoursController.dispose();
    _closedDaysController.dispose();
    _phoneController.dispose();
    _openedYearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('店名を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final store = StoreMaster(
      id: _isEdit ? widget.editData!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      formalName: _formalNameController.text.trim(),
      url: _urlController.text.trim(),
      prefecture: _prefectureController.text.trim(),
      address: _addressController.text.trim(),
      hasOnlineShop: _hasOnlineShop,
      hasPhysicalStore: _hasPhysicalStore,
      hasRoastery: _hasRoastery,
      beanTendency: _beanTendencyController.text.trim(),
      memo: _memoController.text.trim(),
      imageUrl: _imageUrl,
      snsUrl: _snsUrlController.text.trim(),
      businessHours: _businessHoursController.text.trim(),
      closedDays: _closedDaysController.text.trim(),
      phone: _phoneController.text.trim(),
      openedYear: _openedYearController.text.trim(),
      sourceUrl: _isEdit ? widget.editData!.sourceUrl : '',
      infoFetchedAt: _isEdit ? widget.editData!.infoFetchedAt : null,
    );

    try {
      final service = ref.read(dataServiceProvider);
      if (_isEdit) {
        await service.updateStore(store);
        debugPrint('[Antigravity] Action: 購入店更新 (id=${store.id})');
      } else {
        await service.addStore(store);
        debugPrint('[Antigravity] Action: 購入店登録 (id=${store.id})');
      }
      if (_isEdit) {
        ref.read(storeMasterProvider.notifier).updateOptimistic(store);
      } else {
        ref.read(storeMasterProvider.notifier).addOptimistic(store);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? '購入店を更新しました' : '購入店を登録しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: 購入店保存に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.storeNew,
      title: _isEdit ? '購入店編集' : null,
      saveLabel: _isEdit ? '購入店を更新する' : '購入店を登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        FormSection(
          icon: Icons.storefront_outlined,
          title: '基本情報',
          children: [
            MockTextField(
              label: '店名',
              hint: '例: Navy',
              required: true,
              controller: _nameController,
            ),
            MockTextField(
              label: '正式名称',
              hint: '例: Navy Coffee Roaster',
              controller: _formalNameController,
            ),
            MockTextField(
              label: 'URL',
              hint: '例: https://example.com/',
              keyboardType: TextInputType.url,
              controller: _urlController,
            ),
            MockTextField(
              label: '都道府県',
              hint: '例: 兵庫県',
              controller: _prefectureController,
            ),
            MockTextField(
              label: '住所',
              hint: '都道府県以下の住所',
              controller: _addressController,
            ),
            MockSwitchTile(
              label: 'オンライン販売',
              initialValue: _hasOnlineShop,
              onChanged: (v) => setState(() => _hasOnlineShop = v),
            ),
            MockSwitchTile(
              label: '実店舗',
              initialValue: _hasPhysicalStore,
              onChanged: (v) => setState(() => _hasPhysicalStore = v),
            ),
            MockSwitchTile(
              label: '焙煎所併設',
              initialValue: _hasRoastery,
              onChanged: (v) => setState(() => _hasRoastery = v),
            ),
            MockTextField(
              label: '取扱豆の傾向',
              hint: '例: スペシャルティ中心/浅煎り多め',
              maxLines: 3,
              controller: _beanTendencyController,
            ),
            MockTextField(
              label: 'メモ',
              maxLines: 3,
              controller: _memoController,
            ),
          ],
        ),
        FormSection(
          icon: Icons.info_outline,
          title: '詳細情報',
          children: [
            MockTextField(
              label: 'SNS',
              hint: '例: https://www.instagram.com/...',
              keyboardType: TextInputType.url,
              controller: _snsUrlController,
            ),
            MockTextField(
              label: '営業時間',
              hint: '例: 月-金10:00-17:00',
              controller: _businessHoursController,
            ),
            MockTextField(
              label: '定休日',
              hint: '例: 火曜',
              controller: _closedDaysController,
            ),
            MockTextField(
              label: '電話番号',
              keyboardType: TextInputType.phone,
              controller: _phoneController,
            ),
            MockTextField(
              label: '開業年',
              hint: '例: 2015',
              keyboardType: TextInputType.number,
              controller: _openedYearController,
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
