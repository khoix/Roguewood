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

## Wave 2 — Clubhouse and D01 original identity art

Original illustrations generated with the image-generation tool for this project, from
the exact checked-in prompts below; no third-party reference images, logos or samples.
PNG outputs are retained byte-for-byte. AtlasTexture regions are runtime views, not
rewritten sources. Authored model geometry, static shaders and rarity frames are
original repository code. No E20 activation or audio is delivered by these batches.

| Asset | Original source and exact prompt | SHA-256 | Runtime / verification |
|---|---|---|---|
| E16-ART `deco.club_sign` | `assets/clubhouse/deco.club_sign.png`; `assets/clubhouse/sources/deco.club_sign.txt` | `14b048f477787961118232add3c5072097389d0647fa3e47f5b65d08bff25e39` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `deco.lane_trim` | `assets/clubhouse/deco.lane_trim.png`; `assets/clubhouse/sources/deco.lane_trim.txt` | `ee3475dae28a764bc6508da16da687627d9eec7e2302d8bb7f38d37670d02507` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `deco.trophy_case` | `assets/clubhouse/deco.trophy_case.png`; `assets/clubhouse/sources/deco.trophy_case.txt` | `2c450d32b7cd5f05d5ffb8d987f90004aac317ae03909185169819f35c85df14` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `plaque.custodian` | `assets/clubhouse/plaque.custodian.png`; `assets/clubhouse/sources/plaque.custodian.txt` | `b4aa13958a1499b47ae6a6493bf17bb9f7d4b07c065098a05c3a3abcbb85d01a` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `plaque.surveyor` | `assets/clubhouse/plaque.surveyor.png`; `assets/clubhouse/sources/plaque.surveyor.txt` | `004d81c4bac6121a1fd2867f2250f767b92d4941cdb2a9c9a3e08e31cc4020d8` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `ribbon.mixed_rack` | `assets/clubhouse/ribbon.mixed_rack.png`; `assets/clubhouse/sources/ribbon.mixed_rack.txt` | `70c132b6f9bd1867c633b3fff3f2ca152b01163a6160180cd296ded466970524` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `ribbon.spare_hand` | `assets/clubhouse/ribbon.spare_hand.png`; `assets/clubhouse/sources/ribbon.spare_hand.txt` | `493e20fa94a7f2af78d175650c18ecbd3f41998c000416836d89a4e6f83d5e61` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `ribbon.true_curve` | `assets/clubhouse/ribbon.true_curve.png`; `assets/clubhouse/sources/ribbon.true_curve.txt` | `4f314a7fdae5c3a79d43d38c2be45c2bc08909787d5fefd5f572376fc72b4530` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `trophy.house` | `assets/clubhouse/trophy.house.png`; `assets/clubhouse/sources/trophy.house.txt` | `6e2f3a87d9bae7b54a7569da6be50fdc9effaae4dc8f9ec29ce19b64445530dd` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E16-ART `trophy.house_campaign` | `assets/clubhouse/trophy.house_campaign.png`; `assets/clubhouse/sources/trophy.house_campaign.txt` | `5a68fe2897e07082e7c1633e707ac1d01fd152aa029fb8bed792dcbe92be6519` | 120px shelf and real J11ART; earned/not-yet, portrait/landscape |
| E19-A08 `ball.gold` | `assets/items/d01/source.ball.gold.png`; `assets/items/d01/source.ball.gold.txt` | `a023d9a258003e91be3ea7bdffc7c3be25b97dc21b78327ccf1d7e2e6a113771` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A08 `pin.glass` | `assets/items/d01/source.pin.glass.png`; `assets/items/d01/source.pin.glass.txt` | `1d34497e5b8daf2e315cdecc888b3bcbd9f9beb2e715b8a9a37020174b5d7aac` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A08 `pin.fuse` | `assets/items/d01/source.pin.fuse.png`; `assets/items/d01/source.pin.fuse.txt` | `8d3fa6632fa5021e42aa0815fa6613b33786727351a27433d07a5462c87b0ea1` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A08 `pin.crown` | `assets/items/d01/source.pin.crown.png`; `assets/items/d01/source.pin.crown.txt` | `2398e565ef9d257bb03689d14775c697345c947aff20e31da35934e0b16fce1a` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A09 `pin.echo` | `assets/items/d01/source.pin.echo.png`; `assets/items/d01/source.pin.echo.txt` | `7d64482fc058d1661eae116bd5dda58989b09cf3ecf3eb93bd3bbf36c5ee31d2` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A09 `consumable.nudge` | `assets/items/d01/source.consumable.nudge.png`; `assets/items/d01/source.consumable.nudge.txt` | `a592afd0330dce16835fe86bb34cb34486ec036dfeb392b0cb36c41b72083753` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A09 `consumable.reserve_call` | `assets/items/d01/source.consumable.reserve_call.png`; `assets/items/d01/source.consumable.reserve_call.txt` | `99c79eb4a6516970fdf3b30ec01f45b3e9db8f8aa70655b162c74f1f13f85266` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A09 `consumable.rule_waiver` | `assets/items/d01/source.consumable.rule_waiver.png`; `assets/items/d01/source.consumable.rule_waiver.txt` | `8bcd74fa3570f5f21065100c039c10e67a0e489b955bbd1628c051db4ae56600` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A10 `ball.spark` | `assets/items/d01/source.ball.spark.png`; `assets/items/d01/source.ball.spark.txt` | `23e740ca7934e99db172a7a4ca3894cc53b613025e980d3aaf392c8b902b982a` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A11 `ball.ghost` | `assets/items/d01/source.ball.ghost.png`; `assets/items/d01/source.ball.ghost.txt` | `a34aba1c6504563d03fac57b072afba6cdef3ca76ecd8c5241e02e212292884a` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |
| E19-A12 `ball.splitter` | `assets/items/d01/source.ball.splitter.png`; `assets/items/d01/source.ball.splitter.txt` | `32e11ba1bd51e951a4eb48bd710ece7f0f22a838d3969b753c91981c1b749a33` | 192px card / 48px icon, gray/silhouette comparison, static identity model where defined; native integration waits E18 |

