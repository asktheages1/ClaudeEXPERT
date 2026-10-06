# O5 — Model behavior & system design (as of 2026-10-06)
All tags accessed 2026-10-06. PL = https://platform.claude.com/docs/en/ ; CC = https://code.claude.com/docs/en/

## TL;DR
- Opus 5.5 (`claude-opus-5-5`): thinking is always on, and effort is the main control (default `medium` vs `high` on Opus 5). `max_tokens` must cover thinking (128K max). Non-default temperature/top_p/top_k and prefill are rejected. [OF PL prompting-claude-opus-5-5] [OF PL models/opus-5-5/migration-guide]
- Name the exact behavior you want or don't want; generic instructions just swap defaults. Requests to write reasoning in the reply can be refused (`reasoning_extraction`). [OF PL prompting-claude-opus-5-5]
- Caching minimum is 512 tokens on Opus 5.5/Fable 5.1/Sonnet 5.5 (Haiku 4.5 4,096 [3P]). Opus 5.5: 5m write $5, 1h $8, read $0.20. Changing top-level `effort` breaks the cache. [OF PL whats-new-opus-5-5]
- AN engineering posts not fetched, so the design patterns marked [ASSUMPTION] need checking.

## Deltas vs O0/O1/O2 (recheck those files)
- 2.1.290: Bash checks ask for glob-expanding read-only commands (`rg`, `git grep`) and more `ps` forms; WebSearch refills at 100/h instead of a hard stop at 200; WebFetch reports truncation past 100k chars. Recheck O0 §4 deny notes. [CL via 3P]
- 2.1.291: fixes cloud sessions dropping permission answers (2.1.290 regression) and quitting dropping the last messages (2.1.288 regression). [CL via IS]
- Haiku 4.5: O0 §5/§9 say "retirement 2026-10-15 at earliest". Still Active on 2026-10-06 with no retirement notice; 60-day notice rule → not before ~2026-12-05 [ASSUMPTION: date arithmetic]. See §5.
- Fable 5.1 and Mythos 5.1 released 2026-09-01; both Active, not retiring before 2027-09-01. See §5.

## 1. Prompting rules
Opus 5.5 [OF PL/build-with-claude/prompt-engineering/prompting-claude-opus-5-5]:
- Opus 5 prompts work unchanged, and Opus 5.5 uses fewer tokens per task. Speed: Anthropic's launch post (@claudeai on X, 2026-09-22) claims >30% faster output than Opus 5 [OF]. An independent test by The New Stack measured only about 11% faster (103.4 vs 93.1 tok/s) [3P].
- Effort: set `medium` explicitly and sweep levels on your evals. Per the guide, Opus 5.5 at medium matches or exceeds Opus 5 at high on coding and knowledge-work evals [OF]. Keep `xhigh`/`max` for measured gains, and cut thinking by lowering effort, not with prompt text.
- At equal levels it thinks more than Opus 5. 128,000 `max_tokens` worked well for agentic coding.
- From Opus 5 with thinking disabled: start at `low`, drop "write your reasoning" lines, read `display: "summarized"`, and parse responses by block type.
- Unattended: a text-only `end_turn` ≠ done. Keep a checklist, send continuations naming open items, and stop after 2–3. Optionally use a small-model completion checker. The documented standing-instruction paragraph must be added from the first request; mid-session system edits invalidate thinking blocks.
- Progress updates are `thinking` blocks, empty by default. Use `display: "updates"` (beta `thinking-display-updates-2026-08-18`). For silent stretches, append a turn-scoped reminder after ~5 quiet steps (`clear_at: "next_user_message"`), at most 2–3 times.
- Multi-app work: add "explore broadly before acting" for sources the task didn't name.
- Multi-agent: append `elapsed Ns / budgetNs` to each message so teams finish sooner. The budget is advisory, so keep a hard timeout.
- Chat: remove "think carefully" lines.
- Injection: wrap pasted text in `<pasted_content id="RAND">…</pasted_content id="RAND">` and add the documented note.
- Vision: higher resolution plus crop/zoom tools for dense inputs.
- Frontend: list the exact styles to avoid.
- Safeguards cover bio, cyber and reasoning extraction. A refusal returns `stop_reason: "refusal"` with `stop_details`. Fallback models retry except for `reasoning_extraction`.

