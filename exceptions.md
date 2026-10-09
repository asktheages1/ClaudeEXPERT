# Exceptions

Exceptions to general rules (documented behavior, KB facts, usual patterns) found while working on a task and confirmed by facts. Not for exceptions to the owner's instructions or to CLAUDE.md. Newest first.
Format: `## YYYY-MM-DD — rule → exception`, then:
- General rule, with its source (KB § + tag, or docs URL).
- Observed exception, with evidence (mandatory): `[MEASURED: command → result, date, CC version, model, n]` or `[SOURCE: URL, date]`.
- Scope: when it applies, and what is still unverified.

## 2026-10-09 — each `claude -p` run gets its own session → nested `claude -p` in a cloud session reuses the parent's `session_id`
- General rule: a `claude -p` run without `--resume`/`--continue` starts a new session and returns its own `session_id` [SOURCE: code.claude.com/docs/en/headless.md; O3 §headless].
- Observed exception: two fresh nested runs (no `--resume`) started from this cloud session reported `session_id` = the parent session's ID `38e43983-…` in both the init and the result events; the environment has `CLAUDE_CODE_SESSION_ID` set [MEASURED: `claude -p ... --output-format stream-json` → init/result `session_id` equal to the parent's, 2026-10-09, CC 2.1.295, Opus 5.5, n=2]. Consistent with O0 §1 note that the window transcript also gets entries of nested `claude -p` (U5-31).
- Scope: cloud session, nested runs inheriting `CLAUDE_CODE_SESSION_ID`. Consequence: hook state keyed by `session_id` (flag files, logs) is shared between the parent and every nested run. Unverified: whether `env -u CLAUDE_CODE_SESSION_ID claude -p` gets a fresh ID, and behavior on a local machine.

