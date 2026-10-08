[Part 1/3 of https://code.claude.com/docs/en/memory.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# How Claude remembers your project

> Give Claude persistent instructions with CLAUDE.md or AGENTS.md files, and let Claude accumulate learnings automatically with auto memory.

Each Claude Code session begins with a fresh context window. Two mechanisms carry knowledge across sessions:

* **CLAUDE.md files**: instructions you write to give Claude persistent context. Claude can also read a repository's [`AGENTS.md` files](#agents-md) in place of CLAUDE.md
* **Auto memory**: notes Claude writes itself based on your corrections and preferences

This page covers how to:

* [Write and organize CLAUDE.md files](#claude-md-files)
* [Use an existing AGENTS.md](#agents-md) as your project instructions
* [Scope rules to specific file types](#organize-rules-with-claude/rules/) with `.claude/rules/`
* [Configure auto memory](#auto-memory) so Claude takes notes automatically
* [Troubleshoot](#troubleshoot-memory-issues) when instructions aren't being followed

## CLAUDE.md vs auto memory

Claude Code has two complementary memory systems. Both are loaded at the start of every conversation. Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a [PreToolUse hook](/docs/en/hooks-guide) instead. The more specific and concise your instructions, the more consistently Claude follows them.

| | CLAUDE.md files | Auto memory |
| :- | :- | :- |
| **Who writes it** | You | Claude |
| **What it contains** | Instructions and rules | Learnings and patterns |
| **Scope** | Project, user, or org | Per repository, shared across worktrees |
| **Loaded into** | Every session | Every session (first 200 lines or 25KB) |
| **Use for** | Coding standards, workflows, project architecture | Your preferences, corrections you give Claude, project context Claude can't derive from the code |

Use CLAUDE.md files when you want to guide Claude's behavior. Auto memory lets Claude learn from your corrections without manual effort.

Subagents can also maintain their own auto memory. See [subagent configuration](/docs/en/sub-agents#enable-persistent-memory) for details.

## CLAUDE.md files

CLAUDE.md files are markdown files that give Claude persistent instructions for a project, your personal workflow, or your entire organization. You write these files in plain text; Claude reads them at the start of every session. If your repository uses `AGENTS.md` instead, see [AGENTS.md](#agents-md).

### When to add to CLAUDE.md

Treat CLAUDE.md as the place you write down what you'd otherwise re-explain. Add to it when:

* Claude makes the same mistake a second time
* A code review catches something Claude should have known about this codebase
* You type the same correction or clarification into chat that you typed last session
* A new teammate would need the same context to be productive

Keep it to facts Claude should hold in every session: build commands, conventions, project layout, "always do X" rules. If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a [skill](/docs/en/skills) or a [path-scoped rule](#organize-rules-with-claude/rules/) instead. The [extension overview](/docs/en/features-overview#build-your-setup-over-time) covers when to use each mechanism.

### Choose where to put CLAUDE.md files

CLAUDE.md files can live in several locations, each with a different scope. The table below lists them in load order, from broadest scope to most specific, so a project instruction appears in context after a user instruction.

| Scope | Location | Purpose | Use case examples | Shared with |
| - | - | - | - | - |
| **Managed policy** | • macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br />• Linux and WSL: `/etc/claude-code/CLAUDE.md`<br />• Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide instructions managed by IT/DevOps | Company coding standards, security policies, compliance requirements | All users in organization |
| **User instructions** | `~/.claude/CLAUDE.md` | Personal preferences for all projects | Code styling preferences, personal tooling shortcuts | Only you (all projects) |
| **Project instructions** | `./CLAUDE.md` or `./.claude/CLAUDE.md`. See [AGENTS.md](#agents-md) for when `./AGENTS.md` loads instead of or alongside them | Team-shared instructions for the project | Project architecture, coding standards, common workflows | Team members via source control |
| **Local instructions** | `./CLAUDE.local.md` | Personal project-specific preferences; add to `.gitignore` | Your sandbox URLs, preferred test data | Only you (current project) |

CLAUDE.md and CLAUDE.local.md files in the directory hierarchy above the working directory are loaded at launch. Files in subdirectories load on demand. See [How CLAUDE.md files load](#how-claude-md-files-load) for when they load and the full resolution order.

For large projects, you can break instructions into topic-specific files using [project rules](#organize-rules-with-claude/rules/). Rules let you scope instructions to specific file types or subdirectories.

### Set up a project CLAUDE.md

A project CLAUDE.md can be stored in either `./CLAUDE.md` or `./.claude/CLAUDE.md`. Create this file and add instructions that apply to anyone working on the project: build and test commands, coding standards, architectural decisions, naming conventions, and common workflows. These instructions are shared with your team through version control, so focus on project-level standards rather than personal preferences. To confirm the file loaded, run `/context` in a session and check the list under **Memory files**.

<Tip>
  Run `/init` to generate a starting CLAUDE.md automatically. Claude analyzes your codebase and creates a file with build commands, test instructions, and project conventions it discovers. If a CLAUDE.md already exists, `/init` suggests improvements rather than overwriting it. Refine from there with instructions Claude wouldn't discover on its own.

  For an interactive multi-phase flow instead, set the `CLAUDE_CODE_NEW_INIT` environment variable to `1` before you run `/init`. Set it in your shell or in the `env` block of a settings file, as shown in [Set environment variables](/docs/en/env-vars#set-environment-variables). With it set, `/init` asks which artifacts to set up: CLAUDE.md files, skills, and hooks. It then explores your codebase with a subagent, fills in gaps via follow-up questions, and presents a reviewable proposal before writing any files. The variable only changes how `/init` runs, so you can leave it set.
</Tip>

### Write effective instructions

Claude treats CLAUDE.md files as context, not enforced configuration, so how you write instructions affects how reliably Claude follows them. Write instructions that are concrete enough to verify:

* "Use 2-space indentation" instead of "Format code properly"
* "Run `npm test` before committing" instead of "Test your changes"
* "API handlers live in `src/api/handlers/`" instead of "Keep files organized"

Keep your files short, organized, and consistent:

* **Size**: target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence. Move instructions that matter for only part of the codebase into [path-scoped rules](#path-specific-rules), which load only when Claude works with matching files. [Imports](#import-additional-files) help you organize a long file but don't reduce its context cost, because imported files also load at launch.
* **Structure**: group related instructions under markdown headers and bullets. Organized sections are easier for Claude to follow than dense paragraphs.
* **Consistency**: if two instructions contradict each other, Claude may pick one arbitrarily. Review your CLAUDE.md files, nested CLAUDE.md files in subdirectories, and [`.claude/rules/`](#organize-rules-with-claude/rules/) periodically to remove outdated or conflicting instructions. To have Claude find them for you, [run a prompt audit](#audit-your-instruction-files).

#### Audit your instruction files

To have Claude check your instruction files for outdated or conflicting content, run `/doctor prompt-audit` in a session. Claude looks for problems such as instructions written for older models, references to files or commands that don't exist, and files that contradict each other. You get a report of findings with proposed edits, and nothing in your files changes until you ask Claude to apply them.

By default, the audit covers your CLAUDE.md, CLAUDE.local.md, and AGENTS.md files, plus the rules, skills, commands, subagents, and output styles under `.claude/` and `~/.claude/`. To audit one file or directory instead, pass its path, for example `/doctor prompt-audit .claude/skills/deploy`.

The audit runs through the bundled `/claude-api` skill. It's unavailable while that skill is turned off in [`skillOverrides`](/docs/en/skills#override-skill-visibility-from-settings) or with [`disableBundledSkills`](/docs/en/settings-reference#disablebundledskills). `/doctor prompt-audit` requires Claude Code v2.1.283 or later.

### Import additional files

CLAUDE.md files can import additional files using `@path/to/import` syntax. Imported files are expanded and loaded into context at launch alongside the CLAUDE.md that references them.

Both relative and absolute paths are allowed. Relative paths resolve relative to the file containing the import, not the working directory. Imported files can recursively import other files, with a maximum depth of four hops.

To import a file whose path contains spaces, put a backslash before each space. Without the backslashes, the path ends at the first space, even when the import is on a line of its own. A path wrapped in quotes isn't imported at all, with or without the backslashes. This import loads a file from a folder named `Design Docs`:

```text theme={null}
- API conventions @Design\ Docs/api-conventions.md
```

Import parsing skips Markdown code spans and fenced code blocks. To mention a path in your CLAUDE.md without importing it, wrap it in backticks: writing `` `@README` `` keeps the text literal, while `@README` outside backticks imports the file.

To pull in a README, package.json, and a workflow guide, reference them with `@` syntax anywhere in your CLAUDE.md:

```text theme={null}
See @README for project overview and @package.json for available npm commands for this project.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

For private per-project preferences that shouldn't be checked into version control, create a `CLAUDE.local.md` at the project root. It loads alongside `CLAUDE.md` and is treated the same way. Add `CLAUDE.local.md` to your `.gitignore` so it isn't committed. With `CLAUDE_CODE_NEW_INIT=1` set, running `/init` and choosing the personal option does this for you.

If you work across multiple git worktrees of the same repository, a gitignored `CLAUDE.local.md` only exists in the worktree where you created it. To share personal instructions across worktrees, import a file from your home directory instead:

```text theme={null}
# Individual Preferences
- @~/.claude/my-project-instructions.md
```

<Warning>
  An import in a project-level memory file is external when its path resolves outside your working directory, like the home directory import above. The first time Claude Code encounters external imports in a project, it shows an approval dialog listing the files. If you decline, the imports stay disabled and the dialog doesn't appear again.

  Claude Code shows the dialog to protect you from files other people commit to a shared project. User-scope memory files, such as `~/.claude/CLAUDE.md` and `~/.claude/rules/`, are files you wrote yourself. Except in [Cowork](https://claude.com/product/cowork) sessions on your desktop, Claude Code loads their imports without the dialog and trusts them like the rest of your personal configuration.

  In Cowork sessions on your desktop, Claude Code skips any import in a user-scope file that resolves to a path outside the session's working directory and loads the rest of the file. In those sessions it also skips a `~/.claude/CLAUDE.md` that is itself a symlink or hard link, and a symlinked `~/.claude/rules/` directory or rule file that points outside the working directory.
</Warning>

### How CLAUDE.md files load

Claude Code loads `CLAUDE.md` and `CLAUDE.local.md` from your current working directory and every directory above it. Run Claude Code in `foo/bar/` and it loads instructions from `foo/bar/CLAUDE.md`, `foo/CLAUDE.md`, and any `CLAUDE.local.md` files alongside them.

All discovered files are concatenated into context rather than overriding each other. Across the directory tree, content is ordered from the filesystem root down to your working directory. For the `foo/bar/` example, `foo/CLAUDE.md` appears in context before `foo/bar/CLAUDE.md`, so instructions closer to where you launched Claude are read last. Within each directory, `CLAUDE.local.md` is appended after `CLAUDE.md`, so your personal notes are the last thing Claude reads at that level.

Claude also discovers `CLAUDE.md` and `CLAUDE.local.md` files in subdirectories under your current working directory. Instead of loading them at launch, Claude Code includes them when Claude uses the [Read](/docs/en/tools-reference#read-tool-behavior), [Write](/docs/en/tools-reference#write-tool-behavior), or [Edit](/docs/en/tools-reference#edit-tool-behavior) tool on a file in those subdirectories. If Claude already used one of those tools on a subdirectory's `CLAUDE.md` itself, that file isn't loaded this way, because Claude Code treats it as already in the conversation. For files inside a worktree under `.claude/worktrees/`, see [Isolate subagents with worktrees](/docs/en/worktrees#isolate-subagents-with-worktrees).

If you work in a large monorepo where other teams' CLAUDE.md files get picked up, use [`claudeMdExcludes`](#exclude-specific-claude-md-files) to skip them. For the full layout of root and per-directory CLAUDE.md files and rules, see [Monorepos and large repos](/docs/en/large-codebases).

Block-level HTML comments (`<!-- maintainer notes -->`) in CLAUDE.md files are stripped before the content is injected into Claude's context. Use them to leave notes for human maintainers without spending context tokens on them. Comments inside code blocks are preserved. When you open a CLAUDE.md file directly with the Read tool, comments remain visible.

#### Load from additional directories

The `--add-dir` flag gives Claude access to additional directories outside your main working directory. By default, CLAUDE.md files from these directories are not loaded.

To also load memory files from additional directories, set the `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` environment variable:

```bash theme={null}
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```

The inline form sets the variable for that one launch in Bash or Zsh. To keep it on for every session, add it to the `env` block in `~/.claude/settings.json` as shown in [Set environment variables](/docs/en/env-vars#set-environment-variables).

This loads `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, and `CLAUDE.local.md` from the additional directory. `CLAUDE.local.md` is skipped if you exclude `local` from [`--setting-sources`](/docs/en/cli-reference).

### Organize rules with `.claude/rules/`

For larger projects, you can organize instructions into multiple files using the `.claude/rules/` directory. This keeps instructions modular and easier for teams to maintain. Rules can also be [scoped to specific file paths](#path-specific-rules), so they only load into context when Claude works with matching files, reducing noise and saving context space.

<Note>
  Rules load into context every session or when matching files are opened. For task-specific instructions that don't need to be in context all the time, use [skills](/docs/en/skills) instead, which only load when you invoke them or when Claude determines they're relevant to your prompt.
</Note>

#### Set up rules

Place markdown files in your project's `.claude/rules/` directory. Each file should cover one topic, with a descriptive filename like `testing.md` or `api-design.md`. All `.md` files are discovered recursively, so you can organize rules into subdirectories like `frontend/` or `backend/`:

```text theme={null}
your-project/
├── .claude/
│   ├── CLAUDE.md           # Main project instructions
│   └── rules/
│       ├── code-style.md   # Code style guidelines
│       ├── testing.md      # Testing conventions
│       └── security.md     # Security requirements
```

Rules without [`paths` frontmatter](#path-specific-rules) are loaded at launch with the same priority as `.claude/CLAUDE.md`.

Project rules are skipped if you exclude `project` from [`--setting-sources`](/docs/en/cli-reference). Before v2.1.211, rules that load on demand, including path-scoped rules and rules in nested `.claude/rules/` directories, loaded even when `project` was excluded.

#### Path-specific rules

Rules can be scoped to specific files using YAML frontmatter with the `paths` field. These conditional rules only apply when Claude is working with files matching the specified patterns.

```markdown theme={null}
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- All API endpoints must include input validation
- Use the standard error response format
- Include OpenAPI documentation comments
```

Rules without a `paths` field are loaded unconditionally and apply to all files. Path-scoped rules trigger when Claude uses the Read, Write, or Edit tool on a file matching the pattern, not on every tool use. Matching also works when Claude reaches a file through a symlinked path to the project directory, for example in a symlinked checkout.

Use glob patterns in the `paths` field to match files by extension, directory, or any combination:

| Pattern | Matches |
| - | - |
| `**/*.ts` | All TypeScript files in any directory |
| `src/**/*` | All files under `src/` directory |
| `*.md` | Markdown files in the project root |
| `src/components/*.tsx` | React components in a specific directory |

You can specify multiple patterns and use brace expansion to match multiple extensions in one pattern:

```markdown theme={null}
---
paths:
  - "src/**/*.{ts,tsx}"
  - "lib/**/*.ts"
  - "tests/**/*.test.ts"
---
```

Each brace group multiplies the number of expanded patterns: `src/*.{ts,tsx}` expands to two patterns, and `{a,b}/{c,d}/*.{ts,tsx}` to eight. To keep expansion bounded, a rule's whole `paths` list shares one budget of 1,000 expanded patterns and 4 MiB, and patterns without braces don't count against it.

Claude Code uses any pattern that would exceed the budget unexpanded, and its literal braces match no files. Before v2.1.217, a `paths` value with many brace groups stalled or crashed the CLI at startup.

Glob syntax treats `[` as the start of a bracket expression such as `[abc]`. A pattern with a `[` that can't be read as a bracket expression, such as `photos [2024/**`, is invalid: it matches nothing, and the rule's other patterns keep working. To match a literal `[` in a file name, escape it as `photos \[2024/**`. Before v2.1.207, one invalid pattern made the Read tool fail for every file the rule was evaluated against, instead of matching nothing.

<h4 id="rules-frontmatter-reference">
  Rule frontmatter reference
</h4>

Configure a rule with YAML [frontmatter](/docs/en/glossary#frontmatter) between `---` markers at the top of the file. `paths` is the only field Claude Code reads from a rule; any other field is ignored without an error. Claude Code removes the frontmatter before loading the rule into context.

| Field | Required | Description |
| :- | :- | :- |
| `paths` | No | Glob patterns that [scope the rule to matching files](#path-specific-rules). Accepts a YAML list or a comma-separated string |

If the YAML between the markers doesn't parse, Claude Code ignores the frontmatter and loads the rule as if it had no `paths`. Run `claude --debug` to see the parse error.

#### Share rules across projects with symlinks

The `.claude/rules/` directory supports symlinks, so you can maintain a shared set of rules and link them into multiple projects. Circular symlinks are detected and handled gracefully.

Claude Code treats a symlink whose target is outside your working directory like an [external import](#import-additional-files). The linked rules don't load until you approve external imports for the project, and after that only the ones without a [`paths` field](#path-specific-rules) load.

Claude Code asks for that approval once per project, in a dialog at the start of an interactive session. The dialog lists the linked rule files alongside any external `@path` imports. To load shared rules without that approval, keep them in [`~/.claude/rules/`](#user-level-rules), where they apply to every project on your machine.

This example links both a shared directory and an individual file:

```bash theme={null}
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

If you point a `.claude/rules/` or `CLAUDE.md` symlink at a network path such as the UNC share `\\server\share` or a path under `/net` or `/Network`, the linked instructions don't load. Claude Code doesn't follow the link, because looking up such a path can contact the host it names. `\\wsl$` paths don't count as network paths.

#### User-level rules

Personal rules in `~/.claude/rules/` apply to every project on your machine. Use them for preferences that aren't project-specific:

```text theme={null}
~/.claude/rules/
├── preferences.md    # Your personal coding preferences
└── workflows.md      # Your preferred workflows
```

Claude Code loads user-level rules before project rules, so a project rule appears later in Claude's context than a user rule. Neither set overrides the other: if a user rule and a project rule conflict, Claude may follow either one, so keep the two consistent.
