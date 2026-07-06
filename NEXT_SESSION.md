# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-06(T1-2a 完了)

## 1. 当日やったこと(2026-07-06)

**Cycle 20 / T1-2a 完了**: 抽出030の画面骨組みを実装。

- 旧 `lib/screens/calculator_screen.dart`(記録画面。メソッド/器具選択・タイマー・Pouring Steps編集・評価スコア・保存が1画面に同居)を、抽出パートのみの `lib/screens/brew_recipe_screen.dart`(`BrewRecipeScreen`)に分離。評価(スコア入力・記録保存)は含めず、完了ボタンから 031(`BrewEvaluationScreen`、現時点ではUIモック)へ遷移するのみ(データ引き継ぎは次の T1-2b、records保存は T2-5a)。
- `lib/layout/main_layout.dart` の 030 タブ、`lib/screens/home_screen.dart`(Brew Coffee ボタン/Reuse Recipe)、`lib/screens/coffee_log_list_screen.dart`(スワイプ→Copy Recipe)の3箇所を `CalculatorScreen` → `BrewRecipeScreen` に差し替え。
- 旧 `calculator_screen.dart` は完全に置き換えられたため削除。対応する `test/calculator_test.dart` は `test/brew_recipe_test.dart` にリネームし、`BrewRecipeScreen` を対象にするよう更新。
- 検証済み: `flutter analyze`(新規issue 0件、既存89→75件に減少)、`flutter test`(全18件パス)、`flutter run -d web-server` + ブラウザで実データ確認 — 030タブへの遷移、Sheetsの実メソッド一覧(13件)がドロップダウンに表示、メソッド選択でPouring Steps(実データ)がテーブルに反映、メソッド未選択時のバリデーションSnackBar、評価画面への遷移ボタン、いずれも正常動作を確認。評価UIが含まれていないこと(分離できていること)も確認。
- **検証中に発見した既知の問題**(T1-2aの実装バグではなく、`MainLayout`の`NavigationRail`側の潜在バグの可能性): ブラウザのウィンドウリサイズや一部のマウスホイールscrollをきっかけに`NavigationRail`で`RenderFlex overflowed`が発生し、タブの描画が一時的に応答なしになる現象を確認(再読み込みで復旧、データ処理への影響なし)。詳細は `rules/verification.md` の教訓に追記済み。次に030系画面を触る際に再現するか軽く確認し、再現するなら`NavigationRail`のレイアウトを見直す。
- commit/push 済み。

## 2. 次回の着手点

依存が満たされた次のタスク(`docs/改修マスタープラン.md` §3 Phase 1 参照):

| ID | タスク | 依存 |
|---|---|---|
| T1-2b | 評価031の画面骨組みと 030→031 のデータ受け渡し | T1-2a ✅ |
| T1-4a | 抽出履歴リスト002(実データ表示) | T1-1c ✅ |
| T1-3 | ダッシュボード001の骨組み | T1-1c ✅ |
| T1-5a | 汎用マスター画面テンプレート化 | T1-1c ✅ |

推奨: T1-2a の直後なので T1-2b(030→031のデータ受け渡し)から着手すると文脈を活かせる。

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
> 「\start を実行してください。T1-2b(030→031のデータ受け渡し)から着手します。」
