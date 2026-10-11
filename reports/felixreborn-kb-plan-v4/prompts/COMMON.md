# COMMON — shared by the KB-plan session prompts S1–S5 (FelixReborn)

Every session prompt starts with: "Read `docs/prompts/COMMON.md` in full, then this prompt in full, before any other action." `CLAUDE.md` wins over this file; this file wins over nothing else. The plan is `docs/prompts/PLAN.md`; read it only when a prompt says so.

## The three goals (every step serves one; do not add anything that serves none)
G1: Claude returns to the knowledge base for every topical question, not only the first. G2: the base does not go stale unnoticed. G3: agents know where things are. Threat model: laziness, shortcuts, forgetting — not deliberate circumvention. Do not build defences beyond the prompt; an idea outside it goes in one line of the reply, not into code.

## Reading
- "Read in full": the Read tool without `offset`/`limit`, or exactly `cat <path>` (no pipes, no `;`) for a file ≤ 28,000 bytes. Bash shows at most ~30,000 characters inline; a larger file through `cat` shows you only a 2 KB preview (`docs/import/probes-2026-10-11.md` P0, R0).
- Lists headed "Read in full" are whole files; "Read in part" names the range, and the reply says it was partial. Do not read beyond the lists "to be safe"; a listed file that is missing: stop and report.
- The knowledge base and `docs/import/` findings beat your memory; when they disagree, say so.

## Agents
- Agents see only their prompt, `CLAUDE.md` (general-purpose; not Explore) and, once S1 is merged, `.claude/agent-rules.md` + the map injected at start. Put into every agent prompt: goal; files to read in full; constraints (English in files, evidence tags, no self-report as evidence, no quotas, "nothing found" is a valid result); output path; done criterion; "edit nothing outside your output path(s)".
- Agents do not know `$SCRATCH` or any variable of yours: write absolute paths into their prompts.
- Every Agent call sets `model` and `effort` (the prompt names them). Launch independent agents in one message. Two agents never edit the same file. Agents cannot ask the owner and a classifier denial does not stop them: decide before launching.
- The **reviewer** (one per session where the prompt names it; `model: "opus"`, `effort: "high"`): give it the session prompt, the criteria and the diff as files (`git diff origin/main...HEAD > "$SCRATCH/review/diff.patch"` plus one patch per changed file; Bash output is cut at ~30,000 chars, so the reviewer reads the patch files with Read; the whole diff may exceed Read's 256 KB limit, so point it at the per-file patches). Its task: "Report only (a) factual errors — a claim, number or mechanism that contradicts a cited knowledge file or source, quote both — and (b) done-criteria that fail when you check them. Per finding: file:line, what is wrong, evidence, fix. Nothing else; 'nothing found' is valid." You fix (a) and (b) findings.
- Nested `claude -p` runs (tests, probes) are not agents: each sets `--model claude-opus-5-5 --effort low --permission-mode acceptEdits --max-turns <n> --max-budget-usd 0.5 --output-format json`, starts at the root of a detached worktree in the scratchpad (commit first; `git worktree add --detach "$SCRATCH/kbtest" HEAD`), so the worktree's own `.claude/settings.json` loads (O0 §4: project hooks load only from the start directory). Read results from JSON and transcripts with `jq`, never from the model's words. Bash calls longer than ~90 s: `timeout` up to 600 s.

## Evidence and state
- Evidence tags as in `knowledge/CLAUDE.md` (from S1). New facts: `[MEASURED: command → result, date, CC version, model, n]`, `[SOURCE: URL, date]`, `[CL x.y.z, date]`, `[ASSUMPTION]`. A number without a run is an estimate and says so. A step not run is NOT RUN.
- "Done" = every command in the prompt's "Done when" exits as stated; paste their last lines into the reply.
- New measurements go to `docs/FINDINGS.md` with tag and n.
- `$SCRATCH` = the session scratchpad named in the system prompt; temporary checkouts, bare remotes and patch files live there, never in the repository.

## End of every session
Run `/dostawa` (from S1 on; S1 runs its steps by hand as its last task). `STATUS.md` "Next task" names the next prompt file (`docs/prompts/S<n+1>-….md`) with model Opus 5.5, effort high. Reply per `CLAUDE.md` "Owner rules": Polish, what is done and verified, NOT RUN, the reviewer's verdict in one line, open questions last.
