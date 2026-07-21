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
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/create/bean_create_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// T4-1e: 012(新規豆追加)の産地マスタ選択ドロップダウン・新規産地追加・
/// 焙煎日入力の検証。
class _FakeDataService implements DataService {
  final List<OriginMaster> origins;
  BeanMaster? lastAdded;
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
  Future<void> updateBean(BeanMaster bean) async {}
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
}
