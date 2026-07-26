import 'package:bean_base/services/math/encoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roastOrdinalMap (T3-42: 焙煎度8段階統一)', () {
    test('新8段階(日本語)が浅い順に1.0〜8.0で読み取れる', () {
      expect(roastOrdinalMap['ライト'], 1.0);
      expect(roastOrdinalMap['シナモン'], 2.0);
      expect(roastOrdinalMap['ミディアム'], 3.0);
      expect(roastOrdinalMap['ハイ'], 4.0);
      expect(roastOrdinalMap['シティ'], 5.0);
      expect(roastOrdinalMap['フルシティ'], 6.0);
      expect(roastOrdinalMap['フレンチ'], 7.0);
      expect(roastOrdinalMap['イタリアン'], 8.0);
    });

    test('英語(アルファベット表記)でも同じ段階として解釈される', () {
      expect(roastOrdinalMap['Light'], roastOrdinalMap['ライト']);
      expect(roastOrdinalMap['Cinnamon'], roastOrdinalMap['シナモン']);
      expect(roastOrdinalMap['Medium'], roastOrdinalMap['ミディアム']);
      expect(roastOrdinalMap['High'], roastOrdinalMap['ハイ']);
      expect(roastOrdinalMap['City'], roastOrdinalMap['シティ']);
      expect(roastOrdinalMap['Full City'], roastOrdinalMap['フルシティ']);
      expect(roastOrdinalMap['French'], roastOrdinalMap['フレンチ']);
      expect(roastOrdinalMap['Italian'], roastOrdinalMap['イタリアン']);
    });

    test('既存の本番データが使う旧5段階表記が欠測にならず新8段階へ解決される(2026-07-26ユーザー確認済み対応表)', () {
      expect(roastOrdinalMap['浅煎り'], 2.0); // → シナモン
      expect(roastOrdinalMap['中浅煎り'], 3.0); // → ミディアム
      expect(roastOrdinalMap['中煎り'], 4.0); // → ハイ
      expect(roastOrdinalMap['中深煎り'], 5.0); // → シティ
      expect(roastOrdinalMap['深煎り'], 7.0); // → フレンチ
    });

    test('roastLevels8はUIの選択肢として浅い順8件を提供する', () {
      expect(roastLevels8, [
        'ライト',
        'シナモン',
        'ミディアム',
        'ハイ',
        'シティ',
        'フルシティ',
        'フレンチ',
        'イタリアン',
      ]);
      for (final label in roastLevels8) {
        expect(roastOrdinalMap.containsKey(label), isTrue, reason: '$label がroastOrdinalMapに無い');
      }
    });

    test('未知の焙煎度表記は欠測(null)として扱われる', () {
      expect(roastOrdinalMap['謎の焙煎度'], isNull);
    });
  });
}
