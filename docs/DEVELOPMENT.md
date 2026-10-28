# Development

Read AI-HANDOFF.md before changes; it records the active branch (E04 work is on `claude/roguewood-build`, derived from the E03-accepted `codex/roguewood-build`).

## Prerequisites

Install Godot 4.5.2 **standard** (not .NET) and matching 4.5.2 export templates from https://godotengine.org/download/archive/4.5.2-stable/. Verify `godot --version` begins `4.5.2.stable.`. Python 3.10+ is required (no third-party Python packages). Set `GODOT_BIN` to the executable path if it is not named godot/godot4 on PATH.

From repository root:

```sh
python3 tools/qa.py doctor
python3 tools/qa.py import
python3 tools/qa.py unit
python3 tools/qa.py content
python3 tools/qa.py integration
python3 tools/qa.py physics
python3 tools/qa.py smoke
python3 tools/qa.py export
```

`export` builds and starts Linux x86-64 debug output, requires matching templates, and is Linux-only. It does not validate iOS, Android, or Windows. Use the editor's template manager to install templates, or see the CI installation script for Linux. Outputs live in ignored build/. CI repeats doctor, unit, content, integration, physics, smoke, and export on pushes and pull requests.

Open project.godot with the pinned editor; F5 runs the shell, and Enter League opens the E04 throw lab. Hold the ball, drag to line up, circle to spin, then flick up. Mouse works through touch emulation, and Options opens the throw settings (handedness, sensitivity, reduced motion, larger targets, assist controls). It is developer scaffolding, not release artwork or the game loop. Use `"$GODOT_BIN" --path .` with your shell's environment-variable syntax for CLI launch.

E02 supplies unit, content, and contract integration suites; see [Contracts](CONTRACTS.md). The E03 e2e command supports the bootstrap J01 journey described below. E03 must implement actual UI/input-driven E2E, deterministic fixtures and failure artifacts. Logs report engine script errors even if the engine returns zero.

## Mobile feasibility

See decisions/001-foundation.md for target matrix, renderer and module boundaries. iOS export needs macOS and Xcode; Android needs Android SDK/JDK; signing and device evidence remain outstanding. No credentials or export_credentials.cfg belong in Git. Linux smoke is the bootstrap acceptance check, not a substitute for device testing.

CI verifies both downloads against tools/godot-downloads.sha512, copied from the official 4.5.2 release SHA512-SUMS.txt and verified locally. Update version and checksums together when intentionally upgrading.

## E03 native journey

`python3 tools/qa.py e2e --journey J01` drives native UI actions through menu, fixed House League/House Kit entry, deterministic reset and return. Only that initial fixture is selectable; catalogue and Career eligibility come later. `shell` remains a quick alias for the underlying script. Use `xvfb-run -a python3 tools/qa.py e2e --journey J01 --rendered` on Linux to exercise real rendering and save menu/session/reset/returned PNGs. A real desktop display also works without Xvfb. These captures document developmental UI, not final art approval.

Artifacts live in ignored `artifacts/e03/headless` and `artifacts/e03/rendered`. Per-run screenshot cleanup prevents old captures from falsely satisfying validation. Logs include state checkpoints. `--inject-failure` must return nonzero and retain the failure log (plus failure.png when rendered). State waits are bounded at two seconds; outer process timeout is thirty seconds and preserves partial output. A hung renderer may prevent a final failure screenshot, so earlier checkpoints and timeout logs are retained. CI runs both modes and uploads diagnostics even on failure. J01 is the E03 bootstrap journey, not later device/whole-game acceptance. Other journeys are rejected until implemented.

Automated J01 explicitly uses Godot Dummy audio; normal gameplay audio is unchanged. Intentional failure artifacts use separate headless-failure/rendered-failure directories. CI also runs `xvfb-run -a python3 tools/verify_diagnostics.py`, checking the deliberate failure exit, PNG signatures, failure logs, timeout partial output and strict engine-error rejection. Locally `--headless` runs the same diagnostics without screenshot assertions.

## E04 throw lab, physics fixtures and J02

