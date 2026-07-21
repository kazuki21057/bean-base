import 'dart:math';

import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/services/statistics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatisticsService Tests', () {
    late StatisticsService service;
    late List<CoffeeRecord> mockRecords;

    setUp(() {
      service = StatisticsService();
      mockRecords = [
        CoffeeRecord(
          id: '1',
          brewedAt: DateTime(2023, 1, 1, 10, 0),
          beanId: 'bean1',
          methodId: 'method1',
          beanWeight: 20,
          totalWater: 300,
          totalTime: 180,
          scoreOverall: 8,
          scoreFragrance: 7,
          scoreAcidity: 7,
          scoreBitterness: 7,
          scoreSweetness: 7,
          scoreComplexity: 7,
          scoreFlavor: 7,
          taste: '', 
          comment: '', 
          grindSize: '', 
          temperature: 90, 
          dripperId: '', 
          filterId: '',
          grinderId: '',
          roastLevel: '',
          origin: '',
          concentration: '',
          bloomingWater: 30,
          bloomingTime: 30,
        ),
        CoffeeRecord(
          id: '2',
          brewedAt: DateTime(2023, 1, 2, 10, 0),
          beanId: 'bean1',
          methodId: 'method2',
          beanWeight: 15,
          totalWater: 225,
          totalTime: 150,
          scoreOverall: 9,
          scoreFragrance: 8,
          scoreAcidity: 8,
          scoreBitterness: 6,
          scoreSweetness: 8,
          scoreComplexity: 8,
          scoreFlavor: 8,
          taste: '',
           comment: '', 
           grindSize: '', 
           temperature: 90, 
           dripperId: '', 
           filterId: '',
           grinderId: '',
           roastLevel: '',
           origin: '',
           concentration: '',
           bloomingWater: 30,
           bloomingTime: 30,
        ),
        CoffeeRecord(
          id: '3',
          brewedAt: DateTime(2023, 1, 3, 10, 0),
          beanId: 'bean2',
          methodId: 'method1',
          beanWeight: 18,
          totalWater: 270,
          totalTime: 160,
          scoreOverall: 7,
          scoreFragrance: 6,
          scoreAcidity: 6,
          scoreBitterness: 8,
          scoreSweetness: 6,
          scoreComplexity: 6,
          scoreFlavor: 6,
          taste: '',
           comment: '', 
           grindSize: '', 
           temperature: 90, 
           dripperId: '', 
           filterId: '',
           grinderId: '',
           roastLevel: '',
           origin: '',
           concentration: '',
           bloomingWater: 30,
           bloomingTime: 30,
        ),
      ];
    });

    test('calculateKPI calculates correctly', () {
      final kpi = service.calculateKPI(mockRecords);
      
      expect(kpi.totalBrews, 3);
      expect(kpi.totalBeansWeight, 20 + 15 + 18);
      expect(kpi.averageScore, (8 + 9 + 7) / 3);
    });

    test('filterRecords filters by date range', () {
      final filter = StatisticsFilter(
        dateRange: DateTimePair(DateTime(2023, 1, 1), DateTime(2023, 1, 1)),
      );
      final filtered = service.filterRecords(mockRecords, filter);
      
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('calculateRadarData returns global average', () {
      final filter = StatisticsFilter();
      final data = service.calculateRadarData(mockRecords, filter);
      
      // Global Avg for Fragrance: (7+8+6)/3 = 7
      expect(data.average['Fragrance'], 7.0);
      // Global Avg Score: (8+9+7)/3 = 8.0
      expect(data.average['Score'], 8.0);
      expect(data.target, isNull);
    });

    test('calculateRadarData returns target average for selected Bean', () {
      final filter = StatisticsFilter(
        comparisonTargetType: 'Bean',
        comparisonTargetId: 'bean1',
      );
      final data = service.calculateRadarData(mockRecords, filter);
      
      expect(data.target, isNotNull);
      // Bean1 Avg Fragrance: (7+8)/2 = 7.5
      expect(data.target!['Fragrance'], 7.5);
      // Bean1 Avg Score: (8+9)/2 = 8.5
      expect(data.target!['Score'], 8.5);
    });

    // T4-3a(F2、相関行列ベース化): mockRecordsの6軸のうちBitternessだけが他5軸と
    // 逆相関(7,6,8)で、残り5軸は全く同じ値(7,8,6)というランク1の縮退データのため、
    // 固有値は[6,0,0,0,0,0]に決定的に定まる一方、2番目以降の固有値が縮退(=0が5重)
    // しているためPC2以降の固有ベクトルの向きは不定(実装依存)。よって符号に依存しない
    // 量(固有値・寄与率・累積寄与率・絶対値・符号の相対関係)のみを検証する。
    // 期待値はtools/verify_pca.py(numpy.linalg.eigh)で事前検証済み。
    test('calculatePca は相関行列ベースでPC1〜6の固有値・寄与率・スコアを返す (§9.7)', () {
      final result = service.calculatePca(mockRecords);

      expect(result.points.length, mockRecords.length);
      expect(result.excludedFeatures, isEmpty); // 全軸で標準偏差>0

      // 全成分(6件)を保持する (設計書§6.1手順4、従来はPC1/PC2のみ2件だった)
      expect(result.components.length, 6);
      expect(result.components.first.contributions.length, 6);

      // 固有値: ランク1データのためPC1のみ6、残りは0 (Σλ=m=6を維持)
      expect(result.components[0].eigenvalue, closeTo(6.0, 1e-9));
      for (var i = 1; i < 6; i++) {
        expect(result.components[i].eigenvalue, closeTo(0.0, 1e-9));
      }

      // 寄与率 (T-13) ・累積寄与率 (T-14)
      expect(result.components[0].contributionRatio, closeTo(1.0, 1e-9));
      expect(result.components[0].cumulativeRatio, closeTo(1.0, 1e-9));
      expect(result.components[5].cumulativeRatio, closeTo(1.0, 1e-9));

      // PC1負荷量 (T-15): 縮退していないため絶対値・符号関係が決定的。
      // Fragrance/Acidity/Sweetness/Complexity/Flavorは同じ値の列(相関+1)なので
      // 絶対値1.0で同符号、Bitternessだけ逆相関(-1.0)で反対符号。
      final pc1 = result.components[0].contributions;
      for (final axis in ['Fragrance', 'Acidity', 'Sweetness', 'Complexity', 'Flavor']) {
        expect(pc1[axis]!.abs(), closeTo(1.0, 1e-6));
      }
      expect(pc1['Bitterness']!.abs(), closeTo(1.0, 1e-6));
      expect(pc1['Fragrance']! * pc1['Bitterness']!, lessThan(0)); // 逆相関=反対符号

      // PC1スコア (T-12): record1は全軸が平均(7)なのでスコア0、record2/3は
      // ±√6(≈2.449)で符号が逆になる (numpyでの事前検証値と一致)。
      expect(result.points[0].x.abs(), closeTo(0.0, 1e-9));
      expect(result.points[1].x.abs(), closeTo(sqrt(6), 1e-6));
      expect(result.points[2].x.abs(), closeTo(sqrt(6), 1e-6));
      expect(result.points[1].x * result.points[2].x, lessThan(0));
    });

    test('calculatePca は標準偏差0の軸を除外する', () {
      // 6軸のうちscoreFlavorだけ全件同値(7)にすると、その軸だけ相関行列から
      // 除外され、残り5軸でPCAが行われることを確認する (設計書§6.1手順2)。
      final constantFlavorRecords = mockRecords
          .map((r) => r.copyWith(scoreFlavor: 7))
          .toList();

      final result = service.calculatePca(constantFlavorRecords);

      expect(result.excludedFeatures, ['Flavor']);
      expect(result.components.length, 5);
      expect(result.components.first.contributions.containsKey('Flavor'), isFalse);
    });
  });
}
