import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean_master.dart';
import '../models/coffee_record.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../providers/data_providers.dart';
import '../services/data_service.dart';
import '../widgets/bean_image.dart';

/// T3-76: 002/003からの編集導線。旧実装は`CoffeeRecord`のごく一部しか編集
/// できず、豆・器具・メソッド等のマスタ参照フィールドが編集不可だった。
/// 031(`brew_evaluation_screen.dart`)のドロップダウン選択パターン(`_resolveById`
/// によるマスタ一覧からの選択、サムネイル付きラベル)を再利用し、直接編集させると
/// 存在しないIDになりうる参照フィールドを安全に編集できるようにした。
class LogEditScreen extends ConsumerStatefulWidget {
  final CoffeeRecord log;

  const LogEditScreen({super.key, required this.log});

  @override
  ConsumerState<LogEditScreen> createState() => _LogEditScreenState();
}

class _LogEditScreenState extends ConsumerState<LogEditScreen> {
  static const _tasteOptions = ['すっきり', 'バランス', 'コク深い'];
  static const _concentrationOptions = ['薄い', 'ちょうど良い', '濃い'];

  late DateTime _brewedAt;
  late TextEditingController _beanWeightController;
  late TextEditingController _waterAmountController;
  late TextEditingController _tempController;
  late TextEditingController _timeController;
  late TextEditingController _grindSizeController;
  late TextEditingController _commentController;
  late TextEditingController _bloomingWaterController;
  late TextEditingController _bloomingTimeController;

  // Scores
  late int _scoreFragrance;
  late int _scoreAcidity;
  late int _scoreBitterness;
  late int _scoreSweetness;
  late int _scoreComplexity;
  late int _scoreFlavor;
  late int _scoreOverall;

  // T3-76: マスタ参照フィールドはID文字列を真実の値として保持し、ドロップダウンの
  // 表示値は都度プロバイダーの一覧から`_resolveById`で解決する
  // (`DropdownButtonFormField.value`はitems内と同一インスタンスである必要があるため)。
  late String _beanId;
  late String _grinderId;
  late String _dripperId;
  late String _filterId;
  late String _methodId;
  late String? _taste;
  late String? _concentration;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    _brewedAt = log.brewedAt;
    _beanWeightController = TextEditingController(text: log.beanWeight.toStringAsFixed(1));
    _waterAmountController = TextEditingController(text: log.totalWater.toStringAsFixed(1));
    _tempController = TextEditingController(text: log.temperature.toStringAsFixed(1));
    _timeController = TextEditingController(text: log.totalTime.toString());
    _grindSizeController = TextEditingController(text: log.grindSize);
    _commentController = TextEditingController(text: log.comment);
    _bloomingWaterController = TextEditingController(text: log.bloomingWater.toStringAsFixed(1));
    _bloomingTimeController = TextEditingController(text: log.bloomingTime.toString());

    _scoreFragrance = log.scoreFragrance;
    _scoreAcidity = log.scoreAcidity;
    _scoreBitterness = log.scoreBitterness;
    _scoreSweetness = log.scoreSweetness;
    _scoreComplexity = log.scoreComplexity;
    _scoreFlavor = log.scoreFlavor;
    _scoreOverall = log.scoreOverall;

