# E02 rules and data contracts

Version 1 is a deliberately small executable contract, not the complete item catalogue. `content/catalogue.json` is the production registry and currently has **zero** items. `content/fixtures` is test data, excluded from catalogue counts. The full 270-definition target and six Leagues are unchanged. E17 authors production definitions; E18 extends the closed effect vocabulary with tested mechanics.

## Identity and content

Stable IDs use `category.snake_case`, lowercase ASCII, such as `pin.wood`. They are permanent identities, never display names or array indices. Do not reuse retired IDs. Changing data shape or semantics requires a schema version change and a migration at the persistence boundary (E10); unknown versions fail now.

The JSON schemas in `content/schemas` are the machine-readable contracts. `src/contracts/contracts.gd` executes their closed subset: type, properties, required, additionalProperties=false, items/count bounds, string length/pattern, enum, and finite numeric bounds. This is not a general JSON Schema implementation; adding a keyword requires validator/tests in the same change. Catalogue semantic checks additionally reject duplicate IDs, invalid category prefixes, invalid incompatibility references, malformed effect/owner combinations, resale above purchase, and false completeness claims. Legendary pool weights are zero for the reward-only initial policy. Prices and weights are unbalanced fixtures, not final economy tuning.

Every item declares category, rarity, weight, unlock condition, Division, prices, effects, limits/charges/exhaustion, downside, tags, incompatibilities and asset references. `charges=0` means no charge limit. Availability is independent of rarity. Unlock prerequisites reference future boss/championship/mastery gate IDs; E15 owns the gate registry, reachability/cycle checks and eligibility evaluation. They are not yet treated as catalogue item references.

Completeness separately tracks authored, mechanics, automated validation, artwork, effects/audio, unlock assigned, and integrated. The fixture leaves all false. No assets are claimed complete; asset existence/quality auditing remains E19/E27. Empty production data passes shape validation without implying content completeness.

## Input and simulation boundary

`launch` records contain version, unique caller-assigned launch ID, ball ID, roll index, normalized start/target x (-1 left, +1 right), a unit direction vector with positive forward component, power in [0,1], signed spin in [-1,1], and frozen ring radius normalized to lane half-width. These are logical lane coordinates, independent of pixels or engine meters. E04 maps to physical units; E05 decides gesture thresholds and clockwise sign mapping. Ring center forward plane is configured by the lane. Zero power is representable but the input layer must decide whether the gesture commits or cancels.

`roll_result` records identify the exact originating launch/ball/roll and list unique newly fallen rack positions 1–10 plus accuracy. Positions retain their original rack identity after motion. `validate_result_for_launch` rejects mismatches. The frame resolver additionally rejects pins credited in two rolls. Simulation owns causal attribution and accuracy measurement; the contracts do not infer either from a visual effect. Results cross the boundary as copied JSON-compatible data, never live scene nodes.

## Resolution boundary

`FrameRules.resolve(frame)` accepts `schema_version`, ten `pins`, one strike roll or two completed non-strike `rolls`, and zero to five ordered `charms`. Each pin has position, item_id, effects and optional retriggers; each roll has roll_index, ball_id, fallen_positions, accuracy and effects; each Charm has item_id and effects. `validate` is executable frame-shape validation. Only completed frames resolve. Callers must validate and hydrate item effects from the registry; UI cannot inject arbitrary effects.

Each effect has op, amount, trigger and scope. Supported ops are add_value, add_mult, multiply_mult, payout and grow_value. Supported lifetimes are roll, frame, match and run (run means League attempt; never Career). Scopes identify lifetime; this pure single-frame resolver does not enforce match/attempt quotas. Future owners must supply eligible effects and persist used counters. Do not interpret metadata as implemented cross-frame limits.

The trigger is eligibility: fallen, standing, ball, charm, or unconditional after_bank. Payout/grow_value can activate on those owner-appropriate triggers and always defer their mutation until after banking. Only payout/grow_value may use after_bank. This distinction lets a Gold/Grower pin require falling without altering the score mid-chain. Retriggers repeat only fallen Value/Mult effects, bounded at eight per pin; they never repeat payout, growth, physics or another retrigger. Selecting retrigger targets from actual collisions is later work.

Ordering is category → fallen pins by original position (including repeats) → standing pins by position → balls by roll index → best frame accuracy once → Charms in slot order → floor(Value × Mult) once at bank → deferred mutations. Declared effect-array order is preserved. The result returns ok, schema_version, category, pin_value, mult, integer score, ordered events and future_effects, or ok=false/errors. Event sources identify pin position, roll index or Charm slot; phase, op, amount, scope and repeat annotate effect events. Category, accuracy and bank events have their specific payloads. Event array order is authoritative. Presentation observes copies and never changes rules/RNG.

Godot JSON parsing represents numbers as floats; integer fields accept only finite integral values. Round-trip comparisons preserve numeric value and event order, rather than requiring an engine integer/float storage tag.

The current numeric range is finite nonnegative effect amounts up to one million, positive multipliers, and banked scores within the exact JSON integer range (2^53−1). Oversized scoring chains return an error instead of silently overflowing. A later large-number representation must be explicit. No random number generator is consumed here; probabilistic breakage and all physical operations remain future mechanics.

## Commands and evidence

`python3 tools/qa.py unit` exercises invalid data, JSON round-trips and pure scoring. `content` lints the actual production registry. `integration` hydrates a frame from catalogue and launch/result fixtures and verifies its score and serialized events. These are headless contract tests, **not gameplay E2E**. E03 supplies real input-driven E2E. All commands use the pinned Godot engine and fail on engine script errors or a missing completion marker.
