# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-11(T2-2c・T2-1a・T2-1b・T2-3a〜c・T2-4a・T2-4b 完了、5時間セッション上限まで継続)

## -4.10 当日やったこと(2026-07-11、T2-4b・最新)

**Cycle 20 / T2-4b 完了**: 030の「新規として保存」を021(MethodCreateScreen)への継承遷移に置き換えた。これでマスタープラン§4画面インベントリの030行(Pouring Steps・タイマー・編集・評価ボタン→031)がすべて✅になった。

- `lib/screens/create/method_create_screen.dart`: `MethodCreateScreen`に`prefillFrom`(`MethodMaster?`)・`prefillSteps`(`List<PouringStep>?`)を追加。`editData`と違い、常に新規メソッドとして登録される(既存メソッドの上書きにはならない)。`initState`で`editData ?? prefillFrom`から基本情報をプリフィルし、`prefillSteps`は**必ず`'new_'`プレフィックスの新しいIDへ差し替えてから複製**する(元のIDのまま渡すと`_submit()`が`updatePouringStep`を呼び、元メソッド側のステップを書き換えてしまう事故になるため)。
- `lib/screens/brew_recipe_screen.dart`: `_promptNewName()`(独自の名前入力ダイアログ)と`_saveAsNewSimulated()`を削除し、`_goToSaveAsNew()`に置き換え。現在のメソッドの基準値・スケーリング済みPouring Stepsから`prefillMethod`(名前は「元の名前 (コピー)」)を組み立て、`MethodCreateScreen(prefillFrom:, prefillSteps:)`へ`Navigator.push`するだけのシンプルな実装。名前の最終確定と実際の登録(`DataService.addMethod`/`addPouringStep`)は021の既存`_submit()`フローにそのまま合流する。
- `test/brew_recipe_test.dart`に新規テストを追加。「新規として保存」→「V60 Test (コピー)」という名前で021へ遷移し、Pouring Steps(Bloom)も引き継がれていること、かつ**元のメソッド(M1)自体は`updateMethod`が呼ばれておらず上書きされていないこと**を検証(021もPouring Steps部分は`ListView`のため、遷移後の画面でも下方向スクロールが必要だった)。
- 検証: `flutter analyze`(新規issue 0件、50件のまま)、`flutter test` 全件パス(65件、新規1件追加)。
- **ブラウザでの実データ確認は途中まで実施**(`flutter run -d chrome --web-port=8770`)。030でメソッド選択・Pouring Steps読込までは正常動作を確認できたが、保存ダイアログへスクロールする段階でマウスホイール・ドラッグ双方のスクロール操作がFlutter Web(CanvasKit)のリスト内スクロールに反映されず(1回`Page.captureScreenshot`がタイムアウトする場面もあった)、それ以上粘らずに切り上げた(`rules/verification.md`記載の「無理に全項目をスクロール確認しない」教訓に従った判断)。**「新規として保存」→021遷移→プリフィル内容の実ブラウザでの目視確認は今回未実施**(フェイクDataServiceのwidgetテストで導線自体は検証済み)。次回セッションで余裕があれば実施を推奨。
- マスタープラン §3 T2-4bと、§4画面インベントリの030行を✅に更新。
- **本日はユーザーが2回にわたり明示的に続行を承認**(1回目「トークン数で頭打ちになるまで」、2回目「5時間制限にかかるまで続けて」)。コストガードレールは本タスク中にも発火($134→$172)したが、事前承認済みの継続指示の範囲内と判断した。
- commit/push 予定(このセッション内、T2-4b単独コミット)。

## -4.9 当日やったこと(2026-07-11、T2-4a)

**Cycle 20 / T2-4a 完了**: 030(抽出レシピ)の「メソッドを保存」→上書きを、実際のDataService接続に置き換えた。

- `lib/screens/brew_recipe_screen.dart`: `_saveOverwrite()`を新規実装。021(`MethodCreateScreen._submit`)と同じadd/update/delete差分パターンで、`updateMethod`(基準豆量を現在の豆量へ、基準湯量を計算後合計へ更新)・`updatePouringStep`/`addPouringStep`(ステップごと)・`deletePouringStep`(削除されたステップ)を呼び出し、成功後に`methodMasterProvider`/`pouringStepsProvider`をinvalidateする。
- **ID重複追加バグを未然に対策**: `PouringStep.id`が`'new_'`プレフィックスの間は「未保存」の目印として使われるが、030は保存後も画面が開いたままのため(021のように保存後に画面を閉じない)、同じ`'new_'`IDのまま2回目の保存をすると`addPouringStep`が再度呼ばれて二重追加されてしまう。これを防ぐため、保存成功後にステップIDを`'ps_<timestamp>_<index>'`という確定IDへ差し替え、ローカルの`_workingSteps`/`_originalSteps`を新しいIDで更新し直す処理を追加した(NEXT_SESSION.mdの前回引き継ぎで自分自身に残した注意点)。
- 「新規として保存」は今回もスコープ外(T2-4bの担当)。`_saveAsNewSimulated`という別関数名に切り出し、シミュレーション動作(SnackBar表示のみ)を維持。021への継承遷移は未実装のまま。
- `test/brew_recipe_test.dart`にフェイク`DataService`(`method_template_test.dart`と同じパターン)を使った新規テストを追加。豆量を15g→30gに変更して上書き保存し、`updateMethod`の`baseBeanWeight`が30になること、`updatePouringStep`が呼ばれステップの水量が正しく2倍(30ml→60ml)にスケーリングされて保存されることを検証。
- 検証: `flutter analyze`(新規issue 0件、50件のまま)、`flutter test` 全件パス(64件、新規1件追加)。
- **ブラウザでの実データ確認は「上書き」ボタンを押さずに実施**(本番Sheetsへの誤書き込みを避けるため。`rules/verification.md`記載済みの教訓に従った)。`flutter run -d chrome --web-port=8769`でメソッド選択・Pouring Steps読込までが正常に動作し、コンソールエラーが無いことのみ確認。実際の保存動作の検証はフェイクDataServiceを使った上記widgetテストに委ねた。
- マスタープラン §3 T2-4aを✅に更新。
- **本日はユーザーが2回にわたり明示的に続行を承認**(1回目「トークン数で頭打ちになるまで」、2回目「5時間制限にかかるまで続けて」)。コストガードレールは本タスク中にも発火($95→$134)したが、事前承認済みの継続指示の範囲内と判断した。
- commit/push 予定(このセッション内、T2-4a単独コミット)。

