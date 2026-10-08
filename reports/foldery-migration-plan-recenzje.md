# Plan migracji Foldery: decyzje z recenzji

Załączniki do `reports/foldery-migration-plan.md` (wersja 4.2), wydzielone, żeby plan mieścił się w jednym odczycie (Read ≤ 25k tokenów). Historia decyzji; obowiązuje treść planu.

## Załącznik R: uwagi recenzji „meta” i decyzje

| Uwaga | Decyzja | Uzasadnienie / zmiana w planie |
|---|---|---|
| Wersja dwuetapowa (A mechaniczny, B kondensacja) | **Przyjęta ze zmianą** | Przyjęta w całości poza jednym: rozdział na pliki „-historia” w A odrzucony, bo wymaga oceny znaczenia, czyli pracy z etapu B. W A akapity zostają w kolejności „od najnowszego” (§0, A2, §5) |
| M1 odbiór w nowej sesji niewykonalny przed scaleniem | Przyjęta | A6 (w sesji migracji) + A7 (nowa sesja na `main`) |
| M2 sprzeczny limit MAPA 6 000 B | Przyjęta (mój błąd) | MAPA ≤ 40 000, STATUS ≤ 6 000 |
| M3 prowokacje mogą zaszkodzić | Przyjęta | wszystkie z `--dry-run` |
| M4 Stop hook porównuje ze startem sesji | Przyjęta | `turn-baseline.sh` (UserPromptSubmit) |
| M5 pokrycie identyfikatorami słabe | Przyjęta | konkordancja linii 100% zamiast identyfikatorów; §1 i §5 dosłownie |
| M6 odwołania „§N” | Przyjęta | stabilne numery §5.N, KONKORDANCJA.tsv, grep `§[0-9]` (A3.4) |
| M7 ręczne wagi, historia w nagłówku MAPA §4, brak przymusu „przepisuj” | Przyjęta ze zmianą | rozmiar w KB sprawdzany ±10%; stały nagłówek §4; zakaz `**v4.` tylko w plikach oznaczonych jako skondensowane (w A pliki są dosłowne) |
| M8 `git mv` na starcie | Przyjęta | A0.1; plan w `/MIGRACJA/` poza `GaleriaFolderow/` (D8) |
| M9 kopiować skryptem | Przyjęta | A3.1 |
| M10 wycofanie | Przyjęta | §7 |
| M11 klasyfikator przy `.claude/` | Przyjęta | ścieżka `staging/` (A5) |
| M12 duplikaty MAPA §3, EFFORT §6.10 | Przyjęta | A4.3, A4.4 |
| M13 protokół weryfikacji pod `tests/**` się nie załaduje | Przyjęta | protokół w `/CLAUDE.md`, szczegóły w `SRODOWISKO-TESTY.md` |
| M14 archiwum w `GaleriaFolderow/` | Przyjęta ze zmianą | archiwum w `/archiwum/` (poza zipem i grepem po `GaleriaFolderow`); samo `git grep` odrzucone, bo archiwum jest źródłem dla skryptu w A i dla kondensacji w B |
| M15 GitHub MCP omija hooki | Przyjęta ze zmianą | deny 4 narzędzi zapisu zamiast hooka (prostsze i twarde) |
| Uwaga o `read()` w `doc_check` | Przyjęta | A4.5 |
| Odstępstwo „§1 dosłownie w CLAUDE.md” (runda 2) | **Wycofane** | N1 |
| N1 nieaktualne reguły §1 w pliku ładowanym wszystkim | Przyjęta (mój błąd) | §1 → `ZASADY-UZYTKOWNIKA.md` dosłownie; nagłówek tylko do archiwum; CLAUDE.md streszcza obowiązujące reguły |
| N2 konkordancja rozjedzie się po edycjach A3.4/A4 | Przyjęta | konkordancja na commicie po A3.2, SHA w POSTEP.md, późniejsze sprawdzenia względem SHA |
| N3 kolejność `git mv` vs `merge --ff-only`, brak katalogu | Przyjęta | A0.1 merge, A0.2 `mkdir -p` + `git mv` |
| N4 prowokacja MCP może naprawdę wypchnąć | Przyjęta | `/permissions`, potem wywołanie na nieistniejące repo/gałąź |
| N5 stdout hooka UserPromptSubmit trafia do kontekstu | Przyjęta | `turn-baseline.sh` cichy, limit 30 s |
| N6 zepsuty frontmatter reguły = ładowanie zawsze | Przyjęta | `doc_check` pkt 9 |
| N7 tolerancja ±10% za ciasna | Przyjęta | pełne KB, max(10%, 1 KB) |
| N8 kondensacja opcjonalna | Przyjęta | `doc_check` pkt 8 + lista w STATUS; wyjątek „odłożona” (§5) |

## Załącznik T: recenzja techniczna i decyzje

