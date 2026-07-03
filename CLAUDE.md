# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context & Status

**BeanBase 2.0** is a personal Flutter app for logging coffee brews, managing equipment master data, and analyzing taste data (PCA + AI interpretation). It targets Web (Chrome, the primary verification target) and mobile.

This project was originally developed with **Google Antigravity** (agent persona "Antigravity", global rules in `GEMINI.md`). `GEMINI.md` is no longer present in the repo — its conventions survive in `rules/verification.md` and `.agent/rules/verification.md`, and the `[Antigravity]` logging prefix remains in the codebase. Development is tracked in numbered **Cycles**; each cycle is documented under `docs/` (`implementation_plan.md`, `task.md`, `walkthrough.md`). Older cycles are archived in `docs/archive/`.

**Current status (latest = Cycle 18, "Firestore migration", completed 2026-06-28):**
- Storage was migrated from the original **Google Sheets** backend to **Firebase Firestore**. The legacy `SheetsService` (`lib/services/sheets_service.dart`) still exists but is only used by the one-time migration script — all app reads/writes now go through `FirestoreService`.
- A one-time migration is triggered manually by the user via the **cloud icon (☁️) on the Home screen**, which runs `FirestoreMigrator` (`lib/utils/firestore_migrator.dart`) to batch-copy all Sheets data into Firestore.
- Multi-tenant schema (`users/{userId}/...`) is in place, currently hardcoded to `userId = 'default_user'`; auth is the intended future direction.
- **Next steps** (`NEXT_STEPS.md`): cascade-delete Firebase Storage images when a master is deleted; verify mobile layouts on real devices; extract a reusable image-upload component (DRY); brush up the Statistics page.
- The Firebase project is `beanbase-app-2016` (`firebase.json`). Agent sandbox environments block outbound Firebase traffic, so final Firestore connectivity must be verified by the user running `flutter run` locally.

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

**BeanBase 2.0** is a Flutter coffee brewing journal app targeting Web (Chrome) and mobile. State management is Riverpod; persistence is Firestore (migrated in Cycle 18).

### Firestore Schema (multi-tenant)
All data lives under `users/{userId}/` with subcollections:
- `records` — `CoffeeRecord` brewing logs
- `beans`, `grinders`, `drippers`, `filters` — equipment master data
- `methods` — brew methods
- `pouringSteps` — steps linked to a method via `methodId` field

`FirestoreService` (`lib/services/firestore_service.dart`) wraps all Firestore CRUD. The provider is `firestoreServiceProvider`. Data is exposed via `FutureProvider`s in `lib/providers/data_providers.dart`.

### Navigation
`MainLayout` (`lib/layout/main_layout.dart`) wraps every screen via `MaterialApp.builder`. On desktop (≥640px) it renders a `NavigationRail`; on mobile it renders a `NavigationBar`. Navigation is driven by `navIndexProvider` (StateProvider) and uses a **global `NavigatorKey`** (`lib/utils/nav_key.dart`) with `pushAndRemoveUntil` to simulate top-level tabs.

### Models
All models in `lib/models/` use `json_annotation` + `json_serializable`. Generated files are `*.g.dart`. After any model change, regenerate with `build_runner build`.

### Services
| Service | Purpose |
|---|---|
| `FirestoreService` | CRUD for all Firestore collections |
| `ImageService` | Upload images to Firebase Storage; fallback to local path on mobile |
| `AiAnalysisService` | Calls Gemini API (gemini-2.5-flash → 2.0-flash-lite → 1.5-flash fallback) to interpret PCA components |
| `StatisticsService` | PCA and KPI computation using `ml_linalg` |

### Image Handling
Images are stored in Firebase Storage under `bean_images/`. `ImageService.uploadImage()` handles both web (bytes) and mobile (file path). The `BeanImage` widget (`lib/widgets/bean_image.dart`) renders images with platform-specific implementations.

## Verification Rules (from `rules/verification.md`)

Before submitting any change:
1. `flutter analyze` — fix all errors and warnings
2. `flutter test` — all tests must pass
3. `flutter run` — verify the app launches, no exceptions/errors in console, no UI overflow (yellow/black stripes), and external services (Firestore, Firebase Storage) connect successfully
4. Visually verify behavior in the browser (e.g. that an image-upload button is actually clickable), not just by reading code

