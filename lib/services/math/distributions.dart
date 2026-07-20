import 'dart:math' as math;

/// 標準正規分布の確率密度関数 φ(z) = exp(−z²/2)/√(2π)
double normalPdf(double z) {
  return math.exp(-z * z / 2) / math.sqrt(2 * math.pi);
}

/// 標準正規分布の累積分布関数 Φ(z) = 0.5·(1+erf(z/√2))
double normalCdf(double z) {
  return 0.5 * (1 + erf(z / math.sqrt2));
}

/// 誤差関数 erf(x) (Abramowitz–Stegun 7.1.26 近似、|誤差|<1.5e-7)。
/// x=0 は近似多項式の丸め誤差(係数和が1にわずかに満たない)により
/// ~1e-9 の残差が出るため、厳密値 0 を特別扱いする
/// (`tools/verify_distributions.py` で確認済み)。
double erf(double x) {
  if (x == 0.0) return 0.0;

  final sign = x >= 0 ? 1.0 : -1.0;
  final ax = x.abs();

  const p = 0.3275911;
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;

  final t = 1.0 / (1.0 + p * ax);
  final poly = (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t;
  final y = 1.0 - poly * math.exp(-ax * ax);
  return sign * y;
}

const int _lanczosG = 7;
const List<double> _lanczosCoef = [
  0.99999999999980993,
  676.5203681218851,
  -1259.1392167224028,
  771.32342877765313,
  -176.61502916214059,
  12.507343278686905,
  -0.13857109526572012,
  9.9843695780195716e-6,
  1.5056327351493116e-7,
];

/// log(Γ(x)) の Lanczos 近似 (g=7, n=9、正則化不完全ベータ関数の内部計算専用)。
double _logGamma(double x) {
  if (x < 0.5) {
    return math.log(math.pi / math.sin(math.pi * x)) - _logGamma(1 - x);
  }
  final xm1 = x - 1;
  var a = _lanczosCoef[0];
  for (var i = 1; i <= _lanczosG + 1; i++) {
    a += _lanczosCoef[i] / (xm1 + i);
  }
  final t = xm1 + _lanczosG + 0.5;
  return 0.5 * math.log(2 * math.pi) + (xm1 + 0.5) * math.log(t) - t + math.log(a);
}

/// 正則化不完全ベータ関数 I_x(a,b) の連分数展開 (Numerical Recipes の betacf、Lentz 法)。
double _betaContinuedFraction(double a, double b, double x) {
  const maxIterations = 200;
  const eps = 1e-12;
  const fpMin = 1e-300;

  final qab = a + b;
  final qap = a + 1;
  final qam = a - 1;

  var c = 1.0;
  var d = 1.0 - qab * x / qap;
  if (d.abs() < fpMin) d = fpMin;
  d = 1.0 / d;
  var h = d;

  for (var m = 1; m <= maxIterations; m++) {
    final m2 = 2 * m;
    var aa = m * (b - m) * x / ((qam + m2) * (a + m2));
    d = 1.0 + aa * d;
    if (d.abs() < fpMin) d = fpMin;
    c = 1.0 + aa / c;
    if (c.abs() < fpMin) c = fpMin;
    d = 1.0 / d;
    h *= d * c;

    aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
    d = 1.0 + aa * d;
    if (d.abs() < fpMin) d = fpMin;
    c = 1.0 + aa / c;
    if (c.abs() < fpMin) c = fpMin;
    d = 1.0 / d;
    final delta = d * c;
    h *= delta;

    if ((delta - 1.0).abs() < eps) break;
  }
  return h;
}

/// 正則化不完全ベータ関数 I_x(a,b) (連分数展開、Lentz 法、最大200項、tol 1e-12)。
double regularizedIncompleteBeta(double a, double b, double x) {
  if (x < 0 || x > 1) {
    throw ArgumentError('xは[0,1]の範囲でなければなりません');
  }
  if (x == 0.0 || x == 1.0) return x;

  final bt = math.exp(
    _logGamma(a + b) -
        _logGamma(a) -
        _logGamma(b) +
        a * math.log(x) +
        b * math.log(1 - x),
  );

  if (x < (a + 1) / (a + b + 2)) {
    return bt * _betaContinuedFraction(a, b, x) / a;
  } else {
    return 1 - bt * _betaContinuedFraction(b, a, 1 - x) / b;
  }
}

/// t 分布の累積分布関数。
/// t ≥ 0 のとき F(t;ν) = 1 − ½·I_{ν/(ν+t²)}(ν/2, ½)、t<0 は対称性で処理。
double studentTCdf(double t, double df) {
  final x = df / (df + t * t);
  final ib = regularizedIncompleteBeta(df / 2, 0.5, x);
  return t >= 0 ? 1 - 0.5 * ib : 0.5 * ib;
}

/// t 分布の分位点関数 (studentTCdf の二分法逆関数、区間 [-50,50]、tol 1e-9)。
double tQuantile(double p, double df) {
  var lo = -50.0;
  var hi = 50.0;
  while (hi - lo > 1e-9) {
    final mid = (lo + hi) / 2;
    if (studentTCdf(mid, df) < p) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}
