# Plan migracji systemu dokumentacji Foldery

Wersja: **4.2** (trwałość po migracji: przegląd U1–U10; hooki w jednym pliku Pythona `foldery-hooks/hooks.py` z testem 82/82, Załącznik H; recenzja sceptyka SK1–SK17; wcześniej: recenzje „meta” M1–M15, N1–N8, techniczna T1–T13, S4/S5; decyzje: `foldery-migration-plan-recenzje.md`) · 2026-10-08 · podstawa: `reports/foldery-analysis.md` (dalej „Raport”), Foldery `main` @ `be31a48`.
Słowniczek pojęć: Raport, początek pliku.

## 0. Idea w trzech zdaniach

1. **Etap A** to jedna sesja wykonująca mechaniczną, bezstratną przebudowę: tekst przenosi skrypt według zakresów linii, a każda stara linia ląduje dokładnie w jednym nowym pliku (sprawdzalne w 100%). Do tego dochodzą nowy krótki `CLAUDE.md`, nowy strażnik `doc_check`, hooki, agenci i skille.
2. Sam etap A daje cały zysk ładowania (kontekst ~240k → ~5k na starcie i ~18k przy pracy z kodem), bo wynika on z tego, *gdzie* tekst leży, a nie z tego, jak jest napisany.
3. **Etap B** to kondensacja „do stanu obecnego”, po jednym pliku na sesję (skill `/kondensacja`, z recenzentem), w kolejności z STATUS.md. Do tego czasu pliki dosłowne są **zamrożone** (`doc_check` odrzuca każdą ich zmianę poza kondensacją), więc warstwy nie mogą odrastać. Ryzyko utraty wiedzy rozkłada się na małe, sprawdzalne zmiany.
4. **Po migracji** dokumentację pilnuje program, nie tylko tekst: push na `main` przechodzi tylko wtedy, gdy gałąź zmieniła STATUS.md, a przy zmianie kodu także CHANGELOG i dokumentację (albo zawiera jawne „docs: bez zmian (powód)”), i gdy `doc_check` jest zielony.

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
| K8 | Trwałość: push na `main` bez zmiany STATUS.md albo ze zmianą kodu bez CHANGELOG/dokumentacji jest blokowany; zmiana pliku zamrożonego daje czerwony `doc_check`; wyzwalacz CI inny niż `workflow_dispatch` blokuje **każdy** push | `bash test_hooks.sh` (82/82) + prowokacje A6 | 0 |

## 2. Decyzje właściciela przed startem

| # | Pytanie | Rekomendacja |
|---|---|---|
| D1 | Zgoda na etap A (przeniesienie, nowy `doc_check`, hooki) | **Tak** |
| D2 | Czy zip ma zawierać nowy `/CLAUDE.md` (leży poza `GaleriaFolderow/`) | **Nie.** Zip jest dla Twojego Windowsa, Claude pracuje z gita (MAPA §0). Reguła „always re-add CLAUDE.md to the zip” (stary §2) do usunięcia |
| D3 | Archiwum starego CLAUDE.md w `/archiwum/CLAUDE-do-v4.37.9.md` (korzeń repo, poza zipem i poza `GaleriaFolderow/`; nazwa ≠ `CLAUDE.md`, więc nie ładuje się samo); usunięte po zakończeniu etapu B (zostaje w historii git) | **Tak** |
| D4 | Backupy → tagi git; zip (20 MB) commitowany przy każdej dostawie zostaje na zawsze w historii git (~+20 MB na sesję: wolniejszy klon, dysk sesji ~30 GB, O0 §7) | **Osobna sprawa, nie w tej migracji, ale do decyzji wkrótce** (np. zip tylko przez SendUserFile, bez commitu) |
| D5 | CI `doc_check` na push | **Nie** (limit minut Actions); zastępuje go hook przed pushem na `main` |
| D6 | Branch protection `main` | **Nie teraz** (prywatne repo = płatny plan, O0 §7) |
| D7 | Wyjątek od reguły „scalaj z `main` po każdej pracy”: etap A scalany raz, po A6 (odbiór w sesji migracji), a nie po każdej fazie | **Tak** (pół migracji na `main` zostawiłoby następnym sesjom niespójny system) |
| D8 | Plan trafia do Foldery jako `/MIGRACJA/PLAN-MIGRACJI.md` (+ `MIGRACJA/RAPORT.md` = analiza ze szkicami (szkice hooków w Raporcie §6 są **nieaktualne**, obowiązuje Załącznik H), + `MIGRACJA/CLAUDE-NOWY.md` = gotowy nowy CLAUDE.md, + `MIGRACJA/hooks/hooks.py` i `MIGRACJA/hooks/test_hooks.sh` = gotowe hooki z testem, + `MIGRACJA/RECENZJE.md` = decyzje z recenzji) **w korzeniu repo** (poza `GaleriaFolderow/`, żeby jego przeczytanie nie wczytało starego CLAUDE.md). Wgrywasz go sam albo pozwalasz mi go tam wypchnąć. Folder `/MIGRACJA/` usuwany na końcu etapu A | **Tak** |
| D9 | Tryb uprawnień sesji migracji: **Auto**; gdy klasyfikator odmówi zapisu w `.claude/`, przełączasz sesję na chwilę na „Accept edits” i zatwierdzasz zapis kliknięciem (ścieżki chronione w tym trybie pytają, O0 §4; Z19), potem z powrotem Auto. Wgrywanie plików przez GitHub tylko w ostateczności | **Tak** (musisz być wtedy przy sesji; czekanie na zgodę = bezczynność, sesja może wygasnąć, O0 §7) |
| D10 | Etap B jako osobne sesje kondensacji zlecane przez Ciebie (`/kondensacja`, po jednym pliku, kolejność w STATUS.md: najpierw niezmienniki), zamiast „przy okazji” | **Tak**; ok. 15–18 plików × ~1 h [ASSUMPTION], można rozłożyć w czasie, bo pliki są zamrożone |

