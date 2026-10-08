[Part 1/4 of https://code.claude.com/docs/en/permissions.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Configure permissions

> Control what Claude Code can access and do with fine-grained permission rules, modes, and managed policies.

Claude Code supports fine-grained permissions so that you can specify exactly what the agent is allowed to do and what it can't. You can check permission settings into version control to share them with every developer in your organization, and each developer can customize their own.

## Permission system

Claude Code uses a tiered permission system to balance power and safety. The table shows, for each tool type, whether Manual mode asks before the action runs. The other [permission modes](#permission-modes) change which of these ask you; in auto mode a classifier reviews actions instead of you, and [how the classifier evaluates actions](/docs/en/permission-modes#how-the-classifier-evaluates-actions) lists which ones it sees.

| Tool type | Example | Approval required | "Yes, and don't ask again" behavior |
| :- | :- | :- | :- |
| Read-only | File reads, Grep | No, within the [working directory and additional directories](#working-directories) | N/A |
| Bash commands | Shell execution | Yes, except a built-in set of [read-only commands](#read-only-commands) | Permanently per repository and command |
| File modification | Edit/write files | Yes | Until session end |
| Web fetch | WebFetch | Yes, except a built-in set of [preapproved documentation domains](/docs/en/tools-reference#webfetch-tool-behavior) | Permanently per repository and domain |
| Web search | WebSearch | Yes | Permanently per repository |

A permission prompt shows what Claude is about to do, followed by your options. This example is the prompt for a Bash command, from a session in Manual mode:

<Frame>
  <img src="https://mintcdn.com/claude-code/oa7CKjMeIChox26S/images/permission-prompt-bash-light.png?fit=max&auto=format&n=oa7CKjMeIChox26S&q=85&s=87585d008a29304873466399f7b476f6" className="dark:hidden" alt="A Claude Code permission prompt titled Bash command. Under a tip about auto mode, it shows the description 'Run the test suite', the command npm test, and the line 'This command requires approval', then asks 'Do you want to proceed?' with four options: Yes; Yes, and don't ask again for: npm test *; Yes, and switch to auto mode; and No. A footer lists two keys: Esc to cancel and Tab to amend." width="1512" height="680" data-path="images/permission-prompt-bash-light.png" />

  <img src="https://mintcdn.com/claude-code/oa7CKjMeIChox26S/images/permission-prompt-bash-dark.png?fit=max&auto=format&n=oa7CKjMeIChox26S&q=85&s=dd25688056898df1d1e4f1b5542bc978" className="hidden dark:block" alt="A Claude Code permission prompt titled Bash command. Under a tip about auto mode, it shows the description 'Run the test suite', the command npm test, and the line 'This command requires approval', then asks 'Do you want to proceed?' with four options: Yes; Yes, and don't ask again for: npm test *; Yes, and switch to auto mode; and No. A footer lists two keys: Esc to cancel and Tab to amend." width="1512" height="680" data-path="images/permission-prompt-bash-dark.png" />
</Frame>

The third option, **Yes, and switch to auto mode**, [doesn't appear on every prompt](/docs/en/permission-modes#switch-permission-modes).

When you choose "Yes, and don't ask again" and the approval saves permanently, such as for a Bash command or a WebFetch domain, Claude Code saves the rule to `.claude/settings.local.json` at the root of the git repository, resolved through [worktrees](/docs/en/worktrees) to the main checkout. The rule applies to future sessions anywhere in that repository, including sessions started in subdirectories and in worktrees. A file-modification approval isn't saved to the file: as the table shows, it lasts until the session ends. In some cases, such as outside a git repository or on Windows, Claude Code doesn't use the repository root; [Where Claude Code looks for each file](/docs/en/settings#where-claude-code-looks-for-each-file) lists those cases and where it saves the rule instead.

Before v2.1.211, Claude Code always saved the rule in the starting directory, so an approval granted in a worktree or subdirectory didn't apply to the rest of the repository. Rules that earlier versions saved in a subdirectory or worktree still apply to sessions started there.

Sometimes a permission prompt offers only a one-time approval, with no "don't ask again" option and no option to allow the action for the rest of the session. Claude Code offers those options only when the prompt can show you everything they would allow, so a rule you save from a prompt covers only what its option named. When a prompt offers only the one-time approval, approve the action once, or add the rule yourself in [`/permissions`](#manage-permissions).

### Add a comment when you answer a permission prompt

You can attach a note to Claude when you approve or deny a single action. On most permission prompts, including Bash, PowerShell, file, and MCP tool prompts, move to **Yes** or **No** and press `Tab` to open a comment field on that option. WebFetch and browser prompts don't offer the field. The options that allow the action for the rest of the session or save a rule don't take one either.

With the field open, type the comment and then press one of these keys:

* `Enter`: submits your answer with the comment attached. If you leave the field empty, Claude Code submits the answer without a comment.
* `Tab`: closes the field without answering. Claude Code keeps the text you typed and still sends it if you answer with that option.
* `Shift+Tab`: on a file prompt, such as an Edit or Write prompt, closes the field the same as `Tab`. Before v2.1.235, pressing `Shift+Tab` inside the field instead selected the option that allows the action for the rest of the session, so Claude Code approved the action for the rest of the session and discarded the comment.

Claude Code delivers the comment differently depending on how you answered:

* **Yes**: Claude Code runs the action, then sends your comment to Claude after the result.
* **No**: Claude Code sends your comment to Claude as the reason for the denial, and Claude continues working. If you select **No** without a comment on a prompt from the main conversation, Claude Code stops the turn.

## Manage permissions

You can view and manage Claude Code's tool permissions with `/permissions`. The dialog lists all permission rules and the `settings.json` file each rule comes from. You can open the dialog while Claude is working: when you add or remove a rule, Claude Code applies the change starting with Claude's next tool call in the same turn. Before v2.1.234, Claude Code queued the command until the turn finished.

* **Allow** rules let Claude Code use the specified tool without manual approval.
* **Ask** rules prompt for confirmation whenever Claude Code tries to use the specified tool.
* **Deny** rules prevent Claude Code from using the specified tool.

Rules are evaluated in order: deny, then ask, then allow. The first match in that order determines the outcome, and rule specificity doesn't change the order.

A broad deny rule like `Bash(aws *)` blocks every matching call, including calls that also match a narrower allow rule like `Bash(aws s3 ls)`. An allow rule can't carve an exception out of a deny rule. The same precedence applies between ask and allow: a matching ask rule prompts even when a more specific allow rule also matches the same call.

Deny rules behave differently depending on whether they name a tool or scope a pattern within one. A bare tool name like `Bash` removes the tool from Claude's context entirely, so Claude never sees it. If you add such a rule mid-session, Claude can't call the tool from its next tool call on; [Denying an entire tool](/docs/en/prompt-caching#denying-an-entire-tool) covers what happens to a definition Claude has already seen. A scoped rule like `Bash(rm *)` leaves the tool available and blocks matching calls when Claude attempts them.

Bare-name removal applies to every tool except [`EndConversation`](/docs/en/tools-reference#endconversation-tool-behavior): a deny rule can't remove it while any other tool remains, and an ask rule never prompts for it.

<Note>
  Permission rules are enforced by Claude Code, not by the model. Instructions in your prompt or `CLAUDE.md` shape what Claude tries to do, but they don't change what Claude Code allows. To grant or revoke access, use `/permissions`, the rules described here, a [permission mode](/docs/en/permission-modes), or a [PreToolUse hook](#extend-permissions-with-hooks).
</Note>

When [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) is available to your session, the dialog also includes the [auto mode classifier rules](/docs/en/auto-mode-config#edit-rules-from-permissions). Select the **Auto mode** tab to view them.

## Permission modes

Claude Code supports several permission modes that control how it approves tool calls. See [Permission modes](/docs/en/permission-modes) for when to use each one. To change the mode sessions start in, set `defaultMode` in your [settings files](/docs/en/settings#where-settings-live). [Which mode a session starts in](/docs/en/permission-modes#which-mode-a-session-starts-in) covers the built-in default for each plan and what the VS Code extension reads.

| Mode | Description |
| :- | :- |
| `default` | Prompts for permission on first use of each tool. Labeled Manual in the CLI, the VS Code and JetBrains extensions, and the desktop app, and Claude Code accepts `manual` as an alias |
| `acceptEdits` | Automatically accepts file edits and common filesystem commands such as `mkdir`, `touch`, `mv`, and `cp` for paths in the working directory or `additionalDirectories` |
| `plan` | Claude reads files and runs read-only shell commands to explore but doesn't edit your source files; with [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) available, classifier-approved commands also run. Labeled Plan in the CLI and the VS Code extension |
| `auto` | Runs without routine prompts; before actions such as shell commands and network requests run, a background [classifier](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) checks that they align with your request |
| `dontAsk` | Auto-denies every call that would otherwise prompt; file reads in your working directories and other actions that need no approval still run, as do tools pre-approved via `/permissions` or `permissions.allow` rules. `AskUserQuestion`, MCP tools marked [`requiresUserInteraction`](/docs/en/mcp#require-approval-for-a-specific-tool), and connector tools [your organization set to `ask`](/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code are denied even if you've allowed them |
| `bypassPermissions` | Skips permission prompts, except for the [actions no mode auto-approves](/docs/en/permission-modes#actions-no-mode-auto-approves) |

<Warning>
  In `bypassPermissions` mode, Claude Code skips permission prompts, including for writes to [protected paths](/docs/en/permission-modes#protected-paths) such as `.git` and `.claude`. The [cross-session messaging safeguards](/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) still apply. Only use this mode in isolated environments like containers or VMs where Claude Code can't cause damage.
</Warning>

To prevent `bypassPermissions` or `auto` mode from being used, set `permissions.disableBypassPermissionsMode` or `permissions.disableAutoMode` to `"disable"` in any [settings file](/docs/en/settings#where-settings-live). These are most useful in [managed settings](#managed-settings) where they can't be overridden.

## Permission rule syntax

Permission rules follow the format `Tool` or `Tool(specifier)`. Parentheses inside the specifier are literal, so a command or path that contains them needs no escaping.

### Match all uses of a tool

To match all uses of a tool, use only the tool name without parentheses:

| Rule | Effect |
| :- | :- |
| `Bash` | Matches all Bash commands |
| `WebFetch` | Matches all web fetch requests |
| `Read` | Matches all file reads |

`Bash(*)` is equivalent to `Bash` and matches all Bash commands. As a deny rule, both forms remove the tool from Claude's context.

### Use specifiers for fine-grained control

Add a specifier in parentheses to match specific tool uses:

| Rule | Effect |
| :- | :- |
| `Bash(npm run build)` | Matches the exact command `npm run build` |
| `Read(./.env)` | Matches reading the `.env` file in the current directory |
| `WebFetch(domain:example.com)` | Matches fetch requests to example.com |

### Match by input parameter

Deny and ask rules can match a top-level input parameter on any built-in tool with `Tool(param:value)`.

To match a parameter on an MCP tool, pass a deny rule with [`--disallowedTools`](/docs/en/cli-reference#cli-flags). When Claude Code loads a settings file, it skips any `mcp__` rule that has parentheses. Claude Code lists the skipped rule in the invalid-settings dialog when an interactive session starts, and in [`claude doctor`](/docs/en/debug-your-config#check-resolved-settings) output.

A parameter rule matches when Claude calls the tool with that parameter set to that exact value. An allow rule for one parameter value wouldn't establish that the call is safe overall, so allow rules continue to use each tool's own specifier syntax. This works for any scalar parameter the tool accepts:

| Rule | Matches |
| :- | :- |
| `Agent(model:opus)` | Agent calls that request the Opus model tier |
| `Agent(isolation:worktree)` | Agent calls that request a git worktree |
| `Bash(run_in_background:true)` | Bash calls that run in the background |

Parameter matching follows these rules:

* The parameter name must be a direct field of the tool's input, such as `model` on the Agent tool. Fields nested inside an object or array are not matchable
* Each rule names one parameter. To gate on both `model` and `isolation`, write two rules, `Agent(model:opus)` and `Agent(isolation:worktree)`, rather than combining them in one rule
* The value supports `*` as a wildcard that matches any sequence of characters, so `Agent(isolation:*)` matches any explicit isolation value. Without `*` the match is exact
* A parameter the model omits is never matched, so `Agent(model:*)` doesn't match a call that leaves `model` unset
* The value is compared against the literal input Claude sends, before any normalization. `Agent(model:opus)` matches the alias `opus` but not a full model ID
* A `Skill(skill:<name>)` deny rule instead [matches the skill under any of its names](/docs/en/skills#restrict-claude’s-skill-access), such as its alias or display name
* Run with [`--verbose`](/docs/en/cli-reference) to see the exact parameter names and values in each tool call
* Whitespace around the colon is ignored

You can't match a tool's primary content field this way: `command` for Bash and PowerShell, `file_path` for Read, Edit, and Write, `path` for Grep and Glob, `notebook_path` for NotebookEdit, and `url` for WebFetch. A rule like `Bash(command:rm *)` would be bypassable by a compound command, so Claude Code ignores it and emits a startup warning. Use `Bash(rm *)`, `Read(./path)`, or `WebFetch(domain:host)` instead.

### Wildcard patterns

A `*` in a Bash rule matches any text, including spaces, so one rule covers a family of commands. A rule with no `*` matches one exact command.

<Warning>
  Put the `*` after the subcommand. In `git log --oneline main`, `git` is the program and `log` is the subcommand, the word that determines what the program does. Claude Code matches everything before the first `*` as written, so those words are what limit the rule: `Bash(git log *)` allows only `git log` commands, and `Bash(git *)` allows every git command. Claude Code [warns at startup](/docs/en/errors#has-a-wildcard-before-the-rest-of-the-command) about an allow rule with a `*` before the subcommand, such as `Bash(git * main)`.
</Warning>

Write the command you want Claude to run without asking, and replace the parts that vary with `*`. With this configuration, Claude Code runs npm scripts and git commits without asking and refuses commands that begin with `git push`. A push written another way, such as `git -C . push`, isn't matched; see [what a Bash rule doesn't match](#bash-rule-limits).

```json theme={null}
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

A `*` can go anywhere in the rule: at the start, in the middle, or at the end. Each row shows a rule, commands it matches, and nearby commands it doesn't match:

| You write | Matches | Doesn't match |
| :- | :- | :- |
| `Bash(npm run build)` | `npm run build` | `npm run build --watch` |
| `Bash(npm run *)` | `npm run build`, `npm run test --watch`, `npm run` | `npm install` |
| `Bash(git log * main)` | `git log --oneline main`, `git log -5 main`, `git log --output=<file> main` | `git log main`, `git push origin main` |
| `Bash(git * main)` | `git merge main`, `git push origin main`, `git -c core.fsmonitor=<script> diff main` | `git log` |
| `Bash(* --version)` | `node --version`, `bash -c 'echo hi' --version` | `node -v` |
| `Bash(ls *)` | `ls -la`, `ls` | `lsof` |
| `Bash(ls*)` | `ls -la`, `lsof` | |
| `Bash(* --help *)` | `npm --help x` | `npm --help` |

Three matching rules produce those rows:

* **The `*` stands in for whatever text is in its place.** In `Bash(git * main)`, it stands in for the subcommand, so Claude Code matches every git subcommand and every option before it. That includes `-c`, which makes git run a program you name. In `Bash(* --version)`, the `*` stands in for the program, so any program matches.
* **A `*` at the end, with a space before it, also matches the bare command.** `Bash(ls *)` matches `ls`, and `Bash(git log *)` matches `git log`. That holds only when the trailing `*` is the rule's only wildcard: `Bash(* --help *)` matches `npm --help x` but not `npm --help`.
* **The space before a trailing `*` is part of the rule.** `Bash(ls *)` requires a space after `ls`, so `lsof` doesn't match. `Bash(ls*)` has no space, so it matches `lsof` too.

The `:*` suffix is an equivalent way to write a trailing wildcard, so `Bash(ls:*)` matches the same commands as `Bash(ls *)`.

The permission dialog writes the space-separated form when you select "Yes, and don't ask again" for a command prefix. The `:*` form is only recognized at the end of a pattern. In a pattern like `Bash(git:* push)`, the colon is treated as a literal character and won't match git commands.

### Tool name wildcards

Deny and ask rules also accept glob patterns in the tool-name position. The pattern must match the full tool name: `"*"` matches every tool, and `"mcp__*"` matches every MCP tool across all servers. A tool matched by a bare-name glob deny rule is removed from Claude's context, the same as a bare tool name, including the [`EndConversation`](/docs/en/tools-reference#endconversation-tool-behavior) exception: a glob deny can't remove it while any other tool remains, and a glob ask never prompts for it. This configuration denies every MCP tool:

```json theme={null}
{
  "permissions": {
    "deny": [
      "mcp__*"
    ]
  }
}
```

Allow rules accept tool-name globs only after a literal `mcp__<server>__` prefix. The server segment must be glob-free so the rule names a specific server you configured. `mcp__puppeteer__*` matches every tool from the `puppeteer` server, and `mcp__github__get_*` matches its `get_` tools. An unanchored allow glob such as `"*"`, `"B*"`, or `"mcp__*"` is skipped with a warning and doesn't auto-approve anything.

A deny or ask rule whose tool name matches no known tool produces a startup warning to catch typos. Tool names containing `_` or `*` are exempt from the check, and so are the names of tools Claude Code has removed, such as `TaskOutput`.

The label shown for a tool in the transcript and permission dialog can differ from its canonical name. For example, the tool labeled `Stop Task` in the transcript has the canonical name `TaskStop`. Permission rules and [hook matchers](/docs/en/hooks) don't match the label, so a rule written as `Stop Task` doesn't match. For deny and ask rules, the startup warning above catches the mismatch. Use the canonical names listed in the [tools reference](/docs/en/tools-reference).

## Tool-specific permission rules

### Bash

Bash rules match the whole command text, with `*` standing in for any text. [Wildcard patterns](#wildcard-patterns) shows which commands each rule shape matches and where to put the `*`. The rest of this section covers how Claude Code matches compound commands and wrappers, what a rule doesn't match, read-only commands, and redirections.

#### Compound commands

<Tip>
  Claude Code is aware of shell operators, so a rule like `Bash(safe-cmd *)` won't give it permission to run the command `safe-cmd && other-cmd`. The recognized command separators are `&&`, `||`, `;`, `|`, `|&`, `&`, and newlines. A rule must match each subcommand independently.
</Tip>

Deny and ask rules apply when any subcommand matches them, including a command nested inside a subshell, a command substitution, or a control-flow body such as a `for` loop. An ask rule like `Bash(git clean *)` still prompts you for `cd /tmp && git clean -f` or `echo "$(git clean -f)"`, even in [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode).

When `&&` or `||` has nothing after it, such as in `npm test &&`, Claude Code treats the command as unparseable and doesn't split it into subcommands for allow-rule matching, so a rule such as `Bash(npm *)` doesn't approve it.

When you approve a compound command with "Yes, and don't ask again", Claude Code saves a separate rule for each subcommand that requires approval, rather than a single rule for the full compound string. For example, approving `git status && npm test` saves a rule for `npm test`, so future `npm test` invocations are recognized regardless of what precedes the `&&`. Subcommands like `cd` into a directory outside your working directories generate their own Read rule for that path. Up to 5 rules may be saved for a single compound command.

<h4 id="process-wrappers">
  Wrappers
</h4>

Before matching Bash rules, Claude Code strips a fixed set of wrappers, so a rule like `Bash(npm test *)` also matches `timeout 30 npm test`. The stripped wrappers are `timeout`, `time`, `nice`, `nohup`, and `stdbuf`, plus the shell builtins `command` and `builtin`, and zsh's `noglob`. Each runs its argument as the actual command. Two related forms aren't stripped: the query form `command -v`, which looks up a command rather than running one, and zsh's `nocorrect`.

Claude Code also strips a leading assignment of certain known-safe environment variables, so `Bash(npm test *)` matches `NODE_ENV=test npm test`. An allow rule won't match past an assignment of any other variable. A deny or ask rule matches past any leading assignment, so `Bash(rm *)` in deny still matches `FOO=bar rm -rf tmp/`.

Bare `xargs` is also stripped, so `Bash(grep *)` matches `xargs grep pattern`. Stripping applies only when `xargs` has no flags: an invocation like `xargs -n1 grep pattern` is matched as an `xargs` command, so rules written for the inner command do not cover it.

This wrapper list is built in and is not configurable. Development environment runners such as `direnv exec`, `devbox run`, `mise exec`, `npx`, and `docker exec` are not in the list. Because these tools execute their arguments as a command, a rule like `Bash(devbox run *)` matches whatever comes after `run`, including `devbox run rm -rf .`. To approve work inside an environment runner, write a specific rule that includes both the runner and the inner command, such as `Bash(devbox run npm test)`. Add one rule per inner command you want to allow.

Exec wrappers such as `watch`, `setsid`, `ionice`, and `flock` can't be auto-approved by a prefix rule like `Bash(watch *)`, so in Manual mode they always prompt. The same applies to `find` with `-exec` or `-delete`: a `Bash(find *)` rule doesn't cover these forms. To approve a specific invocation, write an exact-match rule for the full command string.

<h4 id="bash-rule-limits">
  What a Bash rule doesn't match
</h4>

A Bash rule matches the command text Claude writes, after Claude Code splits [compound commands](#compound-commands) and strips [wrappers](#process-wrappers). It doesn't match the same program invoked in a different form, so a deny or ask rule covers the invocation Claude usually produces and isn't a security boundary around the program. These rules in `deny` or `ask` stop the first form and not the others:

| Rule | Stops | Doesn't stop |
| :- | :- | :- |
| `Bash(curl *)` | `curl https://example.com` | `/usr/bin/curl https://example.com`, `sh -c 'curl https://example.com'` |
| `Bash(rm *)` | `rm -rf build/` | `/bin/rm -rf build/`, `bash -c 'rm -rf build/'` |
| `Bash(git push *)` | `git push origin main` | `git -C . push origin main`, `git -c push.default=current push origin main`, `git 'push' origin main` |

Your other rules and the permission mode decide the commands in the last column.

For filesystem and network enforcement that doesn't depend on the command text, use [sandboxing](/docs/en/sandboxing). To inspect the full command text with your own logic before it runs, use a [PreToolUse hook](#extend-permissions-with-hooks).

#### Read-only commands

Claude Code recognizes a built-in set of Bash commands as read-only and runs them without a permission prompt in every mode, except as [`permissions.blockReadsOutsideWorkingDirectories`](/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) changes for paths outside your working directories. The set includes `ls`, `cat`, `echo`, `pwd`, `head`, `tail`, `grep`, `find`, `wc`, `which`, `diff`, `stat`, `du`, `cd`, and read-only forms of `git`. The set is not configurable; to require a prompt for one of these commands, add an `ask` or `deny` rule for it. In auto mode, these commands can also wait for the classifier's review; see [how the classifier evaluates actions](/docs/en/permission-modes#how-the-classifier-evaluates-actions).

A redirect such as `ls > out.txt` adds a check on the target. See [Redirections](#redirections).

Unquoted glob patterns are permitted for commands whose every flag is read-only, so `ls *.ts` and `wc -l src/*.py` run without a prompt.

In Manual mode, commands from this set still prompt in these cases:

* **Unquoted globs for commands with write-capable flags**: commands with write-capable or exec-capable flags, such as `find`, `sort`, `sed`, and `git`, prompt when an unquoted glob is present, because the glob could expand to a flag like `-delete`.
* **`docker` pointed at another daemon**: read-only forms of `docker` prompt when the command carries a flag that selects a different daemon, such as `-H`, `--context`, or Podman's `--url` and `--connection`.
* **`file` with path-opening flags**: `file` prompts when it passes `-m`/`--magic-file` or `-f`/`--files-from`, because those flags make `file` open the paths named in the flag's value.
* **Network paths on Windows**: a command whose arguments include a network (UNC) path, such as `\\server\share\file`, prompts because accessing a network path can send your Windows credentials to the host it names. The same check applies to [PowerShell tool](/docs/en/tools-reference#powershell-tool) commands.
* **Writes to special shell variables**: a command that sets, unsets, or loops over certain special shell variables, such as `PATH` or `IFS`, prompts even when the rest of the command is read-only.
* **Commands the analysis can't parse**: when Claude Code can't fully parse a command, it asks for approval instead of treating the command as read-only. Commands longer than 10,000 characters always prompt because they exceed what the analysis parses.

A `cd` into a path inside your working directory or an [additional directory](#working-directories) is also read-only, and a compound command like `cd packages/api && ls` runs without a prompt when each part qualifies on its own. These combinations prompt even when each part is read-only:

* **`cd` with `git`**: prompts when the `cd` changes into a different directory, since running `git` in a new directory can execute that directory's hooks. A `cd` whose target resolves to the current working directory is a no-op and doesn't trigger the prompt.
* **`cd` with a redirect**: prompts when Claude Code can't determine which directory the redirect target resolves against after the `cd` runs. A command whose only redirect target is `/dev/null`, such as `cd app; grep -r pattern . 2>/dev/null`, doesn't prompt, because `/dev/null` doesn't depend on the working directory.

<Warning>
  Bash permission patterns that try to constrain command arguments are fragile. For example, `Bash(curl http://github.com/ *)` intends to restrict curl to GitHub URLs, but won't match variations like:

  * Options before URL: `curl -X GET http://github.com/...`
  * Different protocol: `curl https://github.com/...`
  * Redirects: `curl -L http://short.example.com/xyz`, which redirects to GitHub
  * Variables: `URL=http://github.com && curl $URL`

  For more reliable URL filtering, consider:

  * **Restrict Bash network tools**: use deny rules to stop `curl`, `wget`, and similar commands, then use the WebFetch tool with `WebFetch(domain:github.com)` permission for allowed domains. A deny rule doesn't match the same program by path or inside `sh -c`, so pair it with the [sandbox network allowlist](/docs/en/sandboxing#network-isolation) when the restriction must hold; see [what a Bash rule doesn't match](#bash-rule-limits)
  * **Use PreToolUse hooks**: implement a hook that validates URLs in Bash commands and blocks disallowed domains
  * **Add CLAUDE.md guidance**: describe your allowed curl patterns in `CLAUDE.md`. This shapes what Claude tries but doesn't enforce a boundary, so pair it with one of the options above

  Note that using WebFetch alone doesn't prevent network access. If Bash is allowed, Claude can still use `curl`, `wget`, or other tools to reach any URL.
</Warning>

#### Redirections

When a command redirects output or input, Claude Code checks the redirect target against your file rules as if Claude wrote or read that file directly:

* **Output redirects**: for `> file`, `>> file`, or `2> file`, the check covers your `Edit` allow and deny rules, [protected paths](/docs/en/permission-modes#protected-paths), and the [working directories](#working-directories). A rule such as `Bash(git commit *)` allows the command, not the target. A target that starts with `~` or contains a glob character needs your approval.
* **Input redirects**: for `< file`, the check covers your `Read` allow and deny rules and the working directories. A target outside the working directories needs your approval unless an allow rule covers it. A target that contains a glob pattern, or a relative path that follows a `cd` in the same command, needs your approval even when an allow rule covers it. Claude Code checks input targets in v2.1.257 and later.

Targets with no file behind them aren't checked: `/dev/null`, file-descriptor forms such as `2>&1` and `<&3`, and here-docs and here-strings.

Claude Code also checks the files a `tee` command writes, including in a pipeline such as `make | tee build.log`. The check covers your `Edit` allow and deny rules, [protected paths](/docs/en/permission-modes#protected-paths), and the [working directories](#working-directories). An allow rule such as `Bash(tee *)` doesn't cover a destination outside the working directories. Claude Code checks `tee` targets in v2.1.269 and later.
