# How Claude and Claude Code work — verified facts

As of 2026-10-03/04 · Claude Code 2.1.289 · research model `claude-opus-5-5` (1M window) · Linux cloud container, 4 vCPU.

**Size budget of this file: ≤ 40 KB and ≤ 22,500 Read-counter tokens** — one Read (limit 25,000 tokens, §1) with ~10% margin. File state: 38,565 B, 17,754 tokens of content [MEASURED: Read counter on the file repeated 3×, (53,269 − 7)/3, 2026-10-06]. Polish original: 40,050 B, 21,873 tokens [MEASURED: Read counter, (43,753 − 7)/2, 2026-10-06].

**Session reading budget** [ASSUMPTION with calculation]: files read in full together ≤ 200k tokens, each ≤ 25k, rest in fragments or via agents; after start (~76k) and the 200k full-read budget, ~508k remains to the cloud compaction threshold (~784k, §1). Peaks: workflow agents 98–300k (single-topic agents 164–228, overall-assessment agent 300), main window 488k after ~5 h, no compaction (from 01:46Z the window transcript also has entries of nested `claude -p`, U5-31) [MEASURED: peak column of workflow cost summary; window transcript usage, 2026-10-04].

Tags: [SOURCE: URL, date] · [MEASURED: command → result, date] · [CODE: location in 2.1.289 binary] · [ASSUMPTION] = inference or calculation; no date = 2026-10-03. URL abbreviations: CC = code.claude.com/docs/en/, PL = platform.claude.com/docs/en/ (PL = platform, not Polish), AN = anthropic.com/, CE = CC cloud-environments.md. ID (e.g. T1b-04) = finding with quote and evidence in the research report; outside that report, the evidence is the adjacent tag. "ibid." = source as above.


## 1. Context and the Read tool
- 1M window in API: Opus 4.6+, Sonnet 4.6+, Fable, Mythos; others (e.g. Sonnet 4.5, Haiku 4.5) 200K; output up to 128K [SOURCE: PL build-with-claude/context-windows], Haiku 4.5 64K [SOURCE: PL models/overview] (T1a-01, T1a-02). In Claude Code 1M without variant: Opus 4.7+, Sonnet 5+, Fable; Opus/Sonnet 4.6 only via [1m] [SOURCE: CC model-config.md] (T1a-03, T1a-04). Subagent window = its model's window [SOURCE: CC sub-agents.md] (T1a-09).
- Everything counts toward the window, also cached prefix and thinking of previous turns; context awareness per the page: Sonnet 5/4.6/4.5 and Haiku 4.5, Opus 5.5 not on the list [SOURCE: PL context-windows] (T1a-26, T1a-27); [ASSUMPTION] do not assume Opus 5.5 knows the remaining window (T1a-28).
- Cloud session start 75.6k tok.: 22 tools ≈26.9k (counted as JSON, approximation), instruction file 31.6 KB 16.2, system prompt 12.2, invoked skill 6.2, list of 30 skills (15,730 chars) 5.8, message 8 KB 3.9 [MEASURED: Read counter on start texts -> coverage 97.4%, 2026-10-04] (U1-01, U1-02, U1-03, U1-23).
- Invoked skill enters as a user message [MEASURED: start transcript] (T1a-S-05). MCP deferred by default: at start tool names and server instructions; exceptions: alwaysLoad, ENABLE_TOOL_SEARCH [SOURCE: CC how-claude-code-works.md, mcp.md, 2026-10-04] (T1a-12); subagents and workflow agents had MCP with full schema [MEASURED: prompt_snapshot of transcripts, 2026-10-04] (U1-S-02, T2a-S-02).
- Skill list: budget = window × chars/token (3 for Opus 5.5, 4 for older) × 1% = 30,000 chars at 1M, entry up to 1,536 chars; overflow: descriptions of least-used ones vanish [SOURCE: CC skills.md] [CODE: skill_listing] (T2a-20, U1-22, U1-24).
- `claude -p "/context" --output-format json` counts categories for 0 USD, but without the cloud session section [MEASURED: -> num_turns 0, 2026-10-04] (U1-06).
- Autocompact threshold = min(W×PCT, W−13,000), W = window − 20,000: 1M → 967K [CODE: threshold]; cloud sets PCT itself [SOURCE: CC claude-code-on-the-web.md] (here 80 [MEASURED: env] → ~784K) (T1a-39, T1a-S-01, T1a-37); window may come from server [SOURCE: CC changelog 2.1.288]; /context in -p shows 33k buffer [MEASURED: claude -p /context]; [ASSUMPTION] whether 784K applies – unresolved (T1a-40, T1a-S-09, U1-08).
- Restored after compaction: system prompt, root CLAUDE.md, auto memory, plan, invoked skills truncated to 5,000 tok. (25,000 total, beginning kept), up to 5 files read or edited, most recently modified (>5,000 tok. path only); skill list not restored, hook context and detailed early instructions only in summary, paths rules and nested CLAUDE.md on reading a matching file [SOURCE: CC context-window.md] (T1a-42..T1a-47, T1a-35, T2a-16).
- After several rapid refills autocompaction stops with an error [SOURCE: CC how-claude-code-works.md], in code 3 [CODE: sTt=3] (T1a-50); /compact is a large request [SOURCE: CC costs.md] (T1a-51).
- `<total_tokens>` is a client reminder: default 15M per agent (server or env var changes it), used = current context + collapsed by compaction − anchor; not window nor cost [CODE: totalTokensReminder] (U1-09, U1-10) [MEASURED: 15M − counter ≈ input of last call, 2026-10-04] (U1-11).
- Read: 25,000 tok. per call, file 256 KB [CODE: Read limits]; docs don't state them (T1b-02); change: CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS [SOURCE: CC env-vars.md] (T1b-03).
  - whole file >25k tok. and ≤256 KB → PARTIAL view ~85% of limit [CODE: PARTIAL view] (219 of 782 lines [MEASURED: Read]; T1b-08, T5-18); such a read doesn't count before Edit [SOURCE: CC tools-reference.md] (T1b-15).
  - file >256 KB without limit (also with offset alone) → hard error [MEASURED: Read 324 KB -> exceeds 256KB] (T1b-04, T1b-05).
  - with limit: 256 KB doesn't apply; range >25k tok. → error with count, >3.2M B → error [MEASURED: Read 3.0/3.77 MB] (T1b-06, T1b-07, T1b-S-02).
  - no cut at 2000 lines contrary to tool description; 12,018-char line whole [MEASURED: 2026-10-03] (T1b-11, T1b-12, T1b-10).
  - prefix "N\t" = ~2.1 tok./line (+2.2-2.8% of Polish md, depending on line length); trailing \n gives empty line [MEASURED: 2026-10-04] (U1-20, U1-21, U1-19).
