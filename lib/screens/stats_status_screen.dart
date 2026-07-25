import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coffee_record.dart';
import '../models/origin_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/gp_service.dart';
import '../services/math/design_matrix.dart';
import '../services/math/encoding.dart';
import '../services/preference_service.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';
import 'stats_theory_screen.dart';

/// 042 統計処理の稼働状況 (T3-36)。
///
/// F1(回帰)/F2(PCA)/F4(GP)/F5(好み検定)それぞれについて、現在のデータで
/// 計算が実行できる状態か(設計書§1.3の最小データ条件)を一覧表示する。
/// offの場合は有効化に必要な条件を、各項目からは[StatsTheoryLink]経由で
/// 041の該当セクションへ遷移できる。090から遷移して開く。
///
/// 数値計算は既存の各サービス(`RegressionService`用の`buildRegressionMatrix`/
/// `StatisticsService.calculatePca`/`PreferenceService`/`GpService`)が持つ
/// 最小データ条件の判定ロジックをそのまま呼び出す(CLAUDE.md絶対規則:
/// 数値計算はDartローカル実装、新規ロジックを本ページで発明しない)。
class StatsStatusScreen extends ConsumerWidget {
  const StatsStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(coffeeRecordsProvider);
    final asyncOrigins = ref.watch(originMasterProvider);

    return MockScreenScaffold(
      screen: AppScreen.statsStatus,
      children: [
        FormSection(
          icon: Icons.rule_folder_outlined,
          title: '統計処理の稼働状況',
          children: [
            const Text(
              '現在のデータ件数で各機能の計算が実行できるかを表示します。'
              '赤色の項目は、右側の本アイコンから理論説明(041)を確認できます。',
              style: TextStyle(fontSize: 13, color: kMocha),
            ),
            const SizedBox(height: 12),
            if (asyncRecords.isLoading || asyncOrigins.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (asyncRecords.hasError)
              Text('抽出履歴の読み込みエラー: ${asyncRecords.error}', style: const TextStyle(color: Colors.red))
            else if (asyncOrigins.hasError)
              Text('産地マスタの読み込みエラー: ${asyncOrigins.error}', style: const TextStyle(color: Colors.red))
            else
              ..._buildRows(asyncRecords.value ?? const [], asyncOrigins.value ?? const []),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildRows(List<CoffeeRecord> records, List<OriginMaster> origins) {
    final originById = {for (final o in origins) o.id: o};

    final items = [
      _statusRow('重回帰分析 (F1)', StatsTheorySection.regression, _f1Status(records, originById)),
      _statusRow('主成分分析 / PCA (F2)', StatsTheorySection.pca, _f2Status(records)),
      _statusRow('ガウス過程回帰・探索 (F4)', StatsTheorySection.gp, _f4Status(records, originById)),
      _statusRow('好みの傾向の検定 (F5)', StatsTheorySection.preference, _f5Status(records, originById)),
    ];

    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      widgets.add(items[i]);
      if (i != items.length - 1) widgets.add(const Divider(height: 24));
    }
    return widgets;
  }

  Widget _statusRow(String title, StatsTheorySection section, _FeatureStatus status) {
    final color = status.on ? Colors.green : Colors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kEspresso)),
              const SizedBox(height: 2),
              Text(
                status.on ? '稼働中 — ${status.detail}' : '未稼働 — ${status.detail}',
                style: TextStyle(fontSize: 13, color: status.on ? Colors.green.shade800 : Colors.red.shade800),
              ),
            ],
          ),
        ),
        StatsTheoryLink(section: section, tooltip: '$titleの理論を読む'),
      ],
    );
  }
}

class _FeatureStatus {
  final bool on;
  final String detail;
  const _FeatureStatus(this.on, this.detail);
}

/// F1(設計書§1.3): n ≥ 30 かつ n ≥ 5×説明変数。
_FeatureStatus _f1Status(List<CoffeeRecord> records, Map<String, OriginMaster> originById) {
  final design = buildRegressionMatrix(records, originById);
  final n = design.x.length;
  final p = design.columnNames.length - 1;
  final required = math.max(30, 5 * p);
  if (n < required) {
    return _FeatureStatus(false, 'データが不足しています (必要: $required件, 現在: $n件)');
  }
  return _FeatureStatus(true, '現在 $n 件のデータで計算できます');
}

/// F2(設計書§1.3): n ≥ 3 (既存踏襲)。
_FeatureStatus _f2Status(List<CoffeeRecord> records) {
  const required = 3;
  final n = records.length;
  if (n < required) {
    return _FeatureStatus(false, 'データが不足しています (必要: $required件, 現在: $n件)');
  }
  return _FeatureStatus(true, '現在 $n 件のデータで計算できます');
}

/// F5(設計書§1.3): グループ(産地×焙煎度) n ≥ 3 で統計量表示。
_FeatureStatus _f5Status(List<CoffeeRecord> records, Map<String, OriginMaster> originById) {
  const required = 3;
  final profile = PreferenceService().build(records, originById);
  final maxGroupN = profile.groups.isEmpty
      ? 0
      : profile.groups.map((g) => g.n).reduce((a, b) => a > b ? a : b);
  if (maxGroupN < required) {
    return _FeatureStatus(
      false,
      'グループ(産地×焙煎度)ごとに$required件以上必要です (現在の最大グループ: $maxGroupN件)',
    );
  }
  return _FeatureStatus(true, '産地×焙煎度グループの最大$maxGroupN件で統計量を表示できます');
}

/// F4(設計書§1.3): 重み付き有効サンプル数 n_eff ≥ 10。
/// 代表として最新記録の産地×焙煎度でフィットを試みる。設計書§7.5の重み付けでは
/// 一致しない記録も最低0.2の重みで寄与するため、どの組み合わせで試してもほぼ
/// 同じ判定になる(=全体のデータ量に対する稼働状況の概況として妥当)。
_FeatureStatus _f4Status(List<CoffeeRecord> records, Map<String, OriginMaster> originById) {
  if (records.isEmpty) {
    return const _FeatureStatus(false, 'この属性の推薦にはデータが不足しています (n_eff < 10)');
  }
  final sample = records.last;
  final roastOrdinal = roastOrdinalMap[sample.roastLevel] ?? 3.0;
  final model = GpService().fit(records, sample.originId, roastOrdinal, originById);
  if (model == null) {
    return const _FeatureStatus(false, 'この属性の推薦にはデータが不足しています (n_eff < 10)');
  }
  return _FeatureStatus(true, '有効サンプル数 n_eff=${model.nEff.toStringAsFixed(1)} で推薦できます');
}
