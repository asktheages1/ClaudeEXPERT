# Review of the FelixReborn KB session prompts (00-COMMON, S00–S13)

Reviewer: Opus 5.5, effort high, independent; did not see the conversation that produced the prompts. Date: 2026-10-11.
Read in full with the Read tool: root `CLAUDE.md`; `knowledge/O0-how-claude-works.md`; `knowledge/O2-syntax-cheatsheet.md` l. 1–200 and §D (l. 386–525); `knowledge/O3-automation-orchestration.md` (whole file); `findings.md`; the FelixReborn skeleton CLAUDE.md (uploads path); `reports/kb-plan-2026-10-11/PLAN.md`; `01-przeglad-CLAUDE-md.md`; `02-sesje-i-agenci.md`; all 15 prompt files.
Static checks run here (2026-10-11, this container): see the `[MEASURED]` tags below. No `claude -p`, no network.

---

## 1. Verdict and the five required changes

**Verdict.** The prompts are well grounded in the KB on hook mechanics (events, payload fields, exit codes, `onFailure`, the full-read definition, the `cat` truncation trap), and the one-step-per-session sequence covers every goal of the plan. They will nevertheless not run as written: S00's own done criterion cannot pass, the CI design makes almost every later PR unmergeable once branch protection is on, and the precedence clause "CLAUDE.md wins" hands control to a skeleton CLAUDE.md that contradicts the prompts in several places. Several prompts were adapted from a plan written for the ClaudeEXPERT repository and target sections, lists and files that do not exist in FelixReborn, and the owner's requirement "every read verified by a script" is unmet until S09–S12.

**Ranked top 5 required changes**
1. **CI and branch protection (blocking).** Split the "gate files changed" check out of the required `kb-check` job. Make main's checker run only the phases it knows. Drop the impossible "green CI on S00's PR" criterion. Set `fetch-depth` for the merge-base diff. (S00 F1–F4)
2. **S00 phase 0 cannot pass on today's files (blocking).** O0 is 39,247 B and O2 is 39,951 B, but phase 0 enforces ≤ 28,000 bytes on `knowledge/*.md`. The reference check is vacuous: 0 backticked `file §x` references exist. (S00 F5–F6)
3. **Pre-S00 owner actions and precedence (blocking).** Copy the prompts into `docs/prompts/` and decide the root-vs-`Warsztat/` layout. Then either fix skeleton lines 7, 15 and 45 yourself before S00, or have COMMON override them with a dated owner decision. Today "CLAUDE.md wins" re-imposes the USD/consent gate before every multi-agent session and the "work in Warsztat/" rule. (COMMON C1–C3)
4. **Script-verified reading from S00 onward (important).** Add `tools/verify_reads.py` in S00: it checks transcripts with the same full-read definition the S08 logger will use, and runs after every agent wave and on the main transcript. Remove partial reads ("sections 1, 2…", "first 15 lines", "lines 1–200") from the lists headed "Read in full". (X1)
5. **Fix the adaptation errors from the ClaudeEXPERT plan (important).** The open-conflicts list, the evidence-tag legend, the "KB table", "Read O0 in full" and "Reviewing designs" exist only in ClaudeEXPERT's CLAUDE.md. S05 step 3, S06 steps 3 and 7, S13 step 2 and phase 1's tag regex depend on them. `FINDINGS-claudeexpert.md` placed inside `knowledge/` will fail phases 1a, 1c and 2. (X2)

---

## 2. Findings per file

### 00-COMMON.md

**C1 — blocking — precedence hands control to a skeleton that contradicts the prompts.**
Quote: "Where it conflicts with `CLAUDE.md`, `CLAUDE.md` wins".
The skeleton CLAUDE.md contradicts the prompts in these places:
- l. 7 "Work in Warsztat/; only accepted work is promoted to Gotowe/", while every prompt builds `tools/`, `knowledge/` and `.claude/` in the root.
- l. 45 "Several agents, workflows, loops: cost and time estimate, then the owner's yes" (USD gates).
- l. 18: a reply format different from COMMON §5.
- l. 30: a reviewer from `.claude/agents/reviewer.md`, which does not exist until S10.
Evidence: skeleton l. 7, 18, 30, 45. Review 01 §1 points 2–3 and §2 (l. 45) already flag l. 7 and l. 45, but no prompt changes the skeleton before S13, and COMMON §3 forbids editing CLAUDE.md.
Scenario: S01 must launch 6 agents. CLAUDE.md wins, so the window stops for an estimate and the owner's yes; in the cloud, waiting counts as inactivity (O0 §7 "Waiting for approval / MCP login = inactivity, session may expire" [SOURCE]).
Fix: before S00 the owner applies review 01 §1 points 2–3 and the l. 7 and l. 45 rows to the skeleton (it is his file and he can edit it on GitHub). Otherwise add to COMMON: "Owner decision 2026-10-xx: the agents listed in a session prompt are pre-approved; this file overrides CLAUDE.md l. 7, 18, 30, 45 until S13."

**C2 — important — `/tmp/kbtest` and `git worktree add … <branch>`.**
Quote §2: "runs from a separate checkout (`git worktree add /tmp/kbtest <branch>`)".
Two problems:
- (a) `<branch>` = the session branch fails with "already checked out". S07 uses `HEAD`, which gives a detached worktree; make that the rule.
- (b) The worktree holds only committed state, while S07 and S08 point `--settings` at `Warsztat/probes/*.json` and hooks written in the same session: "Uncommitted changes don't reach the copy" (O0 §3 [ASSUMPTION; MEASURED via git]).
- (c) Skeleton l. 15 allows only the repository and the session scratchpad. `/tmp/kbtest` is neither, and CLAUDE.md wins (C1).
Fix: `git worktree add --detach "$SCRATCH/kbtest" HEAD` after a commit, where `$SCRATCH` is the scratchpad path. Pass `--settings` with an absolute path into the main checkout.

