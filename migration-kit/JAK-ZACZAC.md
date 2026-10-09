# Jak zacząć migrację dokumentacji (karta dla właściciela)

Zestaw: `PLAN-MIGRACJI-v5.md` + prompty. Ty uruchamiasz sesje i odpowiadasz na kilka pytań; resztę robi Claude.

## Krok 0 (raz): pakiet do ClaudeEXPERT
Odpowiedz „tak” na pytanie o umieszczenie pakietu (koniec obecnej sesji): sesja wypchnie folder `migration-kit/` do
ClaudeEXPERT i otworzy PR — scal go (instrukcja niżej). Potem kolejno: porządki w Foldery (niżej), dopiero potem
nowy projekt — sesja doradcy kopiuje zabezpieczenia z uporządkowanego Foldery.

## Kolejność (nowy projekt, np. pobtweaks)
| # | Sesja (repozytorium) | Pierwsza wiadomość | Koszt | Twój czas | Możesz odejść? |
|---|---|---|---|---|---|
| 1 | ClaudeEXPERT (samo) | `Wykonaj migration-kit/PROMPT-ANALIZA-I-PLAN-v2.md dla repozytorium asktheages1/<nazwa>.` | ok. 25–40 USD | ok. 5 min: po ok. 20 min napisz „jestem”, odpowiedz na 2 pytania zbiorcze; na końcu scal PR | po pytaniach tak |
| 2 | projekt (samo) | `Wykonaj MIGRACJA/PROMPT-ETAP-A-v2.md od kroku 1.` | 18–25 USD | 1 min | od razu |
| 3 | projekt (samo) | `Wykonaj MIGRACJA/PROMPT-ETAP-B-v2.md od kroku 1.` | 110–150 USD* | ok. 5 min: przejrzyj 3 linie próbki po ok. 20 min | po próbce tak |
| — | projekt (samo), gdy sesja wypisze „przegląd zaległy” | `/przeglad` | 3–8 USD | 1 min | od razu |
\* Dla projektu wielkości Foldery. Po analizie (sesja 1) dostaniesz liczbę dla swojego projektu. Mały projekt kończy się
po 1–2 sesjach (klasa „none” albo „light”).

Każda sesja: przed wysłaniem pierwszej wiadomości sprawdź model **Opus 5.5** (nie Fable), potem `/effort high`, tryb Auto.

## Foldery (migracja już zrobiona)
Jedna sesja porządkowa: Foldery (samo), wiadomość `Wykonaj migration-kit/PROMPT-FOLDERY-ETAP-C.md z repozytorium
ClaudeEXPERT na Foldery.`, 15–25 USD, ok. 1 h. Na początku jedno pytanie o paczkę zip. Warunek: pakiet jest już w
ClaudeEXPERT (folder `migration-kit/`) — patrz `ZMIANY-v5.md` §4.

## Co zobaczysz i co robić
- **„Accept edits”** (zapis w `.claude/`): przełącz tryb, zatwierdź, wróć do Auto. Zdarza się najwyżej raz na sesję.
- **Do ok. 10 agentów naraz** w sesji 3 to normalne (narzędzie Agent, nie workflow).
- **Sesja stoi, gdy wrócisz:** napisz `wznów`.
- **PR do scalenia:** GitHub w telefonie → Pull requests → ten PR → „Merge pull request” → „Confirm”.
- Każda sesja kończy się listą „Zmiany w tej odpowiedzi”, „Następny krok” (z gotową pierwszą wiadomością następnej
  sesji) i pytaniami w ramce. Nie musisz niczego wklejać ani wgrywać.

## Jak zlecać duże zadanie (żeby nie dopisywać wymagań w kolejnych wiadomościach)
W pierwszej wiadomości napisz:
1. cel jednym zdaniem i dla kogo jest wynik;
2. co jest w zakresie, a czego nie dotykać (np. „tylko moje aplikacje z Claude”);
3. limity, jeśli jakieś chcesz (np. liczba agentów), i język plików;
4. „recenzja kończy się, gdy runda nie znajdzie nic ważnego; trzecia runda tylko za moją zgodą; każda recenzja mówi
   też, co wyciąć”;
5. „pytania zbierz na początek albo na koniec, nie w trakcie”.
