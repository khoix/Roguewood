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

## Wave 1 / E19-A05

`assets/items/sources/e19-a05.png`: unchanged original built-in generated source,
no references; exact prompt in briefs/E19-A05-source-prompt.txt. SHA256
`147ff9dc5c40ac24ebc4a98720e5c33bb22a8f6a7549779d835e9a7a61bc561e`.
Four distinct original pendant designs (coin cart, three-pin turkey fan, coin
hourglass, final-sector watch) use authored AtlasTexture views for card/icon/
in-play/static reduced slots and Common-family Uncommon/Rare frames. All four
native purchases, equipped identities and binder cards verified; 192px/48px
contact and reduced view inspected. Artwork true, effects/audio false. No
third-party material, exclusive-rights or clearance claim. Phone remains E26.

## Wave 1 / E19-A06

`assets/items/sources/e19-a06.png`: original unchanged built-in generation,
no references. Exact prompt retained; SHA256
`d1f853e5652e1eccb28e0bb05dee997cedd5d02047ad39c618829030eb5ef6b8`.
Authored AtlasTexture bounds retain full ticket edges and badge loops. Encore's
layered tickets, Standing Order's sealed clipboard, Dead Straight's hexagonal
survey seal and Clean Sweep's round broom seal are distinct constructions.
Original Common/Uncommon frames and explicit type/rarity text. Card/icon/in-play/
static reduced slots use the same identities. Charms verified in actual shop and
binder; rule badges verified by stable rule ID through both complete slice
encounters. Artwork true, effects/audio separate. No external material or
exclusive-rights/clearance claim; phone readability stays E26.

| E19-A07 kit.house | Original generated pixel illustration; no external reference | `assets/items/sources/e19-a07.png`; unchanged transparent source, AtlasTexture views | `docs/art/briefs/E19-A07-prompt.txt` | SHA-256 `62c3b4e3f5439fe9ec4d37ae425e3b7231f208a860cf03eb095a4ca40499f6a5` | Native binder/equipment/reduced and 192/48px contact inspected |

| E21-R01 rival.surveyor | Original generated six-state atlas, no external reference | `assets/rivals/surveyor.png`; runtime regions, source unchanged | `docs/art/briefs/E21-R01-prompt.txt` | SHA-256 `a367e49bd6772a5a3cfde7508269251001ec08bc5466a2e675cb26b852ea9d64` | 180/72px contact and native intro/reaction |
| E21-R01 Dead Straight | Original procedural ruler/wood snap and lock glyph | `assets/audio/dead_straight.wav`, `assets/effects/dead_straight.tres` | `tools/author_foley.py dead_straight wood 1270 0.23`; no samples | Peak ≤0.48; four-voice bounded mix | Native mute/zero-volume/effect controls; desktop only |

| E21-R02 rival.custodian | Original project-owned E12 reference, new six-state generated atlas with correction pass | `assets/rivals/custodian.png`; unchanged source | `docs/art/briefs/E21-R02-prompt.txt` | SHA-256 `89ba126e185923c47a873ec01a7cff12bbe349cdc31da414aadfe135b449f8d4` | 180/72px and real intro/reaction/result, portrait/landscape inspected |
| E21-R02 Clean Sweep | Original brushed cloth PCM and diagonal sweep glyph | `assets/audio/clean_sweep.wav`, `assets/effects/clean_sweep.tres` | `tools/author_foley.py clean_sweep cloth 600 0.4`; no samples | Peak ≤0.48 | Actual open-frame rule-bank cue, shared sound controls |

| E20-V01 ball.echo | Original echo vector recipe + metal PCM; existing final identity illustration | `assets/effects/ball_echo.tres`, `assets/audio/ball_echo.wav` | `tools/author_effect_batch.py E20-V01`; config in batches.json | Audio SHA-256 `0ec84db3ad8d95d768ce8bd91bd544635097b2b89ed4e17d212de3cbed4a4fbf` | Native activation, reduced, skip/mute; 64px contact |

| E20-V01 charm.encore | Original tickets vector recipe + paper PCM; existing final identity illustration | `assets/effects/charm_encore.tres`, `assets/audio/charm_encore.wav` | `tools/author_effect_batch.py E20-V01`; config in batches.json | Audio SHA-256 `158120b13ad40555628404fbf45b0867b2bc70b0783cc2ae4e34a9dc865a762d` | Native activation, reduced, skip/mute; 64px contact |

