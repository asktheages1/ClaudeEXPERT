[Part 2/3 of https://code.claude.com/docs/en/settings.md, fetched 2026-10-08]

### Share settings with your team

Commit `.claude/settings.json` so everyone who clones the repository gets the same permissions, hooks, and plugins. Each teammate can still override it for themselves in their own `.claude/settings.local.json`, so personal exceptions don't need a commit. For a complete team file, see [a team's shared settings](/docs/en/settings-example#a-teams-shared-settings).

Some of what you commit waits until each teammate [trusts the folder](/docs/en/permissions#project-allow-rules-and-workspace-trust), and a few keys never take effect from a repository file; [Troubleshoot a setting that doesn't apply](#common-cases) covers both.

<span id="local-settings-file" />

<span id="where-claude-code-saves-the-project-local-file" />

<span id="the-project-local-file" />

<span id="keep-personal-settings-out-of-the-repository" />

### Keep personal settings out of a repository

To change a setting for yourself in one project without changing it for your teammates, save it in `.claude/settings.local.json` inside the project. Claude Code applies that file over the committed `.claude/settings.json`, so if your team's file sets `"model": "claude-sonnet-5"` and you want Opus, put `"model": "claude-opus-5-5"` in your local file and only your sessions change.

Claude Code also writes to this file, keeps it out of your commits, and applies its allow rules without the trust step:

* **Claude Code writes it too.** When Claude asks permission to run a Bash command and you choose "Yes, and don't ask again", Claude Code saves that [permission approval](/docs/en/permissions#permission-system) here as an `allow` rule.
* **You don't need to gitignore it yourself, unless you created it by hand.** The first time Claude Code writes the file in a git repository that doesn't already ignore it, it adds `**/.claude/settings.local.json` to your global git excludes file, so the file stays out of your commits in every repository. That file is `core.excludesFile` when your global git config sets it to an absolute or `~`-prefixed path; otherwise it's `$XDG_CONFIG_HOME/git/ignore`, or `~/.config/git/ignore` when `XDG_CONFIG_HOME` is unset. If you created the file by hand and Claude Code hasn't written to it yet, add it to `.gitignore` yourself.
* **Its allow rules don't wait for trust while the file stays untracked.** Because the file is yours and not the repository's, Claude Code applies its `allow` rules without the [workspace trust](/docs/en/permissions#project-allow-rules-and-workspace-trust) step it requires for the committed file. If the file is tracked by git, the trust step applies to it too; see [When your local settings file needs trust](/docs/en/permissions#when-your-local-settings-file-needs-trust).

<span id="where-claude-code-looks-for-each-file" />

<span id="how-claude-code-keeps-the-local-file-out-of-git" />

<span id="local-allow-rules-dont-wait-for-workspace-trust" />

#### Where Claude Code keeps the local file in a git repository

When Claude asks permission to run a Bash command and you choose "Yes, and don't ask again", Claude Code saves that approval as an `allow` rule in `.claude/settings.local.json`. If you start Claude Code in a subdirectory of a git repository, it reads and writes that file at the repository root and applies the approval across the whole repository. In a [worktree](/docs/en/worktrees), it uses the file at the main checkout's root.

Two rules qualify the root location:

* **When the file stays with `.claude/settings.json` instead**: outside a git repository, when the repository root is your home directory, on Windows, or when the repository root or its `.git` or `.claude` entry isn't owned by your user.
* **Paths in the file don't anchor at the repository root**: a permission rule that starts with `/` or a relative sandbox path [anchors at the session's primary working directory](/docs/en/permissions#read-and-edit) instead.

Before v2.1.211, Claude Code kept the file in the starting directory. It still reads a file an earlier version left there alongside the root file; where both set the same key, the root's value applies, and permission rules from both files apply. The Agent SDK's [`resolveSettings()`](/docs/en/agent-sdk/typescript#resolvesettings) helper always reads the file from the starting directory.

Claude Code reads the shared `.claude/settings.json` from the session's [primary working directory](/docs/en/permissions#working-directories), so to use a file committed at the repository root, start Claude Code there. After you [move the session with `/cd`](/docs/en/permissions#move-the-session-to-another-directory), Claude Code reads both project files from the new directory instead, placing the local file by the same rules. Reading them from the directory you moved to requires Claude Code v2.1.246 or later.

<span id="managed-settings-delivery" />

<span id="precedence-within-the-managed-tier" />

<span id="parent-settings-from-embedding-hosts" />

<span id="enforce-settings-for-an-organization" />

<span id="settings-your-organization-manages" />

### Check what your organization enforces

If your organization manages Claude Code, some settings are decided for you and nothing you put in your own files changes them. To see which, run `/status`: the `Setting sources` line names the managed source that applies to you. Managed settings apply wherever Claude Code runs on this machine; [What a developer can change](/docs/en/managed-settings#what-a-developer-can-change) covers local admin rights and tools other than Claude Code.

Managed settings reach you through the [delivery mechanisms](/docs/en/managed-settings#delivery-mechanisms) on the managed settings page, most commonly:

* [Server-managed settings](/docs/en/server-managed-settings), which Claude Code fetches from the claude.ai admin console or a self-hosted [Claude apps gateway](/docs/en/claude-apps-gateway)
* MDM or OS-level policies, and `managed-settings.json` files in a system directory
* An embedding host such as Claude Desktop, through the SDK `managedSettings` option; see [Control policy from an embedding host](/docs/en/managed-settings#parent-settings-from-embedding-hosts)

In a [Cowork](https://claude.com/docs/cowork/overview) session that runs on your machine in the Claude Desktop app, Claude Code doesn't fetch server-managed settings from the claude.ai admin console, and it reads policy deployed to your device unless your organization's Claude Desktop configuration sets `requireCoworkFullVmSandbox`. [Where and when a policy applies](/docs/en/managed-settings#where-and-when-a-policy-applies) covers Cowork and cloud sessions.

If you're the administrator, [Set up Claude Code for your organization](/docs/en/admin-setup) walks through choosing what to enforce, and [Deploy managed settings](/docs/en/managed-settings) covers delivery and how to confirm a policy is in force.

## Change a setting

You can change a setting from the `/config` menu, by editing a settings file, or for one session from the command line.

<span id="system-prompt" />

Claude Code's system prompt isn't published. To give Claude standing instructions, use [`CLAUDE.md` files](/docs/en/memory) or the `--append-system-prompt` flag.

### Use the /config menu

Run `/config` inside Claude Code and open the **Config** tab. It lists a short set of personal options such as theme, editor mode, and verbose output, not every settings key. Select an option to change it; Claude Code saves it for you:

* **Most options**: `~/.claude/settings.json`
* **A few options, such as Show tips**: `.claude/settings.local.json`
* **The [global config options](/docs/en/settings-reference#global-config-settings)**: `~/.claude.json`

To set one option without the menu, pass `key=value`, such as `/config verbose=true`.

<Note>
  `/config` is part of the terminal interface. The [VS Code](/docs/en/vs-code) chat panel and the [desktop app](/docs/en/desktop) don't open it; change settings there by editing a settings file or through those apps' own settings.
</Note>

### Edit a settings file

Open the settings file for the scope you want in your editor and add or change a key. Settings files are strict JSON: a `//` comment or a trailing comma is a syntax error, and Claude Code reports the file as a [Settings Error](#fix-a-broken-settings-file) at the next start. For example, to let Claude Code run your lint and test commands without asking and stop it reading `.env` files, add this to `~/.claude/settings.json`:

```json ~/.claude/settings.json theme={null}
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)"
    ]
  }
}
```

Each entry under `permissions` is a rule that names a tool and what it may do; [Configure permissions](/docs/en/permissions) explains the syntax. The `$schema` line points to the [published JSON schema](https://json.schemastore.org/claude-code-settings.json) for Claude Code settings, which gives you autocomplete and inline validation in VS Code, Cursor, and any other editor that supports JSON schema. The schema can lag behind the newest CLI releases, so a validation warning on a recently documented key doesn't mean your configuration is invalid.

After you save, run `/status` inside Claude Code to confirm the file loaded; [Confirm what loaded](#check-what-loaded) says what the `Setting sources` line shows and how a broken file is reported.

For a complete personal file, team file, and organization file, each shown with a comment on every key it sets, see the [example settings files](/docs/en/settings-example).

<span id="pass-settings-for-one-session" />

### Change a setting for one session

To try a value without saving it, set it when you start Claude Code. The value applies to that session and your settings files stay as they were. You have three ways to do it:

* **`--settings`**: pass a key as JSON, inline or as a path to a file. Claude Code applies it above your user, project, and local files and below managed settings. It can set any key your user settings file can set; it can't set `Managed` or `Global config` keys.
* **A flag for that key**: some keys have their own flag, such as `--model` for `model` and `--effort` for `effortLevel` and `modelSettings`.
* **An environment variable**: export the key's paired variable before you run `claude`, such as `ANTHROPIC_MODEL` for `model`.

Each key's entry on the [settings reference](/docs/en/settings-reference) lists its per-session overrides and which one takes precedence, so check the entry for the key you want to change.

Commands you run inside a session mostly save your choice: when you change a setting in `/config`, Claude Code writes it to your settings files, and `/model` saves the value as your default for new sessions.

If you press `s` in the `/model` picker, Claude Code switches the model without saving it as your user default. [Adjust effort level](/docs/en/model-config#adjust-effort-level) says which `/effort` picks Claude Code saves as your default for the model you're using and which apply to the current session only.

For example, to start one session on Opus without changing your default:

```bash theme={null}
claude --settings '{"model": "claude-opus-5-5"}'
```

### When edits take effect

Claude Code watches your settings files and reloads them when they change, so it applies most edits to the running session without a restart, including edits to `permissions`, `hooks`, and credential helpers such as `apiKeyHelper`. Claude Code also loads a settings file you create mid-session if its folder existed when the session started. For the project's `.claude/` folder, it loads the file even when you create the folder in the same session.

The reload covers user, project, local, and managed settings, and Claude Code runs the [`ConfigChange` hook](/docs/en/hooks#configchange) for each settings-file change it detects, not for managed settings that arrive from MDM or the claude.ai console. Managed settings that arrive through MDM or from the claude.ai console reach a running session on a schedule rather than on save; the [delivery table](/docs/en/managed-settings#choose-a-delivery-mechanism) gives it per source.

Claude Code reads some keys only once, at session start, so an edit to one of them doesn't reach the running session. Admin-side keys that also wait for a restart, such as `requiredMinimumVersion`, are listed under [where and when a policy applies](/docs/en/managed-settings#where-and-when-a-policy-applies). The ones you're most likely to edit mid-session:

* [`model`](/docs/en/settings-reference#model): use [`/model`](/docs/en/model-config#setting-your-model) to switch mid-session. Each model has its own prompt cache, so the first request after a switch re-reads the whole conversation uncached; see [Switching models](/docs/en/prompt-caching#switching-models)
* [`effortLevel`](/docs/en/settings-reference#effortlevel) and [`modelSettings`](/docs/en/settings-reference#modelsettings): use [`/effort`](/docs/en/model-config#adjust-effort-level) to change effort mid-session

<span id="verify-active-settings" />

<span id="check-what-loaded" />

### Confirm what loaded

Run `/status` inside Claude Code to see which settings sources are active. The **Status** tab includes a `Setting sources` line that lists each settings file Claude Code loaded for the current session, such as `User settings` or `Project local settings`. When [managed settings](/docs/en/admin-setup#decide-how-settings-reach-devices) are in effect, the managed settings entry shows in parentheses how they reached your machine.

The line confirms which files Claude Code read; it doesn't show which file supplied each key. To list entries Claude Code rejected, run [`claude doctor`](/docs/en/debug-your-config); for a model that project or managed settings set, the startup header names the file that set it. `/status` and `/config` open the same dialog on different tabs, and the **Config** tab isn't a view of your `settings.json` contents.

### Fix a broken settings file

If you mistype JSON or set a key to a value Claude Code doesn't accept, Claude Code tells you at the start of an interactive session. What it shows depends on how much of the file is affected:

* **Settings Error**: a user, project, or local file has invalid JSON or a value the schema rejects. At the start of an interactive session Claude Code shows a dialog that lets you fix the file with Claude's help, exit, or continue without the broken settings.
* **Settings Warning**: only individual entries fail, such as a malformed permission rule or an unknown hook event name. Claude Code skips those values and keeps the rest of the file in effect.
* **Managed settings**: Claude Code keeps enforcing the rest of the file. [Invalid entries in managed settings](/docs/en/managed-settings#invalid-entries-in-managed-settings) says what it drops and which keys fall back to a stricter value until you fix them. For a managed settings document that isn't valid JSON, see [Managed settings document could not be parsed](/docs/en/errors#managed-settings-document-could-not-be-parsed).
* **Configuration error**: `~/.claude.json` can't be parsed. Claude Code copies the broken file to `~/.claude/backups/.claude.json.corrupted.<timestamp>` and asks whether to exit and fix it by hand or reset to the default configuration; a `-p` run prints the error and exits. To recover your previous state, copy back one of the five most recent `.claude.json.backup.<timestamp>` files in `~/.claude/backups/`, which Claude Code saves before it writes the file.

After you continue, run `/status` to see the affected files and `claude doctor` for the details of each error.

A `-p` run shows no dialog. Unless [a managed settings document can't be parsed](/docs/en/errors#managed-settings-document-could-not-be-parsed), Claude Code skips the broken file or values and continues with the rest, so after a `-p` run that ignores a setting, run `claude doctor` to see what it dropped.

<span id="how-scopes-interact" />

<span id="key-points-about-the-configuration-system" />

<span id="which-value-claude-code-uses" />

<span id="which-value-wins" />

## Settings precedence

When the same key appears in more than one place, Claude Code uses the value from the highest level that sets it. The stack below shows the levels, highest on top; a key at a higher level overrides the same key anywhere below it.

<SettingsPrecedence />

In order, highest precedence first:

1. **Managed settings**: settings your organization deploys, by a `managed-settings.json` file, an MDM policy, or [server-managed settings](/docs/en/server-managed-settings) from the claude.ai console. Nothing in your own settings files or `--settings` overrides a managed key, and a flag such as `--model` picks only from the models your organization allows. A managed [`model`](/docs/en/settings-reference#model) is a starting default, not a lock; the locks are [`availableModels`](/docs/en/settings-reference#availablemodels) and [`deniedModels`](/docs/en/settings-reference#deniedmodels). When your organization delivers more than one managed source, the rules for [precedence within the managed tier](/docs/en/managed-settings#precedence-within-the-managed-tier) say what Claude Code reads from each.
2. **Command line**: JSON you pass with `--settings <file-or-json>` when you start `claude`, for that session only; see [Change a setting for one session](#change-a-setting-for-one-session). A key you set there overrides the same key in your project and user settings files, and a key you leave out keeps its value from those files. Other flags, such as `--model`, set one thing for the session and aren't part of this stack; a key's entry on the [settings reference](/docs/en/settings-reference) says which flags override it.
3. **Project local settings** (`.claude/settings.local.json`): your personal settings for this project.
4. **Shared project settings** (`.claude/settings.json`): settings your team checks into source control.
5. **User settings** (`~/.claude/settings.json`): your personal settings for every project.

Environment variables aren't a level in this stack. When a behavior has both a shell variable and a settings key, which one applies is decided per pair, not by level: `ANTHROPIC_MODEL` exported in your shell applies over the `model` key from any file, while `ANTHROPIC_DEFAULT_MODEL` applies only when no file sets `model`. The [environment variables reference](/docs/en/env-vars#precedence) says which keys have a pair and which one Claude Code reads first. An `env` block inside a settings file is an ordinary key and follows the levels above.

For a few security-sensitive keys, Claude Code honors a stricter value from a lower level over a managed value; [Exceptions to managed settings precedence](#exceptions-to-managed-settings-precedence) lists them.

### Lists merge instead of overriding

When you set the same list key, such as `permissions.allow`, in more than one file, Claude Code combines the lists instead of picking one, so each file can add entries without removing another file's. Four keys that hold model lists or per-model entries follow their own rules:

* [`fallbackModel`](/docs/en/settings-reference#fallbackmodel) is an ordered chain where position carries meaning, so Claude Code takes the whole value from the highest-precedence file that defines it.
* [`modelPicker`](/docs/en/settings-reference#modelpicker) holds one ordered list of rows plus a replace flag, so Claude Code never merges rows from two sources. It takes the whole value from the highest of managed settings, `--settings`, and user settings that defines it, and ignores the key in project and local settings. Requires Claude Code v2.1.242 or later.
* [`availableModels`](/docs/en/settings-reference#availablemodels): when the managed settings Claude Code applies define it, Claude Code applies that list as-is and ignores entries you add in user, project, or local settings, unless an app that embeds Claude Code supplies its own model list; see [Exceptions to managed settings precedence](#exceptions-to-managed-settings-precedence). Across managed sources the list never merges either; [how Claude Code combines managed sources](/docs/en/managed-settings#how-claude-code-combines-managed-sources) says which source's list applies. Across non-managed scopes Claude Code merges the arrays as usual.
* [`modelSettings`](/docs/en/settings-reference#modelsettings): Claude Code resolves it one model at a time, together with [`effortLevel`](/docs/en/settings-reference#effortlevel). The `modelSettings` entry states which file's value applies to a model.

<span id="examples" />

### Precedence examples

While Claude works, Claude Code shows a one-line tip under the spinner, such as "Use /config to change your default permission mode (including Plan Mode)". Suppose you want those tips off, so you set [`spinnerTipsEnabled`](/docs/en/settings-reference#spinnertipsenabled) to `false` in `~/.claude/settings.json`. Each scenario below is something that can turn them back on, and what you can do about it.

#### Team settings override personal settings

Your team's `.claude/settings.json` sets it to `true`. Claude Code uses the project value because shared project sits above user, so you see tips in that project and nowhere else.

You can get your value back: add `"spinnerTipsEnabled": false` to `.claude/settings.local.json` in that project. Project local sits above shared project, so your sessions there stop showing tips and your teammates' sessions don't change.

#### Organization settings override everything

Your organization's managed settings set it to `true`. Nothing you put in user, project, or local settings turns tips off, and neither does `--settings`. Managed is the top level.

You can't get your value back. Run `/status` to see which managed source applies, and ask your administrator if the policy should change.

#### The command line overrides your files for one session

You started the session with `claude --settings '{"spinnerTipsEnabled": true}'`. Command line sits above every file except managed, so that session shows tips even though your files say `false`.

You get your value back on the next session; `--settings` lasts one session and doesn't write to any file.

#### A flag or environment variable sets the same thing

Some keys have a command line flag or an environment variable that overrides the settings value regardless of which file set it: `ANTHROPIC_MODEL` overrides the [`model`](/docs/en/settings-reference#model) setting, and `--model` overrides both for a session.

Whether you can get your value back depends on the key: unset the variable or drop the flag, and check the key's entry on the [settings reference](/docs/en/settings-reference) and the variable's row on the [environment variables reference](/docs/en/env-vars) for which one Claude Code uses.

<span id="keys-ignored-in-a-repository-file" />

<span id="keys-only-you-or-your-organization-can-set" />

<span id="common-cases" />

<span id="which-value-applies-in-common-situations" />
