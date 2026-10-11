# S09 — Read gate for the main session, built in log-only mode

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
The chain that forces the main session to read the topic file before answering exists, is fixture-tested, and runs in `KBGATE_MODE=log`: it records every decision it *would* have taken (block / allow, which files, why) without blocking. Blocking is switched on in S12 after the logs from S09–S11 are analysed.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/context-window-and-read.md`
- `knowledge/topics.json`, `tools/kb_topics.py`
- `.claude/hooks/` (every file), `docs/FINDINGS.md` (S07, S08 entries)

## Work
1. **UserPromptSubmit**: match the prompt with `kb_topics.py`; write `{prompt_id, required: [≤3 files], topics}` to the gate state; on stdout (goes to context): `Required reading for this prompt: <files> — Read tool in full, or exactly "cat <path>" for files under 28 KB. Other tools stay blocked until the log shows the read (mode: <KBGATE_MODE>).` Nothing when no topic matches. Timeout budget 30 s (keep the matcher under 1 s; no network).
2. **PreToolUse "read first"** (matcher `*`): if the current `prompt_id` has unmet required files, deny (exit 2 in `block` mode; log in `log` mode) every tool except: `Read` of a required file, `Bash` whose command is exactly `cat <required path>`, `Bash` matching `^\s*git (add|commit|push)\b`, and any event carrying `agent_id`. A required file that does not exist → allow and log a warning. The hook fails open on its own error and logs it.
3. **Stop**: re-match topics on `last_assistant_message` as well; required = union over the current prompt and the previous `carry_over_prompts` prompts (from `topics.json`), capped by `max_required_per_prompt` and by a per-session ceiling (`settings.max_required_per_session`, default 8); unmet after the last compaction → in `block` mode exit 2 with reason `Re-check your previous answer against <file> (read it in full) and state corrections.`; in `log` mode record the decision. Never exit early on `stop_hook_active`; log every time the 8-block cap would be hit (count blocks per `prompt_id`).
4. **PostCompact**: already appends the marker (S08); the matcher and the Stop hook treat reads before the marker as void.
5. The S07 result on Read-after-compaction decides one rule: if `file_unchanged` comes back after compaction, the logger must *not* count it as full (the content is not in context); implement whichever branch S07 measured and cite the FINDINGS entry in the code comment.
6. Fixtures for every branch (matched / unmatched prompt, met / unmet at PreToolUse, agent_id exemption, git exemption, missing file, Stop with carry-over, Stop after compaction). `tools/test_hooks.sh` green.
7. Live tests from `/tmp/kbtest` in `KBGATE_MODE=block` via `--settings` (the repository itself stays in `log`): (i) a prompt about hooks, answer without reading → PreToolUse denies an Edit and Stop blocks naming `hooks.md` (n=2); (ii) same prompt after a full Read → no block (n=2); (iii) read, then a forced compaction, then a follow-up → Stop requires the read again (n=2; if S07 could not force compaction, NOT RUN and say so). Assert with `jq` on the JSON output and the gate log.
8. **Baseline report** `docs/reviews/baseline-S08.md` from the S08 logger rows (this session's own rows excluded): per prompt that matched a topic, did a full read of the required file happen before the first assistant message? Numbers with n. This is the first measurement of the owner's complaint; say plainly how small n is.
9. `docs/TESTS.md`, `MAPA.md`, `STATUS.md` Live mechanisms: "read gate (main): log-only since S09".

## Done when
```
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
jq -c 'select(.event=="stop_decision")' .claude/kbgate/*.jsonl | head -3    # decisions are being logged
```
plus the live-test results with `jq` commands.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`; they read all of `.claude/hooks/` and try to construct a prompt that should be gated but is not, and one that is gated but should not be; each such case is a finding with the phrase). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push. Next prompt: `docs/prompts/S10-read-gate-agents.md`.
