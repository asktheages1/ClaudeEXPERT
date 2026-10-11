# Review 1: KB restructure plan v1 (`PLAN.md`, 2026-10-11)

Reviewer: independent agent, Opus 5.5 (`claude-opus-5-5`), effort xhigh as set by the caller. I did not see the conversation that produced the plan.
Read in full before judging: root `CLAUDE.md`; `knowledge/O0-how-claude-works.md`; O2 §A (A1–A8) and §D (D1–D6, incl. D5), §E and "Verify live"; O3 header, "Deltas", §5, §7, §8 and the end of the file; O1 §2–§5 and "Check again"; O5 header, "Deltas", §4, §5; all of `findings.md`; `PLAN.md`.

## 0. Probes run for this review
Five cheap probes, run in the session scratchpad outside the repo. Total cost 0.81 USD, inside the CLAUDE.md cost gate. Each probe ran once (n=1), so each result is an anecdote, not a rule. For P1–P4 the setup was CC 2.1.296, `claude -p --model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns ≤8 --max-budget-usd ≤1`, with hooks loaded from `--settings`. Each hook wrote its stdin to a file.

| ID | What | Result [MEASURED, 2026-10-11, n=1] |
|---|---|---|
| P0 | `cat` of a 35,350-char file in this agent's Bash tool (auto mode) | "Output too large (34.5KB). Full output saved to … Preview (first 2KB)". Claude saw 2 KB. |
| P1 | Hook payload logger for UserPromptSubmit, PreToolUse(Agent), SubagentStart, PostToolUse(Read\|Bash), SubagentStop and Stop. The main session ran one Read and one Explore subagent ran one Read. Cost 0.19 USD. | `prompt_id` was identical in all six events, subagent events included. `scratchpad_dir` was identical everywhere and has the form `/tmp/claude-0/<cwd-slug>/<session_id>/scratchpad`. Subagent events also carried `agent_id` and `agent_type`. Agent `tool_input` keys were `description, prompt, subagent_type, run_in_background`. SubagentStart carried `agent_id, agent_type, prompt_id`, with no prompt and no `tool_use_id`. Read `tool_response` was `{type:"text", file:{filePath, content, numLines, startLine, totalLines}}`. Stop carried `stop_hook_active` and `last_assistant_message`. The nested `-p` reported the launching session's `session_id`, and `CLAUDE_CODE_SESSION_ID` is set in env. |
| P2 | `cat big.txt` (35,350 chars) in the main session, then a general-purpose subagent. The SubagentStop hook copied `agent_transcript_path` at hook time. Cost 0.26 USD. | Bash `tool_response` had `stdout` = 30,000 chars (of 35,350), plus `persistedOutputPath` and `persistedOutputSize: 35350`. The model said it saw only L00001–L00019, the 2 KB preview. At SubagentStop the agent transcript already had 15 lines, including the first user message (the prompt) and the Read call. |
| P3 | Read the same unchanged file twice with no offset or limit. Cost 0.21 USD. | The 2nd call's `tool_response` was `{"type":"file_unchanged","file":{…}}`, with no content. The model reported that it "pointed back to that earlier result". |
| P4 | `kb/CLAUDE.md` with a marker. The main session ran `cat kb/topic.txt`, then an Explore subagent Read `kb/other.txt`. Cost 0.15 USD. | The main transcript has a `nested_memory` attachment for `kb/CLAUDE.md` right after the `cat`, and the main session made no other access to `kb/`. The Explore transcript has a `nested_memory` attachment after its Read. |

These results are worth a `findings.md` entry. I did not write one because the brief limited me to this file.

## 1. Verdict
**Needs changes.** The direction is right: deterministic gates, a single source (`topics.json`) for the map and the hooks, CI, and honest model scope. Some parts are sound and should stay: the layout decision itself, the model-scope rule, H1 and H5 as concepts, and the "what stays soft" section.

