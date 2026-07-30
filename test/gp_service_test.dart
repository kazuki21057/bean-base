import 'dart:math' as math;

import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/services/gp_service.dart';
import 'package:flutter_test/flutter_test.dart';

CoffeeRecord _rec({
  required String methodId,
  required String grinderId,
  required String grindSize,
  required String originId,
  required String roastLevel,
  double temperature = 92,
  double beanWeight = 15,
  double totalWater = 225,
  int totalTime = 150,
  int score = 7,
}) {
  return CoffeeRecord(
    id: 'r',
    brewedAt: DateTime(2026, 7, 20),
    grinderId: grinderId,
    dripperId: '',
    filterId: '',
    beanId: 'b1',
    roastLevel: roastLevel,
    origin: '',
    beanWeight: beanWeight,
    grindSize: grindSize,
    methodId: methodId,
    taste: '',
    concentration: '',
    temperature: temperature,
    bloomingWater: 30,
    totalWater: totalWater,
    bloomingTime: 30,
    totalTime: totalTime,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    scoreOverall: score,
    comment: '',
    originId: originId,
  );
}

void main() {
  group('GpService.fitWithParams / predict (設計書§9.5-1,2、T3-52で4次元化)', () {
    // 標準化後に十分散らばった12点 (温度/比率/秒/正規化粒度)。
    final xs = [
      [85.0, 15.0, 180.0, 0.72],
      [88.0, 16.0, 150.0, 0.44],
      [90.0, 14.0, 200.0, 0.80],
      [92.0, 17.0, 160.0, 0.50],
      [80.0, 15.0, 210.0, 0.65],
      [96.0, 18.0, 120.0, 0.36],
      [84.0, 16.0, 240.0, 0.55],
      [89.0, 15.0, 190.0, 0.75],
      [91.0, 14.5, 170.0, 0.42],
      [86.0, 17.0, 140.0, 0.60],
      [93.0, 16.5, 220.0, 0.48],
      [87.0, 14.0, 130.0, 0.68],
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
        final pred = GpService().predict(
          model!,
          xs[i][0],
          xs[i][1],
          xs[i][2].round(),
          xs[i][3],
        );
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
      final pred = GpService().predict(
        model!,
        farPoint[0],
        farPoint[1],
        farPoint[2].round(),
        farPoint[3],
      );
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

  group('GpService.fitForMethod の行フィルタ (設計書§8.2-3)', () {
    test('methodId違い・粒度未記録・grindSteps未定義のミルの記録は除外される', () {
      final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0, 96.0, 82.0];
      final ratios = [14.5, 15.0, 15.5, 16.0, 16.5, 17.0, 17.5, 18.0];
      final times = [140, 150, 160, 170, 180, 190, 200, 210];
      final grinds = ['10', '12', '14', '16', '18', '11', '13', '15'];
      final scores = [6, 7, 8, 6, 7, 8, 6, 7];

      final validRecords = [
        for (var i = 0; i < 8; i++)
          _rec(
            methodId: 'm1',
            grinderId: 'g1',
            grindSize: grinds[i],
            originId: 'origin_1',
            roastLevel: 'ハイ',
            temperature: temps[i],
            totalWater: 15 * ratios[i],
            totalTime: times[i],
            score: scores[i],
          ),
      ];
      final wrongMethod = [
        _rec(methodId: 'm2', grinderId: 'g1', grindSize: '12', originId: 'origin_1', roastLevel: 'ハイ'),
        _rec(methodId: 'm2', grinderId: 'g1', grindSize: '13', originId: 'origin_1', roastLevel: 'ハイ'),
      ];
      final noGrindSize = [
        _rec(methodId: 'm1', grinderId: 'g1', grindSize: '', originId: 'origin_1', roastLevel: 'ハイ'),
      ];
      final unknownGrinder = [
        _rec(methodId: 'm1', grinderId: 'gDrip', grindSize: '10', originId: 'origin_1', roastLevel: 'ハイ'),
      ];

      final model = GpService().fitForMethod(
        [...validRecords, ...wrongMethod, ...noGrindSize, ...unknownGrinder],
        methodId: 'm1',
        originId: 'origin_1',
        roastOrdinal: 4.0,
        targetGrinderId: 'g1',
        grindStepsByGrinderId: {'g1': 20}, // gDrip は意図的に未登録(ドリップバッグ相当)。
      );

      expect(model, isNotNull);
      expect(model!.nRows, 8);
    });
  });

  group('GpService.fitForMethod の最小データ条件 (設計書§8.2-4)', () {
    List<CoffeeRecord> buildRecords(int n, List<double> weightPattern) {
      final temps = List.generate(n, (i) => 80.0 + (i % 12));
      final ratios = List.generate(n, (i) => 14.0 + (i % 5) * 0.8);
      final times = List.generate(n, (i) => 120 + (i % 8) * 15);
      final grinds = List.generate(n, (i) => (10 + i % 8).toString());
      return [
        for (var i = 0; i < n; i++)
          _rec(
            methodId: 'm1',
            grinderId: weightPattern[i] >= 1.0 ? 'g1' : 'g1', // グリッド不一致は別テストで扱う。
            grindSize: grinds[i],
            originId: weightPattern[i] >= 0.5 ? 'origin_1' : 'origin_9',
            roastLevel: weightPattern[i] >= 0.5 ? 'ハイ' : 'イタリアン',
            temperature: temps[i],
            totalWater: 15 * ratios[i],
            totalTime: times[i],
          ),
      ];
    }

    test('n_eff が6.0未満(nRows=8)なら null', () {
      // 5行 weight1.0 + 3行 weight0.2 = 5.6 < 6.0。
      final pattern = [1.0, 1.0, 1.0, 1.0, 1.0, 0.2, 0.2, 0.2];
      final model = GpService().fitForMethod(
        buildRecords(8, pattern),
        methodId: 'm1',
        originId: 'origin_1',
        roastOrdinal: 4.0,
        targetGrinderId: 'g1',
        grindStepsByGrinderId: {'g1': 20},
      );
      expect(model, isNull);
    });

    test('n_eff が6.0以上かつnRows>=8なら非null', () {
      // 6行 weight1.0 + 2行 weight0.2 = 6.4 >= 6.0。
      final pattern = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.2, 0.2];
      final model = GpService().fitForMethod(
        buildRecords(8, pattern),
        methodId: 'm1',
        originId: 'origin_1',
        roastOrdinal: 4.0,
        targetGrinderId: 'g1',
        grindStepsByGrinderId: {'g1': 20},
      );
      expect(model, isNotNull);
    });

    test('n_eff は十分でも nRows=7 なら null', () {
      final pattern = List<double>.filled(7, 1.0);
      final model = GpService().fitForMethod(
        buildRecords(7, pattern),
        methodId: 'm1',
        originId: 'origin_1',
        roastOrdinal: 4.0,
        targetGrinderId: 'g1',
        grindStepsByGrinderId: {'g1': 20},
      );
      expect(model, isNull);
    });
  });

  group('GpService.fitForMethod のミル不一致の重み (設計書§8.2-5)', () {
    test('目標ミルと異なる記録の重みは半分になる', () {
      final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0, 96.0, 82.0];
      final ratios = [14.5, 15.0, 15.5, 16.0, 16.5, 17.0, 17.5, 18.0];
      final times = [140, 150, 160, 170, 180, 190, 200, 210];
      final grinds = ['10', '12', '14', '16', '9', '11', '13', '15'];

      final sameGrinder = [
        for (var i = 0; i < 4; i++)
          _rec(
            methodId: 'm1',
            grinderId: 'g1',
            grindSize: grinds[i],
            originId: 'origin_1',
            roastLevel: 'ハイ',
            temperature: temps[i],
            totalWater: 15 * ratios[i],
            totalTime: times[i],
          ),
      ];
      final otherGrinder = [
        for (var i = 4; i < 8; i++)
          _rec(
            methodId: 'm1',
            grinderId: 'g2',
            grindSize: grinds[i],
            originId: 'origin_1',
            roastLevel: 'ハイ',
            temperature: temps[i],
            totalWater: 15 * ratios[i],
            totalTime: times[i],
          ),
      ];

      final model = GpService().fitForMethod(
        [...sameGrinder, ...otherGrinder],
        methodId: 'm1',
        originId: 'origin_1',
        roastOrdinal: 4.0,
        targetGrinderId: 'g1',
        grindStepsByGrinderId: {'g1': 20, 'g2': 30},
      );

      expect(model, isNotNull);
      // origin/roast一致(重み1.0) × (g1: 1.0, g2: 0.5) = 4*1.0 + 4*0.5 = 6.0。
      expect(model!.nEff, closeTo(6.0, 1e-9));
    });
  });

  group('GpService.optimize の粗/細グリッド (設計書§8.2-6)', () {
    test('refine:true の best.mean は refine:false の best.mean 以上', () {
      final temps = [82.0, 85.0, 88.0, 91.0, 94.0, 80.0, 96.0, 87.0, 90.0, 83.0, 93.0, 89.0];
      final ratios = [14.5, 15.0, 15.5, 16.0, 16.5, 17.0, 17.5, 18.0, 14.0, 16.2, 15.8, 17.2];
      final times = [130, 145, 160, 175, 190, 205, 220, 135, 150, 165, 180, 195];
      final grinds = ['9', '10', '11', '12', '13', '14', '15', '16', '8', '17', '18', '9'];
      final scores = [6, 7, 8, 9, 6, 5, 7, 8, 6, 7, 8, 9];

      final records = [
        for (var i = 0; i < 12; i++)
          _rec(
            methodId: 'm1',
            grinderId: 'g1',
            grindSize: grinds[i],
            originId: 'origin_1',
            roastLevel: 'ハイ',
            temperature: temps[i],
            totalWater: 15 * ratios[i],
            totalTime: times[i],
            score: scores[i],
          ),
      ];

      final model = GpService().fitForMethod(
        records,
        methodId: 'm1',
        originId: 'origin_1',
        roastOrdinal: 4.0,
        targetGrinderId: 'g1',
        grindStepsByGrinderId: {'g1': 20},
      );
      expect(model, isNotNull);

      final coarse = GpService().optimize(model!, refine: false);
      final refined = GpService().optimize(model, refine: true);

      expect(refined.best.mean, greaterThanOrEqualTo(coarse.best.mean - 1e-9));
    });
  });
}
