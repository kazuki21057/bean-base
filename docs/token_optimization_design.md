# 日次ループのトークン消費削減 設計書

作成: 2026-08-02(Sonnet 5 による実測ベース)
対象: `/full_loop` 1ループあたりのトークン消費(=コスト)の削減
正本: 本書。実装タスクは `docs/改修マスタープラン.md` §3 の T3-73 グループ。

---

## 1. 計測方法

`C:\Users\winni\.claude\projects\C--src-Claude-bean-base\*.jsonl`(セッションのtranscript)を
`message.id` で重複排除しながら集計した。`loop_guard.js` と違い**1リクエスト単位**で
コンテキスト長・キャッシュ読み書き・出力トークンを分解できる。

集計スクリプトは本タスクで `tools/analyze_transcript.js` としてリポジトリに残す(T3-73a)。

---

## 2. 実測結果(直近3ループ)

| セッション | 内容 | リクエスト数 | ツール呼出数 | 平均ctx | 最大ctx | cacheR | cacheW | out | 概算コスト |
|---|---|---|---|---|---|---|---|---|---|
| `4106fcd1` | T3-53c(045画面新設) | 143 | 174 | **231k** | 337k | 31.9M | 1.15M | 94k | **$15.3** |
| `8f94bf11` | T3-69(store→storeId移行) | 176 | 226 | **207k** | 355k | 35.5M | 0.89M | 93k | **$15.4** |
| `6c86309a` | T3-53d(ドキュメント追記のみ) | 110 | 113 | **119k** | 193k | 12.7M | 0.41M | 35k | **$5.9** |

単価: cache read $0.30/M、cache write $3.75/M、output $15/M(Sonnet、200k以下の通常帯)。

### コスト構造(最重要)

```
コスト ≒ Σ(各リクエストのコンテキスト長) × $0.30/M  +  cacheW + output
       ≒ リクエスト数 × 平均コンテキスト長 × $0.30/M + α
```

**cacheR が全体の 60〜65% を占める単一最大要因**($15.3のうち$9.6)。
そして cacheR は「リクエスト数 × 平均コンテキスト長」でしかない。
つまり削るべきは **①リクエスト数** と **②コンテキスト長** の2つだけであり、
「ファイルを読む量」自体は(それがコンテキストに居座り続ける限り)②に効く形でしか効かない。

### 決定的な事実

- **全セッションの初回リクエストが 54,660 トークン**。作業を1つもしていない時点のベースライン。
- 高コストな2ループは **平均ctxが200kを超えている**。Sonnet は入力200k超で長コンテキスト料金帯
  (入力・キャッシュ読みとも**約2倍**)に入る。最大ctxが337k/355kなので、
  ループ後半のリクエストは**全部2倍単価で払っている**。安いループ(`6c86309a`)は最大193kで
  この帯に入っていない。**コスト差2.6倍の主因はここ**。
- **143リクエスト中125が「ツール呼び出し1個だけ」**。並列バッチがほぼ使われていない。

---

## 3. Findings(削減余地)

### F1: コンテキストが200kの料金境界を越えている 【最大】
平均207〜231k、最大337k。境界超過後は単価2倍かつ自動コンパクション(コンテキスト全体の
読み直し+書き直し)も発生する。**「1ループのコンテキストを常に200k未満に保つ」**ことが
最も費用対効果が高い。

### F2: 直列1ツール実行(125/143リクエスト)
独立した読み取りを1メッセージにまとめれば、その分だけリクエスト数(=cacheRの係数)が減る。
実測では冒頭の状況確認だけで `Read×3 + Bash×2` を5リクエストに分けていた。

### F3: 同一ファイルの重複Read
`NEXT_SESSION.md` を1セッションで4回、`bean_create_screen.dart` を9回Readしていた。
Readのたびに**全文がコンテキストに追加で積まれる**(上書きではない)。
9回×24k文字 = 216k文字 ≒ 80kトークンが同一ファイルのために消費された計算。

