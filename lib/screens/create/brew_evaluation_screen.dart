import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bean_master.dart';
import '../../models/coffee_record.dart';
import '../../models/equipment_masters.dart';
import '../../models/method_master.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../models/pending_brew_info.dart';
import '../../services/data_service.dart';
import '../../widgets/bean_image.dart';
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
/// Cycle 20 T3-15/T3-17: 030でメソッド未選択でもこの画面へ進めるようにし、
/// メソッド・豆量・総湯量も030からの引き継ぎ値をこの画面で編集できるようにした。
/// 湯温は030から引き継がず(元々メソッドの既定値を無条件に使っていた)、この画面で
/// 都度入力する運用に変更した。
/// Cycle 20 T3-16: 豆/グラインダー/ドリッパー/フィルターの選択リストの各項目に
/// マスター画像のサムネイルを表示するようにした。
/// Cycle 20 T3-18: 「味わい」(テイスト/濃度)入力欄は4:6メソッド選択時のみ表示・
/// 保存する(他メソッドでは非表示かつCoffeeRecordへ空文字で保存)。
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

  /// T3-17: メソッド・豆量・総湯量も030からの引き継ぎ値をここで編集できる。
  late MethodMaster? _method = widget.info.method;
  late final TextEditingController _beanWeightController =
      TextEditingController(text: widget.info.beanWeight.toStringAsFixed(1));
  late final TextEditingController _totalWaterController =
      TextEditingController(text: widget.info.totalWater.toStringAsFixed(1));

  /// T3-17: 湯温は030から引き継がず、この画面で毎回入力する運用にしたため
  /// 空欄で初期化する。
  final _temperatureController = TextEditingController();

  /// T3-18: 「味わい」欄は4:6メソッド選択時のみ表示・保存する。
  bool get _isTasteApplicable => _method?.name.contains('4:6') ?? false;

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
    _beanWeightController.dispose();
    _totalWaterController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  /// 評価入力欄をデフォルト値に戻す(`setState`内で呼ぶこと)。
  /// [_formResetGeneration]をインクリメントし、各ウィジェットのkeyに反映して
  /// 強制的に再構築させることで、MockChoiceChips/MockScoreSlider自身が持つ
  /// 内部状態(タップ済みの選択)もあわせてリセットする。
  /// 器具・豆選択(_bean/_grinder/_dripper/_filter)、メソッド・豆量・総湯量・
  /// 湯温(_method/_beanWeightController等)は同じ設定で連続記録することが
  /// 多いためリセットせず維持する。抽出日時のみ現在時刻へ進める。
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
    final beanWeight = double.tryParse(_beanWeightController.text) ?? info.beanWeight;
    final totalWater = double.tryParse(_totalWaterController.text) ?? info.totalWater;
    final temperature = double.tryParse(_temperatureController.text) ?? 0.0;
    final isTasteApplicable = _isTasteApplicable;
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
        originId: _bean?.originId ?? '',
        beanWeight: beanWeight,
        grindSize: _grinder?.grindRange ?? '',
        methodId: _method?.id ?? '',
        // T3-18: 4:6メソッド以外では味わい入力欄が非表示のため空文字で保存する。
        taste: isTasteApplicable ? (_taste ?? '') : '',
        concentration: isTasteApplicable ? (_concentration ?? '') : '',
        temperature: temperature,
        bloomingWater: info.bloomingWater,
        totalWater: totalWater,
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

  /// T3-16: 選択リストの各項目にマスター画像のサムネイルを表示する。
  Widget _thumbnailLabel(String? imageUrl, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kLatte),
          ),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? BeanImage(imagePath: imageUrl, fit: BoxFit.cover, placeholderIcon: icon)
              : Icon(icon, size: 16, color: kMocha),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final methodsAsync = ref.watch(methodMasterProvider);
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
        _BrewSummaryCard(
          method: _method,
          beanWeight: double.tryParse(_beanWeightController.text) ?? info.beanWeight,
          totalWater: double.tryParse(_totalWaterController.text) ?? info.totalWater,
          totalTime: info.totalTime,
        ),
        FormSection(
          icon: Icons.coffee_maker_outlined,
          title: '抽出情報',
          children: [
            // T3-17: メソッドも030からの引き継ぎ値をここで編集できる。
            methodsAsync.when(
              data: (methods) => DropdownButtonFormField<MethodMaster>(
                decoration: const InputDecoration(labelText: 'メソッド'),
                value: _resolveById(methods, _method?.id, (m) => m.id),
                isExpanded: true,
                items: [
                  for (final m in methods)
                    DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _method = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('メソッド読み込みエラー: $e'),
            ),
            const SizedBox(height: 12),
            MockTextField(
              label: '豆量',
              suffix: 'g',
              keyboardType: TextInputType.number,
              controller: _beanWeightController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            MockTextField(
              label: '総湯量',
              suffix: 'g',
              keyboardType: TextInputType.number,
              controller: _totalWaterController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            MockTextField(
              label: '湯温',
              suffix: '℃',
              hint: '92',
              keyboardType: TextInputType.number,
              controller: _temperatureController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            beansAsync.when(
              data: (beans) {
                final inStock = beans.where((b) => b.isInStock).toList();
                return DropdownButtonFormField<BeanMaster>(
                  decoration: const InputDecoration(labelText: '豆'),
                  value: _resolveById(inStock, _bean?.id, (b) => b.id),
                  isExpanded: true,
                  items: [
                    for (final b in inStock)
                      DropdownMenuItem(
                        value: b,
                        child: _thumbnailLabel(b.imageUrl, Icons.coffee, b.name),
                      ),
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
                    DropdownMenuItem(
                      value: g,
                      child: _thumbnailLabel(g.imageUrl, Icons.settings, g.name),
                    ),
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
                    DropdownMenuItem(
                      value: d,
                      child: _thumbnailLabel(d.imageUrl, Icons.filter_alt_outlined, d.name),
                    ),
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
                    DropdownMenuItem(
                      value: f,
                      child: _thumbnailLabel(f.imageUrl, Icons.filter_frames_outlined, f.name),
                    ),
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
        // T3-18: 4:6メソッド選択時のみ「味わい」欄を表示する。
        if (_isTasteApplicable)
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

/// 030(抽出レシピ)から引き継いだ抽出情報のサマリ表示。
/// T3-17: メソッド・豆量・総湯量はこの画面で編集可能になったため、030の
/// 引き継ぎ値そのものではなく、呼び出し元([_BrewEvaluationScreenState.build])
/// が現在の入力値を渡す(編集すると即座にサマリへ反映される)。
/// 湯温は030から引き継がずこの画面で新規入力する運用(T3-17)のため、
/// このサマリには含めない(下の「抽出情報」セクションの入力欄で確認できる)。
class _BrewSummaryCard extends StatelessWidget {
  final MethodMaster? method;
  final double beanWeight;
  final double totalWater;
  final int totalTime;

  const _BrewSummaryCard({
    required this.method,
    required this.beanWeight,
    required this.totalWater,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    final methodText = method?.name ?? 'メソッド未選択';
    final weightText = '豆 ${beanWeight.toStringAsFixed(1)}g / 湯 ${totalWater.toStringAsFixed(1)}g';
    final timeText = _formatTime(totalTime);

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
