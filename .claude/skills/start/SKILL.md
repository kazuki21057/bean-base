---
name: start
description: This skill should be used when the user runs "\start" or "/start", or asks to begin/resume a daily development loop session for this project. Pulls the latest changes and surfaces today's candidate task from the master plan and session handover notes.
---

# start — 日次ループのセッション開始

BeanBase 2.0 の「日次改修ループ」(`CLAUDE.md` §日次改修ループ運用ルール) における、1ループの起点。実装には入らず、状況確認とタスク候補の提示までを行う。

## 手順

1. `git pull` を実行する。コンフリクトが出た場合は実装に進まず、内容をユーザーに報告して指示を仰ぐ。
2. `.claude/loop_state.md` と `.claude/loop_failures.txt` を読み、当日のコスト・ターン数・連続失敗回数を確認する。しきい値(コスト$12超・ターン30到達・連続失敗3回)にすでに達している場合は、新規タスクに着手せず、その旨をユーザーに伝えて指示を仰ぐ。
3. `NEXT_SESSION.md` の「次回の着手点」節を読み、前回セッションの引き継ぎ事項(未解決の注意点、推奨タスクなど)を把握する。
4. `docs/改修マスタープラン.md` §3(フェーズ詳細＆タスク分解)の該当フェーズのタスク表を読み、「依存が満たされた最上位のタスク」(依存タスクがすべて✅で、かつタスク表内で最も上にあるもの)を特定する。
5. 上記を踏まえて、当日の候補タスクを1つ(NEXT_SESSION.mdの推奨と一致すればそれを優先、食い違いがあれば理由とともに両論併記)提示する。タスクのID・内容・依存・サイズを含めて簡潔に示し、着手してよいか確認する。

## 注意

- このスキル自体はタスクの実装を行わない。ユーザーの承認(または具体的な着手指示)を得てから実装に入る。
- `git pull` でユーザーの未コミット変更と衝突するリスクがある場合は、`git status` で作業ツリーの状態を先に確認する。
