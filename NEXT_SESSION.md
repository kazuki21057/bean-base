# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-08(**Sonnet 5**、`/full_loop`。**T5-A23(有人ループ側への`verify.ps1`/`verify.sh`配線)を完了**。**コード変更なし・`lib/`不変のためデプロイ対象外**。verifierが`tools/verify.sh`実行で8項目全て`ok:true`を確認。commit・**push済み**)

> **本書の構成(2026-07-29改訂)**: 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに **直近1セッション分の作業ログだけ** を残す。それ以前は `docs/archive/NEXT_SESSION_log.md` へ退避済み(節番号・本文はそのまま)。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> **書き足しルール**: `/end`・`/full_loop`で当日ログを追記する際は「3. 直近の作業ログ」の**古い節をアーカイブ先頭へ移してから**新しい節を1件だけ置く(本書は常に1件)。完了タスクの実装内容は本書に長く書かず、要点(何を変えたか・次に効く制約)だけ書く。タスク定義・進捗の正本は `docs/改修マスタープラン.md`。**「1. 現状サマリ」「2. 次回の着手点」も同様に直近セッション分の要点だけを残し、過去の詳細経緯は`docs/archive/マスタープラン_完了タスク.md`・`docs/archive/NEXT_SESSION_log.md`に譲って書かない**(2026-08-08、T5-A21で明記)。

## 1. 現状サマリ