| E20-V02 pin.grower | Original growth vector recipe + wood PCM; existing final identity illustration | `assets/effects/pin_grower.tres`, `assets/audio/pin_grower.wav` | `tools/author_effect_batch.py E20-V02`; config in batches.json | Audio SHA-256 `330249cfeea3424f5f59601639e4c77256517f6f8d24998e5a897ec2f3c6e951` | Native activation, reduced, skip/mute; 64px contact |

| E20-V02 charm.patient_investor | Original hourglass vector recipe + metal PCM; existing final identity illustration | `assets/effects/charm_patient_investor.tres`, `assets/audio/charm_patient_investor.wav` | `tools/author_effect_batch.py E20-V02`; config in batches.json | Audio SHA-256 `88eeef2a57340708098a63f9c9d6837015e272526234c57ef67cb7cd69f8d214` | Native activation, reduced, skip/mute; 64px contact |

| E20-V03 pin.gold | Original coin vector recipe + metal PCM; existing final identity illustration | `assets/effects/pin_gold.tres`, `assets/audio/pin_gold.wav` | `tools/author_effect_batch.py E20-V03`; config in batches.json | Audio SHA-256 `76737c0c6adddd60e56add52b7013e34faeb4900b34f03f7235a47cb71847ee1` | Native activation, reduced, skip/mute; 64px contact |

| E20-V03 charm.gold_rush | Original coins vector recipe + metal PCM; existing final identity illustration | `assets/effects/charm_gold_rush.tres`, `assets/audio/charm_gold_rush.wav` | `tools/author_effect_batch.py E20-V03`; config in batches.json | Audio SHA-256 `f1c21c8af03b397cd571ec4ed66b4300d32c0d40ff7e7bb8cf862e365bad1d3f` | Native activation, reduced, skip/mute; 64px contact |

| E20-V04 pin.anchor | Original brace vector recipe + metal PCM; existing final identity illustration | `assets/effects/pin_anchor.tres`, `assets/audio/pin_anchor.wav` | `tools/author_effect_batch.py E20-V04`; config in batches.json | Audio SHA-256 `6dc1d07e685aaf72572f8eca71c7afc60e25db8930fd440416621b54e00e3cad` | Native activation, reduced, skip/mute; 64px contact |

| E20-V04 charm.standing_order | Original tabs vector recipe + paper PCM; existing final identity illustration | `assets/effects/charm_standing_order.tres`, `assets/audio/charm_standing_order.wav` | `tools/author_effect_batch.py E20-V04`; config in batches.json | Audio SHA-256 `a524004542c871fc5464fe93066fa906140d421f815749f44807915049fde300` | Native activation, reduced, skip/mute; 64px contact |

| E20-V04 charm.lone_survivor | Original isolate vector recipe + metal PCM; existing final identity illustration | `assets/effects/charm_lone_survivor.tres`, `assets/audio/charm_lone_survivor.wav` | `tools/author_effect_batch.py E20-V04`; config in batches.json | Audio SHA-256 `83628b3329bd4225dbe21012cee2221b57d5949c8bf3bcea78e0e3fbeb8b084d` | Native activation, reduced, skip/mute; 64px contact |

| E20-V05 charm.finisher | Original flag vector recipe + cloth PCM; existing final identity illustration | `assets/effects/charm_finisher.tres`, `assets/audio/charm_finisher.wav` | `tools/author_effect_batch.py E20-V05`; config in batches.json | Audio SHA-256 `9fda344cd6ccd5392e9f3772df08c59b002cb2373dd10fe782c769f7b5c259de` | Native activation, reduced, skip/mute; 64px contact |

| E20-V05 charm.turkey_club | Original feathers vector recipe + wood PCM; existing final identity illustration | `assets/effects/charm_turkey_club.tres`, `assets/audio/charm_turkey_club.wav` | `tools/author_effect_batch.py E20-V05`; config in batches.json | Audio SHA-256 `e838f0a579f0c18ca25a3f567b4afba15418e6820f1118d510138bbfca90497a` | Native activation, reduced, skip/mute; 64px contact |

