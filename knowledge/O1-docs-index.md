# O1-docs-index.md — where to find knowledge about Claude / Claude Code / API (as of 2026-10-06)

Rule zero: start from the index `https://code.claude.com/docs/llms.txt` (Claude Code) or `https://platform.claude.com/llms.txt` (API). Then fetch the specific page as `.md` with `curl`, not WebFetch, because WebFetch summarizes and loses content. Read this file together with O0 (measured facts); markers below map 1:1 to O0's: [SOURCE] = [ŹRÓDŁO], [MEASURED] = [POMIAR], [ASSUMPTION] = [ZAŁOŻENIE].

## TL;DR
- Source of truth: CC has the canonical `https://code.claude.com/docs/llms.txt` (38,149 chars, 172 links). Per the Fern Agent Score audit of 2026-07-23, the `.md` variant and content negotiation worked on 10/10 sampled pages, with no redirects. PL publishes `llms.txt` and `llms-full.txt`. Old `docs.anthropic.com` and `docs.claude.com` addresses redirect, but some end in 404.
- Tool: WebFetch converts HTML to Markdown and passes it through a separate small model ("lossy by design" per CC tools-reference). Full content: `curl -sL <url>.md`, then Read/grep on the file. The `claude-code-guide` agent (Haiku; Glob, Grep, Read, WebFetch, WebSearch) is for quick CC questions, not for verification.
- Cloud network: CE's Trusted list includes api.anthropic.com, docs.claude.com, platform.claude.com, code.claude.com, claude.ai, claude.com, support.claude.com, anthropic.com, www.anthropic.com, github.com, api.github.com, raw.githubusercontent.com. It ends with a "Model Context Protocol" section listing `*.modelcontextprotocol.io` (the asterisk means subdomain matching) [SOURCE: CE, 2026-10-06]. Whether that entry also covers the bare host is unverified: test with curl [ASSUMPTION].

## 0. Conventions
- Abbreviations: CC = https://code.claude.com/docs/en/ · PL = https://platform.claude.com/docs/en/ · AN = https://www.anthropic.com/ · CE = CC cloud-environments · GH = https://docs.github.com/en/ · MCP = https://modelcontextprotocol.io/
- Reliability: [OF] official docs · [BLOG] AN engineering/research/news · [CL] changelog/release notes · [IS] GitHub issue (a report, not a spec) · [3P] third party (blog, mirror, audit), never the sole basis for a claim.
- Address status (2026-10-06): ✅ page returned/fetched during research · 🔗 address known from an official page's internal link or navigation, page itself not fetched · ❓ unverified.
- `.md` variant: worked on 10/10 sampled CC pages (`<url>.md` and content negotiation) [SOURCE: buildwithfern.com/agent-score/company/claude-code/llms.txt, 2026-07-23, 3P]. Sample of 10, not all 172. In PL the `.md` variant appeared in the old llms.txt (docs.claude.com/…/x.md); for platform.claude.com [ASSUMPTION: check with curl].
- Every fetched CC page starts with a block "Documentation Index … https://code.claude.com/docs/llms.txt" [SOURCE: CC cloud-environments, 2026-10-06].

## 1. INDEX topic → page

