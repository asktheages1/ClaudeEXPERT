#!/bin/bash
# Tests for scripts/check.sh and .claude/hooks/stop.sh.
# Builds a temp copy of the working tree with its own git repo and a local bare
# remote, plants each failure check.sh must catch, and asserts the FAIL line.
# Exit 0 = all tests pass. Touches nothing in this repo.
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; failed=0

ok()  { echo "PASS $1"; pass=$((pass + 1)); }
bad() { echo "FAILED $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/    | /'; failed=$((failed + 1)); }

git_q() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@" >/dev/null 2>&1; }

# Baseline: copy tracked + untracked (not ignored) files, own repo, pushed to a bare remote.
BASE="$TMP/base"; mkdir -p "$BASE"
(cd "$SRC" && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t "$BASE")
git init -q --bare "$TMP/remote.git"
(cd "$BASE" && git_q init -b work && git_q add -A && git_q commit -m base \
  && git_q remote add origin "$TMP/remote.git" && git_q push -u origin work)

fresh() { rm -rf "$TMP/w"; cp -a "$BASE" "$TMP/w"; cd "$TMP/w" || exit 2; }

# expect <name> <mode> <regex of expected FAIL line>  (runs check.sh in $TMP/w)
expect() {
  local out rc
  out=$(scripts/check.sh "$2" 2>&1); rc=$?
  if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -Eq "^FAIL .*$3"; then ok "$1"
  else bad "$1 (rc=$rc, want 1 and /$3/)" "$out"; fi
}

# 0. Clean copy is green.
fresh; out=$(scripts/check.sh all 2>&1); rc=$?
if [ "$rc" -eq 0 ] && ! printf '%s\n' "$out" | grep -q '^FAIL'; then ok "clean run green"; else bad "clean run green (rc=$rc)" "$out"; fi

# 0b. Clean run from a subdirectory is also green (root comes from the script path).
fresh; out=$(cd knowledge && ../scripts/check.sh all 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "clean run from subdirectory green" || bad "clean run from subdirectory (rc=$rc)" "$out"

# 1. Oversized knowledge file.
fresh; f=$(ls knowledge/*.md | head -1); head -c 40001 /dev/zero | tr '\0' 'x' > "$f"
expect "knowledge file > 40000 bytes" files "$f is 40001 bytes > 40000"

# 2. CLAUDE.md > 200 lines (bytes still under 16000).
fresh; head -c 0 /dev/null > CLAUDE.md; for i in $(seq 1 201); do echo "l" >> CLAUDE.md; done
expect "CLAUDE.md > 200 lines" files "CLAUDE.md has 201 lines > 200"

# 3. CLAUDE.md > 16000 bytes (lines still under 200).
fresh; head -c 16001 /dev/zero | tr '\0' 'y' > CLAUDE.md
expect "CLAUDE.md > 16000 bytes" files "CLAUDE.md is 16001 bytes > 16000"

# 4. Bad header (date format) in findings.md.
fresh; printf '\n## Oct 6 2026 — something\n- fact [MEASURED: x → y, 2026-10-06]\n' >> findings.md
expect "bad header" files "findings.md:[0-9]+ bad header"

# 4b. Impossible date in header.
fresh; printf '\n## 2026-13-45 — something\n- fact [MEASURED: x → y]\n' >> findings.md
expect "invalid date in header" files "findings.md:[0-9]+ invalid date"

# 5. Entry without an evidence tag (exceptions.md).
fresh; printf '\n## 2026-10-07 — rule → exception\n- trust me, it works\n' >> exceptions.md
expect "entry without tag" files "exceptions.md:[0-9]+ entry has no evidence tag"

# 5b. A tag only inside a code fence does not count.
fresh; printf '\n## 2026-10-07 — fenced\n```\n[MEASURED: fake]\n```\n' >> findings.md
expect "tag only inside code fence" files "findings.md:[0-9]+ entry has no evidence tag"

# 6. Non-executable hook.
fresh; chmod -x .claude/hooks/stop.sh
expect "non-executable hook" files ".claude/hooks/stop.sh is not executable"

# 6b. Executable on disk but committed as 100644.
fresh; git update-index --chmod=-x .claude/hooks/session-start.sh
expect "hook committed without +x" files ".claude/hooks/session-start.sh has git mode 100644"

# 6c. Hook wired to a wrong path.
fresh; sed -i 's#hooks/stop.sh#hooks/stopp.sh#' .claude/settings.json
expect "Stop hook wired to wrong path" files "does not wire .claude/hooks/stop.sh"

# 7. Uncommitted change to a tracked file.
fresh; echo "x" >> findings.md
expect "uncommitted file" git "uncommitted change"

# 7b. Untracked file.
fresh; echo "x" > stray.txt
expect "untracked file" git "untracked file.*stray.txt"

# 8. Unpushed commit.
fresh; echo "x" > new.txt; git_q add new.txt; git_q commit -m n
expect "unpushed commit" git "1 unpushed commit"

# 9. Missing upstream with a local-only commit.
fresh; git_q checkout -b orphan-branch; echo "x" > new.txt; git_q add new.txt; git_q commit -m n
expect "missing upstream" git "has no upstream"

# 9b. Missing upstream, nothing local-only (fresh session branch): green by design.
fresh; git_q checkout -b fresh-session; out=$(scripts/check.sh git 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "no upstream, no local commits = green" || bad "no upstream, no local commits (rc=$rc)" "$out"

# --- Stop hook (stdin JSON, counter per session_id) ---
hook() { printf '{"session_id":"%s","stop_hook_active":%s,"hook_event_name":"Stop"}' "$1" "$2" | .claude/hooks/stop.sh; }
sid="test-$$-$RANDOM"
fresh; echo "x" > stray.txt   # red
o1=$(hook "$sid" false); o2=$(hook "$sid" true); o3=$(hook "$sid" true); o4=$(hook "$sid" true)
printf '%s' "$o1" | grep -q '"decision":"block".*1/3.*stray.txt' && ok "stop: red blocks (1/3) with FAIL lines" || bad "stop: block 1" "$o1"
printf '%s' "$o3" | grep -q '"decision":"block".*3/3' && ok "stop: 3rd consecutive block" || bad "stop: block 3" "$o3"
printf '%s' "$o4" | grep -q '"systemMessage":"Stop hook gave up after 3' && ! printf '%s' "$o4" | grep -q decision \
  && ok "stop: gives up on 4th stop with systemMessage" || bad "stop: give-up" "$o4"
printf '%s' "$o1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null && ok "stop: block output is valid JSON" || bad "stop: JSON" "$o1"
o5=$(hook "$sid" false)
printf '%s' "$o5" | grep -q '1/3' && ok "stop: new turn (stop_hook_active=false) restarts the count" || bad "stop: reset" "$o5"
rm -f stray.txt; o6=$(hook "$sid" true); rc=$?
[ "$rc" -eq 0 ] && [ -z "$o6" ] && ok "stop: green lets the turn end (no output, exit 0)" || bad "stop: green (rc=$rc)" "$o6"
chmod -x scripts/check.sh; o7=$(hook "$sid-b" false)
printf '%s' "$o7" | grep -q '"decision":"block".*check.sh missing or not executable' && ok "stop: missing check.sh blocks" || bad "stop: missing check.sh" "$o7"
rm -f "${HOME:-/tmp}/.cache/claudeexpert-stop-hook/$sid".count "${HOME:-/tmp}/.cache/claudeexpert-stop-hook/$sid-b".count

echo "test-check.sh: $pass passed, $failed failed"
[ "$failed" -eq 0 ]
