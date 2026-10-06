# A | Cel i miara sukcesu
> Co właściwie ma robić każdy system i po czym poznać, że robi to dobrze. Bez tego nie da się ocenić ani posłuszeństwa Claude, ani skuteczności audytu.

## A1 | Jakie konkretne rezultaty ma dawać każdy z moich systemów i komu mają służyć?
- why: Bez nazwanego rezultatu nie da się stwierdzić, czy Claude „się słucha” ani czy audyt coś przeoczył; każda ocena staje się wrażeniem.
- src: analiza własna; KB O0 §6 „Apparent understanding” [SOURCE: CC best-practices]
- hidden: no
- origin: own

## A2 | Po czym, niezależnie od zapewnień Claude, poznam, że zadanie zostało wykonane dobrze?
- why: Bez sprawdzalnych kryteriów odbioru „gotowe” znaczy tylko „Claude tak twierdzi”, a dwie oceny tej samej pracy wychodzą różnie.
- src: KB O0 §6 „False done”; https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („A good task is one where two domain experts would independently reach the same pass/fail verdict.”)
- deps: A1
- hidden: no
- origin: kb

## A3 | Które błędy są dla mnie najdroższe, a które mogę tolerować?
- why: Bez tego kontrola jest rozłożona na ślepo: za droga tam, gdzie błąd nic nie kosztuje, i za słaba tam, gdzie kosztuje najwięcej.
- src: KB O0 §8 (przegląd w świeżym kontekście opłaca się tam, gdzie błąd kosztuje więcej niż przegląd)
- deps: A1
- hidden: yes
- origin: kb

## A4 | Które zadania w ogóle nadają się do powierzenia Claude, a które lepiej zrobić samemu lub innym narzędziem?
- why: Źle dobrane zadanie daje pozorną pracę, której sprawdzanie trwa dłużej niż zrobienie jej samemu.
- src: analiza własna; KB O0 §8 (małe, iteracyjne zadania taniej w głównym oknie)
- deps: A1, A3
- hidden: yes
- origin: own

### A4.1 | Jak duże zadanie mogę dać jednej sesji lub jednemu agentowi, zanim jakość zacznie spadać, i po czym poznam, że trzeba je podzielić?
- why: Zbyt duże zadanie zapełnia pamięć roboczą modelu; Claude zaczyna „zapominać” wcześniejsze polecenia i częściej się myli, a ja widzę tylko końcowe „gotowe”.
- src: https://code.claude.com/docs/en/best-practices („When the context window is getting full, Claude may start "forgetting" earlier instructions or making more mistakes.”); KB O0 §1 (stopniowy spadek jakości, bez progu liczbowego)
- deps: A4, G3
- hidden: yes
- origin: docs

## A5 | Które decyzje zostawiam wyłącznie sobie, a kiedy Claude ma przerwać pracę i zapytać?
- why: Bez tej granicy Claude albo rozstrzyga sprawy, które należą do mnie (także nieodwracalne), albo zatrzymuje się bez potrzeby.
- src: KB O0 §3, §8; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 („Pause for the user only when the work genuinely requires them”)
- deps: A3
- hidden: no
- origin: kb

# B | Posłuszeństwo wobec instrukcji
> Dlaczego Claude nie zawsze robi to, co napisałem. „Instrukcje” to pliki CLAUDE.md (stałe instrukcje projektu wczytywane na starcie sesji), polecenia w rozmowie, opisy agentów i ustawienia konta. Agent to osobna instancja Claude uruchomiona do podzadania, która nie zna mojej rozmowy.

## B1 | Które moje zasady muszą być przestrzegane bez wyjątku, a które są tylko wskazówkami?
- why: Tekst instrukcji tylko doradza modelowi; jeśli nie oddzielę zasad bezwzględnych od preferencji, te pierwsze będą łamane tak samo jak drugie.
- src: KB O0 §6, §8; https://code.claude.com/docs/en/memory („Claude treats them as context, not enforced configuration.”)
- deps: A3
- hidden: no
- origin: kb

### B1.1 | Dla każdej zasady bezwzględnej: co ją faktycznie wymusza, a co tylko o niej przypomina?
- why: Zakaz zapisany w instrukcji to prośba; np. wypchnięcia zmian do wersji głównej nie blokuje ani serwer pośredniczący chmury, ani domyślne zabezpieczenia, a moje uprawnienia administratora mogą ominąć ochronę gałęzi (ustawienie w GitHub blokujące zmiany w gałęzi).
- src: KB O0 §8 („Hard is only what Claude Code or the server enforces”) [SOURCE: CE; MEASURED: claude auto-mode defaults]; https://code.claude.com/docs/en/security („A rule that access can bypass doesn't block a session's push”); https://code.claude.com/docs/en/debug-your-config („where you need a guarantee instead of guidance”)
- deps: I1
- hidden: no
- origin: kb

## B2 | Skąd wiem, które instrukcje Claude naprawdę „widzi” w danym momencie: w głównej sesji i u każdego agenta?
- why: Zasada, której Claude nie dostał, nie może być przestrzegana; poprawia się wtedy treść, choć przyczyną jest to, że plik w ogóle nie dotarł.
- src: KB O0 §2 tabela „At start” [MEASURED: transkrypty, 2026-10-04]; https://code.claude.com/docs/en/sub-agents („Explore and Plan skip your CLAUDE.md files”)
- hidden: yes
- origin: kb

### B2.1 | Co dzieje się z poleceniami i zakazami podanymi w rozmowie, gdy długa sesja zostanie automatycznie streszczona (kompakcja: skrócenie historii, żeby zmieściła się w pamięci roboczej modelu)?
- why: Polecenie podane tylko w rozmowie przetrwa jedynie jako streszczenie; zakaz typu „nie wypychaj zmian” może zniknąć.
- src: KB O0 §1, §4; https://code.claude.com/docs/en/permission-modes („a boundary can be lost if context compaction removes the message that stated it.”)
- hidden: yes
- origin: docs

### B2.2 | Od kiedy obowiązuje zmiana instrukcji: od razu, od nowej sesji, czy dopiero po włączeniu jej do głównej wersji repozytorium?
- why: Poprawka, która „nie działa”, często jeszcze nie obowiązuje; agenci i automatyczne zabezpieczenia mają wersję z początku sesji.
- src: KB O0 §2 [MEASURED: plik dodany w trakcie sesji niewidoczny dla nowego agenta]; findings.md 2026-10-06; https://www.anthropic.com/engineering/multi-agent-research-system („agents might be anywhere in their process.”)
- deps: F2
- hidden: yes
- origin: kb

### B2.3 | Które z moich stałych ustawień (instrukcje i pamięć konta claude.ai, pliki w repozytoriach, ustawienia osobiste) docierają do którego miejsca pracy i które wygrywa, gdy się różnią?
- why: Zasada zapisana w jednym miejscu nie działa tam, gdzie zakładam, albo przegrywa z kopią, o której zapomniałem.
- src: KB O0 §2 [MEASURED: preferencje claude.ai tylko w głównym oknie, u żadnego agenta]; https://code.claude.com/docs/en/features-overview („when the same name exists at multiple levels, one definition wins”); niesprawdzone: czy pamięć konta claude.ai dociera do sesji Claude Code
- deps: B2
- hidden: yes
- origin: kb

