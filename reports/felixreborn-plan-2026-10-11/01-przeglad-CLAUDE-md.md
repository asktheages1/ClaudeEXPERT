# FelixReborn — przegląd szkieletu CLAUDE.md względem bazy wiedzy i wkomponowanie planu KB

Data: 2026-10-11. Plik oceniany: `claude-felixReborn.md` (69 linii, ~11 KB). Baza: `knowledge/` tego repo (snapshot CC 2.1.289–2.1.291) + `findings.md` (do 2026-10-11, CC 2.1.296). Plan KB: `reports/kb-plan-2026-10-11/PLAN.md` v3.

Założenie zmienione przez właściciela 2026-10-11: **model zagrożeń to lenistwo, skróty, zaokrąglanie na własną korzyść, nieuwaga i zapominanie, nie bunt.** Skutek dla planu: zamiast `deny` na plikach bramek wystarczą reguły `ask` (tak jak szkielet już zakłada w l. 19), CI z `main` zostaje jako zapora na pomyłki, a cała warstwa „ochrona przed celowym obejściem" (fałszowanie logu, `--settings disableAllHooks`, drugi checkout) wypada z zakresu i zostaje tylko jako jedna linia w sekcji o granicach.

## 1. Werdykt

Szkielet jest dobry i zgodny z bazą w ~90 %: sekcja „Enforcement and its limits" powtarza O0 §8 i findings z 2026-10-11 bez przekłamań, reguły dla agentów (l. 43–48) pokrywają O0 §2–§3, tabela środowisk jest trafna. Trzy problemy strukturalne i kilkanaście drobnych:

1. **Plik opisuje jako istniejące ~15 mechanizmów, których nie ma** (hook SessionStart, `doc_check`, `tools/test_hooks.sh`, bramka push, reguły `deny`, agenci `reviewer`/`implementer`, skille `/<delivery>` i `/<health-check>`, `MAPA.md`, `STATUS.md`, `BACKLOG`, `FINDINGS`, `OWNER-RULES`, `EFFORT-RULES`, `TESTS.md`). Findings 2026-10-11 (recenzent szablonów): „a template must not describe hooks, agents or skills as existing (Claude then skips repeating rules in agent prompts)". Sam plik w l. 4–6 mówi, że mechanizm bez testu to rada, ale nie mówi, **które** z opisanych są dziś radą. Naprawa: nie przepisywać pliku na „kiedyś będzie", tylko dodać jedno zdanie w „Start of every session": „`STATUS.md` sekcja *Live mechanisms* wymienia, które bramki, hooki, agenci i skille z tego pliku istnieją i są przetestowane; wszystko spoza tej listy to na razie rada" — i `STATUS.md` z tą sekcją musi powstać w sesji 0 (prompt S00). Lista żyje w STATUS, nie tu, więc CLAUDE.md nie zmienia się przy każdym kroku.

2. **Warsztat/ i Gotowe/ nie działają dla mechanizmów, które muszą być w korzeniu.** Hooki działają tylko z `.claude/settings.json` w katalogu startu (O0 §4 [MEASURED]), zagnieżdżony `knowledge/CLAUDE.md` działa tylko pod `knowledge/` (O0 §2), CI tylko z `.github/`. Repo, które „tworzy samo siebie", musi mieć żywą konfigurację w korzeniu. Propozycja: **korzeń = żywy system** (to, co tu działa), `Gotowe/` = **eksport budowany skryptem** z korzenia (`tools/export_template.py`: kopiuje CLAUDE.md, `.claude/`, `tools/kb_*`, `tests/`, `knowledge/` do `Gotowe/`, więc nie mogą się rozjechać; CI sprawdza, że eksport = commit), `Warsztat/` = szkice, które jeszcze nie są żywe. Zmiana w l. 7: „Work in Warsztat/; only accepted work is promoted to Gotowe/" → „Drafts live in Warsztat/; what is live runs from the repository root; Gotowe/ is generated from the root by `tools/export_template.py` and never edited by hand".

