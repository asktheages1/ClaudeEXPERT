[Part 13/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `strictPluginOnlyCustomization`

Block skills, agents, hooks, and MCP servers from user and project sources, so they can come only from plugins or managed settings. Combine it with [`strictKnownMarketplaces`](#strictknownmarketplaces) to control the full customization supply chain: the marketplace allowlist controls which plugins users can install.

* **Scope**: [`Managed`](#scopes)
* **Type**: `true` to lock all four kinds of customization, or an array naming the kinds to lock, from `"skills"`, `"agents"`, `"hooks"`, and `"mcp"`
* **Default**: unset, so nothing is locked

This example locks skills and hooks and leaves agents and MCP servers unlocked:

```json managed-settings.json theme={null}
{
  "strictPluginOnlyCustomization": ["skills", "hooks"]
}
```

The four sub-key entries below list what each surface blocks and what still loads. Claude Code ignores surface names it doesn't recognize rather than failing the settings file, so you can add new surface names before every client has updated.

### `strictPluginOnlyCustomization.skills`

Lock the `skills` surface. Claude Code stops loading skills from `~/.claude/skills/` and `.claude/skills/`, custom commands from `~/.claude/commands/` and `.claude/commands/`, skills and commands under `--add-dir` directories, and skills synced from your claude.ai account. It keeps loading plugin skills, bundled skills, and skills in the managed policy directory.

* **Scope**: [`Managed`](#scopes)
* **Type**: the string `"skills"` in the [`strictPluginOnlyCustomization`](#strictpluginonlycustomization) array
* **Default**: not locked

```json managed-settings.json theme={null}
{
  "strictPluginOnlyCustomization": ["skills"]
}
```

### `strictPluginOnlyCustomization.agents`

Lock the `agents` surface. Claude Code stops loading agents from `~/.claude/agents/`, `.claude/agents/`, and `--add-dir` directories. It keeps loading plugin agents, built-in agents, and agents in the managed policy directory.

* **Scope**: [`Managed`](#scopes)
* **Type**: the string `"agents"` in the [`strictPluginOnlyCustomization`](#strictpluginonlycustomization) array
* **Default**: not locked

```json managed-settings.json theme={null}
{
  "strictPluginOnlyCustomization": ["agents"]
}
```

### `strictPluginOnlyCustomization.hooks`

Lock the `hooks` surface. Claude Code stops running hooks from user, project, and local `settings.json`, and keeps running plugin hooks and hooks in managed settings.

* **Scope**: [`Managed`](#scopes)
* **Type**: the string `"hooks"` in the [`strictPluginOnlyCustomization`](#strictpluginonlycustomization) array
* **Default**: not locked

```json managed-settings.json theme={null}
{
  "strictPluginOnlyCustomization": ["hooks"]
}
```

### `strictPluginOnlyCustomization.mcp`

Lock the `mcp` surface. Claude Code stops loading MCP servers from `~/.claude.json` and `.mcp.json`, and keeps loading plugin MCP servers, [`managed-mcp.json`](/docs/en/managed-mcp) servers, and servers from [`managedMcpServers`](#managedmcpservers).

* **Scope**: [`Managed`](#scopes)
* **Type**: the string `"mcp"` in the [`strictPluginOnlyCustomization`](#strictpluginonlycustomization) array
* **Default**: not locked

```json managed-settings.json theme={null}
{
  "strictPluginOnlyCustomization": ["mcp"]
}
```

### `enabledPlugins`

Turn individual [plugins](/docs/en/plugins/overview) on or off, keyed by `plugin-name@marketplace-name`. A plugin with no entry at any scope falls back to its [`defaultEnabled`](/docs/en/plugins/manifest-reference#fields) value. When you enable or disable a plugin with `/plugin` or `claude plugin enable`, Claude Code writes this key for you.

* **Scope**: [`Any file`](#scopes)
* **Type**: object mapping `plugin-name@marketplace-name` to a Boolean
* **Default**: unset, so each plugin follows its `defaultEnabled` value

This example enables two plugins from the `team-tools` marketplace and disables one from `personal`:

```json settings.json theme={null}
{
  "enabledPlugins": {
    "code-formatter@team-tools": true,
    "deployment-tools@team-tools": true,
    "experimental-features@personal": false
  }
}
```

Each scope serves a different purpose:

* **User settings**: your personal plugin preferences
* **Project settings**: plugins shared with everyone in the repository
* **Local settings**: per-machine overrides, gitignored when Claude Code saves a setting there
* **Managed settings**: organization-wide policy. A plugin set to `false` here is blocked from installation at every scope and hidden from the marketplace

Project settings take precedence over user settings, so setting a plugin to `false` in `~/.claude/settings.json` doesn't disable a plugin that the project's `.claude/settings.json` enables. To opt out of a project-enabled plugin on your machine, set it to `false` in `.claude/settings.local.json` instead. Plugins force-enabled by managed settings can't be disabled this way, since managed settings override local settings.

Enabling a plugin from an external source such as a GitHub repository or npm package in a project's `.claude/settings.json` doesn't install it for other people. On every path that loads plugins, Claude Code reports the plugin as not installed until each user [installs it themselves](/docs/en/plugins/org#require-plugins-per-repository).

### `extraKnownMarketplaces`

Register additional plugin marketplaces by name, so that people who open the repository, or everyone your managed settings reach, get the marketplace without adding it themselves. Claude Code registers each marketplace it doesn't already know. Whether a plugin that [`enabledPlugins`](#enabledplugins) names from it installs depends on the plugin's source and which file enables it; that entry has the rules.

* **Scope**: [`Any file`](#scopes). Claude Code honors entries in a repository's `.claude/settings.json` or `.claude/settings.local.json` only after you accept the workspace trust dialog for that folder; in a folder you haven't trusted, including a `-p` run there, it ignores them without a message.
* **Type**: object mapping a marketplace name to an object with a `source` object and an optional `autoUpdate` Boolean
* **Default**: unset

This example registers a GitHub marketplace and a marketplace from a self-hosted git URL:

```json settings.json theme={null}
{
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": {
        "source": "github",
        "repo": "acme-corp/claude-plugins"
      }
    },
    "security-plugins": {
      "source": {
        "source": "git",
        "url": "https://git.example.com/security/plugins.git"
      }
    }
  }
}
```

[What runs before you trust a folder](/docs/en/permissions#what-runs-before-you-trust-a-folder) compares the trust gate with the other content a repository can supply. You can also write this key as `additionalMarketplaces`; see [Marketplace key aliases](#marketplace-key-aliases).

Set `"autoUpdate": true` alongside `source` to make Claude Code refresh that marketplace and update its installed plugins in the background after startup. When omitted, `claude-plugins-official` and most other official Anthropic marketplaces default to `true`, and third-party marketplaces default to `false`. See [Configure auto-updates](/docs/en/plugins/install#keep-plugins-updated).

When more than one settings file defines a marketplace entry under the same name, Claude Code uses the entry from the [highest-precedence file](/docs/en/settings#settings-precedence) whole. That entry replaces the lower-precedence entry and inherits none of its fields, so a redefinition can't combine one file's `source.headers` credential with a URL another file controls. Before v2.1.228, Claude Code merged same-name entries field by field, so an entry in a higher-precedence file could inherit fields it didn't set, including another file's `headers`.

#### Marketplace source types

The `source` object takes one of these forms:

* **`github`**: a GitHub repository, with `repo`
* **`git`**: any git URL, with `url`
* **`url`**: a direct URL to a `marketplace.json` file, with `url` and optional `headers` and `headersHelper` for authenticated access. `headersHelper` names a command that prints headers whose values are too short-lived to list in `headers`, and requires Claude Code v2.1.238 or later
* **`file`**: a local path to a `marketplace.json` file, with `path`
* **`directory`**: a local filesystem path, with `path`. Use it for development, or for a marketplace your organization [deploys to each machine](/docs/en/plugins/mods/admin#install-your-organizations-mods).
* **`settings`**: an inline marketplace declared directly in the settings file without a hosted repository, with `name` and `plugins`

The `git` source type works with any git hosting service, including self-hosted GitLab and Bitbucket. Claude Code clones the repository with the same authentication that `git clone` would use on that machine: configured credential helpers or SSH keys. A provider token such as `GITHUB_TOKEN` takes effect through a credential helper that reads it. See [Private repositories](/docs/en/plugins/host-marketplace#grant-access-to-a-private-marketplace) for setup details.

For `github` and `git` sources, Claude Code never downloads [Git LFS](https://git-lfs.com) content when it clones the marketplace repository to add or update it. LFS-tracked files are checked out as pointer files, and the add or update output reports how many.

The `skipLfs` field inside the `source` object is accepted and has no effect. Before v2.1.274, Claude Code downloaded LFS content unless you set `"skipLfs": true`.

For a `url` source, set `headersHelper` inside the `source` object when the credential in `headers` expires and a command has to produce a fresh one. Requires Claude Code v2.1.238 or later. For what the command must print and where Claude Code runs it, see [Write the headersHelper command](/docs/en/plugins/host-marketplace#write-the-headershelper-command), and for the cases where Claude Code doesn't run it, see [When Claude Code skips a headersHelper command](/docs/en/plugins/host-marketplace#when-claude-code-skips-a-headershelper-command-or-drops-its-output). Once you set `headersHelper` on an `https://` marketplace URL, Claude Code runs the command at two points, reusing one run's output for up to 60 seconds:

* Before each fetch of that marketplace's `marketplace.json`, including a later refresh. Claude Code sends the printed headers with that fetch.
* Before each plugin archive download on the marketplace URL's origin, meaning the same scheme, host, and port. Claude Code sends the output with that download, and no other download gets the headers.

Claude Code ignores any `headersHelper` set in the `.claude/settings.json` or `.claude/settings.local.json` of a directory you add with [`--add-dir`](/docs/en/permissions#what-runs-before-you-trust-a-folder), on a `url` source and on an inline plugin entry alike, and sends only the fixed `headers` set in that file. [How users accept a headersHelper command](/docs/en/plugins/host-marketplace#how-users-accept-a-headershelper-command) covers the other settings files.

Plugins listed in a `settings` source must reference external sources such as GitHub or npm, and the `name` must match the marketplace key. You still enable each plugin separately in `enabledPlugins`. This example declares one plugin inline:

```json settings.json theme={null}
{
  "extraKnownMarketplaces": {
    "team-tools": {
      "source": {
        "source": "settings",
        "name": "team-tools",
        "plugins": [
          {
            "name": "code-formatter",
            "source": {
              "source": "github",
              "repo": "acme-corp/code-formatter"
            }
          }
        ]
      }
    }
  }
}
```

A plugin entry under `source: 'settings'` whose own `source` is an [`archive`](/docs/en/plugins/marketplace-reference#archive-plugin-source) can set `headers` for the archive download. If the value you would put in `headers` is short-lived, such as a token your registry mints on request, set a `headersHelper` command instead. An entry may set both. Both fields require Claude Code v2.1.238 or later.

Claude Code sends the entry's `headers`, and whatever the command prints, with that plugin's archive download and with no other download. Claude Code runs the command only when a user [installs or updates that one plugin by itself](/docs/en/plugins/host-marketplace#how-users-accept-a-headershelper-command). Three further rules depend on which file holds the entry:

* **`strict`**: unlike an entry in a marketplace's `marketplace.json`, an entry in settings doesn't need `"strict": false`, because a settings file carries no manifest fields to inline. See [Strict mode](/docs/en/plugins/marketplace-reference#strict-mode).
* **Folder trust**: for an entry in a project's `.claude/settings.json` or `.claude/settings.local.json`, Claude Code runs the command only after the user has also [trusted that folder](/docs/en/permissions#what-runs-before-you-trust-a-folder).
* **Header filter**: Claude Code drops [request-routing and client-identity header names](/docs/en/plugins/host-marketplace#when-claude-code-skips-a-headershelper-command-or-drops-its-output) from an entry in a project's `.claude/settings.json` or `.claude/settings.local.json`, because a repository can supply those files. Claude Code applies the same filter to a catalog entry and to an entry in an `--add-dir` directory's settings, and no filter to an entry in your user settings, a `--settings` file, or managed settings.

#### Marketplace key aliases

On Claude Code v2.1.232 or later, you can write `extraKnownMarketplaces` as `additionalMarketplaces` and `strictKnownMarketplaces` as `allowedMarketplaces`. Claude Code treats each alias as follows:

* Earlier versions ignore the alias, so keep the canonical spelling in a file that older versions also read, such as a managed settings file for a fleet with mixed Claude Code versions.
* In any settings file that accepts the canonical key, Claude Code reads the alias exactly as it reads the canonical key.
* Claude Code may rewrite `additionalMarketplaces` to `extraKnownMarketplaces` when it updates the file.
* If you set both spellings in one file, Claude Code uses the canonical value and ignores the alias.

### `pluginConfigs`

Store the non-sensitive answers you give a plugin's [`userConfig`](/docs/en/plugins/manifest-reference#user-configuration) configuration dialog, keyed by plugin ID. Claude Code writes this key to your user settings when you fill in the dialog, so you don't need to edit it by hand. Claude Code stores sensitive options in the macOS Keychain instead, falling back to `~/.claude/.credentials.json` when the Keychain rejects the write; on platforms without a supported keychain, it stores them in `~/.claude/.credentials.json`.

* **Scope**: [`User or managed`](#scopes)
* **Type**: object mapping a plugin ID to an object with an `options` field, mapping each option name to a string, number, Boolean, or array of strings, and an optional `mcpServers` field holding per-server user configuration values in the same shape
* **Default**: unset

This example stores the `api_endpoint` option for the `deployer` plugin from `acme-tools`:

```json settings.json theme={null}
{
  "pluginConfigs": {
    "deployer@acme-tools": {
      "options": {
        "api_endpoint": "https://api.example.com"
      }
    }
  }
}
```

Built-in plugins store their options under the same key with an `@builtin` suffix. For example, the [**Project instructions**](/docs/en/memory#choose-which-instruction-files-load) setting that controls whether Claude Code reads `AGENTS.md` files is `pluginConfigs["cc-plugin-agents-md@builtin"].options.instructionFiles`. Before v2.1.285, the plugin's ID was `agents-md@builtin`. Later versions read an entry under either ID.

Claude Code ignores project and local entries because it substitutes these values into plugin hook, MCP, and LSP configurations, and a cloned repository must not be able to supply them. Before v2.1.207, project and local settings were also read.

### `prependPlugins`

List the managed plugins whose [mods](/docs/en/plugins/mods/overview) run before every mod a user installs, in the listed order. When you set this key in managed settings, name `sec-default@builtin` in the list to keep the built-in guard. In managed settings, Claude Code skips an id whose plugin doesn't count as your organization's. See [Install your organization's mods and set the order](/docs/en/plugins/mods/admin#install-your-organizations-mods) for those conditions and for how the two ordering keys work together.

* **Scope**: [`User or managed`](#scopes). Claude Code reads the key from managed settings. It reads the key from user settings only on a machine with no managed settings, for a user who isn't signed in with a Team or Enterprise plan. It ignores the key in project and local settings and in a `--settings` file.
* **Type**: array of `plugin-name@marketplace-name` strings
* **Default**: unset

```json managed-settings.json theme={null}
{
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": { "source": "directory", "path": "/opt/acme/claude-plugins" }
    }
  },
  "enabledPlugins": { "acme-guard@acme-tools": true },
  "prependPlugins": ["acme-guard@acme-tools", "sec-default@builtin"]
}
```

### `appendPlugins`

List the managed plugins whose [mods](/docs/en/plugins/mods/overview) run after every mod a user installs, in the listed order. An id listed in both `prependPlugins` and `appendPlugins` is prepended. In managed settings, Claude Code skips an id whose plugin doesn't [count as your organization's](/docs/en/plugins/mods/admin#install-your-organizations-mods).

* **Scope**: [`User or managed`](#scopes). Claude Code reads the key from managed settings. It reads the key from user settings only on a machine with no managed settings, for a user who isn't signed in with a Team or Enterprise plan. It ignores the key in project and local settings and in a `--settings` file.
* **Type**: array of `plugin-name@marketplace-name` strings
* **Default**: unset

```json managed-settings.json theme={null}
{
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": { "source": "directory", "path": "/opt/acme/claude-plugins" }
    }
  },
  "enabledPlugins": { "acme-audit@acme-tools": true },
  "appendPlugins": ["acme-audit@acme-tools"]
}
```

## MCP

Control which MCP servers Claude Code connects to and which an organization allows. See [Connect to external tools with MCP](/docs/en/mcp) and [Managed MCP configuration](/docs/en/managed-mcp).

### `allowAllClaudeAiMcps`

Load the [claude.ai connectors](/docs/en/mcp#use-mcp-servers-from-claude-ai) Claude Code fetches itself alongside a deployed `managed-mcp.json`. Without this key, `managed-mcp.json` takes exclusive control of MCP servers and suppresses those connectors.

* **Scope**: [`Managed`](#scopes). Users can't re-enable connectors that exclusive control suppressed.
* **Type**: Boolean
  * `true`: Claude Code loads the claude.ai connectors alongside a deployed `managed-mcp.json`
  * `false`: a deployed `managed-mcp.json` takes exclusive control of MCP servers and suppresses the claude.ai connectors [Claude Code fetches itself](/docs/en/mcp#how-connectors-reach-claude-code)
* **Default**: `false`, so a deployed `managed-mcp.json` suppresses the claude.ai connectors Claude Code fetches itself

```json managed-settings.json theme={null}
{
  "allowAllClaudeAiMcps": true
}
```

[`allowedMcpServers`](#allowedmcpservers) and [`deniedMcpServers`](#deniedmcpservers) still apply to the connectors this key loads. Connectors delivered to a [cloud session](/docs/en/claude-code-on-the-web) whose host carries a `managed-mcp.json`, such as a self-hosted runner, stay suppressed. See [Allow claude.ai connectors alongside the managed set](/docs/en/managed-mcp#allow-claude-ai-connectors-alongside-the-managed-set).

### `allowClaudeInChromeWithManagedMcp`

Let the built-in [Claude in Chrome](/docs/en/chrome) server run alongside a deployed `managed-mcp.json`. Without this key, a deployed `managed-mcp.json` blocks Claude in Chrome in terminal sessions. Requires Claude Code v2.1.282 or later.

* **Scope**: [`Managed`](#scopes), from the device's own managed settings only: an MDM-deployed plist or HKLM registry key, or a system `managed-settings.json` file. Claude Code ignores it in server-managed settings, in the user-writable HKCU registry, and in user or project settings.
* **Type**: Boolean
  * `true`: the built-in Claude in Chrome server can run alongside a deployed `managed-mcp.json`
  * `false`: a deployed `managed-mcp.json` blocks Claude in Chrome in terminal sessions
* **Default**: `false`, so a deployed `managed-mcp.json` blocks Claude in Chrome in terminal sessions

```json managed-settings.json theme={null}
{
  "allowClaudeInChromeWithManagedMcp": true
}
```

A [`deniedMcpServers`](#deniedmcpservers) entry for `claude-in-chrome` still blocks the server with this key on. See [Allow Claude in Chrome alongside the managed set](/docs/en/managed-mcp#allow-claude-in-chrome-alongside-the-managed-set).

### `allowedMcpServers`

Allowlist the MCP servers people can add. Claude Code blocks any server that doesn't match an entry wherever it's defined, including plugin servers, servers a user passes with `--mcp-config`, and servers from claude.ai.

Built-in servers such as Claude in Chrome, the `ide` server Claude Code connects to in a running [VS Code](/docs/en/vs-code#the-built-in-ide-mcp-server) or [JetBrains](/docs/en/jetbrains#the-built-in-ide-mcp-server) IDE, and servers the CLI itself configures are exempt from the allowlist, and the denylist still applies to them. On Claude Code v2.1.268 or later, a [Claude Tag](/docs/en/claude-tag) session's Slack tools are also exempt from the allowlist, and the denylist still applies to them. In-process `type: "sdk"` servers are exempt from both lists; the [app that started the session](/docs/en/mcp#how-connectors-reach-claude-code) registers them.

Servers your organization delivers are also exempt from the allowlist, and the denylist still applies to them. The exemption covers every [`managedMcpServers`](#managedmcpservers) entry, and any [`managed-mcp.json`](/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) entry whose values use no `${VAR}` expansion. See [How a server is evaluated](/docs/en/managed-mcp#how-a-server-is-evaluated) for the full check order. Before v2.1.259, servers from `managed-mcp.json` had to match too.

* **Scope**: [`Any file`](#scopes). Entries from every file merge into one allowlist unless [`allowManagedMcpServersOnly`](#allowmanagedmcpserversonly) is set. Deploy it in managed settings to enforce it.
* **Type**: array of objects, each with exactly one key: `serverName`, a string limited to letters, numbers, hyphens, and underscores; `serverCommand`, an array of the command and its arguments matched exactly; or `serverUrl`, a URL pattern with `*` wildcards
* **Default**: unset, so every server is allowed; an empty array blocks every server users add

This example allows only the stdio server that the listed `npx` command starts:

```json settings.json theme={null}
{
  "allowedMcpServers": [
    { "serverCommand": ["npx", "-y", "@modelcontextprotocol/server-filesystem"] }
  ]
}
```

A [`deniedMcpServers`](#deniedmcpservers) entry takes precedence, so a server on both lists is blocked. Once the list contains any `serverCommand` entry, a stdio server must match a `serverCommand` entry, and once it contains any `serverUrl` entry, a remote server must match a `serverUrl` entry: a `serverName` match no longer admits that kind of server. See [Policy-based control with allowlists and denylists](/docs/en/managed-mcp#policy-based-control-with-allowlists-and-denylists).
