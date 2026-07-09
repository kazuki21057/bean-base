import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/filter_detail_screen.dart';
import 'package:bean_base/screens/filter_list_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T1-5b の汎用マスターテンプレート適用(フィルター)の検証。
/// プレビュー環境(サンドボックス)ではGASへの外部通信がブロックされるため、
/// DataServiceをフェイクに差し替えたwidgetテストで一覧→詳細→編集→保存/削除の
/// 一連の導線を確認する。
class _FakeDataService implements DataService {
  final List<FilterMaster> filters;
  FilterMaster? lastAdded;
  FilterMaster? lastUpdated;
  String? lastDeletedId;

  _FakeDataService(this.filters);

  @override
  Future<void> addFilter(FilterMaster filter) async {
    lastAdded = filter;
    filters.add(filter);
  }

  @override
  Future<void> updateFilter(FilterMaster filter) async {
    lastUpdated = filter;
    final index = filters.indexWhere((f) => f.id == filter.id);
    if (index >= 0) filters[index] = filter;
  }

  @override
  Future<void> deleteFilter(String id) async {
    lastDeletedId = id;
    filters.removeWhere((f) => f.id == id);
  }

  @override
  Future<List<FilterMaster>> getFilters() async => filters;

  // --- Unused by this test: minimal stubs to satisfy the interface ---
  @override
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> addDripper(DripperMaster dripper) async {}
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
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];
  @override
  Future<List<DripperMaster>> getDrippers() async => [];
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
  Future<void> updateGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> updateMethod(MethodMaster method) async {}
  @override
  Future<void> updatePouringStep(PouringStep step) async {}
}

void main() {
  late List<FilterMaster> filters;
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service) => [
        dataServiceProvider.overrideWithValue(service),
        filterMasterProvider.overrideWith((ref) => service.getFilters()),
        coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
        beanMasterProvider.overrideWith((ref) async => <BeanMaster>[]),
        methodMasterProvider.overrideWith((ref) async => <MethodMaster>[]),
      ];

  setUp(() {
    filters = [
      FilterMaster(id: 'f1', name: 'V60ペーパーフィルター 02', material: 'ペーパー(漂白)', size: '02'),
      FilterMaster(id: 'f2', name: 'ネルフィルター', material: '布(ネル)', size: 'その他'),
    ];
    fakeService = _FakeDataService(filters);
  });

  testWidgets('016 一覧に実データが表示され、行タップで017詳細へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: FilterListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('V60ペーパーフィルター 02'), findsOneWidget);
    expect(find.text('ネルフィルター'), findsOneWidget);

    await tester.tap(find.text('V60ペーパーフィルター 02'));
    await tester.pumpAndSettle();

    expect(find.text('ペーパー(漂白)'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
  });

  testWidgets('017詳細の編集→保存でDataService.updateFilterが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: FilterDetailScreen(filter: filters[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'V60ペーパーフィルター 02'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'V60ペーパーフィルター 03');
    await tester.tap(find.text('フィルターを更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdated?.name, 'V60ペーパーフィルター 03');
    expect(fakeService.lastUpdated?.id, 'f1');
  });

  testWidgets('017詳細の削除確認→DataService.deleteFilterが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: MaterialApp(home: FilterDetailScreen(filter: filters[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('削除確認'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(fakeService.lastDeletedId, 'f1');
  });

  testWidgets('016の＋ボタン→018新規フォームで登録するとDataService.addFilterが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService),
        child: const MaterialApp(home: FilterListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'メリタ アロマフィルター');
    await tester.tap(find.text('フィルターを登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.name, 'メリタ アロマフィルター');
  });
}
