import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/widgets/roast_level_slider.dart';

import 'golden_test_helper.dart';

/// T5-A8: RoastLevelSlider(共通コンポーネント)のgolden(ライト/ダーク)。
void main() {
  testWidgets('RoastLevelSlider golden(ライト)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: RoastLevelSlider(value: '中煎り', onChanged: (_) {}),
      brightness: Brightness.light,
      goldenPath: 'goldens/roast_level_slider_light.png',
      width: 320,
    );
  });

  testWidgets('RoastLevelSlider golden(ダーク)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: RoastLevelSlider(value: '中煎り', onChanged: (_) {}),
      brightness: Brightness.dark,
      goldenPath: 'goldens/roast_level_slider_dark.png',
      width: 320,
    );
  });
}
