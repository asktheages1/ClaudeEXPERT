[Part 10/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `showClearContextOnPlanAccept`

When Claude finishes a plan in [plan mode](/docs/en/permission-modes#review-and-approve-a-plan), it shows an approval menu. Planning can use a lot of context, so this key adds a first option to that menu, **Yes, clear context and …**, that approves the plan, clears the conversation context, and starts implementing from the plan alone. The rest of the label names the permission mode the session continues in, and shows how much of your context the planning used.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: the plan approval menu gets a first option, **Yes, clear context and …**, that approves the plan and clears the conversation context
  * `false`: the plan approval menu shows no clear-context option
* **Default**: `false`

```json settings.json theme={null}
{
  "showClearContextOnPlanAccept": true
}
```

### `showTurnDuration`

Show or hide the turn duration message after each response, such as "Cooked for 1m 6s · done 6:05 PM". The clock after "done" shows when the turn finished; [`timeFormat`](#timeformat) and [`timeZone`](#timezone) control its format and zone. Appears in `/config` as **Show turn duration**.

* **Scope**: [`Any file`](#scopes). A value in `~/.claude.json` from an older version applies when no settings file sets it.
* **Type**: Boolean
  * `true`: you see the turn duration message after each response
  * `false`: Claude Code hides the turn duration message
* **Default**: `true`

```json settings.json theme={null}
{
  "showTurnDuration": false
}
```

### `spellcheck`

Underline misspelled words in the prompt input as you type, using a spell checker you install. Claude Code checks only the text in the input box. [Check spelling as you type](/docs/en/interactive-mode#check-spelling-as-you-type) covers installing aspell, hunspell, or ispell and what the checker covers. Requires Claude Code v2.1.235 or later.

* **Scope**: [`User or managed`](#scopes). The block from the highest tier that sets it applies as a whole.
* **Type**: object with `enabled` (Boolean), `checker` (`"aspell"`, `"hunspell"`, `"ispell"`, or `"auto"`), `language` (string, passed to the checker as its dictionary name), and `color` (string, a terminal color name, `#rrggbb`, `rgb(r,g,b)`, `ansi256(n)`, or `ansi:<name>`)
* **Default**: unset, so spell checking is off; `checker` defaults to `"auto"`, the first of the three found on `PATH`; `language` defaults to the checker's own dictionary; `color` defaults to the theme's error color

```json settings.json theme={null}
{
  "spellcheck": { "enabled": true, "language": "en_GB" }
}
```

### `spinnerTipsEnabled`

While Claude works, the spinner line rotates through short tips about Claude Code features, such as "Use Plan Mode to prepare for a complex request before making changes. Press Shift+Tab twice to enable." Set this key to `false` to hide them. Appears in `/config` as **Show tips**.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: you see tips in the spinner while Claude is working
  * `false`: Claude Code hides spinner tips
* **Default**: `true`

```json settings.json theme={null}
{
  "spinnerTipsEnabled": false
}
```

### `spinnerTipsOverride`

Add your own tips to the [spinner tips](#spinnertipsenabled) that Claude Code shows while Claude works, or replace the built-in tips with yours. Claude Code puts your tips in the same rotation as the built-in ones.

If you set [`spinnerTipsEnabled`](#spinnertipsenabled) to `false`, Claude Code hides all tips, yours included.

* **Scope**: [`Any file`](#scopes). Claude Code honors tip objects, `tipsFile`, `label`, and `excludeDefault` from user settings, the `--settings` flag, and managed settings; from project and local settings it reads plain string tips only.
* **Type**: object with `tips`, `tipsFile`, `label`, and `excludeDefault` fields, each optional
* **Default**: unset, so Claude Code shows only the built-in tips

Tip objects, `tipsFile`, `label`, and the Scope line's rule that project and local settings contribute plain strings only require Claude Code v2.1.247 or later.

Each `tips` entry is a plain string or an object with these fields:

| Field | Required | Description |
| :- | :- | :- |
| `id` | Yes | Up to 64 letters, digits, `.`, `_`, or `-`. Claude Code keys the tip's show history on it, so the tip's cooldown survives reordering the list. Of two entries with the same id, Claude Code uses the first |
| `text` | Yes | The tip, one line of up to 500 characters. Claude Code strips ANSI escapes and control characters and collapses whitespace |
| `cooldownSessions` | No | Sessions Claude Code waits before showing the tip again, `0` to `1000`, default `0` |
| `priority` | No | Order among tips that have gone unshown equally long, higher first, `-10` to `10`, default `0` |

Claude Code reads a plain string as a tip with those defaults and a position-based id, so its show history resets when you reorder the list. Give a tip an `id` to keep its history across edits.

Claude Code reads at most 200 tips across `tips` and `tipsFile`, and drops an invalid entry with a debug warning instead of rejecting the settings file.

Use the remaining fields to name a tips file, set the prefix, and hide the built-in tips:

* `tipsFile`: an absolute or `~/` path to a local JSON file holding an array of the same entries, or an object with a `tips` array, up to 256 KB. Claude Code reads the file once per process, so it loads your edits at the next start. You can't set it through [server-managed settings](/docs/en/server-managed-settings); deploy inline `tips` there, or deploy the path in an on-disk `managed-settings.json`.
* `label`: the prefix Claude Code shows before tips from user, `--settings`, and managed settings, up to 40 characters. The default is `Tip`, the same prefix as the built-in tips, and tips from project and local settings always use it.
* `excludeDefault`: set it to `true` to hide the built-in tips and show only yours. When Claude Code can't load any of your tips, for example because `tipsFile` doesn't exist or every entry is invalid, it keeps the built-in rotation instead of an empty spinner.

When more than one settings file sets the key, Claude Code shows tips from all of them and takes `tipsFile`, `label`, and `excludeDefault` from whichever of managed settings, the `--settings` flag, and user settings is the highest-precedence one that sets each.

This example, in your user settings, adds a plain string tip and an object tip to the rotation under the `Acme tip` prefix:

```json settings.json theme={null}
{
  "spinnerTipsOverride": {
    "label": "Acme tip",
    "tips": [
      "Run /review before opening a PR",
      {
        "id": "gateway-errors",
        "text": "Seeing 5xx errors? Check the gateway status page first",
        "cooldownSessions": 5,
        "priority": 2
      }
    ]
  }
}
```

Each field in the example changes one thing about how Claude Code shows the tips:

* `label`: Claude Code shows both tips as `Acme tip: ...` instead of `Tip: ...`.
* The plain string: Claude Code gives it the defaults, so it can come up again in the very next session.
* `id`: Claude Code keys the second tip's show history on `gateway-errors`, so its cooldown still applies after you add or reorder tips.
* `cooldownSessions`: after Claude Code shows the `gateway-errors` tip, it doesn't show that tip again until five sessions later.
* `priority`: when the `gateway-errors` tip and another tip have gone unshown for the same number of sessions, for example when neither has been shown yet, Claude Code shows `gateway-errors` first. The plain string has the default priority, `0`.

While Claude works, Claude Code shows your tips in the spinner with your prefix, such as `Acme tip: Run /review before opening a PR`.

### `spinnerVerbs`

While a turn is in progress, the spinner shows a rotating verb such as "Accomplishing", "Architecting", or "Baking". Use this key to add your own verbs to that rotation or replace the built-in list with yours.

* **Scope**: [`Any file`](#scopes)
* **Type**: object with a `verbs` array of strings and `mode`, one of:
  * `"append"`: Claude Code adds your verbs to the built-in set
  * `"replace"`: Claude Code shows only your verbs
* **Default**: unset, so Claude Code uses the built-in verbs

This example adds two verbs to the built-in set:

```json settings.json theme={null}
{
  "spinnerVerbs": {
    "mode": "append",
    "verbs": ["Pondering", "Crafting"]
  }
}
```

In `"replace"` mode with an empty `verbs` array, Claude Code keeps the built-in verbs.

### `statusLine`

Run your own command to render a [status line](/docs/en/statusline) below the prompt with context such as the model, cost, or git branch. Optional fields adjust spacing, add periodic re-runs, and hide the built-in vim mode indicator when your script renders `vim.mode` itself.

* **Scope**: [`Any file`](#scopes). When [`allowManagedHooksOnly`](#allowmanagedhooksonly) is on, or [`disableAllHooks`](#disableallhooks) is set outside managed settings, only the managed settings value runs.
* **Type**: object with `type` set to `"command"` and a `command` string, plus optional `padding` as a number of characters, `refreshInterval` as a number of seconds, minimum `1`, and `hideVimModeIndicator` as a Boolean
* **Default**: unset, so no status line

This example prints the model name and context usage, and adds two characters of horizontal spacing:

```json settings.json theme={null}
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"[\\(.model.display_name)] \\(.context_window.used_percentage // 0)% context\"'",
    "padding": 2
  }
}
```

The example needs [`jq`](https://jqlang.org/) installed and runs in a shell. For PowerShell and Git Bash equivalents, see [Windows configuration](/docs/en/statusline#windows-configuration); for the full setup, see [Manually configure a status line](/docs/en/statusline#manually-configure-a-status-line).

### `subagentStatusLine`

When Claude runs [subagents](/docs/en/sub-agents), Claude Code lists them in a task display below the prompt, one row per subagent showing `name · description · token count`. This key lets you run your own command to rewrite those rows, for example to show each subagent's context usage as a percentage. On each refresh, Claude Code sends the visible rows as one JSON object on stdin, with a `tasks` array carrying each subagent's `id`, `name`, `status`, `model`, `tokenCount`, and more, and replaces the row for each `id` you write back as a `{"id", "content"}` line. Rows you don't write back keep the default rendering.

* **Scope**: [`Any file`](#scopes). When [`allowManagedHooksOnly`](#allowmanagedhooksonly) is on, or [`disableAllHooks`](#disableallhooks) is set outside managed settings, only the managed settings value runs.
* **Type**: object with `type` set to `"command"` and a `command` string
* **Default**: unset, so Claude Code renders the default rows

```json settings.json theme={null}
{
  "subagentStatusLine": {
    "type": "command",
    "command": "jq -c '.tasks[] | {id, content: \"\\(.name): \\(.tokenCount) tokens\"}'"
  }
}
```

See [Subagent status lines](/docs/en/statusline#subagent-status-lines).

### `syntaxHighlightingDisabled`

Claude Code colors code by language in the diffs, code blocks, and file previews it shows in the terminal, with its built-in highlighter; no plugin or language server is involved. Set this key to `true` to show them as plain text instead, for example if the colors clash with your terminal theme or slow a screen reader.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code turns off syntax highlighting in diffs, code blocks, and file previews
  * `false`: Claude Code highlights syntax
* **Default**: `false`

```json settings.json theme={null}
{
  "syntaxHighlightingDisabled": true
}
```

### `terminalProgressBarEnabled`

Some terminals can show a progress indicator on the tab or in the taskbar for the program running in them. While Claude is working, Claude Code reports an in-progress state to the terminal, so you can see from another tab or window whether the session is still busy. The indicator stays visible after the turn ends while [background subagents](/docs/en/sub-agents#run-subagents-in-foreground-or-background) or [dynamic workflows](/docs/en/workflows) are still running, and clears once the session is idle.

Claude Code reports it only in terminals that support the indicator: ConEmu, Ghostty 1.2.0 or later, and iTerm2 3.6.6 or later. Set this key to `false` to stop Claude Code from reporting it. Appears in `/config` as **Terminal progress bar**.

* **Scope**: [`Any file`](#scopes). A value in `~/.claude.json` from an older version applies when no settings file sets it.
* **Type**: Boolean
  * `true`: you see the terminal progress bar in terminals that support it
  * `false`: Claude Code hides the terminal progress bar
* **Default**: `true`

```json settings.json theme={null}
{
  "terminalProgressBarEnabled": false
}
```

### `terminalTitleFromRename`

Claude Code sets your terminal tab's title. By default it uses a title it generates from the conversation, and once you give the session a [name](/docs/en/sessions#name-your-sessions) with `/rename` or `--name`, the tab shows that name instead. Set this key to `false` to keep the generated title on the tab even after you name the session. The name itself still applies, so `/resume <name>` and the session picker find it.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: the terminal tab title shows the session name you set
  * `false`: the tab keeps the title Claude Code generates from your conversation
* **Default**: `true`

```json settings.json theme={null}
{
  "terminalTitleFromRename": false
}
```

To stop Claude Code from updating the terminal title at all, set [`CLAUDE_CODE_DISABLE_TERMINAL_TITLE`](/docs/en/env-vars) to `1` instead.

### `theme`

Pick the color theme for the interface. Appears in `/config` as **Theme**.

* **Scope**: [`Any file`](#scopes). A value in `~/.claude.json` from an older version applies when no settings file sets it.
* **Type**: string, one of:
  * `"auto"`: matches your terminal's light or dark background
  * `"dark"`: the dark theme
  * `"light"`: the light theme
  * `"dark-daltonized"`: the dark theme with colorblind-friendly colors
  * `"light-daltonized"`: the light theme with colorblind-friendly colors
  * `"dark-ansi"`: the dark theme using only your terminal's ANSI color palette
  * `"light-ansi"`: the light theme using only your terminal's ANSI color palette
  * `"custom:<slug>"` or `"custom:<plugin-name>:<slug>"`: a custom theme from `~/.claude/themes/` or a plugin
* **Default**: `"dark"`

```json settings.json theme={null}
{
  "theme": "light-daltonized"
}
```

See [Create a custom theme](/docs/en/terminal-config#create-a-custom-theme).

### `timeFormat`

Choose how Claude Code writes the times it shows in the interface, such as the `done 6:05 PM` at the end of each turn duration message and the timestamps in the [transcript viewer](/docs/en/interactive-mode#transcript-viewer). To pick a preset, run `/config` and set **Time format**. Requires Claude Code v2.1.257 or later.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"auto"`: the same as unset; each time keeps its built-in format, which follows your locale on the turn duration message
  * `"12-hour"`: a 12-hour clock
  * `"24-hour"`: a 24-hour clock
  * `"24-hour-utc"`: a 24-hour clock in UTC with `Z` after the minutes, such as `18:05Z`; Claude Code ignores [`timeZone`](#timezone) for this preset
  * A strftime pattern such as `"%H:%M"`: Claude Code writes each time with the pattern. Any value that contains a `%` is a pattern, and any other value outside the presets counts as `"auto"`
* **Default**: `"auto"`

```json settings.json theme={null}
{
  "timeFormat": "24-hour"
}
```

`/config` offers only the presets, so to use a strftime pattern, add the key to a settings file. This example shows each time as a two-digit 24-hour clock:

```json settings.json theme={null}
{
  "timeFormat": "%H:%M"
}
```

The turn duration message and the transcript viewer then show times such as `18:05`. In the transcript viewer, the pattern is the whole timestamp, so add date directives when you want the date there. This example puts the date in front of the clock:

```json settings.json theme={null}
{
  "timeFormat": "%Y-%m-%d %H:%M"
}
```

The same surfaces then show times such as `2026-09-01 18:05`.

### `timeZone`

Show the times in the interface in a time zone other than your system's. Set it to an [IANA time zone name](https://www.iana.org/time-zones), such as `"UTC"` or `"Europe/Dublin"`. The times that [`timeFormat`](#timeformat) controls then show in this zone. If `timeFormat` is `"24-hour-utc"`, times stay in UTC and Claude Code ignores this key. `/config` has no row for this key, so set it in a settings file. Requires Claude Code v2.1.257 or later.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, an IANA time zone name. When Claude Code doesn't recognize the name, it uses your system time zone
* **Default**: unset, so times show in your system time zone

```json settings.json theme={null}
{
  "timeZone": "Europe/Dublin"
}
```

### `tui`

Choose the terminal UI renderer. Use `"fullscreen"` for the flicker-free [alt-screen renderer](/docs/en/fullscreen) with virtualized scrollback, or `"default"` for the classic main-screen renderer. Running `/tui fullscreen` or `/tui default` writes this key for you.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"default"`: the classic main-screen renderer
  * `"fullscreen"`: the flicker-free alt-screen renderer with virtualized scrollback
* **Default**: unset, so Claude Code [picks the renderer for you](/docs/en/fullscreen#fullscreen-by-default)
* **Per-session overrides**: [`CLAUDE_CODE_NO_FLICKER`](/docs/en/env-vars) and [`CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN`](/docs/en/env-vars) take precedence over this key for one session: `CLAUDE_CODE_NO_FLICKER=1` turns fullscreen on, and `CLAUDE_CODE_NO_FLICKER=0` or `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` turns it off; when both are set, Claude Code turns it off

```json settings.json theme={null}
{
  "tui": "fullscreen"
}
```

Under tmux `-CC` or over SSH to Windows, Claude Code keeps the classic renderer unless you set `CLAUDE_CODE_NO_FLICKER=1`. Background sessions opened from [agent view](/docs/en/agent-view) always use the fullscreen renderer regardless of this setting.

### `verbose`

By default, the transcript collapses each tool call to a short summary, such as the command Claude ran and a line count of its output, and you press `Ctrl+O` to switch the whole transcript to the expanded view when you want the details. Set this key to `true` to show every tool call's full input and output inline as it happens, which is useful when you're debugging a hook, an MCP server, or a long shell command. Appears in `/config` as **Verbose output**.

* **Scope**: [`Any file`](#scopes). A value in `~/.claude.json` from an older version applies when no settings file sets it.
* **Type**: Boolean
  * `true`: you see full tool output
  * `false`: you see truncated summaries of tool output
* **Default**: `false`
* **Per-session overrides**: [`--verbose`](/docs/en/cli-reference#cli-flags) takes precedence over this key for one session

```json settings.json theme={null}
{
  "verbose": true
}
```

A [`viewMode`](#viewmode) value or a sticky `/focus` selection overrides this key every session.

### `viewMode`

Set the transcript view Claude Code starts in: `"default"`, `"verbose"`, or `"focus"`. When set, it overrides both the sticky `/focus` selection and the [`verbose`](#verbose) setting.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"default"`: the normal transcript with truncated tool output
  * `"verbose"`: the transcript with full tool output
  * `"focus"`: only your last prompt, a one-line summary of tool calls with edit diffstats, and the final response. Focus view needs the [fullscreen renderer](#tui)
* **Default**: unset, so the `verbose` setting and your last `/focus` choice apply
* **Per-session overrides**: [`--verbose`](/docs/en/cli-reference#cli-flags) takes precedence over this key for one session

```json settings.json theme={null}
{
  "viewMode": "focus"
}
```

### `vimInsertModeRemaps`

Map two-key INSERT-mode sequences to Escape in [vim editor mode](/docs/en/interactive-mode#vim-editor-mode). Each key is exactly two printable characters typed in sequence, and `"<Esc>"` is the only supported target; Claude Code ignores other entries. Requires Claude Code v2.1.208 or later.

* **Scope**: [`User or managed`](#scopes). A repository can't remap your keystrokes.
* **Type**: object mapping a two-character sequence to `"<Esc>"`
* **Default**: unset

```json settings.json theme={null}
{
  "vimInsertModeRemaps": {
    "jj": "<Esc>"
  }
}
```

Has no effect unless `editorMode` is `"vim"`. See [Remap INSERT-mode key sequences](/docs/en/interactive-mode#remap-insert-mode-key-sequences). Requires Claude Code v2.1.208 or later.

### `voice`

Turn on [voice dictation](/docs/en/voice-dictation) and choose how the dictation key behaves. Claude Code writes this object for you when you run `/voice`.

* **Scope**: [`Any file`](#scopes)
* **Type**: object with `enabled` as a Boolean, `autoSubmit` as a Boolean that applies in hold mode only, and `mode`, one of:
  * `"hold"`: you hold the dictation key while speaking and release it to stop
  * `"tap"`: you tap the key once to start recording and again to send
* **Default**: unset, so dictation is off; when `enabled` is `true` and `mode` is unset, Claude Code uses `"hold"`

This example turns dictation on and makes the key tap once to start recording and again to send:

```json settings.json theme={null}
{
  "voice": {
    "enabled": true,
    "mode": "tap"
  }
}
```

`autoSubmit` sends the prompt when you release the key in hold mode. Voice dictation requires a claude.ai account.
