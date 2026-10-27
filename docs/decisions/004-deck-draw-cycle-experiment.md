# ADR 004 — E07 equipment: draw-and-cycle deck vs direct selection

Status: **provisional**, recorded for E07 on 2026-10-27, pending the owner's review. This ADR records an experiment, not a final rule. Design §15 says to test the proposed deck against direct selection and to make the call "through the vertical-slice playtest, not after producing the entire catalogue". That playtest is E13. Until then:

- The draw-and-cycle deck stays the **default** (design §2 already names it as the current proposal).
- Direct selection stays available as a lab option (Options → Equipment), so both can be played side by side.
- Nothing here is a balance claim. The items are lab fixtures, and the outcome model is synthetic.

## What was built

- **`CardDeck`** (`src/rules/card_deck.gd`) follows the §15 proposal:
  - A seeded draw pile and a four-card hand. On the first frame it draws four.
  - At each later frame start, it keeps at most one card, discards the rest and draws back to four. Draws happen only at frame start; the hand lasts for both rolls.
  - A played ball card goes to the discard pile (a strike does not refund it). A played tactical card is exhausted for the run, and only one tactical card is allowed per roll.
  - Cycle is once per frame: discard one unplayed card and draw one.
  - When the draw pile runs out, the sorted discard pile is reshuffled with the deck's own RNG stream. Exhausted cards never return.
  - At match start, everything except exhausted cards is recombined and shuffled.
  - The House ball is never a card. Arming nothing throws House.
  - The full state (piles, flags and RNG state) round-trips through JSON, ready for E10 saves.
- **`DirectLoadout`** (`src/rules/direct_loadout.gd`) is the original rule. House plus up to two special ball types are always visible, and each special has two uses per match. Tactical items are picked directly and exhausted when used. There is no draw, retain or cycle. It exposes the same interface, so the lab can swap the two models.
- **Lab fixtures** (`content/fixtures/lab_catalogue.json`, all completeness flags false):
  - Lab Value: +30 Value.
  - Lab Mult: +2 Mult.
  - Lab Coin: +$1 payout.
  - Lab Focus: tactical, +3 Mult on its roll.
  - The lab deck is two copies of each ball plus Lab Focus. The direct bag is Lab Value and Lab Mult plus Lab Focus.
  - The fixture balls share House physics (`LaneSpec.SIMULATED_BALLS`). Real per-ball physics is E17/E18 work.
- **Scoring:** played tactical cards join their roll's effects in `FrameBuilder.build(..., tactics)`. The log credits each effect to the card that supplied it ("Roll 1 Lab Focus +3 Mult", "After bank: Roll 2 Lab Coin +$1").
- **Lab UI** (`src/presentation/card_hand.gd`): a card row at the bottom for thumb reach. In landscape it becomes a two-row panel away from the assist side, so it never covers the ball.
  - Tap, click or focus-and-accept a card to arm it. Tap it again to disarm.
  - Cycle, then a card, swaps that card. The status line names the ball and tactic that will be thrown.
  - After a frame, tapping a card marks it ★ KEEP for the next frame. Keep is not offered at the end of a match, because the deck recombines then.
  - Cards lock while a ball is rolling. A cancelled or rejected throw spends nothing.
  - Every committed roll's trial-log line records the model, the thrown ball, the card and tactic played, the hand at the time, whether a cycle was used, the card kept from the last frame and the pile counts. This is the evidence for the human playtest.

## Structural experiment

Command: `python3 tools/qa.py experiment`, which writes `artifacts/e07/deck-experiment.json`.

- **Runs:** 1000 seeded runs of eight two-frame matches. Every frame is scored by the real `FrameRules`.
- **Outcome model:** the pinfall comes from a synthetic, seeded stream:
  - 30% strike; otherwise 5–9 pins.
  - 40% spare conversion.
  - Uniform accuracy grades.
