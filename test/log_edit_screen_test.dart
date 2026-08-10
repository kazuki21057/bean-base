// ignore_for_file: unawaited_futures
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/bean_purchase.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/models/store_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/log_edit_screen.dart';
import 'package:bean_base/services/data_service.dart';

import 'helpers/fake_master_notifiers.dart';

/// T3-76: 履歴編集画面(002/003からの`LogEditScreen`)で豆・器具・メソッド等の
/// マスタ参照フィールドが編集・保存できることを検証する。
class _FakeDataService implements DataService {
  CoffeeRecord? lastUpdatedRecord;

  @override
  Future<void> updateCoffeeRecord(CoffeeRecord record) async {
    lastUpdatedRecord = record;
  }

  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];
  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> deleteCoffeeRecord(String id) async {}

  // --- Unused by this test: minimal stubs to satisfy the interface ---
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
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> addDripper(DripperMaster dripper) async {}
  @override
  Future<void> addFilter(FilterMaster filter) async {}
  @override
  Future<void> addGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> addMethod(MethodMaster method) async {}
  @override
  Future<void> addPouringStep(PouringStep step) async {}
  @override
  Future<void> deleteBean(String id) async {}
  @override
  Future<void> deleteDripper(String id) async {}
  @override
  Future<void> deleteFilter(String id) async {}
  @override
  Future<void> deleteGrinder(String id) async {}
  @override
  Future<void> deleteMethod(String id) async {}
  @override
  Future<void> deletePouringStep(String id) async {}
  @override
  Future<void> deletePouringStepsForMethod(String methodId) async {}
  @override
  Future<List<BeanMaster>> getBeans() async => [];
  @override
  Future<List<DripperMaster>> getDrippers() async => [];
  @override
  Future<List<FilterMaster>> getFilters() async => [];
  @override
  Future<List<GrinderMaster>> getGrinders() async => [];
  @override
  Future<List<MethodMaster>> getMethods() async => [];
  @override
  Future<List<PouringStep>> getPouringSteps() async => [];
  @override
  Future<void> updateBean(BeanMaster bean) async {}
  @override
  Future<void> updateDripper(DripperMaster dripper) async {}
  @override
  Future<void> updateFilter(FilterMaster filter) async {}
  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> updateMethod(MethodMaster method) async {}
  @override
  Future<void> updatePouringStep(PouringStep step) async {}
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

CoffeeRecord _buildLog({
  required String beanId,
  required String grinderId,
  required String dripperId,
  required String filterId,
  required String methodId,
}) {
  return CoffeeRecord(
    id: 'r1',
    brewedAt: DateTime(2026, 8, 1, 9, 0),
    grinderId: grinderId,
    dripperId: dripperId,
    filterId: filterId,
    beanId: beanId,
    roastLevel: '浅煎り',
    origin: 'エチオピア',
    beanWeight: 20,
    grindSize: '中挽き',
    methodId: methodId,
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 40,
    totalWater: 300,
    bloomingTime: 45,
    totalTime: 210,
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

/// `LogEditScreen`は保存成功時に`Navigator.pop`を2回呼ぶ(編集画面を閉じ、
/// さらに詳細画面もスキップして一覧へ戻る実際の002→003→編集の遷移を想定した
/// 挙動)。単体の`MaterialApp(home: LogEditScreen(...))`だと戻り先route が
/// 無く2回目のpopでクラッシュするため、実際のnavigationスタックを模した
/// 3階層(一覧→詳細→編集)を`onGenerateInitialRoutes`で用意する。
Future<void> _pumpLogEditScreen(
  WidgetTester tester,
  CoffeeRecord log,
  List<Override> overrides,
) async {
  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: Text('一覧')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  navKey.currentState!.push(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('詳細'))));
  await tester.pumpAndSettle();
  navKey.currentState!.push(MaterialPageRoute(builder: (_) => LogEditScreen(log: log)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'LogEditScreen: T3-76 旧記録では未選択だった豆・グラインダー・ドリッパー・'
      'フィルター・メソッドをこの画面で選択・保存できる', (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    final bean = BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true);
    final grinder = GrinderMaster(id: 'g1', name: 'Kingrinder K6');
    final dripper = DripperMaster(id: 'd1', name: 'V60');
    final filter = FilterMaster(id: 'f1', name: 'ペーパー');
    final method = MethodMaster(
      id: 'm1',
      name: 'V60 Test',
      author: '',
      baseBeanWeight: 20,
      baseWaterAmount: 300,
      description: '',
      recommendedEquipment: '',
    );
    final log = _buildLog(beanId: '', grinderId: '', dripperId: '', filterId: '', methodId: '');

    await _pumpLogEditScreen(tester, log, [
      dataServiceProvider.overrideWithValue(fakeService),
      methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [method])),
      beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [bean])),
      grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => [grinder])),
      dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => [dripper])),
      filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => [filter])),
    ]);

    await tester.tap(find.byType(DropdownButtonFormField<BeanMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('エチオピア').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<GrinderMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kingrinder K6').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<DripperMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<FilterMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ペーパー').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<MethodMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60 Test').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    final saved = fakeService.lastUpdatedRecord;
    expect(saved, isNotNull);
    expect(saved!.beanId, 'b1');
    expect(saved.roastLevel, '浅煎り');
    expect(saved.origin, 'エチオピア');
    expect(saved.grinderId, 'g1');
    expect(saved.dripperId, 'd1');
    expect(saved.filterId, 'f1');
    expect(saved.methodId, 'm1');
  });

  testWidgets('LogEditScreen: T3-76 豆が未選択のまま保存しようとするとエラーが表示され保存されない',
      (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    final log = _buildLog(beanId: '', grinderId: '', dripperId: '', filterId: '', methodId: '');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => <MethodMaster>[])),
          beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => <BeanMaster>[])),
          grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => <GrinderMaster>[])),
          dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => <DripperMaster>[])),
          filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => <FilterMaster>[])),
        ],
        child: MaterialApp(home: LogEditScreen(log: log)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('豆を選択してください'), findsOneWidget);
    expect(fakeService.lastUpdatedRecord, isNull);
  });

  testWidgets(
      'LogEditScreen: T3-76 4:6メソッド選択時のみ味わい欄が表示され、選択・保存できる',
      (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    final bean = BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true);
    final method46 = MethodMaster(
      id: 'm1',
      name: '4:6メソッド',
      author: '',
      baseBeanWeight: 20,
      baseWaterAmount: 300,
      description: '',
      recommendedEquipment: '',
    );
    final log = _buildLog(beanId: 'b1', grinderId: '', dripperId: '', filterId: '', methodId: 'm1');

    await _pumpLogEditScreen(tester, log, [
      dataServiceProvider.overrideWithValue(fakeService),
      methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [method46])),
      beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [bean])),
      grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => <GrinderMaster>[])),
      dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => <DripperMaster>[])),
      filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => <FilterMaster>[])),
    ]);

    expect(find.text('テイスト'), findsOneWidget);
    expect(find.text('濃度'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    final saved = fakeService.lastUpdatedRecord;
    expect(saved, isNotNull);
    expect(saved!.taste, 'バランス');
    expect(saved.concentration, 'ちょうど良い');
  });
}
