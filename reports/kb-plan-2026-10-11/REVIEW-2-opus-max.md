# Review 2: KB restructure plan v2 (`PLAN.md`, 2026-10-11)

Reviewer: independent agent, Opus 5.5 (`claude-opus-5-5`), effort max as set by the caller. I had no access to the conversation that produced the plan and no web access.

Read in full before judging:
- root `CLAUDE.md` and `knowledge/O0-how-claude-works.md`;
- O2 §A (A1–A8), §D (D1–D6), §E and "Verify live";
- O3 header, "Deltas", §5–§10, "Verify live" and "New URLs";
- O1 header, §0, §1.5, §2–§5 and "Check again";
- O5 in full;
- `findings.md`, `exceptions.md` and `REVIEW-1-opus-xhigh.md`;
- `PLAN.md` v2, plus v1 via `git show 8b0add4:reports/kb-plan-2026-10-11/PLAN.md`.

Plan lines are cited as `L<n>` (`cat -n PLAN.md`).

## 0. Evidence gathered for this review

### Probes
All probes ran in the session scratchpad (`/tmp/claude-0/…/scratchpad/probe{A,B,C}`), outside the repo, on 2026-10-11 with CC 2.1.296. Command: `claude -p "<task>" --model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns 6 --max-budget-usd 0.5 --settings hooks.json --output-format json`. Each probe ran once (n=1), so each result is an anecdote until repeated. Total cost: 0.33 USD.

| ID | Question | Result [MEASURED] | USD |
|---|---|---|---|
| A | Does the Bash `tool_response.stdout` of an exact `cat` equal the file bytes? This is the premise of plan 3c.2, "`sha256(stdout) == sha256(pliku)`". Setup: a PostToolUse(`Bash\|Read`) hook dumped its stdin. The file had 154 B in 8 lines, contained `→ ≤ §`, trailing spaces and a tab, and ended in `\n`. | **Bash:** `stdout` is 153 B, the file without its final `\n`. `stdout + "\n" == file`, and the two sha256 values differ. Response keys: `stdout, stderr, interrupted, isImage, noOutputExpected`. **Read:** `type:"text"`, `startLine` 1, `numLines` 8, `totalLines` 8, `file.content` byte-identical to the file. `modelUsage` also listed `claude-haiku-5-5`. | 0.095 |
| B | Does a narrow handler with `if: "Bash(git push *)"` and `onFailure: "block"` fail closed and stay narrow (plan 3b a/b)? Setup: the handler's command was a non-existent path; a second handler logged every Bash call; `--allowedTools "Bash(git *)"`; a local bare remote. | `git status --short` ran. `git push origin HEAD:refs/heads/probe1` was blocked. `git -C . push origin HEAD:refs/heads/probe2` went through. `git for-each-ref` on the remote shows only `refs/heads/probe2`, so this is not the model's self-report. | 0.112 |
| C | Does SubagentStart `additionalContext` reach an Explore subagent (plan step 2, road 4)? | The agent transcript, copied at SubagentStop from `agent_transcript_path`, has a `hook_additional_context` attachment carrying the marker. The Explore agent returned the marker. The SubagentStart payload had `agent_type:"Explore"` and no `prompt` key, consistent with review 1 P1. | 0.126 |
| A+C | What session identity does a nested `-p` get? | `session_id` equals the launching session's ID in both runs. `scratchpad_dir` is `/tmp/claude-0/<slug of the nested run's cwd>/<session_id>/scratchpad`, which is not the launching session's scratchpad when the cwd differs (n=2). | — |

### Static measurements (no model)
- `cat knowledge/O*.md | wc -c` gives 141,939. `grep -c '^ *- '` gives 627, which includes YAML list lines inside code blocks. `grep -cE '^#{2,3} '` gives 87, which includes one line inside O1 §5's code block (O1 l.166 `## Claude / CC / API documentation`).
- **Fact IDs:**
  - The IDs are in O0, plus `U4-01` at O1 l.131. There are 350 unique IDs and 425 occurrences.
  - **67 IDs occur more than once.** 65 of them sit in sections that PLAN §1 sends to *different* new files.
  - Most of these are O0 §8 citing IDs from §1–§7. Example: `T1b-02` appears at O0 l.23 (§1) and l.185 (§8).
- **Not mapped by the §1 table:**
  - the TL;DR sections of O1–O5 (19 bullets: O1 3, O2 3, O3 5, O4 4, O5 4);
  - the file headers, including O0's "Session reading budget" paragraph, which carries fact `U5-31`.
- **Rule 0.4 as written** means: a tag on the bullet or on its `##`/`###` heading, with parent bullets exempt. Applied to the 616 bullets outside code blocks, ≈130 fail (approximate regex). Examples:
  - O0 §2 l.52–56, which are children of a tagged parent bullet;
  - O5 §1 bullets under the plain line "Opus 5.5 [OF …]:";
  - every TL;DR bullet;
  - O3 §3, O4 §2.
- **Model scope:** 36 non-table lines name Sonnet, Haiku, Mythos or older models (O0 16, O1 2, O5 18).
- **Verbatim sizes of the 13 planned files** (Python `len`): the largest are `docs-index` 18,688 chars, `hooks` 18,269 and `agents-and-workflows` 13,902. So the 28,000-char cap passes at step 0.
- All six KB files, `CLAUDE.md` and `findings.md` end with `\n`.
- **Container:**
  - Locale is POSIX: `printf '→§≤\n' | wc -m` gives 9, so `wc -m` counts bytes here.
  - `which bwrap socat` finds nothing.
  - `python3`, `jq`, `sha256sum`, `gh` and `git` are present.
- **`CLAUDE.md`:** 9,774 B and 107 lines, unchanged since `b096c2f` (2026-10-06).

