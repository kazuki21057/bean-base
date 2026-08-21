// T5-B23 adversaryレビューMajor-1対応: `PublicShell._tabs`が`static const`
// リストだったため、タブ切替の`setState`で`PublicShell`が再ビルドされても
// `HomeScreen`(`_HomeBody`)の`build()`が再実行されず、`homeScreenClock()`が
// 呼び直されない不具合の回帰テスト。`homeScreenClock`を差し替えた状態で
// タブ切替を行い、ホームタブに戻った際に「抽出回数(今週)」の表示が
// 最新の`homeScreenClock()`を反映して更新されることを確認する。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/public/home_screen.dart';
import 'package:bean_base/screens/public/public_shell.dart';
import 'package:bean_base/widgets/public/bb_stat_tile.dart';

import '../../helpers/fake_master_notifiers.dart';

CoffeeRecord _record({required DateTime brewedAt}) {
  return CoffeeRecord(
    id: '1',
    brewedAt: brewedAt,
    grinderId: 'g1',
    dripperId: 'd1',
    filterId: 'f1',
    beanId: 'b1',
    roastLevel: '中煎り',
    origin: 'エチオピア',
    beanWeight: 18,
    grindSize: '中挽き',
    methodId: 'm1',
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 30,
    totalWater: 280,
    bloomingTime: 30,
    totalTime: 150,
    scoreFragrance: 4,
    scoreAcidity: 4,
    scoreBitterness: 3,
    scoreSweetness: 4,
    scoreComplexity: 4,
    scoreFlavor: 4,
    scoreOverall: 4,
    comment: '',
  );
}

String _extractionCountValue(WidgetTester tester) {
  final tile = tester.widgetList<BbStatTile>(find.byType(BbStatTile)).firstWhere(
        (w) => w.label == '抽出回数(今週)',
      );
  return tile.value;
}

void main() {
  // 基準週: 2026-08-24(月)〜2026-08-30(日)。
  final mondayThisWeek = DateTime(2026, 8, 24, 0, 0, 0);
  final nowThisWeek = DateTime(2026, 8, 24, 10, 0);
  // 記録から10週間後: 記録が「今週」に含まれなくなる時刻。
  final nowManyWeeksLater = DateTime(2026, 11, 2, 10, 0);

  testWidgets(
    'タブ切替後にホームタブへ戻ると、homeScreenClockの変更が反映される'
    '(_tabsのstatic const化による再ビルド抑止の回帰テスト)',
    (tester) async {
      homeScreenClock = () => nowThisWeek;
      addTearDown(() => homeScreenClock = DateTime.now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coffeeRecordsProvider.overrideWith(
              (ref) async => [_record(brewedAt: mondayThisWeek)],
            ),
            beanMasterProvider.overrideWith(
              () => FakeBeanMasterNotifier(
                () async => [
                  BeanMaster(
                    id: 'b1',
                    name: 'テスト豆',
                    roastLevel: '中煎り',
                    origin: 'エチオピア',
                  ),
                ],
              ),
            ),
          ],
          child: const MaterialApp(home: PublicShell()),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 記録は基準時刻の週内なので「1」。
      expect(_extractionCountValue(tester), '1');

      // homeScreenClockを、記録がもう「今週」に含まれない時刻へ差し替える。
      homeScreenClock = () => nowManyWeeksLater;

      // 「履歴」タブへ切り替え→「ホーム」タブへ戻す。
      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      // タブ切替による再ビルドでhomeScreenClock()が呼び直され、
      // 「今週」の集計が更新されて「0」になっていること。
      expect(_extractionCountValue(tester), '0');
    },
  );
}
