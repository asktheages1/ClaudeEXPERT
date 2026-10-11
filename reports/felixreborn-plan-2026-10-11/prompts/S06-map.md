# S06 — The map: topics.json, generator, knowledge/CLAUDE.md, navigation probes (no hooks yet)

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Every shortcut into the base lands in the right file without a hook: file names are topics, `grep -i <word> knowledge/CLAUDE.md` answers with a file, and touching any file in `knowledge/` auto-loads the map (nested CLAUDE.md). One source (`knowledge/topics.json`) generates the map, the `Keywords:` headers and, later, the hook rules.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/instructions-memory-skills.md` (nested CLAUDE.md loading rules; the measured facts about Explore and `cat`)
- the first 15 lines of every `knowledge/*.md` topic file

## Work
1. **`knowledge/topics.json`**: `{"topic": {"keywords": [regexes, Polish stems included, e.g. "hook(s|ów|ach|iem)?", "zaczep"], "files": ["hooks.md", ...] (≤ 3, priority order)}, ...}` plus `"settings": {"carry_over_prompts": 3, "max_required_per_prompt": 3}`. One topic per topic file at minimum; cross-cutting topics (effort, cache, compaction, worktree, deny) map to the 1–3 files that hold them. Test phrases: `tests/topics/phrases.tsv` (phrase_pl_or_en, expected_first_file), ≥ 3 per topic.
2. **`tools/kb_build.py`**: reads `topics.json` and the topic files' `As of:` headers; writes (a) `knowledge/STATE.md` (version from the headers, models, phase, per-file byte sizes; **no live values**: no `claude --version`, no date, no network), (b) the generated section of `knowledge/CLAUDE.md` between `<!-- generated:start -->` / `<!-- generated:end -->`: one line per keyword group "`<keywords>` → `<file>` §…", sorted; and the `Keywords:` / `Related:` header lines of every topic file (Related = the other files of the same topics). Idempotent: running twice changes nothing. CI (`.github/workflows/kb-check.yml`) runs it and fails on a diff: add that step.
3. **`knowledge/CLAUDE.md`** (≤ 9,500 bytes, hand-written part + generated part): what the base is; how to read (Read tool, full; `cat` only under 28 KB); the evidence-tag legend; the one copy of the open-conflicts list (moved from `recheck-and-conflicts.md`; `CLAUDE.md` root keeps its copy until S13, say so in the reply); "when a topic is named, read its file in full in this session, after the last compaction; the read gate enforces it once live"; the old-name table lives in the stubs. Verify the nested load yourself: in a scratch `claude -p` from `/tmp/kbtest` (worktree of this branch; `--model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns 4 --max-budget-usd 0.5 --output-format json`) ask for one line of `knowledge/hooks.md` and check the JSON transcript for a `nested_memory` attachment naming `knowledge/CLAUDE.md`.
4. `reports/README.md` and `migration-kit/README.md` if those directories exist here (one line per file); `MAPA.md` §1 points to `knowledge/CLAUDE.md` for the base.
5. `tools/kb_check.py --phase 2`: every `knowledge/*.md` content file is covered by ≥ 1 topic; every file in `topics.json` exists; every regex compiles; every phrase in `tests/topics/phrases.tsv` matches its expected first file (the matcher is a function in `tools/kb_topics.py`, shared with the future hooks); `knowledge/CLAUDE.md` ≤ 9,500 bytes; generated sections equal a fresh `kb_build.py` run.
6. **Navigation probes** (12 agents, one message, all `effort: "low"`, `model: "opus"`): 5 general-purpose and 5 Explore, each with one question from `phrases.tsv` phrased naturally ("Which hook events can block a tool call? Answer from the files in knowledge/ and name the file you used."); 2 custom agents defined in `.claude/agents/probe-omit.md` with `omitClaudeMd: true` (same question). After they finish, find each agent's transcript (`~/.claude/projects/*/` or the task output files the Agent tool names) and with `jq` extract the first `Read`/`cat` of a `knowledge/` file and whether a `nested_memory` or `hook_additional_context` attachment appeared. Pass: ≥ 4/5 per type hit the expected first file; `omitClaudeMd`: record whether the nested map loaded (no threshold; this is the unverified case). Write the table to `docs/FINDINGS.md` with `[MEASURED …, n=5/5/2]`.
7. `CLAUDE.md` root: the KB table → two lines pointing at `knowledge/CLAUDE.md`; write to `Warsztat/CLAUDE.md.proposed.diff` (append), name it in the reply.

## Done when
```
python3 tools/kb_build.py && git diff --quiet -- knowledge/ ; echo exit=$?    # idempotent
python3 tools/kb_check.py --phase 2 --tree HEAD ; echo exit=$?
wc -c knowledge/CLAUDE.md     # ≤ 9500
```
plus the probe table in `docs/FINDINGS.md` with the pass/fail per type.

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/CLAUDE.md`, `knowledge/topics.json`, `tests/topics/phrases.tsv`; they each add 5 phrases of their own and run the matcher). Fix or reject. `STATUS.md` (Live mechanisms: "nested knowledge/CLAUDE.md map — measured S06"), `CHANGELOG.md`, commit, push. Next prompt: `docs/prompts/S07-probes.md`.
