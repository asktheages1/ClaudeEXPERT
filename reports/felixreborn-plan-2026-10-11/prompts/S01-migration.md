# S01 — Migration: six evidence-type files → topic files, by script, without changing a word

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Move every line of `knowledge/O0…O5` into topic-named files via a mapping table and a script, prove nothing was lost or duplicated, rewrite only cross-references, import the two pieces of KB meta-content that lived in the source repository's root CLAUDE.md, and leave redirect stubs. No wording changes otherwise. No new facts.

## Read in full
- `CLAUDE.md`, `STATUS.md`
## Read in part (say so)
- `knowledge/O0-how-claude-works.md` sections 1 and 2 (Read limits, nested CLAUDE.md), to brief the agents.

## Target files and sources (section level; the script expands this)
| New file | Sources |
|---|---|
| `context-window-and-read.md` | O0 §1; O1 §2 "Tool limits" sub-bullets (Read, Bash, Glob/Grep, WebFetch) |
| `instructions-memory-skills.md` | O0 §2; O2 §C; O2 §D5; O4 §5 |
| `agents-and-workflows.md` | O0 §3; O0 §4 first four bullets (agent definition, model precedence, tools/disallowedTools, permissionMode/omitClaudeMd); O2 §B; O3 §5–6 |
| `hooks.md` | O2 §A (A1–A8); O0 §4 bullets about hooks |
| `permissions-settings-automode.md` | O2 §D1–D4, D6; the remaining O0 §4 bullets |
| `models-effort-cost.md` | O0 §5; O5 §4; O5 §5 |
| `prompting-and-model-weaknesses.md` | O0 §6; O5 §1–3 |
| `cloud-environment.md` | O0 §7; O1 §3 cloud-network bullets |
| `headless-sdk-ci.md` | O3 §1–4, §7–10 |
| `mcp-and-plugins.md` | O4 §1–4, §6 |
| `design-rules.md` | O0 §8 |
| `docs-index.md` | O1 §0, §1, the rest of §2, §3 (non-network), §4; the "New URLs for O1" sections of O3–O5 |
| `recheck-and-conflicts.md` | O0 §9; O1 "Check again" and §5; O2 §E; every "Verify live" and "Deltas vs …" section of O2–O5; **plus the imported block below** |
| file headers (above the first `##`, incl. O0's "Session reading budget" with `U5-31`) and the TL;DR sections of O1–O5 | a row each: `recheck-and-conflicts.md` section "Source file headers and TL;DRs (verbatim, historical)" — nothing is dropped |

**Imported block** (from the source repository's root `CLAUDE.md`, which FelixReborn does not have; paste verbatim into `recheck-and-conflicts.md` under "Known open conflicts (imported 2026-10-11, never resolve silently)"):
```
- Sonnet 5.5 default effort: O0 §5 says medium, O5 §1 says high.
- Workflow concurrency: O0 §3 measured `min(16, max(2, CPU−2))`; docs say "up to 16, fewer with fewer CPUs" (O3).
- Workflow agent cache TTL: O3 says 5 min by default even on subscriptions; check against O0 §3.
- Haiku 4.5 retirement: O0 says not before 2026-10-15; O5 says not before ~2026-12-05.
- Glob/Grep on Linux (O1 §2): depends on build; check the session's tool list.
```
The evidence-tag legend is already in COMMON §3 and `docs/FINDINGS.md`; `knowledge/CLAUDE.md` (S06) will carry it for the base.

## Work
1. **Section-level rows by script.** `tools/kb_migrate.py --emit-sections` reads the table above (committed as `knowledge/migration-table.md`) and the six files' headings and writes `knowledge/migration-map.tsv` (old_file, start_line, end_line, new_file, new_section_heading, note) with one row per heading-delimited block, headers and TL;DRs included. Rows for the three sections that split per bullet (O0 §4, O1 §2, O1 §3) are emitted as `TODO` placeholders.
2. **Mapping agents** (2, `model: "opus"`, `effort: "high"`, general-purpose, one message): agent A gets O0 (`Read in full`: `knowledge/O0-how-claude-works.md`), agent B gets O1; each replaces the `TODO` rows of its file with one row per bullet (the sub-bullets of a split bullet travel with it), using the table above as the target; no reordering, no rewriting; output `Warsztat/migration-map-<Ofile>.tsv`; done when the rows tile the TODO ranges exactly (no gap, no overlap; print the check). Run `verify_reads.py` on both transcripts for their O-file.
3. Merge; `tools/kb_migrate.py --check-only` asserts the rows tile every source file from line 1 to the end with no overlap, and every `new_file` is in the table.
4. **`tools/kb_migrate.py`** writes the 13 new files (header: title line; `Keywords: (placeholder until S06)`; `Related: (placeholder until S06)`; `As of: <the oldest "As of" among the sources>`; `Cap: 28000 bytes`; then the mapped blocks in table order under the given headings) and rewrites `O0…O5` as stubs: title, one sentence ("Moved on <date>; see the table"), and a table "old section → new file § section" for every old `##`/`###` heading (87). **Cross-references** are the one allowed change: every `O[0-5] §<id>` and bare `§<n>` in moved text is rewritten from the old→new heading table (e.g. `O0 §4` → `permissions-settings-automode.md §…` or `hooks.md §…` as the mapping decides; an ambiguous bare `§n` whose old section split across files is rewritten to the file that received the first bullet, and listed in the report).
5. **`tools/kb_migrate_check.py`**: normalise every non-blank, non-heading line (collapse whitespace; fenced code blocks compared as whole blocks) of the old files (`git show origin/main:knowledge/<f>`) and the new content files (stubs excluded); assert `Counter(old) == Counter(new)` **after applying the reference rewrite to the old lines**; and that the multiset of fact-ID occurrences (regex `\b[TU][0-9][a-z]?(-S)?-[0-9]+\b`) is unchanged (report the counts; the expectation today is 350 unique / 425 occurrences, but the assertion is equality, not the numbers). Exit 1 with a diff on any mismatch. Never fix a mismatch by editing a new file by hand.
6. `kb_check.py --phase 0` on the result (the stub-table resolution for `O[0-5] §` references applies only to text outside `knowledge/`, e.g. `docs/import/`; inside the base, references are rewritten). Update `knowledge/phase.txt`? No: phase stays 0.
7. `MAPA.md`, `STATUS.md`. **Interim routing**: the skeleton's "Start of every session" line that names `<kb>/O0-how-claude-works.md` now points at a stub; write `Warsztat/proposed/CLAUDE.md.S01.diff` changing it to "`knowledge/<topic file>` per the stub's table; the map arrives in S06" and name it as a decision in the reply.

## Done when
```
python3 tools/kb_migrate.py --check-only ; echo exit=$?
python3 tools/kb_migrate_check.py ; echo exit=$?
python3 tools/kb_check.py --phase 0 --tree HEAD ; echo exit=$?
for f in knowledge/*.md; do printf "%s %s\n" "$(wc -c <"$f")" "$f"; done | sort -n | tail -3   # content files ≤ 28000
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/migration-map.tsv`; two new topic files of their choice read in full against their sources via `git show origin/main:knowledge/<f>` written to `Warsztat/_scratch/review/old-<f>` for Read). Fix or reject. `STATUS.md` (add "migration verified by kb_migrate_check.py"), `CHANGELOG.md`, commit, push, tag. Next prompt: `docs/prompts/S02-changelog-triage.md`.
