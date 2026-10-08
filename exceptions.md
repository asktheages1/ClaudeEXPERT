# Exceptions

Exceptions to general rules (documented behavior, KB facts, usual patterns) found while working on a task and confirmed by facts. Not for exceptions to the owner's instructions or to CLAUDE.md. Newest first.
Format: `## YYYY-MM-DD — rule → exception`, then:
- General rule, with its source (KB § + tag, or docs URL).
- Observed exception, with evidence (mandatory): `[MEASURED: command → result, date, CC version, model, n]` or `[SOURCE: URL, date]`.
- Scope: when it applies, and what is still unverified.

## 2026-10-08 — Edit deny catches the listed Bash file commands → also `cp` into the denied path
- General rule: Read/Edit deny rules also cover the Bash file commands Claude Code recognizes; the docs list `cat`, `head`, `tail`, `sed`, `tee` and redirections [SOURCE: CC permissions part2, 2026-10-08].
- Observed exception: with `.claude/settings.json` deny `Edit(./backup/**)` and allow `Bash(cp *)`, `cp a.txt backup/b.txt` was denied ("Permission to use Bash … has been denied", in `permission_denials`); without the deny the copy ran [MEASURED: reviewer agent, claude -p --model sonnet --effort low, 2026-10-08, CC 2.1.294, claude-sonnet-5-5, n=1 + control].
- Scope: `cp` destination; `mv`, `rsync`, `install` and the source side of `cp` unverified. Consequence: a deny on a backup directory can break a backup step done with `cp`.

## 2026-10-08 — nested CLAUDE.md loads on Read/Write/Edit only → also on Bash `cat` / `head`
- General rule: subdirectory CLAUDE.md files (and `paths:` rules) load "when Claude uses the Read, Write, or Edit tool on a file in those subdirectories" [SOURCE: https://code.claude.com/docs/en/memory.md, 2026-10-08; O0 §2].
- Observed exception: in a fresh `claude -p` session, Bash `cat sub/a.txt` and, in another session, `head -1 sub/a.txt` each produced `nested_memory` attachments for `sub/CLAUDE.md` and `.claude/rules/r.md` (`paths: sub/**`); Grep on `sub/` and `python3 -c "open('sub/a.txt')"` did not [MEASURED: claude -p --model sonnet --effort low --allowedTools "Bash(cat *)|Bash(head *)|Grep|Bash(python3 *)", transcript attachment order, 2026-10-08, CC 2.1.294, claude-sonnet-5-5, n=1 per command].
- Scope: probably the file-reading commands Claude Code recognizes (the same set deny rules check, O0 §4) [ASSUMPTION]. Unverified: other commands (`sed -n`, `less`, `tail`), Glob, other CC versions.
