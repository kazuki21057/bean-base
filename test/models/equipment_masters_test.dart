import 'package:bean_base/models/equipment_masters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GrinderMaster.grindSteps', () {
    test('数値文字列を段階数として返す', () {
      expect(
        GrinderMaster(id: 'M001', name: 'Timemore c3 pro', grindRange: '20')
            .grindSteps,
        20,
      );
      expect(
        GrinderMaster(id: 'M002', name: 'Kingrinder K6', grindRange: '180')
            .grindSteps,
        180,
      );
    });

    test('0・null・空文字・解析不能な文字列は null', () {
      expect(
        GrinderMaster(id: '916e917a', name: 'ドリップバッグ', grindRange: '0')
            .grindSteps,
        isNull,
      );
      expect(
        GrinderMaster(id: 'x', name: 'x', grindRange: null).grindSteps,
        isNull,
      );
      expect(
        GrinderMaster(id: 'x', name: 'x', grindRange: '').grindSteps,
        isNull,
      );
      expect(
        GrinderMaster(id: 'x', name: 'x', grindRange: 'abc').grindSteps,
        isNull,
      );
    });
  });

  group('GrinderMaster.fromJson 型ガード(T3-52a回帰テスト)', () {
    test('Sheetsが数値で返す grindRange を String に変換する', () {
      final grinder = GrinderMaster.fromJson({
        'id': 'M002',
        'name': 'Kingrinder K6',
        'grindRange': 180, // 本番シートの実際の型(数値)
      });

      expect(grinder.grindRange, '180');
      expect(grinder.grindSteps, 180);
    });
  });
}
