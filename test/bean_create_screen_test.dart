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
import 'package:bean_base/screens/create/bean_create_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// T4-1e: 012(新規豆追加)の産地マスタ選択ドロップダウン・新規産地追加・
/// 焙煎日入力の検証。
class _FakeDataService implements DataService {
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
  BeanPurchase? lastAddedPurchase;
  bool throwOnAddBeanPurchase = false;
  @override
  Future<void> addBeanPurchase(BeanPurchase purchase) async {
    if (throwOnAddBeanPurchase) throw Exception('購入履歴の記録に失敗');
    lastAddedPurchase = purchase;
  }
  @override
  Future<void> updateBeanPurchase(BeanPurchase purchase) async {}
  @override
  Future<void> deleteBeanPurchase(String id) async {}
  final List<OriginMaster> origins;
  BeanMaster? lastAdded;
  BeanMaster? lastUpdated;
  OriginMaster? lastSavedOrigin;

  _FakeDataService(this.origins);

  @override
  Future<List<OriginMaster>> fetchOriginMasters() async => origins;
  @override
  Future<void> saveOriginMaster(OriginMaster origin) async {
    lastSavedOrigin = origin;
    origins.add(origin);
  }

  @override
  Future<void> addBean(BeanMaster bean) async => lastAdded = bean;
  @override
  Future<void> updateBean(BeanMaster bean) async => lastUpdated = bean;
  @override
  Future<void> deleteBean(String id) async {}
  @override
  Future<List<BeanMaster>> getBeans() async => [];
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
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service) => [
        dataServiceProvider.overrideWithValue(service),
        originMasterProvider.overrideWith((ref) => service.fetchOriginMasters()),
      ];

  setUp(() {
    fakeService = _FakeDataService([
      OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
      OriginMaster(id: 'origin_5', countryCode: 'BR', nameJa: 'ブラジル', nameEn: 'Brazil', region: '中南米'),
    ]);
  });

  testWidgets('産地ドロップダウンで選択→登録するとoriginId・originが正しく保存される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '豆の名前').hitTestable(), '豆A');

    await tester.tap(find.byType(DropdownButtonFormField<OriginMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ブラジル').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('豆を登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.originId, 'origin_5');
    expect(fakeService.lastAdded?.origin, 'ブラジル');
  });

  testWidgets('新規産地追加ダイアログで追加するとDataService.saveOriginMasterが呼ばれ選択状態になる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新規産地追加'));
    await tester.pumpAndSettle();

    expect(find.text('新規産地追加'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, '産地名(必須、例: エチオピア)'), 'ケニア');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect(fakeService.lastSavedOrigin?.nameJa, 'ケニア');

    await tester.enterText(find.widgetWithText(TextField, '豆の名前').hitTestable(), '豆B');
    await tester.tap(find.text('豆を登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.origin, 'ケニア');
  });

  testWidgets('焙煎日を入力せずに登録してもroastDateはnullのまま', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '豆の名前').hitTestable(), '豆C');
    await tester.tap(find.text('豆を登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.roastDate, isNull);
  });

  testWidgets('T3-30: パッケージ画像から自動入力ボタンが表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('パッケージ画像から自動入力(AI)'), findsOneWidget);
  });

  testWidgets('T3-35: 自動入力ボタンをタップするとファイル選択/カメラ撮影の選択ダイアログが表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('パッケージ画像から自動入力(AI)'));
    await tester.pumpAndSettle();

    expect(find.text('画像の取得方法'), findsOneWidget);
    expect(find.text('ファイルから選択'), findsOneWidget);
    expect(find.text('カメラで撮影'), findsOneWidget);
  });

  testWidgets('T3-34: 画像アップロード欄がパッケージ/豆/情報の3つ表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 「画像」FormSectionはListView下方にあり遅延生成されるため、
    // scrollUntilVisibleでスクロールしてから確認する(T3-29の教訓と同様)。
    await tester.scrollUntilVisible(
      find.text('パッケージ画像'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('パッケージ画像'), findsOneWidget);
    expect(find.text('豆画像'), findsOneWidget);
    expect(find.text('情報画像(説明書き等)'), findsOneWidget);
  });

  testWidgets('T3-34: 編集時に既存の3種類の画像URLがフォームに引き継がれ、更新時にそのまま保存される', (tester) async {
    final edit = BeanMaster(
      id: 'b1',
      name: '既存の豆',
      roastLevel: '中煎り',
      origin: 'ブラジル',
      imageUrl: 'https://example.com/package.jpg',
      beanImageUrl: 'https://example.com/bean.jpg',
      infoImageUrl: 'https://example.com/info.jpg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: BeanCreateScreen(editData: edit)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('豆を更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded, isNull);
    expect(fakeService.lastUpdated?.imageUrl, 'https://example.com/package.jpg');
    expect(fakeService.lastUpdated?.beanImageUrl, 'https://example.com/bean.jpg');
    expect(fakeService.lastUpdated?.infoImageUrl, 'https://example.com/info.jpg');
  });

  testWidgets('T3-63b: 012の新規登録で購入日を入力するとbp_init_<豆ID>のIDで初回購入が記録される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '豆の名前').hitTestable(), '豆D');
    await tester.enterText(find.widgetWithText(TextField, '焙煎所 / 購入店').hitTestable(), 'テスト焙煎所');

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, '初期購入量(g)'),
      50,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '初期購入量(g)').hitTestable(), '200');

    await tester.scrollUntilVisible(
      find.text('購入日'),
      50,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('購入日'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('豆を登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded, isNotNull);
    expect(fakeService.lastAddedPurchase, isNotNull);
    expect(fakeService.lastAddedPurchase?.id, 'bp_init_${fakeService.lastAdded!.id}');
    expect(fakeService.lastAddedPurchase?.beanId, fakeService.lastAdded!.id);
    expect(fakeService.lastAddedPurchase?.quantityGrams, 200);
    expect(fakeService.lastAddedPurchase?.storeName, 'テスト焙煎所');
  });

  testWidgets('T3-63b: 012の新規登録で購入日を入力しなければ初回購入は記録されない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: BeanCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '豆の名前').hitTestable(), '豆E');
    await tester.tap(find.text('豆を登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded, isNotNull);
    expect(fakeService.lastAddedPurchase, isNull);
  });

  testWidgets('T3-63b: 編集モードで購入日があっても初回購入は記録されない', (tester) async {
    final edit = BeanMaster(
      id: 'b1',
      name: '既存の豆',
      roastLevel: '中煎り',
      origin: 'ブラジル',
      purchaseDate: DateTime(2026, 7, 1),
      initialQuantityGrams: 150,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: BeanCreateScreen(editData: edit)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('豆を更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdated, isNotNull);
    expect(fakeService.lastAddedPurchase, isNull);
  });
}
