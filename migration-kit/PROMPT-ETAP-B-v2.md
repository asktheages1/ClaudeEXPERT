# Stage B + C: accept stage A, rewrite every moved file in ONE session with agents, then clean up
# (template; Foldery values filled in as the example)

Replaces Foldery `GaleriaFolderow/dokumentacja/przekazanie/PROMPT-etap-B-partia.md` and its unmerged addendum
(466e645). Plan: `MIGRACJA/PLAN-MIGRACJI-v5.md`; owner decisions: `MIGRACJA/DECYZJE.md` (never ask them again).
This prompt is frozen once the session starts. It is > 5,000 tokens: after compaction only its path returns — the
resume section says what to do.

```
USTAW PRZED WKLEJENIEM
Model: Opus 5.5 (sprawdź w wyborze modelu — nie Fable) · wysiłek: high · workflow: nie (narzędzie Agent)
Start: nowa sesja z JEDNYM repozytorium Foldery (main), tryb Auto
Pierwsza wiadomość: Wykonaj MIGRACJA/PROMPT-ETAP-B-v2.md od kroku 1.
Co zobaczysz: najpierw sprawdzenie etapu A, potem próba na 2 plikach (ok. 20 min) — pokażę Ci 3 linie wyniku do
oceny. Potem fale: naraz do ok. 10 agentów (5 piszących + 5 recenzentów) — to normalne dla narzędzia Agent.
Po próbie możesz odejść: sesja sama się budzi i wznawia; każdy gotowy plik jest od razu zapisany w git.
Jeśli wrócisz, a sesja stoi — napisz: wznów.
Szacunek: 110–150 USD, 1,5–2 h (przeliczę po próbie; powyżej 1,3 × górnej granicy przerwę i zapytam).
```

## Placeholders (filled at step 1; agent prompts get absolute paths, never `<…>`)
| Name | Value / how |
|---|---|
| `<VER>` | `grep -m1 -oP 'APP_VERSION = "\K[^"]+' GaleriaFolderow/galeria.py` |
| `<BASE_SHA>` | `git rev-parse --short origin/main` at step 1 |
| `<DATE>` | today, YYYY-MM-DD |
| `<BR>` | `git branch --show-current` |
| `<S>` | the session scratchpad directory (absolute) |
| `<CODE>` / `<LOGIC>` | `GaleriaFolderow/galeria.py` / `cd GaleriaFolderow && ./tools/testy.sh logic` |
| `<slug>` | file name without `.md`, per file (also inside a group); `grupa-1`… for a grouped writer |
| UI names kept verbatim | Katalog, Katalogowanie, Litery, Osoby, Strzałki, Boksy, Opcje, Montaż, Ściana, Tutaj, Szybko, Cięcie and every other label shown in the program |

## Scope: 25 units (bytes after stage A); one writer per unit unless grouped; one reviewer per FILE
Big: `ai/USUWANIE-OBIEKTOW-3.md` 35740, `ai/USUWANIE-OBIEKTOW-2.md` 32569, `architektura/tryb-ciecia.md` 32384,
`OGRANICZENIA.md` 32365, `architektura/panele.md` 31855, `.claude/rules/galeria-niezmienniki.md` 30878 (rule file),
`spec/SPEC-B.md` 29415 (spec), `architektura/montaz-hybryda-2.md` 28383, `spec/SPEC-A.md` 27897 (spec),
`architektura/sortowanie-osoby-litery.md` 26711, `architektura/montaz-hybryda-1.md` 24038, `PLIKI.md` 23592,
`architektura/przegladarka-wideo.md` 20635, `architektura/sortowanie-strzalki-boksy.md` 20445.
Medium, grouped by size (≤ ~35 KB per writer): `ai/USUWANIE-OBIEKTOW-1.md` 19088 + `architektura/okno-adresu-kadr-filmu.md`
10597; `architektura/przycinanie-edycja.md` 15922 + `architektura/katalog.md` 15184; `architektura/watki-tlo-diagnostyka.md`
10839 + `architektura/okno-glowne.md` 9813 + `architektura/operacje-plikow.md` 8750.
Small, one writer: `SRODOWISKO-TESTY.md` 5154, `architektura/wyszukiwarka.md` 4923, `architektura/ai-wskazniki.md` 4894.
Special: `architektura/mapa-kodu-reczna.md` — keep only what `python3 GaleriaFolderow/tools/mapa_kodu.py` does not
print; move that into the matching area files' drafts (route as „for <file>”), then delete the file.
Paths are under `GaleriaFolderow/dokumentacja/` unless they start with `.claude/`. Every moved file is in scope; a
file not rewritten at the end is reported, never silently left.

