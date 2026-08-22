// ignore_for_file: always_use_package_imports, avoid_catches_without_on_clauses
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bean_master.dart';
import '../../models/bean_purchase.dart';
import '../../models/origin_master.dart';
import '../../models/store_master.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/ai_analysis_service.dart';
import '../../services/ai_key_service.dart';
import '../../services/data_service.dart';
import '../../services/image_service.dart';
import '../../widgets/image_upload_field.dart';
import '../../utils/bean_storage.dart';
import '../../widgets/roast_level_slider.dart';
import '../roast_guide_screen.dart';
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
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _initialQuantityController = TextEditingController();
  String? _roastLevel;
  String? _storageLocation;
  DateTime? _purchaseDate;
  DateTime? _roastDate;
  bool _isInStock = true;
  bool? _seekOptimalConditions;
  String? _imageUrl;
  String? _beanImageUrl;
  String? _infoImageUrl;
  bool _isSaving = false;
  bool _isExtracting = false;

  /// T4-1e(設計書§3.2): 産地はOriginMaster選択に置換(自由入力の`_originController`は廃止)。
  String? _selectedOriginId;

  /// T3-69(設計書§9): 購入店はStoreMaster選択に置換(自由入力の`_storeController`は廃止)。
  /// 未選択の場合、編集時は既存の`store`自由入力文字列を保存時にそのまま残す
  /// (店名不明な旧データ・非店舗値3件の後方互換のため)。
  String? _selectedStoreId;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;
    _nameController.text = edit?.name ?? '';
    _typeController.text = edit?.type ?? '';
    _initialQuantityController.text = edit?.initialQuantityGrams?.toStringAsFixed(1) ?? '';
    _roastLevel = (edit?.roastLevel.isNotEmpty ?? false) ? edit!.roastLevel : null;
    _storageLocation =
        (edit?.storageLocation.isNotEmpty ?? false) ? edit!.storageLocation : null;
    _purchaseDate = edit?.purchaseDate;
    _roastDate = edit?.roastDate;
    _isInStock = edit?.isInStock ?? true;
    _seekOptimalConditions = edit?.seekOptimalConditions;
    _imageUrl = edit?.imageUrl;
    _beanImageUrl = edit?.beanImageUrl;
    _infoImageUrl = edit?.infoImageUrl;
    _selectedOriginId = (edit?.originId.isNotEmpty ?? false) ? edit!.originId : null;
    _selectedStoreId = (edit?.storeId.isNotEmpty ?? false) ? edit!.storeId : null;
  }

  /// T3-50: `bool?`(未回答/探索する/探索しない)を`MockChoiceChips`の3択と
  /// 相互変換する。
  static const _seekOptimalOptions = ['未回答', '探索する', '探索しない'];

  static String _seekOptimalToLabel(bool? v) {
    if (v == true) return '探索する';
    if (v == false) return '探索しない';
    return '未回答';
  }

  static bool? _seekOptimalFromLabel(String? label) {
    if (label == '探索する') return true;
    if (label == '探索しない') return false;
    return null;
  }

  static T? _resolveById<T>(List<T> items, String? id, String Function(T) idOf) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  /// T3-69(設計書§5.4): 購入店マスタに未登録の店を最小構成(店名のみ、028の
  /// 必須項目と同じ)で追加する。詳細情報は後で027の編集画面から補完する想定。
  Future<void> _addNewStore() async {
    final nameController = TextEditingController();

    final created = await showDialog<StoreMaster>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('新規購入店追加'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '店名(必須)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(dialogContext).pop(
                  StoreMaster(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                  ),
                );
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );

    if (created == null) return;
    try {
      await ref.read(dataServiceProvider).addStore(created);
      debugPrint('[Antigravity] Action: 購入店マスタ追加 (id=${created.id})');
      ref.read(storeMasterProvider.notifier).addOptimistic(created);
      setState(() => _selectedStoreId = created.id);
    } catch (e) {
      debugPrint('[Antigravity] Error: 購入店マスタ追加に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('購入店の追加に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// T3-30/T3-35/T3-41: パッケージ/説明カード画像(ファイル選択またはカメラ撮影)を
  /// Gemini Visionに渡し豆情報を抽出、抽出できた項目のみフォームへ反映する
  /// (専用ページは作らず012内で完結)。カメラ撮影の場合は、撮影画像をAI抽出に
  /// 使うと同時に情報画像(T3-34)として保存し豆に紐付ける(終了条件)。
  /// ファイル/カメラの選択ダイアログと取得ロジックはT3-41で`image_upload_field.dart`の
  /// `pickImageFile`へ共通化した(全マスターの画像アップロード欄と同じ経路)。
  Future<void> _extractFromImage() async {
    // T5-B0c: `pickImageFile`内部の画像リサイズ(`compute`経由)が例外を投げた場合
    // ここで未捕捉のままだとユーザーに何も表示されずボタンが無反応に見えるため、
    // 取得段階の例外もtry/catchで拾う(adversaryレビュー指摘)。
    final ({PlatformFile file, ImagePickSource source})? picked;
    try {
      picked = await pickImageFile(context);
    } catch (e) {
      debugPrint('[Antigravity] Error: 画像の取得に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の取得に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (picked == null || picked.file.bytes == null) return;

    final bytes = Uint8List.fromList(picked.file.bytes!);
    await _runBeanImageExtraction(
      bytes: bytes,
      filename: picked.file.name,
      saveAsInfoImage: picked.source == ImagePickSource.camera,
    );
  }

  Future<void> _runBeanImageExtraction({
    required Uint8List bytes,
    required String filename,
    required bool saveAsInfoImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? apiKey;
    try {
      apiKey = await ref.read(aiKeyServiceProvider).readKey();
    } on AiKeyUnavailableException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if ((apiKey == null || apiKey.isEmpty) && mounted) {
      apiKey = await _askApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        try {
          await ref.read(aiKeyServiceProvider).saveKey(apiKey);
        } on AiKeyUnavailableException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
          return;
        }
      }
    }
    if (apiKey == null || apiKey.isEmpty) return;

    setState(() => _isExtracting = true);
    try {
      // T5-A104: AsyncErrorの場合`.value`は例外を投げるため`.valueOrNull`を使う。
      final origins = ref.read(originMasterProvider).valueOrNull ?? const [];
      final stores = ref.read(storeMasterProvider).valueOrNull ?? const [];
      final preferredModel = prefs.getString('gemini_model');
      debugPrint('[Antigravity] Action: 豆情報のAI抽出を実行 (file=$filename, camera=$saveAsInfoImage)');
      final extracted = await ref.read(aiAnalysisServiceProvider).extractBeanInfoFromImage(
            imageBytes: bytes,
            mimeType: _mimeTypeFromName(filename),
            knownOrigins: origins.map((o) => o.nameJa).toList(),
            apiKey: apiKey,
            preferredModel: preferredModel,
          );
      _applyExtractedInfo(extracted, origins, stores);

      if (saveAsInfoImage) {
        final url = await ref.read(imageServiceProvider).saveImage(
              PlatformFile(name: filename, size: bytes.length, bytes: bytes),
            );
        if (url != null) {
          debugPrint('[Antigravity] Action: 撮影画像を情報画像として保存 (url=$url)');
          setState(() => _infoImageUrl = url);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('撮影した画像を情報画像として保存しました')),
            );
          }
        } else {
          debugPrint('[Antigravity] Error: 撮影画像の情報画像への保存に失敗');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('撮影画像の情報画像への保存に失敗しました'), backgroundColor: Colors.red),
            );
          }
        }
      }
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

  void _applyExtractedInfo(
    ExtractedBeanInfo extracted,
    List<OriginMaster> origins,
    List<StoreMaster> stores,
  ) {
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

    // T3-69: 購入店も産地と同じくAI抽出結果を既存の購入店マスタへ自動照合する。
    final unmatchedStore = extracted.store;
    StoreMaster? matchedStore;
    if (extracted.store != null) {
      for (final s in stores) {
        if (s.name == extracted.store || s.name.contains(extracted.store!) || extracted.store!.contains(s.name)) {
          matchedStore = s;
          break;
        }
      }
    }

    setState(() {
      if (extracted.name != null) {
        _nameController.text = extracted.name!;
        filled.add('豆の名前');
      }
      if (matchedStore != null) {
        _selectedStoreId = matchedStore.id;
        filled.add('購入店');
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
        filled.add('煎り度');
      }
      if (extracted.roastDate != null) {
        _roastDate = extracted.roastDate;
        filled.add('焙煎日');
      }
    });

    if (!mounted) return;
    var message = filled.isEmpty ? '反映できる項目がありませんでした。' : '自動入力しました: ${filled.join('、')}(内容を確認してください)';
    if (extracted.store != null && matchedStore == null) {
      message += '\n購入店「$unmatchedStore」は既存の購入店に一致しなかったため未選択です。必要なら「新規購入店追加」から登録してください。';
    }
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
    // T5-A104: AsyncErrorの場合`.value`は例外を投げるため`.valueOrNull`を使う。
    final origins = ref.read(originMasterProvider).valueOrNull ?? const [];
    final selectedOrigin = _resolveById(origins, _selectedOriginId, (o) => o.id);
    // T3-69(設計書§9): 選択されたStoreMasterのnameをstoreへ同時コピーする
    // (originIdと同じパターン。未選択時は既存のstore自由入力文字列を維持=後方互換)。
    final stores = ref.read(storeMasterProvider).valueOrNull ?? const [];
    final selectedStore = _resolveById(stores, _selectedStoreId, (s) => s.id);
    final bean = BeanMaster(
      id: _isEdit ? edit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      roastLevel: _roastLevel ?? '',
      origin: selectedOrigin?.nameJa ?? edit?.origin ?? '',
      originId: _selectedOriginId ?? '',
      roastDate: _roastDate,
      store: selectedStore?.name ?? edit?.store ?? '',
      storeId: _selectedStoreId ?? '',
      type: _typeController.text.trim(),
      imageUrl: _imageUrl,
      beanImageUrl: _beanImageUrl,
      infoImageUrl: _infoImageUrl,
      purchaseDate: _purchaseDate,
      firstUseDate: edit?.firstUseDate,
      lastUseDate: edit?.lastUseDate,
      isInStock: _isInStock,
      initialQuantityGrams: double.tryParse(_initialQuantityController.text.trim()),
      storageLocation: _storageLocation ?? '',
      seekOptimalConditions: _seekOptimalConditions,
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
      if (_isEdit) {
        ref.read(beanMasterProvider.notifier).updateOptimistic(bean);
      } else {
        ref.read(beanMasterProvider.notifier).addOptimistic(bean);
      }

      // T3-63b(設計書§5.1): 新規登録時のみ、購入日が入力されていれば初回購入を
      // 購入履歴へ1行追記する。固定ID`bp_init_<豆ID>`により遡及登録スクリプトを
      // 後から流しても衝突しない。失敗しても豆の登録自体は成功扱いにする。
      var purchaseHistoryFailed = false;
      if (!_isEdit && _purchaseDate != null) {
        final purchase = BeanPurchase(
          id: 'bp_init_${bean.id}',
          beanId: bean.id,
          purchasedAt: _purchaseDate,
          roastDate: _roastDate,
          quantityGrams: bean.initialQuantityGrams,
          storeId: bean.storeId,
          storeName: bean.store,
          createdAt: DateTime.now(),
        );
        try {
          await service.addBeanPurchase(purchase);
          ref.read(beanPurchasesProvider.notifier).addOptimistic(purchase);
          debugPrint('[Antigravity] Action: 初回購入を記録 (豆ID=${bean.id})');
        } catch (e) {
          purchaseHistoryFailed = true;
          debugPrint('[Antigravity] Error: 初回購入履歴の記録に失敗 (豆ID=${bean.id}) $e');
        }
      }

      if (mounted) {
        final message = _isEdit
            ? '豆を更新しました'
            : (purchaseHistoryFailed ? '豆を登録しましたが購入履歴の記録に失敗しました' : '豆を登録しました');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ref.watch(storeMasterProvider).when(
                        data: (stores) => DropdownButtonFormField<StoreMaster>(
                          decoration: const InputDecoration(labelText: '購入店'),
                          value: _resolveById(stores, _selectedStoreId, (s) => s.id),
                          isExpanded: true,
                          items: [
                            for (final s in stores)
                              DropdownMenuItem(value: s, child: Text(s.name)),
                          ],
                          onChanged: (v) => setState(() => _selectedStoreId = v?.id),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => Text('購入店読み込みエラー: $e'),
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '新規購入店追加',
                  onPressed: _addNewStore,
                ),
              ],
            ),
            if ((_selectedStoreId == null || _selectedStoreId!.isEmpty) &&
                (widget.editData?.store.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '未紐付けの旧データ: 「${widget.editData!.store}」(該当する購入店があれば上で選択してください)',
                  style: const TextStyle(fontSize: 12, color: kMocha),
                ),
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
            RoastLevelSlider(
              value: _roastLevel,
              onChanged: (v) => setState(() => _roastLevel = v),
              trailing: RoastGuideLink(currentLabel: _roastLevel),
            ),
            MockChoiceChips(
              label: '保存場所',
              options: beanStorageLocations,
              initialValue: _storageLocation,
              onChanged: (v) => setState(() => _storageLocation = v),
            ),
          ],
        ),
        FormSection(
          icon: Icons.science_outlined,
          title: '最適条件の探索',
          children: [
            const Text(
              'この豆で最適なメソッド・湯温・粒度を探しますか?回答するとダッシュボードの案内が表示されなくなります。',
              style: TextStyle(fontSize: 12, color: kMocha),
            ),
            const SizedBox(height: 8),
            MockChoiceChips(
              label: '最適条件を探索するか',
              options: _seekOptimalOptions,
              initialValue: _seekOptimalToLabel(_seekOptimalConditions),
              onChanged: (v) =>
                  setState(() => _seekOptimalConditions = _seekOptimalFromLabel(v)),
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
