import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/widgets/brew/gp_explorer_section.dart';

import 'helpers/fake_master_notifiers.dart';

/// T3-52c(gp_multidim_design.md §6): F4レシピ探索セクション(4次元GP+メソッド別
/// ランキング)の検証。豆・ミルに十分な記録があるとメソッド比較表+推奨条件が
/// 表示されること、データ不足時は固定文言が出ることを確認する。
CoffeeRecord _record(
  String id, {
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
}) {
  return CoffeeRecord(
    id: id,
    brewedAt: DateTime(2026, 7, 20),
    beanId: 'b1',
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

Future<void> _pump(
  WidgetTester tester, {
  required List<CoffeeRecord> records,
  List<BeanMaster> beans = const [],
  List<GrinderMaster> grinders = const [],
  List<MethodMaster> methods = const [],
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
        home: Scaffold(
          body: SingleChildScrollView(child: const GpExplorerSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final beans = [
    BeanMaster(id: 'b1', name: 'エチオピア イルガチェフェ', roastLevel: 'ハイ', origin: '', originId: 'origin_1'),
  ];
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

  group('GpExplorerSection (T3-52c)', () {
    testWidgets('豆とミルのドロップダウンが表示される', (tester) async {
      await _pump(tester, records: const [], beans: beans, grinders: grinders, methods: methods);

      expect(find.text('豆'), findsOneWidget);
      expect(find.text('ミル'), findsOneWidget);
    });

    testWidgets('メソッドに十分な記録があると比較表と推奨条件を表示する', (tester) async {
      final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0, 96.0, 82.0];
      final ratios = [14.5, 15.0, 15.5, 16.0, 16.5, 17.0, 17.5, 18.0];
      final times = [140, 150, 160, 170, 180, 190, 200, 210];
      final grinds = ['80', '90', '100', '110', '120', '85', '95', '105'];
      final scores = [6, 7, 8, 9, 6, 7, 8, 9];

      final records = [
        for (var i = 0; i < 8; i++)
          _record(
            'r$i',
            methodId: 'm1',
            grinderId: 'g1',
            grindSize: grinds[i],
            originId: 'origin_1',
            roastLevel: 'ハイ',
            score: scores[i],
            temperature: temps[i],
            totalWater: 15 * ratios[i],
            totalTime: times[i],
          ),
      ];

      await _pump(tester, records: records, beans: beans, grinders: grinders, methods: methods);

      expect(find.textContaining('おすすめの条件'), findsOneWidget);
      expect(find.textContaining('95%予測区間'), findsOneWidget);
      expect(find.textContaining('予測総合評価マップ'), findsOneWidget);
      expect(find.text('4:6メソッド'), findsWidgets);
    });

    testWidgets('記録が少なくどのメソッドも最小データ条件を満たさない場合は案内文を表示する', (tester) async {
      final records = [
        for (var i = 0; i < 3; i++)
          _record(
            'r$i',
            methodId: 'm1',
            grinderId: 'g1',
            grindSize: '90',
            originId: 'origin_1',
            roastLevel: 'ハイ',
            score: 7 + i,
          ),
      ];

      await _pump(tester, records: records, beans: beans, grinders: grinders, methods: methods);

      expect(find.textContaining('この豆に近い記録が十分に集まっているメソッドがまだありません'), findsOneWidget);
      expect(find.textContaining('おすすめの条件'), findsNothing);
    });

    testWidgets('産地・焙煎度が登録された豆が無い場合は案内文を表示する', (tester) async {
      final noOriginBeans = [
        BeanMaster(id: 'b2', name: '産地未設定の豆', roastLevel: 'ハイ', origin: '', originId: ''),
      ];

      await _pump(tester, records: const [], beans: noOriginBeans, grinders: grinders, methods: methods);

      expect(find.textContaining('産地・焙煎度が登録された豆がまだありません'), findsOneWidget);
    });

    testWidgets('T3-54b踏襲: モバイル幅(390)でもオーバーフローしない', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0, 96.0, 82.0];
      final ratios = [14.5, 15.0, 15.5, 16.0, 16.5, 17.0, 17.5, 18.0];
      final times = [140, 150, 160, 170, 180, 190, 200, 210];
      final grinds = ['80', '90', '100', '110', '120', '85', '95', '105'];
      final records = [
        for (var i = 0; i < 8; i++)
          _record(
            'r$i',
            methodId: 'm1',
            grinderId: 'g1',
            grindSize: grinds[i],
            originId: 'origin_1',
            roastLevel: 'ハイ',
            score: 7 + (i % 3),
            temperature: temps[i],
            totalWater: 15 * ratios[i],
            totalTime: times[i],
          ),
      ];

      await _pump(tester, records: records, beans: beans, grinders: grinders, methods: methods);

      expect(find.textContaining('おすすめの条件'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
