# Zarzuty sceptyka-recenzenta (Opus 5.5, effort max, świeży kontekst) — pełny tekst obu rund, 2026-10-11

Recenzent nie widział rozmowy; dostał ścieżki do czterech plików CLAUDE.md, bazy wiedzy (O0, O2, O5, playbook, findings, changelog), raportu i szablonu. Werdykt rundy 1: AKCEPTUJĘ PO POPRAWKACH (warunki: zarzuty 1–11). Werdykt rundy 2: AKCEPTUJĘ PO POPRAWKACH (warunki N1–N3; po ich wprowadzeniu akceptacja bez kolejnej rundy). Decyzje autora: `ANALIZA-porownawcza-CLAUDE-md.md` §7.

---

# RUNDA 1

## Przeczytane w całości
Źródła (line count z `wc -l`, zgodny z Read):
- Foldery: 119 linii, 11 007 B, końce linii CRLF.
- PoBTweaks: 256 linii, 31 622 B, LF.
- Expert: 107 linii, 9 881 B, CRLF. Po usunięciu znaków CR jest identyczny z `/home/user/ClaudeEXPERT/CLAUDE.md` (sprawdzone `diff`).
- Felix: 31 linii, 3 540 B, CRLF.
Wyniki pracy: raport 115 linii; szablon 72 linie.
Baza wiedzy: O0 205 linii; O5 99 linii (cały plik); playbook 97 linii; findings 25 linii.

## Przeczytane częściowo
- O2 (527 linii): l. 1–160 (TL;DR, A1–A8) oraz l. 386–527 (D1–D6, E, Verify live).
- CHANGELOG.md (987 KB): wpisy 2.1.295, 2.1.293, 2.1.72, 2.1.69, l. 85–100; zmiany 2.1.292–2.1.296 przejrzane grepem (hook, CLAUDE.md, worktree, subagent, settings, permission, classifier, rules, effort).
- O1, O3, O4: tylko grep po kilku hasłach.

## Moje pomiary
- `claude --version` zwraca 2.1.296, tak jak podaje raport.
- Tokeny policzyłem licznikiem Read (metoda z O0 §1): Foldery 4 426 (raport 4 425), PoBTweaks 16 094 (16 093), Expert 3 753 (3 752), Felix 1 133 (1 132), szablon 4 992 (4 991), szablon bez komentarzy HTML 4 229 (4 228). [MEASURED 2026-10-11, CC 2.1.296, Opus 5.5, n=1]. Wszystkie liczby raportu zgadzają się z moimi z dokładnością do 1 tokena. Linie i bajty z `wc` też się zgadzają. Szablon ma 9 komentarzy HTML o łącznej wielkości 1 615 B.
- Trzy cytaty z changelogu się potwierdzają (2.1.72 komentarze HTML ukryte; 2.1.293 reguły `paths` przy `cat/head/tail/sed -n/grep`; 2.1.295 `onFailure: "block"`).

## Zarzut 1 — BLOKUJĄCY. Szablon opisuje jako istniejące mechanizmy, których w nowym projekcie nie ma
Gdzie: szablon l. 18, 19, 23, 31, 36, 39, 45, 49, 55, 57, 69, 71, 72.
Co jest źle: zdania w trybie oznajmującym (nie miejsca do wypełnienia `<…>`) przedstawiają jako działające: hook Stop (l. 18); hook SessionStart (l. 23, 36); hook SubagentStart wstrzykujący `.claude/agent-rules.md` (l. 45); `doc_check` (l. 39); `tools/test_hooks.sh` (l. 69, 71); `.claude/agents/reviewer.md` (l. 31) i `implementer.md` (l. 49); skille `/dostawa` (l. 55, 57) i `/przeglad` (l. 72).
Dlaczego to groźne: instrukcja „Replace every <placeholder>, delete lines that do not apply” stoi tylko w komentarzu HTML, którego Claude przy auto-ładowaniu nie widzi [CL 2.1.72]; właściciel nie odróżni, które zdania zależą od mechanizmu, którego jeszcze nie ma; najgorszy przypadek to l. 45 — Claude uzna, że subagenci dostają reguły z hooka, więc nie powtórzy ich w promptach; zgubiony jest jedyny mechanizm z Foldery dla zasady „ten plik zmienia się tylko za zgodą” („a permission prompt asks him”, Foldery l. 29) — przeczy to własnej deklaracji raportu (l. 115) i Felixowi (l. 7).
Dowód: O0 §8 l. 181: „A rule for an agent must be in the prompt or definition”; O0 §8 l. 179.
Poprawka: (a) każde takie zdanie zamienić na warunkowe miejsce do wypełnienia; (b) dodać linię widoczną dla Claude: „If a mechanism named in this file (hook, script, agent, skill) does not exist in the repository, say so and treat that line as advice; never assume it ran.”; (c) w komentarzu HTML lista kontrolna „Mechanisms this file assumes”; (d) przywrócić mechanizm zgody: `"ask": ["Edit(/CLAUDE.md)", "Edit(/.claude/**)"]` w `.claude/settings.json` (O2 D4) [ASSUMPTION: czy reguła `ask` pyta także w trybie auto — sprawdzić na atrapie]; (e) w §6 raportu dopisać, że szablon wymaga zestawu startowego (playbook §8 p. 3 „Harness before content”).

