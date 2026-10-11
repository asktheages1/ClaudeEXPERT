# S08 — First live hooks: map injection, agent rules, push gate, read logger, session-protocol check (no read gate yet)

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Six hooks go live from `.claude/settings.json`, each proven by `tools/test_hooks.sh` on recorded fixtures and by live runs: SessionStart (map + state), SubagentStart (agent rules + map), the PreToolUse push gate (narrow, fail-closed; broad, fail-open), a PostToolUse read logger plus a UserPromptSubmit topic logger that record **without blocking**, and a Stop session-protocol check in log mode. The loggers start the baseline the owner's complaint needs.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/permissions-settings-automode.md`
- `Warsztat/probes/RESULTS.md`, `tests/fixtures/README.md`
## Read in part (say so)
- `docs/FINDINGS.md`: the S07 entries.

## Rules for every hook in this project
- Scripts in `.claude/hooks/` with fixed names: `kb_sessionstart.sh`, `kb_subagentstart.sh`, `kb_pushgate_narrow.sh`, `kb_pushgate_broad.sh`, `kb_readlog.py`, `kb_promptlog.py`, `kb_postcompact.sh`, `kb_stop_protocol.py`. Commands in settings use `${CLAUDE_PROJECT_DIR}/.claude/hooks/<name>` (absolute: `cwd` follows `cd`). POSIX sh + `python3` (+ `jq`); first line of logic: `[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0` (cloud only; the PC variant is in BACKLOG; say "cloud only" in STATUS).
- `KBGATE_TESTING=1` (set by the harness): a gate never calls the harness or the checker recursively.
- `KBGATE_MODE`: `off` (every hook exits 0 at once), `log` (record, never block), `block`. Default unset = `log`. **The push gate honours only `off`**: it blocks in `log` too (it is the one gate meant to be hard from S08). The owner sets `off` in the cloud environment variables as the kill switch.
- State: `${CLAUDE_PROJECT_DIR}/.claude/kbgate/<sha of transcript_path>.jsonl`, single-line `O_APPEND`; paths repo-relative and worktree-normalised; `Gotowe/` paths excluded.
- Every hook: ≥ 2 fixtures, an entry in `docs/TESTS.md`. `.claude/settings.json` is classifier-protected and under an `ask` rule from the skeleton: write it as the **last** edit before the reviewers; on refusal, per COMMON §3 (`Warsztat/proposed/.claude/settings.json`, tests via `--settings`).

## Work
1. **SessionStart** (`startup`, `resume`, `compact`): prints the generated section of `knowledge/CLAUDE.md` (between the markers), `version`, branch vs `origin/main` (`timeout 10 git fetch origin main`), the top 20 lines of `STATUS.md`, "health check due" when `Last review` > 90 days; `compact`: the generated section only. Total ≤ the cap S07 probe 11 measured (≤ 9,500 if it measured 10,000).
2. **`.claude/agent-rules.md`** (≤ 3,000 characters: the skeleton's "Agents and nested runs" rules relevant to a subagent, plus COMMON §1 in two sentences) and **SubagentStart** (matcher `*`): `hookSpecificOutput.additionalContext` = `agent-rules.md` + the generated map lines; combined ≤ 9,500 characters, enforced by `kb_check.py --phase 2` (the S06 check now has its input).
3. **Push gate**: (a) `PreToolUse`, matcher `Bash`, `if: "Bash(git push *)"`, `onFailure: "block"` → `python3 ${CLAUDE_PROJECT_DIR}/tools/kb_check.py --tree HEAD` and `KBGATE_TESTING=1 bash ${CLAUDE_PROJECT_DIR}/tools/test_hooks.sh`; non-zero → exit 2 with the error list on stderr. (b) `PreToolUse`, matcher `Bash`, no `if`, no `onFailure`: regex `\bgit\b.*\bpush\b`; same checks; fail-open on its own error (`.claude/kbgate/errors.log`). Scope per the owner's decision in `STATUS.md` (block every failing push, or only pushes whose refspec targets `main` with others warned); default until decided: block every failing push **except** refs named `wip/*`, which get a warning (so half-done work can always leave a disposable VM).
4. **Read logger** `PostToolUse`, matcher `Read|Bash`: `{ts, prompt_id, agent_id?, path, full, sha256, source}` for every `knowledge/*.md`; `full` via the function in `tools/verify_reads.py` (Read fields; exact `cat`; `stdout.rstrip("\n") == file_text.rstrip("\n")`; `file_unchanged` only after a FULL since the last PostCompact marker). **PostCompact**: appends `{compact: true}`. **Prompt logger** `UserPromptSubmit`: `{ts, prompt_id, source: user|automatic, topics matched via kb_topics.py, required files}` — logs only; no stdout.
5. **Stop session-protocol check** (log mode): records whether `docs/reviews/<Sxx>-fable.md` and `-opus.md` exist for the session named in `STATUS.md` "Last session", whether `STATUS.md` differs from `origin/main`, whether there are unpushed commits; `hookSpecificOutput.additionalContext` with the missing items (to Claude) and `systemMessage` (to the owner); exit 0 (block mode arrives in S12b). Also the dirty-`knowledge/` advisory from the plan.
6. `tools/test_hooks.sh`: fixtures for every hook and branch from S07 payloads (push with a broken header in a `knowledge/*.md` copy → exit 2; `git -C . push` → handler (b) catches; full Read; truncated `cat` with `persistedOutputPath` → `full:false`; `cat` with trailing newline → `full:true`; `file_unchanged` before/after a FULL; Stop protocol with/without reviews).
7. Live tests from the scratchpad worktree with `--settings <absolute path to the repository's .claude/settings.json or the Warsztat copy>`: (i) a push of a tree with a broken header in `knowledge/hooks.md` to a **local bare remote** (`git init --bare "$SCRATCH/remote.git"`; never GitHub: the cloud cannot delete branches) → blocked, stderr names the error (n=2); (ii) an Explore subagent run → its transcript has `hook_additional_context` with a marker (n=2); (iii) `cat` of a 27 KB and a 31 KB base file → logger rows `full:true` / `full:false` (n=2 each). Assert with `jq -e` on the JSON output and on the **worktree's** `.claude/kbgate/*.jsonl`, filtered by the test run's `transcript_path`.
8. `docs/TESTS.md`, `MAPA.md`; `Warsztat/proposed/CLAUDE.md.S08.diff`: the skeleton's conditional "If a SubagentStart hook injects `.claude/agent-rules.md`" becomes measured. Copy the gate logs per COMMON §3.

## Done when
```
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?          # phase from phase.txt (2)
jq -e 'select(.event=="read") | .full' "$SCRATCH/kbtest/.claude/kbgate/"*.jsonl | head -1   # live test rows exist
```
plus the three live-test results in the reply with their `jq` commands.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`; they read every file in `.claude/hooks/` and run `tools/test_hooks.sh`). Fix or reject. `STATUS.md` (Live mechanisms: the six hooks, "fixtures + live n=2", "cloud only"; "read gate: not built; loggers only"), `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push, tag. Next prompt: `docs/prompts/S09-read-gate-main.md`. From now on the gate logs of every session are evidence: later sessions also commit them.
