import 'dart:math' as math;

import 'package:bean_base/services/math/linear_solve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cholesky / choleskySolve / choleskyLogDet', () {
    test('A=[[4,2],[2,3]], b=[10,8] -> L=[[2,0],[1,√2]], x=[1.75,1.5]', () {
      final a = [
        [4.0, 2.0],
        [2.0, 3.0],
      ];
      final l = cholesky(a);

      expect(l[0][0], closeTo(2, 1e-10));
      expect(l[0][1], closeTo(0, 1e-10));
      expect(l[1][0], closeTo(1, 1e-10));
      expect(l[1][1], closeTo(math.sqrt(2), 1e-10));

      final x = choleskySolve(l, [10, 8]);
      expect(x[0], closeTo(1.75, 1e-10));
      expect(x[1], closeTo(1.5, 1e-10));

      expect(choleskyLogDet(l), closeTo(math.log(8), 1e-10));
    });

    test('非正定値 [[1,2],[2,1]] -> StateError', () {
      expect(
        () => cholesky([
          [1.0, 2.0],
          [2.0, 1.0],
        ]),
        throwsStateError,
      );
    });
  });

  group('choleskyInverse', () {
    test('対称正定値行列の逆行列が A·A⁻¹=I を満たす', () {
      final a = [
        [4.0, 2.0, 0.0],
        [2.0, 5.0, 1.0],
        [0.0, 1.0, 3.0],
      ];
      final l = cholesky(a);
      final inv = choleskyInverse(l);

      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          var sum = 0.0;
          for (var k = 0; k < 3; k++) {
            sum += a[i][k] * inv[k][j];
          }
          expect(sum, closeTo(i == j ? 1.0 : 0.0, 1e-8));
        }
      }
    });
  });
}
