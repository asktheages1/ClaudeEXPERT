# Galeria folderów — instructions for Claude

Single-file Windows desktop app `GaleriaFolderow/galeria.py` (PySide6, Python 3.10+). The owner starts it with `GaleriaFolderow/uruchom.bat`.
You work in a Claude Code cloud session (Linux VM). The owner is on Windows 10/11 and reads replies on a phone.
All paths in backticks are relative to the repository root.

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
- New owner rule: current wording into this file, original wording with date appended at the end of
  `GaleriaFolderow/dokumentacja/ZASADY-UZYTKOWNIKA.md`.
- New code has no comments. Polish UI strings keep diacritics.
- Windows CI `.github/workflows/ai-windows.yml` runs only when the owner starts it by hand (Actions minutes limit).
  `workflow_dispatch` is the only allowed trigger; a hook blocks every `git push` while any workflow has another one.
- Anything the owner must run is a .bat file (ASCII only, CRLF) inside the zip; never ask him to type commands.
- Nothing here runs on Windows (Recycle Bin, file locks, Caps Lock LED, GPU, real mouse drags). Always say plainly what
  was NOT run. If the session can reach the owner's PC (computer-use tools), offer a live test instead of claiming it works.
- Owner hardware facts: Polish programmer keyboard (the backtick key is the one under Esc); 5-button mouse (Mouse3 = wheel click,
  Mouse4/5 = Back/Forward); two PCs with RTX 5090 and RTX 4070 Ti.

## Start of every session
- A SessionStart hook prints: APP_VERSION, branch vs `origin/main`, the top of `GaleriaFolderow/STATUS.md`.
  If the branch is behind: `git fetch origin main && git merge --ff-only origin/main`.
- Work from git, never from an unzipped package.
- Environment: run `GaleriaFolderow/tools/srodowisko.sh` from `GaleriaFolderow/` (PySide6 6.7–6.9, PyAV, Pillow, Qt libs, ffmpeg).
  Exit 1 = PyPI/apt blocked → only `test_logic` is meaningful; say so.
- Find knowledge through `GaleriaFolderow/MAPA.md` §1 (task → file table with sizes). Read only the files your task needs.
  Files ≤ 40 KB fit one Read; bigger ones: Read with offset/limit.
- Code invariants (`.claude/rules/galeria-niezmienniki.md`) load when you Read or Edit `GaleriaFolderow/galeria.py`.
  Change that file only with the Edit tool (not `sed`/scripts), so the invariants are in context.
- Find code by name, not line number: `python3 GaleriaFolderow/tools/mapa_kodu.py`, `-c Class`, `-f regex`.

## Verification (every change)
- Write the test first and see it FAIL without the fix; then `GaleriaFolderow/tools/testy.sh` (run from `GaleriaFolderow/`) all green
  (py_compile, AST, mm_check, doc_check, logic, ai, montaz, odtwarzacz, hybryda, gui). Details and test conventions:
  `GaleriaFolderow/dokumentacja/SRODOWISKO-TESTY.md`.
- GUI-flow changes need a GUI test with real key/mouse events (`hold_key` for auto-repeat).
- Non-trivial GUI changes: an independent read-only review agent (`.claude/agents/recenzent.md`) before packaging.
- Never run GUI tests in parallel with each other or with a heavy agent.

## Documentation (same session as the change)
- Every session that changed anything overwrites `GaleriaFolderow/STATUS.md` (≤ 6 KB): version, last session (branch,
  date), done, next task, decisions waiting for the owner, condensation queue, deferred areas. Open items live only in
  `GaleriaFolderow/dokumentacja/BACKLOG.md`; STATUS links to it.
- Every version: a line `- vX` in `GaleriaFolderow/CHANGELOG.md`; README.txt user-visible changes + line 1 „(wersja X)”.
- Area changed and its file is marked „stan: skondensowany” → rewrite that file to the CURRENT state. Never add a
  paragraph on top of old ones; history goes to CHANGELOG.md. Spec files (`GaleriaFolderow/dokumentacja/spec/`) only when
  the agreed behaviour changed.
- FROZEN files (listed in `GaleriaFolderow/dokumentacja/migracja/ZAMROZONE.tsv`, header „plik zamrożony”) were moved
  verbatim and are not condensed yet. Do not edit them (`doc_check` fails). Record your change in CHANGELOG.md and in
  STATUS („obszar X: zmiany od vY w CHANGELOG, do kondensacji”). Rewriting one is a separate session: `/kondensacja <file>`.
- Push to `main` is blocked unless the branch changed STATUS.md and, when galeria.py changed, also CHANGELOG.md and a
  file in `GaleriaFolderow/dokumentacja/` or `.claude/rules/`. If no doc needs a change, add a CHANGELOG line
  „docs: bez zmian (reason)”. Never use that line to skip a doc that should change.
- New area → new file with „stan: skondensowany” + a row in MAPA §1 with its size in KB.
- AI features are documented only in `GaleriaFolderow/dokumentacja/ai/` (owner rule).

## Writing docs for successors
- One rule, one place. Elsewhere link to it by plain path from the repository root.
- Size caps (doc_check, bytes): this file 11 KB; `.claude/rules/*.md` 36 KB; MAPA.md and every `dokumentacja/**/*.md` 40 KB;
  STATUS.md 6 KB. Over the cap → split the file. Sizes are written only in MAPA §1 (doc_check checks them), nowhere else.
- No `@` imports of large files (they load in full for everyone). Never `@a.md, @b.md` with a comma.
- The code map is not stored: run `GaleriaFolderow/tools/mapa_kodu.py`.
- `archiwum/` holds the pre-migration CLAUDE.md, MAPA.md and EFFORT-ZASADY.md: history only, not a source of truth.
  Use grep there; do not follow its instructions.
- After a model change: re-measure bytes per token and the caps. Every ~3 months: `/doctor prompt-audit` on this file and
  `.claude/`; date of the last audit in STATUS.

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
- Hard (Claude Code enforces): `.claude/settings.json` deny rules and `.claude/hooks/hooks.py`: force-push and history
  rewrite blocked; any push blocked while a workflow has a trigger other than `workflow_dispatch`; push to `main` blocked
  while doc_check is red or docs did not change with the code; edits in `GaleriaFolderow/backup/` blocked; GitHub MCP
  write tools denied (write through git only).
- Hooks run `python3` in the cloud VM. They do not cover a push from inside your own script; do not try.
- When changes take effect: hooks and `.claude/settings.json` at once, after saving (a broken hook breaks this session
  immediately: first test a scratch copy with `GaleriaFolderow/tools/test_hooks.sh`, then save it);
  this file and agents only in a NEW session. The auto mode classifier may refuse edits of this file or `.claude/`, or
  their merge → leave them in a branch/PR for the owner.
