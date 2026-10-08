[Part 18/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `copyFullResponse`

Make [`/copy`](/docs/en/commands) copy the full response every time, without the picker it otherwise shows when the response contains code blocks. Selecting **Always copy full response** in that picker sets this key to `true`. Appears in `/config` as **Skip the /copy picker**.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: `/copy` copies the full response without showing the picker
  * `false`: when the response contains code blocks, `/copy` shows a picker where you choose one code block or the full response
* **Default**: `false`

```json ~/.claude.json theme={null}
{
  "copyFullResponse": true
}
```

Claude Code ignores this key in `settings.json`.

### `copyOnSelect`

Copy text to your clipboard automatically when you finish selecting it with the mouse in [fullscreen rendering](/docs/en/fullscreen#use-the-mouse) or [agent view](/docs/en/agent-view). Appears in `/config` as **Copy on select** while fullscreen rendering is on.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code copies text to your clipboard when you finish selecting it
  * `false`: selecting text leaves your clipboard unchanged, and you [copy the selection with a keyboard shortcut](/docs/en/fullscreen#use-the-mouse) instead
* **Default**: `true`

```json ~/.claude.json theme={null}
{
  "copyOnSelect": false
}
```

Claude Code ignores this key in `settings.json`.

### `defaultToAgentsView`

Open [agent view](/docs/en/agent-view) instead of a new conversation when you run `claude` with no arguments. Appears in `/config` as **Open agents view by default** unless agent view is [turned off](#disableagentview).

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: `claude` with no arguments opens agent view, unless agent view is [turned off](#disableagentview)
  * `false`: `claude` with no arguments starts a new conversation
* **Default**: `false`

```json ~/.claude.json theme={null}
{
  "defaultToAgentsView": true
}
```

Claude Code ignores this key in `settings.json`.

### `diffTool`

Choose where Claude Code shows the diff of an `Edit` or `Write` change it proposes when a [VS Code](/docs/en/vs-code) or [JetBrains](/docs/en/jetbrains#features) IDE is connected: `"auto"` opens it in the IDE's diff viewer, `"terminal"` keeps it in the terminal. Appears in `/config` as **Diff tool** only while Claude Code is connected to a VS Code or JetBrains IDE.

* **Scope**: [`Global config`](#scopes)
* **Type**: string, one of:
  * `"auto"`: Claude Code opens the diff in the IDE's diff viewer when a VS Code or JetBrains IDE is connected
  * `"terminal"`: Claude Code keeps the diff in the terminal
* **Default**: `"auto"`

```json ~/.claude.json theme={null}
{
  "diffTool": "terminal"
}
```

Claude Code ignores this key in `settings.json`.

### `externalEditorContext`

When you press `Ctrl+G`, Claude Code opens the prompt you're typing in your [external editor](/docs/en/interactive-mode#general-controls). With this key on, the editor buffer starts with Claude's previous response as `#` comment lines, so you can read it while you write, and Claude Code strips those lines when you save. Appears in `/config` as **Show last response in external editor**.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: the editor buffer starts with Claude's previous response as `#` comment lines, which Claude Code strips when you save
  * `false`: the editor buffer opens with only your prompt
* **Default**: `false`

```json ~/.claude.json theme={null}
{
  "externalEditorContext": true
}
```

With it on, the buffer Claude Code opens looks like this, and only the text below the marker line is sent as your prompt:

```text theme={null}
# ─── Claude's last response (for reference; removed on save) ───
# I added the retry loop to fetchUser in src/api.ts and a test
# for the timeout case. Want me to wire the same retry into
# fetchOrders?
# ─── Write your reply below this line ──────────────────────────

Yes, and cap it at three attempts.
```

Claude Code keeps the last 50 lines of the response and marks the cut with `# … (earlier output truncated)`.

Claude Code ignores this key in `settings.json`.

### `leftArrowOpensAgents`

Press `←` on an empty prompt to [background the session and open agent view](/docs/en/agent-view#switch-sessions-without-leaving-the-terminal). Set this key to `false` to turn the shortcut off. Appears in `/config` as **← opens agents** when agent view is available.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: pressing `←` on an empty prompt in a session you started in the terminal backgrounds it and opens agent view
  * `false`: Claude Code turns the shortcut off; in a session you [attached to from agent view](/docs/en/agent-view#attach-to-a-session), `←` on an empty prompt still detaches
* **Default**: `true`

```json ~/.claude.json theme={null}
{
  "leftArrowOpensAgents": false
}
```

Claude Code ignores this key in `settings.json`.

### `permissionExplainerEnabled`

<Warning>
  Removed in v2.1.257, together with the `Ctrl+E` command explanation on Bash and PowerShell permission prompts. Setting it has no effect on current versions.
</Warning>

Through v2.1.256, you could press `Ctrl+E` on a Bash or PowerShell permission prompt to see a model-generated explanation of the command, and set this key to `false` to turn that shortcut off.

* **Scope**: [`Global config`](#scopes). On v2.1.256 and earlier.
* **Type**: Boolean
* **Default**: `true`

### `prStatusFooterEnabled`

Show a badge in the prompt footer for the current branch's open pull request or merge request, with a colored underline that shows its [status](/docs/en/interactive-mode#pr-review-status). Appears in `/config` as **Show PR status footer**.

* **Scope**: [`Global config`](#scopes)
* **Type**: Boolean
  * `true`: the footer shows the badge under the conditions in [PR review status](/docs/en/interactive-mode#pr-review-status)
  * `false`: Claude Code skips the footer's pull request and merge request check and doesn't show that badge. A session you [attached to from agent view](/docs/en/agent-view#attach-to-a-session) can still show a plain link to a pull request [linked to it](/docs/en/agent-view#pull-request-status)
* **Default**: `true`

```json ~/.claude.json theme={null}
{
  "prStatusFooterEnabled": false
}
```

Claude Code ignores this key in `settings.json`.

### `teammateDefaultModel`

<Warning>
  Removed in v2.1.234, together with its `/config` row **Default teammate model**. Setting it has no effect on current versions.
</Warning>

Through v2.1.233, you set this key to the model for [agent team](/docs/en/agent-teams#specify-teammates-and-models) teammates your prompt didn't name a model for: an alias such as `"sonnet"`, or `null` to follow the lead's model. For the model Claude Code picks for such teammates now, see [specify teammates and models](/docs/en/agent-teams#specify-teammates-and-models).

* **Scope**: [`Global config`](#scopes). On v2.1.233 and earlier.
* **Type**: string, a model alias or full model ID, or `null`
* **Default**: unset

## See also

* [Configure permissions](/docs/en/permissions): rule syntax, permission modes, and workspace trust
* [Environment variables](/docs/en/env-vars): every `CLAUDE_*`, `ANTHROPIC_*`, and provider variable Claude Code reads
* [Tools available to Claude](/docs/en/tools-reference): the built-in tools and which need approval
* [Example settings files](/docs/en/settings-example): a personal file, a team file, and an organization's managed file
* [Set up managed settings](/docs/en/admin-setup): how organizations decide what to enforce
* [Deploy managed settings](/docs/en/managed-settings): delivery mechanisms, precedence within the managed tier, and invalid entries in managed settings
* [Debug your configuration](/docs/en/debug-your-config): `claude doctor` and the Settings Error dialog
