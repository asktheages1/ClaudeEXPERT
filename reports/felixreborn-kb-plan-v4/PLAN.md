# FelixReborn knowledge-base plan v4 (2026-10-11)

Replaces plan v3 and the FelixReborn plan v2 with its 16 prompts (removed; in git history). Their measurements were kept in `reports/probes-2026-10-11.md`. Target repository: FelixReborn. Input: the owner's skeleton `claude-felixReborn-input.md` (this directory, verbatim).

## 1. The three goals and the cut rule
1. **G1**: Claude does not return to the knowledge base after the first message; it answers later questions from memory.
2. **G2**: The base goes stale and nobody notices.
3. **G3**: Agents do not know where things are.

Everything below serves at least one goal, named in brackets. Anything that served none was cut, not deferred (§9). Threat model: laziness, shortcuts, forgetting. Not deliberate circumvention. The only hard server-side protection is branch protection (O0 §8 [ASSUMPTION from O0 §4, §7]); the owner knows this and the plan adds none.

## 2. Owner decisions of 2026-10-11 (this session)
- Model scope: content about models the owner never uses is removed. Only Opus 5.5 and Fable 5.1 stay, plus traps that bite a user of those two (e.g. `claude -p` without `--model` runs on Sonnet 5.5, O0 §5 [MEASURED]).
- Agents get the map at start **and** a read gate at their end.
- Structure check: the Foldery solution, ported (§3). No GitHub Actions. Claude merges into `main` itself, locally (`merge` + `git push origin main`), so the push gate has something to guard.
- Reviews: one reviewer, Opus 5.5 high, read-only. It reports only factual errors and unmet done-criteria; nothing else is fixed or backlogged.
- Two maps: `MAPA.md` §1 for project docs, `knowledge/CLAUDE.md` for the base. Each file appears in exactly one of them.

## 3. Structure check (ported from `asktheages1/foldery`: `GaleriaFolderow/tools/doc_check.py`, `.claude/hooks/hooks.py`, skill `/dostawa`) [G3, protects G1–G2]
- **`tools/doc_check.py`**: one Python file, standard library only. Exit 1 on any error, 0 otherwise. Warnings never block.
  - Byte caps (UTF-8), all in one function `limits()`; > 100 % = error, 90–100 % = `WARNING`:

    | File | Cap (B) | Reason |
    |---|---|---|
    | `CLAUDE.md` | 20,000 (HTML comments stripped) | skeleton l. 38. At ≥ 90 %: tell the owner, never split |
    | `knowledge/*.md` except the map | 28,000 | must be readable whole with `cat`: Bash shows ≤ ~30,000 chars inline, above that a 2 KB preview (`reports/probes-2026-10-11.md` P0, R0 [MEASURED, n=2]) |
    | `knowledge/O[0-5]-*.md` (until S2 removes them) | 40,000 | their own header budget (O0 header) |
    | `knowledge/CLAUDE.md` (base map) | 6,500 | injected into every agent together with `agent-rules.md`. Per-field limit is 10,000 chars, overflow becomes a 2,000-char preview (O2 §A6 [S:hooks]) |
    | `.claude/agent-rules.md` | 2,500 | same injection |
    | `MAPA.md`, `docs/**/*.md` | 28,000 | read whole with `cat` |
    | `STATUS.md` | 6,000 | skeleton l. 38 |

  - Combined injection (`agent-rules.md` + map without HTML comments) > 9,000 B = error.
  - Maps:
    - Every `knowledge/*.md` except the map has a line in `knowledge/CLAUDE.md`. Every `docs/**/*.md` has a row in `MAPA.md` §1 (`docs/import/` included).
    - First mention carries the size `(N KB)`, checked against the real size with tolerance max(10 %, 1 KB).
    - Unmapped file = error. Dead path = error: a backticked path in a map or in `CLAUDE.md` that starts with `knowledge/`, `docs/`, `tools/`, `.claude/hooks/`, `.claude/skills/` or `.claude/agents/`, ends in a file extension, and does not exist. Narrower than Foldery's rule, so the skeleton's other paths (`.bat`, `_tmp/`, `~/.claude`) are not flagged.
    - A size annotation `(N KB)` outside the two maps (in `CLAUDE.md`, `STATUS.md`, `knowledge/`, `docs/` except `docs/import/`, whose files are frozen history) = error.
  - `knowledge/CLAUDE.md` has a line `As of: Claude Code 2.1.<n> (YYYY-MM-DD)` [G2]; the date is checked from S5.
  - From S2: every map line parses as `- <keywords> → \`<file>\` (N KB) …`. Keywords are comma-separated, case-insensitive; a trailing `*` means "prefix", for Polish stems [G1, G3: the read gate reads them].
  - `--self-test`: one passing and one failing fixture per rule (`tests/doc_check/`).
