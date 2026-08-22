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
import 'package:bean_base/screens/store_detail_screen.dart';
import 'package:bean_base/screens/store_list_screen.dart';
import 'package:bean_base/services/data_service.dart';

import 'helpers/fake_master_notifiers.dart';

CoffeeRecord _mockRecord({required String beanId, required int scoreOverall}) {
  return CoffeeRecord(
    id: '${beanId}_${scoreOverall}_log',
    brewedAt: DateTime(2026, 7, 20, 9, 0),
    grinderId: '',
    dripperId: '',
    filterId: '',
    beanId: beanId,
    roastLevel: '',
    origin: '',
    beanWeight: 20,
    grindSize: '',
    methodId: 'm1',
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
    scoreOverall: scoreOverall,
    comment: '',
  );
}

/// T3-68: 購入店の一覧026/詳細027/新規028の検証。
/// `docs/store_master_design.md`§5のとおり、既存のドリッパー等と同じ
/// 汎用テンプレート(MasterListTemplate/MasterDetailTemplate)を適用している
/// ため、`dripper_template_test.dart`と同型の一覧→詳細→編集→保存/削除の
/// 導線に加え、この画面固有の「この店で買った豆」「統計」セクションを検証する。
class _FakeDataService implements DataService {
  final List<StoreMaster> stores;
  final List<BeanMaster> beans;
  final List<CoffeeRecord> records;
  StoreMaster? lastAdded;
  StoreMaster? lastUpdated;
  String? lastDeletedId;

  _FakeDataService(this.stores, {this.beans = const [], this.records = const []});

  @override
  Future<List<StoreMaster>> getStores() async => stores;
  @override
  Future<void> addStore(StoreMaster store) async {
    lastAdded = store;
    stores.add(store);
  }

  @override
  Future<void> updateStore(StoreMaster store) async {
    lastUpdated = store;
    final index = stores.indexWhere((s) => s.id == store.id);
    if (index >= 0) stores[index] = store;
  }

  @override
  Future<void> deleteStore(String id) async {
    lastDeletedId = id;
    stores.removeWhere((s) => s.id == id);
  }

  // --- Unused by this test: minimal stubs to satisfy the interface ---
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
  Future<void> addCoffeeRecord(CoffeeRecord record) async {}
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
  Future<void> deleteCoffeeRecord(String id) async {}
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
  Future<List<BeanMaster>> getBeans() async => beans;
  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => records;
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
  Future<void> updateCoffeeRecord(CoffeeRecord record) async {}
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

void main() {
  late List<StoreMaster> stores;
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service, List<StoreMaster> stores) => [
        dataServiceProvider.overrideWithValue(service),
        storeMasterProvider.overrideWith(() => FakeStoreMasterNotifier(() => service.getStores())),
        coffeeRecordsProvider.overrideWith((ref) async => service.records),
        beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => service.beans)),
        methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => <MethodMaster>[])),
      ];

  setUp(() {
    stores = [
      StoreMaster(id: 's1', name: 'Navy', prefecture: '兵庫県', hasRoastery: true),
      StoreMaster(id: 's2', name: 'SORA'),
    ];
    fakeService = _FakeDataService(stores);
  });

  testWidgets('026 一覧に実データが表示され、行タップで027詳細へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, stores),
        child: const MaterialApp(home: StoreListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Navy'), findsOneWidget);
    expect(find.text('SORA'), findsOneWidget);
    expect(find.text('兵庫県 ・ 自家焙煎'), findsOneWidget);

    await tester.tap(find.text('Navy'));
    await tester.pumpAndSettle();

    // 027詳細: 基本情報の項目が表示される
    expect(find.text('オンライン販売 ・ 実店舗 ・ 焙煎所併設'), findsNothing);
    expect(find.text('焙煎所併設'), findsOneWidget);
  });

  testWidgets('027詳細: この店で買った豆・統計セクションがstoreId一致の豆から算出される', (tester) async {
    final beans = [
      BeanMaster(
        id: 'b1',
        name: 'エチオピア イルガチェフェ',
        roastLevel: '',
        origin: '',
        store: 'Navy',
        storeId: 's1',
        initialQuantityGrams: 200,
      ),
      BeanMaster(
        id: 'b2',
        name: 'ケニア ニエリ',
        roastLevel: '',
        origin: '',
        store: 'SORA',
        storeId: 's2',
        initialQuantityGrams: 100,
      ),
    ];
    final records = [
      _mockRecord(beanId: 'b1', scoreOverall: 8),
      _mockRecord(beanId: 'b1', scoreOverall: 6),
      _mockRecord(beanId: 'b2', scoreOverall: 9),
    ];
    fakeService = _FakeDataService(stores, beans: beans, records: records);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, stores),
        child: MaterialApp(home: StoreDetailScreen(store: stores[0])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('エチオピア イルガチェフェ'), findsOneWidget);
    expect(find.text('ケニア ニエリ'), findsNothing);

    // 「統計」セクションは画面下部にあるため、スクロールして表示させる。
    await tester.dragUntilVisible(
      find.text('購入回数'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('1回'), findsOneWidget);
    expect(find.text('200g'), findsOneWidget);
    expect(find.text('7.0'), findsOneWidget);
  });

  testWidgets('027詳細の編集→保存でDataService.updateStoreが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, stores),
        child: MaterialApp(home: StoreDetailScreen(store: stores[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Navy'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Navy Coffee');
    await tester.tap(find.text('購入店を更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdated?.name, 'Navy Coffee');
    expect(fakeService.lastUpdated?.id, 's1');
  });

  testWidgets('027詳細の削除確認→DataService.deleteStoreが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, stores),
        child: MaterialApp(home: StoreDetailScreen(store: stores[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('削除確認'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(fakeService.lastDeletedId, 's1');
  });

  testWidgets('026の＋ボタン→028新規フォームで登録するとDataService.addStoreが呼ばれる(店名必須)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, stores),
        child: const MaterialApp(home: StoreListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 店名未入力のまま保存すると弾かれる
    await tester.tap(find.text('購入店を登録する'));
    await tester.pumpAndSettle();
    expect(find.text('店名を入力してください'), findsOneWidget);
    expect(fakeService.lastAdded, isNull);

    await tester.enterText(find.byType(TextField).first, '岬の焙煎所');
    await tester.tap(find.text('購入店を登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.name, '岬の焙煎所');
  });

  testWidgets('T5-A104 Major#3: 抽出記録の取得に失敗するとエラーメッセージが表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overridesFor(fakeService, stores),
          coffeeRecordsProvider.overrideWith((ref) async => throw Exception('通信エラー')),
        ],
        child: MaterialApp(home: StoreDetailScreen(store: stores[0])),
      ),
    );
    await tester.pumpAndSettle();

    // 通信失敗時も無言でデータ0件扱いにせず、ユーザーにエラーを伝える。
    expect(find.textContaining('データの読み込みに失敗した項目があります'), findsOneWidget);
    // 店名自体は(コンストラクタ引数へのフォールバックで)引き続き表示される。
    expect(find.text('Navy'), findsWidgets);
  });
}
