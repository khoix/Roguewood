# AV-N4 — Neon Controlled Curve and shop upgrades

Source: E17-D15, E18-C18, AV-N1/AV-N2/AV-N3, WAVE13-CODEX.
Coordinator b97354b merged before work. Prescribed effort: High.

| ID | Identity and presentation |
|---|---|
| shop_upgrade.trade_in | Ivory pawn ticket with brass $1 stamp; observed sale with confirmed returned amount |
| shop_upgrade.specialist_shelf | Violet shelf bracket with cyan enamel edge; mark actual slot 7 Specialist offer |
| ball.comet | Midnight-violet bowling ball with cyan/gold comet curl; bounded short trail on accurate curved release |
| charm.metronome | Walnut/brass metronome with cyan pendulum; arm lands on beat for paid ×1.5 |
| consumable.steady_hand | Chalked ivory hand cradling cyan ball; armed marker and accurate-curve cue, paid ×2 |
| ribbon.mastery.controlled_curve | Violet/cyan cloth award, brass curved-ball medallion and three small stars |

Five items: icon, card, in_play, rarity_treatment, activation, sound,
reduced_motion. Comet in_play is an original static pixel material on existing
presentation meshes. Ribbon uses the existing assets/clubhouse/<asset ID>.png
hook; no Career writes. Its existing model strips mastery from the ID, so an
unchanged runtime alias ribbon.controlled_curve.png accompanies the requested
ribbon.mastery.controlled_curve.png source. No gameplay values or protected paths changed.

Provenance plan: original generated transparent atlases (A: three, B: two), plus
one separate ribbon PNG. Store generator outputs unchanged; AtlasTexture region
views only. Exact prompts and hashes in ASSET-LEDGER. Original deterministic
foley from author_foley.py; no sampled audio or external marks.

Evidence plan: J03C18 retains real targets, native purchases and independent
bank. Extended JAVN4: both license cards, confirmed sale, marked Specialist slot
7, three mastery items in shop/Binder, Comet material and accurate curved trail,
armed hand, three paid effects/sounds, reduced-motion repeat and Goals
progress and the ribbon in Trophies. Contacts show canonical cards, 44px identities and static/moving
cues. The earned ribbon is an explicitly labelled contact specimen; no Career data is changed.
J03C18 only earns one controlled curve, not the full mastery. Do not claim otherwise.

Before DONE: flags on only these five items; unit/content, J03C18 and affected
art journeys headless/rendered; physics and pinned score checks; provenance,
handoff, wave index, commit/push and remote/clean-tree verification. No captures
committed. Stop at the completed item checkpoint before AV-N5.

## 2026-11-23 Comet rotation visibility revision

ID/slot: ball.comet, in_play (existing material and presentation mesh).
Original static shader math only; preserve the generated card/icon sources and
violet/cyan/gold enamel identity. The narrow UV-gated mark was already local,
but almost absent from J02's visible center sample. Use an oblique curved cyan
band and parallel fine trail across the local sphere, plus a tangent-projected
gold star. Quantize local coordinates for the pixel finish; no TIME animation.
Keep metallic/roughness/emission values and the three coordinator UI-33b shaders.
Provenance/hash: ASSET-LEDGER.md. No external images, samples or gameplay values.
Verification: unit/content; J02 and JAVN4/JAVN4R headless/rendered. Review J02's
rest/roll/spin contact sheet plus armed and normal/reduced native Comet captures.
Final results and measured rotation differences: docs/handoffs/AV-N4.md.
