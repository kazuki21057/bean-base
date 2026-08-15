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

利用可能モデル(`agy models`): `gemini-3.6-flash-{high,medium,low}` / `gemini-3.5-flash-{high,medium,low}` / `gemini-3.1-pro-{high,low}` / `claude-sonnet-4-6` / `claude-opus-4-6-thinking` / `gpt-oss-120b-medium`(agy経由でClaude/GPTも中継可能だが、Claude利用枠節約という目的には使わない)。**2026-08-14再取得時点では`gemini-3.7-flash-{high,medium,low}`が追加され最新世代になっている**(T5-A78)。新モデルの追従はハードコードではなく、ラッパー側で`agy models`の出力から`gemini-<major>.<minor>-flash-high`のうち数値最大のものを自動解決する方式に変更済み(§9.2参照)。

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
9. **`agy -p "/usage"`がヘッドレスモード(`-p`)で恒常的に失敗する新規regressionを発見(2026-08-14、T5-A80、Windows実機1.1.13)**。`--output-format json`・text両形式で計3回試行し全て`read_file`/`command`権限の自動拒否で失敗。`--log-file`で内部ログを追うと、`/usage`がクライアント側の組み込みスラッシュコマンドとして展開されず(`Slash commands unchanged, skipping update`)通常のプロンプトとして解釈され、`C:\Program Files\Git`への無関係な`ListDir`/`read_file`を試みて拒否されていた。同一パターンが`/help`でも再現し、**特定コマンドではなく1.1.13のヘッドレスモードにおけるスラッシュコマンド展開自体のregressionの疑い**(原因は未特定、旧バージョン1.1.11/1.1.12で確認されていた§2の「`/usage`は消費ゼロで構造化JSONを返す」という前提は1.1.13では成立しない可能性がある)。詳細と対応は§7「T5-A80の結論」。

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
| 2026-08-14 | T5-A75-1 | researcher | gemini-3.7-flash-high | 17 | 126.9s | 1 | **不採用(出典不整合)** | 「Flutter Webのデプロイ後キャッシュ問題への対処」の調査。報告の体裁(確認済み/推測の分離・日本語)は良好で、「Flutter no longer generates a service worker by default」は公式ページに逐語で存在することを親が確認。しかし**引用元が1本しかなく、その1本が裏付けない主張まで同じURLに帰属させていた**——Service Workerのwaiting状態によるstale問題・CDNキャッシュ衝突の記述は当該ページに存在しないことを親がWebFetchで確認。§9.7-7の「別内容を指す出典が1本でもあれば不採用」に該当 |
| 2026-08-14 | T5-A75-2 | researcher | gemini-3.7-flash-high | 17 | 113.8s | 1 | **採用** | 「Dart/Flutterのクライアントサイド数値計算パッケージ比較」の調査。抽出検査2本(`pub.dev/packages/data`・`dart.dev/guides/language/concurrency`)とも実在し主張と整合。`data`パッケージの固有値分解/SVD/多項式回帰・Web対応、Dart Web が isolate 非対応であることをいずれも確認。確認済み/推測の分離あり、日本語規約違反なし |
| 2026-08-14 | T5-A75-3 | researcher | gemini-3.7-flash-high | 17 | 108.1s | 1 | **不採用(死んだURL)** | 「Material 3のレスポンシブ・ナビゲーション切替の慣習」の調査。`flutter_adaptive_scaffold`が Discontinued であることは実在確認できた(有用な指摘)が、ブレークポイント数値の出典 `https://m3.material.io/foundations/layout/understanding-layout/parts-of-layout` が **HTTP 404**。同ドメインの別URL(`/components/navigation-rail/overview`)は200を返すため、ドメイン側の取得失敗ではなく実在しないURLと判断 |

**新規判明の地雷(T5-A41で発見、上書きブロックへ追加済み・上記§9.3反映済み)**: agyが既存の`.ps1`ファイルを編集すると、日本語コメントを含むファイルの UTF-8 BOM が失われることがあり、PowerShell 5.1環境で構文エラーになる(教訓L127と同種の事象)。ラッパーの上書きブロックに保持指示を追加した(本節・§9.3を参照)。ただしラッパー自身によるBOM自動検査・復元は未実装(検出は`verifier`委譲またはビルド確認に依存する)。

**T5-A41の結論(判定基準は§9.7-5の4項目)**:
- 3件とも`verifier`が(修正後)全項目パス・日本語規約違反ゼロ・既知の地雷(5マスタ一律適用/外部ID `.toString()`/`build_runner`再生成、いずれも今回は非該当スコープ)を踏んでいないことを確認。差し戻し(親による直接修正)は3件中2件で1回ずつ、1件は0回——いずれも「1回以内」の基準を満たす。
- 3件中3件が「採用」相当と判定できたため、§9.5状態遷移表の**「条件付き常時」(3件中2件以上で移行)の条件は満たす**。一方「常時委譲」は`lib/`配下での追加3件の実績が必要条件であり、今回のパイロットは`docs/`・`tools/`・`.claude/`配下のみのため**未達**。
- **結論: パイロットから「条件付き常時」(有人`/full_loop`の`implementer`役、対象を`docs/`・`tools/`・`.claude/`配下の非Dartファイル+`lib/`配下のS規模タスクへ拡大)へ移行する。** `lib/`配下タスクへ実際に3件分の実績を積んだ時点で「常時委譲」への移行を再検討する。モデルは**T5-A78以降、既定で「最新のGemini Flash(`-high`)を自動解決」**する(2026-08-14時点の解決結果は`gemini-3.7-flash-high`)。`gemini-3.1-pro-high`は応答品質(`<END_OF_TURN>`漏れ)の問題が解消するまで比較検証以外での常用は避ける。

**T5-A75の結論(`researcher`役のパイロット3件、判定基準は§9.7-7の4項目)**:

