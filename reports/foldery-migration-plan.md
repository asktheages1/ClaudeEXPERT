# Plan migracji systemu dokumentacji Foldery

Wersja: 1 (przed recenzjami) · 2026-10-08 · podstawa: `reports/foldery-analysis.md` (dalej „Raport”), Foldery `main` @ `be31a48`.
Słowniczek pojęć: Raport, początek pliku.

## 0. Cel i kryteria sukcesu (mierzalne)

Cel: każda przyszła sesja i każdy agent Foldery dostaje automatycznie tylko to, czego potrzebuje. Wiedzę projektu znajduje przez jedną tabelę, a reguły „nigdy/zawsze” wymusza program, nie tekst. Nic z obecnej wiedzy nie ginie.

| # | Kryterium | Jak sprawdzić | Dziś |
|---|---|---|---|
| K1 | Instrukcje projektu na starcie sesji ≤ 8k tokenów | `/context` → Memory files + długość wyniku SessionStart | 0 na starcie, 239,9k po pierwszym Read |
| K2 | Instrukcje po pierwszym Read `galeria.py` ≤ 25k tokenów łącznie | `/context` po Read `galeria.py` z `limit` | 239,9k |
| K3 | Każdy plik oznaczony w MAPA §1 jako „czytaj w całości” ≤ 20k tokenów | pomiar `/context` (metoda: Raport §5) | MAPA 29,4k, USUWANIE 44,8k |
| K4 | Żadna informacja z dzisiejszego CLAUDE.md nie ginie bez decyzji | skrypt pokrycia identyfikatorów (F2.4) ≥ 99% + lista świadomych wyjątków; archiwum pełnej kopii | — |
| K5 | Reguły: force-push, push trigger w CI, edycja backupów, scalanie do `main` przy czerwonym `doc_check` są blokowane przez program | prowokacje z F7 | 0 blokad |
| K6 | Testy zielone: `./tools/testy.sh` (bez znanego czerwonego „siatka gruba i mocna”) | wynik testów | zielone |
| K7 | Strażnik sam się pilnuje: test mutacyjny `doc_check` w `test_logic` przechodzi na nowym układzie | `test_logic` | jest, na starym układzie |

## 1. Decyzje właściciela przed startem (z rekomendacją)

| # | Pytanie | Rekomendacja | Konsekwencja wyboru |
|---|---|---|---|
| D1 | Zgoda na podział `GaleriaFolderow/CLAUDE.md` i nowy `doc_check` | **Tak** | Bez tego plan nie rusza |
| D2 | Czy paczka zip ma zawierać nowy główny `CLAUDE.md` (leży poza `GaleriaFolderow/`) | **Nie.** Zip jest dla Twojego Windowsa; Claude pracuje z gita (MAPA §0: „never unzip a package to work”). Reguła „always re-add CLAUDE.md to the zip” (CLAUDE.md §2) do usunięcia | Tak → dopisać `../CLAUDE.md` do polecenia zip |
| D3 | Pełna kopia starego CLAUDE.md jako archiwum `GaleriaFolderow/dokumentacja/archiwum/CLAUDE-do-v4.37.9.md` (nie ładuje się samo, bo nazwa ≠ `CLAUDE.md`) | **Tak** (siatka bezpieczeństwa dla K4; grep zamiast `git show`) | Ryzyko: ktoś potraktuje archiwum jako źródło prawdy → nagłówek „HISTORIA, nie źródło prawdy” + wpis w CLAUDE.md |
| D4 | Backupy `backup/` (70 kopii, ~70 MB) zastąpić tagami git | **Osobna decyzja, nie w tej migracji** (dotyczy paczki i audytów, nie dokumentacji) | — |
| D5 | Lekkie CI `doc_check` na push (Ubuntu, ~1 min) | **Nie teraz** (Twój limit minut Actions); hook przed scaleniem do `main` daje to samo w sesjach Claude | Tak → dodatkowy plik workflow i wyjątek w `guard-edit` |
| D6 | Branch protection `main` | **Nie teraz** (prywatne repo = płatny plan, O0 §7) | — |
| D7 | Kto wykonuje | **Jedna sesja Foldery** (jedno repo), model Opus 5.5, wysiłek `high`, + 3 agentów-redaktorów (F2) + 1 recenzent | Sama sesja bez agentów: wolniej, większy kontekst głównego okna |
| D8 | Jak plan trafia do Foldery | Wgrywasz ten plik do Foldery jako `GaleriaFolderow/dokumentacja/migracja/PLAN-MIGRACJI.md` (tak jak wgrałeś pliki tutaj), albo pozwalasz mi go tam wypchnąć | Bez tego sesja Foldery planu nie widzi (sesja z dwoma repo nie czyta `.claude/settings.json`, Raport §3 D6) |

