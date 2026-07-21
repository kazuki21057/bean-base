import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coffee_record.dart';
import '../models/origin_master.dart';
import 'math/design_matrix.dart';
import 'math/distributions.dart';
import 'math/linear_solve.dart';

/// 重回帰分析(F1)の係数1本分 (設計書§5.1)。
class RegressionCoefficient {
  final String name;
  final double beta;
  final double se;
  final double tValue;
  final double pValue;
  final double vif; // 切片の vif は double.nan

  RegressionCoefficient({
    required this.name,
    required this.beta,
    required this.se,
    required this.tValue,
    required this.pValue,
    required this.vif,
  });
}

/// 重回帰分析の結果 (設計書§5.1)。
class RegressionResult {
  final List<RegressionCoefficient> coefficients;
  final int n;
  final int p;
  final double r2;
  final double adjR2;
  final double aic;
  final double sigmaHat;
  final List<double> fitted;
  final List<double> residuals;
  final int excludedRows;
  final int defaultScoreCount; // §2.1.5(3) scoreOverall==7 の件数
  final DesignMatrixResult design;

  RegressionResult({
    required this.coefficients,
    required this.n,
    required this.p,
    required this.r2,
    required this.adjR2,
    required this.aic,
    required this.sigmaHat,
    required this.fitted,
    required this.residuals,
    required this.excludedRows,
    required this.defaultScoreCount,
    required this.design,
  });
}

class _OlsFit {
  final List<double> beta;
  final List<List<double>> xtxInverse;
  final List<double> fitted;
  final List<double> residuals;
  final double rss;
  final double tss;

  _OlsFit(this.beta, this.xtxInverse, this.fitted, this.residuals, this.rss, this.tss);
}

double _dot(List<double> a, List<double> b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += a[i] * b[i];
  }
  return s;
}

/// 正規方程式 (XᵀX)β̂=Xᵀy を Cholesky 分解で解く最小二乗フィッタ (設計書§2.1.1)。
/// X は線形従属(ランク落ち)の場合 null を返す。
_OlsFit? _fitOls(List<List<double>> x, List<double> y) {
  final n = x.length;
  final p1 = x[0].length;
  final xtx = List.generate(p1, (_) => List<double>.filled(p1, 0.0));
  final xty = List<double>.filled(p1, 0.0);
  for (var i = 0; i < n; i++) {
    for (var a = 0; a < p1; a++) {
      xty[a] += x[i][a] * y[i];
      for (var b = 0; b < p1; b++) {
        xtx[a][b] += x[i][a] * x[i][b];
      }
    }
  }

  List<List<double>> l;
  try {
    l = cholesky(xtx);
  } on StateError {
    return null;
  }

  final beta = choleskySolve(l, xty);
  final inv = choleskyInverse(l);
  final fitted = [for (final row in x) _dot(row, beta)];
  final residuals = [for (var i = 0; i < n; i++) y[i] - fitted[i]];
  final rss = residuals.fold(0.0, (s, e) => s + e * e);
  final yBar = y.reduce((a, b) => a + b) / n;
  final tss = y.fold(0.0, (s, v) => s + (v - yBar) * (v - yBar));
  return _OlsFit(beta, inv, fitted, residuals, rss, tss);
}

/// 変数 j の VIF (設計書 T-10)。j を残りの説明変数(切片込み)で回帰した R² から算出。
double _vifForColumn(List<List<double>> x, int j) {
  final n = x.length;
  final p1 = x[0].length;
  if (p1 <= 2) return 1.0; // 他に説明変数が無い

  final subX = <List<double>>[];
  final subY = <double>[];
  for (var i = 0; i < n; i++) {
    final row = <double>[1.0];
    for (var k = 1; k < p1; k++) {
      if (k == j) continue;
      row.add(x[i][k]);
    }
    subX.add(row);
    subY.add(x[i][j]);
  }
  final fit = _fitOls(subX, subY);
  if (fit == null) return double.nan;
  final r2 = fit.tss > 0 ? 1 - fit.rss / fit.tss : 0.0;
  if ((1 - r2).abs() < 1e-12) return double.infinity;
  return 1 / (1 - r2);
}