## 3. Wykonawca, model, koszt, czas (etap A)

```
USTAW PRZED WKLEJENIEM
Model: Opus 5.5 · wysiłek: high · workflow: nie (1 recenzent na końcu, narzędzie Agent)
Start (chmura): model Opus 5.5 w wyborze modelu sesji, potem jako pierwsze polecenie /effort high
Tryb uprawnień: Auto (D9)
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
- `.gitattributes`: `*.sh text eol=lf` i `*.py text eol=lf`. To higiena, **nie ochrona**: plik wgrany bez `git add` (np. przez stronę GitHuba) zachowuje `\r\n` także po sklonowaniu [MEASURED n=1: repo testowe, `git update-index --cacheinfo`, 2026-10-08]. Skrypt basha z CRLF kończy się kodem 2 [MEASURED n=1: sceptyk E4], a kod 2 w UserPromptSubmit odrzuca **każdy prompt** [SOURCE: CC hooks part3]. Dlatego wszystkie hooki są w Pythonie (CRLF mu nie szkodzi; test CRLF w `test_hooks.sh`), a hooki nieblokujące zawsze kończą się kodem 0 (Załącznik H). Wcześniej `git status --ignored`: czy nie wypłynie przypadkowy `.claude/`.

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

Reguła `.claude/rules/testy.md` (szkic w Raporcie §5) **nie powstaje** w etapie A: wybór konwencji testów z §2/§3 to praca z etapu B. Konwencje testów są w `SRODOWISKO-TESTY.md`, a protokół weryfikacji w `/CLAUDE.md` (U4).

### A3. Przeniesienie i dowód bezstratności
1. Kopiowanie **tylko skryptem** (`sed -n 'a,bp'` / Python według KONKORDANCJA.tsv), nigdy przepisywaniem przez model (M9).
2. Każdy plik docelowy dostaje 3-liniowy nagłówek (w pliku reguły `galeria-niezmienniki.md` **po** zamykającym `---` frontmattera, bo frontmatter musi zostać w linii 1, SK10): obszar, „przeniesione dosłownie z CLAUDE.md v4.37.9; akapity od najnowszego, nowszy zastępuje starszy; **plik zamrożony: nie dopisuj, zmiana tylko przez kondensację (`/kondensacja`)**; **przy sprzeczności obowiązują `/CLAUDE.md` i skill `/dostawa`**” (T10: pliki dosłowne zawierają nieaktualne polecenia, np. „always re-add CLAUDE.md to the zip”, „§4 new paragraph at the TOP”).
3. **Skrypt konkordancji** (`/MIGRACJA/konkordancja.py`, **commitowany**, bo scratchpad ginie przy odzyskaniu maszyny, T9b):
   - zakresy w KONKORDANCJA.tsv pokrywają linie 1–4711 archiwum dokładnie, bez luk i nakładek (T9a);
   - multizbiór linii archiwum (bez linii-nagłówków `## N.`) = suma multizbiorów linii przeniesionych do plików docelowych plus linie oznaczone w KONKORDANCJA.tsv jako „tylko archiwum” (nagłówek l. 1–14), bez dodanych nagłówków i bez nowej treści CLAUDE.md;
   - wynik 100% albo lista różnic do wyjaśnienia;
   - to samo dla MAPA §9 i podziału USUWANIE;
   - **uruchamiany na commicie zrobionym zaraz po A3.2, zanim A3.4/A4 zmienią przeniesione linie (N2)**; SHA tego commita i wynik zapisz w POSTEP.md; późniejsze sprawdzenia (A6.4, recenzent) liczą konkordancję względem tego SHA (`git show <sha>:<plik>`), a nie względem bieżących plików.
4. Kontrola § (M6): `grep -rn '§[0-9]' GaleriaFolderow .claude CLAUDE.md` (z pominięciem `dokumentacja/ZASADY-UZYTKOWNIKA.md`, który zostaje w brzmieniu oryginalnym; do jego nagłówka dopisać legendę „stary § → nowy plik” z KONKORDANCJA.tsv) → każde odwołanie do starych sekcji zamienić na ścieżkę pliku (np. „CLAUDE.md §6” → „`.claude/rules/galeria-niezmienniki.md`”). Odwołania „§5.N” zostają, bo numery są stabilne; do nich dopisać plik `spec/SPEC-A|B.md`. Odwołania w testach z listy A0.4 też poprawić.

### A4. Nowe pliki nawigacji i strażnik (w **jednym commicie** razem z plikami z A5)
Kolejność (SK8): A4.1–A4.6 i A4.7 przygotowane → **A5** (pliki `.claude/`, `test_hooks.sh`) → A4.8 testy → jeden commit. `/CLAUDE.md` odsyła do plików z A5, więc bez nich `doc_check` pkt 4 byłby czerwony.