## 2. Wykonawca, model, koszt, czas

```
USTAW PRZED WKLEJENIEM
Model: Opus 5.5 · wysiłek: high · workflow: nie (3 agentów-redaktorów w osobnych worktree + 1 recenzent, narzędzie Agent)
Start: claude --model opus --effort high
Uzasadnienie: przepisanie ~240k tokenów wiedzy z zachowaniem faktów = dużo weryfikacji; obszary rozłączne → agenci równolegle.
```
- Szacunek kosztu (cennik API, ASSUMPTION): główne okno ~10–20 USD, agenci-redaktorzy 3 × 3–6 USD, recenzent 3–5 USD → **~25–45 USD**, **3–5 h**. Na subskrypcji przekłada się to na zużycie limitów. Każdy agent dotykający `GaleriaFolderow/` zanim stary CLAUDE.md zniknie płaci za jego wczytanie (240k), co jest tu nieuniknione, bo to materiał źródłowy.
- Program bez zmian: `APP_VERSION` zostaje 4.37.9, paczka ma tę samą nazwę (reguła „audyty / docs nie zmieniają wersji”, CLAUDE.md §1).

## 3. Fazy

Kolejność jest wiążąca. Każda faza kończy się commitem na gałęzi sesji i **pushem gałęzi** (praca w chmurze ginie bez pushu, O0 §7). Do `main` scalamy dopiero po F7 (wyjątek od reguły „scalaj po każdej pracy”: niedokończona migracja na `main` zostawiłaby następnym sesjom pół systemu; zapisać tę decyzję w CHANGELOG).

### F0. Przygotowanie (główne okno, ~15 min)
1. `git fetch origin main && git merge --ff-only origin/main`. Gałąź sesji = `main`.
2. Pomiar bazowy (Raport §5, metoda `/context` z importami w katalogu poza repo): CLAUDE.md, MAPA, USUWANIE, README. Zapis do notatek migracji.
3. Kopia archiwalna (D3): `cp GaleriaFolderow/CLAUDE.md GaleriaFolderow/dokumentacja/archiwum/CLAUDE-do-v4.37.9.md` + 3-liniowy nagłówek „HISTORIA, stan na v4.37.9, nie źródło prawdy; aktualne: MAPA.md §1”.
4. `tests/` i `tools/`: nic nie zmieniać w tej fazie.

### F1. Infrastruktura (~5 min)
1. `.gitignore`: usunąć `.claude/`, dodać `.claude/worktrees/` i `.claude/settings.local.json`.
2. Sprawdzić, że w repo nie ma przypadkowego `.claude/` z dawnych sesji (`git status --ignored`), zanim zniknie wpis.

### F2. Podział treści (agenci-redaktorzy + główne okno, ~2–3 h)
**Zasada przepisania:** każdy plik docelowy opisuje **stan obecny** obszaru. Warstwy „vX.Y supersedes…” scalić w jeden opis. Historia decyzji zostaje w `CHANGELOG.md` i archiwum. Kod jest arbitrem: przy sprzeczności opis kontra kod wygrywa kod (`tools/mapa_kodu.py -f`), a opis się poprawia.

