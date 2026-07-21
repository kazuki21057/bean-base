import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/services/math/design_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

CoffeeRecord _record({
  required String originId,
  required String roastLevel,
  required double temperature,
  required double totalWater,
  required double beanWeight,
  required int totalTime,
  required int scoreOverall,
}) {
  return CoffeeRecord(
    id: 'r',
    brewedAt: DateTime(2026, 7, 21),
    grinderId: 'g',
    dripperId: 'd',
    filterId: 'f',
    beanId: 'b',
    roastLevel: roastLevel,
    origin: '',
    originId: originId,
    beanWeight: beanWeight,
    grindSize: '',
    methodId: 'm',
    taste: '',
    concentration: '',
    temperature: temperature,
    bloomingWater: 0,
    totalWater: totalWater,
    bloomingTime: 0,
    totalTime: totalTime,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    scoreOverall: scoreOverall,
    comment: '',
  );
}

final _originById = {
  'origin_1': OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
  'origin_2': OriginMaster(id: 'origin_2', countryCode: 'KE', nameJa: 'ケニア', nameEn: 'Kenya', region: 'アフリカ'),
  'origin_3': OriginMaster(id: 'origin_3', countryCode: 'BR', nameJa: 'ブラジル', nameEn: 'Brazil', region: '中南米'),
  'origin_4': OriginMaster(id: 'origin_4', countryCode: 'UG', nameJa: 'ウガンダ', nameEn: 'Uganda', region: 'アフリカ'),
};

void main() {
  group('buildRegressionMatrix (設計書§4.4)', () {
    test('行フィルタ: 湯温欠測・焙煎度未解決の行を除外しexcludedRowsに反映', () {
      final records = [
        for (var i = 0; i < 6; i++)
          _record(originId: 'origin_1', roastLevel: '中煎り', temperature: (90 + i).toDouble(), totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
        _record(originId: 'origin_1', roastLevel: '中煎り', temperature: 0, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
        _record(originId: 'origin_1', roastLevel: '不明な焙煎度', temperature: 90, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
      ];

      final design = buildRegressionMatrix(records, _originById);

      expect(design.excludedRows, 2);
      expect(design.x.length, 6);
    });

    test('産地ダミー: 個別水準がn<5でも地域プールが5以上なら地域水準として残る', () {
      final records = [
        for (var i = 0; i < 7; i++)
          _record(originId: 'origin_1', roastLevel: '中煎り', temperature: (90 + i).toDouble(), totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
        for (var i = 0; i < 3; i++)
          _record(originId: 'origin_2', roastLevel: '中煎り', temperature: (88 + i).toDouble(), totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 6),
        for (var i = 0; i < 3; i++)
          _record(originId: 'origin_4', roastLevel: '中煎り', temperature: (87 + i).toDouble(), totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 6),
        _record(originId: 'origin_3', roastLevel: '中煎り', temperature: 85, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 8),
      ];

      final design = buildRegressionMatrix(records, _originById);

      expect(design.baseLevel, 'エチオピア'); // n=7で最多
      expect(design.dummyLevels.toSet(), {'アフリカ', 'その他'}); // ケニア+ウガンダ計6→アフリカ、ブラジル単独1→その他
      expect(design.categoryCounts['エチオピア'], 7);
      expect(design.categoryCounts['アフリカ'], 6);
      expect(design.categoryCounts['その他'], 1);
      expect(design.columnNames, containsAll(['産地:アフリカ', '産地:その他']));
      expect(design.columnNames, isNot(contains('産地:エチオピア'))); // 基準水準はダミー列を作らない
    });

    test('産地ダミー: 地域プールも5未満なら「その他」に統合', () {
      final records = [
        for (var i = 0; i < 6; i++)
          _record(originId: 'origin_1', roastLevel: '中煎り', temperature: (90 + i).toDouble(), totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
        _record(originId: 'origin_2', roastLevel: '中煎り', temperature: 88, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 6),
        _record(originId: 'origin_3', roastLevel: '中煎り', temperature: 85, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 8),
      ];

      final design = buildRegressionMatrix(records, _originById);

      expect(design.dummyLevels, ['その他']);
      expect(design.categoryCounts['エチオピア'], 6);
      expect(design.categoryCounts['その他'], 2);
    });

    test('連続変数(湯温)は採用行の平均で中心化される', () {
      final records = [
        _record(originId: 'origin_1', roastLevel: '中煎り', temperature: 80, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
        _record(originId: 'origin_1', roastLevel: '中煎り', temperature: 90, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
        _record(originId: 'origin_1', roastLevel: '中煎り', temperature: 100, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
      ];

      final design = buildRegressionMatrix(records, _originById);

      final tempColumn = [for (final row in design.x) row[1]];
      final sum = tempColumn.reduce((a, b) => a + b);
      expect(sum, closeTo(0.0, 1e-9));
      expect(design.centerMeans['temperature'], closeTo(90.0, 1e-9));
    });

    test('交互作用列(焙煎順序×湯温)は最終列に中心化済みの積として入る', () {
      final records = [
        _record(originId: 'origin_1', roastLevel: '浅煎り', temperature: 85, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
        _record(originId: 'origin_1', roastLevel: '深煎り', temperature: 95, totalWater: 240, beanWeight: 15, totalTime: 180, scoreOverall: 7),
      ];

      final design = buildRegressionMatrix(records, _originById);

      expect(design.columnNames.last, '焙煎順序×湯温(交互作用)');
      final interactionColumn = [for (final row in design.x) row.last];
      final tempColumn = [for (final row in design.x) row[1]];
      final roastColumn = [for (final row in design.x) row[4]];
      for (var i = 0; i < interactionColumn.length; i++) {
        expect(interactionColumn[i], closeTo(tempColumn[i] * roastColumn[i], 1e-9));
      }
    });
  });
}
