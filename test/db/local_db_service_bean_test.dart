// LocalDbService 束2(豆・購入店・購入履歴)のテスト。
//
// 正本: docs/local_db_schema_design.md §7.5.3(束2の完了条件)。
// 対象: bean_master(BeanMaster) / store_master(StoreMaster)
// / bean_purchases(BeanPurchase)。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/db/local_database.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/bean_purchase.dart';
import 'package:bean_base/models/store_master.dart';
import 'package:bean_base/services/local_db_service.dart';

void main() {
  group('LocalDbService 豆・購入店・購入履歴(束2)', () {
    late LocalDatabase db;
    late LocalDbService service;

    setUp(() {
      db = LocalDatabase(NativeDatabase.memory());
      service = LocalDbService(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('豆マスタ(bean_master)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addBean(
          BeanMaster(id: 'b1', name: '豆1', roastLevel: '', origin: ''),
        );
        await service.addBean(
          BeanMaster(id: 'b2', name: '豆2', roastLevel: '', origin: ''),
        );

        final list1 = await service.getBeans();
        expect(list1.map((b) => b.id).toList(), ['b1', 'b2']);

        await service.updateBean(
          BeanMaster(id: 'b1', name: '豆1改', roastLevel: '', origin: ''),
        );
        final list2 = await service.getBeans();
        expect(list2.firstWhere((b) => b.id == 'b1').name, '豆1改');

        await service.deleteBean('b1');
        final list3 = await service.getBeans();
        expect(list3.map((b) => b.id).toList(), ['b2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        expect(
          () => service.addBean(
            BeanMaster(id: '', name: 'x', roastLevel: '', origin: ''),
          ),
          throwsA(isA<LocalDbException>()),
        );
        await service.addBean(
          BeanMaster(id: 'b1', name: '豆1', roastLevel: '', origin: ''),
        );
        expect(
          () => service.addBean(
            BeanMaster(id: 'b1', name: '別', roastLevel: '', origin: ''),
          ),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updateBean(
            BeanMaster(id: 'none', name: 'x', roastLevel: '', origin: ''),
          ),
          throwsA(isA<LocalDbException>()),
        );
        await service.deleteBean('none');
        final list = await service.getBeans();
        expect(list.length, 1);
      });

      test('型往復(a): seekOptimalConditionsのbool?3値(null/true/false)が往復する', () async {
        await service.addBean(
          BeanMaster(
            id: 'b_null',
            name: '未回答',
            roastLevel: '',
            origin: '',
            seekOptimalConditions: null,
          ),
        );
        await service.addBean(
          BeanMaster(
            id: 'b_true',
            name: '探索する',
            roastLevel: '',
            origin: '',
            seekOptimalConditions: true,
          ),
        );
        await service.addBean(
          BeanMaster(
            id: 'b_false',
            name: '探索しない',
            roastLevel: '',
            origin: '',
            seekOptimalConditions: false,
          ),
        );

        final list = await service.getBeans();
        expect(
          list.firstWhere((b) => b.id == 'b_null').seekOptimalConditions,
          isNull,
        );
        expect(
          list.firstWhere((b) => b.id == 'b_true').seekOptimalConditions,
          isTrue,
        );
        expect(
          list.firstWhere((b) => b.id == 'b_false').seekOptimalConditions,
          isFalse,
        );
      });

      test('型往復(b): initialQuantityGramsのnullと0.0が区別される', () async {
        await service.addBean(
          BeanMaster(
            id: 'b_qty_null',
            name: '未設定',
            roastLevel: '',
            origin: '',
            initialQuantityGrams: null,
          ),
        );
        await service.addBean(
          BeanMaster(
            id: 'b_qty_zero',
            name: 'ゼロ',
            roastLevel: '',
            origin: '',
            initialQuantityGrams: 0.0,
          ),
        );

        final list = await service.getBeans();
        expect(
          list.firstWhere((b) => b.id == 'b_qty_null').initialQuantityGrams,
          isNull,
        );
        expect(
          list.firstWhere((b) => b.id == 'b_qty_zero').initialQuantityGrams,
          0.0,
        );
      });

      test('型往復(c): 数字だけの文字列IDが数値化されず文字列で戻る', () async {
        await service.addBean(
          BeanMaster(
            id: '1712345678901',
            name: 'タイムスタンプID',
            roastLevel: '',
            origin: '',
          ),
        );
        final list = await service.getBeans();
        expect(list.single.id, '1712345678901');
        expect(list.single.id, isA<String>());
      });
    });

    group('購入店マスタ(store_master)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addStore(StoreMaster(id: 's1', name: '店1'));
        await service.addStore(StoreMaster(id: 's2', name: '店2'));

        final list1 = await service.getStores();
        expect(list1.map((s) => s.id).toList(), ['s1', 's2']);

        await service.updateStore(StoreMaster(id: 's1', name: '店1改'));
        final list2 = await service.getStores();
        expect(list2.firstWhere((s) => s.id == 's1').name, '店1改');

        await service.deleteStore('s1');
        final list3 = await service.getStores();
        expect(list3.map((s) => s.id).toList(), ['s2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        expect(
          () => service.addStore(StoreMaster(id: '', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
        await service.addStore(StoreMaster(id: 's1', name: '店1'));
        expect(
          () => service.addStore(StoreMaster(id: 's1', name: '別')),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updateStore(StoreMaster(id: 'none', name: 'x')),
          throwsA(isA<LocalDbException>()),
        );
        await service.deleteStore('none');
        final list = await service.getStores();
        expect(list.length, 1);
      });

      test('bool列(hasOnlineShop等)が往復する', () async {
        await service.addStore(
          StoreMaster(
            id: 's1',
            name: '店1',
            hasOnlineShop: true,
            hasPhysicalStore: false,
            hasRoastery: true,
          ),
        );
        final list = await service.getStores();
        final s = list.single;
        expect(s.hasOnlineShop, isTrue);
        expect(s.hasPhysicalStore, isFalse);
        expect(s.hasRoastery, isTrue);
      });
    });

    group('購入履歴(bean_purchases)', () {
      test('追加→登録順で一覧→更新→削除', () async {
        await service.addBeanPurchase(
          BeanPurchase(id: 'p1', beanId: 'b1'),
        );
        await service.addBeanPurchase(
          BeanPurchase(id: 'p2', beanId: 'b1'),
        );

        final list1 = await service.getBeanPurchases();
        expect(list1.map((p) => p.id).toList(), ['p1', 'p2']);

        await service.updateBeanPurchase(
          BeanPurchase(id: 'p1', beanId: 'b1', memo: '改'),
        );
        final list2 = await service.getBeanPurchases();
        expect(list2.firstWhere((p) => p.id == 'p1').memo, '改');

        await service.deleteBeanPurchase('p1');
        final list3 = await service.getBeanPurchases();
        expect(list3.map((p) => p.id).toList(), ['p2']);
      });

      test('空ID追加/重複ID追加/不在ID更新はLocalDbException、不在ID削除は例外なし', () async {
        expect(
          () => service.addBeanPurchase(BeanPurchase(id: '', beanId: 'b1')),
          throwsA(isA<LocalDbException>()),
        );
        await service.addBeanPurchase(BeanPurchase(id: 'p1', beanId: 'b1'));
        expect(
          () => service.addBeanPurchase(BeanPurchase(id: 'p1', beanId: 'b2')),
          throwsA(isA<LocalDbException>()),
        );
        expect(
          () => service.updateBeanPurchase(
            BeanPurchase(id: 'none', beanId: 'b1'),
          ),
          throwsA(isA<LocalDbException>()),
        );
        await service.deleteBeanPurchase('none');
        final list = await service.getBeanPurchases();
        expect(list.length, 1);
      });

      test('quantityGramsのnullと0.0が区別される', () async {
        await service.addBeanPurchase(
          BeanPurchase(id: 'p_null', beanId: 'b1', quantityGrams: null),
        );
        await service.addBeanPurchase(
          BeanPurchase(id: 'p_zero', beanId: 'b1', quantityGrams: 0.0),
        );
        final list = await service.getBeanPurchases();
        expect(
          list.firstWhere((p) => p.id == 'p_null').quantityGrams,
          isNull,
        );
        expect(
          list.firstWhere((p) => p.id == 'p_zero').quantityGrams,
          0.0,
        );
      });

      test('DateTime往復がisAtSameMomentAsで一致する', () async {
        final purchasedAt = DateTime(2026, 8, 1, 10, 30);
        await service.addBeanPurchase(
          BeanPurchase(id: 'p1', beanId: 'b1', purchasedAt: purchasedAt),
        );
        final list = await service.getBeanPurchases();
        expect(
          list.single.purchasedAt!.isAtSameMomentAs(purchasedAt),
          isTrue,
        );
      });
    });
  });
}
