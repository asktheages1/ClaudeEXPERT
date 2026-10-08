[Part 4/4 of https://code.claude.com/docs/en/permission-modes.md, fetched 2026-10-08]

## Critical paths

Critical paths are the directories Claude Code protects from `rm` and `rmdir` commands, such as the filesystem root, your home directory, and your working directory.

Claude Code never lets a [`permissions.allow`](/docs/en/permissions#manage-permissions) rule or a [`PreToolUse` hook](/docs/en/permissions#extend-permissions-with-hooks) that returns `"allow"` approve an `rm` or `rmdir` command that targets a critical path, even in modes that skip other prompts. This circuit breaker guards against model error. A matching deny rule still blocks the command outright.

What happens instead [depends on your permission mode](#critical-path-removals-in-each-permission-mode). `Remove-Item` and the `cmd` removal built-ins have their own checks, covered in [Remove-Item in PowerShell](#remove-item-in-powershell).

### Which paths are critical

Claude Code treats an `rm` or `rmdir` target as a critical path when it is any of the following:

* The filesystem root
* Top-level directories, meaning any direct child of the root, such as `/usr`, `/etc`, or `/data`
* Your home directory
* Windows drive roots and their top-level directories, such as `C:\` and `C:\Windows`
* Your working directory and its parents
* Your additional working directories and their parents, but only when the removal is a glob under one of them, such as `rm -rf <dir>/*`. `rm -rf <dir>` on the directory itself doesn't trigger this check

### Other targets that count as critical paths

Claude Code also treats the following `rm` and `rmdir` targets as critical paths. The last column says why each one counts.

| Target | Example | Why it counts |
| :- | :- | :- |
| A glob or trailing slash directly under a shell variable | `rm -rf "$DIR"/*` | The command becomes a removal from the filesystem root when the variable is empty |
| The same form under a positional parameter such as `$1` or `$@`, when nothing in the command gives it a value | `rm -rf "$1"/*` | The command expands to a removal from the root |
| A shell variable followed by one common top-level directory name, such as `mnt`, `tmp`, `usr`, or `Users` | `rm -rf "$TMPDIR/mnt"` | When the variable expands empty, the command removes `/mnt` |
| A variable that the same command assigns from a directory-printing substitution, such as `$(pwd)` or `$(git rev-parse --show-toplevel)` | `D=$(pwd); rm -rf "$D"` | The value can name your working directory or repository root |
| A target that is only the output of a command substitution, when the `rm` is recursive | `rm -rf "$(pwd)"` | Claude Code can't check the target before the command runs |
| A trailing command substitution after a critical path | `rm -rf ~/$(cmd)` | Claude Code checks the path that would remain if the substitution expanded empty, here your home directory |
| A target that is only backslashes | `rm -rf "\\"` | Git Bash on Windows reads a lone backslash as the current drive's root, so the check applies on every platform |
| Some targets that end in `/*` or `/*/` | `rm -rf logs/*/*`, `rm -rf logs/*/`, `cd logs && rm -rf a/*` | Claude Code can't tell before the command runs which directories they reach |

To turn off the check on a target that is only command substitution output, set [`CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT=1`](/docs/en/env-vars#variables) in the environment that launches Claude Code.

### Removals inside nested commands and inline scripts

Claude Code also looks inside these constructs:

* **Nested commands**: a subshell with `(...)`, a brace group with `{ ...; }`, command substitution with `$(...)` or backticks, or process substitution with `<(...)`. Claude Code finds a critical-path removal whether it sits inside the nested form, as in `(rm -rf ~)` or `echo "$(rm -rf ~)"`, or elsewhere in the same command.
* **Inline scripts**: a script passed to `sh`, `bash`, `zsh`, or a similar POSIX shell with `-c`, as in `bash -c 'rm -rf ~'`.
  * When the script is double-quoted, the invoking shell expands its variables before the inner shell receives the script. In `find . -name '*.tmp' -exec sh -c "rm -rf \"$1\"/*" _ {} \;`, the command expands to a removal from the filesystem root once per match, and Claude Code treats it as a critical-path removal.
  * A single-quoted script that binds `$1` to a real value, as `sh -c 'rm -rf "$1"/*' _ {}` does, isn't flagged.

To turn off the check on a critical path typed directly in a `-c` script, such as `~`, set [`CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT=1`](/docs/en/env-vars#variables) in the environment that launches Claude Code.

### Rewrite a flagged command

How to rewrite a command so it passes the check depends on which of the [other targets](#other-targets-that-count-as-critical-paths) it uses:

* **A glob or trailing slash under a variable such as `$DIR`**: guard each expansion so the shell stops with an error when the variable is unset or empty, as in `rm -rf "${DIR:?}"/*`, or use a literal path. A removal whose expansions are all guarded that way passes this check, so in `bypassPermissions` mode it runs without a prompt unless another [critical-path](#critical-paths) check flags it.
* **A glob or trailing slash under a variable that is normally set, such as `$HOME`**: use a literal path.
* **A variable assigned from a directory-printing substitution**: use a literal path. A `"${D:?}"` guard doesn't clear this check, because the variable isn't empty.
* **A target that is only command substitution output**: run the substitution on its own first, then remove the literal paths it prints. The prompt tells Claude to do the same.

For a glob or trailing slash under a variable, the prompt names the flagged `rm` and says how to rewrite it so the check passes.

### Critical-path removals in each permission mode

What Claude Code does with a critical-path removal depends on your permission mode:

| Mode | Outcome |
| :- | :- |
| `default`, `acceptEdits` | Asks you to approve it |
| `plan` | Asks you to approve it. When [the classifier reviews commands during planning](#analyze-before-you-edit-with-plan-mode) and no bypass permissions are available, handles it as in `auto` mode |
| `auto` | Asks you to approve it in the terminal, with a [time limit](#time-limits-and-denials-in-auto-and-bypasspermissions-modes). Elsewhere, denies it |
| `dontAsk` | Denies it |
| `bypassPermissions` | Asks you to approve it, with a time limit in the terminal |

If an explicit [ask rule](/docs/en/permissions#manage-permissions) matches the command, Claude Code asks you instead, even in `auto` mode and without a time limit. In modes that ask, a [`PermissionRequest` hook](/docs/en/hooks#permissionrequest) can answer the prompt.

### Time limits and denials in auto and bypassPermissions modes

In `auto` and `bypassPermissions` modes, the terminal prompt for a critical-path removal shows a two-minute countdown:

* If the countdown runs out before you answer, Claude Code denies the command and tells Claude what to do instead, so an unattended session keeps working.
* Press any key while the prompt is open to stop the countdown and keep the prompt waiting for your answer.
* After three of these prompts run out unanswered in a session, Claude Code stops showing them and denies further critical-path removals immediately. Sending a new message starts the count over.

In `auto` mode, wherever Claude Code can't show you a terminal prompt, it denies the command immediately, for example in [non-interactive runs](/docs/en/headless) with `-p`, in [Agent SDK](/docs/en/agent-sdk/permissions) sessions, and in the VS Code extension's chat panel and the Desktop app. The denial tells Claude to report what it wanted to delete and leave the removal to you.

The `auto` and `bypassPermissions` handling requires Claude Code v2.1.281 or later. To turn it off, set [`CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT=1`](/docs/en/env-vars#variables) in the environment that launches Claude Code. In `auto` mode, critical-path removals then go to the classifier instead, and in `bypassPermissions` mode the prompt has no time limit.

### Remove-Item in PowerShell

When you enable the [PowerShell tool](/docs/en/tools-reference#powershell-tool), Claude Code gives `Remove-Item` and the `cmd` built-ins `rd`, `rmdir`, `del`, and `erase` their own checks, separate from the `rm` critical-path list. For `Remove-Item`, the outcome depends on the target, and the first matching case applies:

* **System paths**: the filesystem root and its top-level directories, drive roots and their top-level directories, and your home directory. Claude Code denies the command in every mode, without asking you.
* **Wildcards**: a bare `*`, or any target ending in `/*` or `\*`, including a glob under a shell variable such as `$dir/*`. Claude Code denies the command in every mode, without asking you, before the [classifier](#eliminate-prompts-with-auto-mode) sees it.
* **Your working directory or one of its parents, with `-Recurse`**: Claude Code treats the command like any other that needs approval in your permission mode, so it asks you in modes that ask, sends it to the classifier in `auto` mode, and denies it in `dontAsk` mode. `bypassPermissions` mode skips this check.

The system-paths case also applies to `rd`, `rmdir`, `del`, and `erase` when Claude runs them through `cmd`, as in `cmd /c rd /s /q C:\Users`. By default, Claude Code denies such a command in every mode, without asking you. This `cmd` check requires Claude Code v2.1.283 or later.

When judging a `cmd` target, Claude Code treats a PowerShell variable that follows literal text as empty. That makes `cmd /c rd /s /q "C:\$name"` a removal of `C:\`, so it is denied too. A trailing wildcard counts as the folder it empties, so `cmd /c del /q C:\*` is denied and `cmd /c del /q dist\*` in your project is not.

To turn the `cmd` check off, set [`CLAUDE_CODE_DISABLE_POWERSHELL_CMD_RM_DENY=1`](/docs/en/env-vars#variables) in the environment that launches Claude Code. Claude Code ignores this variable in a settings file's `env` block. `Remove-Item` on a system path stays denied either way.

## See also

* [Permissions](/docs/en/permissions): allow, ask, and deny rules; managed policies
* [Configure auto mode](/docs/en/auto-mode-config): tell the classifier which infrastructure your organization trusts
* [Hooks](/docs/en/hooks): custom permission logic via `PreToolUse` and `PermissionRequest` hooks
* [Security](/docs/en/security): safeguards and best practices
* [Sandboxing](/docs/en/sandboxing): filesystem and network isolation for Bash commands
* [Non-interactive mode](/docs/en/headless): run Claude Code with the `-p` flag
