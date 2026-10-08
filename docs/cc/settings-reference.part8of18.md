[Part 8/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `sandbox.network.allowLocalBinding`

Let sandboxed commands on macOS listen on network ports, for example to start a dev server, and connect to any port on localhost. A command that listens on a non-loopback address accepts connections from other machines. The key has no effect on Linux and WSL2, where each sandboxed command has its own loopback interface. To reach a server on the host from Linux or WSL2, see [A command fails to reach a server on localhost](/docs/en/sandboxing#a-command-fails-to-reach-a-server-on-localhost).

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: Boolean
  * `true`: sandboxed commands on macOS can listen on any local address and connect to any port on localhost
  * `false`: sandboxed commands on macOS can't listen on a port or connect directly to servers on localhost
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "allowLocalBinding": true
    }
  }
}
```

### `sandbox.network.allowMachLookup`

List additional XPC and Mach service names the macOS sandbox may look up. Tools that communicate over XPC, such as the iOS Simulator or Playwright, need their services listed here.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: array of strings, each a service name; a single trailing `*` matches a prefix, and `"*"` alone matches every service
* **Default**: unset

This allows every service under the `com.apple.coresimulator.` prefix:

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "allowMachLookup": ["com.apple.coresimulator.*"]
    }
  }
}
```

### `sandbox.network.allowedDomains`

Pre-allow domains for outbound traffic from sandboxed commands, so the sandbox doesn't prompt for them. Wildcards such as `*.example.com` match subdomains, and an optional `:port` suffix limits an entry to one port; an entry without a port matches every port.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox). Only managed settings when [`allowManagedDomainsOnly`](#sandbox-network-allowmanageddomainsonly) is set.
* **Type**: array of strings, each a domain, wildcard pattern, or IP literal, with an optional `:port` suffix
* **Default**: unset, so your permission mode decides [what happens to each new host](/docs/en/sandboxing#hosts-outside-your-allowed-domains)

This pre-allows GitHub on every port, every npm subdomain, and one API host on port 443 only:

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org", "api.example.com:443"]
    }
  }
}
```

Write IPv6 literals bracketed, with an optional port: `"[::1]"` allows every port and `"[::1]:443"` one port. The bracketed form requires Claude Code v2.1.229 or later. See [IPv6 addresses in domain lists](/docs/en/sandboxing#ipv6-addresses-in-domain-lists).

### `sandbox.network.deniedDomains`

Block domains for outbound traffic from sandboxed commands, using the same wildcard, port, and IPv6 syntax as [`allowedDomains`](#sandbox-network-alloweddomains). A denied domain stays blocked even when an `allowedDomains` entry matches it too.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of strings, each a domain, wildcard pattern, or IP literal, with an optional `:port` suffix
* **Default**: unset

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "deniedDomains": ["sensitive.cloud.example.com"]
    }
  }
}
```

