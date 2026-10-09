# Stage A: mechanical move + minimal harness (template; Foldery values filled in as the example)

Plan and reasons: `MIGRACJA/PLAN-MIGRACJI-v5.md`. Owner decisions: `MIGRACJA/DECYZJE.md` (never ask them again).
This prompt is frozen once the session starts; nobody sends addenda from other sessions.

| Placeholder | Foldery value |
|---|---|
| `<SRC>` (big instruction file) / bytes / lines | `GaleriaFolderow/CLAUDE.md` / 543094 / 4711 (on-demand nested) |
| `<DIR>` (its folder) | `GaleriaFolderow/` |
| `<CODE>` (main code file) | `GaleriaFolderow/galeria.py` |
| `<LOGIC>` (logic + static tests) | `cd GaleriaFolderow && ./tools/testy.sh logic` |
| `<BACKUP>` (folder never edited) | `GaleriaFolderow/backup/` |
| `<VER>` (version, unchanged) | `4.37.9` |
| `<PRE_SHA>` / `<BR>` / `<DATE>` | parent of the move commit, recorded in POSTEP at 1.2 / `git branch --show-current` / today, YYYY-MM-DD |

```
USTAW PRZED WKLEJENIEM
Model: Opus 5.5 (sprawdź w wyborze modelu — nie Fable) · wysiłek: high · workflow: nie (2 audytorów naraz)
Start: nowa sesja z JEDNYM repozytorium Foldery (main), tryb Auto
Pierwsza wiadomość: Wykonaj MIGRACJA/PROMPT-ETAP-A-v2.md od kroku 1.
Jeśli sesja poprosi o „Accept edits” (zapis w .claude/): przełącz, zatwierdź, wróć do Auto.
Szacunek: 18–25 USD, ok. 1 h. Możesz odejść po wysłaniu — pytania (jeśli będą) dostaniesz na końcu.
```

## Rules for this session
- Progress log `MIGRACJA/POSTEP.md`: after every step what was done, SHAs, command → result, „decisions without the
  owner”. Commit and push the session branch after every step.
- Before step 1.2: no Read/Edit/Write and no single-file `cat`/`head`/`tail`/`sed -n`/`grep` on any path under `<DIR>`
  (each loads `<SRC>`, ≈ 240k tokens, for the whole session). Only `git cat-file`, `git show`, `git ls-files`.
- Program behaviour is not changed; `APP_VERSION` stays. Gate for this stage: `<LOGIC>`; no full test suite.
- Every agent call: `model: "opus"`, `effort: "high"`; `name` only if the Agent schema lists it. After launching
  agents end the turn; never poll (no Monitor, list_events or sleep loops).
- Owner questions: AskUserQuestion only if the owner wrote in the last 10 minutes; otherwise take the plan's
  recommendation, record it in POSTEP, ask in the final reply. Implement exactly the approved option text.
- Scratch via `mktemp -d`; never `rm -rf`. Nothing is committed after the merge.

## 1. Start
1. `git fetch origin main && git merge --ff-only origin/main` on the session branch. Start condition:
   `git cat-file -s HEAD:<SRC>` = 543094; otherwise stop (the line ranges below would be wrong).
   `get_session`: `session_context.model` = claude-opus-5-5 and `session_context.effort_level` ∈ {high, xhigh, max}
   (when present) → else stop and say so. If `archiwum/` already holds the moved source (a restart after 1.2), check
   its size instead of the start condition and continue at 1.3.
2. Remove `<SRC>` from loading (first record `git rev-parse --short HEAD` as `<PRE_SHA>` in POSTEP):
   - on-demand nested source (Foldery): `mkdir -p archiwum && git mv <SRC> archiwum/CLAUDE-do-v<VER>.md`; check
     `test ! -e <SRC>`; commit + push.
   - source that loads at start (root `CLAUDE.md`, `.claude/CLAUDE.md`, an unscoped rule or its `@` imports): the same
     `git mv`, commit, push, merge into `main` with the three calls of 4.5 (no hook exists yet; if the classifier or
     a hook refuses: PR, and the reply says „Najpierw scal PR <link>, potem nowa sesja”), then STOP and reply:
     „Otwórz nową sesję z tą samą pierwszą wiadomością” (this session keeps the start version and would pass it to every agent). The new session starts
     from `main` and continues at 1.3.
3. Baseline numbers: copy them from `MIGRACJA/ANALIZA.md` if HEAD equals the SHA measured there; else measure by
   import of `git show <PRE_SHA>:<SRC>` copied to scratch. The old doc gate is red from 1.2 until step 4 — expected.
4. `git grep -n 'CLAUDE.md\|§[0-9]' -- ':!<BACKUP>' ':!archiwum'` → list in POSTEP (fixed in 3.5).

## 2. Infrastructure
`.gitignore`: track `.claude/` except `.claude/worktrees/` and `.claude/settings.local.json`.

