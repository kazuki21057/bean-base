# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-09(**Sonnet 5**、`/full_loop`。**T5-C3完了(✅)+T5-A4実装完了(検証待ち)**。architect(102kトークン)+implementer(150kトークン、45分)を要する大規模タスクだったためセッション分割ルールに該当し、T5-A4の独立検証・push・進捗表更新は次セッションへ持ち越し。commitのみ実施、**push未実施**)

> **本書の構成(2026-07-29改訂)**: 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに **直近1セッション分の作業ログだけ** を残す。それ以前は `docs/archive/NEXT_SESSION_log.md` へ退避済み(節番号・本文はそのまま)。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> **書き足しルール**: `/end`・`/full_loop`で当日ログを追記する際は「3. 直近の作業ログ」の**古い節をアーカイブ先頭へ移してから**新しい節を1件だけ置く(本書は常に1件)。完了タスクの実装内容は本書に長く書かず、要点(何を変えたか・次に効く制約)だけ書く。タスク定義・進捗の正本は `docs/改修マスタープラン.md`。**「1. 現状サマリ」「2. 次回の着手点」も同様に直近セッション分の要点だけを残し、過去の詳細経緯は`docs/archive/マスタープラン_完了タスク.md`・`docs/archive/NEXT_SESSION_log.md`に譲って書かない**(2026-08-08、T5-A21で明記)。

## 1. 現状サマリ

