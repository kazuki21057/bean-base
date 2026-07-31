import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/exploration_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_master_notifiers.dart';

/// T3-53c(設計書§10.2): 045画面(探索の検証状況)の検証。
/// `test/gp_explorer_section_test.dart`の`_record`ヘルパと同じ流儀で、
/// GPが成立する8件構成のCoffeeRecordを使い回す。
CoffeeRecord _record(
  String id, {
  required String beanId,
  required String methodId,
  required String grinderId,
  required String grindSize,
  required String originId,
  required String roastLevel,
  required int score,
  double temperature = 92,
  double beanWeight = 15,
  double totalWater = 225,
  int totalTime = 150,
  DateTime? brewedAt,
}) {
  return CoffeeRecord(
    id: id,
    brewedAt: brewedAt ?? DateTime(2026, 7, 20),
    beanId: beanId,
    methodId: methodId,
    beanWeight: beanWeight,
    totalWater: totalWater,
    totalTime: totalTime,
    scoreOverall: score,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    taste: '',
    comment: '',
    grindSize: grindSize,
    temperature: temperature,
    dripperId: '',
    filterId: '',
    grinderId: grinderId,
    roastLevel: roastLevel,
    origin: '',
    originId: originId,
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

/// GPの最小データ条件(nEff>=6.0 かつ nRows>=8)を満たす8件セット。
List<CoffeeRecord> _sufficientRecords({
  required String beanId,
  required String methodId,
  required List<int> scores,
}) {
  final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0, 96.0, 82.0];
  final ratios = [14.5, 15.0, 15.5, 16.0, 16.5, 17.0, 17.5, 18.0];
  final times = [140, 150, 160, 170, 180, 190, 200, 210];
  final grinds = ['80', '90', '100', '110', '120', '85', '95', '105'];
  return [
    for (var i = 0; i < 8; i++)
      _record(
        '${methodId}_r$i',
        beanId: beanId,
        methodId: methodId,
        grinderId: 'g1',
        grindSize: grinds[i],
        originId: 'origin_1',
        roastLevel: 'ハイ',
        score: scores[i],
        temperature: temps[i],
        totalWater: 15 * ratios[i],
        totalTime: times[i],
        brewedAt: DateTime(2026, 7, 1 + i),
      ),
  ];
}

Future<void> _pump(
  WidgetTester tester, {
  required List<CoffeeRecord> records,
  List<BeanMaster> beans = const [],
  List<GrinderMaster> grinders = const [],
  List<MethodMaster> methods = const [],
  String? initialBeanId,
  String? initialGrinderId,
  String? initialMethodId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coffeeRecordsProvider.overrideWith((ref) async => records),
        beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => beans)),
        grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => grinders)),
        methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => methods)),
      ],
      child: MaterialApp(
        home: ExplorationStatusScreen(
          initialBeanId: initialBeanId,
          initialGrinderId: initialGrinderId,
          initialMethodId: initialMethodId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final grinders = [
    GrinderMaster(id: 'g1', name: 'Kingrinder K6', grindRange: '180'),
  ];
  final methods = [
    MethodMaster(
      id: 'm1',
      name: '4:6メソッド',
      author: '',
      baseBeanWeight: 15,
      baseWaterAmount: 225,
      description: '',
      recommendedEquipment: '',
    ),
  ];

  group('ExplorationStatusScreen (T3-53c)', () {
    testWidgets('記録が十分にあるとき、5つの見出しがすべて出る', (tester) async {
      final beans = [
        BeanMaster(id: 'b1', name: 'エチオピア イルガチェフェ', roastLevel: 'ハイ', origin: '', originId: 'origin_1'),
      ];
      final records = _sufficientRecords(beanId: 'b1', methodId: 'm1', scores: [6, 7, 8, 9, 6, 7, 8, 9]);

      await _pump(tester, records: records, beans: beans, grinders: grinders, methods: methods);

      expect(find.text('探索サマリ'), findsOneWidget);
      expect(find.textContaining('次に試すと良い条件'), findsOneWidget);
      expect(find.text('スコアの推移'), findsOneWidget);
      expect(find.text('試した条件の分布'), findsOneWidget);
      expect(find.text('試行の一覧'), findsOneWidget);
    });

    testWidgets('initialBeanId/initialMethodIdを渡すと、その豆・メソッドが選択された状態で開く', (tester) async {
      final beans = [
        // 名前順で先頭に来る豆(アルファ)。記録を持たせず、既定選択との違いが
        // 見分けられるようにする。
        BeanMaster(id: 'b_alpha', name: 'アルファ', roastLevel: 'ハイ', origin: '', originId: 'origin_1'),
        BeanMaster(id: 'b_zeta', name: 'ゼータ', roastLevel: 'ハイ', origin: '', originId: 'origin_1'),
      ];
      final twoMethods = [
        methods.first,
        MethodMaster(
          id: 'm2',
          name: 'Bメソッド',
          author: '',
          baseBeanWeight: 15,
          baseWaterAmount: 225,
          description: '',
          recommendedEquipment: '',
        ),
      ];
      // m1の方がスコアが高く(既定=μ降順で先頭になる)、m2は低め。
      final records = [
        ..._sufficientRecords(beanId: 'b_zeta', methodId: 'm1', scores: [8, 9, 8, 9, 8, 9, 8, 9]),
        ..._sufficientRecords(beanId: 'b_zeta', methodId: 'm2', scores: [4, 5, 4, 5, 4, 5, 4, 5]),
      ];

      await _pump(
        tester,
        records: records,
        beans: beans,
        grinders: grinders,
        methods: twoMethods,
        initialBeanId: 'b_zeta',
        initialMethodId: 'm2',
      );

      // b_zeta(記録あり)が選択されているため、空状態メッセージではなく
      // 試行回数の集計行が出る。
      expect(find.textContaining('この豆の抽出記録がまだありません'), findsNothing);
      expect(find.textContaining('試行 16 回'), findsOneWidget);
      // 既定(μ降順)ならm1が選ばれるはずだが、initialMethodId:'m2'を
      // 指定したのでBメソッドが選択されている。
      expect(find.textContaining('次に試すと良い条件 — Bメソッド'), findsOneWidget);
    });

    testWidgets('該当豆の記録が0件のとき案内文が出て、スコア推移・試行一覧が描かれない', (tester) async {
      final beans = [
        BeanMaster(id: 'b_empty', name: '記録なしの豆', roastLevel: 'ハイ', origin: '', originId: 'origin_1'),
      ];

      await _pump(
        tester,
        records: const [],
        beans: beans,
        grinders: grinders,
        methods: methods,
        initialBeanId: 'b_empty',
      );

      expect(find.textContaining('この豆の抽出記録がまだありません'), findsOneWidget);
      expect(find.text('スコアの推移'), findsNothing);
      expect(find.text('試行の一覧'), findsNothing);
    });

    testWidgets('記録が1件だけのとき、スコア推移に案内文が出る', (tester) async {
      final beans = [
        BeanMaster(id: 'b_one', name: '記録1件の豆', roastLevel: 'ハイ', origin: '', originId: 'origin_1'),
      ];
      final records = [
        _record(
          'r_single',
          beanId: 'b_one',
          methodId: 'm1',
          grinderId: 'g1',
          grindSize: '90',
          originId: 'origin_1',
          roastLevel: 'ハイ',
          score: 7,
        ),
      ];

      await _pump(
        tester,
        records: records,
        beans: beans,
        grinders: grinders,
        methods: methods,
        initialBeanId: 'b_one',
      );

      expect(find.text('スコアの推移'), findsOneWidget);
      expect(find.textContaining('記録が2件以上になるとスコアの推移を表示します'), findsOneWidget);
    });

    testWidgets('モバイル幅(390)でもオーバーフローしない', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final beans = [
        BeanMaster(id: 'b1', name: 'エチオピア イルガチェフェ', roastLevel: 'ハイ', origin: '', originId: 'origin_1'),
      ];
      final records = _sufficientRecords(beanId: 'b1', methodId: 'm1', scores: [6, 7, 8, 9, 6, 7, 8, 9]);

      await _pump(tester, records: records, beans: beans, grinders: grinders, methods: methods);

      expect(find.textContaining('次に試すと良い条件'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
