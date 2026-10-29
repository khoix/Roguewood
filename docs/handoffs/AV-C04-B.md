# AV-C04-B — Chalk Grip, Spin Wax, Coin Slot

Implementation: DONE. Codex / codex/roguewood-build. Base `e47b7c0`,
AV-C04-A pushed and remote SHA/clean tree verified before this batch.

## Before

Three items: ball_mod.chalk_grip, ball_mod.spin_wax, ball_mod.coin_slot. Six
exact declared D04 landed IDs each: icon, card, rarity_treatment, activation,
sound, reduced_motion. No invented in_play ID. Flags only after native checks.

Original generated three-object source sheet, unchanged PNG plus prompt/hash;
AtlasTexture views only. Chalk's grooved block, wax's notched puck and coin's
slotted plate have distinct monochrome silhouettes. Host overlays: small chalk
crescent, paired wax sheen strokes, tiny slot plate. Hook/Hammer materials,
emblems, holes, silhouette and physics stay visible/unchanged. Spin Wax may add
only a narrow segmented accent beside the actual committed curve trail.
Original vector glyphs and synthesized PCM material foley, resolver-owned awards.

JAVC04B: actual shop purchases onto separate Hook/Hook/Hammer card UIDs, owned
shop badge, native hand and inspector, binder and menu reload. Explicit seeded
hand fixtures may use CardDeck.create_with on the already-purchased UIDs to
exercise each condition; all arming, consumption, throws, reports and banks are
native. Chalk spare-only +2 per used roll; Wax any-roll-curved +4 per used roll,
straight quiet; Coin strike-only $2 after bank, spare/open quiet. Independent
resolution with actual frame_mods; controls/reduced/Skip/4x and both viewports.
Contact proofs at 32/64/192px with grayscale/silhouette and normal/static effects.
Unit/content and affected native journeys headless/rendered before commit/push.

Next: AV-C04-C (Echo Charge, Lantern; High), then House theme (High). No future
modification flags, rules/physics/persistence or League specification edits.

## Completion evidence — 2026-10-29

The interrupted rendered check from checkpoint `6adfde3` was resumed with the
current test script and completed in full. All eighteen exact resource paths
are bound; artwork and effects_audio are true for these three items only.

Native JAVC04B passed headless (checkpoint's final script) and rendered (this
session). Real shop payments, separate Hook/Hook/Hammer UIDs, hand/inspector,
owned shop, binder and menu reload all passed. Every modified card was armed,
consumed into discard and recorded in frame_mods by the game. Cosmetic aim and
rolling bodies retain their host identity, mass and collision. All three real
host close-ups and 32/64/192px color/grayscale/silhouette contacts were inspected.

| Native case | Bank / income | Modification cue |
|---|---|---|
| Coin Slot open | 0 / $0 | Quiet |
| Spin Wax curved strike | 1260 / $0 | One +4 Mult; actual curved trail accent |
| Chalk Grip spare | 480 / $0 | One +2 Mult for the used card |
| Coin Slot strike | 560 / $2 | One payout, after bank |
| Spin Wax straight open | 0 / $0 | Quiet; no curve accent |
| Chalk Grip strike | 700 / $0 | Quiet |

Every bank and fact set matches independent resolution using actual reports,
actual release grades and frame_mods. These observed totals are fixture results,
not hardcoded score replacements. Native 4x replay preserves cue details/order;
mute, zero volume, disabled effects, reduced motion/flash and Skip preserve banks.
All three cues started their real audio resources; maximum active voices was four.

Validation logs and captures (ignored; CI uploads the native/contact folders):
- `artifacts/wave6/validation/B-final-rendered.log` and
  `artifacts/av-c04-b/native/rendered/metrics.json`: complete rendered PASS.
- `B-final-headless.log`, `B-contact-headless.log`, `B-contact-rendered.log`,
  `B-regression-A-headless.log`, `B-regression-C04-headless.log`: checkpoint
  PASS evidence retained; implementation was unchanged on resume.
- `B-flags-unit.log`, `B-flags-content.log`, `B-flags-J11ART-headless.log`:
  PASS after setting the three completion flags.
- `B-regression-A-rendered.log`, `B-regression-C04-rendered.log`: PASS on the
  completed catalogue. The former preserves Brass/Leaf/Keystone and their repeats;
  the latter buys/attaches all eight C04 modifications and checks strike/open banks.
- `B-J11ART-rendered.log`: PASS, including required icons for the newly completed items.
- `B-final-scope.json`: only assigned assets and art/effects flags changed against
  `e47b7c0`; restricted paths untouched; shared qa.py/workflow edits add-only,
  upload path inside its list and 90-minute CI timeout preserved.

Linux Godot 4.5.2 / Compatibility / Xvfb llvmpipe evidence, not physical-phone
certification. Rendered CPU measurements are slow under this software renderer:
frame-wise p95 process samples span about 161–307 ms and draw calls reach 907.
No GPU/device frame-rate claim. Dummy audio validates playback starts and voice
limits, not an ear review on hardware. A's earlier full invariant/regression
matrix remains documented in AV-C04-A.md; no rules or physics were changed here.

Local rerun environment: source `/tmp/wave2_env.sh` (DISPLAY=:99, GODOT_BIN and
XDG directories), then use repository `python3 tools/qa.py` commands. Native
Godot execution needs network-enabled sandbox access here. Never commit captures.

Next: AV-C04-C, Echo Charge and Lantern (High), then E22-L01-ART House theme
(High). Keep codex/roguewood-build; no PR to main. Coordinator integrates this
branch. The coordinator advanced to `5b9a965` during the pause with C05–C07;
claims are unchanged. This batch retains the agreed `046b04d` merge base so the
coordinator can integrate its scoped art work with those concurrent mechanics.
