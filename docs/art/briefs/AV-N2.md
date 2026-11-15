# AV-N2 — Neon's opening six

Wave 13, Codex, High effort. Inputs: E18-C16 / E17-D13, the live Neon theme,
UI-6, and coordinator merge 81cda95 (through UI-7 and the UI-A4 claim).
DC-N3's six items are not part of this art batch.

## Sources and slots

Original OpenAI-generated illustrations, with no reference image, donor asset,
brand or sampled recording. Group A is Glow Ball, Prism Pin and Grip Tape;
group B is Spotlight, Afterimage and Laser Level. Exact prompts are adjacent
AV-N2-A-prompt.txt / AV-N2-B-prompt.txt. Source PNGs remain byte-identical.
AtlasTexture regions select each subject's padded alpha bounds within its third.

Each stable ID below fills card, icon, in_play, rarity_treatment, activation,
sound and reduced_motion. `tools/author_neon_n2_items.py A|B` reproduces the
resources and audio, preserving flags. Artwork/effects_audio are enabled only
after native validation; other completeness fields remain coordinator-owned.

| ID | Identity / host appearance | Visible and audible effect |
|---|---|---|
| ball.glow | Mint swirls in deep teal resin; stable mint-ribbon material | Curved launch leaves a short mint trail; reduced mode keeps one still arc at the ball. Paid curved-strike row shows exact +5 Mult with a glass note. |
| pin.prism | Opaque ivory, cyan and lavender facets; silver neck | Actual curved knockdown has a small facet cue; paid row displays exact +25 Value with a high glass note. Straight falls stay silent. |
| ball_mod.grip_tape | Indigo tape coil with cyan ticks; narrow textured-looking host belt | Committed curved launch has a HOOK x1.4 annotation and cloth stroke. This is a physical identity, not an invented score award. |
| pin_mod.spotlight | Small brass cinema lamp and clamp; native collar and lens | Lens lights only when this host is the first pin directly knocked down by a curved ball; a FIRST HIT cue precedes its exact paid +3 Mult. Dry wood click. |
| charm.afterimage | Teal ball pendant with a lavender second silhouette | Two short arcs settle around the actual paid spare multiplier, x1.5, with a soft swish. |
| charm.laser_level | Brass spirit level, mint bubble and cyan line | Paid straight-frame cue shows the actual fallen count, count ticks and exact Value, with a dry click. Curved frames stay silent. |

All physical observers read committed launch/tracker facts. No rule or physics
field is written. The existing first-direct helper supplies Spotlight's identity;
Prism reads per-roll knockdowns, not a frame-wide inferred curve. Grip Tape and
Spotlight preserve the host's skin and silhouette and add no collision bodies.
Ability-effects-off suppresses cues, trails and the Spotlight flare; static
identities remain. Reduced motion/flash holds cue progress and removes the trail.

Original deterministic foley: existing author_foley.py, mono 16-bit PCM,
22050 Hz, 0.32 s, normalized peak 0.48; existing four-voice mix/volume/mute.
Hashes and exact recipes are in ASSET-LEDGER.md.

## Evidence

JAVN2 extends the real J03C16 journey: buys/places all six, retains the independent
1012/2015/720 banks and explanations, and lets each score reveal finish naturally.
It captures native curved trail/first-hit/paid rows, six shop and six Binder cards,
the Grip Tape host, then a real reduced-motion Grip Tape cleanup (bank 1012).
JAVN2C and JAVN2BC show canonical cards, 44px icons, normal/reduced cues and count
specimens. These contact specimens are illustrations, not claimed earned rewards.
Unit projection cases cover straight/curved, first/non-first and strike/spare
eligibility, exact amounts, the ten fallen positions and immutable resolver data.

No physical-phone or hardware-audio trial is claimed. Missing hooks: none.
