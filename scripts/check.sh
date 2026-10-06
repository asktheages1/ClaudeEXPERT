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
TAG_RE='\[(MEASURED|SOURCE|CODE|CL|3P|ASSUMPTION|OF|IS|BLOG)(:|\])|\[S:'
HEADER_RE='^## [0-9]{4}-[0-9]{2}-[0-9]{2} — [^[:space:]].*$'
TOMORROW=$(date -u -d tomorrow +%F 2>/dev/null || date -u -v+1d +%F)   # GNU || BSD/macOS

valid_date() { # pure bash, no GNU date: YYYY-MM-DD is a real calendar date
  local y=$((10#${1:0:4})) m=$((10#${1:5:2})) d=$((10#${1:8:2})) max=31
  [ "$m" -ge 1 ] && [ "$m" -le 12 ] && [ "$d" -ge 1 ] || return 1
  case $m in 4|6|9|11) max=30 ;; 2) max=28; { [ $((y % 4)) -eq 0 ] && [ $((y % 100)) -ne 0 ]; } || [ $((y % 400)) -eq 0 ] && max=29 ;; esac
  [ "$d" -le "$max" ]
}

fails=0
fail() { echo "FAIL $(printf '%s' "$*" | tr -d '\000-\010\013-\037\177')"; fails=$((fails + 1)); }

bytes() { wc -c < "$1" | tr -d ' '; }

