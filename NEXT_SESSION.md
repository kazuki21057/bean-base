# 次回開発再開時の手順書 (Next Session Handover)

最終更新: 2026-08-09(**Sonnet 5**、同一セッション継続の`/full_loop`。**T5-A32完了(implementer→verifier→ui_verifier)。`ui_probe.ps1`のdevice_lost検知を最大15分→10秒以内に短縮。T5-A4完了条件の再実行でoverflowはスクショ・dump実測で検出できたがログ行が取れない食い違いを発見、原因究明はT5-A36へ分離。コード変更は`tools/ui_probe.ps1`等2ファイルのみでデプロイ対象外**)

> **本書の構成(2026-07-29改訂)**: 「1. 現状サマリ」「2. 次回の着手点」を先頭に置き、その後ろに **直近1セッション分の作業ログだけ** を残す。それ以前は `docs/archive/NEXT_SESSION_log.md` へ退避済み(節番号・本文はそのまま)。他ドキュメントの「NEXT_SESSION.md『-4.xx』節参照」は、最新節以外ならアーカイブ側を見ること。
> **書き足しルール**: `/end`・`/full_loop`で当日ログを追記する際は「3. 直近の作業ログ」の**古い節をアーカイブ先頭へ移してから**新しい節を1件だけ置く(本書は常に1件)。完了タスクの実装内容は本書に長く書かず、要点(何を変えたか・次に効く制約)だけ書く。タスク定義・進捗の正本は `docs/改修マスタープラン.md`。**「1. 現状サマリ」「2. 次回の着手点」も同様に直近セッション分の要点だけを残し、過去の詳細経緯は`docs/archive/マスタープラン_完了タスク.md`・`docs/archive/NEXT_SESSION_log.md`に譲って書かない**(2026-08-08、T5-A21で明記)。

## 1. 現状サマリ

- **2026-08-09(`/full_loop`、Sonnet 5、`/clear`後の新規セッション): T5-A32(`ui_probe.ps1`改善)を`implementer`→`verifier`→`ui_verifier`で完了**。`Invoke-Prepare`を「ビルド→起動→install」順に再構成、`Invoke-Adb`共通ラッパー、`Assert-DeviceAlive`(プロセス生死でなく`adb get-state`応答性で判定、T5-A31のハング事象もカバーする設計)、`-Prepare -Retry`自動再試行、`-AvdName`既定値を`beanbase_ui`に統一。`verifier`がdevice_lost検知(要求10秒以内、実測8.6秒)・通常フロー・`analyze`(新規issue0件)を独立確認。**T5-A4完了条件の再実行で新知見**: overflowはスクショ・`-Dump`bounds実測で検出できたが、要求される`RenderFlex overflowed`ログ行は`-Log`で検出できず(`rules/lessons_archive.md` L130)。原因究明はT5-A36へ分離、T5-A4は完了済みへ移していない。**コード変更は`tools/ui_probe.ps1`・`.claude/agents/ui_verifier.md`のみ(`lib/`不変)のためデプロイ/本番確認は省略**。
- 進行中はマスタープラン **Phase 5**(Android公開版)がメインライン。Phase 1〜4(統計解析含む)は完了済み。Phase 3残件はT3-75gのみ(要ユーザー確認)。
- **Phase 5トラックA(開発運用基盤)完了済み**: T5-A1・A2・A3・A5・A6・A9・A10・A11・A18〜A24・A26・A27・A28・A30・A31・A32(21件)。**T5-A4はT5-A32でも完了条件未達(ログ行不一致、T5-A36の結論待ち)**。次点最優先は依存が満たされた通常タスク(T5-A33→A34→A35〈loop_guard改善、依存順〉、続いてT5-A36〈T5-A4のログ検出食い違いの原因究明〉、他にT5-A7/A8/A13/A14/A15/A25も依存なし。現時点で依存充足の⚠️上位モデルタスクは無し)。トラックCはT5-C3完了済み(1件)。T5-A12は引き続きT5-A17(`.claude/settings.night.json`設置、ユーザー実施待ち)がブロッカーのため着手不可。正本は`docs/android_release/開発運用基盤設計.md`・`検証強化設計.md`・`リリース計画書.md`。
- ストレージはGoogle Sheets+Drive(GAS Web App経由)。GASは`gas/Code.gs`をclaspで管理(現行デプロイ@19)。本番: https://beanbase-app-2016.web.app (Firebase Hosting)。
- 実装済みの正本設計書: `docs/bean_purchase_design.md`(追加購入・購入履歴)、`docs/store_master_design.md`(購入店マスタ)。
- **モデル分担ルール(2026-08-08改訂、恒久)**: 親セッションは既定でSonnet 5で起動する(`/model sonnet`)。**Opus 5は`architect`サブエージェント経由でのみ使い、親セッションでは使わない。** タスク選定はモデルで分岐させない——依存が満たされた「⚠️上位モデルで実施」タスクがあれば`architect`へ優先委譲(成果物は設計書のみ)、無ければ通常タスクへフォールバックする。詳細・根拠は`CLAUDE.md`§日次改修ループ運用ルール・`docs/token_reduction_report_20260808.md`。
- **デプロイ・push運用ルール(2026-08-08改訂、恒久)**: `firebase deploy`・`clasp push`/`clasp redeploy`は**実行前に必ずチャットでユーザーの明示的な許可を得る**。**`git push`は`verifier`が全項目パスを報告済み(またはコード変更を含まない)なら確認不要**(未検証・検証NGのpushと`--force`系は要確認)。分類器にブロックされた場合もサブエージェント委譲などで回避せず、ユーザーに相談する(詳細は`rules/lessons_archive.md` L91)。本番Sheets/Driveへのデータ書き込み(削除以外)は確認不要。

