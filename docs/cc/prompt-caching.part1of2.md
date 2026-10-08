[Part 1/2 of https://code.claude.com/docs/en/prompt-caching.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# How Claude Code uses prompt caching

> Claude Code manages prompt caching automatically. See why a model switch triggers a slow uncached turn, what `/compact` costs, why CLAUDE.md edits don't apply mid-session, and how to check your cache hit rate.

Prompt caching makes Claude Code faster and more cost-efficient. Without caching, the API would reprocess your full history on every turn. With caching, it reuses what it already processed, bills the re-read at the [cached token rate](https://platform.claude.com/docs/en/about-claude/pricing), and fully processes only what changed.

Claude Code handles prompt caching for you, unless you [disable it](#disable-prompt-caching). It is still useful to know how prompt caching works, because some actions invalidate the cache and make the next response slower and more expensive while it rebuilds. This page covers which actions those are, why some settings wait for a restart to apply, and how to check cache performance when usage looks high.

## How the cache is organized

Each time you send a message in Claude Code, it makes a new API request. The model doesn't remember anything between requests, so Claude Code re-sends the full context: the system prompt, your project context, every prior message and tool result, and your new message. New content is appended at the end, which means most of each request is identical to the one before it. Prompt caching is how the API avoids reprocessing the part that didn't change.

The API caches by matching the start of each request, called the prefix, against content it recently processed. On a normal turn, the prefix is the entire previous request and only the latest exchange is new. The match is exact, so a change anywhere in the prefix recomputes everything after it. There is no per-file or per-segment caching. See [how prompt caching works](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#how-prompt-caching-works) in the API reference for the underlying mechanism.

<img src="https://mintcdn.com/claude-code/VbDJw--l6T9a9Wvm/images/prompt-caching-prefix.svg?fit=max&auto=format&n=VbDJw--l6T9a9Wvm&q=85&s=f2e8f0b8298a50305fe428ca3f1d1594" className="dark:hidden" alt="Four turns shown as growing horizontal bars. Each turn's request contains everything from the previous turn plus the latest exchange appended at the end. On turns two and three, the unchanged prefix is read from cache and only the new exchange is processed. On turn four, the system prompt changed, so the prefix no longer matches and the entire request is reprocessed and written." width="720" height="454" data-path="images/prompt-caching-prefix.svg" />

<img src="https://mintcdn.com/claude-code/_xqph1dUOslCOwsj/images/prompt-caching-prefix-dark.svg?fit=max&auto=format&n=_xqph1dUOslCOwsj&q=85&s=297dc1c639f0915cae858d0c4b6f3be5" className="hidden dark:block" alt="Four turns shown as growing horizontal bars. Each turn's request contains everything from the previous turn plus the latest exchange appended at the end. On turns two and three, the unchanged prefix is read from cache and only the new exchange is processed. On turn four, the system prompt changed, so the prefix no longer matches and the entire request is reprocessed and written." width="720" height="454" data-path="images/prompt-caching-prefix-dark.svg" />

To get the most out of prefix matching, Claude Code orders each request so content that rarely changes between turns comes first:

| Layer | Content | Changes when |
| - | - | - |
| System prompt | Core instructions, tool definitions | The set of loaded tool definitions changes |
| Project context | CLAUDE.md, auto memory, unscoped rules | Session starts, or after `/clear` or `/compact` |
| Conversation | Your messages, Claude's responses, tool results | Every turn |

A change to the conversation layer leaves the system prompt and project context cached. A change to the system prompt invalidates everything, because all later content now sits behind a different prefix. The third column gives common triggers rather than an exhaustive list, and the sections below cover the full set.

The prefix-match rule explains most of the behaviors on this page. [Plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode) and [skill loading](/docs/en/skills), for example, append their instructions as conversation messages, so the cached prefix stays intact.

Two settings don't appear in the layer table but still affect what stays cached:

* **Model**: each model has its own cache. Switching models recomputes the entire request even when the content is identical. See [Switching models](#switching-models) below.
* **Effort level**: on most models, each effort level has its own cache, so changing effort mid-session recomputes the entire request. On Opus 5.5, Sonnet 5.5, Haiku 5.5, and Fable 5.1 with an API key or a Claude subscription, the cache stays intact by default. See [Changing effort level](#changing-effort-level) below.

<Tip>
  Pick your model and effort level at the top of a session, then save `/compact` for natural breaks between tasks. The fewer changes you make mid-task, the higher your cache hit rate.
</Tip>

### Where the cache lives

Caching happens server-side, in whichever infrastructure serves your model. Where that is depends on how you authenticate:

* **API key, Claude subscription, or [Claude Platform on AWS](/docs/en/claude-platform-on-aws)**: the cache lives in Anthropic's infrastructure, accessed through the [Claude API](https://platform.claude.com/docs)
* **Amazon Bedrock or Google Cloud's Agent Platform**: the cache lives in your cloud provider's serving infrastructure
* **Microsoft Foundry**: depends on the deployment's [hosting option](https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry#hosting-options). Hosted on Azure deployments are served on Azure infrastructure; Hosted on Anthropic deployments are served on Anthropic's infrastructure
* **Custom `ANTHROPIC_BASE_URL` or [LLM gateway](/docs/en/llm-gateway)**: the cache lives wherever your requests are forwarded, and whether caching works depends on the gateway

Claude Code also appends system context mid-conversation, such as file-change notices, and marks that block for caching on every provider and connection unless you set [`CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`](/docs/en/llm-gateway-protocol#disable-pre-release-capabilities), in which case that block is sent uncached.

At the provider's own endpoint, Amazon Bedrock and its [Mantle endpoint](/docs/en/amazon-bedrock#use-the-mantle-endpoint), Google Cloud's Agent Platform, and Microsoft Foundry cache the block the same way the Claude API does.

When your requests pass through an [LLM gateway](/docs/en/llm-gateway), a custom `ANTHROPIC_BASE_URL`, or a cloud provider base-URL override such as [`ANTHROPIC_BEDROCK_BASE_URL`](/docs/en/env-vars), what stays cached depends on how the gateway handles the [`cache_control` markers](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#explicit-cache-breakpoints) Claude Code sends:

* **Forwards them unchanged**: the block and your conversation cache the same as at the provider's own endpoint.
* **Rejects the marked request with a `400` error naming `cache_control`**: Claude Code re-sends the request with the marker moved off the block and onto your last conversation message, and keeps it there for the rest of the conversation. The block bills as uncached input; your conversation stays cached.
* **Removes the markers while returning success**: your entire conversation history bills as uncached input on every turn. A gateway that converts block-form system content to a plain string drops the marker the same way.

For what each provider stores and processes, see [data usage](/docs/en/data-usage). Wherever the cache lives, entries expire after a period of inactivity, and [Cache lifetime](#cache-lifetime) below covers the TTL and how to extend it.

## Actions that invalidate the cache

These actions can cause the next request to miss part or all of the cache. You see a one-time slower, more expensive turn, after which the new prefix is cached. Most of them are avoidable mid-task once you know they have a cost. A model switch can feel free until you notice the slower turn that follows.

* [Switching models](#switching-models)
* [Changing effort level](#changing-effort-level)
* [Turning on fast mode](#turning-on-fast-mode)
* [Connecting or removing an MCP server](#connecting-or-removing-an-mcp-server)
* [Enabling or disabling a plugin](#enabling-or-disabling-a-plugin)
* [Denying an entire tool](#denying-an-entire-tool)
* [Compacting the conversation](#compacting-the-conversation)
* [Accumulating many images](#accumulating-many-images)
* [Upgrading Claude Code](#upgrading-claude-code)

### Switching models

Each model has its own cache. Switching with [`/model`](/docs/en/model-config#setting-your-model) means the next request reads the entire conversation history with no cache hits, even though the content is identical.

When you run `/model` at the terminal, Claude Code asks you to confirm the switch only while the cache is still warm and the new model isn't the one that produced the last response. The cache stays warm for one [cache TTL](#cache-lifetime) after Claude Code last sent a request in this conversation or Claude last responded. Once that time passes, the cache has expired, so Claude Code switches without asking.

Before v2.1.238, Claude Code didn't check the cache TTL and asked even after the cache had expired.

You can also require this confirmation or skip it with a [PreModelSwitch hook](/docs/en/hooks#premodelswitch-decision-control).

The [`opusplan` model setting](/docs/en/model-config#opusplan-model-setting) resolves to Opus during plan mode and Sonnet during execution, so each plan-mode toggle is a model switch and starts a fresh cache.

[Automatic model fallback](/docs/en/model-config#automatic-model-fallback) on Fable models, Opus 5.5, Sonnet 5.5, and Opus 5 is also a model switch. When a safety classifier flags a request in a category that has a fallback model, Claude Code re-runs the request on that model and the session continues there.

When a skill or command's frontmatter names a [`model`](/docs/en/skills#frontmatter-reference) other than the session's current model, that turn is also a model switch: the next request reads the entire conversation history with no cache hits. The session model resumes on your next prompt. A `context: fork` skill sets the [forked subagent's model](/docs/en/skills#run-skills-in-a-subagent) instead.

### Changing effort level

On most models, changing the [effort level](/docs/en/model-config#adjust-effort-level) mid-session means the next request reads the entire conversation history with no cache hits. While the cache is still warm, Claude Code asks you to confirm the change first.

On Opus 5.5, Sonnet 5.5, Haiku 5.5, and Fable 5.1 with an API key or a Claude subscription, changing effort keeps the cache, and Claude Code applies the new level without asking. This doesn't apply on Amazon Bedrock, Google Cloud's Agent Platform, or a [Claude apps gateway](/docs/en/claude-apps-gateway), or when you set [`CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`](/docs/en/llm-gateway-protocol#disable-pre-release-capabilities) or your organization has a HIPAA configuration.

Before v2.1.260, changing effort on Fable 5.1 with an API key or a Claude subscription also invalidated the cache.

### Turning on fast mode

Enabling [fast mode](/docs/en/fast-mode) adds a request header that is part of the cache key, so the first request Claude Code sends with fast mode on reads the entire conversation history with no cache hits. Claude Code sets that header once when a turn starts and keeps it for the whole turn, so when you turn fast mode on while Claude is working, the cache miss from the header happens on the first request of your next turn. Those uncached input tokens are billed at [fast mode rates](/docs/en/fast-mode#understand-the-cost-tradeoff), which is why turning it on at the start of a session costs less than turning it on deep into a long one. If your current model doesn't support fast mode, enabling fast mode also [switches your model](#switching-models), and that switch starts a fresh cache on its own from the next request in the running turn.

The cost applies once per conversation. After the first fast mode turn, Claude Code keeps sending the header and varies only the request's speed setting, which is not part of the cache key. Turning fast mode off, the [automatic fallback to standard speed](/docs/en/fast-mode#handle-rate-limits) after a rate limit, and turning it back on later all keep the cache. If you [run out of usage credits](/docs/en/fast-mode#handle-rate-limits) mid-session, Claude Code retries each rejected fast mode request at standard speed the same way, so this fallback also keeps the cache. `/clear` and `/compact` reset this, since they rebuild the cache at those points anyway.

### Connecting or removing an MCP server

Tool definitions sit in the system prompt layer, so the cache invalidates when the set of tool definitions in the request changes between turns. Toggling the [advisor tool](/docs/en/advisor) is an exception: its definition sits after the cache breakpoint, so enabling or disabling `/advisor` keeps the cached prefix intact. Whether an [MCP server](/docs/en/mcp) change does this depends on whether [tool search](/docs/en/mcp#scale-with-mcp-tool-search) defers the session's MCP tools, the default on supported models:

* **Tools deferred**: Claude Code keeps the tool list from the conversation's first request for the whole conversation, so a server connecting or disconnecting mid-session doesn't disturb anything already cached. A server that finishes connecting after the first request supplies its tools as deferred definitions that Claude loads on demand.
* **Tools loaded upfront**: adding a definition invalidates the cache, and so does removing one on purpose. This applies when tool search is [below its `auto` threshold, disabled, or unavailable](/docs/en/mcp#configure-tool-search), such as on Google Cloud's Agent Platform models earlier than the Claude 4.5 generation, with a custom `ANTHROPIC_BASE_URL` gateway, or on a Microsoft Foundry [deployment hosted on Azure](https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry#hosting-options) once Claude Code detects that the deployment rejects tool search.

Without tool search, whether a mid-session server change invalidates the cache depends on what changed. For each change, this table gives whether the cache is kept and what happens to the tool definitions in the next request.

| Mid-session change | Cache | Tool definitions in the next request |
| - | - | - |
| A server connects, or a [dynamic tool update](/docs/en/mcp#dynamic-tool-updates) adds tools | Invalidated | The new definitions are added |
| A server drops out with no action on your part, such as a stdio server's process exiting | Kept | The server's definitions stay unchanged. A call to one of its tools returns an error instead of running |
| A remote server [reconnects automatically](/docs/en/mcp#automatic-reconnection) after its connection drops | Kept, unless a request sent while the server reconnects adds the `WaitForMcpServers` tool, which invalidates the cache once | The server's definitions stay unchanged. A request sent while the server reconnects can add `WaitForMcpServers` when the conversation hasn't listed it yet, and the tool then stays listed for the rest of the conversation |
| You remove a tool on purpose, such as with a [deny rule](#denying-an-entire-tool) or by disabling its server in `/mcp` | Invalidated | The definition is removed |

When you resume a conversation whose tools load into the prefix, one of its MCP servers can still be connecting as the first request goes out. If the transcript recorded that server's tool definitions, that request includes them as recorded, so it doesn't change when the server finishes connecting with the same tools.

Editing your MCP config does not by itself change the cache. The new config takes effect only after a restart, which is when the server connects or disconnects.

### Enabling or disabling a plugin

When you enable or disable a [plugin](/docs/en/plugins/overview), what the change costs depends on which component types the plugin provides. The cases below cover each component type, when Claude Code applies the change, and what happens when you disable a plugin again in the same session.

#### Plugin components that keep the cache

Claude Code never invalidates the cache for a plugin's skills, commands, agents, hooks, monitors, or themes. It appends their content after the existing conversation, so the next request pays for that content and still reads everything before it from the cache.

#### Plugins that provide MCP servers

When you enable or disable a plugin that provides [MCP servers](/docs/en/plugins/components#mcp-servers), Claude Code follows the same rules as when you [connect or remove an MCP server](#connecting-or-removing-an-mcp-server).

#### Code intelligence plugins

When you enable a [code intelligence plugin](/docs/en/plugins/code-intelligence), Claude gets the [LSP tool](/docs/en/tools-reference#lsp-tool-behavior).

#### When plugin changes apply

A change you make in the `/plugin` menu goes through [`/reload-plugins`](/docs/en/plugins/cli-reference#reload-plugins), which Claude Code runs for you when you close the menu. You pay the cost, whether appended announcements or a full re-read, on the first turn after the change applies. Claude Code can also apply a change on its own:

* For a plugin with a `command` source, Claude Code [can reload the plugin itself](/docs/en/plugins/loading#when-a-command-source-re-runs).
* When you [install a plugin from the `/plugin` interface](/docs/en/plugins/install#install-a-plugin), Claude Code can activate it during the install. The install summary tells you whether it did.
* When you [move the session with `/cd`](/docs/en/permissions#move-the-session-to-another-directory) on v2.1.246 or later, Claude Code applies the plugins the new directory's settings enable as part of the move, without the full re-read warning that holds a `/reload-plugins`.
* In interactive sessions, when you add or remove a plugin in a [folder of plugins](/docs/en/plugins/create#load-a-directory-or-archive-for-one-session) you passed with `--plugin-dir`, the change applies right away. If applying it would trigger a full re-read, Claude Code holds the change instead and shows a notice to run `/reload-plugins`. Requires Claude Code v2.1.265 or later.

When `/reload-plugins` runs and the reload would trigger a full re-read, Claude Code shows a warning and doesn't apply the reload. Run `/reload-plugins --force` to apply it anyway.

`/reload-plugins` also runs in sessions without an interactive terminal, such as the desktop app, the Agent SDK, and [non-interactive mode](/docs/en/headless) with `-p`, when you type it into the session directly. Requires Claude Code v2.1.260 or later.

In those sessions the reload applies everything except plugin MCP server changes, which [take effect in your next session](/docs/en/plugins/cli-reference#reload-plugins) and so never cost a full re-read mid-session.

#### Plugins you enable and then disable in one session

When you disable a plugin you enabled earlier in the session, Claude Code restores the previous request shape. If that prefix is still within its [cache lifetime](#cache-lifetime), the next request reads the older cache entry instead of rebuilding.

### Denying an entire tool

If you add a bare tool name like `Bash` or `WebFetch` as a [deny rule](/docs/en/permissions#manage-permissions), Claude can't call that tool from your next request on, whether you add the rule through `/permissions` or by [editing a settings file directly](/docs/en/settings#when-edits-take-effect). That includes a rule you add through `/permissions` in the middle of a turn.

When [tool search](/docs/en/mcp#scale-with-mcp-tool-search) is active, which is the default on supported models, the request's tool definitions don't change and the cached prefix survives. When tool search is unavailable or disabled, Claude Code removes the definition from the next request, which invalidates the cache, and so does removing the rule later.

Only a deny rule that matches in the tool-name position blocks a tool this way: a bare tool name, the equivalent `Bash(*)` form, or a [tool-name glob](/docs/en/permissions#tool-name-wildcards) like `"*"`. A glob that matches only MCP tools, such as `"mcp__*"`, blocks those tools the same way. Scoped deny rules like `Bash(rm *)`, and all allow and ask rules, don't change which tools Claude sees. Claude Code checks them when Claude attempts a call, leaving the prefix intact.

### Compacting the conversation

[Compaction](/docs/en/context-window#what-survives-compaction) replaces your message history with a summary. By design, this invalidates the conversation layer, since the next request has a new, shorter history that doesn't share a prefix with the old one. Claude Code reuses the system prompt layer unless the conversation was [resumed while keeping a system prompt that would otherwise have changed](#resuming-a-session); in that case the first compaction switches to the current prompt and that layer rebuilds once. It reloads project context from disk, which cache-hits only if CLAUDE.md and memory are unchanged since the session started.

To produce the summary, Claude Code sends a separate request with the same system prompt, tools, and history as your conversation, plus a summarization instruction appended as a final user message. While the cache is warm, that request reads your prefix from the cache, so a mid-session `/compact` costs a fraction of what the context size suggests and spends most of its time generating the summary.

After a break longer than the [cache lifetime](#cache-lifetime), there is no cache left to read, so the summarization request reprocesses the full history as uncached input. This is why `/compact` costs the most when you [resume an old session](/docs/en/sessions#resume-from-a-summary). In both the warm and cold cases, the turn after compaction rebuilds the conversation cache for only the much shorter summary, so that turn is not the slow part.

<Tip>
  Compaction works in your favor when the context you discard is content you no longer need. To choose when its overhead happens, run `/compact` at a natural break in your work, such as between tasks, instead of waiting for auto-compaction to trigger mid-task. If you've gone down a path you want to abandon entirely, [`/rewind`](#rewinding-the-conversation) to an earlier turn instead. Rewinding truncates back to a prefix that is already cached, rather than building a new one as compaction does.
</Tip>
