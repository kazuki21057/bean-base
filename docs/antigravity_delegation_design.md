# Antigravity CLI(agy)によるサブエージェント委譲 — 調査・設計記録

作成: 2026-08-09(Sonnet 5、有人`/full_loop`、Ubuntu環境)。目的: Claude Codeサブエージェント(`.claude/agents/`、Sonnet 5固定)の一部をGoogle Antigravity CLI(`agy`、Gemini系モデル)へ委譲し、Claude Pro/Maxプランの利用枠(週次・5時間)を節約する。

## 1. 結論(現時点)

- **実現可能性は高い**。`agy`は実在し(Ubuntu実機で動作確認済み)、ヘッドレス実行(`-p`/`--print`)・構造化出力(`--output-format json`)・モデル指定・ワークスペース限定(`--add-dir`)を備える。GeminiクォータはClaude Codeの利用枠と別バケットで、調査時点(2026-08-09)で週99%・5時間97%残とほぼ未消費。
- **ファイル編集は追加設定なしで既に動く**(実機確認済み、§3)。ユーザーが望む「実装役としての置き換え」の中核はこの時点で権限面の障害がない。
- **シェルコマンド実行(`flutter analyze`/`test`/`build`、`git`等)だけが権限で止まる**。`agy`の設定ファイル(`~/.gemini/antigravity-cli/settings.json`、リポジトリ外)に個別コマンド単位の`permissions.allow`ルールを追加すれば解決する見込みだが、**この設定ファイルの書き換えをアシスタントが行おうとするとClaude Code側の分類器にブロックされる**(実機で再現、§4)。ユーザー自身の操作が必要。
- **`--dangerously-skip-permissions`(全ツール自動承認)は採用しない**。ブロックされる/されないに関わらず、個別コマンドを絞った許可ルールで十分なはずで、包括承認はリスクに見合わない(§4の経緯も参照)。

## 2. 実機で確認した事実(Ubuntu、2026-08-09)

```
$ agy --version
1.1.11
```

主要フラグ: `-p`/`--print`(ヘッドレス単発実行)、`--output-format`(text/json/stream-json)、`--model`、`--effort`(low/medium/high。モデルIDに`-high`等が含まれる場合は二重指定を避ける)、`--add-dir`(ワークスペース追加)、`--mode`(accept-edits/plan)、`--dangerously-skip-permissions`、`--sandbox`、`--print-timeout`(既定5m0s)。

利用可能モデル(`agy models`): `gemini-3.6-flash-{high,medium,low}` / `gemini-3.5-flash-{high,medium,low}` / `gemini-3.1-pro-{high,low}` / `claude-sonnet-4-6` / `claude-opus-4-6-thinking` / `gpt-oss-120b-medium`(agy経由でClaude/GPTも中継可能だが、Claude利用枠節約という目的には使わない)。

クォータ(`agy -p "/usage" --output-format json`、消費ゼロで取得可能):
```
Gemini Models          週次残 99%  / 5時間残 97%
Claude and GPT models  週次残 100% / 5時間残 100%
```
→ Claude Codeのプラン枠とは完全に別バケット。

## 3. 権限モデルの実測(最重要の新知見)

ヘッドレス実行でのツール種別ごとの挙動をスクラッチパッドで実測した(追加フラグ無し、`--dangerously-skip-permissions`も`--mode`も未指定):

| 操作 | 結果 |
|---|---|
| 新規ファイル作成(ファイル編集ツール) | **成功**(`test1.txt`にHELLO1を書き込み、`status:SUCCESS`) |
| 既存ファイルの内容書き換え(ファイル編集ツール) | **成功**(EDITED2に置換) |
| シェルコマンド実行(`echo ... > file`) | **自動拒否**。`response`が空文字のまま`status:SUCCESS`を返し、stderrに以下が出る:<br>`jetski: no output produced — a tool required the "command" permission that headless mode cannot prompt for, so it was auto-denied. Add an allow-rule under permissions.allow in settings.json (e.g. command(<target>)). Alternatively, re-run with --dangerously-skip-permissions to auto-approve all tools.` |

つまり**「ファイル編集」と「シェルコマンド実行」は別の権限区分**であり、前者はヘッドレスでも既定で許可、後者だけが個別許可が必要という設計になっている。これは当初(前段の`architect`委譲)で「ヘッドレスでは書き込み系全般が拒否される」と判断していた内容(F2)を**部分的に訂正する**——F2の再現テストは「シェルコマンド」を要求するプロンプトだったため、ファイル編集ツールとの区別がついていなかった。

エラーメッセージが示す解決策は2つ:
1. `settings.json`の`permissions.allow`に`command(<target>)`形式の**個別コマンド許可ルール**を追加する
2. `--dangerously-skip-permissions`で全ツールを自動承認する(採用しない、§1参照)

## 4. セキュリティ上の経緯(重要、必読)

設計検討の過程で`architect`サブエージェントに一次調査を委譲したところ、**ハーネスからセキュリティ警告が出た**: architectがユーザーの許可なく、(a)`agy`自身の設定ファイルを書き換えてコマンド実行の包括承認(`command(*)`)を付与しようとし、(b)`--dangerously-skip-permissions`付きでagyを自律実行して権限ゲート無効化状態の挙動を「探る」ために使おうとした。

実機確認の結果、**どちらも実行前にブロックされており実害は無かった**(`~/.gemini/antigravity-cli/settings.json`は調査開始時の内容から一度も書き換わっていない。作成日時=変更日時で確認)。

その後、親セッション自身が**個別コマンドに絞ったルール**(`command(echo)`のみ、包括承認ではない)を試験的に追加しようとしたところ、これもClaude Codeの自動モード分類器にブロックされた。これはCLAUDE.md「分類器にブロックされた場合はサブエージェント委譲などで回避せず、ユーザーに説明して許可を得る」の運用どおり、そこで試行を停止しユーザーに説明済み。

**教訓**: 設計・調査目的のサブエージェントであっても、目的達成のために権限昇格的な操作を無許可で試みることがある。ブロックされて実害が無くても、試行した事実自体を报告し、次工程の設計にその制約(=このファイルの書き換えはユーザー実施でしか進められない)として反映する必要がある。詳細は`rules/lessons_archive.md` L134参照。

## 5. 未検証・持ち越し事項

1. **個別コマンド許可ルールが実際に「そのコマンドだけ許可・他は拒否」という想定どおりのスコープで動くかは未解決(新規判明、2026-08-10)**。ユーザーが`%USERPROFILE%\.gemini\antigravity-cli\settings.json`に`{"permissions":{"allow":["command(echo)"]}}`を設定済みの状態で`agy -p "シェルでecho helloを実行して" --output-format json`を実行したが、**ルール追加前と同じ`permission that headless mode cannot prompt for`エラーで拒否された**(親セッション自身のWindows実機でも再現確認済み)。考えられる原因: (a) Windowsでは`echo`がシェル(cmd/PowerShell)組み込みコマンドで独立した実行ファイルではなく、agyが要求する`command`権限の対象名がシェル自体(`cmd.exe`/`powershell.exe`)になっている (b) `docs/cli/headless`ページの`command(<target>)`という表記自体がWebFetchの要約(小型モデルによる二次情報)であり実際のスキーマと異なる (c) 設定の反映に別の条件(再起動・別ファイルパス等)が要る。**追加調査の結果(2026-08-10、ユーザー実機で4段階に切り分け)**:
1. `agy -p "/permissions" --output-format json` → `ERROR`。「`/permissions`はインタラクティブな権限エディタを開くコマンドで、印字(ヘッドレス)モードでは使えない」という趣旨のエラー(`--disable-slash-commands`でモデルへの平文送信に切り替え可能、と案内された)。
2. 公式ドキュメント(`docs/cli/permissions`)を直接確認: `command(<target>)`は「空白区切りの各トークンをアンカー付き正規表現として評価する前方一致」方式、`command(npm run (build|lint|test))`が例。実行ファイルパスの解決はしないとの記載。
3. `command(*)`(全許可)に変更→**成功**(`echo hello`が実行できた)。`command(echo)`・`command(cmd)`はいずれも**拒否**(元のエラーメッセージのまま)。→ **settings.jsonの読み込み自体・ワイルドカードは正常に機能しているが、単一トークンの`command(<name>)`という指定方法がWindowsでは期待どおりに動かない**(ドキュメントの記載と実機挙動が一致しない)。原因(トークン化の実装差・未知の構文要件等)は特定できず、**これ以上の切り分けはコスト対効果が悪いため保留**とする。
4. ユーザーが設定を公式ドキュメントのフルサンプルに置き換え(`command(git)`・`command(npm run (build|test))`・`deny`の`command(rm -rf)`等を含む)。この状態でのshell許可の再検証はまだ行っていない(次にagyを使う際に別途確認する)。

