# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-03（Cycle 19 完了 → Phase 1 へ）

## 1. 当日やったこと（2026-07-03）

**Cycle 19 完了**: Google Sheets バックエンドへの完全移行が完了。

- スマホセッション（T0-4b）の内容をマージ: `ImageService` を Firebase Storage → Google Drive (GAS経由) に切替
- GAS スクリプト更新・新デプロイ URL を `sheets_service.dart` に反映
- `flutter pub get` / `flutter run -d chrome` で疎通確認 **→ 成功**
- ループガードの上限を3倍に拡大（コスト $0.5→$1.5、ターン 10→30）

## 2. 次回の着手点

**Phase 1 — 画面構成・ナビ再編（Cycle 20）** から開始。

| ID | タスク |
|---|---|
| T1-1 | 14画面のルーティング骨組み（`NavigatorKey`/`navIndexProvider` 再編） |
| T1-2 | **抽出(030)と評価(031)を別画面に分離** |
| T1-3 | ダッシュボード001の骨組み |

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
> 「\start を実行し、Phase 1（Cycle 20）を開始してください。T1-1 から着手します。」
