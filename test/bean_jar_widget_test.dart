import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/widgets/bean_jar_widget.dart';

/// Cycle 20 T2-2a: 瓶ビジュアル・ウィジェット(静的、10%刻み11段階)の検証。
void main() {
  group('BeanJarWidget.stage スナップロジック', () {
    final cases = <(num, int)>[
      (0, 0),
      (4, 0),
      (6, 10),
      (10, 10),
      (14, 10),
      (16, 20),
      (49, 50),
      (51, 50),
      (94, 90),
      (96, 100),
      (100, 100),
      (150, 100), // 範囲外は100にクランプ
      (-10, 0), // 範囲外は0にクランプ
    ];

    for (final (input, expected) in cases) {
      test('percent=$input → stage=$expected', () {
        expect(BeanJarWidget(percent: input).stage, expected);
      });
    }
  });

  testWidgets('任意の残量%を渡すとスナップされた%表示と対応する瓶が描画される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BeanJarWidget(percent: 63, label: 'エチオピア'),
        ),
      ),
    );

    // 63% は10%刻みで60%にスナップされる
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('エチオピア'), findsOneWidget);
    expect(find.byKey(const Key('bean_jar_fill_stage_60')), findsOneWidget);
  });

  testWidgets('0%の瓶は空(高さ0)で描画される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BeanJarWidget(percent: 0),
        ),
      ),
    );

    expect(find.text('0%'), findsOneWidget);
    final fillSize = tester.getSize(find.byKey(const Key('bean_jar_fill_stage_0')));
    expect(fillSize.height, 0);
  });

  testWidgets('100%の瓶は満タンで描画される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BeanJarWidget(percent: 100),
        ),
      ),
    );

    expect(find.text('100%'), findsOneWidget);
    final fillSize = tester.getSize(find.byKey(const Key('bean_jar_fill_stage_100')));
    // height:76 の瓶の内側(枠2px分を除く)がほぼ満タンで塗られる
    expect(fillSize.height, closeTo(72, 0.1));
  });
}