1. **`/CLAUDE.md`**: gotowy plik leży w `MIGRACJA/CLAUDE-NOWY.md` (przygotowany poza sesją, uwzględnia wszystkie poprawki planu). Przenieś go `git mv MIGRACJA/CLAUDE-NOWY.md CLAUDE.md` i popraw tylko ścieżki, które w A2 wyszły inaczej (np. nazwy plików obszarów). Zawiera:
   - zasady użytkownika: aktualne brzmienie, krótko, z odsyłaczem do `dokumentacja/ZASADY-UZYTKOWNIKA.md` (A2, N1);
   - protokół weryfikacji (A2, §3);
   - start sesji (hook wypisuje stan);
   - nawigacja: „szukasz wiedzy → `GaleriaFolderow/MAPA.md` §1”;
   - reguły pisania dokumentacji (§8 tego planu);
   - archiwum: „tylko historia, przez grep, nie źródło prawdy”;
   - pliki zamrożone, kondensacja `/kondensacja`, odkładanie zmian do CHANGELOG + STATUS (§5);
   - STATUS nadpisywany przez **każdą** sesję, która coś zmieniła (nie tylko przy nowej wersji; U9);
   - kiedy działają zmiany: hooki i `settings.json` od razu, CLAUDE.md i agenci w nowej sesji (U8);
   - wszystkie ścieżki w backtickach liczone od korzenia repo, bez ręcznych rozmiarów (U7);
   - znane ograniczenie: hooki wymagają `python3` (jest w chmurze; lokalnie na Windowsie bez niego nie działają);
   - cel ≤ 11 KB (wersja 4.2 pliku zmierzona przed wysłaniem do Foldery).
2. **`GaleriaFolderow/STATUS.md`** ≤ 6 KB (nadpisywany przez każdą sesję ze zmianami): wersja, ostatnia sesja (gałąź, data), zrobione ostatnio, następne zadanie, decyzje czekające na właściciela, kolejka kondensacji (pliki zamrożone w kolejności) i obszary ze zmianami odłożonymi do kondensacji. Otwarte sprawy są tylko w `dokumentacja/BACKLOG.md`; STATUS do niego odsyła, nie kopiuje (U9).
3. **`MAPA.md`**:
   - §0 bez zmian;
   - §1 = tabela zadanie → plik z adnotacją rozmiaru w KB, np. „(28 KB)”, sprawdzaną przez `doc_check` (M7a);
   - §2 bez zmian;
   - §3 (checklista dostawy) → jedna linia „procedura: skill `/dostawa`” (M12);
   - §4 code map **usunięta** z MAPA (U3): wygenerowana mapa rośnie z kodem i w pliku z limitem 40 KB zablokowałaby kiedyś scalanie. Zostaje jedna linia „mapa kodu na żądanie: `python3 tools/mapa_kodu.py` (`-c Klasa`, `-f regex`)”. Przedtem sprawdź, czy §4 to czysty wynik generatora: `diff <(python3 tools/mapa_kodu.py) <(sed -n '/^## 4\./,/^## 5\./p' MAPA.md)`. Ręczne dopiski, jeśli są, idą do odpowiednich plików `architektura/` (wpis w KONKORDANCJA.tsv). Pełna §4 zostaje w `/archiwum/MAPA-do-v4.37.9.md`;
   - §5–§8 bez zmian;
   - §9 usunięty (→ STATUS.md, CHANGELOG);
   - cel ≤ 40 KB (bez §3, §4 i §9 wyraźnie poniżej [ASSUMPTION; zmierzyć bajty po zmianie]).