### F4: 大きなファイルの全文Read
1回で 30k / 25k / 24k / 22k / 22k / 20k 文字のReadが並ぶ。
上位6件だけで約143k文字 ≒ 55kトークン。しかも以後の全リクエストで再課金される。

### F5: 検証コマンドの出力が長い
- `flutter test 2>&1 | tail -150` → 13k文字
- `flutter analyze 2>&1 | tail -100` → 7k文字(既存47件のissueを毎回全部読んでいる)
これらは1ループ中に複数回実行される。

### F6: 新規ファイルをWriteした後にEdit連打+全文Read
T3-53cでは `exploration_status_screen.dart` に対して
Write(36k文字)→ Edit×8 → Read×2(30k文字) で計約100k文字 ≒ 38kトークン。
Editは old_string/new_string の両方が出力トークンとして課金され、かつコンテキストにも残る。

### F7: ベースライン54.6kの内訳に不要物がある
- `firebase@firebase` プラグイン(グローバル有効): スキル12個 + MCPツール約50個。
  本プロジェクトのFirestoreは**legacy・実行時未使用**(CLAUDE.md明記)なので不要。
- `playwright` MCP(ツール28個): `claude-in-chrome` と役割が重複。実運用では
  `claude-in-chrome` しか使っていない(直近3セッションでplaywright呼び出し0件)。
- `CLAUDE.md` 16.8KB ≒ 6kトークン。毎リクエスト課金される。

### F8: ブラウザ検証のスクリーンショット
1セッションあたり12〜16枚。1枚あたり約1.5kトークンで、以後コンテキストに残り続ける
(16枚 ≒ 24kトークン)。`get_page_text` / `find` / `read_console_messages(pattern指定)` は
桁違いに安い。

---

## 4. 施策と期待効果

| # | 施策 | 効く場所 | 期待削減 |
|---|---|---|---|
| S1 | ループを「実装」「検証+デプロイ+/end」の2セッションに分割 | F1 | 平均ctxを230k→130k前後に。**$15→$8程度** |
| S2 | 独立ツール呼び出しの並列バッチ | F2 | リクエスト数 -15〜25% |
| S3 | 再Read禁止・部分Read(offset/limit・Grep)の徹底 | F3/F4 | 平均ctx -30〜50k |
| S4 | 検証コマンドを短出力形に統一 | F5 | -20k文字/ループ |
| S5 | 大きな新規ファイルは分割Write、確認はanalyze/testで代替 | F6 | 出力・ctx 各 -20k |
| S6 | firebaseプラグイン・playwright MCPの無効化、CLAUDE.mdの圧縮 | F7 | ベースライン 54.6k→45k前後、全リクエストに効く |
| S7 | スクリーンショットは最終確認1〜2枚に限定、他はテキスト系ツール | F8 | -15〜20kトークン |

**合計目標: 1ループ $15 → $7〜9(約40〜50%減)。**

---

## 5. 実装タスク分解(Sonnet 5 が設計判断なしで実施できる粒度)

### T3-73a: 計測スクリプトをリポジトリに追加
- **新規**: `tools/analyze_transcript.js`(Node、依存なし)
- **仕様**: 引数に `.jsonl` パスを取り、`message.id` で重複排除して以下を標準出力:
  `uniqueRequests` / `totalToolCalls` / `toolsPerRequest ヒストグラム` / `avgCtx` / `maxCtx` /
  `cacheR` / `cacheW` / `out` / `概算コスト` / ツール別の結果文字数 / 上位25件の大きなツール結果。
- **単価定数**: `CACHE_READ=0.30e-6`, `CACHE_WRITE=3.75e-6`, `OUTPUT=15e-6`(200k超は2倍として
  `ctx > 200000` のリクエストは単価2倍で計上する)。