    _beanId = log.beanId;
    _grinderId = log.grinderId;
    _dripperId = log.dripperId;
    _filterId = log.filterId;
    _methodId = log.methodId;
    // 031(brew_evaluation_screen.dart)と同じ方針: 未選択のまま保存されて
    // 空文字がずっと保持されるのを避けるため、中央値をデフォルトにしておく。
    _taste = _optionOrNull(_tasteOptions, log.taste) ?? _tasteOptions[1];
    _concentration = _optionOrNull(_concentrationOptions, log.concentration) ?? _concentrationOptions[1];
  }

  @override
  void dispose() {
    _beanWeightController.dispose();
    _waterAmountController.dispose();
    _tempController.dispose();
    _timeController.dispose();
    _grindSizeController.dispose();
    _commentController.dispose();
    _bloomingWaterController.dispose();
    _bloomingTimeController.dispose();
    super.dispose();
  }

  static String? _optionOrNull(List<String> options, String? value) {
    if (value == null || value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  /// 031(`brew_evaluation_screen.dart`)と同一のヘルパー: IDが一致する要素を
  /// リストから都度解決して`DropdownButtonFormField.value`に渡す。
  static T? _resolveById<T>(List<T> items, String id, String Function(T) idOf) {
    if (id.isEmpty) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  bool _isTasteApplicable(List<MethodMaster> methods) {
    final method = _resolveById(methods, _methodId, (m) => m.id);
    return method?.name.contains('4:6') ?? false;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final beans = ref.read(beanMasterProvider).valueOrNull ?? [];
    final methods = ref.read(methodMasterProvider).valueOrNull ?? [];
    final bean = _resolveById(beans, _beanId, (b) => b.id);
    if (bean == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('豆を選択してください'), backgroundColor: Colors.red),
      );
      return;
    }
    final isTasteApplicable = _isTasteApplicable(methods);

    setState(() => _isSaving = true);

    try {
      final updatedLog = widget.log.copyWith(
        brewedAt: _brewedAt,
        beanWeight: double.tryParse(_beanWeightController.text) ?? widget.log.beanWeight,
        totalWater: double.tryParse(_waterAmountController.text) ?? widget.log.totalWater,
        temperature: double.tryParse(_tempController.text) ?? widget.log.temperature,
        totalTime: int.tryParse(_timeController.text) ?? widget.log.totalTime,
        grindSize: _grindSizeController.text,
        comment: _commentController.text,
        bloomingWater: double.tryParse(_bloomingWaterController.text) ?? widget.log.bloomingWater,
        bloomingTime: int.tryParse(_bloomingTimeController.text) ?? widget.log.bloomingTime,
        scoreFragrance: _scoreFragrance,
        scoreAcidity: _scoreAcidity,
        scoreBitterness: _scoreBitterness,
        scoreSweetness: _scoreSweetness,
        scoreComplexity: _scoreComplexity,
        scoreFlavor: _scoreFlavor,
        scoreOverall: _scoreOverall,
        beanId: bean.id,
        roastLevel: bean.roastLevel,
        origin: bean.origin,
        originId: bean.originId,
        beanImageUrl: bean.imageUrl,
        grinderId: _grinderId,
        dripperId: _dripperId,
        filterId: _filterId,
        methodId: _methodId,
        // T3-18と同じ方針: 4:6メソッド以外では味わい入力欄が非表示のため空文字で保存する。
        taste: isTasteApplicable ? (_taste ?? '') : '',
        concentration: isTasteApplicable ? (_concentration ?? '') : '',
      );

      await ref.read(dataServiceProvider).updateCoffeeRecord(updatedLog);
      debugPrint('[Antigravity] Action: 002/003から抽出記録を編集 (id=${updatedLog.id}, bean=${updatedLog.beanId})');

      // Refresh logs
      ref.invalidate(coffeeRecordsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('記録を更新しました')));
        Navigator.pop(context); // Close Edit
        Navigator.pop(context); // Close Detail (optional, or rely on nav stack)
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: 抽出記録の編集保存に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _brewedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_brewedAt),
      );
      if (time != null) {
        setState(() {
          _brewedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(methodMasterProvider);
    final beansAsync = ref.watch(beanMasterProvider);
    final grindersAsync = ref.watch(grinderMasterProvider);
    final drippersAsync = ref.watch(dripperMasterProvider);
    final filtersAsync = ref.watch(filterMasterProvider);
    final methods = methodsAsync.valueOrNull ?? [];
    final isTasteApplicable = _isTasteApplicable(methods);

    return Scaffold(
      appBar: AppBar(
        title: const Text('抽出記録を編集'),
        actions: [
          IconButton(
            icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('日時'),
              subtitle: Text('${_brewedAt.year}/${_brewedAt.month}/${_brewedAt.day} ${_brewedAt.hour}:${_brewedAt.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
            ),
            const Divider(),
            _buildSection('豆・器具・メソッド', [
              beansAsync.when(
                data: (beans) => DropdownButtonFormField<BeanMaster>(
                  decoration: const InputDecoration(labelText: '豆'),
                  value: _resolveById(beans, _beanId, (b) => b.id),
                  isExpanded: true,
                  items: [
                    for (final b in beans)
                      DropdownMenuItem(value: b, child: _thumbnailLabel(b.imageUrl, Icons.coffee, b.name)),
                  ],
                  onChanged: (v) => setState(() => _beanId = v?.id ?? ''),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('豆読み込みエラー: $e'),
              ),
              const SizedBox(height: 12),
              grindersAsync.when(
                data: (grinders) => DropdownButtonFormField<GrinderMaster>(
                  decoration: const InputDecoration(labelText: 'グラインダー'),
                  value: _resolveById(grinders, _grinderId, (g) => g.id),
                  isExpanded: true,
                  items: [
                    for (final g in grinders)
                      DropdownMenuItem(value: g, child: _thumbnailLabel(g.imageUrl, Icons.settings, g.name)),
                  ],
                  onChanged: (v) => setState(() => _grinderId = v?.id ?? ''),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('グラインダー読み込みエラー: $e'),
              ),
              const SizedBox(height: 12),
              drippersAsync.when(
                data: (drippers) => DropdownButtonFormField<DripperMaster>(
                  decoration: const InputDecoration(labelText: 'ドリッパー'),
                  value: _resolveById(drippers, _dripperId, (d) => d.id),
                  isExpanded: true,
                  items: [
                    for (final d in drippers)
                      DropdownMenuItem(value: d, child: _thumbnailLabel(d.imageUrl, Icons.filter_alt_outlined, d.name)),
                  ],
                  onChanged: (v) => setState(() => _dripperId = v?.id ?? ''),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('ドリッパー読み込みエラー: $e'),
              ),
              const SizedBox(height: 12),
              filtersAsync.when(
                data: (filters) => DropdownButtonFormField<FilterMaster>(
                  decoration: const InputDecoration(labelText: 'フィルター'),
                  value: _resolveById(filters, _filterId, (f) => f.id),
                  isExpanded: true,
                  items: [
                    for (final f in filters)
                      DropdownMenuItem(value: f, child: _thumbnailLabel(f.imageUrl, Icons.filter_frames_outlined, f.name)),
                  ],
                  onChanged: (v) => setState(() => _filterId = v?.id ?? ''),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('フィルター読み込みエラー: $e'),
              ),
              const SizedBox(height: 12),
              methodsAsync.when(
                data: (methods) => DropdownButtonFormField<MethodMaster>(
                  decoration: const InputDecoration(labelText: 'メソッド'),
                  value: _resolveById(methods, _methodId, (m) => m.id),
                  isExpanded: true,
                  items: [
                    for (final m in methods)
                      DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _methodId = v?.id ?? ''),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('メソッド読み込みエラー: $e'),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('抽出パラメータ', [
              _buildNumField(_beanWeightController, '豆量(g)'),
              _buildNumField(_waterAmountController, '総湯量(ml)'),
              _buildNumField(_tempController, '湯温(℃)'),
              _buildNumField(_timeController, '抽出時間(秒)'),
              _buildNumField(_bloomingWaterController, '蒸らし湯量(ml)'),
              _buildNumField(_bloomingTimeController, '蒸らし時間(秒)'),
              _buildTextField(_grindSizeController, '挽き目'),
              _buildTextField(_commentController, 'コメント', maxLines: 3),
            ]),
            if (isTasteApplicable) ...[
              const SizedBox(height: 16),
              _buildSection('味わい', [
                _buildChoiceDropdown('テイスト', _tasteOptions, _taste, (v) => setState(() => _taste = v)),
                const SizedBox(height: 12),
                _buildChoiceDropdown('濃度', _concentrationOptions, _concentration, (v) => setState(() => _concentration = v)),
              ]),
            ],
            const SizedBox(height: 16),
            _buildSection('評価スコア', [
              _buildScoreSlider('香り', _scoreFragrance, (v) => setState(() => _scoreFragrance = v)),
              _buildScoreSlider('酸味', _scoreAcidity, (v) => setState(() => _scoreAcidity = v)),
              _buildScoreSlider('苦味', _scoreBitterness, (v) => setState(() => _scoreBitterness = v)),
              _buildScoreSlider('甘み', _scoreSweetness, (v) => setState(() => _scoreSweetness = v)),
              _buildScoreSlider('複雑さ', _scoreComplexity, (v) => setState(() => _scoreComplexity = v)),
              _buildScoreSlider('風味', _scoreFlavor, (v) => setState(() => _scoreFlavor = v)),
              _buildScoreSlider('総合', _scoreOverall, (v) => setState(() => _scoreOverall = v)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildNumField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildChoiceDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: _optionOrNull(options, value),
      isExpanded: true,
      items: [
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildScoreSlider(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: value.toString(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// 031(`brew_evaluation_screen.dart`)の`_thumbnailLabel`と同一パターン。
  Widget _thumbnailLabel(String? imageUrl, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3EE),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD7CCC8)),
          ),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? BeanImage(imagePath: imageUrl, fit: BoxFit.cover, placeholderIcon: icon)
              : Icon(icon, size: 16, color: const Color(0xFF6D4C41)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
