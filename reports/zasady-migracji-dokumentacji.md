# Zasady ogólne migracji systemu dokumentacji: aplikacje właściciela budowane z Claude

Wersja 3.1 · 2026-10-08 · Claude Code 2.1.294 · po recenzji sceptyka (Załącznik Z) i przeglądzie trwałości planu Foldery 4.2 (Z27 poprawiona, nowe Z28–Z30).
Źródło przypadku: `reports/foldery-analysis.md` i `reports/foldery-migration-plan.md` (wersja 4).
Słowniczek pojęć: `reports/foldery-analysis.md`, początek pliku.

## 0. Zakres i jak tego używać

**Zakres:** wyłącznie Twoje aplikacje, które budujesz z Claude **w sesjach Claude Code w chmurze**, tak jak Foldery:
- maszyna wirtualna Linux;
- jedno repo na sesję, sesja startuje w korzeniu repo, gałąź sesji z `origin/main`;
- Ty pracujesz na Windowsie.

Poza zakresem: praca lokalna na komputerze programisty, inne systemy operacyjne, zespoły, cudze konfiguracje.

**Jak używać:**
- To baza do pisania planu migracji kolejnej aplikacji, nie gotowy plan.
- Każda zasada ma **regułę**, **dowód** (z tagiem), **sprawdzian** i, gdzie to ma sens, **kiedy nie stosować**.
- Liczby (limity bajtów, budżety) to **parametry do zmierzenia w każdym projekcie** (rozdział 8).
- Pomiary n=1 to anegdota do potwierdzenia.
- Fakty o Claude Code dotyczą wersji 2.1.294. Po nowej wersji sprawdź je według O0 §9.

Rozdziały:
1. Pomiar.
2. Ładowanie.
3. Treść i odsyłacze.
4. Egzekwowanie reguł.
5. Agenci i chmura.
6. Proces migracji.
7. Szablon planu.
8. Parametry per projekt.
9. Granice uogólnienia.

---

## 1. Pomiar

**Z1. Mierz wagi tokenami, nie znakami. Mierz kopiami plików wewnątrz katalogu pomiarowego.**
- Reguła: utwórz katalog roboczy poza repo i **skopiuj** do niego mierzone pliki. Dodaj `CLAUDE.md` z `- @plik` (ścieżka względna, jeden import na linię). Uruchom:

  ```
  claude -p "/context" --model <m> --effort <e> --permission-mode default --max-turns 1 --max-budget-usd 0.5
  ```

  Odczytaj tabelę Memory files i sprawdź, że **każdy** plik się na niej pojawił. Druga metoda: licznik w błędzie Read (O0 §1).
- Dowód:
  - znaki/3,2 i bajty/4 mylą o 13–55% [MEASURED: O0 §1];
  - metoda `/context` kosztowała 0 USD [MEASURED: Raport Foldery B3];
  - import pliku spoza katalogu roboczego jest w `-p` **po cichu pomijany**, bo wymaga dialogu zgody, którego `-p` nie pokazuje [MEASURED n=1: sceptyk P3; SOURCE: CC memory part1 „Import additional files”];
  - bajty na token: polski md 1,9–2,3, angielski ok. 2,7 [MEASURED: O0 §1, Raport B3].
- Sprawdzian: liczba plików w Memory files = liczba importów. Zgodność dwóch metod jest prawdopodobna, ale niezmierzona [ASSUMPTION].
- Zawsze: po zmianie modelu zmierz ponownie, bo tokenizer się zmienia [SOURCE: O0 §1].

**Z2. Najpierw inwentarz, potem decyzje.**
- Reguła: dla każdego źródła instrukcji ustal bajty, linie, tokeny, **kiedy się ładuje** i **kto go dostaje**. Źródła w sesji chmurowej:
  - każdy `CLAUDE.md` (korzeń i podkatalogi) i `AGENTS.md`;
  - `.claude/rules/*`;
  - skille (opisy i treści);
  - treści definicji `.claude/agents/*`, `.claude/commands/*`, output style;
  - pliki, do których CLAUDE.md każe zaglądać;
  - strażnicy w testach;
  - setup script środowiska, który może pisać `~/.claude/CLAUDE.md` [SOURCE: CC cloud-environments part2].
- Dowód: w Foldery dopiero inwentarz pokazał, że plik opisany jako „czytaj tylko części” ładuje się w całości wszystkim [MEASURED: Raport §2, B4].
- Sprawdzian: inwentarz obejmuje każde źródło z listy, łącznie z „brak”.

---

## 2. Ładowanie

**Z3. Zawsze ładowane = tylko to, czego potrzebuje każde okno i każdy agent.**
- Reguła: główny `CLAUDE.md` krótki. Parametr startowy: ≤ 200 linii (docs) i świadomy budżet tokenów (Foldery: ≤ ~5k). Reszta na żądanie.
- Dowód:
  - dłuższy plik obniża przestrzeganie reguł [SOURCE: CC memory.md];
  - płaci go każdy agent, który go ładuje: ok. 0,5k tokenów na KB **polskiego** tekstu (O0 §8; angielski ok. 0,37k/KB);
  - 31,6 KB zwiększało start agenta o 16k tokenów [MEASURED: O0 §2].
- Sprawdzian: `/context` na starcie nowej sesji (Ty) albo zagnieżdżone `claude -p "/context"` w korzeniu repo (sesja).
- Kiedy nie stosować: repo-baza wiedzy, które celowo ładuje dużo (jak to repo).

