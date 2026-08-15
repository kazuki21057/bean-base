# 失敗プレイブック設計 — 既知障害の自動検知・自動対処と未知障害のエスカレーション

**タスク**: T5-A58(⚠️上位モデルで実施、`/insights`レポート 2026-08-12「今後の展望」由来)
**作成**: 2026-08-13 / architect
**位置づけ**: 無人夜間ループ(`tools/night_loop.ps1` + `/night_loop`スキル)の運用基盤の一部。正本は `docs/android_release/開発運用基盤設計.md`(§7「想定される失敗モードと対策」を本書が具体化・置き換える)。本書は**設計のみ**で、実装は後続タスク(§7)で行う。

---

## 1. 目的と設計方針

### 1-1. 解きたい問題

無人ループで障害が起きるたび、翌朝の有人セッションがゼロから原因究明している。同じパターン(ファイルロック・BOM喪失・エミュレータ・権限拒否)が繰り返されており、**既知のものは機械が判定して片付け、未知のものだけ人間に上げる**ことで人間側のコストを削る。

### 1-2. 5つの設計原則

| # | 原則 | 理由 |
|---|---|---|
| P1 | **プレイブック自身が新たな停止要因にならない**(fail-open) | 検知層が落ちてループが止まったら本末転倒。プレイブック内の例外は握りつぶし、記録だけ残して exit 0 する |
| P2 | **自動対処は「冪等・非破壊・限定範囲・誤爆時無害」の4条件を全て満たすものだけ** | §3-2 の判定基準。1つでも欠ければ「検知して記録・通知するだけ」に落とす |
| P3 | **権限設定は絶対に自動変更しない** | 無人実行の唯一の実効的な安全装置が `deny`/`allow`(開発運用基盤設計 §4-4)。無人プロセス自身にそれを緩めさせるのは権限昇格そのもの(教訓 L134) |
| P4 | **未知障害はリトライせず、証拠を束ねて1回で人間へ** | 原因不明のまま再試行すると被害が広がる。人が読む材料(ログ抜粋・git status・直近の判定)を機械が先に集めておく |
| P5 | **記録は必ず残す。「何も起きなかった」と「記録できなかった」を区別する** | 2026-08-12のファイルロック事故は、記録が消えていたことに3日気付けなかった(commit 77d6094) |

### 1-3. 既存の仕組みとの関係(重複を作らない)

| 既存 | 本設計での扱い |
|---|---|
| `tools/night_loop.ps1` の `Write-LineWithRetry` / フォールバックログ / 日次ローテーション(77d6094) | **FP-01 の対処層としてそのまま使う。** 共有ヘルパーとして `tools/lib/loop_io.ps1` へ切り出し、プレイブックからも呼ぶ |
| `Save-NightLoopLastRun -Outcome ...`(`.claude/night_loop_last_run.json`) | **エスカレーションの出口として拡張する。** outcome を追加し、履歴ログ `.claude/night_outcomes.log` への追記を同時に行う(FP-06 のデータ源) |
| `tools/check_encoding.ps1` + PostToolUse フック(T5-A50、実装済み) | **FP-02 の検知経路(a)。** 重複実装せず、プレイブックは「ループ境界での一括検査+自動修復」を担当する |
| `tools/emulator.ps1` の `Clear-StaleEmulator` / `-Doctor`、`tools/ui_probe.ps1` の `Assert-DeviceAlive` | **FP-03 の対処層としてそのまま使う。** プレイブックは判定と呼び出し順の制御だけを持つ |
| `tools/antigravity_delegate.ps1` の終了コード 10〜17(`docs/antigravity_delegation_design.md` §9.4) | **FP-05(a) の検知シグネチャとして読むだけ。** 既存のフォールバック挙動は変更しない |
| **T5-A53(`tools/preflight.ps1` 新設)** | **本設計に統合する。** `preflight.ps1` は作らず `tools/failure_playbook.ps1 -Mode Preflight` に一本化する(2つの起動前チェックが並立すると必ず片方だけ更新されて乖離する)。T5-A53 は本設計のタスク群に吸収して閉じることを提案する |

---

## 2. 全体構成

### 2-1. 実行形態

単一のスクリプト `tools/failure_playbook.ps1` を4モードで使う。**すべて PowerShell 側の処理**であり、LLM(claude)は結果ファイルを**読むだけ**にする(`.claude/` 配下への `Edit`/`Write` はハーネスの分類器にハードブロックされる、教訓 L140)。

| モード | 呼び出し元 | 実行タイミング | 主な対象ルール |
|---|---|---|---|
| `-Mode Preflight` | `night_loop.ps1`(手順7.5の直前) | claude 起動前 | FP-01, FP-02, FP-06, FP-07 |
| `-Mode Watchdog` | `night_loop.ps1`(手順9で別プロセス起動) | claude 実行中、常駐 | FP-05(c) |
| `-Mode Postmortem` | `night_loop.ps1`(手順10) | claude 終了後 | FP-02, FP-04, FP-05(a), 未知障害 |
| `-Mode Check` | `/night_loop` スキル(手順5のpushゲート前) | push 判定の直前 | FP-02(変更された `.ps1` のみ) |

### 2-2. 引数

| 引数 | 型 | 既定 | 説明 |
|---|---|---|---|
| `-Mode` | string(必須) | — | `Preflight` / `Watchdog` / `Postmortem` / `Check` |
| `-WrapperPid` | int | `$PID` | Watchdog が子孫プロセスを辿る起点(`night_loop.ps1` の PID) |
| `-StreamLogPath` | string | — | Watchdog/Postmortem が読む `.claude/night_logs/<stamp>.jsonl` |
| `-ErrLogPath` | string | — | Postmortem が読む `.claude/night_logs/<stamp>.err.log` |
| `-ClaudeExitCode` | int | 0 | Postmortem に渡す claude の終了コード |
| `-StallMinutes` | double(T5-A65実装時にintから変更。理由は§9-7) | 20 | Watchdog: jsonl が伸びない許容時間(1段目) |
| `-HardCapMinutes` | double(同上) | 90 | Watchdog: 起動からの絶対上限 |
| `-Unattended` | switch | — | 無人モード(`$env:BEANBASE_NIGHT_LOOP -eq '1'` を呼び出し元が判定して渡す)。FP-03/FP-05 の自動対処はこの指定時のみ実行する |
| `-ConfigPath` | string | `tools\failure_playbook.config.json` | しきい値の上書き(無ければ既定値で続行、`night_loop.config.json` と同じ方針) |