## 1. Verdict

**Needs changes before step 0.** v2 incorporates most of review 1 faithfully and its direction is right, but step 0 cannot meet its own done criterion (its checker needs artifacts that only steps 1c, 2 and 3e create, and its "each fact ID exactly once" invariant fails a perfect move because 65 IDs already sit in sections sent to different files), and the server-side backstop that §7 relies on can be rewritten by the branch it checks. The forced-reading gates also rest on a premise this review measured as false (Bash `stdout` drops the trailing newline, so `sha256(stdout)` never equals `sha256(file)` for any KB file), and they have deadlock paths and bypasses that §7 does not list.

**Top 5 required changes (ranked):**
1. **Make step 0 executable** (B1, I6).
   - Split it into 0a and 0b:
     - **0a:** checker and trusted CI, run on today's O0–O5;
     - **0b:** a *scripted* move driven by a machine-readable mapping table.
   - Give the checker per-step profiles.
   - Change the migration invariant to: every normalized line exactly once, and the multiset of ID occurrences unchanged.
   - Map the TL;DRs and headers.
   - Decide the interim root-CLAUDE.md routing before O0 becomes a stub.
2. **Make the backstop trustworthy and §7 honest** (B2).
   - The required check runs on `pull_request_target`, with workflow and checker taken from `main`, and treats the PR tree as data.
   - It fails on any diff to gate paths.
   - List every GitHub write path (`gh`, every MCP write tool) explicitly.
   - Probe the session token's permissions before enabling protection.
   - State that "the owner merges" is a habit, not a mechanism.
3. **Fix the read-gate specs before 3c/3d and run them log-only first** (I1, I3).
   - Compare after removing trailing newlines (probe A).
   - Exempt events that carry an `agent_id` from the main-session gate.
   - Fail open on a missing required file.
   - Always let `git add/commit/push` through.
   - Gate an allowlist of agent types.
   - Normalize worktree paths.
   - Probe whether the 8-block cap applies to SubagentStop.
4. **Protect everything a hook reads at runtime, lock last, and state the threat model** (I2, I4).
   - Protect `knowledge/topics.json` and the other `scripts/kb_*`.
   - Add the unlisted bypasses to §7: log forgery via Python, nested `-p --settings '{"disableAllHooks":true}'` or the kill-switch variable, `gh`, worktree edits, and lexical topic matching.
   - Merge the deny "lock" after the gate scripts are built, so the owner is not hand-editing about 8 scripts on GitHub.
5. **Measure before enforcing, and fix the money** (I5, I8).
   - Use log-only mode to measure the baseline of the owner's failure. Add an A/B probe on whether `cat` re-reads between compactions help before ruling them out.
   - Step 1's stated 40–90 USD is below its own per-unit anchors (67–146).
   - Price the review rounds, the Routine and the recurring injections.
   - Change step 4's metric to total injected start tokens, not root CLAUDE.md alone.

## 2. Citation audit

**Method.** I checked every KB, findings and review citation in v2 against the quoted file and section.

**Conclusion on the author's reading.** The citations are consistent with having read what the author claims (O0, O2 §A/§D5, O3 §7–8, O1 §2–§5, findings, review 1). One citation (O2 §D4) lies outside that list, but review 1 quotes it verbatim. Nothing is fabricated. The errors fall into two patterns:
- caveat tags from review 1 or findings were lost when restated ([ASSUMPTION] on the worktree catch, the scratchpad inheritance and the GitHub mechanics);
- schema facts are attributed to probes that did not measure them.

