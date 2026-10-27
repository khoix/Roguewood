# ADR 008 — E13 vertical slice: content contract v2, the slice League and content sets

Status: accepted for E13 on 2026-10-27 (owner merge is approval, AGENTS.md). It follows design §4 (run and kit), §6 (fixed resolution order, effect scopes), §7–§9 (the first four balls, six pins and ten Charms), §10/§18 (bosses as named rivals), §13 stage 3 (two Divisions, six matches, shop, save/resume, two bosses, four balls, six pins, twelve Charms; "at least three distinct viable builds") and §15 (starting deck, item economy fields). **Targets, prices and item numbers are provisional** inputs for E24 balance, not tuned values. Device feel, the human playtest and the final equipment-model decision remain open gates (see "Gates").

## Content contract v2 (catalogue and frame)

Catalogue `schema_version` 2 and frame `schema_version` 2 extend the closed effect vocabulary. Version 1 data stays valid and resolves exactly as before; a v1 catalogue or frame may not use any v2 field (refused).

- **Conditions** — `effect.condition`, every key must hold:
  - `category`: frame categories the effect needs (Finisher: strike; Spare Change: spare);
  - `match_frame`: the frame of the match (Last Chance: 2);
  - `standing_count`: pins standing at frame end (Lone Survivor: open with exactly 1);
  - `curved`: a roll's committed spin reached the documented threshold, `|spin| ≥ 0.25` (Hook Artist);
  - `all_house`: every roll used the House Ball (House Favorite);
  - `streak_min`: consecutive strikes including this frame (Turkey Club: 3).
  A deferred (after-bank, match-end) effect cannot be conditional.
