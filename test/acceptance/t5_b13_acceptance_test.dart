// T5-B13 全体の受け入れテスト(束4で完了)。
//
// 完了条件: docs/local_db_schema_design.md §7.5.3(束4)
// 1. `useLocalDb: true`相当のプロバイダオーバーライドで、5マスタ(豆/グラインダー/
//    ドリッパー/フィルター/メソッド)+抽出記録+購入履歴+購入店の全部で
//    追加→一覧→更新→削除が通る。
// 2. personal版(`useLocalDb: false`)が従来どおりSheetsServiceで動く
//    (=dataServiceProviderがSheetsServiceを返す)ことを確認する。
//
// 注: kPersonalEdition/kPublicEditionはuseLocalDb: falseのまま変えない方針
// (§7.5.1-2、切替はT5-B14完了後)。そのため「useLocalDb: true相当」の検証には
// テスト専用のAppEditionインスタンスを使う。
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/config/app_edition.dart';
import 'package:bean_base/db/local_database.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/bean_purchase.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/store_master.dart';
import 'package:bean_base/providers/local_db_provider.dart';
import 'package:bean_base/services/data_service.dart';
import 'package:bean_base/services/sheets_service.dart';

/// テスト専用: ローカルDBバックエンドを使う設定(kPublicEdition/kPersonalEditionは
/// 現状useLocalDb: falseのまま変えない方針のため、ここでだけtrueにする)。
const AppEdition _kLocalDbTestEdition = AppEdition(
  kind: Edition.public,
  enabledScreens: kAllAppScreens,
  useLocalDb: true,
  aiKeyMode: AiKeyMode.proxy,
  showAds: false,
  enableSubscription: false,
  showDebugScreens: false,
);

CoffeeRecord _record(String id) => CoffeeRecord(
      id: id,
      brewedAt: DateTime(2026, 1, 1),
      grinderId: '',
      dripperId: '',
      filterId: '',
      beanId: '',
      roastLevel: '',
      origin: '',
      beanWeight: 15.0,
      grindSize: '',
      methodId: '',
      taste: '',
      concentration: '',
      temperature: 92.0,
      bloomingWater: 30.0,
      totalWater: 240.0,
      bloomingTime: 30,
      totalTime: 180,
      scoreFragrance: 5,
      scoreAcidity: 5,
      scoreBitterness: 5,
      scoreSweetness: 5,
      scoreComplexity: 5,
      scoreFlavor: 5,
      scoreOverall: 5,
      comment: '',
      originId: '',
    );

