import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/widgets/statistics/pca_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CoffeeRecord _record(
  int i, {
  int fragrance = 5,
  int acidity = 5,
  int bitterness = 5,
  int sweetness = 5,
  int complexity = 5,
  int flavor = 5,
}) {
  return CoffeeRecord(
    id: 'r$i',
    brewedAt: DateTime(2026, 7, 21),
    beanId: 'b$i',
    methodId: 'm',
    beanWeight: 15,
    totalWater: 225,
    totalTime: 150,
    scoreOverall: 7,
    scoreFragrance: fragrance,
    scoreAcidity: acidity,
    scoreBitterness: bitterness,
    scoreSweetness: sweetness,
    scoreComplexity: complexity,
    scoreFlavor: flavor,
    taste: '',
    comment: '',
    grindSize: '',
    temperature: 90,
    dripperId: '',
    filterId: '',
    grinderId: '',
    roastLevel: '中煎り',
    origin: 'エチオピア',
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

// 6軸それぞれ異なる変動パターンを持つ非縮退データ(実質的なPCAが行える程度に
// 分散が分かれている)。
final _variedRecords = [
  _record(1, fragrance: 6, acidity: 7, bitterness: 3, sweetness: 8, complexity: 5, flavor: 6),
  _record(2, fragrance: 8, acidity: 4, bitterness: 7, sweetness: 5, complexity: 8, flavor: 4),
  _record(3, fragrance: 4, acidity: 8, bitterness: 4, sweetness: 3, complexity: 6, flavor: 8),
  _record(4, fragrance: 7, acidity: 3, bitterness: 8, sweetness: 7, complexity: 3, flavor: 5),
  _record(5, fragrance: 5, acidity: 6, bitterness: 5, sweetness: 6, complexity: 7, flavor: 3),
  _record(6, fragrance: 9, acidity: 5, bitterness: 6, sweetness: 4, complexity: 4, flavor: 7),
];

Future<void> _pump(WidgetTester tester, List<CoffeeRecord> records) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: PcaDetailPanel(records: records)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PcaDetailPanel (T4-3b)', () {
    testWidgets('データ不足(3件未満)なら何も表示しない', (tester) async {
      final records = [_record(1), _record(2)];
      await _pump(tester, records);

      expect(find.text('寄与率'), findsNothing);
      expect(find.textContaining('v1.1'), findsNothing);
    });

    testWidgets('十分なデータで寄与率バー・負荷量テーブル・AIボタンを表示する', (tester) async {
      await _pump(tester, _variedRecords);

      expect(find.textContaining('v1.1: 分析方法を相関行列ベースに改善しました'), findsOneWidget);
      expect(find.text('寄与率'), findsOneWidget);
      expect(find.text('負荷量 (PC1/PC2、|L|≥0.5を強調)'), findsOneWidget);
      expect(find.text('AIで深掘り解釈する'), findsOneWidget);
      // 除外軸は無い(全軸で分散があるデータ)。
      expect(find.textContaining('除外された軸'), findsNothing);
    });

    testWidgets('標準偏差0の軸があると除外メッセージを表示し、残り軸でPCAを行う', (tester) async {
      // scoreFlavorを全件同値(7)にすると、その軸だけ除外される。
      final records = _variedRecords.map((r) => r.copyWith(scoreFlavor: 7)).toList();
      await _pump(tester, records);

      expect(find.textContaining('除外された軸(全件同値のため計算不可): Flavor'), findsOneWidget);
      expect(find.text('寄与率'), findsOneWidget);
    });
  });
}
