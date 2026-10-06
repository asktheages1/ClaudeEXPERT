# O3 — Automation & orchestration (CC 2.1.289–2.1.291)
All tags accessed 2026-10-06. CC = https://code.claude.com/docs/en/ ; PL = https://platform.claude.com/docs/en/ ; GH = https://github.com/

## TL;DR
- Baseline: `claude --bare -p "<task>" --permission-mode dontAsk|auto --permission-prompts none --allowedTools "<list>" --max-turns N --max-budget-usd X --output-format json`. [OF CC/headless] [OF CC/cli-reference]
- `total_cost_usd` is a client-side estimate, and resumed runs report cumulative totals. `--json-schema` results land in `structured_output`. [OF CC/headless]
- Workflows (JS `agent()`/`pipeline()`/`parallel()`) keep the plan in code and resume in the same session. Limits: 1,000 agents/run, 4,096 items/call. [OF CC/workflows]
- Agent teams: experimental and interactive-only. A shared task list with file locking, plus a mailbox of JSON files. [OF CC/agent-teams]
- `/goal`: a tool-less small-fast-model evaluator with no built-in cap, so write "or stop after N turns" into the condition. [OF CC/goal]

## Deltas vs O0/O1/O2 (recheck those files)
- Workflow concurrency: O0 §3 gives `min(16,max(2,CPU-2))` [MEASURED there]. Docs now say "up to 16, fewer with fewer CPUs"; `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS` (1–256, v2.1.269+). Keep O0's formula as measured until re-measured. [OF CC/workflows]
- Cache TTL: workflow agents and in-process teammates get 5-min TTL by default, even on subscriptions; `subagentPromptCacheTtl: "1h"` raises it. Recheck O0 §3 TTL rows. [OF CC/workflows]
- `--bare` "will become the default for `-p` in a future release". Before v2.1.286 it only partly isolated a session. [OF CC/headless]
- SDK `settingSources` default: CC TS reference = "CLI defaults (all sources)"; older PL agent-sdk/skills page = none. CC page is newer; pass `[]` for isolation. [OF CC/agent-sdk/typescript]
- Agent teams still experimental; when enabled, a *named* Agent call launches a teammate in interactive sessions. [OF CC/agent-teams]

