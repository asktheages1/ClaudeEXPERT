[Part 2/4 of https://code.claude.com/docs/en/permissions.md, fetched 2026-10-08]

### PowerShell

PowerShell permission rules use the same shape as Bash rules. Wildcards with `*` match at any position, the `:*` suffix is equivalent to a trailing ` *`, and a bare `PowerShell` or `PowerShell(*)` matches every command. This configuration allows `Get-ChildItem` and `git commit` commands while blocking `Remove-Item`:

```json theme={null}
{
  "permissions": {
    "allow": [
      "PowerShell(Get-ChildItem *)",
      "PowerShell(git commit *)"
    ],
    "deny": [
      "PowerShell(Remove-Item *)"
    ]
  }
}
```

Common aliases are canonicalized before matching. A rule written for the cmdlet name also matches its aliases, so `PowerShell(Get-ChildItem *)` matches `gci`, `ls`, and `dir` as well. Matching is case-insensitive.

Claude Code parses the PowerShell AST and checks each command in a compound command independently. Pipeline operators `|`, statement separators `;`, and on PowerShell 7+ the chain operators `&&` and `||` split a compound command into subcommands. A rule must match every subcommand for the compound command to be allowed.

### Read and Edit

To block Claude's file tools from reading a file or directory, add a `Read` deny rule for its path, such as `Read(./.env)` or `Read(./secrets/**)`; [Exclude sensitive files](/docs/en/settings-reference#exclude-sensitive-files) has a paste-ready example. If your project has a `.claudeignore` file, it has no effect, so move its entries into `Read` deny rules.

`Edit` rules apply to all built-in tools that edit files. Claude makes a best-effort attempt to apply `Read` rules to all built-in tools that read files like Grep and Glob, to `@file` mentions in your prompts, and to the selection and open-file context that a connected [IDE](/docs/en/vs-code#the-built-in-ide-mcp-server) shares with Claude.

A `Read` deny rule also blocks the [Edit and Write tools](/docs/en/errors#file-is-covered-by-a-read-deny-rule) on the same path, including creating a new file there. NotebookEdit isn't covered, so add an `Edit` deny rule for paths no tool may change. The check requires Claude Code v2.1.208 or later on edits, and v2.1.228 or later on writes.

Claude Code checks file permissions against `Edit(path)` and `Read(path)` rules only. If you write a path rule for `Write`, `NotebookEdit`, `Glob`, or the legacy `MultiEdit` tool instead, Claude Code accepts the rule but never consults it, and [warns at startup](/docs/en/errors#is-not-matched-by-file-permission-checks), except for a `Glob` rule passed in `--allowedTools`. Use `Edit(docs/**)` in place of `Write(docs/**)`, `NotebookEdit(docs/**)`, or `MultiEdit(docs/**)`, and `Read(docs/**)` in place of `Glob(docs/**)`. Claude Code doesn't warn about a tool-name rule with no path, such as a deny rule for `Write`; it matches that rule at the tool level everywhere. Requires Claude Code v2.1.210 or later.

<Warning>
  Read and Edit deny rules apply to Claude's built-in file tools, to file commands Claude Code recognizes in Bash, such as `cat`, `head`, `tail`, `sed`, and `tee`, and to the targets of Bash [redirections](#redirections) such as `> file` and `< file`. They don't apply to a command that reads files without naming them, such as `grep -r pattern .` run from the directory that holds the file, or to arbitrary subprocesses that read or write files indirectly, like a Python or Node script that opens files itself. For OS-level enforcement that blocks all processes from accessing a path, [enable the sandbox](/docs/en/sandboxing).
</Warning>

Read and Edit rules both use [gitignore](https://git-scm.com/docs/gitignore) pattern syntax with four distinct pattern types; for single-segment directory patterns, the matching depth also depends on the rule type, described later in this section:

| Pattern | Meaning | Example | Matches |
| - | - | - | - |
| `//path` | Absolute path from filesystem root | `Read(//Users/alice/secrets/**)` | `/Users/alice/secrets/**` |
| `~/path` | Path from home directory | `Read(~/Documents/*.pdf)` | `/Users/alice/Documents/*.pdf` |
| `/path` | Path relative to the settings source | `Edit(/src/**/*.ts)` | `<primary working directory>/src/**/*.ts` in project settings |
| `path` or `./path` | Path relative to current directory | `Read(*.env)` | `<cwd>/*.env` |

<Warning>
  A pattern like `/Users/alice/file` isn't an absolute path. The single leading slash anchors at the settings source, not the filesystem root. Use `//Users/alice/file` for absolute paths.
</Warning>

A `/path` pattern anchors at a directory associated with the settings source that defines it, so the same rule matches different locations depending on where you put it:

| Rule defined in | `/path` resolves to |
| :- | :- |
| Project settings at `.claude/settings.json` | `<primary working directory>/path` |
| Local settings at `.claude/settings.local.json` | `<primary working directory>/path` |
| User settings at `~/.claude/settings.json` | `~/.claude/path` |
| A file passed with `--settings <file>` | `<directory of file>/path` |
| CLI flags or session rules | `<primary working directory>/path` |

A rule you add through `/permissions` follows the row for the settings file you save it to.

Local settings rules anchor at the session's [primary working directory](#working-directories), not at the repository root where Claude Code [stores the file](#permission-system) in v2.1.211 and later. In a session started at the repository root, the two directories are the same; in a [worktree](/docs/en/worktrees) session, a shared rule such as `Edit(/src/**)` matches that worktree's own `src/` directory.

A deny rule such as `Read(/secrets/**)` in user settings blocks `~/.claude/secrets/**`, not a `secrets` directory in your project. To write a rule in user settings that applies inside every project, use a `//` absolute path or a `~/` home-relative path instead.

On Windows, paths are normalized to POSIX form before matching. `C:\Users\alice` becomes `/c/Users/alice`, so use `//c/**/.env` to match `.env` files anywhere on that drive. To match across all drives, use `//**/.env`.

Examples:

* `Edit(/docs/**)`: edits in `<primary working directory>/docs/`, not `/docs/` or `<primary working directory>/.claude/docs/`
* `Read(~/.zshrc)`: reads your home directory's `.zshrc`
* `Edit(//tmp/scratch.txt)`: edits the absolute path `/tmp/scratch.txt`
* `Read(src/**)`: as an allow rule, reads from `<current-directory>/src/` only; as a deny or ask rule, matches a `src` directory at any depth under the current directory

A rule only matches files under its anchor; within that bound, matching depth depends on the pattern shape and, for single-segment directory patterns, the rule type, described below. Bare filenames follow gitignore semantics and match at any depth, so `Read(.env)` and `Read(**/.env)` are equivalent:

| Deny rule | Blocks | Does not block |
| - | - | - |
| `Read(.env)` or `Read(**/.env)` | any `.env` at or under the current directory | `.env` in a parent directory or another project |
| `Read(//**/.env)` | any `.env` anywhere on the filesystem | nothing; the rule is anchored at the filesystem root |

A relative pattern with a single directory segment, such as `src/**`, matches at different depths depending on the rule type:

* **Allow rules**: `Edit(src/**)` matches only `<cwd>/src` and the files under it. To allow a directory name at any depth, write `Edit(**/src/**)`.
* **Deny and ask rules**: `Read(secrets/**)` matches a directory named `secrets` at any depth under the current directory, so the rule also applies to nested copies.

Every other pattern shape matches at the same depth in every rule type: `Edit(/src/**)` and `Edit(src/components/**)` match only at their anchored location, while `Edit(**/src/**)` matches at any depth.

The following example shows each pattern shape against a project with a top-level `src/` directory and a nested copy under `vendor/`:

```text theme={null}
<current-directory>/
├── src/
│   └── app.ts
└── vendor/
    └── pkg/
        └── src/
            └── lib.js
```

| Rule | Matches `src/app.ts` | Matches `vendor/pkg/src/lib.js` |
| :- | :- | :- |
| `Edit(src/**)` as an allow rule | Yes | No |
| `Edit(src/**)` as a deny or ask rule | Yes | Yes |
| `Edit(/src/**)` in any rule type | Yes | No |
| `Edit(**/src/**)` in any rule type | Yes | Yes |

<Note>
  In gitignore patterns, `*` matches within a single path segment and can appear at any position in the pattern, while `**` matches across directories.
</Note>

When you approve a file path with "Yes, and don't ask again", Claude Code escapes gitignore pattern characters in that path, such as `[`, `]`, and `*`, so the generated rule matches only the literal path you approved. Rules you write yourself aren't escaped. Before v2.1.202, Claude Code saved the path unescaped, so a generated rule for a directory named `[2024-06] Reports` could fail to match its own path or match unintended sibling directories.

You don't need to escape parentheses in a path, so `Edit(./Finance (2024)/**)` matches the `Finance (2024)` folder as spelled.

A deny or ask rule whose path isn't usable as a gitignore pattern still guards that exact path. An allow rule with an unusable pattern doesn't approve anything.

A deny or ask pattern that starts with `!` is a gitignore negation. It carves the paths it matches out of the `path` or `./path` rules listed before it. In one settings file's `deny` list, `Read(*.env)` followed by `Read(!sample.env)` blocks every file whose name ends in `.env` at any depth, except files named `sample.env`. A `!` rule listed first carves nothing out.

The carve-out reaches only rules from the same source. A `Read(!.env)` in project settings or in `--disallowedTools` doesn't cancel a `Read(./.env)` deny from managed settings or any other settings file.

Two limits narrow what a `!` pattern can carve out:

* Claude Code reads a `!` pattern relative to the current directory even when `/`, `~/`, or `//` follows the `!`, so the pattern can't reach a rule anchored with one of those prefixes. `Read(!~/notes/public/**)` carves nothing out of `Read(~/notes/**)`.
* A carve-out can't reopen a file inside a directory that a rule blocks as a whole. With `Read(secrets/**)` and `Read(!secrets/public/**)`, Claude Code still blocks `secrets/public` along with the rest of `secrets`.

#### Symlinks

When a file path Claude requests goes through a symlink, the permission check covers two paths: the one Claude requested and the file it resolves to. This applies to symbolic links on macOS, Linux, and Windows, and to directory junctions on Windows.

##### How rules match a symlinked path

Allow and deny rules treat the requested path and the file it resolves to differently:

* **Allow rules**: apply only when both the requested path and the file it resolves to match. A read through a symlink inside an allowed directory that points outside it doesn't match the rule.
* **Deny rules**: apply when either the requested path or the file it resolves to matches. A symlink that points to a denied file is itself denied. For example, with `Read(./project/**)` allowed and `Read(~/.ssh/**)` denied, a symlink at `./project/key` pointing to `~/.ssh/id_rsa` is blocked: the target fails the allow rule and matches the deny rule.

On macOS and Linux, a deny or ask rule written through a symlinked directory with a `//`, `~/`, or `/` pattern also applies at the directory's real location. For example, on macOS, where `/etc` resolves to `/private/etc`, `Read(//etc/**)` blocks `/private/etc/hosts` too. Before v2.1.268, a deny or ask rule written through a symlinked directory didn't apply to a path given by its real location.

Grep and Glob search the directory the `path` argument resolves to. Claude Code applies `Read` deny rules to that directory.

##### Writes through a symlink

If the path Claude asks to edit or write is itself a symlink, the Edit and Write tools [refuse the write and direct Claude to the link's target](/docs/en/errors#refusing-after-a-symlink-changed).

A write can still pass through a symlink when a directory on the way to the file is a symlink, or when a Bash or PowerShell command does the writing. For those writes, what happens depends on where the file the write resolves to sits relative to your [working directories](#working-directories) and the [protected paths](/docs/en/permission-modes#protected-paths):

* **Resolves outside the working directories**: when the requested path is inside your working directories and the file it resolves to isn't, the write isn't auto-approved in [`acceptEdits` mode](/docs/en/permission-modes#auto-approve-file-edits-with-acceptedits-mode). In [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode), unless an allow rule approves the write, you're prompted for it instead of the classifier deciding. The prompt names the path the write resolves to.
* **Resolves to a protected path that the requested path doesn't name**: the [protected paths table](/docs/en/permission-modes#protected-paths) gives the outcome for each permission mode, except that where the table routes the write to the classifier, this write prompts you instead.

##### Paths that can't be resolved or that change

When Claude Code can't determine where a path leads on disk, for example because symlinks on it form a loop, the Read, Edit, and Write tools [refuse the operation](/docs/en/errors#refusing-after-a-symlink-changed).

When a tool then opens the approved file, it [confirms that the path still resolves to the location the permission check approved](/docs/en/errors#refusing-after-a-symlink-changed).

### WebFetch

WebFetch rules use a `domain:` prefix and match against the hostname of the requested URL. Matching is case-insensitive, supports `*` wildcards, and strips a trailing `.` from both the rule and the hostname so `example.com.` and `example.com` are treated the same.

* `WebFetch(domain:example.com)` matches requests to `example.com`
* `WebFetch(domain:*.example.com)` matches any subdomain at any depth, such as `api.example.com` or `a.b.example.com`, but not `example.com` itself
* `WebFetch(domain:*)` matches every domain. It isn't the same as a bare `WebFetch` rule; see [Allow or deny every fetch](#allow-or-deny-every-fetch)

In any position other than a leading `*.` or a bare `*`, the wildcard matches only the text between two dots. `WebFetch(domain:example.*)` matches `example.org`, where `*` becomes `org`, but not `example.evil.com`, where `*` would have to become `evil.com` and cross a dot. This keeps a trailing wildcard from matching domains an attacker could register.

Wildcards in `WebFetch` rules require Claude Code v2.1.172 or later to match fetches.

#### Allow or deny every fetch

A bare `WebFetch` rule is the tool name with no `domain:` part, such as `"deny": ["WebFetch"]`. Both it and `WebFetch(domain:*)` cover every URL, but Claude Code applies them differently, and only the `domain:` form also adds its domain to the sandbox's [allowed or denied domain list](/docs/en/sandboxing#network-isolation). That section lists the wildcard forms the sandbox honors and the version that added bare `*`.

Each row shows what a rule does in the `allow` list and in the `deny` list:

| Rule | In `allow` | In `deny` |
| :- | :- | :- |
| `WebFetch` | Claude fetches without prompting you. Doesn't change which hosts sandboxed commands can reach. | Claude Code removes the `WebFetch` tool, so Claude can't fetch at all. Doesn't change which hosts sandboxed commands can reach. |
| `WebFetch(domain:*)` | Claude fetches without prompting you, and sandboxed commands can reach any host. | Claude Code keeps the tool and refuses each fetch, and sandboxed commands can't reach any host. |

The two forms also differ on reads of [artifacts](/docs/en/artifacts), the pages the Artifact tool publishes on claude.ai. A bare `WebFetch` deny or ask rule doesn't apply to those reads. A `domain:` rule covering `claude.ai` or the `*.claudeusercontent.com` content host, such as `WebFetch(domain:claude.ai)` or `WebFetch(domain:*)`, denies each read or prompts before it. An [`Artifact` rule](/docs/en/artifacts#disable-artifacts) does the same.

When a rule blocks a read, the denial names the rule. Before v2.1.268, a bare `WebFetch` deny rule blocked every artifact read, and a bare ask rule prompted before each one.

To let Claude fetch freely while keeping the sandbox allowlist as it is, use the bare form. This `settings.json` does that:

```json theme={null}
{
  "permissions": {
    "allow": ["WebFetch"]
  }
}
```

When you ask Claude to fetch a page, it fetches without a prompt. When you ask it to run a [sandboxed](/docs/en/sandboxing) `curl` against a host outside the sandbox allowlist, Claude Code still prompts you for that host, because the bare rule didn't add the host to the allowlist.

In [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode), Claude instead names the host in the command's [per-command allowed domains](/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode) for the classifier to review.

### MCP

MCP rules use the server name as configured in Claude Code, optionally followed by the name of a tool from that server.

* `mcp__puppeteer` matches any tool provided by the `puppeteer` server
* `mcp__puppeteer__*` uses wildcard syntax and also matches all tools from the `puppeteer` server
* `mcp__puppeteer__puppeteer_navigate` matches the `puppeteer_navigate` tool provided by the `puppeteer` server

If your organization has set a [claude.ai connector](/docs/en/mcp#organization-controls-on-connector-tools) tool to `ask` and that setting reaches Claude Code in your session, allow rules for that tool don't take effect: Claude Code prompts on every call, even in `auto` and `bypassPermissions` modes. In `dontAsk` mode, which never prompts, Claude Code denies the call instead. Tools from connectors Claude Code fetches itself appear as `mcp__claude_ai_<server>__<tool>`.

In a [Cowork](https://claude.com/docs/cowork/overview) session in the Claude Desktop app, Claude runs shell commands through Cowork's `mcp__workspace__bash` tool rather than the built-in `Bash` tool, and Cowork likewise provides `mcp__workspace__web_fetch` for web fetches. Claude Code also applies deny rules that name the whole `Bash` or `WebFetch` tool to these Cowork tools, so a managed `Bash` deny rule stops Claude from running shell commands in Cowork. When Claude Code blocks such a call, the message names the Cowork tool: `Permission to use mcp__workspace__bash has been denied.` Allow rules don't carry over: Claude Code never applies a `Bash` allow rule to `mcp__workspace__bash`.

### Agent (subagents)

Use `Agent(AgentName)` rules to control which [subagents](/docs/en/sub-agents) Claude can use:

* `Agent(Explore)` matches the Explore subagent
* `Agent(Plan)` matches the Plan subagent
* `Agent(my-custom-agent)` matches a custom subagent named `my-custom-agent`

Add these rules to the `deny` array in your settings or use the `--disallowedTools` CLI flag to disable specific agents. To disable the Explore agent:

```json theme={null}
{
  "permissions": {
    "deny": ["Agent(Explore)"]
  }
}
```

### Cd

`Cd` rules control which directories the [`/cd` command](/docs/en/commands) can move the session to. `Cd` is not a model-invocable tool: Claude can't call it, and the rules apply only when you run `/cd` yourself.

A bare `Cd` deny rule disables `/cd` entirely. A `Cd(<path-pattern>)` deny rule blocks matching targets. Deny rules check every spelling of the target, including each symlink hop it resolves through, so a rule written for one path also blocks targets that resolve to it.

Adding any `Cd` allow rule switches `/cd` to allowlist mode: the resolved target directory must match one of your allow rules, or `/cd` refuses. With no `Cd` rules configured, `/cd` keeps its default behavior and prompts you to trust an unfamiliar directory.

Path patterns share the `//`, `~/`, and `/` anchors from [Read and Edit rules](#read-and-edit), but matching is anchored to the whole directory path rather than gitignore-style. `*` matches exactly one path segment and `**` matches across segments. A trailing `/**` also matches its named root.

| Rule | Matches | Does not match |
| - | - | - |
| `Cd(~/code/*)` | `~/code/app` | `~/code/app/src`, `~/code` |
| `Cd(~/code/**)` | `~/code` and any directory under it | directories outside `~/code` |
| `Cd(**/node_modules)` | any `node_modules` directory at any depth under the current directory | `node_modules/pkg` |

## Extend permissions with hooks

[Claude Code hooks](/docs/en/hooks-guide) let you register custom shell commands that evaluate permissions at runtime. When Claude Code makes a tool call, PreToolUse hooks run before the permission prompt, for every tool except [`EndConversation`](/docs/en/tools-reference#endconversation-tool-behavior). The hook output can deny the tool call, force a prompt, or skip the prompt to let the call proceed.

PreToolUse hook decisions don't bypass permission rules. Claude Code evaluates deny and ask rules regardless of what a PreToolUse hook returns: a matching deny rule blocks the call, and a matching ask rule still prompts even when the hook returned `"allow"` or `"ask"`. This preserves the deny-first precedence described in [Manage permissions](#manage-permissions), including deny rules set in managed settings.

That precedence covers hooks in settings files and in a plugin's `hooks/hooks.json`. A [mod](/docs/en/plugins/mods/overview) you install that handles `tool.check` answers after the rules and the `PreToolUse` hooks have decided, and its answer can replace theirs:

* **Ask rules**: the mod can approve a call that an ask rule would prompt for
* **A block from a `PreToolUse` hook**: the mod can approve the call, unless the hook is in managed settings
* **The auto mode classifier**: in [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode), a call the mod approves runs without a classifier check
* **Deny rules**: on a machine with managed settings, or when you're signed in with a Team or Enterprise plan, deny rules hold over the mod by default, and your organization can change that. Anywhere else, the mod can approve a call that a deny rule refuses.

See [Decide whether to trust a mod](/docs/en/plugins/mods/overview#decide-whether-to-trust-a-mod), or [Manage mods for your organization](/docs/en/plugins/mods/admin#know-what-happens-by-default) if you deploy managed settings.

MCP tools marked [`requiresUserInteraction`](/docs/en/mcp#require-approval-for-a-specific-tool) also still prompt when a hook returns `"allow"`, as do connector tools [your organization set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code.

A blocking hook also takes precedence over allow rules. A hook that exits with code 2 stops the tool call before permission rules are evaluated, so the block applies even when an allow rule would otherwise let the call proceed. To run all Bash commands without prompts except for a few you want blocked, add `"Bash"` to your allow list and register a PreToolUse hook that rejects those specific commands. See [Block edits to protected files](/docs/en/hooks-guide#block-edits-to-protected-files) for a hook script you can adapt.