- **終了条件**: `node tools/analyze_transcript.js <直近のjsonl>` が上表と同じ形式で出力する。
- **検証**: `node` 実行のみ。`flutter analyze`/`test` には影響しない。

### T3-73b: `rules/verification.md` の検証コマンドを短出力形に差し替え
- **変更**: §必須検証フロー の1・2を以下のコマンド形に置き換え、理由(トークン削減)を1行添える。
  - 静的解析: `flutter analyze 2>&1 | Select-String -Pattern "issues found|error •" | Select-Object -Last 5`
    (PowerShell)/ Bash なら `flutter analyze 2>&1 | grep -E "issues found|error •" | tail -5`
  - テスト: `flutter test 2>&1 | tail -15`(**失敗時のみ** `tail -150` で再実行して詳細を見る)
- **追記**: 「既存issue件数のベースラインは `.claude/analyze_baseline.txt` に数値のみ保存し、
  次回はその数値との差分だけを見る」ルール。ファイルは1行(例: `47`)。
- **終了条件**: verification.md に上記が反映され、`.claude/analyze_baseline.txt` が現在値で作成済み。

### T3-73c: `CLAUDE.md` に「トークン運用規約」節を追加(※本設計と同時に実施済みなら確認のみ)
- **追加位置**: §日次改修ループ運用ルール の直後。
- **内容**(箇条書き5項目、これ以上増やさない):
  1. 独立したツール呼び出しは1メッセージにまとめる。
  2. 一度Readしたファイルを再Readしない(Edit後の確認Readは禁止。Edit/Writeは失敗すればエラーになる)。
  3. 300行超のファイルは全文Readせず `Grep` か `Read(offset/limit)` で必要箇所だけ読む。
  4. 検証コマンドは短出力形(`rules/verification.md`)を使う。失敗時のみ詳細を取り直す。
  5. ブラウザ確認は `get_page_text`/`find`/`read_console_messages(pattern)` を優先し、
     スクリーンショットは最終確認の1〜2枚に限る。
- **終了条件**: CLAUDE.md に上記節が存在する。

### T3-73d: `full_loop` / `start` スキルにセッション分割(S1)を組み込む
- **変更**: `.claude/skills/full_loop/SKILL.md`
- **追加する手順**: 手順4(検証)に入る前に **`.claude/loop_state.md` の当ループcost が $7 を超えている、
  または実装で触れたファイル数が5を超えている場合**は、
  (a) 実装内容を `NEXT_SESSION.md` の「3. 直近の作業ログ」に**検証待ち**として書き、
  (b) commitまで済ませ(pushはしない)、
  (c) ユーザーに「実装完了。検証・デプロイは新しいセッション(`/clear` 後に `/full_loop 検証のみ`)で
      続行してください」と報告し `PushNotification` も送って**そのセッションを終える**。
- **追加する手順**: 手順1(状況確認)で `NEXT_SESSION.md` に「検証待ち」の記載があれば、
  タスク選定をスキップして検証・デプロイ・`/end` から再開する。
- **理由をSKILL.mdに1行記載**: コンテキスト200k超で単価が2倍になるため。
- **終了条件**: SKILL.md に上記2分岐が明記されている。

### T3-73e: firebaseプラグイン・playwright MCP の無効化
- **手順**:
  1. `claude mcp list` で playwright がどのスコープ(user/project/local)にあるか確認。
  2. project スコープなら `.claude/settings.json` の `disabledMcpjsonServers` に追加。
     user スコープなら**ユーザーに確認してから** `claude mcp remove playwright -s user` を提案する
     (他プロジェクトに影響するため**勝手に消さない**)。
  3. firebaseプラグインは `C:\Users\winni\.claude\settings.json` の `enabledPlugins` にあるため
     グローバル。**ユーザー確認必須**。まず `.claude/settings.json`(プロジェクト)に
     `"enabledPlugins": {"firebase@firebase": false}` を書いて起動し直し、効くかを確認する。
     効かない場合はユーザーに判断を仰ぐ。
