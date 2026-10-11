# S4 — Read gates: main session (Stop) and agents (SubagentStop) [G1, G3]

Read `docs/prompts/COMMON.md` in full, then this prompt in full, before any other action.

## Goal
A topical question cannot be answered — by the main session or by a gated agent — without a full read of the matching knowledge file after that question. Built per `docs/prompts/PLAN.md` §5, proven by fixtures and by live nested runs, live in the repository at the end of the session, with `KBGATE=off` as the kill switch.

## Read in full
- `CLAUDE.md`, `STATUS.md`, `docs/prompts/PLAN.md` (§5 is the spec), `knowledge/CLAUDE.md`
- `knowledge/hooks.md` (events, payloads, exit codes, output limits, Stop cap, `stop_hook_active`), `.claude/hooks/hooks.py`, `tools/test_hooks.sh`
## Read in part (say so)
- `docs/import/probes-2026-10-11.md`: sets P (P1–P3) and R (R6), set A (field names you will parse).

## Steps
1. **Matcher** in `hooks.py`: parse the map lines (`- <keywords> → \`<file>\``); keyword match case-insensitive on word boundaries, `*` = prefix; ≤ 3 files per text, ordered by number of hits. `tests/topics.tsv` (phrase, expected first file; ≥ 2 per topic file, Polish and English) checked by `tools/tests.sh`.
2. **Handlers** (new names in `HANDLERS`; all exit 0 at once when `KBGATE=off`; non-gate errors print to stderr and exit 0, as Foldery's non-Bash handlers do):
   - `readlog` (PostToolUse `Read|Bash`), `compact` (PostCompact `manual|auto`): PLAN §5 "Logger" and "PostCompact", state in `.claude/kbgate/<sha1(transcript_path)>.jsonl` under `$CLAUDE_PROJECT_DIR`, single-line appends, paths repo-relative with `.claude/worktrees/<n>/` stripped.
   - `prompt` (UserPromptSubmit): PLAN §5; stdout only on a match; < 1 s.
   - `stop` (Stop): PLAN §5, 3 blocks per `prompt_id`, then `systemMessage`. Do **not** exit early on `stop_hook_active` (O2 §A8's example does; here the counter is the cap; say so in a code comment). The block message names `cat` for the post-compaction case.
   - `substop` (SubagentStop): PLAN §5; gated types `general-purpose` + the `name:` of every `.claude/agents/*.md`; 2 blocks per `agent_id`; same `stop_hook_active` rule; transcript missing or without a user message → retry once after 1 s, then pass with a logged warning.
3. **`.claude/agent-rules.md`**: one sentence that a gated agent's end is checked; stays ≤ 2,500 B (`doc_check`).
4. **Fixtures** for every branch: match / no match; Read full, Read partial (`offset`), `file_unchanged` before and after a full read, after a compaction marker; `cat` exact, `cat` piped, `cat` with `persistedOutputPath`, `stdout` without the final newline; Stop met / unmet / third block → pass with `systemMessage`; match only in `last_assistant_message`; SubagentStop gated type unmet → 2, Explore → 0, `agent_id` reads counted only for that agent; `KBGATE=off` → 0. The probes file lists measured field names, not whole payloads: write the fixtures by hand from those names, exactly as spelled there.
5. **Settings**: add the five hooks to `.claude/settings.json` in Foldery's command form (timeouts: 30 for `prompt`, 60 for the rest). Write settings as the **last** code edit before the live tests, after `bash tools/tests.sh` is green — hooks take effect at once in this session (O0 §4). Your own later questions in this session will be gated; that is intended; `KBGATE=off` only if the gate blocks honest work, and say so.
6. **Live tests** (nested `claude -p` per COMMON, from the detached worktree, which carries the committed settings; budget ≤ 0.5 USD each, `--max-turns 8`):
   (i) "Which hook events can block an action? Answer from memory, do not read files." → pass = either a Stop block naming `hooks.md`, then a full read, then the answer, or a `full:true` read logged under the run's `prompt_id` before the first answer (the UserPromptSubmit text may make the model read first); report which branch happened (n=2);
   (ii) same question with "read knowledge/hooks.md first" → no block (n=2);
   (iii) the main run starts a `general-purpose` agent with "Which hook events can block an action? Do not read files." → SubagentStop block, the agent reads `hooks.md` (n=2);
   (iv) same with an `Explore` agent → no SubagentStop block (n=1).
   Evidence from `jq` on the JSON result and the transcripts (main and agent), plus the worktree's `.claude/kbgate/*.jsonl`. Results with n to `docs/FINDINGS.md`. A test whose premise fails (e.g. project hooks do not fire in subagents): record it, do not work around it, report it as a blocker for that half of the gate.
7. **`CLAUDE.md`**: the S4 rows of PLAN §8 — one sentence each; report bytes before/after.
8. **Reviewer** (`reviewer`, `opus`, `high`): reads PLAN §5, `knowledge/hooks.md`, the diff patches, `$SCRATCH/review/tests.txt` and `$SCRATCH/review/live.txt` (your `jq` outputs). (a) = a handler that contradicts PLAN §5 or a measured payload field; a phrase from the owner's typical questions in `knowledge/CLAUDE.md` keywords that the matcher misses or sends to the wrong file (it lists 5 it tried); (b) = failing done-criteria.
9. `/dostawa`. `STATUS.md` "Next task": `docs/prompts/S5-freshness.md`.

## Done when
```
bash tools/tests.sh ; echo exit=$?                 # fixtures + topics.tsv + doc_check
python3 tools/doc_check.py ; echo exit=$?
jq -s 'map(select(.full==true)) | length' "$SCRATCH/kbtest/.claude/kbgate/"*.jsonl   # > 0: live reads were logged
```
plus the four live results with their `jq` commands and n.
