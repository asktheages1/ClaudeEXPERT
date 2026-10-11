# Review 2 (Fable 5.1, xhigh): KB restructure plan v2 (`PLAN.md`, 2026-10-11)

Reviewer: independent agent, Fable 5.1 (`claude-fable-5-1`), effort set by the caller. I did not see the conversation that produced the plan. Read in full before judging: root `CLAUDE.md`; `knowledge/O0-how-claude-works.md`; O2 §A, §D, §E and "Verify live"; O3 header, "Deltas", §5, §7, §8, "Verify live", "New URLs"; O1 header, §0, §2–§5, "Check again"; O5 header, "Deltas", §4, §5; O4 §5–§6; all of `findings.md` and `exceptions.md`; `REVIEW-1-opus-xhigh.md`; `PLAN.md` v1 (commit 8b0add4) and v2 (9bee091).

## 0. Measurements made for this review
All local except one nested `claude -p` (0.196 USD, inside the 1.5 USD budget). CC 2.1.296 in this container. Each is n=1 unless stated.

| ID | What | Result [MEASURED, 2026-10-11] |
|---|---|---|
| R0 | `cat` of the 36,589-byte `REVIEW-1-opus-xhigh.md` in this agent's Bash tool (auto mode) | "Output too large (35.7KB). Full output saved to … Preview (first 2KB)". Reproduces review 1 P0 (combined n=2). This agent's system context also carries the "While auto mode is active … read files with cat, head, or sed -n … rather than … Read" instruction (n=2 with review 1). |
| R1 | Fact-ID multiplicity in O0–O5: `grep -ohE '\b[TU][0-9][a-z]?(-S)?-[0-9]+\b' \| sort \| uniq -c` | 425 occurrences, 350 unique IDs, 67 IDs occur 2–3× (e.g. `U5-01`, `U4-01`, `T4-15`, `T4-09`, `T3-29` ×3). Review 1's 351 vs my 350 is a regex edge; immaterial. |
| R2 | Content that is not a `- ` bullet: `grep -c '^\|'` and code fences per file | Table rows: O1 69, O2 125, O3 59, O4 13, O5 6 (272 total); code-fence lines: O1 2, O2 32. Numbered items: O1 4, O2 20. Bullets exactly duplicated across files: 0. |
| R3 | Bullets with no `[` tag anywhere on the line | O0 36, O1 39, O2 138, O3 32, O4 53, O5 33. O1's section headings carry no tag at all (`## 2. LIVE LOOKUP MECHANISMS`), so the heading-inherits rule does not rescue O1. |
| R4 | `wc -m` under this container's locale (`LC_CTYPE=POSIX`) vs `LC_ALL=C.UTF-8` on O0 | 39,247 vs 39,023; `wc -c` = 39,247. `wc -m` counts bytes under POSIX. |
| R5 | `git ls-files \| grep -iE 'json\|fixture\|\.sh$\|\.py$'`; `.gitignore` | No JSON, script or fixture files tracked; no `.gitignore`. The P1–P3 payloads the plan names as fixtures are not in the repo. |
| R6 | Nested `claude -p` from the scratchpad (not the repo): `--model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns 6 --max-budget-usd 0.5 --settings hooks.json`, hooks: SubagentStart (returns `hookSpecificOutput.additionalContext` with marker `KBMARK-7731`), PostToolUse(Bash) (dumps stdin), SubagentStop (copies `agent_transcript_path`). Main ran `cat kb/x.txt` (28 bytes, 2 lines, UTF-8 arrows, trailing newline), then an Explore subagent Read `kb/y.txt`. Cost 0.196 USD, 4 turns, `modelUsage` keys `claude-opus-5-5`, `claude-haiku-5-5`. | (a) The Explore transcript's line 3 is `{"type":"attachment","attachment":{"type":"hook_additional_context"…}}` containing the marker, right after the first user message (line 1) and a `hook_success` attachment (line 2); the agent also answered "YES" and quoted it. **SubagentStart `additionalContext` reaches an Explore subagent.** (b) Bash `tool_response` keys: `interrupted, isImage, noOutputExpected, stderr, stdout`; `persistedOutputPath` absent for small output; `stdout` = file content **without the trailing newline**: 23 chars vs 28 file bytes; `sha256(stdout)` ≠ `sha256(file)`; equal only after appending `\n`. (c) SubagentStart payload keys: `agent_id, agent_type, cwd, hook_event_name, prompt_id, scratchpad_dir, session_id, transcript_path` (no prompt, no `permission_mode`). SubagentStop adds `effort`, `last_assistant_message`, `background_tasks`, `session_crons`, `stop_hook_active`. |

## 1. Verdict
**Not ready to start step 0; fixable in one more revision.** v2 is a real improvement and touches every review-1 item (36 of 36; 4 only partially, none silently dropped as a whole), its citations are almost all accurate, and the direction (deterministic gates, one `topics.json`, CI, stubs, step 0 as a pure move) is right. But step 0's own done criterion is unattainable as written: `kb_check.py` is specified to run checks whose inputs do not exist until step 2 (`topics.json`, generated `Keywords:`) or whose content step 1 removes (model scope), and the preservation check would fail on first run because fact IDs occur 425 times for 350 IDs and 272 table rows plus all code blocks are outside its "bullets" definition. The one mechanism the plan still treats as hard outside the session, CI from `origin/main`, runs the workflow file of the branch it checks, so it remains bypassable by the route the plan itself lists as soft; and the Bash "full read" criterion (`sha256(stdout) == sha256(file)`) fails on every file because `stdout` drops the trailing newline (R6b).