4. **EFFORT-ZASADY.md**: §6 pkt 10 → jedna linia z odsyłaczem do `/CLAUDE.md` (M12); §5 → skill `/przekazanie` (A5), w pliku linia z odsyłaczem.
5. **`tools/doc_check.py` v2.** Wszystkie odczyty idą przez `read()`, a rozmiary to `len(read(x).encode())`, bo test mutacyjny podmienia `read`.
   1. Wersja `{ver}`:
      - `CHANGELOG.md` ma linię `- v{ver}` lub `- **v{ver}`;
      - `STATUS.md` zawiera `v{ver}`;
      - README linia 1 `(wersja {ver})`;
      - (bez sprawdzania MAPA §4, bo jej już nie ma, U3).
      - Czy STATUS, CHANGELOG i dokumentacja zmieniły się razem z kodem, sprawdza strażnik pushu na `main` (różnica gałęzi, Załącznik H), bo `doc_check` widzi tylko pliki, nie zmiany (U1).
      - **Bez** wymogu wpisu w architekturze (to on napędzał narastanie).
   2. Limity bajtów:
      - `../CLAUDE.md` ≤ 11 000;
      - `../.claude/rules/*.md` ≤ 36 000 (T11);
      - `../.claude/agent-rules.md` ≤ 9 000 znaków (limit `additionalContext` 10 000, T11);
      - `MAPA.md` ≤ 40 000;
      - `STATUS.md` ≤ 6 000;
      - każdy `dokumentacja/**/*.md` ≤ 40 000 (poza `migracja/`).
   3. Adnotacje „(N KB)” w MAPA §1 w pełnych KB, zgodne z rzeczywistym rozmiarem z tolerancją max(10%, 1 KB) (N7).
   4. Martwe odsyłacze: ścieżki w backtickach z końcówką `.md|.py|.sh|.bat|.txt|.tsv|.yml` istnieją. Baza jest stała (U7): w `../CLAUDE.md` **korzeń repo** (np. `GaleriaFolderow/tools/doc_check.py`, `.claude/agents/recenzent.md`); w MAPA §1 katalog `GaleriaFolderow/`. Za ścieżkę uznaje się całą zawartość pary backticków w jednej linii, bez spacji, `*`, `<` i `@` (to wzorce, polecenia i przykłady). Zawartość backticków w CLAUDE.md nie może zawierać znaku backtick (U7: podwójne backticki rozjeżdżają parowanie).
   5. `GaleriaFolderow/CLAUDE.md` nie istnieje albo ma ≤ 2 000 B (zakaz powrotu wielkiego pliku).
   6. `../.github/workflows/*.yml`: klucze pod `on:` (forma blokowa i inline, np. `on: push`, `on: [push, workflow_dispatch]`) to **wyłącznie** `workflow_dispatch` (lista dozwolonych, nie zakazanych: łapie też `schedule`, `workflow_run`, `pull_request_target`, T8). Wszystkie odczyty przez `read(<dokładna ścieżka względna>)`, a katalogi listuje `os` (wzorzec testu mutacyjnego).
   7. Pliki z nagłówkiem „stan: skondensowany” (etap B) nie zawierają lead-inów wersji (wzorzec `^\*\*v\d+\.`, nie tylko `**v4.`, SK12; M7c).
   8. Każdy plik `dokumentacja/architektura/*.md` i `dokumentacja/spec/*.md`, którego nie ma w `ZAMROZONE.tsv` (czyli nowy po migracji), musi mieć nagłówek „stan: skondensowany” (N8).
   9. `../.claude/rules/galeria-niezmienniki.md` zaczyna się od `---` w linii 1, zawiera `paths:` z `GaleriaFolderow/galeria.py` i zamykające `---`. Zepsuty YAML sprawiłby, że reguła (~15k tok.) ładowałaby się w każdej sesji na starcie [SOURCE: CC memory.md, „Rule frontmatter reference”] (N6).
   10. Żaden plik w `../.claude/hooks/` nie zawiera znaku `\r` (CRLF; dla Pythona to higiena, nie awaria), a definicje `../.claude/agents/*.md` i `../.claude/skills/*/SKILL.md` mają `---` w linii 1 oraz pole `name` (agenci) i `description`. Literówka w polu jest ignorowana bez komunikatu, a plik bez `name` jest pomijany (O0 §4, O2 §B1).
   11. Pliki zamrożone (U2): dla każdego wiersza `GaleriaFolderow/dokumentacja/migracja/ZAMROZONE.tsv` (`ścieżka	sha256`, ścieżki od korzenia repo) plik musi istnieć i albo mieć sha256 równy zapisanemu, albo mieć w pierwszych 10 liniach „stan: skondensowany” (wtedy jest już normalnym plikiem). Komunikat błędu: „plik zamrożony X zmieniony bez kondensacji: cofnij zmianę (`git checkout origin/main -- X`), zapisz ją w CHANGELOG + STATUS albo uruchom `/kondensacja X`”. Wypisuje (bez błędu) liczbę plików jeszcze zamrożonych. Sha liczone **jedną formułą** w `doc_check` i w `konkordancja.py --zamroz`: `sha256(read(p).encode("utf-8"))` (SK11). Pkt 11 szuka nagłówka w pierwszych 10 liniach licząc frontmatter (SK10).
   12. `../CLAUDE.md` nie zawiera adnotacji rozmiaru `(N KB)` ani `(Nk tok.)`: rozmiary są tylko w MAPA §1, gdzie pilnuje ich pkt 3 (U7).
6. **`tests/test_logic.py`**, blok „v47+ dokumentacja” (~l. 10433–10454):
   - mutacja wersji 9.99.9 musi dać komunikaty z `CHANGELOG`, `STATUS`, `README` (`len ≥ 3`);
   - nowe mutacje: fałszywy `../CLAUDE.md` 12 000 B → błąd limitu; MAPA §1 z nieistniejącą ścieżką → błąd odsyłacza; workflow z `push:` → błąd CI; jeden bajt dopisany do pliku zamrożonego → błąd pkt 11; ten sam plik z nagłówkiem „stan: skondensowany” → bez błędu; `(28 KB)` w `../CLAUDE.md` → błąd pkt 12.
7. **`ZAMROZONE.tsv`** (ostatni krok A4, po A3.4 i po nagłówkach): `konkordancja.py --zamroz` odmawia, gdy plik już istnieje (wyjątek: w sesji migracji po poprawkach recenzenta A6.4, z opcją `--nadpisz`; SK6), i zapisuje sha256 wszystkich plików przeniesionych dosłownie, czyli `architektura/*`, `spec/*`, `OGRANICZENIA.md`, `PLIKI.md`, `SRODOWISKO-TESTY.md`, `.claude/rules/galeria-niezmienniki.md`, części `ai/USUWANIE-OBIEKTOW-*.md`. **Nie zamrażać**: `ZASADY-UZYTKOWNIKA.md` (dziennik oryginalnych brzmień reguł: nowa reguła właściciela = obowiązujące brzmienie w `/CLAUDE.md` + oryginał z datą dopisany na końcu), `BACKLOG.md` (żywa lista), `CHANGELOG.md`, `ai/README.md`, MAPA, EFFORT-ZASADY, README.txt.
   
   Test `ast`/źródeł zakazujących napisów sprawdzić grep-em przed zmianą komunikatów (MAPA §7).
