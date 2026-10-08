# Plan migracji systemu dokumentacji Foldery

Wersja: **4.1** (poprawki S4/S5 z recenzji zasad ogólnych; wcześniej: po dwóch rundach recenzji „meta” (M1–M15, N1–N8, Załącznik R) i po niezależnej recenzji technicznej (T1–T13, Załącznik T)) · 2026-10-08 · podstawa: `reports/foldery-analysis.md` (dalej „Raport”), Foldery `main` @ `be31a48`.
Słowniczek pojęć: Raport, początek pliku.

## 0. Idea w trzech zdaniach

1. **Etap A** to jedna sesja wykonująca mechaniczną, bezstratną przebudowę: tekst przenosi skrypt według zakresów linii, a każda stara linia ląduje dokładnie w jednym nowym pliku (sprawdzalne w 100%). Do tego dochodzą nowy krótki `CLAUDE.md`, nowy strażnik `doc_check`, hooki, agenci i skille.
2. Sam etap A daje cały zysk ładowania (kontekst ~240k → ~5k na starcie i ~18k przy pracy z kodem), bo wynika on z tego, *gdzie* tekst leży, a nie z tego, jak jest napisany.
3. **Etap B** to kondensacja „do stanu obecnego”, robiona po jednym obszarze naraz przy okazji normalnej pracy w danym obszarze, z recenzentem. Ryzyko utraty wiedzy rozkłada się wtedy na małe, sprawdzalne zmiany.

## 1. Kryteria sukcesu (mierzalne)

| # | Kryterium | Jak sprawdzić | Dziś |
|---|---|---|---|
| K1 | Instrukcje projektu na starcie sesji ≤ 8k tokenów | `/context` → Memory files + wynik SessionStart | 0 na starcie, 239,9k po pierwszym Read |
| K2 | Instrukcje po pierwszym Read `galeria.py` ≤ 25k tokenów | `/context` po Read `galeria.py` z `limit` | 239,9k |
| K3 | Każdy plik w `dokumentacja/` i `MAPA.md` ≤ 40 KB (≈ ≤ 20k tok., jeden Read) | `doc_check` (bajty) + pomiar `/context` próbki | MAPA 29,4k, USUWANIE 44,8k tok. |
| K4 | Etap A bezstratny: każda linia starego CLAUDE.md i MAPA §9 jest w dokładnie jednym miejscu docelowym | skrypt konkordancji (A3.3) = 100%, `diff` dla kopii dosłownych | — |
| K5 | Blokowane przez program: force-push, push na `main` przy czerwonym `doc_check`, trigger `push:` w CI, edycja `backup/`, zapis plików przez narzędzia GitHub MCP | prowokacje A6 (`--dry-run`) | 0 blokad |
| K6 | `./tools/testy.sh` zielone (poza znanym czerwonym „v4.18.5: siatka gruba i mocna”) | testy | zielone |
| K7 | Test mutacyjny `doc_check` w `test_logic` przechodzi na nowym układzie | `test_logic` | jest, na starym |

## 2. Decyzje właściciela przed startem

| # | Pytanie | Rekomendacja |
|---|---|---|
| D1 | Zgoda na etap A (przeniesienie, nowy `doc_check`, hooki) | **Tak** |
| D2 | Czy zip ma zawierać nowy `/CLAUDE.md` (leży poza `GaleriaFolderow/`) | **Nie.** Zip jest dla Twojego Windowsa, Claude pracuje z gita (MAPA §0). Reguła „always re-add CLAUDE.md to the zip” (stary §2) do usunięcia |
| D3 | Archiwum starego CLAUDE.md w `/archiwum/CLAUDE-do-v4.37.9.md` (korzeń repo, poza zipem i poza `GaleriaFolderow/`; nazwa ≠ `CLAUDE.md`, więc nie ładuje się samo); usunięte po zakończeniu etapu B (zostaje w historii git) | **Tak** |
| D4 | Backupy → tagi git | **Osobna sprawa, nie w tej migracji** |
| D5 | CI `doc_check` na push | **Nie** (limit minut Actions); zastępuje go hook przed pushem na `main` |
| D6 | Branch protection `main` | **Nie teraz** (prywatne repo = płatny plan, O0 §7) |
| D7 | Wyjątek od reguły „scalaj z `main` po każdej pracy”: etap A scalany raz, po A6 (odbiór w sesji migracji), a nie po każdej fazie | **Tak** (pół migracji na `main` zostawiłoby następnym sesjom niespójny system) |
| D8 | Plan trafia do Foldery jako `/MIGRACJA/PLAN-MIGRACJI.md` **w korzeniu repo** (poza `GaleriaFolderow/`, żeby jego przeczytanie nie wczytało starego CLAUDE.md). Wgrywasz go sam albo pozwalasz mi go tam wypchnąć. Folder `/MIGRACJA/` usuwany na końcu etapu A | **Tak** |

## 3. Wykonawca, model, koszt, czas (etap A)

```
USTAW PRZED WKLEJENIEM
Model: Opus 5.5 · wysiłek: high · workflow: nie (1 recenzent na końcu, narzędzie Agent)
Start: claude --model opus --effort high
Uzasadnienie: praca mechaniczna, ale z wieloma zależnymi krokami i twardą weryfikacją; podział na agentów niepotrzebny.
```
Prompt startowy dla sesji Foldery (wklejasz po ustawieniu):
> Wykonaj `MIGRACJA/PLAN-MIGRACJI.md`, etap A, w podanej kolejności. Pierwsze polecenia sesji to kroki A0.1–A0.2, przed otwarciem jakiegokolwiek pliku w `GaleriaFolderow/`.

- Szacunek: **~10–25 USD w cenniku API, 2–4 h** [ASSUMPTION]. Bez agentów-redaktorów, a stary CLAUDE.md nie ładuje się nikomu dzięki A0.2 (uwaga M8). Większość kosztu to odczyt archiwum przy przypisywaniu zakresów (A2): przypisywać po liście lead-inów z rozmiarami, nie czytając całości. Koszt zmierzyć z transkryptu po A2 (uwaga recenzenta technicznego).
- Program bez zmian: `APP_VERSION` 4.37.9, ta sama nazwa paczki (reguła „docs nie zmieniają wersji”).

## 4. Etap A: fazy

Każda faza kończy się commitem i **pushem gałęzi sesji** (praca w chmurze ginie bez pushu, O0 §7). Postęp idzie do `/MIGRACJA/POSTEP.md` po każdej fazie: plik przeżywa kompaktowanie, rozmowa nie (O0 §8).

