[Part 1/3 of https://code.claude.com/docs/en/cloud-environments.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Configure cloud environments

> Configure cloud environments for Claude Code cloud sessions: network access levels, environment variables, setup scripts, and environment caching.

<Note>
  Cloud environments apply to [cloud sessions](/docs/en/claude-code-on-the-web), which are available on Pro, Max, and Team plans, and for Enterprise users with [premium seats or Chat + Claude Code seats](https://support.claude.com/en/articles/11845131-use-claude-code-with-your-team-or-enterprise-plan).
</Note>

Each [cloud session](/docs/en/claude-code-on-the-web) runs in a cloud environment. You can configure an environment to allow or deny [network access](#access-levels), [set environment variables](#set-environment-variables) for the session, on Pro and Max plans store [network secrets](#add-network-secrets) that sessions use without seeing them, and run a [setup script](#setup-scripts) before Claude starts working.

The same environments apply wherever you start a cloud session: the [Desktop app](/docs/en/desktop), the [Claude mobile app](/docs/en/mobile), your browser at [claude.ai/code](https://claude.ai/code), the terminal with [`claude --cloud`](/docs/en/claude-code-on-the-web#from-terminal-to-cloud), [routines](/docs/en/routines), and [Claude Tag](https://claude.com/docs/claude-tag/overview). Each of these surfaces can also route to a [self-hosted environment](/docs/en/self-hosted-environments). [Availability and limitations](/docs/en/self-hosted-environments#availability-and-limitations) covers what Claude can't use yet when a Claude Tag session runs in one.

<Info>
  [Remote Control](/docs/en/remote-control) sessions connect the web and mobile interfaces to a session on your own machine, which uses your machine's network and files, not a cloud environment. Claude Tag channel sessions use organization-level environments only, either [shared environments](#organization-shared-environments) or [self-hosted environments](/docs/en/self-hosted-environments).
</Info>

## The Default environment

If you don't have an environment yet, onboarding sets up the **Default** environment. How depends on where you onboard:

* **CLI flows such as `/web-setup`**: create **Default** for you
* **Web onboarding on Pro and Max**: creates **Default** for you
* **Web onboarding on Team and Enterprise**: shows a **Create your first cloud environment** form unless an Owner has turned on [Quick setup](/docs/en/claude-code-on-the-web#quick-setup-for-team-and-enterprise); keep the form's defaults and click **Create & finish** to get the same **Default** environment

**Default** carries no configuration of its own:

* [**Trusted** network access](#access-levels): sessions reach package registries and other [allowlisted domains](#default-allowed-domains), and nothing else through the session's network.
* No other configuration: **Default** defines no environment variables or setup script, so sessions start with just the [pre-installed tools](#installed-tools).

With only **Default** available, every session runs in it. When you have more than one environment, sessions choose one per surface:

* In the Desktop app, the mobile app, and at claude.ai/code, sessions you start yourself use the environment shown in the [selector](#configure-your-environment). An [organization default](#organization-shared-environments) set by an Owner fills the selection when you haven't picked one. Threads in a [project](/docs/en/claude-projects#project-settings-reference) use the environment set in the project's settings instead.
* From the CLI, Claude Code uses your [`/remote-env` pick](#select-an-environment-from-the-cli), or falls back to the Anthropic-hosted environment when your list has one, and otherwise to the first environment in your list that isn't a bridge environment, an entry [Remote Control](/docs/en/remote-control) registers to represent your own machine rather than a cloud environment. For a [self-hosted environment](/docs/en/self-hosted-environments), passing `--environment <environment-id>` with its `ccpool_` ID [when you dispatch a session](/docs/en/self-hosted-environments-testing#run-the-test-loop) overrides the `/remote-env` pick and the fallback for that invocation. Claude Code rejects Anthropic-hosted `env_` IDs passed to the flag, so use `/remote-env` to target those. The flag requires Claude Code v2.1.224 or later.

Configure an environment when the default isn't enough: when Claude needs to reach domains outside the [default allowlist](#default-allowed-domains), needs environment variables set for its sessions, or needs dependencies installed before it starts working.

## Configure your environment

Create, edit, and archive environments from the environment selector, which you reach at [claude.ai/code](https://claude.ai/code) after [web onboarding](/docs/en/web-quickstart), or from the prompt box in the [Desktop app](/docs/en/desktop#cloud-sessions). Environments you create are personal to your account; [shared environments](#organization-shared-environments) created by an Owner appear in the same selector. See [Installed tools](#installed-tools) for what's available without any configuration.

<Steps>
  <Step title="Open the environment selector">
    On [claude.ai/code](https://claude.ai/code), select the cloud icon showing the current environment's name, in the row above the message box. There's no settings page or direct URL for the selector.

    <Frame>
      <img src="https://mintcdn.com/claude-code/ZFId6l95856c5LSw/images/cloud-environment-selector.png?fit=max&auto=format&n=ZFId6l95856c5LSw&q=85&s=cc2813a5664519eaf5a89d793ce5af26" alt="The environment selector open above the message box at claude.ai/code. The cloud button showing the environment name Default sits in the row above the message box. The open menu lists a Local row with Download and Desktop only labels, a Cloud section where the Default environment is selected with a checkmark and shows a settings gear icon on hover, an Add cloud environment option, and a Remote Control section with setup instructions." width="1672" height="682" data-path="images/cloud-environment-selector.png" />
    </Frame>
  </Step>

  <Step title="Add or edit an environment">
    Select **Cloud** to list your environments. Then select **Add cloud environment**, or hover over an existing environment and select the settings icon that appears on the right.

    The dialog includes the name, network access level, environment variables, and setup script. When you edit an existing cloud environment on a Pro or Max plan, the dialog also includes [network secrets](#add-network-secrets).

    <Frame>
      <img src="https://mintcdn.com/claude-code/ZFId6l95856c5LSw/images/cloud-environment-dialog.png?fit=max&auto=format&n=ZFId6l95856c5LSw&q=85&s=30d4478b31d1f879f7ee287ddab32505" alt="The New cloud environment dialog. A Name field with the placeholder Default, a Network access selector set to Trusted with links to the network policy and access levels, an Environment variables box showing .env-format placeholder text with a note that values are visible to anyone using the environment, a Setup script box described as a Bash script that runs when a new session starts before Claude Code launches, and Cancel and Create environment buttons." width="874" height="1372" data-path="images/cloud-environment-dialog.png" />
    </Frame>
  </Step>
</Steps>

### Set environment variables

Environment variables use `.env` format, one `KEY=value` pair per line. Plain values don't need quotes, and if you quote a value with a matching pair, the quotes don't become part of the value. Quote a value that spans multiple lines or contains a `#`: in an unquoted value, `#` starts a comment and the rest of the line is dropped.

The following example defines three variables.

```text theme={null}
NODE_ENV=development
LOG_LEVEL=debug
DATABASE_URL=postgres://localhost:5432/myapp
```

A session reads the environment's values into ordinary environment variables that any command Claude runs can read, except `OTEL_*` variables. Claude Code uses those for its own [telemetry export](/docs/en/monitoring-usage#telemetry-from-cloud-sessions-and-claude-tag) and doesn't pass them to the commands it runs.

In an Anthropic-hosted environment, a session reads the environment's values when you create it and again each time Claude Code starts in the session's VM afterward, which happens in two cases:

* **The VM is restored after being idle**: after a few minutes without activity, a session's VM pauses with its files saved. Your next message restores the same VM and starts Claude Code again.
* **The VM was reclaimed and is rebuilt**: if the paused VM has since been [reclaimed](/docs/en/claude-code-on-the-web#environment-expired), reopening the session provisions a fresh VM.

After you edit, add, or remove a variable, an existing session in an Anthropic-hosted environment keeps the values it last read until its VM is next restored or rebuilt, and uses your change from then on. Its VM pauses on its own once the session is idle, and you can't pause it yourself. To use a new value right away, ask Claude to set it on the command it runs, for example `LOG_LEVEL=trace npm test`, or start a new session.

A cloud session also sets some variables itself when it starts. For [`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`](/docs/en/claude-code-on-the-web#manage-context), the value the session sets overrides one you add here, so adding that key here has no effect.

Anyone who uses the environment can read the values. On Pro and Max plans, use a [network secret](#add-network-secrets) instead for a key the agent proxy can attach to a request. The [requests that never get a secret](#requests-that-never-get-the-credential) are listed there.

<span id="add-api-credentials" />

<h3 id="add-network-secrets">
  Add network secrets
</h3>

A network secret is an API key or token you store on a cloud environment so Claude can call that API from any session in the environment without seeing the key. Anthropic's agent proxy adds the key to requests for the hosts you list, after each request leaves the session's VM, so the key itself stays outside the VM.

Network secrets are available on Pro and Max plans. They aren't available on Team or Enterprise plans yet, so the **Network secrets** section doesn't appear in the environment dialog on those plans.

#### Requirements

These requirements decide whether you can add a secret and whether the agent proxy can use it once added:

* **Role**: an organization admin role in your claude.ai organization
  * On Team and Enterprise, Owners hold it and Admins don't
  * On Pro and Max, you hold it in your own organization
* **Environment type**: an Anthropic-hosted cloud environment that already exists. A [self-hosted environment](/docs/en/self-hosted-environments) doesn't have network secrets
* **API reachability**: the API accepts connections from the internet, because requests leave from Anthropic's network
* **Encryption keys**: if your organization uses customer-managed encryption keys, you can't save network secrets

<h4 id="add-a-credential">
  Add a secret
</h4>

You add secrets one at a time, and you can't edit a secret after you add it. To change a secret's hosts or value, delete it and add it again.

<Steps>
  <Step title="Open the environment's network secrets">
    [Open the environment for editing](#configure-your-environment) at [claude.ai/code](https://claude.ai/code). In the **Edit environment** dialog, find the **Network secrets** section. You see the secrets already on the environment, each with the hosts it applies to.
  </Step>

  <Step title="Add the secret">
    Select **Add secret** and fill in the form. Keep the default **Credential type**, **Bearer**, for an API key that travels in a request header, and fill in these fields:

    * **Name**: a label for the secret, such as `Internal billing API`
    * **Allowed websites**: the API's hosts, such as `api.example.com`. A leading `*.` matches every subdomain
    * **Custom headers**: one row for the header that carries the key. The row starts with `Authorization` as the header's **Name** and `Bearer` as its **Prefix**; paste the key itself as the **Value**. For a header like `X-Api-Key` that takes the bare value, change the name and clear the prefix

    For an API that authenticates another way, pick a different **Credential type**. The list is the same one [Claude Tag](https://claude.com/docs/claude-tag/overview), the Slack integration for Team and Enterprise plans, offers for [connections](https://claude.com/docs/claude-tag/admins/add-connections).
  </Step>

  <Step title="Save the secret">
    Select **Connect**. The secret appears in the list with its hosts, saved without the dialog's **Save changes** button. You can't view the value again after saving.
  </Step>
</Steps>

To confirm the secret works, start a session in the environment and ask Claude to call the API, for example with `curl`. The API answers as if the key were in the request, and the key doesn't appear in the session's environment variables or in any file. If the list marks a secret **Not sent** instead, the note under it says why and what to do. Two secrets whose hosts overlap without matching exactly get no marker, and the agent proxy sends only one of them.

<h4 id="which-requests-get-the-credential">
  Which requests get the secret
</h4>

The agent proxy attaches a secret to a request when the request's host matches one you listed on that secret. Sessions can reach those hosts even when the environment's [network access level](#access-levels) wouldn't otherwise allow them, except the [hosts that never get the secret](#requests-that-never-get-the-credential). The secret applies in every session that runs in the environment, whoever started it, until you delete it.

<h4 id="requests-that-never-get-the-credential">
  Requests that never get the secret
</h4>

The agent proxy never attaches a secret you add to these requests:

* **GitHub**: the [GitHub proxy](#github-proxy) authenticates requests to GitHub instead, so you don't need a network secret for it
* **The Anthropic API and public package registries**: `api.anthropic.com`, `registry.npmjs.org`, `jsr.io`, `npm.jsr.io`, `pypi.org`, `files.pythonhosted.org`, `index.crates.io`, and `proxy.golang.org`
* **Setup script requests**: Claude Code connects to the agent proxy when it launches, after the [setup script](#setup-scripts) has run
* **Claude Code's telemetry export**: Claude Code sends its [telemetry export](/docs/en/monitoring-usage#telemetry-from-cloud-sessions-and-claude-tag) itself rather than through a command it runs, and that request doesn't go through the agent proxy

### Select an environment from the CLI

Run `/remote-env` in your terminal to choose the default environment for cloud sessions you create from the CLI, such as [`claude --cloud`](/docs/en/claude-code-on-the-web#from-terminal-to-cloud). The command opens a picker of your existing environments and saves your choice to the `remote.defaultEnvironmentId` key in your [user settings](/docs/en/settings#where-settings-live), so it applies in every project on your machine until you change it, unless the same key is set at a higher-precedence [settings layer](/docs/en/settings#settings-precedence), such as a repo's project settings.

A [self-hosted environment](/docs/en/self-hosted-environments) ID, which has the form `ccpool_...`, follows a stricter source rule. See [`remote.defaultEnvironmentId`](/docs/en/settings-reference#remote-defaultenvironmentid) for the settings layers Claude Code honors it from.

`/remote-env` only sets the default: it doesn't start a session, and it can't add or edit environments. Manage them from the [environment selector](#configure-your-environment).

### Archive an environment

To archive one of your own environments, open it for editing and select **Archive**. An Owner archives a [shared environment](#organization-shared-environments) from the **Cloud environments** page in admin settings. You can't delete an environment, only archive it.

Archiving affects new sessions, not running ones:

* Sessions already running in the environment continue to work.
* The environment disappears from the selector and from `/remote-env`, so you can't pick it for new sessions.
* Network secrets on the environment stay attached in its running sessions. Delete any you no longer want before you archive.
* No new session can start in an archived environment, on any surface. If the environment was your saved [CLI default](#select-an-environment-from-the-cli), Claude Code starts CLI cloud sessions in the Anthropic-hosted environment when your list has one, and otherwise in the first environment in your list that isn't a [Remote Control bridge environment](#the-default-environment). Anything configured with the environment explicitly, such as a [routine](/docs/en/routines#environments-and-network-access), can't start new sessions in it. Point it at another environment.

### Organization-shared environments

On Team and Enterprise plans, an Owner can create cloud environments that are shared with every member of the organization. The same role manages everything else on the **Cloud environments** admin page, including [self-hosted environments](/docs/en/self-hosted-environments); the Admin role can't open the page. The full list of roles that can open it is the one for [managing server-managed settings](/docs/en/server-managed-settings#access-control).

Shared environments appear in each member's [environment selector](#configure-your-environment) under an **Organization** heading, after the member's own environments under **Personal**, so a team can standardize on one configuration instead of each member recreating it. Selecting a shared environment's settings icon there opens a read-only summary of its configuration for every member, Owners included.

An Owner makes an environment available to the organization in one of two ways:

* **Create a shared environment**: use the **Cloud environments** page in [admin settings](https://claude.ai/admin-settings), which is also where Owners edit and archive shared environments. Each one has a name, a [network access level](#access-levels), [environment variables](#set-environment-variables) in `.env` format, and a [setup script](#setup-scripts).
* **Share a personal environment**: open one of your own environments for editing in the environment selector, then share it from the **Who can use it** row. The environment keeps its ID, so sessions and routines that already use it aren't affected, and every member can then see it and start sessions in it.

Owners choose the organization's [default environment](#the-default-environment) separately, at [claude.ai/admin-settings/claude-code](https://claude.ai/admin-settings/claude-code).

Every member's sessions in a shared environment read its variables, so don't include secrets in them. [Network secrets](#add-network-secrets), which give sessions a key they can't read, aren't available on Team or Enterprise plans yet.

### Set the environment a Claude Tag channel uses

In [Claude Tag](https://claude.com/docs/claude-tag/overview) channels, Claude works as your organization's shared identity, not as any member, so channel sessions use organization-level environments only, either shared environments or [self-hosted environments](/docs/en/self-hosted-environments). To give a channel a toolchain that isn't [pre-installed](#installed-tools), such as .NET, an Owner can create a [shared environment](#organization-shared-environments) from the **Cloud environments** admin page with a [setup script](#setup-scripts) that installs it. Point the channel at an environment in one of two ways:

* Set a shared or self-hosted environment as the organization's [default environment](#the-default-environment) at [claude.ai/admin-settings/claude-code](https://claude.ai/admin-settings/claude-code).
* [Pin one to a channel](https://claude.com/docs/claude-tag/admins/troubleshooting#channel-sessions-use-the-wrong-environment-or-can%E2%80%99t-find-one) in the Claude Tag admin settings.

## Network access

Each environment sets one network access level, which controls the outbound connections its sessions can make. The default level, **Trusted**, allows package registries and other [allowlisted domains](#default-allowed-domains); **Custom** takes your own domain list.

To change an environment's network access, [open it for editing](#configure-your-environment) and use the **Network access** selector in the dialog. A [shared environment](#organization-shared-environments) opens read-only there, so an Owner changes its network access from the **Cloud environments** page in [admin settings](https://claude.ai/admin-settings) instead. The cloud icon that opens the selector appears on the app surfaces listed under [The Default environment](#the-default-environment) and in the [routine editor](/docs/en/routines#environments-and-network-access); personal environments don't have a separate page in your claude.ai account settings.

When you change an Anthropic-hosted environment's network access, its existing sessions follow the new setting within about a minute, for requests that go through the session's [network allowlist](#access-levels). You don't need to start a new session.

<Note>
  MCP connectors you enable on a session or routine work without adding their hosts to **Allowed domains**, because connector traffic travels through Anthropic's servers rather than the session's network. This relies on the same Anthropic-bound channel noted under [Security and isolation](/docs/en/claude-code-on-the-web#security-and-isolation). Turn off any connector you don't need to limit which tools Claude can reach.
</Note>
