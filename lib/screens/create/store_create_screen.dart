// ignore_for_file: always_use_package_imports, avoid_catches_without_on_clauses
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/store_master.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/ai_analysis_service.dart';
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
  bool _isFetchingInfo = false;

  /// T3-70(設計書§8.4): AI自動取得を「反映」したときの出典。手入力のみの場合は空のまま。
  String _sourceUrl = '';
  DateTime? _infoFetchedAt;

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
    _sourceUrl = edit?.sourceUrl ?? '';
    _infoFetchedAt = edit?.infoFetchedAt;
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

  /// T3-70(設計書§8.2①): 028の店名欄横の「AIで自動入力」ボタンから起動する。
  /// T3-78: 似た店名を誤って断定するリスクを避けるため、候補(`candidates`)が
  /// 1件でもあれば必ず候補選択ダイアログを経てから確定情報を再取得する。
  /// 取得結果は即座に反映せず、確認ダイアログでのユーザー確認を経てから反映する
  /// (§8.4、無条件保存の禁止)。
  Future<void> _fetchStoreInfoWithAi() async {
    final storeName = _nameController.text.trim();
    if (storeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に店名を入力してください')),
      );
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

    final preferredModel = prefs.getString('gemini_model');
    final hint = _prefectureController.text.trim().isEmpty ? null : _prefectureController.text.trim();

    // 確認ダイアログ・候補選択ダイアログはユーザー入力待ちのため、
    // その間はスピナー(_isFetchingInfo)を止める(通信中のみtrueにする、
    // でなければ確認待ち中もインジケータが回り続けpumpAndSettleが収束しないバグになる)。
    setState(() => _isFetchingInfo = true);
    var candidate = await _runStoreInfoFetch(storeName, hint, apiKey, preferredModel);
    if (mounted) setState(() => _isFetchingInfo = false);
    if (candidate == null) return;

    if (candidate.candidates.isNotEmpty) {
      if (!mounted) return;
      final selected = await _showCandidateSelectionDialog(candidate.candidates);
      if (selected == null || !mounted) return;
      setState(() => _isFetchingInfo = true);
      candidate = await _runStoreInfoFetch('$storeName($selected)', hint, apiKey, preferredModel);
      if (mounted) setState(() => _isFetchingInfo = false);
      if (candidate == null) return;
    }

    if (candidate.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('情報を取得できませんでした。手動で入力してください。'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
      return;
    }

    if (mounted) await _showConfirmDialogAndApply(candidate);
  }

  /// T3-78: フォームに入力済みの項目を検索の絞り込みヒントとして渡す(空欄は渡さない)。
  Future<StoreInfoCandidate?> _runStoreInfoFetch(
    String storeName,
    String? hint,
    String apiKey,
    String? preferredModel,
  ) async {
    String? nonEmpty(String v) => v.trim().isEmpty ? null : v.trim();
    try {
      debugPrint('[Antigravity] Action: 購入店情報のAI取得を実行 (store=$storeName)');
      return await ref.read(aiAnalysisServiceProvider).fetchStoreInfo(
            storeName: storeName,
            hintPrefecture: hint,
            hintAddress: nonEmpty(_addressController.text),
            hintUrl: nonEmpty(_urlController.text),
            hintPhone: nonEmpty(_phoneController.text),
            hintBusinessHours: nonEmpty(_businessHoursController.text),
            hintClosedDays: nonEmpty(_closedDaysController.text),
            hintOpenedYear: nonEmpty(_openedYearController.text),
            hintHasOnlineShop: _hasOnlineShop ? true : null,
            hintHasPhysicalStore: _hasPhysicalStore ? true : null,
            hintHasRoastery: _hasRoastery ? true : null,
            hintBeanTendency: nonEmpty(_beanTendencyController.text),
            hintSnsUrl: nonEmpty(_snsUrlController.text),
            apiKey: apiKey,
            preferredModel: preferredModel,
          );
    } catch (e) {
      debugPrint('[Antigravity] Error: 購入店情報のAI取得に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取得に失敗しました: $e\n手動で入力してください。'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
      return null;
    }
  }

  /// [candidates]は呼び出し側で非空であることを保証済み(T3-78)。
  Future<String?> _showCandidateSelectionDialog(List<String> candidates) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗の候補を確認してください'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AIが検索した候補です。該当する店舗を選んでください。'),
              const SizedBox(height: 12),
              for (final c in candidates)
                ListTile(
                  title: Text(c),
                  onTap: () => Navigator.pop(context, c),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ],
      ),
    );
  }

  Future<void> _showConfirmDialogAndApply(StoreInfoCandidate candidate) async {
    final existing = <String>{
      if (_formalNameController.text.trim().isNotEmpty) 'formalName',
      if (_urlController.text.trim().isNotEmpty) 'url',
      if (_prefectureController.text.trim().isNotEmpty) 'prefecture',
      if (_addressController.text.trim().isNotEmpty) 'address',
      if (_hasOnlineShop) 'hasOnlineShop',
      if (_hasPhysicalStore) 'hasPhysicalStore',
      if (_hasRoastery) 'hasRoastery',
      if (_beanTendencyController.text.trim().isNotEmpty) 'beanTendency',
      if (_snsUrlController.text.trim().isNotEmpty) 'snsUrl',
      if (_businessHoursController.text.trim().isNotEmpty) 'businessHours',
      if (_closedDaysController.text.trim().isNotEmpty) 'closedDays',
      if (_phoneController.text.trim().isNotEmpty) 'phone',
      if (_openedYearController.text.trim().isNotEmpty) 'openedYear',
    };

    final applied = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _StoreInfoConfirmDialog(candidate: candidate, existingNonEmptyFields: existing),
    );
    if (applied == null || !mounted) return;
    if (applied.isEmpty) return;

    setState(() {
      if (applied.containsKey('formalName')) _formalNameController.text = applied['formalName'] as String;
      if (applied.containsKey('url')) _urlController.text = applied['url'] as String;
      if (applied.containsKey('prefecture')) _prefectureController.text = applied['prefecture'] as String;
      if (applied.containsKey('address')) _addressController.text = applied['address'] as String;
      if (applied.containsKey('hasOnlineShop')) _hasOnlineShop = applied['hasOnlineShop'] as bool;
      if (applied.containsKey('hasPhysicalStore')) _hasPhysicalStore = applied['hasPhysicalStore'] as bool;
      if (applied.containsKey('hasRoastery')) _hasRoastery = applied['hasRoastery'] as bool;
      if (applied.containsKey('beanTendency')) _beanTendencyController.text = applied['beanTendency'] as String;
      if (applied.containsKey('snsUrl')) _snsUrlController.text = applied['snsUrl'] as String;
      if (applied.containsKey('businessHours')) _businessHoursController.text = applied['businessHours'] as String;
      if (applied.containsKey('closedDays')) _closedDaysController.text = applied['closedDays'] as String;
      if (applied.containsKey('phone')) _phoneController.text = applied['phone'] as String;
      if (applied.containsKey('openedYear')) _openedYearController.text = applied['openedYear'] as String;
      _sourceUrl = candidate.sourceUrls.join('\n');
      _infoFetchedAt = DateTime.now();
    });

    debugPrint('[Antigravity] Action: 購入店情報のAI取得結果を反映 (項目数=${applied.length})');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AIの取得結果を反映しました(${applied.length}項目)。内容を確認してください。'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
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
      sourceUrl: _sourceUrl,
      infoFetchedAt: _infoFetchedAt,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MockTextField(
                    label: '店名',
                    hint: '例: Navy',
                    required: true,
                    controller: _nameController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton(
                    icon: _isFetchingInfo
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_outlined),
                    tooltip: 'AIで自動入力',
                    onPressed: _isFetchingInfo ? null : _fetchStoreInfoWithAi,
                  ),
                ),
              ],
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