But the plan's centrepiece, the forced-reading chain H4, has three problems as specified:
- it can be satisfied without the model ever seeing the file (P0/P2: a truncated `cat` still counts; P1: a subagent's read counts for the main session);
- its Stop check runs only after the answer has been shown;
- the session it gates can switch it off by editing ordinary files.

Step 1 also hides the riskiest operation, moving all ~142 KB of the KB into 13 new files. That move has no sub-step, no done criterion and no cost line. Several "done" criteria depend on scripts that only step 3 builds, or on self-report.

**Top 5 changes required (ranked):**
1. **Decide whether a read was "full" from `tool_response`, not from command text or parameters** (F1, F10, F9). Read: `type=="text"`, `startLine==1`, `numLines>=totalLines`. Bash: no `persistedOutputPath` and stdout ≥ file length. The main Stop gate counts only log entries without `agent_id`. Handle `file_unchanged` explicitly. Set a hard cap of **≤ 28,000 chars** per KB file so a single `cat` is never truncated.
2. **Make the migration its own mechanical step 0, with no wording changes, and build the checker (H1) and CI (H5) in that step** (F2, F12, F18). A script verifies preservation: all 351 fact IDs and every normalized bullet land exactly once in the new files. A complete old-section → new-file mapping is checked. O0–O5 become redirect stubs so CLAUDE.md routing and old citations never break between merges.
3. **Protect the gates from the session they gate** (F3, F4, F5):
   - Put the hook scripts under deny-protected paths and add a ConfigChange block.
   - Have CI run the checker from `main`, not from the branch being checked.
   - Turn on branch protection that also binds administrators.
   - Deny the GitHub MCP write tools.
   - Put `onFailure: "block"` only on the hook narrowed with `if: "Bash(git push *)"`, not on the hook that fires for every Bash call.
   - Delete the claim that CI "cannot be bypassed".
4. **Re-specify the Stop and SubagentStop gates** (F6, F7, F8):
   - Never exit early on `stop_hook_active`.
   - List the 8-block cap as soft.
   - Match topics also on `last_assistant_message`, carry them forward a few prompts, and include Polish word stems.
   - Add a PreToolUse "read before acting" gate.
   - Make the `agent_transcript_path` route primary for agents (it worked in P2).
   - Inject the map with SubagentStart `additionalContext`.
   - Have the `updatedInput` hook copy every field of the Agent input.
5. **Split step 3 into sub-steps that start with a probe, each with a fixture-based hook test harness (`test_hooks.sh`) and numeric thresholds, and re-estimate costs** (F12, F13, F14). Step 1 is likely 2–4× the stated 15–30 USD.

## 2. Findings

### F1 — Blocking — Reads count as "full" even when Claude never saw the file (check B)
- **What is wrong.** H4.2 defines a full read as "Read without offset/limit, or `cat` of the whole file". That definition misses four cases:
  1. A `cat` of a file over ~30,000 chars gives Claude a 2 KB preview, yet the logger records "cat of the whole file".
  2. `cat f > /dev/null`, `cat f | wc -l`, `cat a.md b.md c.md` (together over 30k chars) and `cat f | head` all look like `cat <file>` to a text matcher.
  3. Subagent reads carry the parent's `prompt_id`. A lazy "agent, read hooks.md for me" therefore satisfies the main session's Stop gate, although the main context never saw the file.
  4. A repeated Read returns a stub (F10).
- **Evidence.**
  - P0 and P2 for case 1. O1 §2: "larger output goes to a file with a 2,000-char preview". O0 §6: "Bash inline ~30,000 chars".
  - The plan's own 40 KB hard cap allows files above 30k chars.
  - P1 for case 3: the subagent's PostToolUse carried the same `prompt_id` as the main UserPromptSubmit, plus an `agent_id`.
  - `cat` is the main reading path, not an edge case. This session's harness instruction says: "While auto mode is active: … read files with cat, head, or sed -n … rather than using the dedicated Read" [MEASURED: this agent's system context, 2026-10-11].
  - The plan's UserPromptSubmit text "(full Read, no offset/limit)" therefore contradicts what the harness tells Claude.
- **Fix.**
  - Read: decide fullness from `tool_response` (`type=="text" && file.startLine==1 && file.numLines>=file.totalLines`; fields measured in P1).
  - Bash: count a read as full only if the command reads a single file, `persistedOutputPath` is absent, and `len(stdout) ≥ chars(file)`. Comparing the sha256 of stdout with the sha256 of the file is stricter.
  - The main gate ignores entries that have an `agent_id`. SubagentStop counts only entries with its own `agent_id`.
  - Hard cap of 28,000 chars per file (F9).
  - Hook message: "read <file> in full with Read or one single-file `cat`".

### F2 — Blocking — The whole migration is hidden inside step 1, and the layout table does not cover every source (checks C, D)
- **What is wrong.**
  - §1 has step 1 write straight into the 13 new files, and step 2 "nie przenosi treści". So all of O0–O5 moves during step 1: 141,939 B, 627 bullets, 87 `##`/`###` sections and 351 unique fact IDs [MEASURED: `wc -c`, `grep -c '^ *- '`, `grep -oE` ID pattern].
  - Yet 1a/1b/1c list only the changelog, the delta boxes, the new pages and the model scope. The move has no criterion and no cost line.
  - Moving every fact while also rewriting it is the "everything at once" pattern the owner said always ended badly.
  - The §1 table also leaves sources without a proper target:
    - O1 §0 conventions, O1 §3 verification procedure (all but the cloud-network part) and O1 §4;
    - O2 §D6 examples and O2 §E;
    - O5 §5 (status and deprecations);
    - the four agent-definition bullets at the top of O0 §4 (name/description, model precedence, tools/disallowedTools, permissionMode/omitClaudeMd). These fall into "O0 §4 (reszta)" and so would land in `permissions-settings-automode.md`, not in `agents-and-workflows.md`.