- **終了条件**: 新規セッションの初回リクエストのコンテキストが 54,660 から**有意に減っている**ことを
  `tools/analyze_transcript.js` で確認(目標 50k未満)。効果が無ければ変更を戻して結果を記録する。
- **注意**: これは設定変更なので、**必ず1つずつ変えて1回ずつ計測**する。まとめて変えない。

### T3-73f: `CLAUDE.md` の圧縮
- **方針**: 毎ループ必要な規約だけ残し、「統計解析・予測機能の実装ルール」節(約2.5KB)は
  `statistics_feature_design.md` へのポインタ3行に縮める(該当タスク着手時のみ読む運用は
  §毎ループの読み取り最小セット と整合)。同様に「Response Language & Documentation Conventions」の
  実例列挙(2026-07-29の発見事例など)を `rules/lessons_archive.md` へ移し、規約本文だけ残す。
- **制約**: **規約の内容を削ってはいけない**。移動とポインタ化のみ。移動先は必ず本文中に明記する。
- **終了条件**: `CLAUDE.md` が 16.8KB → **10KB以下**。移動した内容が移動先に全文残っている。
- **検証**: 移動前後で `git diff` を確認し、削除された行がすべて移動先に存在することを目視確認。

### T3-73g: 効果測定と記録
- 上記適用後の最初の `/full_loop` 完了時に `tools/analyze_transcript.js` を実行し、
  §2の表と同じ形式で `docs/token_optimization_design.md` §7 に1行追記する。
- 目標($7〜9)に届かない場合は、未達の原因(どのFindingが残っているか)を1〜3行で記録する。
- **終了条件**: §7 に実測値が1行以上記録されている。

---

## 6. 実施順序

`T3-73a`(計測基盤)→ `T3-73b`・`T3-73c`(規約、軽量)→ `T3-73d`(分割、効果大)→
`T3-73e`(設定、要ユーザー確認)→ `T3-73f`(圧縮)→ `T3-73g`(測定)。

`T3-73a`〜`T3-73d` は互いに独立なので同一ループでまとめて実施してよい(いずれもドキュメント/
スクリプトのみでFlutterコードに触れないため、`flutter analyze`/`test` の実行は最後に1回でよい)。

---

## 7. 効果測定ログ

