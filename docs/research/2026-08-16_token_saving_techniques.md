# AIコーディングエージェント運用におけるトークン/コスト節約テクニック調査レポート(第2回)

- 調査日: 2026-08-16
- 調査目的: `/full_loop`(architect/implementer/verifier/adversaryへの委譲を複数回含む日次自動開発ループ)の運用において、(1)繰り返し読み込みのオーバーヘッド削減 (2)サブエージェント委譲のオーバーヘッド削減 (3)検証(テスト・ビルド)の繰り返しコスト削減 (4)その他一般的ベストプラクティス、の4観点でWeb調査を行う。特に、直近の実測で5時間枠使用率が短時間で大きく消費される傾向(本セッション開始時点でセッション37%・週次77%)があることを踏まえ、**マルチエージェント運用でのレート制限/クォータ管理のプラクティス**を重点的に調べる。
- 調査範囲: 着手前に`docs/token_optimization_design.md` §10-1〜§10-7(2026-08-15付の前回調査`docs/research/2026-08-15_token_saving_techniques.md`とその採否判断11件を含む)を読み、そこに挙がった手法・決定済み事項とは重複させない。今回はClaude Code公式ドキュメント(`code.claude.com/docs`)を優先的に一次情報として参照した。個人ブログ・アグリゲーター記事(truefoundry、bestagent.dev等)は多数ヒットしたが、一次情報で裏が取れた事実を優先し、裏が取れない数値・設定は「推測・未確認」に区別して記載した。

## 確認済みの事実

すべて公式ドキュメント(`code.claude.com/docs`)から`WebFetch`で取得した原文(英語)に基づく。取得日はすべて2026-08-16。

### A. 検証(テスト・ビルド)の繰り返しコスト削減

**[C1] `PreToolUse`フックでテストコマンドの出力を事前フィルタする**: `flutter test`/`flutter analyze`等のBashコマンドをフックで横取りし、失敗行(`FAIL`/`ERROR`)だけをgrepして返すことで、Claudeが目にするコンテキストを大幅に削減できると公式に例示されている。`~/.claude/hooks/`にスクリプトを置き`settings.json`の`hooks.PreToolUse`に登録する形。
- 出典: https://code.claude.com/docs/en/costs
- 効果: 「1万行のログファイルを読む代わりに、grepでERROR行だけを返せば数万トークンが数百トークンまで減る」と例示(具体的な削減率の一次実測は明記されていない)。
- 適用可能性(初見): 現行の`.claude/agents/implementer.md`(T5-A92反映済み)は「反復中は対応テストのみ実行、報告直前にフル`analyze`→`test`→`build web`」という**範囲の絞り込み**(TIA、前回採用済み)を行っているが、フル実行時の**出力量そのもの**は絞っていない。`flutter test`/`flutter build web`の生出力(特に大量ログや警告)をPreToolUseフックで失敗行のみに絞れば、TIAと直交する形でさらに実装側のコンテキストを削れる可能性がある。ただし本プロジェクトは委譲(`implementer`サブエージェント)経由の実行が中心のため、フックがサブエージェントのBash呼び出しにも効くかは要確認(**未確認**)。

**[C11] サブエージェント/スキルのfrontmatterで`effort`レベルを個別指定できる**: `effort: medium`等をサブエージェント定義のMarkdownに書くと、そのサブエージェントが呼ばれた時だけeffortレベルを上書きできる。`medium`は「コスト重視のワークでトークン使用量を削減し、多少の知性とトレードオフする」と説明されている。
- 出典: https://code.claude.com/docs/en/model-config
- 適用可能性(初見): 現行`CLAUDE.md`は`/code-review`(adversary相当)の実行時に「effortは既定`medium`」と定めているが、これはコマンド呼び出し時の指定であり、`.claude/agents/implementer.md`・`verifier.md`・`architect.md`自体のfrontmatterに`effort`を書き込む方式は未採用と見られる(**推測**、`.claude/agents/*.md`の内容は本調査では未確認)。定型的な差分レビュー無しの`implementer`+`verifier`往復(§10-1で最軽量とされる型)に`effort: medium`を明示すれば、Sonnet 5のadaptive reasoning自体の思考量を絞れる可能性がある。