### A0. Przygotowanie (kolejność kroków 1–2 wiążąca, N3)
1. `git fetch origin main && git merge --ff-only origin/main`, a SHA `main` zapisz w POSTEP.md (potrzebne do wycofania, §7). Fetch i merge nie otwierają plików przez Read ani `cat`, więc nie ładują zagnieżdżonego CLAUDE.md [ASSUMPTION; sprawdza to `/context` w kroku 2].
2. **Zanim cokolwiek w `GaleriaFolderow/` zostanie otwarte:** `mkdir -p archiwum && git mv GaleriaFolderow/CLAUDE.md archiwum/CLAUDE-do-v4.37.9.md`. `git mv` to nie `cat`/`head`, które ładują zagnieżdżony plik (Raport B5/B6). Od tej chwili źródłem jest archiwum, czytane Readem z `offset/limit` lub przez `sed -n`.
   **Sprawdzenie (T3)**: wykonawca nie może sam wpisać `/context`, bo to polecenie dla człowieka, a zagnieżdżony CLAUDE.md i tak nie pojawia się na liście Memory files. Sprawdza więc programowo: `grep -c 'GaleriaFolderow/CLAUDE.md' ~/.claude/projects/*/"$CLAUDE_CODE_SESSION_ID"*.jsonl` (lub najnowszy `.jsonl` projektu) po `git mv` **i ponownie po pierwszym Read pliku z `GaleriaFolderow/`**. Szuka wpisu `nested_memory` z tą ścieżką; oczekiwane 0 (metoda: Raport B4/B5). Gdyby się wczytał, praca dalej działa, tylko drożej; zapisz w POSTEP.md. Opcjonalnie Ty wpisujesz `/context` i podajesz sumę.
3. Pomiar bazowy (Raport §5): `claude -p "/context" --model opus --effort medium --permission-mode default --max-turns 1 --max-budget-usd 0.5` uruchomione w katalogu poza repo z `CLAUDE.md` importującym mierzone pliki. Wykonawca może to zrobić sam przez Bash (0 USD).
4. Sprawdzenie odwołań w kodzie: `grep -n 'CLAUDE.md\|§[0-9]' GaleriaFolderow/galeria.py GaleriaFolderow/tests/*.py GaleriaFolderow/tools/*` → lista w POSTEP.md (np. `test_logic.py:2258` „(§5.5)”).
5. `doc_check` jest od teraz czerwony na gałęzi (brak `GaleriaFolderow/CLAUDE.md`). To akceptowalne, bo nic nie jest scalane przed A6.

### A1. Infrastruktura
- `.gitignore`: usunąć `.claude/`, dodać `.claude/worktrees/` i `.claude/settings.local.json`.
- `.gitattributes`: `*.sh text eol=lf` i `*.py text eol=lf` dla `.claude/hooks/`. Skrypt hooka z końcówkami CRLF (np. wgrany z Windowsa) kończy się kodem 2, czyli **blokuje każde wywołanie Bash** [MEASURED n=1: recenzent-sceptyk E4]. Wcześniej `git status --ignored`: czy nie wypłynie przypadkowy `.claude/`.

### A2. Mapa przeniesień (konkordancja)
1. Skrypt (scratchpad, nie repo) listuje akapity archiwum: nr linii, pierwsze 90 znaków lead-inu `**…**`, rozmiar.
2. Sesja przypisuje **każdy zakres linii** do jednego pliku docelowego i zapisuje to w `GaleriaFolderow/dokumentacja/migracja/KONKORDANCJA.tsv` (`start	koniec	stary_§	plik_docelowy`). Plik zostaje w repo na stałe: stary § → nowy plik.
3. Docelowe pliki (wszystkie **kopie dosłowne**, kolejność akapitów zachowana):

| Źródło (archiwum) | Cel | Limit |
|---|---|---|
| nagłówek (l. 1–14) | tylko archiwum (w KONKORDANCJA.tsv: „zastąpione nowym `/CLAUDE.md`”) | — |
| §1 Zasady (l. 15–45) | `GaleriaFolderow/dokumentacja/ZASADY-UZYTKOWNIKA.md` dosłownie, z nagłówkiem „brzmienie oryginalne z datami i cytatami; **obowiązujące brzmienie: `/CLAUDE.md`**”. Nowy `/CLAUDE.md` streszcza obecnie obowiązujące reguły (po polsku, uwagi przed wdrożeniem, scalanie, nazwa zipa, „Zmiany…”, bez komentarzy, uczciwość co do nieuruchomionego, dokumentacja w tej samej sesji według nowego układu) i odsyła do tego pliku. Dosłowne wklejenie §1 do CLAUDE.md odrzucone (N1): wniosłoby do pliku ładowanego wszystkim nieaktualne polecenia („wpis w §4/§8”, „MAPA §9”, „single source of truth”) | 40 KB |
| §2 Pliki | `GaleriaFolderow/dokumentacja/PLIKI.md` | 40 KB |
| §3 Środowisko i weryfikacja | `GaleriaFolderow/dokumentacja/SRODOWISKO-TESTY.md`; w `/CLAUDE.md` 6-linijkowy protokół weryfikacji (test najpierw, `testy.sh`, recenzent dla zmian GUI, „powiedz, czego nie uruchomiłeś”) jako reguła obowiązująca; szczegóły w pliku (uwaga M13) | 40 KB |
| §4 Architektura | `GaleriaFolderow/dokumentacja/architektura/<obszar>.md` według obszarów z MAPA §1 (np. `operacje-plikow`, `panele-katalog`, `przegladarka-wideo`, `przycinanie-edycja`, `sortowanie` (Litery/Osoby/Strzałki/Boksy), `wyszukiwarka-zakladki`, `montaz-hybryda`, `okno-adresu-kadr-filmu`, `watki-tlo-diagnostyka`, `ai-wskazniki`); plik > 40 KB → `-1`, `-2` | 40 KB |
| §5 Specyfikacja | `GaleriaFolderow/dokumentacja/spec/SPEC-A.md`, `SPEC-B.md` podzielone na granicy numeru punktu; **numeracja „5.N” zostaje** (stabilne identyfikatory, M6) | 40 KB |
| §6 Niezmienniki | `/.claude/rules/galeria-niezmienniki.md` z frontmatterem `paths: ["**/GaleriaFolderow/galeria.py"]` (`**/` także dla kopii w `.claude/worktrees/…`, T12) + treść dosłownie (30,2 KB) | 36 KB (T11) |
| §7 Ograniczenia | `GaleriaFolderow/dokumentacja/OGRANICZENIA.md` | 40 KB |
| MAPA.md (całość przed zmianą) i EFFORT-ZASADY.md (całość) | `/archiwum/MAPA-do-v4.37.9.md`, `/archiwum/EFFORT-ZASADY-do-v4.37.9.md` (kopie `cp`, źródło dla treści przepisanej do `/dostawa` i `/przekazanie`, T9c) | — |
| §8 Changelog | `GaleriaFolderow/CHANGELOG.md` | bez limitu (grep) |
| §9 Backlog | `GaleriaFolderow/dokumentacja/BACKLOG.md` | 40 KB |
| MAPA §9 Status (historia) | `GaleriaFolderow/CHANGELOG.md`, sekcja „Status log (dawne MAPA §9)” | — |
| `dokumentacja/ai/USUWANIE-OBIEKTOW.md` (85 KB) | podział na granicach `##`: [§1] [§2] [§3–§8 ≈ 35 KB] (§2+§3 razem przekraczają 40 KB, T recenzja C5); `ai/README.md` jako indeks | 40 KB |

