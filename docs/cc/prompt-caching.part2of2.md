[Part 2/2 of https://code.claude.com/docs/en/prompt-caching.md, fetched 2026-10-08]

### Accumulating many images

The API limits how many images and PDFs each request can carry. For the current numbers, see [Request limits](https://platform.claude.com/docs/en/build-with-claude/vision#request-limits) in the API docs. Claude Code also caps the total size of the images and PDFs in a request, so large screenshots reach the limit with fewer images than small ones.

When the next request would pass either limit, Claude Code removes a batch of the oldest images and PDFs from what it sends, which leaves room for more before it needs to remove any again. Claude can no longer see the removed images. If Claude needs one of them again, share it again.

Removing images changes the messages that held them, so the next request reprocesses the conversation from the earliest of those messages onward. Because Claude Code removes a batch at a time, you see one slower turn per batch rather than one with each new screenshot.

### Upgrading Claude Code

A new Claude Code version typically updates the system prompt or tool definitions, so the first conversation you start after an upgrade builds its cache from the top. [Auto-update](/docs/en/setup#auto-updates) downloads new versions in the background but applies them on the next launch, never mid-session, so you see this as an uncached first turn after restarting rather than a surprise during a session. Set `DISABLE_AUTOUPDATER=1` to control when upgrades apply.

<Note>
  For what it costs to resume a conversation you started before the upgrade, see [Resuming a session](#resuming-a-session).
</Note>

## Actions that keep the cache

These actions either append to the end of the conversation or don't touch the request at all. Some of them, such as editing CLAUDE.md, keep the cache for the same reason the change doesn't reach the running session until `/clear`, `/compact`, or a restart.

* [Editing files in your repository](#editing-files-in-your-repository)
* [Editing CLAUDE.md mid-session](#editing-claude-md-mid-session)
* [Changing permission mode](#changing-permission-mode)
* [Changing output style](#changing-output-style)
* [Invoking skills and commands](#invoking-skills-and-commands)
* [Running `/recap`](#running-%2Frecap)
* [Rewinding the conversation](#rewinding-the-conversation)
* [Spawning a subagent](#subagents-and-the-cache)

### Editing files in your repository

File contents enter context only when Claude reads them, and reads append to the conversation. Editing a file Claude previously read does not retroactively change the earlier read in history. Instead, Claude Code appends a [`<system-reminder>`](/docs/en/glossary#system-reminder) noting the file changed, and Claude re-reads it if needed.

### Editing CLAUDE.md mid-session

Your project-root and user-level CLAUDE.md files are read once at session start and held in memory. Editing them mid-session does not invalidate the cache, but the edit also doesn't apply. Claude keeps working with the version that was loaded at session start. The new content loads on the next `/clear`, `/compact`, or restart.

[Nested CLAUDE.md files in subdirectories](/docs/en/memory) and [rules with `paths:` frontmatter](/docs/en/memory#path-specific-rules) load later, on demand. Editing one yourself before it loads does take effect. After it loads, the content is part of the conversation history, so a mid-session edit doesn't retroactively change it.

### Changing permission mode

Switching between [permission modes](/docs/en/permission-modes), such as from Manual to accept edits, does not change the system prompt or tool definitions, so mode changes are cache-safe. The exception is plan mode with the [`opusplan`](/docs/en/model-config#opusplan-model-setting) model setting, which switches the model between Opus and Sonnet as you enter or leave plan mode. That makes the mode toggle a [model switch](#switching-models).

### Changing output style

When you switch [output styles](/docs/en/output-styles) mid-session with [`/output-style`](/docs/en/output-styles#change-your-output-style), `/config`, or the `outputStyle` setting, Claude uses the new style starting with your next message. Claude Code delivers the new style's instructions as a message in the conversation, so that request still reads the system prompt and the earlier conversation from the cache.

Before v2.1.251, a mid-session style switch kept the cache but didn't apply until you ran `/clear` or started a new session.

### Invoking skills and commands

[Skills](/docs/en/skills) and [commands](/docs/en/commands) inject their instructions as user messages at the point of invocation. Nothing earlier in the conversation changes. A skill or command whose frontmatter names a `model` can be a [model switch](#switching-models) for that turn.

### Running `/recap`

[`/recap`](/docs/en/interactive-mode#session-recap) generates a summary for display in your terminal. Unlike `/compact`, it appends the summary as command output rather than replacing your message history, so the cached prefix stays intact.

### Rewinding the conversation

[`/rewind`](/docs/en/checkpointing) truncates your conversation back to an earlier turn. The remaining history is the same content the cache was built from at that point, and the system prompt and project context layers are unchanged, so the next request hits the earlier cache entry. Every turn since then has read through that prefix, which kept the entry warm even if the original turn was longer ago than the TTL.

Restoring file checkpoints alongside the conversation has no separate effect on the cache. File contents enter context only when Claude reads them, the same as [editing files in your repository](#editing-files-in-your-repository).

## Resuming a session

When you [resume a session](/docs/en/sessions#resume-a-session), Claude Code sends the whole conversation again, and the request reads from the cache whatever part of its prefix is unchanged and still within the [cache lifetime](#cache-lifetime). The layer table at the top of this page says what changes each layer.

The system prompt would change after a [Claude Code upgrade](#upgrading-claude-code) or with different [`--append-system-prompt`](/docs/en/cli-reference#system-prompt-flags) text on the resume. By default, the resumed conversation keeps the system prompt it started with, so its history still sits behind the same prompt, and the change takes effect once the conversation is compacted or in a new conversation. [System prompt flags in resumed conversations](/docs/en/cli-reference#system-prompt-flags-in-resumed-conversations) covers the cases where Claude Code rebuilds the prompt on every request instead.

## Cache lifetime

Cached prefixes expire after a period of inactivity. Each request that hits the cache resets the timer, so the cache stays warm as long as you keep working. After a long enough gap, the next request recomputes the full input and re-establishes the cache, which is why the first turn back after stepping away can be noticeably slower.

On a Pro or Max plan, when you resume a large session after a long break, Claude Code [offers to resume from a summary](/docs/en/sessions#resume-from-a-summary) so later requests don't carry the full history.

The time to live (TTL) controls how long a gap the cache survives. The API offers two: a five-minute TTL, and a [one-hour TTL](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#1-hour-cache-duration) that keeps the cache warm through longer breaks but [charges a higher rate for cache writes](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#pricing). The longer TTL helps when you leave a session idle and come back to it, because you skip the reprocessing an expired prefix costs. It costs more on short bursts of work that never idle past five minutes, where the higher write rate applies and the longer cache lifetime goes unused.

### Which TTL each request gets

Claude Code decides the TTL per request, and every request falls in one of two fixed buckets:

* **Main conversation**: your interactive turns, non-interactive `-p` runs, and Agent SDK turns, plus the helpers Claude Code runs inline with them
* **Everything else**: the requests Claude Code makes outside that conversation, such as [subagents](/docs/en/sub-agents), [workflows](/docs/en/workflows), in-process [teammates](/docs/en/agent-teams), forks, compaction, and session titles

Unless you choose a TTL yourself, Claude Code requests the one-hour TTL only on a Claude subscription within your plan's included usage. There it requests the hour for the main conversation, plus a small set of helper requests that Anthropic controls server-side. This table gives each bucket's default TTL under both kinds of billing.

| Request bucket | Claude subscription, within plan usage | Usage credits, API key, or cloud provider |
| - | - | - |
| Main conversation | One hour | Five minutes |
| Everything else | Five minutes, except the server-controlled helper requests, which get one hour | Five minutes |

Once you go over your plan's usage limit and Claude Code draws on [usage credits](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans), you are billed for that usage, so Claude Code drops the main conversation to the five-minute TTL, which charges a lower rate for cache writes. To keep the one-hour TTL there, [choose the TTL yourself](#choose-the-ttl-yourself).

### Choose the TTL yourself

You can set a TTL for either bucket. Each control takes `5m` or `1h`, and Claude Code ignores any other value.

* **Main conversation**: the [`promptCacheTtl`](/docs/en/settings-reference#promptcachettl) setting, or the `CLAUDE_CODE_PROMPT_CACHE_TTL` [environment variable](/docs/en/env-vars)
* **Everything else**: the [`subagentPromptCacheTtl`](/docs/en/settings-reference#subagentpromptcachettl) setting, or the `CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL` environment variable

Both settings and both environment variables require Claude Code v2.1.242 or later. If you sign in with an API key or use a cloud provider, set `promptCacheTtl` to `1h` to give the main conversation a one-hour cache. Requests outside it keep the five-minute default until you choose a TTL for that bucket too.

When more than one control applies, Claude Code takes the first match in this order:

1. `FORCE_PROMPT_CACHING_5M=1`, which forces five minutes for both buckets
2. The bucket's environment variable
3. The bucket's setting
4. For a subagent's requests, the `cacheTtl` value in the subagent's [`experimental` frontmatter field](/docs/en/sub-agents#supported-frontmatter-fields), which requires Claude Code v2.1.248 or later. Claude Code ignores a `1h` there while your Claude subscription is using usage credits
5. `ENABLE_PROMPT_CACHING_1H=1`, which requests one hour for both buckets
6. The [default for the request's bucket](#which-ttl-each-request-gets)

Set `FORCE_PROMPT_CACHING_5M=1` when you're debugging cache behavior, comparing the two TTLs, or overriding a longer TTL set in [managed settings](/docs/en/managed-settings).

To confirm which TTL your main conversation's cache writes used, run `claude -p "hello" --output-format json` and read `usage.cache_creation` in the result. Claude Code reports one-hour cache writes under `ephemeral_1h_input_tokens` and five-minute cache writes under `ephemeral_5m_input_tokens`.

Through an LLM gateway you set with `ANTHROPIC_BASE_URL`, part of the one-hour request travels in the `anthropic-beta` header, so configure the gateway to [forward that header unchanged](/docs/en/llm-gateway-protocol#request-headers). The one-hour TTL isn't available through the [Claude apps gateway](/docs/en/claude-apps-gateway#availability-and-limitations). On Amazon Bedrock, prompt caching support, minimum cacheable prefix length, and one-hour TTL availability all vary by model. If cache token counts stay at zero, check [supported models, regions, and limits](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-caching.html#prompt-caching-models) in the Amazon Bedrock documentation.

## Cache scope

In Claude Code, the cache is effectively scoped to one machine and directory. The system prompt embeds your auto memory paths, and the conversation opens with an announcement of the working directory, platform, shell, and OS version. Two sessions in different directories therefore build different prefixes and miss each other's cache.

Sessions you run in parallel in the same directory build matching prefixes and read each other's cache. Sequential sessions share the prefix only when the git status snapshot taken at startup matches, since each conversation also carries the branch and recent commits from that snapshot.

The underlying API cache is broader. Caches are isolated between organizations, and on some providers, [between workspaces within an organization](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#cache-storage-and-sharing). Within those boundaries, any two requests with the same model and prefix read the same cache. For Agent SDK callers running fleets of automated processes, see [improve prompt caching across users and machines](/docs/en/agent-sdk/modifying-system-prompts#improve-prompt-caching-across-users-and-machines) to move the auto memory location out of the system prompt and share the system prompt's cache entry across users and machines.

## Check cache performance

Cache performance shows up as two token counts the API reports on every response. The most direct way to watch them live is a [statusline script](/docs/en/statusline) that reads the `current_usage` object:

| Field | Meaning |
| - | - |
| `cache_creation_input_tokens` | Tokens written to the cache on this turn, billed at the cache write rate |
| `cache_read_input_tokens` | Tokens served from cache on this turn, billed at the model's [cached token rate](https://platform.claude.com/docs/en/about-claude/pricing), below the standard input rate |

A high read-to-creation ratio means caching is working well. If creation stays high turn after turn, something is changing in your prefix. The [actions that invalidate the cache](#actions-that-invalidate-the-cache) section lists the usual causes.

For a per-session summary, run `/usage`. After the main conversation's first response, Claude Code adds a [`Prompt cache (main)` line](/docs/en/costs#prompt-cache-statistics) to the Session block, showing the session's hit ratio, miss count, and whether the cache is warm right now. A status line script can read the same numbers from the [`prompt_cache` object](/docs/en/statusline#prompt-cache-fields). Both require Claude Code v2.1.251 or later.

The `Prompt cache (main)` line also names the likely cause of the last miss when Claude Code can identify one, for example `likely cause: tool definitions changed`. The likely-cause text requires Claude Code v2.1.260 or later.

For visibility across an organization, the OpenTelemetry exporter reports cache read and creation tokens per user and session. See [Monitor usage](/docs/en/monitoring-usage) for the metric and event attribute reference.

## Subagents and the cache

A [subagent](/docs/en/sub-agents) starts its own conversation with its own system prompt and tool set, separate from the parent's. Its first request doesn't read the parent's cache, because the two prefixes differ, and it warms a cache of its own across its turns. Subagents fall outside the main-conversation [TTL bucket](#which-ttl-each-request-gets), so they get five minutes even on a subscription until you [choose a longer one](#choose-the-ttl-yourself).

The parent's cache is unaffected. From the parent's side, the subagent's call and result append to the conversation, leaving the parent's prefix intact.

A [fork](/docs/en/sub-agents#fork-the-current-conversation), by contrast, inherits the parent's system prompt, tools, and conversation history exactly, so its first request reads the parent's cache.

Other requests can also read a prefix that an earlier request cached:

* **Session copies**: a session you [copy with `/fork`](/docs/en/agent-view#copy-the-session-with-%2Ffork) receives its isolation instruction as a message at the end of the copied conversation, so the cache that the original conversation built stays intact.
* **Compaction**: the summarization call described in [Compacting the conversation](#compacting-the-conversation) uses the same prefix-sharing approach.
* **Resumed subagents**: when Claude [resumes a subagent](/docs/en/sub-agents#resume-subagents), the resumed run's first request can read the cache the original run warmed.
* **Workflow fan-outs**: in a [workflow fan-out](/docs/en/workflows#prompt-caching-in-a-fan-out) of same-prefix agents, Claude Code holds all but the first for up to 5 seconds by default, so their first requests can read the prefix that the first agent cached.

## Disable prompt caching

Disabling caching is occasionally useful when debugging caching behavior with a specific model or provider. To turn it off, set one of these environment variables to `1`:

| Variable | Effect |
| - | - |
| `DISABLE_PROMPT_CACHING` | Disable for all models |
| `DISABLE_PROMPT_CACHING_HAIKU` | Disable for the default Haiku model |
| `DISABLE_PROMPT_CACHING_SONNET` | Disable for the default Sonnet model |
| `DISABLE_PROMPT_CACHING_OPUS` | Disable for the default Opus model |
| `DISABLE_PROMPT_CACHING_FABLE` | Disable for Fable only |

`DISABLE_PROMPT_CACHING_HAIKU` applies to the default Haiku model, the model the `haiku` alias resolves to. It disables caching wherever that model runs, including the main conversation when it is your main model. Covering the main conversation requires Claude Code v2.1.283 or later.

The variable also covers a background model you set with the deprecated `ANTHROPIC_SMALL_FAST_MODEL` variable, when that model differs from your main model.

A different Haiku version that you pin as your main model keeps caching; set `DISABLE_PROMPT_CACHING` to disable caching for it.

`DISABLE_PROMPT_CACHING_SONNET` and `DISABLE_PROMPT_CACHING_OPUS` each apply to the model the `sonnet` or `opus` alias resolves to. If you set any other Sonnet or Opus model ID as your main model, that model keeps caching. For example, a session on `claude-sonnet-5` keeps caching while `sonnet` resolves to `claude-sonnet-5-5`. To disable caching for that model, set `DISABLE_PROMPT_CACHING`.

To set caching policy across an organization, put any of these or the [TTL variables](#cache-lifetime) in the `env` block of [managed settings](/docs/en/managed-settings). For normal use, leave caching enabled.

## Related resources

* [Lessons from building Claude Code: Prompt caching is everything](https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything): the design rationale for plan mode, deferred tool loading, and compaction
* [Explore the context window](/docs/en/context-window): what loads into context and when
* [Reduce token usage](/docs/en/costs#reduce-token-usage): strategies beyond caching for managing context size
* [Track and reduce costs](/docs/en/agent-sdk/cost-tracking): cache token tracking and TTL configuration for Agent SDK callers
* [Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching): the underlying API mechanism, breakpoints, and pricing
