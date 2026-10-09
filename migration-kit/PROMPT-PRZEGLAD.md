# Health check of the documentation system (any project migrated with plan v5)

Run when the session-start line says „przegląd zaległy”, after a model change, or monthly if the owner chose the
scheduled check (owner rule in `CLAUDE.md`). Read-only except STATUS and BACKLOG.

```
USTAW PRZED WKLEJENIEM
Model: Opus 5.5 (nie Fable) · wysiłek: high · workflow: nie (bez agentów)
Start: nowa sesja z samym repozytorium projektu, tryb Auto
Pierwsza wiadomość: /przeglad   (skill zainstalowany przez migrację)
Szacunek: 3–8 USD, 15 min. Wynik: krótka lista w STATUS i jedna linia w odpowiedzi.
```

## Checks (each: command → result → OK / finding)
1. K1: `claude -p "/context" --model opus --effort high --permission-mode default --max-turns 1 --max-budget-usd 0.5`
   in the repo root → project instructions ≤ 8k tokens. K2 = K1 + every `paths` rule matching the main code file,
   measured by import in a scratch dir → ≤ 25k.
2. New or changed instruction sources since the SHA in the STATUS line „Ostatni przegląd: <date> <SHA>”:
   `git diff --name-status <SHA> -- '*CLAUDE.md' '*AGENTS.md' '*CLAUDE.local.md' .claude/rules .claude/skills
   .claude/agents .claude/commands`; any nested `CLAUDE.md` or unscoped rule > 5 KB is a finding.
3. Doc gate green; navigation sizes current.
4. Growth: every doc file whose size grew > 20 % since the last check (`git diff --stat <last-check-SHA> --
   '*.md'`) → read its new parts: appended layers („vX: …” paragraphs, „newer supersedes older”) instead of a rewrite
   are a finding.
5. CHANGELOG: version lines newest first under `## Versions (newest first)`; nothing after the list except „Paczki”.
6. STATUS ≤ 6 KB and current (last session, next task); BACKLOG has no items closed elsewhere.
7. Leftovers: `git grep -nE 'Moved verbatim|ZAMROZONE|KONKORDANCJA|/kondensacja' -- ':!*CHANGELOG.md' ':!.claude/skills/przeglad' ':!*ZASADY-UZYTKOWNIKA.md' ':!*.zip'` → empty.
8. After a model change: bytes per token by import of one doc file per language; if it moved > 10 %, recompute the byte caps
   in the doc gate script (rule cap = (25k − K1) × bytes/token) and note it.
9. `/doctor prompt-audit` is a command for the owner: if the last one is > 3 months old, add it to „Następny krok”.

## Output
STATUS: replace the line „Ostatni przegląd: …” with „Ostatni przegląd: <today> <HEAD SHA>”. Findings → BACKLOG items (one line each, with the command that shows them). Commit, push, merge as the
project's rules say.

## Final reply (Polish, ≤ 6 lines + the standard ending)
„Przegląd: X/9 OK”; the findings in one line each; cost; „Zmiany w tej odpowiedzi”; „Następny krok”.