| 日付 | 対象ループ | リクエスト数 | 平均ctx | 最大ctx | コスト | 備考 |
|---|---|---|---|---|---|---|
| 2026-08-01 | T3-53c(適用前) | 143 | 231k | 337k | $15.3 | ベースライン |
| 2026-08-01 | T3-53d(適用前) | 110 | 119k | 193k | $5.9 | ドキュメントのみの軽いループ |
| 2026-08-05 | T3-73e(playwright MCP除去後、新規セッション初回リクエスト) | - | - | - | - | 初回ctx 54,660→**52,702**(-3.6%)。目標50k未満は未達。次候補はfirebaseプラグイン無効化(グローバル設定・要ユーザー確認) |
| 2026-08-05 | T3-73e(firebaseプラグイン プロジェクトスコープ無効化後、新規セッション初回リクエスト) | - | - | - | - | 初回ctx 52,702→**52,715**(実質変化なし、誤差範囲)。**効果ゼロと判定し`.claude/settings.json`の`enabledPlugins`変更を撤回**。原因: このセッションのdeferred tools一覧に`mcp__plugin_firebase_firebase__*`が約30件残っており、プロジェクトスコープの`enabledPlugins: false`はこの環境では効いていないと判明。firebaseプラグイン無効化はグローバル設定(`C:\Users\winni\.claude\settings.json`)側でのみ試せる余地が残るが、他プロジェクトへの影響があるため今回は見送り、ユーザー判断待ちとする |
| 2026-08-05 | T3-73g(T3-73d〜f適用後、最初の`/full_loop`=本ループ自体、ドキュメント/設定のみで実装なし) | 23 | 77,659 | 96,379 | $1.1 | 目標($7〜9)との比較不可(本ループはFlutterコード変更が無い軽量ループのため)。`totalToolCalls`計測値がツール呼び出し実数と乖離している疑いがあり(本ループ実測では過少)、この指標自体は参考値扱いとする。実コード変更を伴う次回以降の通常ループでの再測定が必要 |
| 2026-08-09 | T5-A27(`/full_loop`、architectへ委譲する⚠️タスク、ドキュメントのみで実装なし) | - | - | - | loop_state.md記載値$0.0000(架空、T5-A28の既知の限界により本ループ中のサブエージェント消費が未反映) | サブエージェント`architect`1体で150,509トークン消費(ツール呼び出し40回、所要約18分)。loop_guardは`UserPromptSubmit`時のみ更新されるためこの消費は次回プロンプト送信まで`loop_state.md`に反映されない(T5-A28で特定済みの制約、原因調査自体は別ループでarchitectへ委譲予定) |
| 2026-08-09 | T5-A28(`/full_loop`、architectへ委譲する⚠️タスク本体、ドキュメントのみで実装なし) | - | - | - | loop_state.md記載値$0.0000(本ループはこのプロンプト1回のみでUserPromptSubmitが1度しか発火していないため。§9-Aの結論どおりサブエージェント分は非計上) | サブエージェント`architect`1体で85,852トークン消費(ツール呼び出し36回、所要約8.7分)。T5-A27より軽量なのはコード探索・実測作業がT5-A27で既に済んでいた分、調査対象が絞られていたため |
| | | | | | | |

## 8. Proプラン使用率ログ(ユーザー申告ベース、2026-08-09追加)

ユーザーがセッション開始時・終了時にClaude.ai上で見える「使用量(%)」を申告し、ここに蓄積する。目的は`loop_guard`のコスト実測($)とプラン使用率(%)の対応関係を積み上げ、%からコスト・コストから%への換算精度を上げること。**申告が無いループは記録しない**(推測値を書かない)。

| 日付 | セッション種別 | 開始% | 終了% | 差分% | loop_guardコスト | ターン数 | 備考 |
|---|---|---|---|---|---|---|---|
| 2026-08-09 | `/full_loop`(T5-A4検証〜) | 62% | 81% | 19pt | $4.188(セッション中盤の一時点、末尾の正確な累計は未取得) | 2(参考値、同一セッション内で複数`/full_loop`相当を実行したためloop_guardのループ識別子が跨いでいる可能性あり) | サブエージェント4体(verifier×2, implementer×1, ui_verifier×1)で合計約20万トークン消費。`/usage`実測: sonnet 100%・cache hit 96%。cache hit率が高いため実消費トークン数の割に%消費・$コストは相対的に抑えられている可能性がある |
| 2026-08-09 | `/full_loop`(T5-A27、`/clear`後の新規セッション) | 82% | 100%(オーバー、超過課金に移行) | 18pt+ | $3.017(ユーザー申告時点のloop_state.md記載値。ターン4/40) | 4 | **【T5-A28で訂正】この行の「150,509トークン」は誤り**——親transcriptの`toolUseResult.usage`(最終API呼び出し1回分のみ)を全消費と誤読していた。サブエージェントのtranscript実測では**6,369,414トークン / $6.82**(約42倍)。以下の記述は訂正前の値に基づく。`architect`委譲1回(150,509トークン)のみで82%→100%超過。`/usage`内訳: **opus 65%・sonnet 35%・cache hit 96%**——上限到達の主因は`architect`のOpus消費と判断できる。**loop_guardの異常も観測**: このタイミングで「境界未検出のフォールバック」表示となり夜間モードのしきい値($8/40/2)が誤適用されていた(本来は有人モード$24/30/3)。**原因は§9-Cで特定済み**(プロンプトが`82% /full_loop`と行頭以外にコマンドを書いた形だったためスラッシュコマンドが展開されず、transcriptに`<command-name>`マーカーが残らなかった) |

