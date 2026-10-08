#!/bin/bash
# Test of hooks.py in a throwaway repo. Usage: bash test_hooks.sh /path/to/hooks.py
# Prints one line per case and "WYNIK: N/M"; exit 0 only when all cases pass.
H=$(realpath "${1:?hooks.py path}")
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q --bare -b main "$T/origin.git"
git clone -q "$T/origin.git" "$T/w" 2>/dev/null
W="$T/w"; cd "$W" || exit 1
git checkout -q -b main 2>/dev/null
mkdir -p GaleriaFolderow/tools GaleriaFolderow/dokumentacja GaleriaFolderow/backup .github/workflows .claude
printf 'APP_VERSION = "1.0.0"\n' > GaleriaFolderow/galeria.py
printf 'stan\n' > GaleriaFolderow/STATUS.md
printf -- '- v1.0.0\n' > GaleriaFolderow/CHANGELOG.md
printf 'obszar\n' > GaleriaFolderow/dokumentacja/a.md
printf 'import os,sys\nsys.exit(1 if os.environ.get("RED")=="1" else 0)\n' > GaleriaFolderow/tools/doc_check.py
printf 'name: ai\non:\n  workflow_dispatch:\n    inputs:\n      x:\n        type: string\njobs: {}\n' > .github/workflows/ai.yml
printf 'REGULY AGENTOW\n' > .claude/agent-rules.md
git add -A && git commit -qm init && git push -q origin main 2>/dev/null
git checkout -q -b claude/sess
printf 'stan 2\n' > GaleriaFolderow/STATUS.md && git commit -qam status
export CLAUDE_PROJECT_DIR="$W"
pass=0; tot=0
chk() { # name expected_exit actual_exit
  tot=$((tot+1)); if [ "$2" = "$3" ]; then pass=$((pass+1)); r=OK; else r=BLAD; fi
  echo "$r [$1] oczekiwane $2, jest $3"; }
bashcase() { # expected command [RED] [cwd]
  RED="${3:-}" python3 -I "$H" bash <<<"$(jq -n --arg c "$2" --arg d "${4:-$W}" '{tool_input:{command:$c},cwd:$d}')" >/dev/null 2>&1
  chk "bash: $2 RED=${3:-0}" "$1" "$?"; }
