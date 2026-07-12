import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bean_master.dart';
import '../../models/coffee_record.dart';
import '../../models/equipment_masters.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../models/pending_brew_info.dart';
import '../../services/data_service.dart';
import 'create_form_widgets.dart';

/// 031 抽出結果の評価。
///
/// Cycle 20 T1-2b: 030(抽出レシピ)から実際の抽出情報([PendingBrewInfo])を
/// 引き継ぎ、サマリに表示する。
/// Cycle 20 T2-5a: 評価スコア・コメント入力を状態として保持し、「登録する」で
/// 実際に`CoffeeRecord`を組み立てて`DataService.addCoffeeRecord`に保存する
/// 本実装へ置き換えた。
/// Cycle 20 T2-5b: 原設計(`docs/Beanbase改修案.md`)の「登録が完了したら
/// この画面031に戻ってくる」という記述どおり、登録成功後はダッシュボードへ
/// popせず031に留まり、評価フォームをリセットして連続記録できるようにした。
/// 2件目以降の`brewedAt`は登録時点の現在時刻を使う(030で選んだ日時のまま
/// 複数件登録すると記録が見分けにくくなるため)。豆残量は`calculateBeanRemainingPercent`
/// (T2-2b)がCoffeeRecordの`beanWeight`集計から動的に算出する設計のため、
/// `coffeeRecordsProvider`をinvalidateするだけで001/010の表示に自動反映される。
/// Cycle 20 T3-5: 豆/グラインダー/ドリッパー/フィルター選択と抽出日時を
/// 030から移動し、この画面の入力欄にした(030はメソッド・豆量のみを扱う)。
/// 002からの「評価を継承」(`PendingBrewInfo.bean`等)はこれらの初期値として使う。
/// 「続けて記録」時は器具・豆選択はそのまま維持し(同じ設定で複数杯淹れることが
/// 多いため)、抽出日時のみ登録時点の現在時刻へ進める。
class BrewEvaluationScreen extends ConsumerStatefulWidget {
  final PendingBrewInfo info;

  const BrewEvaluationScreen({super.key, required this.info});

  @override
  ConsumerState<BrewEvaluationScreen> createState() => _BrewEvaluationScreenState();
}

class _BrewEvaluationScreenState extends ConsumerState<BrewEvaluationScreen> {
  static const _tasteOptions = ['すっきり', 'バランス', 'コク深い'];
  static const _concentrationOptions = ['薄い', 'ちょうど良い', '濃い'];

  // MockChoiceChipsはユーザーが実際にタップするまでonChangedを呼ばないため、
  // チップ側のデフォルト選択(initialIndex ?? 1)と同じ値で初期化しておく。
  // そうしないと、ユーザーが一度もチップを触らずに登録した場合に
  // taste/concentrationが空文字のまま保存されてしまう。
  late String? _taste = _optionOrNull(_tasteOptions, widget.info.taste) ?? _tasteOptions[1];
  late String? _concentration =
      _optionOrNull(_concentrationOptions, widget.info.concentration) ?? _concentrationOptions[1];
  late double _scoreFragrance = (widget.info.scoreFragrance ?? 5).toDouble();
  late double _scoreAcidity = (widget.info.scoreAcidity ?? 5).toDouble();
  late double _scoreBitterness = (widget.info.scoreBitterness ?? 5).toDouble();
  late double _scoreSweetness = (widget.info.scoreSweetness ?? 5).toDouble();
  late double _scoreComplexity = (widget.info.scoreComplexity ?? 5).toDouble();
  late double _scoreFlavor = (widget.info.scoreFlavor ?? 5).toDouble();
  late double _scoreOverall = (widget.info.scoreOverall ?? 7).toDouble();
  final _commentController = TextEditingController();
  bool _isSaving = false;

  late DateTime _brewedAt = widget.info.brewedAt;
  late BeanMaster? _bean = widget.info.bean;
  late GrinderMaster? _grinder = widget.info.grinder;
  late DripperMaster? _dripper = widget.info.dripper;
  late FilterMaster? _filter = widget.info.filter;

  /// 登録済み件数(このセッション内)。0件目は030から引き継いだ`info.brewedAt`を
  /// そのまま使い、2件目以降(「続けて記録」)は登録時点の現在時刻を使う。
  int _recordCount = 0;

  /// フォームリセット時にインクリメントし、MockChoiceChips/MockScoreSliderの
  /// keyへ反映することでウィジェットを強制的に再構築(初期値へ戻す)する。
  int _formResetGeneration = 0;

