# S04 — Missing documentation pages: fetch, digest, index

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
The pages the audit found missing are fetched as `.md`, their decision-changing facts land in the right topic file with `[SOURCE: URL, date]`, `knowledge/docs-index.md` has a row per page (status, date), and `knowledge/docs-hashes.tsv` has sha256 and size per fetched file. One owner per target file; nothing edits a file two agents share. This PR introduces phase 1b (hand review by the owner; say so).

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/docs-index.md` (its sections on live lookup mechanisms and on the verification procedure are the method for this session)
## Read in part (say so)
- `head -15` of every topic file.

## Pages (commit as `knowledge/pages-1b.txt`, one URL per line, `.md` suffix, `/en/` paths)
CC = `https://code.claude.com/docs/en/`, PL = `https://platform.claude.com/docs/en/`. Packages = one agent = one target file:
- **hooks** → `hooks.md`: CC `hooks`, `hooks-guide` (the base's hook table was built from docs only, partly from search excerpts).
- **scheduling** → `headless-sdk-ci.md`: CC `routines`, `scheduled-tasks`, `desktop-scheduled-tasks` (S11 reads scheduling there).
- **permissions** → `permissions-settings-automode.md`: CC `sandbox-environments`, `security-guidance`, `server-managed-settings`, `settings-example`.
- **context** → `context-window-and-read.md`: CC `checkpointing`, `large-codebases`, `troubleshooting`, `debug-your-config`; plus, if the owner approved the API pages (`STATUS.md` decision), PL `build-with-claude/compaction-background`, `compaction-keep-recent-turns`, `compaction-on-demand`, `compaction-thinking-blocks`, `compaction-threshold`, `context-editing`, `build-with-claude/cache-diagnostics`.
- **plugins** → `mcp-and-plugins.md`: CC `plugins/mods/gallery`, `plugins/mods/interface`, `plugins/mods/troubleshoot`, `plugins/manifest-reference`, `plugins/loading`, `plugins/relevance`.
- **cloud** → `cloud-environment.md`: CC `remote-control`, `channels-reference`.
- **models** → `models-effort-cost.md` and `prompting-and-model-weaknesses.md` (one agent owns both): PL `build-with-claude/prompt-engineering/prompting-claude-fable-5-1`, `about-claude/models/model-ids-and-versions`, `about-claude/models/choosing-a-model`; plus, if approved, PL `agents-and-tools/tool-use/memory-tool`, `agents-and-tools/tool-use/tool-search-tool`, `build-with-claude/mid-conversation-effort-example`.
- **index** → `docs-index.md` (runs after the others): rows for every page from the reports; verifies each URL with `curl -sS -o /dev/null -w '%{http_code} %{url_effective}\n' -L`.

## Work
1. Network check: `curl -sS -o /dev/null -w '%{http_code}\n' https://code.claude.com/docs/llms.txt` and `https://platform.claude.com/llms.txt`. 403 = policy: stop and report; never retry.
2. **Fetch-and-digest agents** (7, `model: "opus"`, `effort: "high"`, general-purpose, one message; the index agent afterwards). Prompt skeleton:
   ```
   For each URL in your package: curl -sL -o Warsztat/_scratch/pages/<slug>.md "<url>.md" (a 403 is policy: record it and continue); record HTTP code, byte size and sha256sum. A 404: resolve per knowledge/docs-index.md (llms.txt grep, then WebSearch site:) and record the new URL. Read each fetched file in full with the Read tool; a file over 25,000 tokens in parts with offset/limit, and say so. Extract only facts that change a decision for a Claude Code / API / cloud user on Opus 5.5 or Fable 5.1: limits, defaults, flags, events, fields, precedence, version thresholds, traps. No tutorials. Edit only your target file(s): replace a stale fact in place or add a bullet in the matching section, each with [SOURCE: <url>, <date>]; keep ≤ 28,000 bytes, else stop and propose a split. Write Warsztat/pages/report-<package>.md: per URL: code, size, sha256, facts added (file §), facts replaced (old → new), or "nothing relevant because …". Edit nothing else.
   ```
   `verify_reads.py` on each transcript for its fetched files (full or declared parts).
3. After all agents finish: merge the reports into `knowledge/docs-hashes.tsv` (url, date, http_code, bytes, sha256); launch the index agent; the fetched pages stay in `Warsztat/_scratch/` (not committed; S05 re-fetches by URL and compares hashes).
4. **Your own edit, after the agents**: promote the measured hook facts from `docs/import/FINDINGS-claudeexpert.md` (2026-10-11 entries: truncated `cat`, `file_unchanged`, `prompt_id` sharing, SubagentStart injection, stdout trailing newline, push-gate probe) into `hooks.md` and `context-window-and-read.md` as `[MEASURED …]` bullets with the tags verbatim; the Glob/Grep finding (2026-10-06) into `context-window-and-read.md`.
5. `kb_check.py --phase 1b`: every URL in `pages-1b.txt` has a row in `docs-index.md` (status + date) and in `docs-hashes.tsv`. Set `knowledge/phase.txt` to `1b`.

## Done when
```
python3 tools/kb_check.py --phase 1b --tree HEAD ; echo exit=$?     # runs 0, 1a, 1, 1b
```

## End of session
Reviewers per COMMON §4 (KB files for them: `hooks.md` and `permissions-settings-automode.md` in full; they re-fetch two pages by URL from `pages-1b.txt`, compare the sha256 with `docs-hashes.tsv`, and verify 10 new `[SOURCE]` bullets against the text, reading in parts if needed). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push, tag. Next prompt: `docs/prompts/S05-model-scope.md`.