## 3. Move by script, prove losslessness
1. A scratch script lists paragraphs of the archive: line, first 90 chars of the lead-in, bytes. Assign line ranges →
   targets from that list (never read the archive in full). Write `GaleriaFolderow/dokumentacja/migracja/KONKORDANCJA.tsv`
   (`start end old_§ target`); every line in exactly one row; lines that go nowhere are marked `archive only`.
   Targets (≤ 40 KB each, split at `##` when larger; area names are yours to choose from the lead-ins):
   §1 owner rules → `dokumentacja/ZASADY-UZYTKOWNIKA.md` (owner's wording log, permanent); §2 → `dokumentacja/PLIKI.md`;
   §3 → `dokumentacja/SRODOWISKO-TESTY.md`; §4 → `dokumentacja/architektura/<area>.md`, AI paragraphs →
   `dokumentacja/ai/<area>.md`; §5 → `dokumentacja/spec/SPEC-A.md`, `SPEC-B.md` split at a point boundary (numbering
   5.N kept); §6 → `.claude/rules/galeria-niezmienniki.md` (cap 36 000 B); §7 → `dokumentacja/OGRANICZENIA.md`;
   §8 → `CHANGELOG.md`; §9 → `dokumentacja/BACKLOG.md` (permanent); old MAPA §4 hand-written code map →
   `dokumentacja/architektura/mapa-kodu-reczna.md`; MAPA §9 → `CHANGELOG.md` section `## Status log (history)` at the end.
2. Copy only by script (`sed -n` / Python per TSV). The rule file starts with exactly these three lines, header after:
   `---` / `paths: ["**/GaleriaFolderow/galeria.py"]` / `---`.
3. CHANGELOG by script: heading `## Versions (newest first)`; every version entry (a `- v<N>…` line plus its
   continuation lines) sorted newest first by version number; package counters (Foldery: `^- v(4[1-9]|5[0-9]|6[01])\b`,
   v41–v61) and the „Paczki” list under `## Paczki`; other undotted `- vN` lines are versions N.0; entries of the same
   version: newest first (by date; same date: reverse the source order if that block was oldest-first); then
   `## Status log (history)`. Order changes, lines do not; every undotted line and its destination listed in POSTEP.
4. Header (3 lines) only on the files stage B rewrites (all targets except ZASADY, BACKLOG, CHANGELOG): area;
   „Moved verbatim from CLAUDE.md v<VER>; rewritten in stage B. Until then do not edit it; record changes of this area in
   CHANGELOG + STATUS.”; „On conflict `/CLAUDE.md` and `/dostawa` win.”
5. Commit. Concordance script `GaleriaFolderow/dokumentacja/migracja/konkordancja.py` on that SHA: ranges cover lines
   1–4711 without gaps or overlaps; multiset of archive lines = moved lines + `archive only` lines → 100 %. SHA and
   result → POSTEP, plus the full list of `archive only` lines (for auditor 1).
6. Replace `§N` references with file paths everywhere except `<BACKUP>`, `archiwum/` and the owner's wording log (it
   gets a legend line); `§5.N` stay and get the SPEC file name. Record the first touch of `<CODE>` (Read or Edit) and
   whether the rule's contents reminder appeared — that is the K2 presence check.

## 4. Navigation and gate (one commit together with step 5)
1. `/CLAUDE.md` (≤ 11 KB, English): standing owner rules (plan §2) in their current wording, plus every `DECYZJE.md`
   answer that governs future sessions (zip D3, health check D6, docs language) — each also appended with its date to
   `dokumentacja/ZASADY-UZYTKOWNIKA.md`; start of session; verification protocol; where knowledge is (`MAPA.md` §1);
   doc rules (one rule one place, rewrite not append, caps); agents; enforcement and its known limits (plan §5); „code
   wins over docs”; „one session with changes at a time”; „moved files are rewritten in stage B; until then record
   changes in CHANGELOG + STATUS”.
2. `GaleriaFolderow/STATUS.md` (≤ 6 KB; `CLAUDE.md` says every overwrite keeps the line „Ostatni przegląd”): version; this session's id (`get_session`) and branch; done; next task = stage
   B with its exact first message; decisions waiting; audit line „Ostatni przegląd: <DATE> <HEAD SHA>”.
3. `GaleriaFolderow/MAPA.md`: §1 task → file table with „(N KB)”; code map removed (`tools/mapa_kodu.py` on demand);
   old checklist → `/dostawa`.
4. `tools/doc_check.py` v2 with the checks of plan §5 (doc gate) and a mutation test in `tests/test_logic.py`, one
   mutated input per check.
