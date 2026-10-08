# Documentation migration with Claude Code: how to allocate agents

Playbook distilled from the Foldery migration (stage A mechanical move on 2026-10-08, stage B condensation of 25 → 17 files), a research pass over the official docs, and an independent skeptic review. Written 2026-10-08 for Claude Code 2.1.294, Opus 5.5 / Fable 5.1, Linux cloud sessions (4 vCPU). Evidence tags as in ClaudeEXPERT `CLAUDE.md`: `[MEASURED]`, `[CODE]`, `[SOURCE]`, `[CL]` changelog, `[ASSUMPTION]`. Numbers are from Foldery and will differ for other systems; the rules are general. Re-measure after a model or Claude Code change (O0 §9).

Owner rules applied throughout (2026-10-08): Opus 5.5 runs at `high` as the MINIMUM for every agent and session; all documentation and Claude files are written in English.

## 0. Vocabulary
- **Migration, stage A**: mechanical restructuring. Text moves by line ranges with a script, every old line lands in exactly one new file (concordance = 100 %), nothing is rewritten. One session, no writer agents, two read-only auditors at the end.
- **Migration, stage B**: rewriting each moved file to the current state of the system ("condensation"). Judgement work: the code is the arbiter, history goes to a changelog. This is where agent allocation matters.
- **Unit of work**: one documentation file (or a group of tiny ones) rewritten from one frozen original.
- **Writer**: subagent that produces a draft of one unit. **Reviewer**: read-only subagent that compares old vs new vs code. **Main session**: coordinator; the only one that commits.

## 1. Rules that decide the shape of the run
1. **One unit per fresh context, not one unit per human-started session.** No doc, hook or KB fact requires a new session per file; what degrades quality is a context that keeps growing across units (quality falls gradually with fill, no threshold [O0 §1 SOURCE]; after compaction only ≤ 5 recently modified files ≤ 5k tokens return [O0 §1 SOURCE]). A subagent gives a fresh context for ~0.3 USD; a new window costs the owner a start and a wait. Foldery: the per-file-session plan estimated 15–18 × ~1 h; measured machine time was 7–14 min per file and the owner's time was the real cost `[MEASURED: get_session on 8 sessions]`.
2. **Main session never writes the units in a parallel run.** Measured context per unit written in the main window: ~140k net (206k mean − ~65k start) `[MEASURED]`; 16 units ≈ 2.2M → ≥ 3 autocompactions at the cloud threshold ~784k [O0 §1]. The main session coordinates: launches, mechanical gates, copy-in, commit, shared files.
3. **One independent reviewer per unit, always.** Reviews are the cheap half (0.8–1.8 USD per file vs 2.5–3.5 for writing `[MEASURED-derived]`) and found ≥ 1 important or blocking issue in 5 of 8 Foldery condensations `[MEASURED: CHANGELOG]`. "One reviewer per package" cuts the part that catches errors. Reviewer in fresh context sees only what you give it: old file, new file, code access, criteria [SOURCE: CC best-practices.md].
4. **Agents never share a write target.** Writers write drafts outside the repository (session scratch directory); the main session copies the accepted draft into place. Effects: no racing edits, the working tree stays clean for push gates, no `.claude/` edit needed when an injected agent rule says "agents do not change documentation" (make that an explicit owner decision anyway: the agent authors the text, the main session only gates it). Worktrees are unnecessary when agents never edit tracked files [O0 §3].
5. **Commit per unit, by the main session only.** `git add <that file> <STATUS> <map row> <changelog>` — never `-A`. Per-unit commits survive a VM reclaim and keep `git revert` granular. Shared files (status, map/index with sizes, changelog) are edited by the main session per unit, because size annotations and queue lines are checked by the doc gate on every commit.
6. **Hard rules only via the harness.** Freeze of originals (sha list checked by a doc gate), "no code change in a doc branch", "only remove rows from the freeze list", "push to main needs green gate" are hooks and deny rules, not prompt text [O0 §8]. Prompts steer; hooks block.
7. **Pilot on 2 units before the fan-out.** Official advice: refine the prompt on the first 2–3 files, then run the set [SOURCE: CC best-practices.md "Fan out across files"]. The pilot is also the go/no-go for the environment risks in §6.