---

## 9. loop_guard のコスト計測が実態と乖離する問題(T5-A28、2026-08-09 architect調査)

調査環境: Claude Code 2.1.225 / Windows。対象は`.claude/hooks/loop_guard.js`と`.claude/settings.json`のhooks設定。

### 9-0. 結論(先に要点)

当初の想定「`UserPromptSubmit`でしか発火しないというフック起動タイミングの制約」は**問題の一部でしかない**。より重大な欠陥が別にあり、**フックがいつ発火してもサブエージェントのコストは1円も計上されていなかった**。実測で、サブエージェント4体を使ったループでは`loop_guard`が見えていたのは総コストの**33.2%**($6.91 / 実額$20.81)だった。3つの独立した欠陥に分解でき、**いずれも修正可能**(「対応不可」ではない)。

### 9-A. 欠陥A: サブエージェントの消費が集計対象外(影響最大)

`loop_guard.js`はフックが渡す`transcript_path`(=親セッションのJSONL)1本だけを読み、`message.usage`を合算する(`analyze()`、`loop_guard.js:165-222`)。ところが**Claude Code 2.1.225はサブエージェントの会話を親JSONLに書かない**。親と同階層の`<セッションID>/subagents/agent-<id>.jsonl`という別ファイルに書き、`isSidechain:true`のエントリは親JSONLに1件も存在しない(実測: 親204行中sidechain 0件)。したがって`analyze()`はサブエージェント分を構造的に取りこぼす。

実測(セッション`eef0d647-...`、2026-08-09の`/full_loop`。単価はloop_guardと同じ重み付けで再計算):

| 区分 | モデル | トークン | コスト |
|---|---|---|---|
| 親セッション(loop_guardが見ている範囲) | sonnet-5 | 13,854,449 | $6.908 |
| sub: verifier | sonnet-5 | 453,700 | $0.390 |
| sub: implementer | sonnet-5 | 19,683,551 | $8.497 |
| sub: researcher | sonnet-5 | 833,222 | $0.796 |
| sub: architect | opus-5 | 3,675,220 | $4.223 |
| **合計** | | **38,500,142** | **$20.814** |

`loop_guard`の可視範囲は**33.2%**。「サブエージェント4体で約20万トークン」という§8の記録も、親transcriptの`toolUseResult.usage`を全消費と誤読したもの(下記)で、実際は2桁多い。

**代替案として却下したもの**: 親transcriptのTaskツール結果には`toolUseResult.usage`/`totalTokens`/`resolvedModel`が入っており一見使えるが、**これは最終API呼び出し1回分の値でしかない**。T5-A27の`architect`では`totalTokens=150509`と記録される一方、同一エージェントのJSONL実測は6,369,414トークン(約42倍)。これを集計源にすると過小評価が残るため使わない。集計源は`subagents/agent-*.jsonl`の`message.usage`とする。

### 9-B. 欠陥B: ターン中に再計算されない(当初の想定どおり、ただし修正可能)

`.claude/settings.json`に登録されているフックは`UserPromptSubmit`と`Stop`のみ。`/full_loop`は1回のプロンプト送信の中でサブエージェントを連続実行するため、その間はどちらも発火せず`loop_state.md`が固まる。加えて`UserPromptSubmit`時は`raw`にコマンド文字列が見つかると境界を`nowIso`に置く(`loop_guard.js:278-284`)ので、**`/full_loop`送信直後の値は必ず`$0.0000 / turns=0`になる**。これが「サブエージェント消費後も$0.0000のまま」の直接の理由であり、実測どおりの挙動。

`Stop`はサブエージェント完了時には発火していない。実測: `architect`は01:52:00に完了したが、親transcriptの`stop_hook_summary`は01:56:33と02:00:07の2件のみで、01:52台には無い。

