# Open items

Decisions waiting for the owner and facts still unverified. Read at every session start (SessionStart hook).
Keep under 8,000 bytes: remove items once decided or verified. Newest first.

## Waiting for the owner's decision
- KB update proposal (2026-10-06): add to O0 §2 the measurement that a 2 MB CLAUDE.md loads in full, 526–620k tokens depending on content (52–62% of a 1M window), no truncation [MEASURED: findings.md 2026-10-06, CC 2.1.292, Sonnet 5.5, n=2 files].

## Known open conflicts in the KB (never resolve silently; offer to measure)
- Sonnet 5.5 default effort: O0 §5 says medium, O5 §1 says high.
- Workflow concurrency: O0 §3 gives `min(16, max(2, CPU−2))` from the binary [CODE] and measured 2 at 4 CPU; docs say "up to 16, fewer with fewer CPUs" (O3).
- Workflow agent cache TTL: O3 says 5 min by default even on subscriptions; check against O0 §3.
- Haiku 4.5 retirement: O0 says not before 2026-10-15; O5 says not before ~2026-12-05.
- Glob/Grep on Linux (O1 §2): depends on build; this build had both (findings.md 2026-10-06).

## Unverified
- Whether Claude Code prints the "CLAUDE.md too long" warning (O0 §6 T5-S-04) for a 2 MB file: not visible in the `claude -p "/context"` JSON result (2026-10-06).
- Whether a merge into `main` that touches only `knowledge/` passes the auto mode classifier (findings.md 2026-10-06).