`-ConfigPath` で指定する設定ファイル(`tools/failure_playbook.config.json`)のキー(T5-A90で追加。Preflight実行ループの外部呼び出しがタイムアウト無しでハングした事故の再発防止、詳細は§3 FP-03の訂正注記・§8リスク表9行目):

| キー | 既定 | 説明 |
|---|---|---|
| detectBudgetSec | 120 | Preflight/Postmortem/Check のDetect累積所要の上限秒。超過後のルールは実行せず「判定不能(タイムアウト)」として escalate 記録する |
| slowDetectWarnSec | 30 | 単一ルールのDetectがこの秒数を超えたら result=slow_detect の警告を1行記録する(検知結果には影響しない) |
| adbTimeoutSec | 15 | adb.exe 単発呼び出しの上限秒 |
| emulatorStatusTimeoutSec | 30 | tools/emulator.ps1 -Status(子プロセス)の上限秒 |
| emulatorControlTimeoutSec | 150 | tools/emulator.ps1 -Start / -Stop(子プロセス)の上限秒 |
| wmiTimeoutSec | 20 | Get-CimInstance の -OperationTimeoutSec |

### 2-3. 標準出力(1行JSON)と終了コード

`tools/antigravity_delegate.ps1` と同じく **標準出力は1行JSONのみ**(人間向けメッセージは `Write-Host` とログファイルへ)。

```json
{"ok":true,"phase":"preflight","detected":[{"ruleId":"FP-02-BOM","severity":"auto","action":"repaired","result":"ok","detail":"tools/emulator.ps1 にBOMを再付与"}],"escalate":false,"escalations":[]}
```

| 終了コード | 意味 | 呼び出し元の扱い |
|---|---|---|
| 0 | 検知なし、または自動対処が成功した | そのまま続行 |
| 1 | 検知したが続行可能(warn / 人間への申し送りあり) | **続行する。** night_report に申し送りを書く |
| 2 | 続行不可(§4 の abort 対象のみ) | claude を起動せず `Save-NightLoopLastRun -Outcome 'error_preflight'` で終了 |

**exit 2 を返してよいのは FP-07 の必須バイナリ不在・ディスク空き不足だけ**とする(P1)。ファイルロック・BOM・エミュレータ・スタール検知は**絶対に abort しない**——プレイブックが新しい「毎晩スキップされる」原因になるのを防ぐ。

### 2-4. 生成・更新するファイル(すべて確定)

| パス | 形式 | 書き手 | 用途 |
|---|---|---|---|
| `.claude/failure_events.tsv` | TSV(ヘッダ付き) | プレイブック | 全検知イベントの追記ログ。列: `timestamp / phase / ruleId / severity / action / result / detail` |
| `.claude/failure_state.json` | JSON | プレイブック | ルールごとの連続回数と最終状態。`{"FP-01-FILELOCK":{"consecutive":2,"lastAt":"...","lastAction":"switched","lastResult":"ok","escalated":false}, ...}` + トップレベルに `{"lastOutcome":"...","lastOutcomeStreak":3,"updatedAt":"..."}` |
| `.claude/failure_reports/<yyyyMMdd-HHmmss>-<ruleId|unknown>.md` | Markdown | プレイブック | 人が読む証拠束(§5) |
| `.claude/night_outcomes.log` | TSV | `night_loop.ps1`(`Save-NightLoopLastRun` から) | 1行=1発火の `timestamp / outcome / reason`。FP-06 の唯一のデータ源 |
| `night_report.md`(リポジトリ直下) | Markdown | `night_loop.ps1` / claude | 既存。§6 の「## 検知した障害」節を追加する |

`.gitignore` へ追加(既存の `.claude/night_*` と同じ扱い): `.claude/failure_events.tsv` / `.claude/failure_state.json` / `.claude/failure_reports/` / `.claude/night_outcomes.log`。

### 2-5. ルール登録簿の持ち方

ルール(ID・シグネチャ・重大度・対処・上限回数)は **`tools/failure_playbook.ps1` 内の PowerShell 配列として持つ**。別JSONに切り出さない——シグネチャの正規表現と対処コードが離れると片方だけ更新されて乖離するため。ルールレコードの形は次で固定する。

```
@{ Id='FP-02-BOM'; Title='UTF-8 BOM喪失'; Phase=@('Preflight','Postmortem','Check');
   Severity='auto';            # auto | warn | escalate
   MaxAutoAttempts=1;          # これを超えたらescalate
   Detect={ ... };             # スクリプトブロック。検知したら詳細文字列の配列を返す
   Repair={ param($detail) ... } }   # Severity='auto' のときのみ呼ばれる
```

---

## 3. 既知障害の一覧

### 3-1. 一覧(7パターン)

| ID | 障害 | 裏付け | 重大度 | 自動対処 |
|---|---|---|---|---|
| FP-01-FILELOCK | ログファイルのロック(孤児プロセスによる共有違反) | **実発生**(2026-08-12、commit 77d6094) | warn(切替のみ auto) | 書き込み先の切替のみ。**kill はしない** |
| FP-02-BOM | `.ps1` の UTF-8 BOM 喪失 | **実発生**(教訓 L127 / L142) | auto | BOM 再付与 + 構文再検査 |
| FP-03-EMULATOR | Android エミュレータのクラッシュ / 無反応ハング | **実発生**(T5-A31 で約9分ハングを観測、T5-A32 で対処済み) | auto(無人時のみ) | `-Stop` → `Clear-StaleEmulator` → `-Start` を最大1回 |
| FP-04-PERMISSION | `dontAsk` の allow 未列挙によるツール拒否 | **実発生**(教訓 L132) | escalate | **禁止**(検知と提案文の生成のみ) |
| FP-05-HANG | エージェント / claude プロセスのハング | (a)agy は設計上の既定動作、(c)claude 本体は**未観測(仮説)** | (a)auto / (c)warn→条件付き停止 | (a)Claude へフォールバック、(c)2段階の猶予後に子孫プロセスを特定停止 |
| FP-06-SILENTSTALL | 同一スキップ/エラーが連続し、ループが実質停止 | **実発生**(commit abed7f6、4回連続 `skipped_session_window`) | warn | なし(検知・通知のみ) |
| FP-07-MISSINGBIN | 必須バイナリ不在・ディスク空き不足 | claude 不在時の処理は実装済み。agy PATH 不在は**マスタープラン T5-A53 の記述由来で未検証** | escalate(agy のみ auto) | agy 不在時に委譲先を Claude 固定にするだけ |

### 3-2. 自動対処を許すかどうかの判定基準(安全側の基準)

