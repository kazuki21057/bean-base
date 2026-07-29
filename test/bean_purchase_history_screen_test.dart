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
import 'package:bean_base/screens/bean_purchase_history_screen.dart';
import 'package:bean_base/services/data_service.dart';

import 'helpers/fake_master_notifiers.dart';

/// T3-64(`docs/bean_purchase_design.md`§6.1〜§6.3): 購入履歴(025)のリスト形式の検証。
class _FakeDataService implements DataService {
  final List<BeanMaster> beans;
  final List<BeanPurchase> purchases;

  _FakeDataService({this.beans = const [], this.purchases = const []});

  @override
  Future<List<BeanMaster>> getBeans() async => beans;
  @override
  Future<List<BeanPurchase>> getBeanPurchases() async => purchases;

  @override
  Future<void> addBeanPurchase(BeanPurchase purchase) async {}
  @override
  Future<void> updateBeanPurchase(BeanPurchase purchase) async {}
  @override
  Future<void> deleteBeanPurchase(String id) async {}
  @override
  Future<List<StoreMaster>> getStores() async => [];
  @override
  Future<void> addStore(StoreMaster store) async {}
  @override
  Future<void> updateStore(StoreMaster store) async {}
  @override
  Future<void> deleteStore(String id) async {}
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
  List<Override> overridesFor(_FakeDataService service) => [
        dataServiceProvider.overrideWithValue(service),
        beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() => service.getBeans())),
        beanPurchasesProvider.overrideWith(
            () => FakeBeanPurchaseNotifier(() => service.getBeanPurchases())),
      ];

  final beans = [
    BeanMaster(id: 'b1', name: 'エチオピア イルガチェフェ', roastLevel: '浅煎り', origin: 'エチオピア', store: 'Navy'),
    BeanMaster(id: 'b2', name: 'ケニア ニエリ', roastLevel: '中煎り', origin: 'ケニア', store: '岬の焙煎所'),
  ];

  testWidgets('購入日降順に行が表示され、豆名・購入店名・購入量がsubtitleに出る', (tester) async {
    final purchases = [
      BeanPurchase(
        id: 'p1',
        beanId: 'b1',
        purchasedAt: DateTime(2026, 7, 1),
        quantityGrams: 200,
        storeName: 'Navy',
      ),
      BeanPurchase(
        id: 'p2',
        beanId: 'b2',
        purchasedAt: DateTime(2026, 7, 29),
        quantityGrams: 300,
        storeName: '岬の焙煎所',
        roastDate: DateTime(2026, 7, 25),
      ),
    ];
    final fakeService = _FakeDataService(beans: beans, purchases: purchases);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanPurchaseHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final titles = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList();
    final keniaIndex = titles.indexWhere((t) => t == 'ケニア ニエリ');
    final ethiopiaIndex = titles.indexWhere((t) => t == 'エチオピア イルガチェフェ');
    expect(keniaIndex, greaterThanOrEqualTo(0));
    expect(ethiopiaIndex, greaterThanOrEqualTo(0));
    expect(keniaIndex, lessThan(ethiopiaIndex));

    expect(find.text('2026/07/29 · 岬の焙煎所 · 300.0g · 焙煎 07/25'), findsOneWidget);
    expect(find.text('2026/07/01 · Navy · 200.0g'), findsOneWidget);
  });

  testWidgets('行タップで豆詳細(011)へ遷移する', (tester) async {
    final purchases = [
      BeanPurchase(
        id: 'p1',
        beanId: 'b1',
        purchasedAt: DateTime(2026, 7, 1),
        quantityGrams: 200,
        storeName: 'Navy',
      ),
    ];
    final fakeService = _FakeDataService(beans: beans, purchases: purchases);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanPurchaseHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('エチオピア イルガチェフェ'));
    await tester.pumpAndSettle();

    expect(find.text('基本情報'), findsOneWidget);
  });

  testWidgets('履歴0件で空状態が出る', (tester) async {
    final fakeService = _FakeDataService(beans: beans, purchases: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanPurchaseHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('購入履歴がありません'), findsOneWidget);
  });
}