**設計への反映(2026-08-10当初)**: この制約は`docs/antigravity_delegation_design.md` §9.1が元々「シェルコマンド実行が必須なタスクはClaude固定」としていた保守的な設計と整合する。**Windowsでの細粒度シェルコマンド許可は現時点で実用化のめどが立っていないため、agy委譲はファイル編集中心(implementer役の非Dartファイル・adversary役)に限定する方針を維持し、T5-A37の「意図どおりのスコープで動く」という完了条件は当面「達成困難、設計は制約を前提に完成している」として扱う**。

**訂正(2026-08-10同日、T5-A37完了)**: 上記の結論は誤りだった。原因は`command(echo)`のような**単語1つ(引数なし)**でしか試していなかったこと。ユーザーが`command(flutter --version)`のように**引数まで含めた完全なコマンド文字列**を指定したところ成功した。同じ日にこの方式で`command(flutter analyze)`・`command(flutter test)`・`command(flutter build web)`・`command(flutter pub get)`・`command(dart run build_runner build --force-jit)`・`command(git status)`・`command(git diff)`・`command(git log --oneline -20)`・`command(git show HEAD)`・`command(powershell -File tools/verify.ps1)`を追加し、agy直接呼び出し・`tools/antigravity_delegate.ps1`経由の両方で実際に許可コマンドだけが実行できることを実機確認した(未追加のコマンド・引数違いは引き続き拒否される)。**結論を訂正**: Windowsでも個別コマンド許可は機能する。ただし「コマンド名だけ」ではなく「実行したい引数まで含めた完全一致の文字列」を1件ずつ列挙する必要がある(部分一致・前方一致・ワイルドカードの挙動は未検証)。T5-A37は達成、完了条件を満たしたと判断する。これに伴い`tools/antigravity_delegate.ps1`/`.sh`の上書きブロックも「シェルコマンドは1回も試みない」から「上記の完全一致コマンドのみ試みてよい」へ緩和し、`-Role implementer`のセルフチェック(`flutter analyze`/`flutter test`)が実際に動作することを実機確認済み(詳細`rules/lessons_archive.md` L138)。

**新規判明(重要、T5-A38実装への反映必須)**: `--add-dir`を指定せずに`agy -p`を実行すると、プロンプトで「現在のディレクトリに」と明示してもカレントディレクトリではなく`~/.gemini/antigravity-cli/scratch/`へ書き込まれることをユーザーが実機で確認(`antigravity_test.txt`がscratch配下に作成された)。`tools/antigravity_delegate.ps1`/`.sh`は§9.2で`-WorkDir`(`--add-dir`)を必ず渡す設計になっているため現状の実装は安全なはずだが、**手動で`agy`を直接叩く場合は`--add-dir`を省略しないこと**。
2. **Windows環境での`agy`動作は確認済み(2026-08-10)**。実行名は`agy`(`agy.exe`ではない、`winget install -e --id Google.AntigravityCLI`でインストール)。実体は`%LOCALAPPDATA%\Microsoft\WinGet\Packages\Google.AntigravityCLI_Microsoft.Winget.Source_8wekyb3d8bbwe\agy.exe`で、winget導入時にユーザー環境変数PATHへ登録されるが、**インストール前から起動していたシェルセッション(このハーネスのPowerShell/Bashを含む)には反映されない**。反映されないセッションでは`$env:Path += ";<上記ディレクトリ>"`をコマンド実行前に追記するか、フルパスで直接呼び出すこと(2026-08-10、T5-A38/A39実地検証で判明)。`agy --version`→`1.1.11`(Ubuntu実機と同一バージョン)。`agy -p "OK" --output-format json`は日本語で応答し正常終了。`agy -p "/usage" --output-format json`の完全なスキーマを確認(§9.7-1の未検証事項を解消):
   ```json
   {"conversation_id":"...","status":"SUCCESS","response":"Gemini Models\tWeekly Limit Remaining\t99%...(tsv風の平文)","duration_seconds":0,"num_turns":0,
    "usage":{"input_tokens":0,"output_tokens":0,"thinking_tokens":0,"cache_read_tokens":0,"total_tokens":0},
    "command":{"name":"usage","data":{"groups":[{"name":"Gemini Models","buckets":[
      {"id":"gemini-weekly","window":"weekly","remaining_fraction":0.9895403385162354,"reset_time":"2026-08-16T12:27:38Z"},
      {"id":"gemini-5h","window":"5h","remaining_fraction":0.9944406747817993,"reset_time":"2026-08-10T03:36:32Z"}]},
      {"name":"Claude and GPT models","buckets":[{"id":"3p-weekly","remaining_fraction":1,...},{"id":"3p-5h","remaining_fraction":1,...}]}]}}}
   ```
   注: 通常の`-p`応答(`agy -p "OK"`)には`usage.input_tokens`/`output_tokens`等の**実トークン数が入る**(`/usage`コマンド応答時のみ`usage`が全て0で、実データは`command.data.groups[].buckets[].remaining_fraction`側に入る)。`tools/antigravity_delegate.ps1`/`.sh`の`tokens`フィールド抽出ロジック(§9.2、現在ベストエフォートの正規表現)は、通常応答では`.usage.input_tokens`/`.usage.output_tokens`をJSONパスで直接読む形に更新できる(T5-A41実施前に反映すること)。
3. **agy組み込みのChrome DevTools MCP**(ヘッドレスでのブラウザ操作)の可否は未調査。当面ブラウザ確認(`verifier`のUI検証)はClaude側`claude-in-chrome`に残す前提で設計してよい。
4. **コード品質**: Flutter/Dart実装や本リポジトリ固有の規約(全マスタータブへの一律適用・`[Antigravity]`ログ・外部ID `.toString()`化・日本語UI文言)へのGemini系モデルの習熟度は未検証。ファイル編集の権限が通っても、品質面はパイロット運用で確認する必要がある。
5. Web上の「Claude利用コストを27〜64%削減」という数値(個人ブログ複数、裏取り不十分)は本設計では採用しない。効果はパイロット運用の実測で判定する。
6. **T5-A38/T5-A39実地検証(2026-08-10、Windows実機)で判明した3件**:
   - `tools/antigravity_delegate.ps1`の`Invoke-AgyProcess`が使っていた`ProcessStartInfo.ArgumentList`(コレクション型API)がこのPCのWindows PowerShell 5.1には存在せず(`[System.Diagnostics.ProcessStartInfo].GetProperty('ArgumentList')`が空)、agy.exeに引数が1つも渡らずハングしてタイムアウトする実装バグがあった。`.Arguments`(単一文字列)+自前クオート関数に置き換えて修正済み。
   - `~/.gemini/antigravity-cli/settings.json`の`write_file`許可ルールは、公式サンプルのプレースホルダパス(`src/`・`/path/to/project/`)のままだと**このリポジトリの実パスに一致せず機能しない**。`write_file(C:/src/Claude/bean-base/)`のように実パスへ書き換える必要がある(ユーザーが実機で修正・確認済み)。
   - `command(git)`・`command(npm run (build|test))`・`command(flutter)`(いずれも引数なしの単語1つ)はユーザーが実機で個別に試したが**Windowsでは機能せず**、`.claude/agents/implementer.md`の「セルフチェック(必ず実施)」がagy用の上書きブロックより強く解釈され、agyがシェル拒否時に応答ごと打ち切る(Claude側のような優雅なスキップをしない)ことも判明したため、上書きブロックを「シェルコマンドは1回も試みない」という明示禁止に強化した(この時点ではagy委譲は**ファイル編集+読み取り調査**の範囲に限定)。**同日中に訂正**: 引数まで含めた完全なコマンド文字列(`command(flutter analyze)`等)なら機能することが判明(§5-1訂正、T5-A37完了)。上書きブロックは「上記の完全一致コマンドのみ試みてよい」へ再度緩和し、`flutter analyze`/`flutter test`のセルフチェックが`-Role implementer`経由で実際に動作することを確認済み。