## Zarzut 2 — WAŻNY. Błąd faktyczny o worktree
Gdzie: szablon l. 49. „A worktree is cut from origin/main: commit + push first”. Wypchnięcie gałęzi sesji nie zmienia `origin/main`, więc kopia agenta nadal nie zawiera Twoich commitów. Źródło (Foldery l. 94) mówi „commit + push + merge first”; przy skracaniu wypadło „merge”. Raport w l. 16 i l. 85 opisuje to poprawnie, więc szablon jest sprzeczny z własnym raportem.
Dowód: O0 §3 l. 67 („`isolation: worktree` = copy from origin/<default branch> … not from parent's HEAD; `worktree.baseRef: "head"` = local HEAD”); O0 §3 l. 68 („Uncommitted changes don't reach the copy”).
Poprawka: „A worktree is cut from `origin/<default branch>`, not from your branch: set `worktree.baseRef: "head"` in `.claude/settings.json` and commit before starting the agent (uncommitted changes do not reach the copy). Merging into `main` first is possible only under merge policy A.”

## Zarzut 3 — WAŻNY. `onFailure: "block"` „na każdej bramce” przeczy wierszowi o python3 i może zablokować sesję
Gdzie: szablon l. 64 i l. 70. Wiersz l. 64 mówi „hooks need python3 on PATH or they silently do not run”; l. 70 każe „set onFailure: "block" on every gate”. Po zastosowaniu l. 70 brak python3 na PC nie wyłącza bramek po cichu, tylko blokuje każdą akcję, którą bramka obejmuje. Bramka nasłuchująca na Edit/Write/Bash po awarii zablokuje też edycję `.claude/settings.local.json` — wyjście awaryjne `disableAllHooks` przestaje być osiągalne z sesji [ASSUMPTION wyprowadzone z brzmienia changelogu, niezmierzone]. Uderza to w wymóg Felixa „ma działać tak samo w chmurze i lokalnie”.
Dowód: CL 2.1.295; O2 A6 l. 135 (zła ścieżka do skryptu daje kod 127, „policy hook is then silently off”); O2 A1 l. 31 (`disableAllHooks`).
Poprawka: `onFailure: "block"` tylko na bramkach z wąskim `if` (np. `Bash(git push *)`, edycje chronionych ścieżek), nigdy na hooku odpalanym przy każdym Bash/Edit/Write; wiersz PC: „without it a gate with `onFailure: "block"` blocks its action and other hooks are silently off; the setup check reports a missing `python3`”; droga awaryjna dla właściciela: na PC plik `.bat`, który ustawia `disableAllHooks`; w chmurze zmiana `.claude/settings.json` na GitHubie i nowa sesja.

## Zarzut 4 — WAŻNY. Pominięte warunki „twardych” zabezpieczeń
Gdzie: szablon l. 68–69; brak zdania o katalogu startowym.
(a) Reguły deny i hooki projektu ładują się tylko wtedy, gdy sesja lub `claude -p` startuje w katalogu głównym repo, a sesja ma podpięte tylko to jedno repo; inaczej cała warstwa „Hard” znika bez komunikatu. Expert miał to zdanie (l. 79); raport l. 102 odrzucił całą sekcję „eksperymenty” jako domenową i ta reguła wypadła razem z nią. (b) „Hard on every path is only branch protection and the sandbox” bez warunków z KB: ochrona gałęzi w prywatnym repo działa tylko w płatnym planie i domyślnie nie obejmuje admina (repo PoB jest prywatne, PoB l. 200); sandbox w chmurze niezweryfikowany (`bwrap` nie jest zainstalowany). Raport l. 107 przytacza O0 §8 bez tego zastrzeżenia.
Dowód: O0 §4 l. 99; O0 §8 l. 195; playbook §4 l. 47; findings 2026-10-08; O0 §7 l. 169 i O0 §8 l. 196; O0 §4 l. 98.
Poprawka: „Project deny rules and hooks load only when the session or `claude -p` starts at the repository root, in a session with this repository alone; start every `claude -p` from the root.”; l. 69: „Hard on every write to GitHub is only server-side branch protection — for a private repository only on a paid plan and with admin bypass disabled; check it is on, otherwise push to `main` is guarded only by hooks. The sandbox is off unless `sandbox.enabled`; in the cloud it is unverified.”