- **Evidence.** PLAN l.17, l.21–37, l.45–62.
- **Fix.** Add a **step 0 "mechanical move"** with no wording changes, verified by a script:
  - every fact ID (`T1a-01`, `U3-15`…; 351 of them, almost all in O0) and every normalized bullet text from O2–O5, which have no IDs, appears in exactly one new file;
  - an explicit, script-checked old-section → new-file table;
  - O0–O5 become redirect stubs listing old § → new file §.

  Then 1a/1b/1c edit files that already exist. This keeps the plan's benefit of moving each fact only once and makes every step diffable.

### F3 — Blocking — CI and the hooks can be disabled by the session they police (checks A, B)
- **What is wrong.** H5 says CI is "jedyna kontrola, której sesja nie obejdzie (O0 §8)". O0 §8 says something else: hard is "branch protection in repo (the only one on every path of writing to the server)". CI does not qualify, for four reasons:
  1. CI runs the branch's own `kb_check.py` and the branch's own workflow file.
  2. `scripts/` and `.github/` are ordinary paths. In auto mode, "edits in working dir bypass classifier except protected paths (.claude/ except worktrees, .git, .vscode, .mcp.json, shell rc etc.)" (O0 §4).
  3. Hook changes apply live: "hooks and permissions work in session" (O0 §3); "File edits are picked up by a watcher" (O2 §A1). So an edit to `scripts/kb_*` (H1, and the plan puts the H4 scripts in `scripts/` too) weakens gates mid-session with no classifier check at all.
  4. `.claude/settings.local.json` with `"disableAllHooks": true` overrides the project setting. O2 §D1: local > project; §A1: "the value after precedence counts". That file is a protected path, so the classifier sees the edit, but the classifier is soft.
- **Fix.**
  - Put the hook scripts in `.claude/hooks/`.
  - Add **deny** rules for the exact gate paths, e.g. `Edit(/.claude/hooks/**)`, `Edit(/.claude/settings.json)`, `Edit(/.claude/settings.local.json)`, `Edit(/scripts/kb_check.py)`, `Edit(/.github/workflows/**)`. Do not deny `Edit(/.claude/**)` as a whole: findings 2026-10-11 notes that would also catch agent worktrees.
  - Add a **ConfigChange** hook that blocks `project_settings` and `local_settings` changes mid-session (O2 §A5: "yes (except policy_settings)").
  - CI runs the checker from `origin/main` against the branch tree, and fails when the diff touches gate files. GitHub mechanics are not in the KB [ASSUMPTION: verify].
  - Turn on branch protection that includes administrators. O0 §7: "by default doesn't apply to admin".
  - Residual risk, to list in §6: deny "does NOT catch … python script or commands inside bash script" (O0 §4).

### F4 — Important — The push gate does not cover GitHub MCP write tools (check B)
- **What is wrong.** H3 matches only `Bash`. This session's tool list includes `mcp__github__push_files`, `create_or_update_file`, `delete_file`, `create_branch` and `merge_pull_request` [MEASURED: this agent's deferred-tool list, 2026-10-11]. Any of them writes to the server with no `kb_check` run.
- **Evidence.** O0 §8: "deny / ask and PreToolUse hook (also on GitHub MCP tools) only reduce risk".
- **Fix.** Deny those tools by bare name in project settings ("Deny with a bare name removes the tool from context", O2 §D4). That is simpler than a hook and enforced before the classifier.

### F5 — Important — `onFailure: "block"` sits on a hook that fires for every Bash call (check B)
- **What is wrong.** H3 deliberately matches inside the script, not with `if`, so the push hook runs for every Bash call (l.96). It then adds `onFailure: "block"`, "Tylko na tych dwóch wąskich bramkach" (l.98), citing findings 2026-10-11. That finding warns against exactly this configuration: "`onFailure: "block"` only on narrow gates, because a hook on every Bash/Edit call that cannot start … would block even the edit that disables hooks". The skeptic report (`reports/claude-md-comparison-2026-10-11/RECENZJA-zarzuty-sceptyka.md` l.43) gives the fix: a narrow `if` such as `Bash(git push *)`. With the plan as written, a missing interpreter, a syntax error or a wrong path (exit 127, O2 §A6) blocks **every** Bash call, and Bash is the main tool in auto mode.
- **Fix.** Use two handlers:
  - (a) `if: "Bash(git push *)"` with `onFailure: "block"`;
  - (b) a broad Bash handler without `onFailure` that catches `git -C … push` and similar variants; it fails open, and CI is the backstop.

  Also write down the emergency route: the owner edits the settings on GitHub, then starts a new session.

