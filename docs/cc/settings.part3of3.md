[Part 3/3 of https://code.claude.com/docs/en/settings.md, fetched 2026-10-08]

### Troubleshoot a setting that doesn't apply

When you set a key and Claude Code doesn't behave as if you had, start with `/status` to see which files it loaded, then find your symptom below. [Debug your configuration](/docs/en/debug-your-config) covers the wider checks, including a clean-configuration test.

#### A value you set is ignored

Something else is setting the same key, the file can't set that value, or the file didn't load:

* **A higher level sets it.** Another settings file, a `--settings` flag, or a managed source sets the key above yours; the [stack](#settings-precedence) says which. A flag or environment variable can also override the key on its own, decided key by key; the key's entry on the [settings reference](/docs/en/settings-reference) says which one Claude Code uses, and the [`env` entry](/docs/en/settings-reference#env) covers a managed `env` value versus a shell export.
* **A security key keeps its strict value.** For a few keys Claude Code honors the restrictive value from any file, so a project `true` for [`disableClaudeAiConnectors`](/docs/en/settings-reference#disableclaudeaiconnectors) stays on; see [Exceptions to managed settings precedence](#exceptions-to-managed-settings-precedence).
* **The file can't set that value.** [`permissions.defaultMode`](/docs/en/settings-reference#permissions-defaultmode) values `auto` and `bypassPermissions` don't take effect from project or local settings; set them in user or managed settings instead, or pass `--permission-mode` for one session. Before v2.1.257, `bypassPermissions` took effect from any file.

  A telemetry export variable in an [`env`](/docs/en/settings-reference#env) block doesn't take effect from project or local settings either, apart from a few off values. [Variables Claude Code ignores in `env`](/docs/en/settings-reference#variables-claude-code-ignores-in-env) lists the variables and those values.
* **The file is broken.** Invalid JSON or a rejected value makes Claude Code skip the file or the entry; see [Fix a broken settings file](#fix-a-broken-settings-file).

#### A change you made in Claude Code is lost in new sessions

When you save a choice for new sessions from inside Claude Code, such as a default model with `/model`, Claude Code writes it to your user settings file, `~/.claude/settings.json`. If you can't write to that file, for example because another tool generates it or links it to a read-only copy, the change applies to the current session and is gone in the next one. Set the key in the tool that generates the file, or replace the file with one you can write to.

If you can write to the file and the change still doesn't last, check whether the change was [for one session only](#change-a-setting-for-one-session) or [a higher level sets the same key](#a-value-you-set-is-ignored). For the `model` key, [A new session starts on a different model than you picked](/docs/en/model-config#a-new-session-starts-on-a-different-model-than-you-picked) lists more causes.

#### A managed change hasn't reached you

Managed sources reach a running session on the schedule in the [delivery table](/docs/en/managed-settings#choose-a-delivery-mechanism), so restart the session first. If `/status` then names a different source than the one your administrator changed, a higher-priority source applies; [How Claude Code combines managed sources](/docs/en/managed-settings#how-claude-code-combines-managed-sources) gives the order.

#### A committed key doesn't reach teammates

Two things keep a key in `.claude/settings.json` from applying for everyone who clones it:

* **Claude Code ignores the key in a repository file.** Look for `User, local, or managed`, `User or managed`, `Managed`, or `Global config` in the Scope column of the [settings index](/docs/en/settings-reference#settings-index). Those keys never apply from the shared file, apart from a few that a repository file can still switch off. Each of those entries says so on its Scope line. `Global config` keys apply only from `~/.claude.json`.

  Inside the `env` key, the telemetry export variables never apply from the shared file either, apart from a few off values; see [Variables Claude Code ignores in `env`](/docs/en/settings-reference#variables-claude-code-ignores-in-env).
* **The key waits for trust.** `permissions.allow` rules, `permissions.additionalDirectories`, `extraKnownMarketplaces`, and most [`env`](/docs/en/settings-reference#env) values apply only after each teammate [trusts the folder](/docs/en/permissions#project-allow-rules-and-workspace-trust). Until then they still see prompts and don't get plugins from a marketplace the file declares. `deny` and `ask` rules apply right away.

#### Permission rules combine differently than you expected

* **You chose "Yes, and don't ask again" on a permission prompt but still get prompted for the same tool.** That choice saved an `allow` rule to your local file, and an `allow` rule there doesn't outrank an `ask` rule from a project or managed file; [how permission rules combine](/docs/en/permissions#settings-precedence) explains the order. In the VS Code extension the approval card lets you pick the destination file, including the project's shared file, which changes the rule for everyone; in the CLI, Claude Code writes only to your local file.
* **Your organization's allow rules still apply alongside yours.** That's expected: Claude Code merges [`permissions.allow`](/docs/en/settings-reference#permissions-allow) across scopes, unless your organization sets [`allowManagedPermissionRulesOnly`](/docs/en/settings-reference#allowmanagedpermissionrulesonly).

<span id="security-keys-where-the-stricter-value-applies" />

### Exceptions to managed settings precedence

For a few keys whose values restrict a session, Claude Code honors a restrictive value from a scope that otherwise couldn't override managed settings. Find the key in this table to see which value it honors and from where.

| Key | Value Claude Code honors | Notes |
| :- | :- | :- |
| [`disableClaudeAiConnectors`](/docs/en/settings-reference#disableclaudeaiconnectors) | `true` from any scope | Honored even when a managed source sets `false` |
| [`enableArtifact`](/docs/en/settings-reference#enableartifact) | `false` from any scope, and `disableArtifact: true` from any scope | Honored even when a managed source sets `true`; nothing turns the [Artifact tool](/docs/en/artifacts#disable-artifacts) back on. Requires Claude Code v2.1.242 or later |
| [`isolatePeerMachines`](/docs/en/settings-reference#isolatepeermachines) | `true` from any scope | Honored even when a managed source sets `false` |
| [`permissions.blockReadsOutsideWorkingDirectories`](/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) | `true` from any scope | Honored even when a managed source sets `false`. Requires Claude Code v2.1.257 or later |
| [`autoMode.classifyAllShell`](/docs/en/settings-reference#automode-classifyallshell) | `true` from `~/.claude/settings.json` or `--settings` | Honored even when a managed source sets `false` |
| [`remoteControlAtStartup`](/docs/en/settings-reference#remotecontrolatstartup) | `false` from `.claude/settings.json` or `.claude/settings.local.json` | Honored even when a managed source sets `true`; a project or local `true` is ignored |
| [`crossSessionInbound`](/docs/en/settings-reference#crosssessioninbound) | A stricter value from `.claude/settings.json` or `.claude/settings.local.json`, on the `accept` \< `hold` \< `refuse` ladder | Honored over managed, `--settings`, and user values; a project or local value that isn't stricter is ignored |
| [`useAutoModeDuringPlan`](/docs/en/settings-reference#useautomodeduringplan) | `false` from any managed source, `--settings`, `~/.claude/settings.json`, or `.claude/settings.local.json` | Honored even when the winning managed source sets `true`; a `false` in `.claude/settings.json` is ignored |
| [`syncClaudeAiSkills`](/docs/en/settings-reference#syncclaudeaiskills) | `false` from any managed source, `--settings`, `~/.claude/settings.json`, or `.claude/settings.local.json` | Honored even when the winning managed source sets `true`; a `false` in `.claude/settings.json` is ignored |
| [`syncClaudeAiPlugins`](/docs/en/settings-reference#syncclaudeaiplugins) | `false` from any managed source, `--settings`, `~/.claude/settings.json`, or `.claude/settings.local.json` | Honored even when the winning managed source sets `true`; a `false` in `.claude/settings.json` is ignored |
| [`maxEffortLevel`](/docs/en/settings-reference#maxeffortlevel) | A lower cap from any scope, including `--settings` | Honored even when the managed settings Claude Code applies set a higher cap; the lowest cap applies. Requires Claude Code v2.1.267 or later |

An app that runs Claude Code inside itself and sets [`CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`](/docs/en/env-vars) is also an exception. Claude Code takes that app's model configuration over the `model`, `fallbackModel`, `modelPicker`, and `modelOverrides` keys from every managed source, and over the model-selection variables in a managed `env` block, such as `ANTHROPIC_MODEL` and the `ANTHROPIC_DEFAULT_*_MODEL` family. Claude Code keeps a managed [`availableModels`](/docs/en/settings-reference#availablemodels) allowlist in force unless the app supplies its own.

## Settings in cloud sessions

A [cloud session](/docs/en/claude-code-on-the-web) runs in a [cloud environment](/docs/en/cloud-environments) on a fresh clone of your repository, not on your machine. That changes which settings reach it:

* **Shared project settings** (`.claude/settings.json`): read in a session with one repository, because the file is part of the clone and the session starts inside it. Commit a setting there to apply it in those sessions. A session with several repositories starts above the clones and reads only the `enabledPlugins` and `extraKnownMarketplaces` keys from each repository's `.claude/settings.json`, not permission rules, hooks, `env`, or other keys. The marketplaces and plugins those two keys declare still [don't load in a cloud session](/docs/en/cloud-environments#what-carries-over-from-your-setup).
* **User and project local settings** (`~/.claude/settings.json` and `.claude/settings.local.json`): not read. Both stay on your machine, and the local file isn't in the clone.
* **Managed settings**: a `managed-settings.json` file or MDM profile on your device doesn't reach a cloud session. Your organization's [server-managed settings](/docs/en/server-managed-settings) do; [surface coverage](/docs/en/model-config#surface-coverage) lists which cloud sessions receive them. A [self-hosted environment](/docs/en/self-hosted-environments) also reads the managed settings file in its runner image. [How Claude Code combines managed sources](/docs/en/managed-settings#how-claude-code-combines-managed-sources) says when that file applies.
* **`/config`**: in your browser at claude.ai/code, opens the Claude Code section of your claude.ai settings instead of changing a value. To change a setting for a cloud session, set an [environment variable](/docs/en/cloud-environments#set-environment-variables) on the environment, or in a session with one repository, commit the key to that repository's `.claude/settings.json`.

[What carries over from your setup](/docs/en/cloud-environments#what-carries-over-from-your-setup) lists the rest: `CLAUDE.md`, skills, MCP servers, plugins, and credentials.

## What's next

* [All settings](/docs/en/settings-reference): every key, with where you set it and an example
* [Example settings files](/docs/en/settings-example): a personal file, a team file, and an organization's managed file
* [Configure permissions](/docs/en/permissions): allow, ask, and deny rules, and what Claude Code runs without asking
* [Environment variables](/docs/en/env-vars): the variables Claude Code reads and the `env` block
* [Debug your configuration](/docs/en/debug-your-config): when a setting doesn't apply
* [Claude directory reference](/docs/en/claude-directory): every file Claude Code reads, including subagents, MCP servers, plugins, and `CLAUDE.md`
