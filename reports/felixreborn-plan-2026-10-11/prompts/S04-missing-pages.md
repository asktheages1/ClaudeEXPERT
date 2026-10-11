# S04 — Missing documentation pages: fetch, digest, index

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
The pages the audit found missing are fetched as `.md`, their decision-changing facts land in the right topic file with `[SOURCE: URL, date]`, and `knowledge/docs-index.md` has a row per page with status and date; `knowledge/docs-hashes.tsv` has sha256 and size per fetched file.

## Read in full (Read tool)
- `CLAUDE.md`, `STATUS.md`
- `knowledge/docs-index.md` (the lookup method in its §2 and the verification procedure in §3 are the method for this session)
- `knowledge/CLAUDE.md` if it exists, else the first 15 lines of every topic file

## Pages (commit as `knowledge/pages-1b.txt`, one URL per line, `.md` suffix, `/en/` paths)
CC = `https://code.claude.com/docs/en/`, PL = `https://platform.claude.com/docs/en/`.
- hooks package → `hooks.md`: CC `hooks`, `hooks-guide`, `routines`, `scheduled-tasks` (the hook pages re-fetched because the KB's hook table was built from docs only and partly from search excerpts).
- permissions package → `permissions-settings-automode.md`: CC `sandbox-environments`, `security-guidance`, `server-managed-settings`, `settings-example`.
- context/troubleshooting package → `context-window-and-read.md` and `instructions-memory-skills.md`: CC `checkpointing`, `large-codebases`, `troubleshooting`, `debug-your-config`.
- plugins package → `mcp-and-plugins.md`: CC `plugins/mods/gallery`, `plugins/mods/interface`, `plugins/mods/troubleshoot`, `plugins/manifest-reference`, `plugins/loading`, `plugins/relevance`.
- cloud package → `cloud-environment.md`: CC `remote-control`, `desktop-scheduled-tasks`, `channels-reference`.
- models package → `models-effort-cost.md` and `prompting-and-model-weaknesses.md`: PL `build-with-claude/prompt-engineering/prompting-claude-fable-5-1`, `about-claude/models/model-ids-and-versions`, `about-claude/models/choosing-a-model`.
- API package (**only if `STATUS.md` says the owner approved it**; otherwise skip and say so) → `context-window-and-read.md`/`models-effort-cost.md`: PL `build-with-claude/compaction-background`, `compaction-keep-recent-turns`, `compaction-on-demand`, `compaction-thinking-blocks`, `compaction-threshold`, `context-editing`, `agents-and-tools/tool-use/memory-tool`, `agents-and-tools/tool-use/tool-search-tool`, `build-with-claude/mid-conversation-effort-example`, `build-with-claude/cache-diagnostics`.
- index package → `docs-index.md`: the agent that owns `docs-index.md` writes the rows for every page above from the other agents' reports and verifies each URL with `curl -sS -o /dev/null -w '%{http_code} %{url_effective}\n' -L`.

## Work
1. Check the network once: `curl -sS -o /dev/null -w '%{http_code}\n' https://code.claude.com/docs/llms.txt` and the same for `https://platform.claude.com/llms.txt`. A 403 is policy: stop and report (the owner adjusts the environment's network list).
2. **Fetch-and-digest agents** (one per package above, 7 or 8, `model: "opus"`, `effort: "high"`, general-purpose, one message; the index agent starts after the others finish). Prompt skeleton:
   ```
   For each URL in your package: curl -sL -o Warsztat/pages/<slug>.md "<url>.md"; record HTTP code, byte size and sha256sum. If the .md is a 404, resolve per knowledge/docs-index.md §3 (llms.txt grep, then WebSearch site:) and record the new URL. Read each fetched file in full with the Read tool (files over 25,000 tokens: read in parts with offset/limit and say so). Extract only facts that change a decision for a Claude Code / API / cloud user on Opus 5.5 or Fable 5.1: limits, defaults, flags, events, fields, precedence, version thresholds, traps. No tutorials, no marketing. Then edit your target file(s) in knowledge/: replace a stale fact in place, or add a bullet in the matching section, each with [SOURCE: <url>, <date>]; keep ≤ 28,000 bytes, else stop and propose a split. Write Warsztat/pages/report-<package>.md: per URL: code, size, sha256, facts added (file §), facts replaced (old → new), "nothing relevant because …" when so. Never edit a file outside your package. Report the path of that file.
   ```
3. Merge the reports into `knowledge/docs-hashes.tsv` (url, date, http_code, bytes, sha256) and let the index agent write the `docs-index.md` rows.
4. Promote the measured facts about hooks from `knowledge/FINDINGS-claudeexpert.md` (entries 2026-10-11: truncated `cat`, `file_unchanged`, `prompt_id` sharing, SubagentStart injection, stdout trailing newline, push-gate probe) into `hooks.md` and `context-window-and-read.md` as `[MEASURED …]` bullets, and the Glob/Grep finding (2026-10-06) into `context-window-and-read.md`. This is the one content edit you make yourself; keep the tags verbatim.
5. Extend `tools/kb_check.py --phase 1b`: every URL in `pages-1b.txt` has a row in `docs-index.md` (status + date) and in `docs-hashes.tsv`.

## Done when
```
python3 tools/kb_check.py --phase 1b --tree HEAD ; echo exit=$?
python3 tools/kb_check.py --phase 1 --tree HEAD ; echo exit=$?
wc -l knowledge/pages-1b.txt knowledge/docs-hashes.tsv     # hashes ≥ pages
```

## End of session
Reviewers per COMMON §4 (KB files for them: `hooks.md` and `permissions-settings-automode.md` in full, plus the two fetched pages behind them in `Warsztat/pages/`; they verify 10 new `[SOURCE]` bullets against the fetched text). Fix or reject. `STATUS.md`, `CHANGELOG.md`, commit, push. Next prompt: `docs/prompts/S05-model-scope.md`.