### B. 繰り返し読み込み・コンテキスト肥大化の抑制

**[C2] 自動コンパクション閾値(`autoCompactWindow`)を明示的に下げられる**: Sonnet 5はAPI上は常に1Mトークンのネイティブコンテキスト窓を持ち、**デフォルトでは約967Kトークンに達するまで自動コンパクションが働かない**。`/autocompact 200k`のようにコマンドで設定するか、`settings.json`の`autoCompactWindow`、または`CLAUDE_CODE_AUTO_COMPACT_WINDOW`環境変数で閾値を明示的に下げられる。
- 出典: https://code.claude.com/docs/en/model-config
- 適用可能性(初見): 本プロジェクトが`docs/token_optimization_design.md`で問題視している「200kトークン超で単価が約2倍になる」価格境界と、Claude Codeのデフォルトの自動コンパクション閾値(約967K)は**大きく乖離している**。つまりデフォルト設定では、単価が2倍になる境界を越えてもなお自動コンパクションは発動しない。`autoCompactWindow`を200K付近(または現行の終了条件と揃えた値)に明示的に設定すれば、**単価倍加の境界を越える前に強制的に会話を圧縮させる**という直接的なレバーになりうる。ただし親セッションは既に`/clear`+セッション分割($7目安)で運用しているため、効果があるのは「セッション分割前提が崩れて長時間化した場合の保険」としての位置づけになる可能性が高い(**要検証**)。

**[C3] Sonnet 5・Opus 5は「adaptive reasoning」モデルであり、固定思考トークン予算(`MAX_THINKING_TOKENS`)は効かない**: 公式に「Fable 5、Sonnet 5、Opus 4.7以降は常にadaptive reasoningを使い、固定思考予算モードと`CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`はこれらに適用されない」と明記されている。思考量を絞りたい場合は`MAX_THINKING_TOKENS`ではなく`/effort`(low/medium/high/xhigh)を使う必要がある。
- 出典: https://code.claude.com/docs/en/model-config (`Adaptive-reasoning models ignore nonzero budgets, so use effort levels there instead.` は同テーマの https://code.claude.com/docs/en/costs にも記載)
- 適用可能性(初見): 一部の外部ブログ(下記「推測・未確認」参照)は「`MAX_THINKING_TOKENS`設定が最も効果の高いトークン削減策」と紹介しているが、**本プロジェクトが使用する親セッション(Sonnet 5)・`architect`(Opus 5想定)・`implementer`/`verifier`(Sonnet 5)にはこの設定は効かない**。効かせたい場合は各ロールのeffortレベル調整(C11参照)が正しい手段であり、ブログの助言をそのまま適用しても効果が出ない可能性が高い。

### C. サブエージェント委譲のオーバーヘッド削減

**[C4] サブエージェント単位でのモデル指定と一括ルーティング**: サブエージェント定義のfrontmatterで`model: haiku`のように個別指定できるほか、`CLAUDE_CODE_SUBAGENT_MODEL`環境変数を設定すると全サブエージェントのモデルを一括で上書きできる(優先順位は環境変数が最優先、次に呼び出し時のmodelパラメータ、frontmatterのmodel、最後にメイン会話のモデルを継承)。公式コスト削減ガイドは「単純なサブエージェントタスクにはサブエージェント設定で`model: haiku`を指定せよ」と明記。
- 出典: https://code.claude.com/docs/en/costs(`For simple subagent tasks, specify model: haiku in your subagent configuration.`)、https://code.claude.com/docs/en/model-config(`CLAUDE_CODE_SUBAGENT_MODEL`の存在を確認)
- 適用可能性(初見): 前回調査は「マルチモデルルーティング」全体を"既に採用済み"(親+`implementer`/`verifier`=Sonnet、`architect`=Opus限定)として不採用に分類しているが、それは**役割単位**のルーティングであり、**Haikuという第3の選択肢**は検討対象になっていなかった。`adversary`(`/code-review`)のような定型チェック作業や、機械的なファイル操作のみを行うSタスクのバッチ委譲(T5-A94(b))にHaikuを割り当てる余地があるかは未検討(**要検討**、実際にHaikuで十分な精度が出るかは本調査の範囲外)。

