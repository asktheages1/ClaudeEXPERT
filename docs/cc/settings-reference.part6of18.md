[Part 6/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `sandbox.autoAllowBashIfSandboxed`

Let Claude Code run sandboxed Bash commands without a permission prompt. Commands that can't run in the sandbox still go through the regular permission flow, and `deny` rules and content-scoped `ask` rules such as `Bash(git push *)` still apply; a bare `Bash` ask rule is skipped for sandboxed commands. Set it to `false` to send sandboxed commands through the regular permission flow too, which the `/sandbox` **Mode** tab calls regular permissions mode.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code runs sandboxed Bash commands without a permission prompt, subject to `deny` rules and content-scoped `ask` rules; `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` turns auto-allow off
  * `false`: sandboxed commands go through the regular permission flow, so your allow rules and permission mode decide. The `/sandbox` **Mode** tab calls this regular permissions mode
* **Default**: `true`

This keeps the sandbox on and sends sandboxed commands through the regular permission flow:

```json settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": false
  }
}
```

See [Sandbox modes](/docs/en/sandboxing#sandbox-modes) for what auto-allow mode still prompts on and how it behaves in plan mode.

### `sandbox.excludedCommands`

Name commands that Claude Code runs outside the sandbox, such as tools that don't work under it. Each entry uses the same syntax as the content of a `Bash(...)` [permission rule](/docs/en/permissions#permission-rule-syntax): an exact command, a prefix such as `docker *`, or a wildcard pattern. A pattern with no wildcard is an exact match, so `docker` matches only `docker` with no arguments.

Your entries take a Bash call out of the sandbox only when they cover every command in it, and some call shapes stay sandboxed even then. A `docker *` entry alone doesn't take `npm ci && docker build .` out of the sandbox.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: array of command patterns
* **Default**: unset, so no command is excluded

```json settings.json theme={null}
{
  "sandbox": {
    "excludedCommands": ["docker *"]
  }
}
```

Claude Code keeps a Bash call sandboxed when it has one of these shapes, among others:

* A command starting with `sudo`, `eval`, or `xargs`
* A `cd`, `pushd`, or `popd`, wherever it appears in the call
* A command substitution, a subshell, or a control-flow block such as `if` or `for`
* A redirection, such as `docker build . > build.log`, other than one that only duplicates a file descriptor, as `2>&1` does
* A command name that comes from a variable
* A `git clone`, `git init`, `git worktree add`, `git worktree move`, or `git bundle create` with a path argument that is absolute, starts with `~`, or contains a `..` segment

For example, `cd build && docker compose up` stays sandboxed under a `docker *` entry, and adding a `cd` entry doesn't change that. Under a `git *` entry, `git clone <url> vendor/lib` runs outside the sandbox, but `git clone <url> ~/tools` stays sandboxed. A clone writes a whole tree of files, possibly executable ones, wherever its destination path points.

Excluded commands still go through the regular permission flow. Exclusion is a convenience, not a security boundary: when a tool only needs to write somewhere specific, [`filesystem.allowWrite`](#sandbox-filesystem-allowwrite) keeps it sandboxed.

Entries from the settings scopes the session loads combine into one list unless the sandbox is [admin-required](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox). While it is, Claude Code ignores entries in `.claude/settings.json` and `.claude/settings.local.json`, so a cloned repository can't take commands out of the sandbox. Entries in managed settings, `--settings`, and your `~/.claude/settings.json` still apply, and no managed-only lock covers this list.

### `sandbox.allowUnsandboxedCommands`

Let Claude retry a command outside the sandbox with the `dangerouslyDisableSandbox` parameter after the sandbox blocks it. When it's `false`, Claude Code ignores that parameter. While the sandbox is running, commands Claude runs are then sandboxed unless they match an [`excludedCommands`](#sandbox-excludedcommands) entry. The `/sandbox` **Overrides** tab shows that state as **Strict sandbox mode**. A `false` in managed settings turns on strict sandbox mode for the developers it covers.

* **Scope**: [`Any file`](#scopes), with [a limit on project and local settings](/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)
* **Type**: Boolean
  * `true`: Claude can retry a command outside the sandbox with the `dangerouslyDisableSandbox` parameter after the sandbox blocks it
  * `false`: Claude Code ignores that parameter, so while the sandbox is running, commands Claude runs are sandboxed unless they match an `excludedCommands` entry
* **Default**: `true`

This enforces strict sandbox mode for everyone the managed settings cover:

```json managed-settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "allowUnsandboxedCommands": false
  }
}
```

A `false` from managed settings or `--settings` also makes the sandbox [admin-required](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox). A `false` in your user settings holds against a project's `true` but doesn't make the sandbox admin-required. Holding against a project's value requires Claude Code v2.1.285 or later.

Who approves an unsandboxed retry depends on your permission mode and allow rules. See [The unsandboxed retry escape hatch](/docs/en/sandboxing#the-unsandboxed-retry-escape-hatch).

To see when commands you type yourself at the [`!` shell-mode prompt](/docs/en/interactive-mode#shell-mode-with-prefix) run sandboxed, see [strict sandbox mode](/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode).

### `sandbox.filesystem`

Control which paths sandboxed commands can read and write. By default they can write to the working directory, the per-user temp directory, and directories you add with `--add-dir`, `/add-dir`, or `permissions.additionalDirectories`, and can read the rest of the filesystem, including credential files. Widen or narrow that with the four path lists, or switch the filesystem layer off with `disabled`. See [Filesystem isolation](/docs/en/sandboxing#filesystem-isolation) for the default boundaries.

* **Scope**: [`Any file`](#scopes)
* **Type**: object with `allowWrite`, `denyWrite`, `denyRead`, and `allowRead` arrays, plus the `allowManagedReadPathsOnly` and `disabled` Booleans
* **Default**: unset, so the default read and write boundaries apply

This lets sandboxed commands write to a build directory and your kubeconfig, and hides your AWS credentials file:

```json settings.json theme={null}
{
  "sandbox": {
    "filesystem": {
      "allowWrite": ["/tmp/build", "~/.kube"],
      "denyRead": ["~/.aws/credentials"]
    }
  }
}
```

Claude Code enforces these lists at the OS sandbox boundary, so they apply to every subprocess a sandboxed command starts, such as `kubectl`, `terraform`, or `npm`. Claude Code adds your [permission rules](/docs/en/sandboxing#permission-rules) to the same lists: `Edit` allow and deny rules to `allowWrite` and `denyWrite`, `Read` deny rules to `denyRead`, and `WebFetch(domain:...)` allow and deny rules to the [`network`](#sandbox-network) domain lists.

Unless a lock applies, Claude Code merges these lists across the settings files the session loads. [`allowManagedReadPathsOnly`](#sandbox-filesystem-allowmanagedreadpathsonly) limits `allowRead` to entries from managed settings, and [`allowManagedDomainsOnly`](#sandbox-network-allowmanageddomainsonly) does the same for allowed domains. [Repository locks](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox) leave out entries from a repository's settings files.

[Configure sandboxing](/docs/en/sandboxing#configure-sandboxing) covers sources you exclude with `--setting-sources`. When you edit a list during a session, Claude Code [applies the change to the running session](/docs/en/settings#when-edits-take-effect).

#### Sandbox path prefixes

Paths in `allowWrite`, `denyWrite`, `denyRead`, `allowRead`, and [`credentials.files`](#sandbox-credentials-files) resolve by their prefix:

| Prefix | Meaning | Example |
| :- | :- | :- |
| `/` | Absolute path from filesystem root | `/tmp/build` stays `/tmp/build` |
| `~/` | Relative to home directory | `~/.kube` becomes `$HOME/.kube` |
| `./` or no prefix | Relative to the project root for project settings, or to `~/.claude` for user settings | `./output` in `.claude/settings.json` resolves to `<project-root>/output` |

The `//path` prefix for absolute paths also works. If you use single-slash `/path` expecting project-relative resolution, switch to `./path`. This syntax differs from [Read and Edit permission rules](/docs/en/permissions#read-and-edit), which use `//path` for absolute and `/path` for project-relative: sandbox filesystem paths use standard conventions, so `/tmp/build` is an absolute path.

Claude Code strips a trailing slash from a directory path, so `~/.aws` and `~/.aws/` match the same directory. Before v2.1.224, Claude Code passed the trailing slash through to the sandbox, and Claude could still read or write paths under a `denyRead` or `denyWrite` entry written with one.

Claude Code also removes a trailing `/**`, so `~/build/**` and `~/build` cover the same directory. Whether a wildcard such as `*` works depends on which list the entry is in and on the platform:

* **`allowWrite` and `denyWrite`**: on macOS, wildcards work. On Linux and WSL2, the sandbox mounts concrete paths, so Claude Code skips an entry that contains `*`, `?`, or `[` once the trailing `/**` is removed, and that entry has no effect. Claude Code adds the paths from your `Edit` permission rules to these lists, so the same limit applies to them, and the **Config** tab of `/sandbox` warns about `Edit` and `Read` permission rules that contain wildcards.
* **`denyRead` and `allowRead`**: wildcards work on every platform. On Linux and WSL2, Claude Code expands a read entry to the concrete paths it matches, which it doesn't do for the write lists.

### `sandbox.filesystem.allowWrite`

Add paths where sandboxed commands can write, beyond the working directory, the per-user temp directory, and the directories you've added with `--add-dir`, `/add-dir`, or `permissions.additionalDirectories`. Use it when a subprocess such as `kubectl` or a build tool needs to write outside the project.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: array of path strings, using the [sandbox path prefixes](#sandbox-path-prefixes)
* **Default**: unset, so sandboxed commands can write to the working directory, the per-user temp directory, directories you've added with `--add-dir` or `/add-dir`, and directories in [`permissions.additionalDirectories`](#permissions-additionaldirectories)

This lets a build write under `/tmp/build` and lets `kubectl` update your kubeconfig:

```json settings.json theme={null}
{
  "sandbox": {
    "filesystem": {
      "allowWrite": ["/tmp/build", "~/.kube"]
    }
  }
}
```

Claude Code merges `allowWrite` entries and the paths from your `Edit(...)` allow permission rules across the settings scopes the session loads, leaving out the ones from repository settings while [`permissions.blockReadsOutsideWorkingDirectories`](#sandboxed-commands-under-the-block) is on. [Repository locks](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox) can leave out a repository's entries too. An `allowWrite` entry can't lift a [protected path](/docs/en/sandboxing#protected-paths).

### `sandbox.filesystem.denyWrite`

Block sandboxed commands from writing to specific paths, including paths inside a directory that is otherwise writable.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of path strings, using the [sandbox path prefixes](#sandbox-path-prefixes)
* **Default**: unset

This keeps sandboxed commands from changing system configuration or installing binaries:

```json settings.json theme={null}
{
  "sandbox": {
    "filesystem": {
      "denyWrite": ["/etc", "/usr/local/bin"]
    }
  }
}
```

Claude Code merges entries across every settings scope the session loads, and adds the paths from your `Edit(...)` deny permission rules.

### `sandbox.filesystem.denyRead`

Block sandboxed commands from reading specific paths, such as credential files that the default read policy would otherwise expose. To protect a credential file and keep it usable through the sandbox proxy, see [`sandbox.credentials`](#sandbox-credentials) instead.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of path strings, using the [sandbox path prefixes](#sandbox-path-prefixes)
* **Default**: unset, so sandboxed commands keep the [default read access](/docs/en/sandboxing#filesystem-isolation), which includes credential files such as `~/.aws/credentials`

```json settings.json theme={null}
{
  "sandbox": {
    "filesystem": {
      "denyRead": ["~/.aws/credentials"]
    }
  }
}
```

Claude Code merges entries across every settings scope the session loads, and adds the paths from your `Read(...)` deny permission rules. When [`filesystem.disabled`](#sandbox-filesystem-disabled) is `true`, Claude Code doesn't enforce these entries.

### `sandbox.filesystem.allowRead`

Re-open reading for specific paths inside a region that [`denyRead`](#sandbox-filesystem-denyread) blocks, to build workspace-only read access. An exact or wildcard `denyRead` entry stays blocked inside a broader `allowRead`, as the [overlap table](/docs/en/sandboxing#configure-sandboxing) shows. When a wildcard `denyRead` entry such as `~/**/.env` matches a directory, Claude Code blocks reads of its contents as well. Before v2.1.236 on macOS, Claude Code re-opened the paths a wildcard `denyRead` entry matched wherever a broader `allowRead` entry covered them, and left a matched directory's contents readable.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: array of path strings, using the [sandbox path prefixes](#sandbox-path-prefixes)
* **Default**: unset

This blocks reads of your home directory except the project itself:

```json settings.json theme={null}
{
  "sandbox": {
    "filesystem": {
      "denyRead": ["~/"],
      "allowRead": ["."]
    }
  }
}
```

Claude Code resolves a `.` entry to the project root in project settings and to `~/.claude` in user settings. Claude Code merges entries across the settings files the session loads unless [`allowManagedReadPathsOnly`](#sandbox-filesystem-allowmanagedreadpathsonly) is set, and leaves out entries from repository settings while [`permissions.blockReadsOutsideWorkingDirectories`](#sandboxed-commands-under-the-block) is on. [Repository locks](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox) can leave out a repository's entries too.

### `sandbox.filesystem.allowManagedReadPathsOnly`

Honor only the [`allowRead`](#sandbox-filesystem-allowread) entries that come from managed settings, so developers can't re-open read access to paths your organization blocked. Claude Code still merges `denyRead` entries from every settings scope the session loads.

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code honors only the `allowRead` entries from managed settings
  * `false`: `allowRead` entries from other settings files can merge in
* **Default**: `false`

This blocks reads of the home directory, re-opens `~/work`, and stops developers from re-opening anything else:

```json managed-settings.json theme={null}
{
  "sandbox": {
    "filesystem": {
      "denyRead": ["~/"],
      "allowRead": ["~/work"],
      "allowManagedReadPathsOnly": true
    }
  }
}
```

See [Keep developers from widening the policy](/docs/en/sandboxing#keep-developers-from-widening-the-policy).

### `sandbox.filesystem.disabled`

Skip filesystem isolation while keeping network isolation. Sandboxed commands get unrestricted read and write access to the host filesystem, and their network egress stays confined to [`network.allowedDomains`](#sandbox-network-alloweddomains). Use it when you sandbox to control where commands connect rather than what they write. Requires Claude Code v2.1.216 or later.

* **Scope**: [`User or managed`](#scopes). When managed settings configure `sandbox.filesystem` at all, or list a `sandbox.credentials.files` entry with `"mode": "deny"`, only managed settings can set it.
* **Type**: Boolean
  * `true`: Claude Code skips filesystem isolation and keeps network isolation
  * `false`: filesystem isolation stays on
* **Default**: `false`, so filesystem isolation stays on

This leaves the filesystem open and confines network egress to GitHub and npm:

```json settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "disabled": true
    },
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"]
    }
  }
}
```

With the layer off, Claude Code doesn't enforce `denyRead` or `credentials.files` `deny` entries, while `credentials.envVars` entries and applied `mask` entries keep working. [`autoAllowBashIfSandboxed`](#sandbox-autoallowbashifsandboxed) still defaults to `true`, so set it to `false` to keep prompting. See [Disable filesystem isolation](/docs/en/sandboxing#disable-filesystem-isolation) for the full list of sources that can set it and what changes when isolation is off. Requires Claude Code v2.1.216 or later.

### `sandbox.ignoreViolations`

Silence sandbox violation reports for paths you expect a command to probe and be refused, such as a tool that checks `/etc/hosts` on startup, so those denials don't show up as violations or in what Claude sees. The sandbox still blocks the access; only the report is suppressed. Keys are substrings to match against the command, with `*` matching every command, and values are substrings of the violation to ignore for that command, such as a filesystem path.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: object mapping a command substring to an array of violation substrings, usually paths
* **Default**: unset, so every violation is reported

```json settings.json theme={null}
{
  "sandbox": {
    "ignoreViolations": {
      "*": ["/etc/hosts"]
    }
  }
}
```

### `sandbox.enableWeakerNestedSandbox`

Run the Linux sandbox inside an unprivileged Docker container, where bubblewrap can't mount a fresh `/proc`. Instead the inner sandbox bind-mounts the container's existing `/proc`, which exposes process information that a fresh mount would hide. This reduces security; use it only when the outer container already provides the isolation you need.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: Boolean
  * `true`: the inner sandbox bind-mounts the container's existing `/proc` instead of mounting a fresh one
  * `false`: the sandbox mounts a fresh `/proc`, which doesn't work in an unprivileged Docker container
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "enableWeakerNestedSandbox": true
  }
}
```

Linux and WSL2 only. See [Bubblewrap fails to start inside a container](/docs/en/sandboxing#bubblewrap-fails-to-start-inside-a-container).

### `sandbox.enableWeakerNetworkIsolation`

Let sandboxed commands on macOS reach the system TLS trust service, `com.apple.trustd.agent`. Go-based tools such as `gh`, `gcloud`, and `terraform` need it to verify TLS certificates when you use [`network.httpProxyPort`](#sandbox-network-httpproxyport) with a MITM proxy and a custom CA. This reduces security by opening a potential data exfiltration path through the trust service.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: Boolean
  * `true`: sandboxed commands on macOS can reach `com.apple.trustd.agent`
  * `false`: sandboxed commands on macOS can't reach the system TLS trust service
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "enableWeakerNetworkIsolation": true
  }
}
```

If you don't use a MITM proxy, list the failing tools in [`excludedCommands`](#sandbox-excludedcommands) instead; see [Go-based CLIs fail TLS verification on macOS](/docs/en/sandboxing#go-based-clis-fail-tls-verification-on-macos).

### `sandbox.allowAppleEvents`

Let sandboxed commands on macOS send Apple Events, which `open`, `osascript`, and tools that open URLs in a browser need; without it they fail with error `-600`. This removes code-execution isolation: sandboxed commands can launch other applications unsandboxed with no user prompt, and can send AppleScript commands to running applications such as Terminal, subject to the per-app macOS automation-consent prompt (TCC).

* **Scope**: [`User or managed`](#scopes)
* **Type**: Boolean
  * `true`: sandboxed commands on macOS can send Apple Events
  * `false`: sandboxed commands on macOS can't send Apple Events, so `open` and `osascript` fail with error `-600`
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "allowAppleEvents": true
  }
}
```

To keep isolation and still run one such tool, add it to [`excludedCommands`](#sandbox-excludedcommands) instead. See [Apple Events on macOS](/docs/en/sandboxing#security-limitations).
