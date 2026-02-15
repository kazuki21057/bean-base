import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_linalg/linalg.dart';
import 'dart:math';
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

class PcaComponent {
  final String name;
  final Map<String, double> contributions;
  PcaComponent(this.name, this.contributions);
}

class PcaResult {
  final List<PcaPoint> points;
  final List<PcaComponent> components;
  PcaResult(this.points, this.components);
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

  // PCA Calculation
  PcaResult calculatePca(List<CoffeeRecord> records) {
    if (records.length < 3) return PcaResult([], []);

    try {
      // 1. Extract features
      final featureNames = ['Fragrance', 'Acidity', 'Bitterness', 'Sweetness', 'Complexity', 'Flavor'];
      final features = records.map((r) => [
        r.scoreFragrance.toDouble(),
        r.scoreAcidity.toDouble(),
        r.scoreBitterness.toDouble(),
        r.scoreSweetness.toDouble(),
        r.scoreComplexity.toDouble(),
        r.scoreFlavor.toDouble(),
      ].toList()).toList();

      final matrix = Matrix.fromList(features);

      // 2. Center the data
      final meanVector = matrix.mean(); 
      final centeredMatrix = matrix.mapRows((row) => row - meanVector);

      // 3. Covariance Matrix
      // C = (X^T * X) / (n - 1)
      final n = records.length;
      final covMatrix = (centeredMatrix.transpose() * centeredMatrix) / (n - 1).toDouble();

      // 4. Eigenvalue Decomposition using Jacobi Method
      final eigenResult = _jacobiEigenvalueAlgorithm(covMatrix);
      
      // 5. Select top 2 principal components
      final pc1 = Vector.fromList(eigenResult.eigenvectors[0]);
      final pc2 = Vector.fromList(eigenResult.eigenvectors[1]);

      // Calculate PCA Components (Contributions)
      Map<String, double> _getContributions(Vector pc) {
        final map = <String, double>{};
        for (int i = 0; i < featureNames.length; i++) {
          map[featureNames[i]] = pc[i];
        }
        return map;
      }

      final components = [
        PcaComponent('PC1', _getContributions(pc1)),
        PcaComponent('PC2', _getContributions(pc2)),
      ];

      // 6. Project data
      final projectionMatrix = Matrix.fromColumns([pc1, pc2]);
      final projected = centeredMatrix * projectionMatrix;

      List<PcaPoint> points = [];
      for (int i = 0; i < records.length; i++) {
        final row = projected.getRow(i);
        points.add(PcaPoint(
          records[i].id,
          records[i].beanId, 
          row[0], 
          row[1],
          {
            'method': records[i].methodId,
            'score': records[i].scoreOverall,
          }
        ));
      }
      return PcaResult(points, components);

    } catch (e, stack) {
      print('PCA Calculation Error: $e');
      print(stack);
      return PcaResult([], []);
    }
  }

  // Simple Jacobi Eigenvalue Algorithm for Symmetric Matrices
  _EigenResult _jacobiEigenvalueAlgorithm(Matrix matrix, {int maxIter = 100, double tol = 1e-10}) {
    final n = matrix.rowCount;
    // Copy matrix to Dart lists for mutable operations
    List<List<double>> A = List.generate(n, (i) => matrix.getRow(i).toList());
    
    // Initialize V as identity matrix
    List<List<double>> V = List.generate(n, (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0));

    for (int iter = 0; iter < maxIter; iter++) {
      // Find pivot (max off-diagonal element)
      double maxVal = 0.0;
      int p = 0, q = 0;
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          if (A[i][j].abs() > maxVal) {
            maxVal = A[i][j].abs();
            p = i;
            q = j;
          }
        }
      }

      if (maxVal < tol) break;

