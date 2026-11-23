# AV-N5 — Both Halves, Rebound Rescue and five mastery items

State: DONE — implementation and verification (2026-11-17).
Branch: codex/roguewood-build. Coordinator 8bafa27 (UI-13) merged by 0cbd9a4
before authoring. No rebase, force-push, main push or PR.

## Delivered

Compass Pin, Split Pattern, Dry Run, Long Game and Second Chance have all seven
asset slots and artwork/effects_audio flags. Both Halves and Rebound Rescue have
original ribbon illustrations. Their byte-identical runtime aliases omit
`mastery`, matching the existing Clubhouse lookup. The source plan, exact prompts,
hashes and sound recipes are in docs/art/briefs/AV-N5* and ASSET-LEDGER.md.
Generated PNGs are unchanged; AtlasTexture regions provide item views.

Ready IDs: `pin.compass`, `charm.split_pattern`, `charm.dry_run`,
`charm.long_game`, `charm.second_chance`, `ribbon.mastery.both_halves` and
`ribbon.mastery.rebound_rescue`. Runtime ribbon aliases are `ribbon.both_halves`
and `ribbon.rebound_rescue`.

Compass Pin uses an ivory enamel and brass compass rose on its presentation
mesh. Its needle turns to the actual lane and its light follows the existing
catalogue's eligible-lane list; House Oil remains unlit. Compass, Split Pattern
and Long Game show the current lane with active/muted colour. Dry Run marks the
actual 34-foot crossing and measured side. Long Game also marks the 47-foot oil
boundary. Second Chance observes the actual rebound with a scorecard marker,
separate from Bumper Guard's marker and from the later paid reward.

Scoring cues use resolver-attributed amounts: Compass +25 Value, Split Pattern
×2, Dry Run's actual fallen count as chalk tallies and +Mult, Long Game ×1.5,
and Second Chance ×1.5. Each has original deterministic material foley. No
scoring reward is inferred from a visual observation. Reduced motion/flash
freezes cue geometry and sets the compass needle directly. The existing
ability-effects switch suppresses the overlays.

No gameplay, input, physics, persistence, Career or economy logic changed.
No missing hook request.

## Verification

Pinned Godot 4.5.2, Linux Compatibility/llvmpipe, isolated Xorg displays
:90/:91/:92 with MIT-SHM disabled; two rendering threads for the main batch and
one per supplementary rendered worker. Writable XDG directories under /tmp.
Dummy audio; no phone hardware, speaker trial or phone performance claim.
Logs/results are ignored local outputs in artifacts/wave14/av-n5/.

Unit/content and physics pass. Physics digest:
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
J03 retains 560/240/70 and J05 retains 21060 in both modes.

The asset audit reproduces all 31 generated resource/catalogue/audio outputs
exactly. Source and sound hashes match the ledger; five WAVs are mono PCM16,
22050 Hz, 7056 frames, peak 0.48. Catalogue changes are only the five items'
assets and their two completion flags. QA, CI and test-runner edits are add-only;
the new art step is gated to the art shard. Protected paths are unchanged.

The 69-check targeted batch passes: unit/content/physics and these 33 journeys
in both modes: JAVN5, JAVN5R, JAVN5C, JAVN5BC, JAVN4, JAVN4R, JAVN4C, JAVN4BC,
J03C18, J02, JAVT01, J03, J05, JAVN3, JAVN3R, JAVN1, JAVN2, JUIA1, JUIA2,
J06, J08, J11, J11ART, J03C13, J03C15, J03C16, J03C17, J03C19, J03C20,
JTUT, J01, J22L01 and J22L02. The latter two retain full-League assertions;
JTUT/J01 also cover the merged coordinator tutorial.

The supplementary art run adds 142 distinct checks. Together, all 211 distinct
checks pass, including all 175 configured art-shard journey modes (88 headless,
87 rendered). JAVC04B rendered initially exceeded its 900-second timeout during
concurrent software rendering; an isolated rerun passed in 511.7 seconds with
the original timeout and assertions unchanged. The failed attempt is retained
alongside the retry log. Initial contact attempts also required restoring a
stale display after the environment restarted.

Visual review moved the lane panels below the aiming HUD and enlarged their
small labels. Final unit/content and JAVN5/JAVN5R/J03C19 in both modes pass after
that last readability adjustment: eight further successful checks. The final
lane labels, side reading, rescue, paid cues, shop/Binder identities, reduced
presentation and native ribbons were visually reviewed. All 64 captures are
present. There are 220 recorded attempts for 211 distinct passing checks,
including the superseded timeout and the eight refinement checks.