**次の4条件を全て満たすときだけ `Severity='auto'`(自動実行)とする。1つでも欠ければ `warn`(検知+記録+通知)へ落とす。**

1. **冪等**: 2回実行しても結果が変わらない
2. **非破壊**: 削除・上書きを伴わない。伴う場合は事前に退避したうえで復元可能
3. **限定範囲**: 影響がリポジトリ配下、または**本ループ自身が作った資源**に閉じる
4. **誤爆時無害**: 検知が誤りだった場合の被害が「無駄な1操作」で済む

**原則 warn 以上に置くもの**: プロセスの kill、ファイル・ディレクトリの削除、権限設定(`.claude/settings*.json`)の変更、git 履歴・作業ツリーの変更(`git reset` / `git clean` / `git checkout --` / `git stash`)。

**唯一の例外は FP-05(c) の停止処理**。理由は (a) 停止対象を「wrapper の子孫プロセス」かつ「コマンドラインに `night_loop` を含む」で**一意に確定でき**、名前一致の総当たり kill を避けられること、(b) 放置すると翌朝まで**ループ全体が停止したまま**になり被害が停止処理より大きいこと。ただし2段階(警告 → 猶予 → 停止)を必須とし、対象が0件なら**停止せず escalate のみ**にする。

**有人時の縮退**: `-Unattended` が無い(人が見ている)場合、FP-03 の自動再起動と FP-05(c) の停止は**行わない**。検知して提示するに留める。

---

### FP-01-FILELOCK ログファイルのロック

**症状**: `tail -f` 等の常駐監視コマンドが孤児化してログファイルのハンドルを握り続け、`Add-Content` が失敗し続ける。ラッパーは「成功」で終了するため、記録が無いことに気付けない。

**検知シグネチャ**(いずれか1つで検知)

| # | 対象 | 判定 |
|---|---|---|
| A | `.claude/night_logs/wrapper-<yyyyMMdd>.log` / `.claude/night_runs.log` / `.claude/night_skips.log` / `.claude/night_usage_log.tsv` / `.claude/night_outcomes.log` / `.claude/night_loop_last_run.json` / `night_report.md` | `[System.IO.File]::Open($p,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)` が `IOException` を投げ、`$_.Exception.HResult -band 0xFFFF` が **32(ERROR_SHARING_VIOLATION)または 33(ERROR_LOCK_VIOLATION)** |
| B | `.claude/night_logs/wrapper.fallback-*.log` / `night_skips.fallback-*.log` / `night_usage_log.fallback-*.log` | 存在し、`LastWriteTime` が直近24時間以内(=前回の発火でロック回避が発動した痕跡) |
| C | 容疑プロセス | `Get-CimInstance Win32_Process` で `CommandLine` に `night_logs` または `wrapper-` を含み、かつ `Name` が `tail.exe` / `more.com` / `powershell.exe` / `pwsh.exe`、かつ `ParentProcessId` のプロセスが**存在しない**(孤児) |

**自動対処**

- **(auto)** シグネチャ A を検知したファイルは、当日分に連番サフィックスを付けた新規パス(`wrapper-20260813-2.log` のように)へ**書き込み先を切り替える**。冪等・非破壊・誤爆時は「ログが1本増えるだけ」なので4条件を満たす。切替後のパスは `failure_events.tsv` と `night_report.md` に記録する。
- **(warn / 自動実行しない)** シグネチャ C の容疑プロセスの **kill はしない**。誤爆時の被害は「ユーザーが手動で開いている監視プロセス・エディタの強制終了(未保存データの消失)」で、条件4を満たさない。代わりに PID・プロセス名・コマンドラインを警告として記録し、night_report の「人がやること」に**終了すべき PID を明示**する。
- 設定 `autoKillLockHolders`(既定 **false**)を用意する。true にした場合でも、対象は「孤児(親不在)」かつ「名前が `tail.exe` / `more.com`」かつ「`-Unattended` 指定時」の3条件を全て満たすものに限る。**既定値を true にしない。**
- シグネチャ B のフォールバックログは**本体ログへ自動統合しない**(時系列が壊れるため)。存在の記録のみ。

**エスカレーション基準**

- 書き込み先を切り替えても書けない → **その場で escalate**(自動リトライ 0 回)。
- フォールバックログが**3日連続**で生成されている → escalate(切替で凌げているが根本が残っている)。

---

### FP-02-BOM `.ps1` の UTF-8 BOM 喪失

**症状**: 日本語コメント入り `.ps1` が BOM 無し UTF-8 で保存され、PowerShell 5.1 が ANSI と誤認して構文エラーになる。Claude の `Write` でも agy の編集でも起きる(L127 / L142)。

**検知シグネチャ**

| # | 対象 | 判定 |
|---|---|---|
| A | PostToolUse フック(既存 `tools/check_encoding.ps1`) | `.claude/encoding_warnings.log` に当ループ境界(`.claude/loop_boundary.txt`)以降のタイムスタンプの行がある |
| B | `Preflight`: `tools/*.ps1` と `.claude/hooks/*.ps1` の全件 / `Postmortem`・`Check`: `git diff --name-only` + `git ls-files --others --exclude-standard` の `*.ps1` | `[System.IO.File]::ReadAllBytes($p)` の先頭3バイトが `EF BB BF` でない |
| C | 同上 | `[System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$null, [ref]$errs)` の `$errs.Count -gt 0` |

**自動対処**

- **(auto)** シグネチャ B を検知したら、既存バイト列の先頭に BOM を付与して書き戻す(`[System.IO.File]::WriteAllBytes` で `EF BB BF` + 元バイト列、**内容は1バイトも変更しない**)。4条件をすべて満たす(冪等・非破壊・リポジトリ内・誤爆しても BOM が付くだけで PowerShell は正しく読む)。
- 修復後に必ずシグネチャ C を再実行し、`$errs.Count -eq 0` を確認する。**0 にならなければ BOM 以外の破壊**なので修復を打ち切り escalate(該当ファイルは触らずそのまま残す)。
- 対象は**リポジトリ配下の `.ps1` のみ**。他拡張子・リポジトリ外は一切触らない。

**エスカレーション基準**

- 修復後も `ParseFile` エラーが残る → **即 escalate**。
- 同一ファイルが**2ループ連続**で修復対象になった(直しても壊れ続ける)→ escalate。
- `Check` モードで escalate になった場合、`/night_loop` スキルは **push ゲートを通さない**(§6-2)。

---

### FP-03-EMULATOR エミュレータのクラッシュ / ハング

