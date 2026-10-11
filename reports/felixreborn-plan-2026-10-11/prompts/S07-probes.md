# S07 — Probes before any gate: measure what the hooks will rely on, record fixtures

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Every premise of the read gates and the push gate is measured here (n ≥ 2), the real hook payloads are recorded as fixtures, and nothing is built on an assumption. No hooks are installed in the repository in this session.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md` (all of it: events, inputs, exit codes, the measured bullets promoted in S04)
- `knowledge/context-window-and-read.md` (Read limits, compaction restoration, `cat` truncation)
- `tests/fixtures/README.md`

## Method
All probes are nested `claude -p` runs from a worktree: `git worktree add /tmp/kbtest HEAD`, `cd /tmp/kbtest`, each run `--model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns 6 --max-budget-usd 0.5 --output-format json --settings Warsztat/probes/<probe>.json`, where the settings file holds only the hooks needed for that probe, each hook being `tee`-style: `cat > tests/fixtures/<Event>-<case>-<n>.json` plus the exit code under test. Read results from the JSON output and the transcript with `jq`, never from the model's words. Every probe runs twice; a disagreement between runs is reported, not averaged. Record each result in `docs/FINDINGS.md` as `[MEASURED: command → result, date, CC version, model, n]`.

## Probes (one subsection each in `Warsztat/probes/RESULTS.md`)
1. **Read after compaction**: read a 12 KB file, force `/compact` (`claude -p` with a prompt that includes `/compact` then a second question, or two turns via `--resume`), read again: does the second Read return `file_unchanged` (bad: the gate would accept a stub with no content) or content?
2. **`updatedInput` on Agent**: a PreToolUse hook on `Agent` that returns `hookSpecificOutput.updatedInput` with the prompt prefixed; does the subagent's first message contain the prefix? Does it need `permissionDecision: "allow"`? Does the auto classifier still evaluate the task (compare a run in `--permission-mode auto` if available in `-p`)?
3. **SubagentStop for workflow agents**: a tiny Workflow with one agent; does `SubagentStop` fire with `agent_transcript_path`? If the Workflow tool is unavailable in `-p`, NOT RUN.
4. **Block cap on SubagentStop**: a SubagentStop hook that always exits 2 on an agent that only answers text; count how many blocks before Claude Code overrides (Stop documents 8).
5. **Project-settings hooks inside subagents**: the same logger placed in `/tmp/kbtest/.claude/settings.json` (not `--settings`); does the subagent's Read fire it?
6. **ConfigChange**: a hook that exits 2 on `project_settings`; edit `.claude/settings.json` in the run; is the change applied?
7. **PostCompact on auto-compaction**: fill the context to the threshold with a large file in a worktree with `CLAUDE_CODE_AUTO_COMPACT_WINDOW` lowered; does `PostCompact` fire and what does its payload hold?
8. **`ask` rules vs `git rm` / `git mv`** on a gate file: a `permissions.ask` rule on `Edit(/.claude/hooks/**)`; does `git mv .claude/hooks/x .claude/hooks/y` prompt (in `-p` with `--permission-mode default` the run should end on the pending prompt or deny)?
9. **stdout fidelity**: `cat` of a 27,900-byte file with Polish letters and three trailing newlines; compare `tool_response.stdout` with the file after `rstrip("\n")`; also a 31,000-byte file (expect `persistedOutputPath`).
10. **`effortLevel` in project `.claude/settings.json`**: set `effortLevel: "high"` and run without `--effort`; read the effort field from the transcript.
11. **`additionalContext` size**: a SessionStart hook printing 9,500 and then 10,500 characters; what reaches the context (full vs 2 KB preview)?

## Fixtures
Every recorded payload goes to `tests/fixtures/<Event>-<case>.json` with `_hook` and `_expect_exit` fields added by hand per `tests/fixtures/README.md`; `bash tools/test_hooks.sh --list` must show them. Remove absolute paths that leak the VM layout only if they are not the thing under test.

## Done when
```
ls tests/fixtures/*.json | wc -l      # ≥ 15
bash tools/test_hooks.sh ; echo exit=$?   # 0 (no hooks yet → 0 cases run, listed)
grep -c "MEASURED" docs/FINDINGS.md     # increased by ≥ 11
```
`Warsztat/probes/RESULTS.md` has a row per probe with n, both results and the fixture names; NOT RUN rows say why.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`; they re-run two probes of their choice from the same settings files and compare). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push (fixtures included). Next prompt: `docs/prompts/S08-injection-and-push-gate.md`.