### F6 — Important — The Stop gate's strength is left unspecified, and it fires after the answer (checks B, C)
- **What is wrong.**
  - (a) H4.4 does not say how `stop_hook_active` is handled. The KB's own example (O2 §A8 ex. 5) exits 0 when `stop_hook_active` is true. Copied as is, the gate blocks once and the second stop always passes.
  - (b) Even when written correctly, the gate has a cap. O2 §A5: "After a Stop hook blocks 8 times in a row with no tool call from Claude in between, Claude Code overrides it and ends the turn". A model that keeps answering with text ends the turn anyway. Plan §6 does not list this.
  - (c) Stop fires at "end of Claude's reply" (O2 §A5). The owner has already read the answer, produced without the file, so the gate forces a read *after* the first wrong answer of the snowball.
- **Fix.**
  - In H4, never exit early on `stop_hook_active`; log every time the cap is hit.
  - Add the cap to §6.
  - The block reason must say "re-check your previous answer against <file> and state corrections".
  - Add a **PreToolUse read-before-acting gate**: on matched prompts, deny every tool except reads of the required files until those reads are logged. That makes reading hard for any turn that edits, spawns agents or runs experiments.
  - For pure Q&A, consider measuring direct injection of the matched section through UserPromptSubmit `additionalContext`. The cap is 10,000 chars, and overflow becomes a 2,000-char preview (O2 §A6), so the generator would have to split sections at ≤ ~9,500 chars. This puts the content in context before Claude writes anything, which is the only way to give the model truly "no choice".

### F7 — Important — Matching topics only on the user prompt misses the owner's actual failure (check C)
- **What is wrong.** The owner's failure is follow-up turns: "after the first message" Claude stops returning to the docs. Follow-ups often contain no keywords ("a co z tym drugim?"). Prompts are in Polish (CLAUDE.md "Language") and inflected ("hooków", "hookach"), while the Keywords lines are planned for English grep. UserPromptSubmit also fires on automatic turns such as a background agent's report (O2 §A5: "incl. automatic turns (/loop, background subagent report)").
- **Evidence.** Stop receives `last_assistant_message` (O2 §A5; P1).
- **Fix.**
  - The Stop hook also matches `topics.json` against `last_assistant_message`, i.e. what Claude actually talked about.
  - Matched topics stay required for the next K prompts.
  - `topics.json` regexes include Polish stems.
  - Cap the files required per prompt (e.g. ≤ 3, in priority order) so a broad prompt does not force 5 × 8k tokens of reading.
  - Decide whether automatic turns are matched.

### F8 — Important — Gaps in the agent gate (checks A, B)
- (a) "agent nie ma wyboru, bo linia jest w jego pierwszej wiadomości" is overstated. The injected line is an instruction, which is soft by the plan's own rule 0.1. Only SubagentStop enforces anything.
- (b) `updatedInput` "replaces whole input" (O2 §A5). The measured Agent input keys are `description, prompt, subagent_type, run_in_background`, plus `model`/`effort`/`isolation` when set (P1). The hook must copy them all, or it silently drops, for example, `effort: "max"`.
  - Unverified: whether `updatedInput` on Agent needs `permissionDecision: "allow"`.
  - If it does, unverified whether that skips the auto classifier, which "evaluates subagent task before start" (O0 §3). Measure both.
- (c) Linking a spawn to its `agent_id` by time order breaks with parallel spawns. SubagentStart has no prompt and no `tool_use_id` (P1). The plan's fallback did work, though: at SubagentStop the agent transcript already held the first user message and the Read calls (P2, n=1). Make it the primary route. SubagentStop re-matches topics on the agent's first user message and checks reads logged under that `agent_id`; no spawn → agent mapping is needed.
- (d) SubagentStart supports `additionalContext` (O2 §A5). It can inject the map into **every** subagent, Explore and `omitClaudeMd` included, without depending on a nested CLAUDE.md.
- (e) P4 showed Explore receiving the nested `CLAUDE.md` after a Read (n=1), so plan check 2(c) is half answered; `omitClaudeMd` is still open. Explore stays ungated, so delegating "explain hooks" to Explore is still a shortcut. That is acceptable only because the main gate covers the main answer; say so in §6.

