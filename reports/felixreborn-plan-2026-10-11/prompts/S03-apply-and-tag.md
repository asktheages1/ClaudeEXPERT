# S03 — Apply the changelog triage, drain the delta boxes, tag every fact

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Every relevant triage row is applied to its topic file (old fact replaced, not appended), every "Deltas vs …" / "New URLs for O1" item in `recheck-and-conflicts.md` and `docs-index.md` is resolved into facts, and every bullet in the base carries an evidence tag. `As of:` headers mean "changelog reviewed through <version>" and move to the current version. This PR introduces phases 1a and 1: `main`'s checker caps at phase 0, so the owner reviews it by hand (say so).

## Read in full
- `CLAUDE.md`, `STATUS.md`, `knowledge/changelog-triage.tsv`
- `knowledge/recheck-and-conflicts.md`

## Work
1. **Boxes first, by you.** Turn every item of the "Deltas vs …" sections into an extra triage row (target = the owning topic file, reason = "delta box") and every "New URLs" entry into a row targeting `docs-index.md`; append them to `knowledge/changelog-triage.tsv` with version `box`; then delete the box sections. This keeps one owner per file in step 3.
2. Split rows by `target_file`; 7 packages, each ≤ 2 files and ≤ ~45 KB of source (largest paired with smallest); `Warsztat/package-<n>.md` with the file(s), their rows, the tag legend from COMMON §3 and the tagging rule below.
3. **Editor agents** (7, `model: "opus"`, `effort: "high"`, general-purpose, one message). Prompt skeleton:
   ```
   Read in full with the Read tool, no offset/limit: Warsztat/package-<n>.md, then every knowledge file it names. Apply each row: replaces_line set → replace that fact in place (same bullet, new wording, tag `[CL <version>, <date>]`); new fact → one bullet in the section the subject belongs to, same tag; never append a contradiction next to an old fact; never add a bullet without a tag. Then tag every bullet in your files that has no evidence tag on its own line, in its `##`/`###` heading, in a bold pseudo-heading above it, or in its parent bullet (accepted tags: the COMMON §3 legend; TL;DR-style summary bullets under a heading called TL;DR are exempt): take the source from the file's existing tags or from the row; if none applies, tag `[UNTAGGED: needs source]` and list it. Keep every file ≤ 28,000 bytes; if a file would exceed it, stop editing that file, report the overflow and propose a split. Touch no file outside your package. Report: rows applied (version, bullet_no), rows not applied and why, bullets newly tagged, bullets tagged UNTAGGED.
   ```
   `verify_reads.py` on every editor's transcript for its files.
4. Implement in `tools/kb_check.py`: phase 1a (no section titled "Deltas vs" or "New URLs"; `As of:` equals the current version in every content file; `knowledge/STATE.md` exists with `version:` and `phase: 1a`) and phase 1 (every bullet outside fenced code has a tag per the rule in step 3; `[UNTAGGED: needs source]` counts as tagged but is listed). Write `knowledge/STATE.md` by hand this once (S06's generator takes over); set `knowledge/phase.txt` to `1`. `triage_check.py --applied`: verifies by text, not by report: a row with `replaces_line` → the old line is absent from `target_file` and a `[CL <version>` tag is present; a new-fact row → `target_file` contains ≥ as many `[CL <version>` lines as rows of that version target it; box rows → the box sections are gone and `docs-index.md` has the URL.
5. Verify three replaced facts yourself against `Warsztat/changelog-group-<n>.md`: old line, new line, changelog bullet, in the reply.
6. UNTAGGED bullets → `docs/BACKLOG.md` ("needs a source", file and line).

## Done when
```
python3 tools/kb_check.py --phase 1 --tree HEAD ; echo exit=$?      # runs 0, 1a, 1
grep -rn "Deltas vs\|New URLs for O1" knowledge/ | wc -l             # 0
python3 tools/triage_check.py knowledge/changelog-triage.tsv --applied ; echo exit=$?
```

## End of session
Reviewers per COMMON §4 (KB files for them: two edited topic files of their choice in full; `Warsztat/changelog-group-<n>.md` for the rows they re-check, 10 each). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push, tag. Next prompt: `docs/prompts/S04-missing-pages.md`.
