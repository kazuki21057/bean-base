import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
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
}