- **Per-count scaling** — `effect.per` multiplies the amount: `growth` (the owner's counter), `retriggers` (repeats performed this frame), `fallen`/`standing`, optionally `:item_id` (Gold Rush: per Gold pin down; Standing Order: per standing Anchor). A zero count applies nothing. Multipliers and payouts never scale (no runaway economy).
- **Retrigger** — op `retrigger` on a ball (Echo): repeats the scoring effects of the **first pin the ball knocked down directly** that roll (`roll.first_direct`, from the knockdown log's earliest `ball` cause), in that pin's rack slot (§6 step 2). Retriggers never repeat income or growth (§15), and a pin's repeats are capped at 8. The log names the cause: "Pin 5 Ruby Pin +2 Mult (retrigger 1 · Roll 1 Echo Ball)".
- **Growth** — op `grow_value` adds to the owner's run counter after banking; trigger `match_end` grows a Charm after each completed match (Patient Investor). `RunInventory` keeps `growth` on each owned entry (it moves with the pin and is lost on sale) and applies it with `apply_frame`/`settle_match`. Grower: +10 Value, +5 Value per growth, grows +1 when knocked down.
- **Strike streak** — the run keeps `strike_streak` across matches; the frame `context` carries the streak before the frame and `match_frame`. Any non-strike resets it.
- **Physics profiles** — optional `item.physics` on balls (`mass_scale`, `spin_response`) and pins (`mass_scale`, `bounce`), applied per roll by `src/simulation/item_physics.gd` and `LaneWorld.setup(..., item_physics)`. Items without a profile keep the House/Wood values exactly: the E04/E05 physics digest `75d1a3c0…` is unchanged.
- **Events** carry `effect_index` (the score log names the exact item behind each effect), and `count`/`base`/`per`, `condition` and `cause` when present. `ScoreLog.item_text` states every rule ("×2 Mult (strike)", "+2 Mult per Gold Pin down", "hook ×1.6") on hand cards and their inspection and on shop offers, where long texts are still clipped (playtest defect 9).

## Production batch E13-S01 (`content/catalogue.json`)

25 definitions with stable ids, all `authored`, `mechanics`, `automated_validation` and `unlock_assigned`; **`artwork`, `effects_audio` and `integrated` are false** (E19/E20). They are the first production entries; the release counts in the checkpoint start here.

| Family | Items |
|---|---|
| Balls (4) | House (unlimited, outside the deck), Hook (spin response ×1.6; overcurves), Hammer (mass ×1.35, spin response ×0.6), Echo (first-direct-pin retrigger) |
| Pins (6) | Wood (+10), Ruby (+10, +2 Mult), Gold (+10, +$1), Anchor (+10 down, +3 Mult standing; mass ×1.6), Grower (+10, +5 per growth), Rubber (+10; bounce 0.45 vs 0.25) |
| Charms (12) | the ten of §9, plus two authored: **Encore** (+3 Mult per retrigger; Echo family; unlocked by The Surveyor) and **Standing Order** (+2 Mult per standing Anchor; standing family; unlocked by The Custodian) |
| Boss rules (2) | Dead Straight, Clean Sweep |
| Kit (1) | House Kit |

Prices follow the §15 bands (common $3–5, uncommon $5–7, rare $7–10). Wood and House are not sold in the shop (pool weight 0).

## The slice League (`content/slice/league.json`)

- **Kit:** ten Wood pins, the House Ball outside the deck, and the §15 standard deck of six special-ball cards: two each of Hook, Hammer and Echo. $6, five empty Charm slots, two empty reserves.
- **Division 1:** opener 300, feature 500, boss **The Surveyor** 800 — *Dead Straight*: charged spin is disabled. The launch is constrained before it is saved or simulated (`RivalRules.constrain_launch`), the assist spin control locks, the spin meter reads zero, the aim label reads "Spin disabled", and the status says so. Hook Artist and the Hook Ball's advantage vanish; Hammer and straight-line placement are the counterplay.
- **Division 2:** opener 1100, feature 1600, boss **The Custodian** 2400 — *Clean Sweep*.
- **First clears:** a boss beaten **mid-League** banks its Career reward at once (Career written before the attempt's shop checkpoint), announced in the shop; the attempt continues to the next Division's opener. Unlocks reach the shop pool from the **next** attempt (§16, ADR 007). No boss repeats within an attempt (§15) unless its Division is an explicit `championship` (the E14 generator's flag), which may bring back a boss already met; distinct bosses may share a rule.
- **`LeagueRun`** (`src/rules/league_run.gd`) chains Division specs in the DivisionRun format and answers DivisionRun's questions (so the lab, HUD and saves drive either). E14 generates more Divisions in the same format; LeagueRun consumes them unchanged.
- **Division 2 targets** were set with the strategy simulation (below): high enough that buying nothing never wins, low enough that several intentional builds do at ordinary accuracy. They are not a measured human curve.

## Content sets (`src/rules/content_set.gd`)

- `slice` (default): the production catalogue and League above.
- `lab` (`--content=lab`): the E06–E10 fixtures, the single lab Division and lab kit. Mechanism journeys (J02–J05, J07, J08) keep them, so their exact expectations (560/240/70, 21060, J07's ten stages) still hold.
- Content validation (`qa.py content`) checks both sets: catalogue, League (Division order, rising targets across Divisions, no repeated boss outside a championship, known rules) and kit (ten catalogue pins, ball/tactical deck cards, two copies at most, House outside the deck).

## Saves

Attempt schema **2** records `content_set` and stores the League (`{index, practice, done, current}`). The registered migration v1 → v2 marks every v1 save as lab content with a one-Division League; the frozen v1 golden saves still load exactly. A save is offered only to the content set it was made with ("made with the lab content, not slice"). Run entries gain `growth` and the run `strike_streak`, both defaulting for older data.

## Other integration

- **Charm order** can be changed in the shop (◀ Move … before …; §4, §6: "the interface previews this ordering consequence"); each move is a saved shop transaction.
- **Pin materials:** slice pins get a per-item finish and colour on the lane (developmental; shape markings and final art are E19). Lab racks now show all Wood truthfully instead of E12's alternating study finishes.
- **Rival portrait:** E12's Custodian atlas appears only in Divisions whose rival is The Custodian, with that rival's own lines. The Surveyor has no original portrait yet (E21) and keeps the HUD bubble.
- **Retry** reads "Retry League" when the League has several Divisions.

## Strategy simulation (`tools/slice_strategies.gd`, `qa.py slice`)

400 seeded attempts per strategy play the real inventory, shop (its own seeded stream), deck, League, rules, builder and resolver. Only pinfall is synthetic: an ordinary-player model (strike 28% with House at the pocket; Hammer +10 points; Hook +8 when it can spin, with a 10% overcurve; any curve +5; −3 per racked Anchor; spare 40%; a deliberate single-pin leave 50%; head pin first 75% of the time). The same throws are dealt to every strategy on a seed. Strategies buy, place, order (additions before multipliers) and throw towards one build and adapt to Clean Sweep by clearing the rack.

Results (400 runs each; `artifacts/e13/slice-strategies-{locked,unlocked}.json`, CI artifact `journeys`):

| Strategy | Win (fresh Career) | Win (both unlocks) | Division 1 cleared | Mean banked frame | Mean non-strike frame |
|---|---:|---:|---:|---:|---:|
| Strike chain (Ruby; Flat Bonus, Finisher, Turkey Club; Hammer) | 43.0% | 39.0% | 80.5% | 1084.0 | 693.1 |
| Echo-Ruby retrigger (Ruby on the head pin; Echo Ball; Encore when unlocked) | 50.2% | 50.2% | 85.3% | 1208.9 | 929.5 |
| Curve (Hook Ball, Hook Artist, Ruby) | 53.8% | 44.8% | 84.0% | 1239.9 | 734.0 |
| Gold and Grower economy (Gold Rush, Patient Investor) | 32.3% | 29.5% | 78.8% | 905.6 | 728.5 |
| Anchor standing (Anchors, Lone Survivor; clears under Clean Sweep) | 25.5% | 19.5% | 78.5% | 902.7 | 829.3 |
| Baseline: random purchases and balls | 16.8% | 14.5% | 67.3% | 759.3 | 573.6 |
| Baseline: buy nothing, House only | 0.0% | 0.0% | 26.3% | 355.2 | 246.2 |

- **Viability:** buying nothing never wins and buying at random wins about one attempt in six. Three distinct builds (strike chain, Echo-Ruby retrigger, curve) win 43–54% and the Gold/Grower economy about a third; the Anchor standing build is the weakest intentional build (about a quarter), because Clean Sweep forbids its leaves in the last match. The gate's "at least three distinct viable builds" is met **in simulation only**. The non-strike frames of the Echo-Ruby, Anchor and Gold builds outscore a plain 560 strike, as §9 asks.
- **Where attempts end:** for the five intentional builds, 44–62% of losses happen at The Custodian (Clean Sweep, the last match) and 8–14% at The Surveyor. House-only attempts mostly end at The Surveyor (45% of its losses).
- **Pool dilution:** with both rival unlocks in the pool (`--unlocked`, `slice-strategies-unlocked.json`) most builds win slightly *less*, because Encore and Standing Order dilute the Charm slots: the §16 fairness concern, recorded for E15/E24.
- **Not shown:** feel, comprehension or fun; real accuracy distributions; device timing. The §13 "10–15 minute slice" duration is unmeasured: it needs the human session.

## Gates and limitations

- **Real-device play session: BLOCKED** — no phone or mobile build in this environment (E26). The protocol and outstanding defects are in `docs/playtests/E13-slice-playtest.md`. ADR 004's equipment-model decision (deck vs direct) waits for that human session; the deck stays the default.
- The slice shop's **Tactical and Workshop slots are empty** ("Nothing available"): the slice scope has no consumables or modifications (E17/E18).
- **Rack swaps** between existing positions have rules (`swap_pins`) but no shop control yet; a bought pin is placed on a chosen position.
- No art, VFX or audio for the batch (E19/E20); no Surveyor portrait (E21).
