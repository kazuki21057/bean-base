import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:bean_base/models/analysis_snapshot.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/widgets/statistics/preference_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CoffeeRecord _record(String id, int score, {String origin = '', String roastLevel = '浅煎り'}) {
  return CoffeeRecord(
    id: id,
    brewedAt: DateTime(2026, 7, 21),
    beanId: 'b',
    methodId: 'm',
    beanWeight: 15,
    totalWater: 225,
    totalTime: 150,
    scoreOverall: score,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    taste: '',
    comment: '',
    grindSize: '',
    temperature: 90,
    dripperId: '',
    filterId: '',
    grinderId: '',
    roastLevel: roastLevel,
    origin: origin,
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

// §9.6と同じ構成: エチオピア×浅煎り(n=5, 高評価)+5つの小グループ(各n=2)。
final _groupA = [
  _record('a1', 8, origin: 'エチオピア', roastLevel: '浅煎り'),
  _record('a2', 9, origin: 'エチオピア', roastLevel: '浅煎り'),
  _record('a3', 8, origin: 'エチオピア', roastLevel: '浅煎り'),
  _record('a4', 9, origin: 'エチオピア', roastLevel: '浅煎り'),
  _record('a5', 8, origin: 'エチオピア', roastLevel: '浅煎り'),
];
final _restGroups = [
  [_record('r1', 5, origin: 'ブラジル', roastLevel: '中煎り'), _record('r2', 6, origin: 'ブラジル', roastLevel: '中煎り')],
  [_record('r3', 5, origin: 'コロンビア', roastLevel: '中深煎り'), _record('r4', 6, origin: 'コロンビア', roastLevel: '中深煎り')],
  [_record('r5', 5, origin: 'グアテマラ', roastLevel: '深煎り'), _record('r6', 6, origin: 'グアテマラ', roastLevel: '深煎り')],
  [_record('r7', 5, origin: 'ケニア', roastLevel: '中浅煎り'), _record('r8', 6, origin: 'ケニア', roastLevel: '中浅煎り')],
  [_record('r9', 5, origin: 'ホンジュラス', roastLevel: '浅煎り'), _record('r10', 6, origin: 'ホンジュラス', roastLevel: '浅煎り')],
];
final _records = [..._groupA, ..._restGroups.expand((g) => g)];

Future<void> _pump(
  WidgetTester tester,
  List<CoffeeRecord> records, {
  List<AnalysisSnapshot> snapshots = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        originMasterProvider.overrideWith((ref) async => <OriginMaster>[]),
        preferenceSnapshotsProvider.overrideWith((ref) async => snapshots),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: PreferenceSection(records: records)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AnalysisSnapshot _snapshot(DateTime createdAt, List<Map<String, dynamic>> groups) {
  return AnalysisSnapshot(
    id: 'snap_${createdAt.millisecondsSinceEpoch}',
    createdAt: createdAt,
    type: 'preference',
    dataCount: 10,
    payloadJson: json.encode({'createdAt': createdAt.toIso8601String(), 'totalRecords': 10, 'groups': groups, 'statements': []}),
  );
}

void main() {
  group('PreferenceSection (T4-4c)', () {
    testWidgets('statementsカードとグループ統計テーブルが表示される', (tester) async {
      await _pump(tester, _records);

      expect(find.textContaining('「エチオピア×浅煎り」を高評価する傾向'), findsOneWidget);
      expect(find.text('グループ統計'), findsOneWidget);
      expect(find.textContaining('エチオピア×浅煎り'), findsWidgets);
      expect(find.text('有意'), findsOneWidget);
      // n=2の小グループは「n不足」バッジ。
      expect(find.text('n不足'), findsWidgets);
    });

    testWidgets('有意なグループが無い場合は固定の案内文を表示する(n<5のグループ自体は統計テーブルに残る)', (tester) async {
      final flat = [for (var i = 0; i < 3; i++) _record('f$i', 7, origin: 'ブレンド', roastLevel: '中煎り')];
      await _pump(tester, flat);

      expect(find.textContaining('現時点で統計的に明確な好みの偏りは検出されていません'), findsOneWidget);
      // n=3<5の唯一のグループはstatements対象外だが、グループ統計テーブル自体には
      // 「n不足」として表示される(グループが1件以上あれば表を出す設計のため)。
      expect(find.text('グループ統計'), findsOneWidget);
      expect(find.text('n不足'), findsOneWidget);
    });

    testWidgets('履歴が無い場合は案内文を表示する', (tester) async {
      await _pump(tester, _records, snapshots: const []);

      expect(find.textContaining('履歴データがまだありません'), findsOneWidget);
    });

    testWidgets('履歴が2件以上あればグループ選択ドロップダウンと折れ線グラフを表示する', (tester) async {
      final snapshots = [
        _snapshot(DateTime(2026, 7, 1), [
          {'originLevel': 'エチオピア', 'roastLabel': '浅煎り', 'mean': 8.0, 'ciLower': 7.0, 'ciUpper': 9.0},
        ]),
        _snapshot(DateTime(2026, 7, 15), [
          {'originLevel': 'エチオピア', 'roastLabel': '浅煎り', 'mean': 8.4, 'ciLower': 7.7, 'ciUpper': 9.1},
        ]),
      ];
      await _pump(tester, _records, snapshots: snapshots);

      expect(find.text('履歴: グループ別の平均の推移'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
