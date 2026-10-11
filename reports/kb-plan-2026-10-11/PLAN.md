# Plan przebudowy bazy wiedzy (KB) — wersja 3, 2026-10-11

Historia: v1 → recenzja 1 (Opus 5.5 xhigh, `REVIEW-1-opus-xhigh.md`) → v2 → audyt 2 (Fable 5.1 xhigh, `REVIEW-2-fable-xhigh.md`; Opus 5.5 max, `REVIEW-2-opus-max.md`) → v3. Audyt 2 potwierdził, że v2 uwzględniła recenzję 1 (36/36 pozycji, 4 częściowo), a cytaty z bazy są w większości poprawne; obie recenzje zgodnie uznały v2 za „do poprawy w jednej rewizji" z tych samych powodów. Lista, co z audytu przyjęto, a co odrzucono i dlaczego: §11.

Język: plan po polsku (czyta właściciel). Wszystko, co z niego trafi do `knowledge/`, skryptów, hooków i CI, po angielsku (reguła CLAUDE.md).

## 0. Zasady i model zagrożeń

1. **Twarde > miękkie.** Gdzie da się wymusić mechanizmem (reguła `deny`, hook z kodem wyjścia 2, kontrola na serwerze GitHub), nie piszemy prośby do modelu. Prośba zostaje tylko tam, gdzie mechanizmu nie ma, i jest wtedy wymieniona w §8. Podstawa: O0 §8 (wnioski oznaczone tam jako [ASSUMPTION] z faktów O0 §2, §4, §6 [SOURCE: CC memory.md, permissions.md, best-practices.md]).
2. **Model zagrożeń (nowe, audyt 2).** Bramki mają zatrzymać *lenistwo i skróty*: odpowiedź bez czytania, agent bez lektury, push zepsutej bazy. *Celowego* obejścia przez model nie da się zatrzymać lokalnie: w kontenerze nie ma sandboxa (`bwrap` nieobecny [MEASURED: audyt 2]), a reguła `deny` nie łapie skryptów Pythona ani komend wewnątrz skryptu bash (O0 §4 [MEASURED]). Celowe obejście łapie tylko kontrola po stronie serwera (§4 krok 0a) i Twój przegląd PR. Wszystko, co lokalne, jest więc „twarde wobec skrótów, miękkie wobec zamiaru". To zdanie ma stać w `design-rules.md`.
3. **Jeden krok na raz.** Każdy krok to osobna sesja (lub kilka), kryterium „gotowe" = komenda z kodem wyjścia, przed merge tag `kb-pre-step-N`, cofnięcie = revert merge'a (ustawienia po Twojej stronie: branch protection, zmienna środowiska, Routine mają własne „cofnij"). Kolejny krok po Twoim „tak".
4. **Jednostka zgody na edycję KB** (nowe). CLAUDE.md każe proponować każdą zmianę KB „plik, sekcja, stare → nowe". Przy setkach edycji w kroku 1 to niewykonalne. Propozycja: **Twój merge PR danego kroku, po przeczytaniu jego pliku triage (lista: co, gdzie, dlaczego), jest tym „tak"**. Wymaga jednej linii w CLAUDE.md (Twoja decyzja, §10 Q6).
5. **Dwa najlepsze modele.** Treść o zachowaniu, promptowaniu i effort tylko dla Opus 5.5 i Fable 5.1. Inne modele zostają wyłącznie w wierszach oznaczonych znacznikiem: `[scope: trap]` (pułapka, np. „`claude -p` bez `--model` leci na Sonnet 5.5", O0 §5 [MEASURED]), `[scope: component]` (składnik systemu: Haiku generuje tytuły, napędza `claude-code-guide`, ocenia `/goal`; O0 §5, O1 §2, O3 §7), `[scope: why-not]` (pomiary porównawcze, które uzasadniają wybór dwóch modeli, np. „Haiku 4.5 failed 2/4 and 0/4 at Opus medium price", O0 §5) albo w tabeli ID/cen. Skrypt: nazwa modelu spoza listy w linii bez znacznika i poza tabelą = błąd. Lista modeli w `STATE.md`.
6. **Każdy fakt ma znacznik dowodu.** Reguła dla skryptu: znacznik w linii, w nagłówku sekcji nad nią, w pogrubionym pseudonagłówku lub w punkcie-rodzicu obejmuje punkty pod spodem; punkty TL;DR są zwolnione (streszczają otagowane sekcje). Dzisiejsze pliki tej reguły nie spełniają w ~130 punktach [MEASURED: audyt 2], więc check jest włączany dopiero w kroku 1 po jednorazowym otagowaniu (policzonym w koszcie).
7. **Limit pliku: 28 000 bajtów** (`len(bytes)` w skrypcie; nie `wc -m`, bo w tym kontenerze locale POSIX liczy bajty, a na runnerze CI znaki [MEASURED: audyt 2]). Cel roboczy 12–20 KB. Powód: w trybie auto harness każe czytać pliki przez `cat`, a Bash pokazuje inline najwyżej ~30 000 znaków, powyżej Claude widzi 2 KB podglądu (O1 §2; próby P0, R0 [MEASURED, n=2]). Bajty ≥ znaki, więc limit jest bezpieczny niezależnie od tego, w czym liczy obcięcie (niezmierzone). Limit Read (25 000 tokenów, O0 §1 [CODE]) przy tym rozmiarze nie wiąże. Największe pliki po przeprowadzce: `docs-index` 18 688, `hooks` 18 269, `agents-and-workflows` 13 902 znaków [MEASURED: audyt 2], więc krok 0 przechodzi.

