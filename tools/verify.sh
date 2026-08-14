#!/usr/bin/env bash
# tools/verify.sh
#
# 決定論的な検証項目(analyze/test/build等)をまとめて実行し、結果を JSON 1つで
# 標準出力へ返す。検証エージェント(verifier)が `flutter analyze`/`flutter test` の
# 生出力(1回7k〜13k文字、以後の全リクエストに課金され続ける)を直接読まずに済むよう
# にすることが目的。詳細ログは .claude/verify_logs/<timestamp>_<項目名>.log へ書く。
#
# 使い方: bash tools/verify.sh [--edition personal|public]
#
# 仕様の正本: docs/android_release/検証強化設計.md §3-2
# 対応する Windows 用スクリプト: tools/verify.ps1(同一ロジック)

set -uo pipefail

# --- jq 依存チェック --------------------------------------------------------
# jq が無い環境(Windows Git Bash 標準)では、jq を呼ぶ箇所が全て失敗し標準出力が
# 完全に空になる(「JSON 1つを標準出力へ返す」契約が壊れる)。ここで先に検出し、
# 手書きの単一JSONを出して非ゼロ終了する。Windows では tools/verify.ps1 を使う。
if ! command -v jq >/dev/null 2>&1; then
  echo '{"ok":false,"error":"jq_not_found","message":"jq が見つかりません。Windows では tools/verify.ps1 を使うか、jq をインストールしてください。"}'
  exit 1
fi

# --- 引数解析 -----------------------------------------------------------
EDITION="public"
TASK=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --edition)
      EDITION="${2:-public}"
      shift 2
      ;;
    --task)
      TASK="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# 注: 現時点では lib/main_public.dart(公開版エントリポイント、E-1未着手)が
# 存在しないため、edition による分岐は build_apk_release のフォールバック処理
# (main_public.dart有無の確認)以外に無い。将来 main_public.dart 追加時に拡張する。
echo "[verify.sh] edition=${EDITION}" >&2

# --- 準備 -----------------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT" || exit 1

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR=".claude/verify_logs"
mkdir -p "$LOG_DIR"

log_path() {
  echo "${LOG_DIR}/${TIMESTAMP}_$1.log"
}

# コミット前の全変更ファイル(追跡ファイルの差分 + 新規未追跡ファイル)
mapfile -t CHANGED_FILES < <(
  { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } \
    | sort -u
)

# --- 各検査項目 -------------------------------------------------------------

# 1. analyze: 既存issue件数(.claude/analyze_baseline.txt、BOM付きの可能性あり)と比較
run_analyze() {
  local log
  log="$(log_path analyze)"
  flutter analyze >"$log" 2>&1

  local baseline current
  baseline=$(tr -cd '0-9' <.claude/analyze_baseline.txt)
  baseline=${baseline:-0}

  if grep -qE "No issues found" "$log"; then
    current=0
  else
    current=$(grep -oE '[0-9]+ issues found' "$log" | tail -1 | grep -oE '^[0-9]+')
    current=${current:-0}
  fi

  local ok=true
  if [[ "$current" -gt "$baseline" ]]; then
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    jq -n --argjson baseline "$baseline" --argjson current "$current" \
      '{ok: true, baseline: $baseline, current: $current}'
  else
    jq -n --argjson baseline "$baseline" --argjson current "$current" --arg log "$log" \
      '{ok: false, baseline: $baseline, current: $current, log: $log}'
  fi
}

# 2. test: 全パスを確認
run_test() {
  local log
  log="$(log_path test)"
  flutter test >"$log" 2>&1
  local rc=$?

  local last_line passed failed
  last_line=$(grep -oE '\+[0-9]+( -[0-9]+)?:' "$log" | tail -1)
  passed=$(echo "$last_line" | grep -oE '^\+[0-9]+' | tr -d '+')
  failed=$(echo "$last_line" | grep -oE ' -[0-9]+' | tr -d ' -')
  passed=${passed:-0}
  failed=${failed:-0}

  local ok=true
  if [[ "$rc" -ne 0 || "$failed" -ne 0 ]]; then
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    jq -n --argjson passed "$passed" --argjson failed "$failed" \
      '{ok: true, passed: $passed, failed: $failed}'
  else
    jq -n --argjson passed "$passed" --argjson failed "$failed" --arg log "$log" \
      '{ok: false, passed: $passed, failed: $failed, log: $log}'
  fi
}