| Źródło (dzisiejszy CLAUDE.md) | Cel | Limit | Kto |
|---|---|---|---|
| nagłówek + §1 (zasady użytkownika) | główny `/CLAUDE.md` (skrót reguł) + `GaleriaFolderow/dokumentacja/ZASADY-UZYTKOWNIKA.md` (pełne brzmienie z datami i cytatami) | 11 KB / 40 KB | główne okno |
| §2 Pliki | `dokumentacja/PLIKI.md` (inwentarz bez historii; opisy testów w `.claude/rules/testy.md`); pakowanie → skill `/dostawa` | 40 KB | główne okno |
| §3 Środowisko i weryfikacja | `.claude/rules/testy.md` (protokół weryfikacji, pułapki z MAPA §2/§7) + krótko w `/CLAUDE.md`; snippet AST już jest w `tools/ast_check.py` (usunąć z tekstu) | 32 KB | główne okno |
| §4 Architektura | `dokumentacja/architektura/<obszar>.md`, podział według tabeli MAPA §1 (np. operacje-plikow-undo, panele-kafelki-katalog, przegladarka-podglad-wideo, przycinanie-edycja, sortowanie-litery-osoby-strzalki-boksy, wyszukiwarka-zakladki, montaz-hybryda, okno-adresu-kadr-filmu, diagnostyka-watki-tlo) | 40 KB każdy | 3 agentów-redaktorów (podział obszarów rozłączny) |
| §5 Specyfikacja | `dokumentacja/spec/<obszar>.md`, te same obszary co §4, albo dopisana sekcja „Specyfikacja (uzgodnione)” w pliku obszaru, jeśli zmieści się w limicie | 40 KB | j.w. |
| §6 Niezmienniki | `.claude/rules/galeria-niezmienniki.md`, `paths: GaleriaFolderow/galeria.py`; bez historii wersji, pogrupowane tematycznie | 32 KB | główne okno |
| §7 Ograniczenia | sekcja „Ograniczenia” w plikach obszarów (preferowane) albo `dokumentacja/OGRANICZENIA.md` | 40 KB | agenci |
| §8 Changelog | `GaleriaFolderow/CHANGELOG.md` **dosłownie** (bez przepisywania) + na górze linie z MAPA §9 starsze niż bieżący stan | bez limitu (nie czytany w całości, grep) | główne okno |
| §9 Backlog | `dokumentacja/BACKLOG.md` | 40 KB | główne okno |
| MAPA §9 Status | `GaleriaFolderow/STATUS.md` (nadpisywany: wersja, zrobione, otwarte, następne zadanie, decyzje czekające) | 6 KB | główne okno |
| `dokumentacja/ai/USUWANIE-OBIEKTOW.md` (44,8k) | podział na 2–3 pliki w `dokumentacja/ai/` ≤ 40 KB; README.md w `ai/` jako indeks | 40 KB | agent C |
| EFFORT-ZASADY §5–§6 | skill `/przekazanie` (blok + szablon); w EFFORT-ZASADY zostaje §1–§4, §7–§9 | ≤ 20 KB | główne okno |

F2.1. Główne okno pisze listę obszarów i przypisanie każdego akapitu §4/§5/§7 (lead-in `**…**` + nr linii) do obszaru, potem zapisuje ją w `dokumentacja/migracja/PRZYPISANIE.md`. Agenci dostają tylko swoje wiersze.

F2.2. Agenci-redaktorzy to **general-purpose z promptem**, nie definicja z `.claude/agents/`, bo katalog agentów utworzony w trakcie sesji wymaga restartu (Raport §7 krok 6). Pracują **na wspólnym checkoucie bez `isolation: worktree`**: worktree powstałby z `origin/main` bez niezacommitowanej pracy F0–F2.1 (O0 §3), a każdy agent pisze tylko własne nowe pliki, więc konfliktów nie ma. Prompt agenta: cel, przypisane akapity, zasada przepisania, limit bajtów, zakaz ruszania innych plików, format raportu (co gdzie trafiło, co pominięte i dlaczego, sprzeczności opis kontra kod).