# Appendix S cases 1-20 (RED=1)
bashcase 0 'git push -u origin claude/session-abc' 1
bashcase 0 'git push origin HEAD && rm -f /tmp/x.txt' 1
bashcase 0 'git add -A && git commit -m "kafelki +2 px" && git push -u origin claude/x' 1
bashcase 0 'git push origin HEAD 2>&1 | tail -f /dev/null' 1
bashcase 0 'git commit -m "opis: git push -f jest zabroniony"' 1
bashcase 0 'git push --dry-run origin HEAD' 1
bashcase 0 'git push' 1
bashcase 2 'git push -fu origin x' 1
bashcase 2 'git push origin "+HEAD:main"' 1
bashcase 2 'git -c core.x=1 push --force' 1
bashcase 2 'git --no-pager push -f origin x' 1
bashcase 2 'git -C . push --force-with-lease' 1
bashcase 2 'git push --mirror origin' 1
bashcase 2 'git push --dry-run origin HEAD:main' 1
bashcase 2 'git push origin HEAD:refs/heads/main' 1
bashcase 2 'git push origin main' 1
bashcase 2 'git fetch origin main && git checkout main && git merge --ff-only origin/main && git merge --no-edit claude/s && git push origin main && git checkout claude/s' 1
bashcase 2 'git checkout main && git merge claude/s && git push' 1
bashcase 0 'git push origin claude/maintenance' 1
bashcase 2 'git filter-repo --path x' 1
# case 21: main push, doc_check green, branch changed STATUS only
bashcase 0 'git push origin main'
# case 22: current branch main, RED
git checkout -q main; bashcase 2 'git push' 1; git checkout -q claude/sess
# new: diff rules (doc_check green)
printf 'APP_VERSION = "1.0.1"\n' > GaleriaFolderow/galeria.py && git commit -qam code
bashcase 2 'git push origin HEAD:main'                              # code without CHANGELOG/docs
printf -- '- v1.0.1\n' >> GaleriaFolderow/CHANGELOG.md && git commit -qam cl
bashcase 2 'git push origin HEAD:main'                              # CHANGELOG but no docs, no marker
printf -- '  docs: bez zmian (tylko stała)\n' >> GaleriaFolderow/CHANGELOG.md && git commit -qam marker
bashcase 0 'git push origin HEAD:main'                              # marker accepted
git checkout -q -b claude/s2 origin/main
printf 'APP_VERSION = "1.0.2"\n' > GaleriaFolderow/galeria.py
printf -- '- v1.0.2\n' >> GaleriaFolderow/CHANGELOG.md; printf 'obszar 2\n' > GaleriaFolderow/dokumentacja/a.md
git commit -qam all
bashcase 2 'git push origin HEAD:main'                              # no STATUS
printf 'stan 3\n' > GaleriaFolderow/STATUS.md && git commit -qam st
bashcase 0 'git push origin HEAD:main'                              # complete
bashcase 0 'git push -u origin claude/s2' 1                         # session branch, RED: passes
# workflow trigger check on every push
sed -i 's/^on:$/on:\n  push:/' .github/workflows/ai.yml
bashcase 2 'git push -u origin claude/s2'                           # working tree has push trigger
git checkout -q .github/workflows/ai.yml
printf 'name: b\non: [push, workflow_dispatch]\njobs: {}\n' > .github/workflows/b.yml && git add -A && git commit -qm wf
bashcase 2 'git push origin claude/s2'                              # HEAD has inline push trigger
git rm -q .github/workflows/b.yml && git commit -qm rmwf
bashcase 0 'git push origin claude/s2'
bashcase 0 'ls -la; echo push'                                      # no git push
git worktree add -q "$T/wt" main 2>/dev/null
bashcase 2 'git push' 1 "$T/wt"                                     # worktree on main, RED (S4)
bashcase 0 'git push' 1                                             # main checkout on session branch
# wf_triggers parser
pyt() { tot=$((tot+1)); got=$(python3 -I -c "import importlib.util,sys;s=importlib.util.spec_from_file_location('h',sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);print(m.wf_bad(sys.argv[2]))" "$H" "$1");
  if [ "$got" = "$2" ]; then pass=$((pass+1)); echo "OK [wf] $got"; else echo "BLAD [wf] $1 -> $got (oczekiwane $2)"; fi; }
pyt $'on: push\n' "['push']"
pyt $'on: workflow_dispatch\n' "[]"
pyt $'"on":\n  schedule:\n    - cron: x\n  workflow_dispatch:\n' "['schedule']"
pyt $'on: {workflow_dispatch: {inputs: {a: {type: string}}}, pull_request_target: {}}\n' "['pull_request_target']"
pyt $'on:\n  - workflow_dispatch\n  - workflow_run\n' "['workflow_run']"
pyt $'on: # komentarz\n  workflow_dispatch:\n' "[]"
# edit guard
editcase() { # expected json
  python3 -I "$H" edit <<<"$2" >/dev/null 2>&1; chk "edit: $3" "$1" "$?"; }