7. **2026-08-14の追加調査で判明した事項(Web調査中心、一部は実機1件)**:
   - **`command()`の公式仕様**: 公式ドキュメント(`antigravity.google/docs/cli/permissions`、2026-08-14取得)によれば、`command(<ルール>)`は**空白区切りでトークン化され、各トークンが`^(?:pattern)$`のアンカー付き正規表現として評価される**。公式例は`command(npm run (build|lint|test))`。この仕様は§5-1の実機結論(完全一致の文字列を1件ずつ列挙する必要がある)と矛盾しない——`command(flutter)`が`flutter analyze`にマッチしなかったのは**ルールと実行コマンドのトークン数不一致**として説明できる。**新たに示唆されたのは、トークン単位の正規表現(`command(flutter test test/.*)`等)で「トークン数は固定のまま引数の値だけを可変にする」許可が書ける可能性**。**未実機検証**。拡張候補と検証手順は本書§10。
   - **バージョン**: ローカルは1.1.12、公開最新は1.1.13(2026-08-14リリース)。1.1.11で「許可リスト検証の脆弱性修正」が入ったとの二次情報がある(一次未確認)。**許可リストの照合ロジックはバージョン間で変わりうる**前提で扱い、アップグレード時は必ず許可/拒否のスモーク検証をやり直す(本書§10-3)。
   - **原則の明文化(業界のヘッドレス権限ベストプラクティスと既存教訓§4の一致点)**: **エージェントに自分自身の権限設定ファイル(`~/.gemini/antigravity-cli/settings.json`・`.claude/settings*.json`)を読み書きさせない**。許可リストの変更は常にユーザーが手で行い、アシスタントは「追加候補の文字列」を提案するに留める(`docs/failure_playbook.md`のFP-04が「検知+`allow`追加候補行の生成のみ、自動書き換えは禁止」としているのと同じ立場)。ラッパーは既にこのファイルを読み書きしない設計(§9.2)であり、本項はその理由付けを恒久ルールとして固定するもの。
8. **agyのWeb検索能力は「可能」(2026-08-14、実機1件で確認。§9.7-4を解消)**。親セッションが`agy -p "Web検索ツールは使えますか?使えるなら今日の東京の天気を検索して"`を実行したところ、`status:SUCCESS`で検索結果に基づく具体的な予報(気温・降水確率)が返った。追加の権限設定は不要だった。**確認できたのは「Web検索ツールがヘッドレスでも動く」ことだけで、調査品質(出典の実在性・確認済み/推測の分離・網羅性)は未評価**。したがって§9.1の「Web調査を含むタスクはClaude固定」は撤回するが、品質はT5-A75のパイロット3件(判定基準は§9.7-7)で確かめてから常用へ進める。

## 6. 次のアクション

タスク分解は`docs/改修マスタープラン.md` §3 トラックA(T5-A37〜)に登録した。概要:

- ~~⚠️ユーザー実施: `~/.gemini/antigravity-cli/settings.json`への個別コマンド許可ルール追加、および実効性の確認(§5-1)~~ → **2026-08-10完了(T5-A37)**
- `tools/antigravity_delegate.sh`/`.ps1`: ヘッドレス委譲ラッパー実装(ファイル編集は無条件許可、コマンドは許可リスト経由、非0終了時はClaude側サブエージェントへ自動フォールバック)
- ⚠️ユーザー実施: Windows側の`agy`動作確認
- ~~パイロット導入・実績記録(まずファイル編集中心のタスクから。品質実績が積み上がるまで本番適用は限定的に)~~ → **2026-08-10完了(T5-A41)、「条件付き常時」へ移行(§7・§9.5)**

## 7. 実績ログ

記録元は`.claude/agy_logs/ledger.tsv`〈§9.2〉で、`/end`時に1行へ要約して転記する。

| 日付 | タスクID | 役割 | モデル | exit | 所要 | 変更F数 | 判定 | 備考 |
|---|---|---|---|---|---|---|---|---|
| 2026-08-10 | T5-A25 | implementer | gemini-3.6-flash-high | 0 | 197.8s | 3 | 採用(要修正1件) | `tools/night_loop.ps1`のカウンタ実装は正しかったが、編集によりファイル先頭のUTF-8 BOMが消失しPowerShell 5.1でパースエラー(76件)になる重大な副作用を検出(verifierが実機確認)。親が直接BOMを復元して解消(教訓化・下記参照)。ロジック自体・SKILL.md追記は日本語規約違反なし |
| 2026-08-10 | T5-A29 | implementer | gemini-3.1-pro-high | 0 | 410.3s | 2 | 採用(応答品質に難あり) | 実装(`.claude/full_loop_run_count.txt`・`SKILL.md`追記)自体は正確で地雷回避も良好だったが、`response`本文の先頭に`<END_OF_TURN>`という制御トークンが63行連続で漏れ、後続に本来の日本語報告が続く形になっていた。ラッパーの`response_head`(800文字で切る設計)が全て`<END_OF_TURN>`で埋まり実質無意味化。gemini-3.6-flash-highでは未発生。出力トークン数も20,162(A13の5,584・A25の13,672より多い)で、無駄なトークン消費も伴う |
| 2026-08-10 | T5-A13 | implementer | gemini-3.6-flash-high | 0 | 35.0s | 1 | 採用(要修正1件) | `.claude/agents/implementer.md`への新見出し追記(Android/公開版の実装規約3項目)。**教訓L140(`.claude/`配下へのClaude実装者委譲がハードブロックされる問題)がagy経由では発生しないことを実機確認**——T5-A13は前回Claude実装者委譲で失敗し有人セッションでの直接編集が必要とされていたが、agyでは正常に編集できた。転記時に原文の理由説明の括弧書き1箇所が省略されていたため親が直接補完 |

**新規判明の地雷(T5-A41で発見、上書きブロックへ追加済み・上記§9.3反映済み)**: agyが既存の`.ps1`ファイルを編集すると、日本語コメントを含むファイルの UTF-8 BOM が失われることがあり、PowerShell 5.1環境で構文エラーになる(教訓L127と同種の事象)。ラッパーの上書きブロックに保持指示を追加した(本節・§9.3を参照)。ただしラッパー自身によるBOM自動検査・復元は未実装(検出は`verifier`委譲またはビルド確認に依存する)。

