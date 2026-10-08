[Part 4/5 of https://code.claude.com/docs/en/skills.md, fetched 2026-10-08]

### Restrict Claude's skill access

By default, Claude can invoke any skill that doesn't have `disable-model-invocation: true` set. Skills that define [`allowed-tools`](#pre-approve-tools-for-a-skill) grant Claude access to those tools without per-use approval during the turn that invokes the skill; the grant clears when you send your next message. Your [permission settings](/docs/en/permissions) still govern baseline approval behavior for all other tools. A few built-in commands are also available through the Skill tool, including `/init` and `/security-review`. Other built-in commands such as `/compact` are not.

Three ways to control which skills Claude can invoke:

**Disable all skills** by denying the Skill tool in `/permissions`:

```text theme={null}
# Add to deny rules:
Skill
```

**Allow or deny specific skills** using [permission rules](/docs/en/permissions):

```text theme={null}
# Allow only specific skills
Skill(commit)
Skill(review-pr *)

# Deny specific skills
Skill(deploy *)
```

Permission syntax: `Skill(name)` for exact match, `Skill(name *)` for prefix match with any arguments.

The table shows what a `deny` rule blocks beyond the name you write, by the kind of name in the rule.

| Your `deny` rule names | Example rule | Claude Code also blocks |
| :- | :- | :- |
| An alias | `Skill(review)` | The bundled `/code-review`, through its `/review` alias |
| An unqualified name | `Skill(deploy)` | A [nested skill](#where-skills-live) listed as `apps/web:deploy` |
| A [skill synced from claude.ai](#how-synced-skills-behave) | `Skill(anthropic-skills:deploy)` | That skill when Claude Desktop delivers it to a session as a plugin |
| The plugin form of a synced skill | `Skill(deploy:deploy)` | The synced skill |
| A skill in the [parameter form](/docs/en/permissions#match-by-input-parameter) | `Skill(skill:deploy)` | The skill whichever of its names Claude calls it by, including its alias and display name |

Before v2.1.260, Claude Code didn't block a nested skill listed under its qualified name when the deny rule named only the unqualified name.

Claude Code matches an `allow` rule only against the skill's own name and the name in Claude's invocation. To approve a [synced skill](#how-synced-skills-behave) without a prompt, name it inside its [reserved namespace](#names-reserved-for-synced-skills):

* `Skill(anthropic-skills:pdf)` approves the synced `pdf` skill
* `Skill(anthropic-skills *)` approves every synced skill
* `Skill(anthropic *)` doesn't cover `anthropic-skills:pdf`, because a prefix outside the namespace doesn't match the names inside it

**Hide individual skills** by adding `disable-model-invocation: true` to their frontmatter. This removes the skill from Claude's context entirely.

<Note>
  With `user-invocable: false`, you can't invoke the skill, but Claude still can. To keep Claude from invoking it through the Skill tool, set `disable-model-invocation: true`.
</Note>

### Override skill visibility from settings

The `skillOverrides` setting controls skill visibility from your [settings](/docs/en/settings) instead of the skill's own frontmatter. Use it for skills whose SKILL.md you don't want to edit, such as ones checked into a shared project repo. The `/skills` menu writes it for you: highlight a skill and press `Space` to cycle states, then `Esc` to save to `.claude/settings.local.json`.

Each key is a skill name and each value is one of four states:

| Value | Listed to Claude | In `/` menu |
| :- | :- | :- |
| `"on"` | Name and description | Yes |
| `"name-only"` | Name only | Yes |
| `"user-invocable-only"` | Hidden | Yes |
| `"off"` | Hidden | Hidden |

The `/skills` menu labels the `"user-invocable-only"` state `user-only`.

`"off"` also hides the skill from the command lists advertised to [Remote Control](/docs/en/remote-control) clients and to [Agent SDK](/docs/en/agent-sdk/skills#discover-available-commands) callers, in addition to the terminal `/` menu. Invoking a hidden skill by its full name returns the `skillOverrides` error instead of running it.

A skill that is absent from `skillOverrides` is treated as `"on"`. The example below collapses one skill to its name and turns another off entirely:

```json theme={null}
{
  "skillOverrides": {
    "legacy-context": "name-only",
    "deploy": "off"
  }
}
```

Some bundled skills have aliases, such as `checkup` for `/doctor`. If you set a `skillOverrides` entry under an alias in [managed settings](/docs/en/managed-settings) or in a file you pass with the `--settings` flag, Claude Code applies it to the skill behind the alias. You can only restrict a skill further through an alias, never make it more visible, and if you also set an entry under the skill's own name in managed settings, that entry takes precedence. Before v2.1.260, Claude Code didn't apply an entry under an alias to the skill in any settings source.

In user, project, and local settings, Claude Code matches entries against skill names only. If you set an entry for `review` there, it applies to a skill named `review`, not to the bundled `/code-review` through its `/review` alias.

Plugin skills are not affected by `skillOverrides`. Manage those through `/plugin` instead.

### Find unused skills

Every skill in the [skill listing](#skill-descriptions-are-cut-short) adds to your context on every turn, whether or not Claude ever uses it. Run `/skill-doctor` to see what each of your skills costs and how often it gets used, so you can decide which ones to turn off. In an interactive session, the report opens in the `/plugin` manager's **Stats** tab. In [non-interactive mode](/docs/en/headless) with `-p`, Claude Code prints it as text.

The report covers the skills in your session other than bundled skills and enterprise skills. It flags skills in the listing that have never been invoked and says where to turn them off. Of the skills it tells you where to turn off, start with the ones that have the highest context cost. The report also lists plugins you haven't used recently.

`/skill-doctor` requires Claude Code v2.1.252 or later and isn't available in sessions that skip [feature-flag fetching](/docs/en/env-vars#features-that-need-feature-flag-fetching). If you run `/skill-doctor` over [Remote Control](/docs/en/remote-control) from your phone or browser, Claude Code replies [`Skill usage reports are not available on this connection.`](/docs/en/errors#skill-usage-reports-are-not-available-on-this-connection) instead. Run `/skill-doctor` in the terminal on the machine where the session is running.

## Evaluate and iterate on a skill

Seeing a skill trigger tells you Claude found it, not that it did what you intended. To know a skill is working, measure separately whether Claude invokes it on the prompts it should, and whether the output matches what you expect when it does.

The check for both is a baseline comparison. Collect a few realistic prompts, run each one in a fresh session with the skill available and again with it turned off, and compare the results. A fresh session matters because leftover context from authoring the skill will mask gaps in the written instructions.

How you turn the skill off for the second run depends on where it comes from:

* **Personal or project skill**: set it to `"off"` in [`skillOverrides`](#override-skill-visibility-from-settings).
* **Skill that a plugin provides**: `skillOverrides` doesn't apply to plugin skills. Use [`claude plugin eval`](/docs/en/plugin-evals#the-no-plugin-baseline) instead, which repeats each run with no plugin loaded.

Two tools automate the baseline comparison. For a skill that ships in a [plugin](/docs/en/plugins/overview), [`claude plugin eval`](/docs/en/plugin-evals) runs each prompt in an isolated session with and without the plugin, scores it with graders you define or that it writes for you, and exits non-zero below a threshold so you can gate CI on it. For iterating on a single skill inside a Claude Code conversation, the skill-creator plugin below runs a similar loop with its own `evals/evals.json` format. The two formats aren't interchangeable.

### Run evals with skill-creator

The [`skill-creator` plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator) automates the comparison loop inside Claude Code. In the VS Code extension or the desktop app, install it from the official marketplace by following [Install a plugin](/docs/en/plugins/install#install-a-plugin). In a terminal, start Claude Code by running `claude`, then enter this at its prompt:

```text theme={null}
/plugin install skill-creator@claude-plugins-official
```

If the install fails, match the message Claude Code reports:

* `Marketplace "claude-plugins-official" not found`: add the marketplace with `/plugin marketplace add anthropics/claude-plugins-official`, then retry the install.
* The plugin is [not found in the marketplace](/docs/en/plugins/install#install-a-plugin): check the plugin name.

If the install summary reports `Run /reload-plugins to apply.`, Claude Code then runs that reload for you. If the reload warns that your next message would re-read the conversation, run `/reload-plugins --force` to make the plugin's skills available in the current session. Then ask Claude to evaluate an existing skill, for example `evaluate my summarize-changes skill with skill-creator`. The plugin walks you through writing test cases and runs the loop:

* **Test cases**: stores prompts, input files, and expected behavior in `evals/evals.json` inside the skill directory
* **Isolated runs**: spawns a [subagent](/docs/en/sub-agents) per test case so each run starts with a clean context, and records token count and duration
* **Grading**: checks each assertion against the output and writes pass or fail with evidence to `grading.json`
* **Benchmark**: aggregates pass rate, time, and tokens for with-skill versus without-skill into `benchmark.json` so you can compare the pass-rate improvement against the token and time overhead
* **Version comparison**: runs a blind A/B between two versions of the skill so you can confirm an edit is an improvement before committing it
* **Description tuning**: generates should-trigger and should-not-trigger prompts, measures the hit rate, and proposes description edits when the skill activates on the wrong requests
* **Review viewer**: opens an HTML report where you inspect each output and record qualitative feedback that the next iteration reads

For the eval file format and the full iteration workflow, see [Evaluating skill output quality](https://agentskills.io/skill-creation/evaluating-skills) on agentskills.io. For background on the benchmark and comparison modes, see the [skill-creator announcement](https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills).

## Share skills

Skills can be distributed at different scopes depending on your audience:

* **Project skills**: Commit `.claude/skills/` to version control
* **Plugins**: Create a `skills/` directory in your [plugin](/docs/en/plugins/overview)
* **Managed**: Deploy organization-wide through [managed settings](/docs/en/managed-settings)

### Generate visual output

Skills can bundle and run scripts in any language, giving Claude capabilities beyond what's possible in a single prompt. One pattern is generating visual output: interactive HTML files that open in your browser for exploring data, debugging, or creating reports.

This example creates a codebase explorer: an interactive tree view where you can expand and collapse directories, see file sizes at a glance, and identify file types by color.

Create the Skill directory:

```bash theme={null}
mkdir -p ~/.claude/skills/codebase-visualizer/scripts
```

Save this to `~/.claude/skills/codebase-visualizer/SKILL.md`. The description tells Claude when to activate this Skill, and the instructions tell Claude to run the bundled script. The script path uses [`${CLAUDE_SKILL_DIR}`](#available-string-substitutions) so it resolves correctly whether the skill is installed at the personal, project, or plugin level:

````yaml theme={null}
---
name: codebase-visualizer
description: Generate an interactive collapsible tree visualization of your codebase. Use when exploring a new repo, understanding project structure, or identifying large files.
allowed-tools: Bash(python3 *)
---

# Codebase Visualizer

Generate an interactive HTML tree view that shows your project's file structure with collapsible directories.

## Usage

Run the visualization script from your project root:

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/visualize.py .
```

This creates `codebase-map.html` in the current directory and opens it in your default browser.

## What the visualization shows

- **Collapsible directories**: Click folders to expand/collapse
- **File sizes**: Displayed next to each file
- **Colors**: Different colors for different file types
- **Directory totals**: Shows aggregate size of each folder
````

Save this to `~/.claude/skills/codebase-visualizer/scripts/visualize.py`. This script scans a directory tree and generates a self-contained HTML file with:

* A **summary sidebar** showing file count, directory count, total size, and number of file types
* A **bar chart** breaking down the codebase by file type (top 8 by size)
* A **collapsible tree** where you can expand and collapse directories, with color-coded file type indicators

The script requires Python 3 but uses only built-in libraries, so there are no packages to install:

```python expandable theme={null}
#!/usr/bin/env python3
"""Generate an interactive collapsible tree visualization of a codebase."""

import json
import sys
import webbrowser
from html import escape
from pathlib import Path
from collections import Counter

IGNORE = {'.git', 'node_modules', '__pycache__', '.venv', 'venv', 'dist', 'build'}

def scan(path: Path, stats: dict) -> dict:
    result = {"name": path.name, "children": [], "size": 0}
    try:
        for item in sorted(path.iterdir()):
            if item.name in IGNORE or item.name.startswith('.'):
                continue
            if item.is_file():
                size = item.stat().st_size
                ext = item.suffix.lower() or '(no ext)'
                result["children"].append({"name": item.name, "size": size, "ext": ext})
                result["size"] += size
                stats["files"] += 1
                stats["extensions"][ext] += 1
                stats["ext_sizes"][ext] += size
            elif item.is_dir():
                stats["dirs"] += 1
                child = scan(item, stats)
                if child["children"]:
                    result["children"].append(child)
                    result["size"] += child["size"]
    except PermissionError:
        pass
    return result

def generate_html(data: dict, stats: dict, output: Path) -> None:
    ext_sizes = stats["ext_sizes"]
    total_size = sum(ext_sizes.values()) or 1
    sorted_exts = sorted(ext_sizes.items(), key=lambda x: -x[1])[:8]
    colors = {
        '.js': '#f7df1e', '.ts': '#3178c6', '.py': '#3776ab', '.go': '#00add8',
        '.rs': '#dea584', '.rb': '#cc342d', '.css': '#264de4', '.html': '#e34c26',
        '.json': '#6b7280', '.md': '#083fa1', '.yaml': '#cb171e', '.yml': '#cb171e',
        '.mdx': '#083fa1', '.tsx': '#3178c6', '.jsx': '#61dafb', '.sh': '#4eaa25',
    }
    lang_bars = "".join(
        f'<div class="bar-row"><span class="bar-label">{ext}</span>'
        f'<div class="bar" style="width:{(size/total_size)*100}%;background:{colors.get(ext,"#6b7280")}"></div>'
        f'<span class="bar-pct">{(size/total_size)*100:.1f}%</span></div>'
        for ext, size in sorted_exts
    )
    def fmt(b):
        if b < 1024: return f"{b} B"
        if b < 1048576: return f"{b/1024:.1f} KB"
        return f"{b/1048576:.1f} MB"

    html = f'''<!DOCTYPE html>
<html><head>
  <meta charset="utf-8"><title>Codebase Explorer</title>
  <style>
    body {{ font: 14px/1.5 system-ui, sans-serif; margin: 0; background: #1a1a2e; color: #eee; }}
    .container {{ display: flex; height: 100vh; }}
    .sidebar {{ width: 280px; background: #252542; padding: 20px; border-right: 1px solid #3d3d5c; overflow-y: auto; flex-shrink: 0; }}
    .main {{ flex: 1; padding: 20px; overflow-y: auto; }}
    h1 {{ margin: 0 0 10px 0; font-size: 18px; }}
    h2 {{ margin: 20px 0 10px 0; font-size: 14px; color: #888; text-transform: uppercase; }}
    .stat {{ display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #3d3d5c; }}
    .stat-value {{ font-weight: bold; }}
    .bar-row {{ display: flex; align-items: center; margin: 6px 0; }}
    .bar-label {{ width: 55px; font-size: 12px; color: #aaa; }}
    .bar {{ height: 18px; border-radius: 3px; }}
    .bar-pct {{ margin-left: 8px; font-size: 12px; color: #666; }}
    .tree {{ list-style: none; padding-left: 20px; }}
    details {{ cursor: pointer; }}
    summary {{ padding: 4px 8px; border-radius: 4px; }}
    summary:hover {{ background: #2d2d44; }}
    .folder {{ color: #ffd700; }}
    .file {{ display: flex; align-items: center; padding: 4px 8px; border-radius: 4px; }}
    .file:hover {{ background: #2d2d44; }}
    .size {{ color: #888; margin-left: auto; font-size: 12px; }}
    .dot {{ width: 8px; height: 8px; border-radius: 50%; margin-right: 8px; }}
  </style>
</head><body>
  <div class="container">
    <div class="sidebar">
      <h1>📊 Summary</h1>
      <div class="stat"><span>Files</span><span class="stat-value">{stats["files"]:,}</span></div>
      <div class="stat"><span>Directories</span><span class="stat-value">{stats["dirs"]:,}</span></div>
      <div class="stat"><span>Total size</span><span class="stat-value">{fmt(data["size"])}</span></div>
      <div class="stat"><span>File types</span><span class="stat-value">{len(stats["extensions"])}</span></div>
      <h2>By file type</h2>
      {lang_bars}
    </div>
    <div class="main">
      <h1>📁 {escape(data["name"])}</h1>
      <ul class="tree" id="root"></ul>
    </div>
  </div>
  <script>
    const data = {json.dumps(data)};
    const colors = {json.dumps(colors)};
    function fmt(b) {{ if (b < 1024) return b + ' B'; if (b < 1048576) return (b/1024).toFixed(1) + ' KB'; return (b/1048576).toFixed(1) + ' MB'; }}
    function esc(s) {{ return s.replace(/[&<>"']/g, c => ({{"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}}[c])); }}
    function render(node, parent) {{
      if (node.children) {{
        const det = document.createElement('details');
        det.open = parent === document.getElementById('root');
        det.innerHTML = `<summary><span class="folder">📁 ${{esc(node.name)}}</span><span class="size">${{fmt(node.size)}}</span></summary>`;
        const ul = document.createElement('ul'); ul.className = 'tree';
        node.children.sort((a,b) => (b.children?1:0)-(a.children?1:0) || a.name.localeCompare(b.name));
        node.children.forEach(c => render(c, ul));
        det.appendChild(ul);
        const li = document.createElement('li'); li.appendChild(det); parent.appendChild(li);
      }} else {{
        const li = document.createElement('li'); li.className = 'file';
        li.innerHTML = `<span class="dot" style="background:${{colors[node.ext]||'#6b7280'}}"></span>${{esc(node.name)}}<span class="size">${{fmt(node.size)}}</span>`;
        parent.appendChild(li);
      }}
    }}
    data.children.forEach(c => render(c, document.getElementById('root')));
  </script>
</body></html>'''
    output.write_text(html)

if __name__ == '__main__':
    target = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
    stats = {"files": 0, "dirs": 0, "extensions": Counter(), "ext_sizes": Counter()}
    data = scan(target, stats)
    out = Path('codebase-map.html')
    generate_html(data, stats, out)
    print(f'Generated {out.absolute()}')
    webbrowser.open(f'file://{out.absolute()}')
```

To test, open Claude Code in any project and ask "Visualize this codebase." Claude runs the script, which prints the generated file's path, such as `Generated /path/to/codebase-map.html`, and opens it in your browser. If you work in a headless environment where no browser opens, the printed path confirms the script succeeded.

This pattern works for any visual output: dependency graphs, test coverage reports, API documentation, or database schema visualizations. The bundled script does the work while Claude handles orchestration.

## Troubleshooting

### Skill not triggering

If Claude doesn't use your skill when expected:

1. Check the description includes keywords users would naturally say
2. Verify the skill appears in `What skills are available?`
3. Try rephrasing your request to match the description more closely
4. Invoke it directly with `/skill-name` if the skill is user-invocable

If the frontmatter YAML is malformed, Claude Code loads the skill body with empty metadata, so `/skill-name` still works but Claude can't match against your `description`. Run with `--debug` to see the parse error.

If the skill ships in a plugin, you can measure how often it triggers across realistic prompts rather than checking one at a time: write an eval case with a [`tool_used: Skill` grader](/docs/en/plugin-evals#create-your-first-eval-suite) and run it with `claude plugin eval` after each description change.

To find `SKILL.md` files whose frontmatter doesn't parse, run [`claude plugin validate`](/docs/en/plugins/cli-reference#validate-a-directory) on the skills directory, for example `claude plugin validate .claude/skills` for project skills or `claude plugin validate ~/.claude/skills` for personal skills. Requires Claude Code v2.1.233 or later.
