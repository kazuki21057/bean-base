import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/store_master.dart';

/// T3-67(docs/store_master_design.md§2): StoreMasterのシリアライズ検証。
void main() {
  test('fromJson/toJsonが往復する', () {
    final store = StoreMaster(
      id: 'store_navy',
      name: 'Navy',
      formalName: 'Navy Coffee Roaster',
      url: 'https://www.navycoffeeroaster.com/',
      prefecture: '兵庫県',
      address: '明石市大蔵中町4-8',
      hasOnlineShop: true,
      hasPhysicalStore: true,
      hasRoastery: true,
      beanTendency: 'スペシャルティコーヒー',
      memo: 'メモ',
      imageUrl: 'https://drive.google.com/uc?id=1',
      snsUrl: 'https://www.instagram.com/navy_coffee_roaster/',
      businessHours: '8:00-18:00',
      closedDays: '火曜',
      phone: '078-965-6998',
      openedYear: '2019',
      sourceUrl: 'https://example.com',
      infoFetchedAt: DateTime(2026, 7, 28, 12, 0),
    );

    final roundTripped = StoreMaster.fromJson(store.toJson());

    expect(roundTripped.id, store.id);
    expect(roundTripped.name, store.name);
    expect(roundTripped.formalName, store.formalName);
    expect(roundTripped.url, store.url);
    expect(roundTripped.prefecture, store.prefecture);
    expect(roundTripped.address, store.address);
    expect(roundTripped.hasOnlineShop, true);
    expect(roundTripped.hasPhysicalStore, true);
    expect(roundTripped.hasRoastery, true);
    expect(roundTripped.beanTendency, store.beanTendency);
    expect(roundTripped.memo, store.memo);
    expect(roundTripped.imageUrl, store.imageUrl);
    expect(roundTripped.snsUrl, store.snsUrl);
    expect(roundTripped.businessHours, store.businessHours);
    expect(roundTripped.closedDays, store.closedDays);
    expect(roundTripped.phone, store.phone);
    expect(roundTripped.openedYear, store.openedYear);
    expect(roundTripped.sourceUrl, store.sourceUrl);
    expect(roundTripped.infoFetchedAt, store.infoFetchedAt);
  });

  test('数値IDがStringにキャストされる(Sheetsが数値IDを返す既知の挙動)', () {
    final store = StoreMaster.fromJson({'id': 1784633291938, 'name': 'テスト店'});
    expect(store.id, '1784633291938');
    expect(store.id, isA<String>());
  });

  test('空IDはクラッシュせず既定値の空文字になる', () {
    final store = StoreMaster.fromJson({'name': 'テスト店'});
    expect(store.id, '');
  });

  test('bool列は大文字TRUE/FALSE表記を解釈する(GASのシート表現)', () {
    final store = StoreMaster.fromJson({
      'id': 's1',
      'name': 'テスト店',
      'hasOnlineShop': 'TRUE',
      'hasPhysicalStore': 'FALSE',
      'hasRoastery': 'true',
    });
    expect(store.hasOnlineShop, true);
    expect(store.hasPhysicalStore, false);
    expect(store.hasRoastery, true);
  });

  test('bool未設定は既定でfalse', () {
    final store = StoreMaster.fromJson({'id': 's1', 'name': 'テスト店'});
    expect(store.hasOnlineShop, false);
    expect(store.hasPhysicalStore, false);
    expect(store.hasRoastery, false);
  });

  test('店名未設定は既定値-になる', () {
    final store = StoreMaster.fromJson({'id': 's1'});
    expect(store.name, '-');
  });

  test('開業年がGoogle Sheetsで数値化されて返ってきても文字列にキャストされる'
      '(数字のみの開業年は「TRUE」判定と同型でSheetsが自動的に数値型にする既知の挙動)', () {
    final store = StoreMaster.fromJson({'id': 's1', 'name': 'テスト店', 'openedYear': 2019});
    expect(store.openedYear, '2019');
    expect(store.openedYear, isA<String>());
  });

  test('kInitialStoreMastersは7店・IDが固定スラッグで全て一意', () {
    expect(kInitialStoreMasters.length, 7);
    final ids = kInitialStoreMasters.map((s) => s.id).toSet();
    expect(ids.length, 7);
    expect(ids, contains('store_navy'));
    expect(ids, contains('store_kobe_coffee'));
    expect(ids, contains('store_heisei'));
    expect(ids, contains('store_sora'));
    expect(ids, contains('store_misaki'));
    expect(ids, contains('store_akekure'));
    expect(ids, contains('store_youth'));
  });
}
