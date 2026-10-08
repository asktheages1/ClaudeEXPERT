[Part 4/5 of https://code.claude.com/docs/en/sub-agents.md, fetched 2026-10-08]

### Concurrent subagent limit

Two limits control subagent use, each with its own variable: this one stops Claude from spawning more subagents while too many are running, and the [depth limit](#let-subagents-spawn-their-own-subagents) caps how deeply subagents nest. There's no limit on the total number of subagents Claude can spawn over a session.

By default, when 20 subagents are running in a session, spawning another with the Agent tool fails with `Concurrent subagent limit reached`, and the error tells Claude not to retry. Spawning succeeds again when the running count drops below the limit. To change the limit, set [`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`](/docs/en/env-vars) to any positive whole number. Sessions with [ultracode](/docs/en/model-config#adjust-effort-level) active are exempt: the limit isn't enforced there. Requires Claude Code v2.1.217 or later.

The limit blocks only subagents Claude spawns with the Agent tool, but other runs occupy the same slots:

* An in-session fork you start with [`/subtask`](#fork-the-current-conversation) takes a slot while it runs and is never blocked by the limit.
* [Resuming a subagent](#resume-subagents) that already finished takes a fresh slot without checking the limit, so resumes can push the running count past it.

Agents that other features run, such as [workflow](/docs/en/workflows) agents and [agent team](/docs/en/agent-teams) teammates, follow their own limits instead.

### Manage subagent context

#### What loads at startup

Each subagent starts with a fresh, isolated context window. It doesn't see your conversation history, the skills you've already invoked, or the files Claude has already read. Claude composes a delegation message that summarizes the task, and the subagent works from there. The exception is a [fork](#fork-the-current-conversation), which inherits the parent conversation instead of starting fresh.

A non-fork subagent's initial context contains:

* **System prompt**: the agent's own prompt plus environment details that Claude Code appends, not the Claude Code system prompt. Custom subagents define theirs in the [markdown body](#write-subagent-files) or `prompt` field. Built-in agents have predefined prompts.
* **Task message**: the delegation prompt Claude writes when it hands off the work.
* **CLAUDE.md files**: every level of the [CLAUDE.md hierarchy](/docs/en/memory#how-claude-md-files-load) the main conversation loads, including `~/.claude/CLAUDE.md`, project rules, `CLAUDE.local.md`, managed policy files, and any [`AGENTS.md` files](/docs/en/memory#agents-md) loaded as project instructions. The built-in Explore and Plan agents skip this. A subagent whose definition sets [`omitClaudeMd`](#supported-frontmatter-fields) loads only the managed policy files, or none at all when the definition comes from [managed settings](#choose-the-subagent-scope).
* **Git status**: a snapshot Claude Code reads from your repository when the subagent starts. Absent outside a Git repository or whenever the snapshot is turned off; see [`includeGitInstructions`](/docs/en/settings-reference#includegitinstructions). Explore and Plan skip it regardless.
* **Preloaded skills**: full content of any skill named in the agent's [`skills` field](#preload-skills-into-subagents). Built-in agents don't preload skills.
* **Sibling roster**: a [system reminder](/docs/en/glossary#system-reminder) listing `main` and every other named agent in the session, each a valid `to` value for [`SendMessage`](#resume-subagents). Requires Claude Code v2.1.206 or later. The roster appears only when the subagent's tools include `SendMessage` and at least one other agent has a name, whether Claude named it when spawning it or it runs as an [agent team](/docs/en/agent-teams) teammate. It is a snapshot taken when the subagent starts, so agents named later don't appear.

To launch one of your own subagents without the user, project, and local CLAUDE.md files, set [`omitClaudeMd: true`](#supported-frontmatter-fields) in its frontmatter or `--agents` JSON.

The main conversation still has your full CLAUDE.md when it reads these subagents' results, so most rules don't need to reach the subagent itself. If a rule must, such as "ignore the `vendor/` directory," restate it in the prompt you give Claude when delegating.

You can't change which subagents receive git status. Only Explore and Plan skip it.

Some main-conversation state never reaches a non-fork subagent:

* **Output style**: a subagent runs its own system prompt, so your [output style](/docs/en/output-styles) doesn't shape its responses, except in a [fork](#fork-the-current-conversation).
* **Auto memory**: the main conversation's [auto memory](/docs/en/memory#auto-memory) isn't loaded. To give a subagent persistent memory of its own, use the [`memory` field](#enable-persistent-memory).
* **Context window size**: a subagent's context window is sized by its own model, not the parent's. Delegating to a model with a smaller window gives that subagent the smaller window.

#### Resume subagents

Each subagent invocation creates a new instance rather than continuing an earlier one. To continue an existing subagent's work instead of starting over, ask Claude to resume it.

Resumed subagents retain their full conversation history, including all previous tool calls, results, and reasoning. If the subagent spawned [background subagents of its own](#let-subagents-spawn-their-own-subagents), that history includes the results they delivered while it ran. The subagent picks up exactly where it stopped rather than starting fresh.

* When a subagent completes, Claude receives its agent ID.
* The built-in Explore and Plan agents are one-shot and return no agent ID, so Claude can't resume them. Use `general-purpose` or a custom subagent when you need to continue the work.
* When a subagent stops at its [`maxTurns`](#supported-frontmatter-fields) limit, Claude Code marks the returned output as partial, and Claude can resume the subagent to continue its work.

Claude uses the `SendMessage` tool with the agent's ID or name as the `to` field to resume it. `SendMessage` doesn't require [agent teams](/docs/en/agent-teams) to be enabled; only structured team-protocol messages such as `shutdown_request` and `plan_approval_response` do. Beyond subagents and teammates, in sessions where cross-session messaging is enabled, Claude can use the same tool to message [your other Claude Code sessions](/docs/en/cross-session-messaging), on this machine or [beyond it](/docs/en/cross-session-messaging#message-sessions-on-other-machines).

To resume a subagent, ask Claude to continue the previous work:

```text wrap theme={null}
Use the code-reviewer subagent to review the authentication module
[Agent completes]

Continue that code review and now analyze the authorization logic
[Claude resumes the subagent with full context from previous conversation]
```

When Claude sends a completed subagent a message with the `SendMessage` tool, the subagent resumes in the background without a new `Agent` invocation. The same applies to a subagent that Claude stopped with the `TaskStop` tool, once its stopped run has exited. The resumed run keeps the [tool set from where the subagent first ran](#run-subagents-in-foreground-or-background) and can keep reading the [prompt cache the original run warmed](/docs/en/prompt-caching#subagents-and-the-cache).

A subagent that has the `SendMessage` tool can send that message too. In an interactive session, the resumed agent then reports back to the subagent that resumed it, not to your main conversation. That subagent waits for the result before finishing its own work. When a subagent messages an agent it reports to, such as its own launcher, Claude Code resumes that agent without redirecting its results.

A subagent you stopped yourself, with `x` in `/tasks` or an SDK `stop_task` request, doesn't auto-resume. If Claude sends it a message, the message is refused and Claude is told the agent was cancelled.

While [that subagent's row is still in the subagent panel](#run-subagents-in-foreground-or-background), type into its transcript to resume it yourself. After that, a message from Claude can auto-resume it again.

Resuming starts a new run of the agent under the same ID, so a subagent that had already failed or completed shows as running again in the task list and in the Agent SDK's task events. Before v2.1.205, it kept showing its earlier failed or completed status while the resumed run was working.

`SendMessage` checks that a name still refers to the same agent it reached earlier in the conversation. If a newer agent has taken the name, such as a re-spawned background agent that reused it, Claude Code refuses the send rather than delivering it to the wrong agent, and the error reports which agent the name now reaches so Claude can retarget. To reach the earlier agent while it's still running, Claude addresses it by the agent ID it received when it spawned that agent. The check is scoped to the current conversation and resets on `/clear`.

A subagent treats messages from the agent that launched it as normal task direction, including mid-task course corrections, and acts on them within its own permission settings. Two limits hold regardless of who sent the message: no message from any agent counts as your approval for a pending permission prompt, and no agent message can change a subagent's permission settings, `CLAUDE.md`, or configuration. Only the permission system or your own messages can grant approval.

You can also ask Claude for the agent ID if you want to reference it explicitly, or find IDs in the transcript files at `~/.claude/projects/{project}/{sessionId}/subagents/`. Each transcript is stored as `agent-{agentId}.jsonl`.

Subagent transcripts persist independently of the main conversation:

* **Main conversation compaction**: when the main conversation compacts, subagent transcripts are unaffected. They're stored in separate files.
* **Session persistence**: subagent transcripts persist within their session. You can [resume a subagent](#resume-subagents) after restarting Claude Code by resuming the same session.
* **Automatic cleanup**: Claude Code deletes subagent transcripts after the `cleanupPeriodDays` retention period, 30 days by default, following the [retention sweep rules](/docs/en/claude-directory#cleaned-up-automatically).

#### Auto-compaction

Subagents support automatic compaction using the same logic as the main conversation. Compaction triggers under the same conditions, and `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` applies to subagents as well. See [environment variables](/docs/en/env-vars) for when the override takes effect.

Compaction events are logged in subagent transcript files:

```json theme={null}
{
  "type": "system",
  "subtype": "compact_boundary",
  "compactMetadata": {
    "trigger": "auto",
    "preTokens": 167189
  }
}
```

The `preTokens` value shows how many tokens were used before compaction occurred.

## Fork the current conversation

<Note>
  Run a forked subagent with `/subtask`, which requires Claude Code v2.1.212 or later. When [agent view is turned off](/docs/en/agent-view#turn-off-agent-view), `/subtask` isn't available and `/fork` starts the forked subagent instead; otherwise `/fork` copies the whole session into a new [background session](/docs/en/agent-view#from-inside-a-session).
</Note>

A fork is a subagent that inherits the entire conversation so far instead of starting fresh. This drops the input isolation that subagents otherwise provide: a fork sees the same system prompt, tools, model, and message history as the main session, so you can hand it a side task without re-explaining the situation. The fork's own tool calls still stay out of your conversation and only its final result comes back, so your main context window stays clean. Use a fork when any other subagent would need too much background to be useful, or when you want to try several approaches in parallel from the same starting point.

Claude starts a fork by requesting the `fork` subagent type through the Agent tool. You control whether it can with [fork mode](#turn-fork-mode-on-or-off), which is on by default in interactive sessions.

You can start a fork yourself with `/subtask` followed by a task, whether or not fork mode is on. On v2.1.161 through v2.1.211 the command is `/fork`. Claude Code names the fork from the first words of the task. The following example forks the conversation to draft test cases while you continue with the implementation in the main session:

```text wrap theme={null}
/subtask draft unit tests for the parser changes so far
```

The fork appears in a panel below your prompt and runs in the background while you keep working. When it finishes, its result arrives as a message in your main conversation. The next section covers the panel controls for watching and steering forks while they run.

### Observe and steer running forks

Running forks appear in a panel below the prompt input, with one row for the main session and one for each fork.

When a fork finishes successfully, Claude Code removes its row. Claude Code keeps the row of a fork that failed or that you stopped for 30 seconds, [the same as for any other background subagent](#run-subagents-in-foreground-or-background). Before v2.1.232, Claude Code kept a finished fork's row for 30 seconds as well.

Use these keys to interact with the panel:

| Key | Action |
| :- | :- |
| `↑` / `↓` | Move between rows |
| `Enter` | Open the selected fork's transcript and send it follow-up messages |
| `x` | Stop the selected fork if it's running, or dismiss its row if it's no longer running. On the main session row, or on the row of the fork whose transcript you opened with `Enter`, `x` types into the prompt instead |
| `Esc` | Return focus to the prompt input |

With a fork's or subagent's transcript open, follow-up messages and [skills](/docs/en/skills) go to that agent, and built-in commands go to your main conversation, with these safeguards:

* `/compact`, `/clear`, and `/rewind` act on the main conversation, so Claude Code asks you to confirm before running one of them from this view.
* `/model` and `/fast` set the main conversation's model and fast mode, not the viewed agent's, so they don't run from this view. A notice tells you why.

To have the viewed agent read your message before the work it's waiting on finishes, send it with [`Ctrl+Enter` or `Ctrl+X Ctrl+S`](/docs/en/keybindings#chat-actions). Any shell command or subagent the agent is waiting on that can move to the [background](/docs/en/tools-reference#background-commands) moves there and keeps running. When the agent is writing a response, or waiting on work that can't move to the background, it keeps going and reads your message once that finishes. Requires Claude Code v2.1.286 or later.

### How forks differ from other subagents

A fork inherits everything the main session has at the moment it spawns. Any other subagent starts fresh from its definition.

| | Fork | Non-fork subagent |
| :- | :- | :- |
| Context | Full conversation history | Fresh context with the prompt you pass |
| System prompt and tools | Same as main session | From the subagent's [definition file](#write-subagent-files), [filtered for background runs](#available-tools) |
| Model | Same as main session | From the subagent's `model` field |
| Permissions | Prompts surface in your terminal | [Prompts surface in your main session](#run-subagents-in-foreground-or-background) when running in the background |
| Prompt cache | Shared with main session | Separate cache |

Because a fork's system prompt and tool definitions are identical to the parent, its first request reuses the parent's [prompt cache](/docs/en/prompt-caching#subagents-and-the-cache). Because of that reuse, a fork costs less than a fresh subagent for tasks that need the same context.

When Claude spawns a fork through the Agent tool, it can pass `isolation: "worktree"` so the fork's file edits are written to a separate git worktree instead of your checkout. A fork can't spawn further forks.

### Turn fork mode on or off

Claude Code turns fork mode on by default in interactive sessions and leaves it off by default in [non-interactive mode](/docs/en/headless) with `-p` and in the Agent SDK. The interactive default requires Claude Code v2.1.232 or later. On earlier versions, set `CLAUDE_CODE_FORK_SUBAGENT` to `1` to turn fork mode on.

You can tell fork mode is on from how Claude Code handles the Agent tool:

* Claude can spawn a fork by requesting the `fork` subagent type. When Claude doesn't request a type, it gets the [general-purpose](#built-in-subagents) subagent, if the session still has that type. Subagents spawned from a definition, such as Explore, work as usual.
* Claude Code runs the subagents Claude spawns in the background, forks and non-fork subagents alike, apart from the [cases that stay in the foreground](#run-subagents-in-foreground-or-background). Claude Code also removes the Agent tool's `run_in_background` parameter, so Claude can't ask for the foreground.

Set the [`CLAUDE_CODE_FORK_SUBAGENT`](/docs/en/env-vars) environment variable to override the defaults:

* `1` turns fork mode on in non-interactive mode and the Agent SDK as well
* `0` turns fork mode off in every kind of session

To keep fork mode on but stop Claude from spawning forks, [deny the `fork` subagent type](#disable-specific-subagents) with an `Agent(fork)` rule. Claude Code still runs the subagents Claude spawns in the background, apart from the same [cases that stay in the foreground](#run-subagents-in-foreground-or-background).

## Example subagents

These examples demonstrate effective patterns for building subagents. Use them as starting points, or generate a customized version with Claude.

<Tip>
  **Best practices:**

  * **Design focused subagents:** each subagent should excel at one specific task
  * **Write descriptions that single out one subagent:** Claude uses the description to decide when to delegate. Make each description specific enough to route to the right subagent, and keep the combined set within the [15,000-token description budget](#understand-automatic-delegation)
  * **Limit tool access:** grant only necessary permissions for security and focus
  * **Check into version control:** share project subagents with your team
</Tip>

### Code reviewer

A read-only subagent that reviews code without modifying it. This example shows how to design a focused subagent with limited tool access that excludes Edit and Write, and a detailed prompt that specifies exactly what to look for and how to format output.

```markdown theme={null}
---
name: code-reviewer
description: Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code is clear and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Good test coverage
- Performance considerations addressed

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include specific examples of how to fix issues.
```

### Debugger

A subagent that can both analyze and fix issues. Unlike the code reviewer, this one includes Edit because fixing bugs requires modifying code. The prompt provides a clear workflow from diagnosis to verification.

```markdown theme={null}
---
name: debugger
description: Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues.
tools: Read, Edit, Bash, Grep, Glob
---

You are an expert debugger specializing in root cause analysis.

When invoked:
1. Capture error message and stack trace
2. Identify reproduction steps
3. Isolate the failure location
4. Implement minimal fix
5. Verify solution works

Debugging process:
- Analyze error messages and logs
- Check recent code changes
- Form and test hypotheses
- Add strategic debug logging
- Inspect variable states

For each issue, provide:
- Root cause explanation
- Evidence supporting the diagnosis
- Specific code fix
- Testing approach
- Prevention recommendations

Focus on fixing the underlying issue, not the symptoms.
```

### Data scientist

A domain-specific subagent for data analysis work. This example shows how to create subagents for specialized workflows outside of typical coding tasks. It explicitly sets `model: sonnet` for more capable analysis.

```markdown theme={null}
---
name: data-scientist
description: Data analysis expert for SQL queries, BigQuery operations, and data insights. Use proactively for data analysis tasks and queries.
tools: Bash, Read, Write
model: sonnet
---

You are a data scientist specializing in SQL and BigQuery analysis.

When invoked:
1. Understand the data analysis requirement
2. Write efficient SQL queries
3. Use BigQuery command line tools (bq) when appropriate
4. Analyze and summarize results
5. Present findings clearly

Key practices:
- Write optimized SQL queries with proper filters
- Use appropriate aggregations and joins
- Include comments explaining complex logic
- Format results for readability
- Provide data-driven recommendations

For each analysis:
- Explain the query approach
- Document any assumptions
- Highlight key findings
- Suggest next steps based on data

Always ensure queries are efficient and cost-effective.
```
