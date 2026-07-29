import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/utils/bean_stock_calculator.dart';

CoffeeRecord _fakeLog({required String beanId, required double beanWeight, DateTime? brewedAt}) {
  return CoffeeRecord(
    id: 'l-$beanId-$beanWeight-${brewedAt ?? DateTime(2026, 7, 1)}',
    brewedAt: brewedAt ?? DateTime(2026, 7, 1),
    grinderId: '',
    dripperId: '',
    filterId: '',
    beanId: beanId,
    roastLevel: '',
    origin: '',
    beanWeight: beanWeight,
    grindSize: '',
    methodId: '',
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 40,
    totalWater: 300,
    bloomingTime: 30,
    totalTime: 180,
    scoreFragrance: 5,
    scoreAcidity: 5,
    scoreBitterness: 5,
    scoreSweetness: 5,
    scoreComplexity: 5,
    scoreFlavor: 5,
    scoreOverall: 7,
    comment: '',
  );
}

BeanMaster _fakeBean({
  double? initialQuantityGrams,
  double? stockBaselineGrams,
  DateTime? stockBaselineAt,
}) {
  return BeanMaster(
    id: 'b1',
    name: 'テスト豆',
    roastLevel: '中煎り',
    origin: 'エチオピア',
    initialQuantityGrams: initialQuantityGrams,
    stockBaselineGrams: stockBaselineGrams,
    stockBaselineAt: stockBaselineAt,
  );
}

void main() {
  group('calculateBeanRemainingPercent', () {
    test('初期購入量が未設定の豆は0%(既存データ互換)', () {
      final bean = _fakeBean(initialQuantityGrams: null);
      expect(calculateBeanRemainingPercent(bean, []), 0);
    });

    test('初期購入量が0以下の豆は0%', () {
      final bean = _fakeBean(initialQuantityGrams: 0);
      expect(calculateBeanRemainingPercent(bean, []), 0);
    });

    test('抽出履歴がなければ100%', () {
      final bean = _fakeBean(initialQuantityGrams: 200);
      expect(calculateBeanRemainingPercent(bean, []), 100);
    });

    test('使用量の合計を差し引いた残量%を返す', () {
      final bean = _fakeBean(initialQuantityGrams: 200);
      final records = [
        _fakeLog(beanId: 'b1', beanWeight: 20),
        _fakeLog(beanId: 'b1', beanWeight: 30),
      ];
      // (200 - 50) / 200 * 100 = 75%
      expect(calculateBeanRemainingPercent(bean, records), 75);
    });

    test('他の豆の抽出履歴は計算に含まれない', () {
      final bean = _fakeBean(initialQuantityGrams: 100);
      final records = [
        _fakeLog(beanId: 'other', beanWeight: 90),
        _fakeLog(beanId: 'b1', beanWeight: 10),
      ];
      // (100 - 10) / 100 * 100 = 90%
      expect(calculateBeanRemainingPercent(bean, records), 90);
    });

    test('使用量が初期量を超えても0%未満にはならない', () {
      final bean = _fakeBean(initialQuantityGrams: 50);
      final records = [_fakeLog(beanId: 'b1', beanWeight: 999)];
      expect(calculateBeanRemainingPercent(bean, records), 0);
    });
  });

  group('T3-60 在庫基準点(stockBaselineGrams)', () {
    test('基準点設定直後(記録なし)は100%になる', () {
      final bean = _fakeBean(
        initialQuantityGrams: 200,
        stockBaselineGrams: 80,
        stockBaselineAt: DateTime(2026, 7, 29),
      );
      expect(calculateBeanRemainingPercent(bean, []), 100);
      expect(calculateBeanRemainingGrams(bean, []), 80);
    });

    test('基準点より後の記録のみ差し引かれる', () {
      final bean = _fakeBean(
        initialQuantityGrams: 200,
        stockBaselineGrams: 80,
        stockBaselineAt: DateTime(2026, 7, 29),
      );
      final records = [
        _fakeLog(beanId: 'b1', beanWeight: 100, brewedAt: DateTime(2026, 7, 1)), // 基準点より前: 無視
        _fakeLog(beanId: 'b1', beanWeight: 20, brewedAt: DateTime(2026, 7, 30)), // 基準点より後: 差し引く
      ];
      // (80 - 20) / 80 * 100 = 75%
      expect(calculateBeanRemainingPercent(bean, records), 75);
      expect(calculateBeanRemainingGrams(bean, records), 60);
    });

    test('基準点未設定の既存豆は従来どおりinitialQuantityGrams基準で算出される(後方互換)', () {
      final bean = _fakeBean(initialQuantityGrams: 200);
      final records = [_fakeLog(beanId: 'b1', beanWeight: 50, brewedAt: DateTime(2026, 7, 1))];
      // (200 - 50) / 200 * 100 = 75%
      expect(calculateBeanRemainingPercent(bean, records), 75);
      expect(calculateBeanRemainingGrams(bean, records), 150);
    });

    test('基準点を使った使用量が基準点を超えても0g未満にはならない', () {
      final bean = _fakeBean(
        initialQuantityGrams: 200,
        stockBaselineGrams: 30,
        stockBaselineAt: DateTime(2026, 7, 29),
      );
      final records = [_fakeLog(beanId: 'b1', beanWeight: 999, brewedAt: DateTime(2026, 7, 30))];
      expect(calculateBeanRemainingPercent(bean, records), 0);
      expect(calculateBeanRemainingGrams(bean, records), 0);
    });
  });
}