## Zarzut 5 — WAŻNY. Brak reguły dla subagentów, którzy też ładują ten plik
Gdzie: szablon l. 11–19 i l. 45–46. Subagent general-purpose i agent workflow dostają CLAUDE.md, ale nie mają AskUserQuestion; czytają polecenia, których nie mogą wykonać (l. 13 „get explicit confirmation … AskUserQuestion”, l. 14 „stop … and ask”, l. 18 format zakończenia odpowiedzi). Skutek: agent stanie albo napisze raport w formacie dla właściciela [ASSUMPTION co do zachowania]. PoB miał rozwiązanie (l. 87–89: „ta sekcja i raport otwarcia go nie obowiązują”); szablon wziął z PoB §2 tylko fakt o `omitClaudeMd`.
Dowód: O0 §2 l. 53–54 (general-purpose i workflow agent: CLAUDE.md = yes); O0 §2 l. 57 (agenci tracą AskUserQuestion); playbook §5 l. 55.
Poprawka: „If you are a subagent or a workflow agent: the Owner rules on reply format, questions and screen consent do not apply; never stop to ask — finish what you can and list open questions, assumptions and refusals in your report; your task prompt overrides this file where they differ.”

## Zarzut 6 — WAŻNY. „Wersja przy scalaniu” działa tylko przy polityce A, a reguła o sesjach równoległych zginęła
Gdzie: szablon l. 55–56 i l. 36. Przy polityce B właściciel sam klika merge na GitHubie — nikt nie nadaje numeru wersji, nie dopisuje CHANGELOG ani nie robi paczki „at merge time”. L. 36 każe każdej sesji nadpisać `STATUS.md`; dwie równoległe sesje dadzą dwa PR z konfliktem w STATUS. Rozwiązania z plików: Foldery l. 65 („One session with changes at a time; if two ran in parallel, merge both STATUS texts by hand”); PoB l. 209–213 i 226–229 („nigdy dwa scalania naraz”, „podział pracy = podział plików”). Raport tego nie omawia (grep „równoleg/parallel/naraz” = 0).
Poprawka: l. 56 przenieść do opcji A; dla B: „the branch carries the version number, CHANGELOG line and package; before the PR, merge `origin/main` into the branch and resolve STATUS/CHANGELOG conflicts keeping both texts; one versioned PR open at a time.”; przywrócić regułę z Foldery l. 65.

## Zarzut 7 — WAŻNY. Wymóg Felixa „tak samo w chmurze i lokalnie” jest zapowiedziany (l. 6), ale nie zrealizowany
(a) Git na PC: szablon l. 53 opisuje tylko gałąź sesji w chmurze; na PC nic nie każe utworzyć gałęzi, więc przy polityce B lokalna sesja commituje prosto na `main`. PoB l. 206 miał regułę (`git switch -c <temat>`); wypadła bez słowa. (b) Auto memory (MEMORY.md) działa na PC, a w chmurze nie; wiersz PC (l. 64) tego nie wymienia. (c) PoB §6 (l. 140–150) w raporcie w ogóle nie występuje: każda zmiana ma dalej działać w chmurze; zmiana narzędzi lub testów = aktualizacja skryptu chmurowego w tej samej sesji; awarię skryptu naprawia się w skrypcie, nie obchodzi ręcznie. Szablon l. 26 przyjął wersję Foldery („exit ≠ 0 → … go on”) bez tej naprawy. (d) PoB l. 22: gdy nie ma narzędzia do wysyłania plików, trzeba to powiedzieć; szablon l. 57 zakłada SendUserFile wszędzie [ASSUMPTION].
Dowód: Felix l. 12; O0 §2 l. 49; O2 D3 l. 438 (`autoMemoryEnabled`).
Poprawka: „On the owner's PC: `git fetch` and `git switch -c <topic>` from an up-to-date `main` before the first edit; never commit on `main` locally under policy B.”; wiersz PC: „auto memory exists here, not in the cloud: set `"autoMemoryEnabled": false` in `.claude/settings.json` [project scope unverified]; keep everything later sessions need in the repo.”; skrócona reguła PoB §6 pogodzona z l. 26.

## Zarzut 8 — WAŻNY. Reguły właściciela zmienione bez zgłoszenia
(a) Effort agentów: szablon l. 47 proponuje „`medium` for scouting”; reguła właściciela z 2026-10-08: „Opus 5.5 at effort high or above for the session, every agent and every claude -p” (Foldery l. 38); playbook l. 5: „high as the MINIMUM”. KB wspiera `medium` jako start (O0 §8 l. 189), ale CLAUDE.md tego repo każe taki konflikt zgłosić, nie rozstrzygać samemu. (b) Język raportów: Felix l. 24 „reports: Polish”; szablon l. 11 „Everything written to the repository … is in English”; raport l. 68 nazywa te dwie reguły Felixa sprzecznymi — nie są (jedna dotyczy czatu, druga plików). (c) Czytanie w całości: Felix l. 26; raport l. 23 nazywa to „najlepszą zasadą”, szablon l. 15 zachowuje tylko drugą połowę zdania. (d) Cechy właściciela z Felixa pominięte: l. 27 (polska terminologia prawnicza), l. 28 („Pomocnicy”).
Poprawka: (a) placeholder z jawnym konfliktem i „owner decides”; (b) „Reports and files meant for the owner to read: Polish; everything else written to the repository: English.”; (c) „Read a file in full before changing it or drawing conclusions from it; a file read only in parts is named as such.”; (d) dodać dwie linie albo wpisać do tabeli odrzuceń z powodem.

