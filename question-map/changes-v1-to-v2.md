# Question map: what changed from draft v1 to v2

Date: 2026-10-06. v1 = `draft-v1.md` (own analysis + 3 research agents on official docs + 1 independent review). v2 = `tree-v2.md` = the content seeded into the Artifact. `mapa-pytan-v2.json` is the same tree in the Artifact's import format (backup).

## Source of the changes
- One research agent (agent 5) collected 77 community-reported Claude Code pitfalls. Each has a URL opened in that session (WebFetch), a quote and a date. 76 are GitHub issues in anthropics/claude-code; 1 is a third-party guide on GitHub.
- These are community reports, not facts. Quotes passed through WebFetch's summarising model and are not byte-verified.
- Forums and blogs were not covered: reddit, Hacker News, dev.to, medium and most blog domains are blocked by this environment's network policy (see findings.md 2026-10-06).

## Changes
1. Four questions added (origin: community):
   - **B7.1** Czy stałe zasady (np. język i forma odpowiedzi) obowiązują przez całą sesję, także po długich ciągach czynności?
   - **F8** Jak dowiem się o zmianach, które sesja wprowadziła poza treścią plików (ustawienia repozytorium, gałąź domyślna, wdrożenia, publikacje pod moim nazwiskiem), i skąd dowie się o nich następna sesja?
   - **I7** Skąd wiem, że zgoda lub polecenie, na które Claude się powołuje, naprawdę pochodzi ode mnie i obejmuje dokładnie to, co zostało wykonane?
   - **M7** Jak wykryję, że część mojego systemu po cichu się nie włączyła albo przestała działać, choć wszystko wygląda poprawnie?
2. Community reports attached to 60 questions (new field "Zgłoszenia społeczności"). Per question, pitfall numbers from the table below:

   A5: [28]; B1.1: [2, 4, 9, 25, 37, 38, 39, 40, 56]; B2: [9, 10, 11, 17, 65]; B2.1: [1, 14]; B2.2: [35, 40]; B2.3: [13]; B3: [5]; B5: [3, 7, 8]; B6.1: [73]; B7: [16, 66]; B7.1: [6]; C3: [5, 20]; C4.1: [30]; D1: [19, 21]; D2: [20]; D2.1: [74]; D2.2: [27]; D3: [21, 22, 24, 50, 53]; E2: [29, 31, 67]; E3: [29]; E4: [19, 23, 24, 39]; F1: [51, 52, 53, 54]; F2: [55]; F3: [34, 59]; F4: [60, 61]; F5: [18]; F5.1: [14, 15, 16]; F6: [46]; F7: [59]; F7.1: [63]; F8: [42, 62]; G2.1: [57]; G4: [65]; G5: [62]; H1: [36]; H2: [12, 34]; H4: [26, 31, 32, 33, 48, 76]; H5: [32, 61]; I1: [37, 46, 47, 48]; I2: [41, 64]; I3: [76, 77]; I4.1: [4]; I5: [49]; I6: [42]; I7: [25, 43, 44, 45]; J2: [55]; J3: [11, 56, 58]; K1: [71, 72]; K2: [73]; K3: [74]; K5.1: [70]; L1: [70, 71]; L2: [69]; L3: [18, 36, 50, 69]; L4: [68]; M3: [64]; M7: [17, 35, 56, 66]; N2.1: [72, 75]; N3: [67]; N4: [44, 45]

3. Nothing else changed: no v1 question's wording, why line, source, dependencies or hidden flag was edited, and nothing was removed or moved.

## Where my integration differs from agent 5's proposal
- Pitfall 17 (custom agents vanish after /compact) mapped to B2 and M7, not B2.1: B2.1 is about instructions given in conversation.
- Pitfall 54 (scratchpad wiped after idle) mapped to F1 only, not L2: it is about persistence, not usage limits.
- Agent's NEW-c added in branch F (as F8), not M: what breaks is the next session starting from a wrong state.
- Agent's NEW-d added as sub-question B7.1, not a key question: one report only (weak support).

