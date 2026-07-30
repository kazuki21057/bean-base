import 'dart:math' as math;

import '../models/bean_master.dart';
import '../models/coffee_record.dart';
import '../models/method_master.dart';
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

/// F3: レシピ提案 (設計書§7.4)。T3-48でメソッドを提案に組み込んだ。
///
/// 提案するメソッドは、T3-47で追加した`MethodMaster.recommendedRoastLevel`が
/// 対象豆の焙煎度と一致するものに絞る(一致するメソッドが無ければ提案しない)。
/// 湯温はメソッド依存にするため、GP経路は`GpService.fitForMethod`(T3-52で4次元化・
/// メソッド別フィット)を候補メソッドごとに実行し、予測スコアμが最大のメソッドを
/// 採用する。group_best経路(GPが使えないときのフォールバック)も同様に候補メソッド
/// で淹れた記録に絞り、その記録が実際に使ったmethodIdをそのまま提案に載せる。
///
/// GP経路にはGpService.fitForMethodが要求する`targetGrinderId`が必要だが、F3は
/// 030のGP探索UI(T3-52)と異なりミルを明示的に選ぶ手順を持たない。そのため
/// 対象豆と同じ産地×焙煎度の過去記録から最頻出のgrinderIdを採用する
/// (2026-07-30ユーザー指示)。該当記録が無ければGP経路はスキップしgroup_bestへ。
///
/// 在庫豆の判定(残量>0)は`lib/utils/bean_stock_calculator.dart`の
/// `calculateBeanRemainingPercent`が既存実装として存在する(T4-5a調査で確認)。
/// どの豆を対象にするかは呼び出し側(ダッシュボードカード)の責務とし、
/// 本サービスは「特定の豆1件」に対する提案生成のみを担う。
class SuggestionService {
  /// 設計書§7.4手順1「週1回(提案履歴の直近rationaleを見て7件に1件)はEI最大点を
  /// 提案」の判定。過去のGP提案(gp_mean/gp_ei)が7件たまるごとに1件をEIにする。
  static bool shouldExplore(List<RecipeSuggestion> history) {
    final gpCount = history.where((s) => s.rationale == 'gp_mean' || s.rationale == 'gp_ei').length;
    return gpCount % 7 == 6;
  }

