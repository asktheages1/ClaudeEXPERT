[Part 4/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `modelPricing`

Report spend at the rates your organization pays instead of list price. Set it when your organization has contracted rates, so the dollar figures developers see match your bill. Claude Code applies the rates in `/usage`, the [status line](/docs/en/statusline), the Agent SDK's `total_cost_usd`, the [`--max-budget-usd`](/docs/en/cli-reference) limit, and the [OpenTelemetry](/docs/en/monitoring-usage) cost metric and events. You supply the rates: Claude Code doesn't read them from your contract or the Claude Console. Requires Claude Code v2.1.242 or later.

* **Scope**: [`Managed`](#scopes). Deploy the key through server-managed settings, an MDM policy, a `managed-settings.json` file, or a [policy helper](/docs/en/managed-settings#compute-the-policy-with-a-helper-program). Claude Code ignores it in user, project, and local settings, in `--settings`, and on Windows in the user-writable [HKCU registry](/docs/en/managed-settings#where-each-mechanism-stores-the-policy). With server-managed settings, each session reports costs at list price until that session's [settings fetch](/docs/en/server-managed-settings#fetch-and-caching-behavior) has confirmed the setting. A host application that embeds Claude Code and sets [`CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`](/docs/en/env-vars) can supply a table of its own through the SDK [`managedSettings`](/docs/en/agent-sdk/typescript#options) option, which Claude Code uses only when no managed source sets the key and only in Claude Code v2.1.246 or later.
* **Type**: object with an optional `multiplier` and an optional `overrides` map
* **Default**: unset, so Claude Code reports list price unless a host application supplies a table

Set `multiplier` alone for a flat discount or markup, `overrides` alone for per-model rates, or both.

This example sets contracted rates for Sonnet 4.6 and then reduces every figure, the Sonnet row included, by 15%:

```json managed-settings.json theme={null}
{
  "modelPricing": {
    "multiplier": 0.85,
    "overrides": {
      "claude-sonnet-4-6": {
        "input": 2.4,
        "output": 12,
        "cacheRead": 0.24,
        "cacheWrite": 3
      }
    }
  }
}
```

Set `multiplier` above 1, up to 10, to mark every figure up. A markup requires Claude Code v2.1.271 or later. Earlier versions ignore a `multiplier` above 1 with a warning and keep the rest of the setting.

For the steps, including how to confirm the rates are in effect, see [Report spend at your contracted rates](/docs/en/costs#report-spend-at-your-contracted-rates).

<span id="modelpricing-multiplier" />

<span id="modelpricing-overrides" />

#### Fields for `modelPricing`

| Field | Type | What it does |
| :- | :- | :- |
| `multiplier` | number greater than 0 and at most 10 | Scales every cost Claude Code computes, whether or not an `overrides` row covers it. Below 1 is a discount, above 1 a markup |
| `overrides` | map of model ID to a rate object with `input`, `output`, `cacheRead`, and `cacheWrite`, each 0 to 10000 | The USD-per-million-token rates for that model, all four required. `cacheWrite` covers both five-minute and one-hour cache writes. See [Which models a row applies to](#which-models-a-modelpricing-row-applies-to) |

Claude Code uses a row's rates exactly as you wrote them, without adding the fast-mode surcharge or the [US-only-inference rate](https://platform.claude.com/docs/en/about-claude/pricing). If you also set `multiplier`, Claude Code applies it on top of the row's rates. Claude Code drops a row with a rate it can't parse, or a `multiplier` it can't parse, and keeps the rest; see [Fix a broken settings file](/docs/en/settings#fix-a-broken-settings-file).

#### Which models a `modelPricing` row applies to

Claude Code decides which models a row applies to from the row's key:

* **A built-in model's ID**: a key Claude Code itself uses for a built-in model, whether that key is the model's own ID, such as `claude-sonnet-4-6`, or its Bedrock, Agent Platform, or Foundry ID. Claude Code applies the row to every dated snapshot ID and provider-specific ID of that model.
* **Any other key**: a key that isn't a built-in model's ID, such as a gateway model alias. Claude Code applies the row to that one ID only. When a model ID matches one of your keys exactly and also falls under a row keyed by a built-in model's ID, Claude Code uses the exact match.
* **A Bedrock application inference profile**: once Claude Code has resolved the profile to the model it routes to, through your [`modelOverrides`](#modeloverrides) map or the [`bedrock:GetInferenceProfile` lookup](/docs/en/amazon-bedrock#iam-configuration), Claude Code applies that model's row to the profile.

### `modelSettings`

Save an [effort level](/docs/en/model-config#adjust-effort-level) for each model you use. Requires Claude Code v2.1.251 or later.

In an interactive session on your machine, when you save `low`, `medium`, `high`, or `xhigh` as your default with `/effort` or the `/model` picker's effort slider, Claude Code writes that level here under the model you're using, so you rarely edit this key yourself. When you pick one of those levels in the [VS Code extension's model picker](/docs/en/vs-code#use-the-prompt-box), Claude Code saves it here the same way. The [`effortLevel`](#effortlevel) entry lists the sessions where `/effort` applies to that session only.

Edit the key by hand to change or remove a level you saved.

A model's `effortLevel` here takes precedence over the top-level [`effortLevel`](#effortlevel) in the same settings file. Across files, Claude Code resolves each model separately: the highest-precedence [settings file](/docs/en/settings#settings-precedence) that sets either an `effortLevel` for that model or a top-level `effortLevel` that [applies to that model](#effortlevel) decides, so an `effortLevel` in managed settings outranks a level you saved in user settings. [Adjust effort level](/docs/en/model-config#adjust-effort-level) lists what else can override a saved level, such as `--effort` at launch.

To cap one model's effort rather than set its level, add a [`maxEffortLevel`](#maxeffortlevel) field to that model's entry. The field requires Claude Code v2.1.267 or later.

* **Scope**: [`Any file`](#scopes)
* **Type**: object mapping a model name to an object with any of these fields:
  * `effortLevel`: one of `"low"`, `"medium"`, `"high"`, or `"xhigh"`
  * [`maxEffortLevel`](#maxeffortlevel): the highest effort level the model may run at
  * `autoCompactWindow`: a number of tokens from `100000` to `1000000`, or `"auto"` for the window tuned for the model. [`/autocompact`](/docs/en/model-config#set-the-auto-compact-window) saves here. For that model, the value takes precedence over a top-level [`autoCompactWindow`](#autocompactwindow) in the same settings file. Requires Claude Code v2.1.288 or later
* **Default**: unset

Claude Code writes each entry under the model's canonical name, such as `claude-opus-5-5`, and matches that model's alias, date-suffixed, `[1m]`, and recognized provider-specific IDs to the same entry.

This example keeps Opus 5.5 at `high` while other models use their own saved or default levels:

```json settings.json theme={null}
{
  "modelSettings": {
    "claude-opus-5-5": {
      "effortLevel": "high"
    }
  }
}
```

Run `/effort auto` to clear your saved level for the model you're using. Claude Code leaves the other entries and any top-level `effortLevel` in place.

### `outputStyle`

Select an [output style](/docs/en/output-styles) by name. An output style is a saved set of instructions that changes Claude's role, tone, and output format, such as the built-in Explanatory and Learning styles or one you wrote yourself.

If you change this key during a session, Claude uses the new style starting with your next message. For what that message costs in prompt caching, see [Changing output style](/docs/en/prompt-caching#changing-output-style). Before v2.1.251, the edit applied only after you ran `/clear` or started a new session.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, the name of a [built-in](/docs/en/output-styles#built-in-output-styles) or [custom](/docs/en/output-styles#create-a-custom-output-style) output style
* **Default**: unset, so Claude Code uses the default style

This example selects the built-in Explanatory style, which adds educational insights between tasks:

```json settings.json theme={null}
{
  "outputStyle": "Explanatory"
}
```

### `promptCacheTtl`

Choose how long the [prompt cache](/docs/en/prompt-caching) holds the main conversation. This key applies to your interactive, `-p`, and Agent SDK turns, together with the helpers Claude Code runs inline with them. The one-hour lifetime keeps the cache warm across longer breaks, and the API [bills each cache write at a higher rate](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#pricing) than at the five-minute lifetime. Requires Claude Code v2.1.242 or later.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"5m"`: the cache holds for five minutes
  * `"1h"`: the cache holds for an hour
* **Default**: unset, so each main-conversation request gets [its default lifetime](/docs/en/prompt-caching#which-ttl-each-request-gets)
* **Per-session overrides**: [`FORCE_PROMPT_CACHING_5M`](/docs/en/env-vars) takes precedence over everything else, then [`CLAUDE_CODE_PROMPT_CACHE_TTL`](/docs/en/env-vars), then this key, and last [`ENABLE_PROMPT_CACHING_1H`](/docs/en/env-vars)

This example keeps the main conversation on the one-hour lifetime and leaves subagents on five minutes:

```json settings.json theme={null}
{
  "promptCacheTtl": "1h",
  "subagentPromptCacheTtl": "5m"
}
```

For what each lifetime costs, see [Cache lifetime](/docs/en/prompt-caching#cache-lifetime).

### `showThinkingSummaries`

See summaries of Claude's [extended thinking](/docs/en/model-config#extended-thinking) in interactive sessions. Set it if you want the full summaries when you expand thinking with `Ctrl+O`. When unset or `false`, the Anthropic API redacts thinking blocks and Claude Code shows a collapsed stub; third-party providers don't redact.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: you see full thinking summaries when you expand thinking with `Ctrl+O`
  * `false`: the Anthropic API redacts thinking blocks and Claude Code shows a collapsed stub
* **Default**: `false`

```json settings.json theme={null}
{
  "showThinkingSummaries": true
}
```

Redaction changes only what you see, not what the model generates. To reduce thinking spend, [lower the budget or disable thinking](/docs/en/model-config#extended-thinking) instead.

### `subagentPromptCacheTtl`

Choose how long the [prompt cache](/docs/en/prompt-caching) holds the requests Claude Code makes outside the main conversation. This key applies to [subagents](/docs/en/sub-agents), [workflows](/docs/en/workflows), and Claude Code's own background and helper requests, such as compaction and session titles. The one-hour lifetime keeps the cache warm across longer breaks, and the API [bills each cache write at a higher rate](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#pricing) than at the five-minute lifetime. Requires Claude Code v2.1.242 or later.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"5m"`: the cache holds for five minutes
  * `"1h"`: the cache holds for an hour
* **Default**: unset, so each of these requests gets [its default lifetime](/docs/en/prompt-caching#which-ttl-each-request-gets)
* **Per-session overrides**: [`FORCE_PROMPT_CACHING_5M`](/docs/en/env-vars) takes precedence over everything else, then [`CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL`](/docs/en/env-vars), then this key, then [`ENABLE_PROMPT_CACHING_1H`](/docs/en/env-vars), which asks for the one-hour lifetime on every request. For where a subagent's own frontmatter value ranks, see [Choose the TTL yourself](/docs/en/prompt-caching#choose-the-ttl-yourself)

This example gives subagents and the other requests outside the main conversation the one-hour lifetime:

```json settings.json theme={null}
{
  "subagentPromptCacheTtl": "1h"
}
```

This key covers the requests [`promptCacheTtl`](#promptcachettl) doesn't, so set both to choose a lifetime for every request Claude Code makes. For how a subagent's cache differs from the main conversation's, see [Subagents and the cache](/docs/en/prompt-caching#subagents-and-the-cache).

### `switchModelsOnFlag`

Choose what happens when a [safety classifier flags a request](/docs/en/model-config#automatic-model-fallback): switch to the fallback model and continue, or pause so you can choose between switching and editing the prompt.

* **Scope**: [`Any file`](#scopes). Appears in `/config` as **Switch models when a message is flagged**.
* **Type**: Boolean
  * `true`: Claude Code switches to the fallback model and continues
  * `false`: in an interactive session Claude Code pauses so you can choose between switching and editing the prompt; where no dialog can show, such as a `-p` run, the flagged request ends as an error
* **Default**: `true`, switch automatically

```json settings.json theme={null}
{
  "switchModelsOnFlag": false
}
```

See [Ask before switching](/docs/en/model-config#ask-before-switching).

### `ultracode`

Start sessions with [ultracode](/docs/en/workflows#let-claude-decide-with-ultracode) on. With it on, Claude plans a workflow for each substantive task instead of waiting for you to ask. Claude plans workflows only when [dynamic workflows](/docs/en/workflows) are enabled for you and your model supports `xhigh` effort. The key doesn't change the session's effort level: ultracode runs at whichever level the session uses. Claude Code reads this key but never writes it: `/effort ultracode` turns ultracode on for the current session only.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: sessions start with ultracode on when dynamic workflows are enabled for you and your model supports `xhigh`
  * `false`: sessions start with ultracode off
* **Default**: unset, so ultracode is off
* **Per-session overrides**: `/effort ultracode` turns ultracode on for one session without this key, and `/effort ultracode off` turns it off for one session when this key is `true`. The `--effort ultracode` flag also turns it on for one session, at `xhigh` effort, and requires Claude Code v2.1.203 or later

```json settings.json theme={null}
{
  "ultracode": true
}
```

The session's effort level comes from [`effortLevel`](#effortlevel), [`modelSettings`](#modelsettings), and the other [effort sources](/docs/en/model-config#adjust-effort-level), and an [effort cap](/docs/en/model-config#organization-effort-limits) such as [`maxEffortLevel`](#maxeffortlevel) lowers that level without turning ultracode off. This and the `/effort ultracode off` form require Claude Code v2.1.284 or later. Before v2.1.284, `ultracode: true` ran the session at `xhigh` effort, and an effort cap below `xhigh` kept ultracode off. An Agent SDK `apply_flag_settings` control request also accepts the key.

## Permission settings

Decide what Claude can do without asking, which permission mode a session starts in, and what auto mode's classifier allows. For rule syntax and the permission model, see [Configure permissions](/docs/en/permissions).

### `allowManagedPermissionRulesOnly`

Make managed settings the only settings source of permission rules. Claude Code then ignores `allow`, `ask`, and `deny` rules in user, project, local, and `--settings` files, ignores `--allowedTools`, hides the always-allow choices in permission prompts, and stops saving new rules.

When [parent settings from an embedding host](/docs/en/managed-settings#let-an-embedding-host-add-policy) apply, Claude Code treats them as part of the managed tier. It drops their `allow` rules and `additionalDirectories`, and keeps their `deny` and `ask` rules except `Read` and `Edit` rules whose pattern starts with `!`. A host can't carve paths out of the managed rules with a `!` rule, whether or not you set this key.

`--disallowedTools` rules and the current session's `deny` and `ask` rules still apply, including after Claude Code reloads settings mid-session. They only restrict, so they can't widen what the managed rules grant. Before v2.1.257, Claude Code dropped those command-line and session rules at the first settings reload.

For what a `!` pattern in a `--disallowedTools` or session rule can carve out, see [Read and Edit rules](/docs/en/permissions#read-and-edit).

When you set this key, Claude Code v2.1.282 or later also ignores the [`allowed-tools`](/docs/en/skills#pre-approve-tools-for-a-skill) frontmatter in skills and `.claude/commands/` files from these sources:

* A repository's `.claude/` directory
* Your `~/.claude/skills/` and `~/.claude/commands/` directories, including [skills synced from claude.ai](/docs/en/skills#where-synced-skills-load)
* An `--add-dir` directory
* [Plugins declared with a `.claude-plugin` manifest](/docs/en/plugins/loading#plugins-shared-through-a-repository) inside `~/.claude/skills/` or the project's `.claude/skills/`

Skills from managed settings and bundled skills keep their `allowed-tools`. A skill's `disallowed-tools` still applies. For what a developer sees when Claude Code ignores the field, see [When only managed permission rules apply](/docs/en/skills#when-only-managed-permission-rules-apply).

* **Scope**: [`Managed`](#scopes)
* **Type**: Boolean
  * `true`: managed settings become the only settings source of permission rules
  * `false`: Claude Code applies permission rules from user, project, local, and `--settings` files in addition to the managed ones
* **Default**: unset, so Claude Code applies permission rules from user, project, and local settings and from `--settings`, in addition to the managed ones

```json managed-settings.json theme={null}
{
  "allowManagedPermissionRulesOnly": true
}
```

This key doesn't lock down the MCP server allowlist; for that, set [`allowManagedMcpServersOnly`](#allowmanagedmcpserversonly). See [Managed-only settings](/docs/en/managed-settings#managed-only-settings).

### `autoMode`

Add your own rules to what the [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) classifier blocks and allows. Use it to tell the classifier which repos, buckets, and domains your organization trusts, so it stops blocking routine internal operations. The classifier ships with [built-in allow and deny rules](/docs/en/auto-mode-config#inspect-the-defaults-and-your-effective-config). Include the literal string `"$defaults"` in an array to keep those built-in rules at that position and add yours around them; leave it out to replace them with yours.

* **Scope**: [`User or managed`](#scopes)
* **Type**: object with `environment`, `allow`, `soft_deny`, and `hard_deny` arrays of prose rules, plus the [`classifyAllShell`](#automode-classifyallshell) Boolean
* **Default**: unset, so the classifier uses only its [built-in rules](/docs/en/auto-mode-config#inspect-the-defaults-and-your-effective-config)

This example keeps the built-in `soft_deny` rules, through `"$defaults"`, and adds one more that blocks `terraform apply`:

```json settings.json theme={null}
{
  "autoMode": {
    "soft_deny": ["$defaults", "Never run terraform apply"]
  }
}
```

When more than one of those files sets the same array, Claude Code concatenates the entries. For the rule format and how each array is applied, see [Configure auto mode](/docs/en/auto-mode-config).

### `autoMode.classifyAllShell`

Send every Bash and PowerShell command through the auto mode classifier while auto mode is active. By default, auto mode suspends only allow rules that could run arbitrary code: tool-wide and wildcard rules such as `Bash(*)`, and interpreter or shell-wrapper prefixes such as `Bash(python *)`. A command that any other allow rule matches, such as `Bash(npm test)`, skips the classifier unless it carries [per-command allowed domains](/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode). When it skips, a destructive argument the rule's prefix didn't anticipate can get through unseen. Setting this key suspends every shell allow rule for the session so the classifier sees every command. Requires Claude Code v2.1.193 or later.

* **Scope**: [`User or managed`](#scopes). Read wherever [`autoMode`](#automode) is read.
* **Type**: Boolean
  * `true`: while auto mode is active, Claude Code sends every Bash and PowerShell command through the classifier and suspends your shell allow rules; outside auto mode the rules still apply
  * `false`: auto mode suspends only allow rules that could run arbitrary code, such as `Bash(*)` and `Bash(python *)`; a command that any other allow rule matches skips the classifier unless it carries [per-command allowed domains](/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode), and every other shell command goes through it
* **Default**: `false`

```json settings.json theme={null}
{
  "autoMode": {
    "classifyAllShell": true
  }
}
```

See [Route all shell commands through the classifier](/docs/en/auto-mode-config#route-all-shell-commands-through-the-classifier).

### `disableAutoMode`

Remove [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) from the `Shift+Tab` cycle. Any session that would otherwise [start in auto mode](/docs/en/permission-modes#which-mode-a-session-starts-in), whether from `--permission-mode auto`, a settings file, or the built-in default, starts in `default` instead. Administrators set it in managed settings to prevent developers in their organization from using auto mode.

* **Scope**: [`Any file`](#scopes). Most useful in [managed settings](/docs/en/managed-settings), where users can't override it. Also accepted under `permissions` as `permissions.disableAutoMode`.
* **Type**: the string `"disable"`
* **Default**: unset

```json settings.json theme={null}
{
  "disableAutoMode": "disable"
}
```
