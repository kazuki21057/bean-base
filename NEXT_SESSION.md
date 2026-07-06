# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-07(T1-4a 完了)

## 1. 当日やったこと(2026-07-07)

**Cycle 20 / T1-2b 完了**(commit 5f8ed87): 評価031の画面骨組みと030→031のデータ受け渡し。詳細は前回セクション参照。

**Cycle 20 / T1-4a 完了**: 抽出履歴リスト002(実データ表示)。

- `lib/screens/log_list_screen.dart` を新規作成。UIモック(`LogListMockScreen`)の骨格(`MockScreenScaffold`/`MockListRow`/`MockScoreBadge`)に、実データ(`coffeeRecordsProvider`/`beanMasterProvider`/`methodMasterProvider`)を接続した本実装。旧 `CoffeeLogListScreen` と同じフィルタ(`methodId`が空でない・`totalTime>0`)・ソート(`brewedAt`降順)を踏襲。
- 行タップは既存の実画面 `LogDetailScreen`(003本実装はT1-4b)へ遷移。**スワイプでの評価継承(T1-4c)は未実装**(旧`CoffeeLogListScreen`にあった「スワイプでレシピ再利用」機能は今回のリニューアルで一旦削除。T1-4cで新しい意味(評価継承)のスワイプとして作り直す想定)。
- `lib/layout/main_layout.dart`(002タブ)・`lib/screens/home_screen.dart`(「View All Logs」ボタン)の参照先を`LogListScreen`に差し替え。役目を終えた `lib/screens/coffee_log_list_screen.dart` は削除、`test/screen_transition_test.dart` の期待値も新画面のタイトル/空状態文言に更新。
- 検証済み: `flutter analyze`(新規issue 0件、72件に減少)、`flutter test`(全17件パス)、`flutter run -d web-server` + ブラウザで実データ確認 — 002タブへの遷移、Sheetsの実履歴(豆名・日時・メソッド名・スコア)がリスト表示、行タップで実データを持った003(LogDetailScreen)へ遷移、コンソールに機能に影響するエラー無し(画像読み込み例外は豆マスターのローカルパス起因の既知事象で本タスクと無関係)を確認。
- commit/push 済み。

## 2. 次回の着手点

依存が満たされた次のタスク(`docs/改修マスタープラン.md` §3 Phase 1 参照):

| ID | タスク | 依存 |
|---|---|---|
| T1-4b | 抽出履歴詳細003(全情報表示・編集) | T1-4a ✅ |
| T1-4c | 002 のスワイプ→評価継承で 031 へ遷移 | T1-4a ✅, T1-2b ✅ |
| T1-3 | ダッシュボード001の骨組み | T1-1c ✅ |
| T1-5a | 汎用マスター画面テンプレート化 | T1-1c ✅ |

推奨: T1-4b(抽出履歴詳細003)から着手すると 002→003 の流れが完結する。その後 T1-4c(スワイプ→031)も依存が揃っている。

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
> 「\start を実行してください。T1-4b(抽出履歴詳細003)から着手します。」