## -4.8 当日やったこと(2026-07-11、T2-3a・T2-3b・T2-3c)

**Cycle 20 / T2-3a・T2-3b・T2-3c 完了**: 抽出レシピ030を実データ接続の新デザインへ移植。

- **重要な発見(着手前)**: 本番ナビ「Calc」タブ(`main_layout.dart`)は、090ギャラリー専用のUIモック(`BrewRecipeMockScreen`)ではなく、**メソッド/器具選択・Pouring Steps読込・重量スケーリング・タイマー・ステップハイライト・031への引き継ぎまで全部実装済みの旧`BrewRecipeScreen`(733行)を既に使っていた**(T1-7で判明したMastersタブと同じパターン。マスタープランはPhase1で030・040のこの状態を想定していなかった)。ユーザーに確認し、「既存ロジックを新デザインに移植」の方針で進めることに決定。
- `lib/screens/brew_recipe_screen.dart` を全面書き換え。**保持したロジック**: メソッド選択→`pouringStepsProvider`から該当ステップ抽出・基準豆量プリフィル、豆量変更に応じた比例スケーリング(`waterRatio`優先、無ければ`waterAmount`をfactor倍)、`Stopwatch`+`Timer.periodic`による経過時間表示、経過時間から現在のステップindexを求めるロジック、`PendingBrewInfo`を組み立てて031(`BrewEvaluationScreen`)へ引き継ぐ`_finishAndEvaluate`。**変更した点**: 見た目を`MockScreenScaffold`+`FormSection`(Phase2共通ウィジェット)に統一、Pouring Steps表示を旧`DataTable`直書きから021(`MethodCreateScreen`)と共通の`MethodStepsEditor`ウィジェットに置き換え。
- `lib/widgets/method_steps_editor.dart` に `activeStepIndex`(int?, デフォルトnull)を追加し、該当行を`Colors.amber.shade100`でハイライト(T2-3c)。021側は未指定のため非破壊。`MaterialStateProperty`(deprecated)ではなく`WidgetStateProperty`を使用。
- **メソッド保存(上書き/新規)は意図的に従来どおりシミュレーションのまま**(`debugPrint`+`SnackBar`のみ、実際のSheets書き込みはしない)。実際のDataService接続はマスタープラン上T2-4a(上書き)・T2-4b(新規、021への継承遷移)という別タスクの担当であり、今回のスコープ(T2-3a〜c)を超えるため意図的に着手しなかった。
- `lib/routing/screen_registry.dart`の`AppScreen.brewRecipe`を`BrewRecipeMockScreen`→`BrewRecipeScreen`(実装済み本体)に差し替え、不要になった`lib/screens/mock/brew_recipe_mock_screen.dart`を削除(他マスターのモック削除と同じパターン)。
- **副産物のバグ修正**: `FormSection`(`create_form_widgets.dart`)のタイトル`Row`に`Expanded`が無く、長いタイトル文字列("Pouring Steps (経過時間で現在のステップを強調)")で`RenderFlex overflowed`が発生することを新規テストで発見。`Text`を`Expanded`で包んで修正(17ファイルで使われる共通ウィジェットだが、非破壊な安全側の修正)。
- `test/brew_recipe_test.dart`を新デザイン・日本語UIに合わせて全面更新。**新たに得た教訓**: `MockScreenScaffold`は`ListView`(遅延ビルド)を使うため、旧`SingleChildScrollView`版と異なりビューポート外のウィジェットはテストの`find`で見つからない。`dragUntilVisible`で上方向に戻すとオフスクリーン位置でのタップがエラーになったため、**下方向に一方向でのみスクロールする**構成に変更して解決(`rules/verification.md`に教訓追記)。
- 検証: `flutter analyze`(新規issue 0件、50件のまま)、`flutter test` 全件パス(63件、変更なし。brew_recipe_test.dartの中身は書き換えたがテスト数は同じ)。
- **ブラウザ目視確認を実施**(`flutter run -d chrome --web-port=8768`、実データ・本番Sheets接続、本番ナビ「Calc」タブ経由)。メソッドドロップダウンに実データ13件が表示され、「4:6メソッド」選択でPouring Steps(蒸らし 0:00 45.0g 等)が実際に読み込まれることを確認。タイマー再生ボタンで実際に00:06までカウントアップし、アイコンが再生⇄一時停止に切り替わることを確認。コンソールエラーなし。**ステップハイライトの色(amber)自体はスクリーンショットの解像度上、目視でのピクセル確認はできていない**(タイマーが動作し`activeStepIndex`の計算ロジックは旧実装からの直接移植のため機能的には問題ない想定だが、次回セッションで余裕があれば拡大スクリーンショットでの確認を推奨)。
- マスタープラン §3 T2-3a・T2-3b・T2-3cを✅に更新。**§4画面インベントリの030行は未更新のまま(⬜)** — 説明文に含まれる「編集」(Pouring Steps編集の永続化)がT2-4a/bで未実装のため、画面としての完全達成はまだ先。
- **本日はユーザーが2回にわたり明示的に続行を承認**(1回目「トークン数で頭打ちになるまで」、2回目「5時間制限にかかるまで続けて」)。コストガードレールは本タスク中に複数回発火($45→$95)したが、いずれもユーザーの事前承認済みの継続指示の範囲内と判断した。
- commit/push 予定(このセッション内、T2-3a〜c単独コミット)。

## -4.7 当日やったこと(2026-07-11、T2-1b)

**Cycle 20 / T2-1b 完了**: ダッシュボード001の本実装。ただし新規コードはゼロ行 — T1-3・T2-1a・T2-2b・T2-2cで既に実装済みだった内容が、001の元デザイン仕様(`docs/Beanbase改修案.md`)の3項目すべてを既に満たしていることを確認しただけの「検証のみ」タスクだった。