8. `./tools/testy.sh logic` zielone (+ pełne `testy.sh` przed A6).

### A5. Hooki, ustawienia, agenci, skille
Szkice hooków z Raportu §6 są **nieaktualne**. Obowiązuje Załącznik H: jeden plik `hooks.py` z podpoleceniami, kopiowany dosłownie (`cp MIGRACJA/hooks/hooks.py .claude/hooks/hooks.py`), nigdy przepisywany przez model.

**Wywołanie hooków (T2, U5, SK1):** forma powłoki ze sprawdzeniem istnienia pliku, bez `args`:
`"command": "[ ! -f \"$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py\" ] || exec python3 -I \"$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py\" <podpolecenie>"`.
Powód: `python3` z nieistniejącym plikiem kończy się kodem 2, co w PreToolUse blokuje **każde** Bash, Edit i Write, także naprawę [MEASURED: sceptyk, `claude -p` z hookiem bez pliku → „hook error … echo never executed”, n=1]. Do braku pliku dochodzi np. przy `git checkout` commita sprzed migracji albo wycofaniu (§7). Z warunkiem brak pliku = kod 0 (test SK1 w `test_hooks.sh`). Bit wykonywalności nie jest potrzebny, a CRLF Pythonowi nie szkodzi. **Kolejność:** `cp hooks.py` → `test_hooks.sh` → dopiero wpis w `settings.json`.

**`.claude/settings.json` → `permissions.deny`:**
- `Bash(git push --force*)`, `Bash(git push -f*)`, `Bash(git push * --force*)`, `Bash(git push * -f*)`: pierwsza warstwa; właściwą robotę robi `hooks.py bash`;
- narzędzia zapisu GitHub MCP, które omijałyby hooki na Bash (M15, T7): `mcp__github__push_files`, `mcp__github__create_or_update_file`, `mcp__github__delete_file`, `mcp__github__merge_pull_request`, `mcp__github__enable_pr_auto_merge`, `mcp__github__update_pull_request_branch`, `mcp__github__actions_run_trigger` (zużywa minuty Actions);
- `Bash(gh pr merge*)`, `Bash(gh api *merge*)`. To dopasowanie tekstu, więc miękkie (O0 §4); `gh pr` i tak odrzuca proxy chmury (GraphQL) [SOURCE: CC cloud-environments part2 „GitHub proxy”];
- **bez** deny na `backup/` i na zip (T6): reguła Edit/Read obejmuje też `cp` do tej ścieżki [MEASURED: exceptions.md 2026-10-08], więc zablokowałaby backup z `/dostawa`. Ochrona `backup/` jest w `hooks.py edit` (tylko narzędzia Edit/Write).

**`hooks`** (zdarzenie → podpolecenie):
- SessionStart `startup|resume|compact` → `session` (`timeout: 60`);
- UserPromptSubmit → `turn`;
- SubagentStart → `subagent`;
- PreToolUse `Bash` → `bash` (`timeout: 120`);
- PreToolUse `Edit|Write` → `edit`;
- Stop → `stop` (`timeout: 60`).

**Co robi `hooks.py`** (szczegóły i lista przypadków: Załącznik H):
- `bash`: tokenizacja `shlex` per podpolecenie (T1), zdejmuje nakładki (`timeout`, `nice`, `env`, `command`, `if`, nawiasy itd.), śledzi `cd` i `git -C` (SK4); `HEAD`/`@` na gałęzi `main` = push na `main`; ref z `$` albo backtickiem → blokada „podaj gałąź wprost”; force-push, `--mirror`, `+refspec`, `filter-branch/-repo` → blokada; przy **każdym** `git push` sprawdza wyzwalacze workflow na dysku i w HEAD (tylko `workflow_dispatch`, U6); przy pushu na `main` dodatkowo reguły różnicy gałęzi względem `origin/main` (U1: STATUS.md zmieniony; przy zmianie `galeria.py` także CHANGELOG.md oraz `dokumentacja/` lub `.claude/rules/`, albo linia „docs: bez zmian (powód)” w CHANGELOG) i zielony `doc_check` (uruchamiany bez `-I`, limit 80 s, SK7, SK13); push na `main` w tym samym wywołaniu co `fetch`/`checkout`/`merge`/`commit` → blokada, bo hook widzi stan sprzed polecenia (SK5: scalanie i push to osobne wywołania, także w `/dostawa`); brak `origin/main` albo merge-base → blokada (SK2); `BACKLOG.md`, `ZASADY-UZYTKOWNIKA.md`, `migracja/` nie liczą się jako dokumentacja (SK3); gdy `origin/main` ma `ZAMROZONE.tsv`: wolno w nim tylko usuwać wiersze, a kondensacja i zmiana `galeria.py` w jednej gałęzi → blokada (SK6); stan repo z `cwd` wejścia (S4); push gałęzi sesji przechodzi zawsze, jeśli workflow są poprawne; błąd samego strażnika przy `git push` → blokada z komunikatem (fail-closed), przy innych poleceniach strażnik się nie uruchamia;
- `edit`: zapis do `/GaleriaFolderow/backup/` → blokada; zapis workflow → strażnik składa plik wynikowy (Write: `content`; Edit: bieżący plik z zamianą `old_string`→`new_string`) i sprawdza wyzwalacze (T8);
- `turn` / `stop`: stan tury = HEAD + `git status -z` + rozmiar i `mtime_ns` każdego zmienionego pliku (wykrywa ponowną edycję, T5; tańsze niż `git diff --binary` przy zipie 20 MB); `turn` milczy (N5); `stop` przy zmianie bez „Zmiany w tej odpowiedzi” zwraca `additionalContext`, co kontynuuje turę z limitem 8 [SOURCE: CC hooks part7 „Stop decision control”];
- `session`: APP_VERSION, gałąź, za/przed `origin/main` (gdy gałąź jest i za, i przed: `git merge --no-edit origin/main`, SK15), 40 linii STATUS.md;
- `subagent`: treść `.claude/agent-rules.md` jako `additionalContext`;
- `turn`, `stop`, `session`, `subagent` **zawsze kończą się kodem 0**, także przy złym JSON-ie i błędzie (U5).

