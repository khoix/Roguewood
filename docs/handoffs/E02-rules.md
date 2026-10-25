# E02 rules worker handoff

Status: REVIEW — coordinator must integrate and complete shared contract/CI validation.
Owner: e02_rules. Branch: codex/roguewood-e02-rules.
Base: f3cf20513906e0bec534fde84df25538969b3ac7.
Exclusive paths: src/rules, tests/rules_test.gd, this handoff.

## Delivered

`src/rules/frame_rules.gd` is a pure headless GDScript resolver. Public methods:

- `resolve(frame: Dictionary) -> Dictionary`: `{ok:false, errors:[String]}` on invalid input; otherwise `{ok:true, schema_version:1, category, pin_value, mult, score, events, future_effects}`.
- `validate(frame: Dictionary) -> Array[String]`: validation errors without scoring.

Frame schema v1 contains exactly `schema_version`, `pins`, `rolls`, `charms`.
Ten pins: `{position:1..10, item_id:"pin.slug", effects:[], retriggers?:0..8}`.
Completed rolls: `{roll_index:1|2, ball_id:"ball.slug", fallen_positions:[], accuracy:"miss"|"clean"|"sweet"|"perfect", effects:[]}`.
Zero to five ordered Charms: `{item_id:"charm.slug", effects:[]}`.
Effect fields: `{op, amount, trigger, scope}`. Supported operations are add_value, add_mult, multiply_mult, payout, grow_value. Amounts must be finite within 0..1e6; multiply_mult requires a positive amount. Scope is roll/frame/match/run. IDs use lowercase namespace.slug with letters/digits/underscores; each component starts with a letter.

Pins accept fallen/standing/after_bank triggers; balls accept ball/after_bank; Charms accept charm/after_bank. Unknown fields and malformed effects fail closed. after_bank permits only payout/grow_value. Activation-triggered payout/growth is queued, preserving eligibility, then emitted after the bank event. An explicit after_bank trigger is unconditional for that owner at resolution.

Events have deterministic phase/source/op/amount/scope/repeat fields plus intermediate counters where relevant. Category and bank events have their own result fields. Pin sources are original rack positions, ball sources are roll indices, Charm sources are one-based order. Arrays are copied; the caller's frame remains unchanged. Input pin order/collision order does not affect scoring event order. Charm order intentionally does.

Scoring order: category; fallen pins in rack order including explicit scoring-only retriggers; standing pins in rack order; ball effects in roll order; best accuracy once; Charms left-to-right; final multiplication and floor once; deferred payouts/growth. Non-finite scores and totals above the exact supported numeric range (2^53−1) fail explicitly.

## Validation actually run

Godot 4.5.2.stable.official.6ce3de25a headless script invoked `tests/rules_test.gd.run()`; result `RULES_CHECKS_DONE failures=0`. The coordinator's permanent runner will call the same static suite. `git diff --check` passed.

Cases include Wood strike560/spare240/open90; gutter0; Ruby/Charm3360 and reverse2800; standing scoring; best accuracy once; fractional final rounding; bounded scoring retriggers without repeated growth/payout; deferred mutation ordering; standing-reward eligibility; exact event sequence; repeated identical results; input immutability; JSON roundtrip; canonical pin/roll ordering; malformed completion/duplicate knockdowns/duplicate positions; invalid IDs, effects, fields, finite bounds and numeric types; overflow failure.

## Boundaries and next integration

This resolver consumes already-materialized item effects and physical outcomes; catalogue reference lookup and physical attribution are caller responsibilities. It does not run physics, UI, RNG, inventory mutations, persistent consumption, or match/run scope deduplication. Scope is a declared lifetime contract; future owners must supply eligible effects. Growth and payout records are proposals for future-state application, not applied state. Breakage/chance/complex item mechanics are not in the supported E02 opcode subset and must be versioned additions in their assigned milestones. Retrigger targeting is supplied explicitly by the future simulation/effect adapter; no recursive collision or retrigger evaluation exists here.

Coordinator: integrate these paths, run combined unit/content suites and smoke, publish worker/integration commits, record reviewed evidence. E03 remains the next pending milestone, proposed effort High.