- `docs/Beanbase改修案.md`(改修の発端となった原設計メモ)を確認したところ、001の仕様は「①残豆量表示(詳細ボタン→010、各豆クリック→011)」「②直近5件の抽出履歴表示(リストボタン→002、各履歴クリック→003)」「③黒板風にする」の3点のみ。これらはそれぞれ T2-2b/T2-2c(①)・元々T1-3で実装済み(②)・T2-1a(③)で個別タスクとして完了済みだったため、§3タスク表のT2-1b(「デザインどおりの001が実データで動作」)は既に事実上満たされていた。
- 唯一このセッションで未検証だったのは「直近5件→リストボタン→002→各履歴クリック→003」の導線(①の010/011導線と③の黒板風はT2-2c/T2-1aで既に目視確認済み)。`flutter run -d chrome --web-port=8767`(実データ)で001→「すべての履歴を見る」→002(抽出履歴リスト、実データ141件超相当表示)→行クリック→003(抽出履歴詳細、実データの抽出情報・評価が表示)の一連を確認。001→瓶クリック→011(豆詳細)の導線も再確認。
- **観測した現象(バグではないと判断)**: 002・003への遷移直後、一部の漢字(「岬の焙煎所」「浅煎り」「日付」「湯温」等)が一瞬□(トウフ)表示になったが、スクロール操作による再描画後に正しく表示された。`rules/verification.md`記載済みの「Flutter Web(CanvasKit)初回描画時のグリフ未読込」の教訓と一致する既知の一過性現象で、新規の教訓追記は不要と判断。
- コンソールに`ImageCodecException`(豆画像URLがローカルファイルパスでweb上ロード不可)が出たが、これはT1-6a以降記録済みの既知事象で今回の変更とは無関係。
- 検証: コード変更なしのため`flutter analyze`/`flutter test`は前回(T2-1a)の結果から変化なし(50 issues・63 tests pass)。ブラウザ目視確認のみ実施。
- マスタープラン §3 T2-1bを✅に、§4 画面インベントリの001行を✅に更新。
- **本日はユーザーが2回にわたり明示的に続行を承認**(1回目「トークン数で頭打ちになるまで」、2回目「5時間制限にかかるまで続けて」)。コストガードレールは本タスク開始前後で複数回発火($41→$45)したが、いずれもユーザーの事前承認済みの継続指示の範囲内と判断し新規タスク(検証のみ)に着手した。
- commit/push 予定(このセッション内、T2-1b単独コミット。コード変更が無いためドキュメント更新のみのコミットになる)。

## -4.6 当日やったこと(2026-07-11、T2-1a)

**Cycle 20 / T2-1a 完了**: 黒板風テーマ(配色・背景テクスチャ)を共通ウィジェット側にオプションとして定義し、001(ダッシュボード)全体に適用。

- **適用範囲をユーザーに確認**: マスタープランの終了条件は「001に黒板風背景が適用されて表示される」のみだが、001のウェルカムバナー部分は既に黒板風(濃緑+木枠)で実装済みだった。「001全体を黒板風に」広げる案と「ウェルカムバナーの見た目据え置き+共通化のみ」案を提示し、ユーザーは前者を選択。
- `lib/theme/blackboard_theme.dart` を新規作成。配色定数(`kBoardBg`/`kBoardBgLight`/`kBoardFrame`/`kChalkWhite`/`kChalkMuted`/`kChalkAccent`/`kChalkError`)と、`CustomPainter`でチョークの粉・かすれを薄く描く`BlackboardTexture`ウィジェット(固定シードRandomで再描画のたびに変化しない)を定義。既存のコーヒートーン配色(`create_form_widgets.dart`のkMocha等、001以外の21画面で使用中)とは別系統として扱い、既存画面には一切影響しない設計。
- 共通ウィジェットに非破壊のオプション引数を追加(すべてデフォルト値で既存の見た目を維持):
  - `MockScreenScaffold`(`mock/mock_scaffold.dart`)に`boardTexture: bool`(デフォルトfalse)。trueで背景色`kBoardBg`+`BlackboardTexture`適用。
  - `FormSection`(`create/create_form_widgets.dart`)に`dark: bool`(デフォルトfalse)。trueで`kBoardBgLight`背景+`kBoardFrame`枠+チョーク色のアイコン/タイトルに切替。
  - `MockSwitchTile`に`labelColor: Color?`(デフォルトnull=既存色)。
  - `BeanJarWidget`(`widgets/bean_jar_widget.dart`)に`textColor: Color?`(デフォルトnull=既存のkEspresso/kMocha)。
- `dashboard_screen.dart`: `MockScreenScaffold(boardTexture: true)`、両方の`FormSection`に`dark: true`、ウェルカムバナーのハードコード16進数を共通定数に置き換え(見た目は変更なし)、各種テキスト(空状態メッセージ・エラー・ローディングスピナー・リンクボタン)をチョーク配色に統一。「直近の抽出5件」の`MockListRow`(白カード)はあえて白のまま維持し、黒板に紙が貼られたような見た目にした(全面ダーク化はコントラスト設計のリスクが高いため見送り)。
- 検証: `flutter analyze`(新規issue 0件、50件のまま)、`flutter test` 全件パス(63件、変更なし)。
- **ブラウザ目視確認を実施**(`flutter run -d chrome --web-port=8766`、実データ)。001全体が黒板風(濃緑背景+テクスチャ+木枠セクション)で表示され、トグルON/OFFで瓶の表示切替も継続動作することを確認。コンソールエラーなし。**豆名の日本語(「神戸珈琲物語」)が一瞬□に見える現象があったが、ズームスクリーンショット取得中にCDPタイムアウトが発生し確認できず、代わりに通常スクリーンショットを撮り直したところ正常に表示されていた(JPEG圧縮による見かけ上の乱れと判断、フォント欠損ではない)。**
- マスタープラン §3 T2-1aを✅に更新。
- **本日はユーザーの明示的な事前承認(「トークン数で頭打ちになるまで、コストを気にせず続けて」)のもとコスト上限($12)を大幅に超過($31台)して継続した。** T2-2cの完了時点で一度ガードレールが発火したが、ユーザーの事前承認を継続の根拠として次タスク(T2-1a)にも着手。2回目のガードレール発火(このタスク完了直後)を機に、これ以上の新規タスクには着手せず本セッションを終了する判断とした。
- commit/push 予定(このセッション内、T2-1a単独コミット)。

