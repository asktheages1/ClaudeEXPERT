[Part 2/3 of https://code.claude.com/docs/en/hooks-guide.md, fetched 2026-10-08]

## How hooks work

Claude Code fires hook events at specific points in its lifecycle. When an event fires, Claude Code runs all matching hooks in parallel; see [Hook handler fields](/docs/en/hooks#hook-handler-fields) for how duplicate handlers are treated. The table below shows each event and when it triggers:

| Event | When it fires |
| :- | :- |
| `SessionStart` | When a session begins or resumes |
| `Setup` | When you start Claude Code with `--init-only`, or with `--init` or `--maintenance` in `-p` mode. For one-time preparation in CI or scripts |
| `UserPromptSubmit` | When a prompt is submitted, before Claude processes it. Also fires on [turns Claude Code starts on its own](/docs/en/hooks#userpromptsubmit) |
| `UserPromptExpansion` | When a user-typed command expands into a prompt, before it reaches Claude. Can block the expansion |
| `PreToolUse` | Before a tool call executes. Can block it |
| `PermissionRequest` | When a tool call needs a permission decision |
| `PermissionDenied` | When auto mode denies a tool call, including denials without a classifier verdict. Use JSON `hookSpecificOutput.retry: true` to tell the model it may retry the denied tool call. Claude Code ignores `retry` when the classifier produced no verdict |
| `PostToolUse` | After a tool call succeeds |
| `PostToolUseFailure` | After a tool call fails |
| `PostToolBatch` | After a full batch of parallel tool calls resolves, before the next model call |
| `Notification` | When Claude Code sends a notification |
| `MessageDisplay` | While assistant message text is displayed |
| `SubagentStart` | When a subagent is spawned |
| `SubagentStop` | When a subagent finishes |
| `TaskCreated` | When a task is being created via `TaskCreate` |
| `TaskCompleted` | When a task is being marked as completed |
| `Stop` | When Claude finishes responding |
| `StopFailure` | When the turn ends due to an API error |
| `TeammateIdle` | When an [agent team](/docs/en/agent-teams) teammate is about to go idle |
| `InstructionsLoaded` | When a CLAUDE.md or `.claude/rules/*.md` file is loaded into context. Fires at session start and when files are lazily loaded during a session |
| `ConfigChange` | When a configuration file changes during a session |
| `CwdChanged` | When the working directory changes, for example when Claude executes a `cd` command. Useful for reactive environment management with tools like direnv |
| `DirectoryAdded` | When a working directory is added mid-session via `/add-dir` or the SDK `register_repo_root` control request |
| `FileChanged` | When a watched file changes on disk. The `matcher` field specifies which filenames to watch |
| `WorktreeCreate` | When a worktree is being created via `--worktree`, `isolation: "worktree"`, or for a background session. Replaces default git behavior |
| `WorktreeRemove` | When a worktree that a `WorktreeCreate` hook created is being removed |
| `PreCompact` | Before context compaction |
| `PostCompact` | After context compaction completes |
| `PreModelSwitch` | Before Claude Code applies a model switch that you or a client requested. Can block the switch |
| `PostModelSwitch` | After the session's model changes, including changes Claude Code makes on its own, such as restoring the model when you resume a session |
| `Elicitation` | When an MCP server requests user input during a tool call |
| `ElicitationResult` | After a user responds to an MCP elicitation, before the response is sent back to the server |
| `SessionEnd` | When a session terminates |

Each hook has a `type` that determines how it runs. Most hooks use `"type": "command"`, which runs a shell command. Four other types are available:

* `"type": "http"`: POST event data to a URL. See [HTTP hooks](#http-hooks).
* `"type": "mcp_tool"`: call a tool on a configured MCP server. See [MCP tool hooks](/docs/en/hooks#mcp-tool-hook-fields).
* `"type": "prompt"`: single-turn LLM evaluation. See [Prompt-based hooks](#prompt-based-hooks).
* `"type": "agent"`: multi-turn verification with tool access. Agent hooks are experimental and may change. See [Agent-based hooks](#agent-based-hooks).

### Combine results from multiple hooks

When multiple hooks match the same event, every hook's command runs to completion before Claude Code merges the results. One hook returning `deny` doesn't stop sibling hooks from executing. Don't rely on one hook's `deny` to suppress side effects in another hook.

After all matching hooks finish, Claude Code combines their outputs. For `PreToolUse` permission decisions, the most restrictive answer applies, in the order `deny`, `defer`, `ask`, `allow`. Text from `additionalContext` is kept from every hook and passed to Claude together.

The example below registers two `PreToolUse` hooks on `Bash`. The first appends every command to a log file and exits 0. The second runs a script that exits 2 to deny when the command contains `rm -rf`:

```json theme={null}
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r .tool_input.command >> ~/.claude/bash.log"
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-rm-rf.sh"
          }
        ]
      }
    ]
  }
}
```

When Claude tries to run `rm -rf /tmp/build`, both hooks execute in parallel. The logging hook writes the command to `~/.claude/bash.log` and exits 0, which reports no decision. The guardrail hook exits 2, which denies the tool call. The deny takes precedence, so Claude Code blocks the command and shows Claude the guardrail's stderr. The log entry is still written because the logging hook already ran.

### Read input and return output

Hooks communicate with Claude Code through stdin, stdout, stderr, and exit codes. When an event fires, Claude Code passes event-specific data as JSON to your script's stdin. Your script reads that data, does its work, and tells Claude Code what to do next via the exit code.

#### Hook input

Every event includes common fields like `session_id`, a unique ID for the session, and `cwd`, the working directory when the event fired, but each event type adds different data. When Claude runs a Bash command, a `PreToolUse` hook receives these fields on stdin:

* `hook_event_name`: the event that triggered the hook
* `tool_name`: the tool Claude is about to use
* `tool_input`: the arguments Claude passed to the tool. For Bash, its `command` field holds the shell command.

For example, the hook input for an `npm test` command looks like this:

```json theme={null}
{
  "session_id": "abc123",
  "cwd": "/Users/sarah/myproject",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  }
}
```

Your script can parse that JSON and act on any of those fields. `UserPromptSubmit` hooks get the `prompt` text instead, `SessionStart` hooks get a `source` of `startup`, `resume`, `clear`, `compact`, or `fork`, and so on. See [Common input fields](/docs/en/hooks#common-input-fields) in the reference for shared fields, and each event's section for event-specific schemas.

#### Hook output

Your script tells Claude Code what to do next by writing to stdout or stderr and exiting with a specific code. The following `PreToolUse` hook blocks a command:

```bash theme={null}
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

if echo "$COMMAND" | grep -q "drop table"; then
  echo "Blocked: dropping tables is not allowed" >&2  # stderr becomes Claude's feedback
  exit 2                                               # exit 2 = block the action
fi

exit 0  # exit 0 = no decision; the normal permission flow applies
```

The exit code determines what happens next:

* **Exit 0**: your hook reports no objection through its exit code.
  * For a `PreToolUse` hook this doesn't approve the tool call: the normal [permission flow](/docs/en/permissions) still applies.
  * For `UserPromptSubmit`, `UserPromptExpansion`, `SessionStart`, and `PostModelSwitch` hooks, Claude Code adds stdout it [treats as plain text](/docs/en/hooks#exit-code-0) to Claude's context.
* **Exit 2**: Claude Code blocks the action. Write a reason to stderr. Where it lands depends on the event: some events feed it to Claude as feedback so it can adjust, others show it to the user, and a few, such as `ConfigChange` and `Elicitation`, surface no message. Some events can't be blocked: for `SessionStart` and others, exit 2 shows stderr to the user and execution continues. See [exit code 2 behavior per event](/docs/en/hooks#exit-code-2-behavior-per-event) for the full list.
* **Any other exit code**: for most events, the outcome depends on what your hook printed to stdout:
  * A parsed object that passes schema validation: Claude Code ignores the exit code, the JSON alone decides the outcome, and the hook isn't reported as an error. The per-event exceptions, like `WorktreeCreate` failing on any nonzero exit, are listed in the reference's [Exit code output](/docs/en/hooks#exit-code-output) section.
  * A parsed object that fails schema validation, or stdout that Claude Code [tries to parse as JSON](/docs/en/hooks#exit-code-0) but that isn't valid JSON: a non-blocking error; the notice carries the validation or parse message.
  * Stdout that Claude Code [treats as plain text](/docs/en/hooks#exit-code-0), or empty stdout: the action proceeds as a non-blocking error. The transcript shows a `<hook name> hook error` notice, then the first line of stderr prefixed with `Failed with non-blocking status code:`. To capture the full stderr, enable [debug logging](/docs/en/hooks#debug-hooks) with `claude --debug` or by running `/debug` mid-session.

#### Structured JSON output

Exit codes only let you block or stay silent. For more control, exit 0 and print a JSON object to stdout instead.

<Note>
  Use exit 2 to block with a stderr message, or exit 0 with JSON for structured control. Choose one approach per hook. For what happens when you mix them, see [Exit code output](/docs/en/hooks#exit-code-output).
</Note>

For example, a `PreToolUse` hook can deny a tool call and tell Claude why, or escalate it to the user for approval:

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use rg instead of grep for better performance"
  }
}
```

With `"deny"`, Claude Code cancels the tool call and feeds `permissionDecisionReason` back to Claude.

On `PreToolUse`, Claude Code handles each `permissionDecision` value as follows:

* `"allow"`: skip the interactive permission prompt. Deny and ask rules, including enterprise managed deny lists, still apply, as do prompts for MCP tools marked [`requiresUserInteraction`](/docs/en/mcp#require-approval-for-a-specific-tool) and for connector tools [your organization set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code
* `"deny"`: cancel the tool call and send the reason to Claude
* `"ask"`: show the permission prompt to the user as normal

A fourth value, `"defer"`, is available in [non-interactive mode](/docs/en/headless) with the `-p` flag. It exits the process with the tool call preserved so an Agent SDK wrapper can collect input and resume. See [Defer a tool call for later](/docs/en/hooks#defer-a-tool-call-for-later) in the reference.

A `PreModelSwitch` hook returns the same `permissionDecision` field: `"allow"` lets a model switch proceed, and `"deny"` cancels it. `"ask"` has you confirm the switch when you run `/model` in an interactive session; everywhere else, Claude Code treats `"ask"` as a refusal. See [PreModelSwitch decision control](/docs/en/hooks#premodelswitch-decision-control).

Other events use different decision patterns. For example, `PostToolUse` and `Stop` hooks use a top-level `decision: "block"` field, while `PermissionRequest` uses `hookSpecificOutput.decision.behavior`. See the [summary table](/docs/en/hooks#decision-control) in the reference for a full breakdown by event.

For `UserPromptSubmit` hooks, use `hookSpecificOutput.additionalContext` instead to inject text into Claude's context. Nest `additionalContext` inside `hookSpecificOutput`; if you place it at the top level of the JSON, Claude Code silently ignores it. For example, this output adds the current branch state to every prompt:

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Current branch: release-42. Deploy freeze until Friday."
  }
}
```

See [UserPromptSubmit decision control](/docs/en/hooks#userpromptsubmit-decision-control) for the full output shape, including blocking prompts and setting the session title.

Hooks with `type: "prompt"` handle output differently: see [Prompt-based hooks](#prompt-based-hooks).

### Filter hooks with matchers

Without a matcher, a hook fires on every occurrence of its event. Matchers let you narrow that down. For example, if you want to run a formatter only after file edits, not after every tool call, add a matcher to your `PostToolUse` hook:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "prettier --write ..." }
        ]
      }
    ]
  }
}
```

The `"Edit|Write"` matcher fires only when Claude uses the `Edit` or `Write` tool, not when it uses `Bash`, `Read`, or any other tool. A comma separates alternatives the same way, so `"Edit, Write"` is equivalent. See [Matcher patterns](/docs/en/hooks#matcher-patterns) for how plain names and regular expressions are evaluated.

<Note>
  Claude can also create or modify files by running shell commands. If your hook must see every file change, such as for compliance scanning or audit logging, add a [`Stop`](/docs/en/hooks#stop) hook that scans the working tree once per turn. For per-call coverage instead, also match `Bash|PowerShell` and have your script list modified and untracked files with `git status --porcelain`. The [PowerShell hook input section](/docs/en/hooks#powershell) explains why matching `Bash` alone is not enough. To run a hook when a specific file changes on disk, whatever wrote it, use a [FileChanged](/docs/en/hooks#filechanged) hook.
</Note>

Each event type matches on a specific field:

| Event | What the matcher filters | Example matcher values |
| :- | :- | :- |
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied` | tool name | `Bash`, `Edit\|Write`, `mcp__.*` |
| `SessionStart` | how the session started | `startup`, `resume`, `clear`, `compact`, `fork` |
| `Setup` | which CLI flag triggered setup | `init`, `maintenance` |
| `SessionEnd` | why the session ended | `clear`, `resume`, `logout`, `prompt_input_exit`, `other` |
| `Notification` | notification type | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_url_dialog`, `elicitation_complete`, `elicitation_response`, `agent_needs_input`, `agent_completed`, `quota_auto_resume_fired`, `quota_auto_resume_stale`, `quota_auto_resume_disabled` |
| `SubagentStart` | agent type | `general-purpose`, `Explore`, `Plan`, or custom agent names |
| `PreCompact`, `PostCompact` | what triggered compaction | `manual`, `auto` |
| `PreModelSwitch`, `PostModelSwitch` | canonical name of the model the session switches to, as described under [PreModelSwitch](/docs/en/hooks#premodelswitch) | `claude-opus-5`, `claude-opus-4-6\|claude-opus-5`, `.*opus.*` |
| `SubagentStop` | agent type | same values as `SubagentStart` |
| `ConfigChange` | configuration source | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` |
| `DirectoryAdded` | how the directory was added | `slash_command`, `register_repo_root` |
| `StopFailure` | error type | `rate_limit`, `overloaded`, `authentication_failed`, `oauth_org_not_allowed`, `account_on_hold`, `billing_error`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, `cloud_credential_error`, `unknown` |
| `InstructionsLoaded` | load reason | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact` |
| `Elicitation` | MCP server name | your configured MCP server names |
| `ElicitationResult` | MCP server name | same values as `Elicitation` |
| `FileChanged` | literal filenames to watch (see [FileChanged](/docs/en/hooks#filechanged)) | `.envrc\|.env` |
| `UserPromptExpansion` | command name | your skill or command names |
| `UserPromptSubmit`, `PostToolBatch`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `CwdChanged`, `MessageDisplay` | no matcher support | always fires on every occurrence |

The tabs below show a few more matchers on different event types.

<Tabs>
  <Tab title="Log every Bash command">
    Match only `Bash` tool calls and log each command to a file. The `PostToolUse` event fires after the command completes, so `tool_input.command` contains what ran. The hook receives the event data as JSON on stdin, and `jq -r '.tool_input.command'` extracts only the command string, which `>>` appends to the log file:

    ```json theme={null}
    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Bash",
            "hooks": [
              {
                "type": "command",
                "command": "jq -r '.tool_input.command' >> ~/.claude/command-log.txt"
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>

  <Tab title="Match MCP tools">
    MCP tools use a different naming convention than built-in tools: `mcp__<server>__<tool>`, where `<server>` is the MCP server name and `<tool>` is the tool it provides. For example, `mcp__github__search_repositories` or `mcp__filesystem__read_file`. Tools from a [plugin-bundled server](/docs/en/mcp#plugin-provided-mcp-servers) use a scoped server segment instead, such as `mcp__plugin_my-plugin_db__query`. Use a regex matcher to target all tools from a specific server, or match across servers with a pattern like `mcp__.*__write.*`. See [Match MCP tools](/docs/en/hooks#match-mcp-tools) in the reference for the full list of examples.

    The command below extracts the tool name from the hook's JSON input with `jq` and writes it to stderr. Writing to stderr keeps stdout clean for JSON output and sends the message to the [debug log](/docs/en/hooks#debug-hooks):

    ```json theme={null}
    {
      "hooks": {
        "PreToolUse": [
          {
            "matcher": "mcp__github__.*",
            "hooks": [
              {
                "type": "command",
                "command": "echo \"GitHub tool called: $(jq -r '.tool_name')\" >&2"
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>

  <Tab title="Clean up on session end">
    The `SessionEnd` event supports matchers on the reason the session ended. This hook only fires on the `clear` reason, set when you run `/clear`, not on normal exits:

    ```json theme={null}
    {
      "hooks": {
        "SessionEnd": [
          {
            "matcher": "clear",
            "hooks": [
              {
                "type": "command",
                "command": "rm -f /tmp/claude-scratch-*.txt"
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>
</Tabs>

#### Filter by tool name and arguments with the `if` field

The `if` field uses [permission rule syntax](/docs/en/permissions) to filter hooks by tool name and arguments together, so the hook process only spawns when the tool call matches. This goes beyond `matcher`, which filters at the group level by tool name only.

For example, this configuration runs a hook only when Claude uses `git` commands rather than all Bash commands:

```json theme={null}
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git *)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-git-policy.sh"
          }
        ]
      }
    ]
  }
}
```

Whether your hook command runs depends on the shape of your `if` pattern and the Bash command Claude is invoking:

| `if` pattern | Bash command | Hook runs? | Why |
| :- | :- | :- | :- |
| `Bash(git *)` | `git push` | yes | command name matches |
| `Bash(git *)` | `npm test && git push` | yes | each subcommand is checked; `git push` matches |
| `Bash(git *)` | `echo $(git log)` | yes | commands inside `$()` and backticks are checked; `git log` matches |
| `Bash(git *)` | `echo $(date)` | no | no subcommand matches `git *` |
| `Bash(git push *)` | `echo $(date)` | yes | patterns that specify more than the command name run the hook anyway on `$()`, backticks, or `$VAR` |

When Claude Code can't determine which commands the Bash input runs, it runs your hook regardless of the pattern. The [Bash matching table](/docs/en/hooks#bash-if-matching) covers the command shapes Claude Code can and can't narrow by subcommand. Because the filter is best-effort, use the [permission system](/docs/en/permissions) rather than a hook to enforce a hard allow or deny.

The `if` field accepts the same patterns as permission rules: `"Bash(git *)"`, `"Edit(*.ts)"`, and so on. To match multiple tool names, use separate handlers each with its own `if` value, or match at the `matcher` level where pipe alternation is supported.

`if` only works on tool events: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, and `PermissionDenied`. Adding it to any other event prevents the hook from running.
