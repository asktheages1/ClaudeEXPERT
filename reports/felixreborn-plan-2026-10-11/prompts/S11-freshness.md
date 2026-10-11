# S11 — Freshness: the base knows how old it is, every session sees it

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
`tools/kb_freshness.sh` reports, at every session start, how far the base is behind Claude Code and the official docs; the report is advisory (soft) and says so; the weekly Routine is specified for the owner to create. The read gates keep running in `log` mode and collecting data.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/docs-index.md` (§2 lookup mechanisms, §3 verification procedure, "Check again")
- `knowledge/headless-sdk-ci.md` (scheduling: `/loop`, Routines, `/goal`)
- `knowledge/cloud-environment.md` (network policy, 403 = policy)
- `.claude/hooks/sessionstart*` (the S08 hook this session extends)

## Work
1. **`tools/kb_freshness.sh`** (POSIX sh + `python3`): prints (a) `claude --version` vs `version:` in `knowledge/STATE.md`; (b) the versions and bullet counts in the raw CHANGELOG newer than STATE's version (fetched with `curl -sL --max-time 10`; cached in `.claude/kbgate/freshness-cache.json` for 24 h; on 403/timeout prints "network: unavailable (policy)" and uses the cache or skips); (c) link count of `https://code.claude.com/docs/llms.txt` vs the count recorded in `knowledge/STATE.md` (`llms_links:` field added by `kb_build.py` from a committed `knowledge/llms-snapshot.txt` that S11 creates once: the current llms.txt, so the diff is mechanical); (d) days since each topic file's last commit (`git log -1 --format=%cs -- <file>`); (e) one verdict line: `KB freshness: OK | STALE (<n> versions behind, <k> new docs links)` with STALE at ≥ 3 versions or ≥ 10 new links. Exit 0 always; `--check` exits 1 when STALE (for the Routine).
2. SessionStart hook (`startup`, `resume`) appends the verdict line and the version line to its output; the full report only when STALE; total still ≤ the cap measured in S07.
3. Fixture: `tests/freshness/STATE-sample.md` + a sample CHANGELOG + a sample llms.txt; `tools/test_hooks.sh` runs `kb_freshness.sh --offline --root tests/freshness` and asserts the verdict line.
4. **Routine specification** for the owner, `docs/RAPORT-routine.md` (Polish): what to create in the Claude app (a weekly scheduled session on this repository), the prompt to paste (English, included verbatim: run `tools/kb_freshness.sh --check`; if STALE, fetch the new changelog versions and `whats-new` pages, write a triage file like S02 for the delta, append the summary to `docs/FINDINGS.md`, commit to the standing branch `kb-freshness`, push; never edit `knowledge/` content; never merge), model Opus 5.5, effort medium, and how to stop it. Do not create the Routine yourself.
5. `knowledge/recheck-and-conflicts.md`: the "Check again" schedule now points at the script and the Routine; remove duplicated manual steps that the script covers.
6. `docs/TESTS.md`, `MAPA.md`, `STATUS.md` Live mechanisms: "freshness report at SessionStart (advisory)".

## Done when
```
bash tools/kb_freshness.sh ; echo exit=$?                     # prints the verdict line
bash tools/kb_freshness.sh --offline --root tests/freshness ; echo exit=$?
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/docs-index.md`, `knowledge/headless-sdk-ci.md`; they run the script themselves and check the Routine prompt against the base's rules for unattended runs: explicit model and effort, no self-reported done, named stops). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push. Next prompt: `docs/prompts/S12-enforce-and-lock.md`.