## -4.5 当日やったこと(2026-07-11、T2-2c)

**Cycle 20 / T2-2c 完了**: 空瓶の非表示+チェックボックスでの表示切替を 001(ダッシュボード)にも追加。

- **セッション冒頭の片付け**: 2026-07-03のセッション由来で数日間未コミットのまま残っていた `CLAUDE.md`(`\start`/`\end` → `/start`/`/end` スキル参照への統一)・`NEXT_SESSION.md`・新規 `.claude/skills/start`・`.claude/skills/end`・`docs/claude_code_optimization/設計書.md` を単独コミットとしてpush(実装前の前提整理)。`lib/models/*.g.dart` の差分は内容変更なし(改行コードのみ、コミット不要と判断)。
- **タスク選定で分岐**: マスタープラン§3のタスク表順では T2-1a が「依存充足済みの最上位タスク」だったが、NEXT_SESSION.mdの引き継ぎ推奨は T2-2c。ユーザーに確認し T2-2c を選択。
- 010(`bean_list_screen.dart`)は T2-2b の時点で既に「残量0%の豆も表示する」トグル(`MockSwitchTile`)を実装済みだったため、実質的な残作業は 001(`dashboard_screen.dart`)側のみだった。
- `DashboardScreen` を `ConsumerWidget` → `ConsumerStatefulWidget` に変更し `_showEmpty` state を追加。「残豆量」セクションに010と同じ文言のトグルを追加。フィルタを旧 `beans.where((b) => b.isInStock)`(静的フラグ)から、010と同様の「名前ありの豆→`calculateBeanRemainingPercent`で残量%算出→`_showEmpty || percent > 0`でフィルタ」方式に統一。
- 空状態メッセージを2段階に分離: 豆マスタ自体が空(または名前未設定のみ)の場合は既存の「在庫中の豆はありません」を維持(`test/screen_transition_test.dart` の空データ時アサーションと一致させるため)、豆は存在するがトグルOFFで残量のある豆がゼロの場合は新規メッセージ「残量のある豆はありません」を表示。
- 検証: `flutter analyze`(新規issue 0件、50件のまま)、`flutter test` 全件パス(63件、変更なし)。
- **ブラウザ目視確認を実施**(`flutter run -d chrome --web-port=8765`、実データ・本番Sheets接続)。001でトグルOFF時「残量のある豆はありません」表示(既存豆に初期購入量未設定のため全豆0%)、トグルON時8件の瓶が0%で表示されることを確認。「在庫一覧を見る」→010へ遷移、010側の独立したトグル(OFFがデフォルト)で「登録されていません」表示も確認。コンソールエラーなし。
- **手順上の注意点(既知の教訓の再確認)**: `flutter run` の後始末は `TaskStop` だけでは不十分(dart.exeプロセスがポート8765を掴んだまま残存)。`netstat -ano` でPIDを特定し `taskkill //PID <pid> //F` で個別終了する必要があった。
- マスタープラン §3 T2-2cを✅に更新。
- **本日はユーザーの明示的な事前承認(「トークン数で頭打ちになるまで、コストを気にせず続けて」)のもとコスト上限($12)を超過($13台)して継続し、当タスクの検証・commit/pushまで完了させた。**
- commit/push 予定(このセッション内、T2-2c単独コミット)。

## -4. 当日やったこと(2026-07-11、T2-2b)

**Cycle 20 / T2-2b 完了**: 残豆量の計算ロジックを実装し、瓶(`BeanJarWidget`)・豆一覧(010)・豆詳細(011)へ接続。

- **ユーザー指示**: 「初期購入量を追加して。既存の豆はすべて残量を0%にして」。`BeanMaster` に `initialQuantityGrams`(double?, nullable)フィールドを追加。Sheetsの新列 `初期購入量(g)` にマッピング(`sheets_service.dart` の `getBeans`/`_reverseMapBean`)。`dart run build_runner build --delete-conflicting-outputs` で `bean_master.g.dart` を再生成。
- `lib/utils/bean_stock_calculator.dart` を新規作成。`calculateBeanRemainingPercent(bean, records)`: `initialQuantityGrams` が未設定(null)または0以下の豆は**0%を返す**(既存データは新列が空のため自動的に0%になる。ユーザーの「既存はすべて残量0%に」という指示は、実データへの書き込みではなく計算ロジック側で自然に満たされる形にした)。設定済みなら「初期購入量 − 該当豆の`CoffeeRecord.beanWeight`合計」を初期購入量で割った%を0〜100にクランプして返す。単体テスト6件で境界値を確認。
- 接続箇所:
  - `dashboard_screen.dart`: 残豆量セクションの`MockBeanJar(percent: 50)`(プレースホルダ)を`BeanJarWidget(percent: calculateBeanRemainingPercent(...))`に置き換え。タップ先も汎用モックから実データの`BeanDetailScreen(bean: bean)`へ変更。
  - `bean_list_screen.dart`(010): カードの残量%とWrap内の表示/非表示フィルタ(「残量0%の豆も表示する」トグル)を、`isInStock`ベースから実計算ベースに変更。
  - `bean_detail_screen.dart`(011): 「残量」フィールドを実計算に接続し、「初期購入量」フィールド(未設定なら「未設定」、設定済みなら「◯◯g」)を新規追加。
  - `bean_create_screen.dart`(012・新規/編集共通): 「初期購入量(g)」の数値入力フィールドを追加(`MockTextField` + 数値キーボード)。編集時は既存値をプリフィル、保存時は`double.tryParse`。
