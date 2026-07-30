import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/utils/roast_range.dart';
import 'package:bean_base/widgets/roast_range_slider.dart';

/// T3-71a: RoastRangeSlider単体テスト(設計書§8.1、7件)+roast_range.dartの
/// 純関数テスト。スライダー操作はtester.dragが不安定なため使わず、
/// RangeSlider.onChangedのコールバックを直接呼ぶ方式で検証する。
void main() {
  Widget build({
    required String? minValue,
    required String? maxValue,
    required void Function(String?, String?) onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RoastRangeSlider(minValue: minValue, maxValue: maxValue, onChanged: onChanged),
      ),
    );
  }

  group('RoastRangeSlider', () {
    testWidgets('1. min/max共にnullのとき未設定表示・values=(3,6)・クリア無効', (tester) async {
      await tester.pumpWidget(build(minValue: null, maxValue: null, onChanged: (_, __) {}));

      expect(find.text('未設定(スライダーを動かして範囲を選択)'), findsOneWidget);
      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values, const RangeValues(3, 6));
      final clearButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'クリア'));
      expect(clearButton.onPressed, isNull);
    });

    testWidgets('2. ミディアム〜フルシティのとき範囲表示とvalues=(3,6)', (tester) async {
      await tester.pumpWidget(build(minValue: 'ミディアム', maxValue: 'フルシティ', onChanged: (_, __) {}));

      expect(find.textContaining('ミディアム 〜 フルシティ'), findsOneWidget);
      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values, const RangeValues(3, 6));
    });

    testWidgets('3. シティ/シティ(点)のとき「シティ (City)」表示とvalues=(5,5)', (tester) async {
      await tester.pumpWidget(build(minValue: 'シティ', maxValue: 'シティ', onChanged: (_, __) {}));

      expect(find.textContaining('シティ (City)'), findsOneWidget);
      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values, const RangeValues(5, 5));
    });

    testWidgets('4. 中煎り〜深煎り(旧5段階)のときハイ〜フレンチとvalues=(4,7)(後方互換の回帰テスト)', (tester) async {
      await tester.pumpWidget(build(minValue: '中煎り', maxValue: '深煎り', onChanged: (_, __) {}));

      expect(find.textContaining('ハイ 〜 フレンチ'), findsOneWidget);
      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values, const RangeValues(4, 7));
    });

    testWidgets('5. フルシティ/ミディアム(逆転)は入れ替えてミディアム〜フルシティ・values=(3,6)', (tester) async {
      await tester.pumpWidget(build(minValue: 'フルシティ', maxValue: 'ミディアム', onChanged: (_, __) {}));

      expect(find.textContaining('ミディアム 〜 フルシティ'), findsOneWidget);
      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values, const RangeValues(3, 6));
    });

    testWidgets('6. 謎の焙煎/null(未知)は未設定表示・values=(3,6)・onChangedは呼ばれない', (tester) async {
      var called = false;
      await tester.pumpWidget(build(minValue: '謎の焙煎', maxValue: null, onChanged: (_, __) => called = true));

      expect(find.textContaining('謎の焙煎'), findsOneWidget);
      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values, const RangeValues(3, 6));
      expect(called, isFalse);
    });

    testWidgets('7. RangeSlider.onChangedを直接呼ぶとコールバックに(シナモン,シティ)が渡り、続けてクリアで(null,null)', (tester) async {
      String? receivedMin;
      String? receivedMax;
      await tester.pumpWidget(build(
        minValue: 'ライト',
        maxValue: 'ライト',
        onChanged: (min, max) {
          receivedMin = min;
          receivedMax = max;
        },
      ));

      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      slider.onChanged!(const RangeValues(2, 5));

      expect(receivedMin, 'シナモン');
      expect(receivedMax, 'シティ');

      await tester.tap(find.widgetWithText(TextButton, 'クリア'));
      await tester.pumpAndSettle();

      expect(receivedMin, isNull);
      expect(receivedMax, isNull);
    });
  });

  group('resolveMethodRoastRange / methodMatchesRoastOrdinal(純関数、設計書§4.2)', () {
    MethodMaster method({String? min, String? max, String? level}) {
      return MethodMaster(
        id: 'm',
        name: 'm',
        author: '',
        baseBeanWeight: 0,
        baseWaterAmount: 0,
        description: '',
        recommendedEquipment: '',
        recommendedRoastMin: min,
        recommendedRoastMax: max,
        recommendedRoastLevel: level,
      );
    }

    test('手順2: min/maxとも非nullなら小さい方がmin,大きい方がmax', () {
      final range = resolveMethodRoastRange(method(min: 'ミディアム', max: 'フルシティ'));
      expect(range, isNotNull);
      expect(range!.min, 3.0);
      expect(range.max, 6.0);
    });

    test('手順2: 逆転していても入れ替えて解決する', () {
      final range = resolveMethodRoastRange(method(min: 'フルシティ', max: 'ミディアム'));
      expect(range!.min, 3.0);
      expect(range.max, 6.0);
    });

    test('手順3: 片方だけ非nullなら点として扱う', () {
      final range = resolveMethodRoastRange(method(min: 'シティ', max: null));
      expect(range!.min, 5.0);
      expect(range.max, 5.0);
      expect(range.isPoint, isTrue);
    });

    test('手順4: 両方nullなら旧単一値にフォールバックする', () {
      final range = resolveMethodRoastRange(method(level: 'ハイ'));
      expect(range!.min, 4.0);
      expect(range.max, 4.0);
    });

    test('手順4/5: すべてnull・未知の値ならnull(未設定)', () {
      expect(resolveMethodRoastRange(method()), isNull);
      expect(resolveMethodRoastRange(method(level: '謎の焙煎')), isNull);
    });

    test('methodMatchesRoastOrdinal: 範囲の両端はtrue', () {
      final m = method(min: 'ミディアム', max: 'シティ');
      expect(methodMatchesRoastOrdinal(m, 3.0), isTrue);
      expect(methodMatchesRoastOrdinal(m, 5.0), isTrue);
    });

    test('methodMatchesRoastOrdinal: 範囲外はfalse', () {
      final m = method(min: 'ミディアム', max: 'シティ');
      expect(methodMatchesRoastOrdinal(m, 2.0), isFalse);
      expect(methodMatchesRoastOrdinal(m, 6.0), isFalse);
    });

    test('methodMatchesRoastOrdinal: 未設定はfalse(候補外)', () {
      expect(methodMatchesRoastOrdinal(method(), 4.0), isFalse);
    });
  });
}