      // Calculate rotation angle
      double theta = 0.0;
      double diff = A[q][q] - A[p][p];
      if (diff.abs() < 1e-20) {
        theta = 3.1415926535897932 / 4;
      } else {
        theta = 0.5 * atan(2 * A[p][q] / diff);
        // Better formula: tan(2theta) = 2*App / (Aqq - App)
        // theta = 0.5 * atan2(2 * A[p][q], diff); 
        // Dart's num has atan, but standard formula involves atan2 for stability?
        // Let's use simple atan derived:
        // t = sgn(diff) / (|diff|/sqrt(...) + ...) 
        // Using standard atan for now
        
        // Using simpler approximation if A[p][q] is small? No.
        // theta = 0.5 * atan2(2*A[p][q], A[q][q] - A[p][p]);  <-- Wait, Aqq - App or App - Aqq?
        // standard: tan(2theta) = 2*Apq / (App - Aqq) ? No (Aqq - App).
        // Let's use a stable implementation logic.
      }
      
      // Let's rely on standard Jacobi rotation formulas
      // y = (A[q][q] - A[p][p]) / 2.0;
      // x = -A[p][q];  (to zero out Apq)
      // t = (x.abs() / (y.abs() + sqrt(x*x + y*y))) * x.sign * y.sign ... too complex to recall perfectly
      
      // Using the theta from atan:
      // tan(2phi) = 2 a_pq / (a_pp - a_qq) => 2 a_pq / (a_qq - a_pp) if we want to zero it?
      // Formulas:
      // phi = 0.5 * atan2(2 * A[p][q], A[q][q] - A[p][p]);
      // But standard atan(x) ranges -pi/2 to pi/2.
      
      // Let's just use:
      double phi = 0.5 * atan(2 * A[p][q] / (A[p][p] - A[q][q]));
      // Correction if denominator is near 0 done above roughly, but let's be precise.
      if ((A[p][p] - A[q][q]).abs() < 1e-10) {
         phi = (3.1415926535897932 / 4) * (A[p][q] > 0 ? 1 : -1);
      } else {
         phi = 0.5 * atan(2 * A[p][q] / (A[p][p] - A[q][q]));
      }

      double c = cos(phi);
      double s = sin(phi);

      // Update A
      // We only need to update rows/cols p and q, but since we have full matrix A in memory...
      // A_new = J^T * A * J
      // This is element-wise update.
      
      // Store old values
      double app = A[p][p];
      double aqq = A[q][q];
      double apq = A[p][q];

      A[p][p] = c * c * app - 2 * s * c * apq + s * s * aqq;
      A[q][q] = s * s * app + 2 * s * c * apq + c * c * aqq;
      A[p][q] = 0.0; // Theoretically 0
      A[q][p] = 0.0;

      for (int k = 0; k < n; k++) {
        if (k != p && k != q) {
          double akp = A[k][p];
          double akq = A[k][q];
          A[k][p] = c * akp - s * akq;
          A[p][k] = A[k][p];
          A[k][q] = s * akp + c * akq;
          A[q][k] = A[k][q];
        }
      }

      // Update eigenvectors V
      // V_new = V * J
      for (int k = 0; k < n; k++) {
        double vkp = V[k][p];
        double vkq = V[k][q];
        V[k][p] = c * vkp - s * vkq;
        V[k][q] = s * vkp + c * vkq;
      }
    }

    // Extract eigenvalues (diagonal of A) and paired eigenvectors (columns of V)
    List<_EigenPair> pairs = [];
    for (int i = 0; i < n; i++) {
      // Get column i from V
      List<double> eigenvector = [];
      for (int k = 0; k < n; k++) eigenvector.add(V[k][i]);
      pairs.add(_EigenPair(A[i][i], eigenvector));
    }

    // Sort by eigenvalue descending
    pairs.sort((a, b) => b.eigenvalue.compareTo(a.eigenvalue));

    return _EigenResult(
      pairs.map((p) => p.eigenvalue).toList(),
      pairs.map((p) => p.eigenvector).toList(),
    );
  }

}

class _EigenResult {
  final List<double> eigenvalues;
  final List<List<double>> eigenvectors;
  _EigenResult(this.eigenvalues, this.eigenvectors);
}

class _EigenPair {
  final double eigenvalue;
  final List<double> eigenvector;
  _EigenPair(this.eigenvalue, this.eigenvector);
}

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

// State Providers for UI
final statisticsFilterProvider = StateProvider<StatisticsFilter>((ref) => StatisticsFilter());

