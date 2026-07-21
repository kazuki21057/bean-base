import 'dart:math';

import '../models/coffee_record.dart';
import '../models/origin_master.dart';
import 'math/distributions.dart';
import 'math/encoding.dart';

/// F5: 産地×焙煎度でグループ化した好み傾向の統計量 (設計書§7.1)。
class PreferenceGroupStat {
  final String originLevel; // 産地名(originId解決後、無ければ自由入力origin)
  final String roastLabel; // '浅煎り' 等(roastOrdinalMapの順序値から逆引きした代表ラベル)
  final int n;
  final double mean;
  final double sd;
  final double ciLower; // T-22
  final double ciUpper; // T-22
  final double? welchT; // n>=5のみ (T-23)
  final double? welchP; // n>=5のみ (T-24)
  final bool significant; // Bonferroni補正後 p < 0.05/m

  PreferenceGroupStat({
    required this.originLevel,
    required this.roastLabel,
    required this.n,
    required this.mean,
    required this.sd,
    required this.ciLower,
    required this.ciUpper,
    required this.welchT,
    required this.welchP,
    required this.significant,
  });
}

class PreferenceProfile {
  final DateTime createdAt;
  final int totalRecords;
  final List<PreferenceGroupStat> groups; // mean降順
  final List<String> statements;

  PreferenceProfile({
    required this.createdAt,
    required this.totalRecords,
    required this.groups,
    required this.statements,
  });
}

class _GroupEntry {
  final String originLevel;
  final String roastLabel;
  final int n;
  final double mean;
  final double sd;
  final double ciLower;
  final double ciUpper;
  final double? welchT;
  final double? welchP;
  final double? restMean; // welchP計算時のx̄_rest(statements文言用)

  _GroupEntry({
    required this.originLevel,
    required this.roastLabel,
    required this.n,
    required this.mean,
    required this.sd,
    required this.ciLower,
    required this.ciUpper,
    required this.welchT,
    required this.welchP,
    required this.restMean,
  });
}

/// F5: 好みプロファイル(層別統計・Welch検定・Bonferroni補正・statements生成)。
/// 設計書§2.4・§7.1。数値計算(t分位点・t分布CDF)は`math/distributions.dart`に委譲。
class PreferenceService {
  static const _minGroupSizeForTest = 5;

