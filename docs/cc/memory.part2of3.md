[Part 2/3 of https://code.claude.com/docs/en/memory.md, fetched 2026-10-08]

### Manage CLAUDE.md for large teams

For organizations deploying Claude Code across teams, you can centralize instructions and control which CLAUDE.md files are loaded.

#### Deploy organization-wide CLAUDE.md

Organizations can deploy a centrally managed CLAUDE.md that applies to all users on a machine. This file cannot be excluded by individual settings.

<Steps>
  <Step title="Create the file at the managed policy location">
    * macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`
    * Linux and WSL: `/etc/claude-code/CLAUDE.md`
    * Windows: `C:\Program Files\ClaudeCode\CLAUDE.md`
  </Step>

  <Step title="Deploy with your configuration management system">
    Use MDM, Group Policy, Ansible, or similar tools to distribute the file across developer machines. See [managed settings](/docs/en/managed-settings) for other organization-wide configuration options.
  </Step>
</Steps>

The `claudeMd` key lets you put managed CLAUDE.md content directly inside `managed-settings.json` instead of deploying a separate file.

**Scope**: every Claude Code session on the machine, in every repository. For repository-specific guidance, commit a project CLAUDE.md instead.

**Precedence**: same as a managed CLAUDE.md file. Loads before user and project CLAUDE.md.

**Where it's honored**: managed and policy settings only. Setting `claudeMd` in user, project, or local settings has no effect.

The example below adds behavioral instructions directly in a managed settings file:

```json theme={null}
{
  "claudeMd": "Always run `make lint` before committing.\nNever push directly to main."
}
```

A managed CLAUDE.md and [managed settings](/docs/en/managed-settings) serve different purposes. Use settings for technical enforcement and CLAUDE.md for behavioral guidance:

| Concern | Configure in |
| :- | :- |
| Block specific tools, commands, or file paths | Managed settings: `permissions.deny` |
| Enforce sandbox isolation | Managed settings: `sandbox.enabled` |
| Environment variables and API provider routing | Managed settings: `env` |
| Login method and organization restrictions | Managed settings: `forceLoginMethod`, `forceLoginOrgUUID` |
| Code style and quality guidelines | Managed CLAUDE.md |
| Data handling and compliance reminders | Managed CLAUDE.md |
| Behavioral instructions for Claude | Managed CLAUDE.md |

Settings rules are enforced by the client regardless of what Claude decides to do. CLAUDE.md instructions shape Claude's behavior but are not a hard enforcement layer.

#### Exclude specific CLAUDE.md files

In large monorepos, ancestor CLAUDE.md files may contain instructions that aren't relevant to your work. The `claudeMdExcludes` setting lets you skip specific files by path or glob pattern.

This example excludes a top-level CLAUDE.md and a rules directory from a parent folder. Add it to `.claude/settings.local.json` so the exclusion stays local to your machine:

```json theme={null}
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/monorepo/other-team/.claude/rules/**"
  ]
}
```

Patterns are matched against absolute file paths using glob syntax. You can configure `claudeMdExcludes` at any [settings layer](/docs/en/settings#where-settings-live): user, project, local, or managed policy. Arrays merge across layers.

To exclude a rules file you reach through a [symlink](#share-rules-across-projects-with-symlinks), whether the file or its directory is the link, write the pattern against either path: the file's path under `.claude/rules/` or its link target. A pattern that matches either path excludes the file. Before v2.1.239, only a pattern that matched the link target excluded the file.

Managed policy CLAUDE.md files cannot be excluded. This ensures organization-wide instructions always apply regardless of individual settings.

## AGENTS.md

Claude Code can read [`AGENTS.md`](/docs/en/glossary#agents-md) as your project instructions, so a repository already set up for other coding agents works without adding a `CLAUDE.md`, an import, or a setting. This table shows what Claude reads by default for each combination of instruction files in your repository:

| Your repository has | Claude reads |
| :- | :- |
| An `AGENTS.md`, and no `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it | Your `AGENTS.md` |
| An `AGENTS.md` and a `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it | Your `CLAUDE.md` files only |
| A `CLAUDE.md` that already [imports `AGENTS.md`](#share-one-file-with-other-coding-tools) | Your `CLAUDE.md`, with `AGENTS.md` included through the import |

To change the default, for example to have Claude always read both files, read only `CLAUDE.md`, or read only your organization's managed instructions, [change the **Project instructions** setting](#choose-which-instruction-files-load).

<Note>
  Reading `AGENTS.md` directly requires Claude Code v2.1.277 or later. In some sessions Claude [can't read `AGENTS.md`](#when-agents-md-support-is-unavailable), so [import it from a `CLAUDE.md`](#share-one-file-with-other-coding-tools) there instead.
</Note>

### When Claude Code reads AGENTS.md

By default, Claude reads `AGENTS.md` only when you have no `CLAUDE.md` in your working directory or above it. Here's which of your files count for that check:

* **Count, so Claude reads them instead of `AGENTS.md`**: a `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in your working directory or any directory above it
* **Don't count, and keep loading alongside `AGENTS.md`**: your `~/.claude/CLAUDE.md`, your organization's managed `CLAUDE.md`, and `.claude/rules/` files

When none count, here's what Claude reads and how you can tell:

* **At session start**: every `AGENTS.md` and `.claude/AGENTS.md` in your working directory and the directories above it. In an interactive session you see a line such as `no CLAUDE.md found; AGENTS.md loaded: /home/you/repo/AGENTS.md` in the conversation
* **As Claude works in subdirectories**: a subdirectory's `AGENTS.md`, when Claude opens a file there with the Read tool and that subdirectory has none of the three `CLAUDE.md` files of its own
* **Inside each `AGENTS.md`**: [`@path` imports](#import-additional-files) are expanded, [`claudeMdExcludes`](#exclude-specific-claude-md-files) patterns apply, and subagents that [skip project instructions](/docs/en/sub-agents#what-loads-at-startup) skip these files too
* **Not read**: `AGENTS.local.md`, `AGENTS.override.md`, or anything under a `.agents/` directory

<Note>
  Because `CLAUDE.local.md` counts, adding one to keep your own uncommitted instructions in a project that relies on `AGENTS.md` stops Claude from reading `AGENTS.md` for you. To keep your `CLAUDE.local.md` and still have Claude read `AGENTS.md`, set **Project instructions** to [`claude-md-and-agents-md`](#choose-which-instruction-files-load).
</Note>

### Choose which instruction files load

To change which files Claude reads, type `/config` in a Claude Code session to open the settings panel, then set **Project instructions** to one of these values:

| Value | What Claude reads |
| :- | :- |
| `claude-md-or-agents-md` | Your `CLAUDE.md` files, or your `AGENTS.md` files when you have no `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it. This is the default |
| `claude-md-and-agents-md` | Your `CLAUDE.md` and `AGENTS.md` files together, each directory's `CLAUDE.md` files first and its `AGENTS.md` after them. Claude Code skips an `AGENTS.md` it has already loaded, so one that your `CLAUDE.md` imports or symlinks to isn't read twice |
| `claude-md` | Your `CLAUDE.md` files only |
| `managed-only` | Only your organization's managed `CLAUDE.md` and [auto memory](#auto-memory) at launch. Your project, local, and user `CLAUDE.md` files, your `.claude/rules/` files, and every `AGENTS.md` are left out. A subdirectory's `CLAUDE.md` and `.claude/rules/` files, and [path-scoped rules](#path-specific-rules), still load on demand |

You can also set the value in a settings file instead of `/config`. Add it to [`pluginConfigs`](/docs/en/settings-reference#pluginconfigs) under `cc-plugin-agents-md@builtin`, the ID of the built-in plugin that reads `AGENTS.md`. Claude Code reads the entry from `~/.claude/settings.json`, a `--settings` file, or [managed settings](/docs/en/managed-settings), and ignores it in project and local settings files. This example has Claude read both files:

```json settings.json theme={null}
{
  "pluginConfigs": {
    "cc-plugin-agents-md@builtin": {
      "options": { "instructionFiles": "claude-md-and-agents-md" }
    }
  }
}
```

Before v2.1.285, the plugin's ID was `agents-md@builtin`, and Claude Code ignored an entry under `cc-plugin-agents-md@builtin`. If earlier versions also read your settings file, use `agents-md@builtin` there. Claude Code v2.1.285 and later reads an entry under either ID.

Your change applies from the next message you send and in every new session.

### When AGENTS.md support is unavailable

In these sessions Claude reads `CLAUDE.md` files only, and **Project instructions** doesn't appear in the `/config` settings panel:

* You're on a Claude Code version before v2.1.277
* You used `/plugin` to disable the built-in plugin that reads `AGENTS.md`
* In some cases, it's your [first session after you upgrade](/docs/en/env-vars#first-session-after-an-install-or-upgrade) from v2.1.276 or earlier. Claude reads `AGENTS.md` from your next session on

Before v2.1.281, some sessions, such as those on Amazon Bedrock or with telemetry disabled, read `CLAUDE.md` files only. On those versions, update Claude Code. To give Claude your `AGENTS.md` in any of these sessions, [import it from a `CLAUDE.md`](#share-one-file-with-other-coding-tools).

### Where AGENTS.md differs from CLAUDE.md

An `AGENTS.md` that Claude reads through the **Project instructions** setting differs from a `CLAUDE.md` in these places:

| | `CLAUDE.md` | `AGENTS.md` read through the setting |
| :- | :- | :- |
| [`InstructionsLoaded` hooks](/docs/en/hooks#instructionsloaded) | Fire | Don't fire. They fire as usual for an `AGENTS.md` that a `CLAUDE.md` imports or symlinks to |
| Directories you add with `--add-dir` while [`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD`](#load-from-additional-directories) is set | Their `CLAUDE.md` loads | Their `AGENTS.md` doesn't load |
| An `@path` import of a file outside your working directory | Claude Code asks you to approve [external imports](#import-additional-files) | Loads only if you already approved external imports for this project, with no prompt |

### Remove an earlier AGENTS.md workaround

If you set Claude Code up to read `AGENTS.md` before it did so on its own, here's what to do with each common setup:

* **A `CLAUDE.md` containing `@AGENTS.md`**: you can leave it. Keeping the import never makes Claude read `AGENTS.md` twice, whichever **Project instructions** value you use. Remove the `CLAUDE.md` if it holds nothing else, or keep it if some of your sessions [can't load `AGENTS.md` directly](#when-agents-md-support-is-unavailable).
* **A `CLAUDE.md` that tells Claude in words to read `AGENTS.md`**: Claude sees `AGENTS.md` only if it decides to open the file. Delete the `CLAUDE.md` so Claude reads `AGENTS.md` directly, or replace the sentence with an `@AGENTS.md` import.
* **A `CLAUDE.md` symlinked to `AGENTS.md`**: nothing, or delete the symlink. Either way Claude reads the content once.
* **A `SessionStart` hook that prints `AGENTS.md`**: remove it. Once Claude reads `AGENTS.md` directly, the hook adds a second copy to the context.

### Share one file with other coding tools

When Claude isn't reading your `AGENTS.md` directly, you can still keep it as the one file every tool shares by putting an `@AGENTS.md` import in a `CLAUDE.md` next to it. Do this when your project also has a `CLAUDE.md`, when you've set **Project instructions** to `claude-md`, or in sessions that [can't load `AGENTS.md`](#when-agents-md-support-is-unavailable). Add any Claude-specific instructions below the import, and Claude reads the imported file first, then the rest:

```markdown CLAUDE.md theme={null}
@AGENTS.md

## Claude Code

Use plan mode for changes under `src/billing/`.
```

If you don't need Claude-specific content, a symlink also works:

```bash theme={null}
ln -s AGENTS.md CLAUDE.md
```

The command prints no output on success. Before you choose the symlink over the import, check these constraints:

* **Editing**: Claude reads `CLAUDE.md` through the link, but the Edit and Write tools [refuse to write through a symlink](/docs/en/errors#refusing-after-a-symlink-changed), and the refusal directs Claude to edit the link's target, `AGENTS.md`, instead
* **Windows**: if you or anyone who clones the repository works on Windows, use the `@AGENTS.md` import instead. Creating a symlink there needs Administrator privileges or Developer Mode, and Git checks a committed symlink out as a plain text file unless `core.symlinks` is enabled, which leaves that clone with a one-line `CLAUDE.md` in place of your instructions

With either approach, run `/context` in your next session and confirm `CLAUDE.md` appears under **Memory files**.

### Migrate instructions from other tools

Running [`/init`](/docs/en/commands) reads other tools' instruction files and incorporates the relevant parts into the generated `CLAUDE.md`:

* Cursor rules in `.cursor/rules/` or `.cursorrules`
* Copilot rules in `.github/copilot-instructions.md`
* With `CLAUDE_CODE_NEW_INIT=1` set: `AGENTS.md`, `.devin/rules/`, `.windsurf/rules/` or `.windsurfrules`, and `.clinerules`

You can also run [`/import`](/docs/en/commands) to bring a supported coding agent's configuration into Claude Code, which appends a one-time copy of instruction files such as `AGENTS.md` to the matching `CLAUDE.md` and carries over MCP servers, commands, subagents, and skills. Requires Claude Code v2.1.213 or later.

## Auto memory

Auto memory lets Claude accumulate knowledge across sessions without you writing anything. As it works, Claude saves four kinds of notes for itself. Claude records the kind as a `type` field in the memory file's frontmatter:

* `user`: your role, expertise, and working preferences
* `feedback`: corrections you give Claude and approaches you confirm
* `project`: ongoing work, deadlines, and decisions that Claude can't derive from the code or git history
* `reference`: where to find information outside the project, such as an issue tracker or dashboard

Claude skips anything it can derive from the codebase, such as architecture, file paths, or debugging fixes. It also skips anything your CLAUDE.md files already say.

Claude doesn't save something every session. It decides what's worth remembering based on whether the information would be useful in a future conversation.

### Enable or disable auto memory

Auto memory is on by default in local sessions. Outside [Claude Tag](https://claude.com/docs/claude-tag/overview) sessions, a session in a [self-hosted environment](/docs/en/self-hosted-environments-configuration#how-each-session’s-config-is-assembled) runs with auto memory off by default.

To toggle it, open `/memory` in a session and use the auto memory toggle, which saves `autoMemoryEnabled` to your user settings at `~/.claude/settings.json`.

The toggle turns auto memory off but doesn't turn it back on in these sessions:

* A [background session](/docs/en/agent-view)
* A session that another Claude Code session started, such as when Claude runs `claude` through its Bash tool

While auto memory is off there, the toggle reads `off · can't be turned on here; use a session started outside Claude Code`. To turn auto memory back on, run `claude` directly in your terminal and use the `/memory` toggle in that session.

To turn it off for a single project, set `autoMemoryEnabled` in that project's settings:

```json theme={null}
{
  "autoMemoryEnabled": false
}
```

To disable auto memory via environment variable, set `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

### Storage location

Each project gets its own memory directory at `~/.claude/projects/<project>/memory/`. The `<project>` path is derived from the git repository, so all worktrees and subdirectories within the same repo share one auto memory directory. Outside a git repo, the project root is used instead.

If you set [`CLAUDE_CODE_PROJECT_DIR_NAME`](/docs/en/sessions#name-the-project-directory-yourself) beside `CLAUDE_CONFIG_DIR`, Claude Code uses that name as the `<project>` directory under `<config dir>/projects/` instead, whichever repository you launch it in, so projects launched with that config directory share one auto memory directory. Requires Claude Code v2.1.234 or later.

To store auto memory in a different location, set `autoMemoryDirectory` in your `settings.json`. It is read from any [settings scope](/docs/en/settings#settings-precedence): user, project, local, policy, or `--settings`.

```json theme={null}
{
  "autoMemoryDirectory": "~/my-custom-memory-dir"
}
```

The value must be an absolute path or start with `~/`.

When you set it in a project's `.claude/settings.json` or `.claude/settings.local.json`, Claude Code honors it under the same [workspace trust rule as hooks in settings files](/docs/en/permissions#what-runs-before-you-trust-a-folder). While [`permissions.blockReadsOutsideWorkingDirectories`](/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) is on, Claude Code loads no auto memory from a directory that a [repository-supplied settings file](/docs/en/permissions#when-your-local-settings-file-needs-trust) chooses and saves none to it, wherever that directory sits.

The directory contains a `MEMORY.md` index and one topic file per memory:

```text theme={null}
~/.claude/projects/<project>/memory/
├── MEMORY.md           # Index, one line per memory, loaded into every session
├── user_role.md        # One memory
├── feedback_testing.md # One memory
└── ...                 # Any other topic files Claude creates
```

`MEMORY.md` acts as an index of the memory directory. Claude reads and writes files in this directory throughout your session, using `MEMORY.md` to keep track of what's stored where.

Auto memory is machine-local. All worktrees and subdirectories within the same git repository share one auto memory directory. Files are not shared across machines or cloud environments.

Claude Code deletes old session transcripts after the [`cleanupPeriodDays`](/docs/en/settings-reference#cleanupperioddays) retention period, but excludes the memory files in the memory directory from that [retention sweep](/docs/en/claude-directory#cleaned-up-automatically). `MEMORY.md` and topic files stay until you or Claude edits or deletes them.

### How it works

The first 200 lines of `MEMORY.md`, or the first 25KB, whichever comes first, are loaded at the start of every conversation. Content beyond that threshold is not loaded at session start. Claude keeps `MEMORY.md` concise by moving detailed notes into separate topic files.

After Claude writes to `MEMORY.md`, Claude Code measures the file against the 200-line and 25KB read limits. If the file is near a limit, Claude Code reminds Claude to shorten it: keep one line per entry, move detail into topic files, and merge or drop stale entries. If the file is over a limit, the write still succeeds, but Claude Code returns an [error telling Claude to rewrite the index](/docs/en/errors#memory-index-is-over-its-read-limit), because everything past the limit is dropped on the next load.

This limit applies only to `MEMORY.md`. Claude Code loads a CLAUDE.md file of up to 4 MiB in full and skips a larger file. Shorter files produce better adherence.

Claude Code doesn't load topic files such as `user_role.md` or `feedback_testing.md` at startup. Claude reads them on demand using its standard file tools when it needs the information.

The main conversation's auto memory isn't loaded into [subagents](/docs/en/sub-agents#what-loads-at-startup); the exception is a [fork](/docs/en/sub-agents#fork-the-current-conversation), which inherits the parent conversation and system prompt. A subagent's own auto memory, enabled with the subagent `memory` field, is a separate directory.

Claude reads and writes memory files during your session. When you see messages like "Saved 2 memories" or "Recalled 2 memories" in the Claude Code interface, Claude is actively updating or reading from `~/.claude/projects/<project>/memory/`.

When Claude writes a memory file that begins with YAML frontmatter, Claude Code records the write time in a `modified` frontmatter field as an ISO 8601 timestamp. The timestamp shows how current the fact is, both to you and to Claude when it reads the memory back. Any file that has frontmatter gets the field the next time Claude writes it, including files created on earlier versions; Claude Code never adds frontmatter to a file that has none. The `modified` field requires Claude Code v2.1.214 or later.

### Audit and edit your memory

Auto memory files are plain markdown you can edit or delete at any time. Run [`/memory`](#view-and-edit-with-%2Fmemory) to browse and open memory files from within a session.

## View and edit with `/memory`

The `/memory` command lists your CLAUDE.md, CLAUDE.local.md, and other memory file locations across user and project scopes, including user and project CLAUDE.md entries for files that don't exist yet. It also lets you toggle auto memory on or off and provides an option to open the auto memory folder. Select any file to open it in your editor; selecting one that doesn't exist yet creates it first. To check which `CLAUDE.md` and rules files loaded at launch, run `/context`.

GUI editors such as VS Code open the file in a separate window, and you can keep using the session while it's open. Before v2.1.216, `/memory` waited for you to close the file before responding. Terminal editors such as Vim take over the terminal until you exit.

When you ask Claude to remember something, like "always use pnpm, not npm" or "remember that the API tests require a local Redis instance," Claude saves it to auto memory. To add instructions to CLAUDE.md instead, ask Claude directly, like "add this to CLAUDE.md," or edit the file yourself via `/memory`.