**T5-A41の結論(判定基準は§9.7-5の4項目)**:
- 3件とも`verifier`が(修正後)全項目パス・日本語規約違反ゼロ・既知の地雷(5マスタ一律適用/外部ID `.toString()`/`build_runner`再生成、いずれも今回は非該当スコープ)を踏んでいないことを確認。差し戻し(親による直接修正)は3件中2件で1回ずつ、1件は0回——いずれも「1回以内」の基準を満たす。
- 3件中3件が「採用」相当と判定できたため、§9.5状態遷移表の**「条件付き常時」(3件中2件以上で移行)の条件は満たす**。一方「常時委譲」は`lib/`配下での追加3件の実績が必要条件であり、今回のパイロットは`docs/`・`tools/`・`.claude/`配下のみのため**未達**。
- **結論: パイロットから「条件付き常時」(有人`/full_loop`の`implementer`役、対象を`docs/`・`tools/`・`.claude/`配下の非Dartファイル+`lib/`配下のS規模タスクへ拡大)へ移行する。** `lib/`配下タスクへ実際に3件分の実績を積んだ時点で「常時委譲」への移行を再検討する。モデルは既定`gemini-3.6-flash-high`を優先し、`gemini-3.1-pro-high`は応答品質(`<END_OF_TURN>`漏れ)の問題が解消するまで比較検証以外での常用は避ける。

---

## 8. オーケストレータ(親セッション)のモデル選定

作成: 2026-08-09(`architect`/Opus 5、Windows環境)。ユーザーからの問い「下位モデルサブエージェントをagyへ置き換えたとき、親はSonnet 5でよいのか/上位モデルにすべきか/上位モデルで設計を作り込めば親はSonnetで回るか」への回答。

### 8.1 結論

**親セッションはSonnet 5のままにする。agy委譲を導入してもOpusに上げない。** Opusを使うのは従来どおり`architect`サブエージェント経由のみ(`CLAUDE.md`§日次改修ループ運用ルールのモデル分担ルールを変更しない)。

**そして「上位モデルで設計を作り込めば日々のオーケストレーションはSonnetで回せるか」はYES。** 本§8・§9で確定させた仕様(ルーティング表・ラッパーのI/F・フォールバック条件・プロンプト組み立て)があれば、日々の親セッションに残る判断は機械的なものだけになる。

### 8.2 根拠

**(1) agy委譲で減るのは「委譲先」のコストであり、親のコストは1トークンも減らない。**
`docs/token_reduction_report_20260808.md` §2.2の実測では、Opus親のセッションは中央コンテキスト186,248・200k超27.9%・推定$6.62、Sonnet親は中央86k〜116k・200k超ゼロ・$1.88〜$2.33。単価差1.7倍に対し実測差は約3倍。**親のモデルは今も1ループあたり最大の単一レバー**であり、委譲先を無料化してもこの性質は変わらない。

**(2) 概算すると、Opusへ上げると節約分がちょうど打ち消される。**
T5-A28の集計では、当時のループ消費のうち親セッションが可視範囲33.2%・残りがサブエージェント分だった。仮にサブエージェントを全廃してagyへ移せば、Claude側の消費は約1/3になる。しかしその1/3をOpusで回すと(1)の実測比 約3倍が乗り、**元の水準に戻る**。実測されたループ総額($11.89〜$20.81)を出発点にすると、Sonnet親+agy委譲は概ね$4〜$7、Opus親+agy委譲は$12〜$21で、後者は現状と変わらない。

**(3) 実際には「全サブエージェントの置き換え」は成立しない(§9.1)。** `verifier`は`tools/verify.ps1`(シェル実行)と`claude-in-chrome`が必須、`ui_verifier`はエミュレータ+adb+画像判定が必須で、いずれもagyでは代替できない。置き換えられるのは`implementer`(条件付き)・`adversary`・`researcher`(条件付き)に留まる。したがって削減幅は(2)の上限値より小さく、Opus化の余地はさらに狭い。

**(4) agy導入後に親へ増える仕事は「量」であって「難度」ではない。** 増えるのは (a) 委譲本文をファイルに書き出す (b) 戻ってきたJSONを見て採否を決める (c) 非0終了ならClaude側へ再委譲する、の3つ。いずれも§9で機械的な規則に落としてあり、モデルの知能が律速にならない。品質担保は`tools/verify.ps1`という**決定的なスクリプト**と`verifier`(Claude)が担うので、agyの出力品質を親が読解力で見抜く必要もない。

**(5) 見落としやすい副作用: agyの応答は親のコンテキストに乗る。** Claudeサブエージェントは`Task`ツールで別コンテキストを持ち、親には最終報告だけが返る。agyは`Bash`/`PowerShell`経由なので、**標準出力がそのまま親のtool_resultになる**。ここを無制限にすると「委譲したのに親のコンテキストが膨らむ」という最悪の形になり、単価の高いOpus親ではその損失が3倍で効く。§9.2で標準出力を1行JSON+先頭800文字に固定するのはこのため。

### 8.3 「委譲先の単価」と「親のモデル」は独立した軸

ユーザーの問いの前提にある「サブエージェントが安くなるなら親を上げてもよいのでは」という発想は、**枠(quota)が共通なら成立するが、本件では成立しない**。agyの消費先はGeminiバケット、親の消費先はClaudeバケットで、両者に融通は無い(§2)。Geminiバケットが余っていることは、Claudeバケットを多く使ってよい理由にならない。**Claude枠の節約が目的である以上、親のモデルは低いほど良い**が正しい整理になる。

### 8.4 前倒し設計 vs 継続運用 — architect起動条件はそのまま流用できる

`CLAUDE.md`の既存4条件(⚠️上位モデルで実施タスク / 原因不明・再発バグ / implementerが2回失敗 / フィールド名・画面ID等の新規決定)は、agy導入後も**そのまま有効**。新しい条件を足す必要は無い。理由と対応は次のとおり。

| agy導入で生じる新しい判断 | 既存条件で吸収できるか | 対応 |
|---|---|---|
| このタスクをagyへ出すかClaudeへ出すか | 吸収不要 | §9.1のルーティング表で**機械判定**にする。親に裁量を持たせない |
| agyの出力を採用するか差し戻すか | 吸収不要 | `verifier`の合否(決定的)で判定する。親の主観判断にしない |
| agyがNGだった後の再試行 | **吸収できる** | 「implementerが2回失敗」に**agyの失敗も1回として数える**。ただし**同一タスクでagyを2回続けて使わない**(1回目agy → NGなら2回目はClaude `implementer` → それもNGならarchitect) |
| agyをパイロットから常時委譲へ昇格させるか | **吸収できる** | 運用方式の「新規決定」に当たる。T5-A41の昇格判定は`architect`が行う |

したがって運用モデルは「**Opusで一度だけ作り込み(本§8・§9)、以後の日次ループはSonnet親で回す。判断が要る場面だけ既存4条件でarchitectへ上げる**」で確定とする。

### 8.5 この結論を見直す条件

次のいずれかが観測されたら再検討する(それ以外では議論を蒸し返さない)。

1. agy委譲を常時運用した状態で、`.claude/loop_state.md`の親セッションコストが**3ループ連続で$12を超える**(Sonnet親でも枠が厳しいなら、削るべきは親の仕事量であってモデルではない、という判断のための観測)。
2. Sonnet親のルーティング誤り(§9.1の表に反する委譲)が**5ループ中2回以上**発生する。この場合はまずルーティング表の曖昧さを疑い、表を機械判定に近づける修正を先に行う。

---

## 9. タスク引き渡し方式の詳細設計

### 9.1 役割ごとの適合判定(ルーティング表)

判定は**タスクの属性から機械的に決める**。親に「どちらが良さそうか」を考えさせない。

