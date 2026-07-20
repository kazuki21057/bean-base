import 'package:bean_base/models/origin_master.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OriginMaster', () {
    test('json round-trip', () {
      final origin = OriginMaster(
        id: 'origin_1',
        countryCode: 'ET',
        nameJa: 'エチオピア',
        nameEn: 'Ethiopia',
        region: 'アフリカ',
      );

      final json = origin.toJson();
      final restored = OriginMaster.fromJson(json);

      expect(restored.id, origin.id);
      expect(restored.countryCode, origin.countryCode);
      expect(restored.nameJa, origin.nameJa);
      expect(restored.nameEn, origin.nameEn);
      expect(restored.region, origin.region);
    });

    test('数値IDが渡された場合も文字列にキャストされる', () {
      final restored = OriginMaster.fromJson({
        'id': 123,
        'countryCode': 'ET',
        'nameJa': 'エチオピア',
        'nameEn': 'Ethiopia',
        'region': 'アフリカ',
      });
      expect(restored.id, '123');
    });
  });

  group('kInitialOriginMasters', () {
    test('設計書§3.1の初期15件データが揃っている', () {
      expect(kInitialOriginMasters.length, 15);
      final ids = kInitialOriginMasters.map((o) => o.id).toSet();
      expect(ids.length, 15, reason: 'IDが重複していない');
      final countryCodes = kInitialOriginMasters.map((o) => o.countryCode).toSet();
      expect(countryCodes.length, 15, reason: '国コードが重複していない');
    });
  });
}
