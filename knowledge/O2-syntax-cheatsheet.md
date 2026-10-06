# Claude Code syntax cheat sheet: hooks · agent/skill frontmatter · settings hierarchy

As of 2026-10-06 · Claude Code 2.1.289+ · sources: documentation only, nothing measured live (no [MEASURED]).

**Conventions.** `[S:x]` = [SOURCE: CC x, accessed 2026-10-06], where CC = code.claude.com/docs/en/, PL = platform.claude.com/docs/en/. `[S:x*]` = from a search-result excerpt of the same page (not a full read), medium confidence. `[ASSUMPTION]` = inference without a source. `[UNCERTAIN]` = non-doc source (blog or aggregator).

## TL;DR
- Hooks: 33 events, 5 handler types. Only exit 2 or a JSON decision blocks; exit 1 does not (A6).
- Agents: `name`+`description` required, camelCase, unknown fields silently ignored. Skills: nothing required, kebab-case (B2, C2).
- Settings: managed > CLI > local > project > user; arrays merge, scalars take the highest level; deny > ask > allow (D1–D2). Precedence differs per category (E).

---

## A. HOOKS

### A1. Where to define, scope [S:hooks]
| Location | Scope |
|---|---|
| `~/.claude/settings.json` | all projects |
| `.claude/settings.json` | project (committed) |
| `.claude/settings.local.json` | project, local |
| managed policy | organization |
| plugin `hooks/hooks.json` (optional top-level `description`) | while plugin enabled |
| skill frontmatter | from skill invocation to end of session; `once:true` removes the hook after its 1st successful run |
| agent frontmatter | only while the subagent runs; `Stop` is converted to `SubagentStop` |

- Settings, managed and plugin hooks also fire inside subagents; input then has `agent_id` and `agent_type`.
- Hooks in a project agent's frontmatter run only after the folder trust dialog is accepted (v2.1.218+); running under `-p` does not count as accepting the dialog.
- Hooks in a project skill's frontmatter also run in `-p`.
- Cloud sessions do not read `~/.claude/settings.json`.
- `disableAllHooks:true`: the value after precedence counts. Project `false` overrides user `true`. One run: `--settings '{"disableAllHooks": true}'`. Nothing outside managed can disable managed hooks. A single hook cannot be disabled.
- `allowManagedHooksOnly` (managed only): blocks user/project/local/plugin hooks; exception: plugins force-enabled in managed `enabledPlugins`. Also restricts `statusLine`, `fileSuggestion`, `subagentStatusLine`.
- `allowedHttpHookUrls` = URL allowlist for `http` hooks. `httpHookAllowedEnvVars` limits env vars interpolated into headers.
- `/hooks` is a read-only browser. File edits are picked up by a watcher.

### A2. Structure
```json
{"hooks":{"<Event>":[{"matcher":"<pattern>","hooks":[{"type":"command","command":"...","timeout":600}]}]}}
```

**Common handler fields** [S:hooks]
- `type` (required).
- `if`: one rule in permission syntax, e.g. `"Bash(git *)"`, `"Edit(*.ts)"`. No `&&`, no lists. Evaluated only on PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, PermissionDenied; on other events a hook with `if` never runs. Best-effort match: the hook runs when the command cannot be parsed.
- `timeout` in seconds. Default 600 for `command`/`http`/`mcp_tool`, 30 for `prompt`, 60 for `agent`. For command/http/mcp_tool it drops to 30 on UserPromptSubmit, PreModelSwitch, PostModelSwitch and to 10 on MessageDisplay. SessionEnd has a shared 1.5 s budget, raised to max 60 s by a longer `timeout`.
- `statusMessage`: spinner text.
- `once`: works only in skill frontmatter.

**Handler types** [S:hooks]
| `type` | Own fields |
|---|---|
| `command` | `command` (req.), `args` (exec form, no shell), `async`, `asyncRewake` (background; exit 2 wakes Claude, stderr delivered as system reminder), `shell`: `"bash"`/`"powershell"` (ignored with `args`) |
| `http` | `url` (req., POST JSON), `headers` (`$VAR`/`${VAR}`), `allowedEnvVars` (required for header vars to interpolate) |
| `mcp_tool` | `server` (req.; plugin: `plugin:<plugin>:<server>`), `tool` (req.), `input` with `${tool_input.file_path}` etc.; since v2.1.118 [UNCERTAIN: claudefa.st; official changelog confirms the feature, not the version] |
| `prompt` | `prompt` (req.; `$ARGUMENTS` = input JSON, `\$` escapes), `model`, `continueOnBlock` [S:hooks-guide] |
| `agent` | `prompt`, `model`; experimental, up to 50 tool turns [S:hooks-guide] |

- Shell form runs `sh -c`; on Windows Git Bash or PowerShell. Quote path placeholders in shell form; docs prefer exec form.
- `${user_config.*}` in plugin hooks works only in exec form (since v2.1.207); in shell form use `$CLAUDE_PLUGIN_OPTION_<KEY>`.
- **Prompt/agent hook, model reply:** `{"ok":true}` or `{"ok":false,"reason":"..."}`, optionally `"impossible":true`. On Stop/SubagentStop `reason` goes back to Claude and the turn continues; with `impossible:true` the stop is allowed. `continueOnBlock:true` (prompt only) returns `reason` to Claude instead of ending the turn. Agent hook with `ok:false` behaves like prompt with `continueOnBlock:true` and does not support `impossible` [S:hooks*, S:hooks-guide].
- Type restrictions: SessionStart accepts only `command` and `mcp_tool`. Setup accepts only `command`. PermissionRequest does not support `agent`. `mcp_tool` is skipped on SessionStart at startup and on Setup (MCP servers not ready yet) [S:hooks].
- `async`: hook does not block; its result reaches Claude on the next turn. Timeout not enforced unless `asyncRewake` [S:hooks*].