`python3 tools/qa.py physics` runs `content/fixtures/throws/lab_throws.json` through real Jolt worlds headless at `--fixed-fps 60`. It checks contracts and outcome classes and requires repeated launches, aim delays and a JSON rack round trip to produce identical results. It also reports start-x sensitivity. The output is `artifacts/e04/physics.log` and `physics-report.json`, whose `digest` summarizes every outcome and final pose, so you can compare digests across machines. A run takes about 20 s.

`python3 tools/qa.py e2e --journey J02` drives the shell and throw lab through `Input.parse_input_event` touch and drag events. It covers three cancel paths (sideways only, slow, and OS-cancelled) that must consume nothing, and a touch away from the ball. It then plays a straight two-roll frame in which survivors are respotted, no pin is credited twice and the E02 `FrameRules.validate` accepts the frame, followed by Next Rack and a gutter frame. Finally it checks that both live rolls replay identically from their committed records in fresh worlds. J02 passes `--fixed-fps 60`, so gesture timing is deterministic. `--rendered` (via `xvfb-run -a` on Linux) saves aim, cancelled, rolling, roll1, roll2_aim, frame and gutter PNGs to `artifacts/e04/rendered`, and `--inject-failure` must exit 1. Expect about 1 minute rendered on llvmpipe. These captures show developmental geometry, not art approval or device feel.

## E05 curves, settings and J02 extension

J02 also covers:
- A tap on the lane that moves the target ring, and a short flick that cancels.
- A clockwise and a counter-clockwise circle gesture. Each must charge matching spin without steering the flick, contract and freeze the ring, carry the moved target, and hook more than 5 cm the matching way.
- A mouse throw, through touch emulation.
- Settings toggled through focused controls: reduced motion and assist on, then off.
- An assist throw driven only by keyboard actions on the sliders and Throw. Its launch must equal `LaunchMapper.from_controls`.
- A throw after rotating to landscape.
- A trial-log check: one complete line per committed roll, with touch, mouse and assist sources present.

J02 pins a phone-portrait window (450×800, so a 720×1280 canvas) in both modes. The project now uses stretch aspect `expand`, so the canvas follows the window; without this profile, the 64×64 headless window would turn the same injected gesture into different motion. Rendered J02 adds the target, curve_right_hold, curve_right, curve_left, assist and landscape captures, and saves `trials.jsonl` beside the screenshots. It takes about 70 s rendered on llvmpipe.

`physics` now includes curved fixtures. They check pocket hooks for both hands, that hook grows with spin, an exact mirror for opposite spin, faster throws hooking less, and spin 0 staying straight. In play, every committed roll appends to `user://throw_trials.jsonl` for the device trials in `docs/playtests/E05-device-trials.md`. Screenshots and logs are never committed; CI uploads them as the `journeys` artifact.

## E06 scoring and J03

When a frame completes, the lab scores it with `FrameRules` and plays the calculation in the score panel. The panel shows Value × Mult counters, a flat ten-slot rack coloured by the roll that took each pin, and the ordered calculation log. Speed cycles through 1×, 2× and 4× and is kept in the session settings; Skip reveals everything. Frame totals accumulate into the lab total and the shell's session fixture.

`python3 tools/qa.py e2e --journey J03` plays strike, spare and open frames through real input:
- Options toggles reduced motion and the assist controls through focused controls.
- Keyboard steps move the assist sliders, then Throw.
- The strike is position +0.10 at 70% power. The spare is −0.40 at 60%, leaving 1-3-6, then a centre throw. The open frame is the same first roll followed by a gutter.

Each frame must:
- Bank the score an independent `FrameBuilder` + `FrameRules` resolution gives (560, 240, 70).
- Match the base formula.
- List the category first and the bank last, credit each fallen pin once in rack order, and award accuracy once.
- Colour every pin by the roll that took it.
- Update the running total.

The journey also exercises speed cycling, the carried speed preference and Skip. `--rendered` saves scoring, strike, spare and open PNGs to `artifacts/e06/rendered`. The outcomes come from the deterministic physics, so a physics change that alters them fails J03 with a category message.

## E07 equipment, J04 and the experiment

The lab's card row plays the experimental deck (default) or direct selection (Options → Equipment). Switching models starts a new match on a fresh frame, or at Next Rack. The deck is seeded from the session seed.

