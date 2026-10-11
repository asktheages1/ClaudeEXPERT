# S09 — Read gate for the main session, built in log-only mode

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
The chain that forces the main session to read the topic file before answering exists, is fixture-tested, and runs in `KBGATE_MODE=log`: it records every decision it *would* take (block / allow, which files, why) without blocking. Blocking is switched on in S12a after the logs from S09–S11 (and, if the owner agreed, two ordinary Q&A sessions) are analysed.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/context-window-and-read.md`
- `knowledge/topics.json`, `tools/kb_topics.py`, every file in `.claude/hooks/`
## Read in part (say so)
- `docs/FINDINGS.md`: S07 and S08 entries.

## Work
1. **UserPromptSubmit** (extends `kb_promptlog.py`): match the prompt; write `{prompt_id, required: [≤ max_required_per_prompt], topics, source}`; automatic turns (background agent reports, `/loop`) are logged with `source: automatic` and **do not** arm the gate unless `settings.gate_automatic_turns` is true (default false; add it to `topics.json`). Stdout (to context) on a user turn that matched: `Required reading for this prompt: <files> — Read tool in full, or exactly "cat <path>" for files under 28 KB. Other tools are blocked until the log shows the read (mode: <KBGATE_MODE>).` Keep the matcher under 1 s.
2. **PreToolUse "read first"** (matcher `*`, new `kb_readfirst.py`): with unmet required files for the current `prompt_id`: deny (exit 2 in `block`; log in `log`) every tool except `Read` of a required file, `Bash` whose command is exactly `cat <required path>`, `Bash` matching `^\s*git (add|commit|push|status|diff)\b`, and any event carrying `agent_id`. A required file that does not exist → allow with a logged warning. Fails open on its own error, logged.
3. **Stop** (new `kb_stop_readgate.py`, separate from the protocol hook): re-match topics on `last_assistant_message`; required = union over the current and the previous `carry_over_prompts` user prompts, capped by `max_required_per_prompt` and `max_required_per_session`; unmet after the last compaction → `block`: exit 2 with `Re-check your previous answer against <file> (read it in full) and state corrections.`; `log`: record. Never exit early on `stop_hook_active` (a deliberate departure from the KB's example; cite S07 probe 4 in the code comment); count blocks per `prompt_id`; ≥ 3 for one prompt is logged as a tuning signal.
4. **PostCompact**: the marker exists (S08); the S07 probe-1 result decides whether `file_unchanged` after compaction counts: implement the measured branch and cite the FINDINGS entry in the code.
5. Fixtures for every branch (matched / unmatched prompt; automatic turn; met / unmet at PreToolUse; `agent_id` and git exemptions; missing file; Stop with carry-over; Stop after compaction). Harness green.
6. Live tests from the scratchpad worktree in `KBGATE_MODE=block` via `--settings` (the repository stays in `log`): (i) a prompt about hooks that asks for an Edit of a scratch file, no read → PreToolUse denies the Edit and Stop blocks naming `hooks.md` (n=2); (ii) same after a full Read → no block (n=2); (iii) read, forced compaction (`--input-format stream-json`, as in S07 probe 1), follow-up → Stop requires the read again (n=2; NOT RUN if S07 could not force compaction). Assert with `jq -e` on the JSON output and the worktree gate log.
7. **Baseline report** `docs/reviews/baseline-S08.md` from `docs/gatelogs/S08/`: per user prompt that matched a topic, did a FULL read of a required file happen before the first assistant message? Numbers with n; say that the population is a build session.
8. `docs/TESTS.md`, `MAPA.md`; `STATUS.md` Live mechanisms: "read gate (main): log-only since S09, cloud only". Copy the gate logs per COMMON §3.

## Done when
```
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
jq -e 'select(.event=="stop_decision")' .claude/kbgate/*.jsonl | head -1    # decisions are logged (exit 0 only if a row exists)
```
plus the live-test results with `jq` commands.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`; they read all of `.claude/hooks/` and try to construct one prompt that should be gated but is not, and one that is gated but should not be; each is a finding with the phrase). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push, tag. Next prompt: `docs/prompts/S10-read-gate-agents.md`.
