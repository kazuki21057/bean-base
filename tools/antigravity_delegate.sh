#!/usr/bin/env bash
# tools/antigravity_delegate.sh
#
# Claude Codeサブエージェント(implementer/adversary/researcher)の一部を
# Google Antigravity CLI(agy、Geminiバックエンド)へヘッドレス委譲するラッパー。
# Claude Pro/Maxプランの利用枠(週次・5時間)を節約する目的で、Geminiバケット側の
# 枠が余っているタスクをagyへ逃がす。
#
# 仕様の正本: docs/antigravity_delegation_design.md §9(9.1〜9.7)。
# 対応する Windows 用スクリプト: tools/antigravity_delegate.ps1(同一引数名・同一JSONスキーマ・同一終了コード)。
# 引数名は本スクリプトのみケバブケース(--role等)、.ps1側はパスカルケース(-Role等)。
#
# 標準出力(stdout)は必ず1行JSONのみ(親が読む唯一の契約)。進捗メッセージは
# すべてstderrへ出す(tools/verify.shと同じ流儀)。
#
# 使い方:
#   bash tools/antigravity_delegate.sh --role implementer --task-file <path> \
#     [--files "a.md,b.md"] [--done-when "..."] [--task-id T5-A38] [--model gemini-3.6-flash-high] \
#     [--effort medium] [--timeout-sec 600] [--work-dir <path>] [--out-dir .claude/agy_logs] \
#     [--skip-quota-check] [--dry-run]

set -uo pipefail

progress() { echo "[antigravity_delegate.sh] $1" >&2; }

# --- jq依存チェック(tools/verify.shと同じ理由: 手書きJSONの事故を避けるため) ------------
# 判断: jq未検出は§9.4の終了コード表に対応する項目が無いため、「ラッパーが呼び出しミスで
# 動作できない」扱いとしてexit 2(引数エラーと同枠)に含めた。実運用でこの分岐に当たったら
# 環境整備(jqインストール)が必要。
if ! command -v jq >/dev/null 2>&1; then
  echo '{"ok":false,"exit_code":2,"status":"ARG_ERROR","error":"jq_not_found","fallback":false,"fallback_reason":null}'
  exit 2
fi

# --- 引数解析 -----------------------------------------------------------
ROLE=""
TASK_FILE=""
FILES=""
DONE_WHEN=""
TASK_ID=""
MODEL="gemini-3.6-flash-high"
EFFORT=""
EFFORT_SET=false
TIMEOUT_SEC=600
WORK_DIR=""
OUT_DIR=".claude/agy_logs"
SKIP_QUOTA_CHECK=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="${2:-}"; shift 2 ;;
    --task-file) TASK_FILE="${2:-}"; shift 2 ;;
    --files) FILES="${2:-}"; shift 2 ;;
    --done-when) DONE_WHEN="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --effort) EFFORT="${2:-}"; EFFORT_SET=true; shift 2 ;;
    --timeout-sec) TIMEOUT_SEC="${2:-600}"; shift 2 ;;
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-.claude/agy_logs}"; shift 2 ;;
    --skip-quota-check) SKIP_QUOTA_CHECK=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) shift ;;
  esac
done

# --- 準備 -----------------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
  echo '{"ok":false,"exit_code":2,"status":"ARG_ERROR","error":"repo_root_not_found","fallback":false,"fallback_reason":null}'
  exit 2
fi
cd "$REPO_ROOT" || exit 2

relpath() {
  local full="$1"
  local rel="${full#"$REPO_ROOT"/}"
  echo "$rel"
}

