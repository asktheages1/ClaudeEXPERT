[Part 2/2 of https://code.claude.com/docs/en/workflows.md, fetched 2026-10-08]

### Edit a saved script

To change a [workflow you saved](#save-the-workflow-for-reuse), edit its `.js` file or ask Claude to make the change. Before you edit or ask, run the `/workflow-authoring` [bundled skill](/docs/en/skills#bundled-skills) to load the script-writing reference Claude works from. The skill requires Claude Code v2.1.248 or later.

To run the edited version in the current session, run [`/reload-skills`](/docs/en/commands#all-commands) to re-read the workflow directories, then run `/<name>` again.

Claude Code applies these rules to each part of the file when it loads and runs the script:

* **`meta` block**: keep `export const meta` as the first statement, and keep it a plain object literal with a `name` and a `description`. If it contains anything other than literal values, such as a variable, a function call, or a spread, Claude Code drops `/<name>` from `/` autocomplete.
* **Body**: besides `agent()`, `pipeline()`, and `parallel()`, you can call `phase()` to group the agents that follow under a title in the progress view, call `log()` to show a message above the phases, and read the [`args`](#pass-input-to-a-saved-workflow) global. If the body has a syntax error, Claude Code reports it when you run the workflow.
* **`phases`**: if you list them in `meta`, give each entry exactly the title you pass to `phase()`. A `phase()` title with no entry gets a progress group of its own.
* **Timestamps and randomness**: Claude Code makes `Date.now()`, `Math.random()`, and a no-argument `new Date()` throw inside the script, so that a [relaunched run](#resume-after-a-pause) repeats the same `agent()` calls. Pass a timestamp in through `args` instead.

You can also edit [the script of a single run](#how-a-workflow-runs) rather than the saved copy. [Resume after a pause](#resume-after-a-pause) covers which agents run again when you relaunch an edited script. For the Workflow tool's inputs, see its entry in the [Agent SDK reference](/docs/en/agent-sdk/typescript#workflow).

## How a workflow runs

The workflow runtime executes the script in an isolated environment, separate from your conversation. Intermediate results stay in script variables instead of landing in Claude's context.

Every run writes its script to a file under your session's directory in `~/.claude/projects/`. Claude receives the path when the run starts, so you can ask for it. You can open that file to read the orchestration Claude wrote, diff it against a previous run's script, or edit it and ask Claude to relaunch from the edited version.

Claude can start a workflow only from a script file the session is already allowed to read. To run a script kept outside your working directory, add its directory with [`/add-dir`](/docs/en/permissions#working-directories) or a [Read allow rule](/docs/en/permissions#read-and-edit) first.

The runtime tracks each agent's result as the run progresses, which is what makes a run [resumable](#resume-after-a-pause) within the same session.

### Prompt caching in a fan-out

Agents in the same run can read each other's [prompt cache](/docs/en/prompt-caching#subagents-and-the-cache). Two agents that run with the same model, effort level, agent type, tools, output schema, and working directory build the same tools-and-system-prompt prefix, so an agent that starts after a matching sibling's response has begun reads that sibling's cache on its first request.

A workflow agent's requests fall outside the main conversation's [cache TTL bucket](/docs/en/prompt-caching#which-ttl-each-request-gets), so its cache holds for five minutes by default, including on a Claude subscription. To keep it for an hour, set [`subagentPromptCacheTtl`](/docs/en/settings-reference#subagentpromptcachettl) to `1h`. The API bills 1-hour cache writes at a higher rate.

When a fan-out starts several matching agents at once, Claude Code holds all but the first until the first agent's response begins, then releases the held agents together so their first requests read the shared prefix instead of each processing it uncached. Claude Code caps the hold at [`CLAUDE_CODE_WORKFLOW_PREFIX_STAGGER_MS`](/docs/en/env-vars) milliseconds, `5000` by default. Set it to `0` to disable the hold.

### Behavior and limits

The runtime applies the following constraints:

| Constraint | Why |
| :- | :- |
| No mid-run user input | A run pauses on its own only for agent permission prompts and a [usage-limit wait](#when-a-run-hits-your-usage-limit). For sign-off between stages, run each stage as its own workflow |
| No direct filesystem or shell access from the workflow itself | Agents read, write, and run commands. The script coordinates the agents |
| No module loading: a script that contains `import()` fails before the run starts | The script body is plain JavaScript. Put work that needs a library in an agent's task |
| Up to 16 concurrent agents by default, fewer when Claude Code has fewer CPUs available, including inside a CPU-limited container. To change the limit, set [`CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS`](/docs/en/env-vars#variables) to a value from 1 to 256, which requires Claude Code v2.1.269 or later | Bounds local resource use |
| In a fan-out, agents that share the first agent's prompt-cache prefix start up to 5 seconds after it by default | All but the first read the [prefix the first agent cached](#prompt-caching-in-a-fan-out) instead of each processing it uncached |
| Up to 4,096 items in a single `parallel()` or `pipeline()` call: the runtime rejects a longer list with an error | A silent cap would drop part of the workload without telling the script |
| 1,000 agents total per run | Prevents runaway loops |

## Manage runs

Once a run starts, you manage it from the `/workflows` view, or by expanding its progress line in the task panel below the input box.

When you stop a run, it stays in the task panel while any of its agents' processes are still running. If you stop it again, Claude Code re-signals those processes.

### Resume after a pause

Resume a paused run from `/workflows` by selecting it and pressing `p`. For a run you stopped, ask Claude to relaunch the workflow with the same script. If agents from the stopped run haven't exited yet, Claude Code refuses the relaunch until they have, so a second copy of those agents can't run alongside them.

Claude Code replays the run in the order agents started, and each agent either returns its saved result or runs again:

* **Completed**: returns its saved result. The first agent whose prompt differs from the previous run, because you edited the script or an earlier agent returned something different, runs again, and so does every agent after it, even ones that completed.
* **Still running when you stopped**: starts over. Stopping the whole run doesn't count any agent as failed.
* **Failed**: runs again, and so does every agent that started after it, even ones that completed. Stopping one agent alone, by selecting it in [`/workflows`](#watch-the-run) and pressing `x`, counts as failing.

That last case means a failure in the middle of a fan-out reruns work that already finished. If a script starts A, B, C, and D in that order and B fails, relaunching returns A from cache and runs B, C, and D again.

You can resume a run within the same Claude Code session. What happens to a running workflow when you leave the session depends on how you leave:

* If you [background the session](/docs/en/agent-view#what-carries-over-when-you-background), Claude Code replays the run the same way in the background session and continues it.
* If you exit Claude Code while a workflow is running and [agent view is on](/docs/en/agent-view#from-inside-a-session), the exit dialog offers `Move to background and exit`, which carries the run over the same way. If you choose `Exit and stop tasks` instead, or the option isn't offered, the run stops with the session. Claude Code keeps the run's saved results under that session's directory in `~/.claude/projects/`, so a session you resume with `claude --resume` can replay them when you ask Claude to relaunch the workflow. In a session you start fresh, Claude has no earlier run to relaunch and starts the workflow over as a new run.

In a [cloud session](/docs/en/claude-code-on-the-web), Claude Code also saves the run's results with the session's conversation history, which survives when the session's VM is reclaimed. When you [reopen such a session](/docs/en/claude-code-on-the-web#environment-expired) and ask Claude to relaunch the workflow, completed agents still return their saved results.

In local and cloud sessions alike, when Claude relaunches an earlier run and Claude Code can't find that run's saved results at all, the relaunch fails with a `nothing to resume` error instead of starting the run over on its own. Ask Claude to start the workflow over as a new run.

### When a run hits your usage limit

When an agent hits your claude.ai [usage limit](/docs/en/interactive-mode#wait-for-a-usage-limit-to-reset), the run pauses rather than failing that agent: the agents that hit the limit wait for the reset, and no new agents start. Shortly after the limit resets, the waiting agents run again and the run continues on its own. Requires Claude Code v2.1.271 or later; on earlier versions, the affected agents fail.

While the run waits, its progress line in the task panel and the [`/workflows`](#watch-the-run) header show when the limit resets.

The run pauses only when all of these hold; when one doesn't, the affected agent fails instead:

* The session is interactive and signed in with a claude.ai subscription. A run doesn't pause in [non-interactive mode](/docs/en/headless) with `claude -p` or the [Agent SDK](/docs/en/agent-sdk/overview), in a [background session](/docs/en/agent-view), or in a [Remote Control](/docs/en/remote-control) or [agent team](/docs/en/agent-teams) teammate session.
* [`autoContinueAtUsageLimit`](/docs/en/settings-reference#autocontinueatusagelimit) is on, the same setting that lets the session itself [wait for a usage limit to reset](/docs/en/interactive-mode#wait-for-a-usage-limit-to-reset). If you turn it off during a wait, the wait ends and the waiting agents fail.
* The limit resets within 24 hours. A weekly limit can reset further out.
* The run hasn't already waited twice. When it hits the limit a third time, the agent fails.

### Cost

A workflow spawns many agents, so a single run can use meaningfully more tokens than working through the same task in conversation. Runs count toward your plan's usage and rate limits.

To gauge the spend before committing to a large task, run the workflow on a small slice first: one directory instead of the whole repo, or a narrow question instead of a broad one. The `/workflows` view shows each agent's token usage as the run progresses, and you can stop the run there at any time, usually without losing completed work. [Resume after a pause](#resume-after-a-pause) covers what a stopped run keeps. The runtime's [agent caps](#behavior-and-limits) limit how many agents a single run can spawn, which bounds the cost of a runaway script. To keep runs to fewer agents, choose the `small` [size guideline](#set-a-size-guideline).

Claude Code also flags a run that grows unusually large. When a workflow schedules more than 25 agents, or its projected token total passes 1.5 million, its progress line in the task panel below the input box shows a `Large workflow` warning. The warning points you to [`/workflows`](#watch-the-run), where you can stop the run.

The warning is advisory: it doesn't pause or limit the run. Two settings change when you see it:

* If you choose a [size guideline](#set-a-size-guideline) yourself, its agent count replaces the 25-agent threshold. The built-in default guideline leaves the threshold at 25.
* Sessions with [ultracode](#let-claude-decide-with-ultracode) on don't show the warning, because turning ultracode on already opts you in to large runs.

Claude Code picks each workflow agent's model in the same [order it uses for subagents](/docs/en/sub-agents#choose-a-model). A model the script names for a stage counts as the per-invocation model in that order. When nothing else assigns one, the agent runs on your session's model.

To control the model cost:

* Check `/model` before a large run if you usually switch to a smaller model for routine work
* Ask Claude to use a smaller model for stages that don't need the strongest one when you describe the task

When your organization's [`availableModels` allowlist](/docs/en/model-config#restrict-model-selection) blocks a model the script requests for an agent, that agent runs on a substituted model instead, following the same [substitution rules as subagents](/docs/en/sub-agents#choose-a-model). The run's progress view in [`/workflows`](#watch-the-run) shows a warning naming both the requested and substituted models.

### Set a size guideline

A size guideline tells Claude how many agents to aim for when it writes a dynamic workflow. Claude Code sends the guideline to Claude as advice, not a cap, so a prompt that calls for a different scale still overrides it. Requires Claude Code v2.1.202 or later.

Each value maps to an agent count:

| Value | Agent count Claude aims for |
| :- | :- |
| `unrestricted` | No guideline: Claude sizes the workflow to the task |
| `small` | Fewer than 5 agents |
| `medium` | Fewer than 10 agents |
| `large` | Fewer than 50 agents |

The default is `medium`, or `small` when you're signed in on a Pro plan with Claude Code v2.1.271 or later. Until you choose a value, the `/config` row marks the value as the default, and the workflow's `Running in background` line names the size in force. Requires Claude Code v2.1.219 or later; earlier versions default to `unrestricted`.

To change the guideline, pick a value for the Dynamic workflow size setting in `/config`, or run `/config workflowSizeGuideline=small`. On v2.1.219 and later, you can also set the [`workflowSizeGuideline` key](/docs/en/settings-reference#workflowsizeguideline) in any settings file; that value takes precedence over `/config`, and Claude Code hides the `/config` row while a settings file provides one.

Changes take effect on the next prompt. The [runtime agent caps](#behavior-and-limits) still apply regardless of the setting.

### Turn workflows off

Workflows are available in the CLI, the Desktop app, the IDE extensions, [non-interactive mode](/docs/en/headless) with `claude -p`, and the [Agent SDK](/docs/en/agent-sdk/overview). The same disable settings apply on every surface.

To turn workflows off for yourself:

* Toggle Dynamic workflows off in `/config`. Persists across sessions.
* Set `"disableWorkflows": true` in `~/.claude/settings.json`. Persists across sessions.
* Set `CLAUDE_CODE_DISABLE_WORKFLOWS=1`. Read at startup, so it applies wherever you set it.

To turn workflows off for your whole organization, set `"disableWorkflows": true` in [managed settings](/docs/en/server-managed-settings), or use the toggle on the [Claude Code admin settings](https://claude.ai/admin-settings/claude-code) page.

When workflows are disabled:

* `/workflows`, the workflow commands, and the `/workflow-authoring` skill are unavailable
* The `ultracode` keyword no longer triggers a run, and the **Ultracode** toggle is removed from `/effort`

A run that was already in progress keeps going.

Turning workflows off also makes [ultracode](#let-claude-decide-with-ultracode) unavailable. No managed setting rules out ultracode alone: wherever it's [available](/docs/en/model-config#when-ultracode-is-available), users can turn it on with `/effort ultracode`. An [effort cap](/docs/en/model-config#organization-effort-limits) lowers the effort level a session with ultracode on runs at, but doesn't turn ultracode off.

## Related resources

* [Run agents in parallel](/docs/en/agents): compare subagents, agent view, agent teams, and workflows
* [Create custom subagents](/docs/en/sub-agents): the worker primitive workflows orchestrate
* [Manage costs](/docs/en/costs): how multi-agent runs count toward usage limits
