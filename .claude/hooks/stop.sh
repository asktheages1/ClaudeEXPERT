#!/bin/bash
# Stop hook: the turn may not end while scripts/check.sh fails (oversized files, malformed entries,
# uncommitted or unpushed work). Blocks up to 3 times in a row for the same failure, then gives up
# with a visible message, so an unfixable failure (e.g. network down) cannot trap the session.
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
sid=$(jq -r '.session_id // "nosession"' <<<"$input" 2>/dev/null)
counter="${TMPDIR:-/tmp}/claude-stop-hook-count-$sid"   # outside the repo: an untracked file here would fail check_git itself
out=$(scripts/check.sh all 2>&1); rc=$?
if [ $rc -eq 0 ]; then rm -f "$counter"; exit 0; fi
n=$(cat "$counter" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" >"$counter"
if [ "$n" -gt 3 ]; then
  rm -f "$counter"
  jq -n --arg m "Stop hook gave up after 3 blocks; the repository is still failing checks:"$'\n'"$out" '{systemMessage:$m}'
  exit 0
fi
jq -n --arg r "Stop hook (block $n/3): scripts/check.sh failed. Fix the cause, commit and push before ending the turn; drafts belong in the scratchpad, not the repo. If it cannot be fixed, say so to the owner."$'\n'"$out" '{decision:"block", reason:$r}'
exit 0