- **3件中「採用」は1件のみ。§9.5の昇格条件(3件中2件以上)を満たさないため、`researcher`役は「パイロット」に据え置く**(「条件付き常時」へ進めない)。不採用2件はいずれも**出典の質**が原因で、報告の体裁(日本語規約・確認済み/推測の分離)や所要時間(108〜127秒)はむしろ良好だった。
- **失敗の型が明確**: (1)実在しないURLを出典として書く(件3、404)、(2)実在する1本のURLに、そのページが裏付けない主張まで束ねて帰属させる(件1)。**どちらも報告を読むだけでは気づけず、親がURLを実際に開いて初めて分かる**。§9.1の「規約・権限・課金・セキュリティの判断根拠となる調査はClaude固定」という除外条件は妥当であり、維持する。
- **`researcher`役をagyへ出す場合の追加条件(本結論により新設)**: 採否に関わらず、**親は主要な主張の出典URLを最低2本、実際にWebFetchで開いて「実在するか」「その主張を裏付けているか」を確認する**。この検査を省略するなら`researcher`役をagyへ出さない。検査コストを含めても、Claude `researcher`より安いかどうかは次のパイロットで再評価する。→ **2026-08-14、T5-A79で機械検証(`tools/verify_citations.ps1`)に置き換えた。以後この手作業は不要。**

**T5-A79の結論(2026-08-14、ユーザー依頼「agy自身に出典確認強化をすることで対応できないか」への回答)**:

同一テーマ(Material 3のブレークポイント。T5-A75で404捏造が起きたのと同じ題材)を、**出典検証の追加規則を付けたプロンプト**で`gemini-3.1-pro-high`と`gemini-3.7-flash-high`の2モデルに投げて比較した。

| 観点 | pro(`gemini-3.1-pro-high`) | flash(`gemini-3.7-flash-high`) |
|---|---|---|
| 所要時間 / 入力トークン | 201.5秒 / 194,195 | 278.3秒 / 488,704 |
| 出典の分散 | **1本のURLに7主張を集中** | 6ドメイン8本に分散 |
| 実体の正確さ | `flutter_adaptive_scaffold`(Discontinued)基準のみ。M3公式値は取得失敗を理由に「未確認」へ降格 | M3公式の値(compact <600 / medium 600–839 / expanded 840–1199 / large 1200–1599 / XL ≥1600)を取得し、親のWebSearchによる裏取りと一致 |
| URL捏造 | **なし** | **なし**(親がWebFetchで2本を抽出検査、いずれも実在・整合) |
| 機械検証の結果 | exit 0(7行passed、`overused_urls`警告) | exit 0(6行passed、`m3.material.io`の2行は`unverifiable`) |

- **プロンプト強化だけで失敗の型①(実在しないURLを出典に書く)は再発しなくなった**。pro側は`m3.material.io`の取得が404だったことを正直に報告し、該当主張を「推測・未確認」へ降格している。T5-A75では同じ状況で存在しないURLを出典として書いていた。
- **ただし失敗の型②(実在URLへの無関係な帰属)は、プロンプトだけでは保証できない**。「引用が実在すること」と「引用が主張を裏付けること」は別問題であり、pro側の7行は引用自体はすべて実在したが、引用文にdp値は含まれていなかった(隣接する文からの引用)。**したがって機械検証(URL実在+引用の原文照合)を必須の関門として入れる**。これがT5-A79の実装である。
- **モデル選択の結論: proへ切り替えない**。(1)agyのクォータは`Gemini Models`という**単一グループでFlashとProが同じバケットを共有**しており(`agy -p /usage`の生JSON: "Models within this group: Gemini Flash, Gemini Pro"、"Quota is consumed proportionally to the cost of the tokens")、**proはサブスク内で使えるがトークン単価が高い分だけ枠を速く消費する**。(2)提供されているproは`gemini-3.1-pro-high`で、Flashの最新(3.7)より**2世代古い**。(3)実測でも今回はflashの方が網羅性・正確さで上回った。既定は引き続きT5-A78の最新Flash自動解決とし、proは`-Model`明示指定の比較用途に留める。
- **副次的な発見(委譲範囲の拡大余地として重要)**: `agy -p /usage`は`Gemini Models`とは**別グループ**として`Claude and GPT models`(Claude Sonnet 4.6 / Opus 4.6 / GPT-OSS)を持ち、こちらは週次100%・5時間100%で**まったく未使用**である。このバケットはAntigravity側の割り当てであり、ユーザーのClaude Pro枠とは別勘定と考えられる(未実証)。**実証できれば委譲範囲の拡大余地は「proへの切り替え」より遥かに大きい**。検証方法は「`-Model claude-sonnet-4-6`で1回実呼び出しし、`Claude and GPT models`バケットが減る一方でローカルAPI(`localhost:3000`)のClaude Pro使用率が動かないことを確認する」。→ T5-A80として起票。
- **新規判明の地雷(重要、§9.2の前提が誤りだった)**: **`--mode plan`はファイル書き込みを禁止しない。** 3件とも agy が `docs/research/2026-08-14_*.md` を自分で作成し、ラッパーが exit 17(`READONLY_ROLE_CHANGED_FILES`)で検出した。§9.2の「`researcher`は`--mode plan`で起動するためagy自身はファイルを書けない」という記述は**実機で反証された**ので、「書けてしまうことを前提に、ラッパーの exit 17 で検出して親が扱いを決める」という運用へ改める。なお `--mode plan` でも**agy本体は exit 0** を返すため、**ラッパーの exit 17 判定が唯一の検出手段**である(この判定を外してはならない)。
- 参考値: 3件の合計トークンは input 385,225 / output 31,884(すべてGeminiバケット)、所要は合計348.8秒。実行時点のGeminiクォータ残は週次97%・5時間98〜100%で、消費はごく小さい。

**T5-A80の結論(2026-08-14、`Claude and GPT models`バケットの別勘定検証、判定不能)**:

