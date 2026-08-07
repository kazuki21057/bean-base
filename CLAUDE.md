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

**運用ルール(詳細は`docs/archive/マスタープラン_作業ログ.md`「T3-73f」)**: ユーザー確認が要る場面(`AskUserQuestion`・着手可否・終了報告・リスク操作)は`PushNotification`でも通知。**モデル分担ルール(恒久、2026-08-05にサブエージェント委譲へ移行)**: 上位モデルは方針・実装内容の検討まで、実装は必ずSonnet 5に回す(`⚠️上位モデルで実施`の成果物は設計書+タスク分解のみでコードは書かない)。**`/start`・`/full_loop`の親セッション(オーケストレーター)は常に上位モデルであることを前提とする(2026-08-08改訂)**。したがって「上位モデルで起動されたか」でタスク選定を分岐させない: 依存が満たされた`⚠️上位モデルで実施`タスクがあればそれを優先し(`architect`へ委譲、成果物は設計書のみ)、無ければ**通常タスクへフォールバックして着手する**(実装は`implementer`、検証は`verifier`)。旧「上位モデル起動時は⚠️タスク以外に着手しない/無ければ何もしない」(2026-07-28・07-29)は、親が自分でコードを書いていた時代の規定であり**廃止**(残すと⚠️タスクが全て依存未充足のときループが止まる)。**この分担は`.claude/agents/`のサブエージェントで実行する**: 設計・原因究明=`architect`(opus)、コード実装=`implementer`(sonnet)、検証=`verifier`(sonnet)。親セッションは選定・判断・ユーザー確認・commit/push/デプロイのみを担い、**コードの実装と検証は自分で行わず担当エージェントに委譲する**(モデルは各定義の`model:`で自動選択されるので`Agent`ツールに`model`を渡さない)。`architect`を呼ぶのは「⚠️上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。委譲先は`CLAUDE.md`の文脈を持たないため、**日本語で報告する指示と確定済み仕様をプロンプトに書き出して渡す**。デプロイ・push・本番データ削除は委譲せず親がユーザー許可を得て実行する(分類器ブロックの回避目的の委譲は禁止)。詳細は`/full_loop`スキル§サブエージェントへの委譲。開始/終了手順は`/start`・`/end`スキルが正本。

## トークン運用規約(実測に基づく)

1ループのコストは**「リクエスト数 × 平均コンテキスト長」**でほぼ決まり、**200kトークン超で単価が約2倍**になる(詳細・実測値は`docs/token_optimization_design.md`)。(1)独立したツール呼び出しは1メッセージにまとめる (2)一度Readしたファイルを再Readしない、**Edit/Write直後の確認Readは禁止**(失敗すればツールがエラーを返す) (3)300行超のファイルは全文Readせず`Grep`(`-A`/`-B`)か`Read(offset/limit)`で必要箇所だけ読む (4)検証コマンドは短出力形(`rules/verification.md`§必須検証フロー)、**失敗したときだけ**詳細を取り直す (5)ブラウザ確認は`get_page_text`/`find`/`read_console_messages(pattern指定)`を優先し、スクリーンショットは最終確認の1〜2枚に限る。

## 統計解析・予測機能の実装ルール

正本は`statistics_feature_design.md`(絶対規則§0、構成マップ§3〜7、データ規則§1.3/3.5/7.1、テスト§9)。食い違えば設計書優先、**実装前に必ず該当節を読む**。要点: 数値計算(回帰・PCA・GP・EI・検定)はDartローカル実装でGeminiに計算させない、設計書に無いフィールド名等を発明しない、Phase順(§10)厳守、統計量は点推定+不確実性をセット表示。
