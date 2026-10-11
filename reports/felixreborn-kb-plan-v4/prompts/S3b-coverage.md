# S3b — Coverage pass: every relevant docs page read in full and compared with the base [G1, G2]

Read `docs/prompts/COMMON.md` in full (its "Access" section binds this session), then this prompt in full, before any other action.

## Goal
S3 read only the pages the base never mentioned and applied the changelog. Pages the base already cites were never re-read in full, so a gap or error from the first digest survives. This session reads every relevant page that S3 did not read in full, compares it with the base, and adds or replaces in the topic files every decision-changing fact the base lacks or gets wrong. The topic files are what the read gate (S4) enforces. The base gets more complete; it does not become a copy of the docs.

## Read in full
- `CLAUDE.md`, `STATUS.md`, `knowledge/CLAUDE.md`, `knowledge/docs-index.md`, `.claude/skills/kb-update/SKILL.md` (S3's relevance rule and edit rule, steps 2 and 4)
- `docs/kb-updates/*-triage.tsv` (S3's record: which pages S3 read)

## Steps
1. **Page list.** `curl -sL https://code.claude.com/docs/llms.txt` and `https://platform.claude.com/llms.txt` (COMMON "Access"; 403: stop). Write `docs/kb-updates/<YYYY-MM-DD>-coverage.tsv`, one row per link of both indexes. Columns:
   - `url`;
   - `relevant` (yes/no, S3's relevance rule; the owner's model scope applies);
   - `reason`;
   - `target_file` (one topic file, or the file that gets most of its facts);
   - `read_in`: `S3` when `docs-index.md` shows the page fetched in S3 with S3's date; else `S3b` for relevant pages, empty for irrelevant ones;
   - `status`: filled in step 4.

   Add `tools/coverage_check.py` (stdlib):
   - every `llms.txt` link of the two saved index files has exactly one row;
   - `relevant` ∈ {yes, no}; `reason` non-empty;
   - every relevant row has a `target_file` that exists;
   - every `S3b` row has a `status`;
   - exit 1 on any error.

   Add it to `tools/tests.sh` with the saved index files as input (`docs/kb-updates/<date>-llms-*.txt`).
2. **Packages.** `S3b` rows grouped by `target_file`, cut into reader packages of ~5 pages or ~200k tokens of page text (bytes ÷ 2.7 for English, O0 §1), whichever comes first. Expected ≈ 20 packages [ASSUMPTION]. Write `$SCRATCH/coverage/package-<n>.md`: the page URLs, the target file(s), the edit rule of `/kb-update` step 4, the tag legend.
3. **Readers** (`general-purpose`, `model: "opus"`, `effort: "high"`; approved with the plan), launched in waves of ≤ 10 per message. Reader prompt: "Read in full `<abs path>/package-<n>.md`, then your target knowledge file(s) in full. For each page:
   - fetch it with `curl -sL -o <abs scratch>/pages/<slug>.md <url>.md` (403/401: record it and stop your work; 404: find the new URL in `llms.txt`, else record it);
   - read it in full with Read (above 25,000 tokens in consecutive parts; say so);
   - compare it with the target file(s).

   Write `<abs scratch>/coverage/proposals-<n>.tsv` with columns `target_file`, `section`, `kind` (new | replaces), `old_line` (quoted verbatim for replaces), `new_line` (one bullet, tagged `[SOURCE: <url>, <today>]`), `page_section`. Propose only facts that are missing from the base or contradict it and that change a decision for an Opus 5.5 / Fable 5.1 user of Claude Code and the cloud. No tutorials, no quotas; 'nothing found' is valid. Edit no repository file. Report per page: HTTP code, read whole or in parts, proposals count."
4. **Editors** (6, `general-purpose`, `model: "opus"`, `effort: "high"`, one message), with S3's file packages, one owner per file.
   - Each gets the proposals for its files: `$SCRATCH/coverage/editor-<k>.tsv`, merged by you; duplicates between readers removed by you.
   - Each applies them with `/kb-update` step 4's edit rule: replace in place, tagged, never leave a contradiction next to an old fact.
   - A file reaching 90 % of 28,000 B: split per `/dostawa` and report the new files, so you can update the map.
   - Report: applied, rejected and why.

   You then set `status` in `coverage.tsv` per page: `read: <n> facts` / `read: nothing new` / `failed: <HTTP code>`. In `docs-index.md`: status ✅/❌ and date per page.
5. **Map.** `knowledge/CLAUDE.md`: new files from splits mapped, sizes updated, keywords added for new subjects (S2's keyword rule). Combined injection ≤ 9,000 B: over it, stop and tell the owner.
6. **Reviewer** (`reviewer`, `opus`, `high`). It reads:
   - `coverage.tsv`;
   - the readers' and editors' reports;
   - two edited files in full;
   - for 10 changed facts of its choice, the page text in `$SCRATCH/pages/`.

   (a) = a fact that contradicts its page, an untagged new bullet, an old fact left beside its replacement, a relevant page marked irrelevant; (b) = failing done-criteria.
7. `/dostawa`. `STATUS.md` "Next task": `docs/prompts/S4-read-gates.md`.

## Done when
```
python3 tools/coverage_check.py docs/kb-updates/*-coverage.tsv ; echo exit=$?
grep -c $'\tS3b\t' docs/kb-updates/*-coverage.tsv          # = number of pages read here
grep -c 'failed: 40[13]' docs/kb-updates/*-coverage.tsv    # 0 (a refusal stops the session instead)
python3 tools/doc_check.py ; echo exit=$?
bash tools/tests.sh ; echo exit=$?
```
plus the per-file count of facts added/replaced and the pages that failed with their HTTP codes.
