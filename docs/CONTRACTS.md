# E02 rules and data contracts

Version 1 is a deliberately small executable contract, not the complete item catalogue. `content/catalogue.json` is the production registry; since E13 it holds batch **E13-S01** (25 definitions, catalogue v2; see the E13 section and ADR 008), with artwork and effects/audio still false. `content/fixtures` is test data, excluded from catalogue counts. The full 270-definition target and six Leagues are unchanged. E17 authors production definitions; E18 extends the closed effect vocabulary with tested mechanics.

## Identity and content

Stable IDs use `category.snake_case`, lowercase ASCII, such as `pin.wood`. They are permanent identities, never display names or array indices. Do not reuse retired IDs. Changing data shape or semantics requires a schema version change and a migration at the persistence boundary (E10); unknown versions fail now.

The JSON schemas in `content/schemas` are the machine-readable contracts. `src/contracts/contracts.gd` executes their closed subset: type, properties, required, additionalProperties=false, items/count bounds, string length/pattern, enum, and finite numeric bounds. This is not a general JSON Schema implementation; adding a keyword requires validator/tests in the same change. Catalogue semantic checks additionally reject duplicate IDs, invalid category prefixes, invalid incompatibility references, malformed effect/owner combinations, resale above purchase, and false completeness claims. Legendary pool weights are zero for the reward-only initial policy. Prices and weights are unbalanced fixtures, not final economy tuning.

Every item declares category, rarity, weight, unlock condition, Division, prices, effects, limits/charges/exhaustion, downside, tags, incompatibilities and asset references. `charges=0` means no charge limit. Availability is independent of rarity. Unlock prerequisites reference future boss/championship/mastery gate IDs; E15 owns the gate registry, reachability/cycle checks and eligibility evaluation. They are not yet treated as catalogue item references.

Completeness separately tracks authored, mechanics, automated validation, artwork, effects/audio, unlock assigned, and integrated. The fixture leaves all false. No assets are claimed complete; asset existence/quality auditing remains E19/E27. Empty production data passes shape validation without implying content completeness.

## Input and simulation boundary

`launch` records contain version, unique caller-assigned launch ID, ball ID, roll index, normalized start/target x (-1 left, +1 right), a unit direction vector with positive forward component, power in [0,1], signed spin in [-1,1], and frozen ring radius normalized to lane half-width. These are logical lane coordinates, independent of pixels or engine meters. E04 maps to physical units; E05 decides gesture thresholds and clockwise sign mapping. Ring center forward plane is configured by the lane. Zero power is representable but the input layer must decide whether the gesture commits or cancels.

`roll_result` records identify the exact originating launch/ball/roll and list unique newly fallen rack positions 1–10 plus accuracy. Positions retain their original rack identity after motion. `validate_result_for_launch` rejects mismatches. The frame resolver additionally rejects pins credited in two rolls. Simulation owns causal attribution and accuracy measurement; the contracts do not infer either from a visual effect. Results cross the boundary as copied JSON-compatible data, never live scene nodes.

## E04 simulation records

E04 maps logical launches to physical units (see [ADR 002](decisions/002-throw-lab-physics.md)). The simulated `start_x` range is ±0.795; anything wider would put the ball over the gutter, so the lane rejects it rather than clamping. Only `ball.house` is simulated; any other ball is rejected explicitly, never ignored. `power` maps linearly to 4.5–9.0 m/s. `spin` (E05, [ADR 003](decisions/003-spin-curve-input.md)) is positive when clockwise as the bowler sees it, and hooks the ball right (+x). It is side rotation about the travel axis at up to 15 rad/s, acting through the lane oil pattern. A shot is curved when |spin| ≥ 0.25 (`LaneSpec.is_curved`); rules must use that function, never a visual judgement. `target_x` is where the player put the ring, and `ring_radius` is the ring's size frozen at release. Accuracy measures where the ball center crosses the ring plane and grades it with those frozen values (perfect ≤ 0.08, sweet ≤ 0.16, otherwise clean when inside). Gestures and the accessible controls build launches through the same `LaunchMapper` path.

`knockdown_log` (schema `knockdown_log.schema.json`, version 1) is the simulation's causal record for one roll, crossing the boundary as JSON data:

