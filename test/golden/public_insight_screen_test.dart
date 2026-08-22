// T5-B25: P300 インサイト画面(lib/screens/public/insight_screen.dart)と
// P310 インサイトの詳細画面(lib/screens/public/insight_detail_screen.dart)
// のgolden。いずれも表示層のみの固定プレースホルダのため状態は1つ
// (ライト/ダーク)ずつ。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/screens/public/insight_detail_screen.dart';
import 'package:bean_base/screens/public/insight_screen.dart';
import 'package:bean_base/theme/public/bb_theme.dart';

import 'golden_test_helper.dart';

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';
    final theme = buildPublicTheme(brightness);

    testWidgets('InsightScreen golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: const InsightScreen(),
        brightness: brightness,
        theme: theme,
        width: 412,
        height: 915,
        goldenPath: 'goldens/public/insight_screen_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('InsightDetailScreen golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: const InsightDetailScreen(),
        brightness: brightness,
        theme: theme,
        width: 412,
        height: 915,
        goldenPath: 'goldens/public/insight_detail_screen_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);
  }
}
