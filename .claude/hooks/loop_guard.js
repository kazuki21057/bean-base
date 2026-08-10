#!/usr/bin/env node
/**
 * loop_guard.js — 日次改修ループのガードレール
 *
 * 役割:
 *   - 現セッションの transcript を読み、「1ループ」分のコスト(重み付け)・
 *     ターン数を算出する。
 *   - コストはトークン種別ごとの単価で重み付け合算するため /cost に近い。
 *     トークン数は transcript から誤差ゼロ。
 *   - 結果を .claude/loop_state.md に書き出す。
 *   - UserPromptSubmit 時は状態を stdout に出して文脈へ注入し、
 *     しきい値超過なら「停止して引き継ぎ書を書け」と指示する。
 *   - Stop 時はファイル更新のみ(サイレント)。
 *
 * 終了条件のしきい値は「有人ループ」「夜間ループ」でモードを分けて適用する
 * (docs/android_release/開発運用基盤設計.md §5、2026-08-08 T5-A11 で追加。
 * CLAUDE.md・改修マスタープラン §5 と一致させること):
 *   - 有人ループ(/start・/full_loop): コスト > $24 / ターン数 >= 30 /
 *     連続失敗 >= 3
 *     (2026-07-21 ユーザー指示によりコスト上限$12→$24。2026-07-25
 *     ユーザー指示によりコスト・ターン数・連続失敗の集計単位を
 *     すべて「当日累計」→「1ループ単位」に変更)。
 *   - 夜間ループ(/night_loop): コスト > $8 / ターン数 >= 40 / 連続失敗 >= 2
 *     (無人実行のため事故時の被害を早期に抑える目的で、有人より厳しい
 *     しきい値にしている)。
 *   - 「1ループ」の境界は、transcript内で最後に検出した `/start`・
 *     `/full_loop`・`/night_loop` のいずれかの呼び出し(コマンド展開後の
 *     テキストに `<command-name>/start</command-name>` 等を含む実ユーザー
 *     ターン)。cron 経由の `/loop` 再実行や tools/night_loop.ps1 経由の
 *     `/night_loop` も同じ形で展開されるため、毎回のループ起点をここで
 *     検出できる。どのコマンドで境界を検出したかによって適用モード
 *     (有人/夜間)を決める。境界が1件も見つからない場合は従来どおり
 *     当日累計にフォールバックし、モードは判別不能として安全側
 *     (しきい値が厳しい夜間)を採用する。
 *   - 連続失敗は Claude が .claude/loop_failures.txt に「<ループ識別子>
 *     <回数>」形式で記録する(識別子は loop_state.md に出力される
 *     `ループ識別子` の値をそのまま使う)。識別子が現在のループと異なれば
 *     0 扱い(=新しいループでリセット)。
 */

'use strict';

const fs = require('fs');
const path = require('path');

// --- しきい値 (モード別。境界を判別できない場合は安全側=夜間を使う) ---
const THRESHOLDS = {
  attended: {
    label: '有人',
    costLimit: 24, // USD (2026-07-21 ユーザー指示により$12から2倍に変更)
    turnLimit: 30,
    failLimit: 3,
  },
  night: {
    label: '夜間',
    costLimit: 8,
    turnLimit: 40,
    failLimit: 2,
  },
};

// --- 料金 (per 1M tokens) ---
// cache 書込 = in * 1.25 (5分TTL), cache 読込 = in * 0.1
const PRICING = {
  'claude-fable-5': { in: 10.0, out: 50.0 },
  'claude-mythos-5': { in: 10.0, out: 50.0 },
  'claude-opus-5': { in: 5.0, out: 25.0 },
  'claude-opus-4-8': { in: 5.0, out: 25.0 },
  'claude-opus-4-7': { in: 5.0, out: 25.0 },
  'claude-opus-4-6': { in: 5.0, out: 25.0 },
  'claude-sonnet-5': { in: 3.0, out: 15.0 },
  'claude-sonnet-4-6': { in: 3.0, out: 15.0 },
  'claude-haiku-4-5': { in: 1.0, out: 5.0 },
};
const DEFAULT_PRICE = { in: 10.0, out: 50.0 }; // 不明モデルは既知最高単価(Fable 5)で安全側

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch (_) {
    return '';
  }
}

