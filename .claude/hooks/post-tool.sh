#!/bin/bash
# PostToolUse hook (Bash, Edit, Write): immediate, non-blocking feedback when a file leaves its budget.
# Exit 2 on PostToolUse does not undo anything; it only delivers stderr to Claude right away.
cat >/dev/null
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
out=$(scripts/check.sh files 2>&1) && exit 0
echo "post-tool hook: file budget violated, fix before ending the turn (the Stop hook will block):"$'\n'"$out" >&2
exit 2
