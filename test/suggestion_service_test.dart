import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/recipe_suggestion.dart';
import 'package:bean_base/services/suggestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

CoffeeRecord _record({
  required String id,
  required String originId,
  required String roastLevel,
  required int scoreOverall,
  required double temperature,
  required double beanWeight,
  required double totalWater,
  required int totalTime,
  DateTime? brewedAt,
}) {
  return CoffeeRecord(
    id: id,
    brewedAt: brewedAt ?? DateTime(2026, 7, 1),
    beanId: 'other-bean',
    methodId: 'm',
    beanWeight: beanWeight,
    totalWater: totalWater,
    totalTime: totalTime,
    scoreOverall: scoreOverall,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    taste: '',
    comment: '',
    grindSize: '',
    temperature: temperature,
    dripperId: '',
    filterId: '',
    grinderId: '',
    roastLevel: roastLevel,
    origin: '',
    originId: originId,
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

void main() {
  group('SuggestionService (T4-5a, group_bestのみ・GP未接続)', () {
    final bean = BeanMaster(
      id: 'bean1',
      name: 'テスト豆',
      roastLevel: '浅煎り',
      origin: 'エチオピア',
      originId: 'origin_1',
      isInStock: true,
    );

    test('同グループ内でscoreOverallが最も高い記録の条件を提案する', () {
      final records = [
        _record(id: 'r1', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 6, temperature: 88, beanWeight: 15, totalWater: 225, totalTime: 150),
        _record(id: 'r2', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 9, temperature: 92, beanWeight: 20, totalWater: 300, totalTime: 180),
        _record(id: 'r3', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 7, temperature: 90, beanWeight: 15, totalWater: 220, totalTime: 160),
      ];

      final suggestion = SuggestionService().suggestFor(bean, records, {});

      expect(suggestion, isNotNull);
      expect(suggestion!.rationale, 'group_best');
      expect(suggestion.temperature, 92);
      expect(suggestion.brewRatio, closeTo(15.0, 1e-9)); // 300/20
      expect(suggestion.totalTimeSec, 180);
      expect(suggestion.beanId, 'bean1');
      expect(suggestion.originId, 'origin_1');
      expect(suggestion.accepted, '');
      expect(suggestion.resultRecordId, '');
    });

    test('スコアが同点の場合はより新しい記録を優先する', () {
      final records = [
        _record(id: 'old', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 8, temperature: 88, beanWeight: 15, totalWater: 225, totalTime: 150, brewedAt: DateTime(2026, 1, 1)),
        _record(id: 'new', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 8, temperature: 91, beanWeight: 15, totalWater: 225, totalTime: 150, brewedAt: DateTime(2026, 6, 1)),
      ];

      final suggestion = SuggestionService().suggestFor(bean, records, {});

      expect(suggestion!.temperature, 91);
    });

    test('異なる産地・焙煎度の記録は同グループとみなさない', () {
      final records = [
        _record(id: 'r1', originId: 'origin_2', roastLevel: '浅煎り', scoreOverall: 10, temperature: 96, beanWeight: 15, totalWater: 225, totalTime: 150),
        _record(id: 'r2', originId: 'origin_1', roastLevel: '深煎り', scoreOverall: 10, temperature: 96, beanWeight: 15, totalWater: 225, totalTime: 150),
      ];

      final suggestion = SuggestionService().suggestFor(bean, records, {});

      expect(suggestion, isNull);
    });

    test('brewRatioが計算できない記録(豆量0)は候補から除外する', () {
      final records = [
        _record(id: 'r1', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 10, temperature: 96, beanWeight: 0, totalWater: 225, totalTime: 150),
        _record(id: 'r2', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 8, temperature: 90, beanWeight: 15, totalWater: 225, totalTime: 150),
      ];

      final suggestion = SuggestionService().suggestFor(bean, records, {});

      expect(suggestion!.temperature, 90);
    });

    test('同グループの記録が無ければ提案しない(GP未接続のためnullを返す)', () {
      final suggestion = SuggestionService().suggestFor(bean, [], {});
      expect(suggestion, isNull);
    });

    test('豆のoriginIdが未設定なら提案しない', () {
      final beanNoOrigin = BeanMaster(id: 'b2', name: 'テスト豆2', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true);
      final records = [
        _record(id: 'r1', originId: '', roastLevel: '浅煎り', scoreOverall: 9, temperature: 92, beanWeight: 15, totalWater: 225, totalTime: 150),
      ];

      final suggestion = SuggestionService().suggestFor(beanNoOrigin, records, {});

      expect(suggestion, isNull);
    });

    test('豆の焙煎度がroastOrdinalMapで解決できなければ提案しない', () {
      final beanUnknownRoast = BeanMaster(id: 'b3', name: 'テスト豆3', roastLevel: '謎の焙煎度', origin: 'エチオピア', originId: 'origin_1', isInStock: true);
      final records = [
        _record(id: 'r1', originId: 'origin_1', roastLevel: '謎の焙煎度', scoreOverall: 9, temperature: 92, beanWeight: 15, totalWater: 225, totalTime: 150),
      ];

      final suggestion = SuggestionService().suggestFor(beanUnknownRoast, records, {});

      expect(suggestion, isNull);
    });
  });

  group('SuggestionService.suggestWithGp / shouldExplore (T4-6c)', () {
    final bean = BeanMaster(
      id: 'bean1',
      name: 'テスト豆',
      roastLevel: '浅煎り',
      origin: 'エチオピア',
      originId: 'origin_1',
      isInStock: true,
    );

    // origin_1×浅煎りで12件 → 全て weight 1.0、n_eff=12 ≥ 10でGP経路に入る。
    final gpRecords = () {
      final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0];
      final waters = [225.0, 240.0, 210.0, 225.0, 255.0, 210.0];
      final times = [150, 165, 135, 180, 150, 195];
      final scores = [7, 8, 6, 9, 7, 8];
      return [
        for (var i = 0; i < 12; i++)
          _record(
            id: 'g$i',
            originId: 'origin_1',
            roastLevel: '浅煎り',
            scoreOverall: scores[i % 6],
            temperature: temps[i % 6],
            beanWeight: 15,
            totalWater: waters[i % 6],
            totalTime: times[i % 6],
          ),
      ];
    }();

    test('n_eff≥10のときgp_meanを予測スコア+区間つきで返し、条件がグリッド範囲内', () {
      final result = SuggestionService().suggestWithGp(bean, gpRecords, {});

      expect(result, isNotNull);
      expect(result!.suggestion.rationale, 'gp_mean');
      expect(result.isGp, isTrue);
      expect(result.predMean, isNotNull);
      expect(result.predLower, isNotNull);
      expect(result.predUpper, isNotNull);
      expect(result.predLower!, lessThanOrEqualTo(result.predMean!));
      expect(result.predMean!, lessThanOrEqualTo(result.predUpper!));
      // optimizeの候補グリッド(設計書§2.3.3): 湯温80-96/比率14-18/時間120-240。
      expect(result.suggestion.temperature, inInclusiveRange(80, 96));
      expect(result.suggestion.brewRatio, inInclusiveRange(14, 18));
      expect(result.suggestion.totalTimeSec, inInclusiveRange(120, 240));
    });

    test('explore=trueのときはgp_ei(EI最大点)を返す', () {
      final result = SuggestionService().suggestWithGp(bean, gpRecords, {}, explore: true);

      expect(result, isNotNull);
      expect(result!.suggestion.rationale, 'gp_ei');
      expect(result.predMean, isNotNull);
    });

    test('n_eff<10のときはgroup_bestにフォールバックし予測値はnull', () {
      final fewRecords = [
        _record(id: 'r1', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 8, temperature: 90, beanWeight: 15, totalWater: 225, totalTime: 150),
        _record(id: 'r2', originId: 'origin_1', roastLevel: '浅煎り', scoreOverall: 9, temperature: 92, beanWeight: 15, totalWater: 225, totalTime: 150),
      ];

      final result = SuggestionService().suggestWithGp(bean, fewRecords, {});

      expect(result, isNotNull);
      expect(result!.suggestion.rationale, 'group_best');
      expect(result.isGp, isFalse);
      expect(result.predMean, isNull);
    });

    test('shouldExplore: GP提案が6件たまると次の1件をEIに切り替える(7件に1回)', () {
      RecipeSuggestion gp(String r) => RecipeSuggestion(
            id: r, createdAt: DateTime(2026, 7, 1), beanId: 'b', originId: 'o', roastLevel: '浅煎り',
            temperature: 90, brewRatio: 15, totalTimeSec: 150, rationale: r, accepted: '', resultRecordId: '');

      expect(SuggestionService.shouldExplore([]), isFalse);
      // gp_mean 6件 → 次(7件目)はEI。
      final six = [for (var i = 0; i < 6; i++) gp('gp_mean')];
      expect(SuggestionService.shouldExplore(six), isTrue);
      // group_bestは分母に数えない。
      final withGroupBest = [gp('group_best'), gp('group_best')];
      expect(SuggestionService.shouldExplore(withGroupBest), isFalse);
    });
  });
}