### 1.1 Claude Code (CC, [OF])
| Topic | Address (append `.md` for full content) | When to use | St. |
|---|---|---|---|
| Full index | https://code.claude.com/docs/llms.txt | first step on any unfamiliar topic | ✅ |
| Heading map | CC claude_code_docs_map | section list of every page, good for grep | ✅ |
| Overview | CC overview | surfaces: terminal, IDE, desktop, web | ✅ |
| How CC works | CC how-claude-code-works | agent loop, tools | 🔗 |
| Context and compaction | CC context-window; CC costs | context use, auto-compact, token costs | 🔗 / ✅ |
| Prompt caching in CC | CC prompt-caching | CC cache, TTL (`promptCacheTtl` in settings-reference) | 🔗 |
| Tools (Read, Bash, WebFetch…) | CC tools-reference | tool list, Read/Bash/WebFetch limits | ✅ |
| CLAUDE.md and memory | CC memory | CLAUDE.md hierarchy, rules, auto memory | 🔗 |
| Skills | CC skills | SKILL.md, frontmatter, `allowed-tools` | 🔗 (curl 200 per 3P) |
| Subagents | CC sub-agents | frontmatter, built-in agents (incl. claude-code-guide), available tools | ✅ |
| Agent teams / agent view | CC agent-teams; CC agent-view | teammates, background agents | ✅ |
| Workflows / ultracode | CC workflows | dynamic workflows (`Workflow` tool); ultracode described in CC model-config | ✅ |
| /goal | CC goal | condition evaluator after each turn | ✅ |
| Scheduling, /loop | CC scheduled-tasks; CC routines | recurring tasks, cloud Routines | ✅ / 🔗 |
| Hooks | CC hooks (reference); CC hooks-guide | events, matcher, exit codes | ✅ / 🔗 |
| Permissions | CC permissions; CC permission-modes | rule syntax, modes (default, acceptEdits, plan, auto, dontAsk, bypass) | 🔗 / ✅ |
| Auto mode | CC auto-mode-config | `autoMode.environment`, `/auto-mode-setup` | ✅ |
| Sandbox | CC sandboxing | Bash sandbox, `sandbox.network.*` | 🔗 |
| Settings | CC settings; CC settings-reference | scopes and precedence; index of every key | 🔗 / ✅ |
| Environment variables | CC env-vars | all CLAUDE_*, ANTHROPIC_*, BASH_* | 🔗 |
| Network, proxy, required domains | CC network-config | CC host list, proxy, mTLS, watchdogs | ✅ |
| MCP in CC | CC mcp | `.mcp.json`, scope, tool search, claude.ai connectors | 🔗 |
| Plugins and marketplace | CC plugins/overview; CC plugins/mods/reference | plugins, mods API | 🔗 / ✅ |
| Output styles | CC output-styles | response styles | 🔗 |
| Worktrees | CC worktrees | branch isolation | 🔗 |
| -p / headless | CC headless | `-p`, `--bare`, `--allowedTools` | ✅ |
| Agent SDK | CC agent-sdk; CC agent-sdk/python; CC agent-sdk/quickstart; CC agent-sdk/custom-tools | SDK now documented under the CC domain | ✅ |
| Claude Code SDK → Agent SDK migration | PL agent-sdk/migration-guide | package renames | ✅ |
| CLI and commands | CC cli-reference; CC commands; CC interactive-mode | flags, slash commands | ✅ |
| GitHub Actions | CC github-actions (+ repo anthropics/claude-code-action) | CI | 🔗 / ❓ |
| Cloud / web | CC claude-code-on-the-web; CC web-quickstart; CE = CC cloud-environments | cloud sessions, GitHub proxy, Trusted, setup script | ✅ |
| Self-hosted env | CC self-hosted-environments | own runners | 🔗 |
| Platforms, IDE | CC platforms; CC vs-code; CC jetbrains; CC desktop; CC chrome | where to run CC | ✅ / 🔗 |
| Models, aliases, effort | CC model-config | aliases (opus, sonnet, fable, opusplan), effort, ultracode, `CLAUDE_CODE_SUBAGENT_MODEL` | ✅ |
| Errors | CC errors | error messages, retry | 🔗 |
| Best practices | CC best-practices | verification, context, auto mode | ✅ |
| Agents (overview) | CC agents | per O0 | 🔗 |
| Changes | CC changelog; CC whats-new (+ weekly CC whats-new/2026-wNN) | what changed since version X | ✅ [CL] |