**ただしフック機構上の制約ではない。** claude.exe 2.1.225のバイナリには`SubagentStop`(49箇所)・`PostToolUse`(92箇所)を含む8種のフックイベント名が存在し、`hookSpecificOutput.additionalContext`も実装されている。`PostToolUse`に`matcher: "Task"`で登録すれば、各サブエージェント完了直後(=Taskツール結果が確定した時点、サブエージェントJSONLも書き終わっている)に親のコンテキストで再計算できる。

### 9-C. 欠陥C: ループ境界の検出がスラッシュコマンドの展開形に依存している

`findLoopBoundary()`はtranscript内の`<command-name>/full_loop</command-name>`を探す(`loop_guard.js:131`)。しかし**行頭以外にコマンドを書くとClaude Codeは展開しない**。2026-08-09のT5-A27ループではユーザーが`82% /full_loop`と送ったため、transcriptには生テキスト`82% /full_loop`しか残っていない(実測確認済み)。結果:

- `UserPromptSubmit`時は`raw`の緩い正規表現`/\/(start|full_loop|night_loop)\b/`が拾うので有人モードになる。
- `Stop`など以降のすべての発火では境界が見つからず、**当日累計へフォールバック+モード判別不能で安全側の夜間しきい値($8/40/2)を誤適用**する。§8に記録された異常はこれ。

### 9-D. 推奨する改善策

**推奨は「loop_guard.jsをサブエージェント集計対応にし(A)、`PostToolUse(matcher: Task)`フックを追加し(B)、境界をファイルに永続化する(C)」の3点セット。** 代替運用への退避は不要。Aだけでも精度は3倍になるが、Aを入れてもBが無ければ`/full_loop`のセッション分割判定(cost>$7)はターン終了まで動かないため、AとBはセットで入れる。実装タスクはマスタープラン**T5-A33〜T5-A35**。

性能上の懸念は無い(最大10MBのtranscriptで`JSON.parse`全走査73ms、既存フックの実測所要201ms)。

**副次的に必要な運用変更**: `full_loop`スキル手順3.5は現在「`.claude/loop_state.md`をReadし直す必要はなく、フック出力の値をそのまま使う」と書いてあるが、フック出力はそのターンの**開始時点**の値なので、実装後は**手順3.5で`.claude/loop_state.md`をReadする**に改める(15行程度で安価)。T5-A34に含める。

**仮説(未検証)**: (1)`PostToolUse`が`hookSpecificOutput.additionalContext`で文脈注入できれば、Read無しで警告を届けられる。まずはサイレント書き込みだけ実装し、注入の可否は検証で確かめる。(2)`SubagentStop`登録時に渡される`transcript_path`が親のものかサブエージェントのものかは未確認。T5-A33の`resolveTranscriptTargets()`は両方を受け付ける実装にするため、どちらでも壊れない。

### 9-E. 実装仕様(implementer向け。設計判断は不要)

#### T5-A33: `loop_guard.js` にサブエージェント消費を合算する

対象は`.claude/hooks/loop_guard.js`のみ。

1. 新関数`resolveTranscriptTargets(transcriptPath)`を追加し、`{ mainTranscript, subagentFiles }`を返す。
   - `dir = path.dirname(transcriptPath)`、`base = path.basename(transcriptPath, '.jsonl')`。
   - `path.basename(dir) === 'subagents'` なら(サブエージェントのtranscriptを渡された場合): `sessionDir = path.dirname(dir)`、`mainTranscript = sessionDir + '.jsonl'`。
   - そうでなければ: `mainTranscript = transcriptPath`、`sessionDir = path.join(dir, base)`。
   - `subagentFiles` = `path.join(sessionDir, 'subagents')` 直下で`.jsonl`で終わるファイルの絶対パス配列(`.meta.json`は除外)。ディレクトリが存在しない・読めない場合は空配列(例外を投げない)。
