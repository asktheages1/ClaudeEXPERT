[Part 15/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `disableDeepLinkRegistration`

Stop Claude Code from registering the `claude-cli://` protocol handler with the operating system, which it otherwise does after you send the first prompt of an interactive session. [Deep links](/docs/en/deep-links) let external tools open a Claude Code session with a pre-filled prompt. Set this in environments where protocol handler registration is restricted or managed separately.

* **Scope**: [`Any file`](#scopes)
* **Type**: the string `"disable"`
* **Default**: unset, so Claude Code registers the handler

```json settings.json theme={null}
{
  "disableDeepLinkRegistration": "disable"
}
```

### `disableDesktopLocalSessions`

Turn off Code sessions that run on the device in the [desktop app](/docs/en/desktop#local-sessions-on-managed-devices), for deployments where developers should work on remote machines over SSH. In the Code tab, the **Local** environment stays in the environment dropdown but is grayed out and can't be selected, with a tooltip saying your organization turned it off; on Windows the WSL entry is grayed out the same way, though whether WSL sessions run on a managed device at all is [governed separately](/docs/en/admin-setup#wsl-sessions-in-claude-code-desktop). New sessions default to the first [SSH connection](/docs/en/desktop#ssh-sessions) if one is configured, and the app refuses to start or resume a session on the device, including an SSH connection back to the same machine. SSH sessions to other hosts and cloud sessions are unaffected. The desktop app reads this key; the terminal CLI ignores it. Requires Claude Desktop v1.37937.0 or later.

* **Scope**: [`Managed`](#scopes). By default, the desktop app reads the key from [one managed source](/docs/en/managed-settings#how-claude-code-combines-managed-sources).
* **Type**: Boolean; only the JSON Boolean `true` takes effect
  * `true`: the desktop app offers no on-device Code sessions; existing local sessions stay listed but can't continue
  * `false`: local sessions stay available
* **Default**: unset, so local sessions are available

```json managed-settings.json theme={null}
{
  "disableDesktopLocalSessions": true
}
```

The desktop app ignores any other value, and a value that isn't a Boolean, such as the string `"true"` or `1`, also logs a warning. Pair it with [`sshConfigs`](#sshconfigs) so users land on a working connection, and with [`sshHostAllowlist`](#sshhostallowlist) to limit which hosts they can reach. See [Local sessions on managed devices](/docs/en/desktop#local-sessions-on-managed-devices).

Claude Desktop supplies Code sessions with policy derived from your desktop configuration, for example the egress allowlist, filesystem sandbox, and MCP restrictions in third-party deployments. Claude Code ignores those parent settings whenever an [admin source](/docs/en/managed-settings#how-claude-code-combines-managed-sources) is present: server-managed settings, an MDM or OS-level policy, or a managed settings file. Deploying this key through one of those on a device that had none before, as in third-party deployments, therefore stops the desktop-derived policies from applying. [Let an embedding host add policy](/docs/en/managed-settings#let-an-embedding-host-add-policy) covers when parent settings can still merge; this holds for any key you deploy that way, not only this one.

### `disableRemoteControl`

Turn off [Remote Control](/docs/en/remote-control): Claude Code then refuses `claude remote-control`, the `--remote-control` flag, auto-start, and the in-session toggle, and reports that your organization's policy disabled it. Place it in [managed settings](/docs/en/managed-settings) for per-device MDM enforcement.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code refuses `claude remote-control`, the `--remote-control` flag, auto-start, and the in-session toggle
  * `false`: Remote Control stays available
* **Default**: `false`

```json settings.json theme={null}
{
  "disableRemoteControl": true
}
```

### `enableArtifact`

Turn off the [Artifact](/docs/en/artifacts) tool, which publishes session output as a private web page on claude.ai. When you turn the **Artifacts** row off in `/config`, Claude Code writes this key to your user settings, so you don't usually edit it by hand. Requires Claude Code v2.1.196 or later.

* **Scope**: [`Any file`](#scopes). Every file can turn the tool off, and none can turn it back on.
* **Type**: Boolean
  * `false`: Claude Code turns the Artifact tool off for every session the file applies to
  * `true`: the same as leaving the key unset, because it never overrides a `false` from another file, from [`CLAUDE_CODE_DISABLE_ARTIFACT`](/docs/en/env-vars), or from your organization's [admin setting](/docs/en/artifacts#manage-artifacts-for-your-organization)
* **Default**: unset, so the tool follows your account's [availability](/docs/en/artifacts#availability)

```json settings.json theme={null}
{
  "enableArtifact": false
}
```

While a source other than your own user settings keeps the tool turned off, Claude Code hides the **Artifacts** row in `/config`, because turning it on there wouldn't change anything. [Disable artifacts](/docs/en/artifacts#disable-artifacts) lists every way to turn the tool off.

### `inputNeededNotifEnabled`

Get a push notification on your phone when a permission prompt or question is waiting for your input. Claude Code sends these only while [Remote Control](/docs/en/remote-control) is connected. Appears in `/config` as **Push when actions required**.

* **Scope**: [`Any file`](#scopes). Claude Code also reads a value left in `~/.claude.json` by older versions.
* **Type**: Boolean
  * `true`: you get a push notification on your phone when a permission prompt or question is waiting, while Remote Control is connected
  * `false`: Claude Code sends no such notifications
* **Default**: `false`

```json settings.json theme={null}
{
  "inputNeededNotifEnabled": true
}
```

See [Mobile push notifications](/docs/en/remote-control#mobile-push-notifications).

### `preferredNotifChannel`

Choose how Claude Code notifies you when a task completes or a permission prompt is waiting. Appears in `/config` as **Local notifications**.

* **Scope**: [`Any file`](#scopes). Claude Code also reads a value left in `~/.claude.json` by older versions.
* **Type**: string, one of:
  * `"auto"`: Claude Code sends a desktop notification in iTerm2, Ghostty, and Kitty, rings the bell in Terminal.app only when its audible bell is off, and does nothing elsewhere
  * `"terminal_bell"`: Claude Code rings the bell character in any terminal
  * `"iterm2"`: Claude Code sends an iTerm2 desktop notification
  * `"iterm2_with_bell"`: Claude Code sends an iTerm2 desktop notification and rings the bell
  * `"kitty"`: Claude Code sends a Kitty desktop notification
  * `"ghostty"`: Claude Code sends a Ghostty desktop notification
  * `"notifications_disabled"`: Claude Code sends no notification
* **Default**: `"auto"`

```json settings.json theme={null}
{
  "preferredNotifChannel": "terminal_bell"
}
```

With `"auto"`, Claude Code sends a desktop notification in iTerm2, Ghostty, and Kitty. In Terminal.app it rings the bell character only when you have turned Terminal's audible bell off, and in other terminals it does nothing. Set `"terminal_bell"` to ring the bell character in any terminal. See [Get a terminal bell or notification](/docs/en/terminal-config#get-a-terminal-bell-or-notification).

### `remote.defaultEnvironmentId`

Pick the default [cloud environment](/docs/en/cloud-environments) for cloud sessions you create from the CLI, such as with `claude --cloud`. Claude Code writes this key to your user settings when you pick an environment with [`/remote-env`](/docs/en/cloud-environments#select-an-environment-from-the-cli).

* **Scope**: [`Any file`](#scopes). For a self-hosted environment ID, user or managed settings, or the `--settings` flag only.
* **Type**: string, an environment ID such as `env_...` or `ccpool_...`
* **Default**: unset, so Claude Code uses the Anthropic-hosted environment when your list has one, and otherwise the first environment in your list that isn't a [Remote Control bridge environment](/docs/en/cloud-environments#the-default-environment), or the first environment when every one is a bridge environment
* **Per-session overrides**: `--environment` takes precedence over this key for the one cloud session it creates

```json settings.json theme={null}
{
  "remote": {
    "defaultEnvironmentId": "env_0123abcd"
  }
}
```

An Anthropic-hosted environment ID, which starts with `env_`, follows the standard settings precedence, so a value in a repository's project settings overrides your user-level pick. A [self-hosted environment](/docs/en/self-hosted-environments) ID, which starts with `ccpool_`, is honored only from user settings, managed settings, and the `--settings` flag; Claude Code ignores one in a repository's project or local settings, and `/remote-env` shows which value it ignored, so a checked-in file can't steer sessions onto a self-hosted environment you didn't choose.

### `remoteControlAtStartup`

Connect [Remote Control](/docs/en/remote-control) automatically when each interactive session starts, instead of waiting for `/remote-control`. Set it to `true` to turn auto-connect on, `false` to turn it off. Appears in `/config` as **Enable Remote Control for all sessions**.

* **Scope**: [`Any file`](#scopes). Claude Code also reads a value left in `~/.claude.json` by older versions.
* **Type**: Boolean
  * `true`: Claude Code connects Remote Control automatically when each interactive session starts
  * `false`: Claude Code waits for `/remote-control`
* **Default**: unset, so the [auto-connect default](/docs/en/remote-control#enable-remote-control-for-all-sessions) applies
* **Per-session overrides**: `--remote-control` turns Remote Control on for one session even when this key is `false`, and no flag turns it off for one session

```json settings.json theme={null}
{
  "remoteControlAtStartup": true
}
```

Claude Code ignores a `true` from project or local settings, so a repository can turn auto-connect off for its checkout but can't turn it on. For the full per-scope behavior, see [Enable Remote Control for all sessions](/docs/en/remote-control#enable-remote-control-for-all-sessions) and the [security keys where the stricter value applies](/docs/en/settings#security-keys-where-the-stricter-value-applies).

### `sshConfigs`

Add SSH connections to the [Desktop](/docs/en/desktop#pre-configure-ssh-connections-for-your-team) environment dropdown. Administrators use it to distribute shared connections to a team. Connections you define in managed settings show as managed, so users can select them but can't edit or delete them in the app.

* **Scope**: [`User or managed`](#scopes). The desktop app reads this key. By default, it reads managed connections from [one managed source](/docs/en/managed-settings#how-claude-code-combines-managed-sources).
* **Type**: array of objects, each with required `id`, `name`, and `sshHost` and optional `sshPort` and `sshIdentityFile`
* **Default**: unset

This example adds one connection named `Dev VM` that connects to `user@dev.example.com`:

```json settings.json theme={null}
{
  "sshConfigs": [
    {
      "id": "dev-vm",
      "name": "Dev VM",
      "sshHost": "user@dev.example.com"
    }
  ]
}
```

### `sshHostAllowlist`

Limit the hosts a [Desktop SSH session](/docs/en/desktop#restrict-which-ssh-hosts-users-can-connect-to) can connect to. Only the Desktop app reads this key; the CLI doesn't. Patterns are case-insensitive: `*` matches any host, `*.example.com` matches `example.com` and every subdomain, and anything else is an exact match against the hostname after `~/.ssh/config` resolution. An empty array turns SSH sessions off.

* **Scope**: [`Managed`](#scopes). By default, Desktop reads the key from [one managed source](/docs/en/managed-settings#how-claude-code-combines-managed-sources).
* **Type**: array of hostname patterns
* **Default**: unset, so any host is allowed

This example allows `devboxes.example.com` and its subdomains, plus the exact host `bastion.example.com`:

```json managed-settings.json theme={null}
{
  "sshHostAllowlist": ["*.devboxes.example.com", "bastion.example.com"]
}
```

A value that Desktop can't read as a list of hosts, such as `true` or an object, counts as an empty array until you correct it, except `null`, which counts as unset. Requires Claude Desktop v2.26454.0 or later.

If you set [`managedSourcesBehavior`](#managedsourcesbehavior) to `"merge"` in your highest-ranked source, Desktop combines the lists from every [admin source](/docs/en/managed-settings#how-claude-code-combines-managed-sources) and allows a host that matches any of them. If you set an empty array in one source, SSH sessions stay on for the hosts another source lists.

<span id="authentication-and-login" />

## Authentication and providers

Supply credentials through helper scripts and, for organizations, force a login method or organization. See [Authentication](/docs/en/authentication).

### `allowedProviders`

List the services a machine may reach Claude through, such as the Anthropic API, Amazon Bedrock, or an LLM gateway. A session on a provider that isn't listed is refused at startup, at login, and when it next contacts the API, so switching to an unlisted provider mid-session is refused too. The [refusal message](/docs/en/errors#managed-settings-dont-allow-this-api-provider) names what selected the provider and the steps to continue. Requires Claude Code v2.1.285 or later.

* **Scope**: [`Managed`](#scopes). A list that the machine's own admin sources set, MDM policies and managed settings files, keeps applying when server-managed settings also deliver one: a session may then use only the providers on both lists, so a server-managed list can narrow what the machine allows but never widen it. Which machine source's `allowedProviders` counts follows [how Claude Code combines managed sources](/docs/en/managed-settings#how-claude-code-combines-managed-sources). A list delivered through server-managed settings alone reaches only the sessions that [fetch server-managed settings](/docs/en/server-managed-settings#platform-availability).
* **Type**: array of strings, each one of:
  * `"anthropic"`: the Anthropic API on Anthropic's own host, through a claude.ai or Console sign-in or an API key. Pair it with [`forceLoginMethod`](#forceloginmethod) or [`forceLoginOrgUUID`](#forceloginorguuid) to also restrict the sign-in
  * `"bedrock"`: [Amazon Bedrock](/docs/en/amazon-bedrock)
  * `"vertex"`: [Google Cloud's Agent Platform](/docs/en/google-vertex-ai), formerly Vertex AI
  * `"foundry"`: [Microsoft Foundry](/docs/en/microsoft-foundry)
  * `"anthropicAws"`: [Claude Platform on AWS](/docs/en/claude-platform-on-aws)
  * `"mantle"`: the Amazon Bedrock [Mantle endpoint](/docs/en/amazon-bedrock#use-the-mantle-endpoint). A session that [runs Mantle alongside the Invoke API](/docs/en/amazon-bedrock#run-mantle-alongside-the-invoke-api) uses both providers, so list `"bedrock"` and `"mantle"` together for it
  * `"customEndpoint"`: the Anthropic API or a cloud provider's API sent to another host, such as an [LLM gateway](/docs/en/llm-gateway) named by `ANTHROPIC_BASE_URL` or by a provider's endpoint variable such as `ANTHROPIC_BEDROCK_BASE_URL`. Claude Code admits it only for the exact value a managed [`env`](#env) block pins
  * `"gateway"`: a [Cloud gateway](/docs/en/claude-apps-gateway) sign-in
* **Default**: unset, so any provider can be used

```json managed-settings.json theme={null}
{
  "allowedProviders": ["anthropic", "bedrock"]
}
```

Each cloud provider's entry means that provider's own service, including its regional, FIPS, and private endpoints.

An entry Claude Code doesn't recognize as a provider name is dropped and reported, and the rest of the list stays enforced. With an empty list, or one whose every entry is unrecognized, Claude Code refuses every provider and doesn't start on the machine.

#### Endpoints that need a pin in managed `env`

A pin is an endpoint variable's value set in a managed [`env`](#env) block. When a session sends a provider's traffic somewhere other than that provider's own service, Claude Code admits it only if the session's value is the same as the pin. These endpoints need one:

* **`"customEndpoint"` sessions**: the variable that names the host, such as `ANTHROPIC_BASE_URL`
* **Amazon Bedrock**: the AWS SDK's `AWS_ENDPOINT_URL`, `AWS_ENDPOINT_URL_BEDROCK`, and `AWS_ENDPOINT_URL_BEDROCK_RUNTIME` variables when they point outside Bedrock's own service. The session stays under `"bedrock"` rather than `"customEndpoint"`
* **A gateway sign-in's URL**: the session stays under `"gateway"`, and [`forceLoginGatewayUrl`](#forcelogingatewayurl) also counts as the pin

Which `env` blocks count as pins depends on where the list is set:

* **An administrator source on the machine sets a list**: only the `env` blocks of the machine's own administrator sources count
* **Only server-managed settings set a list**: an `env` value in those server-managed settings counts too

The list doesn't judge a cloud provider's credential and tenancy variables or the network path, such as `HTTPS_PROXY` and certificate settings. Set those for the fleet in the managed `env` block.

### `apiKeyHelper`

Run your own command to produce the credential Claude Code sends with model requests. Claude Code runs the command through the system shell, `/bin/sh` on macOS and Linux and `cmd` on Windows, and sends its output as both the `X-Api-Key` and `Authorization: Bearer` headers. Use it for dynamic or rotating credentials, such as short-lived tokens fetched from a vault.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, a shell command line
* **Default**: unset, so Claude Code doesn't run a helper

```json settings.json theme={null}
{
  "apiKeyHelper": "/bin/generate_temp_api_key.sh"
}
```

Claude Code caches the value and reruns the command in these cases:

* After the cache lifetime, five minutes by default or the interval you set with [`CLAUDE_CODE_API_KEY_HELPER_TTL_MS`](/docs/en/env-vars).
* When a request to the Anthropic API, directly or through an [LLM gateway](/docs/en/llm-gateway), fails with `401` or `403`.
* Before sending a request to the Anthropic API, directly or through an LLM gateway, when the cached output is a JWT that expired after the helper produced it. Requires Claude Code v2.1.246 or later.

The last two cases apply only when the helper's output is the credential Claude Code sends and `ANTHROPIC_AUTH_TOKEN` isn't set.

In interactive sessions, when the command comes from project or local settings, Claude Code doesn't run it until you accept the workspace trust prompt. See [Credential management](/docs/en/authentication#credential-management).

### `awsAuthRefresh`

Run your own command, such as `aws sso login`, to refresh the credentials in your `.aws` directory when the ones Claude Code has for [Amazon Bedrock](/docs/en/amazon-bedrock) stop working. Claude Code checks the current credentials against STS first and runs the command only when that check fails, then reads the refreshed `.aws` directory.

When the check fails at the same time in several Claude Code processes that use the same command and credentials, such as separate terminals or IDE windows, one process runs the command and the rest wait for that run instead of starting their own. A process that has waited 60 seconds with a request pending runs the command itself. To turn this off, set [`CLAUDE_CODE_DISABLE_AUTH_REFRESH_LOCK`](/docs/en/env-vars) to `1`.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, a shell command line
* **Default**: unset, so Claude Code doesn't refresh AWS credentials for you

```json settings.json theme={null}
{
  "awsAuthRefresh": "aws sso login --profile myprofile"
}
```

Use this key when your refresh flow writes to `.aws`; use [`awsCredentialExport`](#awscredentialexport) when it prints credentials instead. See [advanced credential configuration](/docs/en/amazon-bedrock#advanced-credential-configuration).

### `awsCredentialExport`

Run your own command that prints AWS credentials as JSON, so Claude Code can call [Amazon Bedrock](/docs/en/amazon-bedrock) with credentials that don't live in your `.aws` directory. Claude Code accepts the `aws sts` output shape and the flat `aws configure export-credentials` shape, and scopes the credentials to its own Bedrock client, so the shell commands Claude runs still see your ambient credentials.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, a shell command line
* **Default**: unset, so Claude Code uses the ambient AWS credential chain

```json settings.json theme={null}
{
  "awsCredentialExport": "/bin/generate_aws_grant.sh"
}
```

Unlike [`awsAuthRefresh`](#awsauthrefresh), Claude Code always runs this command when it's set, without checking the ambient credentials first. See [advanced credential configuration](/docs/en/amazon-bedrock#advanced-credential-configuration).

### `forceLoginMethod`

Restrict which kind of account people can log in with. Set `"claudeai"` to allow only claude.ai accounts, `"console"` to allow only Claude Console accounts, or `"gateway"` to send people to a [cloud gateway](/docs/en/claude-apps-gateway) instead of a first-party login. Administrators set it in managed settings and pair it with [`forceLoginOrgUUID`](#forceloginorguuid) to keep developers' claude.ai logins inside one organization. If you set it to `"claudeai"` or `"console"` in any settings file, Claude Code also stops offering the [keyless Console sign-in](/docs/en/authentication#sign-in-without-an-api-key) in the sessions that file applies to.

* **Scope**: [`Any file`](#scopes). Claude Code honors `"gateway"` only from a managed source on the machine: `managed-settings.json`, the macOS plist or Windows HKLM registry, or a policy helper. It treats `"gateway"` as unset in user, project, local, HKCU, and server-managed settings, the same rule as [`forceLoginGatewayUrl`](#forcelogingatewayurl).
* **Type**: string, one of:
  * `"claudeai"`: only claude.ai accounts can log in
  * `"console"`: only Claude Console accounts can log in
  * `"gateway"`: Claude Code sends people to a cloud gateway instead of a first-party login
* **Default**: unset, so people pick a login method

```json settings.json theme={null}
{
  "forceLoginMethod": "claudeai"
}
```

Every first-party login path applies the restriction, including the [VS Code extension](/docs/en/vs-code), the Agent SDK, `claude setup-token`, and `/install-github-app`, except the terminal's interactive login screen, reached by `/login` or first-run onboarding, which pre-selects the method without enforcing it. Before v2.1.212, only terminal logins applied it. See [Restrict login to your organization](/docs/en/authentication#restrict-login-to-your-organization) for how each login path, environment credentials, and third-party providers are handled.

When a managed source on the machine sets `"gateway"`, Claude Code doesn't use a leftover login, API key, or `apiKeyHelper` credential. See [Administrator policy requires a Cloud gateway sign-in](/docs/en/errors#administrator-policy-requires-a-cloud-gateway-sign-in) for the message each one produces. If you select a cloud provider through `CLAUDE_CODE_USE_BEDROCK` or a similar environment variable, the session doesn't need the gateway sign-in. Before v2.1.261, Claude Code used a leftover login on these machines.
