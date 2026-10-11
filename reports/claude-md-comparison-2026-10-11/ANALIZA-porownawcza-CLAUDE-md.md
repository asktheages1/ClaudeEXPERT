# Analiza porównawcza czterech plików CLAUDE.md (2026-10-11, wersja 2.1 po dwóch rundach recenzji)

Zakres: `claudeFolderymd.md` (Galeria folderów), `claudePOBTWEAKSmd.md` (PoBTweaks), `claudeExpertmd.md` (ClaudeEXPERT; identyczny z CLAUDE.md tego repozytorium), `claudeFelixmd.md` (Felix). Wszystkie cztery przeczytane w całości (513 linii łącznie).
Podstawa oceny: `knowledge/O0-how-claude-works.md` (w całości), `O2-syntax-cheatsheet.md` §A i §D, `O5` §1–§2, `reports/doc-migration-playbook.md` §1, §5, §8, §9, `findings.md`. Wersja Claude Code w sesji: 2.1.296 (KB: 2.1.291). Delta changelogu 2.1.292–2.1.296 pod kątem CLAUDE.md i hooków [CL, pobrane 2026-10-11]: 2.1.293 reguły `paths:` i zagnieżdżone CLAUDE.md ładują się też przy jednoplikowym `cat`/`sed -n`/`grep`; 2.1.295 `onFailure: "block"` dla hooków (hook, który padnie, nie wystartuje lub przekroczy czas, blokuje zamiast przepuszczać); 2.1.72 komentarze HTML w CLAUDE.md są ukryte przed Claude przy auto-ładowaniu (widoczne przy czytaniu narzędziem Read). Nic z tego nie zmienia rankingu; wszystkie trzy fakty wykorzystałem w pliku wynikowym.

Oznaczenia dowodów jak w CLAUDE.md repo: `[MEASURED]` własny pomiar, `[SOURCE]`/`[OF]` dokumentacja, `[CL]` changelog, `[ASSUMPTION]` wniosek. „O0 §8” = sekcja 8 pliku O0. Wersja 1 raportu i szablonu leży obok (`ANALIZA.v1.md`, `CLAUDE-perfect.v1.md`); zmiany po recenzji: §7.

## 1. Werdykt

**Najlepszy „ogólnie, uniwersalnie i bazowo”: Foldery.** Ranking jako *plik bazowy*: Foldery > Expert > Felix > PoBTweaks. Ranking jako *źródło rozwiązań*: PoBTweaks ≥ Foldery > Expert > Felix.

Dlaczego Foldery:
1. Jako jedyny ma sekcję „Enforcement and its limits”: wymienia, co egzekwuje mechanizm (deny, hooki exit 2, ochrona gałęzi), jakie są znane obejścia i kiedy zmiany wchodzą w życie. To wprost wniosek O0 §8 („twarde jest tylko to, co egzekwuje Claude Code lub serwer; CLAUDE.md tylko steruje”) i O0 §6 („CLAUDE.md to wiadomość użytkownika, bez gwarancji posłuszeństwa” [SOURCE: CC memory.md]).
2. Ma pełny szkielet operacyjny: zasady właściciela → start sesji → weryfikacja → dokumentacja i stan → agenci → egzekwowanie. Każda sekcja wskazuje mechanizm (hook SessionStart, hook Stop, doc_check, SubagentStart, prompt uprawnień przy edycji tego pliku), nie tylko tekst.
3. Rozmiar: 119 linii, 11 KB, 4 425 tokenów [MEASURED] — w zaleceniu „< 200 linii” [SOURCE: CC memory.md, O0 §2] i blisko budżetu z playbooka §8 („krótki root CLAUDE.md ≤ ~10 KB z nawigacją zamiast treści”; Foldery ma 11 KB, więc nieco ponad).
4. Reguły dla agentów są zgodne z KB: agenci nie widzą rozmowy ani preferencji (O0 §2), dostają reguły hookiem SubagentStart, nie mogą pytać właściciela (O0 §8), worktree powstaje z `origin/main`, stąd „commit + push + merge first” (O0 §3), model i effort podawane jawnie (O0 §5).
5. Kontrola zmian samego pliku: zgoda właściciela wymuszona promptem uprawnień, oryginalne brzmienie z datą w osobnym pliku, świadomość, że klasyfikator auto mode może odmówić edycji CLAUDE.md/`.claude/` (findings.md 2026-10-06 [MEASURED]).

Jego wady (naprawione w pliku wynikowym): treść czysto projektowa (fakty o sprzęcie, Windows CI, komentarze w kodzie, folder dokumentacji AI) jest w bazie szumem; „Opus 5.5 high dla sesji” zapisane jako tekst, choć model i effort sesji ustawia `settings.json` (`model`, `effortLevel`, czytane na starcie, O2 §D3), nie CLAUDE.md; brak bramki kosztowej dla agentów (Expert ją ma); brak reguły zakresu „tylko to repo” (Expert, PoB ją mają).

