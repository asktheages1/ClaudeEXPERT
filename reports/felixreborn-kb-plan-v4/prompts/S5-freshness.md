# S5 — Freshness: a start line that says how old the base is, and a weekly Routine [G2]

Read `docs/prompts/COMMON.md` in full, then this prompt in full, before any other action.

## Goal
Every session start says whether the base is behind Claude Code; once a week a scheduled cloud session runs `/kb-update` on a fixed branch and stops before merging, so unattended edits wait for the owner or the next attended session.

## Read in full
- `CLAUDE.md`, `STATUS.md`, `knowledge/CLAUDE.md`, `.claude/skills/kb-update/SKILL.md`
- `knowledge/headless-sdk-ci.md` (Routines, scheduled tasks — digested in S3; if the Routine facts are missing there, stop and report: the design depends on them)
## Read in part (say so)
- `.claude/hooks/hooks.py`: `h_session` and `HANDLERS`.

## Steps
1. **SessionStart line** in `h_session`: `KB: As of 2.1.<a> · Claude Code 2.1.<b> · <n> versions, <d> days behind · OK|STALE`. `<b>` from `claude --version` (local, timeout 5 s; missing → `?`); STALE at ≥ 3 versions or > 30 days since the `As of:` date (add `As of: … (YYYY-MM-DD)` to the map line if the date is missing; `doc_check` rule: date present). Also `kb-update: <n> commits ahead of main` when `origin/kb-update` exists (from the start hook's `git fetch`; `unknown` offline). No HTTP at start; the existing `git fetch origin main` with timeout stays. The `/kb-update` skill already writes the date (S3); here `doc_check` only enforces it. On STALE add: "run /kb-update or wait for the weekly Routine". Fixtures: OK, STALE by versions, STALE by days, `claude` missing, `kb-update` ahead.
2. **Routine** — specify in `docs/RAPORT-routine.md` (Polish, for the owner): weekly, a fresh session per run in this repository's cloud environment, prompt (English, verbatim in the file): `git fetch origin main; git fetch origin kb-update || true; git switch kb-update 2>/dev/null && git merge --no-edit origin/main || git switch -c kb-update origin/main`; run `/kb-update`; push `kb-update`; **do not merge into main**; write the summary (versions covered, facts changed, pages added, NOT RUN items) as the reply; model Opus 5.5, effort high (the plan's level for every session); named stops: network 403, triage over 4 agents' worth, any `doc_check` error it cannot fix. Then ask the owner in this session (one question, recommended option first) whether to create it now; on yes create it with the Routine tool your session has (fresh session per run, push notification on, cron jittered off the hour, his time zone asked if unknown); creation takes no model, so set Opus 5.5 with the Routine update tool afterwards; effort cannot be set on a Routine: put `effortLevel: "high"` in `.claude/settings.json` (project scope unverified, skeleton l. 46) and say the first run's transcript must confirm it. On no, leave the spec. `RAPORT-routine.md` also says how the owner gets the branch merged: in an attended session he writes „scal kb-update”; that session runs `git merge origin/kb-update` into its own branch, then `/dostawa`. Never edit account settings otherwise.
3. **`CLAUDE.md`**: the S5 row of PLAN §8 (health check: the start line; `/kb-update` when STALE or from the Routine; merging the `kb-update` branch is an attended step via `/dostawa`); net bytes ≤ 0; report before/after.
4. `/dostawa`. `STATUS.md` "Next task": "KB plan done; owner decides" and list the decisions still waiting.

## Done when
```
bash tools/tests.sh ; echo exit=$?                 # includes the freshness fixtures
python3 tools/doc_check.py ; echo exit=$?
echo '{"hook_event_name":"SessionStart","source":"startup"}' | python3 -I .claude/hooks/hooks.py session | grep -E '^KB: '   # one line
```
plus the Routine's ID (if created) or "spec only".
