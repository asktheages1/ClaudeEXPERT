# S12 — Analyse the logs, switch the read gates to block, measure re-reading, lock the gate files with `ask`

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Decide from data, not opinion, whether the read gates earn their cost; switch them to `block`; settle the one open design question (does a forced re-read between compactions help?) with an A/B probe; and put the gate files under `ask` rules so an honest change needs the owner's yes in the session.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/permissions-settings-automode.md`, `knowledge/prompting-and-model-weaknesses.md`
- `docs/reviews/baseline-S08.md`, `docs/FINDINGS.md` (S07–S11 entries)
- `.claude/kbgate/` is per-VM and gone: the sessions S09–S11 each **committed** their gate logs to `docs/gatelogs/<Sxx>.jsonl` at the end (if a session did not, say so and use what exists)

## Work
1. **Log analysis** `docs/reviews/gate-analysis.md`: over S09–S11 logs: prompts that matched a topic; of those, how many had a full read before the first assistant message (baseline); how many Stop decisions would have blocked; how many PreToolUse decisions would have blocked and which tools; false positives (a block decision where the reviewer of that session found the answer correct without the read; cross-check with the session reviews); files required most often; estimated token overhead per gated prompt (file bytes / 2.7 [ASSUMPTION], sum). Numbers with n. If n < 10 matched prompts in total, say the data is thin and still proceed (the owner asked for block mode; the data decides tuning, not existence).
2. **Tune** `topics.json` from the analysis: stems that never matched, phrases that matched wrongly, `carry_over_prompts`, `max_required_per_prompt`. Re-run `tests/topics/phrases.tsv`.
3. **A/B probe on re-reading** (6 agents, `model: "opus"`, `effort: "high"`, general-purpose, one message): all get the same scripted conversation (a prepared transcript-like prompt: a full read of `hooks.md` is simulated by including its text at the top, then 6 unrelated short tasks, then a precise question whose answer is one line in `hooks.md`, e.g. which events accept `type: "prompt"`). Arm A (3 agents): the question is preceded by "Before answering, `cat knowledge/hooks.md` again." Arm B (3 agents): no re-read instruction. You grade each answer against the file (exact/partial/wrong). Record in `docs/FINDINGS.md` `[MEASURED …, n=3 per arm]` and decide: if arm A is better by ≥ 2 of 3, add a `reread_after_prompts` setting (default 6) to the Stop gate; otherwise leave "one full read per compaction epoch" and write the measured reason.
4. **Switch to block**: `KBGATE_MODE` default in the hooks changes from `log` to `block` (the env var still overrides). Live tests from `/tmp/kbtest` repeat S09 (i)–(iii) and S10 A/B with the repository's own settings file (n=2 each).
5. **Lock with `ask`** in `.claude/settings.json` `permissions.ask`: `Edit(/.claude/hooks/**)`, `Edit(/.claude/settings.json)`, `Edit(/.claude/settings.local.json)`, `Edit(/.claude/agent-rules.md)`, `Edit(/tools/kb_*)`, `Edit(/tools/test_hooks.sh)`, `Edit(/.github/workflows/**)`, `Edit(/knowledge/topics.json)`; never `Edit(/.claude/**)` (agent worktrees). Add a **ConfigChange** hook on `project_settings|local_settings` that, in `block` mode, exits 2 with "settings changed mid-session: restart or get the owner's yes" (semantics per S07 probe 6). Verify the `ask` rule on a dummy file in the session's permission mode (the `<verify …>` note in `CLAUDE.md` line 19) and record it.
6. `.claude/settings.json` deny list: GitHub MCP write tools by bare name (`mcp__github__push_files`, `create_or_update_file`, `delete_file`, `merge_pull_request`, `enable_pr_auto_merge`, `update_pull_request_branch`, `create_branch`, `actions_run_trigger`) — `CLAUDE.md` already promises "write through git only"; make it true.
7. `tools/export_template.py` (first version): copies `CLAUDE.md`, `.claude/`, `tools/kb_*`, `tools/test_hooks.sh`, `tests/`, `knowledge/` (or only `design-rules.md` + `knowledge/CLAUDE.md` with `--kb minimal`, per the owner's decision in `STATUS.md`) into `Gotowe/`; CI runs it and fails on a diff. `Gotowe/` is never edited by hand.
8. `docs/TESTS.md`, `MAPA.md`, `STATUS.md` Live mechanisms: "read gates: block mode since S12 (main + agents)", "ask rules on gate files", "GitHub MCP write tools denied", "Gotowe/ generated".

## Done when
```
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
python3 tools/export_template.py && git diff --quiet -- Gotowe/ ; echo exit=$?
grep -c '"ask"' .claude/settings.json
```
plus the live-test table (S09 i–iii, S10 A/B, n=2) and the A/B result in the reply.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`, `knowledge/permissions-settings-automode.md`; they read `docs/reviews/gate-analysis.md` and check every number against the logs, and they try one prompt each that the tuned `topics.json` should catch). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push. Next prompt: `docs/prompts/S13-claude-md.md`.