**症状**: プロセスは生存したまま `adb` に応答しなくなる(T5-A31 で約9分のハングを観測)、または突然クラッシュして `multiinstance.lock` が残る。

**検知シグネチャ**

| # | 判定 |
|---|---|
| A(死亡) | `tools/emulator.ps1 -Status` が実行中AVDを返さない、または `adb devices` に `beanbase_ui` のシリアルが出ない |
| B(ハング) | `adb -s <serial> get-state` が **10秒以内に応答しない**、または `device offline` を返す。あるいは `adb shell getprop sys.boot_completed` が `1` を返さない状態が **120秒継続**。この間 `qemu-system-x86_64` プロセスは生存している(`HasExited` では検知できない) |
| C(残骸) | `<avdHome>/beanbase_ui.avd/multiinstance.lock` または `hardware-qemu.ini.lock` が存在するのに `adb devices` に現れない |
| D(クラッシュ痕跡) | `Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='Windows Error Reporting'; StartTime=<ループ開始>}` に `qemu-system-x86_64` を含むイベントがある(T5-A30 で使った確認手法) |

**自動対処**

- **(auto、`-Unattended` 指定時のみ)** `tools/emulator.ps1 -Stop` → `Clear-StaleEmulator` → `-Start -AvdName beanbase_ui` を **最大1回**(合計2回試行、`rules/verification.md` の「エミュレータ検証はリトライ2回上限」= T5-A56 と整合)。
- 対象 AVD を **`beanbase_ui` に固定**する。他の AVD には触らない(ユーザーが手動で使っている可能性があるため、条件3を満たすための制約)。
- 有人時(`-Unattended` なし)は再起動せず、検知内容の提示のみ。

**エスカレーション基準**

- 2回目の起動も失敗 → escalate。ただし**ループ自体は中断しない**。Android 検証を「未実施(理由: エミュレータ復旧失敗)」として扱い、**push ゲートの条件2は「満たされていない」と扱う**(= main には入れず `night/<タスクID>` ブランチ + PR)。Web(Chrome)側の検証は続行してよい。

（訂正・T5-A90）本ルールの「10秒タイムアウト」は当初シグネチャB(adb get-state)のみに掛かっており、
その手前の adb start-server と tools/emulator.ps1 -Status が無制限だったため、2026-08-15に
Preflightが約9時間ハングする事故を起こした。以後、FP-03の外部呼び出しは全て
Invoke-ProcessWithTimeout(tools/lib/loop_io.ps1)経由とし、tools/emulator.ps1 は
kill可能な子プロセスとして呼ぶ。-Status がタイムアウトした場合は新シグネチャ T として扱い、
自動再起動(Repair)は行わない(同じadb経路で再び刺さるため)。

---

### FP-04-PERMISSION `dontAsk` による権限拒否

**症状**: `.claude/settings.night.json` の `allow` に未列挙のツールが黙って拒否される(`dontAsk` は「allow に無ければ拒否」、教訓 L132)。無人実行では誰も気付けない。

**検知シグネチャ**(`Postmortem` で `.jsonl` と `.err.log` を走査、大文字小文字無視)

| # | 正規表現 / 条件 |
|---|---|
| A | `Permission to use (?<tool>[A-Za-z_]+) has been denied` |
| B | `running in don'?t ask mode` |
| C | `permission that headless mode cannot prompt for`(agy 側。`docs/antigravity_delegation_design.md` §9.4 の exit 12 と同一文字列) |
| D | `.claude/agy_logs/ledger.tsv` の当ループ境界以降の行で `exit_code` が `12` |

**自動対処**

- **禁止(escalate のみ)**。`.claude/settings.night.json` および `.claude/settings*.json` の `allow`/`deny` を**プレイブックが書き換えることを明示的に禁止する**(P3。無人実行の唯一の実効的な安全装置を無人プロセス自身に緩めさせないため。教訓 L134 の再発防止でもある)。
- 代わりに、拒否されたツール名(シグネチャ A の `tool` キャプチャ)から **`allow` へ追加すべき候補行をそのまま貼れる形で生成**し、night_report の「人がやること」に書く。例:

  ```
  - **人がやること**: `.claude/settings.night.json` の `permissions.allow` に次の1行を追加してください
    "PowerShell(powershell -File tools\\failure_playbook.ps1*)"
  ```

**エスカレーション基準**

- **1件でも検知したら即 escalate**(リトライしない)。
- ただし push ゲートの判定は変えない——検証(`verify.ps1` / `adversary`)が全 green ならその結果を信じる。拒否の事実は night_report に必ず残す。

---

### FP-05-HANG エージェント / claude プロセスのハング

3層に分けて扱う。**(c) は未観測の仮説**であり、実装は「まず記録、次に停止」の2段階にする。

#### (a) agy 委譲のハング(裏付けあり: ラッパーの既定動作)

- **検知**: `.claude/agy_logs/ledger.tsv` の当ループ境界以降の行に `exit_code=11`(外側タイムアウトで kill、§9.4)。
- **自動対処(auto)**: 既存ルールどおり Claude サブエージェントへフォールバック。プレイブックは**記録するだけ**で挙動を変えない(`.claude/loop_failures.txt` の連続失敗にも数えない、`CLAUDE.md` の既存規定)。
- **エスカレーション**: 同一タスクで2回連続 exit 11 → escalate(agy 側の恒常的な問題を疑う)。

#### (b) Claude サブエージェント(`Task`)のハング

- コードで検知しない。**親セッションの運用ルール**(目安10分でタイムアウトして切り替える)として `/night_loop` スキルに残す。理由: `Task` の進行はハーネス内部にあり、外部プロセスからは観測できない。
- ただし (b) が起きると結果的に (c) の stall として現れるため、実効的な受け皿は (c) が持つ。

#### (c) claude プロセス本体の無応答(**仮説・未観測**)

- **検知シグネチャ**: `-Mode Watchdog` を `night_loop.ps1` の手順9で**別プロセスとして先に起動**し、30秒間隔で次を見る。
  - **stall**: `-StreamLogPath` の `.jsonl` の `Length` と `LastWriteTime` が **`StallMinutes`(既定20分)変化しない**、かつ対象プロセスが生存している
  - **hardcap**: 起動から **`HardCapMinutes`(既定90分)** 経過