### 1.2 API / platform (PL, [OF])
| Topic | Address | When to use | St. |
|---|---|---|---|
| Indexes | https://platform.claude.com/llms.txt; https://platform.claude.com/llms-full.txt | API page list | ✅ (existence per PL resources/overview zh-TW; size ❓) |
| Models overview (source of truth for IDs) | PL models/overview | current IDs, context, prices | 🔗 (PL navigation) |
| Per-model pages | PL models/opus-5-5/overview; …/whats-new-opus-5-5; …/migration-guide | Opus 5.5: `claude-opus-5-5`, 1M context, 128K output, $4/$20 per MTok, adaptive thinking (always on), default effort medium, knowledge cutoff Jun 2026 | ✅ |
| Other models | PL models/{opus-5, opus-4-8, opus-4-6, opus-4-5, sonnet-5, sonnet-5-5, fable-5-1}/… | legacy models and comparisons | ✅ |
| Migrations (index) | PL about-claude/models/migration-guide | list: Fable 5.1/Mythos 5.1, Mythos 5/Fable 5, Opus 5.5, Sonnet 5.5, Haiku 4.5 | ✅ |
| Deprecations | PL about-claude/model-deprecations | retirement dates, replacements, parameters | ✅ |
| API release notes | PL release-notes/overview | API, SDK and Console changes (newest first) | ✅ [CL] |
| claude.ai system prompts | PL release-notes/system-prompts/overview | app prompt (not API) | ✅ |
| Context | PL build-with-claude/context-windows | 1M, thinking, compaction | ✅ (3P listing) |
| Token counting | PL build-with-claude/token-counting | count_tokens | 🔗 |
| Pricing | PL about-claude/pricing | prices, fast mode, Managed Agents | ✅ |
| Prompt caching (API) | PL build-with-claude/prompt-caching | TTL 5m/1h, minimum (512 tokens on Opus 5.5) | ✅ |
| Effort | PL build-with-claude/effort | effort levels | 🔗 |
| Cost vs intelligence | PL about-claude/models/optimizing-for-cost-and-intelligence | cost per task | ✅ |
| Prompt engineering | PL build-with-claude/prompt-engineering/claude-prompting-best-practices; …/prompting-claude-opus-5; …/prompting-claude-opus-5-5; …/prompting-claude-fable-5 | per-model guidance | ✅ / ✅ / ✅ / 🔗 |
| Hallucinations | PL test-and-evaluate/strengthen-guardrails/reduce-hallucinations (O0 path: …/prompt-engineering/reduce-hallucinations) | paths disagree: check with curl | ❓ |
| Rate limits | PL api/rate-limits | RPM/TPM limits | ❓ |
| Batch | PL build-with-claude/batch-processing | results available for 29 days | ✅ |
| Files API | PL build-with-claude/files | file upload | ❓ |
| Citations | PL build-with-claude/citations | citations combined with structured outputs → 400 | ✅ |
| Structured outputs | PL build-with-claude/structured-outputs | JSON schema | ❓ |
| Tool use | PL agents-and-tools/tool-use/overview; …/web-fetch-tool; …/server-tools; …/programmatic-tool-calling | API tools | ✅ (web-fetch, server-tools, PTC) / 🔗 |
| MCP connector | PL agents-and-tools/mcp-connector | MCP via API | ❓ |
| Managed Agents | PL managed-agents/tools; PL managed-agents/migration | `agent_toolset_20260401`, migration from SDK | ✅ |
| Claude Platform on AWS | PL build-with-claude/claude-platform-on-aws | AWS | ✅ |
| Fast mode | PL build-with-claude/fast-mode | faster variant | ✅ |
| Model cards | PL resources/overview | system cards | ✅ |

### 1.3 Blog, research, other Anthropic sources
- [BLOG] AN engineering/multi-agent-research-system ("How we built our multi-agent research system", 2025-06-13) ✅
- [BLOG] AN engineering/effective-harnesses-for-long-running-agents (initializer + coding agent, claude-progress.txt) ✅
- [BLOG] related: AN engineering/effective-context-engineering-for-ai-agents, …/harness-design-long-running-apps, …/managed-agents ✅ (search index)
- [BLOG] AN research/reward-tampering ("Sycophancy to subterfuge", 2024-06; arXiv 2406.10162) ✅ (indirect confirmation)
- [BLOG] AN research/towards-understanding-sycophancy-in-language-models ❓ (paper: arXiv 2310.13548 [ASSUMPTION])
- Status: https://status.claude.com (components: claude.ai, Console, API, Claude Code, Cowork, Claude for Government; Atom/RSS; history: status.claude.com/history) ✅. Alternative: status.anthropic.com [3P].
- Help / plans: https://support.claude.com (formerly support.anthropic.com) ❓ — search `site:support.claude.com <topic>`.
- Policies: AN legal/aup ❓.
- Claude Tag (Slack): https://claude.com/docs/claude-tag/overview 🔗 (linked from CE); claude.com/docs = "Claude.ai Documentation", has its own /docs/llms.txt ✅.
- Claude in Chrome: CC chrome 🔗. Claude Security, Claude Science: ❓ (not confirmed).
- GitHub: github.com/anthropics/claude-code/blob/main/CHANGELOG.md ✅ [CL] (over 400 KB, read in fragments); releases: github.com/anthropics/claude-code/releases ✅; issues: github.com/anthropics/claude-code/issues [IS]; other repos (claude-agent-sdk-python/-typescript, skills, claude-cookbooks, claude-code-action, anthropic-sdk-*) ❓.

