import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/theme/public/bb_colors.dart';
import 'package:bean_base/theme/public/bb_theme.dart';
import 'package:bean_base/widgets/public/bb_bottom_sheet.dart';
import 'package:bean_base/widgets/public/bb_buttons.dart';
import 'package:bean_base/widgets/public/bb_card.dart';
import 'package:bean_base/widgets/public/bb_chip.dart';
import 'package:bean_base/widgets/public/bb_empty_state.dart';
import 'package:bean_base/widgets/public/bb_error_view.dart';
import 'package:bean_base/widgets/public/bb_extraction_ring.dart';
import 'package:bean_base/widgets/public/bb_list_row.dart';
import 'package:bean_base/widgets/public/bb_loading.dart';
import 'package:bean_base/widgets/public/bb_number_field.dart';
import 'package:bean_base/widgets/public/bb_section_header.dart';
import 'package:bean_base/widgets/public/bb_stat_tile.dart';

import 'golden_test_helper.dart';

/// T5-B22(束1): 公開版共通コンポーネント(BbCard/BbListRow/BbSectionHeader/
/// BbPrimaryButton・BbTextButton/BbChip)のgolden(ライト/ダーク)。
/// T5-B22(束2): BbEmptyState/BbLoadingSkeleton・BbLoadingSpinner/BbErrorViewを追加。
/// T5-B22(束3): BbBottomSheet/BbNumberField/BbStatTile/BbExtractionRingを追加。
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

    testWidgets('BbEmptyState golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: BbEmptyState(
          icon: Icons.local_cafe_outlined,
          title: 'まだ記録がありません',
          description: '1杯淹れると、味の傾向が見えはじめます。',
          actionLabel: 'はじめての抽出を記録する',
          onActionTap: () {},
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_empty_state_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbErrorView golden(フルスクリーン, $suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: BbErrorView(
          title: 'データを読み込めませんでした。',
          description: 'アプリを再起動しても直らない場合は、書き出したデータから復元してください。',
          onRetry: () {},
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_error_view_fullscreen_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbErrorView golden(インライン, $suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: BbErrorView(
          title: '記録を保存できませんでした。',
          description: '端末の空き容量を確認して、もう一度お試しください。',
          onRetry: () {},
          isInline: true,
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_error_view_inline_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbLoadingSkeleton golden($suffix)', (tester) async {
      // シマーアニメーションが無限周期のため`pumpAndSettle`はタイムアウトする。
      // 固定フレームで撮る(束1のBbPrimaryButton isLoading分岐と同じ方針)。
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: SizedBox(
                width: 320,
                child: RepaintBoundary(
                  key: goldenTargetKey,
                  child: const BbLoadingSkeleton(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byKey(goldenTargetKey),
        matchesGoldenFile('goldens/public/bb_loading_skeleton_$suffix.png'),
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbLoadingSpinner golden($suffix)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(
              child: SizedBox(
                width: 320,
                height: 120,
                child: RepaintBoundary(
                  key: goldenTargetKey,
                  child: BbLoadingSpinner(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byKey(goldenTargetKey),
        matchesGoldenFile('goldens/public/bb_loading_spinner_$suffix.png'),
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbBottomSheet golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: BbBottomSheet(
          title: '抽出パラメータ',
          actions: [
            BbTextButton(label: 'キャンセル', onPressed: () {}),
            BbPrimaryButton(label: '保存', onPressed: () {}),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('豆量・湯温・注湯ステップを調整できます。'),
          ),
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_bottom_sheet_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbNumberField golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: BbNumberField(
          label: '豆量',
          value: 18,
          min: 1,
          max: 100,
          unit: 'g',
          presets: const [15, 18, 20, 22],
          onChanged: (_) {},
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_number_field_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbStatTile golden($suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: Row(
          children: const [
            Expanded(
              child: BbStatTile(
                label: '豆量',
                value: '18',
                unit: 'g',
                deltaValue: '+1.2',
                deltaLabel: '前回比',
                isPositiveDelta: true,
              ),
            ),
            Expanded(
              child: BbStatTile(
                label: '抽出時間',
                value: '2:45',
                deltaValue: '-0.3',
                deltaLabel: '前回比',
                isPositiveDelta: false,
              ),
            ),
          ],
        ),
        brightness: brightness,
        theme: theme,
        width: 320,
        goldenPath: 'goldens/public/bb_stat_tile_$suffix.png',
      );
    }, skip: skipGoldenOnNonWindows);

    testWidgets('BbExtractionRing golden(live, $suffix)', (tester) async {
      await pumpAndMatchGolden(
        tester,
        child: const BbExtractionRing(
          steps: [30, 90, 180],
          totalSeconds: 240,
          elapsedSeconds: 90,
          diameter: 240,
          mode: BbExtractionRingMode.live,
        ),
        brightness: brightness,
        theme: theme,
        goldenPath: 'goldens/public/bb_extraction_ring_live_$suffix.png',
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

  // T5-B22(束2): 束2コンポーネントの未カバー分岐(ライトのみ、束1と同粒度)。
  testWidgets('BbEmptyState golden(アクション無し分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BbEmptyState(
        icon: Icons.insights_outlined,
        title: 'あと3件でインサイトが使えます',
        description: '味の傾向を出すには記録が5件必要です。いまは2件です。',
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_empty_state_no_action_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbErrorView golden(フルスクリーン・再試行無し分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BbErrorView(
        title: 'データを読み込めませんでした。',
        description: 'アプリを再起動しても直らない場合は、書き出したデータから復元してください。',
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_error_view_fullscreen_no_retry_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbLoadingSkeleton golden(5行分岐)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          backgroundColor: lightTheme.scaffoldBackgroundColor,
          body: const Center(
            child: SizedBox(
              width: 320,
              child: RepaintBoundary(
                key: goldenTargetKey,
                child: BbLoadingSkeleton(lineCount: 5),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byKey(goldenTargetKey),
      matchesGoldenFile('goldens/public/bb_loading_skeleton_5lines_light.png'),
    );
  }, skip: skipGoldenOnNonWindows);

  // T5-B22(束3): 束3コンポーネントの未カバー分岐(ライトのみ、束1・束2と同粒度)。
  testWidgets('BbBottomSheet golden(アクション無し分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BbBottomSheet(
        title: '注湯ステップ',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('1投目: 0:00〜0:30\n2投目: 0:30〜1:30'),
        ),
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_bottom_sheet_no_actions_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbNumberField golden(エラー状態・プリセット無し分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: BbNumberField(
        label: '豆量',
        value: null,
        min: 1,
        max: 100,
        unit: 'g',
        onChanged: (_) {},
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_number_field_error_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbStatTile golden(補助行無し分岐)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BbStatTile(label: '湯温', value: '92', unit: '℃'),
      brightness: Brightness.light,
      theme: lightTheme,
      width: 320,
      goldenPath: 'goldens/public/bb_stat_tile_no_delta_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbExtractionRing golden(staticMode)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BbExtractionRing(
        steps: [15, 45],
        totalSeconds: 150,
        elapsedSeconds: 150,
        diameter: 96,
        mode: BbExtractionRingMode.staticMode,
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      goldenPath: 'goldens/public/bb_extraction_ring_static_light.png',
    );
  }, skip: skipGoldenOnNonWindows);

  testWidgets('BbExtractionRing golden(thumbnail)', (tester) async {
    await pumpAndMatchGolden(
      tester,
      child: const BbExtractionRing(
        steps: [15, 45],
        totalSeconds: 150,
        elapsedSeconds: 150,
        diameter: 36,
        mode: BbExtractionRingMode.thumbnail,
      ),
      brightness: Brightness.light,
      theme: lightTheme,
      goldenPath: 'goldens/public/bb_extraction_ring_thumbnail_light.png',
    );
  }, skip: skipGoldenOnNonWindows);
}
