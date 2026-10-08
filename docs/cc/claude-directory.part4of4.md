[Part 4/4 of https://code.claude.com/docs/en/claude-directory.md, fetched 2026-10-08]

### Kept until you delete them

Apart from the rows that say otherwise, the retention cleanup sweep doesn't remove the paths below, and Claude Code keeps them until you delete them.

| Path under `~/.claude/` | Contents |
| - | - |
| `history.jsonl` | Every prompt you've typed, with timestamp and project path. Used for up-arrow recall, `Ctrl+R` history search, and `!` shell-command completion. Each sweep removes the entries older than `cleanupPeriodDays` when the [HIPAA configuration applies to your sessions](/docs/en/hipaa-setup#check-how-developers-sign-in-and-connect). |
| `stats-cache.json` | Aggregated token and cost counts shown by `/usage` |
| `remote-settings.json` | Cached copy of [server-managed settings](/docs/en/server-managed-settings) for your organization, or `{}` when your organization has configured none. Only present when the session [fetches them](/docs/en/server-managed-settings#platform-availability). Claude Code checks for updates at startup and hourly during a session. Claude Code deletes it when you log out. |
| `cache/changelog.md` | Cached copy of the Claude Code changelog, shown by `/release-notes`. Refreshed in the background. |
| `policy-limits.json` | Cached feature policy settings for your organization. Only present for some account types. Refreshed automatically. A `policy-limits.json.stamp.json` sidecar records which account or API key the cache belongs to. Claude Code deletes both files when you log out. |

<h4 id="state-files-to-keep">
  State files to keep
</h4>

Depending on which features you use, `~/.claude/` also holds files that the tables under [Application data](#application-data) don't list. Of those, caches and lock files are safe to delete. Keep these state files:

* `.credentials.json`: your [login credentials](/docs/en/authentication#credential-management)
* `agent-memory/`: [subagent memory](/docs/en/sub-agents#enable-persistent-memory)
* `jobs/` and `daemon/`: [background session](/docs/en/agent-view#where-state-is-stored) state

### Plaintext storage

Transcripts and history are not encrypted at rest. OS file permissions are the only protection. If a tool reads a `.env` file or a command prints a credential, that value is written to `projects/<project>/<session>.jsonl`. To reduce exposure:

* Lower `cleanupPeriodDays` to shorten how long Claude Code keeps transcripts
* Set [`desktopSessionCleanupPeriodDays`](/docs/en/settings-reference#desktopsessioncleanupperioddays) to give Claude Desktop and Cowork transcripts an age limit too
* Set the [`CLAUDE_CODE_SKIP_PROMPT_HISTORY`](/docs/en/env-vars) environment variable to skip writing transcripts and prompt history in any mode. In non-interactive mode, you can instead pass `--no-session-persistence` alongside `-p`, or set `persistSession: false` in the TypeScript Agent SDK; the Python SDK has no equivalent option.
* Use [permission rules](/docs/en/permissions) to deny reads of credential files

### Clear local data

Run `claude purge` to delete the state Claude Code holds for one project. It deletes:

* Transcripts and auto memory under `projects/`
* Per-session `tasks/`, `debug/`, and `file-history/` entries
* Matching prompt lines in `history.jsonl`
* The project's entry in `~/.claude.json`

Images you pasted or attached in the project's sessions and each session's [scratchpad](#session-scratchpad-directory) are stored under Claude Code's temp directory rather than `~/.claude`, so the purge doesn't remove them. The [retention sweep](#cleaned-up-automatically) still deletes the images once they're older than `cleanupPeriodDays`; a purged session's scratchpad stays until you delete it or your operating system clears the temp directory.

The command prints the full deletion plan and asks for confirmation before removing anything.

Before v2.1.288, the command was `claude project purge`.

The examples below use `~/work/my-repo` as a placeholder. Replace it with the path to your project. If no state matches the path, the command prints an error and exits with status 1.

Preview the plan without deleting anything:

```bash theme={null}
claude purge ~/work/my-repo --dry-run
```

The plan lists each matching item and why it is included:

```text theme={null}
Purge plan for /home/user/work/my-repo:

  dir:    /home/user/.claude/projects/-home-user-work-my-repo
           project transcripts (.jsonl) and memory/
  config: projects["/home/user/work/my-repo"]
           project entry in ~/.claude.json (trust, history, MCP servers)
  filter: /home/user/.claude/history.jsonl
           12 prompt(s) typed in this project

shell-snapshots/ are not project-scoped and will not be touched
backups/ may still contain this project entry in old .claude.json snapshots (/home/user/.claude/backups); at most 5 are kept and they rotate out automatically
Dry run: 3 item(s) would be deleted.
```

Delete with a single confirmation prompt:

```bash theme={null}
claude purge ~/work/my-repo
```

The command prints the same plan, then asks `Delete 3 item(s) for /home/user/work/my-repo? This cannot be undone. [y/N]` and deletes only if you answer `y`.

Omit the path to pick a project from an interactive list.

Skip the confirmation prompt for use in scripts:

```bash theme={null}
claude purge ~/work/my-repo --yes
```

Pass `--all` instead of a path to purge state for every project at once, which deletes `history.jsonl` outright rather than filtering it. Pass `-i` to step through the deletion plan one item at a time.

The command leaves `shell-snapshots/` and `backups/` alone because those are not project-scoped, and warns about them in the plan output. If anyone ran [`/heapdump`](/docs/en/troubleshooting#high-cpu-or-memory-usage) on the machine, delete the `.heapsnapshot` files it wrote too. A heap snapshot contains the full conversation and any credentials the process held, and neither the retention sweep nor the purge touches it.

You can also delete any of the application-data paths above by hand, apart from the [state files to keep](#state-files-to-keep). New sessions are unaffected. The table below shows what you lose for past sessions.

| Delete | You lose |
| - | - |
| `~/.claude/projects/` | Resume, continue, and rewind for past sessions, and auto memory for every project |
| `~/.claude/history.jsonl` | Up-arrow prompt recall, `Ctrl+R` history search, and `!` shell-command completion |
| `~/.claude/paste-cache/` | Pasted text in recalled prompts; see [paste large content](/docs/en/terminal-config#paste-large-content) |
| `~/.claude/uploads/` | Attachments that past [Remote Control](/docs/en/remote-control) sessions refer to by path |
| `~/.claude/file-history/` | Checkpoint restore for past sessions |
| `~/.claude/stats-cache.json` | Historical totals shown by `/usage` |
| `~/.claude/usage-data/` | Past [`/insights`](/docs/en/costs#analyze-your-usage-patterns) reports and the cached analysis data used to build them |
| `~/.claude/feedback-bundles/` | Feedback and bug-report archives you haven't yet sent to your Anthropic account team |
| `~/.claude/feedback/drafts/` | [Claude-drafted feedback](/docs/en/tools-reference#sendfeedback-tool-behavior) you haven't sent |
| `~/.claude/remote-settings.json` | Nothing. Re-fetched on next launch. |
| `~/.claude/cache/changelog.md` | Nothing. Refreshed in the background. |
| `~/.claude/policy-limits.json` | Nothing. Refreshed automatically. |
| `~/.claude/tasks/` | Task lists that a resumed session would pick up |
| `~/.claude/skills/.trash/`, `~/.claude/plugins/.trash/` | The chance to recover [synced skills](/docs/en/skills#how-synced-skills-behave) and [synced plugins](/docs/en/plugins/loading#synced-plugins) that Claude Code removed |
| `~/.claude/plugins/installed_plugins.set-aside.<date>.<hash>.json`, `~/.claude/plugins/installed_plugins.unreadable.<date>.<hash>.kept` | The copies of plugin install records that Claude Code dropped or couldn't read. Nothing reads them back |
| `~/.claude/debug/`, `~/.claude/plans/`, `~/.claude/session-env/`, `~/.claude/shell-snapshots/`, `~/.claude/backups/` | Nothing user-facing |
| `~/.claude/todos/`, `~/.claude/statsig/`, `~/.claude/logs/`, `~/.claude/image-cache/` | Nothing. Legacy directories not written by current versions. |

Don't delete `~/.claude.json`, `~/.claude/settings.json`, or `~/.claude/plugins/`: those hold your auth, preferences, and installed plugins.

## Related resources

* [Manage Claude's memory](/docs/en/memory): write and organize CLAUDE.md, rules, and auto memory
* [Configure settings](/docs/en/settings): set permissions, hooks, environment variables, and model defaults
* [Create skills](/docs/en/skills): build reusable prompts and workflows
* [Configure subagents](/docs/en/sub-agents): define specialized agents with their own context
