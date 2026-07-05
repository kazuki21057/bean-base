# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-05（コスト上限超過につき停止 / ユーザー依頼の作成画面UIモック作業後）

## 1. 当日やったこと（2026-07-05）

**Cycle 20 / T1-1c 完了**(コミット済み): `MainLayout` を `AppScreen.topLevelTabs` ベースに再構築。

**ユーザー依頼: 全22画面のUIモック作成(マスタープランのタスク表とは別枠。コスト上限超過をユーザーが明示的に承認して続行)**

- 対象: **全22画面**。作成系6画面(012/015/018/021/024/031)+既存系16画面(001/002/003/010/011/013/014/016/017/019/020/022/023/030/040/090)
- 追加ファイル:
  - `lib/screens/create/` — 共通フォーム部品(`create_form_widgets.dart`: コーヒートーン暫定パレット・セクション・チップ・画像/日付ピッカー・スコアスライダー)+作成系6画面
  - `lib/screens/mock/` — `mock_scaffold.dart`(一覧/詳細系の共通骨格・瓶ビジュアル・スコアバッジ等)+ `dashboard_mock_screen.dart`(001 黒板風)/`log_mock_screens.dart`(002/003)/`bean_mock_screens.dart`(010カード/011)/`master_mock_screens.dart`(013〜023 の汎用リスト・詳細モック)/`brew_recipe_mock_screen.dart`(030 タイマー+Steps強調)/`stats_settings_mock_screens.dart`(040/090)
  - `lib/routing/screen_registry.dart`(画面ID→Widget解決テーブル。全22画面登録済み)
  - `.claude/launch.json`(`flutter run -d web-server --web-port=8123` のプレビュー起動設定)
- 変更ファイル: `lib/screens/debug/screen_gallery_screen.dart`(遷移先を screen_registry 経由に変更、「UIモック」バッジ表示)
- モック間遷移を一部実装済み: 010→011/012、各マスターリスト→詳細/新規、030→031、040→090
- **全画面ともデータ未接続**(保存/編集ボタンはSnackBar+`[Antigravity] MockSave`ログのみ)
- 検証済み: `flutter analyze`(新規issue 0件、既存84件のまま)、`flutter test`(17件全パス)、`flutter run -d web-server`+ブラウザで主要画面(001/002/003/010/013/020/030/040/090+作成系6画面)の表示・遷移確認、コンソールエラー/オーバーフロー無し
- `docs/改修マスタープラン.md` に2026-07-05付けの補足注記を更新(各タスクの状態はデータ接続完了まで⬜のまま)
- **未commit**。commit/pushの可否をユーザーに確認中。

## 2. 次回の着手点

1. **最優先**: 上記UIモック作業(`lib/screens/create/`・`lib/screens/mock/`・`lib/routing/screen_registry.dart`・`.claude/launch.json`・screen_gallery_screen.dart変更・マスタープラン注記)をユーザーに確認の上 commit/push する。
2. その後 Phase 1 — 画面構成・ナビ再編を継続(全画面のUIモックが揃ったので、各タスクは「モックに実データを接続する」作業になる)。

| ID | タスク | 依存 |
|---|---|---|
| T1-2a | 抽出030の画面骨組み(既存記録画面から抽出パートを分離) | T1-1c ✅ |
| T1-4a | 抽出履歴リスト002(実データ表示) | T1-1c ✅ |
| T1-3 | ダッシュボード001の骨組み | T1-1c ✅ |
| T1-5a | 汎用マスター画面テンプレート化 | T1-1c ✅(今回のUIモックが土台に使える) |

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
> 「\start を実行してください。まず未commitの作成画面UIモック(lib/screens/create/)をcommit/pushし、その後 T1-2a から着手します。」