- `knockdowns`: credited pins in fall order, each with `sequence` 1..n, physics `tick`, `cause` (`ball` depth 1, `pin` with `source_position` and depth = source + 1, or `environment` depth 0), and `reason` (`tilt`, `off_deck`, `lean`).
- `standing`: survivors. Credited and standing pins partition the racked pins.
- `gutter` plus `voided_positions`: a ball that left the lane before touching any pin credits nothing; the pins it disturbed are respotted and listed as voided.
- `target_crossed`/`target_offset` (normalized, relative to lane center), `settle` (`settled` or `timeout`), and the roll's `ticks`.

Semantic validation rejects double credit, gaps or reordering in the sequence, cause/source/depth mismatches, unknown source pins, credit on a gutter ball, voids without a gutter, and an offset on an uncrossed target. `Contracts.validate_log_for_result` requires the log to credit exactly the result's `fallen_positions` for the same launch, ball and roll. Future mechanics (Echo, Spark, Ghost, Crown, Gold) should read attribution and order from this log, not from visuals.

Rack state (`rack_after`) is simulation-internal version 1: `{schema_version, standing: [{position, x, f}]}` in lane meters, where survivors are re-spotted upright. It is not yet a validated persistence schema. E10 freezes it with a migration, and persisting it with full-precision JSON reproduces roll two exactly.

Enum checks compare numbers by value, so an engine-built record holding int `1` matches a schema's JSON-decoded `1.0`. Booleans never match numbers.

## Resolution boundary

`FrameRules.resolve(frame)` accepts `schema_version`, ten `pins`, one strike roll or two completed non-strike `rolls`, and zero to five ordered `charms`. Each pin has position, item_id, effects and optional retriggers; each roll has roll_index, ball_id, fallen_positions, accuracy and effects; each Charm has item_id and effects. `validate` is executable frame-shape validation. Only completed frames resolve. Callers must validate and hydrate item effects from the registry; UI cannot inject arbitrary effects.

Each effect has op, amount, trigger and scope. Supported ops are add_value, add_mult, multiply_mult, payout and grow_value. Supported lifetimes are roll, frame, match and run (run means League attempt; never Career). Scopes identify lifetime; this pure single-frame resolver does not enforce match/attempt quotas. Future owners must supply eligible effects and persist used counters. Do not interpret metadata as implemented cross-frame limits.

The trigger is eligibility: fallen, standing, ball, charm, or unconditional after_bank. Payout/grow_value can activate on those owner-appropriate triggers and always defer their mutation until after banking. Only payout/grow_value may use after_bank. This distinction lets a Gold/Grower pin require falling without altering the score mid-chain. Retriggers repeat only fallen Value/Mult effects, bounded at eight per pin; they never repeat payout, growth, physics or another retrigger. Selecting retrigger targets from actual collisions is later work.

Ordering is category → fallen pins by original position (including repeats) → standing pins by position → balls by roll index → best frame accuracy once → Charms in slot order → floor(Value × Mult) once at bank → deferred mutations. Declared effect-array order is preserved. The result returns ok, schema_version, category, pin_value, mult, integer score, ordered events and future_effects, or ok=false/errors. Event sources identify pin position, roll index or Charm slot; phase, op, amount, scope and repeat annotate effect events. Category, accuracy and bank events have their specific payloads. Event array order is authoritative. Presentation observes copies and never changes rules/RNG.

Godot JSON parsing represents numbers as floats; integer fields accept only finite integral values. Round-trip comparisons preserve numeric value and event order, rather than requiring an engine integer/float storage tag.

The current numeric range is finite nonnegative effect amounts up to one million, positive multipliers, and banked scores within the exact JSON integer range (2^53−1). Oversized scoring chains return an error instead of silently overflowing. A later large-number representation must be explicit. No random number generator is consumed here; probabilistic breakage and all physical operations remain future mechanics.

## E06 frame assembly and readable resolution

`FrameBuilder.build(loadout, catalogue, reports)` turns a completed frame's LaneWorld reports into a `FrameRules` frame. A frame is complete after a first-roll strike or a second roll. The builder:
- Revalidates each report's launch, result and knockdown-log contracts.
- Hydrates every pin, ball and Charm effect from the catalogue by stable ID; neither UI nor loadout can carry effects.
- Applies `FrameRules.validate`, which, among other checks, refuses a pin credited in both rolls.

