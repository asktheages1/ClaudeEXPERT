# Analiza systemu dokumentacji repozytorium asktheages1/Foldery (gałąź `main`)

Data: 2026-10-08 · Claude Code 2.1.294 · model sesji: Opus 5.5 · Foldery HEAD `be31a48` (ten sam, który mierzyła poprzednia sesja).
Pliki Foldery czytałem przez GitHub MCP jako dane (bez klonowania: `git clone` zablokował klasyfikator auto mode, Załącznik B). Kopie zgadzają się bajt w bajt (hash obiektu git = SHA z GitHuba).

Słowniczek pojęć używanych niżej (każde wyjaśnione też przy pierwszym użyciu):
- **token**: jednostka, w której model liczy tekst; polski markdown to ok. 2 bajty na token.
- **kontekst / okno**: wszystko, co model „ma przed oczami” w danej rozmowie (1M tokenów dla Opus 5.5). Każde zapytanie wysyła je w całości od nowa.
- **subagent / agent**: osobna instancja Claude uruchamiana przez główne okno, z własnym, pustym kontekstem.
- **hook**: skrypt, który Claude Code (program, nie model) uruchamia sam w określonym momencie, np. przed każdym poleceniem. Kod wyjścia 2 = blokada.
- **reguła deny**: wpis w `.claude/settings.json`, który program egzekwuje niezależnie od tego, co model postanowi.
- **commit / push / merge / gałąź (branch)**: zapis zmiany w git / wysłanie jej na GitHuba / scalenie dwóch linii zmian / osobna linia zmian.
- **CI**: automatyczne testy na serwerach GitHuba (GitHub Actions).
- **branch protection**: ustawienie GitHuba, które serwer egzekwuje (np. „nie wolno pushować na `main` bez zielonego testu”).

---

## 1. Werdykt

1. System Foldery jest dopracowany merytorycznie (reguły z datami i powodami, mapa zadanie → co czytać, strażnik `tools/doc_check.py`), ale **architektura ładowania jest odwrócona**. Cała wiedza siedzi w jednym zagnieżdżonym pliku `GaleriaFolderow/CLAUDE.md` o wadze **239,9k tokenów**. Claude Code wstawia go w całości do kontekstu przy pierwszym dotknięciu dowolnego pliku w `GaleriaFolderow/`. Dostaje go wtedy i główne okno, i każdy subagent, także Explore [MEASURED, Załącznik B].
2. Instrukcje typu „czytaj tylko §1 i §6” albo „nie czytaj CLAUDE.md od góry do dołu” (MAPA §1) nic nie zmieniają: plik jest już w kontekście cały.
3. Plik rośnie z założenia. `doc_check.py` wymaga nowego wpisu `vX` w §4 i §8 przy każdej wersji, a reguła „newest first, newer supersedes older” dokłada akapity zamiast je przepisywać. W efekcie 70% pliku to historia (§4 architektura 113k tokenów, §8 changelog 55k) [ASSUMPTION: proporcja z liczby znaków].
4. Rozmiary podane w samych dokumentach są nieaktualne o czynnik 2–3 (np. „MAPA.md ≈20 KB”, a ma 60 KB). Pliki oznaczone „czytaj najpierw / czytaj całość” przekraczają limit jednego Read (25k tokenów), więc zwykłe przeczytanie daje tylko początek pliku (PARTIAL view).
5. **Żadna reguła nie jest egzekwowana twardo.** Nie ma `.claude/` (hooków, deny, agentów, skilli). Co gorsza, `.gitignore` zawiera `.claude/`, więc nawet gdyby sesja je utworzyła, nigdy nie trafią do repozytorium.
6. Rozwiązanie:
   - krótki główny `CLAUDE.md` w korzeniu repo (≤ 5k tokenów);
   - niezmienniki kodu jako reguła `.claude/rules/` z `paths: GaleriaFolderow/galeria.py` (ładuje się tylko przy pracy z kodem);
   - architektura podzielona na pliki ≤ 20k tokenów w `dokumentacja/`, czytane na żądanie przez tabelę z MAPA;
   - changelog poza ładowanym tekstem;
   - hooki i deny dla reguł „nigdy” i „zawsze”;
   - agent recenzent i skill „dostawa” zamiast powtarzania procedur w czterech miejscach.
7. Zysk: kontekst stały spada z ~240k do ~5k tokenów, a przy pracy z kodem do ~20k, dla każdego okna i każdego agenta [ASSUMPTION: z budżetów w §5].
8. Migracja to jedna sesja „tylko dokumentacja” z jednoczesną zmianą `doc_check.py` i testu w `test_logic`. Inaczej testy zrobią się czerwone (§7).

---

## 2. Inwentarz

Kolumna „Ładuje się” opisuje stan **dziś** dla sesji w chmurze z jednym repo (start w korzeniu `/home/user/foldery`). W korzeniu repo nie ma CLAUDE.md ani `.claude/`, więc na starcie sesja nie ma **żadnych** instrukcji projektu.

| Plik | Bajty | Linie | Tokeny | Ładuje się | Kto dostaje |
|---|---:|---:|---:|---|---|
| `GaleriaFolderow/CLAUDE.md` | 543 094 | 4 711 | **239,9k** [MEASURED: `/context`, import w katalogu testowym] | Automatycznie, w całości, przy pierwszym Read/Write/Edit pliku z `GaleriaFolderow/` (docs) oraz przy `cat`/`head` takiego pliku w Bash; nie przy Grep ani `python3 open()` [MEASURED n=1, Załącznik B] | Główne okno; general-purpose; **Explore też** [MEASURED n=1]; zapewne każdy agent, który dotknie folderu |
| `GaleriaFolderow/MAPA.md` | 59 995 | 397 | **29,4k** [MEASURED] | Tylko gdy model sam go otworzy (polecenie w nagłówku CLAUDE.md) | Kto przeczyta; jeden Read daje PARTIAL view (> 25k) [SOURCE: O0 §1] |
| `GaleriaFolderow/README.txt` | 97 643 | 1 013 | **47,8k** [MEASURED] | Na żądanie (podręcznik użytkownika) | j.w., ≥ 2 Read |
| `dokumentacja/ai/USUWANIE-OBIEKTOW.md` | 85 466 | 750 | **44,8k** [MEASURED] | Na żądanie; prompt następcy każe czytać „CAŁĄ” | j.w., ≥ 2 Read |
| `EFFORT-ZASADY.md` | 19 109 | — | ~9,5k [ASSUMPTION: 1,9–2,0 B/token zmierzone na plikach polskich obok] | Na żądanie (CLAUDE.md §2) | — |
| `dokumentacja/ai/PROMPT-NASTEPCA-v4.37.4.md` | 17 167 | — | ~8,5k [ASSUMPTION] | Gdy właściciel wklei / każe wykonać | — |
| `dokumentacja/ai/ANALIZA-PO-v4.37.3.md` | 16 287 | — | ~8k [ASSUMPTION] | Na żądanie | — |
| `dokumentacja/ai/README.md` | 601 | — | ~0,3k [ASSUMPTION] | Na żądanie | — |
| `PROPOZYCJA-*.md` (3) | 8 080–11 944 | — | 4–6k każdy [ASSUMPTION] | Na żądanie | — |
| `WIZUALIZACJA-*.html` (3) | 61 379–941 063 | — | — | Nie dla modelu (dla człowieka) | — |
| `tools/doc_check.py` | 1 979 | — | — | Uruchamiany przez `testy.sh` i koniec `test_logic` | Strażnik wersji w dokumentach |
| `.github/workflows/ai-windows.yml` | 5 554 | — | — | Tylko ręcznie (`workflow_dispatch`) | CI Windows |
| `.gitignore` | 22 | 2 | — | — | Zawiera **`.claude/`** (blokuje commit hooków/ustawień) |
| `backup/` (70 kopii `galeria.py`), zip 20 MB | ~90 MB | — | — | Nie dla modelu, ale każda sesja je klonuje | — |
| `galeria.py` | 1 805 270 | 39 588 [MEASURED przez poprzednią sesję] | — | Kod (> 256 KB: Read tylko z `limit`) | — |