- Counter in Read error = countTokens of content without line numbers: overhead 7, additive, matches usage within 3 tok.; cheap: offset=1 + limit > line count, short text after filler >25k [MEASURED: 2026-10-03/04] (T1b-20, T1b-21, T1b-22, T1b-28, T1b-S-01, U1-04).
- B/token (Opus 5.5): Polish md 1.83-2.13 (lower bound: Polish original of this file), Lua 2.00-2.16 (only measured samples, spread depends on file), JSON 1.80-2.33, English md 2.66-2.78, short lines with numbers 1.55 [MEASURED: Read counter, 2026-10-03/04] (T1b-23..T1b-27, T1b-32); tokenizer 4.7+ gives ~30% more – measure per model [SOURCE: PL build-with-claude/token-counting] (T1b-29).
- Without counter: chars/3.2 underestimates (pl md 38-46%, Lua 33-37%, en 13-17%), bytes/4 by 30-55%, bytes/1.94: pl md ±7%, Lua up to +11%, en +37-43% [MEASURED: formulas vs Read counter] (T1b-40, T1b-41, T1b-43).
- Quality: degrades gradually with fill (context rot), no numeric threshold [SOURCE: PL context-windows] (T1a-54, T1a-55); long CLAUDE.md: §2 (T1a-57, T1a-61). Per Opus 5 prompting page quality constant across whole 1M [SOURCE: PL …/prompting-claude-opus-5] (T5-S-01); Opus 5.5 pages silent [SOURCE: grep of pages, 2026-10-04] (U1-25).
- Example [ASSUMPTION with calculation]: start without skill ≈ 69k + files read in full (~48 KB Polish md) ≈ 96k; to 784K ~688k remains (T1a-63). With 40 KB knowledge file start ≈ 119k = 12% of window (T1a-65).

## 2. Instructions, memory, skills, visibility

- CLAUDE.md: managed, user, project, local; from working dir and parents, concatenated from root down [SOURCE: CC memory.md] (T2a-08, T2a-09)
- Subdirectory CLAUDE.md enters in full on Read of a file from it (since 2.1.288 also Write/Edit); .ignore doesn't block [MEASURED: Read of 2 lines → nested_memory 18.5 KB] (T2a-10, T2a-11, T2a-S-04)
- @ imports and .claude/rules without paths load at start, don't save context; recommended <200 lines, longer file lowers adherence; hard block: §6 [SOURCE: CC memory.md] (T2a-12, T2a-13, T2a-14, T2a-15)
- Instruction file 31.6 KB = 16,094 tokens; agent start with it costlier by 16.2-16.6k (upper bound) [MEASURED: claude -p with/without CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 → 33,175 / 49,392; Read counter, 2026-10-04] (T1a-S-03, U2-29, T2a-04, U1-16, U1-17)
- Editing CLAUDE.md in session has no effect until /compact, /clear or restart; no /clear in cloud [SOURCE: CC prompt-caching.md, claude-code-on-the-web.md, 2026-10-04] (U2-01, U2-S-05)
  - new subagents, workflow agents and auto classifier have the start version [CODE: userContext once per session] [MEASURED: file added in session → absent for new agent, 2026-10-04] (U2-03..06)
  - nested one edited before its first load works [SOURCE: CC prompt-caching.md, 2026-10-04] (U2-02)
