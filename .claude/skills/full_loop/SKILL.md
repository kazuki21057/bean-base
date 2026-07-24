---
name: full_loop
description: Use when the user asks to run one full daily-loop iteration autonomously end-to-end — pick the next task, implement it, verify, deploy to production, confirm in production, and close the session — without pausing for step-by-step approval. Triggered by instructions like "依存がなく優先度が高いものから着手して。コストを気にせず一括で終わらせて。デプロイして本番確認してから/endして" or "フルで一気通貫でやって".
---

# full_loop — 選定〜実装〜デプロイ〜本番確認〜/end を一括実行する

`/start`(状況確認・候補提示のみ)と`/end`(締めの手順のみ)を、ユーザーの明示的な一括実行指示のもとで1回の指示で最後まで繋げて実行する「自動フルループ」モード。BeanBase 2.0 の「日次改修ループ」(`CLAUDE.md` §日次改修ループ運用ルール)の1ループ分を、着手確認を挟まずに完走させる。

## いつ使うか

ユーザーが以下のような**一括実行の明示的指示**をした場合に使う:
- 「依存がなく優先度が高いものから着手して」
- 「コストを気にせずひとつのタスクを一括で終わらせて」
- 「終わったらデプロイして本番環境確認してから/endして」

これらの指示が無い通常の`/start`実行では、このスキルを使わず`start`スキル(候補提示→ユーザーの着手承認待ち)を使うこと。**着手対象タスクの選定自体をユーザー承認なしで進めてよい、というのがこのスキル固有の許可**であり、それ以外の安全装置(コスト/ターン上限、本番データ書き込みの確認等)は通常運用と同じく効かせる。

## 手順

1. **状況確認**(`start`スキルの手順1〜4と同じ): `git pull`→コンフリクトがあれば停止して報告。`.claude/loop_state.md`・`.claude/loop_failures.txt`でしきい値(コスト$24超/ターン30到達/連続失敗3回)超過を確認→超過していれば新規着手せずユーザーに報告して止まる。`NEXT_SESSION.md`の「次回の着手点」と`docs/改修マスタープラン.md` §3 のタスク表を読む。
2. **タスク選定**: 「依存が満たされた最上位のタスク」を1つ選ぶ。`NEXT_SESSION.md`の推奨と一致すればそれを採用。複数の無依存タスクがあればタスク表内で上にあるものを優先し、選定理由を一言でユーザーに共有してから実装に入る(この選定に限り承認を待たない)。
3. **実装**: `CLAUDE.md`の規約(全マスタータブへの一律適用、`[Antigravity]`ログ、外部データのID `.toString()`化、モデル追加時のシート列プロビジョニング漏れ対策など)に従う。統計解析・予測機能に触れる場合は同ファイル§統計解析・予測機能の実装ルールを厳守する。
4. **検証**(`rules/verification.md`準拠): `flutter analyze`(新規issue無し)→`flutter test`(全パス)→`flutter build web`成功。可能なら`build/web`をローカル配信し`claude-in-chrome`で実データに対しブラウザ確認する。
5. **デプロイ**(`docs/deploy.md`手順): `firebase deploy --only hosting`。GASスキーマの非破壊的変更(列追加等、`gas/Code.gs`の`EXISTING_SHEET_EXTRA_COLUMNS`経由)は続行してよいが、**本番Sheets/Driveへの実データ登録・削除を伴う場合は実行前にユーザーへ一度確認する**(既存運用ルールを一括実行モードでも省略しない)。
6. **本番確認**: デプロイした`build/web`と同一の成果物をローカル配信(未使用ポート、Service Workerキャッシュ回避)し、本番GAS実データに対して新機能を`claude-in-chrome`で確認する。拡張が本番ドメインを直接ブロックする制約の回避策(`docs/deploy.md`記載)。
7. **`/end`の手順をそのまま実行**: (a) `NEXT_SESSION.md`更新(今回の実装内容・検証結果・本番確認結果・次回の着手点) → (b) `docs/改修マスタープラン.md`の進捗表更新(⬜→✅) → (c) 新しい教訓があれば`rules/verification.md`に追記 → (d) `docs/`配下のCycle連番確認 → (e) commit/push。

## 注意

- 終了条件(連続失敗3回・コスト$24超・ターン30到達)に達した場合は、実装途中でも直ちに手順7(引き継ぎ記載を優先した`/end`手順)に切り替えて停止する。新規タスクには着手しない。
- 本番への破壊的操作(データ削除等)は、一括実行の指示があってもその都度リスクを一言説明してから実行する。
- push は共有リモートへの反映のため、ユーザーが明示的に「確認不要、自動でpushして」等と言っていない限り、実行前に一度状況を共有する。