## Wave 3 — original D02 Charm identities

Generated from the written briefs without external image references. PNG sources
are unchanged originals; adjacent text files preserve exact generation prompts.
Runtime AtlasTexture regions provide transparent-margin cropping. No image
resampling or editing was used. Four identity resources per Charm; activation
and sound remain future E20 work. Crown Jewel reuses the E12 full-card Epic foil
in its preview; reduced motion retains the static unshaded identity.

| Batch / item | Source and prompt | Source SHA-256 | Checks |
|---|---|---|---|
| E19-A13 `charm.pin_counter` | `assets/items/d02/source.charm.pin_counter.png`; `assets/items/d02/source.charm.pin_counter.txt` | `822792f26e48b6570cb482c5b77efae1f22a20a78ad6bb3fe254a95eb06fb244` | 192px card / 48px color, gray and silhouette; native shop/inventory/binder |
| E19-A13 `charm.hot_streak` | `assets/items/d02/source.charm.hot_streak.png`; `assets/items/d02/source.charm.hot_streak.txt` | `9ef239f44d73a79bc5ee74eb2b0a7bc25a31d0388016a16960ca3d79a768e261` | 192px card / 48px color, gray and silhouette; native shop/inventory/binder |
| E19-A13 `charm.last_stand` | `assets/items/d02/source.charm.last_stand.png`; `assets/items/d02/source.charm.last_stand.txt` | `3c10e878ac12b3687aa2b1c148941cf59c8e6bc37e58ee1c5dc2f7fb2ed5ece2` | 192px card / 48px color, gray and silhouette; native shop/inventory/binder |
| E19-A13 `charm.tip_jar` | `assets/items/d02/source.charm.tip_jar.png`; `assets/items/d02/source.charm.tip_jar.txt` | `9b444d6a86d206313ec3d576539b3746f79c0b78a5f70c9b15378a4b501ae488` | 192px card / 48px color, gray and silhouette; native shop/inventory/binder |
| E19-A14 `charm.banana_ball` | `assets/items/d02/source.charm.banana_ball.png`; `assets/items/d02/source.charm.banana_ball.txt` | `da28143f0a7a884a7ff3b985587ce0be33e7c9aaf6d57fc8727886f89fd735f5` | 192px card / 48px color, gray and silhouette; native shop/inventory/binder |
| E19-A14 `charm.plumb_line` | `assets/items/d02/source.charm.plumb_line.png`; `assets/items/d02/source.charm.plumb_line.txt` | `6d26c47ac0ce8465f347c21d0c93ed621f456a36d0490339779e6ca306292783` | 192px card / 48px color, gray and silhouette; native shop/inventory/binder |
| E19-A14 `charm.glass_cutter` | `assets/items/d02/source.charm.glass_cutter.png`; `assets/items/d02/source.charm.glass_cutter.txt` | `ab5c61cf53b09f4082dd81b99e6da7e2978e13a7c847d76eee2ef82d2794cd67` | 192px card / 48px color, gray and silhouette; authored only; native check after E18 |
| E19-A14 `charm.split_specialist` | `assets/items/d02/source.charm.split_specialist.png`; `assets/items/d02/source.charm.split_specialist.txt` | `9c8471b2533a04c538ba862ebfd4e528ba66be0080fd35638e93e1e652dedd1c` | 192px card / 48px color, gray and silhouette; authored only; native check after E18 |
| E19-A15 `charm.sweet_spot` | `assets/items/d02/source.charm.sweet_spot.png`; `assets/items/d02/source.charm.sweet_spot.txt` | `d2bbe7e2a29c772ff1d783f58d532a214a149f79e4efa46c56ee62c97592ef58` | 192px card / 48px color, gray and silhouette; authored only; native check after E18 |
| E19-A15 `charm.back_row` | `assets/items/d02/source.charm.back_row.png`; `assets/items/d02/source.charm.back_row.txt` | `d1d6a0a4a5da05000dd387207e9bc27f9fb098ad7e35feb15c214e799e0e872f` | 192px card / 48px color, gray and silhouette; authored only; native check after E18 |
| E19-A15 `charm.underdog` | `assets/items/d02/source.charm.underdog.png`; `assets/items/d02/source.charm.underdog.txt` | `5e299864fe901c59ac6d44e519b439f16344e8e22007e1df82e6c08cff4346d7` | 192px card / 48px color, gray and silhouette; authored only; native check after E18 |
| E19-A15 `charm.crown_jewel` | `assets/items/d02/source.charm.crown_jewel.png`; `assets/items/d02/source.charm.crown_jewel.txt` | `880d6b479cf49b2baa75e9296bfed431b1ce620e2d151d2f1537c80bcc84de88` | 192px card / 48px color, gray and silhouette; authored only; native check after E18 |

