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
import 'package:bean_base/models/method_master.dart' show MethodMaster;
import 'package:bean_base/screens/create/brew_evaluation_screen.dart'
    show BrewEvaluationScreen;
import 'package:bean_base/screens/create/create_form_widgets.dart' show CreateFormScaffold;
import 'package:bean_base/screens/master_template.dart' show kMasterListFirstItemKey;
import 'package:bean_base/screens/mock/mock_scaffold.dart'
    show MockListRow, MockScreenScaffold;
import 'package:bean_base/screens/settings_screen.dart';
import 'package:bean_base/screens/statistics_screen.dart';
import 'package:bean_base/widgets/method_steps_editor.dart';

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
        // GAS初回GET(タイムアウト+リトライを含む)が完了する前にベースラインを
        // 取ると0件のまま確定してしまい、後段の件数比較が空振りで通ってしまう
        // (T5-A105)ため、読み込み完了(件数表示 or 空表示)まで明示的に待つ。
        await tester.tap(find.byKey(const ValueKey('nav_tab_002')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        await _pumpUntil(
          tester,
          () =>
              find.byType(MockListRow).evaluate().isNotEmpty ||
              find.text('抽出履歴がありません').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 90),
          reason: '002の初期読み込みが完了しませんでした',
        );
        final baselineLogCount = find.byType(MockListRow).evaluate().length;

        // --- 2. 記録: 抽出(豆選択→抽出パラメータ入力)→評価 ---
        // 2a. 030(抽出レシピ): メソッドを選択し、豆量(抽出パラメータ)を入力する。
        await tester.tap(find.byKey(const ValueKey('nav_tab_030')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);

        // 030はメソッド一覧(ダッシュボード表示中に取得済み)と注湯ステップ一覧
        // (030へ来て初めて取得開始)を別々に読み込む。ステップ未読込の間はメソッド選択が
        // 無効化されているため、有効になるまで待つ(pumpAndSettleはGASの往復を待たない)。
        final methodDropdown = find.byKey(const ValueKey('brew_recipe_method_dropdown'));
        await _pumpUntil(
          tester,
          () {
            final elements = methodDropdown.evaluate();
            if (elements.isEmpty) return false;
            final field = elements.single.widget as DropdownButtonFormField<MethodMaster>;
            return field.onChanged != null;
          },
          reason: '030のメソッド選択が有効になりませんでした(注湯ステップの取得が完了していない)',
        );
        // 開いたメニューは全画面のModalBarrierを持つため、この時点でhitTestableな
        // DropdownMenuItemは「開いているメニューの項目」だけになる(閉じた状態の各
        // ドロップダウンがIndexedStackに持つ表示用コピーはバリアに隠れて除外される)。
        // 旧実装は.last(ツリー順で最後)を使っていたが、これは非表示コピーを掴む
        // ことがあり、タップ自体は例外なく成功するのに実際には選択されない
        // (031への遷移時に method=未選択 のまま)という問題があった。
        // 031の豆選択ドロップダウンで確立済みの.hitTestable().first方式に統一する。
        //
        // さらに(T5-A105): 先頭候補を無条件に選ぶと、pouring_steps の取得が
        // (GAS往復の失敗等で)空のまま確定しているメソッドを選んでしまうことがある。
        // その場合 totalTime=0 の記録が保存され、002の一覧は totalTime>0 の記録
        // しか表示しないため、保存しても件数が増えず後段の判定が意味を失う
        // (T5-A103)。注湯ステップ(duration合計>0)を持つメソッドが見つかるまで、
        // ドロップダウンを開き直して最大5候補まで順に試す。
        const maxMethodTries = 5;
        var methodValid = false;
        for (var i = 0; i < maxMethodTries && !methodValid; i++) {
          await tester.tap(methodDropdown);
          await tester.pumpAndSettle();
          final methodOptions =
              find.byWidgetPredicate((w) => w is DropdownMenuItem).hitTestable();
          expect(
            methodOptions,
            findsWidgets,
            reason: 'メソッドマスタが1件も登録されていません(前提未整備)',
          );
          final optionCount = methodOptions.evaluate().length;
          if (i >= optionCount) {
            // 候補を全て試し終えた(登録メソッドが5件未満)。
            break;
          }
          await tester.tap(methodOptions.at(i));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text('メソッドを選択してください'),
            findsNothing,
            reason: '030でメソッドを選択したのに_selectedMethodが更新されていません',
          );

          final editorFinder = find.byType(MethodStepsEditor);
          if (editorFinder.evaluate().isNotEmpty) {
            final steps =
                tester.widget<MethodStepsEditor>(editorFinder.first).initialSteps;
            final totalDuration =
                steps.fold<int>(0, (sum, step) => sum + step.duration);
            debugPrint('[Antigravity] 030メソッド選択: 候補$i件目 '
                'steps=${steps.length} totalDuration=$totalDuration');
            if (steps.isNotEmpty && totalDuration > 0) {
              methodValid = true;
            }
          }
        }
        if (!methodValid) {
          fail('注湯ステップ(duration>0)を持つメソッドが1件もありません。002の一覧は '
              'totalTime>0 の記録しか表示しないため、このまま保存しても件数が増えません'
              '(前提未整備、または pouring_steps の取得失敗)');
        }

        final beanWeightField = find.descendant(
          of: find.byKey(const ValueKey('brew_recipe_bean_weight_field')),
          matching: find.byType(TextField),
        );
        await tester.enterText(beanWeightField, '18');
        await tester.pumpAndSettle();

        // 030画面は MockScreenScaffold の ListView(通常コンストラクタ)を使っており、
        // 直前に配置された GpExplorerSection(F4 GP推薦の予測総合評価マップ等、データ量
        // に応じて非常に長くなる)のせいで最下部の「抽出を終えて評価へ (031)」ボタンが
        // ビューポート外(Element未構築)になりうる。ListViewは通常コンストラクタでも
        // SliverChildListDelegate により描画上は遅延構築されるため、tap前に
        // scrollUntilVisible でスクロールしてビューポート内に入れる。
        // 030画面にはメソッド選択後、注湯ステップ表(横方向SingleChildScrollView)も
        // 存在し Scrollable が複数になるため、対象を縦方向(axisDirection.down)の
        // Scrollable = MockScreenScaffold の ListView に絞る。
        // 「抽出を終えて評価へ (031)」ボタンは MockScreenScaffold の ListView 最後尾にある。
        // scrollUntilVisible は (a) cacheExtent 内でElementが構築された時点で停止し
        // ビューポート外のままになる (b) 末尾の Scrollable.ensureVisible が jumpTo のみで
        // フレームを回さず tap が古い座標を使う (c) 直後に pump するとGP推薦セクションが
        // データ到着で伸びてボタンが再びビルド範囲外へ出る、の3経路で失敗するため使わない。
        // 対象の縦 Scrollable を最下部へ直接ジャンプさせ、タップ可能になるまで繰り返す。
        // NavigationRail(幅640px以上)も縦 Scrollable を持つため、030画面の骨格配下に限定する。
        final recipeScrollable = find
            .descendant(
              of: find.byType(MockScreenScaffold),
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            )
            .first;
        final finishButton = find.byKey(const ValueKey('brew_recipe_finish_button'));
        var finishButtonReady = false;
        for (var i = 0; i < 12; i++) {
          if (finishButton.hitTestable().evaluate().isNotEmpty) {
            finishButtonReady = true;
            break;
          }
          final position = tester.state<ScrollableState>(recipeScrollable).position;
          debugPrint('[Antigravity] 030最下部へジャンプ: 試行=$i '
              'pixels=${position.pixels} max=${position.maxScrollExtent}');
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle(const Duration(milliseconds: 200));
        }
        expect(
          finishButtonReady,
          isTrue,
          reason: '030画面を最下部までスクロールしても「抽出を終えて評価へ (031)」ボタンが'
              'タップ可能になりませんでした(GP推薦セクションの読み込みが終わらない等)',
        );
        // ここで pump を挟むと GP推薦セクションの伸長でボタンが再び画面外へ出るため、
        // hitTestable の確認直後にフレームを回さずそのままタップする。
        await tester.tap(finishButton.hitTestable());
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(
          find.byType(BrewEvaluationScreen),
          findsOneWidget,
          reason: '030の「抽出を終えて評価へ」から031(評価)へ遷移できませんでした',
        );

        // 2b. 031(評価): 湯温(必須項目)を入力し、豆を選択して登録する。
        // enterText はヒットテストを伴わないため、スクロール前に入力してよい。
        final temperatureField = find.descendant(
          of: find.byKey(const ValueKey('eval_temperature_field')),
          matching: find.byType(TextField),
        );
        await tester.enterText(temperatureField, '92');
        await tester.pumpAndSettle();

        // 豆選択は031のListViewの5番目の入力欄にあり、エミュレータ(幅411dp)では
        // 初期表示のビューポート(実効約450dp)に入らない。ListViewのcacheExtent(250)
        // 内なのでElementは構築されており find.byKey では見つかるが、実描画位置は
        // CreateFormScaffoldの下部バー/MainLayoutのNavigationBarの裏側にある。
        // そのままtapすると座標がNavigationBar中央(=マスタータブ)に落ち、
        // pushAndRemoveUntilで010へ飛んで031が破棄される
        // (実測: Offset(205.7, 626.8)でヒットテスト失敗 → 直後にDropdownMenuItemが
        //  0件になり Bad state: No element)。
        final beanDropdown = find.byKey(const ValueKey('eval_bean_dropdown'));
        final evalScrollable =
            find.ancestor(of: beanDropdown, matching: find.byType(Scrollable)).first;
        await _scrollUntilTappable(
          tester,
          evalScrollable,
          beanDropdown,
          reason: '031画面をスクロールしても豆選択ドロップダウンがタップ可能になりませんでした',
        );
        await tester.tap(beanDropdown.hitTestable());
        await tester.pumpAndSettle();

        // 開いたメニューは全画面のModalBarrierを持つため、この時点でhitTestableな
        // DropdownMenuItemは「開いているメニューの項目」だけになる(閉じた状態の各
        // ドロップダウンがIndexedStackに持つ表示用コピーはバリアに隠れて除外される)。
        // メニュー内が長いと末尾が画面外になりうるため .last ではなく先頭を選ぶ。
        final beanOptions =
            find.byWidgetPredicate((w) => w is DropdownMenuItem).hitTestable();
        expect(
          beanOptions,
          findsWidgets,
          reason: '在庫あり(isInStock=true)の豆が1件も登録されていません(前提未整備)',
        );
        await tester.tap(beanOptions.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('評価を登録する'));
        // 保存はGAS(Sheets)へのHTTP往復を2回直列に行う
        // (coffee_dataへのadd → 好みプロファイルのAnalysisSnapshot保存)。
        // その待機中、031画面はフレームを1つもスケジュールしない
        // (CreateFormScaffoldは`_isSaving`中もローディング表示を出さず、保存ボタンを
        //  disabledにするだけ)。LiveTestWidgetsFlutterBindingのpumpAndSettleは
        // 「予約フレームが尽きた」時点で戻るため、`_isSaving=true`の再描画1フレームで
        // 約3秒後に戻ってしまい、保存完了前にアサートして必ず失敗していた。
        // SnackBarが出るまで短い間隔でpumpしながらポーリングする。
        final saveMessage = await _pumpUntilSnackBar(
          tester,
          const ['登録しました', '登録に失敗しました', '豆を選択してください', '湯温を入力してください'],
          reason: '「評価を登録する」を押しても保存結果のSnackBarが表示されませんでした',
        );
        expect(tester.takeException(), isNull);
        expect(
          saveMessage,
          contains('登録しました'),
          reason: '抽出記録の保存に失敗しました(表示されたSnackBar: $saveMessage)',
        );

        // --- 3. 保存後、一覧画面(002)に反映されていることを確認 ---
        // GAS再取得(タイムアウト+リトライを含む)には固定pumpAndSettleの数秒より
        // 大幅に長くかかりうる(T5-A105)ため、件数がベースラインを上回るまで
        // ポーリングする。
        await tester.tap(find.byKey(const ValueKey('nav_tab_002')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        await _pumpUntil(
          tester,
          () => find.byType(MockListRow).evaluate().length > baselineLogCount,
          timeout: const Duration(seconds: 90),
          reason: '保存した抽出記録が履歴一覧(002)に反映されませんでした',
        );
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
        // tester.pageBack()はFlutter SDK側で英語の'Back'ツールチップ固定でしか
        // 戻るボタンを探さない(widget_tester.dart)。本アプリは日本語ローカライズ
        // されており実際のツールチップは'戻る'のため、直接タップする。
        await tester.tap(find.byTooltip('戻る'));
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
          // pageBack()は英語'Back'ツールチップ固定でしか探さない(SDK側の制約、
          // 上のSettingsScreenの戻る導線と同じ理由)ため、日本語ツールチップを直接タップする。
          await tester.tap(find.text('キャンセル'));
          await tester.pumpAndSettle(const Duration(seconds: 1));
          await tester.tap(find.byTooltip('戻る')); // 詳細 → 一覧
          await tester.pumpAndSettle(const Duration(seconds: 1));
          await tester.tap(find.byTooltip('戻る')); // 一覧 → マスターハブ
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      },
    );
  });
}

