#!/bin/bash
# Stop hook: block the end of a turn while scripts/check.sh all is red.
# - Blocks with {"decision":"block","reason":...} listing the FAIL lines.
# - Counts blocks per session in a state dir outside the repo; after MAX_BLOCKS
#   blocks in one continuation chain it gives up (lets the turn end) with a
#   systemMessage, well under Claude Code's own cap of 8 consecutive blocks
#   [SOURCE: https://code.claude.com/docs/en/hooks.md, 2026-10-06].
# - The counter restarts when check.sh is green or when stop_hook_active is false
#   (a new turn end, not a continuation forced by a Stop hook).
# - No network calls. No jq dependency (must not fail silently on a machine without jq).
set -u

MAX_BLOCKS=3
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CHECK="$HOOK_DIR/../../scripts/check.sh"
STATE_DIR="${HOME:-/tmp}/.cache/claudeexpert-stop-hook"

input=$(cat)
sid=$(printf '%s' "$input" | tr -d '\n' | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
sid=$(printf '%s' "${sid:-unknown}" | tr -c 'A-Za-z0-9_-' '_')
if printf '%s' "$input" | tr -d '\n' | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  active=true
else
  active=false
fi

json_str() { # JSON-escape stdin into a quoted string; control chars other than tab/newline are dropped
  printf '"%s"' "$(tr -d '\000-\010\013-\037\177' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r//g' | awk 'BEGIN{ORS="\\n"} {print}')"
}

log() { printf '%s sid=%s active=%s %s\n' "$(date -u +%FT%TZ)" "$sid" "$active" "$*" >> "$STATE_DIR/log" 2>/dev/null || true; }

mkdir -p "$STATE_DIR" 2>/dev/null
counter="$STATE_DIR/$sid.count"
persist=1
[ -d "$STATE_DIR" ] && [ -w "$STATE_DIR" ] || persist=0

count=0
if [ "$active" = true ] && [ -f "$counter" ]; then
  count=$(cat "$counter" 2>/dev/null); [[ "$count" =~ ^[0-9]+$ ]] || count=0
fi

if [ -x "$CHECK" ]; then
  # Bounded below the hook timeout (120 s): a hung check.sh must block, not time out silently.
  if command -v timeout >/dev/null 2>&1; then out=$(timeout 60 "$CHECK" all 2>&1); rc=$?
  else out=$("$CHECK" all 2>&1); rc=$?; fi   # macOS has no timeout(1) by default
  [ "$rc" -eq 124 ] && out="FAIL setup: scripts/check.sh timed out after 60 s"
else
  out="FAIL setup: $CHECK missing or not executable"; rc=127
fi

if [ "$rc" -eq 0 ]; then
  rm -f "$counter" 2>/dev/null
  log "green allow"
  exit 0
fi

fails=$(printf '%s\n' "$out" | grep '^FAIL' | head -40)
[ -n "$fails" ] || fails="check.sh exited $rc without FAIL lines: $(printf '%s' "$out" | head -c 2000)"

# Without a writable counter a loop could not be bounded: block only the first stop of a chain.
if [ "$persist" -eq 0 ] && [ "$active" = true ]; then count=$MAX_BLOCKS; fi

if [ "$count" -ge "$MAX_BLOCKS" ]; then
  rm -f "$counter" 2>/dev/null
  log "give-up after $count blocks"
  msg=$(printf 'Stop hook gave up after %s blocks: scripts/check.sh is still RED. The turn ends with these failures unresolved:\n%s' "$count" "$fails" | json_str)
  printf '{"systemMessage":%s}\n' "$msg"
  exit 0
fi

count=$((count + 1))
[ "$persist" -eq 1 ] && printf '%s\n' "$count" > "$counter"
log "block $count/$MAX_BLOCKS"
reason=$(printf 'scripts/check.sh all is RED (stop blocked %s/%s). Fix these, commit and push, then finish:\n%s' "$count" "$MAX_BLOCKS" "$fails" | json_str)
printf '{"decision":"block","reason":%s}\n' "$reason"
exit 0
