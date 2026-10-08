[Part 14/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `allowManagedMcpServersOnly`

Make the managed allowlist the only one that applies. Claude Code then reads [`allowedMcpServers`](#allowedmcpservers) from managed settings alone and ignores allowlists in user, project, and local settings; [`deniedMcpServers`](#deniedmcpservers) still merges from every settings scope, so users can still block servers for themselves. Administrators set it so a user's own settings can't broaden what the managed allowlist permits.

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code reads `allowedMcpServers` from managed settings alone and ignores allowlists in user, project, and local settings
  * `false`: allowlists from every settings scope merge
* **Default**: `false`, so allowlists from every settings scope merge

This example locks the allowlist to managed settings and allows only the server named `github`:

```json managed-settings.json theme={null}
{
  "allowManagedMcpServersOnly": true,
  "allowedMcpServers": [
    { "serverName": "github" }
  ]
}
```

Users can still add MCP servers of their own; only servers that match the managed allowlist load. See [Restrict the allowlist to managed settings only](/docs/en/managed-mcp#restrict-the-allowlist-to-managed-settings-only).

### `deniedMcpServers`

Block specific MCP servers. Claude Code refuses to load a matching server wherever it's defined, including plugin servers, servers passed with `--mcp-config`, servers from `managed-mcp.json`, servers from [`managedMcpServers`](#managedmcpservers), and the claude.ai connectors [it fetches itself](/docs/en/mcp#how-connectors-reach-claude-code). In-process `type: "sdk"` servers are exempt; the app that started the session registers them.

* **Scope**: [`Any file`](#scopes). Entries from every file merge into one denylist, and [`allowManagedMcpServersOnly`](#allowmanagedmcpserversonly) doesn't change that. Deploy it in managed settings to enforce it.
* **Type**: array of objects, each with exactly one key: `serverName`, a string, so a claude.ai connector's display name such as `"claude.ai Slack"` works; `serverCommand`, an array of the command and its arguments matched exactly; or `serverUrl`, a URL pattern with `*` wildcards
* **Default**: unset, so no server is blocked; an empty array also blocks nothing

```json settings.json theme={null}
{
  "deniedMcpServers": [
    { "serverName": "filesystem" }
  ]
}
```

The denylist takes precedence over [`allowedMcpServers`](#allowedmcpservers), so a server on both lists is blocked. See [Policy-based control with allowlists and denylists](/docs/en/managed-mcp#policy-based-control-with-allowlists-and-denylists).

### `disableClaudeAiConnectors`

Turn off the [claude.ai MCP connectors](/docs/en/mcp#use-mcp-servers-from-claude-ai) [Claude Code fetches itself](/docs/en/mcp#how-connectors-reach-claude-code), so it neither fetches nor connects them. A `true` in any settings file applies: a checked-in project `.claude/settings.json` can opt a repository out of those connectors, but a project-level `false` can't override a user- or managed-level `true`.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code neither fetches nor connects those connectors
  * `false`: the same as unset; Claude Code fetches your connectors unless another settings file or `ENABLE_CLAUDEAI_MCP_SERVERS` turns them off
* **Default**: `false`, so Claude Code fetches your connectors
* **Per-session overrides**: [`ENABLE_CLAUDEAI_MCP_SERVERS`](/docs/en/env-vars) set to `false` turns connectors off for one session; whichever of the two turns them off, the other can't turn them back on

```json settings.json theme={null}
{
  "disableClaudeAiConnectors": true
}
```

Servers you pass explicitly with `--mcp-config` are unaffected. To block individual connectors instead of all of them, use [`deniedMcpServers`](#deniedmcpservers). See [Disable claude.ai connectors](/docs/en/mcp#disable-claude-ai-connectors).

### `disabledMcpjsonServers`

Reject specific servers defined in a project's `.mcp.json` file so Claude Code never connects them or asks you to approve them. A rejection in any settings file applies, including a project `.claude/settings.json` checked into the repository.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of strings, the server names as they appear in `.mcp.json`
* **Default**: unset

```json settings.json theme={null}
{
  "disabledMcpjsonServers": ["filesystem"]
}
```

Claude Code writes this key to `.claude/settings.local.json` when you reject a server in the approval dialog. `claude mcp get <name>` shows a rejected server as `✘ Rejected (see disabledMcpjsonServers in settings)`. Rejection takes precedence over [`enabledMcpjsonServers`](#enabledmcpjsonservers) and [`enableAllProjectMcpServers`](#enableallprojectmcpservers).

### `enableAllProjectMcpServers`

Approve every MCP server defined in project `.mcp.json` files without a prompt. Claude Code writes this key to `.claude/settings.local.json` when you choose to approve all servers in the approval dialog.

* **Scope**: [`Any file`](#scopes). In a folder whose trust dialog you haven't accepted, Claude Code honors it from user settings, managed settings, and `--settings` and ignores it in the shared project file, both in the session and for `claude mcp list` and `claude mcp get`; [Project server approvals and workspace trust](/docs/en/mcp#project-server-approvals-and-workspace-trust) says when an untracked `.claude/settings.local.json` counts too.
* **Type**: Boolean
  * `true`: Claude Code approves every MCP server defined in project `.mcp.json` files without a prompt
  * `false`: Claude Code asks you to approve each server. In a trusted folder, a `false` in a higher-precedence file overrides a `true` in a lower one; in a folder you haven't trusted, a `true` in any honored file is enough
* **Default**: unset, so Claude Code asks you to approve each server

```json settings.json theme={null}
{
  "enableAllProjectMcpServers": true
}
```

A [`disabledMcpjsonServers`](#disabledmcpjsonservers) entry still rejects a server.

### `enabledMcpjsonServers`

Approve specific servers defined in project `.mcp.json` files so Claude Code connects them without asking. Claude Code writes this key to `.claude/settings.local.json` when you approve a server in the approval dialog.

* **Scope**: [`Any file`](#scopes). In a folder whose trust dialog you haven't accepted, Claude Code honors it from user settings, managed settings, and `--settings` and ignores it in the shared project file, both in the session and for `claude mcp list` and `claude mcp get`; [Project server approvals and workspace trust](/docs/en/mcp#project-server-approvals-and-workspace-trust) says when an untracked `.claude/settings.local.json` counts too.
* **Type**: array of strings, the server names as they appear in `.mcp.json`
* **Default**: unset

This example approves the `memory` and `github` servers from the project's `.mcp.json`:

```json settings.json theme={null}
{
  "enabledMcpjsonServers": ["memory", "github"]
}
```

A [`disabledMcpjsonServers`](#disabledmcpjsonservers) entry still rejects a server.

### `managedMcpServers`

Provide remote MCP servers to every user from managed settings. Users keep the servers they add themselves and can't edit or remove the ones you provide. Requires Claude Code v2.1.259 or later.

* **Scope**: [`Managed`](#scopes). Claude Code drops the key with a warning in user, project, and local settings, and doesn't read it in the Claude Desktop app's Code tab on a third-party deployment or in the app's Cowork sessions, where Claude Desktop supplies and locks those sessions' MCP servers itself.
* **Type**: object keyed by server name. Each entry has the `.mcp.json` shape for an `http` or `sse` server: a required `https://` `url`, and optionally `headers`, `oauth`, and the other HTTP and SSE options. Claude Code drops entries that fail validation, and [What an entry can contain](/docs/en/managed-mcp#what-an-entry-can-contain) lists the conditions
* **Default**: unset, so managed settings provide no servers

This example provides one HTTP server named `search`:

```json managed-settings.json theme={null}
{
  "managedMcpServers": {
    "search": {
      "type": "http",
      "url": "https://search.example.com/mcp"
    }
  }
}
```

For precedence, how provided servers combine with `managed-mcp.json` and the allow and deny lists, and what users see, see [Provide servers through managed settings](/docs/en/managed-mcp#provide-servers-through-managed-settings).

## Agents, sessions, and worktrees

Set the default agent, control teammates and cross-session messaging, and configure worktrees. See [Subagents](/docs/en/sub-agents) and [Worktrees](/docs/en/worktrees).

### `agent`

Run the main thread as a named [subagent](/docs/en/sub-agents#invoke-subagents-explicitly), so Claude Code applies that subagent's system prompt, tool restrictions, and model to your session. The same key sets the default agent for sessions you dispatch from `claude agents`.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, the name of a built-in or custom agent
* **Default**: unset, so the main thread runs as Claude Code's default agent
* **Per-session overrides**: `--agent` takes precedence over this key for one session

```json settings.json theme={null}
{
  "agent": "code-reviewer"
}
```

A plugin's own `settings.json` can also supply this key; see [Ship default settings with your plugin](/docs/en/plugins/components#default-settings).

### `crossSessionInbound`

Choose what this session does with [messages arriving from your other Claude Code sessions](/docs/en/cross-session-messaging#control-inbound-messages). When no value applies, Claude Code decides per message from the two sessions' permission-mode classes. Requires Claude Code v2.1.224 or later.

* **Scope**: [`Any file`](#scopes). A project or local value applies only when it's stricter than the value managed settings, the `--settings` flag, or user settings give.
* **Type**: string, one of:
  * `"accept"`: Claude Code delivers the message to Claude
  * `"hold"`: Claude Code shows a notice for the message without delivering it
  * `"refuse"`: Claude Code drops the message
* **Default**: unset, so Claude Code decides per message

```json settings.json theme={null}
{
  "crossSessionInbound": "hold"
}
```

Claude Code reads managed settings first, then the `--settings` flag, then user settings, and applies the first value found. `refuse` is stricter than `hold`, and `hold` is stricter than `accept`. When none of the trusted sources sets a value, a project or local `hold` or `refuse` still applies, replacing the per-message default. In sessions with cross-session messaging, this key appears in `/config` as **Messages from your other sessions**, which writes it to user settings; the row requires Claude Code v2.1.232 or later, and Claude Code hides it while the `--settings` flag or managed settings set the key.

Claude Code [warns](/docs/en/errors#crosssessioninbound-must-be-one-of-accept-hold-refuse) when you set a value it doesn't recognize. While that value is present in a user, project, local, or `--settings` file, Claude Code holds inbound messages, even when a source that takes precedence sets `accept`. A `refuse` that another source sets still applies. Fix or remove the value to clear the hold.

When the unrecognized value is in [managed settings](/docs/en/managed-settings), Claude Code instead treats it as `refuse` until an administrator fixes it. Before v2.1.248, Claude Code ignored an unrecognized value without warning.

### `disableAgentView`

Turn off [background agents and agent view](/docs/en/agent-view): `claude agents`, `--bg`, `/background`, and the on-demand supervisor. Set it in [managed settings](/docs/en/managed-settings) to enforce it for an organization.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code turns off `claude agents`, `--bg`, `/background`, and the on-demand supervisor
  * `false`: agent view is available
* **Default**: unset, so agent view is available
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_AGENT_VIEW`](/docs/en/env-vars) turns agent view off for one session; whichever of the two turns it off, the other can't turn it back on

```json settings.json theme={null}
{
  "disableAgentView": true
}
```

### `isolatePeerMachines`

Require your explicit approval before Claude's `SendMessage` reaches one of your sessions beyond this machine; see [Require approval for cross-machine messages](/docs/en/cross-session-messaging#require-approval-for-cross-machine-messages). The approval prompt appears even in [`bypassPermissions` mode](/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode).

* **Scope**: [`Any file`](#scopes). A `true` from any scope applies, so a checked-in project file can turn the requirement on but not off.
* **Type**: Boolean
  * `true`: Claude Code asks for your approval before Claude's `SendMessage` reaches one of your sessions beyond this machine
  * `false`: cross-machine messages don't prompt
* **Default**: unset, so cross-machine messages don't prompt

```json settings.json theme={null}
{
  "isolatePeerMachines": true
}
```

The cross-machine `SendMessage` approval requires Claude Code v2.1.224 or later.

### `processWrapper`

On macOS and Linux, place a corporate launcher command in front of the [background processes Claude Code starts](/docs/en/corporate-launcher#what-the-launcher-covers). Claude Code runs the launcher with its own command line appended, so the launcher must exec into Claude Code; see [Run Claude Code behind a corporate launcher](/docs/en/corporate-launcher) for the launcher contract. Requires Claude Code v2.1.210 or later.

* **Scope**: [`User or managed`](#scopes)
* **Type**: string, the launcher command as an argv prefix, such as an absolute path with optional arguments
* **Default**: unset, so background processes start unwrapped
* **Per-session overrides**: [`CLAUDE_CODE_PROCESS_WRAPPER`](/docs/en/env-vars) takes precedence over this key for one session

```json settings.json theme={null}
{
  "processWrapper": "/opt/corp/launcher --profile claude"
}
```

Claude Code ignores the launcher on Windows and starts every process unwrapped. Requires Claude Code v2.1.210 or later.

### `teammateMode`

Choose where Claude Code shows [agent team](/docs/en/agent-teams) teammates: inside your main terminal pane, or in split panes when your terminal supports them. See [Choose a display mode](/docs/en/agent-teams#choose-a-display-mode).

* **Scope**: [`Any file`](#scopes). Claude Code also reads a value left in `~/.claude.json` by older versions.
* **Type**: string, one of:
  * `"in-process"`: teammates run inside your main terminal pane
  * `"auto"`: split panes when you're running inside tmux, or inside iTerm2 with `it2` on your `PATH` or tmux installed; in-process otherwise
  * `"tmux"`: split panes using tmux or iTerm2, detected from your terminal
  * `"iterm2"`: iTerm2 native split panes through the `it2` CLI
* **Default**: `"in-process"`
* **Per-session overrides**: `--teammate-mode` takes precedence over this key for one session

```json settings.json theme={null}
{
  "teammateMode": "auto"
}
```

<span id="worktree-settings" />

### `worktree`

Configure how Claude Code creates and manages [git worktrees](/docs/en/worktrees) for `--worktree`, the `EnterWorktree` tool, and isolated subagents and background sessions.

* **Scope**: [`Any file`](#scopes)
* **Type**: object with `baseRef`, `symlinkDirectories`, `sparsePaths`, and `bgIsolation`
* **Default**: unset

This example branches new worktrees from your current `HEAD` and symlinks `node_modules` into each one:

```json settings.json theme={null}
{
  "worktree": {
    "baseRef": "head",
    "symlinkDirectories": ["node_modules"]
  }
}
```

To copy gitignored files like `.env` into new worktrees, add a [`.worktreeinclude` file](/docs/en/worktrees#copy-gitignored-files-into-worktrees) to your project root instead of a setting.

### `worktree.baseRef`

Choose which ref new worktrees branch from. `"fresh"` branches from `origin/<default-branch>` for a clean tree matching the remote; `"head"` branches from your current local `HEAD`, so unpushed commits and feature-branch state are present in the worktree.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"fresh"`: new worktrees branch from `origin/<default-branch>`
  * `"head"`: new worktrees branch from your current local `HEAD`, including unpushed commits
* **Default**: `"fresh"`

```json settings.json theme={null}
{
  "worktree": {
    "baseRef": "head"
  }
}
```

Inside a linked worktree, `"head"` resolves to that worktree's `HEAD`, not the main checkout's.

### `worktree.symlinkDirectories`

Symlink directories from the main repository into each worktree so you don't duplicate large directories on disk.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of strings, directory paths relative to the repository root
* **Default**: unset, so Claude Code symlinks no directories

This example symlinks `node_modules` and `.cache` from the main repository into every new worktree:

```json settings.json theme={null}
{
  "worktree": {
    "symlinkDirectories": ["node_modules", ".cache"]
  }
}
```

### `worktree.sparsePaths`

Check out only the listed directories in each worktree through git sparse-checkout. Claude Code writes only those directories plus root-level files to disk, which is faster in large monorepos; see [Check out only the directories you need](/docs/en/large-codebases#check-out-only-the-directories-you-need).

* **Scope**: [`Any file`](#scopes)
* **Type**: array of strings, directory paths relative to the repository root
* **Default**: unset, so each worktree checks out the whole tree

This example checks out only `packages/my-app` and `shared/utils`, plus root-level files, in each worktree:

```json settings.json theme={null}
{
  "worktree": {
    "sparsePaths": ["packages/my-app", "shared/utils"]
  }
}
```

While a sparse worktree exists, git enables `extensions.worktreeConfig` in the repository's shared `.git/config`.

### `worktree.bgIsolation`

Choose how [background sessions](/docs/en/agent-view#how-file-edits-are-isolated) isolate their file edits. If you moved a session to the background with `←` or `/background`, that session edits files in place whatever this key says. With `"worktree"`, Claude Code blocks `Edit` and `Write` in the main checkout until the session calls `EnterWorktree`; with `"none"`, background jobs edit the working copy directly. Set `"none"` for a repository where git worktrees are impractical.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"worktree"`: Claude Code blocks `Edit` and `Write` in the main checkout until the session calls `EnterWorktree`
  * `"none"`: background jobs edit the working copy directly
* **Default**: `"worktree"`

```json settings.json theme={null}
{
  "worktree": {
    "bgIsolation": "none"
  }
}
```

Outside a git repository, a [`WorktreeCreate` hook](/docs/en/worktrees#non-git-version-control) that fails releases the block so the session can edit the working directory in place; that release requires Claude Code v2.1.203 or later.

## Remote, desktop, and notifications

Configure Remote Control, cloud environments, the desktop app, and the notifications Claude Code sends when it needs you. See [Remote Control](/docs/en/remote-control).

### `agentPushNotifEnabled`

Allow Claude to send a push notification to your phone when it decides one is worth sending, for example when a long task finishes. Claude Code syncs this choice to your account, and pushes arrive while [Remote Control](/docs/en/remote-control) is connected. Appears in `/config` as **Push when Claude decides**.

* **Scope**: [`Any file`](#scopes). Claude Code also reads a value left in `~/.claude.json` by older versions.
* **Type**: Boolean
  * `true`: Claude can send a push notification to your phone when it decides one is worth sending
  * `false`: Claude doesn't send those notifications
* **Default**: `false`

```json settings.json theme={null}
{
  "agentPushNotifEnabled": true
}
```

See [Mobile push notifications](/docs/en/remote-control#mobile-push-notifications).

### `awaySummaryEnabled`

Show a one-line session recap when you return to the terminal after a few minutes away. Set it to `false`, or turn off **Session recap** in `/config`, to stop the recap.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: you see a one-line session recap when you return after a few minutes away
  * `false`: Claude Code shows no recap
* **Default**: unset, so the recap is on
* **Per-session overrides**: [`CLAUDE_CODE_ENABLE_AWAY_SUMMARY`](/docs/en/env-vars) takes precedence over this key for one session, in either direction

```json settings.json theme={null}
{
  "awaySummaryEnabled": false
}
```

Claude Code never shows the recap in non-interactive mode.

### `disableArtifact`

<Warning>
  Deprecated, and replaced by [`enableArtifact`](#enableartifact). Claude Code still honors `disableArtifact: true` as equivalent to `enableArtifact: false`, and ignores `disableArtifact: false`.
</Warning>

Use [`enableArtifact`](#enableartifact) instead to turn off the [Artifact](/docs/en/artifacts) tool, which publishes session output as a private web page on claude.ai. When you turn the **Artifacts** row off in `/config`, Claude Code writes `enableArtifact` to your user settings and clears this key.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code turns the Artifact tool off for every session the file applies to, and no other file turns it back on
  * `false`: ignored; to leave the tool on, remove the key
* **Default**: unset, so the tool follows your account's [availability](/docs/en/artifacts#availability)
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_ARTIFACT`](/docs/en/env-vars) set to `1` turns the tool off for one session

```json settings.json theme={null}
{
  "disableArtifact": true
}
```

[Disable artifacts](/docs/en/artifacts#disable-artifacts) lists every way to turn the tool off.
