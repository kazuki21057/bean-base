# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-10(T1-5d 完了)

## 0. 当日やったこと(2026-07-10)

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

## 1. 前回やったこと(2026-07-09)

**Cycle 20 / T1-5a・T1-5b・T1-5c 完了**: 汎用マスター画面テンプレート化と、ドリッパー/フィルター/グラインダーへの適用。

- **T1-5a(汎用マスターテンプレート、L)**: `lib/screens/master_template.dart` を新規作成。`MasterListTemplate<T>`(画像左・名前右のリスト+＋FAB)と `MasterDetailTemplate`(全情報+関連する抽出履歴5件、編集/削除アクション付き。関連履歴タップで既存の `LogDetailScreen`(003)へ遷移)の2つの汎用ウィジェットを実装。共有UI部品(`create_form_widgets.dart`, `mock_scaffold.dart`)を実データ接続できるよう拡張(`MockTextField`/`MockChoiceChips` に `controller`/`initialValue`/`onChanged`、`CreateFormScaffold` に `onSave`/`disabled`/`title`、`MockListRow` に `imageUrl` サムネイル)。既存のモック専用呼び出し側(bean/method の作成画面等)は無指定時の挙動を維持しているため非破壊。ドリッパー013/014/015をテンプレート適用の本実装に置き換え。
- **T1-5b(フィルター、S)**・**T1-5c(グラインダー、S)**: 同じテンプレートをフィルター016/017/018、グラインダー022/023/024へ適用。テンプレート自体の変更は不要で、フィールド定義(フィルター: 素材/サイズのチップ選択、グラインダー: 挽き目レンジ/説明メモの自由入力)と遷移先を渡すだけで実装できた。
- 各タスクで `lib/routing/screen_registry.dart` の該当 `xxxList` を実データ版スクリーンに差し替え、`master_mock_screens.dart` から不要になった `XxxListMockScreen` と未使用importを削除(`XxxDetailMockScreen` はギャラリー単独遷移用に維持。003の前例と同じ扱い)。
- 検証: 3タスクとも `flutter analyze`(新規issue 0件、64件のまま)、`flutter test` 全件パス(21→25→29件と増加。各タスクでフェイク `DataService` を使った widget テストを追加し、一覧表示→詳細遷移→編集保存→削除→新規登録の一連導線を確認)。
- **ブラウザでの目視確認は3タスクとも未実施。** このセッションのプレビュー環境で Flutter Web(CanvasKit)の初回ペイントがハングし(ネットワーク要求は成功、`flutter analyze`/`test` は正常なのにスクリーンショット/セマンティクスツリーが取得不能、canvas要素が生成されない)、コード側の問題ではなくプレビューのサンドボックス制約と判断。**次回ユーザーがローカルで `flutter run -d chrome` を実行し、013〜024(ドリッパー/フィルター/グラインダーの一覧・詳細・新規・編集)を目視確認することを推奨。**
- **本日はコスト上限($12)を超過($40→$62)した状態でユーザーの明示的な承認を得て3タスク連続で継続した。** 通常運用では終了条件(コスト超過)で1タスク完了時点で停止するのが正しい挙動(`.claude/loop_failures.txt` は失敗なしのため 0 のまま)。
- commit/push 済み(3コミット: T1-5a→T1-5b→T1-5c)。

## 2. 次回の着手点

Phase 1(Cycle 20)の残タスク(`docs/改修マスタープラン.md` §3 参照):

| ID | タスク | 依存 | サイズ |
|---|---|---|---|
| T1-6a | 豆管理カード一覧010(カード形式・実データ) | T1-1c ✅ | M |
| T1-6b | 豆詳細011・新規豆012(テンプレート応用) | T1-6a, T1-5a ✅ | M |

推奨: T1-5a〜dが全て完了し `lib/screens/master_template.dart`(`MasterListTemplate`/`MasterDetailTemplate`)が4マスター種で実証済み(ドリッパー/フィルター/グラインダー/メソッド)。`MasterDetailTemplate`には`extraSections`(fields と関連履歴の間に任意ウィジェットを挿入)が追加済みなので、豆詳細011で必要になりそうな独自セクション(残量%表示など)があれば同じ仕組みが使える。次はT1-6a(豆管理カード一覧010)。ただし010は他マスターの「画像左・名前右のリスト」ではなく「カード形式(焙煎所/豆名/煎り度/画像/残量、0%表示チェックボックス)」という異なるレイアウト仕様のため、`MasterListTemplate`をそのまま流用せず新規カードUIの実装が必要になる可能性が高い。

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
