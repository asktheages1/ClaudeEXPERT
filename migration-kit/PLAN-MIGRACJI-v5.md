# Documentation migration plan v5 (reusable template; Foldery values as the worked example)

Version 5.1 · 2026-10-09 · replaces ClaudeEXPERT `reports/foldery-migration-plan.md` v4.2 and
`reports/zasady-migracji-dokumentacji.md` (branch `AAA-dok-review`), `reports/doc-migration-playbook.md` (main) where
they conflict, and Foldery `GaleriaFolderow/dokumentacja/przekazanie/PROMPT-etap-B-partia.md`. Built from the measured
course of the Foldery migration (transcripts, costs, commits) and checked by 7 control agents; every change and every
rejected finding: `ZMIANY-v5.md`.

## Package (all files belong together)
| File | For | Size cap |
|---|---|---|
| `JAK-ZACZAC.md` | owner (Polish, phone): what to start, when, what it costs | 3 KB |
| `PLAN-MIGRACJI-v5.md` (this) | advisor and executors: what and why | 25 KB |
| `PROMPT-ANALIZA-I-PLAN-v2.md` | advisor session: measure, size class, decision sheet, filled prompts | 15 KB |
| `PROMPT-ETAP-A-v2.md` | executor: stage A (mechanical move + harness) | 18 KB |
| `PROMPT-ETAP-B-v2.md` | executor: stage B + C (rewrite with agents, clean-up, acceptance of A) | 24 KB |
| `PROMPT-PRZEGLAD.md` | any later session: health check of the doc system | 4 KB |
| `PROMPT-FOLDERY-ETAP-C.md` | Foldery only: the clean-up its migration never did; produces the reference harness | 8 KB |
| `ZMIANY-v5.md` | owner, next advisor: defect → fix, review decisions | — |
Where it should live: ClaudeEXPERT `main`, folder `migration-kit/` (owner decision, `ZMIANY-v5.md` §4). Until then the
owner keeps the files; the advisor session gets them from that folder.

## 0. The idea
1. Measure what loads automatically, and when (Foldery: 0 tokens at start, then 239.9k at the first touch of
   `GaleriaFolderow/` — an on-demand nested `CLAUDE.md` invisible to `/context` at start).
2. Pick the size class: none / light / full (§2). Most of the benefit comes from stage A alone.
3. Stage A moves text by script, provably losslessly, and installs a small harness (Foldery result: 4k tokens at start,
   ≈ 17k with the code rule).
4. Stage B rewrites every moved file to the current state in ONE session with writer + reviewer agents after a pilot;
   stage C, in the same session, removes every transitional mechanism. Stage A is accepted at the start of that
   session (a new session sees what successors see).
5. The owner answers ≤ 6 questions once, at the start; his standing rules apply without asking.

## 1. Success criteria
| # | Criterion | Check |
|---|---|---|
| K1 | Project instructions at session start ≤ 8k tokens | `claude -p "/context" --model opus --effort high --permission-mode default --max-turns 1 --max-budget-usd 0.5` in the repo root (0 USD) |
| K2 | Instructions after the first touch of the main code file ≤ 25k | K1 + tokens of every `paths` rule matching that file, measured by import (scratch `CLAUDE.md` with `- @<copy of the rule>`); presence: the first Read of the file shows the rule's contents reminder |
| K3 | Every doc file ≤ 40 KB, rules ≤ the rule cap (§5) | doc gate |
| K4 | Stage A lossless | concordance = 100 % on a recorded SHA + auditor review of „archive only” lines and of rewritten targets |
| K5 | Push gate blocks the cases of §5 and passes honest pushes | hook test + dry-run provocations |
| K6 | Logic tests + static checks green after each stage (docs and comments change, not behaviour) | test runner subset |
| K7 | End state: no moved-verbatim header, no freeze or concordance tooling, no `archiwum/`, no `MIGRACJA/`, no CHANGELOG „Status log” | one grep list in stage C |
| K8 | Owner-started sessions: 3 (advisor, A, B+C) — plus 1 restart if the source loads at start (§6 A) | count |