F2.3. Główne okno: nowy `MAPA.md`:
- §0 bez zmian merytorycznych;
- §1 = tabela zadanie → plik **z wagą w tokenach** i adnotacją „w całości / w częściach”;
- §4 code map;
- §5–§8 bez zmian lub skrócone;
- §9 usunięty (→ STATUS.md);
- cel ≤ 40 KB.

F2.4. Sprawdzenie kompletności (skrypt jednorazowy w scratchpadzie, nie w repo):
- wyciąga ze starego CLAUDE.md wszystkie identyfikatory w backtickach (nazwy funkcji, klas, stałych, plików) i lead-iny `**v…**`;
- sprawdza ich obecność w zbiorze: nowe pliki + `.claude/rules/*` + CHANGELOG.md;
- wynik ≥ 99%, a resztę wypisać i świadomie zatwierdzić (np. usunięte funkcje).

Uzupełnia to recenzent (F2.5) na faktach jakościowych.

F2.5. Recenzent (general-purpose, tylko odczyt w promptcie; Bash do `git diff`): porównuje stare §1–§7 z nowymi plikami. Szuka zgubionych reguł, zmienionych znaczeń, sprzeczności między plikami i różnic opis kontra kod. Każde istotne znalezisko: poprawka albo odrzucenie z dowodem.

### F3. Strażnik `doc_check.py` v2 (główne okno, ~45 min) — **w jednym commicie z F4**
Zakres nowych reguł (każda z komunikatem po polsku, jak dziś):
1. Wersja: `CHANGELOG.md` ma linię `- v{ver}` lub `- **v{ver}` (zamiast CLAUDE.md §8); `STATUS.md` zawiera `v{ver}` (zamiast MAPA §9); MAPA §4 nagłówek `Code map (snapshot v{ver}` (bez zmian); README linia 1 `(wersja {ver})` (bez zmian). Usunąć wymóg „§4 Architecture zawiera v{ver}”: to on powodował narastanie.
2. Limity bajtów: `../CLAUDE.md` ≤ 11 000; `../.claude/rules/*.md` ≤ 32 000; `MAPA.md`, `STATUS.md` ≤ 6 000, każdy `dokumentacja/**/*.md` poza `archiwum/` ≤ 40 000.
3. Martwe odsyłacze: każda ścieżka w backtickach z MAPA §1 i z `../CLAUDE.md` kończąca się na `.md`, `.py`, `.sh`, `.bat`, `.txt` istnieje.
4. Zakaz powrotu wielkiego pliku: `GaleriaFolderow/CLAUDE.md` nie istnieje albo ma ≤ 2 000 B.
5. CI ręczne: `../.github/workflows/*.yml` nie zawierają kluczy `push:` ani `pull_request:` pod `on:` (proste dopasowanie linii; wyjątek tylko po decyzji D5).

`tests/test_logic.py` (blok „v47+ dokumentacja”, dziś linie ~10433–10454):
- zmienić warunek mutacji na komunikaty z nowymi nazwami (`CHANGELOG`, `MAPA.md §4`, `README`, `STATUS`), `len(...) >= 4`;
- dodać mutację rozmiaru (fałszywy `CLAUDE.md` 12 000 B → błąd limitu) i mutację martwego odsyłacza.

`tools/testy.sh` bez zmian (już wywołuje `doc_check`).

### F4. Przełączenie (główne okno, ~30 min) — **ten sam commit co F3**
1. Nowy `/CLAUDE.md` (szkic: Raport §6, uzupełniony o: odsyłacz do `dokumentacja/ZASADY-UZYTKOWNIKA.md`, `STATUS.md`, archiwum z ostrzeżeniem, regułę „przy pracy z kodem niezmienniki ładują się same”).
2. Usunięcie `GaleriaFolderow/CLAUDE.md`.
3. Aktualizacja odwołań do „CLAUDE.md §N” w: MAPA, EFFORT-ZASADY §6 pkt 10, `dokumentacja/ai/*.md`, README (jeśli są), komunikatach `doc_check`. Wyszukać `grep -rn 'CLAUDE.md §\|CLAUDE\.md' GaleriaFolderow .github`.
4. `./tools/testy.sh` (co najmniej `logic`) zielone → commit → push gałęzi.