`python3 tools/qa.py e2e --journey J04` drives the real lab with touch, mouse and keyboard on the card row and with assist throws. Frame scores are checked against an independent `FrameBuilder` + `FrameRules` resolution with the played tactical cards. The journey checks:
- The first draw (four of seven).
- Arming and disarming a card without starting a throw.
- A cycle, once per frame.
- A tactical card exhausted for the run.
- A kept card leading the next hand.
- The empty draw pile reshuffling.
- No keep at match end, then the recombine at the next match.
- House thrown when nothing is armed.
- Cards locked while the ball rolls.
- Switching to direct selection, where a special's two uses run out and leave the bag while House stays available.

`--rendered` saves the hand, keep, match_over, exhausted and direct PNGs to `artifacts/e07/rendered`. Deck order comes from session seed 1 and outcomes from the deterministic physics, so a change to either can alter which cards appear. The journey picks cards by kind rather than by position.

`python3 tools/qa.py experiment` runs the ADR 004 structural comparison: 1000 seeded runs through the real models and `FrameRules`. It writes `artifacts/e07/deck-experiment.json`, and `deck_test` checks that the experiment is repeatable.

## E08 shop and J05

After a match's second frame, Next Rack pays the match (interest on the held balance, then $3) and opens the Pro Shop:
- Five offers: Charm, Charm, Equipment, Tactical and Workshop.
- Reroll, the $3 removal service, Sell buttons, and a choice sheet for placements and replacements, with Cancel.
- Next Match recombines the deck with the purchases.

The lab's rack, Charms, deck and modifications come from the run inventory, so purchases score in the next match. The journeys from J02 to J04 now leave the shop with Next Match.

`python3 tools/qa.py e2e --journey J05` plays a match with touch, mouse and keyboard. It then checks:
- The settlement, including Lab Coin item income.
- Five eligible offers, and a touch purchase into a free Charm slot.
- A sold offer, and disabled unaffordable offers and reroll (with refused direct requests).
- An escalating reroll.
- A pin placement that moves Wood to a reserve, and a modification attached to a chosen host.
- A full Charm row: Cancel changes nothing, and replacement sells the old Charm.
- Removal, cancelled and then done.
- Selling, and buy-then-sell losing money.
- The ledger matching the wallet.
- A landscape reflow.
- Match 2 scoring with the purchases, against an independent resolution.

To reach a full Charm row in one visit, the journey grants $30 and seats four reward-only Crown Charms through the inventory API. This fixture setup is logged in the ledger. `--rendered` saves the shop, bought, funds, place_pin, full_slot, removed, landscape and match2 PNGs to `artifacts/e08/rendered`.

## E09 Division and J06

Entering the League starts attempt 1 of House League Division 1: an opener (target 300), a feature (500) and The Custodian (800, Clean Sweep), each within two frames.
- The match bar shows the match, target, score and frames left, plus an inspectable boss or rule badge.
- Crossing a target ends the match after that frame and opens the shop, which previews the next match and the boss rule.
- A missed target ends the attempt.
- The boss match opens with a skippable introduction. The rival reacts (with precedence and a cooldown) without ever taking input.
- The result screen offers Retry Division or New Attempt, and Clubhouse.
- First clears are kept in an in-memory Career record for the app run.

Options → Practice removes targets. J02–J05 use Practice.

`python3 tools/qa.py e2e --journey J06` plays three attempts with the deterministic J03 shots:
1. Win the opener and feature early (unused-frame payout), skip the introduction, throw through a reaction, and lose the boss when Clean Sweep banks an open frame as 0. Then Retry.
2. Watch the short introduction advance by itself, defeat the boss with two strikes, and bank the first clear.
3. Confirm the unlock carried over, lose the opener, check the Career record survives, then return to the Clubhouse.

`--rendered` saves the preview, shop_preview, intro, boss, lost, won and lost_again PNGs to `artifacts/e09/rendered`.

## E10 saves and J07

The game saves the attempt as one snapshot at every committed step (ADR 007):
- before a thrown roll animates;
- after each roll and frame resolves;
- after every shop transaction, cycle and frame start;
- on backgrounding.

It saves the Career separately. The Clubhouse offers **Continue Attempt** for an unfinished attempt and explains any fallback to a backup or any unusable save.

