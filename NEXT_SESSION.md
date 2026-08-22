# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-22(Sonnet 5、有人`/full_loop`(引数なし)。**T5-B13-3(LocalDbService束3: 抽出記録・メソッド・注湯ステップ)完了・commit済み**。詳細は「3. 直近の作業ログ」参照)

> 本書の構成(2026-07-29改訂): 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに直近1セッション分の作業ログだけを残す。それ以前はdocs/archive/NEXT_SESSION_log.mdへ退避済み。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> 書き足しルール: /end・/full_loopで当日ログを追記する際は「3. 直近の作業ログ」の古い節をアーカイブ先頭へ移してから新しい節を1件だけ置く(本書は常に1件)。タスク定義・進捗の正本はdocs/改修マスタープラン.md。

## 1. 現状サマリ

- **【2026-08-22・有人`/full_loop`(引数なし)】T5-B13-3(LocalDbService束3: `coffee_data`/`methods_master`/`pouring_steps`の13メソッド)を`implementer`が実装、束1・2のヘルパー・rowid並び順・upsert方式を踏襲。`deletePouringStepsForMethod`はSheets版に対応が無いため新規実装(設計書§7.2-1どおり)。`verifier`が独立検証(`verify.ps1`全項目green・`test/db/local_db_service_brew_test.dart`12件全pass、DateTime往復・本番模倣ケース含む)。commit済み(push未実施、下記参照)。**
- 進行中はマスタープラン Phase 5(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- Phase 5トラックA(開発運用基盤)完了済み(38件、詳細はdocs/改修マスタープラン.md §3参照)。トラックCはT5-C3完了済み(1件)。正本はdocs/android_release/開発運用基盤設計.md・検証強化設計.md・リリース計画書.md。agy委譲の正本はdocs/antigravity_delegation_design.md(§7実績ログ・§9設計)。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASはgas/Code.gsをclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: docs/bean_purchase_design.md(追加購入・購入履歴)、docs/store_master_design.md(購入店マスタ)。
- モデル分担ルール(2026-08-08改訂、恒久): 親セッションは既定でSonnet 5で起動する(/model sonnet)。Opus 5はarchitectサブエージェント経由でのみ使い、親セッションでは使わない。タスク選定はモデルで分岐させない。詳細・根拠はCLAUDE.md§日次改修ループ運用ルール・docs/token_reduction_report_20260808.md。
- デプロイ・push運用ルール(2026-08-08改訂、恒久): firebase deploy・clasp push/clasp redeployは実行前に必ずチャットでユーザーの明示的な許可を得る。git pushはverifierが全項目パスを報告済み(またはコード変更を含まない)なら確認不要(未検証・検証NGのpushと--force系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細はrules/lessons_archive.md L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **【2026-08-22最新】T5-B13-1〜3完了。次点はT5-B13-4(`LocalDbService`束4: 解析・レシピ提案+`dataServiceProvider`配線+受入、依存T5-B13-3充足)。** T5-B13は`architect`により4束(T5-B13-1〜4)へ分割済み、分割方針・各束の完了条件は`docs/local_db_schema_design.md` §7.5参照。束4実装時は束1〜3で確定した共通規約(rowid並び順・upsert方式・`LocalDbException`文言・共通ヘルパー)を`lib/services/local_db_service.dart`から読んで踏襲すること。束4で`dataServiceProvider`配線+受入テストが入り、`integration_test`スモークの判定が絡む(GAS接続不安定性由来のFAILは束4の失敗に数えない、設計書§7.5.3)。過去セッションの詳細な着手点履歴は`docs/archive/NEXT_SESSION_log.md`「旧『2. 次回の着手点』バックログ」節を参照。
タスクの正本はdocs/改修マスタープラン.md §3。

サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化): .claude/agents/に複数体——architect(設計・原因究明、opus固定)/implementer(実装、sonnet固定)/verifier(検証、sonnet固定)/adversary(敵対的レビュー、sonnet固定)等。/start・/full_loop・/night_loopでは、コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する。architectを呼ぶのは「上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は/full_loopスキル§サブエージェントへの委譲、要約はCLAUDE.md§日次改修ループ運用ルール。

トラックAは完成済み(2026-08-15ユーザー承認済み、以後トラックB本格着手中)。

ユーザー実施待ちで着手不可: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(28豆中24豆の初期購入量(g)入力)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)。**T5-C1(Play Consoleデベロッパー登録$25)は2026-08-10、ユーザーとの相談の結果「優先度は低い」と結論**(トラックB=製品開発が0/43タスクで未着手・40〜60人日規模のため、14日待機はボトルネックにならない。詳細は上記「-5.72」節参照)。急かさなくてよい。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。コンテキスト200k超で単価が約2倍になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約はCLAUDE.md§トークン運用規約、実測と削減設計はdocs/token_optimization_design.md。

Proプラン使用率ログ(2026-08-09追加): ユーザーがセッション開始時・終了時の使用量(%)を申告してくれる場合、docs/token_optimization_design.md §8 に記録する(申告が無いループは書かない)。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.133 当日やったこと(2026-08-22、Sonnet 5、有人`/full_loop`(引数なし)。**T5-B13-3完了**)

- 依存(T5-B13-2)が充足済みのT5-B13-3(`LocalDbService`束3: 抽出記録・メソッド・注湯ステップ)を選定。方針は束1・2の踏襲+設計書§7.2-1で確定済みのためarchitectは呼ばず`implementer`へ直接委譲。
- `implementer`が`coffee_data`(32列)・`methods_master`(13列)・`pouring_steps`(8列)の13メソッドを実装。`deletePouringStepsForMethod`はSheets版に対応が無いため新規実装。`coffee_data.updated_at`(ローカルDB専用メタ列、`CoffeeRecord`モデルに対応フィールド無し)は保存のたび`DateTime.now()`で埋める実装とした(設計書に明記なし、実装時の判断として報告あり)。`test/db/local_db_service_brew_test.dart`を新規作成。
- `verifier`が独立検証。`verify.ps1`全項目green(analyze新規issue0・test519件全pass・build web/apk成功・golden/codegen/secret_scan問題なし)。実装者は「21件全pass」と報告したが、verifierの実測では12件(4 group・12 test)、`grep`で確認しCRUD一式+異常系・`deletePouringStepsForMethod`限定削除・DateTime往復・本番模倣ケースの4完了条件が全てカバーされていることを確認、マスタープランの記載を12件に訂正した。
- UI変更なし・`lib/db`層のみ(`dataServiceProvider`配線は束4)のためデプロイ・本番確認は不要と判断。変更ファイル数4(5超えないため)・区切りでもないため`/code-review`はスキップ。
- 委譲1回ごとの予算チェックポイント($14.4)には未到達(実測$4.80)。
- **次回セッションでやること**: T5-B13-4(`LocalDbService`束4: 解析・レシピ提案+`dataServiceProvider`配線+受入、依存T5-B13-3充足)から着手。共通規約(`_requireId`/`_logWrite`/`_fail`/`_byRowId`ヘルパー、rowid並び順、upsert方式)は`lib/services/local_db_service.dart`の既存実装を読んで踏襲すること。束4完了でT5-B13全体(トラックB内の1タスク群)が完了するため、区切り条件に該当し`/code-review`実行を検討すること。

> これ以前の作業ログはdocs/archive/NEXT_SESSION_log.mdを参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID trig_01W3iqfgRZYaVZvkY8Jc83gg。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件はCLAUDE.md§日次改修ループ運用ルールと/start・/end・/full_loop・/night_loopスキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