Rozkład CLAUDE.md na sekcje (znaki, tokeny proporcjonalnie do zmierzonych 239,9k) [ASSUMPTION: proporcja znaków]:

| § | Znaki | ~Tokeny | Charakter |
|---|---:|---:|---|
| 1 Zasady współpracy | 3 325 | 1,5k | reguły (stałe) |
| 2 Pliki | 22 932 | 10k | inwentarz + pakowanie |
| 3 Środowisko i weryfikacja | 4 559 | 2k | procedura |
| 4 Architektura | 255 649 | 113k | opis kodu, warstwy historyczne |
| 5 Specyfikacja | 55 714 | 25k | uzgodnienia z użytkownikiem |
| 6 Niezmienniki | 30 189 | 13k | reguły kodu („nie psuj”) |
| 7 Ograniczenia | 31 757 | 14k | wiedza |
| 8 Changelog | 123 419 | 55k | historia (dubluje git log) |
| 9 Backlog | 14 618 | 6k | stan |

Kontekst sesji Foldery po pierwszym Read w `GaleriaFolderow/`:
- ~40k (system i narzędzia) + 240k = **~280k zanim padnie pierwsze słowo o zadaniu** [ASSUMPTION: start z O0 §1 + pomiar].
- Kompaktowanie w chmurze następuje przy ~784k (O0 §1).
- Po kompaktowaniu zagnieżdżony CLAUDE.md wypada i wraca w całości przy następnym dotknięciu folderu [SOURCE: CC context-window.md, 2026-10-08].

Koszt (cennik API, przy subskrypcji to zużycie limitów) [ASSUMPTION: obliczenie z cen w O5 §4]:
- Zapis 240k do cache: ~1,2 USD przy TTL 5 min (agenci), ~1,9 USD przy TTL 1 h (główne okno).
- Każde kolejne zapytanie: odczyt z cache ~0,05 USD.
- Sesja z 4 agentami, którzy dotkną folderu: ~5 USD tylko na wczytanie tego pliku.

---

## 3. Diagnoza

### Co działa
- **Deterministyczne strażniki w kodzie**: `doc_check.py`, `mm_check.py`, `ast_check.py` uruchamiane przez `testy.sh` i `test_logic` (z testem mutacyjnym). Dobry wzorzec: reguła sprawdzana skryptem, nie tekstem [SOURCE: pliki Foldery, be31a48].
- **Mapa „zadanie → co czytać”** (MAPA §1) i `tools/mapa_kodu.py` zamiast numerów linii. Dobra idea, tylko oparta na nieistniejącej możliwości czytania części CLAUDE.md.
- **Reguły użytkownika z datą i cytatem** (CLAUDE.md §1): zrozumiałe dla modelu, łatwe do audytu.
- **Wydzielenie dokumentacji AI do `dokumentacja/ai/`** (decyzja użytkownika z 2026-10-06): to dokładnie kierunek, który rekomenduję dla całości.
- **Prompt następcy** (`PROMPT-NASTEPCA-v4.37.4.md`): ma cel, dowody, punkty „zapytaj użytkownika”, podział na agentów, zakazy dla agentów, wymaganie dowodu. Wzorcowy, zgodny z O0 §8.

### Co się psuje (z dowodami)

**D1. Jeden plik 240k tokenów ładowany w całości wszystkim.**
- Dowód: [MEASURED: `/context` → 239,9k] oraz [MEASURED: probe1, Explore dostał zagnieżdżony CLAUDE.md i regułę `paths` po Read, n=1].
- Dokumentacja mówi, że Explore pomija CLAUDE.md [SOURCE: CC sub-agents.md, 2026-10-08]. Pomija jednak tylko pliki ładowane na starcie, a te ładowane przy czytaniu dostaje.
- Skutki:
  - koszt (§2);
  - spadek jakości przy dużym wypełnieniu kontekstu [SOURCE: CC best-practices.md: „performance degrades as it fills”];
  - przepadek reguł w środku długiego pliku [SOURCE: CC memory.md: „Longer files consume more context and reduce adherence”, cel < 200 linii; Foldery ma 4 711].

