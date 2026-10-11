# FelixReborn knowledge-base plan v4 (2026-10-11, amended 2026-10-12)

Replaces plan v3 and the FelixReborn plan v2 with its 16 prompts (removed; in git history). Their measurements were kept in `reports/probes-2026-10-11.md`. Target repository: FelixReborn. Input: the owner's skeleton `claude-felixReborn-input.md` (this directory, verbatim; in FelixReborn it is the root `CLAUDE.md`).

## 1. The three goals and the cut rule
1. **G1**: Claude does not return to the knowledge base after the first message; it answers later questions from memory.
2. **G2**: The base goes stale and nobody notices.
3. **G3**: Agents do not know where things are.

Everything below serves at least one goal, named in brackets. Anything that served none was cut, not deferred (§9). Threat model: laziness, shortcuts, forgetting. Not deliberate circumvention. The only hard server-side protection is branch protection (O0 §8 [ASSUMPTION from O0 §4, §7]); the owner knows this and the plan adds none.

## 2. Owner decisions of 2026-10-11 (this session)
- Model scope: content about models the owner never uses is removed. Only Opus 5.5 and Fable 5.1 stay, plus traps that bite a user of those two (e.g. `claude -p` without `--model` runs on Sonnet 5.5, O0 §5 [MEASURED]).
- Agents get the map at start **and** a read gate at their end.
- Structure check: the Foldery solution, ported (§3). No GitHub Actions. Claude merges into `main` itself, locally (`merge` + `git push origin main`), so the push gate has something to guard.
- Reviews: one reviewer, Opus 5.5 high, read-only. It reports only factual errors and unmet done-criteria.
- Two maps: `MAPA.md` §1 for project docs, `knowledge/CLAUDE.md` for the base. Each file appears in exactly one of them.
- `CLAUDE.md` cap is 40 KB, not 20 KB. No rule makes a session delete or shorten content to stay under a cap. A file over its cap is split (the owner's split rule). `CLAUDE.md` is never split: at ≥ 90 % the owner is told. A file that cannot be split (the base map) over its cap: stop and tell the owner.

### 2b. Owner decisions of 2026-10-12
- Hook tests: Foldery's `test_hooks.sh` pattern is ported in reduced form (§3 "Hook tests"); its cases are not copied.
- The three extra push refusals (§3) are built.
- Coverage pass: new session S3b after S3 (§6). Every relevant documentation page is read in full and compared with the base; missing facts go into the topic files, which are under the read gate (S4). The plan now has 6 session prompts.
- Inputs reach FelixReborn by the owner's upload (§10); sessions read no other repository or branch. Any refused access: stop and tell the owner (COMMON "Access").
- `knowledge/O0`: the owner's uploaded version (2026-10-10 content, budget 50 KB) wins over ClaudeEXPERT's, line endings normalised to LF. The ClaudeEXPERT lines it lacks (2.1.292–2.1.293, 2026-10-08) go to `docs/import/O0-claudeexpert-delta-2026-10-12.md`; S3 promotes them. Owner: „Aktualniejsze o0 wygrywa”.
- Original wording (Polish, verbatim): „Dopisać A.” · „a - tak, b - tak, c- tak” · „Jezeli ma korzystac z innych galezi w jakims celu to MUSZA byc w promptach zgody na odczyt itd. !!! jezeli nie udalo sie w takiej sytuacji uzyskac dostepu TO ZATRZYMUJE DZIALANIE I O TYM INFORMUJE ZAWSZE!!!”

### 2a. Original wording (Polish, verbatim; for `docs/OWNER-RULES.md`, skeleton l. 19)
- Plan A–D (layout, migration O0–O5 → topic files ≤ 28 KB, sessions S1–S5, cuts): „Tak.”
- Model scope: „To byl moj wymóg - zbedne i niepotrzebne informacje o modelach ktorych nigdy nie uzywam.”
- Agents: „Mapa + bramka”.
- Structure check: „przenieś rozwiązanie z repo asktheages1/foldery (działa w praktyce). […] 1) Checker = jeden skrypt Python bez zależności. Limity w bajtach UTF-8 per typ pliku w jednej funkcji. Powyżej 100% = błąd (exit 1), 90–100% = OSTRZEŻENIE bez blokady. 2) Każdy plik dokumentacji ma wpis w mapie z adnotacją „(N KB)”; checker porównuje ją z rzeczywistym rozmiarem (tolerancja max(10%, 1 KB)). Rozmiary tylko w mapie, nigdzie indziej. Brak pliku w mapie = błąd. 3) Hook PreToolUse blokuje WYŁĄCZNIE git push na main, gdy checker jest czerwony. Push gałęzi roboczych zawsze przechodzi, bez wyjątków wip/*. 4) Checker jest w zestawie testów i w procedurze końca pracy. Ostrzeżenie ≥90% przy pliku zmienionym w sesji → podział w tej samej sesji (nazwa-1.md / nazwa-2.md po nagłówku blisko połowy, poprawa odsyłaczy i mapy). 5) Bez GitHub Actions (limit minut). Scalanie z main robisz lokalnie (merge + git push origin main), żeby hook miał co pilnować.”
- Reviewer: „Rekomendowane - recenzent opus 5.5 high”.
- `CLAUDE.md` cap: „limit to 40 kb . I zadnego "tyle usunac co dodalo"”.

## 3. Structure check (ported from `asktheages1/foldery`: `GaleriaFolderow/tools/doc_check.py`, `.claude/hooks/hooks.py`, skill `/dostawa`) [G3, protects G1–G2]
- **`tools/doc_check.py`**: one Python file, standard library only. Exit 1 on any error, 0 otherwise. Warnings never block.
  - Byte caps (UTF-8), all in one function `limits()`; > 100 % = error, 90–100 % = `WARNING`:

    | File | Cap (B) | Reason |
    |---|---|---|
    | `CLAUDE.md` | 40,000 (HTML comments stripped) | owner, 2026-10-11 (the skeleton's l. 38 said 20 KB; S1 corrects that line). At ≥ 90 %: tell the owner, never split |
    | `knowledge/*.md` except the map | 28,000 | must be readable whole with `cat`: Bash shows ≤ ~30,000 chars inline, above that a 2 KB preview (`reports/probes-2026-10-11.md` P0, R0 [MEASURED, n=2]) |
    | `knowledge/O0-how-claude-works.md` (until S2 removes it) | 50,000 | its own header budget (owner, 2026-10-10; the owner's O0 is the one used, §2b) |
    | `knowledge/O[1-5]-*.md` (until S2 removes them) | 40,000 | their own header budget |
    | `MAPA.md`, `docs/**/*.md` | 40,000 | skeleton l. 38, Foldery |
    | `STATUS.md` | 6,000 | skeleton l. 38 |

  - Combined injection (`agent-rules.md` + `knowledge/CLAUDE.md` without HTML comments) > 9,000 B = error; no separate caps for the two files. Source: Foldery checks `agent-rules.md` ≤ 9,000; the per-field limit is 10,000 chars, overflow becomes a 2,000-char preview (O2 §A6 [S:hooks]). Over it: stop and tell the owner (the map cannot be split).
  - Maps:
    - Every `knowledge/*.md` except the map has a line in `knowledge/CLAUDE.md`. Every `docs/**/*.md` has a row in `MAPA.md` §1 (`docs/import/` included).
    - First mention carries the size `(N KB)`, checked against the real size with tolerance max(10 %, 1 KB).
    - Unmapped file = error. Dead path = error: a backticked path in a map or in `CLAUDE.md` that starts with `knowledge/`, `docs/`, `tools/`, `.claude/hooks/`, `.claude/skills/` or `.claude/agents/`, ends in a file extension, and does not exist. Narrower than Foldery's rule, so the skeleton's other paths (`.bat`, `_tmp/`, `~/.claude`) are not flagged.
    - A size annotation `(N KB)` outside the two maps (in `CLAUDE.md`, `STATUS.md`, `knowledge/`, `docs/` except `docs/import/`, whose files are frozen history) = error.
  - `knowledge/CLAUDE.md` has a line `As of: Claude Code 2.1.<n> (YYYY-MM-DD)` [G2]; the date is checked from S5.
  - From S2: every map line parses as `- <keywords> → \`<file>\` (N KB) …`. Keywords are comma-separated, case-insensitive; a trailing `*` means "prefix", for Polish stems [G1, G3: the read gate reads them].
  - `--self-test`: one passing and one failing fixture per rule (`tests/doc_check/`).
