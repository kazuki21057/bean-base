import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:bean_base/screens/create/store_create_screen.dart';
import 'package:bean_base/services/ai_analysis_service.dart';
import 'package:bean_base/services/data_service.dart';

import 'helpers/fake_master_notifiers.dart';

/// T3-70(設計書`docs/store_master_design.md`§8)・T3-78: 新規購入店のAI自動取得。
/// マスタープランの終了条件どおり、①confidence:low・既存値ありは既定OFF、
/// ②candidatesが空でなければ必ず候補選択を挟み選ばなければ何も反映しない、
/// ③取得失敗時に手入力へ落とせること、の3点を検証する。
class _FakeAiAnalysisService extends AiAnalysisService {
  StoreInfoCandidate? Function(String storeName)? onFetch;
  Object? throwError;
  int callCount = 0;

  @override
  Future<StoreInfoCandidate> fetchStoreInfo({
    required String storeName,
    String? hintPrefecture,
    String? hintAddress,
    String? hintUrl,
    String? hintPhone,
    String? hintBusinessHours,
    String? hintClosedDays,
    String? hintOpenedYear,
    bool? hintHasOnlineShop,
    bool? hintHasPhysicalStore,
    bool? hintHasRoastery,
    String? hintBeanTendency,
    String? hintSnsUrl,
    required String apiKey,
    String? preferredModel,
  }) async {
    callCount++;
    if (throwError != null) throw throwError!;
    final result = onFetch?.call(storeName);
    if (result == null) throw Exception('unexpected call');
    return result;
  }
}

class _FakeDataService implements DataService {
  final List<StoreMaster> stores;
  StoreMaster? lastAdded;

  _FakeDataService(this.stores);

  @override
  Future<List<StoreMaster>> getStores() async => stores;
  @override
  Future<void> addStore(StoreMaster store) async {
    lastAdded = store;
    stores.add(store);
  }

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
  Future<List<CoffeeRecord>> getCoffeeRecords() async => [];
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
  late List<StoreMaster> stores;
  late _FakeDataService fakeService;
  late _FakeAiAnalysisService fakeAi;

  List<Override> overridesFor() => [
        dataServiceProvider.overrideWithValue(fakeService),
        storeMasterProvider.overrideWith(() => FakeStoreMasterNotifier(() => fakeService.getStores())),
        aiAnalysisServiceProvider.overrideWithValue(fakeAi),
      ];

  setUp(() {
    SharedPreferences.setMockInitialValues({'gemini_api_key': 'test-key'});
    stores = [];
    fakeService = _FakeDataService(stores);
    fakeAi = _FakeAiAnalysisService();
  });

