#!/bin/bash
# Stop hook. Local failures (budgets, format, uncommitted, stash, ignored files) block on every stop:
# they are always fixable, and Claude Code's own cap (8 continuations without a tool call) is the exit.
# Push failures may be the network: they block 3 times in a row, then let the turn end.
# No jq needed to block: exit 2 + stderr (O2 A6).
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 2
out=$(scripts/check.sh all 2>&1) && { rm -f "${TMPDIR:-/tmp}/kb-stop-push-count-$(basename "$PWD")"; exit 0; }
if printf '%s\n' "$out" | grep -v -e '^OK' -e 'not pushed' -e 'on no remote branch' -e '^[0-9a-f]\{7,\} ' | grep -q .; then
  printf 'Stop hook: scripts/check.sh failed. Fix it, commit and push; drafts go to the scratchpad.\n%s\n' "$out" >&2
  exit 2
fi
c="${TMPDIR:-/tmp}/kb-stop-push-count-$(basename "$PWD")"; n=$(( $(cat "$c" 2>/dev/null || echo 0) + 1 )); echo "$n" >"$c"
if [ "$n" -le 3 ]; then printf 'Stop hook (push %s/3): commits not pushed. Push, or tell the owner why it fails.\n%s\n' "$n" "$out" >&2; exit 2; fi
rm -f "$c"; echo "{\"systemMessage\":\"Stop hook: turn ended with UNPUSHED commits (push failed 3 times).\"}"; exit 0
