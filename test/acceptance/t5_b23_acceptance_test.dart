// 受け入れテスト: T5-B23
// 完了条件(docs/改修マスタープラン.md より): 画面: ホーム / goldenあり。
// `ui_verifier`の7項目で指摘なし
//
// 本ファイルは委譲プロンプトで確定した以下3条件を機械判定する。
// (a) `PublicScreen.home`が存在しIDが`P100`であること
// (b) ホーム画面の空状態が`デザイン方針.md` §10「ホーム 0件」の文言と一致すること
// (c) goldenファイルが存在すること
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/routing/public_screen.dart';
import 'package:bean_base/screens/public/home_screen.dart';
import 'package:bean_base/theme/public/bb_theme.dart';

import '../helpers/fake_master_notifiers.dart';

void main() {
  group('受け入れ(T5-B23)', () {
    test('(a) PublicScreen.homeが存在しIDがP100である', () {
      expect(PublicScreen.values, contains(PublicScreen.home));
      expect(PublicScreen.home.id, 'P100');
    });

    testWidgets('(b) ホーム画面の空状態がデザイン方針.md §10の文言と一致する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coffeeRecordsProvider.overrideWith((ref) async => []),
            beanMasterProvider.overrideWith(
              () => FakeBeanMasterNotifier(() async => []),
            ),
          ],
          child: MaterialApp(
            theme: buildPublicTheme(Brightness.light),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('まだ記録がありません'), findsOneWidget);
      expect(find.text('1杯淹れると、味の傾向が見えはじめます。'), findsOneWidget);
      expect(find.text('はじめての抽出を記録する'), findsOneWidget);
    });

    test('(c) ホーム画面のgoldenファイルが存在する', () {
      const paths = [
        'test/golden/goldens/public/home_screen_with_records_light.png',
        'test/golden/goldens/public/home_screen_with_records_dark.png',
        'test/golden/goldens/public/home_screen_empty_light.png',
        'test/golden/goldens/public/home_screen_empty_dark.png',
        'test/golden/goldens/public/home_screen_weekly_records_light.png',
        'test/golden/goldens/public/home_screen_weekly_records_dark.png',
      ];
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path が存在しません');
      }
    });
  });
}
