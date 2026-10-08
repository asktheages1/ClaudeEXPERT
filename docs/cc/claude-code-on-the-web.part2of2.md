[Part 2/2 of https://code.claude.com/docs/en/claude-code-on-the-web.md, fetched 2026-10-08]

### Manage context

Cloud sessions support [built-in commands](/docs/en/commands) that produce text output. Commands that only run in the terminal interface, such as `/plugin` or `/resume`, aren't available. Commands that open a picker or panel in the terminal behave differently in cloud sessions:

* **`/model`, `/effort`, `/color`, and `/rename`**: pass the value as an argument, for example `/model sonnet`, instead of opening the terminal picker or slider. The argument forms require Claude Code v2.1.205 or later in the session's environment and follow each command's [availability notes](/docs/en/commands#all-commands).
* **`/fast`**: toggles [fast mode](/docs/en/fast-mode#use-fast-mode-in-cloud-sessions) for the session when fast mode is [available on your account](/docs/en/fast-mode#requirements). Requires Claude Code v2.1.271 or later in the session's environment.
* **`/config`**: in your browser at claude.ai/code, opens the Claude Code section of your settings instead of setting a value, and text after the command, including `key=value`, is ignored. To change a setting for a cloud session, set an [environment variable](/docs/en/cloud-environments#set-environment-variables) on the environment, or in a session with one repository, commit the key to that repository's `.claude/settings.json`. [Settings in cloud sessions](/docs/en/settings#settings-in-cloud-sessions) lists what each session reads.

For context management specifically:

| Command | Works in cloud sessions | Notes |
| :- | :- | :- |
| `/compact` | Yes | Summarizes the conversation to free up context. Accepts optional focus instructions like `/compact keep the test output` |
| `/context` | Yes | Shows what's currently in the context window |
| `/clear` | No | Start a new session from the sidebar instead |

Auto-compaction runs automatically when the context window approaches capacity. Cloud sessions set [`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`](/docs/en/env-vars) themselves, so compaction triggers partway through the [auto-compact window](/docs/en/model-config#set-the-auto-compact-window) rather than when the window fills. That value overrides one you add in your [environment variables](/docs/en/cloud-environments#set-environment-variables), so adding the variable there doesn't change when compaction triggers.

To change the auto-compact window instead, set [`CLAUDE_CODE_AUTO_COMPACT_WINDOW`](/docs/en/env-vars) in your environment variables, or run [`/autocompact`](/docs/en/commands#all-commands) with a token count in a session where the variable isn't set.

[Subagents](/docs/en/sub-agents) work the same way they do locally. Claude can spawn them with the Agent tool to offload research or parallel work into a separate context window, keeping the main conversation lighter. Subagents defined in your repo's `.claude/agents/` are picked up automatically.

[Agent teams](/docs/en/agent-teams) are off by default but can be enabled by adding `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your [environment variables](/docs/en/cloud-environments#set-environment-variables).

### Take back a queued message

If you send a message while Claude is working, the message queues until Claude reads it. To take a queued message back, click the ✕ on it. The text returns to the message box so you can edit it or send something else.

If Claude has already read the message, it stays in the conversation.

### Share sessions

To share a session, toggle its visibility according to the account types below. After that, share the session link as-is. Recipients see the latest state when they open the link, but their view doesn't update in real time.

#### Share from an Enterprise or Team account

Sharing works as follows for Enterprise and Team accounts:

* **Visibility options**: **Private** and **Team**. Team visibility makes the session visible to other members of your claude.ai organization
* **Repository access**: verification is enabled by default, based on the GitHub account connected to the recipient's account
* **Your name**: your account's display name is visible to all recipients with access
* **Slack sessions**: [Claude in Slack](/docs/en/slack) sessions are automatically shared with Team visibility

#### Share from a Max or Pro account

Sharing works as follows for Max and Pro accounts:

* **Visibility options**: **Private** and **Public**. Public visibility makes the session visible to any user logged into claude.ai
* **Repository access**: verification isn't enabled by default
* **Sensitive content**: check your session before sharing. Sessions may contain code and credentials from private GitHub repositories

To require recipients to have repository access, or to hide your name from shared sessions, go to [**Settings > Claude Code > Sharing settings**](https://claude.ai/settings/claude-code).

### Archive sessions

You can archive sessions to keep your session list organized. Archived sessions are hidden from the default session list but can be viewed by filtering for archived sessions.

To archive a session, hover over the session in the sidebar and select the archive icon.

### Delete sessions

Deleting a session permanently removes the session and its data. This action can't be undone. You can delete a session in two ways:

* **From the sidebar**: filter for archived sessions, then hover over the session you want to delete and select the delete icon
* **From the session menu**: open a session, select the dropdown next to the session title, and select **Delete**

You will be asked to confirm before a session is deleted.

## Auto-fix pull requests

Claude can watch a pull request and automatically respond to CI failures and review comments. Claude subscribes to GitHub activity on the PR, and when a check fails or a reviewer leaves a comment, Claude investigates and pushes a fix if one is clear.

<Note>
  Auto-fix requires the Claude GitHub App to be installed on your repository. If you haven't already, install it from the [GitHub App page](https://github.com/apps/claude).
</Note>

There are a few ways to turn on auto-fix depending on where the PR came from and what device you're using:

* **PRs created in a cloud session**: open the session at claude.ai/code, open the CI status bar, and select **Auto-fix**
* **From your terminal**: run [`/autofix-pr`](/docs/en/commands) while on the PR's branch. Claude Code detects the open PR with `gh`, spawns a cloud session, and turns on auto-fix in one step
* **From the mobile app**: tell Claude to auto-fix the PR, for example "watch this PR and fix any CI failures or review comments"
* **Any existing PR**: paste the PR URL into a session and tell Claude to auto-fix it

Auto-fix is a per-PR toggle. To stop monitoring, open the CI status bar in the session at claude.ai/code and clear the **Auto-fix** toggle, or tell Claude to stop watching the PR.

### How Claude responds to PR activity

When auto-fix is active, Claude receives GitHub events for the PR including new review comments and CI check failures. For each event, Claude investigates and decides how to proceed:

* **Clear fixes**: if Claude is confident in a fix and it doesn't conflict with earlier instructions, Claude makes the change, pushes it, and explains what was done in the session
* **Ambiguous requests**: if a reviewer's comment could be interpreted multiple ways or involves something architecturally significant, Claude asks you before acting
* **Duplicate or no-action events**: if an event is a duplicate or requires no change, Claude notes it in the session and moves on

GitHub does not emit a webhook when the base branch advances and creates a merge conflict, so auto-fix can't react to conflicts on its own. To resolve a conflict, open the session and ask Claude to rebase.

Claude may reply to review comment threads on GitHub as part of resolving them. These replies are posted using your GitHub account, so they appear under your username, but each reply is labeled as coming from Claude Code so reviewers know it was written by the agent and not by you directly.

<Warning>
  If your repository uses comment-triggered automation such as Atlantis, Terraform Cloud, or custom GitHub Actions that run on `issue_comment` events, be aware that Claude can reply on your behalf, which can trigger those workflows. Review your repository's automation before enabling auto-fix, and consider disabling auto-fix for repositories where a PR comment can deploy infrastructure or run privileged operations.
</Warning>

## Security and isolation

Each cloud session is separated from your machine and from other sessions through several layers:

* **Isolated virtual machines**: each session runs in an isolated, Anthropic-managed VM. Sessions your organization routes to a [self-hosted environment](/docs/en/self-hosted-environments) run on your own infrastructure instead, where isolation is your deployment's responsibility
* <span id="default-allowed-domains" />**Network access controls**: in Anthropic-hosted environments, network access is limited by default and can be disabled. See [Network access](/docs/en/cloud-environments#network-access) for the access levels, the [default allowed domains](/docs/en/cloud-environments#default-allowed-domains), and the traffic that doesn't go through the allowlist. In a self-hosted environment, you restrict session egress at your own network boundary. When running with network access disabled, Claude Code can still communicate with the Anthropic API, which may allow data to exit the VM.
* **Credential protection**: in Anthropic-hosted environments, git credentials and signing keys stay outside the sandbox, and a proxy authenticates on the session's behalf with scoped credentials. In a self-hosted environment, your deployment supplies git credentials; see [Configure git](/docs/en/self-hosted-environments-deploy#configure-git)
* **Network secrets**: in Anthropic-hosted environments on Pro and Max plans, keys you [add to a cloud environment](/docs/en/cloud-environments#add-network-secrets) stay outside the sandbox the same way, attached to matching requests after they leave the session. A self-hosted environment doesn't have network secrets, and Team and Enterprise plans don't have them yet
* **Secure analysis**: code is analyzed and modified within the session's isolated environment before creating PRs

## Troubleshooting

For runtime API errors that appear in the conversation such as `API Error: 500`, `529 Overloaded`, `429`, or `Prompt is too long`, see the [Error reference](/docs/en/errors). Those errors and their fixes are shared with the CLI and Desktop app. The sections below cover issues specific to cloud sessions.

### Session creation failed

If a new session fails to start with `Session creation failed` or stalls at provisioning, Claude Code could not allocate a VM for the session.

* Check [status.claude.com](https://status.claude.com) for cloud session incidents
* Retry after a minute, as capacity is provisioned on demand
* Confirm your GitHub connection can reach the repository by following [No repositories appear after connecting GitHub](/docs/en/web-quickstart#no-repositories-appear-after-connecting-github)

### Unable to get organization UUID

`claude --cloud` and `claude --teleport` require sign-in with a claude.ai account. If you authenticate with an API key, or your stored account details are stale, you see one of these:

* `Unable to get organization UUID`
* ``Cloud sessions need a claude.ai sign-in. Run `claude auth login` (or /login in a local session), then try again.``
* `Error loading Claude Code sessions` in the session picker, when you run `claude --teleport` without a session ID

Run [`claude auth login`](/docs/en/cli-reference#cli-commands) in your shell to sign in with your claude.ai account, then retry the command. Inside a running session, `/login` does the same. If the error names your provider instead, see the [error table](#errors-when-sending-to-a-cloud-session): cloud sessions aren't available through third-party providers.

From v2.1.274 through v2.1.289, the sign-in message read `Claude Code cloud sessions require authentication with a Claude.ai account. API key authentication is not sufficient. Please run /login to authenticate, or check your authentication status with /status.`

### Remote Control session expired or access denied

`--teleport` connects through the same Remote Control session infrastructure that cloud sessions use, so authentication and session-expiry errors surface with Remote Control wording. You may see `Remote Control session expired` or `Access denied`. The connection token is short-lived and scoped to your account.

* Run `/login` locally to refresh your credentials, then reconnect
* Confirm you are signed in to the same account that owns the session
* If you see `Remote Control may not be available for this organization`, an Owner has not enabled cloud sessions for your organization

### Errors when sending to a cloud session

These errors come from running `claude` with [`--cloud <session-id>`](#send-follow-ups-from-the-cli), with or without `-p`. The CLI prefixes errors with `Error: `. A failed delivery is wrapped as `failed to send message to cloud session <id>: <reason>`.

| Message | What it means |
| - | - |
| `Cloud sessions aren't available with <provider>. They run on Anthropic's infrastructure and require an Anthropic account.` | Claude Code is configured for a third-party provider. The message names the provider with the label your configuration uses, such as `Amazon Bedrock` or `Google Vertex AI`. Remove that provider's configuration, for example by unsetting `CLAUDE_CODE_USE_BEDROCK`, and sign in with an Anthropic account (`claude auth login`). |
| `Cloud sessions are disabled by your organization's policy. Contact your organization admin to enable them.` | The `allow_remote_sessions` organization policy is off. |
| `Couldn't verify your organization's policy for cloud sessions. Check your network connection and try again.` | Claude Code couldn't fetch your organization's policy, so it refuses the send rather than assume cloud sessions are allowed. Check your network connection and retry. |
| `Attaching to an existing cloud session is not enabled for your account.` | You ran `--cloud <session-id>` without `-p`. Send the message with `claude -p "your message" --cloud <session-id>`. |
| `Session not found: <id>` | The ID or URL doesn't match a session you can access. Check it against the session's claude.ai/code URL. |
| `cloud session <id> is archived and cannot accept new messages` | The session has been archived. Start a new session instead. |

### Environment expired

Cloud sessions stop after a period of inactivity and the session's VM is reclaimed. A session counts as inactive while it waits for you to approve an [MCP connector](/docs/en/cloud-environments#network-access) tool call or to sign in to an MCP server, and it can expire during that wait.

Reopen the session from [claude.ai/code](https://claude.ai/code) to provision a fresh VM:

* **Restored**: your conversation history
* **Not restored**: background work that was still running when the VM was reclaimed, such as subagents and shell commands

## Limitations

Before relying on cloud sessions for a workflow, account for these constraints:

* **Rate limits**: cloud sessions share rate limits with all other Claude and Claude Code usage within your account. Running multiple tasks in parallel consumes more rate limits proportionately. There is no separate compute charge for the cloud VM.
* **Time limits**: commands Claude runs and SessionStart hooks have default timeouts you can change, and a setup script is cached only when it finishes in roughly five minutes. See [Time limits](/docs/en/cloud-environments#time-limits)
* **Repository authentication**: you can only pull a cloud session into your terminal when you are authenticated to the same account
* **Platform restrictions**: repository cloning and pull request creation require GitHub. Self-hosted [GitHub Enterprise Server](/docs/en/github-enterprise-server) instances are supported for Team and Enterprise plans. You can send a GitLab, Bitbucket, or other non-GitHub repository to a cloud session as a [local bundle](#send-local-repositories-without-github) by setting `CCR_FORCE_BUNDLE=1`, but the session can't push results back to that remote
* **Organization IP allowlist**: cloud sessions call the Anthropic API from Anthropic-managed infrastructure, not your network, while sessions in a [self-hosted environment](/docs/en/self-hosted-environments) call it from your own network. If your organization has [IP allowlisting](https://support.claude.com/en/articles/13200993-restrict-access-to-claude-with-ip-allowlisting) enabled, every Anthropic-hosted cloud session fails with an authentication error. The same applies to [Code Review](/docs/en/code-review) and to [routines](/docs/en/routines) that run on Anthropic-hosted environments; a routine routed to a self-hosted environment calls the API from your own network. Contact [Anthropic support](https://support.claude.com/) to exempt Anthropic-hosted services from your organization's IP allowlist.

## Related resources

* [Cloud environments](/docs/en/cloud-environments): configure network access, environment variables, and setup scripts for cloud sessions
* [Projects](/docs/en/claude-projects): one conversation where Claude coordinates parallel cloud sessions on your repositories and reports back
* [Ultrareview](/docs/en/ultrareview): run a deep multi-agent code review in a cloud sandbox
* [Routines](/docs/en/routines): automate work on a schedule, via API call, or in response to GitHub events
* [Hooks configuration](/docs/en/hooks): run scripts at session lifecycle events
* [All settings](/docs/en/settings-reference): all configuration options
* [Security](/docs/en/security): isolation guarantees and data handling
* [Data usage](/docs/en/data-usage): what Anthropic retains from cloud sessions
* [Claude Tag](https://claude.com/docs/claude-tag/overview): an organization-managed @Claude in Slack that runs on the same cloud infrastructure