### A3. Matcher [S:hooks]
- `"*"`, `""` or absent: everything.
- Only `[A-Za-z0-9_\- ,|]`: exact string or list split on `|` or `,`.
- Any other character: unanchored JS regex, e.g. `Edit.*` also matches `NotebookEdit`; full match: `^Edit$`.
- FileChanged and StopFailure: exact match only for `[A-Za-z0-9_|]`, separator `|` only.
- MCP: `mcp__<server>__<tool>`; whole server `mcp__memory__.*`. Bare `mcp__memory` is an exact string and matches nothing.
- Plugin MCP: `mcp__plugin_<plugin>_<server>__<tool>`.
- Plugin agent: `^my-plugin:reviewer$` (contains `:`, so it takes the regex path).
- A matcher on an event without matcher support is silently ignored.

### A4. Common input fields (stdin / POST body) [S:hooks]
- `session_id`, `transcript_path` (written async, may lack the current turn), `cwd` (follows `cd` and worktree), `hook_event_name`.
- `prompt_id` (UUID; absent before the first input).
- `scratchpad_dir` (v2.1.257+).
- `permission_mode`: `default|plan|acceptEdits|auto|dontAsk|bypassPermissions`. Manual mode arrives as `"default"`. Not every event gets this field.
- `effort:{level}` in tool context; also `$CLAUDE_EFFORT`.
- In a subagent or with `--agent`: `agent_id`, `agent_type`.
- No `$CLAUDE_MODEL`; only SessionStart has `model` (not always).

### A5. Events (33) [S:hooks; * = from excerpts]
Columns: when · matcher · blocks? (exit 2 effect) · specific input · specific output.