## Zarzut 9 — WAŻNY. Brak reguły zakresu i brak jej analizy
Dwa z czterech plików mają regułę „pracuj tylko w obrębie projektu”: Expert l. 13; PoB §0.2 (l. 12–18). W szablonie nie ma żadnej reguły zakresu; raport ani jej nie wymienia, ani nie odrzuca. Na PC Claude ma dostęp do całego dysku.
Dowód: O0 §8 l. 180 („Without sandbox deny is not a boundary”); O2 D3 l. 419 (`permissions.blockReadsOutsideWorkingDirectories`, działanie niezmierzone).
Poprawka: „Work only inside this repository (cloud: also the session scratchpad for temporary files; PC: temporary files in `_tmp/`, ignored by git). Never read or change anything outside it — other repositories, the owner's documents, system settings — unless he asks.”; w „Enforcement” mechanizm: deny dla wrażliwych ścieżek na PC i/lub `blockReadsOutsideWorkingDirectories` [do zmierzenia]; wiersz w tabeli porównań.

## Zarzut 10 — WAŻNY. Przekazanie następnego kroku: fałszywa teza o „identycznej regule” i pominięte EFFORT-ZASADY
Raport l. 79: „Pliki .bat, wyniki do plików, czat = streszczenie | Foldery + PoB §8 | identyczna reguła w obu”. Co do promptu dla następnej sesji to nieprawda: Foldery l. 18 („handover prompt … written into files”, właściciel nigdy nie wkleja) vs PoB l. 49–50 („Prompt dla następnego okienka zawsze podajesz w rozmowie CAŁY (blok kodu do skopiowania)”, decyzja 2026-10-01). Dwie przeciwne decyzje właściciela; szablon (l. 16) wybiera Foldery i tego nie zgłasza. Oba dojrzałe projekty mają mechanizm „model, effort i agenci dla następnego kroku + blok przekazania” (Foldery l. 100: `EFFORT-ZASADY.md`, skill `/przekazanie`; PoB §0.8). W raporcie słowo „EFFORT” nie pada ani razu; w szablonie tego mechanizmu nie ma.
Poprawka: poprawić raport l. 79; w szablonie jawny wybór A/B („Next session: <A: the next task is the 'Next task' line of STATUS.md … | B: the full prompt … as one copyable code block in chat, also saved to `<docs>/prompts/<id>.md`>”); „When you propose the next step, state model, effort and whether agents are needed, each with a one-line reason (rules: `<docs>/EFFORT-RULES.md`).”; w raporcie przeanalizować EFFORT-ZASADY.

## Zarzut 11 — WAŻNY. Nowe sprzeczności w szablonie
Raport l. 58 chwali szablon za „bez sprzeczności”; KB: przy sprzecznych regułach model wybiera dowolnie (O0 §6 l. 132). Cztery: (a) l. 14 „Numbers in replies come from a run, not an estimate” vs l. 46 „cost and time estimate”; (b) l. 13 „do not stop after a plan” — wypadł wyjątek z PoB l. 94 (plan/audyt na życzenie → czekaj na „działaj”); (c) l. 14 „behaviour unknown: stop … and ask” — PoB l. 95 miał najpierw zrzut wiki, pytanie dopiero potem; w uogólnieniu Claude pyta nie-programistę o zachowanie kodu, które może sam sprawdzić; przeczy l. 13; (d) l. 31 wymaga recenzenta przy każdej nietrywialnej zmianie (0,8–1,8 USD, playbook l. 78), a l. 46 pozwala bez pytania tylko na „one agent … within ~1 USD”.
Poprawka: (a) „Numbers stated as facts come from a run; estimates (cost, time) are marked as estimates.”; (b) „…do not stop after a plan — unless the owner asked for a plan or an audit: deliver it and wait for his go.”; (c) „…: first check the code, the docs or a run; if that does not settle it and the answer is the owner's knowledge or decision, stop before coding that part and ask…”; (d) „One agent or probe within ~1 USD, and the reviewer required by Verification: run it.”

