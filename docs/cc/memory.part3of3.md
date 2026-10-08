[Part 3/3 of https://code.claude.com/docs/en/memory.md, fetched 2026-10-08]

## Troubleshoot memory issues

These are the most common issues with CLAUDE.md and auto memory, along with steps to debug them.

### Claude isn't following my CLAUDE.md

CLAUDE.md content is delivered as a user message after the system prompt, not as part of the system prompt itself. Claude reads it and tries to follow it, but there's no guarantee of strict compliance, especially for vague or conflicting instructions.

To debug:

* Run `/context` and check the list under **Memory files** to verify the CLAUDE.md and CLAUDE.local.md files that should load at launch. If one is missing there, Claude can't see it. Use `/memory` to open and edit the files.
* A `CLAUDE.md` in a subdirectory of your working directory doesn't appear under **Memory files**, because it loads on demand rather than at launch. When it loads, a `Loaded` line with its path appears in the terminal. To test a new one, create it from your shell rather than asking Claude to write it, then ask Claude to read a file in that subdirectory.
* Check that the relevant CLAUDE.md is in a location that gets loaded for your session (see [Choose where to put CLAUDE.md files](#choose-where-to-put-claude-md-files)).
* Make instructions more specific. "Use 2-space indentation" works better than "format code nicely."
* Look for conflicting instructions across CLAUDE.md files. If two files give different guidance for the same behavior, Claude may pick one arbitrarily.
* Check whether your instruction competes with guidance Claude Code adds on its own. If your CLAUDE.md sets commit or pull request rules, turn off the built-in ones with [`includeGitInstructions`](/docs/en/settings-reference#includegitinstructions) and set the attribution text with [`attribution`](/docs/en/settings-reference#attribution).

If the instruction is something that must run at a specific point, such as before every commit or after each file edit, write it as a [hook](/docs/en/hooks-guide) instead. Hooks execute as shell commands at fixed lifecycle events and apply regardless of what Claude decides to do.

For instructions you want at the system prompt level, use [`--append-system-prompt`](/docs/en/cli-reference#system-prompt-flags). You pass it at launch, so it's better suited to scripts and automation than interactive use. For how it behaves when you resume a conversation, see [System prompt flags in resumed conversations](/docs/en/cli-reference#system-prompt-flags-in-resumed-conversations).

<Tip>
  Use the [`InstructionsLoaded` hook](/docs/en/hooks#instructionsloaded) to log which `CLAUDE.md` and rules files are loaded, when they load, and why. This is useful for debugging path-specific rules or lazy-loaded files in subdirectories.
</Tip>

### My AGENTS.md isn't loading

If your repository has an `AGENTS.md` and Claude doesn't seem to know what it says, the usual cause is a `CLAUDE.md` somewhere on the project path. By default Claude reads `AGENTS.md` only when you have no `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it. Check these in order:

1. Look for a `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in your working directory or any directory above it, other than your `~/.claude/CLAUDE.md`. If you find one, Claude reads it instead of `AGENTS.md` unless you set **Project instructions** to `claude-md-and-agents-md`.
2. Run `claude --version` and confirm v2.1.277 or later. Before v2.1.281, some sessions, such as those on Amazon Bedrock or with telemetry disabled, [couldn't load `AGENTS.md`](#when-agents-md-support-is-unavailable) either, so on those versions update to v2.1.281 or later.
3. Type `/config` in your session to open the settings panel and confirm **Project instructions** isn't set to `claude-md` or `managed-only`. If you don't see the setting there at all, your session is one that [can't load `AGENTS.md`](#when-agents-md-support-is-unavailable).

To check whether Claude read your `AGENTS.md`, run `/memory` and look for its path in the list.

Before v2.1.280, `/memory` and `/context` didn't list an `AGENTS.md` that Claude read directly. On those versions, ask Claude what its project instructions say instead.

If you want to keep the `CLAUDE.md` you found, or your session can't load `AGENTS.md`, [add a `CLAUDE.md` next to your `AGENTS.md` that imports it](#share-one-file-with-other-coding-tools).

### I don't know what auto memory saved

Run `/memory` and select the auto memory folder to browse what Claude has saved. Everything is plain markdown you can read, edit, or delete.

### My CLAUDE.md is too large

Files over 200 lines consume more context and may reduce adherence. Claude Code skips a file over 4 MiB. Use [path-scoped rules](#path-specific-rules) to load instructions only when Claude works with matching files, or trim content that isn't needed in every session. Splitting into [`@path` imports](#import-additional-files) helps organization but doesn't reduce context, since imported files load at launch.

If one of your instruction files is over the recommended length, you see a warning at startup and when you run `/status`. You also see a warning when files that are each within that length add up past a combined limit at session start. Each CLAUDE.md, rules file, and `@path` import counts as a separate file.

The [`/doctor`](/docs/en/commands#all-commands) checkup proposes trims for a checked-in CLAUDE.md: it cuts content Claude can derive from the codebase, such as directory layouts, dependency lists, and architecture overviews, and keeps pitfalls, rationale, and conventions that differ from tool defaults. The trim check requires Claude Code v2.1.206 or later.

### Instructions seem lost after `/compact`

Project-root CLAUDE.md survives compaction: after `/compact`, Claude re-reads it from disk and re-injects it into the session. Nested CLAUDE.md files in subdirectories and rules with [`paths:` frontmatter](#path-specific-rules) load again on demand.

If an instruction disappeared after compaction, it was given only in conversation, lives in a nested CLAUDE.md that hasn't reloaded yet, or is a path-scoped rule that hasn't matched a file since. Add conversation-only instructions to CLAUDE.md to make them persist. See [What survives compaction](/docs/en/context-window#what-survives-compaction) for the full breakdown.

See [Write effective instructions](#write-effective-instructions) for guidance on size, structure, and specificity.

## Related resources

* [Debug your configuration](/docs/en/debug-your-config): diagnose why CLAUDE.md or settings aren't taking effect
* [Skills](/docs/en/skills): package repeatable workflows that load on demand
* [Settings](/docs/en/settings): configure Claude Code behavior with settings files
* [Subagent memory](/docs/en/sub-agents#enable-persistent-memory): let subagents maintain their own auto memory