| Event | When | Matcher | Block / exit 2 | Input | Output |
|---|---|---|---|---|---|
| SessionStart | start/resume | `startup` `resume` `clear` `compact` `fork` (fork since v2.1.214) | no; stderr to user | `source`, `model?`, `agent_type?`, `session_title?`; on resume/fork (v2.1.251+): `seconds_since_last_response`, `context_tokens`, `prompt_cache_likely_expired`, `estimated_cache_write_usd` | `additionalContext`, `initialUserMessage` (`-p`), `sessionTitle`, `watchPaths`, `reloadSkills`; plain stdout goes to context |
| Setup | `--init-only`, `-p --init`, `-p --maintenance` | `init` `maintenance` | no; ignored | `trigger` | JSON discarded |
| UserPromptSubmit | before prompt is processed, incl. automatic turns (`/loop`, background subagent report) | none | yes; prompt rejected | `prompt`, `session_title?` | `decision:"block"`, `reason` (to user), `additionalContext`, `sessionTitle`, `suppressOriginalPrompt`; stdout goes to context |
| UserPromptExpansion | expansion of a typed `/command` or MCP prompt | `command_name` | yes | `expansion_type` (`slash_command`/`mcp_prompt`), `command_name`, `command_args`, `command_source`, `prompt` | `decision`, `reason`, `additionalContext` |
| PreToolUse | before a tool (except `EndConversation`) | tool name | yes; blocks the call, stderr to Claude | `tool_name`, `tool_input`, `tool_use_id`, `mcp_server{name,source}` (v2.1.274+) | `hookSpecificOutput`: `permissionDecision` `allow|deny|ask|defer`, `permissionDecisionReason`, `updatedInput` (replaces whole input), `additionalContext` |
| PermissionRequest | when a permission prompt would show | tool name | **no**, exit 2 ignored | `tool_name`, `tool_input`, `permission_suggestions`, no `tool_use_id` | `hookSpecificOutput.decision{behavior allow|deny, updatedInput, updatedPermissions, message, interrupt}` |
| PermissionDenied | denial in auto mode | tool name | no | `tool_name`, `tool_input`, `tool_use_id`, `reason` | `hookSpecificOutput.retry:true` |
| PostToolUse | after tool success | tool name | no; stderr to Claude | `tool_input`, `tool_response`, `tool_use_id`, `duration_ms?` | `decision:"block"`+`reason`, `additionalContext`, `updatedToolOutput`, `updatedMCPToolOutput`, `classifierContext` (v2.1.236+) |
| PostToolUseFailure | tool error | tool name | no; stderr to Claude | `error`, `is_interrupt?`, `duration_ms?` | `additionalContext` |
| PostToolBatch | after a whole batch of parallel calls | none | yes; stops the loop | `tool_calls[]` (`tool_response` serialized) | `additionalContext`, `decision`, `continue:false` |
| Notification | notification | `permission_prompt` `idle_prompt` `auth_success` `elicitation_dialog` `elicitation_url_dialog` `elicitation_complete` `elicitation_response` `agent_needs_input` `agent_completed` `quota_auto_resume_fired` `quota_auto_resume_stale` `quota_auto_resume_disabled` | no; ignored | `message`, `title?`, `notification_type` | only `terminalSequence` |
| MessageDisplay | streaming assistant text | none | no; original shown | `turn_id`, `message_id`, `index`, `final`, `delta` | `displayContent` (changes display only) |
| SubagentStart | subagent spawn | agent type | no; stderr to user | `agent_id`, `agent_type` | `additionalContext` |
| SubagentStop | subagent end | agent type | yes; subagent does not finish | `stop_hook_active`, `agent_id`, `agent_type`, `agent_transcript_path`, `last_assistant_message`, `background_tasks`, `session_crons` | as Stop |
| TaskCreated | `TaskCreate` | none | yes; task rolled back | `task_id`, `task_subject`, `task_description?`, `teammate_name?`, `team_name?` | `decision:"block"`; `continue:false` ignored |
| TaskCompleted | task marked complete | none | yes | as TaskCreated | exit 2 or `continue:false` |
| Stop | end of Claude's reply | none | yes; Claude continues | `stop_hook_active`, `last_assistant_message`, `background_tasks`, `session_crons` | `decision:"block"`+`reason`, `hookSpecificOutput.additionalContext` |
| StopFailure | turn ended by API error | `rate_limit` `overloaded` `authentication_failed` `oauth_org_not_allowed` `account_on_hold` `billing_error` `invalid_request` `model_not_found` `server_error` `max_output_tokens` `cloud_credential_error` (v2.1.267+) `unknown` | no; all ignored | `error`, `error_details?`, `last_assistant_message?`* | only `terminalSequence` |
| TeammateIdle | agent-team teammate about to go idle | none | yes | (not established)* | exit 2 / `continue:false` |
| InstructionsLoaded | CLAUDE.md or `.claude/rules/*.md` loaded | `session_start` `nested_traversal` `path_glob_match` `include` `compact` | no; ignored | `file_path`, `memory_type` (User/Project/Local/Managed), `load_reason`, `globs?`, `trigger_file_path?`, `parent_file_path?` | none; does not fire for AGENTS.md read directly |
| ConfigChange | config file changed during session | `user_settings` `project_settings` `local_settings` `policy_settings` `skills` | yes (except `policy_settings`) | `source`, `file_path?`* | `decision:"block"`+`reason` |
| CwdChanged | cwd changed (e.g. `cd`) | none | no | `old_cwd`, `new_cwd`* | `watchPaths`; has `CLAUDE_ENV_FILE` |
| DirectoryAdded | `/add-dir` or SDK `register_repo_root` | `slash_command` `register_repo_root` | no; stderr to debug log | `directory`, `source`* | none |
| FileChanged | watched file changed | literal file names, e.g. `.envrc\|.env` | no | `file_path`, `event`* | `watchPaths`, `systemMessage`; has `CLAUDE_ENV_FILE` |
| WorktreeCreate | `--worktree`, `isolation:"worktree"`, background session; replaces git | none | yes; any code ≠0 = failure | `name`* | command: path on stdout; http: `hookSpecificOutput.worktreePath` |
| WorktreeRemove | worktree removal | none | yes; ≠0 = failure if dir remains | (not established) | JSON discarded |
| PreCompact | before compaction | `manual` `auto` | yes; blocks compaction | `trigger`, `custom_instructions` (null on auto)* | `decision:"block"` |
| PostCompact | after compaction | `manual` `auto` | no | `trigger`, `compact_summary`* | none |
| PreModelSwitch | before a requested (not automatic) model switch | canonical name from `to_model` | yes; timeout also blocks | `from_model`, `to_model` | `permissionDecision` allow/deny/ask, `permissionDecisionReason` or `decision:"block"` |
| PostModelSwitch | after a model switch (incl. automatic); v2.1.251+* | ditto | no | `from_model`, `to_model` | `additionalContext`; stdout goes to context |
| Elicitation | MCP server asks for input | MCP server name | yes; refusal | `mcp_server_name`, `message`, `mode?`, `url?`, `elicitation_id?`, `requested_schema?`* | `action` accept/decline/cancel, `content` |
| ElicitationResult | after user answers | MCP server name | yes; action becomes decline | `mcp_server_name`, `action`, `mode?`, `elicitation_id?`, `content?`* | `action`, `content` |
| SessionEnd | session end | `clear` `resume` `logout` `prompt_input_exit` `other` (`bypass_permissions_disabled` removed in v2.1.234) | no | `reason` | none |