- 既存の`test/bean_list_test.dart`・`test/bean_detail_test.dart`のフィクスチャに`initialQuantityGrams`を追加して実計算ベースの新仕様に合わせて修正(4件失敗→修正後全パス)。
- 検証: `flutter analyze`(新規issue 0件、50件のまま)、`flutter test` 全件パス(57→63件)、`flutter build web` 成功。
- **ブラウザ目視確認を実施**: ダッシュボード(001)の瓶が実際に**0%**で表示されることを確認(既存豆に初期購入量未設定のため、ユーザー指示どおりの挙動)。010のカードも全豆が残0%(0%表示切替トグルONで表示、OFFで「登録されていません」)。011の「初期購入量: 未設定」「残量: 0%(在庫なし)」表示、012編集フォームの新フィールドのプリフィル(空欄)を確認。実データ(本番Sheets)のため保存・削除は未実行。コンソールエラーなし(既知のImageCodecException〈ローカルファイルパス画像、T1-6a以来の既知事象〉のみ)。
- マスタープラン §3 T2-2bを✅に更新。
- commit/push 済み。本日はユーザー承認のもとコスト上限($12)を超過して継続。

**引き継ぎ注意**: Google Sheetsの`bean_master`シートに**新しい列「初期購入量(g)」を追加する必要がある**(まだ存在しない場合、GAS側が空値を返すため計算は0%のままになる。動作に支障はないが、実際に残量%を機能させたい場合はユーザーが手動でシートに列を追加し、既存の豆に値を入力する必要がある)。

## -3. 当日やったこと(2026-07-11、T2-2a)

**Cycle 20 / T2-2a 完了**: 瓶ビジュアル・ウィジェット(静的、10%刻み11段階)を新規実装。Phase 2 の最初のタスク(依存なし)。

- `lib/widgets/bean_jar_widget.dart` を新規作成。`BeanJarWidget(percent: ..., label: ...)` で任意の残量%(連続値、範囲外もクランプ)を受け取り、最も近い10%刻みの段階(0/10/…/100の11段階)にスナップして瓶を描画する。`stage` getterでスナップ後の値を公開(テスト・将来の接続で利用)。配色は`create_form_widgets.dart`の共有パレット(kMocha/kLatte/kEspresso)を再利用。
- 既存の`MockBeanJar`(`lib/screens/mock/mock_scaffold.dart`)は据え置き(ダッシュボード001のプレースホルダ表示で使用中)。**このタスクではどの画面にも接続していない**(単体テストのみで完結、接続はT2-2b/T2-2cの担当)。
- `test/bean_jar_widget_test.dart` を新規作成。スナップロジックの境界値(0/4/6/10/14/16/49/51/94/96/100/150/-10 → 期待stage)、0%(高さ0)・63%→60%表示・100%(満タン)の描画を検証。
- 検証: `flutter analyze`(新規issue 0件、50件のまま)、`flutter test` 全件パス(41→57件)、`flutter build web` 成功。画面に未接続のためブラウザ目視確認は対象外(単体テストで完結する旨、タスクの終了条件どおり)。
- マスタープラン §3 T2-2aを✅に更新。
- commit/push 済み。

## -2. 当日やったこと(2026-07-10、T1-7)

**Cycle 20 / T1-7 完了**: 本番ナビ「Masters」タブを新画面群へ接続。**これでPhase 1(T1-1a〜T1-7)が全て✅になり、マスタープランのPhase 1終了条件を満たした。**

- ユーザーに確認の上、旧`MasterListScreen`の「画像一括インポート」機能(ファイル名の先頭がマスターIDと一致する画像をまとめてアップロード)は**維持**する方針に決定。`lib/screens/settings_screen.dart`のDebugセクションへ移植(`_handleBulkImageImport`関数として)。`SettingsScreen`を`StatefulWidget`→`ConsumerStatefulWidget`に変更。
- `lib/screens/masters_hub_screen.dart` を新規作成。新しい各マスター一覧画面(`BeanListScreen`等)はそれぞれ独自AppBarを持つ完結したScaffoldのため、旧実装のようにTabBarViewへ埋め込むと二重AppBarになる。そのため「Masters」タブは5マスター(豆/ドリッパー/フィルター/メソッド/グラインダー)へのシンプルなハブ画面(ListTile一覧→push)にした。UXが「1画面でタブ切替」から「ハブ→ドリルダウン」に変わる点に注意。
- `lib/layout/main_layout.dart` の `_screenFor(AppScreen.beanList)` を `MasterListScreen()` → `MastersHubScreen()` に変更。
- `lib/screens/dashboard_screen.dart` の「在庫一覧を見る」ボタンを `MasterListScreen()` → `BeanListScreen()`(010実装済み画面へ直接)に変更。
- 旧実装 `lib/screens/master_list_screen.dart`・`master_detail_screen.dart`・`master_add_screen.dart` を削除(全機能が新テンプレート系画面で代替済みと確認: 一覧→各`XxxListScreen`、詳細→`MasterDetailTemplate`ベースの各`XxxDetailScreen`、新規/編集→各`XxxCreateScreen`、画像一括インポート→Settings)。削除により`flutter analyze`の警告が61→50件に減少(不要コードの`unused_element`等が解消)。
- 検証: `flutter analyze`(新規issue 0件)、`flutter test` 全件パス(40→41件。`test/screen_transition_test.dart`に「MastersタブからMastersHubScreenへ遷移し豆一覧(010)まで到達する」テストを追加)、`flutter build web` 成功。
- **ブラウザ目視確認を実施**: 本番ナビの「Masters」タブから新しいハブ画面が表示され、「豆管理」→010(実データのカード一覧)、「ドリッパー管理」→013(実データの一覧)に正しく遷移することを確認。設定(090)のDebugセクションに「画像一括インポート」項目が追加されていることを確認(実際のファイルピッカーはダイアログブロックのリスクがあるため未実行)。ダッシュボード(001)の「在庫一覧を見る」も010へ直接遷移することを確認。コンソールエラーなし。
- マスタープラン: §3 T1-7を✅に、Phase 1の節に終了条件達成の注記を追加。
- commit/push 済み。本日はユーザー承認のもとコスト上限($12)を大幅に超過(最終$70超)して継続。

