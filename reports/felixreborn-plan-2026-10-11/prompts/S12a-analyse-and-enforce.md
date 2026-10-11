# S12a — Analyse the gate logs, tune, switch the read gates to block

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Decide from data what to tune, then switch both read gates to `block`. No locks, no settings-permission changes in this session (S12b). The building session itself runs with `KBGATE_MODE=log` in its environment until the final settings edit, which is the last action before the reviewers.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/hooks.md`, `knowledge/prompting-and-model-weaknesses.md`
- `docs/reviews/baseline-S08.md`, every file in `.claude/hooks/`, `knowledge/topics.json`
## Read in part (say so)
- `docs/gatelogs/*/` (JSONL; read via the analysis script, not by eye); `docs/FINDINGS.md` S07–S11 entries.

## Work
1. **Log analysis** `tools/gate_analysis.py docs/gatelogs/ > docs/reviews/gate-analysis.md`: over all committed logs (S08–S11 and any baseline Q&A sessions): user prompts that matched a topic; of those, FULL read of a required file before the first assistant message (baseline rate); Stop decisions that would have blocked; PreToolUse decisions that would have blocked, by tool; **false positives defined operationally**: a block decision on a prompt whose required file had a FULL read after the last compaction (a logger or matcher miss), nothing else; most-required files; token overhead per gated prompt = file bytes / 2.7 `[ASSUMPTION]`; blocks per prompt ≥ 3. Numbers with n and the population named (build sessions vs Q&A). Thin data is reported as thin; the owner asked for block mode, so the data decides tuning, not existence.
2. **Tune** `topics.json`: stems that never matched, false positives, `carry_over_prompts`, `max_required_per_prompt`, `gate_automatic_turns`; `phrases.tsv` extended with the real prompts that misfired; `kb_check.py --phase 2` green.
3. **Re-reading between compactions**: the question "does a forced `cat` re-read after N prompts improve answers" stays **open** (the reviewers showed a short-prompt A/B cannot detect context rot; a real test needs ≥ 150k tokens of intervening work and n ≥ 5 per arm). Record it in `docs/BACKLOG.md` with that design and keep "one full read per compaction epoch" as the rule.
4. **Switch to block**: hooks' default `KBGATE_MODE` from `log` to `block` (env still overrides). Live tests from the scratchpad worktree with the repository's settings file: S09 (i)–(iii) and S10 A/B/C again (n=2 each; agents inside nested runs: 5 + 2 reviewers).
5. `docs/TESTS.md`, `MAPA.md`; `STATUS.md` Live mechanisms: "read gates: block mode since S12a (main + agents), cloud only". Copy the gate logs. The `.claude/settings.json` / hooks edit is the last write before the reviewers.

## Done when
```
python3 tools/gate_analysis.py docs/gatelogs/ > /dev/null ; echo exit=$?
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
grep -q 'KBGATE_MODE:-block' .claude/hooks/kb_readfirst.py .claude/hooks/kb_stop_readgate.py .claude/hooks/kb_agentgate.py ; echo exit=$?
```
plus the live-test table and the baseline numbers in the reply.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/hooks.md`; they check every number in `docs/reviews/gate-analysis.md` against the logs by re-running the script, and try one prompt each that the tuned `topics.json` should catch). Fix or reject. `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push, tag. Next prompt: `docs/prompts/S12b-lock-and-export.md`.