- **Stop: continuation cap.** After a Stop hook blocks 8 times in a row with no tool call from Claude in between, Claude Code overrides it and ends the turn with a warning. Raise with `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` [S:hooks-guide]. Always check `stop_hook_active`.
- **PreToolUse** [S:hooks-guide]:
  - Several hooks: precedence `deny` > `defer` > `ask` > `allow`.
  - Settings deny/ask rules are evaluated independently of a hook's `allow`.
  - `defer` works only in `-p` and only with a single tool call in the turn.
  - `AskUserQuestion` and `ExitPlanMode` need `allow` together with `updatedInput`.
  - Deprecated top-level `decision:"approve"|"block"` maps to allow/deny.
  - `tool_input.file_path` is always absolute; on Windows with `\`.
  - A command/http/mcp_tool hook timeout does not block the call.
- **Since 2.1.288:** PreToolUse and PermissionRequest block the call when hook matching fails or the tool input cannot be serialized to JSON (previously the hook was skipped) [S:changelog]. Failed matching ≠ timeout: a timeout still does not block.

### A6. Exit codes and JSON [S:hooks]
- **0**: success. Stdout parsed as JSON if it starts with `{` and ends with `}`. Plain text reaches context only for UserPromptSubmit, UserPromptExpansion, SessionStart, PostModelSwitch; elsewhere it goes to the debug log. Stderr on 0 goes to the debug log only.
- **2**: block on events that support it. Message = `reason` from JSON or stderr. Not overridable even by `permissionDecision:"allow"`. Since v2.1.214 exit 2 with schema-invalid JSON still blocks.
- **Other (e.g. 1)**: non-blocking error, action proceeds. If JSON is valid, the JSON decides. Exception: Worktree*, where any ≠0 code is a failure. A wrong script path gives 127, a non-blocking error: the policy hook is then silently off.
- **HTTP**: 2xx with empty body = success. 2xx with JSON = as above. Non-2xx, connection error or plain text = non-blocking error. Only 2xx with a JSON decision blocks.
- **Universal JSON fields:**
  - `continue` (default true; `false` stops Claude and takes precedence over decisions).
  - `stopReason`.
  - `suppressOutput`: accepted, no effect.
  - `systemMessage`: message to the user.
  - `terminalSequence`: only OSC 0/1/2/9/99/777 and BEL.
- 10,000-char limit per `additionalContext`/`systemMessage`/`initialUserMessage`/stdout; overflow goes to a file and Claude gets a 2,000-char preview.
- `hookSpecificOutput` requires `hookEventName`.
- Top-level `decision:"block"`/`reason` supported by: UserPromptSubmit, UserPromptExpansion, PostToolUse, PostToolUseFailure, PostToolBatch, Stop, SubagentStop, ConfigChange, PreCompact (and TaskCreated).

### A7. Variables, concurrency, debug [S:hooks]
- `${CLAUDE_PROJECT_DIR}`: project root where the session started; does not follow worktrees.
- `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`: exported as env vars in both forms (shell and exec).
- `CLAUDE_ENV_FILE`: append `export ...` with `>>`. Available only in SessionStart, Setup, CwdChanged, FileChanged.
- `CLAUDE_CODE_REMOTE="true"` in the web environment; absent in local CLI.
- `CLAUDE_CODE_BRIDGE_SESSION_ID` (v2.1.199+, Remote Control); `CLAUDE_EFFORT`; `CLAUDE_PLUGIN_OPTION_<KEY>`.
- All matching hooks run in parallel. An identical handler from several settings files runs once; plugin and skill copies stay separate.
- Hooks run without a TTY, so `/dev/tty` is unavailable.
- Debug: `claude --debug-file <path>` or `--debug` (log in `~/.claude/debug/<session-id>.txt`) [S:hooks*].

### A8. Examples
**1. Block `rm` with exit 2 (PreToolUse)**
```json
{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","if":"Bash(rm *)","command":"${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh","args":[]}]}]}}
```
```bash
#!/bin/bash
cmd=$(jq -r '.tool_input.command')
if [[ "$cmd" == *"rm -rf"* ]]; then echo "Blocked: rm -rf" >&2; exit 2; fi
exit 0
```
**2. Same, JSON version (exit 0)**
```bash
#!/bin/bash
cmd=$(jq -r '.tool_input.command')
if echo "$cmd" | grep -q 'rm -rf'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"rm -rf blocked"}}'
fi
exit 0
```
**3. Format after Edit/Write (PostToolUse)**
```json
{"hooks":{"PostToolUse":[{"matcher":"Edit|Write","hooks":[{"type":"command","command":"jq -r '.tool_input.file_path' | xargs npx prettier --write"}]}]}}
```
**4. Context after compaction (SessionStart, matcher `compact`)**
```json
{"hooks":{"SessionStart":[{"matcher":"compact","hooks":[{"type":"command","command":"echo 'Reminder: use bun, not npm. Current branch:' $(git branch --show-current)"}]}]}}
```

**5. Stop forcing continuation while tests fail**
```bash
#!/bin/bash
input=$(cat)
[ "$(jq -r '.stop_hook_active' <<<"$input")" = "true" ] && exit 0
if ! npm test >/dev/null 2>&1; then
  jq -n '{decision:"block",reason:"Tests fail. Fix them before finishing."}'
