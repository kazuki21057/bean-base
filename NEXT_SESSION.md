# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-11(T2-2a 完了、Phase 2 着手)

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

Phase 2(Cycle 23〜、`docs/改修マスタープラン.md` §3 Phase 2セクション参照)の残タスク:

| ID | タスク | 依存 | サイズ |
|---|---|---|---|
| T2-1a | 黒板風テーマ(配色・フォント・背景テクスチャ) | T1-3 ✅ | M |
| T2-2b | 残豆量の計算ロジック(抽出履歴から豆ごとの残量算出)と瓶(`BeanJarWidget`)への接続 | T2-2a ✅ | M |
| T2-3a | 抽出レシピ030: 豆名・豆量・メソッド選択フォーム | T1-2a ✅ | M |
| T2-5a | 評価画面031の本実装 | T1-2b ✅ | M |

推奨: T2-2b(残豆量の計算ロジック)。`lib/widgets/bean_jar_widget.dart`(T2-2a、スナップ描画のみ・単体テスト済み)ができたので、次は「抽出履歴からどう残量%を計算するか」のロジックを実装し、`dashboard_screen.dart`の`MockBeanJar`・`bean_list_screen.dart`/`bean_detail_screen.dart`の`isInStock`ベースの暫定表示(100%/0%)を実計算+`BeanJarWidget`へ置き換える。残量計算式(豆の初期量をどう持つか、抽出ごとの使用量をどう引くか)はBeanMaster/CoffeeRecordモデルに現状「量」フィールドが無いため、モデル拡張が必要かどうかも含めて設計が要る(着手前にユーザーへ計算方式を確認するのが安全)。

**T1-7で変わったUX(参考)**: 本番ナビの「Masters」タブは旧来の「1画面でタブ切替」ではなく、`MastersHubScreen`(5マスターへのリンク一覧)→各`XxxListScreen`という「ハブ→ドリルダウン」方式になった。旧`master_list_screen.dart`/`master_detail_screen.dart`/`master_add_screen.dart`は削除済み。画像一括インポート機能は設定(090)のDebugセクションに移植済み。

## 2.5 自動ループのセットアップ状況

### ⏸ クラウドルーティン(現在【無効化中】)
- ID: `trig_01W3iqfgRZYaVZvkY8Jc83gg`
- 再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。

## 3. 日次ループの回し方(毎回)
1. `\start`(git pull・当日タスク確認)
2. `docs/改修マスタープラン.md` から当日タスクを選ぶ
3. 実装 → 検証(`flutter analyze`→`test`→`run`)
4. 判定: OK→commit/push＋進捗表更新 / NG→本書を更新して翌日へ
5. 失敗するたび `.claude/loop_failures.txt` を+1(成功で0リセット)
6. 終了条件に達したら新規着手せず、本書と進捗表を更新して `\end`

## 4. 開発再開時のプロンプト例
> 「\start を実行してください。T1-5d(メソッドへのテンプレート適用)から着手します。」
