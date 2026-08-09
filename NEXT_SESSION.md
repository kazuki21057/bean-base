# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-09(Sonnet 5、/full_loop 有人モード。**このセッションはLinux環境で起動されたためPowerShell/Androidエミュレータが使えず、T5-A4/A7/A12/A16/A17/A36には着手不可**。代わりにエミュレータ不要のT5-A8(goldenテスト基盤)を選定・実装。ファイル数超過(13件>5件)によりセッション分割ルールを適用、検証(verifier)は次回セッションへ持ち越し=「検証待ち」)

> 本書の構成(2026-07-29改訂): 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに直近1セッション分の作業ログだけを残す。それ以前はdocs/archive/NEXT_SESSION_log.mdへ退避済み。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> 書き足しルール: /end・/full_loopで当日ログを追記する際は「3. 直近の作業ログ」の古い節をアーカイブ先頭へ移してから新しい節を1件だけ置く(本書は常に1件)。タスク定義・進捗の正本はdocs/改修マスタープラン.md。

## 1. 現状サマリ

- 2026-08-09(/full_loop、有人モード、Sonnet 5): **T5-A17の直接原因は解消済み**。ユーザーが.claude/settings.night.jsonのallowにEdit/Writeを追加(commit 591e32c)、無人実行でのコード変更ブロック問題は解消した。ただしT5-A17の正式な完了条件(T5-A12の試走で(a)(b)(c)を確認)はまだ未実施——T5-A12はWindows環境での`night_loop.ps1`実行が前提のため、Linux環境の本セッションでは実施できない。
- **重要な環境制約(今回新規判明)**: 本セッションはLinux環境(PowerShell/adb/Androidエミュレータ利用不可)で起動された。T5-A4/A7/A12/A16/A17(完了条件)/A36はいずれも`ui_probe.ps1`等のPowerShellツールやエミュレータが前提のため、**Windows環境のセッションでないと着手・完了できない**。次回セッションがWindows環境であれば通常どおり選定してよい。Linux環境で再開する場合はこれらを避け、エミュレータ非依存のタスク(A8はこのループで実施済み、A13/A14/A15/A25/A29等)を優先する。
- T5-A36の状況(変化なし、Windows環境待ち): architectが原因究明済み(Flutter debugビルドのstructured errors既定有効によりlogcatにFlutterErrorが出ない)、implementerがT1〜T9を実装済み・コミット済み(f1681e8・6b4cb59、tools/ui_probe.ps1等4ファイル、lib/不変)。検証の核心手順(意図的overflow挿入→ui_probe.ps1→ui_verifier確認)はWindows環境でのみ実施可能。
- T5-A36の状況(変化なし): architectが原因究明済み(Flutter debugビルドのstructured errors既定有効によりlogcatにFlutterErrorが出ない)、implementerがT1〜T9を実装済み・コミット済み(f1681e8・6b4cb59、tools/ui_probe.ps1等4ファイル、lib/不変)。今回verifierとadversaryを並行起動して再検証を試みた: verifierは-Prepareビルド成功・偽陽性なし・flutter analyze新規issue0件を確認したが、核心の「意図的overflowでの検出成功」は上記の権限ブロックにより未実施。adversaryはCritical指摘0件、Major指摘2件(a: -SkipBuild使用時にdart-define有無を警告しない伝播漏れ、b: 本変更自体がまだ独立検証を経ていない〈今回も未解消〉)。次回は.claude/settings.night.json修正後、(1)lib/screens/settings_screen.dartに一時的なoverflow行を挿入→ui_probe.ps1 -Prepare→ui_verifier起動→検出確認→git checkoutで復元、という設計書§5-2a-J手順そのままを実施すれば完了できる見込み。
- 進行中はマスタープラン Phase 5(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- Phase 5トラックA(開発運用基盤)完了済み: T5-A1・A2・A3・A5・A6・A9・A10・A11・A18〜A24・A26・A27・A28・A30〜A35(24件)。T5-A36は検証待ち(上記)、通れば完了済みへ。T5-A4はT5-A36完了後に完了条件を再実行する。T5-A17は上記の新発見(Edit/Write未許可)により未完了かつ追加対応が必要と判明。他にT5-A7/A8/A13/A14/A15/A25/A29も依存なし。トラックCはT5-C3完了済み(1件)。正本はdocs/android_release/開発運用基盤設計.md・検証強化設計.md・リリース計画書.md。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASはgas/Code.gsをclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: docs/bean_purchase_design.md(追加購入・購入履歴)、docs/store_master_design.md(購入店マスタ)。
- モデル分担ルール(2026-08-08改訂、恒久): 親セッションは既定でSonnet 5で起動する(/model sonnet)。Opus 5はarchitectサブエージェント経由でのみ使い、親セッションでは使わない。タスク選定はモデルで分岐させない。詳細・根拠はCLAUDE.md§日次改修ループ運用ルール・docs/token_reduction_report_20260808.md。
- デプロイ・push運用ルール(2026-08-08改訂、恒久): firebase deploy・clasp push/clasp redeployは実行前に必ずチャットでユーザーの明示的な許可を得る。git pushはverifierが全項目パスを報告済み(またはコード変更を含まない)なら確認不要(未検証・検証NGのpushと--force系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細はrules/lessons_archive.md L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> 親セッションは /model sonnet(Sonnet 5)で起動する。CLAUDE.md §日次改修ループ運用ルールのモデル分担ルールに従う。Opus 5はarchitectサブエージェント経由でのみ使う。
>
> **最優先(検証待ち)**: 今回のセッションでT5-A8(goldenテスト基盤)をimplementerが実装済み・コミット済みだが、ファイル数超過(13件)によりverifierへの検証委譲がセッション分割で持ち越しになっている。次回セッション開始時は`/full_loop 検証のみ`等でタスク選定・実装をスキップし、**手順4(検証)から再開**すること。verifierへの委譲内容は下記「3. 直近の作業ログ」参照。検証OKならT5-A8を完了済みへ移し、コード変更を含む(test/・rules/のみだがlib/は不変のためデプロイ対象外)のでpushのみ実施。
>
> **環境依存の分岐(今回新規判明)**: 次回セッションがWindows環境かLinux環境かで着手できるタスクが変わる。
> - **Windows環境の場合**: T5-A17は直接原因(Edit/Write権限)は解消済みなので、T5-A12(有人監視下night_loop.ps1試走)→T5-A17完了条件確認 を優先。その後T5-A36(検証強化設計§5-2a-J手順、(a)〜(e))→T5-A4再確認、の順に着手するとトラックAの完了に近づく。
> - **Linux環境の場合**: PowerShell/エミュレータ非依存のタスクのみ選定する。T5-A8検証(上記最優先)の次はT5-A13/A14/A15/A25/A29(タスク表順、いずれも依存なし)。
>
> 副次発見の別タスク化を検討(未着手・変化なし): T5-A36調査中、font_scale 2.0+density 560条件で現行UIに実際のoverflowが2箇所見つかった件。docs/改修マスタープラン.mdに新規ID(例: T5-A37)で追加するか判断すること。
>
> §Hに記録された既知の制約(次セッションで踏まないこと): ダークモードはlib/main.dartにdarkTheme/themeModeが未実装のため、ui_verifierの項目5(ダークモード判読性)は現時点で検査不能(T5-B21完了まで「未実施」と報告させる仕様。指摘として扱わない)。UIAutomatorはFlutterのsemanticsノードを返さないことを実測済み。AndroidManifest.xmlにrelease/profileビルド用のINTERNET権限が無いことも判明(トラックBで対処要)。エミュレータは起動30秒後の安定確認後でも突然クラッシュすることがある。新規: .claude/settings.night.jsonのdontAskはallow未列挙のツールを拒否する(許可ではない)ため、無人実行向けの権限プロファイルを設計・変更する際は想定する全ツールを実際に1回動かして実測する(L132)。

タスクの正本はdocs/改修マスタープラン.md §3。

サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化): .claude/agents/に複数体——architect(設計・原因究明、opus固定)/implementer(実装、sonnet固定)/verifier(検証、sonnet固定)/adversary(敵対的レビュー、sonnet固定)等。/start・/full_loop・/night_loopでは、コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する。architectを呼ぶのは「上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は/full_loopスキル§サブエージェントへの委譲、要約はCLAUDE.md§日次改修ループ運用ルール。

トラックAを完成させるまで製品開発(トラックB)は本格化させない(夜間自動実行が無いと40〜60人日規模を消化できないため)。

ユーザー実施待ちで着手不可: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(11メソッドの推奨焙煎度設定)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)、T5-A17(.claude/settings.night.jsonのallowにEdit/Write追加、今回新規発覚)、T5-C1(Play Consoleデベロッパー登録$25。テスター12人は知り合いから確保可能なため律速ではなく、残るクリティカルパスはPlay Consoleの本人確認と14日間の待機のみ)。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。コンテキスト200k超で単価が約2倍になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約はCLAUDE.md§トークン運用規約、実測と削減設計はdocs/token_optimization_design.md。

