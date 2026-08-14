---
name: verify
description: Use when the user runs "/verify", or when any task's verification phase needs to delegate to the verifier subagent using the standard Chrome-first / emulator-2-retry-limit / PASS-FAIL-table flow. Wraps the same delegation prompt template already defined in full_loop's step 4 so it can be invoked standalone.
---

# verify — verifierサブエージェントへの定型委譲と報告整形

## 目的・役割分担

**検証を実際に実行するのは`.claude/agents/verifier.md`(`verifier`サブエージェント)であり、このスキル自身は検証を行わない。** このスキルは「検証をどう呼び出すか」「結果をどう報告するか」の**手順書**であり、以下2点をコード化する:

1. `verifier`への委譲プロンプトの型(`.claude/skills/full_loop/SKILL.md`手順4のテンプレートと同一のものを再利用する。ここで新しいテンプレートは作らない)
2. `verifier`の報告を**PASS/FAIL表形式**へ整形して出力するフォーマット

`/verify`単体で呼ばれても、`full_loop`/`night_loop`の検証フェーズから呼ばれても、同じ手順・同じテンプレートを使う。検証コマンドの中身(`flutter analyze`/`flutter test`/`flutter build web`の実行方法、`tools/verify.ps1`の読み方等)は`rules/verification.md`§必須検証フローが正本であり、このスキルには書き写さない(verifier自身がそれをReadする)。

## 手順

1. **検証対象の確認**: このループ/タスクで変更したファイル一覧と、「何が確認できれば今回の変更が効いたと言えるか」の判定条件を確認する(実装フェーズの報告、または直前の`git diff --stat`から拾う)。この2つが揃っていないと委譲プロンプトが埋められないため、無ければ先に確認する。
2. **`verifier`サブエージェントへ委譲する**: `.claude/skills/full_loop/SKILL.md`手順4に定義された委譲プロンプトのテンプレートをそのまま使い、`<ファイル一覧>`と`<条件>`を手順1の内容で埋めて渡す(テンプレート文言自体はここでは複製しない。参照先を都度読むこと)。verifierは`rules/verification.md`の§必須検証フローと§既知の失敗しやすい検証経路(下記参照)に従って自律的に検証する。
   - 委譲は同期実行(`run_in_background: false`)で行い、完了を待ってから次に進む。
3. **報告をPASS/FAIL表へ整形する**: verifierからの日本語報告を受け取り、以下の3列マークダウン表に整形して出力する。

   | 項目 | 判定 | 補足 |
   |---|---|---|
   | analyze | PASS/FAIL/未実施 | 件数・baseline差分など |
   | test | PASS/FAIL/未実施 | 通過数/失敗数 |
   | test_coverage_delta | PASS/FAIL/未実施 | 参考値(トップレベル判定に含まれない) |
   | build_apk_release | PASS/FAIL/未実施 | skipped時はnoteを引用 |
   | build_web_release | PASS/FAIL/未実施 | 失敗時はsummary要点 |
   | golden | PASS/FAIL/未実施 | diff_count |
   | codegen_clean | PASS/FAIL/未実施 | timeout時はreason |
   | secret_scan | PASS/FAIL/未実施 | 検出内容があれば要点 |
   | acceptance | PASS/FAIL/未実施 | タスクIDと、失敗した個別チェック名。`acceptance_missing`はFAIL |
   | integration_test(エミュレータ) | PASS/FAIL/未実施 | 未実施ならその理由 |
   | ブラウザ確認 | PASS/FAIL/未実施 | 確認した画面・操作 |

   - `verifier`が「未実施(理由)」と報告した項目は**FAILではなく「未実施」**として扱う(`tools/verify.ps1`の`skipped:true`項目、および環境未整備によるエミュレータ未実施を含む)。
   - 表の下に、FAIL/未実施だった項目の要点(件数・エラー種別・該当ファイル:行、ログの生出力は貼らない)を箇条書きで添える。
   - 表全体が全項目PASS(未実施を除く)であれば「今回の変更について検証完了」と結論を一言で添える。1件でもFAILがあれば、その事実だけを述べ原因の推定はしない(verifierと同じく判断は委譲元が行う)。

## 参照(車輪の再発明をしない)

- 委譲プロンプトのテンプレート本体: `.claude/skills/full_loop/SKILL.md` 手順4
- 検証コマンド・8項目JSONスキーマ・ログの読み方: `rules/verification.md` §必須検証フロー
- **既知の失敗しやすい検証経路**(エミュレータのリトライ上限2回・ブラウザ優先・GASエンドポイントへの直接curl禁止): `rules/verification.md` §既知の失敗しやすい検証経路
- verifierの絶対規則(コード修正禁止・デプロイ禁止・本番データ書き換え禁止・原因推定禁止等): `.claude/agents/verifier.md`

## 注意

- このスキル自身は`flutter analyze`/`flutter test`/`flutter build`を直接実行しない。実行するのは委譲先の`verifier`。
- NGだった場合の原因判断・implementer/architectへの差し戻しは、このスキルの範囲外(呼び出し元の`full_loop`等が行う)。