| Uwaga | Decyzja | Zmiana |
|---|---|---|
| T1 regexy `guard-bash` blokują poprawne i przepuszczają force/main (zmierzone) | Przyjęta | `guard_bash.py` z tokenizacją (Załącznik S), 22/22 + moje 8/8 |
| T2 exec form wymaga bitu wykonywalności; brak = strażnik wyłączony | Przyjęta | wywołanie przez `bash` / `python3 -I` |
| T3 `/context`, `/hooks`, `/permissions` wpisuje człowiek | Przyjęta | sprawdzenia przez transkrypt (`nested_memory`), skutki i `claude -p "/context"`; opcjonalnie Ty |
| T4 scalenie do `main` może zostać odrzucone | Przyjęta | ścieżka PR (A6.5) |
| T5 hash statusu nie widzi ponownej edycji | Przyjęta | hash z treścią zmian; `additionalContext` zamiast `block` |
| T6 deny `backup/` i zip mogą zablokować dostawę | Przyjęta ze zmianą | deny usunięte; `backup/` chroni `guard-edit.sh` (Edit/Write); prowokacja `cp` |
| T7 inne drogi zapisu (`gh`, MCP auto-merge, Actions) | Przyjęta | dodatkowe deny (miękkie dla `gh`, twarde dla MCP) |
| T8 sprawdzenie CI przepuszcza `on: push` | Przyjęta | lista dozwolonych: tylko `workflow_dispatch` |
| T9 pokrycie zakresów, skrypt ginie, treść przepisana bez źródła | Przyjęta | pokrycie 1–4711, skrypt w repo, archiwum MAPA i EFFORT |
| T10 pliki dosłowne zawierają nieaktualne polecenia | Przyjęta | nagłówek „przy sprzeczności obowiązują `/CLAUDE.md` i `/dostawa`” |
| T11 limit reguły 32 KB za ciasny; brak limitu agent-rules | Przyjęta | 36 KB; agent-rules ≤ 9 000 znaków |
| T12 `paths` w worktree niezweryfikowane | Przyjęta | `**/GaleriaFolderow/galeria.py` + test w A7.3 |
| T13 wycofanie przez `revert` zakresu zawiedzie przy commicie scalenia | Przyjęta | `git restore --source=<stary_main>` + commit |
| Szacunek kosztu optymistyczny | Przyjęta | 10–25 USD, pomiar po A2 |

## Załącznik U: przegląd trwałości wersji 4.1 i decyzje

| Uwaga | Decyzja | Zmiana |
|---|---|---|
| U1 nic nie wymusza zmian dokumentacji razem z kodem; STATUS może być nieaktualny | Przyjęta | reguły różnicy przy pushu na `main` (H), K8 |
| U2 etap B bez wymuszenia, furtka „odłożona”, zakres tylko `architektura/`, `spec/` | Przyjęta | zamrożenie (`ZAMROZONE.tsv`, `doc_check` pkt 11), §5 przepisany, `/kondensacja`, D10 |
| U3 MAPA §4 rośnie w pliku z limitem 40 KB | Przyjęta | §4 usunięta, mapa na żądanie (A4.3) |
| U4 CLAUDE-NOWY odsyła do nieistniejącej `.claude/rules/testy.md` | Przyjęta | odsyłacz usunięty, plik nie powstaje (A2) |
| U5 `.gitattributes` nie chroni przed CRLF z wgrania; hook basha z exit 2 na UserPromptSubmit blokuje każdy prompt | Przyjęta | hooki w Pythonie, nieblokujące zawsze 0, test CRLF; D9 zamiast wgrywania |
| U6 sprawdzenie wyzwalaczy CI tylko przy pushu na `main` | Przyjęta | przy każdym `git push`; `edit` składa plik wynikowy |
| U7 mieszane bazy ścieżek i ręczny rozmiar w CLAUDE.md | Przyjęta | ścieżki od korzenia, `doc_check` pkt 4 (baza), pkt 12 |
| U8 „zmiany `.claude/` działają w nowej sesji” nieprawdziwe dla hooków | Przyjęta | poprawione w CLAUDE-NOWY i §8 |
| U9 STATUS tylko przy nowej wersji; STATUS i BACKLOG dublują „otwarte” | Przyjęta | STATUS przy każdej sesji ze zmianami; otwarte tylko w BACKLOG |
| U10 drobne: start z flagami CLI w chmurze, edycja `galeria.py` poza Edit nie wczytuje niezmienników, brak `prompt-audit` w CLAUDE.md | Przyjęta | §3, CLAUDE-NOWY |
| Zip 20 MB w historii git | Odnotowana | D4, poza migracją |

Wiersze Załączników R i T wymieniające `guard-bash.sh`, `guard-edit.sh`, `turn-baseline.sh`, `stop-check.sh` dotyczą wersji wcześniejszych; ich funkcje są teraz podpoleceniami `hooks.py`.
