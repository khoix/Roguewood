# AV-N4 — Controlled Curve, shop upgrades and mastery items

State: DONE — implementation and verification (2026-11-17).
Branch: codex/roguewood-build. Coordinator b97354b (UI-12) merged by 38d68cb
before authoring; coordinator 9ec104e (UI-13) merged by 2bc73b5 before final
validation. Both are merge commits. No rebase, force-push, main push or PR.

## Delivered

Trade-In, Specialist Shelf, Comet Ball, Metronome and Steady Hand now have all
seven asset slots and artwork/effects_audio flags. The Controlled Curve ribbon
has its original illustration, plus a byte-identical `ribbon.controlled_curve`
alias for the existing Clubhouse asset-name hook. Source plan, exact generation
prompts and provenance are in docs/art/briefs/AV-N4* and ASSET-LEDGER.md.
Generated PNGs are unchanged; AtlasTexture regions provide item views.

Ready IDs: `shop_upgrade.trade_in`, `shop_upgrade.specialist_shelf`,
`ball.comet`, `charm.metronome`, `consumable.steady_hand`, and
`ribbon.mastery.controlled_curve` (runtime alias `ribbon.controlled_curve`).

Trade-In displays the actual confirmed sale return, without reconstructing its
bonus. Specialist Shelf marks the actual slot 7 offer with a cyan border; the
shop art row explains it, and the opened offer visibly says Specialist. Both
upgrades play their native purchase cues. Existing ownership loaded from a save
does not replay purchase cues.

Comet's violet enamel, cyan curl and gold star dress the existing presentation
ball. Its twelve-point trail starts only after the measured accurate curved
crossing. Steady Hand has an armed hand marker and a measured curved-release cue.
Metronome ticks beside the held ball and stops on the measured accurate release.
Resolver-attributed paid cues display Comet +6 Mult, Steady Hand ×2 and Metronome
×1.5, with distinct original procedural sounds. Observed release cues do not
claim the later scoring reward.

Reduced motion/flash freezes cue geometry and replaces the moving Comet trail
with a fixed halo. The existing ability-effects switch suppresses the overlays.
No gameplay, input, physics, persistence, Career or economy logic changed.
No missing hook request.

## Verification

Pinned Godot 4.5.2, Linux Compatibility/llvmpipe, isolated Xorg :93 with MIT-SHM
disabled; LP_NUM_THREADS=2 and writable XDG directories under /tmp. Remaining
art checks use independent Xorg :91/:92 with LP_NUM_THREADS=1. Dummy audio;
no phone hardware or speaker trial. Final results/logs are local ignored outputs
in artifacts/wave14/av-n4/.

Unit/content and physics pass. Physics digest:
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
Asset audit reproduces all 31 generated resource/catalogue/audio outputs exactly.
All source and sound hashes match the ledger; five WAVs are mono PCM16, 22050 Hz,
7056 frames, peak 0.48. Catalogue audit permits only the five items' assets and
their two completion flags. QA, CI and test-runner additions are add-only, with
new art steps gated to the art shard.

With flags enabled, JAVN4/JAVN4R/JAVN4C/JAVN4BC and the original J03C18 pass
headless and rendered. The native independent bank remains 4410. All 52
captures are present; the shop/Binder identities, marked Specialist offer and
opened label, paid cues, reduced halo and native ribbon were visually reviewed.
J03 retains 560/240/70 and J05 retains 21060 in both modes.

The targeted batch is complete: 61 checks pass (unit/content/physics and these
29 journeys in both modes): JAVN4, JAVN4R, JAVN4C, JAVN4BC, J03C18, J02,
JAVT01, J03, J05, JAVN3, JAVN3R, JAVN1, JAVN2, JUIA1, JUIA2, J06, J08, J11,
J11ART, J03C13, J03C15, J03C16, J03C17, J03C19, J03C20, JTUT, J01, J22L01,
J22L02. JTUT/J01 cover the merged coordinator tutorial; both League journeys
retain the original full-run assertions.

