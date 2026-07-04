# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-07-04（Cycle 20 T1-1a 完了）

## 1. 当日やったこと（2026-07-04）

**Cycle 20 / T1-1a 完了**: 画面ID enum・ルート定数の定義、ナビ再編方針の決定。

- `lib/routing/app_screen.dart` を新規追加: 22画面ぶんの `AppScreen` enum（画面ID・和名・`routePath`）を定義
- ナビ再編方針を決定（同ファイルのdocコメントに記載）:
  - `navIndexProvider` はトップレベルタブ(001/010/002/030/040 の5つ, `AppScreen.topLevelTabs`)にのみ使用
  - 090(設定)はボトムナビ非表示・歯車アイコン等からの遷移のみ
  - 詳細/編集/新規画面は既存の `navigatorKey` 経由の push/pop のみで、navIndexProviderは変更しない
- この環境に Flutter SDK が無かったため、`flutter_linux_3.44.4-stable.tar.xz` をスクラッチパッドに導入して検証（`.metadata`のDart制約 `^3.10.7` を満たすバージョンを選定）。永続化はされないため次回セッションでも同様の導入が必要な可能性あり。
- `flutter analyze` → 新規追加ファイルにより増えたissueは0件（既存84件のまま）
- `flutter test` → 17件全パス
- `flutter run` は未実施（今回の変更は既存画面に未接続の新規ファイルのみのため、マスタープランの実装日方針に従いスキップ）
- ユーザー指示によりコスト上限を $1.5 → $12 に引き上げ（`.claude/hooks/loop_guard.js` / `CLAUDE.md` / 本マスタープラン §5・§5.1 を統一）
- **PR作成**: [#2](https://github.com/kazuki21057/bean-base/pull/2)（`claude/session-start-8d308k` → `main`）。マージ待ち。
- **本日の終了条件**: 当日コストが新上限 $12 も超過($13.273)したため、新規改修を打ち切り本書を更新して終了。

## 2. 次回の着手点

**Phase 1 — 画面構成・ナビ再編（Cycle 20〜22）** 継続。次は T1-1b。

| ID | タスク | 依存 |
|---|---|---|
| T1-1b | 全22画面のプレースホルダ画面生成（`AppScreen` enum を使用） | T1-1a ✅ |
| T1-1c | `MainLayout`(NavigationRail/Bar)を新ナビ構成に再マップ | T1-1b |
| T1-2a | 抽出030の画面骨組み | T1-1c |

## 2.5 自動ループのセットアップ状況

### ⏸ クラウドルーティン（現在【無効化中】）
- ID: `trig_01W3iqfgRZYaVZvkY8Jc83gg`
- 再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。

## 3. 日次ループの回し方（毎回）
1. `\start`（git pull・当日タスク確認）
2. `docs/改修マスタープラン.md` から当日タスクを選ぶ
3. 実装 → 検証（`flutter analyze`→`test`→`run`）
4. 判定: OK→commit/push＋進捗表更新 / NG→本書を更新して翌日へ
5. 失敗するたび `.claude/loop_failures.txt` を+1（成功で0リセット）
6. 終了条件に達したら新規着手せず、本書と進捗表を更新して `\end`

## 4. 開発再開時のプロンプト例
> 「\start を実行し、Phase 1（Cycle 20）を開始してください。T1-1 から着手します。」
