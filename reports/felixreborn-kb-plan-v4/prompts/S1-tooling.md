# S1 — Tooling: inputs, structure checker, push gate to `main`, start and agent hooks, hook tests, `/dostawa` [G3; protects G1–G2]

The owner starts this session with „Wykonaj docs/prompts/S1-tooling.md”. Read `CLAUDE.md` in full first, then `docs/prompts/COMMON.md` in full (its "Access" section binds this session), then this prompt. Model check: `echo $CLAUDE_EFFORT` and `get_session` (if available); say in the reply whether this is Opus 5.5 / high and continue either way.

## Goal
FelixReborn's uploaded inputs are verified. It gets:
- a structure checker ported from Foldery;
- a hook that blocks a push to `main` while that checker is red, or when the push is not a separate Bash call, not `HEAD`, or the tracked tree is dirty;
- start and agent-injection hooks;
- hook tests in Foldery's pattern;
- the end-of-work skill `/dostawa`;
- a `CLAUDE.md` that claims only what is live.

`knowledge/` content is not edited in this session.

## Read in full
- `CLAUDE.md`, `docs/prompts/COMMON.md`, `docs/prompts/PLAN.md` (§3, §4, §8 are the spec for this session).
- `docs/import/foldery/doc_check.py`, `docs/import/foldery/hooks.py`, `docs/import/foldery/dostawa-SKILL.md`, `docs/import/foldery/settings.json` (Foldery at ec7ce87, uploaded by the owner; reference only, Polish messages: port them, do not run them as this repository's tools).
## Read in part (say so)
- `docs/import/foldery/test_hooks.sh`: lines 1–140 (isolation, `wynik`, `cb`, fixture, `nb`) and the sections step 7 names.
- `knowledge/O0-how-claude-works.md` §2 and §4 (nested CLAUDE.md loading, hooks); `knowledge/O2-syntax-cheatsheet.md` §A (hook events, exit codes, output limits).

## Steps
1. **Inputs check** (no cloning; COMMON "Access": this session reads no other repository or branch).
   - `CLAUDE.md` must exist at the root. If it does not (e.g. only `claude.md.md`): stop. This session started without the owner's instructions, because Claude Code loads only `CLAUDE.md` (`docs/import/FINDINGS-claudeexpert.md` 2026-10-12 [MEASURED]). Tell the owner to rename the file and start again.
   - `sha256sum -c docs/import/MANIFEST.sha256`: every line `OK`. Any `FAILED` or missing file: stop (COMMON stop rule) and list them. A CRLF copy also fails, and the 40,000 B caps depend on LF.
2. **State files** (only those missing; never overwrite an existing owner file — report it):
   - `STATUS.md` (≤ 6 KB): version `0.1.0`, last session, done, next task, decisions waiting for the owner, deferred, and the line `Last review: <today> <SHA of HEAD before this session's first commit>`.
   - `MAPA.md`: §1 table task → file with `(N KB)` for every `docs/**/*.md`, `docs/import/` included.
   - `CHANGELOG.md`: `## Versions (newest first)`, one line.
   - `docs/FINDINGS.md` (header), `docs/BACKLOG.md` (header).
   - `docs/OWNER-RULES.md`: append, dated, the owner's original wording from `docs/prompts/PLAN.md` §2a (2026-10-11) and §2b (2026-10-12), each with the condensed English rule from §2 / §2b.
   - `.gitignore`: `.claude/kbgate/`, `.claude/worktrees/`, `_tmp/`, `__pycache__/`.
3. **Interim base map** `knowledge/CLAUDE.md` (≤ 9,000 B together with `agent-rules.md`):
   - what the base is; the reading rule (COMMON "Reading");
   - `As of: Claude Code 2.1.291 (2026-10-06)`: the newest version the snapshot covers. the 2.1.292–2.1.293 lines are in `docs/import/O0-claudeexpert-delta-2026-10-12.md` until S3, which also moves the `As of:` line;
   - the evidence-tag legend and the "Known open conflicts" list, copied verbatim from `docs/import/claudeexpert-tags-and-conflicts.md`;
   - one line per O-file with `(N KB)` and its contents column from that file's table.

   S2 replaces this map.
4. **`tools/doc_check.py`** per PLAN §3.
   - Keep Foldery's structure: `limits()`, `warnings()`, `problems()`, the size-annotation regex, tolerance `max(0.1 * real, 1000)`, the dead-path check narrowed per PLAN §3, the `(N KB)`-outside-maps rule. English messages.
   - Leave out the version, README, CHANGELOG-order, galeria, workflow and frontmatter rules: they serve no goal here.
   - Two maps: `knowledge/CLAUDE.md` covers `knowledge/*.md`; `MAPA.md` §1 covers `docs/**/*.md`, `docs/import/` included.
   - `CLAUDE.md` size is counted with `<!-- … -->` removed.
   - `--self-test` with fixtures in `tests/doc_check/`: one pass and one fail case per rule. The self-test copies a fixture tree to a temp dir and runs the checks with `--root`.
   - Must be green on today's tree. O-files are under their caps (O0 50,000, O1–O5 40,000). O2 at 99.9 % gives a WARNING: expected, and not a split trigger, since it is not edited this session.
5. **`.claude/hooks/hooks.py`** with handlers `bash`, `session`, `subagent`, ported per PLAN §3–§4.
   - Copy Foldery's functions verbatim where the PLAN says "unchanged", including the three refusals (separate Bash call, `HEAD` only, clean tracked tree; owner, 2026-10-12).
   - Add the recognition of `--all` / `--branches` / `--mirror` / `*` or source-less refspecs, and of a refspec-less push under `remote.*.push` / `push.default upstream|tracking|matching`, as a push to `main` (PLAN §3). Do not port Foldery's standing refusals of these forms.
   - Adapt paths: `tools/doc_check.py` from the repo root; `STATUS.md` at the root; version = the `Version:` line of `STATUS.md` instead of `APP_VERSION`; `Last review:` instead of `Ostatni przegląd:`; health check 90 days.
   - Delete what PLAN §3 lists as not ported. Messages in English; every block (exit 2) writes its reason to stderr.
   - `subagent`: `additionalContext` = `.claude/agent-rules.md` + `knowledge/CLAUDE.md` with HTML comments removed.
   - **`.claude/agent-rules.md`** (short; counts toward the 9,000 B injection): the skeleton's subagent paragraph (l. 43–44) condensed; "the base map follows; a task that names a topic: read that file in full (Read, or exactly `cat <path>` ≤ 28 KB) before answering"; "write only your output path".
6. **`.claude/settings.json`**: merge into the existing file if any (keep owner entries).
   - Entries: SessionStart (`startup|resume|compact`, timeout 60), SubagentStart, PreToolUse matcher `Bash` timeout 120.
   - Commands in Foldery's form `[ ! -f "$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py" ] || exec python3 -I "$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py" <handler>`.
   - Hooks take effect at once (O0 §4): write settings only after step 7's `bash tools/test_hooks.sh .claude/hooks/hooks.py` is green (do step 7 before this step).
   - From this step on `hooks.py` is live. Any later change to it, e.g. a reviewer fix: edit a copy in `$SCRATCH`, `bash tools/test_hooks.sh <copy>` green, then copy it over.
   - A classifier refusal on `.claude/`: COMMON fallback is `/dostawa` step 6; say so.
7. **Hook tests** `tools/test_hooks.sh` per PLAN §3 "Hook tests": path argument, isolation, bare-`origin` fixture with `nb`, `RED=1` checker stub, `bash_case` and the other helpers, `2-without-message` = failure, `RESULT: n/m`, exit ≠ 0 on failure.

   Port the pattern with English names, not Foldery's cases. Cases below. "Pair" = `RED=1` → 2 and `RED=0` → 0 on a clean tree at `HEAD`.
   - **Not a push → 0:** `ls; echo push`; a commit message containing `git push origin HEAD:main`; `git status`; empty command; `git checkout main && git merge x` without a push.
   - **Session branch push → 0 with `RED=1` and `RED=0`:** `git push origin <branch>`, `-u`, bare `git push`, `HEAD:<branch>`, `--dry-run`; branches named `claude/main` and `mainline`.
   - **Push to `main` recognised → pair** (Foldery „rozpoznanie pushu do main”): `HEAD:main`, `HEAD:refs/heads/main`, `<current branch>:main`, `<HEAD sha>:main`, `--dry-run`, `-u`, two refspecs, wrappers `timeout` / `env` / `VAR=` / subshell / `if` / `while`, `git -C .`, `cd <repo> && git push origin HEAD:main`.
   - **Bulk forms → 2 with `RED=1`** (PLAN §3): `--all`, `--branches`, `--mirror`, `'refs/heads/*:refs/heads/*'`, `:main`. Not refused with `RED=0` for their form alone (Foldery's standing refusals are not ported).
   - **Push without refspec under config → 2 with `RED=1`** (counts as a push to `main`, PLAN §3; cases from Foldery „push bez refspec przy konfiguracji”): under `-c remote.origin.push=…`, under `push.default upstream|tracking|matching`, and the same set in the repository config. An explicit session-branch refspec under the same config → 0 with `RED=1` and `RED=0`. Plain `git push` without such config on a session branch → 0.
   - **The three refusals with `RED=0`** (Foldery „źródło pushu do main”, „czyste drzewo”, „fetch/checkout/merge w jednym wywołaniu”):
     - another branch or SHA as source → 2; an ancestor of `origin/main` → 0;
     - modified or staged tracked file → 2; only an untracked file → 0;
     - `fetch` / `checkout` / `switch` / `merge` / `pull` / `rebase` / `reset` / `commit` and a push to `main` in one call → 2;
     - `git status && git log -1 && git push origin HEAD:main` → 0.
   - **`main` checked out in a worktree:** bare `git push` and `git push origin HEAD` from it → 2 with `RED=1` (Foldery „gałąź main w worktree”).
   - **`/dostawa` path:** call 1 (`git fetch origin main && git checkout -B main origin/main && git merge --no-edit <branch>`) with `RED=1` → 0; call 2 (`git push origin main`) → pair. `-o` / `--push-option` → pair.
   - **No reachable `origin`** (fetch fails; the hook must not crash): push of `HEAD` to `main` → 2 with `RED=1`; `<other sha>:main` → 2 (the ancestor check fails).
   - **`session`:** version line, top of `STATUS.md`; „health check due” only after 90 days of `Last review:`; sources `startup`, `resume`, `compact`.
   - **`subagent`:** `additionalContext` ≤ 9,000 B (`jq -r .hookSpecificOutput.additionalContext | wc -c`); contains `.claude/agent-rules.md` and a map line.
   - **Bad JSON and empty stdin:** `session` / `subagent` → 0. For `bash`, assert what the ported code does; a block must carry a message.
   - **Wrapper:** `hooks.py` missing → 0. A CRLF copy: red push to `main` → 2, branch push → 0.
   - **Known limits `limit/…`** per PLAN §3.

   `tools/tests.sh` = `doc_check.py --self-test` + `doc_check.py` + `bash tools/test_hooks.sh .claude/hooks/hooks.py`.
8. **Skill `.claude/skills/dostawa/SKILL.md`** per PLAN §3 (no version bump, zip or package: FelixReborn ships none yet).

   **`.claude/agents/reviewer.md`**: `name: reviewer`, description, `tools: Read, Grep, Glob`, `model: opus`, `effort: high`, body = the reviewer task from COMMON. An agents directory created mid-session needs a new session (O0 §3), so it is first used in S2.
9. **Live check** of the push gate from a detached worktree in `$SCRATCH` with a bare remote (never GitHub):
   - one nested `claude -p` asked to push a commit that breaks a map size to `main` → blocked, stderr names the problem;
   - then to a work branch → passes.

   Assert with `git for-each-ref` on the bare remote, not with the model's words. n=1 each; record in `docs/FINDINGS.md`.
10. **`CLAUDE.md`** edits listed for S1 in PLAN §8 (l. 48 de-linked, so `doc_check` stays green), nothing else; report bytes before/after. Then `docs/OWNER-RULES.md` entry for the reviewer rule (l. 30) and merge policy A.
11. **Reviewer** (COMMON; this session: `subagent_type: "general-purpose"`, `model: "opus"`, `effort: "high"`; the prompt says "do not edit files and do not run commands that change anything"). It reads:
    - PLAN §3–§4, §8;
    - the diff patches;
    - the Foldery files in `docs/import/foldery/`;
    - `tools/tests.sh` output saved to `$SCRATCH/review/tests.txt`.

    Its task is the owner's newer reviewer rule (PLAN §2, 2026-10-11): only factual errors and failing done-criteria. It replaces `CLAUDE.md` l. 30, which step 10 edits. Fix its (a)/(b) findings (a `hooks.py` fix: scratch copy first, step 6).
12. **End**: `/dostawa` steps by hand (the skill was created this session; invoke it if listed, otherwise follow the file). `STATUS.md` "Next task": `docs/prompts/S2-migration.md`.

## Done when
```
sha256sum -c --quiet docs/import/MANIFEST.sha256 ; echo exit=$?   # 0
python3 tools/doc_check.py ; echo exit=$?          # 0; a WARNING for O2 allowed
python3 tools/doc_check.py --self-test ; echo exit=$?
bash tools/test_hooks.sh .claude/hooks/hooks.py | tail -1   # RESULT: n/n
bash tools/tests.sh ; echo exit=$?
git -C "$SCRATCH/kbtest-remote.git" for-each-ref    # the blocked push is absent, the branch push present
git status --short | wc -l                         # 0
git log origin/main -1 --format=%H                 # equals the session's merge commit (or the PR link, if the merge was refused)
```