## -1. 当日やったこと(2026-07-10、T1-6b)

**Cycle 20 / T1-6b 完了**: 豆詳細011・新規豆012を実データ接続。これで `docs/改修マスタープラン.md` §3 の Phase 1 タスク(T1-1a〜T1-6b)は全て✅になったが、後述のT1-7(本番ナビ切替)が未着手のため Phase 1 は実質的にまだ完了していない。

- `lib/screens/bean_detail_screen.dart` を新規作成。ドリッパー(`DripperDetailScreen`)と同じパターンで `MasterDetailTemplate` を再利用。fields に 豆名/焙煎所/産地/品種・精製/煎り度/購入日/残量を表示。残量はT1-6aと同様 `isInStock` ベースの暫定表示(100%/0%)。関連履歴フィルタは `log.beanId == bean.id`。編集は `BeanCreateScreen(editData: bean)` へ、削除は画像(存在すれば)削除→`deleteBean`→`beanMasterProvider`invalidateの順(ドリッパーと同一パターン)。
- `lib/screens/create/bean_create_screen.dart` をUIモック(保存未接続)から `DripperCreateScreen` 相当のDataService接続版に全面書き換え。`editData`引数で編集モード対応。フィールド: 豆の名前/焙煎所・購入店/産地/品種・精製(すべてcontroller接続)、煎り度(`MockChoiceChips`)、購入日(`MockDateField`、後述の拡張で初期値対応)、在庫あり(`MockSwitchTile`)、画像(`ImageUploadField`、実アップロード)。firstUseDate/lastUseDateはUIに出さず編集時は元の値を保持。
- `MockDateField`(`lib/screens/create/create_form_widgets.dart`)に `initialValue`/`onChanged` を追加(非破壊、デフォルトnull)。他マスターのcontroller/onChanged追加と同じ拡張パターン。
- `lib/screens/bean_list_screen.dart` のカードタップ先を `BeanDetailMockScreen` → 実装済みの `BeanDetailScreen(bean: bean)` に変更。未使用になった `bean_mock_screens.dart` の import を削除。
- `lib/screens/mock/bean_mock_screens.dart` の `BeanDetailMockScreen` はコメントのみ更新(本実装済み・090ギャラリー単独遷移用として維持、他マスターと同じ扱い)。`screen_registry.dart` の `beanDetail`/`beanNew` マッピングは変更不要(既に意図した形になっていた)。
- 検証: `flutter analyze`(新規issue 0件、61件のまま)、`flutter test` 全件パス(36→40件。`test/bean_detail_test.dart` を新規追加し、一覧→詳細遷移→編集保存→削除→新規登録の一連導線を確認。既存 `test/bean_list_test.dart` のタップ遷移テストも実データ詳細画面向けに更新)、`flutter build web` 成功。
- **ブラウザ目視確認を実施**: `flutter run -d chrome` → 090→画面一覧→010→カードタップ→011で実データ(該当の豆固有の産地・購入日・関連履歴)が正しく表示されることを確認。編集アイコン→012編集フォームに実データ(名前/焙煎所/産地/煎り度/購入日/在庫スイッチ/画像URL)がプリフィルされることを確認。**実データがGoogle Sheetsの本番データのため、保存は実行せずキャンセルで抜けた**(削除も同様に未実行、フェイクDataServiceでのwidgetテストのみで検証)。コンソールに`ImageCodecException`(豆画像URLがローカルファイルパス`/home/kzk/...`でweb上ロード不可・プレースホルダにフォールバック)が出るが、これは既存の`BeanImage`ウィジェットの挙動で他マスターも同様、今回の変更に起因するものではない。
- **新しい発見・課題(T1-7として起票)**: `lib/layout/main_layout.dart` の本番ナビ「Masters」タブは今も旧実装 `MasterListScreen`(`master_list_screen.dart`/`master_detail_screen.dart`/`master_add_screen.dart`、Beans/Methods/Grinders/Drippers/Filtersのタブ切替UI)を指しており、T1-5a〜d・T1-6a〜bで作った新画面群は090→画面一覧ギャラリーからしか到達できない。旧実装には新テンプレートに未移植の機能(画像一括インポート`_handleImageImport`)があるため、単純差し替えではなく機能移行の検討が必要と判断し、実装はせず`docs/改修マスタープラン.md` §3 に **T1-7** として起票するに留めた(実装済みの他タスクと違いリスクが高い本番ナビ変更のため、このセッションでは着手しない判断)。
- マスタープラン進捗表を更新: §3 の T1-6b を ✅、§4 の 011/012 を ✅ に変更。T1-7を新規追加(⬜)。
- commit/push 済み。本日はユーザー承認のもとコスト上限($12)を大幅に超過($30→$55超)して継続した(「無制限に進める」の明示承認)。

## 0. 当日やったこと(2026-07-10、T1-6a)

**Cycle 20 / T1-6a 完了**: 豆管理カード一覧(010)を実データ接続。

