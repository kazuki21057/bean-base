// T5-B25: 公開版(Android) P310 インサイトの詳細画面(表示層のみ)。
//
// 正本は docs/android_monetization/デザイン方針.md §9.4「P310 インサイトの
// 詳細」行。実際の根拠図表示・確信度説明(T5-B30/T5-B31/T5-B32)は未実装の
// ため、本画面は骨格・スタイルのみを持つ固定プレースホルダとする
// (`home_screen.dart`のインサイト要約カードと同じ前例を踏襲、T5-B23)。
// 生の統計量やしきい値付きの文言は一切出さない。他画面からの導線配線は
// 本タスクの範囲外(未配線)。
import 'package:flutter/material.dart';

import 'package:bean_base/widgets/public/bb_empty_state.dart';

/// P310 インサイトの詳細画面本体(表示層のみ)。
class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('インサイトの詳細')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: BbEmptyState(
              icon: Icons.insights_outlined,
              title: 'この機能は準備中です',
              description: '記録がたまると、ここに見立ての根拠が表示されます。',
            ),
          ),
        ),
      ),
    );
  }
}
