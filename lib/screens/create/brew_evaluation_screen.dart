import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../../models/pending_brew_info.dart';
import 'create_form_widgets.dart';

/// 031 抽出結果の評価。
///
/// Cycle 20 T1-2b: 030(抽出レシピ)から実際の抽出情報([PendingBrewInfo])を
/// 引き継ぎ、サマリに表示する。評価スコア・コメント入力とrecordsへの保存は
/// 引き続きUIモック(T2-5aで実装)。
class BrewEvaluationScreen extends StatelessWidget {
  final PendingBrewInfo info;

  const BrewEvaluationScreen({super.key, required this.info});

  static const _tasteOptions = ['すっきり', 'バランス', 'コク深い'];
  static const _concentrationOptions = ['薄い', 'ちょうど良い', '濃い'];

  int? _optionIndex(List<String> options, String? value) {
    if (value == null || value.isEmpty) return null;
    final i = options.indexOf(value);
    return i >= 0 ? i : null;
  }

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.brewEvaluation,
      saveLabel: '評価を登録する',
      children: [
        _BrewSummaryCard(info: info),
        FormSection(
          icon: Icons.restaurant_outlined,
          title: '味わい',
          children: [
            MockChoiceChips(
              label: 'テイスト',
              options: _tasteOptions,
              initialIndex: _optionIndex(_tasteOptions, info.taste) ?? 1,
            ),
            MockChoiceChips(
              label: '濃度',
              options: _concentrationOptions,
              initialIndex:
                  _optionIndex(_concentrationOptions, info.concentration) ?? 1,
            ),
          ],
        ),
        FormSection(
          icon: Icons.star_outline,
          title: 'スコア (0〜10)',
          children: [
            MockScoreSlider(
                label: '香り',
                initialValue: (info.scoreFragrance ?? 5).toDouble()),
            MockScoreSlider(
                label: '酸味', initialValue: (info.scoreAcidity ?? 5).toDouble()),
            MockScoreSlider(
                label: '苦味',
                initialValue: (info.scoreBitterness ?? 5).toDouble()),
            MockScoreSlider(
                label: '甘み',
                initialValue: (info.scoreSweetness ?? 5).toDouble()),
            MockScoreSlider(
                label: '複雑さ',
                initialValue: (info.scoreComplexity ?? 5).toDouble()),
            MockScoreSlider(
                label: '風味', initialValue: (info.scoreFlavor ?? 5).toDouble()),
            const Divider(height: 24),
            MockScoreSlider(
                label: '総合', initialValue: (info.scoreOverall ?? 7).toDouble()),
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
              initialValue: info.comment,
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
