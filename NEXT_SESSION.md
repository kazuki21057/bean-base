# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-06-28

## 1. 当日やったこと（改修の準備セットアップ）
BeanBase 大規模改修の **土台** を整備した。コード改修（Phaseタスク）はまだ未着手。

- **全体設計書を作成**: `docs/改修マスタープラン.md`（進捗表付き）。今後の毎日のタスクはここから選ぶ。
- **日次改修ループのルールを CLAUDE.md に追記**: 終了条件4つ（①タスク完了 ②連続3回失敗 ③当日コスト>$0.5 ④当日ターン>=10）。
- **ガードレール実装**: `.claude/hooks/loop_guard.js`（Stop/UserPromptSubmitフック）。transcript からコスト（種別単価で重み付け）とターン数を算出し `.claude/loop_state.md` へ出力、超過時に停止指示を注入。`settings.local.json` に登録済み・発火確認済み。
- データ基盤の方針確定: **Firestore → Google Sheets に戻す**（`SheetsService` 再活用）。

## 2. 残課題 / 次回の着手点
- **Cycle 19 = Phase 0「データ基盤を Sheets に戻す」から開始**（マスタープラン §3 参照）。
  - T0-1 `SheetsService` の現状調査・再有効化方針
  - T0-2 `data_providers.dart` の読み取りを Firestore→Sheets に切替
  - T0-3 各CRUDの書込を Sheets に戻す
  - T0-4 画像保存先の方針決定（Drive or ローカル）
  - T0-5 `analyze`/`test`/`run` で接続確認
- 終了条件（Cycle 19）: Sheets 経由で一覧/登録/編集/削除が動き `flutter run` で接続成功。

## 3. 日次ループの回し方（毎回）
1. `\start`（git pull・当日タスク確認）
2. `docs/改修マスタープラン.md` から当日タスクを選ぶ
3. 実装 → 検証（`flutter analyze`→`test`→`run`）
4. 判定: OK→commit/push＋walkthrough＋進捗表更新 / NG→本書を更新して翌日へ
5. 失敗するたび `.claude/loop_failures.txt` を+1（成功で0リセット）
6. 終了条件に達したら新規着手せず、本書と進捗表を更新して `\end`

## 4. 開発再開時のプロンプト例
> 「\start を実行し、NEXT_SESSION.md と docs/改修マスタープラン.md を確認して、Cycle 19（Phase 0：データ基盤を Sheets に戻す）の T0-1 から進めてください。」

お疲れ様でした。また次回！