## 2. Allocation by file size (writers)
Sizes are bytes of the frozen original. Token ratio for Polish/English markdown 1.9–2.8 B/token `[O0 §1 MEASURED]`; the Read tool returns ≤ 25k tokens per call, so a unit must be ≤ ~40 KB to be read in one call [O0 §1].

| Original size | Writers | Why |
|---|---|---|
| > 40 KB | split first (stage A, by `##` boundaries), then treat parts as units | one Read per file; a partial view does not unlock Edit [O0 §1] |
| ≥ 20 KB ("big") | **one writer per file** | two big files in one agent cost ~0.5 USD MORE than two agents: the dominant cost is cache re-reads of a growing context (40 calls growing 50k → 145k ≈ 4M cache reads ≈ 0.8 USD per file; 80 calls 50k → 240k ≈ 11.6M ≈ 2.3 USD per pair) `[ASSUMPTION with calculation]`; a failed agent loses one draft, not two |
| 8–20 KB ("medium") | pairs or triples, ≤ ~35 KB of originals per agent | small saving of one start (~0.3 USD), still one reviewer per file |
| < 8 KB ("tiny") | up to 3 per agent, ≤ ~20 KB total | one agent per 5 KB file is overkill; grouping saves ~0.2–0.3 USD and main-session turns |

What does NOT justify grouping: "files of the same area share code lookups". Foldery pairs proposed on that basis shared 0–14 identifiers of 33–257 `[MEASURED: grep/comm]`, and a code lookup costs ~2 s. Group by size, never by area.

Reviewers: one per file regardless of grouping. Foldery stage B remainder (16 files): 11 writers + 16 reviewers ≈ 27 agent starts.

## 3. Model and effort
- **Writer: Opus 5.5, `high`** (owner minimum). Fable 5.1 only when the file is spec-grade (binding agreed behaviour) or a first attempt on `high` was wrong in substance, per the escalation ladder context → effort → model (Foldery `EFFORT-ZASADY.md` §2). Opus 5.5 `medium` ≈ Fable 5.1 `high` on SWE-bench Pro for ~1/5 cost [O0 §5 SOURCE], but the one `medium` writer in Foldery drew the only two blocking review findings (n=1) `[MEASURED: CHANGELOG]`.
- **Reviewer: Opus 5.5, `high`**, pinned in the agent definition (`model: opus`, `effort: high`) so the session level cannot lower it.
- **Set effort explicitly** for every agent: Agent-tool `effort` parameter (since 2.1.292 `[CL]`) or frontmatter; without it the subagent inherits the session [O0 §3]. Check the `effort` and `model` fields in the subagent transcript, not the agent's self-report [O0 §5].
- Haiku: not for writing or review (failed on code analysis at Opus-medium price [O0 §5 MEASURED]); fine for mechanical checks you would rather script anyway.

