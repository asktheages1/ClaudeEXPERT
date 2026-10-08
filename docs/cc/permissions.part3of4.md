[Part 3/4 of https://code.claude.com/docs/en/permissions.md, fetched 2026-10-08]

## Working directories

By default, Claude has access to files in the directory where you launched it. That directory is the session's primary working directory until you [move the session with `/cd`](#move-the-session-to-another-directory). You can extend this access:

* **During startup**: use `--add-dir <path>` CLI argument
* **During session**: use `/add-dir` command
* **Persistent configuration**: add to `additionalDirectories` in [settings files](/docs/en/settings#where-settings-live)

Files in additional directories follow the same permission rules as the original working directory: they become readable without prompts, and file editing permissions follow the current permission mode.

You can't add most [network paths](/docs/en/errors#working-directory-is-a-network-path), such as the UNC share `\\server\share`, as working directories, because looking one up can contact the host it names. On Windows, map the share to a drive letter instead and pass the drive with `--add-dir` at launch.

Set [`permissions.blockReadsOutsideWorkingDirectories`](/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) to make the file tools refuse the paths it fences in every permission mode. In auto mode, Claude Code offers to turn it on the first time Claude [reads outside the working directories](/docs/en/permission-modes#first-read-outside-the-working-directories).

In background sessions on macOS, the session host requests access to protected folders such as `~/Desktop`, `~/Documents`, and `~/Downloads` separately from your terminal when Claude needs to read or write files there; if reads there fail with `Operation not permitted`, see [how to grant folder access to background sessions](/docs/en/agent-view#background-sessions-can’t-read-desktop-documents-or-downloads-on-macos).

### Move the session to another directory

To move the session to a different primary working directory, rather than [adding a directory](#working-directories) alongside the current one, run `/cd <path>`. Claude Code keeps the conversation, loads the new directory's `CLAUDE.md`, and prompts you to [trust the workspace](#project-allow-rules-and-workspace-trust) if you haven't worked in it before. Afterward, Claude Code [finds the moved session](/docs/en/sessions#resume-a-session) when you run `--resume` from the new directory.

As soon as you move, Claude Code applies the new directory's project configuration:

* Its project settings, including their permission rules and [hooks](/docs/en/hooks)
* Its [`.mcp.json` servers](/docs/en/mcp#project-scope), subject to the same [server approval](/docs/en/mcp#project-server-approvals-and-workspace-trust) as at startup, and the [local-scope](/docs/en/mcp#local-scope) MCP servers you registered in it
* The [plugins](/docs/en/plugins/overview) its settings enable, its [skills](/docs/en/skills#discovery-from-parent-and-nested-directories), and its [subagents](/docs/en/sub-agents)
* Its [`env`](/docs/en/settings-reference#env) values, applied on top of the environment variables from the previous directory's settings, which stay in effect

Claude Code also disconnects the previous directory's project and [local-scope](/docs/en/mcp#local-scope) MCP servers, and the servers of [plugins](/docs/en/mcp#plugin-provided-mcp-servers) that are no longer enabled after the move. It takes [additional directories](#working-directories) from the new directory's settings instead of the previous one's, and keeps the directories you added with `--add-dir` or `/add-dir`. Hooks the move activates still receive [`${CLAUDE_PROJECT_DIR}`](/docs/en/hooks#reference-scripts-by-path) set to the project root where the session started.

When the new directory isn't trusted yet, Claude Code lists in the trust prompt the allow rules, additional directories, hooks, and helper commands the directory's settings would activate, so you can review them before you accept. If you decline, the session stays where it is. Before v2.1.246, `/cd` didn't apply the new directory's settings, hooks, MCP servers, or skills until you resumed the session, and its trust prompt didn't list what the directory's settings would activate.

Restrict or disable `/cd` targets with [`Cd` permission rules](#cd).

### Additional directories grant file access, not configuration

Adding a directory extends where Claude can read and edit files. It doesn't make that directory a full configuration root: most `.claude/` configuration is not discovered from additional directories, though a few types are loaded as exceptions.

These exceptions apply only to directories added with the `--add-dir` flag or the `/add-dir` command, including directories the Agent SDK adds through the flag. Directories listed in `permissions.additionalDirectories` in a settings file grant file access only and don't load any of the configuration below.

The Agent SDK's [`additionalDirectories`](/docs/en/agent-sdk/typescript#options) option in TypeScript and [`add_dirs`](/docs/en/agent-sdk/python#claudeagentoptions) option in Python receive the exceptions too, even though the TypeScript option shares its name with the settings key. The SDK passes each entry to Claude Code as `--add-dir`, so those directories behave like flag-added directories. Skills, commands, and subagents from any flag-added directory load through the `project` [setting source](/docs/en/agent-sdk/claude-code-features#control-filesystem-settings-with-settingsources), so they don't load when you exclude that source with [`--setting-sources`](/docs/en/cli-reference) on the CLI or `settingSources` in the SDK, and [bare mode](/docs/en/headless#start-faster-with-bare-mode) skips the commands and subagents among them.

The following configuration types are loaded from `--add-dir` directories:

| Configuration | Loaded from `--add-dir` |
| :- | :- |
| [Skills](/docs/en/skills) in `.claude/skills/` | Yes, with live reload |
| [Command files](/docs/en/skills#where-skills-live) in `.claude/commands/` | Yes, without live reload. When the added directory and your project both define a command with the same name, Claude Code runs your project's command |
| [Subagents](/docs/en/sub-agents) in `.claude/agents/` | Yes, without live reload |
| [Settings](/docs/en/settings) in `.claude/settings.json` and `.claude/settings.local.json` | `enabledPlugins` and [`extraKnownMarketplaces`](/docs/en/settings-reference#extraknownmarketplaces) keys only |
| [CLAUDE.md](/docs/en/memory) files, `.claude/rules/`, and `CLAUDE.local.md` | Only when `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` is set. `CLAUDE.local.md` additionally requires the `local` setting source, which is enabled by default |

To load the skills, commands, and subagents from a subdirectory of your [primary working directory](#working-directories) mid-session, run `/add-dir` with that subdirectory's path. Claude Code loads them for the rest of the session without prompting you or adding a working directory, because the subdirectory is already readable. This requires Claude Code v2.1.257 or later.

Claude Code discovers output styles from the current working directory and its parents, your user directory at `~/.claude/`, and managed settings. Hooks and other `.claude/settings.json` keys load from the current working directory's `.claude/` folder with no parent-directory fallback, alongside your user `~/.claude/settings.json` and managed settings. `.claude/settings.local.json` loads from the git repository root instead, even when you start Claude Code in a subdirectory, except in the cases where Claude Code [doesn't use the repository root](/docs/en/settings#where-claude-code-looks-for-each-file), such as on Windows; before v2.1.211, it too loaded only from the current working directory. [Agent SDK](/docs/en/agent-sdk/claude-code-features#control-filesystem-settings-with-settingsources) sessions load it from the working directory in all versions.

To share that configuration across projects, use one of these approaches:

* **User-level configuration**: place files in `~/.claude/agents/`, `~/.claude/output-styles/`, or `~/.claude/settings.json` to make them available in every project
* **Plugins**: package and distribute configuration as a [plugin](/docs/en/plugins/overview) that teams can install
* **Launch from the config directory**: run Claude Code from the directory containing the `.claude/` configuration you want

## How permissions interact with sandboxing

Permissions and [sandboxing](/docs/en/sandboxing) are complementary security layers:

* **Permissions** control which tools Claude Code can use and which files or domains it can access. They apply to Bash, Read, Edit, WebFetch, MCP, and every other tool, except that a deny or ask rule can't block [`EndConversation`](/docs/en/tools-reference#endconversation-tool-behavior) while any other tool remains.
* **Sandboxing** provides OS-level enforcement that restricts shell commands' filesystem and network access. It applies to Bash, PowerShell, and [Monitor](/docs/en/tools-reference#monitor-tool) tool commands and their child processes.

Use both for defense-in-depth, since sandbox restrictions still apply even if a prompt injection bypasses Claude's decision-making. Paths and domains from both sandbox settings and permission rules are [merged into the final sandbox configuration](/docs/en/sandboxing#permission-rules).

When you enable sandboxing and leave `autoAllowBashIfSandboxed` at its default of `true`, sandboxed Bash commands run without prompting even if your permissions include a bare `Bash` ask rule, or the [equivalent `Bash(*)` form](#match-all-uses-of-a-tool): the sandbox boundary substitutes for that whole-tool prompt.

In [plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode), Claude Code skips this substitution. Without an ask rule, the [built-in read-only commands](#read-only-commands) still run without prompting, and any other shell command goes through the regular permission flow while you are still planning; see [plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode) for how Claude Code gates commands there. With a bare `Bash` ask rule, every Bash command prompts, including sandboxed read-only commands, the same as outside sandboxing. Before v2.1.212, the substitution applied in plan mode as well.

These checks still apply:

* Content-scoped ask rules like `Bash(git push *)` still force a prompt
* Explicit deny rules still apply
* `rm` or `rmdir` commands that target a [critical path](/docs/en/permission-modes#critical-paths) still go through the regular permission flow

Commands that won't run sandboxed, such as excluded commands, respect the bare `Bash` ask rule as usual. See [sandbox modes](/docs/en/sandboxing#sandbox-modes) to change this behavior.

<span id="managed-only-settings" />

## Managed settings

For organizations that need centralized control, administrators deploy managed settings that user and project settings can't override, apart from a few [security-sensitive keys](/docs/en/settings#exceptions-to-managed-settings-precedence). [Deploy managed settings](/docs/en/managed-settings) covers the delivery mechanisms, precedence within the managed tier, and the [keys that only managed settings can set](/docs/en/managed-settings#managed-only-settings).

One of those keys, [`allowManagedPermissionRulesOnly`](/docs/en/settings-reference#allowmanagedpermissionrulesonly), makes managed settings the only settings source of permission rules. Its entry lists every source Claude Code then ignores.

`disableBypassPermissionsMode` is typically placed in managed settings to enforce organizational policy, but it works from any scope. A user can set it in their own settings to lock themselves out of bypass mode.

## Settings precedence

Permission rules follow the same [settings precedence](/docs/en/settings#settings-precedence) as all other Claude Code settings, with managed settings highest: no other level, including command line arguments, can override a managed permission rule.

If a tool is denied at any level, no other level can allow it. For example, a managed settings deny can't be overridden by `--allowedTools`, and `--disallowedTools` can add restrictions beyond what managed settings define.

The same holds across settings scopes: if user settings allow a permission and project settings deny it, the deny rule blocks it. The reverse is also true: a user-level deny blocks a project-level allow, because deny rules from any scope are evaluated before allow rules.

This precedence is between settings files and command line arguments. For whether a deny rule holds over a [mod](/docs/en/plugins/mods/overview) you install, see [Extend permissions with hooks](#extend-permissions-with-hooks).

Embedding hosts can supply additional managed policy via the SDK `managedSettings` option, including permission allow rules unless the admin sets the `allowManaged*Only` locks; [Deliver policy to Claude Desktop sessions](/docs/en/claude-apps-gateway#deliver-policy-to-claude-desktop-sessions) covers when embedder policy applies at all.

## Project allow rules and workspace trust

`permissions.allow` rules and `permissions.additionalDirectories` entries in a project's `.claude/settings.json` grant capability, so Claude Code applies them only after you accept the [workspace trust dialog](/docs/en/security#additional-safeguards) for that folder. The dialog lists the rules and directories the folder would grant so you can review them first. `deny` and `ask` rules aren't affected, since they only restrict.

Claude Code keys and stores the trust you accept according to where you start it:

* In a repository, Claude Code keys the trust on the git repository root, so the trust covers the whole repository apart from any git repository nested inside it, such as a submodule. In a [worktree](/docs/en/worktrees), it uses the main checkout's root, as it does for [saved rules](#permission-system).
* Outside a repository, Claude Code keys the trust on the directory you started it from, and the trust covers any subdirectory of that directory apart from a git repository nested inside it, such as a clone. Each covered subdirectory then counts as a folder whose parent you trusted.
* When you start in your home directory, Claude Code holds the trust for the current session only and doesn't write it to disk; see the [additional safeguards](/docs/en/security#additional-safeguards) note.

Claude Code shows the trust dialog in interactive sessions only. A `claude -p` run or an SDK session never shows it, and trusting a parent folder doesn't count for these rules, so [What runs before you trust a folder](#what-runs-before-you-trust-a-folder) says which repository content Claude Code still uses in each of those two situations.

Before it starts or restarts a [background session](/docs/en/agent-view), Claude Code also checks workspace trust for the directory the session runs in. If you run `claude --bg` from a terminal in a directory you haven't trusted, the trust dialog appears first and the session starts once you accept it. Where no dialog can appear, such as in a script, the command exits with a [`Workspace not trusted`](/docs/en/errors#workspace-not-trusted-when-dispatching-a-background-session) error instead.

### When your local settings file needs trust

`.claude/settings.local.json` is normally your own file, so Claude Code applies its allow rules and additional directories without the trust step. When the file is tracked in git, or `.claude` is a symlink, Claude Code treats it as repository-supplied instead and holds its rules until you trust the folder.

Claude Code runs git to tell the two apart, and it runs git only once you've trusted the folder: you accepted the trust dialog for it or for a parent directory whose trust extends to it, or you're in a `-p` or SDK session, which counts as accepted. Until then, where you started Claude Code decides what happens to the file's rules:

* **In your configuration home:** Claude Code applies that folder's `.claude/settings.local.json` right away without running git. Your configuration home is your home directory, or a directory whose `.claude` subdirectory you've set as [`CLAUDE_CONFIG_DIR`](/docs/en/env-vars#variables). If that `CLAUDE_CONFIG_DIR` directory sits inside a git repository and Claude Code [keeps your local settings at the repository root](/docs/en/settings#where-claude-code-looks-for-each-file) instead, it holds the rules like anywhere else.
* **Anywhere else:** Claude Code holds the file's rules like project settings. Once the check has run, Claude Code applies the rules of an untracked file, or of a file in a directory outside any git repository, even though you haven't trusted that exact folder.

<Note>
  The configuration-home exception skips only the trust step. `~/.claude/settings.local.json` is still [local scope](/docs/en/settings#compare-the-scope-of-each-settings-file), so Claude Code reads it only in sessions you start in your home directory itself, not in every project. To apply permission rules across all your projects, add them to your user settings instead: `~/.claude/settings.json`, or `$CLAUDE_CONFIG_DIR/settings.json` when `CLAUDE_CONFIG_DIR` is set.
</Note>

Before v2.1.207, Claude Code applied an untracked file's rules before you accepted the dialog.

### What runs before you trust a folder

Each row is one kind of content a repository can supply. The columns are the two situations in which you haven't trusted the folder itself: you trusted only a parent folder, or you ran `claude -p` or the SDK there, which never shows the trust dialog. The parent-folder column doesn't apply inside a [nested repository](#project-allow-rules-and-workspace-trust): in an interactive session Claude Code shows the trust dialog for it, and a `claude -p` or SDK run there follows the `claude -p` column.

| What the repository supplies | You trusted only a parent folder | `claude -p` or the SDK, folder never trusted |
| :- | :- | :- |
| [Hooks](/docs/en/hooks) in settings files, the [`env`](/docs/en/settings-reference#env) block and helper commands such as [`apiKeyHelper`](/docs/en/settings-reference#apikeyhelper), and a project skill's [hooks](/docs/en/hooks#hooks-in-skills-and-agents) and [`allowed-tools`](/docs/en/skills#pre-approve-tools-for-a-skill) | Used | Used. Workspace trust never gates a skill's `allowed-tools` in any session |
| `permissions.allow` rules and `additionalDirectories` in `.claude/settings.json` | Not used until you accept the trust dialog, which appears again listing them | Not used. Claude Code prints a [`this workspace has not been trusted`](/docs/en/errors#workspace-has-not-been-trusted) warning to stderr |
| Frontmatter hooks in a project [subagent](/docs/en/sub-agents#hooks-in-subagent-frontmatter), a project [`@skills-dir` plugin](/docs/en/plugins/loading#plugins-shared-through-a-repository), and [`extraKnownMarketplaces`](/docs/en/settings-reference#extraknownmarketplaces) entries from the repository or an `--add-dir` directory | Not used, and no dialog is offered | Not used |
| Inline [`mcpServers`](/docs/en/sub-agents#scope-mcp-servers-to-a-subagent) in the frontmatter of a subagent from the repository or an `--add-dir` directory | Not used, and no dialog is offered | Not used |
| Servers in `.mcp.json`, including ones the repository [approves in its own settings](/docs/en/mcp#project-server-approvals-and-workspace-trust) | Claude Code asks you before connecting them. The repository's own approvals don't count | Connected without asking, approved or not. The SDK loads them only when `settingSources` includes project settings. `claude mcp list` in the same folder still reports such a server as pending |
| A [`headersHelper`](/docs/en/mcp#trust-a-folder-before-its-headershelper-runs) on a server in `.mcp.json` | Not run until you accept the trust dialog, which appears again naming where the helper is declared. Claude Code connects the server with its static `headers` alone until then | Not run. Claude Code connects the server with its static `headers` alone and prints a [`headersHelper not run`](/docs/en/errors#headershelper-not-run) line per server to stderr |

For the rows that need this exact folder trusted, trust it by hand: set `projects["<path>"].hasTrustDialogAccepted` to `true` in `~/.claude.json`, where `<path>` is the repository root, or the folder itself outside a repository. Claude Code prints the exact key in the debug log line for a skipped subagent hook or inline MCP server, in the stderr warning for skipped allow rules, and in the `headersHelper not run` line for a skipped helper.

Before you run `claude -p` in a repository you didn't write, decide what it may run on your machine:

* Pass `--setting-sources user`, or set the SDK's `settingSources` without project settings, so Claude Code reads neither the project's settings files nor its `.mcp.json`
* Start with [`--bare`](/docs/en/headless#start-faster-with-bare-mode) so Claude Code reads no hooks, skills, custom commands, subagents, plugins, or `.mcp.json` servers from the project. The project's `env` block and helpers such as `awsAuthRefresh` in its settings files still apply, and Claude Code reads `apiKeyHelper` only from `--settings`
* Pass `--settings '{"disableAllHooks": true}'` to [turn hooks off](/docs/en/hooks#disable-or-remove-hooks) for that run. Setting it in your user settings alone isn't enough, because the repository's project settings take precedence over yours and can set it back to `false`
* Add a [`disabledMcpjsonServers`](/docs/en/settings-reference#disabledmcpjsonservers) entry to reject a `.mcp.json` server by name in every session type
