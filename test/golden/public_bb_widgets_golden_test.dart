import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/theme/public/bb_colors.dart';
import 'package:bean_base/theme/public/bb_theme.dart';
import 'package:bean_base/widgets/public/bb_buttons.dart';
import 'package:bean_base/widgets/public/bb_card.dart';
import 'package:bean_base/widgets/public/bb_chip.dart';
import 'package:bean_base/widgets/public/bb_list_row.dart';
import 'package:bean_base/widgets/public/bb_section_header.dart';

import 'golden_test_helper.dart';

/// T5-B22(束1): 公開版共通コンポーネント(BbCard/BbListRow/BbSectionHeader/
/// BbPrimaryButton・BbTextButton/BbChip)のgolden(ライト/ダーク)。
void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';
    final theme = buildPublicTheme(brightness);
    final bbColors = theme.extension<BbColors>()!;

    testWidgets('BbCard golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: const BbCard(
          child: Text('コーヒー豆 エチオピア イルガチェフェ'),
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_card_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbListRow golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: BbListRow(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          title: 'エチオピア イルガチェフェ',
          subtitle: '浅煎り・水洗式',
          value: '18',
          unit: 'g',
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_list_row_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbSectionHeader golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: BbSectionHeader(
          eyebrow: '最近の記録',
          title: '履歴',
          actionLabel: 'すべて見る',
          onActionTap: () {},
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_section_header_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbPrimaryButton golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BbPrimaryButton(label: '抽出をはじめる', onPressed: () {}),
            const SizedBox(height: 12),
            BbPrimaryButton(
              label: '削除する',
              onPressed: () {},
              isDestructive: true,
            ),
            const SizedBox(height: 12),
            BbTextButton(label: 'キャンセル', onPressed: () {}),
          ],
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_primary_button_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbChip golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BbChip(label: 'すべて', selected: true, onSelected: (_) {}),
            BbChip(label: '浅煎り', onSelected: (_) {}),
            BbChip(
              label: '中深煎り',
              roastDotColor: bbColors.roastRamp[3],
              onSelected: (_) {},
            ),
          ],
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_chip_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);
  }

  // T5-B22(束1)夜間ループ敵対的レビューMajor-2: 上記ループは各コンポーネント
  // 1バリアントしか撮っておらず分岐が退行検知の外にあったため、未カバー分岐を
  // 個別に追加する(ライト固定。視覚差分が分かればライトのみで可)。
  final lightTheme = buildPublicTheme(Brightness.light);
  final lightBbColors = lightTheme.extension<BbColors>()!;

  testWidgets('BbCard golden(onTap分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: BbCard(
        onTap: () {},
        child: const Text('コーヒー豆 エチオピア イルガチェフェ'),
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_card_on_tap_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbListRow golden(leading/subtitle/value省略分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BbListRow(title: 'エチオピア イルガチェフェ'),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_list_row_minimal_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbPrimaryButton golden(isLoading分岐)', (tester) async {
    // isLoading中は`CircularProgressIndicator`が無限アニメーションするため、
    // `pumpAndMatchGolden`の`pumpAndSettle`だとタイムアウトする。固定フレームで撮る。
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          backgroundColor: lightTheme.scaffoldBackgroundColor,
          body: Center(
            child: SizedBox(
              width: 320,
              child: RepaintBoundary(
                key: goldenTargetKey,
                child: BbPrimaryButton(
                  label: '抽出をはじめる',
                  onPressed: () {},
                  isLoading: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byKey(goldenTargetKey),
      matchesGoldenFile('goldens/public/bb_primary_button_loading_light.png'),
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbChip golden(selected+roastDotColor同時分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: BbChip(
        label: '中深煎り',
        selected: true,
        roastDotColor: lightBbColors.roastRamp[3],
        onSelected: (_) {},
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_chip_selected_roast_dot_light.png',
    );
  }, skip: skipGoldenOnNonWindows);
}
