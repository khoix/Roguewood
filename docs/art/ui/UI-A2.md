# UI-A2 — card material and icon integration

Delivery is assets only; card_view.gd and the inspector are not modified.
`assets/ui/materials/manifest.json` resolves league → rarity → frame, overlay,
and reduced resource. House is the first authored League family, with five
rarity variants; it references the approved UI-A1 frames without changing their
IDs or art. `fallback_league` explicitly resolves unprovided League families to
House. No Neon or other future League visual design is claimed this wave.

## Layer contract

Use a mouse-ignoring ColorRect sized to the entire card face, with the selected
ShaderMaterial duplicated per card (`duplicate()`), positioned at (0,0). This is
an additive alpha overlay, not a texture-sampling shader for the illustration.
Insert it after the illustration and before badge/text, stamp, price and tag.
Hide it with the face during flips/back display. Never attach it to the whole
Button: it does not sample TEXTURE. Existing inspector foil must be disabled
when this layer is used, to avoid double effects. Claude owns that integration.

The shader uses normalized UV mapped to the canonical 210×300 face. Rim effects
stay in x3–9 and x201–207, y15–285. Art effects stay in (15,41)–(195,222), excluding
the category badge safety rectangle (15,41)–(46,73). Name, rules, rarity labels
and UI-A1's corrected bottom safe inset remain untouched. Compact UI-1 cards
use a different text layout: keep the overlay below all live labels and badges;
if their art recess differs, apply only the rim or disable the layer until the
canonical mask has been mapped to that compact art rectangle.

| Tier | Material |
|---|---|
| Common | matte: transparent overlay |
| Uncommon | restrained brass glint on vertical frame metal |
| Rare | sea-glass holographic border; art interior stays untouched |
| Epic | alternating violet/sea-glass facets across the art and frame |
| Legendary | brass/sea-glass engraved prism substrate |

The Legendary resource is a reusable substrate. It does not replace individual
Legendary item artwork, animation or signature reveals required by design §15.
There is no Legendary catalogue item in this delivery; the contact sheet labels
its five columns as material studies, not real item rarity assignments.

## Animation and accessibility

No TIME uniform is used: the material cannot animate itself during aiming.
The integration supplies `progress` in [0,1] during inspection or activation.
Suggested inspection mapping: clamp(0.42 + 0.25*tilt.x + 0.15*tilt.y, 0, 1),
with each tilt axis normalized to [-1,1]; settle to 0.42 on release.
An activation can sweep once over 180 ms, without delaying game state.
No sensor or device-motion permission is needed.

Load the reduced resource or set `reduced=true` for either reduced motion or
reduced flash. This fixes phase at 0.42 regardless of progress changes. Common
stays matte in every state. Default strength 0.65; zero disables all decoration.
Alpha is capped at 0.22 to preserve illustration contrast; no flashes or pulses.
Duplicate materials so touching one card cannot alter a sibling's highlight.

## Final icons

The manifest is the binding authority. Eight approved score/category masters
remain unchanged: Value, Mult, $, ball, pin, Charm, tactical, upgrade. Nine new
32px original vector masters share their dark plate and brass line weight:
Cycle, Inspect, deck, discard, Options, target, lock, armed and sold.
Use nearest filtering at native 32px or integer multiples. Pair state/action
icons with accessible labels; lock/armed/sold are distinct shapes, not colors.
The icon row in JUIA2 follows manifest order. No gameplay meaning is encoded in
foil strength or icon color alone.

## Reproduction and evidence

Run `python3 assets/ui/materials/build_materials.py` to reproduce ten material
resources, the league manifest and nine action icons. All are original source.
JUIA2 via qa.py captures phase_a, phase_b and base at 1200×800. Top row receives
changing progress, bottom row is reduced. Pixel comparisons prove common and
reduced stability, phase response for the four shiny tiers, and zero changes in
name/rule/rarity/category zones relative to the uncoated baseline.