- **2026-08-08(`/full_loop`、Sonnet 5、本セッション): T5-A23完了(✅)。`rules/verification.md`に一括検証スクリプト(`tools/verify.ps1`/`tools/verify.sh`)の手順を新設**し、個別`flutter analyze`→`test`→`build`手順はフォールバックとして残した。`full_loop`手順4にも一言追記。verifierが実際に`tools/verify.sh`を実行し8項目全て`ok:true`(analyze新規issueなし・test 360件パス・build_web_release成功等)を確認済み。**次はT5-A24**。
- 進行中はマスタープラン **Phase 5**(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- **Phase 5トラックA(開発運用基盤)完了済み**: T5-A1・A2・A3・A9・A10・A18・A19・A20・A21・A22・A23。**次に着手すべきはT5-A24**(ドキュメント重複統合、`docs/token_reduction_report_20260808.md` §10に確定済み)、その後T5-A11(`loop_guard.js`しきい値の夜間/有人分岐)。正本は`docs/android_release/開発運用基盤設計.md`・`検証強化設計.md`・`リリース計画書.md`。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASは`gas/Code.gs`をclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: `docs/bean_purchase_design.md`(追加購入・購入履歴)、`docs/store_master_design.md`(購入店マスタ)。
- **モデル分担ルール(2026-08-08改訂、恒久)**: 親セッションは既定でSonnet 5で起動する(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** タスク選定はモデルで分岐させない——依存が満たされた「⚠️上位モデルで実施」タスクがあれば`architect`へ優先委譲(成果物は設計書のみ)、無ければ通常タスクへフォールバックする。詳細・根拠は`CLAUDE.md`§日次改修ループ運用ルール・`docs/token_reduction_report_20260808.md`。
- **デプロイ・push運用ルール(2026-08-08改訂、恒久)**: `firebase deploy`・`clasp push`/`clasp redeploy`は**実行前に必ずチャットでユーザーの明示的な許可を得る**。**`git push`は`verifier`が全項目パスを報告済み(またはコード変更を含まない)なら確認不要**(未検証・検証NGのpushと`--force`系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細は`rules/lessons_archive.md` L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **親セッションは `/model sonnet`(Sonnet 5)で起動する。** `CLAUDE.md` §日次改修ループ運用ルールのモデル分担ルールに従う。Opus 5は`architect`サブエージェント経由でのみ使う。
>
> **次に着手するタスク: T5-A24**(T5-A19〜T5-A23は2026-08-08完了)。`docs/token_reduction_report_20260808.md` §10 T5-A24に対応表・終了条件まで確定済みで、`implementer`へそのまま委譲できる(`architect`不要)。ただし依存は`T5-A19〜A23`(全て完了済みなので依存は解消済み)。着手前に報告書を全読みせず§10の該当タスク節だけを読むこと。

**タスクの正本は `docs/改修マスタープラン.md` §3。**

**サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化)**: `.claude/agents/`に3体——`architect`(設計・原因究明、**opus**固定)/`implementer`(実装、sonnet固定)/`verifier`(検証、sonnet固定)。`/start`・`/full_loop`では、**コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する**(モデルは各定義の`model:`で自動選択されるので`Agent`ツールに`model`を渡さない)。`architect`を呼ぶのは「⚠️上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は`/full_loop`スキル§サブエージェントへの委譲、要約は`CLAUDE.md`§日次改修ループ運用ルール。

**T5-A24完了後の推奨着手順**: T5-A11(`loop_guard.js`しきい値の夜間/有人分岐、依存なし)に進む。**これが済むとT5-A12(有人監視下の試走→スケジューラ登録)の依存が全部揃う**。正本は`開発運用基盤設計.md` §5(夜間=$8/ターン40/連続失敗2、有人=$24/30/3)。他に依存なしで着手できるトラックA: T5-A5(`researcher`新設)・T5-A6(エミュレータ整備)・T5-A8(golden基盤)・T5-A13(`implementer`追記)・T5-A14(Proでのopus可否実測)・T5-A15(lint強化)。**トラックAを完成させるまで製品開発(トラックB)は本格化させない**(夜間自動実行が無いと40〜60人日規模を消化できないため)。

**⚠️ 夜間ループを実際に回す前にT5-A17(ユーザーによる`.claude/settings.night.json`設置)が必須**。未設置だと`tools/night_loop.ps1`が`claude`を起動せずexit 2で止まる。内容は`開発運用基盤設計.md` §4-4に全文あり(**2026-08-08にforce pushのdenyパターン5つを追加した最新版をコピーすること**、教訓L126)。

**ユーザー実施待ちで着手不可**: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(11メソッドの推奨焙煎度設定)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)、T5-A17(`.claude/settings.night.json`設置)、T5-C1(Play Consoleデベロッパー登録$25。テスター12人は知り合いから確保可能なため律速ではなく、残るクリティカルパスはPlay Consoleの本人確認と14日間の待機のみ)。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。**コンテキスト200k超で単価が約2倍**になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約は`CLAUDE.md`§トークン運用規約、実測と削減設計は`docs/token_optimization_design.md`。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.47 当日やったこと(2026-08-08、**Sonnet 5**、`/full_loop`。**T5-A23完了**)

- `rules/verification.md` §必須検証フローに「0. 一括検証スクリプト」を新設。`tools/verify.ps1`(Windows)/`tools/verify.sh`(Bash)で`analyze`/`test`/`build`等8項目を1コマンド実行し、標準出力JSONのサマリのみ読む(失敗項目だけ`.claude/verify_logs/`のログを読む)運用に統一。既存の個別コマンド手順(1・2番)は「スクリプトが使えない場合のフォールバック」として残した。`.claude/skills/full_loop/SKILL.md`手順4にも一言追記(委譲プロンプトのテンプレ本文は変更なし)。
- `implementer`への委譲1回で完了(`architect`不要)。implementer自身も`tools/verify.sh`を試走し全項目pass。
- 続けて`verifier`へ検証委譲し、`rules/verification.md`を読んだ状態から実際に`tools/verify.sh`を実行させて確認。結果: 8項目全て`ok:true`(analyze baseline=current=31件、test 360件パス、build_web_release成功、build_apk_releaseはskip、golden diff 0件、codegen差分なし、secret_scan検出なし)。標準出力JSONのみで判定でき、完了条件(20行以内)も満たした。
- 旧-5.46節(T5-A22)を`docs/archive/NEXT_SESSION_log.md`へ退避。3節構成・冒頭の構成説明・書き足しルールは維持。
- コード変更なし(`lib/`不変)のためデプロイ・本番確認は対象外。commit・push済み。**次はT5-A24**。

> これ以前(-5.46節以前)の作業ログは **`docs/archive/NEXT_SESSION_log.md`** を参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID `trig_01W3iqfgRZYaVZvkY8Jc83gg`。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件は `CLAUDE.md`§日次改修ループ運用ルールと `/start`・`/end`・`/full_loop` スキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
