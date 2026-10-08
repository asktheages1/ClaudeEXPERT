[Part 5/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `permissions`

Control which tools Claude can use without asking, which ones always prompt, and which ones are blocked, and set the [permission mode](/docs/en/permission-modes) a session starts in. Every `permissions.*` key below nests under this object.

* **Scope**: [`Any file`](#scopes)
* **Type**: object with `allow`, `ask`, `deny`, `additionalDirectories`, `blockReadsOutsideWorkingDirectories`, `defaultMode`, `disableBypassPermissionsMode`, and `disableAutoMode`
* **Default**: unset

This example approves `npm run` commands without asking, prompts before `git push`, blocks reads of `.env`, and starts sessions in `acceptEdits`:

```json settings.json theme={null}
{
  "permissions": {
    "allow": ["Bash(npm run *)"],
    "ask": ["Bash(git push *)"],
    "deny": ["Read(./.env)"],
    "defaultMode": "acceptEdits"
  }
}
```

The three rule arrays share one syntax; see [Permission rule syntax](#permission-rule-syntax) under `permissions.allow`. For how permission rules from different files combine, see [how permission rules merge across scopes](/docs/en/permissions#settings-precedence); for how settings keys in general combine, see [Settings precedence](/docs/en/settings#settings-precedence) on the settings guide.

### `useAutoModeDuringPlan`

Choose whether Claude Code uses the auto mode classifier to review shell commands in plan mode. With the default `true`, the classifier reviews each command during planning when auto mode is available and you see no prompt, except for [critical-path removals](/docs/en/permission-modes#critical-paths). Set `false` to get a permission prompt for every command outside the built-in read-only set. Appears in `/config` as **Use auto mode during plan**.

* **Scope**: [`User, local, or managed`](#scopes). A repository can't turn it off for you.
* **Type**: Boolean
  * `true`: the same as unset; when auto mode is available, the classifier reviews each shell command during planning instead of prompting you for it, except [critical-path removals](/docs/en/permission-modes#critical-paths). A `false` in any of these files still turns it off
  * `false`: you get a permission prompt for every command outside the built-in read-only set
* **Default**: `true`

```json settings.json theme={null}
{
  "useAutoModeDuringPlan": false
}
```

### `permissions.allow`

List the tool uses Claude Code approves without asking you. In an MCP rule, `*` can appear only in the tool name after the `mcp__<server>__` prefix, such as `mcp__github__get_*`; it can't appear in the server name.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of permission rule strings
* **Default**: unset
* **Per-session overrides**: `--allowedTools` adds allow rules for one session, and a deny rule from any settings file still blocks a tool it names

This example approves `git diff` and lets Claude Code read your `.zshrc` without asking:

```json settings.json theme={null}
{
  "permissions": {
    "allow": ["Bash(git diff *)", "Read(~/.zshrc)"]
  }
}
```

Claude Code applies `allow` rules from a project's `.claude/settings.json` only after you accept the [workspace trust dialog](/docs/en/permissions#project-allow-rules-and-workspace-trust) for that folder.

#### Permission rule syntax

Permission rules follow the format `Tool` or `Tool(specifier)`. Claude Code evaluates `deny` rules first, then `ask`, then `allow`, and the first match decides regardless of how specific each rule is; see the [permission rule evaluation order](/docs/en/permissions#manage-permissions).

Each row shows one rule shape and what it matches.

| Rule | What it matches |
| :- | :- |
| `Bash` | Every Bash command |
| `Bash(npm run *)` | Commands starting with `npm run` |
| `Read(./.env)` | Reads of the `.env` file |
| `WebFetch(domain:example.com)` | Fetch requests to example.com |

For the complete rule syntax, including wildcard behavior, tool-specific patterns for Read, Edit, WebFetch, MCP, and Agent rules, and the security limitations of Bash patterns, see [Permission rule syntax](/docs/en/permissions#permission-rule-syntax).

### `permissions.ask`

List the tool uses that prompt you for confirmation even in a permission mode that would otherwise approve them, such as `acceptEdits` or `bypassPermissions`. In `dontAsk` mode Claude Code denies a matching tool use instead of prompting.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of permission rule strings
* **Default**: unset

```json settings.json theme={null}
{
  "permissions": {
    "ask": ["Bash(git push *)"]
  }
}
```

<span id="exclude-sensitive-files" />

### `permissions.deny`

List the tool uses Claude Code blocks. Use it for files that hold API keys, secrets, or environment values: Claude Code excludes matching files from file discovery and search results, denies reads of them, and blocks the [Edit and Write tools](/docs/en/permissions#read-and-edit) on the matching paths.

Read and Edit deny rules apply to Claude's built-in file tools, to file commands Claude Code recognizes in Bash, such as `cat`, `head`, `tail`, `sed`, and `tee`, and to the targets of Bash [redirections](/docs/en/permissions#redirections) such as `> file` and `< file`; they don't apply to a command that reads files without naming them, such as `grep -r pattern .`, or to arbitrary subprocesses, so for OS-level enforcement [enable the sandbox](/docs/en/sandboxing).

* **Scope**: [`Any file`](#scopes)
* **Type**: array of permission rule strings
* **Default**: unset
* **Per-session overrides**: `--disallowedTools` adds deny rules for one session alongside this key

This example denies reads of `.env` files, the `secrets` directory, and a credentials file, and blocks `curl` commands:

```json settings.json theme={null}
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)",
      "Bash(curl *)"
    ]
  }
}
```

Tool names accept glob patterns, so `"*"` denies every tool and `"mcp__*"` denies every MCP tool. Claude Code ignores a deny rule for the [`EndConversation`](/docs/en/tools-reference#endconversation-tool-behavior) tool as long as any other tool is still available to Claude. A `Bash` deny rule matches the command as Claude writes it, so `Bash(curl *)` doesn't stop `/usr/bin/curl` or `sh -c 'curl …'`; see [what a Bash rule doesn't match](/docs/en/permissions#bash-rule-limits). This key replaces the deprecated `ignorePatterns` configuration.

### `permissions.additionalDirectories`

Give Claude file access to directories outside the one you started in, as additional [working directories](/docs/en/permissions#working-directories). Most `.claude/` configuration is [not discovered](/docs/en/permissions#additional-directories-grant-file-access-not-configuration) from these directories.

* **Scope**: [`Any file`](#scopes), with [limits on the sandbox write access](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox) that project and local entries give
* **Type**: array of directory paths
* **Default**: unset
* **Per-session overrides**: `--add-dir` and `/add-dir` add directories for one session alongside this key

```json settings.json theme={null}
{
  "permissions": {
    "additionalDirectories": ["../docs/"]
  }
}
```

Like `allow` rules, entries in a project's `.claude/settings.json` take effect only after you accept the [workspace trust dialog](/docs/en/permissions#project-allow-rules-and-workspace-trust) for that folder.

### `permissions.blockReadsOutsideWorkingDirectories`

Make Claude's file tools refuse reads outside your [working directories](/docs/en/permissions#working-directories) in every permission mode, including `bypassPermissions`. Claude Code denies `Read`, `Grep`, `Glob`, and `LSP` calls on those paths and tells Claude to ask you to add the directory with `/add-dir`. Files Claude Code itself needs stay readable, such as your skills, plugins, rules, agents, commands, and the `CLAUDE.md` memory file under `~/.claude/`. Requires Claude Code v2.1.257 or later.

Claude Code doesn't refuse shell commands the same way:

* [Actions no mode auto-approves](/docs/en/permission-modes#actions-no-mode-auto-approves) covers when a shell command that reads such a path prompts you
* [Sandboxed commands under the block](#sandboxed-commands-under-the-block) covers what a sandboxed command can read

A Bash command the shell parser can't trace, such as one that changes directory more than once or runs a subshell, prompts you even in auto mode and `bypassPermissions` mode. The prompt appears even when the command names no path outside the working directories. This prompt doesn't apply when the command runs in the [sandbox](/docs/en/sandboxing) and the sandbox enforces the block.

Claude Code also writes `true` here when you choose to block such reads on [auto mode's prompt before the first read outside the working directories](/docs/en/permission-modes#first-read-outside-the-working-directories).

* **Scope**: [`Any file`](#scopes). A `true` in any file applies, so a repository can turn the block on for itself but can't lift yours.
* **Type**: Boolean
  * `true`: Claude's file tools refuse reads outside the working directories
  * `false`: the same as unset; the block still applies if another file sets `true`
* **Default**: unset, so reads outside the working directories follow your [permission mode](/docs/en/permission-modes)

```json settings.json theme={null}
{
  "permissions": {
    "blockReadsOutsideWorkingDirectories": true
  }
}
```

Directories you add with `--add-dir`, `/add-dir`, or `additionalDirectories` in your user or managed settings count as working directories for the block. Directories added only in repository settings don't count: those in `.claude/settings.json`, and those in `.claude/settings.local.json` unless git reports that file as untracked. In a directory that isn't a git repository, or when git tracks the file, Claude Code treats `.claude/settings.local.json` as repository settings, so put directories you want to keep readable in your user settings instead.

When [`autoMemoryDirectory`](#automemorydirectory) comes from the project's `.claude/settings.json`, or from a `.claude/settings.local.json` [treated as repository-supplied](/docs/en/permissions#when-your-local-settings-file-needs-trust), Claude Code loads no [auto memory](/docs/en/memory#storage-location) from that directory and saves none to it.

To lift the block, remove the key from every settings file that sets it, then start a new session.

#### Sandboxed commands under the block

When [sandboxing](/docs/en/sandboxing) is on, the block also covers sandboxed commands. Claude Code denies them read access to your home directory and to the other roots that hold user files: `/Users`, `/home`, `/root`, `/Volumes`, `/mnt`, `/media`, `/run/media`, and `/srv`. It then re-opens the working directories, [worktrees](/docs/en/worktrees) Claude Code creates in the session, the session temp directory, and the parts of `~/.claude` that commands need, such as skills and plugins. While the block is in force, `allowRead` and `allowWrite` entries from repository settings don't count.

When the session's working directory is a linked [git worktree](/docs/en/worktrees), including one Claude Code entered mid-session, the repository's common `.git` directory stays readable and writable to sandboxed commands, so git keeps working there.

In these cases the block doesn't reach sandboxed commands, while Claude's file tools keep enforcing it:

* Filesystem isolation is off through [`sandbox.filesystem.disabled`](#sandbox-filesystem-disabled)
* [`allowManagedReadPathsOnly`](#sandbox-filesystem-allowmanagedreadpathsonly) is set
* The path of the directory you started Claude Code in contains a glob character such as `*`, `?`, or `[`

Under the block, Claude Code re-opens your global git configuration files to sandboxed commands so `git` keeps your identity and settings:

* `~/.gitconfig`
* The `config`, `ignore`, and `attributes` files under `$XDG_CONFIG_HOME/git`, which defaults to `~/.config/git`
* Files your global git configuration names through `[include]`, `[includeIf]`, `core.excludesFile`, or `core.attributesFile`

Claude Code judges each file separately. When a file lies where a sandboxed command can write, directly or through a symlink, Claude Code doesn't re-open the files it names.

On Linux and WSL2, a configuration file that is a symlink can stay unreadable at its own path, and `git` then runs without it. `~/.git-credentials` and `$XDG_CONFIG_HOME/git/credentials` stay blocked.

If a re-opened file holds a secret, such as an `http.extraHeader` token, add its path to [`sandbox.filesystem.denyRead`](#sandbox-filesystem-denyread). A `denyRead` entry that covers a file always takes precedence over this re-open.

### `permissions.defaultMode`

Set the [permission mode](/docs/en/permission-modes) new sessions start in. When you leave it unset, sessions start in the [built-in default](/docs/en/permission-modes#which-mode-a-session-starts-in) for your surface.

* **Scope**: [`Any file`](#scopes). `auto` and `bypassPermissions` don't take effect from project or local settings, so set them in `~/.claude/settings.json` instead. Before v2.1.257, `bypassPermissions` took effect from any file. For conversations the VS Code extension starts, Claude Code reads only user, managed, and `--settings` values.
* **Type**: string, one of:
  * `"default"`: Claude Code runs only reads without asking
  * `"acceptEdits"`: Claude Code also runs file edits and common filesystem commands such as `mkdir` and `mv` without asking
  * `"plan"`: Claude Code reads and plans but blocks edits until you approve a plan
  * `"auto"`: Claude Code runs without routine prompts; before actions such as shell commands and network requests run, a background classifier checks that they align with your request
  * `"dontAsk"`: Claude Code auto-denies every call that would otherwise prompt; reads, other actions that need no approval, and pre-approved tools still run
  * `"bypassPermissions"`: Claude Code runs everything without asking
  * `"manual"`: an alias for `"default"`
* **Default**: unset
* **Per-session overrides**: `--permission-mode`, and its equivalent `--dangerously-skip-permissions` for `bypassPermissions`, take precedence over this key for one session

```json settings.json theme={null}
{
  "permissions": {
    "defaultMode": "acceptEdits"
  }
}
```

Permission rules layer on top of every mode: `deny` rules block in every mode, including `bypassPermissions`. See [Permission modes](/docs/en/permission-modes). In cloud sessions, Claude Code honors only `acceptEdits`, `plan`, `default`, and `auto` from this key. For conversations the VS Code extension starts, see [which setting the extension reads for the starting permission mode](/docs/en/permission-modes#switch-permission-modes).

### `permissions.disableBypassPermissionsMode`

Prevent anyone from entering `bypassPermissions` mode. Claude Code then rejects the `--dangerously-skip-permissions` flag, and ignores an [agent definition's](/docs/en/sub-agents#permission-modes) `permissionMode: bypassPermissions`, so the subagent runs with the parent session's permission mode.

* **Scope**: [`Any file`](#scopes). Typically set in [managed settings](/docs/en/managed-settings) to enforce organizational policy.
* **Type**: the string `"disable"`
* **Default**: unset
* **Per-session overrides**: this key takes precedence over `--dangerously-skip-permissions`, which Claude Code rejects while the key is set

```json settings.json theme={null}
{
  "permissions": {
    "disableBypassPermissionsMode": "disable"
  }
}
```

Before v2.1.223, Claude Code applied the frontmatter permission mode even with bypass disabled.

### `skipAutoPermissionPrompt`

Skip the one-time notice describing [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) that Claude Code shows when you first enter auto mode yourself, for example through your own settings or the mode selector, rather than when the built-in default starts a session in it. Claude Code shows that notice once and then records that it was shown, so this key only matters where the notice hasn't appeared yet.

* **Scope**: [`User or managed`](#scopes). A repository can't set it for you.
* **Type**: Boolean
  * `true`: Claude Code skips the notice
  * `false`: the same as unset; the notice appears once unless another of these files sets `true`
* **Default**: unset, so the notice appears once

```json settings.json theme={null}
{
  "skipAutoPermissionPrompt": true
}
```

### `skipDangerousModePermissionPrompt`

Skip the confirmation dialog Claude Code shows before a session enters `bypassPermissions` mode, whether from `--dangerously-skip-permissions` or from `defaultMode: "bypassPermissions"`. Claude Code writes `true` here in your user settings when you accept that dialog once.

* **Scope**: [`User, local, or managed`](#scopes). An untrusted repository can't skip the dialog for you.
* **Type**: Boolean
  * `true`: Claude Code skips the confirmation dialog before a session enters `bypassPermissions` mode
  * `false`: the same as unset; the dialog appears unless another of these files sets `true`
* **Default**: unset, so the dialog appears

```json settings.json theme={null}
{
  "skipDangerousModePermissionPrompt": true
}
```

## Sandbox settings

Isolate the commands Claude runs from your filesystem, your network, and your credentials. For how sandboxing works and platform requirements, see [Sandboxing](/docs/en/sandboxing).

### `sandbox`

Isolate the Bash commands Claude runs from your filesystem and network with [sandboxing](/docs/en/sandboxing). Turn the sandbox on with `enabled`, then narrow or widen what sandboxed commands can touch with the `filesystem`, `network`, and `credentials` sub-objects. The sandbox runs on macOS, Linux, and WSL2.

* **Scope**: [`Any file`](#scopes)
* **Type**: object with `enabled`, `failIfUnavailable`, `autoAllowBashIfSandboxed`, `excludedCommands`, `allowUnsandboxedCommands`, `enableWeakerNestedSandbox`, `enableWeakerNetworkIsolation`, `allowAppleEvents`, `bwrapPath`, `socatPath`, `ignoreViolations`, and `ripgrep`, plus the `filesystem`, `network`, and `credentials` objects
* **Default**: unset, so Claude Code runs commands without a sandbox

This turns the sandbox on, skips permission prompts for sandboxed commands, runs `docker` outside the sandbox, opens two extra write paths, hides your AWS credentials file, and pre-allows GitHub and npm:

```json settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker *"],
    "filesystem": {
      "allowWrite": ["/tmp/build", "~/.kube"],
      "denyRead": ["~/.aws/credentials"]
    },
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"]
    }
  }
}
```

When managed settings set a Boolean key such as `enabled` or `failIfUnavailable`, that value overrides anything a developer sets. Claude Code merges array keys across the settings scopes the session loads, so a developer can append entries; see [Keep developers from widening the policy](/docs/en/sandboxing#keep-developers-from-widening-the-policy) for the managed-only locks. To require the sandbox for an organization, see [Enforce sandboxing with managed settings](/docs/en/sandboxing#enforce-sandboxing-with-managed-settings).

### `sandbox.enabled`

Turn on [sandboxing](/docs/en/sandboxing) for Bash commands. When you pick a mode in the `/sandbox` panel, Claude Code writes this key to `.claude/settings.local.json` for the current project; set it in `~/.claude/settings.json` to sandbox every project.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: Boolean
  * `true`: Claude Code sandboxes Bash commands
  * `false`: Bash commands run unsandboxed
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "enabled": true
  }
}
```

On Linux and WSL2 the sandbox needs `bubblewrap` and `socat`; see [Set up Linux and WSL2](/docs/en/sandboxing#set-up-linux-and-wsl2). When the sandbox can't start, Claude Code runs commands unsandboxed unless you also set [`failIfUnavailable`](#sandbox-failifunavailable).

### `sandbox.failIfUnavailable`

Make Claude Code exit with an error at startup when `sandbox.enabled` is `true` but the sandbox can't start, because a dependency is missing or the platform is unsupported. Without this key, Claude Code runs commands unsandboxed. Managed deployments that require sandboxing as a security gate can use this setting.

On a platform the sandbox doesn't support, Claude Code doesn't start with this key on. See [Enforce sandboxing with managed settings](/docs/en/sandboxing#enforce-sandboxing-with-managed-settings).

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: Boolean
  * `true`: Claude Code exits with an error at startup when `sandbox.enabled` is `true` but the sandbox can't start
  * `false`: Claude Code runs commands unsandboxed when the sandbox can't start
* **Default**: `false`

This makes every managed machine sandbox commands or refuse to start:

```json managed-settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true
  }
}
```

See [Enforce sandboxing with managed settings](/docs/en/sandboxing#enforce-sandboxing-with-managed-settings).