## Zarzut 12 — WAŻNY, ale jako zalecenie, nie warunek. Dwa rdzenie Felixa usunięte z niewystarczającym powodem
Felix opiera się na: wiedzy z KB zamiast pamięci (l. 15, 20) i niezależnym sprawdzeniu każdego planu, analizy, promptu i kodu (l. 15). Raport usuwa oba: l. 103 „brak progu kosztowego” uzasadnia dodanie progu, nie wycięcie przeglądu planów; l. 104 „tylko w repo z KB” — szablon nie daje w zamian zdania „nie polegaj na pamięci o Claude Code” (Felix i Expert l. 39 je mają). Koszt O0 (ok. 17,7 tys. tokenów) jest argumentem przeciw obowiązkowi, nie przeciw regule warunkowej.
Poprawka: l. 31 „Non-trivial change, and any plan, analysis or prompt the owner will act on: one independent read-only reviewer (within the cost gate)…”; w „Start”: „Claude Code behaviour (hooks, permissions, agents, settings, cloud): do not rely on memory; check `<docs>/FINDINGS.md` and the official docs first; in a repository with the knowledge base, `<kb>/O0-how-claude-works.md`.”; albo przedstawić właścicielowi jako jego decyzję.

## Zarzut 13 — DROBNY. Zawyżone tagi i cytaty
(a) Raport l. 24, 55, 95: „PL = +25–35 % tokenów [MEASURED]” — to iloraz B/token różnych tekstów, czyli [ASSUMPTION]; KB ma bezpośredni pomiar tej samej treści w dwóch językach (O0 l. 5): +23 %. (b) Raport l. 103 „(playbook §1.3 [MEASURED])” — w playbooku koszt recenzji ma tag `[MEASURED-derived]`, koszt startu agenta „[ASSUMPTION from O0 §2 start sizes]”. (c) Raport l. 94: hook InstructionsLoaded odpala tylko dla CLAUDE.md i `.claude/rules` (O2 A5 l. 106), nie dla STAN/MAPA; „O0 §5 self-report ungrounded” dotyczy effortu, nie czytania plików. (d) Raport l. 77: odwołanie do O0 §6 „quoty/fabrykacja” nie wspiera tezy. (e) Raport l. 15: Foldery (11 007 B) nie mieści się w „≤ ~10 KB” z playbooka §8; szablon ma limit 20 KB = 2× budżet playbooka, bez wyjaśnienia (powód: reguła właściciela z Foldery l. 85).

## Zarzut 14 — DROBNY. Zniekształcenia PoB i Felixa w raporcie
(a) PoB §3 vs §12 „czytelnik musi sam rozstrzygać” — PoB rozstrzyga to wprost w obu miejscach (l. 93, l. 238). (b) STAN, Pamietac, Niedokonczone to nie „pliki nakładające się” — PoB l. 38–42 definiuje je rozłącznie; scalenie ma sens z innego powodu (mniej plików). (c) „start wymaga trzech plików w całości” — CLAUDE.md ładuje się sam, szablon też każe czytać STATUS i MAPA §1; realna różnica to cała MAPA zamiast §1, a rozmiaru MAPA nikt nie zmierzył. (d) Felix ma „stan między sesjami … git” (l. 18, l. 31). (e) Felix każe obowiązkowo czytać tylko O0 (l. 15), nie „cały folder knowledge”.

## Zarzut 15 — DROBNY. Nieścisłości i niespójności w szablonie
(a) Limity powtórzone (20 KB w l. 19 i 39; 6 KB w l. 24, 36, 39) — łamie „One rule, one place”. (b) Pozostałości polskie z Foldery: „przegląd zaległy — uruchom /przeglad”, „Ostatni przegląd:”, nazwy skilli `/dostawa`, `/przeglad`. (c) `.claude/rules/*.md` do 36 KB bez rozróżnienia: reguły bez `paths:` ładują się na starcie (O0 §2 l. 39) — 36 KB to ok. 13 tys. tokenów w starcie każdego agenta. (d) „hooks and settings at once” — `model` i `effortLevel` czytane tylko przy starcie (O2 D3). (e) l. 47: O0 §5 l. 114 — `effortLevel` w ustawieniach użytkownika nie działa na Opus 5.5; zakres projektu niezweryfikowany. (f) brak `/reload-skills` dla nowego folderu skilli (O0 §2 l. 46, §8 l. 183). (g) przegląd tylko „after every model change” — O0 §9 l. 202 każe też po nowej wersji CC. (h) „a file ≤ 40 KB fits one Read” — dla krótkich linii z liczbami (1,55 B/tok) 40 KB to ok. 26 tys. tokenów. (i) l. 55 „open a PR” vs l. 68 „write through git only” — samym gitem PR-a nie da się otworzyć.

## Zarzut 16 — DROBNY. Mniejsze sekcje źródeł bez analizy
PoB §0.3 (zrzuty pokazywane w rozmowie, nie archiwizowane; brak narzędzia → powiedz); PoB §0.6 (produkt nie zawiera i nie czyta plików roboczych); PoB §7 l. 159–160 (nigdy nie zgadywać nazwy ani sygnatury funkcji — plik:linia) i l. 158 (heredoc w bashu psuje się na apostrofach → skrypt przez Write). Każda ma wersję ogólną; dopisać do §5 raportu jako wzięte albo odrzucone z powodem.

