import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:bean_base/screens/brew_recipe_screen.dart';
import 'package:bean_base/screens/create/brew_evaluation_screen.dart';
import 'package:bean_base/services/data_service.dart';
import 'package:bean_base/widgets/dashboard/recipe_suggestion_card.dart';

import 'helpers/fake_master_notifiers.dart';

/// T4-5b(設計書§7.4): F3レシピ提案カードの検証。
/// 在庫豆(残量>0)+同グループの過去記録があると提案カードが出ること、
/// [今回はパス]でaccepted='no'が保存されカードが消えること、対象が無いときの
/// 案内文、推奨焙煎度(§7.4後半)の表示・一致バッジを確認する。
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
  final List<RecipeSuggestion> saved = [];
  final List<RecipeSuggestion> updated = [];

  @override
  Future<void> saveRecipeSuggestion(RecipeSuggestion suggestion) async {
    saved.add(suggestion);
  }

  @override
  Future<void> updateRecipeSuggestion(RecipeSuggestion suggestion) async {
    updated.add(suggestion);
  }

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
}

// T3-48: 提案されるメソッドは対象豆の焙煎度に`recommendedRoastLevel`が一致する
// ものに限られる。テストの既定豆はすべて'浅煎り'なので、既定メソッド'm'・
// 既定ミル'g1'(挽き目調整段階40)を一致するものとして用意する。
final _defaultMethod = MethodMaster(
  id: 'm',
  name: 'メソッドA',
  author: '',
  baseBeanWeight: 15,
  baseWaterAmount: 225,
  description: '',
  recommendedEquipment: '',
  recommendedRoastLevel: '浅煎り',
);
final _defaultGrinder = GrinderMaster(id: 'g1', name: 'ミル1', grindRange: '40');