## 1. Docelowy układ plików (decyzja przed krokiem 0)

Zasada: **nazwa pliku = pytanie, na które odpowiada**; znaczniki przy faktach niosą „skąd wiemy", więc podział O0–O5 po typie dowodu jest zbędny.

| Nowy plik | Z czego (pełna tabela wierszowa powstaje w 0b jako `migration-map.tsv`) |
|---|---|
| `knowledge/CLAUDE.md` | mapa (generowana z `topics.json`): słowo kluczowe → plik, po linii, tak żeby `grep -i hook knowledge/CLAUDE.md` odpowiadał wprost; reguła znaczników; **jedyna** kopia listy otwartych sprzeczności (do kroku 4 lista zostaje też w głównym CLAUDE.md, bo jego edycja to osobna zgoda); ≤ 9 500 bajtów (limit wstrzyknięcia hooka 10 000 znaków na pole, O2 §A6) |
| `knowledge/STATE.md` | generowany **wyłącznie z wejść zacommitowanych** (nagłówki `As of:`, lista modeli, rozmiary plików); wartości żywe (`claude --version`, data, `llms.txt`) idą do raportu świeżości, nigdy do pliku, który CI porównuje (inaczej CI czerwienieje samo z siebie) |
| `context-window-and-read.md` | O0 §1, O1 §2 „Tool limits" (ile `cat` widzi Claude to pytanie o kontekst, nie o indeks) |
| `instructions-memory-skills.md` | O0 §2, O2 §C, O2 §D5, O4 §5 |
| `agents-and-workflows.md` | O0 §3, cztery punkty o definicji agenta z początku O0 §4, O2 §B, O3 §5–6 |
| `hooks.md` | O2 §A, punkty o hookach z O0 §4; pomiary P0–P4, R6, A–C jako [MEASURED] (w kroku 1, za zgodą) |
| `permissions-settings-automode.md` | O2 §D1–D4, D6, reszta O0 §4 |
| `models-effort-cost.md` | O0 §5, O5 §4, O5 §5 |
| `prompting-and-model-weaknesses.md` | O0 §6, O5 §1–3 |
| `cloud-environment.md` | O0 §7, część sieciowa O1 §3 |
| `headless-sdk-ci.md` | O3 §1–4, §7–10 |
| `mcp-and-plugins.md` | O4 §1–4, §6 |
| `design-rules.md` | O0 §8, model zagrożeń (§0.2); sekcja „Reviewing designs" z CLAUDE.md dopiero w kroku 4 (edycja CLAUDE.md) |
| `docs-index.md` | O1 §0, §1, reszta §2, §3 (bez części sieciowej), §4; skrzynki „New URLs" z O3–O5; sumy kontrolne pobranych stron w osobnym pliku maszynowym `docs-hashes.tsv`, nie tutaj (plik najbliżej limitu) |
| `recheck-and-conflicts.md` | O0 §9, O1 „Check again", O1 §5 (do skasowania w kroku 4), O2 §E, wszystkie „Verify live" i „Deltas" |
| TL;DR plików O1–O5 (19 punktów) i nagłówki plików (w tym akapit „Session reading budget" z O0 z faktem U5-31) | każdy ma wiersz w `migration-map.tsv`: cel albo jawne „drop" z powodem |
| `O0…O5-*.md` | **zaślepki**: tabela „stara § → nowy plik §" (87 sekcji); zostają do kroku 4 |

Nagłówek pliku treści (5 linii): tytuł, `Keywords:`, `Related:`, `As of:`, `Cap: 28000 bytes`. W kroku 0 `Keywords:`/`Related:` są ręcznymi zaślepkami; generator z kroku 2 je nadpisuje.

## 2. Krok 0a — strażnik, zaufane CI, ochrona gałęzi (na dzisiejszych O0–O5, zanim cokolwiek się ruszy)

- **H1 `scripts/kb_check.py`** z profilami per faza (`--phase`, bieżąca faza zapisana w `STATE.md`; CI uruchamia bieżącą). Faza 0: limit bajtów, nagłówki, poprawność odwołań `plik §x`, cele zaślepek, parser pomija bloki kodu (O1 l.166 i O2 §D5 mają nagłówki/punkty wewnątrz kodu). Faza 1a: brak sekcji-skrzynek, wersja w `STATE.md`. Faza 1 (po otagowaniu): znaczniki. Faza 1c: zakres modeli. Faza 2: pokrycie mapy, `Keywords:`, walidacja `topics.json`, diff sekcji generowanych. Tryby: `--tree HEAD` (bramka push, CI) i `--worktree` (pętla edycji). Każdy błąd = lista + kod ≠ 0.
- **H5 zaufane CI**: workflow na `pull_request_target`, czyli definicja workflow i strażnik pochodzą z `main`, a drzewo PR jest **danymi** (checkout do podkatalogu, `permissions: contents: read`, nic z PR nie jest wykonywane). Dodatkowo: PR, który zmienia pliki bramek (`.claude/**` poza `.claude/worktrees/`, `.github/**`, `scripts/kb_*`, `scripts/test_hooks.sh`, `knowledge/topics.json`) jest czerwony z listą plików — taki PR mergujesz tylko Ty, po przeczytaniu. Semantyka `pull_request_target` i „brakujący wymagany check blokuje merge" nie są w bazie: **zweryfikować na docs.github.com metodą z O1 przed startem i zapisać jako [SOURCE]** w `headless-sdk-ci.md`. Bootstrap: PR tworzący strażnika nie może być sprawdzony przez `main`, więc ten jeden przeglądasz ręcznie.
- **Branch protection** na `main`: wymagany check po nazwie joba, obejmująca administratora (repo publiczne [MEASURED: GitHub API, 2026-10-11], więc bez opłat; domyślnie admin jest wyłączony, O0 §7 [SOURCE: github/docs]). Skutek: przy zepsutym CI nic nie zmergujesz bez wyłączenia ochrony (§10 Q5). Przed włączeniem sonda tylko-do-odczytu: `gh api repos/asktheages1/ClaudeEXPERT --jq .permissions` (czy token sesji ma `admin`; jeśli tak, sesja mogłaby sama zmienić ochronę — zapis do §8).
- **Ścieżki zapisu na serwer** do zamknięcia regułami: MCP GitHub `push_files`, `create_or_update_file`, `delete_file`, `merge_pull_request`, `enable_pr_auto_merge`, `update_pull_request_branch`, `create_branch`, `actions_run_trigger` (bare name = narzędzie znika, O2 §D4) oraz `Bash(gh pr merge *)`, `Bash(gh api *)` (reguły tekstowe, miękkie; `gh` jest zainstalowane [MEASURED]). „Ty mergujesz" to dziś nawyk, nie mechanizm: sesja działa Twoim tokenem GitHub (O0 §7).
- `.gitignore` (dziś nie istnieje [MEASURED]): `.claude/kbgate/`, wyjścia sond, worktree.
- Skrypty sond i nagrane ładunki hooków (R6, A–C) zacommitowane w `tests/fixtures/`.

Gotowe: `kb_check.py --phase 0` = 0 na dzisiejszych plikach; CI zielone na gałęzi testowej i czerwone na gałęzi celowo zmieniającej `.github/workflows/`; branch protection widoczna w API. Model/effort: Opus 5.5 high; koszt ~5–10 USD [ASSUMPTION: praca skryptowa, bez agentów].

## 3. Krok 0b — przeprowadzka skryptem, bez zmiany brzmienia

- `migration-map.tsv` (stary plik, zakres linii, nowy plik, nowa sekcja; ok. 120 wierszy; wiersze per punkt tam, gdzie sekcja się dzieli: O0 §4, O1 §3). **Ty przeglądasz tabelę, nie 142 KB diffu.**
- `scripts/kb_migrate.py` czyta tabelę i tworzy nowe pliki oraz zaślepki. Model pisze tabelę, skrypt przenosi tekst.
- `scripts/kb_migrate_check.py`: każda znormalizowana linia niepusta i nienagłówkowa (punkty, wiersze tabel, akapity; bloki kodu porównywane jako całość) występuje w nowych plikach **dokładnie raz**, a **multizbiór wystąpień identyfikatorów faktów jest niezmieniony** (350 ID, 425 wystąpień, 67 ID powtórzonych, bo O0 §8 cytuje §1–§7 [MEASURED: audyt 2]; „każdy ID raz" z v2 było błędne).
- Routing przejściowy: po 0b główny CLAUDE.md nadal każe „O0 w całości", a O0 jest zaślepką. Dwie opcje (§10 Q5′): minimalna edycja routingu w CLAUDE.md w kroku 0b (Twoja zgoda) albo słabsza nawigacja do kroku 2.
- Gotowe: `kb_migrate_check.py` = 0; `kb_check.py --phase 0` = 0; CI zielone. Model/effort: Opus 5.5 medium (tabela) + skrypty; koszt ~3–6 USD [ASSUMPTION].

## 4. Krok 1 — aktualizacja treści (cztery sesje)

**1a. Changelog, skrzynki, otagowanie.** `CHANGELOG.md` (raw GitHub, O1 §2), wpisy 2.1.292–2.1.296 (372 punkty [MEASURED]) → `changelog-triage.tsv`: punkt → plik docelowy albo „nieistotne" + powód; skrypt sprawdza liczbę wierszy, cel ∈ lista plików ∪ {irrelevant}, powód niepusty. Zmieniony fakt **zastępuje** stary, znacznik `[CL 2.1.29x, data]`; do zweryfikowania w docs: `autoCompactWindow`, `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`; aktualizacja „Haiku 4.5 generuje tytuły" → `claude-haiku-5-5` [MEASURED: próby P3, A]. Skrzynki „Deltas"/„New URLs" do celów, sekcje usunięte. Jednorazowe otagowanie ~130 punktów (reguła 0.6). Gotowe: `kb_check.py --phase 1a` = 0 i `--phase 1` (znaczniki) = 0.

**1b. Brakujące strony** (`pages-1b.txt` zacommitowany; skrypt wymaga wiersza w `docs-index.md` ze statusem i datą oraz wiersza w `docs-hashes.tsv` z sha256 i rozmiarem dla każdego URL). CC: `hooks`, `hooks-guide` (O2 jest „documentation only", częściowo z wycinków; `*` przy wierszach PostCompact, ConfigChange), `routines`, `scheduled-tasks`, `sandbox-environments`, `checkpointing`, `large-codebases`, `troubleshooting`, `debug-your-config`, `plugins/mods/*`, `plugins/manifest-reference`, `plugins/loading`, `plugins/relevance`, `remote-control`, `desktop-scheduled-tasks`, `channels-reference`, `security-guidance`, `server-managed-settings`, `settings-example`; PL: `prompting-claude-fable-5-1`, `models/model-ids-and-versions`, `models/choosing-a-model`; **PL opcjonalnie** (tylko jeśli budujesz wprost na API; §10 Q7): `compaction-*` (5), `context-editing`, `memory-tool`, `tool-search-tool`, `mid-conversation-effort-example`, `cache-diagnostics`. Metoda z O1: `curl -sL <url>.md`, `grep -n`/Read z offsetem; do bazy fakty zmieniające decyzje, nie samouczki. Promocja pomiarów P0–P4, R6, A–C do `hooks.md` i findings 2026-10-06 (Glob/Grep) do odpowiedniego pliku. Gotowe: `kb_check.py --phase 1b` = 0.

**1c. Zakres modeli.** Znaczniki `[scope: …]` (reguła 0.5); usunięcie reszty; z listy sprzeczności zdjęcie „Haiku 4.5 retirement" i „Sonnet 5.5 default effort" jako „nie śledzimy" — **to edycja listy w głównym CLAUDE.md, osobna zgoda** (§10 Q3′). Gotowe: `--phase 1c` = 0. Recenzent (Opus 5.5 high) sprawdza 20 losowych faktów z 1a/1b — doradczo.

Koszt kroku 1 (Opus 5.5 high) [ASSUMPTION, per jednostka]: triage + skrzynki + otagowanie ≈ 1 sesja 5–10 USD; 13 plików do edycji po changelogu × 3,6–8,1 USD (findings 2026-10-08, ciężka sesja jednego pliku z recenzentem) = 47–105 USD; 22–33 stron × 0,5–1 USD = 11–33 USD; 1c ≈ 3–5 USD; recenzent 1c ≈ 3–5 USD. **Razem 70–160 USD**; bez opcjonalnych stron PL ok. 6–13 USD mniej. Czas maszyny 10–15 h. Podaj pułap; przy niższym tniemy 1b.

## 5. Krok 2 — mapa i drogowskazy bez hooków

Drogi obsłużone mechanizmem:
1. `ls knowledge/` → nazwy = tematy.
2. `grep -i <słowo> knowledge/CLAUDE.md` → linia „słowo → plik"; jako grep jednego pliku ładuje mapę. (`grep -r` po katalogu: zmierzyć hook `PostToolUse` na Bash zwracający `additionalContext` z liniami mapy dla szukanego słowa, O2 §A5 — to już hook, więc w 3a′.)
3. Dotknięcie pliku `knowledge/` → `knowledge/CLAUDE.md` wchodzi w całości (zagnieżdżony CLAUDE.md: O2 §D5 [SOURCE: CC memory.md]; `cat/head/tail/sed -n/grep` jednego pliku od 2.1.293 [CL]; O0 §2 [MEASURED: Read]; `cat` i Read agenta Explore: P4 [MEASURED, n=1]; `omitClaudeMd` do sprawdzenia w 3a, próg: 2/2).

Elementy: `knowledge/topics.json` (temat → regexy PL+EN z rdzeniami → ≤ 3 pliki w kolejności); `scripts/kb_build.py` (z `topics.json` i nagłówków buduje `STATE.md`, mapę, `Keywords:`; sekcje między `<!-- generated -->`); CI porównuje wynik generatora z commitem. Główny CLAUDE.md: tabela KB → dwie linie wskazujące `knowledge/CLAUDE.md` (osobna zgoda). Gotowe: `--phase 2` = 0; próba: 5 pytań do general-purpose i 5 do Explore, `jq` po transkryptach, pierwszy Read trafia w plik z `topics.json` ≥ 4/5 na typ. Koszt (Opus 5.5 high) ~5–8 USD.

## 6. Krok 3 — twarde mechanizmy (sześć podkroków, każdy mergowalny i odwracalny; blokada na końcu)

Fakty: hooki z ustawień projektu działają też w subagentach (O2 §A1 [SOURCE]; próby P1/R6 ładowały hooki przez `--settings`, nie z ustawień projektu, więc projektowa ścieżka do potwierdzenia w 3a); kod 2 blokuje i nie da się go nadpisać (O2 §A6); `Stop`/`SubagentStop` z kodem 2 nie pozwalają zakończyć (O2 §A5); `PreToolUse` `updatedInput` zastępuje całe wejście (O2 §A5). Rozwój hooków: na gałęzi deweloperskiej, testy z osobnego checkoutu (`git worktree add /tmp/kbtest`) przez `--settings <plik>` (O0 §4 [MEASURED]: hook z `--settings` działa w `-p`), bez dotykania chronionego `.claude/settings.json`; blokada (3f) wchodzi **po** zbudowaniu bramek, żebyś nie edytował ~8 skryptów ręcznie na GitHubie. Każdy hook zaczyna od `[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0` (O2 §A7), bo ten sam `.claude/settings.json` załaduje się na Twoim PC, gdzie nie ma `python3` (findings 2026-10-11). Stan bramek w `${CLAUDE_PROJECT_DIR}/.claude/kbgate/`, klucz = `transcript_path` (unikalny per proces; `session_id` dziedziczy zagnieżdżone `-p`, P1/A/C), ścieżki normalizowane do względnych wobec repo (agenci w worktree czytają `.claude/worktrees/<n>/knowledge/…`, a `${CLAUDE_PROJECT_DIR}` nie podąża za worktree, O2 §A7), zapisy jednoliniowe `O_APPEND`. Wyłącznik: zmienna w środowisku chmury albo „GitHub + nowa sesja".

**3a. Sondy** (n ≥ 2 każda, wynik do `findings.md`, zapis `[MEASURED]` z podaniem, że mierzyła sesja budująca): Read po `/compact` (czy `file_unchanged` się resetuje; jeśli nie, bramka po kompakcji byłaby spełniona pustym stubem); `updatedInput` na Agent (czy wymaga `permissionDecision: "allow"`, czy omija klasyfikator, O0 §3); `SubagentStop` dla agentów workflow; limit 8 blokad dla `SubagentStop` (O2 dokumentuje go tylko dla `Stop`); `omitClaudeMd` + zagnieżdżony CLAUDE.md; hooki z `.claude/settings.json` projektu w subagentach; `ConfigChange`: co znaczy „block"; czy `PostCompact` odpala się przy autokompakcji; `deny` vs `git rm/mv/checkout` na plikach bramek; powtórka A–C; wierność `stdout` dla pliku 27–28 KB i z kilkoma `\n` na końcu. Koszt ~2–4 USD.

**3a′. Wstrzykiwanie mapy** (dawne drogi 4–5 z kroku 2): `SubagentStart` → `additionalContext` z mapą do każdego agenta, także Explore i `omitClaudeMd` (dociera do Explore: R6a, C [MEASURED, n=2]); `SessionStart` (`startup`, `resume`, `compact`) → mapa (raport świeżości dopiero w 3e). Hook grep-r z §5. Wymaga Twojego commitu `.claude/settings.json`. Gotowe: `test_hooks.sh` zielone w CI; żywo n=2.

**3b. Bramki zapisu + logger bez bramki (baza pomiarowa).** (a) `PreToolUse`, `if: "Bash(git push *)"`, `onFailure: "block"` → `kb_check.py --tree HEAD`; błąd = kod 2 (próba B [MEASURED, n=1]: zły skrypt z `onFailure` zablokował `git push`, a `git -C . push` przeszedł, czyli handler jest wąski i fail-closed). (b) szeroki handler Bash bez `onFailure`, regex `\bgit\b.*\bpush\b`, fail-open, zaporą CI. (c) `Stop` przy zmianach w `knowledge/`: doradczy, przez `systemMessage` (stdout `Stop` idzie tylko do logu debug, O2 §A6). (d) **logger** `PostToolUse` na Read i Bash (definicja z 3c.2), **bez żadnej bramki**, przez ≥ 2 realne sesje: mierzy, jak często dziś sesja odpowiada na pytanie tematyczne bez pełnego czytania. To jedyny dowód, czy H4 jest warte kosztu. Gotowe: `test_hooks.sh` (fixtures z `tests/fixtures/`, asercje kodów wyjścia) zielone w CI; push z zepsutym nagłówkiem zablokowany n=2; raport bazowy w findings.

**3c. Wymuszone czytanie, sesja główna.**
1. `UserPromptSubmit`: dopasowanie promptu do `topics.json` (rdzenie PL+EN); wymagane pliki (≤ 3) pod `prompt_id`; stdout do kontekstu: „Required reading: … (Read, or exactly `cat <path>`); other tools are blocked until done".
2. Logger: **pełne czytanie decyduje odpowiedź narzędzia**: Read → `tool_response.type == "text"`, `file.startLine == 1`, `file.numLines >= file.totalLines` (pola z P1, A); Bash → komenda pasuje do `^\s*cat\s+(\S+)\s*$` (bez potoków, `;`, `&&`), ścieżka względem `cwd` z ładunku jest plikiem KB, brak `persistedOutputPath`, `interrupted == false`, `stdout.rstrip("\n") == file_text.rstrip("\n")` jako tekst UTF-8 (`stdout` nie ma końcowego `\n`: R6b, A [MEASURED, n=2]; porównanie sum kontrolnych z v2 nigdy by nie przeszło). Wpisy z `agent_id` nie liczą się dla sesji głównej (subagent ma ten sam `prompt_id`, P1). `file_unchanged` liczy się tylko po pełnym czytaniu po ostatniej kompakcji. Wpis zawiera sha256 pliku; inna suma przy sprawdzeniu = „zmieniony, nieprzeczytany".
3. `PostCompact`: unieważnia wpisy sprzed kompakcji.
4. `PreToolUse` „najpierw czytaj": przy dopasowanym prompcie blokuje (kod 2) narzędzia poza Read/`cat` wymaganych plików; **wyjątki na stałe**: `git add/commit/push` (żeby nigdy nie uwięzić pracy w sesji, która nie może wypchnąć; O0 §7: niewypchnięte pliki giną z VM), zdarzenia z `agent_id` (inaczej blokuje każdego działającego agenta), brak wymaganego pliku = przepuść z głośnym ostrzeżeniem. Fail-open przy awarii hooka (bez `onFailure`) — w §8.
5. `Stop`: dopasowanie także do `last_assistant_message` (P1); tematy obowiązują przez K=3 kolejne prompty; pułap wymaganych plików na sesję; brak pełnego czytania po ostatniej kompakcji → kod 2 „re-check your previous answer against <file> and state corrections"; **nigdy nie wychodzi wcześniej przy `stop_hook_active`**; limit 8 blokad logowany. Ponowne czytanie między kompakcjami: Read zwraca stub (P3), `cat` daje świeżą kopię blisko końca kontekstu (O0 §1: jakość spada z wypełnieniem, bez progu). Czy to pomaga, **niezmierzone**: sonda A/B w 3a (to samo pytanie K promptów po czytaniu, z wymuszonym `cat` i bez, ocena względem pliku, n ≥ 3 na ramię). Do wyniku: jedno pełne czytanie na epokę kompakcji (§10 Q2).
6. Opcja do zmierzenia: wstrzyknięcie dopasowanej sekcji wprost przez `additionalContext` (≤ 9 500 znaków) — treść w kontekście zanim Claude napisze cokolwiek; więcej tokenów na pytanie (§10 Q3).
Tryb: **najpierw log-only przez ≥ 2 sesje**, potem blokady. Gotowe: `test_hooks.sh`; żywo: pytanie o hooki bez czytania → `PreToolUse` blokuje Edit, `Stop` blokuje i nazywa plik; po kompakcji log wyzerowany; asercje `jq` po JSON z `-p`; n ≥ 2.

**3d. Wymuszone czytanie, agenci.** Tylko **lista** typów: `general-purpose` i nazwani agenci własni (nie `claude-code-guide` — agent Haiku do docs na żywo; nie agenci bez Read/Bash; nie Explore). `PreToolUse` na Agent: kopia **całego** `tool_input`, zmiana tylko `prompt` (dopisana linia lektury; miękka). `SubagentStop`: czyta `agent_transcript_path` (przy `SubagentStop` zawierał pierwszą wiadomość i Read: P2, R6 [MEASURED, n=2]; zapis asynchroniczny, O2 §A4 — stąd n ≥ 2 w 3a), dopasowuje tematy do pierwszej wiadomości, sprawdza log pod `agent_id`; brak → kod 2. Obsługa `stop_hook_active` jak w `Stop`; limit blokad dla `SubagentStop` z 3a. Log-only przez ≥ 2 sesje, potem blokada. Gotowe: `test_hooks.sh`; żywo n ≥ 2.

**3e. Świeżość.** `scripts/kb_freshness.sh`: `claude --version` vs `STATE.md`, wersje i punkty changelogu od tej pory, linki `llms.txt` vs zapisane, dni od edycji; `curl --max-time`, wynik cache'owany raz dziennie, pomijany przy zmiennej testowej; z `SessionStart` do kontekstu — miękki. Gotowe: skrypt zwraca 0, wyjście zawiera linię wersji ze `STATE.md`, parser testowany fixture'em. Routine tygodniowa (jedna stała gałąź/PR aktualizowany co tydzień, nie nowa gałąź co tydzień; §10 Q8): po 3f, na stronach `routines`/`scheduled-tasks` z 1b; zakładasz sam; koszt ~2–5 USD/tydzień [ASSUMPTION: jedna sesja Opus 5.5 medium].

**3f. Blokada** (ostatnia): `deny` na `Edit(/.claude/hooks/**)`, `Edit(/.claude/settings.json)`, `Edit(/.claude/settings.local.json)`, `Edit(/scripts/kb_*)`, `Edit(/scripts/test_hooks.sh)`, `Edit(/.github/workflows/**)`, `Edit(/knowledge/topics.json)` (plik konfigurujący bramki, edytowalny w zwykłej pracy — model mógłby zwęzić bramkę w trakcie; O0 §6 cytuje badania o ukrywaniu niewykonania); nie `Edit(/.claude/**)` w całości (worktree agentów, findings 2026-10-11 [ASSUMPTION: dopasowanie niezmierzone]); hook `ConfigChange` na `project_settings`/`local_settings` (semantyka z 3a). Od tej chwili zmiany bramek tylko PR-em, który CI oznacza na czerwono, a Ty przeglądasz (§10 Q4′).

Koszt kroku 3 (Opus 5.5 high; sondy na Opus 5.5 low, 0,1–0,26 USD każda [MEASURED: 12 sond z recenzji]): 3a 2–4, 3a′ 3–5, 3b 5–8, 3c 6–10, 3d 4–7, 3e 2–4, 3f 1–2 → **23–40 USD**. Koszt stały po wdrożeniu: mapa ≈ 3,5 tys. tokenów [ASSUMPTION: 2,7 B/token] przy starcie sesji, przy pierwszym dotknięciu `knowledge/` i w każdym agencie; plus wymuszone czytania — mierzone w 3b/3c.

## 7. Krok 4 — CLAUDE.md (każda zmiana = osobna zgoda; klasyfikator może odrzucić edycję jako „Self-Modification": findings 2026-10-06, 2 odmowy — zapis stałej zgody na merge i fast-forward `main` — przy 3 zwykłych edycjach przepuszczonych)

- Tabela KB, znaczniki, sprzeczności, „Freshness", „Live lookups", „Reviewing designs" → `knowledge/CLAUDE.md`, `docs-index.md`, `design-rules.md`. Usunąć „O0 w całości raz na sesję". Dodać jednostkę zgody (§0.4) i linię „po zmianie w `knowledge/` uruchom `kb_build.py`, potem `kb_check.py --worktree`". Skasować zaślepki i O1 §5.
- Gotowe: najpierw ponowny pomiar zacommitowanego CLAUDE.md licznikiem Read (baza 3 752 tokenów z findings była mierzona na kopii 9 881 B, a plik w repo ma 9 774 B [MEASURED: audyt 2]); cel ≤ 2 500 tokenów; metryka właściwa: **łączne tokeny wstrzykiwane na starcie** sesji głównej i agenta general-purpose, przed i po; skrypt porównuje zapisane liczby. Działa od następnej sesji (O0 §2). Koszt ~2–3 USD.

## 8. Co zostaje miękkie (pełna lista)

- Linia lektury w prompcie agenta; raport świeżości; komunikat `Stop` przy brudnym `knowledge/`; bramki w trybie log-only.
- Fałszowanie logu bramek przez `python3 -c` (deny nie widzi Pythona, O0 §4); CI nie widzi logu w `.gitignore`.
- Zagnieżdżone `claude -p` z korzenia repo z `--settings '{"disableAllHooks": true}'`, `--setting-sources user` albo ze zmienną wyłącznika: zero bramek.
- Edycja plików bramek z drugiego checkoutu/worktree (reguły `deny` są zakotwiczone w żywym checkoucie, O2 §D4; agent w worktree omija też klasyfikator, O0 §4) — łapie CI z `main`.
- Reguły tekstowe na `gh`, `git -C . push`, skrypty w pliku — łapie CI.
- Token sesji z prawami `admin` mógłby zmienić branch protection (do sprawdzenia w 0a).
- Limit 8 blokad `Stop` (i prawdopodobnie `SubagentStop`); bramka „najpierw czytaj" i logger fail-open przy awarii hooka; brakujący wymagany plik = przepuść.
- Dopasowanie tematów leksykalne (prompt bez słowa kluczowego jest nieobjęty); `UserPromptSubmit` odpala się też na turach automatycznych (raporty agentów w tle, `/loop`).
- Sesje z kilkoma repozytoriami i `-p` spoza korzenia: zero hooków i reguł (O0 §4, §7). Agenci workflow (prompty jako literały w skrypcie, bez hooka). Explore niegatowany. „Przeczytał" ≠ „zrozumiał". Brak wymuszonego ponownego czytania między kompakcjami do wyniku sondy A/B.
- Routine: zależy od założenia i od tego, czy sesja zrobi wpis.

## 9. Kto co robi i ile to kosztuje

Ty: zatwierdzasz `migration-map.tsv` i triage; commitujesz/zatwierdzasz `.claude/settings.json` (3a′, 3b, 3f); włączasz branch protection; ustawiasz zmienną wyłącznika; zakładasz Routine; mergujesz; każda zmiana CLAUDE.md osobno. Ja: reszta, po Twoim „tak" na krok.

| Krok | Model / effort | Jednorazowo [ASSUMPTION] |
|---|---|---|
| 0a | Opus 5.5 high | 5–10 USD |
| 0b | Opus 5.5 medium | 3–6 |
| 1a–1c | Opus 5.5 high | 70–160 (bez opcjonalnych PL: −6…−13) |
| 2 | Opus 5.5 high | 5–8 |
| 3a–3f | Opus 5.5 high, sondy low | 23–40 |
| 4 | Opus 5.5 medium | 2–3 |
| recenzje planu dotąd | Opus xhigh, Fable xhigh, Opus max | ~241k + 224k + 332k tokenów agentów + 1,3 USD sond; przy cenach O0 §5 szacunkowo 8–15 USD |
| recenzje kolejnych kroków (jeśli chcesz) | Opus 5.5 high, 1 na krok | 3–8 na krok |
| **Razem** | | **~110–230 USD** + recenzje |
| Stałe | | Routine 2–5 USD/tydzień; mapa ~3,5k tokenów na sesję i na agenta; wymuszone czytania — do zmierzenia |

Fable 5.1 kosztuje 2,5× Opus (O0 §5); wykonanie na Fable tylko, jeśli tak zdecydujesz (§10 Q9).

## 10. Pytania do decyzji

1. Układ z §1, krok 0a/0b (strażnik i CI najpierw, przeprowadzka skryptem z tabeli, którą przeglądasz) — tak / nie / zmiany?
2. Ponowne czytanie między kompakcjami: „raz na epokę kompakcji" (projekt) czy wymuszony `cat` co K promptów? Proponuję najpierw sondę A/B z 3a.
3. Dwie osobne decyzje: (a) bramka `PreToolUse` „najpierw czytaj" (blokuje narzędzia poza czytaniem i gitem) — tak?; (b) test wstrzykiwania sekcji wprost do promptu (więcej tokenów, zero możliwości pominięcia) — tak?
3′. Zdjęcie dwóch sprzeczności z listy w CLAUDE.md w 1c (to edycja CLAUDE.md przed krokiem 4) — tak?
4′. Model pracy nad bramkami: Claude buduje i testuje je z worktree na gałęzi dev, a po 3f każda zmiana bramek idzie PR-em, który CI oznacza na czerwono i który tylko Ty mergujesz — akceptujesz?
5. Branch protection obejmująca Ciebie: przy zepsutym CI lub awarii GitHub Actions nic nie zmergujesz bez wyłączenia ochrony — akceptujesz?
5′. Routing przejściowy po 0b: minimalna edycja CLAUDE.md teraz czy słabsza nawigacja do kroku 2?
6. Jednostka zgody na KB (§0.4): Twój merge PR kroku po przeczytaniu triage = „tak" — zgoda?
7. 1b: pobierać opcjonalne strony PL o API (kompakcja po stronie API, memory tool, context editing…)? Tylko jeśli budujesz wprost na API.
8. Routine: po 3f, jedna stała gałąź aktualizowana co tydzień — tak?
9. Model wykonania: Opus 5.5 high (tabela §9) czy Fable 5.1 (2,5×)? Pułap budżetu na krok 1 i na całość?
10. Dokumenty planu i recenzji w repo po polsku (jak dotąd) czy po angielsku?
11. Wyłącznik awaryjny: zmienna w środowisku chmury czy „GitHub + nowa sesja"?

## 11. Audyt 2: co przyjęto, co odrzucono

Przyjęto (z obu audytów): krok 0 na 0a/0b z profilami faz i przeprowadzką skryptem; niezmiennik „każda linia raz + multizbiór ID bez zmian"; TL;DR i nagłówki w tabeli; `pull_request_target` + czerwone CI na plikach bramek + weryfikacja semantyki na docs.github.com + bootstrap ręczny; pełna lista ścieżek zapisu na serwer (MCP, `gh`); sonda uprawnień tokena; definicja pełnego `cat` po `rstrip("\n")` i dokładny wzorzec komendy; limit w bajtach; `transcript_path` jako klucz logu; normalizacja ścieżek worktree; wyjątki dla `git add/commit/push`, `agent_id`, brakującego pliku; lista typów agentów; blokada jako ostatni podkrok; `topics.json` i `scripts/kb_*` pod ochroną; model zagrożeń; `CLAUDE_CODE_REMOTE`; `.gitignore`; fixtures w repo; log-only jako baza pomiarowa; sonda A/B ponownego czytania; `STATE.md` tylko z wejść zacommitowanych; hashy stron w osobnym pliku; O1 §2 „Tool limits" do pliku o kontekście; `systemMessage` dla doradczego `Stop`; kopia całego `tool_input`; jedna kopia listy sprzeczności; model/effort per krok; koszty per jednostka, jednorazowe i stałe osobno, recenzje policzone; kryteria 3e i kroku 4 jako komendy; `jq` w testach żywych; `resume` w SessionStart; cache i timeout w freshness; poprawki cytatów (O0 §2 → O2 §D5 [SOURCE]; worktree [ASSUMPTION]; scratchpad zagnieżdżonego `-p` liczony z jego własnego cwd [MEASURED: A, C, n=2]; P1 przez `--settings`; klucze Agent ze schematu; 5-plikowe zastrzeżenie przy kompakcji; druga odmowa z 2026-10-06 = fast-forward; baza tokenów CLAUDE.md mierzona na innej kopii; `transcript_path` asynchroniczny); poprawki wpisu „Hook payload probes" w `findings.md`; hook `PostToolUse` dla `grep -r` jako pomiar.

Odrzucono / odłożono: (1) jednostka limitu `wc -c` w shellu vs `len(text)` w Pythonie — audyty różnią się; wybrano bajty w skrypcie (`len(bytes)`), bo bajty ≥ znaki, więc bezpieczne niezależnie od jednostki obcięcia; (2) „rozbić §9 Q3 na dwa" — przyjęte; (3) HMAC na logu — odrzucone zgodnie z audytem (hooki i Bash dzielą środowisko, klucz widoczny); (4) sekcje „Verify live" do planu — zostają w `recheck-and-conflicts.md`, nie są zadaniem tego planu; (5) weryfikacja „repo publiczne" — audytorzy nie mieli sieci; pomiar z tej sesji (API GitHub) stoi.