check_log() { # $1 = findings.md or exceptions.md
  local f="$1" in_fence=0 in_cmt=0 n=0 hdr="" hdr_line=0 tagged=0 line text
  [ -f "$f" ] || { fail "files: $f missing"; return; }
  # Entry = any "#" heading line after line 1 (must be "## YYYY-MM-DD — title") up to the
  # next heading or EOF. Tags inside ``` / ~~~ fences, <!-- comments --> and `inline code`
  # do not count; an unclosed fence or comment is itself a failure.
  close_entry() {
    if [ -n "$hdr" ] && [ "$tagged" -eq 0 ]; then
      fail "files: $f:$hdr_line entry has no evidence tag: $hdr"
    fi
  }
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    if [ "$in_cmt" -eq 0 ] && [[ "$line" =~ ^[[:space:]]*(\`\`\`|~~~) ]]; then in_fence=$((1 - in_fence)); continue; fi
    [ "$in_fence" -eq 1 ] && continue
    text="$line"
    if [ "$in_cmt" -eq 1 ]; then
      [[ "$text" == *"-->"* ]] || continue
      text="${text#*-->}"; in_cmt=0
    fi
    text=$(printf '%s' "$text" | sed -e 's/<!--.*-->//g' -e 's/`[^`]*`//g')
    if [[ "$text" == *"<!--"* ]]; then text="${text%%<!--*}"; in_cmt=1; fi
    if [ "$n" -gt 1 ] && [[ "$line" =~ ^[[:space:]]{0,3}# ]]; then
      close_entry
      hdr="$line"; hdr_line=$n; tagged=0
      if ! printf '%s\n' "$line" | grep -Eq "$HEADER_RE"; then
        fail "files: $f:$n bad header (want '## YYYY-MM-DD — title'): $line"
      else
        local d="${line:3:10}"
        if ! valid_date "$d"; then
          fail "files: $f:$n invalid date in header: $line"
        elif [[ "$d" > "$TOMORROW" ]]; then
          fail "files: $f:$n future date in header: $line"
        fi
      fi
      continue
    fi
    if [ -n "$hdr" ] && printf '%s\n' "$text" | grep -Eq "$TAG_RE"; then tagged=1; fi
  done < "$f"
  close_entry
  [ "$in_fence" -eq 0 ] || fail "files: $f has an unclosed code fence"
  [ "$in_cmt" -eq 0 ] || fail "files: $f has an unclosed <!-- comment"
}

check_files() {
  # 1. Knowledge files (any depth): each <= 40,000 bytes (one Read call, CLAUDE.md "Updating the KB").
  local f found=0
  while IFS= read -r -d '' f; do
    found=1
    if [ ! -f "$f" ]; then fail "files: $f is not a regular file"; continue; fi
    local b; b=$(bytes "$f")
    [ "$b" -le "$KB_MAX_BYTES" ] || fail "files: $f is $b bytes > $KB_MAX_BYTES"
  done < <(find knowledge -name '*.md' -print0 2>/dev/null)
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

  # 4. Hooks and scripts executable, on disk and in the git index: a 100644 file
  #    loses +x on the next clone and the hook then fails as a non-blocking error
  #    [SOURCE: https://code.claude.com/docs/en/hooks.md, 2026-10-06].
  local idx
  for f in .claude/hooks/* scripts/*.sh; do
    [ -f "$f" ] || continue
    [ -x "$f" ] || fail "files: $f is not executable"
    idx=$(git ls-files -s -- "$f" 2>/dev/null | awk '{print $1}')
    if [ -n "$idx" ] && [ "$idx" != "100755" ]; then
      fail "files: $f has git mode $idx (want 100755)"
    fi
  done

  # 5. Hook wiring: settings.json parses, Stop and SessionStart are wired with the exact
  #    commands, no disableAllHooks, and every other command that starts with
  #    ${CLAUDE_PROJECT_DIR} points to an existing executable.
  local s=.claude/settings.json
  if [ ! -f "$s" ]; then fail "files: $s missing"; return; fi
  if ! command -v jq >/dev/null 2>&1; then fail "files: jq not installed, cannot validate $s"; return; fi
  if ! jq -e . "$s" >/dev/null 2>&1; then fail "files: $s is not valid JSON"; return; fi
  # Exact command strings: a no-op that merely mentions the path must not pass.
  local want_stop='"${CLAUDE_PROJECT_DIR}"/.claude/hooks/stop.sh'
  local want_ss='"${CLAUDE_PROJECT_DIR}"/.claude/hooks/session-start.sh'
  jq -e --arg w "$want_stop" '[.hooks.Stop[]? | select((.matcher // "") == "" or .matcher == "*") | .hooks[]? | select(.type == "command" and .command == $w and ((.timeout // 600) >= 30))] | length > 0' "$s" >/dev/null 2>&1 \
    || fail "files: $s does not wire exactly $want_stop to Stop (no matcher, timeout >= 30)"
  jq -e --arg w "$want_ss" '[.hooks.SessionStart[]? | select((.matcher // "") | split("|") | (index("startup") != null and index("resume") != null and index("compact") != null)) | .hooks[]? | select(.type == "command" and .command == $w)] | length > 0' "$s" >/dev/null 2>&1 \
    || fail "files: $s does not wire exactly $want_ss to SessionStart (matcher startup|resume|compact)"
  # disableAllHooks in any project settings file switches every hook off.
  local sf
  for sf in .claude/settings*.json; do
    [ -f "$sf" ] || continue
    grep -q 'disableAllHooks' "$sf" && fail "files: $sf contains disableAllHooks"
  done
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
  # Modified/staged tracked files.
  local st; st=$(git status --porcelain --untracked-files=no 2>/dev/null)
  if [ -n "$st" ]; then
    fail "git: $(printf '%s\n' "$st" | wc -l | tr -d ' ') uncommitted change(s): $(printf '%s\n' "$st" | head -5 | cut -c4- | tr '\n' ' ')"
  fi
  # Untracked files: only the committed .gitignore may hide them, not .git/info/exclude
  # or a global excludesFile. Claude Code puts settings.local.json in global excludes;
  # it is personal, so it is allowed (its disableAllHooks is checked in "files").
  local unt; unt=$(git ls-files --others --exclude-per-directory=.gitignore 2>/dev/null | grep -vx '.claude/settings.local.json')
  if [ -n "$unt" ]; then
    fail "git: $(printf '%s\n' "$unt" | wc -l | tr -d ' ') untracked file(s): $(printf '%s\n' "$unt" | head -5 | tr '\n' ' ')"
  fi
  # Index flags that make git status blind to edits.
  local hidden; hidden=$(git ls-files -v 2>/dev/null | grep -E '^([a-z]|S) ' | cut -c3- | head -5)
  [ -z "$hidden" ] || fail "git: assume-unchanged/skip-worktree flags hide edits: $(printf '%s\n' "$hidden" | tr '\n' ' ')"
  local br; br=$(git branch --show-current)
  if [ -z "$br" ]; then fail "git: detached HEAD (no branch to push)"; return; fi
  local up_remote; up_remote=$(git config --get "branch.$br.remote" 2>/dev/null)
  if [ -n "$up_remote" ] && [ "$up_remote" != "origin" ]; then
    fail "git: upstream of $br is on remote '$up_remote', not origin"
  elif git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
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
