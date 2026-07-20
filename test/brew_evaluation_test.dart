import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pending_brew_info.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/create/brew_evaluation_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T2-5a: 031(評価画面)の本実装(評価入力→records登録)の検証。
/// method_template_test.dart等と同じフェイクDataServiceパターンで、
/// 030から引き継いだ抽出情報+評価入力が実際にCoffeeRecordとして
/// addCoffeeRecordに渡ることを確認する。
/// Cycle 20 T2-5b: 登録後に031に留まり連続記録できることも検証する。
/// Cycle 20 T3-5: 豆/グラインダー/ドリッパー/フィルター選択が030から031へ
/// 移動したため、これらは`PendingBrewInfo`に事前セットせず、031画面上の
/// ドロップダウンから選択してCoffeeRecordに反映されることを検証する。
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
  testWidgets(
      'BrewEvaluationScreen: 030からは豆/グラインダー/ドリッパー/フィルター未選択で引き継ぎ、031で選択して登録するとCoffeeRecordに反映される',
      (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    final bean = BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true);
    final grinder = GrinderMaster(id: 'g1', name: 'Kingrinder K6');
    final dripper = DripperMaster(id: 'd1', name: 'V60');
    final filter = FilterMaster(id: 'f1', name: 'ペーパー');
    // T3-5: 030は豆量以外の器具・豆を選択しないため、PendingBrewInfoにはbean/
    // grinder/dripper/filterを一切セットしない(030→031の実際の引き継ぎ状態)。
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
      beanWeight: 20,
      totalWater: 300,
      totalTime: 210,
      bloomingWater: 40,
      bloomingTime: 45,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          methodMasterProvider.overrideWith((ref) async => [info.method!]),
          beanMasterProvider.overrideWith((ref) async => [bean]),
          grinderMasterProvider.overrideWith((ref) async => [grinder]),
          dripperMasterProvider.overrideWith((ref) async => [dripper]),
          filterMasterProvider.overrideWith((ref) async => [filter]),
        ],
        child: MaterialApp(home: BrewEvaluationScreen(info: info)),
      ),
    );
    await tester.pumpAndSettle();

    // サマリ・メソッド選択欄の両方に引き継いだメソッドが表示されている(T3-17)。
    // 豆は031で選ぶためこの時点ではまだ未選択(ドロップダウンのラベルのみ表示)。
    expect(find.text('4:6メソッド'), findsNWidgets(2));
    expect(find.text('エチオピア'), findsNothing);

    // 031で豆/グラインダー/ドリッパー/フィルターを選択する。
    // T3-17でメソッド・豆量・総湯量・湯温の入力欄が追加されたため、下にある
    // ドロップダウンは画面外になりうる(下方向にスクロールしてからタップする。
    // brew_recipe_test.dartと同じパターン)。
    final listView = find.byType(ListView);
    await tester.drag(listView, const Offset(0, -300));
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('評価を登録する'));
    await tester.pumpAndSettle();

    final saved = fakeService.lastAddedRecord;
    expect(saved, isNotNull);
    expect(saved!.beanId, 'b1');
    expect(saved.methodId, 'm1');
    expect(saved.grinderId, 'g1');
    expect(saved.dripperId, 'd1');
    expect(saved.filterId, 'f1');
    expect(saved.beanWeight, 20.0);
    expect(saved.totalWater, 300.0);
    expect(saved.totalTime, 210);
    // MockScoreSlider/MockChoiceChipsの初期値がそのまま登録される
    expect(saved.scoreOverall, 7);
    expect(saved.taste, 'バランス');
    expect(saved.concentration, 'ちょうど良い');
    expect(find.text('抽出記録を登録しました(1件目)。続けて記録できます'), findsOneWidget);
  });

  testWidgets('BrewEvaluationScreen: 登録後もダッシュボードへ戻らず031に留まり、連続記録できる(T2-5b)。'
      '器具・豆選択は維持され、抽出日時のみ進む(T3-5)',
      (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    // 002からの「評価を継承」を想定し、bean を PendingBrewInfo に事前セットする。
    final bean = BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true);
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
      bean: bean,
      beanWeight: 20,
      totalWater: 300,
      totalTime: 210,
      bloomingWater: 40,
      bloomingTime: 45,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          methodMasterProvider.overrideWith((ref) async => [info.method!]),
          beanMasterProvider.overrideWith((ref) async => [bean]),
          grinderMasterProvider.overrideWith((ref) async => <GrinderMaster>[]),
          dripperMasterProvider.overrideWith((ref) async => <DripperMaster>[]),
          filterMasterProvider.overrideWith((ref) async => <FilterMaster>[]),
        ],
        child: MaterialApp(home: BrewEvaluationScreen(info: info)),
      ),
    );
    await tester.pumpAndSettle();

    // 1件目登録
    await tester.tap(find.text('評価を登録する'));
    await tester.pumpAndSettle();

    // ダッシュボードへ遷移せず、031自体(豆ドロップダウンの選択値)がまだ表示されている
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

  testWidgets(
      'BrewEvaluationScreen: 030でメソッド未選択(T3-15)でも表示・登録でき、この画面でメソッド・豆量・総湯量を編集できる(T3-17)。'
      '4:6メソッド以外では「味わい」欄が非表示・非保存になる(T3-18)',
      (WidgetTester tester) async {
    final fakeService = _FakeDataService();
    final v60Method = MethodMaster(
      id: 'm2',
      name: 'V60 Test',
      author: 'Test',
      baseBeanWeight: 15,
      baseWaterAmount: 250,
      description: '',
      recommendedEquipment: '',
    );
    // T3-15: 030でメソッドを選ばずに031へ進んだ状態を再現(method: null)。
    final info = PendingBrewInfo(
      brewedAt: DateTime(2026, 7, 20, 9, 0),
      method: null,
      beanWeight: 20,
      totalWater: 0,
      totalTime: 0,
      bloomingWater: 0,
      bloomingTime: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          methodMasterProvider.overrideWith((ref) async => [v60Method]),
          beanMasterProvider.overrideWith((ref) async => <BeanMaster>[]),
          grinderMasterProvider.overrideWith((ref) async => <GrinderMaster>[]),
          dripperMasterProvider.overrideWith((ref) async => <DripperMaster>[]),
          filterMasterProvider.overrideWith((ref) async => <FilterMaster>[]),
        ],
        child: MaterialApp(home: BrewEvaluationScreen(info: info)),
      ),
    );
    await tester.pumpAndSettle();

    // メソッド未選択のままでも表示され、味わい欄は非表示(4:6メソッドではないため)。
    expect(find.text('メソッド未選択'), findsOneWidget);
    expect(find.text('テイスト'), findsNothing);

    // この画面でメソッドを選択できる(T3-17)。
    await tester.tap(find.byType(DropdownButtonFormField<MethodMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60 Test').last);
    await tester.pumpAndSettle();

    // V60 Testも4:6メソッドではないため、選択後も味わい欄は表示されない。
    expect(find.text('テイスト'), findsNothing);

    // 豆量・総湯量もこの画面で編集できる(T3-17)。
    await tester.enterText(find.widgetWithText(TextField, '豆量'), '25');
    await tester.enterText(find.widgetWithText(TextField, '総湯量'), '400');
    await tester.pumpAndSettle();

    await tester.tap(find.text('評価を登録する'));
    await tester.pumpAndSettle();

    final saved = fakeService.lastAddedRecord;
    expect(saved, isNotNull);
    expect(saved!.methodId, 'm2');
    expect(saved.beanWeight, 25.0);
    expect(saved.totalWater, 400.0);
    // 4:6メソッドではないため、味わい入力は空文字で保存される(T3-18)。
    expect(saved.taste, '');
    expect(saved.concentration, '');
  });
}