| # | Plan citation (line) | Verdict | Actual text when not correct |
|---|---|---|---|
| 1 | L11 "O0 §8 (wnioski oznaczone tam jako [ASSUMPTION] z faktów O0 §4 [SOURCE: CC permissions.md, hooks.md])" | **Overstated** | The [ASSUMPTION] part is right: O0 §8: "Each point is an [ASSUMPTION] derived from facts above". But the hard-list bullet cites T2a-15 (O0 §2, memory.md), T2b-27 and U2-19 (O0 §4, permissions/permission-modes) and T5-07 (O0 §6: "hooks [SOURCE: CC best-practices.md]"). hooks.md is not its source. The same bullet lists "sandbox (shell commands)", which rule 0.1 leaves out, and O0 §8 adds "Without sandbox deny is not a boundary". |
| 2 | L13 `claude -p` without `--model` runs on Sonnet 5.5, O0 §5 [MEASURED] | Correct | — |
| 3 | L13 Haiku generates titles (O0 §5), drives `claude-code-guide` (O1 §2), judges `/goal` (O3 §7) | Correct as KB citations | O0 §5 says "calls Haiku 4.5 for title". Probe A's `modelUsage` shows `claude-haiku-5-5`, so the KB fact is stale; 1a should update it. |
| 4 | L14 a heading tag covers the bullets under it, "tak robi dziś O2" | **Overstated** | True for most O2 sections ("### A1. Where to define, scope [S:hooks]"), but not all. A2 tags bold pseudo-headings ("**Common handler fields** [S:hooks]"). A8, B5, C5 and D6 headings carry no tag. TL;DR bullets have none. O0 tags parent bullets whose children carry none. About 130 bullets fail the rule (§0). |
| 5 | L15 F9, P0/P2 [MEASURED, n=1]; O1 §2 `BASH_MAX_OUTPUT_LENGTH` default 30,000; Read limit 25,000 tokens O0 §1 [CODE] | Correct | — |
| 6 | L15 "w trybie auto Claude czyta pliki przez `cat`" | Correct (it is an instruction, so a tendency) | The same harness line is in this agent's context: "read files with cat, head, or sed -n … rather than using the dedicated Read". |
| 7 | L23 hook injection limit 10,000, O2 §A6 | Correct | Note that the limit applies per output field ("10,000-char limit per `additionalContext`/`systemMessage`/`initialUserMessage`/stdout"), not as a combined total. |
| 8 | L44 "141 939 B, 627 punktów, 87 sekcji, 351 identyfikatorów" | Correct, with caveats | Reproduced 141,939, 627 and 87. I count 350 unique IDs. The 87 includes a code-block line, and the IDs are not unique per bullet (§0), which matters for L46. |
| 9 | L48 "Repo jest publiczne [MEASURED: GitHub API …]" | Not verified | Unverifiable without web access. Remote: `github.com/asktheages1/ClaudeEXPERT`. |
| 10 | L48 admin exemption, O0 §7 [SOURCE: github/docs] | Correct | — |
| 11 | L56 raw CHANGELOG via O1 §2; 372 bullets [MEASURED]; `allow_large` in the Read schema [MEASURED] | Correct | `allow_large` is also in this agent's Read schema. |
| 12 | L60 O2 is "documentation only", partly from excerpts | Correct | — |
| 13 | L62 sha256 of the fetched `.md`, O1 §3 | Correct | — |
| 14 | L68 findings 2026-10-08: 3.6–8.1 USD per heavy single-file session | Correct citation; **the total does not follow from it** (I8) | — |
| 15 | L76 "O0 §2 [SOURCE: CC memory.md] [MEASURED: Read] [CL 2.1.293]" | **Misattributed** | The nested-load bullet carries "[CL 2.1.293, 2026-10-08]" and "[MEASURED: Read of 2 lines → nested_memory 18.5 KB]", not memory.md. The memory.md support is O2 §D5: "Parent dirs load at start, subdirs on demand (Read/Write/Edit)". |
| 16 | L76 `cat` and Explore Read confirmed by P4 [MEASURED, n=1] | Correct | — |
| 17 | L77 SubagentStart `additionalContext`, O2 §A5 | Correct | Now also [MEASURED] for Explore by probe C (n=1). |
| 18 | L78 SessionStart `startup`/`compact`, O0 §6 [SOURCE: hooks-guide]; ≤10,000, O2 §A6 | Correct | — |
| 19 | L86 "hooki z ustawień projektu działają też w subagentach (O2 §A1, próba P1)" | **Overstated (P1 part)** | O2 §A1: "Settings, managed and plugin hooks also fire inside subagents" supports the claim. But P1 loaded its hooks "from `--settings`" (review 1 §0), the CLI level, not project settings. |
| 20 | L86 exit 2 not overridable (O2 §A6); Stop/SubagentStop block (O2 §A5); `updatedInput` replaces the whole input (O2 §A5) | Correct | — |
| 21 | L88 "nie `Edit(/.claude/**)` w całości: złapałoby worktree agentów" | **Overstated** | findings 2026-10-11: "would also catch agent worktrees in `.claude/worktrees/` [ASSUMPTION: path matching unmeasured]". |
| 22 | L88 ConfigChange can block, O2 §A5; bare-name deny removes the tool, O2 §D4; parallel hooks, O2 §A7 | Correct | ConfigChange input fields are excerpt-only (`file_path?`*). |
| 23 | L88 `onFailure: "block"` only on the narrow `if` handler (findings 2026-10-11) | Correct | Also confirmed by probe B (n=1). |
| 24 | L88 env vars visible to the environment's users (O0 §7); `-p` from the repo root runs hooks without trust (O0 §4) | Correct | — |
| 25 | L88 "zagnieżdżone `-p` dziedziczy `session_id` i katalog scratchpad rodzica (próba P1)" | **Half wrong** | `session_id`: correct (P1; probes A and C). Scratchpad: P1 only showed main and subagent events of *one* run sharing a scratchpad. Review 1 F11 tagged parent inheritance "[ASSUMPTION from the measured path pattern]". Probes A and C show the nested run's `scratchpad_dir` is built from the nested run's own cwd. |
| 26 | L90 "po kompakcji treść > 5 000 tokenów nie wraca, O0 §1" | **Incomplete** (M1c not applied) | O0 §1: "up to 5 files read or edited, most recently modified (>5,000 tok. path only)". |
| 27 | L90 classifier evaluates the subagent task (O0 §3) | Correct | — |
| 28 | L96 Read fields measured in P1; subagent shares `prompt_id` (P1) | Correct | Read fields reproduced by probe A. |
| 29 | L98/L99 Stop after the reply, 8-block cap, `last_assistant_message` (O2 §A5, P1); Read stub (P3) | Correct | O2 documents the cap for Stop only: "After a Stop hook blocks 8 times …". |
| 30 | L103 "(`description`, `prompt`, `subagent_type`, `run_in_background`, `model`, `effort`, `isolation`; P1)" | **Overstated** | Review 1 §0 P1: "Agent `tool_input` keys were `description, prompt, subagent_type, run_in_background`". The other three come from the schema (O0 §3), not P1. |
| 31 | L103 P2 transcript already had the first message and the Read call at SubagentStop | Correct (n=1) | Missing the caveat in O2 §A4: "`transcript_path` (written async, may lack the current turn)". |
| 32 | L107 0.15–0.26 USD per trivial `-p` at effort low | Correct | Probes A–C cost 0.095–0.126. |
| 33 | L109 "findings 2026-10-06: 2 odmowy przy zapisie zgody na merge, 3 zwykłe edycje przepuszczone" | **Partly wrong** | findings: "editing CLAUDE.md to record a standing approval to merge, **and then fast-forwarding `main`** with a branch that changes CLAUDE.md". Only one of the two denials was the approval edit. |
| 34 | L113 "≤ dzisiejsze 3 752 (findings 2026-10-11)" | **Overstated** | findings: "Expert 9,881 B → 3,752 tok". The committed CLAUDE.md is 9,774 B and 107 lines, unchanged since 2026-10-06. 9,881 − 9,774 = 107 [ASSUMPTION: a CRLF copy]. So the baseline was measured on a different file. |
| 35 | L118 8-block cap (O2 §A5); L119 deny misses Python and in-script commands (O0 §4); L120 multi-repo and out-of-root `-p` load no project hooks (O0 §4, §7) | Correct | — |
| 36 | L119 "łapie CI z main i branch protection" | **Wrong as stated** | See B2. The checker has no gate-file check, and a `pull_request` run uses the PR's own workflow file [ASSUMPTION: GitHub semantics, not in the KB]. |