Dlaczego nie pozostałe:
- **Expert** (107 linii, 9,9 KB, 3 752 tok. [MEASURED]) jest najczystszy w dyscyplinie dowodowej, bramce kosztowej i trwałości w chmurze, ale to plik dla asystenta-doradcy nad bazą wiedzy: połowa treści (tagi dowodów, tabela plików KB, otwarte konflikty, świeżość, live lookups) nie przenosi się na projekt z kodem. Nie ma sekcji o egzekwowaniu dla *siebie*; wymienia ją tylko jako listę kontrolną przy recenzji cudzych systemów. Trzy jego reguły są jednak ogólne i weszły do bazy: „nic poza tym repozytorium”, „deny i hooki ładują się tylko ze startu w katalogu głównym”, „nie ufaj pamięci o Claude Code”. Zastrzeżenie: to CLAUDE.md repozytorium, pod którym pracuję; recenzent sprawdził stronniczość i jej w rankingu nie znalazł (§7).
- **Felix** (31 linii, 3,5 KB, 1 132 tok. [MEASURED]) ma najlepszą *zasadę* („ważne reguły egzekwowane mechanizmami, nie dobrą wolą”; „czytaj plik w całości, mów wprost, czego nie przeczytałeś”) i jako jedyny żąda identycznego działania w chmurze i lokalnie. Ma też zalążek trwałości („zapisz zlecenie w repo”, „commituj i pushuj każdą zmianę”). Ale to starter: brak startu sesji, weryfikacji, stanu między sesjami, agentów, egzekwowania. Nakaz „przy każdym planie/analizie/prompcie/kodzie użyj ≥ 1 agenta sprawdzającego” nie ma progu kosztowego i, jak sam plik przyznaje, nie jest niczym wymuszony. Obowiązkowe O0 na starcie (ok. 17,7 tys. tokenów, O0 nagłówek) ma sens tylko w repo z bazą wiedzy. Nazwa i patron to ozdobnik bez funkcji.
- **PoBTweaks** (256 linii, 31,6 KB, 16 093 tok. [MEASURED]) ma najwięcej rozwiązań, których inni nie mają, ale jako plik jest antywzorcem z O0 §6: 16 tys. tokenów to tyle, co zmierzony w O0 §2 plik instrukcji 31,6 KB, który podraża start *każdego* agenta ładującego CLAUDE.md o ~16 tys. tokenów [MEASURED O0 §2]; „dłuższy plik obniża posłuszeństwo” [SOURCE: CC memory.md]. Po polsku: ta sama treść kosztuje ok. +23 % tokenów (O0 nagłówek: angielski 38 565 B = 17 754 tok., polski 40 050 B = 21 873 tok. [MEASURED]); bajty na token w czterech plikach (1,97 PL vs 2,49–3,13 EN) są z tym zgodne [ASSUMPTION z obliczenia]; właściciel ustalił angielski jako język plików Claude. Reguły przeplecione historią (daty decyzji, numery planów „4.17b”, „D26”, „zasada 4.23”), które nic nie mówią świeżej sesji i łamią „jedna reguła, jedno miejsce” (playbook §5: „co wyrzucać: historię, daty decyzji, »użytkownik powiedział«”). Wyjątek „zgłoś i czekaj” (§12) wobec „wykonuj do końca” (§3) jest rozstrzygnięty w obu miejscach — koszt to ta sama reguła zapisana dwa razy, nie sprzeczność. Raport otwarcia w *każdej* odpowiedzi to koszt bez mechanizmu („brak raportu = odpowiedź nieważna” nie jest niczym egzekwowane). Start każe przeczytać STAN i całą MAPĘ (nie tylko jej §1; rozmiar MAPY niezmierzony).

## 2. Pomiary

| Plik | Linie | Bajty | Tokeny (licznik Read) | B/token | Język | Nagłówki |
|---|---|---|---|---|---|---|
| Foldery | 119 | 11 007 | 4 425 | 2,49 | EN | 8 |
| PoBTweaks | 256 | 31 622 | 16 093 | 1,97 | PL | 15 |
| Expert | 107 | 9 881 | 3 752 | 2,63 | EN | 13 |
| Felix | 31 | 3 540 | 1 132 | 3,13 | EN | 6 |
| Plik wynikowy v1 | 72 | 13 539 (11 924 bez komentarzy HTML) | 4 991 (4 228 bez komentarzy) | 2,71 | EN | 8 |
| Plik wynikowy v2 (po 1. rundzie) | 78 | 19 879 (17 203 bez komentarzy HTML) | 7 255 (6 002 bez komentarzy) | 2,87 | EN | 8 |
| **Plik wynikowy v2.1 (końcowy)** | 78 | 20 668 (17 744 bez komentarzy HTML) | 7 558 (6 179 bez komentarzy) | 2,87 | EN | 8 |

Metoda [MEASURED 2026-10-11, CC 2.1.296, sesja Fable 5.1, n=1 na plik; recenzent powtórzył pomiar w sesji Opus 5.5 z wynikiem ±1 tok.]: licznik z błędu Read (O0 §1): wypełniacz 130 KB → 48 089 tok.; wypełniacz + plik → wynik; różnica = tokeny pliku. Trzy pliki źródłowe mają końce linii CRLF (bajty liczą znak CR, ok. 1 %). Komentarze HTML nie wchodzą do kontekstu przy auto-ładowaniu [CL 2.1.72; O2 §D5]; przy czytaniu narzędziem Read są widoczne.