## 2. Size class and decision sheet
Size class (advisor, from measurements):
- **none** — start ≤ 15k tokens and no instruction/doc file > 40 KB: only the standing rules in `CLAUDE.md`, the minimal
  harness (§5) and a navigation table. One executor session ≈ 10–20 USD. No stage B.
- **light** — moved docs ≤ ~60 KB: stage A and the rewrite in one session, writer + reviewer in the main window.
- **full** — larger: stage A, then B+C with agent waves.
Break-even (for the owner): one-off cost ÷ (tokens saved per call × calls per week × price) — say it in weeks.

Standing owner rules (apply without asking; source: owner's words 2026-10-02…08):
replies Polish, short, strict but fair; the owner reads on a phone and never pastes or uploads anything; every result
in files, delivered with SendUserFile; every file Claude reads as instructions or docs is English, owner-facing files
Polish; Opus 5.5 effort `high` minimum for every session, agent and `claude -p`; files the owner runs are `.bat`
(ASCII, CRLF); reply ending „Zmiany w tej odpowiedzi” → „Następny krok” → `## ❓ Pytanie do Ciebie`; suboptimal
requests are challenged before work; commit + push + merge to `main` at the end of every piece of work.

Decision sheet — at most 6 questions, 2 AskUserQuestion calls, each with consequences and the recommended option first:
| # | Question | Recommendation |
|---|---|---|
| D1 | Size class none / light / full (with cost and break-even) | the measured class |
| D2 | Stage B: all moved files incl. spec files in ONE session with agents (spec points the code contradicts come to you at the end) | yes |
| D3 | Delivery zip: keep committing it to the repo, or only send it (SendUserFile) | only send it [Foldery: zips ≈ 90 % of a 60–100 MB clone; stopping commits stops growth, does not shrink the history] |
| D4 | May stage B run while you are away (it wakes itself, resumes after restarts) | yes |
| D5 | Up to ~10 agents at once in stage B (5 writers + 5 reviewers) — normal for the Agent tool | yes [Foldery: not told beforehand] |
| D6 | Health check later: monthly scheduled check (≈ 5 USD/run) or a reminder line at session start after 90 days | reminder line |
A decision not on the sheet: the executor takes this plan's recommendation, records it in the progress file, and asks
in its final reply. Decisions that govern future sessions (D3, D6, language) become owner rules in the target's
`CLAUDE.md` + a dated line in its rules log during stage A.

## 3. Roles and channels
- **Advisor** (one session, ClaudeEXPERT only, Opus high): measures, writes the filled prompts. Reads docs live (per
  `knowledge/O1`: `curl -sL https://code.claude.com/docs/en/<page>.md` into scratch, grep, Read with offset) and O0
  once; never checks out `AAA-dok-review` (its `CLAUDE.md` preloads ~217k tokens). Delivers into the target through a
  pushed branch + PR; never pushes the target's `main` (its pushes bypass the target's hooks).
