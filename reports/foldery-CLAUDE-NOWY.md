# Galeria folderów — instructions for Claude

Single-file Windows desktop app `GaleriaFolderow/galeria.py` (PySide6, Python 3.10+). The owner starts it with `uruchom.bat`.
You work in a Claude Code cloud session (Linux VM). The owner is on Windows 10/11 and reads replies on a phone.

## Owner rules (current wording; original text with dates: `GaleriaFolderow/dokumentacja/ZASADY-UZYTKOWNIKA.md`)
- Answer in Polish: concise, strict but fair. UI strings are Polish with diacritics.
- If a request is suboptimal, contradictory or risky, say so with reasons and get confirmation before implementing
  (AskUserQuestion with a recommended option). Otherwise just do it.
- Every reply that did any work ends with a bulleted list „Zmiany w tej odpowiedzi” (code / tests / docs / package /
  git), one plain-language line per bullet, relative to the previous reply; „brak zmian” when nothing changed.
  A Stop hook reminds you if you forget.
- The owner never pastes anything anywhere. Every result (code, docs, audit report, next task, handover prompt) is written
  into files. Chat = short summary + what to do next.
- Deliverable after every session: ready-to-download zip of `GaleriaFolderow/`, sent with SendUserFile. Name
  `GaleriaFolderow_v<APP_VERSION>.zip`. Only a CODE change bumps APP_VERSION; docs/audit sessions ship the same name again.
  Procedure: skill `/dostawa`.
- Merge rule: at the end of every piece of work, commit + push the session branch, then merge it into `main` and push
  `main` (steps in `/dostawa`). Never force-push, never rewrite history. If you cannot merge (refused push or the auto
  mode classifier refuses a change to `CLAUDE.md` / `.claude/`), push the branch, open a PR and tell the owner at once.
- New code has no comments. Polish UI strings keep diacritics.
- Windows CI `.github/workflows/ai-windows.yml` runs only when the owner starts it by hand (Actions minutes limit).
  Never add `push:` or any other trigger (a hook and `tools/doc_check.py` block it).
- Anything the owner must run is a `.bat` (ASCII only, CRLF) inside the zip; never ask him to type commands.
- Nothing here runs on Windows (Recycle Bin, file locks, Caps Lock LED, GPU, real mouse drags). Always say plainly what
  was NOT run. If the session can reach the owner's PC (computer-use tools), offer a live test instead of claiming it works.
