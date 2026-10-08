# docs/cc index

Verbatim copies of official Claude Code doc pages, fetched 2026-10-08. Refresh: `bash tools/refresh-docs.sh`, then `git diff docs/cc` shows what changed upstream. Each part fits one Read call. Bytes / ~2.7 = approximate tokens for English markdown.

| Page | File | Bytes | sha256[:16] of full page | `##` sections in this file |
|---|---|---|---|---|
| memory | memory.part1of3.md | 22459 | a3e8fc767a871c9b | CLAUDE.md vs auto memory; CLAUDE.md files |
| memory | memory.part2of3.md | 22433 |  | AGENTS.md; Claude Code; Auto memory; View and edit with `/memory` |
| memory | memory.part3of3.md | 6912 |  | Troubleshoot memory issues; Related resources |
| claude-directory | claude-directory.part1of4.md | 24864 | 93f1978339d3a481 | Commands; Stack; Rules; Diff to review; Input Validation; Authentication |
| claude-directory | claude-directory.part2of4.md | 36052 |  | Patterns seen; Recurring issues; Project; Reference; Auth Token Issues; Database Connection Drops |
| claude-directory | claude-directory.part3of4.md | 23103 |  | Explore the directory; What's not shown; Choose the right file; File reference; Frontmatter fields by file; Troubleshoot configuration; Application data |
| claude-directory | claude-directory.part4of4.md | 8862 |  | Related resources |
| context-window | context-window.part1of3.md | 35842 | a375193efcb09a53 |  |
| context-window | context-window.part2of3.md | 23909 |  | What the timeline shows; What survives compaction; When your context fills up |
| context-window | context-window.part3of3.md | 1044 |  | Check your own session; Related resources |
| best-practices | best-practices.part1of2.md | 21716 | 3f2d4f1a6eeba4cb | Give Claude a way to verify its work; Explore first, then plan, then code; Provide specific context in your prompts; Configure your environment; Communicate effectively; Manage your session |
| best-practices | best-practices.part2of2.md | 14973 |  | Automate and scale; Avoid common failure patterns; Develop your intuition; Related resources |
| large-codebases | large-codebases.part1of2.md | 23320 | e3876d436261084d | What this guide covers; Choose where to start Claude; Layer CLAUDE.md files by directory; Reduce what Claude reads; Scope worktrees and file access |
| large-codebases | large-codebases.part2of2.md | 11147 |  | Add per-directory skills; Test structure; Running tests; Test utilities; Patterns; Centralize conventions when layering stops scaling; Put it together; Scope and plan changes that span packages; Next steps |
| features-overview | features-overview.part1of2.md | 27383 | b5a7d0ad57b45975 | Overview; Match features to your goal; Understand context costs |
| features-overview | features-overview.part2of2.md | 1358 |  | Learn more |
| debug-your-config | debug-your-config.md | 15949 | 44280de02450ce25 | See what loaded into context; Check resolved settings; Check MCP servers; Check hooks; Test against a clean configuration; Check common causes; Related resources |
| hooks-guide | hooks-guide.part1of3.md | 22316 | 24c62108fe59fae6 | Set up your first hook; What you can automate |
| hooks-guide | hooks-guide.part2of3.md | 21826 |  | How hooks work |
| hooks-guide | hooks-guide.part3of3.md | 17457 |  | Prompt-based hooks; Agent-based hooks; HTTP hooks; Limitations and troubleshooting; Learn more |
| skills | skills.part1of5.md | 34325 | 122b065227f63905 | Bundled skills; Getting started |
| skills | skills.part2of5.md | 21772 |  | Configure skills |
| skills | skills.part3of5.md | 23222 |  | Additional resources; Advanced patterns; Pull request context; Your task; Environment |
| skills | skills.part4of5.md | 21778 |  | Evaluate and iterate on a skill; Share skills; Usage; What the visualization shows; Troubleshooting |
| skills | skills.part5of5.md | 5331 |  | Related resources |
| sub-agents | sub-agents.part1of5.md | 31656 | 7d245a15843f5470 | Built-in subagents; Quickstart: create your first subagent; Configure subagents |
| sub-agents | sub-agents.part2of5.md | 27071 |  |  |
| sub-agents | sub-agents.part3of5.md | 23854 |  | Work with subagents |
| sub-agents | sub-agents.part4of5.md | 21924 |  | Fork the current conversation; Example subagents |
| sub-agents | sub-agents.part5of5.md | 3402 |  | Next steps |
| hooks | hooks.part1of10.md | 28330 | 403645d3a96659f4 | Hook lifecycle; Configuration |
| hooks | hooks.part2of10.md | 22884 |  |  |
| hooks | hooks.part3of10.md | 34488 |  | Hook input and output |
| hooks | hooks.part4of10.md | 23072 |  | Hook events |
| hooks | hooks.part5of10.md | 31806 |  |  |
| hooks | hooks.part6of10.md | 24327 |  |  |
| hooks | hooks.part7of10.md | 22782 |  |  |
| hooks | hooks.part8of10.md | 23978 |  |  |
| hooks | hooks.part9of10.md | 22296 |  | Prompt-based hooks |
| hooks | hooks.part10of10.md | 17347 |  | Agent-based hooks; Run hooks in the background; Security considerations; Windows PowerShell tool; Debug hooks |
| settings | settings.part1of3.md | 22013 | 5c41248aea5764d3 | Settings files and who they affect |
| settings | settings.part2of3.md | 23349 |  | Change a setting; Settings precedence |
| settings | settings.part3of3.md | 12266 |  | Settings in cloud sessions; What's next |
| settings-reference | settings-reference.part1of18.md | 35966 | 336052874e175d06 | Settings index |
| settings-reference | settings-reference.part2of18.md | 33073 |  |  |
| settings-reference | settings-reference.part3of18.md | 24169 |  | Model and responses |
| settings-reference | settings-reference.part4of18.md | 22153 |  | Permission settings |
| settings-reference | settings-reference.part5of18.md | 21717 |  | Sandbox settings |
| settings-reference | settings-reference.part6of18.md | 22117 |  |  |
| settings-reference | settings-reference.part7of18.md | 22314 |  |  |
| settings-reference | settings-reference.part8of18.md | 23688 |  | Memory and context |
| settings-reference | settings-reference.part9of18.md | 21883 |  | Interface and terminal |
| settings-reference | settings-reference.part10of18.md | 22213 |  |  |
| settings-reference | settings-reference.part11of18.md | 21772 |  | Git and attribution; Hooks and automation |
| settings-reference | settings-reference.part12of18.md | 24666 |  | Plugins and skills |
| settings-reference | settings-reference.part13of18.md | 23996 |  | MCP |
| settings-reference | settings-reference.part14of18.md | 22298 |  | Agents, sessions, and worktrees; Remote, desktop, and notifications |
| settings-reference | settings-reference.part15of18.md | 23730 |  | Authentication and providers |
| settings-reference | settings-reference.part16of18.md | 24530 |  | Updates and versioning; Tools; Privacy and telemetry; Enterprise and managed settings |
| settings-reference | settings-reference.part17of18.md | 22627 |  | Global config settings |
| settings-reference | settings-reference.part18of18.md | 8123 |  | See also |
| permissions | permissions.part1of4.md | 32208 | 5968a6bf06e691b5 | Permission system; Manage permissions; Permission modes; Permission rule syntax; Tool-specific permission rules |
| permissions | permissions.part2of4.md | 23468 |  | Extend permissions with hooks |
| permissions | permissions.part3of4.md | 21831 |  | Working directories; How permissions interact with sandboxing; Managed settings; Settings precedence; Project allow rules and workspace trust |
| permissions | permissions.part4of4.md | 928 |  | Example configurations; See also |
| permission-modes | permission-modes.part1of4.md | 26027 | b6c78ae3ef22a18d | Available modes; Common setups; Switch permission modes |
| permission-modes | permission-modes.part2of4.md | 29978 |  | Auto-approve file edits with acceptEdits mode; Analyze before you edit with plan mode |
| permission-modes | permission-modes.part3of4.md | 23329 |  | Allow only pre-approved tools with dontAsk mode; Skip all checks with bypassPermissions mode; Protected paths |
| permission-modes | permission-modes.part4of4.md | 10715 |  | Critical paths; See also |
| workflows | workflows.part1of2.md | 22962 | b8bcf57ea428c0d7 | When to use a workflow; Run a bundled workflow; Have Claude write a workflow; Example workflow prompts |
| workflows | workflows.part2of2.md | 16225 |  | How a workflow runs; Manage runs; Related resources |
| prompt-caching | prompt-caching.part1of2.md | 23285 | c0c7f0fda35b26ca | How the cache is organized; Actions that invalidate the cache |
| prompt-caching | prompt-caching.part2of2.md | 19445 |  | Actions that keep the cache; Resuming a session; Cache lifetime; Cache scope; Check cache performance; Subagents and the cache; Disable prompt caching; Related resources |
| claude-code-on-the-web | claude-code-on-the-web.part1of2.md | 21950 | 8d8dafb92ee1a351 | Cloud environments; GitHub authentication options; Move tasks between terminal and cloud; Work with sessions |
| claude-code-on-the-web | claude-code-on-the-web.part2of2.md | 18253 |  | Auto-fix pull requests; Security and isolation; Troubleshooting; Limitations; Related resources |
| cloud-environments | cloud-environments.part1of3.md | 22080 | 8c54460a12a00943 | The Default environment; Configure your environment; Network access |
| cloud-environments | cloud-environments.part2of3.md | 22227 |  | What's available in cloud sessions; Setup scripts |
| cloud-environments | cloud-environments.part3of3.md | 16292 |  | Default allowed domains; Related resources |
