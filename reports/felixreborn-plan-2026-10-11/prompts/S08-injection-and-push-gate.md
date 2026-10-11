# S08 — First live hooks: map injection, agent rules, push gate, read logger (no read gate yet)

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Four hooks go live from `.claude/settings.json`, each proven by `tools/test_hooks.sh` on recorded fixtures and by one live run: SessionStart (map + state), SubagentStart (agent rules + map into every subagent), PreToolUse push gate (narrow, fail-closed; broad, fail-open), and a PostToolUse read logger that records every read of a `knowledge/` file **without blocking anything**. The logger starts the baseline measurement the owner's complaint needs.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/permissions-settings-automode.md`
- `Warsztat/probes/RESULTS.md`, `docs/FINDINGS.md` (S07 entries)
- `tests/fixtures/README.md`

## Rules for every hook in this project
- Scripts live in `.claude/hooks/`, POSIX sh + `python3` (+ `jq` allowed); first line of logic: `[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0` (the owner's PC has no `python3`; a PC-safe variant is a later task in `docs/BACKLOG.md`).
- State in `${CLAUDE_PROJECT_DIR}/.claude/kbgate/` (gitignored), one JSONL per `transcript_path` hash (not `session_id`: a nested `-p` inherits it), single-line `O_APPEND` writes.
- `KBGATE_MODE` env var: `off` (every hook exits 0 at once), `log` (record, never block), `block` (enforce). Default when unset: `log`. The owner sets `off` in the cloud environment variables as the kill switch.
- Nothing network-bound in SessionStart this session (freshness comes in S11).
- Every hook has ≥ 2 fixtures in `tests/fixtures/` and an entry in `docs/TESTS.md`.
- `.claude/settings.json` is a protected path for the auto-mode classifier and under an `ask` rule per `CLAUDE.md`: if the edit is refused, keep it in the branch and tell the owner (per `CLAUDE.md` "Git"); never work around it.

## Work
1. **SessionStart** (`startup`, `resume`, `compact`): prints the hand-written part of `knowledge/CLAUDE.md` (the map) and the top 20 lines of `STATUS.md`, plus `version`, branch vs `origin/main` (`git fetch` is allowed here, with `--max-time` equivalent: `timeout 10 git fetch origin main`), and "health check due" when `Last review` is older than 90 days. Total output ≤ 9,500 characters (S07 probe 11 decides the real cap; apply it). On `compact` print only the map.
2. **SubagentStart** (matcher `*`): returns `hookSpecificOutput.additionalContext` = `.claude/agent-rules.md` (write it: the agent-relevant rules from `CLAUDE.md` "Agents and nested runs", ≤ 3,000 characters) + the map. Measured to reach Explore (findings 2026-10-11, n=2); re-check with one live run that greps the subagent transcript for a marker.
3. **Push gate**: handler (a) `PreToolUse`, matcher `Bash`, `if: "Bash(git push *)"`, `onFailure: "block"`, runs `python3 tools/kb_check.py --tree HEAD` and `bash tools/test_hooks.sh`; non-zero → exit 2 with the error list on stderr. Handler (b) `PreToolUse`, matcher `Bash`, no `if`, no `onFailure`: regex `\bgit\b.*\bpush\b` on `tool_input.command`; same checks; fail-open on its own error (log to `.claude/kbgate/errors.log`). Both skip when `KBGATE_MODE=off`.
4. **Read logger** `PostToolUse`, matcher `Read|Bash`: appends `{ts, prompt_id, agent_id?, path (repo-relative, worktree-normalised), full: bool, sha256(file), source: "read"|"cat"}` for every `knowledge/*.md` touched. `full` rule: Read → `tool_response.type == "text" && file.startLine == 1 && file.numLines >= file.totalLines`; `file_unchanged` → `full` only if a full read of that path is already logged after the last `PostCompact` marker; Bash → command matches `^\s*cat\s+(\S+)\s*$`, path resolved against the payload `cwd`, no `persistedOutputPath`, `interrupted == false`, `stdout.rstrip("\n") == file_text.rstrip("\n")` as UTF-8 text. **PostCompact** hook appends a `{compact: true}` marker. No blocking in this session.
5. **Stop advisory**: if `git status --porcelain knowledge/` is non-empty, `systemMessage`: "knowledge/ has uncommitted changes; run tools/kb_check.py --worktree before pushing". Exit 0 always.
6. `tools/test_hooks.sh`: now runs every fixture; add fixtures for each hook from S07 payloads (a push with a broken header → exit 2; `git -C . push` → handler (b) catches; a full Read; a truncated `cat` with `persistedOutputPath` → `full:false`; a `cat` with trailing newline → `full:true`).
7. Live tests from `/tmp/kbtest` (worktree, `--settings` pointing at the repo's `.claude/settings.json` copy): (i) push with a deliberately broken header in a scratch file → blocked, stderr names the error (n=2); (ii) an Explore subagent run → transcript has `hook_additional_context` with the marker (n=2); (iii) `cat` of a 27 KB and a 31 KB KB file → logger rows `full:true` / `full:false` (n=2 each). Verify with `jq` on the JSON output and on `.claude/kbgate/*.jsonl`.
8. `docs/TESTS.md`, `MAPA.md`, `CLAUDE.md` proposed diff: the SubagentStart sentence changes from conditional to measured (write to `Warsztat/CLAUDE.md.proposed.diff`).

## Done when
```
bash tools/test_hooks.sh ; echo exit=$?            # all fixtures, 0
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
jq -s 'length' .claude/kbgate/*.jsonl                # ≥ 1 row from the live tests
```
plus the three live-test results in the reply with their `jq` commands.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`; they read every file in `.claude/hooks/` and run `tools/test_hooks.sh` themselves). Fix or reject. `STATUS.md` (Live mechanisms: list the four hooks with "fixtures + live n=2"; "read gate: log-only"), `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push. Next prompt: `docs/prompts/S09-read-gate-main.md`.