### A3. Przeniesienie i dowód bezstratności
1. Kopiowanie **tylko skryptem** (`sed -n 'a,bp'` / Python według KONKORDANCJA.tsv), nigdy przepisywaniem przez model (M9).
2. Każdy plik docelowy dostaje 2-liniowy nagłówek: obszar, „przeniesione dosłownie z CLAUDE.md v4.37.9; akapity od najnowszego, nowszy zastępuje starszy; plik do kondensacji w etapie B; **przy sprzeczności obowiązują `/CLAUDE.md` i skill `/dostawa`**” (T10: pliki dosłowne zawierają nieaktualne polecenia, np. „always re-add CLAUDE.md to the zip”, „§4 new paragraph at the TOP”).
3. **Skrypt konkordancji** (`/MIGRACJA/konkordancja.py`, **commitowany**, bo scratchpad ginie przy odzyskaniu maszyny, T9b):
   - zakresy w KONKORDANCJA.tsv pokrywają linie 1–4711 archiwum dokładnie, bez luk i nakładek (T9a);
   - multizbiór linii archiwum (bez linii-nagłówków `## N.`) = suma multizbiorów linii przeniesionych do plików docelowych plus linie oznaczone w KONKORDANCJA.tsv jako „tylko archiwum” (nagłówek l. 1–14), bez dodanych nagłówków i bez nowej treści CLAUDE.md;
   - wynik 100% albo lista różnic do wyjaśnienia;
   - to samo dla MAPA §9 i podziału USUWANIE;
   - **uruchamiany na commicie zrobionym zaraz po A3.2, zanim A3.4/A4 zmienią przeniesione linie (N2)**; SHA tego commita i wynik zapisz w POSTEP.md; późniejsze sprawdzenia (A6.4, recenzent) liczą konkordancję względem tego SHA (`git show <sha>:<plik>`), a nie względem bieżących plików.
4. Kontrola § (M6): `grep -rn '§[0-9]' GaleriaFolderow .claude CLAUDE.md` (z pominięciem `dokumentacja/ZASADY-UZYTKOWNIKA.md`, który zostaje w brzmieniu oryginalnym; do jego nagłówka dopisać legendę „stary § → nowy plik” z KONKORDANCJA.tsv) → każde odwołanie do starych sekcji zamienić na ścieżkę pliku (np. „CLAUDE.md §6” → „`.claude/rules/galeria-niezmienniki.md`”). Odwołania „§5.N” zostają, bo numery są stabilne; do nich dopisać plik `spec/SPEC-A|B.md`. Odwołania w testach z listy A0.4 też poprawić.

### A4. Nowe pliki nawigacji i strażnik (w **jednym commicie**)
1. **`/CLAUDE.md`** (szkic: Raport §6, z poprawkami):
   - zasady użytkownika: aktualne brzmienie, krótko, z odsyłaczem do `dokumentacja/ZASADY-UZYTKOWNIKA.md` (A2, N1);
   - protokół weryfikacji (A2, §3);
   - start sesji (hook wypisuje stan);
   - nawigacja: „szukasz wiedzy → `GaleriaFolderow/MAPA.md` §1”;
   - reguły pisania dokumentacji (§8 tego planu);
   - archiwum: „tylko historia, przez grep, nie źródło prawdy”;
   - znane ograniczenie: hooki są skryptami bash, więc lokalnie na Windowsie bez Git Bash nie działają;
   - cel ≤ 11 KB.
2. **`GaleriaFolderow/STATUS.md`** ≤ 6 KB (nadpisywany): wersja, zrobione ostatnio, otwarte, następne zadanie, decyzje czekające na właściciela.
3. **`MAPA.md`**:
   - §0 bez zmian;
   - §1 = tabela zadanie → plik z adnotacją rozmiaru w KB, np. „(28 KB)”, sprawdzaną przez `doc_check` (M7a);
   - §2 bez zmian;
   - §3 (checklista dostawy) → jedna linia „procedura: skill `/dostawa`” (M12);
   - §4 code map z nagłówkiem o stałym formacie `## 4. Code map (snapshot vX.Y.Z)`, bez historii (M7b);
   - §5–§8 bez zmian;
   - §9 usunięty (→ STATUS.md, CHANGELOG);
   - cel ≤ 40 KB (§0–§8 bez §9 ≈ 41 KB, minus §3 i nagłówek §4 ≈ 35 KB [ASSUMPTION z pomiaru recenzenta]).