Proプラン使用率ログ(2026-08-09追加): ユーザーがセッション開始時・終了時の使用量(%)を申告してくれる場合、docs/token_optimization_design.md §8 に記録する(申告が無いループは書かない)。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.64 当日やったこと(2026-08-09、Sonnet 5、/full_loop 有人モード。**T5-A8「検証待ち」**——implementerが実装・コミット完了、verifierへの検証委譲はファイル数超過によるセッション分割で次回へ持ち越し)

- **環境確認**: 本セッションはLinux環境(`which pwsh`該当なし)で起動されたため、PowerShell/adb/Androidエミュレータが前提のT5-A4/A7/A12/A16/A36には着手不可と判断。
- **T5-A17の直接原因は解消済みと確認**: git logでcommit 591e32c(ユーザーが.claude/settings.night.jsonのallowにEdit/Write追加済み)を確認。ただし完了条件(T5-A12試走)自体はWindows環境が前提のため未実施のまま。
- **タスク選定**: 依存なし・エミュレータ非依存で今回の環境でも完結できる最上位タスクとしてT5-A8(goldenテスト基盤)を選定。
- **implementerに委譲・実装完了**: `test/helpers/overflow_test_helper.dart`(overflow機械判定、`FlutterError.onError`差し替え+3解像度pump)、`test/settings_screen_overflow_test.dart`(設定画面090への適用)、`test/golden/`配下にgolden基盤(`golden_test_helper.dart`)+3コンポーネント(`bean_jar_widget`/`coffee_log_card`/`roast_level_slider`)×ライト/ダーク=6ケースのgoldenテスト・画像、`rules/verification.md`にgolden自動更新禁止ルールを追記。一時検証で(a)overflow挿入時に実際にfailすること(b)`kMocha`色変更時にgoldenが実際にfailすること(30.09%ピクセル差)、をいずれも確認しrevert済み。`flutter analyze`新規issue0件、`flutter test`367件全pass、`flutter build web`成功(すべてimplementer自己申告、独立検証は未実施)。
- **セッション分割(3.5)を適用**: 実装で触れたファイルが13件(閾値5件超)のため、verifierへの検証委譲は行わずここでセッションを終える。ループコストは$6.73(閾値$7未満だがファイル数条件が単独で発火)。commitのみ実施しpushは見送り。
- **次回やること**: `flutter test test/golden/`・`flutter test test/settings_screen_overflow_test.dart`の独立実行、`git status`でlib/無変更確認、`rules/verification.md`追記部分の書式確認、をverifierに委譲する(委譲プロンプト例は上記実装内容をそのまま「検証対象」として渡せばよい)。OKならT5-A8を完了済みへ移し、`docs/archive/マスタープラン_完了タスク.md`に詳細転記、pushする。
- **変更ファイル(未push)**: `test/helpers/overflow_test_helper.dart`(新規)、`test/settings_screen_overflow_test.dart`(新規)、`test/golden/`配下10ファイル(新規、golden_test_helper.dart・3コンポーネント分golden_test.dart×3・goldens/*.png×6)、`rules/verification.md`(編集)。lib/は最終的に無変更(implementer報告・`git status`で確認済み)。

> これ以前(-5.63節以前)の作業ログはdocs/archive/NEXT_SESSION_log.mdを参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID trig_01W3iqfgRZYaVZvkY8Jc83gg。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件はCLAUDE.md§日次改修ループ運用ルールと/start・/end・/full_loop・/night_loopスキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
