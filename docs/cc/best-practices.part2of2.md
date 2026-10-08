[Part 2/2 of https://code.claude.com/docs/en/best-practices.md, fetched 2026-10-08]

### Course-correct early and often

<Tip>
  Correct Claude as soon as you notice it going off track.
</Tip>

The best results come from tight feedback loops. Though Claude occasionally solves problems perfectly on the first attempt, correcting it quickly generally produces better solutions faster.

* **`Esc`**: stop Claude mid-action with the `Esc` key. Context is preserved, so you can redirect.
* **`Esc + Esc` or `/rewind`**: press `Esc` twice or run `/rewind` to open the rewind menu and restore previous conversation and code state, or summarize from a selected message.
* **`"Undo that"`**: have Claude revert its changes.
* **`/clear`**: reset context between unrelated tasks. Long sessions with irrelevant context can reduce performance.

If you've corrected Claude more than twice on the same issue in one session, the context is cluttered with failed approaches. Run `/clear` and start fresh with a more specific prompt that incorporates what you learned. A clean session with a better prompt almost always outperforms a long session with accumulated corrections.

### Manage context aggressively

<Tip>
  Run `/clear` between unrelated tasks to reset context.
</Tip>

Claude Code automatically compacts conversation history when you approach context limits, which preserves important code and decisions while freeing space.

During long sessions, Claude's context window can fill with irrelevant conversation, file contents, and commands. This can reduce performance and sometimes distract Claude.

* Use `/clear` frequently between tasks to reset the context window entirely
* When auto compaction triggers, Claude summarizes what matters most, including code patterns, file states, and key decisions
* For more control, run `/compact <instructions>`, like `/compact Focus on the API changes`
* To compact only part of the conversation, use `Esc + Esc` or `/rewind`, select a message checkpoint, and choose **Summarize from here** or **Summarize up to here**. The first condenses messages from that point forward while keeping earlier context intact; the second condenses earlier messages while keeping recent ones in full. See [the rewind menu's summarize options](/docs/en/checkpointing#rewind-and-summarize).
* Customize compaction behavior in CLAUDE.md with instructions like `"When compacting, always preserve the full list of modified files and any test commands"` to ensure critical context survives summarization
* For questions that don't need to stay in context, use [`/btw`](/docs/en/interactive-mode#side-questions-with-%2Fbtw). The answer never enters conversation history, so you can check a detail without growing context.

### Use subagents for investigation

<Tip>
  Delegate research with `"use subagents to investigate X"`. They explore in a separate context, keeping your main conversation clean for implementation.
</Tip>

Since context is your fundamental constraint, use subagents to keep research out of it. When Claude researches a codebase it reads lots of files, all of which consume your context. Subagents run in separate context windows and report back summaries:

```text wrap theme={null}
Use subagents to investigate how our authentication system handles token
refresh, and whether we have any existing OAuth utilities I should reuse.
```

You can also use subagents for verification after Claude implements something. See [Add an adversarial review step](#add-an-adversarial-review-step).

### Rewind with checkpoints

<Tip>
  Every prompt you send that starts a turn creates a checkpoint. You can restore conversation, code, or both to any previous checkpoint.
</Tip>

Claude automatically snapshots files before each change so a checkpoint can restore them. Double-tap `Escape` or run `/rewind` to open the rewind menu. You can restore conversation only, restore code only, restore both, or summarize from a selected message. See [Checkpointing](/docs/en/checkpointing) for details.

Instead of carefully planning every move, you can tell Claude to try something risky. If it doesn't work, rewind and try a different approach. Checkpoints are saved with the conversation, so you can close your terminal, resume the session later, and still rewind.

<Warning>
  Checkpoints only track changes made through Claude's file editing tools. Changes made through Bash commands or external processes are not captured. This isn't a replacement for git.
</Warning>

### Resume conversations

<Tip>
  Name sessions with `/rename` and treat them like branches: each workstream gets its own persistent context.
</Tip>

Claude Code saves conversations locally, so when a task spans multiple sittings you don't have to re-explain the context. Run [`claude --continue`](/docs/en/sessions#resume-a-session) to pick up where you left off, or `claude --resume` to choose from a list. Give sessions descriptive names like `oauth-migration` so you can find them later. See [Manage sessions](/docs/en/sessions) for the full set of resume, branch, and naming controls.

***

## Automate and scale

Once you're effective with one Claude, multiply your output with parallel sessions, non-interactive mode, and fan-out patterns.

### Run non-interactive mode

<Tip>
  Use `claude -p "prompt"` in CI, pre-commit hooks, or scripts. Add `--output-format stream-json --verbose` for streaming JSON output.
</Tip>

With `claude -p "your prompt"`, you can run Claude non-interactively, without an interactive prompt. The run still creates a resumable session unless you pass `--no-session-persistence`. [Non-interactive mode](/docs/en/headless) is how you integrate Claude into CI pipelines, pre-commit hooks, or any automated workflow. The output formats let you parse results programmatically: plain text, JSON, or streaming JSON.

```bash theme={null}
# One-off queries
claude -p "Explain what this project does"

# Structured output for scripts
claude -p "List all API endpoints" --output-format json

# Streaming for real-time processing
claude -p "Analyze this log file" --output-format stream-json --verbose
```

The first command prints plain text. The `json` format returns a single JSON object with a `result` field. The `stream-json` format prints one JSON object per line, starting with an init event.

### Run multiple Claude sessions

<Tip>
  Run multiple Claude sessions in parallel to speed up development, run isolated experiments, or start complex workflows.
</Tip>

Pick the parallel approach that fits how much coordination you want to do yourself, and add messaging when the sessions need to pass findings between them:

* [Worktrees](/docs/en/worktrees): run separate CLI sessions in isolated git checkouts so edits don't collide
* [Cross-session messaging](/docs/en/cross-session-messaging): let the sessions you run yourself pass findings to each other
* [Desktop app](/docs/en/desktop#work-in-parallel-with-sessions): manage multiple local sessions visually, optionally each in its own worktree
* [Use Claude Code in the cloud](/docs/en/claude-code-on-the-web): run sessions on Anthropic-managed infrastructure by default
* [Agent view](/docs/en/agent-view): research preview. Run `claude agents` to dispatch sessions that keep running in the background and watch them from one screen
* [Agent teams](/docs/en/agent-teams): experimental and disabled by default. Automated coordination of multiple sessions with shared tasks, messaging, and a team lead

Beyond parallelizing work, multiple sessions enable quality-focused workflows. A fresh context improves code review since Claude won't be biased toward code it just wrote.

For example, use a Writer/Reviewer pattern:

| Session A (Writer) | Session B (Reviewer) |
| - | - |
| `Implement a rate limiter for our API endpoints` | |
| | `Review the rate limiter implementation in @src/middleware/rateLimiter.ts. Look for edge cases, race conditions, and consistency with our existing middleware patterns.` |
| `Here's the review feedback: [Session B output]. Address these issues.` | |

You can do something similar with tests: have one Claude write tests, then another write code to pass them.

### Fan out across files

<Tip>
  Loop through tasks calling `claude -p` for each. Use `--allowedTools` to pre-approve tools for batch operations.
</Tip>

For large migrations or analyses, you can distribute work across many parallel Claude invocations. Run [`/batch <instruction>`](/docs/en/commands#all-commands) to have Claude split the change across 5 to 30 subagents. Each subagent works in its own worktree. To drive the fan-out from your own script instead, loop over `claude -p`:

<Steps>
  <Step title="Generate a task list">
    Have Claude write the list of files that need migrating to a file, so the loop in the next step can read it, with a prompt like `list all 2,000 Python files that need migrating and save the list to files.txt`
  </Step>

  <Step title="Write a script to loop through the list">
    ```bash theme={null}
    for file in $(cat files.txt); do
      claude -p "Migrate $file from Python 2 to Python 3. Return OK or FAIL." \
        --allowedTools "Edit,Bash(git commit *)" \
        --permission-mode dontAsk
    done
    ```
  </Step>

  <Step title="Test on a few files, then run on all of them">
    Refine your prompt based on what goes wrong with the first 2-3 files, then run on the full set. The `--allowedTools` flag pre-approves the tools the migration needs, and [`--permission-mode dontAsk`](/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode) denies anything else that would need approval, which matters when you're running unattended.
  </Step>
</Steps>

You can also integrate Claude into existing data/processing pipelines:

```bash theme={null}
claude -p "<your prompt>" --output-format json | your_command
```

### Run autonomously with auto mode

For uninterrupted execution with background safety checks, use [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode). A classifier model reviews commands before they run, blocking scope escalation, unknown infrastructure, and hostile-content-driven actions while letting routine work proceed without prompts.

```bash theme={null}
claude --permission-mode auto -p "fix all lint errors"
```

When the classifier repeatedly blocks actions in a non-interactive run with the `-p` flag, Claude Code doesn't stop the run. See [when auto mode falls back](/docs/en/permission-modes#when-auto-mode-falls-back) for what happens instead and for the thresholds.

### Add an adversarial review step

<Tip>
  Before treating a task as done, have a subagent review the diff in a fresh context and report gaps.
</Tip>

The longer Claude works unattended, the more an independent check matters before you count the work as done. A reviewer running in a fresh [subagent](/docs/en/sub-agents) context sees only the diff and the criteria you give it, not the reasoning that produced the change, so it evaluates the result on its own terms.

For a correctness check, run the bundled [`/code-review` skill](/docs/en/commands), which reviews the current diff for bugs in a fresh subagent and returns findings to the session. To check the diff against your plan instead, write the review prompt yourself. Name the work to check, the plan to check it against, and what counts as a finding:

```text wrap theme={null}
Use a subagent to review the rate limiter diff against PLAN.md. Check that
every requirement is implemented, the listed edge cases have tests, and
nothing outside the task's scope changed. Report gaps, not style preferences.
```

Because the reviewer runs as a subagent, the implementing session receives the gaps directly and can fix them and re-review without you copying findings between windows.

<Callout>
  A reviewer prompted to find gaps will usually report some, even when the work is sound, because that is what it was asked to do. Chasing every finding leads to over-engineering: extra abstraction layers, defensive code, and tests for cases that can't happen. Tell the reviewer to flag only gaps that affect correctness or the stated requirements, and treat the rest as optional.
</Callout>

***

## Avoid common failure patterns

These are common mistakes. Recognizing them early saves time:

* **The kitchen sink session.** You start with one task, then ask Claude something unrelated, then go back to the first task. Context is full of irrelevant information.
  > **Fix**: `/clear` between unrelated tasks.
* **Correcting over and over.** Claude does something wrong, you correct it, it's still wrong, you correct again. Context is polluted with failed approaches.
  > **Fix**: After two failed corrections, `/clear` and write a better initial prompt incorporating what you learned.
* **The over-specified CLAUDE.md.** If your CLAUDE.md is too long, Claude ignores half of it because important rules get lost in the noise.
  > **Fix**: Ruthlessly prune. If Claude already does something correctly without the instruction, delete it or convert it to a hook.
* **The trust-then-verify gap.** Claude produces a plausible-looking implementation that doesn't handle edge cases.
  > **Fix**: Always provide verification (tests, scripts, screenshots). If you can't verify it, don't ship it.
* **The infinite exploration.** You ask Claude to "investigate" something without scoping it. Claude reads hundreds of files, filling the context.
  > **Fix**: Scope investigations narrowly or use subagents so the exploration doesn't consume your main context.

***

## Develop your intuition

The patterns in this guide aren't set in stone. They're starting points that work well in general, but might not be optimal for every situation.

Sometimes you *should* let context accumulate because you're deep in one complex problem and the history is valuable. Sometimes you should skip planning and let Claude figure it out because the task is exploratory. Sometimes a vague prompt is exactly right because you want to see how Claude interprets the problem before constraining it.

Pay attention to what works. When Claude produces great output, notice what you did: the prompt structure, the context you provided, the mode you were in. When Claude struggles, ask why. Was the context too noisy? The prompt too vague? The task too big for one pass?

Over time, you'll develop intuition that no guide can capture. You'll know when to be specific and when to be open-ended, when to plan and when to explore, when to clear context and when to let it accumulate.

## Related resources

* [How Claude Code works](/docs/en/how-claude-code-works): the agentic loop, tools, and context management
* [Extend Claude Code](/docs/en/features-overview): skills, hooks, MCP, subagents, and plugins
* [Common workflows](/docs/en/common-workflows): step-by-step recipes for debugging, testing, PRs, and more
* [CLAUDE.md](/docs/en/memory): store project conventions and persistent context
