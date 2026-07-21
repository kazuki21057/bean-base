import 'dart:math' as math;

import '../models/bean_master.dart';
import '../models/coffee_record.dart';
import '../models/origin_master.dart';
import '../models/recipe_suggestion.dart';
import 'gp_service.dart';
import 'math/encoding.dart';

/// GP接続後(T4-6c)の提案結果。予測スコアと区間はGP経路のときのみ非nullになる
/// (group_best経路では過去記録の条件をそのまま返すため予測値は持たない)。
class SuggestionResult {
  final RecipeSuggestion suggestion;

  /// GP経路の予測総合評価(点推定)。group_bestならnull。
  final double? predMean;

  /// 95%予測区間(設計書§2.5、√(sd²+σ_n²)ベース)。group_bestならnull。
  final double? predLower;
  final double? predUpper;

  SuggestionResult(this.suggestion, {this.predMean, this.predLower, this.predUpper});

  bool get isGp => suggestion.rationale == 'gp_mean' || suggestion.rationale == 'gp_ei';
}

/// F3: レシピ提案 (設計書§7.4)。
///
/// T4-6cでGP推薦エンジン(F4)に接続した。[suggestWithGp]が主経路で、豆の
/// (originId, roastOrdinal)向けにGPモデル(§7.5)をフィットできる(n_eff≥10)なら
/// μ最大点(rationale='gp_mean')を、探索フラグが立っていればEI最大点
/// (rationale='gp_ei')を提案する。n_eff<10のときは[suggestFor]の
/// フォールバック経路(rationale='group_best': 同グループの過去最高スコア記録の
/// 条件をそのまま提案)に落ちる。
///
/// 在庫豆の判定(残量>0)は`lib/utils/bean_stock_calculator.dart`の
/// `calculateBeanRemainingPercent`が既存実装として存在する(T4-5a調査で確認)。
/// どの豆を対象にするかは呼び出し側(T4-5bのダッシュボードカード)の責務とし、
/// 本サービスは「特定の豆1件」に対する提案生成のみを担う。
class SuggestionService {
  /// 設計書§7.4手順1「週1回(提案履歴の直近rationaleを見て7件に1件)はEI最大点を
  /// 提案」の判定。過去のGP提案(gp_mean/gp_ei)が7件たまるごとに1件をEIにする。
  static bool shouldExplore(List<RecipeSuggestion> history) {
    final gpCount = history.where((s) => s.rationale == 'gp_mean' || s.rationale == 'gp_ei').length;
    return gpCount % 7 == 6;
  }

  /// GP優先の提案(設計書§7.4手順1・2)。GPがフィットできれば予測スコア+区間つきの
  /// gp_mean(または[explore]時はgp_ei)、できなければgroup_bestへフォールバックする。
  /// どちらも提案を作れなければnull。
  SuggestionResult? suggestWithGp(
    BeanMaster bean,
    List<CoffeeRecord> records,
    Map<String, OriginMaster> originById, {
    bool explore = false,
  }) {
    final roastOrdinal = roastOrdinalMap[bean.roastLevel];
    if (bean.originId.isNotEmpty && roastOrdinal != null) {
      final gp = GpService();
      final model = gp.fit(records, bean.originId, roastOrdinal, originById);
      if (model != null) {
        final opt = gp.optimize(model);
        final pick = explore ? opt.exploreX : opt.bestX;
        final pred = explore ? opt.explore : opt.best;
        final totalSd = math.sqrt(pred.sd * pred.sd + model.sigmaN * model.sigmaN);
        return SuggestionResult(
          RecipeSuggestion(
            id: 'sugg_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
            beanId: bean.id,
            originId: bean.originId,
            roastLevel: bean.roastLevel,
            temperature: pick.t,
            brewRatio: pick.r,
            totalTimeSec: pick.s,
            rationale: explore ? 'gp_ei' : 'gp_mean',
            accepted: '',
            resultRecordId: '',
          ),
          predMean: pred.mean,
          predLower: (pred.mean - 1.96 * totalSd).clamp(0.0, 10.0),
          predUpper: (pred.mean + 1.96 * totalSd).clamp(0.0, 10.0),
        );
      }
    }
    final fallback = suggestFor(bean, records, originById);
    if (fallback == null) return null;
    return SuggestionResult(fallback);
  }

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