## Rules for this session
- Writers write drafts OUTSIDE the repo; only the main session writes inside it. The main session never reads a draft
  in full: mechanical gates + the reviewer read it.
- Agent calls: `subagent_type`, `model: "opus"`, `effort: "high"`, `run_in_background: true`; `name` only if the Agent
  schema lists it. At most 10 agents running at once, resumed ones included (a resume takes a fresh slot); a writer in a
  fix round uses a writer slot.
- After launching agents end the turn; never poll (no Monitor, list_events, sleep loops). Before ending such a turn,
  if ToolSearch finds `send_later`, keep exactly one pending wake-up 25 min ahead: „Sprawdź worker_epoch i ledger;
  wykonaj Wznowienie” (its trigger id in `<S>/agenci.txt`; the previous one deleted with `delete_trigger`). Before
  step 11 delete the pending wake-up; from step 11 on no new wake-ups (spec re-reviews there run with
  `run_in_background: false`).
- Before every launch: `get_session` — `rate_limit_info.status` ≠ `allowed` or `isUsingOverage` = true → launch
  nothing, finish running units, `send_later` at `resetsAt`. A notification „failed” → same check; else resume once.
- One unit per commit; `git add` of exact paths, never `-A` or globs; push the branch after every commit.
- Ledger `MIGRACJA/POSTEP-B.md` (committed with each unit): header = `<S>`, `<BR>`, `worker_epoch`, process start
  (`ps -o lstart= -C claude`), session id; one row per ACCEPTED unit: file, bytes old → new, review B/I/M, fixed ids,
  rejected ids + evidence, verified by grep (yes/no). Live state (agentIds, drafts in progress) only in `<S>/agenci.txt`.
  Every change of the brief after the pilot is copied to `MIGRACJA/brief.md` and committed.
- Shared files (MAPA, CHANGELOG, STATUS, ledger) belong to the main session; agents are told so.
- Context: keep agent replies short (the limits below); automatic compaction (~784k) is survived by the resume
  section's step 0.
- Owner questions: AskUserQuestion only if the owner wrote in the last 10 minutes; otherwise collect them for step 11.

## 1. Start and acceptance of stage A
1. `git fetch origin main && git merge --ff-only origin/main`; fill the placeholders. `get_session`:
   `session_context.model` = claude-opus-5-5, `external_metadata.last_served_model` = claude-opus-5-5 and
   `session_context.effort_level` ∈ {high, xhigh, max} (when present), else stop.
   Write the ledger header. Copy this prompt to `<S>/prompt.md`.
2. Acceptance of A (results go into the stage-C CHANGELOG line): K1 by `claude -p "/context" --model opus --effort high
   --permission-mode default --max-turns 1 --max-budget-usd 0.5` in the repo root (≤ 8k); K2 = K1 + the rule file's
   tokens by import (≤ 25k) — do NOT Read `<CODE>` in this session; skills `/dostawa`, `/przekazanie` listed;
   `git push --dry-run --force origin HEAD` → blocked; stop reminder: after this step's first file change, the reply
   without „Zmiany w tej odpowiedzi” gets one reminder.
3. `python3 GaleriaFolderow/tools/doc_check.py` green; `git status` clean; ToolSearch: `SendMessage` (else fix rounds use a
   fresh `fix-<slug>` agent with the brief + review) and `send_later`.

## 2. Scratch
`<S>/stary/<slug>.md` = `git show origin/main:<path>` for every unit; `<S>/nowy/`; `<S>/brief.md` and
`<S>/brief-spec.md` from the sections below (filled); `<S>/tools/lost_names.py`; `<S>/agenci.txt`.

## 3. Anchors
For each unit: `git grep -n '<file name>' -- GaleriaFolderow .claude CLAUDE.md ':!GaleriaFolderow/backup'` → headings or
lead-ins of this file cited elsewhere → the writer's „keep or map” list.

