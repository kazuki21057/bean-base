# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working with this repository.

## Project Context & Status

**BeanBase 2.0** is a personal Flutter app for logging coffee brews, managing equipment master data, and analyzing taste data (PCA + AI interpretation). It targets Web (Chrome, the primary verification target) and mobile. Originally developed with Google Antigravity; its main surviving convention is the `[Antigravity]` logging prefix used throughout the codebase. Development is tracked in numbered **Cycles** under `docs/` (older cycles in `docs/archive/`); when starting a new one, check the highest existing number and increment — never reuse or skip.

**Current status (latest = Cycle 19, "Sheets revert", completed 2026-07-03):**

- **Storage backend is Google Sheets** via a GAS Web App. All CRUD goes through the `DataService` abstraction (`lib/services/data_service.dart`); the active implementation is `SheetsService` (`lib/services/sheets_service.dart`). Switching backends is a one-line change in `dataServiceProvider`. **Images** go to Google Drive via the same GAS app (`ImageService` POSTs base64, GAS saves to Drive and returns a URL stored in Sheets).
- **Firestore is legacy**: `FirestoreService`, `FirestoreMigrator`, `firebase_options.dart` remain from Cycle 18 but are unused at runtime — don't extend unless a task explicitly says so.
- Renovation is tracked in **`docs/改修マスタープラン.md`** (source of truth for phases/tasks/progress); session handover in **`NEXT_SESSION.md`**. Next up: Phase 1 (Cycle 20), screen/navigation restructure.

## 毎ループの読み取り最小セット(トークン削減のため整理)

1ループで**全読みしてよいのは以下だけ**(過去記録はアーカイブへ分離済み。必要時のみID・日付・キーワードでgrepして該当箇所だけ読む、全読み禁止):
- `CLAUDE.md`(本ファイル、規約)
- `NEXT_SESSION.md`(引き継ぎ。**直近1セッション分の作業ログのみ**を保つ)
- `docs/改修マスタープラン.md` §2・§3の**未完了行**(当日タスクの選定)
- `rules/verification.md`(検証フロー+**教訓インデックス**、1行見出しのみ)
- `.claude/loop_state.md`/`.claude/loop_failures.txt`(しきい値確認)

**通常は読まず、必要時だけgrep**: `rules/lessons_archive.md`(教訓全文、`L37`等で引く)/`docs/archive/マスタープラン_完了タスク.md`(完了タスク詳細、IDで引く)/`docs/archive/マスタープラン_作業ログ.md`(日付順ログ)/`docs/archive/NEXT_SESSION_log.md`(過去セッションログ)/`statistics_feature_design.md`ほか各設計書(**該当タスク実装時だけ**必要な節を読む)。追記も同じ方針: 完了タスク詳細は上記アーカイブへ、教訓は`rules/lessons_archive.md`末尾へ、毎回読むファイルは短いまま保つ。

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (Chrome is the primary target)
flutter run -d chrome

# Run all tests
flutter test

# Run a single test file
flutter test test/statistics_service_test.dart

# Static analysis
flutter analyze

