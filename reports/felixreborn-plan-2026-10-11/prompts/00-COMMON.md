# COMMON — rules shared by every FelixReborn KB session prompt

Every session prompt `Sxx-*.md` starts with: "Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action." This file is the contract between the session and the owner. Where it conflicts with `CLAUDE.md`, `CLAUDE.md` wins; where `CLAUDE.md` is silent, this file applies.

## 0. Repository layout assumed by the prompts
```
CLAUDE.md  STATUS.md  MAPA.md  CHANGELOG.md
docs/      FINDINGS.md BACKLOG.md OWNER-RULES.md TESTS.md prompts/ reviews/
knowledge/ (the knowledge base: O0–O5 before S01, topic files after; CLAUDE.md map, STATE.md, topics.json)
tools/     kb_check.py kb_build.py kb_migrate.py kb_migrate_check.py kb_freshness.sh test_hooks.sh export_template.py
tests/fixtures/   (recorded hook payloads, one JSON per event)
.claude/   settings.json hooks/ agents/ rules/ agent-rules.md
.github/workflows/kb-check.yml
Warsztat/  (drafts)   Gotowe/ (generated export, never edited by hand)
```
If the layout differs, adapt paths and say so in the reply; never silently invent a parallel structure.

## 1. How to read (this is the whole point of the project)
- A file named in "Read in full" is read with the **Read tool, no `offset`, no `limit`**. Not `cat`: in this environment a `cat` of a file over ~30,000 characters shows you a 2 KB preview while the hook log records 30,000 [MEASURED 2026-10-11, n=2]. For files under 28,000 bytes `cat <path>` (alone, no pipes) is acceptable.
- A second Read of an unchanged file returns `file_unchanged` with no content; that is fine when the content is still in your context. After a compaction it is not: re-read.
- Do not read "to be safe" beyond the list; do not skip anything on the list. If a listed file is missing, stop and report; do not substitute.
- Knowledge-base facts beat your memory. If you "know" something that contradicts a KB file, the KB wins and you say so.

## 2. Agents
- You are the only one who sees this prompt, the owner's rules and the conversation. Every agent sees only its own prompt plus `CLAUDE.md` (general-purpose, workflow) or nothing (Explore, `omitClaudeMd`). Put into each agent prompt: goal; exact files to read in full (with the Read-tool rule from §1); constraints (English in the repository, evidence tags, no self-report, no quotas, "nothing found" is a valid result); output path; done criterion; named stops.
- Every Agent call sets `model` and `effort` explicitly. Defaults for this project: workers `model: "opus"`, `effort: "high"`; probes `effort: "low"`; reviewers see §4. Fable only as a reviewer.
- Never more than 15 agents in a session, the two reviewers included. Launch independent agents in one message so they run concurrently.
- Agents cannot ask the owner and a classifier denial does not stop them: decide everything before launching; tell them to list open questions in their report.
- Nested `claude -p` runs (probes) are not agents. Every one sets `--model`, `--effort`, `--permission-mode`, `--max-turns`, `--max-budget-usd`, and runs from a separate checkout (`git worktree add /tmp/kbtest <branch>`), never from the repository root once hooks exist.

## 3. Evidence, state, git
- Every fact written to `knowledge/` or `docs/FINDINGS.md` carries a tag: `[MEASURED: command → result, date, CC version, model, n]`, `[SOURCE: URL, date]`, `[CL x.y.z, date]`, `[ASSUMPTION]`. A number without a run is an estimate and says so.
- "Done" means the listed commands exit 0 and you pasted their last lines into the reply. A step you did not run is reported as NOT RUN.
- From S08 on, before ending: copy the gate logs `.claude/kbgate/*.jsonl` to `docs/gatelogs/<Sxx>/` and commit them (the VM directory does not survive; S12 analyses them).
- Before ending: `STATUS.md` rewritten (version, this session, done, next task, decisions waiting for the owner, **Live mechanisms** list), `CHANGELOG.md` line, `docs/FINDINGS.md` entries for anything measured, commit, push to the session branch. The VM is disposable.
- English in every file in the repository; Polish only in the chat reply and in files whose name starts with `RAPORT-`.
- Never edit `CLAUDE.md` yourself: write the proposed diff to `Warsztat/CLAUDE.md.proposed.diff` and name it in the reply. Never touch `main`.

## 4. End-of-session review (mandatory, every session)
After the work and before `STATUS.md`, launch two reviewers **in one message**, both `subagent_type: "general-purpose"`:
- `model: "fable"`, `effort: "high"`;
- `model: "opus"`, `effort: "xhigh"`.
Prompt for each (fill the brackets):
```
You are an independent, skeptical reviewer of one work session in this repository. You did not see the session.
Read in full, with the Read tool and no offset/limit: docs/prompts/00-COMMON.md; docs/prompts/[Sxx].md; [the KB files this session touched or relied on]; docs/FINDINGS.md.
Then run: git diff origin/main...HEAD --stat; git diff origin/main...HEAD (read all of it).
Check, in this order, and write docs/reviews/[Sxx]-[fable|opus].md:
1. Omissions: anything the session prompt required that the diff does not show. Quote the prompt line.
2. Knowledge-base conformance: every mechanism, claim or number in the diff that contradicts a KB file or has no evidence tag. Quote the KB file and section.
3. Done criteria: run every "done" command yourself if you have Bash; report exit codes. A criterion you cannot run: say NOT RUN.
4. Shortcuts: places where the session rounded in its own favour (partial read reported as full, a test skipped, a self-report instead of a run, a tag without a run).
5. Findings entries: evidence present, n stated, no claim beyond the measurement.
Per finding: severity (blocking / important / minor), file:line, what is wrong, evidence, fix. "Nothing found" is a valid result for a category. Do not pad. Reply with the verdict and the ranked top 5.
```
Then: fix or reject every finding with evidence (a rejection names the file and section that proves the reviewer wrong), re-run the done commands, and only then write `STATUS.md`, commit, push.

## 5. Reply format
Polish. Lead with what is done and verified, then what is NOT RUN, then the reviewers' verdicts in one line each, then the full prompt for the next session as one copyable block (if the next session is known), then open questions in the `## ❓ Pytanie do Ciebie` format from `CLAUDE.md`. No paths in the prose unless the owner must open the file.