- **2026-08-09(`/full_loop`、Sonnet 5、本セッション): T5-C3完了(✅、`researcher`がPlay Console公開要件を調査、`docs/research/2026-08-09_play_requirements.md`)+T5-A4実装完了(検証待ち)**。T5-A4(`ui_verifier`エージェント新設)は新規決定を伴うため`architect`へ設計委譲(タップ方式・スクショ取得・待機ロジック・ツール権限等を確定、`検証強化設計.md` §5-2aに追記)→`implementer`が`tools/ui_probe.ps1`・`.claude/agents/ui_verifier.md`を実装、実装者の自己確認は成功したが**独立検証(verifier)・完了条件の実地確認(overflow画面での指摘テスト)は未実施**。architect+implementerで合計25万トークン超・処理45分超を要したため、T3-73dのセッション分割ルール(cost>$7)に該当し、検証・push・進捗表更新は次セッションへ持ち越し(詳細は§3)。
- 進行中はマスタープラン **Phase 5**(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- **Phase 5トラックA(開発運用基盤)完了済み**: T5-A1・A2・A3・A5・A6・A9・A10・A11・A18〜A24・A26(16件)。**T5-A4は実装済みだが検証待ち(次点候補)**。その後は通常タスク(T5-A8/A13/A14/A15/A25、依存なし)。トラックCはT5-C3完了済み(1件)。T5-A12は引き続きT5-A17(`.claude/settings.night.json`設置、ユーザー実施待ち)がブロッカーのため着手不可。正本は`docs/android_release/開発運用基盤設計.md`・`検証強化設計.md`・`リリース計画書.md`。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASは`gas/Code.gs`をclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: `docs/bean_purchase_design.md`(追加購入・購入履歴)、`docs/store_master_design.md`(購入店マスタ)。
- **モデル分担ルール(2026-08-08改訂、恒久)**: 親セッションは既定でSonnet 5で起動する(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** タスク選定はモデルで分岐させない——依存が満たされた「⚠️上位モデルで実施」タスクがあれば`architect`へ優先委譲(成果物は設計書のみ)、無ければ通常タスクへフォールバックする。詳細・根拠は`CLAUDE.md`§日次改修ループ運用ルール・`docs/token_reduction_report_20260808.md`。
- **デプロイ・push運用ルール(2026-08-08改訂、恒久)**: `firebase deploy`・`clasp push`/`clasp redeploy`は**実行前に必ずチャットでユーザーの明示的な許可を得る**。**`git push`は`verifier`が全項目パスを報告済み(またはコード変更を含まない)なら確認不要**(未検証・検証NGのpushと`--force`系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細は`rules/lessons_archive.md` L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **親セッションは `/model sonnet`(Sonnet 5)で起動する。** `CLAUDE.md` §日次改修ループ運用ルールのモデル分担ルールに従う。Opus 5は`architect`サブエージェント経由でのみ使う。
>
> **次に着手するタスク(この順)**:
> 1. **T5-A4の独立検証**: `verifier`へ委譲し、以下を確認させる。(a) `tools\ui_probe.ps1 -Prepare`実行→JSON1行が返り`ok:true`(エミュレータの安定性次第で複数回試行が要る場合あり。implementer報告によると本セッションのサンドボックス環境ではエミュレータが起動後30〜90秒で自発的にクラッシュする不安定な挙動があった)。(b) `-Shot`で撮ったPNGを`Read`で開いて壊れていないこと。(c) `flutter build apk --debug`が再現性をもって通ること。(d) `.claude/ui_verify/`配下が`git status`に出ないこと(`.gitignore`動作確認)。OKなら`tools/ui_probe.ps1`・`.claude/agents/ui_verifier.md`・`.gitignore`・`docs/android_release/検証強化設計.md`(§H追記分)をpushする。
> 2. **T5-A4の完了条件の実地確認**(verifier検証後、親セッションが実施): `lib/screens/settings_screen.dart`のbody先頭に一時的に長文`Row`を挿入してoverflowを発生させる→`ui_verifier`エージェントを呼び出し画面ID 090(設定画面)を指定→項目1(Overflow)が「指摘あり」かつ`A RenderFlex overflowed by`のログ行が根拠として引用されることを確認→**同時にoverflowを仕込んでいない画面では「該当なし」になること(偽陽性が出ないこと)も確認**→`git checkout -- lib/screens/settings_screen.dart`で復旧。OKならマスタープランのT5-A4を完了済みリストへ移す。
> 3. その後は通常のタスク選定(依存なしのT5-A7〈T5-A6完了により依存充足〉/T5-A8/A13/A14/A15/A25のいずれか、タスク表順)。T5-A12はT5-A17(ユーザー実施待ち)がブロッカーのため引き続き選ばない。
>
> **§Hに記録された既知の制約**(次セッションで踏まないこと): ダークモードは`lib/main.dart`に`darkTheme`/`themeMode`が未実装のため、`ui_verifier`の項目5(ダークモード判読性)は現時点で検査不能(T5-B21完了まで「未実施」と報告させる仕様。指摘として扱わない)。UIAutomatorはFlutterのsemanticsノードを返さないことを実測済み(§5-2aの仮説は棄却、比率タップが唯一の操作手段)。`AndroidManifest.xml`にrelease/profileビルド用の`INTERNET`権限が無いことも判明(トラックBで対処要、T5-A4の範囲外)。

**タスクの正本は `docs/改修マスタープラン.md` §3。**

**サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化)**: `.claude/agents/`に3体——`architect`(設計・原因究明、**opus**固定)/`implementer`(実装、sonnet固定)/`verifier`(検証、sonnet固定)。`/start`・`/full_loop`では、**コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する**(モデルは各定義の`model:`で自動選択されるので`Agent`ツールに`model`を渡さない)。`architect`を呼ぶのは「⚠️上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は`/full_loop`スキル§サブエージェントへの委譲、要約は`CLAUDE.md`§日次改修ループ運用ルール。

**トラックAを完成させるまで製品開発(トラックB)は本格化させない**(夜間自動実行が無いと40〜60人日規模を消化できないため)。

**T5-A17(`.claude/settings.night.json`設置)は2026-08-09時点で未設置(ファイル自体が存在しない)ことを確認した**(2026-08-08時点の「untracked状態で存在」というメモは誤り、当時のセッションの一時的な状態だった可能性)。`tools/night_loop.ps1`は`-Force`指定時でも本ファイルの不在チェックはスキップしない設計のため、T5-A12(night_loop.ps1の有人試走)はこのファイルが無い限り実運用テストができない。ユーザーが`開発運用基盤設計.md` §4-4の内容をコピーして設置するまでT5-A12は着手不可。

**ユーザー実施待ちで着手不可**: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(11メソッドの推奨焙煎度設定)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)、T5-A17(`.claude/settings.night.json`設置)、T5-C1(Play Consoleデベロッパー登録$25。テスター12人は知り合いから確保可能なため律速ではなく、残るクリティカルパスはPlay Consoleの本人確認と14日間の待機のみ)。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。**コンテキスト200k超で単価が約2倍**になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約は`CLAUDE.md`§トークン運用規約、実測と削減設計は`docs/token_optimization_design.md`。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.52 当日やったこと(2026-08-09、**Sonnet 5**、`/full_loop`。**T5-C3完了+T5-A4実装完了(検証待ち)**)

- **選定理由**: 前回セッションの推奨どおりT5-C3(researcher実行)→トラックA最上位の未着手タスクを選定。T5-A6完了により依存が解けたT5-A4(依存: T5-A6のみ)がテーブル順でT5-A8より上位のため選定。
- **T5-C3**: `researcher`へ委譲。Play Console公開要件(クローズドテスト12名14日連続/targetSdkVersion Android16・API36が2026-08-31以降必須・猶予2026-11-01まで/データセーフティ申告/アカウント削除要件/課金・広告ポリシー)を一次情報中心に調査、出典URL・取得日つきで`docs/research/2026-08-09_play_requirements.md`に整理。T5-A5の終了条件(T5-C3の実行)も同時に満たしたため両方を完了済みリストへ。トラックCの完了済みリストを新設(1件目)。
- **T5-A4**: `ui_verifier`エージェント新設は「エミュレータをどう操作するか」という新規決定を伴うため、まず`architect`へ設計委譲。決定事項: 比率タップ(UIAutomatorはFlutterのsemanticsノードを返さないため不採用、実測で確認)/`adb screencap`+`pull`+`Read`でのスクショ判定(PowerShellの`>`リダイレクトはバイナリを壊すため禁止)/豆腐検出は2.5秒待機+再判定/ツールは`Read,Grep,Glob,PowerShell,ToolSearch`のみ(`Write`/`Edit`/`Bash`は与えない)/画面特定は親からのID指定を原則としフォールバックで`screen_registry.dart`から機械的に導出/Windows専用。`検証強化設計.md` §5-2aに実装詳細として追記(11小節)。**副産物の発見**: ダークモード未実装(項目5は検査不能)、release/profileビルドに`INTERNET`権限が無い(トラックB課題として記録)。
- 続けて`implementer`へ実装委譲。`tools/ui_probe.ps1`(9サブコマンド、UTF-8 BOM付き)・`.claude/agents/ui_verifier.md`を新設、`.gitignore`に`.claude/ui_verify/`追記、`flutter build apk --debug`成功を確認。実装中に2つの問題を発見・修正(PowerShell 5.1で`adb`の`2>$null`が`$ErrorActionPreference=Stop`下でErrorRecord化する不具合/`wm size`等のブート直後の空応答へのリトライ追加)。**このサンドボックス環境のAndroidエミュレータが起動後30〜90秒で自発的にクラッシュする不安定な挙動があった**(実装不備ではなく環境側の問題と判断)。
- **architectが102kトークン・implementerが150kトークン(実行時間45分)を要する規模になった**ため、T3-73dのセッション分割しきい値(ファイル数>5、実際は6ファイル touched)に該当。**T5-A4の独立検証(verifier)・完了条件の実地確認(overflow画面での指摘テスト)・push・マスタープラン進捗表更新は次セッションに持ち越し**。commitは実施、pushは未実施。
- コミット対象: `tools/ui_probe.ps1`(新規)、`.claude/agents/ui_verifier.md`(新規)、`docs/research/2026-08-09_play_requirements.md`(新規)、`.gitignore`、`docs/android_release/検証強化設計.md`(§5-2a新設+§H追記)、`docs/改修マスタープラン.md`(T5-A5・T5-C3完了)、`NEXT_SESSION.md`(本更新)。

> これ以前(-5.51節以前)の作業ログは **`docs/archive/NEXT_SESSION_log.md`** を参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID `trig_01W3iqfgRZYaVZvkY8Jc83gg`。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件は `CLAUDE.md`§日次改修ループ運用ルールと `/start`・`/end`・`/full_loop` スキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
