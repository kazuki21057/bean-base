import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/coffee_record.dart';
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
/// 本実装へ置き換えた。登録後はダッシュボード(001)まで戻る(030の古い
/// レシピ・タイマー状態には戻らない)。評価登録時の豆残量自動計算・031への
/// 復帰フローはT2-5bのスコープ。
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

  static String? _optionOrNull(List<String> options, String? value) {
    if (value == null || value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  static int? _optionIndex(List<String> options, String? value) {
    if (value == null) return null;
    final i = options.indexOf(value);
    return i >= 0 ? i : null;
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

  Future<void> _submit() async {
    final info = widget.info;
    setState(() => _isSaving = true);
    try {
      final record = CoffeeRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brewedAt: info.brewedAt,
        grinderId: info.grinder?.id ?? '',
        dripperId: info.dripper?.id ?? '',
        filterId: info.filter?.id ?? '',
        beanId: info.bean?.id ?? '',
        roastLevel: info.bean?.roastLevel ?? '',
        origin: info.bean?.origin ?? '',
        beanWeight: info.beanWeight,
        grindSize: info.grinder?.grindRange ?? '',
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
        beanImageUrl: info.bean?.imageUrl,
      );

      final service = ref.read(dataServiceProvider);
      await service.addCoffeeRecord(record);
      debugPrint('[Antigravity] Action: 031から抽出記録を登録 (id=${record.id}, bean=${record.beanId}, method=${record.methodId})');
      ref.invalidate(coffeeRecordsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('抽出記録を登録しました')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    return CreateFormScaffold(
      screen: AppScreen.brewEvaluation,
      saveLabel: '評価を登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        _BrewSummaryCard(info: info),
        FormSection(
          icon: Icons.restaurant_outlined,
          title: '味わい',
          children: [
            MockChoiceChips(
              label: 'テイスト',
              options: _tasteOptions,
              initialIndex: _optionIndex(_tasteOptions, _taste) ?? 1,
              onChanged: (v) => setState(() => _taste = v),
            ),
            MockChoiceChips(
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
                label: '香り',
                initialValue: _scoreFragrance,
                onChanged: (v) => _scoreFragrance = v),
            MockScoreSlider(
                label: '酸味',
                initialValue: _scoreAcidity,
                onChanged: (v) => _scoreAcidity = v),
            MockScoreSlider(
                label: '苦味',
                initialValue: _scoreBitterness,
                onChanged: (v) => _scoreBitterness = v),
            MockScoreSlider(
                label: '甘み',
                initialValue: _scoreSweetness,
                onChanged: (v) => _scoreSweetness = v),
            MockScoreSlider(
                label: '複雑さ',
                initialValue: _scoreComplexity,
                onChanged: (v) => _scoreComplexity = v),
            MockScoreSlider(
                label: '風味',
                initialValue: _scoreFlavor,
                onChanged: (v) => _scoreFlavor = v),
            const Divider(height: 24),
            MockScoreSlider(
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
    final beanText = info.bean?.name ?? '豆未選択';
    final methodText = info.method.name;
    final weightText = '豆 ${info.beanWeight.toStringAsFixed(1)}g / 湯 ${info.totalWater.toStringAsFixed(1)}g';
    final tempText = info.method.temperature != null ? '${info.method.temperature!.toStringAsFixed(0)}℃' : '温度未設定';
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
              _SummaryChip(icon: Icons.coffee, text: beanText),
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