- **Pairing:** every policy sees the same pinfall on a seed, so differences come only from equipment.
- **Policies:**
  - *house* never plays a card.
  - *greedy* plays Mult before Value before Coin, plays the tactical card at once, cycles away its weakest ball when holding no Mult card, and keeps its best card.
  - *random* chooses uniformly (House included) and cycles or keeps on a coin flip.

| Measure (per match unless noted) | deck greedy | deck random | direct greedy | direct random | house |
|---|---:|---:|---:|---:|---:|
| Mean score | 1412.8 | 1031.8 | 1306.6 | 1105.3 | 720.0 |
| SD / p10–p90 | 359.8 / 930–1870 | 382.5 / 540–1540 | 398.5 / 780–1820 | 387.3 / 600–1620 | 318.4 / 320–1120 |
| Uplift vs House | +96.2% | +43.3% | +81.5% | +53.5% | — |
| Choices per frame | 3.27 | 3.32 | 1.77 | 1.83 | 0 |
| Distinct ball types offered per roll | 2.60 | 2.63 | 1.59 | 1.87 | — |
| Best ball (Mult) available per roll | 71.0% | 87.2% | 58.7% | 93.1% | — |
| Frames with no ball card | 0% | 0% | 0% | 0% | — |
| Cycles / retains / reshuffles per run | 1.46 / 8 / 7.34 | 8.04 / 4.06 / 7.81 | — | — | — |

**Decision leverage** is how much better greedy play scores than random play in the same model: +36.9% for the deck and +18.2% for direct selection.

### Observations

1. **Decisions:** the deck creates about twice as many decisions per frame (keep and cycle on top of ball and tactic). Those decisions matter about twice as much: greedy play beats random play by 37% with the deck and by 18% with direct selection. On this structural measure the deck adds useful decisions rather than noise.
2. **Ceiling and spread:** the deck's greedy mean beat direct's, with a slightly smaller spread. The reason is that a seven-card deck reshuffles about once a match, so Mult cards come back within a match. Direct selection hard-caps them at two uses. The deck therefore has no per-match ceiling on a given special, only a draw-rate one. Shop prices, the deck cap and per-card charges (E08/E17/E24) must account for this.
3. **Dead hands:** no frame lacked a ball card with this starter list. With a four-card hand and at most two rolls, two or more cards are usually discarded unplayed every frame; the cards are churning, not scarce. Thinner decks (tactical-heavy kits, removal services) could change this, and E08/E23 must re-measure.
4. **Cost of interaction** (observed in J04 and the captures): the deck asks for more taps per frame (arm, sometimes cycle, then keep). The card row and keep flow fit at phone size in portrait and landscape. Whether this feels like play or bookkeeping cannot be measured here.

## Human playtest gate (E13 vertical slice)

Play both models in A/B sessions with the same seeds, and use the trial log to attribute each choice. Adopt the deck unless one of these holds; otherwise fall back to §15's alternative (persistent equipment, drawing only tactical cards):

- Players report frustration with the draw ("I never get my ball") more often than they report interesting choices.
- Players keep or cycle in fewer than about a third of frames once past onboarding, which would mean the extra decisions are ignored.
- A model change costs more frame time than the decision is worth (measured per frame against the direct model).
- Players prefer direct selection when asked after both sessions.

## Unresolved questions

- **Special-ball ceiling:** keep reshuffle-driven reuse, or add per-card charges or per-match caps? (See observation 2.)
- **Hand and deck size:** is a four-card hand right when a frame has at most two rolls? What is the right relationship to the 16-card cap and two copies per identity (E08)?
- **Tactical timing:** §15 lets each tactical card say whether it is played before or after a throw. Lab Focus is before-throw only. After-throw tactics need a post-roll window in the flow (E17/E18).
- **Keep across matches:** this build drops the kept card at match end, because §15 says the deck recombines at match start. Confirm, or carry it over.
- **Money:** Coin-style payout cards only make sense once the E08 economy exists. Their value against score cards is untested.
- **Saves:** `to_dict`/`from_dict` preserve the order, piles and RNG state. E10 must save the deck at a frame boundary or after a committed play, so a committed card can never be replayed through a reload.