  /// GP優先の提案(設計書§7.4手順1・2、T3-48でメソッド選定を追加)。
  ///
  /// [methods]の中から`recommendedRoastLevel`が[bean]の焙煎度と一致するものを
  /// 候補とし、GPがフィットできれば候補メソッドの中で予測スコアμが最大のものを
  /// (rationale='gp_mean'、[explore]時は'gp_ei')、できなければ候補メソッドの
  /// group_bestへフォールバックする(rationale='group_best')。候補メソッドが
  /// 1つも無い、またどちらの経路も提案を作れなければnull。
  SuggestionResult? suggestWithGp(
    BeanMaster bean,
    List<CoffeeRecord> records,
    Map<String, OriginMaster> originById,
    List<MethodMaster> methods,
    Map<String, int> grindStepsByGrinderId, {
    bool explore = false,
  }) {
    final roastOrdinal = roastOrdinalMap[bean.roastLevel];
    if (bean.originId.isEmpty || roastOrdinal == null) return null;

    final candidateMethods =
        methods.where((m) => m.recommendedRoastLevel == bean.roastLevel).toList();
    if (candidateMethods.isEmpty) return null;

    final targetGrinderId = _mostFrequentGrinderId(records, bean.originId, roastOrdinal);
    if (targetGrinderId != null) {
      final gp = GpService();
      MethodMaster? bestMethod;
      GpModel? bestModel;
      ({GpPrediction best, GpPoint bestX, GpPrediction explore, GpPoint exploreX})? bestOpt;

      for (final method in candidateMethods) {
        final model = gp.fitForMethod(
          records,
          methodId: method.id,
          originId: bean.originId,
          roastOrdinal: roastOrdinal,
          targetGrinderId: targetGrinderId,
          grindStepsByGrinderId: grindStepsByGrinderId,
        );
        if (model == null) continue;
        final opt = gp.optimize(model, refine: true);
        if (bestOpt == null || opt.best.mean > bestOpt.best.mean) {
          bestMethod = method;
          bestModel = model;
          bestOpt = opt;
        }
      }

      if (bestMethod != null && bestModel != null && bestOpt != null) {
        final pick = explore ? bestOpt.exploreX : bestOpt.bestX;
        final pred = explore ? bestOpt.explore : bestOpt.best;
        final totalSd = math.sqrt(pred.sd * pred.sd + bestModel.sigmaN * bestModel.sigmaN);
        return SuggestionResult(
          RecipeSuggestion(
            id: 'sugg_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
            beanId: bean.id,
            originId: bean.originId,
            roastLevel: bean.roastLevel,
            methodId: bestMethod.id,
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

    final candidateMethodIds = candidateMethods.map((m) => m.id).toSet();
    final fallback = suggestFor(bean, records, candidateMethodIds);
    if (fallback == null) return null;
    return SuggestionResult(fallback);
  }

  /// [bean]と同じ産地(originId)×焙煎順序値(roastOrdinalMap)のCoffeeRecordのうち、
  /// [candidateMethodIds]に含まれるmethodIdで淹れられたもののなかで、
  /// scoreOverallが最も高い記録の条件を提案として返す(methodIdは記録が実際に
  /// 使ったものをそのまま採用)。該当記録が無い、[candidateMethodIds]が空、
  /// またはbeanのoriginId/roastLevelが解決できない場合はnull。
  RecipeSuggestion? suggestFor(
    BeanMaster bean,
    List<CoffeeRecord> records,
    Set<String> candidateMethodIds,
  ) {
    final roastOrdinal = roastOrdinalMap[bean.roastLevel];
    if (bean.originId.isEmpty || roastOrdinal == null) return null;
    if (candidateMethodIds.isEmpty) return null;

    final sameGroup = records.where((r) =>
        r.originId == bean.originId &&
        roastOrdinalMap[r.roastLevel] == roastOrdinal &&
        r.brewRatio != null &&
        candidateMethodIds.contains(r.methodId));

    CoffeeRecord? best;
    for (final r in sameGroup) {
      if (best == null ||
          r.scoreOverall > best.scoreOverall ||
          (r.scoreOverall == best.scoreOverall && r.brewedAt.isAfter(best.brewedAt))) {
        best = r;
      }
    }
    if (best == null) return null;

    return RecipeSuggestion(
      id: 'sugg_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      beanId: bean.id,
      originId: bean.originId,
      roastLevel: bean.roastLevel,
      methodId: best.methodId,
      temperature: best.temperature,
      brewRatio: best.brewRatio!,
      totalTimeSec: best.totalTime.round(),
      rationale: 'group_best',
      accepted: '',
      resultRecordId: '',
    );
  }

  /// GP経路の`targetGrinderId`(§gp_multidim_design.md §5)を、F3には明示的な
  /// ミル選択UIが無いため、対象豆と同じ産地×焙煎度の過去記録から最頻出の
  /// grinderIdで代用する(2026-07-30ユーザー指示)。該当記録が無ければnull。
  String? _mostFrequentGrinderId(
    List<CoffeeRecord> records,
    String originId,
    double roastOrdinal,
  ) {
    final usage = <String, int>{};
    for (final r in records) {
      if (r.grinderId.isEmpty) continue;
      if (r.originId != originId) continue;
      if (roastOrdinalMap[r.roastLevel] != roastOrdinal) continue;
      usage[r.grinderId] = (usage[r.grinderId] ?? 0) + 1;
    }
    if (usage.isEmpty) return null;
    String? best;
    var bestCount = -1;
    usage.forEach((id, count) {
      if (count > bestCount) {
        best = id;
        bestCount = count;
      }
    });
    return best;
  }
}