## Pytanie 1 — rzetelność analizy każdego z czterech plików
Foldery: zrozumiany dobrze; pominięte l. 29 (mechanizm zgody), l. 65 (sesje równoległe), l. 100 (EFFORT/przekazanie); jedno przekłamanie przy skracaniu (l. 94). PoBTweaks: główne linie zrozumiane, ale nierówno; bez śladu §0.2, §0.3, §0.6, §6, §7; §0.8 sprowadzony do „pełny prompt + CO DALEJ”; pominięte l. 87–89 i l. 206; zniekształcenia §3/§12 i §0.7. Expert: zrozumiany; z częściami domenowymi wypadły reguły ogólne (l. 79, l. 13) i ogólny wariant „Freshness”. Felix: potraktowany najsurowiej („najlepsza zasada” pochwalona, potem pominięta; „raporty po polsku” i cechy właściciela zgubione; dwa rdzenie usunięte z niepełnym powodem; drobne zniekształcenia); sekcja „Where things stand” ma ślad.

## Pytanie 2 — poprawność wniosków
Ranking Foldery > Expert > Felix > PoBTweaks: zgadzam się; żaden zarzut tego nie zmienia. Cytaty z KB sprawdzone i zgodne: O0 §8 l. 179; O0 §6 l. 132; O0 §2 l. 39, 40; O0 §8 l. 184; O0 §3 l. 67; O0 §5 l. 111; O0 §7 l. 168; O0 §6 l. 150–151; O2 D3 l. 424–425; O2 D5 l. 471; O5 §2 l. 50; playbook l. 16, 52, 85; findings 2026-10-06; changelog 2.1.72, 2.1.293, 2.1.295. Niepodparte lub zawyżone: zarzut 13 (a–e); O0 §8 l. 196 bez zastrzeżenia o płatnym planie; teza o „identycznej regule”. Fakty z KB sprzeczne z szablonem: O0 §3 l. 67; changelog 2.1.295 wobec l. 64; O0 §4 l. 99 i §8 l. 195; O0 §2 l. 53–57; O0 §2 l. 49; O2 D3. Zmiany 2.1.292–2.1.296: nic nie zmienia wniosków raportu.

## Pytanie 3 — czy decyzje mają uzasadnienie w KB
Odrzucenia: 1 raport otwarcia — słuszna, uzasadnienie częściowo błędne (13c); 2 polski — słuszna, liczba zawyżona (13a); 3 historia — słuszna; 4 trzy pliki na start — uzasadnienie słabe (14c); 5 trzy pliki pamięci — rozsądna, powód błędny (14b); 6 reguły domenowe PoB — słuszna; 7 specyfika Foldery — słuszna; 8 „Opus high” jako tekst — co do sesji słuszna, minimum `high` dla agentów zgubione (8a); 9 części domenowe Expert — słuszna poza 4, 9, 15g; 10 „≥ 1 agent” — powód uzasadnia próg, nie usunięcie (12), tag zawyżony (13b); 11 obowiązkowe O0 — brak zamiennika (12), zniekształcenie (14e); 12 język odpowiedzi — do przyjęcia, zgubione „raporty po polsku” (8b); 13 patron — słuszna; 14 scalanie przez Claude — słuszna, ale „wersja przy scalaniu” tylko dla A (6), brak zastrzeżenia o planie (4); 15 usuwanie gałęzi — słuszna. Elementy wzięte mają poprawne dowody z wyjątkami: worktree (2); „identyczna reguła” (10); PoB §3 z O0 §6 (13d); onFailure — fakt prawdziwy, zastosowanie złe (3); SubagentStart jako istniejący (1).

## Pytanie 4 — czy autor przeczytał pliki w całości
Do końca: tak (treść z ostatnich sekcji każdego pliku jest w raporcie i szablonie; pomiary pokrywają się co do 1 tokena). Nie wszystko jednak przeanalizowano: PoB §0.2, §0.3, §0.6, §6, §7, EFFORT z §0.8; Foldery l. 65 i l. 100; Expert l. 13 i l. 79; Felix l. 27. Zdania, których nie dałoby się tak napisać po uważnej lekturze: raport l. 79, l. 24, l. 61, l. 23, l. 104; szablon l. 49.

## Pytanie 5 — czy szablon zgadza się z KB i z wnioskami raportu
Problemy: zarzuty 1–8, 11, 15. Rozmiary zgodne z raportem. Komentarze HTML: teza poprawna. Placeholdery `<…>` w porządku; problemem są zdania napisane jako fakt (1). Odrzucone w raporcie, a obecne w szablonie: „medium for scouting” (8a); pozostałości z Foldery (15b). Przyjęte, a nieobecne: „czytaj plik w całości” (8c); poprawna reguła worktree (2).

