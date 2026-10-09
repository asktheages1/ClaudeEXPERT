# Changes in plan v5 and prompts v2: defect → fix, review decisions, owner decisions

Written 2026-10-09 in Foldery session `session_01VVhNLbGrLA94Jw3WZszaph`. Nothing was changed in any repository
branch for this package (owner instruction); the files are delivered in the chat.

## 1. Method
- Primary material: transcripts of the 6 advisory and 9 executor sessions of 2026-10-08 (owner messages verbatim,
  tool calls, `get_session` costs), Foldery git history and CHANGELOG, ClaudeEXPERT branch `AAA-dok-review` (plan v4.2,
  review decisions R/T/U/SK, principles Z1–Z30, analysis, hooks) and `main` (playbook, findings).
- Agents (Opus 5.5, high, read-only): 2 forensic (planning + stage A; stage-B batch + spec session), then 7 control
  agents in parallel: 3 documentation-compliance (loading/context/skills; hooks/permissions/settings; agents/cloud), a
  reviewer, a critic, a meta reviewer, a lessons verifier; then 1 fix verifier (§7). About 140 findings; decisions
  below by finding id (prefixes: L = loading, EG = enforcement, AG = agents, R = reviewer, C = critic, M = meta,
  W/U/VM = lessons verifier).

## 2. Main defects of the Foldery migration and their fix
| Defect (evidence) | Fix in v5 |
|---|---|
| Documentation language never decided; 7 files condensed in Polish, then 7 translators + 7 reviewers (≈ 11–15 % of stage-B cost, U2) | standing owner rule (plan §2): every file Claude reads is English; brief states it |
| One owner-started session per file planned (D10, [ASSUMPTION]); replaced the same day | stage B = one session with agents after a pilot; size class none/light/full |
| One-sided review loop: 5 rounds, ≈ 63 findings, no mechanism removed as disproportionate (U6) | two-sided questions, „realistic” defined, protected list, stop when a round yields nothing blocking/important (W7) |
| Reviewers without the target repo; false premises (MAPA §4 „generator output”) survived | reviewers work in a clone and verify premises by command |
| Plan 44 KB, citations the executor could not open, advisor preload ≈ 217–457k tokens, ≈ 730k per advisory turn | plan ≤ 25 KB, prompts self-contained with tagged facts; docs read live; never check out `AAA-dok-review` |
| Hook test of 82 cases still missed 14 push-gate gaps; rewrite during stage A; executor implemented more than the approved option (exotic forms) | minimal harness with an explicit push-to-main definition (C1); one reference harness built once (Foldery stage C) and copied; known limits tested as „exit 0”; implement exactly the approved text |
| Freeze machinery built for weeks, lived ≈ 7 h, still loaded and run; its test crashed when the queue emptied | no freeze list; text-only header „do not edit until stage B”; stage C removes every transitional mechanism; tests use synthetic fixtures |
| Stale local `main` → „unrelated histories” in 5 of 5 sessions; `/dostawa` still has the failing recipe | three-call merge with `git checkout -B main origin/main` in `/dostawa` and every prompt |
| CHANGELOG in two orders + ambiguous „above the newest” → 25 batch lines appended to „Status log” | stage A reorders the version list by script under a fixed heading; insertion asserted once; gate checks order; „Status log” removed in C |
| SHA/„repackaged” commits after merges; 15 re-zips of one version | nothing committed after a merge; decisions asked before packaging; zip per D3 |
| Fixes accepted on the writer's word; owner: „zgłosili znaleziska - i co, claude nie poprawiał?” | writer reports new line per fix; main greps every blocking/important fix and rejection; re-review rule |
| Rewrite grew files +26 % in the batch | ≤ old × 1.10 unless a reader would be misled; reviewer flags bloat |
| Spec excluded from „one session” (owner: „MÓWIŁEŚ 1 SESJA”); spec session 30.76 USD for 2 files | spec in the batch with its own brief, point-number gate, always re-reviewed; owner answers applied in the same session when present |
| Resume addendum written after the batch started, never merged; no wake-up after a restart | watchdog (`worker_epoch`, `send_later` wake-up), resume section in the prompt, ledger committed per unit, brief copy committed |
| Owner surprised by ~8 agents; asked „co mam robić” in 4 sessions; CLAUDE.md for Foldery not delivered | `JAK-ZACZAC.md`; D5 asked; every phase ends with deliverables + exact next first message |
| Separate acceptance session (A7) without a next prompt; effort drifted to medium | acceptance at the start of B; model check in every settings block; effort explicit on every agent |
| Full test suite (13 min) for a docs-only stage | logic + static tests only |
| Nothing checks the system after migration day (owner's 13:13 requirement) | `PROMPT-PRZEGLAD.md` + reminder line in the session hook (D6) |

## 3. Review findings — decisions
Accepted (applied in the files): L1–L13; EG-E1–E8, EG-M1–M7, EG-M9–M11, EG-C1, EG-C2, EG-C3, EG-C4; AG-1–AG-11;
R-B1–R-B3, R-I1–R-I13, R-M1–R-M12, R-C1, R-C3–R-C7; C1–C19 (C13 partly: `turn` + `stop` only where the owner
rules require the reply list); M1 (as owner decision §4), M2 (`PROMPT-FOLDERY-ETAP-C.md`), M3, M4, M5, M6, M8, M11,
M12, M13 (cost table in the stage-C commit message, read by the next advisor), M14, M15, M16 (§6); W1–W4, W6–W11;
VM1–VM5.
Rejected or changed, with reason:
- R-C2 (drop the CHANGELOG order check): kept, because W1 showed the source is in two orders; the order is fixed once by
  script in stage A and the check then costs nothing.
- EG-M8 (STATUS required only when code/docs change): rule kept; its churn came from SHA commits after merges, which v5
  forbids.
- R-M13 / W5 (known red tests; full suite once in A0): dropped instead — no v5 stage changes behaviour, so the gate is the
  logic subset; a red-test baseline is not needed and cost 13 min in Foldery.
- M7 (rewrite the principles file and playbook into one English kit README): plan §11 states what is superseded and what
  stays valid; the rewrite itself is an owner decision (§4), not done in this package.
- M9 (translate every remaining Polish file Claude reads): standing rule for new projects; for Foldery the owner answered
  in the batch's final question round „translated only when rewritten” (Foldery commit ddd0ea8, CHANGELOG line
  „owner decisions recorded”) — kept (the fix verifier read only the question in the old prompt, not the answer); Foldery stage C rewrites `agent-rules.md` and `recenzent.md`
  (English), EFFORT-ZASADY and BACKLOG stay Polish until rewritten.
