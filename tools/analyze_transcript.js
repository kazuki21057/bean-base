// T3-73a(docs/token_optimization_design.md §5): セッションtranscript(.jsonl)を
// message.id で重複排除しながら集計し、1ループのコスト構造を可視化するツール。
// 依存なし(素のNode.jsのみ)。
//
// 実行方法: node tools/analyze_transcript.js <transcriptのjsonlパス>
//
// 出力(設計書§2の実測表と同形式): uniqueRequests / totalToolCalls /
// toolsPerRequestヒストグラム / avgCtx / maxCtx / cacheR / cacheW / out /
// 概算コスト / ツール別の結果文字数 / 上位25件の大きなツール結果。
const fs = require('fs');

const CACHE_READ_RATE = 0.30e-6;
const CACHE_WRITE_RATE = 3.75e-6;
const OUTPUT_RATE = 15e-6;
const LONG_CTX_THRESHOLD = 200000;
const LONG_CTX_MULTIPLIER = 2;

function main() {
  const path = process.argv[2];
  if (!path) {
    console.error('使い方: node tools/analyze_transcript.js <transcriptのjsonlパス>');
    process.exit(1);
  }

  const lines = fs.readFileSync(path, 'utf8').split('\n').filter((l) => l.trim().length > 0);

  const seenRequestIds = new Set();
  const requests = []; // { ctx, cacheR, cacheW, out, toolCallCount }
  const toolNameById = new Map(); // tool_use_id -> tool name
  const toolResultSizes = []; // { tool, id, chars }

  for (const line of lines) {
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }

    if (entry.type === 'assistant' && entry.message) {
      const msg = entry.message;
      const content = Array.isArray(msg.content) ? msg.content : [];
      for (const block of content) {
        if (block.type === 'tool_use') {
          toolNameById.set(block.id, block.name);
        }
      }

      if (!msg.id || !msg.usage || seenRequestIds.has(msg.id)) continue;
      seenRequestIds.add(msg.id);

      const usage = msg.usage;
      const inputTokens = usage.input_tokens || 0;
      const cacheR = usage.cache_read_input_tokens || 0;
      const cacheW = usage.cache_creation_input_tokens || 0;
      const out = usage.output_tokens || 0;
      const ctx = inputTokens + cacheR + cacheW;
      const toolCallCount = content.filter((b) => b.type === 'tool_use').length;

      requests.push({ ctx, cacheR, cacheW, out, toolCallCount });
    } else if (entry.type === 'user' && entry.message && Array.isArray(entry.message.content)) {
      for (const block of entry.message.content) {
        if (block.type !== 'tool_result') continue;
        const chars = toolResultChars(block.content);
        toolResultSizes.push({
          tool: toolNameById.get(block.tool_use_id) || '(不明)',
          id: block.tool_use_id,
          chars,
        });
      }
    }
  }

  const uniqueRequests = requests.length;
  const totalToolCalls = requests.reduce((a, r) => a + r.toolCallCount, 0);
  const avgCtx = uniqueRequests ? Math.round(requests.reduce((a, r) => a + r.ctx, 0) / uniqueRequests) : 0;
  const maxCtx = uniqueRequests ? Math.max(...requests.map((r) => r.ctx)) : 0;
  const cacheR = requests.reduce((a, r) => a + r.cacheR, 0);
  const cacheW = requests.reduce((a, r) => a + r.cacheW, 0);
  const out = requests.reduce((a, r) => a + r.out, 0);

  let cost = 0;
  for (const r of requests) {
    const multiplier = r.ctx > LONG_CTX_THRESHOLD ? LONG_CTX_MULTIPLIER : 1;
    cost += multiplier * (r.cacheR * CACHE_READ_RATE + r.cacheW * CACHE_WRITE_RATE + r.out * OUTPUT_RATE);
  }

  const histogram = {};
  for (const r of requests) {
    const key = r.toolCallCount >= 3 ? '3+' : String(r.toolCallCount);
    histogram[key] = (histogram[key] || 0) + 1;
  }

  const charsByTool = {};
  for (const t of toolResultSizes) {
    charsByTool[t.tool] = (charsByTool[t.tool] || 0) + t.chars;
  }

  console.log(`uniqueRequests: ${uniqueRequests}`);
  console.log(`totalToolCalls: ${totalToolCalls}`);
  console.log('toolsPerRequest ヒストグラム:');
  for (const key of Object.keys(histogram).sort()) {
    console.log(`  ${key}件: ${histogram[key]}リクエスト`);
  }
  console.log(`avgCtx: ${avgCtx}`);
  console.log(`maxCtx: ${maxCtx}`);
  console.log(`cacheR: ${cacheR}`);
  console.log(`cacheW: ${cacheW}`);
  console.log(`out: ${out}`);
  console.log(`概算コスト: $${cost.toFixed(1)}`);

  console.log('ツール別の結果文字数(降順):');
  for (const [tool, chars] of Object.entries(charsByTool).sort((a, b) => b[1] - a[1])) {
    console.log(`  ${tool}: ${chars.toLocaleString()}文字`);
  }

  console.log('上位25件の大きなツール結果:');
  const top25 = [...toolResultSizes].sort((a, b) => b.chars - a.chars).slice(0, 25);
  for (const t of top25) {
    console.log(`  ${t.tool} (${t.id}): ${t.chars.toLocaleString()}文字`);
  }
}

function toolResultChars(content) {
  if (typeof content === 'string') return content.length;
  if (Array.isArray(content)) {
    return content.reduce((a, block) => {
      if (typeof block === 'string') return a + block.length;
      if (block && typeof block.text === 'string') return a + block.text.length;
      return a + JSON.stringify(block || '').length;
    }, 0);
  }
  return JSON.stringify(content || '').length;
}

main();