The throw lab's loadout is ten `pin.wood` and `ball.house` from `content/fixtures/lab_catalogue.json`. That is a lab fixture outside the production registry, with every completeness flag false. E17/E18 replace it with authored items and Charms.

`ScoreLog.steps(result, frame, names, owners)` translates the authoritative event list into ordered calculation steps:
- The category base comes first, then fallen pins in rack order (with retriggers), standing pins, balls, the single best accuracy award, Charms, the single bank, and deferred effects last.
- Each step carries a text line, a symbol (`+` add, `×` multiply, `=` base or bank, `→` deferred), the pin to highlight, and the running Pin Value and Mult the resolver recorded.
- The score panel only reveals these steps (1×/2×/4×, or Skip), so presentation can never change a banked score. Unit tests and J03 compare every displayed number with an independent resolution.

## E07 equipment state (provisional, ADR 004)

Two equipment models share one interface: `start_match`, `start_frame(retain)`, `options()`, `play(uid, roll_index)`, `can_cycle`/`cycle(uid)`, `can_retain`, `counts`, `to_dict`:
- `CardDeck` (`src/rules/card_deck.gd`, model `"deck"`) is the experimental draw-and-cycle deck. Its saved form is `{schema_version: 1, model, cards: {uid: item_id}, draw_pile (last = top), hand, discard, exhausted, frame, cycled, reshuffles, tactical_rolls, seed, rng_state}`. `seed` and `rng_state` are decimal strings, so JSON cannot round the 64-bit values. `from_dict` continues the exact same shuffles.
- `DirectLoadout` (`src/rules/direct_loadout.gd`, model `"direct"`) is the comparison model: House plus two specials with two uses each per match, and directly chosen tactical items.

How the deck plays:
- Card uids (`card-N`) are stable per copy. The item id's category prefix decides how a card plays: `ball.` goes to discard after use; `consumable.` is exhausted for the run, at most one per roll.
- The House ball is never a card, and `ball.house` is thrown whenever nothing is armed.
- Every shuffle uses only the deck's own RNG stream, over uid-sorted piles, so physics and other systems never consume it.

`FrameBuilder.build(loadout, catalogue, reports, tactics)` takes `tactics` as roll index → tactical item ids. It appends their catalogue effects (category `consumable` only) to that roll's effects. It returns `owners` (roll index → the item id behind each roll effect), which `ScoreLog` uses to credit each step to the card that supplied it. Payout and growth steps keep the banked score on show. The lab fixture balls (`ball.lab_value`, `ball.lab_mult`, `ball.lab_coin`) are simulated with House physics (`LaneSpec.SIMULATED_BALLS`); any other ball id is still refused at commit.

## E08 run economy state (ADR 005)

`RunInventory` (`src/rules/run_inventory.gd`) is a League attempt's owned state, never Career-scoped. Its saved form (`to_dict`, schema 1) is:
- `money` and `match_number`.
- `rack`: positions "1".."10" mapped to entries.
- `reserves`: two entries or null.
- `charms`: an ordered list of entries.
- `cards`: uid mapped to entry, plus `next_card`.
- `ledger`: rows of `{match, kind, amount, item_id}`.

An entry is `{item_id, paid, mod, mod_paid}`. `paid` is the price actually paid (0 for the kit), and sale values derive from it. `mod` is the attached modification ("" for none), at most one per pin or ball card.

Places are refs: `rack:N`, `reserve:N`, `charm:N`, `card:<uid>`. Purchases go through `placements(item_id)`, which lists each possible target with what it would displace (`moves_to`) or replace and sell (`replaces`, `sale`). `place` accepts only a listed target, so nothing is dropped silently.

`Shop` (`src/rules/shop.gd`, schema 1) saves its offers, visit, rerolls this visit, Division, unlocked prerequisites, selection log, seed and RNG state, with seed and state as decimal strings. `ineligibility(item, inventory)` is the executable eligibility rule. `plan(index, inventory)` previews a purchase without changing anything. `buy` and `remove_card` refuse without changing state.