/// 指定の縦スクロール領域を少しずつスクロールし、[target] がタップ可能
/// (hitTestable)になるまで待つ。現在位置より「下」にある対象専用。
///
/// scrollUntilVisible / ensureVisible は
/// (a) cacheExtent 内で Element が構築された時点で「見つかった」と判定して停止し、
///     ウィジェットはビューポート外のまま残る
/// (b) 内部の Scrollable.ensureVisible が jumpTo のみでフレームを回さず、
///     直後の tap が古い座標を使う
/// の2経路で失敗するため使わない(030の「抽出を終えて評価へ」ボタンで実証済み)。
///
/// タップ可能になった直後に pump を挟むとレイアウトが動いて再び画面外へ出ることが
/// あるため、呼び出し側は本メソッドの直後にフレームを回さずそのまま tap すること。
Future<void> _scrollUntilTappable(
  WidgetTester tester,
  Finder scrollable,
  Finder target, {
  required String reason,
  double step = 120,
  int maxTries = 20,
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (target.hitTestable().evaluate().isNotEmpty) return;
    final position = tester.state<ScrollableState>(scrollable).position;
    final next = (position.pixels + step) > position.maxScrollExtent
        ? position.maxScrollExtent
        : (position.pixels + step);
    debugPrint('[Antigravity] タップ可能になるまでスクロール: 試行=$i '
        'pixels=${position.pixels} → $next max=${position.maxScrollExtent}');
    if (next <= position.pixels) break; // これ以上スクロールできない
    position.jumpTo(next);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }
  expect(target.hitTestable(), findsOneWidget, reason: reason);
}

