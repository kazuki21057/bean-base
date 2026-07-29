import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/bean_purchase.dart';

/// T3-62(docs/bean_purchase_design.md§2): BeanPurchaseのシリアライズ検証。
void main() {
  test('fromJson/toJsonが往復する', () {
    final purchase = BeanPurchase(
      id: 'bp_1784633291938',
      beanId: '1784633000000',
      purchasedAt: DateTime(2026, 7, 29, 12, 0),
      roastDate: DateTime(2026, 7, 25),
      quantityGrams: 200.0,
      storeId: 'store_navy',
      storeName: 'Navy',
      memo: '定期便',
      createdAt: DateTime(2026, 7, 29, 12, 1),
    );

    final roundTripped = BeanPurchase.fromJson(purchase.toJson());

    expect(roundTripped.id, purchase.id);
    expect(roundTripped.beanId, purchase.beanId);
    expect(roundTripped.purchasedAt, purchase.purchasedAt);
    expect(roundTripped.roastDate, purchase.roastDate);
    expect(roundTripped.quantityGrams, purchase.quantityGrams);
    expect(roundTripped.storeId, purchase.storeId);
    expect(roundTripped.storeName, purchase.storeName);
    expect(roundTripped.memo, purchase.memo);
    expect(roundTripped.createdAt, purchase.createdAt);
  });

  test('数字のみのbeanIdがStringにキャストされる(Sheetsが数値セルとして返す既知の挙動)', () {
    final purchase = BeanPurchase.fromJson({
      'id': 'bp_1',
      'beanId': 1784633000000,
    });
    expect(purchase.beanId, '1784633000000');
    expect(purchase.beanId, isA<String>());
  });

  test('数字のみのidもStringにキャストされる', () {
    final purchase = BeanPurchase.fromJson({'id': 1784633291938, 'beanId': 'b1'});
    expect(purchase.id, '1784633291938');
    expect(purchase.id, isA<String>());
  });

  test('空JSONでもクラッシュせず既定値になる', () {
    final purchase = BeanPurchase.fromJson({});
    expect(purchase.id, '');
    expect(purchase.beanId, '');
    expect(purchase.purchasedAt, isNull);
    expect(purchase.roastDate, isNull);
    expect(purchase.quantityGrams, isNull);
    expect(purchase.storeId, '');
    expect(purchase.storeName, '');
    expect(purchase.memo, '');
    expect(purchase.createdAt, isNull);
  });

  test('Sheetsの区切り表記(スラッシュ・スペース)の日付を解釈する', () {
    final purchase = BeanPurchase.fromJson({
      'id': 'bp_1',
      'beanId': 'b1',
      'purchasedAt': '2026/07/29 12:00',
    });
    expect(purchase.purchasedAt, DateTime(2026, 7, 29, 12, 0));
  });

  test('購入量(g)が文字列で来ても数値にキャストされる', () {
    final purchase = BeanPurchase.fromJson({
      'id': 'bp_1',
      'beanId': 'b1',
      'quantityGrams': '200.5',
    });
    expect(purchase.quantityGrams, 200.5);
  });

  test('copyWithで指定フィールドのみ上書きされる', () {
    final purchase = BeanPurchase(id: 'bp_1', beanId: 'b1', storeName: 'Navy');
    final updated = purchase.copyWith(storeName: 'HEISEI COFFEE');
    expect(updated.id, 'bp_1');
    expect(updated.beanId, 'b1');
    expect(updated.storeName, 'HEISEI COFFEE');
  });
}
