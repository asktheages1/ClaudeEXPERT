[Part 3/4 of https://code.claude.com/docs/en/claude-directory.md, fetched 2026-10-08]

                    <span style={{
    fontSize: '7px',
    color: 'var(--ce-accent)',
    marginTop: '6px'
  }}>●</span>
                    <span>{tip}</span>
                  </div>)}
              </div>}

            {}
            {selected.example && <div style={{
    marginBottom: '16px'
  }}>
                {selected.exampleIntro && <div style={{
    fontSize: '15px',
    color: 'var(--ce-text-2)',
    lineHeight: 1.6,
    marginBottom: '10px'
  }}>
                    {selected.exampleIntro}
                  </div>}
                <div style={{
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '6px 10px',
    background: 'var(--ce-code-header)',
    border: '1px solid var(--ce-border)',
    borderRadius: '8px 8px 0 0'
  }}>
                  <span style={{
    fontFamily: 'var(--ce-mono)',
    fontSize: '11px',
    fontWeight: 600,
    color: 'var(--ce-text-3)'
  }}>{selected.label}</span>
                  <button onClick={() => copyExample(selected.id, selected.example)} style={{
    padding: '3px 8px',
    borderRadius: '4px',
    fontSize: '11px',
    fontWeight: 600,
    cursor: 'pointer',
    transition: 'all 0.15s',
    background: isCopied ? 'rgba(85,138,66,0.08)' : 'var(--ce-code-header)',
    border: isCopied ? '0.5px solid rgba(85,138,66,0.2)' : '0.5px solid var(--ce-border)',
    color: isCopied ? '#558A42' : 'var(--ce-text-3)'
  }}>
                    {isCopied ? '✓ Copied' : 'Copy'}
                  </button>
                </div>
                <pre style={{
    margin: 0,
    padding: '12px 14px',
    background: 'var(--ce-code-bg)',
    color: '#E8E6DC',
    fontFamily: 'var(--ce-mono)',
    fontSize: '13px',
    lineHeight: 1.65,
    borderRadius: '0 0 8px 8px',
    overflowX: 'auto',
    whiteSpace: 'pre'
  }}>{selected.example}</pre>
              </div>}

            {}
            {selected.docsLink && <a href={selected.docsLink} style={{
    display: 'inline-flex',
    padding: '5px 12px',
    borderRadius: '6px',
    background: 'var(--ce-accent-bg)',
    border: '1px solid var(--ce-accent-border)',
    color: 'var(--ce-accent)',
    fontSize: '12px',
    fontWeight: 600,
    textDecoration: 'none'
  }}>Full docs →</a>}

            {}
            {selected.children && selected.children.length > 0 && <div style={{
    marginTop: '20px'
  }}>
                <div style={{
    fontSize: '11px',
    fontWeight: 700,
    color: 'var(--ce-text-4)',
    textTransform: 'uppercase',
    letterSpacing: '0.4px',
    marginBottom: '8px'
  }}>Contents</div>
                <div style={{
    display: 'flex',
    flexDirection: 'column',
    gap: '4px'
  }}>
                  {selected.children.map(child => <button key={child.id} onClick={() => selectNode(child)} style={{
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    padding: '6px 8px',
    width: '100%',
    background: 'var(--ce-surface)',
    borderRadius: '6px',
    border: 'none',
    cursor: 'pointer',
    textAlign: 'left',
    transition: 'background 0.1s'
  }} onMouseEnter={e => e.currentTarget.style.background = 'var(--ce-surface-hover)'} onMouseLeave={e => e.currentTarget.style.background = 'var(--ce-surface)'}>
                      {renderIcon(child.icon, child.color, 13)}
                      <span style={{
    fontFamily: 'var(--ce-mono)',
    fontSize: '12px',
    color: 'var(--ce-text-2)'
  }}>{child.label}</span>
                      {child.oneLiner && <span style={{
    fontSize: '11px',
    color: 'var(--ce-text-4)',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap'
  }}>{child.oneLiner}</span>}
                    </button>)}
                </div>
              </div>}
      </div>
    </div>
    </>;
};

Claude Code reads instructions, settings, skills, subagents, and memory from your project directory and from `~/.claude` in your home directory. Commit project files to git to share them with your team; files in `~/.claude` are personal configuration that applies across all your projects.

On Windows, `~/.claude` resolves to `%USERPROFILE%\.claude`. If you set [`CLAUDE_CONFIG_DIR`](/docs/en/env-vars), every `~/.claude` path on this page lives under that directory instead.

