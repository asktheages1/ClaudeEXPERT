import hashlib, json, os, re, shlex, subprocess, sys, tempfile

PROJ = os.environ.get("CLAUDE_PROJECT_DIR", ".")
GUARD_RE = re.compile(r"\bgit\b.*\b(push|filter-branch|filter-repo)\b", re.S)


def run(args, cwd=None, timeout=60):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout)


def git(top, *a, timeout=60):
    return run(["git", "-C", top, *a], timeout=timeout)


def top_of(d):
    return git(d, "rev-parse", "--show-toplevel").stdout.strip() or d


def block(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def wf_triggers(text):
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = re.match(r"""^(["']?)(on|true)\1\s*:\s*(.*?)\s*$""", line)
        if not m:
            continue
        rest = re.sub(r"(^|\s+)#.*$", "", m.group(3)).strip()
        if rest.startswith("["):
            return [x.strip().strip("'\"") for x in rest.strip("[]").split(",") if x.strip()]
        if rest.startswith("{"):
            keys, depth, tok = [], 0, ""
            for ch in rest[1:-1] + ",":
                if ch in "{[":
                    depth += 1
                elif ch in "}]":
                    depth -= 1
                if ch == "," and depth == 0:
                    if tok.strip():
                        keys.append(tok.split(":")[0].strip().strip("'\""))
                    tok = ""
                else:
                    tok += ch
            return keys
        if rest:
            return [rest.strip("'\"")]
        keys, ind = [], None
        for l2 in lines[i + 1:]:
            s = l2.strip()
            if not s or s.startswith("#"):
                continue
            n = len(l2) - len(l2.lstrip())
            if n == 0:
                break
            if ind is None:
                ind = n
            if n == ind:
                keys.append((s[2:] if s.startswith("- ") else s.split(":")[0]).strip().strip("'\""))
        return keys
    return []


def wf_bad(text):
    return [k for k in wf_triggers(text) if k != "workflow_dispatch"]


def wf_problems(top):
    out = []
    d = os.path.join(top, ".github", "workflows")
    if os.path.isdir(d):
        for f in sorted(os.listdir(d)):
            if f.endswith((".yml", ".yaml")):
                with open(os.path.join(d, f), encoding="utf-8", errors="replace") as fh:
                    bad = wf_bad(fh.read())
                if bad:
                    out.append(f".github/workflows/{f} (dysk): {bad}")
    for p in git(top, "ls-tree", "-r", "--name-only", "HEAD", "--", ".github/workflows").stdout.split():
        if p.endswith((".yml", ".yaml")):
            bad = wf_bad(git(top, "show", f"HEAD:{p}").stdout)
            if bad:
                out.append(f"{p} (HEAD): {bad}")
    return out


def diff_problems(top):
    rng = "origin/main...HEAD"
    names = git(top, "diff", "--name-only", rng).stdout.split()
    if not names:
        return []
    p = []
    if "GaleriaFolderow/STATUS.md" not in names:
        p.append("GaleriaFolderow/STATUS.md nie zmieniony w tej gałęzi (przekazanie pracy następnej sesji)")
    if "GaleriaFolderow/galeria.py" in names:
        if "GaleriaFolderow/CHANGELOG.md" not in names:
            p.append("zmiana galeria.py bez wpisu w GaleriaFolderow/CHANGELOG.md")
        docs = any(n.startswith(("GaleriaFolderow/dokumentacja/", ".claude/rules/")) for n in names)
        if not docs:
            added = git(top, "diff", rng, "--", "GaleriaFolderow/CHANGELOG.md").stdout
            if not re.search(r"^\+.*docs: bez zmian \(.+\)", added, re.M):
                p.append("zmiana galeria.py bez zmiany w GaleriaFolderow/dokumentacja/ ani .claude/rules/; "
                         "jeśli celowo: linia 'docs: bez zmian (powód)' w CHANGELOG.md")
    return p


def segments(s):
    lx = shlex.shlex(s.replace("\n", " ; "), posix=True, punctuation_chars=";&|")
    lx.whitespace_split = True
    seg = []
    try:
        for t in lx:
            if t and set(t) <= set(";&|"):
                if seg:
                    yield seg
                seg = []
            else:
                seg.append(t)
    except ValueError:
        yield s.split()
        return
    if seg:
        yield seg


def git_sub(seg):
    i = 0
    while i < len(seg) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", seg[i]):
        i += 1
    if i >= len(seg) or os.path.basename(seg[i]) != "git":
        return None, []
    i += 1
    while i < len(seg) and seg[i].startswith("-"):
        i += 2 if seg[i] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace") else 1
    return (seg[i], seg[i + 1:]) if i < len(seg) else (None, [])


def h_bash(d):
    cmd = d.get("tool_input", {}).get("command", "") or ""
    if not GUARD_RE.search(cmd):
        return
    cwd = d.get("cwd") or PROJ
    try:
        to_main_ctx = any_push = need_main = False
        for seg in segments(cmd):
            sub, args = git_sub(seg)
            if sub in ("checkout", "switch") and "main" in args:
                to_main_ctx = True
            if sub in ("filter-branch", "filter-repo"):
                block("BLOKADA: przepisywanie historii")
            if sub != "push":
                continue
            any_push = True
            opts = [a for a in args if a.startswith("-")]
            pos = [a for a in args if not a.startswith("-")]
            if any(o.startswith(("--force", "--mirror")) or re.match(r"^-[a-zA-Z]*f", o) for o in opts) \
                    or any(x.startswith("+") for x in pos[1:]):
                block("BLOKADA: force-push zabroniony (reguła scalania użytkownika)")
            refs = pos[1:]
            dst_main = any(re.search(r"(^|:)(refs/heads/)?main$", r) for r in refs) or "--all" in opts
            if not refs:
                cur = git(cwd, "branch", "--show-current").stdout.strip()
                dst_main = dst_main or cur == "main" or to_main_ctx
            need_main = need_main or dst_main
        if not any_push:
            return
        top = top_of(cwd)
        wf = wf_problems(top)
        if wf:
            block("BLOKADA push: workflow CI może mieć tylko wyzwalacz workflow_dispatch "
                  "(limit minut Actions, reguła właściciela):\n" + "\n".join(wf))
        if need_main:
            p = diff_problems(top)
            if p:
                block("BLOKADA push na main: brak aktualizacji dokumentacji:\n- " + "\n- ".join(p))
            r = run([sys.executable, "-I", "tools/doc_check.py"], cwd=os.path.join(top, "GaleriaFolderow"), timeout=110)
            if r.returncode != 0:
                block("BLOKADA push na main: doc_check czerwony - najpierw dokumentacja:\n" + r.stdout + r.stderr)
    except SystemExit:
        raise
    except Exception as e:
        block(f"BLOKADA: błąd strażnika ({type(e).__name__}: {e}); polecenie git push/filter wstrzymane, "
              "popraw .claude/hooks/hooks.py")


def h_edit(d):
    ti = d.get("tool_input", {}) or {}
    f = (ti.get("file_path") or "").replace("\\", "/")
    if "/GaleriaFolderow/backup/" in f:
        block("BLOKADA: backup/ jest nienaruszalny (kopie tworzy tylko procedura /dostawa przez cp)")
    if "/.github/workflows/" in f and f.endswith((".yml", ".yaml")):
        try:
            if d.get("tool_name") == "Write":
                new = ti.get("content", "") or ""
            else:
                cur = open(f, encoding="utf-8").read() if os.path.exists(f) else ""
                old, ns = ti.get("old_string", ""), ti.get("new_string", "")
                new = cur.replace(old, ns) if ti.get("replace_all") else cur.replace(old, ns, 1)
        except Exception:
            return
        bad = wf_bad(new)
        if bad:
            block(f"BLOKADA: workflow tylko z wyzwalaczem workflow_dispatch (polecenie właściciela 2026-10-07); niedozwolone: {bad}")


def turn_file(d):
    return os.path.join(tempfile.gettempdir(), "foldery-turn-" + re.sub(r"[^A-Za-z0-9_-]", "", str(d.get("session_id", "x"))))


def state():
    h = hashlib.sha1()
    h.update(git(PROJ, "rev-parse", "HEAD").stdout.encode())
    st = subprocess.run(["git", "-C", PROJ, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
                        capture_output=True, timeout=25).stdout
    h.update(st)
    for t in st.split(b"\0"):
        if len(t) > 3 and t[2:3] == b" ":
            try:
                s = os.stat(os.path.join(PROJ, t[3:].decode("utf-8", "replace")))
                h.update(f"{s.st_size}:{s.st_mtime_ns}".encode())
            except OSError:
                pass
    return h.hexdigest()


def h_turn(d):
    with open(turn_file(d), "w") as fh:
        fh.write(state())


def h_stop(d):
    if d.get("stop_hook_active"):
        return
    try:
        base = open(turn_file(d)).read().strip()
    except OSError:
        return
    if not base or state() == base:
        return
    if "Zmiany w tej odpowiedzi" in (d.get("last_assistant_message") or ""):
        return
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "Stop", "additionalContext":
          "W tej turze zmieniły się pliki albo git, a odpowiedź nie kończy się listą „Zmiany w tej odpowiedzi” "
          "(kod / testy / dokumentacja / paczka / git). Dopisz ją teraz."}}, ensure_ascii=False))


