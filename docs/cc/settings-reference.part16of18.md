[Part 16/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `forceLoginGatewayUrl`

Set the gateway URL the `/login` Cloud gateway screen connects to, so people reach your [cloud gateway](/docs/en/claude-apps-gateway) without typing its address. The screen has no URL field: with this key set, it shows your gateway URL and connects when the person presses Enter; without it, it tells them to contact their IT administrator.

Either this key or `forceLoginMethod: "gateway"` makes the machine gateway-only, except for sessions that select a cloud provider with `CLAUDE_CODE_USE_*`. `/login` then opens on the Cloud gateway screen with no login-method picker. See [Administrator policy requires a Cloud gateway sign-in](/docs/en/errors#administrator-policy-requires-a-cloud-gateway-sign-in) for what happens to a leftover first-party login or API key. Set both keys so the screen connects instead of showing an error.

* **Scope**: [`Managed`](#scopes). Read only from a source on the machine: `managed-settings.json`, the macOS plist or Windows HKLM registry, or a policy helper. Claude Code ignores it in HKCU and server-managed settings.
* **Type**: string, a full URL including the scheme
* **Default**: unset, so the Cloud gateway screen shows an error telling people to contact their IT administrator

```json managed-settings.json theme={null}
{
  "forceLoginGatewayUrl": "https://claude-gateway.example.com"
}
```

If the value isn't a valid URL, the sign-in screen reports it, and the rest of the managed settings file still applies. See [Set the gateway URL](/docs/en/claude-apps-gateway#set-the-gateway-url).

### `forceLoginOrgUUID`

From a managed source, require claude.ai account logins to belong to one Anthropic organization, given as a single UUID, or to any of several organizations, given as an array. From any settings file, Claude Code also uses a single UUID to pre-select that organization during a claude.ai or Claude Console login, and pre-selects nothing for an array. If you set the key in any settings file, Claude Code also stops offering the [keyless Console sign-in](/docs/en/authentication#sign-in-without-an-api-key) in the sessions that file applies to and creates an API key instead.

* **Scope**: [`Any file`](#scopes). Only a managed source enforces the restriction; a single UUID in any other settings file pre-selects the organization during login without restricting it.
* **Type**: string, one UUID, or array of strings, several UUIDs
* **Default**: unset, so any organization can log in

This example accepts logins from either of two organizations without pre-selecting one:

```json managed-settings.json theme={null}
{
  "forceLoginOrgUUID": ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"]
}
```

If a managed source sets an empty array, or a value Claude Code can't parse, Claude Code blocks every login with a misconfiguration message.

See [Restrict login to your organization](/docs/en/authentication#restrict-login-to-your-organization) for how Claude Code treats Claude Console logins, the other login paths, and environment credentials.

### `gatewayInternalNetworks`

Declare the public IPv4 blocks that your organization numbers its internal network from, so `/login` accepts a [cloud gateway](/docs/en/claude-apps-gateway) there. Requires Claude Code v2.1.268 or later.

Without this key, `/login` connects to any gateway on a private address and nothing else. With it, `/login` also accepts a gateway inside a listed block, over a direct connection only. The machine's own address on that connection must also be inside the same block.

* **Scope**: [`Managed`](#scopes). Read only from a source on the machine: `managed-settings.json`, the macOS plist or Windows HKLM registry, or a policy helper. Claude Code ignores it in HKCU and server-managed settings.
* **Type**: array of strings, at most four IPv4 CIDR blocks, each `/8` to `/32`, not overlapping one another, and none overlapping private space.
* **Default**: unset, so `/login` accepts only gateways on private addresses

```json managed-settings.json theme={null}
{
  "gatewayInternalNetworks": ["203.0.113.0/24"]
}
```

Replace the documentation range in the example with your own block. Claude Code refuses the documentation ranges, the ranges that VPN and NAT64 clients use locally, and reserved space that no network is numbered from, such as multicast.

If an entry is invalid, or the value isn't a list of strings, `/login` names the problem and refuses every new gateway sign-in on the machine until you fix the value. Existing sign-ins keep working. See [Allow a gateway on public address space you own](/docs/en/claude-apps-gateway#allow-a-gateway-on-public-address-space-you-own) for the full rules and what developers see.

### `gcpAuthRefresh`

Run your own command to refresh Google Cloud Application Default Credentials when Claude Code finds they've expired or can't be loaded, so [Google Cloud's Agent Platform](/docs/en/google-vertex-ai) requests keep working without you re-authenticating by hand.

When several Claude Code processes that use the same command and credentials, such as separate terminals or IDE windows, find them expired at the same time, one process runs the command and the rest wait for that run instead of starting their own. A process that has waited 60 seconds with a request pending runs the command itself. To turn this off, set [`CLAUDE_CODE_DISABLE_AUTH_REFRESH_LOCK`](/docs/en/env-vars) to `1`.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, a shell command line
* **Default**: unset, so Claude Code's credential error tells you to run `gcloud auth application-default login` yourself

```json settings.json theme={null}
{
  "gcpAuthRefresh": "gcloud auth application-default login"
}
```

See [advanced credential configuration](/docs/en/google-vertex-ai#advanced-credential-configuration).

### `otelHeadersHelper`

Run your own command to generate the headers Claude Code sends with OpenTelemetry exports, for backends whose tokens rotate. Claude Code runs it at startup and periodically after that, and expects a JSON object of string header values on stdout.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, an executable path or a shell command line
* **Default**: unset, so Claude Code adds no helper-generated headers

```json settings.json theme={null}
{
  "otelHeadersHelper": "/bin/generate_otel_headers.sh"
}
```

Set the refresh interval with [`CLAUDE_CODE_OTEL_HEADERS_HELPER_DEBOUNCE_MS`](/docs/en/env-vars). See [Dynamic headers](/docs/en/monitoring-usage#dynamic-headers) for the script requirements and what happens when the helper fails.

## Updates and versioning

Choose an update channel and, for organizations, pin the versions people can run. See [Update Claude Code](/docs/en/setup#update-claude-code).

### `autoUpdatesChannel`

Choose which [release channel](/docs/en/setup#configure-release-channel) background auto-updates and `claude update` follow. Set `"stable"` for a version that is typically about one week old and skips releases with major regressions, or `"latest"` for the most recent release.

* **Scope**: [`Any file`](#scopes). Set it in managed settings to enforce one channel across your organization.
* **Type**: string, one of:
  * `"latest"`: updates follow the most recent release
  * `"stable"`: updates follow a version that is typically about one week old and skips releases with major regressions
* **Default**: unset, so Claude Code follows `"latest"`

```json settings.json theme={null}
{
  "autoUpdatesChannel": "stable"
}
```

Claude Code writes `"stable"` to your user settings when you pick it under **Auto-update channel** in `/config`, and removes the key when you switch back to latest there. `claude install stable` and `claude install latest` also save the channel you name. Switching from `"latest"` to `"stable"` in `/config` asks whether to allow a downgrade or stay on your current version; staying sets [`minimumVersion`](#minimumversion). Homebrew installs ignore this key: the `claude-code` cask tracks stable and `claude-code@latest` tracks latest, and `claude update` defers to `brew upgrade`. To turn auto-updates off entirely, set [`DISABLE_AUTOUPDATER`](/docs/en/setup#disable-auto-updates) in `env`.

### `minimumVersion`

Keep background auto-updates and `claude update` from installing any version below this one, so moving to the `"stable"` channel doesn't downgrade you from a newer `"latest"` build. Claude Code writes this key for you when you choose to stay on your current version while switching channels in `/config`, and clears it when you switch back to `"latest"`.

* **Scope**: [`Any file`](#scopes). Set it in managed settings to pin an organization-wide minimum that user and project settings can't lower.
* **Type**: string, a version number such as `"2.1.100"`; a value that isn't a valid version is ignored
* **Default**: unset, so updates can install any version the channel offers

This example follows the stable channel and refuses to install any version below 2.1.100:

```json settings.json theme={null}
{
  "autoUpdatesChannel": "stable",
  "minimumVersion": "2.1.100"
}
```

This key only constrains updates. To make Claude Code refuse to start below a version, use [`requiredMinimumVersion`](#requiredminimumversion) instead. See [Pin a minimum version](/docs/en/setup#pin-a-minimum-version).

### `requiredMaximumVersion`

Set the newest Claude Code version your organization allows to start. When the running version is newer, Claude Code exits at startup and tells the user to install an approved version through your organization's approved method; `claude install <version>` may also work. Requires Claude Code v2.1.163 or later.

* **Scope**: [`Managed`](#scopes). Claude Code gives no warning when it ignores the key elsewhere.
* **Type**: string, a version number such as `"2.1.150"`; a value that isn't a valid version is ignored
* **Default**: unset, so no ceiling applies

```json managed-settings.json theme={null}
{
  "requiredMaximumVersion": "2.1.150"
}
```

Background auto-updates and `claude update` skip versions above the ceiling, so an installation inside the range stays inside it. `claude update`, `claude install`, and `claude doctor` keep working above the ceiling so users can recover. Pair it with [`requiredMinimumVersion`](#requiredminimumversion) to enforce a range.

### `requiredMinimumVersion`

Set the oldest Claude Code version your organization allows to start. When the running version is older, Claude Code exits at startup and tells the user to update through your organization's approved method. The check runs at startup only, so a session that's already running continues. Requires Claude Code v2.1.163 or later.

* **Scope**: [`Managed`](#scopes). Claude Code gives no warning when it ignores the key elsewhere.
* **Type**: string, a version number such as `"2.1.150"`; a value that isn't a valid version is ignored
* **Default**: unset, so no floor applies

```json managed-settings.json theme={null}
{
  "requiredMinimumVersion": "2.1.150"
}
```

`claude update`, `claude install`, and `claude doctor` keep working below the floor so users can recover. Unlike [`minimumVersion`](#minimumversion), which only prevents downgrades, this key blocks startup. Pair it with [`requiredMaximumVersion`](#requiredmaximumversion) to enforce a range.

## Tools

Turn off specific tools in the [Claude Code desktop app](/docs/en/desktop). The terminal CLI ignores these keys. For the tools themselves, see [Tools available to Claude](/docs/en/tools-reference).

### `browserExternalPageTools`

Stop Claude from using its tools to read or act on external pages in the desktop app's [Browser pane](/docs/en/desktop#browse-external-sites). People in your organization can still open external sites themselves, and local dev server previews keep working with Claude's tools. The desktop app reads this key; the terminal CLI ignores it.

* **Scope**: [`Managed`](#scopes)
* **Type**: string, `"disabled"`; the desktop app also accepts `"disable"`, in either case
* **Default**: unset, so Claude's tools work on external pages

```json managed-settings.json theme={null}
{
  "browserExternalPageTools": "disabled"
}
```

Any other value leaves Claude's tools on, and a non-empty string that isn't one of the two accepted values logs a warning. To block external sites for people and Claude alike, set [`disableBrowserExternalNavigation`](#disablebrowserexternalnavigation) instead. See [Restrict external browsing for your organization](/docs/en/desktop#restrict-external-browsing-for-your-organization).

### `disableBrowserExternalNavigation`

Turn off external browsing in the desktop app's [Browser pane](/docs/en/desktop#browse-external-sites) for people and Claude alike. Localhost dev server previews keep working. The desktop app reads this key; the terminal CLI ignores it.

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean; only the JSON Boolean `true` takes effect
  * `true`: the desktop app turns off external browsing in the Browser pane for people and Claude alike; localhost previews keep working
  * `false`: external browsing stays on
* **Default**: unset, so external browsing is on

```json managed-settings.json theme={null}
{
  "disableBrowserExternalNavigation": true
}
```

The desktop app ignores any other value, and a value that isn't a Boolean, such as the string `"true"` or `1`, also logs a warning. To leave external browsing on but keep Claude's tools off external pages, set [`browserExternalPageTools`](#browserexternalpagetools) instead. See [Restrict external browsing for your organization](/docs/en/desktop#restrict-external-browsing-for-your-organization).

### `disableMobileSimulatorTools`

Block Claude's tools for the desktop app's [iOS Simulator pane](/docs/en/desktop-ios-simulator#turn-off-simulator-access). People keep manual use of the pane; only Claude's access is removed, and nobody can turn it back on from inside the app. The desktop app reads this key; the terminal CLI ignores it.

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean; only the JSON Boolean `true` takes effect
  * `true`: the desktop app blocks Claude's tools for the iOS Simulator pane
  * `false`: Claude's simulator tools follow each person's settings toggle in the desktop app
* **Default**: unset, so Claude's simulator tools follow each person's settings toggle in the desktop app

```json managed-settings.json theme={null}
{
  "disableMobileSimulatorTools": true
}
```

The desktop app ignores any other value, and a value that isn't a Boolean, such as the string `"true"` or `1`, also logs a warning.

<span id="data-and-privacy" />

## Privacy and telemetry

Control how long Claude Code keeps session data and what it sends. The switches that turn off usage metrics and error reports are environment variables, not settings keys: set `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` in the [`env`](#env) key or in the shell. [Telemetry services](/docs/en/data-usage#telemetry-services) says what each one stops. Two exceptions turn off from a settings file: [`feedbackDrafts`](#feedbackdrafts) below for Claude-drafted feedback, and [`feedbackSurveyRate`](#feedbacksurveyrate) below for the session survey.

### `cleanupPeriodDays`

Set how many days Claude Code keeps [session transcripts and other application data](/docs/en/claude-directory#cleaned-up-automatically) before deleting them. Claude Code runs the deletion as a background sweep after a session starts, as long as it can safely determine the retention period. The sweep deletes transcripts without showing a message, so a session you haven't used for longer than the retention period no longer appears in the [`/resume`](/docs/en/sessions#resume-a-session) picker.

* **Scope**: [`Any file`](#scopes)
* **Type**: number of days, a whole number, minimum `1`
* **Default**: `30`

```json settings.json theme={null}
{
  "cleanupPeriodDays": 20
}
```

Setting `0` fails validation, so pick a large value such as `3650` for long retention. To stop Claude Code from writing transcripts at all, see [Plaintext storage](/docs/en/claude-directory#plaintext-storage).

### `desktopSessionCleanupPeriodDays`

Set an age limit in days for the transcripts of sessions you started or most recently continued in Claude Desktop or Cowork. Without this key, Claude Code [keeps those transcripts at any age](/docs/en/claude-directory#cleaned-up-automatically). Claude Code deletes each one once it's older than both this limit and [`cleanupPeriodDays`](#cleanupperioddays), so with `cleanupPeriodDays` at its default of 30, a value of `7` still keeps them 30 days. [Cleaned up automatically](/docs/en/claude-directory#cleaned-up-automatically) lists the cases where `cleanupPeriodDays` applies instead and Claude Code ignores this key. Requires Claude Code v2.1.248 or later.

* **Scope**: [`User or managed`](#scopes). Claude Code also reads the key from a file you pass with `--settings`, and ignores it in project and local settings.
* **Type**: number of days, a whole number, minimum `0`
* **Default**: `0`, which sets no age limit

```json settings.json theme={null}
{
  "desktopSessionCleanupPeriodDays": 90
}
```

### `feedbackDrafts`

Control [Claude-drafted feedback](/docs/en/tools-reference#sendfeedback-tool-behavior): whether Claude can queue feedback drafts for you to review, and whether Claude Code shows a card when Claude queues one.

* **Scope**: [`User or managed`](#scopes)
* **Type**: string, one of `"notify"`, `"quiet"`, or `"off"`
  * `"notify"`: Claude Code shows a card above the prompt when Claude queues a draft, up to [three cards in a session](/docs/en/tools-reference#what-you-see-when-claude-drafts) by default
  * `"quiet"`: Claude drafts without a card. You see the count of queued drafts in the prompt footer and review them in `/feedback`
  * `"off"`: Claude Code removes the SendFeedback tool, so Claude can't queue drafts
* **Default**: `"notify"`
* **Per-session overrides**: [`CLAUDE_CODE_SEND_FEEDBACK`](/docs/en/env-vars) set to `0` turns the feature off for one session

```json settings.json theme={null}
{
  "feedbackDrafts": "quiet"
}
```

Appears in `/config` as **Claude-drafted feedback**, which writes this key to your user settings. You see the `/config` row only in sessions [where Claude can draft feedback](/docs/en/tools-reference#sessions-without-claude-drafted-feedback); setting `"off"` doesn't hide it, so you can turn the feature back on from the same row. A value in managed settings takes precedence over your user setting, so when an administrator sets this key, the row shows the managed value and changing it has no effect. Claude Code ignores this key in project and local settings.

### `feedbackSurveyRate`

Set the probability that the [session quality survey](/docs/en/data-usage#session-quality-surveys) appears when a session is eligible for it. Set `0` to keep the survey from appearing.

* **Scope**: [`Any file`](#scopes)
* **Type**: number between `0` and `1`
* **Default**: unset, so Claude Code uses the rate Anthropic sets remotely, or its built-in rate of `0.005` on Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry, which don't receive remote configuration
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY`](/docs/en/env-vars) set to `1` turns the survey off for one session whatever rate this key sets

```json settings.json theme={null}
{
  "feedbackSurveyRate": 0.05
}
```

The same rate applies to the survey in the VS Code extension.

### `skipWebFetchPreflight`

Skip the [WebFetch domain safety check](/docs/en/data-usage#webfetch-domain-safety-check), which sends each requested hostname to `api.anthropic.com` before fetching. Set `true` in environments that block traffic to Anthropic, such as Amazon Bedrock, Google Cloud's Agent Platform, or Microsoft Foundry deployments with restrictive egress.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code skips the WebFetch domain safety check
  * `false`: the check runs before the first fetch to each hostname in a session, and again for a hostname whose earlier check was blocked or failed
* **Default**: unset, so the check runs before the first fetch to each hostname in a session

```json settings.json theme={null}
{
  "skipWebFetchPreflight": true
}
```

With the check skipped, WebFetch attempts any URL without consulting the blocklist, so pair it with [`WebFetch` permission rules](/docs/en/permissions#webfetch) if you need to restrict which domains Claude can reach.

<span id="managed-policy" />

## Enterprise and managed settings

Keys an organization uses to compute, refresh, and combine managed settings. See [Set up managed settings](/docs/en/admin-setup).

### `disableSideloadFlags`

Reject the `--plugin-dir`, `--plugin-url`, `--agents`, and `--mcp-config` CLI flags at startup, which users could otherwise pass to bypass [`strictKnownMarketplaces`](#strictknownmarketplaces) for a single run. Claude Code exits with an error naming the rejected flags. In [cloud sessions](/docs/en/claude-code-on-the-web), Claude Code instead starts the session and drops every server-delivered `--mcp-config` entry except in-process `type: "sdk"` entries and a [Claude Tag](/docs/en/claude-tag) session's Slack tools. Requires Claude Code v2.1.193 or later.

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code rejects `--plugin-dir`, `--plugin-url`, `--agents`, and `--mcp-config` at startup and exits with an error naming them. In cloud sessions, it instead starts the session and drops every server-delivered `--mcp-config` entry except in-process `type: "sdk"` entries and a Claude Tag session's Slack tools
  * `false`: Claude Code accepts those flags
* **Default**: `false`

```json managed-settings.json theme={null}
{
  "disableSideloadFlags": true
}
```

Claude Code still accepts a `--mcp-config` whose servers are all in-process `type: "sdk"` entries, so the Agent SDK and VS Code extension keep working. Users can still add servers with `claude mcp add` or a `.mcp.json` file; for per-server control, set [`allowedMcpServers`](/docs/en/managed-mcp) as well. Requires Claude Code v2.1.193 or later.

The same check covers plugin folders named in the [`CLAUDE_CODE_PLUGIN_DIRS`](/docs/en/env-vars#variables) environment variable, which requires Claude Code v2.1.280 or later. When the variable names a folder, Claude Code exits with the same error, and the error says to unset the variable.

In cloud sessions, Claude Code also ignores server-delivered mid-session MCP updates, the path behind cloud session configuration and SDK `setMcpServers()` calls that reach those sessions. In-process `type: "sdk"` entries and a Claude Tag session's Slack tools stay exempt there too. Before v2.1.268, both this drop and the startup drop also removed a Claude Tag session's Slack tools. Before v2.1.239, a server-delivered `--mcp-config` blocked a cloud session from starting.

The desktop app manages some plugins itself, including plugins synced from claude.ai and plugins your organization deploys through the app. If you deploy this key to a device through MDM, OS-level policy, or a managed settings file, the desktop app doesn't pass those plugins to the following sessions on that device:

* **[Code sessions on the user's machine](/docs/en/desktop#environment-configuration)**: they also start without the skills enabled for the user's claude.ai account. Plugins that Claude Code installs from marketplaces in your managed settings still load. In [Claude Desktop on 3P](https://claude.com/docs/third-party/claude-desktop/overview), MCP servers from plugins you deploy to the device's `org-plugins` directory stay available too, because the desktop app connects to them itself. Before Claude Desktop v1.37937.0, these sessions failed at startup instead.
* **[Cowork sessions on the user's machine](/docs/en/managed-settings#where-and-when-a-policy-applies)**: the skills inside those plugins and the skills enabled for the user's claude.ai account stay available. In [Claude Desktop on 3P](https://claude.com/docs/third-party/claude-desktop/overview), MCP servers from plugins you deploy to the device's `org-plugins` directory stay available too, because the desktop app connects to them itself. Before Claude Desktop v1.44121.0, these sessions failed at startup instead.
