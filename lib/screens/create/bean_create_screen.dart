import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bean_master.dart';
import '../../models/origin_master.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/ai_analysis_service.dart';
import '../../services/data_service.dart';
import '../../widgets/image_upload_field.dart';
import 'create_form_widgets.dart';

/// T4-1e(設計書§3.2): 産地マスタの地域選択肢(OriginMaster.region、固定4種)。
const _originRegionOptions = ['アフリカ', '中南米', 'アジア・太平洋', 'その他'];

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
  final _typeController = TextEditingController();
  final _initialQuantityController = TextEditingController();
  late List<String> _roastChoices;
  String? _roastLevel;
  DateTime? _purchaseDate;
  DateTime? _roastDate;
  bool _isInStock = true;
  String? _imageUrl;
  String? _beanImageUrl;
  String? _infoImageUrl;
  bool _isSaving = false;
  bool _isExtracting = false;

  /// T4-1e(設計書§3.2): 産地はOriginMaster選択に置換(自由入力の`_originController`は廃止)。
  String? _selectedOriginId;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;
    _nameController.text = edit?.name ?? '';
    _storeController.text = edit?.store ?? '';
    _typeController.text = edit?.type ?? '';
    _initialQuantityController.text = edit?.initialQuantityGrams?.toStringAsFixed(1) ?? '';
    _roastLevel = (edit?.roastLevel.isNotEmpty ?? false) ? edit!.roastLevel : null;
    _purchaseDate = edit?.purchaseDate;
    _roastDate = edit?.roastDate;
    _isInStock = edit?.isInStock ?? true;
    _imageUrl = edit?.imageUrl;
    _beanImageUrl = edit?.beanImageUrl;
    _infoImageUrl = edit?.infoImageUrl;
    _selectedOriginId = (edit?.originId.isNotEmpty ?? false) ? edit!.originId : null;
    _roastChoices = _withCurrentValue(_roastOptions, _roastLevel);
  }

  static T? _resolveById<T>(List<T> items, String? id, String Function(T) idOf) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  static List<String> _withCurrentValue(List<String> base, String? current) {
    if (current == null || current.isEmpty || base.contains(current)) return base;
    return [current, ...base];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeController.dispose();
    _typeController.dispose();
    _initialQuantityController.dispose();
    super.dispose();
  }

  Future<void> _addNewOrigin() async {
    final nameJaController = TextEditingController();
    final nameEnController = TextEditingController();
    final countryCodeController = TextEditingController();
    String region = _originRegionOptions.first;

    final created = await showDialog<OriginMaster>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('新規産地追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameJaController,
                    decoration: const InputDecoration(labelText: '産地名(必須、例: エチオピア)'),
                  ),
                  TextField(
                    controller: nameEnController,
                    decoration: const InputDecoration(labelText: '産地名(英、任意)'),
                  ),
                  TextField(
                    controller: countryCodeController,
                    decoration: const InputDecoration(labelText: '国コード(任意、例: ET)'),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '地域'),
                    initialValue: region,
                    items: [
                      for (final r in _originRegionOptions) DropdownMenuItem(value: r, child: Text(r)),
                    ],
                    onChanged: (v) => setDialogState(() => region = v ?? region),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    final nameJa = nameJaController.text.trim();
                    if (nameJa.isEmpty) return;
                    Navigator.of(dialogContext).pop(
                      OriginMaster(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        countryCode: countryCodeController.text.trim(),
                        nameJa: nameJa,
                        nameEn: nameEnController.text.trim(),
                        region: region,
                      ),
                    );
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == null) return;
    try {
      await ref.read(dataServiceProvider).saveOriginMaster(created);
      debugPrint('[Antigravity] Action: 産地マスタ追加 (id=${created.id})');
      ref.invalidate(originMasterProvider);
      setState(() => _selectedOriginId = created.id);
    } catch (e) {
      debugPrint('[Antigravity] Error: 産地マスタ追加に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('産地の追加に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// T3-30: パッケージ/説明カード画像をGemini Visionに渡し豆情報を抽出、
  /// 抽出できた項目のみフォームへ反映する(専用ページは作らず012内で完結)。
  Future<void> _extractFromImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像の読み込みに失敗しました'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    var apiKey = prefs.getString('gemini_api_key');
    if ((apiKey == null || apiKey.isEmpty) && mounted) {
      apiKey = await _askApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        await prefs.setString('gemini_api_key', apiKey);
      }
    }
    if (apiKey == null || apiKey.isEmpty) return;

    setState(() => _isExtracting = true);
    try {
      final origins = ref.read(originMasterProvider).value ?? const [];
      debugPrint('[Antigravity] Action: 豆情報のAI抽出を実行 (file=${file.name})');
      final extracted = await ref.read(aiAnalysisServiceProvider).extractBeanInfoFromImage(
            imageBytes: Uint8List.fromList(bytes),
            mimeType: _mimeTypeFromName(file.name),
            knownOrigins: origins.map((o) => o.nameJa).toList(),
            apiKey: apiKey,
          );
      _applyExtractedInfo(extracted, origins);
    } catch (e) {
      debugPrint('[Antigravity] Error: 豆情報のAI抽出に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('抽出に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  static String _mimeTypeFromName(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  void _applyExtractedInfo(ExtractedBeanInfo extracted, List<OriginMaster> origins) {
    if (extracted.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像から豆情報を読み取れませんでした。手動で入力してください。')),
        );
      }
      return;
    }

    final filled = <String>[];
    final unmatchedOrigin = extracted.origin;
    OriginMaster? matchedOrigin;
    if (extracted.origin != null) {
      for (final o in origins) {
        if (o.nameJa == extracted.origin || o.nameJa.contains(extracted.origin!) || extracted.origin!.contains(o.nameJa)) {
          matchedOrigin = o;
          break;
        }
      }
    }

    setState(() {
      if (extracted.name != null) {
        _nameController.text = extracted.name!;
        filled.add('豆の名前');
      }
      if (extracted.store != null) {
        _storeController.text = extracted.store!;
        filled.add('焙煎所/購入店');
      }
      if (extracted.type != null) {
        _typeController.text = extracted.type!;
        filled.add('品種・精製');
      }
      if (matchedOrigin != null) {
        _selectedOriginId = matchedOrigin.id;
        filled.add('産地');
      }
      if (extracted.roastLevel != null) {
        _roastLevel = extracted.roastLevel;
        _roastChoices = _withCurrentValue(_roastOptions, _roastLevel);
        filled.add('煎り度');
      }
      if (extracted.roastDate != null) {
        _roastDate = extracted.roastDate;
        filled.add('焙煎日');
      }
    });

    if (!mounted) return;
    var message = filled.isEmpty ? '反映できる項目がありませんでした。' : '自動入力しました: ${filled.join('、')}(内容を確認してください)';
    if (extracted.origin != null && matchedOrigin == null) {
      message += '\n産地「$unmatchedOrigin」は既存の産地に一致しなかったため未選択です。必要なら「新規産地追加」から登録してください。';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _askApiKey() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini APIキーを入力'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'APIキー',
            hintText: 'Google Gemini のAPIキー',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('保存')),
        ],
      ),
    );
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
    // T4-1e(設計書§3.2): 選択されたOriginMasterのnameJaをoriginへ同時コピーする
    // (既存のCoffeeRecord.originコピー処理・後方互換を壊さないため)。
    final origins = ref.read(originMasterProvider).value ?? const [];
    final selectedOrigin = _resolveById(origins, _selectedOriginId, (o) => o.id);
    final bean = BeanMaster(
      id: _isEdit ? edit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      roastLevel: _roastLevel ?? '',
      origin: selectedOrigin?.nameJa ?? edit?.origin ?? '',
      originId: _selectedOriginId ?? '',
      roastDate: _roastDate,
      store: _storeController.text.trim(),
      type: _typeController.text.trim(),
      imageUrl: _imageUrl,
      beanImageUrl: _beanImageUrl,
      infoImageUrl: _infoImageUrl,
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
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _isExtracting ? null : _extractFromImage,
                icon: _isExtracting
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(_isExtracting ? '抽出中...' : 'パッケージ画像から自動入力(AI)'),
              ),
            ),
            const SizedBox(height: 8),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ref.watch(originMasterProvider).when(
                        data: (origins) => DropdownButtonFormField<OriginMaster>(
                          decoration: const InputDecoration(labelText: '産地'),
                          value: _resolveById(origins, _selectedOriginId, (o) => o.id),
                          isExpanded: true,
                          items: [
                            for (final o in origins)
                              DropdownMenuItem(value: o, child: Text(o.nameJa)),
                          ],
                          onChanged: (v) => setState(() => _selectedOriginId = v?.id),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => Text('産地読み込みエラー: $e'),
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '新規産地追加',
                  onPressed: _addNewOrigin,
                ),
              ],
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
            MockDateField(
              label: '焙煎日(任意)',
              initialValue: _roastDate,
              onChanged: (v) => _roastDate = v,
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
              label: 'パッケージ画像',
              initialImageUrl: _imageUrl,
              onImageUploaded: (url) => _imageUrl = url,
            ),
            const SizedBox(height: 16),
            ImageUploadField(
              label: '豆画像',
              initialImageUrl: _beanImageUrl,
              onImageUploaded: (url) => _beanImageUrl = url,
            ),
            const SizedBox(height: 16),
            ImageUploadField(
              label: '情報画像(説明書き等)',
              initialImageUrl: _infoImageUrl,
              onImageUploaded: (url) => _infoImageUrl = url,
            ),
          ],
        ),
      ],
    );
  }
}
