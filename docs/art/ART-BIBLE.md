> Current status: E11 DONE, approved by owner merge PR #4. Review notes below
> are historical design evidence, not an outstanding owner gate. See AGENTS.md.

# Roguewood art bible — candidate 01

Status: proposed visual target for E11. Production approval is pending representative **engine-rendered** portrait and landscape scenes. Generated concept art is a reference, not proof of actual gameplay rendering. E06 and current throw-lab geometry are unchanged.

## Identity and hierarchy

A late-night bowling club: amber lacquered walnut, aged brass, petrol-blue shadows, mineral-colored equipment, and collectible paper that catches impossible light. The player should feel the heft of a ball and the temptation of a beautiful card. Roguewood is the only title; no subtitle. This proposes an original club identity, not a copy of Balatro's composition, type, cards, or branding.

Priority: rack and ball → aim/target → actionable hand → score → atmosphere. The playing lane owns the strongest depth cues; its reflections guide the eye to the pins. Quiet surroundings allow impact and foil to become special. Neither bloom nor pixelation can conceal unfinished assets.

## Color system

| Role | Hex | Use |
|---|---|---|
| Ink | #101820 | deepest outlines and card text on pale stock |
| Petrol | #17363D | background architecture, shadow planes |
| Teal | #377D83 | practical lights and ceramic midtones |
| Sea glass | #95D9CB | cool highlights, fine aim accent |
| Walnut | #573A2E | wood shadows, edges and trim |
| Honey | #C58A49 | lane midtones and warm bounce |
| Brass | #E7BC70 | metal edges, selected focus and score emphasis |
| Ivory | #F4E6CD | neutral type, pin bodies and paper |
| Ruby | #BE4B60 | rare material and danger accent; never sole warning cue |
| Violet | #8976CF | spectral layer and Epic frame details |

These are anchors, not a ten-color total restriction. Derive ramps with hue shifts, not white/black opacity alone. Keep the lane's main luminance below pin faces; keep foil highlights outside rules text. Colors must remain distinguishable by value/marking when desaturated. No red/green-only states.

## Pixel scale and rendering

Design world artwork on a 360×640 portrait composition grid; a logical pixel becomes exactly 2×2 at720×1280, 3×3 at1080×1920. Camera projection/rasterization must be tested in-engine: this spec does not claim the existing 3D lab already achieves it. World surfaces share a coherent texel scale; use authored edge clusters and stepped reflections. Do not simply downsample the greybox and declare it final.

UI text, numerals and touch targets render at native display resolution over the pixel world. Integer scale the artwork with letterboxing if necessary; never blur it to fill a mismatched aspect. Landscape uses its own 640×360 world composition, not a crop of portrait. Shader noise is spatially stable; no per-frame random pixel shimmer.

Primary lines are two logical pixels, secondary lines one. Avoid unintentional isolated single-pixel noise. Individual glints may be one pixel if their material role is clear. The rack must retain a separated silhouette at actual phone size; if it does not, bring the camera's focal composition forward rather than adding glow.

## Composition and responsive layout

Portrait reference720×1280: safe content x24–696; scoreboard y32–150; rack near y350–470; lane/approach y190–960; ball centered around y870 with lateral travel room; hand y1010–1240. These are composition zones, not rigid touch coordinates. Respect device insets. Keep the ball grip path clear of card hit regions and the home gesture area.

Landscape reference1280×720: left status rail x24–224; lane focus x260–950; cards/inspection rail x990–1256; safe top/bottom24px. Move the hand to the right rail; do not shrink portrait cards to illegibility. Rack and approach stay on the same projected axis. Handedness mirrors input access, never text or pin numbering.

Five cards remain visible as distinct illustrations and rarity markers. Compact cards show name, category glyph, rarity label and activation hint; long rules live in a dedicated enlarged inspect view. Required touch targets are at least48×48 native reference pixels and must be validated in logical device points later. No mandatory tiny effect text on a five-card mobile fan.

Score hierarchy: current/target above secondary counters; Value × Mult shown as separate labelled counters with the multiplication symbol. Persist the calculation log from E06 as a crisp overlay. Never bake live values into an illustration.

## Materials and silhouette language

