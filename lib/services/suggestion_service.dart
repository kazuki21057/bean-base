import '../models/bean_master.dart';
import '../models/coffee_record.dart';
import '../models/origin_master.dart';
import '../models/recipe_suggestion.dart';
import 'math/encoding.dart';

/// F3: レシピ提案 (設計書§7.4)。
///
/// T4-5a時点ではGP推薦エンジン(F4、T4-6a〜c)が未接続のため、常に
/// フォールバック経路(rationale='group_best': 同グループの過去最高スコア
/// 記録の条件をそのまま提案)のみを実装する。GP接続後(T4-6c)は
/// n_eff(重み付き有効サンプルサイズ)≥10のときμ最大点(rationale='gp_mean')、
/// 週1回程度EI最大点(rationale='gp_ei')を優先する経路を追加する予定。
///
/// 在庫豆の判定(残量>0)は`lib/utils/bean_stock_calculator.dart`の
/// `calculateBeanRemainingPercent`が既存実装として存在する(T4-5a調査で確認)。
/// どの豆を対象にするかは呼び出し側(T4-5bのダッシュボードカード)の責務とし、
/// 本サービスは「特定の豆1件」に対する提案生成のみを担う。
class SuggestionService {
  /// [bean]と同じ産地(originId)×焙煎順序値(roastOrdinalMap)のCoffeeRecordの
  /// うち、scoreOverallが最も高い記録の条件を提案として返す。
  /// 該当記録が無い、またはbeanのoriginId/roastLevelが解決できない場合はnull。
  ///
  /// [originById]は設計書のシグネチャ(§7.4)には無いが、将来GP接続時に
  /// 同名関数のインターフェースを揃えておくため受け取っている
  /// (現時点の本ロジックはoriginIdのみで完結し中身は参照しない)。
  RecipeSuggestion? suggestFor(
    BeanMaster bean,
    List<CoffeeRecord> records,
    Map<String, OriginMaster> originById,
  ) {
    final roastOrdinal = roastOrdinalMap[bean.roastLevel];
    if (bean.originId.isEmpty || roastOrdinal == null) return null;

    final sameGroup = records.where((r) =>
        r.originId == bean.originId &&
        roastOrdinalMap[r.roastLevel] == roastOrdinal &&
        r.brewRatio != null);

    CoffeeRecord? best;
    for (final r in sameGroup) {
      if (best == null ||
          r.scoreOverall > best.scoreOverall ||
          (r.scoreOverall == best.scoreOverall && r.brewedAt.isAfter(best.brewedAt))) {
        best = r;
      }
    }
    if (best == null) return null; // GP未接続(T4-6c予定)のため、それも無ければ提案しない

    return RecipeSuggestion(
      id: 'sugg_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      beanId: bean.id,
      originId: bean.originId,
      roastLevel: bean.roastLevel,
      temperature: best.temperature,
      brewRatio: best.brewRatio!,
      totalTimeSec: best.totalTime.round(),
      rationale: 'group_best',
      accepted: '',
      resultRecordId: '',
    );
  }
}