**C3 — important — the reviewers cannot "read all of" a large diff through Bash.**
Quote §4 brief: "Then run: git diff origin/main...HEAD --stat; git diff origin/main...HEAD (read all of it)."
Evidence: O1 §2 "Bash: inline output ~30,000 chars; larger output goes to a file with a 2,000-char preview". Findings 2026-10-11 P0/P2: the model saw only the 2 KB preview.
Scenario: S01's diff rewrites ~142 KB of KB text (O0–O5 total 141,939 B [MEASURED: wc -c]), so each reviewer sees 2 KB and "reviews" it. This is the exact shortcut the project exists to stop.
Fix: `git diff origin/main...HEAD > Warsztat/_scratch/review-diff.txt`, then Read it in chunks with `offset`/`limit` (≤ ~20k tokens per call) and report the line ranges read. Also forbid concurrent writes: two reviewers running `kb_build.py`/`export_template.py`, or editing `tests/topics/phrases.tsv` (S06), on the shared checkout race each other ("subagent … on shared checkout", O0 §3 [SOURCE]). Have each reviewer write only to `docs/reviews/<Sxx>-<model>*`.

**C4 — important — "re-read after compaction" may return the same stub.**
Quote §1: "After a compaction it is not: re-read."
Evidence: findings 2026-10-11 P3: a second Read returns `file_unchanged`, and "whether the dedup resets after compaction is unverified". This is S07 probe 1.
Fix: "After a compaction, if Read returns `file_unchanged`, re-read with `cat <path>` (files < 28,000 bytes); larger files in parts with `offset`."

**C5 — important — COMMON vs session prompt precedence is undefined, and S13 breaks COMMON.**
Quote §3: "Never edit `CLAUDE.md` yourself: write the proposed diff to `Warsztat/CLAUDE.md.proposed.diff`". S13 step 2: "Edit (as one proposed diff applied in the branch)".
Fix: one sentence in COMMON: "A session prompt overrides this file where it says so explicitly", and in S13: "This session is the exception to COMMON §3".

**C6 — minor — layout block.**
`Warsztat/` is listed beside the root `tools/`, so CLAUDE.md l. 7 still says to work in `Warsztat/` (C1). `docs/OWNER-SETUP.md` vs "Polish only in files whose name starts with `RAPORT-`" (S00 step 7 names the same file both ways).

**C7 — minor — the session model and effort are never checked.**
Neither COMMON nor any Sxx says which model and effort the main window must run on, or how to check it. 02 says Opus 5.5 high. O0 §9: "Always at start: session model, effort_level and window". O0 §8: "check in transcript model / effort fields, not in self-report".
Fix: COMMON §2 adds "Main window: Opus 5.5, effort high. At start print `$CLAUDE_EFFORT` and the model (get_session); if they differ, stop." It also adds "verify each agent's actual model and effort from its transcript once per session". Findings 2026-10-11 notes the Agent `effort` parameter was accepted, but the actual effort was "not read from its transcript".

**C8 — minor — the gate-log path is inconsistent.**
§3 says "`docs/gatelogs/<Sxx>/`" (a directory); S12 reads "`docs/gatelogs/<Sxx>.jsonl`".

**C9 — minor — §2 is out of date from S08.**
"Every agent sees only its own prompt plus `CLAUDE.md` … or nothing (Explore, `omitClaudeMd`)" is no longer true once S08 injects `agent-rules.md` and the map through SubagentStart.

### S00-bootstrap.md

**F1 — blocking — the required check is red by design on almost every later PR.**
Quote step 6: "then fails with a list if `git diff --name-only …` touches `.claude/**` …, `.github/**`, `tools/kb_*`, `tools/test_hooks.sh`, `knowledge/topics.json`". Step 7: required check `kb-check` with "Include administrators".
Which sessions touch these paths:
- S01 adds `tools/kb_migrate*`.
- S03, S04 and S05 extend `tools/kb_check.py`.
- S06 adds `topics.json`, `kb_build.py`, `kb_topics.py` and a workflow step.
- S08–S12 touch `.claude/**`.
One job means one check. A failing required check blocks the merge for everyone, administrators included, so the owner can merge nothing without switching protection off each time. That defeats the protection.
Evidence: O0 §7: "branch protection by default doesn't apply to admin" [SOURCE: github/docs]; PLAN §10 Q5 itself notes "przy zepsutym CI nic nie zmergujesz" ("with broken CI you can't merge anything").
Fix: two jobs. `kb-check` (required) runs the checker. `gate-files-changed` (not required, or required only together with a review rule the owner satisfies) posts the file list.

**F2 — blocking — the trusted checker never knows the new phase in the PR that introduces it.**
CI runs main's `kb_check.py` on the PR tree with "the phase in `knowledge/STATE.md`". S03's PR sets `phase: 1a`, but main's script has no phase 1a: the result is red, or a silent fallback to phase 0. The same happens in S05 (1c), S06 (2, the `kb_build.py` diff step) and S12 (the `export_template.py` step).
Fix: main's checker runs `min(STATE phase, highest phase it implements)` and prints that it did. A phase-introducing PR is reviewed by hand, the same bootstrap caveat as S00's own PR, stated in each such prompt.

**F3 — important — S00's done criterion is unattainable.**
Quote: "plus the CI run visible as green on this branch's PR". The step-6 caveat itself says "this first PR cannot be checked by a `main` that has no checker". With `pull_request_target` the workflow file comes from the base branch [ASSUMPTION: GitHub behaviour, not in KB, which is what the research agent verifies], so no run appears at all.
Fix: replace it with a local YAML/`actionlint` check, and record "first CI run: S01 PR" in STATUS.

**F4 — important — the diff step fails on a shallow checkout; `--root` and `push` are undefined.**
`git diff --name-only origin/main...<head>` in a `main` checkout made with `actions/checkout` defaults has no history and no PR head [ASSUMPTION: reviewer's knowledge of `actions/checkout` `fetch-depth: 1` default; not in KB, add it to the research agent's questions].
- `--root pr` is used in step 6 but is not among the flags defined in step 4.
- On the `push` trigger `github.event.pull_request` is empty.
Fix: `fetch-depth: 0` plus fetching the head SHA, or list PR files with `gh api repos/{repo}/pulls/{n}/files` under `pull-requests: read`. Define `--root`. Guard the PR-only steps with `if: github.event_name == 'pull_request_target'`.

