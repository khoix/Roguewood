# UI-A1 — House interface visual target

UI-A1-A and UI-A1-B supply the card and House frame-kit targets. These standalone
scenes do not integrate with the hand, shop, HUD or Clubhouse. UI-1/UI-2 remain
Wave 10 work; owner review of this target precedes that integration.

## Card contract

Canonical face: 210×300 px, radius 14 px, outer safe inset 14 px. Portrait
inspection uses 240×344; landscape 210×300. Preserve the aspect ratio within
pixel rounding; never stretch the frame to the shape of a button. Smaller hand
cards must retain name, category and rarity; full rules belong in inspection.

| Layer, back to front | Canonical rectangle / purpose |
|---|---|
| Ink silhouette, material rim, ivory stock | whole face; 14 px corner radius |
| Name banner | (18,10)–(192,38), 20 px live type |
| Petrol art recess | (14,39)–(196,224) |
| Item illustration | (15,41), 180×181, aspect-fit, nearest filtering; 51.7% of face |
| Category badge | (17,44), 26×26; opaque ink ground |
| Rule icon | (17,235), 28×28 |
| Short rule / qualifier | (51,230), 144×22 at 16 px; (51,251), 144×20 at 14 px |
| Rarity seal and label | (18,274), 180×18 at 14 px |

Do not bake names, values, prices or rules into the illustration. The preview's
short hints are visual samples; integration must bind actual catalogue rules and
resolver facts. Ruby: +10 Value and +2 Mult when fallen; Crown Jewel: ×2 frame
Mult only when Crown falls last. Price is a removable shop overlay, never part
of the permanent face. Frames have no nine-slice contract: preserve their aspect
ratio. Panel nine-slice resources are specified below.

## Materials and symbols

Original vector masters live in `assets/ui/cards/`; `build_frames.py` regenerates
them deterministically. Deliberate stepped corner ornaments meet the existing
pixel illustration edges; native text stays unfiltered. `face-common.svg` is
matte stock with square corner studs; uncommon has paired copper cuts; rare has
diamond insets and interference ticks; epic adds glass rays and diagonal bands;
legendary has sculpted brass scrolls and a crown-shaped top/bottom relief.
Rarity always retains a written label and distinct seal. These are static material
targets, not the animated foil or unique Legendary item reveal of UI-A2.

`back.svg` uses House lattice and a brass ball medallion.
No text or item information is on the back. Value is a score
column on a baseline, Mult a multiplication cross, money a dollar-stamped coin.
Categories: ball with holes, necked pin, Charm lozenge, tactical tear-tab packet,
upgrade stepped crest. Do not substitute poker suits. Icons are 32 px masters;
keep their dark plates for contrast over art.

Five existing identities are shown: House Ball (common), Ruby Pin (uncommon),
Crown Jewel (epic), Nudge (common), Spotlight Sign (rare). The separate material
study applies all five frame types for comparison; its labels explicitly state
these are not catalogue rarities. There is no Legendary catalogue item yet.
Typography now uses the bundled Pixelify Sans under SIL OFL 1.1. Native
engine fallback supplies unsupported rarity-seal glyphs; ordinary letters,
digits and dollar signs are covered by the bundled font.

## States and motion for integration

- Rest: no continuous pulsing or shimmer during aim.
- Pressed: translate down 2 px over 70 ms; keep the readable bounds fixed.
- Armed: lift 8 px, add a 3 px sea-glass exterior outline and an ARMED tab.
- Sold: a diagonal SOLD stamp over art; keep name and rarity readable.
- Locked: ink hatch over art and a lock badge; explanation in inspection.
- Deal: 180 ms ease-out, stagger 35 ms; UI state must not wait for animation.
- Flip: 180 ms, swap face/back at the edge-on midpoint; never mirror text.
- Tilt: maximum 6°, settle 150 ms. Foil masks exclude text, badges and counters.
- Cycle: 140 ms move to discard, next card enters in 180 ms. Preserve input order.
- Reduced motion: no lift, tilt or flip; use immediate outline/label state changes.

These are specifications for UI-1, not implemented interactions in the inspector.
No live item assets or House theme IDs/bindings change.

## Evidence

Run `python3 tools/qa.py e2e --journey JUIA1`, then the same command with
`--rendered` under Xvfb. The scene is `src/presentation/ui_a1_preview.tscn`.
The real button switches catalogue cards/material studies. JUIA1 checks both
modes at 720×1280 and 1280×720: face bounds and overlap, illustration containment
and majority area, font metrics, minimum type size, texture availability and
native button activation. Captures are under `artifacts/ui-a1/rendered/`:
`portrait_cards.png`, `portrait_studies.png`, `landscape_cards.png`,
`landscape_studies.png`. CI runs this only in the art shard and uploads that
folder. These checks are not physical-phone readability certification.


## House frame kit (UI-A1-B)