`tools/qa.py` gives every journey its own fresh `artifacts/<task>/<mode>/saves` directory (`--save-dir=`), so tests never touch your own saves. `python3 tools/qa.py unit` includes `save_test`, which checks the store, corruption, versions and migrations, snapshots, the golden v1 saves and the Career. Regenerate golden saves only when adding a new version, with `godot --headless --script res://tools/make_save_fixture.gd -- --out=<dir>`.

`python3 tools/qa.py e2e --journey J07` runs ten stages, each a **separate engine process** sharing one save directory. Each stage leaves the game at a chosen moment, and the next continues through the real menu:
1. Before a throw: after a cycle; backgrounding saves.
2. During a throw: the committed launch re-simulates and equals a clean replay; the card stays spent.
3. During score resolution: banked once.
4. After a purchase: owned once, paid once.
5. After a reroll: the same offers and price.
6. Between rolls: the same standing pins, positions exact.
7. After a boss win: the Career award is kept once and reaches the next attempt's shop pool.
8. A corrupt latest save falls back to the previous checkpoint.
9. With every copy broken, the menu says so and a new attempt starts.

Stage logs are `journey-stage<k>.log`, and `journey.log` collects them. `--rendered` saves the continue_menu, resumed_hand, resumed_roll, resumed_frame, resumed_shop, resumed_reroll, resumed_roll2, career_kept, fallback and no_save PNGs to `artifacts/e10/rendered`.

## E13 vertical slice, J06 and the strategy simulation

The game now plays the production slice by default (ADR 008): the House League's two Divisions with The Surveyor (Dead Straight, 800) and The Custodian (Clean Sweep, 2400), the House Kit (ten Wood pins; two each of Hook, Hammer and Echo; $6) and catalogue batch E13-S01. `--content=lab` selects the E06–E10 fixtures instead. `tools/qa.py` passes `--content=lab` to the mechanism journeys (J02–J05, J07, J08, and `tools/capture_motion.py`); J01 and J06 stage 1 use the slice.

In the shop, ◀ buttons move a Charm one slot left (order matters: additions before multipliers).

`python3 tools/qa.py e2e --journey J06` now has two stages, each a separate engine process with its own save directory:
1. `tests/slice_journey.gd` (slice): an Echo strike retriggers a Wood pin (600); Charms are bought and reordered; Dead Straight locks the spin control and commits a real charged circle gesture as a straight launch; beating The Surveyor clears Division 1 and banks its first clear at once; Clubhouse → Continue Attempt resumes the saved shop exactly; Division 2's targets are met; Clean Sweep banks an open frame as 0; a strike beats The Custodian and wins the League; attempt 2 has both unlocks, loses the opener and keeps the Career.
2. `tests/division_journey.gd` (lab): the E09 Division journey, unchanged.

`--rendered` saves slice_preview, slice_echo, slice_shop, slice_dead_straight, slice_cleared, slice_clean_sweep, slice_won and slice_lost_again, plus the E09 PNGs, to `artifacts/e13/rendered`.

`python3 tools/qa.py slice` runs the seeded build-strategy simulation (`tools/slice_strategies.gd`, 400 attempts per strategy, fresh Career and with both rival unlocks) and writes `artifacts/e13/slice-strategies-{locked,unlocked}.json`. Pinfall there is synthetic (see ADR 008); everything else is the real rules code.

The real-device play session is blocked; its protocol and the outstanding defects are in `docs/playtests/E13-slice-playtest.md`.

## E14 campaign

Select **House Campaign · 8 Divisions (provisional)** in the League menu, or launch
with `--content=campaign`. Attempt number is the seed. The profile uses implemented
rules with provisional encounter fixtures/targets; see ADR 009 for content limits.

`python3 tools/qa.py e2e --journey J09` (optionally `--rendered`) drives the menu,
24 real matches, a midcampaign process restart, a championship restart, endless
continuation, and loss. Captures/logs are under ignored `artifacts/e14/`.
Generator and persistence/stream tests also run in `qa.py unit`.

## E15 Career and J10