Cross-model [OF PL claude-prompting-best-practices]:
- Thinking always on: Fable 5.1, Mythos 5.1, Fable 5, Mythos 5, Opus 5.5.
- Thinking on when omitted: Opus 5, Sonnet 5.5, Sonnet 5.
- Thinking off by default: Opus 4.6–4.8, Sonnet 4.6.
- On 5.x models, asking for `<thinking>` tags may be declined.

| Model | Context | Max out | $ in/out | Default effort | Thinking |
|---|---|---|---|---|---|
| Fable 5.1 | 1M | 128K | 10/50 | high | adaptive, always |
| Opus 5.5 | 1M | 128K | 4/20 | medium | adaptive, always |
| Sonnet 5.5 | 1M | 128K | 2/10 | high | adaptive |
| Haiku 4.5 | 200K | 64K | 1/5 | — | manual `budget_tokens` |
Source: [OF PL/models/haiku-4-5/overview]. Note: O0 §5 lists Sonnet 5.5 default effort as medium — conflict; check CC model-config vs PL models/overview.

- Migration: keep conversations append-only, and note that Priority Tier is unsupported on Opus 5.5. [OF PL migration-guide] CC needs v2.1.280+ for Opus 5.5 [3P claudefa.st].
- [ASSUMPTION] The Opus 5 advice to delete "double-check your work" steps likely carries over [3P claudefa.st]. Fable 5.1 and Sonnet 5.5 pages not fetched.

## 2. Agent and system design
- Briefing: teammates and workflow agents don't inherit history, so the brief needs scope, paths, constraints, output format and done-criteria. [OF CC/agent-teams] State what done looks like and when to stop and ask. [BLOG claude.dev/blog/getting-the-most-out-of-opus-5-5]
- Verification: separate producer from judge (adversarial verify agents; `/deep-research` marks unverifiable claims as unverified). [OF CC/workflows] `/goal` uses an independent evaluator. [OF CC/goal]
- Isolation counters laziness on long lists, self-preferential grading and goal drift. [3P claudefa.st]
- Skip multi-agent for sequential work, same-file edits or many dependencies. [OF CC/agent-teams]
- Context budget: keep results in workflow variables, defer MCP tools, use bare mode. [OF CC/workflows] [OF CC/mcp] [OF CC/headless]
- Use a task list or file as external memory. [OF PL prompting-claude-opus-5-5]
- Failure fixes: a lead doing the work itself → "wait for teammates". Stopped teammates → message or respawn. Lagging tasks → update them manually. [OF CC/agent-teams]
- Not fetched: AN context-engineering, long-running harness, multi-agent research, building effective agents, writing tools.

## 3. Evaluation
- `claude plugin eval`: baseline Δ, pinned models, partial runs excluded (O4 §4). [OF CC/plugin-evals]
- Prefer code graders. LLM judges drift on long text, so keep rubrics as concrete PASS/FAIL. [OF CC/plugin-evals]
- DIY harness [ASSUMPTION from documented flags]: `claude --bare -p "$CASE" --json-schema "$S" --output-format json --max-turns 10 --max-budget-usd 1 --permission-prompts none`. Grade `.structured_output`, log `total_cost_usd`, and use ≥3 runs per case [OF CC/plugin-evals].
- Not fetched: PL test-and-evaluate, AN agent-evals.

