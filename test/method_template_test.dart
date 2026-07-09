import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/method_detail_screen.dart';
import 'package:bean_base/screens/method_list_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T1-5d の汎用マスターテンプレート適用(メソッド)の検証。
/// プレビュー環境(サンドボックス)ではGASへの外部通信がブロックされるため、
/// DataServiceをフェイクに差し替えたwidgetテストで一覧→詳細→編集→保存/削除の
/// 一連の導線と、メソッド固有の注湯ステップ編集を確認する。
class _FakeDataService implements DataService {
  final List<MethodMaster> methods;
  final List<PouringStep> steps;
  final List<CoffeeRecord> logs;
  MethodMaster? lastAddedMethod;
  MethodMaster? lastUpdatedMethod;
  String? lastDeletedMethodId;
  final List<PouringStep> addedSteps = [];
  final List<PouringStep> updatedSteps = [];
  final List<String> deletedStepIds = [];
  bool deletedStepsForMethodCalled = false;

  _FakeDataService({required this.methods, this.steps = const [], this.logs = const []});

  @override
  Future<void> addMethod(MethodMaster method) async {
    lastAddedMethod = method;
    methods.add(method);
  }

  @override
  Future<void> updateMethod(MethodMaster method) async {
    lastUpdatedMethod = method;
    final index = methods.indexWhere((m) => m.id == method.id);
    if (index >= 0) methods[index] = method;
  }

  @override
  Future<void> deleteMethod(String id) async {
    lastDeletedMethodId = id;
    methods.removeWhere((m) => m.id == id);
  }

  @override
  Future<List<MethodMaster>> getMethods() async => methods;

  @override
  Future<void> addPouringStep(PouringStep step) async => addedSteps.add(step);

  @override
  Future<void> updatePouringStep(PouringStep step) async => updatedSteps.add(step);

  @override
  Future<void> deletePouringStep(String id) async => deletedStepIds.add(id);

  @override
  Future<void> deletePouringStepsForMethod(String methodId) async {
    deletedStepsForMethodCalled = true;
  }

  @override
  Future<List<PouringStep>> getPouringSteps() async => steps;

  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => logs;

  // --- Unused by this test: minimal stubs to satisfy the interface ---
  @override
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> addDripper(DripperMaster dripper) async {}
  @override
  Future<void> addFilter(FilterMaster filter) async {}
  @override
  Future<void> addGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> deleteBean(String id) async {}
  @override
  Future<void> deleteCoffeeRecord(String id) async {}
  @override
  Future<void> deleteDripper(String id) async {}
  @override
  Future<void> deleteFilter(String id) async {}
  @override
  Future<void> deleteGrinder(String id) async {}
  @override
  Future<List<BeanMaster>> getBeans() async => [];
  @override
  Future<List<DripperMaster>> getDrippers() async => [];
  @override
  Future<List<FilterMaster>> getFilters() async => [];
  @override
  Future<List<GrinderMaster>> getGrinders() async => [];
  @override
  Future<void> updateBean(BeanMaster bean) async {}
  @override
  Future<void> updateCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> updateDripper(DripperMaster dripper) async {}
  @override
  Future<void> updateFilter(FilterMaster filter) async {}
  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {}
}

CoffeeRecord _fakeLog({required String id, required String methodId}) {
  return CoffeeRecord(
    id: id,
    brewedAt: DateTime(2026, 7, 1),
    grinderId: '',
    dripperId: '',
    filterId: '',
    beanId: 'b1',
    roastLevel: '',
    origin: '',
    beanWeight: 20,
    grindSize: '',
    methodId: methodId,
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 40,
    totalWater: 300,
    bloomingTime: 30,
    totalTime: 180,
    scoreFragrance: 5,
    scoreAcidity: 5,
    scoreBitterness: 5,
    scoreSweetness: 5,
    scoreComplexity: 5,
    scoreFlavor: 5,
    scoreOverall: 7,
    comment: '',
  );
}

void main() {
  late List<MethodMaster> methods;
  late List<PouringStep> steps;
  late List<CoffeeRecord> logs;
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service) => [
        dataServiceProvider.overrideWithValue(service),
        methodMasterProvider.overrideWith((ref) => service.getMethods()),
        pouringStepsProvider.overrideWith((ref) => service.getPouringSteps()),
        coffeeRecordsProvider.overrideWith((ref) => service.getCoffeeRecords()),
        beanMasterProvider.overrideWith((ref) async => <BeanMaster>[]),
      ];

  setUp(() {
    methods = [
      MethodMaster(
        id: 'm1',
        name: '4:6メソッド',
        author: '粕谷 哲',
        baseBeanWeight: 20,
        baseWaterAmount: 300,
        temperature: 92,
        grindSize: '中粗挽き',
        description: '前半4割で味、後半6割で濃度を調整する',
        recommendedEquipment: 'V60',
      ),
      MethodMaster(
        id: 'm2',
        name: 'V60 Standard',
        author: 'HARIO',
        baseBeanWeight: 15,
        baseWaterAmount: 250,
        description: '',
        recommendedEquipment: '',
      ),
    ];
    steps = [
      PouringStep(
        id: 's1',
        methodId: 'm1',
        stepOrder: 1,
        duration: 45,
        waterAmount: 40,
        waterReference: 20,
        description: '蒸らし',
      ),
    ];
    logs = [
      _fakeLog(id: 'l1', methodId: 'm1'),
      _fakeLog(id: 'l2', methodId: 'm1'),
      _fakeLog(id: 'l3', methodId: 'm2'),
    ];
    fakeService = _FakeDataService(methods: methods, steps: steps, logs: logs);
  });

  testWidgets('019一覧に実データと抽出回数が表示され、行タップで020詳細へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: MethodListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4:6メソッド'), findsOneWidget);
    expect(find.text('粕谷 哲 ・ 抽出 2回'), findsOneWidget);
    expect(find.text('HARIO ・ 抽出 1回'), findsOneWidget);

    await tester.tap(find.text('4:6メソッド'));
    await tester.pumpAndSettle();

    expect(find.text('中粗挽き'), findsOneWidget);
    expect(find.text('蒸らし'), findsOneWidget);
  });

  testWidgets('020詳細の編集→注湯ステップを含めて保存するとDataServiceが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: MethodDetailScreen(method: methods[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '4:6メソッド'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '4:6メソッド 改');
    await tester.tap(find.text('メソッドを更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdatedMethod?.name, '4:6メソッド 改');
    expect(fakeService.updatedSteps.any((s) => s.id == 's1'), isTrue);
  });

  testWidgets('020詳細の削除確認→DataService.deleteMethod/deletePouringStepsForMethodが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: MethodDetailScreen(method: methods[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('削除確認'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(fakeService.lastDeletedMethodId, 'm1');
    expect(fakeService.deletedStepsForMethodCalled, isTrue);
  });

  testWidgets('019の＋ボタン→021新規フォームで登録するとDataService.addMethodが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: MethodListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Hoffmann 1cup');
    await tester.tap(find.text('メソッドを登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAddedMethod?.name, 'Hoffmann 1cup');
  });
}
