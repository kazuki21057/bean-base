import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/origin_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/widgets/statistics/regression_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _roasts = ['浅煎り', '中浅煎り', '中煎り', '中深煎り', '深煎り'];

final _origins = [
  OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
];

CoffeeRecord _record(int i, {int? scoreOverride}) {
  return CoffeeRecord(
    id: 'r$i',
    brewedAt: DateTime(2026, 7, 21),
    grinderId: 'g',
    dripperId: 'd',
    filterId: 'f',
    beanId: 'b',
    roastLevel: _roasts[i % 5],
    origin: '',
    originId: 'origin_1',
    beanWeight: 15,
    grindSize: '',
    methodId: 'm',
    taste: '',
    concentration: '',
    // 各連続変数に周期の異なる変動+微小ドリフトを与え、共線性(ランク落ち)を避ける。
    temperature: 84 + (i % 9) + i * 0.03,
    bloomingWater: 0,
    totalWater: 215 + (i % 7) * 4 + i * 0.1,
    bloomingTime: 0,
    totalTime: 150 + (i % 6) * 8 + i,
    scoreFragrance: 0,
    scoreAcidity: 0,
    scoreBitterness: 0,
    scoreSweetness: 0,
    scoreComplexity: 0,
    scoreFlavor: 0,
    scoreOverall: scoreOverride ?? 4 + (i % 7),
    comment: '',
  );
}

Future<void> _pump(WidgetTester tester, List<CoffeeRecord> records) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        originMasterProvider.overrideWith((ref) async => _origins),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: RegressionSection(records: records)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RegressionSection (T4-2c1)', () {
    testWidgets('最小データ条件(§1.3)未満なら計算せず案内文を表示する', (tester) async {
      final records = [for (var i = 0; i < 5; i++) _record(i)];
      await _pump(tester, records);

      expect(find.textContaining('データが不足しています'), findsOneWidget);
      // 係数テーブルや散布図は描画されない。
      expect(find.text('残差 vs 予測値'), findsNothing);
    });

    testWidgets('十分なデータでモデルサマリ・係数・残差プロットを表示する', (tester) async {
      final records = [for (var i = 0; i < 40; i++) _record(i)];
      await _pump(tester, records);

      // モデルサマリのラベル。
      expect(find.text('件数 n'), findsOneWidget);
      expect(find.text('調整済み R²'), findsOneWidget);
      // 係数テーブルと残差プロットの見出し。
      expect(find.text('係数(総合評価への影響)'), findsOneWidget);
      expect(find.text('残差 vs 予測値'), findsOneWidget);
      // 案内文は出ない。
      expect(find.textContaining('データが不足しています'), findsNothing);
      expect(find.textContaining('線形従属'), findsNothing);
    });

    testWidgets('デフォルトスコア(7)が3割超なら未編集バイアス警告を表示する', (tester) async {
      // 全40件を scoreOverall=7 にすると 100% がデフォルト値。
      final records = [for (var i = 0; i < 40; i++) _record(i, scoreOverride: 7)];
      await _pump(tester, records);

      expect(find.textContaining('未編集保存によるバイアス'), findsOneWidget);
    });

    testWidgets('情報アイコンをタップすると§2.1.5の注意ダイアログが開く', (tester) async {
      final records = [for (var i = 0; i < 40; i++) _record(i)];
      await _pump(tester, records);

      await tester.tap(find.text('分析上の注意'));
      await tester.pumpAndSettle();

      expect(find.text('回帰分析を読むときの注意'), findsOneWidget);
      expect(find.textContaining('因果効果ではなく'), findsOneWidget);
    });
  });
}
