[Part 1/5 of https://code.claude.com/docs/en/skills.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Extend Claude with skills

> Create, manage, and share skills to extend Claude's capabilities in Claude Code. Includes custom commands and bundled skills.

Skills extend what Claude can do. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with `/skill-name`.

Create a skill when you keep pasting the same instructions, checklist, or multi-step procedure into chat, or when a section of CLAUDE.md has grown into a procedure rather than a fact. Unlike CLAUDE.md content, a skill's body loads only when it's used, so long reference material costs almost nothing until you need it.

<Note>
  For built-in commands like `/help` and `/compact`, and bundled skills like `/debug` and `/code-review`, see the [commands reference](/docs/en/commands).

  **Custom commands have been merged into skills.** A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way. Your existing `.claude/commands/` files keep working. Skills add optional features: a directory for supporting files, frontmatter to [control whether you or Claude invokes them](#control-who-invokes-a-skill), and the ability for Claude to load them automatically when relevant.
</Note>

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, which works across multiple AI tools. Claude Code extends the standard with additional features like [invocation control](#control-who-invokes-a-skill), [subagent execution](#run-skills-in-a-subagent), and [dynamic context injection](#inject-dynamic-context). See [Using skill frontmatter outside Claude Code](#using-skill-frontmatter-outside-claude-code) for which frontmatter fields are part of the standard and which are Claude Code extensions.

## Bundled skills

Claude Code includes a set of bundled skills, such as `/doctor`, `/code-review`, `/batch`, `/debug`, `/loop`, and `/claude-api`. Bundled skills are prompt-based: they give Claude detailed instructions and let it orchestrate the work using its tools. Most built-in commands instead execute fixed logic directly.

You invoke a bundled skill the same way as any other skill, by typing `/` followed by the skill name. Claude invokes some bundled skills automatically when relevant; others, including `/verify`, run only when you invoke them, which keeps you in control of when these longer-running checks spend time and tokens.

Most bundled skills are available in every session. A few depend on a specific feature: `/workflow-authoring`, for example, is available only when [dynamic workflows](/docs/en/workflows) are enabled.

To turn bundled skills off, use the [`disableBundledSkills`](/docs/en/settings-reference#disablebundledskills) setting.

<Note>
  The [`/doctor`](/docs/en/commands#all-commands) setup checkup stays typable when `disableBundledSkills` is on, in Claude Code v2.1.205 and later. To hide it, set the `DISABLE_DOCTOR_COMMAND` environment variable or a [`skillOverrides`](#override-skill-visibility-from-settings) entry of `"doctor": "off"`. Before v2.1.205, `/doctor` was a built-in command rather than a bundled skill.
</Note>

Bundled skills are listed alongside built-in commands in the [commands reference](/docs/en/commands), marked **Skill** in the Purpose column.

### Check your setup with `/doctor`

Run `/doctor` at the Claude Code prompt for a setup checkup that diagnoses issues and can fix them. Claude reports its findings first and asks for confirmation before changing anything. The checkup covers these areas:

* **Installation health**: duplicate or leftover installs, `PATH` problems, unparseable settings files, and whether a newer version is available on your [release channel](/docs/en/setup#configure-release-channel)
* **Extensions**: unused skills, MCP servers, and plugins compared with their context cost, and slow [hooks](/docs/en/hooks)
* **`CLAUDE.md` files**: local `CLAUDE.md` files that duplicate checked-in ones, checked-in [`CLAUDE.md` content Claude could derive from the codebase](/docs/en/memory#my-claude-md-is-too-large), and the always-loaded guidance that remains, which Claude offers to migrate into skills and nested `CLAUDE.md` files that load on demand
* **Permissions**: an offer to make [auto mode](/docs/en/permissions#permission-modes) your default permission mode and to [pre-approve](/docs/en/permissions) read-only commands that you frequently deny

For read-only installation diagnostics without starting a session, run `claude doctor` in your terminal instead.

To audit your instructions rather than your setup, run `/doctor prompt-audit` at the Claude Code prompt. Claude [checks your `CLAUDE.md` files, skills, and other configuration](/docs/en/memory#audit-your-instruction-files) for outdated or conflicting instructions instead of running the checkup. The `prompt-audit` subcommand requires Claude Code v2.1.283 or later.

### Run and verify your app

Three bundled skills work together to launch your app and confirm changes against the running app instead of tests alone:

| Skill | Purpose |
| :- | :- |
| `/run` | Launch and drive your app to see a change working |
| `/verify` | Build and run your app to confirm a code change does what it should, without falling back to tests or type checks |
| `/run-skill-generator` | Teach `/run` and `/verify` how to build and launch your project |

`/run` and `/verify` work without setup. They infer the launch from your project type (CLI, server, TUI, browser-driven) and from what's in your README, `package.json`, or `Makefile`. That inference gets unreliable for projects that need anything beyond a standard launch: a database, an env file, a graphical session, a multi-step build.

`/run-skill-generator` records the recipe instead. It gets your app running from a clean environment, captures what worked (the install commands, the env vars, the launch script), and commits it as a per-project skill at `.claude/skills/run-<name>/`. After that, `/run`, `/verify`, and any other agent in the repo follow the recorded recipe instead of rediscovering it. Run `/run-skill-generator` once per project, and again if the build or launch process changes.

`/verify` can also record its own recipe. When it has to build and drive your app without a recorded recipe, it writes what worked to `.claude/skills/verify/SKILL.md` at the repo root, or in the touched package directory in a monorepo, so later runs and other agents follow the same steps. At the repo root, the recorded skill replaces the bundled `/verify`.

Claude edits the recorded file only when it steered a run wrong, such as a command that failed or a missing step, so you can commit the file without per-session diffs. Before v2.1.205, the bundled skill told Claude to fold in anything a run learned, which caused frequent merge conflicts.

### Run your checks before each commit

When a session starts with a skill named `verify` or `simplify` in place, Claude Code's commit instructions tell Claude to run it right before each commit, except for changes to docs or tests. This requires Claude Code v2.1.286 or later. Claude gets that instruction when these conditions hold at the start of the session:

* **Location**: the skill loads from the enterprise, personal, project, or additional-directory [location](#where-skills-live), or from a `.claude/commands/` file with that name. The recipe that `/verify` records at your repo root is a project skill, so it counts. The bundled `/verify` and `/simplify`, plugin skills, and skills from your claude.ai account don't count.
* **Invocation**: Claude can invoke the skill. If you've [stopped Claude from invoking it](#control-who-invokes-a-skill), for example with `disable-model-invocation: true`, Claude doesn't get the instruction.
* **Git instructions**: you haven't turned off [`includeGitInstructions`](/docs/en/settings-reference#includegitinstructions). Turning it off removes this instruction together with the rest of the built-in commit and PR instructions.

### Work on Claude API projects

The bundled `/claude-api` skill loads [Claude API](https://platform.claude.com/docs/en/api/overview) and [Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview) reference material for your project's language. Claude also activates it automatically when your code imports `anthropic` or `@anthropic-ai/sdk`.

To start one of the skill's workflows, type a subcommand after the skill name at the Claude Code prompt, for example `/claude-api migrate`. The table lists what each subcommand does and the earliest Claude Code version that includes it. `migrate` and `managed-agents-onboard` predate v2.1.221, the oldest version the table tracks.

| Subcommand | What it does | Minimum version |
| :- | :- | :- |
| `migrate` | Update your existing Claude API code to a newer model | Earlier than v2.1.221 |
| `upgrade` | Move your project's Anthropic SDK dependency across a major version, currently the Python `anthropic` package from 0.x to 1.x | v2.1.236 or later |
| `managed-agents-onboard` | Walk through creating a new Managed Agent | Earlier than v2.1.221 |
| `prompt-audit` | Flag instructions written for older models in your prompts, skills, and tool descriptions and propose fixes as a diff | v2.1.221 or later |
| `cost-optimize` | Profile where your project's Claude API spend goes and propose savings from options such as prompt caching, trimming unneeded input and output tokens, batch processing, effort, and model choice, one change at a time | v2.1.247 or later |
| `build-eval` | Build an eval set for your Claude-powered app | v2.1.259 or later |
| `hillclimb` | Iteratively improve your app against an existing eval | v2.1.259 or later |
| `preserved-thinking-migration` | Find the edits your integration makes to earlier turns, its system prompt, or its tool list that invalidate [preserved thinking](https://platform.claude.com/docs/en/build-with-claude/preserved-thinking) blocks, measure how much reasoning each one drops, and propose fixes one at a time, re-measuring after each change | v2.1.282 or later |

## Getting started

### Create your first skill

This example creates a skill that summarizes the uncommitted changes in your git repository and flags anything risky. It pulls the live diff into the prompt before Claude reads it, so the response is grounded in your actual working tree rather than what Claude can guess from open files. Claude loads the skill automatically when you ask about your changes, or you can invoke it directly with `/summarize-changes`.

<Steps>
  <Step title="Create the skill directory">
    Create a directory for the skill in your personal skills folder. Personal skills are available across all your projects.

    ```bash theme={null}
    mkdir -p ~/.claude/skills/summarize-changes
    ```
  </Step>

  <Step title="Write SKILL.md">
    Every skill needs a `SKILL.md` file with two parts: YAML frontmatter between `---` markers that tells Claude when to use the skill, and markdown content with the instructions Claude follows when the skill runs. The directory name, or the frontmatter `name` when you set one, becomes the command you type, and the `description` helps Claude decide when to load the skill automatically.

    Save this to `~/.claude/skills/summarize-changes/SKILL.md`:

    ```yaml theme={null}
    ---
    description: Summarizes uncommitted changes and flags anything risky. Use when the user asks what changed, wants a commit message, or asks to review their diff.
    ---

    ## Current changes

    !`git diff HEAD`

    ## Instructions

    Summarize the changes above in two or three bullet points, then list any risks you notice such as missing error handling, hardcoded values, or tests that need updating. If the diff is empty, say there are no uncommitted changes.
    ```

    The `` !`git diff HEAD` `` line uses [dynamic context injection](#inject-dynamic-context): Claude Code runs the command and replaces the line with its output before Claude sees the skill content, so the instructions arrive with the current diff already inlined.
  </Step>

  <Step title="Test the skill">
    Open a git project, make a small edit to any file, and start Claude Code by running `claude`. You can test the skill two ways.

    **Let Claude invoke it automatically** by asking something that matches the description:

    ```text theme={null}
    What did I change?
    ```

    **Or invoke it directly** with the skill name:

    ```text theme={null}
    /summarize-changes
    ```

    Either way, Claude should respond with a short summary of your edit and a list of risks.
  </Step>
</Steps>

<h2 id="where-skills-live">
  Choose where skills load
</h2>

Where you save a skill decides which sessions load it. Save it under your home directory to get it in every project, commit it to a repository to share it with everyone who works there, or distribute it through a plugin or managed settings to reach a whole team.

| Location | Path | Loads in |
| :- | :- | :- |
| Enterprise | `.claude/skills/<skill-name>/SKILL.md` in the [managed settings directory](/docs/en/managed-settings#delivery-mechanisms) | All users on machines where your organization deploys it |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects on this machine, but not [Cowork or cloud sessions](#skills-in-cowork-and-cloud-sessions) |
| Project | `.claude/skills/<skill-name>/SKILL.md` | Sessions in this repository. Commit it so your team gets it too |
| Nested | `<subdir>/.claude/skills/<skill-name>/SKILL.md` | Sessions started in or below `<subdir>`. A session started above it loads the skill once Claude works on files there. See [monorepos and subdirectories](#discovery-from-parent-and-nested-directories) |
| Additional directory | `.claude/skills/<skill-name>/SKILL.md` in a directory you pass with `--add-dir` | That session. See [directories outside the project](#skills-from-additional-directories) |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Wherever the [plugin](/docs/en/plugins/overview) is enabled, as `/plugin-name:skill-name` |
| claude.ai account | Skills enabled for your claude.ai account | Cowork sessions, cloud sessions, and terminal sessions where you sign in with that account. See [Skills synced from claude.ai](#how-synced-skills-behave) |

Skill folders also follow these rules:

* **Symlinked folders**: a `<skill-name>` entry in the enterprise, personal, or project location can be a symlink to a directory elsewhere on disk. Claude Code reads `SKILL.md` from the target and loads the skill once even if several locations point at the same target. Plugin skills [handle symlinks differently](/docs/en/plugins/host-marketplace#share-files-within-a-marketplace-with-symlinks).
* **Reserved name `synced`**: don't name a skill folder `synced`, in any capitalization. Claude Code uses `~/.claude/skills/synced/` for [skills downloaded from claude.ai](#where-synced-skills-load) and skips a skill you author at that name in the enterprise, personal, and project locations.
* **Reserved name `anthropic-skills`**: outside a plugin, a skill folder or command file whose name is `anthropic-skills` or starts with `anthropic-skills:` doesn't load. See [Names reserved for synced skills](#names-reserved-for-synced-skills).
* **Command files**: a Markdown file in `.claude/commands/` is the older format and still works. It supports the same [frontmatter](#frontmatter-reference) except `name` and `paths`. To find the name you type to invoke it, see [How a skill gets its command name](#how-a-skill-gets-its-command-name). Prefer a skill for new work, since skills also support [supporting files](#add-supporting-files).
* **Skill folder as a plugin**: add a `.claude-plugin/plugin.json` to a skill folder and it loads as a [plugin](/docs/en/plugins/loading#plugins-shared-through-a-repository) named `<name>@skills-dir`, so it can bundle agents, hooks, and MCP servers. In a project's `.claude/skills/`, this requires accepting the workspace trust dialog first.

<h3 id="discovery-from-parent-and-nested-directories">
  Load skills in monorepos and subdirectories
</h3>

Claude Code loads project skills from `.claude/skills/` in the directory where you start it and in every parent directory up to the repository root, so starting in `packages/frontend/` still picks up skills defined at the root. When you [move the session with `/cd`](/docs/en/permissions#move-the-session-to-another-directory) on v2.1.246 or later, Claude Code adds the new directory's project skills.

In a session running in a linked [git worktree](/docs/en/worktrees), Claude Code searches parent directories only up to the worktree root. On Claude Code v2.1.277 or later, when the worktree checkout has no `.claude/skills` directory at its root, Claude Code loads the main checkout's project skills instead. See [What worktrees share with the main checkout](/docs/en/worktrees#what-worktrees-share-with-the-main-checkout).

Skills in a `.claude/skills/` directory below where you started don't load at startup. They load the first time Claude reads or edits a file in that subdirectory and stay available for the rest of the session. Until then they don't appear in the `/` menu and you can't invoke them by name. To load them sooner, run `/add-dir` with the subdirectory's path, which requires Claude Code v2.1.257 or later.

When a nested skill's directory name matches another skill's name, both stay available. With a `deploy` skill at the repository root and another in `apps/web/.claude/skills/`:

* `/deploy` runs the root skill. Claude Code also lists the directory-qualified variants for Claude, with an instruction to invoke the one whose directory holds the files it's working on, so the nested skill still applies to work in `apps/web/`.
* `/apps/web:deploy` runs the nested skill on its own. Its description names the directory it applies to.

<h3 id="skills-from-additional-directories">
  Load skills from a directory outside the project
</h3>

When you add a directory with `--add-dir` or `/add-dir`, Claude Code loads the skills in that directory's `.claude/skills/`, along with its `.claude/commands/` and `.claude/agents/`. Directories the Agent SDK adds through [`additionalDirectories`](/docs/en/agent-sdk/typescript#options) in TypeScript or [`add_dirs`](/docs/en/agent-sdk/python#claudeagentoptions) in Python load the same way, because the SDK passes them as `--add-dir`. The `permissions.additionalDirectories` setting in `settings.json` grants file access only and loads none of these.

Claude Code watches `.claude/skills/` in a directory you pass with `--add-dir` at launch, as [Edit a skill during a session](#live-change-detection) describes. It doesn't watch the added directory's `.claude/commands/` or `.claude/agents/`, so restart the session after changing a file there.

These loads depend on the `project` [setting source](/docs/en/agent-sdk/claude-code-features#control-filesystem-settings-with-settingsources), which is on by default. A [`strictPluginOnlyCustomization`](/docs/en/settings-reference#strictpluginonlycustomization) policy, [bare mode](/docs/en/headless#start-faster-with-bare-mode), and [`--safe-mode`](/docs/en/cli-reference#cli-flags) each restrict them further, as those pages describe. See [Additional directories grant file access, not configuration](/docs/en/permissions#additional-directories-grant-file-access-not-configuration) for the full table of what an added directory loads, including `CLAUDE.md` and plugin settings.

### Resolve skills that share a name

When two skills share a directory or file name, where each one came from decides which one `/name` runs. For a name set by the frontmatter `name` field, see [How a skill gets its command name](#how-a-skill-gets-its-command-name). The table covers the enterprise, personal, project, nested, plugin, and claude.ai locations, bundled skills, built-in commands, and command files:

| Same name in | Which one runs |
| :- | :- |
| Two of enterprise, personal, and project | Enterprise over personal, and personal over project. With `deploy` in both `~/.claude/skills/` and the project's `.claude/skills/`, `/deploy` runs the personal one |
| Any of those locations and a [bundled skill](#bundled-skills) | Your skill replaces the bundled command, but not its aliases. A project `code-review` skill replaces `/code-review`, and the bundled alias `/review` never runs your skill |
| Any of those locations and a [built-in command](/docs/en/commands) | In a local terminal session, your skill replaces the built-in command, but not its aliases. A project `usage` skill replaces `/usage`, and the built-in alias `/cost` still runs the built-in command |
| A skill and a file in `.claude/commands/` | The skill |
| A project-root skill and a nested skill | Both load. See [monorepos and subdirectories](#discovery-from-parent-and-nested-directories) |
| A plugin skill and a skill at any of the locations above | Both load, because plugin skills are namespaced as `/plugin-name:skill-name` |
| Any of the above and the short name of a skill [synced from your claude.ai account](#how-synced-skills-behave) | The other skill or command. The synced skill is then listed and runs only under its full name. See [When a synced skill name matches another command](#when-a-synced-skill-name-matches-another-command) |

<h3 id="skills-in-cowork-and-cloud-sessions">
  Use skills in Cowork and cloud sessions
</h3>

[Cowork](https://claude.com/product/cowork) sessions and [cloud sessions](/docs/en/cloud-environments#what-carries-over-from-your-setup), including [routines](/docs/en/routines), don't read `~/.claude/skills/` on your machine. Both interactive and scheduled Cowork sessions load the skills enabled for your claude.ai account, synced at session start; manage them from **Customize** in the Desktop app sidebar or from the skills settings on claude.ai. Cloud sessions additionally load project skills committed to the cloned repository's `.claude/skills/`.

If a skill exists only in `~/.claude/skills/` on your machine, Claude Code reports that the skill was not found when a [routine](/docs/en/routines) invokes it, because each routine run starts as a fresh cloud session. To make a personal skill available in these sessions:

* For Cowork and cloud sessions, enable the skill for your claude.ai account.
* For cloud sessions, you can instead commit the skill to the repository's `.claude/skills/`. Plugins declared in the repository's `.claude/settings.json` and plugins enabled only in your user settings [don't load in cloud sessions](/docs/en/cloud-environments#what-carries-over-from-your-setup).

[Desktop scheduled tasks](/docs/en/desktop-scheduled-tasks) run locally on your machine, so they do load `~/.claude/skills/`.

<h3 id="how-synced-skills-behave">
  Skills synced from claude.ai
</h3>

This section applies to you if you use Cowork or cloud sessions, or sign in to Claude Code in your terminal with a claude.ai account. In those sessions, Claude Code loads the skills enabled for your claude.ai account, with no setup on your part, as [Where synced skills load](#where-synced-skills-load) describes. Those skills include the ones you create or turn on in your claude.ai settings, skills your organization provides there, and Anthropic's built-in skills such as `pdf` and `xlsx`.

Claude Code downloads a synced skill from your account rather than reading a file you wrote on the machine where the session runs, so it applies rules to synced skills that don't apply to the skills you store in the [skills locations](#where-skills-live).

#### Where synced skills load

In a Cowork or cloud session, Claude Code loads the skills enabled for your claude.ai account, and [Skills in Cowork and cloud sessions](#skills-in-cowork-and-cloud-sessions) says how to choose which skills those sessions get.

In your terminal, Claude Code syncs those skills in sessions where you sign in with your claude.ai account. When the session starts, Claude Code downloads your account's skills into `~/.claude/skills/synced/` in the background, then checks claude.ai for changes while the session runs. When a check finds that a skill was added, edited, or turned off on claude.ai, Claude Code adds, updates, or removes it in the running session without a restart. Syncing in terminal sessions requires Claude Code v2.1.273 or later.

The checks run less often while the session is idle:

* **While you or Claude work in the session**: a check runs about every 10 minutes.
* **While the session is idle**: a check runs about every 40 minutes. When you type in the session again, Claude Code checks within a few minutes if the last check was more than 10 minutes ago.

The sync never delays startup, because Claude waits for a skill's download only when it invokes that skill. A short [non-interactive](/docs/en/headless) run can therefore finish before a newly added skill downloads, in which case a later session downloads it. To make a non-interactive run download your skills and wait for the list before it answers the prompt, set [`CLAUDE_CODE_SYNC_SKILLS`](/docs/en/env-vars#variables) to `1`. Before v2.1.273, terminal sessions downloaded them only in a `-p` run with this variable set.

Claude Code syncs only in a session that signs in with your claude.ai account and [fetches feature flags from Anthropic](/docs/en/env-vars#features-that-need-feature-flag-fetching). It doesn't sync in these sessions:

* A session that doesn't use a sign-in stored by `/login`, such as one that authenticates with an API key, or one where `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, or an `apiKeyHelper` script supplies the credential
* A session that doesn't fetch feature flags, such as one on Amazon Bedrock or one where you set `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`
* A session in [bare mode](/docs/en/headless#start-faster-with-bare-mode) or one you start with `--safe-mode`
* A session where your organization's managed settings [lock skills to plugin sources](/docs/en/settings-reference#strictpluginonlycustomization-skills), or one you start with a [`--setting-sources`](/docs/en/cli-reference#cli-flags) list that leaves out `user`

If you sign in with `/login` during a session, restart Claude Code to start syncing.

Skills that an earlier session synced stay on disk. Claude Code loads them in later sessions signed in to the same account, even when it can't reach claude.ai.

Claude Code downloads synced skills and never uploads them. If you or Claude edit a file under `~/.claude/skills/synced/`, the change isn't saved to your claude.ai account, and a later sync can overwrite or remove it. To change a synced skill, update it on claude.ai; the next sync downloads the new version.

To see which skills synced, run `/skills`. The menu lists them under `claude.ai sync`.

Some of Anthropic's skills, such as `pdf` and `xlsx`, always sync. For the rest, turn a skill on or off in your skills settings on claude.ai to change whether it syncs.

To stop syncing on a machine, set [`syncClaudeAiSkills`](/docs/en/settings-reference#syncclaudeaiskills) to `false` in your user settings. Claude Code stops downloading, and the next time it starts it moves the skills it already synced to `~/.claude/skills/.trash/` and no longer loads them. Your organization can turn syncing off for everyone by turning off Skills on claude.ai. To stop syncing while leaving Skills on, it can set the same key in [managed settings](/docs/en/managed-settings).

If your organization turns Skills off on claude.ai, Claude Code removes the downloaded skills and they stop loading. The removed skills move to `~/.claude/skills/.trash/`, where you can recover the files until the [retention sweep](/docs/en/claude-directory#cleaned-up-automatically) deletes them. Once your organization turns Skills back on, Claude Code downloads the skills you enabled at the next sync.

#### When a synced skill name matches another command

You can invoke a synced skill by its short name, `/<name>`, or by its full name, `/anthropic-skills:<name>`. When another command uses the short name, `/<name>` runs the other command, and the synced skill runs only as `/anthropic-skills:<name>`. With a local `deploy` skill and a synced `deploy`, `/deploy` runs the local skill and `/anthropic-skills:deploy` runs the synced one. Before v2.1.269, a synced skill had only its short name.

In the `/` menu, `/skills`, and `/context`, a synced skill appears under its short name, or under its full name while another command uses the short name. Run `/skills` in your session. A note under the list explains each synced skill that lost its short name. If one of your personal skills or command files in `~/.claude/` uses the name, the note also says what to rename or delete to free it.

From v2.1.269 through v2.1.280, these lists showed every synced skill under its full name, and `/skills` had no such note; both changed in v2.1.281.

The command that uses the short name can be any of these:

* A built-in command or a [bundled skill](#bundled-skills), including one that's unavailable in your session, for example after you turn bundled skills off
* A skill at any [local level](#where-skills-live) or a file in `.claude/commands/`
* A plugin skill
* An [MCP prompt](/docs/en/mcp#use-mcp-prompts-as-commands)

Claude Code labels synced skills so you can tell where they came from. The `/skills` menu and `/context` group synced skills under `claude.ai sync`, and the `/` command menu marks them as coming from claude.ai.

When it compares names, Claude Code ignores case, spacing, and invisible characters, and treats compatibility forms such as fullwidth letters and dash variants as their plain equivalents. For example, a synced skill named `Commit` and a local skill named `commit` count as the same name, so `/commit` keeps running your local skill.

A name that differs only by a look-alike letter from another alphabet counts as a different name, and the `claude.ai sync` label is how you tell the two apart. These checks and labels require Claude Code v2.1.228 or later.

<h4 id="names-reserved-for-synced-skills">
  Names reserved for synced skills
</h4>

Claude Code reserves the name `anthropic-skills`, and every name inside that namespace such as `anthropic-skills:pdf`, for skills synced from claude.ai, so a synced skill's full name never runs anything else. The name is reserved in every session, whether or not you sign in with a claude.ai account.

* **A skill folder, a frontmatter `name`, a file or subfolder in `.claude/commands/`, or a [saved workflow](/docs/en/workflows#save-the-workflow-for-reuse)**: it doesn't load. A [startup notice](/docs/en/errors#a-skill-command-or-workflow-wasnt-loaded-because-its-name-is-reserved) names the first item to rename or edit.
* **A plugin named `anthropic-skills`**: it loads. When one of its skills and a synced skill are both named `<name>`, `/anthropic-skills:<name>` runs the synced skill.
* **An MCP server named `anthropic-skills`**: it connects and its tools work, but [its prompts don't appear as commands](/docs/en/mcp#use-mcp-prompts-as-commands). Rename the server in your MCP configuration to list them.

#### How Claude Code handles the frontmatter of a synced skill

Claude Code applies two rules to a synced skill's frontmatter:

* The frontmatter applies in every kind of session, so an `allowed-tools` grant goes through the normal [permission flow](/docs/en/permissions). If your organization sets `allowManagedPermissionRulesOnly`, the grant [doesn't apply](#when-only-managed-permission-rules-apply).
* Claude Code sanitizes the display text the skill supplies, such as its description. It removes control characters, and in text that reaches Claude, such as the description, it also escapes angle brackets so the text can't imitate Claude Code's internal formatting. This sanitization requires Claude Code v2.1.228 or later.

#### How Claude Code handles the body of a synced skill

What Claude Code does with a synced skill's body depends on where the session runs:

* In a cloud session, the body keeps the behavior a local skill has, because the session runs in an isolated container.
* In a Cowork session on your desktop, the body keeps the behavior a local skill has, except that Claude Code replaces every `!` command line with the [`disableSkillShellExecution` placeholder](#inject-dynamic-context), as it does for every skill you supply there.
* In any other session on your machine, Claude Code doesn't run [`!` commands](#inject-dynamic-context), doesn't attach the files that `@` references name the way it does for a local skill, and doesn't substitute the `${CLAUDE_PROJECT_DIR}` and `${CLAUDE_SESSION_ID}` placeholders, so the `@` references and both placeholders reach Claude as literal text. A `!` command line reaches Claude as literal text too, or as that placeholder when `disableSkillShellExecution` is on. This handling requires Claude Code v2.1.228 or later.

<h3 id="live-change-detection">
  Edit a skill during a session
</h3>

Claude Code watches skill directories for file changes, except in [bare mode](/docs/en/headless#start-faster-with-bare-mode). When you add, edit, or remove a skill under `~/.claude/skills/`, the project `.claude/skills/`, or a `.claude/skills/` inside an `--add-dir` directory, Claude Code picks up the change within the current session, without a restart.

If you create a top-level skills directory that didn't exist when the session started, run [`/reload-skills`](/docs/en/commands#all-commands) to pick up the skills you put there. Claude Code isn't watching that directory yet, so run `/reload-skills` again after each later change there.

Live change detection covers `SKILL.md` text only. For a skill folder that is also a [plugin](/docs/en/plugins/loading#plugins-shared-through-a-repository), changes to `hooks/`, `.mcp.json`, `agents/`, and `output-styles/` need `/reload-plugins` to take effect.
