# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-09(**Sonnet 5**、`/full_loop`。**T5-A26完了(✅)+T5-A5(researcher.md新設、T5-C3実行は次回)+T5-A6実装完了(検証待ち)**。コスト超過($9>$7)によりT5-A6の独立検証・push・進捗表更新は次セッションへ持ち越し。commitのみ実施、**push未実施**)

> **本書の構成(2026-07-29改訂)**: 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに **直近1セッション分の作業ログだけ** を残す。それ以前は `docs/archive/NEXT_SESSION_log.md` へ退避済み(節番号・本文はそのまま)。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> **書き足しルール**: `/end`・`/full_loop`で当日ログを追記する際は「3. 直近の作業ログ」の**古い節をアーカイブ先頭へ移してから**新しい節を1件だけ置く(本書は常に1件)。完了タスクの実装内容は本書に長く書かず、要点(何を変えたか・次に効く制約)だけ書く。タスク定義・進捗の正本は `docs/改修マスタープラン.md`。**「1. 現状サマリ」「2. 次回の着手点」も同様に直近セッション分の要点だけを残し、過去の詳細経緯は`docs/archive/マスタープラン_完了タスク.md`・`docs/archive/NEXT_SESSION_log.md`に譲って書かない**(2026-08-08、T5-A21で明記)。

## 1. 現状サマリ