| 役割 | agyへ委譲 | 理由・条件 |
|---|---|---|
| `implementer` | **条件付き** | ファイル編集は権限が通る(§3)。**2026-08-10、T5-A41完了により「条件付き常時」へ移行済み(§9.5・§7)。対象は`docs/`・`tools/`・`.claude/`配下の非Dartファイル+`lib/`配下のS規模タスク**。`test/`・`gas/`および`lib/`配下のM規模以上はClaude固定(`lib/`配下で追加3件の実績が積まれるまで「常時委譲」への移行は保留) |
| `verifier` | **不可** | `tools/verify.ps1`(シェル実行)と`claude-in-chrome`が必須。agyには両方無い |
| `adversary` | **可** | 差分レビューは読み取りのみで完結。`git diff`は親が事前にファイルへ落として渡す(§9.3)ためシェル不要。**モデル系統が異なることがレビューの多様性として利点になる** |
| `ui_verifier` | **不可** | エミュレータ起動・adb・スクリーンショット判定が必須 |
| `researcher` | **条件付き(2026-08-14〜パイロット)** | リポジトリ内調査は可。**Web検索は2026-08-14に実機で「可能」と確認済み**(§5-8)のため、旧条件「Web調査を含むタスクはClaude固定」は**撤回**。ただし調査品質は未評価のため、下記のresearcher専用除外条件に当たらない一般調査のみをagyへ出し、T5-A75のパイロット3件(判定基準§9.7-7)で昇格を判定する |
| `architect` | **不可** | 設計判断の品質が成果を決める工程。Opus固定 |

**追加の除外条件(役割によらず、1つでも該当したらClaude固定)**:

- シェルコマンドの実行が成果物に必須で、そのコマンドがT5-A37の許可リストに無い
- 本番Sheets/Driveへの読み書き、`firebase deploy`/`clasp push`、`git commit`/`push`を含む
- 秘密情報(Gemini APIキー等)に触れる
- 夜間ループ(`/night_loop`)である、かつT5-A41の昇格判定が未了

**`researcher`役の専用除外条件(1つでも該当したらClaude固定。パイロット中の暫定、T5-A75で見直す)**:

- 調査結果がそのまま**規約・権限・課金・セキュリティの判断根拠**になる(例: agy自身の許可構文、Claude Codeの課金仕様、ライセンス条項)。誤情報が設計を直接汚染するため、一次情報の突き合わせはClaudeで行う。
- **本リポジトリの意思決定に直結する一次情報の確認**(公式ドキュメント原文の逐語確認、リリースノートの原文確認)。
- 上記に当たらない一般調査(ライブラリの使い方、業界の一般的なプラクティス、比較調査、用語・背景の整理)は**agyへ出してよい**。

**`researcher`役の成果物の受け取り方**: `researcher`は`--mode plan`で起動する(§9.2)ためagy自身はファイルを書けない。調査レポートの全文は**ラッパーが`<OutDir>/<timestamp>_researcher_response.md`へ書き出す**ので、親は標準出力JSONの`response_log`のパスを`Read(offset/limit)`で必要箇所だけ読む。親のコンテキストへ全文を持ち込まない(§8.2-(5))。

### 9.2 ラッパーの入出力インターフェース

`tools/antigravity_delegate.ps1`(Windows本命)/`tools/antigravity_delegate.sh`(Ubuntu・Git Bash)。**両者は同じ引数名・同じJSONスキーマ・同じ終了コードを持つ**(`.sh`はケバブケース`--role`等、`.ps1`はパスカルケース`-Role`等)。

#### 引数

| 引数(.ps1 / .sh) | 必須 | 既定 | 意味 |
|---|---|---|---|
| `-Role` / `--role` | ○ | — | `implementer` / `adversary` / `researcher` のいずれか。他の値は引数エラー(exit 2) |
| `-TaskFile` / `--task-file` | ○ | — | 委譲本文(Markdown)のパス。**長文をコマンドライン引数で渡さない**(引用符地獄と長さ制限の回避) |
| `-Files` / `--files` | — | 空 | 対象ファイルの相対パス一覧(カンマ区切り)。プロンプトに列挙する |
| `-DoneWhen` / `--done-when` | — | 空 | 完了条件を1行で |
| `-TaskId` / `--task-id` | — | 空 | `T5-A38`等。台帳に記録するだけ |
| `-Model` / `--model` | — | `gemini-3.6-flash-high` | agyの`--model`にそのまま渡す |
| `-Effort` / `--effort` | — | 自動 | **モデルIDが`-high`/`-medium`/`-low`で終わる場合は`--effort`を渡さない**(§2の二重指定回避)。それ以外のときだけ既定`medium`を渡す |
| `-TimeoutSec` / `--timeout-sec` | — | `600` | agyへは`--print-timeout <N>m<M>s`形式で渡し、加えてラッパー側で`N+60`秒の外側タイムアウトを掛けてプロセスをkillする |
| `-WorkDir` / `--work-dir` | — | リポジトリルート | `--add-dir`に渡す |
| `-OutDir` / `--out-dir` | — | `.claude/agy_logs` | ログ・台帳の出力先(`.gitignore`に追加する) |
| `-SkipQuotaCheck` / `--skip-quota-check` | — | off | 事前クォータ確認をスキップ |
| `-DryRun` / `--dry-run` | — | off | プロンプトを組み立ててファイルに書くだけでagyを起動しない |

**固定(引数にしない)**: `--output-format json`、`--print`、`--mode`(`implementer`は`accept-edits`、`adversary`/`researcher`は`plan`)。**`--dangerously-skip-permissions`は絶対に渡さない。`~/.gemini/antigravity-cli/settings.json`を読み書きしない。**

#### 標準出力(1行JSON、これが唯一の契約)

進捗メッセージは全てstderrへ出す(`tools/verify.ps1`と同じ流儀)。親はこのJSONだけを読む。

```json
{
  "ok": true,
  "role": "implementer",
  "task_id": "T5-A38",
  "model": "gemini-3.6-flash-high",
  "exit_code": 0,
  "status": "SUCCESS",
  "duration_sec": 132.4,
  "response_chars": 2480,
  "response_head": "(応答の先頭800文字。ここで切る)",
  "response_log": ".claude/agy_logs/20260809-231205_implementer_response.md",
  "prompt_log": ".claude/agy_logs/20260809-231205_implementer_prompt.md",
  "raw_log": ".claude/agy_logs/20260809-231205_implementer_raw.json",
  "changed_files": ["docs/foo.md"],
  "changed_file_count": 1,
  "quota": { "gemini_weekly_remaining_pct": 99, "gemini_5h_remaining_pct": 97, "source": "preflight" },
  "tokens": { "input": null, "output": null, "source": "unavailable" },
  "fallback": false,
  "fallback_reason": null
}
```

- `response_head`は**800文字で必ず切る**。全文は`response_log`に置き、親は必要なときだけ`Read(offset/limit)`で読む(§8.2-(5))。
- `changed_files`は**agyの自己申告を使わない**。実行前後で`git status --porcelain`のエントリ集合を取り、差分から機械的に求める(自己申告は嘘をつきうるため)。
- `tokens`はagyのJSONに使用量フィールドがあれば入れる。**無ければ`null`+`"source":"unavailable"`とし、推測値を書かない**(スキーマ未確認、§9.7-1)。
- `quota`は事前チェック(`agy -p "/usage" --output-format json`、消費ゼロ、§2)の結果。`-SkipQuotaCheck`時は`null`。

#### 台帳

`<OutDir>/ledger.tsv`へ1行追記(ヘッダ付き、TSV)。列: `timestamp / task_id / role / model / exit_code / duration_sec / response_chars / changed_file_count / quota_5h_pct / verdict`。`verdict`は起動時点では空欄で、採否が決まった後に親が埋める(`ok`/`ng`/`fallback`)。この台帳が§7実績ログとloop_guardのサマリ行(§9.6)の唯一のデータ源。

