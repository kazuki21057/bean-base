# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-09(**Sonnet 5**、同一セッション継続の`/full_loop`。**T5-A31完了(implementer→verifier)。`emulator.ps1`の異常検知を180秒→約3秒に短縮。副次観察としてプロセス生存のままハングする事象を1回観測、T5-A32で対応予定。コード変更は`tools/emulator.ps1`等3ファイルのみでデプロイ対象外**)

> **本書の構成(2026-07-29改訂)**: 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに **直近1セッション分の作業ログだけ** を残す。それ以前は `docs/archive/NEXT_SESSION_log.md` へ退避済み(節番号・本文はそのまま)。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> **書き足しルール**: `/end`・`/full_loop`で当日ログを追記する際は「3. 直近の作業ログ」の**古い節をアーカイブ先頭へ移してから**新しい節を1件だけ置く(本書は常に1件)。完了タスクの実装内容は本書に長く書かず、要点(何を変えたか・次に効く制約)だけ書く。タスク定義・進捗の正本は `docs/改修マスタープラン.md`。**「1. 現状サマリ」「2. 次回の着手点」も同様に直近セッション分の要点だけを残し、過去の詳細経緯は`docs/archive/マスタープラン_完了タスク.md`・`docs/archive/NEXT_SESSION_log.md`に譲って書かない**(2026-08-08、T5-A21で明記)。

## 1. 現状サマリ

