[Part 1/3 of https://code.claude.com/docs/en/hooks-guide.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Automate actions with hooks

> Run shell commands automatically when Claude Code edits files, finishes tasks, or needs input. Format code, send notifications, validate commands, and enforce project rules.

Hooks are user-defined shell commands. Claude Code runs them at specific points in its lifecycle, which gives you deterministic control: certain actions always happen rather than relying on the LLM to choose to run them. Use hooks to enforce project rules, automate repetitive tasks, and integrate Claude Code with your existing tools.

For decisions that require judgment rather than deterministic rules, you can also use [prompt-based hooks](#prompt-based-hooks) or [agent-based hooks](#agent-based-hooks) that use a Claude model to evaluate conditions.

For other ways to extend Claude Code, see [skills](/docs/en/skills) for giving Claude additional instructions and executable commands, [subagents](/docs/en/sub-agents) for running tasks in isolated contexts, and [plugins](/docs/en/plugins/overview) for packaging extensions to share across projects.

<Tip>
  This guide covers common use cases and how to get started. For full event schemas, JSON input/output formats, and advanced features like async hooks and MCP tool hooks, see the [Hooks reference](/docs/en/hooks).
</Tip>

## Set up your first hook

To create a hook, add a `hooks` block to a [settings file](#configure-hook-location). This walkthrough creates a desktop notification hook, so you get alerted whenever Claude is waiting for your input instead of watching the terminal.

<Steps>
  <Step title="Add the hook to your settings">
    Open `~/.claude/settings.json` and add a `Notification` hook. If the file doesn't exist, create it. The example below uses `osascript` for macOS; see [Get notified when Claude needs input](#get-notified-when-claude-needs-input) for Linux and Windows commands.

    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
              }
            ]
          }
        ]
      }
    }
    ```

    If your settings file already has a `hooks` key, add `Notification` as a sibling of the existing event keys rather than replacing the whole object. Each event name is a key inside the single `hooks` object:

    ```json theme={null}
    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Edit|Write",
            "hooks": [{ "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write" }]
          }
        ],
        "Notification": [
          {
            "matcher": "",
            "hooks": [{ "type": "command", "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'" }]
          }
        ]
      }
    }
    ```

    You can also ask Claude to write the hook for you by describing what you want in the CLI.
  </Step>

  <Step title="Verify the configuration">
    Type `/hooks` at the Claude Code prompt to open the hooks browser. Your new hook appears in the list under `Notification`.
  </Step>

  <Step title="Test the hook">
    Press `Esc` to return to the CLI. Press `Shift+Tab` until the status bar shows `⏸ manual mode on`, ask Claude to do something that requires permission, then switch away from the terminal. You should receive a desktop notification.
  </Step>
</Steps>

## What you can automate

Hooks let you run code at key points in Claude Code's lifecycle: format files after edits, block commands before they execute, send notifications when Claude needs input, inject context at session start, and more. For the full list of hook events, see the [Hooks reference](/docs/en/hooks#hook-lifecycle).

Each example includes a ready-to-use configuration block that you add to a [settings file](#configure-hook-location).

For a production example of hooks that run a separate model review and feed findings back into the session, see [how the `security-guidance` plugin integrates with Claude Code](/docs/en/security-guidance#how-the-plugin-integrates-with-claude-code).

### Get notified when Claude needs input

Get a desktop notification whenever Claude finishes working and needs your input, so you can switch to other tasks without checking the terminal.

This hook uses the `Notification` event, which Claude Code fires when Claude is waiting for input or permission. See [when each notification type fires](/docs/en/hooks#notification) for the exact timing.

Each tab below uses the platform's native notification command. Add this to `~/.claude/settings.json`:

<Tabs>
  <Tab title="macOS">
    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
              }
            ]
          }
        ]
      }
    }
    ```

    <Accordion title="If no notification appears">
      `osascript` routes notifications through the built-in Script Editor app. If Script Editor doesn't have notification permission, the command fails silently, and macOS won't prompt you to grant it.

      Run this in Terminal once to make Script Editor appear in your notification settings:

      ```bash theme={null}
      osascript -e 'display notification "test"'
      ```

      Nothing will appear yet. Open **System Settings > Notifications**, find **Script Editor** in the list, and turn on **Allow Notifications**. Run the command again to confirm the test notification appears.
    </Accordion>
  </Tab>

  <Tab title="Linux">
    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "notify-send 'Claude Code' 'Claude Code needs your attention'"
              }
            ]
          }
        ]
      }
    }
    ```

    <Accordion title="If no notification appears">
      `notify-send` needs a desktop notification daemon, which headless servers, SSH sessions, and most containers don't have. Test the command directly first:

      ```bash theme={null}
      notify-send 'Claude Code' 'test'
      ```

      If the command isn't found, install the `libnotify-bin` package on Debian and Ubuntu, or your distribution's equivalent.
    </Accordion>
  </Tab>

  <Tab title="Windows (PowerShell)">
    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "powershell.exe -Command \"[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Claude Code needs your attention', 'Claude Code')\""
              }
            ]
          }
        ]
      }
    }
    ```

    <Accordion title="If no dialog appears">
      This command opens a dialog box rather than a notification in the corner of your screen, so the dialog can open behind your terminal window. Test the command directly in PowerShell first.

      If you run Claude Code inside WSL, `powershell.exe` must be available on your `PATH` through Windows interop.
    </Accordion>
  </Tab>
