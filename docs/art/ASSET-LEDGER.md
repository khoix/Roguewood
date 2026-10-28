# E11 source and asset ledger

| Asset | Source | Rights/provenance | State | Runtime use |
|---|---|---|---|---|
| ART-BIBLE.md | Original Codex-authored project specification | Written for this repository; no external text/assets copied | Proposed | Specification only |
| palette.json | Original project palette/token data | Written for this repository | Proposed | Not wired to gameplay |
| assets/art_direction/candidate-01.png | Built-in image generation from original project brief | AI-generated; no external reference image or branded artwork supplied; do not claim legal clearance or exclusive authorship | Inspected direction candidate; geometry/layout defects in VISUAL-REVIEW.md | Reference only, not a screenshot or sprite sheet |
| Typography | No external font imported | Font redistribution rights not yet selected/verified | Provisional engine fallback | Existing engine UI only |

No production ball/pin/card asset completeness flags are advanced by this ledger. Generated lettering is not production typography. Reference images must be decomposed into authored runtime assets and live UI before engine acceptance. Existing engine/source licenses remain unchanged. No downloaded texture, font, icon pack or third-party brand asset was introduced by E11.

Exact original and edit prompts are in candidate-01-prompt.txt and candidate-01-edit-prompt.txt. Retained PNG is the second built-in generation, unchanged at1024×1536. No external image was used for initial generation; edit input was the first generated candidate. This file is source concept art, not a rendered game capture.

Source transport: the binary upload could not complete through the connector. The unchanged PNG is stored losslessly as numbered base64 parts in assets/art_direction/candidate-01-source/. Run `python3 assets/art_direction/restore_concept.py` to reconstruct it; the script verifies SHA256 before writing. The reconstructed PNG is ignored to avoid duplication.

## Wave 1 / E19-A01 source and runtime resources

| Assets | Source / rights basis | State / use |
|---|---|---|
| `assets/items/balls/a01-source.png` | Original built-in generation from `briefs/E19-A01-source-prompt.txt`, no external image/brand reference. Generated output; no claim of exclusive copyright or independent legal clearance. Unchanged RGBA 1280×1280 source. SHA256 `d9e0b9184fef96226157eca6e74efc32a772593b4870cd1d82833d8d32172c7a`. | Four distinct ball illustrations; source art, not a screenshot. |
| `assets/items/balls/{house,hook,hammer,echo}-card.tres` | Original Codex-authored AtlasTexture regions of the source above; no added third-party material. | Card/icon/static reduced-motion slots. Native 48px contact sheet inspected; in-engine inspection wired. |
| `assets/items/balls/identity.gdshader` and four `*-material.tres` | Original repository-authored shader/material definitions, no external code or textures. | Object-local marbling/crescent/crossed bands/rings; no TIME or random animation. Refined engraved edging, riveted bands and stable local material grain; verified in-play. |
| Four `assets/items/balls/*-frame.tres` | Original repository-authored frames using E11 palette. | Common single border / Uncommon paired side border; text seals rendered by live UI. |

A01 completion: all four production `artwork` flags are true after native card,
shop, armed/committed material, reduced-effects and House binder verification.
Coordinator contract c611dea supplies stable IDs; the title fallback was removed.
No effects/audio completion is claimed. Phone testing remains E26. No third-party
texture, font, sound or logo was added.

## Wave 1 / E19-A02 source and runtime resources

| Assets | Source / rights basis | State / use |
|---|---|---|
| `assets/items/pins/a02-source.png` | Original built-in generation from `briefs/E19-A02-source-prompt.txt`; no external image or brand reference. Unchanged RGBA 1254×1254 output. SHA256 `2c0d0b0bb4e5bc596185d263a8b99364fa985f1aabe9f5f31926c71d95bb6967`. Generated output; no claim of exclusive copyright or independent legal clearance. | Four distinct pin illustrations; source art, never a game capture. |
| `assets/items/pins/{wood,ruby,gold,anchor}-card.tres` | Original AtlasTexture views of the source above. Object-centered 620px regions, transparent margins retained. | Card/icon/static reduced-motion slots; 192px cards and 48px icons inspected. |
| `assets/items/pins/identity.gdshader`, four material resources, `src/presentation/pin_identity.gd` | Original repository-authored shader and visual collar geometry, no external code/textures. | Wood bands/grain; Ruby faceted diamond inlays; Gold medallion and coin rings; Anchor chevrons/crossed braces/riveted foot collar. Object-local, no TIME or flash. Actual physical bodies retain their own collision/mass. |
| Four pin frame resources | Original repository-authored E11 palette frame definitions, matching A01. | Common single border / Uncommon paired sides, with explicit rarity text in item views. |

A02's four artwork flags are true after native purchase, placement, actual-body
material, mixed-rack impact, reduced-effects and binder checks. No effects/audio
flag is changed. The full unit suite has a separate historical E13 assertion
conflict (see A02 handoff); it is not reported as passing. No third-party asset
was introduced. Physical-phone readability remains E26.

## Wave 1 / E19-A03

- `assets/items/sources/e19-a03.png`: original built-in generation, followed by
  a spacing-only edit of that output; exact prompts in briefs/E19-A03-source-prompt.txt.
  Unchanged RGBA source; SHA256 `90ed4c2a2d1edd84e10088c3411965632b7549d210e610451816a57cda24fd50`.
  No external reference, brand asset or exclusive-rights claim.
- Grower/Rubber card AtlasTexture views and Flat Bonus/Finisher charm views reuse
  that source for icons and static reduced slots. Charm in-play slots appear in
  the read-only equipped strip; pin in-play slots use original local shaders and
  Rubber's three authored visual rib meshes. Frames are original E11-family styles.
- Native shop purchase/placement, mixed physical rack, equipped strip, binder and
  reduced captures inspected. Four artwork flags true; effects/audio false.
  Shared E13 unit assertion remains a separately logged integration limitation.

## Wave 1 / E19-A04

Original unchanged RGBA 1254×1254 source `assets/items/sources/e19-a04.png`,
built-in generation without external references; exact prompt retained in
briefs/E19-A04-source-prompt.txt. SHA256
`c023a60703e6345ad69a6ff307f18207b7c0996bb6b0c8a5ca1066da115395e4`.
No exclusive-rights or legal-clearance claim. Four original AtlasTexture identities
(split coin, lone-pin arch, hooked nib, clubhouse) serve card/icon/in-play/static
reduced slots. Source pixels remain unchanged; row split y=600 retains complete
loops. Frames use authored Common and Rare structures plus explicit rarity text.
Native actual purchase/equipped/binder and 48px contact reviewed. Four artwork
flags true; ability/audio work stays in E20. No third-party asset introduced.