**`.claude/agent-rules.md`** (≤ 9 000 znaków, pilnuje `doc_check`; wstrzykiwany przez `hooks.py subagent`): lista z Raportu §6 (nie zmieniaj `APP_VERSION`, `backup/`, dokumentacji, zipa ani `main`; zmieniaj tylko swoje funkcje i testy; test najpierw musi paść; testy GUI tylko pod `flock /tmp/galeria_gui.lock` z własnym `TMPDIR`; raport: co zmieniłeś, dowód, czego nie uruchomiłeś, decyzje bez pytania, „nic nie znalazłem” dozwolone; nie pytasz właściciela; odmowy uprawnień w raporcie).

**Agenci i skille:**
- `.claude/agents/recenzent.md` (Read, Grep, Glob; `model: opus`, `effort: high`);
- `.claude/agents/wykonawca.md` (`isolation: worktree`, `disallowedTools: Agent`, `model: opus`, `effort: high`, w treści: „przed uruchomieniem wykonawców: commit + push + scalenie albo `worktree.baseRef: "head"`”);
- `.claude/skills/dostawa/SKILL.md` = dawna MAPA §3 jako kroki (źródło jedyne, M12; oryginał w `/archiwum/MAPA-do-v4.37.9.md`). Scalenie (`fetch`, `checkout main`, `merge`) i `git push origin main` jako **osobne** wywołania Bash (SK5), potem powrót na gałąź sesji. Gdyby `cp` do `backup/` było blokowane (prowokacja A6), backup przez `python3 -c "import shutil; …"`;
- `.claude/skills/przekazanie/SKILL.md` = dawne EFFORT-ZASADY §5 + szablon promptu.

- `.claude/skills/kondensacja/SKILL.md` (U2, D10): argument = plik zamrożony; kroki: przeczytaj plik w całości; kod jest arbitrem (`tools/mapa_kodu.py -f`); scal warstwy „vX supersedes” do stanu obecnego; uwzględnij zmiany odłożone w CHANGELOG (STATUS wskazuje od której wersji); historia zostaje w CHANGELOG i archiwum; nagłówek „stan: skondensowany v<wersja>” zamiast nagłówka zamrożenia, nazwa pliku bez zmian; agent `recenzent` dostaje stary (`git show origin/main:<plik>`) i nowy plik i szuka zgubionych reguł i zmienionych znaczeń; usuń plik z kolejki w STATUS; osobny commit, bez zmian kodu.

**Testy (U5):** `cp MIGRACJA/hooks/test_hooks.sh GaleriaFolderow/tools/test_hooks.sh` (tu, w A5, bo `/CLAUDE.md` do niego odsyła, SK8), potem `bash GaleriaFolderow/tools/test_hooks.sh .claude/hooks/hooks.py` → `WYNIK: 82/82` (repo testowe w katalogu tymczasowym, nic nie dotyka Foldery). Każda późniejsza zmiana `hooks.py`: najpierw ten test na kopii.

**Gdy klasyfikator odrzuca zapisy w `.claude/`** (chroniona ścieżka, „Self-Modification”, M11): według D9 przełączasz sesję na „Accept edits” i zatwierdzasz zapis. W ostateczności pliki trafiają do `/MIGRACJA/staging/.claude/…`, a Ty przenosisz je na GitHubie (Add files); po wgraniu sesja uruchamia test hooków i prowokacje A6, bo wgranie może zmienić końcówki linii (A1).

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
   - druga edycja już zmienionego pliku → przypomnienie (T5);
   - (U6) `sed -i` dodający `push:` pod `on:` w workflow, potem `git push --dry-run origin HEAD` (gałąź sesji) → blokada; przywrócić plik;
   - (U1, SK1) próba w osobnym worktree, nie przez `git checkout` w głównej kopii (usunąłby `.claude/hooks/hooks.py` z dysku): `git worktree add -b probe /tmp/probe origin/main`; w **osobnym** wywołaniu Bash `cd /tmp/probe && printf '\n' >> GaleriaFolderow/galeria.py && git commit -qam probe`; w kolejnym `cd /tmp/probe && git push --dry-run origin HEAD:main` → blokada „STATUS.md nie zmieniony”; potem `git worktree remove --force /tmp/probe && git branch -D probe`;
   - (SK7) `git push --dry-run origin HEAD:main` na kompletnej gałęzi migracji przy zielonym `doc_check` → **musi przejść**;
   - (U2) jeden znak dopisany do pliku zamrożonego → `doc_check` czerwony z komunikatem pkt 11; przywrócić;
   - (U5) `hooks.py turn` i `stop` z wejściem „nie json” → kod 0 (to robi też `test_hooks.sh`).