## Wave 4 — Glass native integration

E19-A16 reuses `source.pin.glass.png` and the five D01 identity resources
recorded above; no new or modified source image. `in_play.pin.glass` now attaches
under the actual pin body. The read-only saved break-row observer restores Wood
at the same body/slot. Native shop, inventory summary, binder, real Glass rack,
post-break and restored next-rack views: `artifacts/e19-a16/native/`. Diagnostic
close views use the same live bodies with a test-only camera move.

## Wave 4 — E20-V08 original ability effects and foley

Eight original vector glyph recipes reuse the final identity illustrations; no
external art or recordings. `tools/author_v08_effects.py` reads exact landed
D01/D02 IDs and emits recipes plus deterministic PCM through `author_foley.py`.
Reproduction parameters are also in `assets/effects/batches.json`. Glass, crack
and swish have separate original synthesis recipes; Hot Streak has a double-tap
pattern. Each WAV is mono 22,050 Hz / 16 bit, peak 0.48, 0.20–0.28 seconds.
Native playback, mute/volume, bounded mixing, causal and quiet cases are checked
in J12V08. Static reduced variants retain resolver counts and saved break slots.

| Batch / item | Original recipe | Resources | Audio SHA-256 |
|---|---|---|---|
| E20-V08 `charm.pin_counter` | `tally` / `paper`; 870 Hz parameter, 0.22s | `res://assets/effects/activation.charm.pin_counter.tres`; `res://assets/audio/sound.charm.pin_counter.wav` | `8a27f74c588c9a64b125dccd8a8fd3ebeead8b20e9986e822a1f0cb5f9e2312c` |
| E20-V08 `charm.hot_streak` | `flame_tally` / `wood`; 780 Hz parameter, 0.28s | `res://assets/effects/activation.charm.hot_streak.tres`; `res://assets/audio/sound.charm.hot_streak.wav` | `7bd86e68c0b5914d21f887cb722ea1d59f353566e2ce97a18fcb159bbf9b87ce` |
| E20-V08 `charm.last_stand` | `standing` / `wood`; 310 Hz parameter, 0.24s | `res://assets/effects/activation.charm.last_stand.tres`; `res://assets/audio/sound.charm.last_stand.wav` | `48330eb5372167d3f1576ddeffb82d84b084041e0ea714044f40eb35359a282a` |
| E20-V08 `charm.tip_jar` | `jar_drop` / `glass`; 1320 Hz parameter, 0.28s | `res://assets/effects/activation.charm.tip_jar.tres`; `res://assets/audio/sound.charm.tip_jar.wav` | `37388ef8d1568e6cec6052b71d940967d0a651d777c6f2bf6837b3119aba5389` |
| E20-V08 `charm.banana_ball` | `banana_strike` / `swish`; 630 Hz parameter, 0.28s | `res://assets/effects/activation.charm.banana_ball.tres`; `res://assets/audio/sound.charm.banana_ball.wav` | `b3e4c0f87ff68b9aa5175750ee253cabe386692f7f9d2ecd19574a6c966783df` |
| E20-V08 `charm.plumb_line` | `plumb` / `metal`; 860 Hz parameter, 0.2s | `res://assets/effects/activation.charm.plumb_line.tres`; `res://assets/audio/sound.charm.plumb_line.wav` | `6e1f3bb147563834d30ffab54d9ab28261ded74dd275651220a04d5f46c71d68` |
| E20-V08 `charm.glass_cutter` | `cutter` / `glass`; 2150 Hz parameter, 0.22s | `res://assets/effects/activation.charm.glass_cutter.tres`; `res://assets/audio/sound.charm.glass_cutter.wav` | `4117d3e29a078c9b9c9d075145bec81b0c0719a417aaebceb8ac3613fb44f050` |
| E20-V08 `pin.glass` | `crack` / `crack`; 1780 Hz parameter, 0.26s | `res://assets/effects/activation.pin.glass.tres`; `res://assets/audio/sound.pin.glass.wav` | `86a05c8189c47b480a3e6e7daf269a4cee4777ca882cb9af1393ae7de5f5522d` |