## 4. Pilot: `galeria-niezmienniki` (rule file) and the small group, in parallel
Run steps 5–8 for both. Record cost before and after (`get_session`). Go / no-go:
(a) completion notifications = agents launched, and `worker_epoch` and process start unchanged → go. A change means
    agents without a notification are lost: do the resume section and continue. Two restarts within pilot + first
    wave → switch to foreground agent calls (`run_in_background: false`, several in one message) for the rest.
(b) pilot cost ≤ 15 USD; extrapolate (pilot USD ÷ pilot files) × 25 + 15. Above 1.3 × 150 → finish, ask the owner.
(c) no systematic flaw in the reviews; if there is one, fix `brief.md` (and `MIGRACJA/brief.md`) before the waves.
(d) refusals in reports: a classifier refusal of `cp` into `.claude/rules/` → one line to the owner (Accept edits).
Show the owner (if present) a 3-line sample: language, KB before → after, the first 3 content lines of one draft.

## 5. Gates on each draft (mechanical)
`wc -c` ≤ 40 000 (rule file ≤ 36 000); rule file: lines 1–3 are exactly the frontmatter; header line `stan:
skondensowany v<VER> (<DATE>)` once within the first 10 lines after any frontmatter; `grep -c '^\*\*v[0-9]'` = 0; no line
contains `Moved verbatim`; bytes ≤ old × 1.10 or item 5 of the report justifies the growth; spec units: the point numbers
are identical — old: top-level list items `grep -cE '^[0-9]+\. '` (Foldery: 28 in SPEC-A = 5.1–5.28); new: headings
`grep -oE '^## 5\.[0-9]+'` (the spec brief prescribes `## 5.N <title>`) — same count and same N set. `lost_names.py` output goes to the
reviewer as a hint only. Failure → SendMessage to the writer with the exact output. > 40 KB after one fix round: the
writer's split proposal (names + sections) is applied by the main session (two files, two MAPA rows).

## 6. Review
`recenzent` (Read, Grep, Glob), one per file, started as soon as a draft passes the gates, with the reviewer prompt.

## 7. Fix round and verification
SendMessage the review to the writer. Every finding ends fixed or rejected with evidence. The writer reports finding →
new line number; the main session greps every blocking/important fix at that line and every blocking/important
rejection against the code. Re-review of the fixed findings by the same reviewer if the file had ≥ 1 blocking or ≥ 2
important findings, and ALWAYS for spec units. Writer reports are grepped for „for <file>:” — content for another file
goes to that file's writer, or to the sweep list (step 9) if that file is already accepted.

## 8. Accept a unit (one at a time)
`cp` draft → repo path; MAPA §1 row „(N KB)” + section names; ledger row; `doc_check` green; `git add` exact paths;
commit message „rewrite <file>: review B/I/M; fixed …; rejected …”; push. Then launch the next unit (big first;
`OGRANICZENIA.md`, `PLIKI.md` and the spec units last — they cite the others).

## 9. Sweep (only after all units are committed)
`git grep` the rewritten files, MAPA §1, `dokumentacja/ai/README.md`, BACKLOG, `PROPOZYCJA-*.md`, skills for old lead-ins
or renamed headings → new section names; apply the sweep list of step 7; exact paths in `git add`.

## 10. Stage C — clean-up (order matters: references first, deletions after)
1. `/CLAUDE.md`: remove migration-only text (moved files, stage B). Refused by the classifier → stop C here, keep every
   file it cites, list the change for the owner (PR description).
2. Every `DECYZJE.md` answer that governs future sessions (D3, D6, language) is in `/CLAUDE.md` (grep each) — else add it
   now. Then `git grep -n` each path to be deleted (`archiwum/`, `GaleriaFolderow/dokumentacja/migracja/`, `mapa-kodu-reczna.md`,
   `MIGRACJA/`) in `CLAUDE.md`, MAPA, skills, STATUS, docs → fix those references in the same commit as the deletion.
3. Check: `grep -L 'stan: skondensowany'` over the unit list and `git grep -l 'Moved verbatim' -- ':!.claude/skills/przeglad' ':!*ZASADY-UZYTKOWNIKA.md' ':!*.zip'` → both
   empty.
