# S12b — Lock the gate files with `ask`, deny the server write tools, generate the template export

Read `docs/prompts/00-COMMON.md` in full, then this file in full, before any other action.

## Goal
Gate files change only with the owner's yes in the session (`ask` rules, as the skeleton promises); GitHub MCP write tools are denied so "write through git only" is true; the Stop protocol check moves to block mode; `Gotowe/` is generated from the root. **All of this is one final settings edit, made after everything else, with the building session running `KBGATE_MODE=log` in its environment**: a session must never lock itself before it has finished editing.

## Read in full
- `CLAUDE.md`, `STATUS.md`
- `knowledge/permissions-settings-automode.md`, `knowledge/hooks.md`
- `.claude/settings.json`, every file in `.claude/hooks/`
## Read in part (say so)
- `docs/FINDINGS.md`: S07 probe 6 (ConfigChange semantics) and probe 8 (`ask` vs `git mv`).

## Work (in this order)
1. **`tools/export_template.py`**: copies `CLAUDE.md`, `.claude/` (excluding `kbgate/`, `worktrees/`, `settings.local.json`), `tools/kb_*`, `tools/verify_reads.py`, `tools/test_hooks.sh`, `tests/`, and `knowledge/` (or only `design-rules.md` + `knowledge/CLAUDE.md` with `--kb minimal`, per the owner's decision in `STATUS.md`; if undecided, full and say so) into `Gotowe/`; `--check` exits 1 on a diff. `Gotowe/` is never edited by hand and never read in a session: add `claudeMdExcludes: ["Gotowe/**/CLAUDE.md"]` to settings (so the export's CLAUDE.md files are not loaded as nested memory) and keep `Gotowe/` excluded in the read logger. CI: add `export_template.py --root pr --check` to `kb-check`.
2. **Stop protocol check** → block mode: exit 2 with the missing items when `STATUS.md` says a session prompt was run and the reviews, the STATUS change or the push are missing; `stop_hook_active` handled; the 8-block cap applies.
3. **ConfigChange** hook on `project_settings|local_settings`: **log mode only** (record and warn via `systemMessage`); the `ask` rule carries the consent. A blocking ConfigChange would also block the owner-approved edit, which contradicts the goal; S07 probe 6 decides what "block" would even mean.
4. **Final settings edit** (one write): `permissions.ask`: `Edit(/CLAUDE.md)`, `Edit(/.claude/settings.json)`, `Edit(/.claude/settings.local.json)`, `Edit(/.claude/agent-rules.md)`, `Edit(/.claude/agents/**)`, `Edit(/.claude/hooks/**)`, `Edit(/.claude/rules/**)`, `Edit(/.claude/skills/**)`, `Edit(/tools/kb_*)`, `Edit(/tools/verify_reads.py)`, `Edit(/tools/test_hooks.sh)`, `Edit(/.github/workflows/**)`, `Edit(/knowledge/topics.json)` (the skeleton's full promise); never `Edit(/.claude/**)` (agent worktrees; path matching `[ASSUMPTION]`). `permissions.deny`: `mcp__github__push_files`, `mcp__github__create_or_update_file`, `mcp__github__delete_file`, `mcp__github__merge_pull_request`, `mcp__github__enable_pr_auto_merge`, `mcp__github__update_pull_request_branch`, `mcp__github__create_branch`, `mcp__github__actions_run_trigger`. Plus the ConfigChange hook entry and the Stop mode change. Classifier refusal → COMMON §3.
5. Verify the `ask` rule on a dummy path in the session's permission mode (the skeleton's `<verify …>` note): record which of the two mechanisms asked (the rule, or the classifier on a protected path) in `docs/FINDINGS.md`. Verify from the scratchpad worktree with `--settings` that `jq '.permissions.ask | length'` equals the list above and that a `git mv` of a hook file is denied/asked per S07 probe 8.
6. `docs/TESTS.md`, `MAPA.md`; `STATUS.md` Live mechanisms: "ask rules on gate files", "GitHub MCP write tools denied", "Stop protocol check: block", "Gotowe/ generated". `Warsztat/proposed/CLAUDE.md.S12b.diff`: the skeleton's "Enforcement" line listing the hard mechanisms now names the real ones (push gate, read gates, Stop protocol, ask rules, MCP deny, CI from `main`). Copy the gate logs.

## Done when
```
python3 tools/export_template.py && python3 tools/export_template.py --check ; echo exit=$?
jq -e '.permissions.ask | length == 13' .claude/settings.json ; echo exit=$?
jq -e '.permissions.deny | length >= 8' .claude/settings.json ; echo exit=$?
bash tools/test_hooks.sh ; echo exit=$?
python3 tools/kb_check.py --tree HEAD ; echo exit=$?
```

## End of session
Reviewers per COMMON §4 (KB files for them: `knowledge/permissions-settings-automode.md`; they read the final `.claude/settings.json` against the skeleton's promises line by line). Fix or reject (a fix to a locked file now asks the owner: if the owner is not present, write the fix to `Warsztat/proposed/` and say so). `STATUS.md`, `CHANGELOG.md`, `docs/FINDINGS.md`, commit, push, tag. Next prompt: `docs/prompts/S13-claude-md.md`.