# 全終了パスがこの関数を通る(契約を1箇所に集約)。
emit_result_and_exit() {
  local ok="$1" exit_code="$2" status="$3" duration_sec="$4" response_chars="$5" \
        response_head="$6" response_log="$7" prompt_log="$8" raw_log="$9" \
        changed_files_json="${10}" quota_json="${11}" tokens_json="${12}" \
        fallback="${13}" fallback_reason="${14}" error_message="${15:-}"

  local extra_error="null"
  if [[ -n "$error_message" ]]; then
    extra_error=$(jq -n --arg e "$error_message" '$e')
  fi

  jq -n \
    --argjson ok "$ok" \
    --arg role "$ROLE" \
    --arg task_id "$TASK_ID" \
    --arg model "$MODEL" \
    --argjson exit_code "$exit_code" \
    --arg status "$status" \
    --argjson duration_sec "${duration_sec:-null}" \
    --argjson response_chars "${response_chars:-0}" \
    --arg response_head "$response_head" \
    --arg response_log "$response_log" \
    --arg prompt_log "$prompt_log" \
    --arg raw_log "$raw_log" \
    --argjson changed_files "$changed_files_json" \
    --argjson quota "$quota_json" \
    --argjson tokens "$tokens_json" \
    --argjson fallback "$fallback" \
    --arg fallback_reason "$fallback_reason" \
    --argjson error "$extra_error" \
    '{
      ok: $ok, role: $role, task_id: $task_id, model: $model, exit_code: $exit_code,
      status: $status, duration_sec: $duration_sec, response_chars: $response_chars,
      response_head: (if $response_head == "" then null else $response_head end),
      response_log: (if $response_log == "" then null else $response_log end),
      prompt_log: (if $prompt_log == "" then null else $prompt_log end),
      raw_log: (if $raw_log == "" then null else $raw_log end),
      changed_files: $changed_files,
      changed_file_count: ($changed_files | length),
      quota: $quota, tokens: $tokens, fallback: $fallback,
      fallback_reason: (if $fallback_reason == "" then null else $fallback_reason end)
    } + (if $error != null then {error: $error} else {} end)'
  exit "$exit_code"
}

# --- 引数バリデーション(exit 2) -------------------------------------------
case "$ROLE" in
  implementer|adversary|researcher) ;;
  *)
    emit_result_and_exit false 2 "ARG_ERROR" null 0 "" "" "" "" "[]" "null" "null" false "" \
      "--role は implementer/adversary/researcher のいずれかを指定してください(指定値: '$ROLE')"
    ;;
esac

if [[ -z "$TASK_FILE" ]]; then
  emit_result_and_exit false 2 "ARG_ERROR" null 0 "" "" "" "" "[]" "null" "null" false "" \
    "--task-file は必須です"
fi

TASK_FILE_RESOLVED=""
if [[ -f "$TASK_FILE" ]]; then
  TASK_FILE_RESOLVED="$(cd "$(dirname "$TASK_FILE")" && pwd)/$(basename "$TASK_FILE")"
elif [[ -f "${REPO_ROOT}/${TASK_FILE}" ]]; then
  TASK_FILE_RESOLVED="${REPO_ROOT}/${TASK_FILE}"
fi
if [[ -z "$TASK_FILE_RESOLVED" ]]; then
  emit_result_and_exit false 2 "ARG_ERROR" null 0 "" "" "" "" "[]" "null" "null" false "" \
    "--task-file が見つかりません: $TASK_FILE"
fi

