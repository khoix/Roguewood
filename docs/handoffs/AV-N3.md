# AV-N3 — Dry Side, Lane Reader, Hook Shot, Line Call, Bounce Back, Straight Money

State: DONE (implementation and required item verification).
Branch: codex/roguewood-build. Coordinator UI-11 (5f38708) merged before work.
No rebase, force-push, main push or PR.

## Delivered

Six identities, all seven asset slots and artwork/effects_audio flags. Source
plan: docs/art/briefs/AV-N3.md. Original three-cell atlases remain unchanged;
AtlasTexture views, deterministic foley recipes and SHA-256 hashes are recorded
in docs/art/ASSET-LEDGER.md. No other catalogue fields changed.

Dry Side marks the measured crossing at 34 ft; Lane Reader names the actual
lane (including normalized House/Dry aliases) beside its chart. Hook Shot draws
the armed stretched guide and marks the committed hook; Line Call draws a
straight chalk guide and displays its resolver-attributed +4 Mult. Bounce Back
marks the observed Bumper Guard rescue separately from the paid +$3, with a
coin following the return path. Straight Money pays with a straight-creased
banknote. The live Charm rail, shop and Binder use the six new identities.

Normal effects use the existing bounded glyph pool. Reduced motion/flash freezes
cue geometry and retains measured side/lane information and exact amounts.
The ability-effects toggle suppresses the overlays through the existing gate.
No physics, rule, input, persistence or economy changes; no missing hook request.

## Verification

Godot 4.5.2, Linux Compatibility / llvmpipe, isolated Xorg :94 (MIT-SHM disabled),
LP_NUM_THREADS=2 and writable XDG directories under /tmp. Dummy audio; no phone
hardware or speaker trial. Unit/content and physics passed during implementation;
physics digest 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
With flags enabled, JAVN3/JAVN3R/JAVN3C/JAVN3BC and the original J03C17 passed
headless and rendered. Native independent banks remain 1120 / 720 / 840 / 80;
the five paid cue amounts are +4 Mult / ×1.5 / +4 Mult / +$3 / +$2, with Hook
Shot verified at its actual committed 1.5 scale. Unit/content passed again after
the final visual changes. J03 retains 560/240/70 and J05 retains 21060 in both
modes. Source/WAV hashes, 22050 Hz mono format and 0.48 peak were checked. Regeneration
of all 37 resource/catalogue/audio outputs was byte-identical (regeneration.json).

A supplementary full-wave matrix completed 72 checks (unit/content and 70
journey modes), all passing, before the deliberate item checkpoint. It was not
completed: remaining full-wave/CI coverage belongs to the later wave integration.
The interrupted in-flight checks are not counted as passes. Local results and
exact remaining list: artifacts/wave14/av-n3/{results.jsonl,remaining-checks.json}.
No claim that the entire art shard passed in this session. Final spacing reruns
all PASS: unit/content and JAVN3/JAVN3R headless/rendered. Logs are final-*.log
and final-results.json in that directory. All 64 item captures were generated;
shop/Binder, side/lane, armed guide, paid cues and both rescue views were inspected.

JAVN3 extends J03C17 without replacing its real purchases, card taps, throws,
explanations or independent bank calculations. It observes all six sounds,
five paid amounts, actual side/lane facts, armed guides and the committed hook.
JAVN3R repeats the same full native flow with reduced motion. Both retain the
original negative assertions (e.g. no Lane Reader on House Oil, no Dry Side on a
right-side roll). The pure projection test checks exact amounts and absences,
rejects missing ownership and confirms authoritative inputs stay unchanged.

The first native run exposed two capture-harness timing/lifetime mistakes:
checking keep-card sizes before their deferred layout settled, and attempting
to log through the closed game screen during Binder captures. Fixed in the new
journey; no shared UI assertion was weakened. Initial failures remain in
/tmp/n3-native.log. Visual review caught and fixed the internal House lane label and separated the
Bounce Back rescue glyph from Bumper Guard. The final native rerun passes both
headless and rendered, including the non-overlap assertion.

## Owner capture index

All captures are ignored local outputs, never committed. Regenerate each journey
with `python3 tools/qa.py e2e --journey ID --rendered`.

- JAVN3: artifacts/av-n3/native/rendered/ (28 images).
- JAVN3R: artifacts/av-n3/reduced/rendered/ (the same 28 images, reduced motion).
- `n3_side.png`: Dry Side's actual left crossing at 34 ft.
- `n3_lane.png`: Lane Reader's Long Oil plate.
- `n3_hook_shot_armed.png`, `n3_line_call_armed.png`, `n3_hook.png`: both armed
  guides and the committed Hook Shot.
- `n3_rescue.png`, `n3_bounce_back_paid.png`: rescue and earned payout separately.
- `n3_dry_side_paid.png`, `n3_lane_reader_paid.png`, `n3_line_call_paid.png`,
  `n3_straight_money_paid.png`: remaining exact paid cues beside the real score.
- `n3_shop_<stable-id-with-underscores>.png` and
  `n3_binder_<stable-id-with-underscores>.png`: all six identities in their real UI.
- Original `c17_shop`, `c17_line_call`, `c17_dry_side`, `c17_lane_reader`,
  `c17_bounce_back` captures remain.
- JAVN3C and JAVN3BC: artifacts/av-n3/{contact,contact-b}/rendered/
  `{count_0,count_1,count_2,motion}.png`: cards, 44px identities, static and moving
  effect specimens. These count labels are inherited; this batch uses fixed
  confirmed amounts, not a per-pin count effect.
- Six sounds: assets/audio/sound.<stable-item-id>.wav.

## Exact resume step

AV-N3 is complete. Next: AV-N4 (High), then AV-N5 (High), then UI-A6 (Medium).
Read E17-D15 and E18-C18; list IDs/slots/provenance/captures before authoring.
Preserve the native marked Specialist offer in shop slot 7. Full-wave regression
coverage is still pending as explicitly recorded above.
Coordinator advanced during the interrupted test run to UI-12c (68b8244). This
item remains based on the recorded UI-11 merge; merge the latest coordinator
branch with a merge commit before starting AV-N4, then read the updated claims.

## Supplementary regression results at this checkpoint

Headless:

J02, J03, J03C13, J03C15, J03C16, J03C17, J03C18, J03C19, J03C20, J05, J06, J08,
J08A01, J08A02, J08A03, J08A04, J08A05, J08A06, J08A06R, J08A07, J11, J11ART, J12R01,
J12R02, J12V01, J12V02, J12V03, J12V04, J12V05, J12V06, J12V07, J19A08, J19A09,
J19A10, J19A11, J19A12, J19A13, J19A14, J21R03, J21R04, J21RC, J22L01, J22L02,
JAVC07AC, JAVC07BC, JAVH1AC, JAVH1BC, JAVH2AC, JAVH2BC, JAVN1, JAVN2, JAVN3, JAVN3BC,
JAVN3C, JAVN3R, JAVT01, JUIA1, JUIA2.

Rendered:

J02, J03, J03C17, J05, J06, J08, JAVN1, JAVN2, JAVN3, JAVN3BC, JAVN3C, JAVN3R.

To resume the full-wave matrix, run both modes of the art-shard journey IDs in
.github/workflows/bootstrap.yml and the protected gameplay journeys in the owner
brief, omitting the passing modes above only if their inputs are unchanged.
The four new AV-N3 journeys and artifact upload path are art-shard gated. qa.py,
CI and run_tests.gd changes are add-only. The coordinator owns central progress.