**Top 5 required changes (ranked):**
1. **Phase the checker and make step 0's criterion attainable** (B1, B2): each check declares the step it starts in (`--phase N`, recorded in `STATE.md`; CI runs that phase); step 0 runs only: cap, headers, stub targets, migration preservation. The preservation check compares the multiset of all normalized non-blank, non-heading lines (bullets, table rows, code lines, paragraphs) old vs new, and per-ID occurrence counts, not "exactly once". Do the move with a script driven by a line-range table, not by the model retyping 142 KB.
2. **Make CI hard or stop calling it hard** (I1): run the check from the base branch's workflow definition (`pull_request_target` or equivalent, verify on GitHub docs before step 0), run `kb_check.py` from `origin/main` against the PR tree as data, and fail when `git diff origin/main...HEAD --name-only` touches `.claude/**`, `scripts/kb_*.py` or `.github/workflows/**`. Restore review 1's "diff touches gate files → fail" rule.
3. **Fix the "full read" definition and the cap unit** (I3, I4): Bash counts only when the command is exactly `cat <one path>` (no pipes, `;`, `&&`), `persistedOutputPath` is absent and `stdout.rstrip("\n") == file_text.rstrip("\n")` (UTF-8 text compare, path resolved against `cwd`); cap files in **bytes** (`wc -c ≤ 28000`), because `wc -m` is locale-dependent (R4) and the truncation unit is unverified.
4. **Separate hooks from step 2** (I2): routes 4–5 are hooks and need `.claude/settings.json`, the test harness and the kill switch from step 3. Either step 2 ships only routes 1–3 (map, `topics.json`, generator, nested `CLAUDE.md`) or it explicitly becomes the first hook step with the harness. Add to 3a: SubagentStart injection n≥2 (R6a shows it works), Bash stdout fidelity, deny on `git rm/mv/checkout` of gate files.
5. **Name model and effort per step, finish the cost table, and complete §7** (I5, I6, I8): every executing session gets `model`/`effort`/`--max-budget-usd` and the cost line says which model it assumes (Fable = 2.5× Opus, O0 §5); add review rounds and the Routine's weekly cost; add to §7 the bypasses not listed: forging `.claude/kbgate/` with `python3 -c`, nested `claude -p` from the repo root counting as main-session reads (`session_id` inherited, no `agent_id`), git plumbing on gate files, read-first gate failing open on hook error, SubagentStop cap.

## 2. Citation audit
Every KB, findings and review citation in PLAN.md v2 was checked against the text. "Correct" = wording and tag match; quotes given where they do not.

