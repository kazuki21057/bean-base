# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-22(Sonnet 5、有人`/full_loop`(引数なし)。**T5-B13-4完了・T5-B13(束1〜4)全体完了・commit済み**。詳細は「3. 直近の作業ログ」参照)

> 本書の構成(2026-07-29改訂): 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに直近1セッション分の作業ログだけを残す。それ以前はdocs/archive/NEXT_SESSION_log.mdへ退避済み。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> 書き足しルール: /end・/full_loopで当日ログを追記する際は「3. 直近の作業ログ」の古い節をアーカイブ先頭へ移してから新しい節を1件だけ置く(本書は常に1件)。タスク定義・進捗の正本はdocs/改修マスタープラン.md。

## 1. 現状サマリ

- **【2026-08-22・有人`/full_loop`(引数なし)】T5-B13-4(LocalDbService束4: `analysis_history`/`recipe_suggestions`の5メソッド+`dataServiceProvider`配線)を`implementer`が実装、束1〜3のヘルパー・rowid並び順・upsert方式を踏襲。`verifier`が独立検証(`verify.ps1 -Task T5-B13`〈親グループID、詳細はL181〉全項目green・受入テスト含め全pass)。`adversary`敵対的レビューでCritical/Major指摘なし(Minor1件はその場で修正)。**T5-B13(束1〜4)全体が完了**。commit済み(push実施、下記参照)。**
- 進行中はマスタープラン Phase 5(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- Phase 5トラックA(開発運用基盤)完了済み(38件、詳細はdocs/改修マスタープラン.md §3参照)。トラックCはT5-C3完了済み(1件)。正本はdocs/android_release/開発運用基盤設計.md・検証強化設計.md・リリース計画書.md。agy委譲の正本はdocs/antigravity_delegation_design.md(§7実績ログ・§9設計)。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASはgas/Code.gsをclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: docs/bean_purchase_design.md(追加購入・購入履歴)、docs/store_master_design.md(購入店マスタ)。
- モデル分担ルール(2026-08-08改訂、恒久): 親セッションは既定でSonnet 5で起動する(/model sonnet)。Opus 5はarchitectサブエージェント経由でのみ使い、親セッションでは使わない。タスク選定はモデルで分岐させない。詳細・根拠はCLAUDE.md§日次改修ループ運用ルール・docs/token_reduction_report_20260808.md。
- デプロイ・push運用ルール(2026-08-08改訂、恒久): firebase deploy・clasp push/clasp redeployは実行前に必ずチャットでユーザーの明示的な許可を得る。git pushはverifierが全項目パスを報告済み(またはコード変更を含まない)なら確認不要(未検証・検証NGのpushと--force系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細はrules/lessons_archive.md L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **【2026-08-22最新】T5-B13(束1〜4)全体完了。次点はT5-B14(画像のローカル保存、依存T5-B13-4充足)。** `path_provider`は既に依存にあるので追加不要。public版は`ImageService`をDrive→ローカルに差し替える(終了条件: 画像を登録→再起動後も表示される、受入: `test/acceptance/t5_b14_acceptance_test.dart`)。過去セッションの詳細な着手点履歴は`docs/archive/NEXT_SESSION_log.md`「旧『2. 次回の着手点』バックログ」節を参照。
タスクの正本はdocs/改修マスタープラン.md §3。

サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化): .claude/agents/に複数体——architect(設計・原因究明、opus固定)/implementer(実装、sonnet固定)/verifier(検証、sonnet固定)/adversary(敵対的レビュー、sonnet固定)等。/start・/full_loop・/night_loopでは、コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する。architectを呼ぶのは「上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は/full_loopスキル§サブエージェントへの委譲、要約はCLAUDE.md§日次改修ループ運用ルール。

トラックAは完成済み(2026-08-15ユーザー承認済み、以後トラックB本格着手中)。

ユーザー実施待ちで着手不可: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(28豆中24豆の初期購入量(g)入力)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)。**T5-C1(Play Consoleデベロッパー登録$25)は2026-08-10、ユーザーとの相談の結果「優先度は低い」と結論**(トラックB=製品開発が0/43タスクで未着手・40〜60人日規模のため、14日待機はボトルネックにならない。詳細は上記「-5.72」節参照)。急かさなくてよい。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。コンテキスト200k超で単価が約2倍になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約はCLAUDE.md§トークン運用規約、実測と削減設計はdocs/token_optimization_design.md。

Proプラン使用率ログ(2026-08-09追加): ユーザーがセッション開始時・終了時の使用量(%)を申告してくれる場合、docs/token_optimization_design.md §8 に記録する(申告が無いループは書かない)。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.134 当日やったこと(2026-08-22、Sonnet 5、有人`/full_loop`(引数なし)。**T5-B13-4完了・T5-B13全体完了**)

- 依存(T5-B13-3)が充足済みのT5-B13-4(`LocalDbService`束4: 解析・レシピ提案+配線+受入)を選定。方針は束1〜3の踏襲+設計書§7.5.3で確定済みのためarchitectは呼ばず`implementer`へ直接委譲。
- `implementer`が`analysis_history`(5列)・`recipe_suggestions`(12列)の5メソッドを実装、`mappers.dart`へ2テーブル分追記、`dataServiceProvider`(`data_service.dart`)を`LocalDbService`へ配線(両エディションとも`useLocalDb: false`のため挙動不変)。`local_db_service.dart`の`UnimplementedError`が0件(44メソッド完了)。新規`test/db/local_db_service_analysis_test.dart`(8件)・新規`test/acceptance/t5_b13_acceptance_test.dart`(10件、5マスタ+抽出記録+購入履歴+購入店の全CRUD)。`analyze`新規issue0・`test`537件全pass・`build web`成功。
- `verifier`が独立検証。**教訓L181**: `verify.ps1 -Task T5-B13-4`(サブID)で実行すると`acceptance_missing`の誤検知になった(受入テストファイルは束1〜4共通で親グループID`t5_b13`命名のため)。`-Task T5-B13`(親グループID)で再実行し`acceptance.ok: true`を確認、他全項目もgreen。
- T5-B13(束1〜4)全体完了に該当するため`/code-review`(区切り条件)を実行。`adversary`が差分をレビューしCritical/Major指摘0件、Minor1件(コメントのセクション引用ずれ`§7.5.1-2`→正しくは`§11-2`)は親が直接修正(1行・非委譲しきい値内)。
- UI変更なし・`lib/db`層のみのためデプロイ・本番確認は不要と判断。
- 委譲1回ごとの予算チェックポイント($14.4)には未到達(実測$8.37)。
- **次回セッションでやること**: T5-B14(画像のローカル保存、依存T5-B13-4充足)から着手。`path_provider`は既存依存にあるので追加不要。public版の`ImageService`をDrive→ローカルへ差し替える設計・実装が必要(方針は明らかなためarchitect不要、implementerへ直接委譲可)。

> これ以前の作業ログはdocs/archive/NEXT_SESSION_log.mdを参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID trig_01W3iqfgRZYaVZvkY8Jc83gg。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件はCLAUDE.md§日次改修ループ運用ルールと/start・/end・/full_loop・/night_loopスキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