function localDateStr(d) {
  // ローカルタイムの YYYY-MM-DD
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function priceFor(model) {
  if (!model) return DEFAULT_PRICE;
  if (PRICING[model]) return PRICING[model];
  // 日付サフィックス等は前方一致でフォールバック
  for (const key of Object.keys(PRICING)) {
    if (model.startsWith(key)) return PRICING[key];
  }
  return DEFAULT_PRICE;
}

function isRealUserPrompt(entry) {
  // tool_result だけの user エントリはターンに数えない
  if (entry.type !== 'user') return false;
  const content = entry.message && entry.message.content;
  if (typeof content === 'string') return content.trim().length > 0;
  if (Array.isArray(content)) {
    return content.some((b) => b && b.type === 'text');
  }
  return false;
}

function extractText(entry) {
  const content = entry.message && entry.message.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .filter((b) => b && b.type === 'text' && typeof b.text === 'string')
      .map((b) => b.text)
      .join('\n');
  }
  return '';
}

// ループ境界: 実ユーザーターンのテキストに /start・/full_loop・/night_loop の
// コマンド展開マーカーを含むもの。cron 経由の再実行(/loop)や
// tools/night_loop.ps1 経由の /night_loop も同じ形で展開されるため、毎回の
// ループ起点をここで検出できる。マッチしたコマンド名(グループ1)から
// 適用モード(有人/夜間)も判定する。
const LOOP_BOUNDARY_RE =
  /<command-name>\/(start|full_loop|night_loop)<\/command-name>/;

// コマンド名 → 適用モード('attended'=有人 / 'night'=夜間)
function modeForCommand(name) {
  return name === 'night_loop' ? 'night' : 'attended';
}

// transcript内で最後に検出したループ境界のタイムスタンプと、
// それがどのコマンドに由来する境界か(= 適用モード)を返す。
// 境界が1件も見つからなければ { ts: null, mode: null }。
function findLoopBoundary(lines) {
  let lastTs = null;
  let lastMode = null;
  for (const line of lines) {
    const s = line.trim();
    if (!s) continue;
    let obj;
    try {
      obj = JSON.parse(s);
    } catch (_) {
      continue;
    }
    if (!isRealUserPrompt(obj)) continue;
    if (!obj.timestamp) continue;
    const m = LOOP_BOUNDARY_RE.exec(extractText(obj));
    if (m) {
      lastTs = obj.timestamp;
      lastMode = modeForCommand(m[1]);
    }
  }
  return { ts: lastTs, mode: lastMode };
}

// transcript_path から「親transcript」と「配下のサブエージェントtranscript群」を
// 解決する。SubagentStop等ではサブエージェント側のtranscript_pathが渡ってくる
// 可能性があるため、どちらを渡されても同じ結果になるようにする
// (T5-A33。docs/token_optimization_design.md §9-E 参照)。
function resolveTranscriptTargets(transcriptPath) {
  const dir = path.dirname(transcriptPath);
  const base = path.basename(transcriptPath, '.jsonl');

  let mainTranscript;
  let sessionDir;
  if (path.basename(dir) === 'subagents') {
    // サブエージェントのtranscriptを渡された場合
    sessionDir = path.dirname(dir);
    mainTranscript = sessionDir + '.jsonl';
  } else {
    mainTranscript = transcriptPath;
    sessionDir = path.join(dir, base);
  }

  let subagentFiles = [];
  try {
    const subDir = path.join(sessionDir, 'subagents');
    const entries = fs.readdirSync(subDir);
    subagentFiles = entries
      .filter((f) => f.endsWith('.jsonl') && !f.endsWith('.meta.json'))
      .map((f) => path.join(subDir, f));
  } catch (_) {
    subagentFiles = [];
  }

  return { mainTranscript, subagentFiles };
}

