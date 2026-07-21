import 'dart:math' as math;

import 'package:bean_base/services/gp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GpService.fitWithParams / predict (設計書§9.5-1,2)', () {
    // 標準化後に十分散らばった12点 (温度/比率/秒)。tools/verify_gp.py で
    // numpy実装との一致(maxerr 2e-12, maxsd 1e-6, far sd 1.0)を確認済み。
    final xs = [
      [85.0, 15.0, 180.0],
      [88.0, 16.0, 150.0],
      [90.0, 14.0, 200.0],
      [92.0, 17.0, 160.0],
      [80.0, 15.0, 210.0],
      [96.0, 18.0, 120.0],
      [84.0, 16.0, 240.0],
      [89.0, 15.0, 190.0],
      [91.0, 14.5, 170.0],
      [86.0, 17.0, 140.0],
      [93.0, 16.5, 220.0],
      [87.0, 14.0, 130.0],
    ];
    final ys = [7.0, 8.0, 6.0, 7.5, 6.5, 8.5, 7.0, 7.2, 6.8, 7.8, 7.3, 6.2];
    final weights = List<double>.filled(12, 1.0);

    test('σ_n=1e-6 で訓練点上の予測meanが訓練yに一致(誤差1e-3)、sd<1e-2', () {
      final model = GpService().fitWithParams(
        xs,
        ys,
        weights,
        lengthScale: 1.0,
        sigmaF: 1.0,
        sigmaN: 1e-6,
      );
      expect(model, isNotNull);

      for (var i = 0; i < xs.length; i++) {
        final pred = GpService().predict(model!, xs[i][0], xs[i][1], xs[i][2].round());
        expect(pred.mean, closeTo(ys[i], 1e-3));
        expect(pred.sd, lessThan(1e-2));
      }
    });

    test('訓練データから十分遠い点(標準化後+10)のsd ≈ σ_f', () {
      final model = GpService().fitWithParams(
        xs,
        ys,
        weights,
        lengthScale: 1.0,
        sigmaF: 1.0,
        sigmaN: 1e-6,
      );
      expect(model, isNotNull);

      final d = xs[0].length;
      final xMean = List<double>.filled(d, 0.0);
      for (final row in xs) {
        for (var j = 0; j < d; j++) {
          xMean[j] += row[j];
        }
      }
      for (var j = 0; j < d; j++) {
        xMean[j] /= xs.length;
      }
      final xStd = List<double>.filled(d, 0.0);
      for (final row in xs) {
        for (var j = 0; j < d; j++) {
          final diff = row[j] - xMean[j];
          xStd[j] += diff * diff;
        }
      }
      for (var j = 0; j < d; j++) {
        xStd[j] = math.sqrt(xStd[j] / xs.length);
      }

      final farPoint = [for (var j = 0; j < d; j++) xMean[j] + 10 * xStd[j]];
      final pred = GpService().predict(model!, farPoint[0], farPoint[1], farPoint[2].round());
      expect(pred.sd, closeTo(1.0, 1e-2)); // σ_f=1.0
    });
  });

  group('expectedImprovement (設計書§9.5-3, T-21)', () {
    test('μ-f*-ξ=0.5, σ=1e-9 のときEI≈0.5', () {
      final ei = expectedImprovement(0.51, 1e-9, 0.0);
      expect(ei, closeTo(0.5, 1e-6));
    });

    test('μ-f*-ξ=-0.5, σ=1e-9 のときEI<1e-6', () {
      final ei = expectedImprovement(-0.49, 1e-9, 0.0);
      expect(ei, lessThan(1e-6));
    });

    test('σ=1, μ=f*+ξ のときEI=φ(0)=0.398942', () {
      final ei = expectedImprovement(0.01, 1.0, 0.0);
      expect(ei, closeTo(0.398942, 1e-4));
    });
  });
}
