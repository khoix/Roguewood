# AV-N1 — Neon's unlock spine

Wave 13, Codex. High effort. Two bounded three-item groups, based on UI-6
333c0af merged into codex/roguewood-build. No DC-N3–N5 art is included.

## Inputs and provenance

Read E18-C15, E17-D12 and Bumper Guard's E17-D04 record, E22-L02's live
binding notes, UI-6 and WAVE12-CODEX. Original generated illustrations:

- A: Oilskin Ball, Laser Ball, Tempo Pin; prompt AV-N1-A-prompt.txt.
- B: Neon Sign, Blacklight, Bumper Guard; prompt AV-N1-B-prompt.txt.

Both sources are 2172×724 RGBA PNGs, created with OpenAI image generation.
No external references, brands, downloaded art or sampled recordings. Original
source PNGs are retained unchanged. Atlas regions select each illustration's
alpha bounds within its own third, with 12px padding. No resampling, repainting
or alpha removal. The shared canonical card supplies labels, rarity and foil.
`tools/author_neon_items.py A|B` recreates resources and deterministic PCM;
it preserves completeness flags. Assets and hashes are in ASSET-LEDGER.md.

## Identities and presentation

| ID | Identity and physical marking | Activation |
|---|---|---|
| ball.oilskin | Petrol resin, teal marbling, silver beads; spatially stable beaded shader | Oil drops and OIL HOLD on an actual committed oil-hold launch; short swish, no score bonus |
| ball.laser | Indigo resin, cyan equator and crosshair | A short line at the measured sweet/perfect target crossing; paid score cue counts accurate rolls and displays the resolver's Mult amount; glass ping |
| pin.tempo | Ivory pin, paired neck rings and dark meter band | The paid row fills one or two meter bars, with the actual accurate count and Value; dry metronomic wood click. Clean/miss frames stay silent |
| charm.neon_sign | Hanging silver/enamel RW tube plaque | One or two lit letters from the paid accurate count of a curved frame, with exact Mult; bright glass note |
| ball_mod.blacklight | Violet lamp cartridge with brass mount | Two narrow violet host rings preserve its skin and holes; a paid curved-strike flare and exact multiplication cue; low glass note |
| ball_mod.bumper_guard | Ribbed rubber U-guard, silver shell, inward chevrons | Small host brackets; a local bumper rail and inward arrow only when the tracker records the rebound. Separate paid penalty cue, with the floor explained in the native log; rubber thump |

All six fill `icon`, `card`, `in_play`, `rarity_treatment`, `activation`,
`sound`, and `reduced_motion`. Prefixes are the slot followed by the stable
item ID. Resource paths are `assets/items/neon/`; audio is
`assets/audio/sound.<item-id>.wav`. In-play is a ShaderMaterial for balls and
Tempo, a cosmetic PackedScene for the modifications, and the static identity
texture for Neon Sign (the live equipment rail consumes its icon).

Reduced motion or flash fixes animated cue progress, retaining count, amount,
rail, arrow and measured beam. Ability-effects-off suppresses these annotations;
identities remain. Sound uses the existing four-voice priority/mute/volume mix.
All audio is mono 16-bit PCM, 22050 Hz, 0.32 s, peak 0.48 before the game mixer.

## Evidence design

JAVN1 subclasses J03C15, retaining every original shop purchase, replay,
explanation and independent bank. Its only change to reveal timing is to let
the native score sequence finish without the inherited tap-to-finish. It
captures each paid row, measured Laser beam and real rebound. A subsequent
Oilskin frame and Binder visit extend the same attempt. Purchases and throws
are real input; the parent's logged wallet, eligibility and gate fixtures stay.

JAVN1C / JAVN1BC show the six canonical cards, 44px icon and reduced identities,
normal cues and static count specimens 0/1/2. Contact specimens illustrate
states; they do not claim to be earned gameplay rewards. Unit cases resolve
actual zero/one/two-accurate frames and qualifying/nonqualifying attachments,
then verify exact projection and immutable input data. No rule function is
replaced, no physics or scoring field is written by the presentation.

## Limits

Oilskin's native extra frame is on House Oil. Its cross-oil behavior remains
the coordinator's mechanics/physics evidence; the cue reads `oil_hold` on any
lane without making a new physics claim. No physical-phone/audio-device trial.
AV-N2 and the live Neon theme tail are separate, unfinished Wave 13 claims.
