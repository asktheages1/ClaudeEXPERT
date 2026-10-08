[Part 2/3 of https://code.claude.com/docs/en/cloud-environments.md, fetched 2026-10-08]

### Access levels

The **Network access** field in the [environment dialog](#configure-your-environment) takes one of four levels:

| Level | Outbound connections |
| :- | :- |
| **None** | No outbound network access through the session's network |
| **Trusted** | [Allowlisted domains](#default-allowed-domains) only: package registries, GitHub, cloud SDKs |
| **Full** | Any domain |
| **Custom** | Your own allowlist, optionally including the defaults |

Whichever level you pick, sessions can still reach these, because each one takes a path that doesn't go through the session's network allowlist:

* GitHub, through its [separate proxy](#github-proxy)
* [MCP connectors](#network-access) you enable, whose traffic travels through Anthropic's servers
* The hosts you listed on the environment's [network secrets](#add-network-secrets), except the [hosts that never get the secret](#requests-that-never-get-the-credential)
* The Anthropic API, for Claude Code's own requests, even at **None**, as noted under [Security and isolation](/docs/en/claude-code-on-the-web#security-and-isolation)

### Allow specific domains

To allow domains that aren't in the Trusted list, select **Custom** in the environment's network access settings, then list one domain per line in the **Allowed domains** field. This example allows three hosts an internal project might need.

```text theme={null}
api.example.com
*.internal.example.com
registry.example.com
```

Sessions in this environment can now reach `api.example.com`, any subdomain of `internal.example.com`, and `registry.example.com`, and no other domains through the session's network. [GitHub traffic](#github-proxy), [MCP connector traffic](#network-access), and requests to the hosts of the environment's [network secrets](#add-network-secrets), other than the [hosts that never get the secret](#requests-that-never-get-the-credential), don't go through this allowlist. A leading `*.` matches every subdomain. To keep the [Trusted domains](#default-allowed-domains) too, check **Also include default list of common package managers**; leave it unchecked to allow only what you list.

If your organization uses [artifacts](/docs/en/artifacts#availability), you don't need `*.frame.claudeusercontent.com` in the list for sessions to read them. When the list leaves that host out, Claude Code reads artifact content through the session's connection to Anthropic instead. Keep the host in an allowlist in two situations:

* **Sessions in this environment open another organization's public artifacts**: Claude Code fetches those from the host directly, so add it to this list.
* **You're configuring the local CLI or a self-hosted runner**: keep the host in that allowlist. See [network access requirements](/docs/en/network-config#network-access-requirements) and the self-hosted [network requirements](/docs/en/self-hosted-environments-deploy#network-requirements).

Each environment has its own allowed-domains list; there's no organization-level allowlist that admins can push to every member's environments. No [server-managed setting](/docs/en/server-managed-settings) adds domains to an environment's network allowlist either. To give a team one standard list, an Owner can create an [organization-shared environment](#organization-shared-environments) with **Custom** network access and that list.

### GitHub proxy

In Anthropic-hosted environments, all GitHub operations go through a dedicated proxy that keeps your real GitHub credentials outside the session's VM, independent of the environment's [access level](#access-levels). Sessions in a self-hosted environment authenticate git operations with credentials your deployment provides; [Configure git](/docs/en/self-hosted-environments-deploy#configure-git) covers the options, including per-session minted credentials and an opt-in to this same proxy. The proxy provides:

* **Git credentials**: the git client inside the VM uses a scoped credential, which the proxy verifies and swaps for your actual GitHub token.
* **API requests**: requests from the built-in GitHub tools, and from `gh` under the [`proxy-injected` placeholder](#work-with-github-issues-and-pull-requests), go out with your real credentials substituted.
* **Push restrictions**: the proxy rejects branch deletions and pushes of anything other than a branch, such as a tag. It doesn't limit which branches a push can update. To do that, use branch protection rules or rulesets on GitHub.
* **Repository scope**: the proxy serves GitHub API requests for the repositories attached to the session. An API request for another repository gets a 403 whose message starts with `GitHub access to` and contains `is not enabled for this session`.
* **GraphQL restrictions**: the proxy rejects requests to GitHub's GraphQL endpoint with a 403 whose message starts with `GitHub GraphQL is not available from Claude Code sessions` and names the REST fallback, `gh api repos/{owner}/{repo}/...`. `gh` subcommands that use GraphQL, such as `gh pr` and `gh issue`, get the same 403. The restriction applies to every request through the proxy regardless of the credentials you supply, so a `GH_TOKEN` you set gets the same 403. Claude can't reach GitHub APIs that exist only in GraphQL, such as Projects v2, through the proxy.

Committed files from public repositories arrive through `raw.githubusercontent.com`, which the [security proxy](#security-proxy) handles instead. That domain is in the default [Trusted list](#default-allowed-domains), so those files stay reachable unless the environment's [access level](#access-levels) excludes it.

### Security proxy

Cloud sessions in Anthropic-hosted environments run behind an HTTP/HTTPS network proxy for security and abuse prevention purposes; in a [self-hosted environment](/docs/en/self-hosted-environments-deploy#default-deny-egress), outbound traffic leaves through your own network boundary instead. All outbound internet traffic from an Anthropic-hosted session passes through this proxy, which provides:

* Protection against malicious requests
* Rate limiting and abuse prevention

## What's available in cloud sessions

In Anthropic-hosted environments, each session gets a fresh virtual machine (VM) running Ubuntu 24.04 on x86\_64, regardless of your own operating system and CPU architecture, with your repository cloned and common toolchains pre-installed. When a dependency provides precompiled binaries, such as Ruby gems with native extensions or prebuilt Python wheels, use its x86\_64 Linux build to match the VM. This section covers the Anthropic-hosted defaults, the built-in GitHub tools, how to [run tests and services](#run-tests-start-services-and-add-packages), the [resource limits](#resource-limits) each VM gets, and the [time limits](#time-limits) on long-running work.

<Note>
  Sessions your organization routes to a [self-hosted environment](/docs/en/self-hosted-environments) run on your own runners instead, with the tools your runner image provides.
</Note>

### What carries over from your setup

Cloud sessions start from a fresh clone of your repository. Anything you commit to the repo is available. Anything you've installed or configured only on your own machine isn't available in the session. Your organization's policy arrives separately through [server-managed settings](/docs/en/server-managed-settings).

| | Available in cloud sessions | Why |
| :- | :- | :- |
| Your repo's `CLAUDE.md` | Yes | Part of the clone |
| Your repo's `.claude/settings.json` hooks and permission rules | Yes, in a session with one repository | Part of the clone. A session with several repositories, including a [project](/docs/en/claude-projects#what-threads-pick-up-from-your-repositories) thread, starts above the clones and doesn't read them |
| Your repo's `.mcp.json` MCP servers | Yes, in a session with one repository | Part of the clone, found from the session's working directory |
| Your repo's `.claude/rules/` | Yes | Part of the clone |
| Your repo's `.claude/skills/`, `.claude/agents/`, `.claude/commands/` | Yes | Part of the clone |
| Plugins and marketplaces declared in your repo's `.claude/settings.json` | No | A cloud session doesn't install the plugins a repository turns on under [`enabledPlugins`](/docs/en/settings-reference#enabledplugins), including ones from the marketplaces it lists under [`extraKnownMarketplaces`](/docs/en/settings-reference#extraknownmarketplaces) |
| Your organization's [server-managed settings](/docs/en/server-managed-settings) | Yes, except in [Claude Tag](https://claude.com/docs/claude-tag/overview) sessions | Fetched from Anthropic's servers when the session starts. See [Surface coverage](/docs/en/model-config#surface-coverage) for how `availableModels` is enforced in cloud sessions. Settings deployed to your device through MDM or managed settings files don't apply, because the session runs on an Anthropic-managed VM; in a [self-hosted environment](/docs/en/self-hosted-environments), sessions also read the managed settings file in the runner image, per [how Claude Code combines managed sources](/docs/en/managed-settings#how-claude-code-combines-managed-sources) |
| Your user `~/.claude/CLAUDE.md` | No | Lives on your machine, not in the repo. See [Add personal preferences without committing to the repo](#add-personal-preferences-without-committing-to-the-repo) |
| Your user `~/.claude/skills/`, `~/.claude/agents/`, `~/.claude/commands/` | No | Live on your machine, not in the repo. Commit them to the repo's `.claude/` directory instead. Cloud sessions automatically load skills you enable on claude.ai |
| Plugins enabled only in your user settings | No | User-scoped `enabledPlugins` lives in `~/.claude/settings.json` on your machine |
| MCP servers you added with `claude mcp add` at the default local scope or the user scope | No | Those write to `~/.claude.json` on your machine, not the repo. Add the server with `claude mcp add --scope project`, which writes the repo's [`.mcp.json`](/docs/en/mcp#project-scope), and commit that file. A session with one repository loads it |
| Transport variables in your repo's `.claude/settings.json` `env` block, such as `NODE_EXTRA_CA_CERTS` and the [mTLS client certificate variables](/docs/en/network-config#mtls-authentication) | No | The hosting environment manages the session's API connection, so Claude Code ignores these keys and notes each ignored key in the session's debug log |
| API keys and tokens for services Claude calls | On Pro and Max plans, as [network secrets](#add-network-secrets) | You add the key once on the environment and the agent proxy attaches it to requests for the hosts you list. A key the agent proxy [can't attach](#requests-that-never-get-the-credential), or any key on a Team or Enterprise plan, stays in an environment variable |
| Interactive auth like AWS SSO | No | Not supported. SSO requires browser-based login that can't run in a cloud session |

To make your own configuration available in cloud sessions, commit it to the repo.

Anyone who uses the environment can read its environment variables and setup script. The dialog's note under **Environment variables** says so and warns against putting secrets there. On Pro and Max plans, store a key the agent proxy can attach as a [network secret](#add-network-secrets) instead.

#### Add personal preferences without committing to the repo

In an Anthropic-hosted environment, add a [setup script](#setup-scripts) that writes `~/.claude/CLAUDE.md` for preferences you'd rather not put in a shared repository. Claude Code loads that file as [user instructions](/docs/en/memory#choose-where-to-put-claude-md-files) in the session. This example sets a commit-message preference:

```bash theme={null}
#!/bin/bash
mkdir -p ~/.claude
cat > ~/.claude/CLAUDE.md <<'EOF'
Use conventional commit messages.
EOF
```

Put the script on one of your own environments rather than a [shared one](#organization-shared-environments).

Run `/context` in your next cloud session and confirm `/root/.claude/CLAUDE.md` appears under **Memory files**.

### Installed tools

Cloud sessions come with common language runtimes, build tools, and databases pre-installed. The table below summarizes what's included by category.

| Category | Included |
| :- | :- |
| **Python** | Python 3.x with pip, poetry, uv, black, mypy, pytest, ruff |
| **Node.js** | 20, 21, and 22, with npm, yarn, pnpm, bun¹, eslint, prettier, chromedriver |
| **Ruby** | 3.1, 3.2, 3.3 with gem, bundler, rbenv |
| **PHP** | 8.3 with Composer |
| **Java** | OpenJDK 21 with Maven and Gradle |
| **Go** | Go with module support |
| **Rust** | rustc and cargo |
| **C/C++** | GCC, Clang, cmake, ninja, conan |
| **Docker** | docker, dockerd, docker compose |
| **Databases** | PostgreSQL 16, Redis 7.0 |
| **Utilities** | git, gh, jq, yq, ripgrep, tmux, vim, nano |

¹ Bun is installed but has known [proxy compatibility issues](#install-dependencies-with-a-sessionstart-hook) for package fetching.

To get the versions of most of the tools in this table, ask Claude to run `check-tools` in a cloud session. It's a shell command installed on the session VM, not a command you type with `/`; you ask Claude because [Claude runs all VM commands for you](#run-tests-start-services-and-add-packages). For a tool it doesn't report, such as Ruby, PHP, bun, PostgreSQL, or Redis, ask Claude to run the tool's own version command, for example `psql --version`.

Node.js versions are installed at `/opt/node20`, `/opt/node21`, and `/opt/node22`, with 22 on `PATH` by default. To work with a different version, ask Claude to prepend that version's `bin` directory, such as `/opt/node20/bin`, to `PATH`.

Toolchains outside this list, such as the .NET SDK, aren't pre-installed even when their package registries are on the [default allowlist](#default-allowed-domains). Install them with a [setup script](#setup-scripts).

### Work with GitHub issues and pull requests

Cloud sessions include built-in GitHub tools that let Claude read issues, list pull requests, fetch diffs, and post comments without any setup. These tools authenticate through the [GitHub proxy](#github-proxy) using whichever method you configured under [GitHub authentication options](/docs/en/claude-code-on-the-web#github-authentication-options), so your token never enters the container.

You can set `GH_TOKEN` or `GITHUB_TOKEN` yourself in [environment settings](#set-environment-variables), or leave both unset and let the [GitHub proxy](#github-proxy) authenticate for you:

* If you set a token, it passes through to the container unchanged, so your scripts and GitHub's [`gh` CLI](https://cli.github.com) use it directly.
* If you set neither and the [GitHub proxy](#github-proxy) is handling authentication for your session, both variables read as the placeholder string `proxy-injected` in the commands Claude runs, and the proxy substitutes your real credentials on outbound GitHub requests. `gh api` calls for attached repositories work without a token of your own, but a script that reads `GITHUB_TOKEN` directly gets the placeholder, not a usable token.

A token you set is an ordinary environment variable, so anyone who uses the environment can read it; the proxy path keeps the credential out of the environment configuration and the session VM.

To check which case applies to your session, ask Claude to run `echo $GH_TOKEN`.

GitHub's [`gh` CLI](https://cli.github.com) is pre-installed. If you need a GitHub operation the built-in tools don't cover, ask Claude to call the REST API with `gh api`. `gh` subcommands that use the REST API, such as `gh workflow list`, work too. The proxy [rejects subcommands that use GraphQL](#github-proxy), such as `gh pr` and `gh issue`. `gh` reads `GH_TOKEN` automatically, so you don't need to run `gh auth login`.

### Link output back to the session

Each cloud session has a transcript URL on claude.ai, and the session can read its own ID from the `CLAUDE_CODE_REMOTE_SESSION_ID` environment variable. Use this to put a traceable link in PR bodies, commit messages, Slack posts, or generated reports so a reviewer can open the run that produced them.

Commits that Claude creates in a cloud session include a `Claude-Session: <url>` git trailer, and PR bodies include the session URL on its own line. To omit the trailer and the PR-body link, set [`attribution.sessionUrl`](/docs/en/settings-reference#attribution-sessionurl) to `false`.

To include the session link in something other than a commit or PR, such as a Slack message Claude posts or a report file it writes, have Claude run the following command and use its output. The command converts the `cse_` prefix in the environment variable's value to the `session_` prefix that the transcript URL expects:

```bash theme={null}
echo "https://claude.ai/code/${CLAUDE_CODE_REMOTE_SESSION_ID/#cse_/session_}"
```

### Run tests, start services, and add packages

You don't get a shell into the session VM. Claude runs every command for you, so phrase the tasks in this section as requests in your prompt.

#### Run tests

Claude runs tests as part of working on a task. Ask for it in your prompt, like "fix the failing tests in `tests/`" or "run pytest after each change." Test runners that come with the [pre-installed toolchains](#installed-tools), like pytest and cargo test, work without additional setup. A runner your project declares as a dependency, like jest, installs with your dependencies.

#### Start services

PostgreSQL and Redis are pre-installed but not running by default. Ask Claude to start whichever you need; the commands it runs are:

```bash theme={null}
service postgresql start
```

```bash theme={null}
service redis-server start
```

Docker is available for running containerized services. Ask Claude to run `docker compose up` to start your project's services. Network access to pull images follows your environment's [access level](#access-levels), and the [Trusted defaults](#default-allowed-domains) include Docker Hub and other common registries.

If your images are large or slow to pull, add `docker compose pull` or `docker compose build` to your [setup script](#setup-scripts). The [environment cache](#environment-caching) keeps the pulled images, so each new session has them on disk. The cache stores files only, not running processes, so Claude still starts the containers each session.

#### Add packages

To add packages that aren't pre-installed, use a [setup script](#setup-scripts). The [environment cache](#environment-caching) keeps what the script installs, so packages you install there are available at the start of every session without reinstalling each time. You can also ask Claude to install packages mid-session, but those installs don't carry over to other sessions.

### Resource limits

Cloud sessions in Anthropic-hosted environments run with approximate resource ceilings that may change over time:

* 4 vCPUs
* 16 GB of RAM
* 30 GB of disk

The VM may stop tasks that need significantly more memory, such as large build jobs or memory-intensive tests. For workloads beyond these limits, use [Remote Control](/docs/en/remote-control) to run Claude Code on your own hardware, or run cloud sessions in a [self-hosted environment](/docs/en/self-hosted-environments) on compute your organization operates.

### Time limits

In Anthropic-hosted environments, these time limits apply to long-running work in a cloud session, such as a build, an install, or a test run. Each entry links to the section that defines the limit.

* **Commands Claude runs**: a cloud environment doesn't set its own command timeout, so the Bash tool's defaults apply. Claude waits 2 minutes for a foreground command by default and can ask for up to 10 minutes.

  When a command reaches its [timeout](/docs/en/tools-reference#timeout-and-output-limits), Claude Code [moves it to the background](/docs/en/tools-reference#foreground-commands-that-move-to-the-background) instead of stopping it, unless the command starts with `sleep`. A command moved this way can keep running for up to 30 more minutes before Claude Code stops it at its [background time limit](/docs/en/tools-reference#time-limit-for-background-commands). Setting `BASH_DEFAULT_TIMEOUT_MS` above `1800000` milliseconds lengthens that limit as well as the foreground default.
* **SessionStart hooks**: Claude Code cancels a `command` hook after 600 seconds unless you set [`timeout`](/docs/en/hooks#common-fields), in seconds, on the hook entry. Claude Code doesn't enforce the timeout on a hook you run with [`async: true`](/docs/en/hooks#run-hooks-in-the-background).
* **Setup script**: a script that takes longer than roughly five minutes isn't cached. [Script requirements](#script-requirements) covers how to stay under that.
* **Idle sessions**: after a few minutes without activity, a session's VM pauses with its files saved, and a paused VM can later be reclaimed. [Set environment variables](#set-environment-variables) describes what a session picks up in each case, and [Environment expired](/docs/en/claude-code-on-the-web#environment-expired) covers how to reopen a session whose VM was reclaimed.

To raise the command timeouts for an environment's sessions, add [`BASH_DEFAULT_TIMEOUT_MS` and `BASH_MAX_TIMEOUT_MS`](/docs/en/env-vars#variables) to its [environment variables](#set-environment-variables). Both take milliseconds. For example, `BASH_DEFAULT_TIMEOUT_MS=600000` makes 10 minutes the default.

## Setup scripts

A setup script is a Bash script that runs when a new cloud session starts, before Claude Code launches. Use setup scripts to install dependencies, configure tools, or fetch anything the session needs that isn't pre-installed.

Scripts run as root on Ubuntu 24.04, so `apt install` and most language package managers work.

To add a setup script, open the environment settings dialog and enter your script in the **Setup script** field.

This example installs [ShellCheck](https://www.shellcheck.net/), which isn't pre-installed.

```bash theme={null}
#!/bin/bash
apt update && apt install -y shellcheck
```
