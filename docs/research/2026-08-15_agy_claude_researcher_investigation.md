# agy経由`claude-sonnet-4-6`によるresearcher役パイロット調査(T5-A85)まとめ

作成: 2026-08-15、セカンドオピニオン依頼用。

## 背景・目的

BeanBase 2.0では、Claude Codeのサブエージェント作業の一部を、別課金バケットのGoogle Antigravity CLI(`agy`)経由でGemini/Claudeモデルへヘッドレス委譲してコスト・利用枠を節約する仕組み(`tools/antigravity_delegate.ps1`)を運用している。2026-08-14に「agy経由の`claude-sonnet-4-6`/`claude-opus-4-6-thinking`呼び出しは、Claude ProプランのAnthropic課金とは別勘定である」とユーザーが自身の課金情報から確認したため、これまでGeminiモデルのみに委譲していた役割(`researcher`/`implementer`/`architect`)をClaudeモデルでも試すパイロット計画を設計した(`docs/antigravity_delegation_design.md` §12)。

本ドキュメントは、その第一弾`T5-A85`(`researcher`役 × `claude-sonnet-4-6`パイロット3件)を実施した際に遭遇した**再現性の高い失敗パターン**の記録。

## 環境

- OS: Windows、PowerShell 5.1(agyの起動はGit Bash経由ではなく`ProcessStartInfo`で直接、または対話的にはPowerShellから直接)
- agyバージョン: 1.1.13
- 認証: Google(Antigravity)側のkeyring OAuth。Claude/GPTモデルはAntigravity内の別クォータグループ「Claude and GPT models」を消費し、Anthropic側のClaude Pro個人契約とは別勘定(2026-08-14にユーザーが確認済み)
- 呼び出し方式: `agy -p "<prompt>" --model claude-sonnet-4-6 --mode <plan|accept-edits> --add-dir <絶対パス> --output-format json --print-timeout <N>`(単発ヘッドレスプロンプト、非対話)

## 実施内容

### 事前準備: `/usage`ヘッドレス取得の可否確認

過去(教訓L158)「`agy -p "/usage"`はheadlessで恒常的に失敗する」という記録があったが、これはGit Bash(MSYS)のパス自動変換が`/usage`を絶対パスと誤認していたことが原因と2026-08-15に訂正済みだった。**PowerShell経由(Git Bash非経由)で直接叩くと正常に動作し**、Claude/GPTバケットの残量を含む正確なJSONが返ることを再確認した:

```json
{"status":"SUCCESS","response":"Gemini Models\tWeekly Limit Remaining\t96%...\nClaude and GPT models\tWeekly Limit Remaining\t99%\t...\nClaude and GPT models\tFive Hour Limit Remaining\t100%\t...\n", ...}
```

### スモーク検証3件(T5-A84、参考)

`claude-sonnet-4-6`で(1)ファイル読み取り(2)Web検索(3)`claude-opus-4-6-thinking`への`--effort`指定、を単発で確認。(1)(2)は成功、(3)は`--effort`が拒否されexit 1(想定どおり)。**いずれも単発の軽い応答で、複数ステップの探索は伴わなかった**。

### `researcher`役パイロット3件(T5-A85、本題)

`tools/antigravity_delegate.ps1 -Role researcher -Model claude-sonnet-4-6 -TaskFile <path>` で3件実行(ラッパーは`researcher`役を`--mode plan`で起動する設計)。各タスクは「Web調査→`docs/research/*.md`にレポートを作成し、末尾に出典表を置く」という、既存のGeminiモデルでは複数回成功実績のある定型プロンプト。

**3件とも同一の失敗パターンで完了(exit 18 = 出典検証失敗、原因はレポートファイル自体が存在しないため)**:

| # | テーマ | 所要 | `num_turns` | `response`の終わり方 | ファイル生成 |
|---|---|---|---|---|---|
| 1 | Dart `freezed`+`json_serializable`併用のベストプラクティス | 176.7s | 1 | 「...必要な情報が揃いました。これでレポートを作成します。」で終了 | なし |
| 2 | Google Play購入トークンのサーバー検証フロー | 255.6s | 1 | 実際に取得したURL一覧を列挙している途中で切れる | なし |
| 3 | `drift`パッケージのマイグレーション仕様の公式ドキュメント逐語確認 | 178.3s | 1 | 「...レポートを作成します。」で終了 | なし |

いずれも:
- agyプロセス自体は `exit_code:0` / `status:"SUCCESS"`(正常終了として扱われる)
- `response_head`を見ると、Web検索・複数ページのフェッチは**実際に複数回行われている**(URLを列挙するところまでは進む)
- しかし`num_turns`は常に**1**のまま
- 最終成果物(ファイル書き込み、または本文中へのレポート全文出力)には一度も到達しない
- `changed_file_count: 0`(ファイルシステムへの書き込みが一切発生していない)

## 追加診断(ユーザー指摘を受けて実施)

ユーザーから「`--mode plan`(読み取り専用モード)が原因で書き込めていないのでは、`accept-edits`にすれば書けるのでは」という指摘があり、以下2件を追加で検証した。

