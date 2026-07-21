import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coffee_record.dart';
import '../models/origin_master.dart';
import 'math/distributions.dart';
import 'math/encoding.dart';
import 'math/linear_solve.dart';

/// F4: ガウス過程回帰の学習済みモデル (設計書§7.5)。
class GpModel {
  final List<List<double>> xTrain; // 標準化済み訓練入力
  final List<double> xMean;
  final List<double> xStd;
  final double yMean;
  final List<List<double>> cholL; // K = L·Lᵀ の L
  final List<double> alpha; // K⁻¹(y-yMean)
  final double lengthScale;
  final double sigmaF;
  final double sigmaN;
  final double fStar; // 訓練データの max(y) (生値、EI用)
  final double nEff; // 重み付き有効サンプルサイズ Σwᵢ

  GpModel({
    required this.xTrain,
    required this.xMean,
    required this.xStd,
    required this.yMean,
    required this.cholL,
    required this.alpha,
    required this.lengthScale,
    required this.sigmaF,
    required this.sigmaN,
    required this.fStar,
    required this.nEff,
  });
}

/// 1点での予測結果 (設計書§7.5)。[sd] は潜在関数の事後標準偏差 (T-19、
/// 観測ノイズ σ_n² を含まない)。予測区間として表示する際は
/// √(sd²+σ_n²) を呼び出し側で計算する (設計書§2.5)。
class GpPrediction {
  final double mean;
  final double sd;
  final double ei;

  GpPrediction({required this.mean, required this.sd, required this.ei});
}

double _dot(List<double> a, List<double> b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += a[i] * b[i];
  }
  return s;
}

/// RBF カーネル (T-16、[a][b] は標準化済み入力)。
double _kernel(List<double> a, List<double> b, double lengthScale, double sigmaF) {
  var sqDist = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    sqDist += d * d;
  }
  return sigmaF * sigmaF * math.exp(-sqDist / (2 * lengthScale * lengthScale));
}

/// 期待改善量 (Expected Improvement、T-21)。σ=0 のときは貪欲な活用に一致する。
double expectedImprovement(double mu, double sigma, double fStar, {double xi = 0.01}) {
  final improvement = mu - fStar - xi;
  if (sigma <= 0) return math.max(improvement, 0.0);
  final z = improvement / sigma;
  return improvement * normalCdf(z) + sigma * normalPdf(z);
}

class _ModelFit {
  final GpModel model;
  final double logLik;
  _ModelFit(this.model, this.logLik);
}

/// F4: GP 推薦エンジン (設計書§7.5)。
class GpService {
  static const _lengthScaleGrid = [0.5, 1.0, 2.0];
  static const _sigmaFGrid = [0.5, 1.0, 2.0];
  static const _sigmaNGrid = [0.5, 1.0, 1.5];

  /// [originId]・[roastOrdinal] の豆向けに、全記録を重み付き学習データとして
  /// GP をフィットする。重み (設計書§7.5): 同一グループ1.0 / 同産地・焙煎差1
  /// 以内0.5 / その他0.2。n_eff = Σwᵢ < 10 なら null。
  ///
  /// [originById] は設計書のシグネチャ通り受け取るが、重み判定はoriginId・
  /// roastOrdinalMapの直接比較のみで完結するため中身は参照しない
  /// (suggestion_service.dartのoriginByIdと同じ扱い)。
  GpModel? fit(
    List<CoffeeRecord> records,
    String originId,
    double roastOrdinal,
    Map<String, OriginMaster> originById,
  ) {
    final xsRaw = <List<double>>[];
    final ys = <double>[];
    final weights = <double>[];

    for (final r in records) {
      final ratio = r.brewRatio;
      if (r.scoreOverall <= 0 || ratio == null || r.temperature <= 0 || r.totalTime <= 0) {
        continue;
      }
      final recordRoastOrdinal = roastOrdinalMap[r.roastLevel];
      double weight;
      if (r.originId == originId && recordRoastOrdinal == roastOrdinal) {
        weight = 1.0;
      } else if (r.originId == originId &&
          recordRoastOrdinal != null &&
          (recordRoastOrdinal - roastOrdinal).abs() <= 1) {
        weight = 0.5;
      } else {
        weight = 0.2;
      }
      xsRaw.add([r.temperature, ratio, r.totalTime.toDouble()]);
      ys.add(r.scoreOverall.toDouble());
      weights.add(weight);
    }

    final nEff = weights.fold(0.0, (s, w) => s + w);
    if (nEff < 10) return null;

    return _fitGrid(xsRaw, ys, weights, nEff);
  }

  /// 固定グリッド (設計書§2.3.2) で対数周辺尤度 (T-20) 最大の (ℓ,σ_f,σ_n) を選ぶ。
  GpModel? _fitGrid(List<List<double>> xsRaw, List<double> ys, List<double> weights, double nEff) {
    _ModelFit? best;
    for (final l in _lengthScaleGrid) {
      for (final sf in _sigmaFGrid) {
        for (final sn in _sigmaNGrid) {
          final fit = _buildModel(xsRaw, ys, weights, l, sf, sn, nEff);
          if (fit == null) continue;
          if (best == null || fit.logLik > best.logLik) best = fit;
        }
      }
    }
    return best?.model;
  }

