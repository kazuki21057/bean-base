import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/screens/brew_recipe_screen.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/services/data_service.dart';

/// Cycle 20 T2-3a: 030(抽出レシピ)を実データ接続の新デザインへ移植した際の
/// 検証。メソッド選択→Pouring Steps読込・編集・保存ダイアログの導線を確認する
/// (旧英語UI版の検証内容を新デザイン・日本語UIに合わせて更新)。
/// 新デザインは`ListView`(遅延ビルド)を使うため、旧`SingleChildScrollView`
/// 版と異なりビューポート外のウィジェットは明示的にスクロールしてから
/// 検証する必要がある(上へスクロールし戻すとオフスクリーンでの
/// タップがエラーになるため、下方向にのみスクロールする一方向の流れにする)。
///
/// Cycle 20 T2-4a: 「上書き保存」がDataServiceに実際に接続されたことを
/// フェイクDataServiceで検証する(method_template_test.dartと同じパターン)。
class _FakeDataService implements DataService {
  final List<MethodMaster> methods;
  final List<PouringStep> steps;
  MethodMaster? lastUpdatedMethod;
  final List<PouringStep> addedSteps = [];
  final List<PouringStep> updatedSteps = [];
  final List<String> deletedStepIds = [];

  _FakeDataService({required this.methods, this.steps = const []});

  @override
  Future<void> updateMethod(MethodMaster method) async {
    lastUpdatedMethod = method;
    final index = methods.indexWhere((m) => m.id == method.id);
    if (index >= 0) methods[index] = method;
  }

  @override
  Future<List<MethodMaster>> getMethods() async => methods;

  @override
  Future<void> addPouringStep(PouringStep step) async => addedSteps.add(step);

  @override
  Future<void> updatePouringStep(PouringStep step) async => updatedSteps.add(step);

  @override
  Future<void> deletePouringStep(String id) async => deletedStepIds.add(id);

  @override
  Future<List<PouringStep>> getPouringSteps() async => steps;

  @override
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];

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
  Future<void> addGrinder(GrinderMaster grinder) async {}
  @override
  Future<void> addMethod(MethodMaster method) async {}
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
  Future<void> updateBean(BeanMaster bean) async {}
  @override
  Future<void> updateCoffeeRecord(CoffeeRecord record) async {}
  @override
  Future<void> updateDripper(DripperMaster dripper) async {}
  @override
  Future<void> updateFilter(FilterMaster filter) async {}
  @override
  Future<void> updateGrinder(GrinderMaster grinder) async {}
}

