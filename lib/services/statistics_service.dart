import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_linalg/linalg.dart';
import '../models/coffee_record.dart';

// Filter model
class StatisticsFilter {
  final DateTimePair? dateRange;
  final String? comparisonTargetType; // 'Bean' or 'Method'
  final String? comparisonTargetId;

  StatisticsFilter({
    this.dateRange,
    this.comparisonTargetType,
    this.comparisonTargetId,
  });

  StatisticsFilter copyWith({
    DateTimePair? dateRange,
    String? comparisonTargetType,
    String? comparisonTargetId,
  }) {
    return StatisticsFilter(
      dateRange: dateRange ?? this.dateRange,
      comparisonTargetType: comparisonTargetType ?? this.comparisonTargetType,
      comparisonTargetId: comparisonTargetId ?? this.comparisonTargetId,
    );
  }
}

class DateTimePair {
  final DateTime start;
  final DateTime end;
  DateTimePair(this.start, this.end);
}

// KPI Model
class StatisticsKPI {
  final int totalBrews;
  final double totalBeansWeight;
  final double averageScore;

  StatisticsKPI(this.totalBrews, this.totalBeansWeight, this.averageScore);
}

// Radar Data Model
class RadarChartDataModel {
  final Map<String, double> average;
  final Map<String, double>? target;

  RadarChartDataModel({required this.average, this.target});
}

// PCA Point Model
class PcaPoint {
  final String id;
  final String label;
  final double x;
  final double y;
  final Map<String, dynamic> metadata;

  PcaPoint(this.id, this.label, this.x, this.y, this.metadata);
}

class StatisticsService {
  
  List<CoffeeRecord> filterRecords(List<CoffeeRecord> records, StatisticsFilter filter) {
    return records.where((r) {
      if (filter.dateRange != null) {
        if (r.brewedAt.isBefore(filter.dateRange!.start) || 
            r.brewedAt.isAfter(filter.dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  StatisticsKPI calculateKPI(List<CoffeeRecord> records) {
    if (records.isEmpty) return StatisticsKPI(0, 0, 0);

    final totalBrews = records.length;
    final totalWeight = records.fold(0.0, (sum, r) => sum + r.beanWeight);
    final avgScore = records.fold(0.0, (sum, r) => sum + r.scoreOverall) / totalBrews;

    return StatisticsKPI(totalBrews, totalWeight, avgScore);
  }

  RadarChartDataModel calculateRadarData(List<CoffeeRecord> allRecords, StatisticsFilter filter) {
    Map<String, double> _avg(List<CoffeeRecord> list) {
       if (list.isEmpty) {
         return {
           'Fragrance': 0, 'Acidity': 0, 'Bitterness': 0, 
           'Sweetness': 0, 'Complexity': 0, 'Flavor': 0
         };
       }
       final count = list.length;
       return {
         'Fragrance': list.fold(0.0, (s, r) => s + r.scoreFragrance) / count,
         'Acidity': list.fold(0.0, (s, r) => s + r.scoreAcidity) / count,
         'Bitterness': list.fold(0.0, (s, r) => s + r.scoreBitterness) / count,
         'Sweetness': list.fold(0.0, (s, r) => s + r.scoreSweetness) / count,
         'Complexity': list.fold(0.0, (s, r) => s + r.scoreComplexity) / count,
         'Flavor': list.fold(0.0, (s, r) => s + r.scoreFlavor) / count,
       };
    }

    final globalAvg = _avg(allRecords);
    Map<String, double>? targetAvg;

    if (filter.comparisonTargetType != null && filter.comparisonTargetId != null) {
      List<CoffeeRecord> targetRecords = [];
      if (filter.comparisonTargetType == 'Bean') {
        targetRecords = allRecords.where((r) => r.beanId == filter.comparisonTargetId).toList();
      } else if (filter.comparisonTargetType == 'Method') {
        targetRecords = allRecords.where((r) => r.methodId == filter.comparisonTargetId).toList();
      }
      if (targetRecords.isNotEmpty) {
        targetAvg = _avg(targetRecords);
      }
    }

    return RadarChartDataModel(average: globalAvg, target: targetAvg);
  }

  // PCA Calculation
  List<PcaPoint> calculatePca(List<CoffeeRecord> records) {
    // PCA temporarily disabled due to ml_linalg version issue (SingularValueDecomposition not found)
    // TODO: Fix dependency or implement custom SVD
    return [];
  }
}

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

// State Providers for UI
final statisticsFilterProvider = StateProvider<StatisticsFilter>((ref) => StatisticsFilter());

