# O4 — Extensions: MCP, plugins, skills, evals (CC 2.1.289–2.1.291)
All tags accessed 2026-10-06. CC = https://code.claude.com/docs/en/ ; MCPS = https://modelcontextprotocol.io/specification/

## TL;DR
- MCP: `claude mcp add --transport http|sse|stdio`; `add-json` for `ws`. A `url` without `type` is an error. Tool search is on by default and `alwaysLoad` exempts a server or tool. Output warns at 10k and caps at 25k tokens. [OF CC/mcp]
- Spec 2026-07-28 (current): stateless, `server/discover`, `resultType: "input_required"` (MRTR), Tasks as an extension. Roots, sampling and logging deprecated. [OF MCPS/2026-07-28/changelog] [3P]
- plugin.json: only `name` is required. `claude plugin validate --strict` is the CI gate. [OF CC/plugins-reference]
- `claude plugin eval` (v2.1.269+): 3 runs with and 3 without the plugin, and Δ is the value the plugin adds. [OF CC/plugin-evals]

## Deltas vs O0/O1/O2
- O1 §1.4 asked whether an MCP spec newer than 2026-07-28 exists: none found as of 2026-10-06 (RC was 2026-05-21). [3P stacktr.ee]
- O0 §1 (MCP deferred by default) is consistent with docs: tool search on by default; exemptions `alwaysLoad` (server) and `_meta anthropic/alwaysLoad` (tool). [OF CC/mcp]

## 1. MCP in Claude Code [OF CC/mcp]
- Add:
  - `claude mcp add --transport http <name> <url> [--header "K: V"]`
  - `claude mcp add [--env K=V] --transport stdio <name> -- <cmd> [args]`
  - `claude mcp add-json <name> '<json>'`
  - `-s local|project|user` (default local); `-t`/`-H`/`-e` short forms.
- Manage: `list`, `get`, `remove [--scope]`, `login <name> [--no-browser]`, `logout`; `/mcp`, `/mcp reconnect all` (v2.1.284+).
- Transports: `http` (alias `streamable-http`, recommended). `sse` is deprecated, with auto-fallback (v2.1.265+). `ws` is add-json only and header auth only. `sdk` is SDK-host only.
- `.mcp.json` server keys: `type`, `url`, `headers`, `headersHelper`, `command`, `args`, `env`, `timeout`, `alwaysLoad`. Reserved names: `workspace`, `claude-in-chrome`, `computer-use`, `Claude Preview`, `Claude Browser`.
- Expansion: `${VAR}` and `${VAR:-default}`; an unset var without default stays literal, with a warning. Stdio servers get `CLAUDE_PROJECT_DIR` (use `${CLAUDE_PROJECT_DIR:-.}` in non-plugin configs). `roots/list` = launch dir + add-dirs.
- Approval: committed `enableAllProjectMcpServers`/`enabledMcpjsonServers` are ignored until workspace trust (v2.1.196+). User, managed and `--settings` approvals apply. `disabledMcpjsonServers` always rejects. Per-project `disabledMcpServers`/`enabledMcpServers` live in `~/.claude.json`.
- Timeouts:
  - `MCP_TIMEOUT` = startup (`-p` waits 30 s).
  - Per-server `timeout` (ms, ≥1000) overrides `MCP_TOOL_TIMEOUT` (default ≈28 h).
  - Idle timeout: remote 5 min, stdio 30 min (`CLAUDE_CODE_MCP_TOOL_IDLE_TIMEOUT`).
  - Main-thread calls over 2 min auto-background (`CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS`, v2.1.212+).
- Output: warning at 10,000 tokens (fixed), cap 25,000 (`MAX_MCP_OUTPUT_TOKENS`). Text over 50,000 chars is saved to a file. `_meta` `anthropic/maxResultSizeChars` allows up to 500k chars, but images still count against the cap [3P sume.com].
- Tool search:
  - Default on. Off with a non-first-party `ANTHROPIC_BASE_URL` or `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`.
  - `ENABLE_TOOL_SEARCH=true|auto|auto:N|false` [3P].
  - `"alwaysLoad": true` per server; `_meta {"anthropic/alwaysLoad": true}` per tool.
  - Descriptions are truncated at 2KB [3P startdebugging.net].
- Runtimes: v2 (spec 2026-07-28) is the default from v2.1.232 (flags) or v2.1.274. Overrides: `MCP_SDK_GENERATION=v1|v2`, `MCP_PROTOCOL_NEGOTIATION=auto|legacy`.
- Reconnect: remote 5× with backoff; first connect 3× on transient errors; stdio never. Discovery cache opt-in: `MCP_DISCOVERY_CACHE=1`.
- Plugin tool names: `mcp__plugin_<plugin>_<server>__<tool>`. Bare-key hook matchers never fire for them (see O2 §A3).
- Cloud sessions: plugin servers start on demand. For network limits see O0 §7 and O1 §3.
- `claude mcp serve` [3P oodle.ai], unverified. Not fetched: resource @-mentions, MCP prompts as commands, connectors, managed allow/deny keys (CC/managed-mcp).