- Watchdogの診断ログを `.claude/night_logs/watchdog-<yyyyMMdd-HHmmss>-<wrapper PID>.out.log` / `.err.log` にリダイレクトし、Watchdog終了確認後に wrapper.log へ `[failure_playbook] watchdog-stdout:` / `watchdog-stderr:` として転記してから削除する。
- **監視対象プロセスの特定**(名前一致の総当たりを禁止するための手順、確定):
  1. `Get-CimInstance Win32_Process -Filter "ParentProcessId=$WrapperPid"` から**深さ5まで再帰的に子孫を列挙**する(`claude` は `.cmd` シム経由で `cmd.exe` → `node.exe` になりうるため、直接の子だけでは足りない)
  2. そのうち `Name` が `claude.exe` / `node.exe` で、かつ `CommandLine` に `night_loop` を含むものだけを対象とする
  3. 該当が **0件なら停止処理を行わず escalate のみ**(誤爆回避)
- **自動対処(2段階)**:
  - 1段目(`StallMinutes` 到達): **警告のみ**。`failure_events.tsv` に `action=none / result=warned` を記録し、監視を続ける
  - 2段目(合計 `StallMinutes`×2 = 40分 無成長、または hardcap 到達): 上記で確定した対象を**子孫から順に** `Stop-Process -Id <pid> -Force` する
  - 停止後: `Save-NightLoopLastRun -Outcome 'error_watchdog_stall'`、証拠束(§5)を生成、night_report に停止時刻・`.jsonl` の最終行・`git status --porcelain` の一覧を書く
- **作業ツリーには一切触らない**。`git stash` / `git reset` / `git checkout --` の自動実行は禁止(P2、かつ夜間プロファイルの deny 対象)。停止後は作業ツリーが汚れたまま残るため、次回発火は既存の「作業ツリー汚れガード」でスキップされる——これは**意図した挙動**(壊れた状態で次のタスクを始めない)。ただしそのスキップは FP-06 が拾って「停止しています」と通知する。
- **Watchdog 自身の制約(重要)**: 監視対象ファイルを**開いたまま保持しない**。`Get-Item` の `Length` / `LastWriteTime` のみを見る。ハンドルを保持すると Watchdog 自身が FP-01 の原因になる。また `night_loop.ps1` は claude 終了後に `.claude/night_watchdog.stop` を作成し、Watchdog はその存在または `WrapperPid` の消滅を検知して**自ら終了する**(孤児化させない)。フラグは片方向の通知に過ぎないため、`night_loop.ps1` 側は `Start-Process -PassThru` で保持したプロセスオブジェクトに対し `WaitForExit(45秒)` で実際の終了を確認する。タイムアウト時は `Stop-Process -Force` で回収する。順序は「フラグ作成→終了確認→フラグ削除→診断ログの転記・削除」で固定し、終了確認より前にフラグ削除やログ削除へ進んではならない(Watchdogがフラグを一度も観測できないレース、および `-RedirectStandardOutput/-RedirectStandardError` のハンドル保持による削除失敗=FP-01の自作自演を防ぐ)。タイムアウト値は「ポーリング間隔+15秒」以上を保つ。

**エスカレーション基準**: Watchdog が停止処理を実行したら**常に人間へ**。同じタスクを自動で再試行しない(`failure_state.json` に記録し、`/night_loop` スキル手順1が読んで別タスクを選ぶ)。

---

### FP-06-SILENTSTALL 同一スキップ / エラーの連続(サイレントスタール)

**症状**: ラッパーは毎回正常終了しているが、同じ理由でスキップし続けて実際には何も進んでいない。実際に4回連続 `skipped_session_window` が起き、人が気付くまで放置された(commit abed7f6)。

**検知シグネチャ**

- データ源として **`.claude/night_outcomes.log`**(1行=1発火の `timestamp<TAB>outcome<TAB>reason`)を新設し、`Save-NightLoopLastRun` から `Write-LineWithRetry` で追記する(既存の `night_loop_last_run.json` は1件しか保持せず履歴が取れないため)。
- 判定(いずれか):
  - 直近 **3回**の発火が**同一 outcome** で、かつ `completed` 以外
  - 直近 **72時間**に `outcome=completed` が **1件も無い**
  - 直近 **5回**の発火に `error_*` が **3件以上**含まれる

**自動対処**

- **なし(検知・通知のみ)**。スキップの多くは正当(有人セッションが動いている、作業ツリーが汚れている)であり、自動解除は正当なガードを潰す。条件4(誤爆時無害)を満たさない。

**エスカレーション基準**

- 3回連続 → toast + `night_report.md` の「人がやること」に理由と outcome を明記
- 5回連続 → `night_report.md` の**見出し行**を `# ⛔ 夜間ループが停止しています(<outcome> が5回連続)` にして、朝スマホで開いた瞬間に分かる形にする

---

### FP-07-MISSINGBIN 必須バイナリ不在・ディスク空き不足

**検知シグネチャ**(`Preflight`)

| 対象 | 判定 | 不在時の扱い |
|---|---|---|
| `claude` / `git` | `Get-Command <name> -ErrorAction SilentlyContinue` が `$null` | **exit 2(abort)**。既存の `error_claude_not_found` 経路と整合させる |
| `flutter` / `dart` | 同上 | exit 2(検証が一切できないため) |
| `node` | 同上 | exit 1(`loop_guard.js` が動かないが本処理は可能) |
| `adb` / `emulator` | 同上 | exit 1(Android 検証のみ不可。FP-03 の自動対処も無効化する) |
| `agy` | 同上 | **exit 0 + auto**: 委譲先を Claude 固定にする旨を記録するだけ(無害な縮退)。**この経路はマスタープラン T5-A53 の記述由来で未検証** |
| ディスク空き | リポジトリのあるドライブの空きが **2GB 未満**(`Get-CimInstance Win32_LogicalDisk`) | exit 2(ビルド・ログ出力が途中で壊れるため、始めない方が安全) |
| `.claude/settings.night.json` | 存在 + JSON 妥当性 | **既存実装(night_loop.ps1 手順7)をそのまま使う。** プレイブックでは重複検査しない |

**自動対処**: agy 不在時の委譲先固定のみ。バイナリの自動インストールは**しない**。

**エスカレーション基準**: exit 2 を返す条件はいずれも 1 回で escalate(リトライしない)。

---

## 4. 未知障害の扱い

**定義**: §3 のどのシグネチャにも合致しないまま、`night_loop.ps1` の例外・claude の非0終了・想定外の outcome が発生した状態。

### 4-1. 振る舞い(P4)