editcase 2 "$(jq -n --arg f "$W/GaleriaFolderow/backup/galeria_v1.py" '{tool_name:"Write",tool_input:{file_path:$f,content:"x"}}')" "Write do backup/"
editcase 0 "$(jq -n --arg f "$W/GaleriaFolderow/galeria.py" '{tool_name:"Edit",tool_input:{file_path:$f,old_string:"1.0.2",new_string:"1.0.3"}}')" "Edit galeria.py"
editcase 2 "$(jq -n --arg f "$W/.github/workflows/ai.yml" '{tool_name:"Edit",tool_input:{file_path:$f,old_string:"on:\n",new_string:"on:\n  push:\n"}}')" "Edit workflow +push"
editcase 0 "$(jq -n --arg f "$W/.github/workflows/ai.yml" '{tool_name:"Edit",tool_input:{file_path:$f,old_string:"type: string",new_string:"type: boolean"}}')" "Edit workflow inputs"
editcase 2 "$(jq -n --arg f "$W/.github/workflows/n.yml" '{tool_name:"Write",tool_input:{file_path:$f,content:"on:\n  schedule:\n    - cron: x\n"}}')" "Write workflow schedule"
# turn + stop
J='{"session_id":"s1","stop_hook_active":false,"last_assistant_message":"gotowe"}'
python3 -I "$H" turn <<<"$J"; o=$(python3 -I "$H" turn <<<"$J"); chk "turn: brak stdout" "" "$o"
o=$(python3 -I "$H" stop <<<"$J"); chk "stop: bez zmian -> cisza" "" "$o"
echo x >> GaleriaFolderow/dokumentacja/a.md
o=$(python3 -I "$H" stop <<<"$J" | jq -r .hookSpecificOutput.hookEventName 2>/dev/null); chk "stop: zmiana bez listy -> przypomnienie" "Stop" "$o"
o=$(python3 -I "$H" stop <<<'{"session_id":"s1","last_assistant_message":"Zmiany w tej odpowiedzi:\n- docs"}'); chk "stop: z listą -> cisza" "" "$o"
o=$(python3 -I "$H" stop <<<'{"session_id":"s1","stop_hook_active":true}'); chk "stop: stop_hook_active -> cisza" "" "$o"
python3 -I "$H" turn <<<"$J"; echo y >> GaleriaFolderow/dokumentacja/a.md
o=$(python3 -I "$H" stop <<<"$J" | jq -r .hookSpecificOutput.hookEventName 2>/dev/null); chk "stop: ponowna edycja zmienionego pliku" "Stop" "$o"
git checkout -q GaleriaFolderow/dokumentacja/a.md
# session + subagent + robustness
o=$(python3 -I "$H" session <<<'{"source":"startup"}' | head -1); case "$o" in *"APP_VERSION 1.0.2"*) chk session 0 0;; *) chk "session: $o" 0 1;; esac
o=$(python3 -I "$H" subagent <<<'{}' | jq -r .hookSpecificOutput.additionalContext); chk subagent "REGULY AGENTOW" "$o"
for n in turn stop session subagent; do python3 -I "$H" $n <<<'nie json' >/dev/null 2>&1; chk "$n: zły JSON -> 0" 0 $?; done
CLAUDE_PROJECT_DIR=/nonexistent python3 -I "$H" turn <<<"$J" >/dev/null 2>&1; chk "turn: zły katalog -> 0" 0 $?
# CRLF copy of hooks.py still works
sed 's/$/\r/' "$H" > "$T/crlf.py"
python3 -I "$T/crlf.py" bash <<<"$(jq -n --arg c 'git push -f origin x' --arg d "$W" '{tool_input:{command:$c},cwd:$d}')" >/dev/null 2>&1; chk "CRLF: force-push" 2 $?
python3 -I "$T/crlf.py" turn <<<"$J" >/dev/null 2>&1; chk "CRLF: turn" 0 $?
# --- skeptic review K1-K6 ---
cd "$W"; git checkout -q -f claude/s2 2>/dev/null; git worktree remove -f "$T/wt"
newb() { git checkout -q -f -B "$1" origin/main; }
full() { printf "$1\n" >> GaleriaFolderow/galeria.py; printf "$1\n" >> GaleriaFolderow/STATUS.md; printf -- "- v$1\n" >> GaleriaFolderow/CHANGELOG.md; }
# K4: push to main via HEAD/@/wrappers (local main has code change only)
git checkout -q -f main; printf '# k4\n' >> GaleriaFolderow/galeria.py; git commit -qam k4
for c in 'git push origin HEAD' 'git push -u origin HEAD' 'git push origin @' 'timeout 60 git push origin main' '(git push origin main)' 'env X=1 git push origin main' 'command git push origin main' 'if git push origin main; then echo ok; fi' 'git push origin $(git branch --show-current)'; do bashcase 2 "$c"; done
bashcase 2 'nice -n 5 git push -f origin x'
bashcase 2 'timeout 60 git push --force'
git reset -q --hard origin/main; git checkout -q -f claude/s2
bashcase 0 'git push -u origin HEAD'                                  # session branch via HEAD
git worktree add -q "$T/wt2" main 2>/dev/null
bashcase 2 "cd $T/wt2 && git push" 1                                  # cd into worktree on main, RED
git worktree remove -f "$T/wt2"
# K5: merge chain + push main in one call is refused; push alone passes
newb claude/k5; full k5; printf 'k5\n' >> GaleriaFolderow/dokumentacja/a.md; git commit -qam k5
bashcase 2 'git fetch origin main && git push origin HEAD:main'
bashcase 0 'git push origin HEAD:main'
# K3: BACKLOG does not count as documentation
newb claude/k3; full k3; mkdir -p GaleriaFolderow/dokumentacja; printf 'x\n' > GaleriaFolderow/dokumentacja/BACKLOG.md; git add -A; git commit -qm k3
bashcase 2 'git push origin HEAD:main'
# K2: missing origin/main blocks push to main
newb claude/k2; full k2; printf 'k2\n' >> GaleriaFolderow/dokumentacja/a.md; git commit -qam k2
git update-ref -d refs/remotes/origin/main
bashcase 2 'git push origin HEAD:main'
git fetch -q origin
# K6: freeze list in origin/main
git checkout -q -f main; mkdir -p GaleriaFolderow/dokumentacja/migracja
printf 'GaleriaFolderow/dokumentacja/a.md\tabc\nGaleriaFolderow/dokumentacja/b.md\tdef\n' > GaleriaFolderow/dokumentacja/migracja/ZAMROZONE.tsv
printf 'b\n' > GaleriaFolderow/dokumentacja/b.md; git add -A; git commit -qm freeze; git push -q origin main; git fetch -q origin
newb claude/k6a; full k6a; printf 'cond\n' > GaleriaFolderow/dokumentacja/a.md; git commit -qam k6a
bashcase 2 'git push origin HEAD:main'                                # condensation + code in one branch
newb claude/k6b; printf 'k6b\n' >> GaleriaFolderow/STATUS.md; printf 'GaleriaFolderow/x.md\t0\n' >> GaleriaFolderow/dokumentacja/migracja/ZAMROZONE.tsv; git commit -qam k6b
bashcase 2 'git push origin HEAD:main'                                # rows added to ZAMROZONE
newb claude/k6c; printf 'k6c\n' >> GaleriaFolderow/STATUS.md; sed -i '/b.md/d' GaleriaFolderow/dokumentacja/migracja/ZAMROZONE.tsv; printf 'skondensowany\n' > GaleriaFolderow/dokumentacja/b.md; git commit -qam k6c
bashcase 0 'git push origin HEAD:main'                                # row removed, condensation alone
# K1: shell-form wrapper used in settings.json
WR='[ ! -f "$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py" ] || exec python3 -I "$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py" bash'
FJ=$(jq -n --arg c 'git push -f origin x' --arg d "$W" '{tool_input:{command:$c},cwd:$d}')
sh -c "$WR" <<<"$FJ" >/dev/null 2>&1; chk "K1: brak hooks.py -> 0" 0 $?
mkdir -p "$W/.claude/hooks"; cp "$H" "$W/.claude/hooks/hooks.py"
sh -c "$WR" <<<"$FJ" >/dev/null 2>&1; chk "K1: hooks.py obecny, force -> 2" 2 $?
echo "WYNIK: $pass/$tot"; [ "$pass" = "$tot" ]