- **モデル選定**: `agy models`を実機確認したところ、**Sonnet 5相当のモデルIDは存在しない**(Claude系は`claude-sonnet-4-6`・`claude-opus-4-6-thinking`のみ、他は`gpt-oss-120b-medium`とGemini系`gemini-3.7-flash-*`まで)。ユーザー要望の「可能ならSonnet 5」は満たせず、既存の設計書記載どおり`claude-sonnet-4-6`を使用した。
- **agy側バケット残量の直接計測は今回できなかった**。`agy -p "/usage" --output-format json`をjson/text両形式で計3回試行し、いずれも`read_file`/`command`権限の自動拒否で失敗(response空)。`--log-file`で原因を追跡し、§5-9の新規regressionを特定(`/help`でも同一パターン再現)。`~/.gemini/antigravity-cli/settings.json`への許可追加で回避できる可能性はあるが、§5-7の設計原則(エージェントに自分自身の権限設定ファイルを読み書きさせない)により変更せず、§1の既定方針により`--dangerously-skip-permissions`も使用しなかった。
- **実験本番**: `agy -p "BeanBase 2.0のREADME相当のプロジェクト概要を3行で要約して" --model claude-sonnet-4-6 --output-format json`を1回実行、`status:SUCCESS`(所要9.8秒、input 18,850 / output 463 / cache_read 17,093、計19,313トークン)。ワークスペースの`read_file`許可が無く実際の要約はできなかったが、不足情報を日本語で確認し返す実用的なやり取りが成立し、**Claude Sonnet呼び出し自体が問題なく機能することは確認できた**。
- **ローカルAPI(`localhost:3000`)比較**: 実験直前 `Current session 71% / Current week 41%` → 直後 `73% / 42%`と上昇した。ただし対照として、agy呼び出しを挟まず本タスク自身の調査作業(Read/Bash診断)のみを行った直後にも`71→73→74%`(週`41→42→42%`)と**同程度の増分がagy呼び出しの有無に関わらず一貫して観測された**——このセッション自身の並行消費がノイズとして支配的で、単発のagy呼び出し(19,313トークン)による影響を切り分けられなかった。
- **結論: 判定不能**。(a) agy側`Claude and GPT models`バケットの直接計測ができなかったこと、(b) ローカルAPI比較がこのセッション自身の並行消費で強く交絡していたこと、の2点により、当初計画していた「前後比較による別勘定の実証」は今回のセッションでは完遂できなかった。**補助的な状況証拠**として、`--log-file`のログでは`kazuki21057@gmail.com`のAntigravity(Google)側keyring OAuthで認証し通信先も`daily-cloudcode-pa.googleapis.com`(Google Cloud Code Assistバックエンド)であることを確認しており、このClaude Codeセッションが使うAnthropic側の認証・課金経路とは構造的に別のものである。別勘定説を補強する状況証拠だが、実測による確証には至っていない。
- **§9.1ルーティング表の変更は見送る**(別勘定を確証できていないため)。**再検証の条件**: (1)`/usage`のregressionをユーザーが対話モード(TUI)または許可追加で回避できる状態にしてから行う (2)agy呼び出しの前後で本タスク自身の他の調査作業を挟まず、単発の計測のみを完結させる、の2点を満たすこと。

**追記(2026-08-14、ユーザー確認により確定)**: 上記の「判定不能」はagyヘッドレスの`/usage`regressionによりアシスタント自身の計測手段が塞がれていたことによるもので、**ユーザーが自身のAnthropic側アカウント・請求情報を直接確認できる立場から「agy経由でclaude-sonnet-4-6を使ってもClaudeのトークンは消費しない」と明確に確認した**。アシスタント側の計測環境では検証できない領域(ユーザー自身の課金ダッシュボード等)の事実であり、ユーザー自身の一次情報として採用する。**結論を「別勘定・確定(ユーザー確認)」へ更新し、§9.1ルーティング表の見直しに着手する**(詳細はarchitectへの委譲結果を追記予定の§12参照)。

**T5-A84の結論(2026-08-15、Claudeモデルのスモーク検証3件+3pバケット消費実測)**:

- **前提の訂正が実証された**: NEXT_SESSION.mdの持ち越し確認事項どおり、`agy -p "/usage" --output-format json`をPowerShell経由(Git Bash非経由)で実行したところ**正常に動作し、Claude/GPTバケットの残量まで含めて正確なJSONが返った**。教訓L158の「Git Bash〈MSYS〉のパス自動変換が真因」を実測で再確認し、**⚠️ユーザー実施(TUI手動確認)は不要と判明**——親セッションがPowerShell経由で全自動計測できた。
- **3pバケット消費実測(前後)**: Claude/GPT週次残 99.45%→97.38%(-2.07pt)、Claude/GPT 5時間残 100%→93.77%(-6.23pt)。テスト2件の成功呼び出し(ファイル読み取り・Web検索)+1件のエラー終了(effort拒否、課金前に弾かれた可能性が高い)での消費。Geminiバケットは週次96%→96%・5時間100%→100%で不変、**別勘定であることも改めて裏付けられた**。
- **スモーク検証3件の結果**(いずれも`--model claude-sonnet-4-6`、実行例は`docs/antigravity_delegation_design.md`本節の記録用に親が直接agy CLIを実行):
  1. **ファイル読み取り可否**: ✅可能。ただし`--add-dir`に**絶対パス**が必須(相対パス`.`では「現在アクティブなワークスペースが設定されていない」エラーで失敗する新規知見)。絶対パス指定で`CLAUDE.md`の実際のH1見出し`# CLAUDE.md`を正確に読み取り・引用できた。
  2. **Web検索**: ✅可能。「Anthropicの最新Claudeモデル」を問うと実際にWeb検索し、Claude Opus 5(2026-07-24リリース)を出典URL付きで回答した。
  3. **`claude-opus-4-6-thinking`のeffort受理**: ❌不可。`--effort high`を明示指定するとexit 1、`"--effort is not supported for model \"claude-opus-4-6-thinking\""`という明確なエラーで拒否される。**T5-A83で実装済みの「claude-/gpt-接頭辞では`--effort`を渡さない」抑制ロジックが正しい設計だったことを実機で確認**。
- **完了条件の判定**: ファイル読み取りが成功したため、**T5-A85以降(researcher/implementer/architectのclaude-sonnet-4-6パイロット)は続行してよい**。
- **副次的な改善余地(未実装、別タスク化を検討)**: `tools/antigravity_delegate.ps1`の`Invoke-QuotaPreflight`は`claude-`/`gpt-`接頭辞モデルの場合に呼び出し自体をスキップし`source:"not_applicable_claude_gpt_bucket"`を返す(T5-A83仕様どおり)。今回の実測で同関数はモデル非依存でClaude/GPTバケットの実数値も取得できることが分かったため、スキップせず実数値を記録する余地がある。ただし「クォータ10%未満で中断」というGemini向け安全弁をClaude/GPTバケットへも適用するかは設計判断を要するため、本タスクの範囲外として次点タスク化を検討する(新規タスク化は未実施)。
- **`--add-dir`絶対パス必須の知見**は、T5-A85〜A87のパイロットでも`tools/antigravity_delegate.ps1`が`$WorkDir`に絶対パス(`$RepoRoot`)を使っているため影響なし(ラッパー自体は元々正しく実装されていた)。