/// [condition]が真になるまで実フレームを回して待つ。
/// `pumpAndSettle`は「スケジュール済みフレームが尽きた」時点で戻り、
/// GASへのHTTP往復のようにフレームを伴わない待機には使えないため。
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
  Duration interval = const Duration(milliseconds: 250),
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (!DateTime.now().isBefore(deadline)) {
      fail('$reason(${timeout.inSeconds}秒待機)');
    }
    await tester.pump(interval);
  }
}

/// 非同期処理の完了で「後から」表示されるSnackBarを待ち、その本文を返す。
///
/// `pumpAndSettle`は「スケジュール済みのフレームが無くなった」時点で戻るため、
/// GASへのHTTP往復のように**フレームを一切スケジュールしない待機**には使えない。
/// 031の保存中は`CreateFormScaffold`が保存ボタンをdisabledにするだけでローディング
/// 表示が無く、`pumpAndSettle(3秒)`は再描画1フレームで戻ってしまう。
///
/// SnackBarは既定4秒で自動的に閉じるため、ポーリング間隔はそれより十分短く取る。
/// タイムアウト時は、待機中に観測したSnackBar本文をすべてエラーメッセージへ含める
/// (保存失敗・必須入力バリデーション等、どこで止まったかを1回の実行で切り分けるため)。
Future<String> _pumpUntilSnackBar(
  WidgetTester tester,
  List<String> messages, {
  required String reason,
  Duration interval = const Duration(milliseconds: 250),
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  final seen = <String>{};
  while (true) {
    final texts = find
        .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>();
    for (final text in texts) {
      seen.add(text);
      if (messages.any(text.contains)) {
        debugPrint('[Antigravity] SnackBarを検出: $text');
        return text;
      }
    }
    if (!DateTime.now().isBefore(deadline)) {
      fail('$reason(${timeout.inSeconds}秒待機。'
          '観測したSnackBar: ${seen.isEmpty ? "なし" : seen.join(" / ")})');
    }
    await tester.pump(interval);
  }
}