  /// テスト容易性のため、θ (ℓ,σ_f,σ_n) を固定して直接フィットする入口を公開
  /// (設計書のクラス定義には無いが、regression_service.dartのfitDesignと同じ
  /// 理由づけ。§9.5のテストはグリッド探索やCoffeeRecordパイプラインを介さず
  /// 特定のθでの予測分布の性質を検証する必要があるため)。
  GpModel? fitWithParams(
    List<List<double>> xsRaw,
    List<double> ys,
    List<double> weights, {
    required double lengthScale,
    required double sigmaF,
    required double sigmaN,
  }) {
    final nEff = weights.fold(0.0, (s, w) => s + w);
    return _buildModel(xsRaw, ys, weights, lengthScale, sigmaF, sigmaN, nEff)?.model;
  }

  _ModelFit? _buildModel(
    List<List<double>> xsRaw,
    List<double> ys,
    List<double> weights,
    double lengthScale,
    double sigmaF,
    double sigmaN,
    double nEff,
  ) {
    final n = xsRaw.length;
    final d = xsRaw[0].length;

    final xMean = List<double>.filled(d, 0.0);
    for (final row in xsRaw) {
      for (var j = 0; j < d; j++) {
        xMean[j] += row[j];
      }
    }
    for (var j = 0; j < d; j++) {
      xMean[j] /= n;
    }

    final xStd = List<double>.filled(d, 0.0);
    for (final row in xsRaw) {
      for (var j = 0; j < d; j++) {
        final diff = row[j] - xMean[j];
        xStd[j] += diff * diff;
      }
    }
    for (var j = 0; j < d; j++) {
      xStd[j] = math.sqrt(xStd[j] / n);
      if (xStd[j] == 0) xStd[j] = 1.0; // 分散0の次元でのゼロ割回避
    }

    final xTrain = [
      for (final row in xsRaw)
        [for (var j = 0; j < d; j++) (row[j] - xMean[j]) / xStd[j]],
    ];

    final yMean = ys.reduce((a, b) => a + b) / n;
    final yCentered = [for (final v in ys) v - yMean];

    final k = List.generate(n, (_) => List<double>.filled(n, 0.0));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        k[i][j] = _kernel(xTrain[i], xTrain[j], lengthScale, sigmaF);
      }
      k[i][i] += (sigmaN * sigmaN) / weights[i];
    }

    List<List<double>> l;
    try {
      l = cholesky(k);
    } on StateError {
      return null;
    }

    final alpha = choleskySolve(l, yCentered);
    final logDet = choleskyLogDet(l);
    final logLik = -0.5 * _dot(yCentered, alpha) - 0.5 * logDet - (n / 2) * math.log(2 * math.pi);
    final fStar = ys.reduce(math.max);

    final model = GpModel(
      xTrain: xTrain,
      xMean: xMean,
      xStd: xStd,
      yMean: yMean,
      cholL: l,
      alpha: alpha,
      lengthScale: lengthScale,
      sigmaF: sigmaF,
      sigmaN: sigmaN,
      fStar: fStar,
      nEff: nEff,
    );
    return _ModelFit(model, logLik);
  }

  /// 新規条件 (湯温・比率・総抽出時間秒) での予測 (T-18/T-19) + EI (T-21)。
  GpPrediction predict(GpModel model, double temperature, double brewRatio, int totalTimeSec) {
    final xRaw = [temperature, brewRatio, totalTimeSec.toDouble()];
    final xStar = [
      for (var j = 0; j < xRaw.length; j++) (xRaw[j] - model.xMean[j]) / model.xStd[j],
    ];

    final kStar = [
      for (final xi in model.xTrain) _kernel(xStar, xi, model.lengthScale, model.sigmaF),
    ];
    final mean = _dot(kStar, model.alpha) + model.yMean;

    final v = choleskySolve(model.cholL, kStar);
    final kxx = model.sigmaF * model.sigmaF; // RBFのk(x*,x*)=σf² (距離0)
    var variance = kxx - _dot(kStar, v);
    if (variance < 0) variance = 0.0;
    final sd = math.sqrt(variance);

    final ei = expectedImprovement(mean, sd, model.fStar);

    return GpPrediction(mean: mean, sd: sd, ei: ei);
  }

  /// 候補グリッド (設計書§2.3.3: 湯温80-96℃刻み1、brew ratio 14.0-18.0刻み0.5、
  /// 時間120-240秒刻み15) の全点でμ・EIを評価し、μ最大点と EI 最大点を返す。
  ({
    GpPrediction best,
    ({double t, double r, int s}) bestX,
    GpPrediction explore,
    ({double t, double r, int s}) exploreX,
  }) optimize(GpModel model) {
    GpPrediction? bestPred;
    ({double t, double r, int s})? bestX;
    GpPrediction? explorePred;
    ({double t, double r, int s})? exploreX;

    for (var tInt = 80; tInt <= 96; tInt++) {
      final t = tInt.toDouble();
      for (var ri = 0; ri <= 8; ri++) {
        final r = 14.0 + ri * 0.5;
        for (var s = 120; s <= 240; s += 15) {
          final pred = predict(model, t, r, s);
          if (bestPred == null || pred.mean > bestPred.mean) {
            bestPred = pred;
            bestX = (t: t, r: r, s: s);
          }
          if (explorePred == null || pred.ei > explorePred.ei) {
            explorePred = pred;
            exploreX = (t: t, r: r, s: s);
          }
        }
      }
    }

    return (best: bestPred!, bestX: bestX!, explore: explorePred!, exploreX: exploreX!);
  }
}

final gpServiceProvider = Provider((ref) => GpService());