Claude Code merges this list from every settings source the session loads even when `allowManagedDomainsOnly` is set, so a developer can always tighten the deny list. For IPv6 literals, see [IPv6 addresses in domain lists](/docs/en/sandboxing#ipv6-addresses-in-domain-lists).

An entry written with the trailing dot that marks a fully qualified domain name, such as `example.com.`, blocks the same connections as `example.com`.

### `sandbox.network.strictAllowlist`

Deny sandboxed commands access to hosts outside the allowlist instead of prompting for approval. The allowlist is [`allowedDomains`](#sandbox-network-alloweddomains) plus domains from `WebFetch(domain:...)` allow rules, or only the managed settings entries when [`allowManagedDomainsOnly`](#sandbox-network-allowmanageddomainsonly) is set. [Locks that apply without an admin-required sandbox](/docs/en/sandboxing#locks-that-apply-without-an-admin-required-sandbox) covers a repository's entries. Requires Claude Code v2.1.219 or later.

* **Scope**: [`User or managed`](#scopes). A repository can't turn it on or off.
* **Type**: Boolean
  * `true`: Claude Code denies sandboxed commands access to hosts outside the allowlist
  * `false`: unless another trusted settings file sets `true`, Claude Code decides a host outside the allowlist by permission mode instead of denying it outright: in auto mode it checks the host against the command's [per-command allowed domains](/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode), in `dontAsk` mode it denies, in `bypassPermissions` mode and in interactive terminal plan-mode sessions where bypass is available it allows, and otherwise it asks you
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "strictAllowlist": true
    }
  }
}
```

Claude Code enforces this for sandboxed commands only; in-process tools such as `WebFetch` still follow their [permission rules](/docs/en/sandboxing#permission-rules). When any of the honored sources sets it to `true`, it stays on. See [Network isolation](/docs/en/sandboxing#network-isolation). Requires Claude Code v2.1.219 or later.

### `sandbox.network.allowManagedDomainsOnly`

Lock the network allowlist to what managed settings define. Claude Code then honors only `allowedDomains` and `WebFetch(domain:...)` allow rules from managed settings, ignores domains from user, project, local, and `--settings` settings, and blocks a non-allowed domain automatically instead of prompting.

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code honors only `allowedDomains` and `WebFetch(domain:...)` allow rules from managed settings and blocks a non-allowed domain instead of prompting
  * `false`: domains from other settings files can merge into the allowlist
* **Default**: `false`

This locks the allowlist to GitHub and npm and ignores any domains developers add:

```json managed-settings.json theme={null}
{
  "sandbox": {
    "network": {
      "allowManagedDomainsOnly": true,
      "allowedDomains": ["github.com", "*.npmjs.org"]
    }
  }
}
```

While the key is `true`, the sandbox is [admin-required](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox), and only managed settings can set a [proxy port](#sandbox-network-httpproxyport).

Denied domains still merge from every source the session loads. See [Keep developers from widening the policy](/docs/en/sandboxing#keep-developers-from-widening-the-policy).

### `sandbox.network.httpProxyPort`

Point the sandbox at your own HTTP proxy instead of the one Claude Code runs. Organizations do this to inspect HTTPS traffic, apply their own filtering rules, or log requests. Your proxy takes over filtering, and Claude Code stops applying its domain lists and network prompts to traffic sent there. When unset, Claude Code starts its own proxy for HTTP traffic.

* **Scope**: [`Any file`](#scopes), unless [other sandbox settings limit which files can set a port](/docs/en/sandboxing#custom-proxy-configuration)
* **Type**: number, a local TCP port
* **Default**: unset, so Claude Code runs its own proxy

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "httpProxyPort": 8080
    }
  }
}
```

Set [`socksProxyPort`](#sandbox-network-socksproxyport) too if your proxy should carry SOCKS traffic as well; with only one of the two set, Claude Code still runs its own proxy for the other protocol. See [Custom proxy configuration](/docs/en/sandboxing#custom-proxy-configuration).

### `sandbox.network.socksProxyPort`

Point the sandbox at your own SOCKS5 proxy instead of the one Claude Code runs. Your proxy takes over filtering, and Claude Code stops applying its domain lists and network prompts to traffic sent there. When unset, Claude Code starts its own proxy for SOCKS traffic.

* **Scope**: [`Any file`](#scopes), unless [other sandbox settings limit which files can set a port](/docs/en/sandboxing#custom-proxy-configuration)
* **Type**: number, a local TCP port
* **Default**: unset, so Claude Code runs its own proxy

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "socksProxyPort": 8081
    }
  }
}
```

See [Custom proxy configuration](/docs/en/sandboxing#custom-proxy-configuration).

### `sandbox.network.tlsTerminate`

Make the sandbox proxy terminate TLS so it can read the contents of HTTPS requests. This is experimental, and `mask` [credential substitution](/docs/en/sandboxing#mask-credentials) requires it. Set `{}` to generate an ephemeral certificate authority for the session, or set `caCertPath` and `caKeyPath` to use your own.

* **Scope**: [`User or managed`](#scopes). A repository can't switch it on or supply a certificate authority.
* **Type**: object with optional `caCertPath` and `caKeyPath` strings, each a file path
* **Default**: unset, so the proxy doesn't terminate or inspect TLS

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "tlsTerminate": {}
    }
  }
}
```

When more than one honored source sets it, Claude Code uses the value from the highest-precedence source: managed settings, then the `--settings` flag, then user settings.

<span id="context-and-memory" />

## Memory and context

Control what Claude Code loads into context, how it compacts, and where it keeps memory and plans. See [Manage context](/docs/en/context-window) and [Memory](/docs/en/memory).

### `autoCompactEnabled`