## Wave 5 — AV-C03-A original effects and retained identities

Crown Pin retains the original D01 identity; Crown Jewel and Split Specialist retain
the original D02 identity sets and E12 rarity treatment. No identity image edits.
`tools/author_c03_effects.py AV-C03-A` authors exact landed design IDs; vector
construction is in `ability_glyph.gd`. `author_foley.py` synthesizes original mono
22050 Hz, 16-bit PCM without samples, recordings or third-party material.
Crown uses brass-like resonance; Jewel uses a short inharmonic glass/gem accent;
Split uses a lower caliper tap. Crown zero is deliberately silent. Reduced-motion
and reduced-flash cues retain values and construction without animated movement.

| Item | Recipe / sound synthesis | WAV SHA-256 |
|---|---|---|
| `pin.crown` | `crown_last`; metal, 1180 Hz, 0.30 s; #e9c179; priority 3; peak 0.48 | `ac347a7a17551ba27b26c84c44e9035f21579878834151ff9c8c9f8541d88dca` |
| `charm.crown_jewel` | `jewel_last`; glass, 1660 Hz, 0.34 s; #d1b6e8; priority 3; peak 0.48 | `87bc6d101533ce1a29ea3b3ac79cf24e9bbb6cfc86cfe1ff7115510240e49d32` |
| `charm.split_specialist` | `split_leave`; metal, 640 Hz, 0.26 s; #b8d6d0; priority 2; peak 0.48 | `81603a66bb95eb7ca6752f97c162c8fa5483af4bfe31de68c78c2dda241f8c8f` |

Paths: `assets/effects/activation.<item-id>.tres` and
`assets/audio/sound.<item-id>.wav`. Native evidence: `artifacts/av-c03-a/`;
see `docs/handoffs/AV-C03-A.md` for purchase, binder, live rack and active/quiet checks.

## Wave 5 — AV-C03-B original effects and retained identities

Sweet Spot, Back Row and Underdog retain their original D02 identity resources.
Exact landed activation/sound IDs are authored by `tools/author_c03_effects.py
AV-C03-B`; glyph construction is in ability_glyph.gd. Native Back Row rack outlines
are cosmetic drawings from actual counted positions. No identity image edits.
Original deterministic mono 22050 Hz, 16-bit PCM; no samples or recordings. Sweet
Spot has a short glass-ring accent, Back Row a dry wood tap, Underdog a quiet
two-hit rising metal latch (0/55 ms, gains 0.65/1, second pitch ×1.045). Peak 0.48.

