# Exceptions

Exceptions to general rules (documented behavior, KB facts, usual patterns) found while working on a task and confirmed by facts. Not for exceptions to the owner's instructions or to CLAUDE.md. Newest first.
Format: `## YYYY-MM-DD — rule → exception`, then:
- General rule, with its source (KB § + tag, or docs URL).
- Observed exception, with evidence (mandatory): `[MEASURED: command → result, date, CC version, model, n]` or `[SOURCE: URL, date]`.
- Scope: when it applies, and what is still unverified.

## 2026-10-06 — "Agent tool has no effort field" → it has one from CC 2.1.292
- General rule: "Agent tool: `model` field (aliases sonnet/opus/haiku/fable only) and `isolation`, NO effort field [CODE: Agent schema]"; an ad hoc subagent gets the session effort (KB O0 §3, §5 "How to set: agent", §8).
- Observed exception: CC 2.1.292 changelog: "Added an `effort` parameter to the Agent tool, so Claude runs a sub-agent at the effort level you ask for" [SOURCE: https://code.claude.com/docs/en/changelog, entry 2.1.292 dated October 6, 2026, fetched 2026-10-06]. This session's Agent tool schema lists `effort` (low…max), with the instruction to set it only when the user or instructions explicitly ask [MEASURED: session tool list, 2026-10-06, CC 2.1.292, Opus 5.5, n=1].
- Scope: CC ≥ 2.1.292. Not used in this session, so unverified: whether a set value shows up in the subagent transcript's `effort` field and how it ranks against agent frontmatter `effort`. KB O0 §3/§5/§8 need an update (owner approval required).