if [[ -z "$WORK_DIR" ]]; then WORK_DIR="$REPO_ROOT"; fi
case "$OUT_DIR" in
  /*) OUT_DIR_FULL="$OUT_DIR" ;;
  *) OUT_DIR_FULL="${REPO_ROOT}/${OUT_DIR}" ;;
esac
mkdir -p "$OUT_DIR_FULL"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

progress "role=${ROLE} task_id=${TASK_ID} model=${MODEL} dry_run=${DRY_RUN}"

# --- 台帳(ledger.tsv)への追記 -------------------------------------------
add_ledger_row() {
  local exit_code="$1" duration_sec="$2" response_chars="$3" changed_file_count="$4" quota_5h_pct="${5:-}"
  local ledger_path="${OUT_DIR_FULL}/ledger.tsv"
  if [[ ! -f "$ledger_path" ]]; then
    printf 'timestamp\ttask_id\trole\tmodel\texit_code\tduration_sec\tresponse_chars\tchanged_file_count\tquota_5h_pct\tverdict\n' >"$ledger_path"
  fi
  # verdict(ok/ng/fallback)は起動時点では空欄。採否確定後に親が埋める(§9.2)。
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t\n' \
    "$TIMESTAMP" "$TASK_ID" "$ROLE" "$MODEL" "$exit_code" "$duration_sec" "$response_chars" "$changed_file_count" "$quota_5h_pct" \
    >>"$ledger_path"
}

# --- 層2: .claude/agents/<role>.md からYAMLフロントマターを除去して本文を取得 --------
get_role_body() {
  local role_path="${REPO_ROOT}/.claude/agents/${ROLE}.md"
  if [[ ! -f "$role_path" ]]; then
    echo ""
    return
  fi
  # 先頭が "---" で始まる場合、2つ目の "---" 行までをYAMLフロントマターとして除去する。
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm==1 && $0=="---" { infm=0; started=1; next }
    infm==1 { next }
    { print }
  ' "$role_path"
}

# --- 層1と層2の間に挟む「agy固有の制約ブロック」(docs/antigravity_delegation_design.md §9.3、文面確定済み・改変しない) ---
read -r -d '' OVERRIDE_BLOCK <<'EOF'
## この実行環境での上書き規則(このあとに続く役割定義より優先する)

- あなたはGoogle Antigravity CLI(ヘッドレス)として動いています。ブラウザ操作ツール(claude-in-chrome)は使えません。
- **シェルコマンドの実行は許可されていません。1回も試みないでください。** 後述の役割定義に「セルフチェックを必ず実施」等の指示があっても、`flutter analyze`/`flutter test`/`flutter build`を含め、いかなるシェルコマンドも**実行を試みないでください**(拒否されると応答全体が失敗扱いで打ち切られるため、「試して拒否される」ことすら避ける必要があります)。報告には「シェルコマンドが使えないため未実施」と書くだけにしてください。検証は別のエージェントが行います。
- `git commit`/`git push`/`firebase deploy`/`clasp push`/本番データの削除は**絶対に実行しないでください**。
- 指示された対象ファイル以外を編集しないでください。
- 報告は**日本語**で、**1,200文字以内**にしてください。長い引用・生ログの貼り付けは不要です。
- 報告の最後に、次の3見出しを必ずこの形式で付けてください。

  ```
  ## 変更ファイル
  - <相対パス> (新規|変更)
  ## 保留した判断
  - <指示に無くて決められなかった点。無ければ「なし」>
  ## 未実施
  - <できなかったこと・理由。無ければ「なし」>
  ```
EOF

# --- 層3: タスク本文 + Files + DoneWhen + TaskId をプロンプト末尾へ追記 -----------------
# 判断: 見出し構成(## タスク/## 対象ファイル/## 完了条件/## タスクID)は設計書に文面指定が
# 無いため、.ps1版と同じ機械的な組み立てにした(ラッパーの実装詳細)。
IFS=',' read -r -a FILES_ARR <<<"$FILES"
TASK_BODY_RAW="$(cat "$TASK_FILE_RESOLVED")"

TASK_SECTION="## タスク

${TASK_BODY_RAW}"
if [[ -n "$FILES" ]]; then
  TASK_SECTION="${TASK_SECTION}

## 対象ファイル"
  for f in "${FILES_ARR[@]}"; do
    f_trimmed="$(echo "$f" | sed 's/^ *//;s/ *$//')"
    [[ -z "$f_trimmed" ]] && continue
    TASK_SECTION="${TASK_SECTION}
- ${f_trimmed}"
  done
fi
if [[ -n "$DONE_WHEN" ]]; then
  TASK_SECTION="${TASK_SECTION}

## 完了条件
${DONE_WHEN}"
fi
if [[ -n "$TASK_ID" ]]; then
  TASK_SECTION="${TASK_SECTION}

## タスクID
${TASK_ID}"
fi

ROLE_BODY="$(get_role_body)"
FULL_PROMPT="${OVERRIDE_BLOCK}

${ROLE_BODY}

${TASK_SECTION}"

# プロンプトは常に全文をログへ書く(直接渡す/参照渡しに関わらず、監査・T5-A41比較用に残す。§9.2)。
PROMPT_LOG_PATH="${OUT_DIR_FULL}/${TIMESTAMP}_${ROLE}_prompt.md"
printf '%s' "$FULL_PROMPT" >"$PROMPT_LOG_PATH"
PROMPT_LOG_REL="$(relpath "$PROMPT_LOG_PATH")"