## 2. 次回の着手点

> **親セッションは `/model sonnet`(Sonnet 5)で起動する。** `CLAUDE.md` §日次改修ループ運用ルールのモデル分担ルールに従う。Opus 5は`architect`サブエージェント経由でのみ使う。
>
> **次に着手するタスク(この順)**: 現時点で依存充足の⚠️上位モデルタスクは無いため、通常タスクへフォールバックする。
> 1. **T5-A33(loop_guardの集計源修正)→T5-A34(ターン内再計算フック追加)→T5-A35(ループ境界の永続化)を順に実施**(T5-A28の改善策、依存順。T5-A32は2026-08-09完了済み)。実装仕様は`docs/token_optimization_design.md` §9-Eに確定済みのため`implementer`委譲でよい(`architect`不要)。T5-A34完了後は`full_loop`スキル手順1・3.5を「フック出力ではなく`.claude/loop_state.md`をReadして判定する」に改める必要がある(§9-Eに明記済み)。
> 2. **T5-A36(T5-A4のログ検出食い違いの原因究明)を実施**(T5-A32検証で発見。依存はT5-A32、完了済み)。設定画面にoverflowを仕込んでも`-Dump`/スクショでは検出できるのに`adb logcat`ベースの`-Log`ではログ行(`A RenderFlex overflowed by`)が1件も取れない原因を究明し、(a)ログ出力を復活させる対処、または(b)`.claude/agents/ui_verifier.md`とT5-A4完了条件(検証強化設計§5-2a-J(d))を「視覚的証拠+dump実測で正式根拠とする」形に緩和する、のいずれかを決める(`rules/lessons_archive.md` L130参照)。原因不明のバグ調査のため`architect`への委譲を検討してよい。結論後にT5-A4の完了条件を再実行して通ればT5-A4を完了済みへ移す。
> 3. その後は通常のタスク選定(依存なしのT5-A7/A8/A13/A14/A15/A25のいずれか、タスク表順)。T5-A12はT5-A17(ユーザー実施待ち)がブロッカーのため引き続き選ばない。
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

### -5.58 当日やったこと(2026-08-09、**Sonnet 5**、`/clear`後の新規セッションの`/full_loop`。**T5-A32完了(implementer→verifier→ui_verifier)。device_lost検知を最大15分→10秒以内に短縮。T5-A4再確認でログ検出の食い違いを発見しT5-A36へ分離**)