| 発生箇所 | outcome(`Save-NightLoopLastRun`) | 追加でやること |
|---|---|---|
| ラッパー層の例外(既存 `catch`) | `error_exception`(既存のまま) | 証拠束 `<stamp>-unknown.md` を生成し、night_report に「未知の障害」として記載 |
| claude 非0終了でシグネチャ不一致 | **`error_claude_exit_unknown`(新設)** | 同上。既存 `error_claude_exit` は「既知シグネチャに合致した非0終了」に限定する |
| Watchdog による停止 | **`error_watchdog_stall`(新設)** | §3 FP-05(c) のとおり |
| Preflight の abort | **`error_preflight`(新設)** | 理由(FP-07 のどれか)を `reason` に入れる |
| 既知障害を自動対処で解消できた | 通常の outcome(`completed` 等)のまま | `failure_events.tsv` に `result=ok` を記録。night_report には「自動対処: 〇〇」と1行だけ書く |

### 4-2. 未知障害はリトライしない

同じ処理を再実行しない。次のトリガー時刻には通常どおり動く(=時間を置いた1回の再試行になる)。同じ未知障害が繰り返せば **FP-06 が3回連続で拾って通知する**——これが未知障害に対する唯一の自動的な再発検知経路であり、新しいシグネチャを人間が §3 に追加するための入口になる。

### 4-3. 新しいシグネチャの追加フロー(運用)

1. 未知障害の証拠束(§5)を朝の有人セッションが読む
2. 原因が特定できたら、`tools/failure_playbook.ps1` のルール配列に1件追加し、`rules/lessons_archive.md` に教訓を追記する
3. 対処を `auto` にするかは §3-2 の4条件で判定する。**迷ったら `warn`**(検知だけして人に渡す)

---

## 5. 証拠束(`failure_reports/<stamp>-<ruleId|unknown>.md`)

人間がゼロから調査しなくて済むよう、プレイブックが機械的に集められるものを先に集める。**フォーマットを固定する**(claude に自由記述させない)。

```markdown
# 障害レポート 2026-08-13 04:12:33 — unknown

- **phase**: postmortem
- **outcome**: error_claude_exit_unknown
- **claude 終了コード**: 143
- **トリガー**: 0410 / 無人モード
- **所要時間**: 62.4分

## 直近の wrapper ログ(末尾40行)
```
(.claude/night_logs/wrapper-20260813.log の末尾40行)
```

## stderr(末尾40行)
```
(.claude/night_logs/<stamp>.err.log の末尾40行。存在しない場合は「stderr は出力されていません」)
```

## stream-json の最終3イベント
```
(.claude/night_logs/<stamp>.jsonl の末尾3行。長い行は先頭500文字で切る)
```

## 作業ツリーの状態
```
(git status --porcelain の出力。0行なら「クリーン」)
```

## 直近5回の発火結果
```
(.claude/night_outcomes.log の末尾5行)
```

## 既知シグネチャとの照合結果
- FP-01-FILELOCK: 不一致
- FP-02-BOM: 不一致
- ...(全ルールについて 一致 / 不一致 を列挙する)
```

最後の「照合結果」を必ず載せる——**何を確認済みなのか**が分かると、朝の調査が「残りの可能性」から始められる。

---

## 6. 呼び出し元への配線

### 6-1. `tools/night_loop.ps1`

| 挿入位置 | 内容 |
|---|---|
| 手順7.5(作業ツリー汚れガード)の**直前** | `-Mode Preflight` を実行。exit 2 なら claude を起動せず `Save-NightLoopLastRun -Outcome 'error_preflight'` で終了(exit 2)。exit 1 なら記録して続行 |
| 手順9(claude 起動)の**直前** | `Start-Process powershell -ArgumentList '-NoProfile','-File','tools\failure_playbook.ps1','-Mode','Watchdog','-WrapperPid',$PID,'-StreamLogPath',$logPath -WindowStyle Hidden -PassThru` で Watchdog を起動し、戻り値のプロセスオブジェクトを `$script:WatchdogProcess` に保持する(終了確認に使う)。標準出力/標準エラーは `.claude/night_logs/watchdog-<RunStamp>-<PID>.out.log` / `.err.log` へリダイレクトする |
| 手順10(終了処理)の**先頭** | `.claude/night_watchdog.stop` を作成 → `-Mode Postmortem` 実行 → Watchdog の終了を確認(`WaitForExit`、タイムアウト時は `Stop-Process -Force`)→ フラグ削除・診断ログ転記、の順で実行 |
| `Save-NightLoopLastRun` | `.claude/night_outcomes.log` への追記を追加(`Write-LineWithRetry` を使う) |
| `Send-NightNotification` | 任意引数 `-FailureSummary`(文字列配列)を追加し、night_report に `## 検知した障害` 節として出力する |
| `Write-LineWithRetry` | 定義を `tools/lib/loop_io.ps1` へ移し、`. (Join-Path $PSScriptRoot 'lib\loop_io.ps1')` でドットソースする(同名・同シグネチャなので呼び出し側は無変更) |

### 6-2. `.claude/skills/night_loop/SKILL.md`

| 手順 | 追加内容 |
|---|---|
| 1(状況確認) | `.claude/failure_state.json` を Read する。`escalated:true` のルールがあれば、その内容を締めの night_report へ必ず転記する。`FP-05-HANG` が `escalated:true` の場合、**前回停止したタスクと同じタスクを選ばない** |
| 5(pushゲート)の直前 | 変更ファイルに `.ps1` が含まれる場合、`powershell -File tools\failure_playbook.ps1 -Mode Check` を実行し、**exit 0 でなければ push ゲートを通さない**(条件5として追加) |
| 6(締め) | night_report に `## 検知した障害` 節を書く(自動対処できたものは1行、escalate は「人がやること」へ) |
| 7(通知) | escalate があれば `PushNotification` の本文に含める |

### 6-3. その他の文書

- `docs/android_release/開発運用基盤設計.md` §7: 失敗モード表の各行から本書の FP-ID へ参照を張る(表自体は残し、詳細を本書に委ねる)
- `rules/verification.md`: 教訓インデックスに1行(「無人ループの既知障害と自動対処は `docs/failure_playbook.md` が正本」)
- `CLAUDE.md` §日次改修ループ運用ルール: 1文だけ追記(本文は本書へ委ねる)
- `.gitignore`: §2-4 の4パス

---

## 7. 実装タスクへの分解(`docs/改修マスタープラン.md` §3 トラックA へ追加)

タスクIDは既存の最大値 T5-A60 の続き。すべて `implementer` 実施可(設計判断は本書で確定済み)。

