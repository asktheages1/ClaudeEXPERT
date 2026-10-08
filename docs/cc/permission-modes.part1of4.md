[Part 1/4 of https://code.claude.com/docs/en/permission-modes.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Choose a permission mode

> Control whether Claude asks before acting. Switch permission modes with Shift+Tab in the CLI, the mode indicator in VS Code, or the mode selector in Desktop.

A permission mode sets which actions Claude can take in a session without asking you first. In Manual mode, Claude Code stops and asks you before most actions that edit files, run shell commands, or reach the network. In [auto mode](#eliminate-prompts-with-auto-mode), a second model, the classifier, reviews actions instead of you; [how the classifier evaluates actions](#how-the-classifier-evaluates-actions) lists which actions it reviews and which skip it.

With Claude Code v2.1.283 or later, auto mode is the built-in starting permission mode for interactive terminal and VS Code sessions. On earlier versions, it's the built-in starting permission mode only on Pro, Max, and Team plans. [Which mode a session starts in](#which-mode-a-session-starts-in) covers the surfaces and settings that change the starting permission mode. You can also change a running session's permission mode at any time.

## Available modes

Each mode makes a different tradeoff between convenience and oversight. The table below shows what Claude can do without a permission prompt in each mode. Manual mode appears under its config value, `default`.

| Mode | What runs without asking | Best for |
| :- | :- | :- |
| `default` | Reads only | Reviewing every action yourself, sensitive work |
| [`acceptEdits`](#auto-approve-file-edits-with-acceptedits-mode) | Reads, file edits, and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`, etc.) | Iterating on code you're reviewing |
| [`plan`](#analyze-before-you-edit-with-plan-mode) | Reads, plus classifier-approved commands when [auto mode](#eliminate-prompts-with-auto-mode) is available | Exploring a codebase before changing it |
| [`auto`](#eliminate-prompts-with-auto-mode) | Everything, with background safety checks | Long tasks, reducing prompt fatigue |
| [`dontAsk`](#allow-only-pre-approved-tools-with-dontask-mode) | Reads and pre-approved tools; anything that would prompt is denied | Locked-down CI and scripts |
| [`bypassPermissions`](#skip-all-checks-with-bypasspermissions-mode) | Everything | Isolated containers and VMs only |

The mode that reviews every action is named **Manual** in the CLI, in `claude --help`, in the VS Code and JetBrains extensions, and in the desktop app. Its config value is `default`, which is what hooks and SDK integrations use. The CLI accepts `manual` as an alias wherever you type the value, for example `claude --permission-mode manual` or `"defaultMode": "manual"`.

Writes to [protected paths](#protected-paths) are never auto-approved except in `bypassPermissions` mode and in plan-mode sessions where bypass permissions are available, meaning interactive terminal sessions started in a way that [puts `bypassPermissions` in the mode cycle](#switch-permission-modes).

Modes set the baseline. Layer [permission rules](/docs/en/permissions#manage-permissions) on top to pre-approve or block specific tools. Deny rules block in every mode, including `bypassPermissions`. Deny and ask rules don't apply to [`EndConversation`](/docs/en/tools-reference#endconversation-tool-behavior) as long as Claude still has at least one other tool it can call. Allow rules have no effect in `bypassPermissions`.

<h3 id="actions-no-mode-auto-approves">
  Actions no mode auto-approves
</h3>

Claude Code doesn't auto-approve the following in any mode, including `bypassPermissions`. Each bullet links to the section that says what happens instead in each mode:

* Tools matched by an explicit [ask rule](/docs/en/permissions#manage-permissions)
* Connector tools your organization [set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools), in sessions where that setting reaches Claude Code
* Tools that require user interaction: the built-in `AskUserQuestion` tool and MCP tools marked [`requiresUserInteraction`](/docs/en/mcp#require-approval-for-a-specific-tool)
* `rm` and `rmdir` removals targeting a [critical path](#critical-paths), which no allow rule or `PreToolUse` hook `"allow"` approves
* The [cross-session messaging safeguards](#skip-all-checks-with-bypasspermissions-mode)
* Reads outside the working directories while [`permissions.blockReadsOutsideWorkingDirectories`](/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) is on: recognized file-reading Bash commands prompt even in auto mode and `bypassPermissions` mode, and so does any [unsandboxed retry](/docs/en/sandboxing#the-unsandboxed-retry-escape-hatch) that needs approval to run outside the sandbox. Requires Claude Code v2.1.257 or later.

  A command the shell parser can't trace, such as one that changes directory more than once or runs a subshell, prompts the same way even when it names no outside path. This prompt doesn't apply when the command runs in the [sandbox](/docs/en/sandboxing) and the sandbox enforces the block.

## Common setups

Permission modes decide whether Claude asks before an action, and the [Bash sandbox](/docs/en/sandboxing) and outer [isolation boundaries](/docs/en/sandbox-environments) decide what an action can reach once it runs. Each row below pairs a goal with the flags or settings that get you there and the isolation it needs, as a starting point. [Available modes](#available-modes) lists what runs without a prompt in each mode.

| You want to | Start with | Isolation needed | Notes |
| :- | :- | :- | :- |
| Review every action yourself | Manual mode: `claude --permission-mode default` | None | Sensitive work, unfamiliar code |
| Iterate locally with fewer prompts, without a classifier | Manual mode plus the Bash sandbox in [auto-allow mode](/docs/en/sandboxing#sandbox-modes): `claude --permission-mode default`, then run `/sandbox` and select auto-allow | The built-in Bash sandbox, on macOS, Linux, and WSL2 | Deny rules still apply, and ask rules that name a command, such as `Bash(git push *)`, still prompt. To turn the sandbox on from a settings file instead, set [`sandbox.enabled`](/docs/en/settings-reference#sandbox-enabled) to `true` |
| Explore before changing anything | `claude --permission-mode plan` | None | Claude Code blocks edits until you [approve a plan](#review-and-approve-a-plan) |
| Work hands-off in auto mode | `claude --permission-mode auto`, the [built-in starting permission mode](#which-mode-a-session-starts-in) with v2.1.283 or later | None; a sandbox or container adds defense in depth | Requires a [supported model](#eliminate-prompts-with-auto-mode), and your organization can [turn auto mode off](#eliminate-prompts-with-auto-mode) |
| Run in CI with an exact allowlist | `claude -p "run the test suite" --permission-mode dontAsk --allowedTools "Bash(npm test)" "Read"` | None beyond what your CI runner provides | [Cloud sessions](/docs/en/claude-code-on-the-web) ignore `dontAsk` from settings files |
| Run fully unattended inside a container | `claude -p "<prompt>" --dangerously-skip-permissions` | Required: a container, VM, or the [sandbox runtime](/docs/en/sandbox-environments#sandbox-runtime); on Linux and macOS, run it as a [non-root user](#skip-all-checks-with-bypasspermissions-mode) | Cloud sessions ignore this mode from settings files. In this `-p` run, the [few calls that would still prompt](#skip-all-checks-with-bypasspermissions-mode) are denied instead |

The Bash sandbox and auto mode work independently and combine, with the exceptions listed under [Sandbox modes](/docs/en/sandboxing#sandbox-modes). For the full interaction, see [How sandboxing relates to permissions and permission modes](/docs/en/sandboxing#how-sandboxing-relates-to-permissions-and-permission-modes) and [How isolation relates to permission modes](/docs/en/sandbox-environments#how-isolation-relates-to-permission-modes).

<h2 id="which-mode-a-session-starts-in">
  Which mode a session starts in
</h2>

When you start a new session in a terminal, Claude Code takes the permission mode from the first of these that applies:

1. The `--permission-mode` flag, or `--dangerously-skip-permissions`

2. `permissions.defaultMode` in a [settings file](/docs/en/settings#where-settings-live)

   If you set `"auto"` in `.claude/settings.json` or `.claude/settings.local.json`, the value doesn't take effect, and Claude Code then uses the built-in default rather than a `defaultMode` from `~/.claude/settings.json`. If you set `"bypassPermissions"` in those two files, it doesn't take effect either, and the session starts in Manual mode. The other values apply from any settings file.

3. The built-in default

Conversations the VS Code extension starts follow the extension's own list in [Switch permission modes](#switch-permission-modes). For the permission mode Claude Code starts a resumed session in, see [permission mode on resume](/docs/en/sessions#permission-mode-on-resume).

The built-in `auto` default requires Claude Code v2.1.228 or later on macOS, Linux, and WSL, and v2.1.233 or later on native Windows. On earlier versions, the built-in default is Manual.

The built-in default depends on how you run Claude Code. The first row that matches your session applies. The table covers sessions you start in a terminal or through the VS Code extension; for the desktop app and claude.ai, see the Desktop and Web tabs in [Switch permission modes](#switch-permission-modes).

| How you run Claude Code | Built-in starting permission mode |
| :- | :- |
| Any settings file sets `disableAutoMode` to `"disable"` | `default` |
| `claude -p` or the [Agent SDK](/docs/en/agent-sdk/permissions#permission-modes) | `default` in sessions that [fetch feature flags](/docs/en/env-vars#features-that-need-feature-flag-fetching). In sessions that don't, such as on a third-party provider or with telemetry off, `auto` with Claude Code v2.1.285 or later and `default` on earlier versions. A session in an organization whose policy withholds the `auto` default starts in `default` instead |
| Your organization has the [HIPAA configuration](#hipaa-configuration) applied and the session is [eligible for it](/docs/en/hipaa-setup#check-how-developers-sign-in-and-connect) | `default` with Claude Code v2.1.285 or later; auto mode stays available to switch to |
| In a terminal or through the [VS Code extension](/docs/en/vs-code) | `auto` with Claude Code v2.1.283 or later; on earlier versions, `auto` on Pro, Max, or Team plans in sessions that [fetch feature flags](/docs/en/env-vars#features-that-need-feature-flag-fetching), and `default` otherwise |

In your [first session after an install or upgrade](/docs/en/env-vars#first-session-after-an-install-or-upgrade), Claude Code can choose the starting permission mode before its feature flags arrive. That session can start in a different permission mode than the table gives.

When the flag, a settings file, or the built-in default selects `auto` but auto mode isn't available to the session, Claude Code starts the session in Manual instead. Auto mode is unavailable when the session doesn't meet the [availability requirements](#eliminate-prompts-with-auto-mode), such as a settings file turning it off or a model that doesn't support it, or when Anthropic has temporarily turned it off server-side.

The first time the built-in default starts one of your sessions in auto mode, Claude Code shows a notice that links to this page:

* In a terminal, once, at the top of the session
* In the VS Code extension, as a card on the new-conversation screen that stays until you dismiss it

If your `~/.claude/settings.json` sets a `defaultMode` other than `auto` and no other settings file sets one, your sessions keep starting in that mode. On Pro, Max, and Team plans, and in sessions that [don't fetch feature flags](/docs/en/env-vars#features-that-need-feature-flag-fetching), Claude Code asks once, in the terminal or in the VS Code extension, whether to change the setting to auto mode. If you decline, your setting stays as it is.

<h3 id="start-in-a-different-mode">
  Start in a different permission mode
</h3>

You can set the starting permission mode for one session, or as a default for every session on a machine, in a project, or in an organization. When more than one settings file sets `permissions.defaultMode`, [settings precedence](/docs/en/settings#settings-precedence) decides, so a project or managed value outranks `~/.claude/settings.json`. To change the permission mode of a session that's already running, see [Switch permission modes](#switch-permission-modes).

| To set the starting permission mode for | Do this |
| :- | :- |
| One session you're about to start | Pass the permission mode as a flag, for example `claude --permission-mode default` |
| Every terminal session you start on this machine | Set `permissions.defaultMode` in `~/.claude/settings.json`. For what the VS Code extension reads, see [Switch permission modes](#switch-permission-modes) |
| Every terminal session you start in one project | Set `permissions.defaultMode` in the project's `.claude/settings.json`. Sessions you start in a terminal honor every value except `auto` and `bypassPermissions`; sessions the VS Code extension starts don't read project settings for the starting permission mode |
| Every terminal session in your organization | Set `permissions.defaultMode` in [managed settings](/docs/en/managed-settings). Terminal sessions start in that mode and people can still switch to auto mode; for what the VS Code extension reads, see [Switch permission modes](#switch-permission-modes). To remove auto mode so nobody can select it, set `permissions.disableAutoMode` to `"disable"` instead |

This example makes every terminal session on your machine start in Manual mode, whose config value is `default`. Save it in `~/.claude/settings.json`:

```json theme={null}
{
  "permissions": {
    "defaultMode": "default"
  }
}
```

The next session you start shows `⏸ manual mode on` in the status bar.

<h3 id="hipaa-configuration">
  Permission modes with the HIPAA configuration
</h3>

In an organization with the [HIPAA configuration](/docs/en/hipaa-setup) applied, the built-in `auto` default doesn't apply. A terminal or VS Code session starts in Manual mode when nothing else chooses its starting permission mode. A terminal session also shows `Auto mode isn't the default for your organization · Shift+Tab to switch`, and the VS Code extension shows no notice. [Check how developers sign in and connect](/docs/en/hipaa-setup#check-how-developers-sign-in-and-connect) lists the sessions this applies to.

Auto mode and `bypassPermissions` stay available:

* **Switch to auto mode**: press `Shift+Tab`, or use [your interface's control](#switch-permission-modes)
* **Start in auto mode**: pass `--permission-mode auto`, or set `permissions.defaultMode` to `auto` in your user settings, or in managed settings for your whole organization. See [Start in a different permission mode](#start-in-a-different-mode)
* **Remove auto mode**: set [`permissions.disableAutoMode`](/docs/en/settings-reference#disableautomode) to `"disable"` in managed settings
* **Block `bypassPermissions`**: set [`permissions.disableBypassPermissionsMode`](/docs/en/settings-reference#permissions-disablebypasspermissionsmode) to `"disable"` in managed settings

Requires Claude Code v2.1.285 or later, the [minimum version for the HIPAA configuration](/docs/en/hipaa-setup#update-claude-code-and-claude-desktop).

## Switch permission modes

Each interface has its own control for switching permission modes during a session and its own way of choosing the permission mode new sessions start in. Select your interface to see its controls.

<Tabs>
  <Tab title="CLI">
    **During a session**: press `Shift+Tab` to cycle permission modes. From `auto`, the first press switches to `default`, and the cycle then runs `default` → `acceptEdits` → `plan`. Optional modes slot in after `plan`. The status bar shows the active mode as a gray `⏸ manual mode on` for `default`, or as `⏵⏵ accept edits on`, `⏸ plan mode on`, `⏵⏵ auto mode on`, `⏵⏵ don't ask on`, or `⏵⏵ bypass permissions on`.

    Watch the status bar in this clip of a session that started in auto mode. Each time you press `Shift+Tab`, it changes from `auto mode on` to `manual mode on`, `accept edits on`, `plan mode on`, and back to `auto mode on`.

    <Frame>
      <video autoPlay muted loop playsInline className="w-full dark:hidden" style={{aspectRatio: "1440 / 264"}} src="https://mintcdn.com/claude-code/oa7CKjMeIChox26S/images/permission-modes-cycle-light.mp4?fit=max&auto=format&n=oa7CKjMeIChox26S&q=85&s=198ca90aeb2e3675b3d01b7d686aab0b" aria-label="The status bar under the Claude Code prompt changes with each press of Shift+Tab: auto mode on, manual mode on, accept edits on, plan mode on, then auto mode on again." data-path="images/permission-modes-cycle-light.mp4" />

      <video autoPlay muted loop playsInline className="w-full hidden dark:block" style={{aspectRatio: "1440 / 264"}} src="https://mintcdn.com/claude-code/oa7CKjMeIChox26S/images/permission-modes-cycle-dark.mp4?fit=max&auto=format&n=oa7CKjMeIChox26S&q=85&s=994cdeec4e99d2f474d236c1087d6e63" aria-label="The status bar under the Claude Code prompt changes with each press of Shift+Tab: auto mode on, manual mode on, accept edits on, plan mode on, then auto mode on again." data-path="images/permission-modes-cycle-dark.mp4" />
    </Frame>

    Not every mode is in the default cycle:

    * `auto`: appears when [auto mode is available](#eliminate-prompts-with-auto-mode); cycling to it switches permission modes without a confirmation prompt
    * `bypassPermissions`: appears after you start with `--permission-mode bypassPermissions`, `--dangerously-skip-permissions`, `--allow-dangerously-skip-permissions`, or `permissions.defaultMode: "bypassPermissions"` in [user, `--settings`, or managed settings](/docs/en/settings-reference#permissions-defaultmode). The `--allow-` variant adds the permission mode to the cycle without activating it
    * `dontAsk`: never appears in the cycle; set it with `--permission-mode dontAsk`

    Enabled optional modes slot in after `plan`, with `bypassPermissions` first and `auto` last. If you have both enabled, you will cycle through `bypassPermissions` on the way to `auto`.

    **From a Bash permission prompt**: in the Manual and `acceptEdits` permission modes, when [auto mode](#eliminate-prompts-with-auto-mode) is available, Claude Code adds **Yes, and switch to auto mode** to a Bash command's permission prompt. Select it to approve the command and switch the session to auto mode. [PowerShell tool](/docs/en/tools-reference#powershell-tool) prompts don't offer the option. Requires Claude Code v2.1.247 or later.

    Claude Code doesn't add the option to prompts forced by one of your [`ask` rules](/docs/en/permissions#manage-permissions) or by a [hook](/docs/en/hooks#pretooluse-decision-control), because auto mode still shows you those prompts, so switching wouldn't remove them.

    **At startup**: pass the permission mode as a flag.

    ```bash theme={null}
    claude --permission-mode plan
    ```

    **As a default**: set `permissions.defaultMode` at the scope you want, as described in [Start in a different permission mode](#start-in-a-different-mode).

    The same `--permission-mode` flag works with `-p` for [non-interactive runs](/docs/en/headless).
  </Tab>

  <Tab title="VS Code">
    **During a session**: click the mode indicator at the bottom of the prompt box. It uses these labels for the modes on this page:

    | UI label | Mode |
    | :- | :- |
    | Manual | `default` |
    | Edit automatically | `acceptEdits` |
    | Plan | `plan` |
    | Auto | `auto` |
    | Bypass permissions | `bypassPermissions` |

    **As a default**: to pin the permission mode conversations start in, set `claudeCode.initialPermissionMode` in your VS Code user settings to `default`, `manual`, `acceptEdits`, `plan`, or `bypassPermissions`. The setting doesn't accept `auto`; to start in Auto, leave it unset and pick **Auto** from the mode indicator once, as item 2 below describes. The extension starts each new conversation in the first of these that applies:

    1. `claudeCode.initialPermissionMode`
    2. The mode you last picked from the mode indicator, if it was Manual, Edit automatically, or Auto. Picking Plan or Bypass permissions applies to that conversation only
    3. `permissions.defaultMode` from [managed settings](/docs/en/managed-settings) or `~/.claude/settings.json`
    4. The [built-in default](#which-mode-a-session-starts-in) for your plan, provider, and organization settings

    The extension never reads a project's `.claude/settings.json` or `.claude/settings.local.json` for the starting permission mode. When `claudeCode.claudeProcessWrapper` is set, items 3 and 4 don't apply: those conversations start in Manual unless item 1 or item 2 sets a permission mode.

    Before v2.1.283, item 3 applied only on Pro, Max, and Team plans in sessions that [fetch feature flags](/docs/en/env-vars#features-that-need-feature-flag-fetching).

    Auto appears in the mode indicator when [auto mode is available](#eliminate-prompts-with-auto-mode).

    Bypass permissions requires the **Allow dangerously skip permissions** toggle in the extension settings. Without it, the permission mode doesn't appear in the indicator, and a `bypassPermissions` value from item 1 or item 3 starts the conversation in Manual instead. Auto from any item likewise starts the conversation in Manual when auto mode isn't available.

    See the [VS Code guide](/docs/en/vs-code) for extension-specific details.
  </Tab>

  <Tab title="JetBrains">
    The JetBrains plugin runs Claude Code in the IDE terminal, so switching permission modes works the same as in the CLI: press `Shift+Tab` to cycle, or pass `--permission-mode` when launching.
  </Tab>

  <Tab title="Desktop">
    **During a session**: in the Code tab, use the mode selector next to the send button. Not every mode appears in the selector:

    * **Auto**: appears when [auto mode is available](#eliminate-prompts-with-auto-mode)
    * **Bypass permissions**: requires the **Allow bypass permissions mode** toggle in Desktop settings on Pro and Max plans; on Team and Enterprise plans, organization policy controls it instead

    The Cowork tab doesn't use these modes. Cowork has its own permission modes, enabled separately, and the Cowork tab shows no mode selector at all until a mode beyond its default is enabled for your account. See the [Cowork docs](https://claude.com/docs/cowork/overview).

    For desktop-specific details, see [Choose a permission mode](/docs/en/desktop#choose-a-permission-mode) in the Desktop guide.

    **As a default**: set `defaultMode` in [settings](/docs/en/settings#where-settings-live). The desktop app reads the same settings files as the CLI and applies the permission mode to new local sessions.

    A mode you pick in the mode selector is remembered per folder and takes precedence over `defaultMode` for that folder. Plan is the exception: picking it applies to the current session only.

    For where `defaultMode` goes in a settings file, see the example under [Start in a different permission mode](#start-in-a-different-mode).
  </Tab>

  <Tab title="Web and mobile">
    On [claude.ai/code](https://claude.ai/code), use the mode dropdown next to the prompt box. In the mobile app, tap the **+** button in the prompt box, then **Permission**. Cloud sessions and Remote Control sessions offer different permission modes:

    * **[Cloud sessions](/docs/en/claude-code-on-the-web)**: Accept edits, Plan, and Auto. Accept edits corresponds to `default` mode: cloud sessions pre-approve file edits regardless of mode, so the dropdown shows Accept edits instead of Manual. Cloud sessions still honor `defaultMode: "acceptEdits"` from settings. Auto mode appears only when your organization allows it and the selected model supports it. Bypass permissions isn't available.
    * **[Remote Control](/docs/en/remote-control) sessions** on your local machine: Manual, Accept edits, Plan, and Auto for a session you started yourself, and you can't select Bypass permissions from the app. To use Auto, the session has to meet the auto mode [availability requirements](#eliminate-prompts-with-auto-mode). For a project thread running on your computer, see [Run a thread on your own computer](/docs/en/claude-projects#run-a-thread-on-your-own-computer).
      * Except for Bypass permissions, the dropdown shows the permission mode the local session is in, including one set from the terminal. It updates when the permission mode changes in the app or in the terminal.
      * Sessions hosted by the [desktop app](/docs/en/desktop) or the [VS Code extension](/docs/en/vs-code) report permission mode changes to claude.ai as they happen, the same as sessions hosted in a terminal.
      * Before v2.1.202, sessions connected with `/remote-control` or `claude --remote-control` didn't report their permission mode at all, so claude.ai and the mobile app could show a permission mode the session wasn't in. The mismatch affected only the label. Claude Code generated permission prompts from the session's actual permission mode, and they still appeared in the app for approval.

    For Remote Control, the local machine running the session must be signed in with your claude.ai account; API keys aren't supported. You can also set the starting permission mode when launching that local session:

    ```bash theme={null}
    claude remote-control --permission-mode acceptEdits
    ```
  </Tab>
</Tabs>