## 1. CLI flags (headless subset; `--help` is incomplete) [OF CC/cli-reference] [OF CC/headless]
| Flag | Value / default | Notes |
|---|---|---|
| `-p, --print` | prompt | rejects `--bg`, and `--cloud` with a task |
| `--output-format` | `text`\|`json`\|`stream-json` | print only |
| `--input-format` | `text`\|`stream-json` | |
| `--json-schema` | JSON Schema | → `structured_output`. Invalid schema errors (v2.1.205+). `format` is an annotation only. |
| `--include-partial-messages` | — | `-p` + stream-json; emits `stream_event` |
| `--verbose` | — | used with stream-json |
| `--max-turns N` | no limit | errors on hit |
| `--max-budget-usd X` | none | Client estimate, incl. subagents; restored totals excluded. At cap: `Budget limit reached` and bg subagents stop (v2.1.217+). |
| `-r/--resume <id\|name\|path.jsonl>`, `-c`, `--fork-session`, `--session-id <uuid>`, `--no-session-persistence` | — | cross-project ID search v2.1.223+ |
| `--permission-mode` | `default`\|`manual`\|`acceptEdits`\|`plan`\|`auto`\|`dontAsk`\|`bypassPermissions` | Omitting it can start the run in `auto`, so always set it. |
| `--permission-prompts host\|none` | `host` | v2.1.259+. `none` denies prompts and removes AskUserQuestion. |
| `--permission-prompt-tool <mcp>` | — | waits up to `MCP_TIMEOUT` (30 s) |
| `--allowedTools`/`--disallowedTools` | rules (O2 §D4) | Bare deny removes the tool; `"mcp__*"` removes all MCP. A bare `Bash` allow is dropped in auto mode. |
| `--tools "<list>"\|""\|default` | — | Built-ins only. Default omits Glob/Grep on macOS/Linux. |
| `--mcp-config`, `--strict-mcp-config` | — | `-p` waits for pending servers (v2.1.221+) |
| `--system-prompt[-file]`, `--append-system-prompt[-file]` | — | Flag + file form combine (v2.1.283+). Prompt is snapshotted on the first request; `--system-prompt-snapshot off` (v2.1.257+). `__SYSTEM_PROMPT_DYNAMIC_BOUNDARY__` line (v2.1.275+). |
| `--append-subagent-system-prompt[-file]` | — | `-p` only; v2.1.205+/v2.1.261+ |
| `--exclude-dynamic-system-prompt-sections` | — | cross-machine cache reuse |
| `--agents '<json>'\|<file>`, `--agent <name>` | — | file form v2.1.281+; validated v2.1.242+ |
| `--settings <file\|json>` (≤2 MiB), `--setting-sources user,project,local` | — | teammates inherit sources |
| `--bare` | — | Skips hooks/skills/plugins/MCP/memory/CLAUDE.md. Needs `ANTHROPIC_API_KEY` or `apiKeyHelper`. No reminders or bg tasks since v2.1.286. |
| `--restricted` | — | v2.1.248+; eval harness mode, no exec tools |
| `--safe-mode` | — | all customizations off |
| `--model`, `--effort low…max\|ultracode`, `--fallback-model a,b` | — | ultracode v2.1.203+ |
| `--forward-subagent-text` | — | v2.1.211+; stream-json |
| `--include-hook-events`, `--prompt-suggestions`, `--replay-user-messages` | — | stream-json |
| `--debug[=cats]`, `--debug-file` | — | filter only in `=` form |
| `--init`, `--init-only`, `--maintenance` | — | Setup hooks (print mode) |

Subcommands: `claude agents [--json]`, `attach/logs/respawn/stop/rm <id|name>` (partial names v2.1.290+), `claude daemon status|stop`, `claude auth status` (exit 0/1), `claude setup-token`, `claude doctor`, `claude ultrareview [--json]`. [OF CC/cli-reference]

## 2. Exit codes and errors [OF CC/headless]
- 0 = success, non-zero = failure. Invalid flags go to stderr pre-run. In-run failures (e.g. auth) print as the result on stdout.
- SIGTERM → 143 with no result recorded. SIGINT or SDK `interrupt()` ends the turn cleanly. `CLAUDE_CODE_RESUME_INTERRUPTED_TURN=1` continues the interrupted turn.
- Stdin cap is 10MB (non-zero exit when exceeded).
- Background Bash is killed about 5 s after the result. Background subagents and workflows hold `-p` open up to a 10-min idle ceiling (`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`).
- Invalid `--mcp-config` entries are skipped but the run still exits 0, so gate on `mcp_server_errors`.

## 3. JSON schemas
- `json` result fields: `result`, `session_id`, `usage`, `total_cost_usd` + per-model cost, `structured_output`, `permission_denials`. [OF CC/headless] `is_error`, `num_turns`, `subtype: "success"` appear only in 3P/SDK examples [3P]; verify.
- stream-json events [OF CC/headless]:
  - `system/init`: model, tools, `mcp_servers[{name,status}]`, `mcp_server_errors[{name,type,message}]` (v2.1.219+), `plugins`, `plugin_errors` (path v2.1.283+), `capabilities[]` (v2.1.205+).
  - `system/api_retry`: `attempt`, `max_retries`, `retry_delay_ms`, `error_status`, `error` (rate_limit, overloaded, server_error, max_output_tokens, …).
  - Also `system/plugin_install`, `stream_event`, `assistant`/`user` with `parent_tool_use_id`, `permission_denied`, hook events, `prompt_suggestion`, and the final `result`.