| タスクID | 概要 | 完了条件 | 依存 | サイズ |
|---|---|---|---|---|
| **T5-A61** | プレイブック基盤: `tools/lib/loop_io.ps1`(`Write-LineWithRetry` の移設)+ `tools/failure_playbook.ps1` の骨格(§2-2 の引数・§2-3 の1行JSON・終了コード・§2-5 のルール配列・§2-4 の記録層)+ `-Mode Preflight` に **FP-02 / FP-07 / FP-01(シグネチャA・B)** を実装。`night_loop.ps1` は `Write-LineWithRetry` をドットソースに置き換える | `-Mode Preflight` が1行JSONを返し `.claude/failure_events.tsv` と `.claude/failure_state.json` が生成される。BOM を意図的に落とした `.ps1` を置くと自動修復され `ParseFile` エラー0件になる。`night_loop.ps1 -DryRun` が従来どおり成功する | なし | **M** |
| **T5-A62** | FP-06: `Save-NightLoopLastRun` に `.claude/night_outcomes.log` 追記を追加、新 outcome(`error_preflight` / `error_claude_exit_unknown` / `error_watchdog_stall`)を定義、Preflight に連続判定(3回連続/72時間/5回中3件)を実装。`Send-NightNotification -FailureSummary` と night_report の `## 検知した障害` 節 | `night_outcomes.log` に同一 outcome を3行仕込むと Preflight が warn を出し、night_report に「人がやること」が入る。5行なら見出しが `# ⛔ 夜間ループが停止しています` になる | T5-A61 | **S** |
| **T5-A63** | FP-05(c): `-Mode Watchdog` の実装(30秒間隔・stall2段階・hardcap・§3 FP-05 の子孫プロセス特定手順・`night_watchdog.stop` による自己終了・ハンドル非保持)+ `night_loop.ps1` 手順9/10 への配線 | ダミーの長時間プロセスを対象に、1段目で警告のみ・2段目で対象のみ停止することを実測。対象0件のときは停止せず escalate だけになることを実測。claude 正常終了時に Watchdog が自動終了し孤児が残らないことを確認。かつ `night_loop.ps1` 終了時点で `watchdog-*` の診断ログが残っていない(=ハンドルが解放されている) | T5-A61 | **M** |
| **T5-A64** | FP-04 + 未知障害: `-Mode Postmortem` の実装(§3 FP-04 の正規表現4種、`.jsonl`/`.err.log` 走査、§5 の証拠束生成、全ルールの照合結果出力)+ `night_loop.ps1` 手順10 への配線 | 権限拒否文字列を含むダミー `.jsonl` を置くと FP-04 が escalate になり、`allow` 追加候補行が night_report に出る。どのシグネチャにも合致しない非0終了で `error_claude_exit_unknown` と証拠束が生成される | T5-A61 | **S** |
| **T5-A65** | FP-03: エミュレータの検知(シグネチャ A〜D)と復旧(`-Stop` → `Clear-StaleEmulator` → `-Start`、最大1回、`-Unattended` 時のみ、AVD は `beanbase_ui` 固定)。復旧失敗時に「Android 検証は未実施」を `failure_state.json` へ記録 | エミュレータ停止状態から Preflight を実行すると1回だけ再起動を試み、結果が `failure_events.tsv` に残る。有人モードでは再起動せず検知のみになることを確認 | T5-A61 | **S** |
| **T5-A66** | `-Mode Check` の実装 + 配線一式: `.claude/skills/night_loop/SKILL.md`(手順1・5・6・7)、`docs/android_release/開発運用基盤設計.md` §7、`rules/verification.md` インデックス、`CLAUDE.md` 1文、`.gitignore` 4パス。あわせて **T5-A53(`tools/preflight.ps1`)を本設計に統合済みとして閉じる** | `grep -n "failure_playbook" .claude/skills/night_loop/SKILL.md CLAUDE.md rules/verification.md docs/android_release/開発運用基盤設計.md` が全ファイルでヒットする。BOM を落とした `.ps1` を含む変更で `-Mode Check` が非0を返す | T5-A61〜T5-A65 | **S** |
| **T5-A67** | **⚠️ユーザー実施**(アシスタントは自分の権限設定を変更しない): `.claude/settings.night.json` の `permissions.allow` に `"PowerShell(powershell -File tools\\failure_playbook.ps1*)"` を追加する | 無人ループで `-Mode Check` が権限拒否されずに実行できる(次回発火の `failure_events.tsv` で確認) | T5-A66 | **S** |
| **T5-A68** | 障害注入テスト: 機械的に再現できる5件(FP-01 ロック保持プロセスを立てる / FP-02 BOM を落とす / FP-04 拒否文字列入りダミー `.jsonl` / FP-06 outcome ログ3行 / FP-07 PATH から `adb` を外す)を注入し、検知・対処・エスカレーションが設計どおり動くことを確認。結果を本書 §8 に追記 | 5件すべてで期待どおりの `ruleId` / `severity` / `action` / `result` が `failure_events.tsv` に記録される。テスト後に注入した状態がすべて元に戻っている | T5-A66 | **M** |

### 7-1. 実装時の必須注意(既知の地雷)

- **`.ps1` は BOM 付き UTF-8 で保存する**(L127 / L142)。新規作成・変更した `.ps1` は保存後に必ず `powershell -File <path> -Mode Preflight` 相当で1回実行し、構文エラーが出ないことを確認する。プレイブック自身が BOM 事故で壊れると検知層ごと失われる。
- **ネイティブ exe の `2>$null` / `2>&1` を使わない**(L128)。`adb` / `git` の呼び出しは `cmd /c '... 2>&1'` か個別ファイルへのリダイレクトにする。
- **外部コマンド出力の `.Trim()` は null ガードを先に置く**(L127 後半)。`adb devices` は一過性に空を返す。
- **プレイブック内の例外は必ず握りつぶす**(P1)。トップレベルを `try/catch` で包み、catch では `failure_events.tsv` に `ruleId=FP-INTERNAL` を1行書いて exit 0 する。
- `lib/` 配下の製品コードは**一切変更しない**。本タスク群は運用基盤のみ。
- **テスト用ハングフック**(T5-A90): 環境変数 `BEANBASE_FP_TEST_HANG_SEC` を設定して起動すると、モード開始直後に指定秒数 `Start-Sleep` する。`tools/acceptance/t5_a90_check.ps1` が `night_loop.ps1` 側の外側タイムアウト(`playbookPreflightTimeoutSec` 等)を実地確認するためのフォールトインジェクション専用で、未設定時は完全に無効。
- **テスト用シーム2種**(T5-A97、`night_loop.ps1`側): 環境変数 `BEANBASE_NL_TEST_LOCK_PATH` は多重起動ガードのロックファイルパスを差し替え、`BEANBASE_NL_TEST_STOP_AFTER_PREFLIGHT=1` はPreflight判定ブロック完了直後(`Save-NightLoopLastRun`を呼ばずに)終了する。いずれも`tools/acceptance/t5_a90_check.ps1`のチェック3が他プロセス(夜間ループの常駐Watchdog等)と競合せず安定して差分判定するための専用フックで、未設定時は完全に無効。

