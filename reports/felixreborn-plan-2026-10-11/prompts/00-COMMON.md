# COMMON — rules shared by every FelixReborn KB session prompt (v2, after two prompt reviews)

Every session prompt `Sxx-*.md` starts with: "Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action." This file is the contract between the session and the owner.

Precedence: `CLAUDE.md` > dated owner decisions in `docs/OWNER-RULES.md` > a session prompt where it says "this session is the exception" > this file. The owner decisions S00 requires (precondition 0) name the skeleton lines they override, so the two never conflict in practice.

## 0. Repository layout assumed by the prompts
```
CLAUDE.md  STATUS.md  MAPA.md  CHANGELOG.md
docs/      FINDINGS.md BACKLOG.md OWNER-RULES.md TESTS.md prompts/ reviews/ gatelogs/ import/
docs/import/FINDINGS-claudeexpert.md     (history from the source repository; never a KB content file)
knowledge/ (the knowledge base: O0–O5 before S01, topic files after; CLAUDE.md map, STATE.md, phase.txt, topics.json)
tools/     kb_check.py verify_reads.py kb_build.py kb_topics.py kb_migrate.py kb_migrate_check.py kb_freshness.sh test_hooks.sh export_template.py
tests/fixtures/ (recorded hook payloads)  tests/kb_check/  tests/topics/  tests/freshness/
.claude/   settings.json hooks/ agents/ rules/ agent-rules.md kbgate/ (gitignored)
.github/workflows/kb-check.yml
Warsztat/  (drafts, committed)  Warsztat/_scratch/ (gitignored)  Gotowe/ (generated export)
```
"The scratchpad" = the session scratchpad directory the harness names at start (cloud) or `_tmp/` (PC). Temporary checkouts and probe remotes live there, never in `/tmp` directly.

## 1. How to read (this is the whole point of the project)
- "Read in full" = the **Read tool with no `offset` and no `limit`** for files over 28,000 bytes; for files up to 28,000 bytes `cat <path>` alone (no pipes, no `;`) is equivalent. A `cat` of a larger file shows you a 2 KB preview while the hook log records 30,000 characters [MEASURED 2026-10-11, n=2]; the auto-mode harness tells you to prefer `cat`, so this rule decides when it is allowed.
- Lists headed "Read in full" contain only whole files. Partial reads are listed under "Read in part" with the range, and you say in the reply that they were partial.
- A second Read of an unchanged file returns `file_unchanged` with no content; fine while the content is still in your context. After a compaction: `cat` (≤ 28 KB) or Read in parts with `offset`, because whether the stub resets after compaction is unverified until S07.
- Files named by the read gate (once live) count as listed: read them first.
- Do not read beyond the lists "to be safe"; do not skip a listed file. A listed file that is missing: stop and report; never substitute.
- The knowledge base beats your memory; when they disagree, the base wins and you say so.
- At start, print your model and effort (`echo $CLAUDE_EFFORT`; `get_session` if available) and say in the reply whether they are Opus 5.5 / high; continue either way.

## 2. Agents
- Agents see their own prompt plus `CLAUDE.md` (general-purpose, workflow) and, from S08, the map and `agent-rules.md` injected at start; Explore and `omitClaudeMd` agents get only the injection and the nested `knowledge/CLAUDE.md` on first touch (from S06). Nobody but you sees this prompt, the owner's rules or the conversation. Put into each agent prompt: goal; exact files to read (with the §1 rule); constraints (English in the repository, evidence tags, no self-report, no quotas, "nothing found" is a valid result); output path; done criterion; named stops; "edit nothing outside your output path".
- Every Agent call sets `model` and `effort`. Workers: `model: "opus"`, `effort: "high"`; probes: `effort: "low"`; reviewers: §4. Fable only as a reviewer. Once per session, read one agent's real model and effort from its transcript (the Agent tool names the agent's output file; that file is its JSONL transcript) and record them.
- Never more than 15 agents in a session, reviewers included; agents started inside a nested `claude -p` count too. Launch independent agents in one message. Two agents never edit the same file; one owner per file.
- Agents cannot ask the owner and a classifier denial does not stop them: decide everything before launching.
- **Verified reading.** After every agent wave and before launching the reviewers, run `python3 tools/verify_reads.py <transcript.jsonl> <file>...` (built in S00) on each agent's transcript and on your own (`ls -t ~/.claude/projects/*/*.jsonl | head -1`, or the `transcript_path` a hook payload gives) for every file its prompt listed as "Read in full". It applies the same full-read rule as the S08 logger. A failed check means the agent is re-run with a sharper prompt; paste the tool's summary line into the reply.
- Nested `claude -p` runs (probes) are not agents. Each sets `--model`, `--effort`, `--permission-mode`, `--max-turns`, `--max-budget-usd`, `--output-format json`, and runs from a detached worktree in the scratchpad: commit first, then `git worktree add --detach "$SCRATCH/kbtest" HEAD`; `--settings` and any hook paths are absolute paths into the main checkout. Runs longer than ~90 s: give the Bash call a `timeout` (≤ 600 s) or run it in the background and wait.

