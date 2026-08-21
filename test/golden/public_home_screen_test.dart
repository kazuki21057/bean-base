// T5-B23: P100 ホーム画面(lib/screens/public/home_screen.dart)のgolden。
// 記録あり(週次0件)/0件/週次に実データありの3状態(ライト/ダーク)。
//
// 週次統計(抽出回数/平均総合評価)は`homeScreenClock`(トップレベル関数変数、
// T5-B23 adversaryレビューMajor-2対応)が返す「現在時刻」基準で「今週」を
// 判定する。1つ目のケースはフィクスチャの`brewedAt`を十分に過去(2024年)の
// 固定日時にし、`homeScreenClock`を差し替えず(=実行時の`DateTime.now()`の
// まま)常に「今週」に含まれない(=0件・'-')状態を描画する(最後の抽出・
// 最近の記録は`brewedAt`の値自体をそのまま表示するため影響しない)。
// 3つ目のケースは逆に`homeScreenClock`を固定日時(2026-08-27木曜)を返す
// 関数に差し替え、同じ週(2026-08-24月曜始まり)の`brewedAt`を持つ記録を
// 12件用意することで、抽出回数が2桁・平均総合評価が小数になる分岐を
// 再現性のあるgoldenとして固定する(adversaryレビューMajor-1対応、T5-B23)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/public/home_screen.dart';
import 'package:bean_base/theme/public/bb_theme.dart';

import '../helpers/fake_master_notifiers.dart';
import 'golden_test_helper.dart';

CoffeeRecord _record({
  required String id,
  required String beanId,
  required DateTime brewedAt,
  required int scoreOverall,
}) {
  return CoffeeRecord(
    id: id,
    brewedAt: brewedAt,
    grinderId: 'g1',
    dripperId: 'd1',
    filterId: 'f1',
    beanId: beanId,
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
    scoreOverall: scoreOverall,
    comment: '',
  );
}

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';
    final theme = buildPublicTheme(brightness);

    testWidgets('HomeScreen golden(記録あり, $suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: ProviderScope(
          overrides: [
            coffeeRecordsProvider.overrideWith(
              (ref) async => [
                _record(
                  id: '1',
                  beanId: 'b1',
                  brewedAt: DateTime(2024, 1, 10, 8, 30),
                  scoreOverall: 4,
                ),
                _record(
                  id: '2',
                  beanId: 'b1',
                  brewedAt: DateTime(2024, 1, 11, 9),
                  scoreOverall: 3,
                ),
                _record(
                  id: '3',
                  beanId: 'b2',
                  brewedAt: DateTime(2024, 1, 12, 7, 45),
                  scoreOverall: 5,
                ),
                _record(
                  id: '4',
                  beanId: 'b2',
                  brewedAt: DateTime(2024, 1, 13, 8, 15),
                  scoreOverall: 4,
                ),
              ],
            ),
            beanMasterProvider.overrideWith(
              () => FakeBeanMasterNotifier(
                () async => [
                  BeanMaster(
                    id: 'b1',
                    name: 'エチオピア イルガチェフェ',
                    roastLevel: '浅煎り',
                    origin: 'エチオピア',
                  ),
                  BeanMaster(
                    id: 'b2',
                    name: 'ブラジル セラード',
                    roastLevel: '中煎り',
                    origin: 'ブラジル',
                  ),
                ],
              ),
            ),
          ],
          child: const HomeScreen(),
        ),
        brightness: brightness,
        theme: theme,
        width: 412,
        height: 915,
        goldenPath: 'goldens/public/home_screen_with_records_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('HomeScreen golden(0件, $suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: ProviderScope(
          overrides: [
            coffeeRecordsProvider.overrideWith((ref) async => []),
            beanMasterProvider.overrideWith(
              () => FakeBeanMasterNotifier(() async => []),
            ),
          ],
          child: const HomeScreen(),
        ),
        brightness: brightness,
        theme: theme,
        width: 412,
        height: 915,
        goldenPath: 'goldens/public/home_screen_empty_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('HomeScreen golden(今週12件・平均4.3, $suffix)', (tester) async {
      // 2026-08-24(月)始まりの週。12件すべてこの週内の`brewedAt`にし、
      // 抽出回数が2桁、平均総合評価(合計52/12=4.333...→表示上4.3)が
      // 小数になる分岐でのレイアウト崩れを検証する。
      final fixedNow = DateTime(2026, 8, 27, 18, 0);
      homeScreenClock = () => fixedNow;
      addTearDown(() => homeScreenClock = DateTime.now);
      final weeklyRecords = [
        _record(id: '1', beanId: 'b1', brewedAt: DateTime(2026, 8, 24, 8), scoreOverall: 4),
        _record(id: '2', beanId: 'b1', brewedAt: DateTime(2026, 8, 24, 12), scoreOverall: 4),
        _record(id: '3', beanId: 'b1', brewedAt: DateTime(2026, 8, 25, 8), scoreOverall: 4),
        _record(id: '4', beanId: 'b1', brewedAt: DateTime(2026, 8, 25, 12), scoreOverall: 4),
        _record(id: '5', beanId: 'b1', brewedAt: DateTime(2026, 8, 25, 18), scoreOverall: 5),
        _record(id: '6', beanId: 'b1', brewedAt: DateTime(2026, 8, 26, 8), scoreOverall: 4),
        _record(id: '7', beanId: 'b1', brewedAt: DateTime(2026, 8, 26, 12), scoreOverall: 4),
        _record(id: '8', beanId: 'b1', brewedAt: DateTime(2026, 8, 26, 18), scoreOverall: 5),
        _record(id: '9', beanId: 'b1', brewedAt: DateTime(2026, 8, 27, 8), scoreOverall: 4),
        _record(id: '10', beanId: 'b1', brewedAt: DateTime(2026, 8, 27, 10), scoreOverall: 4),
        _record(id: '11', beanId: 'b1', brewedAt: DateTime(2026, 8, 27, 12), scoreOverall: 5),
        _record(id: '12', beanId: 'b1', brewedAt: DateTime(2026, 8, 27, 15), scoreOverall: 5),
      ];

      await pumpAndMatchGolden(
        tester,
        child: ProviderScope(
          overrides: [
            coffeeRecordsProvider.overrideWith((ref) async => weeklyRecords),
            beanMasterProvider.overrideWith(
              () => FakeBeanMasterNotifier(
                () async => [
                  BeanMaster(
                    id: 'b1',
                    name: 'エチオピア イルガチェフェ',
                    roastLevel: '浅煎り',
                    origin: 'エチオピア',
                  ),
                ],
              ),
            ),
          ],
          child: const HomeScreen(),
        ),
        brightness: brightness,
        theme: theme,
        width: 412,
        height: 915,
        goldenPath: 'goldens/public/home_screen_weekly_records_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);
  }
}
