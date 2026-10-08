[Part 3/4 of https://code.claude.com/docs/en/permission-modes.md, fetched 2026-10-08]

### Boundaries you state in conversation

The classifier treats boundaries you state in the conversation as a block signal. If you tell Claude "don't push" or "wait until I review before deploying", the classifier blocks matching actions even when the default rules would allow them. A boundary stays in force until you lift it in a later message. Claude's own judgment that a condition was met does not lift it.

Boundaries are not stored as rules. The classifier re-reads them from the transcript on each check, so a boundary can be lost if [context compaction](/docs/en/costs#reduce-token-usage) removes the message that stated it. For a hard guarantee, add a [deny rule](/docs/en/permissions#permission-rule-syntax) instead.

### Approvals you state in conversation

If you tell Claude that a blocked action is allowed, the classifier reads that as your approval and can clear the block. How you worded it decides whether the action runs, and how far the approval reaches:

* **Name the action and its specifics**: your message has to name the action and the specific thing that makes it dangerous, such as the branch of a force push. Naming the verb alone clears nothing, so "you can force-push" leaves the block in place.
* **Expect it to cover one action**: an approval covers the destructive action you named, so a later action is blocked again unless you granted the approval as standing. To stop approving a routine pattern one action at a time, add it to [`autoMode.allow`](/docs/en/auto-mode-config#override-the-block-and-allow-rules).
* **Some blocks stay in place**: [the classifier's precedence order](/docs/en/auto-mode-config#override-the-block-and-allow-rules) sets out which blocks your approval can reach. To run a step it won't clear, [leave auto mode](#switch-permission-modes) and answer the permission prompt.

### When auto mode falls back

When auto mode can't approve your session's actions, what happens depends on the case:

* **A blocked action**: Claude Code shows a notification and lists the action in `/permissions` under the **Recently denied** tab, where you can press `r` to retry it with a manual approval.
* **Repeated blocks**: if the classifier blocks an action 3 times in a row or 20 times total, auto mode pauses and Claude Code resumes prompting. Approving the prompted action resumes auto mode. See [Repeated-block thresholds](#repeated-block-thresholds) for how the blocks are counted.
* **No verdict from the classifier**: when a safety check separate from auto mode refuses the classifier's own request, or the classifier's response doesn't parse, Claude Code denies the action without the notification or the **Recently denied** entry. See [Auto mode cannot determine the safety of an action](/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action) for the message each case shows and what to do.
* **No verdict from the server**: under [server-side classifier review](#server-side-classifier-review), Claude Code denies an action the server gives no verdict for, and stops the turn after ten responses in a row with no verdict. See [The server returned no safety verdict](/docs/en/errors#the-server-returned-no-safety-verdict).
* **A mode switch during a check**: if you switch permission modes while a classifier check is pending, Claude Code discards a verdict the new mode wouldn't have requested. You're prompted for approval instead, or the action is auto-denied in [`dontAsk` mode](#allow-only-pre-approved-tools-with-dontask-mode).

#### Repeated-block thresholds

The thresholds of 3 blocks in a row and 20 blocks total are not configurable. The total counter persists for the session and resets only when its own limit triggers a fallback. Claude Code doesn't count a denial toward either threshold when a safety check separate from auto mode refuses the classifier's own request.

A [non-interactive](/docs/en/headless) `-p` run without a [`--permission-prompt-tool`](/docs/en/cli-reference#cli-flags) has no prompt to fall back to. When repeated blocks reach a threshold, the action doesn't run and Claude keeps working. Claude Code doesn't stop the run.

Repeated blocks usually mean the classifier is missing context about your infrastructure. Use `/feedback` to report false positives, or have an administrator [configure trusted infrastructure](/docs/en/auto-mode-config).

### How auto mode evaluates actions

The following sections cover the order Claude Code evaluates an action in, how the classifier reviews subagent work, and what classifier calls add in cost and latency.

<span id="how-the-classifier-evaluates-actions" />

<AccordionGroup>
  <Accordion title="How the classifier evaluates actions">
    Each action goes through a fixed decision order. The first matching step wins:

    1. Actions matching your [allow, ask, or deny rules](/docs/en/permissions#manage-permissions) resolve immediately, with these exceptions:
       * Writes to [protected paths](#protected-paths) route to the classifier even when an allow rule matches
       * No allow rule approves `rm` and `rmdir` removals targeting a [critical path](#critical-paths)
       * MCP tools marked [`requiresUserInteraction`](/docs/en/mcp#require-approval-for-a-specific-tool) prompt you directly even when an allow rule matches, and so do connector tools [your organization set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code
       * A shell command that carries [per-command allowed domains](/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode) also routes to the classifier even when an allow rule matches, because a rule approves the command, not its hosts
       * Ask rules that match on a command's content, such as `Bash(git push *)`, fall back to a permission prompt
       * A write that the [symlink check](/docs/en/permissions#symlinks) resolves to a protected path prompts you when the path Claude requested isn't itself protected
    2. Read-only actions and file edits in your working directory are auto-approved, except writes to [protected paths](#protected-paths) and [the first read outside the working directories](#first-read-outside-the-working-directories), which prompts you
       * In a session with [server-side classifier review](#server-side-classifier-review), read-only and [sandboxed](/docs/en/sandboxing#sandbox-modes) shell commands wait for that review and are blocked if it flags them
       * A write inside your working directory that the [symlink check](/docs/en/permissions#symlinks) resolves to a location outside it prompts you
       * When Claude reads an [artifact someone else made](/docs/en/artifacts#read-an-artifact-shared-with-you), the approval cases listed in that section apply
    3. Everything else goes to the classifier, apart from [critical-path removals](#critical-paths) under their default handling. The connector tools and `requiresUserInteraction` MCP tools that prompt you directly in step 1 never reach the classifier either, so neither an org-required approval nor a consent step is auto-approved
    4. If the classifier blocks, Claude receives the reason. In most sessions the reason names the rule the classifier matched, such as `[Data Exfiltration]`, rather than giving a written explanation; see [Review denials](/docs/en/auto-mode-config#review-denials)

    A [mod](/docs/en/plugins/mods/overview) you install that handles `tool.check` can approve an action before step 3, and the classifier doesn't check an action the mod approves. See [Extend permissions with hooks](/docs/en/permissions#extend-permissions-with-hooks).

    In the VS Code extension, how [Claude in Chrome](/docs/en/chrome) browser actions get approved depends on how the session connected to the browser: see [Permission prompts in VS Code sessions](/docs/en/chrome#permission-prompts-in-vs-code-sessions).

    On entering auto mode, broad allow rules that grant arbitrary code execution are dropped:

    * Blanket `Bash(*)` or `PowerShell(*)`
    * Wildcarded interpreters like `Bash(python*)`
    * Package-manager run commands
    * `Agent` allow rules
    * [`Monitor`](/docs/en/tools-reference#monitor-tool) allow rules, because Claude Code runs Monitor commands through the shell

    Narrow rules like `Bash(npm test)` stay in effect. Claude Code restores the dropped rules when you leave auto mode. Before v2.1.236, Claude Code left `Monitor` allow rules in effect in auto mode, so a rule that matched the whole tool approved Monitor commands without classifier review.

    Claude Code also runs `git status` itself before a command that would discard uncommitted work, such as `git reset --hard` or `rm -rf`, and shows the classifier whether staged, modified, or untracked work is present. Claude Code reports untracked files in that check even when the repository's git configuration sets `status.showUntrackedFiles=no`.

    In the classifier requests sent by Claude Code itself, the classifier sees user messages, tool calls other than read-only lookups such as file reads and searches, and your CLAUDE.md content. Tool results are stripped from those requests, so hostile content in a file or web page can't manipulate the classifier directly.

    You can annotate a call's result with a [PostToolUse hook's `classifierContext` field](/docs/en/hooks#annotate-a-result-for-the-auto-mode-classifier), which the classifier reads as application-provided context. The field requires Claude Code v2.1.236 or later.

    A separate server-side probe scans incoming tool results and flags suspicious content before Claude reads it. For more on how these layers work together, see the [auto mode announcement](https://claude.com/blog/auto-mode) and the [engineering deep dive](https://www.anthropic.com/engineering/claude-code-auto-mode).
  </Accordion>

  <Accordion title="How auto mode handles subagents">
    The classifier checks [subagent](/docs/en/sub-agents) work at three points:

    1. Before a subagent starts, the delegated task description is evaluated, so a dangerous-looking task is blocked at spawn time.
    2. While the subagent runs, each of its actions goes through the same [decision order](#how-the-classifier-evaluates-actions) as in the parent session, with the same block and allow rules. Any `permissionMode` in the subagent's frontmatter is ignored.
    3. When the subagent finishes, the classifier reviews its work and its final report before the parent reads the report. When the classifier flags the subagent's work or report, or a separate API safety check refuses the review, the report is still delivered, prepended with a security warning. When the classifier is unavailable for the review, the report arrives with a note to verify the subagent's work before acting on it.
  </Accordion>

  <Accordion title="Cost and latency">
    The classifier runs on Claude Sonnet 5 by default rather than on your `/model` selection. A classifier model that Anthropic configures server-side takes precedence over that default. When your session's model is Claude Sonnet 4.6, or when [`availableModels`](/docs/en/model-config#restrict-model-selection) excludes Sonnet 5, the classifier runs on the session's model instead, or on an Opus model when the session runs on a [Fable model](/docs/en/model-config#work-with-fable). On providers other than the Anthropic API, that Opus fallback is the model you set in [`ANTHROPIC_DEFAULT_OPUS_MODEL`](/docs/en/model-config#environment-variables), or Opus 5 if you haven't set one.

    The session's first auto-mode request validates the Sonnet 5 default: if the request succeeds, Sonnet 5 stays the session's classifier model, and if it fails because the model isn't available, the session uses the fallback instead.

    On Enterprise plans and on accounts that use the Claude API, [Claude Platform on AWS](/docs/en/claude-platform-on-aws), Amazon Bedrock, Google Cloud's Agent Platform, or Microsoft Foundry, classifier calls count toward your token usage. Each check sends a portion of the transcript plus the pending action, adding a round-trip before execution. Reads and working-directory edits outside protected paths skip the classifier, so the overhead comes mainly from shell commands and network operations. Where the server reviews the actions as part of the session's model requests, there are no separate classifier calls to count; see [Server-side classifier review](#server-side-classifier-review).

    Sandboxed network access adds no per-connection classifier requests. The classifier judges [the hosts a command names](/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode) together with the command in one review, and Claude Code checks each connection against the approved list without calling the classifier again.
  </Accordion>
</AccordionGroup>

## Allow only pre-approved tools with dontAsk mode

If you set `dontAsk` mode, Claude Code auto-denies every tool call that would otherwise prompt you. Claude still runs actions that need no approval in Manual mode, such as file reads inside your working directories and [read-only Bash commands](/docs/en/permissions#read-only-commands), plus actions matching your `permissions.allow` rules and calls approved by a [PreToolUse hook](/docs/en/permissions#extend-permissions-with-hooks). Use this mode for CI pipelines or restricted environments where you pre-define what Claude may do; the session never waits for input. The status bar shows `⏵⏵ don't ask on` while this mode is active.

Claude Code denies calls matching your explicit [`ask` rules](/docs/en/permissions#manage-permissions) rather than prompting. It also denies the built-in `AskUserQuestion` tool even if your allow rules match it, and does the same to connector tools [your organization set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code. It denies MCP tools marked [`_meta["anthropic/requiresUserInteraction"]`](/docs/en/mcp#require-approval-for-a-specific-tool) the same way, because their approval card needs an answer this mode never collects.

`rm` and `rmdir` removals targeting a [critical path](#critical-paths), such as `rm -rf /` and `rm -rf ~`, are denied even when an allow rule matches them or a `PreToolUse` hook allows them.

[Cloud sessions](/docs/en/claude-code-on-the-web) ignore `defaultMode: "dontAsk"`; see [bypassPermissions](#skip-all-checks-with-bypasspermissions-mode) for details.

Set it at startup with the flag:

```bash theme={null}
claude --permission-mode dontAsk
```

## Skip all checks with bypassPermissions mode

`bypassPermissions` mode disables permission prompts and safety checks so tool calls execute immediately, including writes to [protected paths](#protected-paths).

The [actions no mode auto-approves](#actions-no-mode-auto-approves) still prompt in this mode. Reading [another organization's public artifact](/docs/en/artifacts#read-an-artifact-shared-with-you) needs your approval, and this mode doesn't ask for it, so Claude can't read one. The [Remove-Item in PowerShell](#remove-item-in-powershell) denies also apply in this mode.

Two [cross-session messaging](/docs/en/cross-session-messaging) safeguards still apply in this mode, and in interactive terminal plan-mode sessions where bypass permissions are available:

* The [`isolatePeerMachines`](/docs/en/settings-reference#isolatepeermachines) approval prompt for messages to your sessions beyond this machine still appears.
* When no [`crossSessionInbound`](/docs/en/cross-session-messaging#control-inbound-messages) value applies, Claude Code holds an inbound message from another of your sessions for your approval, and delivers without asking only when the sending session identifies itself as also bypassing permission prompts. If you leave the permission mode while messages are held, Claude Code re-applies the inbound rules and delivers any held message they now accept.

In interactive terminal sessions with bypass permissions available, Claude Code also doesn't enforce [plan mode's](#analyze-before-you-edit-with-plan-mode) blocks. Claude is still instructed to plan without editing, but a file edit or shell command it attempts during planning runs without prompting. Explicit [ask rules](/docs/en/permissions#manage-permissions) and `rm` and `rmdir` removals targeting a [critical path](#critical-paths) still prompt.

Plan mode keeps its blocks wherever Claude Code runs without an interactive terminal, including [non-interactive runs](/docs/en/headless) with `-p`, [Agent SDK](/docs/en/agent-sdk/permissions#plan-mode-plan) sessions, and conversations in the [VS Code extension](/docs/en/vs-code)'s chat panel. There, `--allow-dangerously-skip-permissions` makes `bypassPermissions` selectable later.

<Warning>
  Only use this mode in isolated environments like containers, VMs, or dev containers without internet access, where Claude Code cannot damage your host system.
</Warning>

You can't enter `bypassPermissions` from a session you started without it enabled. Enable it at launch with [`permissions.defaultMode: "bypassPermissions"`](/docs/en/settings-reference#permissions-defaultmode) or with an enabling flag:

```bash theme={null}
claude --permission-mode bypassPermissions
```

The `--dangerously-skip-permissions` flag is equivalent.

Claude Code refuses `bypassPermissions` in a session you start with [`--restricted`](/docs/en/cli-reference#cli-flags). `--restricted` requires Claude Code v2.1.248 or later.

The first time you start an interactive session with this mode enabled, Claude Code shows a warning dialog asking you to accept responsibility for actions taken without permission checks:

* **If you accept**: Claude Code sets `skipDangerousModePermissionPrompt` to `true` in `~/.claude/settings.json`, so later sessions skip the dialog. To see the dialog again, remove the key from that file or set it to `false`. The [`skipDangerousModePermissionPrompt` reference](/docs/en/settings-reference#skipdangerousmodepermissionprompt) lists the other settings files where you or your organization can set it.
* **If you decline**: Claude Code exits.

In [non-interactive mode](/docs/en/headless) no dialog is shown, and a [background session](/docs/en/agent-view) started with `--bg` is refused until you've accepted the dialog in an interactive session.

On Linux and macOS, Claude Code refuses to start in this mode when running as root or under `sudo`:

```text theme={null}
--dangerously-skip-permissions cannot be used with root/sudo privileges for security reasons
```

The check is skipped automatically inside a recognized sandbox. To run autonomously in a container, use the [dev container](/docs/en/devcontainer) configuration, which runs Claude Code as a non-root user.

[Cloud sessions](/docs/en/claude-code-on-the-web) don't honor `defaultMode: "bypassPermissions"` or `"dontAsk"` from your settings files, so a repository's checked-in settings can't start a cloud session in bypass-permissions mode. The setting is ignored silently and the session starts in the permission mode shown in the mode dropdown instead. See [Switch permission modes](#switch-permission-modes) for which modes cloud sessions offer.

<Warning>
  `bypassPermissions` offers no protection against prompt injection or unintended actions. For background safety checks with far fewer permission prompts, use [auto mode](#eliminate-prompts-with-auto-mode) instead. Administrators can block this mode by setting `permissions.disableBypassPermissionsMode` to `"disable"` in [managed settings](/docs/en/managed-settings).
</Warning>

## Protected paths

Writes to a small set of paths are never auto-approved, except in `bypassPermissions` mode and in interactive terminal sessions in plan mode with [bypass permissions](#skip-all-checks-with-bypasspermissions-mode) available. This prevents accidental corruption of repository state and Claude's own configuration.

| Mode | Protected-path writes |
| :- | :- |
| `default`, `acceptEdits` | Prompted |
| `plan` | Allowed in interactive terminal sessions with [bypass permissions](#skip-all-checks-with-bypasspermissions-mode) available. Otherwise, routed to the classifier when [auto mode](#eliminate-prompts-with-auto-mode) is available during planning, and prompted when it isn't |
| `auto` | Routed to the classifier |
| `dontAsk` | Denied |
| `bypassPermissions` | Allowed |

In a session started with [`--restricted`](/docs/en/cli-reference#cli-flags), which requires Claude Code v2.1.248 or later, the classifier can't approve protected-path writes.

In the modes that route protected-path writes to the classifier, a write that the [symlink check](/docs/en/permissions#symlinks) resolves to a protected path prompts you instead when the path Claude requested isn't itself protected.

[`permissions.allow`](/docs/en/permissions#manage-permissions) rules in settings files do not pre-approve protected-path writes. The safety check runs before Claude Code evaluates allow rules from settings, so an entry such as `Edit(.claude/**)` in `~/.claude/settings.json` or `.claude/settings.json` does not change the per-mode outcome in the table above. In permission modes that prompt, the prompt for a write to the project's `.claude/` folder or to `~/.claude/` can offer one of these session-scoped options:

* For the project's `.claude/` folder: **Yes, and allow Claude to edit files in this project's .claude folder for this session**
* For `~/.claude/`: **Yes, and allow Claude to edit files in its \~/.claude folder for this session**

Protected directories:

* `.git`
* `.config/git`
* `.vscode`
* `.idea`
* `.husky`
* `.cargo`
* `.devcontainer`
* `.yarn`
* `.mvn`
* `.claude`, with a few exceptions, such as:
  * Claude's own git worktrees under `.claude/worktrees/`
  * The current session's own plan files in `~/.claude/plans/`, or in the [`plansDirectory`](/docs/en/settings-reference#plansdirectory) you set
  * A [background session](/docs/en/agent-view#where-state-is-stored)'s own scratch directory at `~/.claude/jobs/<id>/tmp/`
  * Markdown files in the project's [auto memory](/docs/en/memory#storage-location) directory, such as `~/.claude/projects/<project>/memory/`, in a session started without `--restricted`
  * Markdown files in a [subagent memory](/docs/en/sub-agents#enable-persistent-memory) directory, such as `.claude/agent-memory/`, in a session started without `--restricted`
* A directory you loaded with [`--plugin-dir`](/docs/en/plugins/mods/create#change-a-mod-with-claude), because Claude Code reloads and runs a mod's code from it when a file changes

Protected files:

* `.gitconfig`, `.gitmodules`
* `.bashrc`, `.bash_profile`, `.bash_login`, `.bash_aliases`, `.bash_logout`, `.zshrc`, `.zprofile`, `.zshenv`, `.zlogin`, `.zlogout`, `.profile`, `.envrc`
* `.npmrc`, `.yarnrc`, `.yarnrc.yml`, `.pnp.cjs`, `.pnp.loader.mjs`, `.pnpmfile.cjs`, `bunfig.toml`, `.bunfig.toml`
* `.bazelrc`, `.bazelversion`, `.bazeliskrc`
* `.pre-commit-config.yaml`, `lefthook.yml`, `lefthook.yaml`, `.lefthook.yml`, `.lefthook.yaml`
* `gradle-wrapper.properties`, `maven-wrapper.properties`
* `.devcontainer.json`
* `.ripgreprc`, `pyrightconfig.json`
* `.mcp.json`, `.claude.json`
