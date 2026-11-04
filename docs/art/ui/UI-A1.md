# UI-A1 — House interface visual target

Session A supplies the card target. Session B (frame kit, licensed pixel font,
throw/shop compositions) is still open. This standalone scene does not integrate
with the hand, shop, HUD or Clubhouse. UI-1/UI-2 remain Wave 10 work.

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
ratio. Session B will specify nine-slice panel resources separately.

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
Typography is the provisional engine fallback in Session A; the licensed pixel
font is explicitly Session B scope.

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