### 診断1: 同一タスクを`--mode accept-edits`で再実行

pilot 1と同一プロンプトを、ラッパーを介さず直接 `agy -p "..." --model claude-sonnet-4-6 --mode accept-edits --add-dir <絶対パス> --output-format json` で実行。

```json
{"status":"SUCCESS","response":"十分な情報が集まりました。ドキュメントを作成します。\n","duration_seconds":55.5,"num_turns":1, "usage":{"input_tokens":46230,"output_tokens":1497,"cache_read_tokens":110779,...}}
```

**`--mode accept-edits`でも同じパターンで失敗**(「ドキュメントを作成します。」で切れ、ファイルは生成されず)。→ **`--mode plan`が原因ではないと判明**。

### 診断2: 探索を伴わない最小限の書き込みタスク

「調査は不要、指定ファイルに1行だけ書き込め」という探索ゼロの最小タスクを`--mode accept-edits`・`claude-sonnet-4-6`で実行。

```json
{"status":"SUCCESS","response":"書き込み完了しました。\n\n[minimal_write_test.txt](...)に `agy claude-sonnet-4-6 write test OK` の1行を書き込みました。\n","duration_seconds":7.5,"num_turns":1,"usage":{"input_tokens":20242,"output_tokens":319,...}}
```

**成功**。実際にファイルが作成され、指定した内容と一致することを確認した(diskで直接確認済み)。

## 現時点の仮説(未確定)

- `--mode`(`plan`/`accept-edits`)の違いは今回の失敗の原因ではない(診断1で反証)。
- 探索(Web検索・複数ページ取得)を**伴わない**単純なタスクは成功する(診断2)。
- 探索を**伴う**タスクは、`num_turns:1`のまま「これから成果物を作ります」という宣言で応答が打ち切られ、実際の成果物(ファイル書き込み or 本文への出力)に到達しない。
- 推測: agyのヘッドレス単発プロンプト(`-p`)モードには、1ターンあたりの内部ステップ数(ツール呼び出し回数)に上限があり、探索に使い切ると最終アクションを実行する前に応答生成が打ち切られるのではないか。Geminiモデルでは同種のタスク(T5-A75/T5-A79)で正常に完走した実績があるため、**モデル側の挙動差**(Claude系はツール呼び出し1回あたりのステップ消費が大きい、または打ち切り基準が異なる)の可能性がある。
- ただし根本原因はagy側の内部実装(非公開)に依存するため、こちらからは確定できていない。

## クォータ消費実測

「Claude and GPT models」バケット(Anthropic Claude Pro個人契約とは別勘定):

| 時点 | 週次残 | 5時間残 |
|---|---|---|
| T5-A84開始前 | 99.45% | 100% |
| T5-A84(スモーク3件)後 | 97.38% | 93.77% |
| T5-A85(researcher3件+診断2件)後 | **79.20%** | **39.26%** |

**探索を伴う重いタスク1件あたりの消費は、軽いスモーク応答の一桁大きい**(5時間バケットが約6時間で93.77%→39.26%まで低下、うち大半は今回の5〜6回の重い呼び出しによるもの)。5時間バケットの残りが40%を切っており、このペースで同種の重いタスクを続けるとさらに数件で20%の安全domain(§12.9の中断基準)に到達しうる。

## 保留していること

- **T5-A85の結論**: `researcher`役のClaudeモデル化は「不採用」と暫定判定し、現行どおりGemini既定を維持する方向で設計書(`docs/antigravity_delegation_design.md` §7)・マスタープラン(`docs/改修マスタープラン.md`のT5-A85行)へ記録済み。
- **T5-A86(`implementer`役 × `claude-sonnet-4-6`パイロット3件)は未着手のまま待機中**。診断2(探索ゼロなら成功)を踏まえると、探索量の少ない小規模な`implementer`タスクなら成功する可能性は残っている。ただし対象タスク選定(トラックB本格化を避けつつ、設計判断を伴わない`lib/`または`test/`配下のタスクが見当たらない)という別の制約もあり、ユーザーの判断待ちで停止している。

## セカンドオピニオンで確認したい点

1. agyの`-p`(headless print)モードで`num_turns`が常に1に固定される挙動、および探索の多いタスクで最終アクション前に応答が打ち切られる現象について、既知の制約・ドキュメント・回避策(例: `--print-timeout`以外のステップ数上限パラメータの有無、プロンプトを分割して複数回`-p`を呼ぶ設計にすべきか等)はあるか。
2. Claude系モデル(`claude-sonnet-4-6`)固有の挙動なのか、Gemini系でも探索量を増やせば同様に発生するのか(こちらはGemini側では2026-08-14時点で3件×2ラウンド、探索を伴うタスクで完走実績があるため、モデル差の可能性が高いと見ているが未確証)。
3. `researcher`役のようにWeb調査→レポート作成という「探索してから書く」性質のタスクを、この制約下でagy×Claudeへ委譲する場合の設計(タスクを細分化する/`--mode`以外の別フラグを使う等)に心当たりがあれば。
