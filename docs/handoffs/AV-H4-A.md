# AV-H4-A — Double Take, Called Shot, Pin Count

State: DONE (implementation and native verification). Branch: codex/roguewood-build. Based on UI-A2 dc5877e,
UI-A1-C motion refinement 47bf589, and merge a83baff of Claude's tethered swing
through ec9cabc. The coordinator's production UI/input changes came through
that merge; Codex did not edit those owned paths.

## Delivered

- Six asset slots for each tactical: card, icon, rarity treatment, reduced
  identity, activation and sound. Original generated atlas at full card-window
  resolution; original procedural foley, static reduced treatments. Double
  Take/Called Shot remain Uncommon, Pin Count Common.
- Double Take: doubled pin outlines on the actual first direct pin in the
  score rack. Repeat ordinal plus exact pre-bank effect ownership distinguishes
  it from stacked Echo Ball/Echo Charge. The native explanation credits Double
  Take. Unknown future conditional grants are not guessed by this adapter.
- Called Shot: pointing glove at the pocket, lit on the paid strike event and
  desaturated grey on a spent non-strike. Failure is a silent annotation at the
  start of score reveal; it does not invent a resolver effect or multiplier.
- Pin Count: one tick per event.count, exact fallen-slot outlines from committed
  frame data, and the existing native +5-per-pin calculation. Reduced mode shows
  every tick immediately; normal mode reveals that authoritative target count.
- Brief/provenance: docs/art/briefs/E17-D10.md and docs/art/ASSET-LEDGER.md.
  Only these three catalogue entries have updated slots and artwork/effects_audio
  flags. Cleanup Crew/Lucky Seven remain false. No rules, physics or theme binding
  changes. No production card/UI scripts edited.

## Verification and evidence

Pinned Godot 4.5.2, Compatibility/Mesa llvmpipe. PASS: qa.py unit/content,
JAVH4AC, J03C11, JAVC04C, J03C10 and JUIA1 headless and rendered. Physics,
J03 and J05 headless also PASS. Logs: artifacts/wave10-codex/av-h4-a/.
Final unit/content logs use the -final suffix. git diff --check PASS.

- Unit projection tests: exact stacked repeat causes; no input mutation;
  zero/partial/full Pin Count; Called Shot strike/spare/open and absent snapshot.
- JAVH4AC: full card/icon/reduced contact, normal cue and grey miss/full count.
  Rendered pixels verify desaturation instead of a brown tinted hand.
- J03C11: preserves purchases, throws and independent banks 1120/600/1190/560;
  adds cue/audio/count/first-direct assertions. A fresh Called Shot is bought
  through the shop and spent on a spare, banking the independent 840 without
  its multiplier or success sound. Both motion settings are exercised.
- Shared-adapter regressions: JAVC04C (Echo Charge/Lantern) and J03C10 (prior
  House equipment/keepsakes and jar lifecycle), headless and rendered.
- UI-A1-C motion check: JUIA1 headless/rendered, all 61 captures. Normal sky moves;
  reduced stays pixel-identical. Constellation lines use 18% alpha.
- Physics digest remains 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f;
  J03 remains 560/240/70, J05 21060.

Captures (never committed):
- artifacts/av-h4-a/contact/rendered/{contact,motion,counted}.png
- artifacts/e18-c11/rendered/h4_{called_shot_ball,double_take_retrigger,pin_count_ball,called_shot_missed}.png
- artifacts/ui-a1/rendered/sky_motion.mp4 (native 24-frame sequence at 12 fps),
  and the 16:9, 4:3, portrait/backdrop matrix listed in UI-A1.md.

qa.py, run_tests.gd and CI are add-only. New JAVH4AC step is art-shard-only;
its upload folder is inside the existing artifact path list. Full Wave 10
closing matrix and physical-phone approval are not claimed by this batch.

## Coordinator follow-up: existing stacked-repeat explanation

Read-only review found a pre-existing text limitation in src/rules/score_log.gd,
_cause: it selects the first non-ball retrigger owner on a roll, without the
repeat ordinal. With Echo Ball plus Double Take, it therefore labels the Echo
repeat Double Take too; Echo Charge plus Double Take can similarly share one
label. This batch's art projection distinguishes those causes exactly and its
unit cases cover all three together. The ordinary J03C11 Double Take explanation
is correct. Claude should make the text attribution ordinal-aware in the rules
lane; Codex has not edited that owned path. Score amounts are unaffected.

## Resume exactly here

Next: AV-H4-B, High recommended because Cleanup Crew must show the first-roll
leave against 2, and Lucky Seven must land on 7 only for exactly seven down.
Read landed E17-D10, E18-C11 and the updated J03C11. Add their two briefs,
identities, activation, sound and presentation evidence; only then set their
six asset slots and both flags. Preserve all existing J03C11 checks/captures.
After B, run the complete Wave 10 regression matrix from codex-wave10.md and
write WAVE10-CODEX.md listing the UI-A1-C backdrop/capture review set. No AV-T01
or future League work. UI-A2 assets remain ready for Claude's integration via
docs/art/ui/UI-A2.md; owner layout approval is the UI-2 dependency.
