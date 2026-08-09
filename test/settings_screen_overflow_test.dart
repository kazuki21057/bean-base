import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/models/store_master.dart';
import 'package:bean_base/models/bean_purchase.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/settings_screen.dart';
import 'package:bean_base/services/data_service.dart';

import 'helpers/overflow_test_helper.dart';

/// 実データ通信を伴わない空のフェイク(`test/settings_screen_test.dart`の
/// `_FakeDataService`と同型)。overflow判定は表示内容ではなく描画サイズのみを
/// 見るため、全メソッドを空実装にして即時解決させる
/// (本番GAS通信への依存を無くしテストを決定的にする)。
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
  @override
  Future<void> addBeanPurchase(BeanPurchase purchase) async {}
  @override
  Future<void> updateBeanPurchase(BeanPurchase purchase) async {}
  @override
  Future<void> deleteBeanPurchase(String id) async {}
  @override
  Future<List<BeanMaster>> getBeans() async => [];
  @override
  Future<void> updateBean(BeanMaster bean) async {}
  @override
  Future<List<OriginMaster>> fetchOriginMasters() async => [];
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

/// T5-A8(`docs/android_release/検証強化設計.md` D-4節): 設定画面(090)への
/// overflow機械判定の適用例。エミュレータ不要で3つの実機解像度相当サイズを
/// widget testでpumpし、`RenderFlex overflowed`が出ないことを確認する。
///
/// `dataServiceProvider`/`originMasterProvider`は本番GAS通信に依存するため
/// フェイクへ差し替える(サンドボックス環境では通信がハングしうる、
/// `rules/verification.md`教訓L47参照。差し替えないと`pumpAndSettle`が
/// スピナー描画のまま`timed out`になることを実機で確認済み)。
void main() {
  setUp(() {
    // 未設定だと`SharedPreferences.getInstance()`が例外を投げ、
    // ロード中スピナー(無限アニメーション)から進まず`pumpAndSettle`が
    // タイムアウトする(実機で確認済み)。
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsScreen: 3つの実機解像度相当サイズでoverflowが発生しない', (tester) async {
    final fakeService = _FakeDataService();

    final detected = await pumpAndDetectOverflow(
      tester,
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(fakeService),
          originMasterProvider.overrideWith((ref) => fakeService.fetchOriginMasters()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expectNoOverflow(detected);
  });
}