/// T3-70(設計書§8.4): AI取得結果の確認ダイアログ。無条件保存は禁止のため、
/// 項目ごとにチェックボックスで選ばせてから「反映」を押した項目だけを返す。
/// `confidence: low`と既に値が入っている項目は既定チェックOFF(上書き事故の防止)。
class _StoreInfoRow {
  final String key;
  final String label;
  final dynamic value;
  final String displayValue;
  final String confidence;

  const _StoreInfoRow({
    required this.key,
    required this.label,
    required this.value,
    required this.displayValue,
    required this.confidence,
  });
}

class _StoreInfoConfirmDialog extends StatefulWidget {
  final StoreInfoCandidate candidate;
  final Set<String> existingNonEmptyFields;

  const _StoreInfoConfirmDialog({required this.candidate, required this.existingNonEmptyFields});

  @override
  State<_StoreInfoConfirmDialog> createState() => _StoreInfoConfirmDialogState();
}

class _StoreInfoConfirmDialogState extends State<_StoreInfoConfirmDialog> {
  late final List<_StoreInfoRow> _rows = _buildRows();
  late final Map<String, bool> _checked = {
    for (final r in _rows) r.key: r.confidence != 'low' && !widget.existingNonEmptyFields.contains(r.key),
  };

  List<_StoreInfoRow> _buildRows() {
    final c = widget.candidate;
    String conf(String key) => c.confidence[key] ?? 'low';
    final rows = <_StoreInfoRow>[];
    void addString(String key, String label, String? value) {
      if (value == null) return;
      rows.add(_StoreInfoRow(key: key, label: label, value: value, displayValue: value, confidence: conf(key)));
    }

    void addBool(String key, String label, bool? value) {
      if (value == null) return;
      rows.add(_StoreInfoRow(
          key: key, label: label, value: value, displayValue: value ? 'あり' : 'なし', confidence: conf(key)));
    }

    addString('formalName', '正式名称', c.formalName);
    addString('url', 'URL', c.url);
    addString('prefecture', '都道府県', c.prefecture);
    addString('address', '住所', c.address);
    addBool('hasOnlineShop', 'オンライン販売', c.hasOnlineShop);
    addBool('hasPhysicalStore', '実店舗', c.hasPhysicalStore);
    addBool('hasRoastery', '焙煎所併設', c.hasRoastery);
    addString('beanTendency', '取扱豆の傾向', c.beanTendency);
    addString('snsUrl', 'SNS', c.snsUrl);
    addString('businessHours', '営業時間', c.businessHours);
    addString('closedDays', '定休日', c.closedDays);
    addString('phone', '電話番号', c.phone);
    addString('openedYear', '開業年', c.openedYear);
    return rows;
  }

  String _confidenceLabel(String c) => switch (c) {
        'high' => '確信度高',
        'medium' => '確信度中',
        _ => '確信度低',
      };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AIによる取得結果の確認'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('チェックした項目だけが反映されます。内容を確認してからチェックしてください。'),
              const SizedBox(height: 8),
              for (final r in _rows)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _checked[r.key] ?? false,
                  onChanged: (v) => setState(() => _checked[r.key] = v ?? false),
                  title: Text('${r.label}  ${r.displayValue}'),
                  subtitle: Text(_confidenceLabel(r.confidence)),
                ),
              if (widget.candidate.sourceUrls.isNotEmpty) ...[
                const Divider(),
                const Text('出典', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final url in widget.candidate.sourceUrls)
                  Text(url, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: () {
            final applied = <String, dynamic>{
              for (final r in _rows)
                if (_checked[r.key] == true) r.key: r.value,
            };
            Navigator.pop(context, applied);
          },
          child: const Text('反映'),
        ),
      ],
    );
  }
}
