[Part 1/5 of https://code.claude.com/docs/en/sub-agents.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Create custom subagents

> Create and use specialized AI subagents in Claude Code for task-specific workflows and improved context management.

Subagents are specialized AI assistants that handle specific types of tasks. Use one when a side task would flood your main conversation with search results, logs, or file contents you won't reference again: the subagent does that work in its own context and returns only the summary. Define a custom subagent when you keep spawning the same kind of worker with the same instructions.

Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions. It also sends its own requests, which count toward the same [usage limits](/docs/en/costs#plan-usage-breakdown) as your main conversation. When Claude encounters a task that matches a subagent's description, it delegates to that subagent, which works independently and returns results. To see the context savings in practice, the [context window visualization](/docs/en/context-window) walks through a session where a subagent handles research in its own separate window.

<Note>
  Subagents work within a single session. To run many independent sessions in parallel and monitor them from one place, see [background agents](/docs/en/agent-view). For separate sessions that pass messages to each other, see [cross-session messaging](/docs/en/cross-session-messaging). For a coordinated team of sessions Claude spawns and supervises, see [agent teams](/docs/en/agent-teams).
</Note>

Subagents help you:

* **Preserve context** by keeping exploration and implementation out of your main conversation
* **Enforce constraints** by limiting which tools a subagent can use
* **Reuse configurations** across projects with user-level subagents
* **Specialize behavior** with focused system prompts for specific domains
* **Control costs** by routing tasks to faster, lower-cost models like Haiku

Claude uses each subagent's description to decide when to delegate tasks. When you create a subagent, write a clear description so Claude knows when to use it.

Those descriptions take up context, so keep them short. When the combined descriptions of your subagents, except the built-in ones, exceed 15,000 tokens, Claude Code shows a [warning at startup with the total token count](/docs/en/errors#agent-descriptions-are-over-the-15000-token-limit). Trim the `description` fields of your subagents, and move detail into each subagent's system prompt, which only loads when that subagent runs.

## Built-in subagents

Claude Code includes built-in subagents that Claude automatically uses when appropriate. Each inherits the parent conversation's permission rules; most run with a restricted tool set.

Explore and Plan skip your CLAUDE.md files and the git status snapshot to keep research fast and inexpensive. Every other built-in and [custom subagent](#configure-subagents) loads both, unless its definition sets the [`omitClaudeMd`](#supported-frontmatter-fields) field to skip the user, project, and local CLAUDE.md files. For the full breakdown of what reaches a subagent, see [what loads at startup](#what-loads-at-startup).

<Tabs>
  <Tab title="Explore">
    A fast, read-only agent optimized for searching and analyzing codebases.

    * **Model**: the main conversation's model. When the main conversation runs Fable, Explore's model depends on how you connect:
      * With a Claude subscription, an Anthropic Console account, or an [LLM gateway](/docs/en/llm-gateway) reached through `ANTHROPIC_BASE_URL`, Explore runs on the Opus model that the [`opus` alias](/docs/en/model-config#model-aliases) resolves to.
      * On Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, [Claude Platform on AWS](/docs/en/claude-platform-on-aws), or a [Claude apps gateway](/docs/en/claude-apps-gateway), Explore stays on the main conversation's model.
    * **Tools**: read-only tools; Write and Edit are denied
    * **Purpose**: file discovery, code search, codebase exploration

    A [user or project subagent](#choose-the-subagent-scope) named `Explore` overrides the built-in and keeps its own `model` field, so define one with `model: haiku` to run exploration on a lower-cost model. To force one model onto every subagent, Explore included, see [Run every subagent on one model](#run-every-subagent-on-one-model).

    Claude delegates to Explore when it needs to search or understand a codebase without making changes. This keeps exploration results out of your main conversation context.

    When invoking Explore, Claude specifies a thoroughness level: **quick** for targeted lookups, **medium** for balanced exploration, or **very thorough** for comprehensive analysis.
  </Tab>

  <Tab title="Plan">
    A research agent used during [plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode) to gather context before presenting a plan.

    * **Model**: inherits from the main conversation, unless you set `CLAUDE_CODE_SUBAGENT_MODEL` and [force it onto every subagent](#run-every-subagent-on-one-model)
    * **Tools**: read-only tools; Write and Edit are denied
    * **Purpose**: codebase research for planning

    When you're in plan mode and Claude needs to understand your codebase, it delegates research to the Plan subagent so that exploration output stays in a separate context window while the main conversation remains read-only.
  </Tab>

  <Tab title="General-purpose">
    A capable agent for complex, multi-step tasks that require both exploration and action.

    * **Model**: the [`CLAUDE_CODE_SUBAGENT_MODEL`](#choose-a-model) model if you set one and nothing assigns a model another way, otherwise the main conversation's model; [Choose a model](#choose-a-model) states the full order, and [Run every subagent on one model](#run-every-subagent-on-one-model) shows how to make the variable override those sources
    * **Tools**: every tool [available to subagents](#available-tools)
    * **Purpose**: complex research, multi-step operations, code modifications

    Claude delegates to general-purpose when the task requires both exploration and modification, complex reasoning to interpret results, or multiple dependent steps.
  </Tab>

  <Tab title="Other">
    Claude Code includes additional helper agents for specific tasks. These are typically invoked automatically, so you don't need to use them directly.

    | Agent | Model | When Claude uses it |
    | :- | :- | :- |
    | claude | None of its own; follows the [model order](#choose-a-model) when Claude spawns it as a subagent | When a task doesn't fit a more specialized agent. A catch-all with every tool [available to subagents](#available-tools). Also the default agent for a dispatched [background session](/docs/en/agent-view); [which permission mode it starts in](/docs/en/agent-view#permission-mode-model-and-effort) depends on how the session was started |
    | statusline-setup | Sonnet | When you run `/statusline` to configure your status line |
    | claude-code-guide | Haiku | When you ask questions about Claude Code features |
  </Tab>
</Tabs>

Built-in subagents are registered by default in interactive sessions. To restrict them:

* To block a specific built-in type, add it to `permissions.deny` as shown in [Disable specific subagents](#disable-specific-subagents).
* To prevent Claude from delegating to any subagent, deny the `Agent` tool itself with [`permissions.deny`](/docs/en/permissions#tool-specific-permission-rules).
* To remove only the built-in `Explore` and `Plan` subagents, set [`CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1`](/docs/en/env-vars). Claude reads and explores files directly instead of delegating to them. Requires Claude Code v2.1.198 or later.
* In [non-interactive mode](/docs/en/headless) and the [Agent SDK](/docs/en/agent-sdk/overview), set [`CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS=1`](/docs/en/env-vars) to remove all built-in types and supply only your own.

An Agent tool call that omits `subagent_type` fails with [`subagent_type is required`](/docs/en/errors#subagent-type-is-required) when the session has no `general-purpose` subagent to fall back on.

Beyond these built-in subagents, you can create your own with custom prompts, tool restrictions, permission modes, hooks, and skills. The following sections show how to get started and customize subagents.

## Quickstart: create your first subagent

Subagents are Markdown files with YAML frontmatter. To create one, ask Claude to write it for you, or [write the file yourself](#write-subagent-files).

This walkthrough creates a user-level subagent that reviews code and suggests improvements.

<Steps>
  <Step title="Ask Claude to create the subagent">
    In Claude Code, describe the subagent you want and where to save it:

    ```text wrap theme={null}
    Create a personal code-improver subagent in ~/.claude/agents/ that scans
    files and suggests improvements for readability, performance, and best
    practices. It should explain each issue, show the current code, and
    provide an improved version. Make it read-only and have it use Sonnet.
    ```

    Claude writes the file with a `name`, a `description`, a `tools` list, a `model`, and a system prompt.
  </Step>

  <Step title="Review the file">
    Open `~/.claude/agents/code-improver.md` and confirm the frontmatter matches what you asked for. The result looks like this:

    ```markdown theme={null}
    ---
    name: code-improver
    description: Scans files and suggests improvements for readability, performance, and best practices. Use after writing or modifying code.
    tools: Read, Grep, Glob
    model: sonnet
    ---

    You are a code improvement specialist. For each issue you find, explain
    the problem, show the current code, and provide an improved version.
    ```

    Because the file lives in `~/.claude/agents/`, the subagent is available in every project on your machine. To scope it to one project instead, move it to that project's `.claude/agents/` directory. [Choose the subagent scope](#choose-the-subagent-scope) compares the two.
  </Step>

  <Step title="Try it out">
    Ask Claude to delegate to the new subagent:

    ```text wrap theme={null}
    Use the code-improver agent to suggest improvements in this project
    ```

    Claude delegates to your new subagent, which scans the codebase and returns improvement suggestions. In the transcript, the delegation appears as a tool call row showing the subagent's name followed by a short task description, such as `code-improver(Suggest code improvements)`.

    If Claude can't find the new subagent, restart Claude Code and try again. This happens only when `~/.claude/agents/` didn't exist before the session started, because a running session doesn't detect a newly created `agents` directory.
  </Step>
</Steps>

You now have a subagent you can use in any project on your machine to analyze codebases and suggest improvements.

You can also write subagent files by hand, define them via CLI flags, or distribute them through plugins. The following sections cover all configuration options.

<Note>
  Running `/agents` prints a reminder to ask Claude or edit `.claude/agents/` and `~/.claude/agents/` directly.
  On Claude Code v2.1.197 and earlier, `/agents` opens an interactive wizard with a **Running** tab that lists live subagents and a **Library** tab for creating, editing, and deleting them.&#x20;
</Note>

## Configure subagents

A subagent's file location determines who it's available to, and its frontmatter determines what it can do. This section covers where subagent files live and every field they support.

### Choose the subagent scope

Store subagent files in different locations depending on scope. When multiple subagents share the same name, Claude Code uses the one from the higher-priority location.

| Location | Scope | Priority | How to create |
| :- | :- | :- | :- |
| Managed settings | Organization-wide | 1 (highest) | Deployed via [managed settings](/docs/en/settings) |
| `--agents` CLI flag | Current session | 2 | Pass JSON when launching Claude Code |
| `.claude/agents/` | Current project | 3 | Ask Claude, or create the file manually |
| `~/.claude/agents/` | All your projects | 4 | Ask Claude, or create the file manually |
| Plugin's `agents/` directory | Where plugin is enabled | 5 (lowest) | Installed with [plugins](/docs/en/plugins/overview) |

**Project subagents** (`.claude/agents/`) are ideal for subagents specific to a codebase. Check them into version control so your team can use and improve them collaboratively.

Project subagents are discovered by walking up from the current working directory, so every `.claude/agents/` between there and the repository root is scanned. When more than one of these nested directories defines the same `name`, Claude Code uses the definition closest to the working directory.

When you add a directory with `--add-dir` or `/add-dir`, Claude Code also loads its `.claude/agents/` folder, alongside your project subagents. See [Additional directories](/docs/en/permissions#additional-directories-grant-file-access-not-configuration) for which other configuration types load from `--add-dir`. To share subagents across projects without `--add-dir`, use `~/.claude/agents/` or a [plugin](/docs/en/plugins/overview).

**User subagents** (`~/.claude/agents/`) are personal subagents available in all your projects.

Claude Code scans `.claude/agents/` and `~/.claude/agents/` recursively, so you can organize definitions into subfolders such as `agents/review/` or `agents/research/`. The subdirectory path doesn't affect how a subagent is identified or invoked, because identity comes only from the `name` frontmatter field.

Keep `name` values unique across the whole tree: if two files under the same `.claude/agents/` directory, including its subfolders, declare the same name, Claude Code loads only one of them, chosen by filesystem read order rather than a documented precedence. Across nested project directories, the definition closest to the working directory wins, as described above. The [`/doctor`](/docs/en/commands#all-commands) setup checkup reports files in the same directory that share a name and proposes renaming or removing all but one. Before v2.1.205, `/doctor` opened a diagnostics screen that listed duplicates and showed which definition was active.

Plugin `agents/` directories are also scanned recursively. Unlike project and user scopes, a subfolder inside a plugin's `agents/` directory becomes part of the [scoped identifier](#invoke-subagents-explicitly): a file at `agents/review/security.md` in plugin `my-plugin` registers as `my-plugin:review:security`.

**CLI-defined subagents** are passed as JSON when launching Claude Code. They exist only for that session and aren't saved to disk, making them useful for quick testing or automation scripts. You can define multiple subagents in a single `--agents` call:

<Tabs>
  <Tab title="macOS, Linux, WSL">
    ```bash theme={null}
    claude --agents '{
      "code-reviewer": {
        "description": "Expert code reviewer. Use proactively after code changes.",
        "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
        "tools": ["Read", "Grep", "Glob", "Bash"],
        "model": "sonnet"
      },
      "debugger": {
        "description": "Debugging specialist for errors and test failures.",
        "prompt": "You are an expert debugger. Analyze errors, identify root causes, and provide fixes."
      }
    }'
    ```
  </Tab>

  <Tab title="Windows PowerShell">
    ```powershell theme={null}
    claude --agents @'
    {
      "code-reviewer": {
        "description": "Expert code reviewer. Use proactively after code changes.",
        "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
        "tools": ["Read", "Grep", "Glob", "Bash"],
        "model": "sonnet"
      },
      "debugger": {
        "description": "Debugging specialist for errors and test failures.",
        "prompt": "You are an expert debugger. Analyze errors, identify root causes, and provide fixes."
      }
    }
    '@
    ```
  </Tab>
</Tabs>

In [non-interactive mode](/docs/en/headless), `--agents` also accepts the path to a JSON file holding the same object, for definitions too large to pass on the command line. For example, `claude -p --agents ./agents.json "Review my changes"` reads the definitions from that file. In an interactive session, Claude Code refuses a file path. The file form requires Claude Code v2.1.281 or later.

Each top-level key in the JSON is an agent's name, and its value is that agent's definition. Don't start a name with `-`. A definition takes these fields:

* **`prompt`**: the agent's system prompt, equivalent to the markdown body in file-based subagents. `prompt` may be empty. If you select an agent with an empty `prompt` and no `memory` field as the session's agent with `--agent`, the session's system prompt is left unchanged. An empty `prompt` requires Claude Code v2.1.281 or later.
* **[Frontmatter fields](#supported-frontmatter-fields)**: `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `initialPrompt`, `memory`, `effort`, `background`, `omitClaudeMd`, and `isolation`.
* **Ignored fields**: `color` and `experimental` aren't accepted here and are ignored rather than rejected.

For what Claude Code does with a value it can't load, and the flags and environment variable that skip that check, see [`Invalid --agents configuration`](/docs/en/errors#invalid-agents-configuration).

**Managed subagents** are deployed by organization administrators. Place markdown files in `.claude/agents/` inside the [managed settings directory](/docs/en/managed-settings#delivery-mechanisms), using the same frontmatter format as project and user subagents. Managed definitions take precedence over project and user subagents with the same name.

**Plugin subagents** come from [plugins](/docs/en/plugins/overview) you've installed. They load automatically alongside your custom subagents and appear in the @-mention typeahead under their scoped name. See the [plugin components reference](/docs/en/plugins/components#agents) for details on creating plugin subagents.

<Note>
  For security reasons, plugin subagents don't support the `hooks`, `mcpServers`, or `permissionMode` frontmatter fields. These fields are ignored when loading agents from a plugin. If you need them, copy the agent file into `.claude/agents/` or `~/.claude/agents/`. You can also add rules to [`permissions.allow`](/docs/en/settings-reference#permissions-allow) in `settings.json` or `settings.local.json`, but these rules apply to the entire session, not only the plugin subagent.

  If you're the plugin's author, ship the hooks in the plugin's [`hooks/hooks.json`](/docs/en/plugins/components#hooks) and the MCP servers in its [`.mcp.json`](/docs/en/plugins/components#mcp-servers) instead. They apply whenever the plugin is enabled rather than only inside the subagent.
</Note>

You can also reuse a subagent definition as an [agent team](/docs/en/agent-teams) teammate: name the subagent type when you ask Claude to spawn the teammate, and Claude Code applies parts of that definition to it. [Use subagent definitions for teammates](/docs/en/agent-teams#use-subagent-definitions-for-teammates) says which scopes and which parts apply in each display mode.

### Write subagent files

Subagent files use YAML frontmatter for configuration, followed by the system prompt in Markdown:

<Note>
  Claude Code watches `~/.claude/agents/` and `.claude/agents/`. When you add or edit a subagent file on disk, or ask Claude to write one for you, Claude Code detects the change within a few seconds and the next delegation uses the updated definition, with no restart needed.

  Three cases still need a restart:

  * The watcher covers only directories that existed when the session started, so after creating a scope's first agent file in a new `agents` directory, restart to load it.
  * Claude Code doesn't watch `.claude/agents/` inside directories added with `--add-dir` or `/add-dir`, so after adding or editing a subagent there, restart to load the change.
  * Sessions started with `--disable-slash-commands` don't watch these directories at all.
</Note>

```markdown .claude/agents/code-reviewer.md theme={null}
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

The frontmatter defines the subagent's metadata and configuration. The body becomes the system prompt that guides the subagent's behavior. Subagents receive only this system prompt plus basic environment details like the working directory, not the Claude Code system prompt.

In [non-interactive mode](/docs/en/headless), pass [`--append-subagent-system-prompt`](/docs/en/cli-reference#cli-flags) to append your text to the end of every subagent's system prompt, nested subagents included, apart from a [forked subagent](#fork-the-current-conversation), which reuses the conversation's own prompt. Requires Claude Code v2.1.205 or later. If your text is too long to pass on the command line, save it to a file and pass the path with `--append-subagent-system-prompt-file` instead. The file flag requires Claude Code v2.1.261 or later.

A subagent starts in the main conversation's current working directory. Within a subagent, `cd` commands don't persist between Bash or PowerShell tool calls and don't affect the main conversation's working directory. To give the subagent an isolated copy of the repository instead, set [`isolation: worktree`](#supported-frontmatter-fields).

A subagent with `isolation: worktree` runs its Bash and PowerShell commands inside its worktree. A command whose working directory resolves to your main checkout instead, for example because the worktree directory was removed while the subagent was running, fails with an error. Before v2.1.203, such a command could run in the main checkout.

This working-directory check covers the whole repository containing the directory you launched Claude Code from. When your session runs in a linked [worktree](/docs/en/worktrees) of its own, the check also covers the main checkout that worktree is linked from. Before v2.1.210, the check covered only the launch directory itself. A command whose working directory resolved elsewhere in the same repository, such as the repository root when you launched Claude Code from a monorepo subdirectory, ran there instead of failing.

For Bash commands, Claude Code also checks the command itself in two ways:

* It blocks a command that redirects git into the main checkout.
* It refuses a command when it can't verify from the command text that any git the command runs stays inside the worktree, for example when the command name is computed at runtime.

The redirect vectors and the shape rules are listed under [How Claude Code enforces isolation](/docs/en/worktrees#how-claude-code-enforces-isolation). PowerShell commands get only the working-directory check.

[Monitor](/docs/en/tools-reference#monitor-tool) commands go through the same working-directory and command-content checks as Bash commands.

When the main conversation itself runs isolated in a worktree, Claude Code applies the same checks to the session and to every subagent it spawns, including subagents without `isolation: worktree`; see [How Claude Code enforces isolation](/docs/en/worktrees#how-claude-code-enforces-isolation).

<h3 id="supported-frontmatter-fields">
  Frontmatter reference
</h3>

Configure a subagent with YAML [frontmatter](/docs/en/glossary#frontmatter) between `---` markers at the top of its file, and write its system prompt as Markdown after the closing `---`. Only `name` and `description` are required.

Multi-word field names use camelCase, such as `maxTurns` and `disallowedTools`, and must match the table exactly: Claude Code ignores a field it doesn't recognize without reporting an error. To find out why a subagent file didn't load, see [Subagent files Claude Code skips](#subagent-files-claude-code-skips).

| Field | Required | Description |
| :- | :- | :- |
| `name` | Yes | Unique identifier of at most 256 characters, such as `code-reviewer` or `reviewer-v2`. [Hooks](/docs/en/hooks#subagentstart) receive this value as `agent_type`. The filename doesn't have to match. Names can't contain `:`, which is reserved for [plugin-scoped identifiers](/docs/en/plugins/overview) such as `my-plugin:reviewer` |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | [Tools](#available-tools) the subagent can use, as a comma-separated string such as `Read, Grep, Bash` or a YAML list. Inherits every tool available to subagents if omitted. If no entry in the list resolves to a tool, the subagent usually [fails to launch](/docs/en/errors#agent-would-be-spawned-with-zero-tools) with an error naming the entries. To preload Skills into context, use the `skills` field rather than listing `Skill` here |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list. Same format as `tools`. An entry with a specifier, such as `Bash(git push *)`, still [removes the whole tool](#available-tools) |
| `model` | No | [Model](#choose-a-model) to use: `sonnet`, `opus`, `haiku`, `fable`, a full model ID such as `claude-opus-5-5`, or `inherit`. When you omit it, Claude Code picks the model in the [subagent model order](#choose-a-model) |
| `permissionMode` | No | [Permission mode](#permission-modes): `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, or `manual` as an alias for `default`. Ignored for [plugin subagents](#choose-the-subagent-scope) |
| `maxTurns` | No | Maximum number of agentic turns before the subagent stops. When the subagent reaches the limit, Claude Code returns its output marked as partial, and Claude can [resume it](#resume-subagents) to continue. The partial marking requires Claude Code v2.1.246 or later |
| `skills` | No | [Skills](/docs/en/skills) to preload into the subagent's context at startup. The full skill content is injected, not only the description. Subagents can still invoke unlisted project, user, and plugin skills through the Skill tool |
| `mcpServers` | No | [MCP servers](/docs/en/mcp) available to this subagent. Each entry is either a server name referencing an already-configured server (e.g., `"slack"`) or an inline definition with the server name as key and a full [MCP server config](/docs/en/mcp#installing-mcp-servers) as value. Ignored for [plugin subagents](#choose-the-subagent-scope) |
| `hooks` | No | [Lifecycle hooks](#define-hooks-for-subagents) scoped to this subagent. Ignored for [plugin subagents](#choose-the-subagent-scope) |
| `memory` | No | [Persistent memory scope](#enable-persistent-memory): `user`, `project`, or `local`. Enables cross-session learning |
| `background` | No | Set to `true` to keep this subagent in the background even when Claude asks to run it in the foreground. Where [fork mode](#turn-fork-mode-on-or-off) is on, Claude Code already runs the subagents Claude spawns [in the background](#run-subagents-in-foreground-or-background) |
| `omitClaudeMd` | No | Set to `true` to launch this subagent without the user, project, and local CLAUDE.md files; [managed policy files](/docs/en/memory#how-claude-md-files-load) still load, except for [managed subagents](#choose-the-subagent-scope). Use it for subagents that take everything they need from the [delegation prompt](#what-loads-at-startup). Ignored when the agent runs as the main session agent via `--agent` or the `agent` setting. Requires Claude Code v2.1.271 or later |
| `effort` | No | Effort level when this subagent is active. Overrides the session effort level, but not the [`CLAUDE_CODE_EFFORT_LEVEL`](/docs/en/env-vars#variables) environment variable. Options: `low`, `medium`, `high`, `xhigh`, `max`; available levels depend on the model |
| `isolation` | No | Set to `worktree` to run the subagent in a temporary [git worktree](/docs/en/worktrees), giving it an isolated copy of the repository branched by default from your [default branch](/docs/en/worktrees#choose-the-base-branch) rather than the parent session's `HEAD`. The worktree is automatically cleaned up if the subagent makes no changes |
| `color` | No | Display color for the subagent in the task list and transcript. Accepts `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, or `cyan` |
| `initialPrompt` | No | Auto-submitted as the first user turn when this agent runs as the main session agent (via `--agent` or the `agent` setting). [Commands](/docs/en/commands) and [skills](/docs/en/skills) are processed. Prepended to any user-provided prompt. Ignored for [plugin subagents](#choose-the-subagent-scope) |
| `experimental` | No | Map of experimental options. Set its `cacheTtl` key to `5m` or `1h` to choose the [prompt cache lifetime](/docs/en/prompt-caching#choose-the-ttl-yourself) for this subagent's requests, at the frontmatter's place in the [cache lifetime precedence](/docs/en/prompt-caching#choose-the-ttl-yourself). Claude Code ignores any other value, ignores `1h` while your Claude subscription is using usage credits, and reads the field only from subagent files. Requires Claude Code v2.1.248 or later |

Write `cacheTtl` inside the `experimental` map, not at the top level of the frontmatter.

```yaml theme={null}
---
name: repo-auditor
description: Audits a large repository and reports what it finds
experimental:
  cacheTtl: 1h
---
```

#### Subagent files Claude Code skips

Claude Code skips a file in a project, user, or managed `agents` directory, or in one under a directory you add with `--add-dir`, without reporting it in the session, when the frontmatter has any of these problems:

* **No `name`**: Claude Code treats the file as documentation kept beside your agents.
* **An opening `---` that isn't the file's first line**: Claude Code reads the file as having no frontmatter and treats it as documentation.
* **A `name` that starts with `-`, contains `:`, or is longer than 256 characters**: Claude Code skips the file and writes an error to the debug log.
* **A `name` but no `description`**: Claude Code skips the file and writes the reason to the debug log.
* **YAML that doesn't parse**: Claude Code reads no fields from the file, skips it, and writes the parse error to the debug log.

To see the debug log, run Claude Code with `--debug`.

A [plugin subagent](/docs/en/plugins/components#agents) whose frontmatter has no `name` or doesn't parse still loads, under its filename.

##### Check an `agents` directory before a session

To find files in an `agents` directory whose frontmatter doesn't parse, run `claude plugin validate` against the directory, for example `.claude/agents` or `~/.claude/agents`. Claude Code checks only [the directory you name](/docs/en/plugins/cli-reference#validate-a-directory), and doesn't flag a file whose frontmatter parses but has no `name`. Requires Claude Code v2.1.233 or later.