Most users only edit `CLAUDE.md` and `settings.json`. If your repository already has an `AGENTS.md` for other coding agents, Claude Code [can read that](/docs/en/memory#agents-md) in place of a `CLAUDE.md`. The rest of the directory is optional: add skills, rules, or subagents as you need them.

## Explore the directory

Click files in the tree to see what each one does, when it loads, and an example.

<ClaudeExplorer />

## What's not shown

The explorer covers files you author and edit. A few related files live elsewhere:

| File | Location | Purpose |
| - | - | - |
| `managed-settings.json` | System-level, varies by OS | Enterprise-enforced settings that your own settings files and `--settings` values can't override, apart from [narrow exceptions](/docs/en/settings#exceptions-to-managed-settings-precedence). See [where to save the file](/docs/en/managed-settings#deploy-a-managed-settings-file) and [which managed source Claude Code uses](/docs/en/managed-settings#precedence-within-the-managed-tier). |
| `CLAUDE.local.md` | Project root | Your private preferences for this project, loaded alongside CLAUDE.md. Create it manually and add it to `.gitignore`. |
| `AGENTS.md` | Project root, `.claude/`, or any directory | Project instructions you write for AI coding agents. Claude Code can [load it](/docs/en/memory#agents-md) in place of a `CLAUDE.md`. |
| Installed plugins | `~/.claude/plugins` | Cloned marketplaces, installed plugin versions, the `installed_plugins.json` install record, and per-plugin data, managed by `claude plugin` commands. Plugins [synced from your claude.ai account](/docs/en/plugins/loading#synced-plugins) download into `~/.claude/plugins/synced/`. For a plugin installed from a marketplace [`command` source](/docs/en/plugins/marketplace-reference#command-plugin-source) in link mode, Claude Code stores links here instead of a copy, and the plugin's files stay in the directory the command prints. A `command` source requires Claude Code v2.1.229 or later. A plugin listed by relative path in a marketplace you added from a local path also [loads in place](/docs/en/plugins/loading#find-plugins-on-disk) from its source directory rather than from a cache copy. See [plugin caching](/docs/en/plugins/loading#find-plugins-on-disk) for how orphaned versions are cleaned up. |

`~/.claude` also holds data Claude Code writes as you work: transcripts, prompt history, file snapshots, caches, and logs. See [application data](#application-data) below.

## Choose the right file

Different kinds of customization live in different files. Use this table to find where a change belongs.

| You want to | Edit | Scope | Reference |
| :- | :- | :- | :- |
| Give Claude project context and conventions | `CLAUDE.md` | project or global | [Memory](/docs/en/memory) |
| Allow or block specific tool calls | `settings.json` `permissions` or `hooks` | project or global | [Permissions](/docs/en/permissions), [Hooks](/docs/en/hooks) |
| Run a script before or after tool calls | `settings.json` `hooks` | project or global | [Hooks](/docs/en/hooks) |
| Set environment variables for the session | `settings.json` `env` | project or global | [Settings](/docs/en/settings-reference#all-settings) |
| Keep personal overrides out of git | `settings.local.json` | project only | [Settings scopes](/docs/en/settings#where-settings-live) |
| Add a prompt or capability you invoke with `/name` | `skills/<name>/SKILL.md` | project or global | [Skills](/docs/en/skills) |
| Define a specialized subagent with its own tools | `agents/*.md` | project or global | [Subagents](/docs/en/sub-agents) |
| Orchestrate many subagents from a script | `workflows/*.js` | project or global | [Dynamic workflows](/docs/en/workflows) |
| Connect external tools over MCP | `.mcp.json` | project only | [MCP](/docs/en/mcp) |
| Change how Claude formats responses | `output-styles/*.md` | project or global | [Output styles](/docs/en/output-styles) |

## File reference

This table lists every file the explorer covers. Project-scope files live in your repo under `.claude/` (or at the root for `CLAUDE.md`, `.mcp.json`, and `.worktreeinclude`). Global-scope files live in `~/.claude/` and apply across all projects.

<Note>
  Several things can override what you put in these files:

  * [Managed settings](/docs/en/server-managed-settings) deployed by your organization take precedence over every settings file and `--settings` value, apart from the [exceptions under Settings precedence](/docs/en/settings#exceptions-to-managed-settings-precedence)
  * CLI flags like `--permission-mode` or `--settings` override `settings.json` for that session
  * Some environment variables take precedence over their equivalent setting, but this varies: check the [environment variables reference](/docs/en/env-vars) for each one

  See [settings precedence](/docs/en/settings#settings-precedence) for the full order.
</Note>

Click a filename to open that node in the explorer above.

| File | Scope | Commit | What it does | Reference |
| - | - | - | - | - |
| [`CLAUDE.md`](#ce-claude-md) | Project and global | ✓ | Instructions loaded every session | [Memory](/docs/en/memory) |
| [`rules/*.md`](#ce-rules) | Project and global | ✓ | Topic-scoped instructions, optionally path-gated | [Rules](/docs/en/memory#organize-rules-with-claude/rules/) |
| [`settings.json`](#ce-settings-json) | Project and global | ✓ | Permissions, hooks, env vars, model defaults | [Settings](/docs/en/settings) |
| [`settings.local.json`](#ce-settings-local-json) | Project only | | Your personal overrides, gitignored when Claude Code saves a setting to it | [Settings scopes](/docs/en/settings#where-settings-live) |
| [`.mcp.json`](#ce-mcp-json) | Project only | ✓ | Team-shared MCP servers | [MCP scopes](/docs/en/mcp#mcp-installation-scopes) |
| [`.worktreeinclude`](#ce-worktreeinclude) | Project only | ✓ | Gitignored files to copy into new worktrees | [Worktrees](/docs/en/worktrees#copy-gitignored-files-into-worktrees) |
| [`skills/<name>/SKILL.md`](#ce-skills) | Project and global | ✓ | Reusable prompts invoked with `/name` or auto-invoked | [Skills](/docs/en/skills) |
| [`commands/*.md`](#ce-commands) | Project and global | ✓ | Single-file prompts; same mechanism as skills | [Skills](/docs/en/skills) |
| [`output-styles/*.md`](#ce-output-styles) | Project and global | ✓ | Custom instruction sets that adjust how Claude works | [Output styles](/docs/en/output-styles) |
| [`agents/*.md`](#ce-agents) | Project and global | ✓ | Subagent definitions with their own prompt and tools | [Subagents](/docs/en/sub-agents) |
| [`workflows/*.js`](#ce-workflows) | Project and global | ✓ | Dynamic workflow scripts written by Claude and saved from `/workflows`; each file becomes a `/<name>` command | [Dynamic workflows](/docs/en/workflows) |
| [`agent-memory/<name>/`](#ce-agent-memory) | Project and global | ✓ | Persistent memory for subagents | [Persistent memory](/docs/en/sub-agents#enable-persistent-memory) |
| [`~/.claude.json`](#ce-claude-json) | Global only | | App state, OAuth, UI toggles, personal MCP servers | [Global config](/docs/en/settings-reference#global-config-settings) |
| [`projects/<project>/memory/`](#ce-global-projects) | Global only | | Auto memory: Claude's notes to itself across sessions | [Auto memory](/docs/en/memory#auto-memory) |
| [`keybindings.json`](#ce-keybindings) | Global only | | Custom keyboard shortcuts | [Keybindings](/docs/en/keybindings) |
| [`themes/*.json`](#ce-themes) | Global only | | Custom color themes | [Custom themes](/docs/en/terminal-config#create-a-custom-theme) |

## Frontmatter fields by file

Skills, command files, subagents, output styles, and rules read their configuration from YAML [frontmatter](/docs/en/glossary#frontmatter) at the top of the file, and each accepts its own set of fields. This table lists the field names for each file and links to the reference that describes them.

| File | Frontmatter fields | Reference |
| - | - | - |
| `skills/<name>/SKILL.md` | `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, `metadata`, `license`, `compatibility` | [Skill frontmatter](/docs/en/skills#frontmatter-reference) |
| `commands/*.md` | The skill fields except `name` and `paths` | [Skill frontmatter](/docs/en/skills#frontmatter-reference) |
| `agents/*.md` | `name`, `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`, `background`, `effort`, `isolation`, `color`, `initialPrompt`, `omitClaudeMd`, `experimental` | [Subagent frontmatter](/docs/en/sub-agents#supported-frontmatter-fields) |
| `output-styles/*.md` | `name`, `description`, `keep-coding-instructions`, `force-for-plugin` | [Output style frontmatter](/docs/en/output-styles#frontmatter) |
| `rules/*.md` | `paths` | [Rule frontmatter](/docs/en/memory#rules-frontmatter-reference) |

Agents shipped in a [plugin](/docs/en/plugins/components#agents) honor a subset of the subagent fields.

## Troubleshoot configuration

If a setting, hook, or file isn't taking effect, see [Debug your configuration](/docs/en/debug-your-config) for the inspection commands and a symptom-first lookup table.

## Application data

Beyond the config you author, `~/.claude` holds data Claude Code writes during sessions. These files are plaintext. Anything that passes through a tool is written to a transcript on disk: file contents, command output, pasted text.

### Cleaned up automatically

Claude Code deletes the files in the paths below once they're older than [`cleanupPeriodDays`](/docs/en/settings-reference#cleanupperioddays), as long as it can safely determine the retention period. The default is 30 days and the minimum is 1; setting `0` fails with a validation error. The same age cutoff applies to automatic removal of [orphaned worktrees](/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees).

| Path under `~/.claude/` | Contents |
| - | - |
| `projects/<project>/<session>.jsonl` | Full conversation transcript: every message, tool call, and tool result |
| `projects/<project>/<session>.orphaned-<timestamp>-<suffix>.jsonl`, `projects/<project>/<session>.jsonl.superseded-<timestamp>` | A previous transcript for the session that Claude Code set aside instead of overwriting or deleting it. It doesn't appear in the session picker |
| `projects/<project>/<session>/subagents/` | [Subagent](/docs/en/sub-agents) conversation transcripts, removed with the parent session transcript when it ages out |
| `projects/<project>/<session>/tool-results/` | Large tool outputs spilled to separate files, and full-size copies of [images that MCP tools return](/docs/en/mcp#images-in-tool-results) |
| `file-history/<session>/` | Pre-edit snapshots of files Claude changed, used for [checkpoint restore](/docs/en/checkpointing). Holds snapshots for the 100 most recent checkpoints; snapshot files that no retained checkpoint references are deleted, except each file's first snapshot |
| `plans/` | Plan files written during [plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode) |
| `debug/` | Per-session debug logs, written while debug logging is on, such as when you start with [`--debug`](/docs/en/cli-reference#cli-flags) or run `/debug` |
| `paste-cache/` | Contents of large pastes |
| `image-cache/<session>/` | Attached images saved by Claude Code v2.1.274 and earlier. Later versions save pasted and attached images outside `~/.claude`, in an `images/` directory for each session under the temp directory that [`CLAUDE_CODE_TMPDIR`](/docs/en/env-vars) controls. The sweep removes other sessions' leftover directories here, whatever their age. |
| `uploads/<session>/` | Files you attach from the web or mobile app, and photos you attach from the mobile app, when messaging a [Remote Control](/docs/en/remote-control) session. An attachment to a [cloud session](/docs/en/claude-code-on-the-web) is saved in that session's own cloud environment instead, not on your machine. |
| `dev-mods/<session>/` | [Mods that Claude wrote](/docs/en/plugins/mods/create#ask-claude-for-a-mod) during the session |
| `session-env/` | Per-session environment metadata |
| `tasks/` | Task lists written by the task tools, one directory per list |
| `shell-snapshots/` | Aliases, functions, and shell options captured at startup and applied by the [Bash tool](/docs/en/tools-reference#bash-tool-behavior) to each command. Removed on clean exit. The sweep clears any left after a crash. |
| `backups/` | Earlier versions of `~/.claude.json`, copied when Claude Code rewrites the file. Claude Code keeps the five newest, plus a copy of any version it couldn't parse. |
| `feedback-bundles/` | Redacted transcript archives written by `/feedback` on third-party providers or when no Anthropic credentials are configured, for sending to your Anthropic account team |
| `feedback/drafts/` | Queued [Claude-drafted feedback](/docs/en/tools-reference#sendfeedback-tool-behavior) awaiting your review in `/feedback`. Swept after `cleanupPeriodDays` or 30 days, whichever is shorter. When the queue is at its 10-draft limit, Claude Code deletes the oldest draft to make room. |
| `usage-data/` | `report.html` and timestamped report copies written by [`/insights`](/docs/en/costs#analyze-your-usage-patterns), plus cached per-session analysis data used to build them |
| `skills/.trash/`, `plugins/.trash/` | [Skills](/docs/en/skills#how-synced-skills-behave) and [plugins](/docs/en/plugins/loading#synced-plugins) that the claude.ai sync removed, such as after you turn one off on claude.ai or stop syncing. The files stay here so you can recover them until the sweep deletes them |
| `plugins/installed_plugins.set-aside.<date>.<hash>.json`, `plugins/installed_plugins.unreadable.<date>.<hash>.kept` | Dated copies Claude Code makes before rewriting [`installed_plugins.json`](/docs/en/plugins/loading#find-plugins-on-disk): install records it dropped, and the contents of a file it couldn't read. |
| `todos/`, `statsig/`, `logs/` | Legacy directories from older versions. No longer written. The sweep removes their contents and then the empty directory. |

Session files in `sessions/`, auto memory, and Claude Desktop and Cowork transcripts each follow their own retention rule:

* **`sessions/`**: holds one small file per running session, used to detect concurrent sessions and crashes. It isn't part of the age-based sweep: Claude Code removes each file when its session exits and clears crash leftovers on the next launch.
* **Auto memory**: the sweep doesn't delete the memory files in a project's [auto memory](/docs/en/memory#auto-memory) directory, `projects/<project>/memory/`. Claude Code removes that directory only if it has been empty for the whole retention period. Before v2.1.228, the sweep treated folders inside the memory directory as session data and could delete old files beneath it.
* **Claude Desktop and Cowork transcripts**: Claude Code keeps the transcript of a session you started or most recently continued in Claude Desktop or Cowork at any age. To give these transcripts an age limit, set [`desktopSessionCleanupPeriodDays`](/docs/en/settings-reference#desktopsessioncleanupperioddays). Requires Claude Code v2.1.248 or later; earlier versions delete them after `cleanupPeriodDays`.

  Claude Code deletes these transcripts after `cleanupPeriodDays` instead in either of these cases:

  * [Managed settings](/docs/en/managed-settings) set `cleanupPeriodDays`
  * The [HIPAA configuration applies to your sessions](/docs/en/hipaa-setup#check-how-developers-sign-in-and-connect)

Claude Code skips the age-based sweep in these cases:

* **Bare mode**: when you run `claude -p` with [`--bare`](/docs/en/headless#start-faster-with-bare-mode), Claude Code doesn't run the sweep in that session.
* **Paused sweep**: if Claude Code can't safely determine the retention period, it pauses the retention cleanup sweep; the [`retention_sweep` event](/docs/en/monitoring-usage#retention-sweep-event) lists each configuration that pauses it. When the cause is a settings file that can't be read or parsed, or settings errors with `cleanupPeriodDays` or `desktopSessionCleanupPeriodDays` explicitly set, Claude Code also shows a warning in `/status` until you fix the settings errors. When [managed settings](/docs/en/server-managed-settings) provide `cleanupPeriodDays`, Claude Code runs the sweep at the managed value in either case.

To check that the machines in your organization run the sweep with the retention period you set, see [Check the retention sweep](/docs/en/monitoring-usage#check-the-retention-sweep).

### Session scratchpad directory

The scratchpad is a per-session directory that Claude Code gives Claude for temporary files: intermediate results, helper scripts, and drafts that don't belong in your project. When Claude says it saved something "to the scratchpad", the file is there. Claude uses it instead of `/tmp`, and can create, edit, and read files in it without a permission prompt.

The scratchpad lives under Claude Code's temp directory rather than `~/.claude`. Find the current session's path for your platform:

* **macOS**: `/private/tmp/claude-<uid>/<project>/<session-id>/scratchpad/`
* **Linux**: `/tmp/claude-<uid>/<project>/<session-id>/scratchpad/`, or the same shape under `$TMPDIR` when your system sets one
* **Windows**: `%TEMP%\claude\<project>\<session-id>\scratchpad\`

`<project>` is your working directory path with every character other than letters and digits replaced by `-`, such as `-Users-you-my-project`. If you set [`CLAUDE_CODE_TMPDIR`](/docs/en/env-vars), the tree moves under that directory instead. Hooks receive the current session's path as [`scratchpad_dir`](/docs/en/hooks#common-input-fields).

Scratchpad files last as long as the session's transcript: the [retention sweep](#cleaned-up-automatically) deletes the directory when it deletes the transcript, and [`claude purge`](#clear-local-data) doesn't touch the temp directory. Because the directory sits under the system temp location, your operating system can also clear it, such as on restart. To keep something Claude wrote there, ask Claude to move it into your project.

A session has a scratchpad only when all of these hold:

* You're signed in with a claude.ai account rather than an API key
* The session uses the Anthropic API, not Amazon Bedrock, Google Cloud's Agent Platform, or Microsoft Foundry
* [`enableArtifact`](/docs/en/settings-reference#enableartifact) isn't set to `false`