2. Read `GaleriaFolderow/galeria.py` (`limit: 50`) → komunikat „Loaded … galeria-niezmienniki.md”. Jeśli reguła utworzona w trakcie sesji się nie wczyta, rozstrzyga A7.2.
3. `./tools/testy.sh` (K6, K7), konkordancja 100% względem SHA z A3.3 (K4), `doc_check` (K3).
4. **Recenzent** (general-purpose, model opus, tylko odczyt): sprawdza konkordancję, nowy CLAUDE.md, MAPA, `doc_check`, hooki i treść agent-rules. Każde istotne znalezisko: poprawka albo odrzucenie z dowodem.
5. Paczka zip tej samej wersji, STATUS.md (z kolejką kondensacji, D10), usunięcie `/MIGRACJA/` (prócz `KONKORDANCJA.tsv` i `ZAMROZONE.tsv` w `dokumentacja/migracja/`; `konkordancja.py` przenieść tam też; commit; to musi być przed scaleniem, żeby `MIGRACJA/` nie trafiła na `main` (SK8)).
6. Scalenie do `main` według reguły scalania (zanotować SHA przed i po). **Jeśli klasyfikator odrzuci scalenie** (zmiana `/CLAUDE.md` i `.claude/` = „Self-Modification”, findings.md 2026-10-06, n=2; T4):
   - sesja uruchamia `doc_check`, `testy.sh` i `git push --dry-run origin HEAD:main` (ta sama bramka co hook, nic nie wysyła; SK9), wypycha gałąź i otwiera PR (`create_pull_request`, którego plan nie blokuje);
   - Ty scalasz na GitHubie;
   - to samo czeka każdą przyszłą sesję zmieniającą `/CLAUDE.md` lub `.claude/`; wpisać to do `/CLAUDE.md`.
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

## 5. Etap B: kondensacja (po jednym pliku na sesję)

- **Zakres (U2):** wszystkie pliki z `ZAMROZONE.tsv`, nie tylko `architektura/` i `spec/`. Kolejność w STATUS.md: najpierw `.claude/rules/galeria-niezmienniki.md` (ładuje się przy każdej pracy z kodem, ~15k tokenów z historią), potem obszary najczęściej zmieniane.
- **Kto i kiedy (D10):** osobne sesje, które zlecasz: „`/kondensacja <plik>`”. Bez „przy okazji”: sesja zadaniowa jest skupiona na zadaniu i odkładałaby kondensację stale [ASSUMPTION].
- **Zanim plik zostanie skondensowany** sesja zadaniowa **nie zmienia go** (`doc_check` pkt 11 to blokuje). Zmianę zapisuje w CHANGELOG (linia wersji) i w STATUS („obszar X: zmiany od vY w CHANGELOG, do kondensacji”), a przy pushu na `main` używa linii „docs: bez zmian (obszar X zamrożony)”, jeśli nie zmieniła innego pliku dokumentacji. Nowy niezmiennik przed kondensacją niezmienników: kondensuje się najpierw plik niezmienników (dlatego jest pierwszy w kolejce).
- **Kondensacja** (skill `/kondensacja`, A5): plik przepisany do stanu obecnego, kod arbitrem, nagłówek „stan: skondensowany v<wersja>”, recenzent porównuje stary i nowy plik, osobny commit.
- **Twarde granice:** plik zamrożony zmieniony bez nagłówka → czerwony `doc_check` (pkt 11); nagłówek dodany bez przepisania → czerwony, bo plik dosłowny ma lead-iny `**v4.` (pkt 7); nowy plik w `architektura/`/`spec/` bez nagłówka → czerwony (pkt 8). Jakości samego przepisania pilnuje tylko recenzent (miękkie).
- Koniec etapu B: `ZAMROZONE.tsv` bez plików niezmienionych → usunąć `/archiwum/` (zostaje w git).
- Koszt: ok. 15–18 sesji × ~1 h [ASSUMPTION].

## 6. Ryzyka

| Ryzyko | Prawd. | Zapobieganie |
|---|---|---|
| Utrata informacji | niskie w A (konkordancja 100%), średnie w B | A3.3; w B recenzent per obszar + archiwum |
| Rozjazd strażnika i dokumentów | wysokie bez jednego commitu | A4 w jednym commicie, testy przed pushem |
| Klasyfikator odrzuca zapisy `.claude/` / CLAUDE.md | średnie (findings.md 2026-10-06, n=2) | ścieżka `staging/` (A5) |
| Zły hook blokuje pracę | niskie | testy JSON, prowokacje; awaryjnie `--settings '{"disableAllHooks": true}'` (CC hooks.md) |
| Hook po cichu nie działa albo blokuje wszystko (ścieżka, brak pliku) | średnie | forma powłoki z warunkiem istnienia (SK1), prowokacje A6.1 |
| Pliki w etapie A są „warstwowe”, mogą zawierać sprzeczne akapity | pewne do czasu B | nagłówek „nowszy zastępuje starszy” (jak dziś), kondensacja przy dotknięciu obszaru |
| `git mv` jednak wczytuje stary plik (niezweryfikowane) | niskie | sprawdzenie transkryptu w A0.2; jeśli wczytał, praca dalej działa, tylko drożej |
| Agenci workflow bez SubagentStart (niezweryfikowane) | nieznane | reguły dla agentów powtarzać w promptach workflow |
| GitHub MCP, `gh` lub skrypt omija hook (np. push z wnętrza skryptu) | niskie | deny narzędzi MCP i `gh pr merge`/`gh api *merge*`; pełna ochrona tylko branch protection (D6) |
| Scalenie odrzucone przez klasyfikator | średnie | PR + scalenie przez Ciebie (A6.6, T4) |
| Dokumentacja nie nadąża za kodem po migracji (U1) | wysokie bez strażnika | reguły różnicy przy pushu na `main` (H); świadome obejście tylko jawną linią „docs: bez zmian (powód)” |
| Warstwy odrastają w plikach dosłownych; etap B się nie kończy (U2) | wysokie bez zamrożenia | `ZAMROZONE.tsv` + `doc_check` pkt 7, 8, 11; sesje kondensacji zlecane przez Ciebie (D10) |
| Pilna poprawka w pliku zamrożonym | średnie | zapis w CHANGELOG + STATUS albo `/kondensacja` tego pliku |
| Hook z CRLF blokuje Bash albo każdy prompt (U5) | było: średnie | hooki w Pythonie, nieblokujące zawsze exit 0, test CRLF |
| Push z wnętrza skryptu, `git` przez alias lub `sh -c` omija strażnika | niskie | znane ograniczenie (O0 §4); twardo tylko branch protection (D6) |