4. **EFFORT-ZASADY.md**: §6 pkt 10 → jedna linia z odsyłaczem do `/CLAUDE.md` (M12); §5 → skill `/przekazanie` (A5), w pliku linia z odsyłaczem.
5. **`tools/doc_check.py` v2.** Wszystkie odczyty idą przez `read()`, a rozmiary to `len(read(x).encode())`, bo test mutacyjny podmienia `read`.
   1. Wersja `{ver}`:
      - `CHANGELOG.md` ma linię `- v{ver}` lub `- **v{ver}`;
      - `STATUS.md` zawiera `v{ver}`;
      - nagłówek MAPA `## 4. Code map (snapshot v{ver})` (dokładny format, linia ≤ 60 znaków);
      - README linia 1 `(wersja {ver})`.
      - **Bez** wymogu wpisu w architekturze (to on napędzał narastanie).
   2. Limity bajtów:
      - `../CLAUDE.md` ≤ 11 000;
      - `../.claude/rules/*.md` ≤ 36 000 (T11);
      - `../.claude/agent-rules.md` ≤ 9 000 znaków (limit `additionalContext` 10 000, T11);
      - `MAPA.md` ≤ 40 000;
      - `STATUS.md` ≤ 6 000;
      - każdy `dokumentacja/**/*.md` ≤ 40 000 (poza `migracja/`).
   3. Adnotacje „(N KB)” w MAPA §1 w pełnych KB, zgodne z rzeczywistym rozmiarem z tolerancją max(10%, 1 KB) (N7).
   4. Martwe odsyłacze: ścieżki w backtickach w MAPA §1 i `../CLAUDE.md` z końcówką `.md|.py|.sh|.bat|.txt|.tsv` istnieją.
   5. `GaleriaFolderow/CLAUDE.md` nie istnieje albo ma ≤ 2 000 B (zakaz powrotu wielkiego pliku).
   6. `../.github/workflows/*.yml`: klucze pod `on:` (forma blokowa i inline, np. `on: push`, `on: [push, workflow_dispatch]`) to **wyłącznie** `workflow_dispatch` (lista dozwolonych, nie zakazanych: łapie też `schedule`, `workflow_run`, `pull_request_target`, T8). Wszystkie odczyty przez `read(<dokładna ścieżka względna>)`, a katalogi listuje `os` (wzorzec testu mutacyjnego).
   7. Pliki z nagłówkiem „stan: skondensowany” (etap B) nie zawierają lead-inów `**v4.` (M7c).
   8. Każdy plik `dokumentacja/architektura/*.md` i `dokumentacja/spec/*.md`, którego nie ma w `KONKORDANCJA.tsv` (czyli nowy po migracji), musi mieć nagłówek „stan: skondensowany”. `doc_check` wypisuje (bez błędu) liczbę plików jeszcze nieskondensowanych, a STATUS.md je wymienia (N8).
   10. Żaden plik w `../.claude/hooks/` nie zawiera znaku `\r` (CRLF), a definicje `../.claude/agents/*.md` i `../.claude/skills/*/SKILL.md` mają `---` w linii 1 oraz pole `name` (agenci) i `description`. Literówka w polu jest ignorowana bez komunikatu, a plik bez `name` jest pomijany (O0 §4, O2 §B1).
   9. `../.claude/rules/galeria-niezmienniki.md` zaczyna się od `---` w linii 1, zawiera `paths:` z `GaleriaFolderow/galeria.py` i zamykające `---`. Zepsuty YAML sprawiłby, że reguła (~15k tok.) ładowałaby się w każdej sesji na starcie [SOURCE: CC memory.md, „Rule frontmatter reference”] (N6).
6. **`tests/test_logic.py`**, blok „v47+ dokumentacja” (~l. 10433–10454):
   - mutacja wersji 9.99.9 musi dać komunikaty z `CHANGELOG`, `STATUS`, `MAPA.md §4`, `README` (`len ≥ 4`);
   - nowe mutacje: fałszywy `../CLAUDE.md` 12 000 B → błąd limitu; MAPA §1 z nieistniejącą ścieżką → błąd odsyłacza; workflow z `push:` → błąd CI.
   
   Test `ast`/źródeł zakazujących napisów sprawdzić grep-em przed zmianą komunikatów (MAPA §7).
7. `./tools/testy.sh logic` zielone (+ pełne `testy.sh` przed A6).

### A5. Hooki, ustawienia, agenci, skille
Szkice: Raport §6. Poniżej różnice, które obowiązują (po recenzji technicznej T1–T8, T11).

**Wywołanie hooków (T2):** zawsze przez interpreter, nie przez bit wykonywalności:
- `"command": "bash", "args": ["${CLAUDE_PROJECT_DIR}/.claude/hooks/X.sh"]`;
- `"command": "python3", "args": ["-I", "${CLAUDE_PROJECT_DIR}/.claude/hooks/guard_bash.py"]`.

Plik wgrany przez GitHub „Add files” ma tryb 100644, a hook, który nie może wystartować, to błąd nieblokujący: akcja przechodzi i strażnik jest wyłączony [SOURCE: CC hooks part3 „Other exit codes”].

**`.claude/settings.json` → `permissions.deny`:**
- `Bash(git push --force*)`, `Bash(git push -f*)`, `Bash(git push * --force*)`, `Bash(git push * -f*)`: pierwsza warstwa; właściwą robotę robi `guard_bash.py`;
- narzędzia zapisu GitHub MCP, które omijałyby hooki na Bash (M15, T7): `mcp__github__push_files`, `mcp__github__create_or_update_file`, `mcp__github__delete_file`, `mcp__github__merge_pull_request`, `mcp__github__enable_pr_auto_merge`, `mcp__github__update_pull_request_branch`, `mcp__github__actions_run_trigger` (zużywa minuty Actions);
- `Bash(gh pr merge*)`, `Bash(gh api *merge*)`. To dopasowanie tekstu, więc miękkie (O0 §4); `gh pr` i tak odrzuca proxy chmury (GraphQL) [SOURCE: CC cloud-environments part2 „GitHub proxy”];
- **bez** deny na `backup/` i na zip (T6): reguła Edit/Read działa też na rozpoznane polecenia Bash, więc mogłaby zablokować `cp galeria.py backup/…` z procedury dostawy i `unzip -l`. Ochrona `backup/` przechodzi do `guard-edit.sh` (tylko narzędzia Edit/Write).

**`hooks`:**
- SessionStart `startup|resume|compact` → `session-start.sh`;
- UserPromptSubmit → `turn-baseline.sh`;
- SubagentStart → `subagent-start.sh`;
- PreToolUse `Bash` → `guard_bash.py` (`timeout: 120`);
- PreToolUse `Edit|Write` → `guard-edit.sh`;
- Stop → `stop-check.sh`.