fi
exit 0
```

---

## B. AGENT FRONTMATTER (subagent)

### B1. Locations and same-`name` precedence [S:sub-agents]
1. managed (`.claude/agents/` in the managed settings directory)
2. `--agents` (JSON, session only)
3. `.claude/agents/`: scanned recursively, walking up to the repo root; with several nested ones the closest to cwd wins
4. `~/.claude/agents/`
5. plugin `agents/`: subfolder becomes part of the ID, e.g. `my-plugin:review:security`

- Duplicates in one tree: file-system read order wins (undocumented).
- `--add-dir` directories also load `.claude/agents/`, without live reload.
- A file is skipped when: no `name`; opening `---` not on line 1; `name` starts with `-` or contains `:` (since v2.1.218); `description` missing; YAML does not parse.
- Validate: `claude plugin validate .claude/agents` (v2.1.233+).

### B2. Fields (unknown ones silently ignored; camelCase) [S:sub-agents]
| Field | Type / values | Default / notes |
|---|---|---|
| `name` | string, no `:`; file name need not match | **required**; passed to hooks as `agent_type` |
| `description` | string | **required**; total descriptions >15,000 tokens triggers a warning |
| `tools` | `Read, Grep` or YAML list; `Agent(worker, researcher)`; `mcp__srv`/`mcp__srv__*` | absent = inherits all tools available to subagents; zero resolved tools = agent does not start |
| `disallowedTools` | as `tools`; `mcp__*` | applied before `tools`; `Bash(git push *)` removes the whole tool |
| `model` | `sonnet` `opus` `haiku` `fable`, full ID, `inherit` | absent → model resolution order (B4) |
| `permissionMode` | `default` `acceptEdits` `auto` `dontAsk` `bypassPermissions` `plan` `manual` | inherited; ignored when parent is in bypass/acceptEdits/auto; `bypassPermissions` works only if parent is in it too (v2.1.267) |
| `maxTurns` | int | at the limit the result is marked partial (v2.1.246+) |
| `skills` | list | injects full content; a skill with `disable-model-invocation:true` cannot be injected |
| `mcpServers` | list: name or `{name:{type stdio/http/sse/ws, ...}}` | inline from project requires folder trust (v2.1.238) |
| `hooks` | as in settings | only while the subagent runs |
| `memory` | `user` `project` `local` | → `~/.claude/agent-memory/<n>/`, `.claude/agent-memory/<n>/`, `.claude/agent-memory-local/<n>/`; loads 200 lines/25 KB of `MEMORY.md` |
| `background` | bool | `true` = always in background |
| `effort` | `low` `medium` `high` `xhigh` `max` | inherited from session |
| `isolation` | `worktree` | none; worktree cleaned up if unchanged |
| `color` | `red` `blue` `green` `yellow` `purple` `orange` `pink` `cyan` | — |
| `initialPrompt` | string | 1st turn when the agent is the main session (`--agent`) |
| `omitClaudeMd` | bool | v2.1.271+; skips user/project/local CLAUDE.md |
| `experimental.cacheTtl` | `5m`/`1h` | v2.1.248+; files only |

- **Plugin**: ignores `permissionMode`, `hooks`, `mcpServers`, `initialPrompt` [S:plugins/components]. (see E).
- **`--agents` JSON**: does not accept `color` or `experimental` (ignored).
- `Agent(type)` in `tools` is an allowlist only for the main agent (`claude --agent`). In a subagent the parenthesized list is ignored. `Task(...)` = pre-v2.1.63 alias.
- Nesting depth: default 3 (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`). Concurrency limit: 20 (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`).

### B3. `--agents` JSON [S:sub-agents]
```bash
claude --agents '{"reviewer":{"description":"Reviews code. Use proactively.","prompt":"You are a senior reviewer.","tools":["Read","Grep","Glob"],"model":"sonnet"}}'
```
- Object key = agent name, no leading `-`. `prompt` = file body, may be empty (v2.1.281).
- In `-p` a file path may replace the JSON (v2.1.281+).

### B4. Model and effort [S:sub-agents]
- Model order: call parameter > frontmatter `model` (`inherit` = main conversation's model) > `CLAUDE_CODE_SUBAGENT_MODEL` > main conversation model. In force since v2.1.251; before, the env var won.
- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` forces the env var (v2.1.257+).
- Agent `effort` overrides session effort.

### B5. Examples
```markdown
---
name: api-developer
description: Implements API endpoints per team conventions. Use proactively for API work.
tools: Read, Edit, Write, Bash, Grep, Glob
disallowedTools: WebFetch
model: sonnet
effort: high
permissionMode: acceptEdits
maxTurns: 40
skills:
  - api-conventions
memory: project
isolation: worktree
color: blue
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint.sh"
---
You implement API endpoints. Follow the preloaded conventions.
```
```markdown
---
name: code-reviewer
description: Read-only reviewer. Use after code changes.
tools: Read, Grep, Glob
model: inherit
---
Review the diff; report Critical / Warning / Suggestion. Do not modify files.
```

---

## C. SKILLS (SKILL.md) and COMMANDS

### C1. Status of commands [S:skills]
- `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both produce `/deploy`.
- A command supports all skill frontmatter except `name` and `paths`. On a name clash the skill wins.
- In commands a subdirectory becomes a `:` prefix, e.g. `commands/frontend/component.md` → `/frontend:component`.

### C2. Frontmatter fields (all optional; kebab-case except `when_to_use`) [S:skills]
| Field | Values / effect |
|---|---|
| `name` | name in the `/` menu; default = directory name (directory also invokes the skill). No CC limits; spec/API: ≤64 chars, `[a-z0-9-]`, no XML, no words `anthropic`, `claude` [S:PL agents-and-tools/agent-skills/overview] |
| `description` | recommended; absent = 1st non-empty body line. In the skill listing `description`+`when_to_use` truncated to 1536 chars (`skillListingMaxDescChars`); spec/API: ≤1024, non-empty [S:PL] |
| `when_to_use` | appended to description, counts toward 1536 |
| `argument-hint` | e.g. `[issue-number]` |
| `arguments` | named positional arguments: space-separated string or list |
| `disable-model-invocation` | `true` = Claude does not invoke it itself, description not in context, cannot be injected into a subagent, and (since v2.1.196) cannot run from a scheduled task. Default `false` |
| `user-invocable` | `false` = hidden from `/`, only Claude invokes. Default `true` |
| `allowed-tools` | pre-approves permissions for the invoking turn only (does not restrict the tool pool); space/comma string or list. Folder trust does not block it; ignored in project and personal skills (and other sources the setting lists) when managed `allowManagedPermissionRulesOnly` is set (v2.1.282+) |
| `disallowed-tools` | removes tools from the pool until the next message |
| `model` | until end of turn; `inherit`; with `context: fork` sets the subagent model |
| `effort` | `low` `medium` `high` `xhigh` `max` |
| `context` | `fork` = separate subagent without conversation history |
| `agent` | subagent type for `fork`; default `general-purpose` |
| `background` | only with `fork`; `false` = wait for result. Default `true` (v2.1.218+) |
| `hooks` | registered on invocation, active until session end; `once` works |
| `paths` | globs (comma string or list); auto-load only when matching files are touched |
| `shell` | `bash` (default) or `powershell` for `` !`cmd` `` and the ```` ```! ```` block |
| `metadata` | arbitrary map, not interpreted by CC |
| `license`, `compatibility` | accepted, no effect; `compatibility` ≤500 chars |

- Booleans accept `yes`/`no`/`on`/`off`/`1`/`0` (v2.1.218+).
- Frontmatter is read only if `---` is on line 1. Broken YAML: skill loads without fields.
- `version` is not in the CC table, so it is ignored [ASSUMPTION].
- Outside CC (claude.ai upload, Skills API) only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` are allowed. Any other field is a hard error.

### C3. Substitutions in the body [S:skills]
- `$ARGUMENTS`: full argument string. If no placeholder is used, CC appends `ARGUMENTS: <...>` at the end.
- `$ARGUMENTS[N]` and `$N`: 0-based, shell-style quoting. Missing argument = placeholder stays literal.
- `$name` from `arguments`: missing argument = empty string.
- `\$1` gives literal text.
- Variables: `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}` (v2.1.196+), `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` (plugin only). `SKILL_DIR`/`PROJECT_DIR` are also substituted in Bash rules in `allowed-tools`.
- `` !`cmd` ``: at line start or after whitespace; runs before the content is sent to Claude. ```` ```! ```` block for multi-line commands.
  - A command error aborts the whole skill invocation.
  - The command must be allowed by rules, else abort (except in auto mode).
  - `disableSkillShellExecution` turns this off.
  - Does not work in skills synced from claude.ai.