**Key invariants:**
- When modifying UI or functionality for any master type, apply changes to **all four tabs** (Bean, Grinder, Dripper, Filter) — never just Bean.
- Log all key actions and external service interactions with the `[Antigravity]` prefix: `debugPrint('[Antigravity] Action: ...')`. Wrap external calls in try/catch and log errors the same way.
- When adding or migrating Firestore, run `flutterfire configure` to regenerate `firebase_options.dart` with real values (the committed values may be placeholders in sandboxed environments).
- ID fields from external data (Sheets returns numeric IDs as int/double) must be explicitly cast via `.toString()` in `fromJson` to prevent `type 'int' is not a subtype of type 'String?'` crashes. Guard against empty IDs to avoid Firestore path errors.
- The Gemini API key is stored client-side via `shared_preferences` (key `gemini_api_key`), set on the Settings screen — it is not committed.

## Response Language & Documentation Conventions

These carry over from the project's original global `GEMINI.md` (`C:\Users\winni\.gemini\GEMINI.md`) and govern how to communicate and document work:

- **Respond in Japanese by default**, unless the user asks otherwise.
- The three project documents — `implementation_plan.md` (実装計画), `walkthrough.md` (修正内容の確認), `task.md` (タスクリスト) — are **written in Japanese**.
- **Do not generate these documents for simple questions or information-gathering tasks** that don't involve complex code changes or new features. Skipping docs is especially recommended when running on a Fast model. When docs *are* warranted, get the user's explicit permission first.
- When generating them, save all three to a **new folder under `docs/`**, named with an English topic for the chat, spaces replaced by underscores (the cycle convention `docs/cycle_<N>_<name>/` follows this).

## Cycle Workflow

Development proceeds in numbered Cycles. When starting a new cycle, check the highest existing cycle number under `docs/` and `docs/archive/` and increment correctly — do not reuse or skip numbers. Each cycle gets its own `docs/cycle_<N>_<name>/` folder with `implementation_plan.md`, `task.md`, and `walkthrough.md`. Handover notes for the next session live in `NEXT_SESSION.md` / `NEXT_STEPS.md` at the repo root.

## 日次改修ループ運用ルール (BeanBase 改修)

進行中の大規模改修は **1日1回のループ** で進める。全体設計と進捗は **`docs/改修マスタープラン.md`** が単一の真実とし、毎日のタスクはここから選ぶ。

**1ループの流れ:** `\start` → マスタープランから当日タスク選択 → 実装 → 検証(`flutter analyze`→`test`→`run`) → 判定 → OKなら commit/push + walkthrough と進捗表更新 / NGなら `NEXT_SESSION.md` に引き継ぎ書を更新 → `\end`。

**終了条件 — 次のいずれかに達したら必ず停止すること:**
1. **タスク完了** — その日の終了条件(各Cycle冒頭に明記)を満たした。
2. **連続3回失敗** — 「失敗」=実装後の検証(`analyze`/`test`/`run`)でエラーが出ること。失敗するたび `.claude/loop_failures.txt` の整数を+1し、成功したら0にリセットする。3に達したら停止。
3. **当日コストが $1.5 超** — `loop_guard.js` が transcript のトークンを種別単価で重み付け合算して算出。
4. **当日ターン数が 30 に達した** — 同フックが算出。

**ガードレールの仕組み:** `.claude/hooks/loop_guard.js`(Stop / UserPromptSubmit フック)が毎ターン現セッションの transcript を解析し、当日のコスト・ターン数を `.claude/loop_state.md` に書き出す。UserPromptSubmit 時には状態を文脈へ注入し、しきい値超過時は「新規改修を止め、引き継ぎ書と進捗表を更新して終了せよ」と指示する。**コスト・ターン数の数値はこのフックが真実**(自前で数えない)。連続失敗は自分で `loop_failures.txt` を更新する。

**停止時の作法(graceful shutdown):** 終了条件に達したら、新規の改修着手はせず、(a)`NEXT_SESSION.md` に「当日やったこと・残課題・次の着手点」を更新、(b)`docs/改修マスタープラン.md` の進捗表を更新、(c)可能なら commit/push、を行ってから終了する。

## Session Commands

- `\start` — run `git pull`, summarize pending tasks
- `\end` — summarize next steps, `git push`, update rules with any new lessons, ensure cycle numbering in `docs/` is sequential
