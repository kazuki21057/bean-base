import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/services/preference_service.dart';
import 'package:flutter_test/flutter_test.dart';

CoffeeRecord _record(String id, int score, {String origin = '', String roastLevel = '浅煎り'}) {
  return CoffeeRecord(
    id: id,
    brewedAt: DateTime(2026, 7, 21),
    beanId: 'b',
    methodId: 'm',
    beanWeight: 15,
    totalWater: 225,
    totalTime: 150,
    scoreOverall: score,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    taste: '',
    comment: '',
    grindSize: '',
    temperature: 90,
    dripperId: '',
    filterId: '',
    grinderId: '',
    roastLevel: roastLevel,
    origin: origin,
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

void main() {
  group('PreferenceService (T4-4a, §9.6)', () {
    // 設計書§9.6のフィクスチャ: グループA(エチオピア×浅煎り)=[8,9,8,9,8](n=5,平均8.4)。
    // 残り10件は「合計すると[5,6,5,6,5,6,5,6,5,6](平均5.5)」だが、Bonferroni補正の
    // グループ数m=1(検定対象=n>=5のグループのみ)にするため、5つの異なる産地×焙煎度
    // (いずれもn=2<5で検定対象外)に分散させて配置する。
    final groupA = [
      _record('a1', 8, origin: 'エチオピア', roastLevel: '浅煎り'),
      _record('a2', 9, origin: 'エチオピア', roastLevel: '浅煎り'),
      _record('a3', 8, origin: 'エチオピア', roastLevel: '浅煎り'),
      _record('a4', 9, origin: 'エチオピア', roastLevel: '浅煎り'),
      _record('a5', 8, origin: 'エチオピア', roastLevel: '浅煎り'),
    ];
    final restGroups = [
      [_record('r1', 5, origin: 'ブラジル', roastLevel: '中煎り'), _record('r2', 6, origin: 'ブラジル', roastLevel: '中煎り')],
      [_record('r3', 5, origin: 'コロンビア', roastLevel: '中深煎り'), _record('r4', 6, origin: 'コロンビア', roastLevel: '中深煎り')],
      [_record('r5', 5, origin: 'グアテマラ', roastLevel: '深煎り'), _record('r6', 6, origin: 'グアテマラ', roastLevel: '深煎り')],
      [_record('r7', 5, origin: 'ケニア', roastLevel: '中浅煎り'), _record('r8', 6, origin: 'ケニア', roastLevel: '中浅煎り')],
      [_record('r9', 5, origin: 'ホンジュラス', roastLevel: '浅煎り'), _record('r10', 6, origin: 'ホンジュラス', roastLevel: '浅煎り')],
    ];
    final records = [...groupA, ...restGroups.expand((g) => g)];

    test('グループAの平均・CI・Welch検定・significantがscipy検証値と一致する (許差1e-4)', () {
      final profile = PreferenceService().build(records, {});

      final a = profile.groups.firstWhere((g) => g.originLevel == 'エチオピア' && g.roastLabel == '浅煎り');

      expect(a.n, 5);
      expect(a.mean, closeTo(8.4, 1e-9));
      expect(a.sd, closeTo(0.547723, 1e-6));

      // T-22: t_{0.975,4}=2.776445 → 8.4±0.680087 (tools/verify_preference.py で検証済み)
      expect(a.ciLower, closeTo(7.719913, 1e-4));
      expect(a.ciUpper, closeTo(9.080087, 1e-4));

      // T-23/T-24: scipy.stats.ttest_ind(equal_var=False)と一致 (§9.6訂正後の値)
      expect(a.welchT, closeTo(9.788265, 1e-4));
      expect(a.welchP, closeTo(1.17011564e-05, 1e-9));

      // 検定対象(n>=5)はグループAのみなのでm=1、Bonferroni補正後もp<0.05で有意。
      expect(a.significant, isTrue);
    });

    test('n<5のグループはWelch検定を行わずsignificant=falseになる', () {
      final profile = PreferenceService().build(records, {});
      final small = profile.groups.where((g) => g.originLevel != 'エチオピア');

      for (final g in small) {
        expect(g.n, lessThan(5));
        expect(g.welchT, isNull);
        expect(g.welchP, isNull);
        expect(g.significant, isFalse);
      }
    });

    test('groupsはmean降順、statementsは有意なグループのみ固定テンプレートで生成される', () {
      final profile = PreferenceService().build(records, {});

      // mean降順
      for (var i = 1; i < profile.groups.length; i++) {
        expect(profile.groups[i - 1].mean, greaterThanOrEqualTo(profile.groups[i].mean));
      }

      expect(profile.totalRecords, records.length);
      expect(profile.statements.length, 1);
      expect(profile.statements.first, contains('「エチオピア×浅煎り」を高評価する傾向'));
      expect(profile.statements.first, contains('平均8.4'));
      expect(profile.statements.first, contains('p=0.000'));
    });

    test('有意なグループが無い場合は固定の案内文を返す', () {
      // 全記録が同一グループ(比較対象の「残り」が存在しないため誰も検定されない)。
      final flatRecords = [
        for (var i = 0; i < 6; i++) _record('f$i', 7, origin: 'ブレンド', roastLevel: '中煎り'),
      ];
      final profile = PreferenceService().build(flatRecords, {});

      expect(profile.statements, ['現時点で統計的に明確な好みの偏りは検出されていません (データ蓄積中)']);
    });

    test('originIdがOriginMasterで解決できればそちらを優先し、無ければ自由入力originにフォールバックする', () {
      final withOriginId = _record('o1', 8, origin: '自由入力産地', roastLevel: '浅煎り')
          .copyWith(originId: 'origin_1');
      final withoutOriginId = _record('o2', 8, origin: '自由入力産地2', roastLevel: '浅煎り');

      final origins = {
        'origin_1': OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
      };

      final profile = PreferenceService().build([withOriginId, withoutOriginId], origins);

      final levels = profile.groups.map((g) => g.originLevel).toSet();
      expect(levels, {'エチオピア', '自由入力産地2'});
    });

    test('焙煎度が未知(roastOrdinalMapに無い)の行は除外される', () {
      final unknown = _record('u1', 8, roastLevel: '謎の焙煎度');
      final known = _record('k1', 8, roastLevel: '浅煎り');

      final profile = PreferenceService().build([unknown, known], {});

      expect(profile.totalRecords, 1);
    });
  });
}