- `@file`: includes a file (except in locally synced skills) [S:skills].
- Stacking: `/a /b 123` passes `123` to both skills; max 1+5 skills.

### C4. Structure and locations [S:skills]
```text
my-skill/
├── SKILL.md        # required; <500 lines recommended
├── reference.md    # loaded on demand
└── scripts/helper.py
```
| Location | Path |
|---|---|
| Enterprise | `<managed dir>/.claude/skills/<n>/SKILL.md` |
| Personal | `~/.claude/skills/<n>/SKILL.md` |
| Project | `.claude/skills/<n>/SKILL.md` (+ parent dirs up to repo root) |
| Nested | `<subdir>/.claude/skills/...`, loaded when a file in subdir is touched; on name clash `/apps/web:deploy` |
| `--add-dir` | `.claude/skills/` (with live reload) |
| Plugin | `<plugin>/skills/<n>/SKILL.md` → `/plugin:skill` |
| claude.ai | `/anthropic-skills:<n>` (reserved name) |

- Precedence: **enterprise > personal > project**.
- A skill shadows a built-in or bundled command of the same name, but not its aliases.
- Plugin and nested skills load alongside (namespaced).
- Reserved names: `synced`, `anthropic-skills`.

### C5. Examples
```yaml
---
name: fix-issue
description: Fix a GitHub issue by number
disable-model-invocation: true
argument-hint: "[issue] [branch]"
arguments: [issue, branch]
allowed-tools: Bash(gh issue view *) Bash(git checkout *)
---
Fix GitHub issue $issue on branch $branch.
Issue body: !`gh issue view $0`
```
```yaml
---
name: deep-research
description: Research a topic in the codebase thoroughly
context: fork
agent: Explore
background: false
---
Research $ARGUMENTS: find files with Glob/Grep, read them, summarize with file references.
```

---

## D. SETTINGS HIERARCHY

