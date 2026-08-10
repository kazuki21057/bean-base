// ignore_for_file: always_use_package_imports
import '../models/method_master.dart';
import '../services/math/encoding.dart';

/// 焙煎度の範囲(順序値 1.0〜8.0、min <= max)。
class RoastRange {
  final double min;
  final double max;
  const RoastRange(this.min, this.max);

  bool get isPoint => min == max;
  bool contains(double ordinal) => ordinal >= min && ordinal <= max;
}

/// [method]の推奨焙煎度の範囲を解決する(`docs/method_roast_range_design.md`§4.2)。
/// 新2列(`recommendedRoastMin`/`recommendedRoastMax`)を優先し、片方だけなら点として
/// 扱う。両方未設定なら旧単一値`recommendedRoastLevel`にフォールバックする。
/// いずれも解決できなければ未設定としてnullを返す。
RoastRange? resolveMethodRoastRange(MethodMaster method) {
  final a = roastOrdinalMap[method.recommendedRoastMin];
  final b = roastOrdinalMap[method.recommendedRoastMax];
  if (a != null && b != null) {
    return RoastRange(a < b ? a : b, a > b ? a : b);
  }
  if (a != null) return RoastRange(a, a);
  if (b != null) return RoastRange(b, b);
  final c = roastOrdinalMap[method.recommendedRoastLevel];
  if (c != null) return RoastRange(c, c);
  return null;
}

/// [method]の推奨焙煎度の範囲が[beanRoastOrdinal]を含むか。
/// 範囲が未設定(resolveがnull)なら候補外として**false**を返す
/// (`docs/method_roast_range_design.md`§1.1①のユーザー決定)。
bool methodMatchesRoastOrdinal(MethodMaster method, double beanRoastOrdinal) {
  final range = resolveMethodRoastRange(method);
  if (range == null) return false;
  return range.contains(beanRoastOrdinal);
}

/// 020(詳細画面)などの表示用ラベル(`docs/method_roast_range_design.md`§4.3)。
String formatMethodRoastRange(MethodMaster method) {
  final range = resolveMethodRoastRange(method);
  if (range != null) {
    if (range.isPoint) {
      final index = range.min.round() - 1;
      return '${roastLevels8[index]} (${roastLevels8En[index]})';
    }
    final loIndex = range.min.round() - 1;
    final hiIndex = range.max.round() - 1;
    return '${roastLevels8[loIndex]} 〜 ${roastLevels8[hiIndex]}';
  }
  for (final raw in [
    method.recommendedRoastMin,
    method.recommendedRoastMax,
    method.recommendedRoastLevel,
  ]) {
    if (raw != null && raw.isNotEmpty) return raw;
  }
  return '-';
}