**T5-A85の結論(2026-08-15、`researcher`役×`claude-sonnet-4-6`パイロット3件、結果: 不採用)**:

- **3件中3件とも失敗**(判定基準§12.9の条件(1)「`verify_citations`がexit 0」を全件満たせず、`exit_code:18`/`status:"CITATION_UNVERIFIED"`/`citations.status:"REPORT_NOT_FOUND"`)。一般調査2件(`freezed`+`json_serializable`、Google Play購入トークン検証)・緩和候補テーマ1件(`drift`マイグレーション仕様の逐語確認)のいずれも同一パターンで失敗し、テーマによる差は見られなかった。
- **失敗パターンは3件とも同一**: agy呼び出し自体は`exit=0`・`status:"SUCCESS"`(正常終了扱い)、所要176〜256秒、Web検索・ページ取得は実際に複数回行われている(`response_head`に取得ログが残る)にもかかわらず、**`num_turns:1`のまま**応答が「レポートを作成します」という宣言で尻切れになり、`docs/research/*.md`へのファイル書き込みが1件も発生しなかった(`changed_file_count:0`)。
- **原因の切り分け(ユーザー指摘により追試)**: 当初「`--mode plan`の読み取り専用制約が原因では」という仮説を立てたが、**同一プロンプトを`--mode accept-edits`(書き込み許可モード、`implementer`役と同じ)で直接実行しても同じ失敗が再現した**(所要55.5秒・`num_turns:1`・応答が「ドキュメントを作成します。」で尻切れ・ファイル未作成)。**したがって原因は`--mode plan`ではない**。3件+追試1件すべてで`num_turns:1`のまま応答が打ち切られている共通点から、**agyヘッドレス`-p`単発プロンプト+`claude-sonnet-4-6`の組み合わせが、1ターンあたりの内部ステップ数(Web検索・ページ取得を複数回行った後)を使い切ると、ファイル書き込み等の最終アクションを実行する前に応答を打ち切る構造的な制約(ステップ予算切れ)を持つ**と推定する。Geminiモデルでは同種の制約に達していない(T5-A75/A79では正常完了)ため、モデル側の挙動差(Claudeは内部ツール呼び出し1回あたりのステップ消費が大きい、または応答生成の打ち切り基準が異なる)によるものと考えられる。根本原因はagy側の内部実装に依存するため未確定(agyのバージョンアップやプロンプトの簡素化〈調査範囲を絞る〉で改善する可能性はあるが本パイロットの範囲では追試しない)。
- **結論: `researcher`役のClaudeモデル化(agy経由)は不採用。現行どおりGemini(`gemini-3.7-flash-high`自動解決)を既定のまま維持する。** §9.5のresearcher状態遷移表は「パイロット」のまま据え置き、Claude化は再挑戦しない(モード変更〈`--mode plan`以外を試す〉やプロンプト構造の作り込みをすれば改善する可能性はあるが、現状の設計〈読み取り専用役として扱う前提〉を崩すため本パイロットの範囲では追試しない)。
- **参考値**: 3件合計トークン input 474,981 / output 29,615(3pバケット消費、Geminiバケットとは別勘定)。ログは`.claude/agy_logs/20260815_200800`・`_201145`・`_201629`各`_researcher_*`。

**T5-A86の結論(2026-08-15、`implementer`役×`claude-sonnet-4-6`パイロット3件、結果: 採用)**:

- **対象タスクの選び方**: トラックA完成前で`lib/`配下のM規模タスクが存在しない(Track B未着手)ため、`test/pilot/`配下に**使い捨ての検証専用テストファイル**を3本(T5-A46〜A48ダミータスクと同じ発想)、`lib/utils/bean_stock_calculator.dart`の既存関数に対するテストコードを**親が全文事前確定**して委譲した(探索・設計判断ゼロの粒度)。判定後にファイルは削除済み(本採用のテストではない)。
- **1件目、初回試行で`PERMISSION_DENIED`(exit 12)**: 委譲プロンプトの「agy固有の上書き規則」(シェル許可リストは`flutter analyze`/`flutter test`等の**完全一致文字列のみ**)と、`.claude/agents/implementer.md`にT5-A92で追記した「反復中は`flutter test test/xxx_test.dart`のように**特定ファイル指定**で回してよい」という指示が**矛盾**しており、agyが特定ファイル指定の`flutter test`を試みて拒否され、応答全体が打ち切られた(応答は空)。**タスクプロンプト側で「検証コマンドは一切実行しないこと」を明示追記して再試行したところ、1件目は成功(exit 0)**。2件目・3件目は最初からこの追記込みで実行し、いずれも一発success相当(下記参照)。
- **2件目・3件目、ラッパーの誤検知(exit 16 `NO_CHANGES`)**: agyの応答は成功、`git status --porcelain`ベースの変更ファイル検出が`changed_file_count:0`を返したが、**実際にはファイルは正しく書き込まれていた**(親が`Read`で直接確認、内容は指示どおり一字一句一致)。原因は`test/pilot/`が1件目の実行で既にuntracked扱いになっており、`git status --porcelain`はuntrackedディレクトリを`?? test/pilot/`という1行にまとめて返す(個別ファイルを列挙しない)ため、同一ディレクトリへの2回目以降の追加は「変化なし」に見えてしまう。**`tools/antigravity_delegate.ps1`の変更検出ロジックの既知の限界**(同一ディレクトリへ複数回agy呼び出しを行うケースで偽陰性になる)。
- **実測結果(3件とも§9.7-5の4基準+BOM喪失なしを満たす)**: `flutter test test/pilot/`で3件とも実際にPASS(親が直接実行し確認、3 tests / All tests passed)。日本語規約違反ゼロ、既知の地雷なし、差し戻しは1件目のみ・1回(内容ではなく検証コマンド実行可否の指示不足が原因)。
- **結論: 3件中3件が実質「採用」相当。§12.9の昇格条件(3件中2件以上)を満たすため、`implementer`役は`lib/`のM規模・`test/`配下に限りClaudeモデル(`claude-sonnet-4-6`)で「条件付き常時」へ移行してよい。** ただし実運用に移す前に、上記で見つかった2件の不具合への対処が必要:
  1. **agy委譲プロンプトの恒久修正が必要**: `tools/antigravity_delegate.ps1`の上書き規則ブロックへ「セルフチェック(`flutter analyze`/`flutter test`/`flutter build web`)はagy委譲では一切実行せず、`実装後のセルフチェック`および`反復中の検証範囲(T5-A92)`の節はagy委譲には適用しない」という一文を追加し、タスクごとに親が追記しなくても済むようにする(新規タスク化を検討)。
  2. **`changed_file_count`の偽陰性は既知の限界として運用でカバー**: 同一ディレクトリへ連続してagy委譲する場合、`exit 16`が出ても親が直接ファイル内容を確認すること。恒久修正(`git status --porcelain --untracked-files=all`への変更、または対象ディレクトリのファイルハッシュ比較)は影響範囲が広いため新規タスク化を検討。