## 3. Evidence, state, git
- Evidence tags (the legend the base uses; a line in `knowledge/` without one of these is untagged): `[MEASURED: command → result, date, CC version, model, n]`, `[CODE: location]`, `[SOURCE: URL, date]`, `[OF]`, `[S:page]`, `[S:page*]` (search excerpt, medium confidence), `[CL x.y.z, date]`, `[BLOG]`, `[IS]` (GitHub issue), `[3P]`, `[UNCERTAIN]`, `[ASSUMPTION]`, `[UNTAGGED: needs source]` (temporary, listed in BACKLOG). Precedence when sources disagree: `[MEASURED]`/`[CODE]` for the current version > `[OF]`/`[CL]` > `[BLOG]` > `[IS]` > `[3P]` > `[ASSUMPTION]`; newer date wins within a level.
- A number without a run is an estimate and says so. "Done" = the listed commands exit 0 and their last lines are in the reply; a step not run is NOT RUN.
- `kb_check.py` phases are ordered and cumulative: `0 < 1a < 1 < 1b < 1c < 2`; `--phase N` runs N and every earlier phase; no `--phase` = the phase in `knowledge/phase.txt`.
- Before ending: `verify_reads.py` on your own transcript; from S08 on, copy `.claude/kbgate/*.jsonl` to `docs/gatelogs/<Sxx>/` and commit; `STATUS.md` rewritten (version, this session, done, next task, decisions waiting for the owner, **Live mechanisms** with "cloud only" where true, a **Step SHAs** table with this session's final commit); `CHANGELOG.md` line; `docs/FINDINGS.md` entries for anything measured; commit; push the branch; then `git tag kb-step-<Sxx> && git push origin kb-step-<Sxx>` (if the proxy refuses the tag, NOT RUN; the SHA in STATUS is the record). The VM is disposable.
- `Warsztat/` is committed (later sessions depend on it); `Warsztat/_scratch/` is not.
- English in every repository file; Polish only in the chat reply and in files named `RAPORT-*.md`.
- Never edit `CLAUDE.md` (S13 is the stated exception): write `Warsztat/proposed/CLAUDE.md.<Sxx>.diff` (one numbered patch per session) and name it in the reply. Never touch `main`. A classifier refusal on `.claude/` or `CLAUDE.md`: write the intended content to `Warsztat/proposed/<same relative path>`, commit it, and tell the owner which file to copy on GitHub; tests still run via `--settings` on that copy.

## 4. End-of-session review (mandatory, every session)
Before the reviewers: `git diff origin/main...HEAD --stat > Warsztat/_scratch/review/<Sxx>-stat.txt`; `git diff origin/main...HEAD -- . ':!Warsztat/_scratch' > Warsztat/_scratch/review/<Sxx>-diff.patch`; one patch per changed file under `Warsztat/_scratch/review/<Sxx>/`. Then launch two reviewers **in one message**, both `subagent_type: "general-purpose"`:
- `model: "fable"`, `effort: "high"`;
- `model: "opus"`, `effort: "xhigh"`.
Prompt for each (fill the brackets):
```
You are an independent, skeptical reviewer of one work session in this repository. You did not see the session. Edit nothing except docs/reviews/[Sxx]-[fable|opus].md; run no build or generator script; running read-only checks is allowed.
Read in full (Read tool, no offset/limit unless the file is over 25,000 tokens, then in parts and say which ranges): docs/prompts/00-COMMON.md; docs/prompts/[Sxx].md; [the KB files this session touched or relied on]; the docs/FINDINGS.md entries of this and the previous session.
Read the diff from the patch files in Warsztat/_scratch/review/[Sxx]/ (never through Bash: inline output is cut at ~30,000 characters); report which files and ranges you read.
Check, in this order, and write docs/reviews/[Sxx]-[fable|opus].md:
1. Omissions: anything the session prompt required that the diff does not show. Quote the prompt line.
2. Knowledge-base conformance: every mechanism, claim or number in the diff that contradicts a KB file or has no evidence tag. Quote the KB file and section.
3. Done criteria: run every "done" command yourself; report exit codes. A criterion you cannot run: NOT RUN.
4. Shortcuts: a partial read reported as full, a skipped test, a self-report instead of a run, a tag without a run, a cap "adapted" to pass.
5. Findings entries: evidence present, n stated, no claim beyond the measurement.
Per finding: severity (blocking / important / minor), file:line, what is wrong, evidence, fix. "Nothing found" is valid per category. Do not pad. Reply with the verdict and the ranked top 5.
```
Then: fix or reject every finding with evidence (a rejection names the file and section that proves the reviewer wrong), re-run the done commands, and only then write `STATUS.md`, commit, push, tag.

## 5. Reply format
Polish, per `CLAUDE.md` "Owner rules" (its ending sections apply). Lead with what is done and verified, then NOT RUN, then the reviewers' verdicts in one line each, then `verify_reads.py` summary lines, then the full prompt for the next session as one copyable block (if known), then open questions under `## ❓ Pytanie do Ciebie`. No paths in the prose unless the owner must open the file.