</Tabs>

The empty `matcher` fires on all notification types. To fire only on specific events, set it to one of these values:

| Matcher | Fires when |
| :- | :- |
| `permission_prompt` | Claude needs you to approve a tool use or a sandboxed command's [network request](/docs/en/sandboxing#network-isolation), and the prompt has waited about six seconds |
| `idle_prompt` | Claude finished responding about 60 seconds ago and you haven't typed since |
| `auth_success` | Authentication completes |
| `elicitation_dialog` | An MCP server opens an elicitation form and you haven't typed for about six seconds |
| `elicitation_url_dialog` | An MCP server asks you to open a browser URL and you haven't typed for about six seconds |
| `elicitation_complete` | An MCP server reports that a [URL-mode elicitation](/docs/en/hooks#elicitation-input) is complete |
| `elicitation_response` | An MCP elicitation response is sent back to the server |
| `agent_needs_input` | A background session starts waiting on your input while [agent view](/docs/en/agent-view) is open. Also fires when a terminal session shows you an [agent team teammate's terminal setup question](/docs/en/agent-teams#choose-a-display-mode) or auto mode's notice about [classifier request charges](/docs/en/auto-mode-classifier-billing) and you haven't typed for about six seconds |
| `agent_completed` | A background session finishes or fails. Fires only while [agent view](/docs/en/agent-view) is open |
| `quota_auto_resume_fired` | Claude Code continues your task after a claude.ai usage limit paused it: at the reset, or sooner when something you do in Claude Code during the wait, such as adding usage credits, upgrading your plan, or switching models, makes usage available again, with the [model-setting exception](/docs/en/interactive-mode#wait-for-a-usage-limit-to-reset) |
| `quota_auto_resume_stale` | A claude.ai usage limit reset while your computer slept for more than about 30 minutes. Claude Code waits for you to press `Enter` instead of continuing. After a shorter sleep it continues and fires `quota_auto_resume_fired` instead |
| `quota_auto_resume_disabled` | Claude Code ends its wait for a claude.ai usage limit without continuing your task: [`autoContinueAtUsageLimit`](/docs/en/settings-reference#autocontinueatusagelimit) turned off or the reset moved more than 24 hours away during a wait Claude Code started on its own, the continued task kept hitting the limit, or the continuation was blocked before it reached the model. Doesn't fire when you press `Esc` or `Ctrl+C`, or pick **Don't continue automatically** |

Claude Code times `permission_prompt` differently in a terminal and in Claude Desktop, the VS Code extension, and other hosts that answer permission requests through the Agent SDK. See [when each notification type fires](/docs/en/hooks#notification) for both timings.

The `quota_auto_resume_fired`, `quota_auto_resume_stale`, and `quota_auto_resume_disabled` matchers require Claude Code v2.1.234 or later.

In terminal sessions, `permission_prompt` for a sandboxed command's network request requires Claude Code v2.1.246 or later.

`agent_needs_input` for a teammate's terminal setup question requires Claude Code v2.1.248 or later.

Type `/hooks` at the Claude Code prompt and confirm the hook appears under `Notification`.

### Auto-format code after edits

Automatically run [Prettier](https://prettier.io/) on every file Claude edits, so formatting stays consistent without manual intervention.

This hook uses the `PostToolUse` event with an `Edit|Write` matcher, so it runs only after file-editing tools. The command extracts the edited file path with [`jq`](https://jqlang.org/) and passes it to Prettier. Add this to `.claude/settings.json` in your project root:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

To test the hook, ask Claude to add a line with single-quoted strings to a JavaScript file, then open the file: with Prettier's default settings, the hook rewrites them to double quotes.

When the hook succeeds, Claude Code shows nothing in the conversation. To confirm the hook ran, check that the edited file is reformatted, or see [Debug techniques](#debug-techniques).

To reformat a specific file however it changes, including when a `Bash` command rewrites it, use a [FileChanged](/docs/en/hooks#filechanged) hook instead.

<Note>
  The Bash examples on this page use `jq` for JSON parsing. Install it with `brew install jq` on macOS, `apt-get install jq` on Debian and Ubuntu, or see [`jq` downloads](https://jqlang.org/download/).
</Note>

### Block edits to protected files

Prevent Claude from modifying sensitive files like `.env`, `package-lock.json`, or anything in `.git/`. Claude receives feedback explaining why the edit was blocked, so it can adjust its approach.

This example uses a separate script file that the hook calls. The script checks the target file path against a list of protected patterns and exits with code 2 to block the edit.

<Steps>
  <Step title="Create the hook script">
    Save this to `.claude/hooks/protect-files.sh`:

    ```bash theme={null}
    #!/bin/bash
    # protect-files.sh

    INPUT=$(cat)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

    # Normalize Windows backslash separators so the patterns below match
    FILE_PATH="${FILE_PATH//\\//}"

    PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

    for pattern in "${PROTECTED_PATTERNS[@]}"; do
      if [[ "$FILE_PATH" == *"$pattern"* ]]; then
        echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
        exit 2
      fi
    done

    exit 0
    ```
  </Step>

  <Step title="Make the script executable on macOS and Linux">
    Hook scripts must be executable for Claude Code to run them:

    ```bash theme={null}
    chmod +x .claude/hooks/protect-files.sh
    ```
  </Step>

  <Step title="Register the hook">
    Add a `PreToolUse` hook to `.claude/settings.json` that runs the script before any `Edit` or `Write` tool call:

    ```json theme={null}
    {
      "hooks": {
        "PreToolUse": [
          {
            "matcher": "Edit|Write",
            "hooks": [
              {
                "type": "command",
                "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
              }
            ]
          }
        ]
      }
    }
    ```
  </Step>

  <Step title="Test the hook">
    Ask Claude to add a comment to your `.env` file. Claude Code blocks the edit before it runs and passes the script's `Blocked:` message to Claude as feedback.
  </Step>
</Steps>

### Re-inject context after compaction

When Claude's context window fills up, compaction summarizes the conversation to free space. This can lose important details. Use a `SessionStart` hook with a `compact` matcher to re-inject critical context after every compaction.

Claude Code adds plain text your command writes to stdout to Claude's context. This example reminds Claude of project conventions and recent work. Add this to `.claude/settings.json` in your project root:

```json theme={null}
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
          }
        ]
      }
    ]
  }
}
```

You can replace the `echo` with any command that produces dynamic output, like `git log --oneline -5` to show recent commits. For injecting context on every session start, consider using [CLAUDE.md](/docs/en/memory) instead. For environment variables, see [`CLAUDE_ENV_FILE`](/docs/en/hooks#persist-environment-variables) in the reference.

### Audit configuration changes

Track when settings or skills files change during a session. The `ConfigChange` event fires when an external process or editor modifies a configuration file, so you can log changes for compliance or block unauthorized modifications.

This example appends each change to an audit log. Add this to `~/.claude/settings.json`:

```json theme={null}
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '{timestamp: now | todate, source: .source, file: .file_path}' >> ~/claude-config-audit.log"
          }
        ]
      }
    ]
  }
}
```

The matcher filters by configuration type: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, or `skills`. To block a change from taking effect, exit with code 2 or return `{"decision": "block"}`. See the [ConfigChange reference](/docs/en/hooks#configchange) for the full input schema.

To confirm the hook records changes, edit a settings file in another editor while a session is running, then open `~/claude-config-audit.log`: the hook appends one JSON line per change with the timestamp, source, and file path.

### Reload environment when directory or files change

Some projects set different environment variables depending on which directory you are in. Tools like [direnv](https://direnv.net/) do this automatically in your shell, but Claude's Bash tool doesn't pick up those changes on its own.

Pairing a `SessionStart` hook with a `CwdChanged` hook fixes this. `SessionStart` loads the variables for the directory you launch in, and `CwdChanged` reloads them each time Claude changes directory. Both write to `CLAUDE_ENV_FILE`, which Claude Code runs as a script preamble before each Bash command. Add this to `~/.claude/settings.json`:

```json theme={null}
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
          }
        ]
      }
    ],
    "CwdChanged": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
          }
        ]
      }
    ]
  }
}
```

Run `direnv allow` once in each directory that has an `.envrc` so direnv is permitted to load it. If you use devbox or nix instead of direnv, the same pattern works with `devbox shellenv` or `devbox global shellenv` in place of `direnv export bash`.

To react to specific files instead of every directory change, use `FileChanged` with a `matcher` listing the filenames to watch, separated by `|`. When building the watch list, Claude Code splits this value into literal filenames rather than evaluating it as a regex. See [FileChanged](/docs/en/hooks#filechanged) for how the same value also filters which hook groups run when a file changes. This example watches `.envrc` and `.env` in the working directory:

```json theme={null}
{
  "hooks": {
    "FileChanged": [
      {
        "matcher": ".envrc|.env",
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
          }
        ]
      }
    ]
  }
}
```

See the [CwdChanged](/docs/en/hooks#cwdchanged) and [FileChanged](/docs/en/hooks#filechanged) reference entries for input schemas, `watchPaths` output, and `CLAUDE_ENV_FILE` details.

### Auto-approve specific permission prompts

Skip the approval dialog for tool calls you always allow. This example auto-approves `ExitPlanMode`, the tool Claude calls when it finishes presenting a plan and asks to proceed, so you aren't prompted every time a plan is ready.

Unlike the exit-code examples above, auto-approval requires your hook to write a JSON decision to stdout. Claude Code runs `PermissionRequest` hooks when it's about to ask you for permission, and if your hook returns `"behavior": "allow"`, Claude Code answers the request on your behalf.

The matcher scopes the hook to `ExitPlanMode` only, so no other prompts are affected. Add this to `~/.claude/settings.json`:

```json theme={null}
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\": {\"hookEventName\": \"PermissionRequest\", \"decision\": {\"behavior\": \"allow\"}}}'"
          }
        ]
      }
    ]
  }
}
```

When the hook approves, Claude Code exits plan mode and restores whatever permission mode was active before you entered plan mode. The transcript shows "Allowed by PermissionRequest hook" where the dialog would have appeared. The hook path always keeps the current conversation: it can't clear context and start a fresh implementation session the way the dialog can.

To set a specific permission mode instead, your hook's output can include an `updatedPermissions` array with a `setMode` entry. The `mode` value is any permission mode like `default`, `acceptEdits`, or `bypassPermissions`, and `destination: "session"` applies it for the current session only.

<Note>
  `bypassPermissions` only applies if you started the session with bypass mode already available: `--dangerously-skip-permissions`, `--permission-mode bypassPermissions`, `--allow-dangerously-skip-permissions`, or `permissions.defaultMode: "bypassPermissions"` in [user, `--settings`, or managed settings](/docs/en/settings-reference#permissions-defaultmode). It doesn't apply if bypass mode is disabled by [`permissions.disableBypassPermissionsMode`](/docs/en/permissions#managed-settings), or if you started the session in [restricted mode](/docs/en/cli-reference#cli-flags).

  Claude Code never saves it as `defaultMode`.
</Note>

To switch the session to `acceptEdits`, your hook writes this JSON to stdout:

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow",
      "updatedPermissions": [
        { "type": "setMode", "mode": "acceptEdits", "destination": "session" }
      ]
    }
  }
}
```

Keep the matcher as narrow as possible. Matching on `.*` or leaving the matcher empty would auto-approve every tool permission prompt, including file writes and shell commands. See the [PermissionRequest reference](/docs/en/hooks#permissionrequest-decision-control) for the full set of decision fields.
