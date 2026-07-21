import '../../models/coffee_record.dart';
import '../../models/origin_master.dart';
import 'encoding.dart';

/// 重回帰分析(F1)の計画行列 (設計書§4.4)。
///
/// [centerMeans] は連続変数を中心化する際に使った平均値
/// (`predict()` で新規入力を同じ基準で中心化するために必要。設計書の
/// クラス定義には無いが、`RegressionService.predict()` の実装に必須のため追加)。
/// [dummyLevels] は産地ダミー列の水準(基準水準を除く、列順)、[baseLevel] は
/// 基準水準(産地ダミー無し)。いずれも同様の理由で追加。
class DesignMatrixResult {
  final List<List<double>> x; // n×(p+1)、第1列=1 (切片)
  final List<double> y;
  final List<String> columnNames; // ['切片', '湯温(中心化)', ...] 表示用
  final int excludedRows; // 欠測等で除外した行数
  final Map<String, int> categoryCounts; // 産地ダミーの水準別件数(基準水準含む)
  final Map<String, double> centerMeans;
  final List<String> dummyLevels;
  final String baseLevel;

  DesignMatrixResult({
    required this.x,
    required this.y,
    required this.columnNames,
    required this.excludedRows,
    required this.categoryCounts,
    required this.centerMeans,
    required this.dummyLevels,
    required this.baseLevel,
  });
}

/// F1用計画行列を組み立てる (設計書§4.4)。
///
/// 注: 設計書§4.4手順2の「経過日数」列(roastDateの記録率70%以上で追加)は、
/// roastDateが`BeanMaster`のフィールドであり本関数のシグネチャ(CoffeeRecordと
/// originByIdのみ)からは参照できないため、本実装では見送っている
/// (2026-07-21、次回セッションで要判断。詳細はNEXT_SESSION.md参照)。
DesignMatrixResult buildRegressionMatrix(
  List<CoffeeRecord> records,
  Map<String, OriginMaster> originById,
) {
  final valid = <CoffeeRecord>[];
  var excluded = 0;
  for (final r in records) {
    final ratio = r.brewRatio;
    final roastOrdinal = roastOrdinalMap[r.roastLevel];
    final origin = originById[r.originId];
    if (r.scoreOverall <= 0 ||
        ratio == null ||
        r.temperature <= 0 ||
        r.totalTime <= 0 ||
        roastOrdinal == null ||
        origin == null) {
      excluded++;
      continue;
    }
    valid.add(r);
  }

  if (valid.isEmpty) {
    return DesignMatrixResult(
      x: const [],
      y: const [],
      columnNames: const ['切片'],
      excludedRows: excluded,
      categoryCounts: const {},
      centerMeans: const {},
      dummyLevels: const [],
      baseLevel: '',
    );
  }

  final n = valid.length;
  final temps = [for (final r in valid) r.temperature];
  final ratios = [for (final r in valid) r.brewRatio!];
  final minutes = [for (final r in valid) r.totalTime / 60.0];
  final roastOrdinals = [for (final r in valid) roastOrdinalMap[r.roastLevel]!];

  double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
  final tempMean = mean(temps);
  final ratioMean = mean(ratios);
  final minMean = mean(minutes);
  final roastMean = mean(roastOrdinals);

  final tempC = [for (final v in temps) v - tempMean];
  final ratioC = [for (final v in ratios) v - ratioMean];
  final minC = [for (final v in minutes) v - minMean];
  final roastC = [for (final v in roastOrdinals) v - roastMean];

  // 産地ダミー: 水準決定 (設計書§4.4手順3)
  final rawCounts = <String, int>{};
  for (final r in valid) {
    rawCounts[r.originId] = (rawCounts[r.originId] ?? 0) + 1;
  }

  final levelForOrigin = <String, String>{};
  for (final originId in rawCounts.keys) {
    final count = rawCounts[originId]!;
    levelForOrigin[originId] =
        count >= 5 ? originById[originId]!.nameJa : 'region:${originById[originId]!.region}';
  }
  final levelCountsPass1 = <String, int>{};
  for (final originId in rawCounts.keys) {
    final level = levelForOrigin[originId]!;
    levelCountsPass1[level] = (levelCountsPass1[level] ?? 0) + rawCounts[originId]!;
  }
  final finalLevelForOrigin = <String, String>{};
  for (final originId in rawCounts.keys) {
    final level = levelForOrigin[originId]!;
    if (level.startsWith('region:') && levelCountsPass1[level]! < 5) {
      finalLevelForOrigin[originId] = 'その他';
    } else {
      finalLevelForOrigin[originId] = level;
    }
  }
  String displayName(String level) => level.startsWith('region:') ? level.substring('region:'.length) : level;

  final finalLevelCounts = <String, int>{};
  for (final originId in rawCounts.keys) {
    final level = displayName(finalLevelForOrigin[originId]!);
    finalLevelCounts[level] = (finalLevelCounts[level] ?? 0) + rawCounts[originId]!;
  }

  var baseLevel = finalLevelCounts.keys.first;
  for (final level in finalLevelCounts.keys) {
    if (finalLevelCounts[level]! > finalLevelCounts[baseLevel]!) baseLevel = level;
  }
  final dummyLevels = finalLevelCounts.keys.where((l) => l != baseLevel).toList()..sort();

  final columnNames = <String>[
    '切片',
    '湯温(中心化)',
    'brewRatio(中心化)',
    '総抽出時間分(中心化)',
    '焙煎順序(中心化)',
    for (final level in dummyLevels) '産地:$level',
    '焙煎順序×湯温(交互作用)',
  ];

  final xRows = <List<double>>[];
  final yVals = <double>[];
  for (var i = 0; i < n; i++) {
    final recordLevel = displayName(finalLevelForOrigin[valid[i].originId]!);
    final row = <double>[
      1.0,
      tempC[i],
      ratioC[i],
      minC[i],
      roastC[i],
      for (final level in dummyLevels) (recordLevel == level ? 1.0 : 0.0),
      roastC[i] * tempC[i],
    ];
    xRows.add(row);
    yVals.add(valid[i].scoreOverall.toDouble());
  }

  return DesignMatrixResult(
    x: xRows,
    y: yVals,
    columnNames: columnNames,
    excludedRows: excluded,
    categoryCounts: finalLevelCounts,
    centerMeans: {
      'temperature': tempMean,
      'brewRatio': ratioMean,
      'totalTimeMin': minMean,
      'roastOrdinal': roastMean,
    },
    dummyLevels: dummyLevels,
    baseLevel: baseLevel,
  );
}