**F5 — blocking — phase 0 fails on today's `knowledge/`.**
Quote step 4: "Phase 0 checks, on `knowledge/*.md`: size ≤ 28,000 bytes … It must pass on today's `knowledge/`".
Evidence: O0 = 39,247 B, O2 = 39,951 B [MEASURED: `ls -la knowledge/`, 2026-10-11]. PLAN §0.7 sized the 28 KB cap for the files *after* migration ("Największe pliki po przeprowadzce … 18 688", "largest files after the migration… 18,688").
Scenario: the window either reports failure on its own done criterion, or "adapts" the cap, which is favourable rounding. After the merge, `push` to `main` runs phase 0 on main's O-files and stays red until S01.
Fix: phase 0 = 40,000 B for `O[0-5]-*.md` (their own header budget, O0 l. 5) and 28,000 B for every other content file. Or make the cap phase-1a-and-later only.

**F6 — important — the phase-0 reference check is vacuous, and bare references will dangle after S01.**
Quote: "every `` `<file> §<x>` `` reference points to an existing heading".
Evidence [MEASURED: grep, 2026-10-11]: 0 backticked `file §x` references in O0–O5; 20 references of the form `O[0-5] §x`; 14 bare `§N` references inside O0 (e.g. l. 39 "hard block: §6", l. 63 "effort precedence: §5", l. 83 "denials: §4").
After S01's verbatim move, "§6" inside `instructions-memory-skills.md` points nowhere, and "O0 §3" points to a stub. Phase 0 as specified checks none of this.
Fix: check the forms the KB actually uses (`O[0-5] §[0-9A-E.]+`, bare `§[0-9]` resolved within the source file). In S01, let `kb_migrate.py` rewrite references from the old→new heading table, with `kb_migrate_check.py` allowing only that substitution.