def h_session(d):
    lines = []
    try:
        src = open(os.path.join(PROJ, "GaleriaFolderow", "galeria.py"), encoding="utf-8", errors="replace").read()
        m = re.search(r'^APP_VERSION\s*=\s*["\']([^"\']+)', src, re.M)
        ver = m.group(1) if m else "?"
    except OSError:
        ver = "?"
    try:
        git(PROJ, "fetch", "-q", "origin", "main", timeout=25)
    except Exception:
        pass
    br = git(PROJ, "branch", "--show-current").stdout.strip()
    behind = git(PROJ, "rev-list", "--count", "HEAD..origin/main").stdout.strip() or "?"
    ahead = git(PROJ, "rev-list", "--count", "origin/main..HEAD").stdout.strip() or "?"
    lines.append(f"Foldery: APP_VERSION {ver} · gałąź {br} · za origin/main: {behind} · niescalone z main: {ahead}")
    if behind not in ("0", "?"):
        lines.append("NAJPIERW: git fetch origin main && git merge --ff-only origin/main")
    if ahead not in ("0", "?") and d.get("source") != "startup":
        lines.append("Gałąź ma commity nie scalone z main: przed końcem pracy /dostawa (scalenie).")
    try:
        with open(os.path.join(PROJ, "GaleriaFolderow", "STATUS.md"), encoding="utf-8") as fh:
            lines.append("--- GaleriaFolderow/STATUS.md ---")
            lines.extend(fh.read().splitlines()[:40])
    except OSError:
        lines.append("(brak GaleriaFolderow/STATUS.md)")
    print("\n".join(lines))


def h_subagent(d):
    p = os.path.join(PROJ, ".claude", "agent-rules.md")
    if os.path.exists(p):
        with open(p, encoding="utf-8") as fh:
            t = fh.read()
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "SubagentStart", "additionalContext": t}},
                         ensure_ascii=False))


HANDLERS = {"bash": h_bash, "edit": h_edit, "turn": h_turn, "stop": h_stop,
            "session": h_session, "subagent": h_subagent}

if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}
    if name in ("bash", "edit"):
        HANDLERS[name](data)
        sys.exit(0)
    try:
        HANDLERS[name](data)
    except Exception as e:
        print(f"hooks.py {name}: {type(e).__name__}: {e}", file=sys.stderr)
    sys.exit(0)
