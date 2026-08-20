// integration_test/smoke_test.dart
//
// T5-A7: `integration_test`パッケージによるスモークテストスイート。
// 完了条件(docs/改修マスタープラン.md 342行目より):
// 「`integration_test` スモークスイート。起動→記録(抽出→評価)→保存→一覧反映→
//   インサイト表示→設定 の一筆書き+5マスタ全部の一覧→詳細→編集
//   エミュレータ上で全パス。`verify.ps1`とは別コマンドで実行できる」
//
// 実行方法(`tools/verify.ps1`には組み込まない、独立コマンドとして実行する):
//   flutter test integration_test/smoke_test.dart -d <エミュレータID>
//
// 前提条件(モック化しない。実際のGoogle Sheets/GAS Web Appへ読み書きする):
//   - 起動対象は lib/main.dart(personal版、T5-B1で追加された main_public.dart 側ではない)
//   - 少なくとも1件の抽出メソッドが登録済みで、その注湯ステップに時間(duration>0)が
//     設定されていること(注湯ステップが無い記録は log_list_screen.dart のフィルタで
//     一覧から除外されるため)
//   - 少なくとも1件の在庫あり(isInStock=true)の豆が登録済みであること
//     (brew_evaluation_screen.dart の豆選択ドロップダウンは在庫ありのみを表示する)
//   - 豆/グラインダー/ドリッパー/フィルター/メソッドの5マスタそれぞれに
//     1件以上登録済みであること(一覧→詳細→編集の導線確認に使う)
// これらは実運用中の個人アプリでは通常満たされる。満たされない環境では該当ステップで
// テストが失敗する(前提データ未整備のシグナルとして扱い、意図的にスキップはしない)。
//
// 本テストは1本の一筆書きシナリオとして実装し、保存した抽出記録・マスタデータは
// 削除・変更しない(5マスタの編集導線はキャンセルで戻り、実データを変更しない)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bean_base/main.dart' as app;
import 'package:bean_base/screens/create/create_form_widgets.dart' show CreateFormScaffold;
import 'package:bean_base/screens/master_template.dart' show kMasterListFirstItemKey;
import 'package:bean_base/screens/mock/mock_scaffold.dart' show MockListRow;
import 'package:bean_base/screens/settings_screen.dart';
import 'package:bean_base/screens/statistics_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('受け入れ(T5-A7)', () {
    testWidgets(
      '起動→記録(抽出→評価)→保存→一覧反映→インサイト表示→設定+5マスタ全部の一覧→詳細→編集',
      (tester) async {
        // --- 1. アプリ起動(lib/main.dart、personal版) ---
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);

        // 履歴一覧の初期件数を記録しておく(保存後の反映確認のベースライン)。
        await tester.tap(find.byKey(const ValueKey('nav_tab_002')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        final baselineLogCount = find.byType(MockListRow).evaluate().length;

        // --- 2. 記録: 抽出(豆選択→抽出パラメータ入力)→評価 ---
        // 2a. 030(抽出レシピ): メソッドを選択し、豆量(抽出パラメータ)を入力する。
        await tester.tap(find.byKey(const ValueKey('nav_tab_030')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('brew_recipe_method_dropdown')));
        await tester.pumpAndSettle();
        final methodOption = find.byWidgetPredicate((w) => w is DropdownMenuItem).first;
        expect(
          methodOption,
          findsOneWidget,
          reason: 'メソッドマスタが1件も登録されていません(前提未整備)',
        );
        await tester.tap(methodOption);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final beanWeightField = find.descendant(
          of: find.byKey(const ValueKey('brew_recipe_bean_weight_field')),
          matching: find.byType(TextField),
        );
        await tester.enterText(beanWeightField, '18');
        await tester.pumpAndSettle();

        await tester.tap(find.text('抽出を終えて評価へ (031)'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);

        // 2b. 031(評価): 豆を選択し、湯温(必須項目)を入力して登録する。
        await tester.tap(find.byKey(const ValueKey('eval_bean_dropdown')));
        await tester.pumpAndSettle();
        final beanOption = find.byWidgetPredicate((w) => w is DropdownMenuItem).first;
        expect(
          beanOption,
          findsOneWidget,
          reason: '在庫あり(isInStock=true)の豆が1件も登録されていません(前提未整備)',
        );
        await tester.tap(beanOption);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final temperatureField = find.descendant(
          of: find.byKey(const ValueKey('eval_temperature_field')),
          matching: find.byType(TextField),
        );
        await tester.enterText(temperatureField, '92');
        await tester.pumpAndSettle();

        await tester.tap(find.text('評価を登録する'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('登録しました'),
          findsOneWidget,
          reason: '抽出記録の保存に失敗しました',
        );

        // --- 3. 保存後、一覧画面(002)に反映されていることを確認 ---
        await tester.tap(find.byKey(const ValueKey('nav_tab_002')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.text('抽出履歴がありません'), findsNothing);
        final afterLogCount = find.byType(MockListRow).evaluate().length;
        expect(
          afterLogCount,
          greaterThan(baselineLogCount),
          reason: '保存した抽出記録が履歴一覧(002)に反映されていません',
        );

        // --- 4. インサイト表示画面(統計 040)が開けることを確認 ---
        await tester.tap(find.byKey(const ValueKey('nav_tab_040')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.byType(StatisticsScreen), findsOneWidget);

        // --- 5. 設定画面(090)が開けることを確認 ---
        await tester.tap(find.byKey(const ValueKey('nav_tab_001')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('設定'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.byType(SettingsScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        // --- 6. 5マスタ全部: 一覧→詳細→編集の導線を確認 ---
        // 実データは変更しない(編集画面は開くだけでキャンセルして戻る)。
        await tester.tap(find.byKey(const ValueKey('nav_tab_010')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);

        const masterHubLabels = [
          '豆管理',
          'ドリッパー管理',
          'フィルター管理',
          'メソッド管理',
          'グラインダー管理',
        ];

        for (final label in masterHubLabels) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(tester.takeException(), isNull, reason: '$label 一覧の表示に失敗しました');

          expect(
            find.byKey(kMasterListFirstItemKey),
            findsOneWidget,
            reason: '$label にマスタデータが1件も登録されていません(前提未整備)',
          );
          await tester.tap(find.byKey(kMasterListFirstItemKey));
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(tester.takeException(), isNull, reason: '$label 詳細画面への遷移に失敗しました');

          expect(
            find.byTooltip('編集'),
            findsOneWidget,
            reason: '$label 詳細画面に編集導線がありません',
          );
          await tester.tap(find.byTooltip('編集'));
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(tester.takeException(), isNull, reason: '$label 編集画面への遷移に失敗しました');
          expect(
            find.byType(CreateFormScaffold),
            findsOneWidget,
            reason: '$label 編集画面が開けませんでした',
          );

          // 実データを変更せず、キャンセルで詳細→一覧→マスターハブへ戻る。
          await tester.tap(find.text('キャンセル'));
          await tester.pumpAndSettle(const Duration(seconds: 1));
          await tester.pageBack(); // 詳細 → 一覧
          await tester.pumpAndSettle(const Duration(seconds: 1));
          await tester.pageBack(); // 一覧 → マスターハブ
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      },
    );
  });
}
