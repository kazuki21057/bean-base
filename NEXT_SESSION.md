# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-09(T1-5a 完了)

## 0. 当日やったこと(2026-07-09)

**Cycle 20 / T1-5a 完了**: 汎用マスター画面テンプレート化(リスト/詳細/新規フォームの共通ウィジェット)。ドリッパー013/014/015に適用。

- `lib/screens/master_template.dart` を新規作成。`MasterListTemplate<T>`(画像左・名前右のリスト+＋FAB)と `MasterDetailTemplate`(全情報+関連する抽出履歴5件、編集/削除アクション付き)の2つの汎用ウィジェットを実装。関連履歴タップで既存の実装済み `LogDetailScreen`(003)へ遷移する導線も接続。
- 共有UI部品(`lib/screens/create/create_form_widgets.dart`, `lib/screens/mock/mock_scaffold.dart`)を実データ接続できるよう拡張: `MockTextField`/`MockChoiceChips` に `controller`/`initialValue`/`onChanged` を追加、`CreateFormScaffold` に `onSave`/`disabled`/`title` オーバーライドを追加、`MockListRow` に `imageUrl` サムネイル表示を追加。既存のモック専用呼び出し側(bean/filter/grinder/method の作成画面)は無指定時の挙動を維持しているため非破壊。
- `lib/screens/dripper_list_screen.dart`(013)・`lib/screens/dripper_detail_screen.dart`(014)を新規作成。`lib/screens/create/dripper_create_screen.dart`(015)はUIモックから `DataService` 接続の本実装(新規登録+編集の両対応)に置き換え。
- `lib/routing/screen_registry.dart` の `dripperList` を実データ版 `DripperListScreen` に差し替え。`lib/screens/mock/master_mock_screens.dart` から不要になった `DripperListMockScreen` を削除(`DripperDetailMockScreen` はギャラリー単独遷移用に維持、003の前例と同じ扱い)。
- 検証: `flutter analyze`(新規issue 0件、64件のまま)、`flutter test`(21件中21件パス。新規 `test/dripper_template_test.dart` で一覧表示→詳細遷移→編集保存→削除→新規登録の一連導線をフェイク `DataService` 経由で確認)。
- **注意:** `flutter run -d web-server` によるブラウザ実機確認は、このセッションのプレビュー環境で CanvasKit の初回ペイントがハング(スクリーンショット/セマンティクスツリーが取得不能、キャンバス要素が生成されない)し、実施できなかった。コード側のエラーではなく(analyze/test は正常)、プレビューのサンドボックス制約と考えられる。**次回ユーザーがローカルで `flutter run -d chrome` を実行し、013→014→015の遷移・保存・削除を目視確認することを推奨。**
- commit/push 未実施(次回冒頭で実施予定、または今回のセッション内で実施)。

## 1. 前回やったこと(2026-07-08)

**Cycle 20 / T1-4b・T1-4c 完了**(前セクション参照): 抽出履歴詳細003、002のスワイプ→評価継承。

**Cycle 20 / T1-3 完了**: ダッシュボード001の骨組み(残豆量・直近5件のプレースホルダ+各遷移)。

- `lib/screens/dashboard_screen.dart` を新規作成。UIモック(`DashboardMockScreen`)の骨格(黒板風ウェルカムボード+`FormSection`×2)に、「直近の抽出5件」は実データ(`coffeeRecordsProvider`、実装済みの003へ遷移)を接続。「残豆量」は在庫中の豆の実名を表示しつつ、残量%の算出ロジック自体はPhase 2(T2-2b)実装のためプレースホルダ値(50%固定)のまま。
- 遷移: 直近5件の行タップ→003(`LogDetailScreen`、実データ)、「すべての履歴を見る」→002(`LogListScreen`、実データ)、「在庫一覧を見る」→010相当(既存の実画面`MasterListScreen`)、残豆量の瓶タップ→011(`BeanDetailMockScreen`、モックのまま。実データ接続はT1-6bで実装)。
- `lib/main.dart`・`lib/layout/main_layout.dart` の初期画面/タブ0を旧`HomeScreen`から`DashboardScreen`に差し替え。旧`HomeScreen`(実データの在庫グリッド+直近ログ+Firestore移行ボタン等)は役目を終えたため削除。`test/screen_transition_test.dart` の期待値も新画面(001バッジ・タイトル・空状態文言)に更新。
- 検証済み: `flutter analyze`(新規issue 0件、64件に減少 — HomeScreen削除分の警告が減った)、`flutter test`(全17件パス)、`flutter run -d web-server` + ブラウザで001→002/003/010/011の4遷移すべてを実際にクリックして確認。コンソールに新規の機能影響エラーなし(豆マスター画像パス起因の既知事象のみ)。
- commit/push 済み。

## 2. 次回の着手点

Phase 1(Cycle 20)の残タスク(`docs/改修マスタープラン.md` §3 参照):

| ID | タスク | 依存 | サイズ |
|---|---|---|---|
| T1-5b | テンプレートをフィルター016/017/018へ適用 | T1-5a ✅ | S |
| T1-5c | テンプレートをグラインダー022/023/024へ適用 | T1-5a ✅ | S |
| T1-5d | テンプレートをメソッド019/020/021へ適用(名前/発案者小書き/抽出回数の差分吸収) | T1-5a ✅ | M |
| T1-6a | 豆管理カード一覧010(カード形式・実データ) | T1-1c ✅ | M |
| T1-6b | 豆詳細011・新規豆012(テンプレート応用) | T1-6a, T1-5a ✅ | M |

推奨: T1-5a完了により `lib/screens/master_template.dart` の `MasterListTemplate`/`MasterDetailTemplate` が使えるようになった。`lib/screens/dripper_list_screen.dart`・`dripper_detail_screen.dart`・`create/dripper_create_screen.dart` を実装パターンとして、T1-5b(フィルター、Sサイズ)から着手するのが最も軽い。フィールド構成がほぼ同じなので流用しやすい。

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
> 「\start を実行してください。T1-5a(汎用マスター画面テンプレート化)から着手します。」
