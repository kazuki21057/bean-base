import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/widgets/coffee_log_card.dart';

import 'golden_test_helper.dart';

/// T5-A8: CoffeeLogCard(共通コンポーネント)のgolden(ライト/ダーク)。
void main() {
  final log = CoffeeRecord(
    id: 'log_golden_1',
    brewedAt: DateTime(2026, 1, 15, 8, 30),
    grinderId: 'g1',
    dripperId: 'd1',
    filterId: 'f1',
    beanId: 'b1',
    roastLevel: 'ミディアム',
    origin: 'エチオピア',
    beanWeight: 15,
    grindSize: '中挽き',
    methodId: 'm1',
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 30,
    totalWater: 240,
    bloomingTime: 30,
    totalTime: 180,
    scoreFragrance: 7,
    scoreAcidity: 6,
    scoreBitterness: 5,
    scoreSweetness: 7,
    scoreComplexity: 6,
    scoreFlavor: 7,
    scoreOverall: 8,
    comment: '',
  );

  testWidgets('CoffeeLogCard golden(ライト)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: CoffeeLogCard(
        log: log,
        beanName: 'エチオピア イルガチェフェ',
        methodName: 'ペーパードリップ',
      ),
      brightness: Brightness.light,
      goldenPath: 'goldens/coffee_log_card_light.png',
      width: 400,
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('CoffeeLogCard golden(ダーク)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: CoffeeLogCard(
        log: log,
        beanName: 'エチオピア イルガチェフェ',
        methodName: 'ペーパードリップ',
      ),
      brightness: Brightness.dark,
      goldenPath: 'goldens/coffee_log_card_dark.png',
      width: 400,
    );
  }, skip: skipGoldenOnNonWindows);
}