## 3. Review-1 incorporation audit

v2 contains no list of rejected findings and marks nothing "rejected". So every gap below is a **silent drop**.

| Item | Status in v2 | Where; what is missing |
|---|---|---|
| F1 | Incorporated | 3c.2, the 3c.1 message, the agent_id rule (L96), the cap (L15). The Bash rule itself is wrong (I1). |
| F2 | Incorporated | Step 0 and the added table rows. The invariant and completeness are broken (B1). |
| F3 | **Partly; silent drop** | L48 keeps "runs the checker from `origin/main`". Dropped: "**and fails when the diff touches gate files**" and "GitHub mechanics are not in the KB [ASSUMPTION: verify]" (review 1 l.98). |
| F4 | Incorporated | L88. The list ends in "…"; `create_branch`, named in F4, is not listed. |
| F5 | Incorporated | 3b (a)/(b) and the kill switch. Premise confirmed by probe B. |
| F6 | Incorporated | 3c.4, 3c.5, 3c.6; the cap is in §7. |
| F7 | Incorporated | 3c.1 and 3c.5; ≤3 files; automatic turns become Q7. |
| F8 | Incorporated | 3d, road 4, §7. The (b) attribution is overstated (citation 30). |
| F9 | Incorporated | Rule 0.5. |
| F10 | Incorporated, **but changed** | F10 made dropping N conditional ("If the dedup does reset, drop N"). v2 drops N unconditionally and extends "adds nothing" to `cat` (I5). |
| F11 | Incorporated | L88. |
| F12 | **Mostly; silent drop** | Dropped: "Live tests are checked with jq over the -p JSON output" (l.194), and the concern that step-3 results are written as "[MEASURED] w findings" by the session that built the gates. 3a still says "Wynik do findings.md". |
| F13 | Incorporated | 3a–3e. |
| F14 | **Partly; silent drop** | Steps 1 and 3 were re-estimated. Dropped: review-round cost, H6 weekly cost, and "keep one-off and recurring costs separate" (l.213–217). |
| F15 | **Partly; silent drop** | The pages were added and H2 is soft. Dropped: "Each run pushes a new branch, so the owner gets one more branch to merge every week" (l.222). |
| F16 | Incorporated | Road 2 and the injections. |
| F17 | Incorporated | Rule 0.4, but the rule is too narrow for the current files (B1). |
| F18 | **Partly; silent drop** | The stubs and the step 2/4 decisions are in. 1c's removal of conflicts from "the list" (L65) is not named as a CLAUDE.md decision, although review 1 l.240 says "so does 1c". |
| F19 | Incorporated | L12, L88, L47, L127. |
| M1a | Incorporated | The O0 §2 citation was removed. |
| M1b | Incorporated | With the source imprecision in citation 1. |
| M1c | **Not applied** | Citation 26. |
| M1d | **Partly** | The n=3 was added; the two denials are still both described as approval edits (citation 33). |
| M1e–M1g | Incorporated | L48, L76, L56. |
| M2–M7 | Incorporated | Stubs table, ≤10,000, "składnik", `HEAD` tree, advisory Stop, `Cap:` header. |
| M8 | Incorporated as soft | §7. No Workflow hook is specified anywhere, so "partial matching" names no mechanism. |
| M9 | Incorporated | 1b. |
| Q1–Q8 | Carried over | Plan §9 Q2–Q9. Q4's "public or private" was answered by a measurement I could not check. |

### `findings.md` entry "2026-10-11 — Hook payload probes" vs review 1 §0
n is stated ("n=1 each, so anecdotes until repeated"), and the payload bullet (P1), the SubagentStop bullet (P2) and the nested-CLAUDE.md bullet (P4) match review 1. Deviations:
1. **"Five `claude -p` probes" is wrong for P0.** Review 1: "P0 | `cat` … in this agent's Bash tool (auto mode)", and "For P1–P4 the setup was … `claude -p`". The "0.81 USD total" is P1–P4 only (0.19 + 0.26 + 0.21 + 0.15). The bullet "[MEASURED: P0 in this session's Bash tool …]" also places P0 in the author's session rather than the reviewer agent's.
2. **The title claims more than was measured.** "truncated `cat` counts as nothing": the measurement is that Claude saw a 2 KB preview.
3. **The "Consequence" sentence is an untagged design inference.** It reads "(no `persistedOutputPath`, stdout hash = file hash … keep gated files under ~28,000 chars)" with no [ASSUMPTION] tag. Its hash rule is contradicted by probe A.
4. **"adds no tokens and no content":** "no content" was measured; "no tokens" is an inference, since the stub is itself a small tool result.
5. **The SubagentStop conclusion overgeneralizes.** "a SubagentStop hook can check an agent's reads from its transcript" rests on n=1 and omits the async-write caveat in O2 §A4.

## 4. Findings on v2

