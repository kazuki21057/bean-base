import 'package:bean_base/models/bean_master.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BeanMaster T4-1b拡張(originId・roastDate)', () {
    test('json round-trip', () {
      final bean = BeanMaster(
        id: '1',
        name: 'エチオピア イルガチェフェ',
        roastLevel: '浅煎り',
        origin: 'エチオピア',
        originId: 'origin_1',
        roastDate: DateTime(2026, 7, 1),
      );

      final json = bean.toJson();
      final restored = BeanMaster.fromJson(json);

      expect(restored.originId, 'origin_1');
      expect(restored.roastDate, DateTime(2026, 7, 1));
      // 既存フィールドが壊れていないことも確認
      expect(restored.origin, 'エチオピア');
      expect(restored.roastLevel, '浅煎り');
    });

    test('originId・roastDate未設定の既存データはデフォルト値になる', () {
      final restored = BeanMaster.fromJson({
        'id': '1',
        'name': '既存の豆',
        'roastLevel': '中煎り',
        'origin': 'ブラジル',
      });
      expect(restored.originId, '');
      expect(restored.roastDate, isNull);
    });

    test('copyWithでoriginId・roastDateを更新できる', () {
      final bean = BeanMaster(
        id: '1',
        name: '豆',
        roastLevel: '中煎り',
        origin: 'ブラジル',
      );
      final updated = bean.copyWith(originId: 'origin_5', roastDate: DateTime(2026, 6, 1));
      expect(updated.originId, 'origin_5');
      expect(updated.roastDate, DateTime(2026, 6, 1));
      expect(updated.name, '豆');
    });
  });
}
