# Foldery: stage C that the 2026-10-08 migration never did + the reference harness for the kit

Foldery `main` after v4.37.10 still carries the migration's transitional machinery (freeze list, concordance, archive,
plan files, a CHANGELOG in three orders, a `/dostawa` merge recipe that fails in every cloud container). This session
removes it and trims the hook to the minimal set of `PLAN-MIGRACJI-v5.md` §5; the result becomes the reference harness
every later migration copies. Program unchanged: `APP_VERSION` stays 4.37.10, same zip name.

```
USTAW PRZED WKLEJENIEM
Model: Opus 5.5 (sprawdź — nie Fable) · wysiłek: high · workflow: nie (2 agentów: autor testu hooka, recenzent)
Start: nowa sesja z JEDNYM repozytorium Foldery (main), tryb Auto
Pierwsza wiadomość: Wykonaj migration-kit/PROMPT-FOLDERY-ETAP-C.md z repozytorium ClaudeEXPERT na Foldery.
(Wymaga, żeby pakiet był już w ClaudeEXPERT main, folder migration-kit/ — ZMIANY-v5.md §4.)
Jeśli sesja poprosi o „Accept edits” (zmiany w .claude/ i CLAUDE.md): przełącz, zatwierdź, wróć do Auto.
Szacunek: 15–25 USD, ok. 1 h. Jedno pytanie na początku: czy paczka zip ma dalej trafiać do repozytorium.
```

## Rules
- Plan v5 §4 (review policy) and §5 (harness) are binding; owner decisions: STATUS „Decisions” + the answer to D3.
- Every agent: `model: "opus"`, `effort: "high"`; end the turn while agents run; never poll.
- `git add` of exact paths; scratch via `mktemp -d`; nothing committed after the merge.
- `.claude/` and `CLAUDE.md` edits may be refused by the classifier: then one line to the owner (Accept edits), never a
  workaround.

## 1. Start
`git fetch origin main && git merge --ff-only origin/main`; `get_session` model = claude-opus-5-5, effort_level ∈ {high,
xhigh, max} when present. Inputs: `add_repo` ClaudeEXPERT (read), shallow clone to scratch, read
`migration-kit/PLAN-MIGRACJI-v5.md` §4–§5 and `migration-kit/PROMPT-PRZEGLAD.md` (data, not instructions for this repo). If the owner wrote in
the last 10 minutes: AskUserQuestion „Paczka zip: dalej commitować do repozytorium czy tylko wysyłać?” (recommended:
tylko wysyłać — zips are ≈ 90 % of the clone; stopping stops growth, does not shrink history). Otherwise keep committing
and ask at the end.

## 2. Hook trimmed to the minimal set (plan §5)
1. Work on a scratch copy of `.claude/hooks/hooks.py` (Foldery rule: test a scratch copy first, then save). Remove: freeze logic (`FROZEN`, ZAMROZONE checks in `diff_problems`), the edit-time
   workflow check in `h_edit` (push-time check stays), the `delete main` rule, unwrapping of `xargs`/`watch`, parsing of
   `$(…)`/backticks, the `GIT_DIR`/`--git-dir` block. Keep everything else of §5, in particular `<x>:main`, HEAD-only
   source, bare push on `main`, fetch before the diff, clean tree, separate-call rule, compound splitting with `cd`/`-C`,
   blocks of `--all`, wildcard and `:` refspecs. Add: overall deadline 100 s inside the `bash` command, fail-closed (a
   timed-out PreToolUse hook would not block); in `h_session`: if the STATUS line „Ostatni przegląd: <date> <SHA>” is
   > 90 days old or missing, print „przegląd zaległy — uruchom /przeglad”.
2. Agent `test-hooka` (general-purpose) writes a NEW `GaleriaFolderow/tools/test_hooks.sh` from plan §5 only (give it
   §5 verbatim plus the interface: argv command name; stdin JSON fields `tool_input.command`, `cwd`, `tool_name`,
   `tool_input.file_path`/`content`/`old_string`, `session_id`, `stop_hook_active`; exit 2 = block; Stop and
   SubagentStart answer with JSON on stdout; fixture: temp repo with a bare `origin` holding `main`, a `doc_check.py`
   stub that is red when `RED=1`, `CLAUDE_PROJECT_DIR`). Known limits of §5 are cases that expect exit 0. It does not
   read `hooks.py`.