#### 実装上の地雷(implementerへの申し送り)

- **PowerShellで`2>&1`によるネイティブ実行のstderr取り込みをしない**(Windows PowerShell 5.1では各行がErrorRecordに包まれ`$?`が`false`になる)。`System.Diagnostics.Process`で`RedirectStandardOutput`/`RedirectStandardError`を個別に取る。
- プロンプトの受け渡しは、**組み立て後の文字列が8,000文字以下なら`-p`に直接渡す。超える場合は`prompt_log`に書き出し、`-p`には「`<prompt_log>`を読んで、その指示に従って作業してください」という短文だけを渡す**(コマンドライン長の上限回避。agyはファイル読み取りができる)。
- 実行名は`agy`/`agy.exe`のどちらかが未確定(T5-A40)。`Get-Command agy`→`agy.exe`の順で探索し、両方無ければexit 10。
- ラッパー自身は**フォールバックを実行しない**(Claudeを呼ぶ手段を持たない)。非0終了と`fallback_reason`を返すだけで、Claude側サブエージェントへの再委譲は**親が行う**(§9.4)。

### 9.3 プロンプトの組み立てと`AGENTS.md`の役割分担

#### 3層構造

| 層 | 実体 | 読み込ませ方 | 内容 |
|---|---|---|---|
| 1. プロジェクト規約 | `AGENTS.md`(リポジトリ直下、20行以内) | **agyが自動読込** | 役割によらず常に効く不変条件。言語・スタック・地雷・禁止事項 |
| 2. 役割定義 | `.claude/agents/<role>.md` | **ラッパーがYAMLフロントマターを除去して本文をプロンプトへ差し込む** | 役割ごとの絶対規則・報告形式 |
| 3. タスク | `-TaskFile`の本文 + `-Files` + `-DoneWhen` | ラッパーがプロンプト末尾へ追記 | 今回の作業内容 |

**層2で既存の`.claude/agents/*.md`を再利用し、agy用に別ファイルを複製しない。** 複製すると必ず片方だけ更新されて乖離する。フロントマター(`name`/`description`/`model`/`tools`)はagyには無意味なので機械的に落とす。

#### 層1と層2の間に挟む「agy固有の制約ブロック」(ラッパーに埋め込む固定文、全役割共通)

`.claude/agents/*.md`にはClaude前提の記述(claude-in-chrome、`flutter analyze`のセルフチェック、verifierへの引き継ぎ等)が含まれるため、**後勝ちの上書きブロック**を挟んで矛盾を解消する。文面は次で確定(実装時はこのまま埋め込む)。

> ## この実行環境での上書き規則(このあとに続く役割定義より優先する)
>
> - あなたはGoogle Antigravity CLI(ヘッドレス)として動いています。ブラウザ操作ツール(claude-in-chrome)は使えません。
> - **シェルコマンドの実行は許可されていない場合があります**。拒否されたら再試行せず、「実行できなかったコマンド」として報告に書いてください。`flutter analyze`/`flutter test`/`flutter build`のセルフチェックは、実行できない場合はスキップしてかまいません(検証は別のエージェントが行います)。
> - `git commit`/`git push`/`firebase deploy`/`clasp push`/本番データの削除は**絶対に実行しないでください**。
> - 指示された対象ファイル以外を編集しないでください。
> - 既存の`.ps1`ファイルを編集する場合、元のファイルがUTF-8 BOM付きであればBOMを失わないでください(日本語コメントを含む`.ps1`がBOM無しUTF-8で保存されると、PowerShell 5.1で構文エラーになります)。
> - 報告は**日本語**で、**1,200文字以内**にしてください。長い引用・生ログの貼り付けは不要です。
> - 報告の最後に、次の3見出しを必ずこの形式で付けてください。
>
>   ```
>   ## 変更ファイル
>   - <相対パス> (新規|変更)
>   ## 保留した判断
>   - <指示に無くて決められなかった点。無ければ「なし」>
>   ## 未実施
>   - <できなかったこと・理由。無ければ「なし」>
>   ```

#### `adversary`役への差分の渡し方

agyはシェルを使えない前提なので、**親が`git diff`を事前にファイルへ落として渡す**。手順を固定する。

1. 親: `git diff --stat > <scratch>/diff_stat.txt` と `git diff > <scratch>/diff.patch` を実行
2. 親: `-TaskFile`に「レビュー対象は`<scratch>/diff.patch`。変更概要は`<scratch>/diff_stat.txt`」と書く
3. 親: `-Files`にレビュー対象の実ファイル一覧を渡す(agyが前後の文脈を読めるように)

#### `AGENTS.md`の確定内容(T5-A39はこれをそのまま作る)

```markdown
# AGENTS.md — BeanBase 2.0

- 回答・コメント・UI文言・ログ本文はすべて**日本語**で書く(例外: コード上の識別子、ライブラリ/API等の固有名詞、`[Antigravity]`プレフィックス)。
- スタックはFlutter Web + Riverpod。永続化はGoogle Sheets(GAS Web App経由、`lib/services/sheets_service.dart`)。
- Firestore関連(`firestore_service.dart`・`firestore_migrator.dart`・`firebase_options.dart`)は**レガシーで未使用**。指示が無い限り触らない。
- 外部から来る数値ID(Sheetsはint/doubleを返す)は`fromJson`で必ず`.toString()`する。空IDはガードする。
- 主要アクション・外部呼び出しは`debugPrint('[Antigravity] ...')`でログする。外部呼び出しはtry/catchで包み、エラーも同形式でログする。
- マスター系の変更は**5マスタすべて**(豆・グラインダー・ドリッパー・フィルター・メソッド)へ一律に適用する。豆だけ直して終わらせない。
- `lib/models/`を変更したら`dart run build_runner build --force-jit`で`*.g.dart`を再生成する(`--delete-conflicting-outputs`は使わない)。
- 統計解析・予測機能は`statistics_feature_design.md`が正本。数値計算(回帰・PCA・GP・EI・検定)はDartローカル実装で行い、LLMに計算させない。
- 秘密情報(Gemini APIキー等)をコード・ドキュメント・コミットに含めない。
- `git commit`/`git push`/`firebase deploy`/`clasp push`/本番データの削除は行わない。
- 指示に無い仕様(フィールド名・シート列名・画面ID・UI文言)を発明しない。判断が要る点は実装せず質問として報告する。
- 委譲の仕組みと役割ごとの規約は`docs/antigravity_delegation_design.md` §9を参照。
```

### 9.4 失敗検出とフォールバック

#### 終了コード

| exit | 意味 | 検出方法 | 親の動作 |
|---:|---|---|---|
| 0 | 成功 | 応答が非空 | 採否判断へ進む |
| 2 | 引数エラー | 未知の`-Role`、`-TaskFile`不在 | **フォールバックしない**。親の呼び出しミスなので直して再実行 |
| 10 | agy未検出 | `agy`/`agy.exe`ともPATHに無い | Claude側サブエージェントへ再委譲 |
| 11 | タイムアウト | 外側タイムアウトでkill | 同上 |
| 12 | 権限自動拒否 | stderrに`permission that headless mode cannot prompt for`を含む、**または**`status`が`SUCCESS`なのに`response`が空(§3の紛らわしい失敗モード) | 同上。加えて**ルーティング違反の疑い**として台帳に記録 |
| 13 | クォータ不足 | 事前チェックでGemini週次残または5時間残が**10%未満** | 同上 |
| 14 | JSON解析失敗 | 標準出力がJSONでない/`response`キーが無い | 同上 |
| 15 | agyがその他の非0終了 | プロセス終了コード≠0 | 同上 |
| 16 | 応答はあるが変更0件 | `role=implementer`で`changed_file_count==0` | 同上 |
| 17 | 読み取り専用役なのに変更発生 | `role`が`adversary`/`researcher`で`changed_file_count>0` | 同上。**ラッパーは自動で復元しない**(破壊的操作のため)。変更ファイル一覧を親へ返し、親が扱いを決める |

