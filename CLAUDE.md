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

Detailed rules live in `rules/verification.md`. Summary: `flutter analyze`(zero new issues) → `flutter test`(all pass) → `flutter run`(no exceptions/overflow, external services connect) → visual browser verification.

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

大規模改修は**1日1回のループ**で進める。**`docs/改修マスタープラン.md`が単一の真実**、§3のタスク表から「依存が満たされた最上位のタスク」を選ぶ。

**流れ**: `/start` → タスク選択 → 実装(`implementer`へ委譲) → 検証(`verifier`へ委譲、`analyze`→`test`→`run`)→ OKならcommit/push+進捗表更新 / NGなら`NEXT_SESSION.md`に引き継ぎ → `/end`。

**終了条件(直近の`/start`・`/full_loop`以降の1ループ単位、`loop_guard.js`が`.claude/loop_state.md`に算出——この数値が真実)**: (1)タスク完了 (2)連続3回失敗(`.claude/loop_failures.txt`に記録、成功で0リセット) (3)コスト$24超 (4)ターン数30到達。停止時は新規着手せず(a)`NEXT_SESSION.md`更新(b)マスタープラン進捗表更新(c)可能ならcommit/push、の順で締める。

**運用ルール(詳細は`docs/archive/マスタープラン_作業ログ.md`「T3-73f」)**: ユーザー確認が要る場面(`AskUserQuestion`・着手可否・終了報告・リスク操作)は`PushNotification`でも通知。**モデル分担ルール(2026-08-08夜 改訂、恒久)**: **親セッションは既定でSonnet 5で起動する**(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** 根拠は`docs/token_reduction_report_20260808.md` §2・§5——実測でOpus親は中央コンテキスト18.6万・200k超27.9%に達し推定コストの47%を単独で占めたのに対し、Sonnet親は中央8.6万〜11.6万・200k超ゼロ。単価差1.7倍に対し実測差は約3倍。**タスク選定はモデルで分岐させない**: 依存が満たされた`⚠️上位モデルで実施`タスクがあればそれを優先し(**親のモデルに関わらず`architect`へ委譲**、成果物は設計書+タスク分解のみでコードは書かせない)、無ければ通常タスクへフォールバックする(実装は`implementer`、検証は`verifier`)。旧「上位モデル起動時は⚠️タスク以外に着手しない」(2026-07-28・07-29)および「親は常に上位モデルである前提」(2026-08-08昼)は**いずれも廃止**。`architect`を呼ぶ4条件がそのままOpusへのエスカレーション条件になる。**この分担は`.claude/agents/`のサブエージェントで実行する**: 設計・原因究明=`architect`(opus)、コード実装=`implementer`(sonnet)、検証=`verifier`(sonnet)。親セッションは選定・判断・ユーザー確認・commit/push/デプロイのみを担い、**コードの実装と検証は自分で行わず担当エージェントに委譲する**(モデルは各定義の`model:`で自動選択されるので`Agent`ツールに`model`を渡さない)。`architect`を呼ぶのは「⚠️上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。委譲先は`CLAUDE.md`の文脈を持たないため、**日本語で報告する指示と確定済み仕様をプロンプトに書き出して渡す**。デプロイ・push・本番データ削除は委譲せず親がユーザー許可を得て実行する(分類器ブロックの回避目的の委譲は禁止)。詳細は`/full_loop`スキル§サブエージェントへの委譲。開始/終了手順は`/start`・`/end`スキルが正本。

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
- **サブエージェントの濫用禁止**: Opus 5は委譲しすぎる傾向がある。数回のツール呼び出しで自分が終えられる作業、および検証目的の委譲はしない(詳細は§日次改修ループ運用ルール)。

## 統計解析・予測機能の実装ルール

正本は`statistics_feature_design.md`(絶対規則§0、構成マップ§3〜7、データ規則§1.3/3.5/7.1、テスト§9)。食い違えば設計書優先、**実装前に必ず該当節を読む**。要点: 数値計算(回帰・PCA・GP・EI・検定)はDartローカル実装でGeminiに計算させない、設計書に無いフィールド名等を発明しない、Phase順(§10)厳守、統計量は点推定+不確実性をセット表示。