**`guard_bash.py`** (T1): tekst i 22 przypadki testowe w **Załączniku S**. Działanie:
- rozbija polecenie na podpolecenia (`;`, `&`, `|`, nowa linia) przez `shlex`, pomija prefiksy `VAR=` i opcje globalne git;
- działa tylko na `git push` oraz `filter-branch`/`filter-repo`;
- force = opcja `--force…`/`--mirror`, klaster `-…f…` albo refspec z `+`;
- push na `main` = refspec `(^|:)(refs/heads/)?main$`, `--all`, albo brak refspec przy bieżącej gałęzi `main` lub po wcześniejszym `checkout/switch main` w tym samym poleceniu (to wzorzec scalania z MAPA §3);
- push na `main` uruchamia `doc_check` i przy czerwonym blokuje (exit 2); push gałęzi sesji przechodzi zawsze.

Przypadki zmierzone przez recenzenta: 22/22. Sprawdzone ponownie przeze mnie: 8/8 [MEASURED: `jq … | python3 -I guard_bash.py` w repo testowym, 2026-10-08].

**Stan tury (T5), wspólny dla `turn-baseline.sh` i `stop-check.sh`, uruchamiany w korzeniu repo:**
```bash
{ git rev-parse HEAD; git status --porcelain=v1 -z --untracked-files=all; git diff HEAD --binary; git ls-files -o --exclude-standard -z | xargs -0r sha1sum; } 2>/dev/null | sha1sum
```
Sam `git status --porcelain` nie wykrywa ponownej edycji pliku już zmienionego [MEASURED przez recenzenta, repo testowe].

**`turn-baseline.sh`** (M4, N5): zapisuje ten hash do `${TMPDIR:-/tmp}/foldery-turn-<session_id>`. **Nie wypisuje nic na stdout**, bo zwykły stdout hooka UserPromptSubmit trafia do kontekstu [SOURCE: O2 §A6]. Limit 30 s [SOURCE: O2 §A2].

**`stop-check.sh`:**
- liczy hash ponownie; gdy różni się od bazy tury, a `last_assistant_message` nie zawiera „Zmiany w tej odpowiedzi”, zwraca `hookSpecificOutput.additionalContext` z przypomnieniem, zamiast `decision: "block"`. Ochrona przed pętlą jest ta sama (`stop_hook_active`, limit 8), ale w transkrypcie widać „Stop hook feedback” zamiast błędu [SOURCE: CC hooks part7];
- brak pliku bazy = nic nie robi;
- bez wymuszania `doc_check` i scalania.

**`guard-edit.sh`:**
- (a) workflow: dozwolony tylko `workflow_dispatch` pod `on:` (forma blokowa i inline, T8);
- (b) ścieżka zawierająca `/GaleriaFolderow/backup/` → exit 2 (zastępuje deny, T6).

**`session-start.sh`:** jak w Raporcie §6 + przypomnienie, gdy gałąź ma commity nie scalone z `main`.

**`subagent-start.sh` + `.claude/agent-rules.md`** (≤ 9 000 znaków, pilnuje `doc_check`): jak w Raporcie §6.

**Agenci i skille:**
- `.claude/agents/recenzent.md` (Read, Grep, Glob; `model: opus`, `effort: high`);
- `.claude/agents/wykonawca.md` (`isolation: worktree`, `disallowedTools: Agent`, `model: opus`, `effort: high`, w treści: „przed uruchomieniem wykonawców: commit + push + scalenie albo `worktree.baseRef: "head"`”);
- `.claude/skills/dostawa/SKILL.md` = dawna MAPA §3 jako kroki (źródło jedyne, M12; oryginał w `/archiwum/MAPA-do-v4.37.9.md`). Gdyby `cp` do `backup/` było blokowane (prowokacja A6), backup przez `python3 -c "import shutil; …"`;
- `.claude/skills/przekazanie/SKILL.md` = dawne EFFORT-ZASADY §5 + szablon promptu.

**Testy:** każdy hook przed commitem testowany JSON-em na stdin (przypadek dozwolony i blokowany), `guard_bash.py` wszystkimi 22 przypadkami z Załącznika S.

**Gdy klasyfikator odrzuca zapisy w `.claude/`** (chroniona ścieżka, „Self-Modification”, M11): gotowe pliki trafiają do `/MIGRACJA/staging/.claude/…`, a Ty przenosisz je jednym commitem na GitHubie (Add files) albo zatwierdzasz w sesji. Tryb pliku nie ma znaczenia dzięki T2.

### A6. Odbiór w sesji migracji (przed scaleniem)
Hooki i ustawienia działają w trwającej sesji po zapisaniu pliku, także gdy `.claude/` powstał w trakcie (≥ 2.1.257) [SOURCE: CC debug-your-config.md]. Nowy CLAUDE.md i agenci działają dopiero w nowej sesji (O0 §2, §3). Polecenia `/hooks`, `/permissions`, `/context` wpisuje człowiek, więc wykonawca sprawdza działanie przez skutki (T3):
1. **Prowokacje wyłącznie z `--dry-run`** (M3), żeby w razie błędu hooka nic nie wyszło na serwer:
   - `git push --dry-run --force origin HEAD` → blokada;
   - `git push --dry-run origin HEAD:main` przy celowo zepsutym STATUS.md → blokada (potem przywrócić);
   - `git push --dry-run origin HEAD` przy czerwonym `doc_check` → przechodzi;
   - Edit workflow dodający `on: push` → blokada;
   - Edit pliku w `backup/` → blokada;
   - `cp GaleriaFolderow/galeria.py GaleriaFolderow/backup/_probe.py` → **musi przejść** (T6), potem usunąć plik;
   - narzędzie `mcp__github__push_files` **nie występuje** na liście narzędzi sesji (deny z gołą nazwą usuwa narzędzie z kontekstu [SOURCE: O2 §D4]); nie wywoływać go (N4);
   - odpowiedź bez „Zmiany…” po zmianie pliku → jedno przypomnienie;
   - pytanie bez zmian w tej turze → bez przypomnienia;
   - druga edycja już zmienionego pliku → przypomnienie (T5).
2. Read `GaleriaFolderow/galeria.py` (`limit: 50`) → komunikat „Loaded … galeria-niezmienniki.md”. Jeśli reguła utworzona w trakcie sesji się nie wczyta, rozstrzyga A7.2.
3. `./tools/testy.sh` (K6, K7), konkordancja 100% względem SHA z A3.3 (K4), `doc_check` (K3).
4. **Recenzent** (general-purpose, model opus, tylko odczyt): sprawdza konkordancję, nowy CLAUDE.md, MAPA, `doc_check`, hooki i treść agent-rules. Każde istotne znalezisko: poprawka albo odrzucenie z dowodem.
5. Scalenie do `main` według reguły scalania (zanotować SHA przed i po). **Jeśli klasyfikator odrzuci scalenie** (zmiana `/CLAUDE.md` i `.claude/` = „Self-Modification”, findings.md 2026-10-06, n=2; T4):
   - sesja uruchamia `doc_check` i `testy.sh`, wypycha gałąź i otwiera PR (`create_pull_request`, którego plan nie blokuje);
   - Ty scalasz na GitHubie;
   - to samo czeka każdą przyszłą sesję zmieniającą `/CLAUDE.md` lub `.claude/`; wpisać to do `/CLAUDE.md`.