## 4. Claude Agent SDK
- Packages: `@anthropic-ai/claude-agent-sdk` (TS) / `claude_agent_sdk` (Py, `ClaudeAgentOptions`). The TS SDK bundles the CC binary, and versions track (SDK 0.3.191 ↔ CC 2.1.191). [OF CC/agent-sdk/typescript]
- Functions: `query({prompt, options})`, `startup()`, `prewarm()`/`claim()` (alpha, v0.3.282+), `tool()`, `createSdkMcpServer({name,version,instructions,tools,alwaysLoad,timeout})`, `listSessions`, `getSessionMessages`, `getSessionInfo`, `renameSession`, `tagSession`, `resolveSettings()`. [OF CC/agent-sdk/typescript]

| Option | Default | Note |
|---|---|---|
| `settingSources` | all sources | `[]` = isolated. Py ≤0.1.59 treated `[]` as omitted [3P]. |
| `systemPrompt` | minimal prompt | `{type:'preset',preset:'claude_code',append,excludeDynamicSections}` |
| `tools` / `allowedTools` / `disallowedTools` | — / `[]` / `[]` | allowed = auto-approve only |
| `permissionMode` | undefined (may be auto) | bypass needs `allowDangerouslySkipPermissions` |
| `permissionPrompts` | `'host'` | `'none'` v2.1.259+ |
| `canUseTool` | — | only on fall-through to prompt |
| `hooks` | `{}` | callback matchers per event |
| `agents` / `agent` | — | AgentDefinition: `prompt`, `description`, `model`, `mcpServers`, `effort`, `permissionMode`, `omitClaudeMd` |
| `skills` | — | `'all'` or names; adds Skill tool |
| `resume`, `continue`, `forkSession`, `sessionId`, `persistSession` (true), `sessionStore` | — | sessions |
| `maxTurns`, `maxBudgetUsd`, `taskBudget` | — | budgets |
| `model`, `fallbackModel`, `effort`, `thinking` (`{type:'adaptive'}`) | — | |
| `outputFormat {type:'json_schema',schema}` | — | structured output |
| `includePartialMessages`, `forwardSubagentText` | false | streaming |
| `env` | `process.env` | **replaces** the env, so spread `process.env` |

- Prompt is a string or `AsyncIterable<SDKUserMessage>`. `ultracode` triggers only when `origin:{kind:"human"}`. [OF CC/agent-sdk/typescript] [OF CC/workflows]
- Env: `API_TIMEOUT_MS` (600000), `CLAUDE_CODE_MAX_RETRIES` (10, cap 15), `CLAUDE_CODE_RETRY_WATCHDOG=1`. [OF CC/agent-sdk/typescript]
- Agent teams can't be configured through SDK options. [OF CC/agent-sdk/claude-code-features]
- [ASSUMPTION] Python mirrors the TS fields in snake_case. Python ref, cost-tracking and breaking changes not fetched.

## 5. Workflows
- Available on paid plans and the API; Pro enables via `/config`. v2.1.154+ [3P]. [OF CC/workflows]
- Script: JS with top-level await. The first statement must be `export const meta = {name, description, phases?}` as a pure literal. Globals: `agent()`, `pipeline(items,...stages)` (no barrier), `parallel()` (barrier), `phase()`, `log()`, `args`. [OF CC/workflows] `workflow(name,args)` composes one level deep. [3P alexop.dev]
- `agent()` opts: `schema`, `label` [OF]; `phase`, `model`, `agentType`, `isolation:'worktree'` [3P]. Schema mismatch retries 5× (`MAX_STRUCTURED_OUTPUT_RETRIES`). A stopped or failed call returns `null`, so `.filter(Boolean)`. [OF CC/workflows]
- `Date.now()`, `Math.random()`, `new Date()` and `import()` throw; the script has no fs or shell. [OF CC/workflows]
- Limits: 16 concurrent by default (env 1–256), 5 s prefix stagger, 4,096 items per call, 1,000 agents per run, no mid-run input. [OF CC/workflows]
- Resume: completed agents replay from cache. The first changed or failed agent, and every agent started after it, rerun. Cloud sessions persist results. [OF CC/workflows]
- Usage limit: interactive subscription runs pause and continue (v2.1.271+). In `-p`/SDK/bg the agent fails. [OF CC/workflows]
- Cost: a `Large workflow` warning at >25 agents or >1.5M tokens. `workflowSizeGuideline` = `small`(<5)/`medium`(<10, default)/`large`(<50)/`unrestricted`. [OF CC/workflows]
- `-p`/SDK need an allow rule `Workflow` or `Workflow(<name>)`, auto mode, bypass, a hook or canUseTool. The keyword doesn't fire from `-p` or scheduled prompts (v2.1.210+). [OF CC/workflows]
- Save to `.claude/workflows/` or `~/.claude/workflows/` (project wins). Plugin workflows are `/<plugin>:<name>`. Edit with `/workflow-authoring`, then `/reload-skills`. Disable with `disableWorkflows` or `CLAUDE_CODE_DISABLE_WORKFLOWS=1`. [OF CC/workflows]

