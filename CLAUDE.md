# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context & Status

**BeanBase 2.0** is a personal Flutter app for logging coffee brews, managing equipment master data, and analyzing taste data (PCA + AI interpretation). It targets Web (Chrome, the primary verification target) and mobile.

The project was originally developed with Google Antigravity; its main surviving convention is the `[Antigravity]` logging prefix used throughout the codebase. Development is tracked in numbered **Cycles** documented under `docs/` (older cycles in `docs/archive/`).

**Current status (latest = Cycle 19, "Sheets revert", completed 2026-07-03):**

- **Storage backend is Google Sheets** via a GAS (Google Apps Script) Web App. All CRUD goes through the `DataService` abstraction (`lib/services/data_service.dart`); the active implementation is `SheetsService` (`lib/services/sheets_service.dart`). Switching backends is a one-line change in `dataServiceProvider`.
- **Images are stored in Google Drive**, uploaded via the same GAS Web App (`ImageService` POSTs base64 to the GAS endpoint, which saves to Drive and returns a shareable URL stored in Sheets).
- **Firestore code is legacy**: `FirestoreService`, `FirestoreMigrator`, and `firebase_options.dart` remain from Cycle 18 but are not used at runtime. Do not extend them unless a task explicitly says so.
- The large-scale renovation is tracked in **`docs/改修マスタープラン.md`** (single source of truth for phases, tasks, and progress). Session handover lives in **`NEXT_SESSION.md`**. Next up: Phase 1 (Cycle 20), screen/navigation restructure.

## 毎ループの読み取り最小セット(2026-07-29、トークン削減のため整理)

1ループで**全読みしてよいのは以下だけ**。過去の記録はすべてアーカイブへ分離済みなので、必要になったとき **ID・日付・キーワードで grep して該当箇所だけ**読む(全読み禁止)。

| 毎回読む(全読み可) | 用途 |
|---|---|
| `CLAUDE.md`(本ファイル) | 規約 |
| `NEXT_SESSION.md` | 引き継ぎ。**直近1セッション分の作業ログのみ**を保つ |
| `docs/改修マスタープラン.md` §2・§3の**未完了行** | 当日タスクの選定 |
| `rules/verification.md` | 検証フロー+**教訓インデックス**(1行見出しのみ) |
| `.claude/loop_state.md` / `.claude/loop_failures.txt` | しきい値確認 |

| 通常は読まない(必要時に grep) | 中身 |
|---|---|
| `rules/lessons_archive.md` | 教訓の全文(インデックスの `L37` 等で引く) |
| `docs/archive/マスタープラン_完了タスク.md` | 完了タスク行の詳細(タスクIDで引く) |
| `docs/archive/マスタープラン_作業ログ.md` | 日付順の作業ログ(日付・IDで引く) |
| `docs/archive/NEXT_SESSION_log.md` | 過去セッションの作業ログ |
| `statistics_feature_design.md` ほか各設計書 | 統計・購入履歴・購入店・焙煎度スライダー。**該当タスクを実装するときだけ**、必要な節だけ読む |

追記も同じ方針で行う: 完了タスクの実装詳細は上記アーカイブへ、教訓は `rules/lessons_archive.md` 末尾へ足し、毎回読むファイルは短いまま保つ。

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

# Regenerate code after model changes (json_annotation / riverpod_generator)
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

State management is Riverpod; persistence is Google Sheets (reverted from Firestore in Cycle 19).

### Data Flow (current)
- `DataService` (`lib/services/data_service.dart`) — abstract CRUD contract for all entities (records, beans, grinders, drippers, filters, methods, pouringSteps).
- `SheetsService` (`lib/services/sheets_service.dart`) — the active implementation. Talks to a GAS Web App (`kGoogleSheetsApiUrl`). Handles Japanese-key sheets; numeric IDs from Sheets must be cast to String.
- `dataServiceProvider` — the single switch point for the backend. Data is exposed via `FutureProvider`s in `lib/providers/data_providers.dart`.
- When the GAS script is updated, a **new deployment URL** is issued — update `kGoogleSheetsApiUrl` accordingly.

### Legacy (do not extend without explicit instruction)
- `FirestoreService`, `FirestoreMigrator` (Cycle 18 remnants). If a task requires touching Firestore, run `flutterfire configure` first to regenerate `firebase_options.dart` (committed values may be placeholders).

