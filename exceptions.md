# Exceptions

Exceptions to general rules (documented behavior, KB facts, usual patterns) found while working on a task and confirmed by facts. Not for exceptions to the owner's instructions or to CLAUDE.md. Newest first.
Format: `## YYYY-MM-DD — rule → exception`, then:
- General rule, with its source (KB § + tag, or docs URL).
- Observed exception, with evidence (mandatory): `[MEASURED: command → result, date, CC version, model, n]` or `[SOURCE: URL, date]`.
- Scope: when it applies, and what is still unverified.

## 2026-10-06 — `$CLAUDE_EFFORT` is the actual effort → at SessionStart of a nested `claude -p` it is the parent's value
- General rule: actual effort can be read from the `effort` field of the transcript or `$CLAUDE_EFFORT` (O0 §5 T4-15, T4-19 [MEASURED]); a nested `-p` does not inherit the parent's effort (O0 §5 U4-18 [MEASURED]).
- Exception: in a nested `claude -p … --effort low` started from a session whose `CLAUDE_EFFORT=high`, a SessionStart hook saw `CLAUDE_EFFORT=high` and no `effort` field in its input, while the Stop hook of the same run saw `CLAUDE_EFFORT=low` and `effort.level=low` [MEASURED: `claude -p "Reply with the single word OK." --settings settings.json --model claude-sonnet-5-5 --effort low --permission-mode plan --max-turns 1 --max-budget-usd 0.2` with a hook logging `$CLAUDE_EFFORT` and `.effort` → `SessionStart env_CLAUDE_EFFORT=high input_effort="absent"`, `Stop env_CLAUDE_EFFORT=low input_effort={"level":"low"}`, 0.045 USD, 2026-10-06, CC 2.1.292, n=1].
- Scope: the variable is set by the child only after SessionStart; any SessionStart hook (also in the main session) reports an inherited or stale value. Read effort from a later hook's input or the transcript. Unverified: whether the main cloud session's SessionStart sees the launcher's value or none.

