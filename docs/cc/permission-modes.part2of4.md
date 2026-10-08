[Part 2/4 of https://code.claude.com/docs/en/permission-modes.md, fetched 2026-10-08]

## Auto-approve file edits with acceptEdits mode

`acceptEdits` mode lets Claude create and edit files in your working directory without prompting. The status bar shows `⏵⏵ accept edits on` while this mode is active.

In addition to file edits, `acceptEdits` mode auto-approves common filesystem Bash commands: `mkdir`, `touch`, `rm`, `rmdir`, `mv`, `cp`, and `sed`. These commands are also auto-approved when prefixed with safe environment variables such as `LANG=C` or `NO_COLOR=1`, or process wrappers such as `timeout`, `nice`, or `nohup`. Like file edits, auto-approval applies only to paths inside your working directory or `additionalDirectories`.

Each path also goes through the [symlink check](/docs/en/permissions#symlinks), so a write that resolves outside that scope isn't auto-approved either. Paths outside that scope, writes to [protected paths](#protected-paths), `rm` and `rmdir` removals targeting a [critical path](#critical-paths), and all other Bash commands except the [built-in read-only set](/docs/en/permissions#read-only-commands) still prompt.

When the [PowerShell tool](/docs/en/tools-reference#powershell-tool) is enabled, `acceptEdits` mode also auto-approves `Set-Content`, `Add-Content`, `Clear-Content`, and `Remove-Item` on in-scope paths, along with their common aliases. The same scope and protected-path rules apply, and `Remove-Item` gets [its own check](#remove-item-in-powershell). A positional argument that contains a quote character, such as the apostrophe in `Set-Content .\notes.txt "It's done"`, still prompts even on in-scope paths, because Claude Code can't statically validate an argument whose quoted and unquoted readings differ. Pass the content through a named parameter such as `-Value` to avoid the prompt.

Use `acceptEdits` when you want to review changes in your editor or via `git diff` after the fact rather than approving each edit inline.

Press `Shift+Tab` once from Manual mode to enter it, or start with it directly:

```bash theme={null}
claude --permission-mode acceptEdits
```

## Analyze before you edit with plan mode

Plan mode tells Claude to research and propose changes without making them. Claude reads files, runs shell commands to explore, and writes a plan, but does not edit your source. Except in interactive terminal sessions with [bypass permissions available](#skip-all-checks-with-bypasspermissions-mode), edits stay blocked until you approve the plan.

What happens to a shell command during planning depends on the session, and the first of these cases that matches applies:

* **Interactive terminal sessions with bypass permissions available**: neither the classifier nor a prompt applies to planning commands. [Skip all checks with bypassPermissions mode](#skip-all-checks-with-bypasspermissions-mode) covers the few things that still prompt there.
* **[Auto mode](/docs/en/auto-mode-config) available and the `useAutoModeDuringPlan` setting on**, which it is by default: the classifier reviews shell commands other than [critical-path removals](#critical-paths) instead of prompting you. Approved commands run, and rejected ones are blocked.
* **Auto mode not available, or `useAutoModeDuringPlan` off**: commands outside the [built-in read-only set](/docs/en/permissions#read-only-commands) prompt for approval, including when the sandbox's [auto-allow mode](/docs/en/sandboxing#sandbox-modes) is enabled.

Enter plan mode by pressing `Shift+Tab` or prefixing a single prompt with `/plan`. You can also start in plan mode from the CLI:

```bash theme={null}
claude --permission-mode plan
```

Press `Shift+Tab` again to leave plan mode without approving a plan.

### Review and approve a plan

When the plan is ready, Claude presents it and asks how to proceed. From that prompt you can choose:

* **Yes, and use auto mode**: approve and start in [auto mode](#eliminate-prompts-with-auto-mode). If auto mode isn't [available to your session](#eliminate-prompts-with-auto-mode), for example because your organization turned it off, this option reads **Yes, auto-accept edits**. If you started the session with bypass permissions enabled, the option reads **Yes, and switch to BYPASS PERMISSIONS (no further prompts) for this session** instead.
* **Yes, manually approve edits**: approve and review each edit individually.
* **No, keep planning**: stay in plan mode and tell Claude what to change.

Approving a plan exits plan mode and switches the session to the permission mode each approve option describes, so Claude starts editing. To plan again, cycle back to plan mode with `Shift+Tab`, or prefix your next prompt with `/plan`.

Press `Ctrl+G` to open the proposed plan in your default text editor and edit it directly before Claude proceeds. When [`showClearContextOnPlanAccept`](/docs/en/settings-reference#showclearcontextonplanaccept) is enabled, the list gains a first option that approves the plan and clears the planning context.

Accepting a plan also gives the session a [generated title](/docs/en/sessions#name-your-sessions) based on the plan, unless you've already named the session.

### Set plan mode as the default

To make plan mode the default for a project's terminal sessions, set `defaultMode` to `plan` in `.claude/settings.json`, placed as the example under [Start in a different permission mode](#start-in-a-different-mode) shows. Conversations the [VS Code extension](/docs/en/vs-code) starts don't read project settings for the starting permission mode. There, set `claudeCode.initialPermissionMode` to `plan` in your VS Code user settings instead.

<h2 id="eliminate-prompts-with-auto-mode">
  Eliminate permission prompts with auto mode
</h2>

Auto mode lets Claude execute without routine permission prompts. A separate classifier model reviews actions before they run, blocking anything that escalates beyond your request, targets unrecognized infrastructure, or appears driven by hostile content Claude read. Explicit [ask rules](/docs/en/permissions#manage-permissions) still force a prompt.

With Claude Code v2.1.283 or later, auto mode is the [built-in starting permission mode](#which-mode-a-session-starts-in) for interactive terminal and VS Code sessions on every plan and provider. On earlier versions, it's the built-in starting permission mode only on Pro, Max, and Team plans.

The classifier also reviews each message Claude sends to another agent with [`SendMessage`](/docs/en/tools-reference), whether plain text or a structured [agent team](/docs/en/agent-teams) message, before Claude Code delivers it, both in auto mode and in [plan mode while the classifier reviews commands](#analyze-before-you-edit-with-plan-mode); the send review requires Claude Code v2.1.222 or later.

By default, the classifier doesn't review `rm` and `rmdir` removals targeting a critical path, such as `rm -rf /` or `rm -rf ~`. [Critical paths](#critical-paths) covers what happens to them in each permission mode.

Auto mode also nudges Claude to keep working without stopping for clarifying questions, though Claude still asks when your prompt or a skill explicitly relies on it. For stronger autonomous behavior in a mode that still prompts you, set the [Proactive output style](/docs/en/output-styles) instead.

<Warning>
  Auto mode reduces permission prompts but does not guarantee safety. Use it for tasks where you trust the general direction, not as a replacement for review on sensitive operations.
</Warning>

Auto mode is available only when your account meets all of these requirements:

* **Plan**: All plans.
* **Organization**: on Team and Enterprise, auto mode is available by default. Administrators can turn it off for the organization by setting `permissions.disableAutoMode` to `"disable"` in [managed settings](/docs/en/managed-settings).
* **Model**: on the Anthropic API and [Claude Platform on AWS](/docs/en/claude-platform-on-aws), Claude Opus 4.6 or later, Sonnet 4.6 or later, Haiku 5.5, or a [Fable model](/docs/en/model-config#work-with-fable). On Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, and signed-in [Claude apps gateway](/docs/en/claude-apps-gateway) sessions, only Claude Sonnet 5 or later, Opus 4.7 or later, Haiku 5.5, and the Fable models. Older models, including Sonnet 4.5, Opus 4.5, Haiku 4.5, and claude-3 models, are not supported on any provider.
* **Provider**: available by default on the Anthropic API, Claude Platform on AWS, Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, and signed-in Claude apps gateway sessions.

If Claude Code reports auto mode as unavailable, first check these requirements and whether any settings file sets [`disableAutoMode`](/docs/en/settings-reference#disableautomode). Anthropic may also have turned auto mode off server-side, or the server may have rejected auto mode for your account. A session that received either answer keeps auto mode off until the session ends, so start a new session later.

A separate message that names a model and says auto mode "cannot determine the safety" of an action means a classifier request failed. That failure is usually transient, but on Amazon Bedrock it can repeat until your account can invoke the named model. See the [error reference](/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action) for the causes and what to do.

If you set `defaultMode: "auto"` in [settings](/docs/en/settings-reference#all-settings) and a terminal session starts in Manual mode with no error, the setting is likely in `.claude/settings.json` or `.claude/settings.local.json`. `auto` doesn't take effect from those files. Move it to `~/.claude/settings.json`. For a conversation the VS Code extension started, check the extension's own list in [Switch permission modes](#switch-permission-modes) instead.

<h3 id="enable-auto-mode-on-bedrock-agent-platform-or-foundry">
  Auto mode on Bedrock, Agent Platform, or Foundry
</h3>

On [Amazon Bedrock](/docs/en/amazon-bedrock), [Google Cloud's Agent Platform](/docs/en/google-vertex-ai), [Microsoft Foundry](/docs/en/microsoft-foundry), and signed-in [Claude apps gateway](/docs/en/claude-apps-gateway) sessions, auto mode is available by default. When nothing else sets a permission mode, it's also the [built-in starting permission mode](#which-mode-a-session-starts-in), on the versions that section's table lists. To choose the starting permission mode yourself, set `permissions.defaultMode` as [Start in a different permission mode](#start-in-a-different-mode) describes, or pick a permission mode from the VS Code extension's mode indicator.

Only Claude Sonnet 5 or later, Opus 4.7 or later, Haiku 5.5, and the Fable models are supported on these providers. On any other model, the session starts in Manual instead. Auto mode with Haiku 5.5 on these providers requires Claude Code v2.1.293 or later.

To prevent developers from using auto mode, set `disableAutoMode` to `"disable"` in [managed settings](/docs/en/managed-settings). This removes `auto` from the `Shift+Tab` cycle, and a session started with `--permission-mode auto` starts in Manual instead. A session already running in auto mode leaves it when the setting reaches that session from an [admin-deployed source](/docs/en/managed-settings#which-managed-source-claude-code-uses), and shows `auto mode disabled by settings`. Before v2.1.251, a running session kept auto mode until it ended.

In v2.1.158 through v2.1.206, auto mode was off on these providers until you set `CLAUDE_CODE_ENABLE_AUTO_MODE=1`, and Claude Code ignored `defaultMode: "auto"` on these providers unless the variable was also set. The variable is still accepted for compatibility and has no effect from v2.1.207 onward.

### Server-side classifier review

In auto mode, Claude Code can ask the server to check the actions that [the decision order](#how-the-classifier-evaluates-actions) sends for review, as part of the session's model requests, in place of sending its own classifier requests. These sessions ask:

* **A direct connection to the Anthropic API**: in interactive terminal sessions and in `-p`, Agent SDK, [VS Code extension](/docs/en/vs-code), and [desktop app](/docs/en/desktop) sessions, whatever your plan or account type, as Anthropic rolls it out. In interactive terminal sessions, this requires Claude Code v2.1.271 or later on Pro, Max, and Team plans, and v2.1.278 or later on Enterprise plans and Claude API accounts. In `-p`, Agent SDK, VS Code extension, and desktop app sessions, this requires Claude Code v2.1.281 or later. From v2.1.282, a session that [doesn't fetch feature flags](/docs/en/env-vars#features-that-need-feature-flag-fetching), for example because you turned telemetry off, asks the server by default in any kind of session.
* **A cloud provider, or an LLM gateway or proxy**: on [Claude Platform on AWS](/docs/en/claude-platform-on-aws), Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry, and whenever you point `ANTHROPIC_BASE_URL` at an [LLM gateway or proxy](/docs/en/llm-gateway), whatever your plan. Asking by default requires Claude Code v2.1.278 or later.
* **A signed-in [Claude apps gateway](/docs/en/claude-apps-gateway) session**: requires Claude Code v2.1.280 or later

Where the server reviews the actions, its verdicts decide them. Two other outcomes are possible:

* **The server doesn't review the session**: a response completes with no review results, or the server answers that it doesn't review this session. The most common causes are an LLM gateway or proxy that drops the request for review or the results, and a platform, region, or credential that doesn't have server-side checks yet. Claude Code falls back to its own classifier requests. Once that fallback holds for the rest of the session, it shows a [notice about classifier request charges](/docs/en/auto-mode-classifier-billing) on accounts where those requests are billed.
* **The server gives no verdict for an action**: Claude Code denies the action rather than run it unreviewed. On any connection, this happens when the response ends before the review results arrive or the results arrive in a form Claude Code can't read. An LLM gateway or proxy that cuts responses short or rewrites the results can cause either. On a direct connection to the Anthropic API, it also happens when the server's check fails for the action, for example by timing out. [The server returned no safety verdict](/docs/en/errors#the-server-returned-no-safety-verdict) covers the denial message, what happens when denials repeat, and what to do.

To skip asking the server and always use Claude Code's own classifier requests, set [`CLAUDE_CODE_AUTO_MODE_SERVER=0`](/docs/en/env-vars). On a direct connection to the Anthropic API, the variable requires Claude Code v2.1.281 or later. Setting it to `1` there turns server review on in a session that doesn't have it yet, unless you've also set `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1`. If you set `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` and leave `CLAUDE_CODE_AUTO_MODE_SERVER` unset, Claude Code also stops asking the server, except as [Disable pre-release capabilities](/docs/en/llm-gateway-protocol#disable-pre-release-capabilities) describes.

### What the classifier blocks by default

The classifier trusts your working directory and the remotes that were configured for it when the session started. A remote added or repointed during the session with `git remote add` or `git remote set-url` isn't trusted, and everything else is treated as external until you [configure trusted infrastructure](/docs/en/auto-mode-config).

**Blocked by default**:

* Downloading and executing code, like `curl | bash`
* Sending sensitive data to external endpoints
* Production deploys and migrations
* Mass deletion on cloud storage
* Granting IAM or repo permissions
* Modifying shared infrastructure
* Irreversibly destroying files that existed before the session
* Force push
* Committing or pushing a change that would send secrets or sensitive data outside the repository when it runs, or widen what a deploy exposes. This covers a CI workflow or deploy configuration that passes a secret to a destination that doesn't already receive it, a script or setup step that reads a secret store and sends the data out, and a config change that widens what a deploy publishes, such as a registry, visibility, artifact, or sourcemap setting. The check applies on any branch, applies even when the repository is public, and fires when the change is committed or pushed, whether or not that commit or push triggers the pipeline; clearing it requires naming the execution effect, not only the commit or push. Before v2.1.211, this check was scoped to the default branch instead: a push there was blocked when it carried sensitive content, changes concealed or misdescribed relative to what you asked for, content ported in from outside the repository, or routed around a review you asked for
* `git reset --hard`, `git checkout -- .`, `git restore .`, `git clean -fd`, `git stash drop`, or `git stash clear`, which the classifier presumes would discard uncommitted changes
* `git commit --amend` when the commit at HEAD was not created in this session
* From v2.1.198, `git commit --amend` when the commit at HEAD has already been pushed. A message-only reword is not blocked: `--amend -m` with nothing newly staged, on a commit that Claude created during this session
* `terraform destroy`, `pulumi destroy`, `cdk destroy`, or `terragrunt destroy`, and applying a plan that destroys resources
* Writing to a secret manager, or changing DNS records or TLS certificates
* Merging a pull request no human has approved, approving Claude's own pull request, or disabling CI checks
* Posting a comment that is itself a command to automation, such as `atlantis apply` or a bot's `/deploy` or `/merge`
* Toggling, ramping, or deleting a production feature flag
* Applying infrastructure changes to a protected IaC scope, or draining and removing cluster nodes
* Writes to a shared compute cluster that reach beyond the resource you named, such as a label selector or `--all` that catches other users' jobs
* Creating Kubernetes resources that run on every node or intercept cluster traffic, such as DaemonSets and admission webhooks
* Interactive shells or port-forwards into a sensitive remote target
* Opening a tunnel or reverse shell that makes a local service reachable from the public internet
* Printing a live credential or token into the transcript or a file
* Accessing a location listed as a sensitive data location in your [environment](/docs/en/auto-mode-config#define-trusted-infrastructure), copying data out of one, or sending data from one to an audience the entry excludes
* Routing a package install around your internal package registry to a public registry. This applies when an internal registry or mirror is listed in your environment or when you've told Claude in the conversation that one exists
* Running a command with a flag that disarms a safety guard, like `--insecure`
* Launching an autonomous agent loop that runs without human approval or a sandbox, such as one started with `--dangerously-skip-permissions` or `--no-sandbox`. This includes running a third-party agent or eval harness with isolation and per-action approval disabled, such as a runner started with `--yes-always`
* [Claude in Chrome](/docs/en/chrome) browser actions that could send page content, cookies, or credentials off-origin
* Deleting files in `/tmp`, `$TMPDIR`, or another shared scratch or cache directory by wildcard, glob, or age filter rather than by a specific named path
* Including sensitive details in content sent, uploaded, published, or written to other people or shared systems, when your own message didn't authorize those details for that recipient. PR and issue bodies, commit messages, and comments count as this kind of outbound content when the repository is outside the trust boundary or public, including your organization's own public repositories; internal file paths, code names, live API response data such as emails or account identifiers, and infrastructure identifiers count as sensitive details. Live personal data from an API response in a PR or issue body, such as an email address, an account or organization identifier, or a usage metric, requires you to name those details and the recipient regardless of the repository's visibility or trust boundary. That check requires Claude Code v2.1.203 or later
* Sending keystrokes to Claude Code's own tmux pane to drive its own interface, which the classifier treats as Claude changing its own permissions or oversight
* Commenting out, deleting, or force-passing a test or assertion that guards security behavior, such as auth, access control, input validation, or sandboxing
* Deleting or tearing down a stateful resource Claude didn't create in the session, when no more specific deletion rule applies and you didn't name that resource
* Repointing an API base URL, proxy endpoint, webhook receiver, or registry mirror at a third-party host that doesn't fit the task, including in example files like `.env.example`
* Changing where pushes go with `git remote set-url` or `git remote add`, unless you named the new remote
* Pushing secrets or personal or entrusted data to a repository known to be public, or pushing confidential material there that isn't part of that repository's own work. A dotfiles repository's own subject matter is the one exception for personal or entrusted data, and content from a private repository reaching any public surface is blocked the same way; both refinements require Claude Code v2.1.203 or later. Before v2.1.203, personal data was grouped with confidential material and blocked only when it wasn't part of that repository's own work. When a repository's visibility isn't established, the classifier doesn't block on that alone; it judges the content against the other rules instead
* Opening a pull request against a different repository or organization, forking with `gh repo fork`, or pushing to a third-party repository, unless you named that external target

Several of these categories depend on [environment](/docs/en/auto-mode-config#define-trusted-infrastructure) entries, such as sensitive remote targets and protected IaC scopes, that you can narrow to concrete names.

Claude Code v2.1.203 and later also block these by default:

* Content from a sensitive local store, or from a file whose name, path, or type marks it as sensitive, entering a commit, a push, PR or issue text, a gist or paste, or a package publish, unless you named both the source and the destination. Session transcripts and conversation logs, credential and configuration dot-folders such as SSH keys, cloud credentials, browser profiles, and shell history, and user-data exports all count, and the repository being private doesn't clear it

Claude Code v2.1.205 and later also block these by default:

* Writing to Claude Code session transcripts, the `.jsonl` history files under `~/.claude/projects/` or your configured config directory, whether directly or through a shell command. The rule also covers the metadata lines Claude Code appends to each transcript entry for its own checks. Reading a transcript isn't blocked
* A recursive forced delete such as `rm -rf "$VAR"` or `Remove-Item -Recurse -Force $dir` whose target is a shell variable that isn't assigned anywhere in the conversation the classifier sees, or a glob rooted at such a variable. The value came only from earlier command output, which the classifier never receives, so the classifier can't verify the deletion target against the other deletion rules. The block clears when you name the exact path being deleted, or when Claude re-runs the delete with the resolved literal path written into the command. Deletes whose target the classifier can resolve aren't affected.

  A glob directly under the variable, as in `rm -rf "$VAR"/*`, is a [critical path](#critical-paths) instead. `Remove-Item` targets that are a bare `*` or end in `/*` or `\*` never reach the classifier: Claude Code [denies them outright](#remove-item-in-powershell).

Claude Code v2.1.257 and later also block these by default:

* Requesting credentials from the cloud instance-metadata endpoint, such as `169.254.169.254`, or explicitly authenticating a cloud, cluster, or registry call with the machine's own service-account or node identity
* Reaching a public host by a route other than a direct request, such as a tunnel, a reverse shell, or a resolver or proxy configuration rewritten to point outside
* Reading credentials that belong to the host rather than to your task, such as node certificates or the node's container-registry auth
* Connecting to or scanning sibling containers, pods, or VMs that Claude didn't start, or the node beneath the container

If Claude Code runs somewhere that is meant to allow one of these, describe that setup in a [Host containment entry](/docs/en/auto-mode-config#define-trusted-infrastructure) in `autoMode.environment`.

Claude Code v2.1.261 and later also block these by default:

* Posting or writing a link to a public paste, diagram, or data-sharing service in a message, PR or issue text, a document, or anywhere else the link will be opened or fetched, when the URL itself carries the content being shared, unless you named that service

**Allowed by default**:

* Local file operations in your working directory
* Installing dependencies declared in your lock files or manifests
* Reading `.env` and sending credentials to their matching API
* Read-only HTTP requests
* Pushing to any branch of the repository you're working in, including the default branch. A non-default branch whose name marks it as a deploy or publication target, such as `production` or `gh-pages`, isn't covered: the classifier judges a push there on its own terms. The push's content is still checked against the other rules, [`permissions.deny` rules](/docs/en/permissions#manage-permissions) can still block push commands [as written](/docs/en/permissions#bash-rule-limits) in every mode, and the remote's own branch protection still applies. Before v2.1.211, only pushes to the branch you started on, branches Claude created, and routine pushes to the default branch were allowed by default, and before v2.1.203 any direct push to the default branch was blocked
* Deleting the exact jobs Claude created earlier in the same session
* Reading, reviewing, or writing security-related code, configs, and threat models as part of your task
* Messages between agents working together in the same multi-agent session
* Sending data to the trusted domains, buckets, and services you list in [`environment`](/docs/en/auto-mode-config#define-trusted-infrastructure). This covers data flow only, not destructive or credential operations on the same infrastructure
* [Claude in Chrome](/docs/en/chrome) navigation to a trusted internal domain, localhost, or a URL you named

Sandboxed commands don't get network access by default. Claude names the hosts a command needs on the command itself, the classifier reviews them with the command, and an approved list opens those hosts for that one command alone. [Per-command allowed domains](/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode) covers what a list can and can't open and what happens when a command reaches for an unlisted host.

Run `claude auto-mode defaults` to print the full rule lists as JSON. If routine actions get blocked, an administrator can add trusted repos, buckets, and services via the `autoMode.environment` setting: see [Configure auto mode](/docs/en/auto-mode-config).

Pushing to any branch of the repository you're working in and creating a pull request that matches your request run without a prompt, unless the push or pull request falls under the [blocked list](#what-the-classifier-blocks-by-default), such as secrets or sensitive data leaving the repository, or a pull request that targets a different repository or organization. To require a human checkpoint before these commands while staying in auto mode, add `permissions.ask` rules, which match the command [as written](/docs/en/permissions#bash-rule-limits): see [Common boundaries](/docs/en/auto-mode-config#common-boundaries).

<h3 id="first-read-outside-the-working-directories">
  The first read outside the working directories
</h3>

While [`permissions.blockReadsOutsideWorkingDirectories`](/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) is off, file reads run without a prompt in auto mode, including reads outside the [working directories](/docs/en/permissions#working-directories). The first time Claude uses the Read, Grep, or Glob tool on a path outside them, Claude Code asks whether to allow that read.

The prompt doesn't appear in non-interactive `-p` runs or background sessions; reads there run as before.

Whatever you answer, Claude keeps working:

* **Yes, and keep allowing any reads outside the working directories**: the read runs, later reads outside the working directories run as before, and Claude Code records your answer so the prompt doesn't appear again
* **No, and block reads outside the working directories from now on**: the read is refused, and Claude Code sets [`permissions.blockReadsOutsideWorkingDirectories`](/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) to `true` in your user settings, which makes the file tools refuse such reads in every later session and every permission mode. To let Claude read such a path later, add its directory with `/add-dir` or remove the setting.
* **No, and ask again next time**: the read is refused, and the next read outside the working directories prompts again
* **Yes, but ask again next time**: the read runs, nothing is saved, and the next read outside the working directories prompts again
