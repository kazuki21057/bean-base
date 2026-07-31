import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/services/exploration_status_service.dart';

/// T3-53(exploration_status_design.md §10.1): ExplorationStatusService の
/// summarize/judgeProgress を検証する。
CoffeeRecord _record(
  String id, {
  required DateTime brewedAt,
  String beanId = 'b1',
  String grinderId = 'g1',
  String grindSize = '90',
  int score = 7,
  double temperature = 90,
  double beanWeight = 15,
  double totalWater = 225,
  int totalTime = 150,
}) {
  return CoffeeRecord(
    id: id,
    brewedAt: brewedAt,
    beanId: beanId,
    methodId: 'm1',
    beanWeight: beanWeight,
    totalWater: totalWater,
    totalTime: totalTime,
    scoreOverall: score,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    taste: '',
    comment: '',
    grindSize: grindSize,
    temperature: temperature,
    dripperId: '',
    filterId: '',
    grinderId: grinderId,
    roastLevel: '',
    origin: '',
    originId: '',
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

void main() {
  final service = ExplorationStatusService();
  const grindSteps = {'g1': 180};

  group('ExplorationStatusService.summarize (T3-53)', () {
    test('他の豆の記録・scoreOverall==0の記録はtrialsに入らず、後者はunscoredCountに数えられる', () {
      final records = [
        _record('r1', beanId: 'b1', brewedAt: DateTime(2026, 1, 1), score: 7),
        _record('r2', beanId: 'b2', brewedAt: DateTime(2026, 1, 2), score: 8),
        _record('r3', beanId: 'b1', brewedAt: DateTime(2026, 1, 3), score: 0),
      ];

      final summary = service.summarize(records, beanId: 'b1', grindStepsByGrinderId: grindSteps);

      expect(summary.trials.length, 1);
      expect(summary.trials.single.record.id, 'r1');
      expect(summary.unscoredCount, 1);
    });

    test('brewedAt昇順でindexが1..Nになる。同一brewedAtはid昇順で安定する', () {
      final t = DateTime(2026, 2, 1);
      final records = [
        _record('r_b', brewedAt: t, score: 7),
        _record('r_a', brewedAt: t, score: 8),
        _record('r_c', brewedAt: DateTime(2026, 1, 1), score: 6),
      ];

      final summary = service.summarize(records, beanId: 'b1', grindStepsByGrinderId: grindSteps);

      expect(summary.trials.map((t) => t.record.id).toList(), ['r_c', 'r_a', 'r_b']);
      expect(summary.trials.map((t) => t.index).toList(), [1, 2, 3]);
    });

    test('bestSoFarはこれまでの累積最大、bestTrialは最高スコアの試行', () {
      final scores = [6, 8, 7, 9];
      final records = [
        for (var i = 0; i < scores.length; i++)
          _record('r$i', brewedAt: DateTime(2026, 3, 1 + i), score: scores[i]),
      ];

      final summary = service.summarize(records, beanId: 'b1', grindStepsByGrinderId: grindSteps);

      expect(summary.trials.map((t) => t.bestSoFar).toList(), [6, 8, 8, 9]);
      expect(summary.bestTrial?.index, 4);
    });

    test('grindNormはclicks/grindSteps、1.0にクランプ、解析不能/ミル未登録はnullかつhasFullCondition=false', () {
      final records = [
        _record('r1', brewedAt: DateTime(2026, 4, 1), grinderId: 'g1', grindSize: '90'),
        _record('r2', brewedAt: DateTime(2026, 4, 2), grinderId: 'g1', grindSize: '200'),
        _record('r3', brewedAt: DateTime(2026, 4, 3), grinderId: 'g1', grindSize: 'abc'),
        _record('r4', brewedAt: DateTime(2026, 4, 4), grinderId: 'g_unknown', grindSize: '90'),
      ];

      final summary = service.summarize(records, beanId: 'b1', grindStepsByGrinderId: grindSteps);
      final byId = {for (final t in summary.trials) t.record.id: t};

      expect(byId['r1']!.grindNorm, 0.5);
      expect(byId['r1']!.hasFullCondition, isTrue);
      expect(byId['r2']!.grindNorm, 1.0);
      expect(byId['r3']!.grindNorm, isNull);
      expect(byId['r3']!.hasFullCondition, isFalse);
      expect(byId['r4']!.grindNorm, isNull);
      expect(byId['r4']!.hasFullCondition, isFalse);
      expect(summary.conditionIncompleteCount, 2);
    });

    test('条件キー(湯温1℃/比率0.5/時間15秒/粒度生クリック値)の丸めで同一条件が1通りに畳まれる', () {
      final records = [
        // 湯温90.4と90.0は同じ90に丸められ、比率・時間・粒度も揃えると1つの条件に畳まれる。
        _record('r1', brewedAt: DateTime(2026, 5, 1), temperature: 90.4, totalWater: 15 * 15.0, totalTime: 150, grindSize: '90'),
        _record('r2', brewedAt: DateTime(2026, 5, 2), temperature: 90.0, totalWater: 15 * 15.2, totalTime: 155, grindSize: '90'),
        // 湯温91は別条件として数えられる。
        _record('r3', brewedAt: DateTime(2026, 5, 3), temperature: 91.0, totalWater: 15 * 15.0, totalTime: 150, grindSize: '90'),
      ];

      final summary = service.summarize(records, beanId: 'b1', grindStepsByGrinderId: grindSteps);

      expect(summary.uniqueConditionCount, 2);
    });

    test('meanScoreは単純平均、lastTriedAtは最終試行日', () {
      final records = [
        _record('r1', brewedAt: DateTime(2026, 6, 1), score: 6),
        _record('r2', brewedAt: DateTime(2026, 6, 5), score: 8),
      ];

      final summary = service.summarize(records, beanId: 'b1', grindStepsByGrinderId: grindSteps);

      expect(summary.meanScore, 7.0);
      expect(summary.lastTriedAt, DateTime(2026, 6, 5));
    });
  });

  group('ExplorationStatusService.judgeProgress (T3-53)', () {
    test('eiMaxの3段階判定としきい値境界', () {
      expect(service.judgeProgress(0.30).level, ExplorationProgress.early);
      expect(service.judgeProgress(0.10).level, ExplorationProgress.midway);
      expect(service.judgeProgress(0.01).level, ExplorationProgress.converged);
      expect(service.judgeProgress(0.20).level, ExplorationProgress.early);
      expect(service.judgeProgress(0.05).level, ExplorationProgress.midway);
    });

    test('gaugeはeiMax=1.0で0.0、eiMax=0.0で1.0、eiMax=2.0で0.0(クランプ)', () {
      expect(service.judgeProgress(1.0).gauge, 0.0);
      expect(service.judgeProgress(0.0).gauge, 1.0);
      expect(service.judgeProgress(2.0).gauge, 0.0);
    });
  });
}
