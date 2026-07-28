import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/widgets/method_steps_editor.dart';

/// T3-58: 030で豆量を変更しても注湯ステップの湯量表示が変わらなかった不具合の回帰テスト。
/// [MethodStepsEditor]単体で、親からbaseBeanWeight/methodBaseBeanWeightが
/// 変化したとき(=030で豆量を変更したときの再ビルドを模擬)、
/// TextFormFieldの表示(湯量)が即座に更新されることを確認する。
void main() {
  final steps = [
    PouringStep(
      id: 'S1',
      methodId: 'M1',
      stepOrder: 1,
      duration: 30,
      waterAmount: 30,
      waterReference: 15.0,
      description: 'Bloom',
    ),
    PouringStep(
      id: 'S2',
      methodId: 'M1',
      stepOrder: 2,
      duration: 30,
      waterAmount: 120,
      waterReference: 15.0,
      description: 'Pour',
    ),
  ];

  Widget buildWithWeight(double baseBeanWeight, double methodBaseBeanWeight) {
    return MaterialApp(
      home: Scaffold(
        body: MethodStepsEditor(
          initialSteps: steps,
          isEditing: true,
          baseBeanWeight: baseBeanWeight,
          methodBaseBeanWeight: methodBaseBeanWeight,
          onStepsChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('豆量が基準どおりのとき、waterRatio未設定ステップはそのままの湯量が表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWithWeight(15.0, 15.0));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '30.0'), findsOneWidget); // 累計: 30
    expect(find.widgetWithText(TextFormField, '150.0'), findsOneWidget); // 累計: 30+120
  });

  testWidgets('豆量を基準の2倍に変更すると、waterRatio未設定ステップの湯量表示も即座に2倍になる(T3-58)',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWithWeight(15.0, 15.0));
    await tester.pumpAndSettle();

    // 030側で豆量入力欄が変わったのと同じ状況(親の再ビルド)を模擬。
    await tester.pumpWidget(buildWithWeight(30.0, 15.0));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '60.0'), findsOneWidget); // 30 * 2
    expect(find.widgetWithText(TextFormField, '300.0'), findsOneWidget); // (30+120) * 2
  });
}