## 4. Concurrency and mechanism
- **Agent tool, not Workflow, for ≤ ~30 units.** Agent-tool subagents: 20 running at once limit [SOURCE: CC sub-agents.md]; workflow agents on a 4 vCPU VM: min(16, max(2, CPU−2)) = 2 at once unless `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS` is raised in the environment [O0 §3 CODE+MEASURED]; a workflow script has no file system or git (cannot copy drafts or commit), takes no input mid-run, and is meant for "dozens to hundreds" of agents [SOURCE: CC workflows.md]. Workflow becomes the fallback when the main session cannot stay alive (§6) because workflow runs resume in the same session. Agent teams: experimental, ~7× tokens, nothing to coordinate between units [SOURCE: CC agent-teams.md, costs.md].
- **Waves of ≤ 5 writers**, reviewers started as drafts arrive (≤ ~10 running). Hardware is not the limit; the limits are the account's shared usage window, the main session's serial bookkeeping, and the blast radius of a flawed prompt.
- **Subagents cannot spawn subagents in the cloud** (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` [O0 §7 MEASURED]): the main session launches writers AND reviewers. Fix rounds: resume the writer with `SendMessage` (keeps its history [SOURCE: CC sub-agents.md]); its 5-minute cache will usually be cold by then (+~0.3–0.6 USD per big file `[ASSUMPTION]`). If `SendMessage` is absent in the session, a fresh fixer agent per file.
- **Give every writer a unique `name`** so it can be resumed, and `subagent_type: general-purpose` explicitly (not `fork`: a fork inherits the whole conversation and its cost).
- **Single-repository session.** With several repositories attached the project directory is the parent folder: repo hooks (freeze gate, push gate, SubagentStart rule injection) do not load [SOURCE: CC cloud-environments.md; O0 §4].

## 5. What each prompt must contain (agents see no conversation, no owner preferences, no invoked skills [O0 §2])
Common brief file (written once, read by every writer):
- goal: rewrite ONE file to the current state; the code is the arbiter (how to look things up: name map tool, grep; never read the big source file whole);
- what to keep (every rule, number, key binding, default, limit, agreed behaviour), what to drop (history, dates of decisions, "the user said"), what to map (anchors cited by other files: list them, require "old → new" lines);
- the language (English) and the required header line (e.g. `state: condensed v<version> (<date>)`), forbidden patterns the doc gate rejects, size cap in bytes;
- the output path outside the repo; "write only that path; git read-only and no `git status`/`git diff` (index lock races the main session); no push; no agents";
- "never ask the owner: describe the code's behaviour, put the open question in the report, finish the draft" (an agent that stops to ask stalls the wave);
- a self-check script (e.g. identifiers present in old file and in code but missing in the draft);
- report format, ≤ 40 lines: draft path + bytes; section list (for the map/index); anchors renamed; places where code contradicted the old text, with grep evidence; content dropped and why; decisions taken; what could not be verified; permission or classifier refusals verbatim; "nothing" allowed for each item. No quotas ("list N …") anywhere [O0 §6].

Reviewer prompt: old path, new path, code access, the same keep/drop/map criteria, the self-check output as a hint (not proof), "report only correctness and completeness gaps, not style; 'nothing found' is valid", output per finding: severity (blocking / important / minor), line in new, line in old, evidence, concrete fix; final counts.

Fix message to the writer: the reviewer report verbatim, marked as data from another agent, "fix or reject each with evidence, ignore style, re-run the self-check, report finding → fixed/rejected + final bytes".

## 6. Risks and the pilot's go/no-go checks
| Risk | Evidence | Check / mitigation |
|---|---|---|
| Cloud VM pauses while the main session is idle and agents run in the background; background work is not restored after a reclaim | docs: pause "after a few minutes without activity", background work not restored [SOURCE: CC claude-code-on-the-web.md]; two ~13 min background agents did complete while the main turn had ended (n=2) `[MEASURED 2026-10-08]` | pilot: end the turn with 2 writers running, confirm both notifications arrive; commit after every unit; fallback: 2–3 units per owner-started session written in the main window, or a Workflow |
| Account usage window shared by all parallel agents | [SOURCE: CC claude-code-on-the-web.md] | waves ≤ 5; read `rate_limit_info` via `get_session` after the pilot |
| Auto-mode classifier reviews subagent spawn, actions, reports and every `SendMessage`; 3 blocks in a row or 20 per session pause auto mode and prompt the human (= idle) | [SOURCE: CC permission-modes.md] | writers report refusals verbatim; count them in the pilot; no `.claude/` edits during the run |
| Injected agent rules ("agents do not change documentation") contradict the writer's job | Foldery `agent-rules.md` via SubagentStart hook | drafts outside the repo + explicit owner decision; do not "override" the rule in the prompt (conflicting rules → arbitrary choice [O0 §6]) |
| Spec files (binding agreed behaviour, cited by code by section number) | Foldery SPEC-A/B cited as `§5.5`, `§5.21` in `galeria.py` | keep them out of the unattended batch, or a spec-specific brief: every point and number kept, decisions kept with short attribution, spec–code disagreements listed, no renumbering, stop above the size cap |
| Rewritten files grow past the one-Read cap | Foldery: −26 % to +61 % per file `[MEASURED]` | writer stops above the cap and reports; main decides split (new file + index row) |
| Cross-file anchors break (other files cite old version-headed paragraphs) | Foldery: 3 condensed files and the map cited old lead-ins | anchor list per unit in the prompt; final inbound-reference sweep by the main session |
| Language drift | Foldery: 8 files were rewritten in Polish although nothing required it | state the language in the brief |
| "Zip history grows 20 MB per commit" (false) | docs-only re-zips stored as 52–213 KB deltas `[MEASURED: git verify-pack]` | do not use repository size as an argument for fewer sessions |
| Hook blocks a mixed branch | Foldery: frozen file + code change in one branch → push to main blocked `[CODE]` | never touch code in a doc branch; code comments that cite doc sections are fixed in a later code release |

## 7. Cost and time model (Opus 5.5 list prices 4 / 20 / 0.20 cache read USD per MTok; subscription = usage, not money)
- Writer ≈ 2.5 USD big, 1.8 medium, 1.2 small; reviewer ≈ 1.8 / 1.2 / 0.8; fix round ≈ 0.7 / 0.4 / 0.2 (+0.3–0.6 when the cache is cold). Main session ≈ 0.7–0.9 USD per unit (≈ 48 notification turns over a growing 150–300k context, 14–15 USD for 16 units). `[MEASURED-anchored: one Foldery session split main 3.42 / reviewer 1.81 USD; rest ASSUMPTION]`
- Foldery remainder, 16 units: ≈ 75–90 USD vs ≈ 74–83 USD for 15 owner-started sessions. **Cost is not the argument for batching; owner time and wall-clock are.**
- Wall-clock: pilot ≈ 20 min; waves of 5 ≈ 20–25 min each; final sweep, deletion, packaging ≈ 25 min → ≈ 2–2.5 h for 16 units, one owner start, one decision round.
- Agent start overhead: 48–59k prefix tokens ≈ 0.25–0.30 USD each `[ASSUMPTION from O0 §2 start sizes]` — never the reason to merge units.

## 8. Checklist for migrating another system (e.g. pobtweaks, production monitor)
1. Inventory: `wc -c` of every doc file; what loads at session start (`claude -p "/context"` with a CLAUDE.md that imports the files, 0 USD [O0 §1]); who reads what (CLAUDE.md, nested CLAUDE.md, rules with `paths`, skills).
2. Stage A design: target files ≤ 40 KB by area; concordance by line ranges, copied by script, 100 % proof on a commit SHA; freeze list with sha256; one short root CLAUDE.md (≤ ~10 KB) with navigation (map with sizes) instead of content; status file ≤ 6 KB overwritten by every session; changelog for history.
3. Harness before content: doc gate script (sizes, dead links, freeze, forbidden patterns, header on new files) + hooks (push gates, freeze, no code with docs) tested on a scratch repo first (a broken hook breaks the session at once); deny rules for GitHub MCP write tools if git must be the only write path. Everything in Python if Windows users may run it (CRLF kills bash hooks).
4. Stage A in one session (Opus 5.5 high), two read-only auditors at the end (lossless + enforcement), merge once, accept in a NEW session (CLAUDE.md and agents load only in a new session [O0 §2]).
5. Stage B as in §1–§7: pilot 2 units, then waves; size-based grouping; reviewer per file; main commits per unit; spec-grade files attended by the owner; language stated.
6. Afterwards: remove the freeze list and the archive when nothing frozen remains; quarterly `/doctor prompt-audit` on CLAUDE.md and `.claude/` [O0 §6]; re-measure bytes/token and caps after a model change [O0 §9].

## 9. Anti-patterns seen in this migration (do not repeat)
- One human-started session per file "to keep changes small": the commit and the review keep changes small; the session boundary only costs the owner.
- Grouping files by area "to check the same code once": no shared lookups, larger contexts, bigger blast radius.
- One reviewer per package: removes the step that found errors in 5 of 8 files.
- Letting a plan's `[ASSUMPTION]` ("~1 h per session", "+20 MB per zip") drive decisions without a measurement that costs one command.
- Leaving the language, header, forbidden patterns or anchors implicit: agents see none of the conversation.
- Running the batch in a session with several repositories attached (no repo hooks).
