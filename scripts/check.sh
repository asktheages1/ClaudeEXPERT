#!/bin/bash
# Deterministic repo checks. Usage: scripts/check.sh [files|git|all]  (default: all)
# Exit 0 = green. Exit 1 = at least one "FAIL ..." line on stdout. Exit 3 = usage error.
# No network calls: git checks use local refs only.
set -u

mode="${1:-all}"
case "$mode" in files|git|all) ;; *) echo "usage: $0 [files|git|all]" >&2; exit 3 ;; esac

# Repo root = parent of this script's directory, so the result does not depend on cwd.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)" || { echo "FAIL setup: cannot resolve repo root"; exit 1; }
cd "$ROOT" || { echo "FAIL setup: cannot cd to $ROOT"; exit 1; }

KB_MAX_BYTES=40000
CLAUDE_MAX_LINES=200
CLAUDE_MAX_BYTES=16000
TAG_RE='\[(MEASURED|SOURCE|CODE|CL|3P|ASSUMPTION|OF|IS|BLOG)\b|\[S:'
HEADER_RE='^## [0-9]{4}-[0-9]{2}-[0-9]{2} — [^[:space:]].*$'

fails=0
fail() { echo "FAIL $*"; fails=$((fails + 1)); }

bytes() { wc -c < "$1" | tr -d ' '; }

