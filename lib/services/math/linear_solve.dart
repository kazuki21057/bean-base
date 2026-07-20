import 'dart:math' as math;

/// 対称正定値行列 A の Cholesky 分解 A = L·Lᵀ を返す (L は下三角行列)。
/// 正定値でない場合は [StateError] を投げる。
List<List<double>> cholesky(List<List<double>> a) {
  final n = a.length;
  final l = List.generate(n, (_) => List<double>.filled(n, 0.0));

  for (var i = 0; i < n; i++) {
    for (var j = 0; j <= i; j++) {
      var sum = 0.0;
      for (var k = 0; k < j; k++) {
        sum += l[i][k] * l[j][k];
      }
      if (i == j) {
        final diag = a[i][i] - sum;
        if (diag <= 0) {
          throw StateError('行列が正定値ではありません');
        }
        l[i][j] = math.sqrt(diag);
      } else {
        l[i][j] = (a[i][j] - sum) / l[j][j];
      }
    }
  }
  return l;
}

/// Cholesky 分解済みの下三角行列 [l] を使い、L·Lᵀ x = b を前進・後退代入で解く。
List<double> choleskySolve(List<List<double>> l, List<double> b) {
  final n = l.length;

  final y = List<double>.filled(n, 0.0);
  for (var i = 0; i < n; i++) {
    var sum = 0.0;
    for (var k = 0; k < i; k++) {
      sum += l[i][k] * y[k];
    }
    y[i] = (b[i] - sum) / l[i][i];
  }

  final x = List<double>.filled(n, 0.0);
  for (var i = n - 1; i >= 0; i--) {
    var sum = 0.0;
    for (var k = i + 1; k < n; k++) {
      sum += l[k][i] * x[k];
    }
    x[i] = (y[i] - sum) / l[i][i];
  }
  return x;
}

/// Cholesky 分解済みの下三角行列 [l] から、元の対称正定値行列 A の逆行列を返す
/// (単位ベクトルごとに [choleskySolve] を適用し、列として組み立てる)。
List<List<double>> choleskyInverse(List<List<double>> l) {
  final n = l.length;
  final inv = List.generate(n, (_) => List<double>.filled(n, 0.0));
  for (var col = 0; col < n; col++) {
    final e = List<double>.filled(n, 0.0);
    e[col] = 1.0;
    final x = choleskySolve(l, e);
    for (var row = 0; row < n; row++) {
      inv[row][col] = x[row];
    }
  }
  return inv;
}

/// Cholesky 分解済みの下三角行列 [l] から log|A| = 2·Σ log(Lᵢᵢ) を返す。
double choleskyLogDet(List<List<double>> l) {
  var sum = 0.0;
  for (var i = 0; i < l.length; i++) {
    sum += math.log(l[i][i]);
  }
  return 2 * sum;
}
