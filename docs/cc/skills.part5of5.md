[Part 5/5 of https://code.claude.com/docs/en/skills.md, fetched 2026-10-08]

### Skill triggers too often

If Claude uses your skill when you don't want it:

1. Make the description more specific
2. Add `disable-model-invocation: true` if you only want manual invocation

### Claude stops following a skill

If Claude follows a skill in its first response and stops following it later, start with whichever of these cases matches:

* **Claude skipped a rule that must hold every time**: move the rule into a [hook](/docs/en/hooks-guide). Claude Code runs a hook every time its event occurs, such as before each file edit, whether or not Claude is following the skill. To keep the rule with the skill, define the hook in the skill's [`hooks` frontmatter](/docs/en/hooks#hooks-in-skills-and-agents). That hook applies from the time the skill is invoked until the session ends.
* **Claude skipped guidance it should apply with judgment**: word the guidance so it applies to the whole task, for example "Run the tests after every edit" rather than "Run the tests". Claude Code adds the skill's content to the conversation when the skill is invoked and [doesn't re-read the file](#skill-content-lifecycle) on later turns.
* **The conversation was compacted**: invoke the skill again to restore its full content. After [compaction](/docs/en/how-claude-code-works#when-context-fills-up), Claude Code [can keep only the start of an invoked skill](#skill-content-lifecycle), so put the most important instructions near the top of `SKILL.md`.

### Skill descriptions are cut short

Claude Code loads a listing of skill names and descriptions into context so Claude knows what's available. The listing always contains every skill name, but if you have many skills, Claude Code drops some descriptions to fit the listing's character budget, which removes the keywords Claude needs to match your request. The budget scales at 1% of the model's context window. When the listing overflows, Claude Code drops descriptions starting with the skills you invoke least, so the skills you use most keep their full text.

Run `/doctor` for an estimate of the listing's context cost and its biggest contributors. To find skills worth turning off, run [`/skill-doctor`](#find-unused-skills). When the listing exceeds its budget, Claude Code also writes a warning to the debug log, visible with [`--debug`](/docs/en/cli-reference#cli-flags).

The Skills row in `/context` reports the size of the listing after the budget is applied, so it matches what the model receives. Before v2.1.196, the row counted the full text of every description and could show a value several times larger than the configured budget.

To raise the budget, set the [`skillListingBudgetFraction`](/docs/en/settings-reference#skilllistingbudgetfraction) setting (for example, `0.02` = 2%) or the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable to a fixed character count. To free budget for other skills, set low-priority entries to `"name-only"` in [`skillOverrides`](#override-skill-visibility-from-settings) so they list without a description. You can also trim the `description` and `when_to_use` text at the source: put the key use case first, since each entry's combined text is capped at 1,536 characters regardless of budget. The cap is configurable with [`skillListingMaxDescChars`](/docs/en/settings-reference#skilllistingmaxdescchars).

### Personal skills disappeared

If skill folders you created in `~/.claude/skills/` are gone, look in `~/.claude/skills/.trash/`. When Claude Code [syncs skills from claude.ai](#how-synced-skills-behave), it downloads them into the separate `synced` subfolder and doesn't move or delete the folders you create.

Before v2.1.280, a file named `manifest.json` in `~/.claude/skills/` caused Claude Code to move the skill folders that file listed into a timestamped folder under `~/.claude/skills/.trash/`, and those skills stopped loading.

To restore a skill, move its folder from the timestamped folder back into `~/.claude/skills/`. Do this before the [retention sweep](/docs/en/claude-directory#cleaned-up-automatically) deletes trash entries, by default 30 days after they were moved to the trash.

## Related resources

* **[Debug your configuration](/docs/en/debug-your-config)**: diagnose why a skill isn't appearing or triggering
* **[Evaluating skill output quality](https://agentskills.io/skill-creation/evaluating-skills)**: the eval file format and iteration workflow on agentskills.io
* **[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)**: writing guidance that applies across Claude products
* **[Subagents](/docs/en/sub-agents)**: delegate tasks to specialized agents
* **[Plugins](/docs/en/plugins/overview)**: package and distribute skills with other extensions
* **[Hooks](/docs/en/hooks)**: automate workflows around tool events
* **[Memory](/docs/en/memory)**: manage CLAUDE.md files for persistent context
* **[Commands](/docs/en/commands)**: reference for built-in commands and bundled skills
* **[Permissions](/docs/en/permissions)**: control tool and skill access
* **[Claude Tag skills](https://claude.com/docs/claude-tag/admins/skills-repo)**: project skills committed to a repo also load when that repo is used in a Claude Tag channel
