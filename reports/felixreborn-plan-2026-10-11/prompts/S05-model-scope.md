# S05 — Model scope: only the top two models; agent definitions for later sessions

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
`knowledge/STATE.md` names the two models the base covers (`claude-opus-5-5`, `claude-fable-5-1`); every line in the base naming another model is in the ID/price table or carries a `[scope: …]` marker; the rest is removed with a record. Two agent definitions needed later are created now (an agents directory created mid-session needs a restart). This PR introduces phase 1c (hand review; say so).

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/models-effort-cost.md`, `knowledge/recheck-and-conflicts.md`

## Work
1. `grep -n -i -E 'sonnet|haiku|mythos|opus 4|opus-4|claude-3|opus 5([^.0-9]|$)|fable 5([^.0-9]|$)' knowledge/*.md > Warsztat/model-lines.txt`. Markers, inline at the end of the line: `[scope: trap]` (a measured behaviour that bites a top-two user, e.g. `claude -p` without `--model` runs on Sonnet 5.5); `[scope: component]` (a system part on a small model: title generation, `claude-code-guide`, the `/goal` evaluator); `[scope: why-not]` (a comparative measurement that justifies the two-model choice); `[scope: predecessor-advice]` (Opus 5 / Fable 5 prompting advice that the Opus 5.5 / Fable 5.1 pages call a reasonable starting point; **keep by default**, the owner may decide otherwise, see the reply); table rows under the price/ID heading need no marker. Everything else: delete, recording file, line and text in `Warsztat/model-scope-deletions.md`.
2. `knowledge/STATE.md`: `models: [claude-opus-5-5, claude-fable-5-1]`; `knowledge/phase.txt` → `1c`. `kb_check.py --phase 1c`: a name matching the regex above on a line outside the price/ID table and without a `[scope: …]` marker is an error.
3. Conflicts: in `recheck-and-conflicts.md` move "Haiku 4.5 retirement" and "Sonnet 5.5 default effort" from the imported "Known open conflicts" list to "Not tracked (out of scope since <date>)". This list lives only in the base (imported in S01), so no `CLAUDE.md` change is involved.
4. **Agent definitions** in `.claude/agents/` (directory created in S00; classifier refusal → COMMON §3): `reviewer.md` (the skeleton's per-change code reviewer: `tools: Read, Grep, Glob`, `model: opus`, `effort: high`; not the COMMON §4 pair, which needs Bash to run done commands) and `probe-omit.md` (`omitClaudeMd: true`, `tools: Read, Grep, Glob, Bash`, `model: opus`, `effort: low`; used by S06's probes). Note in `STATUS.md` Live mechanisms: "definitions only; Agent-tool `effort` vs frontmatter precedence unverified (O0 §3): read the real effort from the transcript".
5. **Fact verifier** (1 agent, `model: "opus"`, `effort: "high"`, general-purpose): "Range: the commits between the S02 and S04 step SHAs in `STATUS.md` (`git fetch --unshallow origin main` first if the clone is shallow; `git diff <S02 sha>..<S04 sha> -- knowledge/`). Pick 20 added or changed bullets at random (`shuf`) carrying `[CL …]` or `[SOURCE …]`. For each: open the source (`Warsztat/CHANGELOG.md`, or `curl -sL <url>.md` into `Warsztat/_scratch/`, comparing sha256 with `knowledge/docs-hashes.tsv`), quote the supporting sentence, mark correct / overstated / wrong. Write `Warsztat/fact-verification.md`. Nothing found is valid. Edit nothing else." Fix every wrong or overstated bullet; record the rate in `docs/FINDINGS.md`.
6. New-model rule in `recheck-and-conflicts.md`: "When PL models/overview lists a model above the two in STATE.md, S05 is repeated for the new pair."

## Done when
```
python3 tools/kb_check.py --phase 1c --tree HEAD ; echo exit=$?    # runs 0 … 1c
grep -c "scope:" knowledge/*.md | tail -5
ls .claude/agents/reviewer.md .claude/agents/probe-omit.md
```

## End of session
Reviewers per COMMON §4 (KB files for them: `models-effort-cost.md`, `Warsztat/model-scope-deletions.md`, `Warsztat/fact-verification.md`). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push, tag. Next prompt: `docs/prompts/S06-map.md`.
