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
import 'package:bean_base/screens/grinder_detail_screen.dart';
import 'package:bean_base/screens/grinder_list_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T1-5c の汎用マスターテンプレート適用(グラインダー)の検証。
/// プレビュー環境(サンドボックス)ではGASへの外部通信がブロックされるため、
/// DataServiceをフェイクに差し替えたwidgetテストで一覧→詳細→編集→保存/削除の
/// 一連の導線を確認する。
class _FakeDataService implements DataService {
  final List<GrinderMaster> grinders;
  GrinderMaster? lastAdded;
  GrinderMaster? lastUpdated;
  String? lastDeletedId;

  _FakeDataService(this.grinders);

  @override
  Future<void> addGrinder(GrinderMaster grinder) async {
    lastAdded = grinder;
    grinders.add(grinder);
  }

  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {
    lastUpdated = grinder;
    final index = grinders.indexWhere((g) => g.id == grinder.id);
    if (index >= 0) grinders[index] = grinder;
  }

  @override
  Future<void> deleteGrinder(String id) async {
    lastDeletedId = id;
    grinders.removeWhere((g) => g.id == id);
  }

  @override
  Future<List<GrinderMaster>> getGrinders() async => grinders;

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
  Future<void> deleteMethod(String id) async {}
  @override
  Future<void> deletePouringStep(String id) async {}
  @override
  Future<void> deletePouringStepsForMethod(String methodId) async {}
  @override
  Future<List<BeanMaster>> getBeans() async => [];
  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];
  @override
  Future<List<DripperMaster>> getDrippers() async => [];
  @override
  Future<List<FilterMaster>> getFilters() async => [];
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
  late List<GrinderMaster> grinders;
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service) => [
        dataServiceProvider.overrideWithValue(service),
        grinderMasterProvider.overrideWith((ref) => service.getGrinders()),
        coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
        beanMasterProvider.overrideWith((ref) async => <BeanMaster>[]),
        methodMasterProvider.overrideWith((ref) async => <MethodMaster>[]),
      ];

  setUp(() {
    grinders = [
      GrinderMaster(id: 'g1', name: 'コマンダンテ C40', grindRange: '15〜25クリック', description: '月1で分解清掃'),
      GrinderMaster(id: 'g2', name: 'Wilfa Svart', grindRange: '中挽き常用'),
    ];
    fakeService = _FakeDataService(grinders);
  });

  testWidgets('022 一覧に実データが表示され、行タップで023詳細へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: GrinderListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('コマンダンテ C40'), findsOneWidget);
    expect(find.text('Wilfa Svart'), findsOneWidget);

    await tester.tap(find.text('コマンダンテ C40'));
    await tester.pumpAndSettle();

    expect(find.text('15〜25クリック'), findsOneWidget);
    expect(find.text('月1で分解清掃'), findsOneWidget);
  });

  testWidgets('023詳細の編集→保存でDataService.updateGrinderが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: GrinderDetailScreen(grinder: grinders[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'コマンダンテ C40'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'コマンダンテ C40 MK4');
    await tester.tap(find.text('グラインダーを更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdated?.name, 'コマンダンテ C40 MK4');
    expect(fakeService.lastUpdated?.id, 'g1');
  });

  testWidgets('023詳細の削除確認→DataService.deleteGrinderが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: GrinderDetailScreen(grinder: grinders[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('削除確認'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(fakeService.lastDeletedId, 'g1');
  });

  testWidgets('022の＋ボタン→024新規フォームで登録するとDataService.addGrinderが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: GrinderListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Baratza Encore');
    await tester.tap(find.text('グラインダーを登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.name, 'Baratza Encore');
  });
}