### B1 — Blocking — Step 0 cannot pass its own done criterion, and its invariant rejects a perfect move
- **What is wrong.**
  1. **`kb_check.py = 0` (L51) is unreachable on verbatim content.** Step 0 moves content "bez zmiany brzmienia" and says "Nic nie dopisujemy" (L44). Yet its `kb_check.py` (L47) runs checks whose inputs don't exist yet or need content edits:
     - `Keywords:` headers, map coverage and `topics.json` validation: the generator and `topics.json` arrive in step 2 (L80);
     - `STATE.md`: generated, step 2;
     - model scope: the cleanup is 1c;
     - rule 0.4: about 130 bullets fail;
     - "brak sekcji-skrzynek": the boxes are drained in 1a.

     The only way to pass would be to switch checks off, and the plan doesn't say so.
  2. **The ID invariant fails on a perfect move.** `kb_migrate_check.py`: "każdy identyfikator faktu … występuje **dokładnie raz** w nowych" (L46). 65 IDs already appear in sections sent to different files.
  3. **The table is not "pełna" (L21).** It omits the 19 TL;DR bullets and the file headers, including `U5-31`, while the checker requires every bullet to land exactly once.
  4. **Nothing says the move is scripted.** A model retyping 142 KB is the riskiest way to run a "mechanical" step. The owner, who is not a software engineer, cannot review a 142 KB diff.
  5. **"`git diff --stat` pokazuje tylko przenosiny" is not a command result.** One file split into many shows up as deletions plus insertions.
- **Evidence.** §0 static measurements; L21, L44–51.
- **Fix.**
  - **0a:** `kb_check.py` with per-step check profiles in a committed config. The step-0 profile covers the size cap, `§` references and the migration check. Add the trusted CI (B2) and branch protection, and get them green on today's O0–O5 before anything moves.
  - **0b:** a deterministic splitter driven by a machine-readable mapping table:
    - bullet-level rows for O0 §4 and O1 §3;
    - a row, or an explicit "drop" entry, for every TL;DR and header;
    - the splitter writes the new files and the stubs.
  - **Migration invariant:** every normalized non-code line appears exactly once, and the multiset of ID occurrences is unchanged. Fenced code is skipped.
  - The owner reviews the ~120-row table, not the output.
  - Enable the tag, scope and map checks in the step that creates their inputs.

### B2 — Blocking — The server-side backstop can be rewritten by the branch it checks
- **What is wrong.** §7 (L119) says hook-script edits made via Python are caught by "CI z main i branch protection". That fails four ways.
  - (a) **The required check is matched by name.** On `pull_request` events, GitHub runs the workflow file from the PR's merge commit. A branch that edits `.github/workflows/kb-check.yml` therefore decides what "uruchamia strażnika z `origin/main`" means [ASSUMPTION: GitHub Actions semantics, not in the KB; verify on docs.github.com with the O1 curl method before step 0].
  - (b) **`kb_check.py` checks KB content only** (L47). Nothing in it looks at gate files, because F3's "fails when the diff touches gate files" was dropped.
  - (c) **Gate files are editable from any second checkout.** Anchored deny rules apply only to the live checkout: "`/p` = relative to the settings source (project/local → main working dir…)" (O2 §D4). Two examples:
    - the plan's own `git worktree add /tmp/kbtest` (L88);
    - an `isolation: worktree` agent, whose edits also skip the classifier: "protected paths (.claude/ except worktrees, …)" (O0 §4).

    Either can edit `.claude/hooks/*`, `scripts/kb_check.py` and the workflow, commit and push.
  - (d) **"Ty mergujesz" is not enforced.**
    - The session acts with the owner's GitHub identity: "proxy swaps session credential for user token" (O0 §7), and "GraphQL only PR operations" pass the proxy (O0 §7).
    - `gh` is installed and proxy-configured [MEASURED: `which gh`; environment block].
    - The plan denies only MCP write tools, and its list ends in "…" (L88).
    - So `gh pr merge`, or the unnamed MCP `enable_pr_auto_merge`, can merge a PR whose check is green.
- **Fix.**
  - **Required check:** a workflow on `pull_request_target`, so the workflow and checker come from `main`. It checks out the PR head as data only, runs with `permissions: contents: read`, and never executes PR code. It fails, listing the files, whenever the diff touches gate paths: `.claude/**` except `.claude/worktrees/`, `.github/**`, `scripts/kb_*`, `scripts/test_hooks.sh`, `knowledge/topics.json`.
  - **Bootstrap:** `main` cannot check the PR that creates the checker (0a), so the owner reviews that one by hand.
  - **Deny rules:**
    - Name every MCP write tool explicitly: `push_files`, `create_or_update_file`, `delete_file`, `merge_pull_request`, `enable_pr_auto_merge`, `update_pull_request_branch`, `create_branch`, `actions_run_trigger`.
    - Add `Bash(gh pr merge *)` and `Bash(gh api *)`. These are text rules, so they are soft; list them in §7.
  - **Read-only probe before enabling protection:** `gh api repos/<owner>/<repo> --jq .permissions`. If the token has `admin`, a session could change branch protection itself.
  - **Rewrite §7:** what is hard is "no direct push to `main`, and no merge with a red *trusted* check". Who clicks merge, and what a gate-file PR contains, is the owner's review.

### I1 — Important — The Bash "full read" rule fails for every KB file
- **What is wrong.** 3c.2 (L96) counts a Bash read as full when "`sha256(stdout) == sha256(pliku)`".
  - Probe A: `stdout` drops the file's final newline, and every KB file ends with `\n`. So a `cat` never counts.
  - The 3c.4 gate blocks everything but reads, and an auto-mode session is told by its harness to read with `cat`. It will repeat `cat` and stay blocked.
  - Review 1's alternative, `len(stdout) ≥ chars(file)`, also fails, by 1.
  - Read is fine: `file.content` was byte-identical.
