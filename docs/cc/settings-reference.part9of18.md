[Part 9/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `fileCheckpointingEnabled`

Have Claude Code snapshot files before each edit so [`/rewind`](/docs/en/checkpointing) can restore them. Appears in `/config` as **Rewind code (checkpoints)**, and toggling it there writes this key to your user settings.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code snapshots files before each edit so `/rewind` can restore them
  * `false`: Claude Code doesn't snapshot files, so `/rewind` can't restore them
* **Default**: `true`
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_FILE_CHECKPOINTING`](/docs/en/env-vars) turns checkpointing off for one session; whichever of the two turns it off, the other can't turn it back on

```json settings.json theme={null}
{
  "fileCheckpointingEnabled": false
}
```

In a `-p` run or an Agent SDK session, Claude Code ignores this key. The SDK turns checkpointing on with its `enableFileCheckpointing` option, and a bare `-p` run needs `CLAUDE_CODE_ENABLE_SDK_FILE_CHECKPOINTING=true`. See [File checkpointing in the Agent SDK](/docs/en/agent-sdk/file-checkpointing).

### `plansDirectory`

Choose where Claude Code stores the plan files it writes in [plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode). Claude Code resolves the path relative to the project root.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, a path relative to the project root
* **Default**: unset, so Claude Code uses `~/.claude/plans`

```json settings.json theme={null}
{
  "plansDirectory": "./plans"
}
```

Claude Code stores plans in `~/.claude/plans` instead of the directory you set in cases such as these:

* **Outside the project root**: the path resolves outside the project root, as `"../plans"` does.
* **Backslash on macOS, Linux, and WSL**: the resolved path contains a backslash, as the Windows-style `"docs\\plans"` does. Write `"docs/plans"`, which works on Windows too.

### `skillListingBudgetFraction`

Each turn, Claude sees a [listing of your skills](/docs/en/skills#skill-descriptions-are-cut-short) with their descriptions, and Claude Code caps that listing at a share of the context window. When the listing is over the cap, Claude Code keeps every skill's name but drops the descriptions of the least-used skills, so Claude can still invoke those skills but is less likely to choose one on its own. Raise this key to keep more descriptions visible at the cost of more context per turn.

* **Scope**: [`Any file`](#scopes)
* **Type**: number, a fraction greater than `0` and at most `1`
* **Default**: `0.01`, which reserves 1% of the context window

```json settings.json theme={null}
{
  "skillListingBudgetFraction": 0.02
}
```

To see how much context the listing uses and which skills contribute most, run `/doctor`.

### `skillListingMaxDescChars`

Each turn, Claude sees a [listing of your skills](/docs/en/skills#skill-descriptions-are-cut-short) that shows each skill's `description` and `when_to_use` text. This key caps how many characters of that text Claude Code shows per skill; longer text is cut at the cap.

* **Scope**: [`Any file`](#scopes)
* **Type**: number of characters, a positive integer
* **Default**: `1536`

```json settings.json theme={null}
{
  "skillListingMaxDescChars": 2048
}
```

Raise it to keep long descriptions intact at the cost of more context per turn; lower it to fit more skills under [`skillListingBudgetFraction`](#skilllistingbudgetfraction).

### `taskOutputMaxChars`

<Warning>
  Removed in v2.1.277, together with the `TaskOutput` tool it sized. Setting it has no effect on current versions. Claude reads a background task's [output file](/docs/en/tools-reference#background-commands) with `Read` instead.
</Warning>

Through v2.1.276, you set this key to the number of characters of a [background task's](/docs/en/tools-reference#background-commands) output that Claude received inline when it read the task with the `TaskOutput` tool.

## Interface and terminal

Change how Claude Code looks and behaves in your terminal: theme, editor mode, status line, spinner, notifications inside the session, and accessibility. See [Terminal configuration](/docs/en/terminal-config).

### `askUserQuestionTimeout`

Let an unanswered [`AskUserQuestion`](/docs/en/tools-reference) dialog auto-continue after a period of idle time, submitting whatever options you had already selected. Set it when you step away and want Claude to continue without you. With the default, questions wait until you answer them. For when the timer pauses or never starts, see [Question auto-continue timeout](/docs/en/tools-reference#question-auto-continue-timeout).

* **Scope**: [`User or managed`](#scopes)
* **Type**: string, one of `"60s"`, `"5m"`, `"10m"`, or `"never"`
* **Default**: `"never"`
* **Per-session overrides**: [`CLAUDE_AFK_TIMEOUT_MS`](/docs/en/env-vars) takes precedence over this key for one session

```json settings.json theme={null}
{
  "askUserQuestionTimeout": "5m"
}
```

Appears in `/config` as **Question auto-continue timeout**, which writes this key to user settings; Claude Code hides the row while managed settings or the `--settings` flag set the key.

### `autoContinueAtUsageLimit`

After a claude.ai usage limit stops your session, wait in the open session and continue the task automatically after the reset. See [Turn automatic continue off](/docs/en/interactive-mode#turn-automatic-continue-off). Requires Claude Code v2.1.234 or later.

* **Scope**: [`User or managed`](#scopes). Read from user settings, `--settings`, and managed settings only. When none of those sets the key, a project or local settings file that sets it turns the feature off rather than being ignored.
* **Type**: Boolean
  * `true`: after a claude.ai usage limit stops your session, Claude Code waits in the open session and continues the task automatically after the reset
  * `false`: Claude Code doesn't start the wait on its own. You can still [start a wait yourself](/docs/en/interactive-mode#start-a-wait-yourself) from the usage-limit options menu
* **Default**: `true`

```json settings.json theme={null}
{
  "autoContinueAtUsageLimit": false
}
```

Appears in `/config` as **Continue automatically at usage limit**, which writes this key to user settings; Claude Code hides the row while managed settings or the `--settings` flag set the key.

### `autoScrollEnabled`

Follow new output to the bottom of the conversation in [fullscreen rendering](/docs/en/fullscreen). Turn it off to stay where you scrolled while Claude keeps working; permission prompts still scroll into view.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: the conversation follows new output to the bottom
  * `false`: you stay where you scrolled while Claude keeps working; permission prompts still appear below the transcript
* **Default**: `true`

```json settings.json theme={null}
{
  "autoScrollEnabled": false
}
```

Appears in `/config` as **Auto-scroll** when fullscreen rendering is on, which writes this key to user settings.

### `axScreenReader`

Render screen-reader friendly output: flat text without decorative borders or animations. Screen-reader mode uses the classic renderer, so the `tui` setting has no effect while it is active; attached [background sessions](/docs/en/agent-view) still render fullscreen.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code renders flat text without decorative borders or animations, using the classic renderer
  * `false`: Claude Code renders normally
* **Default**: unset, so screen-reader mode is off
* **Per-session overrides**: [`--ax-screen-reader`](/docs/en/cli-reference#cli-flags) takes precedence over [`CLAUDE_AX_SCREEN_READER`](/docs/en/env-vars), and both take precedence over this key for one session

```json settings.json theme={null}
{
  "axScreenReader": true
}
```

### `bashEditDiffEnabled`

Choose whether Claude Code records which files changed in a Git repository while a Bash command runs. When it records them, you see their diff in the terminal after the command, and your [PostToolUse Bash hooks](/docs/en/hooks#bash) receive the changed-file list.

A listed file isn't always one the command changed. A change that another program or another Bash call made while the command ran can appear there too.

Set the key to `true` to record them in every permission mode. Requires Claude Code v2.1.269 or later.

* **Scope**: [`User or managed`](#scopes). A `true` counts only from your user settings, JSON passed with `--settings`, or [managed settings](/docs/en/managed-settings), so a `true` in a repository's `.claude/settings.json` or `.claude/settings.local.json` can't turn the recording on. A `false` in either repository file still turns it off unless a [higher-precedence](/docs/en/settings#settings-precedence) file sets `true`.
* **Type**: Boolean
* **Default**: unset, so Claude Code records changes in auto mode and `bypassPermissions` mode when it directs Claude to edit files through Bash
* **Per-session overrides**: [`CLAUDE_CODE_BASH_EDIT_DIFF`](/docs/en/env-vars) takes precedence over this key for one session

```json settings.json theme={null}
{
  "bashEditDiffEnabled": true
}
```

### `companyAnnouncements`

Show your organization's announcements to users at startup. When you list more than one, Claude Code picks one at random for each session; on a person's very first launch it shows the first entry.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of strings
* **Default**: unset, so no announcement shows

```json settings.json theme={null}
{
  "companyAnnouncements": [
    "Welcome to Acme Corp! Review our code guidelines at docs.example.com"
  ]
}
```

### `defaultShell`

Choose whether Bash or PowerShell runs the shell commands you type with the [`!` prefix](/docs/en/interactive-mode#shell-mode-with-prefix) in the input box, the ones Claude Code runs directly and adds to the session.

`"powershell"` works only while the [PowerShell tool](/docs/en/tools-reference#powershell-tool) is on. The tool is on by default on Windows without Git Bash, and on Windows with Git Bash for claude.ai and Console accounts. In Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry sessions, and on macOS, Linux, and WSL, set `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` to turn the tool on. Set that variable to `0` to turn the tool off.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"bash"`: Claude Code runs your `!` commands in Bash
  * `"powershell"`: Claude Code runs your `!` commands in PowerShell
* **Default**: `"bash"`, or `"powershell"` on Windows when Bash isn't available

```json settings.json theme={null}
{
  "defaultShell": "powershell"
}
```

If the shell you name isn't available, Claude Code uses the other one: `"powershell"` falls back to Bash when the PowerShell tool is off, and `"bash"` falls back to PowerShell when Bash isn't installed.

### `dialogExpiry`

Set the deadline for dialogs Claude Code [forwards to a remote client](/docs/en/remote-control#limitations), such as a Remote Control or SDK host, and for the approval dialog for a [held cross-session message](/docs/en/cross-session-messaging#control-inbound-messages). On Claude Code v2.1.236 or later, the same deadline bounds the mid-session [Fable usage-credits consent prompt](/docs/en/model-config#fable-and-usage-credits) in a session that may have nobody at the terminal. When no answer arrives before the deadline, Claude Code cancels the dialog and continues with its no-action default. Requires Claude Code v2.1.224 or later.

* **Scope**: [`User or managed`](#scopes)
* **Type**: string, one of `"60s"`, `"5m"`, `"10m"`, or `"never"`, which disables the deadline
* **Default**: `"5m"`
* **Per-session overrides**: [`CLAUDE_CODE_USER_DIALOG_TIMEOUT_MS`](/docs/en/env-vars) takes precedence over this key for one session

```json settings.json theme={null}
{
  "dialogExpiry": "10m"
}
```

Permission prompts and [`AskUserQuestion`](/docs/en/tools-reference#askuserquestion-tool-behavior) questions use their own flows and aren't governed by this deadline. Appears in `/config` as **Dialog expiry**, which writes this key to user settings; the row requires Claude Code v2.1.232 or later, and Claude Code hides it while managed settings or the `--settings` flag set the key.

### `editorMode`

Choose the key binding mode for the input prompt.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"normal"`: standard key bindings in the prompt input
  * `"vim"`: vim-style editing with NORMAL, INSERT, and VISUAL modes
* **Default**: `"normal"`

```json settings.json theme={null}
{
  "editorMode": "vim"
}
```

Appears in `/config` as **Editor mode**, which writes this key to user settings.

### `emojiCompletionEnabled`

Show emoji suggestions when you type `:` plus a shortcode in the prompt input, and replace a completed shortcode such as `:heart:` with its emoji. Set it to `false` to turn off both.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code shows emoji suggestions after `:` and replaces a completed shortcode with its emoji
  * `false`: Claude Code neither suggests emoji nor replaces shortcodes
* **Default**: `true`

```json settings.json theme={null}
{
  "emojiCompletionEnabled": false
}
```

See [Emoji shortcodes](/docs/en/interactive-mode#emoji-shortcodes). Requires Claude Code v2.1.217 or later.

<span id="file-suggestion-settings" />

### `fileSuggestion`

Run your own command to supply `@` file path autocomplete instead of the built-in file suggestion. The built-in suggestion uses fast filesystem traversal; a large monorepo may do better with project-specific indexing such as a pre-built file index.

* **Scope**: [`Any file`](#scopes). Under the [status line and file suggestion gates](#status-line-and-file-suggestion-gates), Claude Code turns the command off or runs only a managed value, and skips yours without warning.
* **Type**: object with `type`, always `"command"`, and `command`, the shell command to run
* **Default**: unset, so Claude Code uses the built-in file suggestion

```json settings.json theme={null}
{
  "fileSuggestion": {
    "type": "command",
    "command": "~/.claude/file-suggestion.sh"
  }
}
```

After you save this, type `@` followed by part of a path in the prompt: the suggestions come from your command's output.

#### Command input and output

Claude Code runs the command with the same environment variables as [hooks](/docs/en/hooks), including `CLAUDE_PROJECT_DIR`, and stops waiting after five seconds. The command receives JSON on stdin with a `query` field holding what you've typed so far:

```json theme={null}
{"query": "src/comp"}
```

Print newline-separated file paths to stdout. Claude Code shows at most 15:

```text theme={null}
src/components/Button.tsx
src/components/Modal.tsx
src/components/Form.tsx
```

The following script reads the query and hands it to a repository file index:

```bash theme={null}
#!/bin/bash
query=$(cat | jq -r '.query')
# Replace your-repo-file-index with your own file search command
your-repo-file-index --query "$query" | head -20
```

<span id="footer-link-badges" />

### `footerLinksRegexes`

Render extra clickable badges in the footer below the input box when a regex matches turn output: tool results, including file contents and fetched pages, and Claude's own responses. Use it to turn IDs printed by project CLIs, such as review tools and issue trackers, into session links.

* **Scope**: [`User or managed`](#scopes)
* **Type**: array of objects, each with `type` set to `"regex"`, a `pattern` regex, a `url` template, and an optional `label`; `{name}` placeholders in `url` and `label` are filled from named capture groups in `pattern`
* **Default**: unset, so no badges render

This example matches issue keys such as `PROJ-1234` and builds each link from the captured key:

```json settings.json theme={null}
{
  "footerLinksRegexes": [
    {
      "type": "regex",
      "pattern": "\\b(?<key>PROJ-\\d+)\\b",
      "url": "https://issues.example.com/browse/{key}",
      "label": "{key}"
    }
  ]
}
```

With this configured, when `PROJ-1234` appears in a tool result or in Claude's reply, a `PROJ-1234` badge appears in the footer linking to `https://issues.example.com/browse/PROJ-1234`.

#### Badge constraints

Each entry's URL, label, and badge count are bounded as follows:

| Constraint | Behavior |
| :- | :- |
| URL origin | Captured values are URL-encoded and the constructed URL must share the template's literal origin. A capture can fill a path segment or query value but can't change where the link points |
| URL length | Constructed URLs longer than 2048 characters are dropped |
| URL scheme | Must be `https`, `http`, or a recognized editor or workspace deep-link scheme: `vscode`, `vscode-insiders`, `cursor`, `windsurf`, `zed`, `jetbrains`, `idea`, `slack`, `linear`, `notion`, `figma` |
| Label | Defaults to the matched text and is truncated to 28 display columns |
| Badge count | At most 5 badges render. The oldest is displaced by newer matches and `/clear` removes them |

When a turn completes, Claude Code matches each entry's `pattern` regex against the turn output on the main thread, so a slow regex blocks the UI until it finishes. Nested quantifiers such as `(a+)+$` can take exponentially long against certain inputs and freeze the session, so keep each `pattern` linear and avoid nesting `+` or `*`.

Footer badges render alongside a [custom status line](/docs/en/statusline) when one is configured; neither replaces the other. Use a status line for a script-driven row that computes its own content from session data, and footer badges to turn IDs from the conversation into links without a script.

### `keybindingFlavor`

<Warning>
  Deprecated since v2.1.261 and has no effect. The prompt's word-editing keys always [follow readline conventions](/docs/en/interactive-mode#make-ctrl-w-delete-back-to-whitespace), as in Bash. Claude Code still accepts `keybindingFlavor`, so a settings file that sets it stays valid.
</Warning>

In v2.1.238 through v2.1.260, setting it to `"readline"` made `Ctrl+W` delete back to the previous whitespace instead of only the previous word.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, `"classic"` or `"readline"`
* **Default**: unset

### `maxProseWidth`

Cap the width of the prose in Claude's responses so lines stay readable in a wide terminal. Paragraphs, headings, lists, and blockquotes wrap within this many columns, while tables and code blocks keep the full terminal width. Requires Claude Code v2.1.282 or later.

* **Scope**: [`Any file`](#scopes)
* **Type**: number of terminal columns, a whole number, minimum `40`. Claude Code ignores any other value
* **Default**: unset, so prose wraps at the terminal edge

```json settings.json theme={null}
{
  "maxProseWidth": 80
}
```

### `prefersReducedMotion`

Reduce or turn off interface animations such as the spinner, shimmer, and flash effects. Appears in `/config` as **Reduce motion**.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code reduces or turns off interface animations such as the spinner, shimmer, and flash effects
  * `false`: the same as unset; Claude Code shows its animations
* **Default**: `false`

```json settings.json theme={null}
{
  "prefersReducedMotion": true
}
```

### `promptSuggestionEnabled`

Show or hide [prompt suggestions](/docs/en/interactive-mode#prompt-suggestions), the grayed-out predictions that appear in your prompt input. Set it to `false`, or turn off **Prompt suggestions** in `/config`, to hide them.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: you see prompt suggestions in your prompt input
  * `false`: Claude Code hides prompt suggestions
* **Default**: `true`
* **Per-session overrides**: [`CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION`](/docs/en/env-vars) takes precedence over this key for one session

```json settings.json theme={null}
{
  "promptSuggestionEnabled": false
}
```

Prompt suggestions need a claude.ai or Console account with telemetry on. On Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry, or with telemetry turned off, such as by [`DISABLE_TELEMETRY`](/docs/en/env-vars), this key has no effect and only `CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION=1` turns them on.

### `respectGitignore`

Control whether the `@` file picker leaves out files that match `.gitignore` patterns. Appears in `/config` as **Respect .gitignore in file picker**.

* **Scope**: [`Any file`](#scopes). When no settings file sets it, Claude Code falls back to `respectGitignore` in `~/.claude.json`, which the `/config` toggle writes.
* **Type**: Boolean
  * `true`: the `@` file picker leaves out files that match `.gitignore` patterns
  * `false`: the `@` file picker includes files that match `.gitignore` patterns
* **Default**: `true`

```json settings.json theme={null}
{
  "respectGitignore": false
}
```

### `respondToBashCommands`

Choose whether Claude responds after you run a shell command with the [`!` prefix](/docs/en/interactive-mode#shell-mode-with-prefix) in the input box. By default, Claude Code adds the command's output to the conversation and Claude replies to it. Set this key to `false` to add the output to context without a reply, so you can run several commands and ask about them together.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code adds the command's output to the conversation and Claude replies to it
  * `false`: Claude Code adds the output to context without a reply
* **Default**: `true`

```json settings.json theme={null}
{
  "respondToBashCommands": false
}
```

See [Shell mode with `!` prefix](/docs/en/interactive-mode#shell-mode-with-prefix).