## 2. Building an MCP server
- The current revision is 2026-07-28 (RC 2026-05-21). No newer revision found. [OF MCPS/2026-07-28/changelog] [3P stacktr.ee]
- Changes vs 2025-11-25 [OF MCPS/2026-07-28/changelog]:
  - No `initialize` and no `Mcp-Session-Id`. Version and capabilities travel in `_meta`.
  - `server/discover` is MUST, and mismatches return `UnsupportedProtocolVersionError`.
  - `resultType` = `complete`|`input_required`.
  - Tasks → `io.modelcontextprotocol/tasks` extension.
  - Resource not-found = `-32602`.
  - OTel `traceparent` in `_meta`.
  - HTTP+SSE Deprecated, with a ≥12-month window.
- Roots, Sampling and Logging deprecated (SEP-2577). [3P stacktr.ee] Routing headers `MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name`. [3P blog.cloudflare.com/mcp-v2]
- Annotations (hints only): `readOnlyHint` (false), `destructiveHint` (true), `idempotentHint` (false), `openWorldHint` (true), `title`. [OF CC/agent-sdk/typescript]
- Guidance: paginate instead of raising caps, and use alwaysLoad sparingly. [OF CC/mcp] Scaffold with `/plugin install mcp-server-dev@claude-plugins-official`. [OF CC/mcp]
- Not fetched: AN "writing tools for agents", PL tool-use best practices, SDK quickstarts.

## 3. Plugins [OF CC/plugins-reference]
- Layout: `.claude-plugin/plugin.json` (optional; only that file goes in there). At the root: `skills/<n>/SKILL.md`, `commands/`, `agents/`, `hooks/hooks.json` (with a `"hooks"` wrapper), `.mcp.json`, `.lsp.json`, `output-styles/`, `workflows/`, `themes/`, `monitors/monitors.json`, `evals/`, `settings.json`.

| Field | Rule |
|---|---|
| `name` | required, kebab-case. A `claude-`/`anthropic-` prefix is a validate error. |
| `version` | pins users until changed |
| `description`, `author{name}`, `homepage`, `repository`, `license`, `keywords`, `displayName`, `metadata` | metadata |
| `defaultEnabled` | default true |
| `dependencies` | `"n"`, `"n@mkt"`, `{name,marketplace,version}` |
| `settings` | only `agent`, `subagentStatusLine` |
| `skills` | **adds** to `skills/` |
| `commands`, `agents`, `outputStyles`, `workflows`, `experimental.themes/monitors` | **replace** defaults |
| `hooks`, `mcpServers` (also `.mcpb`), `lspServers` | **merge** |
| `experimental.evals` | default `evals/` |
| `userConfig`, `channels` | strict objects |

- Paths must start `./` and stay inside the root (`..` is an error). Unknown top-level keys are stripped with a warning.
- userConfig fields: `type` (string|number|boolean|directory|file), `title`, `description` (required), plus `required`, `default`, `options` (v2.1.271+), `multiple`, `sensitive` (keychain), `min`/`max`. Values are stored in `pluginConfigs`.
- Reference forms: `${user_config.KEY}` in MCP/LSP config, exec-form hook args and skill bodies. `CLAUDE_PLUGIN_OPTION_<KEY>` in hook env. Shell-form hooks and monitors reject `${user_config.*}`.
- `${CLAUDE_PLUGIN_ROOT}` changes on update. `${CLAUDE_PLUGIN_DATA}` = `~/.claude/plugins/data/<id>/` and survives updates. Neither is in the Bash tool env.
- CLI: `claude plugin install <p>@<mkt>`, `validate [--strict]`, `init`, `tag`, `eval`, `uninstall [--keep-data]`; `--plugin-dir`, `--plugin-url`, `/reload-plugins`. Validate results: passed / passed with warnings / failed. [OF CC/plugins-reference] [OF CC/cli-reference]
- Marketplace entries append to plugin.json unless `strict: false`. A skill-bundle uses `strict: false` + `skills: [...]`. [OF GH/anthropics/claude-plugins-official]
- Plugin agents ignore `permissionMode`, `hooks`, `mcpServers`, `initialPrompt` (see O2 §B2, §E).
- Not fetched: full marketplace.json schema, update behavior, `strictKnownMarketplaces`/`extraKnownMarketplaces`, mods.