- **Evidence.** Probe A [MEASURED, n=1].
- **Fix.**
  - Count a `cat` as full when `stdout == file_text` after removing trailing newlines from both, `persistedOutputPath` is absent and `interrupted` is false.
  - Resolve the path against the payload `cwd`.
  - Add probe A's payload as a `test_hooks.sh` fixture.
  - Repeat the probe in 3a (n ≥ 2) with a 27–28K-char file and with a file ending in several newlines.

### I2 — Important — Gate inputs are writable by the gated session, §7 omits concrete bypasses, and no threat model is stated
- **What is wrong.** None of the following is under deny or listed in §7.
  - **`knowledge/topics.json` configures the gates** of 3c/3d (L80, L95). It is a KB file the session edits in normal work, and working-dir edits skip the classifier (O0 §4). Dropping a stem or a topic narrows a live gate mid-session. "The model edits the check" is a documented failure mode: O0 §6 cites reward-tampering research, "it escalated into hiding non-completion".
  - **Other runtime inputs are unprotected:** `scripts/kb_build.py`, `scripts/test_hooks.sh` (which runs in CI, L92), `scripts/kb_freshness.sh` and `scripts/kb_migrate_check.py`.
  - **The gate log can be forged.** Deny catches Bash redirection but "does NOT catch … python script" (O0 §4), so `python3 -c` can append fake "full read" lines to `.claude/kbgate/`. §7's Python line covers hook scripts only, and claims CI catches them; CI never sees a gitignored log.
  - **Nested runs from the repo root can run gate-free.** Any of these gives a run that can edit and push with no gates; §7 lists only "`-p` spoza korzenia":
    - `claude -p --settings '{"disableAllHooks": true}'` (O2 §A1: "One run");
    - `--setting-sources user` (O0 §4: no project deny rules);
    - `KBGATE_OFF=1 claude -p` (the kill-switch variable, L88).
  - **`gh` and unnamed MCP write tools** (B2).
  - **Topic matching is lexical.** A task phrased without a keyword ("PreToolUse", "matcher", "exit 2", "zaczep") is ungated. §7 says so only for workflow agents.
  - **There is no sandbox.** `bwrap` is absent [MEASURED], so O0 §8 applies: "Without sandbox deny is not a boundary". Rule 0.1 lists the hard mechanisms without the sandbox and never says it is unavailable.
- **Fix.**
  - State the threat model in §0: the gates stop lazy shortcuts. Deliberate circumvention by the session cannot be prevented locally without a sandbox; it is caught only server-side (B2) or by the owner.
  - Put every file a hook reads at runtime under deny, including `topics.json`, and have CI flag changes to them.
  - Add the items above to §7.

### I3 — Important — The read gates can deadlock a session or loop an agent
- **What is wrong.**
  - **Subagent tool calls get blocked.** 3c.4 blocks "każde narzędzie" until the main session's reads are logged. PreToolUse also fires inside subagents (O2 §A1), nothing exempts events that carry an `agent_id`, and subagent reads do not count for the main session (L96). A background agent still running when a new prompt is gated is blocked with no way out.
  - **A missing required file blocks everything.** If a required file no longer exists, for example after 1b splits `docs-index.md` (L15), every tool is blocked, including `git commit` and `git push`. The kill switch needs a new session (L88). The work is then stranded in a session that cannot push, and lost when its VM is reclaimed (O0 §7: "ignored and unpushed files then most likely lost [ASSUMPTION]").
  - **3d gates every agent type except Explore** (L103).
    - `claude-code-guide` is a Haiku agent for live docs (O1 §2), yet it would be forced to read local KB files.
    - Custom agents without Read or Bash cannot satisfy the gate at all.
    - 3d doesn't say how `stop_hook_active` is handled, and the 8-block cap is documented for Stop only (O2 §A5). If the cap doesn't apply to SubagentStop, such an agent loops until the budget runs out.
  - **Worktree agents are never credited.** `isolation: worktree` agents read `.claude/worktrees/<n>/knowledge/…`, and "`${CLAUDE_PROJECT_DIR}` … does not follow worktrees" (O2 §A7). A logger keyed on `${CLAUDE_PROJECT_DIR}/knowledge/` never credits those reads.
- **Fix.**
  - The main-session gate ignores events with an `agent_id`.
  - A missing required file means allow, with a loud warning; CI validates `topics.json`.
  - Always let `git add/commit/push` through.
  - Gate an allowlist of agent types: general-purpose plus named custom agents.
  - Normalize paths to repo-relative.
  - Add "does the cap apply to SubagentStop?" to 3a.
  - Run 3c/3d log-only for at least 2 real sessions before they block anything.

### I4 — Important — The lock lands before the gates are built
- **What is wrong.** 3b merges the deny rule on `Edit(/.claude/hooks/**)` (L88) before 3c, 3d and 3e add about six more hook scripts. From then on there are only two ways to build them:
  - the owner writes every script and fix by hand on GitHub (Q4, L134). This contradicts "Ja: wszystko inne" (L127), and hand-applying iterative hook fixes is the most error-prone task in the plan for someone who is not a software engineer;
  - or the session develops them in a second checkout, which turns the B2(c) bypass into standard procedure.
- **Fix.**
  - Build and test the 3b–3d gates with the deny rules off, or in a dev branch tested from `/tmp/kbtest`.
  - Make the "lock" the last sub-step: deny rules, ConfigChange and `topics.json` protection, merged after the gate tests pass.
  - Reword Q4: later gate changes go through a PR that CI flags and the owner reviews.