---

## 8. 検証観点

### 8-1. 「効いた」と言える判定条件

1. 注入した5件の既知障害が、**人手を介さず** `failure_events.tsv` に正しい `ruleId` で記録される
2. `auto` のもの(FP-02、FP-03、FP-07 の agy 不在)が**実際に解消**され、後続処理が続行する
3. `warn` / `escalate` のもの(FP-01 の kill、FP-04、FP-06)が**自動実行されず**、`night_report.md` の「人がやること」に具体的な操作が1行で書かれる
4. どのシグネチャにも合致しない障害で、証拠束が §5 のフォーマットで生成され、**照合結果に全ルールが列挙**される
5. プレイブックを意図的に壊した状態(例: ルール配列に例外を投げるブロックを置く)でも、**夜間ループが従来どおり完走する**(P1 の確認)

### 8-2. 回帰で押さえるケース

| ケース | 期待 |
|---|---|
| 障害が1件も無い通常の夜間ループ | `failure_events.tsv` に行が増えない(または `result=ok` のみ)、所要時間の増加が **30秒以内** |
| `-DryRun` 実行 | Preflight は動くが Watchdog は起動しない。`night_outcomes.log` に追記しない(既存の DryRun 方針と揃える) |
| 有人試走(`-Force`、`-Unattended` なし) | FP-03 の再起動と FP-05(c) の停止が**行われない** |
| `.claude/failure_state.json` が壊れている / 存在しない | 例外にせず新規作成して続行する |
| Watchdog 起動中に claude が正常終了 | Watchdog が60秒以内に自ら終了し、プロセスが残らない(**孤児化させないこと自体が FP-01 の予防**) |
| ロック中のファイルへ書けない状態 | 切替先ファイルに全ログが残り、`night_report.md` が更新される |

### 8-3. 既知のリスクと緩和

| リスク | 緩和 |
|---|---|
| Watchdog が停止フラグに応答せず強制終了された場合、Watchdog 自身の JSON 出力・証拠束が失われる | wrapper.log に強制終了の WARN を残す。強制終了自体が異常の兆候なので、この行が出たら人が `failure_events.tsv` を確認する |
| 検知層(Detect)自身が無期限ブロックすると、fail-openのtry/catchでは救えずループ全体が停止する | 上限を3層で担保する: (1)外部呼び出しごとのタイムアウト (2)Detect累積予算(detectBudgetSec) (3)night_loop.ps1側の子プロセス上限(playbookPreflightTimeoutSec、超過時はプロセスツリーごとkillして続行)。Watchdog(FP-05(c))はclaude起動後にしか動かないため、Preflightフェーズは(3)が唯一の保険である |

---

## 9. 残った不明点・判断待ち

| # | 内容 | 扱い |
|---|---|---|
| 1 | **FP-05(c) は未観測の仮説**。claude 本体が無応答になる事象は本プロジェクトでまだ確認されていない | しきい値(20分/40分/90分)は暫定。T5-A63 実装後、実際の正常系ループの所要時間(`night_outcomes.log` の記録)を3回分見てから調整する |
| 2 | `-Unattended` の判定を誰が持つか | 本設計では**呼び出し元(`night_loop.ps1`)が `$env:BEANBASE_NIGHT_LOOP` を見て渡す**。プレイブック側では環境変数を直接読まない(有人試走で誤判定しないため) |
| 3 | FP-01 のシグネチャ C(孤児プロセス列挙)は `Win32_Process` の `CommandLine` 取得に権限が要る場合がある | 取得できなければ「容疑者不明」として記録するだけにする(fail-open)。T5-A61 実装時に実測して本書へ追記する |
| 4 | `autoKillLockHolders` を将来 true にするか | **当面 false 固定**。3日連続でフォールバックログが出る事態が実際に繰り返された場合のみ再検討する |
| 5 | T5-A53(`tools/preflight.ps1`)の統合はユーザー承認が要るか | マスタープラン上の別タスクを閉じる判断のため、T5-A66 実施時にユーザーへ一言確認する(重複実装を避ける意図)。**2026-08-13、ユーザー承認済み。**統合方針(§1-3・§7 T5-A66行のとおり `preflight.ps1` は作らず `failure_playbook.ps1 -Mode Preflight` に一本化する)を正式に採用し、実際の切替配線は T5-A66 で行う |
| 6 | `tools/lib/loop_io.ps1`(T5-A61で新設、`failure_playbook.ps1`がドットソースする依存)自身がBOMを喪失した場合、FP-02-BOMルール(ドットソース後にしか動かない)では救えないことがT5-A61実装中に判明した(教訓L148) | ドットソース**直前**に`loop_io.ps1`専用の最小限BOM事前チェック・修復を単独で実行するブートストラップ処理を追加して解消済み(`tools/failure_playbook.ps1` 63〜84行目付近)。`failure_events.tsv`への正式記録はせず`[Console]::Error`への1行メッセージのみ(通常のFP-02-BOM検知・記録経路とは別扱い)。T5-A62以降で同種の「エンジンより先に読み込まれる依存」を追加する場合は同じ手当てが必要になることに注意 |
| 7 | `-StallMinutes`/`-HardCapMinutes`を§2-2表どおり`int`型で実装したところ、§8のテスト方法(「0.02分=1.2秒のような小さい値に上書きして短時間で検証」)で渡す分数分がPowerShellのパラメータバインド時に丸められ`0`になり、意図した2段階(警告→停止)の検証ができない実害がT5-A65実装中に判明した | `int`から`double`へ変更して解消(T5-A65)。既定値20/90自体は変わらず、算術・文字列展開とも互換のため他への影響はない。§2-2表を更新済み |
| 8 | FP-05(c)の証拠束(§5)の「トリガー」欄は元テンプレート例が`0410 / 無人モード`(=起動時刻+モード)だが、`night_loop.ps1`の実際の起動トリガー種別(cron/手動等)はWatchdogプロセス単体からは取得できない | Watchdog起動時刻(`HHmm`)+`-Unattended`有無から`"<HHmm> / 無人モード"`のように簡易生成する実装とした(T5-A65)。厳密なトリガー種別(`BEANBASE_NIGHT_TRIGGER`等)の反映はT5-A66の配線時に呼び出し元から渡す形で拡張可能 |