**D2. Mechanizm wzrostu jest wbudowany.**
- `doc_check.py` sprawdza, czy `v{APP_VERSION}` występuje w §4 i jako linia `- vX` w §8 (kod: `claude[claude.index("## 4. Architecture"):claude.index("## 5. Functional spec")]`) [SOURCE: tools/doc_check.py, be31a48].
- Każda wersja wymusza więc nowy akapit w opisie architektury.
- MAPA §3 pkt 2 każe dodać „§4 new paragraph at the TOP”, a MAPA §1 mówi „newest first, newer supersedes older”.
- Reguła z nagłówka („revise or delete entries that became stale, don't just append”) jest sprzeczna z tym, co wymusza strażnik. Strażnik wygrywa, bo jest twardy.

**D3. Nieaktualne liczby w dokumentach o dokumentach** [SOURCE: pliki Foldery vs MEASURED]:

| Twierdzenie | Gdzie | Stan faktyczny |
|---|---|---|
| MAPA.md ≈ 20 KB | CLAUDE.md wiersz 8 | 60 KB, 29,4k tokenów |
| galeria.py ~23k linii | CLAUDE.md §2 | 39 588 linii |
| CLAUDE.md ≈ 305 KB, §4 126 KB, §8 78 KB | MAPA §1 | 543 KB, §4 ~256 KB, §8 ~123 KB |
| plik ≈ 34 000 linii | MAPA §4 nagłówek | 39 588 |
| „24k-line galeria.py”, „written at v4.18.3” | MAPA nagłówek | v4.37.9 |

Żaden mechanizm nie pilnuje rozmiarów, więc każda liczba w tekście się starzeje.

**D4. Sprzeczne kopie tej samej reguły.**
- Nazwa paczki:
  - CLAUDE.md §1: `GaleriaFolderow_v<APP_VERSION>.zip`, „vN counter … history only”;
  - MAPA §8: „Zip name `GaleriaFolderow_vN.zip`”;
  - MAPA §3 pkt 3: „N = last „Paczki” number + 1”.
- Zipy w repo: CLAUDE.md §2 „the repo … also keeps the zips (`_v30`, `_v31`)” vs MAPA §3 „repo root keeps ONLY the newest zip”.
- Reguła dokumentacji występuje w 4 miejscach: nagłówek CLAUDE.md, §1, MAPA §3 pkt 2, EFFORT-ZASADY §6 pkt 10.
- Przy konflikcie model wybiera dowolnie [SOURCE: CC memory.md: „Claude may pick one arbitrarily”].

**D5. Pułapki limitu Read.**
- Read daje maks. 25k tokenów na wywołanie. Plik powyżej tego, czytany bez `offset/limit`, zwraca PARTIAL view, czyli tylko pierwszą część [SOURCE/CODE: O0 §1].
- Dotyczy to MAPA.md (29,4k), który CLAUDE.md każe „READ FIRST”, oraz USUWANIE-OBIEKTOW.md (44,8k), który prompt następcy każe czytać „CAŁĄ”.
- CLAUDE.md (543 KB > 256 KB) czytany Readem bez `limit` daje błąd [MEASURED: O0 §1]. Dziś to nie szkodzi, bo plik i tak ładuje się sam.

**D6. Wszystkie reguły „nigdy/zawsze” są miękkie.**
- Dotyczy: scalania z `main`, zakazu force-push, ręcznego CI, listy „Zmiany w tej odpowiedzi”, zielonego `doc_check` przed paczką i braku komentarzy w kodzie.
- To tekst, który model *zwykle* respektuje. Twarde są tylko deny, hook z exit 2, sandbox i branch protection [SOURCE: O0 §8; CC memory.md: „not a hard enforcement layer”].
- `.gitignore` z wpisem `.claude/` uniemożliwia dodanie twardych mechanizmów do repo [SOURCE: .gitignore, be31a48]. Sesja w chmurze czyta tylko to, co jest w klonie [SOURCE: CC settings.md, „Settings in cloud sessions”].

**D7. Agenci dostają reguły przypadkiem.**
- Preferencje użytkownika z claude.ai (po polsku, surowo itd.) nie trafiają do żadnego agenta [MEASURED: O0 §2].
- Reguły dla agentów istnieją tylko w ręcznie pisanych promptach (dobrych, ale jednorazowych).
- Jedyne, co agent dostaje automatycznie, to 240k tokenów całej historii projektu.

**D8. Stan i przekazanie pracy są rozproszone.**
- Stan żyje w trzech miejscach: MAPA §9 (120 linii, dopisywane, rośnie jak changelog), CLAUDE.md §9 i prompty `PROMPT-NASTEPCA-*`.
- Nowa sesja nie ma żadnego automatycznego „gdzie jesteśmy”: SessionStart nie istnieje, a CLAUDE.md w korzeniu nie istnieje.

**D9. Środowisko.**
- `tools/srodowisko.sh` instaluje PySide6/PyAV/Qt w każdej sesji (1–3 min). Skrypt setup środowiska chmury jest cache'owany jako obraz dysku [SOURCE: CC cloud-environments.md, „Setup scripts”; O0 §7].
- Repo waży ~90 MB w backupach i zipie, a każda sesja robi świeży klon.
- W tej sesji klasyfikator auto mode odmówił `git clone` (powód „Untrusted Code Integration”) [MEASURED n=1]. Dotyczy sesji, która dołącza Foldery jako drugie repo, nie sesji Foldery.

---

## 4. Odsyłacze, które działają

| Mechanizm | Składnia | Kiedy się ładuje | Co dokładnie | Pułapki |
|---|---|---|---|---|
| **Import `@`** | `@ścieżka` poza backtickami i blokami kodu, najlepiej jeden na linię (np. `- @docs/x.md`). Ścieżka względna wobec pliku z importem; spacje jako `\ `; maks. 4 poziomy [SOURCE: CC memory.md, 2026-10-08] | Razem z plikiem, który importuje. W głównym CLAUDE.md na starcie, w zagnieżdżonym przy jego załadowaniu [MEASURED: findings.md 2026-10-08] | Cały plik, bez limitu Read (219 KB zaimportowane w całości) [MEASURED: findings.md 2026-10-08] | **Nie oszczędza kontekstu** (docs: „imports … don't reduce its context cost”). Przecinek po ścieżce psuje import po cichu (`@a.md, @b.md` → zaimportowany tylko b) [MEASURED: findings.md]. W cudzysłowie nie działa. Ścieżka poza repo wymaga zgody (dialog) |
| **Zagnieżdżony `CLAUDE.md`** | plik `CLAUDE.md` w podkatalogu | Przy Read/Write/Edit pliku w tym podkatalogu [SOURCE: CC memory.md]; **także przy `cat`/`head` w Bash, nie przy Grep ani `python3 open()`** [MEASURED n=1, Załącznik B] | Cały plik naraz. Nie pojawia się w `/context` → Memory files | Dociera do Explore [MEASURED n=1]. Po kompaktowaniu wypada i wraca przy następnym dotknięciu. Edycja w trakcie sesji działa tylko przed pierwszym załadowaniem (O0 §2) |
| **`.claude/rules/*.md` bez `paths`** | dowolny plik `.md` | Na starcie, jak CLAUDE.md [SOURCE: CC memory.md] | Cały plik | To samo co CLAUDE.md, ten sam koszt |
| **`.claude/rules/*.md` z `paths`** | frontmatter `---\npaths:\n  - "GaleriaFolderow/galeria.py"\n---` (jedyne czytane pole; YAML lista lub ciąg z przecinkami) | Przy Read/Write/Edit pasującego pliku [SOURCE: CC memory.md]; także `cat`/`head` [MEASURED n=1] | Cała reguła | Dociera do Explore i general-purpose [MEASURED n=1]. Po kompaktowaniu wypada i wraca przy następnym dopasowaniu [SOURCE: CC context-window.md]. Przy jednym pliku z kodem każda reguła na `galeria.py` ładuje się przy każdej pracy z kodem (brak selektywności) |
| **Zwykła ścieżka w tekście** | „Przeczytaj `dokumentacja/x.md`” | Nigdy automatycznie. Tylko gdy model wykona Read | To, co Read zwróci: ≤ 25k tokenów na wywołanie, powyżej PARTIAL view [CODE/MEASURED: O0 §1] | Model może pominąć (miękkie). Plik do czytania w całości trzymaj ≤ 20k tokenów albo napisz „czytaj w częściach offset/limit”. Wewnątrz backticków `@x` zostaje dosłownym tekstem, i to dobrze |
| **Skill** | `.claude/skills/<nazwa>/SKILL.md` | Opis (≤ 1 536 znaków) zawsze; treść po wywołaniu `/nazwa` albo gdy model uzna opis za pasujący [SOURCE: CC skills.md] | Po kompaktowaniu treść wraca, maks. 5k tokenów na skill [SOURCE: CC context-window.md] | Dobór przez opis jest zawodny; dla procedur wywołuj jawnie `/nazwa` |
| **Hook SessionStart / SubagentStart** | `.claude/settings.json` → `additionalContext` (JSON) lub zwykły stdout (tylko SessionStart) | Start/wznowienie/kompaktowanie sesji; start każdego subagenta [SOURCE: CC hooks.md] | Maks. 10 000 znaków, nadmiar trafia do pliku z podglądem 2 000 znaków [SOURCE: O2 §A6] | SubagentStart nie blokuje, tylko wstrzykuje. Czy działa dla agentów workflow: niezweryfikowane (§9) |

**Zasady pisania odsyłaczy dla następców:**
1. To, co musi być zawsze: tylko główny `CLAUDE.md` (krótki), bez `@` do dużych plików.
2. To, co dotyczy kodu: reguła z `paths` na `GaleriaFolderow/galeria.py`.
3. Reszta: zwykła ścieżka w tabeli „zadanie → plik” (MAPA §1) plus wymiar pliku w tokenach, np. „`dokumentacja/architektura/montaz.md` (14k, czytaj w całości)”.
4. Nigdy `@plik, @plik` z przecinkiem. Nigdy liczb rozmiaru wpisanych ręcznie bez strażnika (D3).

---

## 5. Docelowa struktura

```
/CLAUDE.md                                   ≤ 120 linii, ≤ 5k tok.  (ładuje się wszystkim na starcie)
/.gitignore                                  bez „.claude/”; zamiast tego .claude/worktrees/ i .claude/settings.local.json
/.claude/settings.json                       deny + hooki (§6)
/.claude/hooks/session-start.sh              stan na start / po kompaktowaniu
/.claude/hooks/subagent-start.sh             reguły dla każdego subagenta (≤ 10 000 znaków)
/.claude/hooks/guard-bash.sh                 PreToolUse Bash: force-push, push przy czerwonym doc_check
/.claude/hooks/guard-edit.sh                 PreToolUse Edit|Write: workflow bez „push:”
/.claude/hooks/stop-check.sh                 Stop: lista „Zmiany…”, doc_check po commicie
/.claude/agent-rules.md                      ≤ 1,5k tok.  tekst wstrzykiwany agentom
/.claude/agents/recenzent.md                 tylko do odczytu, model/effort jawnie
/.claude/agents/wykonawca.md                 isolation: worktree, zakazy
/.claude/skills/dostawa/SKILL.md             wersja → backup → docs → CRLF → zip → commit → merge (≤ 3k tok.)
/.claude/skills/przekazanie/SKILL.md         blok „USTAW PRZED WKLEJENIEM” + szablon promptu (z EFFORT-ZASADY §5)
/.claude/rules/galeria-niezmienniki.md       paths: GaleriaFolderow/galeria.py  ≤ 15k tok.  (dzisiejszy §6)
/.claude/rules/testy.md                      paths: GaleriaFolderow/tests/**      ≤ 4k tok.
GaleriaFolderow/
  STATUS.md                                  ≤ 3k tok., NADPISYWANY (stan + następne zadanie), nie dopisywany
  MAPA.md                                    ≤ 20k tok. (bez §9 historii; tabela zadanie → plik z wagą)
  CHANGELOG.md                               bez limitu; nie ładowany; szukać grep-em (dzisiejsze §8 + MAPA §9)
  README.txt                                 bez zmian (dla użytkownika)
  EFFORT-ZASADY.md                           ≤ 10k tok. (§5 przenieść do skilla przekazanie)
  dokumentacja/
    architektura/<obszar>.md                 każdy ≤ 20k tok.: katalog, kafelki, przegladarka, montaz-hybryda,
                                             osoby-litery-strzalki-boksy, przycinanie, wyszukiwarka, wideo, operacje-plikow…
    SPEC.md lub spec/<obszar>.md             dzisiejszy §5 (25k → 2 pliki)
    OGRANICZENIA.md                          §7 (14k)
    BACKLOG.md                               §9 (6k)
    ai/                                      jak dziś; USUWANIE-OBIEKTOW.md podzielić na 2–3 pliki ≤ 20k
```

**Budżety (zasady wag):**

| Rodzaj | Limit | Dlaczego |
|---|---|---|
| Główny CLAUDE.md | ≤ 120 linii i ≤ 5k tok. (≈ ≤ 11 KB przy 2,26 B/tok.) | Płaci go każde okno i każdy agent przy starcie. Docs: < 200 linii. Każde 0,5k = koszt startu każdego agenta (O0 §8) |
| Reguły bez `paths` | 0 (nie używać) | Ładują się zawsze, jak CLAUDE.md |
| Reguła z `paths` na `galeria.py` | ≤ 15k tok. | Dociera przy każdej pracy z kodem, także do agentów (zmierzone) |
| Plik do przeczytania w całości | ≤ 20k tok. (polski md ≈ ≤ 40 KB, angielski ≈ ≤ 54 KB) | Limit Read 25k minus margines; powyżej PARTIAL view (O0 §1) |
| Opis skilla | ≤ 300 znaków | Lista skilli ma budżet; skrócone opisy gubią słowa kluczowe [SOURCE: CC skills.md] |
| `additionalContext` hooka | ≤ 8 000 znaków | Twardy limit 10 000 (O2 §A6) |
| Start sesji (instrukcje projektu) | ≤ 8k tok. | CLAUDE.md + wynik SessionStart |
| Praca z kodem | +≤ 20k tok. | + reguła niezmienników + reguła testów |

**Jak mierzyć wagi (nie znaki/4, które mylą o 13–55%, O0 §1):**
- (a) Katalog roboczy poza repo z `CLAUDE.md`, który ma `- @plik` dla każdego mierzonego pliku. Potem `claude -p "/context" --model opus --effort medium --permission-mode default --max-turns 1 --max-budget-usd 0.5` i odczyt tabeli Memory files. Koszt 0 USD, tak mierzyłem w Załączniku B.
- (b) Licznik w błędzie Read (O0 §1).

**Twarde pilnowanie wag:** rozszerzyć `doc_check.py` o limity **bajtów** jako przybliżenie tokenów, skalibrowane pomiarem 2,0–2,26 B/tok.:
- `CLAUDE.md` ≤ 11 000 B;
- `.claude/rules/*.md` ≤ 32 000 B;
- `MAPA.md` i każdy plik w `dokumentacja/` ≤ 40 000 B;
- `STATUS.md` ≤ 6 000 B.

Skrypt nie policzy tokenów bez API, a bajty liczy deterministycznie. Ratio sprawdzić ponownie po zmianie modelu (O0 §9).

---

## 6. Egzekwowanie reguł dla następców

### Twarde vs miękkie (każda reguła z dzisiejszego §1–§3 i MAPA §8)

| Reguła | Dziś | Proponowany mechanizm | Twardość |
|---|---|---|---|
| Dokumentacja aktualizowana w każdej sesji ze zmianą | tekst + `doc_check` w testach | `doc_check` w hooku PreToolUse na `git push` (exit 2) + Stop hook po commicie | Twarde dla ścieżki Bash-tool → push. Obejście: push z wnętrza skryptu (O0 §4) |
| Nigdy force-push / przepisywanie historii | tekst | deny `Bash(git push --force*)`, `Bash(git push -f*)` + regex w `guard-bash.sh` (łapie `-C`, `+ref`) | Twarde na poziomie narzędzia; deny dopasowuje tekst, hook dopasowuje wzorce. Pełne tylko z branch protection na GitHubie |
| Workflow CI tylko ręcznie (bez `push:`) | tekst | `guard-edit.sh` (Edit/Write pliku w `.github/workflows/` z `push:` → exit 2) + sprawdzenie w `doc_check` (łapie też edycję przez `sed`) | Twarde (hook) + twarde przy testach (skrypt) |
| Backupy są nienaruszalne | tekst („Keep all”) | deny `Edit(/GaleriaFolderow/backup/**)` (Read zostaje: audyty porównują z backupem) | Twarde dla Edit/Write; `cp` w Bash dalej działa, i dobrze (tak powstaje backup) |
| Lista „Zmiany w tej odpowiedzi” | tekst | Stop hook: gdy drzewo albo HEAD zmienione, a ostatnia wiadomość nie zawiera nagłówka → `decision: block` raz (`stop_hook_active`) | Twarde wykrycie, jedno upomnienie; limit 8 kontynuacji [SOURCE: CC hooks.md] |
| Scalenie z `main` po każdej pracy | tekst | Skill `/dostawa` (procedura) + Stop hook przypominający, gdy HEAD ≠ origin/main | Miękkie (procedura) + wykrycie. Klasyfikator może zablokować merge zmieniający CLAUDE.md („Self-Modification”, findings.md 2026-10-06, n=2) |
| Po polsku, zwięźle, „powiedz, gdy prośba nieoptymalna” | tekst + preferencje claude.ai | Główny CLAUDE.md (2 linie) | Miękkie (z natury). Preferencje claude.ai nie docierają do agentów, ale agenci nie piszą do użytkownika |
| Brak komentarzy w nowym kodzie | tekst | Opcjonalnie skrypt w `ast_check`: porównanie liczby linii `#` z backupem | Twarde, jeśli dodasz skrypt; dziś miękkie |
| Kolejność testów, GUI nie równolegle | tekst | `testy.sh` już szereguje; `flock` w MAPA §7 | Częściowo twarde (skrypt) |
| Niezmienniki kodu (§6) | 13k tokenów w 240k | Reguła `paths` → widoczne dokładnie przy pracy z kodem | Miękkie (to wiedza), ale zawsze obecne |

### Szkice (gotowe do wklejenia przez sesję Foldery; tu niezapisane do repo)

> **Nieaktualne od planu 4.2:** szkice hooków i `settings.json` poniżej zastąpił `reports/foldery-hooks/hooks.py` (Python, test 82/82) i sekcja A5 planu. Szkic `/CLAUDE.md` zastąpił `reports/foldery-CLAUDE-NOWY.md`. Lista treści `agent-rules.md` nadal obowiązuje.

**`/CLAUDE.md`** (angielski, zgodnie z Twoją konwencją; ~80 linii):
```markdown
# Galeria folderów — instructions for Claude
Single-file Windows app `GaleriaFolderow/galeria.py` (PySide6). Owner writes Polish: answer in Polish, concise,
strict but fair; if a request is suboptimal or risky, say why and get confirmation first (AskUserQuestion).

## Start of every session
- Hook prints status: version, branch vs origin/main, STATUS.md. If behind main: `git merge --ff-only origin/main`.
- Then read `GaleriaFolderow/MAPA.md` §1 (task → file table; sizes in tokens). Read only the files your task needs.
- Code invariants load automatically when you read galeria.py (.claude/rules/galeria-niezmienniki.md).

## Rules (user, with dates in CHANGELOG.md)
- Docs updated in the SAME session as any change: the area file in dokumentacja/architektura/, CHANGELOG.md line,
  STATUS.md (overwrite, ≤ 6 KB), MAPA §4 regenerated (`python3 tools/mapa_kodu.py`), README line 1.
  `tools/doc_check.py` must print DOC OK (also enforced by a pre-push hook).
- Delivery: run `/dostawa` (version, backup, CRLF, zip, commit, push, merge into main). Never force-push.
- Every reply that did work ends with „Zmiany w tej odpowiedzi” (Stop hook checks).
- Windows CI `.github/workflows/ai-windows.yml` stays manual-only (hook blocks a push trigger).
- New code: no comments; Polish UI strings with diacritics. Test first, see it fail, `./tools/testy.sh` green.
- Say plainly what was NOT run (Windows, GPU, real files).

## Writing docs for successors
- One fact in one place; link by plain path + size, e.g. `dokumentacja/architektura/montaz.md` (14k tok.).
- Rewrite an area file to the current state; history goes to CHANGELOG.md, never as new paragraphs on top.
- Size caps (doc_check enforces bytes): CLAUDE.md 11 KB, rules 32 KB, docs files 40 KB, STATUS.md 6 KB.
- No `@` imports of big files; never `@a.md, @b.md` (comma breaks the import).
- Agents: use .claude/agents/wykonawca.md / recenzent.md; give each its part of the task, goal, done-criteria.
```

**`/.claude/settings.json`:**
```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force*)", "Bash(git push -f*)", "Bash(git push * --force*)", "Bash(git push * -f*)",
      "Edit(/GaleriaFolderow/backup/**)",
      "Read(/GaleriaFolderow_v*.zip)"
    ]
  },
  "hooks": {
    "SessionStart": [{ "matcher": "startup|resume|compact",
      "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start.sh", "args": [], "timeout": 60 }] }],
    "SubagentStart": [{ "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/subagent-start.sh", "args": [] }] }],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/guard-bash.sh", "args": [], "timeout": 120 }] },
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/guard-edit.sh", "args": [] }] }
    ],
    "Stop": [{ "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/stop-check.sh", "args": [], "timeout": 120 }] }]
  }
}
```
Uwagi:
- Ścieżki `/…` w deny są względne wobec katalogu pliku ustawień, czyli korzenia repo [SOURCE: O2 §D4].
- Forma `args: []` (exec) unika problemów z cudzysłowami [SOURCE: CC hooks.md].
- Hooki z `settings.json` działają bez zaufania folderu także w `-p` [SOURCE: CC permissions.md, tabela „What runs before you trust a folder”].

**`.claude/hooks/session-start.sh`:**
```bash
#!/bin/bash
in=$(cat); sid=$(jq -r '.session_id' <<<"$in"); src=$(jq -r '.source' <<<"$in")
cd "$CLAUDE_PROJECT_DIR" || exit 0
[ "$src" = startup ] && git rev-parse HEAD > "${TMPDIR:-/tmp}/foldery-head-$sid" 2>/dev/null
git fetch -q origin main 2>/dev/null
behind=$(git rev-list --count HEAD..origin/main 2>/dev/null)
ver=$(grep -m1 -oP '^APP_VERSION = "\K[^"]+' GaleriaFolderow/galeria.py)
echo "Foldery: APP_VERSION $ver · gałąź $(git branch --show-current) · za origin/main: ${behind:-?}"
[ "${behind:-0}" != 0 ] && echo "NAJPIERW: git merge --ff-only origin/main"
echo "--- GaleriaFolderow/STATUS.md ---"; head -40 GaleriaFolderow/STATUS.md 2>/dev/null
exit 0
```

**`.claude/hooks/subagent-start.sh`** (wstrzykuje `agent-rules.md` każdemu subagentowi, także Explore):
```bash
#!/bin/bash
jq -n --rawfile t "$CLAUDE_PROJECT_DIR/.claude/agent-rules.md" \
  '{hookSpecificOutput:{hookEventName:"SubagentStart",additionalContext:$t}}'
```
`agent-rules.md`, ok. 15 linii:
- nie zmieniaj `APP_VERSION`, `backup/`, dokumentacji, zipa ani `main` (to robi główne okno);
- zmieniaj tylko swoje funkcje i testy;
- test najpierw musi paść bez poprawki;
- testy GUI tylko pod `flock /tmp/galeria_gui.lock` z własnym `TMPDIR`;
- raport: co zmieniłeś, dowód (polecenie → wynik), czego nie uruchomiłeś, decyzje podjęte bez pytania; „nic nie znalazłem” jest dozwolone;
- nie pytasz użytkownika: przy niejasności przerwij i opisz w raporcie;
- odmowy uprawnień wypisz w raporcie.

**`.claude/hooks/guard-bash.sh`:**
```bash
#!/bin/bash
cmd=$(jq -r '.tool_input.command // empty')
if grep -Eq 'git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push' <<<"$cmd"; then
  if grep -Eq '(--force|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+[^[:space:]]+)' <<<"$cmd"; then
    echo "BLOKADA: force-push zabroniony (reguła scalania użytkownika)" >&2; exit 2; fi
  out=$(cd "$CLAUDE_PROJECT_DIR/GaleriaFolderow" && python3 tools/doc_check.py 2>&1) || {
    echo "BLOKADA push: doc_check czerwony – najpierw dokumentacja:" >&2; echo "$out" >&2; exit 2; }
fi
grep -Eq 'git[^;&|]*(filter-branch|filter-repo)' <<<"$cmd" && { echo "BLOKADA: przepisywanie historii" >&2; exit 2; }
exit 0
```

**`.claude/hooks/guard-edit.sh`:**
```bash
#!/bin/bash
in=$(cat); f=$(jq -r '.tool_input.file_path // empty' <<<"$in")
case "$f" in */.github/workflows/*)
  jq -r '.tool_input.content // .tool_input.new_string // ""' <<<"$in" | grep -Eq '^[[:space:]]*(push|pull_request)[[:space:]]*:' &&
  { echo "BLOKADA: workflow tylko ręcznie (polecenie właściciela 2026-10-07, limit minut Actions)" >&2; exit 2; } ;;
esac
exit 0
```

**`.claude/hooks/stop-check.sh`:**
```bash
#!/bin/bash
in=$(cat)
[ "$(jq -r '.stop_hook_active' <<<"$in")" = true ] && exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0
sid=$(jq -r '.session_id' <<<"$in"); base=$(cat "${TMPDIR:-/tmp}/foldery-head-$sid" 2>/dev/null)
dirty=$(git status --porcelain | head -1); moved=""; [ -n "$base" ] && [ "$(git rev-parse HEAD)" != "$base" ] && moved=1
[ -z "$dirty$moved" ] && exit 0
r=""
jq -r '.last_assistant_message // ""' <<<"$in" | grep -q 'Zmiany w tej odpowiedzi' || r="dodaj listę „Zmiany w tej odpowiedzi”. "
[ -n "$moved" ] && ! (cd GaleriaFolderow && python3 tools/doc_check.py >/dev/null 2>&1) && r="${r}doc_check czerwony po commicie. "
[ -n "$moved" ] && [ "$(git rev-list --count origin/main..HEAD 2>/dev/null)" != 0 ] && r="${r}gałąź nie jest scalona z main (/dostawa). "
[ -z "$r" ] && exit 0
jq -n --arg r "Przed zakończeniem: $r" '{decision:"block",reason:$r}'
```
Test każdego hooka przed użyciem: `echo '{…json…}' | ./hook.sh; echo $?` [SOURCE: CC hooks-guide.md]. Potem `/hooks` w sesji. Literówka w ścieżce skryptu = hook po cichu wyłączony (exit 127) [SOURCE: CC hooks.md].

**`.claude/agents/recenzent.md`:**
```markdown
---
name: recenzent
description: Independent read-only review of the whole session diff before packaging. Use once, after merging all work.
tools: Read, Grep, Glob
model: opus
effort: high
---
You review a diff of GaleriaFolderow/galeria.py and tests against backup/galeria_v<prev>.py. The main session gives you
the path of a diff file it wrote. Check: correctness, threads (GUI thread vs workers, AI process), signal arities,
invariants (they load when you read galeria.py), event flow, auto-repeat, honesty about what was not run.
Report each finding: severity, file:line, evidence, concrete fix. Report only correctness gaps; "nothing found" is a valid answer.
You cannot edit files.
```
- Bez Bash, czyli naprawdę tylko do odczytu (O0 §8). Diff przygotowuje główne okno.
- `model` i `effort` podane jawnie, bo agent bez nich dziedziczy ustawienia sesji (O0 §5).

**`.claude/agents/wykonawca.md`:**
- frontmatter: `isolation: worktree`, `model: opus`, `effort: high`, `disallowedTools: Agent`;
- ciało: zakazy z `agent-rules.md` plus „pracujesz w kopii od origin/main”.

Pułapka: worktree powstaje z `origin/<domyślna gałąź>`, nie z HEAD sesji, a niezacommitowane zmiany do niego nie trafiają [SOURCE: CC worktrees.md przez O0 §3]. Przed uruchomieniem agentów trzeba zrobić commit, push i scalenie z `main`, albo ustawić `worktree.baseRef: "head"`.

**`.claude/skills/dostawa/SKILL.md`:**
- MAPA §3 przepisana jako kroki, `description` ≤ 300 znaków;
- wywoływać jawnie `/dostawa`;
- kroki: `!`git status`` na start, potem wersja, backup, dokumentacja (checklista), CRLF, zip (`git rm` starego), `unzip -l`, commit z dopiskami, push, merge do `main`, powrót na gałąź.

**`.claude/skills/przekazanie/SKILL.md`:**
- blok „USTAW PRZED WKLEJENIEM” i reguły z EFFORT-ZASADY §5–§6 oraz szablon promptu (wzór: `PROMPT-NASTEPCA-v4.37.4.md`);
- wynik zapisywany do `dokumentacja/przekazanie/PROMPT-<wersja>.md`, a STATUS.md wskazuje ostatni.

**`.claude/rules/galeria-niezmienniki.md`:**
- `---\npaths:\n  - "GaleriaFolderow/galeria.py"\n---`, a pod spodem dzisiejszy §6 (13k tok.), oczyszczony z historii wersji;
- oprócz tego `.claude/rules/testy.md` z `paths: GaleriaFolderow/tests/**`: konwencje testów z dzisiejszego §2 i pułapki z MAPA §2 i §7.

### Jak agenci dostają reguły
- **general-purpose i własni agenci:** główny CLAUDE.md na starcie [SOURCE: CC sub-agents.md, „What loads at startup”], `agent-rules.md` przez SubagentStart, niezmienniki przy Read `galeria.py` [MEASURED analogicznie, n=1].
- **Explore/Plan:** bez CLAUDE.md na starcie, ale z SubagentStart i z regułą `paths` przy Read [MEASURED n=1].
- **Agenci workflow:** CLAUDE.md tak (O0 §2). SubagentStart niezweryfikowany (§9), więc reguły kluczowe trzeba powtórzyć w promptach agentów.
- Preferencje z claude.ai do żadnego agenta nie trafiają (O0 §2).

### Przekazanie pracy następnej sesji
1. Stan jest w `STATUS.md`, nadpisywanym (≤ 6 KB): wersja, co zrobione, co otwarte, następne zadanie, decyzje czekające na użytkownika.
2. SessionStart wypisuje go automatycznie na starcie i po kompaktowaniu.
3. Historia jest w `CHANGELOG.md` i git log (nie ładuje się).
4. Prompt dla następcy powstaje przez `/przekazanie` i leży w pliku. Plik jest „wiedzą do przeczytania”, a nie instrukcją ładowaną zawsze.

---

## 7. Plan migracji (kolejność ma znaczenie)

| Krok | Co | Ryzyko i jak je zdjąć |
|---|---|---|
| 0 | Twoje decyzje: (a) zgoda na podział CLAUDE.md i nowy `doc_check`; (b) czy zip ma zawierać główny `CLAUDE.md`, bo dziś reguła mówi „always re-add CLAUDE.md to the zip”; (c) czy backupy zastąpić tagami git (90 MB w repo); (d) czy dodać lekkie CI `doc_check` na push (zużywa minuty Actions); (e) czy włączyć branch protection (repo prywatne = płatny plan, O0 §7) | Bez (a) nie ruszać kroku 3 |
| 1 | Sesja Foldery „tylko dokumentacja” (wersja programu bez zmian, ta sama nazwa zipa). `.gitignore`: usunąć `.claude/`, dodać `.claude/worktrees/` i `.claude/settings.local.json` | Brak |
| 2 | Pomiar startowy (metoda z §5), zapis do CHANGELOG | Brak |
| 3 | Podział: §6 → `.claude/rules/galeria-niezmienniki.md`; §4 → `dokumentacja/architektura/*.md` (każdy ≤ 40 KB, **przepisany do stanu obecnego**, bez warstw „v4.18.1 supersedes…”); §5 → spec; §7 → OGRANICZENIA; §9 → BACKLOG; §8 i MAPA §9 → `CHANGELOG.md`; STATUS.md z bieżącego stanu; MAPA §1 → nowe ścieżki z wagami; MAPA ≤ 40 KB | Utrata informacji przy przepisywaniu → przed usunięciem starego pliku agent-recenzent porównuje fakty stary vs nowy (lista nagłówków **v…** z §4 i §6 musi mieć miejsce docelowe) |
| 4 | **W tym samym commicie**: `doc_check.py` (sprawdza `CHANGELOG.md` „- vX”, `STATUS.md`, MAPA §4 nagłówek, README, limity bajtów, brak `push:` w workflow) + aktualizacja testu mutacyjnego w `test_logic` + usunięcie `GaleriaFolderow/CLAUDE.md` + nowy główny `/CLAUDE.md` | Rozjazd kodu strażnika i dokumentów = czerwone testy → jeden commit, `./tools/testy.sh` zielone przed push |
| 5 | `.claude/settings.json` + hooki + `agent-rules.md`; każdy hook przetestowany JSON-em na stdin, potem w nowej sesji `/hooks` i prowokacja (próba `git push -f` na gałęzi testowej, edycja workflow z `push:`) | Edycje `.claude/` w auto mode idą do klasyfikatora (chroniona ścieżka) [SOURCE: CC permission-modes.md, „Protected paths”] → możliwe pytania o zgodę; zmiany CLAUDE.md przy scalaniu do `main` mogą zostać odrzucone jako „Self-Modification” (findings.md 2026-10-06) → scal sam na GitHubie |
| 6 | Agenci i skille (`recenzent`, `wykonawca`, `/dostawa`, `/przekazanie`); EFFORT-ZASADY §5 → skill | Nowy katalog `.claude/agents/` utworzony w trakcie sesji wymaga restartu sesji [SOURCE: CC sub-agents.md] |
| 7 | Nowa sesja Foldery: `/context` (CLAUDE.md ~5k), Read `galeria.py` z `limit` → reguła się ładuje (komunikat „Loaded”), test agenta Explore | Zmiana CLAUDE.md działa dopiero w nowej sesji (O0 §2) |
| 8 | Ty w UI środowiska chmury: setup script = instalacja z `tools/srodowisko.sh` (cache obrazu, < 5 min) [SOURCE: CC cloud-environments.md] | Skrypt > ~5 min nie jest cache'owany; exit ≠ 0 = brak sesji (O0 §7) |
| 9 | Opcje z kroku 0 (d), (e) | Koszt minut / płatny plan |

---

## 8. Odrzucone alternatywy

| Alternatywa | Dlaczego nie |
|---|---|
| Zostawić jeden plik, ale porozbijać go importami `@` | Importy ładują się razem z plikiem: zero oszczędności [SOURCE: CC memory.md] |
| Zagnieżdżony CLAUDE.md z importami części | Ładuje wszystko naraz przy pierwszym dotknięciu [MEASURED: findings.md 2026-10-08] |
| Reguły `paths` per obszar kodu | Kod jest w jednym pliku `galeria.py` (wymóg użytkownika „keep single-file”), więc każda reguła pasuje zawsze. Ma sens dopiero po podziale kodu na moduły, a to decyzja użytkownika, dziś nie zalecam |
| Wiedza architektoniczna w skillach | Skill odpala się po opisie (zawodnie); tabela w MAPA + Read jest deterministyczna. Skille tylko dla procedur (`/dostawa`, `/przekazanie`) |
| `AGENTS.md` zamiast CLAUDE.md | Brak zysku; ten sam mechanizm ładowania [SOURCE: CC memory.md] |
| Output style do „po polsku, lista Zmian” | Zastępuje instrukcje inżynierskie (chyba że `keep-coding-instructions`), działa tylko w głównym oknie (O0 §2); Stop hook jest twardszy |
| `/goal` do pilnowania dokumentacji | Mały model ocenia rozmowę, nie pliki; Stop hook ze skryptem sprawdza pliki (O0 §6) |
| Auto memory | Nie istnieje w sesji chmurowej (O0 §2) |
| `claudeMdExcludes` na stary plik | Ukrywa reguły zamiast je przenieść; tylko do testu w trakcie migracji |
| Setup script piszący `~/.claude/CLAUDE.md` | Nie jest w repo, nie dotyczy innych środowisk; tylko na prywatne preferencje |
| Branch protection jako główny mechanizm | Na prywatnym repo wymaga płatnego planu, admin domyślnie omija (O0 §7). Zostaje jako opcja |
| CI na każdy push | Twój limit minut Actions (polecenie 2026-10-07). Hook pre-push daje to samo lokalnie za darmo |
| Workflow wieloagentowy do migracji | Jedna spójna przeróbka dokumentów z wieloma zależnościami: lepsze główne okno + 1 recenzent (O0 §3) |

---

## 9. Niezweryfikowane / otwarte pytania

1. **`cat`/`head` w Bash ładują zagnieżdżony CLAUDE.md i reguły `paths`** (docs mówią tylko o Read/Write/Edit). Zmierzone n=1 na CC 2.1.294; Grep i `python3 open()` nie ładują (n=1 każde). Wpisane do `exceptions.md`. Do powtórzenia po nowej wersji CC.
2. **Explore dostaje pliki ładowane przy czytaniu** (n=1, Sonnet 5.5). Czy Explore w chmurze może dostać model z oknem 200K: przy dzisiejszym 240k pliku taki agent by się przepełnił. Niezmierzone.
3. Czy **SubagentStart** odpala dla agentów **workflow** i czy reguła `paths` do nich dociera. Docs mówią o narzędziu Agent; niezmierzone. Test: workflow z 1 agentem, koszt ~0,3–1 USD, wymaga Twojej zgody (workflow).
4. Czy plik reguły > 25k tokenów ładuje się w całości (importy tak, zmierzone; reguły nie testowane). Proponowany limit 15k omija pytanie.
5. Czy w sesji chmurowej działa zaufanie folderu dla **hooków w frontmatterze agenta** (wymagają zaufania) [SOURCE: CC sub-agents.md]. Dlatego proponuję hooki w `settings.json`, które zaufania nie wymagają.
6. Tokeny EFFORT-ZASADY, PROMPT-NASTEPCA, ANALIZA, PROPOZYCJA-*: oszacowane z sąsiednich pomiarów, nie zmierzone (repo prywatne: raw 404, MCP inline).
7. Zgodność MAPA §4 z kodem nie sprawdzona: `galeria.py` > 1 MB nie przechodzi przez MCP, a klon zablokował klasyfikator. Liczba linii 39 588 pochodzi z pomiaru poprzedniej sesji.
8. Odmowa `git clone` przez klasyfikator (n=1) dotyczy sesji z ClaudeEXPERT jako repo główne. W sesji samej Foldery nie występuje (tam klon robi środowisko).
9. Koszty w USD to obliczenia z cennika API; przy subskrypcji przekładają się na limity, nie na rachunek.

---

## Załącznik A: pokrycie dokumentacji

| Strona (docs/cc) | Status | Uwagi |
|---|---|---|
| memory, claude-directory, context-window, best-practices, large-codebases, features-overview, debug-your-config, hooks-guide | wczytane z góry (import CLAUDE.md) | całość |
| sub-agents | przeczytane: part1, part2, part3 (do „Work with subagents”), part4 (Concurrent limit … Auto-compaction) | pominięte: część o forkach i przykładach (nieistotne) |
| hooks | przeczytane: part2 (Reference scripts … Disable hooks), part3 (Exit code output, per event), part4 (SessionStart, Setup, InstructionsLoaded), part7 (SubagentStart, SubagentStop, Stop); spis nagłówków wszystkich 10 części | PreToolUse input/decision: z O2 §A5 (preload) zamiast part5 |
| settings | przeczytane: part3 (troubleshoot, wyjątki, „Settings in cloud sessions”) | part1–2: z O2 §D (preload) |
| permissions | przeczytane: part3 od „Project allow rules and workspace trust” | składnia reguł: O2 §D4 (preload) |
| permission-modes | grep + odczyt sekcji „Protected paths” | reszta nieużyta |
| skills | przeczytane: part2 (Configure skills, frontmatter, nazwy) | part1, 3–5 nieużyte (tworzenie, eval) |
| cloud-environments | przeczytane: part2 (dostęp sieci, GitHub proxy, co przechodzi do chmury, setup scripts) | part1, 3 nieużyte |
| claude-code-on-the-web | przeczytane: part1 od „Work with sessions” | reszta nieużyta |
| prompt-caching | przeczytane: part1 (organizacja cache, akcje unieważniające) | part2 nieużyta |
| settings-reference | nieużyta | żaden proponowany klucz poza opisanymi w O2/settings |
| workflows | nieużyta | workflow nie jest rekomendowany (§8) |

## Załącznik B: eksperymenty

| # | Polecenie (skrót) | Wynik | Koszt | n |
|---|---|---|---|---|
| B0 | `claude -p "/context" --model opus --effort medium …` w ClaudeEXPERT | 29 plików pamięci, 217,4k tokenów, start 241,8k | 0 USD | 1 |
| B1 | Pobranie plików Foldery przez GitHub MCP, `git hash-object` | SHA = SHA GitHuba (CLAUDE.md `da07d8b`, MAPA `b5055a8`, README `813f43f`, USUWANIE `444327c`) | 0 | 1 |
| B2 | `git clone --depth 1 …/foldery` | **Odmowa klasyfikatora auto mode**: „Untrusted Code Integration” | 0 | 1 |
| B3 | `/context` w katalogu testowym z `CLAUDE.md` = `- @f-CLAUDE.md` `- @MAPA.md` `- @README.txt` `- @USUWANIE-OBIEKTOW.md` | 239,9k / 29,4k / 47,8k / 44,8k tokenów (B/tok.: 2,26 / 2,04 / 2,04 / 1,91) | 0 USD | 1 |
| B4 | Repo testowe: `CLAUDE.md` (ROOT), `sub/CLAUDE.md` (NESTED), `.claude/rules/r.md` z `paths: sub/**` (RULE); `claude -p` każe uruchomić agenta general-purpose i Explore, każdy robi Read `sub/a.txt`; grep kanarków w transkryptach | general-purpose: ROOT, NESTED, RULE; **Explore: NESTED, RULE, bez ROOT** (załączniki `nested_memory` ×2); główne okno: tylko ROOT | 0,18 USD (`--model sonnet --effort low --max-turns 8 --max-budget-usd 1`) | 1 |
| B5 | Główne okno: Bash `cat sub/a.txt`, potem Grep | `nested_memory` (NESTED+RULE) pojawia się **zaraz po wyniku Bash `cat`**, przed Grep | 0,06 USD | 1 |
| B6 | Osobne sesje: tylko Grep `sub/` · tylko `python3 -c "open('sub/a.txt')"` · tylko `head -1 sub/a.txt` | Grep: nie ładuje · python: nie ładuje · **head: ładuje** | 0,15 USD | 1 każde |

Razem eksperymenty: ~0,39 USD. Model w transkryptach: `claude-sonnet-5-5` (odczyt z pola `message.model`, nie z deklaracji modelu).
