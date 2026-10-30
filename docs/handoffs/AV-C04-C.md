# AV-C04-C — Echo Charge and Lantern

Implementation: DONE. Codex / codex/roguewood-build. Base `792e24b`,
AV-C04-B complete, pushed and remote SHA/clean tree verified. Effort: High.

## Before

Only ball_mod.echo_charge and pin_mod.lantern. Read the exact six asset IDs each
from E17-D04 landed: icon, card, rarity_treatment, activation, sound,
reduced_motion. No new in_play slot or mechanics. Original generated RGBA source
with prompt/hash retained unchanged; AtlasTexture views. Original small cosmetic
host meshes, vector effects and synthesized foley with provenance in the ledger.

Echo Charge: open double clasp and two fastening feet, distinct from Echo Ball's
whole orb; small off-centre host ring, no erased Hammer/Hook marking. One pair
of pulses/link to the actual repeated first-direct pin, keyed to its resolver
cause; no cue on a gutter or a pin with no repeated scoring event. Check legal
hosts and native Echo-host exclusion, repeated attached-pin effects, payout dedup,
replay/Skip/settings and unchanged physics/bank. No inferred extra scoring.

Lantern: handled rectangular frame and a single wick. Small shoulder attachment,
static lit/unlit state from the actual knockdown tracker. At its standing event,
outline the actual standing rack positions and show the resolver's Mult/count.
Strike/spare quiet. Check partial and full standing sets, fall extinguishing,
reduced motion/flash, host recognition, card/binder/shop and native reload.

JAVC04C buys actual offers onto Hammer, a second compatible Hook, and rack 6, exercise actual throws,
compare independent resolution, inspect native hosts, 4x/Skip/audio/effects and
portrait/landscape. JAVC04CC supplies 32/64/192px color/grayscale/silhouette and
static effect contact checks, including Echo Ball and other flame silhouettes.
Unit/content plus affected headless/rendered regressions before flags and push.
No rules, physics, persistence, League specs or unassigned completeness flags.

Next after this batch: E22-L01-ART House theme (High); preview assets and stable
ID/drop-path handoff, live integration remains Claude's Wave 8 work.

## Delivered implementation and native evidence — 2026-10-29

Twelve exact declared resources, original generated source/prompt and matched
unlit Lantern source, bounded cosmetic host attachments, two original foley cues,
actual repeated/standing rack links. Artwork and effects_audio are set for these
two items after the final native passes. No other catalogue flags changed.

Charge's open clasp preserves Hammer's bands and Hook's crescent. The native
journey buys onto Hammer, then sells that real host and buys Charge again onto
Hook: the catalogue's max_owned=1 limit is respected. The actual picker excludes
Echo Ball. Both real aim/rolling bodies retain physics and original identity;
shop, hand/inspector, binder and menu reload are checked.

Lantern's initial geometric frame was too flat in the native close-up. Final
presentation samples matching lit and extinguished illustrations on two small
cosmetic quads, showing one at a time from the real tracker. Source PNGs remain
unchanged. Its internal unlit helper is not an added catalogue/design slot.
The Wood body, collar and silhouette stay visible. All final close-ups and the
32/64/192px grayscale/silhouette/look-alike contact sheet were inspected.

| Actual native frame | Bank | Cues |
|---|---|---|
| Charged gutter, full standing rack | 0 | Lantern +10 Mult, slots 1–10; Charge quiet |
| Charged Hammer strike | 750 | One Charge repeat on actual first-direct pin 3; Lantern off |
| House partial open | 280 | Lantern +3 Mult, slots 1, 3, 6; Charge quiet |
| Second charged Hammer strike | 750 | One Charge repeat on pin 3; Lantern quiet |
| Charged Hook strike | 600 | One Charge repeat on actual first-direct pin 1 |

Headless and rendered final values match. Release grades remain native inputs;
every bank/fact set is compared with independent resolution, not substituted.
The effect is aligned to the actual repeated row and roll cause. Host cues/audio
remain; Charge is drawn last so the host cannot immediately replace its pin link.
A repeat ordinal (e.g. 2 after an intrinsic repeat) still means one Charge use.

Units cover Wood/Ruby/Gold/Crown, intrinsic repeats and the eight-repeat cap,
zero-award Crown silence, a Crown with only a paid attached effect, one deferred
Gold income, absent contact, and partial/full/fallen Lantern sets. Projectors do
not mutate inputs or guess ownership from animation. Four-voice bounds, audio
starts, mute/zero volume/effects toggle, 4x exact ordering, reduced states, silent
Skip and bank/inventory immutability pass natively. Both viewports are captured.

During fixture development, replaying the zero-score mid-match frame triggered
an engine callback failure. The controls exercise now uses the completed winning
strike, matching the established A/B harness pattern; actual zero-score play
still runs. An attempted second simultaneous Charge was correctly refused by
max_owned=1, so the fixture now performs the legal sale/repurchase above. Neither
failure was addressed by changing production rules or gameplay flow.

Verification files (ignored, never commit screenshots):
- `artifacts/wave6/validation/C-final-headless.log`, `C-final-rendered.log`:
  final JAVC04C passes; metrics and captures in `artifacts/av-c04-c/native/`.
- `C-contact-headless.log`, `C-contact-rendered.log`: JAVC04CC passes; contact
  includes Echo Ball, Hot Streak, Patient Investor and the extinguished state.
- `C-flags-unit.log`, `C-flags-content.log`, `C-flags-J11ART-headless.log`:
  pass after setting the four completion flags.
- `C-headless-regressions.json`: all fourteen commands pass: unit/content/physics,
  J03C01–C04, J11ART, J12V08, J19A16, JAVC03A/B and JAVC04A/B.
- `C-rendered-regressions.json`: all five affected rendered checks pass: JAVC04A/B,
  J03C04, J11ART and JAVC03A.
- `C-final-scope.json`: only these two items' assets/art/effects fields against
  792e24b; no restricted paths, batches, rules or League specs; shared lists
  add-only and CI timeout preserved at 90 minutes.

Physics digest remains 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
Native evidence is Linux/Godot 4.5.2, Xvfb/Compatibility/llvmpipe and Dummy audio.
It validates asset playback and the four-voice pool, not a hardware ear/device
performance test. Software-renderer CPU samples are recorded in metrics.json;
no phone/GPU frame-rate certification is claimed. Source/audio hashes and exact
creation recipes are in ASSET-LEDGER.md.