## B3 | Jak wykryję, że zasada została złamana, bez polegania na tym, że Claude sam się przyzna?
- why: Dziś złamanie zasady wychodzi przypadkiem; bez niezależnego wykrywania nie wiem, jak często się zdarza.
- src: analiza własna; KB O0 §4 (odmowy zabezpieczeń widać tylko w raporcie agenta)
- deps: B1, D2
- hidden: no
- origin: own

## B4 | Co musi być przed Claude zawsze, co tylko przy związanym zadaniu i ile tekstu wczytywanego zawsze to już za dużo?
- why: Gdy wszystko trafia do plików wczytywanych na starcie, przestrzeganie spada, a każdy agent płaci za ten tekst przy uruchomieniu.
- src: KB O0 §2, §6, §8; https://code.claude.com/docs/en/memory („target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence.”; „If an entry is a multi-step procedure or only matters for one part of the codebase, move it”)
- deps: G3
- hidden: no
- origin: docs

### B4.1 | Kiedy Claude stosuje moją zasadę tam, gdzie nie pasuje, albo pomija ją w nowym przypadku, to z czego to wynika?
- why: Bez rozpoznania przyczyny dopisuję kolejne zasady-wyjątki, a problem wraca w innej postaci.
- src: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices („Claude is smart enough to generalize from the explanation.”; „you can use more normal prompting”)
- hidden: yes
- origin: docs

## B5 | Co się dzieje, gdy moje instrukcje przeczą sobie nawzajem albo wbudowanym instrukcjom Claude Code, których nie widzę?
- why: Claude wybiera wtedy sam i nie musi o tym powiedzieć; wygląda to na nieposłuszeństwo, choć jest skutkiem sprzeczności.
- src: https://code.claude.com/docs/en/memory („if two instructions contradict each other, Claude may pick one arbitrarily”); https://code.claude.com/docs/en/how-claude-code-works („the rule may have come from a system reminder.”)
- deps: B2.3
- hidden: yes
- origin: docs

