# Findings

Important findings, crucial information and notable interactions from sessions. Newest first.
Format: `## YYYY-MM-DD — title`, then the fact with its evidence tag (see CLAUDE.md "Evidence tags"). Promote confirmed, general facts to `knowledge/` (with the owner's approval) and note it here.

## 2026-10-08 — Nested CLAUDE.md with `@` imports loads whole documents on demand, past the Read limit
- Setup: `quiz/CLAUDE.md` with `- @a.md` and `- @b.md` (a.md 219,831 B with canaries at start, middle, end); `claude -p` told to Read only `quiz/trigger.txt` and list visible canaries → all 4 canaries listed; one turn added ~104k tokens of cache creation, i.e. the import is not bound by the 25,000-token Read limit [MEASURED: claude -p --model sonnet --effort low, 2026-10-08, CC 2.1.294, claude-sonnet-5-5, n=1, 0.56 USD]. Docs: imports expand recursively up to four hops, paths relative to the importing file; a CLAUDE.md up to 4 MiB loads in full; nested files reload on demand after compaction [SOURCE: https://code.claude.com/docs/en/memory.md, 2026-10-08].
- Syntax pitfall: `Ladowane pliki: @rozdzial3.md, @rozdzial4.md` imported only rozdzial4.md; the comma became part of the first path and that import failed silently [MEASURED: same probe, n=1, 0.05 USD]. Consistent with docs ("the path ends at the first space"). Use one import per line or separate with spaces only.
- Third-party reports: `@` imports in ancestor (parent-directory) CLAUDE.md files not expanded, some fixed, some open [IS: claudeissues.com mirrors of anthropics/claude-code issues 78216, 79046, 85683]. The descendant (subdirectory) case above worked.

## 2026-10-08 — Citations check precision, not completeness or optimality
- Owner's experience: answers with a citation for every claim were still wrong or suboptimal, because a better or alternative mechanism for the given configuration was left out. A citation proves a fact exists, not that the answer considered all options [ASSUMPTION, owner report, 2026-10-08].
- Working method for design answers: state goal and constraints, list every candidate mechanism, eliminate each with a reason, give failure conditions of the pick, test the pick (and the runner-up when it matters) by experiment.
- Example from this session: for "force full reading of 8 doc pages" Claude proposed only PostToolUse + Stop hooks and missed a candidate: a nested `CLAUDE.md` with `@` imports of the pages, which Claude Code loads on Read of a file in that directory and reloads after compaction (O0 §1, §2). Unverified: whether `@` imports expand in a nested CLAUDE.md and whether there is a size cap [ASSUMPTION; test with dummy files].

## 2026-10-08 — Size of 8 CC doc pages vs the Read limit ("read it all" instructions)
- `curl -sL https://code.claude.com/docs/en/<page>.md` → all 200; bytes: memory 51,575 · large-codebases 34,296 · context-window 60,542 · best-practices 36,520 · skills 106,047 · claude-directory 92,536 · features-overview 28,566 · debug-your-config 15,873 (total ~426 KB) [MEASURED: curl + wc -c, 2026-10-08, CC 2.1.294].
- skills = 38,167 and claude-directory = 36,439 tokens of content, over the 25,000-token Read limit, so each needs ≥ 2 Read calls with offset/limit; a plain Read gives a PARTIAL view (O0 §1) [MEASURED: Read counter (count − 7), 2026-10-08, CC 2.1.294, Opus 5.5, n=1]. Others estimated at 2.7 B/token (O0 §1): whole set ≈ 160k tokens [ASSUMPTION].
- large-codebases, claude-directory, features-overview and debug-your-config are not in the O1 index. CC 2.1.292–2.1.294 changelog: no change to Read or WebFetch limits [CL, grep, 2026-10-08].

## 2026-10-06 — Auto mode classifier blocks Claude from changing its own instructions, even on the owner's request
- After the owner told Claude to merge to `main` itself, two actions were denied with reason `[Self-Modification]`: editing CLAUDE.md to record a standing approval to merge, and then fast-forwarding `main` with a branch that changes CLAUDE.md [MEASURED: 2 auto mode classifier denials, 2026-10-06, CC 2.1.291, Opus 5.5, n=2]. Consistent with O0 §4 (protected paths always go to the classifier). Ordinary edits to CLAUDE.md requested by the owner were allowed in the same session (n=3).
- Consequence: the owner merges changes into `main` on GitHub. Whether merges touching only `knowledge/` pass the classifier is unverified.

## 2026-10-06 — Glob and Grep present as dedicated tools
- In this cloud session (CC 2.1.291, Linux) the tool list contained `Glob` and `Grep` [MEASURED: session tool list, 2026-10-06, CC 2.1.291, Opus 5.5, n=1]. Related open conflict in CLAUDE.md ("Glob/Grep on Linux", O1 §2) stays open until confirmed across builds.

## 2026-10-06 — Session work is invisible to later sessions until merged into main
- Each cloud session gets its own branch cut from `origin/main` (O0 §7 [SOURCE: CE]; this session: `claude/compassionate-shannon-amdhmm` from `origin/main` 676c5b6 [MEASURED: git branch -r, git log, 2026-10-06]). KB edits and entries in this file reach the next session only after the owner merges them. Rule added to CLAUDE.md "Persistence".
