# AV-N1 — Oilskin, Laser, Tempo, Neon Sign, Blacklight, Bumper Guard

State: implementation complete; verification IN_PROGRESS (two rendered regression failures; see below).
Branch: `codex/roguewood-build`. Base: merge `7dcb506` of coordinator UI-6
`333c0af`, including main's Wave 12 merge `cd1cfc9`. No rebase, force-push,
main push or pull request.

## Delivered

Two three-item groups, High effort. Seven slots per item: `icon`, `card`,
`in_play`, `rarity_treatment`, `activation`, `sound`, `reduced_motion`.
Stable IDs: `ball.oilskin`, `ball.laser`, `pin.tempo`, `charm.neon_sign`,
`ball_mod.blacklight`, `ball_mod.bumper_guard`. Both artwork/effects_audio flags
are enabled for these six only. Mechanics, prices, gates and other flags stay
unchanged. `tests/mechanics_c15_test.gd` now expects the delivered art flags;
all its mechanics checks remain intact.

- Oilskin: beaded resin skin; OIL HOLD annotation and swish on its committed
  launch, without inventing a scoring reward.
- Laser: cyan seam/crosshair skin; a short beam only after the measured target
  crossing grades sweet/perfect; exact paid Mult cue and glass ping.
- Tempo: ivory pin with an indigo meter band. Its reward visibly fills one/two
  meter bars from the actual accurate-roll count and names the paid Value.
  A clean/miss frame has no success cue or sound.
- Neon Sign: an enamel RW plaque in the live Charm rail; its paid curved-frame
  cue lights one/two letters and names the exact Mult amount.
- Blacklight: native card badge and narrow violet rings on its actual host,
  retaining the host's markings. Paid curved-strike flare and multiplication
  cue, muted when ability effects are off.
- Bumper Guard: native badge and small rubber host brackets. A bumper segment
  and inward arrow appear only for its own recorded rebound, with a rubber
  thump; its later score cue names the penalty while the explanation retains
  "never below 1". The native replay after Continue still rebounds and counts.

The artwork is original generated pixel illustration, with unchanged sources;
materials, overlays, cues and deterministic synthesized foley are authored
project assets. Exact prompts and source contract: `docs/art/briefs/AV-N1.md`.
Hashes and permission/provenance record: `docs/art/ASSET-LEDGER.md`.

## Verification

Pinned Godot 4.5.2, Linux Compatibility / Mesa llvmpipe, Xorg dummy display :99,
LP_NUM_THREADS=2, writable XDG directories under /tmp. No device trial claimed.

Unit and content PASS with flags enabled. Unit projection cases cover actual
zero/one/two-accurate frames, exact amounts/grades, qualifying/nonqualifying
attachments and immutable resolver data. Physics digest remains:
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.

JAVN1 extends J03C15. It retains all purchases, placements, replay, independent
banks and explanations; it lets the native score reveal complete instead of
skipping it, then adds an Oilskin throw and six Binder visits. Original banks:
70 (rescue), 1650 (curved Blacklight strike), 1200 (Laser strike). The additional
Oilskin frame banks 520, independently checked. JAVN1C and JAVN1BC exercise
canonical cards, 44px icons/reduced identities, normal cues and 0/1/2 specimens.

Regression checkpoint: 163 of 165 commands PASS. This includes all headless
art journeys, the named game regressions in both modes except J03C15 rendered,
and every rendered art journey except JAVC04B. The two failures are NOT waived:

- JAVC04B rendered: exceeded its 900 s timeout during the concurrent matrix.
- J03C15 rendered: XServer `BadShmSeg (invalid shared segment parameter)`.

JAVN1 rendered also passed separately, including its final host/Binder captures.
Unit/content passed separately with final flags. J03 remains 560/240/70 and
J05 21060. Native art is delivered, but this handoff does not call final
verification DONE while the two regressions remain unresolved. The final
read-only attribution guard and effects-off flare guard should be covered by
a fresh JAVN1 rendered run when resuming (the matrix's JAVN1 headless passes).

Resume: use a display with MIT-SHM disabled (sandbox commands use separate IPC
namespaces) and rerun JAVC04B/J03C15 rendered sequentially before diagnosing a
code regression. Preserve existing failure logs. Do not increase timeouts or
remove assertions to get a pass. Then rerun unit/content and JAVN1 rendered on
the exact final tree, inspect captures, update this status and push.
Machine-readable local evidence: `artifacts/wave13/av-n1/{commands,results}.json`
and individual logs. New QA registrations, CI steps and run_tests.gd are
add-only. Every new CI art step is guarded by `if: matrix.shard == 'art'`.
No protected gameplay, League configuration, project or export file is edited.

## Owner capture index

Captures are local ignored outputs, never committed. Regenerate with
`python3 tools/qa.py e2e --journey <ID> --rendered` on Godot 4.5.2 and a display.

- JAVN1C: `artifacts/av-n1/contact/rendered/{count_0,count_1,count_2,motion}.png`:
  Oilskin, Laser and Tempo canonical cards and icon scale, then reward meters.
- JAVN1BC: same names in `artifacts/av-n1/contact-b/rendered/`: Neon Sign,
  Blacklight and Bumper Guard; reduced count specimens and normal effects.
- JAVN1: `artifacts/av-n1/native/rendered/n1_rebound_live.png`: real rescued
  roll, static rail under reduced effects. `n1_bumper_guard_paid.png`: penalty.
- Same folder: `n1_tempo_paid.png`, `n1_laser_beam.png`, `n1_laser_paid.png`,
  `n1_neon_sign_paid.png`, `n1_blacklight_paid.png`, `n1_oil_hold.png`.
- `n1_host_blacklight.png`, `n1_host_bumper_guard.png`: native attachment
  overlays and badges with the host identity retained.
- `n1_shop_<item-id-with-underscores>.png` and
  `n1_binder_<item-id-with-underscores>.png`: every assigned card in real UI;
  Binder capture scrolls the selected card into view above the pinned footer.
- The original `c15_shop`, `c15_rebound`, `c15_curved_strike`, `c15_laser`
  captures remain part of the child journey.
- Audio to audition: `assets/audio/sound.<stable-item-id>.wav`, six files.

## Limits and coordinator hand-off

All existing hooks needed by AV-N1 were available; no new rule hook request.
Oilskin's extra native frame is House Oil. Cross-oil physics is the existing
coordinator test suite's evidence; the presentation reads the same oil-hold
flag on every lane. No phone hardware or physical audio playback is claimed.

Delivered for coordinator review, with final verification still open:
all six identities, host appearances, effects/sounds, flags and art journeys.
The coordinator owns central AI-HANDOFF updates and the sole merge path to main.

## Resume exactly here

This is the permitted early Wave 13 checkpoint. AV-N2 and the Neon theme tail
are NOT_STARTED, not silently deferred as finished. See WAVE13-CODEX.md for
those exact next steps. Do not start AV-N3 or Salvage art in this wave.
