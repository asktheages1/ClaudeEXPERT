[Part 3/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

## Model and responses

Choose which models Claude Code uses and how it responds. For how these settings interact with the `/model` command and environment variables, see [Model configuration](/docs/en/model-config).

### `advisorModel`

Pick which model answers when Claude calls the server-side [advisor tool](/docs/en/advisor). Unset it to turn the advisor off. The advisor must be at least as capable as your main model. See [Choose an advisor model](/docs/en/advisor#choose-an-advisor-model) for the accepted pairings and what happens when you pick one that isn't accepted.

You don't usually edit this key by hand. Run `/advisor` to open a picker that shows the current choice, the models that can advise, and **No advisor**. Claude Code saves your pick to this key in `~/.claude/settings.json`. If you pick from a [Remote Control](/docs/en/remote-control) client or in a session attached to a remote worker, the pick applies to that session only and doesn't change this key.

If your account requires the [usage-credits consent](/docs/en/advisor#fable-advisor-and-usage-credits), accept it first by running `/model fable`. Until you do, picking Fable in `/advisor` saves nothing and Claude Code tells you to run `/model fable` first.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of the aliases `"fable"`, `"opus"`, or `"sonnet"`, which resolve to Claude Code's current default version of that model family, or a full model ID such as `"claude-opus-5-5"`
* **Default**: unset, so the advisor is off
* **Per-session overrides**: `--advisor` takes precedence over this key for one session. [`CLAUDE_CODE_DISABLE_ADVISOR_TOOL`](/docs/en/env-vars) turns the advisor off, and this key can't turn it back on

```json settings.json theme={null}
{
  "advisorModel": "opus"
}
```

The key has no effect on providers where the advisor [isn't available](/docs/en/advisor#requirements), such as Amazon Bedrock and Claude Platform on AWS. `"fable"` requires [Fable access](/docs/en/advisor#choose-an-advisor-model).

### `alwaysThinkingEnabled`

Turn [extended thinking](/docs/en/model-config#extended-thinking) off for every session by setting this to `false`. Thinking is on by default, so `true` changes nothing. Most people set this through `/config` rather than by editing the file.

On models that always think, such as Opus 5.5, Sonnet 5.5, Haiku 5.5, and the Fable models, `false` has no effect. On [third-party providers](/docs/en/third-party-integrations) Claude Code omits the `thinking` parameter instead of turning thinking off, so adaptive-reasoning models may still think. With thinking turned off on the Anthropic API, Claude Code sends effort `high` instead of a higher level to models it knows [don't accept that combination](/docs/en/errors#effort-isnt-available-with-thinking-turned-off), such as Opus 5.

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: no effect; thinking is already on
  * `false`: Claude Code turns extended thinking off for every session
* **Default**: unset, so thinking is on for models that support it
* **Per-session overrides**: [`MAX_THINKING_TOKENS`](/docs/en/env-vars) takes precedence over this key for one session: `0` turns thinking off, under the same model and provider limits as `false`, and a positive value turns thinking on even when this key is `false`. On adaptive-reasoning models the number itself is ignored

```json settings.json theme={null}
{
  "alwaysThinkingEnabled": false
}
```

### `availableModels`

Restrict which models people can select for the main session, [subagents](/docs/en/sub-agents), [skills](/docs/en/skills), and the [advisor](/docs/en/advisor). A managed list constrains `/model`, `--model`, and the `model` key in a developer's own files; a model outside it can't be selected. With the default prefix matching, this doesn't touch the Default option on its own; pair it with [`enforceAvailableModels`](#enforceavailablemodels) for that.

* **Scope**: [`Any file`](#scopes). Deploy it in managed settings to enforce it for an organization.
* **Type**: array of model aliases or IDs
* **Default**: unset, so every model is available

This example lets people select only Sonnet and Haiku models:

```json settings.json theme={null}
{
  "availableModels": ["sonnet", "haiku"]
}
```

A model ID entry such as `"claude-opus-5"` also permits later versions that extend it, such as Opus 5.5. To block one of those versions, use [`deniedModels`](#deniedmodels). To make each model ID entry permit only the version it names, use [`availableModelsMatch`](#availablemodelsmatch). See [Restrict model selection](/docs/en/model-config#restrict-model-selection).

### `availableModelsMatch`

Choose how [`availableModels`](#availablemodels) entries match model IDs. By default a model ID entry also permits later versions that extend it, so `"claude-opus-5"` permits Opus 5.5. With `"exact"`, each model ID entry permits only the version it names, so a newer version of that model stays blocked until you list it. Requires Claude Code v2.1.283 or later.

* **Scope**: [`Managed`](#scopes). Claude Code ignores the key in user, project, and local settings and in `--settings`, with a warning
* **Type**: string, one of:
  * `"prefix"`: a model ID entry permits its version and any model ID that extends it with another segment
  * `"exact"`: a model ID entry permits only the version it names, including that version's dated IDs, so `"claude-opus-5"` permits Opus 5 but not `claude-opus-5-5`. A family alias such as `"opus"` still permits the whole family, and `best`, `opusplan`, and `default` entries are ignored
* **Default**: `"prefix"`

This example permits Opus 5 and Sonnet 5 and no later release of either:

```json managed-settings.json theme={null}
{
  "availableModels": ["claude-opus-5", "claude-sonnet-5"],
  "availableModelsMatch": "exact"
}
```

With `"exact"`, the Default option is also limited to the listed models whenever the list names at least one model or family. See [Block specific models or versions](/docs/en/model-config#block-specific-models-or-versions).

### `deniedModels`

Block specific models, with or without an [`availableModels`](#availablemodels) allowlist and even when that list permits them. Claude Code hides a blocked model from the `/model` picker, and the model can't be selected anywhere `availableModels` is enforced. A session on the Default option doesn't run a blocked model either, as [Block specific models or versions](/docs/en/model-config#block-specific-models-or-versions) describes. Requires Claude Code v2.1.283 or later.

* **Scope**: [`Managed`](#scopes). Claude Code ignores the key in user, project, and local settings and in `--settings`, with a warning
* **Type**: array of model aliases or IDs
  * A family alias such as `"opus"` blocks every model in that family
  * A model ID such as `"claude-opus-5-5"` blocks that version in every spelling, including dated and provider-specific IDs
  * A model ID with no minor version, such as `"claude-opus-5"`, also blocks later minor versions such as Opus 5.5. Write `"claude-opus-5-0"` to block Opus 5 alone
  * `best`, `opusplan`, and `default` entries are ignored
* **Default**: unset, so no model is blocked

This example permits Opus and Sonnet models and blocks Opus 5.5:

```json managed-settings.json theme={null}
{
  "availableModels": ["opus", "sonnet"],
  "deniedModels": ["claude-opus-5-5"]
}
```

See [Block specific models or versions](/docs/en/model-config#block-specific-models-or-versions).

### `effortLevel`

Set a default [effort level](/docs/en/model-config#adjust-effort-level) for models you haven't saved a level for. Lower levels are faster and cheaper on straightforward tasks, and higher levels reason more deeply on complex problems.

When you run `/effort low`, `medium`, `high`, or `xhigh` in an interactive session on your machine, Claude Code saves the level for the active model under [`modelSettings`](#modelsettings) rather than writing this key. Before v2.1.251, `/effort` wrote this key.

Within the same settings file, Claude Code uses a model's saved level rather than this key. [`modelSettings`](#modelsettings) states the cross-file precedence.

In a session attached to a remote worker, in a `-p` run, and in the Agent SDK, `/effort` applies to that session only. [Adjust effort level](/docs/en/model-config#adjust-effort-level) lists the interactive picks that also apply to that session only. The message that `/effort` prints says which happened.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, one of:
  * `"low"`: the least reasoning, for short, scoped, latency-sensitive tasks that aren't intelligence-sensitive
  * `"medium"`: reduces token usage for cost-sensitive work that can trade off some intelligence
  * `"high"`: balances token usage and intelligence
  * `"xhigh"`: deeper reasoning at higher token spend
* **Default**: unset
* **Per-session overrides**: `--effort` takes precedence over this key for one session, and [`CLAUDE_CODE_EFFORT_LEVEL`](/docs/en/env-vars) takes precedence over both

```json settings.json theme={null}
{
  "effortLevel": "xhigh"
}
```

In your user settings file, `~/.claude/settings.json`, this key is the older form `/effort` wrote before it saved levels per model, and it keeps applying where it applied before, on Opus 5, Fable 5.1, and earlier models. Opus 5.5 and models released after it ignore it and start at their own default until you save a level for them, which `/effort` writes under [`modelSettings`](#modelsettings). In project, local, and managed settings, and with `--settings`, this key applies to every model.

### `enforceAvailableModels`

The `/model` picker has a **Default** option, and [`default` model setting](/docs/en/model-config#default-model-setting) describes the model it resolves to. An [`availableModels`](#availablemodels) allowlist limits the models you can name, but with the default [prefix matching](#availablemodelsmatch) it doesn't remap your account type's default, so **Default** can still resolve to a model outside the list. This key closes that gap. Requires Claude Code v2.1.175 or later.

When your organization deploys any managed settings, Claude Code reads this key from the managed source alone and ignores it in your other files.

For how this key applies to the startup model checks, see [Amazon Bedrock](/docs/en/amazon-bedrock#when-your-organization-enforces-a-model-allowlist) and [Google Cloud's Agent Platform](/docs/en/google-vertex-ai#when-your-organization-enforces-a-model-allowlist).

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: when **Default** would resolve to a model outside `availableModels`, Claude Code resolves it to the first available model in the list
  * `false`: this key doesn't change how **Default** resolves
* **Default**: `false`

This example restricts named selections to Sonnet and Haiku models and makes **Default** resolve to the first of them that is available:

```json settings.json theme={null}
{
  "availableModels": ["sonnet", "haiku"],
  "enforceAvailableModels": true
}
```

This key has no effect when `availableModels` is unset or empty. See [Enforce the allowlist for the Default model](/docs/en/model-config#enforce-the-allowlist-for-the-default-model). Requires Claude Code v2.1.175 or later.

### `fallbackModel`

Name backup models for Claude Code to try, in order, when your primary model is overloaded or unavailable. Claude Code switches to the next available model in the chain for the rest of the turn and shows a notice. Without a chain, Claude Code retries the same model and then surfaces the server's error, and you retry or switch models yourself.

A switch means one turn with a cold [prompt cache](/docs/en/prompt-caching#switching-models) on the fallback model; your next message tries the primary model first again.

* **Scope**: [`Any file`](#scopes)
* **Type**: array of model aliases or IDs; `"default"` expands to the default model
* **Default**: unset, so a failed request isn't retried on another model
* **Per-session overrides**: `--fallback-model` takes precedence over this key for one session

This example tries Sonnet 5 first, then Haiku 4.5, when your primary model fails:

```json settings.json theme={null}
{
  "fallbackModel": ["claude-sonnet-5", "claude-haiku-4-5"]
}
```

Unlike most array settings, this key doesn't merge across settings files: the highest-precedence file that defines it supplies the whole chain. If your project file sets `["claude-sonnet-5"]` and your user file sets `["claude-haiku-4-5"]`, the chain is `["claude-sonnet-5"]` only. Claude Code keeps at most three distinct allowed models from the list and ignores the rest. See [Fallback model chains](/docs/en/model-config#fallback-model-chains).

### `fastMode`

Turn [fast mode](/docs/en/fast-mode) on for sessions where it's available, for interactive work like rapid iteration or live debugging where you want speed at a higher cost per token. You don't usually edit this key by hand: running `/fast` writes `fastMode: true` to `~/.claude/settings.json`, and running it again to turn fast mode off removes the key. Fast mode runs only on Opus 5.5, Opus 5, and Opus 4.8: turning it on from another model switches you to Opus, and switching to an unsupported model turns it off. See [Switch models while fast mode is on](/docs/en/fast-mode#switch-models-while-fast-mode-is-on).

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code turns fast mode on for sessions where it's available
  * `false`: fast mode stays off
* **Default**: unset, so fast mode is off
* **Per-session overrides**: [`CLAUDE_CODE_DISABLE_FAST_MODE`](/docs/en/env-vars) turns fast mode off for one session, and this key can't turn it back on

```json settings.json theme={null}
{
  "fastMode": true
}
```

### `fastModePerSessionOptIn`

Normally, running `/fast` saves [`fastMode`](#fastmode) to a person's user settings, so fast mode is on at the start of every later session. Set this key to `true` to stop that: a saved `fastMode: true` no longer turns fast mode on at session start, and each person has to run `/fast` in each session they want it. Claude Code leaves the `fastMode` key in their file, so turning this key off restores the old behavior.

Owners on Team or Enterprise plans can deploy it organization-wide through [server-managed settings](/docs/en/server-managed-settings). When managed settings set the key, `/fast on` is refused outside interactive terminal sessions and reports that your organization has disabled fast mode. That covers [non-interactive mode](/docs/en/headless), the [VS Code extension](/docs/en/vs-code), and [cloud sessions](/docs/en/claude-code-on-the-web).

* **Scope**: [`Any file`](#scopes)
* **Type**: Boolean
  * `true`: a saved `fastMode: true` no longer turns fast mode on at session start, so each person runs `/fast` in each session they want it; a `fastMode: true` passed with `--settings` still counts for that session unless managed settings set this key
  * `false`: a saved `fastMode: true` turns fast mode on at the start of every later session
* **Default**: `false`

```json settings.json theme={null}
{
  "fastModePerSessionOptIn": true
}
```

See [Require per-session opt-in](/docs/en/fast-mode#require-per-session-opt-in).

### `language`

Have Claude respond in a language other than English by default. There is no fixed list for responses: Claude Code passes the value verbatim to Claude as an instruction to always respond in that language, so any language name Claude can read works. Claude Code doesn't check the value, so a misspelled name reaches Claude as written rather than producing an error. The same value sets the language for [voice dictation](/docs/en/voice-dictation#change-the-dictation-language), which does have a fixed list of [supported dictation languages](/docs/en/voice-dictation#change-the-dictation-language), and for auto-generated session titles.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, any language name, such as `"japanese"`, `"spanish"`, or `"french"`; Claude Code doesn't validate it
* **Default**: unset; session titles then match the language of your conversation

```json settings.json theme={null}
{
  "language": "japanese"
}
```

### `maxEffortLevel`

Cap the [effort level](/docs/en/model-config#adjust-effort-level) a session can use, leaving lower levels available. Any higher level runs at the cap instead, including one from `/effort`, the `/model` picker, `--effort`, [`CLAUDE_CODE_EFFORT_LEVEL`](/docs/en/env-vars), a skill's or subagent's `effort` frontmatter, or the model's own default. Claude Code applies the cap itself before each request, so it holds on every provider, including Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry. Requires Claude Code v2.1.267 or later.

* **Scope**: [`Any file`](#scopes). Deploy it in managed settings to enforce it for an organization. When several scopes set a cap, the lowest applies, so a cap set in one scope can't be raised from another
* **Type**: string, one of `"low"`, `"medium"`, `"high"`, `"xhigh"`, or `"max"`. A `"max"` value sets no cap
* **Default**: unset, so no cap applies
* **Per-model caps**: add `maxEffortLevel` to a model's [`modelSettings`](#modelsettings) entry. That entry replaces this key for the model only within the settings source that sets both, such as your user settings or one [managed source](/docs/en/managed-settings#how-claude-code-combines-managed-sources). Set `"max"` there to exempt the model from that source's cap; Claude Code still applies caps from other sources

This example caps every model at `medium` and exempts Sonnet 4.6:

```json settings.json theme={null}
{
  "maxEffortLevel": "medium",
  "modelSettings": {
    "claude-sonnet-4-6": {
      "maxEffortLevel": "max"
    }
  }
}
```

When your organization also sets an [effort limit](/docs/en/model-config#organization-effort-limits) for a model, the lower of the two caps applies.

### `model`

Set the model every new session uses, so you don't have to pick one with `/model` each time. Setting it here doesn't stop you from switching mid-session. If your admin set an [organization default model](/docs/en/model-config#organization-default-model) to override user selection, you get that model even when you set this key in user, project, or local settings.

* **Scope**: [`Any file`](#scopes)
* **Type**: string, a model alias or full model ID
* **Default**: unset, so Claude Code uses your account's default model
* **Per-session overrides**: `--model` takes precedence over [`ANTHROPIC_MODEL`](/docs/en/env-vars), and both take precedence over this key for one session, including over a managed `model`; an [`availableModels`](#availablemodels) list still applies to the pick

```json settings.json theme={null}
{
  "model": "claude-sonnet-5"
}
```

A value here outranks [`ANTHROPIC_DEFAULT_MODEL`](/docs/en/model-config#set-a-default-model-for-new-sessions), which Claude Code uses only when nothing else selects a model.

### `modelOverrides`

Map Anthropic model IDs to provider-specific model IDs, such as Amazon Bedrock inference profile ARNs. Each model picker entry then uses its mapped value when calling the provider API. Administrators use this on [Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry](/docs/en/model-config#override-model-ids-per-version) to route each model version to a specific inference profile, version name, or deployment for governance, cost allocation, or regional routing.

* **Scope**: [`Any file`](#scopes)
* **Type**: object mapping model ID to provider model ID
* **Default**: unset

This example routes every call for Opus 4.6 to the named Bedrock inference profile:

```json settings.json theme={null}
{
  "modelOverrides": {
    "claude-opus-4-6": "arn:aws:bedrock:us-east-1:123456789012:inference-profile/example"
  }
}
```

See [Override model IDs per version](/docs/en/model-config#override-model-ids-per-version).

### `modelPicker`

List the models the `/model` picker offers, in the order you write them and under labels you choose, so the picker lists the models your organization runs, after the built-in lineup or instead of it. Each row's `model` is taken verbatim, so it accepts anything `--model` accepts: an alias such as `opus`, an Anthropic model ID, or a provider-format ID for Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, or an LLM gateway. Requires Claude Code v2.1.242 or later.

* **Scope**: [`User or managed`](#scopes). Claude Code reads the key from managed settings, `--settings`, and user settings, and ignores it in project and local settings so a repository you clone can't relabel the picker. The highest of those three that sets the key supplies the whole lineup, and Claude Code never combines lineups from two sources.
* **Type**: object with an `options` array of rows and an optional `replaceBuiltInOptions` Boolean
* **Default**: unset, so the picker shows the built-in lineup

This example adds two Bedrock deployments after the built-in lineup, under names your team recognizes:

```json managed-settings.json theme={null}
{
  "modelPicker": {
    "options": [
      { "model": "us.anthropic.claude-opus-4-8", "label": "Opus (production)" },
      {
        "model": "us.anthropic.claude-sonnet-4-6",
        "label": "Sonnet (production)",
        "description": "Day-to-day work"
      }
    ]
  }
}
```

<span id="modelpicker-options" />

<span id="modelpicker-replacebuiltinoptions" />

#### Fields for `modelPicker`

The key takes two fields, one for the rows themselves and one for whether they replace the built-in lineup or add to it.

| Field | Type | What it does |
| :- | :- | :- |
| `options` | array of rows, each with a required `model` and optional `label`, `description`, and `behavesAs` | The rows the picker shows, in this order, except that a grayed-out row moves to the bottom. Without a `label`, Claude Code titles the row with the built-in name for a model it knows, or the model ID otherwise, and without a `description` it writes a generic second line |
| `replaceBuiltInOptions` | Boolean, default `false` | Set it to `true` to show only these rows, **Default**, and a row for the model the session is already using. Leave it unset to add these rows after the built-in lineup |

An entry in `options` can also carry an optional `behavesAs` string beside its `model`, which requires v2.1.257 or later. Set it to the ID of a model your Claude Code version already knows, such as `claude-opus-4-8`, on an entry whose `model` is newer than your version. Claude Code then applies that known model's capabilities and effort defaults to the entry instead of treating its model as unknown. The entry's label and the model ID Claude Code sends in requests don't change.

With `replaceBuiltInOptions` on, Claude Code hides every other row: the built-in lineup, the rows it adds for [`availableModels`](#availablemodels) entries, the models [gateway discovery](/docs/en/llm-gateway-protocol#model-discovery) found, and [`ANTHROPIC_CUSTOM_MODEL_OPTION`](/docs/en/model-config#add-a-custom-model-option). With it off, Claude Code skips a listed model that the built-in lineup already covers. A label changes what the picker shows, not which model Claude Code runs.

An [`availableModels`](#availablemodels) allowlist still applies to these rows. Before you add a listed model to the allowlist, read [Merge behavior](/docs/en/model-config#merge-behavior): a specific model ID narrows its family's wildcard entry. Claude Code also checks each row against the session before it shows the picker:

* **Dropped**: a row Claude Code can't serve, such as a retired model or a model your organization has no access to
* **Grayed out**: a row you can't select yet, shown with the reason
* **No row survives**: Claude Code keeps the built-in lineup, filtered by the allowlist as usual

Claude Code drops a row it can't parse and keeps the rest. See [Fix a broken settings file](/docs/en/settings#fix-a-broken-settings-file).
