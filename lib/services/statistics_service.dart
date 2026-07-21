import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/coffee_record.dart';
import 'math/eigen.dart';

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

class PcaComponent {
  final String name;
  final Map<String, double> contributions; // 負荷量 (T-15、相関行列ベースでは元変数との相関係数に一致)
  final double eigenvalue;
  final double contributionRatio; // T-13
  final double cumulativeRatio; // T-14
  PcaComponent(
    this.name,
    this.contributions, {
    required this.eigenvalue,
    required this.contributionRatio,
    required this.cumulativeRatio,
  });
}

class PcaResult {
  final List<PcaPoint> points;
  final List<PcaComponent> components; // 全主成分(標準偏差0の軸を除いた最大6件、固有値降順)
  final List<String> excludedFeatures; // 標準偏差0(全件同値)で相関行列から除外した軸名
  PcaResult(this.points, this.components, [this.excludedFeatures = const []]);
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
           'Sweetness': 0, 'Complexity': 0, 'Flavor': 0, 'Score': 0
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
         'Score': list.fold(0.0, (s, r) => s + r.scoreOverall) / count,
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

  // PCA計算 (F2、設計書§6.1・§2.2.1)。相関行列ベース + eigenSymmetric (T4-3a)。
  PcaResult calculatePca(List<CoffeeRecord> records) {
    if (records.length < 3) return PcaResult([], []);

    try {
      const featureNames = ['Fragrance', 'Acidity', 'Bitterness', 'Sweetness', 'Complexity', 'Flavor'];
      final raw = records.map((r) => [
        r.scoreFragrance.toDouble(),
        r.scoreAcidity.toDouble(),
        r.scoreBitterness.toDouble(),
        r.scoreSweetness.toDouble(),
        r.scoreComplexity.toDouble(),
        r.scoreFlavor.toDouble(),
      ]).toList();

      final n = records.length;
      final m = featureNames.length;

      // 列ごとの平均・不偏標準偏差 (n-1で割る。相関行列 R=ZᵀZ/(n-1) の前提、T-11)
      final means = List<double>.generate(m, (j) {
        var s = 0.0;
        for (final row in raw) {
          s += row[j];
        }
        return s / n;
      });
      final stds = List<double>.generate(m, (j) {
        var s = 0.0;
        for (final row in raw) {
          final d = row[j] - means[j];
          s += d * d;
        }
        return sqrt(s / (n - 1));
      });

      // 標準偏差0(全件同値)の軸は標準化できないため相関行列から除外する (設計書§6.1手順2)
      final retained = <int>[];
      final excludedFeatures = <String>[];
      for (var j = 0; j < m; j++) {
        if (stds[j] > 1e-12) {
          retained.add(j);
        } else {
          excludedFeatures.add(featureNames[j]);
        }
      }

      if (retained.length < 2) {
        return PcaResult([], [], excludedFeatures);
      }

      final mr = retained.length;
      // 標準化行列 Z (n x mr、平均0・分散1)
      final z = List<List<double>>.generate(
        n,
        (i) => List<double>.generate(mr, (jr) {
          final j = retained[jr];
          return (raw[i][j] - means[j]) / stds[j];
        }),
      );

      // 相関行列 R = ZᵀZ / (n-1) (T-11)
      final r = List<List<double>>.generate(
        mr,
        (a) => List<double>.generate(mr, (b) {
          var s = 0.0;
          for (var i = 0; i < n; i++) {
            s += z[i][a] * z[i][b];
          }
          return s / (n - 1);
        }),
      );

      final eigen = eigenSymmetric(r);

      final components = <PcaComponent>[];
      var cumulative = 0.0;
      for (var i = 0; i < mr; i++) {
        final eigenvalue = eigen.eigenvalues[i];
        final contributionRatio = eigenvalue / mr; // T-13 (相関行列なのでΣλ=変数数)
        cumulative += contributionRatio;
        final contributions = <String, double>{};
        for (var jr = 0; jr < mr; jr++) {
          // 負荷量 (T-15): 元変数との相関係数に一致
          contributions[featureNames[retained[jr]]] =
              eigen.eigenvectors[i][jr] * sqrt(max(eigenvalue, 0.0));
        }
        components.add(PcaComponent(
          'PC${i + 1}',
          contributions,
          eigenvalue: eigenvalue,
          contributionRatio: contributionRatio,
          cumulativeRatio: cumulative, // T-14
        ));
      }

      // 主成分スコア (T-12): tᵢ = Z vᵢ。散布図表示にはPC1/PC2を使用。
      final v1 = eigen.eigenvectors[0];
      final v2 = eigen.eigenvectors[1];
      final points = <PcaPoint>[];
      for (var i = 0; i < n; i++) {
        var x = 0.0, y = 0.0;
        for (var jr = 0; jr < mr; jr++) {
          x += z[i][jr] * v1[jr];
          y += z[i][jr] * v2[jr];
        }
        points.add(PcaPoint(
          records[i].id,
          records[i].beanId,
          x,
          y,
          {
            'method': records[i].methodId,
            'score': records[i].scoreOverall,
          },
        ));
      }

      return PcaResult(points, components, excludedFeatures);
    } catch (e, stack) {
      debugPrint('[Antigravity] PCA計算エラー: $e\n$stack');
      return PcaResult([], []);
    }
  }
}

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

// State Providers for UI
final statisticsFilterProvider = StateProvider<StatisticsFilter>((ref) => StatisticsFilter());