- **2026-08-09(`/full_loop`、Sonnet 5、Windows環境、本セッション): T5-A26完了(✅、Windows環境の`~/.claude/settings.json`にfrontend-designプラグイン有効化)**。**T5-A5は`.claude/agents/researcher.md`新設まで完了、T5-C3(Play要件調査)の実行は未実施**(新設エージェントは同一セッション直後は呼べない制約=L121のため。数ターン後にエージェント一覧へ反映されたことは確認済みで、次セッションなら即実行可)。**T5-A6は実装完了(Android SDK/JDK導入・AVD作成・`tools/emulator.ps1`/`.sh`新設)、implementerの自己確認(flutter devices・flutter doctor)は成功だが独立検証(verifier)は未実施のため検証待ち**。ユーザー依頼でWindows環境のトークン節約策(loop_guard.jsフック・verify.ps1配線・SKILL.md記載)の動作確認も実施、いずれも正常動作を確認(詳細は§3)。
- 進行中はマスタープラン **Phase 5**(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- **Phase 5トラックA(開発運用基盤)完了済み**: T5-A1・A2・A3・A9・A10・A11・A18〜A24・A26(14件)。**次点候補は T5-A6の独立検証(検証待ち)→T5-C3実行(researcherエージェント)→通常タスク(T5-A8/A13/A14/A15/A25、依存なし)**。T5-A12は引き続きT5-A17(`.claude/settings.night.json`設置、ユーザー実施待ち)がブロッカーのため着手不可。正本は`docs/android_release/開発運用基盤設計.md`・`検証強化設計.md`・`リリース計画書.md`。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASは`gas/Code.gs`をclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: `docs/bean_purchase_design.md`(追加購入・購入履歴)、`docs/store_master_design.md`(購入店マスタ)。
- **モデル分担ルール(2026-08-08改訂、恒久)**: 親セッションは既定でSonnet 5で起動する(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** タスク選定はモデルで分岐させない——依存が満たされた「⚠️上位モデルで実施」タスクがあれば`architect`へ優先委譲(成果物は設計書のみ)、無ければ通常タスクへフォールバックする。詳細・根拠は`CLAUDE.md`§日次改修ループ運用ルール・`docs/token_reduction_report_20260808.md`。
- **デプロイ・push運用ルール(2026-08-08改訂、恒久)**: `firebase deploy`・`clasp push`/`clasp redeploy`は**実行前に必ずチャットでユーザーの明示的な許可を得る**。**`git push`は`verifier`が全項目パスを報告済み(またはコード変更を含まない)なら確認不要**(未検証・検証NGのpushと`--force`系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細は`rules/lessons_archive.md` L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **親セッションは `/model sonnet`(Sonnet 5)で起動する。** `CLAUDE.md` §日次改修ループ運用ルールのモデル分担ルールに従う。Opus 5は`architect`サブエージェント経由でのみ使う。
>
> **次に着手するタスク(この順)**:
> 1. **T5-A6の独立検証**: `verifier`へ委譲し、`tools/emulator.ps1 -Start`実行→数分待って`flutter devices`に`emulator-5554`(Android 14 API 34)が出ること→`tools/emulator.ps1 -Stop`で正常終了・`adb devices`が空になること→`flutter doctor -v`で「No issues found!」であることを確認させる。OKならこのセッションのcommit分(`tools/emulator.ps1`・`.sh`・`.claude/agents/researcher.md`等)をpushし、マスタープランのT5-A6行を完了済みリストへ移す。
> 2. **T5-C3の実行**: `researcher`エージェントへ委譲。調査テーマはPlay Console新規公開要件4点(クローズドテスト要件/targetSdkVersion要件/データセーフティ記載要件/課金・広告ポリシー)、成果物は`docs/research/<日付>_play_requirements.md`。完了したらT5-A5・T5-C3をマスタープランの完了済みリストへ移す。
> 3. その後は通常のタスク選定(依存なしのT5-A8/A13/A14/A15/A25のいずれか、タスク表順)。T5-A12はT5-A17(ユーザー実施待ち)がブロッカーのため引き続き選ばない。

**タスクの正本は `docs/改修マスタープラン.md` §3。**

**サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化)**: `.claude/agents/`に3体——`architect`(設計・原因究明、**opus**固定)/`implementer`(実装、sonnet固定)/`verifier`(検証、sonnet固定)。`/start`・`/full_loop`では、**コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する**(モデルは各定義の`model:`で自動選択されるので`Agent`ツールに`model`を渡さない)。`architect`を呼ぶのは「⚠️上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は`/full_loop`スキル§サブエージェントへの委譲、要約は`CLAUDE.md`§日次改修ループ運用ルール。

**トラックAを完成させるまで製品開発(トラックB)は本格化させない**(夜間自動実行が無いと40〜60人日規模を消化できないため)。

**T5-A17(`.claude/settings.night.json`設置)は2026-08-09時点で未設置(ファイル自体が存在しない)ことを確認した**(2026-08-08時点の「untracked状態で存在」というメモは誤り、当時のセッションの一時的な状態だった可能性)。`tools/night_loop.ps1`は`-Force`指定時でも本ファイルの不在チェックはスキップしない設計のため、T5-A12(night_loop.ps1の有人試走)はこのファイルが無い限り実運用テストができない。ユーザーが`開発運用基盤設計.md` §4-4の内容をコピーして設置するまでT5-A12は着手不可。

**ユーザー実施待ちで着手不可**: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(11メソッドの推奨焙煎度設定)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)、T5-A17(`.claude/settings.night.json`設置)、T5-C1(Play Consoleデベロッパー登録$25。テスター12人は知り合いから確保可能なため律速ではなく、残るクリティカルパスはPlay Consoleの本人確認と14日間の待機のみ)。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。**コンテキスト200k超で単価が約2倍**になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約は`CLAUDE.md`§トークン運用規約、実測と削減設計は`docs/token_optimization_design.md`。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.50 当日やったこと(2026-08-09、**Sonnet 5**、`/full_loop`、Windows環境。**T5-A26完了+T5-A5(researcher.md新設)+T5-A6実装完了(検証待ち)+ユーザー依頼でWindows側トークン節約策の動作確認**)

- **選定理由**: Windows環境検出時はマスタープラン既定ルールによりT5-A26を最優先で着手。次いでタスク表順でT5-A5→(GB級インストールを伴うためユーザーに一言確認のうえ)T5-A6。
- **T5-A26**: `~/.claude/settings.json`にfrontend-designプラグインを有効化(マーケットプレイスキャッシュは既に同期済みだったため設定追加のみ)。マスタープラン完了済みリスト(トラックA、14件目)に追記済み。
- **T5-A5**: `.claude/agents/researcher.md`を`adversary.md`/`verifier.md`と同パターンで新設(`implementer`へ委譲)。**新設エージェントは同一セッション内では作成直後に呼び出せない制約(既知のL121)により、T5-C3の実行は持ち越し**。数ターン後にエージェント一覧へ`researcher`が反映されたことは確認済み(system-reminderで通知された)だが、本セッションはコスト超過のため実行せず次回に回した。
- **T5-A6**: `implementer`へ委譲。Android SDKコマンドラインツール一式・JDK 17をユーザーローカル環境(`%LOCALAPPDATA%\Android`)に導入、AVD `beanbase_test`(API 34, google_apis, x86_64)を作成、`tools/emulator.ps1`/`tools/emulator.sh`(起動/停止/状態確認、Windows/Ubuntu両対応)を新設。`flutter devices`にAVDが表示されること、`flutter doctor -v`が「No issues found!」になることを実測確認済み(**implementer自己申告であり、verifierによる独立検証はまだ未実施**)。実装中に2つのバグを発見・修正(`Write`ツールで保存した`.ps1`がBOM無しUTF-8になり日本語コメントがPowerShell 5.1の構文エラーを起こす/`adb`出力の一時的な空文字への`.Trim()`がnullエラーになる)、`rules/lessons_archive.md`にL127として記録。implementerのバックグラウンド実行が2回ほど「完了通知が来ないまま待機」状態になり、`SendMessage`での再開・`Monitor`での`adb devices`/プロセス監視で状況を直接確認しながら進行させた。
- **ユーザー依頼(Windows環境でのトークン節約策の動作確認)**: `loop_guard.js`フック出力は正常動作(毎ターン`[loop_guard] 本ループ...`が表示され、しきい値も正しく計算されている)。`tools/verify.ps1`を実際に実行し8項目全て`ok:true`を確認(analyze/test/build web/golden/codegen/secret_scan正常、`build_apk_release`は`lib/main_public.dart`未作成のためskip)。`start`/`full_loop`のSKILL.mdはpull後の最新版でT5-A19〜A22の内容(grep抽出・loop_guardフック依拠・`rules/verification.md`非全読み)が正しく反映済みと確認。**ただし本セッション冒頭で`/full_loop`起動時に注入されたスキル本文がgit pull前の古いスナップショットだったため、`.claude/loop_state.md`/`.claude/loop_failures.txt`を(本来不要な)Readをしてしまった一幕があった**——スキル呼び出し時のプロンプト注入とgit pullのタイミング差によるもので、Windows固有の不具合ではない(この現象自体は新規lessonとして記録するほどではないと判断、記録は見送り)。
- 本ループはT3-73dのセッション分割しきい値(cost>$7)を`$9`超で上回ったため、**T5-A6の独立検証・push・マスタープラン進捗表更新は次セッションに持ち越し**。commitは実施、pushは未実施。
- コミット対象: `.claude/agents/researcher.md`(新規)、`tools/emulator.ps1`・`tools/emulator.sh`(新規)、`docs/改修マスタープラン.md`(T5-A26完了・T5-A17状態の訂正)、`rules/verification.md`・`rules/lessons_archive.md`(L127追加)、`NEXT_SESSION.md`(本更新)。

> これ以前(-5.49節以前)の作業ログは **`docs/archive/NEXT_SESSION_log.md`** を参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID `trig_01W3iqfgRZYaVZvkY8Jc83gg`。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件は `CLAUDE.md`§日次改修ループ運用ルールと `/start`・`/end`・`/full_loop` スキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