CoffeeRecord _record(
  String id, {
  required String beanId,
  required String originId,
  required String roastLevel,
  required int score,
  double temperature = 92,
  double beanWeight = 15,
  double totalWater = 225,
  int totalTime = 150,
  String methodId = 'm',
  String grinderId = 'g1',
  String grindSize = '20',
}) {
  return CoffeeRecord(
    id: id,
    brewedAt: DateTime(2026, 7, 20),
    beanId: beanId,
    methodId: methodId,
    beanWeight: beanWeight,
    totalWater: totalWater,
    totalTime: totalTime,
    scoreOverall: score,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    taste: '',
    comment: '',
    grindSize: grindSize,
    temperature: temperature,
    dripperId: '',
    filterId: '',
    grinderId: grinderId,
    roastLevel: roastLevel,
    origin: '',
    originId: originId,
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<BeanMaster> beans,
  required List<CoffeeRecord> records,
  List<OriginMaster> origins = const [],
  List<RecipeSuggestion> history = const [],
  DataService? service,
  List<MethodMaster>? methods,
  List<GrinderMaster>? grinders,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataServiceProvider.overrideWithValue(service ?? _FakeDataService()),
        beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => beans)),
        coffeeRecordsProvider.overrideWith((ref) async => records),
        originMasterProvider.overrideWith((ref) async => origins),
        recipeSuggestionsProvider.overrideWith((ref) async => history),
        methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => methods ?? [_defaultMethod])),
        grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => grinders ?? [_defaultGrinder])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: const RecipeSuggestionCard()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RecipeSuggestionCard (T4-5b)', () {
    // 在庫豆(初期200g・使用30g→残量>0)+同グループの過去記録2件。
    final bean = BeanMaster(
      id: 'b1',
      name: 'エチオピア ゲイシャ',
      roastLevel: '浅煎り',
      origin: 'エチオピア',
      originId: 'origin_1',
      initialQuantityGrams: 200,
      isInStock: true,
    );
    final records = [
      _record('r1', beanId: 'b1', originId: 'origin_1', roastLevel: '浅煎り', score: 8, temperature: 90),
      _record('r2', beanId: 'b1', originId: 'origin_1', roastLevel: '浅煎り', score: 9, temperature: 93),
    ];

    testWidgets('提案可能な在庫豆があると湯温/比率/時間つきのカードを表示する', (tester) async {
      await _pump(tester, beans: [bean], records: records);

      expect(find.text('今日のおすすめレシピ'), findsOneWidget);
      expect(find.text('エチオピア ゲイシャ'), findsOneWidget);
      expect(find.text('メソッドAで淹れてみませんか?'), findsOneWidget);
      // 最高スコア(9点、r2)の条件が提案される: 93℃ / 1:15 / 2:30。
      expect(find.text('93℃'), findsOneWidget);
      expect(find.text('湯:豆 1:15.0'), findsOneWidget);
      expect(find.text('2:30'), findsOneWidget);
      expect(find.text('この条件で淹れる'), findsOneWidget);
      expect(find.text('今回はパス'), findsOneWidget);
    });

    testWidgets('[この条件で淹れる]で030(抽出レシピ画面)へ遷移し、湯温・比率・時間を引き継ぎバッジで表示する(T3-49)', (tester) async {
      await _pump(tester, beans: [bean], records: records);

      await tester.tap(find.text('この条件で淹れる'));
      await tester.pumpAndSettle();

      // 031へ直行せず030に遷移し、030のUIには表示欄が無い項目を
      // 「引き継いだ条件」バッジで確認できる(バッジは画面上部にあるためスクロール不要)。
      expect(find.byType(BrewRecipeScreen), findsOneWidget);
      expect(find.text('おすすめレシピから引き継いだ条件'), findsOneWidget);
      expect(find.text('93℃'), findsOneWidget);
      expect(find.text('湯:豆 1:15.0'), findsOneWidget);
      expect(find.text('2:30'), findsOneWidget);

      // 030はListView(遅延ビルド)のため、下部の「抽出を終えて評価へ」ボタンは
      // スクロールしないとビルドされない(brew_recipe_test.dartと同じ作法)。
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(find.text('抽出を終えて評価へ (031)'), findsOneWidget);
    });

    testWidgets('030から評価へ進むと031で湯温がプリフィルされ、引き継ぎ提案が結果記録に紐付く(T3-49)', (tester) async {
      final service = _FakeDataService();
      await _pump(tester, beans: [bean], records: records, service: service);

      await tester.tap(find.text('この条件で淹れる'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('抽出を終えて評価へ (031)'));
      await tester.pumpAndSettle();

      expect(find.byType(BrewEvaluationScreen), findsOneWidget);
      // T4-5b由来のロジック: F3提案の湯温(93℃)が031の湯温欄にプリフィルされる。
      expect(find.text('93'), findsOneWidget);

      await tester.tap(find.text('評価を登録する'));
      await tester.pumpAndSettle();

      // 採用済み提案(accepted='yes')に結果記録のIDが書き戻される。
      expect(service.updated.length, 1);
      expect(service.updated.single.accepted, 'yes');
      expect(service.updated.single.resultRecordId, isNotEmpty);
    });

    testWidgets('[今回はパス]でaccepted=noが保存され、カードが消える', (tester) async {
      final service = _FakeDataService();
      await _pump(tester, beans: [bean], records: records, service: service);

      expect(find.text('エチオピア ゲイシャ'), findsOneWidget);
      await tester.tap(find.text('今回はパス'));
      await tester.pumpAndSettle();

      expect(service.saved.length, 1);
      expect(service.saved.single.accepted, 'no');
      expect(service.saved.single.beanId, 'b1');
      // カードは非表示になり、対象が無い案内文へ変わる。
      expect(find.text('エチオピア ゲイシャ'), findsNothing);
      expect(find.textContaining('おすすめできる在庫豆がありません'), findsOneWidget);
    });

    testWidgets('在庫豆に過去記録が無い場合は案内文を表示する', (tester) async {
      await _pump(tester, beans: [bean], records: const []);

      expect(find.textContaining('おすすめできる在庫豆がありません'), findsOneWidget);
      expect(find.text('エチオピア ゲイシャ'), findsNothing);
    });

    testWidgets('好みプロファイルに高評価グループがあると推奨焙煎度と一致バッジを表示する', (tester) async {
      // 同産地×浅煎りをn>=3・高評価で構成 → 推奨焙煎度=浅煎り。
      // 豆自身も浅煎りなので「おすすめ焙煎度と一致」バッジが出る。
      final manyRecords = [
        for (var i = 0; i < 4; i++)
          _record('e$i', beanId: 'b1', originId: 'origin_1', roastLevel: '浅煎り', score: 9),
      ];
      // 豆・記録の双方がoriginId経由で同じ産地名(エチオピア)に解決されるよう
      // OriginMasterを渡す(PreferenceServiceのグループ化と整合させる)。
      final origins = [
        OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'Africa'),
      ];
      await _pump(tester, beans: [bean], records: manyRecords, origins: origins);

      // T3-42: 焙煎度8段階統一により、代表ラベルは新8段階の同一順序値(2.0)の
      // 代表名'シナモン'になる(おすすめ焙煎度との一致判定は順序値ベースのため不変)。
      expect(find.textContaining('この産地はシナモンが高評価です'), findsOneWidget);
      expect(find.text('おすすめ焙煎度と一致'), findsOneWidget);
    });

    // --- T4-6c: GP接続 ---

    final stockBean = BeanMaster(
      id: 'b1',
      name: 'エチオピア ゲイシャ',
      roastLevel: '浅煎り',
      origin: 'エチオピア',
      originId: 'origin_1',
      initialQuantityGrams: 500,
      isInStock: true,
    );
    // origin_1×浅煎りで12件 → n_eff=12 ≥ 10 でGP経路に入る。
    final gpRecords = () {
      final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0];
      final waters = [225.0, 240.0, 210.0, 225.0, 255.0, 210.0];
      final times = [150, 165, 135, 180, 150, 195];
      final scores = [7, 8, 6, 9, 7, 8];
      return [
        for (var i = 0; i < 12; i++)
          _record('g$i',
              beanId: 'b1',
              originId: 'origin_1',
              roastLevel: '浅煎り',
              score: scores[i % 6],
              temperature: temps[i % 6],
              totalWater: waters[i % 6],
              totalTime: times[i % 6]),
      ];
    }();

    testWidgets('n_eff≥10の在庫豆はGP予測スコア付きのカードを表示する', (tester) async {
      await _pump(tester, beans: [stockBean], records: gpRecords);

      expect(find.text('エチオピア ゲイシャ'), findsOneWidget);
      expect(find.textContaining('予測スコア'), findsOneWidget);
      // 通常はgp_meanなので「実験的な提案です」バッジは出ない。
      expect(find.text('実験的な提案です'), findsNothing);
    });

    testWidgets('GP提案履歴が6件たまると7件目はEI提案(実験的な提案です)になる', (tester) async {
      final history = [
        for (var i = 0; i < 6; i++)
          RecipeSuggestion(
            id: 'h$i', createdAt: DateTime(2026, 7, 1), beanId: 'b1', originId: 'origin_1',
            roastLevel: '浅煎り', methodId: 'm', temperature: 90, brewRatio: 15, totalTimeSec: 150,
            rationale: 'gp_mean', accepted: '', resultRecordId: ''),
      ];
      await _pump(tester, beans: [stockBean], records: gpRecords, history: history);

      expect(find.text('実験的な提案です'), findsOneWidget);
      expect(find.textContaining('予測スコア'), findsOneWidget);
    });

    testWidgets('T5-A104 Major#3: 抽出記録の取得に失敗するとエラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataServiceProvider.overrideWithValue(_FakeDataService()),
            beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [bean])),
            coffeeRecordsProvider.overrideWith((ref) async => throw Exception('通信エラー')),
            originMasterProvider.overrideWith((ref) async => const []),
            recipeSuggestionsProvider.overrideWith((ref) async => const []),
            methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [_defaultMethod])),
            grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => [_defaultGrinder])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: const RecipeSuggestionCard()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 通信失敗時も無言でデータ0件扱いにせず、ユーザーにエラーを伝える。
      expect(find.textContaining('関連データの読み込みに失敗しました'), findsOneWidget);
    });
  });
}
