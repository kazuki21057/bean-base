// T5-B15 受け入れテスト: エクスポート/インポート(JSON/CSV)。
//
// 完了条件: docs/local_db_schema_design.md §6.1。
// 「エクスポート→アプリのデータ全消去→インポートで完全復元できる」ことを
// 全12テーブルについて検証する。
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';
import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/bean_purchase.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/models/store_master.dart';
import 'package:bean_base/services/import_export_service.dart';
import 'package:bean_base/services/local_db_service.dart';

void main() {
  group('受け入れ(T5-B15): エクスポート→全消去→インポートで完全復元', () {
    late LocalDatabase db;
    late LocalDbService dbService;
    late ImportExportService ie;

    setUp(() async {
      db = LocalDatabase(NativeDatabase.memory());
      dbService = LocalDbService(db);
      ie = ImportExportService(db);

      // 全12テーブルへ代表的なデータを1件以上投入する
      // (origin_masterはLocalDatabase.onCreateの初期投入15件も含む)。
      await dbService.addGrinder(GrinderMaster(
        id: 'g1',
        name: 'グラインダーA',
        grindRange: '1-40',
        description: '説明',
        imageUrl: 'http://example.com/g.png',
      ));
      await dbService.addDripper(DripperMaster(
        id: 'd1',
        name: 'ドリッパーA',
        material: '陶器',
        shape: '円錐',
        imageUrl: 'http://example.com/d.png',
      ));
      await dbService.addFilter(FilterMaster(
        id: 'f1',
        name: 'フィルターA',
        material: '紙',
        size: '02',
        imageUrl: 'http://example.com/f.png',
      ));
      await dbService.saveOriginMaster(OriginMaster(
        id: 'origin_custom',
        countryCode: 'JP',
        nameJa: '日本',
        nameEn: 'Japan',
        region: 'アジア・太平洋',
      ));
      await dbService.addStore(StoreMaster(
        id: 'store1',
        name: '店A',
        formalName: '株式会社店A',
        url: 'http://a.example.com',
        prefecture: '兵庫県',
        address: '住所',
        hasOnlineShop: true,
        hasPhysicalStore: true,
        hasRoastery: false,
        beanTendency: '浅煎り中心',
        memo: 'メモ',
        imageUrl: 'http://example.com/s.png',
        snsUrl: 'http://sns.example.com',
        businessHours: '9-18',
        closedDays: '月曜',
        phone: '000-0000',
        openedYear: '2020',
        sourceUrl: 'http://source.example.com',
        infoFetchedAt: DateTime(2026, 1, 5),
      ));
      await dbService.addBean(BeanMaster(
        id: 'bean1',
        name: '豆A',
        roastLevel: '中煎り',
        origin: 'エチオピア',
        store: '店A',
        type: 'ウォッシュド',
        imageUrl: 'http://example.com/b.png',
        beanImageUrl: 'http://example.com/bb.png',
        infoImageUrl: 'http://example.com/bi.png',
        purchaseDate: DateTime(2026, 1, 1),
        firstUseDate: DateTime(2026, 1, 2),
        lastUseDate: DateTime(2026, 2, 1),
        isInStock: true,
        initialQuantityGrams: 200.0,
        originId: 'origin_custom',
        roastDate: DateTime(2025, 12, 25),
        stockBaselineGrams: 150.0,
        stockBaselineAt: DateTime(2026, 1, 10),
        storageLocation: '職場',
        seekOptimalConditions: true,
        storeId: 'store1',
      ));
      await dbService.addBeanPurchase(BeanPurchase(
        id: 'purchase1',
        beanId: 'bean1',
        purchasedAt: DateTime(2026, 1, 1),
        roastDate: DateTime(2025, 12, 25),
        quantityGrams: 200.0,
        storeId: 'store1',
        storeName: '店A',
        memo: '購入メモ',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      ));
      await dbService.addMethod(MethodMaster(
        id: 'method1',
        name: 'メソッドA',
        author: '発案者A',
        baseBeanWeight: 15.0,
        baseWaterAmount: 240.0,
        temperature: 92.0,
        grindSize: '中細',
        description: '説明',
        recommendedEquipment: '推奨機器',
        sourceUrl: 'http://method.example.com',
        recommendedRoastLevel: '中煎り',
        recommendedRoastMin: '浅煎り',
        recommendedRoastMax: '深煎り',
      ));
      await dbService.addPouringStep(PouringStep(
        id: 'step1',
        methodId: 'method1',
        stepOrder: 1,
        duration: 30,
        waterAmount: 40.0,
        waterReference: 40.0,
        waterRatio: 1.0,
        description: '注意事項',
      ));
      await dbService.addCoffeeRecord(CoffeeRecord(
        id: 'record1',
        brewedAt: DateTime(2026, 1, 1, 8, 0),
        grinderId: 'g1',
        dripperId: 'd1',
        filterId: 'f1',
        beanId: 'bean1',
        roastLevel: '中煎り',
        origin: 'エチオピア',
        beanWeight: 15.0,
        grindSize: '中細',
        methodId: 'method1',
        taste: 'バランス',
        concentration: '普通',
        temperature: 92.0,
        bloomingWater: 30.0,
        totalWater: 240.0,
        bloomingTime: 30,
        totalTime: 180,
        scoreFragrance: 8,
        scoreAcidity: 6,
        scoreBitterness: 5,
        scoreSweetness: 7,
        scoreComplexity: 6,
        scoreFlavor: 7,
        scoreOverall: 7,
        comment: 'コメント',
        grinderImageUrl: 'http://example.com/gi.png',
        dripperImageUrl: 'http://example.com/di.png',
        filterImageUrl: 'http://example.com/fi.png',
        beanImageUrl: 'http://example.com/bimg.png',
        originId: 'origin_custom',
      ));
      await dbService.saveAnalysisSnapshot(AnalysisSnapshot(
        id: 'snap1',
        createdAt: DateTime(2026, 1, 15, 12, 0),
        type: 'pca',
        dataCount: 10,
        payloadJson: '{"a":1}',
      ));
      await dbService.saveRecipeSuggestion(RecipeSuggestion(
        id: 'sugg1',
        createdAt: DateTime(2026, 1, 16, 9, 0),
        beanId: 'bean1',
        originId: 'origin_custom',
        roastLevel: '中煎り',
        methodId: 'method1',
        temperature: 92.0,
        brewRatio: 16.0,
        totalTimeSec: 180,
        rationale: '根拠',
        accepted: '採用',
        resultRecordId: 'record1',
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('全12テーブルが完全復元される', () async {
      final jsonStr = await ie.exportToJson();

      // アプリのデータを全消去する(全12テーブル)。
      await db.delete(db.coffeeDataTable).go();
      await db.delete(db.beanMasterTable).go();
      await db.delete(db.methodsMasterTable).go();
      await db.delete(db.pouringStepsTable).go();
      await db.delete(db.millMasterTable).go();
      await db.delete(db.dripperMasterTable).go();
      await db.delete(db.filterMasterTable).go();
      await db.delete(db.originMasterTable).go();
      await db.delete(db.storeMasterTable).go();
      await db.delete(db.beanPurchasesTable).go();
      await db.delete(db.analysisHistoryTable).go();
      await db.delete(db.recipeSuggestionsTable).go();

      expect(await dbService.getBeans(), isEmpty);
      expect(await dbService.fetchOriginMasters(), isEmpty);
      expect(await dbService.getCoffeeRecords(), isEmpty);

      await ie.importFromJson(jsonStr);

      final grinders = await dbService.getGrinders();
      expect(grinders.length, 1);
      expect(grinders.first.id, 'g1');
      expect(grinders.first.name, 'グラインダーA');
      expect(grinders.first.grindRange, '1-40');

      final drippers = await dbService.getDrippers();
      expect(drippers.single.id, 'd1');
      expect(drippers.single.material, '陶器');

      final filters = await dbService.getFilters();
      expect(filters.single.id, 'f1');
      expect(filters.single.size, '02');

      final origins = await dbService.fetchOriginMasters();
      expect(origins.any((o) => o.id == 'origin_custom' && o.nameJa == '日本'),
          isTrue);

      final stores = await dbService.getStores();
      expect(stores.single.id, 'store1');
      expect(stores.single.hasOnlineShop, isTrue);
      expect(stores.single.hasRoastery, isFalse);
      expect(stores.single.infoFetchedAt, DateTime(2026, 1, 5));

      final beans = await dbService.getBeans();
      expect(beans.single.id, 'bean1');
      expect(beans.single.name, '豆A');
      expect(beans.single.isInStock, isTrue);
      expect(beans.single.originId, 'origin_custom');
      expect(beans.single.storeId, 'store1');
      expect(beans.single.purchaseDate, DateTime(2026, 1, 1));
      expect(beans.single.initialQuantityGrams, 200.0);
      expect(beans.single.seekOptimalConditions, isTrue);

      final purchases = await dbService.getBeanPurchases();
      expect(purchases.single.id, 'purchase1');
      expect(purchases.single.beanId, 'bean1');
      expect(purchases.single.quantityGrams, 200.0);

      final methods = await dbService.getMethods();
      expect(methods.single.id, 'method1');
      expect(methods.single.baseBeanWeight, 15.0);
      expect(methods.single.recommendedRoastMax, '深煎り');

      final steps = await dbService.getPouringSteps();
      expect(steps.single.id, 'step1');
      expect(steps.single.methodId, 'method1');
      expect(steps.single.waterRatio, 1.0);

      final records = await dbService.getCoffeeRecords();
      expect(records.single.id, 'record1');
      expect(records.single.beanId, 'bean1');
      expect(records.single.methodId, 'method1');
      expect(records.single.originId, 'origin_custom');
      expect(records.single.brewedAt, DateTime(2026, 1, 1, 8, 0));
      expect(records.single.scoreOverall, 7);

      final snapshots = await dbService.fetchAnalysisSnapshots();
      expect(snapshots.single.id, 'snap1');
      expect(snapshots.single.dataCount, 10);
      expect(snapshots.single.payloadJson, '{"a":1}');

      final suggestions = await dbService.fetchRecipeSuggestions();
      expect(suggestions.single.id, 'sugg1');
      expect(suggestions.single.resultRecordId, 'record1');
      expect(suggestions.single.brewRatio, 16.0);
    });

    test('CSVエクスポートは1テーブル1ファイル・ヘッダーが日本語列名', () async {
      final csvMap = await ie.exportToCsv();
      expect(csvMap.keys.length, 12);
      expect(csvMap['bean_master'], contains('豆ID'));
      expect(csvMap['bean_master'], contains('豆A'));
      final lines = csvMap['bean_master']!.trim().split('\n');
      // ヘッダー行 + データ1行。
      expect(lines.length, 2);
    });
  });

  group('受け入れ(T5-B15): seekOptimalConditionsのNULL⇔空文字変換', () {
    test('nullはエクスポートで空文字になり、インポートでnullに戻る', () async {
      final db = LocalDatabase(NativeDatabase.memory());
      final dbService = LocalDbService(db);
      final ie = ImportExportService(db);
      addTearDown(() => db.close());

      await dbService.addBean(BeanMaster(
        id: 'bean_null',
        name: '豆B',
        roastLevel: '中煎り',
        origin: 'ブラジル',
        seekOptimalConditions: null,
      ));

      final jsonStr = await ie.exportToJson();
      // JSON nullではなく空文字で出力されること(設計書 local_db_schema_design.md:189)。
      expect(jsonStr, contains('"最適条件探索": ""'));

      await db.delete(db.beanMasterTable).go();
      await ie.importFromJson(jsonStr);

      final beans = await dbService.getBeans();
      expect(beans.single.seekOptimalConditions, isNull);
    });
  });

  group('normalizeExternalId', () {
    test('nullは空文字になる', () {
      expect(normalizeExternalId(null), '');
    });

    test('整数値のdoubleは.0を取り除く', () {
      expect(normalizeExternalId(123.0), '123');
    });

    test('小数はそのまま文字列化する', () {
      expect(normalizeExternalId(1.5), '1.5');
    });

    test('文字列はtrimする', () {
      expect(normalizeExternalId('  42  '), '42');
    });
  });

  group('受け入れ: schemaVersionチェック', () {
    test('自分より新しいschemaVersionのファイルは日本語エラーで拒否される', () async {
      final db = LocalDatabase(NativeDatabase.memory());
      final ie = ImportExportService(db);
      final future = ie.importFromJson(jsonEncode({
        'formatVersion': 1,
        'schemaVersion': db.schemaVersion + 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': <String, dynamic>{},
      }));
      await expectLater(future, throwsA(isA<LocalDbException>()));
      await db.close();
    });

    test('壊れたJSONは日本語エラーになる', () async {
      final db = LocalDatabase(NativeDatabase.memory());
      final ie = ImportExportService(db);
      await expectLater(
        ie.importFromJson('{ 壊れたJSON'),
        throwsA(isA<LocalDbException>()),
      );
      await db.close();
    });
  });
}
