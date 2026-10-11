# S03 — Apply the changelog triage, drain the delta boxes, tag every fact

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Every relevant changelog row from `knowledge/changelog-triage.tsv` is applied to its topic file (old fact replaced, not appended), every "Deltas vs …" / "New URLs for O1" box in `recheck-and-conflicts.md` and `docs-index.md` is resolved into facts, and every bullet in `knowledge/` carries an evidence tag. `As of:` headers move to the current Claude Code version.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`, `knowledge/changelog-triage.tsv`
- `knowledge/recheck-and-conflicts.md`

## Work
1. Split the triage rows by `target_file`; count rows per file. Pair files into 7 work packages so no package exceeds 2 files or ~45 KB of source (pair the largest with the smallest). Write `Warsztat/package-<n>.md` with: the file(s), their rows, and the tagging rule.
2. **Editor agents** (7, `model: "opus"`, `effort: "high"`, general-purpose, one message). Prompt skeleton:
   ```
   Read in full with the Read tool, no offset/limit: Warsztat/package-<n>.md, then every knowledge file it names. Apply each triage row: where replaces_line is set, replace that fact in place (same bullet, new wording, tag `[CL <version>, <date>]`); where it is a new fact, add one bullet in the section the subject belongs to, same tag; never append a contradiction next to an old fact; never add a bullet without a tag. Then tag every bullet in your files that has no evidence tag on its own line, in its heading, in a bold pseudo-heading above it or in its parent bullet: find the source in the file's existing tags or in the triage row; if none applies, tag it `[ASSUMPTION; untagged in source, 2026-10-xx]` and list it in your report. Keep every file ≤ 28,000 bytes; if a file would exceed it, stop editing that file, report the overflow and propose a split. Do not touch files outside your package. Report: rows applied, rows you could not apply and why, bullets newly tagged, bullets tagged [ASSUMPTION].
   ```
   Two agents must never share a file. The `docs-index.md` and `recheck-and-conflicts.md` box-draining is one package of its own: its agent moves each "New URLs" entry into the `docs-index.md` table (status ✅/🔗/❓ as in the source, date) and each "Deltas" item into the target topic file as a tagged fact or into the conflict list.
3. When all agents report: run `tools/kb_check.py --phase 1a` (new checks: no section titled "Deltas vs" or "New URLs"; `As of:` equals the current version in every topic file; `knowledge/STATE.md` exists with `version:` and `phase: 1a`) and `--phase 1` (every bullet outside fenced code has a tag per the rule above; TL;DR bullets exempt). Implement both phases in `tools/kb_check.py` first if S00 left them as stubs. Create `knowledge/STATE.md` by hand this once (S06's generator takes over).
4. Verify three replaced facts yourself against the raw changelog (`Warsztat/CHANGELOG.md`): quote old line, new line, changelog bullet in the reply.
5. `[ASSUMPTION; untagged in source]` bullets: list them in `docs/BACKLOG.md` as "needs a source" with file and line.

## Done when
```
python3 tools/kb_check.py --phase 1a --tree HEAD ; echo exit=$?
python3 tools/kb_check.py --phase 1 --tree HEAD ; echo exit=$?
grep -rn "Deltas vs\|New URLs for O1" knowledge/ | wc -l    # 0
python3 tools/triage_check.py knowledge/changelog-triage.tsv --applied   # every relevant row marked applied by an editor, exit 0
```

## End of session
Reviewers per COMMON §4 (KB files for them: two edited topic files of their choice, read in full, plus `Warsztat/CHANGELOG.md` for the versions applied; they re-check 10 applied rows each). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push. Next prompt: `docs/prompts/S04-missing-pages.md`.
