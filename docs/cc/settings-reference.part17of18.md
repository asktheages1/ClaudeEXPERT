[Part 17/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `forceRemoteSettingsRefresh`

Block CLI startup until Claude Code has freshly fetched [server-managed settings](/docs/en/server-managed-settings). If the fetch fails, Claude Code exits instead of continuing with cached or no settings. Set it when your environment can't accept even a brief window in which a session runs without its managed policy.

When the key is unset, Claude Code doesn't block startup on the fetch, though when the developer signs in at startup it waits up to five seconds for the fetch. A Cloud gateway session always waits, and exits if the gateway can't be reached.

* **Scope**: [`Managed`](#scopes). Claude Code honors a `true` from any admin-controlled managed source, even one that isn't the highest-priority source.
* **Type**: Boolean
  * `true`: Claude Code blocks startup until it has freshly fetched server-managed settings, and exits if the fetch fails
  * `false`: Claude Code doesn't block startup on the fetch, though at a sign-in startup it waits up to five seconds for the fetch
* **Default**: `false`

```json managed-settings.json theme={null}
{
  "forceRemoteSettingsRefresh": true
}
```

Set it in an MDM profile or the managed settings file to enforce fail-closed startup before the first server payload arrives. Claude Code applies the check only in sessions that fetch server-managed settings, so a session that [doesn't fetch them](/docs/en/server-managed-settings#platform-availability) starts without waiting. The `claude auth` subcommands are exempt, so users can re-authenticate when expired credentials are why the fetch fails. See [Enforce fail-closed startup](/docs/en/server-managed-settings#enforce-fail-closed-startup).

### `managedSourcesBehavior`

Choose whether Claude Code applies only the highest-priority [managed source](/docs/en/managed-settings#how-claude-code-combines-managed-sources) your organization delivers, or combines every admin source it delivers. By default Claude Code takes the highest-priority source that carries a [policy key](/docs/en/managed-settings#how-claude-code-combines-managed-sources) and ignores the rest. A policy key is any settings key other than this one and `wslInheritsWindowsSettings`. Under that default, once server-managed settings or an MDM policy deliver a policy key, a `managed-settings.json` file contributes only the [keys Claude Code reads from every admin source](/docs/en/managed-settings#keys-read-from-every-admin-source). With `"merge"`, every admin source you deliver contributes its keys to one combined policy. Requires Claude Code v2.1.242 or later.

Set `"merge"` only where every source [ranked](/docs/en/managed-settings#how-claude-code-combines-managed-sources) below your highest one is under an administrator's control, because Claude Code then adds entries from a lower source, such as `permissions.allow` rules, to the policy.

* **Scope**: [`Managed`](#scopes). Claude Code reads this key from the highest-priority source that carries either this key or a policy key, and ignores this key in every source ranked lower, so a lower source can't opt itself into combining with the source above it. Neither the Windows HKCU registry nor [parent settings from an embedding host](/docs/en/managed-settings#let-an-embedding-host-add-policy) take part in the merge.
* **Type**: string, one of:
  * `"first-wins"`: the highest-priority source that carries a policy key supplies the policy, and lower sources contribute only the [keys Claude Code reads from every admin source](/docs/en/managed-settings#keys-read-from-every-admin-source)
  * `"merge"`: every admin source you deliver contributes its keys, combined by the rules below
* **Default**: `"first-wins"`

Deliver the key in the highest-priority source you deploy. A machine that never receives server-managed settings needs the key in its MDM profile too, because Claude Code reads the key from the highest-priority source that carries it or a policy key. A `managed-settings.json` file is the lowest-ranked admin source, so `"merge"` set there has no source below it to combine with. In server-managed settings, the key looks like this:

```json theme={null}
{
  "managedSourcesBehavior": "merge"
}
```

Under `"merge"`, Claude Code combines each key by its kind. This table gives the rule for each kind. The restriction allowlist, values-taken-whole, and highest-source-only rows name every key they cover, and the other rows give examples:

| Kind of key | How Claude Code combines it | Keys |
| :- | :- | :- |
| Lists | Combines entries from every source | [`permissions.allow`](#permissions-allow), [`sandbox.network.allowedDomains`](#sandbox-network-alloweddomains), and other list keys |
| Locks | Applies the strictest value any source sets. When no source sets a strict value, applies a looser value only from the highest source | [`allowManagedPermissionRulesOnly`](#allowmanagedpermissionrulesonly), [`permissions.disableBypassPermissionsMode`](#permissions-disablebypasspermissionsmode), and other boolean or enum locks |
| Restriction allowlists | Takes the list whole from the highest source that sets it, without adding entries from lower sources. When the highest source doesn't set one, takes it whole from the next source down | [`availableModels`](#availablemodels), [`allowedMcpServers`](#allowedmcpservers), [`allowedProviders`](#allowedproviders), [`strictKnownMarketplaces`](#strictknownmarketplaces), [`allowedChannelPlugins`](#allowedchannelplugins), and the [`fallbackModel`](#fallbackmodel) chain |
| Values taken whole | Takes the value whole from the highest source that sets it, without combining entries or fields from lower sources. When the highest source doesn't set it, takes it whole from the next source down | [`sandbox.credentials.awsPairs`](#sandbox-credentials-awspairs), [`sandbox.ripgrep`](#sandbox-ripgrep) |
| Provided MCP servers | Combines the server names from every source. When two sources set the same name, applies the higher source's whole entry | [`managedMcpServers`](#managedmcpservers) |
| Read from the highest-priority source only | Reads the key only from the highest-priority source that carries a policy key, so a lower source's value is ignored even when the highest source sets none | [`apiKeyHelper`](#apikeyhelper), [`awsAuthRefresh`](#awsauthrefresh), [`awsCredentialExport`](#awscredentialexport), [`gcpAuthRefresh`](#gcpauthrefresh), [`otelHeadersHelper`](#otelheadershelper), `proxyAuthHelper`, [`forceLoginOrgUUID`](#forceloginorguuid), the `"claudeai"` and `"console"` values of [`forceLoginMethod`](#forceloginmethod), [`parentSettingsBehavior`](#parentsettingsbehavior), [`modelPicker`](#modelpicker), [`policyHelper`](#policyhelper), [`permissions.defaultMode`](#permissions-defaultmode) |
| `env` | [Merges per variable across admin sources](/docs/en/managed-settings#keys-read-from-every-admin-source), under both `"first-wins"` and `"merge"` | [`env`](#env) |
| Every other key | Takes the value from the highest source that sets it | [`cleanupPeriodDays`](#cleanupperioddays), [`model`](#model) |

Taking `sandbox.credentials.awsPairs` and `sandbox.ripgrep` whole requires Claude Code v2.1.257 or later.

A few keys add a condition that the table doesn't show:

* **[`policyHelper`](#policyhelper)**: Claude Code honors it only when the highest source that carries a policy key is an MDM policy or a managed settings file, so under server-managed settings it doesn't apply.
* **[`modelOverrides`](#modeloverrides)**: pairs with `availableModels`. Claude Code takes `modelOverrides` from the highest source that sets it, unless a higher source sets `availableModels` without `modelOverrides`. In that case it ignores `modelOverrides` from every source.
* **[`forceLoginGatewayUrl`](#forcelogingatewayurl), [`gatewayInternalNetworks`](#gatewayinternalnetworks), and the `"gateway"` value of [`forceLoginMethod`](#forceloginmethod)**: Claude Code never reads any of them from server-managed settings, so a value there neither applies nor hides one set in an MDM policy or managed settings file. Among the admin sources on the machine, only the highest-ranked one that carries a policy key supplies them, whether or not server-managed settings are also present.
* **[`allowedProviders`](#allowedproviders)**: after the table's rule, the machine's own list still limits the result, as its entry's Scope note states.

To confirm which sources combined on a machine, run `/status` and [read the `Setting sources` line](/docs/en/managed-settings#read-the-source-in-/status).

### `parentSettingsBehavior`

Choose whether Claude Code applies managed settings supplied by an embedding host process, such as the Agent SDK or an IDE extension, when an admin-deployed managed tier is also present. With `"first-wins"`, Claude Code drops the host-supplied settings; with `"merge"`, it applies them under the admin tier through a restrictive-only filter. Set `"merge"` when a host needs to pass its own restrictions to the sessions it launches, for example Claude Desktop delivering a gateway's egress allowlist.

* **Scope**: [`Managed`](#scopes). Claude Code reads it from the highest-priority admin-controlled managed source.
* **Type**: string, one of:
  * `"first-wins"`: Claude Code drops the host-supplied settings when an admin-deployed managed tier is present
  * `"merge"`: Claude Code applies the host-supplied settings under the admin tier through a restrictive-only filter
* **Default**: `"first-wins"`

```json managed-settings.json theme={null}
{
  "parentSettingsBehavior": "merge"
}
```

This key has no effect when no admin-deployed managed tier exists: the host's settings then apply as the only managed tier, still filtered to restrictive values. For the filter's limits and how the managed sources interact, see [Parent settings from embedding hosts](/docs/en/managed-settings#parent-settings-from-embedding-hosts) and [Restrict parent settings](/docs/en/claude-apps-gateway#restrict-parent-settings).

<span id="compute-managed-settings-with-a-policy-helper" />

### `policyHelper`

Run an executable you deploy that computes managed settings at startup, so you can derive policy from device posture, identity, or a remote service instead of a static file. Claude Code runs the helper before it accepts the first prompt and treats the settings it emits as the managed settings for the session.

* **Scope**: [`Managed`](#scopes). Read from the macOS plist, the Windows HKLM registry, or the managed settings file. Claude Code reads the key from the highest-priority managed source that carries a [policy key](/docs/en/managed-settings#how-claude-code-combines-managed-sources) and runs the helper only when that source is one of those three; it ignores the key in server-managed settings, the HKCU registry, and host-supplied parent settings.
* **Type**: object with `path`, `timeoutMs`, and `refreshIntervalMs`
* **Default**: unset, so no helper runs

When server-managed settings deliver the policy at launch, they take precedence over the helper's source and the helper doesn't run.

If a later settings fetch reports the server-managed settings removed, Claude Code runs the helper at that point rather than waiting for the next launch. Its output governs the rest of the session, and a run that fails ends the session with the same message as a [failed startup run](#helper-failures).

This example runs the helper with a 5-second timeout and re-runs it every five minutes:

```json managed-settings.json theme={null}
{
  "policyHelper": {
    "path": "/usr/local/bin/claude-policy",
    "timeoutMs": 5000,
    "refreshIntervalMs": 300000
  }
}
```

#### Write the helper output

Claude Code runs the helper with no arguments, sets `CLAUDE_CODE_VERSION` in its environment, and reads a JSON envelope from stdout, capped at 1 MiB.

Put the settings under a `managedSettings` key. A bare settings object with no `managedSettings` key parses with `managedSettings` undefined and applies nothing, and Claude Code reports no error:

```json theme={null}
{
  "managedSettings": {
    "permissions": { "deny": ["Read(//etc/secrets/**)"] }
  }
}
```

When the helper emits `managedSettings`, that object becomes the only managed settings source for the run: Claude Code ignores the MDM, file, and HKCU sources, reads the [cross-source keys](/docs/en/managed-settings#keys-read-from-every-admin-source) from the helper's output alone, and never merges [parent settings](/docs/en/managed-settings#parent-settings-from-embedding-hosts).

The startup `forceRemoteSettingsRefresh` check runs before the helper and reads any admin source. A helper that exits `0` with an envelope that omits `managedSettings` contributes no managed settings, and the other sources apply as usual.

#### Helper failures

A helper run fails when:

* `path` breaks the rules in [`policyHelper.path`](#policyhelper-path).
* No regular file is at `path`. Claude Code checks for the file before starting the helper, within the same `timeoutMs` budget, so an unresponsive network mount can cause the run to fail.
* The helper exits non-zero, is still running when `timeoutMs` elapses, or doesn't start at all, for example because it isn't executable.
* The helper writes more than 1 MiB to stdout or to stderr.
* stdout isn't a single JSON object, or its `managedSettings` has a [schema violation Claude Code can't repair](/docs/en/managed-settings#find-entries-claude-code-dropped).

When the startup run fails, Claude Code prints the reason and refuses to start. After a non-zero exit, the reason includes the helper's stderr, or its stdout when stderr is empty. After a timeout, the reason names the `timeoutMs` limit and includes none of the helper's output. The refusal covers interactive sessions, `claude -p`, Agent SDK sessions, [background sessions](/docs/en/agent-view), and most subcommands.

The refusal is deliberate, so a helper that needs outage resilience should serve from its own cache and exit `0`.

When a background refresh fails, Claude Code keeps the last successful policy in effect, and `/status` shows the failing refresh with its reason until a refresh succeeds. Each refresh runs under the same `timeoutMs` and failure rules as the startup run.

With `--debug`, Claude Code writes the helper's stderr from every run to the [debug log](/docs/en/debug-your-config).

Claude Code reports an invalid `policyHelper` value as a [dropped entry](/docs/en/managed-settings#find-entries-claude-code-dropped) and starts the session on the remaining managed settings without running a helper. Invalid values include a bare path string and a `timeoutMs` below [its minimum](#policyhelper-timeoutms).

To turn a helper off, remove the key from the source that sets it.

### `policyHelper.path`

Name the helper executable Claude Code runs. For what happens when the path breaks the rules below, see [Helper failures](#helper-failures).

* **Scope**: [`Managed`](#scopes). Read from the macOS plist, the Windows HKLM registry, or the managed settings file, wherever [`policyHelper`](#policyhelper) is read.
* **Type**: string, an absolute path in normalized form, without `.` or `..` segments; on Windows, a drive-letter or UNC path that ends in `.exe`
* **Default**: none; required when `policyHelper` is set

```json managed-settings.json theme={null}
{
  "policyHelper": {
    "path": "/usr/local/bin/claude-policy"
  }
}
```

### `policyHelper.timeoutMs`

Set how long Claude Code waits for the helper before treating the run as failed. A timed-out run fails the same way as a non-zero exit, so at startup Claude Code refuses to start.

* **Scope**: [`Managed`](#scopes). Read from the macOS plist, the Windows HKLM registry, or the managed settings file, wherever [`policyHelper`](#policyhelper) is read.
* **Type**: integer, milliseconds, minimum `1000`
* **Default**: `10000`

```json managed-settings.json theme={null}
{
  "policyHelper": {
    "path": "/usr/local/bin/claude-policy",
    "timeoutMs": 5000
  }
}
```

### `policyHelper.refreshIntervalMs`

Have Claude Code re-run the helper in the background on an interval so policy changes reach a running session. When a refresh succeeds, its output replaces the previous managed settings without a restart; when a refresh fails, Claude Code keeps the policy it already has.

* **Scope**: [`Managed`](#scopes). Read from the macOS plist, the Windows HKLM registry, or the managed settings file, wherever [`policyHelper`](#policyhelper) is read.
* **Type**: integer, milliseconds: `0` to disable refresh, otherwise at least `60000`
* **Default**: unset, so Claude Code runs the helper once at startup

This example re-runs the helper every five minutes:

```json managed-settings.json theme={null}
{
  "policyHelper": {
    "path": "/usr/local/bin/claude-policy",
    "refreshIntervalMs": 300000
  }
}
```

### `wslInheritsWindowsSettings`

Have Claude Code on WSL read managed settings from the Windows policy chain, with HKLM and the Windows managed settings file taking priority over `/etc/claude-code` and HKCU below it. While the chain is on, Claude Code reads `/etc/claude-code` only when [no Windows admin document is present](/docs/en/managed-settings#present-admin-documents) in the HKLM registry value or the `C:\Program Files\ClaudeCode\` folder. Set it to extend the policy you already deploy on Windows to WSL sessions on the same machine, so they follow the same rules as host sessions. Claude Code honors it only when set in the HKLM registry key or in a managed settings file or drop-in under `C:\Program Files\ClaudeCode\`, both of which require Windows admin to write.

* **Scope**: [`Managed`](#scopes). In an admin-controlled Windows source.
* **Type**: Boolean
  * `true`: Claude Code on WSL reads managed settings from the Windows policy chain, and reads `/etc/claude-code` only when no Windows admin document is present
  * `false`: WSL reads only `/etc/claude-code`
* **Default**: `false`, so WSL reads only `/etc/claude-code`

```json managed-settings.json theme={null}
{
  "wslInheritsWindowsSettings": true
}
```

Once an admin source turns the chain on, HKCU policy joins it on WSL only when HKCU also sets the key to `true`. That copy doesn't turn the chain on by itself. A Windows source that contains only this key, set to `true` or `false`, doesn't count as a policy source, so a lower-priority source still supplies the policy. This key has no effect on native Windows.

Claude Code reads `true` and `false` with or without quotes and reads `null` as removing the key. An admin-controlled Windows source that holds any other value counts as a [present admin document](/docs/en/managed-settings#present-admin-documents) with the chain turned on: neither `/etc/claude-code` nor HKCU applies, and a startup warning names the key. An HKLM value or Windows-folder file that exists but can't be read also keeps `/etc/claude-code` from applying whether or not the chain is on. Requires Claude Code v2.1.282 or later.

## Global config settings

Save these keys in `~/.claude.json`, not in a settings file. Claude Code ignores them anywhere else. Claude Code and `/config` write most of them for you, and you can also edit them by hand.

### `autoConnectIde`

Connect to a running IDE automatically when you start Claude Code from an external terminal. Appears in `/config` as **Auto-connect to IDE (external terminal)** when you run Claude Code outside a VS Code or JetBrains terminal.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code connects to a running IDE automatically when you start it from an external terminal
  * `false`: Claude Code doesn't connect automatically from an external terminal; inside a VS Code or JetBrains terminal, or with `--ide`, it still connects
* **Default**: `false`
* **Per-session overrides**: [`CLAUDE_CODE_AUTO_CONNECT_IDE`](/docs/en/env-vars) takes precedence over this key for one session, in either direction

```json ~/.claude.json theme={null}
{
  "autoConnectIde": true
}
```

Claude Code ignores this key in `settings.json`.

### `autoInstallIdeExtension`

Install the Claude Code IDE extension automatically when you run Claude Code from a VS Code terminal. Appears in `/config` as **Auto-install IDE extension** when you run Claude Code inside a VS Code or JetBrains terminal.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code installs the IDE extension automatically when you run it from a VS Code terminal
  * `false`: Claude Code doesn't install the extension automatically
* **Default**: `true`
* **Per-session overrides**: [`CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL`](/docs/en/env-vars) set to `1` skips the install for one session even when this key is `true`

```json ~/.claude.json theme={null}
{
  "autoInstallIdeExtension": false
}
```

Claude Code ignores this key in `settings.json`.

### `claudeInChromeDefaultEnabled`

Start every interactive CLI session with [Chrome integration](/docs/en/chrome) on, without passing `--chrome` each time. If you run [`claude remote-control`](/docs/en/remote-control), a session it starts for one of your [project](/docs/en/claude-projects) threads follows this key too, except in `bypassPermissions` mode. With Claude Code v2.1.287 or later, this key also applies to sessions in the [VS Code extension](/docs/en/vs-code#automate-browser-tasks-with-chrome): see [Enable Chrome by default](/docs/en/chrome#enable-chrome-by-default).

Running `/chrome` and selecting **Enabled by default** sets this key for you. Appears in `/config` as **Claude in Chrome enabled by default**.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code turns on Chrome integration when an interactive CLI session starts, as it does when you pass `--chrome`. In the VS Code extension, sessions connect to the browser as they start
  * `false`: interactive CLI sessions start with Chrome integration off, and Claude Code stops [offering to set it up](/docs/en/chrome#install-the-extension-when-claude-asks). Pass `--chrome` to turn it on for one interactive session. In the VS Code extension, a session connects when you type `@browser`, as when the key is unset
* **Default**: unset, so Chrome integration is off and Claude Code can still offer to set it up
* **Per-session overrides**: `--chrome` and [`--no-chrome`](/docs/en/cli-reference) take precedence over this key for one interactive session

```json ~/.claude.json theme={null}
{
  "claudeInChromeDefaultEnabled": true
}
```

Claude Code ignores this key in `settings.json`.
