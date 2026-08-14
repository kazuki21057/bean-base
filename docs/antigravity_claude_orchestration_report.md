# Report: Hybrid Architecture of Claude Code & Antigravity CLI

## 1. Executive Summary & Cost Verification
* **Token/Billing Separation**: Running models (including Claude Sonnet) via Antigravity CLI (`agy`) utilizes Google Antigravity quotas. It does **not** consume Anthropic API credits or tokens from Claude Code.
* **Accuracy Gap Cause**: Lower accuracy with Gemini Flash compared to native Claude Sonnet is primarily driven by:
  1. *Model Search Depth*: Flash is optimized for high-throughput scanning and tends to truncate deep iterative code-trace loops earlier than Sonnet.
  2. *Contextual Boundaries*: External headless invocations lack native subagent feedback loops unless explicit exploration boundaries, targets, and exit conditions are enforced in the prompt.
* **Sonnet via Antigravity CLI**: Switching Antigravity CLI to Sonnet improves reasoning, but structured prompt contracts and headless integration remain essential to match native subagent performance.

---

## 2. Delegation Architecture: Roles & Constraints

| Role | Tool | Responsibilities | Target Models |
| :--- | :--- | :--- | :--- |
| **Orchestrator** | Claude Code | Task decomposition, test execution, final review, and git integration | Claude Sonnet / Opus |
| **Research Worker** | Antigravity CLI | Large-scale codebase search, call-graph trace, dependency mapping | Gemini Pro / Sonnet |
| **Implementation Worker** | Antigravity CLI | Multi-file code edits, scaffolding in isolated worktrees | Gemini Pro / Sonnet |

---

## 3. Practical Guidelines (Tips for Subagent Calls)

### A. Model Selection by Task
* **Broad Scan / Indexing**: Use `Gemini Flash` (large context digest).
* **Deep Architecture / Bug Root Cause**: Use `Gemini Pro` or `Claude Sonnet` via Antigravity CLI.

### B. Contract-Driven Prompting (Structured Input)
When invoking `agy -p "..."`, strictly specify:
1. **Target scope & entry point files**
2. **Trace depth** (e.g., call sites, interface definitions, DB schemas)
3. **Structured output schema** (File paths, line ranges, rationale, assumptions)

```bash
# Example Invocation
agy -p "
[Role] Deep Codebase Investigation Subagent
[Target] Identify token expiration and refresh handling logic
[Scope] src/auth/ and associated middleware
[Constraints]
1. Return exact file paths and line ranges.
2. Trace caller chains up to route handlers.
3. Output purely factual code references (no speculative summaries).
[Output Format]
JSON: { files: [{ path: string, lines: string, role: string }], flow_summary: string[] }
" --output-format json
```

### C. Workspace Isolation & Context Optimization
* **Isolated Branch/Worktree**: Isolate Antigravity CLI code modifications into a dedicated branch or worktree; evaluate changes via `git diff` within Claude Code before merging.
* **Context Snowball Prevention**: Do not feed raw terminal logs back into Claude Code. Enforce concise structured summaries/JSON from Antigravity CLI to minimize orchestrator prompt cache bloat.

---

## 4. References & Sources
1. **Google Antigravity Documentation**: *Antigravity CLI Overview & Architecture* (`https://antigravity.google/docs/cli/overview`)
2. **Google Antigravity Documentation**: *Headless Mode & Scripting Agent Tasks* (`https://antigravity.google/docs/cli/headless`)
3. **Google Antigravity Documentation**: *Model Quotas and Usage Commands (/usage)* (`https://antigravity.google/docs/cli/commands/usage`)
4. **Google AI Developers Forum**: *Model Routing and Quotas in Antigravity Environment* (`https://discuss.ai.google.dev/t/claude-opus-shows-as-claude-sonnet-4-when-asked-about-model-identity-in-antigravity-ide/120150`)
5. **PADISO Engineering Report**: *Model Evaluation for Code Generation & Reasoning: Sonnet vs. Gemini Architectures* (2026)
