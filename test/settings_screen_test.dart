import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/providers/theme_provider.dart';
import 'package:bean_base/screens/settings_screen.dart';
import 'package:bean_base/services/data_service.dart';

/// T4-1f: データ移行セクションの検証用フェイク。
class _FakeDataService implements DataService {
  final List<BeanMaster> beans;
  final List<OriginMaster> origins;

  _FakeDataService(this.beans, this.origins);

  @override
  Future<List<BeanMaster>> getBeans() async => beans;
  @override
  Future<void> updateBean(BeanMaster bean) async {
    final index = beans.indexWhere((b) => b.id == bean.id);
    if (index >= 0) beans[index] = bean;
  }

  @override
  Future<List<OriginMaster>> fetchOriginMasters() async => origins;
  @override
  Future<void> saveOriginMaster(OriginMaster origin) async {}

  @override
  Future<void> addBean(BeanMaster bean) async {}
  @override
  Future<void> deleteBean(String id) async {}
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

/// Cycle 20 T2-7: 090(設定)の本実装(メインカラー・APIキー保存)の検証。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsScreen: メインカラーを選択するとSharedPreferencesに保存される', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // デフォルトはプリセットの1色目
    expect(container.read(mainColorProvider), mainColorPresets.first);

    // 2色目(黒板グリーン)の中心をタップ
    final circles = find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).shape == BoxShape.circle);
    expect(circles, findsNWidgets(mainColorPresets.length));
    await tester.tap(circles.at(1));
    await tester.pumpAndSettle();

    expect(container.read(mainColorProvider), mainColorPresets[1]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(kMainColorPrefsKey), mainColorPresets[1].toARGB32());
  });

  testWidgets('SettingsScreen: APIキーを入力して保存するとSharedPreferencesに保存される', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'test-api-key-123');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定を保存する'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gemini_api_key'), 'test-api-key-123');
    expect(find.text('設定を保存しました'), findsOneWidget);
  });

  testWidgets('SettingsScreen: データ移行を実行すると結果が表示され、未突合を手動確定できる', (tester) async {
    final origins = [
      OriginMaster(id: 'o_et', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
    ];
    final beans = [
      BeanMaster(id: '1', name: '豆A', roastLevel: '浅煎り', origin: 'エチオピア'),
      BeanMaster(id: '2', name: '豆B', roastLevel: '中煎り', origin: '謎の産地X'),
    ];
    final fakeService = _FakeDataService(beans, origins);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          originMasterProvider.overrideWith((ref) => fakeService.fetchOriginMasters()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('産地データ移行を実行'));
    await tester.pumpAndSettle();

    expect(find.text('2件'), findsOneWidget); // 対象の豆
    expect(beans[0].originId, 'o_et'); // 自動突合成功
    expect(find.text('謎の産地X'), findsOneWidget); // 未突合表示

    await tester.tap(find.byType(DropdownButtonFormField<OriginMaster>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('エチオピア').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('確定'));
    await tester.pumpAndSettle();

    expect(beans[1].originId, 'o_et');
    expect(find.text('謎の産地X'), findsNothing);
  });
}