**Z4. Zagnieżdżony `CLAUDE.md` ładuje się cały i nie tylko głównemu oknu.**
- Reguła: nie używaj podkatalogowego `CLAUDE.md` do czytania wybranych części. Ładuje się w całości przy pierwszym dotknięciu pliku w tym katalogu: w głównym oknie, u general-purpose i u Explore (zmierzone). Agenci Plan, workflow i z `omitClaudeMd` nie są przetestowani; zakładaj, że też.
- Dowód:
  - ładuje się przy Read/Write/Edit [SOURCE: CC memory.md];
  - także przy `cat`/`head` w Bash, a nie przy Grep ani `python3 open()` [MEASURED n=1: exceptions.md 2026-10-08];
  - trafia do agenta Explore [MEASURED n=1: findings.md 2026-10-08];
  - nie widać go w Memory files [SOURCE: CC memory.md];
  - po kompaktowaniu wraca przy następnym dotknięciu [SOURCE: CC context-window.md].
- Sprawdzian: wpis `nested_memory` z jego ścieżką w transkrypcie (`~/.claude/projects/<projekt>/*.jsonl`).
- Kiedy stosować: krótkie lokalne reguły katalogu (kilka KB).

**Z5. Import `@` organizuje, ale nie oszczędza. Pułapka `AGENTS.md`.**
- Reguła:
  - `@plik` ładuje cały plik razem z importującym, bez limitu Read; używaj go tylko do tego, co ma być zawsze w kontekście;
  - składnia: jeden import na linię, ścieżka względem pliku importującego, spacje jako `\ `, nie w cudzysłowie ani w backtickach, maks. 4 poziomy, w obrębie katalogu repo (import zewnętrzny wymaga zgody, Z1);
  - jeśli aplikacja ma `AGENTS.md`, to dodanie jakiegokolwiek `CLAUDE.md` domyślnie **wyłącza** czytanie `AGENTS.md`. Nowy `CLAUDE.md` musi go importować (`@AGENTS.md`) albo przejąć jego treść.