### I5 — Important — The forced-reading gate (H4) neither measures the owner's failure nor covers its long-session form
- **What is wrong.**
  - **The design rules out re-reads by an untested argument.**
    - The owner's complaint: the main session stops returning to the docs after the first message because it "thinks it remembers".
    - v2: "Parametru „N tur" nie ma: drugi Read niezmienionego pliku zwraca stub bez treści (P3), więc wymuszanie powtórki bez kompakcji i bez zmiany pliku nic nie wnosi" (L99).
    - That holds for Read. For `cat`, the auto-mode default, a re-read puts a fresh copy near the end of the context, and O0 §1 notes "Quality: degrades gradually with fill (context rot), no numeric threshold".
    - Whether a fresh copy improves answers is unmeasured, yet the design rules it out.
    - With compaction at about 784K tokens (O0 §1), one read can cover hours.
  - **No step measures the problem or the result.** Nothing measures a baseline (how often sessions answer a KB question today without reading the file) or an outcome. 3c's done criteria count blocks, not correct answers.
- **Fix.**
  - Run 3c log-only first; that measures the baseline at no extra cost.
  - Before deciding on re-reads, add an A/B probe: the same follow-up question asked K prompts after a read, with and without a forced `cat` re-read, graded against the file, n ≥ 3 per arm.
  - Until then, list "no forced re-read between compactions" in §7 and ask the owner (§6 Q2).

### I6 — Important — Navigation gets worse between step 0 and step 2/4 (decide before step 0)
- **What is wrong.**
  - After step 0, O0–O5 are stubs (L38).
  - The root CLAUDE.md still says "Read in full, once per session, before the first substantive answer" for O0, and keeps routing by the O-file table until step 2 (L80) or step 4.
  - A session then reads a 9-row stub and must open several files to get what O0 gave. There is no map until step 2.
  - Steps 1a–1c (three sessions, plus merges) all run in this state.
- **Fix.** Either make a minimal routing edit to the root CLAUDE.md in step 0, as a separate owner decision (CLAUDE.md role item 4), or merge step 2's map in the same window as step 0.

### I7 — Important — Generated files are non-deterministic, and step 2 depends on step 3e
- **What is wrong.**
  - **CI's rebuild-and-diff turns red on its own.** `STATE.md` is "generowany: wersja CC, data, liczba linków i sha256 `llms.txt` …" (L24), and CI "odbudowuje sekcje generowane, porównując z commitem (różnica = błąd)" (L48). If the generator reads `claude --version`, today's date or the live `llms.txt`, the rebuild differs on any later day or after any upstream change. CI then turns red on every PR, and with branch protection binding the admin, nothing merges.
  - **Step 2 uses a step-3e script.** Road 5 injects "mapę i raport świeżości" (L78), but `kb_freshness.sh` arrives only in 3e (L105).
  - **Step 2 needs an unlisted owner action.** It adds SessionStart and SubagentStart hooks to `.claude/settings.json`, a protected path, without listing that action.
- **Fix.**
  - The generator reads only committed inputs, for example the `As of:` headers and a committed inputs file. Live values go to the freshness report, never to a file CI diffs.
  - Until 3e, road 5 injects the map only.
  - List the owner's settings action under step 2.

### I8 — Important — Costs are internally inconsistent and incomplete
- **What is wrong.**
  - **Step 1's figure contradicts its own anchors.** Step 1's per-unit anchors (L68) add up to:
    - 13 files × 3.6–8.1 USD = 47–105 USD;
    - 33 pages × 0.5–1 USD = 16.5–33 USD;
    - one triage session = 3.6–8.1 USD;
    - total: **67–146 USD**.

    The plan states 40–90 USD.
  - **Three costs review 1 F14 asked for still have no figure:**
    - the review rounds (findings 2026-10-11: an Opus max agent used 318,616 tokens; O0 §5: Fable costs 2.5× Opus);
    - the weekly Routine;
    - step 4.

    One-off and recurring costs are still mixed together.
  - **The recurring overhead is larger than step 4's metric shows.** The ≤9,500-char map is injected:
    - at SessionStart;
    - again as the nested `knowledge/CLAUDE.md` on the first touch of `knowledge/` (P4);
    - into every subagent via SubagentStart, at ≈3.5k tokens each [ASSUMPTION: 2.7 B/token, O0 §1].

    Step 4's criterion (L113) compares only root-CLAUDE.md tokens against 3,752.
- **Fix.**
  - Give each step a per-unit table (unit × count × anchor).
  - Add a "recurring" line per session, per agent and per week.
  - Set step 4's metric to the total injected start tokens of a main session and of a general-purpose agent, measured before and after.

### I9 — Important — Several done criteria are not commands with exit codes
- **What is wrong.**
  - **3e has no done criterion at all** (L105).
  - **Step 4's criterion** is a Read-counter measurement made inside a session, against a baseline taken on a different file (citation 34).
  - **Step 0's "`git diff --stat`"** is a judgment, not a check.
  - **The `omitClaudeMd` probe** (L82) has no pass threshold.
  - **The live tests in 3b–3d** say "n=2" or "n ≥ 2" but drop the `jq` assertions review 1 F12 asked for.
- **Fix.**
  - **3e:** `kb_freshness.sh` exits 0, its output contains the `STATE.md` version line, and a fixture tests its parser.
  - **Step 4:** re-measure the committed CLAUDE.md first; a script then checks the recorded numbers.
  - **Live tests:** `jq` assertions with an exit code per test.

