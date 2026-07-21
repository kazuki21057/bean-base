import 'package:bean_base/services/math/design_matrix.dart';
import 'package:bean_base/services/regression_service.dart';
import 'package:flutter_test/flutter_test.dart';

DesignMatrixResult _rawDesign(List<List<double>> x, List<double> y, List<String> columnNames) {
  return DesignMatrixResult(
    x: x,
    y: y,
    columnNames: columnNames,
    excludedRows: 0,
    categoryCounts: const {},
    centerMeans: const {},
    dummyLevels: const [],
    baseLevel: '',
  );
}

void main() {
  group('RegressionService.fitDesign (設計書§9.4)', () {
    test('固定10行データ(y ~ x1+x2、中心化なし)がnumpy.linalg.lstsqと一致(設計書§9.4、'
        '2026-07-21訂正版。tools/verify_regression.py参照)', () {
      final List<double> x1 = [1.0, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final List<double> x2 = [2.0, 1, 4, 3, 6, 5, 8, 7, 10, 9];
      final List<double> y = [3.1, 3.9, 6.2, 6.8, 9.1, 9.9, 12.2, 12.8, 15.1, 15.9];
      final x = [for (var i = 0; i < 10; i++) [1.0, x1[i], x2[i]]];
      final design = _rawDesign(x, y, ['切片', 'x1', 'x2']);

      final result = RegressionService().fitDesign(design);

      expect(result, isNotNull);
      expect(result!.coefficients[0].beta, closeTo(1.25000, 1e-4));
      expect(result.coefficients[1].beta, closeTo(1.11000, 1e-4));
      expect(result.coefficients[2].beta, closeTo(0.39000, 1e-4));
      expect(result.coefficients[0].se, closeTo(0.04049, 1e-4));
      expect(result.coefficients[1].se, closeTo(0.01880, 1e-4));
      expect(result.coefficients[2].se, closeTo(0.01880, 1e-4));
      expect(result.r2, closeTo(0.99987, 1e-5));
      expect(result.adjR2, closeTo(0.99983, 1e-5));
      expect(result.sigmaHat, closeTo(0.058554, 1e-5));
      expect(result.aic, closeTo(-52.3229, 1e-3));
    });

    test('y=2xを完全に説明するデータでR²=1・残差全0', () {
      final List<double> x1 = [1.0, 2, 3, 4, 5];
      final List<double> y = [2.0, 4, 6, 8, 10];
      final x = [for (final v in x1) [1.0, v]];
      final design = _rawDesign(x, y, ['切片', 'x1']);

      final result = RegressionService().fitDesign(design);

      expect(result, isNotNull);
      expect(result!.r2, closeTo(1.0, 1e-9));
      for (final e in result.residuals) {
        expect(e, closeTo(0.0, 1e-9));
      }
    });

    test('x2=2・x1の完全共線データで線形従属エラー(null)', () {
      final List<double> x1 = [1.0, 2, 3, 4, 5];
      final List<double> y = [3.1, 3.9, 6.2, 6.8, 9.1];
      final x = [for (final v in x1) [1.0, v, 2 * v]];
      final design = _rawDesign(x, y, ['切片', 'x1', 'x2']);

      final result = RegressionService().fitDesign(design);

      expect(result, isNull);
    });
  });
}