Have Claude Code [compact the conversation automatically](/docs/en/context-window#when-your-context-fills-up) when context approaches the limit. Appears in `/config` as **Auto-compact**, and toggling it there writes this key to your user settings.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code compacts the conversation automatically when context approaches the limit
  * `false`: Claude Code doesn't compact automatically
* **Default**: `true`
* **Per-session overrides**: [`DISABLE_AUTO_COMPACT`](/docs/en/env-vars) turns auto-compact off for one session; whichever of the two turns it off, the other can't turn it back on

```json settings.json theme={null}
{
  "autoCompactEnabled": false
}
```

The manual `/compact` command keeps working while auto-compact is off.

### `autoCompactWindow`

Set how full the context window gets before Claude Code [compacts automatically](/docs/en/context-window#when-your-context-fills-up).

* **Scope**: [`Any file`](#scopes)
* **Type**: number of tokens, from `100000` to `1000000`. Claude Code caps the value at your model's context window; the [models overview](https://platform.claude.com/docs/en/about-claude/models/overview) lists each model's window
* **Default**: unset, so Claude Code picks a window tuned for your model
* **Per-session overrides**: [`--autocompact`](/docs/en/cli-reference#cli-flags) takes precedence over this key for one session, and [`CLAUDE_CODE_AUTO_COMPACT_WINDOW`](/docs/en/env-vars) takes precedence over both

```json settings.json theme={null}
{
  "autoCompactWindow": 500000
}
```

The [`/autocompact`](/docs/en/commands#all-commands) command saves a window for the current model under [`modelSettings`](#modelsettings), which takes precedence over this key in the same file for that model. [Set the auto-compact window](/docs/en/model-config#set-the-auto-compact-window) covers how the command, flag, variable, and setting interact.

### `autoMemoryDirectory`

Store [auto memory](/docs/en/memory#storage-location) in a directory of your choice instead of the per-project default.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, an absolute or `~/`-prefixed directory path
* **Default**: unset, so Claude Code uses `~/.claude/projects/<project>/memory/`

```json settings.json theme={null}
{
  "autoMemoryDirectory": "~/my-memory-dir"
}
```

From project or local settings, Claude Code honors this key under the same [workspace trust rule as hooks](/docs/en/permissions#what-runs-before-you-trust-a-folder), since a cloned repository can supply those files.

### `autoMemoryEnabled`

Turn [auto memory](/docs/en/memory#enable-or-disable-auto-memory) on or off. When `false`, Claude doesn't read from or write to the auto memory directory. You can also toggle it with `/memory` during a session, which writes this key to your user settings.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: the same as unset; auto memory stays on unless something that outranks this key turns it off for the session, such as `--bare`, safe mode, or `CLAUDE_CODE_DISABLE_AUTO_MEMORY`
  * `false`: Claude doesn't read from or write to the auto memory directory
* **Default**: `true`
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_AUTO_MEMORY`](/docs/en/env-vars) takes precedence over this key for one session, in either direction

```json settings.json theme={null}
{
  "autoMemoryEnabled": false
}
```

### `bashOutputMaxChars`

Set how many characters of a successful Bash or PowerShell command's [output Claude receives inline](/docs/en/tools-reference#output-limits). When output passes the limit, Claude Code saves it to a file and Claude receives a short preview plus the file's path. Raise the limit when command output, such as a verbose build or a full test-suite log, routinely overflows the default and you want Claude to read it without opening the file. Requires Claude Code v2.1.261 or later.

* **Scope**: [`Any file`](#scopes)
* **Type**: number of characters, a positive integer. Claude Code clamps the value into the range `4000` to `128000`
* **Default**: unset, so Claude receives up to 30,000 characters inline

```json settings.json theme={null}
{
  "bashOutputMaxChars": 100000
}
```

When you set this key, Claude Code ignores the [`BASH_MAX_OUTPUT_LENGTH`](/docs/en/env-vars) environment variable.

### `claudeMd`

Inject CLAUDE.md-style instructions as organization-managed memory without deploying a separate file. Claude Code loads the text as a managed memory entry ahead of user and project CLAUDE.md files.

* **Scope**: [`Managed`](#scopes)
* **Type**: string, the text of a CLAUDE.md file; write it as you would the file, Markdown included, with line breaks as `\n`
* **Default**: unset

This example deploys two rules as a short Markdown list:

```json managed-settings.json theme={null}
{
  "claudeMd": "# Engineering rules\n\n- Always run make lint before committing.\n- Never push directly to main."
}
```

See [Deploy organization-wide CLAUDE.md](/docs/en/memory#deploy-organization-wide-claude-md).

### `claudeMdExcludes`

Skip specific `CLAUDE.md` files when Claude Code loads [memory](/docs/en/memory#exclude-specific-claude-md-files). In a large monorepo, use it to skip CLAUDE.md files from other teams that aren't relevant to your work; [Exclude irrelevant CLAUDE.md files](/docs/en/large-codebases#exclude-irrelevant-claude-md-files) in the large-codebases guide walks through that case. Patterns match against absolute file paths.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of strings, each a glob pattern or absolute path
* **Default**: unset, so Claude Code loads every CLAUDE.md it finds

```json settings.json theme={null}
{
  "claudeMdExcludes": ["**/vendor/**/CLAUDE.md"]
}
```

Exclusions apply only to user, project, and local memory files; managed policy CLAUDE.md files can't be excluded.

<span id="environment-variables" />

### `env`

Set environment variables for every session and for the subprocesses Claude Code starts from it. Most variables in the [environment variables reference](/docs/en/env-vars) can go here, which is how you apply one to every session or roll it out to your team. Project and local settings can't set [some of them](#variables-claude-code-ignores-in-env).

* **Scope**: [`Any file`](#scopes)
* **Type**: object mapping variable names to string values
* **Default**: unset

This example turns off automatic compaction and routes API requests through a proxy:

```json settings.json theme={null}
{
  "env": {
    "DISABLE_AUTO_COMPACT": "1",
    "ANTHROPIC_BASE_URL": "https://proxy.example.com"
  }
}
```

#### How `env` values interact with your shell

* A value here overwrites the same variable exported in your shell, and when more than one settings file sets a variable, the [highest-precedence](/docs/en/settings#settings-precedence) one applies. [Variables Claude Code ignores in `env`](#variables-claude-code-ignores-in-env) lists the exceptions for project and local settings.
* When the Claude Desktop app or a [self-hosted environment](/docs/en/self-hosted-environments) runner starts the session, the launch environment it builds takes precedence instead: Claude Code ignores an `env` value from any settings file for a variable the launch environment already sets. The [debug log](/docs/en/debug-your-config) names each ignored variable.
* To cancel a shell export, set the variable to `""`. Claude Code treats an empty value as unset for provider selection, and subprocesses inherit the empty value.
* `NO_COLOR` and `FORCE_COLOR` set here reach only subprocesses. To change Claude Code's own interface colors, set them in your shell before launching `claude`.
* Values here are plain text in the settings file and reach every subprocess Claude Code starts. For an OTLP bearer token that rotates, use [`otelHeadersHelper`](#otelheadershelper); for API credentials, use [`apiKeyHelper`](#apikeyhelper).

#### When Claude Code applies `env` values

* From user settings, `--settings`, and managed settings: at startup, and again in the running session when a saved change alters the merged `env`.
* From project and local settings: after you trust the workspace, or at startup in `-p` mode, which never shows the trust dialog, and again when a saved change alters the merged `env`.
* Variables Claude Code classifies as safe, such as model selection, timeouts and limits, and feature toggles: at startup from every settings file, apart from the [variables project and local settings can't set](#variables-claude-code-ignores-in-env).
* After you [move the session with `/cd`](/docs/en/permissions#move-the-session-to-another-directory) on v2.1.246 or later: the new directory's project and local `env` values, on top of the previous directory's.

#### Variables Claude Code ignores in `env`

* Project and local settings can't set variables that a checked-out repository shouldn't control; set those in your shell, user settings, or managed settings instead. Claude Code drops each one, apart from a few values that turn telemetry off, and logs a warning you can see with `claude --debug`. They include:

  * Variables that choose where Claude Code stores or writes its own files: `CLAUDE_CONFIG_DIR`, `CLAUDE_CODE_TMPDIR`, and the operating-system directory variables such as `HOME`, `TMPDIR`, `TMP`, `TEMP`, and the `XDG_*` family.
  * Windows variables that pick the programs and machine-wide configuration for the processes Claude Code starts, such as `SystemRoot`, `ComSpec`, `ProgramData`, `LOCALAPPDATA`, `PATHEXT`, `PSModulePath`, and the `ProgramFiles` family.
  * Variables that export session content: [`OTEL_LOG_RAW_API_BODIES`](/docs/en/env-vars#variables) and the detailed beta tracing pair `ENABLE_BETA_TRACING_DETAILED` and `BETA_TRACING_ENDPOINT`.
  * The [OpenTelemetry exporter](/docs/en/monitoring-usage) variables that turn telemetry on, choose where it goes, or choose what content it captures:

    * `CLAUDE_CODE_ENABLE_TELEMETRY`, plus the enhanced telemetry beta pair `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA` and `ENABLE_ENHANCED_TELEMETRY_BETA`
    * The exporter selectors `OTEL_LOGS_EXPORTER`, `OTEL_METRICS_EXPORTER`, and `OTEL_TRACES_EXPORTER`
    * The content variables `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_ASSISTANT_RESPONSES`, `OTEL_LOG_TOOL_CONTENT`, and `OTEL_LOG_TOOL_DETAILS`
    * `OTEL_EXPORTER_OTLP_*` variables whose names end in `_ENDPOINT`, `_HEADERS`, `_PROTOCOL`, `_CERTIFICATE`, `_CLIENT_KEY`, or `_INSECURE`, in the generic and per-signal forms, such as `OTEL_EXPORTER_OTLP_ENDPOINT` and `OTEL_EXPORTER_OTLP_METRICS_HEADERS`
    * `OTEL_EXPORTER_PROMETHEUS_HOST` and `OTEL_EXPORTER_PROMETHEUS_PORT`

    Only these values still apply from project and local settings, because they turn something off: `none` for the three exporter selectors, and an off value such as `0` for `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_CONTENT`, and `OTEL_LOG_TOOL_DETAILS`. Such a value overrides the same variable in your user settings, but not one that the environment you start Claude Code from, a `--settings` file, or managed settings sets.

    When a project or local settings file sets a variable in this group, a local interactive session shows a notice at startup. Run `/status` or `claude doctor` to see which ones Claude Code ignored and which turned telemetry off; both list names, never values. A non-interactive run with `-p` or an Agent SDK session shows no notice, so check that your collector still receives data after you upgrade. If it doesn't, set the variables in your user settings, managed settings, the job's environment, or a file you pass with `--settings`.

    Ignoring this group in project and local settings requires Claude Code v2.1.282 or later.
  * Variables that change how Claude Code starts or syncs, such as `CLAUDE_CODE_PROCESS_WRAPPER`, `CLAUDE_CODE_SYNC_SKILLS`, `CLAUDE_CODE_SYNC_PLUGINS`, `CLAUDE_CODE_PLUGIN_CACHE_DIR`, and `CLAUDE_CODE_PLUGIN_SEED_DIR`.

  Before v2.1.251, project and local settings could also set the variables in this list that choose where Claude Code writes its files or that export session content, except `HOME` and `XDG_CONFIG_HOME`.
* Identity variables that Claude Code's hosting environments own, such as `CLAUDE_CODE_REMOTE` and `CLAUDE_CODE_ACCOUNT_UUID`, are ignored from every file.
* [`CLAUDE_CODE_MESSAGING_SOCKET` and `CLAUDE_CODE_MESSAGING_TOKEN`](/docs/en/env-vars#variables), which Claude Code exports itself, are ignored from every file. Ignoring the socket variable requires Claude Code v2.1.224 or later, and ignoring the token requires v2.1.228 or later.
* [`CLAUDE_CODE_PROJECT_DIR_NAME`](/docs/en/sessions#name-the-project-directory-yourself), which Claude Code reads from the launch environment only, is ignored from every file; requires v2.1.234 or later.
* [`CLAUDE_CODE_RESTRICTED`](/docs/en/env-vars#variables), which Claude Code reads from the launch environment only, is ignored from every file.
* [`CLAUDE_CODE_DISABLE_POWERSHELL_CMD_RM_DENY`](/docs/en/env-vars#variables), which Claude Code reads from the launch environment only, is ignored from every file. The variable requires Claude Code v2.1.283 or later.
* [`CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT`, `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT`, and `CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT`](/docs/en/env-vars#variables), which Claude Code reads from the launch environment only, are ignored from every file.