5. `.claude/skills/dostawa/SKILL.md` from the old MAPA §3 plus every duty of MAPA §5–§8 it cited; merge recipe = three
   calls: `git fetch origin main && git checkout -B main origin/main && git merge --no-edit <BR>` / `git push origin
   main` / `git checkout <BR>`; zip per D3; `git add` of named paths, never `-A`. `.claude/skills/przekazanie/SKILL.md`
   from EFFORT-ZASADY §5. `.claude/skills/przeglad/SKILL.md` from `MIGRACJA/PROMPT-PRZEGLAD.md` (frontmatter `name:
   przeglad`, `description`).

## 5. Harness (reference files, never retyped)
1. `cp MIGRACJA/hooks/hooks.py .claude/hooks/hooks.py`; `cp MIGRACJA/hooks/test_hooks.sh GaleriaFolderow/tools/`.
2. `bash GaleriaFolderow/tools/test_hooks.sh .claude/hooks/hooks.py` → all green. Add project cases only for this
   project's paths. Known-limit cases expect exit 0 and stay; only a failing case of plan §5 changes the hook.
3. Then `.claude/settings.json` from `MIGRACJA/hooks/settings.json` (deny list and hooks of plan §5, shell form),
   `.claude/agent-rules.md` (English: no `APP_VERSION`, backup, docs, zip or `main` changes; test first for code;
   report format; „a prompt's own report format replaces this one”), agents `recenzent` (Read, Grep, Glob; opus, high;
   „report format and language as the calling prompt says”) and `wykonawca` (worktree; opus, high).
   If the classifier refuses a write under `.claude/`: one line to the owner (switch to Accept edits once, why).
4. `<LOGIC>` green → the one commit of steps 4 + 5 → push.

## 6. Acceptance in this session
1. Provocations, one at a time, results → POSTEP (record which layer blocked: deny or hook):
   - `git push --dry-run --force origin HEAD` → blocked;
   - CI trigger: worktree `.claude/worktrees/probe-ci` (inside the working dir, so no permission prompt), add `push:`
     under `on:` with `sed -i`, commit, `git -C .claude/worktrees/probe-ci push --dry-run origin HEAD:probe-ci` →
     blocked (the push-time check guards every branch);
   - Edit of a file in `<BACKUP>` (real path) → blocked;
   - worktree `.claude/worktrees/probe-main` from `origin/main`: change `<CODE>` (one blank line) AND `STATUS.md`,
     commit, push `--dry-run origin HEAD:main` → blocked („code without CHANGELOG + docs”);
   - this branch: `git push --dry-run origin HEAD:main` → passes; with STATUS reverted → blocked;
   - remove the worktrees with `git worktree remove --force`.
2. `<LOGIC>`; concordance 100 % on the SHA of 3.5; doc gate green.
3. Two read-only auditors in parallel (`general-purpose`, opus, high), each with the SHA, file list, the owner scope
   list, plan §4, report ≤ 40 lines findings only (id, severity, file, evidence command → result, fix, „worth its
   cost?”), „nothing found” allowed, scratch via `mktemp -d`, no edits:
   - **lossless**: concordance independently; every `archive only` line and every rule-bearing line of the rewritten
     targets (`CLAUDE.md`, `/dostawa`, MAPA) → kept / obsolete with reason;
   - **enforcement**: settings, hooks, test, provocations of 6.1, the cases of plan §5 incl. `<x>:main` and bare push
     on `main`; known limits stay limits.
   Decide each finding by plan §4; record in POSTEP.
4. CHANGELOG: one line directly under `## Versions (newest first)` (Python edit asserting the heading occurs once):
   „- v<VER> dokumentacja (<DATE>): stage A …”. STATUS final. Both BEFORE the zip.

## 7. Delivery and merge
1. Zip per the owner rule (same name, program unchanged), sent with SendUserFile; committed only if D3 says so.
2. Merge with the three calls of 4.5. Classifier refuses the merge or push: `git push --dry-run origin HEAD:main`
   (same gate), push the branch, open a PR, tell the owner at once with the link.

## Resume after an interruption or compaction
Re-read this prompt and `MIGRACJA/POSTEP.md` in full first (they do not survive compaction). `git fetch origin` and,
if `origin/<BR>` is ahead, `git checkout -B <BR> origin/<BR>`. Continue from the first step without a POSTEP
entry. Never redo 1.2 or 3.2 on top of themselves; a half-done uncommitted step: `git stash`, redo it from its start.

## Final reply (Polish, ≤ 12 lines + standard ending)
K3–K5 and `<LOGIC>` results; auditors: fixed / rejected / known limits; what was NOT run (Windows, full test suite);
cost (`get_session`, last call, „stan na HH:MM”); „Zmiany w tej odpowiedzi”; „Następny krok”: „Otwórz nową sesję z
samym Foldery (Opus 5.5, /effort high, Auto) i wyślij: `Wykonaj MIGRACJA/PROMPT-ETAP-B-v2.md od kroku 1.`”;
`## ❓ Pytanie do Ciebie` only for decisions taken without the owner.
