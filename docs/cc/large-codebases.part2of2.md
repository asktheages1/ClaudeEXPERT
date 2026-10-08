[Part 2/2 of https://code.claude.com/docs/en/large-codebases.md, fetched 2026-10-08]

## Add per-directory skills

Any subdirectory can define [skills](/docs/en/skills) scoped to its own stack. A skill loads on demand when Claude determines it's relevant, so API-specific tooling doesn't consume context during frontend work.

Skills live under `.claude/skills/` inside the directory. Commit them alongside that area's code so anyone who clones the repository gets them. In a monorepo this can be one set of skills per package. In a large single-tree codebase it's one set per subsystem such as `src/db/.claude/skills/`.

Create a skill directory inside the subdirectory:

```bash theme={null}
mkdir -p packages/api/.claude/skills/api-testing
```

Then write `SKILL.md` inside that directory, here `packages/api/.claude/skills/api-testing/SKILL.md`. This example teaches Claude the API package's testing patterns:

```markdown packages/api/.claude/skills/api-testing/SKILL.md theme={null}
---
name: api-testing
description: Testing patterns for the API package. Use when writing or modifying tests in packages/api/.
---

## Test structure

Tests are in `src/__tests__/` mirroring the `src/` directory structure.
Each route file has a corresponding `.test.ts` file.

## Running tests

- All tests: `npm test`
- Single file: `npm test -- src/__tests__/routes/users.test.ts`
- Watch mode: `npm test -- --watch`

## Test utilities

- `src/__tests__/helpers/db.ts`: provides `setupTestDb()` and `teardownTestDb()` for database tests
- `src/__tests__/helpers/auth.ts`: provides `createTestUser()` and `getAuthToken()` for authenticated endpoints

## Patterns

- Use `supertest` for HTTP assertions, not raw fetch
- Always wrap database tests in a transaction that rolls back
- Mock external services in `src/__tests__/mocks/`
```

A different subdirectory holds different skills the same way: `packages/web/.claude/skills/component-patterns/` describes the frontend's component conventions instead of testing. When Claude works on a file in `packages/api/`, it loads the api-testing skill. When it works in `packages/web/`, it loads component-patterns instead. Neither directory's skills load during the other's tasks.

You can also scope a skill by file pattern instead of by placement. The [`paths` frontmatter field](/docs/en/skills#frontmatter-reference) takes glob patterns, and Claude loads the skill automatically only when it works with matching files. Use this for a skill that lives in the repository root's `.claude/skills/` but applies only to certain files wherever they appear, such as a database-migration skill scoped to `**/migrations/**`.

For more on creating and organizing skills, see [Skills](/docs/en/skills).

### Keep skills discoverable

With skills spread across many directories, the list Claude chooses from can grow large. Claude picks a skill by reading every discovered skill's name and description, and only the chosen skill's full content loads into context. This section covers how to keep that list small.

Which skills are in scope depends on where you start Claude:

* **From a subdirectory such as `packages/api/`**: skills from that directory, every parent up to the repository root, and the user and enterprise levels
* **From the repository root**: root skills, plus skills from every subdirectory Claude touches during the session, which can accumulate into the hundreds
* **After adding a sibling with [`--add-dir`](#grant-access-across-packages-or-repositories)**: that sibling's skills load too. The `additionalDirectories` setting grants file access only and does not load skills

Names always load, but [when there are many, some skills lose their descriptions entirely](/docs/en/skills#skill-descriptions-are-cut-short), which can strip the keywords Claude uses to decide whether a skill applies. Keep descriptions short and lead with words a request would contain, like "writing or modifying tests in `packages/api/`".

For skills that many directories share, such as PR conventions or a deploy checklist, place them in the repository root's `.claude/skills/` so they load from any starting directory. When shared skills need their own version history or must work across repositories, package them as a [plugin](/docs/en/plugins/overview) instead. Plugin skills use a `plugin-name:skill-name` namespace, so they never collide with per-directory skills. A platform team can version and update them in one place.

To find which skills go unused, enable the OpenTelemetry [logs exporter](/docs/en/monitoring-usage) and set `OTEL_LOG_TOOL_DETAILS=1` so skill names are recorded verbatim instead of redacted. The [`skill_activated` event](/docs/en/monitoring-usage#skill-activated-event) records every invocation in its `skill.name` attribute, and `invocation_trigger` records whether a command, Claude, or a nested skill invoked it, which tells you what to consolidate or retire.

## Centralize conventions when layering stops scaling

Per-directory CLAUDE.md files can become hard to govern as the codebase grows. Conventions drift, files go stale, and no one owns the root. Solving that typically falls to the team that maintains the repository's Claude Code setup rather than to each developer working in their own area.

Move conventions and reference content out of always-loaded CLAUDE.md and into mechanisms that load on demand:

* [Skills](/docs/en/skills): reference material Claude loads only when relevant to the task
* [Plugins](/docs/en/plugins/overview): versioned bundles of skills, hooks, and commands that a platform team owns centrally
* [MCP servers](/docs/en/mcp): if your organization already runs a code search or RAG index over the repository, expose it as an MCP tool so Claude queries it instead of reading files directly

See [server-managed or endpoint-managed settings](/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings) for how platform teams can enforce these centrally.

### Recommend the right plugin at session start

Once conventions live in plugins, a teammate starting Claude in an unfamiliar part of the tree has no signal about which plugin that area's owners maintain. A [`SessionStart` hook](/docs/en/hooks#sessionstart) can close that gap, since Claude Code adds plain text the hook prints to stdout to Claude's context before the first prompt.

For example, you can write a script that reads the launch directory from the [hook input](/docs/en/hooks#common-input-fields), looks it up in a path-to-plugin map committed to the repository, and prints the recommendation for Claude to relay in its first reply. See [Automate actions with hooks](/docs/en/hooks-guide) to write and register the hook.

## Put it together

The combined configuration below uses the monorepo layout. The same files work for any subdirectory in a large single tree. Each subdirectory's `.claude/settings.json` must be self-contained rather than layered on a root file.

The example commits `worktree`, `additionalDirectories`, and the `Read` deny rules in `.claude/settings.json` so every developer in `packages/api/` gets the same sibling access, sparse paths, and exclusions. The file below is the committed per-area settings for `packages/api/`:

```json packages/api/.claude/settings.json theme={null}
{
  "worktree": {
    "sparsePaths": [
      ".claude",
      "packages/api",
      "packages/shared"
    ],
    "symlinkDirectories": [
      "node_modules"
    ]
  },
  "permissions": {
    "additionalDirectories": [
      "../shared"
    ],
    "deny": [
      "Read(./**/dist/**/*)",
      "Read(./**/build/**/*)"
    ]
  }
}
```

Because this session starts from `packages/api/`, sibling packages' CLAUDE.md files are already out of scope, so `claudeMdExcludes` is not needed here. Add it to the repository root's `.claude/settings.local.json` instead if you also start sessions from the root.

The `additionalDirectories` entry applies when you start Claude from `packages/api/` directly. Inside a worktree created from this session, the working directory is the worktree root, so this settings file does not load. The sibling packages are already reachable inside the worktree without it, but the deny rules need a second copy in the repository root's `.claude/settings.json` so worktree sessions pick them up, as the [worktree settings note](#check-out-only-the-directories-you-need) describes:

```json .claude/settings.json theme={null}
{
  "permissions": {
    "deny": [
      "Read(./**/dist/**/*)",
      "Read(./**/build/**/*)"
    ]
  }
}
```

After setup, the repository has this layout:

```text theme={null}
monorepo/
  CLAUDE.md
  .claude/settings.json                           # deny rules for worktree sessions
  packages/
    api/
      CLAUDE.md
      .claude/settings.json                       # worktree, additionalDirectories, deny rules
      .claude/skills/api-testing/SKILL.md
    web/
      CLAUDE.md
      .claude/skills/component-patterns/SKILL.md
    shared/
      CLAUDE.md
```

With this setup, starting Claude from `packages/api/`:

* Loads the root CLAUDE.md and `packages/api/CLAUDE.md`, skips `packages/web/CLAUDE.md`
* Can read and edit files in `packages/api/` and `packages/shared/`
* Skips reads of build output under `dist/` and `build/` in `packages/api/`
* Has the api-testing skill available on demand
* Creates worktrees containing `.claude/`, `packages/api/`, `packages/shared/`, and root-level files, with the deny rules applied across the worktree from the root settings file

## Scope and plan changes that span packages

The configuration above controls what Claude sees. When a single change touches several packages, such as updating a shared type along with every call site that uses it, how you scope and sequence the task also affects the result.

Two techniques help keep a cross-package change consistent:

* **Give Claude the whole change in one session**: handing over the shared edit and its call sites together keeps the decisions behind each edit consistent, rather than re-deriving them per package
* **Plan before editing**: [plan first](/docs/en/best-practices#explore-first-then-plan-then-code) in [plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode), and Claude writes the plan to a file. A long cross-package session [compacts its context](/docs/en/context-window#what-survives-compaction) along the way. Claude Code re-injects the plan file after each compaction, so the plan survives where conversation history may not

## Next steps

Once this configuration is in place, you can refine it:

* Use [hooks](/docs/en/hooks-guide) to run per-directory linters or type-checkers after Claude edits files
* Review [Manage costs effectively](/docs/en/costs) to understand how codebase size affects token usage and how to set spend limits before a wider rollout
* Read [How Claude Code works in large codebases](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start) on the Claude blog for organizational rollout patterns and ownership models that sit above the per-repository configuration on this page
