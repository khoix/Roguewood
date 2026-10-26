# Roguewood art bible — E11 candidate 01

Status: concrete still target for review, not approved release art. Read with
Sections 11 and 17 of `Roguewood-Game-Plan.md`. No production catalogue entries
are completed by these studies. E12 owns the motion proof and user checkpoint.

## Composition

A worn cosmic bowling alley: amber maple and ivory silhouettes against midnight
architecture, teal equipment, coral accents and a distant celestial mural. The
lane, ball and rack lead; collectible materials follow; atmosphere stays third.
Repeated arch ribs, pendant pools, receding boards and gutter highlights establish
depth without particles. The ten-pin mixed rack has ivory/red ceramics, engraved
brass and dark enamel with pale celestial inlays. The marbled teal ball has three
readable finger holes, a contact shadow and a short reflection.

The isolated `assets/art_direction/still.gd` fixture composes native Godot text and
frames over generated art. It is an art review board, **not the playable lane**:
its ball, rack and reflections are baked into one illustration. Never attach
physics to this plate or treat it as a finished sprite sheet. E12 must separate
equipment, environment and reflection layers and reproduce this material quality
with live movement. This restriction is deliberate, not an engine capability claim.

Portrait reference: 720×1280. A 140 px scoreboard keeps target, score, frames and
bank visible; a tall central lane preserves the full ball and rack. The equipment
dock sits above five 132×230 cards. Landscape: 1280×720, a 284 px ledger, full-height
480 px lane, and a collection comparison at right. Landscape cards deliberately
form a material-review grid, not the final playable hand. The production layout
must put five Charms above the play area and the ball bag/consumables below;
portrait uses a two-row Charm tray with inspection expansion. Implement that in
the integrated scene, not by claiming this comparison board tests interactions.

## Palette and light

| Role | Swatches | Rule |
|---|---|---|
| Background | `#101326`, `#1c2037`, `#070a16` | Darkest values surround the lane and back text. |
| Wood/light | `#e9b768`, `#a66a39`, `#f5e4bf` | Amber key light; ivory highlights reserved for readable forms. |
| Score/equipment | `#64dbcc`, `#267e86` | Teal feedback, separate from gold target. |
| Accent | `#ed817c`, `#c691d9` | Coral event accent, plum atmosphere; no persistent flash. |
| Secondary type | `#aaa7bd` | Only on opaque indigo; never over reflected wood. |

Light sources must explain highlights. Use warm overhead keys and thin cool
gutter rims. Reflections lose contrast and detail with distance from the object;
keep pin outlines distinct. Bloom may soften a light source, never primary text
or the rack silhouette. Aim mode suppresses ambient flares and animated foil.

## Pixel scale and typography

Author scene assets on a shared logical 360×640 portrait / 640×360 landscape
grid; 2× output gives 720×1280 / 1280×720. Primary contours should use purposeful
2–4 output-pixel clusters. Nearest filtering, snapped edges and integer scale
where possible; letterbox surplus pixels rather than stretch independently.
Keep smooth subpixel movement in the simulation, quantize only presentation.
The generated source plate is 1024×1536 and currently scaled to the review lane;
its density is a known deviation, requiring a pixel cleanup pass before approval.
The review fixture uses nearest sampling but that alone does not resolve it.

Native Godot fallback type (Noto Sans, bundled with Godot) supplies crisp actual
labels instead of generated lettering. Headers 30–32 px; totals 28–52 px; core
HUD 18–28 px; card titles 19 px, rarity 16 px, secondary specimen metadata 14 px.
At half-size phone display, specimen metadata needs inspection enlargement;
do not use 14 px reference text for live instructions. Production interactive
targets must be at least 44 logical points, with names and effects available in
a large inspection panel. Keep numbers tabular in the production font selection.
Do not imitate another game's logo or use distorted CRT text as primary UI.

## Material and collectible system

| Tier | Still treatment | Required motion proof in E12 |
|---|---|---|
| Common / I | Illustrated matte stock, plain ivory edge | Soft press and clean lift, no foil |
| Uncommon / II | Engraved copper, restrained metallic edge | Small directional edge glint |
| Rare / III | Bordered spectral response, preserved art contrast | Tilt-responsive border foil |
| Epic / IV | Layered rings and full-art iridescent target | Separate foreground depth and full-card foil |
| Legendary / V | Crown composition, gold corner geometry | Individual reveal, anticipation, skippable signature motion |

The five original studies are House pin, Brass pin, Ghost ball, Resonance and
Kingpin. Names/effect labels are art specimens, not approved content mechanics.
No stats or rarity assignments enter the production catalogue. Category labels
and I–V marks preserve meaning without hue. Production category geometry: round
ball medallion, tall pin arch, diamond Charm seal, capped consumable vial, and
stepped upgrade plate. Price remains a shop overlay. Inspection adds full effect,
trigger, compatibility and charges; it must not require motion permission.

Ceramic needs a broad soft highlight and red neckbands, metal narrow warm glints
and engraving, enamel a pale inlay against a dark dimensional body. Marbling
follows the ball sphere and must rotate with it. Ghost uses translucency plus
phase contours, not a recolored solid ball. Echo uses linked concentric rings;
the crown uses layered gold/ivory silhouette, not extra generic particles.

## Motion and accessibility contract

Provisional timings for E12: press 80 ms, card settle 160 ms, inspect tilt capped
at 6 degrees with 120 ms return; ball charge responds immediately; impact accent
60–90 ms; score entries 180–300 ms with 1×/2×/4× and skip. Physics and score never
wait for animation. Additions use `+`, multipliers use `×`, with an ordered log.
Stage activations one at a time before escalating the total. Aim must remain calm.

Reduced motion: fixed card foil, no camera movement, no ambient drift, direct
transitions, persistent effect labels. Reduced flash removes transient lighting
and high-contrast pulses. CRT, chromatic split, shake and scanlines independently
off; all off in this still. Remove secondary particles first when lowering quality.
E12 must show a throw, impact, material-specific effect, scoring chain, card reveal
and return to aim at both aspect ratios; E26 measures real-device pacing.

## Review gate

Review actual-size captures and the 360×640 / 640×360 display equivalents, including
the weakest card. Check ten-pin legibility, ball/aim clearance, card names, tier
distinction without color, reflection restraint, and density consistency. Record
user acceptance or concrete requested revisions in REVIEW.md. Do not scale this
candidate across six Leagues or the catalogue before the E12 visual checkpoint.
