// 受け入れテスト: T5-B25
// 完了条件(docs/改修マスタープラン.md より): 画面: インサイト(表示層のみ) /
// goldenあり。`ui_verifier`の7項目で指摘なし
//
// 本ファイルは委譲プロンプトで確定した以下3条件を機械判定する。
// (a) `PublicScreen.insight`のIDが`P300`、`PublicScreen.insightDetail`の
//     IDが`P310`であること
// (b) InsightScreenのプレースホルダ文言が固定されていること
//     (禁止語チェック: 「PCA」「回帰係数」「p値」「寄与率」「固有値」を
//     含まないこと)
// (c) 4枚のgoldenファイルが存在すること
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/routing/public_screen.dart';
import 'package:bean_base/screens/public/insight_detail_screen.dart';
import 'package:bean_base/screens/public/insight_screen.dart';

const _forbiddenWords = ['PCA', '回帰係数', 'p値', '寄与率', '固有値'];

void main() {
  group('受け入れ(T5-B25)', () {
    test('(a) PublicScreen.insight/insightDetailのIDがP300/P310である', () {
      expect(PublicScreen.values, contains(PublicScreen.insight));
      expect(PublicScreen.values, contains(PublicScreen.insightDetail));
      expect(PublicScreen.insight.id, 'P300');
      expect(PublicScreen.insightDetail.id, 'P310');
    });

    testWidgets('(b) InsightScreenのプレースホルダ文言が固定され禁止語を含まない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: InsightScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('インサイト'), findsWidgets);
      expect(find.text('インサイトは準備中です'), findsOneWidget);
      expect(find.text('記録がたまると、ここに味の傾向が表示されます。'), findsOneWidget);

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final allText = textWidgets.map((w) => w.data ?? '').join('\n');
      for (final word in _forbiddenWords) {
        expect(allText.contains(word), isFalse, reason: '禁止語"$word"が含まれています');
      }
    });

    testWidgets('(b) InsightDetailScreenのプレースホルダ文言が固定され禁止語を含まない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: InsightDetailScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('インサイトの詳細'), findsOneWidget);
      expect(find.text('この機能は準備中です'), findsOneWidget);

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final allText = textWidgets.map((w) => w.data ?? '').join('\n');
      for (final word in _forbiddenWords) {
        expect(allText.contains(word), isFalse, reason: '禁止語"$word"が含まれています');
      }
    });

    test('(c) インサイト画面のgoldenファイルが存在する', () {
      const paths = [
        'test/golden/goldens/public/insight_screen_light.png',
        'test/golden/goldens/public/insight_screen_dark.png',
        'test/golden/goldens/public/insight_detail_screen_light.png',
        'test/golden/goldens/public/insight_detail_screen_dark.png',
      ];
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path が存在しません');
      }
    });
  });
}
