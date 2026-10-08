# Zasady ogólne migracji systemu dokumentacji projektów prowadzonych przez Claude Code

Wersja 1 · 2026-10-08 · Claude Code 2.1.294 · źródło przypadku: `reports/foldery-analysis.md` i `reports/foldery-migration-plan.md` (wersja 4, po recenzji „meta” i technicznej).
Słowniczek pojęć: `reports/foldery-analysis.md`, początek pliku.

## 0. Jak tego używać

- To baza do pisania planu migracji **innego** projektu. Nie jest to gotowy plan. Każda zasada ma cztery części: **regułę**, **dowód** (z tagiem), **sprawdzian** (jak zweryfikować w danym projekcie) i **kiedy nie stosować**.
- Wyprowadzone z **jednego** przypadku (Foldery) oraz z bazy wiedzy (KB) tego repo. Wartości liczbowe (np. limity bajtów) to **parametry do zmierzenia w każdym projekcie**, nie stałe. Pomiary oznaczone n=1 są anegdotą do potwierdzenia [ASSUMPTION co do przenośności].
- Fakty o Claude Code dotyczą wersji 2.1.294. Po nowej wersji sprawdź je według listy z O0 §9 i rozdziału 7.

Struktura dokumentu:
1. Zasady pomiaru.
2. Zasady ładowania (co, kiedy i komu trafia do kontekstu).
3. Zasady treści i odsyłaczy.
4. Zasady egzekwowania reguł.
5. Zasady dla agentów i chmury.
6. Zasady procesu migracji.
7. Szablon planu.
8. Parametry do ustalenia per projekt.
9. Granice uogólnienia.

---

## 1. Pomiar

**Z1. Mierz wagi tokenami, nie znakami.**
- Reguła: każdą decyzję o rozmiarze opieraj na pomiarze. Najtańsza metoda: katalog roboczy poza repo z `CLAUDE.md` zawierającym `- @plik` dla każdego mierzonego pliku, potem `claude -p "/context" --model <m> --effort <e> --permission-mode default --max-turns 1 --max-budget-usd 0.5` i odczyt tabeli Memory files. Druga metoda: licznik w błędzie Read.
- Dowód: znaki/3,2 i bajty/4 mylą o 13–55% [MEASURED: O0 §1]. Metoda `/context` z importami kosztowała 0 USD [MEASURED: Raport Foldery B3]. Bajty na token zależą od języka: polski md 1,9–2,3, angielski 2,7 [MEASURED: O0 §1, Raport B3].
- Sprawdzian: ten sam plik zmierzony dwiema metodami daje wyniki zgodne w granicach kilku procent.
- Kiedy nie stosować: nigdy nie pomijaj. Po zmianie modelu zmierz ponownie, bo tokenizer się zmienia [SOURCE: O0 §1, PL token-counting].

**Z2. Najpierw inwentarz, potem decyzje.**
- Reguła: dla każdego pliku instrukcji lub dokumentacji ustal bajty, linie, tokeny, **kiedy się ładuje** i **kto go dostaje** (główne okno, które agenty).
- Dowód: w Foldery dopiero inwentarz pokazał, że plik opisany jako „czytaj tylko części” ładuje się w całości wszystkim [MEASURED: Raport §2, B4].
- Sprawdzian: inwentarz wymienia każdy `CLAUDE.md`, `AGENTS.md`, `.claude/rules/*`, skille, pliki, do których CLAUDE.md każe zaglądać, i strażników.

---

## 2. Ładowanie

**Z3. Zawsze ładowane = tylko to, czego potrzebuje każde okno i każdy agent.**
- Reguła: główny `CLAUDE.md` krótki. Parametr startowy: ≤ 200 linii (docs) i budżet tokenów ustalony świadomie, w Foldery ≤ ~5k. Wszystko inne ładuje się na żądanie.
- Dowód:
  - CLAUDE.md jest wiadomością w każdym zapytaniu;
  - dłuższy plik obniża przestrzeganie reguł [SOURCE: CC memory.md: „target under 200 lines … reduce adherence”];
  - płaci go każdy agent, który go ładuje (ok. 0,5k na każde KB, O0 §8);
  - plik o rozmiarze 31,6 KB zwiększał start agenta o 16k tokenów [MEASURED: O0 §2].
