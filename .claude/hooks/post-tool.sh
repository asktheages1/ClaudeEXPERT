#!/bin/bash
# PostToolUse hook (Bash, Edit, Write): immediate, non-blocking feedback when a file leaves its budget.
# Exit 2 on PostToolUse undoes nothing; it only delivers stderr to Claude right away. Skipped inside
# subagents (they must not edit; the main session's Stop hook catches everything anyway).
in=$(cat)
jq -e '.agent_id' >/dev/null 2>&1 <<<"$in" && exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
out=$(scripts/check.sh files 2>&1) && exit 0
echo "post-tool hook: file budget or entry format violated, fix before ending the turn (the Stop hook will block):"$'\n'"$out" >&2
exit 2