  Future<void> pumpStoreCreateScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(),
        child: const MaterialApp(home: StoreCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('confidence:lowと既に入力済みの項目は確認ダイアログで既定OFFになる', (tester) async {
    await pumpStoreCreateScreen(tester);

    // 都道府県は事前入力(「既に値が入っている項目」の既定OFF条件を満たす)。
    await tester.enterText(find.widgetWithText(TextField, '都道府県'), '兵庫県');
    await tester.enterText(find.byType(TextField).first, 'テスト珈琲');

    fakeAi.onFetch = (name) => const StoreInfoCandidate(
          formalName: 'テスト珈琲株式会社',
          prefecture: '兵庫県',
          phone: '078-000-0000',
          confidence: {
            'formalName': 'high',
            'prefecture': 'high',
            'phone': 'low',
          },
          sourceUrls: ['https://example.com/test'],
        );

    await tester.tap(find.byTooltip('AIで自動入力'));
    await tester.pumpAndSettle();

    expect(find.text('AIによる取得結果の確認'), findsOneWidget);

    final formalNameTile = tester.widget<CheckboxListTile>(
      find.ancestor(of: find.text('正式名称  テスト珈琲株式会社'), matching: find.byType(CheckboxListTile)),
    );
    final prefectureTile = tester.widget<CheckboxListTile>(
      find.ancestor(of: find.text('都道府県  兵庫県'), matching: find.byType(CheckboxListTile)),
    );
    final phoneTile = tester.widget<CheckboxListTile>(
      find.ancestor(of: find.text('電話番号  078-000-0000'), matching: find.byType(CheckboxListTile)),
    );

    expect(formalNameTile.value, isTrue, reason: '確信度highかつ未入力項目は既定ON');
    expect(prefectureTile.value, isFalse, reason: '既に値が入っている項目は既定OFF');
    expect(phoneTile.value, isFalse, reason: '確信度lowは既定OFF');

    // 反映を押すとチェック済み(正式名称のみ)がフォームへ反映される。
    await tester.tap(find.text('反映'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'テスト珈琲株式会社'), findsOneWidget);
    // 都道府県は未チェックのため事前入力の「兵庫県」のまま(AI取得値で上書きされない)。
    expect(find.widgetWithText(TextField, '兵庫県'), findsOneWidget);
  });

  testWidgets('candidatesが返るとき候補選択が出て、選ばなければ何も反映されない', (tester) async {
    await pumpStoreCreateScreen(tester);
    await tester.enterText(find.byType(TextField).first, 'SORA');

    fakeAi.onFetch = (name) => const StoreInfoCandidate(
          candidates: ['SORA(神戸市北区有馬)', 'SORA(伊勢原市)'],
        );

    await tester.tap(find.byTooltip('AIで自動入力'));
    await tester.pumpAndSettle();

    expect(find.text('店舗の候補を確認してください'), findsOneWidget);
    expect(find.text('SORA(神戸市北区有馬)'), findsOneWidget);

    // キャンセルすると何も反映されない(確認ダイアログも出ない)。
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('キャンセル')));
    await tester.pumpAndSettle();

    expect(find.text('AIによる取得結果の確認'), findsNothing);
    expect(fakeAi.callCount, 1, reason: '候補選択で何も選ばなければ2回目の取得は行わない');
  });

  testWidgets('T3-78: 候補が1件でも必ず候補選択を挟み、選ぶと確定情報を再取得して確認ダイアログに進む', (tester) async {
    await pumpStoreCreateScreen(tester);
    await tester.enterText(find.byType(TextField).first, 'テスト珈琲');

    fakeAi.onFetch = (name) {
      if (!name.contains('(')) {
        return const StoreInfoCandidate(candidates: ['テスト珈琲(神戸市)']);
      }
      return const StoreInfoCandidate(
        formalName: 'テスト珈琲株式会社',
        confidence: {'formalName': 'high'},
      );
    };

    await tester.tap(find.byTooltip('AIで自動入力'));
    await tester.pumpAndSettle();

    // 候補が1件のみでも候補選択ダイアログを必ず経由する。
    expect(find.text('店舗の候補を確認してください'), findsOneWidget);
    await tester.tap(find.text('テスト珈琲(神戸市)'));
    await tester.pumpAndSettle();

    expect(fakeAi.callCount, 2, reason: '候補選択後に確定情報を再取得する');
    expect(find.text('AIによる取得結果の確認'), findsOneWidget);
  });

  testWidgets('取得失敗時はエラーSnackBarが出て手入力を継続できる', (tester) async {
    await pumpStoreCreateScreen(tester);
    await tester.enterText(find.byType(TextField).first, 'テスト珈琲');

    fakeAi.throwError = Exception('ネットワークエラー');

    await tester.tap(find.byTooltip('AIで自動入力'));
    await tester.pumpAndSettle();

    expect(find.textContaining('取得に失敗しました'), findsOneWidget);
    expect(find.textContaining('手動で入力してください'), findsOneWidget);

    // フォームは引き続き手入力できる。
    await tester.enterText(find.byType(TextField).first, 'テスト珈琲(手入力)');
    expect(find.widgetWithText(TextField, 'テスト珈琲(手入力)'), findsOneWidget);
  });

  group('StoreInfoCandidate.fromJson', () {
    test('項目ごとのvalue/confidenceを読み取る', () {
      final candidate = StoreInfoCandidate.fromJson({
        'formalName': {'value': 'テスト珈琲株式会社', 'confidence': 'high'},
        'hasOnlineShop': {'value': true, 'confidence': 'medium'},
        'phone': {'value': '', 'confidence': 'low'},
        'sourceUrls': ['https://example.com/a'],
      });

      expect(candidate.formalName, 'テスト珈琲株式会社');
      expect(candidate.confidence['formalName'], 'high');
      expect(candidate.hasOnlineShop, isTrue);
      expect(candidate.confidence['hasOnlineShop'], 'medium');
      // 空文字はnull扱い(確信できない項目として扱う)。
      expect(candidate.phone, isNull);
      expect(candidate.sourceUrls, ['https://example.com/a']);
    });

    test('candidatesを最大5件まで読み取る(T3-78: 1件のみでも列挙される)', () {
      final candidate = StoreInfoCandidate.fromJson({
        'candidates': ['SORA(神戸市北区有馬)', 'SORA(伊勢原市)'],
      });

      expect(candidate.candidates, ['SORA(神戸市北区有馬)', 'SORA(伊勢原市)']);
      // T3-78: candidatesの有無はisEmptyに影響しない(詳細項目のみで判定する)。
      expect(candidate.isEmpty, isTrue);
    });

    test('全項目null・空JSONならisEmptyがtrue', () {
      final candidate = StoreInfoCandidate.fromJson({});
      expect(candidate.isEmpty, isTrue);
    });
  });
}
