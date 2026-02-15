import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/services/statistics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_linalg/linalg.dart';
import 'package:ml_linalg/dtype.dart';

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
    });

    test('calculatePca returns points with coordinates', () {
      // Need at least 3 records
      final result = service.calculatePca(mockRecords);
      
      expect(result.points.length, mockRecords.length);
      expect(result.points.first.x, isNotNull);
      expect(result.points.first.y, isNotNull);
      expect(result.points.first.metadata, isNotEmpty); // Check metadata
      
      expect(result.components.length, 2); // PC1, PC2
      expect(result.components.first.contributions.length, 6); // 6 features
    });
  });
}