### 1.4 External dependencies
- MCP: https://modelcontextprotocol.io/llms.txt ✅; …/llms-full.txt ✅ (~1.05M tokens per Context7 [3P], too large for context per issue #578 [IS]); versioned spec: MCP specification/2026-07-28/basic/index ✅ (check whether a newer date exists); Python SDK: https://py.sdk.modelcontextprotocol.io (has llms.txt and llms-full.txt) ✅.
- GH about-protected-branches: GH repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches ✅
- GH rulesets: …/managing-rulesets/about-rulesets 🔗
- GH REST rate limits: GH rest/using-the-rest-api/rate-limits-for-the-rest-api ✅ (primary and secondary limits; 900 points/min for REST)
- GH gated-features/protected-branches (from O0) ❓; Actions, tokens, GitHub App, GraphQL limits: ❓ — search `site:docs.github.com`.
- Bedrock / Vertex / Foundry: CC amazon-bedrock, CC google-vertex-ai, CC microsoft-foundry 🔗; provider pages ❓.

### 1.5 Dead and redirected addresses
- `docs.anthropic.com` → `docs.claude.com` → `platform.claude.com/docs` (CC → `code.claude.com/docs`) [SOURCE: PL release-notes/overview, 2026-10-06, CL]. In one repo audit, of 47 redirects 39 landed on a live page and 8 on 404 [SOURCE: github.com/jeremylongshore/tons-of-skills-marketplace/issues/1146, IS/3P].
- `console.anthropic.com` → `platform.claude.com`; `support.anthropic.com` → `support.claude.com` [CL].
- Old CC docs map: `docs.claude.com/en/docs/claude-code/claude_code_docs_map.md` (2025) → now CC claude_code_docs_map [SOURCE: simonwillison.net 2025-10-24, 3P].
- `docs.claude.com/llms.txt` is still indexed with stale links: do not use.
- Search engines index language variants (CC /ko/, PL /zh-TW/, /de/). Always force `/en/`.

