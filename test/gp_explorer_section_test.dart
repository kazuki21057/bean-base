import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/widgets/brew/gp_explorer_section.dart';

/// T4-6b(設計書§7.5): F4レシピ探索セクション(GP予測ヒートマップ)の検証。
/// 産地×焙煎度に十分な記録があるとヒートマップ+推奨条件が表示されること、
/// n_eff<10のときは最小データ案内、産地紐付け記録が無いときの案内を確認する。
CoffeeRecord _record(
  String id, {
  required String originId,
  required String roastLevel,
  required int score,
  double temperature = 92,
  double beanWeight = 15,
  double totalWater = 225,
  int totalTime = 150,
}) {
  return CoffeeRecord(
    id: id,
    brewedAt: DateTime(2026, 7, 20),
    beanId: 'b1',
    methodId: 'm',
    beanWeight: beanWeight,
    totalWater: totalWater,
    totalTime: totalTime,
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
    temperature: temperature,
    dripperId: '',
    filterId: '',
    grinderId: '',
    roastLevel: roastLevel,
    origin: '',
    originId: originId,
    concentration: '',
    bloomingWater: 30,
    bloomingTime: 30,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<CoffeeRecord> records,
  List<OriginMaster> origins = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coffeeRecordsProvider.overrideWith((ref) async => records),
        originMasterProvider.overrideWith((ref) async => origins),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: const GpExplorerSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final origins = [
    OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'Africa'),
  ];

  group('GpExplorerSection (T4-6b)', () {
    testWidgets('同グループに十分な記録があるとヒートマップと推奨条件を表示する', (tester) async {
      // origin_1×中煎り(順序値3)で12件 → 全て weight 1.0、n_eff=12 ≥ 10。
      // 条件を散らしてモデルが縮退しないようにする。
      final temps = [84.0, 86.0, 88.0, 90.0, 92.0, 94.0];
      final ratios = [225.0, 240.0, 210.0, 225.0, 255.0, 210.0];
      final times = [150, 165, 135, 180, 150, 195];
      final scores = [7, 8, 6, 9, 7, 8];
      final records = [
        for (var i = 0; i < 12; i++)
          _record('r$i',
              originId: 'origin_1',
              roastLevel: '中煎り',
              score: scores[i % 6],
              temperature: temps[i % 6],
              totalWater: ratios[i % 6],
              totalTime: times[i % 6]),
      ];

      await _pump(tester, records: records, origins: origins);

      // デフォルト選択(産地=origin_1、焙煎度=中煎り)でヒートマップが描画される。
      expect(find.textContaining('予測総合評価マップ'), findsOneWidget);
      expect(find.text('おすすめの条件'), findsOneWidget);
      expect(find.textContaining('95%予測区間'), findsOneWidget);
      // ヒートマップのヘッダ(比率ラベル)が出ている。
      expect(find.text('湯温\\比率'), findsOneWidget);
    });

    testWidgets('記録が少なくn_effが不足する場合は最小データ案内を表示する', (tester) async {
      // origin_1×中煎りが3件のみ → n_eff=3 < 10。
      final records = [
        for (var i = 0; i < 3; i++)
          _record('r$i', originId: 'origin_1', roastLevel: '中煎り', score: 7 + i),
      ];

      await _pump(tester, records: records, origins: origins);

      expect(find.textContaining('この属性の推薦にはデータが不足しています'), findsOneWidget);
      expect(find.text('おすすめの条件'), findsNothing);
    });

    testWidgets('産地が紐付いた記録が無い場合は案内文を表示する', (tester) async {
      final records = [
        _record('r0', originId: '', roastLevel: '中煎り', score: 8),
      ];

      await _pump(tester, records: records, origins: origins);

      expect(find.textContaining('産地が紐付いた抽出記録がまだありません'), findsOneWidget);
    });
  });
}
