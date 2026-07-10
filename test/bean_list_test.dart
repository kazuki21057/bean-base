import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/bean_list_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T1-6a: 豆管理カード一覧(010)の本実装(実データ表示)の検証。
/// プレビュー環境(サンドボックス)ではGASへの外部通信がブロックされるため、
/// DataServiceをフェイクに差し替えたwidgetテストでカード表示・0%表示切替・
/// 詳細への遷移を確認する。
class _FakeDataService implements DataService {
  final List<BeanMaster> beans;

  _FakeDataService(this.beans);

  @override
  Future<List<BeanMaster>> getBeans() async => beans;

  // --- Unused by this test: minimal stubs to satisfy the interface ---
  @override
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> updateBean(BeanMaster bean) async {}
  @override
  Future<void> deleteBean(String id) async {}
  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> updateCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> deleteCoffeeRecord(String id) async {}
  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];
  @override
  Future<void> addDripper(DripperMaster dripper) async {}
  @override
  Future<void> updateDripper(DripperMaster dripper) async {}
  @override
  Future<void> deleteDripper(String id) async {}
  @override
  Future<List<DripperMaster>> getDrippers() async => [];
  @override
  Future<void> addFilter(FilterMaster filter) async {}
  @override
  Future<void> updateFilter(FilterMaster filter) async {}
  @override
  Future<void> deleteFilter(String id) async {}
  @override
  Future<List<FilterMaster>> getFilters() async => [];
  @override
  Future<void> addGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> deleteGrinder(String id) async {}
  @override
  Future<List<GrinderMaster>> getGrinders() async => [];
  @override
  Future<void> addMethod(MethodMaster method) async {}
  @override
  Future<void> updateMethod(MethodMaster method) async {}
  @override
  Future<void> deleteMethod(String id) async {}
  @override
  Future<List<MethodMaster>> getMethods() async => [];
  @override
  Future<void> addPouringStep(PouringStep step) async {}
  @override
  Future<void> updatePouringStep(PouringStep step) async {}
  @override
  Future<void> deletePouringStep(String id) async {}
  @override
  Future<void> deletePouringStepsForMethod(String methodId) async {}
  @override
  Future<List<PouringStep>> getPouringSteps() async => [];
}

void main() {
  late List<BeanMaster> beans;
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service) => [
        dataServiceProvider.overrideWithValue(service),
        beanMasterProvider.overrideWith((ref) => service.getBeans()),
      ];

  setUp(() {
    beans = [
      BeanMaster(
        id: 'b1',
        name: 'エチオピア イルガチェフェ',
        roastLevel: '浅煎り',
        origin: 'エチオピア',
        store: '岬の焙煎所',
        isInStock: true,
      ),
      BeanMaster(
        id: 'b2',
        name: 'ケニア ニエリ',
        roastLevel: '中煎り',
        origin: 'ケニア',
        store: 'Navy',
        isInStock: false,
      ),
    ];
    fakeService = _FakeDataService(beans);
  });

  testWidgets('010に実データのカードが表示され、在庫ありの豆のみ既定で表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('エチオピア イルガチェフェ'), findsOneWidget);
    expect(find.text('岬の焙煎所'), findsOneWidget);
    expect(find.text('浅煎り'), findsOneWidget);
    expect(find.text('残 100%'), findsOneWidget);

    // 在庫なし(残量0%)の豆は既定では非表示。
    expect(find.text('ケニア ニエリ'), findsNothing);
  });

  testWidgets('0%表示切替をONにすると在庫なしの豆も表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ケニア ニエリ'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('ケニア ニエリ'), findsOneWidget);
    expect(find.text('残 0%'), findsOneWidget);
  });

  testWidgets('カードをタップすると豆詳細(011)へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('エチオピア イルガチェフェ'));
    await tester.pumpAndSettle();

    expect(find.text('この豆の抽出履歴 5件'), findsOneWidget);
  });
}