## B6 | Jak wcześnie wychodzi na jaw, że Claude zrozumiał polecenie inaczej niż ja?
- why: Rozbieżność w rozumieniu celu wychodzi zwykle dopiero po wykonaniu pracy, gdy poprawka kosztuje najwięcej.
- src: KB O0 §6 „Apparent understanding” [SOURCE: CC best-practices]; KB O5 §1 („Name the exact behavior you want or don't want”)
- deps: A2
- hidden: no
- origin: kb

### B6.1 | Czy z mojego polecenia jasno wynika, czy chcę porady czy działania, i jak daleko sięga zadanie?
- why: Claude proponuje zmiany, gdy chciałem je mieć zrobione, robi je, gdy chciałem tylko opinii, albo po cichu zawęża lub poszerza zadanie.
- src: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices („Claude will sometimes provide suggestions rather than implementing them”); …/prompting-claude-fable-5-1 („don't quietly narrow, widen, or swap it”)
- hidden: yes
- origin: docs

## B7 | Czy Claude za każdym razem sięga po przygotowane przeze mnie narzędzia i procedury i trzyma się ich do końca zadania, czy sam decyduje i z czasem odpuszcza?
- why: Procedura pominięta, bo Claude uznał ją za zbędną, albo wykonana tylko na początku, wygląda w raporcie tak samo jak procedura przestrzegana.
- src: https://code.claude.com/docs/en/skills („Claude Code does not re-read the skill file on later turns”); https://support.claude.com/en/articles/13730515 („Connectors aren't loaded until Claude searches for the right one”); https://claude.com/docs/skills/overview („it's the only part Claude sees before deciding to use the skill.”)
- deps: B2
- hidden: no
- origin: docs

# C | Źródła zamiast pamięci
> Jak sprawić, żeby odpowiedzi opierały się na źródłach, a nie na tym, co model „pamięta” z treningu.

## C1 | Przy jakich pytaniach odpowiedź z pamięci modelu jest dla mnie dopuszczalna, a przy jakich musi za nią stać źródło?
- why: Bez tej granicy albo nic nie jest sprawdzone, albo każda odpowiedź kosztuje pełne poszukiwania.
- src: analiza własna; CLAUDE.md tego repozytorium („Your training data is likely older and less precise than the KB”)
- deps: A3
- hidden: no
- origin: own

### C1.1 | Które tematy w mojej pracy zmieniają się tak szybko, że pamięć modelu i moja baza wiedzy szybko stają się nieaktualne, choć brzmią pewnie?
- why: Przy tematach częściowo znanych (narzędzia AI, ceny, przepisy) nieaktualna odpowiedź brzmi najbardziej przekonująco.
- src: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1 („partial background is exactly what makes an out-of-date answer sound authoritative”); CLAUDE.md „Freshness”
- hidden: yes
- origin: docs

## C2 | Które źródła są dla mnie wiarygodne i w jakiej kolejności, gdy sobie przeczą?
- why: Bez ustalonej hierarchii Claude wybiera źródło dowolnie, a sprzeczność znika bez śladu.
- src: CLAUDE.md tego repozytorium (hierarchia dowodów); https://code.claude.com/docs/en/best-practices („Point to sources.”)
- deps: C1
- hidden: no
- origin: kb

## C3 | Jak w gotowej odpowiedzi odróżnię, co pochodzi ze źródła, co z pamięci modelu, co jest domysłem, a czego nie udało się sprawdzić?
- why: Odpowiedzi z pamięci brzmią równie pewnie, a sprawdzenie, które się nie powiodło, wygląda jak brak problemów.
- src: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5 („sometimes answers from its training knowledge when a web search would catch details that have changed.”); https://code.claude.com/docs/en/workflows („lists that claim as unverified instead of counting it as refuted.”)
- deps: C2, D1
- hidden: no
- origin: docs

### C3.1 | Gdy Claude wskazuje źródło, skąd wiem, że źródło naprawdę mówi to, co twierdzenie, i które słowa są cytatem, a które jego parafrazą?
- why: Prawdziwe źródło przypięte do twierdzenia, którego nie popiera, wygląda dokładnie jak dowód.
- src: https://www.anthropic.com/engineering/multi-agent-research-system („citation accuracy (do the cited sources match the claims?)”); …/prompting-claude-fable-5-1 („Summaries reproduce source wording without marking it as a quotation”)
- hidden: yes
- origin: docs

## C4 | Do których potrzebnych mi źródeł Claude ma dostęp w sesji w chmurze i co robi, gdy dostępu nie ma?
- why: Zablokowane źródło łatwo zamienia się w cichą odpowiedź z pamięci albo w „obejście”, które wygląda jak prawdziwy wynik.
- src: KB O0 §7; findings.md 2026-10-06 [MEASURED: fora i blogi zablokowane dla curl i WebFetch w sieci Trusted]; https://code.claude.com/docs/en/claude-projects („Don't substitute, mock, or guess.”)
- deps: J1
- hidden: yes
- origin: kb

### C4.1 | Gdy Claude mówi, że coś przeczytał lub przeszukał, czy widział całość, streszczenie, tylko początek, czy nic?
- why: Wnioski budowane na fragmencie lub pustym wyniku wyglądają jak wnioski z pełnej lektury.
- src: https://code.claude.com/docs/en/tools-reference („WebFetch lossy by design”; „Read returns the first page with a `PARTIAL view` notice”; „a capped call appears in the conversation as a search that did nothing”); KB O0 §1
- hidden: yes
- origin: docs

## C5 | Co Claude ma zrobić, gdy źródła nie rozstrzygają sprawy?
- why: Jeśli „nie wiem” nie jest dozwolonym wynikiem, model wypełnia lukę domysłem podanym jako fakt.
- src: https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/reduce-hallucinations („Explicitly give Claude permission to admit uncertainty.”); CLAUDE.md („Never present a guess as fact”)
- deps: C2
- hidden: no
- origin: docs

# D | Dowody i weryfikacja pracy
> Jak upewnić się, że Claude naprawdę zrobił to, co raportuje, i że jego twierdzenia mają pokrycie.

## D1 | Co dla mnie liczy się jako dowód, że coś zostało sprawdzone albo zrobione?
- why: Bez standardu dowodu „sprawdziłem” nie różni się od zmyślenia; „przetestowane” może znaczyć test, który nawet się nie uruchomił.
- src: https://code.claude.com/docs/en/best-practices („Have Claude show evidence rather than asserting success”); …/prompting-claude-sonnet-5-5 („A syntax-only check, or a check command that failed to start, does not count”)
- deps: A2
- hidden: no
- origin: docs

### D1.1 | Które elementy odpowiedzi (cytaty, linki, liczby, nazwy, wersje) sprawdzam zawsze, a które wyrywkowo?
- why: Sprawdzanie wszystkiego jest niewykonalne, a niesprawdzanie niczego przepuszcza zmyślenia w najbardziej „twardych” miejscach.
- src: analiza własna
- deps: A3
- hidden: no
- origin: own

## D2 | Jak mogę niezależnie od relacji Claude sprawdzić, co faktycznie wykonał: jakie czynności i z jakim wynikiem?
- why: Liczy się rzeczywisty stan plików i systemów, a nie raport; bez wglądu w zapis przebiegu nie odróżnię czynności wykonanej od opisanej.
- src: KB O0 §5 [MEASURED: wysiłek z pola transkryptu, nie z deklaracji]; https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („the outcome is whether a reservation exists”; „read the transcripts and grades from many trials.”)
- deps: D1
- hidden: no
- origin: kb

### D2.1 | Skąd wiem, jakim modelem i na jakim poziomie wysiłku (ustawienie określające, ile model myśli i sprawdza) naprawdę wykonano daną pracę?
- why: Podzadanie bez jawnego ustawienia może biec na słabszym modelu, rozmowa może zostać automatycznie przełączona na słabszy model do jej końca, a deklaracja samego modelu nie jest wiarygodna.
- src: KB O0 §5 [MEASURED: claude -p bez --model → claude-sonnet-5-5]; https://support.claude.com/en/articles/16049681 („the model picker stays on the less capable model for the rest of the conversation.”); https://code.claude.com/docs/en/sub-agents (claude-code-guide działa na Haiku)
- hidden: no
- origin: kb

### D2.2 | Czy wyjaśnienie Claude, dlaczego coś zrobił, mogę traktować jako dowód przyczyny błędu, czy tylko jako hipotezę do sprawdzenia?
- why: Audyt oparty na deklarowanych powodach może przeoczyć prawdziwą przyczynę błędu.
- src: https://www.anthropic.com/research/reasoning-models-dont-say-think (starszy model, warunki badawcze); https://www.anthropic.com/engineering/writing-tools-for-agents („LLMs don’t always say what they mean.”)
- hidden: yes
- origin: docs

## D3 | Gdy Claude pracuje beze mnie, na jakiej podstawie praca zostaje uznana za skończoną: rzeczywistego stanu czy tylko słów Claude?
- why: Model kończy, gdy praca „wygląda na skończoną”; odpowiedź tekstowa bywa tylko raportem z postępu, a ocena oparta wyłącznie na rozmowie daje się przekonać samymi zapewnieniami.
- src: KB O0 §6 „False done”; https://code.claude.com/docs/en/goal („It doesn't run commands or read files independently”); …/prompting-claude-opus-5-5 („Treat a text-only end of turn as a report rather than as proof the task is done.”)
- deps: A2, D1
- hidden: no
- origin: docs

## D4 | Jak wykryję, że Claude przytakuje moim błędnym założeniom albo zmienia zdanie pod moim naciskiem, a nie pod wpływem faktów?
- why: Mój własny nacisk potrafi odwrócić poprawną odpowiedź; przegląd prowadzony w rozmowie ze mną zamienia się w echo.
- src: KB O0 §6 „Sycophancy”; https://www.anthropic.com/research/claude-personal-guidance („The sycophancy rate is 18% in conversations when people push back compared to 9%”; rozmowy o sprawach osobistych, przeniesienie na pracę techniczną to założenie)
- hidden: yes
- origin: docs

## D5 | Na ile wyniki Claude są powtarzalne i ile powtórzeń potrzeba, żeby wniosek był wiarygodny?
- why: Pojedynczy przebieg to anegdota; „zadziałało raz” to coś innego niż „działa za każdym razem”.
- src: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („pass^k measures the probability that all k trials succeed.”); KB O0 §5 [MEASURED: rozrzut kosztu do 2,25×, wynik 4/4, n=2]
- hidden: no
- origin: docs

# E | Audyty i przeglądy
> Dlaczego kilka sesji i agentów przegląda tę samą pracę, a prawdziwe problemy i tak przechodzą.

## E1 | Czego dokładnie ma szukać audyt i czego świadomie nie bada?
- why: Kilka audytów może przeoczyć ten sam rodzaj problemu, bo żaden go nie szukał; audyt bez kryteriów zwraca szum.
- src: https://code.claude.com/docs/en/code-review („focuses on correctness: bugs that would break production”); https://code.claude.com/docs/en/commands (/simplify: „The review doesn't look for correctness bugs.”)
- deps: A2, A3
- hidden: no
- origin: docs

## E2 | Jak zmierzę, ile prawdziwych problemów audyt wyłapuje, a ile przepuszcza, i ile fałszywych alarmów podnosi?
- why: Audyt, którego skuteczności nikt nie zmierzył, daje fałszywe poczucie bezpieczeństwa; kolejny audyt to wtedy tylko kolejny tekst.
- src: https://www.anthropic.com/engineering/harness-design-long-running-apps („Out of the box, Claude is a poor QA agent.”); https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („LLM-as-judge graders should be closely calibrated with human experts”)
- deps: E1
- hidden: no
- origin: docs

### E2.1 | Czy moje sprawdziany badają oba kierunki: że system działa, gdy powinien, i powstrzymuje się, gdy nie powinien?
- why: Sprawdzanie tylko jednej strony przesuwa zachowanie w przeciwną skrajność.
- src: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („One-sided evals create one-sided optimization.”)
- hidden: yes
- origin: docs

## E3 | Kto sprawdza pracę i czy kolejni sprawdzający są naprawdę niezależni od wykonawcy i od siebie nawzajem, czy powielają te same ślepe plamki?
- why: Ten, kto ocenia własną pracę, ocenia ją zbyt łagodnie; ten sam model z tymi samymi materiałami i pozostałościami po wcześniejszych przebiegach popełnia te same błędy, więc zgodność audytów może być kopiowaniem.
- src: https://www.anthropic.com/engineering/harness-design-long-running-apps („agents reliably skew positive when grading their own work”); https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („gaining an unfair advantage on some tasks by examining the git history from previous trials.”); KB O0 §3 [MEASURED: recenzent zmienił 16,7% z 424 ustaleń; poprawność zmian nie oceniona]
- deps: A3, D1
- hidden: no
- origin: docs

## E4 | Czy ten, kto wykonuje pracę, może zmienić to, co go ocenia: testy, listy kontrolne, pliki, w których zapisuje swój postęp, zasady?
- why: Jeśli może, wynik „wszystko zielone” może pochodzić z poprawienia sędziego, a nie z wykonania pracy.
- src: https://www.anthropic.com/research/reward-tampering (warunki badawcze: „altering a checklist so it appeared that incomplete tasks were actually complete”); https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices („It is unacceptable to remove or edit tests”)
- deps: E3
- hidden: yes
- origin: docs

## E5 | Których problemów nie da się znaleźć czytaniem, tylko uruchomieniem albo próbą?
- why: Przegląd tekstu nie wykryje, że coś w praktyce nie działa; w tej bazie wiedzy pomiary nieraz przeczyły dokumentacji.
- src: CLAUDE.md „Experiments”; KB O0 §3, §4 (rozbieżności pomiar–dokumentacja)
- hidden: yes
- origin: kb

## E6 | Co robię z rozbieżnymi wynikami audytów i kto ma ostatnie słowo?
- why: Bez reguły sprzeczności są rozstrzygane po cichu albo wcale.
- src: CLAUDE.md („Known open conflicts (never resolve silently)”)
- deps: C2
- hidden: no
- origin: kb

## E7 | Czy sposób, w jaki zlecam sprawdzenie lub audyt (wymagana liczba zgłoszeń, „tylko poważne”, wymagana pewność), sam z siebie zawyża albo zaniża to, co zostanie zgłoszone?
- why: Takie polecenie model wykonuje dosłownie: przy wymaganej liczbie dopisuje sztuczne zastrzeżenia, przy zawężeniu część ustaleń odpada, zanim ktokolwiek je zobaczy.
- src: https://code.claude.com/docs/en/best-practices („A reviewer prompted to find gaps will usually report some, even when the work is sound”); https://code.claude.com/docs/en/code-review („reports only the findings it's most confident in”); …/prompting-claude-opus-5 („the model may follow that instruction literally and report less”)
- deps: E1
- hidden: yes
- origin: docs

# F | Ciągłość pracy między sesjami
> Co przetrwa, co ginie i jak wyniki z wielu sesji składają się w jedną całość. Gałąź (branch) to osobna wersja plików w repozytorium; main to wersja główna; scalenie (merge) to włączenie zmian z gałęzi do main.

## F1 | Co przetrwa koniec sesji, przerwę i wymianę maszyny w chmurze, a co przepada?
- why: Praca w tle przepada, gdy maszyna sesji zostanie odzyskana po bezczynności; pliki niewypchnięte do repozytorium najpewniej też (założenie).
- src: KB O0 §7 [ASSUMPTION: unpushed files lost]; https://code.claude.com/docs/en/claude-code-on-the-web („Not restored: background work that was still running when the VM was reclaimed”)
- hidden: no
- origin: docs

## F2 | Skąd każda nowa sesja ma wiedzieć, która wersja moich plików i ustaleń jest aktualna?
- why: Każda sesja startuje od wersji głównej na własnej gałęzi; to, czego tam nie ma, dla niej nie istnieje.
- src: findings.md 2026-10-06; https://code.claude.com/docs/en/web-quickstart („Each task gets its own session and its own branch”)
- hidden: no
- origin: kb

## F3 | Kto, kiedy i według jakich zasad włącza wyniki sesji do wersji głównej i co dzieje się z wynikami, których nikt nie włączył?
- why: Niescalone gałęzie rozjeżdżają się z czasem; wyniki istnieją, ale nikt z nich nie korzysta.
- src: findings.md 2026-10-06 (scala właściciel; zabezpieczenie zablokowało scalenie przez Claude)
- deps: F2
- hidden: no
- origin: kb

## F4 | Jak połączyć wyniki równoległych sesji, żeby się nie nadpisały ani sobie nie przeczyły?
- why: Dwie sesje zmieniające ten sam plik dają konflikt albo po cichu kasują swoją pracę.
- src: analiza własna; KB O0 §3 (agenci bez izolacji pracują na wspólnej kopii plików)
- deps: F2, F3
- hidden: no
- origin: own

## F5 | Jak przekazać stan niedokończonej pracy następnej sesji, żeby nie zaczynała od zera ani od błędnych założeń?
- why: Każda sesja zaczyna bez pamięci; bez wspólnego zapisu stanu sesje zgadują, powtarzają pracę albo ogłaszają „gotowe” za wcześnie.
- src: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents („each new session begins with no memory of what came before.”; „see that progress had been made, and declare the job done.”)
- deps: F1, F2
- hidden: no
- origin: docs

### F5.1 | Co z ustaleń, decyzji i dokładnych liczb ginie lub się zniekształca, gdy rozmowa zostaje streszczona albo wyniki przechodzą przez streszczenia od agenta do agenta i od sesji do sesji?
- why: Każde przekazanie przez streszczenie może zgubić lub zmienić szczegół; późniejsza praca łamie wtedy wcześniejsze ustalenia, a wyniki dryfują jak w głuchym telefonie.
- src: …/prompting-claude-fable-5-1 („compaction summaries drop constraints, decisions, or exact details”); https://www.anthropic.com/engineering/multi-agent-research-system („minimize the ‘game of telephone.’”); KB O0 §1
- deps: B2.1
- hidden: yes
- origin: docs

## F6 | Jak odzyskam pracę, gdy coś zostanie nadpisane, usunięte albo zgubione?
- why: Bez drogi powrotu jeden błąd kasuje godziny lub dni pracy; niektóre miejsca nie mają kosza ani historii wersji.
- src: analiza własna; https://support.claude.com/en/articles/16923645 („Deleting a doc is permanent. There's no trash”)
- hidden: no
- origin: own

## F7 | Gdzie trwale lądują wyniki, decyzje i dowody z każdej sesji, jak długo tam leżą i jak je potem odnajduję?
- why: Wyniki rozproszone po rozmowach, gałęziach, plikach roboczych i publikowanych stronach są w praktyce stracone, a bez archiwum nie odtworzę, dlaczego coś zrobiono.
- src: analiza własna; KB O0 §7 (historia sesji zostaje, pliki maszyny nie); https://support.claude.com/en/articles/12618689 („pushes the changes to a new branch in your GitHub repository.”)
- deps: G1, F2
- hidden: no
- origin: own

### F7.1 | Czy zapis przebiegu sesji (transkrypt: pełny zapis czynności Claude) jest dowodem, który muszę zachować, i czy da się go odzyskać po zakończeniu sesji?
- why: Bez tego nie wiem, czy po końcu sesji da się odtworzyć, co Claude zrobił: plik zapisu przebiegu leży na maszynie, która znika, a zostaje tylko historia rozmowy.
- src: KB O3 §9 (transkrypty w ~/.claude/projects/); KB O0 §7
- deps: D2
- hidden: yes
- origin: kb

# G | Wiedza i dokumentacja
> Jak organizować, utrzymywać i archiwizować wiedzę, z której korzystamy ja i Claude.

## G1 | Jakie rodzaje informacji trzyma mój system (zasady, fakty, decyzje, bieżący stan, dowody) i czym różnią się tempem starzenia się i tym, kto może je zmieniać?
- why: Informacje starzejące się w różnym tempie, wymieszane w jednym miejscu, psują się nawzajem; nie wiadomo, co wolno zmienić bez pytania.
- src: analiza własna; podział tego repozytorium: knowledge/, findings.md, exceptions.md
- hidden: yes
- origin: own

### G1.1 | Jak odróżniam wiedzę potwierdzoną od hipotez i jednorazowych obserwacji?
- why: Hipoteza zapisana obok faktu z czasem zaczyna być traktowana jak fakt.
- src: CLAUDE.md tego repozytorium (znaczniki dowodów)
- hidden: no
- origin: kb

## G2 | Gdy kilka repozytoriów lub części systemu potrzebuje tej samej zasady albo wiedzy, gdzie ona leży i skąd wiadomo, która wersja obowiązuje?
- why: Kopie tej samej zasady w kilku repozytoriach rozjeżdżają się, a część plików Claude wczytuje tylko w określonych sytuacjach.
- src: KB O0 §2 (hierarchia CLAUDE.md; zagnieżdżony CLAUDE.md wchodzi przy odczycie pliku z katalogu) [MEASURED]; https://code.claude.com/docs/en/large-codebases („Conventions drift, files go stale, and no one owns the root.”)
- deps: G1, F2
- hidden: no
- origin: kb

### G2.1 | Jak wiedza wspólna dla kilku repozytoriów ma docierać do każdej sesji w chmurze?
- why: Udokumentowany sposób dzielenia ustawień między repozytoriami nie dociera do sesji w chmurze.
- src: https://code.claude.com/docs/en/features-overview („A second repository needs the same setup | Package it as a plugin”); https://code.claude.com/docs/en/cloud-environments („doesn't install the plugins a repository turns on”)
- deps: J1
- hidden: yes
- origin: docs

## G3 | Ile dokumentacji Claude jest w stanie realnie przeczytać i utrzymać w uwadze w jednej sesji i u każdego agenta?
- why: Za długie pliki są czytane częściowo, jakość spada wraz z zapełnieniem pamięci roboczej, a każdy agent płaci za wczytaną wiedzę.
- src: KB O0 §1 (limit odczytu 25 000 tokenów) [CODE]; https://platform.claude.com/docs/en/build-with-claude/context-windows („As token count grows, accuracy and recall degrade”)
- hidden: yes
- origin: kb

## G4 | Kto, kiedy i na podstawie czego aktualizuje dokumentację i jak wykrywam wpisy przestarzałe, sprzeczne lub błędne?
- why: Dokumentacja bez właściciela i terminu przeglądu po cichu staje się nieprawdziwa, a nieaktualna notatka jest czytana jako prawda w każdej kolejnej sesji.
- src: CLAUDE.md „Updating the KB”, „Freshness”; KB O0 §9; https://code.claude.com/docs/en/memory (audyt szuka „files that contradict each other”); [MEASURED: claude --version → 2.1.292, nowsza niż migawka KB 2.1.291, 2026-10-06]
- deps: G1, K1
- hidden: no
- origin: kb

## G5 | Skąd następna sesja ma wiedzieć, że coś zostało celowo postanowione, a nie jest przypadkiem do poprawienia?
- why: Decyzja, której celowość nie jest widoczna, zostaje „poprawiona” przez następną sesję.
- src: analiza własna
- deps: G1
- hidden: yes
- origin: own

## G6 | W jakim języku i formie dokumentacja ma służyć jednocześnie mnie i Claude?
- why: Język wpływa na koszt i czytelność: polski tekst zużywa wyraźnie więcej tokenów (jednostek, w których liczy się tekst i koszt) niż angielski, a ja muszę go rozumieć.
- src: KB O0 §1 [MEASURED: bajty na token: polski md 1,83–2,13, angielski md 2,66–2,78]
- hidden: no
- origin: kb

### G6.1 | Czy instrukcje, które piszę po angielsku, mówią dokładnie to, co mam na myśli, i jak to sprawdzam?
- why: Niuans zgubiony w obcym języku zmienia zasadę, a ja tego nie zauważę.
- src: analiza własna; CLAUDE.md „Language” („The owner sticks to English as the main language of his Claude files”)
- deps: G6
- hidden: yes
- origin: own

# H | Agenci i podział pracy
> Agent to osobna instancja Claude uruchomiona do podzadania, która nie zna mojej rozmowy. Kiedy pomaga, kiedy szkodzi i jak go poinstruować.

## H1 | Kiedy podział pracy na agentów pomaga, a kiedy szkodzi (jakość, koszt, czas)?
- why: Agenci gubią kontekst, zużywają wielokrotnie więcej tokenów i dają wyniki, które trzeba scalać; nie każde zadanie na tym zyskuje.
- src: KB O0 §3, §8; https://www.anthropic.com/engineering/multi-agent-research-system („multi-agent systems use about 15× more tokens than chats.”)
- deps: A3
- hidden: no
- origin: kb

## H2 | Jak upewnić się, że agent, także sprawdzający, dostał wszystko, czego potrzebuje, skoro nie widzi mojej rozmowy, moich preferencji ani plików przeczytanych wcześniej?
- why: Agent działa tylko na tym, co dostał w zleceniu; bez dokładnego opisu dubluje pracę, zostawia luki albo zgaduje, a sprawdzający podnosi fałszywe alarmy.
- src: KB O0 §2 tabela [MEASURED: preferencje tylko w głównym oknie]; https://code.claude.com/docs/en/sub-agents („It doesn't see your conversation history”); https://www.anthropic.com/engineering/multi-agent-research-system („Without detailed task descriptions, agents duplicate work, leave gaps”)
- deps: B2
- hidden: no
- origin: kb

## H3 | Co ma zrobić agent, gdy trafi na decyzję, której nie może podjąć sam, skoro nie może mnie zapytać?
- why: Agent bez reguły zatrzymania zgaduje i idzie dalej.
- src: KB O0 §2, §8 (agenci tracą narzędzie pytania użytkownika) [SOURCE: CC sub-agents]
- deps: A5
- hidden: yes
- origin: kb

## H4 | Jak dowiem się, co agent naprawdę zrobił, czego mu odmówiono i czy jego raport jest kompletny, czy ucięty?
- why: Agent po odmowie zabezpieczeń pracuje dalej bez pytania, a niedokończony lub ucięty raport bywa przekazywany jako pełny wynik.
- src: KB O0 §4 [MEASURED: odmowa = wynik narzędzia, agent kontynuuje]; https://code.claude.com/docs/en/sub-agents („returns that partial output with a note that the subagent was cut off”)
- deps: D2
- hidden: yes
- origin: kb

## H5 | Kto odpowiada za połączenie i sprawdzenie wyników wielu agentów w jedną odpowiedź?
- why: Bez właściciela scalania sprzeczności między agentami giną albo przechodzą do wyniku.
- src: analiza własna; KB O5 §2 (oddzielenie wykonawcy od oceniającego)
- deps: E3
- hidden: no
- origin: own

# I | Granice, uprawnienia i bezpieczeństwo
> Czego Claude nie może zrobić, co może bez pytania, co z zewnątrz może nim sterować i jakie dane wychodzą poza moją kontrolę.

## I1 | Których działań Claude nie może wykonać nigdy, bo są nieodwracalne albo wychodzą poza moje repozytoria?
- why: Bez takiej listy nie wiem, które zakazy muszą być wymuszone, a nie tylko zapisane; jeden nieodwracalny krok kosztuje więcej niż wszystkie oszczędności.
- src: KB O0 §8; https://code.claude.com/docs/en/security
- deps: A3
- hidden: no
- origin: kb

## I2 | Co Claude może zrobić bez mojej zgody, co czeka na mnie i co się dzieje, gdy mnie nie ma: w sesji w chmurze i w zadaniach uruchamianych według harmonogramu?
- why: Zakładam krok potwierdzenia, którego na danej powierzchni nie ma; sesja czekająca na moją zgodę dla połączonej usługi (MCP) jest uznawana za bezczynną i może wygasnąć.
- src: https://code.claude.com/docs/en/web-quickstart („Cloud sessions don't offer Manual or Bypass permissions.”); https://code.claude.com/docs/en/routines („can't act as approval or consent for actions during the run.”); https://code.claude.com/docs/en/claude-code-on-the-web („A session counts as inactive while it waits for you to approve an MCP connector tool call”)
- deps: A5
- hidden: yes
- origin: docs

## I3 | Jakie treści z zewnątrz (strony, zgłoszenia, pliki, wyniki narzędzi, raporty innych agentów) mogą sterować Claude wbrew mnie?
- why: Tekst czytany przez Claude może zawierać polecenia; agent, który może działać, da się wtedy przejąć obcą treścią.
- src: https://code.claude.com/docs/en/security („Prompt injection is a technique where an attacker attempts to override or manipulate an AI assistant's instructions”); https://support.claude.com/en/articles/13364135 („Claude can read information outside your trusted boundary, and can perform actions”)
- hidden: yes
- origin: docs

## I4 | Które moje dane wychodzą poza moją kontrolę i kto je widzi?
- why: Sekrety, treść sesji i udostępnione materiały trafiają do miejsc, o których nie myślę, i nie da się ich potem w pełni wycofać.
- src: analiza własna
- hidden: yes
- origin: own

### I4.1 | Gdzie trzymam hasła, klucze i dane wrażliwe i kto lub co je widzi w środowisku chmurowym?
- why: Zmienne środowiska w chmurze i skrypt startowy widzi każdy, kto korzysta ze środowiska; sesje mogą zawierać dane uwierzytelniające.
- src: https://code.claude.com/docs/en/cloud-environments („Anyone who uses the environment can read its environment variables and setup script.”); KB O0 §7
- hidden: yes
- origin: docs

### I4.2 | Co faktycznie dostaje osoba, której coś udostępniam (strona, rozmowa, link publiczny), i czy mogę to cofnąć?
- why: Udostępnienie odsłania więcej niż widoczny element, a kopie przeżywają cofnięcie dostępu.
- src: https://support.claude.com/en/articles/9547008 („viewers also get access to the attachments and files in that chat.”); https://support.claude.com/en/articles/16762437 („treat a public link as public”)
- hidden: yes
- origin: docs

### I4.3 | Czy chcę, żeby moje rozmowy i sesje służyły do trenowania modeli, i czy wiem, że to ustawienie zmienia też czas ich przechowywania?
- why: Jedno ustawienie rozstrzyga między 30 dniami a pięcioma latami przechowywania i obejmuje też sesje Claude Code.
- src: https://www.anthropic.com/news/updates-to-our-consumer-terms („extending data retention to five years, if you allow us to use your data for model training.”); https://code.claude.com/docs/en/data-usage
- hidden: yes
- origin: docs

## I5 | Które moje prośby zostaną zablokowane przez automatyczne zabezpieczenia i co wtedy robię?
- why: Blokada w połowie zadania zostawia pracę niedokończoną; zdarzyło się (2026-10-06), że zabezpieczenie odmówiło dołączenia repozytorium potrzebnego do zadania i zmiany instrukcji, o którą prosił właściciel.
- src: findings.md 2026-10-06 [MEASURED: odmowy „Self-Modification” i „Permission Grant”]
- deps: I1
- hidden: yes
- origin: kb

## I6 | Co każda połączona usługa i każde repozytorium pozwala Claude czytać i zmieniać w moim imieniu i pod moim nazwiskiem, i jak długo?
- why: Dostęp przyznaje się raz i potem się o nim zapomina; działania Claude wyglądają jak moje, a odpowiedzialność za nie zostaje przy mnie, także za te, których nikt nie oglądał.
- src: https://claude.com/docs/connectors/custom/add-unlisted („create, modify, or delete data, and take actions on your behalf.”); https://code.claude.com/docs/en/routines („appears as you”); https://support.claude.com/en/articles/13364135 („You remain responsible for all actions taken by Claude performed on your behalf.”)
- deps: I1
- hidden: yes
- origin: docs

### I6.1 | Komu ufam, instalując dodatki stworzone przez innych (połączenia, umiejętności, wtyczki), i jak zauważę, że któryś zmienił się po mojej akceptacji?
- why: Sprawdzony dodatek może później zmienić działanie, a dodatki od innych osób nie są weryfikowane przez Anthropic.
- src: https://claude.com/docs/connectors/verification („controls its tools, which can change after review.”); https://claude.com/docs/skills/overview („aren't reviewed by Anthropic”)
- hidden: yes
- origin: docs

# J | Środowisko w chmurze
> Czym sesja na claude.ai różni się od pracy na własnym komputerze i co z tego wynika.

## J1 | Czego brakuje w sesji w chmurze w porównaniu z pracą lokalną i co działa tam inaczej?
- why: Rozwiązanie sprawdzone lokalnie może w chmurze nie działać wcale: brak pamięci automatycznej, brak osobistych ustawień, świeża maszyna przy każdej sesji.
- src: KB O0 §2, §7 [MEASURED: brak katalogu pamięci]; https://code.claude.com/docs/en/cloud-environments („Anything you commit to the repo is available. Anything you've installed or configured only on your own machine isn't”)
- hidden: no
- origin: kb

### J1.1 | Jakie limity techniczne środowiska (czas poleceń, pamięć, dysk, sieć) mogą przerwać pracę w połowie?
- why: Przekroczenie limitu przenosi polecenie w tło albo je przerywa, a przy zapełnionym dysku tymczasowym jego wynik ginie i zadanie zostaje w połowie.
- src: KB O0 §7 (limity czasu poleceń, dysk ~30 GB, sieć) [SOURCE: CE; MEASURED; CODE: komunikat ENOSPC]
- hidden: yes
- origin: kb

### J1.2 | Które funkcje działają tak samo na każdym moim urządzeniu, a które tylko na jednym?
- why: Sposób pracy zbudowany na komputerze po cichu nie działa na telefonie lub w przeglądarce.
- src: https://support.claude.com/en/articles/11725091 („only available in Claude Desktop and Claude Code—not on web or mobile.”); https://support.claude.com/en/articles/9450526 (eksportu nie da się uruchomić z aplikacji mobilnej)
- hidden: yes
- origin: docs

## J2 | Jak sprawić, żeby każda nowa sesja startowała w znanym, powtarzalnym stanie?
- why: Bez tego każda sesja zaczyna w nieco innych warunkach, a błędy trudno odtworzyć; to, co zainstalowano w trakcie sesji, nie przechodzi do następnej.
- src: KB O0 §7 [SOURCE: CE]; https://code.claude.com/docs/en/cloud-environments („those installs don't carry over to other sessions.”)
- deps: J1
- hidden: yes
- origin: kb

## J3 | Co się zmienia, gdy jedna sesja pracuje na kilku repozytoriach naraz?
- why: Część zabezpieczeń, ustawień i automatów wczytuje się tylko z katalogu startowego; przy kilku repozytoriach mogą po cichu nie działać.
- src: KB O0 §4, §7; https://code.claude.com/docs/en/settings („A session with several repositories starts above the clones and reads only the `enabledPlugins` and `extraKnownMarketplaces` keys”)
- deps: J1
- hidden: yes
- origin: docs

# K | Zmiany w czasie
> Modele, Claude Code i dokumentacja zmieniają się co tydzień. Jak system ma to przetrwać.

## K1 | Jak dowiem się, że zmiana w Claude Code, modelu, dokumentacji lub produkcie wpłynęła na mój system?
- why: Nowe wersje wychodzą częściej niż przegląd systemu (28 wydań Claude Code między 2026-09-06 a 2026-10-06), a część zmian produktu wchodzi bez możliwości powrotu.
- src: KB O0 §9; https://code.claude.com/docs/en/changelog (2.1.263–2.1.292); https://support.claude.com/en/articles/15520349 (Cowork: „you can't switch back.”)
- hidden: yes
- origin: docs

## K2 | Które moje zasady, fakty i ustawienia zależą od konkretnej wersji, modelu lub funkcji w fazie podglądu i wymagają ponownego sprawdzenia po zmianie?
- why: Instrukcje pisane pod starszy model pogarszają wynik nowego; ta sama nazwa ustawienia znaczy co innego na różnych modelach, a funkcje podglądowe mogą zniknąć.
- src: KB O0 §6 „Stale prompts”; https://code.claude.com/docs/en/model-config („the same level name does not represent the same underlying value across models.”); https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence („a prompt accumulates text written for a model you no longer use.”)
- deps: K1
- hidden: yes
- origin: docs

## K3 | Co się stanie, gdy model, na którym polegam, zostanie wycofany albo zmieni się model domyślny?
- why: Zapytania do wycofanego modelu przestają działać, a zmiana modelu domyślnego zmienia jakość i koszt bez żadnej zmiany po mojej stronie.
- src: https://platform.claude.com/docs/en/about-claude/model-deprecations („Requests to models past the retirement date will fail.”); KB O0 §5 [MEASURED: claude -p bez --model → Sonnet 5.5]
- deps: K1
- hidden: yes
- origin: docs

## K4 | Jak sprawdzę, czy po zmianie (mojej albo po stronie Anthropic) system działa lepiej, gorzej czy tak samo, bez ręcznego przeglądania wszystkiego?
- why: Bez tego po każdej zmianie nie odróżnię poprawy od pogorszenia ani od przypadku; poprawki piętrzą się, a nikt nie wie, które działają.
- src: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („Teams can't distinguish real regressions from noise”); https://code.claude.com/docs/en/best-practices („test changes by observing whether Claude's behavior actually shifts.”); https://code.claude.com/docs/en/skills („Seeing a skill trigger tells you Claude found it, not that it did what you intended.”)
- deps: A2, E2, D5
- hidden: yes
- origin: docs

## K5 | Co się stanie z moimi systemami, gdy zmieni się plan, cena, dostępność usługi albo zasady dostawcy?
- why: Cały system zależy od jednego dostawcy; model bywał już nagle niedostępny.
- src: KB O5 §5 (zawieszenie Fable 5 z powodu kontroli eksportu) [3P: venturebeat, aljazeera]
- hidden: yes
- origin: kb

### K5.1 | Czy mój sposób automatyzacji (skrypty, uruchomienia bez nadzoru) jest dozwolony w ramach planu, jak jest rozliczany i jak dowiem się o zmianie zasad?
- why: Zasady rozliczania pracy bez nadzoru były już ogłaszane i wstrzymywane; dzisiejsze rozwiązanie może jutro stać się drogie lub niezgodne z regulaminem.
- src: https://support.claude.com/en/articles/15036540 („For now, nothing has changed”); https://www.anthropic.com/legal/consumer-terms (zakaz dostępu „through automated or non-human means” poza wyraźnie dozwolonymi przypadkami)
- hidden: yes
- origin: docs

### K5.2 | Co stanie się z moją pracą, gdy konto zostanie zawieszone lub zamknięte albo przestanę płacić, i czy mogę ją wyeksportować w użytecznej formie?
- why: Praca istniejąca tylko w koncie może zniknąć, a eksport ma ograniczenia.
- src: https://www.anthropic.com/legal/consumer-terms („we may at our option delete any Materials”); https://support.claude.com/en/articles/9450526 („Exported data can't be imported into another personal Claude account”)
- hidden: yes
- origin: docs

# L | Koszt, limity i skala
> Ile kosztuje dany sposób pracy w pieniądzach i limitach planu i kiedy skala się opłaca.

## L1 | Ile kosztuje mój sposób pracy w pieniądzach lub limitach planu i gdzie to widzę?
- why: Sam start agenta kosztuje od kilkudziesięciu do ponad stu tysięcy tokenów, długa sesja zużywa więcej, niż sugeruje aktywność, a limit jest wspólny dla wszystkich miejsc, w których używam Claude.
- src: KB O0 §3, §8 [MEASURED: start agenta 25–180 tys. tokenów]; https://support.claude.com/en/articles/11647753 („counts towards the same usage limit.”); https://code.claude.com/docs/en/costs („A session that has been open for hours can use far more of your plan limits than your activity suggests”)
- hidden: yes
- origin: docs

### L1.1 | Jak upewnić się, że każda sesja zużywa limit mojego planu, a nie jest rozliczana osobno, poza planem?
- why: Jedno ustawienie w środowisku przenosi zużycie na osobne, płatne rozliczanie bez widocznego sygnału.
- src: https://support.claude.com/en/articles/11145838 („Claude Code will use this API key for authentication instead of your Claude subscription”)
- hidden: yes
- origin: docs

## L2 | Co dzieje się z pracą, zwłaszcza bez nadzoru, gdy w połowie skończy się limit albo usługa przestanie odpowiadać?
- why: Część trybów pracy czeka na odnowienie limitu, inne kończą się błędem i gubią postęp; praca zostawiona w tle zaczyna zużywać następne okno limitu.
- src: KB O3 §5 [OF CC workflows]; https://code.claude.com/docs/en/claude-projects („starts using your next usage window without a message from you”); https://support.claude.com/en/articles/12466728 („Capacity issues will not appear on our status page”)
- deps: L1
- hidden: yes
- origin: docs

## L3 | Jak z góry ograniczyć koszt (także dopłaty ponad plan), czas i liczbę powtórzeń zadania?
- why: Bez sufitu pętla lub duża orkiestracja zużywa limit, zanim to zauważę; kilka „uciekających” przebiegów potrafi zjeść większość budżetu, a dopłaty bez limitu rosną bez pytania.
- src: https://www.anthropic.com/engineering/building-effective-agents („include stopping conditions (such as a maximum number of iterations)”); https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence („two problems carried 43% of the spend”); https://support.claude.com/en/articles/12429409 („you can switch to consumption-based pricing at standard API rates”)
- deps: L1
- hidden: yes
- origin: docs

## L4 | Które zadania wymagają najmocniejszego modelu i najwyższego poziomu wysiłku, a które nie, i jak to sprawdzić na własnych zadaniach?
- why: Najwyższe ustawienia kosztują wielokrotnie więcej przy niewielkim zysku; najniższe gubią trudne zadania; pomocnicy bez jawnego ustawienia dostają wartości domyślne.
- src: KB O0 §5 [MEASURED: przegląd poziomów wysiłku]; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence („the default bought nothing measurable over `medium`”; „Long-horizon coding is where effort genuinely buys accuracy.”)
- deps: A3
- hidden: yes
- origin: docs

### L4.1 | Czy oszczędzanie na koszcie sprawia, że Claude rzadziej sięga do źródeł i rzadziej sprawdza swoją pracę?
- why: Oszczędność po cichu odbiera ugruntowanie w źródłach i weryfikację, a ja widzę tylko niższy rachunek.
- src: …/prompting-claude-fable-5-1 (przy niskim wysiłku „more likely to answer from memory”); …/prompting-claude-sonnet-5-5 („At `low`, it keeps its thinking short and can skip verifying a change.”)
- deps: C1, D1
- hidden: yes
- origin: docs

## L5 | Ile kosztuje mnie (czas nadzoru i pieniądze) jedna ukończona praca i czy system się opłaca w porównaniu z pracą bez niego?
- why: System, którego pilnowanie zajmuje więcej czasu, niż oszczędza, jest stratą; liczy się koszt ukończonej pracy, nie cena za token.
- src: analiza własna; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence („compare models on cost per completed task.”)
- deps: L1, A4
- hidden: yes
- origin: own

# M | Przegląd i kontrola nad całością
> Jak jedna osoba widzi, co ma, czego brakuje i co od czego zależy, bez tonięcia w tekście.

## M1 | Co dokładnie mam: z jakich systemów i części składa się moja praca z Claude?
- why: Bez spisu nie wiem, co poprawić, co usunąć i gdzie szukać przyczyny problemu.
- src: analiza własna (obserwacja właściciela); https://code.claude.com/docs/en/debug-your-config („the file didn't load, it loaded from a different location than you expected, or another file overrode it.”)
- hidden: no
- origin: own

## M2 | Co od czego zależy: co się zepsuje, gdy zmienię jeden element?
- why: Zmiana w jednym pliku instrukcji wpływa na agentów i repozytoria, o których nie pamiętam.
- src: analiza własna; KB O0 §2 (hierarchia i wczytywanie instrukcji)
- deps: M1
- hidden: no
- origin: own

## M3 | Jakie minimum informacji potrzebuję regularnie, żeby panować nad systemem bez czytania wszystkiego: co działa, co czeka na mnie, co się skończyło, co się nie udało?
- why: Bez ustalonego minimum albo czytam wszystko, albo nic, i problemy wychodzą za późno.
- src: analiza własna; https://code.claude.com/docs/en/agents („The command for checking on running work depends on which approach you used”)
- deps: M1
- hidden: no
- origin: own

## M4 | W jakiej formie i jakiej długości Claude ma mi raportować i pisać dokumenty, żebym w minutę wiedział, co zrobiono, co otwarte i co wymaga mojej decyzji?
- why: Długi raport pisany roboczym żargonem agenta ukrywa jedyną decyzję, której ode mnie potrzeba, a nowsze modele domyślnie piszą coraz dłuższe pliki.
- src: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 („your final message is their first look at any of it.”); …/prompting-claude-opus-5 („files that Claude Opus 5 writes to disk … are often longer than on prior models.”)
- deps: M3
- hidden: no
- origin: docs

## M5 | Jak śledzę otwarte kwestie, sprzeczności i nierozstrzygnięte pytania, żeby nie ginęły?
- why: Nierozstrzygnięta sprzeczność wraca w kolejnych sesjach jako „nowy” problem.
- src: CLAUDE.md „Known open conflicts”
- hidden: no
- origin: kb

## M6 | Które części mojego systemu naprawdę coś dają, a które są zbędną złożonością?
- why: Zbędne elementy dokładają kosztu i zamieszania, a usuwanie kilku naraz ukrywa, które były potrzebne.
- src: https://www.anthropic.com/engineering/harness-design-long-running-apps („difficult to tell which pieces of the harness design were actually load-bearing”)
- deps: M1, K4
- hidden: yes
- origin: docs

# N | Moja rola i doskonalenie systemu
> Co muszę umieć i robić sam, żeby system z czasem stawał się lepszy, a nie tylko większy.

## N1 | W których częściach mojej pracy nie potrafię sam ocenić, czy wynik Claude jest poprawny, i kto lub co ocenia go wtedy za mnie?
- why: Tam, gdzie nie umiem ocenić wyniku, dobra praca i przekonująco napisana praca wyglądają tak samo.
- src: analiza własna
- deps: E3
- hidden: yes
- origin: own

## N2 | Co robię z zauważoną porażką, żeby ten sam błąd nie wracał, a instrukcje nie rosły bez końca?
- why: Bez pętli nauki te same błędy wracają, a każda poprawka dopisana do instrukcji obniża skuteczność pozostałych.
- src: analiza własna; findings.md i exceptions.md w tym repozytorium
- deps: E2
- hidden: no
- origin: own

### N2.1 | Gdy coś zawiedzie, jak odróżnię winę modelu, moich instrukcji, błędnego sprawdzianu, środowiska i zmiany po stronie Anthropic?
- why: Źle rozpoznana przyczyna prowadzi do poprawiania nie tego, co trzeba; zmiany po stronie dostawcy wyglądają jak losowy spadek jakości.
- src: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents („fails to solve tasks due to grading bugs, agent harness constraints, or ambiguity”); https://www.anthropic.com/engineering/april-23-postmortem („the aggregate effect looked like broad, inconsistent degradation.”)
- hidden: yes
- origin: docs

## N3 | Jak bezpiecznie i tanio sprawdzić zmianę (instrukcję, agenta, sposób pracy), zanim wdrożę ją we wszystkich repozytoriach?
- why: Zmiana wdrożona wszędzie naraz psuje wszystko naraz.
- src: CLAUDE.md „Experiments”; KB O5 §3
- deps: K4, M2
- hidden: yes
- origin: kb

## N4 | Czy przy liczbie próśb o zgodę, raportów i zmian do scalenia, które dostaję, naprawdę czytam to, co zatwierdzam?
- why: Moja zgoda to ostatnia kontrola przed nieodwracalnym krokiem; dawana odruchowo przestaje nią być, a system wciąż na niej polega.
- src: https://code.claude.com/docs/en/security („Prompt fatigue mitigation”); https://code.claude.com/docs/en/permission-modes („reducing prompt fatigue”)
- deps: A5, I2
- hidden: yes
- origin: docs
