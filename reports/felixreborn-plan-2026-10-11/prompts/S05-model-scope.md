# S05 — Model scope: only the top two models, everything else marked or gone

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
`knowledge/STATE.md` names the two models the base covers (today `claude-opus-5-5`, `claude-fable-5-1`); every line in `knowledge/` that names another model is either in the ID/price table or carries `[scope: trap]`, `[scope: component]` or `[scope: why-not]`; the rest is removed. The conflict list drops the two out-of-scope items as "not tracked", and the owner gets that as a separate decision because the list also lives in `CLAUDE.md`.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/models-effort-cost.md`
- `knowledge/recheck-and-conflicts.md`

## Work
1. `grep -n -i -E 'sonnet|haiku|mythos|opus 4|opus-4|claude-3' knowledge/*.md > Warsztat/model-lines.txt`; expect ~36 non-table lines [MEASURED 2026-10-11 on the old layout]. For each line decide: table row (keep), trap (a measured behaviour that bites a top-two user, e.g. `claude -p` without `--model` runs on Sonnet 5.5), component (a system part that runs on a small model: title generation, `claude-code-guide`, `/goal` evaluator), why-not (a comparative measurement that justifies the two-model choice), or delete. Apply the markers inline at the end of the line. Record every deletion in `Warsztat/model-scope-deletions.md` (file, line, text) so the reviewers can check nothing valuable went.
2. `knowledge/STATE.md`: add `models: [claude-opus-5-5, claude-fable-5-1]`, `phase: 1c`. Implement `tools/kb_check.py --phase 1c`: a non-top model name on a line outside the price/ID table and without a `[scope: …]` marker is an error; the table is the one under the heading that contains "price" in `models-effort-cost.md`.
3. Conflicts: in `recheck-and-conflicts.md` move "Haiku 4.5 retirement" and "Sonnet 5.5 default effort" to a "Not tracked (out of scope since <date>)" list. The same two items sit in `CLAUDE.md`'s "Known open conflicts": write the removal as `Warsztat/CLAUDE.md.proposed.diff` (append to the existing proposed diff if present) and name it in the reply.
4. **Fact verifier** (1 agent, `model: "opus"`, `effort: "high"`, general-purpose): "Pick 20 bullets at random (`shuf`) from the bullets added or changed in S03 and S04 (`git log -p origin/main..HEAD -- knowledge/` in the previous two merges, or `git diff <S02 merge>..HEAD`), each with a `[CL …]` or `[SOURCE …]` tag. For each: fetch or open the source (changelog in `Warsztat/CHANGELOG.md`, pages in `Warsztat/pages/` or via `curl -sL <url>.md`), quote the supporting sentence, and mark correct / overstated / wrong. Write `Warsztat/fact-verification.md`. Nothing found is a valid result." Fix every wrong or overstated bullet it finds; record the rate in `docs/FINDINGS.md`.
5. New-model rule, written into `recheck-and-conflicts.md`: "When PL models/overview lists a model above the two in STATE.md, S05 is repeated for the new pair."

## Done when
```
python3 tools/kb_check.py --phase 1c --tree HEAD ; echo exit=$?
python3 tools/kb_check.py --phase 1 --tree HEAD ; echo exit=$?
grep -c "scope:" knowledge/*.md | tail -5
```

## End of session
Reviewers per COMMON §4 (KB files for them: `models-effort-cost.md`, `Warsztat/model-scope-deletions.md`, `Warsztat/fact-verification.md`). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md` (verification rate), commit, push. Next prompt: `docs/prompts/S06-map.md`.
