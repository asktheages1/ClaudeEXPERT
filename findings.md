# Findings

Important findings, crucial information and notable interactions from sessions. Newest first.
Format: `## YYYY-MM-DD — title`, then the fact with its evidence tag (see CLAUDE.md "Evidence tags"). Promote confirmed, general facts to `knowledge/` (with the owner's approval) and note it here.

## 2026-10-06 — Enforcement layer: check.sh + Stop/SessionStart hooks measured
- `scripts/test-check.sh` plants 16 check.sh failures + 1 clean run + 1 subdirectory run + 7 Stop hook cases in a temp copy: 24 passed, 0 failed [MEASURED: scripts/test-check.sh → "24 passed, 0 failed", rc 0, 2026-10-06, CC 2.1.292, n=1 run]. A mutated copy (limit 50,000 B, MAX_BLOCKS 5) made 5 tests fail [MEASURED: same, n=1], so the tests do detect weakened checks.
- Stop hook blocks while check.sh is red, interactive cloud session: stop 1 blocked by both the platform hook (`~/.claude/stop-hook-git-check.sh`) and `.claude/hooks/stop.sh` ("stop blocked 1/3"); stop 2 (`stop_hook_active` true) blocked by `stop.sh` only, the platform hook let it pass [MEASURED: untracked probe-red.txt, two turn ends → 2 "Stop hook feedback" continuations + hook log lines, 2026-10-06 23:27Z, CC 2.1.292, Opus 5.5 high, n=2].
- Stop hook give-up: in `claude -p` (temp copy, untracked file, plan mode) the turn was blocked 3×, then allowed with a `hook_system_message` "Stop hook gave up after 3 blocks"; num_turns 4 [MEASURED: claude -p --model claude-sonnet-5-5 --effort low --permission-mode plan --max-turns 8 --max-budget-usd 1 → transcript: 3× hook_blocking_error, 1× hook_system_message; model claude-sonnet-5-5, effort low; 0.089 / 0.091 USD, 2026-10-06, CC 2.1.292, n=2]. Not measured on the interactive path (it would end this unattended session).
- Stop hook lets the turn end when green, and SessionStart output reaches context: `claude -p` from the repo root quoted the hook's `date -u:` and `branch` lines verbatim; transcript has `hook_success` SessionStart; hook log "green allow" [MEASURED: claude -p --model claude-sonnet-5-5 --effort low --permission-mode plan --max-turns 1 --max-budget-usd 1 → model claude-sonnet-5-5, effort low, 0.063 USD each, 2026-10-06, CC 2.1.292, n=2]. Not the interactive path.
- Nested `claude -p` inherits `CLAUDE_CODE_SESSION_ID`, so its hooks receive the parent's `session_id`: the Stop hook counter file (keyed by session_id) is shared between the session and nested runs [MEASURED: env + hook log sid=3052a50d… for both, 2026-10-06, CC 2.1.292, n=4]. Runs in another directory write their transcript under that directory's `~/.claude/projects/` folder [MEASURED: ls ~/.claude/projects, n=2].

## 2026-10-06 — Auto mode classifier blocks Claude from changing its own instructions, even on the owner's request
- After the owner told Claude to merge to `main` itself, two actions were denied with reason `[Self-Modification]`: editing CLAUDE.md to record a standing approval to merge, and then fast-forwarding `main` with a branch that changes CLAUDE.md [MEASURED: 2 auto mode classifier denials, 2026-10-06, CC 2.1.291, Opus 5.5, n=2]. Consistent with O0 §4 (protected paths always go to the classifier). Ordinary edits to CLAUDE.md requested by the owner were allowed in the same session (n=3).
- Consequence: the owner merges changes into `main` on GitHub. Whether merges touching only `knowledge/` pass the classifier is unverified.

## 2026-10-06 — Glob and Grep present as dedicated tools
- In this cloud session (CC 2.1.291, Linux) the tool list contained `Glob` and `Grep` [MEASURED: session tool list, 2026-10-06, CC 2.1.291, Opus 5.5, n=1]. Related open conflict in CLAUDE.md ("Glob/Grep on Linux", O1 §2) stays open until confirmed across builds.

## 2026-10-06 — Session work is invisible to later sessions until merged into main
- Each cloud session gets its own branch cut from `origin/main` (O0 §7 [SOURCE: CE]; this session: `claude/compassionate-shannon-amdhmm` from `origin/main` 676c5b6 [MEASURED: git branch -r, git log, 2026-10-06]). KB edits and entries in this file reach the next session only after the owner merges them. Rule added to CLAUDE.md "Persistence".