4. CHANGELOG: delete `## Status log (history)` (git keeps it); one line directly under `## Versions (newest first)`
   (Python edit asserting the heading once): „- v<VER> dokumentacja (<DATE>): stages B+C: N files rewritten (review
   B/I/M; fixes grep-verified), mapa-kodu-reczna removed, migration tooling removed; acceptance of A: K1 …, K2 …”.
5. STATUS overwritten (≤ 6 KB): done, next task, decisions waiting, „Ostatni przegląd: <DATE> <HEAD SHA>”.
6. `git rm` of `archiwum/`, `GaleriaFolderow/dokumentacja/migracja/`, `GaleriaFolderow/dokumentacja/architektura/
   mapa-kodu-reczna.md` and LAST `MIGRACJA/` (resume now uses `<S>/prompt.md` and `git show HEAD~1:MIGRACJA/POSTEP-B.md`).
   Commit subject „stage C: clean-up + cost table”; body = cost table: `get_session` usage.cost_usd of this session and of the stage-A session (its id is in
   STATUS history: `git log -p --all -S 'session_' -- GaleriaFolderow/STATUS.md`), time per stage, review totals,
   agent starts — the next advisor reads it as priors.

## 11. Decisions, then delivery
Collected questions (writers' item 8, spec points the code contradicts, refused edits, defaults taken). Owner present:
one AskUserQuestion (≤ 4 questions, recommended first); answers for spec points are applied to the SPEC files now and
re-reviewed (those points only); other answers → STATUS / BACKLOG. Owner absent: record them as waiting; „Następny
krok” then names the short follow-up. Then `doc_check` + `<LOGIC>` green; `/dostawa` (zip per D3; merge in three calls;
only when no agent runs). Classifier refuses → PR + tell the owner.

## 12. Final reply (Polish, ≤ 12 lines + standard ending)
Units done / split / deleted, review totals with „fixes verified by grep”, K1/K2, cost (`get_session` as the last call,
„stan na HH:MM”) vs estimate, what was NOT verified; „Zmiany w tej odpowiedzi” → „Następny krok” → `## ❓ Pytanie do
Ciebie` (only questions not asked in step 11). Per-file details stay in the commit messages and the ledger history.

## Wznowienie (after a restart, a missing notification, „wznów”, or compaction)
0. Re-read `<S>/prompt.md` (or this file) and the ledger in full before any action.
1. `git fetch origin` and, if `origin/<BR>` is ahead, `git checkout -B <BR> origin/<BR>`. Committed units = ledger rows.
2. `<S>` missing → recreate step 2; `<S>/brief.md` ← `MIGRACJA/brief.md` if present.
3. Per unit not committed: report file `<S>/nowy/<slug>.md.report.md` missing → new writer (new name if names are
   used); report present, no review → reviewer; review present, fixes not verified → fix message (writer gone →
   `fix-<slug>`). Never redo committed units.
4. Record the new `worker_epoch` and process start in the ledger header. A permission prompt while the owner is away:
   wait; then continue here.

## Writer brief (`<S>/brief.md`)
```
# Rewrite brief (Foldery stage B, <DATE>). Owner decision: agents write drafts outside the repo; the main session
# gates, copies and commits. No code change: the injected test-first rule and its 5-point Polish report do not apply;
# your report is this brief's (English). Rules in CLAUDE.md about frozen files, /kondensacja, zip and reply footers
# address the main session, not you. MAPA, STATUS, CHANGELOG are not yours.
You rewrite ONE moved documentation file of Galeria folderów (GaleriaFolderow/galeria.py, PySide6, 1.8 MB) into a
description of the CURRENT state of the code, in ENGLISH. Write only your output path and its .report.md. Never edit
files under /home/user/Foldery; git read-only (show, log, grep), no git status/diff, no push, no agents. Never ask the
owner: describe the code's behaviour, put the question in report item 8, finish the draft.
1. Read the old file once in full. Paragraphs are version layers, usually newest first; newer supersedes older.
2. The code is the arbiter: verify every name, key, constant, default, limit and behaviour you keep
   (python3 GaleriaFolderow/tools/mapa_kodu.py -f '<regex>' | -c <Class>; grep -n; Read galeria.py only with
   offset/limit). Text the code contradicts = old: describe the code; list it in item 4.
3. English; identifiers, keys, paths verbatim; UI names stay Polish and verbatim in „…”: <UI names>. Decimal points.
   One rule in one place. No history, no dates of decisions, no „the user said”; no line starting with **v<digit>.
   Header within the first 10 lines (after the 3 frontmatter lines in a .claude/rules file, which stay verbatim):
   title; `stan: skondensowany v<VER> (<DATE>)` + history: `git show <BASE_SHA>:<path>`, CHANGELOG.md; then agreed
   behaviour, known gaps, invariants, name hints, tests.
4. Keep the anchors of your task; a renamed section gets „Old references: „old” → §N”.
5. Size: ≤ old bytes × 1.10. Add something the old file lacked only when a reader would otherwise be misled; list each
   addition in item 5. Never drop a rule to save bytes. Hard cap 40,000 bytes (rule file 36,000); if it cannot fit,
   propose a split at ## boundaries (names + sections). Content that belongs to ANOTHER doc file: leave it out and
   write „for <file>: …” in item 5.
Report → <output>.report.md (items: 1 path + bytes; 2 sections, one line each; 3 anchors renamed; 4 code contradicted
the old text, with grep evidence; 5 additions, drops, „for <file>:” items; 6 decisions taken; 7 not verified; 8 open
questions; 9 refusals verbatim; „none” valid for 3–9). Return ≤ 10 lines: path, bytes, counts per item, item 8.
After a fix round return: finding id → fixed (new line) / rejected (evidence); final bytes.
```

## SPEC brief (`<S>/brief-spec.md`)
= writer brief with items 2 and 5 REPLACED; in item 3, „no dates of decisions / no „the user said”” does not apply
(decisions keep their attribution, see 2′).
2'. The spec is binding agreed behaviour, cited by code as `§5.N`. Keep EVERY point and its number, each as a heading
    `## 5.N <title>` (no renumbering, merging or splitting of points); keep each decision with a short attribution („owner, <date>”) — it is the
    agreement, not history. Where the code disagrees: keep the spec text, add „Code today: …” with grep evidence, list
    the point in item 8. Never change the spec to match the code.
5'. Size: no target; drop only history narrative. Over 40,000 bytes: propose a split at a point boundary.

## Writer call
Prompt: „Read <S>/brief.md (spec units: <S>/brief-spec.md) first and follow it. File: <repo path> (<bytes> B). Old copy:
<S>/stary/<slug>.md. Output: <S>/nowy/<slug>.md. Anchors (keep or map): <list | none>. Notes: <1–3 lines | none>.”
Grouped writer: each file with its own paths, one after another, one report file each.

## Reviewer prompt
„Independent review of a rewritten documentation file. Your report format and language here replace the injected
agent rules and your definition's defaults. Old: <S>/stary/<slug>.md. New: <S>/nowy/<slug>.md. Code:
GaleriaFolderow/galeria.py (Grep; Read only with offset/limit). Check: every rule, number, key binding, default, limit
and decision of the old file is in the new one, or superseded by a newer paragraph of the old file, or is history; no
meaning changed; doubtful claims agree with the code; header line present; anchors kept or mapped: <list>; English
with these UI names verbatim: <UI names>. [Spec: every point number kept; disagreements kept and listed, never
resolved.] Hint, not proof — names in old + code but not in new: <lost_names output>. Not your scope: MAPA, STATUS,
CHANGELOG. Also name bloat (growth without a code reason, history, duplicates of another file) as cut proposals.
Output English, findings only, ≤ 20 lines: id, severity (blocking / important / minor), line new, line old, evidence,
fix; last line counts. Do not list passed checks. „Nothing found” is valid.”

## `<S>/tools/lost_names.py`
```python
import re, sys
old, new, code = (open(p, encoding="utf-8", errors="replace").read() for p in sys.argv[1:4])
norm = lambda m: re.sub(r"\(.*", "", m).split(".")[-1]
names = lambda t: {norm(m) for m in re.findall(r"`([A-Za-z_][A-Za-z0-9_.]*(?:\([^`]*\))?)`", t)}
new_words = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]{3,}", new))
lost = sorted(n for n in names(old) - names(new) if len(n) > 3 and n in code and n not in new_words)
print("\n".join(lost) if lost else "none")
```