# 3. test_coverage_delta: 変更したlib/ファイルに対応するテストファイルの有無(warningのみ、failにしない)
run_coverage_delta() {
  local missing=()
  local f base
  for f in "${CHANGED_FILES[@]}"; do
    [[ "$f" == lib/*.dart ]] || continue
    [[ "$f" == *.g.dart ]] && continue
    [[ -f "$f" ]] || continue
    base="$(basename "$f" .dart)"
    if ! find test -type f -name "${base}_test.dart" 2>/dev/null | grep -q .; then
      missing+=("$f")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo '{"ok": true}'
  else
    local msg=""
    local m
    for m in "${missing[@]}"; do
      msg="${msg}${m} に対応テストなし; "
    done
    msg="${msg%; }"
    jq -n --arg w "$msg" '{ok: true, warning: $w}'
  fi
}

# Android SDK が検出できるかどうかを判定する。
# ANDROID_HOME/ANDROID_SDK_ROOT が実在ディレクトリを指していれば有りとみなす。
# どちらも無ければ flutter doctor の出力で判定する(明示的な未検出メッセージが
# あれば無し、Android toolchain にチェックが付いていれば有り、それ以外は安全側で無し扱い)。
android_sdk_available() {
  if [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME}" ]]; then
    return 0
  fi
  if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT}" ]]; then
    return 0
  fi
  local doctor_out
  doctor_out=$(flutter doctor 2>/dev/null)
  if echo "$doctor_out" | grep -q "Unable to locate Android SDK"; then
    return 1
  fi
  if echo "$doctor_out" | grep -qE '\[✓\] Android toolchain'; then
    return 0
  fi
  return 1
}

# 4. build_apk_release: lib/main_public.dart 未作成、または Android SDK 未検出の場合は
#    「環境・前提が未整備」としてスキップ扱い(ok:true, skipped:true, note)にする。
#    黙って通さないよう skipped/note を必ず含める。それ以外の理由での失敗は従来どおり fail。
run_build_apk_release() {
  local target="lib/main_public.dart"
  if [[ ! -f "$target" ]]; then
    echo '{"ok": true, "skipped": true, "note": "lib/main_public.dart 未作成のためスキップ"}'
    return
  fi

  if ! android_sdk_available; then
    echo '{"ok": true, "skipped": true, "note": "Android SDK 未検出のためスキップ"}'
    return
  fi

  local log
  log="$(log_path build_apk_release)"
  flutter build apk --release -t "$target" >"$log" 2>&1
  local rc=$?

  if [[ $rc -eq 0 ]]; then
    echo '{"ok": true}'
  else
    local summary
    summary=$(grep -iE "error|FAILURE|Exception" "$log" | tail -5 | tr '\n' ' ')
    jq -n --arg summary "$summary" --arg log "$log" \
      '{ok: false, summary: $summary, log: $log}'
  fi
}

# 5. build_web_release
run_build_web_release() {
  local log
  log="$(log_path build_web_release)"
  flutter build web --release >"$log" 2>&1
  local rc=$?

  if [[ $rc -eq 0 ]]; then
    echo '{"ok": true}'
  else
    local summary
    summary=$(grep -iE "error|FAILURE|Exception" "$log" | tail -5 | tr '\n' ' ')
    jq -n --arg summary "$summary" --arg log "$log" \
      '{ok: false, summary: $summary, log: $log}'
  fi
}

# 6. golden: goldenテストが0件なら差分ゼロ扱い(T5-A8未着手のため)
run_golden() {
  local golden_files
  golden_files=$(grep -rlE "matchesGoldenFile\(" test 2>/dev/null || true)

  if [[ -z "$golden_files" ]]; then
    echo '{"ok": true, "diff_count": 0}'
    return
  fi

  local log
  log="$(log_path golden)"
  # shellcheck disable=SC2086
  flutter test $golden_files >"$log" 2>&1
  local rc=$?

  local last_line diff_count
  last_line=$(grep -oE '\+[0-9]+( -[0-9]+)?:' "$log" | tail -1)
  diff_count=$(echo "$last_line" | grep -oE ' -[0-9]+' | tr -d ' -')
  diff_count=${diff_count:-0}

  local ok=true
  if [[ $rc -ne 0 || "$diff_count" -ne 0 ]]; then
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    jq -n --argjson diff_count "$diff_count" '{ok: true, diff_count: $diff_count}'
  else
    jq -n --argjson diff_count "$diff_count" --arg log "$log" \
      '{ok: false, diff_count: $diff_count, log: $log}'
  fi
}

# 7. codegen_clean: build_runner再生成後にlib/**/*.g.dartへ差分が出ないか。
#    git checkout等は使わず、生成物(*.g.dart)だけをバックアップ→復元することで、
#    作業ツリー上の他の未コミット変更(WIP)を一切壊さずに済ませる。
run_codegen_clean() {
  local log
  log="$(log_path codegen_clean)"
  local diff_log="${log%.log}_diff.log"
  : >"$diff_log"

  local backup_dir
  backup_dir="$(mktemp -d)"

  mapfile -t gen_files_before < <(find lib -name "*.g.dart" | sort)
  local f
  for f in "${gen_files_before[@]}"; do
    mkdir -p "$backup_dir/$(dirname "$f")"
    cp "$f" "$backup_dir/$f"
  done

  # build_runner 2.15.1 で --delete-conflicting-outputs は廃止(指定すると警告して無視)。
  # また、clean を挟まないとインクリメンタルビルドが .g.dart の手編集ドリフトを検出しない。
  # --force-jit: path_provider_foundation→objective_c の build hook により
  #              Dart 3.10 系では builders の AOT コンパイルが失敗するため JIT を強制する。
  # timeout: 依存バージョン不整合時にアナライザが復帰不能な再帰に入る事故への保険
  #          (rules/lessons_archive.md L116)。実測の全再生成時間は約40秒。
  timeout -k 10s 120s dart run build_runner clean >"$log" 2>&1
  timeout -k 10s 600s dart run build_runner build --force-jit >>"$log" 2>&1
  local build_rc=$?

  mapfile -t gen_files_after < <(find lib -name "*.g.dart" | sort)

  local diff_found=false
  for f in "${gen_files_before[@]}"; do
    if [[ ! -f "$f" ]]; then
      diff_found=true
      echo "[削除] $f" >>"$diff_log"
    # 改行コード(CRLF/LF)だけの差分は「意味的な差分なし」として無視する。
    # このリポジトリは core.autocrlf=true で作業ツリー上の *.g.dart は CRLF、
    # build_runner の再生成物は LF で出力されるため、生バイト比較(cmp)だと
    # 中身が同一でも常に「差分あり」と誤検知する。
    elif ! diff -q <(tr -d '\r' <"$backup_dir/$f") <(tr -d '\r' <"$f") >/dev/null; then
      diff_found=true
      echo "[変更] $f" >>"$diff_log"
      diff -u <(tr -d '\r' <"$backup_dir/$f") <(tr -d '\r' <"$f") >>"$diff_log" 2>&1 || true
    fi
  done
  for f in "${gen_files_after[@]}"; do
    if [[ ! -f "$backup_dir/$f" ]]; then
      diff_found=true
      echo "[新規] $f" >>"$diff_log"
    fi
  done

  # 復元: build_runner実行前の状態へ厳密に戻す
  for f in "${gen_files_after[@]}"; do
    if [[ ! -f "$backup_dir/$f" ]]; then
      rm -f "$f"
    fi
  done
  for f in "${gen_files_before[@]}"; do
    mkdir -p "$(dirname "$f")"
    cp "$backup_dir/$f" "$f"
  done
  rm -rf "$backup_dir"

  local ok=true
  local timed_out=false
  if [[ $build_rc -eq 124 || $build_rc -eq 137 ]]; then
    ok=false
    timed_out=true
    echo "[build_runnerタイムアウト] 600秒以内に完了しませんでした。analyzer と Dart SDK のバージョン不整合の可能性があります(rules/lessons_archive.md L116 参照)。pubspec.lock の analyzer バージョンを確認してください。" >>"$diff_log"
  elif [[ $build_rc -ne 0 ]]; then
    ok=false
    echo "[build_runner失敗] exit=$build_rc" >>"$diff_log"
  fi
  if [[ "$diff_found" == true ]]; then
    ok=false
  fi

  if [[ "$ok" == true ]]; then
    echo '{"ok": true}'
  elif [[ "$timed_out" == true ]]; then
    jq -n --arg log "$diff_log" '{ok: false, reason: "timeout", log: $log}'
  else
    jq -n --arg log "$diff_log" '{ok: false, log: $log}'
  fi
}

# 8. secret_scan: ステージ済み差分(git diff --cached)のみを対象。
#    'gemini_api_key' はSharedPreferencesのキー名として正規に多数出現するため、
#    キー名そのものではなく実際の秘密情報の"値"の形を検出する。
run_secret_scan() {
  local log
  log="$(log_path secret_scan)"
  : >"$log"

  local staged
  staged=$(git diff --cached 2>/dev/null || true)

  local hit=false

  local aiza_hits
  aiza_hits=$(echo "$staged" | grep -E '^\+[^+]' | grep -oE 'AIza[0-9A-Za-z_-]{35}' || true)
  if [[ -n "$aiza_hits" ]]; then
    hit=true
    {
      echo "[Google/Gemini APIキー形式(AIza...)を検出]"
      echo "$aiza_hits"
    } >>"$log"
  fi

  local generic_hits
  generic_hits=$(echo "$staged" | grep -E '^\+[^+]' | grep -v "gemini_api_key" | \
    grep -inE "(api[_-]?key|secret|token|password)['\"]?[[:space:]]*[:=][[:space:]]*['\"][A-Za-z0-9+/=_-]{20,}['\"]" || true)
  if [[ -n "$generic_hits" ]]; then
    hit=true
    {
      echo "[秘密情報らしきリテラル代入を検出]"
      echo "$generic_hits"
    } >>"$log"
  fi

  if [[ "$hit" == false ]]; then
    echo '{"ok": true}'
  else
    jq -n --arg log "$log" '{ok: false, log: $log}'
  fi
}

normalize_task_id() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr '-' '_'
}

pwsh_available() {
  command -v pwsh >/dev/null 2>&1
}

# 9. acceptance: タスク固有の受け入れ資産(tools/acceptance/*.ps1, test/acceptance/*.dart)を
#    毎回全件回帰実行し(ゴールデンループ)、--task 指定時はそのタスクの受け入れ資産の
#    有無・合否も判定する。仕様の正本: docs/acceptance_harness_design.md §7.2・§7.3
#    pwsh が PATH に無い環境では *.ps1 は全てskip扱いとし、acceptanceがfailにならないようにする。
run_acceptance() {
  local acceptance_dir="tools/acceptance"
  local test_acceptance_dir="test/acceptance"

  local script_files=()
  if [[ -d "$acceptance_dir" ]]; then
    while IFS= read -r -d '' f; do
      script_files+=("$f")
    done < <(find "$acceptance_dir" -maxdepth 1 -type f -name "*_check.ps1" -print0 2>/dev/null | sort -z)
  fi

  if [[ -z "$TASK" && ${#script_files[@]} -eq 0 ]]; then
    echo '{"ok": true, "skipped": true, "note": "受け入れ資産なし(タスク指定なし)"}'
    return
  fi

  local scripts_json="[]"
  local passed=0 failed=0 skipped=0
  local overall_ok=true
  local overall_reason=""
  local pwsh_ok
  if pwsh_available; then pwsh_ok=true; else pwsh_ok=false; fi

  local sf
  for sf in "${script_files[@]}"; do
    local base id log entry
    base="$(basename "$sf")"
    id="${base%.ps1}"

    if [[ "$pwsh_ok" == false ]]; then
      entry=$(jq -n --arg name "$base" '{name: $name, skipped: true, reason: "pwsh_not_found"}')
      skipped=$((skipped + 1))
      scripts_json=$(echo "$scripts_json" | jq --argjson e "$entry" '. + [$e]')
      continue
    fi

    log="$(log_path "acceptance_${id}")"
    timeout -k 5s 60s pwsh -NoProfile -ExecutionPolicy Bypass -File "$sf" >"$log" 2>&1
    local exit_code=$?
    local timed_out=false
    if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
      timed_out=true
    fi

    local json_line=""
    json_line=$(grep -E '^\s*\{' "$log" 2>/dev/null | tail -1)
    local parsed_ok="" parsed_reason="" checks_pass=0 checks_total=0
    local json_valid=false
    if [[ -n "$json_line" ]] && echo "$json_line" | jq -e . >/dev/null 2>&1; then
      json_valid=true
      parsed_ok=$(echo "$json_line" | jq -r '.ok')
      parsed_reason=$(echo "$json_line" | jq -r '.reason // ""')
      checks_total=$(echo "$json_line" | jq '[.checks[]?] | length')
      checks_pass=$(echo "$json_line" | jq '[.checks[]? | select(.ok==true)] | length')
    fi

    if [[ "$timed_out" == true ]]; then
      entry=$(jq -n --arg name "$base" --argjson exit "$exit_code" --arg log "$log" \
        '{name: $name, exit: $exit, ok: false, skipped: false, summary: "timeout", log: $log}')
      failed=$((failed + 1)); overall_ok=false
      [[ -z "$overall_reason" ]] && overall_reason="timeout"
    elif [[ $exit_code -eq 2 ]]; then
      local summary="skipped"
      [[ -n "$parsed_reason" ]] && summary="$parsed_reason"
      entry=$(jq -n --arg name "$base" --argjson exit "$exit_code" --arg summary "$summary" \
        '{name: $name, exit: $exit, ok: true, skipped: true, summary: $summary}')
      skipped=$((skipped + 1))
    elif [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
      if [[ "$json_valid" == false ]]; then
        entry=$(jq -n --arg name "$base" --argjson exit "$exit_code" --arg log "$log" \
          '{name: $name, exit: $exit, ok: false, skipped: false, summary: "json_parse_failed", log: $log}')
        failed=$((failed + 1)); overall_ok=false
        [[ -z "$overall_reason" ]] && overall_reason="json_parse_failed"
      elif [[ "$parsed_ok" == "true" ]]; then
        entry=$(jq -n --arg name "$base" --argjson exit "$exit_code" --arg summary "${checks_pass}/${checks_total} pass" \
          '{name: $name, exit: $exit, ok: true, skipped: false, summary: $summary}')
        passed=$((passed + 1))
      else
        entry=$(jq -n --arg name "$base" --argjson exit "$exit_code" --arg summary "${checks_pass}/${checks_total} pass" --arg log "$log" \
          '{name: $name, exit: $exit, ok: false, skipped: false, summary: $summary, log: $log}')
        failed=$((failed + 1)); overall_ok=false
        [[ -z "$overall_reason" ]] && overall_reason="script_failed"
      fi
    else
      entry=$(jq -n --arg name "$base" --argjson exit "$exit_code" --arg log "$log" \
        '{name: $name, exit: $exit, ok: false, skipped: false, summary: ("script_error(exit=" + ($exit | tostring) + ")"), log: $log}')
      failed=$((failed + 1)); overall_ok=false
      [[ -z "$overall_reason" ]] && overall_reason="script_error"
    fi

    scripts_json=$(echo "$scripts_json" | jq --argjson e "$entry" '. + [$e]')
  done

  local dart_json="null"
  local required=false

  if [[ -n "$TASK" ]]; then
    required=true
    local normalized script_asset dart_asset script_found=false dart_found=false group_file=""
    normalized="$(normalize_task_id "$TASK")"
    script_asset="${acceptance_dir}/${normalized}_check.ps1"
    dart_asset="${test_acceptance_dir}/${normalized}_acceptance_test.dart"
    [[ -f "$script_asset" ]] && script_found=true
    [[ -f "$dart_asset" ]] && dart_found=true

    if [[ "$dart_found" == false ]]; then
      group_file=$(grep -rlF "受け入れ(${TASK})" test 2>/dev/null | head -1 || true)
    fi

    if [[ "$script_found" == false && "$dart_found" == false && -z "$group_file" ]]; then
      dart_json='{"found": false, "path": "", "ok": false, "note": ""}'
      overall_ok=false
      overall_reason="acceptance_missing"
    elif [[ "$dart_found" == true ]]; then
      local dart_log dart_rc
      dart_log="$(log_path "acceptance_dart_${normalized}")"
      timeout -k 10s 300s flutter test "$dart_asset" >"$dart_log" 2>&1
      dart_rc=$?
      if [[ $dart_rc -eq 0 ]]; then
        dart_json=$(jq -n --arg path "$dart_asset" '{found: true, path: $path, ok: true, note: ""}')
      else
        dart_json=$(jq -n --arg path "$dart_asset" --arg log "$dart_log" \
          '{found: true, path: $path, ok: false, note: "", log: $log}')
        overall_ok=false
        [[ -z "$overall_reason" ]] && overall_reason="script_failed"
      fi
    elif [[ -n "$group_file" ]]; then
      local test_ok
      test_ok=$(echo "$RESULT_TEST" | jq -r '.ok')
      dart_json=$(jq -n --arg path "$group_file" --argjson ok "$test_ok" \
        '{found: true, path: $path, ok: $ok, note: "既存テストファイル内のgroupのため単独再実行は省略(testの結果に含まれる)"}')
      if [[ "$test_ok" != "true" ]]; then
        overall_ok=false
        [[ -z "$overall_reason" ]] && overall_reason="script_failed"
      fi
    else
      local script_ok
      script_ok=$(echo "$scripts_json" | jq --arg name "${normalized}_check.ps1" \
        '([.[] | select(.name == $name)] | .[0]) as $m | if $m == null then true else (($m.ok // false) or ($m.skipped // false)) end')
      dart_json=$(jq -n --argjson ok "$script_ok" \
        '{found: false, path: "", ok: $ok, note: "Dart受け入れ資産なし(PowerShell受け入れスクリプトで代替)"}')
    fi
  fi

  local final
  final=$(jq -n \
    --argjson ok "$overall_ok" \
    --arg task "$TASK" \
    --argjson required "$required" \
    --argjson dart "$dart_json" \
    --argjson scripts "$scripts_json" \
    --argjson passed "$passed" \
    --argjson failed "$failed" \
    --argjson skipped "$skipped" \
    '{ok: $ok, task: $task, required: $required, dart: $dart, scripts: $scripts, passed: $passed, failed: $failed, skipped: $skipped}
     | if .dart == null then del(.dart) else . end')

  if [[ "$overall_ok" != true && -n "$overall_reason" ]]; then
    final=$(echo "$final" | jq --arg r "$overall_reason" '. + {reason: $r}')
  fi

  echo "$final"
}

# --- 実行 -------------------------------------------------------------------
# 軽い検査から順に実行する(重いビルドは最後)。
RESULT_ANALYZE="$(run_analyze)"
RESULT_TEST="$(run_test)"
RESULT_COVERAGE="$(run_coverage_delta)"
RESULT_SECRET="$(run_secret_scan)"
RESULT_ACCEPTANCE="$(run_acceptance)"
RESULT_CODEGEN="$(run_codegen_clean)"
RESULT_GOLDEN="$(run_golden)"
RESULT_WEB="$(run_build_web_release)"
RESULT_APK="$(run_build_apk_release)"

jq -n \
  --argjson analyze "$RESULT_ANALYZE" \
  --argjson test "$RESULT_TEST" \
  --argjson coverage "$RESULT_COVERAGE" \
  --argjson apk "$RESULT_APK" \
  --argjson web "$RESULT_WEB" \
  --argjson golden "$RESULT_GOLDEN" \
  --argjson codegen "$RESULT_CODEGEN" \
  --argjson secret "$RESULT_SECRET" \
  --argjson acceptance "$RESULT_ACCEPTANCE" \
  '
  {
    analyze: $analyze,
    test: $test,
    test_coverage_delta: $coverage,
    build_apk_release: $apk,
    build_web_release: $web,
    golden: $golden,
    codegen_clean: $codegen,
    secret_scan: $secret,
    acceptance: $acceptance
  } as $checks
  |
  ($checks
    | [.analyze.ok, .test.ok, .build_apk_release.ok, .build_web_release.ok, .golden.ok, .codegen_clean.ok, .secret_scan.ok, .acceptance.ok]
    | all
  ) as $ok
  | {ok: $ok, checks: $checks}
  '