`FrameBuilder.build(loadout, catalogue, reports, extras)`:
- Now hydrates `loadout.pin_mods` (position → `pin_mod` id) into that pin's effects.
- `extras` (roll → item ids) accepts `consumable` and `ball_mod` items.
- `owners` is keyed by event source (`pin:3`, `roll:1`). `ScoreLog` uses it to credit each step, deferred payouts included, to the item that supplied it. Charm steps are named ("Charm 1 Lab Tally +2 Mult").

`RunInventory.credit_frame(result, frame)` credits every payout in `future_effects` once, since FrameRules never retriggers payouts.

## E09 Division state (ADR 006)

A Division spec (`content/fixtures/lab_division.json`, schema 1) has `division`, `name`, `frames_per_match` and three `matches` (opener, feature, boss), each `{id, kind, name, target}`. The boss names a `rival`. Each rival is `{id, name, initials, color, rule, intro, first_clear: {unlocks, text}, reactions}`, and its `rule` must be a catalogue `boss_rule`. `DivisionRun.validate_spec` checks the order, rising targets, the boss's rival and the rule category.

`DivisionRun` saves `{schema_version, practice, match_index, match_score, frames_played, results: [{id, kind, target, score, frames, won}], outcome, started}`. `record_frame(banked)` ends a match the moment its target is reached, or when the budget is spent. It refuses frames after the match is over.

`RivalRules.bank(rule_ids, result)` returns what the match banks plus explanatory notes, and leaves the FrameRules result unchanged. Unknown rule ids are refused. The score log shows a rule as an extra `rule` step with symbol ✕.

The lab's scored-frame record now also carries `banked`, `match_score`, `match_over` and `match_won`. The session fixture adds `attempt` and `outcome`, and banks `banked` points.

## E10 save files (ADR 007)

Saves live in one directory: `user://saves`, or the shell's `--save-dir=`.
- **Files:** `attempt.json` and `career.json`, each with a `.bak` (the previous good save). A `.corrupt` file is a quarantined unreadable save; a `.tmp` file is an unfinished write and is ignored.
- **Envelope:** `{format: "roguewood", kind, schema_version, sequence, checksum, payload}`. `payload` is canonical JSON text (sorted keys, full float precision) and `checksum` its SHA-256. `SaveStore` writes through a verified temporary file and refuses newer or gapped versions.

**Attempt payload (schema 1)** is `{attempt, seed, phase, content: {catalogue, division}, lab, run, shop, division, equipment}`:
- `phase` is one of aim, committed, roll_resolved, frame_done, shop, intro, division_over.
- `content` holds SHA-256 hashes of the catalogue and Division spec files.
- `run`, `shop`, `division` and `equipment` are those modules' own `to_dict` forms (`CardDeck` or `DirectLoadout`, with `model`).
- `lab` has frame_number, roll_index, match_number, match_frame, total_score, launch_serial, rack (full precision), frame_reports, frame_tactics and frame_mods (roll → ids), kept_last_frame, equipment_model and settlement, plus three phase-specific fields:
  - `pending` `{launch, input}` in `committed`;
  - `last_scored` `{steps, title, banked, category, score, income, match_over, match_won, frame_number}` in `frame_done`;
  - `result` `{title, body, won}` in `division_over`.

`AttemptSnapshot.validate` refuses a payload with unknown phases, missing fields, or item ids absent from the current catalogue. Changed content hashes only produce a warning.

**Career payload (schema 1)** is `{first_clears: {rival_id: {attempt}}, unlocked: [gate ids], intros_seen: {rival_id: true}}`. `CareerProfile.record_first_clear` is idempotent.

**Career payload (schema 2, E15, ADR 010)** adds `awards` (gate → {source, career_attempt}), `attempts` (the uid counter), `championships` (league → {wins, first_attempt, last_attempt}), `mastery` (objective → {career_attempt}), `totals` (metric → count), `tally` ({uid, frame, practice, counts, materials}), `records` (league → {attempts, practice_attempts, best_division, best_total, best_frame, practice_best_frame, wins}) and `items` (item → {first_attempt, attempts, league_wins, last_attempt, last_win}); `first_clears` entries gain `career_attempt`. v1 migrates by adding the keys. Attempt snapshots may carry `career_attempt` (additive within attempt schema 2).

