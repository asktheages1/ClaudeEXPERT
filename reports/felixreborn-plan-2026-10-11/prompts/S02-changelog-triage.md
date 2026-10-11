# S02 — Changelog triage: Claude Code 2.1.292 → current, every bullet gets a destination

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Produce `knowledge/changelog-triage.tsv`: one row per changelog bullet since the KB's version, each with a target topic file or `irrelevant` plus a reason. No KB file changes in this session (S03 applies the rows).

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/recheck-and-conflicts.md` (what the KB already lists as deltas)
- the headers (first 15 lines) of every `knowledge/*.md` topic file, to brief the agents on what lives where

## Work
1. `claude --version` → the current version. The KB version is in each topic file's `As of:` header (2.1.289–2.1.291 after S01; S01 did not update it). Fetch `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` with `curl -sL` into `Warsztat/CHANGELOG.md`; extract the sections for every version newer than the KB version up to the current one (`awk` on `^## `). Count bullets per version and print the counts in the reply (expected for 2.1.292–2.1.296: 92/56/2/143/79 = 372 [MEASURED 2026-10-11]; newer versions add to it).
2. Split into 4 groups of similar size (e.g. 2.1.292 / 2.1.293+2.1.294 / 2.1.295 / 2.1.296+newer). Write each group to `Warsztat/changelog-group-<n>.md` with the bullets numbered.
3. **Triage agents** (4, `model: "opus"`, `effort: "high"`, general-purpose, one message). Prompt skeleton:
   ```
   Read in full with the Read tool: Warsztat/changelog-group-<n>.md; knowledge/CLAUDE.md if it exists, else the first 15 lines of every knowledge/*.md (run: for f in knowledge/*.md; do head -15 "$f"; done). For each bullet decide: target = one topic file in knowledge/ whose subject it changes, or `irrelevant`. Rules: a bullet is relevant if it changes a limit, a default, a flag, an event, a field, a precedence, a cloud behaviour or a model that the KB describes or should describe for Opus 5.5 / Fable 5.1 users of Claude Code, the API and the cloud; desktop-app, enterprise gateway, Bedrock/Vertex, IDE-plugin and UI-cosmetic bullets are irrelevant unless they change hooks, permissions, agents, skills or the cloud. When a bullet replaces a fact the KB states, say which (grep the topic file; quote the old line). Write Warsztat/triage-<n>.tsv: version, bullet_no, bullet_text, target_file, replaces_line_or_empty, reason. Every row has a non-empty reason. No bullet is skipped. Report the row count and the three bullets you were least sure about.
   ```
4. Merge into `knowledge/changelog-triage.tsv`. Check with a script you commit as `tools/triage_check.py`: row count equals the bullet count; every `target_file` exists in `knowledge/` or equals `irrelevant`; every reason non-empty; no duplicate (version, bullet_no). Spot-check 10 random `irrelevant` rows yourself; if more than 1 of 10 is wrong, send that group back to a fresh agent with the examples.
5. Append to `knowledge/recheck-and-conflicts.md` a line per version with the bullet count and the triage file path (that is the only KB edit; keep the tag `[CL <version>, <date>]`).

## Done when
```
python3 tools/triage_check.py knowledge/changelog-triage.tsv ; echo exit=$?
python3 tools/kb_check.py --phase 0 --tree HEAD ; echo exit=$?
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/changelog-triage.tsv`; one group file of their choice; they must re-triage 15 random rows and report disagreements). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push. Next prompt: `docs/prompts/S03-apply-and-tag.md`.