- Sprawdzian: `/context` na starcie nowej sesji; suma Memory files ≤ budżet.
- Kiedy nie stosować: repo-baza wiedzy, które *celowo* ładuje dużo, jak to repo (świadomy koszt, findings.md 2026-10-08).

**Z4. Zagnieżdżony `CLAUDE.md` nie jest „leniwy po kawałku”.**
- Reguła: nie traktuj podkatalogowego `CLAUDE.md` jako sposobu na czytanie wybranych części. Ładuje się **cały** przy pierwszym dotknięciu pliku w tym katalogu, i to wszystkim.
- Dowód:
  - ładuje się przy Read/Write/Edit [SOURCE: CC memory.md];
  - także przy `cat` i `head` w Bash, ale nie przy Grep ani `python3 open()` [MEASURED n=1: exceptions.md 2026-10-08];
  - trafia też do agenta Explore, który pomija CLAUDE.md na starcie [MEASURED n=1: findings.md 2026-10-08];
  - nie widać go w `/context` → Memory files [SOURCE: CC memory.md];
  - po kompaktowaniu wypada i wraca przy następnym dotknięciu [SOURCE: CC context-window.md].
- Sprawdzian: grep transkryptu sesji lub agenta (`~/.claude/projects/<projekt>/*.jsonl`) na wpis `nested_memory` z jego ścieżką.
- Kiedy stosować: krótkie, lokalne reguły katalogu (kilka KB), np. w monorepo [SOURCE: CC large-codebases.md].

