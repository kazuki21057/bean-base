#!/usr/bin/env node
/**
 * loop_guard.js — 日次改修ループのガードレール
 *
 * 役割:
 *   - 現セッションの transcript を読み、当日分(ローカル日付)の
 *     コスト(重み付け)と「ターン数」を算出する。
 *   - コストはトークン種別ごとの単価で重み付け合算するため /cost に近い。
 *     トークン数は transcript から誤差ゼロ。
 *   - 結果を .claude/loop_state.md に書き出す。
 *   - UserPromptSubmit 時は状態を stdout に出して文脈へ注入し、
 *     しきい値超過なら「停止して引き継ぎ書を書け」と指示する。
 *   - Stop 時はファイル更新のみ(サイレント)。
 *
 * 終了条件のしきい値(CLAUDE.md・改修マスタープラン §5 と一致させること):
 *   - 当日コスト > $24 (2026-07-21 ユーザー指示により$12から2倍に変更)
 *   - 当日ターン数 >= 30
 *   - 連続失敗 >= 3 (失敗は Claude が .claude/loop_failures.txt に
 *     「<YYYY-MM-DD> <回数>」形式で記録。日付が当日以外なら 0 扱い)
 */

'use strict';

const fs = require('fs');
const path = require('path');

// --- しきい値 ---
const COST_LIMIT = 24; // USD (2026-07-21 ユーザー指示により$12から2倍に変更)
const TURN_LIMIT = 30;
const FAIL_LIMIT = 3;

// --- 料金 (per 1M tokens) ---
// cache 書込 = in * 1.25 (5分TTL), cache 読込 = in * 0.1
const PRICING = {
  'claude-fable-5': { in: 10.0, out: 50.0 },
  'claude-mythos-5': { in: 10.0, out: 50.0 },
  'claude-opus-4-8': { in: 5.0, out: 25.0 },
  'claude-opus-4-7': { in: 5.0, out: 25.0 },
  'claude-opus-4-6': { in: 5.0, out: 25.0 },
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

function analyze(transcriptPath, today) {
  let cost = 0;
  let turns = 0;
  const perModelTokens = {};

  let lines;
  try {
    lines = fs.readFileSync(transcriptPath, 'utf8').split('\n');
  } catch (_) {
    return { cost, turns, perModelTokens, ok: false };
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

    // 当日フィルタ
    const ts = obj.timestamp;
    if (ts) {
      const d = new Date(ts);
      if (!isNaN(d) && localDateStr(d) !== today) continue;
    }

    // ターン数 (当日の実ユーザープロンプト)
    if (isRealUserPrompt(obj)) turns += 1;

    // コスト (assistant の usage)
    const msg = obj.message;
    const usage = msg && msg.usage;
    if (usage) {
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

  return { cost, turns, perModelTokens, ok: true };
}

function readFailures(projectDir, today) {
  // フォーマット: "<YYYY-MM-DD> <回数>"。日付が当日以外なら 0 扱い。
  // 旧フォーマット(整数のみ)は従来どおりの値として読む(後方互換)。
  try {
    const p = path.join(projectDir, '.claude', 'loop_failures.txt');
    const raw = fs.readFileSync(p, 'utf8').trim();
    const parts = raw.split(/\s+/);
    if (parts.length >= 2) {
      if (parts[0] !== today) return 0;
      const n = parseInt(parts[1], 10);
      return isNaN(n) ? 0 : n;
    }
    const n = parseInt(raw, 10);
    return isNaN(n) ? 0 : n;
  } catch (_) {
    return 0;
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

  const { cost, turns, perModelTokens, ok } = analyze(transcriptPath, today);
  const failures = readFailures(cwd, today);

  const costHit = cost > COST_LIMIT;
  const turnHit = turns >= TURN_LIMIT;
  const failHit = failures >= FAIL_LIMIT;
  const stop = costHit || turnHit || failHit;

  // --- loop_state.md 書き出し ---
  const reasons = [];
  if (costHit) reasons.push(`コスト超過 ($${cost.toFixed(3)} > $${COST_LIMIT})`);
  if (turnHit) reasons.push(`ターン上限 (${turns} >= ${TURN_LIMIT})`);
  if (failHit) reasons.push(`連続失敗 (${failures} >= ${FAIL_LIMIT})`);

  let breakdown = '';
  for (const [m, t] of Object.entries(perModelTokens)) {
    breakdown += `  - ${m}: in=${t.in} cacheW=${t.cc} cacheR=${t.cr} out=${t.out}\n`;
  }

  const state =
    `# loop_state (自動生成 / loop_guard.js)\n\n` +
    `- 日付: ${today}\n` +
    `- 当日コスト(重み付け概算): $${cost.toFixed(4)} / 上限 $${COST_LIMIT}\n` +
    `- 当日ターン数: ${turns} / 上限 ${TURN_LIMIT}\n` +
    `- 連続失敗: ${failures} / 上限 ${FAIL_LIMIT}\n` +
    `- 停止条件: ${stop ? '🛑 到達 — ' + reasons.join(', ') : '✅ 余裕あり'}\n` +
    `- transcript読込: ${ok ? 'OK' : '失敗(空集計)'}\n\n` +
    `## モデル別トークン(当日)\n${breakdown || '  (なし)\n'}` +
    `\n_更新: ${new Date().toISOString()} (${event})_\n`;

  try {
    fs.writeFileSync(path.join(cwd, '.claude', 'loop_state.md'), state, 'utf8');
  } catch (_) {}

  // --- UserPromptSubmit のみ文脈へ注入 ---
  if (event === 'UserPromptSubmit') {
    let out =
      `[loop_guard] 当日 cost=$${cost.toFixed(3)}/$${COST_LIMIT}, ` +
      `turns=${turns}/${TURN_LIMIT}, fails=${failures}/${FAIL_LIMIT}.`;
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
