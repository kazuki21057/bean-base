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

- **Respond in Japanese by default**, unless the user asks otherwise.
- The three cycle documents — `implementation_plan.md` (実装計画), `walkthrough.md` (修正内容の確認), `task.md` (タスクリスト) — are written in Japanese.
- **Do not generate these documents for simple questions or information-gathering tasks.** When they are warranted (complex code changes / new features), get the user's explicit permission first, then save them to a new folder `docs/cycle_<N>_<english_topic>/`.

## Cycle Workflow

Development proceeds in numbered Cycles. When starting a new cycle, check the highest existing cycle number under `docs/` and `docs/archive/` and increment — never reuse or skip numbers.

## 日次改修ループ運用ルール

大規模改修は **1日1回のループ** で進める。全体設計・タスク・進捗・運用詳細は **`docs/改修マスタープラン.md` が単一の真実**。毎日のタスクは同書 §3 の細分化タスク表から「依存が満たされた最上位のタスク」を選ぶ。

**1ループの流れ:** `/start` → マスタープランから当日タスク選択 → 実装 → 検証(`flutter analyze`→`test`→`run`)→ 判定 → OKなら commit/push + 進捗表更新 / NGなら `NEXT_SESSION.md` に引き継ぎ → `/end`。

**終了条件 — 次のいずれかに達したら必ず停止:**
1. **タスク完了** — タスク表に定義された終了条件を満たした。
2. **連続3回失敗** — 検証(`analyze`/`test`/`run`)でエラー。失敗するたび `.claude/loop_failures.txt` を `<当日日付> <回数>` 形式で +1(成功で 0 にリセット。日付が変わると自動的に 0 扱い)。
3. **当日コストが $24 超**(2026-07-21ユーザー指示により$12から2倍に変更) / 4. **当日ターン数が 30 到達** — `loop_guard.js` が transcript から算出。**この数値が真実**(自前で数えない)。

**ガードレール:** `.claude/hooks/loop_guard.js`(UserPromptSubmit / Stop フック、`.claude/settings.json` で有効化)が毎ターン当日コスト・ターン数を `.claude/loop_state.md` に出力し、しきい値超過時は停止を指示する。

**停止時の作法:** 新規着手はせず、(a) `NEXT_SESSION.md` 更新、(b) マスタープラン進捗表更新、(c) 可能なら commit/push、の順で締める。

セッション開始/終了の具体的な手順は `/start`・`/end` スキル(`.claude/skills/start/`・`.claude/skills/end/`)に定義されている。二重管理を避けるため、ここには詳細を書かない。

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
