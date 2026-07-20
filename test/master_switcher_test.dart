import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/bean_list_screen.dart';
import 'package:bean_base/screens/dripper_list_screen.dart';

/// Cycle 20 T3-19: 各マスター管理画面から他マスターの一覧へ直接遷移できる
/// `MasterSwitcherButton`の検証。`MasterListTemplate`/`MasterDetailTemplate`
/// 経由の画面(ドリッパー等)と、独自実装の`BeanListScreen`の両方で
/// ボタンが機能することを確認する。
List<Override> _emptyOverrides() => [
      coffeeRecordsProvider.overrideWith((ref) async => <CoffeeRecord>[]),
      beanMasterProvider.overrideWith((ref) async => <BeanMaster>[]),
      methodMasterProvider.overrideWith((ref) async => <MethodMaster>[]),
      grinderMasterProvider.overrideWith((ref) async => <GrinderMaster>[]),
      dripperMasterProvider.overrideWith((ref) async => <DripperMaster>[]),
      filterMasterProvider.overrideWith((ref) async => <FilterMaster>[]),
    ];

void main() {
  testWidgets('DripperListScreen: 切り替えメニューに他4種のマスターが並び、選択すると該当の一覧へ遷移する(T3-19)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyOverrides(),
        child: const MaterialApp(home: DripperListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();

    // 自分自身(ドリッパー管理)はメニューの選択肢には出ない
    // (AppBarタイトルとして1件だけ存在し、メニュー項目としては追加されない)。
    expect(find.text('ドリッパー管理'), findsOneWidget);
    expect(find.text('豆管理'), findsOneWidget);
    expect(find.text('フィルター管理'), findsOneWidget);
    expect(find.text('メソッド管理'), findsOneWidget);
    expect(find.text('グラインダー管理'), findsOneWidget);

    await tester.tap(find.text('豆管理'));
    await tester.pumpAndSettle();

    expect(find.text('010'), findsOneWidget);
    expect(find.text('豆管理(カード)'), findsOneWidget);
  });

  testWidgets('BeanListScreen(独自実装): 切り替えメニューから他マスターへ遷移できる(T3-19)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyOverrides(),
        child: const MaterialApp(home: BeanListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();

    // 自分自身(豆管理)は選択肢に出ない。
    expect(find.text('豆管理'), findsNothing);
    expect(find.text('ドリッパー管理'), findsOneWidget);

    await tester.tap(find.text('ドリッパー管理'));
    await tester.pumpAndSettle();

    expect(find.text('013'), findsOneWidget);
  });
}
