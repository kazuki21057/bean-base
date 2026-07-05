# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-05（Cycle 20 T1-1c 完了）

## 1. 当日やったこと（2026-07-05）

**Cycle 20 / T1-1c 完了**: `MainLayout` を `AppScreen.topLevelTabs` ベースに再構築。

- `lib/layout/main_layout.dart` を改修: `NavigationRail`/`NavigationBar` の destinations と `_navigateToIndex` を、ハードコードされたindex switchから `AppScreen.topLevelTabs` をループするenum駆動の構造に変更
- アイコン・ラベル・遷移先画面(Home/Masters/Logs/Calc/Stats)は既存のまま維持し、`test/screen_transition_test.dart`（`Icons.coffee`→`CoffeeLogListScreen`）を壊さないことを確認
- `flutter analyze` → 新規issue 0件（既存84件のまま）
- `flutter test` → 17件全パス
- `flutter run -d chrome` → NavigationRailの5タブ(Home/Masters/Logs/Calc/Stats)すべてで正しい画面に遷移すること、コンソールエラー無しを確認
- commit/push 済み

## 2. 次回の着手点

**Phase 1 — 画面構成・ナビ再編（Cycle 20〜22）** 継続。次は T1-2a。

| ID | タスク | 依存 |
|---|---|---|
| T1-2a | 抽出030の画面骨組み(既存記録画面から抽出パートを分離) | T1-1c ✅ |
| T1-4a | 抽出履歴リスト002(実データ表示) | T1-1c ✅ |
| T1-3 | ダッシュボード001の骨組み | T1-1c ✅ |

## 2.5 自動ループのセットアップ状況

### ⏸ クラウドルーティン（現在【無効化中】）
- ID: `trig_01W3iqfgRZYaVZvkY8Jc83gg`
- 再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。

## 3. 日次ループの回し方（毎回）
1. `\start`（git pull・当日タスク確認）
2. `docs/改修マスタープラン.md` から当日タスクを選ぶ
3. 実装 → 検証（`flutter analyze`→`test`→`run`）
4. 判定: OK→commit/push＋進捗表更新 / NG→本書を更新して翌日へ
5. 失敗するたび `.claude/loop_failures.txt` を+1（成功で0リセット）
6. 終了条件に達したら新規着手せず、本書と進捗表を更新して `\end`

## 4. 開発再開時のプロンプト例
> 「\start を実行し、Phase 1（Cycle 20）を開始してください。T1-2a から着手します。」