Evidence: artifacts/wave14/av-n5/{results,art-results,art-rendered-results,
retry-results,label-results}.jsonl, validation-summary.json, one log per check,
asset-audit.json and scope-audit.json. This is not a claim that the whole CI pipeline, Web export or
every other gameplay journey ran locally; full-wave integration and closure
remain with the coordinator.

JAVN5 extends the unchanged J03C19 with real rerolls, purchases, placement,
throws, independent banks and original negative assertions. Banks remain 2790
on Two-Tone, 2480 on Long Oil and 1265 after the Bumper Guard rescue. It adds
actual lane/material/34-foot/rebound observations, five exact paid amounts and
sounds, five native shop/Binder previews, and both Trophies/Goals rows. The unit
test covers positive and negative cases, missing ownership, actual tally counts
and unchanged authoritative inputs. JAVN5R runs the whole reduced-input flow;
it does not require AV-N4's accurate-release timing fixture.

Fixture limits: the inherited Practice journey sets each frame's lane and uses
its existing shop eligibility/wallet fixtures. The original J22L02 checks actual
League lanes separately. The native journey counts one half and one rescue; it
does not earn either full mastery. Native ribbons stay visibly unearned. The
contact sheet labels full-colour earned artwork as specimens and changes no
Career progress. Neither original gameplay assertions nor timeouts were weakened.

## Owner capture index

64 captures, all ignored local outputs and never committed. Regenerate with
`python3 tools/qa.py e2e --journey ID --rendered`.

- JAVN5: artifacts/av-n5/native/rendered/ (28 images).
- JAVN5R: artifacts/av-n5/reduced/rendered/ (the same 28 images).
- `n5_lane_two_tone`, `n5_lane_long_oil`, `n5_lane_house_oil`: actual lane,
  eligible/ineligible Compass light, Split Pattern and Long Game state.
- `n5_side`: Dry Run's measured left side at 34 feet.
- `n5_rescue`: actual rebound, with separate Bumper Guard and Second Chance cues.
- `n5_compass_paid`, `n5_split_pattern_paid`, `n5_dry_run_paid`,
  `n5_long_game_paid`, `n5_second_chance_paid`: exact scoring rewards.
- `n5_shop_<stable-id-with-underscores>` and
  `n5_binder_<stable-id-with-underscores>`: all five identities in their UI.
- `n5_trophies_both_halves`, `n5_trophies_rebound_rescue` and corresponding
  `n5_goals_*`: native unearned ribbons and actual progress text.
- Original `c19_shop`, `c19_two_tone`, `c19_long_oil`, `c19_rescue` remain.
- JAVN5C/JAVN5BC: artifacts/av-n5/{contact,contact-b}/rendered/
  `{count_0,count_1,count_2,motion}.png`: canonical cards, small icons and reduced
  effects. Dry Run specimens show 0/5/10 tallies. Other amounts are fixed;
  contact-b includes both labelled earned ribbon specimens.
- Five sounds: assets/audio/sound.<stable-item-id>.wav.

## Hand-off and exact resume step

To Claude: the five item identities, effects/sounds, completion flags and both
mastery ribbons are ready for integration. The capture index includes the actual
lane and 34-foot readings, Bumper Guard's rescue and Second Chance's later paid
reward. No hook request. The completion commit and verified remote SHA are
reported with this checkpoint. The coordinator owns central progress and wave
closure; no external message is sent.

Stop at completed AV-N5. Next UI-A6 (Medium): fetch/merge the latest coordinator
with a merge commit, read updated claims and docs/prompts/codex-wave14-ui-a6.md,
then make the pin-deck finish manifest-driven and give House its own static
presentation-mesh finish. Check Divisions 1–8 and the Championship; preserve
Neon's finish. No Salvage Wave 15 art or proposed AV-UI1 work.

## Coordinator merge re-verification — 2026-11-23

Coordinator 329447e merged by 489c007. Unit/content and J03C19 pass; J03C19,
JAVN5 and JAVN5R pass headless/rendered. Rescue still banks 1265. Fresh Two-Tone
lane/34-foot side captures were reviewed; labels remain visible with the new UI.
No AV-N5 implementation changes. Physics digest remains 75d1a3c0…; J03 now
600/260/70 and J05 match 2 25920, as BAL-1 requires, both modes pass. Results:
artifacts/wave14/resume-20261123/. Full push CI/integration remain separate.
Next Wave 14 item is UI-A9-H (High), after inspection of the fresh push CI gate.
Comet now passes J02; see AV-N4.md.