- **2026-08-09(`/full_loop`、Sonnet 5、同一セッション継続): T5-A31(`emulator.ps1`改善)を`implementer`→`verifier`で完了**。既定AVDを`beanbase_ui`に変更、`.claude/emu_logs/`へログ分離、起動待機ループに`HasExited`即時検知、`Clear-StaleEmulator`新設、`-Doctor`新設。`verifier`が強制kill後の検知が180秒→約3秒に短縮したことを実地確認。**副次観察**: 正常系確認中に1回、プロセスは生存したまま約9分ハングする事象を観測(`HasExited`では検知不能な失敗モード、T5-A32行に申し送り済み)。`-Stop`が`Clear-StaleEmulator`を呼ばず`multiinstance.lock`が残る軽微な差異も観測(次回`-Start`で自動解消、実害なし)。**コード変更は`tools/emulator.ps1`・`.gitignore`・`docs/改修マスタープラン.md`のみ(`lib/`不変)のためanalyze/test/build/デプロイ/本番確認は省略**。
- 進行中はマスタープラン **Phase 5**(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- **Phase 5トラックA(開発運用基盤)完了済み**: T5-A1・A2・A3・A5・A6・A9・A10・A11・A18〜A24・A26・A27・A28・A30・A31(20件)。**T5-A4はコード検証済みだが実地確認が環境要因で未達成(T5-A32のエミュレータ改善後に再試行)**。次点最優先は依存が満たされた通常タスク(T5-A32(`ui_probe.ps1`改善、T5-A31で観測したハング事象への対応も含めて確認)を優先、続いてT5-A33/A34/A35、他にT5-A8/A13/A14/A15/A25も依存なし。現時点で依存充足の⚠️上位モデルタスクは無し)。トラックCはT5-C3完了済み(1件)。T5-A12は引き続きT5-A17(`.claude/settings.night.json`設置、ユーザー実施待ち)がブロッカーのため着手不可。正本は`docs/android_release/開発運用基盤設計.md`・`検証強化設計.md`・`リリース計画書.md`。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASは`gas/Code.gs`をclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: `docs/bean_purchase_design.md`(追加購入・購入履歴)、`docs/store_master_design.md`(購入店マスタ)。
- **モデル分担ルール(2026-08-08改訂、恒久)**: 親セッションは既定でSonnet 5で起動する(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** タスク選定はモデルで分岐させない——依存が満たされた「⚠️上位モデルで実施」タスクがあれば`architect`へ優先委譲(成果物は設計書のみ)、無ければ通常タスクへフォールバックする。詳細・根拠は`CLAUDE.md`§日次改修ループ運用ルール・`docs/token_reduction_report_20260808.md`。
- **デプロイ・push運用ルール(2026-08-08改訂、恒久)**: `firebase deploy`・`clasp push`/`clasp redeploy`は**実行前に必ずチャットでユーザーの明示的な許可を得る**。**`git push`は`verifier`が全項目パスを報告済み(またはコード変更を含まない)なら確認不要**(未検証・検証NGのpushと`--force`系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細は`rules/lessons_archive.md` L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **親セッションは `/model sonnet`(Sonnet 5)で起動する。** `CLAUDE.md` §日次改修ループ運用ルールのモデル分担ルールに従う。Opus 5は`architect`サブエージェント経由でのみ使う。
>
> **次に着手するタスク(この順)**: 現時点で依存充足の⚠️上位モデルタスクは無いため、通常タスクへフォールバックする。
> 1. **T5-A32(`ui_probe.ps1`改善)を実施**(T5-A27の改善策、依存順。T5-A30・T5-A31は2026-08-09完了済み)。通常タスクのため`implementer`委譲でよい(`architect`不要)。**T5-A31検証時に、`emulator.ps1 -Start`がプロセスは生存したまま約9分ハングする事象を1回観測した**(WERにAPPCRASH記録なし、`adb devices`は空。`HasExited`では検知不能な失敗モード)。T5-A32の`Assert-DeviceAlive`死活監視がこのケースもカバーする設計になっているか、実装時に必ず確認すること(マスタープランT5-A32行に注記済み)。T5-A32完了後にT5-A4の実地確認を再試行: `lib/screens/settings_screen.dart`のbody先頭に一時的に`Row(children: [Text('あ' * 300)])`を挿入してoverflowを発生させる→`flutter build apk --debug`→`ui_verifier`エージェントを呼び出し画面ID 090(設定画面)を指定→項目1(Overflow)が「指摘あり」かつ`A RenderFlex overflowed by`のログ行が根拠として引用されることを確認→**同時にoverflowを仕込んでいない画面では「該当なし」になること(偽陽性が出ないこと)も確認**→`git checkout -- lib/screens/settings_screen.dart`で復旧。OKならマスタープランのT5-A4を完了済みリストへ移す。**旧AVDで実測されたダッシュボードのoverflow(320x640dpで21px)が新AVD `beanbase_ui`(1080x2400dp)でも再現するか確認**(T5-A30の5回検証では専用の画面確認は行っていない)、再現すれば実バグとして別タスク化する。
> 2. **T5-A33(loop_guardの集計源修正)→T5-A34(ターン内再計算フック追加)→T5-A35(ループ境界の永続化)を順に実施**(T5-A28の改善策、依存順)。実装仕様は`docs/token_optimization_design.md` §9-Eに確定済みのため`implementer`委譲でよい(`architect`不要)。T5-A34完了後は`full_loop`スキル手順1・3.5を「フック出力ではなく`.claude/loop_state.md`をReadして判定する」に改める必要がある(§9-Eに明記済み)。
> 3. その後は通常のタスク選定(依存なしのT5-A8〈T5-A32完了後はD-4を統合〉/A13/A14/A15/A25のいずれか、タスク表順)。T5-A12はT5-A17(ユーザー実施待ち)がブロッカーのため引き続き選ばない。
>
> **§Hに記録された既知の制約**(次セッションで踏まないこと): ダークモードは`lib/main.dart`に`darkTheme`/`themeMode`が未実装のため、`ui_verifier`の項目5(ダークモード判読性)は現時点で検査不能(T5-B21完了まで「未実施」と報告させる仕様。指摘として扱わない)。UIAutomatorはFlutterのsemanticsノードを返さないことを実測済み(§5-2aの仮説は棄却、比率タップが唯一の操作手段)。`AndroidManifest.xml`にrelease/profileビルド用の`INTERNET`権限が無いことも判明(トラックBで対処要、T5-A4の範囲外)。エミュレータは起動30秒後の安定確認後でも突然クラッシュすることがあり、待機時間を伸ばすだけでは解決しない(T5-A27で対処するまでui_verifier系タスクは着手コストが高い)。

**タスクの正本は `docs/改修マスタープラン.md` §3。**

**サブエージェント委譲(2026-08-05、ユーザー指示で恒久ルール化)**: `.claude/agents/`に3体——`architect`(設計・原因究明、**opus**固定)/`implementer`(実装、sonnet固定)/`verifier`(検証、sonnet固定)。`/start`・`/full_loop`では、**コードの実装と検証を親セッションが自分で行わず担当エージェントに委譲する**(モデルは各定義の`model:`で自動選択されるので`Agent`ツールに`model`を渡さない)。`architect`を呼ぶのは「⚠️上位モデルで実施」タスク・原因不明/再発バグ・implementerが2回失敗した時・フィールド名/画面ID等の新規決定を伴う時。正本は`/full_loop`スキル§サブエージェントへの委譲、要約は`CLAUDE.md`§日次改修ループ運用ルール。

**トラックAを完成させるまで製品開発(トラックB)は本格化させない**(夜間自動実行が無いと40〜60人日規模を消化できないため)。

**T5-A17(`.claude/settings.night.json`設置)は2026-08-09時点で未設置(ファイル自体が存在しない)ことを確認した**(2026-08-08時点の「untracked状態で存在」というメモは誤り、当時のセッションの一時的な状態だった可能性)。`tools/night_loop.ps1`は`-Force`指定時でも本ファイルの不在チェックはスキップしない設計のため、T5-A12(night_loop.ps1の有人試走)はこのファイルが無い限り実運用テストができない。ユーザーが`開発運用基盤設計.md` §4-4の内容をコピーして設置するまでT5-A12は着手不可。

**ユーザー実施待ちで着手不可**: T3-1 / T3-4(モバイル実機確認・UI磨き込み、T3-20の残り確認待ち)、T3-57(Youth3件の写真提供待ち)、T3-72f(11メソッドの推奨焙煎度設定)、T3-75g(残豆量の分母不整合の補正方針、要ユーザー確認)、T5-A17(`.claude/settings.night.json`設置)、T5-C1(Play Consoleデベロッパー登録$25。テスター12人は知り合いから確保可能なため律速ではなく、残るクリティカルパスはPlay Consoleの本人確認と14日間の待機のみ)。

### トークン運用(2026-08-02追加)

1ループのコストは「リクエスト数 × 平均コンテキスト長」でほぼ決まる。**コンテキスト200k超で単価が約2倍**になるため、実装が長引いたら無理に1セッションで完走せず分割する。規約は`CLAUDE.md`§トークン運用規約、実測と削減設計は`docs/token_optimization_design.md`。

**Proプラン使用率ログ(2026-08-09追加)**: ユーザーがセッション開始時・終了時の使用量(%)を申告してくれる場合、`docs/token_optimization_design.md` §8 に記録する(申告が無いループは書かない)。目的は`loop_guard`のコスト実測($)と使用率(%)の対応関係を蓄積し、換算精度を上げること。次回`/full_loop`・`/start`実行時、ユーザーが開始%を申告したら同様に記録すること。

## 3. 直近の作業ログ(最新1セッションのみ)

### -5.57 当日やったこと(2026-08-09、**Sonnet 5**、同一セッション継続の`/full_loop`。**T5-A31完了(implementer→verifier)、異常検知180秒→約3秒に短縮。副次観察でハング事象を発見しT5-A32へ申し送り**)

- **タスク選定**: タスク表順でT5-A31(`emulator.ps1`改善、T5-A27の改善策D-2)を選定(T5-A30完了で依存充足)。
- **T5-A31をimplementerへ委譲**: `$AvdName`既定値を`beanbase_ui`に変更、起動引数へ`-no-snapshot -no-audio -no-boot-anim`追加+`.claude/emu_logs/`へログ分離(`.gitignore`追記)、起動待機ループ2箇所に`$process.HasExited`即時検知を追加、`Clear-StaleEmulator`(残存プロセスkill+lock削除)新設、`-Doctor`(config.ini主要値+accel-check+直近30分APPCRASH件数を1行JSON)新設。
- **verifierが独立検証**: 強制kill後の検知が**180秒→約3秒**に短縮したことを実地確認、`Clear-StaleEmulator`による後始末も確認。正常系(`-Start`→`ui_probe`→`-Stop`)・`-Doctor`単体・`git status`(変更3ファイルのみ)もOK。
- **副次観察(3点、完了条件外の追加発見)**: ①正常系確認中に1回、`-Start`がプロセスは生存したまま**約9分ハング**する事象を観測(WERにAPPCRASH記録なし、`adb devices`が空)——`HasExited`では検知できない失敗モード。**T5-A32の`Assert-DeviceAlive`死活監視でカバーされる設計か実装時に確認**する注記をマスタープランT5-A32行に追加。②バックグラウンドタスク終了コード255とログ上の成功メッセージの食い違い(T5-A6で確認済みの既知の無害パターンと同型)。③`-Stop`が`Clear-StaleEmulator`を呼ばず`multiinstance.lock`が残存(次回`-Start`で自動解消、実害なし)。
- **コード変更は`tools/emulator.ps1`・`.gitignore`・`docs/改修マスタープラン.md`のみ(`lib/`不変)** のため、`analyze`/`test`/`build`/デプロイ/本番確認は省略し`/end`手順へ直行。
- **軽量記録**: loop_guard本ループは`cost=$8.112/$24, turns=3/30, fails=0/3`(T5-A31検証完了時点の値)。`docs/token_optimization_design.md` §7に記録予定(implementer 67,427トークン+verifier 66,272トークン+2回目の指示継続分を含む=計約13.4万トークン)。
- コミット対象: `docs/改修マスタープラン.md`(T5-A31完了済みリストへ移動、T5-A32へ申し送り注記)、`docs/archive/マスタープラン_完了タスク.md`(T5-A31詳細)、`docs/archive/NEXT_SESSION_log.md`(-5.56節退避)、`docs/token_optimization_design.md`(§7追記)、`NEXT_SESSION.md`(本更新)。

> これ以前(-5.55節以前)の作業ログは **`docs/archive/NEXT_SESSION_log.md`** を参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID `trig_01W3iqfgRZYaVZvkY8Jc83gg`。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件は `CLAUDE.md`§日次改修ループ運用ルールと `/start`・`/end`・`/full_loop` スキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
