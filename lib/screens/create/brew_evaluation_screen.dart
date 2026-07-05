import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import 'create_form_widgets.dart';

/// 031 抽出結果の評価 — UIモック(保存未接続)。
/// 上部に030から引き継ぐ抽出情報のサマリ、下部に評価入力(CoffeeRecordのscore群)。
/// 本実装は T2-5a(登録処理)・T1-2b(030からのデータ受け渡し)で行う。
class BrewEvaluationScreen extends StatelessWidget {
  const BrewEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.brewEvaluation,
      saveLabel: '評価を登録する',
      children: const [
        _BrewSummaryCard(),
        FormSection(
          icon: Icons.restaurant_outlined,
          title: '味わい',
          children: [
            MockChoiceChips(
              label: 'テイスト',
              options: ['すっきり', 'バランス', 'コク深い'],
              initialIndex: 1,
            ),
            MockChoiceChips(
              label: '濃度',
              options: ['薄い', 'ちょうど良い', '濃い'],
              initialIndex: 1,
            ),
          ],
        ),
        FormSection(
          icon: Icons.star_outline,
          title: 'スコア (0〜10)',
          children: [
            MockScoreSlider(label: '香り'),
            MockScoreSlider(label: '酸味'),
            MockScoreSlider(label: '苦味'),
            MockScoreSlider(label: '甘み'),
            MockScoreSlider(label: '複雑さ'),
            MockScoreSlider(label: '風味'),
            Divider(height: 24),
            MockScoreSlider(label: '総合', initialValue: 7),
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
            ),
          ],
        ),
      ],
    );
  }
}

/// 030(抽出レシピ)から引き継がれる抽出情報のサマリ表示(モック値)。
class _BrewSummaryCard extends StatelessWidget {
  const _BrewSummaryCard();

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: const [
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
            children: const [
              _SummaryChip(icon: Icons.coffee, text: 'エチオピア イルガチェフェ'),
              _SummaryChip(icon: Icons.menu_book, text: '4:6メソッド'),
              _SummaryChip(icon: Icons.scale, text: '豆 20g / 湯 300g'),
              _SummaryChip(icon: Icons.thermostat, text: '92℃'),
              _SummaryChip(icon: Icons.timer_outlined, text: '3:30'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '※ モック表示です。実データは 030 抽出レシピ画面から引き継がれます。',
            style: TextStyle(color: kLatte, fontSize: 11),
          ),
        ],
      ),
    );
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