# 8,000文字を超える場合はファイル参照渡しに切り替える(§9.2実装上の地雷)。
# 判断: マルチバイト文字数のカウントはロケール依存(${#VAR}はUTF-8ロケールなら文字数、
# Cロケールならバイト数になりうる)。.ps1版(.NET文字列長=文字数)と厳密には一致しない
# 可能性がある点を注記する。
PROMPT_LEN=${#FULL_PROMPT}
if [[ "$PROMPT_LEN" -le 8000 ]]; then
  PROMPT_ARG="$FULL_PROMPT"
else
  PROMPT_ARG="${PROMPT_LOG_REL} を読んで、その指示に従って作業してください。"
  progress "プロンプトが8000文字を超えたため(${PROMPT_LEN}文字)、ファイル参照渡しに切り替えました: ${PROMPT_LOG_REL}"
fi

# --- DryRun: agyを起動せずプロンプトだけ組み立てて終了 -------------------------------
if [[ "$DRY_RUN" == true ]]; then
  progress "--dry-run のためagyを起動せずプロンプトのみ出力しました: ${PROMPT_LOG_REL}"
  emit_result_and_exit true 0 "DRY_RUN" 0 0 "" "" "$PROMPT_LOG_REL" "" "[]" "null" \
    '{"input":null,"output":null,"source":"unavailable"}' false ""
fi

# --- agy実行ファイルの探索(agy → agy.exe の順。両方無ければexit 10) -------------------
AGY_BIN=""
if command -v agy >/dev/null 2>&1; then
  AGY_BIN="$(command -v agy)"
elif command -v agy.exe >/dev/null 2>&1; then
  AGY_BIN="$(command -v agy.exe)"
fi
if [[ -z "$AGY_BIN" ]]; then
  progress "agy/agy.exe がPATH上に見つかりません"
  add_ledger_row 10 0 0 0
  emit_result_and_exit false 10 "AGY_NOT_FOUND" 0 0 "" "" "$PROMPT_LOG_REL" "" "[]" "null" \
    '{"input":null,"output":null,"source":"unavailable"}' true \
    "agy/agy.exeがPATH上に見つかりません。Claude側サブエージェントへ委譲してください。"
fi
progress "agy実行ファイル: ${AGY_BIN}"

# --- 外部プロセス実行の共通処理 -------------------------------------------------------
# 地雷回避: `2>&1` でstdout/stderrを合流させない(.ps1版と同じ理由の踏襲。Bashでは
# ErrorRecord化の問題は無いが、JSON応答にstderrの雑音が混ざらないよう個別ファイルへ
# リダイレクトする)。外側タイムアウトは GNU coreutils の `timeout` を使う。
run_agy() {
  local timeout_sec_outer="$1"; shift
  local stdout_file="$1"; shift
  local stderr_file="$1"; shift

  local start_ts end_ts
  start_ts=$(date +%s.%N)
  timeout -k 10s "${timeout_sec_outer}s" "$AGY_BIN" "$@" >"$stdout_file" 2>"$stderr_file"
  local rc=$?
  end_ts=$(date +%s.%N)
  DURATION_SEC=$(awk -v s="$start_ts" -v e="$end_ts" 'BEGIN{printf "%.1f", e-s}')

  TIMED_OUT=false
  if [[ $rc -eq 124 || $rc -eq 137 ]]; then
    TIMED_OUT=true
  fi
  RUN_EXIT_CODE=$rc
}

# --- クォータ事前チェック(§9.2、消費ゼロ) ---------------------------------------------
# 判断: `agy -p "/usage" --output-format json` のJSONスキーマは未確認(§9.7-1)。
# キー名を確定できないため、生テキストに対する緩い正規表現で「weekly」「5h/five hour」
# 近傍の数値を拾うベストエフォート実装とし、見つからなければnull(推測値を書かない)。
# T5-A40のWindows実地確認で生出力を確認したうえで、必要なら厳密なJSONパスに置き換える。
get_quota_pct() {
  local text="$1" pattern="$2"
  echo "$text" | grep -ioP "$pattern" | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1
}

QUOTA_JSON="null"
QUOTA_5H_PCT=""
if [[ "$SKIP_QUOTA_CHECK" != true ]]; then
  progress "クォータ事前チェック中..."
  quota_stdout="$(mktemp)"
  quota_stderr="$(mktemp)"
  run_agy 90 "$quota_stdout" "$quota_stderr" -p "/usage" --output-format json --print-timeout 1m0s
  quota_raw_log="${OUT_DIR_FULL}/${TIMESTAMP}_quota_raw.json"
  cp "$quota_stdout" "$quota_raw_log" 2>/dev/null || true
  quota_text="$(cat "$quota_stdout" 2>/dev/null || true)"

  weekly_pct=""
  five_hour_pct=""
  if command -v grep >/dev/null 2>&1 && echo test | grep -ioP 'test' >/dev/null 2>&1; then
    weekly_pct="$(get_quota_pct "$quota_text" '(?i)weekly[^0-9\-]{0,40}[0-9]+(\.[0-9]+)?')"
    five_hour_pct="$(get_quota_pct "$quota_text" '(?i)(5h|5[_ -]?hour|five[_ -]?hour)[^0-9\-]{0,40}[0-9]+(\.[0-9]+)?')"
  else
    progress "grep -P が使えないため、クォータ事前チェックの数値抽出をスキップしました"
  fi
  rm -f "$quota_stdout" "$quota_stderr"

  if [[ -n "$weekly_pct" || -n "$five_hour_pct" ]]; then
    QUOTA_JSON=$(jq -n \
      --argjson w "${weekly_pct:-null}" --argjson f "${five_hour_pct:-null}" \
      '{gemini_weekly_remaining_pct: $w, gemini_5h_remaining_pct: $f, source: "preflight"}')
  else
    QUOTA_JSON='{"gemini_weekly_remaining_pct":null,"gemini_5h_remaining_pct":null,"source":"preflight_unavailable"}'
  fi
  QUOTA_5H_PCT="$five_hour_pct"

  weekly_below=false
  five_hour_below=false
  if [[ -n "$weekly_pct" ]] && awk -v v="$weekly_pct" 'BEGIN{exit !(v<10)}'; then weekly_below=true; fi
  if [[ -n "$five_hour_pct" ]] && awk -v v="$five_hour_pct" 'BEGIN{exit !(v<10)}'; then five_hour_below=true; fi
  if [[ "$weekly_below" == true || "$five_hour_below" == true ]]; then
    progress "Geminiクォータが10%未満のため中断します"
    add_ledger_row 13 0 0 0 "$QUOTA_5H_PCT"
    emit_result_and_exit false 13 "QUOTA_INSUFFICIENT" 0 0 "" "" "$PROMPT_LOG_REL" "" "[]" "$QUOTA_JSON" \
      '{"input":null,"output":null,"source":"unavailable"}' true \
      "Geminiクォータの週次残または5時間残が10%未満です。Claude側サブエージェントへ委譲してください。"
  fi
fi

# --- モデル/エフォート/モード ---------------------------------------------------------
EFFORT_TO_PASS=""
if [[ "$EFFORT_SET" == true && -n "$EFFORT" ]]; then
  EFFORT_TO_PASS="$EFFORT"
elif [[ ! "$MODEL" =~ -(high|medium|low)$ ]]; then
  EFFORT_TO_PASS="medium"
fi

case "$ROLE" in
  implementer) MODE="accept-edits" ;;
  adversary|researcher) MODE="plan" ;;
