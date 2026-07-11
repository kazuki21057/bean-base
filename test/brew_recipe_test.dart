import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/screens/brew_recipe_screen.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/models/pouring_step.dart';

/// Cycle 20 T2-3a: 030(抽出レシピ)を実データ接続の新デザインへ移植した際の
/// 検証。メソッド選択→Pouring Steps読込・編集・保存ダイアログの導線を確認する
/// (旧英語UI版の検証内容を新デザイン・日本語UIに合わせて更新)。
/// 新デザインは`ListView`(遅延ビルド)を使うため、旧`SingleChildScrollView`
/// 版と異なりビューポート外のウィジェットは明示的にスクロールしてから
/// 検証する必要がある(上へスクロールし戻すとオフスクリーンでの
/// タップがエラーになるため、下方向にのみスクロールする一方向の流れにする)。
void main() {
  testWidgets('BrewRecipeScreen: メソッド選択でPouring Stepsが読み込まれ、編集・保存ダイアログが動作する',
      (WidgetTester tester) async {
    final mockMethod = MethodMaster(
      id: 'M1',
      name: 'V60 Test',
      author: 'Test',
      baseBeanWeight: 15.0,
      baseWaterAmount: 250.0,
      description: 'Desc',
      recommendedEquipment: 'V60',
    );

    final mockSteps = [
      PouringStep(id: 'S1', methodId: 'M1', stepOrder: 1, duration: 30, waterAmount: 30, waterReference: 15.0, description: 'Bloom'),
      PouringStep(id: 'S2', methodId: 'M1', stepOrder: 2, duration: 30, waterAmount: 120, waterReference: 15.0, description: 'Pour'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          methodMasterProvider.overrideWith((ref) async => [mockMethod]),
          pouringStepsProvider.overrideWith((ref) async => mockSteps),
          beanMasterProvider.overrideWith((ref) async => []),
          grinderMasterProvider.overrideWith((ref) async => []),
          dripperMasterProvider.overrideWith((ref) async => []),
          filterMasterProvider.overrideWith((ref) async => []),
          coffeeRecordsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: BrewRecipeScreen(),
        ),
      ),
    );
    final listView = find.byType(ListView);

    // Initial load(トップ付近): メソッドのドロップダウンはまだスクロールなしで見える
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<MethodMaster>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V60 Test').last);
    await tester.pumpAndSettle();

    // 豆量に基準値がプリフィルされる
    expect(find.text('15.0'), findsOneWidget);

    // 下方向にのみスクロールして Pouring Steps セクションを表示
    await tester.drag(listView, const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('End Time'), findsOneWidget);
    expect(find.text('Total Water'), findsOneWidget);
    expect(find.text('Bloom'), findsOneWidget);
    expect(find.text('Pour'), findsOneWidget);

    // ステップ追加
    final addStepFinder = find.text('Add Step');
    expect(addStepFinder, findsOneWidget);
    await tester.tap(addStepFinder);
    await tester.pumpAndSettle();

    // 2件 + 追加1件 = 3行(削除アイコンで数える)
    expect(find.byIcon(Icons.delete), findsNWidgets(3));

    // 保存ダイアログ(さらに下にスクロールしてボタンを表示)
    await tester.drag(listView, const Offset(0, -400));
    await tester.pumpAndSettle();
    final saveBtnFinder = find.text('メソッドを保存');
    expect(saveBtnFinder, findsOneWidget);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('上書き'), findsOneWidget);
    expect(find.text('新規として保存'), findsOneWidget);
  });
}