- Skills: always present only descriptions, content on invocation; subagent's skills field injects content at start [SOURCE: CC skills.md] (T2a-19)
- Invoked skill stays in conversation, file not re-read [SOURCE: CC skills.md]; list not restored after compaction (§1) (T2a-24)
- Claude Code detects SKILL.md changes in current session (except bare mode), but an already invoked skill must be invoked again; new top-level skills directory requires /reload-skills after each change [SOURCE: CC skills.md, 2026-10-04] (U3-01, U3-02)
- Cloud: claude.ai account skills and repo .claude/skills; no ~/.claude/skills from PC nor plugins from repo settings [SOURCE: CC skills.md] (T2a-22)
- Output style goes with every request, custom one removes engineering instructions (unless keep-coding-instructions); main conversation and fork only [SOURCE: CC output-styles.md] (T2a-29)
- Auto memory: MEMORY.md (200 lines / 25 KB) at start, local to machine [SOURCE: CC memory.md]; absent in cloud session [MEASURED: no directory nor prompt section] (T2a-31, T2a-32)
- Person's claude.ai preferences (<user_preferences>) only in main window prompt, in no agent; not in docs [MEASURED: prompt_snapshot of transcripts] (T2a-03)
- At start: CLAUDE.md / preferences / parent conversation / Edit-Write / tokens of 1st call (1.3 KB probe); all have the skill list [MEASURED: usage and attachments of transcripts] (T2a-02..07, T2b-70, T1a-21, T1a-22):
  - main window: yes / yes / - / yes / 75.6k
  - general-purpose: yes / no / no / yes / 58.7k
  - workflow agent: yes / no / task only / yes / ~61.7k + 0.49 tok. per task byte (measured 65–97k, longest task 177k) (T1a-S-08, T3-29)
  - custom with omitClaudeMd: no / no / no / per definition / 42.0k
  - Explore: no / no / no / no / 30.8k
