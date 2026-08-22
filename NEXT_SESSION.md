# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-22(Sonnet 5、有人`/full_loop`「T5-A107とnextsession.mdの整理とtaskBを進めて」。**T5-A107完了(62秒維持)・NEXT_SESSION.md整理・T5-B13を4束へ分割しT5-B13-1/-2完了・mainへpush済み**。詳細は「3. 直近の作業ログ」参照)

> 本書の構成(2026-07-29改訂): 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに直近1セッション分の作業ログだけを残す。それ以前はdocs/archive/NEXT_SESSION_log.mdへ退避済み。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> 書き足しルール: /end・/full_loopで当日ログを追記する際は「3. 直近の作業ログ」の古い節をアーカイブ先頭へ移してから新しい節を1件だけ置く(本書は常に1件)。タスク定義・進捗の正本はdocs/改修マスタープラン.md。

## 1. 現状サマリ

- **【2026-08-22・有人`/full_loop`「T5-A107とnextsession.mdの整理とtaskBを進めて」】T5-A107完了(ユーザー判断でリトライ最大待機時間62秒を維持、コード変更なし)。NEXT_SESSION.mdの1・2節に溜まっていた履歴をアーカイブへ退避し整理。T5-B13(LocalDbService、L)を`architect`が4束(T5-B13-1〜4)へ分割、T5-B13-1(基盤+器具マスタ)・T5-B13-2(豆・購入店・購入履歴)を`implementer`が実装・`verifier`が検証、いずれも全項目greenでmainへpush済み(141c14c→1e97cf4)。委譲1回ごとの予算チェックポイント($14.4)を超過したため、T5-B13-3以降には着手せずセッションを締めた(ユーザーが事前に「多少予算オーバーしてもOK」と許可済み)。integration_testスモークはGAS接続不安定性由来の散発的失敗が残る(詳細は`docs/archive/NEXT_SESSION_log.md`「-5.131」節参照)。**
- 進行中はマスタープラン Phase 5(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- Phase 5トラックA(開発運用基盤)完了済み(38件、詳細はdocs/改修マスタープラン.md §3参照)。トラックCはT5-C3完了済み(1件)。正本はdocs/android_release/開発運用基盤設計.md・検証強化設計.md・リリース計画書.md。agy委譲の正本はdocs/antigravity_delegation_design.md(§7実績ログ・§9設計)。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASはgas/Code.gsをclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: docs/bean_purchase_design.md(追加購入・購入履歴)、docs/store_master_design.md(購入店マスタ)。
- モデル分担ルール(2026-08-08改訂、恒久): 親セッションは既定でSonnet 5で起動する(/model sonnet)。Opus 5はarchitectサブエージェント経由でのみ使い、親セッションでは使わない。タスク選定はモデルで分岐させない。詳細・根拠はCLAUDE.md§日次改修ループ運用ルール・docs/token_reduction_report_20260808.md。
- デプロイ・push運用ルール(2026-08-08改訂、恒久): firebase deploy・clasp push/clasp redeployは実行前に必ずチャットでユーザーの明示的な許可を得る。git pushはverifierが全項目パスを報告済み(またはコード変更を含まない)なら確認不要(未検証・検証NGのpushと--force系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細はrules/lessons_archive.md L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **【2026-08-22最新】T5-B13-1・T5-B13-2完了・push済み。次点はT5-B13-3(`LocalDbService`束3: 抽出記録・メソッド・注湯ステップ、依存T5-B13-2充足)。** T5-B13は`architect`により4束(T5-B13-1〜4)へ分割済み、分割方針・各束の完了条件は`docs/local_db_schema_design.md` §7.5参照。束3実装時は束1・束2で確定した共通規約(rowid並び順・upsert方式・`LocalDbException`文言・共通ヘルパー)を`lib/services/local_db_service.dart`から読んで踏襲すること。束4で`dataServiceProvider`配線+受入テストが入り、`integration_test`スモークの判定が絡む(GAS接続不安定性由来のFAILは束4の失敗に数えない、設計書§7.5.3)。T5-A107は完了済み(GETリトライ待機時間62秒を維持)。過去セッションの詳細な着手点履歴は`docs/archive/NEXT_SESSION_log.md`「旧『2. 次回の着手点』バックログ」節を参照。
タスクの正本はdocs/改修マスタープラン.md §3。

サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化): .claude/agents/に複数体——architect(設計・原因究明、opus固定)/implementer(実装、sonnet固定)/verifier(検証、sonnet固定)/adversary(敵対的レビュー、sonnet固定)等。/start・/full_loop・/night_loopでは、コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する。architectを呼ぶのは「上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は/full_loopスキル§サブエージェントへの委譲、要約はCLAUDE.md§日次改修ループ運用ルール。

トラックAは完成済み(2026-08-15ユーザー承認済み、以後トラックB本格着手中)。

ユーザー実施待ちで着手不可: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(28豆中24豆の初期購入量(g)入力)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)。**T5-C1(Play Consoleデベロッパー登録$25)は2026-08-10、ユーザーとの相談の結果「優先度は低い」と結論**(トラックB=製品開発が0/43タスクで未着手・40〜60人日規模のため、14日待機はボトルネックにならない。詳細は上記「-5.72」節参照)。急かさなくてよい。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。コンテキスト200k超で単価が約2倍になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約はCLAUDE.md§トークン運用規約、実測と削減設計はdocs/token_optimization_design.md。

