# Findings

Important findings, crucial information and notable interactions from sessions. Newest first.
Format: `## YYYY-MM-DD — title`, then the fact with its evidence tag (see CLAUDE.md "Evidence tags"). Promote confirmed, general facts to `knowledge/` (with the owner's approval) and note it here.

## 2026-10-06 — CC 2.1.292 adds an `effort` parameter to the Agent tool (KB says there is none)
- Changelog 2.1.292: "Added an `effort` parameter to the Agent tool, so Claude runs a sub-agent at the effort level you ask for" [CL: raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md, fetched 2026-10-06]. O0 §3 (`[CODE]`, 2.1.289) still says the Agent tool has NO effort field; this session runs CC 2.1.292 [MEASURED: claude --version, 2026-10-06]. Not yet checked in this session's Agent tool schema. KB update pending the owner's approval.
- Same changelog: `<system-reminder>` tags in hook output are now escaped before reaching Claude; @-mentioned text files over 256 KB are no longer dropped silently.

## 2026-10-06 — CLAUDE.md size cap and @-import details (not in KB)
- "Claude Code loads a CLAUDE.md file of up to 4 MiB in full and skips a larger file"; imports skip code spans and fenced blocks (backticks keep `@path` literal); block-level HTML comments are stripped before injection; an external import declined once stays disabled and the dialog does not return [SOURCE: https://code.claude.com/docs/en/memory.md, 2026-10-06, sha256 b4e76ef1…].

## 2026-10-06 — Auto mode classifier blocks Claude from changing its own instructions, even on the owner's request
- After the owner told Claude to merge to `main` itself, two actions were denied with reason `[Self-Modification]`: editing CLAUDE.md to record a standing approval to merge, and then fast-forwarding `main` with a branch that changes CLAUDE.md [MEASURED: 2 auto mode classifier denials, 2026-10-06, CC 2.1.291, Opus 5.5, n=2]. Consistent with O0 §4 (protected paths always go to the classifier). Ordinary edits to CLAUDE.md requested by the owner were allowed in the same session (n=3).
- Consequence: the owner merges changes into `main` on GitHub. Whether merges touching only `knowledge/` pass the classifier is unverified.

## 2026-10-06 — Glob and Grep present as dedicated tools
- In this cloud session (CC 2.1.291, Linux) the tool list contained `Glob` and `Grep` [MEASURED: session tool list, 2026-10-06, CC 2.1.291, Opus 5.5, n=1]. Related open conflict in CLAUDE.md ("Glob/Grep on Linux", O1 §2) stays open until confirmed across builds.

## 2026-10-06 — Session work is invisible to later sessions until merged into main
- Each cloud session gets its own branch cut from `origin/main` (O0 §7 [SOURCE: CE]; this session: `claude/compassionate-shannon-amdhmm` from `origin/main` 676c5b6 [MEASURED: git branch -r, git log, 2026-10-06]). KB edits and entries in this file reach the next session only after the owner merges them. Rule added to CLAUDE.md "Persistence".
