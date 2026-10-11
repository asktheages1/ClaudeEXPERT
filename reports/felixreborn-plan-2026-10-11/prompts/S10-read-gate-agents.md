# S10 — Read gate for agents, log-only

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
An agent of a gated type whose task names a topic cannot finish (in `block` mode) until its own transcript shows a full read of the topic file; its prompt carries the reading instruction, added by a hook. Built and fixture-tested here, run in `log` mode until S12.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/agents-and-workflows.md`
- `.claude/hooks/` (every file), `knowledge/topics.json`, `docs/FINDINGS.md` (S07 entries on `updatedInput`, SubagentStop cap, project hooks in subagents)

## Work
1. **Gated agent types**: `settings.gated_agent_types` in `topics.json`: `["general-purpose"]` plus the project's own agents listed in `.claude/agents/` that have Read or Bash. Not gated: `Explore`, `Plan`, `claude-code-guide`, `statusline-setup`, any agent without Read and Bash.
2. **PreToolUse on `Agent`**: match `tool_input.prompt` (and `description`) with `kb_topics.py`; if matched and `subagent_type` is gated: copy the **whole** `tool_input` object, prefix `prompt` with `Read in full with the Read tool before anything else: <files>. Your SubagentStop is checked against the read log.`, return `updatedInput` with the form S07 measured (with or without `permissionDecision: "allow"`); log `{tool_use_id, required, agent_type}`. In `log` mode still inject the line (it is advice; harmless) but never deny.
3. **SubagentStop** (matcher = the gated types, regex `^(general-purpose|<names>)$`): read `agent_transcript_path`; take the first user message; re-match topics; required files = from the message (the injected line gives the exact list); check the gate log for rows with this `agent_id` and `full:true` after the agent's start; unmet → `block` mode exit 2 with reason naming the files; `log` mode record. Handle `stop_hook_active` as in S09; the cap measured in S07 goes into the code comment. If the transcript is missing or empty (async write), wait up to 2 s and retry once, then fail open with a logged warning.
4. Fixtures: matched/unmatched Agent call, gated/ungated type, SubagentStop met/unmet/missing transcript. `tools/test_hooks.sh` green.
5. Live tests (2 test agents, `model: "opus"`, `effort: "low"`, general-purpose, launched from a `/tmp/kbtest` `-p` run in `KBGATE_MODE=block`): A: "Explain which hook events can block; read nothing, answer from memory." → SubagentStop must block (n=2). B: same task with the injected line obeyed → passes (n=2). Assert with `jq` on the agent transcripts and the gate log. Also one Explore agent with a topic task → not gated, no block (n=1).
6. `.claude/agents/reviewer.md`: the read-only reviewer definition `CLAUDE.md` promises: `tools: Read, Grep, Glob`, `model: opus`, `effort: high`, `omitClaudeMd: false`; and `probe-omit.md` from S06 kept. Add both to `STATUS.md` Live mechanisms with "definition only; used from S11".
7. `docs/TESTS.md`, `MAPA.md`.

## Done when
```
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
jq -c 'select(.event=="subagent_stop_decision")' .claude/kbgate/*.jsonl | head -3
```
plus the live-test table (A/B/Explore, n, result, jq command).

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`, `knowledge/agents-and-workflows.md`; they read the two new hooks and the S07 findings they cite, and check that every assumption in the code has a FINDINGS entry). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push. Next prompt: `docs/prompts/S11-freshness.md`.