  static String? _optionOrNull(List<String> options, String? value) {
    if (value == null || value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  static int? _optionIndex(List<String> options, String? value) {
    if (value == null) return null;
    final i = options.indexOf(value);
    return i >= 0 ? i : null;
  }

  /// `DropdownButtonFormField.value`はitems内と同一インスタンスである必要が
  /// あるため、IDが一致する要素をリストから都度解決して渡す
  /// (`_bean`等は002からの継承やプロバイダー再取得で別インスタンスになりうる)。
  static T? _resolveById<T>(List<T> items, String? id, String Function(T) idOf) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.info.comment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 評価入力欄をデフォルト値に戻す(`setState`内で呼ぶこと)。
  /// [_formResetGeneration]をインクリメントし、各ウィジェットのkeyに反映して
  /// 強制的に再構築させることで、MockChoiceChips/MockScoreSlider自身が持つ
  /// 内部状態(タップ済みの選択)もあわせてリセットする。
  /// 器具・豆選択(_bean/_grinder/_dripper/_filter)は同じ設定で連続記録する
  /// ことが多いためリセットせず維持する。抽出日時のみ現在時刻へ進める。
  void _resetForm() {
    _formResetGeneration++;
    _taste = _tasteOptions[1];
    _concentration = _concentrationOptions[1];
    _scoreFragrance = 5;
    _scoreAcidity = 5;
    _scoreBitterness = 5;
    _scoreSweetness = 5;
    _scoreComplexity = 5;
    _scoreFlavor = 5;
    _scoreOverall = 7;
    _commentController.clear();
    _brewedAt = DateTime.now();
  }

  Future<void> _pickBrewedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _brewedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_brewedAt),
    );
    if (time == null) return;
    setState(() {
      _brewedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final info = widget.info;
    setState(() => _isSaving = true);
    try {
      final record = CoffeeRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brewedAt: _brewedAt,
        grinderId: _grinder?.id ?? '',
        dripperId: _dripper?.id ?? '',
        filterId: _filter?.id ?? '',
        beanId: _bean?.id ?? '',
        roastLevel: _bean?.roastLevel ?? '',
        origin: _bean?.origin ?? '',
        beanWeight: info.beanWeight,
        grindSize: _grinder?.grindRange ?? '',
        methodId: info.method.id,
        taste: _taste ?? '',
        concentration: _concentration ?? '',
        temperature: info.method.temperature ?? 0,
        bloomingWater: info.bloomingWater,
        totalWater: info.totalWater,
        bloomingTime: info.bloomingTime,
        totalTime: info.totalTime,
        scoreFragrance: _scoreFragrance.round(),
        scoreAcidity: _scoreAcidity.round(),
        scoreBitterness: _scoreBitterness.round(),
        scoreSweetness: _scoreSweetness.round(),
        scoreComplexity: _scoreComplexity.round(),
        scoreFlavor: _scoreFlavor.round(),
        scoreOverall: _scoreOverall.round(),
        comment: _commentController.text.trim(),
        grinderImageUrl: null,
        dripperImageUrl: null,
        filterImageUrl: null,
        beanImageUrl: _bean?.imageUrl,
      );

      final service = ref.read(dataServiceProvider);
      await service.addCoffeeRecord(record);
      debugPrint('[Antigravity] Action: 031から抽出記録を登録 (id=${record.id}, bean=${record.beanId}, method=${record.methodId})');
      ref.invalidate(coffeeRecordsProvider);

      if (!mounted) return;
      setState(() {
        _recordCount++;
        _resetForm();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('抽出記録を登録しました($_recordCount件目)。続けて記録できます')),
      );
    } catch (e) {
      debugPrint('[Antigravity] Error: 031からの抽出記録登録に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final beansAsync = ref.watch(beanMasterProvider);
    final grindersAsync = ref.watch(grinderMasterProvider);
    final drippersAsync = ref.watch(dripperMasterProvider);
    final filtersAsync = ref.watch(filterMasterProvider);

    return CreateFormScaffold(
      screen: AppScreen.brewEvaluation,
      saveLabel: '評価を登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        _BrewSummaryCard(info: info),
        FormSection(
          icon: Icons.coffee_maker_outlined,
          title: '抽出情報',
          children: [
            beansAsync.when(
              data: (beans) {
                final inStock = beans.where((b) => b.isInStock).toList();
                return DropdownButtonFormField<BeanMaster>(
                  decoration: const InputDecoration(labelText: '豆'),
                  value: _resolveById(inStock, _bean?.id, (b) => b.id),
                  isExpanded: true,
                  items: [
                    for (final b in inStock)
                      DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _bean = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('豆読み込みエラー: $e'),
            ),
            const SizedBox(height: 12),
            grindersAsync.when(
              data: (grinders) => DropdownButtonFormField<GrinderMaster>(
                decoration: const InputDecoration(labelText: 'グラインダー'),
                value: _resolveById(grinders, _grinder?.id, (g) => g.id),
                isExpanded: true,
                items: [
                  for (final g in grinders)
                    DropdownMenuItem(value: g, child: Text(g.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _grinder = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('グラインダー読み込みエラー: $e'),
            ),
            const SizedBox(height: 12),
            drippersAsync.when(
              data: (drippers) => DropdownButtonFormField<DripperMaster>(
                decoration: const InputDecoration(labelText: 'ドリッパー'),
                value: _resolveById(drippers, _dripper?.id, (d) => d.id),
                isExpanded: true,
                items: [
                  for (final d in drippers)
                    DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _dripper = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('ドリッパー読み込みエラー: $e'),
            ),
            const SizedBox(height: 12),
            filtersAsync.when(
              data: (filters) => DropdownButtonFormField<FilterMaster>(
                decoration: const InputDecoration(labelText: 'フィルター'),
                value: _resolveById(filters, _filter?.id, (f) => f.id),
                isExpanded: true,
                items: [
                  for (final f in filters)
                    DropdownMenuItem(value: f, child: Text(f.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _filter = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('フィルター読み込みエラー: $e'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickBrewedAt,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '抽出日時',
                  prefixIcon: Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(
                  '${_brewedAt.year}/${_brewedAt.month.toString().padLeft(2, '0')}/${_brewedAt.day.toString().padLeft(2, '0')} '
                  '${_brewedAt.hour.toString().padLeft(2, '0')}:${_brewedAt.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ],
        ),
        FormSection(
          icon: Icons.restaurant_outlined,
          title: '味わい',
          children: [
            MockChoiceChips(
              key: ValueKey('taste_$_formResetGeneration'),
              label: 'テイスト',
              options: _tasteOptions,
              initialIndex: _optionIndex(_tasteOptions, _taste) ?? 1,
              onChanged: (v) => setState(() => _taste = v),
            ),
            MockChoiceChips(
              key: ValueKey('concentration_$_formResetGeneration'),
              label: '濃度',
              options: _concentrationOptions,
              initialIndex: _optionIndex(_concentrationOptions, _concentration) ?? 1,
              onChanged: (v) => setState(() => _concentration = v),
            ),
          ],
        ),
        FormSection(
          icon: Icons.star_outline,
          title: 'スコア (0〜10)',
          children: [
            MockScoreSlider(
                key: ValueKey('fragrance_$_formResetGeneration'),
                label: '香り',
                initialValue: _scoreFragrance,
                onChanged: (v) => _scoreFragrance = v),
            MockScoreSlider(
                key: ValueKey('acidity_$_formResetGeneration'),
                label: '酸味',
                initialValue: _scoreAcidity,
                onChanged: (v) => _scoreAcidity = v),
            MockScoreSlider(
                key: ValueKey('bitterness_$_formResetGeneration'),
                label: '苦味',
                initialValue: _scoreBitterness,
                onChanged: (v) => _scoreBitterness = v),
            MockScoreSlider(
                key: ValueKey('sweetness_$_formResetGeneration'),
                label: '甘み',
                initialValue: _scoreSweetness,
                onChanged: (v) => _scoreSweetness = v),
            MockScoreSlider(
                key: ValueKey('complexity_$_formResetGeneration'),
                label: '複雑さ',
                initialValue: _scoreComplexity,
                onChanged: (v) => _scoreComplexity = v),
            MockScoreSlider(
                key: ValueKey('flavor_$_formResetGeneration'),
                label: '風味',
                initialValue: _scoreFlavor,
                onChanged: (v) => _scoreFlavor = v),
            const Divider(height: 24),
            MockScoreSlider(
                key: ValueKey('overall_$_formResetGeneration'),
                label: '総合',
                initialValue: _scoreOverall,
                onChanged: (v) => _scoreOverall = v),
          ],
        ),
        FormSection(
          icon: Icons.edit_note,
          title: 'コメント',
          children: [
            MockTextField(
              label: 'メモ',
              hint: '感想・次回への改善点など',
              maxLines: 4,
              controller: _commentController,
            ),
          ],
        ),
      ],
    );
  }
}

/// 030(抽出レシピ)から引き継がれた実際の抽出情報のサマリ表示。
class _BrewSummaryCard extends StatelessWidget {
  final PendingBrewInfo info;

  const _BrewSummaryCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final methodText = info.method.name;
    final weightText = '豆 ${info.beanWeight.toStringAsFixed(1)}g / 湯 ${info.totalWater.toStringAsFixed(1)}g';
    final tempText = info.method.temperature != null ? '${info.method.temperature!.toStringAsFixed(1)}℃' : '温度未設定';
    final timeText = _formatTime(info.totalTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kEspresso,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.coffee_maker_outlined, color: kAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '今回の抽出 (030から引き継ぎ)',
                style: TextStyle(
                  color: kCream,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(icon: Icons.menu_book, text: methodText),
              _SummaryChip(icon: Icons.scale, text: weightText),
              _SummaryChip(icon: Icons.thermostat, text: tempText),
              _SummaryChip(icon: Icons.timer_outlined, text: timeText),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kMocha.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kLatte),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: kCream, fontSize: 12)),
        ],
      ),
    );
  }
}
