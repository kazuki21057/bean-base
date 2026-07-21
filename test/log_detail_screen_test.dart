import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/log_detail_screen.dart';

/// T3-26: 003(抽出履歴詳細)の評価表示デザイン改善の検証。
/// 総合スコアのヒーロー表示・6軸レーダー・テイストチップが出ることを確認する。
CoffeeRecord _record() {
  return CoffeeRecord(
    id: 'r1',
    brewedAt: DateTime(2026, 7, 20, 8, 30),
    beanId: '',
    methodId: '',
    beanWeight: 15,
    totalWater: 225,
    totalTime: 150,
    scoreOverall: 8,
    scoreFragrance: 7,
    scoreAcidity: 8,
    scoreBitterness: 5,
    scoreSweetness: 7,
    scoreComplexity: 6,
    scoreFlavor: 8,
    taste: '明るい',
    comment: 'テストコメント',
    grindSize: '',
    temperature: 92,
    dripperId: '',
    filterId: '',
    grinderId: '',
    roastLevel: '浅煎り',
    origin: '',
    originId: '',
    concentration: '軽い',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        beanMasterProvider.overrideWith((ref) async => []),
        methodMasterProvider.overrideWith((ref) async => []),
        grinderMasterProvider.overrideWith((ref) async => []),
        dripperMasterProvider.overrideWith((ref) async => []),
        filterMasterProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp(home: LogDetailScreen(log: _record())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('評価セクションが総合ヒーロー・レーダー・テイストチップを表示する', (tester) async {
    await _pump(tester);

    // 総合ヒーロー(見出し + 大きな数値 + /10)。
    expect(find.text('総合評価'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text(' / 10'), findsOneWidget);

    // 6軸レーダーチャートが描画されている。
    expect(find.byType(RadarChart), findsOneWidget);

    // テイスト・濃度がチップとして出ている。
    expect(find.text('明るい'), findsOneWidget);
    expect(find.text('軽い'), findsOneWidget);
  });
}
