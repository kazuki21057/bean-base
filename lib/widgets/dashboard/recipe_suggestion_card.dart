import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bean_master.dart';
import '../../models/coffee_record.dart';
import '../../models/origin_master.dart';
import '../../models/pending_brew_info.dart';
import '../../models/recipe_suggestion.dart';
import '../../providers/data_providers.dart';
import '../../screens/create/brew_evaluation_screen.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/data_service.dart';
import '../../services/math/encoding.dart';
import '../../services/preference_service.dart';
import '../../services/suggestion_service.dart';
import '../../theme/blackboard_theme.dart';
import '../../utils/bean_stock_calculator.dart';

/// F3: レシピ提案カード (設計書§7.4)。ダッシュボード(001)に配置する。
///
/// 在庫豆(残量% > 0)のうち`SuggestionService.suggestFor`が提案を返せる豆を、
/// 最終使用日が古い順(放置ぎみの在庫豆を優先)に最大[_maxCards]件カード表示する。
/// 各カードは湯温/比率/時間と、F5好みプロファイルから引いた推奨焙煎度(§7.4後半)を
/// 表示し、[この条件で淹れる](accepted='yes'で保存し031へプリフィル遷移)と
/// [今回はパス](accepted='no'で保存し当該カードを非表示)のボタンを持つ。
///
/// T4-5a時点ではGP未接続のため提案根拠は常にgroup_best(予測スコア・区間は無し)。
class RecipeSuggestionCard extends ConsumerStatefulWidget {
  const RecipeSuggestionCard({super.key});

  @override
  ConsumerState<RecipeSuggestionCard> createState() => _RecipeSuggestionCardState();
}

class _RecipeSuggestionCardState extends ConsumerState<RecipeSuggestionCard> {
  static const int _maxCards = 3;

  /// このセッション中に[淹れる]/[パス]済みの豆ID。カードから除外する
  /// (設計書§7.4手順4「カード表示自体は保存しないが、操作した提案は保存する」)。
  final Set<String> _handledBeanIds = {};