**[C5] Agent Teams機能はplanモードで通常セッションの約7倍のトークンを消費する**: 実験的機能`Agent Teams`(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`で有効化、デフォルト無効)は各teammateが独立したコンテキスト窓を持つ別インスタンスとして動作するため、「teammateがplanモードで動く場合、標準セッションの約7倍のトークンを消費する」と公式に明記されている。
- 出典: https://code.claude.com/docs/en/costs(`Agent teams use approximately 7x more tokens than standard sessions when teammates run in plan mode, because each teammate maintains its own context window and runs as a separate Claude instance.`)
- 適用可能性(初見): 本プロジェクトはこの実験的な`Agent Teams`機能自体を有効化していないと見られ(`CLAUDE.md`に該当環境変数の記述なし)、`architect`/`implementer`/`verifier`は`Task`ツール経由の通常サブエージェント委譲であり別物。ただし、この7倍という数値は「独立したコンテキスト窓を持つ複数インスタンスを並行稼働させることの実測コスト」を公式が定量化した数少ない例であり、将来`Agent Teams`や類似の並列構成を検討する際の判断材料になる。**現状「並列度を上げる方向の最適化は行わない」(`docs/token_optimization_design.md` §10-4)という既存判断を裏付ける追加根拠**として記録する。

**[C12] Agent Teamsのコスト管理指針(教訓として転用可能)**: 公式は「teammateにはSonnetを使う」「チームを小さく保つ(トークン消費はチーム規模にほぼ比例)」「spawnプロンプトを絞る(CLAUDE.md・MCP・スキルは自動読込されるため、spawnプロンプトに書いた内容はすべて上乗せされる)」「作業が終わったteammateは終了させる(生きている限りトークンを消費し続ける)」という4点を挙げている。
- 出典: https://code.claude.com/docs/en/costs(`Use Sonnet for teammates. It balances capability and cost for coordination tasks.` ほか3点)
- 適用可能性(初見): `architect`/`implementer`/`verifier`の委譲構成にも同型の教訓が当てはまる。特に「spawnプロンプトを絞る」は既存のT5-A91(委譲プロンプトの参照渡し・要点のみ返させる)と同方向で、外部裏付けとして記録するに留める(新規アクションは不要、重複気味)。

### D. マルチエージェント運用でのレート制限/クォータ管理(重点論点)

**[C6] 5時間枠+週次枠の二重制で、Team/Enterpriseではクォータがclaude.aiチャット・Coworkとも共有される**: 「各メンバーのClaude Code使用量は、ローリング5時間枠と週次枠でリセットされる**シート単位の割当**から差し引かれる。この割当はClaude chatやCoworkとも共有される」と公式に明記。個人のPro/Maxプランについても同一の二重窓構造(5時間枠+週次枠)であることが前提として記述されている。
- 出典: https://code.claude.com/docs/en/costs(`each member's Claude Code usage draws from a per-seat allowance that resets on a rolling five-hour window and a weekly window. The allowance is shared with Claude chat and Cowork, and its size depends on the member's seat tier`)
- 適用可能性(初見): 本プロジェクトが`CLAUDE.md`・`docs/token_optimization_design.md`で前提としている「5時間枠/週次の二軸」計測方針は、公式のクォータ構造と整合していることが一次情報で確認できた。**Claude.aiチャットやCoworkを同一アカウントで併用している場合、それらの利用も同じクォータを消費する**点は、bean-base運用側で意識されていなければ盲点になりうる(ユーザーが他用途でClaude.aiを併用しているかは本調査の範囲外)。

**[C7] プロンプトキャッシュのライフタイムは、usage credits(追加課金)を使い始めると1時間→5分に短縮される**: 「キャッシュのライフタイムはサブスクリプションでは1時間だが、usage creditsを使い始めた時点で5分に落ちる(API keyやクラウドプロバイダでは元々5分がデフォルト)。`ENABLE_PROMPT_CACHING_1H=1`を設定すればusage credits使用中でも1時間ライフタイムを維持できる」と明記。
- 出典: https://code.claude.com/docs/en/costs(`The lifetime is an hour on a subscription and drops to five minutes once you're drawing on usage credits... You can keep the one-hour lifetime while drawing on usage credits by setting ENABLE_PROMPT_CACHING_1H=1.`)
- 適用可能性(初見): これは**セッション消費が急増する直接的な原因候補**になりうる。もし本プロジェクトの運用でPro/Maxプランの上限を超え「usage credits」による継続利用が有効化されている(または過去にトリガーされたことがある)場合、キャッシュライフタイムが5分に縮み、5分以上の間隔が空くたびにキャッシュミス(=フルコンテキストの再処理、単価も高い)が発生しやすくなる。**本セッション開始時点でセッション37%・週次77%という高消費の一因として、usage credits有効化の有無とキャッシュミス頻度を確認する価値がある**(現状は仮説、実際のusage credits設定状況は本調査では確認できない)。

**[C8] 「長時間セッションで使用量が急増する理由」の公式診断チェックリスト**: 公式ドキュメントは、長時間セッションでクォータ消費が体感的な作業量より早く進む理由として、(1)長いコンテキスト(会話全体を毎リクエスト送信) (2)キャッシュミス(休止後の最初のメッセージがキャッシュ外になりフルコンテキスト再処理) (3)スケジュールタスク(セッションがアイドルでも間隔ごとに全コンテキストを送信) (4)クロスセッションメッセージ(他セッションからのメッセージ配信も全コンテキストを毎回送信) (5)エージェントteammate(生きている限り消費し続ける) (6)コンパクションそのもの(要約対象の会話全体を読むこと自体が大きなリクエストになる)、の6点を列挙している。
- 出典: https://code.claude.com/docs/en/costs(`Long context: Claude Code sends your full conversation with every request, and each time Claude uses tools it sends another request carrying that batch of tool results.` ほか5項目)
- 適用可能性(初見): これは本プロジェクトの§8「Proプラン使用率ログ」で観測される急減の**原因分析用チェックリスト**としてそのまま使える。特に(3)スケジュールタスク・(4)クロスセッションメッセージは、`night_loop`(cron相当の定期実行)や複数セッション運用と関連しうるため、原因調査(architect委譲、10回に1回)の際にこの6項目との突き合わせを行う価値がある。

**[C9] `/usage`はskills・subagents・plugins・MCPサーバー別の使用比率を表示する**: Pro/Max/Team/Enterpriseプランでは`/usage`が直近の使用量を「skills、subagents、plugins、個別のMCPサーバー」ごとにパーセンテージで内訳表示する機能を持つ(`d`/`w`キーで直近24時間・7日を切替)。
- 出典: https://code.claude.com/docs/en/costs(`Attribution: recent usage attributed to skills, subagents, plugins, and individual MCP servers, each shown as a percentage of the total.`)
- 適用可能性(初見): 現行の§7/§8ログは`loop_guard`のコスト・ターン数と手動集計のサブエージェント体数に依存しているが、`/usage`のattribution機能を使えば「`architect`/`implementer`/`verifier`/`adversary`のどれが直近7日でクォータを最も消費しているか」を**公式機能だけで直接観測できる**可能性がある。ただし本プロジェクトのサブエージェントは`.claude/agents/`で名前付き定義されているため、attribution表示がサブエージェント名単位で出るか役割カテゴリ単位でしか出ないかは要確認(**未確認**)。

**[C10] `/insights`コマンドが摩擦点・改善提案を自動レポート化する**: 「`/insights`を実行すると、使った量ではなく**どう作業したか**についてのレポートが得られる。直近セッション(未処理分、最大200件)を分析し、取り組んだ内容・誤解されたリクエストやバグの多発といった摩擦点・より効果的な使い方の提案、をカバーしたHTMLレポートを`~/.claude/usage-data/report.html`に書き出す」と説明されている。
- 出典: https://code.claude.com/docs/en/costs(`Run /insights for a report on how you work rather than how many tokens you've used.`)
- 適用可能性(初見): これは`.claude/skills/token_review/SKILL.md`が担う「調査→実測突き合わせ→改善策」の**調査段階を公式機能で代替・補強できる可能性**がある。前回調査の採否判断(§10-7-2)は`researcher`による外部Web調査を起点にしていたが、`/insights`はこのマシン上の実セッション履歴を直接分析するため、外部一般論より本プロジェクト固有の摩擦点(例: どのタスクで差し戻しが多いか)を直接特定できる可能性が高い。次回の`/token_review`実行時に試す価値がある(**新規タスク化の要否は上位モデル/ユーザー判断**)。

## 推測・未確認

以下は一次情報(`code.claude.com/docs`の直接WebFetch)で原文を確認できなかった、または第三者ブログ・検索結果の要約のみに基づく情報。事実として扱わず、参考情報の域に留める。

- **サブエージェント個別の予算上限(`--max-budget-usd`)**: 第三者ブログ(digitalapplied.com)は「バックグラウンドエージェント実行時に`--max-budget-usd`で予算上限を設定でき、v2.1.217(2026-07-21)より前はバックグラウンドエージェントに対してこの上限が機能しない不具合があった。修正後は上限到達時にエージェント生成が失敗し、既に実行中のバックグラウンドエージェントも停止する」と主張している。公式ドキュメントで直接確認できていない(**未確認**)。もし実在するなら、現行のT5-A93(委譲1回ごとに`.claude/loop_state.md`を手動Readして予算をチェックする運用)を、CLI標準機能によるハード制限で補完できる可能性がある。
  出典: https://www.digitalapplied.com/blog/claude-code-subagent-depth-limits-budget-caps-2026(取得日2026-08-16)
- **`CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`(デフォルト200、無効化不可)・`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`(デフォルト3)**: 検索結果の要約では公式ドキュメント由来とされているが、`code.claude.com/docs/en/env-vars`ページを直接WebFetchでは該当箇所を確認できなかった(ページが長大でツールが該当セクションを検索できなかった)。既存の`CLAUDE.md` §10-4が言及する「同時実行20体・ネスト深度3」とネスト深度の数値(3)は一致するが、セッション総数上限(200)は本プロジェクトの1ループあたりの委譲数(2〜6体)を大きく上回るため、現状は無関係と考えられる(**未確認**、直接確認が必要なら公式`env-vars`ページの該当セクションを個別にgrepし直すこと)。
  出典: WebSearch結果の要約(具体的な一次URLは未特定、取得日2026-08-16)
- **5サブエージェント並行運用で週次枠を1時間以内に使い切った実体験**: 個人ブログ記事が「探索用・レビュー用・ドキュメント調査用・バグ検査用・改善提案用の5サブエージェントを並行稼働させ、1時間以内に週次枠を消費した」「各サブエージェントの2,000トークン要約×3体で1サイクル6,000トークン、10サイクルで約6万トークンが親セッションに蓄積した」という体験談を報告している。教訓として「並行処理で実質的な利益がある場合のみスポーンする」「大規模チームより専門特化した小規模チームが効率的」を挙げている。単一の個人体験談であり、削減率や消費速度の数値がそのまま一般化できるかは不明(**推測**)。
  出典: https://www.xda-developers.com/five-claude-code-subagents-burned-usage-window-hour/(取得日2026-08-16)
- **サードパーティ設定ガイドの一部claim**: `genaiskills.io`の記事は「`.claudeignore`ファイルでインデックス対象を除外できる」「`contextCompactionThreshold`という設定キーでコンパクション閾値を制御できる」等8つの設定を紹介しているが、後者は**公式ドキュメント(`code.claude.com/docs/en/model-config`)で確認できる正しい設定名(`autoCompactWindow`、`/autocompact`コマンド、`CLAUDE_CODE_AUTO_COMPACT_WINDOW`環境変数)と一致しない**。設定キー名の誤りである可能性が高いため、このブログの個別設定名は鵜呑みにせず、C2で示した公式の設定名を使うこと。`.claudeignore`の存在自体も公式コスト削減ページ(`/docs/en/costs`)には記載がなく未確認。
  出典: https://genaiskills.io/articles/claude-code-token-optimisation(取得日2026-08-16)

## 除外した手法(前回調査・`docs/token_optimization_design.md` §10-4/§10-7と重複)

- Context Editing API(`clear_tool_uses`) — 前回調査で様子見判定済み(§10-7-2 #1)。
- コンテキストエンジニアリング4戦略(コンパクション/ノートテイキング/サブエージェント/JIT取得) — 前回調査で採用(限定)判定済み(§10-7-2 #2)。今回見つけた「サブエージェントへ冗長処理を委譲する」公式説明(C1近傍で触れた"Delegate verbose operations to subagents")も同じ枠組みの再確認であり新規手法として扱わない。
- 長時間稼働エージェント向けハーネス設計 — 不採用(重複)判定済み(§10-7-2 #3)。
- 参照渡し(delegation by reference) — 採用済み(T5-A91、§10-7-2 #4)。
- 成果物のファイルシステム書き出し — 不採用(重複)判定済み(§10-7-2 #5)。
- 逐次委譲チェーンのアンチパターン/小さい編集は直接委譲 — 構成は維持、付随論点はT5-A94として採用済み(§10-7-2 #6)。
- Test Impact Analysis(検証範囲の限定) — 採用(限定、T5-A92)判定済み(§10-7-2 #7)。
- AST/依存グラフベースのコードインデックス — 不採用判定済み(§10-7-2 #8)。今回見つけた「コードインテリジェンスプラグイン(言語サーバーによるシンボルナビゲーション)」も同じ「専用ツール導入が前提」という不採用理由がそのまま当てはまるため、新規手法として扱わない。
- マルチモデルルーティング(実装は安価モデル、計画は高性能モデル) — 既に採用済みと判定(§10-7-2 #9)。ただしHaikuへの粒度(C4)は今回新たに見つけた具体化のため、上記のとおり別項目として記載した。
- 実行中のトークン予算強制 — 採用済み(T5-A93、§10-7-2 #10)。
- AgentAssayの統計的回帰テスト削減 — 不採用(範囲外)判定済み(§10-7-2 #11)。
- `subagent_type: "fork"`・マルチエージェント構成の「5〜10倍削減」等の一般的倍率主張・`--dangerously-skip-permissions`・並列度を上げる方向の最適化 — いずれも`docs/token_optimization_design.md` §10-4で不採用・蒸し返さない判断済み。今回見つけたAgent Teamsの「7倍消費」という数値(C5)は、削減ではなく**増加**を示す逆方向の実測値であり、この不採用判断をむしろ補強する追加根拠として§10-Dに記載するに留めた。

## 変動しうる情報への注記

- レート制限の仕様(5時間枠・週次枠の具体的なトークン量、"doubled" 等の一時的な緩和措置)は2026年に入り複数回改定されており、今後も変更されうる。導入・再確認時は`https://code.claude.com/docs/en/costs`を都度参照すること。
- `autoCompactWindow`のデフォルト値(Sonnet 5で約967K)・`effort`レベルの既定値・`CLAUDE_CODE_SUBAGENT_MODEL`等の環境変数は、いずれもClaude Codeのバージョン(`v2.1.xxx`)に紐づく形で頻繁に変更されている(取得したドキュメント内に多数の「Before v2.1.xxx」の記述がある)。設定変更を検討する際は`claude --version`で現在のバージョンを確認し、該当バージョンでの挙動を再確認すること。
- Agent Teams機能(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`)は明示的に実験的機能とされており、7倍という消費倍率を含め仕様が変わる可能性がある。
- usage creditsのキャッシュライフタイム(5分/1時間)は課金体系に直結するため、本プロジェクトでusage creditsを有効化する/した場合は`ENABLE_PROMPT_CACHING_1H`の設定状況を都度確認すること。

## 積み残し・判断が必要な点

- **C7(usage creditsとキャッシュライフタイム)の仮説検証**: 本プロジェクトのアカウントでusage creditsが有効化されているか、過去にトリガーされたことがあるかは本調査の範囲外(Web調査では確認不能、ユーザー本人または`/usage-credits`コマンドでの確認が必要)。もし有効なら`ENABLE_PROMPT_CACHING_1H=1`の設定が5時間枠急減の緩和策になりうるため、次の`/token_review`実行時に確認する価値がある。
- **C9(`/usage`のロール別内訳)を実際に使ってみる**: `.claude/agents/`のサブエージェント名単位で内訳が出るかは未確認。次回ループで`/usage`を`w`(週次)表示させ、§7/§8の手動記録と突き合わせる価値がある(実施の要否は上位モデル/ユーザー判断)。
- **C1(PreToolUseフックによる検証出力フィルタ)・C2(`autoCompactWindow`の明示的引き下げ)・C11(サブエージェントfrontmatterの`effort`指定)の採否判断**: いずれも設定変更を伴うため、`docs/token_optimization_design.md`の既存フレームワーク(§10-4の判断基準)に沿って`architect`または上位モデルが採否を判断すべき事項であり、本レポートでは判断を行わない。
- **`--max-budget-usd`・`CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`等の未確認事項**: 採用を検討する場合は、公式`env-vars`ページ(https://code.claude.com/docs/en/env-vars)を直接開いて該当セクションを確認してから判断すること(本調査ではページが長大でツールから該当箇所を抽出できなかった)。

## 出典一覧

| # | 主張ID | URL | HTTPステータス | 取得日 | 裏付け引用(原文ママ) |
|---|---|---|---|---|---|
| 1 | C1 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | Instead of Claude reading a 10,000-line log file to find errors, a hook can grep for `ERROR` and return only matching lines, reducing context from tens of thousands of tokens to hundreds. |
| 2 | C2 | https://code.claude.com/docs/en/model-config | 200 | 2026-08-16 | Sessions auto-compact before the window fills, at about 967K tokens by default; set CLAUDE_CODE_AUTO_COMPACT_WINDOW to choose a different threshold. |
| 3 | C3 | https://code.claude.com/docs/en/model-config | 200 | 2026-08-16 | Fable 5, Sonnet 5, and Opus 4.7 and later always use adaptive reasoning. The fixed thinking budget mode and CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING do not apply to them. |
| 4 | C4 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | For simple subagent tasks, specify model: haiku in your subagent configuration. |
| 5 | C5 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | Agent teams use approximately 7x more tokens than standard sessions when teammates run in plan mode, because each teammate maintains its own context window and runs as a separate Claude instance. |
| 6 | C6 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | each member's Claude Code usage draws from a per-seat allowance that resets on a rolling five-hour window and a weekly window. The allowance is shared with Claude chat and Cowork |
| 7 | C7 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | The lifetime is an hour on a subscription and drops to five minutes once you're drawing on usage credits |
| 8 | C8 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | Long context: Claude Code sends your full conversation with every request, and each time Claude uses tools it sends another request carrying that batch of tool results. |
| 9 | C9 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | Attribution: recent usage attributed to skills, subagents, plugins, and individual MCP servers, each shown as a percentage of the total. |
| 10 | C10 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | Run /insights for a report on how you work rather than how many tokens you've used. |
| 11 | C11 | https://code.claude.com/docs/en/model-config | 200 | 2026-08-16 | Reduces token usage for cost-sensitive work that can trade off some intelligence |
| 12 | C12 | https://code.claude.com/docs/en/costs | 200 | 2026-08-16 | Use Sonnet for teammates. It balances capability and cost for coordination tasks. |