### F9 — Important — The 40 KB / 22,500-token cap does not match what actually limits a full read (check E)
- **Constraints that actually bind:**
  1. **Bash `cat`:** output above 30,000 chars is replaced by a 2 KB preview (P0, P2; O1 §2: `BASH_MAX_OUTPUT_LENGTH` default 30,000). In auto mode `cat` is the default way to read, so this is the binding limit.
  2. **Read tool:** 25,000 tokens per call (O0 §1 [CODE]). English md runs 2.66–2.78 B/token, and O0 itself measures 2.17 B/token (O0 header: 17,754 tokens at 38,565 B). So 28,000 chars ≈ 10–13k tokens, and the token cap never binds for English files under 28k chars.
  3. **Token counting needs a session.** Counting tokens needs the Read counter, which only a session can run, not CI (O0 §8: "Count budgets with the counter … not chars/3.2 or bytes/4").
- **Weak arguments:**
  - Post-compaction restore needs a file ≤ 5,000 tokens (≈ 10.9–13.9 KB) and covers only the 5 most recently modified files (O0 §1, §8). A 20 KB target does not reach it, so it is no argument for 20 KB. H4 invalidates reads after compaction anyway.
  - Forced-read cost scales with file size. That favours smaller files but sets no hard number.
- **Recommendation.**
  - Hard cap **28,000 chars** (`wc -m`) for any file a gate can require.
  - Working target 12–20 KB.
  - Drop the 40 KB and token-estimate checks from `kb_check`; keep the Read-counter measurement in the recheck list for a model change.
  - `docs-index.md` (~20 KB at the start) is the file most likely to grow past 28k chars. When it does, split it by host (CC / PL).
  - If F6's direct injection is adopted, sections must be ≤ 9,500 chars.

### F10 — Important — Repeated Reads return a stub, so the "N turns" logic is built on a wrong premise (checks A, B)
- **What is wrong.** A second Read of an unchanged file returns `{"type":"file_unchanged"}` and no content (P3). This has two consequences:
  - (a) A re-read after N turns through Read adds neither tokens nor content. This contradicts "Każde ponowne czytanie dodaje ~8 tys. tokenów", which holds only for `cat`.
  - (b) It is unknown whether the deduplication resets after compaction. If it does not, a post-compaction Read returns a stub while the content is gone, and the gate is satisfied with nothing in context.
- **Fix.**
  - Before building H4, measure Read after `/compact`.
  - If the dedup does reset, drop N: a re-read with no compaction and no file change adds nothing. Keep "after compaction" and "file changed since the last read" as the triggers.
  - The logger accepts `file_unchanged` only when a full read of that file is logged after the last PostCompact.

### F11 — Important — Where the gate state lives, and test runs colliding with live sessions (check B)
- **What works.** `scratchpad_dir` was identical in main and subagent events (P1), so it can serve as a key space.
- **What is wrong.**
  - It is the directory Claude is told to use for its own temp files without permission prompts, so the log can be clobbered or forged.
  - A nested `claude -p` inherits the launching session's `session_id` (P1–P4), and the path is `/tmp/claude-0/<cwd-slug>/<session_id>/scratchpad` (P1). A nested `-p` test started at the repo root, as the step 2/3 tests would be, therefore shares the parent's gate log [ASSUMPTION from the measured path pattern]. The O0 header already notes nested `-p` entries landing in the window transcript (U5-31).
  - All matching hooks run in parallel (O2 §A7), so concurrent appends can collide.
  - `/tmp` is lost on VM reclaim (O0 §7). That fails closed (more re-reads), which is acceptable.
- **Fix.**
  - Keep state in `${CLAUDE_PROJECT_DIR}/.claude/kbgate/`, gitignored and covered by a deny-Edit rule, keyed by `session_id`.
  - Run tests from a separate checkout at another path (`git worktree add /tmp/kbtest`), so cwd and project dir differ, or add a `KBGATE_NS` env var to the key.
  - Write the log as single-line `O_APPEND` writes.

### F12 — Important — "Done" criteria depend on later steps, on self-report, or have no threshold (check D)
- **What is wrong.**
  - Step 2(a) relies on `kb_check.py`, which is H1 in step 3. 1a and 1c rely on an unnamed "skrypt".
  - 1c's "reviewer checks 20 random facts and reports ≤ 2 errors" is a model-judged sample that tolerates a 10% error rate.
  - 2(b) has no pass threshold.
  - Step 3 results are written as "[MEASURED] w findings" by the same session that built the gates.
  - Step 4 has no criterion. Its target "≤ 120 linii" is already met: CLAUDE.md is 107 lines [MEASURED: `wc -l`]. findings 2026-10-11 measured this repo's CLAUDE.md at 3,752 tokens; tokens per agent start is the metric that matters (O0 §2, §8).
