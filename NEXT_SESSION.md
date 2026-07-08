# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-08(T1-4c 完了)

## 1. 当日やったこと(2026-07-08)

**Cycle 20 / T1-4b 完了**(前セクション参照): 抽出履歴詳細003(全情報表示・編集)。

**Cycle 20 / T1-4c 完了**: 002のスワイプ→評価継承で031へ遷移。

- `lib/models/pending_brew_info.dart` に評価値(scoreFragrance〜scoreOverall/taste/concentration/comment、いずれも任意)を追加。031側の初期値としてのみ使用し、保存(records反映)は引き続きT2-5aで実装する。
- `lib/screens/create/brew_evaluation_screen.dart` を更新し、`PendingBrewInfo` の評価値があればスコアスライダー・テイスト/濃度チップ・コメント欄の初期値に反映(なければ従来のデフォルト値)。
- `lib/screens/create/create_form_widgets.dart` の `MockTextField` に `initialValue` パラメータを追加(コメント欄の初期値表示用)。
- `lib/screens/log_list_screen.dart` に `Dismissible`(`DismissDirection.endToStart`、パッケージ追加なし)を実装。`confirmDismiss` 内でスワイプされたログの抽出情報・評価値から `PendingBrewInfo` を構築し、`BrewEvaluationScreen`(031)へ遷移。**常に `false` を返すためリストから行は削除されない**。メソッドが(削除等で)見つからない場合はSnackBarで通知し遷移しない。UIモック(`LogListMockScreen`)にあったスワイプ案内文言を実画面にも追加。
- 検証済み: `flutter analyze`(新規issue 0件、71件のまま)、`flutter test`(全17件パス)、`flutter run -d web-server` + ブラウザでスワイプ操作を確認 — 031へ遷移し抽出情報(豆量/湯量/温度/時間)と評価値(スコア・テイスト・濃度)が正しく引き継がれる、スワイプ後もリストから行が消えない、コンソールに`[Antigravity]`ログ以外のエラーなしを確認。
- commit/push 済み。

## 2. 次回の着手点

依存が満たされた次のタスク(`docs/改修マスタープラン.md` §3 Phase 1 参照):

| ID | タスク | 依存 |
|---|---|---|
| T1-3 | ダッシュボード001の骨組み | T1-1c ✅ |
| T1-5a | 汎用マスター画面テンプレート化(リスト/詳細/新規フォームの共通ウィジェット化、Lサイズ) | T1-1c ✅ |
| T1-6a | 豆管理カード一覧010 | T1-1c ✅ |

推奨: Phase 1の残タスクはT1-3(ダッシュボード)・T1-5a(汎用テンプレート、L)・T1-6a(豆管理カード)。T1-5aはT1-5b/c/d・T1-6bの前提になるため優先度が高いが、Lサイズで1ループでは収まらない可能性がある。当日の残り時間・コストに応じてT1-3(Mサイズ)から着手するのも可。

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
> 「\start を実行してください。T1-3(ダッシュボード001)から着手します。」