| Need | Pick [OF CC/workflows] |
|---|---|
| Few side tasks | subagents |
| Reusable instructions | skill |
| Peers that debate | agent team |
| Dozens–hundreds of agents, rerunnable | workflow |

## 6. Agent teams [OF CC/agent-teams]
- Enable with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Interactive only. A *named* Agent call launches a teammate without confirmation.
- Files: `~/.claude/teams/{team}/config.json` (runtime, don't edit), `…/inboxes/{agent}.json`, `~/.claude/tasks/{team}/` (persists). Team = `session-<8 chars of id>`.
- Tasks are pending/in progress/completed, with dependencies and file-locked claims. `TeammateIdle`, `TaskCreated` and `TaskCompleted` hooks block via exit 2.
- Model order: spawn prompt → definition → `CLAUDE_CODE_SUBAGENT_MODEL` → lead. `teammateDefaultModel` was removed in v2.1.234.
- Modes: `in-process` (default)/`auto`/`tmux`/`iterm2`. Teammates inherit the lead's permissions except `dontAsk`, and the lead auto-approves plans.
- Teammates load CLAUDE.md, MCP and skills but not the lead's history, so brief fully.
- Sizing: 3–5 teammates, 5–6 tasks each. No `/resume` of in-process teammates, and task status can lag.

## 7. Scheduling and unattended runs
- `/goal <condition>` (≤4,000 chars). Bare `/goal` shows status; `/goal clear` removes it. Works with `claude -p "/goal …"`. [OF CC/goal]
  - Evaluator: small fast model (`ANTHROPIC_DEFAULT_HAIKU_MODEL`). No tools, transcript only. Verdicts: not met/met/impossible. Implemented as a prompt-based Stop hook.
  - One goal per session, no cap. Stops after several no-tool turns. Auth, credit, overflow and model errors clear it. Check-ins start after 30 min, max 3 (`CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` disables). Blocked by `disableAllHooks`.
- `/loop` is time-based and survives compaction since 2.1.290 [3P ai-tldr.dev]. Ladder: `/loop` → Desktop scheduled tasks → Routines via `/schedule` (cloud) [3P vibeready.sh]. Scheduled-tasks and Routines pages not fetched.
- Background: `claude --bg "<task>"`, `claude agents --json`, `attach|logs|respawn|stop`, `claude daemon status|stop --any`. [OF CC/cli-reference]
- Opus 5.5 loop rule: keep a checklist and auto-continue at most 2–3 times. [OF PL prompting-claude-opus-5-5] (see O5 §1)

## 8. GitHub Actions (`anthropics/claude-code-action@v1`)
- Inputs: `prompt` (a skill or text; when set, the action runs on any event incl. cron), `claude_args`, `anthropic_api_key`, `settings`, `plugins`, `plugin_marketplaces`, `trigger_phrase`, `assignee_trigger`, `label_trigger`, `branch_prefix` (`claude/`). [OF GH/anthropics/claude-code-action/blob/main/docs/usage.md] [OF CC/github-actions]
- v1 removed `mode`, `direct_prompt`, `override_prompt`, `custom_instructions`, `model`, `allowed_tools`, `mcp_config`, `timeout_minutes`. [OF GH/anthropics/claude-code-action/releases/tag/v1]
- A text prompt starts with no shell or GitHub API access; grant tools via `--allowedTools`. [OF CC/github-actions] Example permissions: `contents: read`, `pull-requests: write`, `id-token: write`. [OF GH/…/docs/solutions.md]
- [ASSUMPTION] Put `--max-turns`/`--max-budget-usd` in `claude_args` for cost control.
- [IS] claude-code-action#1003: a slash-command skill prompt exited after 1 turn; status unchecked.

## 9. Observability [OF CC/monitoring-usage]
- OTel:
  - `CLAUDE_CODE_ENABLE_TELEMETRY=1` (required).
  - `OTEL_METRICS_EXPORTER` (otlp|prometheus|console|none), `OTEL_LOGS_EXPORTER`.
  - `OTEL_EXPORTER_OTLP_PROTOCOL` (grpc|http/json|http/protobuf; **no default**), `OTEL_EXPORTER_OTLP_ENDPOINT`, per-signal overrides.
  - Intervals: metrics 60000 ms, logs 5000 ms. Prometheus at `:9464/metrics`.
  - Privacy gates `OTEL_LOG_USER_PROMPTS`/`_TOOL_DETAILS`/`_RAW_API_BODIES` are off by default.
- Metrics: `claude_code.session.count`, `.lines_of_code.count`, `.commit.count`, `.pull_request.count`, `.cost.usage`, `.token.usage` (input/output/cacheRead/cacheCreation), `.code_edit_tool.decision`, `.active_time.total`. Attributes: `model`, `query_source`, `effort`, `agent.name`, `skill.name`.
- Events: `claude_code.user_prompt`, `.assistant_response`, `.tool_result`, `.api_request`; also api_error, tool_decision. The page was truncated, so the list may be incomplete.
- Transcripts are under `~/.claude/projects/`, and `--resume` takes a `.jsonl` path. [OF CC/workflows] [OF CC/cli-reference] Record schema not fetched (see O0 §3 for `output_tokens` caveat). SDK messages carry `parent_tool_use_id` and `parent_agent_id`. [OF CC/agent-sdk/typescript]

## 10. Managed Agents vs SDK vs `-p`
Managed Agents docs not fetched; that column is [ASSUMPTION].
| Criterion | `claude -p` | Agent SDK | Managed Agents |
|---|---|---|---|
| Runs | your shell/CI | your process | Anthropic-hosted |
| Permission host | prompt tool / none | `canUseTool`, hooks | unverified |
| Custom tools | MCP config | in-process SDK MCP | unverified |
| Best for | scripts, CI, evals | products, custom UIs | unverified |

## Verify live
- `claude --bare -p "hi" --output-format json | jq 'keys'` to confirm is_error, num_turns, subtype.
- `claude -p "hi" --output-format stream-json --verbose | jq -c 'select(.type=="system")'`
- `claude -p --max-turns 1 "read every file"; echo $?`
- `nproc`, then a 20-agent trivial workflow to compare concurrency with O0 §3.
- `head -c 2000 ~/.claude/projects/*/<id>.jsonl | jq -c keys` for the transcript schema.
- curl `.md` of CC/scheduled-tasks, CC/routines, CC/agent-sdk/python, PL/managed-agents/overview.

## New URLs for O1
- ✅ CC/cli-reference, CC/headless, CC/workflows, CC/agent-teams, CC/agent-sdk/typescript, CC/goal, CC/monitoring-usage, CC/statusline
- 🔗 CC/github-actions, CC/agents, CC/agent-view, CC/cross-session-messaging, CC/agent-sdk/claude-code-features, CC/agent-sdk/cost-tracking, GH/anthropics/claude-code-action docs/usage.md
