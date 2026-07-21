import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analysis_snapshot.dart';
import '../../models/coffee_record.dart';
import '../../providers/data_providers.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/preference_service.dart';

/// F5: 好みプロファイルセクション (設計書§7.3、T4-4c)。
///
/// 設計書§7.3の3項目:
///   1. 最新プロファイルのstatementsをカード表示。
///   2. グループ統計テーブル: 産地×焙煎/n/平均[95%CI]/p/有意バッジ(n<5は「n不足」)。
///   3. 履歴タブ: analysis_historyのtype='preference'から、選択したグループの
///      平均の推移を折れ線+CI帯で表示。
///
/// 数値計算(層別統計・Welch検定・Bonferroni補正)は`PreferenceService`に委譲済み
/// (T4-4a)。本ウィジェットは表示のみを担う。
class PreferenceSection extends ConsumerWidget {
  final List<CoffeeRecord> records;
  const PreferenceSection({super.key, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrigins = ref.watch(originMasterProvider);

    return asyncOrigins.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('産地マスタの読み込みエラー: $err', style: const TextStyle(color: kMocha)),
      ),
      data: (origins) {
        final originById = {for (final o in origins) o.id: o};
        final profile = PreferenceService().build(records, originById);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statementsCard(profile),
            const SizedBox(height: 16),
            if (profile.groups.isNotEmpty) ...[
              const Text('グループ統計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kEspresso)),
              const SizedBox(height: 8),
              _groupTable(profile),
              const SizedBox(height: 20),
            ],
            _HistorySection(currentGroups: profile.groups),
          ],
        );
      },
    );
  }

  // --- 1. statementsカード ---

  Widget _statementsCard(PreferenceProfile profile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kLatte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in profile.statements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('・$s', style: const TextStyle(fontSize: 12, color: kEspresso)),
            ),
        ],
      ),
    );
  }

  // --- 2. グループ統計テーブル ---

  Widget _groupTable(PreferenceProfile profile) {
    return Table(
      border: TableBorder.all(color: kLatte, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(0.6),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(children: [
          _cell('産地×焙煎', bold: true),
          _cell('n', bold: true),
          _cell('平均 [95%CI]', bold: true),
          _cell('p', bold: true),
          _cell('判定', bold: true),
        ]),
        for (final g in profile.groups)
          TableRow(children: [
            _cell('${g.originLevel}×${g.roastLabel}'),
            _cell('${g.n}'),
            _cell('${g.mean.toStringAsFixed(1)} [${g.ciLower.toStringAsFixed(1)}, ${g.ciUpper.toStringAsFixed(1)}]'),
            _cell(g.welchP != null ? g.welchP!.toStringAsFixed(3) : '-'),
            _judgementBadge(g),
          ]),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: kEspresso,
          ),
        ),
      );

  Widget _judgementBadge(PreferenceGroupStat g) {
    String label;
    Color color;
    if (g.n < 5) {
      label = 'n不足';
      color = kMocha;
    } else if (g.significant) {
      label = '有意';
      color = kAccent;
    } else {
      label = '有意差なし';
      color = kMocha;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// 設計書§7.3項目3: 履歴タブ(選択グループの平均推移+CI帯)。
class _HistorySection extends ConsumerStatefulWidget {
  final List<PreferenceGroupStat> currentGroups;
  const _HistorySection({required this.currentGroups});

  @override
  ConsumerState<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<_HistorySection> {
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final asyncSnapshots = ref.watch(preferenceSnapshotsProvider);

    return asyncSnapshots.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('履歴の読み込みエラー: $err', style: const TextStyle(color: kMocha)),
      ),
      data: (snapshots) {
        final parsed = _parseSnapshots(snapshots);
        if (parsed.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('履歴データがまだありません(抽出記録を登録すると自動的に蓄積されます)',
                style: TextStyle(fontSize: 12, color: kMocha)),
          );
        }

        // 全履歴に登場したグループキー一覧(ドロップダウン用)。
        final keyToLabel = <String, String>{};
        for (final snap in parsed) {
          for (final g in snap.groups) {
            keyToLabel['${g.originLevel}|${g.roastLabel}'] = '${g.originLevel}×${g.roastLabel}';
          }
        }
        final keys = keyToLabel.keys.toList()..sort();
        if (keys.isEmpty) return const SizedBox.shrink();

        _selectedKey ??= _defaultKey(keys);

        final series = <_HistoryPoint>[];
        for (var i = 0; i < parsed.length; i++) {
          final match = parsed[i].groups.where((g) => '${g.originLevel}|${g.roastLabel}' == _selectedKey);
          if (match.isEmpty) continue;
          final g = match.first;
          series.add(_HistoryPoint(index: series.length, createdAt: parsed[i].createdAt, mean: g.mean, ciLower: g.ciLower, ciUpper: g.ciUpper));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('履歴: グループ別の平均の推移', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kEspresso)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedKey,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '表示するグループ', border: OutlineInputBorder()),
              items: [for (final k in keys) DropdownMenuItem(value: k, child: Text(keyToLabel[k]!))],
              onChanged: (v) => setState(() => _selectedKey = v),
            ),
            const SizedBox(height: 12),
            if (series.length < 2)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('このグループの履歴が2件未満のため折れ線を描画できません', style: TextStyle(fontSize: 12, color: kMocha)),
              )
            else
              SizedBox(height: 220, child: _historyChart(series)),
          ],
        );
      },
    );
  }

  String _defaultKey(List<String> keys) {
    // 現在のプロファイルで最もmeanが高いグループがあればそれを既定選択にする。
    for (final g in widget.currentGroups) {
      final key = '${g.originLevel}|${g.roastLabel}';
      if (keys.contains(key)) return key;
    }
    return keys.first;
  }

  List<_ParsedSnapshot> _parseSnapshots(List<AnalysisSnapshot> snapshots) {
    final result = <_ParsedSnapshot>[];
    for (final s in snapshots) {
      try {
        final decoded = json.decode(s.payloadJson) as Map<String, dynamic>;
        final groupsJson = (decoded['groups'] as List?) ?? const [];
        final groups = groupsJson
            .whereType<Map>()
            .map((m) => _HistoryGroup(
                  originLevel: (m['originLevel'] ?? '').toString(),
                  roastLabel: (m['roastLabel'] ?? '').toString(),
                  mean: (m['mean'] as num?)?.toDouble() ?? 0.0,
                  ciLower: (m['ciLower'] as num?)?.toDouble() ?? 0.0,
                  ciUpper: (m['ciUpper'] as num?)?.toDouble() ?? 0.0,
                ))
            .toList();
        result.add(_ParsedSnapshot(createdAt: s.createdAt, groups: groups));
      } catch (_) {
        // 壊れたJSONは無視して他の履歴で描画を続ける。
        continue;
      }
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Widget _historyChart(List<_HistoryPoint> series) {
    final meanSpots = [for (final p in series) FlSpot(p.index.toDouble(), p.mean)];
    final lowerSpots = [for (final p in series) FlSpot(p.index.toDouble(), p.ciLower)];
    final upperSpots = [for (final p in series) FlSpot(p.index.toDouble(), p.ciUpper)];

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: true, border: Border.all(color: kLatte)),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                final d = series[i].createdAt;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 9, color: kMocha)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(spots: lowerSpots, isCurved: false, color: Colors.transparent, barWidth: 0, dotData: const FlDotData(show: false)),
          LineChartBarData(spots: upperSpots, isCurved: false, color: Colors.transparent, barWidth: 0, dotData: const FlDotData(show: false)),
          LineChartBarData(spots: meanSpots, isCurved: false, color: kAccent, barWidth: 2, dotData: const FlDotData(show: true)),
        ],
        // 95%CI帯: lowerSpots(index0)〜upperSpots(index1)の間を塗りつぶす。
        betweenBarsData: [BetweenBarsData(fromIndex: 0, toIndex: 1, color: kAccent.withValues(alpha: 0.15))],
      ),
    );
  }
}

class _ParsedSnapshot {
  final DateTime createdAt;
  final List<_HistoryGroup> groups;
  _ParsedSnapshot({required this.createdAt, required this.groups});
}

class _HistoryGroup {
  final String originLevel;
  final String roastLabel;
  final double mean;
  final double ciLower;
  final double ciUpper;
  _HistoryGroup({
    required this.originLevel,
    required this.roastLabel,
    required this.mean,
    required this.ciLower,
    required this.ciUpper,
  });
}

class _HistoryPoint {
  final int index;
  final DateTime createdAt;
  final double mean;
  final double ciLower;
  final double ciUpper;
  _HistoryPoint({
    required this.index,
    required this.createdAt,
    required this.mean,
    required this.ciLower,
    required this.ciUpper,
  });
}
