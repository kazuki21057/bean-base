import 'dart:math' as math;

/// 実対称行列の固有値分解の結果。
/// [eigenvalues] は降順ソート済み、[eigenvectors][i] が [eigenvalues][i] に対応する単位ベクトル。
class EigenResult {
  final List<double> eigenvalues;
  final List<List<double>> eigenvectors;

  const EigenResult(this.eigenvalues, this.eigenvectors);
}

/// 実対称行列の固有値分解 (古典的巡回 Jacobi 法)。
/// Golub & Van Loan, *Matrix Computations* 4th ed., §8.5。
///
/// [a] は対称行列でなければならない (非対称なら [ArgumentError])。
EigenResult eigenSymmetric(
  List<List<double>> a, {
  int maxSweeps = 50,
  double tol = 1e-12,
}) {
  final n = a.length;
  for (final row in a) {
    if (row.length != n) {
      throw ArgumentError('正方行列ではありません');
    }
  }
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (a[i][j] != a[j][i]) {
        throw ArgumentError('対称行列ではありません');
      }
    }
  }

  final m = List.generate(n, (i) => List<double>.from(a[i]));
  final v = List.generate(
    n,
    (i) => List<double>.generate(n, (j) => i == j ? 1.0 : 0.0),
  );

  double frobeniusNorm() {
    var s = 0.0;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        s += m[i][j] * m[i][j];
      }
    }
    return math.sqrt(s);
  }

  double offNorm() {
    var s = 0.0;
    for (var p = 0; p < n; p++) {
      for (var q = p + 1; q < n; q++) {
        s += m[p][q] * m[p][q];
      }
    }
    return math.sqrt(s);
  }

  var converged = n <= 1;
  for (var sweep = 0; sweep < maxSweeps && !converged; sweep++) {
    for (var p = 0; p < n - 1; p++) {
      for (var q = p + 1; q < n; q++) {
        final apq = m[p][q];
        if (apq == 0.0) continue;

        final theta = (m[q][q] - m[p][p]) / (2 * apq);
        final sign = theta >= 0 ? 1.0 : -1.0;
        final t = sign / (theta.abs() + math.sqrt(theta * theta + 1));
        final c = 1.0 / math.sqrt(t * t + 1);
        final s = t * c;

        final app = m[p][p];
        final aqq = m[q][q];
        m[p][p] = c * c * app - 2 * s * c * apq + s * s * aqq;
        m[q][q] = s * s * app + 2 * s * c * apq + c * c * aqq;
        m[p][q] = 0.0;
        m[q][p] = 0.0;

        for (var i = 0; i < n; i++) {
          if (i == p || i == q) continue;
          final aip = m[i][p];
          final aiq = m[i][q];
          m[i][p] = c * aip - s * aiq;
          m[p][i] = m[i][p];
          m[i][q] = s * aip + c * aiq;
          m[q][i] = m[i][q];
        }

        for (var i = 0; i < n; i++) {
          final vip = v[i][p];
          final viq = v[i][q];
          v[i][p] = c * vip - s * viq;
          v[i][q] = s * vip + c * viq;
        }
      }
    }

    final normA = frobeniusNorm();
    final threshold = tol * (normA == 0 ? 1.0 : normA);
    if (offNorm() < threshold) {
      converged = true;
    }
  }

  if (!converged) {
    throw StateError('Jacobi法が収束しませんでした');
  }

  final eigenvalues = List<double>.generate(n, (i) => m[i][i]);
  final order = List<int>.generate(n, (i) => i)
    ..sort((x, y) => eigenvalues[y].compareTo(eigenvalues[x]));

  return EigenResult(
    [for (final i in order) eigenvalues[i]],
    [
      for (final i in order)
        [for (var r = 0; r < n; r++) v[r][i]],
    ],
  );
}
