import 'package:bean_base/models/coffee_record.dart';
import 'package:flutter_test/flutter_test.dart';

CoffeeRecord _baseRecord({double beanWeight = 15.0, double totalWater = 240.0, String originId = ''}) {
  return CoffeeRecord(
    id: '1',
    brewedAt: DateTime(2026, 7, 21, 8, 0),
    grinderId: 'g1',
    dripperId: 'd1',
    filterId: 'f1',
    beanId: 'b1',
    roastLevel: '中煎り',
    origin: 'ブラジル',
    originId: originId,
    beanWeight: beanWeight,
    grindSize: '中挽き',
    methodId: 'm1',
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 30,
    totalWater: totalWater,
    bloomingTime: 30,
    totalTime: 180,
    scoreFragrance: 7,
    scoreAcidity: 7,
    scoreBitterness: 7,
    scoreSweetness: 7,
    scoreComplexity: 7,
    scoreFlavor: 7,
    scoreOverall: 7,
    comment: '',
  );
}

void main() {
  group('CoffeeRecord T4-1b拡張(originId)', () {
    test('json round-trip', () {
      final record = _baseRecord(originId: 'origin_5');
      final json = record.toJson();
      final restored = CoffeeRecord.fromJson(json);
      expect(restored.originId, 'origin_5');
    });

    test('originId未設定の既存データはデフォルト値になる', () {
      final json = _baseRecord().toJson()..remove('originId');
      final restored = CoffeeRecord.fromJson(json);
      expect(restored.originId, '');
    });
  });

  group('CoffeeRecord.brewRatio (T4-1b、導出プロパティ)', () {
    test('豆量>0のとき湯量/豆量を返す', () {
      final record = _baseRecord(beanWeight: 15.0, totalWater: 240.0);
      expect(record.brewRatio, closeTo(16.0, 1e-9));
    });

    test('豆量0のときnullを返す(欠測行として除外される想定)', () {
      final record = _baseRecord(beanWeight: 0.0, totalWater: 240.0);
      expect(record.brewRatio, isNull);
    });

    test('brewRatioはtoJsonに含まれない(保存しない導出プロパティ)', () {
      final record = _baseRecord(beanWeight: 15.0, totalWater: 240.0);
      expect(record.toJson().containsKey('brewRatio'), isFalse);
    });
  });
}
