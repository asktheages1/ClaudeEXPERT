#!/bin/bash
# SessionStart hook (startup|resume|compact): print state into Claude's context.
# Plain stdout of a SessionStart hook goes to context; output is capped below the 10,000-char
# hook output limit. Always exits 0: SessionStart cannot block
# [SOURCE: https://code.claude.com/docs/en/hooks.md, 2026-10-06].
set -u

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$HOOK_DIR/../.." && pwd -P)"
cd "$ROOT" || exit 0
# timeout(1) is missing on stock macOS: run without a limit there.
t() { if command -v timeout >/dev/null 2>&1; then timeout "$@"; else shift; "$@"; fi; }

{
  echo "SESSION-START (.claude/hooks/session-start.sh)"
  echo "date -u: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "claude --version: $(t 10 claude --version 2>/dev/null || echo unknown)"
  if GIT_TERMINAL_PROMPT=0 t 20 git fetch -q origin main 2>/dev/null; then fetch=ok; else fetch="FAILED (origin/main may be stale)"; fi
  echo "git fetch origin main: $fetch"
  head=$(git rev-parse --short HEAD 2>/dev/null)
  om=$(git rev-parse --short origin/main 2>/dev/null || echo none)
  lr=$(git rev-list --left-right --count origin/main...HEAD 2>/dev/null || echo "? ?")
  echo "branch $(git branch --show-current 2>/dev/null) HEAD $head vs origin/main $om: behind ${lr%%[[:space:]]*}, ahead ${lr##*[[:space:]]}"
  echo "--- scripts/check.sh all ---"
  if [ -x scripts/check.sh ]; then scripts/check.sh all 2>&1 | head -60; else echo "FAIL scripts/check.sh missing or not executable"; fi
  echo "--- end SESSION-START ---"
} | head -c 9500

exit 0