### D1. Levels (highest first) [S:settings]
1. **Managed**: server (claude.ai console), MDM/OS (macOS plist `com.anthropic.claudecode`, Windows `HKLM\SOFTWARE\Policies\ClaudeCode`, value `Settings`), files `managed-settings.json` + `managed-settings.d/*.json` [S:managed-settings*].
   - Dirs: macOS `/Library/Application Support/ClaudeCode/`, Linux/WSL `/etc/claude-code/`, Windows `C:\Program Files\ClaudeCode\`.
   - `.d/` files merged alphabetically after the main file; hidden and non-`.json` files skipped.
   - Within managed, by default the first source that delivers any policy key applies (order: server, then endpoint); `managedSourcesBehavior` changes this.
2. **CLI**: `--settings <file|json>` and flags (`--model`, `--permission-mode`, `--allowedTools`…).
3. `.claude/settings.local.json`: in a git repo it lives at the repo root (v2.1.211+), with exceptions (Windows, no git, repo root = home dir, repo root or its `.git`/`.claude` not owned by the user); in a worktree, the main checkout's root. On first write CC adds it to global git excludes.
4. `.claude/settings.json`: read from the main working directory, no lookup in parent dirs.
5. `~/.claude/settings.json` (Windows `%USERPROFILE%\.claude`; `CLAUDE_CONFIG_DIR` relocates).

- `~/.claude.json` is not settings. It holds the login session, MCP servers (user/local), per-project state (e.g. `projects["<path>"].hasTrustDialogAccepted`) and "global config" keys written by `/config`.
- Env vars are not a level in this hierarchy; precedence is per pair, e.g. `ANTHROPIC_MODEL` > key `model` [S:settings].
- Verify: `/status` (`Setting sources` line), `claude doctor`.

### D2. Merging [S:settings, S:permissions]
- **Scalars**: highest level wins.
- **Arrays** (`permissions.allow/ask/deny`, `claudeMdExcludes`, `allowedHttpHookUrls`, `sandbox.filesystem.allowWrite` etc.): merged, not replaced; deduplicated per [UNCERTAIN: FlorianBruniaux guide].
- Merge exceptions: `fallbackModel` (whole value from highest level), `modelPicker` (managed/`--settings`/user only), managed `availableModels` (no merge), `modelSettings` (per model).
- **Hooks**: add up across all levels.
- **Permissions**:
  - Evaluation deny → ask → allow; first hit decides, rule specificity is irrelevant.
  - Deny at any level blocks allow at another.
  - `--disallowedTools` adds restrictions; `--allowedTools` cannot lift a managed deny.
  - `allow` from `.claude/settings.json` and `additionalDirectories` apply only after folder trust; `deny` and `ask` apply immediately.
- **Exceptions to managed precedence** (the more restrictive value from a lower level wins): `disableClaudeAiConnectors`, `enableArtifact:false`, `isolatePeerMachines`, `remoteControlAtStartup:false`, `crossSessionInbound`, `useAutoModeDuringPlan:false`, `syncClaudeAiSkills:false`, `syncClaudeAiPlugins:false`, `maxEffortLevel`.
- `permissions.defaultMode` = `auto` or `bypassPermissions` does not work from project/local (bypass since v2.1.257).

### D3. Key keys (Scope: Any = all files) [S:settings-reference]
| Key | Syntax / notes |
|---|---|
| `$schema` | `"https://json.schemastore.org/claude-code-settings.json"` (may lag behind the CLI) |
| `permissions` | `{allow[], ask[], deny[], additionalDirectories[], defaultMode, disableBypassPermissionsMode:"disable", disableAutoMode:"disable", blockReadsOutsideWorkingDirectories}` |
| `permissions.defaultMode` | `default`/`manual`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions` |
| `env` | `{"VAR":"val"}`; telemetry vars from project/local ignored |
| `hooks` | see A2 |
| `disableAllHooks` | bool |
| `model` | alias or ID; read at session start |
| `effortLevel` | `low…max`; read at start |
| `modelSettings`, `availableModels`, `fallbackModel` | — |
| `statusLine` | `{"type":"command","command":"~/.claude/statusline.sh"}` |
| `outputStyle` | style name |
| `sandbox` | `{enabled, autoAllowBashIfSandboxed (default true), excludedCommands[], filesystem{allowWrite,denyRead,denyWrite,allowRead}, network{allowedDomains,deniedDomains,...}}` |
| `enabledPlugins` | `{"plugin@marketplace": true}`; project overrides user |
| `extraKnownMarketplaces` | requires folder trust |
| `apiKeyHelper` | command that prints the key |
| `cleanupPeriodDays` | default 30 |
| `worktree` | `{baseRef, bgIsolation, sparsePaths[], symlinkDirectories[]}` |
| `autoMode` | User/managed only: `{allow[], soft_deny[] ("$defaults"), classifyAllShell}` |
| `agent` | subagent name used as session agent (`--agent` flag wins) |
| `skillOverrides` | `{"skill":"on|name-only|user-invocable-only|off"}`; not for plugin skills |
| `disableSkillShellExecution`, `disableBundledSkills`, `claudeMdExcludes`, `autoMemoryEnabled`, `includeGitInstructions`, `attribution` | — |
| **Managed only** | `allowManagedPermissionRulesOnly`, `allowManagedHooksOnly`, `allowManagedMcpServersOnly`, `strictPluginOnlyCustomization{skills,agents,hooks,mcp}`, `strictKnownMarketplaces`, `blockedMarketplaces`, `requiredMinimumVersion`/`requiredMaximumVersion`, `claudeMd`, `forceRemoteSettingsRefresh`, `managedSourcesBehavior`, `disableSideloadFlags`, `deniedModels` |

### D4. Permission rule syntax [S:permissions]
- `Tool` = any use. `Bash(*)` = `Bash`. Deny with a bare name removes the tool from context.
- `Bash(npm run *)`:
  - space before `*` enforces a word boundary: `ls *` ≠ `ls*`;
  - trailing `:*` = ` *`;
  - trailing ` *` also matches the bare command;
  - each subcommand after `&& || ; | &` must match separately;
  - wrappers (`timeout`, `nice`, `nohup`, flagless `xargs`…) are stripped before matching.
