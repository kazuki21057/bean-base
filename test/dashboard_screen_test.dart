import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/models/store_master.dart';
import 'package:bean_base/models/bean_purchase.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/dashboard_screen.dart';
import 'package:bean_base/services/data_service.dart';

import 'helpers/fake_master_notifiers.dart';

/// T3-50: 001ダッシュボードの「最適条件の探索」未回答案内カードの検証。
class _FakeDataService implements DataService {
  final List<BeanMaster> beans;
  BeanMaster? lastUpdated;

  _FakeDataService(this.beans);

  @override
  Future<void> updateBean(BeanMaster bean) async {
    lastUpdated = bean;
    final index = beans.indexWhere((b) => b.id == bean.id);
    if (index >= 0) beans[index] = bean;
  }

  @override
  Future<List<BeanMaster>> getBeans() async => beans;
  @override
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> deleteBean(String id) async {}

  @override
  Future<List<StoreMaster>> getStores() async => [];
  @override
  Future<void> addStore(StoreMaster store) async {}
  @override
  Future<void> updateStore(StoreMaster store) async {}
  @override
  Future<void> deleteStore(String id) async {}
  @override
  Future<List<BeanPurchase>> getBeanPurchases() async => [];
  @override
  Future<void> addBeanPurchase(BeanPurchase purchase) async {}
  @override
  Future<void> updateBeanPurchase(BeanPurchase purchase) async {}
  @override
  Future<void> deleteBeanPurchase(String id) async {}
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
  @override
  Future<List<OriginMaster>> fetchOriginMasters() async => [];
  @override
  Future<void> saveOriginMaster(OriginMaster origin) async {}
  @override
  Future<List<AnalysisSnapshot>> fetchAnalysisSnapshots({String? type}) async => [];
  @override
  Future<void> saveAnalysisSnapshot(AnalysisSnapshot snapshot) async {}
  @override
  Future<List<RecipeSuggestion>> fetchRecipeSuggestions() async => [];
  @override
  Future<void> saveRecipeSuggestion(RecipeSuggestion suggestion) async {}
  @override
  Future<void> updateRecipeSuggestion(RecipeSuggestion suggestion) async {}
}

void main() {
  late List<BeanMaster> beans;
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service) => [
        dataServiceProvider.overrideWithValue(service),
        beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() => service.getBeans())),
        coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
        methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => <MethodMaster>[])),
      ];

  testWidgets('T3-50: 未回答の豆があれば「最適条件の探索」案内カードが表示される', (tester) async {
    beans = [
      BeanMaster(id: 'b1', name: '豆A', roastLevel: '中煎り', origin: 'ブラジル'),
    ];
    fakeService = _FakeDataService(beans);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('「豆A」の最適な淹れ方を探しますか?'), findsOneWidget);
    expect(find.text('探索する'), findsOneWidget);
    expect(find.text('探索しない'), findsOneWidget);
  });

  testWidgets('T3-50: 「探索する」をタップするとupdateBeanが呼ばれseekOptimalConditions=trueになる', (tester) async {
    beans = [
      BeanMaster(id: 'b1', name: '豆A', roastLevel: '中煎り', origin: 'ブラジル'),
    ];
    fakeService = _FakeDataService(beans);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('探索する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdated?.id, 'b1');
    expect(fakeService.lastUpdated?.seekOptimalConditions, true);
    // 楽観的更新により回答済みの豆は案内カードから消える
    expect(find.text('「豆A」の最適な淹れ方を探しますか?'), findsNothing);
  });

  testWidgets('T3-50: 全ての豆が回答済みなら案内カードは表示されない', (tester) async {
    beans = [
      BeanMaster(id: 'b1', name: '豆A', roastLevel: '中煎り', origin: 'ブラジル', seekOptimalConditions: true),
    ];
    fakeService = _FakeDataService(beans);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('最適条件の探索'), findsNothing);
  });
}
