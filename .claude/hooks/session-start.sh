#!/bin/bash
# SessionStart hook (startup, resume, compact): puts the session facts from knowledge/O0 §9 into the
# context deterministically. Plain stdout → context (cap 10,000 chars: open-items first, check output last).
input=$(cat)
src=$(jq -r '.source // "?"' <<<"$input" 2>/dev/null)
model=$(jq -r '.model // "not in hook input: use get_session or /context"' <<<"$input" 2>/dev/null)
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
ver=$(timeout 20 claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "## Session state (SessionStart hook, source=$src, $(date -u +%FT%TZ))"
echo "- Claude Code ${ver:-unknown} · model: $model · context window: not visible to hooks, call get_session or /context before the first substantive answer"
echo "- CLAUDE_EFFORT=${CLAUDE_EFFORT:-unset} (inherited env at start, not authoritative: read effort.level from a later hook input or the transcript) · CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-unset} · CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=${CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH:-unset} · CPU=$(nproc 2>/dev/null) · CLAUDE_CODE_REMOTE=${CLAUDE_CODE_REMOTE:-unset}"
snap=$(grep -m1 -oE 'Claude Code [0-9.]+–[0-9.]+' CLAUDE.md | grep -oE '[0-9.]+$')
if [ -n "$ver" ] && [ -n "$snap" ] && [ "$(printf '%s\n%s\n' "$snap" "$ver" | sort -V | tail -1)" != "$snap" ]; then
  echo "- NEWER than the KB snapshot (≤ $snap): check the changelog delta (O1 §3) before version-sensitive answers and say you did"
fi
if timeout 25 git fetch -q origin main 2>/dev/null; then fetched="fetched"; else fetched="FETCH FAILED, origin/main may be stale"; fi
br=$(git branch --show-current 2>/dev/null)
ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "?")
behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
echo "- git: branch ${br:-DETACHED}, HEAD $(git rev-parse --short HEAD 2>/dev/null), vs origin/main: $ahead ahead / $behind behind ($fetched)"
echo
echo "## open-items.md (decisions waiting for the owner, open KB conflicts, unverified facts)"
cat open-items.md 2>/dev/null || echo "(missing)"
echo
echo "## scripts/check.sh files"
scripts/check.sh files 2>&1 | head -c 1500
exit 0