| Item | Recipe / sound synthesis | WAV SHA-256 |
|---|---|---|
| `charm.sweet_spot` | `grade_pair`; glass, 1490 Hz, 0.24 s; #a9d8d0; priority 2 | `99ffa00db94c6168c9942039653fef15f833589ae1a823a699f26b4f7856e604` |
| `charm.back_row` | `back_four`; wood, 530 Hz, 0.26 s; #d8c498; priority 2 | `57a1e8278ccfc734c8cfad1945633e74016175873beb970de4ba5188cb5b8bc9` |
| `charm.underdog` | `half_target`; metal, 470 Hz, 0.30 s; #c7c6df; priority 3 | `f4bcce135836cc1ebc4dae472eedef5c76e5eae1a05613362af948a4e1c831d0` |

Paths: `assets/effects/activation.<item-id>.tres` and
`assets/audio/sound.<item-id>.wav`. Native/64px evidence: `artifacts/av-c03-b/`.
Reduced motion/flash freezes the same grade, position or threshold construction.
Native text and resolver counts remain authoritative.

## Wave 6 — AV-C04-A identity, overlays, effects and sound

Brass Cap, Gilt Leaf and Keystone: original AI-generated pixel-art illustrations
from OpenAI image generation, 2026-10-29. The original RGBA PNG is retained
unchanged at `assets/items/d04/source.AV-C04-A.png`; its exact request is
`source.AV-C04-A.txt` in the same folder. No external sample, brand or reference
image was supplied. Generated work carries no claim of exclusive rights.

Source SHA-256: `0f7a0a7e6aa85a7166b57ade656e035702c79cf733f0ff20d0c326710ffe5c37`.

`tools/author_c04_art.py AV-C04-A` binds the six declared D04 IDs per item:
icon, card, rarity treatment, activation, sound and reduced motion. AtlasTexture
regions measure opaque object bounds, ignoring near-invisible alpha specks;
they do not edit or resample the PNG. No invented in-play design slot. Badge
views reuse the icon. Cosmetic meshes in `assets/items/d04/overlay.gd` are
original code-authored geometry: a small dome (side plate on Crown), partial
torn leaf, and a trapezoid plate with rivets. The leaf/stone patches sample
their exact declared icon views on tiny unshaded alpha-cut quads, retaining
material detail in the dark lane without adding lights or recolouring the host. No collision shapes or host edits.

Original vector cues: dome/+Mult, torn edge/after-bank coin, counted trapezoid
and actual fallen-slot outlines in the rack diagram.
All amounts, counts, repeated sources and phases come from resolver events.
Original deterministic synthesized mono 22050 Hz, 16-bit PCM; no recordings or
samples. Native audio-start assertions and four-voice limits are verified by
JAVC04A; this is not a physical-device listening claim.

| Item | Recipe / synthesis | WAV SHA-256 |
|---|---|---|
| `pin_mod.brass_cap` | `cap_tick`; metal, 1060 Hz, 0.19 s; priority 2; peak 0.48 | `793f50650cc4882b353b488f160630633a8346aa5debea46be3a4bdf95993cd4` |
| `pin_mod.gilt_leaf` | `leaf_coin`; soft paper plus one 1180 Hz coin tick at 70 ms, 0.25 s; priority 2; peak 0.48 | `047942914b8cede99fe0090baa418445384be9fcfb6a910fc37861a53566d137` |
| `pin_mod.keystone` | `key_count`; wood, 420 Hz, 0.28 s; priority 3; peak 0.48 | `56a408d3cc96fcd093e32a1237149c68d78adbd3c97948c8daf8859204493ecd` |

Identity resources: `assets/items/d04/<design-asset-id>.tres`. Recipes:
`assets/effects/activation.<item-id>.tres`; sounds:
`assets/audio/sound.<item-id>.wav`. Native and 32/64/192px, grayscale/silhouette,
normal/reduced captures: `artifacts/av-c04-a/` (ignored, never committed).
See `docs/handoffs/AV-C04-A.md` for the verification record and scope.
