#!/bin/bash
# Deterministic checks for this repository. Exit 0 = green, 1 = at least one FAIL line.
# Usage: scripts/check.sh [files|git|all]   (default: all)
# Budgets: every file fits one Read call (≤ 40 KB, O0 §1); CLAUDE.md ≤ 200 lines (O0 §2);
# open-items.md ≤ 8 KB (hook stdout cap, compaction survival). Entries dated after 2026-10-06 need
# re-runnable proof: [MEASURED: `command` → result …] or [SOURCE: https://…]; agent output is never MEASURED.
set -u
cd "$(dirname "$0")/.." || exit 1
mode="${1:-all}"; fail=0
err() { printf 'FAIL: %s\n' "$*"; fail=1; }

check_files() {
  # 1. Every file in the repo (tracked or untracked, not ignored) fits one Read call.
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    b=$(wc -c <"$f"); [ "$b" -le 40000 ] || err "$f is $b bytes (limit 40000 per file)"
  done < <(git ls-files --cached --others --exclude-standard)
  l=$(wc -l <CLAUDE.md); [ "$l" -le 200 ] || err "CLAUDE.md has $l lines (limit 200)"
  b=$(wc -c <CLAUDE.md); [ "$b" -le 16000 ] || err "CLAUDE.md is $b bytes (limit 16000)"
  b=$(wc -c <open-items.md); [ "$b" -le 8000 ] || err "open-items.md is $b bytes (limit 8000)"
  # 2. CLAUDE.md is the only instruction file Claude Code loads by itself.
  grep -nE '(^|[[:space:]])@[^[:space:]`]' CLAUDE.md >/dev/null && err "CLAUDE.md contains an @import"
  x=$(git ls-files --cached --others --exclude-standard -- '.claude/rules/*' '.claude/CLAUDE.md' 'CLAUDE.local.md' '*/CLAUDE.md' 'AGENTS.md')
  [ -z "$x" ] || err "auto-loaded instruction files besides CLAUDE.md: $x"
  # 3. Entry format; a [MEASURED: …] tag must carry a backticked command and → result, and must not cite an agent.
  for f in findings.md exceptions.md; do
    out=$(awk -v f="$f" '
      function flush() { if (hdr != "" && !tag) printf "FAIL: %s: entry without evidence tag: %s\n", f, hdr }
      /^## / { flush(); hdr=$0; tag=0
               if ($0 !~ /^## 20[0-9][0-9]-[01][0-9]-[0-3][0-9] — /) printf "FAIL: %s: header must be \"## YYYY-MM-DD — title\": %s\n", f, $0
               strict = (substr($0,4,10) > "2026-10-06"); next }   # entries up to 2026-10-06 grandfathered
      hdr == "" { next }
      /\[MEASURED[^]]*(agent|reviewer)/ { printf "FAIL: %s: agent output tagged MEASURED (it is a claim): %s\n", f, hdr }
      strict && (/\[MEASURED: [^]]*`[^`]+`[^]]*→/ || /\[SOURCE: https?:\/\// || /\[(3P|CL|ASSUMPTION)[]:]/) { tag=1 }
      !strict && /\[(MEASURED|SOURCE|CODE|CL|3P|ASSUMPTION|OF|IS|BLOG|S:)/ { tag=1 }
      END { flush() }' "$f")
    [ -z "$out" ] || { printf '%s\n' "$out"; fail=1; }
  done
  [ $fail -eq 0 ] && echo "OK: files"
}

check_git() {
  s=$(git status --porcelain --untracked-files=all 2>&1)
  [ -z "$s" ] || err "uncommitted or untracked changes:"$'\n'"$s"
  [ -z "$(git stash list)" ] || err "git stash is not empty (stashed work is lost with the container): $(git stash list | head -3)"
  ign=$(git ls-files --others --ignored --exclude-standard | grep -v -e '^\.claude/worktrees/' -e '^\.claude/settings\.local\.json$' | head -5)
  [ -z "$ign" ] || err "ignored files in the repo (lost with the container; move them to the scratchpad): $ign"
  loc=$(git log --branches --not --remotes --oneline 2>/dev/null | head -5)
  [ -z "$loc" ] || err "commits on no remote branch (push them):"$'\n'"$loc"
  [ -n "$(git branch --show-current)" ] || err "detached HEAD: switch back to the session branch"
  [ $fail -eq 0 ] && echo "OK: git"
}

case "$mode" in
  files) check_files ;; git) check_git ;;
  all) check_files; f1=$fail; fail=0; check_git; fail=$((f1 || fail)) ;;
  *) echo "usage: $0 [files|git|all]" >&2; exit 2 ;;
esac
exit $fail
