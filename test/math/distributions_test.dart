import 'package:bean_base/services/math/distributions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalCdf', () {
    test('normalCdf(0)=0.5, normalCdf(1.959964)=0.975', () {
      expect(normalCdf(0), closeTo(0.5, 1e-12));
      expect(normalCdf(1.959964), closeTo(0.975, 1e-6));
    });
  });

  group('studentTCdf', () {
    test('df=10の代表値', () {
      expect(studentTCdf(2.0, 10), closeTo(0.963306, 1e-5));
      expect(studentTCdf(-2.0, 10), closeTo(0.036694, 1e-5));
      expect(studentTCdf(1.812461, 10), closeTo(0.95, 1e-5));
    });
  });

  group('tQuantile', () {
    test('tQuantile(0.975, 10)=2.228139', () {
      expect(tQuantile(0.975, 10), closeTo(2.228139, 1e-4));
    });

    // 設計書§9.3は tQuantile(0.975, 138)=1.977431 と記載しているが、
    // tools/verify_distributions.py でscipy.stats.t.ppfと突き合わせたところ
    // 1.977431 は df=137 の値であり、df=138 の正しい値は 1.977304 (df=137/138の
    // オフバイワン誤記と判断)。ここでは検証済みの正しい値を使う。
    test('tQuantile(0.975, 138)=1.977304 (設計書記載値はdf=137との誤記、検証済み)', () {
      expect(tQuantile(0.975, 138), closeTo(1.977304, 1e-4));
    });
  });
}