| # | PLAN v2 citation | Verdict | Actual text / note |
|---|---|---|---|
| 1 | §0.1 O0 §8 conclusions are `[ASSUMPTION]` from O0 §4 facts `[SOURCE: CC permissions.md, hooks.md]` | correct | O0 §8: "Each point is an [ASSUMPTION] derived from facts above"; O0 §4 tags: "[SOURCE: CC permissions.md, permission-modes.md]", "[SOURCE: CC hooks.md]". M1b fixed. |
| 2 | §0.3 "`claude -p` bez `--model` leci na Sonnet 5.5", O0 §5 [MEASURED] | correct | O0 §5: "Nested `claude -p` without `--model` ran in cloud on Sonnet 5.5 medium, not session model (cause [ASSUMPTION])". Measured in the cloud, nested; cause unknown. Fine as a trap. |
| 3 | §0.3 Haiku generates titles, drives `claude-code-guide`, judges `/goal` (O0 §5, O1 §2, O3 §7) | correct with caveat | O0 §5 "calls Haiku 4.5 for title" (R6 and review P3 show `claude-haiku-5-5` today); O1 §2 "`claude-code-guide` agent. Model Haiku"; O3 §7 says "small fast model (`ANTHROPIC_DEFAULT_HAIKU_MODEL`)", not "Haiku" outright. |
| 4 | §0.4 "znacznik w nagłówku sekcji obejmuje punkty pod nim (tak robi dziś O2)" | correct | O2: "### A1. Where to define, scope [S:hooks]". Note O1 does no such thing (R3). |
| 5 | §0.5 O1 §2: `BASH_MAX_OUTPUT_LENGTH` default 30,000, 2 KB preview | correct | O1 §2: "inline output ~30,000 chars; larger output goes to a file with a 2,000-char preview. `BASH_MAX_OUTPUT_LENGTH` … default 30,000, hard cap 150,000". |
| 6 | §0.5 Read limit 25,000 tokens, O0 §1 [CODE] | correct | O0 §1: "Read: 25,000 tok. per call, file 256 KB [CODE: Read limits]". |
| 7 | §0.5 "w trybie auto Claude czyta pliki przez `cat`" | overstated for the main session | Measured only in Agent-tool subagents' system context (review 1 F1; this agent, R0). Not measured for the owner's main window. The 28 k cap is justified either way. |
| 8 | §0.5 "przy plikach angielskich do 28 000 znaków [limit Read] nigdy nie jest osiągany" | correct | O0 §1 worst measured ratio "short lines with numbers 1.55" B/token → 18.1 k tokens < 25 k; English md 2.66–2.78; O0 itself 2.17 (17,754 tok at 38,565 B). |
| 9 | §1 `knowledge/CLAUDE.md` ≤ 9,500 chars, hook injection limit 10,000 (O2 §A6) | correct | O2 §A6: "10,000-char limit per `additionalContext`/`systemMessage`/`initialUserMessage`/stdout; overflow goes to a file and Claude gets a 2,000-char preview". Note: the nested-CLAUDE.md route is not a hook and has no such limit; the limit binds routes 4–5. |
| 10 | §1 "87 sekcji" | correct | R1/R2: 9+14+31+14+10+9 = 87 `##`/`###`. |
| 11 | §2 "141 939 B, 627 punktów, 87 sekcji, 351 identyfikatorów faktów [MEASURED, recenzja]" | correct counts, wrong use | Bytes 141,939, bullets 627, sections 87 confirmed; IDs 350 unique by my regex. But 425 occurrences (R1): "występuje **dokładnie raz** w nowych" cannot hold. See B2. |
| 12 | §2 branch protection must include administrators, O0 §7 [SOURCE: github/docs] | correct | O0 §7: "branch protection by default doesn't apply to admin; in private repo only on paid plans [SOURCE: github/docs …]". M1e fixed. |
| 13 | §2 "Repo jest publiczne [MEASURED: GitHub API `visibility: public`]" | not re-verified | This audit had no web access. |
| 14 | §2 "Uruchamia strażnika z `origin/main`, nie z gałęzi" | missing caveat | Review 1 F3 tagged the GitHub mechanics "[ASSUMPTION: verify]"; v2 states it as settled and drops the second half of F3 point 1 ("the branch's own workflow file"). See I1. |
| 15 | §3 1a `allow_large` in this session's Read schema [MEASURED] | correct | Present in this session's Read schema too. |
| 16 | §3 1b O2 "documentation only", partly from excerpts | correct | O2 header: "sources: documentation only, nothing measured live"; `[S:hooks*]` rows; A5 "* = from excerpts". |
| 17 | §3 1b sha256 of fetched `.md` (O1 §3) | correct | O1 §3: "Docs pages carry no date. For comparisons, store `sha256sum` of the fetched `.md`." |
| 18 | §4.2–4.3 nested CLAUDE.md on Read, Write/Edit, single-file `cat/head/tail/sed -n/grep` (O0 §2 [SOURCE] [MEASURED: Read] [CL 2.1.293]); P4 for `cat` and Explore Read, n=1 | correct | O0 §2 verbatim; P4 as in review 1 §0. M1f fixed. |
| 19 | §4.4 SubagentStart injects via `additionalContext` (O2 §A5) | correct, now measured | O2 A5 SubagentStart output "`additionalContext`" (full-read row, no `*`). R6a: reaches an Explore subagent, n=1. |
| 20 | §4.5 SessionStart `compact` re-injects context (O0 §6 [SOURCE: CC hooks-guide.md]) | correct | O0 §6: "A: SessionStart hook with compact matcher injects context [SOURCE: CC hooks-guide.md]". |
| 21 | §5 header: O2 §A1 hooks fire in subagents (+P1); §A6 exit 2 not overridable; §A5 Stop/SubagentStop block; `updatedInput` replaces whole input | correct | O2 A1 "Settings, managed and plugin hooks also fire inside subagents"; A6 "Not overridable even by `permissionDecision:"allow"`"; A5 "Stop … yes; Claude continues", "SubagentStop … yes; subagent does not finish", "`updatedInput` (replaces whole input)". |
| 22 | §5 "nie `Edit(/.claude/**)` w całości: złapałoby worktree agentów" | overstated | findings 2026-10-11: "would also catch agent worktrees in `.claude/worktrees/` [ASSUMPTION: path matching unmeasured]". v2 presents it as fact. |
| 23 | §5 deny by bare name removes the MCP tool (O2 §D4) | correct | O2 D4: "Deny with a bare name removes the tool from context"; "Deny/ask accepts `mcp__*`". |
| 24 | §5 `ConfigChange` blocks `project_settings`/`local_settings` (O2 §A5) | correct, excerpt caveat | O2 A5 ConfigChange: "yes (except `policy_settings`)", input "`source`, `file_path?`*" (excerpt-only). Semantics of "block" (change not applied?) unverified; add to 3a. |
| 25 | §5 hooks run in parallel (O2 §A7) | correct | "All matching hooks run in parallel." |
| 26 | §5 env vars visible to the environment's users (O0 §7) | correct | T6-44. |
| 27 | §5 `-p` from the repo root runs project hooks without asking (O0 §4) | correct | "-p runs repo hooks without trust [SOURCE: CC hooks.md]". |
| 28 | §5 nested `-p` "dziedziczy `session_id` i katalog scratchpad rodzica (próba P1)" | half overstated | P1 measured the inherited `session_id` and that `scratchpad_dir` was identical across the six events of one run. "Same scratchpad as the parent" was review 1's "[ASSUMPTION from the measured path pattern]" (F11). |
| 29 | §5 3a: content > 5,000 tokens does not return after compaction (O0 §1) | correct | O0 §1 "(>5,000 tok. path only)". The "up to 5 files" caveat (M1c) is irrelevant for files above 5 k. |
| 30 | §5 3c.4 "Stop działa po [odpowiedzi], O2 §A5" | correct | O2 A5 Stop: "end of Claude's reply". |
| 31 | §5 3c.5 8-block cap (O2 §A5) | correct | "After a Stop hook blocks 8 times in a row with no tool call from Claude in between, Claude Code overrides it". |
| 32 | §5 3d P2: transcript at SubagentStop held the first message and Read calls | correct (n=1) | Review 1 §0 P2. R6 adds n=2 for "first user message present at SubagentStop". |
| 33 | §6 findings 2026-10-06: "2 odmowy przy zapisie zgody na merge, 3 zwykłe edycje przepuszczone" | slightly wrong | findings: the two denials were (1) "editing CLAUDE.md to record a standing approval to merge" and (2) "fast-forwarding `main` with a branch that changes CLAUDE.md". Only the first was a "zapis zgody". n=3 allowed edits: correct (M1d fixed). |
| 34 | §6 CLAUDE.md today 3,752 Read-counter tokens (findings 2026-10-11) | correct | "Expert 9,881 B → 3,752 tok (2.63)". |
| 35 | §6 CLAUDE.md change takes effect next session (O0 §2) | correct | "Editing CLAUDE.md in session has no effect until /compact, /clear or restart". |
| 36 | §7 deny does not catch python scripts or commands inside a bash script (O0 §4) | correct | "does NOT catch grep -r ., python script or commands inside bash script [MEASURED …]". |
| 37 | §7 multi-repo sessions and `-p` outside the root get no project hooks/rules (O0 §4, §7) | correct | T2b-39/40/41, T6-22..26. |
| 38 | §5 cost anchor "0,15–0,26 USD za trywialny `-p` na effort low" | correct | Review 1 §0: 0.15, 0.19, 0.21, 0.26 USD. R6: 0.196. |
| 39 | §3 cost anchor "findings 2026-10-08 … 3,6–8,1 USD" | correct | "3.56–8.14 USD list price per file (mean 5.70, reviewer included)". |
| 40 | §0.3 "Lista „dwa najlepsze" jest w `STATE.md`, skrypt sprawdza resztę" (O0 §5 models) | undefined, see I7 | O0 §5 contains Sonnet/Haiku *measurements* that justify the two-model rule; no marker syntax is defined for "tabela, pułapka, składnik". |

