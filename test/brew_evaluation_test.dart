import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pending_brew_info.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/screens/create/brew_evaluation_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T2-5a: 031(評価画面)の本実装(評価入力→records登録)の検証。
/// method_template_test.dart等と同じフェイクDataServiceパターンで、
/// 030から引き継いだ抽出情報+評価入力が実際にCoffeeRecordとして
/// addCoffeeRecordに渡ることを確認する。
/// Cycle 20 T2-5b: 登録後に031に留まり連続記録できることも検証する。
class _FakeDataService implements DataService {
  CoffeeRecord? lastAddedRecord;
  final List<CoffeeRecord> addedRecords = [];

  @override
  Future<void> addCoffeeRecord(CoffeeRecord record) async {
    lastAddedRecord = record;
    addedRecords.add(record);
  }

  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];

  // --- Unused by this test: minimal stubs to satisfy the interface ---
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
}

void main() {
  testWidgets('BrewEvaluationScreen: 「評価を登録する」で実際にDataService.addCoffeeRecordが呼ばれる',
      (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    final info = PendingBrewInfo(
      brewedAt: DateTime(2026, 7, 11, 9, 0),
      method: MethodMaster(
        id: 'm1',
        name: '4:6メソッド',
        author: '粕谷 哲',
        baseBeanWeight: 20,
        baseWaterAmount: 300,
        temperature: 92,
        description: '',
        recommendedEquipment: '',
      ),
      bean: BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア'),
      grinder: GrinderMaster(id: 'g1', name: 'Kingrinder K6'),
      dripper: DripperMaster(id: 'd1', name: 'V60'),
      filter: FilterMaster(id: 'f1', name: 'ペーパー'),
      beanWeight: 20,
      totalWater: 300,
      totalTime: 210,
      bloomingWater: 40,
      bloomingTime: 45,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataServiceProvider.overrideWithValue(fakeService)],
        child: MaterialApp(home: BrewEvaluationScreen(info: info)),
      ),
    );
    await tester.pumpAndSettle();

    // サマリに引き継いだ抽出情報が表示されている
    expect(find.text('エチオピア'), findsOneWidget);
    expect(find.text('4:6メソッド'), findsOneWidget);

    await tester.tap(find.text('評価を登録する'));
    await tester.pumpAndSettle();

    final saved = fakeService.lastAddedRecord;
    expect(saved, isNotNull);
    expect(saved!.beanId, 'b1');
    expect(saved.methodId, 'm1');
    expect(saved.grinderId, 'g1');
    expect(saved.beanWeight, 20.0);
    expect(saved.totalWater, 300.0);
    expect(saved.totalTime, 210);
    // MockScoreSlider/MockChoiceChipsの初期値がそのまま登録される
    expect(saved.scoreOverall, 7);
    expect(saved.taste, 'バランス');
    expect(saved.concentration, 'ちょうど良い');
    expect(find.text('抽出記録を登録しました(1件目)。続けて記録できます'), findsOneWidget);
  });

  testWidgets('BrewEvaluationScreen: 登録後もダッシュボードへ戻らず031に留まり、連続記録できる(T2-5b)',
      (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    final info = PendingBrewInfo(
      brewedAt: DateTime(2026, 7, 11, 9, 0),
      method: MethodMaster(
        id: 'm1',
        name: '4:6メソッド',
        author: '粕谷 哲',
        baseBeanWeight: 20,
        baseWaterAmount: 300,
        temperature: 92,
        description: '',
        recommendedEquipment: '',
      ),
      bean: BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア'),
      beanWeight: 20,
      totalWater: 300,
      totalTime: 210,
      bloomingWater: 40,
      bloomingTime: 45,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataServiceProvider.overrideWithValue(fakeService)],
        child: MaterialApp(home: BrewEvaluationScreen(info: info)),
      ),
    );
    await tester.pumpAndSettle();

    // 1件目登録
    await tester.tap(find.text('評価を登録する'));
    await tester.pumpAndSettle();

    // ダッシュボードへ遷移せず、031自体(サマリカード)がまだ表示されている
    expect(find.text('エチオピア'), findsOneWidget);
    expect(find.text('評価を登録する'), findsOneWidget);
    expect(fakeService.addedRecords.length, 1);

    // 2件目登録(同じ画面のまま、フォームがリセットされた状態で)
    await tester.tap(find.text('評価を登録する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(fakeService.addedRecords.length, 2);

    // 1件目は030で選んだ日時のまま、2件目以降は登録時点の現在時刻を使う
    final first = fakeService.addedRecords[0];
    final second = fakeService.addedRecords[1];
    expect(first.brewedAt, DateTime(2026, 7, 11, 9, 0));
    expect(second.brewedAt, isNot(equals(first.brewedAt)));
    // 豆・メソッド等の抽出情報は2件目も引き継がれている
    expect(second.beanId, 'b1');
    expect(second.methodId, 'm1');
  });
}
