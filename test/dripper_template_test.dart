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
import 'package:bean_base/screens/dripper_detail_screen.dart';
import 'package:bean_base/screens/dripper_list_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T1-5a の汎用マスターテンプレート(MasterListTemplate/
/// MasterDetailTemplate)をドリッパーへ適用した本実装の検証。
/// プレビュー環境(サンドボックス)ではGASへの外部通信がブロックされるため、
/// DataServiceをフェイクに差し替えたwidgetテストで一覧→詳細→編集→保存/削除の
/// 一連の導線を確認する。
class _FakeDataService implements DataService {
  final List<DripperMaster> drippers;
  DripperMaster? lastAdded;
  DripperMaster? lastUpdated;
  String? lastDeletedId;

  _FakeDataService(this.drippers);

  @override
  Future<void> addDripper(DripperMaster dripper) async {
    lastAdded = dripper;
    drippers.add(dripper);
  }

  @override
  Future<void> updateDripper(DripperMaster dripper) async {
    lastUpdated = dripper;
    final index = drippers.indexWhere((d) => d.id == dripper.id);
    if (index >= 0) drippers[index] = dripper;
  }

  @override
  Future<void> deleteDripper(String id) async {
    lastDeletedId = id;
    drippers.removeWhere((d) => d.id == id);
  }

  @override
  Future<List<DripperMaster>> getDrippers() async => drippers;

  // --- Unused by this test: minimal stubs to satisfy the interface ---
  @override
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {}
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
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];
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
  late List<DripperMaster> drippers;
  late _FakeDataService fakeService;

  List<Override> overridesFor(_FakeDataService service, List<DripperMaster> drippers) => [
        dataServiceProvider.overrideWithValue(service),
        dripperMasterProvider.overrideWith((ref) => service.getDrippers()),
        coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
        beanMasterProvider.overrideWith((ref) async => <BeanMaster>[]),
        methodMasterProvider.overrideWith((ref) async => <MethodMaster>[]),
      ];

  setUp(() {
    drippers = [
      DripperMaster(id: 'd1', name: 'HARIO V60 02', material: 'セラミック', shape: '円錐'),
      DripperMaster(id: 'd2', name: 'Kalita Wave 185', material: 'ステンレス', shape: '平底(ウェーブ)'),
    ];
    fakeService = _FakeDataService(drippers);
  });

  testWidgets('013 一覧に実データが表示され、行タップで014詳細へ遷移する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, drippers),
        child: const MaterialApp(home: DripperListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HARIO V60 02'), findsOneWidget);
    expect(find.text('Kalita Wave 185'), findsOneWidget);

    await tester.tap(find.text('HARIO V60 02'));
    await tester.pumpAndSettle();

    // 014詳細: 全情報が表示される
    expect(find.text('セラミック'), findsOneWidget);
    expect(find.text('円錐'), findsOneWidget);
  });

  testWidgets('014詳細の編集→保存でDataService.updateDripperが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, drippers),
        child: MaterialApp(home: DripperDetailScreen(dripper: drippers[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // 編集フォームに既存の名前が反映されている
    expect(find.widgetWithText(TextField, 'HARIO V60 02'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'HARIO V60 03');
    await tester.tap(find.text('ドリッパーを更新する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdated?.name, 'HARIO V60 03');
    expect(fakeService.lastUpdated?.id, 'd1');
  });

  testWidgets('014詳細の削除確認→DataService.deleteDripperが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, drippers),
        child: MaterialApp(home: DripperDetailScreen(dripper: drippers[0])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('削除確認'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(fakeService.lastDeletedId, 'd1');
  });

  testWidgets('013の＋ボタン→015新規フォームで登録するとDataService.addDripperが呼ばれる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(fakeService, drippers),
        child: const MaterialApp(home: DripperListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'メリタ アロマフィルター');
    await tester.tap(find.text('ドリッパーを登録する'));
    await tester.pumpAndSettle();

    expect(fakeService.lastAdded?.name, 'メリタ アロマフィルター');
  });
}
