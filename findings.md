# Findings

Important findings, crucial information and notable interactions from sessions. Newest first.
Format: `## YYYY-MM-DD — title`, then the fact with its evidence tag (see CLAUDE.md "Evidence tags"). Promote confirmed, general facts to `knowledge/` (with the owner's approval) and note it here.

## 2026-10-06 — Sonnet 5.5 default effort: the "open conflict" is two different surfaces
- Claude Code: "`high` on every model that supports effort, except that Opus 5.5 and Sonnet 5.5 default to `medium`" [SOURCE: https://code.claude.com/docs/en/model-config, line 599 of the fetched .md, 2026-10-06].
- Claude API: `high` is "The default on every model that supports effort except Claude Opus 5.5" [SOURCE: https://platform.claude.com/docs/en/build-with-claude/effort, 2026-10-06]; Sonnet 5.5 prompting page: "Start at `high`, the default on the Claude API" [SOURCE: …/prompt-engineering/prompting-claude-sonnet-5-5, 2026-10-06].
- So O0 §5 (medium) describes Claude Code and O5 §1 (high) describes the API. Not yet applied to the KB or to the CLAUDE.md "Known open conflicts" list: both edits need the owner's approval.

## 2026-10-06 — Subagents cannot write report files
- 3 of 3 `general-purpose` subagents asked to save `report.md` in the scratchpad got Write refused: "Subagents should return findings as text, not write report files. Include this content in your final response instead." [MEASURED: subagent reports, 2026-10-06, CC 2.1.292, Opus 5.5, n=3].
- Consequence: do not ask agents to save their report as a file; their final message is the only copy. Other scratch files (downloaded pages, scripts) were written without problems.

## 2026-10-06 — Subagents without an effort setting ran at session effort
- Three `general-purpose` subagents launched with `model: opus` and no effort ran as `claude-opus-5-5` with `effort: xhigh` in every assistant entry; the session had `CLAUDE_EFFORT=xhigh` [MEASURED: jq over the agents' JSONL transcripts, 118–162 entries each, 2026-10-06, CC 2.1.292]. Consistent with O0 §3 ("Subagent without `effort` inherits session").

## 2026-10-06 — add_repo for a public repository denied by the auto mode classifier
- `add_repo anthropics/claude-code access=read` (needed to research GitHub issues for an owner-requested task) → denied with reason `[Permission Grant]` [MEASURED: tool result, 2026-10-06, CC 2.1.292, Opus 5.5, n=1].
- Consequence: community research used WebSearch and WebFetch on public pages instead of GitHub MCP tools. If the owner wants GitHub API access to other repositories in future sessions, they must allow it (permission rule for `mcp__claude-code-remote__add_repo`) or attach the repository themselves.

## 2026-10-06 — Network reach: curl and WebFetch differ in a cloud session (Trusted network)
- curl from the container: reddit.com, old.reddit.com, news.ycombinator.com, hn.algolia.com, simonwillison.net, dev.to, medium.com → `connect_rejected` (HTTP 000); github.com/anthropics/claude-code/issues and api.github.com/repos/anthropics/claude-code → 403 [MEASURED: curl -w %{http_code}, 2026-10-06, CC 2.1.292, n=1 each]. code.claude.com/docs/llms.txt 200, www.anthropic.com/engineering 200.
- WebFetch: www.reddit.com → "Claude Code is unable to fetch from www.reddit.com"; github.com/anthropics/claude-code/issues?q=… → returned issue titles [MEASURED, n=1 each]. A subagent reported status.claude.com and privacy.claude.com → curl 403 and WebFetch `EGRESS_BLOCKED` [subagent report, not re-run].
- WebFetch to news.ycombinator.com, claudeissues.com and dev.to → `{"error_type":"EGRESS_BLOCKED", … "blocked by the network egress proxy."}` [MEASURED, 2026-10-06, n=1 each].
- So WebFetch is subject to the environment's network allowlist (answers O1 §3's open question for this build: yes, it goes through the egress proxy). It still reached a GitHub page of a repository outside the session, which curl could not: curl to GitHub goes through the GitHub proxy scoped to session repositories (O1 §3), WebFetch apparently not. Practical effect on a Trusted network: community forums and most blogs cannot be opened; GitHub issue and discussion pages can.

## 2026-10-06 — Claude Code version newer than the KB snapshot
- `claude --version` → 2.1.292; KB snapshot is 2.1.289–2.1.291 [MEASURED, 2026-10-06]. Changelog 2.1.292 (2026-10-06) adds an `effort` parameter to the Agent tool (see exceptions.md). A subagent counted 28 releases (2.1.263–2.1.292) between 2026-09-06 and 2026-10-06 in the fetched changelog [subagent count, not re-checked].

## 2026-10-06 — Auto mode classifier blocks Claude from changing its own instructions, even on the owner's request
- After the owner told Claude to merge to `main` itself, two actions were denied with reason `[Self-Modification]`: editing CLAUDE.md to record a standing approval to merge, and then fast-forwarding `main` with a branch that changes CLAUDE.md [MEASURED: 2 auto mode classifier denials, 2026-10-06, CC 2.1.291, Opus 5.5, n=2]. Consistent with O0 §4 (protected paths always go to the classifier). Ordinary edits to CLAUDE.md requested by the owner were allowed in the same session (n=3).
- Consequence: the owner merges changes into `main` on GitHub. Whether merges touching only `knowledge/` pass the classifier is unverified.

## 2026-10-06 — Glob and Grep present as dedicated tools
- In this cloud session (CC 2.1.291, Linux) the tool list contained `Glob` and `Grep` [MEASURED: session tool list, 2026-10-06, CC 2.1.291, Opus 5.5, n=1]. Related open conflict in CLAUDE.md ("Glob/Grep on Linux", O1 §2) stays open until confirmed across builds.

## 2026-10-06 — Session work is invisible to later sessions until merged into main
- Each cloud session gets its own branch cut from `origin/main` (O0 §7 [SOURCE: CE]; this session: `claude/compassionate-shannon-amdhmm` from `origin/main` 676c5b6 [MEASURED: git branch -r, git log, 2026-10-06]). KB edits and entries in this file reach the next session only after the owner merges them. Rule added to CLAUDE.md "Persistence".
