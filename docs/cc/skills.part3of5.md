[Part 3/5 of https://code.claude.com/docs/en/skills.md, fetched 2026-10-08]

### Add supporting files

Skills can include multiple files in their directory. This keeps `SKILL.md` focused on the essentials while letting Claude access detailed reference material only when needed. Large reference docs, API specifications, or example collections don't need to load into context every time the skill runs.

```text theme={null}
my-skill/
├── SKILL.md (required - overview and navigation)
├── reference.md (detailed API docs - loaded when needed)
├── examples.md (usage examples - loaded when needed)
└── scripts/
    └── helper.py (utility script - executed, not loaded)
```

Reference supporting files from `SKILL.md` so Claude knows what each file contains and when to load it:

```markdown theme={null}
## Additional resources

- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

<Tip>Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files.</Tip>

### Control who invokes a skill

By default, both you and Claude can invoke any skill. You can type `/skill-name` to invoke it directly, and Claude can load it automatically when relevant to your conversation. Two frontmatter fields let you restrict this:

* **`disable-model-invocation: true`**: Claude can't invoke the skill on its own. Use this for workflows with side effects or that you want to control timing, like `/commit`, `/deploy`, or `/send-slack-message`. You don't want Claude deciding to deploy because your code looks ready.

* **`user-invocable: false`**: Only Claude can invoke the skill. Use this for background knowledge that isn't actionable as a command. A `legacy-system-context` skill explains how an old system works. Claude should know this when relevant, but `/legacy-system-context` isn't a meaningful action for users to take.

This example creates a deploy skill. If you set `disable-model-invocation: true`, Claude can't run the skill automatically:

```yaml theme={null}
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---

Deploy $ARGUMENTS to production:

1. Run the test suite
2. Build the application
3. Push to the deployment target
4. Verify the deployment succeeded
```

If Claude tries anyway, Claude Code blocks the call and instructs it not to reproduce the deploy steps another way, so expect Claude to suggest running `/deploy` yourself.

Here's how the two fields affect invocation and context loading:

| Frontmatter | You can invoke | Claude can invoke | When loaded into context |
| :- | :- | :- | :- |
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | Not on its own | Description not in context, full skill loads when invoked |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

<Note>
  In a regular session, skill descriptions are loaded into context so Claude knows what's available, but full skill content only loads when invoked. [Subagents with preloaded skills](/docs/en/sub-agents#preload-skills-into-subagents) work differently: the full skill content is injected at startup.
</Note>

#### Where you write the skill's name

To run a skill directly, put its name at the start of your message. After plain text, the name gives Claude permission to run the skill but doesn't run it:

| Where | Example | What happens |
| :- | :- | :- |
| At the start of your message | `/deploy staging` | Claude Code runs the skill directly |
| After plain text, as a separate word with no punctuation attached | `go ahead and /deploy to staging` | Nothing runs directly. The name counts as your permission for that message: Claude can run the skill while it responds, and judges from your wording whether you asked it to |

To write about the skill without permitting a run, leave off the slash.

### Skill content lifecycle

When you or Claude invoke a skill, the rendered `SKILL.md` content enters the conversation as a single message and stays there across later turns. This persistence applies to the skill's instructions, not its permissions: an [`allowed-tools`](#pre-approve-tools-for-a-skill) grant clears when you send your next message. Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps.

When Claude re-invokes a skill whose rendered content is identical to the copy already in context, Claude Code adds a short note that the skill is already loaded rather than a second copy of the content. When the rendered content differs, because the arguments changed or a [dynamic context](#inject-dynamic-context) command produced new output, Claude Code appends the full content again.

[Auto-compaction](/docs/en/how-claude-code-works#when-context-fills-up) carries invoked skills forward within a token budget. When the conversation is summarized to free context, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens. Claude Code fills this budget starting from the most recently invoked skill, so older skills can be dropped entirely after compaction if you have invoked many in one session.

If Claude stops following a skill partway through a session, see [Claude stops following a skill](#claude-stops-following-a-skill).

### Pre-approve tools for a skill

The `allowed-tools` field grants permission for the listed tools during the turn that invokes the skill, so Claude can use them without prompting you for approval. The grant clears when you send your next message, even though the skill content [stays in context](#skill-content-lifecycle); invoking the skill again re-applies it for that turn. It does not restrict which tools are available: every tool remains callable, and your [permission settings](/docs/en/permissions) still govern tools that are not listed. To pre-approve tools for the whole session rather than a single turn, add allow rules to those permission settings instead.

Workspace trust doesn't gate this field. Claude Code applies a project skill's `allowed-tools` even in a `-p` run in a folder you've never trusted. A skill can grant itself broad tool access, so review the `allowed-tools` of skills checked into a repository before you run Claude Code there. To withhold the field from repository skills across your organization, see [When only managed permission rules apply](#when-only-managed-permission-rules-apply).

This skill lets Claude run git commands without per-use approval whenever you invoke it:

```yaml theme={null}
---
name: commit
description: Stage and commit the current changes
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
---
```

To remove tools from Claude's available pool while a skill is active, list them in `disallowed-tools` in the skill's frontmatter. The restriction clears when you send your next message. Like deny rules, the field can't remove [`EndConversation`](/docs/en/tools-reference#endconversation-tool-behavior) while any other tool remains. To block tools across all skills and prompts, add deny rules in your [permission settings](/docs/en/permissions).

#### When only managed permission rules apply

When your organization sets `allowManagedPermissionRulesOnly` in managed settings, Claude Code ignores `allowed-tools` in project and personal skills and in the [other sources the setting's entry lists](/docs/en/settings-reference#allowmanagedpermissionrulesonly). This requires Claude Code v2.1.282 or later.

The tools an affected skill lists go through your organization's managed rules and the normal permission prompt instead. Run `/status` to list each skill whose `allowed-tools` Claude Code has ignored so far in the session. An injected command in the skill that no managed rule allows follows [Permission checks on injected commands](#permission-checks-on-injected-commands).

### Pass arguments to skills

Both you and Claude can pass arguments when invoking a skill. Arguments are available via the `$ARGUMENTS` placeholder.

This skill fixes a GitHub issue by number. The `$ARGUMENTS` placeholder gets replaced with whatever follows the skill name:

```yaml theme={null}
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.

1. Read the issue description
2. Understand the requirements
3. Implement the fix
4. Write tests
5. Create a commit
```

When you run `/fix-issue 123`, Claude receives "Fix GitHub issue 123 following our coding standards..."

If you invoke a skill with arguments but no placeholder in the skill's content receives one, Claude Code appends `ARGUMENTS: <your input>` to the end of the skill content so Claude still sees what you typed. A placeholder is `$ARGUMENTS`, an indexed form such as `$1`, or a named argument. An indexed placeholder with no argument at its position stays as literal text and doesn't count as receiving one. A named placeholder counts even when its position has no argument, because it expands to an empty string.

You can also stack several skills at the start of one message. Typing `/write-tests /fix-issue 123` loads both skills and passes the trailing text `123` as `$ARGUMENTS` to each of them.

Claude Code expands the first skill plus up to five more stacked after it. Expansion stops at the first token that isn't an inline user-invocable skill, so a skill that runs as a [forked subagent](#run-skills-in-a-subagent), such as [`/code-review`](/docs/en/code-review#review-a-diff-locally), or one whose arguments may themselves start with a slash command, such as `/loop`, also ends the run there. That token and everything after it become the argument text for every expanded skill. `/code-review` runs as a forked subagent from v2.1.218; on earlier versions it ran inline and stacked.

To access individual arguments by position, use `$ARGUMENTS[N]` or the shorter `$N`:

```yaml theme={null}
---
name: migrate-component
description: Migrate a component from one language to another
---

Migrate the $ARGUMENTS[0] component from $ARGUMENTS[1] to $ARGUMENTS[2].
Preserve all existing behavior and tests.
```

Running `/migrate-component SearchBar JavaScript TypeScript` replaces `$ARGUMENTS[0]` with `SearchBar`, `$ARGUMENTS[1]` with `JavaScript`, and `$ARGUMENTS[2]` with `TypeScript`. The same skill using the `$N` shorthand:

```yaml theme={null}
---
name: migrate-component
description: Migrate a component from one language to another
---

Migrate the $0 component from $1 to $2.
Preserve all existing behavior and tests.
```

## Advanced patterns

### Inject dynamic context

The `` !`<command>` `` syntax runs shell commands before the skill content is sent to Claude. The command output replaces the placeholder, so Claude receives actual data, not the command itself. Claude Code doesn't run these commands on your machine when the skill is [synced from your claude.ai account](#how-claude-code-handles-the-body-of-a-synced-skill). This restriction requires Claude Code v2.1.228 or later.

This skill summarizes a pull request by fetching live PR data with the GitHub CLI. The `` !`gh pr diff` `` and other commands run first, and their output gets inserted into the prompt:

```yaml theme={null}
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

Substitution runs once over the original file. Command output is inserted as plain text and is not re-scanned for further `` !`<command>` `` placeholders, so a command cannot emit a placeholder for a later pass to expand.

The inline form is only recognized when `!` appears at the start of a line or immediately after whitespace. If `!` follows another character, as in `` KEY=!`cmd` ``, the placeholder is left as literal text and the command does not run.

For multi-line commands, use a fenced code block opened with ` ```! ` instead of the inline form:

````markdown theme={null}
## Environment
```!
node --version
git status --short
```
````

To disable this behavior for skills and custom commands from user, project, plugin, or [additional-directory](#skills-from-additional-directories) sources, set `"disableSkillShellExecution": true` in [settings](/docs/en/settings). Each command is replaced with `[shell command execution disabled by policy]` instead of being run. Bundled and managed skills are not affected. This setting is most useful in [managed settings](/docs/en/managed-settings), where users cannot override it.

Claude Code never runs these commands on your machine when they appear in skills [synced from your claude.ai account](#how-synced-skills-behave), regardless of this setting. This restriction requires Claude Code v2.1.228 or later. [How Claude Code handles the body of a synced skill](#how-claude-code-handles-the-body-of-a-synced-skill) says what Claude receives in place of the command in each kind of session.

<Tip>
  To request deeper reasoning when a skill runs, include `ultrathink` anywhere in the skill content. See [Use ultrathink for one-off deep reasoning](/docs/en/model-config#use-ultrathink-for-one-off-deep-reasoning).
</Tip>

#### How injected commands run

Claude Code picks the tool that runs a skill's injected commands from the `shell` key in the skill's frontmatter and your environment. Every combination runs the commands through the Bash tool or the PowerShell tool, except one that fails the invocation outright:

* `shell: powershell`, with the [PowerShell tool](/docs/en/tools-reference#powershell-tool) enabled: the commands run through the PowerShell tool.
* `shell: bash` when bash isn't available: the invocation fails before any command runs. This happens on Windows without Git Bash. Claude Code shows ``Skill <name> requires bash (`shell: bash` in frontmatter) but Git Bash was not found``.
* Any other combination: the commands run through the Bash tool when bash is available. When it isn't, they run through the PowerShell tool.

Either tool runs the commands the same way it runs Claude's own shell commands. They share the working directory, timeout, and output handling:

* **Working directory**: Claude Code runs each command in the session shell's current working directory. That directory moves when Claude runs `cd`. Use [`${CLAUDE_SKILL_DIR}` or `${CLAUDE_PROJECT_DIR}`](#available-string-substitutions) in paths that must resolve the same way every time.
* **stderr**: with the default `bash` shell, Claude Code merges stderr into stdout. Anything the command writes to stderr appears in the injected text.
* **Timeout**: each command runs under the Bash tool's default 2-minute [timeout](/docs/en/tools-reference#timeout-and-output-limits). When the Bash tool [moves a timed-out command to the background](/docs/en/tools-reference#foreground-commands-that-move-to-the-background), the skill still renders. The injected text reports the move and names the background task and the file collecting the command's output. When the command is one the Bash tool never auto-backgrounds, Claude Code kills it at the timeout. That failure [aborts the invocation](#when-an-injected-command-fails).
* **Output size**: output past the Bash tool's inline ceiling arrives as a file path plus a short preview, not truncated text. [Output limits](/docs/en/tools-reference#output-limits) covers the ceiling and how to adjust each boundary.

The PowerShell tool applies the same timeout, backgrounding, and output-ceiling behavior to the commands it runs. See the [PowerShell tool](/docs/en/tools-reference#powershell-tool) section for its specifics.

#### When an injected command fails

A failed command aborts the entire skill invocation, not just its own placeholder. Claude never sees the skill content for that invocation. The abort shows `Shell command failed for pattern "..."`. The error message includes the command's output under `[stderr]`.

With the default `bash` shell, any non-zero exit code counts as a failure. One carveout applies: Claude Code treats exit code 1 from [search and comparison commands](/docs/en/tools-reference#output-limits) as a normal result and injects their output. Exit codes of 2 or higher fail even for those commands.

Which commands get the carveout depends on the shell:

* Default `bash` shell: the commands listed under [Output limits](/docs/en/tools-reference#output-limits)
* `shell: powershell`, when the PowerShell tool is enabled: a [different set](/docs/en/tools-reference#shell-selection-in-settings-hooks-and-skills) that includes `grep` and `git diff` but not `find` or `diff`

With the default `bash` shell, append `|| true` to any other command you expect to exit non-zero. A check script that exits 1 when it finds problems is one example.

#### Permission checks on injected commands

Injected commands never prompt for permission while the skill renders. Claude Code checks each one against your [permission rules](/docs/en/permissions) first. A command a deny rule matches aborts the invocation with `Shell command permission check failed for pattern "..."`.

Outside [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode), when a command's permission check returns anything other than allow, Claude Code aborts the invocation with the same error. This includes a rule that would normally ask you. To keep an unmatched command from aborting here, pre-approve it with [`allowed-tools`](#pre-approve-tools-for-a-skill). If your organization restricts permission rules to managed settings, see [When only managed permission rules apply](#when-only-managed-permission-rules-apply). Deny and ask rules still override `allowed-tools`. See [Manage permissions](/docs/en/permissions#manage-permissions).

In auto mode, a command that would otherwise need your approval doesn't abort the invocation. The skill loads with an instruction telling Claude to run the command first, and Claude's own call then goes through [auto mode's usual checks](/docs/en/permission-modes#how-the-classifier-evaluates-actions). The invocation still aborts in a [forked skill](#run-skills-in-a-subagent) that sets `agent`, and in a session where Claude doesn't have the [shell tool that runs injected commands](#how-injected-commands-run).

### Run skills in a subagent

Add `context: fork` to your frontmatter when you want a skill to run in isolation. Claude Code starts a new subagent of the type set in the `agent` field and gives it the skill content as its prompt. The subagent doesn't see your conversation history, so the skill's instructions have to stand on their own.

<Note>
  Despite the name, a skill with `context: fork` doesn't run in a [fork of the current conversation](/docs/en/sub-agents#fork-the-current-conversation), which would hand the subagent everything you've discussed so far. When the task depends on that history, fork the conversation instead of using `context: fork`.
</Note>

The forked subagent runs in the [background](/docs/en/sub-agents#run-subagents-in-foreground-or-background): you keep working while it runs, and its result arrives in your conversation when it completes. Set `background: false` in the frontmatter to instead wait for the result in the turn that invoked the skill. Before v2.1.218, forked skills always blocked the turn until they finished.

Claude Code also waits for the result, even when the skill doesn't set `background: false`, in cases like these:

* In non-interactive mode, with the `-p` flag or the Agent SDK
* When you set [`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`](/docs/en/env-vars) to `1`, which also turns off all other background task features
* When you invoke a forked skill while an earlier invocation of the same skill is still running
* When a [scheduled task](/docs/en/scheduled-tasks) fires with the skill as its prompt

A backgrounded fork also runs with the [narrower tool set that applies to background subagents](/docs/en/sub-agents#run-subagents-in-foreground-or-background): the skill's subagent is a regular agent type, so the exemption for subagents that fork the conversation doesn't cover it. If your skill's steps depend on a tool outside that set, set `background: false` to keep the full tool set.

A forked skill that runs in the background applies its edits outside your session's [checkpoints](/docs/en/checkpointing), so `/rewind` doesn't undo them; use git to revert them.

<Warning>
  `context: fork` only makes sense for skills with explicit instructions. If your skill contains guidelines like "use these API conventions" without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output.
</Warning>

Skills and [subagents](/docs/en/sub-agents) work together in two directions:

| Approach | System prompt | Task | Also loads |
| :- | :- | :- | :- |
| Skill with `context: fork` | From agent type | SKILL.md content | CLAUDE.md, per the agent's [startup context](/docs/en/sub-agents#what-loads-at-startup) |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md, per the subagent's [startup context](/docs/en/sub-agents#what-loads-at-startup) |

With `context: fork`, you write the task in your skill and pick an agent type to execute it. The built-in Explore and Plan agents [skip CLAUDE.md and git status](/docs/en/sub-agents#what-loads-at-startup) to keep their context small, so a forked skill using `agent: Explore` sees only the SKILL.md content and the agent's own system prompt. For the inverse, where you define a custom subagent that uses skills as reference material, see [Subagents](/docs/en/sub-agents#preload-skills-into-subagents).

#### Example: Research skill using Explore agent

This skill runs research in a forked Explore agent. The skill content becomes the task, and the agent provides read-only tools optimized for codebase exploration:

```yaml theme={null}
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:

1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

When this skill runs:

1. A new isolated context is created
2. The subagent receives the skill content as its prompt (the "Research \$ARGUMENTS thoroughly" instructions)
3. The `agent` field determines the execution environment (model, tools, and permissions)
4. The subagent summarizes its results and returns them to your main conversation when it finishes

The `agent` field specifies which subagent configuration to use. Options include built-in agents (`Explore`, `Plan`, `general-purpose`) or any custom subagent from `.claude/agents/`. If omitted, uses `general-purpose`.