- **参考値**: 3件合計トークン input 87,815 / output 3,768(3pバケット消費)。所要は21.3s/21.3s/17.6s、いずれも探索ゼロタスクでは高速。ログは`.claude/agy_logs/20260815_204935`・`_205009`・`_205103`各`_implementer_*`(1件目の初回失敗ログは`_204802`)。

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

| 役割 | agyへ委譲 | モデル | 条件 |
|---|---|---|---|
| `implementer` | **条件付き常時** | 既定=最新Gemini Flash(自動解決) | 現行どおり`docs/`・`tools/`・`.claude/`の非Dartファイル+`lib/`のS規模。**変更しない** |
| `implementer`(Claude版) | **条件付き常時(2026-08-15、T5-A86パイロット3件中3件採用で昇格)** | `claude-sonnet-4-6`(明示指定) | `lib/`のM規模・`test/`配下が対象。`gas/`は対象外(本番GASへの影響が不可逆)。**実運用前に、委譲プロンプトへ「セルフチェック(`flutter analyze`/`test`/`build`)はagy委譲では実行しない」の明記が必須**(現状は未修正、明記漏れがあるとT5-A86で発見した`PERMISSION_DENIED`が再発する。詳細§7) |
| `verifier` | **不可(型a、恒久)** | — | 12.4 |
| `adversary` | 可 | **Gemini維持** | 12.5。Claude化は「置換」ではなく「フェーズ完了ループでの2本目追加」としてのみ検討 |
| `ui_verifier` | **不可(型a、恒久)** | — | 12.4 |
| `researcher` | **不採用(2026-08-15、T5-A85パイロット3件中3件失敗)。Gemini既定を維持** | `gemini-3.7-flash-high`(自動解決、現行どおり) | Claude系(`claude-sonnet-4-6`)は探索を伴うタスクで`num_turns:1`のまま応答が打ち切られファイルを生成できない現象を3件+追試2件すべてで再現(原因未確定、詳細§7「T5-A85の結論」)。再挑戦しない |
| `architect` | **パイロット(T5-A87)** | `claude-opus-4-6-thinking`(明示指定) | 12.7。**設計成果物はファイルに書かせず`response_log`経由で受け取る**(読み取り専用役として扱い、exit 17の検出を維持する) |

**追加の除外条件(役割によらず、1つでも該当したらClaude固定)**:

- シェルコマンドの実行が成果物に必須で、そのコマンドがT5-A37の許可リストに無い
- 本番Sheets/Driveへの読み書き、`firebase deploy`/`clasp push`、`git commit`/`push`を含む
- 秘密情報(Gemini APIキー等)に触れる
- 夜間ループ(`/night_loop`)である、かつT5-A41の昇格判定が未了
- 夜間ループ(`/night_loop`)ではClaudeモデルを指定しない。パイロット中の委譲先を無人実行で使わない既存方針(§9.5)と同じ理由。
- 1ループあたりのClaudeモデル委譲は既定2件まで、うち`architect`役は1件まで。3pバケット(`3p-weekly`/`3p-5h`)の残量をヘッドレスで観測できない(§5-9のregression)ため、件数上限で代替する。1件あたりの消費率が実測できた時点(T5-A84)でこの上限を見直す。

**`researcher`役の専用除外条件(1つでも該当したらClaude固定。パイロット中の暫定、T5-A75で見直す)**:

- 調査結果がそのまま**規約・権限・課金・セキュリティの判断根拠**になる(例: agy自身の許可構文、Claude Codeの課金仕様、ライセンス条項)。誤情報が設計を直接汚染するため、一次情報の突き合わせはClaudeで行う。
- **本リポジトリの意思決定に直結する一次情報の確認**(公式ドキュメント原文の逐語確認、リリースノートの原文確認)。
- 上記に当たらない一般調査(ライブラリの使い方、業界の一般的なプラクティス、比較調査、用語・背景の整理)は**agyへ出してよい**。

**`researcher`役の成果物の受け取り方**: 調査レポートの全文は**ラッパーが`<OutDir>/<timestamp>_researcher_response.md`へ書き出す**ので、親は標準出力JSONの`response_log`のパスを`Read(offset/limit)`で必要箇所だけ読む。親のコンテキストへ全文を持ち込まない(§8.2-(5))。

> **訂正(2026-08-14、T5-A75で実機反証)**: 本節にはかつて「`researcher`は`--mode plan`で起動するためagy自身はファイルを書けない」と書いていたが、**これは誤り**。`--mode plan`でもagyはリポジトリ内にファイルを作成する(T5-A75の3件すべてで発生、詳細は§7)。**agy本体はこのとき exit 0 を返す**ため、読み取り専用役の違反を検出できるのは**ラッパーのexit 17(`READONLY_ROLE_CHANGED_FILES`)判定だけ**である。この判定を無効化・緩和しないこと。生成されたファイルの扱い(採用してcommitする/破棄する)は§9.4のとおり親が決める。

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
| `-Model` / `--model` | — | 空(自動解決) | 空のときだけ`agy models`を実行し、`gemini-<major>.<minor>-flash-high`のうち数値最大のものを自動解決してagyの`--model`に渡す(T5-A78)。取得失敗・タイムアウト(目安30秒)・候補ゼロの場合はフォールバック値`gemini-3.6-flash-high`を使う(ラッパー自体は失敗させない)。明示指定時は自動解決せずその値をそのまま渡す |
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
| パイロット(現在。**2026-08-14のT5-A75で昇格条件を満たせず据え置き**) | 有人`/full_loop`の`researcher`役、§9.1のresearcher専用除外条件に当たらない一般調査を3件 | T5-A75で§9.7-7の4基準を3件中2件以上で満たす → **3件中1件のみ「採用」で未達(§7)。再度3件のパイロットを行う場合は、親による出典2本の実在性検査を必須とする** |
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
7. **`researcher`役の調査品質** → **2026-08-14、T5-A75で判定済み(3件中1件のみ採用、昇格条件未達)。結論と失敗の型は§7の「T5-A75の結論」を参照。** 以下は当時定めた判定条件(次回パイロットでも同じ基準を使う)。
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