| E20-V05 charm.last_chance | Original clock vector recipe + metal PCM; existing final identity illustration | `assets/effects/charm_last_chance.tres`, `assets/audio/charm_last_chance.wav` | `tools/author_effect_batch.py E20-V05`; config in batches.json | Audio SHA-256 `c2913a99e0ec7bee4b9bc9368972bfcdd24edebad1992d973250d09ec17d2187` | Native activation, reduced, skip/mute; 64px contact |

| E20-V06 charm.flat_bonus | Original pips vector recipe + wood PCM; existing final identity illustration | `assets/effects/charm_flat_bonus.tres`, `assets/audio/charm_flat_bonus.wav` | `tools/author_effect_batch.py E20-V06`; config in batches.json | Audio SHA-256 `11075a72dc4047e03a0628f4350743219b0b74ecbf0c14d3968e2fdea62bb8c5` | Native activation, reduced, skip/mute; 64px contact |

| E20-V06 charm.spare_change | Original halves vector recipe + metal PCM; existing final identity illustration | `assets/effects/charm_spare_change.tres`, `assets/audio/charm_spare_change.wav` | `tools/author_effect_batch.py E20-V06`; config in batches.json | Audio SHA-256 `3730087cbee373c660ec3da016596d4ae7e69ee5602b17ae49800de04a697b11` | Native activation, reduced, skip/mute; 64px contact |

| E20-V06 charm.house_favorite | Original gable vector recipe + wood PCM; existing final identity illustration | `assets/effects/charm_house_favorite.tres`, `assets/audio/charm_house_favorite.wav` | `tools/author_effect_batch.py E20-V06`; config in batches.json | Audio SHA-256 `8d5627b0976018db1ef186551b2c86cedb8b902fec6435bce831109908eaf34e` | Native activation, reduced, skip/mute; 64px contact |

| E20-V07 ball.hook | Original hook vector recipe + rubber PCM; existing final identity illustration | `assets/effects/ball_hook.tres`, `assets/audio/ball_hook.wav` | `tools/author_effect_batch.py E20-V07`; config in batches.json | Audio SHA-256 `aa7cf92c4883ccd0c9f758c291bb6dfa7953487ca5f2141783ce1d12e5fcdc03` | Native activation, reduced, skip/mute; 64px contact |

| E20-V07 charm.hook_artist | Original nib vector recipe + paper PCM; existing final identity illustration | `assets/effects/charm_hook_artist.tres`, `assets/audio/charm_hook_artist.wav` | `tools/author_effect_batch.py E20-V07`; config in batches.json | Audio SHA-256 `640284671c7734a4de728d76729d2156857863bf202e861f644b5db87583195b` | Native activation, reduced, skip/mute; 64px contact |

| E20-V07 ball.hammer | Original impact vector recipe + wood PCM; existing final identity illustration | `assets/effects/ball_hammer.tres`, `assets/audio/ball_hammer.wav` | `tools/author_effect_batch.py E20-V07`; config in batches.json | Audio SHA-256 `e4fe22e2c05b2e6d550e66273481371eeca4984a7126ee2fcc18cf0894c859c2` | Native activation, reduced, skip/mute; 64px contact |

| E20-V07 pin.rubber | Original elastic vector recipe + rubber PCM; existing final identity illustration | `assets/effects/pin_rubber.tres`, `assets/audio/pin_rubber.wav` | `tools/author_effect_batch.py E20-V07`; config in batches.json | Audio SHA-256 `2a490e5ac6d7d67d909ed57a743185a7d03a62e2eb74469b3d9972633c77dc6b` | Native activation, reduced, skip/mute; 64px contact |

| E20-V07 pin.wood | Original chips vector recipe + wood PCM; existing final identity illustration | `assets/effects/pin_wood.tres`, `assets/audio/pin_wood.wav` | `tools/author_effect_batch.py E20-V07`; config in batches.json | Audio SHA-256 `c7c78abe48d57bd4999f49c52af777d36fd1130f91272e759834208ced29f1ef` | Native activation, reduced, skip/mute; 64px contact |

| E20-V07 pin.ruby | Original facets vector recipe + metal PCM; existing final identity illustration | `assets/effects/pin_ruby.tres`, `assets/audio/pin_ruby.wav` | `tools/author_effect_batch.py E20-V07`; config in batches.json | Audio SHA-256 `ccac514f9361c734b2d119c6fbfff8794ab069e0063a34ac20b1f80be9c6d4e5` | Native activation, reduced, skip/mute; 64px contact |