  @override
  Widget build(BuildContext context) {
    final beansAsync = ref.watch(beanMasterProvider);
    final logs = ref.watch(coffeeRecordsProvider).value ?? const <CoffeeRecord>[];
    final origins = ref.watch(originMasterProvider).value ?? const <OriginMaster>[];
    final originById = {for (final o in origins) o.id: o};

    return FormSection(
      icon: Icons.auto_awesome_outlined,
      title: '今日のおすすめレシピ',
      dark: true,
      children: [
        beansAsync.when(
          data: (beans) {
            final candidates = _buildCandidates(beans, logs, originById);
            if (candidates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'おすすめできる在庫豆がありません(在庫豆に過去の抽出記録が貯まると提案します)',
                  style: TextStyle(color: kChalkMuted),
                ),
              );
            }
            final profile = PreferenceService().build(logs, originById);
            return Column(
              children: [
                for (final c in candidates.take(_maxCards))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SuggestionTile(
                      bean: c.bean,
                      suggestion: c.suggestion,
                      recommendedRoast: _recommendedRoastFor(c.bean, originById, profile),
                      onBrew: () => _onBrew(c.bean, c.suggestion),
                      onPass: () => _onPass(c.bean, c.suggestion),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: kChalkWhite)),
          ),
          error: (e, s) => Text('読み込みエラー: $e', style: const TextStyle(color: kChalkError)),
        ),
      ],
    );
  }

  /// 在庫豆(残量>0)かつ提案を返せる豆を、最終使用日が古い順に並べる。
  List<_Candidate> _buildCandidates(
    List<BeanMaster> beans,
    List<CoffeeRecord> logs,
    Map<String, OriginMaster> originById,
  ) {
    final service = SuggestionService();
    final result = <_Candidate>[];
    for (final bean in beans) {
      if (bean.name.isEmpty || bean.name == '-') continue;
      if (_handledBeanIds.contains(bean.id)) continue;
      if (calculateBeanRemainingPercent(bean, logs) <= 0) continue;
      final suggestion = service.suggestFor(bean, logs, originById);
      if (suggestion == null) continue;
      result.add(_Candidate(bean, suggestion));
    }
    // 最終使用日が古い(=未設定はさらに古い扱い)豆を優先。
    result.sort((a, b) {
      final da = a.bean.lastUseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.bean.lastUseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    return result;
  }

  /// 設計書§7.4後半: 豆の産地について、好みプロファイルで最も平均が高く
  /// n>=3のグループの焙煎度ラベルを返す(該当が無ければnull)。
  String? _recommendedRoastFor(
    BeanMaster bean,
    Map<String, OriginMaster> originById,
    PreferenceProfile profile,
  ) {
    final originName = _originNameOf(bean, originById);
    if (originName == null) return null;
    String? best;
    double bestMean = double.negativeInfinity;
    for (final g in profile.groups) {
      if (g.originLevel != originName || g.n < 3) continue;
      if (g.mean > bestMean) {
        bestMean = g.mean;
        best = g.roastLabel;
      }
    }
    return best;
  }

  /// PreferenceService.build と同じ産地名の解決規則(originId→nameJa、
  /// 無ければ自由入力origin)。どちらも無ければnull。
  String? _originNameOf(BeanMaster bean, Map<String, OriginMaster> originById) {
    final resolved = originById[bean.originId]?.nameJa;
    if (resolved != null && resolved.isNotEmpty) return resolved;
    if (bean.origin.isNotEmpty) return bean.origin;
    return null;
  }

  Future<void> _onBrew(BeanMaster bean, RecipeSuggestion suggestion) async {
    final service = ref.read(dataServiceProvider);
    final accepted = suggestion.copyWith(accepted: 'yes');
    try {
      await service.saveRecipeSuggestion(accepted);
      debugPrint('[Antigravity] Action: レシピ提案を採用 (id=${accepted.id}, bean=${bean.id})');
    } catch (e) {
      debugPrint('[Antigravity] Error: レシピ提案(採用)の保存に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提案の保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (!mounted) return;
    setState(() => _handledBeanIds.add(bean.id));

    // 031(評価画面)へ条件をプリフィルして遷移。記録保存完了時に
    // resultRecordId を書き戻すため、採用済みの提案を引き継ぐ。
    const defaultBeanWeight = 15.0;
    final info = PendingBrewInfo(
      brewedAt: DateTime.now(),
      bean: bean,
      beanWeight: defaultBeanWeight,
      totalWater: suggestion.brewRatio * defaultBeanWeight,
      totalTime: suggestion.totalTimeSec,
      bloomingWater: 0,
      bloomingTime: 0,
      temperature: suggestion.temperature,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrewEvaluationScreen(info: info, pendingSuggestion: accepted),
      ),
    );
  }

  Future<void> _onPass(BeanMaster bean, RecipeSuggestion suggestion) async {
    final service = ref.read(dataServiceProvider);
    try {
      await service.saveRecipeSuggestion(suggestion.copyWith(accepted: 'no'));
      debugPrint('[Antigravity] Action: レシピ提案をパス (id=${suggestion.id}, bean=${bean.id})');
    } catch (e) {
      debugPrint('[Antigravity] Error: レシピ提案(パス)の保存に失敗 $e');
    }
    if (!mounted) return;
    setState(() => _handledBeanIds.add(bean.id));
  }
}

class _Candidate {
  final BeanMaster bean;
  final RecipeSuggestion suggestion;
  _Candidate(this.bean, this.suggestion);
}

class _SuggestionTile extends StatelessWidget {
  final BeanMaster bean;
  final RecipeSuggestion suggestion;
  final String? recommendedRoast;
  final VoidCallback onBrew;
  final VoidCallback onPass;

  const _SuggestionTile({
    required this.bean,
    required this.suggestion,
    required this.recommendedRoast,
    required this.onBrew,
    required this.onPass,
  });

  bool get _roastMatches {
    if (recommendedRoast == null) return false;
    final a = roastOrdinalMap[bean.roastLevel];
    final b = roastOrdinalMap[recommendedRoast];
    return a != null && a == b;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBoardBgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kChalkAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bean.name,
            style: const TextStyle(
              color: kChalkWhite,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '今日はこのレシピはいかが?',
            style: TextStyle(color: kChalkMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.thermostat, '${suggestion.temperature.toStringAsFixed(0)}℃'),
              _chip(Icons.percent, '湯:豆 1:${suggestion.brewRatio.toStringAsFixed(1)}'),
              _chip(Icons.timer_outlined, _formatTime(suggestion.totalTimeSec)),
            ],
          ),
          if (recommendedRoast != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 14, color: kChalkAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'この産地は$recommendedRoastが高評価です',
                    style: const TextStyle(color: kChalkMuted, fontSize: 12),
                  ),
                ),
                if (_roastMatches)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kChalkAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'おすすめ焙煎度と一致',
                      style: TextStyle(color: kChalkAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBrew,
                  icon: const Icon(Icons.coffee, size: 18),
                  label: const Text('この条件で淹れる'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kChalkAccent,
                    foregroundColor: kBoardBg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onPass,
                style: TextButton.styleFrom(foregroundColor: kChalkMuted),
                child: const Text('今回はパス'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kBoardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kChalkAccent),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: kChalkWhite, fontSize: 12)),
        ],
      ),
    );
  }
}
