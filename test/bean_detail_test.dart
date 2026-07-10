import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/bean_detail_screen.dart';
import 'package:bean_base/screens/bean_list_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T1-6b: 豆詳細(011)・新規豆追加/編集(012)の本実装の検証。
/// プレビュー環境(サンドボックス)ではGASへの外部通信がブロックされるため、
/// DataServiceをフェイクに差し替えたwidgetテストで一覧→詳細→編集→保存/削除・
/// 新規登録の一連導線を確認する。
class _FakeDataService implements DataService {
  final List<BeanMaster> beans;
  BeanMaster? lastAdded;
  BeanMaster? lastUpdated;
  String? lastDeletedId;

  _FakeDataService(this.beans);

  @override
  Future<void> addBean(BeanMaster bean) async {
    lastAdded = bean;
    beans.add(bean);
  }

  @override
  Future<void> updateBean(BeanMaster bean) async {
    lastUpdated = bean;
    final index = beans.indexWhere((b) => b.id == bean.id);
    if (index >= 0) beans[index] = bean;
  }

  @override
  Future<void> deleteBean(String id) async {
    lastDeletedId = id;
    beans.removeWhere((b) => b.id == id);
  }

  @override
  Future<List<BeanMaster>> getBeans() async => beans;

  // --- Unused by this test: minimal stubs to satisfy the interface ---
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
        coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
        methodMasterProvider.overrideWith((ref) async => <MethodMaster>[]),
      ];

  setUp(() {
    beans = [
      BeanMaster(
        id: 'b1',
        name: 'エチオピア イルガチェフェ',
        roastLevel: '浅煎り',
        origin: 'エチオピア',
        store: '岬の焙煎所',
        type: 'ウォッシュド',
        purchaseDate: DateTime(2026, 6, 15),
        isInStock: true,
        initialQuantityGrams: 200,
      ),
    ];
    fakeService = _FakeDataService(beans);
  });

  testWidgets('010一覧から011詳細へ遷移し全情報が表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('エチオピア イルガチェフェ'));
    await tester.pumpAndSettle();

    expect(find.text('岬の焙煎所'), findsOneWidget);
    expect(find.text('ウォッシュド'), findsOneWidget);
    expect(find.text('2026/06/15'), findsOneWidget);
    expect(find.text('100% (在庫あり)'), findsOneWidget);
  });

  testWidgets('011詳細の編集→保存でDataService.updateBeanが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: BeanDetailScreen(bean: beans[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'エチオピア イルガチェフェ'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'エチオピア イルガチェフェ 改');
    await tester.tap(find.text('豆を更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdated?.name, 'エチオピア イルガチェフェ 改');
    expect(fakeService.lastUpdated?.id, 'b1');
    // 編集で触れなかった項目(産地・初期購入量)は維持される
    expect(fakeService.lastUpdated?.origin, 'エチオピア');
    expect(fakeService.lastUpdated?.initialQuantityGrams, 200);
  });

  testWidgets('011詳細の削除確認→DataService.deleteBeanが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: BeanDetailScreen(bean: beans[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('削除確認'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(fakeService.lastDeletedId, 'b1');
  });

  testWidgets('010の＋ボタン→012新規フォームで登録するとDataService.addBeanが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ケニア ニエリ');
    await tester.tap(find.text('豆を登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.name, 'ケニア ニエリ');
  });
}
