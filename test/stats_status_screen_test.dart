import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/stats_status_screen.dart';
import 'package:bean_base/screens/stats_theory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _roasts = ['浅煎り', '中浅煎り', '中煎り', '中深煎り', '深煎り'];

final _origins = [
  OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
];

CoffeeRecord _record(int i) {
  return CoffeeRecord(
    id: 'r$i',
    brewedAt: DateTime(2026, 7, 21),
    grinderId: 'g',
    dripperId: 'd',
    filterId: 'f',
    beanId: 'b',
    roastLevel: _roasts[i % 5],
    origin: '',
    originId: 'origin_1',
    beanWeight: 15,
    grindSize: '',
    methodId: 'm',
    taste: '',
    concentration: '',
    temperature: 84 + (i % 9) + i * 0.03,
    bloomingWater: 0,
    totalWater: 215 + (i % 7) * 4 + i * 0.1,
    bloomingTime: 0,
    totalTime: 150 + (i % 6) * 8 + i,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    scoreOverall: 4 + (i % 7),
    comment: '',
  );
}

Future<void> _pump(WidgetTester tester, List<CoffeeRecord> records) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coffeeRecordsProvider.overrideWith((ref) async => records),
        originMasterProvider.overrideWith((ref) async => _origins),
      ],
      child: const MaterialApp(home: StatsStatusScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StatsStatusScreen (T3-36)', () {
    testWidgets('データ不足時は4機能すべて未稼働として表示される', (tester) async {
      final records = [for (var i = 0; i < 2; i++) _record(i)];
      await _pump(tester, records);

      expect(find.text('重回帰分析 (F1)'), findsOneWidget);
      expect(find.text('主成分分析 / PCA (F2)'), findsOneWidget);
      expect(find.text('ガウス過程回帰・探索 (F4)'), findsOneWidget);
      expect(find.text('好みの傾向の検定 (F5)'), findsOneWidget);
      expect(find.textContaining('未稼働'), findsNWidgets(4));
      expect(find.textContaining('稼働中'), findsNothing);
    });

    testWidgets('十分なデータがあれば稼働中として表示される', (tester) async {
      final records = [for (var i = 0; i < 40; i++) _record(i)];
      await _pump(tester, records);

      expect(find.textContaining('稼働中'), findsNWidgets(4));
      expect(find.textContaining('未稼働'), findsNothing);
    });

    testWidgets('本アイコンをタップすると統計理論ページ(041)へ遷移する', (tester) async {
      final records = [for (var i = 0; i < 2; i++) _record(i)];
      await _pump(tester, records);

      expect(find.byType(StatsTheoryScreen), findsNothing);
      await tester.tap(find.byTooltip('重回帰分析 (F1)の理論を読む'));
      await tester.pumpAndSettle();

      expect(find.byType(StatsTheoryScreen), findsOneWidget);
    });
  });
}