// 1ファイル分のコスト・モデル別トークンをスコープ内で集計する
// (mainTranscript・サブエージェントtranscriptの双方に同じロジックを適用するため
// analyze() から切り出した)。
function accumulateCostFromFile(filePath, today, loopBoundaryTs, perModelTokens) {
  let cost = 0;
  let hasUsageInScope = false;

  let lines;
  try {
    lines = fs.readFileSync(filePath, 'utf8').split('\n');
  } catch (_) {
    return { cost, hasUsageInScope };
  }

  for (const line of lines) {
    const s = line.trim();
    if (!s) continue;
    let obj;
    try {
      obj = JSON.parse(s);
    } catch (_) {
      continue;
    }

    const ts = obj.timestamp;
    const tsDate = ts ? new Date(ts) : null;
    const isToday = !!tsDate && !isNaN(tsDate) && localDateStr(tsDate) === today;

    // 「直近のループ境界(/start・/full_loop)以降」ベース。
    // 境界が1件も見つからなかった場合のみ、従来どおり「当日」にフォールバック。
    const inLoopScope = loopBoundaryTs ? !!ts && ts >= loopBoundaryTs : isToday;

    // コスト (assistant の usage)
    const msg = obj.message;
    const usage = msg && msg.usage;
    if (usage && inLoopScope) {
      hasUsageInScope = true;
      const model = msg.model;
      const p = priceFor(model);
      const inp = usage.input_tokens || 0;
      const cc = usage.cache_creation_input_tokens || 0;
      const cr = usage.cache_read_input_tokens || 0;
      const out = usage.output_tokens || 0;
      cost +=
        (inp * p.in + cc * p.in * 1.25 + cr * p.in * 0.1 + out * p.out) / 1e6;

      const key = model || 'unknown';
      const t = perModelTokens[key] || { in: 0, cc: 0, cr: 0, out: 0 };
      t.in += inp;
      t.cc += cc;
      t.cr += cr;
      t.out += out;
      perModelTokens[key] = t;
    }
  }

  return { cost, hasUsageInScope };
}

function analyze(mainTranscript, subagentFiles, today, loopBoundaryTs) {
  let turns = 0;
  const perModelTokens = {};

  // ターン数(実ユーザープロンプト)は mainTranscript のみで数える
  // (サブエージェントへの指示プロンプトをユーザーターンに数えないため)。
  let lines;
  try {
    lines = fs.readFileSync(mainTranscript, 'utf8').split('\n');
  } catch (_) {
    return { cost: 0, subCost: 0, subAgentCount: 0, turns, perModelTokens, ok: false };
  }

  for (const line of lines) {
    const s = line.trim();
    if (!s) continue;
    let obj;
    try {
      obj = JSON.parse(s);
    } catch (_) {
      continue;
    }

    const ts = obj.timestamp;
    const tsDate = ts ? new Date(ts) : null;
    const isToday = !!tsDate && !isNaN(tsDate) && localDateStr(tsDate) === today;
    const inLoopScope = loopBoundaryTs ? !!ts && ts >= loopBoundaryTs : isToday;

    if (inLoopScope && isRealUserPrompt(obj)) turns += 1;
  }

  // コストとモデル別トークンは mainTranscript + subagentFiles 全部を合算する。
  const mainResult = accumulateCostFromFile(mainTranscript, today, loopBoundaryTs, perModelTokens);
  let subCost = 0;
  let subAgentCount = 0;
  for (const f of subagentFiles) {
    const r = accumulateCostFromFile(f, today, loopBoundaryTs, perModelTokens);
    subCost += r.cost;
    if (r.hasUsageInScope) subAgentCount += 1;
  }

  const cost = mainResult.cost + subCost;

  return { cost, subCost, subAgentCount, turns, perModelTokens, ok: true };
}

// .claude/loop_boundary.txt: 直近のループ境界を永続化するファイル。
// UserPromptSubmit の raw テキストからスラッシュコマンドを検出できたときだけ
// 上書きし、以降の PostToolUse・SubagentStop・Stop はこのファイルを読んで
// 境界を維持する(T5-A35。行頭以外に書かれたスラッシュコマンドは Claude Code が
// 展開しないため <command-name> タグが transcript に残らず、findLoopBoundary()
// だけでは検出できないケースの救済。docs/token_optimization_design.md §9-E
// 「T5-A35」参照)。フォーマットは1行 `<ISO8601タイムスタンプ> <attended|night>`。
function loopBoundaryFilePath(projectDir) {
  return path.join(projectDir, '.claude', 'loop_boundary.txt');
}

function readLoopBoundaryFile(projectDir) {
  try {
    const raw = fs.readFileSync(loopBoundaryFilePath(projectDir), 'utf8').trim();
    if (!raw) return null;
    const parts = raw.split(/\s+/);
    if (parts.length < 2) return null;
    const [ts, mode] = parts;
    if (mode !== 'attended' && mode !== 'night') return null;
    if (isNaN(new Date(ts).getTime())) return null;
    return { ts, mode };
  } catch (_) {
    return null;
  }
}