Proプラン使用率ログ(2026-08-09追加): ユーザーがセッション開始時・終了時の使用量(%)を申告してくれる場合、docs/token_optimization_design.md §8 に記録する(申告が無いループは書かない)。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.132 当日やったこと(2026-08-22、Sonnet 5、有人`/full_loop`「T5-A107とnextsession.mdの整理とtaskBを進めて、多少予算オーバーしてもOK」。**T5-A107完了・NEXT_SESSION.md整理・T5-B13を4束へ分割しT5-B13-1/-2完了**)

- T5-A107(GETリトライ最大待機時間の見直し)を`AskUserQuestion`で確認。3案(短縮約30秒/現状維持62秒/最短約15秒)を提示し、ユーザーは「現状維持(62秒のまま)」を選択。信頼性を体感の待たされ感より優先する判断。コード変更なし、マスタープランのT5-A107行を✅完了に更新。
- NEXT_SESSION.mdの「1. 現状サマリ」「2. 次回の着手点」に、運用ルール(直近1件のみ保持)に反して2026-08-14〜08-22の約20セッション分の履歴が溜まっていたことを発見。`docs/archive/NEXT_SESSION_log.md`へ退避し(旧「1. 現状サマリ」バックログ・旧「2. 次回の着手点」バックログの2節を新設)、本文は最新状態のみを残す形(205行→約55行)に整理した。作業中、Writeツールで新規作成した(BOM無し)`.ps1`を`powershell -File`実行するとPowerShell 5.1が日本語をシステム既定コードページで誤読しhere-string終端検出が壊れる事象に遭遇、BOM付与後に解消(新規教訓L180)。
- タスクB(トラックB)は、依存(T5-B12・T5-B3)が充足済みのT5-B13(`LocalDbService`実装、L要分割)を選定。`architect`へ分割方針の設計を委譲し、テーブル/機能グループ単位でT5-B13-1〜4の4束(各M)へ分解(`docs/local_db_schema_design.md` §7.5新設)。並び順はdriftの生成テーブルに`rowId`列ゲッターが無かったため`CustomExpression<int>('rowid')`方式を採用(束1〜2で確定・統一)。
- T5-B13-1(基盤+器具4マスタ、14メソッド)を`implementer`が実装、`lib/services/local_db_service.dart`・`lib/db/mappers.dart`・`lib/providers/local_db_provider.dart`を新規作成。`verifier`が独立検証(`verify.ps1`全項目green・`test/db/local_db_service_equipment_test.dart`13件全pass)、commit・push(bbd4b8a→141c14c、NEXT_SESSION.md整理分と合わせて1コミット)。
- T5-B13-2(豆・購入店・購入履歴、12メソッド)を`implementer`が実装、束1のヘルパー・並び順・upsert方式を踏襲。`bool?`3値・`double?`のnull/0.0区別・数字だけの文字列IDの型往復3ケースをテストで確認。`verifier`が独立検証(全項目green・`test/db/local_db_service_bean_test.dart`12件全pass)、commit・push(141c14c→1e97cf4)。
- 委譲1回ごとの予算チェックポイント($14.4、有人上限$24の6割)をT5-B13-2検証完了時点で超過($16.19)。ユーザーが事前に「多少予算オーバーしてもOK」と許可していたためT5-B13-2の検証まで完走したが、T5-B13-3への着手は見送りセッションを締めた。
- **次回セッションでやること**: T5-B13-3(`LocalDbService`束3: 抽出記録・メソッド・注湯ステップ、依存T5-B13-2充足)から着手。共通規約(`_requireId`/`_logWrite`/`_fail`/`_byRowId`ヘルパー、rowid並び順、upsert方式)は`lib/services/local_db_service.dart`の既存実装を読んで踏襲すること。

> これ以前の作業ログはdocs/archive/NEXT_SESSION_log.mdを参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID trig_01W3iqfgRZYaVZvkY8Jc83gg。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件はCLAUDE.md§日次改修ループ運用ルールと/start・/end・/full_loop・/night_loopスキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