- **タスク選定**: NEXT_SESSION §2の推奨どおりT5-A32(`ui_probe.ps1`改善、T5-A27の改善策D-3)を選定(T5-A31完了で依存充足)。
- **T5-A32をimplementerへ委譲**: `Invoke-Prepare`を「ビルド→起動→install」順に再構成、`Invoke-Adb`共通ラッパー(adb呼び出しの終了コード確認)、`Assert-DeviceAlive`新設(プロセス生死でなく`adb get-state`応答性で判定、T5-A31のハング事象もカバーする設計)、`-Prepare -Retry`自動再試行、`.claude/agents/ui_verifier.md`絶対規則8を具体化。実装完了後、`-AvdName`既定値が旧`beanbase_test`のままという食い違いに気付き、T5-A31の既存決定(`beanbase_ui`)に揃える追加修正をimplementerへ依頼(新規設計判断ではなく既存決定への整合性修正と判断)。
- **verifierが独立検証(1回でまとめて実施)**: `flutter analyze`新規issue0件、device_lost検知を実地再現(kill後8.6秒、要求10秒以内)、通常フロー・`-Alive`サブコマンド正常動作、`git status`(変更2ファイルのみ)を1回の委譲でまとめて確認(検証委譲を1回に集約、ユーザー指示によるトークン節約策)。**なお1回目のverifier委譲ではバックグラウンド処理待ちの状態で報告が返り、再開(SendMessage)後に検証項目の指示内容自体を見失う不具合が発生**(サブエージェントの状態喪失、原因未調査)。項目を明記して再依頼し直すことで解消、次回同様の委譲時は要注意。
- **T5-A32完了条件のうちT5-A4再確認を実施**: implementerに設定画面へ一時的なoverflow(`Text('あ'*300)`)を挿入させ`flutter build apk --debug`→`ui_verifier`エージェントで画面ID 090を確認。**スクリーンショットの黄黒ストライプと`-Dump`のbounds実測(996×53pxが親幅超過)ではoverflowを明確に検出できたが、完了条件が要求する`A RenderFlex overflowed by`ログ行は`-Log`で2回実行とも0件**。偽陽性確認(overflow未仕込みのダッシュボードでは「該当なし」)はOK。原因未特定のため`rules/lessons_archive.md` L130に記録し、原因究明・完了条件見直しをT5-A36として新規タスク化。一時変更は`git checkout`で復旧済み。**T5-A4自体は完了済みへ移していない**(T5-A36の結論待ち)。
- **コード変更は`tools/ui_probe.ps1`・`.claude/agents/ui_verifier.md`のみ(`lib/`不変)** のため、`flutter test`/`flutter build`/デプロイ/本番確認は対象外。
- **軽量記録**: loop_guardのフック値は本ターン内では更新されず(次回`UserPromptSubmit`時に反映、T5-A33〜A35で解消予定)。サブエージェント合計は`implementer`(T5-A32本体136,062+`-AvdName`修正26,154)+`verifier`(1回目72,404+再開71,018+再依頼78,187、うち1回目・再開分の計143,422トークンは指示内容の見失いによる手戻り)+`implementer`(overflow挿入30,278)+`ui_verifier`(102,813)=**計516,916トークン**。ユーザー申告のProプラン使用率39%(開始時点、終了%は未取得。前回セッション終了時と同値のためセッション間で追加消費なし)を§8に記録。
- **ユーザーからの運用フィードバック**: 「検証はある程度まとめて実施すると節約になりそう。コード検証のルールはそのまま、その他の検証はタスクごとの粒度で(トークン都合の細切れではなく)まとめてよい」との指示を受け、今回はverifierへの検証委譲を1回に集約して対応した(詳細は`feedback_verification_batching.md`)。
- コミット対象: `docs/改修マスタープラン.md`(T5-A32完了済みリストへ移動、T5-A36新設)、`docs/archive/マスタープラン_完了タスク.md`(T5-A32詳細)、`docs/archive/NEXT_SESSION_log.md`(-5.57節退避)、`rules/lessons_archive.md`(L130追加)、`rules/verification.md`(L130索引追加)、`docs/token_optimization_design.md`(§7・§8追記)、`NEXT_SESSION.md`(本更新)。

> これ以前(-5.56節以前)の作業ログは **`docs/archive/NEXT_SESSION_log.md`** を参照。

## 4. その他

- クラウドルーティン(現在【無効化中】): ID `trig_01W3iqfgRZYaVZvkY8Jc83gg`。再開前に通知手段・完了時の停止運用・GitHub 接続を決めること。
- 日次ループの回し方・終了条件は `CLAUDE.md`§日次改修ループ運用ルールと `/start`・`/end`・`/full_loop` スキルが正本(ここには書かない)。
- 再開時のプロンプト例: 「/start を実行してください。」