Five 64×64 SVG masters bind through `assets/ui/house/manifest.json` to
StyleBoxTexture resources. `build_kit.py` is their original reproducible source.
Corners remain fixed in native pixels. Horizontal and vertical rails **tile**;
the center fills with the same quiet material. Never scale a whole panel texture
into a stretched picture. Use nearest sampling for the native ornament textures.

| Stable kit ID | Resource | Four slice margins | Four content insets | Minimum size |
|---|---|---|---|---|
| ui.house.hud | hud.tres | 12 px | 20 px | 40×40 |
| ui.house.shop | shop.tres | 16 px | 24 px | 48×48 |
| ui.house.slip | slip.tres | 12 px | 20 px | 40×40 |
| ui.house.menu | menu.tres | 16 px | 24 px | 48×48 |
| ui.house.panel | panel.tres | 12 px | 20 px | 40×40 |

Paths in the table are relative to `assets/ui/house/`. These are new UI IDs;
the existing `assets/leagues/house/manifest.json` is unchanged. Walnut under-rails,
brass chamfered corners and ivory studs connect the interface to the House room.
HUD uses dark ink, shop and ordinary panels petrol, menu a walnut-black ground,
score slips ivory stock with perforation marks. The two original ornaments are
`corner.svg` (32×32; rotate for the other corners) and `divider.svg` (128×16;
keep aspect, do not stretch its center diamond).

For compact buttons, duplicate the frame resource and set content insets to
12 px left/right and 8 px top/bottom; retain the texture slice margins. The
specimen's actual text is centered, with at least 48 px control height. Normal:
shop frame; pressed/focus: HUD brass frame. Integration should add the pressed
translation from Session A, an ARMED tab/sea-glass outline, SOLD stamp, and
LOCKED hatch/badge. No gameplay state is represented solely by color. The
preview tabs select scenes; purchase/draw buttons are visual specimens only.

## Typeface and native text

`assets/ui/fonts/PixelifySans.ttf`, Pixelify Sans Project Authors, unmodified
variable font distributed under SIL Open Font License 1.1; full licence in
`assets/ui/fonts/OFL.txt`. Source URLs and SHA256 are in the asset ledger.
Use native text, never texture-scaled lettering. Font sizes: 48 total, 36 target,
40 shop heading, 32 specimen heading, 24 actions/section headings, 20 navigation
annotation, 20 card name, 16 rule hint, 14 qualifier/rarity. Keep 14 px only for
secondary card labels; never reduce a primary action to make it fit. The font
is an art direction choice, not a claim of physical-phone certification.

Foreground/background anchors: ivory `#f4e6cd` on ink `#101820` or petrol
`#17363d`; ink and walnut `#573a2e` on ivory stock. Gold and sea-glass accent
text is on dark grounds. Foil and ornament never cross text regions.

## Compositions and safe regions

Open `src/presentation/ui_a1_composition.tscn`: Throw, Shop, Frame kit tabs.
The original `ui_a1_preview.tscn` remains the catalogue/material-study inspector.
Both use the same `populate_card` art factory and font. All sample scores,
wallets and actions are explicitly static art-preview data, not live game state.
The House starter has no invented purchase price; it is labelled STARTER.

| View | 720×1280 portrait | 1280×720 landscape |
|---|---|---|
| Shared safe region | 24 px side edges, 16 px top, 24 px bottom | same |
| Preview tabs | y16–64; excluded from production UI | same |
| Throw HUD | (24,88), 672×124 | (24,88), 420×124 |
| Lane frame | (24,228), 672×580 | (312,232), 420×464 |
| Hand | three 210×300 faces at y870 | two 210×300 faces at (766,140), (1000,140) |
| Score slip | offered as separate frame specimen | (24,232), 264×188 |
| Shop masthead | (24,88), 672×124 | (24,88), 1232×124 |
| Shop stock | two 672×430 shelves at y232,686 | one 942×434 shelf at (24,232) |
| Shop actions | bottom row y1188–1256 | right rail x988–1256 |

The lane uses a cosmetic SubViewport with existing Division 1 House backdrop,
lane finish, Wood Pins and House Ball; no collision bodies, saves, input model or
resolver. Native viewport resolution is half the panel interior with nearest
sampling, independently composed for each orientation. The camera keeps both
ball and rack visible. This does not implement or validate E05-R1's held-ball
interaction. No UI overlaps the lane's 12 px inset aiming region.

## Extended evidence and owner review

JUIA1 now captures ten images under `artifacts/ui-a1/rendered/`. Review the four
card images above, then `portrait_throw.png`, `landscape_throw.png`,
`portrait_shop.png`, `landscape_shop.png`, `portrait_kit.png`, `landscape_kit.png`.
The original art-shard CI step uploads all ten; qa.py's capture list was extended
additively. No screenshot is a committed source asset.

The journey additionally verifies real tab input, font coverage, frame slice and
content margins, touch heights, text bounds in both compositions, hand/lane
separation, ball visibility with a safe margin, and byte-identical rendered
corner pixels across panel sizes and orientations. Native view inspection remains
necessary: metric checks cannot certify visual quality or phone ergonomics.
