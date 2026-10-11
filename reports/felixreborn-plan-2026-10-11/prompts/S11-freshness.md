# S11 — Freshness: the base knows how old it is, every session sees it

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
`tools/kb_freshness.sh` reports at session start how far the base is behind Claude Code and the official docs; the report is advisory and says so; the weekly Routine is specified for the owner to create. The read gates keep running in `log` mode and collecting data.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/docs-index.md`, `knowledge/recheck-and-conflicts.md` (the "Check again" schedule lives here after S01)
- `knowledge/headless-sdk-ci.md` (scheduling: `/loop`, Routines, scheduled tasks after S04, `/goal`)
- `knowledge/cloud-environment.md` (network policy; 403 = policy)
- `.claude/hooks/kb_sessionstart.sh`

## Work
1. **`tools/kb_freshness.sh`** (POSIX sh + `python3`): (a) `claude --version` vs `version:` in `knowledge/STATE.md`; (b) versions and bullet counts in the raw CHANGELOG newer than that (`curl -sL --max-time 10`; cache in `.claude/kbgate/freshness-cache.json` for 24 h — per VM, so in the cloud nearly every session pays the fetch: say so; on 403/timeout print `network: unavailable (policy)` and use the cache or skip); (c) link count of `https://code.claude.com/docs/llms.txt` vs `llms_links:` in `STATE.md`, which `kb_build.py` computes from a committed `knowledge/llms-snapshot.txt` created once now; (d) days since each topic file's last commit; (e) verdict line `KB freshness: OK | STALE (<n> versions behind, <k> new docs links)`, STALE at ≥ 3 versions or ≥ 10 new links. Exit 0 always; `--check` exits 1 when STALE; `--offline --root <dir>` for tests; a test namespace variable skips network.
2. `kb_sessionstart.sh` (`startup`, `resume`) appends the verdict and version lines; the full report only when STALE; total within the cap measured in S07.
3. Fixture `tests/freshness/` (sample STATE, CHANGELOG, llms.txt); `tools/test_hooks.sh` runs `kb_freshness.sh --offline --root tests/freshness` and asserts the verdict line.
4. **Routine specification** `docs/RAPORT-routine.md` (Polish): what to create in the Claude app (a weekly scheduled session on this repository), the prompt verbatim (English): `git fetch origin kb-freshness && git switch kb-freshness || git switch -c kb-freshness origin/main`; run `tools/kb_freshness.sh --check`; if STALE: fetch the new changelog versions and the new `whats-new` pages, write a triage file in the S02 format for the delta, append a summary to `docs/FINDINGS.md`, commit, push `kb-freshness` (pushing to an existing non-default branch from a Routine session is unmeasured: mark `[ASSUMPTION]`); never edit `knowledge/` content; never merge; model Opus 5.5, effort medium, `--max-turns`-style stops in the prompt text. How to stop it. Do not create the Routine yourself.
5. `recheck-and-conflicts.md`: "Check again" now points at the script and the Routine; remove manual steps the script covers.
6. `docs/TESTS.md`, `MAPA.md`; `STATUS.md` Live mechanisms: "freshness report at SessionStart (advisory, cloud only)". Copy the gate logs.

## Done when
```
bash tools/kb_freshness.sh ; echo exit=$?                     # prints the verdict line
bash tools/kb_freshness.sh --offline --root tests/freshness | grep -q 'KB freshness:' ; echo exit=$?
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/docs-index.md`, `knowledge/headless-sdk-ci.md`; they run the script and check the Routine prompt against the base's rules for unattended runs: explicit model and effort, no self-reported done, named stops). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push, tag. Next prompt: `docs/prompts/S12a-analyse-and-enforce.md`. If the owner agreed to baseline Q&A sessions, they run now, before S12a, with no prompt file: ordinary questions to the base, gate logs committed at the end of each.
