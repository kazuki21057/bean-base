// T5-B25: 公開版(Android) P300 インサイト画面(表示層のみ)。
//
// 正本は docs/android_monetization/デザイン方針.md §9.4「P300 インサイト」行。
// 実際のインサイト生成(カード変換ロジックT5-B31・進捗表示T5-B32・公開版
// 表示規則T5-B30)は未実装のため、本画面は骨格・スタイルのみを持つ固定
// プレースホルダとする(`home_screen.dart`のインサイト要約カードと同じ
// 「インサイトは準備中です」の前例を踏襲、T5-B23)。生の統計量
// (PCA負荷量・回帰係数・p値・寄与率・固有値等)やしきい値付きの文言は
// 一切出さない。他画面からの導線配線は本タスクの範囲外(未配線)。
import 'package:flutter/material.dart';

import 'package:bean_base/widgets/public/bb_empty_state.dart';

/// P300 インサイト画面本体(表示層のみ)。
class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('インサイト')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: BbEmptyState(
              icon: Icons.insights_outlined,
              title: 'インサイトは準備中です',
              description: '記録がたまると、ここに味の傾向が表示されます。',
            ),
          ),
        ),
      ),
    );
  }
}