- **Fix.** Build H1 and H5 in step 0. Make every criterion a command with an exit code:
  - **1a:** a triage file with 372 rows (bullet → target file, or "irrelevant" plus a reason), checked by row count.
  - **1b:** a `docs-index.md` row per page with the sha256 and byte size of the fetched `.md` (O1 §3 already says "store `sha256sum`").
  - **1c:** the script is the gate; the reviewer is advisory.
  - **2(b):** ≥ 4/5 per agent type, computed with `jq` over the transcripts.
  - **Step 3:** `scripts/test_hooks.sh` feeds recorded payloads to each hook and asserts exit codes and output (O0 §4: "Test: JSON on stdin"); the P1–P3 JSON files are ready-made fixtures. It runs in CI. Live tests are checked with `jq` over the `-p` JSON output.
  - **Step 4:** Read-counter tokens ≤ target.

### F13 — Important — Step 3 is six steps, not one (check D)
- **What is wrong.** It holds six mechanisms and about ten hook handlers, plus premises that are still unmeasured: `updatedInput` semantics, the dedup after compaction, and whether the classifier lets Claude write `.claude/settings.json`. All of it is planned for 1–2 sessions. That is the "everything at once" pattern again.
- **Fix.** Split it, with each merge revertable on its own:
  - 3a: payload probe (partly done here);
  - H1 and H5 move to step 0;
  - 3b: H3 gates;
  - 3c: H4 main-session gate;
  - 3d: H4 agent gate;
  - 3e: H2, with H6 later.

### F14 — Important — Cost estimates are low (check F)
- **Step 1** (15–30 USD, 3 sessions):
  - findings 2026-10-08 measured 3.56–8.14 USD (mean 5.70) per single-file condensation session, reviewer included.
  - Step 1 implicitly rebuilds 13 files (F2), triages 372 bullets, digests ~29 pages (16 CC + 13 PL as listed) and cuts the model scope.
  - The 13 files alone, at the measured per-file rate, come to 46–106 USD [ASSUMPTION], before any pages. The plan's figure is likely 2–4× too low.
- **Step 3** (5–10 USD): my four trivial `-p` probes at effort low cost 0.15–0.26 USD each. Five tests × n ≥ 2 at a realistic effort, plus building about six scripts in a long session, puts 10–20 USD closer [ASSUMPTION].
- **Not estimated at all:**
  - the §8 review rounds. An Opus `max` review agent used 318,616 tokens (findings 2026-10-11), and Fable costs 2.5× Opus (O0 §5);
  - H6's weekly cost;
  - H4's steady-state overhead per session.
- **Fix.** Estimate per unit (per file, per page, per test) × count, anchored on measured runs; keep one-off and recurring costs separate.

### F15 — Important — H6 rests on pages the KB has not fetched, and widens scope (check C)
- **What is wrong.**
  - O3 §7 says "Scheduled-tasks and Routines pages not fetched". 1b fetches `desktop-scheduled-tasks`, not `routines`.
  - Each run pushes a new branch, so the owner gets one more branch to merge every week.
  - H2's "KB is stale" output is only advisory, i.e. soft, and §6 does not list it.
- **Fix.** Either add `routines` and `scheduled-tasks` to 1b or postpone H6 to a later plan. List H2 as soft.

### F16 — Important — The lazy-grep route is overstated (check C)
- **What is wrong.** The plan says `grep -ril <słowo> knowledge/` makes the right file "win". `-l` lists every matching file with no ranking, and "hook" will match most of the 13 files. A multi-file grep also does not trigger the nested CLAUDE.md: since 2.1.293 that happens only for a single-file `cat/head/tail/sed -n/grep` (O0 §2).
- **Fix.**
  - Make the map greppable: keyword → file lines in `knowledge/CLAUDE.md`. A `grep -i hook knowledge/CLAUDE.md` then answers directly, and as a single-file grep it also loads the nested map.
  - Combine this with the SubagentStart injection (F8d) and the SessionStart injection.
  - Measure in 2(b).

### F17 — Important — The "every bullet has a tag" check hides re-tagging work (checks A, C)
- **What is wrong.** O2 puts its tags on headings ("### A1. Where to define, scope [S:hooks]"), and its bullets carry none. O0 §6 has untagged parent bullets ("- Instruction drift:"). A literal check fails most of O2, which turns into hundreds of lines of re-tagging that the plan does not count.
- **Fix.** Teach `kb_check` that a tag on a heading applies to the bullets under it, and exempt parent bullets.