### Navigation
`MainLayout` (`lib/layout/main_layout.dart`) wraps every screen via `MaterialApp.builder`. Desktop (≥640px): `NavigationRail`; mobile: `NavigationBar`. Navigation uses `navIndexProvider` (StateProvider) and a global `NavigatorKey` (`lib/utils/nav_key.dart`) with `pushAndRemoveUntil`. Phase 1 of the renovation will restructure this into ~22 screens — see `docs/改修マスタープラン.md` §4.

### Models
All models in `lib/models/` use `json_annotation` + `json_serializable`. Generated files are `*.g.dart`. After any model change, regenerate with `build_runner build`.

### Services
| Service | Purpose |
|---|---|
| `SheetsService` (via `DataService`) | CRUD for all data, via GAS Web App |
| `ImageService` | Upload images to Google Drive via GAS (web: bytes / mobile: file path), stores the returned URL |
| `AiAnalysisService` | Calls Gemini API (gemini-2.5-flash → 2.0-flash-lite → 1.5-flash fallback) to interpret PCA components |
| `StatisticsService` | PCA and KPI computation using `ml_linalg` |
| `FirestoreService` | **Legacy** — unused at runtime |

## Verification Rules

Detailed rules live in `rules/verification.md` — follow them before submitting any change. Summary: `flutter analyze` (zero new issues) → `flutter test` (all pass) → `flutter run` (no exceptions, no overflow stripes, external services connect) → visual verification in the browser.

**Key invariants:**
- When modifying UI or functionality for any master type, apply changes to **all master tabs/screens** (Bean, Grinder, Dripper, Filter — and Method where applicable) — never just Bean.
- Log all key actions and external service interactions with the `[Antigravity]` prefix: `debugPrint('[Antigravity] Action: ...')`. Wrap external calls in try/catch and log errors the same way.
- ID fields from external data (Sheets returns numeric IDs as int/double) must be explicitly cast via `.toString()` in `fromJson` to prevent `type 'int' is not a subtype of type 'String?'` crashes. Guard against empty IDs.
- The Gemini API key is stored client-side via `shared_preferences` (key `gemini_api_key`), set on the Settings screen — never commit it.
- Agent sandbox environments may block outbound traffic to GAS/Drive; final connectivity must be verified by the user running `flutter run` locally when in a sandbox.

## Response Language & Documentation Conventions

**日本語出力を徹底する(2026-07-29改訂)。** 「日本語で応答する」はチャット返信だけでなく、この作業で生成するあらゆる**出力**(=コードの識別子以外で人が読むテキスト全般)に及ぶ。範囲を以下に明示する。

- **チャット応答**: 既定は日本語(ユーザーが英語等を明示的に指定した場合を除く)。
- **ユーザー向けUI文言(最重要)**: `SnackBar`/`AlertDialog`/エラーメッセージ等、画面に表示される文字列は日本語で書く。**「英語のままでも動くから」という理由で放置しない**(2026-07-29に`lib/services/image_service.dart`の一括画像インポート結果ダイアログ、`lib/services/ai_analysis_service.dart`の`analyzeComponents`のAI解釈失敗メッセージが英語のまま本番に残っていたのを発見・修正した実例あり。ダイアログのタイトルだけ日本語で本文が英語、のような**部分的な日本語化は見落としやすいので特に注意**)。
- **ログ出力**: `debugPrint('[Antigravity] ...')`の`[Antigravity]`はプロジェクト由来の固有表記としてそのまま英字で残すが、**その後ろのメッセージ本文は日本語で書く**(`rules/verification.md`の教訓と統一)。
- **ドキュメント**: `NEXT_SESSION.md`・`docs/改修マスタープラン.md`・`rules/verification.md`の教訓・3点セット文書(`implementation_plan.md`/`walkthrough.md`/`task.md`)はすべて日本語。**3点セット文書は簡単な質問や情報収集のためのタスクでは生成しない。** 複雑なコード変更・新機能追加など生成が妥当な場合のみ、まずユーザーの明示的な許可を得たうえで新規フォルダ`docs/cycle_<N>_<english_topic>/`に保存する(フォルダ名の`<english_topic>`部分のみ既存慣習どおり英語でよい)。
- **commit メッセージ・PR タイトル/本文**: 日本語で書く。ただしハーネスが自動付与する`Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`等の固定トレーラー行はシステム側テンプレートのため英語のまま変更しない。
- **`AskUserQuestion`・`PushNotification`の文面**: 日本語。
- **サブエージェント(`Agent`ツール)への委譲時**: 新規サブエージェントはこのファイルの文脈を持たないため、プロンプト中で明示的に「日本語で報告して」等の指示を含める(委譲先が英語で作業・報告してしまうのを防ぐため)。