### F5. Hooki i ustawienia (główne okno, ~45 min)
Szkice z Raportu §6 z **dwiema poprawkami** wykrytymi przy pisaniu planu:
- `guard-bash.sh`: `doc_check` blokuje **tylko push na `main`** (`git push … main`, `HEAD:main`, `:main`, oraz `git push` bez refspec, gdy bieżąca gałąź to `main`). Push gałęzi sesji z pracą w toku musi przechodzić, bo w chmurze to jedyna ochrona przed utratą pracy. Force-push blokowany zawsze.
- `stop-check.sh`: **tylko** sprawdzenie listy „Zmiany w tej odpowiedzi” (gdy drzewo albo HEAD zmienione od startu, blokada raz). Bez wymuszania `doc_check` i scalenia na Stop, bo popychałoby to model do scalania niegotowej pracy przy każdym pytaniu do Ciebie. Przypomnienie o scaleniu daje SessionStart i `/dostawa`.

Pliki: `.claude/settings.json`, `.claude/hooks/{session-start,subagent-start,guard-bash,guard-edit,stop-check}.sh` (`chmod +x`), `.claude/agent-rules.md` (≤ 8 000 znaków).

Test każdego hooka przed commitem: `echo '<JSON wejścia>' | .claude/hooks/X.sh; echo $?` dla przypadku dozwolonego i blokowanego (wzory wejść: CC hooks.md). Zależności (`jq`, `python3`, GNU `grep -P`) są w obrazie chmury [SOURCE: CC cloud-environments.md „Installed tools”]. Lokalnie na Windowsie (gdybyś kiedyś uruchomił Claude Code u siebie) skrypty bash się nie uruchomią, a hook zostanie po cichu wyłączony (exit 127, nie blokuje). Zapisać to w CLAUDE.md jako znane ograniczenie.

### F6. Agenci i skille (~30 min)
`.claude/agents/recenzent.md` (Read, Grep, Glob; `model: opus`, `effort: high`), `.claude/agents/wykonawca.md` (`isolation: worktree`, `disallowedTools: Agent`, `model: opus`, `effort: high`), `.claude/skills/dostawa/SKILL.md`, `.claude/skills/przekazanie/SKILL.md`. Szkice: Raport §6.
Pułapka worktree: kopia powstaje z `origin/main`, nie z HEAD sesji, więc w `wykonawca.md` i `/dostawa` trzeba zapisać „przed uruchomieniem wykonawców: commit + push + scalenie, albo `worktree.baseRef: "head"` w settings”. Decyzję zapisać w CLAUDE.md.

### F7. Odbiór w **nowej** sesji Foldery (~30 min)
Zmiana CLAUDE.md i nowe katalogi `.claude/agents` działają dopiero w nowej sesji (O0 §2, CC sub-agents.md). Lista kontrolna (wyniki w CHANGELOG):
1. `/context`: Memory files = `/CLAUDE.md` ≤ 5k (K1); wynik SessionStart widoczny (wersja, gałąź, STATUS).
2. Read `GaleriaFolderow/galeria.py` z `limit: 50` → komunikat „Loaded …galeria-niezmienniki.md”; `/context` ≤ 25k instrukcji (K2).
3. Agent Explore czyta `galeria.py` (limit 50) i cytuje pierwszą linię z `agent-rules.md` oraz jeden niezmiennik (dowód SubagentStart + reguła `paths`). Sprawdzić w transkrypcie, nie z relacji agenta.
4. Prowokacje (K5) na gałęzi testowej `test-hooki` (potem usunąć lokalnie):
   - `git push --force` → blokada;
   - `git push origin HEAD:main` przy celowo zepsutym STATUS.md → blokada;
   - `git push -u origin test-hooki` przy czerwonym `doc_check` → przechodzi;
   - Edit workflow z `push:` → blokada;
   - Edit pliku w `backup/` → deny;
   - odpowiedź bez listy „Zmiany…” po zmianie pliku → jedno upomnienie.
