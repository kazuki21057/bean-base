import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/widgets/roast_level_slider.dart';

/// T3-54a: RoastLevelSlider単体テスト(設計書§7.1、6件)。
/// スライダー操作はtester.dragが不安定なため使わず、
/// Slider.onChangedのコールバックを直接呼ぶ方式で検証する。
void main() {
  Widget build({required String? value, required ValueChanged<String?> onChanged}) {
    return MaterialApp(
      home: Scaffold(
        body: RoastLevelSlider(value: value, onChanged: onChanged),
      ),
    );
  }

  testWidgets('value:nullのとき未設定表示・Slider.value=4.0・クリアボタン無効', (tester) async {
    await tester.pumpWidget(build(value: null, onChanged: (_) {}));

    expect(find.text('未設定(スライダーを動かして選択)'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 4.0);
    final clearButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'クリア'));
    expect(clearButton.onPressed, isNull);
  });

  testWidgets('value:ミディアムのとき値表示とSlider.valueが正しい', (tester) async {
    await tester.pumpWidget(build(value: 'ミディアム', onChanged: (_) {}));

    expect(find.textContaining('ミディアム (Medium)  3/8'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 3.0);
  });

  testWidgets('value:中煎り(旧5段階)のとき正しくハイとして表示される(後方互換)', (tester) async {
    await tester.pumpWidget(build(value: '中煎り', onChanged: (_) {}));

    expect(find.textContaining('ハイ (High)  4/8'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 4.0);
  });

  testWidgets('value:謎の焙煎(未知)のとき未設定表示になりonChangedは呼ばれない', (tester) async {
    var called = false;
    await tester.pumpWidget(build(value: '謎の焙煎', onChanged: (_) => called = true));

    expect(find.textContaining('謎の焙煎'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 4.0);
    expect(called, isFalse);
  });

  testWidgets('Slider.onChangedを直接呼ぶとコールバックにシティが渡る', (tester) async {
    String? received;
    await tester.pumpWidget(build(value: 'ライト', onChanged: (v) => received = v));

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(5.0);

    expect(received, 'シティ');
  });

  testWidgets('クリアボタンをタップするとコールバックにnullが渡る', (tester) async {
    String? received = 'unset';
    await tester.pumpWidget(build(value: 'ライト', onChanged: (v) => received = v));

    await tester.tap(find.widgetWithText(TextButton, 'クリア'));
    await tester.pumpAndSettle();

    expect(received, isNull);
  });
}