- Agents (except fork) always lose e.g. AskUserQuestion, Workflow, EnterPlanMode, ScheduleWakeup (won't ask the owner), Agent at depth limit; background agent has only a subset of built-ins (Read, Grep, Bash, Edit, Write…) and all MCP (Edit/Write ban: §4) [SOURCE: CC sub-agents.md, 2026-10-04] (T2a-S-01, T2a-S-02, T3-45, T3-46)
- No CLAUDE.md: omitClaudeMd, Explore/Plan [SOURCE: CC sub-agents.md] (T2b-69). Workflow agent with opts.agentType takes over the definition (omitClaudeMd, effort, disallowedTools): in nested claude -p 25.6 vs 41.9k for default; effort opts.effort > definition > session [MEASURED: transcripts, 2026-10-04]; options are in Workflow tool description, not in web docs [CODE: Workflow description] (U2-09, U2-10, U2-11, U2-12, U2-14)
- git status snapshot: nobody gets it in cloud; locally subagents except Explore/Plan [SOURCE: CC settings-reference.md, 2026-10-04] [MEASURED: 0 of 33 transcripts, 2026-10-04] (U2-33, U2-35, T2a-26)

## 3. Agents, workflow, ultracode
- Agent tool: `model` field (aliases sonnet/opus/haiku/fable only) and `isolation`, NO effort field [CODE: Agent schema] (T3-04)
- Subagent without `effort` inherits session; extended thinking always from window [SOURCE: CC sub-agents.md] (T3-03, T3-10); effort precedence: §5
- Workflow agent: `opts.model`/`opts.effort` per agent, omitted = session [CODE: workflow-authoring skill] [MEASURED: effort in transcripts: general-purpose, Explore = session (xhigh); frontmatter medium → medium; opts.effort high → high, 2026-10-04] (T3-05, T3-06)
- Explore and Plan: usually window model, no CLAUDE.md; subagent in worktree takes CLAUDE.md from window, not from copy [SOURCE: CC sub-agents.md, worktrees.md] (T3-09, T3-18)
- Default no isolation: subagent and team member on shared checkout [SOURCE: CC sub-agents.md, agents.md] (T3-12, T3-22)
- `isolation: worktree` = copy from origin/<default branch> (remote; without remote / origin/HEAD – from local HEAD), not from parent's HEAD; `worktree.baseRef: "head"` = local HEAD, no branch name; tracked files only, rest indicated by .worktreeinclude [SOURCE: CC worktrees.md] (T3-13, T3-14, T3-15, T2b-14, T2b-46, T2b-47)
- Uncommitted changes don't reach the copy [ASSUMPTION; MEASURED via git: worktree add -> commit state, 2026-10-04] (T3-16)
- Copy without changes vanishes after agent; with changes, untracked files or unpushed commits stays (also after `cleanupPeriodDays`) until `git worktree remove --force`; `-p` doesn't clean up; in workflow ~200-500 ms + disk per agent [SOURCE: CC worktrees.md] [CODE: skill] (T3-17, T3-19)
- Concurrent workflow agents = min(16, max(2, CPU-2)); change: CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS (1-256, since 2.1.269) [CODE: binary] (T3-24, T3-S-05)
  - [MEASURED: 4 cores, run of 29 agents -> never more than 2 at once; with queue ≥ 2 exactly 2 ran, next one 1.8-3.5 s after previous ended, 2026-10-04] (T3-25, U3-30)
  - FIFO queue: 2nd stage of `pipeline()` waits behind 1st stages of other items (28.5 min) [MEASURED, 2026-10-04] (T3-S-01)
- Agent-tool subagents outside this limit (measured 3 at once at 4 CPU); their limit: 20 running concurrently (CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS; not enforced under ultracode) [SOURCE: CC sub-agents.md] [MEASURED] (T3-27)
- Fan-out hold (5000 ms) may expire before 1st agent's response - second pays full cache write [MEASURED: 2nd agent cache_read 0, 2026-10-04] (T3-26, T3-S-03)
- Run of 29 workflow agents: 15-76 calls, 1.3-12.6M input tokens, 95.5-98.7% from cache, total 202M [MEASURED: transcript usage, 2026-10-04] (T3-29, T3-30)
- Cache: main window TTL 1 h only on subscription within plan limit (API key, credits, Bedrock and other providers: 5 min; cloud session on subscription: 1 h [MEASURED: window cache_creation, 2026-10-04]); agents 5 min; change: promptCacheTtl, subagentPromptCacheTtl, experimental.cacheTtl; prefix shared only with same model, effort, type, tools, schema, directory [SOURCE: CC prompt-caching.md, workflows.md, 2026-10-04] (T3-35, T3-S-02)
- `output_tokens` in JSONL transcripts = value from stream start - don't sum [MEASURED: 55/56 responses <= 20, 2026-10-04] (T3-31)
- Multi-agent ~15x chat tokens; teams ~7x in plan mode [SOURCE: AN engineering/multi-agent-research-system, CC costs.md] (T3-32, T3-33)
- Window instead of subagent: iterations, shared context across stages, many dependencies, quick changes, time [SOURCE: CC sub-agents.md, AN multi-agent-research-system] (T3-36, T3-39)
- Reviewer in fresh context sees only diff and criteria [SOURCE: CC best-practices.md] (T3-38)
  - [MEASURED: same-model reviewer changed 16.7% of 424 findings and added 55 for 88% of research stage cost, run longer by 110%; correctness not assessed, 2026-10-04] (U3-25, U3-28, U3-30)
- Workflow accepts no input mid-run; stops only on permission prompt and limit [SOURCE: CC workflows.md] (T3-47, U3-S-02)
- Auto classifier evaluates subagent task before start, every action (ignores frontmatter permissionMode) and report [SOURCE: CC permission-modes.md] (U3-24); denials: §4
- Nesting: default 3 levels, CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1 disables [SOURCE: CC sub-agents.md] (T3-50); in cloud set to 1 (§7)
- New and changed agent definitions, hooks and permissions work in session (agent file after a few seconds); restart: agents dir created mid-session, `--add-dir`, `--disable-slash-commands` [SOURCE: CC sub-agents.md, settings.md] (T3-51, U3-04, T2b-21)
- Ultracode: workflow on every significant task (more tokens and time), disables "Large workflow" warning, 20 concurrent subagents limit and consent for 1st workflow in auto; word in prompt = one workflow [SOURCE: CC workflows.md] (T3-56, T3-57, T3-58)
- Only the same session resumes a run (also `--resume`); a new one starts from zero [SOURCE: CC workflows.md] (T3-54)

## 4. Agent definitions, permissions, hooks, auto mode
- Agent definition: only name and description required; field with typo or wrong case (maxTurns, omitClaudeMd) silently ignored; file without name or with bad YAML skipped without message; plugin agent ignores hooks, mcpServers, permissionMode [SOURCE: CC sub-agents.md] (T2b-01, T2b-02, T2b-22, T2b-03, T2b-18)
- model: call parameter > frontmatter (`inherit` = window) > CLAUDE_CODE_SUBAGENT_MODEL > conversation model; same-family alias = exact conversation model [SOURCE: ibid.] (T3-01, T2b-04, T2b-05, T2b-06)
- tools/disallowedTools: comma string or YAML list; entry with specifier (Bash(git push *)) removes whole tool; disallowedTools: Edit, Write leaves Bash and MCP – "read-only" not enforced; memory enables Read/Write/Edit; without Agent in disallowedTools agent launches agents (up to 3 levels) [SOURCE: ibid.] (T2b-09, T2b-10, T2b-15, T2b-11, T3-21)
- permissionMode ignored when conversation is in auto/acceptEdits/bypassPermissions; omitClaudeMd (v2.1.271+) keeps only managed policy [SOURCE: ibid.] (T2b-08, T2b-13)
- Rules: deny > ask > allow, first match; deny from any level wins, works also in bypassPermissions; enforced by Claude Code, not model [SOURCE: CC permissions.md, permission-modes.md] (T2b-24, T2b-25, T2b-26, T2b-27)
- Paths: `//path` = absolute, `~/` = home dir, `/path` = relative to the settings file's source, no prefix = cwd; in deny/ask single-segment dir matches at any depth, multi-segment only at anchor [SOURCE: CC permissions.md]; works at depth, with spaces and non-ASCII chars [MEASURED: Read of dummy deeper -> denied, 2026-10-04] (T2b-28, T2b-29, T2b-30, T2b-31)
- Edit(...) covers Edit/Write/NotebookEdit, Write(path) rules checked by nobody; deny Read also blocks Edit/Write (not NotebookEdit – add deny Edit) [SOURCE: CC permissions.md] (T2b-32, T2b-34)
- Deny Read/Edit catches in Bash cat, sed, redirection; does NOT catch grep -r ., python script or commands inside bash script [MEASURED: dummies -> cat denied, python and script read/write, 2026-10-04] (T2b-35, T2b-36)
- Bash rule matches text, not program (git -C . push bypasses); WebFetch(domain:) doesn't block curl [SOURCE: CC permissions.md] (T2b-37, T2b-38). OS-level enforcement for all processes = sandbox [SOURCE: CC permissions.md, 2026-10-04]; in cloud unmeasured [MEASURED: which bwrap -> absent, 2026-10-04] (T2b-36)
- .claude/settings.json only from start dir: -p in subdirectory = 0 project deny rules [MEASURED: claude -p --debug-file -> 0 rule(s), 2026-10-04] (T2b-39, T2b-40). Also without them: --setting-sources user, start outside project with --add-dir [SOURCE: CC permissions.md], cloud with several repos [SOURCE: CC cloud-environments.md] (T2b-S-04, T2b-82, T2b-41)
- Project allow and agent-frontmatter hooks work after folder trust; deny/ask always [SOURCE: CC permissions.md], also for workflow agents [MEASURED: Read of dummy by workflow agent -> denied] (T2b-43, T2b-17, T2b-42)
- Hooks: exit 2 blocks (stronger than allow), exit 1, missing script and timeout (600 s) don't block; allow from hook doesn't bypass deny/ask; changes live; -p runs repo hooks without trust [SOURCE: CC hooks.md] (T2b-49, T2b-52, T2b-54, T2b-59, T2b-56, T2b-61). Test: JSON on stdin; hook from --settings works in -p [MEASURED: InstructionsLoaded -> log, 2026-10-04] (T2b-57, U2-31)
- Auto: deny before classifier; project autoMode not read [SOURCE: CC auto-mode-config.md]; broad allow (Bash(*), Agent) disabled; edits in working dir bypass classifier except protected paths (.claude/ except worktrees, .git, .vscode, .mcp.json, shell rc etc.) – those always go to it [SOURCE: CC permission-modes.md] (U2-21, U2-28, U2-S-01, U2-27)
- Default 17 allow, 72 soft_deny, 1 hard_deny; push target to any branch (incl. default) exempt, content still evaluated, deployment branches (production, release…) outside the exemption [MEASURED: claude auto-mode defaults, 2026-10-04] (U2-17, U2-18). Boundary set in conversation lost on compaction [SOURCE: CC permission-modes.md] (U2-19)
- Classifier denial = tool result after 8.7 s (deny 0.00-0.01 s); agent continues without asking; in transcript owner sees it only in agent's report [MEASURED: agent transcripts, 2026-10-04] (U3-15, U3-17, U3-S-05). User asked after 3 blocks in a row / 20 total; no server verdict = denial with message, after 10 such responses in a row turn / subagent stops [SOURCE: CC permission-modes.md, errors.md, 2026-10-04] (U3-21, U3-23)

## 5. Models and effort
- Models: Fable 5.1 `claude-fable-5-1` (hardest, long agentic tasks), Opus 5.5 `claude-opus-5-5` (start for most), Sonnet 5.5 `claude-sonnet-5-5`, Haiku 4.5 `claude-haiku-4-5-20251001` (no effort, retirement 2026-10-15 at earliest) [SOURCE: PL models/overview.md] (T4-01, T4-06)
- USD/MTok input/output/cache read: Fable 5.1 10/50/0.25; Opus 5.5 4/20/0.20; Sonnet 5.5 2/10/0.20; Haiku 1/5/0.10; Fable÷Opus = 2.5×, cache read 1.25× [SOURCE: PL about-claude/pricing.md] (T4-02, T4-26)
- Compaction: threshold §1; in cloud own CLAUDE_AUTOCOMPACT_PCT_OVERRIDE value changes nothing; window changed by CLAUDE_CODE_AUTO_COMPACT_WINDOW or /autocompact [SOURCE: CC claude-code-on-the-web.md] (T4-03, T4-S-05)
- Aliases (API): opus→Opus 5.5, sonnet→Sonnet 5.5, fable→Fable 5.1, best→fable/opus, opusplan = opus in plan, sonnet in execution; `default` = Opus 5.5, unless org/account model [SOURCE: CC model-config.md] (T4-04, U4-20, U4-11)
- Nested `claude -p` without `--model` ran in cloud on Sonnet 5.5 medium, not session model (cause [ASSUMPTION]); also calls Haiku 4.5 for title (~0.001 USD) [MEASURED: claude -p without --model -> claude-sonnet-5-5] (U4-07, U4-08, U4-09)
- Levels low/medium/high/xhigh/max (Opus/Sonnet 4.6 no xhigh), unsupported → lower; scale per model; default in Claude Code high, Opus 5.5 and Sonnet 5.5 medium [SOURCE: CC model-config.md, PL models/overview.md, 2026-10-04] (T4-08, T4-09); `--model opus` without `--effort` → medium [MEASURED: transcript effort field] (U4-05)
- Effort covers all output (text, tools, thinking): higher = more calls, verification and autonomous decisions; thinking can't be disabled on Opus 5.5 and Fable; Sonnet 5.5 on API disables upfront thinking via `between_tools` mode (effort ≤ high) [SOURCE: PL build-with-claude/effort.md; verification and decisions: CC model-config.md, Opus 5.5/Fable 5.1 tests, 2026-10-04] (T4-10)
- Precedence: CLAUDE_CODE_EFFORT_LEVEL > `--effort`/`/effort` > settings > default; `effort` in skill/agent frontmatter overrides session, not the env var; maxEffortLevel and org limit cap every level, also from frontmatter and opts.effort; effortLevel won't accept max, in user settings doesn't work on Opus 5.5 [SOURCE: CC model-config.md, env-vars.md] (T4-13, T4-09, T4-S-03, T3-03)
- How to set:
  - session: `/effort <level>`, `/model` (Enter saves, `s` session only); in cloud only with argument [SOURCE: CC claude-code-on-the-web.md] (T4-30, T4-S-03)
  - `claude -p`: `--model`, `--effort`; doesn't inherit parent's effort (CLAUDE_EFFORT is a readout) [MEASURED: CLAUDE_EFFORT=high, -p without --effort -> medium] (U4-18, U4-S-03, T4-14)
  - agent: `effort` in frontmatter; ad hoc subagent = session effort (§3) (T4-S-01, T4-15)
  - workflow: `opts.effort`/`opts.model` (§3) (T4-S-02, T4-21)
- Actual effort: effort field in JSONL transcript or $CLAUDE_EFFORT; self-report "reasoning_effort N" ungrounded [MEASURED: script over transcripts] (T4-15, T4-19)
- Anthropic benchmark, Opus 5.5 SWE-bench Pro vs high: medium −2.5 pts for ~70% of cost, low −8 pts for ~1/3, xhigh +1.4 pts for 2.5×; Opus 5.5 medium = Fable 5.1 high (92.8 vs 92.3%) for ~1/5 of cost [SOURCE: PL about-claude/models/optimizing-for-cost-and-intelligence.md] (T4-11, T4-12)
- Changing effort mid-session: on Opus 5.5, Sonnet 5.5, Fable 5.1 (API key, subscription) Claude Code keeps cache; other models, Bedrock / Agent Platform / gateway, CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS – request from scratch (API: 39,000 tokens rewritten) [SOURCE: CC prompt-caching.md, ibid., 2026-10-04] (T4-31)
- Recommendations: Opus 5.5 – xhigh/max only with measured gain (sweep on own evals); Fable 5.1 – start high, routine medium/low [SOURCE: PL effort.md, prompting-claude-opus-5-5.md]; with automated check: everything low, failures on high ≈ half cost [SOURCE: PL optimizing-for-cost-and-intelligence.md] (U4-13, U4-14, T4-32)
- Measurement, code analysis, n=2: Opus 5.5 4/4 at every level; low 0.22 USD/39 s, medium 0.27/59 s, high 0.57/115 s, xhigh 1.03/213 s (3 runs at once – times indicative); high/xhigh changes strategy (130+ Grep), spread up to 2.25×; Sonnet 5.5 medium 4/4 for 63% of Opus medium; Haiku 4.5 failed (2/4 and 0/4) at Opus medium price [MEASURED: claude -p --effort low..xhigh] (U4-01, U4-03, U4-S-02, U4-04)
- Ultracode is a setting, not a level: Claude plans workflows itself; `--effort ultracode`/SDK also sets xhigh, `/effort ultracode` doesn't, choosing a level doesn't disable it (≥ 2.1.284); session with "high + ultracode" had xhigh, enabling path unknown [MEASURED: transcript effort field, 2026-10-04]; no Large workflow warning nor Auto prompt; word in prompt works only typed by a human, disabled by workflowKeywordTriggerEnabled: false [SOURCE: CC model-config.md, workflows.md] (T4-16, U4-17, T4-23, U4-15)
- `ultrathink`: one-turn instruction, API effort unchanged [SOURCE: CC model-config.md] (T4-17)

## 6. Model weaknesses in long projects and countermeasures

A = automated, L = checklist, T = text; model in parentheses when source isn't general. PL … = PL build-with-claude/prompt-engineering/.
- Instruction drift:
  - CLAUDE.md is a user message, no adherence guarantee; conflicting rules = arbitrary choice; too long a file loses rules; T: <200 lines, emphasis only on one line; L: periodic review [SOURCE: CC memory.md, best-practices.md] (T5-02, T5-03, T5-04, T5-09)
  - A (warns, doesn't block): message at start and in /status for too long a file [SOURCE: CC memory.md] (T5-S-04)
  - A: deterministically binding: hooks [SOURCE: CC best-practices.md] and settings rules, e.g. permissions.deny; CLAUDE.md only advises [SOURCE: CC memory.md] (T5-07)
  - quality drop with full window: §1 (T5-01, T5-S-01)
- Information loss:
  - compaction loses what is only in conversation; what returns: §1 [SOURCE: CC context-window.md] (T5-05, T5-06)
  - A: SessionStart hook with compact matcher injects context [SOURCE: CC hooks-guide.md] (T5-08)
  - Bash inline ~30,000 chars; error ~10,000, middle lost with no path [SOURCE: CC tools-reference.md] (T5-S-05)
- Quantitative quotas: on "list N → fabricated" sources silent [ASSUMPTION] (T5-25); reviewer reports gaps even on good work; T: only correctness gaps matter, "nothing found" allowed [SOURCE: CC best-practices.md, PL …/reduce-hallucinations.md] (T5-21, T5-22)
  - (Opus 5) "only serious" → reports less [SOURCE: PL …/prompting-claude-opus-5.md]; Opus 5.5: no separate advice (Opus 5 patterns = "reasonable starting point"), testers: code review stronger [SOURCE: PL …/prompting-claude-opus-5-5.md, 2026-10-04] (T5-23, U5-05, U5-01)
- Sycophancy (AN research 2023/2024, older models): RLHF may reward agreement; it escalated into hiding non-completion [SOURCE: AN research/towards-understanding-sycophancy-in-language-models, …/reward-tampering] (T5-26, T5-27)
  - T (Opus 5): one-sentence caveat, then proceed as asked; review in fresh context [SOURCE: PL …/prompting-claude-opus-5.md, CC best-practices.md] (T5-28, T5-29)
- False "done":
  - ends when it "looks done"; gates: text < /goal (small model each turn) < Stop hook; unattended, the last two suffice [SOURCE: CC best-practices.md, goal.md, 2026-10-04] (T5-31, T5-33, U5-S-01)
  - (Opus 5.5) turn ended with text only may be a progress update – unattended loop must not take it as the end; background work = unfinished (/goal waits by itself); T: name wanted and unwanted stops [SOURCE: PL …/prompting-claude-opus-5-5.md, 2026-10-04] (U5-10, U5-11, U5-12, U5-S-02)
  - T (Fable 5): every claim with a tool result — almost zero fabricated reports [SOURCE: PL …/prompting-claude-fable-5.md] (T5-34)
  - "remove verification instructions" — for Opus 5; Fable 5: verifier in fresh context [SOURCE: PL …/prompting-claude-opus-5.md, …-fable-5.md]; Opus 5.5: no advice (U5-01) [MEASURED: grep over-verif|re-verify, Opus 5.5 pages → 0, 2026-10-04] (T5-42, U5-02, U5-08)
- Stale prompts: L: after model change review instructions, retest effort, xhigh/max only with measured gain [SOURCE: PL models/opus-5-5/migration-guide.md, …/prompting-claude-opus-5-5.md, 2026-10-04] (U5-04, T5-48, U5-21)
  - L: /doctor prompt-audit (≥2.1.283) finds outdated wording, dead references, contradictions; report + diff, changes nothing [SOURCE: CC memory.md] (T5-46, U5-S-05)
  - works in -p; skips files mentioned without @ – pass them by path: `/doctor prompt-audit <file>` [MEASURED: claude -p "/doctor prompt-audit" → success, 2026-10-04] [SOURCE: CC memory.md] (U5-22, U5-23)
- Knowledge loss: every session from empty window; auto memory on one machine only [SOURCE: CC memory.md] (T5-50, T5-53); L: progress file + git, start by reading and test, end with commit [SOURCE: AN engineering/effective-harnesses-for-long-running-agents] (T5-51)
- Apparent understanding: straight to code = wrong problem; A: plan mode; T: interview, spec, new session [SOURCE: CC best-practices.md] (T5-58, T5-59)

## 7. Claude Code cloud environment
- Fresh Firecracker VM per session: Ubuntu 24.04, 4 vCPU, 16 GB RAM, no swap [MEASURED: uname, nproc, free, ps] (T6-01, T6-02)
- Disk: df 252G, available ~28.6 GiB (rest reserve) = allocation ~30 GB [MEASURED: df, statvfs] (T6-03)
- Bash in cgroup claude-code-bash, cap MemTotal − max(2 GiB, 15%) (here 13.4 GiB [MEASURED: memory.limit_in_bytes]) from server flag [CODE: default cap], though docs: opt-in [SOURCE: CC tools-reference.md] (T6-S-01, T6-04)
- CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1 set: subagents don't launch their own [MEASURED: env, 2026-10-03/04] (T2b-11)
- Idle: after a few minutes paused with files; after VM reclaim new machine, history stays, background work doesn't [SOURCE: CE, CC claude-code-on-the-web.md] (T6-07); ignored and unpushed files then most likely lost [ASSUMPTION] (T6-45)
- Waiting for approval / MCP login = inactivity, session may expire [SOURCE: CC claude-code-on-the-web.md] (T6-08)
- Cache = disk snapshot after setup script, no processes; rebuilt after script/hosts change or ~7 days; installs from session don't carry over [SOURCE: CE] (T6-12, T6-13)
- Within a session: shallow clone from snapshot, local main stale – compare with origin/main [MEASURED: git reflog, is-shallow] (T6-11, T6-29)
- Setup script: root, before Claude Code, cloud only, skipped with cache and after pause; exit ≠ 0 = no session; >~5 min = no cache; no API credentials. SessionStart hook: after start, every session, also locally; limit 600 s; CLAUDE_ENV_FILE; doesn't work with several repos; condition CLAUDE_CODE_REMOTE=true [SOURCE: CE, CC hooks.md] (T6-22..26)
- Network: HTTPS via agent proxy; 403 = policy, don't retry; denial reasons in $HTTPS_PROXY/__agentproxy/status [MEASURED: curl status] (T6-15, T6-16)
- Levels None/Trusted (default)/Full/Custom; change applies in ~1 min; off-list domain = CONNECT 403, package registries and apt work [SOURCE: CE] (T6-19, T6-20) [MEASURED: curl, apt, pip, npm] (T6-17, T6-18)
- Git: proxy swaps session credential for user token; session has own branch from origin/main [SOURCE: CE] (T6-31) [MEASURED: git branch] (T6-30)
- Push of new branch OK, branch deletion 403 [MEASURED: push / push --delete -> 0 / 403] (T6-32); proxy doesn't restrict target branch - protection only on GitHub [SOURCE: CE] (U6-03)
- GitHub: branch protection by default doesn't apply to admin; in private repo only on paid plans [SOURCE: github/docs …/about-protected-branches.md, …/gated-features/protected-branches.md] (U6-05, U6-06)
- API and release-assets only for session repo; GraphQL only PR operations [SOURCE: CE] (T6-33)
- Bash: 2 min, max 10; after limit to background, up to 30 more min; background 30 min, max 2 h [SOURCE: CE, CC tools-reference.md] (T6-36, T6-38) [MEASURED: 8 s at 2 s limit -> background] (T6-37)
- Full tmp (ENOSPC): command output lost; message names full tmp at < 10 MB or < 1000 free inodes and suggests CLAUDE_CODE_TMPDIR [CODE: ENOSPC message] (T6-41)
- Token limits shared with account; parallel tasks use them faster [SOURCE: CC claude-code-on-the-web.md] (T6-40)
- Permissions: modes Accept edits/Plan/Auto; bypassPermissions and dontAsk from settings files ignored; edits without asking [SOURCE: CC permission-modes.md, 2026-10-04] (T6-28)
- Environment variables visible to every user of the environment – not for secrets [SOURCE: CE] (T6-44)

## 8. Conclusions for every working method
Each point is an [ASSUMPTION] derived from facts above (IDs in parentheses).
- Hard is only what Claude Code or the server enforces: deny and hook with exit 2 (only on tool call, not on script inside it), sandbox (shell commands), branch protection in repo (the only one on every path of writing to the server). CLAUDE.md, prompt and boundaries from conversation only steer model and classifier (T2a-15, T2b-27, T5-07, U2-19).
- Without sandbox deny is not a boundary: scripts, `grep -r`, curl beside WebFetch bypass it. "Read-only" agent: remove Bash (or sandbox), writing MCP tools and Agent (T2b-36, T2b-37, T2b-38, T2b-10, T2b-11).
- A rule for an agent must be in the prompt or definition: agent doesn't see conversation or person's preferences, Explore agents and agents with omitClaudeMd do not see CLAUDE.md (T2a-03, T2a-07).
- After CLAUDE.md change mid-session (also via merge / pull), before delegating: /compact or new session — agents and classifier have start version (U2-01, U2-04, U2-05, U2-06).
- New and changed agent definitions, hooks, permissions and skills work in the same session, so check them right away; exceptions: agents/skills dir created mid-session (restart or /reload-skills), `--add-dir`, `--disable-slash-commands`, bare mode; re-invoke an invoked skill (T3-51, U3-01, U3-02, U3-04).
- CLAUDE.md short: each KB ≈ 0.5k start tokens of every agent that gets it; over 200 lines lowers adherence (T1a-S-03, T2a-14).
- File read in full ≤ 25k tokens (Polish markdown ~46 KB, safely 40 KB); above 256 KB only with `limit`; partial view doesn't unlock Edit (T1b-02, T1b-04, T1b-15).
- Count budgets with the counter (Read, usage), not chars/3.2 or bytes/4 (underestimate by 13–55%); redo after model change (T1b-40, T1b-41, T1b-29).
- What must survive a long session: root CLAUDE.md, beginning of SKILL.md, SessionStart hook with compact matcher, state files in repo; of files read with Read, content returns only for the 5 most recently modified, and only for files ≤ 5,000 tokens; larger ones return as path only (T1a-43, T1a-46, T5-08).
- Model and effort of every agent, workflow and `claude -p`: state explicitly and check in transcript model / effort fields, not in self-report (U4-07, T4-15, T4-S-01).
- Opus 5.5: start at default medium; xhigh / max only after measured gain on own task; different level for verification by agent (frontmatter, opts.effort; maxEffortLevel cap cuts it); /effort on Opus 5.5 doesn't break cache but changes the whole session (T4-09, T4-11, T4-13, U4-01, U4-13, T4-31).
- Workflow time from limit min(16, max(2, CPU−2)): at 4 CPU N agents ≈ N/2 × agent time. Ultracode removes scale safeguards — watch scale and cost yourself (T3-24, T3-25, T3-57).
- Agent costs ~25–180k tokens at start (depending on CLAUDE.md, tools and prompt) and millions of input via cache: small and iterative tasks cheaper in main window; fresh-context review pays off where an error costs more than the review (T3-29, T3-30, U2-11, U3-25, U3-28).
- Agent won't ask a human, classifier denial doesn't stop it: decisions before start; in prompt: goal, output format, boundaries, success criterion, named stops and listing of denials (T3-45, U3-15, T5-64, U5-12).
- Prompts without quantitative quotas, with "nothing found" allowed; check unattended completion with Stop hook running a script (deterministic) or /goal (small model judges conversation with Claude's reports), not self-report alone (T5-21, T5-22, T5-31, U5-S-01).
- Prompting advice for another model is a hypothesis; after model change review instructions (e.g. /doctor prompt-audit) and effort anew (U5-01, U5-04, T5-46).
- Start session and every `claude -p` at repo root, in a single-repo session — otherwise project deny and hooks don't load (T2b-39, T2b-40, T2b-41).
- Push to default branch is blocked neither by cloud proxy nor by default classifier; ban = server-side branch protection (private repo: paid plan, no admin exemption); deny / ask and PreToolUse hook (also on GitHub MCP tools) only reduce risk (U2-18, U6-03, U6-05, U6-06).
- In cloud, memory between sessions only in repo; environment from session is disposable (idempotent setup: setup script or SessionStart); push often; compare with origin/main (T2a-32, T6-07, T6-12, T6-11).

## 9. Recheck (after new Claude Code version or model)
Commands and scripts to repeat: research report, section "Sprawdź ponownie" (Recheck).
- Always at start: session model, effort_level and window (get_session or /context), variables CLAUDE_EFFORT, CLAUDE_AUTOCOMPACT_PCT_OVERRIDE and CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH, CPU count.
- New Claude Code version: changelog from 2.1.289; Read limits at boundaries (>256 KB without limit, 2,100 lines, 3.2 MB range); workflow concurrency (binary + script) and subagents (20); effort field in Agent schema; precedence of agent model and effort (probes + transcripts); reload of CLAUDE.md, agents, skills, settings in session; deny on dummies; `claude auto-mode defaults`; git status snapshot in cloud; cloud compaction threshold (/context interactively vs 784K from code); default cache TTLs.
- After 2026-10-15: Haiku 4.5 status and pricing (models/overview, pricing).
- New model: bytes per token (Read counter), skill list budget (chars per token), start breakdown, effort sweep on own task, prompting page and migration guide → instruction review.
- New knowledge file: tokens via Read counter (filler > 25k + file, `offset=1`, large `limit`) vs header budget.