- M10 (separate question about `backup/`): dropped — after repacking, `backup/` is 0.7 MiB of history (W6).

## 4. Owner decisions needed (also asked in the chat)
1. Where the package lives: ClaudeEXPERT `main`, folder `migration-kit/` (recommended; the advisor prompt, the Foldery
   stage-C prompt and `/przeglad` read it from there), plus the header „superseded by migration-kit” on
   `reports/doc-migration-playbook.md`. Getting it there needs one session to push a branch + PR (the owner never
   uploads); this session did not, by the owner's instruction „nie zmieniasz plików w branchach”.
2. Branch `AAA-dok-review` (unmerged, 16 commits): tag it and delete it (recommended — its `CLAUDE.md` preloads ≈ 217k
   tokens and its plan v4.2 is superseded), or keep it.
3. Run `PROMPT-FOLDERY-ETAP-C.md` on Foldery (recommended: it removes the dead machinery and produces the reference
   harness that every new migration copies).
4. Zip in the repository (D3) — asked by the stage-C session itself.

## 5. Corrections to earlier claims of this session
- The retrospective in Foldery (`GaleriaFolderow/dokumentacja/migracja/RETROSPEKTYWA.md`, deleted by Foldery stage C)
  is wrong in: „zip ≈ 20 MB per delivery” (docs-only re-zips are small deltas; after repacking zips are 57.7 of 63 MiB
  of history); „thin backup/” (0.7 MiB); „language decision would have saved one third of stage B” (≈ 11–15 %); „8
  important, all fixed” (one was a MAPA size note; fixes were taken on the writer's word); „hook author wrote the 82/82
  test” (22 cases came from the independent skeptic). Advisory cost was 91.7 USD in 5 sessions (not 94 / 6). Seven,
  not eight, files were condensed in Polish. „Batch estimate accurate” is n=1 and was 3–4× off in time.

## 5a. Owner correction (2026-10-09)
The first version of this package contained money limits (advisor stop at 40/45 USD, stage B pause above 1.3 × the
estimate, pilot ≤ 15 USD, health check ≤ 8 USD, „budget” in the owner card). The owner never set a budget; they came
from the coordinating session and a control agent. Removed on the owner's decision: estimates stay as information, the
real cost is reported at the end, cost never stops a session. Kept: `--max-budget-usd 0.5` on single measuring
`claude -p` calls (ClaudeEXPERT rule for nested runs) and the pause on an exhausted account rate limit (a hard limit
of the platform, not a budget).

## 6. Cost of producing this package
This session up to the rewrite: 53.4 USD (`get_session`, 2026-10-09 00:36 UTC, incl. the earlier retrospective and
analysis work); the final figure is in the chat reply. That is 10 agents for one package — above v5's advisor
estimate; it was an explicit owner request („tryb Agents”, up to 12–15 agents) and is not a pattern for routine work.

## 7. Fix verification
Round 1 (agent „weryfikator-poprawek”): almost all accepted findings present; 1 blocking (restart loop in stage A for a
source that loads at start), 9 important, 14 minor. Score: old package 4/10, new 7/10 before these fixes. Applied:
merge of the move before the restart + restart detection; plan delivered to the target; Foldery stage C reads the kit
from ClaudeEXPERT; `/przeglad` skill + reminder line implemented in the harness; pending wake-up deleted before the
final round; hook trimmed on a scratch copy; counter pattern and equal versions in the CHANGELOG rule; `gh api *merge*`
kept + `--field`/`--raw-field`/`--input`; doc_check point 7 kept; effort checked; `/compact` (not callable by the
model) replaced by auto-compaction + resume; placeholders defined; spec brief item 3 exception; „stage C” commit
subject; DECYZJE answers grepped in CLAUDE.md before deletion; PRZEGLAD checks 2 and 7. Rejected: M9 (owner decision
exists, ddd0ea8). Round 2 (agent „weryfikator-runda-2”, changed parts only): M9 rejection confirmed (owner answered 21:17:01, ddd0ea8);
0 blocking, 5 important, 5 minor — all applied: owner action order (step 0: kit into ClaudeEXPERT, then Foldery stage
C, then a new project), 40-minute question window with „jestem”, restart via PR says „scal PR first”, `<PRE_SHA>` =
parent of the move commit, leftover greps exclude the `/przeglad` skill, the owner's rules log and the zip; no fallback
to a deleted prompt; „or missing” + STATUS keeps the audit line; placeholder names; CHANGELOG template rule for
undotted and equal versions; no wake-ups from step 11 on; FOLDERY-C next step no longer circular. A third round was
not run: plan §4 requires the owner's OK for it.
