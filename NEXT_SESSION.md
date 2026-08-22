# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-22(Sonnet 5、有人`/full_loop`「PR2件の検証を実施して」。**オープンPR #5(T5-B12)・#6(T5-B23)を検証——`tools/verify.ps1`の9項目+受入資産は両方とも全green。だが自動pushゲート条件#2(integration_testスモーク)は計4回試行し4回ともFAIL(GAS接続断/一覧件数不一致/タイムアウトと失敗様相が毎回異なり、コード起因の再現性なし)。ユーザーが「GAS接続不安定性が原因」と判断しmerge/pushを承認、PR #5→#6の順でmainへmerge・push済み(origin/main: b541d32→2e38b3b)**。あわせてユーザー指示によりGAS接続不安定性の根本原因調査をT5-A103として起票(最優先扱い)。詳細は「3. 直近の作業ログ」参照)

> 本書の構成(2026-07-29改訂): 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに直近1セッション分の作業ログだけを残す。それ以前はdocs/archive/NEXT_SESSION_log.mdへ退避済み。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> 書き足しルール: /end・/full_loopで当日ログを追記する際は「3. 直近の作業ログ」の古い節をアーカイブ先頭へ移してから新しい節を1件だけ置く(本書は常に1件)。タスク定義・進捗の正本はdocs/改修マスタープラン.md。

## 1. 現状サマリ

- **【2026-08-22・有人`/full_loop`(引数なし)】PR #7(T5-A104+T5-A105)をmainへmerge・push済み(8b9ab53)。T5-A106完了(SKILL.md大前提の食い違い修正)。本番`coffee_data`のtotalTime=0ゴミレコード5件削除(191→186件)。T5-A107(GETリトライ最大待機時間62秒の見直し)を起票、方針未確定のまま次回セッションへ持ち越し。integration_testスモークはGAS接続不安定性由来の散発的失敗が残る(詳細は`docs/archive/NEXT_SESSION_log.md`「-5.131」節参照)。**
- 進行中はマスタープラン Phase 5(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- Phase 5トラックA(開発運用基盤)完了済み(38件、詳細はdocs/改修マスタープラン.md §3参照)。トラックCはT5-C3完了済み(1件)。正本はdocs/android_release/開発運用基盤設計.md・検証強化設計.md・リリース計画書.md。agy委譲の正本はdocs/antigravity_delegation_design.md(§7実績ログ・§9設計)。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASはgas/Code.gsをclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: docs/bean_purchase_design.md(追加購入・購入履歴)、docs/store_master_design.md(購入店マスタ)。
- モデル分担ルール(2026-08-08改訂、恒久): 親セッションは既定でSonnet 5で起動する(/model sonnet)。Opus 5はarchitectサブエージェント経由でのみ使い、親セッションでは使わない。タスク選定はモデルで分岐させない。詳細・根拠はCLAUDE.md§日次改修ループ運用ルール・docs/token_reduction_report_20260808.md。
- デプロイ・push運用ルール(2026-08-08改訂、恒久): firebase deploy・clasp push/clasp redeployは実行前に必ずチャットでユーザーの明示的な許可を得る。git pushはverifierが全項目パスを報告済み(またはコード変更を含まない)なら確認不要(未検証・検証NGのpushと--force系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細はrules/lessons_archive.md L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **【2026-08-22最新】T5-A107完了(GETリトライ最大待機時間はユーザー判断で62秒のまま維持、コード変更なし)。次点はトラックB系列(T5-B13〈LocalDbService実装、依存T5-B12・T5-B3充足、L要分割〉・T5-B24〈記録画面、L〉・T5-B25〈インサイト画面、M〉)。** integration_testスモークはT5-A104・T5-A105により大幅改善したが、GAS接続不安定性由来の散発的失敗(3回中1回程度)が残るため、今後の検証で失敗した場合はまずT5-A104/A105以降のコード変更が原因かGAS起因かを切り分けてから判断すること。T5-A6(エミュレータ整備)は完了済み(AVD `beanbase_test`/`beanbase_ui`が実在)。過去セッションの詳細な着手点履歴は`docs/archive/NEXT_SESSION_log.md`「旧『2. 次回の着手点』バックログ」節を参照。
タスクの正本はdocs/改修マスタープラン.md §3。

サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化): .claude/agents/に複数体——architect(設計・原因究明、opus固定)/implementer(実装、sonnet固定)/verifier(検証、sonnet固定)/adversary(敵対的レビュー、sonnet固定)等。/start・/full_loop・/night_loopでは、コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する。architectを呼ぶのは「上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は/full_loopスキル§サブエージェントへの委譲、要約はCLAUDE.md§日次改修ループ運用ルール。

トラックAは完成済み(2026-08-15ユーザー承認済み、以後トラックB本格着手中)。

ユーザー実施待ちで着手不可: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(28豆中24豆の初期購入量(g)入力)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)。**T5-C1(Play Consoleデベロッパー登録$25)は2026-08-10、ユーザーとの相談の結果「優先度は低い」と結論**(トラックB=製品開発が0/43タスクで未着手・40〜60人日規模のため、14日待機はボトルネックにならない。詳細は上記「-5.72」節参照)。急かさなくてよい。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。コンテキスト200k超で単価が約2倍になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約はCLAUDE.md§トークン運用規約、実測と削減設計はdocs/token_optimization_design.md。

