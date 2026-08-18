// T5-B22(束1)夜間ループ敵対的レビューMajor-1: `lib/widgets/public/`配下の
// コンポーネントを`buildPublicTheme()`を通さない素の`ThemeData`配下でpumpしても
// クラッシュしないことを確認するスモークテスト(golden不要)。
//
// `BbColors`/`BbTypography`の`ThemeExtension`が登録されていないテーマ配下で
// `context.bbType`/`context.bbColors`を評価すると、以前は`!`によるnull check
// 例外で即クラッシュしていた(`lib/theme/public/bb_theme.dart`のフォールバック
// 追加で解消済み)。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/widgets/public/bb_buttons.dart';
import 'package:bean_base/widgets/public/bb_card.dart';
import 'package:bean_base/widgets/public/bb_chip.dart';
import 'package:bean_base/widgets/public/bb_list_row.dart';
import 'package:bean_base/widgets/public/bb_section_header.dart';

Future<void> _pumpUnderPlainTheme(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      // `buildPublicTheme()`を経由しない素の`ThemeData`(拡張未登録)。
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('BbCard: 素のThemeData配下でクラッシュしない', (tester) async {
    await _pumpUnderPlainTheme(
      tester,
      BbCard(onTap: () {}, child: const Text('テスト')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('BbListRow: 素のThemeData配下でvalue指定してもクラッシュしない',
      (tester) async {
    await _pumpUnderPlainTheme(
      tester,
      const BbListRow(
        title: 'エチオピア イルガチェフェ',
        subtitle: '浅煎り',
        value: '18',
        unit: 'g',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('BbSectionHeader: 素のThemeData配下でクラッシュしない', (tester) async {
    await _pumpUnderPlainTheme(
      tester,
      BbSectionHeader(
        eyebrow: '最近の記録',
        title: '履歴',
        actionLabel: 'すべて見る',
        onActionTap: () {},
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('BbPrimaryButton/BbTextButton: 素のThemeData配下でクラッシュしない',
      (tester) async {
    await _pumpUnderPlainTheme(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BbPrimaryButton(label: '抽出をはじめる', onPressed: () {}),
          BbTextButton(label: 'キャンセル', onPressed: () {}),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('BbChip: 素のThemeData配下でselected+roastDotColorでもクラッシュしない',
      (tester) async {
    await _pumpUnderPlainTheme(
      tester,
      BbChip(
        label: '中深煎り',
        selected: true,
        roastDotColor: Colors.brown,
        onSelected: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