function writeLoopBoundaryFile(projectDir, ts, mode) {
  try {
    fs.writeFileSync(loopBoundaryFilePath(projectDir), `${ts} ${mode}\n`, 'utf8');
  } catch (_) {}
}

function readFailures(projectDir, loopKey) {
  // フォーマット: "<ループ識別子> <回数>"。識別子が現在のループと異なれば 0 扱い
  // (2026-07-25〜。以前は日付キーで「日付が当日以外なら0扱い」だった)。
  // 旧フォーマット(整数のみ)は従来どおりの値として読む(後方互換)。
  try {
    const p = path.join(projectDir, '.claude', 'loop_failures.txt');
    const raw = fs.readFileSync(p, 'utf8').trim();
    const parts = raw.split(/\s+/);
    if (parts.length >= 2) {
      if (parts[0] !== loopKey) return 0;
      const n = parseInt(parts[1], 10);
      return isNaN(n) ? 0 : n;
    }
    const n = parseInt(raw, 10);
    return isNaN(n) ? 0 : n;
  } catch (_) {
    return 0;
  }
}

// .claude/agy_logs/ledger.tsv を読み、ループ境界以降の行を集計して
// loop_state.md に出す参考行(表示専用)を作る(T5-A43。
// docs/antigravity_delegation_design.md §9.6 参照)。
// コスト・ターン数のしきい値判定には一切使わない。台帳が無い・壊れている
// 場合は try/catch で握りつぶし null を返す(既存の writeFileSync 等と同じ流儀)。
function readAgyLedgerSummary(projectDir, today, loopBoundaryTs) {
  try {
    const p = path.join(projectDir, '.claude', 'agy_logs', 'ledger.tsv');
    const lines = fs
      .readFileSync(p, 'utf8')
      .split('\n')
      .map((l) => l.trim())
      .filter((l) => l.length > 0);
    if (lines.length < 2) return null; // ヘッダのみ・空

    const header = lines[0].split('\t');
    const idx = {
      timestamp: header.indexOf('timestamp'),
      exit_code: header.indexOf('exit_code'),
      duration_sec: header.indexOf('duration_sec'),
      quota_5h_pct: header.indexOf('quota_5h_pct'),
    };
    if (
      idx.timestamp < 0 ||
      idx.exit_code < 0 ||
      idx.duration_sec < 0 ||
      idx.quota_5h_pct < 0
    ) {
      return null;
    }

    let count = 0;
    let success = 0;
    let fallback = 0;
    let totalSec = 0;
    let latestTs = null;
    let latestQuota = null;

    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i].split('\t');
      const ts = cols[idx.timestamp];
      if (!ts) continue;
      const tsDate = new Date(ts);
      if (isNaN(tsDate)) continue;
      const isTodayRow = localDateStr(tsDate) === today;
      const inScope = loopBoundaryTs ? ts >= loopBoundaryTs : isTodayRow;
      if (!inScope) continue;

      count += 1;
      const exitCode = parseInt(cols[idx.exit_code], 10);
      if (exitCode === 0) success += 1;
      else fallback += 1;

      const dur = parseFloat(cols[idx.duration_sec]);
      if (!isNaN(dur)) totalSec += dur;

      if (!latestTs || ts > latestTs) {
        latestTs = ts;
        latestQuota = cols[idx.quota_5h_pct];
      }
    }

    if (count === 0) return null;
    return { count, success, fallback, totalSec, quotaPct: latestQuota };
  } catch (_) {
    return null;
  }
}