esac

TIMEOUT_MIN=$(( TIMEOUT_SEC / 60 ))
TIMEOUT_REM_SEC=$(( TIMEOUT_SEC % 60 ))
PRINT_TIMEOUT_STR="${TIMEOUT_MIN}m${TIMEOUT_REM_SEC}s"
OUTER_TIMEOUT_SEC=$(( TIMEOUT_SEC + 60 ))

# --- 実行前のgit status(exit 17判定・changed_files算出用) ----------------------------
before_status_file="$(mktemp)"
git -C "$REPO_ROOT" status --porcelain >"$before_status_file" 2>/dev/null || true

# --- agy本体呼び出し(固定引数: --output-format json / --mode / -p。--dangerously-skip-permissions は絶対に渡さない) ---
MAIN_ARGS=(-p "$PROMPT_ARG" --output-format json --mode "$MODE" --model "$MODEL")
if [[ -n "$EFFORT_TO_PASS" ]]; then
  MAIN_ARGS+=(--effort "$EFFORT_TO_PASS")
fi
MAIN_ARGS+=(--add-dir "$WORK_DIR" --print-timeout "$PRINT_TIMEOUT_STR")

progress "agy呼び出し開始 mode=${MODE} model=${MODEL} effort=${EFFORT_TO_PASS} timeout=${PRINT_TIMEOUT_STR}"
stdout_file="$(mktemp)"
stderr_file="$(mktemp)"
run_agy "$OUTER_TIMEOUT_SEC" "$stdout_file" "$stderr_file" "${MAIN_ARGS[@]}"
progress "agy呼び出し終了 exit=${RUN_EXIT_CODE} timeout=${TIMED_OUT} duration=${DURATION_SEC}s"