**Z5. Import `@` organizuje, ale nie oszczędza.**
- Reguła: `@plik` ładuje cały plik razem z plikiem importującym, bez limitu Read. Używaj go tylko do rzeczy, które i tak mają być zawsze w kontekście.
- Składnia:
  - jeden import na linię;
  - ścieżka względem pliku importującego;
  - spacje poprzedzaj `\`;
  - nie w cudzysłowie i nie w backtickach;
  - maks. 4 poziomy zagnieżdżenia.
- Dowód:
  - [SOURCE: CC memory.md: „imports … don't reduce its context cost”];
  - import 219 KB wszedł w całości [MEASURED: findings.md 2026-10-08];
  - `@a.md, @b.md` z przecinkiem po cichu gubi pierwszy plik [MEASURED: findings.md 2026-10-08].
- Sprawdzian: `/context` → Memory files wymienia każdy importowany plik.

**Z6. Reguły `.claude/rules/` z `paths` są selektywne tylko tak, jak selektywny jest podział kodu.**
- Reguła: użyj reguły z `paths`, gdy wiedza dotyczy konkretnych plików. Jeśli cały kod jest w jednym pliku, reguła na ten plik ładuje się przy *każdej* pracy z kodem. Wtedy to po prostu „ładowane przy kodowaniu”, a nie „ładowane per obszar”.
- Dowód:
  - ładuje się przy Read/Write/Edit pasującego pliku [SOURCE: CC memory.md];
  - także przy `cat`/`head` i u agentów, w tym Explore [MEASURED n=1];
  - jedyne czytane pole frontmattera to `paths`; zepsuty YAML = reguła ładowana zawsze [SOURCE: CC memory.md „Rule frontmatter reference”];
  - po kompaktowaniu wraca dopiero przy dopasowaniu [SOURCE: CC context-window.md].
- Sprawdzian: komunikat „Loaded …” albo wpis `nested_memory` po Read pasującego pliku. W projekcie z worktree sprawdź dopasowanie ścieżki z kopii `.claude/worktrees/…` (we wzorcu np. `**/`) [ASSUMPTION: w Foldery niezweryfikowane, test w planie A7.3].
- Kiedy nie stosować: reguły bez `paths`, bo ładują się zawsze, jak CLAUDE.md.

**Z7. Plik przeznaczony do przeczytania w całości mieści się w jednym Read.**
- Reguła: limit Read to 25k tokenów na wywołanie. Większy plik czytany bez `offset/limit` daje widok częściowy (PARTIAL view), a plik > 256 KB bez `limit` daje błąd. Parametr startowy: ≤ 20k tokenów, co w bajtach oznacza ok. 40 KB dla polskiego tekstu i ok. 54 KB dla angielskiego (przelicz współczynnikiem z Z1).
- Dowód: [CODE/MEASURED: O0 §1]. W Foldery plik „READ FIRST” miał 29,4k tokenów [MEASURED].
- Sprawdzian: `doc_check` z limitem bajtów (Z14) + pomiar tokenów próbki według Z1.

**Z8. Skill to procedura, nie encyklopedia.**
- Reguła: procedury wieloetapowe (dostawa, przekazanie pracy) zamieniaj w skille wywoływane jawnie `/nazwa`. Wiedzy referencyjnej nie wkładaj w skille dobierane po opisie.
- Dowód:
  - w kontekście jest zawsze tylko opis (≤ 1 536 znaków), a treść dochodzi po wywołaniu [SOURCE: CC skills.md];
  - po kompaktowaniu wraca ≤ 5k tokenów na skill [SOURCE: CC context-window.md];
  - dobór po opisie jest zawodny [SOURCE: CC plugin-evals przez O4 §5].
- Sprawdzian: skill widoczny na liście; wywołany jawnie wykonuje kroki.

---

## 3. Treść i odsyłacze

**Z9. Stan bieżący oddzielony od historii.**
- Reguła:
  - plik obszaru opisuje stan obecny;
  - historia trafia do `CHANGELOG.md` i git;
  - stan i następne zadanie są w małym pliku **nadpisywanym** (`STATUS.md`), nie dopisywanym.
- Dowód: w Foldery ok. 70% instrukcji to historia warstwowa („newer supersedes older”) [ASSUMPTION: z proporcji znaków, Raport §2]. Strażnik wymuszał dopisywanie (Z15).
- Sprawdzian: brak lead-inów wersji (`**v4.`) w plikach oznaczonych jako skondensowane; STATUS ≤ limit.

**Z10. Jedna reguła = jeden operatywny zapis.**
- Reguła:
  - każda reguła ma jedno obowiązujące brzmienie;
  - kopie innych plików zastępuj odsyłaczem;
  - oryginał historyczny może istnieć, ale z nagłówkiem „obowiązuje: <plik>”.
- Dowód: przy sprzecznych instrukcjach model może wybrać dowolną [SOURCE: CC memory.md]. W Foldery reguła dokumentacji była w 4 kopiach, a nazwa paczki zip miała 2 sprzeczne brzmienia [SOURCE: pliki Foldery, Raport D4]. Recenzja „meta” odrzuciła przeniesienie starych zasad dosłownie do pliku ładowanego, bo wnosiły nieaktualne polecenia (plan, uwaga N1).
- Sprawdzian: grep kluczowych fraz reguły po całym repo.

**Z11. Odsyłacz to zwykła ścieżka w tabeli „zadanie → plik (rozmiar)”, a rozmiar pilnuje strażnik.**
- Reguła: jedna tabela nawigacyjna (np. MAPA §1) z kolumnami: zadanie, plik, rozmiar (w KB, sprawdzany automatycznie), „czytaj w całości / w częściach”. Nie wpisuj ręcznie liczb rozmiaru bez strażnika.
- Dowód: w Foldery wszystkie ręczne liczby rozmiaru były nieaktualne 2–3 razy [MEASURED: Raport D3].
- Sprawdzian: strażnik porównuje adnotację z rzeczywistym rozmiarem (tolerancja np. max(10%, 1 KB)) i sprawdza, czy ścieżki istnieją (martwe odsyłacze).

**Z12. Pliki dosłownie przeniesione noszą ostrzeżenie o pierwszeństwie.**
- Reguła: plik skopiowany 1:1 ze starego układu ma nagłówek: „przeniesione dosłownie; przy sprzeczności obowiązuje <nowy CLAUDE.md / skill>”.
- Dowód: kopie dosłowne zawierały nieaktualne polecenia (plan, uwaga T10).

---

## 4. Egzekwowanie reguł

**Z13. Rozdziel reguły twarde i miękkie, a każdą regułę „nigdy/zawsze” przypisz do mechanizmu.**

| Mechanizm | Twardość | Ograniczenie |
|---|---|---|
| reguła `deny` w `.claude/settings.json` | twarda na poziomie narzędzia | dopasowanie tekstu; skrypty i inne narzędzia omijają (O0 §4, §8) |
| hook PreToolUse z exit 2 | twarda dla danego narzędzia | tylko to narzędzie; hook, który nie wystartuje, nie blokuje [SOURCE: CC hooks part3] |
| strażnik w testach (skrypt) | twarda, gdy testy są uruchamiane | tylko gdy ktoś uruchomi testy |
| branch protection / ruleset | twarda po stronie serwera | prywatne repo = płatny plan; admin domyślnie omija (O0 §7) |
| CI na push | twarda po stronie serwera | koszt minut Actions |
| CLAUDE.md, reguły, skille, prompt | miękka | model „zwykle” stosuje [SOURCE: CC memory.md] |

- Dowód: O0 §8; CC memory.md („not a hard enforcement layer”).
- Sprawdzian: tabela w planie: reguła → mechanizm → prowokacja testowa.

**Z14. Strażnik dokumentacji to skrypt w testach, który sprawdza kształt, a nie historię.**
- Reguła: strażnik (`doc_check`) sprawdza:
  - wersję w CHANGELOG i STATUS;
  - limity bajtów;
  - martwe odsyłacze;
  - adnotacje rozmiaru;
  - poprawność frontmattera reguł;
  - zakazy (np. trigger CI).
  
  Ma test mutacyjny, który psuje dane i sprawdza, że strażnik to wykryje. Każdy odczyt przechodzi przez jedną funkcję `read()`, żeby test mógł ją podmienić.
- Dowód: wzorzec Foldery (`doc_check` + mutacja w `test_logic`) [SOURCE: pliki Foldery]; uwaga recenzenta o `read()` (plan A4.5).
- Sprawdzian: test mutacyjny pada, gdy strażnik nie wykrywa zmiany.

**Z15. Strażnik nie może nagradzać dopisywania.**
- Reguła: nigdy nie wymagaj „nowego wpisu o wersji w pliku opisowym”. Wpis o wersji należy do CHANGELOG i STATUS.
- Dowód: `doc_check` Foldery wymagał `v{ver}` w opisie architektury, co napędzało narastanie i było sprzeczne z regułą „przepisuj, nie dopisuj” [SOURCE: doc_check.py @be31a48].
- Sprawdzian: przejrzyj każdy warunek strażnika i odpowiedz, czy da się go spełnić bez powiększania pliku opisowego.

**Z16. Hooki: wzorce wykonania.**
- Wywołanie przez interpreter (`"command": "bash"` / `"python3"`, ścieżka w `args`). Nie polegaj na bicie wykonywalności, bo hook, który nie startuje, zostaje po cichu wyłączony [SOURCE: CC hooks part2–3; plan T2].
- Blokada przez exit 2 albo JSON z decyzją. Exit 1 nie blokuje [SOURCE: CC hooks part3].
- Polecenia Bash analizuj per podpolecenie (tokenizacja `shlex`), nie wyrażeniem regularnym po całym tekście. Regex blokował poprawne polecenia i przepuszczał force-push [MEASURED: plan, Załącznik S, 22/22].
- Nie blokuj pushu gałęzi roboczej. W chmurze to jedyna ochrona pracy przed utratą maszyny (O0 §7). Blokuj push na gałąź główną.
- Hook Stop nie zmusza do scalania ani do zielonych testów przy każdej odpowiedzi, bo popychałoby to model do scalania niegotowej pracy (plan A5). Do przypomnień używaj `additionalContext`, nie `block` [SOURCE: CC hooks part7].
- Stan „czy coś zmieniono w tej turze” licz per tura (UserPromptSubmit zapisuje bazę) z hashem uwzględniającym treść zmian. Sam `git status --porcelain` nie widzi ponownej edycji [MEASURED: plan T5].
- UserPromptSubmit i SessionStart: zwykły stdout trafia do kontekstu, więc hook zapisujący stan ma milczeć [SOURCE: O2 §A6].
- `additionalContext` ≤ 10 000 znaków [SOURCE: O2 §A6].
- Każdy hook testuj JSON-em na stdin (przypadek dozwolony i blokowany), zanim go zacommitujesz.

**Z17. Reguły `deny`: pułapki.**
- Gołe `deny` narzędzia usuwa je z kontekstu, a `Bash(...)` to dopasowanie tekstu [SOURCE: O2 §D4].
- Deny `Read`/`Edit` na ścieżce działa też na rozpoznane polecenia Bash (`cat`, przekierowania, prawdopodobnie `cp`). Może więc zablokować procedury, które kopiują pliki [SOURCE: CC permissions; ASSUMPTION dla `cp`, plan T6]. Ochronę ścieżki przed edycją rób hookiem na Edit/Write, gdy Bash ma dalej kopiować.
- Narzędzia zapisu GitHub MCP (push, tworzenie plików, merge, auto-merge, uruchamianie Actions) omijają hooki na Bash. Zablokuj je przez `deny`, jeśli sesje mają zapisywać tylko przez git (plan M15/T7).

---

## 5. Agenci i chmura

**Z18. Każdy rodzaj agenta dostaje reguły inną drogą.**

| Agent | CLAUDE.md na starcie | Pliki ładowane przy czytaniu | SubagentStart `additionalContext` | Preferencje claude.ai |
|---|---|---|---|---|
| general-purpose, własne definicje | tak | tak | tak | nie |
| Explore, Plan | nie | **tak** [MEASURED n=1] | tak | nie |
| definicja z `omitClaudeMd` | nie | [ASSUMPTION: tak] | tak | nie |
| agent workflow | tak (O0 §2) | [ASSUMPTION] | **niezweryfikowane** | nie |

- Reguła:
  - reguły dla agentów (zakazy, format raportu) w jednym pliku wstrzykiwanym przez SubagentStart;
  - w workflow powtarzaj je w promptach;
  - model i effort każdego agenta podawaj jawnie.
- Dowód: [SOURCE: CC sub-agents.md „What loads at startup”; CC hooks part7 „SubagentStart”; O0 §2, §5].
- Sprawdzian: transkrypt agenta, nie jego relacja.

**Z19. Chmura: warunki, bez których mechanizmy nie działają.**
- `.claude/` nie może być w `.gitignore`: sesja czyta tylko to, co jest w klonie [SOURCE: CC settings.md „Settings in cloud sessions”].
- `.claude/settings.json` (hooki, deny) działa tylko w sesji z **jednym** repo [SOURCE: CC settings.md, cloud-environments.md].
- Nowa sesja startuje z `origin/main` (O0 §7), więc nowe CLAUDE.md i agenci są widoczni dopiero po scaleniu.
- Polecenia `/context`, `/hooks`, `/permissions` wpisuje człowiek. Sesja wykonująca plan sprawdza skutki, transkrypt albo uruchamia zagnieżdżone `claude -p "/context"` (plan T3).
- Zapisy w `.claude/` to chroniona ścieżka; w auto mode ocenia je klasyfikator [SOURCE: CC permission-modes „Protected paths”]. Scalanie zmian CLAUDE.md było odrzucane jako „Self-Modification” [MEASURED n=2: findings.md 2026-10-06]. Zaplanuj ścieżkę zapasową: PR + scalenie przez właściciela, a pliki w `staging/` do wgrania ręcznie.
- Instalację środowiska przenieś do setup scriptu środowiska, który jest cache'owany. Warunki: < ~5 min, exit 0 [SOURCE: CC cloud-environments.md].

---

## 6. Proces migracji

**Z20. Dwa etapy: bezstratne przeniesienie, potem kondensacja po obszarze.**
- Reguła:
  - **Etap A** (jedna sesja): tekst przenosi skrypt według zakresów linii (konkordancja), a model go nie przepisuje. Dochodzą nowa nawigacja, strażnik, hooki i agenci.
  - **Etap B**: przepisanie „do stanu obecnego” obszar po obszarze, przy okazji pracy w obszarze, z recenzentem.
- Dowód: cały zysk ładowania wynika z położenia tekstu, a nie z jego zwięzłości (Z3–Z7). Przepisanie całości w jednej sesji koncentruje ryzyko utraty wiedzy (recenzja „meta”, plan Załącznik R). W Foldery: ~240k → ~5k tokenów na starcie po samym etapie A [ASSUMPTION: z budżetów planu, do zmierzenia w A7].
- Sprawdzian:
  - konkordancja: zakresy pokrywają wszystkie linie źródła bez luk i nakładek, a multizbiór linii źródła = suma multizbiorów linii w plikach docelowych;
  - wynik liczony na zapisanym commicie (SHA) przed późniejszymi edycjami;
  - skrypt konkordancji jest w repo.
- Kiedy nie stosować: mała dokumentacja (np. < 50 KB). Wtedy jednorazowe przepisanie z recenzją jest tańsze.

**Z21. Zanim zaczniesz czytać, usuń źródło z automatycznego ładowania.**
- Reguła: jeśli źródłem jest zagnieżdżony CLAUDE.md, pierwszym krokiem (po aktualizacji gałęzi) jest `git mv` do archiwum o innej nazwie. Plan migracji trzymaj poza katalogiem, który ładuje stary plik.
- Dowód: plik ładuje się przy pierwszym dotknięciu katalogu, także przez `cat` (Z4); recenzja „meta” M8. `git mv` nie ładuje pliku [ASSUMPTION: do sprawdzenia transkryptem, plan A0.2].
- Sprawdzian: brak wpisu `nested_memory` dla starego pliku w transkrypcie po pierwszym Read w katalogu.

**Z22. Strażnik i dokumenty zmieniaj w jednym commicie.**
- Reguła: przełączenie strażnika na nowy układ i przeniesienie dokumentów to jeden commit z zielonymi testami.
- Dowód: rozjazd = czerwone testy i blokada dostawy (plan, Ryzyka).

**Z23. Weryfikuj skutkami, w dwóch fazach odbioru.**
- Reguła:
  - (a) w sesji migracji: prowokacje każdej blokady. Pushe tylko z `--dry-run`; narzędzia sprawdzane przez nieobecność na liście albo z nieistniejącym celem, tak żeby błąd hooka niczego nie wysłał. Do tego testy i konkordancja.
  - (b) po scaleniu, w nowej sesji: pomiar ładowania i transkrypty agentów.
- Dowód: plan M1, M3, N4, T3; hooki działają w trwającej sesji po zapisaniu ustawień [SOURCE: CC debug-your-config.md], a CLAUDE.md dopiero w nowej (O0 §2).

**Z24. Wycofanie bez przepisywania historii.**
- Reguła: zapisz SHA gałęzi głównej przed scaleniem. Wycofanie = `git restore --source=<stary_main> --staged --worktree :/` + commit „do przodu”.
- Dowód: `git revert` zakresu zawodzi przy commitach scalenia (plan T13). Wiele projektów zakazuje force-pusha.

**Z25. Plan przechodzi recenzję w dwóch rolach.**
- Reguła:
  - recenzent „meta” ocenia sens i podejście i może je zakwestionować;
  - recenzent techniczny sprawdza mechanizmy i może uruchamiać tanie próby (hooki z JSON, regexy);
  - obaj tylko do odczytu, z ustalonym formatem raportu (ID, waga, dowód, poprawka) i z prawem „nic nie znalazłem”.
- Dowód: w Foldery recenzja „meta” zmieniła strukturę planu (dwa etapy), a techniczna wykryła, że twarde blokady w wersji 3 by nie działały [MEASURED: Raport plan, Załączniki R, T, S]. Recenzent tego samego modelu zmienia ok. 17% ustaleń [MEASURED: O0 §3].
- Kiedy nie stosować: zmiany kosmetyczne.

---

## 7. Szablon planu migracji (do wypełnienia per projekt)

1. **Kryteria sukcesu** (mierzalne): tokeny na starcie, tokeny przy pracy z kodem, maks. rozmiar pliku do czytania, bezstratność, lista blokad z prowokacjami, testy zielone, test mutacyjny strażnika.
2. **Decyzje właściciela**: zakres, zawartość paczek lub wydań, archiwum, CI, branch protection, kto wykonuje (model, effort, agenci), jak plan trafia do repo, wyjątki od reguł scalania.
3. **Wykonawca**: blok „model · effort · workflow”, prompt startowy, szacunek kosztu i czasu.
4. **Etap A**:
   - A0: aktualizacja gałęzi, archiwizacja źródła (Z21), pomiar bazowy (Z1), grep odwołań (`§N`, nazwy plików) w kodzie i testach;
   - A1: `.gitignore`;
   - A2: konkordancja (zakres → plik, stabilne identyfikatory sekcji);
   - A3: przeniesienie skryptem, nagłówki (Z12), dowód bezstratności na zapisanym SHA, poprawa odwołań;
   - A4: nowy CLAUDE.md, STATUS, nawigacja, strażnik + test mutacyjny (jeden commit, Z22);
   - A5: ustawienia, hooki, agenci, skille, ścieżka zapasowa dla klasyfikatora;
   - A6: odbiór w sesji (prowokacje, testy, recenzent), scalenie albo PR;
   - A7: odbiór w nowej sesji;
   - A8: setup script środowiska.
5. **Etap B**: reguła „kondensuj przy dotknięciu obszaru”, prawo odłożenia z wpisem w STATUS, recenzent per obszar, strażnik pilnujący plików skondensowanych, licznik nieskondensowanych w STATUS, usunięcie archiwum na końcu.
6. **Ryzyka i wycofanie** (Z24).
7. **Reguły dla następców** wpisane w nowy CLAUDE.md: jeden fakt w jednym miejscu, przepisuj zamiast dopisywać, limity, bez dużych importów, pomiar po zmianie modelu, okresowy `/doctor prompt-audit` (O0 §6).

## 8. Parametry do ustalenia w każdym projekcie

| Parametr | Wpływa na | Jak ustalić |
|---|---|---|
| Struktura kodu (jeden plik / wiele plików / monorepo) | selektywność reguł `paths` (Z6), podział plików wiedzy | `find`, rozmiary |
| Język dokumentacji | bajty/token → limity bajtów (Z7, Z14) | pomiar Z1 |
| Okno modelu agentów (1M vs 200K) | ile może wejść jednorazowo | O0 §1; model agentów |
| Gdzie pracuje Claude (chmura / lokalnie, system) | czy hooki bash działają; `.gitignore`, setup script (Z19) | środowisko |
| Jedno czy wiele repo w sesji | czy `.claude/settings.json` w ogóle się czyta | konfiguracja sesji |
| Plan GitHuba, prywatność repo | branch protection (Z13) | ustawienia repo |
| Limit minut CI | CI na push (Z13) | właściciel |
| Istniejący strażnicy / testy | gdzie wpiąć strażnika (Z14) | repo |
| Reguły właściciela (scalanie, paczki, język) | hooki i wyjątki planu | obecne instrukcje |
| Rozmiar dokumentacji | czy etap A/B ma sens (Z20) | inwentarz Z2 |

## 9. Granice uogólnienia i rzeczy niezweryfikowane

- **Wyprowadzone z jednego projektu.** Zasady Z3–Z8 i Z13–Z19 opierają się na dokumentacji i KB, więc są ogólne w zakresie wersji 2.1.294. Zasady procesu (Z20–Z25) to sprawdzone w recenzji rozumowanie, ale **plan Foldery nie został jeszcze wykonany**, więc skuteczność procesu w praktyce jest niezmierzona [ASSUMPTION].
- **Pomiary n=1:** ładowanie przez `cat`/`head`, zagnieżdżony plik u Explore, odmowy klasyfikatora. Powtórz po nowej wersji CC.
- **Niezweryfikowane:**
  - SubagentStart dla agentów workflow;
  - dopasowanie `paths` w worktree;
  - czy `git mv` ładuje zagnieżdżony plik;
  - czy deny `Edit` łapie `cp`;
  - działanie `/hooks` i `/permissions` w chmurze;
  - czy plik reguły > 25k tokenów ładuje się w całości.
- **Lokalnie (nie w chmurze):** dochodzą `~/.claude/` (CLAUDE.md, skille, ustawienia użytkownika), auto memory i zaufanie folderu dla `permissions.allow`. Dla projektów lokalnych sprawdź rozdział D2 w O2 i tabelę „What runs before you trust a folder” [SOURCE: CC permissions part3].
