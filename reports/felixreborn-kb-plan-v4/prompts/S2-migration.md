# S2 — Migration: O0–O5 → topic files, word for word, and the keyword map [G3, G1]

Read `docs/prompts/COMMON.md` in full, then this prompt in full, before any other action.

## Goal
Every line of `knowledge/O0…O5` moves into topic-named files ≤ 28,000 B by a table and a script; a check proves nothing was lost or doubled; only cross-references are rewritten; the O-files are deleted; `knowledge/CLAUDE.md` becomes the keyword map the read gate (S4) will parse. No new facts, no rewording.

## Read in full
- `CLAUDE.md`, `STATUS.md`, `knowledge/CLAUDE.md`
- `knowledge/O0-how-claude-works.md`, `knowledge/O1-docs-index.md` (the two files with sections that split per bullet; you write those rows yourself)
## Read in part (say so)
- `knowledge/O2…O5`: headings only (`grep -n '^#' knowledge/O[2-5]-*.md`); they move by whole sections.

## Target files (section level)
| New file | Sources |
|---|---|
| `context-window-and-read.md` | O0 §1; O1 §2 "Tool limits" bullets (Read, Bash, Glob/Grep, WebFetch) |
| `instructions-memory-skills.md` | O0 §2; O2 §C; O2 §D5; O4 §5 |
| `agents-and-workflows.md` | O0 §3; O0 §4 bullets on agent definitions, model precedence, tools/disallowedTools, permissionMode/omitClaudeMd; O2 §B; O3 §5–6 |
| `hooks.md` | O2 §A; O0 §4 bullets on hooks |
| `permissions-settings-automode.md` | O2 §D1–D4, D6; remaining O0 §4 bullets |
| `models-effort-cost.md` | O0 §5; O5 §4–5 |
| `prompting-and-model-weaknesses.md` | O0 §6; O5 §1–3 |
| `cloud-environment.md` | O0 §7; O1 §3 cloud-network bullets |
| `headless-sdk-ci.md` | O3 §1–4, §7–10 |
| `mcp-and-plugins.md` | O4 §1–4, §6 |
| `design-rules.md` | O0 §8 |
| `docs-index.md` | O1 §0, §1, rest of §2, §3 (non-network), §4; "New URLs for O1" sections of O3–O5 |
| `recheck-and-conflicts.md` | O0 §9; O1 "Check again" and §5; O2 §E; every "Verify live" and "Deltas vs …" section; file headers and TL;DR sections of O0–O5 under "Source headers and TL;DRs (historical)" |

The section numbers are from the snapshot; if a heading differs, map by content and say so. A source section the table does not name: put it where its subject belongs and list it in the reply.

## Steps
1. `knowledge/migration-map.tsv` (old_file, start_line, end_line, new_file, new_heading): section rows by script from the headings; per-bullet rows for O0 §4, O1 §2, O1 §3 written by you (sub-bullets travel with their bullet). Both scripts read the sources with `git show origin/main:knowledge/<f>` (step 4 deletes the working copies). `tools/kb_migrate.py --check-only`: rows tile every source file from line 1 to its end, no gap, no overlap, every `new_file` in the table.
2. `tools/kb_migrate.py` writes the 13 files: a header (title; `As of:` = the oldest source `As of`), then the mapped blocks in table order under their headings. Cross-references are the only change: every `O[0-5] §<id>` and bare `§<n>` is rewritten to `<new file> §<new heading>` from the old→new heading table; an ambiguous one (section split across files) points to the file that got its first bullet and is listed in the reply.
3. `tools/kb_migrate_check.py`: normalise every non-blank, non-heading line (collapse whitespace; fenced code blocks compared whole) of the old files after applying the same reference rewrite, and of the new files without their generated header (title and `As of:` line); assert `Counter(old) == Counter(new)`; assert the multiset of fact IDs (`\b[TU][0-9][a-z]?(-S)?-[0-9]+\b`) is unchanged (print counts). Mismatch = exit 1 with the diff; never fix by hand-editing a new file.
4. `git rm knowledge/O[0-5]-*.md`. Apply the same reference rewrite to the live instructions: `CLAUDE.md`, `MAPA.md`, `.claude/agent-rules.md`, `.claude/skills/**`, `docs/prompts/*.md` (history in `docs/import/`, `docs/FINDINGS.md`, `CHANGELOG.md` keeps the old form). Then `grep -rn 'O[0-5] §\|O[0-5]-[a-z]' knowledge/ CLAUDE.md MAPA.md .claude/ docs/prompts/ | grep -v 'docs/prompts/S1-tooling.md'` → nothing (S1's prompt is history). Remove the `O[0-5]-*.md` row from `limits()` in `doc_check.py`.
5. **Map** `knowledge/CLAUDE.md` rewritten (≤ 6,500 B): keep the reading rule, tag legend, conflicts list, `As of:`; one line per topic file `- <keywords> → \`<file>\` (N KB) §1 …, §2 …`. Keywords: the words an owner's question or an agent task would contain, English and Polish, `*` for stems (`hook*`, `uprawnie*`), ≤ 20 per line, no keyword on two lines unless both files hold it. Over 6,500 B: shorten the `§` lists first, never drop keywords or the conflicts list. Add the parse rule to `doc_check.py` (PLAN §3: every map line parses, every keyword compiles, every topic file mapped) with self-test fixtures. `docs-index.md` and `recheck-and-conflicts.md` are mapped like the others.
6. **Navigation probes** (2 agents, one message, `model: "opus"`, `effort: "low"`): one `general-purpose`, one `Explore`; each gets three questions you write, one per different topic file ("Answer from the files in knowledge/ only; name the file you used"). From each agent's transcript (the Agent result names its output file [MEASURED in ClaudeEXPERT, 2026-10-11]; if not, the newest `agent-*.jsonl` under `~/.claude/projects/` by mtime) take with `jq` the first `knowledge/` path it read and whether a `hook_additional_context` attachment (the injected map) is present. Pass: 2 of 3 first reads hit the expected file per agent. Below that: change keywords or the file name once and re-run that agent. Table in `docs/FINDINGS.md` with n.
7. `MAPA.md` §1 row "knowledge base → `knowledge/CLAUDE.md`"; `CLAUDE.md`: only the reference rewrite of step 4 (S1 already routes to the map; verify the line still holds; report bytes before/after).
8. **Reviewer** (`subagent_type: "reviewer"`, `model: "opus"`, `effort: "high"`): reads `knowledge/migration-map.tsv`, the new map, two topic files of its choice in full, and their sources from `$SCRATCH/review/old-<f>` (you write them with `git show origin/main:knowledge/<f>`). (a) = a bullet in a file whose subject it does not match, a map keyword pointing to the wrong file, a broken rewritten reference; (b) = failing done-criteria.
9. `/dostawa`. `STATUS.md` "Next task": `docs/prompts/S3-update.md`.

## Done when
```
python3 tools/kb_migrate.py --check-only ; echo exit=$?
python3 tools/kb_migrate_check.py ; echo exit=$?
ls knowledge/O[0-5]-* 2>/dev/null | wc -l          # 0
python3 tools/doc_check.py ; echo exit=$?          # 0 (map parse rule active)
bash tools/tests.sh ; echo exit=$?
```
plus the probe table.