# Regenerate code after model changes (json_serializable)
dart run build_runner clean && dart run build_runner build --force-jit
```

## Architecture

State management is Riverpod; persistence is Google Sheets (reverted from Firestore, Cycle 19).

- **Data flow**: `DataService`(`lib/services/data_service.dart`) is the abstract CRUD contract; `SheetsService`(`lib/services/sheets_service.dart`) is the active impl, talking to a GAS Web App (`kGoogleSheetsApiUrl`) with Japanese-key sheets (numeric IDs cast to String). `dataServiceProvider` is the single backend switch point; data flows via `FutureProvider`s in `lib/providers/data_providers.dart`. GAS redeploys issue a new URL — update `kGoogleSheetsApiUrl`.
- **Legacy** (don't extend without explicit instruction): `FirestoreService`, `FirestoreMigrator` (Cycle 18). If a task needs Firestore, run `flutterfire configure` first to regenerate `firebase_options.dart` (committed values may be placeholders).
- **Navigation**: `MainLayout`(`lib/layout/main_layout.dart`) wraps every screen via `MaterialApp.builder` — `NavigationRail`(≥640px) / `NavigationBar`(mobile), via `navIndexProvider` and a global `NavigatorKey`(`lib/utils/nav_key.dart`) with `pushAndRemoveUntil`. Phase 1 restructures this into ~22 screens (`docs/改修マスタープラン.md` §4).
- **Models**: `lib/models/` use `json_annotation`/`json_serializable`; regenerate `*.g.dart` with `build_runner build` after changes.

| Service | Purpose |
|---|---|
| `SheetsService` (via `DataService`) | CRUD via GAS Web App |
| `ImageService` | Upload images to Drive via GAS (web: bytes / mobile: path), stores returned URL |
| `AiAnalysisService` | Calls Gemini (2.5-flash→2.0-flash-lite→1.5-flash fallback) to interpret PCA components |
| `StatisticsService` | PCA/KPI computation via `ml_linalg` |
| `FirestoreService` | **Legacy**, unused |

## Verification Rules

Detailed rules live in `rules/verification.md`. Summary: `flutter analyze`(zero new issues) → `flutter test`(all pass) → `flutter run`(no exceptions/overflow, external services connect) → visual browser verification. **既知の失敗しやすい検証経路**(Androidエミュレータのリトライ上限・ブラウザ優先・GAS直curl不可等)は`rules/verification.md`の同名節を参照。無人夜間ループの既知障害の検知・自動対処・エスカレーション基準は`docs/failure_playbook.md`が正本(`tools/failure_playbook.ps1`が実装)。

**Key invariants:**
- Master-type UI/functionality changes apply to **all master tabs/screens** (Bean, Grinder, Dripper, Filter, Method where applicable) — never just Bean.
- Log key actions/external calls with `[Antigravity]`: `debugPrint('[Antigravity] Action: ...')`; wrap external calls in try/catch, log errors the same way.
- External numeric IDs (Sheets returns int/double) must be cast via `.toString()` in `fromJson` (prevents `type 'int' is not a subtype of type 'String?'`); guard empty IDs.
- Gemini API key lives in `shared_preferences` (`gemini_api_key`), set on Settings — never commit it.
- Sandboxes may block GAS/Drive traffic; verify via local `flutter run` when sandboxed.

## Response Language & Documentation Conventions

**日本語出力を徹底する**: チャット応答・**UI文言**(`SnackBar`/`AlertDialog`/エラーメッセージ、最重要。部分的な日本語化=タイトルだけ日本語で本文が英語等は見落としやすい、実例`rules/lessons_archive.md` L41)・ログ本文(`debugPrint('[Antigravity] ...')`の`[Antigravity]`以降)・ドキュメント(`NEXT_SESSION.md`・マスタープラン・教訓・3点セット文書)・commit/PR・`AskUserQuestion`/`PushNotification`は日本語で書く(ハーネス自動付与の固定コミットトレーラーを除く)。3点セット文書は簡単なタスクには生成せず、妥当な場合のみユーザー許可を得て`docs/cycle_<N>_<english_topic>/`に保存する。サブエージェント委譲時は、委譲先がこのファイルの文脈を持たないため「日本語で報告して」等を明示する。

**例外(翻訳しない)**: コード上の識別子、ライブラリ/API/技術用語等の固有名詞、`[Antigravity]`プレフィックス、ハーネスの固定コミットトレーラー。**詳細全文は`docs/archive/マスタープラン_作業ログ.md`「T3-73f」節参照。**

## 日次改修ループ運用ルール

大規模改修は**1日1回のループ**で進める。**`docs/改修マスタープラン.md`が単一の真実**、§3のタスク表から「依存が満たされた最上位のタスク」を選ぶ。**タスク選定時(2026-08-13追記)**: 着手前に、実装+検証+デプロイまで含めた見積もりコストが予算内(有人$24・夜間$20、いずれも下記終了条件・`night_loop`スキルのしきい値と同じ数値)に収まりそうか一言確認してから着手する。収まらないと見込まれる場合はタスクを分割するか、後続ループへ回すことを検討する。

**流れ**: `/start` → タスク選択 → 実装(`implementer`へ委譲) → 検証(`verifier`へ委譲、`analyze`→`test`→`run`)→ OKならcommit/push+進捗表更新 / NGなら`NEXT_SESSION.md`に引き継ぎ → `/end`。

**終了条件(直近の`/start`・`/full_loop`以降の1ループ単位、`loop_guard.js`が`.claude/loop_state.md`に算出——この数値が真実)**: (1)タスク完了 (2)連続3回失敗(`.claude/loop_failures.txt`に記録、成功で0リセット) (3)コスト$24超 (4)ターン数30到達。停止時は新規着手せず(a)`NEXT_SESSION.md`更新(b)マスタープラン進捗表更新(c)可能ならcommit/push、の順で締める。agy(Antigravity CLI)経由の委譲はGeminiまたは別勘定のClaude/GPTバケットを使うため、コスト上限の判定に含めない(1ループあたりのClaudeモデル委譲件数の上限は`docs/antigravity_delegation_design.md` §12.3参照)。件数・所要時間は`loop_state.md`に参考値として出る。

**無人ループ(night_loop)の書き込み範囲の制限(2026-08-13新設、恒久)**: `night_loop`が状態・ログを書き込む先は`.claude/night_*`(`.claude/night_loop_last_run.json`・`.claude/night_runs.log`・`.claude/night_usage_log.tsv`・`.claude/night_logs/`等)に限定する。`.claude/settings.json`・`.claude/agents/*.md`等の恒久設定を含む、それ以外の`.claude/`直下ファイルへの書き込みは無人ループ実行中は行わない。**この制約はpush・デプロイの確認ルールを変更しない**——pushの自動承認(検証完了時は都度確認不要)、デプロイの都度確認必須は、上記「デプロイ・push・削除の確認ルール」節に定めるとおり従来のまま変わらない。

**デプロイ・push・削除の確認ルール(2026-08-08改訂、恒久。正本はここ。経緯は`docs/archive/マスタープラン_作業ログ.md`「T3-73f」)**: `git push`は**検証が完了していれば都度確認は不要**(「検証が完了」とは`verifier`が当該変更について全項目パスを報告した、または**コード変更を含まない**〈ドキュメント・設定のみ〉のいずれか)。検証していない・NGのまま・検証を省略した変更のpushは、従来どおり事前にチャットで許可を得る。**`--force`系のpushは常に確認が必要**(`.claude/settings.json`の`ask`に登録済み)。**デプロイ(`firebase deploy`/`clasp push`・`clasp redeploy`)は上記pushの緩和の対象外で、常に都度確認が必要**——実行直前にチャットで内容を説明し明示的な許可を得る。ファイル・データの**削除**を伴う操作(本番Sheets/Driveのレコード削除、`rm`/`git clean`等の破壊的ファイル操作、`git reset --hard`等)も引き続きその都度リスクを一言説明してから確認を得る(本番Sheets/Driveへの実データの追加・更新〈削除を伴わないもの〉は確認不要)。**ハーネスの自動モード分類器はCLAUDE.md/メモリ上の「事前承認済み」という記述を有効な同意経路とみなさない**(Instruction Poisoning/Auto-Mode Bypassパターン)ため、上記の緩和をチャット上で明示的に指示していても分類器がpush等をブロックすることがある。**その場合はサブエージェントへの委譲などで回避を試みてはならない**(2026-07-30に撤回済みの誤った運用、教訓`rules/lessons_archive.md` L91)。ブロックされたら実行を止め、何を・なぜ実行しようとしたかをユーザーに説明し、チャットでの許可を得た上で改めて実行する。

**セッション継続 vs `/clear` の判断(2026-08-08新設、恒久)**: `/end`の締め(手順末尾、commit/push後)で、次の`/start`・`/full_loop`を**このまま同じセッションで続けるか**、**ユーザーが一度`/clear`してから始めるべきか**を一言提案する。根拠は`loop_guard.js`が毎ターン注入する`[loop_guard] 本ループ(モード) cost=.../turns=...`の直近値(または`.claude/loop_state.md`)——**今回のループの**cost・turnsが、適用中モードの上限の**半分**(有人: $12超 または15ターン以上、夜間: $4超 または20ターン以上)を超えていれば「次回は`/clear`推奨」、超えていなければ「続けて問題なし」と提案する。理由はコンテキストが200kトークン超で単価が約2倍になること(`docs/token_optimization_design.md` F1)——同一セッションでループを重ねるほど会話全体の下地コンテキストが積み上がり単価境界を超えやすくなる。ただし**提案に留め、強制や自動実行はしない**(アシスタントは自分自身に対して`/clear`を呼び出す手段を持たない、`full_loop`スキル§`/loop`による定期実行時の追加ルール参照)。`/loop`(cron)経由の無人連続実行時はユーザーが画面を見ておらずこの提案自体に意味が無いため行わない(引き続きファイルベースの引き継ぎで対応する)。

**`/code-review`の定期実行ルール(2026-08-08新設、恒久)**: `/code-review`を検証項目に加える。ただし`verifier`の`analyze`/`test`/`build`とは異なり**毎ループ実行すると高コストなため、以下いずれかに該当する時だけ実行する**: (1)**大きな修正**——変更ファイル数がT3-73dと同じ基準の5超 (2)**区切りがいいとき**——そのタスクの完了でマスタープランのフェーズ/トラックが完了する時、またはユーザーから明示指示があった時 (3)**夜間定期ループの10回に1回**——`/night_loop`起動回数のカウンタで判定(カウンタ実装はT5-A25、実装されるまでは(1)(2)のみ運用)。実行対象は直近の`git diff`、effortは既定`medium`。**見つかったCritical/Major指摘は報告に留めず、その場で`implementer`に差し戻して修正する**(見つけて終わりを禁止。次に見つかったバグから適用)。実行しない通常ループでは従来どおり`verifier`の`analyze`/`test`/`build`のみで良い。

**トークン浪費の調査ルール(2026-08-09新設、2026-08-10改訂〈5時間枠/週次の二軸記録を明記〉、恒久)**: `full_loop`実行のたび、**軽量な記録は毎回**残す——`loop_guard`のコスト・ターン数、サブエージェント使用時はその合計トークン数、Proプラン使用率は`curl http://localhost:3000/`(ローカル使用状況確認API)の**`Current session`(5時間枠)・`Current week`(週次)の2値を必ずどちらも取得・記録する**(片方だけ記録しない。取得できなければ「未取得」、ユーザーが口頭申告した場合はそちらを優先。推測値は書かない)。セッション開始・終了時の値を`docs/token_optimization_design.md` §7(効果測定ログ)・§8(Proプラン使用率ログ)に追記する。**分析(architectへの委譲時含む)でも両軸を区別する**: 5時間枠はセッション単位で頻繁にリセットされ短期の消費速度を表すのに対し、週次は累積で長期の余力を表すため、片方だけを見ると誤った結論(例: 5時間枠に余裕があっても週次が逼迫していれば実質的に使用不可)に至りうる。**その記録を元にした原因調査・改善策の検討(architectへの委譲)は`/full_loop`実行10回に1回でよい**(カウンタ実装はT5-A25の`/night_loop`版と同様の仕組みを`/full_loop`にも設ける、実装タスクはT5-A29。実装されるまでは、ループ中に明らかな異常(繰り返し失敗するリトライ・計測値の食い違い等)を見つけた場合のみ随時タスク化する運用とする)。目的は`docs/token_optimization_design.md` §8のProプラン使用率ログとコスト実測の対応関係を毎回のオーバーヘッド無しに蓄積すること。

**運用ルール(詳細は`docs/archive/マスタープラン_作業ログ.md`「T3-73f」)**: ユーザー確認が要る場面(`AskUserQuestion`・着手可否・終了報告・リスク操作)は`PushNotification`でも通知。**モデル分担ルール(2026-08-08夜 改訂、恒久)**: **親セッションは既定でSonnet 5で起動する**(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** 根拠は`docs/token_reduction_report_20260808.md` §2・§5——実測でOpus親は中央コンテキスト18.6万・200k超27.9%に達し推定コストの47%を単独で占めたのに対し、Sonnet親は中央8.6万〜11.6万・200k超ゼロ。単価差1.7倍に対し実測差は約3倍。**タスク選定はモデルで分岐させない**: 依存が満たされた`⚠️上位モデルで実施`タスクがあればそれを優先し(**親のモデルに関わらず`architect`へ委譲**、成果物は設計書+タスク分解のみでコードは書かせない)、無ければ通常タスクへフォールバックする(実装は`implementer`、検証は`verifier`)。旧「上位モデル起動時は⚠️タスク以外に着手しない」(2026-07-28・07-29)および「親は常に上位モデルである前提」(2026-08-08昼)は**いずれも廃止**。`architect`を呼ぶ4条件がそのままOpusへのエスカレーション条件になる。**この分担は`.claude/agents/`のサブエージェントで実行する**: 設計・原因究明=`architect`(opus)、コード実装=`implementer`(sonnet)、検証=`verifier`(sonnet)。親セッションは選定・判断・ユーザー確認・commit/push/デプロイのみを担い、**コードの実装と検証は自分で行わず担当エージェントに委譲する**(モデルは各定義の`model:`で自動選択されるので`Agent`ツールに`model`を渡さない)。`architect`を呼ぶのは「⚠️上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。委譲先は`CLAUDE.md`の文脈を持たないため、**日本語で報告する指示と確定済み仕様をプロンプトに書き出して渡す**。デプロイ・push・本番データ削除は委譲せず親がユーザー許可を得て実行する(分類器ブロックの回避目的の委譲は禁止)。詳細は`/full_loop`スキル§サブエージェントへの委譲。開始/終了手順は`/start`・`/end`スキルが正本。**agy(Antigravity CLI、`tools/antigravity_delegate.ps1`)委譲を導入しても親セッションはSonnet 5のまま**(根拠: `docs/antigravity_delegation_design.md` §8)。**同一タスクでagyを2回続けて使わない。agyの非0終了は`.claude/loop_failures.txt`の連続失敗に数えない**(インフラのフォールバックでありタスクの失敗ではないため。詳細は同設計書§9.1・§9.4)。

**委譲の単位の見直し(2026-08-15ユーザー承認、恒久、T5-A94)**: 以下2点に限り、上記「コードの実装と検証は自分で行わず担当エージェントに委譲する」の例外を認める。(a) **非委譲のしきい値**: `lib/`・`gas/`・`test/`・`web/`を含まない1ファイル・目安10行以内の文言/設定の修正で、変更内容が確定しているものは、`implementer`へ委譲せず親が直接編集してよい(検証も`verifier`へ委譲せず親の`git diff`確認で足りる)。(b) **同型Sタスクのバッチ委譲**: 依存を満たした同じファイル群を触る後続のSタスクは、最大3件まで1回の`implementer`委譲へまとめてよい(検証も1回にまとめる。完了報告・進捗表の更新はタスクIDごとに行う)。詳細は`.claude/skills/full_loop/SKILL.md`手順2・3参照。

## トークン運用規約(実測に基づく)

1ループのコストは**「リクエスト数 × 平均コンテキスト長」**でほぼ決まり、**200kトークン超で単価が約2倍**になる(詳細・実測値は`docs/token_optimization_design.md`)。(1)独立したツール呼び出しは1メッセージにまとめる (2)一度Readしたファイルを再Readしない、**Edit/Write直後の確認Readは禁止**(失敗すればツールがエラーを返す) (3)300行超のファイルは全文Readせず`Grep`(`-A`/`-B`)か`Read(offset/limit)`で必要箇所だけ読む (4)検証コマンドは短出力形(`rules/verification.md`§必須検証フロー)、**失敗したときだけ**詳細を取り直す (5)ブラウザ確認は`get_page_text`/`find`/`read_console_messages(pattern指定)`を優先し、スクリーンショットは最終確認の1〜2枚に限る。

## 出力量の規約(2026-08-08追加、Opus 5の冗長化対策)

**Opus 5は既定で応答・成果物が長い。`effort`を下げても表示出力の長さは確実には縮まないので、プロンプト側で縛る**(Anthropic公式のOpus 5移行ガイド記載の対処。簡潔化指示で実測約20%短縮)。以下は全モデル・全セッションに適用する:

- **簡潔さ**: 応答は要点に絞る。免責・前置き・言い換えを削り、本題に文量を割く。説明を求められた場合も、明示的に詳細を求められない限り高レベルの要約に留める。
- **結論先出し**: 作業完了後の第一文は「何が起きたか/何が分かったか」を答える。根拠と詳細はその後。ただし**簡潔さより読みやすさを優先**する——短くする方法は「含める情報を選ぶ」ことであり、断片・矢印(`A → B → 失敗`)・省略語への圧縮ではない。
- **成果物の長さ**: ディスクに書くファイル(報告書・Markdown・設計書)も必要十分に留め、埋め草の節・重複した要約・定型文で膨らませない。
- **自己検証を指示しない**: Opus 5は指示せずとも自己検証する。「最後に必ず検証ステップを入れよ」「サブエージェントで確認させよ」の類は**過剰検証を招くので書かない/既存記述は削る**。検証は`verifier`への委譲で担保する。
- **スコープ厳守**: 依頼された範囲・粒度で仕上げる。曖昧さは慎重な同僚として自分で判断し、解釈違いで作業内容が大きく変わる場合だけ確認する。依頼が誤りだと考える場合は一言述べて依頼どおり進める。勝手に狭めない・広げない・作り変えない。
- **自己訂正を語らない**: ユーザーの判断や成果物が変わる誤りだけ、簡潔に訂正して作業を続ける。謝罪・反省・経緯の詳述はしない。追加質問は誤りの兆候ではない。
- **サブエージェントの濫用禁止**: Opus 5は委譲しすぎる傾向がある。数回のツール呼び出しで自分が終えられる作業、および検証目的の委譲はしない(詳細は§日次改修ループ運用ルール)。概念的な設計質問(方針の是非・トレードオフの説明等)にはまず自分の文章で直接回答し、ユーザーの許可なくリサーチエージェント(researcher)を起動しない。

## 統計解析・予測機能の実装ルール

正本は`statistics_feature_design.md`(絶対規則§0、構成マップ§3〜7、データ規則§1.3/3.5/7.1、テスト§9)。食い違えば設計書優先、**実装前に必ず該当節を読む**。要点: 数値計算(回帰・PCA・GP・EI・検定)はDartローカル実装でGeminiに計算させない、設計書に無いフィールド名等を発明しない、Phase順(§10)厳守、統計量は点推定+不確実性をセット表示。