**Unlock registry (schema 1)**, `content/career/unlocks.json`: `{leagues: [{id, name, content_set, access: [gates], championship: {gates, text}}], gates: [{id, kind (boss|championship|mastery), name}], objectives: [{id, name, text, metric (strikes|spares|curved_strikes|pin_materials), threshold, scope (career|attempt), prerequisites, gates, reward}], counters: {boss rule → [synergy tags]}}`. `UnlockGraph.build` validates it with the catalogue and the Leagues' rivals.

`tests/fixtures/saves/v1` holds the frozen golden saves that every later version must load.

## E13 content contract v2 and the slice (ADR 008)

**Catalogue v2** (`schema_version: 2`) adds, all optional and closed:
- `effect.condition`: `category` (array of open/spare/strike), `match_frame` (1–8), `standing_count` (0–10), `curved` (bool), `all_house` (bool), `streak_min` (1–100). Every key must hold. Not allowed on `after_bank` or `match_end` effects.
- `effect.per`: `growth`, `retriggers`, `fallen` or `standing`, optionally `:<item id>` (which must exist). Only additions and growth scale.
- op `retrigger` (trigger `ball`, whole amount 1–8, never scaled): repeats the scoring effects of the roll's first directly knocked-down pin.
- trigger `match_end` (Charms only, op `grow_value` only).
- `item.physics`: balls `{mass_scale 0.5–2, spin_response 0–2}`, pins `{mass_scale, bounce 0–0.6}`; other categories have none.
A v1 catalogue using any of these is refused.

**Frame v2** (`FrameBuilder.build(loadout, catalogue, reports, extras, context)` always emits it): frame `context {match_frame, strike_streak}` (consecutive strikes before this frame); pin and Charm `growth`; roll `first_direct` (0–10, must have fallen that roll) and `curved`. The resolver returns `strike_streak` (after this frame) and `retriggers`. Events gain `effect_index`, and `count`/`base`/`per`, `condition` and `cause` (the roll behind a retrigger) when they apply. v1 frames resolve exactly as before.

**Run state:** each owned entry has `growth`; the run has `strike_streak`. `apply_frame(result, frame)` banks growth and the streak; `settle_match` also grows match-end Charms and reports `grown`. `move_charm_left(slot)` reorders Charms. Missing fields default to 0.

**League spec** (`content/slice/league.json`, schema 1): `{id, name, batch, kit: {id, name, pins[10], deck, money}, divisions: [DivisionRun specs numbered 1..n]}`. `LeagueRun.validate` adds rising targets across Divisions and no repeated boss (rival) unless that Division has `championship: true` (E14); distinct bosses may share a rule. `LeagueRun` saves `{schema_version, index, practice, done: [DivisionRun dicts], current}`; `results` lists every match with its `division`. `division_cleared()` marks a beaten boss that is not the last; `upcoming()` describes the next match for previews.

**Boss rules:** `RivalRules` maps `boss_rule.clean_sweep` and the lab fixture to Clean Sweep, and `boss_rule.dead_straight` to Dead Straight (`spin_disabled`, `constrain_launch` → spin 0 before the launch is saved or simulated).

**Content sets** (`ContentSet.load_set("slice"|"lab")`): `{id, name, catalogue, divisions, kit, hashes, errors}`; the shell takes `--content=`.

**Attempt payload schema 2** adds `content_set` and stores `division` as the League dict. The store's migration v1 → v2 sets `content_set: "lab"` and wraps the v1 Division as a one-Division League. `AttemptSnapshot.validate(payload, catalogue, content_set)` refuses a save from another content set.

## Commands and evidence

`python3 tools/qa.py unit` exercises invalid data, JSON round-trips, pure scoring, lane geometry, knockdown bookkeeping and gesture recognition. `physics` runs launch fixtures through real Jolt worlds (see DEVELOPMENT.md). `content` lints the actual production registry. `integration` hydrates a frame from catalogue and launch/result fixtures and verifies its score and serialized events. These are headless contract tests, **not gameplay E2E**. E03 supplies real input-driven E2E. All commands use the pinned Godot engine and fail on engine script errors or a missing completion marker.