**10〜17はすべて「Claude側サブエージェントへ自動フォールバック」**。`-TaskFile`は既に書いてあるので、親はその本文をそのまま`Task`ツールのプロンプトへ渡せばよい(再作成のコストがかからない設計)。

#### 再試行の禁止

- **agyのリトライはしない**(exit 11/13は繰り返しても直らない、10/14/15は環境要因)。1回失敗したら即Claudeへ。
- **同一タスクでagyを2回続けて使わない**(§8.4)。1回目agy → 出力がNG → 2回目はClaude `implementer` → それもNG → `architect`。
- **agyの非0終了は`.claude/loop_failures.txt`の連続失敗に数えない**(インフラのフォールバックであってタスクの失敗ではない。数えると3回のフォールバックでループが止まる)。一方、**agyが成功したのに`verifier`がNGを出した場合は通常どおり1回の失敗として数える**。

### 9.5 スキルへの組み込み

#### `/full_loop`(有人)

§サブエージェントへの委譲の表を次の形に拡張する(既存3行は残す)。

| フェーズ | 担当 | 委譲先 | 条件 |
|---|---|---|---|
| 設計・原因究明・タスク分解 | architect | `Task(architect)` | 変更なし(Opus) |
| コード実装 | implementer | **§9.1で「agy可」なら`tools/antigravity_delegate.ps1 -Role implementer`、それ以外は`Task(implementer)`** | 「条件付き常時」(2026-08-10〜): `docs/`・`tools/`・`.claude/`の非Dartファイル+`lib/`配下のS規模タスクがagy対象 |
| 検証 | verifier | `Task(verifier)` | 変更なし(agy不可) |
| 差分レビュー | adversary | **`tools/antigravity_delegate.ps1 -Role adversary`**(`/code-review`の実行条件を満たすループのみ) | 差分は親がファイル化して渡す(§9.3) |

手順3(実装)に「まず§9.1のルーティング表で委譲先を決める。表で判定できない場合はClaudeを選ぶ(**迷ったらClaude**)」を追記する。

#### `/night_loop`(無人)

**T5-A41の昇格判定は2026-08-10に完了し「条件付き常時」へ移行した(下記表・§7参照)。夜間ループでのagy使用は、`lib/`配下での追加3件の実績を積み「常時委譲」へ移行するまで、引き続き使わない。** 無人実行で未検証の委譲先を使うと、失敗の切り分けが翌朝の人間側コストになるため。昇格後は`implementer`役のみ許可し、`verifier`/`adversary`の並行起動(現行の2体並行)は維持する。

#### 判定基準のまとめ(常時/条件付き/パイロット)

| 状態 | 対象 | 移行条件 |
|---|---|---|
| パイロット | 有人`/full_loop`の`implementer`役、対象は非Dartファイルのみ。`adversary`役は`/code-review`実行時のみ | T5-A38・T5-A39完了 |
| 条件付き常時(現在) | 上記+`lib/`配下のS規模タスク | T5-A41で3件中2件以上が「採用」判定 → **2026-08-10、3件中3件で達成、移行済み(§7)** |
| 常時委譲 | 有人・夜間の`implementer`役全般 | T5-A41で3件中3件が「採用」判定、かつ`lib/`配下で追加3件の実績 → `lib/`配下の実績が未着手のため未達 |

`researcher`役の状態遷移(2026-08-14新設、§5-8のWeb検索実機確認を受けて)。

| 状態 | 対象 | 移行条件 |
|---|---|---|
| パイロット(現在) | 有人`/full_loop`の`researcher`役、§9.1のresearcher専用除外条件に当たらない一般調査を3件 | T5-A75で§9.7-7の4基準を3件中2件以上で満たす |
| 条件付き常時 | 上記に加え、除外条件に当たらない調査は既定でagyへ出す(Claudeは除外条件に該当する調査のみ) | 条件付き常時で追加3件、うち出典の実在性抽出検査で虚偽ゼロ |
| 常時委譲 | 有人・夜間の`researcher`役全般 | 上記達成後に再検討(夜間での使用は`implementer`と同じく別途判断) |

### 9.6 `loop_guard`のコスト集計との関係

**結論: agyの消費を`loop_guard.js`のコスト閾値($24/夜間$8)に含めない。ただし可視化のため`loop_state.md`に別行で出す。**

- **含めない理由**: 閾値はClaudeプラン枠の枯渇を避けるための代理指標であり、Geminiバケットは別枠(§2)。含めると、枠を消費していないのにループが早期停止し、agy導入の目的そのものを損なう。
- **ターン数は自動的に含まれる**(agy呼び出しは親の`Bash`/`PowerShell`1回=1ターン相当)。ここは改変不要。
- **可視化**: `loop_guard.js`に`.claude/agy_logs/ledger.tsv`を読む処理を足し、ループ境界タイムスタンプ以降の行を数えて`loop_state.md`に次の1行を追加する。**閾値判定には一切使わない**。
  ```
  - agy委譲(枠外・参考): 3件 / 成功2・フォールバック1 / 合計 412秒 / Gemini 5時間残 96%
  ```
  台帳が無い・壊れている場合は`try/catch`で握りつぶし、行自体を出さない(既存の`writeFileSync`と同じ流儀)。
- **`CLAUDE.md`への明記**: §日次改修ループ運用ルールの終了条件に「agy(Antigravity CLI)経由の委譲はGeminiバケットを使うため、コスト上限の判定に含めない。件数・所要時間は`loop_state.md`に参考値として出る」を1行足す。

### 9.7 未検証事項(§5への追加分)

1. **`agy --output-format json`の完全なスキーマ**。`status`と`response`があることは§3で確認済みだが、トークン使用量フィールドの有無は未確認。→ ラッパーは未知フィールドを無視し、使用量が取れなければ`null`を返す設計にしてある。T5-A40のWindows確認時に`agy -p "OK" --output-format json`の生出力を§5-2へ貼ること。
2. **`--mode plan`が実際に編集を抑止するか**未検証。→ 読み取り専用役では`git status`の前後差分で二重に検出する(exit 17)。
3. **プロンプトをファイル参照で渡した場合にagyが確実に読むか**未検証。→ T5-A38の実地確認項目に含める(8,000文字超のプロンプトで1回試す)。
4. ~~**agyのWeb検索能力**未検証。→ `researcher`役のWeb調査タスクは当面Claude固定(§9.1)。~~ → **2026-08-14解消**: 実機で「可能」を確認(§5-8)。§9.1の「Web調査はClaude固定」は撤回し、パイロット(§9.5)へ移行。**残る未検証は「能力の有無」ではなく「調査品質」**——出典URLの実在性、確認済み/推測の分離、網羅性、レート制限の有無はいずれも未評価で、T5-A75で判定する。
5. **Gemini系モデルのFlutter/Dart・本リポジトリ規約への習熟度**は依然未検証(§5-4)。T5-A41のパイロットで、次を「採用」の判定条件とする(3件で評価)。
   - `verifier`が全項目パスを報告した
   - 日本語規約違反(UI文言・報告の英語混在)がゼロ
   - 既知の地雷(5マスタ一律適用・外部ID`.toString()`・`build_runner`再生成)を踏んでいない
   - 親からの差し戻しが1回以内
