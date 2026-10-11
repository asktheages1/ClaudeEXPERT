# S02 — Changelog triage: Claude Code 2.1.292 → current, every bullet gets a destination

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Produce `knowledge/changelog-triage.tsv`: one row per changelog bullet since the base's version, each with a target topic file or `irrelevant` plus a reason. The only base edit this session is one line per version appended to `recheck-and-conflicts.md`; S03 applies the rows.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/recheck-and-conflicts.md`
- `knowledge/migration-table.md` (new file → old sections; the agents' routing aid, since `Keywords:` headers are placeholders until S06)
## Read in part (say so)
- `head -15` of every `knowledge/*.md` topic file (Bash is fine; this is not a full read).

## Work
1. `claude --version` → current version. The base's version: the `As of:` headers (2.1.289–2.1.291) **but** O0's content already carries a few `[CL 2.1.292 …]` / `[CL 2.1.293 …]` lines: `grep -rn '\[CL 2\.1\.29' knowledge/` and give the list to the agents so those bullets are marked `already-in-kb`, not re-applied. Fetch `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` with `curl -sL` into `Warsztat/CHANGELOG.md` (committed; S03 and S05 need it; a 403 is policy: stop and report); extract the sections for every version newer than 2.1.291 up to the current one (`awk` on `^## `); print bullet counts per version in the reply (2.1.292–2.1.296: 92/56/2/143/79 = 372 [MEASURED 2026-10-11]; newer versions add).
2. Four groups of similar size → `Warsztat/changelog-group-<n>.md`, bullets numbered.
3. **Triage agents** (4, `model: "opus"`, `effort: "high"`, general-purpose, one message). Prompt skeleton:
   ```
   Read in full with the Read tool: Warsztat/changelog-group-<n>.md; knowledge/migration-table.md. Run: for f in knowledge/*.md; do head -15 "$f"; done. Already-applied bullets (do not re-apply): <list from step 1>. For each bullet decide: target = one topic file in knowledge/ whose subject it changes, or `irrelevant`, or `already-in-kb`. Relevant = it changes a limit, a default, a flag, an event, a field, a precedence, a cloud behaviour, or a model, for Opus 5.5 / Fable 5.1 users of Claude Code, the API and the cloud; desktop-app, enterprise gateway, Bedrock/Vertex, IDE-plugin and UI-cosmetic bullets are irrelevant unless they change hooks, permissions, agents, skills or the cloud. When a bullet replaces a fact the base states, grep the topic file and quote the old line. Write Warsztat/triage-<n>.tsv: version, bullet_no, bullet_text, target_file, replaces_line_or_empty, reason. Every row has a non-empty reason. No bullet is skipped. Report the row count and the three bullets you were least sure about. Edit nothing else.
   ```
   `verify_reads.py` on each transcript for its group file.
4. Merge into `knowledge/changelog-triage.tsv`; commit `tools/triage_check.py`: row count = bullet count; `target_file` ∈ existing content files ∪ {irrelevant, already-in-kb}; reason non-empty; no duplicate (version, bullet_no). Spot-check 10 random `irrelevant` rows; > 1 wrong of 10 → send that group back to a fresh agent with the examples.
5. Append to `recheck-and-conflicts.md` one line per version: bullet count, triage file path, tag `[CL <version>, <date>]`.

## Done when
```
python3 tools/triage_check.py knowledge/changelog-triage.tsv ; echo exit=$?
python3 tools/kb_check.py --phase 0 --tree HEAD ; echo exit=$?
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/changelog-triage.tsv`; one group file of their choice; they re-triage 15 random rows and report disagreements). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push, tag. Next prompt: `docs/prompts/S03-apply-and-tag.md`.