## 3. Kryteria (skąd)

1. Długość i koszt: każdy KB ≈ 0,5 tys. tokenów startu *każdego* agenta, który dostaje CLAUDE.md; > 200 linii obniża posłuszeństwo (O0 §8, §2 [SOURCE: CC memory.md] [MEASURED]).
2. Twarde vs miękkie: deny, hook exit 2, sandbox, ochrona gałęzi; reszta to rada (O0 §8, §4). Warunki: deny i hooki projektu ładują się tylko ze startu w katalogu głównym i w sesji z jednym repo (O0 §4 [MEASURED]); ochrona gałęzi w prywatnym repo tylko w płatnym planie i bez wyjątku dla admina (O0 §7); sandbox w chmurze niezmierzony (O0 §4).
3. Widoczność: agent nie widzi rozmowy, preferencji, wywołanych skilli; Explore/`omitClaudeMd` nie widzą CLAUDE.md; general-purpose i agent workflow *widzą* CLAUDE.md, ale nie mają AskUserQuestion (O0 §2, playbook §5).
4. Model i effort jawnie dla agentów, workflow i `claude -p`; `claude -p` bez `--model` nie idzie na modelu sesji (O0 §5 [MEASURED]).
5. Chmura: brak `~/.claude` i auto memory, świeża VM, gałąź sesji z `origin/main`, usunięcie gałęzi = 403, przeżywa tylko repo (O0 §7); na PC auto memory istnieje (O0 §2) — różnica, którą baza musi nazwać.
6. Co wraca po kompakcji: root CLAUDE.md, początek skilli, hook SessionStart (compact), pliki stanu w repo (O0 §1, §8) → stan musi być w repo, nie w rozmowie.
7. Zmiany CLAUDE.md działają od nowej sesji; agenci i klasyfikator mają wersję startową (O0 §2).
8. Fałszywe „gotowe” i quoty: bramki Stop hook / `/goal`, „nic nie znaleziono” dozwolone, bez „wypisz N” (O0 §6).
9. Brief agenta: zakres, ścieżki, ograniczenia, format, kryterium „gotowe”, nazwane stopy (O5 §2 [OF]).
10. Nawigacja zamiast treści: krótki root + mapa z rozmiarami + STATUS ≤ 6 KB + CHANGELOG na historię (playbook §8; O0 §8 „plik ≤ 25 tys. tokenów w jednym Read”).

## 4. Porównanie per obszar

