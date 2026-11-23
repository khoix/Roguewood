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

## Coordinator merge re-verification — 2026-11-23

Affected local re-verification: PASS. Coordinator 329447e merged by 489c007;
fresh fetch found no additional coordinator changes. Unit/content, J03C18 both
modes pass; the Comet/Steady Hand/Metronome strike is now 4725 under BAL-1.

QaRender initially compressed purchase and sale inside the unchanged 85 ms
wall-clock sound debounce. The native art test now waits 100 ms before Sell
actions and checks the visual/audio cues separately. Production audio and
scoring are unchanged. Final JAVN4 and JAVN4R pass headless and rendered.
The reduced-input fixture limit documented above still applies.

J02's unchanged rotation check exposed Comet's barely visible markings: its
old narrow UV band changed only 0.00/0.03 of the sampled surface under roll/spin.
The old material was already mesh-local; this was a visibility/mapping issue.
The revised original shader paints a broad oblique cyan sweep, a parallel fine
trail and a gold four-point star in quantized mesh-local coordinates. Violet
base, palette, reflectivity and subtle emission are retained. No TIME animation,
new nodes, gameplay changes or changes to the coordinator's three UI-33b shaders.

Final unit/content and J02/JAVN4/JAVN4R in both modes: all eight checks PASS.
J02 Comet differences are now 0.27/0.35; all ten balls pass without weakening
assertions. Reviewed the full turn contact sheet, armed Comet card, and normal
and reduced native trail captures. Source/provenance: docs/art/briefs/AV-N4.md
and ASSET-LEDGER.md. Evidence: artifacts/wave14/timed-20261123/comet-checks/.

Owner review: artifacts/e04/rendered/ball_turns.png (Comet is the last row),
artifacts/av-n4/{native,reduced}/rendered/n4_comet_trail.png, and
artifacts/av-n4/native/rendered/n4_armed.png. Captures remain uncommitted.

CI on prior checkpoint 1ecd20a: Bootstrap art job 137473381557 and E11 still
review passed. Bootstrap game job 137473381774 and E12 motion job 137473381425
failed; available annotations only report exit code 1, and log/artifact download
endpoints were unavailable. Their actual failing assertions remain unknown.
A passing local J02 is not a claim those CI jobs are repaired. Fresh push CI is
the gate; inspect it before further implementation. UI-A9-H (High) is next after
integration checks. No hook request and no UI-A9-H authoring in this window.

Supplementary checks in this window: physics and J08 headless/rendered PASS.
Digest: 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
The first attempt stopped at editor import because the sandbox denied local
sockets; the unchanged checks passed with the required execution access.
Evidence: artifacts/wave14/timed-20261123/{motion-sandbox-attempt,motion-checks}/.
This brings the final targeted total to 11 passes. J08 passing locally does not
substitute for E12's separate movie-capture workflow. No new test thresholds,
scoring/input/audio behavior or protected gameplay files were changed.

## Follow-up CI — 2026-11-23, ten-minute continuation

Comet checkpoint b5338c9 passed the full Bootstrap game and art jobs
(run 45138579012) and E11 still review (45138579162). The remaining E12 review
failure reproduced locally as a stale reveal.png requirement in the recording
tool after UI-16 removed that preview. It is independent of Comet and is
tracked in E12.md. AV-N4's local and full Bootstrap verification are complete.