- **Push gate** (`.claude/hooks/hooks.py bash`, PreToolUse matcher `Bash`, timeout 120):
  - Blocks (exit 2) a `git push` that targets `main` while `doc_check.py` is red. Branch pushes pass, unless the hook itself raises an exception or hits its deadline (fail-closed applies to every `git push`). Fail-closed does not cover a `hooks.py` that does not compile: Python exits 1, a non-blocking error, and the gate is silently off (`findings.md` 2026-10-12 [MEASURED]); hence every `hooks.py` change is tested as a scratch copy before it replaces the live file (§3 "Hook tests").
  - Three Foldery rules also refuse a push to `main` when the checker is green, because the checker would otherwise check something other than what is pushed: push combined with `checkout`/`merge`/`fetch` etc. in one call; a ref other than `HEAD`; uncommitted tracked changes. Built (owner, 2026-10-12). `/dostawa` always satisfies them.
  - Ported from Foldery `hooks.py`, unchanged:
    - command parser (`segments`, `strip_wrappers`, `git_sub`; covers `git -C`, `env`, `timeout`, `cd`);
    - main-target detection (refspec, `HEAD` on `main`, `checkout main` in the same call);
    - "push to `main` is a separate Bash call", "push `HEAD` only", "clean tracked tree";
    - fail-closed on its own exception;
    - 100 s deadline.
  - Pushes whose target the hook cannot pin to a branch other than `main` count as a push to `main`, blocked only while red:
    - `--all`, `--branches`, `--mirror`, a refspec with `*` or without a source (`:x`);
    - a push without refspec under `remote.*.push` or `push.default upstream|tracking|matching`.

    Foldery refuses all of them unconditionally: `--mirror` in its force-push block; `--all`/`--branches`, `*`/`:x` and the refspec-less config push in refusals of their own. None of those refusals is ported, because branch pushes always pass (owner rule 3, §2a). Port only the recognition from Foldery `h_bash`. A push with an explicit refspec to a branch other than `main` always passes.
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
- **`tools/tests.sh`** runs `doc_check.py --self-test`, `doc_check.py` and `bash tools/test_hooks.sh .claude/hooks/hooks.py`.
- **Hook tests** (`tools/test_hooks.sh`): the pattern of Foldery `GaleriaFolderow/tools/test_hooks.sh` (in FelixReborn: `docs/import/foldery/test_hooks.sh`), reduced; its cases are written for Foldery's hook and are not copied. Pattern:
  - **Path argument:** `bash tools/test_hooks.sh <path to hooks.py>`. A change to `hooks.py` is made in a scratch copy, tested, and only then copied over the live file. Hooks act at once (O0 §4), and a broken one fails silently (above).
  - **Isolation:** `mktemp -d` removed by `trap`; own `GIT_CONFIG_GLOBAL` with `GIT_CONFIG_NOSYSTEM=1`; `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE`; `LC_ALL=C.UTF-8`. The hook runs as in production: `python3 -I <path> <handler>` under `timeout` (115 s for `bash`: above the 100 s deadline, below the 120 s settings timeout).
  - **Fixture:** a local bare repository as `origin` and its clone, both in the temp directory, never GitHub. `nb <branch> <files…>` makes a branch from `origin/main` with changes in those files. Extra clones or a worktree only where a case needs them. The fixture's `tools/doc_check.py` is a stub: exit 1 when `RED=1`, else 0. The hook tests do not depend on the checker's rules; `doc_check --self-test` tests those.
  - **Assertions:** `bash_case <name> <expected 0|2> <dir> <command> [VAR=…]` builds the PreToolUse Bash JSON with `jq`, pipes it to the hook and compares the exit code. Other events have their own helpers built the same way. Exit 2 with empty stderr is a failure (`2-without-message`): the model would not know why it was blocked. Every case prints `OK [name]` or `FAIL [name] expected X, got Y`; the end prints `RESULT: n/m`; exit ≠ 0 if any case failed.
  - **Wrapper:** the settings command form with `hooks.py` missing → 0 (a broken checkout does not block the session); `hooks.py` with CRLF line endings gives the same results as LF.
  - **Known limits:** bypasses the hook does not catch by design are cases expected to pass, named `limit/…`: push from a script, `sh -c`, `xargs`, `$(…)`, a git alias, `GIT_DIR` / `--git-dir`, `--delete main` (the git proxy refuses branch deletion, O0 §7). They record the boundary (`CLAUDE.md` l. 65) and fail when a hook change moves it; they are not fixes. A listed bypass that the ported hook blocks is not a limit: test it as a normal case.
  - **Not ported:** Edit/Write helper (`ce`: no Edit/Write hook here), force-push, history rewrite, Actions/`.github`, `ask`, the STATUS/CHANGELOG diff rule, Foldery's `turn`/`stop` cases.

