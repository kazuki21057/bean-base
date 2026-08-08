---
name: start
description: This skill should be used when the user runs "\start" or "/start", or asks to begin/resume a daily development loop session for this project. Pulls the latest changes and surfaces today's candidate task from the master plan and session handover notes.
---

# start — 日次ループのセッション開始

BeanBase 2.0 の「日次改修ループ」(`CLAUDE.md` §日次改修ループ運用ルール) における、1ループの起点。実装には入らず、状況確認とタスク候補の提示までを行う。

## 手順

1. `git pull` を実行する。コンフリクトが出た場合は実装に進まず、内容をユーザーに報告して指示を仰ぐ。
2. `.claude/loop_state.md` と `.claude/loop_failures.txt` を読み、本ループのコスト・ターン数・連続失敗回数を確認する(2026-07-25〜、しきい値の集計単位は当日累計ではなく直近の`/start`・`/full_loop`以降の1ループ単位)。しきい値(コスト$24超・ターン30到達・連続失敗3回)にすでに達している場合は、新規タスクに着手せず、その旨をユーザーに伝えて指示を仰ぐ。
3. `NEXT_SESSION.md` の「次回の着手点」節を読み、前回セッションの引き継ぎ事項(未解決の注意点、推奨タスクなど)を把握する。
4. `docs/改修マスタープラン.md` §3(フェーズ詳細＆タスク分解)は`Read`でファイル全体を読まず、`grep -n "| ⬜ |" docs/改修マスタープラン.md`で未完了行だけを抽出し、「依存が満たされた最上位のタスク」(依存タスクがすべて✅で、かつタスク表内で最も上にあるもの)を特定する。依存元が完了しているかの確認が必要な場合は追加で`grep -n "完了済み" docs/改修マスタープラン.md`を実行する(**完了行は本体から `docs/archive/マスタープラン_完了タスク.md` へ分離済みなので、表に残っているのは未完了タスクだけ**。過去の実装内容が必要なときだけアーカイブをタスクIDで grep する)。
5. 上記を踏まえて、当日の候補タスクを1つ(NEXT_SESSION.mdの推奨と一致すればそれを優先、食い違いがあれば理由とともに両論併記)提示する。タスクのID・内容・依存・サイズを含めて簡潔に示し、着手してよいか確認する。**この確認と同時に`PushNotification`でも通知する**(`CLAUDE.md`§日次改修ループ運用ルール、2026-07-25〜)。

## 注意

- **読むファイルは `CLAUDE.md`§毎ループの読み取り最小セットに従う。** アーカイブ類(`rules/lessons_archive.md`・`docs/archive/*`)は全読みせず、必要時に grep で該当箇所だけ読む。
- このスキル自体はタスクの実装を行わない。ユーザーの承認(または具体的な着手指示)を得てから実装に入る。
- **承認後の実装・検証は担当サブエージェントに委譲する(2026-08-05〜)**: 設計・原因究明=`architect`(opus)、実装=`implementer`(sonnet)、検証=`verifier`(sonnet)。委譲の判断基準・プロンプトに書くべき内容は`/full_loop`スキル§サブエージェントへの委譲が正本(`CLAUDE.md`§日次改修ループ運用ルールの「モデル分担ルール」にも要約あり)。
- `git pull` でユーザーの未コミット変更と衝突するリスクがある場合は、`git status` で作業ツリーの状態を先に確認する。
- ユーザーの反応を待つ場面(手順5の着手確認、しきい値超過報告など)は必ず`PushNotification`も併用する。
