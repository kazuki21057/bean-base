import '../models/bean_master.dart';
import '../models/coffee_record.dart';

/// 抽出履歴から豆ごとの残量%を算出する。
///
/// Cycle 20 T2-2b: `BeanMaster.initialQuantityGrams`(初期購入量)から
/// 該当豆の抽出履歴(`CoffeeRecord.beanWeight`の合計)を差し引いた残量を
/// パーセントで返す。`initialQuantityGrams` が未設定(既存データを含む)
/// の豆は算出不能のため 0 を返す。
int calculateBeanRemainingPercent(BeanMaster bean, List<CoffeeRecord> records) {
  final initial = bean.initialQuantityGrams;
  if (initial == null || initial <= 0) return 0;

  final used = records
      .where((r) => r.beanId == bean.id)
      .fold<double>(0, (sum, r) => sum + r.beanWeight);

  final remaining = (initial - used).clamp(0, initial);
  return ((remaining / initial) * 100).round().clamp(0, 100);
}