- **Push gate** (`.claude/hooks/hooks.py bash`, PreToolUse matcher `Bash`, timeout 120):
  - Blocks (exit 2) a `git push` that targets `main` while `doc_check.py` is red. Branch pushes pass, unless the hook itself crashes or times out (fail-closed applies to every `git push`).
  - **Needs the owner's confirmation**: three Foldery rules below also refuse a push to `main` when the checker is green, because the checker would otherwise check something other than what is pushed (push combined with `checkout`/`merge` in one call; a ref other than `HEAD`; uncommitted tracked changes). `/dostawa` always satisfies them.
  - Ported from Foldery `hooks.py`, unchanged:
    - command parser (`segments`, `strip_wrappers`, `git_sub`; covers `git -C`, `env`, `timeout`, `cd`);
    - main-target detection (refspec, `HEAD` on `main`, `checkout main` in the same call);
    - "push to `main` is a separate Bash call";
    - "push `HEAD` only";
    - "clean tracked tree";
    - fail-closed on its own exception;
    - 100 s deadline.
  - Not ported (owner: "only this block"):
    - force-push and history-rewrite blocks;
    - Actions/`.github` checks;
    - the STATUS/CHANGELOG diff rule;
    - `deny` rules of Foldery `settings.json`.
  - Without `python3` (owner's PC) the `exec python3` fails with a non-2 code: the gate is off there, not blocking.
- **End-of-work procedure**: skill `/dostawa`, port of Foldery steps 2, 4, 5:
  1. `doc_check` → `WARNING` on a file changed in this session → split it now. Split at a `##` heading near the middle: `name-1.md` (`git mv`) + `name-2.md`, references and map fixed. `CLAUDE.md` is never split; ≥ 90 % → tell the owner (as in Foldery `/dostawa`).
  2. `tools/tests.sh` green.
  3. `STATUS.md` overwritten, `CHANGELOG.md` line.
  4. Commit named paths, push the branch.
  5. Merge in three separate Bash calls: `git fetch origin main && git checkout -B main origin/main && git merge --no-edit <branch>` / `git push origin main` / `git checkout <branch>`.
  6. If the auto-mode classifier refuses (`CLAUDE.md`/`.claude/` changes: `findings.md` 2026-10-06 [MEASURED, n=2]): `git push --dry-run origin HEAD:main` (same gate, sends nothing), push the branch, open a PR, tell the owner.
- **`tools/tests.sh`** runs `doc_check.py --self-test`, `doc_check.py` and `tools/test_hooks.sh`. `test_hooks.sh` replays fixture JSON (`tests/fixtures/*.json`, fields `_handler`, `_expect_exit`) into `hooks.py`. Push cases run against a temporary repository with a bare `origin` in the scratchpad, never GitHub.

## 4. Maps and injection [G3]
- `knowledge/CLAUDE.md` is a nested CLAUDE.md, so it auto-loads when any file under `knowledge/` is read with Read, or with a single-file `cat`/`head`/`tail`/`sed -n`/`grep` ([CL 2.1.293] in O0 §2; Explore included: `reports/probes-2026-10-11.md` P4 [MEASURED, n=1]).
- Content:
  - what the base is; how to read it (whole file: Read, or exactly `cat <path>` for ≤ 28 KB);
  - the evidence-tag legend;
  - the open-conflicts list (moved from ClaudeEXPERT `CLAUDE.md`);
  - `As of:`;
  - one keyword line per file.
- The map is hand-written; no generator, no `topics.json`.
- **SessionStart** (`hooks.py session`, matcher `startup|resume|compact`): version line, branch vs `origin/main`, top of `STATUS.md`, "health check due" after 90 days of `Last review:` (Foldery `h_session`, ported). From S5: one freshness line.
- **SubagentStart** (`hooks.py subagent`): `additionalContext` = `.claude/agent-rules.md` + `knowledge/CLAUDE.md`. Reaches Explore too (`reports/probes-2026-10-11.md` R6a, C [MEASURED, n=2]); workflow agents are not covered, their prompts repeat the rules (skeleton l. 44).

## 5. Read gates [G1; agents: G1 + G3]
State: `.claude/kbgate/<sha1 of transcript_path>.jsonl` (gitignored), one JSON object per line, append-only. `KBGATE=off` in the environment turns every gate hook into exit 0 (kill switch; the push gate is not affected).
- **Logger**: PostToolUse, matcher `Read|Bash`. For each `knowledge/*.md` read it records `{prompt_id, agent_id?, path, full, sha256}`. Paths are normalised to repo-relative, worktree prefix `.claude/worktrees/<n>/` stripped. `full` is true when:
  - Read: `tool_response.type == "text"`, `file.startLine == 1`, `file.numLines >= file.totalLines` (`reports/probes-2026-10-11.md` P1, A [MEASURED]);
  - Read `file_unchanged` stub (P3): only if a content read of the same file with the same sha256 happened after the last compaction marker;
  - Bash: the command is exactly `cat <path>`, no `persistedOutputPath`, `interrupted` false, `stdout.rstrip("\n") == file_text.rstrip("\n")` (stdout drops the final newline: R6b, A [MEASURED, n=2]).
- **PostCompact** (matchers `manual|auto`, O2 event table): appends a compaction marker. Stubs before it stop counting.
- **UserPromptSubmit**: matches the prompt against the map keywords and records `{prompt_id, required: [≤ 3 files]}`. On a match, stdout (reaches context, O2 §A6) says: "Required reading for this prompt: <files>. Read tool, or exactly `cat <path>`; the Stop hook checks it." Automatic turns also fire this event (O2 event table); they are treated the same.
- **Stop**:
  - required = prompt matches ∪ matches in `last_assistant_message`, at most 3 files;
  - met = a `full` read of each file under this `prompt_id` without `agent_id`;
  - unmet → exit 2, stderr: "Read <file> in full (Read tool; after a compaction exactly `cat <path>`) and check your answer against it; state corrections." At most 3 blocks per `prompt_id`; then exit 0 with a `systemMessage` to the owner ("read gate gave up on <file>"). The built-in cap is 8 consecutive blocks (O2 §A5 [S:hooks-guide]).
  - Do **not** exit early on `stop_hook_active` (the KB's example in O2 §A8 does, which would make this a one-shot gate). The per-`prompt_id` counter (and per-`agent_id` below) is the cap.
  - "Per prompt" is what G1 means: every topical question triggers a fresh read. A repeated Read of an unchanged file costs only the stub's tokens (P3); after compaction the content must really come back (Read with content or `cat`). [ASSUMPTION: whether the stub persists after compaction and whether PostCompact fires on auto-compaction are not measured; fixtures only.]
- **SubagentStop** (agents):
  - gated agent types: `general-purpose` and agents defined in `.claude/agents/`; not Explore, Plan or `claude-code-guide` (navigation and planning helpers that read excerpts by design; the main session that uses their answer is gated at Stop);
  - required = keyword matches in the agent's first user message, read from `agent_transcript_path` (it held the prompt at SubagentStop: P2, R6 [MEASURED, n=2]);
  - met = `full` reads logged with that `agent_id` (subagent events carry `agent_id`: P1 [MEASURED]);
  - unmet → exit 2 with the same message; at most 2 blocks per `agent_id`. The SubagentStop block cap is undocumented, so the plan uses its own counter. Transcript missing or without a user message: retry once after 1 s, then pass with a logged warning.
- `agent-rules.md` tells agents the same rule up front, so the gate is a backstop, not a surprise.
- Not covered (written into `CLAUDE.md` "Enforcement and its limits" in S4):
  - workflow agents;
  - sessions with several repositories, and `claude -p` started outside the root (no project hooks: O0 §4, §7);
  - prompts without a keyword;
  - "read" is not "understood".

## 6. Freshness [G2]
- **S3** builds skill `/kb-update` and runs it once to catch up. Steps:
  1. Changelog delta since `As of:`.
  2. Links in `llms.txt` not yet present in `knowledge/docs-index.md`.
  3. Triage → per-file edits (old fact replaced, never appended).
  4. Model-scope pass.
  5. `As of:` moved, with today's date.
  6. Commit and push the branch (an attended session then runs `/dostawa`; the Routine stops here).
- Agent use scales with the delta: triage by the main window up to ~100 bullets, above that one triage agent per ~100 bullets (max 4); edits by the main window up to ~30 rows and ~5 pages, above that editor agents as in S3.
- **S5**:
  - SessionStart freshness line: local `claude --version` vs `As of:` and days since the `As of:` date. `KB: STALE` at ≥ 3 versions or > 30 days. Plus `kb-update: <n> commits ahead of main` when that branch exists. No HTTP at start (the `git fetch` with timeout that the start hook already does is allowed).
  - A weekly Routine (a scheduled cloud session) runs `/kb-update` on a fixed branch `kb-update`. It pushes that branch and **does not merge**: unattended KB edits wait for an attended session, which the start line tells about them; the Routine also sends a push notification.

## 7. Sessions and agents
One session = one prompt = one branch, merged into `main` by `/dostawa`. The next session starts after the merge. Main window: Opus 5.5 high. The agents named in each prompt are approved with this plan (skeleton l. 45: "several agents … the owner's yes").

| Session | Goal | Main window | Agents (type · model · effort) | Reviewer |
|---|---|---|---|---|
| S1 tooling | G3 + protection | inputs copied in; state files; `doc_check.py`; `hooks.py` (push gate, session, subagent); settings; tests; `/dostawa`; `reviewer.md`; interim map of O0–O5; `CLAUDE.md` edits | none | 1 (general-purpose · opus · high; `reviewer.md` exists only from S2, O0 §3) |
| S2 migration | G3, G1 | `migration-map.tsv`, `kb_migrate.py` + check (every line exactly once, fact-ID multiset unchanged), references rewritten, O0–O5 deleted, keyword map | 2 navigation probes (1 general-purpose, 1 Explore · opus · low): 3 questions each, first `knowledge/` read checked in the transcript | 1 (`reviewer` · opus · high) |
| S3 update | G2 | `/kb-update`, delta, triage merge and check, `docs-index.md`, `recheck-and-conflicts.md`, `design-rules.md`, map sizes, model-scope grep | triage: 1 per ~100 bullets, max 4 (general-purpose · opus · high); editors: 6, one owner per file pair, each applies its triage rows and fetches its new pages (general-purpose · opus · high) | 1 (`reviewer` · opus · high) |
| S4 read gates | G1, G3 | logger, PostCompact, UserPromptSubmit, Stop, SubagentStop, fixtures, live tests in nested `claude -p` (not agents) | none outside the nested runs | 1 (`reviewer` · opus · high) |
| S5 freshness | G2 | SessionStart line, Routine (created after the owner's yes in session), `CLAUDE.md` health-check line | none | none: advisory line + Routine spec, no constraining mechanism (skeleton l. 5 asks review of mechanisms) |

Total: 12 agents + up to 4 reviewers (plan v3/v2: 70).

Cost [ASSUMPTION; list prices; scale from `findings.md` 2026-10-08, 3.6–8.1 USD per heavy single-file session]:
- S1 5–10 USD; S2 4–8; S3 25–55; S4 6–12; S5 2–4.
- **≈ 40–90 USD** in total; Routine 1–5 USD per week.

## 8. FelixReborn `CLAUDE.md`: what each session changes
The file is 17,986 B (CRLF), just under the 90 % warning of its 20 KB cap. Net growth is not possible. Every session's edit removes at least as much as it adds and runs `doc_check` (≥ 90 % → told to the owner in the reply). Edits go through the auto-mode classifier (may refuse: §3 fallback). Line numbers refer to the input file.

| Line | Session | Change |
|---|---|---|
| 5 | S1 | "the owner has merged the PR" → "the work is merged into `main` by `/dostawa` with the push gate green" (merge policy A, owner 2026-10-11) |
| 7 | S1 | add: mechanisms that must run (hooks, settings, checker) live at the repository root, the only place Claude Code loads them (O0 §4); promotion to `Gotowe/` is outside the KB plan |
| 22–24 | S1 | SessionStart line describes the real hook. "markdown ≤ 40 KB fits one Read" → "≤ 28 KB: read whole with Read or exactly `cat <path>`". `<docs>` → `docs/`. `<kb>/O0-…` → `knowledge/CLAUDE.md` (auto-loads on first touch of `knowledge/`) |
| 30 | S1 | reviewer: "Fix or reject every finding with evidence; style findings are ignored" → "report only factual errors and unmet done-criteria; everything else is ignored, not backlogged" (owner 2026-10-11) |
| 38 | S1 | caps → the §3 table; `doc_check` → `tools/doc_check.py`; 90 % rule and split procedure → `/dostawa` |
| 44 | S1 | conditional "If a SubagentStart hook injects …" → measured statement, workflow agents excepted |
| 53, 55 | S1 | merge policy A filled in (`/dostawa`). Next step A: "the next task is the „Next task” line of `STATUS.md`; for the KB plan it names `docs/prompts/<Sn>.md`" |
| 48 | S1 | `.claude/agents/implementer.md` → plain text "an implementer agent (not built yet)", otherwise the dead-path rule is red |
| 64–65 | S1 | hard list = only what is live: push to `main` blocked while `doc_check` is red. Placeholders for unbuilt gates removed. Sandbox: "no `bwrap` in the cloud [MEASURED 2026-10-11]" |
| 23–24, 44, 64 | S4 | read gates: one sentence each in "Start of every session", "Agents", "Enforcement and its limits" (+ what is not covered, §5) |
| 68 | S5 | health check: freshness line at start; `/kb-update` |

Not touched by the plan, and still unbacked: the `ask` rules (l. 19), the Stop reminder (l. 18), `<tests script>` beyond `tools/tests.sh`, the implementer agent (l. 48, de-linked in S1), `/<health-check>` (l. 68), force-push / frozen-dir / MCP denials (l. 64 placeholders, removed in S1 as not live).

## 9. Cut, not deferred
- Trusted CI (`pull_request_target`), the "gate files changed" job, GitHub Actions in general.
- Branch protection with admin inclusion; probe of the token's permissions.
- `ask`/`deny` lock on gate files, `ConfigChange`, denial of GitHub MCP write tools, `gh` rules.
- Log-only phase, gate-log commits, baseline sessions, gate analysis.
- PreToolUse "read first" gate, `updatedInput` on Agent, re-read A/B probe.
- Checker phases 0/1a/1/1b/1c/2.
- Tagging ~130 untagged bullets; `[scope: …]` tags.
- `topics.json`, `kb_build.py`, `STATE.md`, `docs-hashes.tsv`.
- `kb-step-*` tags; `Gotowe/` export.
- `OWNER-RULES` as a precondition; `Warsztat/proposed/*.diff`.
- `verify_reads.py` after every agent wave (the full-read rule lives in the logger).
- Two reviewers per session and "fix or reject every finding".
- GitHub-semantics research agent; optional API-only PL pages.

## 10. Start
1. Merge this branch of ClaudeEXPERT into its `main`. S1 copies `knowledge/`, `findings.md`, `reports/probes-2026-10-11.md` and these prompts from there.
2. Open a FelixReborn cloud session (FelixReborn only) and paste `prompts/S1-tooling.md`.
3. From S2 on, write „dalej”: `STATUS.md` names the next prompt.