6. Paczka zip tej samej wersji, STATUS.md, usunięcie `/MIGRACJA/` (prócz `KONKORDANCJA.tsv` w `dokumentacja/migracja/`; `konkordancja.py` przenieść tam też).

### A7. Odbiór w **nowej** sesji (na `main`, M1)
Nowa sesja zaczyna od `origin/main`, czyli już po scaleniu. Poprawki idą „do przodu” małymi commitami.
1. K1: Ty wpisujesz `/context` (Memory files = `/CLAUDE.md` ≤ 5k). Albo sesja sama uruchamia `claude -p "/context" --model opus --effort medium --permission-mode default --max-turns 1 --max-budget-usd 0.5` w korzeniu repo (mierzy to, co dostaje nowa sesja na starcie, 0 USD). Wynik SessionStart widoczny w odpowiedzi.
2. K2: Read `galeria.py` (`limit: 50`) → w transkrypcie wpis `nested_memory` dla `galeria-niezmienniki.md`; Ty potwierdzasz `/context` ≤ 25k.
3. Agent Explore i agent `wykonawca` (w worktree) czytają `galeria.py` (`limit: 50`). W **ich transkryptach** (nie w relacji) jest treść `agent-rules.md` i niezmienników (T12: dopasowanie `paths` w `.claude/worktrees/…`).
4. Agent `recenzent` daje się wywołać, skille `/dostawa` i `/przekazanie` są widoczne.
5. Wyniki w CHANGELOG.

### A8. Środowisko chmury (Ty, w UI, opcjonalnie)
- Setup script środowiska Foldery: instalacje z `tools/srodowisko.sh` (cache obrazu dysku, sesje bez 1–3 min instalacji) [SOURCE: CC cloud-environments.md].
- Warunki: < ~5 min, exit 0 (O0 §7).

## 5. Etap B: kondensacja (po jednym obszarze, przy okazji)

- **Reguła w `/CLAUDE.md`:** sesja, która zmienia kod obszaru, którego plik nie jest jeszcze skondensowany, najpierw kondensuje ten plik:
  - przepisuje go do stanu obecnego;
  - kod jest arbitrem (`tools/mapa_kodu.py -f`);
  - warstwy „vX supersedes” scala;
  - historię zostawia w CHANGELOG i archiwum;
  - dodaje nagłówek „stan: skondensowany v<wersja>”;
  - commit jest osobny, przed zmianą kodu.
- Wyjątek: sesja z drobną poprawką może odłożyć kondensację, wpisując to do STATUS.md („obszar X: kondensacja odłożona”). Ty możesz też zlecić wprost „skondensuj obszar X”.
- Recenzent porównuje stary i nowy plik obszaru (diff dostępny, plik mały) pod kątem zgubionych reguł i zmienionych znaczeń.
- `doc_check` (A4.5 pkt 7) pilnuje, żeby plik skondensowany nie odrastał warstwami wersji.
- Koniec etapu B: wszystkie pliki skondensowane → usunąć `/archiwum/` (zostaje w git).
- Koszt: rozłożony na zwykłe sesje, ~1 h na obszar [ASSUMPTION].

## 6. Ryzyka

| Ryzyko | Prawd. | Zapobieganie |
|---|---|---|
| Utrata informacji | niskie w A (konkordancja 100%), średnie w B | A3.3; w B recenzent per obszar + archiwum |
| Rozjazd strażnika i dokumentów | wysokie bez jednego commitu | A4 w jednym commicie, testy przed pushem |
| Klasyfikator odrzuca zapisy `.claude/` / CLAUDE.md | średnie (findings.md 2026-10-06, n=2) | ścieżka `staging/` (A5) |
| Zły hook blokuje pracę | niskie | testy JSON, prowokacje; awaryjnie `--settings '{"disableAllHooks": true}'` (CC hooks.md) |
| Hook po cichu nie działa (ścieżka, `chmod`) | średnie | `/hooks`, prowokacje A6.2 |
| Pliki w etapie A są „warstwowe”, mogą zawierać sprzeczne akapity | pewne do czasu B | nagłówek „nowszy zastępuje starszy” (jak dziś), kondensacja przy dotknięciu obszaru |
| `git mv` jednak wczytuje stary plik (niezweryfikowane) | niskie | `/context` w A0.1; jeśli wczytał, praca dalej działa, tylko drożej |
| Agenci workflow bez SubagentStart (niezweryfikowane) | nieznane | reguły dla agentów powtarzać w promptach workflow |
| GitHub MCP, `gh` lub skrypt omija hook (np. push z wnętrza skryptu) | niskie | deny narzędzi MCP i `gh pr merge`/`gh api *merge*`; pełna ochrona tylko branch protection (D6) |
| Hook nie startuje (brak bitu wykonywalności po wgraniu przez GitHub) | było: średnie | wywołanie przez `bash`/`python3` (T2) |
| Scalenie odrzucone przez klasyfikator | średnie | PR + scalenie przez Ciebie (A6.5, T4) |

## 7. Wycofanie
- Przed scaleniem: porzucić gałąź; `main` nietknięty.
- Po scaleniu: przywrócenie drzewa jednym commitem „do przodu” (T13; `git merge --no-edit` z MAPA §3 tworzy commit scalenia, gdy `main` się przesunął, więc `revert` zakresu by się nie udał): `git restore --source=<stary_main> --staged --worktree :/ && git commit -m "Wycofanie migracji dokumentacji"` i push, bez przepisywania historii.

## 8. Reguły dla następców (wpisywane w `/CLAUDE.md`)
- Wiedza: jeden fakt w jednym miejscu; nowy obszar → nowy plik + wiersz w MAPA §1 z rozmiarem w KB.
- Obszar zmieniony → plik obszaru przepisany do stanu obecnego (po kondensacji); linia w CHANGELOG; STATUS nadpisany.
- Pliki do czytania w całości ≤ 40 KB (jeden Read); większe dzielić. `doc_check` pilnuje limitów, odsyłaczy i formatu.
- Bez `@` importów dużych plików; nigdy `@a.md, @b.md` z przecinkiem.
- Po zmianie modelu: pomiar bajtów na token (`/context` z importami) i korekta limitów (O0 §9). Raz na kwartał `/doctor prompt-audit` na `/CLAUDE.md` i `.claude/` (O0 §6).