**例外(翻訳しない)**: コード上の識別子(クラス名・変数名・関数名・ファイル名)、ライブラリ/API/技術用語などの固有名詞、`[Antigravity]`ログプレフィックスそのもの、ハーネスが要求する固定コミットトレーラー。これらは無理に日本語化しない。

## Cycle Workflow

Development proceeds in numbered Cycles. When starting a new cycle, check the highest existing cycle number under `docs/` and `docs/archive/` and increment — never reuse or skip numbers.

## 日次改修ループ運用ルール

大規模改修は **1日1回のループ** で進める。全体設計・タスク・進捗・運用詳細は **`docs/改修マスタープラン.md` が単一の真実**。毎日のタスクは同書 §3 の細分化タスク表から「依存が満たされた最上位のタスク」を選ぶ。

**1ループの流れ:** `/start` → マスタープランから当日タスク選択 → 実装 → 検証(`flutter analyze`→`test`→`run`)→ 判定 → OKなら commit/push + 進捗表更新 / NGなら `NEXT_SESSION.md` に引き継ぎ → `/end`。

**終了条件 — 次のいずれかに達したら必ず停止:**
1. **タスク完了** — タスク表に定義された終了条件を満たした。
2. **連続3回失敗** — 検証(`analyze`/`test`/`run`)でエラー。失敗するたび `.claude/loop_failures.txt` を `<ループ識別子> <回数>` 形式で +1(成功で 0 にリセット。識別子は `.claude/loop_state.md` の「ループ識別子」の値をそのまま使う。新しいループが始まる=識別子が変わると自動的に 0 扱い)。
3. **1ループあたりのコストが $24 超** / 4. **1ループあたりのターン数が 30 到達**(2026-07-25ユーザー指示によりコスト・ターン数・連続失敗のすべてを「当日累計」から「1ループ単位」に変更。「1ループ」は直近の `/start` または `/full_loop` 呼び出し以降を指し、次の `/start`・`/full_loop` が呼ばれるたびリセットされる。境界が検出できない場合のみ従来どおり当日累計にフォールバック) — `loop_guard.js` が transcript から算出。**この数値が真実**(自前で数えない)。

**ガードレール:** `.claude/hooks/loop_guard.js`(UserPromptSubmit / Stop フック、`.claude/settings.json` で有効化)が毎ターン本ループのコスト・ターン数を `.claude/loop_state.md` に出力し、しきい値超過時は停止を指示する。

**停止時の作法:** 新規着手はせず、(a) `NEXT_SESSION.md` 更新、(b) マスタープラン進捗表更新、(c) 可能なら commit/push、の順で締める。

**ユーザーへの依頼・確認は必ずプッシュ通知する(2026-07-25ユーザー指示):** `AskUserQuestion` での質問、着手可否の確認、終了条件到達の報告、削除等リスクのある操作の事前説明など、ユーザーの反応・判断を待つ場面では、その内容とあわせて `PushNotification` ツールでも通知する。`/loop` によるcron定期実行はユーザーが画面を見ていない前提のため、チャット上の文面だけでは気づかれない可能性があるため。

**モデル分担ルール(2026-07-28ユーザー指示、恒久)**: **上位モデル(Opus等)が担当するのは「方針検討」と「実装内容の検討」まで。実装は必ず下位モデル(Sonnet 5)に回す。** 上位モデル指定タスク(`⚠️上位モデルで実施`)の成果物は常に **設計書 + 実装タスクへの分解** であり、コードは書かない。そのかわり上位モデルは、下位モデルが設計判断をせずに済む粒度(フィールド名・シート列名・画面ID・引数表・データ突合規則・過去に踏んだ地雷への注意)まで情報を確定させる責任を負う。`/full_loop`は既定では`⚠️上位モデルで実施`タスクを選ばないが、**上位モデルで起動されている場合はそれらを優先的に選んでよい**(ただしその場合も実装はせず設計とタスク分解のみ)。