- Dowód:
  - [SOURCE: CC memory.md: „imports … don't reduce its context cost”; „When Claude Code reads AGENTS.md”];
  - import 219 KB wszedł w całości [MEASURED: findings.md 2026-10-08];
  - `@a.md, @b.md` z przecinkiem gubi pierwszy plik [MEASURED: findings.md 2026-10-08].
- Sprawdzian: Memory files wymienia każdy importowany plik.

**Z6. Reguły `.claude/rules/` z `paths` są tak selektywne, jak podział kodu.**
- Reguła: reguła z `paths` ładuje się przy pracy z pasującymi plikami. Gdy cały kod jest w jednym pliku, reguła na ten plik ładuje się przy *każdej* pracy z kodem.
- Dowód:
  - przy Read/Write/Edit pasującego pliku [SOURCE: CC memory.md], także przy `cat`/`head` i u agentów, w tym Explore [MEASURED n=1];
  - jedyne czytane pole to `paths`; zepsuty YAML = reguła ładowana zawsze [SOURCE: CC memory.md];
  - reguła 115 KB załadowała się w całości (początek i koniec) [MEASURED n=1: sceptyk P1];
  - po kompaktowaniu wraca dopiero przy dopasowaniu [SOURCE: CC context-window.md].
- Sprawdzian: wpis `nested_memory` po Read pasującego pliku. Dla agentów w worktree sprawdź dopasowanie z `.claude/worktrees/…` (np. wzorzec `**/…`) [ASSUMPTION: niezweryfikowane].
- Kiedy nie stosować: reguły bez `paths`, bo ładują się zawsze.

**Z7. Plik do przeczytania w całości mieści się w jednym Read.**
- Reguła: limit Read to 25k tokenów na wywołanie. Większy plik bez `offset/limit` daje widok częściowy, a plik > 256 KB bez `limit` daje błąd. Parametr startowy: ≤ 20k tokenów (≈ 40 KB polskiego tekstu, ≈ 54 KB angielskiego; przelicz według Z1).
- Dowód: [CODE/MEASURED: O0 §1]; w Foldery plik „READ FIRST” miał 29,4k tokenów [MEASURED].
- Sprawdzian: strażnik z limitem bajtów (Z14) + pomiar próbki (Z1).

**Z8. Skille: procedury jawnie, wiedza tabelą albo skillem, zależnie od tego, czy wybór ma być pewny.**
- Reguła:
  - **Procedury** (dostawa, przekazanie pracy) jako skille wywoływane `/nazwa`. `disable-model-invocation: true` tylko wtedy, gdy uruchamia je wyłącznie człowiek, bo z tym ustawieniem Claude nie może ich wywołać sam, więc polecenie w CLAUDE.md „uruchom `/dostawa`” przestaje działać.
  - **Wiedza referencyjna** jako skill (opis ze słowami-wyzwalaczami albo `paths:` w frontmatterze skilla, ładowany tylko przy pasujących plikach) **albo** tabela „zadanie → plik” + Read. Tabelę wybierz, gdy wybór musi być deterministyczny. Skill, gdy wiedza jest rzadko potrzebna, i wtedy sprawdź evalem, że się uruchamia.
- Dowód:
  - docs wymieniają „Reference content” jako podstawowy rodzaj skilla i zalecają przenoszenie wiedzy z CLAUDE.md do skilli [SOURCE: CC skills part1–2; large-codebases part2];
  - w kontekście jest zawsze tylko opis (≤ 1 536 znaków) [SOURCE: CC skills part2];
  - po kompaktowaniu wraca ≤ 5k tokenów treści na skill [SOURCE: CC context-window.md];
  - najczęstszy błąd to nieuruchomienie skilla, a naprawą jest opis [SOURCE: O4 §5].
  
  Foldery wybrało tabelę z powodu potrzeby deterministycznego wyboru, a nie dlatego, że skille są złe.
- Sprawdzian: `claude plugin eval` albo próbne polecenia (O4 §4).

---

## 3. Treść i odsyłacze

**Z9. Stan bieżący oddzielony od historii.**
- Reguła: plik obszaru opisuje stan obecny; historia trafia do `CHANGELOG.md` i git; stan i następne zadanie są w małym, **nadpisywanym** `STATUS.md`.
- Dowód: w Foldery ok. 70% instrukcji to historia warstwowa [ASSUMPTION: z proporcji znaków, Raport §2]; strażnik wymuszał dopisywanie (Z15).
- Sprawdzian: brak lead-inów wersji w plikach skondensowanych; STATUS ≤ limit.
- Kiedy nie stosować: projekt bez historii wersji w dokumentach.

**Z10. Jedna reguła = jeden obowiązujący zapis.**
- Reguła: kopie zastępuj odsyłaczem. Oryginał historyczny może istnieć z nagłówkiem „obowiązuje: <plik>”.
- Dowód: przy sprzecznych instrukcjach model może wybrać dowolną [SOURCE: CC memory.md]; w Foldery 4 kopie reguły dokumentacji i 2 sprzeczne nazwy paczki [SOURCE: Raport D4]; uwaga N1 w planie.
- Sprawdzian: grep kluczowych fraz reguły po repo.

**Z11. Odsyłacz = zwykła ścieżka w tabeli „zadanie → plik (rozmiar)”; rozmiar pilnuje strażnik.**
- Reguła: jedna tabela nawigacyjna z kolumnami: zadanie, plik, rozmiar w KB (sprawdzany automatycznie), „w całości / w częściach”. Bez ręcznych liczb poza strażnikiem.
- Dowód: w Foldery ręczne liczby rozmiaru były nieaktualne 2–3 razy [MEASURED: Raport D3].
- Sprawdzian: strażnik porównuje adnotację z rozmiarem (np. max(10%, 1 KB)) i wykrywa martwe odsyłacze.

**Z12. Plik przeniesiony dosłownie nosi ostrzeżenie o pierwszeństwie.**
- Reguła: nagłówek „przeniesione dosłownie; przy sprzeczności obowiązuje <nowy CLAUDE.md / skill>”.
- Dowód: kopie dosłowne zawierały nieaktualne polecenia (plan, T10).
- Kiedy nie stosować: pliki już skondensowane (Z20, etap B).

---

## 4. Egzekwowanie reguł

**Z13. Każdą regułę „nigdy/zawsze” przypisz do mechanizmu i znaj jego granice.**

| Mechanizm | Twardość w sesji chmurowej | Granice |
|---|---|---|
| `deny` w `.claude/settings.json` (**tylko** w sesji z jednym repo, z pliku w katalogu startowym; zagnieżdżone `claude -p` z podkatalogu ma 0 reguł [MEASURED: O0 §4]) | twarda na poziomie narzędzia | dopasowanie tekstu; skrypt, `sh -c` lub inne narzędzie omija (O0 §4) |
| hook PreToolUse z exit 2 (ładuje się jak deny) | twarda dla danego narzędzia | tylko to narzędzie; push z wnętrza skryptu przejdzie; hook, który nie wystartuje, nie blokuje [SOURCE: CC hooks part3] |
| strażnik w testach | twarda, gdy testy są uruchamiane | jak wyżej |
| branch protection / ruleset | twarda po stronie serwera | prywatne repo = płatny plan; admin domyślnie omija (O0 §7) |
| CI na push | twarda po stronie serwera | minuty Actions |
| sandbox Bash | w chmurze **niedostępny** (`bwrap` brak) [MEASURED: O0 §4] | — |
| CLAUDE.md, reguły, skille, prompt | miękka | model „zwykle” stosuje [SOURCE: CC memory.md] |

Uwagi do tabeli:
- `.claude/settings.json` działa tylko w sesji z jednym repo. W chmurze sesja startuje w korzeniu repo, więc plik musi leżeć w **korzeniu** (nie jest dziedziczony z innych katalogów) [SOURCE: CC settings part3; large-codebases part1].
- `disableAllHooks` w `--settings` wyłącza hooki projektu; w chmurze tylko przy uruchomieniu `claude -p` z tą flagą [SOURCE: O2 §A1].
- Sprawdzian: tabela w planie „reguła → mechanizm → prowokacja testowa”.

**Z14. Strażnik dokumentacji to skrypt w testach, który sprawdza kształt.**
- Reguła: strażnik sprawdza:
  - wersję w CHANGELOG i STATUS;
  - limity bajtów;
  - martwe odsyłacze;
  - adnotacje rozmiaru;
  - frontmatter reguł;
  - zakazy projektu.
  
  Ma test mutacyjny. Wszystkie odczyty idą przez jedną funkcję `read()`, żeby test mógł ją podmienić.
- Dowód: wzorzec z Foldery (`doc_check` + mutacja w `test_logic`) [SOURCE: pliki Foldery]; plan A4.5. Uwaga: to wzorzec z jednego projektu [ASSUMPTION co do przenośności, opiera się na tym, że projekt ma testy].
- Kiedy nie stosować: projekt bez zestawu testów. Wtedy strażnik jako osobny skrypt w hooku przed pushem na `main`.

**Z15. Strażnik nie może nagradzać dopisywania.**
- Reguła: żaden warunek strażnika nie wymaga nowego wpisu o wersji w pliku opisowym. Wersja należy do CHANGELOG i STATUS.
- Dowód: `doc_check` Foldery wymagał `v{ver}` w opisie architektury, co napędzało narastanie [SOURCE: doc_check.py @be31a48].
- Sprawdzian: dla każdego warunku sprawdź, czy da się go spełnić bez powiększania pliku opisowego.

**Z16. Hooki: wzorce wykonania.**
- Wywołanie przez interpreter (`"command": "bash"` / `"python3"`, ścieżka w `args`), bez polegania na bicie wykonywalności, bo hook, który nie wystartuje, jest po cichu wyłączony [SOURCE: CC hooks part2–3].
- Blokada przez exit 2 albo JSON z decyzją; exit 1 nie blokuje [SOURCE: CC hooks part3].
- **`${CLAUDE_PROJECT_DIR}` tylko do zlokalizowania skryptu.** Stan repo (gałąź, `git status`, strażnik) czytaj w katalogu `cwd` z wejścia JSON hooka. `CLAUDE_PROJECT_DIR` nie podąża za worktree, więc dla agenta z `isolation: worktree` sprawdziłby zły katalog i złą gałąź [SOURCE: CC hooks part2 „Worktrees are different”].
- Polecenia Bash analizuj per podpolecenie (`shlex`), nie wyrażeniem regularnym po całości [MEASURED: plan, Załącznik S, 22/22].
- **Gałąź roboczą przepuszczaj zawsze**, bo w chmurze push to jedyna ochrona pracy (O0 §7). Push na gałąź główną blokuj albo warunkuj (np. zielony strażnik) według Twojej reguły scalania.
- Hook Stop nie zmusza do scalania ani do zielonych testów; przypomina przez `additionalContext` [SOURCE: CC hooks part7].
- Zmiany w turze licz per tura (baza zapisana w UserPromptSubmit) hashem uwzględniającym treść zmian [MEASURED: plan T5].
- UserPromptSubmit i SessionStart: zwykły stdout trafia do kontekstu, więc hook zapisujący stan ma milczeć [SOURCE: O2 §A6].
- `additionalContext` ≤ 10 000 znaków; dłuższy agent dostaje tylko podgląd 2 000 znaków i ścieżkę [SOURCE: CC hooks part3].
- Zależności hooków (`jq`, `python3`, GNU grep) są w obrazie chmury [SOURCE: CC cloud-environments part2].
- Każdy hook testuj JSON-em na stdin (przypadek dozwolony i blokowany), zanim go zacommitujesz.

**Z17. Reguły `deny`: pułapki.**
- Gołe `deny` narzędzia usuwa je z kontekstu; `Bash(...)` to dopasowanie tekstu [SOURCE: O2 §D4].
- Deny `Read`/`Edit` na ścieżce obejmuje rozpoznane polecenia Bash: `cat`, `head`, `tail`, `sed`, `tee`, przekierowania [SOURCE: CC permissions part2], **także `cp` do tej ścieżki** [MEASURED n=1: sceptyk P2]. Może więc zablokować procedurę kopiującą (np. backup). Taką ścieżkę chroń hookiem na Edit/Write.
- Narzędzia zapisu GitHub MCP (push, pliki, merge, auto-merge, uruchamianie Actions) omijają hooki na Bash. Blokuj je przez `deny`, gdy sesje mają zapisywać tylko przez git (plan M15/T7).

---

## 5. Agenci i chmura

**Z18. Każdy rodzaj agenta dostaje reguły inną drogą.**

| Agent | CLAUDE.md na starcie | Pliki przy czytaniu (zagnieżdżony, `paths`) | SubagentStart `additionalContext` | Preferencje claude.ai, auto memory |
|---|---|---|---|---|
| general-purpose, własne definicje | tak | tak | tak | nie |
| Explore, Plan | nie | **tak** [MEASURED n=1] | tak | nie |
| definicja z `omitClaudeMd` | nie | [ASSUMPTION: tak] | tak | nie |
| fork (kopia rozmowy) | dziedziczy całą rozmowę, prompt i output style | — | — | dziedziczy [SOURCE: CC sub-agents part4] |
| agent workflow | tak, chyba że `opts.agentType` wskazuje definicję z `omitClaudeMd` (O0 §2) | [ASSUMPTION] | **niezweryfikowane** | nie |

- Reguła:
  - reguły dla agentów (zakazy, format raportu) w jednym pliku wstrzykiwanym przez SubagentStart;
  - w definicjach własnych agentów najważniejsze reguły wpisz w treść pliku agenta, bo to jego prompt systemowy [SOURCE: CC debug-your-config „Check common causes”];
  - w workflow reguły powtarzaj w promptach;
  - model i effort każdego agenta podawaj jawnie (O0 §5); zagnieżdżone `claude -p` bez `--model` działało na Sonnet 5.5 medium, nie na modelu sesji [MEASURED: O0 §5];
  - w chmurze `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1`: agent nie uruchomi własnych agentów [MEASURED: O0 §7]; projektuj płaski podział pracy;
  - Explore/Plan: reguły powtarzaj w poleceniu delegującym; w `-p` jest też `--append-subagent-system-prompt` [SOURCE: CC sub-agents part1];
  - agent „tylko do odczytu” = bez Bash i bez narzędzi MCP z zapisem, bo samo `disallowedTools: Edit, Write` zostawia Bash (O0 §8; plan, agent recenzent).
- Dowód: [SOURCE: CC sub-agents „What loads at startup”; CC hooks part7 „SubagentStart”].
- Sprawdzian: transkrypt agenta, nie jego relacja.

**Z19. Chmura: warunki, bez których mechanizmy nie działają.**
- `.claude/` nie może być w `.gitignore`, bo sesja czyta tylko to, co jest w klonie [SOURCE: CC settings part3].
- Sesja z jednym repo: `.claude/settings.json` w korzeniu działa. Sesja z wieloma repo go nie czyta [SOURCE: CC settings part3; cloud-environments part2].
- Nowa sesja startuje z `origin/main` (O0 §7): nowe CLAUDE.md, reguły i agenci są widoczni dopiero po scaleniu.
- **Co odświeża się w trakcie sesji:**
  - hooki i ustawienia: tak, po zapisaniu pliku [SOURCE: CC debug-your-config];
  - CLAUDE.md: dopiero nowa sesja (O0 §2);
  - nowy katalog `.claude/agents/`: restart [SOURCE: CC sub-agents part1];
  - nowy katalog skilli: `/reload-skills` (O0 §2).
- `/context`, `/hooks`, `/permissions` wpisuje człowiek. Sesja wykonująca plan sprawdza skutki, transkrypt albo uruchamia zagnieżdżone `claude -p "/context"` (plan T3).
- **Ścieżki chronione** (`.claude/`, `.git`, `.husky`, `.mcp.json`, `.pre-commit-config.yaml`, `lefthook.yml` i in.; **`CLAUDE.md` nie jest na tej liście**) zależnie od trybu [SOURCE: CC permission-modes part3 „Protected paths”]:
  - `default`/`acceptEdits`: pytanie;
  - `auto`: klasyfikator;
  - `dontAsk`: odmowa;
  - `bypassPermissions`: zgoda;
  - `permissions.allow` ich nie odblokowuje.
  
  Wybierz tryb sesji migracji świadomie. Osobna sprawa to werdykt klasyfikatora „Self-Modification” przy zmianach CLAUDE.md i scalaniu takich zmian [MEASURED n=2: findings.md 2026-10-06]. Ścieżka zapasowa: pliki w `staging/` do wgrania przez Ciebie oraz PR scalany przez Ciebie.
- Instalację środowiska przenieś do setup scriptu środowiska (cache; < ~5 min; exit 0) [SOURCE: CC cloud-environments].
- Kod-inteligencja (LSP) nie startuje w chmurze (O1 §4), więc nie opieraj na niej planu.

**Z20a. Przeżycie kompaktowania i przekazanie pracy.**
- Reguła:
  - reguły, które muszą przeżyć kompaktowanie, trzymaj w głównym CLAUDE.md (wraca z dysku);
  - zagnieżdżone pliki i reguły `paths` wracają dopiero przy ponownym dotknięciu pliku;
  - hook SessionStart z matcherem `compact` wstrzykuje STATUS;
  - długie prace prowadzą plik postępu w repo i robią push po każdej fazie, bo kompaktowanie zachowuje pliki, a nie rozmowę, a maszyna chmurowa może zniknąć.
- Dowód: [SOURCE: CC context-window part2 „What survives compaction”; O0 §7, §8].

**Z20b. Worktree agentów powstaje z gałęzi domyślnej.**
- Reguła: kopia `isolation: worktree` startuje z `origin/<gałąź domyślna>`, bez niezacommitowanej i niescalonej pracy. Przed uruchomieniem agentów w worktree: commit, push i scalenie, albo `worktree.baseRef: "head"`.
- Dowód: [SOURCE: CC worktrees przez O0 §3].

---

## 6. Proces migracji

**Z20. Dwa etapy: bezstratne przeniesienie, potem kondensacja po obszarze.**
- Reguła:
  - **Etap A** (jedna sesja): tekst przenosi skrypt według zakresów linii (konkordancja), a nie model; dochodzą nowa nawigacja, strażnik, hooki, agenci.
  - **Etap B**: przepisanie „do stanu obecnego” plik po pliku, w osobnych sesjach z kolejką w STATUS, z recenzentem; do tego czasu pliki dosłowne zamrożone (Z29).
- Dowód: zysk ładowania wynika z położenia tekstu (Z3–Z7); przepisanie całości naraz koncentruje ryzyko (recenzja „meta”, plan, Załącznik R). Skuteczność w praktyce jest **niezmierzona**, bo plan Foldery nie został jeszcze wykonany [ASSUMPTION].
- Sprawdzian:
  - zakresy pokrywają wszystkie linie źródła bez luk i nakładek;
  - multizbiór linii źródła = suma multizbiorów linii w plikach docelowych;
  - liczone na zapisanym SHA przed dalszymi edycjami;
  - skrypt w repo.
- Kiedy nie stosować: dokumentacja mieszcząca się w jednym Read i obejmująca jeden obszar [ASSUMPTION: próg do oceny w projekcie]; wtedy jednorazowe przepisanie z recenzją.

**Z21. Zanim zaczniesz czytać, usuń źródło z automatycznego ładowania.**
- Reguła:
  - Źródło **zagnieżdżone**: po aktualizacji gałęzi pierwszy krok to `git mv` do archiwum o innej nazwie (albo wpis `claudeMdExcludes`; czy działa od razu w trwającej sesji, niezweryfikowane). Plan migracji trzymaj poza tym katalogiem.
  - Źródło **w korzeniu repo** jest w kontekście od startu sesji i przeniesienie go tego nie zmienia. Albo zaakceptuj koszt, albo uruchom pracę z wyłączonym CLAUDE.md (np. zagnieżdżone `claude -p` ze zmienną `CLAUDE_CODE_DISABLE_CLAUDE_MDS=1`, O0 §2).
- Dowód: plik ładuje się przy pierwszym dotknięciu katalogu, także przez `cat` (Z4); `git mv` go nie ładuje [MEASURED n=1: sceptyk P1].
- Sprawdzian: brak wpisu `nested_memory` dla starego pliku w transkrypcie po pierwszym Read w katalogu.

**Z22. Strażnik i dokumenty zmieniaj w jednym commicie.**
- Reguła: przełączenie strażnika i przeniesienie dokumentów to jeden commit z zielonymi testami.
- Dowód: rozjazd = czerwone testy i blokada dostawy (plan, Ryzyka).

**Z23. Weryfikuj skutkami, w dwóch fazach odbioru.**
- Reguła:
  - (a) w sesji migracji: prowokacje każdej blokady, pushe tylko z `--dry-run`, narzędzia przez nieobecność na liście, tak żeby błąd hooka niczego nie wysłał; testy; konkordancja;
  - (b) po scaleniu, w nowej sesji: pomiar ładowania, transkrypty agentów i wszystko, co nie odświeża się w trakcie sesji (nowy CLAUDE.md, nowy katalog `.claude/agents/`, nowy katalog skilli; Z19). W fazie (a) da się sprawdzić tylko hooki, ustawienia i deny.
- Dowód: plan M1, M3, N4, T3; co odświeża się w trakcie sesji: Z19.

**Z24. Wycofanie bez przepisywania historii.**
- Reguła: zapisz SHA gałęzi głównej przed scaleniem. Wycofanie = `git restore --source=<stary_main> --staged --worktree :/` + commit „do przodu”.
- Dowód: `git revert` zakresu zawodzi przy commitach scalenia (plan T13).

**Z25. Plan przechodzi recenzję w dwóch rolach.**
- Reguła:
  - recenzent „meta” ocenia sens i podejście i może je zakwestionować;
  - recenzent techniczny sprawdza mechanizmy i może uruchamiać tanie próby;
  - obaj tylko do odczytu, z formatem raportu (ID, waga, dowód, poprawka) i prawem „nic nie znalazłem”;
  - recenzent dostaje jawnie zakres projektu (np. „tylko sesje w chmurze”).
- Dowód:
  - w Foldery recenzja „meta” zmieniła strukturę planu, a techniczna wykryła, że blokady w wersji 3 by nie działały [MEASURED: plan, Załączniki R, T, S];
  - recenzent bez zakresu oceniał pod scenariusze spoza projektu (Załącznik Z);
  - O0 §3: recenzent tego samego modelu zmienia ok. 17% ustaleń. To częstość zmian, a nie dowód poprawy.
- Kiedy nie stosować: zmiany kosmetyczne.

**Z27. Właściciel na Windowsie, praca w chmurze Linux: końcówki linii i dostarczane pliki.**
- Reguła:
  - hooki pisz w Pythonie (CRLF mu nie szkodzi), a hooki, które nie mają niczego blokować, kończ zawsze kodem 0; hook basha z błędem składni kończy się kodem 2, co w UserPromptSubmit odrzuca **każdy** prompt [SOURCE: CC hooks part3];
  - `.gitattributes` z `eol=lf` to higiena, nie ochrona: plik zapisany do repo bez `git add` (np. wgrany przez stronę GitHuba) zachowuje `\r\n` po sklonowaniu [MEASURED n=1: repo testowe, `git update-index --cacheinfo`, 2026-10-08];
  - strażnik sprawdza, że w `.claude/hooks/` nie ma `\r`;
  - po każdym ręcznym wgraniu plików przez GitHub z Windowsa wykonaj prowokację każdego hooka;
  - pliki uruchamiane przez Ciebie na Windowsie (`.bat`, instrukcje) dostają CRLF i ASCII według reguł projektu, a sesja zawsze mówi wprost, czego nie dało się uruchomić (Windows, GPU, prawdziwe pliki).
- Dowód:
  - skrypt hooka z CRLF uruchomiony przez `bash` kończy się kodem 2, czyli w PreToolUse blokuje każde wywołanie [MEASURED n=1: sceptyk E4];
  - reguły CRLF/ASCII i „powiedz, czego nie uruchomiono” to stałe zasady Foldery [SOURCE: pliki Foldery §2, §3].
- Sprawdzian: `grep -l $'\r' .claude/hooks/*` puste; prowokacje po wgraniu.

**Z28. Trwałość: strażnik patrzy na zmiany, nie tylko na pliki.**
- Reguła: przy pushu na gałąź główną hook liczy różnicę gałęzi względem `origin/main` i wymaga: zmienionego pliku stanu (STATUS) w każdej gałęzi ze zmianami; przy zmianie kodu także CHANGELOG i pliku dokumentacji, albo jawnej linii „docs: bez zmian (powód)”. Strażnik w testach widzi tylko bieżące pliki, więc nie wykryje, że dokumentacja nie nadąża za kodem.
- Dowód: w planie Foldery 4.1 jedyne twarde warunki dotyczyły napisów wersji, rozmiarów i odsyłaczy [SOURCE: plan 4.1 A4.5]; implementacja i test: `reports/foldery-hooks/` [MEASURED: 60/60, 2026-10-08].
- Granica: furtka „bez zmian” jest zapisem, nie oceną; treść ocenia tylko recenzent (miękkie).

**Z29. Pliki przeniesione dosłownie zamrażaj do kondensacji.**
- Reguła: sumy sha256 plików dosłownych w pliku listy; strażnik odrzuca każdą ich zmianę, dopóki plik nie ma nagłówka „stan: skondensowany”. Zmiany w międzyczasie idą do CHANGELOG i STATUS. Kondensacja to osobne sesje zlecane przez właściciela, z kolejką w STATUS, a nie „przy okazji” z prawem odłożenia.
- Dowód: bez zamrożenia sesja dopisywałaby akapity „na górze”, bo tak każe treść pliku dosłownego (plan 4.1, U2) [ASSUMPTION co do zachowania modelu].
- Kiedy nie stosować: migracja bez etapu dosłownego (Z20, „kiedy nie stosować”).

**Z30. Treść generowana nie trafia do pliku z limitem rozmiaru.**
- Reguła: wynik generatora (np. mapa kodu) generuj na żądanie albo trzymaj w osobnym pliku bez ręcznej treści; w pliku nawigacji z limitem bajtów rośnie z kodem i kiedyś zablokuje strażnika.
- Dowód: MAPA §4 Foldery (plan 4.1 → 4.2, U3).

**Z26. Odrzucone mechanizmy, które się uogólniają.**
- Output style: zastępuje instrukcje inżynierskie (chyba że `keep-coding-instructions`) i działa tylko w głównym oknie (O0 §2).
- `/goal`: mały model ocenia rozmowę, nie pliki (O0 §6).
- Auto memory: nie istnieje w sesji chmurowej (O0 §2).
- `claudeMdExcludes` jako „rozwiązanie”: ukrywa reguły zamiast je przenieść; dobre tylko na czas migracji (Z21).
- Import `@` dużych plików (Z5).

---

## 7. Szablon planu migracji

1. **Kryteria sukcesu** (mierzalne), każde z kolumną „dziś” (stan wyjściowy) i sposobem pomiaru: tokeny na starcie, tokeny przy pracy z kodem, maks. rozmiar pliku do czytania, bezstratność, lista blokad z prowokacjami, testy zielone, test mutacyjny strażnika.
2. **Decyzje właściciela**: zawartość paczek i wydań, archiwum, CI, branch protection, kto wykonuje (model, effort, agenci, tryb uprawnień, Z19), jak plan trafia do repo (poza katalogiem ładowanym, Z21), wyjątki od reguły scalania.
3. **Wykonawca**: blok „model · effort · workflow”, prompt startowy, szacunek kosztu i czasu.
4. **Etap A**:
   - A0: aktualizacja gałęzi, usunięcie źródła z ładowania (Z21), pomiar bazowy (Z1), grep odwołań w kodzie i testach, plik postępu (Z20a);
   - A1: `.gitignore` (Z19), `.gitattributes` (Z27); kontrola: sesja z jednym repo, start w korzeniu, każde zagnieżdżone `claude -p` uruchamiane w korzeniu (Z13);
   - A2: konkordancja (zakres → plik, stabilne identyfikatory sekcji);
   - A3: przeniesienie skryptem, nagłówki (Z12), dowód bezstratności na zapisanym SHA, poprawa odwołań;
   - A4: nowy CLAUDE.md (z `@AGENTS.md`, jeśli trzeba, Z5), STATUS, nawigacja, strażnik + test mutacyjny w jednym commicie (Z22);
   - A5: ustawienia, hooki (Z16, Z27, Z28), agenci (Z18), skille (Z8), ścieżka zapasowa dla chronionych ścieżek (Z19); strażnik sprawdza też frontmatter agentów i skilli (literówka w polu jest ignorowana bez komunikatu, plik bez `name` pomijany; O0 §4) oraz brak `\r` w hookach;
   - A6: odbiór w sesji, scalenie albo PR;
   - A7: odbiór w nowej sesji;
   - A8: setup script.
5. **Etap B**: zamrożenie plików dosłownych (Z29), sesje kondensacji z kolejką w STATUS, recenzent per plik, strażnik plików skondensowanych, licznik nieskondensowanych, usunięcie archiwum na końcu.
6. **Ryzyka i wycofanie** (Z24).
7. **Reguły dla następców** w nowym CLAUDE.md: jeden fakt w jednym miejscu, przepisuj zamiast dopisywać, limity, bez dużych importów, pomiar po zmianie modelu, okresowy `/doctor prompt-audit` (O0 §6).

## 8. Parametry do ustalenia w każdym projekcie

| Parametr | Wpływa na | Jak ustalić |
|---|---|---|
| Struktura kodu (jeden plik / wiele plików / wiele pakietów) | selektywność `paths` (Z6), podział wiedzy, reguły Read-deny dla kodu generowanego [SOURCE: CC large-codebases part1] | rozmiary, `find` |
| Język dokumentacji | bajty/token, a od tego limity (Z1, Z7) | pomiar Z1 |
| Model agentów i jego okno | ile może wejść jednorazowo | O0 §1 |
| Czy jest `AGENTS.md` | Z5 | inwentarz |
| Czy projekt ma testy | gdzie strażnik (Z14) | repo |
| Tryb uprawnień sesji migracji | zapisy w `.claude/` (Z19) | Twoja decyzja |
| Sesja z jednym repo czy z wieloma (wątek projektu) | czy `.claude/settings.json` w ogóle działa (Z13, Z19); w sesji z wieloma repo główny CLAUDE.md każdego repo staje się zapewne plikiem podkatalogu [ASSUMPTION] | konfiguracja sesji |
| Jak trafiają pliki od Ciebie (wgrywanie z Windowsa) | końcówki linii, bit wykonywalności (Z16, Z27) | Twój sposób pracy |
| Plan GitHuba, prywatność repo | branch protection (Z13) | ustawienia repo |
| Limit minut CI | CI na push (Z13) | Ty |
| Twoje reguły (scalanie, paczki, język) | hooki, wyjątki planu (Z16) | obecne instrukcje |
| Rozmiar dokumentacji | czy etapy A/B mają sens (Z20) | inwentarz Z2 |
| Długość instalacji środowiska | setup script (Z19) | pomiar |

## 9. Granice uogólnienia i rzeczy niezweryfikowane

- **Ogólne w zakresie (oparte na dokumentacji i pomiarach KB):** Z1–Z7, Z10, Z13, Z16–Z19, Z20a, Z20b, Z21, Z26, Z27.
- **Wzorce z jednego projektu (Foldery), do potwierdzenia:** Z8 (w części), Z9, Z11, Z12, Z14, Z15, Z20, Z22–Z25, Z28–Z30. Plan Foldery nie został wykonany, więc proces jest sprawdzony rozumowaniem i recenzją, nie praktyką.
- **Pomiary n=1:**
  - ładowanie przez `cat`/`head`;
  - zagnieżdżony plik u Explore;
  - `git mv` bez ładowania;
  - reguła 115 KB w całości;
  - `cp` blokowane przez deny `Edit`;
  - pomijanie zewnętrznych importów w `-p`;
  - hook z CRLF = exit 2;
  - odmowy klasyfikatora.
  
  Powtórz po nowej wersji CC.
- **Niezweryfikowane:**
  - SubagentStart dla agentów workflow;
  - dopasowanie `paths` w worktree;
  - `claudeMdExcludes` zmienione w trakcie sesji;
  - działanie `/hooks` i `/permissions` w chmurze.

---

## Załącznik Z: recenzja sceptyka i decyzje

Raport sceptyka powstał, zanim dotarło do niego doprecyzowanie zakresu (tylko Twoje aplikacje w chmurze), więc część uwag dotyczyła pracy lokalnej. Te są odrzucone jako spoza zakresu.

| Uwaga | Decyzja | Zmiana |
|---|---|---|
| S1 import spoza katalogu po cichu pomijany w `-p` (zmierzone) | Przyjęta | Z1: kopie plików, sprawdzenie listy; zgodność metod jako ASSUMPTION |
| S2 Z8 sprzeczne z docs | Przyjęta | Z8 przepisana: wiedza jako skill albo tabela, `paths` w skillach, skutek `disable-model-invocation` |
| S3 katalog startowy, monorepo | Przyjęta w części | w chmurze start w korzeniu repo, więc settings w korzeniu (Z13); monorepo lokalne poza zakresem |
| S4 sandbox, granice hooków | Przyjęta w części | sandbox: w chmurze niedostępny (Z13); granice hooków i `disableAllHooks` dodane |
| S5 `CLAUDE_PROJECT_DIR` nie podąża za worktree | Przyjęta | Z16: stan repo z `cwd` wejścia hooka. **Dotyczy też `guard_bash.py` w planie Foldery** (do poprawy w planie przed wykonaniem) |
| S6 ścieżki chronione per tryb | Przyjęta | Z19: tabela trybów; „Self-Modification” osobno |
| S7 źródła lokalne, AGENTS.md | Przyjęta w części | źródła lokalne poza zakresem; AGENTS.md i setup script w Z2/Z5 |
| S8 `git mv` zmierzone; źródło w korzeniu | Przyjęta | Z21 |
| S9 blokada `main` za mocno sformułowana | Przyjęta | Z16: „blokuj albo warunkuj według reguły scalania” |
| S10 podgląd 2 000 znaków; przenośność hooków | Przyjęta w części | podgląd dodany; przenośność: tylko obraz chmury (zakres) |
| S11 `cp` zmierzone | Przyjęta | Z17 |
| S12 fork, treść definicji agenta, `opts.agentType` | Przyjęta | Z18 |
| S13 17% to częstość zmian, nie poprawa | Przyjęta | Z25 |
| S14 zbyt szeroka „ogólność”, brak „kiedy nie stosować”, reguła > 25k zmierzona | Przyjęta | rozdział 9 przepisany; Z6; „kiedy nie stosować” tam, gdzie ma sens |
| C1 plik postępu i push po fazie | Przyjęta | Z20a |
| C2 przeżycie kompaktowania | Przyjęta | Z20a |
| C3 baza worktree | Przyjęta | Z20b |
| C4 co odświeża się w trakcie sesji | Przyjęta | Z19 |
| C5 agent tylko do odczytu bez Bash | Przyjęta | Z18 |
| C6 odrzucone mechanizmy | Przyjęta | Z26 |
| C7 dźwignie monorepo | Przyjęta w części | Read-deny dla kodu generowanego w §8; LSP nie działa w chmurze; reszta poza zakresem |
| C8 zespoły | Odrzucona | poza zakresem (pracujesz sam) |

**Drugi raport (z zakresem):**

| Uwaga | Decyzja | Zmiana |
|---|---|---|
| S3 kiedy deny/hooki się ładują; sesja z wieloma repo | Przyjęta | Z13 (warunek w tabeli), szablon A1, wiersz w §8 |
| S4 `guard_bash.py` w planie sprawdza zły katalog w worktree | Przyjęta | plan, Załącznik S: stan z `cwd`; przetestowane ponownie z worktree |
| S5 CRLF w hookach = blokada każdego Bash (zmierzone) | Przyjęta | nowa Z27; plan A1 (`.gitattributes`), A4.5 pkt 10 |
| S6 `CLAUDE.md` nie jest ścieżką chronioną; dodatkowe ścieżki | Przyjęta | Z19 |
| S7 co da się sprawdzić w fazie (a), a co dopiero w (b) | Przyjęta | Z23 |
| S12 „wszystkim” za mocno; 0,5k/KB tylko dla polskiego | Przyjęta | Z4; Z3 (już było) |
| S13 model zagnieżdżonego `-p`, głębokość agentów w chmurze, kanały reguł | Przyjęta | Z18 |
| S14 próg 50 KB bez tagu | Przyjęta | Z20 |
| C4 pliki dla Windowsa | Przyjęta | Z27 |
| C6 kolumna „dziś” w kryteriach | Przyjęta | szablon pkt 1 |
| C7 walidacja definicji agentów i skilli | Przyjęta | szablon A5, plan A4.5 pkt 10 |
| Pozostałe (S1, S2, S6–S11, C1–C3, C5) | już w wersji 2 | — |