void main() {
  testWidgets('BrewRecipeScreen: メソッド選択でPouring Stepsが読み込まれ、編集・保存ダイアログが動作する',
      (WidgetTester tester) async {
    final mockMethod = MethodMaster(
      id: 'M1',
      name: 'V60 Test',
      author: 'Test',
      baseBeanWeight: 15.0,
      baseWaterAmount: 250.0,
      description: 'Desc',
      recommendedEquipment: 'V60',
    );

    final mockSteps = [
      PouringStep(id: 'S1', methodId: 'M1', stepOrder: 1, duration: 30, waterAmount: 30, waterReference: 15.0, description: 'Bloom'),
      PouringStep(id: 'S2', methodId: 'M1', stepOrder: 2, duration: 30, waterAmount: 120, waterReference: 15.0, description: 'Pour'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          methodMasterProvider.overrideWith((ref) async => [mockMethod]),
          pouringStepsProvider.overrideWith((ref) async => mockSteps),
          coffeeRecordsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: BrewRecipeScreen(),
        ),
      ),
    );
    final listView = find.byType(ListView);

    // Initial load(トップ付近): メソッドのドロップダウンはまだスクロールなしで見える
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<MethodMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60 Test').last);
    await tester.pumpAndSettle();

    // 豆量に基準値がプリフィルされる
    expect(find.text('15.0'), findsOneWidget);

    // 下方向にのみスクロールして Pouring Steps セクションを表示
    await tester.drag(listView, const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('End Time'), findsOneWidget);
    expect(find.text('Total Water'), findsOneWidget);
    expect(find.text('Bloom'), findsOneWidget);
    expect(find.text('Pour'), findsOneWidget);

    // ステップ追加
    final addStepFinder = find.text('Add Step');
    expect(addStepFinder, findsOneWidget);
    await tester.tap(addStepFinder);
    await tester.pumpAndSettle();

    // 2件 + 追加1件 = 3行(削除アイコンで数える)
    expect(find.byIcon(Icons.delete), findsNWidgets(3));

    // 保存ダイアログ(さらに下にスクロールしてボタンを表示)
    await tester.drag(listView, const Offset(0, -400));
    await tester.pumpAndSettle();
    final saveBtnFinder = find.text('メソッドを保存');
    expect(saveBtnFinder, findsOneWidget);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('上書き'), findsOneWidget);
    expect(find.text('新規として保存'), findsOneWidget);
  });

  testWidgets('BrewRecipeScreen: 「上書き」で実際にDataService.updateMethod/updatePouringStepが呼ばれる',
      (WidgetTester tester) async {
    final method = MethodMaster(
      id: 'M1',
      name: 'V60 Test',
      author: 'Test',
      baseBeanWeight: 15.0,
      baseWaterAmount: 250.0,
      description: 'Desc',
      recommendedEquipment: 'V60',
    );
    final steps = [
      PouringStep(id: 'S1', methodId: 'M1', stepOrder: 1, duration: 30, waterAmount: 30, waterReference: 15.0, description: 'Bloom'),
    ];
    final fakeService = _FakeDataService(methods: [method], steps: steps);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          methodMasterProvider.overrideWith((ref) => fakeService.getMethods()),
          pouringStepsProvider.overrideWith((ref) => fakeService.getPouringSteps()),
          coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
        ],
        child: const MaterialApp(home: BrewRecipeScreen()),
      ),
    );
    final listView = find.byType(ListView);

    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<MethodMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60 Test').last);
    await tester.pumpAndSettle();

    // 豆量を変更(スケーリングが反映されることも合わせて確認)
    await tester.enterText(find.widgetWithText(TextField, '豆量'), '30');
    await tester.pumpAndSettle();

    await tester.drag(listView, const Offset(0, -1000));
    await tester.pumpAndSettle();

    final saveBtnFinder = find.text('メソッドを保存');
    expect(saveBtnFinder, findsOneWidget);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('上書き'));
    await tester.pumpAndSettle();

    expect(fakeService.lastUpdatedMethod?.id, 'M1');
    expect(fakeService.lastUpdatedMethod?.baseBeanWeight, 30.0);
    expect(fakeService.updatedSteps.any((s) => s.id == 'S1'), isTrue);
    // 豆量30g(元の基準15gの2倍)でスケーリングされた水量になっている
    final updatedStep = fakeService.updatedSteps.firstWhere((s) => s.id == 'S1');
    expect(updatedStep.waterAmount, closeTo(60.0, 0.1));
    expect(find.text('「V60 Test」を更新しました'), findsOneWidget);
  });

  testWidgets('BrewRecipeScreen: 「新規として保存」で021へ基準値・Pouring Stepsを引き継いで遷移する',
      (WidgetTester tester) async {
    final method = MethodMaster(
      id: 'M1',
      name: 'V60 Test',
      author: 'Test',
      baseBeanWeight: 15.0,
      baseWaterAmount: 250.0,
      description: 'Desc',
      recommendedEquipment: 'V60',
    );
    final steps = [
      PouringStep(id: 'S1', methodId: 'M1', stepOrder: 1, duration: 30, waterAmount: 30, waterReference: 15.0, description: 'Bloom'),
    ];
    final fakeService = _FakeDataService(methods: [method], steps: steps);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          methodMasterProvider.overrideWith((ref) => fakeService.getMethods()),
          pouringStepsProvider.overrideWith((ref) => fakeService.getPouringSteps()),
          coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
        ],
        child: const MaterialApp(home: BrewRecipeScreen()),
      ),
    );
    final listView = find.byType(ListView);

    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<MethodMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60 Test').last);
    await tester.pumpAndSettle();

    await tester.drag(listView, const Offset(0, -1000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('メソッドを保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新規として保存'));
    await tester.pumpAndSettle();

    // 021(MethodCreateScreen)へ遷移し、名前とPouring Stepsが引き継がれている
    expect(find.widgetWithText(TextField, 'V60 Test (コピー)'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Bloom'), findsOneWidget);

    // 元のメソッド(M1)自体は上書きされていない
    expect(fakeService.lastUpdatedMethod, isNull);
  });

  testWidgets('BrewRecipeScreen: メソッド未選択のままでも「抽出を終えて評価へ」で031へ進める(T3-15)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          methodMasterProvider.overrideWith((ref) async => <MethodMaster>[]),
          pouringStepsProvider.overrideWith((ref) async => <PouringStep>[]),
          coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
          beanMasterProvider.overrideWith((ref) async => <BeanMaster>[]),
          grinderMasterProvider.overrideWith((ref) async => <GrinderMaster>[]),
          dripperMasterProvider.overrideWith((ref) async => <DripperMaster>[]),
          filterMasterProvider.overrideWith((ref) async => <FilterMaster>[]),
        ],
        child: const MaterialApp(home: BrewRecipeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // メソッドを選択しないまま「抽出を終えて評価へ」をタップしても、
    // 以前のようにブロックされず031へ遷移する。
    await tester.tap(find.text('抽出を終えて評価へ (031)'));
    await tester.pumpAndSettle();

    expect(find.text('メソッドを選択してください'), findsNothing);
    expect(find.text('メソッド未選択'), findsOneWidget);
  });
}
