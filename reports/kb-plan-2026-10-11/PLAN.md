# Plan przebudowy bazy wiedzy (KB) — wersja 1, 2026-10-11

Stan wyjściowy: `findings.md` wpis 2026-10-11 „KB navigation audit" (pomiary: brak linków między plikami, brak mapy dla agentów, brak automatu świeżości, 372 wpisy changelogu nieujęte, ~25 istotnych stron docs nieujętych, dwa katalogi poza mapą).

Język dokumentu: polski, bo czyta go właściciel i plan będzie się zmieniał. Wszystko, co z tego planu trafi do `knowledge/`, skryptów i hooków, będzie po angielsku (reguła CLAUDE.md).

## 0. Zasady, które obowiązują w każdym kroku

1. **Twarde > miękkie.** Gdzie da się coś wymusić mechanizmem (reguła `deny`, hook z kodem wyjścia 2, skrypt w CI na serwerze), nie piszemy prośby do modelu. Prośba zostaje tylko tam, gdzie mechanizmu nie ma, i wtedy jest wprost oznaczona jako miękka (§6 tego planu). Podstawa: O0 §8 „Hard is only what Claude Code or the server enforces" [SOURCE: CC memory.md, hooks.md, permissions.md].
2. **Jeden krok na raz.** Każdy krok to osobna sesja (lub kilka), z własnym kryterium „gotowe", sprawdzanym skryptem, nie samoopisem. Kolejny krok zaczyna się po Twoim „tak".
3. **Tylko dwa najlepsze modele.** Treść o zachowaniu, promptowaniu i effort dotyczy wyłącznie Opus 5.5 i Fable 5.1 (dziś). Pozostałe modele zostają w bazie jedynie jako wiersz w tabeli cen i identyfikatorów oraz jako pułapki (np. „`claude -p` bez `--model` leci na Sonnet 5.5", O0 §5 [MEASURED]). Lista „dwa najlepsze" jest zapisana w jednym pliku stanu i skrypt sprawdza, czy baza nie ma sekcji o innych modelach.
4. **Każdy fakt ma znacznik dowodu** (jak dotąd: `[MEASURED]`, `[SOURCE: URL, data]`, `[CL]`, `[ASSUMPTION]`). Skrypt sprawdza, że każdy punkt listy w `knowledge/` ma znacznik.
5. **Limit pliku = tokeny, nie bajty.** Twarda granica: ≤ 22 500 tokenów licznika Read (limit Read to 25 000 tokenów na wywołanie, O0 §1 [CODE]) i ≤ 40 KB jako prosty zamiennik w skrypcie. Cel roboczy: ≤ 20 KB na plik tematyczny. Powód: krok 3 wymusza czytanie całych plików; przy 20 KB (~8 tys. tokenów) wymuszone czytanie trzech plików kosztuje ~25 tys. tokenów, przy 40 KB dwa razy tyle. Dodatkowy argument: po kompakcji (automatycznym skróceniu rozmowy) wraca tylko treść plików ≤ 5 000 tokenów, większe wracają jako sama ścieżka (O0 §1 [SOURCE: CC context-window.md]), więc każdy plik > ~12 KB i tak trzeba czytać ponownie. Nowa opcja `allow_large` w Read (CC 2.1.296 [CL]) pozwala czytać większe pliki na raz, ale nie zmniejsza kosztu w tokenach, więc nie zmienia tej decyzji.

## 1. Decyzja przed krokiem 1: docelowy układ plików

Zmieniam Twoją kolejność w jednym punkcie i mówię dlaczego: jeśli krok 1 (treść) wpisze nowe fakty do dzisiejszych plików O0–O5, a krok 2 (nazwy i mapa) je potnie i przeniesie, każdy fakt będzie przenoszony dwa razy. Dlatego proponuję ustalić **teraz, w tym planie, listę docelowych plików**, a krok 1 od razu pisać do nich. Krok 2 dodaje wtedy tylko mapę, drogowskazy i generator, nie przenosi treści.

Zasada nazewnictwa: **nazwa pliku = pytanie, na które odpowiada**. Leniwe `ls knowledge/` albo `grep -ril hook knowledge/` ma trafić w dobry plik bez mapy. Dzisiejszy podział O0–O5 jest według „skąd wiemy" (pomiar / składnia / streszczenie docs), czego nikt nie zgadnie; znaczniki dowodu przy każdym fakcie i tak niosą tę informację, więc podział po typie dowodu jest zbędny.

| Nowy plik | Z czego powstaje | Szac. rozmiar |
|---|---|---|
| `knowledge/CLAUDE.md` | mapa: temat → plik, reguła znaczników, lista otwartych sprzeczności, tabela starych nazw (O0 §4 → nowy plik) | ≤ 60 linii |
| `knowledge/STATE.md` | **generowany**: wersja CC, data, liczba linków i suma kontrolna `llms.txt`, lista plików z rozmiarem i tokenami, lista „dwa najlepsze modele" | ≤ 40 linii |
| `context-window-and-read.md` | O0 §1 | ~10 KB |
| `instructions-memory-skills.md` | O0 §2, O2 §C, O2 §D5, O4 §5 | ~15 KB |
| `agents-and-workflows.md` | O0 §3, O2 §B, O3 §5–6 | ~18 KB |
| `hooks.md` | O2 §A, O0 §4 (część o hookach) | ~17 KB |
| `permissions-settings-automode.md` | O2 §D1–D4, O0 §4 (reszta) | ~14 KB |
| `models-effort-cost.md` | O0 §5, O5 §4 (cache, ceny); tylko dwa modele + tabela ID/cen | ~10 KB |
| `prompting-and-model-weaknesses.md` | O0 §6, O5 §1–3 | ~12 KB |
| `cloud-environment.md` | O0 §7, O1 §3 (sieć w chmurze) | ~8 KB |
| `headless-sdk-ci.md` | O3 §1–4, §7–10 | ~12 KB |
| `mcp-and-plugins.md` | O4 §1–4, §6 + nowe strony (mods, manifest) | ~12 KB |
| `design-rules.md` | O0 §8 + sekcja „Reviewing designs" z CLAUDE.md | ~6 KB |
| `docs-index.md` | O1 §1–2 + adresy ze skrzynek „New URLs" w O3–O5 | ~20 KB |
| `recheck-and-conflicts.md` | O0 §9, O1 „Check again", wszystkie „Verify live", „Deltas", lista sprzeczności | ~8 KB |

Razem 13 plików treści + mapa + stan. Każdy plik ma stały 5-liniowy nagłówek: tytuł, `Keywords:` (do grep), `Related:` (pliki sąsiednie), `As of:` (wersja CC i data), `Budget:` (bajty/tokeny). Nagłówek sprawdza skrypt. Numeracja sekcji wewnątrz pliku zostaje (cytowanie `hooks.md §A6`).

Do decyzji: akceptujesz ten układ? Jeśli nie, krok 1 pisze do dzisiejszych O0–O5, a przenosiny robi krok 2 (koszt: druga przeprowadzka).

## 2. Krok 1 — aktualizacja treści i pobranie braków

Podzielony na trzy podkroki, każdy to jedna sesja z własnym „gotowe".

**1a. Changelog i skrzynki.**
- Pobrać `CHANGELOG.md` (raw GitHub, O1 §2), wyciąć wpisy 2.1.292–2.1.296 (372 punkty [MEASURED 2026-10-11]), odfiltrować do tematów bazy, każdy zmieniony fakt zastąpić (nie dopisać obok) ze znacznikiem `[CL 2.1.29x, data]`. Już znane: parametr `effort` w Agent (2.1.292), reguły ścieżek na `cat/sed/grep` (2.1.293), `onFailure: "block"` dla hooków (2.1.295), `autoCompactWindow` w agentach, `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`, `allow_large` w Read (2.1.296).
- Przenieść zawartość sekcji „Deltas vs …" i „New URLs for O1" z O3–O5 do plików docelowych; sekcje usunąć. Sprzeczności, których docs już nie rozstrzygają, idą do `recheck-and-conflicts.md`.
- Gotowe, gdy: skrypt nie znajduje sekcji „Deltas"/„New URLs"; `STATE.md` ma wersję 2.1.296; każdy nowy wpis ma znacznik.

**1b. Brakujące strony.** Lista z audytu (findings 2026-10-11), tylko to, co dotyczy Twoich zastosowań:
- CC: `sandbox-environments` (najważniejsze: O0 §8 nazywa sandbox jedyną twardą granicą dla komend, a baza nie ma o nim nic), `checkpointing`, `large-codebases`, `troubleshooting`, `debug-your-config`, `plugins/mods/*`, `plugins/manifest-reference`, `plugins/loading`, `plugins/relevance`, `remote-control`, `desktop-scheduled-tasks`, `channels-reference`, `security-guidance`, `server-managed-settings`, `settings-example`; `common-workflows` tylko przejrzeć.
- PL: `prompting-claude-fable-5-1` (baza cytuje tylko starszą stronę Fable 5), `models/model-ids-and-versions`, `models/choosing-a-model`, pięć stron `compaction-*`, `context-editing`, `memory-tool`, `tool-search-tool`, `mid-conversation-effort-example`, `cache-diagnostics`.
- Metoda z O1: `curl -sL <url>.md` do pliku roboczego, potem `grep -n`/Read z offsetem; WebFetch tylko do orientacji. Do bazy trafiają fakty zmieniające decyzje (limity, domyślne wartości, pułapki), nie samouczki. Każdy ze znacznikiem `[SOURCE: URL, data]`; status adresu w `docs-index.md`.
- Gotowe, gdy: każdy adres z listy ma wpis w `docs-index.md` ze statusem ✅/❌ i datą, a jego fakty są w pliku tematycznym albo jest zapisane „nic istotnego dla nas" z powodem.

**1c. Zakres modeli („dwa najlepsze").**
- `STATE.md` dostaje listę: `claude-opus-5-5`, `claude-fable-5-1`. Skrypt flaguje w `knowledge/` nagłówki i sekcje o innych modelach; dozwolone są tylko wiersze tabeli ID/cen i wpisy oznaczone jako pułapka.
- Usunąć szczegóły o Haiku 4.5/5.5 i Sonnet 5.5 poza tabelą i pułapkami; usunąć konflikt „Haiku 4.5 retirement" z listy sprzeczności (poza zakresem).
- Reguła na przyszłość: gdy pojawi się nowszy model, `STATE.md` zmienia listę, skrypt świeżości (krok 3) to wykrywa po stronie `models/overview`.
- Gotowe, gdy: skrypt zakresu modeli przechodzi; recenzent (jeden agent, Opus 5.5, effort high) sprawdza 20 losowych faktów z nowych plików przeciwko źródłom i zgłasza ≤ 2 błędy, które poprawiamy.

Koszt kroku 1 [ASSUMPTION, na podstawie findings 2026-10-08: ~5,7 USD za ciężką sesję jednego pliku z recenzentem; 2026-10-11: agent Opus max 318 tys. tokenów]: 3 sesje, łącznie ~15–30 USD, ~4–6 h czasu maszyny.

## 3. Krok 2 — nazwy, mapa, drogowskazy („każda droga na skróty prowadzi w dobre miejsce")

Cel: niezależnie od tego, jak Claude lub agent zacznie (`ls`, `grep`, czytanie jednego pliku, odpalenie agenta, pytanie z tematem), trafia na mapę i do właściwego pliku. Pięć dróg, każda obsłużona:

1. **`ls knowledge/`** → nazwy plików = tematy (§1).
2. **`grep -ril <słowo> knowledge/`** → każdy plik ma linię `Keywords:` z synonimami (effort, thinking, xhigh…), więc właściwy plik wygrywa w wynikach.
3. **Czytanie dowolnego pliku z `knowledge/`** → automatyczne wstrzyknięcie mapy. Mechanizm: `knowledge/CLAUDE.md` (zagnieżdżony CLAUDE.md) wchodzi do kontekstu w całości przy Read pliku z tego katalogu, od 2.1.288 także przy Write/Edit, od 2.1.293 także przy `cat`, `head`, `tail`, `sed -n`, `grep` na jednym pliku w Bash (O0 §2 [SOURCE: CC memory.md] [MEASURED: Read 2 linii → nested_memory 18,5 KB] [CL 2.1.293]). To jest mechanizm Claude Code, nie prośba. Do sprawdzenia tanią próbą: czy wstrzyknięcie działa też dla agentów Explore i z `omitClaudeMd` (O0 §2: nie dostają głównego CLAUDE.md; zagnieżdżony — niezmierzone [ASSUMPTION]).
4. **Pytanie z tematem w prompcie** → hook `UserPromptSubmit` (krok 3) dopisuje do kontekstu „lektura obowiązkowa: plik X", a hook `Stop` sprawdza, czy przeczytany.
5. **Odpalenie agenta** → hook `PreToolUse` na narzędziu Agent dopisuje do promptu agenta obowiązkową lekturę (krok 3).

Elementy do zrobienia:
- `knowledge/topics.json`: jedno źródło prawdy: temat → słowa kluczowe (regex) → pliki. Z niego **generowane** są: sekcja mapy w `knowledge/CLAUDE.md`, linie `Keywords:` do sprawdzenia, i reguły hooków z kroku 3. Dzięki temu mapa i hooki nie mogą się rozjechać.
- Generator `scripts/kb_build.py`: z plików i `topics.json` buduje `STATE.md` i sekcję mapy. Części generowane są oznaczone znacznikami `<!-- generated -->`, ręczna zostaje tylko lista sprzeczności i tabela starych nazw.
- `reports/README.md` i `migration-kit/README.md`: po jednej linii na plik; oba katalogi wpisane do mapy jako „materiały właściciela, nie fakty bazy".
- Główny `CLAUDE.md`: tabela KB zastąpiona dwoma liniami wskazującymi `knowledge/CLAUDE.md` (pełna przeróbka w kroku 4).
- Stare cytaty `O0 §4` w `findings.md` i `reports/`: tabela przejścia w mapie; nie poprawiamy historii.

Gotowe, gdy: (a) `kb_check.py` potwierdza, że każdy plik w `knowledge/`, `reports/`, `migration-kit/` jest w mapie, a każde `plik §x` w mapie istnieje; (b) próba: 5 pytań tematycznych do agenta general-purpose i 5 do Explore, mierzymy, czy pierwszy Read trafia w plik z `topics.json` (n=5 na typ, wynik `[MEASURED]`); (c) próba wstrzyknięcia zagnieżdżonego CLAUDE.md dla Explore/omitClaudeMd (n=2).

Koszt: 1 sesja, ~3–6 USD [ASSUMPTION].

## 4. Krok 3 — twarde mechanizmy

Wszystko w repo: `.claude/settings.json` (hooki), `scripts/`, `.github/workflows/`. Fakty o hookach: O2 §A [SOURCE: CC hooks.md]. Kluczowe: hooki z ustawień projektu **działają też wewnątrz subagentów** (O2 §A1), kod wyjścia 2 blokuje i nie da się go nadpisać (O2 §A6), hook `Stop` z kodem 2 nie pozwala zakończyć tury (O2 §A5), `SubagentStop` tak samo dla agenta, `PreToolUse` może podmienić wejście narzędzia (`updatedInput`, O2 §A5).

**H1. Strażnik `scripts/kb_check.py`** (deterministyczny, bez modelu). Sprawdza: budżety plików (bajty; tokeny szacowane z ostatniego pomiaru B/token zapisanego w `STATE.md`), nagłówki, pokrycie mapy, poprawność odwołań `§`, brak sekcji-skrzynek, znacznik dowodu przy każdym punkcie, zakres modeli, zgodność wersji w `STATE.md` z nagłówkami. Wynik: lista błędów, kod wyjścia ≠ 0.

**H2. Strażnik świeżości `scripts/kb_freshness.sh`** (bez modelu). Wypisuje: `claude --version` vs wersja w `STATE.md`, liczbę wersji i punktów changelogu od tej pory, liczbę linków w `llms.txt` vs zapisana, dni od ostatniej edycji każdego pliku. Odpalany przez hook `SessionStart` (matcher `startup` i `compact`), wynik idzie do kontekstu (O2 §A5: stdout SessionStart trafia do kontekstu). Po kompakcji ten sam hook wstrzykuje mapę ponownie (O0 §6: SessionStart z matcherem `compact` to udokumentowany sposób na odzyskanie kontekstu [SOURCE: CC hooks-guide.md]).

**H3. Bramki na zapis:**
- `PreToolUse` na `Bash`: skrypt hooka czyta `tool_input.command`; jeśli pasuje do `\bgit\b.*\bpush\b`, uruchamia `kb_check.py`; błąd → kod 2 → push zablokowany, powód trafia do Claude. Dopasowanie w skrypcie, nie w regule `if`, żeby `git -C . push` też łapać (O0 §4: reguły tekstowe omija `git -C`). Nadal do obejścia skryptem w pliku; zaporą ostateczną jest CI (H5).
- `Stop`: jeśli `git status` pokazuje zmiany w `knowledge/`, uruchamia `kb_check.py`; błąd → kod 2 z listą (tura nie może się skończyć z zepsutą bazą). Z `stop_hook_active` i limitem 8 blokad z rzędu (O2 §A5).
- `onFailure: "block"` na obu (2.1.295 [CL]): zepsuty skrypt blokuje zamiast przepuszczać. Tylko na tych dwóch wąskich bramkach, nie na hookach informacyjnych (findings 2026-10-11: hook na każde Bash z `onFailure: block` potrafi zablokować nawet naprawę).

**H4. Wymuszone czytanie (odpowiedź na Twoje pytanie o „dopiero czytałem, pamiętam").** Łańcuch pięciu hooków, wszystkie deterministyczne:
1. `UserPromptSubmit`: dopasowuje prompt do `topics.json`; listę wymaganych plików zapisuje do pliku stanu w `scratchpad_dir` (pole wejścia hooka, O2 §A4) pod `prompt_id`, i wypisuje na stdout „Required reading: … (full Read, no offset/limit); the Stop hook verifies" (stdout tego zdarzenia trafia do kontekstu). Limit czasu 30 s (O2 §A2).
2. `PostToolUse` na `Read` i `Bash`: loguje każde czytanie pliku z `knowledge/` (ścieżka, czy pełne = bez offset/limit albo `cat` całego pliku, `prompt_id`, `agent_id` jeśli subagent, czas). Log w `scratchpad_dir`. To zastępuje czytanie transkryptu, który „jest zapisywany asynchronicznie i może nie zawierać bieżącej tury" (O2 §A4).
3. `PostCompact`: unieważnia wpisy logu sprzed kompakcji (treść plików > 5 000 tokenów po kompakcji nie wraca, O0 §1).
4. `Stop`: dla bieżącego `prompt_id` porównuje wymagane pliki z logiem; brak pełnego czytania **po ostatniej kompakcji i nie dawniej niż N tur** → kod 2 z powodem „przeczytaj w całości: …". Claude czyta, kończy turę. N jest parametrem w `topics.json`.
5. `PreToolUse` na `Agent` i `SubagentStop`: hook czyta `tool_input.prompt` agenta, dopasowuje tematy, przez `updatedInput` **dopisuje do promptu** linię „Read in full before anything else: …" (agent nie ma wyboru, bo linia jest w jego pierwszej wiadomości) i zapisuje wymagania pod identyfikatorem spawnu. `SubagentStop` sprawdza log dla `agent_id`; brak → kod 2, agent nie kończy. Powiązanie spawn → `agent_id`: `SubagentStart` daje `agent_id` i `agent_type`, nie prompt (O2 §A5), więc wiązanie po kolejności/czasie [ASSUMPTION, do zmierzenia]; zapasowo `SubagentStop` dostaje `agent_transcript_path` i hook sprawdza w transkrypcie obecność dopisanej linii i wywołań Read.

Parametr N (ile tur „ważne" jest czytanie): to decyzja kosztowa. Każde ponowne czytanie dodaje ~8 tys. tokenów do okna (cache obniża koszt w USD, nie rozmiar okna). Twoja obserwacja („95 % przypadków nie pamięta") przemawia za małym N. Propozycja startowa: N = 10 tur, plus zawsze po kompakcji; po dwóch sesjach mierzymy wzrost okna i liczbę blokad `Stop` i korygujemy. Explore nie jest bramkowany (czyta wycinki z założenia, O0 §2); general-purpose i agenci własni są.

**H5. CI na serwerze (`.github/workflows/kb-check.yml`)**: `kb_check.py` na każdym pushu i PR; bez modelu, darmowe minuty. To jedyna kontrola, której sesja nie obejdzie (O0 §8). Czerwony znaczek widzisz przy merge. Blokada merge wymaga branch protection; w repo prywatnym to płatny plan (O0 §7 [SOURCE: github/docs]); do sprawdzenia, czy repo jest publiczne.

**H6. Routine tygodniowa** (zaplanowane zadanie na koncie; zakładasz sam): świeża sesja, `kb_freshness.sh`, przegląd nowych wpisów changelogu i `whats-new`, wpis „co zmienić gdzie" do `findings.md`, push gałęzi. Nie jest twarda, ale bez niej świeżość zależy od tego, czy ktoś otworzy sesję.

Ograniczenia, których hooki nie pokonają (uczciwie): hooki z repo nie ładują się w sesji z kilkoma repozytoriami ani w `claude -p` uruchomionym poza korzeniem (O0 §4, §7); `.claude/settings.json` to ścieżka chroniona, w trybie auto zawsze trafia do klasyfikatora, który już raz zablokował Claude'owi edycję własnych instrukcji (findings 2026-10-06, n=2), więc plik hooków dodajesz lub zatwierdzasz sam; agenci z narzędzia Workflow: `PreToolUse` na Workflow widzi skrypt, nie prompt, więc bramka 5 ich nie obejmie, zostaje `SubagentStop` (czy odpala się dla agentów workflow — niezmierzone [ASSUMPTION]); „przeczytał" ≠ „zrozumiał", tego żaden skrypt nie sprawdzi.

Gotowe, gdy (każdy test n ≥ 2, wynik `[MEASURED]` w findings): (1) push z zepsutym nagłówkiem zablokowany; (2) pytanie o hooki bez czytania `hooks.md` → `Stop` blokuje i nazywa plik; (3) agent z zadaniem o hookach → prompt ma dopisaną lekturę, `SubagentStop` blokuje, gdy jej nie wykonał; (4) po kompakcji log wyzerowany i `Stop` znów wymaga czytania; (5) CI czerwone na celowo zepsutej gałęzi.

Koszt: 1–2 sesje, ~5–10 USD z testami [ASSUMPTION].

## 5. Krok 4 — CLAUDE.md

- Skrócić do ≤ 120 linii: rola, język, komunikacja, persystencja, eksperymenty, dwie linie wskazujące `knowledge/CLAUDE.md`. Tabela KB, znaczniki, lista sprzeczności, „Freshness", „Live lookups" przechodzą do `knowledge/CLAUDE.md` i `docs-index.md`.
- Usunąć „O0 w całości raz na sesję": zastępuje to bramka H4 (czytanie wymuszone per temat, sprawdzane skryptem).
- Dopisać jedną linię: „po zmianie w `knowledge/` uruchom `kb_build.py`, potem `kb_check.py`" (miękka, ale hook `Stop` i tak to wymusi).
- Edycja CLAUDE.md może być odrzucona przez klasyfikator jako „Self-Modification" (findings 2026-10-06); wtedy dostajesz gotowy plik do wklejenia. Zmiana działa od następnej sesji (O0 §2).

Koszt: pół sesji.

## 6. Co zostaje miękkie

- Treść promptów agentów poza linią dopisaną przez hook.
- Sesje z kilkoma repozytoriami i `claude -p` spoza korzenia: zero hooków i reguł projektu.
- Omijanie bramki push przez skrypt w pliku (łapie dopiero CI).
- Routine tygodniowa: zależy od Twojego założenia jej i od tego, czy sesja z Routine zrobi wpis.
- Zrozumienie przeczytanego.

## 7. Pytania do decyzji

1. Układ plików z §1: tak / nie / zmiany?
2. N tur dla wymuszonego ponownego czytania: start 10?
3. Repo publiczne czy prywatne (branch protection)?
4. Plik `.claude/settings.json` z hookami: dodajesz sam z mojego szkicu, czy próbuję i czekam na klasyfikator?
5. Dokumenty planu i recenzji w repo po polsku (jak `reports/` z 2026-10-11) czy po angielsku (reguła CLAUDE.md)?

## 8. Weryfikacja tego planu

Recenzja 1: agent Opus 5.5, effort xhigh — zasadność, kompletność, zgodność z KB i z ustaleniami (twarde > miękkie, jeden krok na raz, dwa modele). Po poprawkach audyt 2: agent Fable 5.1 xhigh i agent Opus 5.5 max, równolegle — sceptyczna recenzja i sprawdzenie, czy autor planu niczego nie pominął i naprawdę przeczytał to, na co się powołuje. Raporty w tym katalogu.
