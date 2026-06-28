# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-06-28（Cycle 19 進行中）

## 1. 当日やったこと（Cycle 19 / Phase 0: データ基盤を Sheets に戻す）
データアクセスを Firestore → **Google Sheets** に差し戻した（T0-1〜T0-3、T0-5 の analyze/test まで）。

- **抽象インターフェース `DataService` を新設**（`lib/services/data_service.dart`）。`SheetsService`/`FirestoreService` 両方に `implements` させ、`@override` 付与。
- **単一の `dataServiceProvider` に集約**。現在は `SheetsService()` を返す。**バックエンド切替はこの1行のみ**で済む構成に。
- 読み取り7プロバイダ（`data_providers.dart`）＋書込9箇所（各画面・`image_service`）を `firestoreServiceProvider` → `dataServiceProvider` に切替。
- **検証**: `flutter analyze` 新規エラー/警告なし（`annotate_overrides` 解消）／`flutter test` **17件全パス**。
- Cycle 19 ドキュメント3点を `docs/cycle_19_sheets_revert/` に作成。マスタープラン進捗表を更新。

## 2. 残課題 / 次回の着手点
- **T0-4b（画像保存の実装）**: 画像保存先は **Google Drive に決定**。実装は **GAS拡張方式**（クライアント直叩きの OAuth を避け、既存 GAS Web App を拡張して画像bytesをDriveへ保存し公開URLを返す）。
  - `ImageService` の Firebase Storage 依存を Drive アップロードに差し替え。Web/モバイル両対応。
  - GAS側: Drive保存 + ファイル共有設定（リンク閲覧可） + `uc?export=view&id=` 形式URL返却。
  - 詳細メモ: `docs/cycle_19_sheets_revert/task.md` の「T0-4 決定」節。
- **T0-5 の run 確認（要ユーザー・ローカル）**: サンドボックスは外部通信不可。ローカルで `flutter run -d chrome` し、Sheets 経由で一覧/登録/編集/削除の疎通を確認。
  - GAS エンドポイント `kGoogleSheetsApiUrl`（`lib/services/sheets_service.dart`）が現在も有効かを併せて確認。
- これらが済めば **Cycle 19 完了** → Phase 1（画面構成・ナビ再編、Cycle 20–22）へ。

## 3. 日次ループの回し方（毎回）
1. `\start`（git pull・当日タスク確認）
2. `docs/改修マスタープラン.md` から当日タスクを選ぶ
3. 実装 → 検証（`flutter analyze`→`test`→`run`）
4. 判定: OK→commit/push＋walkthrough＋進捗表更新 / NG→本書を更新して翌日へ
5. 失敗するたび `.claude/loop_failures.txt` を+1（成功で0リセット）
6. 終了条件に達したら新規着手せず、本書と進捗表を更新して `\end`

## 4. 開発再開時のプロンプト例
> 「\start を実行し、NEXT_SESSION.md を確認。Cycle 19 の残り（T0-4 画像保存先の決定と T0-5 のローカル接続確認）を進めてください。」
