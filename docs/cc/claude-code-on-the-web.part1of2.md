[Part 1/2 of https://code.claude.com/docs/en/claude-code-on-the-web.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Use Claude Code in the cloud

> Run Claude Code sessions in the cloud from your browser, phone, Desktop app, or terminal, move them with `--cloud` and `--teleport`, and auto-fix pull requests.

<Note>
  Cloud sessions are available on Pro, Max, and Team plans, and for Enterprise users with premium seats or Chat + Claude Code seats.
</Note>

A cloud session is a Claude Code session that runs on cloud infrastructure instead of on your machine. By default it runs on infrastructure Anthropic manages, or on your organization's [self-hosted environment](/docs/en/self-hosted-environments) when routed there. The session keeps running after you close your laptop, and you can check on it or steer it from any device.

To let cloud sessions clone your code from GitHub and push branches, connect GitHub with one of the [GitHub connection methods](#github-authentication-options). If your repository is on GitLab, Bitbucket, or another host, see [Platform restrictions](#limitations) for what works.

You can start a cloud session from any of these surfaces:

* **Browser**: [claude.ai/code](https://claude.ai/code), also called Claude Code on the web
* **Mobile**: the **Code** tab in the [Claude app](/docs/en/mobile)
* **Desktop app**: select **Cloud** instead of **Local** when you [start a session](/docs/en/desktop#run-long-running-tasks-in-the-cloud)
* **Terminal**: [`claude --cloud`](#from-terminal-to-cloud)
* **Routines**: [scheduled and triggered runs](/docs/en/routines) each run as a cloud session

Once you're set up, use this page to move work between your terminal and the cloud, manage and share sessions, turn on auto-fix for pull requests, and troubleshoot.

<Note>
  These cases are covered on other pages:

  * **Starting your first cloud session**: [Get started with cloud sessions](/docs/en/web-quickstart) connects GitHub and walks through a task in the browser
  * **Many cloud sessions for one body of work**: a [project](/docs/en/claude-projects) has Claude start and keep track of them for you
  * **Steering a local session from another device**: sessions in your terminal, IDE, or the Desktop app with **Local** selected run on your machine, and [Remote Control](/docs/en/remote-control) lets you reach them from your phone or browser
</Note>

## Cloud environments

Every cloud session runs in a [cloud environment](/docs/en/cloud-environments), the saved configuration that controls network access, environment variables, and setup scripts.

* **Your first environment**: if you don't have one yet, onboarding sets up a **Default** environment with [**Trusted** network access](/docs/en/cloud-environments#access-levels), either by creating it for you or by asking you to create it. See [The Default environment](/docs/en/cloud-environments#the-default-environment) for which of those happens on your plan
* **Which environment a session uses**: see [The Default environment](/docs/en/cloud-environments#the-default-environment) for how sessions choose an environment when you have more than one
* **Change what sessions can reach or run at startup**: see [Configure cloud environments](/docs/en/cloud-environments)
* **What's installed without any configuration**: see [Installed tools](/docs/en/cloud-environments#installed-tools)

## GitHub authentication options

Cloud sessions need access to your GitHub repositories to clone code and push branches. You can grant access in two ways:

| Method | How you connect | Repositories sessions can reach | Best for |
| :- | :- | :- | :- |
| **GitHub App** | Authorize the Claude GitHub App during [web onboarding](/docs/en/web-quickstart) | Any public repository, and private repositories that the Claude GitHub App is installed on | Browser onboarding; teams that want [Auto-fix](#auto-fix-pull-requests) |
| **`/web-setup`** | Run `/web-setup` in your terminal to send your local `gh` CLI token to your Claude account | Any repository your `gh` token can access, whether or not the Claude GitHub App is installed | Individual developers who already use `gh` |

These features depend on the Claude GitHub App being installed on the repository:

* **Auto-fix**: installing the Claude GitHub App on a repository also enables [Auto-fix](#auto-fix-pull-requests) for pull requests in it
* **Projects**: threads in a [project](/docs/en/claude-projects) need the Claude GitHub App installed on each repository they clone, whichever method you connected with. See [Set up GitHub access](/docs/en/claude-projects#set-up-github-access)

In Anthropic-hosted environments, your GitHub credentials stay encrypted on Anthropic's servers and never enter a session's VM. GitHub operations from the VM go through the [GitHub proxy](/docs/en/cloud-environments#github-proxy), which attaches the credential on the server side.

See [Connect from your terminal](/docs/en/web-quickstart#connect-from-your-terminal) for the `/web-setup` walkthrough, including what `/web-setup` stores and how to remove it.

<Note>
  Organizations with [Zero Data Retention](/docs/en/zero-data-retention) enabled, or with the [HIPAA configuration](/docs/en/hipaa-setup) applied, can't use `/web-setup` or other cloud session features.
</Note>

### Quick setup for Team and Enterprise

Quick setup is an organization setting that removes steps from members' GitHub and environment setup. On Team and Enterprise plans it's off by default.

Here's what changes for members when it's on:

* **`/web-setup`**: members can connect GitHub with `/web-setup`. While the setting is off, the command is hidden
* **GitHub App prompt**: browser onboarding skips the Claude GitHub App install prompt
* **First environment**: browser onboarding creates the [**Default** environment](/docs/en/cloud-environments#the-default-environment) for members instead of showing the environment form

An [Owner](/docs/en/server-managed-settings#access-control) turns it on with the **Quick setup** toggle at [**Organization settings > Claude Code**](https://claude.ai/admin-settings/claude-code).

## Move tasks between terminal and cloud

These workflows require the [Claude Code CLI](/docs/en/quickstart) signed in to the same claude.ai account. You can start new cloud sessions from your terminal, or pull cloud sessions into your terminal to continue locally. Cloud sessions persist even if you close your laptop, and you can monitor them from anywhere including the Claude mobile app.

<Note>
  From the CLI, session handoff is one-way: you can pull cloud sessions into your terminal with `--teleport`, but you can't push an existing terminal session to the cloud. The `--cloud` flag with a task description creates a new cloud session for your current repository; with `-p` and a session ID or claude.ai/code URL it instead [queues a message into that existing session](/docs/en/claude-code-on-the-web#send-follow-ups-from-the-cli). The [Desktop app](/docs/en/desktop#continue-in-another-surface) can send a local session in its Code tab to the cloud from its **Open in** menu.
</Note>

### From terminal to cloud

Start a cloud session from the command line with the `--cloud` flag:

```bash theme={null}
claude --cloud "Fix the authentication bug in src/auth/login.ts"
```

This creates a new cloud session on claude.ai. The cloud VM clones your current directory's GitHub remote at your current branch, not your local checkout, so push first if you have local commits. See [Send local repositories without GitHub](#send-local-repositories-without-github) for the cases where Claude Code uploads your local repository instead of cloning.

`--cloud` works with a single repository at a time. The task runs in the cloud while you continue working locally. The older `--remote` spelling still works as a deprecated alias for `--cloud`.

While the cloud container starts, the CLI shows a live checklist of setup steps, such as cloning the repository and running your [setup script](/docs/en/cloud-environments#setup-scripts). It queues messages you type during provisioning and sends them once the session is ready.

<Note>
  `--cloud` creates cloud sessions. `--remote-control` is unrelated: it lets you monitor and steer a local CLI session from claude.ai or the Claude app. See [Remote Control](/docs/en/remote-control).
</Note>

Open the session on claude.ai or the Claude mobile app to check progress or interact directly. From there you can steer Claude, provide feedback, or answer questions as in any other conversation.

If Claude asks a question and the session sits idle, you can still answer when you come back, up to [environment expiry](#environment-expired), and the session continues from your answer.

#### Tips for cloud tasks

**Plan locally, execute in the cloud**: for complex tasks, start Claude in plan mode to collaborate on the approach, then send work to the cloud:

```bash theme={null}
claude --permission-mode plan
```

In plan mode, Claude reads files, runs commands to explore, and proposes a plan without editing source code. Once you're satisfied, save the plan to the repo, commit, and push so the cloud VM can clone it. Then start a cloud session for autonomous execution:

```bash theme={null}
claude --cloud "Execute the migration plan in docs/migration-plan.md"
```

**Run tasks in parallel**: each `--cloud` command creates its own cloud session that runs independently. You can start multiple tasks and they'll all run simultaneously in separate sessions:

```bash theme={null}
claude --cloud "Fix the flaky test in auth.spec.ts"
claude --cloud "Update the API documentation"
claude --cloud "Refactor the logger to use structured output"
```

When a session completes, you can create a PR from claude.ai/code or [teleport](#from-cloud-to-terminal) the session to your terminal to continue working.

#### Send local repositories without GitHub

When you run `claude --cloud` from a repository that has no git remote, or from a github.com repository that the Claude GitHub App isn't installed on, Claude Code bundles your local repository and uploads it directly to the cloud session. This applies even if you connected GitHub with `/web-setup`.

For a full clone, the bundle includes your repository history across all branches, plus uncommitted changes to tracked files.

What happens to uncommitted changes in sensitive files depends on your platform:

* **macOS, Linux, and WSL**: Claude Code leaves uncommitted changes to files named like credentials or keys out of the upload. This includes `.env` files, Terraform `*.tfvars` files, and key files such as `id_rsa` and `*.pem`. It also leaves out uncommitted changes to files that a git filter such as Git LFS manages. A `Left on this machine:` notice names the files left out, and the session starts with the committed version of each, or without the file if none is committed.
* **Native Windows**: uncommitted changes to tracked files upload as they are, whatever the file's name. Stash or revert an edit you don't want in the cloud session before you start it.

To upload a bundle even when Claude Code would otherwise clone from the remote, set `CCR_FORCE_BUNDLE=1`:

```bash theme={null}
CCR_FORCE_BUNDLE=1 claude --cloud "Run the test suite and fix any failures"
```

Bundled repositories must meet these limits:

* The directory must be a git repository with at least one commit
* The bundled repository must be under 100 MB. Larger repositories fall back to bundling only the current branch, then to a single squashed snapshot of the working tree, and fail if the snapshot is still too large
* Untracked files are not included; run `git add` on files you want the cloud session to see
* On macOS, Linux, and WSL, Claude Code refuses the upload when it can't follow a git setting that affects which attribute rules apply to your files, such as `core.attributesFile` set in an included config file. The [refusal message](/docs/en/errors#the-repository-upload-cant-follow-a-git-setting) names the setting and the fix
* Sessions created from a bundle can push back to a GitHub remote only when your [GitHub connection](#github-authentication-options) has push access to that repository

On macOS, Linux, and WSL, the upload also needs git 2.31 or later and a checkout layout it supports, while on native Windows Claude Code uploads without either check. When a checkout doesn't meet those requirements, Claude Code doesn't start the session. It prints an error that contains `Not uploading this working tree:`, names the cause, and says what to change. These are the common causes:

* **Older git**: the installed git is older than 2.31. Update git, then retry.
* **A checkout layout the upload doesn't support**: you started inside a submodule, in a clone made with `git clone --separate-git-dir`, `--shared`, or `--reference`, in a checkout with `core.worktree` set, or in a repository that keeps its refs in the reftable format. Start from the main checkout of a clone made with a plain `git clone` instead.
* **A linked worktree with a sparse checkout**: `git sparse-checkout` writes settings to the worktree's own `config.worktree` file, which the upload doesn't accept, so a worktree that has those settings isn't uploaded, and neither is one Claude Code created with [`worktree.sparsePaths`](/docs/en/settings-reference#worktree-sparsepaths). Start from the repository's main checkout instead.
* **Git configuration kept inside the working tree**: your git configuration includes a file that sits inside the checkout, for example an `include.path` entry that points into the repository. Move that file outside the working tree or remove the include, then retry.

On macOS, Linux, and WSL, a partial clone made with `git clone --filter` uploads as a snapshot of its working tree without history, as long as the clone holds every tracked file locally.

For `claude --cloud`, if the repository is on GitHub, you can avoid the upload and its requirements: push your branch, install the Claude GitHub App on the repository, and start the session again so that it clones from GitHub.

### Send follow-ups from the CLI

Once a cloud session is running, wherever it executes, send it a follow-up message from the `claude` CLI on any machine where you're logged in with `claude auth login`. The CLI authenticates with your Anthropic account credentials and sends no local session state, so the command doesn't need to run from the machine that started the session.

The command posts one message and exits:

```bash theme={null}
claude -p "your message" --cloud <session-id>
```

The CLI queues the message into the session and exits without waiting for a reply. Use it to steer a long-running session, queue the next step while the current one is still finishing, or send follow-ups from a [CI script](/docs/en/self-hosted-environments-testing#run-the-test-loop). You can also pipe the message on stdin instead of passing it as an argument: `echo "your message" | claude -p --cloud <session-id>`.

For `<session-id>`, pass the bare ID, such as `session_...` or `cse_...`, or the session's `claude.ai/code/<id>` URL, with or without the scheme or query string. Find the ID in your session list at claude.ai/code.

<Note>
  `--cloud` requires an Anthropic account. It's not available when Claude Code is configured for Amazon Bedrock, Google Cloud's Agent Platform, or another third-party provider. An [LLM gateway](/docs/en/llm-gateway) configured only through `ANTHROPIC_BASE_URL` doesn't count as a third-party provider for this check, but you still need to sign in with `claude auth login`. Your organization's `allow_remote_sessions` policy must also be enabled. An Owner can turn it on in the Claude Code admin settings at claude.ai/admin-settings/claude-code.
</Note>

#### Output

On success, the command prints the session ID and a link to view the session:

```
Sent to cloud session.
Session ID: session_01DiUkqY2kzbUbDmW1w96rfi
View: https://claude.ai/code/session_01DiUkqY2kzbUbDmW1w96rfi?from=cli&m=0
```

Pass `--output-format json` for a machine-readable result: `{ok, session_id, url}` on success, or `{ok: false, session_id, error}` when the send fails, for example when the session is missing or archived. Configuration errors, such as an unsupported provider or a disabled organization policy, print to stderr without JSON. `--output-format stream-json` isn't supported with `--cloud <session-id>`.

If the send fails, see [Errors when sending to a cloud session](#errors-when-sending-to-a-cloud-session).

### From cloud to terminal

Pull a cloud session into your terminal using any of these:

* **Using `--teleport`**: from the command line, run `claude --teleport` for an interactive session picker, or `claude --teleport <session-id>` to resume a specific session directly. If you have uncommitted changes, you'll be prompted to stash them first.
* **Using `/teleport`**: inside an existing CLI session, run `/teleport` or `/tp` to open the same session picker without restarting Claude Code.
* **From `/tasks`**: run `/tasks` to see your background sessions, then press `t` to teleport into one.
* **From claude.ai/code**: select **Open in > Terminal** from the session menu to copy a command you can paste into your terminal.
* **From inside the cloud session**: type `/teleport` and Claude Code replies with the exact `claude --teleport <session-id>` command for that session, ready to run from a checkout of the repository. Requires Claude Code v2.1.223 or later in the session's environment.

When you teleport a session, Claude verifies you're in the correct repository, fetches and checks out the branch from the cloud session, and loads the full conversation history into your terminal. The terminal gets its own copy of the session: new work there stays local and doesn't appear in the cloud session on claude.ai or the Claude mobile app. To keep steering from your phone after teleporting, start [`/remote-control`](/docs/en/remote-control) in the local session.

`--teleport` is distinct from `--resume`. `--resume` reopens a conversation from this machine's local history and doesn't list cloud sessions; `--teleport` pulls a cloud session and its branch.

#### Teleport requirements

Teleport checks these requirements before resuming a session. If any requirement isn't met, you'll see an error or be prompted to resolve the issue.

| Requirement | Details |
| - | - |
| Clean git state | Your working directory must have no uncommitted changes. Teleport prompts you to stash changes if needed. |
| Correct repository | You must run `--teleport` from a checkout of the same repository, not a fork. If you run it from a checkout of a different repository, Claude Code shows an error that names both the session's repository and your checkout's. If Claude Code can't parse your remote into a hostname, for example an SSH host alias like `git@work:owner/repo.git`, it asks you to confirm, and accepts the checkout when the remote's owner and repository name match the session's repository. |
| Branch available | The branch from the cloud session must have been pushed to the remote. Teleport automatically fetches and checks it out. |
| Same account | You must be authenticated to the same claude.ai account used in the cloud session. |

When teleport fetches the session's branch, the fetch never waits for input in your terminal. If git or ssh would ask for a password, a key passphrase, or confirmation of a new SSH host, the fetch fails, and the checkout then works only if your local clone already has the branch. For the two SSH cases, load your key into `ssh-agent` and run `git fetch` once by hand first to record the host.

#### `--teleport` is unavailable

Teleport requires claude.ai subscription authentication. Find the case that matches yours:

* **You're authenticated via API key**: run `/login` to sign in with your claude.ai account instead
* **The error names your provider**: cloud sessions aren't available through third-party providers. See the [error table](#errors-when-sending-to-a-cloud-session)
* **You're already signed in via claude.ai**: your organization may have disabled cloud sessions

## Work with sessions

Sessions appear in the sidebar at claude.ai/code. From there you can review changes, share with teammates, archive finished work, or delete sessions permanently.

### Permission modes in cloud sessions

You pick a cloud session's [permission mode](/docs/en/permission-modes) from the [mode dropdown](/docs/en/permission-modes#switch-permission-modes), both when you create the task and while the session runs.

Claude Code resumes a session in the permission mode it was in when you do either of these:

* Reopen a session whose Anthropic-hosted [environment expired](#environment-expired)
* Send a message to a session that a self-hosted runner [released while it was idle](/docs/en/self-hosted-environments-reference#runner-cli-flags)

### Review changes

Each session shows a diff indicator with lines added and removed, like `+42 -18`. Select it to open the diff view, leave inline comments on specific lines, and send them to Claude with your next message.

The diff view compares the session's changes against its base branch by default. To compare against any other branch in the repository, select **Compare against** and pick one.

Claude Code computes these diffs from raw git blob content, so diff drivers and `textconv` filters configured in the repository don't apply.

These steps are covered elsewhere:

* **The full walkthrough, including PR creation**: see [Review and iterate](/docs/en/web-quickstart#review-and-iterate)
* **Having Claude monitor the PR for CI failures and review comments automatically**: see [Auto-fix pull requests](#auto-fix-pull-requests)