The Career (`career.json`, schema 2, ADR 010) records unlock gates and where each
came from, first clears, League championships, mastery objectives, per-League
records and the item collection. Every reward is saved the moment it is earned and
counted once. The unlock registry is `content/career/unlocks.json`; `qa.py content`
validates the whole graph (IDs, kinds, sources, loops, reachability, self-unlocks,
starting counters) and prints the availability counts. The menu shows a Career
summary and up to three goals; results list new unlocks ("joins the shop pool from
your next attempt"), titles and goals. Practice attempts grant no unlocks or
mastery progress; the toggle and the match bar say so.

`python3 tools/qa.py e2e --journey J10` runs three real engine processes sharing
one save directory, all through native input on the production slice:
1. A fresh Career: beat The Surveyor. The gate is on disk at once, while this
   attempt's pool keeps Encore locked, even after a reroll. Bank a spare in
   Division 2, then stop while the frame is shown.
2. Restart: the Career is intact and the resumed frame is not counted twice.
   Lose the attempt; the result names the unlock, the kept progress and the
   goals. Retry: the new attempt's pool has Encore. Beat The Surveyor again;
   nothing is awarded twice.
3. Restart: nothing is duplicated, and the saved attempt keeps its Career uid.
   A new attempt in Practice banks a spare that advances no mastery but records
   a practice best.

`--rendered` saves career_fresh, career_unlocked, career_spare, career_lost,
career_no_duplicate, career_practice and career_menu to `artifacts/e15/rendered`.
J09 also asserts that the campaign title is banked once, across its restarts and
Endless. The schema 2 golden Career is `tests/fixtures/saves/v2/career.json`
(`tools/make_save_fixture.gd -- --out=<dir> --career-v2`).

## E16 Clubhouse and J11

The menu is now the Clubhouse, with four tabs:
- **League Board:** League and kit choice, Continue or Enter (Try Again once played), records, titles, followed goals and the latest unlocks.
- **Binder:** every collectible as Locked, Available, Discovered or Mastered; inspect a card for what unlocks it and its history.
- **Trophies:** titles, mastery ribbons, rival plaques and club decorations.
- **Goals:** follow up to three.

Art comes by asset ID from `assets/clubhouse/<id>.png`; until E16-ART delivers it, marked placeholders name each ID. The data comes from `src/clubhouse/clubhouse_model.gd` (unit-tested in `clubhouse_test`).

`python3 tools/qa.py e2e --journey J11` runs two real engine processes on the production slice:
1. Inspect Locked and Available cards, follow a goal, then win the House League on the J06 path. Mastered cards, unlocks and the shelf appear.
2. After a restart, Try Again: buy a new Charm, lose, and see it Discovered with every reward kept. Then return to play.

`--rendered` saves clubhouse_locked, clubhouse_goals, clubhouse_mastered, clubhouse_trophies, clubhouse_discovered and clubhouse_return to `artifacts/e16/rendered`.

## E17 authored batches

Catalogue authoring batches (`content/catalogue/batches/E17-Dxx.json`, at most 12 definitions each) hold full item definitions written ahead of their mechanics:
- the catalogue v2 item;
- the exact trigger text and the new effect primitives E18 must build;
- the pool note, presentation needs for the visual brief, and asset IDs per slot.

They never enter `content/catalogue.json`, a shop, the binder or a save. E18 moves each item in when its mechanics land. `qa.py content` validates every batch against the catalogue and the prospective unlock graph, and prints counts against the release targets and the primitive list. `authored_test` (in `unit`) proves each rule refuses bad data.

## E18 mechanics batches and J03C01

E18-C01 landed six D02 Charms (Pin Counter, Hot Streak, Last Stand, Tip Jar, Banana Ball, Plumb Line) in the catalogue; their design blocks stay in the batch under `landed`.

`python3 tools/qa.py e2e --journey J03C01` seats five of them through the inventory API (logged fixture), then plays strikes, a spare and an open frame in Practice through real input. Each banked score must equal an independent resolution. `--rendered` saves c01_strike, c01_streak, c01_spare and c01_open to `artifacts/e18-c01/rendered`.

`python3 tools/qa.py e2e --journey J03C02` racks ten Glass pins (logged fixture) and checks the Glass breaks against an independent replay of the effects stream, across a real Clubhouse → Continue reload. `--rendered` saves c02_breaks, c02_reloaded and c02_second to `artifacts/e18-c02/rendered`.