3. **Bramki kosztowe w USD (l. 45) nie pasują do konta na subskrypcji.** Właściciel nie jest na API; ograniczeniem są limity tokenów współdzielone z kontem (O0 §7 [SOURCE: CC claude-code-on-the-web.md]) i czas. Naprawa: „One agent or probe: run it. Several agents (up to 15 per session), workflows, loops: say how many, which models and why, and how long it will take; the owner's yes. Cost is reported as tokens from the transcript, not USD."

## 2. Zgodność linia po linii (tylko miejsca do poprawy)

| Linia | Treść | Ocena | Dowód | Poprawka |
|---|---|---|---|---|
| 5 | mechanizm jest realny, gdy `tools/test_hooks.sh` pokazuje blokadę dummy, recenzent przeczytał, właściciel zmergował | zgodne z O0 §8, findings | — | dopisać: „and the Live mechanisms list in STATUS.md names it" |
| 19 | reguły `ask` na CLAUDE.md, settings, agents, hooks, rules, skills; nie `Edit(/.claude/**)` | zgodne; w chmurze oczekiwanie na zgodę = bezczynność, sesja może wygasnąć (O0 §7) | O0 §4, §7; findings 2026-10-11 [ASSUMPTION o worktree] | dopisać do „Environment / Cloud": „a pending `ask` prompt counts as inactivity"; zostawić `<verify …>` jako zadanie S08 |
| 22 | hook SessionStart drukuje wersję, gałąź vs `origin/main`, STATUS, health check | mechanizm nie istnieje; stdout SessionStart trafia do kontekstu (O2 §A5), limit 10 000 znaków (O2 §A6) | — | zostaje jako cel; S08 go buduje; do czasu: fallback z l. 22 („if it printed nothing…") jest poprawny |
| 23 | „markdown ≤ 40 KB fits one Read" | **nieaktualne**: w trybie auto Claude czyta przez `cat`, a Bash pokazuje inline ≤ ~30 000 znaków, dalej 2 KB podglądu | O1 §2; findings 2026-10-11 (P0, R0, n=2) | „≤ 28 KB for a file that must be read whole with `cat`; larger files only with the Read tool (25,000 tokens per call) or in parts, and say so" |
| 23 | `MAPA.md` §1 task → file | dwie mapy: MAPA (dokumenty projektu) i `knowledge/CLAUDE.md` (baza) | plan §5 | zdanie: „project docs: `MAPA.md` §1; the knowledge base: `knowledge/CLAUDE.md` (auto-loaded when any file in `knowledge/` is touched)" |
| 24 | `<kb>/O0-how-claude-works.md` | po kroku 0b O0 jest zaślepką | plan §3 | „`knowledge/CLAUDE.md` → the topic file; read it in full (the read gate, once built, checks that)" |
| 25 | reguły `paths:` ładują się przy Read/Edit/jednoplikowym `cat`/`sed -n`/`grep`; „edit only with the Edit tool" | zgodne (O0 §2 [CL 2.1.293]); od 2.1.288 Write/Edit też ładują | O0 §2 | bez zmian |
| 30 | recenzent read-only, widzi tylko diff | zgodne z O0 §3 (T3-38); read-only wymaga braku Bash/MCP/Agent (l. 47) | O0 §4 | `reviewer.md`: `tools: Read, Grep, Glob` i nic więcej; dopisać `model`, `effort` w definicji |
| 38 | cap 20 KB bez komentarzy HTML; reguły bez `paths:` liczą się | zgodne (O2 §D5; findings 2026-10-11 [CL 2.1.72]) | — | dopisać 28 KB dla plików czytanych przez `cat` (jak l. 23) |
| 44 | „If a SubagentStart hook injects `.claude/agent-rules.md`" | **zmierzone**: `additionalContext` z SubagentStart dociera także do Explore | findings 2026-10-11 (R6a, C, n=2) | zmienić tryb warunkowy na: „A SubagentStart hook injects `.claude/agent-rules.md` into every subagent, Explore included [MEASURED 2026-10-11]; workflow agents: repeat the rules in the prompt" (po zbudowaniu w S08) |
| 45 | progi w USD | niezgodne z kontem | O0 §7 | jak §1 pkt 3 |
| 46 | effort: `effortLevel` w user settings nie działa na Opus 5.5, zakres projektu niezweryfikowany | zgodne z O0 §5 | — | zadanie weryfikacji do S07 (sondy) |
| 48 | `worktree.baseRef: "head"`, commit przed agentem | zgodne | O0 §3 | bez zmian |
| 53 | klasyfikator może odmówić zmiany CLAUDE.md/`.claude/` | zgodne | findings 2026-10-06 | bez zmian |
| 59 | chmura: setup script lub SessionStart instaluje narzędzia | zgodne | O0 §7 | dopisać: „project hooks load only in a single-repository session started at the root" (jest w l. 65, OK) |
| 60 | PC: hooki wymagają `python3`; `onFailure: block` blokuje | zgodne | findings 2026-10-11 | dopisać: każdy hook zaczyna od `[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0` do czasu instalacji Pythona na PC |
| 65 | „The sandbox is off unless `sandbox.enabled`; in the cloud it is unverified" | **zmierzone**: w kontenerze nie ma `bwrap` | findings 2026-10-11 (audyt 2) | „in the cloud there is no `bwrap`, so the sandbox cannot be enabled there [MEASURED 2026-10-11]" |
| 66 | `disableAllHooks` w `settings.local.json` z zgodą właściciela | zgodne (O2 §A1: local > project) | — | bez zmian |
| 68 | health check co 90 dni | nie ma w nim świeżości bazy | plan §6 3e | dopisać: „`tools/kb_freshness.sh` at every SessionStart; a KB behind Claude Code by ≥ 3 versions is reported in the reply" |

## 3. Wkomponowanie planu KB (co dopisać, w której sekcji; łącznie ~2,5 KB, plik zostaje < 15 KB)

**Start of every session** (po l. 24):
- „Knowledge base: `knowledge/` holds topic files (`hooks.md`, `agents-and-workflows.md`, …), a map `knowledge/CLAUDE.md` (auto-loaded on the first touch of any file there) and `knowledge/STATE.md` (Claude Code version the base describes, the two models it covers). A question or task that names a topic in `knowledge/topics.json` requires reading that topic file in full in this session, after the last compaction; the read gate (`.claude/hooks/kb_*`) enforces it once live. Other models than the two in STATE.md appear only as `[scope: trap|component|why-not]` lines."

**Verification** (po l. 30):
- „The knowledge base and this file have a checker, `tools/kb_check.py` (size caps, headers, map coverage, `§` references, evidence tags, model scope); the push gate and CI run it. Hooks have a harness, `tools/test_hooks.sh`, fed with recorded payloads from `tests/fixtures/`; CI runs it. CI takes its workflow and the checker from `main` and treats the branch as data; a PR that changes `.claude/**`, `.github/**`, `tools/kb_*` or `knowledge/topics.json` is red until the owner has read it."

**State and documentation** (po l. 40):
- „`knowledge/STATE.md` and the generated sections of `knowledge/CLAUDE.md` come from `tools/kb_build.py`; never edit them by hand. KB facts newer than the base go to `docs/FINDINGS.md` first and are promoted by the next KB step."

**Agents and nested runs** (po l. 44):
- „Agents of type general-purpose and the named project agents are under the read gate: an agent whose prompt names a topic must read its file in full before its SubagentStop passes. Explore and `claude-code-guide` are not gated. Nested `claude -p` tests run from a separate checkout (`git worktree add /tmp/kbtest`), never from the root, so they do not trip the live gates or pollute the gate log."

**Enforcement and its limits** (po l. 65):
- „Threat model: the gates stop shortcuts, forgetting and favourable rounding, not deliberate circumvention; a session that wanted to could edit a hook from a Python script or run `claude -p --settings '{"disableAllHooks": true}'`. That is accepted: the backstop is CI from `main` and the owner's PR review. Gate files sit under `ask` rules, not `deny`, so an honest fix needs the owner's yes in the session."

**Health check** (l. 68): dopisek z tabeli.

## 3a. Uzupełnienia po recenzjach promptów (2026-10-11)
- Linia 15 („Work only inside this repository … plus the session scratchpad"): prompty trzymają tymczasowe checkouty i zdalne repozytorium testowe w scratchpadzie sesji, nie w `/tmp` — zgodne z linią, bez zmiany.
- Linia 18 (format odpowiedzi): obowiązuje; COMMON §5 jest jej podzbiorem.
- Linia 30 (`reviewer.md`): do S05 nie istnieje; para recenzentów z COMMON §4 (general-purpose z Bash) go zastępuje, a po S05 `reviewer.md` służy do przeglądu zmian kodu, nie do końcowej recenzji sesji (musi uruchamiać komendy).
- Linia 45 (progi w USD i zgoda na kilku agentów): bez decyzji właściciela dosłowne okno zatrzyma się przed każdą sesją z agentami, czekając na zgodę, a w chmurze oczekiwanie = bezczynność. Stąd warunek wstępny S00: dwie datowane decyzje w `docs/OWNER-RULES.md` (układ; agenci z promptu sesji są z góry zatwierdzeni, limit 15).
- `knowledge/FINDINGS-claudeexpert.md` nie może leżeć w `knowledge/` (strażnik uznałby go za plik treści: brak `As of:`, nazwy Haiku/Sonnet, brak tematu) → `docs/import/`.
- Lista „Known open conflicts" i legenda znaczników z CLAUDE.md tego repo nie trafiają do FelixReborn z samą kopią `knowledge/`: S01 importuje listę dosłownie (tekst jest w prompcie), COMMON §3 niesie legendę.

## 4. Rzeczy do decyzji właściciela przed S00

1. Układ repo: `knowledge/` i `tools/` w korzeniu, `Gotowe/` generowane skryptem (§1 pkt 2). Rekomendacja: tak; inaczej hooki i mapa nie zadziałają.
2. Czy `knowledge/` (ok. 140 KB) jest częścią szablonu kopiowanego do innych projektów, czy do innych projektów idzie tylko `design-rules.md` + mapa? Rekomendacja: całość do projektów, w których Claude projektuje mechanizmy (hooki, agenci); do zwykłych projektów tylko `design-rules.md` i `knowledge/CLAUDE.md` z odsyłaczem. Decyzja wpływa na `export_template.py` (S00 robi parametr).
3. Skąd `knowledge/` trafia do FelixReborn: ręczna kopia z `asktheages1/ClaudeEXPERT` (`knowledge/`, `findings.md` → `knowledge/FINDINGS-claudeexpert.md`) przed S00, czy S00 ma dołączyć to repo (`add_repo`) i skopiować. Rekomendacja: kopia ręczna (sesja z dwoma repozytoriami nie ładuje hooków, O0 §7; S00 ich jeszcze nie ma, więc technicznie można, ale prościej mieć jedno repo od początku). S00 sprawdza obecność i zatrzymuje się, jeśli brak.
4. Placeholdery `<…>` w szkielecie (język UI, skille, model/effort, polityka merge A/B, następny krok A/B, zip): S00 nie zgaduje; prompt S00 każe wypisać listę brakujących decyzji w `STATUS.md` i w odpowiedzi.
5. Czy FelixReborn jest publiczne (branch protection za darmo) czy prywatne (płatny plan)? S00 sprawdza to przez API i zapisuje.
6. Zakres bramki push: blokować każdy push z czerwonym strażnikiem (ryzyko: praca uwięziona w jednorazowej VM), czy tylko push do `main`, a gałęzie ostrzegać? Domyślnie w promptach: blokada z wyjątkiem gałęzi `wip/*`.
7. Sesje bazowe: 2–3 zwykłe sesje pytań między S11 a S12a, żeby liczba „odpowiedzi bez czytania" pochodziła z właściwej populacji? Rekomendacja: tak.
8. Linie o Opus 5 / Fable 5 (poprzednicy; jedyna podstawa części rad dla Opus 5.5): zostają ze znacznikiem `[scope: predecessor-advice]` (rekomendacja) czy wypadają?