/// F1: 重回帰分析サービス (設計書§5.1)。
class RegressionService {
  /// CoffeeRecord群から計画行列を組み、最小データ条件(§1.3: n≥30 かつ n≥5p)を
  /// 満たさなければ null を返す。満たせば [fitDesign] でフィットする。
  RegressionResult? fit(List<CoffeeRecord> records, Map<String, OriginMaster> originById) {
    final design = buildRegressionMatrix(records, originById);
    final n = design.x.length;
    final p = design.columnNames.length - 1;
    if (n == 0 || n < 30 || n < 5 * p) return null;
    return fitDesign(design);
  }

  /// 計画行列から直接フィットする (数値計算の中核。テスト容易性のため
  /// [fit] から分離。設計書§5.1のクラス定義には明記が無いが、
  /// §9.4のテスト(生のx1/x2/yで中心化なしの回帰を検証)を満たすには
  /// CoffeeRecord/OriginMasterを介さない入口が必要なため追加した)。
  RegressionResult? fitDesign(DesignMatrixResult design) {
    final n = design.x.length;
    if (n == 0) return null;
    final p = design.columnNames.length - 1;
    final df = n - p - 1;
    if (df <= 0) return null;

    final fit = _fitOls(design.x, design.y);
    if (fit == null) return null;

    final sigma2 = fit.rss / df;
    final sigmaHat = math.sqrt(sigma2);
    final r2 = fit.tss > 0 ? 1 - fit.rss / fit.tss : (fit.rss == 0 ? 1.0 : 0.0);
    final adjR2 = 1 - (1 - r2) * (n - 1) / df;
    final aic = n * math.log(fit.rss / n) + 2 * (p + 2);

    final coefficients = <RegressionCoefficient>[];
    for (var j = 0; j <= p; j++) {
      final se = math.sqrt(sigma2 * fit.xtxInverse[j][j]);
      final t = fit.beta[j] / se;
      final pValue = 2 * (1 - studentTCdf(t.abs(), df.toDouble()));
      final vif = j == 0 ? double.nan : _vifForColumn(design.x, j);
      coefficients.add(RegressionCoefficient(
        name: design.columnNames[j],
        beta: fit.beta[j],
        se: se,
        tValue: t,
        pValue: pValue,
        vif: vif,
      ));
    }

    return RegressionResult(
      coefficients: coefficients,
      n: n,
      p: p,
      r2: r2,
      adjR2: adjR2,
      aic: aic,
      sigmaHat: sigmaHat,
      fitted: fit.fitted,
      residuals: fit.residuals,
      excludedRows: design.excludedRows,
      defaultScoreCount: design.y.where((v) => v == 7.0).length,
      design: design,
    );
  }

  /// 条件を与えて予測値と95%予測区間 (T-25) を返す。
  ({double point, double lower, double upper}) predict(
    RegressionResult model, {
    required double temperature,
    required double brewRatio,
    required double totalTimeMin,
    required double roastOrdinal,
    required String originLevel,
  }) {
    final design = model.design;
    final tempC = temperature - (design.centerMeans['temperature'] ?? 0);
    final ratioC = brewRatio - (design.centerMeans['brewRatio'] ?? 0);
    final minC = totalTimeMin - (design.centerMeans['totalTimeMin'] ?? 0);
    final roastC = roastOrdinal - (design.centerMeans['roastOrdinal'] ?? 0);

    final xStar = <double>[
      1.0,
      tempC,
      ratioC,
      minC,
      roastC,
      for (final level in design.dummyLevels) (originLevel == level ? 1.0 : 0.0),
      roastC * tempC,
    ];

    final point = _dot(xStar, [for (final c in model.coefficients) c.beta]);

    final fit = _fitOls(design.x, design.y);
    final df = model.n - model.p - 1;
    final xInvX = fit == null ? 0.0 : _quadForm(xStar, fit.xtxInverse);
    final se = model.sigmaHat * math.sqrt(1 + xInvX);
    final tCrit = tQuantile(0.975, df.toDouble());

    return (point: point, lower: point - tCrit * se, upper: point + tCrit * se);
  }

  double _quadForm(List<double> v, List<List<double>> m) {
    var s = 0.0;
    for (var i = 0; i < v.length; i++) {
      var rowSum = 0.0;
      for (var j = 0; j < v.length; j++) {
        rowSum += m[i][j] * v[j];
      }
      s += v[i] * rowSum;
    }
    return s;
  }
}

final regressionServiceProvider = Provider((ref) => RegressionService());
