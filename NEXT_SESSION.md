# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-09(**Sonnet 5**、同一セッション継続の`/full_loop`。**T5-A36は「検証待ち」。architectが原因究明(structured errorsが既定有効なためFlutterErrorがlogcatに出ない)→implementerが`--dart-define`追加等T1〜T9を実装済み。本ループコストが$7超のためセッション分割、verifierへの委譲は次セッションへ持ち越し(push未実施、commitのみ)**)

> **本書の構成(2026-07-29改訂)**: 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに **直近1セッション分の作業ログだけ** を残す。それ以前は `docs/archive/NEXT_SESSION_log.md` へ退避済み(節番号・本文はそのまま)。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> **書き足しルール**: `/end`・`/full_loop`で当日ログを追記する際は「3. 直近の作業ログ」の**古い節をアーカイブ先頭へ移してから**新しい節を1件だけ置く(本書は常に1件)。完了タスクの実装内容は本書に長く書かず、要点(何を変えたか・次に効く制約)だけ書く。タスク定義・進捗の正本は `docs/改修マスタープラン.md`。**「1. 現状サマリ」「2. 次回の着手点」も同様に直近セッション分の要点だけを残し、過去の詳細経緯は`docs/archive/マスタープラン_完了タスク.md`・`docs/archive/NEXT_SESSION_log.md`に譲って書かない**(2026-08-08、T5-A21で明記)。

## 1. 現状サマリ

