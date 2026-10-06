# Findings

Important findings, crucial information and notable interactions from sessions. Newest first.
Format: `## YYYY-MM-DD — title`, then the fact with its evidence tag (see CLAUDE.md "Evidence tags"). Promote confirmed, general facts to `knowledge/` (with the owner's approval) and note it here.

## 2026-10-06 — Ask rules vs auto mode; branch protection and admins (from review of an external implementation plan)
- Docs: explicit `ask` rules and a PreToolUse hook `ask` decision still show a prompt in auto mode [SOURCE: https://code.claude.com/docs/en/permission-modes.md (lines on "auto mode still shows you those prompts" and "Explicit ask rules still force a prompt"), 2026-10-06]. Deny/ask rules apply when any subcommand matches, incl. `cd x && ...`, subshells and command substitution, also in auto mode [SOURCE: https://code.claude.com/docs/en/permissions.md#compound-commands, 2026-10-06].
- An external audit (owner's other project) reports one cloud session in auto mode where an Edit covered by an `ask` rule ran without a prompt (n=1, cause not established). Unverified here; contradicts the docs above. Candidate for `exceptions.md` only after a measurement (check rule path anchoring, O0 §4, and which branch's settings were loaded at session start).
- GitHub branch protection: by default does not apply to repo admins; the option "Do not allow bypassing the above settings" extends it to them. Protected branches in private repos need GitHub Pro/Team/Enterprise [SOURCE: github/docs content/repositories/.../about-protected-branches.md and data/reusables/gated-features/protected-branches.md, 2026-10-06]. Cloud sessions push with the user's token (O0 §7 [SOURCE: CE]), so on a repo the owner administers, protection binds Claude only with that option on. O0 §8 ("no admin exemption") is imprecise; KB fix proposed to the owner.
- Stop hook block cap (8 consecutive blocks without a tool call, `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) re-confirmed in hooks-guide.md [SOURCE: https://code.claude.com/docs/en/hooks-guide.md, 2026-10-06]; already in O2 §1.

## 2026-10-06 — Auto mode classifier blocks Claude from changing its own instructions, even on the owner's request
- After the owner told Claude to merge to `main` itself, two actions were denied with reason `[Self-Modification]`: editing CLAUDE.md to record a standing approval to merge, and then fast-forwarding `main` with a branch that changes CLAUDE.md [MEASURED: 2 auto mode classifier denials, 2026-10-06, CC 2.1.291, Opus 5.5, n=2]. Consistent with O0 §4 (protected paths always go to the classifier). Ordinary edits to CLAUDE.md requested by the owner were allowed in the same session (n=3).
- Consequence: the owner merges changes into `main` on GitHub. Whether merges touching only `knowledge/` pass the classifier is unverified.

## 2026-10-06 — Glob and Grep present as dedicated tools
- In this cloud session (CC 2.1.291, Linux) the tool list contained `Glob` and `Grep` [MEASURED: session tool list, 2026-10-06, CC 2.1.291, Opus 5.5, n=1]. Related open conflict in CLAUDE.md ("Glob/Grep on Linux", O1 §2) stays open until confirmed across builds.

## 2026-10-06 — Session work is invisible to later sessions until merged into main
- Each cloud session gets its own branch cut from `origin/main` (O0 §7 [SOURCE: CE]; this session: `claude/compassionate-shannon-amdhmm` from `origin/main` 676c5b6 [MEASURED: git branch -r, git log, 2026-10-06]). KB edits and entries in this file reach the next session only after the owner merges them. Rule added to CLAUDE.md "Persistence".
