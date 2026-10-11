# Plan przebudowy bazy wiedzy (KB) — wersja 2, 2026-10-11

Wersja 1 → 2: po recenzji `REVIEW-1-opus-xhigh.md` (Opus 5.5 xhigh; 19 ustaleń, 5 prób pomiarowych). Zmiany główne: nowy krok 0 (mechaniczna przeprowadzka + strażnik + CI), definicja „pełnego czytania" z odpowiedzi narzędzia zamiast z tekstu komendy, limit 28 000 znaków zamiast 40 KB, ochrona bramek przed sesją, którą pilnują, rozbicie kroku 3 na pięć podkroków, koszty przeliczone.

Stan wyjściowy: `findings.md`, wpisy 2026-10-11 („KB navigation audit" i „hook payload probes").

Język: plan po polsku (czyta właściciel, będzie się zmieniał). Wszystko, co z niego trafi do `knowledge/`, skryptów, hooków i CI, po angielsku (reguła CLAUDE.md).

## 0. Zasady obowiązujące w każdym kroku

1. **Twarde > miękkie.** Gdzie da się wymusić mechanizmem (reguła `deny`, hook z kodem wyjścia 2, kontrola na serwerze GitHub), nie piszemy prośby do modelu. Prośba zostaje tylko tam, gdzie mechanizmu nie ma, i jest wtedy wymieniona w §7 „Co zostaje miękkie". Podstawa: O0 §8 (wnioski oznaczone tam jako [ASSUMPTION] z faktów O0 §4 [SOURCE: CC permissions.md, hooks.md]).
2. **Jeden krok na raz.** Każdy krok to osobna sesja (lub kilka), ma kryterium „gotowe" w postaci komendy z kodem wyjścia, nie opisu. Kolejny krok zaczyna się po Twoim „tak". Przed każdym merge tag `kb-pre-step-N`; cofnięcie = revert merge'a.
3. **Dwa najlepsze modele.** Treść o zachowaniu, promptowaniu i effort dotyczy tylko Opus 5.5 i Fable 5.1. Inne modele zostają jako: wiersz w tabeli ID/cen, pułapka (np. „`claude -p` bez `--model` leci na Sonnet 5.5", O0 §5 [MEASURED]) albo składnik systemu (Haiku generuje tytuły, napędza agenta `claude-code-guide` i ocenia `/goal`; O0 §5, O1 §2, O3 §7). Lista „dwa najlepsze" jest w `STATE.md`, skrypt sprawdza resztę.
4. **Każdy fakt ma znacznik dowodu.** Skrypt sprawdza punkty listy; znacznik w nagłówku sekcji obejmuje punkty pod nim (tak robi dziś O2), punkt-rodzic bez treści jest zwolniony.
5. **Limit pliku: 28 000 znaków** (`wc -m`), cel roboczy 12–20 KB. Powód (recenzja F9, próby P0/P2 [MEASURED 2026-10-11, n=1]): w trybie auto Claude czyta pliki przez `cat`, a Bash pokazuje mu inline najwyżej ~30 000 znaków, powyżej tego widzi tylko 2 KB podglądu (O1 §2: `BASH_MAX_OUTPUT_LENGTH` domyślnie 30 000). Limit Read (25 000 tokenów, O0 §1 [CODE]) przy plikach angielskich do 28 000 znaków nigdy nie jest osiągany, więc liczenie tokenów w skrypcie odpada; pomiar licznikiem Read zostaje na liście „sprawdź po zmianie modelu". Plik, który urośnie ponad limit, dzielimy (najbardziej zagrożony: `docs-index.md`, dzielony na CC / PL).

## 1. Docelowy układ plików (decyzja przed krokiem 0)

Zasada: **nazwa pliku = pytanie, na które odpowiada.** Dzisiejszy podział O0–O5 jest według „skąd wiemy" (pomiar / składnia / streszczenie docs); znaczniki przy faktach niosą tę informację, więc podział jest zbędny.

| Nowy plik | Z czego (stara sekcja → nowy plik; tabela pełna, sprawdzana skryptem w kroku 0) |
|---|---|
| `knowledge/CLAUDE.md` | mapa (generowana z `topics.json`): słowo kluczowe → plik, po jednej linii, tak żeby `grep -i hook knowledge/CLAUDE.md` odpowiadał wprost; reguła znaczników; lista otwartych sprzeczności; ≤ 9 500 znaków (limit wstrzyknięcia hooka to 10 000, O2 §A6) |
| `knowledge/STATE.md` | generowany: wersja CC, data, liczba linków i sha256 `llms.txt`, pliki z rozmiarem, lista dwóch modeli, ostatni pomiar B/token |
| `context-window-and-read.md` | O0 §1 |
| `instructions-memory-skills.md` | O0 §2, O2 §C, O2 §D5, O4 §5 |
| `agents-and-workflows.md` | O0 §3, **cztery punkty o definicji agenta z początku O0 §4**, O2 §B, O3 §5–6 |
| `hooks.md` | O2 §A, punkty o hookach z O0 §4 |
| `permissions-settings-automode.md` | O2 §D1–D4, **D6**, reszta O0 §4 |
| `models-effort-cost.md` | O0 §5, O5 §4, **O5 §5** (status, wycofania) |
| `prompting-and-model-weaknesses.md` | O0 §6, O5 §1–3 |
| `cloud-environment.md` | O0 §7, część sieciowa O1 §3 |
| `headless-sdk-ci.md` | O3 §1–4, §7–10 |
| `mcp-and-plugins.md` | O4 §1–4, §6 |
| `design-rules.md` | O0 §8, sekcja „Reviewing designs" z CLAUDE.md |
| `docs-index.md` | O1 §0 (konwencje), §1, §2, **§3 (procedura weryfikacji, bez części sieciowej), §4**; skrzynki „New URLs" z O3–O5 |
| `recheck-and-conflicts.md` | O0 §9, O1 „Check again", O1 §5 (do skasowania po kroku 4), **O2 §E**, wszystkie „Verify live" i „Deltas", lista sprzeczności |
| `O0…O5-*.md` (stare nazwy) | **zaślepki przekierowujące**: tabela „stara § → nowy plik §" (87 sekcji; za dużo na mapę). Zostają do kroku 4, żeby routing w CLAUDE.md i stare cytaty w `findings.md`/`reports/` działały między merge'ami |

Nagłówek każdego pliku treści (5 linii, sprawdzany): tytuł, `Keywords:`, `Related:`, `As of:` (wersja CC, data), `Cap: 28000 chars` (rozmiar bieżący jest w `STATE.md`, nie w nagłówku, żeby nagłówek nie zmieniał się przy każdej edycji).

## 2. Krok 0 — mechaniczna przeprowadzka, strażnik, CI

Przenosimy **bez zmiany brzmienia**: 141 939 B, 627 punktów, 87 sekcji, 351 identyfikatorów faktów [MEASURED, recenzja]. Nic nie dopisujemy. Dzięki temu krok jest w pełni sprawdzalny maszynowo i odwracalny.

- `scripts/kb_migrate_check.py`: każdy identyfikator faktu i każdy znormalizowany punkt ze starych plików występuje **dokładnie raz** w nowych; każda stara sekcja ma cel w tabeli z §1; zaślepki wskazują istniejące cele.
- **H1 `scripts/kb_check.py`** (deterministyczny, bez modelu): limit 28 000 znaków; nagłówki; pokrycie mapy (każdy plik w `knowledge/`, `reports/`, `migration-kit/` ma wiersz); poprawność odwołań `plik §x`; brak sekcji-skrzynek; znaczniki (reguła 0.4); zakres modeli (dozwolone: tabela, pułapka, składnik); zgodność `STATE.md` z nagłówkami; walidacja `topics.json` niezależna od generatora (każdy regex się kompiluje, każdy plik istnieje, każdy plik treści ma ≥ 1 temat, zdania testowe po polsku i angielsku trafiają w oczekiwane pliki). Sprawdza drzewo `HEAD`, nie katalog roboczy (`git archive HEAD`).
- **H5 CI `.github/workflows/kb-check.yml`**: na każdy push i PR; bez modelu. Uruchamia strażnika **z `origin/main`**, nie z gałęzi, którą sprawdza, i odbudowuje sekcje generowane, porównując z commitem (różnica = błąd). Repo jest publiczne [MEASURED: GitHub API `visibility: public`, 2026-10-11], więc branch protection z wymaganym zielonym CI jest za darmo; musi obejmować administratora, bo domyślnie go nie obejmuje (O0 §7 [SOURCE: github/docs]). Włączasz Ty.
- `reports/README.md`, `migration-kit/README.md`: po linii na plik.

Gotowe, gdy: `kb_migrate_check.py` i `kb_check.py` zwracają 0; CI zielone; `git diff --stat` pokazuje tylko przenosiny i nowe skrypty. Koszt: 1 sesja, ~8–15 USD [ASSUMPTION: głównie praca skryptowa i jedna długa sesja; bez agentów].

## 3. Krok 1 — aktualizacja treści (trzy podkroki, trzy sesje)

**1a. Changelog i skrzynki.**
- `CHANGELOG.md` (raw GitHub, O1 §2), wpisy 2.1.292–2.1.296 (372 punkty [MEASURED]). Plik triage `reports/…/changelog-triage.tsv` z 372 wierszami: punkt → plik docelowy albo „nieistotne" z powodem. Każdy zmieniony fakt **zastępuje** stary, znacznik `[CL 2.1.29x, data]`. Do zweryfikowania w docs (nie tylko w changelogu): `autoCompactWindow`, `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`; `allow_large` potwierdzone w schemacie Read tej sesji [MEASURED].
- Treść skrzynek „Deltas"/„New URLs" wchodzi do plików docelowych; sprzeczności nierozstrzygnięte przez docs idą na listę w `recheck-and-conflicts.md`.
- Gotowe: `wc -l` triage = 372 (+ nagłówek); `kb_check.py` = 0; `STATE.md` = 2.1.296.

**1b. Brakujące strony.** Lista z audytu plus to, czego wymaga krok 3: CC `hooks`, `hooks-guide` (O2 jest „documentation only", częściowo z wycinków; przed budową bramek odświeżyć), `routines`, `scheduled-tasks`. Dalej: `sandbox-environments`, `checkpointing`, `large-codebases`, `troubleshooting`, `debug-your-config`, `plugins/mods/*`, `plugins/manifest-reference`, `plugins/loading`, `plugins/relevance`, `remote-control`, `desktop-scheduled-tasks`, `channels-reference`, `security-guidance`, `server-managed-settings`, `settings-example`; PL: `prompting-claude-fable-5-1`, `models/model-ids-and-versions`, `models/choosing-a-model`, `compaction-*` (5), `context-editing`, `memory-tool`, `tool-search-tool`, `mid-conversation-effort-example`, `cache-diagnostics`. Razem ~33 strony.
- Metoda z O1: `curl -sL <url>.md` do pliku roboczego, `grep -n`/Read z offsetem. Do bazy trafiają fakty zmieniające decyzje, nie samouczki.
- Gotowe: każda strona ma wiersz w `docs-index.md` ze statusem, datą, sha256 i rozmiarem pobranego `.md` (O1 §3) oraz celem („fakty w pliku X" albo „nic istotnego, bo …"); `kb_check.py` = 0.

**1c. Zakres modeli.**
- `STATE.md`: `claude-opus-5-5`, `claude-fable-5-1`. Usunąć szczegóły o Haiku/Sonnet poza tabelą, pułapkami i składnikami; z listy sprzeczności zdjąć „Haiku 4.5 retirement" i „Sonnet 5.5 default effort" (poza zakresem; zapis w `recheck-and-conflicts.md` jako „nie śledzimy").
- Gotowe: `kb_check.py` zakres = 0. Recenzent (Opus 5.5 high) sprawdza 20 losowych faktów z 1a/1b — **doradczo**, każdy błąd poprawiamy.

Koszt kroku 1 [ASSUMPTION, per jednostka: 372 punkty triage ≈ 1 sesja; 33 strony × ~0,5–1 USD pobrania i streszczenia; 13 plików do edycji; wg findings 2026-10-08 ciężka sesja jednego pliku z recenzentem = 3,6–8,1 USD]: 3–4 sesje, **40–90 USD**, 8–12 h czasu maszyny. Podaj pułap budżetu.

## 4. Krok 2 — mapa i drogowskazy („każda droga na skróty prowadzi w dobre miejsce")

Pięć dróg, każda obsłużona mechanizmem, nie prośbą:

1. **`ls knowledge/`** → nazwy = tematy (§1).
2. **`grep`** → `grep -i <słowo> knowledge/CLAUDE.md` daje linię „słowo → plik" (mapa jest greppowalna); jako grep jednego pliku ładuje też mapę do kontekstu. (`grep -ril` po całym katalogu nie szereguje wyników i nie ładuje mapy, więc nie jest drogą, na której polegamy.)
3. **Dotknięcie dowolnego pliku `knowledge/`** → `knowledge/CLAUDE.md` wchodzi w całości przy Read, Write/Edit i jednoplikowym `cat/head/tail/sed -n/grep` (O0 §2 [SOURCE: CC memory.md] [MEASURED: Read] [CL 2.1.293]; `cat` i Read agenta Explore potwierdzone próbą P4 [MEASURED 2026-10-11, n=1]; `omitClaudeMd` do sprawdzenia w 3a).
4. **Start każdego agenta** → hook `SubagentStart` wstrzykuje mapę przez `additionalContext` (O2 §A5), niezależnie od CLAUDE.md, także Explore i `omitClaudeMd`.
5. **Start sesji i każda kompakcja** → hook `SessionStart` (matchery `startup`, `compact`) wstrzykuje mapę i raport świeżości (O0 §6 [SOURCE: CC hooks-guide.md]); łącznie ≤ 10 000 znaków (O2 §A6).

Elementy: `knowledge/topics.json` (temat → regexy PL+EN z rdzeniami odmiany → pliki w kolejności ważności, ≤ 3 na temat); generator `scripts/kb_build.py` (z `topics.json` i plików buduje `STATE.md`, sekcję mapy, linie `Keywords:`; części generowane między `<!-- generated -->`); CI porównuje wynik generatora z commitem. Główny `CLAUDE.md`: tabela KB → dwie linie wskazujące `knowledge/CLAUDE.md` (to zmiana CLAUDE.md = Twoja osobna zgoda).

Gotowe: `kb_check.py` = 0; próba: 5 pytań tematycznych do agenta general-purpose i 5 do Explore, `jq` po transkryptach, pierwszy Read trafia w plik z `topics.json` w ≥ 4/5 na typ; próba `omitClaudeMd` (n=2). Koszt: 1 sesja, ~5–8 USD [ASSUMPTION].

## 5. Krok 3 — twarde mechanizmy (pięć podkroków, każdy osobno mergowalny i odwracalny)

Fakty o hookach: O2 §A [SOURCE: CC hooks.md]; hooki z ustawień projektu działają też w subagentach (O2 §A1, próba P1); kod 2 blokuje i nie da się go nadpisać (O2 §A6); `Stop`/`SubagentStop` z kodem 2 nie pozwalają zakończyć (O2 §A5); `PreToolUse` może podmienić wejście narzędzia (`updatedInput` **zastępuje całe wejście**, O2 §A5).

**Zasada ochrony bramek przed sesją, którą pilnują** (recenzja F3–F5): skrypty hooków w `.claude/hooks/`; reguły `deny` na dokładne ścieżki: `Edit(/.claude/hooks/**)`, `Edit(/.claude/settings.json)`, `Edit(/.claude/settings.local.json)`, `Edit(/scripts/kb_check.py)`, `Edit(/.github/workflows/**)` (nie `Edit(/.claude/**)` w całości: złapałoby worktree agentów); hook `ConfigChange` blokujący zmiany `project_settings`/`local_settings` w trakcie sesji (O2 §A5); `deny` na narzędzia MCP GitHub piszące do serwera (`push_files`, `create_or_update_file`, `delete_file`, `merge_pull_request`…; bare name usuwa narzędzie, O2 §D4), bo omijałyby bramkę push; `onFailure: "block"` **tylko** na handlerze z `if: "Bash(git push *)"`, nigdy na handlerze odpalanym przy każdym Bash (findings 2026-10-11). Stan bramek w `${CLAUDE_PROJECT_DIR}/.claude/kbgate/` (w `.gitignore`, pod `deny`), klucz = `session_id` + przestrzeń testowa, zapisy jednoliniowe `O_APPEND` (hooki działają równolegle, O2 §A7). Wyłącznik awaryjny: zmienna środowiskowa odczytywana przez hooki, ustawiana w ustawieniach środowiska chmury (O0 §7: widoczna dla użytkowników środowiska, dla flagi nie-sekretu to w porządku) albo „edycja ustawień na GitHubie + nowa sesja". Testy `claude -p` zawsze z osobnego checkoutu (`git worktree add /tmp/kbtest`), bo `-p` z korzenia repo uruchamia hooki projektu bez pytania (O0 §4), a zagnieżdżone `-p` dziedziczy `session_id` i katalog scratchpad rodzica (próba P1).

**3a. Sonda** (częściowo zrobiona w recenzji 1; dokończyć, n ≥ 2): Read tego samego pliku po `/compact` (czy stub `file_unchanged` resetuje się, bo po kompakcji treść > 5 000 tokenów nie wraca, O0 §1 — jeśli nie, bramka byłaby spełniona pustym stubem); `updatedInput` na Agent: czy wymaga `permissionDecision: "allow"` i czy to omija klasyfikator auto (O0 §3); czy `SubagentStop` odpala się dla agentów workflow; zagnieżdżony CLAUDE.md dla `omitClaudeMd`. Wynik do `findings.md`. Koszt ~1–2 USD.

**3b. Bramki zapisu (H3).** (a) `PreToolUse`, `if: "Bash(git push *)"`, `onFailure: "block"` → `kb_check.py` na drzewie `HEAD`; błąd = kod 2, push zablokowany. (b) szeroki handler Bash bez `onFailure`, regex `\bgit\b.*\bpush\b` (łapie `git -C . push`), „fail open", zaporą jest CI. (c) `Stop` przy zmianach w `knowledge/`: **doradczy** (komunikat), nie blokujący — blokada uniemożliwiałaby przerwanie tury, żeby Cię zapytać; twardo jest push i CI. Test: `scripts/test_hooks.sh` karmi hooki nagranymi ładunkami (JSON z prób P1–P3 jako fixtures) i sprawdza kody wyjścia; uruchamiany w CI. Żywy test: push z zepsutym nagłówkiem zablokowany, n=2.

**3c. Wymuszone czytanie, sesja główna (H4).** Odpowiedź na „dopiero czytałem, pamiętam":
1. `UserPromptSubmit`: dopasowanie promptu do `topics.json`; wymagane pliki (≤ 3) zapisane pod `prompt_id`; na stdout (idzie do kontekstu) „Required reading: … — read with Read, or one single-file `cat`; a PreToolUse gate blocks other tools until done". Regexy obejmują polskie rdzenie („hook", „hookach", „hooków").
2. `PostToolUse` na Read i Bash loguje czytania plików `knowledge/`. **„Pełne" decyduje odpowiedź narzędzia, nie tekst komendy** (recenzja F1): Read → `tool_response.type == "text"`, `file.startLine == 1`, `file.numLines >= file.totalLines` (pola zmierzone w P1); Bash → komenda czyta jeden plik, brak `persistedOutputPath`, `sha256(stdout) == sha256(pliku)`. Wpisy z `agent_id` **nie liczą się** dla sesji głównej (subagent czytający „za mnie" nie wkłada treści do mojego okna; P1: subagent ma ten sam `prompt_id`). `file_unchanged` liczy się tylko, gdy po ostatniej kompakcji jest zalogowane pełne czytanie tego pliku.
3. `PostCompact`: unieważnia wpisy sprzed kompakcji.
4. **`PreToolUse` „najpierw czytaj"**: przy dopasowanym prompcie blokuje (kod 2) każde narzędzie poza Read/`cat` wymaganych plików, dopóki log ich nie zawiera. To jedyna bramka, która działa **przed** odpowiedzią (Stop działa po niej, O2 §A5).
5. `Stop`: dopasowuje `topics.json` także do `last_assistant_message` (o czym Claude faktycznie mówił, nie tylko o co pytano; pole zmierzone w P1); tematy obowiązują przez kolejne K promptów (start K=3), żeby „a co z tym drugim?" nie omijało bramki; brak pełnego czytania po ostatniej kompakcji → kod 2 z powodem „re-check your previous answer against <file> and state corrections". **Nigdy nie wychodzi wcześniej przy `stop_hook_active`**; każde trafienie limitu 8 blokad (O2 §A5) logowane. Parametru „N tur" nie ma: drugi Read niezmienionego pliku zwraca stub bez treści (P3), więc wymuszanie powtórki bez kompakcji i bez zmiany pliku nic nie wnosi; wyzwalacze to kompakcja i zmiana pliku.
6. Opcja do zmierzenia: dla pytań bez narzędzi wstrzyknięcie dopasowanej sekcji wprost przez `additionalContext` w `UserPromptSubmit` (≤ 9 500 znaków na sekcję); treść jest w kontekście zanim Claude cokolwiek napisze — jedyny sposób na „naprawdę bez wyboru". Koszt: więcej tokenów na pytanie.
Test: `test_hooks.sh` + żywo: pytanie o hooki bez czytania → `PreToolUse` blokuje Edit, `Stop` blokuje i nazywa plik; po kompakcji log wyzerowany; n ≥ 2 każdy.

**3d. Wymuszone czytanie, agenci.** `PreToolUse` na Agent: dopasowanie `tool_input.prompt`, `updatedInput` z **kopią wszystkich pól** (`description`, `prompt`, `subagent_type`, `run_in_background`, `model`, `effort`, `isolation`; P1) i dopisaną linią lektury (to instrukcja, więc miękka; twarde jest to, co niżej). `SubagentStop`: czyta `agent_transcript_path` (w P2 transkrypt przy `SubagentStop` zawierał już pierwszą wiadomość i wywołania Read), dopasowuje tematy do pierwszej wiadomości agenta i sprawdza log pod jego `agent_id`; brak → kod 2, agent nie kończy. Bez wiązania spawn→agent po czasie (psuje się przy równoległych agentach). Explore niegatowany (narzędzie do szukania wycinków; zlecenie „wyjaśnij hooki" agentowi Explore pozostaje skrótem, który łapie dopiero bramka sesji głównej). Test: agent z zadaniem o hookach bez czytania → `SubagentStop` blokuje, n ≥ 2.

**3e. Świeżość (H2) i Routine (H6).** `scripts/kb_freshness.sh` (bez modelu): `claude --version` vs `STATE.md`, wersje i punkty changelogu od tej pory, linki `llms.txt` vs zapisane, dni od edycji plików; odpalany z `SessionStart`, wynik do kontekstu — **miękki** (informuje, nie blokuje). Routine tygodniowa (świeża sesja: freshness + przegląd changelogu i `whats-new` + wpis do `findings.md` + push gałęzi; Ty mergujesz): po udowodnieniu bramek, na stronach `routines`/`scheduled-tasks` z 1b; zakładasz sam.

Koszt kroku 3: 3a ~1–2 USD; 3b–3e po ~4–8 USD (próby recenzji: 0,15–0,26 USD za trywialny `-p` na effort low; testy n ≥ 2 na realnym effort + budowa ~8 skryptów); razem **15–30 USD** [ASSUMPTION]. Koszt stały H4 na sesję: do zmierzenia w 3c (liczba blokad, dodatkowe tokeny).

## 6. Krok 4 — CLAUDE.md (każda zmiana = osobna Twoja zgoda; klasyfikator może odrzucić edycję jako „Self-Modification", findings 2026-10-06: 2 odmowy przy zapisie zgody na merge, 3 zwykłe edycje przepuszczone)

- Tabela KB, znaczniki, sprzeczności, „Freshness", „Live lookups" → `knowledge/CLAUDE.md` i `docs-index.md`. Usunąć „O0 w całości raz na sesję" (zastępuje je bramka 3c). Dopisać linię „po zmianie w `knowledge/` uruchom `kb_build.py`, potem `kb_check.py`" (miękka; CI i push wymuszają).
- Skasować zaślepki O0–O5 i O1 §5 (duplikat procedury). Poprawić stare cytaty? Nie: historia zostaje, tabela przejścia w `recheck-and-conflicts.md`.
- Gotowe: tokeny CLAUDE.md licznikiem Read ≤ dzisiejsze 3 752 (findings 2026-10-11); `kb_check.py` = 0. Działa od następnej sesji (O0 §2).

## 7. Co zostaje miękkie

- Linia lektury dopisana do promptu agenta; raport świeżości; komunikat `Stop` przy brudnym `knowledge/`.
- Limit 8 blokad `Stop` z rzędu bez wywołania narzędzia (O2 §A5): model, który uparcie odpowiada tekstem, w końcu zakończy turę.
- `deny` nie łapie czytania/zapisu ze skryptów Pythona ani komend wewnątrz skryptu bash (O0 §4); zmiana skryptów hooków jest możliwa tą drogą; łapie CI z `main` i branch protection.
- Sesje z kilkoma repozytoriami i `claude -p` spoza korzenia: zero hooków i reguł projektu (O0 §4, §7).
- Agenci workflow: prompty są literałami w skrypcie, dopasowanie częściowe, nietwarde.
- Explore niegatowany. „Przeczytał" ≠ „zrozumiał".
- Routine: zależy od założenia jej i od tego, czy sesja zrobi wpis.

## 8. Kto co robi

Ty: dodajesz/zatwierdzasz `.claude/settings.json` (ścieżka chroniona), włączasz branch protection z CI i administratorem, zakładasz Routine, mergujesz gałęzie, zatwierdzasz każdą zmianę CLAUDE.md, ustawiasz zmienną wyłącznika w środowisku. Ja: wszystko inne, krok po kroku, po Twoim „tak".

## 9. Pytania do decyzji

1. Układ z §1 i krok 0 „przenosiny bez zmiany brzmienia" — tak / nie / zmiany?
2. Limit 28 000 znaków zamiast 40 KB (więcej, mniejszych plików: ~14–16 zamiast 6) — zgoda?
3. Bramka `PreToolUse` „najpierw czytaj" (blokuje wszystkie narzędzia poza czytaniem, dopóki pliki nie są przeczytane) — tak? I czy testować wstrzykiwanie sekcji wprost do promptu (3c.6)?
4. Pliki bramek pod `deny`: Claude nie zmieni hooków, strażnika ani CI; każda zmiana przez Ciebie na GitHubie — akceptujesz?
5. Branch protection obejmująca Ciebie jako administratora — włączysz?
6. Wyłącznik awaryjny: zmienna w środowisku chmury czy „GitHub + nowa sesja"?
7. Wymuszone czytanie także dla sesji automatycznych (Routine, testy `-p`, raporty agentów w tle), czy tylko dla tur, które piszesz?
8. Routine tygodniowa teraz czy po udowodnieniu bramek?
9. Pułap budżetu na krok 1 (szacunek 40–90 USD) i na całość (~70–150 USD plus recenzje)?
10. Dokumenty planu i recenzji w repo po polsku (jak dotąd `reports/`) czy po angielsku?

## 10. Weryfikacja planu

Recenzja 1 (Opus 5.5 xhigh): `REVIEW-1-opus-xhigh.md`, uwzględniona w tej wersji. Audyt 2: Fable 5.1 xhigh i Opus 5.5 max, równolegle — sceptyczna recenzja v2, sprawdzenie, czy recenzja 1 została wprowadzona bez przekłamań, czy autor naprawdę przeczytał to, na co się powołuje, i czego nadal brakuje. Raporty: `REVIEW-2-fable-xhigh.md`, `REVIEW-2-opus-max.md`.
