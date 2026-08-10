// ignore_for_file: always_use_package_imports
import '../models/bean_master.dart';
import '../models/coffee_record.dart';

/// 抽出履歴から豆ごとの残量(g)を算出する。
///
/// T3-60: `stockBaselineGrams`(在庫基準点)が設定されている豆は、その値から
/// `stockBaselineAt`より後の抽出記録の使用量だけを差し引く。基準点未設定の豆は
/// 従来どおり`initialQuantityGrams`(初期購入量)からの完全自動算出にフォールバック
/// する(既存データの後方互換を維持)。
double calculateBeanRemainingGrams(BeanMaster bean, List<CoffeeRecord> records) {
  final baseline = bean.stockBaselineGrams;
  if (baseline != null) {
    final baselineAt = bean.stockBaselineAt;
    final used = records
        .where((r) => r.beanId == bean.id && (baselineAt == null || r.brewedAt.isAfter(baselineAt)))
        .fold<double>(0, (sum, r) => sum + r.beanWeight);
    return (baseline - used).clamp(0, baseline).toDouble();
  }

  final initial = bean.initialQuantityGrams;
  if (initial == null || initial <= 0) return 0;

  final used = records
      .where((r) => r.beanId == bean.id)
      .fold<double>(0, (sum, r) => sum + r.beanWeight);

  return (initial - used).clamp(0, initial).toDouble();
}

/// 抽出履歴から豆ごとの残量%を算出する。
///
/// Cycle 20 T2-2b: `BeanMaster.initialQuantityGrams`(初期購入量)から
/// 該当豆の抽出履歴(`CoffeeRecord.beanWeight`の合計)を差し引いた残量を
/// パーセントで返す。`initialQuantityGrams` が未設定(既存データを含む)
/// の豆は算出不能のため 0 を返す。
/// T3-60: 在庫基準点(`stockBaselineGrams`)が設定されている豆は、分母も
/// 基準点の値を使う(基準点設定直後は100%表示になる)。
int calculateBeanRemainingPercent(BeanMaster bean, List<CoffeeRecord> records) {
  final denominator = bean.stockBaselineGrams ?? bean.initialQuantityGrams;
  if (denominator == null || denominator <= 0) return 0;

  final remaining = calculateBeanRemainingGrams(bean, records);
  return ((remaining / denominator) * 100).round().clamp(0, 100);
}