  PreferenceProfile build(
    List<CoffeeRecord> records,
    Map<String, OriginMaster> originById,
  ) {
    // roastOrdinalMapの各順序値について最初に登場するキーを代表ラベルとする
    // ('浅煎り'→1.0のように、各ブロック先頭の正式名称が採用される)。
    final roastLabelByOrdinal = <double, String>{};
    for (final e in roastOrdinalMap.entries) {
      roastLabelByOrdinal.putIfAbsent(e.value, () => e.key);
    }

    // 焙煎度が未知の行は欠測として除外 (design_matrix.dartと同じ欠測方針)。
    final usable = records.where((r) => roastOrdinalMap.containsKey(r.roastLevel)).toList();

    if (usable.isEmpty) {
      return PreferenceProfile(
        createdAt: DateTime.now(),
        totalRecords: 0,
        groups: const [],
        statements: const ['現時点で統計的に明確な好みの偏りは検出されていません (データ蓄積中)'],
      );
    }

    String originLevelOf(CoffeeRecord r) {
      final resolved = originById[r.originId]?.nameJa;
      if (resolved != null && resolved.isNotEmpty) return resolved;
      if (r.origin.isNotEmpty) return r.origin;
      return '不明';
    }

    // (originLevel, roastLabel) でグルーピング。
    final byKey = <String, List<CoffeeRecord>>{};
    for (final r in usable) {
      final originLevel = originLevelOf(r);
      final roastLabel = roastLabelByOrdinal[roastOrdinalMap[r.roastLevel]]!;
      byKey.putIfAbsent('$originLevel|$roastLabel', () => []).add(r);
    }

    final entries = byKey.values.map((groupRecords) {
      final originLevel = originLevelOf(groupRecords.first);
      final roastLabel =
          roastLabelByOrdinal[roastOrdinalMap[groupRecords.first.roastLevel]]!;
      final scores = groupRecords.map((r) => r.scoreOverall.toDouble()).toList();
      final n = scores.length;
      final mean = _mean(scores);
      final sd = _sd(scores, mean);

      var ciLower = mean;
      var ciUpper = mean;
      if (n >= 2) {
        final tCrit = tQuantile(0.975, (n - 1).toDouble());
        final halfWidth = tCrit * sd / sqrt(n);
        ciLower = mean - halfWidth;
        ciUpper = mean + halfWidth;
      }

      double? welchT;
      double? welchP;
      double? restMean;
      if (n >= _minGroupSizeForTest) {
        final groupSet = groupRecords.toSet();
        final restScores = usable
            .where((r) => !groupSet.contains(r))
            .map((r) => r.scoreOverall.toDouble())
            .toList();
        if (restScores.length >= 2) {
          final rMean = _mean(restScores);
          final rSd = _sd(restScores, rMean);
          final se2 = (sd * sd) / n + (rSd * rSd) / restScores.length;
          if (se2 > 0) {
            final t = (mean - rMean) / sqrt(se2);
            final df = _welchDf(sd, n, rSd, restScores.length);
            welchT = t;
            welchP = 2 * (1 - studentTCdf(t.abs(), df));
            restMean = rMean;
          }
        }
      }

      return _GroupEntry(
        originLevel: originLevel,
        roastLabel: roastLabel,
        n: n,
        mean: mean,
        sd: sd,
        ciLower: ciLower,
        ciUpper: ciUpper,
        welchT: welchT,
        welchP: welchP,
        restMean: restMean,
      );
    }).toList();

    // Bonferroni補正: m = 検定可能(n>=5)なグループ数 (設計書§2.4)。
    final testableCount = entries.where((e) => e.welchP != null).length;
    final alpha = testableCount > 0 ? 0.05 / testableCount : 0.05;

    final groups = entries
        .map((e) => PreferenceGroupStat(
              originLevel: e.originLevel,
              roastLabel: e.roastLabel,
              n: e.n,
              mean: e.mean,
              sd: e.sd,
              ciLower: e.ciLower,
              ciUpper: e.ciUpper,
              welchT: e.welchT,
              welchP: e.welchP,
              significant: e.welchP != null && e.welchP! < alpha,
            ))
        .toList()
      ..sort((a, b) => b.mean.compareTo(a.mean));

    final restMeanByKey = {
      for (final e in entries) '${e.originLevel}|${e.roastLabel}': e.restMean,
    };

    final statements = <String>[];
    for (final g in groups) {
      if (!g.significant) continue;
      final restMean = restMeanByKey['${g.originLevel}|${g.roastLabel}'];
      if (restMean == null) continue;
      final diff = g.mean - restMean;
      final direction = diff >= 0 ? '高' : '低';
      final sign = diff >= 0 ? '+' : '';
      statements.add(
        '「${g.originLevel}×${g.roastLabel}」を$direction評価する傾向 '
        '(平均${g.mean.toStringAsFixed(1)}, 全体$sign${diff.toStringAsFixed(1)}, '
        'p=${g.welchP!.toStringAsFixed(3)})',
      );
    }
    if (statements.isEmpty) {
      statements.add('現時点で統計的に明確な好みの偏りは検出されていません (データ蓄積中)');
    }

    return PreferenceProfile(
      createdAt: DateTime.now(),
      totalRecords: usable.length,
      groups: groups,
      statements: statements,
    );
  }

  double _mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;

  double _sd(List<double> xs, double mean) {
    if (xs.length < 2) return 0;
    final ss = xs.fold(0.0, (s, x) => s + (x - mean) * (x - mean));
    return sqrt(ss / (xs.length - 1));
  }

  // Welch–Satterthwaite近似 (T-24)。
  double _welchDf(double sdA, int nA, double sdB, int nB) {
    final a = (sdA * sdA) / nA;
    final b = (sdB * sdB) / nB;
    return (a + b) * (a + b) / (a * a / (nA - 1) + b * b / (nB - 1));
  }
}