| Obszar | Foldery | PoBTweaks | Expert | Felix | Lepszy | Dlaczego |
|---|---|---|---|---|---|---|
| Długość, język | 4,4k tok., EN | 16,1k tok., PL | 3,8k, EN | 1,1k, EN (za mało treści) | Foldery / Expert | kryterium 1; PL ≈ +23 % tokenów [MEASURED O0] |
| Nawigacja po wiedzy | MAPA §1: zadanie → plik → rozmiar; „czytaj tylko potrzebne” | router MAPA, ale STAN i cała MAPA na start; grep po Pamietac/Niedokonczone | tabela plików z kolumną „Read when” | O0 obowiązkowo; folder knowledge jako główne źródło, bez routingu | Foldery ≈ Expert | kryterium 10 |
| Start sesji | hook SessionStart drukuje wersję, gałąź vs main, STATUS; ff-merge gdy w tyle | raport otwarcia w każdej odpowiedzi; wykrycie środowiska | `git fetch origin main`, porównaj HEAD | brak | Foldery | mechanizm (hook) zamiast tekstu; raport w każdej odpowiedzi = koszt bez bramki |
| Zasada domyślna, pytania | „inaczej po prostu rób”; AskUserQuestion gdy blokuje | §3 wykonuj do końca, nie zatrzymuj się po planie (plan na życzenie → czekaj na „działaj”); STOP gdy brak danych — najpierw zrzut wiki, pytanie dopiero potem; §12 wyjątek: zgłoś i czekaj | zgłoś i uzyskaj potwierdzenie (doradca) | zgłoś, zaproponuj lepsze | PoB §3+§12 + Foldery | najpełniejsze: autonomia + wyjątek + „najpierw sprawdź sam, potem STOP i pytanie” |
| Zakres pracy | brak reguły | §0.2: tylko projekt, `_tmp\`, nie zaglądać do dokumentów, rejestru, innych dysków | „nic poza tym repozytorium” | brak | Expert + PoB | O0 §8 „bez sandboxa deny nie jest granicą” → reguła tekstowa + deny na wrażliwe ścieżki |
| Format odpowiedzi | „Zmiany w tej odpowiedzi” → „Następny krok” → pytanie; hook Stop przypomina | CO DALEJ + raport otwarcia | „odpowiedź najpierw, dowody potem” | zwięźle, wprost | Foldery | jedyny z mechanizmem (Stop hook) |
| Przekazanie następnego kroku | prompt do pliku (właściciel nigdy nie wkleja); model/effort/agenci wg `EFFORT-ZASADY.md`, skill `/przekazanie` | pełny prompt w rozmowie jako blok do skopiowania (decyzja 2026-10-01) + blok USTAW z `EFFORT-ZASADY.md` | — | — | remis: dwie przeciwne decyzje właściciela | w bazie jawny wybór A/B; wspólne: model, effort, agenci z uzasadnieniem przy każdym kroku |
| Weryfikacja | test najpierw (ma paść), skrypt testów, recenzent read-only przy nietrywialnych, „powiedz, czego NIE uruchomiono” | „nigdy »działa« bez uruchomienia”, macierz runnera PC/chmura, liczby tylko zmierzone, zrzuty pokazane w rozmowie | protokół eksperymentów: jawne flagi, n, `[MEASURED]` | „użyj ≥ 1 agenta do sprawdzenia” (bez bramki) | Foldery + PoB | O0 §6 (recenzent w świeżym kontekście); playbook §1.3 (recenzja znalazła błędy w 5 z 8 plików [MEASURED]) |
| Stan między sesjami | STATUS ≤ 6 KB nadpisywany, BACKLOG, CHANGELOG, „przepisz do stanu bieżącego”, jedna sesja ze zmianami naraz | STAN ≤ 6 KB + Pamietac + Niedokonczone (trzy rozłączne pliki); „nigdy dwa scalania naraz”, podział pracy = podział plików | findings.md, exceptions.md (dla KB) | „zapisz zlecenie w repo” | Foldery | kryterium 6; dwa pliki (STATUS + BACKLOG) to mniej do utrzymania niż trzy |
| Agenci | reguły hookiem SubagentStart; nie pytają; model+effort jawnie; worktree z origin/main → commit+push+merge | „ta sekcja nie obowiązuje subagenta”; `omitClaudeMd`; deny wiąże agentów; fachowcy z modelem i effortem | jawne flagi `claude -p`; bramka kosztowa | tylko definicja „pomocnicy” | Foldery + PoB §2 | kryteria 3, 4, 9 |
| Git, trwałość | merge do main z bramką hooków, fallback PR, dry-run, osobne wywołania Bash | „scal”/„scal wszystkie”, gałąź na PC (`git switch -c`), numer wersji przy scalaniu, 403 przy usuwaniu gałęzi | gałąź sesji, push przed końcem tury, właściciel scala | „commituj i pushuj” | Expert ≈ Foldery; pomysły PoB | kryterium 5; polityka scalania to decyzja projektu (trzy pliki mają trzy różne) |
| Egzekwowanie i granice | lista twardych, znane obejścia, kiedy zmiany wchodzą, disableAllHooks | „twarde zakazy = deny w settings.json” | start w katalogu głównym (reguła ogólna); lista kontrolna dla innych | zasada „mechanizmy, nie dobra wola” | Foldery | kryterium 2 |
| Zmiany tego pliku | zgoda + prompt uprawnień, oryginał z datą w ZASADY-UZYTKOWNIKA, klasyfikator | brak | pytaj o zgodę; działa od nowej sesji | tylko za zgodą | Foldery | kryterium 7 + ślad decyzji + mechanizm |
| Środowisko | chmura vs Windows; hooki wymagają python3 | tabela 4 środowisk; §6 „każda zmiana ma dalej działać w chmurze” | tylko chmura | „ma działać tak samo” | PoB (tabela, §6) + Felix (wymóg) | O0 §7; tabela ścięta do 2 wierszy |
| Szum | fakty o sprzęcie, CI, styl kodu (projektowe) | historia, daty, ID planów, decyzje | tabela KB (domenowe) | patron, nazwa | Expert / Foldery | playbook §5 „co wyrzucać” |
| Sprzeczności | brak istotnych | §3/§12 rozstrzygnięte, ale zapisane dwa razy; 0.5 vs §5 (changelog „tylko na życzenie” vs obowiązkowe wpisy ZMIANY/PROGRESS — różne artefakty, mylące nazwy) | otwarte konflikty nazwane jawnie (dobra praktyka) | brak | Expert | O0 §6: konflikt reguł = dowolny wybór |

## 5. Plik wynikowy: co wzięto, co odrzucono

### Wzięte (element → źródło → dowód)
| Element | Z czego | Dlaczego |
|---|---|---|
| Chmura i PC mają działać tak samo; tabela „Environment” (2 wiersze) | Felix + PoB §1 | O0 §7, §2: różnice są realne (auto memory tylko na PC), więc trzeba je nazwać |
| Widoczna linia „mechanizm istnieje tylko, gdy jest w repo; brak → powiedz i traktuj jako radę” + lista kontrolna mechanizmów w komentarzu HTML | nowe (recenzja, zarzut 1) | O0 §8: reguła bez mechanizmu to rada; szablon nie może udawać, że hooki już są |
| Polski w odpowiedziach i raportach dla właściciela; angielski w reszcie repo | Felix (raporty PL) + Expert/Foldery (repo EN) | spójne ze wszystkimi czterema; decyzja do potwierdzenia przez właściciela (§6) |
| Tłumaczenie terminów; polska terminologia prawnicza → sprawdź i potwierdź | Expert + Felix | cecha właściciela, uniwersalna |
| „Zgłoś i potwierdź” jako wyjątek od „wykonuj do końca”; plan/audyt na życzenie → oddaj i czekaj | Foldery + PoB §3, §12 | jedna reguła z wyjątkiem, zapisana raz |
| „Nie zgaduj”: liczby z uruchomienia, szacunki oznaczone; nie zgaduj nazw/sygnatur API (plik:linia); najpierw sprawdź sam, STOP i pytanie, gdy odpowiedź jest wiedzą właściciela | PoB §3, §7, §10 + Expert | O0 §6 (fałszywe „gotowe”, sykofancja) |
| Czytaj plik w całości; mów, czego nie zrobiłeś; NOT RUN zamiast „przeszło” | Felix + Foldery | O0 §6 |
| Tylko to repozytorium; pliki robocze w scratchpadzie / `_tmp/`; dozwolone: dokumentacja i rejestry pakietów (odczyt), pliki wgrane przez właściciela, narzędzia ze skryptu setup | Expert + PoB §0.2 | O0 §8 |
| Pliki `.bat`, wyniki do plików, czat = streszczenie | Foldery + PoB §8 | wspólne obu; forma promptu następnej sesji — osobny wybór A/B (niżej) |
| Zgoda na wszystko, co widać na ekranie właściciela | PoB §0.1 | uniwersalne przy computer-use; Foldery też to wspomina |
| Zakończenie odpowiedzi + hook Stop | Foldery | jedyny wariant z mechanizmem |
| Zmiany tego pliku za zgodą, wymuszone regułami `ask` na `Edit(/CLAUDE.md)`, settings, agent-rules, agents, hooks, rules, skills (nie `.claude/**` — tam leżą worktree agentów); oryginał z datą w OWNER-RULES | Foldery l. 29 (prompt uprawnień) | O2 §D4; O0 §4 (klasyfikator wyłącza worktrees z ochrony `.claude/`); [ASSUMPTION: czy `ask` pyta w trybie auto i czy nie łapie worktree — sprawdzić na atrapie] |
| Start: hook SessionStart, STATUS, MAPA z rozmiarami, Read ≤ 40 KB dla markdownu, skille przed pracą w obszarze, reguły `paths` | Foldery + Expert + PoB §13 | O0 §1, §2, [CL 2.1.293] |
| „Nie ufaj pamięci o Claude Code: FINDINGS, dokumentacja, w repo z KB O0” | Felix + Expert | O0 §6 (stale prompts), warunkowo zamiast obowiązkowo |
| Każda zmiana ma dalej działać w chmurze; skrypt setup naprawiany w skrypcie, nie obchodzony ręcznie | PoB §6 | pogodzone z Foldery „exit ≠ 0 → idź dalej”: idź dalej, ale napraw w tej sesji albo wpis do BACKLOG |
| Weryfikacja: test najpierw, recenzent read-only w świeżym kontekście także dla planów/analiz/promptów, na które właściciel będzie działał (bez pytania do ~1 USD, powyżej szacunek i pytanie); zrzuty pokazane w rozmowie, nie archiwizowane | Foldery + Felix + PoB §0.3, §4 | O0 §3 T3-38; playbook §1.3 |
| Stan: STATUS, BACKLOG, CHANGELOG, jedna sesja ze zmianami naraz, przepisz do stanu bieżącego, jedna reguła jedno miejsce, limity (reguły bez `paths` liczą się do limitu tego pliku), kod wygrywa z dokiem, FINDINGS z dowodami | Foldery + PoB §0.7 + Expert | O0 §1/§8, §2 (reguły bez `paths` ładują się na starcie) |
| Agenci: subagent nie podlega regułom formatu/pytań (zgoda na ekran nadal obowiązuje: tylko z „tak” w prompcie zadania); nie widzą rozmowy; reguły hookiem SubagentStart *jeśli jest*, inaczej w prompcie; nie pytają; bramka kosztowa (recenzent zmiany kodu bez pytania; recenzent planu/analizy/promptu do ~1 USD, powyżej szacunek i pytanie); jawny model/effort; read-only = bez Bash/MCP/Agent; worktree z `origin/<default>` → `baseRef: "head"` + commit, merge tylko przy polityce A | Foldery + PoB §2, §13 + Expert + O0 §8 | O0 §2, §3, §5, §8 |
| Minimum effortu agentów jako decyzja właściciela (Foldery: ≥ high dla wszystkiego, 2026-10-08; PoB §13: zwiadowca medium; KB: medium na start) | Foldery + PoB + O0 §8 | konflikt reguł właściciela — zgłoszony, nie rozstrzygnięty |
| Git: gałąź sesji w chmurze, `git switch -c` na PC, push przed końcem tury, bez force-push, 403 przy usuwaniu gałęzi, polityka scalania A/B (wersja przy scalaniu tylko w A; w B wersja na gałęzi, merge `origin/main` przed PR, jeden PR z wersją naraz), produkt bez plików roboczych | Expert + Foldery + PoB §0.6, §5, §11 | O0 §7 |
| Następny krok: wybór A (STATUS, właściciel pisze „dalej”) / B (pełny prompt w rozmowie + plik); zawsze model, effort, agenci z uzasadnieniem (`EFFORT-RULES.md`) | Foldery + PoB §0.8 | dwie przeciwne decyzje właściciela (Foldery 2026-10-09 vs PoB 2026-10-01) — jawny wybór |
| Enforcement: lista twardych; warunek startu w katalogu głównym i jednego repo; obejścia; ochrona gałęzi tylko w płatnym planie bez wyjątku admina; sandbox niezmierzony; `onFailure: "block"` tylko na wąskich bramkach; disableAllHooks + droga awaryjna; kiedy zmiany wchodzą (model/effortLevel na starcie, `/reload-skills`); przegląd po zmianie modelu i wersji CC | Foldery + Felix + Expert + O0 §4/§7/§8 + [CL 2.1.295] | kryterium 2, 7; O0 §9 |
| Komentarze HTML z pochodzeniem każdej sekcji | nowe (KB) | [CL 2.1.72]: zero kosztu kontekstu; dla właściciela mapa „skąd co” |

### Odrzucone (element → źródło → powód)
| Element | Źródło | Powód odrzucenia |
|---|---|---|
| Raport otwarcia w każdej odpowiedzi („OTWARTE / TRYB / ŚRODOWISKO / STAN / SKILLE”) | PoB §2 | koszt w każdej turze; „brak raportu = odpowiedź nieważna” nie ma mechanizmu; to samo robi raz hook SessionStart; samoraport nie jest dowodem — dowód to log narzędzia (hook `InstructionsLoaded` loguje tylko CLAUDE.md i `.claude/rules` [O2 §A5], recenzent sprawdza resztę) |
| Polski jako język pliku | PoB | ok. +23 % tokenów [MEASURED O0]; reguła właściciela: pliki Claude po angielsku |
| Historia, daty decyzji, ID planów w regułach | PoB | szum obniżający posłuszeństwo (O0 §6); playbook §5; historia → CHANGELOG/OWNER-RULES |
| STAN + cała MAPA na start | PoB §2 | budżet startu (O0 §1); w bazie STATUS + MAPA §1 (rozmiar całej MAPY niezmierzony — różnica niepoliczona) |
| Trzy pliki pamięci (STAN, Pamietac, Niedokonczone) | PoB §0.7 | rozłączne, ale trzy pliki do utrzymania; STATUS + BACKLOG pokrywają to samo |
| Reguły domenowe PoB (zgodność buildów, RePoE, wiki, The Simulation, changelogi dla graczy) | PoB §0.4, §0.9, §9, §10 | projektowe; w bazie tylko wzorzec „STOP przy braku danych, nie szukaj zastępczego źródła” |
| „Heredoc w bashu pada na apostrofach → skrypt .py przez Write” | PoB §7 | technika narzędziowa, nie reguła; heredoc z cudzysłowionym znacznikiem (`<<'EOF'`) nie ma tego problemu; miejsce: reguły/skill |
| Fakty o sprzęcie, Windows CI tylko ręcznie, „kod bez komentarzy”, dokumentacja AI w osobnym folderze | Foldery | projektowe/stylistyczne → `.claude/rules/` lub MAPA |
| „Opus 5.5 high dla sesji” jako tekst | Foldery | CLAUDE.md nie ustawia modelu sesji; robi to `settings.json` (`model`, `effortLevel`, O2 §D3; `effortLevel` w ustawieniach użytkownika nie działa na Opus 5.5, zakres projektu niezweryfikowany, O0 §5) |
| Tabela plików KB, tagi dowodów, otwarte konflikty, świeżość, live lookups | Expert | domenowe (asystent nad KB); w bazie zostaje FINDINGS z dwoma tagami, bramka kosztowa, reguła startu w katalogu głównym |
| „≥ 1 agent przy każdym planie/analizie/prompcie/kodzie” bez progu | Felix | koszt: recenzja 0,8–1,8 USD na jednostkę [playbook §1.3, MEASURED-derived], start agenta ~0,25–0,30 USD [playbook §7, ASSUMPTION]; w bazie: recenzent dla nietrywialnych zmian ORAZ dla planów/analiz/promptów, na które właściciel będzie działał — bez pytania do ~1 USD, powyżej szacunek i pytanie |
| Obowiązkowe O0 na starcie | Felix | tylko w repo z KB (ok. 17,7 tys. tokenów); w bazie reguła warunkowa „nie ufaj pamięci; w repo z KB czytaj O0” |
| „Mów w języku, w którym pisze właściciel” | Felix | pozostałe trzy pliki i preferencje właściciela: polski; w bazie polski |
| Patron, nazwa, „as much automation as possible” | Felix | ozdobniki bez reguły |
| Scalanie przez Claude jako jedyna polityka | Foldery | w Expert scala właściciel, w PoB tylko na „scal”; baza daje wybór A/B |
| Usuwanie gałęzi po scaleniu | PoB §11 | w chmurze 403 (O0 §7 [MEASURED]) — w bazie tylko zakaz; usuwa właściciel |

## 6. Ryzyka, decyzje właściciela, rzeczy niezweryfikowane
- **Szablon to jedna część zestawu.** Bez zestawu startowego (settings z deny/ask, hooki SessionStart/Stop/SubagentStart/bramka pusha, agenci, skille, szkielety STATUS/MAPA/BACKLOG/OWNER-RULES) opisane mechanizmy nie istnieją; szablon mówi to Claude wprost (widoczna linia) i właścicielowi (komentarz). Hooki testować najpierw na repo testowym (playbook §8 p. 3; O0 §3: zepsuty hook psuje sesję od razu).
- **Decyzje właściciela, których baza nie rozstrzyga** (placeholdery): polityka scalania A/B; forma przekazania następnego kroku A/B; minimum effortu agentów (≥ high wg Foldery 2026-10-08 vs medium wg KB i PoB §13); język raportów (polski wg Felixa — przyjęty); recenzent dla planów/analiz/promptów bez pytania tylko do ~1 USD, powyżej szacunek i pytanie (Felix bez progu — odrzucony, patrz N3); auto memory na PC (wyłączyć czy ignorować); przeniesienie szczegółów „Enforcement” do reguły z `paths` (N6).
- **Limit 20 KB** to reguła właściciela z Foldery (l. 85), dwukrotność budżetu z playbooka §8 (~10 KB). Szablon v2.1 ma 17,7 KB / 6 179 tokenów widoczne dla Claude (89 % limitu) i 20,7 KB na dysku; limit w szablonie liczy się bez komentarzy HTML (ukrytych przy ładowaniu), co `doc_check` musi uwzględniać. To o 36–40 % więcej niż Foldery i każdy agent ładujący CLAUDE.md płaci ten koszt (O0 §8). Po wypełnieniu placeholderów projekt powinien ciąć, nie dopisywać. Opcja recenzenta (N6): szczegóły operacyjne z „Enforcement” (obejścia, `onFailure`, droga awaryjna, kiedy zmiany wchodzą, lista przeglądu) przenieść do `.claude/rules/enforcement.md` z `paths: [".claude/**"]` — ładuje się tylko przy pracy na hookach i ustawieniach (O2 §D5, [CL 2.1.293]); w głównym pliku zostaje punkt „co twarde, co rada”; usunięcie niewybranych wariantów A/B daje jeszcze ~1 KB. Decyzja właściciela.
- **Twierdzenia przeniesione z plików właściciela bez własnego pomiaru** (traktować jak [3P]): „agenci workflow mogą nie dostać hooka SubagentStart” (Foldery), „hooki bez python3 na Windows nie działają” (Foldery), lista obejść hooków (Foldery `test_hooks.sh`), 403 przy `git push --delete` (PoB; zgodne z O0 §7). Projekt potwierdza je własnym `test_hooks.sh`.
- **[ASSUMPTION] w szablonie:** reguła `ask` pyta w trybie auto; `blockReadsOutsideWorkingDirectories` działa jak opisano w docs; `autoMemoryEnabled` w zakresie projektu; zablokowanie edycji `settings.local.json` przez bramkę z `onFailure` (wyprowadzone z brzmienia changelogu).
- Pomiar tokenów: n=1 na plik (recenzent powtórzył: ±1); po zmianie modelu przeliczyć (O0 §9).
- Czego CLAUDE.md nie zrobi, choć pliki tego próbują: nie ustawi modelu sesji, nie zablokuje pusha, nie wymusi recenzji ani raportu. Każdy taki punkt w szablonie wskazuje mechanizm (hook, deny, settings.json) albo mówi, że jest radą.

## 7. Recenzja (Opus 5.5, effort max, świeży kontekst) i zmiany po niej
Recenzent przeczytał cztery pliki, O0, O5 i playbook w całości, O2 §A i §D, findings, changelog; powtórzył pomiary (±1 tok.); werdykt: „akceptuję po poprawkach”, warunki: zarzuty 1–11. Co zmieniłem:

| Zarzut | Waga | Decyzja | Zmiana |
|---|---|---|---|
| 1. Szablon opisuje mechanizmy jako istniejące | blokujący | przyjęty | widoczna linia „mechanizm istnieje tylko, gdy jest w repo…”; lista mechanizmów w komentarzu; SubagentStart warunkowo; reguła `ask` na CLAUDE.md/`.claude/`; §6 o zestawie startowym. Nie zamieniłem każdego zdania na `<If …>`: jedna reguła ogólna + lista kontrolna daje to samo bez rozdęcia pliku |
| 2. Worktree „commit + push first” | ważny | przyjęty | `origin/<default>` + `baseRef: "head"` + commit; merge tylko w polityce A |
| 3. `onFailure: "block"` na każdej bramce vs python3 | ważny | przyjęty | tylko wąskie bramki; wiersz PC poprawiony; droga awaryjna dla właściciela |
| 4. Warunki twardych zabezpieczeń | ważny | przyjęty | start w katalogu głównym i jedno repo; ochrona gałęzi: płatny plan, bez wyjątku admina; sandbox niezmierzony |
| 5. Reguła dla subagentów ładujących plik | ważny | przyjęty | pierwszy punkt sekcji „Agents” |
| 6. Wersja przy scalaniu tylko w A; sesje równoległe | ważny | przyjęty | polityka B rozpisana; „jedna sesja ze zmianami naraz” przywrócona |
| 7. Chmura = PC niezrealizowane | ważny | przyjęty | gałąź na PC; auto memory; PoB §6; „brak narzędzia do plików → powiedz” |
| 8. Reguły właściciela zmienione bez zgłoszenia | ważny | przyjęty | effort jako jawna decyzja; raporty po polsku; „czytaj w całości”; terminologia prawnicza; „pomocnicy” |
| 9. Brak reguły zakresu | ważny | przyjęty | „tylko to repozytorium” + mechanizm w Enforcement + wiersz w §4 |
| 10. „Identyczna reguła” o prompcie; EFFORT-ZASADY | ważny | przyjęty | wybór A/B dla następnego kroku; model/effort/agenci z uzasadnieniem; wiersz w §4 |
| 11. Cztery nowe sprzeczności | ważny | przyjęty | wszystkie cztery przeredagowane wg propozycji |
| 12. Rdzenie Felixa | zalecenie | przyjęty | recenzent także dla planów/analiz/promptów (w bramce); „nie ufaj pamięci; w repo z KB czytaj O0” |
| 13. Zawyżone tagi i cytaty | drobny | przyjęty | +23 % [MEASURED O0] zamiast +25–35 %; tagi playbooka; InstructionsLoaded; O0 §6; „blisko ~10 KB”; limit 20 KB = reguła właściciela |
| 14. Zniekształcenia PoB i Felixa | drobny | przyjęty | §1, §4, §5 poprawione (§3/§12 rozstrzygnięte; trzy rozłączne pliki; STAN + cała MAPA; Felix ma git i O0, nie „cały folder”) |
| 15. Nieścisłości w szablonie | drobny | przyjęty, poza (b) częściowo | limity w jednym miejscu; angielskie placeholdery hooka, STATUS i skilli; reguły bez `paths` w limicie; model/effortLevel na starcie; zastrzeżenie o `effortLevel`; `/reload-skills`; przegląd po wersji CC; „markdown ≤ 40 KB”; droga do PR. Zostawione po polsku: napisy w odpowiedziach dla właściciela („Zmiany w tej odpowiedzi”, „Następny krok”, „Pytanie do Ciebie”, „brak zmian”, „dalej”) — to treść czatu, który ma być po polsku, nie treść repo |
| 16. Sekcje PoB bez analizy | drobny | przyjęty, poza heredokiem | §0.3 zrzuty, §0.6 produkt bez plików roboczych, §7 „nie zgaduj sygnatur” — wzięte; heredoc odrzucony (technika, nie reguła; `<<'EOF'` nie ma tego problemu) |

Runda 2 (recenzent sprawdził, że wszystkie 16 poprawek jest w plikach i zgadza się z KB; pomiar powtórzony: ±1 tok.; odrzucenia 1a, 15b i heredoca przyjęte): werdykt „akceptuję po poprawkach”, warunki N1–N3, po ich wprowadzeniu akceptacja bez kolejnej rundy.

| Zarzut (runda 2) | Waga | Decyzja | Zmiana |
|---|---|---|---|
| N1. Subagenci zwolnieni ze zgody na ekran (brzmienie z zarzutu 5 recenzenta) | ważny | przyjęty | „…reply format and questions do not apply to you, and you act on the owner's screen only if your task prompt states his yes for this run” |
| N2. `ask` na `Edit(/.claude/**)` objęłoby worktree agentów w `.claude/worktrees/` (brzmienie z zarzutu 1d) | ważny | przyjęty | jawna lista plików w komentarzu (settings, agent-rules, agents, hooks, rules, skills), w treści „never `Edit(/.claude/**)`”, placeholder weryfikacji także dla worktree |
| N3. Recenzent bez limitu kosztów; raport mówił co innego niż szablon | ważny | przyjęty | „the reviewer of a non-trivial code change: run it. A reviewer for a plan, analysis or prompt: run it if it fits ~1 USD, otherwise give the estimate and ask”; raport ujednolicony |
| N4. Reguła zakresu zabrania rzeczy koniecznych (docs, pliki wgrane, setup) | drobny | przyjęty | „Allowed: the official docs and package registries (read), files the owner sent to this session, tools installed by the setup script” |
| N5. Polityka B: „paczka na gałęzi” czytelne jako commit paczki | drobny | przyjęty | „the package is built from it and sent, never committed” |
| N6. Rozmiar: 17,7 KB widoczne = 89 % limitu przed wypełnieniem | informacja | opcja dla właściciela | opisana w §6 (reguła `paths` dla szczegółów Enforcement; usunięcie niewybranych wariantów A/B) |
