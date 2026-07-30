import 'package:bean_base/models/method_master.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MethodMaster.fromJson 型ガード(T3-52a回帰テスト)', () {
    test('Sheetsが数値で返す grindSize を String に変換する', () {
      final method = MethodMaster.fromJson({
        'id': 'method001',
        'name': 'V60ペーパードリップ',
        'grindSize': 80, // 本番シートの実際の型(数値)
      });

      expect(method.grindSize, '80');
    });

    test('grindSize未設定は null のまま', () {
      final method = MethodMaster.fromJson({
        'id': 'method001',
        'name': 'V60ペーパードリップ',
      });

      expect(method.grindSize, isNull);
    });
  });
}
