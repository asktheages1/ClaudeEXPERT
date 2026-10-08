[Part 3/3 of https://code.claude.com/docs/en/hooks-guide.md, fetched 2026-10-08]

### Configure hook location

Where you add a hook determines its scope:

| Location | Scope | Shareable |
| :- | :- | :- |
| `~/.claude/settings.json` | All your projects | No, local to your machine |
| `.claude/settings.json` | Single project | Yes, can be committed to the repo |
| `.claude/settings.local.json` | Single project | No, gitignored when Claude Code saves a setting to it |
| Managed policy settings | Organization-wide | Yes, admin-controlled |
| [Plugin](/docs/en/plugins/overview) `hooks/hooks.json` | When plugin is enabled | Yes, bundled with the plugin |
| [Skill](/docs/en/skills) frontmatter | The rest of the session once the skill is invoked. See [Hooks in skills and agents](/docs/en/hooks#hooks-in-skills-and-agents) | Yes, defined in the skill file |
| [Subagent](/docs/en/sub-agents) frontmatter | While that subagent is running | Yes, defined in the subagent file |

Run [`/hooks`](/docs/en/hooks#the-%2Fhooks-menu) in Claude Code to browse all configured hooks grouped by event.

To disable hooks, set `"disableAllHooks": true` in your settings file. Claude Code reads the value left after [settings precedence](/docs/en/hooks#disable-or-remove-hooks) applies, so a project's settings file can override yours. Hooks configured in managed settings still run unless `disableAllHooks` is also set there. For the full reach of each level, see [`disableAllHooks`](/docs/en/settings-reference#disableallhooks).

If you edit settings files directly while Claude Code is running, the file watcher normally picks up hook changes automatically.

## Prompt-based hooks

For decisions that require judgment rather than deterministic rules, use `type: "prompt"` hooks. Instead of running a shell command, Claude Code sends your prompt and the hook's input data to a Claude model to make the decision. You can specify a different model with the `model` field if you need more capability.

The model's only job is to return its decision as JSON:

* `"ok": true`: the action proceeds
* `"ok": false`: what happens depends on the event:
  * `Stop` and `SubagentStop`: the `reason` is fed back to Claude so it keeps working, unless the response also sets `"impossible": true` to mark the condition as one that can never be satisfied, in which case Claude Code allows the stop and the turn ends
  * `PreToolUse`: the tool call is denied; by default the turn ends and the deny `reason` appears in the chat as a warning line. Set `continueOnBlock: true` on the hook to instead return the `reason` to Claude as the tool error, so it can adjust and continue. Before v2.1.210, the deny `reason` was returned to Claude as the tool error and the turn continued
  * `PostToolUse`: by default the turn ends and the `reason` appears in the chat as a warning line. Set `continueOnBlock: true` to feed the `reason` back to Claude and continue the turn instead
  * `PostToolBatch`, `UserPromptSubmit`, and `UserPromptExpansion`: the turn ends and the `reason` appears in the chat as a warning line

This example uses a `Stop` hook to ask the model whether all requested tasks are complete. If the model returns `"ok": false` because the condition isn't met yet, Claude keeps working and uses the `reason` as its next instruction:

```json theme={null}
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains to be done\"}."
          }
        ]
      }
    ]
  }
}
```

For full configuration options, see [Prompt-based hooks](/docs/en/hooks#prompt-based-hooks) in the reference.

## Agent-based hooks

<Warning>
  Agent hooks are experimental. Behavior and configuration may change in future releases. For production workflows, prefer [command hooks](/docs/en/hooks#command-hook-fields).
</Warning>

When verification requires inspecting files or running commands, use `type: "agent"` hooks. Unlike prompt hooks, which make a single LLM call, agent hooks spawn a subagent that can read files, search code, and use other tools to verify conditions before returning a decision.

Agent hooks use the `"ok"` / `"reason"` response format with a longer default timeout of 60 seconds and up to 50 tool-use turns. They don't support the prompt-hook `impossible` field. On `ok: false`, Claude Code handles an agent hook the way it handles a prompt hook with `continueOnBlock: true` on the same event, so on `PreToolUse` and `PostToolUse` the turn continues; agent hooks have no `continueOnBlock` field. See [agent hook configuration](/docs/en/hooks#agent-hook-configuration) for the fields, including the `$ARGUMENTS` placeholder that Claude Code replaces with the hook's JSON input.

This example verifies that tests pass before allowing Claude to stop:

```json theme={null}
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Use prompt hooks when the hook input data alone is enough to make a decision. Use agent hooks when you need to verify something against the actual state of the codebase.

For full configuration options, see [Agent-based hooks](/docs/en/hooks#agent-based-hooks) in the reference.

## HTTP hooks

Use `type: "http"` hooks to POST event data to an HTTP endpoint instead of running a shell command. The endpoint receives the same JSON that a command hook would receive on stdin, and returns results through the HTTP response body using the same JSON format.

HTTP hooks are useful when you want a web server, cloud function, or external service to handle hook logic: for example, a shared audit service that logs tool use events across a team.

This example posts every tool use to a local logging service:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/tool-use",
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ]
  }
}
```

The endpoint should return a JSON response body using the same [output format](/docs/en/hooks#json-output) as command hooks. To block a tool call, return a 2xx response with the appropriate `hookSpecificOutput` fields. HTTP status codes alone can't block actions.

Header values support environment variable interpolation using `$VAR_NAME` or `${VAR_NAME}` syntax. Only variables listed in the `allowedEnvVars` array are resolved; all other `$VAR` references remain empty.

For full configuration options and response handling, see [HTTP hooks](/docs/en/hooks#http-hook-fields) in the reference.

## Limitations and troubleshooting

### Limitations

Keep these constraints in mind when designing hooks:

* Command hooks communicate through stdout, stderr, and exit codes only. They can't trigger `/` commands or tool calls. Text returned via `additionalContext` is injected as a [system reminder](/docs/en/glossary#system-reminder) that Claude reads as plain text. HTTP hooks communicate through the response body instead.
* Hook timeouts vary by type. Override per hook with the `timeout` field in seconds.
  * `command`, `http`, `mcp_tool`: 10 minutes. Claude Code lowers this default to 30 seconds for `UserPromptSubmit`, `PreModelSwitch`, and `PostModelSwitch` hooks, and to 10 seconds for `MessageDisplay`.
  * `prompt`: 30 seconds.
  * `agent`: 60 seconds.
  * [`SessionEnd`](/docs/en/hooks#sessionend) hooks of any type share a 1.5-second budget. If your settings set a longer per-hook `timeout`, Claude Code raises the budget to match, up to 60 seconds.
* `PostToolUse` hooks can't undo actions since the tool has already executed.
* [`PermissionRequest`](/docs/en/hooks#permissionrequest) hooks fire when Claude Code is about to ask you for permission, or when it would otherwise auto-deny a call that can't prompt. In [non-interactive mode](/docs/en/headless) with the `-p` flag, they still run outside [`dontAsk` mode](/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode), and a call that no hook decides and nothing else can answer is denied.
* `Stop` hooks fire whenever Claude finishes responding, not only at task completion. They don't fire on user interrupts. API errors fire [StopFailure](/docs/en/hooks#stopfailure) instead.
* When multiple `PreToolUse` hooks return [`updatedInput`](/docs/en/hooks#pretooluse) to rewrite a tool's arguments, the last one to finish takes effect. Since hooks run in parallel, the order is non-deterministic. Avoid having more than one hook modify the same tool's input.

### Hooks and permission modes

`PreToolUse` hooks fire before any permission-mode check, in every [permission mode](/docs/en/permission-modes), including `dontAsk`. A hook that returns `permissionDecision: "deny"` blocks the tool even in `bypassPermissions` mode or with `--dangerously-skip-permissions`. This lets you enforce policy that users can't bypass by changing their permission mode.

The reverse is not true: a hook returning `"allow"` doesn't bypass deny rules from settings, and it can't suppress the prompt for MCP tools marked [`requiresUserInteraction`](/docs/en/mcp#require-approval-for-a-specific-tool) or for connector tools [your organization set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code. Hooks in settings files and in a plugin's `hooks/hooks.json` can tighten restrictions but not loosen them past what permission rules allow.

A [mod](/docs/en/plugins/mods/overview) you install that handles `tool.check` can approve a call that your `PreToolUse` hook blocked, unless the hook is in managed settings. [Extend permissions with hooks](/docs/en/permissions#extend-permissions-with-hooks) lists which rules hold over a mod.

### Hook not firing

The hook is configured but never executes.

* Run `/hooks` and confirm the hook appears under the correct event
* Check that the matcher pattern matches the tool name exactly. Matchers are case-sensitive
* Verify you're triggering the right event type: `PreToolUse` fires before tool execution, `PostToolUse` fires after. A `PermissionRequest` hook fires when Claude Code is about to ask you for permission; see the [limitations](#limitations) for the non-interactive cases

### Hook error in output

You see a message like "PreToolUse hook error: ..." in the transcript.

* Your script exited with a non-zero code unexpectedly. Test it manually by piping sample JSON:
  ```bash theme={null}
  echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh
  echo $?  # Check the exit code
  ```
* If you see "command not found", use absolute paths or `${CLAUDE_PROJECT_DIR}` to reference scripts. To avoid shell quoting entirely, add `"args": []` to switch to [exec form](/docs/en/hooks#exec-form-and-shell-form), which spawns the script directly without a shell
* If you see "jq: command not found", install `jq` or use Python/Node.js for JSON parsing
* If the notice shows a JSON validation message, your hook's stdout parsed as JSON but failed schema validation. If it shows a JSON parse message, the stdout looked like a JSON object but wasn't valid JSON. Both happen even on exit 0.

  To fix a parse failure, build the payload with a JSON encoder such as `jq` instead of string concatenation, so quotes and backslashes inside values are escaped. The reference's [Exit code output](/docs/en/hooks#exit-code-output) section covers the exit-code and JSON combinations
* If the script isn't running at all, make it executable: `chmod +x ./my-hook.sh`

### `/hooks` shows no hooks configured

You edited a settings file but the hooks don't appear in the menu.

* File edits are normally picked up automatically. If they haven't appeared after a few seconds, the file watcher may have missed the change: restart your session to force a reload.
* Verify your JSON is valid: trailing commas and comments aren't allowed
* Confirm the settings file is in the correct location: `.claude/settings.json` for project hooks, `~/.claude/settings.json` for global hooks
* If the menu shows `Only hooks from managed settings run here`, your organization has set [`allowManagedHooksOnly`](/docs/en/settings-reference#allowmanagedhooksonly). Hooks in your user, project, and local settings files don't run and aren't listed

### Stop hook hits the block cap

Claude keeps working instead of stopping, then ends the turn with a warning that the Stop hook blocked too many consecutive times.

Claude Code overrides a Stop hook after it blocks eight times in a row with no tool call from Claude in between. Your hook script needs to check whether it already triggered a continuation. Parse the `stop_hook_active` field from the JSON input and exit early if it's `true`:

```bash theme={null}
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... rest of your hook logic
```

If your hook legitimately needs more than eight iterations to converge, raise the cap with [`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`](/docs/en/env-vars).

### Hook JSON has no effect

Your hook prints valid JSON, but the decision doesn't take effect and no error appears in the transcript. Check which cause applies:

* **Extra output before the JSON**: something else writes to stdout first, usually an unconditional `echo` in your shell profile, so the output no longer starts with `{` and Claude Code doesn't parse it as JSON. The cause and fix follow this list.
* **A field at the wrong level**: compare each field's placement against the [JSON output](/docs/en/hooks#json-output) format. For example, `permissionDecision` belongs inside `hookSpecificOutput`, not at the top level.

When Claude Code runs a shell-form command hook, one without `args`, it spawns `sh -c` on macOS and Linux, Git Bash on Windows, or PowerShell when Git Bash isn't installed by default. This shell is non-interactive, but Git Bash and some configurations, such as `BASH_ENV` pointing at `~/.bashrc`, still source your profile. If that profile contains unconditional `echo` statements, the output gets prepended to your hook's JSON:

```text theme={null}
Shell ready on arm64
{"decision": "block", "reason": "Not allowed"}
```

The combined output no longer starts with `{`, so Claude Code treats all of stdout as plain text and ignores the JSON. On exit 0 nothing is reported in the transcript; the parse attempt is recorded only in the [debug log](/docs/en/hooks#debug-hooks). To fix this, wrap echo statements in your shell profile so they only run in interactive shells:

```bash theme={null}
# In ~/.zshrc or ~/.bashrc
if [[ $- == *i* ]]; then
  echo "Shell ready"
fi
```

The `$-` variable contains shell flags, and `i` means interactive. Hooks run in non-interactive shells, so the echo is skipped.

When your hook returns `permissionDecision` or `additionalContext` at the top level instead of inside `hookSpecificOutput`, the JSON still parses, and Claude Code ignores the misplaced fields without reporting an error. To see which fields it ignored, start Claude Code with `claude --debug` and search the [debug log](/docs/en/hooks#debug-hooks) for `Hook JSON output had unrecognized keys`.

### Debug techniques

Press `Ctrl+O` to open the transcript view to check the outcome of a hook run:

* **Successful run**: you see nothing, unless the hook's JSON surfaces something, such as `systemMessage` or Stop hook feedback.
  * To confirm a hook ran, check for its effect, like a reformatted file, or turn on debug logging as described below and trigger the hook again
* **Blocking error**: on most events you see the hook's feedback. When the hook's JSON made a blocking decision, the feedback is the reason from that decision; otherwise it is the hook's stderr. On a few events, such as `ConfigChange` and `Elicitation`, a block surfaces no message.
* **Non-blocking error**: the action proceeded, and you see a `<hook name> hook error` notice with a short explanation, such as the first line of stderr prefixed with `Failed with non-blocking status code:`, or a JSON validation or parse message.

Which exit-code and JSON combinations produce each outcome, including the per-event exceptions, is defined in the reference's [Exit code output](/docs/en/hooks#exit-code-output) section.

For full execution details including which hooks matched, their exit codes, stdout, and stderr, read the debug log. Start Claude Code with `claude --debug-file /tmp/claude.log` to write to a known path, then `tail -f /tmp/claude.log` in another terminal. If you started without that flag, run `/debug` mid-session to enable logging and find the log path.

## Learn more

* [Hooks reference](/docs/en/hooks): full event schemas, JSON output format, async hooks, and MCP tool hooks
* [Security considerations](/docs/en/hooks#security-considerations): review before deploying hooks in shared or production environments
* [Bash command validator example](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py): complete reference implementation