## Pytanie 6 — co jeszcze powinien wiedzieć właściciel
Stronniczość na korzyść Experta: w rankingu jej nie widzę; jedno rozstrzygnięcie na korzyść Experta bez zgłoszenia (język plików, 8b); wypadła za to reguła Experta „nic poza repo” (9). Systematycznie słabiej potraktowany jest Felix (8, 12, 14). Szablon to tylko jedna część: bez zestawu startowego (settings z deny/ask, hooki SessionStart/Stop/SubagentStart/bramka pusha, agenci, skille, szkielety STATUS/MAPA/BACKLOG/OWNER-RULES) nie zadziała tak, jak opisuje; hooki sprawdzić na repozytorium testowym. Końce linii CRLF w trzech plikach (ok. 1 % bajtów). Licznik tokenów nie zależał od modelu sesji (Fable 5.1 vs Opus 5.5, ±1).

## WERDYKT (runda 1): AKCEPTUJĘ PO POPRAWKACH
Warunki akceptacji: zarzuty 1–11 (zarzut 1 blokujący; w 8 i 10 wystarczy, że raport jawnie przedstawi konflikt i decyzję właściciela). Bez warunku: 12 (zalecenie albo decyzja właściciela), 13–16 (warto poprawić, nie blokują).

---

# RUNDA 2 (po poprawkach autora)

## Werdykt końcowy (runda 2): AKCEPTUJĘ PO POPRAWKACH
Wszystkie 16 poprawek jest w plikach i zgadzają się z bazą wiedzy. Poprawki wprowadziły jednak trzy nowe ważne błędy (N1–N3). Dwa z nich pochodzą z brzmienia, które sam zaproponowałem w pierwszej rundzie. Każdy da się naprawić jednym zdaniem.
Przeczytane w całości: szablon v2 (78 linii, 19 879 B); raport v2 (151 linii); dodatkowo porównanie v1 z v2. Pomiar: szablon v2 ma 7 256 tokenów z komentarzami i 6 003 bez (17 203 B) — zgodne z autorem co do 1 tokena [MEASURED, CC 2.1.296, Opus 5.5, n=1].

## 1. Czy poprawki naprawdę są w plikach
Tak, wszystkie (zweryfikowane w tekście szablonu i raportu, zarzut po zarzucie; 2 zgodne z O0 §3; 3 zgodne z changelogiem 2.1.295; 5 — zob. N1; 12 — zob. N3). Inne nowe twierdzenia szablonu sprawdzone i zgodne z KB: reguły bez `paths:` ładują się na starcie (O0 §2); `effortLevel` czytany na starcie i nie działa w ustawieniach użytkownika na Opus 5.5 (O0 §5, O2 §D3); hooki i reguły uprawnień działają od razu (O0 §3), `/reload-skills` dla nowego folderu skilli (O0 §2); przegląd po nowej wersji Claude Code (O0 §9).

## N1 — WAŻNY. Subagenci zwolnieni ze zgody na ekran (S l. 50)
Zdanie „the Owner rules on reply format, questions and screen consent do not apply to you” zwalnia subagenta z reguły zgody na wszystko, co dzieje się na ekranie właściciela. To brzmienie zaproponowałem sam w zarzucie 5 i to był mój błąd. W PoB ta reguła jest nadrzędna (§0 „zawsze, niezależnie od środowiska, trybu, ustawień i uprawnień”, 0.1). Subagenci mogą mieć narzędzia MCP, w tym computer-use (O0 §2 l. 16 [MEASURED]).
Poprawka: „…the Owner rules on reply format and questions do not apply to you, and you act on the owner's screen only if your task prompt states his yes for this run; never stop to ask — …”

## N2 — WAŻNY. Reguła `ask` na `Edit(/.claude/**)` obejmie też worktree agentów (S l. 22 i l. 4)
Worktree leży w `.claude/worktrees/` (changelog 2.1.157, 2.1.206, 2.1.212, 2.1.246). Reguła zakotwiczona w katalogu głównym (O2 §D4) obejmie każdą edycję implementera z l. 55: właściciel dostawałby prompt przy każdej zmianie pliku albo równoległa praca agentów stanie [ASSUMPTION: dopasowanie ścieżki niezmierzone]. Klasyfikator auto mode z tego powodu wprost wyłącza worktree z ochrony `.claude/` (O0 §4 l. 102). Tę regułę też zaproponowałem ja (zarzut 1d).
Poprawka: wymienić pliki jawnie (`Edit(/CLAUDE.md)`, `Edit(/.claude/settings.json)`, `Edit(/.claude/settings.local.json)`, `Edit(/.claude/agent-rules.md)`, `Edit(/.claude/agents/**)`, `Edit(/.claude/hooks/**)`, `Edit(/.claude/rules/**)`, `Edit(/.claude/skills/**)`); w placeholderze dopisać „…and that an edit inside `.claude/worktrees/` does not ask”.