- **2026-08-09(`/full_loop`、Sonnet 5、同一セッション継続): T5-A36は「検証待ち」状態**。`architect`が根本原因を特定: Flutter debugビルドは既定でstructured errorsが有効なため、`FlutterError`(overflow等)はVM Serviceの`Flutter.Error`拡張イベントに送られ、`flutter run`アタッチ無しの単独起動では受信側が無くlogcatに一切出力されない。`--dart-define=flutter.inspector.structuredErrors=false`をビルド時に付与すれば解消することを実機検証済み(architectが実機で再現・修正・再検証まで完了)。`implementer`がT1〜T9(`tools/ui_probe.ps1`にdart-define追加+overflow正規表現一般化+`-v time`化、`検証強化設計.md`・`ui_verifier.md`・`rules/lessons_archive.md` L130の記述更新)を実装済み。**変更対象**: `tools/ui_probe.ps1`、`docs/android_release/検証強化設計.md`、`.claude/agents/ui_verifier.md`、`rules/lessons_archive.md`(4ファイル、`lib/`不変)。**次にやるべき検証手順**: `verifier`に委譲し、`tools/ui_probe.ps1 -Prepare`でdart-define付きビルドが完走すること、意図的なoverflow(設定画面等)で`-Log`の`hits.overflow`が1件以上検出され`A RenderFlex overflowed by N pixels...`が拾えること(T5-A4完了条件の再実行)、overflowを仕込んでいない画面で偽陽性が出ないことを確認する。通れば**T5-A4を完了済みへ移す**。**副次発見**: `font_scale 2.0`+`density 560`条件で現行UIに実際のoverflowが2箇所(ダッシュボードのおすすめレシピカード周辺)見つかった。本タスク範囲外のため別タスク化を検討(未着手・未タスク化)。
- 進行中はマスタープラン **Phase 5**(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- **Phase 5トラックA(開発運用基盤)完了済み**: T5-A1・A2・A3・A5・A6・A9・A10・A11・A18〜A24・A26・A27・A28・A30〜A35(24件)。**T5-A36は検証待ち(上記)、通れば完了済みへ**。T5-A4はT5-A36完了後に完了条件を再実行する。他にT5-A7/A8/A13/A14/A15/A25/A29も依存なし(現時点で依存充足の⚠️上位モデルタスクは無し)。トラックCはT5-C3完了済み(1件)。T5-A12は引き続きT5-A17(`.claude/settings.night.json`設置、ユーザー実施待ち)がブロッカーのため着手不可。正本は`docs/android_release/開発運用基盤設計.md`・`検証強化設計.md`・`リリース計画書.md`。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASは`gas/Code.gs`をclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: `docs/bean_purchase_design.md`(追加購入・購入履歴)、`docs/store_master_design.md`(購入店マスタ)。
- **モデル分担ルール(2026-08-08改訂、恒久)**: 親セッションは既定でSonnet 5で起動する(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** タスク選定はモデルで分岐させない——依存が満たされた「⚠️上位モデルで実施」タスクがあれば`architect`へ優先委譲(成果物は設計書のみ)、無ければ通常タスクへフォールバックする。詳細・根拠は`CLAUDE.md`§日次改修ループ運用ルール・`docs/token_reduction_report_20260808.md`。
- **デプロイ・push運用ルール(2026-08-08改訂、恒久)**: `firebase deploy`・`clasp push`/`clasp redeploy`は**実行前に必ずチャットでユーザーの明示的な許可を得る**。**`git push`は`verifier`が全項目パスを報告済み(またはコード変更を含まない)なら確認不要**(未検証・検証NGのpushと`--force`系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細は`rules/lessons_archive.md` L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **親セッションは `/model sonnet`(Sonnet 5)で起動する。** `CLAUDE.md` §日次改修ループ運用ルールのモデル分担ルールに従う。Opus 5は`architect`サブエージェント経由でのみ使う。
>
> **セッション分割からの再開(T3-73d)**: 直近セッションはT5-A36の実装(T1〜T9)が完了しコミット済み(pushは未実施)の状態で、コスト$7超によりセッションを分割した。**次回`/full_loop`(または`/full_loop 検証のみ`)ではタスク選定・実装をスキップし、手順4(検証)から再開する**——`verifier`にT5-A36の変更(`tools/ui_probe.ps1`・`docs/android_release/検証強化設計.md`・`.claude/agents/ui_verifier.md`・`rules/lessons_archive.md`)を委譲し、`-Prepare`のdart-define付きビルド完走・意図的overflowでの`-Log`検出(`hits.overflow`≥1、`A RenderFlex overflowed by N pixels...`)・偽陽性なしを確認する。通れば`docs/改修マスタープラン.md`のT5-A36を完了済みへ移し、**T5-A4の完了条件(検証強化設計§5-2a-J(d))も再実行して通れば併せて完了済みへ**。
>
> **その後の次点タスク(この順)**:
> 1. T5-A36検証OK後、通常のタスク選定(依存なしのT5-A7/A8/A13/A14/A15/A25/A29のいずれか、タスク表順)。T5-A12はT5-A17(ユーザー実施待ち)がブロッカーのため引き続き選ばない。
> 2. **副次発見の別タスク化を検討**: T5-A36調査中、`font_scale 2.0`+`density 560`条件で現行UI(ダッシュボードのおすすめレシピカード周辺と推定・未確定)に実際のoverflowが2箇所見つかった。アクセシビリティ観点のタスクとして`docs/改修マスタープラン.md`に新規ID(例: T5-A37)で追加するか判断すること(まだタスク化していない)。
> 3. **T5-A35の残課題**: 本番セッションで実際に行頭以外の`/full_loop`(§9-Cの条件)を踏んだ際、`.claude/loop_boundary.txt`が正しく生成・維持されるかの実地確認がまだ無い。次回そのような入力が発生したら`.claude/loop_boundary.txt`の有無・内容を確認するとよい(必須タスクではない、気づいたら確認する程度)。
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

### -5.62 当日やったこと(2026-08-09、**Sonnet 5**、同一セッション継続の`/full_loop`。**T5-A36「検証待ち」——architect(原因究明)→implementer(T1〜T9実装)完了、verifierへの委譲はコスト超過によりセッション分割で次回へ持ち越し**)

- **タスク選定**: NEXT_SESSION §2の推奨どおりT5-A36(T5-A4のログ検出食い違いの原因究明、依存T5-A32完了済み)を選定。原因不明のバグ調査のため`architect`へ先に委譲。
- **architectが根本原因を特定**: Flutter debugビルドは既定で`flutter.inspector.structuredErrors`が有効(`widget_inspector.dart`)なため、`FlutterError`(overflow等)は`debugPrint`ではなくVM Serviceの`Flutter.Error`拡張イベントに送られる。`flutter run`アタッチ無しの単独起動(`adb install`)では受信側が存在せず、logcatに一切出力されない——ログタグ・正規表現・ビルドモードの問題ではなかった。`--dart-define=flutter.inspector.structuredErrors=false`を付与すれば解消することを実機(エミュレータ)で再現・修正・再検証まで完了。**L130の既存記述の誤りも発見**: 「`-Dump`のbounds実測で検出できた」という記述は誤りで、実際のdump最大ノードは画面幅内に収まっており、はみ出しノードは存在しなかった(uiautomator dumpはFlutterのoverflow検出根拠に使えない)。副次的に、`font_scale 2.0`+`density 560`条件で現行UIに実際のoverflow(ダッシュボードのおすすめレシピカード周辺と推定)が2箇所見つかった(本タスク範囲外、要別タスク化)。
- **implementerがT1〜T9を実装**: `tools/ui_probe.ps1`にビルド時`--dart-define=flutter.inspector.structuredErrors=false`追加・overflow正規表現を`A Render\w+ overflowed by`に一般化・logcat取得を`-v time`化・`-SkipBuild`使用時の注意追記。`docs/android_release/検証強化設計.md`(§B/§C/判定表)、`.claude/agents/ui_verifier.md`(絶対規則に項目9追加、判定根拠をログ or 視覚証拠の二択に限定・`-Dump`bounds不可)、`rules/lessons_archive.md`(L130の原因を特定済みに更新、誤記述を撤回)を更新。
- **セッション分割(T3-73d)を適用**: `.claude/loop_state.md`記載の本ループコストが$11.94(親$1.57+サブ$10.37・2体〈architect+implementer〉)で$7超過のため、`verifier`への検証委譲は行わずここでセッションを終える。commitのみ実施しpushは見送り。次回`/full_loop`(または`/full_loop 検証のみ`)は手順4(検証)から再開し、verifierに委譲する。
- **軽量記録**: loop_guard記載値`cost=$11.9439/$24, turns=0/30`(内訳: 親$1.5700/サブ$10.3740・2体〈architect+implementer〉)。ユーザー申告のProプラン使用率46%(セッション開始時点、終了%は次回申告待ち)を§8に記録予定(次回セッションでverifier分の消費と合わせて記録する)。
- **変更ファイル(未push)**: `tools/ui_probe.ps1`、`docs/android_release/検証強化設計.md`、`.claude/agents/ui_verifier.md`、`rules/lessons_archive.md`(4ファイル、`lib/`不変)。
- コミット対象: 上記4ファイル+`docs/archive/NEXT_SESSION_log.md`(-5.61節退避)、`NEXT_SESSION.md`(本更新)。**マスタープランのT5-A36完了移動・完了タスクアーカイブへの詳細記載・§7/§8のトークンログ追記は、verifier検証OK後の次回セッションで行う(現時点ではT5-A36はまだ⬜のまま)**。

> これ以前(-5.59節以前)の作業ログは **`docs/archive/NEXT_SESSION_log.md`** を参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID `trig_01W3iqfgRZYaVZvkY8Jc83gg`。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件は `CLAUDE.md`§日次改修ループ運用ルールと `/start`・`/end`・`/full_loop` スキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
