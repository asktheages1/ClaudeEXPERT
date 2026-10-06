# Findings

Important findings, crucial information and notable interactions from sessions. Newest first.
Format: `## YYYY-MM-DD — title`, then the fact with its evidence tag (see CLAUDE.md "Evidence tags"). Promote confirmed, general facts to `knowledge/` (with the owner's approval) and note it here.

## 2026-10-06 — KB audit: unique share, Read limits still undocumented, §9 not executable
- Docs still give no numbers for Read limits: tools-reference says only "the token limit" (PARTIAL view, error on explicit offset/limit); env-vars lists `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` without a default. No 25,000 / 256 KB [SOURCE: code.claude.com/docs/en/tools-reference.md, env-vars.md, curl + grep, 2026-10-06]. Workflows page still says "Up to 16 … fewer when … fewer CPUs", no formula [SOURCE: code.claude.com/docs/en/workflows.md, 2026-10-06].
- Tag census over knowledge/ (grep of opening tags, rough): MEASURED+CODE 84, official (SOURCE/OF/S:/CL) 299, 3P/UNCERTAIN 55, ASSUMPTION 32 → own measurements and code ≈ 18% of tagged claims, 77 of 84 in O0. 3P is spread over O1 (20) and O5 (15), not only O5 [MEASURED: grep -oE counts, 2026-10-06].
- O0 §9 says the recheck commands are in the research report, section "Sprawdź ponownie", which is not in this repo → the recheck list cannot be repeated as written [MEASURED: ls of repo, grep O0, 2026-10-06].

## 2026-10-06 — Auto mode classifier blocks Claude from changing its own instructions, even on the owner's request
- After the owner told Claude to merge to `main` itself, two actions were denied with reason `[Self-Modification]`: editing CLAUDE.md to record a standing approval to merge, and then fast-forwarding `main` with a branch that changes CLAUDE.md [MEASURED: 2 auto mode classifier denials, 2026-10-06, CC 2.1.291, Opus 5.5, n=2]. Consistent with O0 §4 (protected paths always go to the classifier). Ordinary edits to CLAUDE.md requested by the owner were allowed in the same session (n=3).
- Consequence: the owner merges changes into `main` on GitHub. Whether merges touching only `knowledge/` pass the classifier is unverified.

## 2026-10-06 — Glob and Grep present as dedicated tools
- In this cloud session (CC 2.1.291, Linux) the tool list contained `Glob` and `Grep` [MEASURED: session tool list, 2026-10-06, CC 2.1.291, Opus 5.5, n=1]. Related open conflict in CLAUDE.md ("Glob/Grep on Linux", O1 §2) stays open until confirmed across builds.

## 2026-10-06 — Session work is invisible to later sessions until merged into main
- Each cloud session gets its own branch cut from `origin/main` (O0 §7 [SOURCE: CE]; this session: `claude/compassionate-shannon-amdhmm` from `origin/main` 676c5b6 [MEASURED: git branch -r, git log, 2026-10-06]). KB edits and entries in this file reach the next session only after the owner merges them. Rule added to CLAUDE.md "Persistence".