## 4. API features
- Caching (Opus 5.5): 512 min; 5m $5 (1.25×), 1h $8 (2×), read $0.20 (0.05×); batch $2/$10. [OF PL whats-new-opus-5-5] [OF PL models/opus-5-5/overview] Reads are 0.1× on most models and 0.025× on Fable 5.1 [3P respan].
- Cache breakers: top-level `effort` changes (use per-message effort, beta), system/tools/message edits, tools added later. [OF PL prompting-claude-opus-5-5]
- CC cache aids: `--exclude-dynamic-system-prompt-sections`, the boundary marker, `subagentPromptCacheTtl`. [OF CC/cli-reference] [OF CC/workflows]
- Thinking counts toward `max_tokens` and is billed as output. [OF PL prompting-claude-opus-5-5] [3P emergent.sh]
- Batch is 50% off. Opus 5.5 supports 300k output via `output-300k-2026-03-24`. [OF PL models/opus-5-5/overview]
- Opus 5.5 supports per-message effort, mid-conversation system messages, task budgets, Files API, PDF, vision, and server/client tools. [OF PL whats-new-opus-5-5]
- Not found or fetched: tier rate limits, fast mode, a 1M long-context premium (none mentioned [3P emergent.sh]), citations, context editing, memory tool, compaction, programmatic tool calling.

## 5. Status and known issues
- 2.1.290 [CL via 3P gradually.ai, classmethod.jp, ai-tldr.dev]:
  - Bash checks ask for glob-expanding `rg`/`git grep` and more `ps` forms.
  - WebSearch refills at 100/h.
  - WebFetch reports text past 100k chars.
  - `/loop` survives compaction.
  - `/chrome` reconnect fix for anthropics/claude-code#98135 [IS].
- 2.1.291: fixes the cloud permission-answer drop (2.1.290 regression) and the lost last messages on quit (2.1.288 regression). [CL via IS TranDenyDFW/claude-code-extension-engineering#54]
- 2.1.285–2.1.289 and open regression issues were not surveyed.
- Deprecations:
  - Haiku 4.5 (`claude-haiku-4-5-20251001`): listed Active, retirement "not sooner than October 15, 2026"; page promises ≥60 days' notice. No notice by 2026-10-06 → earliest ~2026-12-05 [ASSUMPTION: date arithmetic; IS MHammett/content-intelligence#272 got ~11-27 on 09-28]. [OF PL/about-claude/model-deprecations] [OF PL models/haiku-4-5/overview] [3P endoflife.date]
  - Sonnet 4.5 (`claude-sonnet-4-5-20250929`): notice sent 2026-09-30, retirement 2026-11-30; replacement `claude-sonnet-5-5`. [OF PL/about-claude/model-deprecations]
- Fable/Mythos: Fable 5 and Mythos 5 launched 2026-06-09, suspended 2026-06-12 under US export controls; controls lifted 06-30, Fable 5 restored globally from 07-01. [3P venturebeat, aljazeera] Fable 5.1 and Mythos 5.1 released 2026-09-01 [3P MacRumors]; deprecations table lists `claude-fable-5-1` and `claude-mythos-5-1` Active, not retiring before 2027-09-01 [OF]. Access: Fable 5.1 generally available; Mythos 5.1 only via trusted access programs [3P 9to5Mac], reportedly limited to U.S. companies and individuals [3P MacRumors].

## Verify live
- `curl -s https://platform.claude.com/docs/en/about-claude/model-deprecations.md | grep -iE 'haiku-4-5|sonnet-4-5'`
- `curl -s https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | sed -n '1,200p'`
- `gh issue list -R anthropics/claude-code --search "regression workflow compaction cloud hooks" --limit 30`
- API: `temperature: 0.5` on `claude-opus-5-5` should return 400. Then a 600-token cached prompt twice, checking `cache_read_input_tokens`.
- Sonnet 5.5 default effort: compare CC model-config with PL models/overview (conflict with O0 §5).
- Fetch PL prompt-caching, effort, rate-limits, the Sonnet 5.5/Fable 5.1 prompting pages, and AN engineering posts.

## New URLs for O1
- ✅ PL/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
- ✅(search) PL claude-prompting-best-practices, PL models/opus-5-5/{migration-guide,whats-new-opus-5-5,overview}, PL models/haiku-4-5/overview
- 🔗 PL/build-with-claude/effort, thinking, preserved-thinking, refusals-and-fallback, PL/about-claude/model-deprecations, claude.dev/blog/getting-the-most-out-of-opus-5-5