## 11. 外部レポート(Gemini作成)のファクトチェックと反映(2026-08-14)

ユーザーがGeminiに投げて得た`docs/antigravity_claude_orchestration_report.md`を検証した(親セッションが直接`WebFetch`/`WebSearch`で実施——§9.1の「本リポジトリの意思決定に直結する一次情報の確認はagy researcherの除外対象」を体現する事例)。

**出典5件の検証結果**:

| # | 出典 | 実在性 | 主張の裏付け |
|---|---|---|---|
| 1 | `antigravity.google/docs/cli/overview` | 実在 | CLIの位置付け(軽量TUI、Antigravity 2.0と同一エージェントコア)の記述と一致 |
| 2 | `antigravity.google/docs/cli/headless` | 実在 | ヘッドレスモード(`-p`、text/json/stream-json)の記述と一致 |
| 3 | `antigravity.google/docs/cli/commands/usage` | 実在 | `/usage`パネルの例示はGeminiモデルのみ(`Gemini 3.5 Flash`等)。**ClaudeモデルやAnthropic課金への言及は無く、課金分離の主張を裏付けない** |
| 4 | `discuss.ai.google.dev`のスレッド | 実在 | 内容は「Opus選択時にモデル自身がSonnetと自己申告する」というモデルルーティングの不一致についてで、**課金/クォータ分離とは無関係**。実在URLへの無関係な帰属(T5-A75で確認済みの失敗パターン②と同型、教訓L155) |
| 5 | "PADISO Engineering Report: Model Evaluation for Code Generation & Reasoning: Sonnet vs. Gemini Architectures (2026)" | **実在確認できず** | PADISOは実在する企業ブログだが該当タイトルの記事・レポートは検索で見つからない。**捏造出典の疑いが濃厚** |

**中心的主張(§1「Token/Billing Separation」= agy経由のClaude Sonnet呼び出しはAnthropic側の課金・トークンを消費しない)は、T5-A80(2026-08-14完了・判定不能)と同一の主張**。本レポートはこれを断定調で述べるが、根拠として挙げた出典4・5はいずれも主張を裏付けない(4は無関係、5は捏造疑い)。**新規の実証にはならないため、T5-A80の結論(判定不能・§9.1ルーティング表の変更は見送り)を維持する。**

**その他の記載の評価**:
- §1「Accuracy Gap Cause」(Flashの探索深度・contextual boundariesが精度差の原因)は出典の無い分析的主張。既存の実測(T5-A79: `gemini-3.1-pro-high`より`gemini-3.7-flash-high`が上回った)と矛盾はしないが独立した裏付けも無い——仮説以上の扱いはしない。
- §2の委譲アーキテクチャ表が"Research Worker"役にGemini Pro/Sonnetを割り当てる提案は、**T5-A79の実測(proは2世代遅れでflashに劣り、かつFlashと同一クォータバケットを共有)と矛盾**。採用しない。
- §3の実践ガイド(contract-driven prompting・3層構成・JSON出力契約・workspace isolation)は一般論としては妥当で、**大部分は本設計書§9.2〜9.3で同等以上に実装済み**(3層プロンプト構造、stdout 1行JSON契約、`response_log`への全文退避等)。目新しい提案は2点のみ:
  - (a) 調査系タスクの**出力内容自体**にファイルパス/行範囲/根拠のJSONスキーマを課す案(既存のJSON契約はラッパーのメタデータ用で、中身のスキーマは未規定)。実装コストが低く、`researcher`役の報告精度向上に寄与しうる。→ **T5-A81として起票**(§改修マスタープラン.md)。
  - (b) agyのコード編集を専用worktree/ブランチへ隔離してからdiffレビューする案。**採用しない**——現状は作業ツリー直編集+コミット前`git diff`レビュー(§9.3)で同等の安全性を確保しており、単独運用・小規模リポジトリの現状ではworktreeのマージ・後片付けの運用コストが見合わない。将来トラックB本格化でagy委譲頻度が増えた場合に再検討する。

## 12. Claudeモデル別勘定確定を受けたルーティング再設計(T5-A82、2026-08-14)

作成: `architect`(Opus 5)。前提はT5-A80の追記(§7)——**agy経由の`claude-sonnet-4-6`/`claude-opus-4-6-thinking`はユーザーのClaude Proプラン枠を消費しない(別勘定、ユーザー確認により確定)**。本節はこの前提のみを新規入力として§9.1を再設計する。

### 12.1 前提の性質と、前提が崩れたときの検知方法

別勘定の根拠は**ユーザー自身のAnthropic課金情報の確認**であり、アシスタント側の実測は判定不能のまま(§7 T5-A80)。したがって本節の設計は「この一次情報が正しい」ことに全面的に依存する。前提が誤っていた場合に気づくため、次を監視する。

- **検知条件**: agy経由のClaudeモデル呼び出しを3件以上含むループで、Claudeサブエージェント体数が同等の過去ループ(`docs/token_optimization_design.md` §7)と比べ、**週次使用率の増分が+2pt以上大きい**。
- 該当したら本節のパイロットを**即時中断**し、§9.1をT5-A82以前の状態へ戻したうえで再検証する。

### 12.2 「不可」の理由を2型に切り分ける

現行§9.1の判定理由を、モデル変更で解消するか否かで分類した。

| 型 | 定義 | モデル変更で解消するか |
|---|---|---|
| **(a) ツールアクセス制約** | agyヘッドレスに当該ツールが存在しない/許可リストに無い(claude-in-chrome、Androidエミュレータ+adb、`tools/ui_probe.ps1`、`Skill`ツール、未登録シェルコマンド) | **しない**。モデルを変えても同じ壁に当たる |
| **(b) モデル品質・コスト制約** | 実行自体は可能だが、選べるのがGemini系のみで品質が届かない/Claudeは高コストだと考えられていた | **する可能性がある**。別勘定確定により後段の「高コスト」は消滅した |

役割ごとの切り分け結果:

