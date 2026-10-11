# S06 — The map: topics.json, generator, knowledge/CLAUDE.md, navigation probes (no hooks yet)

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Every shortcut into the base lands in the right file without a hook: file names are topics, `grep -i <word> knowledge/CLAUDE.md` answers with a file, and Read/Edit or a single-file `cat`/`head`/`tail`/`sed -n`/`grep` of any file in `knowledge/` auto-loads the map (`ls`, Glob and `grep -r` do not; the map says so). One source (`knowledge/topics.json`) generates the map, the `Keywords:` headers and, later, the hook rules. This PR introduces phase 2 (hand review; say so).

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/instructions-memory-skills.md` (nested CLAUDE.md loading; the measured Explore and `cat` facts)
## Read in part (say so)
- `head -15` of every topic file.

## Work
1. **`knowledge/topics.json`**: `{"topics": {"<topic>": {"keywords": [regexes with Polish stems, e.g. "hook(s|ów|ach|iem)?", "zaczep"], "files": ["hooks.md", ...] (≤ 3, priority order)}}, "settings": {"carry_over_prompts": 3, "max_required_per_prompt": 3, "max_required_per_session": 8, "gated_agent_types": ["general-purpose"]}}`. One topic per topic file at minimum; cross-cutting topics (effort, cache, compaction, worktree, deny) map to the files that hold them. `tests/topics/phrases.tsv` (phrase, expected_first_file), ≥ 3 per topic, Polish and English. The matcher is `tools/kb_topics.py` (one function; the hooks import it).
2. **`tools/kb_build.py`**: inputs only from committed files (`topics.json`, the topic files' `As of:` headers, `knowledge/phase.txt`, per-file byte sizes; no `claude --version`, no date, no network). Writes `knowledge/STATE.md`; the generated section of `knowledge/CLAUDE.md` between `<!-- generated:start -->` / `<!-- generated:end -->` (one line per keyword group: "`<keywords>` → `<file>`", sorted); the `Keywords:` / `Related:` header lines of every topic file (Related = other files of the same topics). Idempotent. CI: add a step to `kb-check` that runs `kb_build.py --root pr --check` (exit 1 on any diff).
3. **`knowledge/CLAUDE.md`** (≤ 9,500 bytes, hand-written part + generated part): what the base is; how to read (COMMON §1 rule in two sentences); the evidence-tag legend (COMMON §3); the open-conflicts list **moved** here from `recheck-and-conflicts.md` (one copy; the stub list there becomes a pointer); the sentence "A prompt or task that names a topic requires reading its file in full in this session, after the last compaction; the read gate enforces it once live"; "the map loads on Read/Edit and single-file `cat`/`head`/`tail`/`sed -n`/`grep`, not on `ls`, Glob or `grep -r`". Verify the nested load: one nested `-p` from the scratchpad worktree (`--model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns 4 --max-budget-usd 0.5 --output-format json`) asking for one line of `knowledge/hooks.md`; find its JSONL under `~/.claude/projects/<slug of the worktree path>/` (the nested run reports the parent's `session_id`, so pick the newest file) and check for a `nested_memory` attachment naming `knowledge/CLAUDE.md`.
4. `MAPA.md` §1 points at `knowledge/CLAUDE.md` for the base. `kb_check.py --phase 2`: every content file is covered by ≥ 1 topic; every file in `topics.json` exists; every regex compiles; every phrase in `phrases.tsv` matches its expected first file; `knowledge/CLAUDE.md` ≤ 9,500 bytes; `kb_build.py --check` clean; `agent-rules.md` + generated map lines ≤ 9,500 characters combined (for S08's injection; `agent-rules.md` does not exist yet → skip with a notice). `knowledge/phase.txt` → `2`.
5. **Navigation probes** (10 agents, one message, `model: "opus"`, `effort: "low"`): 4 general-purpose, 4 Explore, 2 `probe-omit` (the custom type from S05), each with one question from `phrases.tsv` phrased naturally ("Which hook events can block a tool call? Answer from the files in knowledge/ and name the file you used."). The Agent tool result names each agent's output file (its JSONL transcript): with `jq`, extract the first Read/`cat` of a `knowledge/` file and whether a `nested_memory` attachment appeared. Pass: ≥ 3/4 per type on the expected first file; `probe-omit`: record whether the nested map loaded (no threshold; it is the unverified case). Below 3/4: tune `topics.json` or the file name once, re-run that type (the re-run replaces the first, so the count stays 10 + 2 reviewers), then record whatever the second run gives. Table to `docs/FINDINGS.md` with `[MEASURED …, n=4/4/2]`.
6. Root `CLAUDE.md`: the skeleton's "Start of every session" lines that name `MAPA.md` for everything and `<kb>/O0-how-claude-works.md` → "project docs: `MAPA.md`; the knowledge base: `knowledge/CLAUDE.md` (auto-loaded on the first touch of any file there)". Write `Warsztat/proposed/CLAUDE.md.S06.diff`; name it in the reply.

## Done when
```
python3 tools/kb_build.py && git diff --quiet -- knowledge/ ; echo exit=$?    # idempotent
python3 tools/kb_check.py --phase 2 --tree HEAD ; echo exit=$?               # runs 0 … 2
test "$(wc -c < knowledge/CLAUDE.md)" -le 9500 ; echo exit=$?
python3 tools/probe_table_check.py docs/FINDINGS.md S06 ; echo exit=$?       # a row per probe type with n and pass/fail; committed this session
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/CLAUDE.md`, `knowledge/topics.json`, `tests/topics/phrases.tsv`; each adds 5 phrases of their own to a scratch copy and runs the matcher). Fix or reject. `STATUS.md` (Live mechanisms: "nested knowledge/CLAUDE.md map — measured S06; definitions reviewer.md, probe-omit.md"), `CHANGELOG.md`, commit, push, tag. Next prompt: `docs/prompts/S07-probes.md`.