RAW_LOG_PATH="${OUT_DIR_FULL}/${TIMESTAMP}_${ROLE}_raw.json"
cp "$stdout_file" "$RAW_LOG_PATH" 2>/dev/null || true
RAW_LOG_REL="$(relpath "$RAW_LOG_PATH")"
RUN_STDOUT="$(cat "$stdout_file" 2>/dev/null || true)"
RUN_STDERR="$(cat "$stderr_file" 2>/dev/null || true)"
rm -f "$stdout_file" "$stderr_file"

# --- 実行後のgit status差分からchanged_filesを機械的に求める(agyの自己申告を使わない) ---
after_status_file="$(mktemp)"
git -C "$REPO_ROOT" status --porcelain >"$after_status_file" 2>/dev/null || true

CHANGED_FILES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  path="${line:3}"
  if [[ "$path" == *" -> "* ]]; then
    path="${path##* -> }"
  fi
  path="${path%\"}"
  path="${path#\"}"
  CHANGED_FILES+=("$path")
done < <(comm -13 <(sort "$before_status_file") <(sort "$after_status_file") 2>/dev/null | sort -u)
rm -f "$before_status_file" "$after_status_file"

CHANGED_FILE_COUNT=${#CHANGED_FILES[@]}
if [[ $CHANGED_FILE_COUNT -eq 0 ]]; then
  CHANGED_FILES_JSON="[]"
else
  CHANGED_FILES_JSON="$(printf '%s\n' "${CHANGED_FILES[@]}" | jq -R . | jq -s .)"
fi

# --- 終了コード判定(§9.4) ------------------------------------------------------------
RESPONSE_TEXT=""
STATUS_TEXT=""
RESPONSE_LOG_REL=""
HAS_RESPONSE_KEY=false
PARSE_OK=false

if [[ "$TIMED_OUT" == true ]]; then
  EXIT_CODE=11
  STATUS="TIMEOUT"
  FALLBACK_REASON="agy呼び出しがタイムアウトしました(${TIMEOUT_SEC}秒+60秒の外側タイムアウトを超過)"
else
  if echo "$RUN_STDOUT" | jq -e . >/dev/null 2>&1; then
    PARSE_OK=true
    if echo "$RUN_STDOUT" | jq -e 'has("response")' >/dev/null 2>&1; then
      HAS_RESPONSE_KEY=true
    fi
  fi

  if [[ "$PARSE_OK" != true || "$HAS_RESPONSE_KEY" != true ]]; then
    EXIT_CODE=14
    STATUS="JSON_PARSE_FAILED"
    FALLBACK_REASON="agyの標準出力がJSONとして解析できない、またはresponseキーがありません"
  else
    STATUS_TEXT="$(echo "$RUN_STDOUT" | jq -r '.status // ""')"
    RESPONSE_TEXT="$(echo "$RUN_STDOUT" | jq -r '.response // ""')"

    PERMISSION_DENIED=false
    if echo "$RUN_STDERR" | grep -qF 'permission that headless mode cannot prompt for'; then
      PERMISSION_DENIED=true
    fi
    if [[ "$STATUS_TEXT" == "SUCCESS" && -z "$RESPONSE_TEXT" ]]; then
      PERMISSION_DENIED=true
    fi

    if [[ "$PERMISSION_DENIED" == true ]]; then
      EXIT_CODE=12
      STATUS="PERMISSION_DENIED"
      FALLBACK_REASON="シェルコマンド等の実行がヘッドレスで自動拒否された可能性があります(settings.jsonのpermissions.allow未整備)。ルーティング違反の疑いとして台帳に記録してください。"
    elif [[ "$RUN_EXIT_CODE" -ne 0 ]]; then
      EXIT_CODE=15
      STATUS="AGY_NONZERO_EXIT"
      FALLBACK_REASON="agyがゼロ以外の終了コード(${RUN_EXIT_CODE})を返しました"
    elif [[ "$ROLE" == "implementer" && "$CHANGED_FILE_COUNT" -eq 0 ]]; then
      EXIT_CODE=16
      STATUS="NO_CHANGES"
      FALLBACK_REASON="応答はありましたが変更ファイルが0件でした"
    elif [[ ( "$ROLE" == "adversary" || "$ROLE" == "researcher" ) && "$CHANGED_FILE_COUNT" -gt 0 ]]; then
      EXIT_CODE=17
      STATUS="READONLY_ROLE_CHANGED_FILES"
      FALLBACK_REASON="読み取り専用役(${ROLE})のはずが${CHANGED_FILE_COUNT}件のファイル変更が発生しました。自動では復元しません。"
    else
      EXIT_CODE=0
      STATUS="$STATUS_TEXT"
      FALLBACK_REASON=""
    fi
  fi
fi

# --- 応答本文のログ保存(response_head は800文字で必ず切る) -----------------------------
if [[ "$HAS_RESPONSE_KEY" == true ]]; then
  RESPONSE_LOG_PATH="${OUT_DIR_FULL}/${TIMESTAMP}_${ROLE}_response.md"
  printf '%s' "$RESPONSE_TEXT" >"$RESPONSE_LOG_PATH"
  RESPONSE_LOG_REL="$(relpath "$RESPONSE_LOG_PATH")"
fi
RESPONSE_CHARS=${#RESPONSE_TEXT}
if [[ $RESPONSE_CHARS -gt 800 ]]; then
  RESPONSE_HEAD="${RESPONSE_TEXT:0:800}"
else
  RESPONSE_HEAD="$RESPONSE_TEXT"
fi

# --- tokens: agyのJSONに使用量フィールドがあれば拾う。無ければnull(推測値を書かない、§9.2) ---
TOKENS_JSON='{"input":null,"output":null,"source":"unavailable"}'
if [[ "$PARSE_OK" == true ]]; then
  for candidate in usage tokens token_usage; do
    if echo "$RUN_STDOUT" | jq -e --arg c "$candidate" 'has($c)' >/dev/null 2>&1; then
      in_tok=$(echo "$RUN_STDOUT" | jq -r --arg c "$candidate" '.[$c].input // .[$c].input_tokens // .[$c].prompt_tokens // empty')
      out_tok=$(echo "$RUN_STDOUT" | jq -r --arg c "$candidate" '.[$c].output // .[$c].output_tokens // .[$c].completion_tokens // empty')
      if [[ -n "$in_tok" || -n "$out_tok" ]]; then
        TOKENS_JSON=$(jq -n --argjson i "${in_tok:-null}" --argjson o "${out_tok:-null}" '{input:$i, output:$o, source:"agy_json"}')
      fi
      break
    fi
  done
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  OK=true
  FALLBACK=false
else
  OK=false
  FALLBACK=true
fi

add_ledger_row "$EXIT_CODE" "$DURATION_SEC" "$RESPONSE_CHARS" "$CHANGED_FILE_COUNT" "$QUOTA_5H_PCT"

emit_result_and_exit "$OK" "$EXIT_CODE" "$STATUS" "$DURATION_SEC" "$RESPONSE_CHARS" "$RESPONSE_HEAD" \
  "$RESPONSE_LOG_REL" "$PROMPT_LOG_REL" "$RAW_LOG_REL" "$CHANGED_FILES_JSON" "$QUOTA_JSON" "$TOKENS_JSON" \
  "$FALLBACK" "$FALLBACK_REASON"
