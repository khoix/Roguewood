# AV-C04-B — Chalk Grip, Spin Wax, Coin Slot

Implementation: IN_PROGRESS. Codex / codex/roguewood-build. Base `e47b7c0`,
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

## Usage checkpoint — 2026-10-29

Paused at the owner's request to conserve usage. This is implementation work in
progress, not a user/review approval dependency. The containing checkpoint commit
saves the complete working tree on codex/roguewood-build.

Implemented: all eighteen exact asset paths, generated source/prompt, original
foley/glyphs, chalk crescent/wax strokes/slot host overlays, native hand and
inspector badges, narrow committed-curve trail accent, native journey/contact
checks, unit cases and add-only CI steps/upload path. Provenance is in the ledger.
All three artwork/effects_audio flags remain FALSE.

Verified PASS: unit; JAVC04B headless including the latest card-consumption,
rolling-host and straight-trail assertions; JAVC04BC headless/rendered;
JAVC04A headless; J03C04 headless. Initial headless outcomes: Coin open 0; Wax
curved strike 1260; Chalk spare 480; Coin strike 560 and $2; Wax straight 0;
Chalk strike 700 with no Chalk bonus. Actual accuracy grades may change these
banks; every frame compares independent resolution using actual frame_mods.

The full rendered JAVC04B run was deliberately stopped at the usage checkpoint
(after about seven minutes). It has NOT passed. Partial shop/hand/inspector/binder,
all three host close-ups, rolling and activation captures exist and were visually
inspected, but its final conditions/metrics must be rerun. The pipeline used an
older revision of the newest assertions; rerun the current script. No final
content-with-flags check or post-B rendered regression matrix is claimed.

Resume first: run `python3 tools/qa.py e2e --journey JAVC04B --rendered` with
DISPLAY/XDG/Godot environment below, then inspect its log/captures and fix any
failures. The harness orders Wax's curved frame before The Surveyor, whose
Dead Straight rule correctly suppresses spin. Its roll loop checks
FrameBuilder.is_complete so a strike does not wait for a nonexistent second roll.
Seeded hand fixtures call CardDeck.create_with on real owned card UIDs; no
attachment, roll, effect or bank is fabricated.

After the full native pass: set only these three art/effects flags, rerun unit,
content and affected journeys in both modes (A, B/contact, J03C04 and J11ART;
expand only for actual shared changes), inspect captures, audit scope, mark this
batch DONE, commit/push and verify remote SHA/clean tree before AV-C04-C.

Local environment: `/tmp/wave2_env.sh` exports DISPLAY=:99, GODOT_BIN for
`/workspace/tooling/Godot_v4.5.2-stable_linux.x86_64`, and XDG directories under
/workspace/tooling. Tools need network-enabled execution for native Godot in
this sandbox. Logs/captures are ignored under `artifacts/wave6/validation/`
and `artifacts/av-c04-b/`; never commit captures. Full rendered run timeout is
900 seconds on two-CPU Xvfb/llvmpipe. All owned test workers were stopped.
