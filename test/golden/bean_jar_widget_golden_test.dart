import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/widgets/bean_jar_widget.dart';

import 'golden_test_helper.dart';

/// T5-A8: BeanJarWidget(共通コンポーネント)のgolden(ライト/ダーク)。
void main() {
  testWidgets('BeanJarWidget golden(ライト)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BeanJarWidget(percent: 63, label: 'エチオピア'),
      brightness: Brightness.light,
      goldenPath: 'goldens/bean_jar_widget_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BeanJarWidget golden(ダーク)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BeanJarWidget(percent: 63, label: 'エチオピア'),
      brightness: Brightness.dark,
      goldenPath: 'goldens/bean_jar_widget_dark.png',
    );
  }, skip: skipGoldenOnNonWindows);
}