The additional art regression run also completed: 142 further checks pass.
Together, all 203 distinct local checks pass, including all 167 configured
art-shard journey modes (84 headless, 83 rendered) in bootstrap.yml. There were
no failures in this final run. The environment was resumed after the workers
completed; all results and 52 AV-N4 captures were retained and checked. Evidence:
artifacts/wave14/av-n4/{results,art-results,art-rendered-results}.jsonl and
validation-summary.json, with one log per check. Asset/scope audit outputs are
in the same ignored directory. This is not a claim that the entire CI pipeline,
Web export or all other gameplay journeys ran locally; full-wave integration
and closure remain with the coordinator.

JAVN4 extends J03C18 and retains its real purchases, throws, independent bank
calculation and original assertions. It adds actual slot 7 and visible
Specialist-offer checks, confirmed sale/purchase sounds, Comet's live material,
measured trail, armed hand, exact three paid cue amounts and sounds, five native
shop/Binder previews, and the actual Trophies/Goals rows. The projection unit
test checks positive and negative cases, missing ownership, and unchanged
authoritative inputs.

Important reduced-fixture limit: the game's reduced-input timing ring is
deliberately clean-only. JAVN4R commits the original normal timed throw, then
enables reduced presentation before target crossing. It tests reduced visuals
on a genuine accurate committed roll, not accurate reduced-input timing. No
grade, input value or score is forged.

The native journey counts one controlled curve; it does not complete the mastery.
The native ribbon stays visibly unearned. The contact sheet labels the full-colour
earned version as an art specimen and makes no Career changes.

During implementation, the unit test caught an incorrect effect-operation name;
the native test caught the ribbon's runtime filename mismatch. Both were fixed.
Shop captures now wait for the existing deal-in animation to settle. No original
gameplay assertion was weakened.

## Owner capture index

All captures are ignored local outputs, never committed. Regenerate with
`python3 tools/qa.py e2e --journey ID --rendered`.

- JAVN4: artifacts/av-n4/native/rendered/ (22 images).
- JAVN4R: artifacts/av-n4/reduced/rendered/ (the same 22 images).
- `n4_specialist.png`, `n4_specialist_offer.png`: marked actual slot 7 and the
  opened offer's Specialist label.
- `n4_trade_sale.png`: confirmed sale return and upgrade identity.
- `n4_armed.png`, `n4_comet_trail.png`: armed hand, metronome and measured release.
- `n4_comet_paid.png`, `n4_steady_hand_paid.png`, `n4_metronome_paid.png`: exact
  resolver amounts beside the real scoring sequence.
- `n4_shop_<stable-id-with-underscores>.png` and
  `n4_binder_<stable-id-with-underscores>.png`: all five identities in their UI.
- `n4_ribbon_trophies.png`, `n4_mastery_progress.png`: native unearned ribbon and
  actual mastery progress. Original `c18_shop`, `c18_controlled_curve` remain.
- JAVN4C/JAVN4BC: artifacts/av-n4/{contact,contact-b}/rendered/
  `{count_0,count_1,count_2,motion}.png`: cards, small identities and effect
  specimens; contact-b includes the labelled earned ribbon. The inherited count
  names are fixed-amount specimens, not a count-dependent effect.
- Five sounds: assets/audio/sound.<stable-item-id>.wav.

## Hand-off and exact resume step

To Claude: the five item identities, effects/sounds, completion flags and the
Controlled Curve ribbon are ready for integration. The capture index above
includes the required marked Specialist offer in slot 7. No hook request.
The completion commit and remote SHA are reported with this checkpoint; the
coordinator owns the central progress update and wave closure.

Stop at completed AV-N4. Next AV-N5 (High), then UI-A6 (Medium). Fetch and merge
the latest coordinator branch with a merge commit, read updated claims, and
start AV-N5 from E17-D16/E18-C19. List IDs, slots, provenance and captures before
authoring; preserve the native lane/side readings and Bumper Guard rescue paying
Second Chance. Full-wave integration remains separate from this item's results.