| 役割 | 現行判定 | 理由の型 | 判定 |
|---|---|---|---|
| `implementer` | 条件付き常時 | **(b)** | Gemini品質への不確実性から対象を絞っていた。Claude化で拡大余地あり |
| `verifier` | 不可 | **(a)** | 後述12.4のとおり不可を維持 |
| `adversary` | 可(Gemini) | — | 判定自体は「可」。論点はモデル選択(12.5) |
| `ui_verifier` | 不可 | **(a)** | 不可を維持(12.4) |
| `researcher` | パイロット | **(b)** | 失敗2件はいずれも出典の質=モデル起因。Claude化で改善見込み |
| `architect` | 不可 | **(b)+一部(a)** | 設計品質を理由とする(b)が主。ただし視覚デザイン検討(`Skill`で`frontend-design`を読む)とブラウザ再現を伴う原因究明は(a)で不可のまま |

### 12.3 再設計後の §9.1 ルーティング表(T5-A83〜A87の完了に応じて段階適用)

**T5-A83完了・T5-A89実装により、本表は§9.1の現行ルーティング表として採用済み(以下は各パイロットの完了状況に応じて条件が段階的に緩和される記録)。**

| 役割 | agyへ委譲 | モデル | 条件 |
|---|---|---|---|
| `implementer` | **条件付き常時** | 既定=最新Gemini Flash(自動解決) | 現行どおり`docs/`・`tools/`・`.claude/`の非Dartファイル+`lib/`のS規模。**変更しない** |
| `implementer`(Claude版) | **パイロット(T5-A86)** | `claude-sonnet-4-6`(明示指定) | `lib/`のM規模・`test/`配下を対象に3件。`gas/`は対象外(本番GASへの影響が不可逆) |
| `verifier` | **不可(型a、恒久)** | — | 12.4 |
| `adversary` | 可 | **Gemini維持** | 12.5。Claude化は「置換」ではなく「フェーズ完了ループでの2本目追加」としてのみ検討 |
| `ui_verifier` | **不可(型a、恒久)** | — | 12.4 |
| `researcher` | **パイロット(T5-A85)** | `claude-sonnet-4-6`(明示指定) | `tools/verify_citations.ps1`の機械検証(exit 18)は**モデルに関わらず必須のまま**。専用除外条件の緩和は12.6の条件を満たしてから |
| `architect` | **パイロット(T5-A87)** | `claude-opus-4-6-thinking`(明示指定) | 12.7。**設計成果物はファイルに書かせず`response_log`経由で受け取る**(読み取り専用役として扱い、exit 17の検出を維持する) |

**役割によらない追加の除外条件は現行のまま全て有効**(未登録シェルコマンド必須/本番Sheets・Drive・デプロイ・commit/push/秘密情報/夜間ループ)。これに**2件を追加**する。

- **夜間ループ(`/night_loop`)ではClaudeモデルを指定しない**。パイロット中の委譲先を無人実行で使わない既存方針(§9.5)と同じ理由。
- **1ループあたりのClaudeモデル委譲は既定2件まで、うち`architect`役は1件まで**。3pバケット(`3p-weekly`/`3p-5h`)の残量をヘッドレスで観測できない(§5-9のregression)ため、**件数上限で代替する**。1件あたりの消費率が実測できた時点(T5-A84)でこの上限を見直す。
  - **2026-08-15、T5-A84の実測により見直したが、T5-A85の実測で訂正**: `agy -p "/usage"`はPowerShell経由なら正常に観測できる(§5-9の`/usage`失敗はGit Bash固有、教訓L158訂正版)ため「観測できない」という前提は崩れた。ただし**「1件あたりの消費率」はタスクの重さで大きく変わる**——T5-A84のスモーク3件(軽量、単発応答)は週次-2.07pt/5時間-6.23ptと小さかったが、**T5-A85のresearcher3件(Web検索・複数ページ取得を伴う重いタスク)は週次-18.2pt/5時間-54.5ptと一桁大きい**(3件+診断2件の合計、5時間残は93.77%→39.26%まで低下)。**「5時間残が潤沢なら件数上限を設けない」という上記の緩和判断は時期尚早だったため撤回し、`researcher`/`implementer`役も引き続き既定2件まで(件数上限)を基本としつつ、重いタスク(Web検索・複数ファイル探索を伴うもの)ではパイロット1件ごとに`agy -p "/usage"`で5時間残を確認し20%を下回れば即中断する**運用とする(§12.9の共通中断条件と整合)。`architect`役はコスト最大要因(§7)のため引き続き1ループ1件までを維持する。

### 12.4 `verifier`・`ui_verifier`が「不可」のままでよい理由(確認結果)

**両者ともモデル変更では解決しない(型a)。不可を維持する。**

- `verifier`: 必須ツールは(1)`tools/verify.ps1`の実行、(2)`claude-in-chrome`によるブラウザ確認、(3)失敗ログの読解。このうち(2)はagyに存在しない(組み込みChrome DevTools MCPの可否は§5-3で未調査のまま)。ローカル配信用のポート起動コマンドも許可リストに無い。加えて(1)は**決定的スクリプトであり親が直接叩ける=LLMを介在させる利得がゼロ**、(3)だけをagyへ出しても`verify.ps1`のJSONを読むだけの軽作業で、委譲のオーバーヘッドに見合わない。**「Claudeモデルが使えるようになったこと」は`verifier`の不可判定に何の影響も与えない。**
- `ui_verifier`: エミュレータ起動・adb操作(`tools/ui_probe.ps1`は許可リスト未登録)・撮影したPNGを自分で見る画像判定が必須。前2つは型a、3つ目もagyヘッドレスでの画像入力可否が未検証。**不可を維持。**

### 12.5 `adversary`: Geminiを既定のまま維持する

**モデル系統の多様性はレビューの本質的な価値**であり(§9.1既述)、Claudeへ置き換えるとその利点を失ったうえで、レビュアの系統が親・実装者と同一になり同じ盲点を共有する。一方でClaudeレビューを**追加**すれば多様性は増えるが、3pバケットを消費し所要時間も伸びる。

**判断**: 置換しない。**フェーズ/トラック完了ループに限り、Gemini `adversary`に加えて`claude-sonnet-4-6`の2本目レビューを1回だけ試す**(T5-A77と同一ループで実施してよい)。評価は「2本目だけが見つけたCritical/Major件数」で行い、0件なら以後行わない。

