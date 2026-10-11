# S00 — Bootstrap: state files, checker (phase 0), test harness, trusted CI

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Give the repository its first hard mechanism (a checker that CI runs from `main`) and its first honest state file, before any knowledge-base content moves. Nothing in `knowledge/` changes in this session.

## Read in full (Read tool)
- `CLAUDE.md`
- `knowledge/O0-how-claude-works.md` (sections 1, 2, 4, 7, 8)
- `knowledge/O2-syntax-cheatsheet.md` lines 1–200 (hooks) and section D
- `knowledge/FINDINGS-claudeexpert.md` (entries dated 2026-10-11)

## Preconditions (stop and report if any fails; do not improvise)
1. `knowledge/` contains `O0-how-claude-works.md` … `O5-model-behavior-and-system-design.md` and `FINDINGS-claudeexpert.md`. If absent: the owner copies them from `asktheages1/ClaudeEXPERT` (`knowledge/` and `findings.md`). Stop.
2. `git fetch origin main` works and the branch is cut from `origin/main`.
3. `python3`, `jq`, `sha256sum` present (`which`); record versions in the reply.

## Work
1. **State files.** Create `STATUS.md` (≤ 6 KB) with sections: Version, Last session, Done, Next task, Decisions waiting for the owner, Deferred, **Live mechanisms** (today: "none; every hook, gate, agent and skill named in CLAUDE.md is advice until listed here"), and the line `Last review: <date> <SHA>`. Create `MAPA.md` §1 (task → file, size in KB; include the six KB files), `CHANGELOG.md` (one line), `docs/FINDINGS.md` (header + the evidence-tag legend copied from `knowledge/FINDINGS-claudeexpert.md`), `docs/BACKLOG.md`, `docs/OWNER-RULES.md` (empty), `docs/TESTS.md` (how to run `tools/test_hooks.sh` and `tools/kb_check.py`).
2. **Missing decisions.** List every `<…>` placeholder in `CLAUDE.md` in `STATUS.md` under "Decisions waiting for the owner", one line each, with your recommended value and a one-line reason. Do not fill any of them.
3. **`.gitignore`**: `.claude/kbgate/`, `_tmp/`, `Warsztat/_scratch/`, `*.pyc`, `.claude/worktrees/`.
4. **`tools/kb_check.py`** with `--phase N` (default: the phase in `knowledge/STATE.md`, which does not exist yet → phase 0) and `--tree HEAD|--worktree`. Phase 0 checks, on `knowledge/*.md`: size ≤ 28,000 bytes (`len(bytes)`); every `` `<file> §<x>` `` reference points to an existing heading; a markdown parser that skips fenced code blocks (O1 line ~166 and O2 §D5 have headings inside code). Output: one line per error, exit 1 on any error, exit 0 otherwise. Also `--self-test` running on fixtures in `tests/kb_check/` (one passing, one failing sample). It must pass on today's `knowledge/` (phase 0 only). If today's files break a phase-0 rule, report which and why; do not edit `knowledge/` to make it pass.
5. **`tools/test_hooks.sh`** skeleton: for each `tests/fixtures/<Event>-<case>.json`, runs the hook named in the fixture's `_hook` field with the JSON on stdin and asserts the exit code in `_expect_exit`. No hooks exist yet, so it runs zero cases and exits 0; `--list` prints the fixture names. Copy the payload shapes documented in `knowledge/FINDINGS-claudeexpert.md` (2026-10-11 entries: Read `tool_response`, Bash `tool_response` without trailing newline, SubagentStart/Stop keys) into `tests/fixtures/README.md` so S07 records real ones in the same shape.
6. **CI** `.github/workflows/kb-check.yml`: triggers `pull_request_target` and `push` to `main`; the job checks out `main` (the workflow's own ref) into the working directory and the PR head into `pr/` **as data** (`actions/checkout` with `ref: ${{ github.event.pull_request.head.sha }}`, `path: pr`, `persist-credentials: false`), runs `python3 tools/kb_check.py --root pr --tree HEAD` **from the `main` copy of the script**, then fails with a list if `git diff --name-only origin/main...<head>` touches `.claude/**` (except `.claude/worktrees/`), `.github/**`, `tools/kb_*`, `tools/test_hooks.sh`, `knowledge/topics.json`. `permissions: contents: read`. Never executes anything from `pr/`.
   - Launch **one research agent** (`model: "opus"`, `effort: "high"`, general-purpose) before writing the workflow: "Using only `curl -sL` on raw files of `https://raw.githubusercontent.com/github/docs/main/content/actions/...` (find the pages via `https://raw.githubusercontent.com/github/docs/main/content/actions/` listings or WebSearch `site:docs.github.com pull_request_target`), establish and quote: (a) which ref the workflow file is taken from on `pull_request_target`; (b) whether a required status check that never reports blocks the merge; (c) whether branch protection can include administrators. Write `docs/FINDINGS.md`-style entries with `[SOURCE: URL, date]` to `Warsztat/github-semantics.md`. If the network refuses docs.github.com or raw.githubusercontent.com, say so and stop." Use its result; if it could not verify, mark the CI design `[ASSUMPTION]` in `docs/FINDINGS.md` and in the reply.
   - Bootstrap caveat: this first PR cannot be checked by a `main` that has no checker. Say so in the reply; the owner reviews this PR by hand.
7. **Owner instructions** `docs/OWNER-SETUP.md` (Polish allowed; name it `RAPORT-ustawienia-wlasciciela.md`): where to click on GitHub to enable branch protection on `main` with the required check `kb-check` and "Include administrators"; how to undo it. Also the read-only check the session ran: `gh api repos/<owner>/<repo> --jq .permissions` (run it; record whether the session token has `admin`; if `gh` is absent, NOT RUN).
8. `docs/TESTS.md`, `MAPA.md` updated with every new file.

## Done when (paste last lines into the reply)
```
python3 tools/kb_check.py --phase 0 --tree HEAD ; echo exit=$?
python3 tools/kb_check.py --self-test ; echo exit=$?
bash tools/test_hooks.sh ; echo exit=$?
git status --short | wc -l   # 0 after commit
```
plus the CI run visible as green on this branch's PR (or, if the owner has not opened a PR, say NOT RUN).

## End of session
Two reviewers per COMMON §4 (KB files for them: the same list as "Read in full" above). Fix or reject. `STATUS.md` (Live mechanisms: "kb_check.py phase 0 in CI — pending the owner's branch protection"), `CHANGELOG.md`, `docs/FINDINGS.md` (the GitHub semantics entry, the token permissions), commit, push. Reply per COMMON §5; the next prompt is `docs/prompts/S01-migration.md`.