Proプラン使用率ログ(2026-08-09追加): ユーザーがセッション開始時・終了時の使用量(%)を申告してくれる場合、docs/token_optimization_design.md §8 に記録する(申告が無いループは書かない)。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.131 当日やったこと(2026-08-22、Sonnet 5、有人`/full_loop`(引数なし)。**PR #7(T5-A104+新規実装T5-A105)を検証・マージ、T5-A106完了、本番ゴミレコード5件削除、T5-A107起票**)

- オープンPR #7(`night/T5-A104`)から着手。`verifier`へ検証委譲、`verify.ps1 -Task T5-A104`は全項目green・acceptance 3/3を再確認。integration_testスモークを実機2回連続実行したところ両方FAIL(`smoke_test.dart:237`)——ただし直前のGET timeoutログから、原因はT5-A104のコードではなく**`smoke_test.dart`側の固定2秒`pumpAndSettle`**(T5-A105が対処予定の既知欠陥)と判明。
- 予算に余裕があったため即座にT5-A105を`implementer`へ委譲、同じ`night/T5-A104`ブランチに実装(メソッド選択のポーリング化・一覧反映待機の`_pumpUntil`化)。implementer自己確認で実機2回連続PASS。続けて`verifier`が独立検証したところ**1回PASS・1回FAIL**(FAILは`coffee_data`のGET再取得が3回のリトライ全て失敗、GAS側の純粋な接続不安定性と判定、smoke_test側のロジック不備ではない)。
- `AskUserQuestion`でユーザーに3点確認: (1)PR #7マージ可否→**マージする**(2)リトライ最大待機時間62秒の妥当性→**見直したい**(3)本番ゴミレコード削除→**削除する**。回答に基づき、T5-A105の変更をコミット・push、`gh pr merge 7 --merge --delete-branch`でmainへマージ(8b9ab53)。マスタープランのT5-A104・T5-A105行を✅完了に更新、リトライ見直しは**T5-A107として新規起票**(方針は未確定のまま、着手時に要ユーザー合意)。
- T5-A106(SKILL.md大前提の食い違い修正)を実施。`.claude/skills/night_loop/SKILL.md`の「`ui_verifier`/`integration_test`は現時点で存在しない」という誤った大前提2文を実態(いずれもT5-A4・T5-A7完了済み)に合わせて書き換え、ゲート条件#3(`ui_verifier`)を条件#2と同じ扱いで「適用(常時判定、UI変更が無いループは判定対象外)」へ解除。4箇所の差分のみ、非委譲しきい値に該当するため親が直接編集。commit済み(未push、後続コミットとまとめてpush予定)。
- T5-A103調査で判明していた本番`coffee_data`の`抽出時間(秒)=0`ゴミレコードをGAS API経由で調査、5件(2026-08-20付、全て`bean=d009a114`のテストフィクスチャ)を特定・削除(191件→186件、削除後ゴミレコード0件を確認)。今日のT5-A105実機確認で保存された2件(id=1787387129513, 1787387578233)は`抽出時間(秒)`が正常値でゴミレコードに該当しないため削除対象外。
- **新規教訓L179**: PowerShell `Invoke-RestMethod -Body <string>`は日本語キーJSONを既定エンコーディングで送るとGAS側で文字化けしキー一致に失敗する(削除APIが原因不明の`"ID column or value not found"`エラーを返した)。`[System.Text.Encoding]::UTF8.GetBytes()`でバイト列化して送ることで解決。
- **次回セッションでやること**: T5-A107(リトライ最大待機時間の見直し、方針未確定)から着手を検討。通常タスクの次点はT5-B24(記録画面、L)・T5-B25(インサイト画面、M)・T5-B13(LocalDbService実装、依存T5-B12・T5-B3充足)。

> これ以前の作業ログはdocs/archive/NEXT_SESSION_log.mdを参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID trig_01W3iqfgRZYaVZvkY8Jc83gg。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件はCLAUDE.md§日次改修ループ運用ルールと/start・/end・/full_loop・/night_loopスキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