- **Executors**: target-only sessions (so the target's hooks and `settings.json` load).
- **Frozen prompts**: once an executor session starts, nobody edits its prompt or sends it addenda from another
  session; corrections go into the next prompt.
- **Owner channel**: every reply that ends a phase lists deliverables (paths), decisions with consequences and a
  recommendation, and the exact first message of the next session. AskUserQuestion only when the owner wrote in the
  last 10 minutes; otherwise take the recommendation and ask in the final reply.
- **Evidence**: every fact a prompt relies on is written into it with its tag (`[MEASURED …]`, `[SOURCE: CC <page>]`,
  `[ASSUMPTION]`); no pointers to files the executor cannot open.

## 4. Review policy (plan, prompts, harness)
- Every reviewer works in a clone of the target, verifies the plan's premises by a command, and gets the owner's scope
  list verbatim (Foldery: one round was wasted on „monorepo on macOS”).
- Every reviewer answers both: „what is missing or wrong” and „what is unnecessary — what to cut”, each finding with
  the realistic failure it prevents and the cost it adds. „Realistic” = a form seen in a transcript or used by our own
  prompts and skills (`HEAD:main`, `<branch>:main`, `cd x && git push`, bare `git push` on `main`). Anything else is a
  documented known limit, not code.
- Protected (cut only with a measured reason): `git mv` of an on-demand source before opening it; scripted copy +
  concordance; hook shell form with file-exists guard; dry-run provocations; independent auditors; one reviewer per
  rewritten file; pilot with go/no-go.
- Rounds stop when a round yields no blocking or important finding; a third round needs the owner's OK. A second round
  re-checks only what changed.
- The executor implements exactly the option text the owner approved; anything beyond it is asked again.

## 5. Harness: minimal and proportional
Reference implementation: Foldery `.claude/hooks/hooks.py`, `.claude/settings.json`, `GaleriaFolderow/tools/test_hooks.sh`
after `PROMPT-FOLDERY-ETAP-C.md` (post-audit hook minus the freeze logic and the exotic-form parsing). New projects copy
these three files (advisor, via read access to Foldery) and add project cases to the test; nobody retypes a hook.
- **deny** (exact): `mcp__github__{push_files,create_or_update_file,delete_file,merge_pull_request,enable_pr_auto_merge,
  update_pull_request_branch,actions_run_trigger}`; `Bash(git push --force*)`, `Bash(git push -f*)`, `Bash(git push *
  --force*)`, `Bash(git push * -f*)`, `Bash(gh pr merge*)`, `Bash(gh workflow run*)`, `Bash(gh run rerun*)`,
  `Bash(gh api *merge*)`, `Bash(gh api *-X*)`, `Bash(gh api *--method*)`, `Bash(gh api *-f *)`, `Bash(gh api *-F *)`,
  `Bash(gh api *--field*)`, `Bash(gh api *--raw-field*)`, `Bash(gh api *--input*)`. (`create_pull_request`
  stays allowed: it is the merge fallback.) Deny applies to any subcommand of a compound command [SOURCE: CC
  permissions, „Compound commands”].
- **hooks** (one Python file, shell form `[ ! -f "$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py" ] || exec python3 -I
  "$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py" <cmd>` — exec form with a missing file exits 2 and blocks every Bash
  call [MEASURED]; non-blocking commands always exit 0; internal time budget < hook timeout, because a timed-out
  PreToolUse hook does not block [SOURCE: CC hooks, „Timeouts”]):
  - `bash` (PreToolUse Bash, timeout 120): commands split on `&&`, `;`, `||`, `|`, with `cd` / `git -C` followed. Every
    `git push`: force, `+refspec`, `--mirror`, `--all`, wildcard and `:` refspecs → block; any workflow trigger other than `workflow_dispatch` (disk and
    HEAD) → block — this applies to session-branch pushes too. Push to `main` = any refspec whose destination is
    `main` (`main`, `<x>:main`, `<x>:heads/main`, `<x>:refs/heads/main`) or no refspec while on `main`: source must be
    HEAD; `git fetch origin main` first; branch diff vs `origin/main` must change STATUS, and a code change needs
    CHANGELOG + a doc file (or the line „docs: bez zmian (reason)”); doc gate green; tracked tree clean; merge/fetch/
    checkout and the push to `main` in one call → block. Session-branch pushes otherwise pass.
  - `edit` (PreToolUse Edit|Write): writes into the backup folder → block.
  - `turn` (UserPromptSubmit) + `stop` (Stop): `turn` records HEAD and a status hash; `stop` reminds once when files
    changed and the reply lacks „Zmiany w tej odpowiedzi”. Only where the owner rules require that list.
  - `session` (SessionStart, matcher `startup|resume|compact`, so it also returns after compaction): version, branch vs
    `origin/main`, top of STATUS, and „przegląd zaległy — uruchom /przeglad” when the STATUS line „Ostatni przegląd:
    <date> <SHA>” is > 90 days old or missing (D6); `CLAUDE.md` says every STATUS overwrite keeps that line. The check itself is the skill `/przeglad` (from `PROMPT-PRZEGLAD.md`).
  - `subagent` (SubagentStart): injects the agent rules file.
- **Known limits** (documented in `CLAUDE.md`, tested as „exit 0, recorded”, never „fixed”): push from inside a script,
  `sh -c`, `xargs`, `$(…)`, git aliases, `GIT_DIR`/`--git-dir`. Hard on every path
  only: server-side branch protection with admin bypass disabled (private repo: paid plan). Deleting `main` is already
  refused by the cloud git proxy (403).
- **Disable path** if a hook ever blocks honest work: `"disableAllHooks": true` in `.claude/settings.local.json`
  (protected path: one approval) [SOURCE: CC hooks, „Disable or remove hooks”].
- **Doc gate** (script run by the tests; reads through one `read()` function so a mutation test can swap it): version
  line in CHANGELOG, STATUS, README line 1; byte caps (`CLAUDE.md` 11 000, rules = (25k − K1) × measured bytes/token,
  English ≈ 36 000, Polish ≈ 30 000; agent rules 9 000 chars; navigation and docs 40 000; STATUS 6 000); size
  annotations in the navigation table; dead backticked paths; CI triggers; rule, agent and skill frontmatter; no
  `^\*\*v\d+\.` lead-ins in files with the current-state header (the guard against appended layers); CHANGELOG:
  version lines in non-increasing order (equal allowed) directly under the heading `## Versions (newest first)`.
- **Repository hygiene**: nothing is committed after a merge (no SHAs, no „repackaged” notes); `/dostawa` resets the
  container's stale local `main` with `git checkout -B main origin/main` (the „unrelated histories” error hit 5 of 5
  Foldery sessions); the zip follows D3.