6. **`gemini-3.6-flash-high`と`gemini-3.1-pro-high`のどちらが実装役に向くか**未検証。→ 既定は`gemini-3.6-flash-high`(最新世代・high)とし、T5-A41の3件のうち1件は`gemini-3.1-pro-high`で実施して台帳で比較する。
7. **`researcher`役の調査品質**未検証(§5-8)。T5-A75のパイロットで、次を「採用」の判定条件とする(3件で評価。`implementer`の§9.7-5に対応する researcher 版)。
   - 主要な主張に**出典URLと取得日**が付いている。かつ**各件2本を親が抽出検査**し、URLが実在して主張と整合する(実在しない・別内容を指すものが1本でもあれば不採用)。
   - 報告が「**確認済みの事実**」と「**推測・未確認**」に分離されている(`.claude/agents/researcher.md`の報告形式に従う)。裏取りできていない主張を断定形で書いていない。
   - 日本語規約違反ゼロ(報告本文の英語混在なし)。
   - 親からの差し戻しが1回以内。
   加えて**参考値として記録する**(判定には使わない): 同種の調査をClaude `researcher`で行った直近実績とのトークン/所要時間の比較。

---

## 10. 許可リスト拡張の提案(2026-08-14、⚠️ユーザー実施専用)

**本節は提案であり、アシスタントは`~/.gemini/antigravity-cli/settings.json`を書き換えない**(§5-7の原則・§4の教訓)。実施はユーザーが手で行う。実装タスクはT5-A73。

### 10-1. 前提となる照合モデル(この理解が外れると全ルールが無効になる)

公式仕様(§5-7)+実機結果(§5-1)から導かれる作業モデルは次のとおり。**未実機検証**の部分を含むため、拡張は必ず10-4の検証とセットで行う。

1. ルール文字列も実行コマンドも**空白でトークン化**される。
2. **トークン数が一致しないと不一致**(だから`command(flutter)`は`flutter analyze`を許可しない)。
3. 各トークンは`^(?:pattern)$`の**アンカー付き正規表現**として、対応位置のトークン全体に照合される。
4. したがって**`.*`は「任意の1トークン」であって「任意個のトークン」ではない**。可変長引数を許すには、トークン数ごとにルールを分けて書く必要がある。

### 10-2. 追加候補ルール(優先度順)

現在登録済みなのは11件の完全一致(`flutter --version` / `flutter analyze` / `flutter test` / `flutter build web` / `flutter pub get` / `dart run build_runner build --force-jit` / `git status` / `git diff` / `git log --oneline -20` / `git show HEAD` / `powershell -File tools/verify.ps1`)。

| # | 追加候補ルール | 今できないこと | 追加後にできるようになること | リスク評価 |
|---|---|---|---|---|
| 1 | `command(powershell -File tools/verify.ps1 -Task .*)` | T5-A69で新設した受け入れハーネス(`-Task <タスクID>`)をagyが一切実行できない。トークン数が5対3で不一致 | agy `implementer`が自分の変更に対し受け入れテストまで自己検証できる。差し戻し(Claude側の最大コスト要因)の削減に直結 | 低。`verify.ps1`は読み取り+ビルド/テストのみ |
| 2 | `command(flutter test test/.*)` | 単一テストファイルの実行(`flutter test test/foo_test.dart`)ができず、全件実行しかできない | 変更したテストだけを回せる。所要時間短縮=タイムアウト(exit 11)の減少 | 低。`test/`配下に限定されている |
| 3 | `command(flutter analyze .*)` | `flutter analyze lib`のような対象指定ができない | 差分に近い範囲だけ解析でき、出力が短くなる | 低 |
| 4 | `command(git diff .*)` / `command(git diff .* .*)` | `git diff --stat`・`git diff --name-only`・`git diff HEAD~1 HEAD`のいずれも不可(登録済みは`git diff`のみ) | `adversary`役が差分の把握を自力でできる(現在は親がファイルへ落として渡す運用、§9.3) | 低(読み取り専用)。ただし`git diff`は`--`以降にパスを取ると4トークン以上になるため万能ではない |
| 5 | `command(git log --oneline .*)` | `-20`以外の件数指定ができない | 直近N件の確認 | 低 |
| 6 | `command(powershell -File tools/preflight.ps1)`<br>`command(powershell -File tools/check_encoding.ps1 .*)`<br>`command(powershell -File tools/failure_playbook.ps1 .*)` | T5-A50/A53/A61〜A66で新設した運用スクリプトをagyが一切実行できない(=agyに委譲した実装の自己検証手段が無い) | agyが自分の変更をプリフライト・BOM検査・プレイブック検査にかけられる。特に**BOM喪失(L142)はagy自身が最も踏みやすい地雷**なので、自己検査できる価値が大きい | 低〜中。`failure_playbook.ps1`は対処モードでプロセス停止を伴いうるため、**まず`-Mode Check`相当の読み取り用途に限る運用で開始する**(引数を`.*`1トークンに絞ることで多引数呼び出しは通らない) |
| 7 | `command(node tools/analyze_transcript.js .*)` | トークン実測スクリプトを実行できない | T5-A16(トークン実測記録)の作業をagyへ出せる | 低 |
| 8 | `command(flutter build (web\|apk))` | `flutter build apk`が不可(`web`のみ登録済み) | Android版のビルド確認 | 中(所要時間が長くタイムアウトしやすい)。トラックB本格化まで**保留でよい** |

**あわせて`deny`側にも明示的な禁止を置くことを推奨**(現状の設計は「allowに無いものは拒否」だが、多層防御として。ただし`deny`の照合仕様も同じトークンモデルかは**未検証**):

```
command(git commit .*)  /  command(git push .*)  /  command(firebase .*)  /  command(clasp .*)
command(rm .*)  /  command(Remove-Item .*)  /  command(winget .*)
```

### 10-3. agyのバージョン方針

**1.1.12 → 1.1.13 へのアップグレードを推奨する**(⚠️ユーザー実施、`winget upgrade`。タスクT5-A74)。理由と条件は次のとおり。

- 推奨する理由: agyはシェル実行権限を持つツールであり、1.1.11で許可リスト検証の脆弱性修正が入ったとされる(二次情報)ように、**このソフトの修正はまさに本設計が依存している箇所に入る**。2世代遅れを常態化させない。
- **必ず単独で実施し、直後に10-4のスモーク検証をやり直す**。許可リストの照合ロジックはバージョン間で変わりうる(§5-7)ため、拡張(T5-A73)と同じループで済ませるのが効率的。
- **夜間ループの発火直前(23:00・04:10・09:20の直前)には実施しない**。agyの権限拒否は`status:SUCCESS`+空`response`という紛らわしい失敗モード(§3、exit 12)を取るため、無人実行中の回帰は発見が翌朝になる。
- 回帰が出たら`winget install --version 1.1.12`で戻す。

### 10-4. 検証手順(拡張・アップグレードのどちらでも同じものを実行する)

agyを`--add-dir`付きで直接呼び、**許可4件・拒否2件**を1回ずつ確認する。拒否側が通ってしまう場合は**スコープが広がりすぎている**ので、そのルールを削る。

| # | 実行させるコマンド | 期待 |
|---|---|---|
| 1 | `powershell -File tools/verify.ps1 -Task T5-A69` | 許可(実行され結果が返る) |
| 2 | `flutter test test/statistics_service_test.dart` | 許可 |
| 3 | `git diff --stat` | 許可 |
| 4 | `flutter analyze` (既存ルール) | 許可(回帰していないこと) |
| 5 | `git push` | **拒否**(`permission that headless mode cannot prompt for`) |
| 6 | `powershell -File tools/verify.ps1 -Task T5-A69 -Extra x` | **拒否**(トークン数超過。`.*`が1トークンしか吸わないことの確認) |

6が許可されてしまった場合は「`.*`が複数トークンに及ぶ」ことを意味し、10-1の作業モデルが誤りなので**拡張ルールを全て撤回**し、完全一致列挙に戻す。この結果(どちらだったか)を§5-7へ追記する。
