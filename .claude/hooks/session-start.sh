#!/bin/bash
# SessionStart hook (startup, resume, compact): puts the session facts from knowledge/O0 §9 into the
# context deterministically, so no session has to remember to collect them. Plain stdout → context.
input=$(cat)
src=$(jq -r '.source // "?"' <<<"$input" 2>/dev/null)
model=$(jq -r '.model // "not in hook input"' <<<"$input" 2>/dev/null)
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
ver=$(timeout 20 claude --version 2>/dev/null | head -1)
echo "## Session state (SessionStart hook, source=$src, $(date -u +%FT%TZ))"
echo "- Claude Code ${ver:-unknown} · model: $model · CLAUDE_EFFORT=${CLAUDE_EFFORT:-unset} · CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-unset} · CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=${CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH:-unset} · CPU=$(nproc 2>/dev/null) · CLAUDE_CODE_REMOTE=${CLAUDE_CODE_REMOTE:-unset}"
if timeout 25 git fetch -q origin main 2>/dev/null; then fetched="fetched"; else fetched="FETCH FAILED, origin/main may be stale"; fi
br=$(git branch --show-current 2>/dev/null)
ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "?")
behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
echo "- git: branch $br, HEAD $(git rev-parse --short HEAD 2>/dev/null), vs origin/main: $ahead ahead / $behind behind ($fetched)"
echo "- KB header: $(grep -m1 -oE 'Snapshot: [^|]+' CLAUDE.md 2>/dev/null || echo 'not found in CLAUDE.md')"
echo "- scripts/check.sh files → $(scripts/check.sh files 2>&1 | tr '\n' ' ')"
echo
echo "## open-items.md (decisions waiting for the owner, unverified facts)"
cat open-items.md 2>/dev/null || echo "(missing)"
exit 0