- **Lane:** three warm wood ramps, directional board grain, selective oil sheen, thin reflected light bands broken by material. Perspective converges accurately; approach arrows are readable and subordinate.
- **Wood pin:** warm ivory enamel, paired neck bands, wood foot visible at close range. Distinct neck/body proportions.
- **Ruby pin:** inset faceted ruby chest plate and diamond neck marking. It remains recognizably a bowling pin, not a recolored Wood sprite.
- **Anchor pin:** reinforced dark foot collar and chevron neck marking; heavy base silhouette. Standing-state readability is essential.
- **Glass pin:** dark contour, cool rim, internal refraction facets; never invisible transparency.
- **Echo pin:** paired concentric embossed rings; repeats communicated later by a connection pulse, not duplicate rack identity.
- **House ball:** ceramic/polished resin, coherent three-hole anatomy, smooth broad highlight and controlled marbling. Rotation must move texture and holes together in E12.
- **Hook candidate:** sweeping embedded crescent seam, asymmetric swirl and etched direction marks. Its identity survives reduced motion and an effects-off view.

E11's mixed rack demonstrates Wood/Ruby/Anchor/Glass/Echo recognition. These names do not mark production definitions, mechanics or asset sets complete. Original rack positions remain1–10 regardless of material or motion.

## Cards: rarity and category are different axes

| Rarity | Frame/material | Light treatment | Persistent non-color cue |
|---|---|---|---|
| Common | toothy ivory stock, restrained ink border | broad matte highlights only | one square seal + COMMON |
| Uncommon | indigo enamel corners, copper rules | narrow satin band | paired notch seal + UNCOMMON |
| Rare | silver inset, pearlescent image surround | bounded cyan/rose interference | diamond seal + RARE |
| Epic | layered violet glass window, deep bevel | spectral ribbon crossing artwork/frame only | four-ray seal + EPIC |
| Legendary | sculpted brass relief, unique illustrated medallion | authored gold/teal holographic field and restrained star glints | crown seal + LEGENDARY |

Rarity never guarantees superiority for every build. Common fundamentals must look desirable. Foil masks exclude text, cost overlays, category symbols and critical statistics. Art contrast stays stable throughout tilt. Legendary cards require individual illustration/composition; a brighter common frame is insufficient.

Category silhouettes: ball=circle with three holes; pin=necked tapered silhouette; Charm=stitched lozenge; consumable=tear-tab packet; modification=paired bracket; upgrade=stepped license crest. Labels supplement shapes. Price and charge counters are live overlays, not baked artwork. No poker suit symbols.

## Typography

Use a crisp readable sans for body/inspection and tabular numerals for scoring. Choose a display face with restrained club-sign personality only after actual-size readability comparison. Until a font package and its redistribution license are checked into the asset ledger, use the engine fallback and label typography provisional. Do not treat a generated image's lettering as a font or production text source.

At720×1280: primary total48px, secondary counters28px, main labels24px, compact card name20px; inspection body24px with1.35 line spacing. Treat these as starting measurements, not device certification. Preserve minimum contrast4.5:1 for normal text and3:1 for large text/focus boundaries; verify actual composited backgrounds, including foil-on extremes.

## Motion specification (E12 implementation)

Input tracking stays immediate; cosmetic lag must never delay ball placement. Card hover tilt≤6°, lift≤8 logical pixels; settle120–180ms. Deal stagger35ms; inspection open180ms. Spin charge communicates sign with directional arcs, not ambiguous sparkle. Strike impact may use a short localized3-frame highlight with debris and contact response, not a full-screen flash. Score activations remain sequential and inspectable; skip/speed controls alter presentation only.

Foil changes with view/tilt, not continuous flashing. A calm idle state holds a material highlight rather than sweeping at full intensity forever. Reduced motion fixes tilt and removes camera shake and looping sweeps; activation uses outline/label changes. Reduced flash replaces glints with steady edge emphasis. Never remove information with these settings.

These timings are proposals. E12 must record real throw→impact→score→card sequences, reduced-motion alternatives, frame pacing and user review. No animated approval follows from a still.

## E11 acceptance checklist

- One actual engine composition, not merely a reference image: lane/environment, ball, ten mixed pins, HUD and all five rarity treatments.
- Portrait720×1280 and landscape1280×720 captures, plus actual-size phone inspection. No clipping, filtered pixel edges, illegible totals or hidden aiming area.
- Correct10-pin triangular rack and distinct material markings. Text/score values are live UI, not painted into background.
- Light hierarchy and silhouette separate ball/rack from atmospheric details. Inspect grayscale/effects-off and foil extremes.
- Asset ledger names source, author/tool, permission/license basis, provisional/final state and runtime use. No imported brand artwork.
- Independent visual defects recorded. User review is required before mass art expansion; routine prototypes may continue.

Until those checks pass, E11 stays IN_PROGRESS. Concept quality alone does not satisfy this gate.
