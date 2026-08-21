// T5-B23 adversaryレビューMajor-1対応: ホーム画面(lib/screens/public/home_screen.dart)
// の週次集計(「今週」判定、月曜起点)の境界値を検証する。
//
// `homeScreenClock`(トップレベル関数変数、T5-B23 adversaryレビューMajor-2対応)を
// 固定日時を返す関数に差し替え、`brewedAt`が週境界の前後にある記録を与えて、
// `BbStatTile`(label: '抽出回数(今週)')の表示値が意図通り切り替わることを
// 確認する。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/public/home_screen.dart';
import 'package:bean_base/widgets/public/bb_stat_tile.dart';

import '../../helpers/fake_master_notifiers.dart';

CoffeeRecord _record({required String id, required DateTime brewedAt}) {
  return CoffeeRecord(
    id: id,
    brewedAt: brewedAt,
    grinderId: 'g1',
    dripperId: 'd1',
    filterId: 'f1',
    beanId: 'b1',
    roastLevel: '中煎り',
    origin: 'エチオピア',
    beanWeight: 18,
    grindSize: '中挽き',
    methodId: 'm1',
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 30,
    totalWater: 280,
    bloomingTime: 30,
    totalTime: 150,
    scoreFragrance: 4,
    scoreAcidity: 4,
    scoreBitterness: 3,
    scoreSweetness: 4,
    scoreComplexity: 4,
    scoreFlavor: 4,
    scoreOverall: 4,
    comment: '',
  );
}

/// [now]・[brewedAt]でホーム画面をpumpし、「抽出回数(今週)」タイルの
/// 表示値を返す。
Future<String> _extractionCountValue(
  WidgetTester tester, {
  required DateTime now,
  required DateTime brewedAt,
}) async {
  homeScreenClock = () => now;
  addTearDown(() => homeScreenClock = DateTime.now);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coffeeRecordsProvider.overrideWith(
          (ref) async => [_record(id: '1', brewedAt: brewedAt)],
        ),
        beanMasterProvider.overrideWith(
          () => FakeBeanMasterNotifier(
            () async => [
              BeanMaster(
                id: 'b1',
                name: 'テスト豆',
                roastLevel: '中煎り',
                origin: 'エチオピア',
              ),
            ],
          ),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();

  final tile = tester.widgetList<BbStatTile>(find.byType(BbStatTile)).firstWhere(
        (w) => w.label == '抽出回数(今週)',
      );
  return tile.value;
}

void main() {
  // 基準週: 2026-08-24(月)〜2026-08-30(日)。
  final mondayThisWeek = DateTime(2026, 8, 24, 0, 0, 0);
  final fixedNow = DateTime(2026, 8, 24, 10, 0); // 週内の適当な現在時刻。

  group('ホーム画面: 週次集計の週境界(月曜起点)', () {
    testWidgets('月曜0時ちょうどのbrewedAtは今週に含まれる', (tester) async {
      final value = await _extractionCountValue(
        tester,
        now: fixedNow,
        brewedAt: mondayThisWeek,
      );
      expect(value, '1');
    });

    testWidgets('前週日曜23:59:59.999のbrewedAtは今週に含まれない', (tester) async {
      final sundayLastWeek =
          mondayThisWeek.subtract(const Duration(milliseconds: 1));
      final value = await _extractionCountValue(
        tester,
        now: fixedNow,
        brewedAt: sundayLastWeek,
      );
      expect(value, '0');
    });

    testWidgets('今週日曜23:59付近のbrewedAtは今週に含まれる', (tester) async {
      final sundayThisWeek = DateTime(2026, 8, 30, 23, 59);
      final value = await _extractionCountValue(
        tester,
        now: fixedNow,
        brewedAt: sundayThisWeek,
      );
      expect(value, '1');
    });
  });
}