5. `./tools/testy.sh` (K6), `doc_check` (K7), pomiar wag (K3).
6. Dopiero teraz: scalenie do `main` według reguły scalania, paczka zip tej samej wersji, `STATUS.md` → „migracja zakończona”.

### F8. Środowisko chmury (Ty, w UI, ~10 min, opcjonalne, ale zalecane)
- Setup script środowiska Foldery: zawartość instalacji z `tools/srodowisko.sh` (pip PySide6/PyAV/Pillow + apt Qt libs + ffmpeg). Cache'owany obraz dysku, sesje startują bez 1–3 min instalacji [SOURCE: CC cloud-environments.md].
- Warunki: < ~5 min, exit 0 (inaczej sesja nie wystartuje, O0 §7).
- `tools/srodowisko.sh` zostaje jako sprawdzenie (szybkie, gdy wszystko jest).

## 4. Ryzyka

| Ryzyko | Prawdopodobieństwo | Skutek | Zapobieganie |
|---|---|---|---|
| Zgubiona reguła / fakt przy przepisywaniu | średnie | Regresja w kodzie przyszłej sesji | F2.4 skrypt pokrycia, F2.5 recenzent, archiwum (D3) |
| Rozjazd strażnika i dokumentów | wysokie, jeśli F3 i F4 osobno | Czerwone testy, blokada paczki | F3+F4 w jednym commicie, testy przed pushem |
| Klasyfikator auto mode odrzuca zmiany CLAUDE.md / `.claude/` („Self-Modification”, chroniona ścieżka) | średnie (findings.md 2026-10-06, n=2) | Sesja nie może sama scalić do `main` | Ty scalasz na GitHubie albo zatwierdzasz; zaplanować to w F7.6 |
| Hook z błędem blokuje normalną pracę | niskie | Sesja „zakleszczona” | Testy hooków z JSON (F5), `--settings '{"disableAllHooks": true}'` jako awaryjne wyłączenie (CC hooks.md) |
| Hook po cichu nie działa (zła ścieżka, brak `chmod +x`) | średnie | Fałszywe poczucie ochrony | Prowokacje F7.4, `/hooks` |
| Agenci F2 nadpisują sobie pliki | niskie | Utrata pracy agenta | Rozłączne pliki docelowe, główne okno jedyny pisarz plików wspólnych |
| Kontekst głównego okna (240k + praca) | średnie | Kompaktowanie, utrata ustaleń z rozmowy | Postęp zapisywany w `dokumentacja/migracja/POSTEP.md` po każdej fazie (przeżywa kompaktowanie, O0 §8) |
| Nowy układ za mało znany kolejnym sesjom | niskie | Czytają archiwum | Ostrzeżenie w nagłówku archiwum + CLAUDE.md + SessionStart |
| Agenci workflow nie dostają SubagentStart (niezweryfikowane) | nieznane | Agent workflow bez reguł dla agentów | Reguły dla agentów powtarzać w promptach workflow; test przy pierwszym użyciu workflow |

## 5. Wycofanie
- Przed scaleniem do `main` (F0–F7) wystarczy porzucić gałąź; `main` jest nietknięty.
- Po scaleniu: `git revert -m 1 <merge>`, jeden commit, bez przepisywania historii (zgodne z regułą „nigdy force-push”). Stary CLAUDE.md wraca z historii albo z archiwum.

## 6. Utrzymanie po migracji (reguły dla następców, wpisane w `/CLAUDE.md`)
- Zmiana obszaru → przepisz plik obszaru do stanu obecnego (nie dopisuj warstw), dodaj linię w CHANGELOG, nadpisz STATUS.
- Nowy obszar → nowy plik + wiersz w MAPA §1 z wagą.
- Waga pliku przekracza limit → `doc_check` czerwony → podziel plik.
- Po zmianie modelu: ponowny pomiar bajtów na token i korekta limitów (O0 §9).
- Raz na kwartał lub po większej zmianie: `/doctor prompt-audit` na `/CLAUDE.md` i `.claude/` (raport bez zmian w plikach, O0 §6).