### 12.6 `researcher`: `claude-sonnet-4-6`化と除外条件の緩和可否

T5-A75の不採用2件の失敗は型①(実在しないURL)と型②(実在URLへの無関係な帰属)で、いずれも**小型モデルに典型的な弱点**。T5-A79で型①はプロンプト強化で消えたが型②は残り、機械照合(exit 18)を関門に置いた。Claude化で型②の発生率が下がることは期待できるが、**型②はモデル系統によらず起こりうる一般的な失敗**でもあるため、次の2点を設計として固定する。

1. **`tools/verify_citations.ps1`の関門はモデルに関わらず外さない。** Claude化を理由に緩和しない。
2. **専用除外条件は2つに分けて扱う。**
   - 「本リポジトリの意思決定に直結する一次情報の確認(公式ドキュメント原文・リリースノートの逐語確認)」→ **緩和候補**。機械照合が原文一致をまさに検査する領域であり、パイロットが基準を満たせばagyへ出してよい。
   - 「規約・権限・課金・セキュリティの判断根拠になる調査」→ **緩和しない(恒久)**。URLが実在し引用が一致していても**解釈を誤る**ことがあり(§11の外部レポートがまさにこの型)、誤情報が設計を直接汚染する非対称なコストを負う。

### 12.7 `architect`: 慎重段階のパイロット計画

コスト最大要因(§7参照、architect込みループは$19〜$22・セッション30pt超)であり、別勘定のOpusで置き換えられれば効果は最大。一方で**設計の誤りは実装・検証・差し戻しを経て遅れて表面化する**ため、失敗コストも最大。したがって次の枠組みを課す。

**(1) 全面移行は提案しない。** パイロットは3件、いずれも影響範囲の小さいものから順に行い、1件ごとに親が採否を判断する。

**(2) 対象外(Claude `architect`固定・型aのため恒久)**
- 視覚的デザインの検討を含む設計(`Skill`ツールで`frontend-design`を読む必要があり、agyには`Skill`が無い)
- ブラウザでの再現・コンソールログ確認を伴う原因究明(claude-in-chromeが必要)
- implementerが2回失敗した後の原因究明(**最後の砦であり、ここで誤ると打ち手が無くなる**)

**(3) 対象(パイロット候補、この順で1件ずつ)**
1. 運用ルール・ドキュメント構造の設計(`docs/`・`.claude/`のみに影響)
2. S規模の実装設計(`lib/`の1画面・1サービス内で閉じる)
3. M規模の実装設計(複数ファイルにまたがるが、新規フィールド・画面IDの決定を伴わないもの)

**(4) 成果物の受け取り方**: `--mode plan`+読み取り専用役として扱い、**設計書ファイルを書かせない**。全文は`<OutDir>/<timestamp>_architect_response.md`から親が読み、採用分のみ親が`docs/`へ反映する。これによりexit 17(読み取り専用役の変更検出)の防波堤が維持される。ネイティブ`architect`の絶対規則2(指示が無ければ本文として報告に含めファイルを作らない)とも整合する。

**(5) 事実誤認の検出**: パイロット中は、設計書が引用する`path:行`が実在し記述と一致するかを`tools/verify_citations.ps1`のリポジトリ内モード(T5-A88)で機械照合する。`researcher`の出典検証と同じ考え方を、外部URLではなくリポジトリ内参照に適用する。

### 12.8 パイロットの実施順序と依存関係

```
T5-A83 ラッパーのClaudeモデル対応(実装)
  └→ T5-A84 スモーク3件(読み取り/Web検索/effort受理・3pバケット消費実測)   ← ここが通らなければ以降は全て中止
       ├→ T5-A89 ルーティング表・スキル・CLAUDE.md への配線
       ├→ T5-A85 researcher × claude-sonnet-4-6 パイロット3件
       │     └→ T5-A86 implementer × claude-sonnet-4-6 パイロット3件
       └→ T5-A88 verify_citations のリポジトリ内引用モード
             └→ T5-A87 architect × claude-opus-4-6-thinking パイロット3件(T5-A85完了後)
```

`researcher`を先行させるのは、**読み取り専用・成果物が文章のみ・機械検証の関門が既にある**ため、Claudeモデルのagy上での挙動を最も安全に観測できるから。`architect`は`researcher`で挙動が確認できてから着手する。

### 12.9 判定基準(各パイロット共通の書式)

| パイロット | 件数 | 「採用」の条件(全て満たす) | 昇格条件 |
|---|---|---|---|
| T5-A85 `researcher` | 3 | (1)`verify_citations`がexit 0 (2)親が出典2本を抽出検査し実在・整合 (3)確認済み/推測の分離あり (4)日本語規約違反ゼロ (5)差し戻し1回以内 | 3件中2件以上→「条件付き常時(Claudeモデル)」。**3件中3件**かつ緩和候補テーマ(公式ドキュメントの逐語確認)を1件含む→12.6の除外条件のうち「一次情報の逐語確認」のみ緩和 |
| T5-A86 `implementer` | 3 | §9.7-5の4基準(verifier全項目パス/日本語規約違反ゼロ/既知の地雷なし/差し戻し1回以内)+**UTF-8 BOM喪失(L142)なし** | 3件中2件以上→`lib/`のM規模・`test/`をClaudeモデル限定で「条件付き常時」。`gas/`は対象外のまま |
| T5-A87 `architect` | 3 | (1)設計書のリポジトリ内引用がT5-A88の照合を全通過 (2)implementerへ渡してそのまま実装完了(親からの設計差し戻し1回以内) (3)実装後に`verifier`が全項目パス (4)未検証の断定が無い(仮説は仮説と書かれている) (5)日本語規約違反ゼロ | **1件ごとに親が判断し、不採用が1件出た時点で中断**。3件中3件採用で初めて「(3)の対象範囲に限りagy可」へ移行する。それ未満なら「不可」へ差し戻す |

**共通の中断条件**: いずれかのパイロットで(i)12.1の検知条件に該当、(ii)exit 12(権限自動拒否)が2件連続、(iii)3pバケット残が週次20%未満(ユーザーがTUIで確認)——のいずれかが起きたら、そのパイロットを中断して§7へ記録する。

**1件の数え方**: `architect`は**実装+検証まで完了して初めて1件**と数える(設計の誤りは遅れて表面化するため)。`researcher`/`implementer`は従来どおり委譲1回=1件。
