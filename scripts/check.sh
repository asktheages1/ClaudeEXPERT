#!/bin/bash
# Deterministic checks for this repository. Exit 0 = all green, 1 = at least one FAIL line.
# Usage: scripts/check.sh [files|git|all]   (default: all)
# Budgets come from knowledge/O0 §1-§2: a knowledge file must fit one Read call (≤ 40 KB),
# CLAUDE.md must stay under 200 lines, small state files must stay ≤ ~5k tokens to survive compaction.
set -u
cd "$(dirname "$0")/.." || exit 1
mode="${1:-all}"
fail=0
err() { printf 'FAIL: %s\n' "$*"; fail=1; }

check_files() {
  for f in knowledge/*.md; do
    b=$(wc -c <"$f"); [ "$b" -le 40000 ] || err "$f is $b bytes (limit 40000: one Read call)"
  done
  [ -f CLAUDE.md ] || err "CLAUDE.md missing"
  l=$(wc -l <CLAUDE.md); [ "$l" -le 200 ] || err "CLAUDE.md has $l lines (limit 200)"
  b=$(wc -c <CLAUDE.md); [ "$b" -le 16000 ] || err "CLAUDE.md is $b bytes (limit 16000)"
  for f in open-items.md; do
    [ -f "$f" ] || { err "$f missing"; continue; }
    b=$(wc -c <"$f"); [ "$b" -le 8000 ] || err "$f is $b bytes (limit 8000: hook stdout cap and compaction survival)"
  done
  for f in findings.md exceptions.md; do
    [ -f "$f" ] || { err "$f missing"; continue; }
    out=$(awk -v f="$f" '
      function flush() { if (hdr != "" && !tag) printf "FAIL: %s: entry without evidence tag: %s\n", f, hdr }
      /^## / { flush(); hdr=$0; tag=0
               if ($0 !~ /^## 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] — /) printf "FAIL: %s: header must be \"## YYYY-MM-DD — title\": %s\n", f, $0
               next }
      hdr != "" && /\[(MEASURED|SOURCE|CODE|CL|3P|ASSUMPTION|OF|IS|BLOG|S:)/ { tag=1 }
      END { flush() }' "$f")
    [ -z "$out" ] || { printf '%s\n' "$out"; fail=1; }
  done
  for f in .claude/hooks/*.sh scripts/*.sh; do [ -x "$f" ] || err "$f is not executable"; done
  [ $fail -eq 0 ] && echo "OK: files"
}

check_git() {
  s=$(git status --porcelain --untracked-files=all 2>&1)
  [ -z "$s" ] || err "uncommitted or untracked changes (commit them, or move drafts to the scratchpad):"$'\n'"$s"
  if up=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
    n=$(git rev-list --count "$up..HEAD" 2>/dev/null || echo "?")
    [ "$n" = "0" ] || err "$n commit(s) not pushed to $up"
  else
    err "branch $(git branch --show-current) has no upstream: git push -u origin $(git branch --show-current)"
  fi
  [ $fail -eq 0 ] && echo "OK: git"
}

case "$mode" in
  files) check_files ;;
  git) check_git ;;
  all) check_files; f1=$fail; fail=0; check_git; fail=$((f1 || fail)) ;;
  *) echo "usage: $0 [files|git|all]" >&2; exit 2 ;;
esac
exit $fail