## 4. Maps and injection [G3]
- `knowledge/CLAUDE.md` is a nested CLAUDE.md, so it auto-loads when any file under `knowledge/` is read with Read, or with a single-file `cat`/`head`/`tail`/`sed -n`/`grep` ([CL 2.1.293]: ClaudeEXPERT O0 §2; in FelixReborn `docs/import/O0-claudeexpert-delta-2026-10-12.md` until S3 promotes it; Explore included: `reports/probes-2026-10-11.md` P4 [MEASURED, n=1]).
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
  - "Per prompt" is what G1 means: every topical question triggers a fresh read. A repeated Read of an unchanged file costs only the stub's tokens (P3); after compaction the content must really come back (Read with content or `cat`). [ASSUMPTION: whether the stub persists after compaction and whether PostCompact fires on auto-compaction are not measured; test cases only.]
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
- **S3b coverage pass** (owner, 2026-10-12) [G1, G2]. S3 reads only the pages the base never mentioned. Pages it already cites were never re-read in full, so a gap from the first digest would survive every session. S3b closes that gap:
  - Every page of both `llms.txt` indexes gets a row in `docs/kb-updates/<date>-coverage.tsv`, relevant or not (S3's relevance rule), with a reason. Relevant pages that S3 did not read in full are read in full by reader agents (≈ 100 pages, ≈ 20 readers [ASSUMPTION]).
  - Each reader compares its pages with the target topic files, read in full. It proposes only facts that are missing from the base or contradict it and that change a decision, each tagged `[SOURCE: <url>, <date>]`. "Nothing found" is valid; no quotas.
  - Readers edit nothing. Six editors (S3's file packages, one owner per file) apply the proposals with S3's edit rule. A file reaching 90 % of 28 KB is split, and the map is updated.
  - Result: the facts land in topic files, which the read gate (S4) guards. That is why the gaps are filled in the base and not with a docs mirror or live lookups.
- **S5**:
  - SessionStart freshness line: local `claude --version` vs `As of:` and days since the `As of:` date. `KB: STALE` at ≥ 3 versions or > 30 days. Plus `kb-update: <n> commits ahead of main` when that branch exists. No HTTP at start (the `git fetch` with timeout that the start hook already does is allowed).
  - A weekly Routine (a scheduled cloud session) runs `/kb-update` on a fixed branch `kb-update`. It pushes that branch and **does not merge**: unattended KB edits wait for an attended session, which the start line tells about them; the Routine also sends a push notification.

## 7. Sessions and agents
One session = one prompt = one branch, merged into `main` by `/dostawa`. The next session starts after the merge. Main window: Opus 5.5 high. The agents named in each prompt are approved with this plan (skeleton l. 45: "several agents … the owner's yes").

| Session | Goal | Main window | Agents (type · model · effort) | Reviewer |
|---|---|---|---|---|
| S1 tooling | G3 + protection | inputs verified (manifest); state files; `doc_check.py`; `hooks.py` (push gate, session, subagent); settings; tests; `/dostawa`; `reviewer.md`; interim map of O0–O5; `CLAUDE.md` edits | none | 1 (general-purpose · opus · high; `reviewer.md` exists only from S2, O0 §3) |
| S2 migration | G3, G1 | `migration-map.tsv`, `kb_migrate.py` + check (every line exactly once, fact-ID multiset unchanged), references rewritten, O0–O5 deleted, keyword map | 2 navigation probes (1 general-purpose, 1 Explore · opus · low): 3 questions each, first `knowledge/` read checked in the transcript | 1 (`reviewer` · opus · high) |
| S3 update | G2 | `/kb-update`, delta, triage merge and check, `docs-index.md`, `recheck-and-conflicts.md`, `design-rules.md`, map sizes, model-scope grep | triage: 1 per ~100 bullets, max 4 (general-purpose · opus · high); editors: 6, one owner per file pair, each applies its triage rows and fetches its new pages (general-purpose · opus · high) | 1 (`reviewer` · opus · high) |
| S3b coverage | G1, G2 | page list and `coverage.tsv` + check, reader packages, applying order, map update, `docs-index.md` statuses | readers: 1 per ~5 pages or ~200k tokens of page text, ≈ 20, in waves of ≤ 10 (general-purpose · opus · high); editors: 6, S3's packages (general-purpose · opus · high) | 1 (`reviewer` · opus · high) |
| S4 read gates | G1, G3 | logger, PostCompact, UserPromptSubmit, Stop, SubagentStop, test cases, live tests in nested `claude -p` (not agents) | none outside the nested runs | 1 (`reviewer` · opus · high) |
| S5 freshness | G2 | SessionStart line, Routine (created after the owner's yes in session), `CLAUDE.md` health-check line | none | none: advisory line + Routine spec, no constraining mechanism (skeleton l. 5 asks review of mechanisms) |

Total: ≈ 38 agents (12 + S3b ≈ 26) + up to 5 reviewers (plan v3/v2: 70). Six session prompts: S1, S2, S3, S3b, S4, S5.

Cost [ASSUMPTION; list prices; scale from `findings.md` 2026-10-08, 3.6–8.1 USD per heavy single-file session]:
- S1 6–12 USD (hook tests ported); S2 4–8; S3 25–55; S3b 60–160; S4 6–12; S5 2–4.
- **≈ 100–250 USD** in total; Routine 1–5 USD per week.

## 8. FelixReborn `CLAUDE.md`: what each session changes
Line numbers refer to the input file `claude-felixReborn-input.md`. The file is 17,986 B, 45 % of its 40 KB cap: sessions add what their changes need; no session shrinks the file to make room. Edits go through the auto-mode classifier, which may refuse (§3 fallback).

| Line | Session | Change |
|---|---|---|
| 5 | S1 | "the owner has merged the PR" → "the work is merged into `main` by `/dostawa` with the push gate green" (merge policy A, owner 2026-10-11) |
| 7 | S1 | add: mechanisms that must run (hooks, settings, checker) live at the repository root, the only place Claude Code loads them (O0 §4) |
| 22–24 | S1 | SessionStart line describes the real hook. "markdown ≤ 40 KB fits one Read" stays; add: "`cat` shows a file whole only up to ~28 KB; larger files: the Read tool". `<docs>` → `docs/`. `<kb>/O0-…` → `knowledge/CLAUDE.md` (auto-loads on first touch of `knowledge/`) |
| 30 | S1 | reviewer: "Fix or reject every finding with evidence; style findings are ignored" → "report only factual errors and unmet done-criteria" (owner 2026-10-11) |
| 38 | S1 | caps → the §3 table (this file 40 KB, owner 2026-10-11); `doc_check` → `tools/doc_check.py`; 90 % rule and split procedure → `/dostawa` |
| 44 | S1 | conditional "If a SubagentStart hook injects …" → measured statement, workflow agents excepted |
| 53, 55 | S1 | merge policy A filled in (`/dostawa`). Next step A: "the next task is the „Next task” line of `STATUS.md`; for the KB plan it names `docs/prompts/<Sn>.md`" |
| 48 | S1 | `.claude/agents/implementer.md` → plain text "an implementer agent (not built yet)", otherwise the dead-path rule is red |
| 64–65 | S1 | hard list = what is live: push to `main` blocked while `doc_check` is red, or when it is not a separate Bash call, not `HEAD`, or the tracked tree is dirty; l. 65's bypass list = the `limit/…` cases of `tools/test_hooks.sh`. Placeholders for unbuilt gates stay, labelled "advice until built" (skeleton l. 6). Sandbox: "no `bwrap` in the cloud [MEASURED 2026-10-11]" |
| 23–24, 44, 64 | S4 | read gates: one sentence each in "Start of every session", "Agents", "Enforcement and its limits" (+ what is not covered, §5) |
| 68 | S5 | health check: freshness line at start; `/kb-update` |

Not touched by the plan, and still unbacked: the `ask` rules (l. 19), the Stop reminder (l. 18), `<tests script>` beyond `tools/tests.sh`, the implementer agent (l. 48, de-linked in S1), `/<health-check>` (l. 68), force-push / frozen-dir / MCP denials (l. 64 placeholders, labelled as advice in S1).

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
1. The owner uploads the input package to FelixReborn `main`, keeping its paths. Upload the extracted files unchanged: do not open or save them in an editor first. S1 checks every byte against the manifest, and a re-saved file (e.g. CRLF) stops it. The package was built from this directory and ClaudeEXPERT branch `claude/vibrant-albattani-j4qqjv` on 2026-10-12. Contents:
   - `knowledge/O0…O5`, LF line endings. They replace the CRLF upload of 2026-10-12. O0 = the owner's uploaded content (§2b); O1–O5 = ClaudeEXPERT, the same content as the upload.
   - `docs/prompts/`: this plan with a "Paths:" line, COMMON, S1–S5, S3b, `claude-felixReborn-input.md`.
   - `docs/import/`:
     - `FINDINGS-claudeexpert.md` (`findings.md`, probe paths rewritten);
     - `probes-2026-10-11.md`;
     - `claudeexpert-tags-and-conflicts.md` (the "Evidence tags" and "Known open conflicts" sections of ClaudeEXPERT `CLAUDE.md`, verbatim);
     - `O0-claudeexpert-delta-2026-10-12.md` (the ClaudeEXPERT O0 lines the owner's O0 lacks; S3 promotes them);
     - `foldery/` (Foldery `doc_check.py`, `hooks.py`, `test_hooks.sh`, `settings.json` and `/dostawa` as `dostawa-SKILL.md`, at ec7ce87);
     - `MANIFEST.sha256` (checksums of every file above).
2. The owner renames FelixReborn's `claude.md.md` to `CLAUDE.md`. Claude Code loads only that name (`findings.md` 2026-10-12 [MEASURED]).
3. Open a FelixReborn cloud session with FelixReborn only and write „Wykonaj docs/prompts/S1-tooling.md”. S1 first checks the manifest and stops on any mismatch.
4. From S2 on, write „dalej”: `STATUS.md` names the next prompt (S2 → S3 → S3b → S4 → S5).
