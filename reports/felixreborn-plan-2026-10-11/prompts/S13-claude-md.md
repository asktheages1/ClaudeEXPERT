# S13 — CLAUDE.md: move what belongs to the base, delete the stubs, measure the start cost

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
`CLAUDE.md` describes only what is live (per `STATUS.md` Live mechanisms) and routes to the base instead of duplicating it; the redirect stubs and the duplicated procedures are gone; the start cost of a main session and of a general-purpose agent is measured before and after. Every change to `CLAUDE.md` is a proposal: the file is under an `ask` rule and the auto-mode classifier may refuse (findings 2026-10-06); if refused, leave the diff in the branch and the PR for the owner.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`, `Warsztat/CLAUDE.md.proposed.diff` (accumulated proposals from S01–S08)
- `knowledge/CLAUDE.md`, `knowledge/design-rules.md`, `knowledge/recheck-and-conflicts.md`, `knowledge/context-window-and-read.md` (Read-counter method)
- `reports/felixreborn-plan-2026-10-11/01-przeglad-CLAUDE-md.md` if the owner copied it (§3 lists the sentences to embed)

## Work
1. **Measure before**: Read-counter tokens of `CLAUDE.md` (method from `context-window-and-read.md`: a Read with `offset=1` and a large `limit` on a filler file > 25,000 tokens followed by the file; the error's token count difference); total start tokens of a general-purpose agent: launch one trivial agent (`model: "opus"`, `effort: "low"`, task "reply OK") and read `usage.input_tokens` of its first call from its transcript. Record both with `[MEASURED …]`.
2. **Edit** (as one proposed diff applied in the branch): remove the KB table, the evidence-tag legend, "Known open conflicts", "Freshness" and "Live lookups" (now in `knowledge/CLAUDE.md`, `docs-index.md`, `recheck-and-conflicts.md`); remove "Read O0 in full once per session" (the read gate replaces it); embed the sentences from the review §3 (knowledge base paragraph in "Start of every session"; checker/harness/CI paragraph in "Verification"; generated files paragraph in "State and documentation"; gated agent types and the worktree rule in "Agents"; the threat-model sentence in "Enforcement"; the freshness line in "Health check"); move "Reviewing designs for other Claude systems" to `knowledge/design-rules.md` with a one-line pointer; add the approval-unit sentence ("the owner's merge of a step's PR after reading its triage file is the approval the KB rules require") **only if `STATUS.md` records the owner's yes**; fill no `<…>` placeholder the owner has not decided. Keep every rule in one place: a sentence that now lives in the base is a path here, not a copy. HTML comments for provenance (hidden at load, `[CL 2.1.72]`).
3. Delete `knowledge/O0…O5-*.md` stubs; `grep -rn "O[0-5]-" docs/ knowledge/ CLAUDE.md` → every remaining old citation gets the mapping table appended to `recheck-and-conflicts.md` ("old citations: O0 §4 → permissions-settings-automode.md / hooks.md …"), none is rewritten in history files. Delete the duplicated procedure (`docs-index.md` §5 "CLAUDE.md snippet"). Run `kb_build.py` and `kb_check.py` (phase 2).
4. `/doctor prompt-audit CLAUDE.md` in a `-p` run from `/tmp/kbtest` (works in `-p`; pass the path explicitly) → `Warsztat/prompt-audit.md`; apply what is plainly right, list the rest.
5. **Measure after**: repeat step 1. Targets: `CLAUDE.md` ≤ 20 KB per its own cap and fewer tokens than before; agent start tokens not higher than before by more than the map's size. Record both numbers in `docs/FINDINGS.md` and `STATUS.md`.
6. `tools/export_template.py` run; `Gotowe/` diff clean. `docs/TESTS.md`, `MAPA.md`, `CHANGELOG.md` version line (docs-only: no package).

## Done when
```
python3 tools/kb_build.py && git diff --quiet -- knowledge/ ; echo exit=$?
python3 tools/kb_check.py --phase 2 --tree HEAD ; echo exit=$?
ls knowledge/O[0-5]-* 2>/dev/null | wc -l      # 0
python3 tools/export_template.py && git diff --quiet -- Gotowe/ ; echo exit=$?
wc -c CLAUDE.md                                 # ≤ 20480
```
plus the before/after token table in the reply.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/CLAUDE.md`, `knowledge/design-rules.md`; they read the new `CLAUDE.md` in full and check: nothing claimed as live that `STATUS.md` does not list; no rule duplicated between `CLAUDE.md` and the base; every removed sentence has a home). Fix or reject. `STATUS.md` (Live mechanisms complete; "Next task": the owner decides what the template builds next), `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push. This is the last prompt of the KB plan; the reply ends with the list of decisions still waiting for the owner from `STATUS.md`.