### 2b. `findings.md` entry "2026-10-11 — Hook payload probes" vs review 1 §0
Faithful in substance: every number, field list and caveat matches review 1 §0 (0.81 USD, n=1 each, CC 2.1.296, `--settings` hooks, the P1 field lists, P2's 15 lines, P3's `file_unchanged`, P4's `nested_memory` for `cat` and Explore, `omitClaudeMd` left unverified). Two slips:
- The lead sentence says "Five `claude -p` probes"; review 1 §0 says P0 ran in "this agent's Bash tool (auto mode)" and only "For P1–P4 the setup was … `claude -p`". The bullet's own tag ("[MEASURED: P0 in this session's Bash tool, P2 in nested `-p`]") is right; the lead is not.
- "keep gated files under ~28,000 chars" sits inside a `[MEASURED]` bullet as a "consequence". It is an inference (review 1 F9), not a measurement; tag it `[ASSUMPTION]`.
No claim goes beyond what was measured; n is stated.

## 3. Review-1 incorporation audit

| Item | Status in v2 | Where / note |
|---|---|---|
| F1 full-read from `tool_response` | incorporated | §0.5, §3c.2 (Read fields; Bash sha; `agent_id` excluded; `file_unchanged` rule). Bash criterion itself is wrong as written (I3). |
| F2 mechanical step 0; mapping gaps | incorporated | §2 step 0; §1 table adds O1 §0/§3/§4 → `docs-index`, O2 §D6 → permissions, O2 §E → recheck, O5 §5 → models, four agent bullets → agents; stubs. Preservation check mis-specified (B2). |
| F3 gates protected from the session | partially | §5: hooks in `.claude/hooks/`, exact deny paths, ConfigChange, checker from `origin/main`, admin-inclusive protection, residual python risk in §7, "CI cannot be bypassed" claim removed. **Dropped:** "the branch's own workflow file" (F3 point 1) and "CI … fails when the diff touches gate files". See I1. |
| F4 deny GitHub MCP write tools | incorporated | §5. |
| F5 `onFailure: "block"` only on `if: "Bash(git push *)"`; emergency route | incorporated | §5, §3b (a)/(b), kill switch. |
| F6 Stop gate: `stop_hook_active`, cap, after-answer, PreToolUse read-first, direct injection | incorporated | §3c.4–3c.6, §7 cap listed. |
| F7 match `last_assistant_message`, K prompts, Polish stems, ≤3 files, automatic turns | incorporated | §3c.1, §3c.5; automatic turns → §9 Q7. |
| F8 agent gate (a–e) | incorporated | §3d (soft line; copy all fields; transcript route primary; SubagentStart injection; Explore ungated in §7); `updatedInput`/classifier probe in 3a. |
| F9 28,000-char cap | incorporated | §0.5 (`wc -m`; see I4), 12–20 KB target, `docs-index` split, ≤9,500 for injection. |
| F10 `file_unchanged`, drop N | incorporated | §3a probe, §3c.2, §3c.5 ("Parametru „N tur" nie ma"). |
| F11 state location, test collisions, `O_APPEND` | incorporated | §5 (`.claude/kbgate/`, worktree tests, namespace, one-line appends). Key still `session_id` (I5b). |
| F12 done criteria as commands | partially | 1a 372 rows, 1b sha rows, 1c advisory reviewer, 2(b) ≥4/5 via `jq`, `test_hooks.sh`, step 4 counter. **Dropped:** "Step 3 results are written as [MEASURED] by the same session that built the gates" — v2 still has the builder session measure its own gates; 3e has no criterion (I9). |
| F13 split step 3 | incorporated | §5 3a–3e. |
| F14 costs | partially | Step 1 → 40–90 USD with per-unit anchors; step 3 → 15–30. **Not estimated:** review rounds (§9 Q9 says "plus recenzje" only), H6 weekly cost; H4 steady state deferred to 3c (acceptable). No model named for any cost line (I8). |
| F15 Routine pages, H6 later, H2 soft | incorporated | §3 1b (`routines`, `scheduled-tasks`), §3e, §7. |
| F16 greppable map | incorporated | §4 route 2. |
| F17 heading tags, parent bullets | incorporated | §0.4. Still fails on O1 (B1b). |
| F18 stubs; CLAUDE.md edits as separate decisions | partially | Stubs until step 4; §4 and §6 flag CLAUDE.md edits. **Not flagged:** 1c removes two items from the conflict list, which lives in root CLAUDE.md until step 4 (CLAUDE.md role 4; "never resolve silently"). |
| F19 rollback, kill switch, generator SPOF, who does what, `-p` from a worktree | incorporated | §0.2 tags, §5 kill switch, §2 H1 `topics.json` validation + CI rebuild diff, §8, §5 worktree. |
| M1a Explore "czyta wycinki" O0 §2 | incorporated | Citation removed (§3d wording without O0). |
| M1b O0 §8 tag | incorporated | §0.1. |
| M1c 5-file caveat | incorporated (moot) | Post-compaction argument for the cap dropped; 3a cites only the >5 k rule. |
| M1d n=3 allowed edits | incorporated | §6 (second denial mis-described, citation #33). |
| M1e admin exemption | incorporated | §2. |
| M1f `cat` nested CLAUDE.md [CL] until P4 | incorporated | §4.3. |
| M1g `allow_large`, `autoCompactWindow`, `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` | incorporated | §3 1a. |
| M2 old-name table too big for the map | incorporated | Stubs hold the 87-row table. |
| M3 10,000-char output caps | incorporated | §1, §4.5. |
| M4 "component" marker; Sonnet default-effort conflict | incorporated | §0.3, §3 1c. Marker syntax undefined (I7). |
| M5 push gate checks HEAD tree | incorporated | §2 H1, §3b. |
| M6 Stop advisory, push/CI hard | incorporated | §3b (c). |
| M7 header churn | incorporated | §1 (`Cap:` in header, size in `STATE.md`). |
| M8 workflow prompts partial, soft | incorporated | §7. |
| M9 refetch `hooks`, `hooks-guide` before step 3 | incorporated | §3 1b. |
| Q1 28 k cap | carried to §9.2 | — |
| Q2 PreToolUse gate; direct injection test | carried to §9.3 | — |
| Q3 gate files deny-protected | carried to §9.4 | — |
| Q4 public/private; admin-inclusive protection | measured public; §9.5 | — |
| Q5 kill switch | carried to §9.6 | — |
| Q6 automated sessions gated? | carried to §9.7 | — |
| Q7 H6 now or later | carried to §9.8 (text already says "po udowodnieniu bramek") | — |
| Q8 budget ceiling | carried to §9.9 | — |

Silently dropped (no mention, no reason): F3's two sub-items (workflow file from the branch; CI fails on gate-file diffs); F12's independent verification of step-3 measurements; F14's review-round and Routine cost lines; F18's 1c conflict-list edit as a CLAUDE.md approval.

## 4. Findings on v2

### B1 — Blocking — Step 0's `kb_check.py = 0` cannot be met on content moved "bez zmiany brzmienia"
- **What is wrong.** §2 lists in H1, from step 0: model scope, evidence tags, map coverage, `Keywords:` header, `STATE.md` consistency and `topics.json` validation. Three of those have no input or must fail in step 0:
  1. `topics.json`, the generator and the generated `Keywords:` lines are step-2 deliverables (§4 "Elementy: `knowledge/topics.json` … generator `scripts/kb_build.py` … linie `Keywords:`"). Step 0 cannot validate a file that step 2 creates, and a hand-written `Keywords:` line in step 0 is a content judgement, contradicting "Nic nie dopisujemy".
  2. Model scope: O0 §5 moved verbatim contains Sonnet/Haiku behavioural facts ("Sonnet 5.5 on API disables upfront thinking via `between_tools`", "Sonnet 5.5 medium 4/4 for 63% of Opus medium; Haiku 4.5 failed (2/4 and 0/4)"). 1c removes them later, so the scope check must fail in step 0 or be inactive.
  3. Tags: R3 shows 39 untagged bullets in O1 under headings that carry no tag; O5 §4 "Not found or fetched: …", O1 §3 "Is the address alive: …", O1 "Check again" bullets, O3 §7 "`/loop` is time-based …" lines are procedural or list items with no tag. A verbatim move cannot pass rule 0.4 without re-tagging, i.e. wording changes.
- **Evidence.** PLAN §2 vs §4; R2, R3; O0 §5 quoted above.
- **Fix.** Give every check a `phase` (0: cap, headers, stub targets, migration preservation; 1a: no "Deltas/New URLs" boxes, `STATE.md` version; 1c: model scope; 2: map coverage, `Keywords:`, `topics.json`, generated-section diff). `STATE.md` records the current phase; `kb_check.py` and CI run `--phase $(current)`. Step N's done criterion is "phase N passes". Tag coverage: run in step 1 after a one-off re-tag pass that is listed as work (count the R3 numbers in the estimate).

### B2 — Blocking — The migration preservation check is mis-specified and would fail or pass wrongly
- **What is wrong.** §2: "każdy identyfikator faktu i każdy znormalizowany punkt ze starych plików występuje **dokładnie raz** w nowych". (a) 67 IDs occur 2–3× in the old files (R1), because O0 §8 cites IDs in parentheses and sections cross-reference each other; "exactly once" is false before the move. (b) "punkt" = `- ` bullet (627) leaves out 272 table rows (O2 §A5 event table, the single most important reference for step 3; O1 index tables; O3 flag tables), 34 code-fence lines in O1/O2 (all examples), 24 numbered items and the header paragraphs of every file. A check that passes on bullets alone can lose the whole A5 table unnoticed.
- **Evidence.** R1, R2; PLAN §2.
- **Fix.** Normalize every non-blank, non-heading line (collapse whitespace) of old and new content files (stubs excluded), compare as multisets: identical, or the diff is the error list. For IDs, compare per-ID occurrence counts. Produce the move itself with `scripts/kb_migrate.py` from a committed line-range table (`migration-map.tsv`: old file, start line, end line, new file, new section); the model writes the table, the script moves text, the check is then a tautology plus the stubs' target existence. This removes the main error source (model retyping 142 KB) and most of step 0's cost.

### I1 — Important — CI from `origin/main` is still bypassable by the route the plan lists as soft
- **What is wrong.** On `push` and `pull_request`, GitHub runs the workflow file **of the branch being checked**. The checker fetched from `origin/main` runs inside a workflow a branch can rewrite (deny on `.github/workflows/**` is bypassed by `python3 -c` or a bash script, which §7 itself lists as soft). A rewritten job with the same name that exits 0 satisfies the required status check, and branch protection then allows the merge. Review 1 F3 said this ("CI runs … the branch's own workflow file") and proposed "fails when the diff touches gate files"; v2 kept only the checker-from-main part.
- **Evidence.** PLAN §2 H5; O0 §4 "does NOT catch … python script or commands inside bash script"; review 1 F3. The `pull_request_target` behaviour is from GitHub docs, not the KB [ASSUMPTION: verify with a curl of docs.github.com before step 0].
- **Fix.** (1) Trigger on `pull_request_target` so the base branch's workflow definition runs; check out the PR head into a subdirectory as data; never execute anything from it. (2) In that job: `git diff --name-only origin/main...PR_HEAD` ∩ {`.claude/**`, `scripts/kb_*.py`, `.github/workflows/**`} must be empty, else fail. Gate changes then go only through the owner's route (temporarily lifting protection, or a direct commit on GitHub while protection is off), which §8 already describes. (3) Mark the required check by job name in branch protection; a missing check blocks the merge. Until (1)–(2) are in, §7 must say CI is soft against scripts.

### I2 — Important — Step 2 is not independent of step 3
- **What is wrong.** Routes 4 and 5 (§4) are hooks (`SubagentStart`, `SessionStart`). They need `.claude/settings.json`, which §8 says only the owner adds, the deny protection and ConfigChange from §5, the harness `test_hooks.sh` from 3b and the kill switch from §5. Step 2's done criterion (first Read hits the `topics.json` file ≥ 4/5) depends on route 4 working, yet 3a (the probe step) comes after step 2 and does not list SubagentStart injection among its probes.
- **Evidence.** PLAN §4 items 4–5, §5 "Testy `claude -p` zawsze z osobnego checkoutu", §8. R6a: the injection works (n=1), so the risk is sequencing, not feasibility.
- **Fix.** Step 2 = routes 1–3 only (names, greppable map, `topics.json`, generator, nested `knowledge/CLAUDE.md`), measured with the agent probe but without hooks. Routes 4–5 become "3a′: map injection hooks", after 3a and the harness. Drafts of hooks can be tested from a worktree with `--settings <file>` without touching the protected file (O0 §4: "hook from --settings works in -p [MEASURED]"); say so in §8, otherwise every test waits for an owner commit.

### I3 — Important — The Bash "full read" criterion is wrong as written and under-specified
- **What is wrong.** §3c.2: "Bash → komenda czyta jeden plik, brak `persistedOutputPath`, `sha256(stdout) == sha256(pliku)`". R6b: `tool_response.stdout` has no trailing newline (23 chars for a 28-byte file ending in `\n`), so the hashes differ for every KB file; the gate would never accept a `cat`, and in auto mode `cat` is the default read path (R0). "Komenda czyta jeden plik" is not defined; a loose match lets `cat hooks.md; git push` through the read-first gate (3c.4), which must allow exactly the read and nothing else.
- **Evidence.** R6b; PLAN §3c.2, §3c.4.
- **Fix.** Count a Bash read only when `tool_input.command` matches `^\s*cat\s+(\S+)\s*$`, the resolved path (against `cwd`) is a KB file, `persistedOutputPath` is absent, and `stdout.rstrip("\n") == file_text.rstrip("\n")` compared as UTF-8 text. The read-first PreToolUse gate allows Bash only for that exact form. Record both in `test_hooks.sh` with the R6 payload shape (`interrupted, isImage, noOutputExpected, stderr, stdout`).

### I4 — Important — The cap's unit is locale-dependent and the truncation unit is unverified
- **What is wrong.** §0.5 defines the cap as "28 000 znaków (`wc -m`)". In this container `LC_CTYPE=POSIX`, so `wc -m` returns bytes (39,247 for O0); under `C.UTF-8` it returns 39,023 (R4). A GitHub runner and the cloud VM can disagree, and CI would pass a file the session's check rejects or vice versa. Whether `BASH_MAX_OUTPUT_LENGTH` counts bytes or characters is unmeasured (P0's file was ASCII, 35,350 chars = 34.5 KB); KB files hold `→ ≤ ✅` and Polish letters.
- **Fix.** Cap in bytes: `wc -c ≤ 28000`. Bytes ≥ chars, so it is conservative under either truncation unit and locale-independent. Keep 12–20 KB as the target.

### I5 — Important — Bypasses missing from §7
Each is a concrete scenario; none is listed.
- (a) **Log forging.** `python3 -c "open('.claude/kbgate/<sid>.log','a').write('<full read line>')"` writes a valid entry; deny does not see python (O0 §4). Both 3c and 3d are then satisfied with nothing read. A secret-keyed HMAC does not help: hooks and Claude's Bash share the environment, so `env` reveals it. This stays soft; say it.
- (b) **Nested `-p` as a proxy reader.** A nested `claude -p` started at the repo root inherits the parent's `session_id` (P1) and emits no `agent_id`; its reads land in the parent's log and count for the main session. Fix: key the log by `transcript_path` (unique per process; present in every event, R6c) instead of `session_id`.
- (c) **Git plumbing on gate files.** `git rm`, `git mv`, `git checkout <ref> -- .claude/settings.json`, `cp x .claude/settings.json`: not an Edit tool call, and not `cat`/`sed`/redirection (the only Bash forms O0 §4 reports deny catching). Unmeasured; add to 3a; I1's CI rule is the backstop.
- (d) **Read-first gate fails open** by design (no `onFailure`); a hook crash, a missing `jq`, or a 127 lets every tool through silently (O2 §A6 "the policy hook is then silently off").
- (e) **SubagentStop cap.** O2 §A5 documents the 8-block cap for Stop; assume the same for SubagentStop until measured.
- (f) **UserPromptSubmit on automatic turns** (background-agent reports, `/loop`; O2 §A5) can arm the gate for a turn the owner did not write; §9 Q7 asks, §7 should list it.
- (g) **PreToolUse read-first gate vs subagents.** Subagent events share `prompt_id` (P1); if the gate state is keyed by `prompt_id` and the hook does not skip events carrying `agent_id`, it blocks every subagent tool until the main session has read. Implementation note, but it decides whether 3c breaks 3d.

### I6 — Important — Review-1 items dropped without a stated reason
See §3 of this review: F3 (workflow file from the branch; gate-file diff rule), F12 (builder session measures its own gates; 3e has no criterion), F14 (review rounds and weekly Routine not costed), F18 (1c's edit of the conflict list is a root CLAUDE.md edit before step 4). Fix: incorporate or reject each in v3 with one line.

### I7 — Important — The model-scope check has no definable rule, and 1c deletes the evidence for the two-model decision
- **What is wrong.** §0.3 allows "tabela, pułapka, składnik" but defines no marker. A script cannot tell "`claude -p` bez `--model` leci na Sonnet 5.5" (trap) from "Sonnet 5.5 on API disables upfront thinking via `between_tools`" (behaviour) by text. 1c "Usunąć szczegóły o Haiku/Sonnet poza tabelą, pułapkami i składnikami" would also delete O0 §5's comparative measurements ("Sonnet 5.5 medium 4/4 for 63% of Opus medium; Haiku 4.5 failed (2/4 and 0/4) at Opus medium price"), which are the measured reason the owner picked two models.
- **Fix.** Inline marker required on any line naming a non-top model outside the ID/price table: `[scope: trap]`, `[scope: component]`, `[scope: why-not]`. The scope check = "non-top model name on a line without a scope marker and outside the table" → error. Keep the comparative measurements as `[scope: why-not]` rows.

### I8 — Important — Executing model and effort are not named; costs do not say which model they assume
- **What is wrong.** Only the reviewer in 1c has a model (Opus 5.5 high). Steps 0–4 name no model or effort for the session doing the work; the cost lines (8–15, 40–90, 5–8, 15–30 USD) do not say whether they assume Opus 5.5 or Fable 5.1 (2.5× the price, O0 §5), nor which effort. CLAUDE.md's own review checklist lists "Model and effort left implicit" as a usual failure.
- **Fix.** Per step: model, effort, `--max-budget-usd` for nested runs, and the cost line labelled "(Opus 5.5, effort N)". Step 0 at Opus 5.5 medium with the script-driven move (B2) should cost a fraction of 8–15 USD; say so after the script exists.

### I9 — Important — Three done criteria are still not commands
- 3e (freshness + Routine) has no criterion. Fix: `test_hooks.sh` runs `kb_freshness.sh` against a fixture `STATE.md` and asserts the report lines; Routine = `list_triggers` shows it (owner-run).
- Step 4: "tokeny CLAUDE.md licznikiem Read ≤ dzisiejsze 3 752" is a manual in-session measurement and "≤ today" is no reduction. Fix: set a target (the table, tags, conflicts and Freshness/Live-lookup sections leave; ≤ 2,500 tokens is realistic) and keep `wc -c` as the CI proxy with the Read-counter number recorded in `STATE.md`.
- 1b: "każda strona ma wiersz" is not stated as a script check. Fix: `kb_check.py --phase 1b` reads a committed `pages-1b.txt` (33 URLs) and requires a `docs-index.md` row with status, date, sha256 and size for each.

### Minor
- m1. §6: the second 2026-10-06 denial was the fast-forward of `main`, not a "zapis zgody" (citation #33).
- m2. `test_hooks.sh` fixtures "JSON z prób P1–P3" do not exist in the repo (R5); the probe payloads lived in a disposable scratchpad. Re-record in 3a and commit under `tests/fixtures/` (R6's payload shapes are in §0 of this review).
- m3. SessionStart matchers: add `resume` (cloud pause/resume; O2 §A5 lists `startup resume clear compact fork`). `kb_freshness.sh` must use `curl --max-time` and skip network when a test namespace variable is set, or every nested `-p` test pays the fetch.
- m4. `kb_check.py` on `git archive HEAD` only: the Stop advisory (3b c) and the edit loop need `--worktree`; the push gate uses HEAD (M5). Say which mode each caller uses.
- m5. 1a's `wc -l = 372` counts rows, not content. Add: every row's target ∈ {content file list} ∪ {"irrelevant"} and reason non-empty, checked by the same script.
- m6. "File changed since last read" is named as a trigger (3c.5) but not defined. Store the file's sha256 in the log entry; a mismatch at Stop/PreToolUse = not read.
- m7. Step 0 says "Nic nie dopisujemy" yet adds `STATE.md` "generowany" (by what, in step 0?), `Keywords:` lines and READMEs. State that step 0's `STATE.md` and `Keywords:` are hand-written placeholders replaced by the generator in step 2, or move them to step 2.
- m8. 3c.5's `last_assistant_message` matching plus K=3 carry-over can arm reading for any answer that mentions "hook" in passing. After one full read per compaction epoch the cost is one read per file per epoch, which is acceptable; measure the block count in 3c as planned and set a per-session ceiling on required files.
- m9. 1c removes "Sonnet 5.5 default effort" and "Haiku 4.5 retirement" from the list that root CLAUDE.md says must "never [be resolved] silently". Descoping is not resolving, but it is a root CLAUDE.md edit before step 4 and needs the owner's explicit yes (F18).

### Nothing found
- Step order 0 → 1 → 2 → 3 → 4, the stub strategy, rollback by tag + revert, and the push-gate design (two handlers, `onFailure` only on the narrow one) hold up; no further bypass of the push gate matters because branch protection is the real boundary and I1 is where that boundary leaks.
- Costs for steps 2 and 3 are within what review 1's probes and R6 support (0.15–0.26 USD per trivial `-p` at effort low).
- Nothing in v2 adds scope the owner did not ask for, except the weekly Routine (deferred, §9 Q8) and the 372-row triage file, which is the done criterion the owner's "command with an exit code" rule requires.

## 5. Omissions (what to insist on before step 0 starts)
1. **A phase table for `kb_check.py`** (B1) and the **line-range migration table + script** (B2). Without them step 0 has no attainable criterion.
2. **Verify the two GitHub assumptions on docs.github.com** before step 0: base-branch workflow execution (`pull_request_target`), and that a required status check by job name blocks merge when missing; record both as `[SOURCE: …, date]` in `cloud-environment.md` or `headless-sdk-ci.md`. The whole "CI is hard" claim rests on them.
3. **A `.gitignore`** (none exists, R5) covering `.claude/kbgate/`, probe outputs and worktrees before any hook writes state into the repo.
4. **Commit the probe scripts and payload fixtures** (R5) so step 3 does not start by re-deriving them from a review's prose.
5. **A baseline for the owner's complaint.** Nothing measures how often today a session answers a KB question without reading. Cheapest route: deploy the PostToolUse logger of 3c.2 in 3b *without* any gate and count, per topic-matched prompt, whether a full read happened before the first answer. That number before 3c and after 3c is the only evidence H4 earned its cost.
6. **Executing model/effort per step** (I8), and which steps may run on Fable at all.
7. **Local-PC sessions.** The committed `.claude/settings.json` also loads on the owner's PC, where findings 2026-10-11 notes there is no `python3`. Guard every hook with `[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0` (O2 §A7) or make the scripts POSIX sh + `jq` only; otherwise the first local session hits silent 127s (or blocks, on the push handler with `onFailure`).
8. **Dedup rule vs file change.** State whether the Read dedup (`file_unchanged`) keys on mtime or content, since the gate's "file changed" trigger (m6) and the post-compaction probe (3a) both depend on it.

## 6. Open questions only the owner can answer
1. Gate files could then change only by you lifting branch protection (or committing on GitHub while it is off); no session, including one you watch, could ship a hook change through a normal PR. Do you accept that operating model, or do you want a labelled-PR exception (which a session could forge with `gh`)?
2. Which model and effort should the execution sessions use per step, given Fable 5.1 costs 2.5× Opus 5.5? The plan's cost figures only make sense once this is fixed.
3. Dropping "Sonnet 5.5 default effort" and "Haiku 4.5 retirement" from the conflict list is a root CLAUDE.md edit before step 4 and a descoping of a "never resolve silently" item. Explicit yes or no?
4. §9 Q3 as framed bundles two decisions: the read-first PreToolUse gate (blocks all tools until the read) and direct section injection (3c.6, more tokens per prompt). They have different costs and failure modes; answer them separately.
5. Do you want the 3b logger deployed without a gate first (omission 5) to get a before/after number, even though it adds one owner commit of `.claude/settings.json` and one more step?
