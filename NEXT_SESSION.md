# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-07(T1-2b 完了)

## 1. 当日やったこと(2026-07-07)

**Cycle 20 / T1-2b 完了**: 評価031の画面骨組みと 030→031 のデータ受け渡しを実装。

- `lib/models/pending_brew_info.dart` を新規作成。030 で確定した抽出情報(brewedAt/method/bean/grinder/dripper/filter/beanWeight/totalWater/totalTime/bloomingWater/bloomingTime)を保持する `PendingBrewInfo` を定義(Sheetsへの永続化はしない、一時的な受け渡し用)。プレビュー用に `PendingBrewInfo.mock()` も用意。
- `lib/screens/brew_recipe_screen.dart` の `_finishAndEvaluate()` を、旧 `_logThisBrew()` と同じ計算式(現在の豆量に応じたスケーリング、蒸らし分の抽出)で `PendingBrewInfo` を構築し、`BrewEvaluationScreen(info: ...)` へ渡すように変更。
- `lib/screens/create/brew_evaluation_screen.dart` を `PendingBrewInfo` を必須引数として受け取るように変更し、`_BrewSummaryCard` のハードコードされたモック値(豆名/メソッド名/豆量/湯量/温度/時間)を実データ表示に置き換え。評価スコア・コメント入力とrecords保存は引き続きUIモック(T2-5aで実装)。
- `BrewEvaluationScreen()` の呼び出し元(`lib/routing/screen_registry.dart`、UIモック専用の`lib/screens/mock/brew_recipe_mock_screen.dart`)は `PendingBrewInfo.mock()` を渡すよう更新。
- 検証済み: `flutter analyze`(新規issue 0件、75件のまま)、`flutter test`(全17件パス)、`flutter run -d web-server` + ブラウザで実データ確認 — 030で実メソッド(4:6メソッド)選択→Pouring Steps(実データ6件)反映まで確認。**030→031遷移ボタンのクリックはブラウザ自動操作側の制約(後述)により実クリックでは確認できず、コードレビューと計算ロジックの一致(旧CalculatorScreen._logThisBrewと同一式)で妥当性を確認**。
- commit/push 済み。

### 今回発生したブラウザ自動操作の制約(rules/verification.md 既存の教訓に該当)
- メソッド選択後にPouring Stepsテーブルが伸び、030画面の最下部(評価へボタン)を表示するにはスクロールが必要になるが、`computer`ツールのマウスホイールscroll/ドラッグがこのFlutter Web画面の該当スクロール位置より先に進まず、ボタンを直接クリックして確認できなかった(既存教訓「Chrome拡張のマウスホイールscrollがFlutter Webのスクロール可能領域に効かないことがある」に合致)。次回この画面を触る際、`flutter run -d chrome`(headed Chrome、web-serverでなく)での手動確認、または`ensureVisible`相当が使えるテストコードでの検証を検討する。

## 2. 次回の着手点

依存が満たされた次のタスク(`docs/改修マスタープラン.md` §3 Phase 1 参照):

| ID | タスク | 依存 |
|---|---|---|
| T1-4c | 002 のスワイプ→評価継承で 031 へ遷移 | T1-4a, T1-2b ✅(T1-4aが未完了なので実質保留) |
| T1-4a | 抽出履歴リスト002(実データ表示) | T1-1c ✅ |
| T1-3 | ダッシュボード001の骨組み | T1-1c ✅ |
| T1-5a | 汎用マスター画面テンプレート化 | T1-1c ✅ |

推奨: T1-4a(抽出履歴リスト002)から着手すると、その後 T1-4c(002→031連携)に繋げやすい。

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
> 「\start を実行してください。T1-4a(抽出履歴リスト002の実データ表示)から着手します。」