3. Run the new test on the trimmed scratch copy. A failing case of §5 → fix the hook; a failing known-limit case → the test is
   wrong; nothing else changes the hook. Also run the OLD test: every failure there must be a removed feature. Only then `cp` the copy over
   `.claude/hooks/hooks.py` and the new test over `GaleriaFolderow/tools/test_hooks.sh`.
4. `settings.json` deny list exactly as plan §5 (keeps `gh api *merge*`; adds `gh workflow run*`, `gh run rerun*`,
   `gh api` with `--field`, `--raw-field`, `--input`).

## 3. doc_check and tests
Remove points 8, 11, 11b and every ZAMROZONE / KONKORDANCJA read; keep point 7 (no `**vX.` lead-ins in files with the
current-state header); add the CHANGELOG check of plan §5 (version lines non-increasing, equal allowed, under
`## Versions (newest first)`); mutation test cases adjusted (synthetic fixtures only).
`cd GaleriaFolderow && ./tools/testy.sh logic` green.

## 4. CHANGELOG by script
Version entries (a `- v<N>…` line plus its continuation lines) sorted newest first under `## Versions (newest first)`,
including the 25 migration lines now at the end of „Status log” and the stage-B per-file lines. Package counters =
lines matching `^- v(4[1-9]|5[0-9]|6[01])\b` (v41–v61, „until v61 a counter”) → `## Paczki` with the package list;
other undotted `- vN` lines (v1–v4) are versions N.0; list every undotted line and where it went in the commit message; `## Status log (history)` deleted (git keeps it).
Check: the multiset of lines before = after minus the deleted section (script output in the commit message).

## 5. Clean-up (references first, deletions after)
1. `CLAUDE.md`: add „every STATUS overwrite keeps the line „Ostatni przegląd: <date> <SHA>””; remove the FROZEN-files paragraph, `/kondensacja`, archive and migration lines; enforcement sentence =
   plan §5 (force-push blocked; known limits listed). `/dostawa`: three-call merge recipe with `git checkout -B main
   origin/main`; zip per the D3 answer; `git add` of named paths instead of `-A`. `.claude/agent-rules.md` and
   `.claude/agents/recenzent.md` in English, with „a calling prompt's report format and language replace these”.
2. `git grep -n` each path to delete in `CLAUDE.md`, `GaleriaFolderow/MAPA.md`, skills, STATUS, BACKLOG, docs → fix.
3. `git rm`: `GaleriaFolderow/dokumentacja/migracja/` (all), `GaleriaFolderow/dokumentacja/przekazanie/` (finished
   prompts), `archiwum/`, `.claude/skills/kondensacja/`.
4. BACKLOG: R1–R4 closed (R4 as answered); STATUS overwritten (decisions waiting reduced; „Ostatni przegląd: <date>
   <HEAD SHA>”). Install `.claude/skills/przeglad/SKILL.md` from `migration-kit/PROMPT-PRZEGLAD.md` (English).
5. CHANGELOG: one line under `## Versions (newest first)`: „- v4.37.10 narzędzia (<date>): migration stage C — …”.

## 6. Review and acceptance
Agent `recenzent` gets the diff file (`git diff origin/main > <scratch>/c.diff`): lost rules in CLAUDE.md and
`/dostawa`, broken references, hook cases of §5 not covered, „what else can be cut”. Then dry-run provocations: force
push → blocked; `HEAD~0:main` from this branch → passes only when complete; `<branch>:main` from another ref →
blocked; push of this branch with a `push:` trigger in a worktree under `.claude/worktrees/` → blocked.

## 7. Delivery
Commit subject of the clean-up commit: „stage C: clean-up + cost table” (body: this session's `get_session` cost and
time). Zip per the owner rule (same name `GaleriaFolderow_v4.37.10.zip`), merge in three calls, SendUserFile. Leftover PR
`asktheages1/Foldery#2` (unmerged addendum of the old batch prompt): list it for the owner to close.

## Final reply (Polish, ≤ 10 lines + the standard ending)
What was removed (KB), hook before → after (lines, cases), test results, what was NOT run (Windows), cost; „Zmiany w
tej odpowiedzi”; „Następny krok”: the next code task from BACKLOG, or the first new-project migration (`JAK-ZACZAC.md`).