void main() {
  group('受け入れ(T5-B13 全束完了)', () {
    late LocalDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = LocalDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appEditionProvider.overrideWithValue(_kLocalDbTestEdition),
          localDatabaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('useLocalDb: true でdataServiceProviderがLocalDbServiceを返す', () {
      final service = container.read(dataServiceProvider);
      expect(service, isNot(isA<SheetsService>()));
    });

    test('豆マスタ: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      await service.addBean(
        BeanMaster(id: 'bean1', name: '豆A', roastLevel: '中煎り', origin: ''),
      );
      final list1 = await service.getBeans();
      expect(list1.map((b) => b.id), contains('bean1'));

      await service.updateBean(
        BeanMaster(id: 'bean1', name: '豆A改', roastLevel: '中煎り', origin: ''),
      );
      final list2 = await service.getBeans();
      expect(list2.firstWhere((b) => b.id == 'bean1').name, '豆A改');

      await service.deleteBean('bean1');
      final list3 = await service.getBeans();
      expect(list3.any((b) => b.id == 'bean1'), isFalse);
    });

    test('グラインダーマスタ: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      await service.addGrinder(GrinderMaster(id: 'g1', name: 'グラインダーA'));
      final list1 = await service.getGrinders();
      expect(list1.map((g) => g.id), contains('g1'));

      await service.updateGrinder(GrinderMaster(id: 'g1', name: 'グラインダーA改'));
      final list2 = await service.getGrinders();
      expect(list2.firstWhere((g) => g.id == 'g1').name, 'グラインダーA改');

      await service.deleteGrinder('g1');
      final list3 = await service.getGrinders();
      expect(list3.any((g) => g.id == 'g1'), isFalse);
    });

    test('ドリッパーマスタ: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      await service.addDripper(DripperMaster(id: 'd1', name: 'ドリッパーA'));
      final list1 = await service.getDrippers();
      expect(list1.map((d) => d.id), contains('d1'));

      await service.updateDripper(DripperMaster(id: 'd1', name: 'ドリッパーA改'));
      final list2 = await service.getDrippers();
      expect(list2.firstWhere((d) => d.id == 'd1').name, 'ドリッパーA改');

      await service.deleteDripper('d1');
      final list3 = await service.getDrippers();
      expect(list3.any((d) => d.id == 'd1'), isFalse);
    });

    test('フィルターマスタ: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      await service.addFilter(FilterMaster(id: 'f1', name: 'フィルターA'));
      final list1 = await service.getFilters();
      expect(list1.map((f) => f.id), contains('f1'));

      await service.updateFilter(FilterMaster(id: 'f1', name: 'フィルターA改'));
      final list2 = await service.getFilters();
      expect(list2.firstWhere((f) => f.id == 'f1').name, 'フィルターA改');

      await service.deleteFilter('f1');
      final list3 = await service.getFilters();
      expect(list3.any((f) => f.id == 'f1'), isFalse);
    });

    test('メソッドマスタ: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      MethodMaster method(String id, String name) => MethodMaster(
            id: id,
            name: name,
            author: '',
            baseBeanWeight: 15.0,
            baseWaterAmount: 240.0,
            description: '',
            recommendedEquipment: '',
          );
      await service.addMethod(method('m1', 'メソッドA'));
      final list1 = await service.getMethods();
      expect(list1.map((m) => m.id), contains('m1'));

      await service.updateMethod(method('m1', 'メソッドA改'));
      final list2 = await service.getMethods();
      expect(list2.firstWhere((m) => m.id == 'm1').name, 'メソッドA改');

      await service.deleteMethod('m1');
      final list3 = await service.getMethods();
      expect(list3.any((m) => m.id == 'm1'), isFalse);
    });

    test('抽出記録: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      await service.addCoffeeRecord(_record('c1'));
      final list1 = await service.getCoffeeRecords();
      expect(list1.map((r) => r.id), contains('c1'));

      final updated = _record('c1').copyWith(comment: '改');
      await service.updateCoffeeRecord(updated);
      final list2 = await service.getCoffeeRecords();
      expect(list2.firstWhere((r) => r.id == 'c1').comment, '改');

      await service.deleteCoffeeRecord('c1');
      final list3 = await service.getCoffeeRecords();
      expect(list3.any((r) => r.id == 'c1'), isFalse);
    });

    test('購入店: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      await service.addStore(StoreMaster(id: 'st1', name: '店A'));
      final list1 = await service.getStores();
      expect(list1.map((s) => s.id), contains('st1'));

      await service.updateStore(StoreMaster(id: 'st1', name: '店A改'));
      final list2 = await service.getStores();
      expect(list2.firstWhere((s) => s.id == 'st1').name, '店A改');

      await service.deleteStore('st1');
      final list3 = await service.getStores();
      expect(list3.any((s) => s.id == 'st1'), isFalse);
    });

    test('購入履歴: 追加→一覧→更新→削除', () async {
      final service = container.read(dataServiceProvider);
      await service.addBeanPurchase(BeanPurchase(id: 'p1', beanId: 'bean1'));
      final list1 = await service.getBeanPurchases();
      expect(list1.map((p) => p.id), contains('p1'));

      await service.updateBeanPurchase(
        BeanPurchase(id: 'p1', beanId: 'bean1', memo: '改'),
      );
      final list2 = await service.getBeanPurchases();
      expect(list2.firstWhere((p) => p.id == 'p1').memo, '改');

      await service.deleteBeanPurchase('p1');
      final list3 = await service.getBeanPurchases();
      expect(list3.any((p) => p.id == 'p1'), isFalse);
    });
  });

  group('受け入れ: personal版(useLocalDb: false)は従来どおりSheetsServiceで動く', () {
    test('appEditionProviderが既定(kPersonalEdition)ならSheetsServiceを返す', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appEditionProvider).useLocalDb, isFalse);
      final service = container.read(dataServiceProvider);
      expect(service, isA<SheetsService>());
    });

    test('kPublicEditionをoverrideしてもuseLocalDb: falseならSheetsServiceを返す', () {
      final container = ProviderContainer(
        overrides: [
          appEditionProvider.overrideWithValue(kPublicEdition),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appEditionProvider).useLocalDb, isFalse);
      final service = container.read(dataServiceProvider);
      expect(service, isA<SheetsService>());
    });
  });
}