- `Tool(param:value)`: deny/ask only, e.g. `Agent(model:opus)`, `Bash(run_in_background:true)`. Not for primary fields (`command`, `file_path`, `url`…).
- `Read/Edit(path)` in gitignore syntax:
  - `//abs` = from filesystem root;
  - `~/` = from home;
  - `/p` = relative to the settings source (project/local → main working dir; user → `~/.claude/`; `--settings` file → its dir);
  - `p` or `./p` = cwd.
- `Edit` covers all file editors. `Write(...)`, `Glob(...)`, `NotebookEdit(...)`, legacy `MultiEdit(...)` path rules are accepted but never checked, startup warning (v2.1.210+); exception: a `Glob` rule in `--allowedTools`. Use `Edit(...)`/`Read(...)`.
- `Read` deny also blocks Edit and Write on the same path.
- `!pattern` = negation, within the same source only.
- `Edit(src/**)` as allow works only in `<cwd>/src`; as deny/ask it matches `src` at any depth.
- `WebFetch(domain:example.com)`, `domain:*.example.com`, `domain:*`.
- `mcp__srv`, `mcp__srv__*`, `mcp__srv__tool`. Deny/ask accepts `mcp__*`; allow needs a literal `mcp__srv__`.
- `Agent(Explore)`, `Agent(fork)`.
- `Skill(name)` = exact name, `Skill(name *)` = prefix. Deny `Skill(skill:x)` matches all names of the skill.
- `Cd(~/code/**)`.
- `.claudeignore` does not work.

### D5. CLAUDE.md and `.claude/rules` (syntax only) [S:memory]
- Load order: managed `CLAUDE.md` (macOS `/Library/Application Support/ClaudeCode/`, Linux `/etc/claude-code/`, Windows `C:\Program Files\ClaudeCode\`) → `~/.claude/CLAUDE.md` → `./CLAUDE.md` or `./.claude/CLAUDE.md` → `./CLAUDE.local.md`.
- Files concatenate, they do not override. Parent dirs load at start, subdirs on demand (Read/Write/Edit).
- Import `@path`: relative to the file, max 4 levels, escape spaces `\ `. No import inside backticks. External import needs approval.
- `AGENTS.md` is read when there is no CLAUDE.md (v2.1.277+).
- HTML comments are stripped.
- `.claude/rules/**/*.md` and `~/.claude/rules/` (user loaded before project).
- Rule without `paths` = always loaded. With `paths` = loaded on Read/Write/Edit of a matching file. `paths` is the only frontmatter field read from a rule.
```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
---
# API rules
```

### D6. Examples
`.claude/settings.json` (project, committed):
```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["Bash(npm run *)", "Bash(git commit *)", "Edit(/src/**)"],
    "ask": ["Bash(git push *)"],
    "deny": ["Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)"],
    "defaultMode": "acceptEdits"
  },
  "env": {"NODE_ENV": "development"},
  "hooks": {"PostToolUse": [{"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/format.sh", "args": []}]}]},
  "enabledPlugins": {"formatter@acme-tools": true}
}
```
`.claude/settings.local.json` (personal):
```json
{
  "model": "claude-opus-5-5",
  "permissions": {"allow": ["Bash(docker compose *)"]},
  "claudeMdExcludes": ["**/other-team/CLAUDE.md"]
}
```

---

## E. Contradictions, ambiguities, changes after 2.1.289
- **Plugin agent:** sub-agents.md note lists 3 ignored fields, its table 4 (incl. `initialPrompt`); plugins/components lists 4. Assume 4 [S:sub-agents, S:plugins/components].
- **Reversed precedence:** skills enterprise > personal > project, agents project > user, settings local > project > user. Each category has its own order [S:skills, S:sub-agents, S:settings].
- **Hook type restrictions:** only those in A2 are documented; the full event list for prompt/agent is not confirmed [S:hooks*].
- **2.1.290** (2026-10-05, [S:changelog]): `agentId` added to the `tool.check` event of plugin hooks; a skill is found by SKILL.md `name` when it differs from the directory name (listing shows both); TeammateIdle no longer fires from its subagents or forks.
- **2.1.291** (2026-10-06, [S:changelog]): regression fixes only; no syntax changes.
- **Read deny fixes** [S:changelog]: 2.1.289 for files @-mentioned via symlink; 2.1.290 for pasted/dragged image paths and file names listed for an @-mentioned folder. Older versions leak there.

## Verify live
1. Does PreToolUse with a `command` hook that exceeds `timeout` actually let the call through (hooks.md), and does failed input serialization block it (changelog 2.1.288)?
2. Input fields of TeammateIdle, WorktreeRemove, DirectoryAdded and `event` values in FileChanged: log with `cat > /tmp/in.json`.
3. Which events accept `type:"prompt"` and `type:"agent"` (e.g. PreCompact, SubagentStart): check `/doctor` and `claude doctor` warnings.
4. Is `once:true` in an agent hook really ignored, and does `Stop` in an agent run via `--agent` (main session) stay `Stop`?
5. Does a plugin agent with `initialPrompt` run it under `claude --agent plugin:x`?
6. Are `permissions.allow` arrays from several levels deduplicated (`/permissions` shows each rule's source)?
7. Does `version` or an unknown field in SKILL.md produce a warning (`claude plugin validate .claude/skills`)?
8. Is a skill `name` with uppercase or `_` accepted locally (spec allows only `[a-z0-9-]`)?
9. Does `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` actually raise the cap?
10. Is `suppressOutput` really dead, and is a PostToolUse `systemMessage` visible in the CLI?