セッション開始/終了の具体的な手順は `/start`・`/end` スキル(`.claude/skills/start/`・`.claude/skills/end/`)に定義されている。二重管理を避けるため、ここには詳細を書かない。

## トークン運用規約(2026-08-02、実測に基づく)

1ループのコストは **「リクエスト数 × 平均コンテキスト長」** でほぼ決まる(実測: cacheRが全体の6割)。
さらに **コンテキストが200kトークンを超えると単価が約2倍**になる。以下を必ず守る。詳細と実測値は `docs/token_optimization_design.md`。

1. **独立したツール呼び出しは1メッセージにまとめる**(直近ループでは143リクエスト中125が1ツールずつの直列実行だった)。
2. **一度Readしたファイルを再Readしない**。特に**Edit/Write直後の確認Readは禁止**(失敗すればツールがエラーを返すため確認不要)。
3. **300行超のファイルは全文Readしない**。`Grep`(必要なら`-A`/`-B`)か `Read(offset/limit)` で必要箇所だけ読む。
4. **検証コマンドは短出力形**(`rules/verification.md` §必須検証フロー)を使う。**失敗したときだけ**詳細を取り直す。
5. **ブラウザ確認は `get_page_text`/`find`/`read_console_messages(pattern指定)` を優先**し、スクリーンショットは最終確認の1〜2枚に限る(1枚≒1.5kトークンが以後ずっとコンテキストに残る)。

## 統計解析・予測機能の実装ルール

正本は `statistics_feature_design.md`。本節と食い違う場合は設計書が優先。

### 絶対規則

- 数値計算 (回帰・PCA・GP・EI・検定) は Dart ローカル実装。Gemini に計算させない。Gemini は計算済み数値の日本語解釈のみ (プロンプトは設計書 §8 のテンプレート固定)。
- 設計書に無いフィールド名・シート名・クラス名を発明しない。不明点は実装を止めてユーザーに質問。
- Phase 順 (設計書 §10) を厳守: 0 数値基盤 → 1 データ基盤(F6) → 2 回帰(F1) → 3 PCA拡張(F2) → 4 好み(F5) → 5 提案(F3) → 6 GP(F4)。各 Phase はテスト全パスまで次に進まない。
- 統計量は必ず点推定+不確実性 (SE/CI/予測区間) をセット表示。

### 構成マップ

- 数値基盤: `lib/services/math/` — eigen.dart (Jacobi 書き直し版 `eigenSymmetric`、旧 `_jacobiEigenvalueAlgorithm` は削除), linear_solve.dart (Cholesky), distributions.dart (erf/t分布CDF/分位点), design_matrix.dart
- サービス: regression_service.dart / preference_service.dart / suggestion_service.dart / gp_service.dart / migration_service.dart。statistics_service.dart は PCA を相関行列ベースに改修
- モデル追加: origin_master.dart / analysis_snapshot.dart / recipe_suggestion.dart。BeanMaster に originId・roastDate、CoffeeRecord に originId と `brewRatio` getter (保存しない)
- シート追加: origin_master / analysis_history / recipe_suggestions。GAS は `gas/Code.gs` としてリポジトリ管理 (clasp)、シート名ホワイトリスト `ALLOWED_SHEETS` 必須
- UI 配置 (決定事項、設計書§1.2.1): F1/F2/F5 (regression_section / pca_detail_panel / preference_section) は統計画面。F3 (recipe_suggestion_card) はダッシュボード。F4 (gp_explorer_section) は統計画面ではなく**抽出画面(030)**

### データ規則

- 産地は OriginMaster (選択式) が正。自由入力 origin は後方互換のため残すが新規参照は originId 経由
- 焙煎度は `roastOrdinalMap` (encoding.dart) で順序値 1–5 に変換。未知値は欠測として行除外+件数表示
- F5 プロファイルは抽出記録の保存成功のたび自動再計算し analysis_history に保存 (失敗しても記録保存は妨げない)
- 最小データ条件 (設計書 §1.3) を下回るときは計算せず固定文言の案内を表示

### テスト

- 数値テストの期待値・許容誤差は設計書 §9 の値をそのまま使う (例: eigen `[[2,1],[1,2]]`→{3,1}、回帰10行データの β/SE/R²、t分位点)
- 既存69テストのパス維持。PCA 相関行列化で期待値が変わる場合のみ理由コメント付きで更新可