function main() {
  const raw = readStdin();
  let input = {};
  try {
    input = JSON.parse(raw);
  } catch (_) {}

  const event = input.hook_event_name || '';
  const transcriptPath = input.transcript_path || '';
  const cwd = input.cwd || process.cwd();
  const today = localDateStr(new Date());
  const nowIso = new Date().toISOString();

  const { mainTranscript, subagentFiles } = resolveTranscriptTargets(transcriptPath);

  let loopBoundaryTs = null;
  let loopBoundaryMode = null;
  try {
    const boundary = findLoopBoundary(
      fs.readFileSync(mainTranscript, 'utf8').split('\n')
    );
    loopBoundaryTs = boundary.ts;
    loopBoundaryMode = boundary.mode;
  } catch (_) {}

  // UserPromptSubmit は「今まさに送信された」プロンプトに対して発火するため、
  // このプロンプト自体が transcript にまだ書き込まれていないことがある
  // (findLoopBoundary は1ターン遅れて検出することになり、/start・/full_loop・
  // /night_loop 直後のチェックが前ループの累計コストを誤って引き継いでしまう)。
  // 標準ペイロードの `prompt` フィールドを直接チェックする初版の修正は実地では
  // 効果が無かった(フィールド名・格納形式が想定と異なっていた可能性があり、
  // 2026-07-25の次ループでも前ループの高額コストをそのまま引き継いだ)。
  // そのため JSON パース後の特定フィールドに依存せず、stdin の生テキスト全体
  // (`raw`)に境界コマンドの文字列が含まれるかを直接チェックする方式に変更した
  // (フィールド名の実際の仕様が不明でも確実に拾える、最も頑健な検出方法)。
  // 複数マッチしうる場合に備え、最後に出現したコマンドをモード判定に使う。
  // この対処は UserPromptSubmit 専用。PostToolUse・SubagentStop 等では stdin に
  // サブエージェント指示プロンプトやレポート本文、SKILL.md のようなファイルパスが
  // 含まれ、そこに偶然 "/full_loop" 等の部分文字列が現れるとループ境界が
  // 「今この瞬間」に誤って再設定され、それより前の usage エントリが軒並み
  // スコープ外になってコストが常に $0 になるバグが T5-A34 で発見された。
  //
  // さらに、行頭以外に書かれたスラッシュコマンド(例: 「82% /full_loop」)は
  // Claude Code が展開しないため <command-name> タグが transcript に残らず、
  // findLoopBoundary() は UserPromptSubmit の1ターン後もその境界を検出できない
  // (T5-A34 完了時に実測確認)。これを解消するため、UserPromptSubmit で raw から
  // 検出した境界を .claude/loop_boundary.txt に永続化し、以降のイベントでは
  // その内容と findLoopBoundary() の結果を突き合わせて使う(T5-A35。
  // docs/token_optimization_design.md §9-E「T5-A35」参照)。境界の確定順序:
  //   1. UserPromptSubmit の raw に境界コマンドがあれば「今」を新しい境界とし、
  //      .claude/loop_boundary.txt を上書きする(=新しいループの開始)。
  //   2. それ以外は、transcript から検出した境界(findLoopBoundary() の結果、
  //      上のブロックで loopBoundaryTs/loopBoundaryMode に格納済み)と
  //      .claude/loop_boundary.txt の内容を突き合わせ、タイムスタンプが新しい方を
  //      採用する(片方しか無ければそれを使う)。
  //   3. どちらも無ければ現行どおり当日累計フォールバック+モード night。
  // 全体を try/catch で囲み、失敗時は transcript 由来の値(または null)へ
  // フォールバックする(フックを絶対に落とさない)。
  try {
    let boundaryReset = false;
    if (event === 'UserPromptSubmit') {
      const rawBoundaryMatches = [...raw.matchAll(/\/(start|full_loop|night_loop)\b/g)];
      if (rawBoundaryMatches.length > 0) {
        loopBoundaryTs = nowIso;
        loopBoundaryMode = modeForCommand(
          rawBoundaryMatches[rawBoundaryMatches.length - 1][1]
        );
        boundaryReset = true;
        writeLoopBoundaryFile(cwd, loopBoundaryTs, loopBoundaryMode);
      }
    }
    if (!boundaryReset) {
      const persisted = readLoopBoundaryFile(cwd);
      if (persisted && (!loopBoundaryTs || persisted.ts > loopBoundaryTs)) {
        loopBoundaryTs = persisted.ts;
        loopBoundaryMode = persisted.mode;
      }
    }
  } catch (_) {}

  const agySummary = readAgyLedgerSummary(cwd, today, loopBoundaryTs);

  const { cost, subCost, subAgentCount, turns, perModelTokens, ok } = analyze(
    mainTranscript,
    subagentFiles,
    today,
    loopBoundaryTs
  );
  const mainCost = cost - subCost;

  // ループ識別子: 境界タイムスタンプがあればそれ、無ければ当日日付に
  // "today:" を付けたもの(タイムスタンプ形式と衝突しないようにする)。
  // loop_failures.txt はこのキーと完全一致した場合のみ既存カウントを引き継ぐ。
  const loopKey = loopBoundaryTs || `today:${today}`;
  const failures = readFailures(cwd, loopKey);

  // 適用モード: 境界を検出できていれば由来コマンドから決まるモード、
  // 判別できない(境界未検出)場合は安全側(夜間・しきい値が厳しい方)を使う。
  const mode = loopBoundaryMode || 'night';
  const th = THRESHOLDS[mode];

  const costHit = cost > th.costLimit;
  const turnHit = turns >= th.turnLimit;
  const failHit = failures >= th.failLimit;
  const stop = costHit || turnHit || failHit;

  const scopeLabel = loopBoundaryTs ? '本ループ' : '当日(境界未検出のフォールバック)';

  // --- loop_state.md 書き出し ---
  const reasons = [];
  if (costHit) reasons.push(`コスト超過 (${scopeLabel} $${cost.toFixed(3)} > $${th.costLimit})`);
  if (turnHit) reasons.push(`ターン上限 (${scopeLabel} ${turns} >= ${th.turnLimit})`);
  if (failHit) reasons.push(`連続失敗 (${failures} >= ${th.failLimit})`);

  let breakdown = '';
  for (const [m, t] of Object.entries(perModelTokens)) {
    breakdown += `  - ${m}: in=${t.in} cacheW=${t.cc} cacheR=${t.cr} out=${t.out}\n`;
  }

  const state =
    `# loop_state (自動生成 / loop_guard.js)\n\n` +
    `- 日付: ${today}\n` +
    `- 適用モード: ${th.label}ループ` +
    `${loopBoundaryMode ? '' : '(境界未検出のため安全側フォールバック)'}` +
    ` — コスト上限 $${th.costLimit} / ターン上限 ${th.turnLimit} / 連続失敗上限 ${th.failLimit}\n` +
    `- ループ識別子(loop_failures.txt 記録用キー): ${loopKey}\n` +
    `- ${scopeLabel}のコスト(重み付け概算): $${cost.toFixed(4)} / 上限 $${th.costLimit}\n` +
    `- 内訳: 親セッション $${mainCost.toFixed(4)} / サブエージェント $${subCost.toFixed(4)} (${subAgentCount}体)\n` +
    `- ${scopeLabel}のターン数: ${turns} / 上限 ${th.turnLimit}\n` +
    `- 連続失敗: ${failures} / 上限 ${th.failLimit}\n` +
    `- 停止条件: ${stop ? '🛑 到達 — ' + reasons.join(', ') : '✅ 余裕あり'}\n` +
    `- transcript読込: ${ok ? 'OK' : '失敗(空集計)'}\n` +
    (agySummary
      ? `- agy委譲(枠外・参考): ${agySummary.count}件 / 成功${agySummary.success}・` +
        `フォールバック${agySummary.fallback} / 合計 ${Math.round(agySummary.totalSec)}秒 / ` +
        `Gemini 5時間残 ${
          agySummary.quotaPct !== null &&
          agySummary.quotaPct !== undefined &&
          agySummary.quotaPct !== ''
            ? agySummary.quotaPct + '%'
            : '不明'
        }\n`
      : '') +
    `\n` +
    `## モデル別トークン(${scopeLabel})\n${breakdown || '  (なし)\n'}` +
    `\n_更新: ${new Date().toISOString()} (${event})_\n`;

  try {
    fs.writeFileSync(path.join(cwd, '.claude', 'loop_state.md'), state, 'utf8');
  } catch (_) {}

  // --- UserPromptSubmit のみ文脈へ注入 ---
  if (event === 'UserPromptSubmit') {
    let out =
      `[loop_guard] ${scopeLabel}(${th.label}モード) cost=$${cost.toFixed(3)}/$${th.costLimit}, ` +
      `turns=${turns}/${th.turnLimit}, fails=${failures}/${th.failLimit}.` +
      ` sub=$${subCost.toFixed(3)}(${subAgentCount}体)`;
    if (stop) {
      out +=
        `\n🛑 終了条件に到達しました (${reasons.join(', ')})。` +
        `\nこれ以上の新規改修は行わず、NEXT_SESSION.md に引き継ぎ書を更新し、` +
        `docs/改修マスタープランの進捗表を更新してから本日の作業を終了してください。`;
    }
    process.stdout.write(out + '\n');
  }

  process.exit(0);
}

main();