check_log() { # $1 = findings.md or exceptions.md
  local f="$1" in_fence=0 n=0 hdr="" hdr_line=0 tagged=0 line
  [ -f "$f" ] || { fail "files: $f missing"; return; }
  # Entry = "## " line up to the next "## " line or EOF. Lines inside ``` fences are ignored.
  close_entry() {
    if [ -n "$hdr" ] && [ "$tagged" -eq 0 ]; then
      fail "files: $f:$hdr_line entry has no evidence tag: $hdr"
    fi
  }
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    if [[ "$line" =~ ^\`\`\` ]]; then in_fence=$((1 - in_fence)); continue; fi
    [ "$in_fence" -eq 1 ] && continue
    if [[ "$line" =~ ^##[[:space:]] ]] || [[ "$line" =~ ^##$ ]]; then
      close_entry
      hdr="$line"; hdr_line=$n; tagged=0
      if ! printf '%s\n' "$line" | grep -Eq "$HEADER_RE"; then
        fail "files: $f:$n bad header (want '## YYYY-MM-DD — title'): $line"
      else
        local d="${line:3:10}"
        date -u -d "$d" +%F >/dev/null 2>&1 && [ "$(date -u -d "$d" +%F)" = "$d" ] \
          || fail "files: $f:$n invalid date in header: $line"
      fi
      continue
    fi
    if [ -n "$hdr" ] && printf '%s\n' "$line" | grep -Eq "$TAG_RE"; then tagged=1; fi
  done < "$f"
  close_entry
}

check_files() {
  # 1. Knowledge files: each <= 40,000 bytes (one Read call, CLAUDE.md "Updating the KB").
  local f found=0
  for f in knowledge/*.md; do
    [ -e "$f" ] || continue
    found=1
    local b; b=$(bytes "$f")
    [ "$b" -le "$KB_MAX_BYTES" ] || fail "files: $f is $b bytes > $KB_MAX_BYTES"
  done
  [ "$found" -eq 1 ] || fail "files: no knowledge/*.md found"

  # 2. CLAUDE.md: <= 200 lines and <= 16,000 bytes.
  if [ -f CLAUDE.md ]; then
    local l b
    l=$(awk 'END{print NR}' CLAUDE.md); b=$(bytes CLAUDE.md)
    [ "$l" -le "$CLAUDE_MAX_LINES" ] || fail "files: CLAUDE.md has $l lines > $CLAUDE_MAX_LINES"
    [ "$b" -le "$CLAUDE_MAX_BYTES" ] || fail "files: CLAUDE.md is $b bytes > $CLAUDE_MAX_BYTES"
  else
    fail "files: CLAUDE.md missing"
  fi

  # 3. Log entries: header format and at least one evidence tag per entry.
  check_log findings.md
  check_log exceptions.md

  # 4. Hooks and scripts executable, on disk and in the git index (a 100644 file
  #    loses +x on the next clone and the hook then fails silently).
  local idx
  for f in .claude/hooks/* scripts/*.sh; do
    [ -f "$f" ] || continue
    [ -x "$f" ] || fail "files: $f is not executable"
    idx=$(git ls-files -s -- "$f" 2>/dev/null | awk '{print $1}')
    if [ -n "$idx" ] && [ "$idx" != "100755" ]; then
      fail "files: $f has git mode $idx (want 100755)"
    fi
  done

  # 5. Hook wiring: settings.json parses, Stop and SessionStart are wired, every
  #    ${CLAUDE_PROJECT_DIR} command path exists and is executable.
  local s=.claude/settings.json
  if [ ! -f "$s" ]; then fail "files: $s missing"; return; fi
  if ! command -v jq >/dev/null 2>&1; then fail "files: jq not installed, cannot validate $s"; return; fi
  if ! jq -e . "$s" >/dev/null 2>&1; then fail "files: $s is not valid JSON"; return; fi
  jq -e '[.hooks.Stop[]?.hooks[]?.command] | any(test("/\\.claude/hooks/stop\\.sh"))' "$s" >/dev/null 2>&1 \
    || fail "files: $s does not wire .claude/hooks/stop.sh to Stop"
  jq -e '[.hooks.SessionStart[]?.hooks[]?.command] | any(test("/\\.claude/hooks/session-start\\.sh"))' "$s" >/dev/null 2>&1 \
    || fail "files: $s does not wire .claude/hooks/session-start.sh to SessionStart"
  local cmd path
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    path=$(printf '%s' "$cmd" | sed -n 's#^"*\${\{0,1\}CLAUDE_PROJECT_DIR}\{0,1\}"*/\([^" ]*\).*#\1#p')
    [ -n "$path" ] || continue
    [ -x "$path" ] || fail "files: $s hook command points to missing or non-executable $path"
  done < <(jq -r '.hooks // {} | to_entries[] | .value[]?.hooks[]?.command // empty' "$s")
}

check_git() {
  git rev-parse --git-dir >/dev/null 2>&1 || { fail "git: not a git repository"; return; }
  local st; st=$(git status --porcelain --untracked-files=all 2>/dev/null)
  if [ -n "$st" ]; then
    local mod unt
    mod=$(printf '%s\n' "$st" | grep -vc '^??')
    unt=$(printf '%s\n' "$st" | grep -c '^??')
    [ "$mod" -eq 0 ] || fail "git: $mod uncommitted change(s): $(printf '%s\n' "$st" | grep -v '^??' | head -5 | cut -c4- | tr '\n' ' ')"
    [ "$unt" -eq 0 ] || fail "git: $unt untracked file(s): $(printf '%s\n' "$st" | grep '^??' | head -5 | cut -c4- | tr '\n' ' ')"
  fi
  local br; br=$(git branch --show-current)
  if [ -z "$br" ]; then fail "git: detached HEAD (no branch to push)"; return; fi
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    local ahead; ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo "?")
    [ "$ahead" = "0" ] || fail "git: $ahead unpushed commit(s) on $br vs $(git rev-parse --abbrev-ref '@{u}')"
  else
    # No upstream. Fail only when HEAD has commits that are on no remote-tracking ref:
    # a fresh session branch identical to origin/main has nothing to lose.
    local local_only; local_only=$(git rev-list --count HEAD --not --remotes 2>/dev/null || echo "?")
    [ "$local_only" = "0" ] || fail "git: branch $br has no upstream and $local_only commit(s) on no remote ref (git push -u origin $br)"
  fi
}

case "$mode" in
  files) check_files ;;
  git) check_git ;;
  all) check_files; check_git ;;
esac

if [ "$fails" -gt 0 ]; then
  echo "check.sh $mode: RED ($fails failure(s))"
  exit 1
fi
echo "check.sh $mode: GREEN"
exit 0