### Minor
- **m1** — `updatedInput` lists seven fields (L103). Any other field would be silently dropped; for example, O3 §6 says "A *named* Agent call launches a teammate". Instead, copy the whole `tool_input` object and change only `prompt`.
- **m2** — The conflict list is planned in two places, L23 (`knowledge/CLAUDE.md`) and L37 (`recheck-and-conflicts.md`), and it stays in the root CLAUDE.md until step 4: three copies. Keep one.
- **m3** — 1b writes a sha256 and a size for each of about 33 pages into `docs-index.md` (L62). That file is the one closest to the cap and one the gates may force Claude to read in full. Keep the hashes in a separate machine-only file.
- **m4** — The cap is defined with `wc -m` (L15). In this container's POSIX locale `wc -m` counts bytes; on a UTF-8 CI runner it counts chars. Define the cap once, in `kb_check.py`, as `len(text)`.
- **m5** — The section parser must skip fenced code:
  - O1 l.166 is a `##` line inside a code block;
  - O2 §D5 has `# API rules` and YAML bullets inside code.
- **m6** — Mode mismatch:
  - `kb_check.py` checks the `HEAD` tree (L47).
  - Step 4's soft rule, "run `kb_build.py`, then `kb_check.py` after editing `knowledge/`" (L111), expects it to check uncommitted edits.
  - Add a working-tree mode.
- **m7** — O1 §2 "Tool limits" (the Read and Bash limits, Glob/Grep, WebFetch) would go to `docs-index.md` (L36). By the plan's own naming rule, "how much of a `cat` does Claude see" belongs in `context-window-and-read.md`.
- **m8** — §1 moves "Reviewing designs" from the root CLAUDE.md to `design-rules.md` (L35) without saying in which step. That move is a CLAUDE.md change and needs the owner's decision.
- **m9** — Rollback (L12) covers git only:
  - Branch protection, the cloud environment variable and the Routine are owner settings with their own undo steps.
  - Pushing tags from a session is unmeasured; O0 §7 measured only branch push and deletion.
- **m10** — 3b(c)'s advisory message (L92) needs a named channel. On Stop, plain stdout goes to the debug log (O2 §A6); `systemMessage` reaches the owner.
- **m11** — 1c (L65) removes two conflicts from "the list". Until step 4 that list lives in the root CLAUDE.md, so this is a CLAUDE.md edit that needs a separate owner decision (F18).
- **m12** — Scope additions to confirm with the owner:
  - the 13 PL API pages in 1b (§6 Q7);
  - `STATE.md` B/token and `llms.txt` hash fields that no check consumes.

## 5. Omissions (a careful engineer would insist on these before step 0)
1. **A scripted move and a 0a/0b split** (B1): guard first, furniture second.
2. **A written threat model** (I2): it decides how much of step 3 is worth building.
3. **An inventory of GitHub write paths** and a read-only probe of the token's permissions (B2):
   - `git push`;
   - `gh pr merge` and `gh api`;
   - every MCP write tool;
   - tags.
4. **A log-only shadow mode** for 3c/3d, which doubles as the missing baseline (I3, I5).
5. **The KB approval unit at this scale.**
   - CLAUDE.md "Updating the KB" says: "propose the exact change (file, section, old → new, tag, date) and apply it after a yes".
   - Step 1 makes hundreds of edits (372 triage rows, 33 pages).
   - The plan must say what counts as the "yes", for example the owner's merge of a step's PR after reading its triage file. Otherwise step 1 either breaks the rule or needs hundreds of approvals.
6. **Promote measured findings into the KB** as part of step 1, with approval:
   - P0–P4 and probes A–C belong in `hooks.md` as [MEASURED];
   - findings 2026-10-06 on Glob/Grep.
7. **A mechanism for the recursive-grep shortcut.**
   - The plan gives up on `grep -r … knowledge/` (L75).
   - A PostToolUse(Bash) hook can return `additionalContext` with the map lines for the searched word when a command greps `knowledge/` (O2 §A5: PostToolUse output includes `additionalContext`).
   - Measure it in step 2.
8. **Local use.**
   - On a PC without `python3`/`jq`, the push handler with `onFailure: "block"` blocks every push. findings 2026-10-11 warns about exactly this.
   - Either guard on `CLAUDE_CODE_REMOTE` (O2 §A7) or declare the gates cloud-only.
9. **3a additions:**
   - repeat probes A–C (n ≥ 2);
   - ConfigChange blocking semantics and its excerpt-only fields;
   - whether PostCompact fires on auto-compaction (its input is excerpt-only, `compact_summary`*);
   - the cap on SubagentStop;
   - the token permissions.
10. **SessionStart network calls** (the freshness check) run in every session and every `-p` test. Cache the result once a day and add a short timeout.

## 6. Open questions only the owner can answer
1. **Threat model.** Should the gates stop only lazy shortcuts, or also deliberate circumvention by the model? The second cannot be enforced locally (no sandbox: `bwrap` is absent) and pushes the design toward server-side checks and your PR review.
2. **Re-reading between compactions.** Do you accept "one full read per compaction" (the plan's design), or do you want forced `cat` re-reads every K prompts? Those cost more tokens and their value is unmeasured. I would measure first (I5).
3. **Plan Q4, reframed.** Deny rules do not stop Claude from changing gate files through another checkout. The real question: will you review every PR that touches gate files, which CI would flag, and may Claude develop the gate scripts that way during 3c–3e (I4)?
4. **Plan Q5, reframed.** Branch protection that binds you also means you cannot merge anything while CI is broken or GitHub Actions is down, without first switching protection off. Do you accept that?
5. **Interim routing.** Do you approve a minimal root-CLAUDE.md routing edit inside step 0, or accept weaker routing until step 2 (I6)?
6. **KB approval unit.** Is your merge of a step's PR, after reading its triage file, the "yes" that CLAUDE.md "Updating the KB" requires?
7. **Scope of 1b.** The 13 PL pages cover API-side compaction, the memory tool, context editing, tool search and cache diagnostics. Keep them only if you build directly on the API; dropping them saves about 6–13 USD [ASSUMPTION: plan's 0.5–1 USD per page].
8. **Routine.** A new branch to merge every week, or one standing branch or PR that the Routine updates?