**F7 — important — the research agent's method is partly broken.**
Quote: "find the pages via `https://raw.githubusercontent.com/github/docs/main/content/actions/` listings".
raw.githubusercontent.com serves files, not directory listings, and github/docs pages pull key sentences from Liquid `{% data reusables… %}` that the raw markdown omits [ASSUMPTION: reviewer's knowledge, not in KB]. The GitHub REST API outside the session repository may also be restricted: O0 §7 "API and release-assets only for session repo" [SOURCE: CE].
Fix: allow `curl -sL https://docs.github.com/en/...` (HTML; grep the text) and WebSearch. Quote only from fetched text. Add question (d): checkout `fetch-depth`/merge-base for `pull_request_target`.

**F8 — important — owner preconditions are missing.**
- (a) `docs/prompts/` does not exist in FelixReborn. The first line of S00 ("Read `docs/prompts/00-COMMON.md`") fails, and S00 never creates the directory.
- (b) Repository visibility: branch protection on a private repository needs a paid plan (O0 §7 [SOURCE: github/docs]). PLAN measured *ClaudeEXPERT* as public, not FelixReborn.
- (c) The decisions from review 01 §4 (layout, KB-in-template) are not CLAUDE.md placeholders, so step 2 never records them. S12 step 7 then reads "per the owner's decision in `STATUS.md`" and finds nothing.
Fix: preconditions 4–6: prompts present; `gh api repos/<o>/<r> --jq .private`; the 01 §4 decisions listed in STATUS.

**F9 — minor — "Read in full" lists partial reads.**
"`knowledge/O0-how-claude-works.md` (sections 1, 2, 4, 7, 8)", "O2 lines 1–200", "FINDINGS-claudeexpert (entries dated 2026-10-11)". COMMON §1 defines "Read in full" as no offset and no limit. See X1.

**F10 — minor — `.claude/agents/` should be created here.**
S06 needs it, and creating it mid-session forces a restart (S06 F1). Create `.claude/agents/` (with `reviewer.md`, or an empty `.gitkeep`) in S00.

### S01-migration.md

**M1 — important — "exactly once" fails on legitimate duplicates.**
Quote step 4: "asserts each old line appears exactly once in the new set".
Evidence [MEASURED: `cat O*.md | grep -v '^\s*$' | grep -v '^#' | sort | uniq -d -c`, 2026-10-11]: `---` ×15, `|---|---|` ×7, `|---|---|---|` ×3, `|---|---|---|---|` ×3, `exit 0` ×3, plus fence markers. The check cannot pass, and the window will be tempted to loosen it.
Fix: compare multisets (`Counter(old) == Counter(new)`), as PLAN §3 already does for IDs.

**M2 — important — references break silently.**
See S00 F6. "No wording changes" plus bare `§N` means wrong pointers in 13 new files.

**M3 — minor — awk coverage proves nothing about overlaps.**
"sum of end-start+1 over rows == line count" can pass with one overlap plus one gap. `kb_migrate.py --check-only` (a flag the step does not define) should check that the intervals tile.

**M4 — minor (agent optimality) — 6 mapping agents for mostly mechanical work.**
Only O0 §4, O1 §2 and O1 §3 are split per bullet; the other 84 of the 87 headings map whole sections (S01's own table). A script can emit the section-level rows from the table, and one agent (or the main window) maps the three split sections. That saves ~5 agent starts (O0 §8: "Agent costs ~25–180k tokens at start").

**M5 — minor.**
"Interim routing: `CLAUDE.md` still routes to `O0…`": the skeleton routes only via l. 24 "`<kb>/O0-how-claude-works.md`". Name that line.

### S02-changelog-triage.md

**T1 — minor — "No KB file changes in this session" (Goal) vs step 5 "Append to `knowledge/recheck-and-conflicts.md`… (that is the only KB edit)".**
Pick one.

**T2 — minor — the KB version is ambiguous.**
Headers differ: O0 "Claude Code 2.1.289" but it already carries [CL 2.1.292–2.1.293] lines; O3 "2.1.289–2.1.291". State: "triage from 2.1.292; for 2.1.292–2.1.293 check O0's existing [CL] lines first".

**T3 — minor — agents get almost no routing information.**
After S01 the `Keywords:`/`Related:` headers are placeholders, so "first 15 lines of every knowledge/*.md" tells the triage agents only file names. Give them S01's target table (new file → old sections), which is in this prompt's sibling S01.

**T4 — minor — `Warsztat/CHANGELOG.md` must be committed for S03 and S05.**
Say so explicitly.

### S03-apply-and-tag.md

**A1 — important — the box-draining package edits other packages' files.**
Quote: "Two agents must never share a file. The `docs-index.md` and `recheck-and-conflicts.md` box-draining … its agent moves … each 'Deltas' item into the target topic file". That target file belongs to another, concurrent agent on the same checkout (O0 §3 "Default no isolation … shared checkout" [SOURCE]).
Fix: the main window first turns each "Deltas" item into an extra triage row for the owning package, and only then launches the editors.

**A2 — important — `--applied` is self-reported.**
Quote Done: "`triage_check.py … --applied` # every relevant row marked applied by an editor". Editors are never told how to mark rows, and a mark is a self-report.
Fix: `--applied` verifies by text. For a row with `replaces_line`, the old line is absent and a `[CL <version>` tag is present in `target_file`. For a new fact, the count of `[CL <version>` lines in `target_file` is ≥ the row count.

**A3 — important — the tag recognizer is undefined.**
Phase 1 needs the list of accepted notations (`[MEASURED`, `[CODE`, `[SOURCE`, `[OF`, `[S:`, `[CL`, `[BLOG]`, `[IS]`, `[3P`, `[UNCERTAIN`, `[ASSUMPTION`). That legend is in ClaudeEXPERT's CLAUDE.md "Evidence tags", which is not copied to FelixReborn (X2). Put the list in S00 or S03 verbatim.

**A4 — minor — the `[ASSUMPTION]` fallback mislabels doc facts.**
`[ASSUMPTION; untagged in source…]` mislabels a doc-derived fact whose tag was lost. Prefer `[UNTAGGED: needs source]`, so phase 1 can count these separately and BACKLOG lists them.

**A5 — minor — `As of:` "equals the current version in every topic file".**
This also stamps files that no changelog row touched. Acceptable only if the header means "changelog-reviewed through"; say so.

### S04-missing-pages.md

**P1 — important — packages share target files.**
- The API package targets `context-window-and-read.md`/`models-effort-cost.md`, which the context and models packages also edit.
- Step 4 (the main window's own promotion into `hooks.md` and `context-window-and-read.md`) has no stated order relative to the running agents.
Shared checkout, so the edits race (O0 §3).
Fix: one owner per target file. The API package writes a facts file that the models and context agents (or the main window) apply afterwards. Run step 4 after all agents finish.

**P2 — important — Routines and scheduled tasks are misrouted.**
Quote: "hooks package → `hooks.md`: CC `hooks`, `hooks-guide`, `routines`, `scheduled-tasks`". S11 reads `knowledge/headless-sdk-ci.md` "(scheduling: `/loop`, Routines, `/goal`)" to write the Routine spec, and O3 §7 (which becomes `headless-sdk-ci.md`) is where scheduling lives.
Fix: route `routines`/`scheduled-tasks` to `headless-sdk-ci.md` (and `desktop-scheduled-tasks` with them).

**P3 — minor.**
- Section numbers of not-yet-existing headings: "docs-index.md (the lookup method in its §2 and the verification procedure in §3)". S01's headings are chosen by the mapping agents, so cite headings by title.
- Fetch agents lack "403 = policy, don't retry" (O0 §7 [MEASURED]).
- Done `wc -l … # hashes ≥ pages` is not an exit code (phase 1b covers it).

**P4 — minor — `Warsztat/pages/` committed means doc pages in the repository history.**
This may be MBs. Commit `docs-hashes.tsv` and only the pages S05's verifier needs, or keep the pages out of git and re-fetch them by URL.

### S05-model-scope.md

**MS1 — important — the grep misses predecessor models that the owner excluded.**
Quote: "`grep -n -i -E 'sonnet|haiku|mythos|opus 4|opus-4|claude-3'`". It misses "Opus 5" and "Fable 5" (not 5.5/5.1).
Evidence [MEASURED: `grep -nE 'Opus 5([^.0-9]|$)|Fable 5([^.0-9]|$)' O*.md` → 38 lines, 2026-10-11], e.g. O0 l. 141 "(Opus 5) 'only serious' → reports less", l. 147 "T (Fable 5): every claim with a tool result". The phase-1c rule "a non-top model name" is left to the window to define. Some of these lines are the *only* Opus 5.5 guidance the KB has (O0 l. 141: "Opus 5.5: no separate advice (Opus 5 patterns = 'reasonable starting point')"), so deleting them loses the basis, and none of trap/component/why-not fits.
Fix: an explicit regex for all non-top names, plus a fourth marker `[scope: predecessor-advice]`, or an owner decision (Q5).

**MS2 — important — step 3 targets a list FelixReborn does not have.**
Quote: "The same two items sit in `CLAUDE.md`'s 'Known open conflicts'". The FelixReborn skeleton has no such section [MEASURED: grep → 0 hits]. `recheck-and-conflicts.md` will not hold a conflict list either: S01's sources for it (O0 §9, O1 Check again/§5, O2 §E, Verify live, Deltas) do not include ClaudeEXPERT's CLAUDE.md list. See X2.

**MS3 — important — the verifier's commit range is guesswork.**
Quote: "`git log -p origin/main..HEAD -- knowledge/` in the previous two merges, or `git diff <S02 merge>..HEAD`". At S05 start `origin/main..HEAD` is empty, and the cloud clone is shallow (O0 §7 "shallow clone from snapshot" [MEASURED]).
Fix: tag each merged step (PLAN §0.3 "przed merge tag `kb-pre-step-N`", "before merge, tag kb-pre-step-N"; no prompt creates these tags). Use `git fetch --unshallow --tags` and `git diff kb-step-02..kb-step-04 -- knowledge/`.

### S06-map.md

**N1 — important — `.claude/agents/` created mid-session will not load.**
Quote step 6: "2 custom agents defined in `.claude/agents/probe-omit.md` with `omitClaudeMd: true`".
Evidence: O0 §3 "New and changed agent definitions … work in session …; restart: agents dir created mid-session" [SOURCE: CC sub-agents.md].
Also: `.claude/` is a protected path that "always go[es] to" the classifier (O0 §4), and this prompt does not mention a refusal path.
Fix: create the directory in S00 (S00 F10), or pass the definition via `claude -p --agents '<json>'` (O3 §1) in a nested probe.

**N2 — important — step 3 moves a conflict list that does not exist, and step 7 targets a missing table.**
Quote step 3: "the one copy of the open-conflicts list (moved from `recheck-and-conflicts.md`; `CLAUDE.md` root keeps its copy until S13…)". Step 7: "`CLAUDE.md` root: the KB table → two lines". The skeleton has neither a conflicts list nor a KB table (X2).

**N3 — minor — transcript locations are not given.**
Quote: "check the JSON transcript for a `nested_memory` attachment" and "find each agent's transcript (`~/.claude/projects/*/` or the task output files…)". `--output-format json` carries no attachments. The nested run's JSONL is under `~/.claude/projects/<slug of its cwd>/`, and a nested `-p` reports the *parent's* `session_id` (findings 2026-10-11, A/C), so name the slug rule or log `transcript_path` with a temporary `--settings` hook.

**N4 — minor — missing named stop and dead step.**
- No named stop if navigation is < 4/5: tune `topics.json`, or file names? Say which, or "record and continue".
- Step 4 `reports/README.md`, `migration-kit/README.md`: these directories are not in FelixReborn. Drop the step.

**N5 — minor — agent count is at the edge.**
14 agents (12 probes + 2 reviewers); one re-run makes 16. Cut to 4+4+2 probes (still n ≥ 4 per type), or state that a re-run replaces, not adds.

### S07-probes.md

**PR1 — important — probe 1 is confounded by process restart.**
Quote: "force `/compact` (… or two turns via `--resume`)". Over `--resume` the second Read runs in a new process, so a content reply could come from a fresh in-memory read cache, not from compaction resetting it [ASSUMPTION: the dedup state's persistence across processes is not in the KB].
Fix: one process with several turns (`--input-format stream-json`, O3 §1): Read, then `/compact`, then Read.

**PR2 — important — fixtures land in the worktree, and `--settings` paths break.**
The hooks write `cat > tests/fixtures/…` relative to `/tmp/kbtest`, so the files land in the worktree. `--settings Warsztat/probes/<probe>.json` is uncommitted, so it is not in the worktree (O0 §3). Use absolute paths into the main checkout.

**PR3 — minor — probe 3 invites a premature NOT RUN.**
Quote: "If the Workflow tool is unavailable in `-p`, NOT RUN". O3 §5 states how to enable it: "`-p`/SDK need an allow rule `Workflow` or `Workflow(<name>)`, auto mode, bypass…". Add `--allowedTools Workflow`.

**PR4 — minor — probe 8's outcome is nondeterministic.**
Set `--permission-prompts none` (O3 §1: "`none` denies prompts") and read `permission_denials` from the JSON.

**PR5 — minor — done criteria are countable text.**
"`grep -c "MEASURED" docs/FINDINGS.md # increased by ≥ 11`" and "≥ 15 fixtures" can be met by writing the word or splitting files. Replace them with a script over `RESULTS.md`: 11 rows, each with n ≥ 2 and both results, or NOT RUN with a reason, and each named fixture exists. Also, `claude -p` runs may exceed Bash's 2-min default (O0 §7): set `timeout` or run them in the background.

### S08-injection-and-push-gate.md

**H1 — important — the SubagentStart payload exceeds the documented cap.**
Quote step 2: "`additionalContext` = `.claude/agent-rules.md` (… ≤ 3,000 characters) + the map". The map file is ≤ 9,500 B (S06), so the total is ~12,500 chars.
Evidence: O2 §A6 "10,000-char limit per `additionalContext`…; overflow goes to a file and Claude gets a 2,000-char preview". Every subagent would get a 2 KB preview, the same trap again.
Fix: inject agent-rules plus only the generated keyword→file lines, with a test asserting `len ≤ cap from S07 probe 11`.

**H2 — important — "the hand-written part … (the map)" contradicts S06.**
S06 defines the map as the *generated* part (keyword → file lines). The window has to guess which part SessionStart prints. Name the part by its markers.

**H3 — important — live push tests leave branches the session cannot delete.**
Quote step 7(i): "push with a deliberately broken header … → blocked (n=2)". If the gate fails open (the case under test), the push lands on GitHub, and the cloud cannot delete branches: O0 §7 "Push of new branch OK, branch deletion 403" [MEASURED].
Fix: push to a local bare remote (`git init --bare $SCRATCH/remote.git`), as probe B did (findings 2026-10-11 B). Also, the broken header must be in a `knowledge/*.md` file; "a scratch file" outside `knowledge/` is not checked.

**H4 — important — the push gate can trap work in a disposable VM.**
Handler (a) runs `kb_check.py --tree HEAD` and `test_hooks.sh` on every `git push` of every later session, with `onFailure: "block"`. A half-done S09 with one red fixture cannot push, and "ignored and unpushed files then most likely lost" after VM reclaim (O0 §7 [ASSUMPTION]). The in-session kill switch is an environment variable that only the owner can change, for a new session (prompt rule "The owner sets `off` in the cloud environment variables").
Fix (owner choice, Q8): the gate blocks only refspecs that target `main`, and branch pushes get a warning. Or allow `HEAD:refs/heads/wip/*`. CI from `main` remains the hard backstop for merges.

**H5 — important — classifier refusal: "keep it in the branch" is impossible.**
Quote rules: "if the edit is refused, keep it in the branch and tell the owner". A refused edit is never written.
Evidence: O0 §4 "protected paths (.claude/ …) – those always go to it"; findings 2026-10-06 (2 refusals).
Fix: on refusal, write the intended content to `Warsztat/proposed/.claude/...`, commit it, and tell the owner which file to copy on GitHub. The live tests can still run via `--settings` on the Warsztat copy.

**H6 — important — the done criterion proves nothing about the live tests.**
Quote: "`jq -s 'length' .claude/kbgate/*.jsonl # ≥ 1 row from the live tests`". Live tests run from `/tmp/kbtest`, so their rows go to `/tmp/kbtest/.claude/kbgate/` (`${CLAUDE_PROJECT_DIR}` "does not follow worktrees" is about the start directory: O2 §A7). Meanwhile the building session's own reads are logged in the root once settings are live (O0 §3 "hooks … work in session"). The criterion passes without any live test.
Fix: assert on the worktree log with a filter on the test's `transcript_path`.

**H7 — important — no prompt-topic logging, so S09's baseline cannot be computed.**
S09 step 8 wants "per prompt that matched a topic, did a full read … happen before the first assistant message", but S08's logger records reads only, with no prompt and no topic match. Add a UserPromptSubmit logger (`prompt_id`, matched topics via `kb_topics.py`, which exists since S06) in S08.

**H8 — minor — paths, the Stop advisory, and PC behaviour.**
- Hook commands should use `${CLAUDE_PROJECT_DIR}/tools/...`. `cwd` "follows `cd`" (O2 §A4), and with `onFailure: "block"` a relative path after a `cd` blocks every push.
- Stop advisory via `systemMessage` reaches the user, not Claude (O2 §A6 "`systemMessage`: message to the user"). If Claude is the audience, use Stop `hookSpecificOutput.additionalContext` (O2 §A5).
- STATUS "Live mechanisms" should say "cloud only": the `CLAUDE_CODE_REMOTE` guard turns every hook off on the PC.

### S09-read-gate-main.md

**G1 — important — the baseline data is not representative.**
S09–S11 are construction sessions whose prompts name many topics. PLAN 3b(d) asked for "≥ 2 realne sesje" ("≥ 2 real sessions"). No ordinary Q&A sessions are scheduled before S12, which "still proceed[s]" to block. The measurement that justifies the gate's cost is therefore never taken.
Fix (owner, Q6): 2–3 ordinary Q&A sessions between S09 and S12, or say plainly that S12 tunes on construction-session data.

**G2 — important — the read gate conflicts with COMMON §1 once block mode is on.**
COMMON §1: "Do not read 'to be safe' beyond the list". The read gate requires files that may not be on the session prompt's list, and "PreToolUse 'read first'" blocks everything else until they are read. The window then has two contradictory rules (and must read COMMON first while the gate blocks it).
Fix: COMMON §1 adds "files named by the read gate count as listed; read them first".

**G3 — minor — done criteria with no failing exit.**
`jq -c 'select(.event=="stop_decision')' … | head -3` exits 0 with no rows. Use `jq -e`/`grep -q`. The same applies to S10.

**G4 — minor — the Stop design is deliberate but loop-prone.**
"Never exit early on `stop_hook_active`" relies on the 8-block cap (O2 §A5: "Always check `stop_hook_active`"). With topic matching also on `last_assistant_message`, almost every reply in this project mentions hooks or agents, so loops are likely. Make the log count blocks per `prompt_id` (it does) and treat ≥ 3 per prompt as a tuning signal in S12.

### S10-read-gate-agents.md

**GA1 — minor — reviewer.md is "used from S11", but COMMON §4 still uses general-purpose reviewers.**
Correctly so, since they need Bash to run done commands. State that `reviewer.md` is for the skeleton's l. 30 per-change review, not for the end-of-session pair.

**GA2 — minor — agents spawned inside nested runs.**
Live tests spawn agents inside a nested `-p` (A ×2, B ×2, Explore ×1). Whether these count toward the 15 cap is unstated (Q4). Under either reading S10 stays ≤ 15.

**GA3 — minor — `.claude/agents/reviewer.md` creation has the same classifier caveat as H5.**

### S11-freshness.md

**FR1 — minor — the 24-hour cache never hits in the cloud.**
The cache file is in `.claude/kbgate/`, which is per VM, and "Fresh Firecracker VM per session" (O0 §7). Every session start therefore pays up to 10 s of curl. Acceptable, but say so, or commit the cache.

**FR2 — minor — wrong file for "Check again".**
It reads "`knowledge/docs-index.md` (§2…, §3…, 'Check again')", but S01 routes "Check again" to `recheck-and-conflicts.md`. Routines facts are in `hooks.md` after S04 (P2).

**FR3 — minor — the hook file name is a glob.**
`.claude/hooks/sessionstart*` assumes a name S08 never fixes. Fix the name in S08.

### S12-enforce-and-lock.md

**L1 — important — ordering bug: step 5 blocks step 6.**
Step 5 installs a ConfigChange hook that "exits 2" on `project_settings` in block mode (default switched to block in step 4). It also installs the `ask` rule on `Edit(/.claude/settings.json)`. Step 6 then edits `.claude/settings.json` (deny list), which is now asked or blocked. In the cloud, a pending ask is inactivity (O0 §7).
Fix: one final settings edit containing the deny list, the ask rules and the ConfigChange hook, made after every other step.

**L2 — important — ConfigChange blocks honest changes the owner has approved.**
After S12, ConfigChange exits 2 on any settings change, so an owner-approved edit is blocked anyway. This contradicts the goal: "so an honest change needs the owner's yes in the session".
Fix: ConfigChange in log mode (record and warn), and let the `ask` rule carry the consent. Probe 6 decides what "block" even means.

**L3 — important — the A/B probe cannot detect what it targets.**
Quote step 3: "a full read of `hooks.md` is simulated by including its text at the top, then 6 unrelated short tasks, then a precise question". All of this sits in one fresh ~15k-token prompt. The phenomenon is distance and compaction over a long session (O0 §1: "degrades gradually with fill (context rot), no numeric threshold"). Both arms will be at ceiling, and "better by ≥ 2 of 3" will read the null as evidence for "one read per epoch".
Fix: either drop it (save 6 agents) or put ≥ 200k tokens of real intervening work before the question, with n ≥ 5 per arm and the grading done by script against the exact line.

**L4 — important — the ask list is narrower than CLAUDE.md promises.**
Skeleton l. 19 promises `ask` "on this file, settings, agent-rules, agents, hooks, rules and skills". S12's list lacks `Edit(/CLAUDE.md)`, `Edit(/.claude/agents/**)`, `Edit(/.claude/rules/**)` and `Edit(/.claude/skills/**)`. S13's reviewers check "nothing claimed as live that `STATUS.md` does not list".
Fix: add them, or change l. 19.

**L5 — important — the step is overloaded.**
One session does log analysis, tuning, the A/B probe, the block switch, the ask lock, the MCP deny and `export_template`. The owner asked for one step per session. Split it: S12a analysis, tuning and block switch; S12b lock, deny and export.

**L6 — minor — `Gotowe/` duplicates the KB in the working tree.**
`Gotowe/CLAUDE.md` and `Gotowe/knowledge/CLAUDE.md` are nested memory that loads when any file under them is touched (O0 §2). Every `grep -r` hit appears twice, and the read logger's path normalisation may count `Gotowe/knowledge/hooks.md` as `knowledge/hooks.md`.
Fix: `claudeMdExcludes: ["Gotowe/**/CLAUDE.md"]` (O2 §D3), exclude `Gotowe/` in the logger, or build `Gotowe/` as a release artifact instead of a committed tree.

**L7 — minor — `grep -c '"ask"'` counts lines.**
It does not verify the 8 rules. Use `jq '.permissions.ask | length'` and compare with the expected list.

### S13-claude-md.md

**CM1 — important — step 2 removes sections FelixReborn does not have.**
Quote: "remove the KB table, the evidence-tag legend, 'Known open conflicts', 'Freshness' and 'Live lookups' …; remove 'Read O0 in full once per session' …; move 'Reviewing designs for other Claude systems'". These are ClaudeEXPERT CLAUDE.md sections (l. 44, 60, 69, 74, 98 there); the skeleton has none of them [MEASURED: grep → 0 hits]. Meanwhile the fixes review 01 actually lists for the skeleton are not scheduled: §1 points 1–3 and the §2 rows for l. 7, 23, 24, 44, 45, 65, 68. S13 cites only "review §3".
Fix: rewrite step 2 against the skeleton, embedding review 01 §1, §2 and §3 verbatim in the prompt (the review is in ClaudeEXPERT, and S13 reads it only "if the owner copied it").

**CM2 — important — the measurement is wrong.**
Quote step 1: "read `usage.input_tokens` of its first call". With prompt caching, `input_tokens` excludes `cache_creation_input_tokens` and `cache_read_input_tokens`. O0 §2's start sizes are totals (e.g. "general-purpose … 58.7k").
Fix: the sum of the three fields.

**CM3 — minor — the old-reference grep misses most citations, and the proposed diff will not apply.**
`grep -rn "O[0-5]-"` matches only file names; citations look like "O0 §4" (20 in KB text [MEASURED], many more in the FINDINGS files). Use `O[0-5] §`. "docs-index.md §5 'CLAUDE.md snippet'": S01 routes O1 §5 to `recheck-and-conflicts.md`.
Also, `Warsztat/CLAUDE.md.proposed.diff` accumulated by appending from S01, S05, S06 and S08 will not apply as one patch. Keep one numbered patch per session instead.

---

## 3. Cross-cutting findings

**X1 — important — the owner's "every read verified by a script" is unmet for S00–S11.**
Requirement: "An agent assigned a topic must read the whole relevant file, verified by a script; same for the main session".
- Agents: their reads in S01–S07 (mapping, triage, editors, fetchers, navigation probes, reviewers) are never verified. The first verification is S10 (log-only) and S12 (block), and only for general-purpose agents.
- Main session: the main session's reads are never verified before S09.
- "Read in full" lists: they contain partial reads (S00, S02, S04, S06), against COMMON §1.
Feasible today without hooks: transcripts are under `~/.claude/projects/` (O3 §9 [OF]); Read `tool_response` carries `startLine`, `numLines`, `totalLines` (findings P1); Bash `stdout` equality after `rstrip("\n")` (findings R6b/A).
Fix: S00 builds `tools/verify_reads.py <transcript.jsonl> <file>...` with exactly the S08 full-read definition. COMMON §2 requires running it on every agent's transcript after each wave and on the main transcript before the reviewers, with output pasted; failure means re-run the agent. S08's logger reuses the same function.

**X2 — important — adaptation errors: ClaudeEXPERT-only artefacts.**
- Missing from FelixReborn: the evidence-tag legend, the open-conflicts list (5 items), the KB routing table, "Freshness", "Live lookups" and "Reviewing designs" live in ClaudeEXPERT's root CLAUDE.md, not in `knowledge/` or `findings.md`, which are all FelixReborn receives.
- Prompts that depend on them: S03's tag regex (A3), S05 step 3 (MS2), S06 step 3 (N2) and S13 step 2 (CM1).
- `knowledge/FINDINGS-claudeexpert.md` inside `knowledge/`: it is a `knowledge/*.md` file with no `As of:` (phase 1a fails), it names Sonnet and Haiku (phase 1c fails), and no topic covers it (phase 2 fails). No prompt moves or excludes it.
Fix: before S00 the owner also copies those CLAUDE.md sections to `docs/import/claudeexpert-claude-md-sections.md`; S00 turns the conflict list and the tag legend into `knowledge/` content. Move the findings copy to `docs/import/` (outside `knowledge/`), or give it an explicit exclusion in `kb_check`.

**X3 — important — phases are not defined as cumulative.**
- Phase names: 0, 1a, 1, 1b, 1c, 2, and 1a runs before 1.
- Runs without `--phase`: S08–S13 run `kb_check.py --tree HEAD` without `--phase`, so they use STATE's phase (2 after S06). The push gate does the same.
- Effect: unless phase 2 includes 0–1c, tag, size and model-scope checks silently drop out of CI and the push gate.
Fix: one ordered list in S00 (`0 < 1a < 1 < 1b < 1c < 2`), with every phase running all earlier ones.

**X4 — important — "hard over soft" is missed where it is cheap: the session protocol itself.**
The end-of-session protocol is instruction only: two reviews, done commands, STATUS, push. KB: "check unattended completion with Stop hook running a script (deterministic) … not self-report alone" (O0 §8).
Fix: from S08, a Stop hook in log, then block, mode checks:
- `docs/reviews/<Sxx>-fable.md` and `-opus.md` exist;
- `STATUS.md` changed vs `origin/main`;
- no unpushed commits;
- the done commands listed in `docs/prompts/<Sxx>*.md` exit 0 (parsed from the fenced block).

**X5 — important — rollback is dropped.**
PLAN §0.3 "przed merge tag `kb-pre-step-N`, cofnięcie = revert merge'a" ("before merge, tag kb-pre-step-N; rollback = revert of the merge"). No prompt creates tags. This also breaks S05's commit range (MS3). Add tag creation to COMMON §3 (owner or session; tag pushes go through the git proxy [ASSUMPTION: not measured]).

**X6 — minor — PLAN items silently dropped.**
- 3a′ PostToolUse "grep -r" map hook;
- 3c.6 injecting the matched section via `additionalContext` (owner Q3b);
- 1a "verify `autoCompactWindow`, `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`; Haiku 4.5 → `claude-haiku-5-5` for titles";
- the `Bash(gh pr merge *)` / `Bash(gh api *)` rules (defensible under the new threat model; say so in STATUS).
Note them in `docs/BACKLOG.md` in S00, so the drop is a decision, not an omission.

**X7 — agent use per session (D), owner cap 15.**

| Session | Agents incl. 2 reviewers | Assessment |
|---|---|---|
| S00 | 3 | justified |
| S01 | 8 | 5 of 6 mappers replaceable by script (M4) |
| S02 | 6 (≤ 10 with re-sends) | justified |
| S03 | 9 | justified; box package collision (A1) |
| S04 | 10 | justified; file ownership collisions (P1) |
| S05 | 3 | justified |
| S06 | 14 | at the edge (N5); 2 probes fail as designed (N1) |
| S07 | 2 | justified (probes are `-p`) |
| S08–S09 | 2 | justified |
| S10 | 2 + 5 inside nested `-p` | cap reading open (Q4) |
| S11 | 2 | justified |
| S12 | 8 + 4 inside nested `-p` | the 6 A/B agents measure nothing (L3) |
| S13 | 4 | justified |

No agent should blow its context; the largest is S04's hooks package (4 pages read in parts plus `hooks.md`), well under the 1M window (O0 §1). The reviewer brief is concrete (ordered categories, quote-the-KB, severity, "nothing found" allowed). Its weak point is the truncated diff (C3).

**X8 — done criteria judged by self-report (E).**
- S03 `--applied` (A2);
- S06 navigation pass/fail (prose table);
- S07 counts (PR5);
- S08 `jq length` (H6);
- S09/S10 `head -3` (G3);
- S12 `grep -c` (L7);
- S00 "CI green" (F3).
Everything else is a command with an exit code.

---

## 4. Nothing found

- **Hook event/field usage vs O2 §A5–§A7 and findings.** Checked: UserPromptSubmit stdout to context and its 30 s timeout; PreToolUse `updatedInput` replacing the whole input (whole-object copy in S10); SubagentStart/SubagentStop/Stop fields (`agent_transcript_path`, `last_assistant_message`, `stop_hook_active`); `if` only on PreToolUse with `onFailure: "block"` on the narrow handler; matcher syntax (`Read|Bash`, `^(general-purpose|…)$`, `project_settings|local_settings`); PostCompact/ConfigChange existence; the SessionStart 10,000-char cap (probed in S07). Correct, apart from H1 and H8.
- **Full-read definition (S08 step 4).** Matches findings P1, R6b and A exactly, including `rstrip("\n")` and `persistedOutputPath`.
- **`claude -p` flags.** Every nested run sets `--model`, `--effort`, `--permission-mode`, `--max-turns` and `--max-budget-usd` (O0 §5/§8; CLAUDE.md "Experiments").
- **Model and effort.** Aliases `opus`/`fable` and the Agent `effort` parameter match O0 §3/§5 [CL 2.1.292]. Only Opus 5.5 and Fable 5.1 are used.
- **`pull_request_target`.** Correctly marked as to-verify, with an `[ASSUMPTION]` fallback (S00 step 6). See F7 for the method.
- **Cloud single-repo / start-directory rule.** Respected (COMMON §2; review 01 §4.3).
- **S11 Routine specification.** Unattended-run rules (explicit model/effort, `--check` exit code, named stops, "do not create it yourself") are consistent with O0 §6/§8.

---

## 5. Open questions only the owner can answer

1. **Visibility.** Is FelixReborn public, or private on a paid plan? Branch protection, and with it the only hard server-side gate, depends on it (O0 §7).
2. **Layout and skeleton fixes.** Do you accept "root = live system, `Gotowe/` generated, `Warsztat/` = drafts"? Will you fix skeleton l. 7, 15 and 45 yourself before S00, or authorise COMMON to override them until S13 (C1)?
3. **ClaudeEXPERT-only material.** Should the open-conflicts list and the evidence-tag legend from ClaudeEXPERT's CLAUDE.md come with the KB copy (X2)? Where should the `findings.md` copy live?
4. **Agent cap.** Do agents spawned inside nested `claude -p` probes count toward the 15-agent cap?
5. **Predecessor advice.** Lines that carry Opus 5 / Fable 5 advice (the only basis for some Opus 5.5 guidance): keep them under a new `[scope: predecessor-advice]` marker, or delete them (MS1)?
6. **Baseline sessions.** Will you run 2–3 ordinary Q&A sessions between S09 and S12, so the block decision rests on representative data (G1)?
7. **Merge policy.** COMMON says "Never touch `main`"; skeleton merge policy A lets the session merge. Which one?
8. **Push gate scope.** Should the push gate block every push of a failing tree (risk: work trapped in a disposable VM), or only pushes targeting `main`, with branch pushes warned (H4)?
9. **KB in the template.** Full `knowledge/`, or `--kb minimal` (review 01 §4.2)? Needed by S12 step 7.
