[Part 3/5 of https://code.claude.com/docs/en/sub-agents.md, fetched 2026-10-08]

### Define hooks for subagents

Subagents can define [hooks](/docs/en/hooks) that run during the subagent's lifecycle. There are two ways to configure hooks:

* **In the subagent's frontmatter**: define hooks that run only while that subagent is active
* **In `settings.json`**: define session-wide hooks that also fire inside subagents. Tool events such as `PreToolUse` and `PostToolUse` fire for the subagent's tool calls the same way they do in the main conversation, and `SubagentStart` and `SubagentStop` fire when a subagent starts or finishes

Hooks from [settings files, managed policy settings, and plugins](/docs/en/hooks#hook-locations) all apply inside subagents, so a `PreToolUse` hook in `settings.json` also runs before every tool a subagent uses.

#### Hooks in subagent frontmatter

Define hooks directly in the subagent's markdown file. These hooks only run while that specific subagent is active and are cleaned up when it finishes.

<Note>
  Frontmatter hooks fire when the agent is spawned as a subagent through the Agent tool or an @-mention, and when the agent runs as the main session via [`--agent`](#invoke-subagents-explicitly) or the `agent` setting. In the main-session case they run alongside any hooks defined in [`settings.json`](/docs/en/hooks).
</Note>

To let a project-level subagent's frontmatter hooks run, accept the [workspace trust dialog](/docs/en/permissions#project-allow-rules-and-workspace-trust) for the folder that contains the agent file. Hooks from user-level subagents in `~/.claude/agents/` and from definitions you pass with `--agents` run without this step. If you added a folder with `--add-dir` from outside your trusted workspace's repository, trust that folder separately: its `.claude/agents/` hooks don't inherit the workspace's grant.

Until you trust the folder, the subagent still runs, but Claude Code skips its frontmatter hooks and logs an error to the debug log explaining how to trust the folder. This is a stricter rule than the one for hooks in settings files: trusting a parent folder isn't enough, and a `-p` session doesn't count as trusted. [What runs before you trust a folder](/docs/en/permissions#what-runs-before-you-trust-a-folder) compares the two. Before v2.1.218, frontmatter hooks could run from folders you hadn't trusted, including in non-interactive sessions.

All [hook events](/docs/en/hooks#hook-events) are supported. The most common events for subagents are:

| Event | Matcher input | When it fires |
| :- | :- | :- |
| `PreToolUse` | Tool name | Before the subagent uses a tool |
| `PostToolUse` | Tool name | After the subagent uses a tool |
| `Stop` | (none) | When the subagent finishes (converted to `SubagentStop` at runtime) |

This example validates Bash commands with the `PreToolUse` hook and runs a linter after file edits with `PostToolUse`:

```yaml theme={null}
---
name: code-reviewer
description: Review code changes with automatic linting
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

When the agent is invoked as a subagent, `Stop` hooks in frontmatter are automatically converted to `SubagentStop` events.

#### Project-level hooks for subagent events

Configure hooks in `settings.json` that respond to subagent lifecycle events in the main session.

| Event | Matcher input | When it fires |
| :- | :- | :- |
| `SubagentStart` | Agent type name | When a subagent begins execution |
| `SubagentStop` | Agent type name | When a subagent completes |

Both events support matchers to target specific agent types by name. The matcher value is the agent's frontmatter `name` for project-level and user-level subagents, or the plugin-scoped identifier such as `my-plugin:db-agent` for [plugin subagents](/docs/en/plugins/components#agents). A scoped name contains a colon, so it is evaluated as an [unanchored regular expression](/docs/en/hooks#matcher-patterns); anchor it with `^` and `$`, as in `^my-plugin:db-agent$`, to match only that agent.

This example runs a setup script only when the `db-agent` subagent starts, and a cleanup script when any subagent stops:

```json theme={null}
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "db-agent",
        "hooks": [
          { "type": "command", "command": "./scripts/setup-db-connection.sh" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": "./scripts/cleanup-db-connection.sh" }
        ]
      }
    ]
  }
}
```

See [Hooks](/docs/en/hooks) for the complete hook configuration format.

## Work with subagents

### Understand automatic delegation

Claude automatically delegates tasks based on the task description in your request, the `description` field in subagent configurations, and current context. To encourage proactive delegation, include phrases like "use proactively" in your subagent's description field.

Keep descriptions brief: Claude Code shows a startup warning when your subagents' combined descriptions pass [the 15,000-token limit](/docs/en/errors#agent-descriptions-are-over-the-15000-token-limit), and still loads every subagent.

If the subagent ships in a [plugin](/docs/en/plugins/overview), you can measure how reliably Claude delegates to it across realistic prompts instead of checking one at a time: [`claude plugin eval`](/docs/en/plugin-evals) runs each prompt with and without the plugin and scores the results.

### Invoke subagents explicitly

When automatic delegation isn't enough, you can request a subagent yourself. Three patterns escalate from a one-off suggestion to a session-wide default:

* **Natural language**: name the subagent in your prompt; Claude decides whether to delegate
* **@-mention**: guarantees the subagent runs for one task
* **Session-wide**: the whole session runs as that subagent via the `--agent` flag or the `agent` setting

For natural language, there's no special syntax. Name the subagent and Claude typically delegates:

```text wrap theme={null}
Use the test-runner subagent to fix failing tests
Have the code-reviewer subagent look at my recent changes
```

**@-mention the subagent.** Type `@` and pick the subagent from the typeahead, the same way you @-mention files. This ensures that specific subagent runs rather than leaving the choice to Claude:

```text wrap theme={null}
@"code-reviewer (agent)" look at the auth changes
```

Your full message still goes to Claude, which writes the subagent's task prompt based on what you asked. The @-mention controls which subagent Claude invokes, not what prompt it receives.

Subagents provided by an enabled [plugin](/docs/en/plugins/overview) appear in the typeahead under their scoped name, such as `my-plugin:code-reviewer` or `my-plugin:review:security` when the plugin [organizes agents into subfolders](#choose-the-subagent-scope). Named background subagents currently running in the session also appear in the typeahead, showing their status next to the name.

You can also type the mention manually without using the picker: `@agent-<name>` for local subagents, or `@agent-` followed by the scoped name for plugin subagents, for example `@agent-my-plugin:code-reviewer`. While you type this form the typeahead shows file matches rather than agents. The agent mention still resolves when you submit.

**Run the whole session as a subagent.** Pass [`--agent <name>`](/docs/en/cli-reference) to start a session where the main thread itself takes on that subagent's tool restrictions and model:

```bash theme={null}
claude --agent code-reviewer
```

Unless the agent's [prompt is empty](#choose-the-subagent-scope), a custom subagent's system prompt replaces the default Claude Code system prompt entirely, the same way [`--system-prompt`](/docs/en/cli-reference) does. `CLAUDE.md` files and project memory still load through the normal message flow, even when the agent's definition sets [`omitClaudeMd`](#supported-frontmatter-fields).

The agent name appears as `@<name>` in the startup header so you can confirm it's active.

This works with built-in and custom subagents, and the choice persists when you resume the session: Claude Code restores the agent's tool restrictions and model along with the conversation. If the agent no longer exists when you resume, the session continues with the default tools and shows a [warning naming the agent](/docs/en/errors#session-agent-no-longer-available). For the system prompt in either case, see [System prompt flags in resumed conversations](/docs/en/cli-reference#system-prompt-flags-in-resumed-conversations).

For a plugin-provided subagent, you can pass only the agent name and Claude Code finds it:

```bash theme={null}
claude --agent security-reviewer
```

If multiple plugins provide agents with the same name, pass the scoped name to disambiguate:

```bash theme={null}
claude --agent my-plugin:security-reviewer
```

If the plugin places the agent in a subfolder of its `agents/` directory, include the subfolder in the scoped name, for example `claude --agent my-plugin:review:security`.

To make it the default for every session in a project, set `agent` in `.claude/settings.json`:

```json theme={null}
{
  "agent": "code-reviewer"
}
```

The CLI flag overrides the setting if both are present.

### Run subagents in foreground or background

Subagents can run in the foreground or the background:

* **Foreground subagents** block the main conversation until complete. Permission prompts are passed through to you as they come up.
* **Background subagents** run concurrently while you continue working. When a background subagent reaches a tool call that needs permission, Claude Code surfaces the prompt in your main session and names the subagent that is asking. Approve to let the subagent continue, or press Esc to deny that one tool call without stopping the subagent.

For each subagent Claude spawns with the Agent tool, Claude Code picks foreground or background from the first of these cases that applies:

* If an in-process [agent team](/docs/en/agent-teams#limitations) teammate spawned the subagent, Claude Code runs it in the foreground. Claude Code refuses with an error to spawn a teammate's subagent whose definition sets [`background: true`](#supported-frontmatter-fields). Where [fork mode](#turn-fork-mode-on-or-off) is off and you haven't [turned background tasks off](/docs/en/env-vars), Claude Code also refuses with an error when a teammate sets `run_in_background: true`.
* If you set [`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`](/docs/en/env-vars) to `1`, Claude Code runs the subagent in the foreground, in every kind of session and whether or not fork mode is on.
* Where [fork mode](#turn-fork-mode-on-or-off) is on, as it is by default in an interactive session, Claude Code runs the subagent in the background, forks and non-fork subagents alike, and Claude can't ask for the foreground.
* Where fork mode is off, Claude runs the subagent in the background by default and in the foreground when it needs the result before continuing. Fork mode is off in [non-interactive mode](/docs/en/headless) with `-p` and in the Agent SDK unless you turn it on. To keep a particular subagent in the background even when Claude wants the result, set its frontmatter [`background`](#supported-frontmatter-fields) field to `true`.

For a skill with `context: fork`, Claude Code follows the rules in [Run skills in a subagent](/docs/en/skills#run-skills-in-a-subagent) instead, whether or not fork mode is on.

Background subagents run with a [smaller built-in tool set](#available-tools) than foreground subagents, except for conversation forks and [resumed](#resume-subagents) foreground subagents.

Background subagents surface every permission prompt in your main session. When you answer one of those prompts with a choice that lasts beyond that one tool call, such as a grant that lasts for the rest of the session, Claude Code applies your answer to the whole session, including your main conversation.

A background subagent can leave a background [Bash or PowerShell command](/docs/en/tools-reference#background-commands) [running past the end of its turn](/docs/en/interactive-mode#how-backgrounding-works). When that command ends, Claude Code sends the subagent a notification.

A background subagent's results reach Claude as a completion notification in a later turn. Claude waits for that notification before reporting the subagent's results, and if you ask about progress first, it reports that the subagent is still running. Before v2.1.211, Claude sometimes reported results for a background subagent that hadn't finished.

You can also steer this yourself:

* Where fork mode is off, ask Claude to run a task in the background or in the foreground
* Press **Ctrl+B** to background a running task

Claude Code clears a background subagent's row from the subagent panel below the prompt input in one of two ways, depending on how the subagent ended:

* When a subagent finishes successfully, Claude Code removes its row immediately and, except in [screen reader mode](/docs/en/accessibility), shows `/tasks to see subagents` in the footer for 30 seconds. During those 30 seconds, run [`/tasks`](/docs/en/commands) and press `Enter` on the subagent to open its transcript. Before v2.1.232, Claude Code kept the row for 30 seconds after the subagent finished, the same as a failed one, and showed no footer hint.
* When a subagent fails or you stop it, Claude Code keeps its row for 30 seconds. To clear the row sooner, select it and press `x`.

A background subagent that completes stays listed in [`/tasks`](/docs/en/commands), marked done and sorted below running work, for the same 30 seconds as the footer hint. Its detail view stays open when the subagent finishes. Subagents that fail or that you stop leave the list. Before v2.1.208, a completed subagent left the list the moment it finished and its detail view closed.

### Subagent names

Claude can give a subagent a name by passing a `name` parameter on the Agent tool call, and may do so on its own, without asking you first. The name makes the subagent addressable: Claude can [message or resume it by name](#resume-subagents) after it finishes.

In an interactive session with [agent teams](/docs/en/agent-teams) enabled, a subagent that Claude spawns from the main conversation with a `name` launches as a teammate instead, unless the call is a [fork](#fork-the-current-conversation) or passes `isolation` on the call itself. An `isolation` value in the subagent's frontmatter doesn't prevent it, and the teammate then runs in the main session's working directory. See [How Claude starts agent teams](/docs/en/agent-teams#how-claude-starts-agent-teams).

### API errors in subagents

When something [cuts off a subagent's response mid-stream](/docs/en/errors#the-response-above-may-be-incomplete), and the partial response contains text but no tool calls, Claude Code prompts the subagent to continue rather than ending the run. This happens in interactive sessions too. The run ends on the error only once those continuations are used up.

A subagent whose run ends on an API error, such as a usage limit or a repeated server error, reports that failure back to Claude. What Claude receives depends on where the subagent ran:

* **Foreground**: if a rate limit, overload, or server error cuts off a subagent that already produced text output, the Agent tool returns that partial output with a note that the subagent was cut off and didn't finish its task. A subagent that produced nothing, or whose only output was tool calls, fails with [`Agent terminated early due to an API error`](/docs/en/errors#agent-terminated-early-due-to-an-api-error), followed by the error detail.
* **Background**: the subagent is marked failed, and the message Claude receives when it ends names the API error and includes the subagent's last output, so partial work isn't lost.

When you configure a [fallback model chain](/docs/en/model-config#fallback-model-chains) and a subagent encounters a failure the chain covers, such as its model being unavailable, Claude Code switches the subagent to the first model in the chain that accepts the request. The subagent keeps working instead of ending on the error.

Once the underlying API error clears, ask Claude to retry the task or [resume the subagent](#resume-subagents).

### Subagent output scanning

Claude Code scans each subagent's final report before Claude reads it. A subagent may have read files, web pages, or command output you never reviewed, and text from those sources can carry instructions aimed at the main conversation. The scan never removes or rewords anything; it makes two kinds of change you may notice in a report:

* **Backslash insertion**: the scan inserts a backslash into text that imitates Claude Code's own output, such as a `<system-reminder>` tag or a line starting with `Human:` or `Assistant:`, so the imitation reads as ordinary text instead of being mistaken for part of the conversation.
* **Marker line**: the scan prepends a line starting with `[harness: subagent output matched instruction-shaped pattern(s):` when the report imitates a tag like `<system-reminder>` or mentions permission settings such as `bypassPermissions` or `--dangerously-skip-permissions`. Permission-setting mentions get the marker line, but the text itself stays as written.

The scan doesn't judge whether content is malicious, and it doesn't change what an instruction in a report can do: a tool call the report leads Claude to make still goes through the session's [permission checks](/docs/en/permissions) and [sandboxing](/docs/en/sandboxing). It isn't a substitute for [restricting what a subagent can reach](#control-subagent-capabilities).

A report that returns to Claude as the subagent's result also arrives under a header marking it as subagent output. The header states that instructions or approval claims inside the report are the subagent's words and carry no authority from you.

A [background subagent's report](#run-subagents-in-foreground-or-background) arrives inside a completion notification, which is marked as an automated event rather than a message from you.

<Note>
  Subagent output scanning requires Claude Code v2.1.210 or later.
</Note>

### Common patterns

#### Isolate high-volume operations

One of the most effective uses for subagents is isolating operations that produce large amounts of output. Running tests, fetching documentation, or processing log files can consume significant context. By delegating these to a subagent, the verbose output stays in the subagent's context while only the relevant summary returns to your main conversation.

```text wrap theme={null}
Use a subagent to run the test suite and report only the failing tests with their error messages
```

#### Run parallel research

For independent investigations, spawn multiple subagents to work simultaneously:

```text wrap theme={null}
Research the authentication, database, and API modules in parallel using separate subagents
```

Each subagent explores its area independently, then Claude synthesizes the findings. This works best when the research paths don't depend on each other.

<Warning>
  When subagents complete, their results return to your main conversation. Running many subagents that each return detailed results can consume significant context, and each subagent spends tokens of its own while it runs.
</Warning>

For work that needs to keep running in parallel or won't fit in one context window, run it in [separate sessions](/docs/en/agents) and let Claude [pass findings between them](/docs/en/cross-session-messaging).

#### Chain subagents

For multi-step workflows, ask Claude to use subagents in sequence. Each subagent completes its task and returns results to Claude, which then passes relevant context to the next subagent.

```text wrap theme={null}
Use the code-reviewer subagent to find performance issues, then use the optimizer subagent to fix them
```

### Choose between subagents and main conversation

Use the **main conversation** when:

* The task needs frequent back-and-forth or iterative refinement
* Multiple phases share significant context, such as planning, implementation, and testing
* You're making a quick, targeted change
* Latency matters. A subagent that isn't a [fork](#fork-the-current-conversation) starts fresh and may need time to gather context

Use **subagents** when:

* The task produces verbose output you don't need in your main context
* You want to enforce specific tool restrictions or permissions
* The work is self-contained and can return a summary

Consider [Skills](/docs/en/skills) instead when you want reusable prompts or workflows that run in the main conversation context rather than isolated subagent context.

For a question about something already in your conversation, use [`/btw`](/docs/en/interactive-mode#side-questions-with-%2Fbtw) instead of a subagent. It sees your full context but has no tool access, and the answer isn't added to history.

### Let subagents spawn their own subagents

By default, a subagent can spawn subagents of its own, up to three layers below the main conversation. At the depth limit, Claude Code withholds the `Agent` tool from every subagent except a [fork](#fork-the-current-conversation), so a subagent at the limit does its delegated work itself and returns one summary. A fork at the limit keeps `Agent` in its inherited tool list, but the tool returns an error instead of spawning.

Nested subagents suit a delegated task that itself splits into parallel subtasks, such as a reviewer subagent that dispatches a verifier per finding. In an interactive session, only the top-level subagent's summary returns to you and the intermediate output stays out of your main conversation: a subagent that launches background subagents waits for their results before it finishes. In [non-interactive mode](/docs/en/headless) and the Agent SDK, the launching subagent doesn't wait, so a nested background subagent that finishes after its launcher has ended reports to your main conversation instead.

To change the limit, set [`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`](/docs/en/env-vars) to the number of subagent layers you want below your main conversation. For example, this entry in [`settings.json`](/docs/en/settings) caps nesting at two layers:

```json theme={null}
{
  "env": {
    "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "2"
  }
}
```

With this value, your subagents can delegate to a second layer of their own, and that second layer can't delegate further. Set `1` to turn nesting off.

A nested subagent is configured the same way as a top-level one and resolves from the same [scopes](#choose-the-subagent-scope). To keep one subagent from spawning while nesting is on, such as a reviewer that should stay read-only, omit `Agent` from its [`tools`](#available-tools) list or add it to `disallowedTools`.

In the terminal, Claude Code shows nested subagents as a tree in the subagent panel below the prompt input and marks each row that still has descendants in the panel with a `(+N)` count of them. Open a row to see that subagent's siblings and direct children with a path back to `main`.

<Note>
  Earlier versions used different defaults:

  * **v2.1.172 through v2.1.216**: subagents could nest by default, up to five layers deep, and the limit couldn't be changed.
  * **v2.1.217 through v2.1.218**: the limit defaulted to one, so a subagent couldn't spawn its own unless you raised it; v2.1.219 raised the default to three.
</Note>