## 2. LIVE LOOKUP MECHANISMS
- CC: `https://code.claude.com/docs/llms.txt` (canonical; a second address also exists), 38,149 chars ≈ 10k tokens, fits one Read. Covers 100% of the 172 sitemap pages [SOURCE: buildwithfern agent-score, 2026-07-23, 3P]. `https://code.claude.com/docs/llms-full.txt` exists ✅; a mirror reports ~5 MB [SOURCE: github.com/pleaseai/claude-code-docs, 3P]. NEVER read it whole; only `curl … | grep -n`.
- CC sitemap: exists (the audit compares llms.txt against it); exact address ❓ [ASSUMPTION: https://code.claude.com/docs/sitemap.xml].
- `.md` risk: per Fern Agent Score (Claude Code, 2026-07-23), 3 of 10 sampled pages had substantive markdown-vs-HTML content differences (avg 17% missing) and 1 of 10 exceeded 100K chars (max 185K) [3P]. If a gap looks suspicious, compare with the HTML.
- PL: `https://platform.claude.com/llms.txt`, `https://platform.claude.com/llms-full.txt` ✅. Size ❓ (Context7 counts 5.7M / 3.6M tokens after processing, which is not the file size). Treat llms-full as multi-MB and use only with grep.
- MCP: `https://modelcontextprotocol.io/llms.txt`, `/llms-full.txt` ✅.
- RSS: status.claude.com (Atom/RSS) ✅. PL release notes and CC changelog RSS ❓. Instead: raw CHANGELOG `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` (the same feed `/release-notes` reads; cloud sessions don't fetch it automatically) [SOURCE: CC network-config, 2026-10-06].
- Built-in docs search (Ctrl+K) is UI-only. For an agent: grep over llms.txt or WebSearch `site:`.
- Tool limits:
  - Read: limits are measured in O0 §1 (25,000 tokens per call, 256 KB file; PARTIAL view behavior) — use O0, not re-derivation. Docs: reading a larger file whole returns the first page with a `PARTIAL view` notice and offset/limit instructions [SOURCE: CC tools-reference, 2026-10-06]. Override: `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` [SOURCE: CC env-vars per O0].
  - Bash: inline output ~30,000 chars; larger output goes to a file with a 2,000-char preview. `BASH_MAX_OUTPUT_LENGTH` sets how many chars CC reads from the working file: default 30,000, hard cap 150,000. `bashOutputMaxChars` goes up to 128,000 chars and, when set, CC ignores `BASH_MAX_OUTPUT_LENGTH` (v2.1.261+). A command producing over 5 GB is killed [SOURCE: CC tools-reference, 2026-10-06].
  - Glob and Grep: CC tools-reference says they are disabled by default on Linux, with search going through Bash `find`/`grep` (embedded bfs/ugrep) [SOURCE: CC tools-reference]. O0 measurements include Grep calls (U4-01), so check the tool list in the actual session [ASSUMPTION: depends on build/settings].
  - WebFetch: HTML → Markdown, then the prompt runs in a separate model call; "lossy by design". Accept header prefers Markdown; User-Agent starts with `Claude-User`. Has a built-in preapproved list of documentation domains; sandboxed commands do not inherit it [SOURCE: CC tools-reference]. Per code analyses, for a trusted domain a `text/markdown` response under 100k chars skips the small model [3P: giuseppegurgone.com, medium.com/@nblintao]. In 2.1.290 (2026-10-05) WebFetch reports unread content beyond 100K chars and accepts an offset; WebSearch replenishes 100 calls/h [3P: ai-tldr.dev — confirm in CC changelog]. Domains go through a server-side safety check via api.anthropic.com [SOURCE: CC network-config].
- Choosing a tool:
  1. Verbatim quote, number, flag or version: `curl -sL -o /tmp/x.md <url>.md`, then `grep -n` and Read with offset.
  2. Quick orientation on one page: WebFetch with a narrow prompt (output is [3P]-quality, not a quote).
  3. "How do I do X in CC": `claude-code-guide` agent. Model Haiku; tools Glob, Grep, Read, WebFetch, WebSearch [SOURCE: CC sub-agents, 2026-10-06; 3P]. Fetches the docs maps (code.claude.com) [SOURCE: CC network-config]. Known bug: `permissionMode: dontAsk` blocks its WebSearch (v2.1.100) [IS #46250]. Its answer is a summary of a summary — verify key facts with curl. Disable built-in agents: `CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS=1` (-p/SDK).
  4. Unknown address: WebSearch `site:code.claude.com <topic>` / `site:platform.claude.com`.

## 3. VERIFICATION AND REFRESH PROCEDURE
- Is the address alive: `curl -sS -o /dev/null -w '%{http_code} %{url_effective}\n' -L <url>`. 200 with no host change = OK. 301/308 → record the target and check it doesn't 404. 403 in the cloud most likely means a proxy block, not a missing page. Per the audit, CC returns proper 404s for bad addresses and does no redirects [3P].
- On 404: (1) `curl -s https://code.claude.com/docs/llms.txt | grep -i <word>` (API: platform.claude.com/llms.txt); (2) CC claude_code_docs_map; (3) sitemap; (4) WebSearch `site:<host> <title>`; (5) changelog and release notes (renamed?). Only then mark the address ❌ with a date.
- Detecting changes:
  - CC: `claude --version`; CHANGELOG from your version (`grep -n '^## 2.1.2[89]'`); CC whats-new (weekly). Versions 2.1.290–2.1.291 shipped after 2.1.289 [SOURCE: github.com/dubbl-a/house-rules/issues/217, 3P].
  - API: PL release-notes/overview and PL about-claude/model-deprecations.
  - Docs pages carry no date. For comparisons, store `sha256sum` of the fetched `.md`.
- Index marker: `✅ 2026-MM-DD (curl 200)` or `❌ 2026-MM-DD (404 → new URL)`. Write [MEASURED: …] only after an actual curl in this repo.
- Cloud network (CE, [OF], 2026-10-06):
  - Default is Trusted.
  - CE domain list: Anthropic services (api.anthropic.com, docs.claude.com, platform.claude.com, code.claude.com, claude.ai, claude.com, support.claude.com, anthropic.com, www.anthropic.com), GitHub (github.com, api.github.com, raw.githubusercontent.com, codeload…), package registries, clouds.
  - The Trusted list ends with a "Model Context Protocol" section listing `*.modelcontextprotocol.io`. CE: entries marked with `*` match subdomains, so subdomains are allowed. Whether this covers the bare host modelcontextprotocol.io must be checked with curl; if not, use Custom + "Also include default list…" [ASSUMPTION].
  - Outbound session traffic goes through a security proxy, but CE lists exceptions that bypass the session allowlist: GitHub (separate proxy), MCP connectors (traffic goes via Anthropic's servers), hosts with API credentials, and the Anthropic API, available even at None. GitHub proxy: scoped to attached repos (others → 403), GraphQL only from a pinned list (others → 403; fallback `gh api repos/...`).
  - Changing the network level in an Anthropic-hosted environment applies to existing sessions within about a minute for requests going through the session allowlist; no new session needed [SOURCE: CE].
- [ASSUMPTION to measure in the repo]: `for h in code.claude.com platform.claude.com www.anthropic.com github.com modelcontextprotocol.io status.claude.com support.claude.com; do curl -sS -o /dev/null -w "$h %{http_code}\n" https://$h/; done` — record the result as [MEASURED].
- [ASSUMPTION]: in a cloud session WebFetch is executed by the harness inside the VM (request with User-Agent Claude-User), not server-side, so it is subject to the allowlist. Docs only say WebFetch fetches the page from the harness; WebSearch runs in Anthropic's backend [3P: withgauge.com]. Test: WebFetch on a domain outside Trusted while on Trusted (error = goes through the proxy).

## 4. OTHER RELEVANT ISSUES
- Docs vs behavior: CC pages state version thresholds ("Requires v2.1.208 or later"). Compare with `claude --version`. Older behavior is often described as "Before v2.1.x…".
- Per-model generated pages (PL models/<id>/overview, whats-new, migration-guide, prompting-claude-<model>) multiply with each model. The URL pattern is predictable, but confirm in llms.txt before citing.
- The Agent SDK is documented in CC (code.claude.com/docs/en/agent-sdk/...), migration is in PL. On conflict, CC is probably newer [ASSUMPTION].
- Knowledge beyond docs: anthropics/claude-code issues (bugs, workarounds, e.g. Read limit, WebFetch in subagents #59416), CHANGELOG (most version-precise), AN engineering (patterns, not spec), Piebald-AI/claude-code-system-prompts (tool prompts [3P], unofficial). Leaked source code is not a source.
- Unofficial mirrors (pleaseai/claude-code-docs, synced every 6 h) are useful for history diffs, always marked [3P].
- In cloud sessions LSP does not start, repo `enabledPlugins` plugins are not installed, user `~/.claude` does not exist [SOURCE: CE].

## 5. CLAUDE.md snippet (≤15 lines)
```
## Claude / CC / API documentation
- Question about Claude, Claude Code, API, MCP or agents → read O1-docs-index.md first.
- Order: O1 index → page `.md` via `curl -sL` (+ grep / Read with offset) → WebFetch for orientation only.
- Don't guess URLs. Not in O1 → `curl -s https://code.claude.com/docs/llms.txt | grep -i X`
  (API: https://platform.claude.com/llms.txt), then WebSearch `site:`.
- Mark docs facts [SOURCE: URL, date]; inferences [ASSUMPTION]; own tests [MEASURED].
- Dead address (404/403/redirect→404): llms.txt → claude_code_docs_map → WebSearch site:,
  then fix the O1 entry (new URL, status, date).
- After each verification update status and date in O1. Never read llms-full.txt whole.
- Version-dependent behavior: compare `claude --version` with the CC changelog.
```

## Check again
- Weekly: CC changelog/whats-new (version > 2.1.291?), PL release-notes, status.claude.com.
- On every new model: PL models/overview, model-deprecations, migration-guide, prompting-claude-<model>; aliases in CC model-config.
- Monthly: size and link count of code.claude.com/docs/llms.txt (was 38,149 chars / 172 links); 🔗 and ❓ entries via curl (especially PL api/rate-limits, files, structured-outputs, mcp-connector, effort, token-counting, reduce-hallucinations, AN sycophancy, AN legal/aup, GH gated-features).
- Once, in the first cloud session: [MEASURED] curl to the 7 hosts (section 3); whether CE's `*.modelcontextprotocol.io` Trusted entry covers the bare host modelcontextprotocol.io; whether WebFetch goes through the proxy; whether Glob/Grep are in the session's tool list.
- On MCP version change: new date in the path specification/YYYY-MM-DD.
