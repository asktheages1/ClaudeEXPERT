[Part 2/5 of https://code.claude.com/docs/en/sub-agents.md, fetched 2026-10-08]

### Choose a model

The `model` field controls which model the subagent uses:

* **Model alias**: use one of the available aliases: `sonnet`, `opus`, `haiku`, or `fable`
* **Full model ID**: use a full model ID such as `claude-opus-5-5` or `claude-sonnet-5`. Accepts the same values as the `--model` flag
* **inherit**: use the same model as the main conversation

When Claude invokes a subagent, it can also pass a `model` parameter for that specific invocation. Claude Code resolves the subagent's model in this order:

1. The per-invocation `model` parameter
2. The subagent definition's `model` frontmatter, where `inherit` selects the main conversation's model
3. The [`CLAUDE_CODE_SUBAGENT_MODEL`](/docs/en/model-config#environment-variables) environment variable, when you set it to a model alias or model ID
4. The main conversation's model

If an installed [mod](/docs/en/plugins/mods/overview) sets a model in its [`agent.spawn`](/docs/en/plugins/mods/reference#subagents) hook, Claude Code uses that model in place of the per-invocation parameter.

In two cases, a family alias such as `opus` in the per-invocation parameter or the frontmatter resolves to the main conversation's model instead of the [version the alias points to](/docs/en/model-config#model-aliases):

* **The main conversation's model belongs to that family**: the subagent runs on the main conversation's exact model, including any `[1m]` suffix, so it gets the same [extended context](/docs/en/model-config#extended-context) window as the main conversation.
* **Claude Code can't tell the main conversation's model family, on [a provider other than the Anthropic API](/docs/en/third-party-integrations)**: this can happen with an [application inference profile ARN](/docs/en/amazon-bedrock#iam-configuration) on Amazon Bedrock that Claude Code hasn't resolved to a backing model. This case covers only the `opus` alias, and doesn't apply when you set [`ANTHROPIC_DEFAULT_OPUS_MODEL`](/docs/en/model-config#environment-variables), since `opus` then resolves to the model you set.

An alias in `CLAUDE_CODE_SUBAGENT_MODEL` always resolves to the version the alias points to, even when it names the main conversation's family.

Setting `CLAUDE_CODE_SUBAGENT_MODEL` by itself doesn't change the model the built-in Explore and Plan subagents run on. To change it, see [Run every subagent on one model](#run-every-subagent-on-one-model).

Before v2.1.251, `CLAUDE_CODE_SUBAGENT_MODEL` came first in this order and overrode both the per-invocation parameter and the frontmatter, including `model: inherit`.

Setting the variable to `inherit` is the same as leaving it unset. Before v2.1.196, that value forced subagents onto the main conversation's model and ignored the other sources.

Claude Code checks the per-invocation parameter, frontmatter, and environment variable values against your organization's [`availableModels`](/docs/en/model-config#restrict-model-selection) allowlist. For a blocked value, it substitutes another model:

* When the blocked value is a family alias such as `opus`, Claude Code runs the subagent on the newest version of that family the allowlist permits, following the same [substitution rules and provider scope](/docs/en/model-config#restrict-model-selection) as `/model`. Before v2.1.222, Claude Code ran the subagent on the inherited model for a blocked family alias as well.
* For any other blocked value, on providers where that substitution doesn't operate, or when the allowlist permits no version of the family, Claude Code runs the subagent on the inherited model instead. If you set `CLAUDE_CODE_SUBAGENT_MODEL`, Claude Code tries that model first, under these same rules.

In interactive sessions, Claude Code shows a warning naming the requested model and the model the subagent runs on, for either substitution.

To check which model a subagent is running on, run [`/tasks`](/docs/en/commands). Claude Code names the model on the subagent's row, and adds the [effort level](/docs/en/model-config#adjust-effort-level) when the subagent's definition, or the skill it forked from, sets [`effort`](#supported-frontmatter-fields). Requires Claude Code v2.1.242 or later.

A per-invocation `model` parameter also applies when the subagent is [resumed or sent a follow-up message](#resume-subagents), so the subagent stays on that model. Before v2.1.211, resuming dropped the per-invocation value and the subagent reverted to its definition's `model` field or, without one, the main conversation's model.

As of v2.1.198, subagents also inherit the main conversation's [extended thinking](/docs/en/model-config#extended-thinking) configuration: if thinking is on in your session, it's on for the subagent, and if it's off, it stays off. There is no per-subagent thinking setting. Before v2.1.198, subagents ran with extended thinking disabled regardless of the main conversation's setting.

#### Run every subagent on one model

`CLAUDE_CODE_SUBAGENT_MODEL` is a default, so a subagent's definition or a model Claude passes still takes precedence over it. To apply one model to every subagent, [teammate](/docs/en/agent-teams#specify-teammates-and-models), and [workflow agent](/docs/en/workflows), also set `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` to `1`. Requires Claude Code v2.1.257 or later.

* If you set both variables, subagents run on the model in `CLAUDE_CODE_SUBAGENT_MODEL`.
* If you set only `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, subagents run on the main conversation's model, except that the built-in Explore subagent runs on the [model listed for it under Built-in subagents](#built-in-subagents).

For example, to run every subagent on Haiku, set both variables in the `env` block of a [settings file](/docs/en/settings):

```json theme={null}
{
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku",
    "CLAUDE_CODE_SUBAGENT_MODEL_FORCE": "1"
  }
}
```

To check that the setting took effect, run [`/tasks`](/docs/en/commands) while a subagent is running. The subagent's row shows the model it runs on.

While `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is [on](/docs/en/env-vars), Claude Code ignores the `model` field in subagent definitions, and Claude can't pass a model when it starts a subagent. These subagents still run on the main conversation's model:

* A [fork](#fork-the-current-conversation)
* A [skill that runs in a subagent](/docs/en/skills#run-skills-in-a-subagent) with `model: inherit`

### Control subagent capabilities

You can control what subagents can do through tool access, permission modes, and conditional rules.

#### Available tools

Subagents inherit the [built-in tools](/docs/en/tools-reference) and MCP tools available in the main conversation, narrowed by two filters: the first removes a short list of tools from every subagent, and the second reduces the built-in tool set for subagents that run in the [background](#run-subagents-in-foreground-or-background), which is the default. On macOS, Linux, and WSL, a subagent can also receive the Glob and Grep tools when the main conversation doesn't have them, as described under [Glob tool behavior](/docs/en/tools-reference#glob-tool-behavior). [Forks](#fork-the-current-conversation) skip both filters and receive the main conversation's exact tool pool. The first filter removes these tools, even when listed in the `tools` field:

* `Agent`, when the subagent is at the [depth limit](#let-subagents-spawn-their-own-subagents); in a [fork](#fork-the-current-conversation) the tool stays listed but returns an error instead of spawning
* `AskUserQuestion`
* `EndConversation`, which can end only the main conversation; see [EndConversation tool behavior](/docs/en/tools-reference#endconversation-tool-behavior)
* `EnterPlanMode`
* `ExitPlanMode`, unless the subagent's [`permissionMode`](#permission-modes) is `plan`
* `ScheduleWakeup`
* `WaitForMcpServers`
* `Workflow`

The second filter applies to subagents running in the background. Apart from `Agent` and `ExitPlanMode`, which follow the first filter's conditions wherever the subagent runs, a background subagent keeps every MCP tool but only these built-in tools: `Read`, `Grep`, `Glob`, `LSP`, `Bash`, `PowerShell`, `Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`, `EnterWorktree`, `ExitWorktree`, `Monitor`, `TaskStop`, `SendMessage`, and `Artifact`, plus [`SubagentHandback`](/docs/en/tools-reference) for a subagent that reports through it. Claude Code removes every other built-in tool from a background subagent, whether inherited or listed in the `tools` field, so the same definition can resolve to different tools in the foreground and the background. The removal reports no error unless it leaves the `tools` list [resolving to nothing](/docs/en/errors#agent-would-be-spawned-with-zero-tools).

Before v2.1.280, background subagents couldn't use `LSP`.

[`ListAgents`](/docs/en/cross-session-messaging) follows these filters like any built-in tool: a foreground subagent inherits it in sessions where cross-session messaging is enabled, and a background subagent doesn't keep it.

Teammates in [agent teams](/docs/en/agent-teams) additionally keep the task tools and cron tools: `TaskCreate`, `TaskGet`, `TaskList`, `TaskUpdate`, `CronCreate`, `CronDelete`, and `CronList`.

In a [session without the Task tools](/docs/en/tools-reference#task-tool-availability), Claude Code doesn't provide the task tools to subagents either, even when the subagent runs a different model. An in-process teammate follows your session the same way, while a teammate in its own [split pane](/docs/en/agent-teams#choose-a-display-mode) runs as a separate Claude Code process, so its own model decides.

To restrict tools, use the `tools` field as an allowlist or the `disallowedTools` field as a denylist. This example uses `tools` to allow only Read, Grep, Glob, and Bash. The subagent can't edit files, write files, or use any MCP tools:

```yaml theme={null}
---
name: safe-researcher
description: Research agent with restricted capabilities
tools: Read, Grep, Glob, Bash
---
```

This example uses `disallowedTools` to inherit the subagent's tool pool except Write and Edit. The subagent keeps Bash, MCP tools, and the rest of its pool:

```yaml theme={null}
---
name: no-writes
description: Inherits the available tools except file writes
disallowedTools: Write, Edit
---
```

If both are set, `disallowedTools` is applied first, then `tools` is resolved against the remaining pool. A tool listed in both is removed.

When nothing in the `tools` list resolves to a tool, for example because every entry is misspelled or names a tool that isn't available to subagents, Claude Code usually refuses to launch the subagent and the Agent tool returns an error naming the unresolved entries; see [Agent would be spawned with zero tools](/docs/en/errors#agent-would-be-spawned-with-zero-tools) for the message and how to fix each entry. Before v2.1.208, that subagent launched with no tools and could return an empty or confusing result.

Both fields accept MCP server-level patterns in addition to exact tool names: `mcp__<server>` or `mcp__<server>__*` grants or removes every tool from the named server. In `disallowedTools`, `mcp__*` also removes every MCP tool from any server. This example removes every tool from the `github` MCP server while keeping tools from other servers and the built-in tools in its pool:

```yaml theme={null}
---
name: local-only
description: Inherits every tool except those from the github MCP server
disallowedTools: mcp__github
---
```

A `disallowedTools` entry with a specifier, such as `Bash(git push *)`, still removes the whole tool from the subagent, not only the matching commands. To keep Bash and block specific commands, add a [Bash deny rule](/docs/en/permissions#bash) such as `Bash(git push *)` to `permissions.deny` in your settings. The rule applies to the main conversation and to subagents.

#### Restrict which subagents can be spawned

When an agent runs as the main thread with `claude --agent`, it can spawn subagents using the Agent tool. To restrict which subagent types it can spawn, use `Agent(agent_type)` syntax in the `tools` field.

<Note>In version 2.1.63, the Task tool was renamed to Agent. Existing `Task(...)` references in settings and agent definitions still work as aliases.</Note>

```yaml theme={null}
---
name: coordinator
description: Coordinates work across specialized agents
tools: Agent(worker, researcher), Read, Bash
---
```

This is an allowlist: only the `worker` and `researcher` subagents can be spawned. If the agent tries to spawn any other type, the request fails and the agent sees only the allowed types in its prompt. To block specific agents while allowing all others, use [`permissions.deny`](#disable-specific-subagents) instead.

To allow spawning any subagent without restrictions, use `Agent` without parentheses:

```yaml theme={null}
tools: Agent, Read, Bash
```

If you omit `Agent` from the `tools` list entirely, the agent can't spawn any subagents with the Agent tool.

The `Agent(agent_type)` allowlist syntax applies only to an agent running as the main thread with `claude --agent`. In a subagent definition, listing `Agent` in `tools` lets that subagent spawn subagents of its own while the [depth limit](#let-subagents-spawn-their-own-subagents) allows it, but any type list inside the parentheses is ignored.

#### Scope MCP servers to a subagent

Use the `mcpServers` field to give a subagent access to [MCP](/docs/en/mcp) servers that aren't available in the main conversation. Inline servers defined here are connected when the subagent starts, subject to the [trust rule for the agent file's folder](#inline-server-trust), and disconnected when it finishes. String references share the parent session's connection.

<Note>
  The `mcpServers` field applies in both contexts where an agent file can run:

  * As a subagent, spawned through the Agent tool or an @-mention
  * As the main session, launched with [`--agent`](#invoke-subagents-explicitly) or the `agent` setting

  When the agent is the main session, inline server definitions connect at startup alongside servers from [`.mcp.json`](/docs/en/mcp) and settings files, under the same [trust rule for the agent file's folder](#inline-server-trust). In `/mcp`, a remote (HTTP or SSE) server you've used before can show the [`cached` status](/docs/en/mcp#managing-your-servers) instead; Claude Code connects it when Claude first calls one of its tools.
</Note>

Each entry in the list is either an inline server definition or a string referencing an MCP server already configured in your session:

```yaml theme={null}
---
name: browser-tester
description: Tests features in a real browser using Playwright
mcpServers:
  # Inline definition: scoped to this subagent only
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  # Reference by name: reuses an already-configured server
  - github
---

Use the Playwright tools to navigate, screenshot, and interact with pages.
```

Inline definitions use the same schema as `.mcp.json` server entries, keyed by the server name, and support the `stdio`, `http`, `sse`, and `ws` types.

To keep an MCP server out of the main conversation entirely and avoid its tool descriptions consuming context there, define it inline here rather than in `.mcp.json`. The subagent gets the tools; the parent conversation doesn't.

The MCP restrictions that apply to the main session also cover servers declared in subagent frontmatter:

* [`--strict-mcp-config`](/docs/en/cli-reference) and [`--bare`](/docs/en/cli-reference)
* [Enterprise managed MCP configuration](/docs/en/managed-mcp)
* [`allowedMcpServers` and `deniedMcpServers` policies](/docs/en/managed-mcp#policy-based-control-with-allowlists-and-denylists)

When one of these blocks a server, Claude Code skips it and shows a warning naming the blocked servers.

Managed-settings restrictions apply to every subagent regardless of how it is defined. `--strict-mcp-config` doesn't filter servers you pass inline via `--agents` or the SDK `agents` option, since those are explicit caller input.

<h4 id="inline-server-trust">
  Trust required for inline MCP servers
</h4>

Claude Code loads an [inline MCP server](#scope-mcp-servers-to-a-subagent) from an agent file in your project's `.claude/agents/` directory, or in an `--add-dir` directory's `.claude/agents/`, only after you [trust the folder the agent file came from](/docs/en/permissions#what-runs-before-you-trust-a-folder). Before v2.1.238, Claude Code loaded these servers without checking trust.

* **Trust that doesn't count**: a parent folder's trust, and the automatic trust a `-p` or SDK session gets for [hooks in settings files](/docs/en/permissions#what-runs-before-you-trust-a-folder)
* **Until then**: Claude Code skips every inline server in that agent file and writes the exact `projects["<path>"].hasTrustDialogAccepted` key for `~/.claude.json` to the debug log
* **`--add-dir` directories**: a directory outside your trusted workspace's repository needs its own trust entry, since its `.claude/agents/` files don't inherit your workspace's trust

Claude Code loads two kinds of server without checking trust for the folder the agent file came from:

* A name that references a server you already configured
* An inline server in an agent file from `~/.claude/agents/`, in one you pass with `--agents` or the SDK `agents` option, or in one that managed settings supplies

#### Permission modes

Set `permissionMode` to choose the permission mode a subagent runs in. Use the modes' config values, so Manual mode is `default`. If you leave it unset, the subagent inherits the main conversation's [permission mode](/docs/en/permission-modes).

The main conversation's permission mode decides whether Claude Code uses the value you set:

* When the main conversation is in `bypassPermissions`, `acceptEdits`, or [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode), the subagent runs in that same mode and Claude Code ignores the `permissionMode` you set. Under auto mode, the classifier evaluates the subagent's tool calls with the main conversation's block and allow rules. When the subagent finishes, the classifier also reviews its work and its final report before the report is delivered, as [How auto mode handles subagents](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) describes.
* When the main conversation is in `default`, `dontAsk`, or `plan` mode, the subagent runs in the permission mode you set, except `bypassPermissions`. A subagent that declares `bypassPermissions` keeps the main conversation's mode instead. The `bypassPermissions` exception requires Claude Code v2.1.267 or later.

`permissionMode` accepts these values, and `manual` as an alias for `default`:

| Mode | Behavior |
| :- | :- |
| `default` | Manual mode: prompts for permission |
| `acceptEdits` | Auto-accept file edits and common filesystem commands for paths in the working directory or `additionalDirectories` |
| `auto` | [Auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode): a background classifier reviews commands and protected-directory writes |
| `dontAsk` | Auto-deny permission prompts. Explicitly allowed tools still work; `AskUserQuestion`, MCP tools marked [`requiresUserInteraction`](/docs/en/mcp#require-approval-for-a-specific-tool), and connector tools [your organization set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code are denied even if you've allowed them |
| `bypassPermissions` | [Skip permission prompts](/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode). A subagent runs in this mode only when the main conversation does |
| `plan` | Plan mode (read-only exploration) |

#### Preload skills into subagents

Use the `skills` field to inject skill content into a subagent's context at startup. This gives the subagent domain knowledge without requiring it to discover and load skills during execution.

```yaml theme={null}
---
name: api-developer
description: Implement API endpoints following team conventions
skills:
  - api-conventions
  - error-handling-patterns
---

Implement API endpoints. Follow the conventions and patterns from the preloaded skills.
```

The full content of each listed skill is injected into the subagent's context at startup. This field controls which skills are preloaded, not which skills the subagent can access: without it, the subagent can still discover and invoke project, user, and plugin skills through the Skill tool during execution. To prevent a subagent from invoking skills entirely, omit `Skill` from the [`tools`](#available-tools) list or add it to `disallowedTools`.

You can't preload skills that set [`disable-model-invocation: true`](/docs/en/skills#control-who-invokes-a-skill), since preloading draws from the same set of skills Claude can invoke. This includes the bundled `/verify` skill, which Claude can't run on its own.

If a listed skill is missing or disabled, for example by your organization's policy, Claude Code skips it and logs a warning to the debug log.

<Note>
  This is the inverse of [running a skill in a subagent](/docs/en/skills#run-skills-in-a-subagent). With `skills` in a subagent, the subagent controls the system prompt and loads skill content. With `context: fork` in a skill, the skill content is injected into the agent you specify. In both cases the subagent starts without your conversation history.
</Note>

#### Enable persistent memory

The `memory` field gives the subagent a persistent directory that survives across conversations. The subagent uses this directory to build up knowledge over time, such as codebase patterns, debugging insights, and architectural decisions.

```yaml theme={null}
---
name: code-reviewer
description: Reviews code for quality and best practices
memory: user
---

You are a code reviewer. As you review code, update your agent memory with
patterns, conventions, and recurring issues you discover.
```

Choose a scope based on how broadly the memory should apply:

| Scope | Location | Use when |
| :- | :- | :- |
| `user` | `~/.claude/agent-memory/<name-of-agent>/` | the subagent should remember learnings across all projects |
| `project` | `.claude/agent-memory/<name-of-agent>/` | the subagent's knowledge is project-specific and shareable via version control |
| `local` | `.claude/agent-memory-local/<name-of-agent>/` | the subagent's knowledge is project-specific but shouldn't be checked into version control |

Subagent memory is part of [auto memory](/docs/en/memory#auto-memory): if you turn auto memory off, with the `autoMemoryEnabled` setting or `CLAUDE_CODE_DISABLE_AUTO_MEMORY`, the `memory` field has no effect and the subagent launches without the memory instructions or the memory tool access described below.

When memory is enabled:

* The subagent's system prompt includes instructions for reading and writing to the memory directory.
* The subagent's system prompt also includes the first 200 lines or 25KB of `MEMORY.md` in the memory directory, whichever comes first, with instructions to curate `MEMORY.md` if it exceeds that limit.
* Read, Write, and Edit tools are automatically enabled so the subagent can manage its memory files.

##### Persistent memory tips

* `project` is the recommended default scope. It makes subagent knowledge shareable via version control.
* Ask the subagent to consult its memory before starting work: "Review this PR, and check your memory for patterns you've seen before."
* Ask the subagent to update its memory after completing a task: "Now that you're done, save what you learned to your memory." Over time, this builds a knowledge base that makes the subagent more effective.
* Include memory instructions directly in the subagent's markdown file so it proactively maintains its own knowledge base:

  ```markdown theme={null}
  Update your agent memory as you discover codepaths, patterns, library
  locations, and key architectural decisions. This builds up institutional
  knowledge across conversations. Write concise notes about what you found
  and where.
  ```

#### Conditional rules with hooks

For more dynamic control over tool usage, use `PreToolUse` hooks to validate operations before they execute. This is useful when you need to allow some operations of a tool while blocking others.

This example creates a subagent that only allows read-only database queries. The `PreToolUse` hook runs the script specified in `command` before each Bash command executes:

```yaml theme={null}
---
name: db-reader
description: Execute read-only database queries
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
```

Claude Code [passes hook input as JSON](/docs/en/hooks#pretooluse-input) via stdin to hook commands. The validation script reads this JSON, extracts the Bash command, and [exits with code 2](/docs/en/hooks#exit-code-2-behavior-per-event) to block write operations:

```bash theme={null}
#!/bin/bash
# ./scripts/validate-readonly-query.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block SQL write operations (case-insensitive)
if echo "$COMMAND" | grep -iE '\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE)\b' > /dev/null; then
  echo "Blocked: Only SELECT queries are allowed" >&2
  exit 2
fi

exit 0
```

On macOS and Linux, make the script executable, or the hook fails instead of blocking anything:

```bash theme={null}
chmod +x ./scripts/validate-readonly-query.sh
```

To test the rule, ask the subagent to run an `UPDATE` statement: the script exits with code 2, Claude Code blocks the command, and the subagent sees the `Blocked: Only SELECT queries are allowed` message.

See [Hook input](/docs/en/hooks#pretooluse-input) for the complete input schema and [exit codes](/docs/en/hooks#exit-code-output) for how exit codes affect behavior. On Windows, write hook scripts in PowerShell and add `shell: powershell` to the hook entry as shown in [running hooks in PowerShell](/docs/en/hooks#windows-powershell-tool).

#### Disable specific subagents

You can prevent Claude from using specific subagents by adding them to the `deny` array in your [settings](/docs/en/settings-reference#permission-settings). Use the format `Agent(subagent-name)` where `subagent-name` matches the subagent's name field.

```json theme={null}
{
  "permissions": {
    "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
  }
}
```

This works for both built-in and custom subagents. You can also use the `--disallowedTools` CLI flag:

```bash theme={null}
claude --disallowedTools "Agent(Explore)"
```

See [Permissions documentation](/docs/en/permissions#tool-specific-permission-rules) for more details on permission rules.
