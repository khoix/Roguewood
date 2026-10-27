> Current status: E11 DONE, approved by owner merge PR #4. Review notes below
> are historical design evidence, not an outstanding owner gate. See AGENTS.md.

# E11 runtime review — continuation

Status: REVIEW CANDIDATE pending visual-quality acceptance. Original independent
concept review in VISUAL-REVIEW.md is preserved. This record covers the new
runtime fixture, not acceptance of the original concept or final release assets.

## Implemented against recovered review

- Separate runtime lane, ball and ten pins, using E04 LaneSpec.spot(1..10) and
  regulation lathed pin profile. The ball is posed near the deck for a readable
  still composition; this is not the start-of-throw gameplay camera.
- Distinct Wood, Ruby, Anchor, Glass and Echo material studies, including ruby
  inset, anchor foot collar and Echo ring relief. No catalogue flags advanced.
- Native HUD text: target, score, frames, bank and Value × Mult. Five distinct
  card illustrations and common-to-legendary labels/roman marks.
- Separate 720×1280 and 1280×720 layouts; world viewport rasterizes at half size
  and nearest-scales 2×, while text remains native resolution.
- Source checksums and image dimensions checked by capture.py; card bounds and
  native label overflow checked by still.gd. CI preserves screenshots and logs.
- The recovered bible, original source image parts and prior review are retained.

## Visual checks and remaining gaps

Initial runtime review found the ball clipped at the portrait bottom and a strong
lane specular hotspot. Moved the posed ball toward the deck, reduced key/rim
energy and grain amplitude, and increased wood roughness for the next capture.

Runtime material and architecture craft still needs owner comparison against the
original generated quality target. Glass uses a rim/facet material study rather
than screen-space refraction. Category glyphs are present; font choice and
physical-phone readability remain provisional. The landscape collection grid is a review layout, not a completed
interactive hand. No inspection, foil tilt, throw motion or live scoring is proven.

Do not label this final-quality acceptance simply because it renders at a coherent
pixel scale. User quality review remains the E11 acceptance gate;
E12 owns moving sequences only after E11 acceptance. No mass art production.

Reproduce: `xvfb-run -a python3 docs/art/capture.py` with GODOT_BIN pointing to
Godot 4.5.2 stable. Inspect artifacts/e11/portrait.png and landscape.png at actual
size, then half display scale; check ball visibility, ten heads, reflection
restraint, card names, Value/Mult and the weakest Common illustration.