## N3 — WAŻNY. Recenzent bez limitu kosztów; raport twierdzi co innego niż szablon
W szablonie recenzent jest obowiązkowy dla każdej nietrywialnej zmiany oraz dla każdego planu, analizy i promptu (S l. 35); l. 52 zwalnia go ze zgody. W praktyce wraca nieograniczona reguła Felixa, którą raport sam krytykuje (R l. 23). Każda recenzja to 0,8–1,8 USD (playbook l. 78). Raport mówi co innego niż szablon (R l. 93, 115, 124, 147: „w ramach bramki kosztowej”; R l. 95: „recenzent nie wymaga zgody”). Konflikt wziął się z połączenia dwóch moich propozycji (11d i 12).
Poprawka: l. 52: „One agent or probe within ~1 USD, and the reviewer of a non-trivial code change: run it. A reviewer for a plan, analysis or prompt: run it if it fits ~1 USD, otherwise give the estimate and ask.” Albo: właściciel świadomie zostaje przy regule bez progu, a raport w §6 podaje koszt.

## N4 — DROBNY. Reguła zakresu w dosłownym czytaniu zabrania rzeczy koniecznych (S l. 18)
„Never read or change anything outside it” zabrania czytania oficjalnej dokumentacji (wymaganej w l. 28), plików wgranych przez właściciela do sesji i instalowania narzędzi skryptem setup (l. 30, 69).
Poprawka: „Allowed: the official docs and package registries (read), files the owner sent to this session, tools installed by the setup script.”

## N5 — DROBNY. Paczka w polityce B (S l. 61 vs l. 62)
„the branch carries … package” da się przeczytać jako commit paczki do repo; l. 62 mówi „never committed”.
Poprawka: „B: version number and CHANGELOG line are made on the branch; the package is built from it and sent, never committed; …”

## N6 — DROBNY, informacja dla właściciela. Rozmiar szablonu
Widoczna część to 17,2 KB i ok. 6 tys. tokenów: o 42 % więcej niż v1 i o 36 % więcej niż Foldery; 84 % własnego limitu 20 KB, zanim dopisze się cokolwiek o projekcie; po wypełnieniu placeholderów od razu zadziała ostrzeżenie „≥ 90 %”. To nie błąd: każdą linię dodano na wniosek recenzji. Ten koszt płaci jednak każdy agent ładujący CLAUDE.md (O0 §8).
Opcja ograniczenia: szczegóły operacyjne z „Enforcement” (obejścia, `onFailure`, droga awaryjna, kiedy zmiany wchodzą, lista przeglądu) przenieść do `.claude/rules/enforcement.md` z `paths: [".claude/**"]` — ładuje się tylko przy pracy na hookach i ustawieniach (O2 §D5, changelog 2.1.293). Pierwszy punkt sekcji (co twarde, co rada) zostaje w głównym pliku. Usunięcie niewybranych wariantów A/B da jeszcze ok. 1 KB.

## 3. Ocena odrzuceń częściowych
- 1(a): przyjmuję. Linia 9 jest widoczna dla Claude; do tego lista kontrolna w komentarzu i jawny warunek przy SubagentStart, jedynym miejscu, gdzie brak mechanizmu był groźny. Pozostałe zdania przy braku mechanizmu degradują się łagodnie.
- 15(b): przyjmuję. Poprawka objęła komunikat hooka, linię w STATUS i nazwy skilli. Polskie nagłówki odpowiedzi to treść czatu, a ich dosłowne brzmienie jest potrzebne hookowi Stop.
- Heredoc: przyjmuję odrzucenie. To technika, nie reguła bazowa. W tej sesji dwa moje polecenia z `<<'EOF'` i apostrofami zadziałały poprawnie [MEASURED: Linux w chmurze, n=2]. Na Windows niezweryfikowane; jeśli problem tam wystąpi, miejsce na tę wiedzę to reguła albo skill projektu.

## Warunki akceptacji (runda 2)
Warunki: N1, N2, N3. Zalecane, ale nie blokują: N4, N5, N6. Po wprowadzeniu N1–N3 w powyższym brzmieniu (i ujednoliceniu raportu w miejscach wskazanych w N3) akceptuję bez kolejnej rundy recenzji. Autor może sprawdzić to sam grepem po frazach: „screen consent”, „.claude/**” i „bramk”.

---

# Stan po rundzie 2 (autor)
Wprowadzone: N1, N2, N3 (warunki) oraz N4, N5 (zalecenia). N6: opcja opisana w raporcie §6, decyzja właściciela. Sprawdzenie grepem w szablonie v2.1: „screen consent” = 0 trafień; „.claude/**” tylko w zdaniu „never `Edit(/.claude/**)`” i w komentarzu HTML; raport ujednolicony („bramk”: wszędzie „do ~1 USD bez pytania, powyżej szacunek i pytanie”).
