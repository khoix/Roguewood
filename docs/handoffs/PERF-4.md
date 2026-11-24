# Agent task handoff — PERF-4, the hitch at every new aim, found by name (owner, 2026-11-24)

## Assignment
- **Owner:** Claude, from the owner's phone log on PERF-3's build (Web; Resolution Low, Textures Normal; 2026-11-24 07:37–08:00).
- **State:** DONE (implementation and checks). Not tried on a phone.
- **Branch:** `claude/roguewood-build`.
- **Paths:** `src/presentation/card_inspector.gd` (`fallback_for`), `src/presentation/card_hand.gd`, `src/presentation/item_assets.gd` (`hold`), `src/presentation/throw_lab.gd` (spans, `_refresh_hand`), `src/platform/graphics.gd` (`span`, steps in the log); tests `tests/perf2_test.gd`, `tests/clubhouse_journey.gd` (J11).

## What the log showed
- **The hitch remained:** a 180–330 ms frame at almost every new aim, with 1–56 ms of script and 0–3 ms of render, so it was in button and physics handlers.
- **Also:**
  - draw-call spikes of 1,000–2,580 at some aims, intros and scoring;
  - GPU memory 100–180 MB higher during rolls than at the aim.

## How it was found
- **The log names the step:** the game's heavy steps report their time (`Graphics.span`: new roll, lane setup, hand, HUD, layout, save, next match, roll end, celebration). A long frame lists its three largest, with its texture memory.
- **What a desktop House League then showed:** on each new aim, "next match 150–210 ms, new roll 140–210 ms, hand 60–150 ms".
- **The hand's cost:** for every card dealt, the hand built the fixture illustration (`card_inspector.illustration`), a 1983 × 793 sheet decoded again each time (15–50 ms per card on desktop). Only lab fixtures without catalogue art use it; every real card threw it away.

## Changes
- **The fixture art** is built only for an item without card art (`fallback_for`), in the hand and the inspector.
- **The run's cards and Charms keep their art loaded** while they are in the run (`ItemAssets.hold`, refreshed with the hand). A card dealt again no longer decodes its full-size sheet; art leaves with the item. Cost: the deck's sheets stay in memory (about 6 MB per distinct card).
- **Log:** each long frame shows its texture memory and its largest timed steps.

## Measured (desktop House League, Divisions 1–4, log at 150 ms)
- **Before:** 10 logged long frames at a new aim or intro (180–300 ms).
- **After:** 1, the run's very first aim.
- **Remaining long frames** are shop openings (160–240 ms), where each new offer loads its card art the first time.

## Follow-ups
- **Shop openings:** offers' first art loads. The art is full-size (about 1254 px) for a card drawn at most about 550 px on a phone. Smaller imports (`size_limit`) or VRAM-compressed art would cut decoding and memory, but that is a quality call for the owner and Codex.
- **The draw-call spikes and the GPU memory during rolls:** not reproduced on desktop. The next phone log's steps and texture figures should show their source.

## Checks
- `unit` (with the new PERF-4 checks), `content`.
- J01, J02 and J04 (fixture art, both modes), J05 (both modes), J06, J11 (both modes), JTUT, J22L01, J22L02, J03C05: PASS.