## 4. `claude plugin eval` [OF CC/plugin-evals]
- Requires v2.1.269+ and git ≥2.31 if installed. Every run is billed.
- Suite: `evals/<case>/prompt.md` + `graders/<n>.md`, optional `case.yaml` (`schema_version: "1.1"`, `context.scaffold_script|history_file|add_dirs`), `mocks/<server>/<tool>.md`. Results go to `evals/results/<ts>/` (gitignore it).
- prompt.md fields: `max_turns`, `timeout_seconds`, `model`, `tags`, `allowed_tools`, `env`, `runs`. Each run starts in an empty workspace.
- Graders: free `regex`, `tool_used`, `tool_order`, `file_exists`; paid `llm`, `baseline`. Options `weight`, `arm: with-only|both`, `target`. No custom-code graders.
- Scoring: weighted pass fraction, mean over runs, `--threshold` (1.0). `tool_used: Skill` is excluded from the score.
- Flags: `--runs` (3), `-j` (1–8), `--model`, `--judge-model`, `--ablation none|with-without`, `--max-cost-usd`, `--allow-tools`, `--trust-plugin`, `--mocks record|off`, `--json`, `--no-publish`, `--case`, `--tag`, `--eval-dir`.
- Sandbox: temporary HOME/cwd. No user/project config or CLAUDE.md. Read-only tools unless granted. Granted Bash is OS-sandboxed (Linux needs bubblewrap+socat; O0 §4 measured `bwrap` absent in cloud → install before granting Bash).
- Exit: 0 pass; 1 fail/untrusted/invalid; 2 partial (cost ceiling or auth); 130; 143.
- JSON: `schemaVersion: 1`, `partial`, `partialReason`, `aggregates.{overallScore,casesPassed,casesTotal,meanDelta}`, `cases[].aggregates.{score,delta}`, `costUsd`, `claudeVersion`.
- CI: `claude plugin eval . --trust-plugin --json results.json --threshold 0.8 --model claude-sonnet-5 --judge-model claude-haiku-4-5 --no-publish --max-cost-usd 20`.
- Design rules: use regex for long outputs, and pair one result grader with one process grader. If Δ < 0 while the skill fired, suspect the judge.
- `/skill-doctor` (v2.1.261) reports unused skills and their context cost. [CL quoted in IS Adam-S-Daniel/skills-evals#193]

## 5. Skill authoring
- SDK: `skills: 'all'|[names]` plus settingSources that include `user`/`project`. [OF CC/agent-sdk/skills]
- The commonest failure is Claude not picking the skill on natural phrasing; fix the `description`. [OF CC/plugin-evals]
- Frontmatter syntax, locations, substitutions: see O2 §C.
- [ASSUMPTION] Keep SKILL.md ≈≤500 lines, move detail into referenced files and use trigger phrases. The PL best-practices page was not fetched.

## 6. Output styles and status line
- `/output-style <s>` works in `-p` (v2.1.269+). The SDK uses `settings.outputStyle`. [OF CC/headless] The file format was not fetched.
- statusLine: `{"type":"command","command":"…","padding":0,"refreshInterval":N}`, debounced at 300 ms. [OF CC/statusline]
- stdin fields: `model.{id,display_name}`, `workspace.*`, `cost.{total_cost_usd,total_duration_ms,total_lines_added}`, `context_window.{context_window_size,used_percentage,current_usage}`, `effort.level`, `rate_limits.*`, `prompt_cache.*`, `session_id`, `transcript_path`, `version`, `agent.name`. Many fields can be null. [OF CC/statusline]

## Verify live
- `claude mcp add-json t '{"url":"https://example.com/mcp"}'; claude mcp get t; claude mcp remove t`
- `mkdir -p /tmp/p/.claude-plugin && echo '{"name":"t"}' >/tmp/p/.claude-plugin/plugin.json && claude plugin validate /tmp/p --strict`
- `cd /tmp/p && claude plugin eval init --bare c1 && claude plugin eval . --runs 1 --ablation none --trust-plugin --json /tmp/r.json`
- `claude plugin eval --help`; `/skill-doctor`
- Check for a spec revision newer than 2026-07-28 at modelcontextprotocol.io/specification.
- Fetch CC/managed-mcp, CC/plugins/marketplace-reference, CC/skills, PL agent-skills best-practices.

## New URLs for O1
- ✅ CC/mcp, CC/plugins-reference, CC/plugin-evals, CC/statusline; MCPS/2026-07-28/changelog (search)
- 🔗 CC/managed-mcp, CC/plugins/marketplace-reference, CC/plugins/cli-reference, CC/agent-sdk/mcp, CC/agent-sdk/tool-search, modelcontextprotocol.io/docs/develop/build-server
