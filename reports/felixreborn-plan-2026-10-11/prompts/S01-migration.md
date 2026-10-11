# S01 — Migration: six evidence-type files → topic files, by script, without changing a word

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Move every line of `knowledge/O0…O5` into topic-named files via a mapping table and a script, prove nothing was lost or duplicated, and leave redirect stubs. No wording changes. No new facts.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/O0-how-claude-works.md` sections 1 and 2 (Read limits, nested CLAUDE.md) — you need them to brief the agents

## Target files and sources (the mapping agents refine this to line ranges)
| New file | Sources |
|---|---|
| `context-window-and-read.md` | O0 §1; O1 §2 "Tool limits" sub-bullets |
| `instructions-memory-skills.md` | O0 §2; O2 §C; O2 §D5; O4 §5 |
| `agents-and-workflows.md` | O0 §3; the first four bullets of O0 §4 (agent definition, model precedence, tools/disallowedTools, permissionMode/omitClaudeMd); O2 §B; O3 §5–6 |
| `hooks.md` | O2 §A (A1–A8); O0 §4 bullets about hooks |
| `permissions-settings-automode.md` | O2 §D1–D4, D6; the remaining O0 §4 bullets |
| `models-effort-cost.md` | O0 §5; O5 §4; O5 §5 |
| `prompting-and-model-weaknesses.md` | O0 §6; O5 §1–3 |
| `cloud-environment.md` | O0 §7; O1 §3 cloud-network bullets |
| `headless-sdk-ci.md` | O3 §1–4, §7–10 |
| `mcp-and-plugins.md` | O4 §1–4, §6 |
| `design-rules.md` | O0 §8 |
| `docs-index.md` | O1 §0, §1, the rest of §2, §3 (non-network), §4; the "New URLs for O1" sections of O3–O5 |
| `recheck-and-conflicts.md` | O0 §9; O1 "Check again" and §5; O2 §E; every "Verify live" and "Deltas vs …" section of O2–O5 |
| per-file headers (the paragraphs above the first `##`, incl. O0's "Session reading budget" with `U5-31`) and the TL;DR sections of O1–O5 | each gets a row: a target section, or `drop` with a reason |

## Work
1. **Mapping agents** (6, one per O-file, `model: "opus"`, `effort: "high"`, general-purpose, launched in one message). Prompt skeleton:
   ```
   Read in full with the Read tool, no offset/limit: knowledge/<Ofile>.md. Then write Warsztat/migration-map-<Ofile>.tsv with columns: old_file, start_line, end_line, new_file, new_section_heading, note. Rules: the table above is the target; a section that the table splits between files (O0 §4, O1 §2, O1 §3) gets one row per bullet; every line of the source from line 1 to the last, including the file header, TL;DR, tables and fenced code, is covered by exactly one row (rows do not overlap and leave no gap); a line you believe belongs nowhere gets new_file=drop and a reason in note; do not rewrite, reorder or summarise anything. Finish by running: awk to prove coverage (sum of end-start+1 over rows == line count of the file) and print the result. Report: the file path, the coverage line, and any source line you were unsure about.
   ```
2. Merge the six tables into `knowledge/migration-map.tsv` (committed). Review every `drop` row yourself; a drop needs a reason you agree with, otherwise map it.
3. **`tools/kb_migrate.py`**: reads the table, writes the 13 new files (header: title line, `Keywords: (placeholder until S06)`, `Related: (placeholder until S06)`, `As of: <copied from the source header>`, `Cap: 28000 bytes`; then the mapped blocks in table order, each under the given heading), and rewrites `O0…O5` as stubs: a title, one sentence ("Moved on <date>; see the table"), and a table "old section → new file § section" (every old `##`/`###` heading, 87 in total).
4. **`tools/kb_migrate_check.py`**: normalises every non-blank, non-heading line (collapse whitespace) of the old files (from `git show origin/main:knowledge/<f>`) and of the new files (stubs excluded, fenced code blocks compared as whole blocks); asserts each old line appears exactly once in the new set and that the multiset of fact-ID occurrences (regex `\b[TU][0-9][a-z]?(-S)?-[0-9]+\b`; expect 350 unique, 425 occurrences) is unchanged. Exit 1 with a diff on any mismatch.
5. Run both scripts; iterate on the table until the check passes. Never fix a mismatch by editing a new file by hand.
6. `MAPA.md` §1 and `STATUS.md` updated. **Interim routing**: `CLAUDE.md` still routes to `O0…`; write the two-line proposed change to `Warsztat/CLAUDE.md.proposed.diff` ("read the stub's table, then the topic file") and name it in the reply as a decision for the owner.

## Done when
```
python3 tools/kb_migrate.py --check-only ; echo exit=$?     # table covers every source line
python3 tools/kb_migrate_check.py ; echo exit=$?
python3 tools/kb_check.py --phase 0 --tree HEAD ; echo exit=$?
for f in knowledge/*.md; do printf "%s %s\n" "$(wc -c <"$f")" "$f"; done | sort -n | tail -3   # all ≤ 28000
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/migration-map.tsv`, two new topic files of their choice read in full against their sources via `git show origin/main:knowledge/<f>`). Fix or reject. `STATUS.md` (Live mechanisms unchanged; add "migration verified by kb_migrate_check.py"), `CHANGELOG.md`, commit, push. Next prompt: `docs/prompts/S02-changelog-triage.md`.
