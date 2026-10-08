[Part 11/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `voiceEnabled`

<Warning>
  Deprecated since v2.1.92, when the [`voice`](#voice) object replaced it. Claude Code still reads it so older settings files keep working, but new configurations should set `voice.enabled`.
</Warning>

Turn voice dictation on with the single Boolean form that predates the `voice` object. When both are set, `voice.enabled` applies.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: voice dictation is on when you're logged in with a claude.ai account and your organization's policy allows voice, unless `voice.enabled` is set
  * `false`: voice dictation is off, unless `voice.enabled` is set
* **Default**: unset

```json settings.json theme={null}
{
  "voiceEnabled": true
}
```

### `wheelScrollAccelerationEnabled`

Accelerate mouse-wheel scroll speed during fast scrolls in [fullscreen rendering](/docs/en/fullscreen#mouse-wheel-scrolling). Set it to `false` for a constant scroll rate per wheel notch.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code accelerates mouse-wheel scroll speed during fast scrolls
  * `false`: Claude Code scrolls at a constant rate per wheel notch
* **Default**: `true`

```json settings.json theme={null}
{
  "wheelScrollAccelerationEnabled": false
}
```

## Git and attribution

Control the attribution Claude Code adds to commits and pull requests and how it works with git.

<span id="attribution-settings" />

### `attribution`

Customize the attribution Claude Code adds to git commits and pull requests. Commits get a [git trailer](https://git-scm.com/docs/git-interpret-trailers) such as `Co-Authored-By` by default; pull request descriptions get plain text. Set each part separately with the sub-keys below.

* **Scope**: [`Any file`](#scopes)
* **Type**: object with `commit` and `pr` strings and a `sessionUrl` Boolean, or `false` to hide all attribution. The `false` value requires Claude Code v2.1.281 or later; earlier versions reject it and [skip the whole user, project, or local settings file](/docs/en/settings#fix-a-broken-settings-file) that holds it
* **Default**: unset, so Claude Code uses the standard attribution shown under each sub-key

To hide all attribution, set `attribution` to `false`. In a settings file that earlier versions also read, set [`commit`](#attribution-commit) and [`pr`](#attribution-pr) to empty strings and [`sessionUrl`](#attribution-sessionurl) to `false` instead.

This example replaces the commit attribution, removes pull request attribution, and drops the session link:

```json settings.json theme={null}
{
  "attribution": {
    "commit": "Generated with AI\n\nCo-Authored-By: AI <ai@example.com>",
    "pr": "",
    "sessionUrl": false
  }
}
```

Once you set `commit` or `pr`, Claude Code ignores the deprecated `includeCoAuthoredBy` setting and uses its default text for whichever of the two you left unset.

Claude Code tells Claude that your own instructions about attribution, such as a CLAUDE.md or [memory](/docs/en/memory) rule, take precedence over these commit and PR lines, unless the line is set in [managed settings](/docs/en/managed-settings).

### `includeCoAuthoredBy`

<Warning>
  Deprecated since v2.0.62, when [`attribution`](#attribution) replaced it. Claude Code still reads it, but new configurations should set `attribution`.
</Warning>

Use [`attribution`](#attribution) instead, which replaces this key and lets you change or hide the commit trailer, the pull request text, and the session link separately. Claude Code still honors `includeCoAuthoredBy: false` from settings files that predate `attribution`, but ignores it once you set `attribution.commit` or `attribution.pr`.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: the same as unset; Claude Code adds the commit trailer and the pull request attribution text
  * `false`: Claude Code omits both the commit trailer and the pull request attribution text, unless `attribution` sets `commit` or `pr`, in which case the [`attribution`](#attribution) rules apply
* **Default**: `true`

```json settings.json theme={null}
{
  "includeCoAuthoredBy": false
}
```

To hide all attribution, see [`attribution`](#attribution).

### `includeGitInstructions`

Claude Code gives Claude two git-related pieces of context: its built-in instructions for how to write commits and pull requests, in the Bash tool's description, and a git status snapshot of your repository. The snapshot holds the current branch, the main branch, `git status` output, and recent commits. Claude Code reads it when a conversation starts.

Set this key to `false` to leave both out, for example when you use your own git workflow skills.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code includes its built-in commit and pull request workflow instructions and the git status snapshot. Cloud sessions never include the snapshot
  * `false`: Claude Code leaves both out
* **Default**: `true`
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS`](/docs/en/env-vars) takes precedence over this key for one session

```json settings.json theme={null}
{
  "includeGitInstructions": false
}
```

### `prUrlTemplate`

Point the PR links Claude Code renders, in the footer badge and in tool-result summaries, at an internal code-review tool instead of `github.com`. Claude Code substitutes `{host}`, `{owner}`, `{repo}`, `{number}`, and `{url}` from the PR URL. [GitLab merge request](/docs/en/interactive-mode#gitlab-merge-requests) links on both surfaces keep their GitLab URL.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, a URL template using any of the five placeholders
* **Default**: unset

```json settings.json theme={null}
{
  "prUrlTemplate": "https://reviews.example.com/{owner}/{repo}/pull/{number}"
}
```

Claude Code applies the template only to the links it renders itself; a PR number Claude writes in a message, such as `#123`, stays as Claude wrote it. A URL that doesn't have the `/pull/<number>` shape is left unchanged.

### `attribution.commit`

Set the attribution text Claude Code adds to git commits, including any trailers. Set it to an empty string to hide commit attribution.

* **Scope**: [`Any file`](#scopes)
* **Type**: string
* **Default**: unset, so Claude Code adds `Co-Authored-By: <name> <noreply@anthropic.com>`. The name is the model in use when the commit is made, such as `Claude Sonnet 5`. When a [subagent](/docs/en/sub-agents) makes the commit, the trailer names the subagent's model.
  * When Claude Code recognizes the model as a Claude model but can't confirm its exact version, it writes `Claude` alone.
  * When it can't match the model ID to any Claude model, such as a third-party model served through a custom [`ANTHROPIC_BASE_URL`](/docs/en/env-vars), it writes `Claude Code`.

This example replaces the default trailer with a custom line and a custom `Co-Authored-By` trailer:

```json settings.json theme={null}
{
  "attribution": {
    "commit": "Generated with AI\n\nCo-Authored-By: AI <ai@example.com>"
  }
}
```

### `attribution.pr`

Set the attribution text Claude Code adds to pull request descriptions. Set it to an empty string to hide pull request attribution.

* **Scope**: [`Any file`](#scopes)
* **Type**: string
* **Default**: unset, so Claude Code adds `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

```json settings.json theme={null}
{
  "attribution": {
    "pr": ""
  }
}
```

### `attribution.sessionUrl`

Choose whether Claude Code appends the claude.ai session link when it commits or opens a pull request from a [cloud](/docs/en/claude-code-on-the-web) or [Remote Control](/docs/en/remote-control) session. Claude Code adds the link as a `Claude-Session` trailer on commits and as a link in pull request descriptions. Set it to `false` to omit the link.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code appends the claude.ai session link when it commits or opens a pull request from a cloud or Remote Control session
  * `false`: Claude Code omits the link
* **Default**: `true`

```json settings.json theme={null}
{
  "attribution": {
    "sessionUrl": false
  }
}
```

<span id="hook-configuration" />

<span id="hook-and-skill-settings" />

## Hooks and automation

Register hooks, restrict which hooks run, and control workflows. For hook events and payloads, see the [hooks reference](/docs/en/hooks).

### `allowedHttpHookUrls`

Limit which URLs [HTTP hooks](/docs/en/hooks#http-hook-fields) can target. When you define this key, Claude Code runs an HTTP hook only if its URL matches one of the patterns and blocks the rest without running them; an empty array blocks every HTTP hook.

* **Scope**: [`Any file`](#scopes). Arrays merge across settings files.
* **Type**: array of URL patterns, with `*` as a wildcard
* **Default**: unset, so any URL is allowed

This example allows any URL under `https://hooks.example.com/` and any `http://localhost` URL:

```json settings.json theme={null}
{
  "allowedHttpHookUrls": ["https://hooks.example.com/*", "http://localhost:*"]
}
```

Hostname matching is case-insensitive and treats `hooks.example.com.`, with the trailing dot that marks a fully qualified domain name, the same as `hooks.example.com`, which is how DNS treats them. The allowlist applies to hooks from every source, including managed settings.

### `allowManagedHooksOnly`

Restrict hook execution to hooks your organization deploys.

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean
  * `true`: only managed hooks run, plus Agent SDK hooks and hooks from plugins your managed settings force-enable. See [What runs under `allowManagedHooksOnly`](#what-runs-under-allowmanagedhooksonly)
  * `false`: hooks from every settings scope and plugin run
* **Default**: unset, so hooks from every settings scope and plugin run

```json managed-settings.json theme={null}
{
  "allowManagedHooksOnly": true
}
```

#### What runs under `allowManagedHooksOnly`

When you set it to `true`, Claude Code changes which hooks and hook-like commands load:

* **Managed and SDK hooks run**: hooks from managed settings and hooks the [Agent SDK](/docs/en/agent-sdk/overview) registers in process
* **Force-enabled plugin hooks run**: hooks from plugins your managed settings force-enable through [`enabledPlugins`](#enabledplugins). Claude Code matches on the full `plugin@marketplace` ID, so a plugin with the same name from a different marketplace stays blocked. This lets you distribute vetted hooks through an organization marketplace while blocking everything else. A [mod](/docs/en/plugins/mods/overview) in such a plugin loads only when it [counts as your organization's](/docs/en/plugins/mods/admin#install-your-organizations-mods)
* **Everything else is blocked**: user, project, and local hooks, hooks and mods from other installed plugins, and hooks declared in agent frontmatter. [Mods built into Claude Code](/docs/en/plugins/mods/overview#mods-built-into-claude-code) keep running. To block only users' mods, set [`allowManagedModsOnly`](/docs/en/plugins/mods/admin#set-options-on-the-built-in-guard) instead.
* **Command-sourced plugins are disabled**: Claude Code also disables plugins with a [`command` source](/docs/en/plugins/marketplace-reference#command-plugin-source), including plugins force-enabled in managed `enabledPlugins`, unless you set [`disableCommandPluginSources`](#disablecommandpluginsources) to `false` explicitly
* **Marketplace `headersHelper` commands are blocked**: Claude Code also blocks marketplace [`headersHelper` commands](/docs/en/plugins/host-marketplace#authenticate-archive-downloads) unless [`disableCommandPluginSources`](#disablecommandpluginsources) is explicitly set to `false`, except for a marketplace that managed settings themselves declare. Requires Claude Code v2.1.238 or later
* **Status line and file suggestion narrow to managed settings**: Claude Code reads [`statusLine`](/docs/en/statusline), [`fileSuggestion`](#filesuggestion), and [`subagentStatusLine`](/docs/en/statusline#subagent-status-lines) from managed settings only, following the [status line and file suggestion gates](#status-line-and-file-suggestion-gates)

The [`/goal`](/docs/en/goal) command can't run while this key is set, because it depends on hooks.

### `disableAllHooks`

Turn off [hooks](/docs/en/hooks#disable-or-remove-hooks), any custom [status line](/docs/en/statusline), and any custom [file suggestion](#filesuggestion) command. Use it to turn all of these off temporarily without deleting them from your settings.

* **Scope**: [`Any file`](#scopes). Only managed settings can disable managed hooks.
* **Type**: Boolean
  * `true`: Claude Code turns off hooks, any custom status line, and any custom file suggestion command
  * `false`: hooks, the status line, and the file suggestion command run
* **Default**: unset, so hooks run

```json settings.json theme={null}
{
  "disableAllHooks": true
}
```

The reach depends on which file carries the key:

* **In managed settings**: Claude Code disables every configured hook, including managed ones, and keeps running the hooks the [Agent SDK](/docs/en/agent-sdk/overview) registers in process
* **In any other settings file**: Claude Code disables user, project, local, and plugin hooks; managed hooks, Agent SDK hooks, and hooks from plugins force-enabled in managed [`enabledPlugins`](#enabledplugins) keep running

The key also stops [mods](/docs/en/plugins/mods/overview), which are plugins whose code registers hooks:

* **In managed settings**: the mods in every installed plugin stop, your organization's included
* **In any other settings file**: the mods you installed stop, and [your organization's mods](/docs/en/plugins/mods/admin#install-your-organizations-mods) keep running

Mods built into Claude Code keep running in both cases. Each has [its own switch](/docs/en/plugins/mods/overview#mods-built-into-claude-code).

Keeping Agent SDK hooks running when managed settings set this key requires Claude Code v2.1.242 or later.

The [`/goal`](/docs/en/goal) command can't run while hooks are disabled, and the `/hooks` menu shows a notice instead of your hooks.

#### Status line and file suggestion gates

Claude Code makes two decisions for `statusLine`, `fileSuggestion`, and `subagentStatusLine`, in this order:

* **Off entirely**: when managed settings set `disableAllHooks`, or when the folder isn't trusted under the same [workspace trust rule as hooks in settings files](/docs/en/permissions#what-runs-before-you-trust-a-folder)
* **Narrowed to managed settings**: when [`allowManagedHooksOnly`](#allowmanagedhooksonly) is set, when `disableAllHooks` is `true` outside managed settings after [settings precedence](/docs/en/hooks#disable-or-remove-hooks) applies, or when you start Claude Code with `--safe-mode`

Under narrowing, Claude Code runs a managed value if one is deployed. Otherwise it skips your value without warning: the status line is disabled, and `@` autocomplete falls back to the built-in file suggestion.

### `disableWorkflows`

Turn off [dynamic workflows](/docs/en/workflows#turn-workflows-off) and the bundled workflow commands for everyone your settings reach, such as an organization through managed settings. To turn workflows on or off just for yourself, use [`enableWorkflows`](#enableworkflows) instead, which the **Dynamic workflows** toggle in `/config` writes to your user settings.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code turns off dynamic workflows and the bundled workflow commands for everyone your settings reach
  * `false`: the same as unset; whether workflows are on then follows [`enableWorkflows`](#enableworkflows) and your plan's default
* **Default**: `false`
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_WORKFLOWS`](/docs/en/env-vars) turns workflows off for one session; whichever of the two turns them off, the other can't turn them back on

```json settings.json theme={null}
{
  "disableWorkflows": true
}
```

### `enableWorkflows`

Turn [dynamic workflows](/docs/en/workflows) on or off for yourself when your plan's default isn't what you want. Appears in `/config` as **Dynamic workflows**, which writes this key to your user settings and removes it again when you toggle back to your plan's default. To turn workflows off for everyone from managed settings, use [`disableWorkflows`](#disableworkflows) instead.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code turns dynamic workflows on for you
  * `false`: Claude Code turns dynamic workflows off for you
* **Default**: unset, so workflows are on unless you're on the Pro plan, where they're off
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_WORKFLOWS`](/docs/en/env-vars) turns workflows off for one session, and `true` here can't turn them back on while it's set

```json settings.json theme={null}
{
  "enableWorkflows": true
}
```

[`disableWorkflows`](#disableworkflows) and your organization's workflows policy also take precedence: `enableWorkflows: true` can't turn workflows back on while any source turns workflows off. Claude Code hides the `/config` row while a source other than your user settings sets `enableWorkflows`, or sets `disableWorkflows` to `true`.

### `hooks`

Run your own commands, prompts, agents, HTTP requests, or MCP tools as [hooks](/docs/en/hooks) at points in Claude Code's lifecycle, such as before a tool call or when a session starts; the [hooks reference](/docs/en/hooks#hook-events) lists every event, its payload, and its exit codes. Each event maps to a list of matcher groups, and each group lists the handlers to run when the matcher applies.

* **Scope**: [`Any file`](#scopes). Hooks merge across files rather than replacing each other, and hooks from managed settings can't be removed from other files.
* **Type**: object keyed by [hook event](/docs/en/hooks#hook-events); each value is an array of `{ "matcher", "hooks" }` groups whose `hooks` entries have a `type` of `"command"`, `"prompt"`, `"agent"`, `"http"`, or `"mcp_tool"`
* **Default**: unset, so no hooks run

This example runs a script before every Bash tool call:

```json settings.json theme={null}
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "~/.claude/hooks/check-bash.sh" }
        ]
      }
    ]
  }
}
```

For every event, matcher pattern, and handler field, see the [hooks reference](/docs/en/hooks#configuration). To turn hooks off, see [`disableAllHooks`](#disableallhooks); to limit hooks to the ones your organization deploys, see [`allowManagedHooksOnly`](#allowmanagedhooksonly).

### `httpHookAllowedEnvVars`

An [HTTP hook](/docs/en/hooks#http-hook-fields) can put the value of an environment variable into a request header, for example an `Authorization: Bearer $HOOK_TOKEN` header, but only for variables the hook lists in its own `allowedEnvVars`. This key sets an outer limit on that list for every HTTP hook: a hook can use a variable only if both its own `allowedEnvVars` and this key name it. Use it to stop a hook from reading a secret it shouldn't, even when the hook's definition asks for it.

* **Scope**: [`Any file`](#scopes). Arrays merge across settings files.
* **Type**: array of environment variable names
* **Default**: unset, so each hook's own `allowedEnvVars` list applies

This example limits header interpolation to `MY_TOKEN` and `HOOK_SECRET`:

```json settings.json theme={null}
{
  "httpHookAllowedEnvVars": ["MY_TOKEN", "HOOK_SECRET"]
}
```

The allowlist applies to hooks from every source, including managed settings.

### `workflowKeywordTriggerEnabled`

Choose whether typing the keyword `ultracode` in a prompt triggers a [dynamic workflow](/docs/en/workflows#ask-for-a-workflow-in-your-prompt). Set it to `false` to type the word without triggering one.

* **Scope**: [`Any file`](#scopes). Appears in `/config` as **Ultracode keyword trigger**.
* **Type**: Boolean
  * `true`: typing `ultracode` in a prompt triggers a dynamic workflow
  * `false`: you can type the word without triggering one
* **Default**: `true`

```json settings.json theme={null}
{
  "workflowKeywordTriggerEnabled": false
}
```

The `ultracode` effort setting, `/workflows`, and saved workflow commands are unaffected.

### `workflowSizeGuideline`

Set the [agent count Claude aims for](/docs/en/workflows#set-a-size-guideline) in the dynamic workflows it writes. Claude Code sends the value to Claude as advice, not an enforced cap: `"small"` asks for fewer than 5 agents, `"medium"` fewer than 10, and `"large"` fewer than 50. Choose `"small"` when you want to bound what a workflow spends. Requires Claude Code v2.1.219 or later.

* **Scope**: [`Any file`](#scopes). A value there takes precedence over the **Dynamic workflow size** choice in `/config`, which Claude Code stores in `~/.claude.json`, and Claude Code hides that row while a settings file sets the key.
* **Type**: string, one of:
  * `"unrestricted"`: no guideline, so Claude sizes the workflow to the task
  * `"small"`: Claude aims for fewer than 5 agents
  * `"medium"`: Claude aims for fewer than 10 agents
  * `"large"`: Claude aims for fewer than 50 agents
* **Default**: `"medium"`, or `"small"` when you're signed in on a Pro plan with Claude Code v2.1.271 or later

```json settings.json theme={null}
{
  "workflowSizeGuideline": "small"
}
```

Requires Claude Code v2.1.219 or later; on v2.1.202 through v2.1.218, set the guideline in `/config` instead.

<span id="plugin-configuration" />

<span id="manage-plugins" />

<span id="plugin-settings" />