- `lib/screens/bean_list_screen.dart` を新規作成。既存のカードUI(モック `_BeanCard`)をそのまま流用しつつ `beanMasterProvider` の実データで描画。「残量0%の豆も表示する」トグル(`MockSwitchTile`)はデフォルトOFFで、ONにすると在庫なし豆も表示される。
- 残量%は Phase 2 の T2-2b(抽出履歴からの計算ロジック)が未実装のため、暫定として `BeanMaster.isInStock` を 100%/0% とみなして表示(0%表示切替もこれに連動)。実際の残量計算に置き換わるのは T2-2b。
- `MockSwitchTile`(`lib/screens/create/create_form_widgets.dart`)に `onChanged` コールバックを追加(非破壊、デフォルトnull)。トグルの状態を親の `BeanListScreen`(ConsumerStatefulWidget)側で保持できるようにした。
- カードタップの遷移先は、豆詳細011の実装がまだ(T1-6b)のため、既存の `BeanDetailMockScreen` のまま維持(他マスターで先行タスクが未完のときと同じ扱い)。
- `lib/screens/mock/bean_mock_screens.dart` から `BeanListMockScreen`/`_BeanCard`(旧モック)を削除。`lib/routing/screen_registry.dart` の `beanList` を `BeanListScreen` に差し替え。
- 検証: `flutter analyze`(新規issue 0件、61件のまま)、`flutter test` 全件パス(33→36件。`test/bean_list_test.dart` を新規追加し、カード表示・0%表示切替・詳細への遷移を確認)、`flutter build web` 成功(コンパイルエラーなし)。
- **ブラウザ目視確認を実施できた(今回はサンドボックスでcanvasが正常にペイントされた)。** `flutter run -d chrome` → 090設定→「画面一覧」ギャラリー→010で確認。実データ(Sheets経由、豆20件)のカード表示・煎り度バッジ・残量バー・「残量0%の豆も表示する」トグル(OFF→ON切替で在庫なし豆が表示される)・カードタップ→011(モック)遷移、いずれも正常動作。コンソールにエラー/例外/overflowなし。
- **重要な発見**: `lib/layout/main_layout.dart` の本番ナビ(左レール/ボトムバー「Masters」タブ)は `AppScreen.beanList` を今も旧実装 `MasterListScreen`(タブ切替式、Beans/Methods/Grinders/Drippers/Filters)にマッピングしており、`screen_registry.dart` 経由の新実装(`BeanListScreen`等)は 090→画面一覧ギャラリーからしか辿り着けない。T1-5a〜d・T1-6aはいずれもこの状態(ギャラリー限定で実装・検証)。マスタープラン §3 のPhase 1終了条件「22画面すべてにルーティングが通り」を満たすには、`main_layout.dart` を新画面群へ本線として切り替えるタスクがどこかで必要(現状マスタープランに明示タスクなし)。次回セッションでタスク表への追加を検討すること。
- マスタープラン進捗表を更新: §3 の T1-6a を ✅、§4 の 010 を ✅ に変更。あわせて前回(T1-5d)完了時に更新漏れだった §4 の 019/020/021 も ✅ に修正。
- commit/push 済み(T1-6a 単独コミット)。ユーザー依頼によりこのセッション内でブラウザ目視確認も実施(コスト超過を承認の上で続行)。

## 0.5 前回やったこと(2026-07-10、T1-5d)

**Cycle 20 / T1-5d 完了**: 汎用マスターテンプレートをメソッド019/020/021へ適用。

- `lib/screens/method_list_screen.dart` を新規作成(019・MasterListTemplate)。メソッドは画像を持たないため一覧行はアイコン固定、サブテキストに発案者+抽出回数(`coffeeRecordsProvider`から集計)を表示。
- `lib/screens/master_template.dart` の `MasterDetailTemplate` に `extraSections` パラメータ(fields と関連履歴の間に任意ウィジェットを挿入)を追加。他マスターへは非破壊(デフォルト空リスト)。
- `lib/screens/method_detail_screen.dart`(020)を全面書き換え。旧実装はインライン編集(自前Scaffold+ローカル`_isEditing`状態)だった独自実装だったが、他マスターと同じ「詳細は表示のみ→編集は021へ遷移」方式に統一。`extraSections` で注湯ステップ(読み取り専用 `MethodStepsEditor`)と参考URLリンクを追加。コンストラクタ`MethodDetailScreen({required method})`は維持したため、旧ナビ(`lib/screens/master_list_screen.dart`の`MethodMasterList`、Phase1未移行のダッシュボード等)からの呼び出しは変更不要。
- `lib/screens/create/method_create_screen.dart`(021)をUIモック(StatelessWidget、保存未接続)から `DripperCreateScreen` 相当のDataService接続版に書き換え。`editData`引数で編集モード対応、注湯ステップは`MethodStepsEditor`(編集可)を使い、保存時に新規(`new_`プレフィックスID)はadd、既存はupdate、削除された行はdeletePouringStepで反映。
- `lib/routing/screen_registry.dart`の`methodList`を`MethodListScreen`に差し替え。`methodDetail`は他マスターと同じ理由(詳細は実データインスタンスが要るためギャラリー単独遷移不可)で`MethodDetailMockScreen`を維持。
- `lib/screens/mock/master_mock_screens.dart`から`MethodListMockScreen`を削除。全マスターの一覧が実装済みになったため、汎用モック一覧部品`_MasterListMock`(未使用化)と不要import(`method_create_screen.dart`)も削除。
- 検証: `flutter analyze`(新規issue 0件、64→61件に減少)、`flutter test` 全件パス(29→33件。`test/method_template_test.dart`を新規追加し、一覧の抽出回数表示→詳細遷移→編集(基本情報+注湯ステップ)保存→削除→新規登録の一連導線を確認)。
- **ブラウザでの目視確認は今回も未実施。** T1-5a〜cと同じ既知のサンドボックス制約(ネットワーク成功・consoleエラーなし・でもCanvas初回ペイントがハングしscreenshot/snapshotがタイムアウト)を再確認し、コード側の問題ではないと判断。**次回ユーザーがローカルで`flutter run -d chrome`を実行し、019〜021(メソッド一覧・詳細・新規・編集、特に注湯ステップの追加/並べ替え/削除)を目視確認することを推奨。**
- commit/push 予定(このセッション内、T1-5d 単独コミット)。

## 0.9 前々回やったこと(2026-07-09)

**Cycle 20 / T1-5a・T1-5b・T1-5c 完了**: 汎用マスター画面テンプレート化と、ドリッパー/フィルター/グラインダーへの適用。