---

## Załącznik R: uwagi recenzji „meta” i decyzje

| Uwaga | Decyzja | Uzasadnienie / zmiana w planie |
|---|---|---|
| Wersja dwuetapowa (A mechaniczny, B kondensacja) | **Przyjęta ze zmianą** | Przyjęta w całości poza jednym: rozdział na pliki „-historia” w A odrzucony, bo wymaga oceny znaczenia, czyli pracy z etapu B. W A akapity zostają w kolejności „od najnowszego” (§0, A2, §5) |
| M1 odbiór w nowej sesji niewykonalny przed scaleniem | Przyjęta | A6 (w sesji migracji) + A7 (nowa sesja na `main`) |
| M2 sprzeczny limit MAPA 6 000 B | Przyjęta (mój błąd) | MAPA ≤ 40 000, STATUS ≤ 6 000 |
| M3 prowokacje mogą zaszkodzić | Przyjęta | wszystkie z `--dry-run` |
| M4 Stop hook porównuje ze startem sesji | Przyjęta | `turn-baseline.sh` (UserPromptSubmit) |
| M5 pokrycie identyfikatorami słabe | Przyjęta | konkordancja linii 100% zamiast identyfikatorów; §1 i §5 dosłownie |
| M6 odwołania „§N” | Przyjęta | stabilne numery §5.N, KONKORDANCJA.tsv, grep `§[0-9]` (A3.4) |
| M7 ręczne wagi, historia w nagłówku MAPA §4, brak przymusu „przepisuj” | Przyjęta ze zmianą | rozmiar w KB sprawdzany ±10%; stały nagłówek §4; zakaz `**v4.` tylko w plikach oznaczonych jako skondensowane (w A pliki są dosłowne) |
| M8 `git mv` na starcie | Przyjęta | A0.1; plan w `/MIGRACJA/` poza `GaleriaFolderow/` (D8) |
| M9 kopiować skryptem | Przyjęta | A3.1 |
| M10 wycofanie | Przyjęta | §7 |
| M11 klasyfikator przy `.claude/` | Przyjęta | ścieżka `staging/` (A5) |
| M12 duplikaty MAPA §3, EFFORT §6.10 | Przyjęta | A4.3, A4.4 |
| M13 protokół weryfikacji pod `tests/**` się nie załaduje | Przyjęta | protokół w `/CLAUDE.md`, szczegóły w `SRODOWISKO-TESTY.md` |
| M14 archiwum w `GaleriaFolderow/` | Przyjęta ze zmianą | archiwum w `/archiwum/` (poza zipem i grepem po `GaleriaFolderow`); samo `git grep` odrzucone, bo archiwum jest źródłem dla skryptu w A i dla kondensacji w B |
| M15 GitHub MCP omija hooki | Przyjęta ze zmianą | deny 4 narzędzi zapisu zamiast hooka (prostsze i twarde) |
| Uwaga o `read()` w `doc_check` | Przyjęta | A4.5 |
| Odstępstwo „§1 dosłownie w CLAUDE.md” (runda 2) | **Wycofane** | N1 |
| N1 nieaktualne reguły §1 w pliku ładowanym wszystkim | Przyjęta (mój błąd) | §1 → `ZASADY-UZYTKOWNIKA.md` dosłownie; nagłówek tylko do archiwum; CLAUDE.md streszcza obowiązujące reguły |
| N2 konkordancja rozjedzie się po edycjach A3.4/A4 | Przyjęta | konkordancja na commicie po A3.2, SHA w POSTEP.md, późniejsze sprawdzenia względem SHA |
| N3 kolejność `git mv` vs `merge --ff-only`, brak katalogu | Przyjęta | A0.1 merge, A0.2 `mkdir -p` + `git mv` |
| N4 prowokacja MCP może naprawdę wypchnąć | Przyjęta | `/permissions`, potem wywołanie na nieistniejące repo/gałąź |
| N5 stdout hooka UserPromptSubmit trafia do kontekstu | Przyjęta | `turn-baseline.sh` cichy, limit 30 s |
| N6 zepsuty frontmatter reguły = ładowanie zawsze | Przyjęta | `doc_check` pkt 9 |
| N7 tolerancja ±10% za ciasna | Przyjęta | pełne KB, max(10%, 1 KB) |
| N8 kondensacja opcjonalna | Przyjęta | `doc_check` pkt 8 + lista w STATUS; wyjątek „odłożona” (§5) |

## Załącznik T: recenzja techniczna i decyzje

| Uwaga | Decyzja | Zmiana |
|---|---|---|
| T1 regexy `guard-bash` blokują poprawne i przepuszczają force/main (zmierzone) | Przyjęta | `guard_bash.py` z tokenizacją (Załącznik S), 22/22 + moje 8/8 |
| T2 exec form wymaga bitu wykonywalności; brak = strażnik wyłączony | Przyjęta | wywołanie przez `bash` / `python3 -I` |
| T3 `/context`, `/hooks`, `/permissions` wpisuje człowiek | Przyjęta | sprawdzenia przez transkrypt (`nested_memory`), skutki i `claude -p "/context"`; opcjonalnie Ty |
| T4 scalenie do `main` może zostać odrzucone | Przyjęta | ścieżka PR (A6.5) |
| T5 hash statusu nie widzi ponownej edycji | Przyjęta | hash z treścią zmian; `additionalContext` zamiast `block` |
| T6 deny `backup/` i zip mogą zablokować dostawę | Przyjęta ze zmianą | deny usunięte; `backup/` chroni `guard-edit.sh` (Edit/Write); prowokacja `cp` |
| T7 inne drogi zapisu (`gh`, MCP auto-merge, Actions) | Przyjęta | dodatkowe deny (miękkie dla `gh`, twarde dla MCP) |
| T8 sprawdzenie CI przepuszcza `on: push` | Przyjęta | lista dozwolonych: tylko `workflow_dispatch` |
| T9 pokrycie zakresów, skrypt ginie, treść przepisana bez źródła | Przyjęta | pokrycie 1–4711, skrypt w repo, archiwum MAPA i EFFORT |
| T10 pliki dosłowne zawierają nieaktualne polecenia | Przyjęta | nagłówek „przy sprzeczności obowiązują `/CLAUDE.md` i `/dostawa`” |
| T11 limit reguły 32 KB za ciasny; brak limitu agent-rules | Przyjęta | 36 KB; agent-rules ≤ 9 000 znaków |
| T12 `paths` w worktree niezweryfikowane | Przyjęta | `**/GaleriaFolderow/galeria.py` + test w A7.3 |
| T13 wycofanie przez `revert` zakresu zawiedzie przy commicie scalenia | Przyjęta | `git restore --source=<stary_main>` + commit |
| Szacunek kosztu optymistyczny | Przyjęta | 10–25 USD, pomiar po A2 |

