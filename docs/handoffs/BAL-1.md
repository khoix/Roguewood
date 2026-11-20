# Agent task handoff — BAL-1, a clean release earns something (owner, 2026-11-20)

## Assignment
- **Owner:** Claude, from the owner's play notes and the follow-up:
  - "Why does a clean throw gain nothing?"
  - "It seems odd to credit the player with a clean throw, but give them nothing for it. What can we give them that would keep the game balance?"
  - The owner agreed the version below, then: "Work the queued items."
- **State:** DONE.
- **Branch:** `claude/roguewood-build`.
- **Paths:**
  - `src/rules/frame_rules.gd` (`INSIDE_VALUE`), `src/rules/score_log.gd` and `src/presentation/score_panel.gd`;
  - tests: `tests/rules_test.gd`, `tests/scoring_test.gd`, `tests/scoring_journey.gd`, `tests/slice_journey.gd`, `tests/division_journey.gd`, `tests/save_journey.gd`, `tests/ability_journey.gd`, `tests/ability_v08_journey.gd`, `tests/av_c04_a_journey.gd`;
  - docs/CONTRACTS.md and Codex's prompt.

## The rule
A frame's best release adds, once, before the Charms:

| Release | Value | Mult | A plain strike |
|---|---|---|---|
| Miss | — | — | 560 |
| Clean | +10 | — | 600 (was 560) |
| Sweet | +10 | +1 | 750 (was 700) |
| Perfect | +10 | +2 | 900 (was 840) |

- **Each grade includes the one below.** The Value is a pin's worth, added before anything multiplies.
- **The tally says it:** "Clean +10 Value", "Sweet +10 Value +1 Mult", "Perfect +10 Value +2 Mult" or "Miss +0 Mult". A Value-only line shows the Value icon.
- **The accuracy event** now carries `value_amount` and `pin_value` beside `amount` (Mult).
- **Unchanged:** the `accurate` item condition counts sweet or better, as before.

## Balance (the strategy simulation, 400 seeded runs per strategy, before and after)
| Content | Strategy | League win: before → after | Division 1 cleared: before → after |
|---|---|---|---|
| Slice | anchor_survivor | 3.5% → 5.0% | 54.5% → 61.5% |
| Slice | echo_ruby | 10.5% → 12.5% | 63.0% → 67.0% |
| Slice | gold_growth | 6.8% → 9.3% | 51.3% → 59.8% |
| Slice | hook_artist | 12.8% → 16.5% | 62.0% → 66.0% |
| Slice | house_only | 0.0% → 0.0% | 26.3% → 33.5% |
| Slice | random_buyer | 12.8% → 14.0% | 59.3% → 64.5% |
| Slice | strike_chain | 9.8% → 13.8% | 55.8% → 65.3% |
| Slice, rivals unlocked | anchor_survivor | 3.5% → 3.5% | 52.3% → 58.5% |
| Slice, rivals unlocked | echo_ruby | 17.2% → 19.0% | 69.0% → 71.5% |
| Slice, rivals unlocked | gold_growth | 7.3% → 11.0% | 53.5% → 60.8% |
| Slice, rivals unlocked | hook_artist | 12.0% → 16.5% | 61.5% → 66.0% |
| Slice, rivals unlocked | house_only | 0.0% → 0.0% | 26.3% → 33.5% |
| Slice, rivals unlocked | random_buyer | 10.8% → 13.3% | 59.3% → 65.5% |
| Slice, rivals unlocked | strike_chain | 10.2% → 15.3% | 57.8% → 67.3% |
| Neon | house_only | 0.0% → 0.0% | 26.3% → 33.5% |
| Neon | neon_curve | 0.0% → 0.0% | 61.5% → 66.0% |
| Neon | neon_straight | 0.0% → 0.0% | 52.3% → 56.3% |
| Neon | random_buyer | 0.0% → 0.0% | 63.2% → 66.3% |
| Neon | strike_chain | 0.0% → 0.0% | 53.3% → 59.3% |

- **Every build gains a little:** whole-League wins rise 0–5 points, Division 1 clears 4–9 points.
- **Unchanged:** buying nothing still never wins, and Neon stays at no simulated wins.
- **Decision: the targets stay.** The best builds win only 10–19% of simulated runs, so this is a modest easing of a hard game, not a break. E24's balance study can tighten them if play shows it.
- **Regenerate:** `python3 tools/qa.py slice --runs 400`, or `tools/slice_strategies.gd --runs=400 --content=neon`.

## Tests
- **Unit fixtures** now default to a miss, so each item test isolates its item and keeps its hand-computed score.
- **New unit checks:**
  - a plain strike by grade: 560 / 600 / 750 / 900;
  - the best grade counts once;
  - each grade's tally line, banked score and running Value.
- **Journeys:**
  - J03's independent check now includes the grade;
  - J06, J08A06R, J11, J11ART and J12R01–R02 (the slice's Echo strike), J12V01–V08 and JAVC04A compute the clean bonus from the actual release;
  - J06's lab boss strike is 600, two strikes 1200;
  - in J07 the spare's clean bonus already wins the feature, so the second frame is conditional.
- **New fixed values:** J03 600/260/70 (was 560/240/70); J05's match 2 is 25920.
- **PASS:**
  - `unit`, `content` and every journey headless (115);
  - the 15 updated journeys re-run after the changes.