### F18 — Important — Routing breaks between steps, and CLAUDE.md edits need permission (check D)
- **What is wrong.**
  - Between the step 1 merge and the step 2/4 merges, the root CLAUDE.md still routes to files the plan replaces: its table, "O0 in full once per session", and the conflict list (O0 §5, O5 §1, O0 §3, O3, O1 §2).
  - CLAUDE.md role item 4 requires the owner's permission for every CLAUDE.md change. Steps 2 and 4 edit it, and so does 1c if it removes the Haiku conflict before the list moves.
- **Fix.**
  - Keep redirect stubs (F2) until step 4.
  - Name every CLAUDE.md change in the plan as a separate owner decision.

### F19 — Important — Missing: rollback, kill switch, and the generator as a single point of failure (check G)
- **Rollback.** None is defined. Before each merge, tag (`kb-pre-step-N`); rollback = revert the merge.
- **Kill switch.** None is defined for the owner, cloud included. For example: an environment variable the hooks read, set in the cloud environment settings (O0 §7: env vars visible to the environment's users, fine for a non-secret flag); or "edit settings on GitHub + new session".
- **Generator failure modes.** `kb_build.py` generates the map, the Keywords lines and the hook rules from one `topics.json`. A bug there makes all three consistently wrong, and `kb_check` would agree with them. Two fixes:
  - CI rebuilds the generated sections and diffs them;
  - `kb_check` validates `topics.json` independently: every regex compiles, every listed file exists, every content file is covered by at least one topic, and the Polish and English test phrases in a fixture hit the expected files.
- **Who does what.** One list for the owner: add `.claude/settings.json`, set branch protection, create the Routine, merge.
- **Hooks during `claude -p` tests.** The plan does not cover this. "-p runs repo hooks without trust" (O0 §4), so every probe started at the repo root runs the gates, including SessionStart network fetches. Use the separate checkout (F11).

### Minor
- **M1 — Citation slips (check A).**
  - (a) "Explore czyta wycinki z założenia, O0 §2": O0 §2 says no such thing; it only gives a start-cost row.
  - (b) The plan tags O0 §8 as `[SOURCE: …]`, but O0 §8 says "Each point is an [ASSUMPTION] derived from facts above".
  - (c) The post-compaction claim leaves out "up to 5 files … most recently modified" (O0 §1, §8).
  - (d) The findings 2026-10-06 citation gives "n=2" denials but leaves out "Ordinary edits to CLAUDE.md requested by the owner were allowed in the same session (n=3)". It also omits that the denied actions were a standing merge approval and a fast-forward of `main`.
  - (e) The branch-protection citation leaves out the admin exemption (O0 §7).
  - (f) The nested-CLAUDE.md `[MEASURED]` tag covers Read only; the Bash part was `[CL]` until P4 (n=1).
  - (g) `allow_large`, `autoCompactWindow` and `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` appear nowhere in the repo. `allow_large` exists in this session's Read tool schema [MEASURED: tool list]. Mark the other two "to verify" in 1a.
- **M2 — The old-name table does not fit the map.** There are 87 `##`/`###` sections (O0 9, O1 14, O2 31, O3 14, O4 10, O5 9), which cannot share a ≤ 60-line `knowledge/CLAUDE.md` with the map and the conflict list. Put the table in the stubs (F2).
- **M3 — Output caps.** SessionStart and UserPromptSubmit stdout are capped at 10,000 chars (O2 §A6). The map plus the freshness report must stay under that, or Claude gets a 2,000-char preview.
- **M4 — False positives in the model-scope script.** Haiku appears as a *component*, not as a model topic. Examples: title generation (P3 `modelUsage` shows `claude-haiku-5-5`; O0 §5: "calls Haiku 4.5 for title"), the `claude-code-guide` agent's model (O1 §2) and the `/goal` evaluator (O3 §7). Add a third allowed marker, "component". 1c also says nothing about the Sonnet 5.5 default-effort conflict on the CLAUDE.md list.
- **M5 — The push gate checks the wrong tree.** It runs `kb_check` on the working tree, not on the commits being pushed, so uncommitted fixes can hide a broken HEAD. Check HEAD's tree instead (`git archive HEAD | tar -x -C tmp`).
- **M6 — H3's Stop gate blocks pauses.** With a dirty `knowledge/` it blocks Claude from ending a turn mid-edit, e.g. to ask the owner, until the cap is hit. Make it advisory at Stop and hard at push and in CI.
- **M7 — Header churn.** A `Budget:` header line holding the current size changes on every edit. Keep the cap in the header and the measured size in `STATE.md`.
- **M8 — Workflow prompts.** "PreToolUse na Workflow widzi skrypt, nie prompt" is too absolute: agent prompts usually sit in the script as string literals (O3 §5). Partial matching is possible, but keep it soft.
- **M9 — Refresh the hook docs before step 3.** O2 is "documentation only, nothing measured live" (header), with `*` excerpt-only rows; the PostCompact input is one of them. Re-fetch `hooks.md` and `hooks-guide.md` before step 3 (add both to 1b).

## 3. Citations verified as correct
- O2 §A1: settings hooks fire inside subagents with `agent_id`/`agent_type`. Also confirmed by P1.
- O2 §A6: exit 2 cannot be overridden by `permissionDecision:"allow"`.
- O2 §A5: Stop with exit 2 → "Claude continues"; SubagentStop → "subagent does not finish".
- O2 §A5: PreToolUse `updatedInput` exists. The caveat "replaces whole input" is missing from the plan (F8).
- O2 §A5: SubagentStart gives `agent_id`, `agent_type`, no prompt. Confirmed by P1, which also shows `prompt_id`.
- O2 §A5: Stop 8-block cap and `stop_hook_active`. Cited for H3 but not applied to H4 (F6).
- O2 §A4: `scratchpad_dir` (v2.1.257+) exists. Present in all six events in P1.
- O2 §A4: `transcript_path` is "written async, may lack the current turn".
- O2 §A2: UserPromptSubmit command timeout is 30 s. Pure regex matching takes milliseconds, so this is not a real risk as long as the hook does no network or large-file work.
- O2 §A5/§A6: UserPromptSubmit and SessionStart plain stdout goes to context.
- O0 §1: Read limit of 25,000 tokens per call [CODE].
- O0 §1: after compaction, files over 5,000 tokens come back as a path only. The 5-file caveat is missing (M1c).
- O0 §2 + `[CL 2.1.293]`: nested CLAUDE.md loads on Read/Write/Edit and on a single-file `cat/head/tail/sed -n/grep`. P4 confirms `cat` and Explore Read (n=1).
- O0 §6: SessionStart with the `compact` matcher re-injects context [SOURCE: CC hooks-guide.md].
- O0 §4: `git -C . push` bypasses text rules.
- O0 §4: `.claude/` is a protected path that always goes to the classifier.
- O0 §4: `-p` started in a subdirectory loads 0 project rules.
- O0 §7 and findings 2026-10-08: repo hooks do not load in a session with several repos.
- O0 §7: branch protection in a private repo needs a paid plan. The admin caveat is missing (M1e).
- O0 §5: `claude -p` without `--model` ran on Sonnet 5.5 (a correct example of a trap).
- O1 §3: holds the cloud-network notes, so it is the right source for `cloud-environment.md`.
- findings 2026-10-11: 372 bullets (92/56/2/143/79), ~25 relevant missing pages, 0 Routines, `onFailure: "block"` in 2.1.295, and an Opus `max` agent using 318,616 tokens.
- findings 2026-10-08: 5.70 USD mean per single-file session. The figure is correct, but it was measured per doc file, not per KB step (F14).
- findings 2026-10-08 and O0 §3: Agent `effort` parameter since 2.1.292.
- findings 2026-10-06: two `[Self-Modification]` denials. The n=3 counter-evidence is missing (M1d).

## 4. Open questions only the owner can answer
1. Do you accept a hard cap of 28,000 chars per KB file instead of 40 KB (F9)? It means more and smaller files: about 13–16 instead of 6.
2. The Stop gate can only force reading **after** an answer is shown. Should a gated turn also block every non-reading tool until the files are read (F6)? Do you want a test of injecting the matching section directly into the prompt (more tokens per question, but no way to skip it)?
3. Gate files would become deny-protected: Claude could no longer change hooks, the checker or the CI workflow, and every change would go through you on GitHub. Acceptable?
4. Is the repo public or private, and will you enable branch protection that also binds you as admin (paid for private repos)? Without it, a red CI check is only a warning you could click past.
5. Which emergency switch do you want for broken hooks: an environment variable in the cloud environment settings, or "edit settings on GitHub + new session"?
6. Should forced reading also apply to automated sessions (Routine, nested `claude -p` tests) and to background-agent reports, or only to turns you type?
7. Is H6 (weekly Routine) in scope now, or later after the gates are proven?
8. What budget ceiling do you set for step 1, given the re-estimate (likely 2–4× the plan's 15–30 USD)?
