import 'dart:math' as math;

import 'package:bean_base/services/math/eigen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('eigenSymmetric', () {
    test('[[2,1],[1,2]] -> eigenvalues [3,1]', () {
      final result = eigenSymmetric([
        [2, 1],
        [1, 2],
      ]);

      expect(result.eigenvalues[0], closeTo(3, 1e-10));
      expect(result.eigenvalues[1], closeTo(1, 1e-10));

      final expectedVec = 1 / math.sqrt(2);
      expect(result.eigenvectors[0][0].abs(), closeTo(expectedVec, 1e-8));
      expect(result.eigenvectors[0][1].abs(), closeTo(expectedVec, 1e-8));
    });

    test('diag(4,2,1) -> eigenvalues [4,2,1], eigenvectors = 単位行列', () {
      final result = eigenSymmetric([
        [4, 0, 0],
        [0, 2, 0],
        [0, 0, 1],
      ]);

      expect(result.eigenvalues, [
        closeTo(4, 1e-10),
        closeTo(2, 1e-10),
        closeTo(1, 1e-10),
      ]);

      final identity = [
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, 1.0],
      ];
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          expect(
            result.eigenvectors[i][j].abs(),
            closeTo(identity[i][j], 1e-8),
          );
        }
      }
    });

    test('ランダム対称6x6: Av=λv・直交性・trace保存', () {
      final rng = math.Random(42);
      const n = 6;
      final raw = List.generate(
        n,
        (_) => List.generate(n, (_) => 2 * rng.nextDouble() - 1),
      );
      final a = List.generate(
        n,
        (i) => List.generate(n, (j) => (raw[i][j] + raw[j][i]) / 2),
      );

      final result = eigenSymmetric(a);

      // (a) ||A*v_i - λ_i*v_i||∞ < 1e-8
      for (var i = 0; i < n; i++) {
        final v = result.eigenvectors[i];
        final lambda = result.eigenvalues[i];
        for (var r = 0; r < n; r++) {
          var avR = 0.0;
          for (var c = 0; c < n; c++) {
            avR += a[r][c] * v[c];
          }
          expect((avR - lambda * v[r]).abs(), lessThan(1e-8));
        }
      }

      // (b) |v_i . v_j| < 1e-8 (i != j)
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          if (i == j) continue;
          var dot = 0.0;
          for (var k = 0; k < n; k++) {
            dot += result.eigenvectors[i][k] * result.eigenvectors[j][k];
          }
          expect(dot.abs(), lessThan(1e-8));
        }
      }

      // (c) Σλ_i = trace(A)
      var trace = 0.0;
      for (var i = 0; i < n; i++) {
        trace += a[i][i];
      }
      final sumEigenvalues = result.eigenvalues.reduce((x, y) => x + y);
      expect((sumEigenvalues - trace).abs(), lessThan(1e-8));
    });

    test('非対称行列 -> ArgumentError', () {
      expect(
        () => eigenSymmetric([
          [1, 2],
          [3, 4],
        ]),
        throwsArgumentError,
      );
    });
  });
}
