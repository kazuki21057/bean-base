import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/brew_evaluation_screen.dart';
import '../create/create_form_widgets.dart';
import '../../models/pending_brew_info.dart';
import 'mock_scaffold.dart';

/// 030 抽出レシピ — UIモック。豆/メソッド選択+タイマー+Pouring Steps+評価ボタン→031。
/// 本実装は T1-2a(骨組み)/T2-3a〜c(タイマー・ハイライト)。
class BrewRecipeMockScreen extends StatelessWidget {
  const BrewRecipeMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: AppScreen.brewRecipe,
      maxWidth: 560,
      children: [
        FormSection(
          icon: Icons.tune,
          title: '今回のレシピ',
          children: const [
            MockChoiceChips(
              label: '豆',
              options: ['イルガチェフェ', 'キリマンジャロ', 'ブルーリントン'],
              initialIndex: 0,
            ),
            MockChoiceChips(
              label: 'メソッド',
              options: ['4:6メソッド', 'V60 Standard', 'Hoffmann 1cup'],
              initialIndex: 0,
            ),
            MockTextField(
              label: '豆量',
              suffix: 'g',
              hint: '20',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        // タイマー(T2-3bで動作実装)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: kEspresso,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                '01:23',
                style: TextStyle(
                  color: kCream,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 44,
                    color: kAccent,
                    icon: const Icon(Icons.play_circle_fill),
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('UIモックです。タイマーは T2-3b で実装されます。')),
                    ),
                  ),
                  IconButton(
                    iconSize: 36,
                    color: kLatte,
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('UIモックです。タイマーは T2-3b で実装されます。')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        FormSection(
          icon: Icons.water_drop_outlined,
          title: 'Pouring Steps (経過時間で現在のステップを強調)',
          children: [
            _mockStep(context, 1, '0:00', '60 g', '蒸らし', highlighted: false),
            _mockStep(context, 2, '0:45', '60 g', '2投目', highlighted: true),
            _mockStep(context, 3, '1:30', '180 g', '3投目〜', highlighted: false),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.star),
          label: const Text('抽出を終えて評価へ (031)'),
          onPressed: () {
            debugPrint('[Antigravity] Mock遷移: 030 → 031 (抽出情報の引き継ぎは T1-2b)');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BrewEvaluationScreen(info: PendingBrewInfo.mock())),
            );
          },
        ),
      ],
    );
  }

  Widget _mockStep(BuildContext context, int order, String time, String water,
      String label,
      {required bool highlighted}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? kAccent.withValues(alpha: 0.2) : kCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? kAccent : kLatte,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: highlighted ? kAccent : kMocha,
            child: Text('$order',
                style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          SizedBox(
              width: 48,
              child: Text(time,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 56, child: Text(water)),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: kMocha, fontSize: 13)),
          ),
          if (highlighted)
            const Icon(Icons.arrow_left, color: kAccent, size: 28),
        ],
      ),
    );
  }
}