## Open contradiction in the reports
- Pitfall 56 (#89215: repo `.claude/settings.json` hooks never run in web sessions) vs the title of #78119 (says such hooks do work). Unresolved; measurable in a cloud session.

## Pitfall table

| # | Reports | Mapped to |
|---|---|---|
| 1 | #95745 | B2.1 |
| 2 | #90542 | B1.1 |
| 3 | #85677 | B5 |
| 4 | #88470 | B1.1, I4.1 |
| 5 | #99216 | B3, C3 |
| 6 | #96326 | B7.1 |
| 7 | #80988 | B5 |
| 8 | #91861 | B5 |
| 9 | #90450, #89251 | B2, B1.1 |
| 10 | #96361 | B2 |
| 11 | #99275 | B2, J3 |
| 12 | #59309 | H2 |
| 13 | #88354 | B2.3 |
| 14 | #96422 | B2.1, F5.1 |
| 15 | #96261 | F5.1 |
| 16 | #94564 | B7, F5.1 |
| 17 | #88023 | B2, M7 |
| 18 | #65796 | F5, L3 |
| 19 | #46940 | E4, D1 |
| 20 | #92732 | D2, C3 |
| 21 | #63861 | D1, D3 |
| 22 | #97155 | D3 |
| 23 | #89906 | E4 |
| 24 | #89751 | E4, D3 |
| 25 | #95360, #97927 | I7, B1.1 |
| 26 | #61167 | H4 |
| 27 | #96771 | D2.2 |
| 28 | #90650 | A5 |
| 29 | #37279 | E2, E3 |
| 30 | #53994 | C4.1 |
| 31 | #94666 | H4, E2 |
| 32 | #92952, #89709 | H4, H5 |
| 33 | #96546 | H4 |
| 34 | #97924 | F3, H2 |
| 35 | #91781, #50522, #95357 | M7, B2.2 |
| 36 | #69578 | L3, H1 |
| 37 | #84634 | B1.1, I1 |
| 38 | #92542 | B1.1 |
| 39 | #84863 | E4, B1.1 |
| 40 | https://github.com/yurukusa/cc-safe-setup/blob/main/TROUBLESHOOTING.md | B1.1, B2.2 |
| 41 | #95155 | I2 |
| 42 | #90622 | I6, F8 |
| 43 | #88837 | I7 |
| 44 | #95749 | I7, N4 |
| 45 | #98591 | I7, N4 |
| 46 | #70363, #97842 | F6, I1 |
| 47 | #87360 | I1 |
| 48 | #99198 | I1, H4 |
| 49 | #98478 | I5 |
| 50 | #98066 | L3, D3 |
| 51 | #51579 | F1 |
| 52 | #63689 | F1 |
| 53 | #95524 | F1, D3 |
| 54 | #77669 | F1 |
| 55 | #93585 | F2, J2 |
| 56 | #89215 | J3, B1.1, M7 |
| 57 | #78119 | G2.1 |
| 58 | #23627 | J3 |
| 59 | #72502 | F3, F7 |
| 60 | #90943, #98950 | F4 |
| 61 | #83311 | F4, H5 |
| 62 | #98916 | F8, G5 |
| 63 | #99938, #96252 | F7.1 |
| 64 | #95450 | M3, I2 |
| 65 | #92998, #82056 | G4, B2 |
| 66 | #95582, #85207 | B7, M7 |
| 67 | #79998 | E2, N3 |
| 68 | #94534 | L4 |
| 69 | #94770, #94012 | L3, L2 |
| 70 | #97074 | L1, K5.1 |
| 71 | #46829, #41930 | L1, K1 |
| 72 | #98679 | K1, N2.1 |
| 73 | #97117 | K2, B6.1 |
| 74 | #83795 | D2.1, K3 |
| 75 | #42796 | N2.1 |
| 76 | #88134 | I3, H4 |
| 77 | #95857, #98071 | I3 |