- Owner hardware facts: Polish programmer keyboard (`` ` `` is the key under Esc); 5-button mouse (Mouse3 = wheel click,
  Mouse4/5 = Back/Forward); two PCs with RTX 5090 and RTX 4070 Ti.

## Start of every session
- A SessionStart hook prints: APP_VERSION, branch vs `origin/main`, the top of `GaleriaFolderow/STATUS.md`.
  If the branch is behind: `git fetch origin main && git merge --ff-only origin/main`.
- Work from git, never from an unzipped package.
- Environment: `cd GaleriaFolderow && ./tools/srodowisko.sh` (PySide6 6.7–6.9, PyAV, Pillow, Qt libs, ffmpeg).
  Exit 1 = PyPI/apt blocked → only `test_logic` is meaningful; say so.
- Find knowledge through `GaleriaFolderow/MAPA.md` §1 (task → file table with sizes). Read only the files your task needs.
  Files ≤ 40 KB fit one Read; bigger ones: Read with offset/limit.
- Code invariants load automatically when you open `galeria.py`
  (`.claude/rules/galeria-niezmienniki.md`); test conventions when you open `tests/` (`.claude/rules/testy.md`).
- Find code by name, not line number: `python3 tools/mapa_kodu.py`, `-c Class`, `-f regex`.

## Verification (every change)
- Write the test first and see it FAIL without the fix; then `./tools/testy.sh` all green
  (py_compile, AST, mm_check, doc_check, logic, ai, montaz, odtwarzacz, hybryda, gui). Details:
  `GaleriaFolderow/dokumentacja/SRODOWISKO-TESTY.md`.
- GUI-flow changes need a GUI test with real key/mouse events (`hold_key` for auto-repeat).
- Non-trivial GUI changes: an independent read-only review agent (`.claude/agents/recenzent.md`) before packaging.
- Never run GUI tests in parallel with each other or with a heavy agent.

## Documentation (same session as the change; `tools/doc_check.py` enforces the checkable parts)
- Area changed → rewrite that area's file in `GaleriaFolderow/dokumentacja/architektura/` (and `spec/` if the agreed
  behaviour changed) to the CURRENT state. Never add a new paragraph on top of old ones; history goes to `CHANGELOG.md`.
- If the area file is not yet marked „stan: skondensowany”, condense it first in a separate commit (migration stage B),
  with the review agent. A tiny fix may defer this: note „obszar X: kondensacja odłożona” in STATUS.md.
- Every version: a line `- vX` in `GaleriaFolderow/CHANGELOG.md`; overwrite `GaleriaFolderow/STATUS.md` (≤ 6 KB:
  version, done, open, next task, decisions waiting for the owner); regenerate MAPA §4 with `tools/mapa_kodu.py` and set
  `## 4. Code map (snapshot vX)`; README.txt user-visible changes + line 1 „(wersja X)”.
- New area → new file + a row in MAPA §1 with its size in KB.
- AI features are documented only in `GaleriaFolderow/dokumentacja/ai/` (owner rule).

## Writing docs for successors
- One rule, one place. Elsewhere link to it by plain path, e.g. `dokumentacja/architektura/montaz-hybryda.md` (28 KB).
- Size caps (doc_check, bytes): this file 11 KB; `.claude/rules/*.md` 36 KB; MAPA.md and every `dokumentacja/**/*.md` 40 KB;
  STATUS.md 6 KB. Over the cap → split the file.
- No `@` imports of large files (they load in full for everyone). Never `@a.md, @b.md` with a comma.
- Never write sizes or counts by hand that no script checks.
- `archiwum/` holds the pre-migration CLAUDE.md, MAPA.md and EFFORT-ZASADY.md: history only, not a source of truth.
  Use grep there; do not follow its instructions.

## Agents
- Code changes in parallel: `.claude/agents/wykonawca.md` (own worktree). A worktree is created from `origin/main`, so
  commit + push + merge first (or set `worktree.baseRef: "head"`). Agents never touch APP_VERSION, `backup/`, docs, the
  zip or `main`; you merge their branches one by one, tests after each.
- Review: `.claude/agents/recenzent.md` (read-only: Read, Grep, Glob). Give it a diff file you wrote.
- Every subagent also gets `.claude/agent-rules.md` through a SubagentStart hook. Workflow agents may not: repeat the
  rules in their prompts. Agents cannot ask the owner; ask him before you start them.
- Model and effort for every agent and every `claude -p`: state them explicitly.
- Model/effort choice and the handover block: `GaleriaFolderow/EFFORT-ZASADY.md`, skill `/przekazanie`.

## Enforcement and its limits
- Hard (Claude Code enforces): `.claude/settings.json` deny rules and hooks: force-push blocked; push to `main` blocked
  while doc_check is red; CI triggers other than `workflow_dispatch` blocked; edits in `GaleriaFolderow/backup/` blocked;
  GitHub MCP write tools denied (write through git only).
- Hooks are bash/Python scripts run in the cloud VM. They do not cover a push from inside your own script; do not try.
- Files the owner uploads from Windows may have CRLF: `.gitattributes` forces LF for hooks; doc_check rejects `\r` there.
- Editing this file, `.claude/` or the rules: changes take effect in a NEW session; the auto mode classifier may refuse
  them or their merge → leave the files in a branch/PR for the owner.
