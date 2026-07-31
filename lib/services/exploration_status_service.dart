import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coffee_record.dart';

/// 1回の試行(= この豆の抽出記録1件、T3-53設計書§4.1)。
class ExplorationTrial {
  final CoffeeRecord record;

  /// 1始まりの試行番号(brewedAt昇順。同時刻はidの昇順で安定化する)。
  final int index;

  /// 正規化粒度 (0,1]。粒度が数値として読めない/ミルの挽き目調整段階が
  /// 未登録の場合はnull。
  final double? grindNorm;

  /// 湯:豆比。CoffeeRecord.brewRatioをそのまま入れる(null可)。
  final double? brewRatio;

  /// 条件4次元(湯温・比率・時間・正規化粒度)がすべて揃っているか。
  /// falseの行は散布の重ね描き・ユニーク条件数の対象外(スコア推移には使う)。
  final bool hasFullCondition;

  /// この試行までの最高スコア(自分を含む累積最大)。
  final int bestSoFar;

  ExplorationTrial({
    required this.record,
    required this.index,
    required this.grindNorm,
    required this.brewRatio,
    required this.hasFullCondition,
    required this.bestSoFar,
  });
}

/// この豆の探索サマリ(T3-53設計書§4.1)。
class ExplorationSummary {
  /// brewedAt昇順の全有効試行(scoreOverall > 0のみ)。
  final List<ExplorationTrial> trials;

  /// hasFullCondition == trueの試行のうち、条件キー(§4.3)が異なるものの数。
  final int uniqueConditionCount;

  /// 最高スコアの試行(trialsが空ならnull)。同点ならbrewedAtが早い方。
  final ExplorationTrial? bestTrial;

  /// 平均scoreOverall(trialsが空なら0.0)。
  final double meanScore;

  /// 最終試行日(trials.last.record.brewedAt。空ならnull)。
  final DateTime? lastTriedAt;

  /// この豆の記録のうちscoreOverall <= 0で除外した件数。
  final int unscoredCount;

  /// trialsのうちhasFullCondition == falseの件数(散布に出せない件数)。
  final int conditionIncompleteCount;

  ExplorationSummary({
    required this.trials,
    required this.uniqueConditionCount,
    required this.bestTrial,
    required this.meanScore,
    required this.lastTriedAt,
    required this.unscoredCount,
    required this.conditionIncompleteCount,
  });
}

/// 探索の進み具合(T3-53設計書§6)。
enum ExplorationProgress { early, midway, converged }

/// F4派生: 最適条件探索の「検証状況」可視化(T3-53、画面045)向け集計サービス。
/// 集計ロジックはウィジェットに置かずここへ切り出す(StatisticsService/GpServiceと同じ方針)。
class ExplorationStatusService {
  /// [beanId]の豆についての探索サマリを作る。
  /// [grindStepsByGrinderId]はgrinderId -> GrinderMaster.grindSteps。
  ExplorationSummary summarize(
    List<CoffeeRecord> records, {
    required String beanId,
    required Map<String, int> grindStepsByGrinderId,
  }) {
    final beanRecords = records.where((r) => r.beanId == beanId);

    var unscoredCount = 0;
    final scored = <CoffeeRecord>[];
    for (final r in beanRecords) {
      if (r.scoreOverall <= 0) {
        unscoredCount++;
      } else {
        scored.add(r);
      }
    }

    // brewedAt昇順、同時刻はid昇順でタイブレーク(設計書§4.3-3)。
    scored.sort((a, b) {
      final byDate = a.brewedAt.compareTo(b.brewedAt);
      if (byDate != 0) return byDate;
      return a.id.compareTo(b.id);
    });

    var bestSoFar = 0;
    var conditionIncompleteCount = 0;
    final trials = <ExplorationTrial>[];
    final conditionKeys = <String>{};

    for (var i = 0; i < scored.length; i++) {
      final r = scored[i];

      double? grindNorm;
      final clicks = double.tryParse(r.grindSize.trim());
      final grindSteps = grindStepsByGrinderId[r.grinderId];
      if (clicks != null && clicks > 0 && grindSteps != null) {
        grindNorm = clicks / grindSteps;
        if (grindNorm > 1.0) grindNorm = 1.0;
      }

      final brewRatio = r.brewRatio;
      final hasFullCondition =
          brewRatio != null && r.temperature > 0 && r.totalTime > 0 && grindNorm != null;
      if (!hasFullCondition) conditionIncompleteCount++;

      if (r.scoreOverall > bestSoFar) bestSoFar = r.scoreOverall;

      trials.add(ExplorationTrial(
        record: r,
        index: i + 1,
        grindNorm: grindNorm,
        brewRatio: brewRatio,
        hasFullCondition: hasFullCondition,
        bestSoFar: bestSoFar,
      ));

      if (hasFullCondition) {
        // 条件キー(設計書§4.3): 湯温1℃ / 比率0.5 / 時間15秒 / 粒度は生クリック値。
        final key = '${r.temperature.round()}|${(brewRatio * 2).round()}|'
            '${(r.totalTime / 15).round()}|${clicks!.round()}';
        conditionKeys.add(key);
      }
    }

    ExplorationTrial? bestTrial;
    for (final t in trials) {
      if (bestTrial == null || t.record.scoreOverall > bestTrial.record.scoreOverall) {
        bestTrial = t;
      }
    }

    final meanScore = trials.isEmpty
        ? 0.0
        : trials.fold<int>(0, (s, t) => s + t.record.scoreOverall) / trials.length;

    return ExplorationSummary(
      trials: trials,
      uniqueConditionCount: conditionKeys.length,
      bestTrial: bestTrial,
      meanScore: meanScore,
      lastTriedAt: trials.isEmpty ? null : trials.last.record.brewedAt,
      unscoredCount: unscoredCount,
      conditionIncompleteCount: conditionIncompleteCount,
    );
  }

  /// EIの最大値から探索の進み具合を判定する(設計書§6.2)。
  /// 戻り値のgaugeは0.0–1.0(ゲージ表示用、§6.3)。
  ({ExplorationProgress level, double gauge}) judgeProgress(double eiMax) {
    final ExplorationProgress level;
    if (eiMax >= 0.20) {
      level = ExplorationProgress.early;
    } else if (eiMax >= 0.05) {
      level = ExplorationProgress.midway;
    } else {
      level = ExplorationProgress.converged;
    }
    final gauge = (1.0 - eiMax.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    return (level: level, gauge: gauge);
  }
}

final explorationStatusServiceProvider = Provider((ref) => ExplorationStatusService());
