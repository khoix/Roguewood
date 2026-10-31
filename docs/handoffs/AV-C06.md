# AV-C06 — tactical-card presentation

State: DONE (implementation and local verification).
Codex / codex/roguewood-build. Resumed from da7d9cd; origin integration was
already merged. E21-R03/R04 remain complete.

## Delivered

- Nudge's numbered flat rack chooser from da7d9cd, preserving original choice
  order and supporting both original list and real diagram-button input.
- Original activation recipes and deterministic wood/swish/paper foley for
  consumable.nudge, consumable.reserve_call and consumable.rule_waiver. Cues use
  their existing E19 identity art, the shared four-voice priority mixer and its
  mute/volume settings, effects toggle and static reduced-motion renderer.
- Read-only tactical_art.gd observes tactic_played(action). The live signal
  plays cues; frame_actions restores persistent annotations after reload without
  replaying sound. Reserve Call marks the swapped position THIS FRAME ONLY;
  Nudge names the moved pin and destination; Rule Waiver frames/crosses the badge
  and names the frame-only waiver. Annotations clear with authoritative actions.
- Only these three catalogue items receive activation/sound slots and artwork /
  effects_audio true, after successful headless/rendered native checks. Existing
  icon/card/rarity/reduced-motion art is retained. No batch flags changed.

## Validation

J03C06 headless and --rendered PASS, including actual chooser taps, activation
reaching the audio mixer, reduced-motion setting, silent restoration on resume,
frame-marker cleanup and all existing independent scoring assertions. Captures
of the chooser and three card activations/frame treatments inspected. The waiver
cross was refined to a corner mark so it does not obscure the rule name.

Final unit/content PASS with completion flags enabled. Required headless
regressions PASS: J03C05–J03C10, JAVC03A/B, JAVC04A/B/C, J22L01ART,
J11ART, J12V08, J19A16 and J06.
Physics PASS with unchanged digest
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
Logs: artifacts/av-c06. Native captures: artifacts/e18-c06/rendered. CI already
runs/uploads J03C06; qa.py, run_tests.gd and the workflow remain unchanged.

Provenance and exact foley reproduction commands: docs/art/ASSET-LEDGER.md.
No gameplay, simulation, persistence, Career or League data changes. No flags on
Claude's new House items. Screenshots remain ignored. Desktop native evidence;
no subjective sound mix or mobile-device claim. The older score explanation's
rack diagram still uses home positions for nudged pins (E18-C06's documented
limitation); the lane and this chooser show the committed move.

## Resume exactly here

AV-C06 is delivered. Fetch origin, stay on
codex/roguewood-build, merge newer coordinator work with a merge commit if any.
Next AV-C07 (Medium), two sessions of three upgrades:
1. Brief E17-D06's six upgrades; implement Punch Card, Pin Caddy, Clearance Tag.
2. Implement Savings Book, Extra Shelf, Spotlight Sign.
Each session includes category-frame identity art, activation/sound and the named
shop treatments. Preserve rules and stock/economy behavior. Verify J03C07 natively
before only those items' slots and artwork/effects_audio flags. No House item art
or flags from E17-D07…D09 this wave. Coordinator owns central progress and merge.
