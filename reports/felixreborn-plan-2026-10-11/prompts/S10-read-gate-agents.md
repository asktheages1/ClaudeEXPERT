# S10 — Read gate for agents, log-only

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
An agent of a gated type whose task names a topic cannot finish (in `block` mode) until its own transcript shows a full read of the topic file; its prompt carries the reading instruction, added by a hook. Built and fixture-tested here, run in `log` mode until S12a.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/agents-and-workflows.md`
- every file in `.claude/hooks/`, `knowledge/topics.json`
## Read in part (say so)
- `docs/FINDINGS.md`: S07 entries on `updatedInput`, the SubagentStop cap, project hooks in subagents.

## Work
1. **Gated types**: `settings.gated_agent_types` in `topics.json` (`general-purpose` plus the project's own agents in `.claude/agents/` that have Read or Bash; never `Explore`, `Plan`, `claude-code-guide`, `statusline-setup`, `reviewer` (no Bash, but it has Read: gate it only if the owner wants; default no), or any agent without Read and Bash). `kb_build.py` generates the SubagentStop matcher regex from this list (`^(general-purpose|…)$`), so the two never drift.
2. **PreToolUse on `Agent`** (`kb_agentgate.py`): match `tool_input.prompt` and `description`; if matched and the type is gated: copy the **whole** `tool_input` object and change only `prompt` (prefix: `Read in full with the Read tool before anything else: <files>. Your SubagentStop is checked against the read log.`); return `updatedInput` in the form S07 probe 2 measured (with or without `permissionDecision: "allow"`); log `{tool_use_id, required, agent_type}`. `KBGATE_AGENT_INJECT=0` disables the injection (used by the live test). In `log` mode the line is still injected; never deny.
3. **SubagentStop** (matcher generated): read `agent_transcript_path` (retry once after 2 s if missing or empty, then fail open with a logged warning: the write is asynchronous); first user message → required files (from the injected line, else by matching); check the gate log for rows with this `agent_id` and `full:true`; unmet → `block`: exit 2 naming the files; `log`: record. `stop_hook_active` handled as in S09; the cap S07 probe 4 measured in the code comment (if none applies to SubagentStop, cap at 8 in the script).
4. Fixtures: matched/unmatched Agent call; gated/ungated type; SubagentStop met / unmet / missing transcript. Harness green.
5. Live tests from the scratchpad worktree in `KBGATE_MODE=block`, `KBGATE_AGENT_INJECT=0` (so the agent is not told to read): A: a general-purpose agent, `model: "opus"`, `effort: "low"`, task "Explain which hook events can block; answer from memory, read nothing." → SubagentStop decision `block` (n=2). B: same with `KBGATE_AGENT_INJECT=1` → the agent reads, passes (n=2). C: an Explore agent with a topic task → not gated (n=1). Assert with `jq -e` on the agent transcripts and the worktree gate log. These agents run inside nested `-p` and count toward the cap: 5 + 2 reviewers = 7.
6. `docs/TESTS.md`, `MAPA.md`; `STATUS.md` Live mechanisms: "read gate (agents): log-only since S10, cloud only". Copy the gate logs.

## Done when
```
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
jq -e 'select(.event=="subagent_stop_decision")' "$SCRATCH/kbtest/.claude/kbgate/"*.jsonl | head -1
```
plus the live-test table (A/B/C, n, result, jq command).

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`, `knowledge/agents-and-workflows.md`; they read the two new hooks and the S07 findings they cite and check that every assumption in the code has a FINDINGS entry). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push, tag. Next prompt: `docs/prompts/S11-freshness.md`.