## Załącznik S: `guard_bash.py` i przypadki testowe

Autor: niezależny recenzent techniczny, przetestowane 22/22; ponowne sprawdzenie 8 przypadków w tej sesji: zgodne. **Poprawka po recenzji sceptyka (S4):** stan repo (gałąź, korzeń dla `doc_check`) jest liczony z pola `cwd` wejścia hooka, a nie z `CLAUDE_PROJECT_DIR`, które nie podąża za worktree [SOURCE: CC hooks part2 „Worktrees are different”]. Ponowny test: 8 przypadków zgodnych + przypadek worktree (`git push` w worktree na gałęzi `main` przy czerwonym `doc_check` → 2; w głównej kopii na gałęzi sesji → 0) [MEASURED: 2026-10-08]. Kopiować dosłownie do `.claude/hooks/guard_bash.py`.

```python
import json, os, re, shlex, subprocess, sys
_in = json.load(sys.stdin)
cmd = _in.get("tool_input", {}).get("command", "") or ""
CWD = _in.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR", ".")
def segments(s):
    lx = shlex.shlex(s.replace("\n", " ; "), posix=True, punctuation_chars=";&|")
    lx.whitespace_split = True
    seg = []
    try:
        for t in lx:
            if t and set(t) <= set(";&|"):
                if seg: yield seg
                seg = []
            else:
                seg.append(t)
    except ValueError:
        yield s.split(); return
    if seg: yield seg
def git_sub(seg):
    i = 0
    while i < len(seg) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", seg[i]): i += 1
    if i >= len(seg) or os.path.basename(seg[i]) != "git": return None, []
    i += 1
    while i < len(seg) and seg[i].startswith("-"):
        i += 2 if seg[i] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace") else 1
    return (seg[i], seg[i+1:]) if i < len(seg) else (None, [])
def block(msg): print(msg, file=sys.stderr); sys.exit(2)
segs = list(segments(cmd))
to_main_ctx = False
need_doc = False
for seg in segs:
    sub, args = git_sub(seg)
    if sub in ("checkout", "switch") and "main" in args: to_main_ctx = True
    if sub in ("filter-branch", "filter-repo"): block("BLOKADA: przepisywanie historii")
    if sub != "push": continue
    opts = [a for a in args if a.startswith("-")]
    pos = [a for a in args if not a.startswith("-")]
    if any(o.startswith(("--force", "--mirror")) or re.match(r"^-[a-zA-Z]*f", o) for o in opts) \
       or any(p.startswith("+") for p in pos[1:]):
        block("BLOKADA: force-push zabroniony (reguła scalania użytkownika)")
    refs = pos[1:]
    dst_main = any(re.search(r"(^|:)(refs/heads/)?main$", r) for r in refs) or "--all" in opts
    if not refs:
        cur = subprocess.run(["git", "-C", CWD, "branch", "--show-current"],
                             capture_output=True, text=True).stdout.strip()
        dst_main = dst_main or cur == "main" or to_main_ctx
    need_doc = need_doc or dst_main
if need_doc:
    top = subprocess.run(["git", "-C", CWD, "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or CWD
    root = os.path.join(top, "GaleriaFolderow")
    r = subprocess.run([sys.executable, "tools/doc_check.py"], cwd=root, capture_output=True, text=True)
    if r.returncode != 0:
        block("BLOKADA push na main: doc_check czerwony - najpierw dokumentacja:\n" + r.stdout + r.stderr)
sys.exit(0)
```

Wpis w `settings.json`: `{"type":"command","command":"python3","args":["-I","${CLAUDE_PROJECT_DIR}/.claude/hooks/guard_bash.py"],"timeout":120}`.

Testy: `jq -n --arg c "<polecenie>" '{tool_input:{command:$c}}' | python3 -I guard_bash.py; echo $?` (0 = przepuszcza, 2 = blokuje), w repo testowym na gałęzi `claude/sess`, z atrapą `GaleriaFolderow/tools/doc_check.py`, która zwraca 1 przy `RED=1`. Przypadki 1–20 przy `RED=1`:

| # | Polecenie | Oczekiwane |
|---|---|---|
| 1 | `git push -u origin claude/session-abc` | 0 |
| 2 | `git push origin HEAD && rm -f /tmp/x.txt` | 0 |
| 3 | `git add -A && git commit -m "kafelki +2 px" && git push -u origin claude/x` | 0 |
| 4 | `git push origin HEAD 2>&1 \| tail -f /dev/null` | 0 |
| 5 | `git commit -m "opis: git push -f jest zabroniony"` | 0 |
| 6 | `git push --dry-run origin HEAD` | 0 |
| 7 | `git push` | 0 |
| 8 | `git push -fu origin x` | 2 |
| 9 | `git push origin "+HEAD:main"` | 2 |
| 10 | `git -c core.x=1 push --force` | 2 |
| 11 | `git --no-pager push -f origin x` | 2 |
| 12 | `git -C . push --force-with-lease` | 2 |
| 13 | `git push --mirror origin` | 2 |
| 14 | `git push --dry-run origin HEAD:main` | 2 |
| 15 | `git push origin HEAD:refs/heads/main` | 2 |
| 16 | `git push origin main` | 2 |
| 17 | `git fetch origin main && git checkout main && git merge --ff-only origin/main && git merge --no-edit claude/s && git push origin main && git checkout claude/s` | 2 |
| 18 | `git checkout main && git merge claude/s && git push` | 2 |
| 19 | `git push origin claude/maintenance` | 0 |
| 20 | `git filter-repo --path x` | 2 |
| 21 | `git push origin main` (bez `RED`) | 0 |
| 22 | `git push` po `git checkout -b main`, `RED=1` | 2 |