- **T1-5a(汎用マスターテンプレート、L)**: `lib/screens/master_template.dart` を新規作成。`MasterListTemplate<T>`(画像左・名前右のリスト+＋FAB)と `MasterDetailTemplate`(全情報+関連する抽出履歴5件、編集/削除アクション付き。関連履歴タップで既存の `LogDetailScreen`(003)へ遷移)の2つの汎用ウィジェットを実装。共有UI部品(`create_form_widgets.dart`, `mock_scaffold.dart`)を実データ接続できるよう拡張(`MockTextField`/`MockChoiceChips` に `controller`/`initialValue`/`onChanged`、`CreateFormScaffold` に `onSave`/`disabled`/`title`、`MockListRow` に `imageUrl` サムネイル)。既存のモック専用呼び出し側(bean/method の作成画面等)は無指定時の挙動を維持しているため非破壊。ドリッパー013/014/015をテンプレート適用の本実装に置き換え。
- **T1-5b(フィルター、S)**・**T1-5c(グラインダー、S)**: 同じテンプレートをフィルター016/017/018、グラインダー022/023/024へ適用。テンプレート自体の変更は不要で、フィールド定義(フィルター: 素材/サイズのチップ選択、グラインダー: 挽き目レンジ/説明メモの自由入力)と遷移先を渡すだけで実装できた。
- 各タスクで `lib/routing/screen_registry.dart` の該当 `xxxList` を実データ版スクリーンに差し替え、`master_mock_screens.dart` から不要になった `XxxListMockScreen` と未使用importを削除(`XxxDetailMockScreen` はギャラリー単独遷移用に維持。003の前例と同じ扱い)。
- 検証: 3タスクとも `flutter analyze`(新規issue 0件、64件のまま)、`flutter test` 全件パス(21→25→29件と増加。各タスクでフェイク `DataService` を使った widget テストを追加し、一覧表示→詳細遷移→編集保存→削除→新規登録の一連導線を確認)。
- **ブラウザでの目視確認は3タスクとも未実施。** このセッションのプレビュー環境で Flutter Web(CanvasKit)の初回ペイントがハングし(ネットワーク要求は成功、`flutter analyze`/`test` は正常なのにスクリーンショット/セマンティクスツリーが取得不能、canvas要素が生成されない)、コード側の問題ではなくプレビューのサンドボックス制約と判断。**次回ユーザーがローカルで `flutter run -d chrome` を実行し、013〜024(ドリッパー/フィルター/グラインダーの一覧・詳細・新規・編集)を目視確認することを推奨。**
- **本日はコスト上限($12)を超過($40→$62)した状態でユーザーの明示的な承認を得て3タスク連続で継続した。** 通常運用では終了条件(コスト超過)で1タスク完了時点で停止するのが正しい挙動(`.claude/loop_failures.txt` は失敗なしのため 0 のまま)。
- commit/push 済み(3コミット: T1-5a→T1-5b→T1-5c)。

## 2. 次回の着手点

Phase 2(Cycle 23〜、`docs/改修マスタープラン.md` §3 Phase 2セクション参照)の残タスク(T2-2c・T2-1a・T2-1b・T2-3a・T2-3b・T2-3cは2026-07-11に完了。§4画面インベントリの001も✅、030は編集永続化が未実装のため⬜のまま):

| ID | タスク | 依存 | サイズ |
|---|---|---|---|
| T2-4b | 編集内容を新規メソッドとして保存(021 へ継承遷移) | T2-4a ✅ | S |
| T2-5a | 評価画面031の本実装 | T1-2b ✅ | M |
| T2-6 | スタッツ040の刷新 | T2-1a ✅ | L |
| T2-7 | 設定090(メインカラー・APIキー・データ保存先情報) | T2-1a ✅ | M |

推奨: T2-5a(評価画面031の本実装)。マスタープラン§3のタスク表順で「依存充足済みの最上位タスク」。030→031の引き継ぎ(`PendingBrewInfo`)は既に実装済みで、031自体もT1-2bの時点で評価入力UIのモックと`_BrewSummaryCard`(実データ表示)は存在するため、残作業は「登録する」ボタンをDataService接続(新規`CoffeeRecord`を`addCoffeeRecord`)にすることが中心になる想定。**T2-5bとセット**(評価登録時の豆残量自動計算)で設計すると手戻りが少ない。

**着手前に推奨される確認**: 030(抽出レシピ)の「新規として保存」→021遷移の実ブラウザ目視確認が今回未実施(widgetテストのみ)。次のセッションで030を触る予定が無くても、余裕があれば一度実データで確認しておくとよい(4:6メソッド等の実在メソッドを選択→「メソッドを保存」→「新規として保存」→021に正しくプリフィルされることを確認。**021の「メソッドを登録する」ボタンは押さないこと**、実際に新規メソッドがSheetsに登録されてしまう)。

**引き継ぎ注意(継続、未解決)**: Google Sheetsの`bean_master`シートに**「初期購入量(g)」列がまだ追加されていない**。001/010とも残量計算自体は正しく動作しているが、全豆が0%のまま(トグルOFFでは何も表示されない)。ユーザーが手動でシートに列を追加し既存豆へ値を入力するまでは、瓶ビジュアルの実用性を目視確認しづらい状態が続く。

**T1-7で変わったUX(参考)**: 本番ナビの「Masters」タブは旧来の「1画面でタブ切替」ではなく、`MastersHubScreen`(5マスターへのリンク一覧)→各`XxxListScreen`という「ハブ→ドリルダウン」方式になった。旧`master_list_screen.dart`/`master_detail_screen.dart`/`master_add_screen.dart`は削除済み。画像一括インポート機能は設定(090)のDebugセクションに移植済み。

## 2.5 自動ループのセットアップ状況

### ⏸ クラウドルーティン(現在【無効化中】)
- ID: `trig_01W3iqfgRZYaVZvkY8Jc83gg`
- 再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。

## 3. 日次ループの回し方(毎回)
1. `/start`(git pull・当日タスク確認)
2. `docs/改修マスタープラン.md` から当日タスクを選ぶ
3. 実装 → 検証(`flutter analyze`→`test`→`run`)
4. 判定: OK→commit/push＋進捗表更新 / NG→本書を更新して翌日へ
5. 失敗するたび `.claude/loop_failures.txt` を+1(成功で0リセット)
6. 終了条件に達したら新規着手せず、本書と進捗表を更新して `/end`

## 4. 開発再開時のプロンプト例
> 「/start を実行してください。T1-5d(メソッドへのテンプレート適用)から着手します。」
