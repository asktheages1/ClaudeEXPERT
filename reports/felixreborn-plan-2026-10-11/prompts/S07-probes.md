# S07 — Probes before any gate: measure what the hooks will rely on, record fixtures

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Every premise of the read gates and the push gate is measured here (n ≥ 2), the real hook payloads are recorded as fixtures, and nothing is built on an assumption. No hooks are installed in the repository in this session.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/context-window-and-read.md`
- `tests/fixtures/README.md`
## Read in part (say so)
- `knowledge/headless-sdk-ci.md`: the CLI-flags section (`--input-format stream-json`, `--allowedTools`, `--permission-prompts`, `--agents`).

## Method
All probes are nested `claude -p` runs from a detached worktree in the scratchpad (COMMON §2), each `--model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns 6 --max-budget-usd 0.5 --output-format json --settings <absolute path>/Warsztat/probes/<probe>.json`; the settings file holds only the hooks that probe needs, each hook being `tee`-style: `cat > <absolute path>/tests/fixtures/<Event>-<case>-<n>.json` plus the exit code under test. Bash calls that run a probe get `timeout` 300 s or run in the background. Read results from the JSON output and the JSONL transcript with `jq`, never from the model's words. Every probe runs twice; a disagreement between runs is reported, not averaged. Each result → `docs/FINDINGS.md` as `[MEASURED: command → result, date, CC version, model, n]`, and a row in `Warsztat/probes/RESULTS.md` (probe, n, result 1, result 2, fixtures, or NOT RUN with the reason).

## Probes
1. **Read after compaction**, one process: `--input-format stream-json` with three turns (Read a 12 KB file; `/compact`; Read again): does the second Read return `file_unchanged` (bad: a gate would accept a stub with no content) or content? If `/compact` is not honoured in `-p`, NOT RUN with the evidence.
2. **`updatedInput` on Agent**: a PreToolUse hook on `Agent` returning `hookSpecificOutput.updatedInput` with the prompt prefixed; does the subagent's first message contain the prefix? Does it need `permissionDecision: "allow"`? Does the auto classifier still evaluate the task (`--permission-mode auto` if available in `-p`)?
3. **SubagentStop for workflow agents**: `--allowedTools Workflow` and a prompt that calls the Workflow tool with one `agent()`; does `SubagentStop` fire with `agent_transcript_path`?
4. **Block cap on SubagentStop**: a SubagentStop hook that always exits 2 on an agent that only answers text; `--max-turns 20 --max-budget-usd 1.5` for this probe; count blocks before Claude Code overrides (Stop documents 8).
5. **Project-settings hooks inside subagents**: the same logger in the worktree's own `.claude/settings.json` (not `--settings`); does the subagent's Read fire it?
6. **ConfigChange**: a hook that exits 2 on `project_settings`; the run edits `.claude/settings.json`; is the change applied? What does "block" mean here?
7. **PostCompact on auto-compaction**: `CLAUDE_CODE_AUTO_COMPACT_WINDOW` lowered in the worktree run, context filled with a large file; does `PostCompact` fire and what does its payload hold?
8. **`ask` rules vs `git mv`** on a gate file: `permissions.ask` on `Edit(/.claude/hooks/**)`, `--permission-mode default --permission-prompts none`; does `git mv .claude/hooks/x .claude/hooks/y` appear in `permission_denials` of the JSON result?
9. **stdout fidelity**: `cat` of a 27,900-byte file with Polish letters and three trailing newlines → `tool_response.stdout` vs the file after `rstrip("\n")`; and a 31,000-byte file (expect `persistedOutputPath`).
10. **`effortLevel` in project `.claude/settings.json`**: `effortLevel: "high"`, run without `--effort`; read the effort field from the transcript.
11. **`additionalContext` size**: a SessionStart hook printing 9,500 and then 10,500 characters; what reaches the context (full vs 2 KB preview)?

## Fixtures
Recorded payloads are copied from the worktree into the repository's `tests/fixtures/<Event>-<case>.json` with `_hook` and `_expect_exit` added per `tests/fixtures/README.md`; keep `cwd` and paths as recorded (the logger's path resolution is tested against them). `bash tools/test_hooks.sh --list` shows them.

## Done when
```
python3 tools/probe_results_check.py Warsztat/probes/RESULTS.md ; echo exit=$?   # 11 rows; each n≥2 with both results and existing fixtures, or NOT RUN with a reason; committed this session
bash tools/test_hooks.sh ; echo exit=$?   # 0 (no hooks yet → cases listed, none run)
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`; they re-run two probes of their choice from the same settings files and compare). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit (fixtures included), push, tag. Next prompt: `docs/prompts/S08-injection-and-push-gate.md`.
