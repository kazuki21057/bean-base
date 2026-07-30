import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/screens/roast_guide_screen.dart';
import 'package:bean_base/services/math/encoding.dart';

/// T3-51: 焙煎度8段階ガイド(044)のウィジェットテスト。
/// [MockScreenScaffold] が `mainColorProvider`(Riverpod)に依存するため
/// [ProviderScope] でラップする。
void main() {
  Widget wrap(Widget child) {
    return ProviderScope(child: MaterialApp(home: child));
  }

  testWidgets('8段階すべての日本語名・英語表記が目次と本文に表示される', (tester) async {
    await tester.pumpWidget(wrap(const RoastGuideScreen()));

    for (var i = 0; i < roastLevels8.length; i++) {
      expect(
        find.textContaining('${roastLevels8[i]} (${roastLevels8En[i]})'),
        findsOneWidget,
      );
    }
  });

  testWidgets('各段階に見た目の色味・バランス・適した抽出方法のラベルが表示される', (tester) async {
    await tester.pumpWidget(wrap(const RoastGuideScreen()));

    expect(find.text('見た目の色味'), findsNWidgets(8));
    expect(find.text('酸味/苦味/コクのバランス'), findsNWidgets(8));
    expect(find.text('適した抽出方法'), findsNWidgets(8));
  });

  testWidgets('RoastGuideLinkをタップするとRoastGuideScreenへ遷移する', (tester) async {
    await tester.pumpWidget(wrap(
      const Scaffold(body: RoastGuideLink(currentLabel: 'ミディアム')),
    ));

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(RoastGuideScreen), findsOneWidget);
  });

  testWidgets('currentLabelが未知の値でも例外にならず遷移できる', (tester) async {
    await tester.pumpWidget(wrap(
      const Scaffold(body: RoastGuideLink(currentLabel: '謎の焙煎')),
    ));

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(RoastGuideScreen), findsOneWidget);
  });
}