- **Not built**: sha freeze list, concordance freeze mode, frozen-file test block, „only remove rows” rule, permanent
  „condensed” header gate, edit-time workflow check (push-time is the guard), `delete main` rule.

## 6. Stages
### Advisor — `PROMPT-ANALIZA-I-PLAN-v2.md` (≈ 25–40 USD [ASSUMPTION; Foldery spent 91.7 USD in 5 sessions])
Measure (full clone, repacked), size class, decision sheet, filled prompts A and B (or the „none” / „light” variant),
≤ 2 review agents, PR into the target.

### Stage A — `PROMPT-ETAP-A-v2.md` (Foldery: 22.5 USD, 63 min, 13 of them a full test run now dropped)
1. If the source loads at start (root `CLAUDE.md`, `.claude/CLAUDE.md`, unscoped rule or its `@` imports): `git mv` +
   commit + merge into `main`, stop; the owner restarts the session from `main` (the running one keeps the start
   version). If it is on-demand
   (nested): `git mv` before any Read/Edit/Write or single-file `cat`/`head`/`tail`/`sed -n`/`grep` under its folder.
2. Concordance by line ranges from a lead-in list; copy only by script; version list of the changelog reordered by
   script into one newest-first list (multiset concordance stays 100 %); 100 % on a recorded SHA.
3. Navigation: short `CLAUDE.md` (with the standing rules and the lasting D answers), STATUS, navigation table, doc
   gate + mutation test, harness from the reference files, `/dostawa` with the merge recipe; one commit.
4. Acceptance in the session: provocations; logic + static tests; two auditors (lossless incl. „archive only” lines
   and rewritten targets; enforcement incl. „worth its cost?”). Merge.