2. `analyze()`のシグネチャを`analyze(mainTranscript, subagentFiles, today, loopBoundaryTs)`に変更。
   - **ターン数(`isRealUserPrompt`)は`mainTranscript`だけで数える**(サブエージェントへの指示プロンプトをユーザーターンに数えないため)。
   - **コストとモデル別トークンは`mainTranscript` + `subagentFiles`全部を合算**。スコープ判定(`ts >= loopBoundaryTs`、境界未検出時は当日判定)は現行と同じロジックを両方に適用する。
   - 戻り値に`subCost`(サブエージェント分のコスト合計)と`subAgentCount`(スコープ内に`usage`を1件以上持つサブエージェントファイル数)を追加。
   - `ok`は`mainTranscript`の読込可否で従来どおり決める。
3. `findLoopBoundary()`の対象は`mainTranscript`のみ(現行のまま)。
4. `loop_state.md`の出力に1行追加する(既存の「コスト」行の直後)。文言:
   `- 内訳: 親セッション $X.XXXX / サブエージェント $Y.YYYY (N体)`
5. `UserPromptSubmit`時のstdout1行目末尾に` sub=$Y.YYY(N体)`を追加する。

完了条件の検証は、既存セッションのtranscriptを引数に与えて手計算値と一致するかで行う(§9-Aの表の`eef0d647`セッションが検証用データとして使える)。

#### T5-A34: ターン内でも再計算されるようフックを追加する

1. `.claude/settings.json`の`hooks`に2つ追加する(既存の`UserPromptSubmit`・`Stop`はそのまま残す)。
   ```json
   "PostToolUse": [
     { "matcher": "Task",
       "hooks": [{ "type": "command", "command": "node .claude/hooks/loop_guard.js" }] }
   ],
   "SubagentStop": [
     { "hooks": [{ "type": "command", "command": "node .claude/hooks/loop_guard.js" }] }
   ]
   ```
2. `loop_guard.js`は**`UserPromptSubmit`以外ではstdoutを出さない**現行の分岐(`loop_guard.js:341`)をそのまま維持する(`PostToolUse`/`SubagentStop`もサイレント書き込み)。
3. `.claude/skills/full_loop/SKILL.md`の手順3.5を修正する。現行の「`.claude/loop_state.md`をReadし直す必要はなく、フック出力の値をそのまま使う」を、「**`.claude/loop_state.md`をReadし、そこに書かれた本ループのコスト(サブエージェント込み)を使う**。フック出力の`[loop_guard] ...`行はそのターン開始時点の値なのでターン内の判定には使わない」に置き換える。手順1(状況確認)の同趣旨の記述も同様に直す。

#### T5-A35: ループ境界を`.claude/loop_boundary.txt`に永続化する

1. `loop_guard.js`に読み書きを追加。ファイル形式は1行`<ISO8601タイムスタンプ> <attended|night>`。
2. 境界の決定順序を次に変更する。
   1. `raw`(stdin生テキスト)が`/\/(start|full_loop|night_loop)\b/`にマッチ → 境界`= nowIso`、モード`= modeForCommand(最後のマッチ)`。**この場合のみ`.claude/loop_boundary.txt`を上書きする**(新しいループの開始)。
   2. マッチしない場合、`findLoopBoundary()`の結果と`.claude/loop_boundary.txt`の内容を突き合わせ、**タイムスタンプが新しい方**を採用する(片方しか無ければそれを使う)。
   3. どちらも無ければ現行どおり当日累計フォールバック+モード`night`。
3. `.gitignore`に`.claude/loop_boundary.txt`を追加する(`.claude/loop_state.md`が`.gitignore:49`にある近辺に並べる)。
4. ファイル読み書きは全体を`try/catch`で囲み、失敗時は現行のフォールバック挙動に戻す(フックが落ちてはならない)。