## 7. Wycofanie
- Przed scaleniem: porzucić gałąź; `main` nietknięty.
- Po scaleniu: przywrócenie drzewa jednym commitem „do przodu” (T13; `git merge --no-edit` z MAPA §3 tworzy commit scalenia, gdy `main` się przesunął, więc `revert` zakresu by się nie udał): `git restore --source=<stary_main> --staged --worktree :/ && git commit -m "Wycofanie migracji dokumentacji"` i push, bez przepisywania historii.

## 8. Reguły dla następców (wpisywane w `/CLAUDE.md`)
- Wiedza: jeden fakt w jednym miejscu; nowy obszar → nowy plik (od razu „stan: skondensowany”) + wiersz w MAPA §1 z rozmiarem w KB.
- Obszar zmieniony → plik obszaru przepisany do stanu obecnego, jeśli jest skondensowany; jeśli zamrożony → zmiana w CHANGELOG + STATUS (§5). Linia w CHANGELOG przy każdej wersji; STATUS nadpisany przez każdą sesję ze zmianami.
- Pliki do czytania w całości ≤ 40 KB (jeden Read); większe dzielić. `doc_check` pilnuje limitów, odsyłaczy, zamrożenia i formatu; strażnik pushu pilnuje, żeby dokumentacja zmieniała się razem z kodem.
- Ścieżki od korzenia repo, bez ręcznych rozmiarów poza MAPA §1. Bez `@` importów dużych plików; nigdy `@a.md, @b.md` z przecinkiem.
- Hook najpierw testem (`test_hooks.sh`), potem zapis do `.claude/hooks/`: działa od razu po zapisaniu.
- Po zmianie modelu: pomiar bajtów na token (`/context` z importami) i korekta limitów (O0 §9). Raz na kwartał `/doctor prompt-audit` na `/CLAUDE.md` i `.claude/` (O0 §6); data ostatniego audytu w STATUS.

---

## Załącznik H: `hooks.py` i test

Pliki: `reports/foldery-hooks/hooks.py` i `reports/foldery-hooks/test_hooks.sh` w ClaudeEXPERT (w Foldery: `MIGRACJA/hooks/`). Kopiować `cp`, nie przepisywać. Zastępuje Załącznik S wersji 4.1 (kod `guard_bash.py` wszedł do `hooks.py` jako podpolecenie `bash`, logika force/main rozszerzona po recenzji sceptyka, SK4–SK5; 22 przypadki zachowane).

Wpis w `settings.json` (przykład, forma powłoki, SK1): `{"type":"command","command":"[ ! -f \"$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py\" ] || exec python3 -I \"$CLAUDE_PROJECT_DIR/.claude/hooks/hooks.py\" bash","timeout":120}`.

`bash test_hooks.sh hooks.py` buduje w katalogu tymczasowym repo z atrapą `origin`, `doc_check` (czerwony przy `RED=1`) i workflow, i sprawdza 82 przypadki: 22 z dawnego Załącznika S, worktree (S4), reguły różnicy (U1), workflow i parser `on:` (U6), `edit`, `turn`/`stop`, odporność na zły JSON i CRLF, 22 z recenzji sceptyka. Lista z opisem: `foldery-migration-plan-recenzje.md`, Załącznik H-lista.

[MEASURED: `bash test_hooks.sh hooks.py` → `WYNIK: 82/82`, 2026-10-08, Linux, Python 3, git; poza Claude Code, czyli bez sprawdzenia, jak Claude Code przekazuje wejście: to sprawdzają prowokacje A6.]

Znane granice: strażnik nie widzi pushu z wnętrza skryptu, przez alias git ani `sh -c "…"` (O0 §4); reguła „docs: bez zmian (powód)” jest furtką z zapisem, nie oceną treści; jakość treści dokumentacji ocenia tylko recenzent.

## Załączniki recenzji
Decyzje z recenzji (R: „meta” M1–M15, N1–N8; T: techniczna T1–T13; U: trwałość U1–U10) są w `reports/foldery-migration-plan-recenzje.md` (w Foldery: `MIGRACJA/RECENZJE.md`). Wykonawca ich nie potrzebuje: plan już je uwzględnia.