### Stage B + C — `PROMPT-ETAP-B-v2.md` (≈ 110–150 USD, 1.5–2 h [ASSUMPTION from the Foldery batch: 89.35 USD,
50 min for 14 rewrites + 7 translations; v5 scope 25 units ≈ 2.2× the bytes]; re-estimated after the pilot)
Acceptance of A (K1, K2, one provocation, stop reminder) → pilot of 2 units, with a 3-line sample shown to the owner
before he leaves → waves (≤ 10 agents running in total, resumed ones included) → one reviewer per file, every
blocking/important fix verified by grep → sweep → clean-up (C) → decisions (applied to spec files if the owner is
present) → delivery. A watchdog wake-up and a resume section survive VM restarts and compaction.

### Afterwards — `PROMPT-PRZEGLAD.md` (≈ 3–5 USD)
Triggered by D6: re-measure K1/K2, doc gate, files grown > 20 % since stage C, CHANGELOG order, STATUS size, leftover
migration text, bytes/token after a model change; `/doctor prompt-audit` date in STATUS.

## 7. Estimates are priors
Measured Foldery numbers (advisor 91.7 USD / 5 sessions; A 22.5 USD / 63 min; per-file condensation 3.56–8.14 USD each;
batch 89.35 USD / 50 min / 37 agent starts / peak ≈ 8 at once; spec session 30.76 USD for 2 files) are priors, not
promises. Every executor re-estimates from its own pilot (measured USD per unit × remaining units) and reports it as
information. No money limits: the owner never set one, and a cost stop would leave work half-done or a session waiting
for him. Cost is read from `get_session` as the last tool call of a reply.

## 8. Risks
| Risk | Prevention |
|---|---|
| VM paused or reclaimed while agents run (owner away) | commit + push per unit; `worker_epoch` + process start recorded; self wake-up with `send_later`; resume section; compaction trigger re-reads the prompt |
| Usage window exhausted | `get_session` rate limit before every launch; `isUsingOverage` = stop launching |
| Main context too large (Foldery batch: 451k) | short agent reports (≤ 10 / ≤ 20 lines); automatic compaction (~784k) is survived by the resume section's step 0 (re-read prompt + ledger) |
| Writers drop or invent content | one reviewer per file; growth ≤ old + 10 % unless justified; fixes grep-verified |
| Spec meaning changed | spec brief, point-number gate, re-review always; disagreements go to the owner |
| Classifier refuses `.claude/` / `CLAUDE.md` edits or the merge | owner switches to Accept edits once, or PR; listed in the final reply |
| A hook blocks honest work | positive test cases, dry-run provocations, disable path (§5) |

## 9. Rollback
Before merge: drop the branch. After merge: one forward commit `git restore --source=<old main> --staged --worktree :/`.

## 10. Reuse checklist (another app)
Replace: repo and folder names, main code file and its `paths` rule, test runner and its logic subset, owner rules that
differ, size caps after measuring bytes/token, spec files, UI names that stay verbatim, CI rule. The advisor checks
`grep -nE 'GaleriaFolderow|Foldery|galeria\.py|543094|4711|Katalog' MIGRACJA/*.md` → 0 hits for a non-Foldery target.
Keep: size class, decision sheet, review policy, minimal harness, A → B+C, pilot → waves, watchdog + resume,
owner channel, health check.

## 11. Older documents
This plan supersedes, where they conflict: plan v4.2 (freeze, per-file sessions, 5 review rounds), the principles
file Z1–Z30 (Z20 per-file stage B, Z25 review roles, Z29 freeze; still valid: Z1–Z8 loading, Z13–Z19 enforcement traps,
Z27 line endings, Z30), the playbook §6 and §8.2–8.5 (freeze gate, owner-attended spec). The knowledge base O0 §3 is
outdated on one point: the Agent tool has an `effort` parameter (since 2.1.292); `name` may be absent.
