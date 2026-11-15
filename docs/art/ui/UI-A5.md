# UI-A5 — a living night hall

Wave 13 owner extension, High effort per the session directive (supersedes the
repository claim's Medium default). Base: coordinator da92784, including UI-8 and the close
records, merged with merge commit 4a2b542. No Wave 14 work.

## Art-lead review and decisions

The UI-A4 brass wordmark, petrol/gold House Ball and timber night hall already
belong together. The main weaknesses were composition and motion: a large empty
gap below the ball, an abrupt loss of the hall into darkness, a fairly fast
endless ball rotation, and a prompt that periodically became too dim.

- Keep the authored hall, moonlit windows, logo band and original House Ball.
  These establish the game's place, name and bowling identity without a subtitle.
- Extend the portrait hall from 62% to 70% of the view and give its fade a fully
  opaque end before the overscan boundary. This retains more of the timber frame
  around the ball without leaving a moving strip at the bottom of the artwork.
- Bring the portrait prompt from 74% to 68% of the height, closer to the ball.
  Keep the existing landscape hierarchy. Raise the prompt's minimum opacity
  from 55% to 80%; it must never disappear while waiting for the player.
- Keep the 0.3-second total start transition. A tiny response precedes the fade
  inside that budget; the first tap is never deferred by an entrance animation.

The icon remains a deliberately simple gold/petrol ball with three large holes,
one gold seam and a wood-coloured field. Review uses the actual exported favicon
in light/dark Chromium tab chrome, actual-size 180/32/16 browser rendering, and
an explicitly simulated iPhone home-screen size/mask study. It does not claim a
physical iPhone installation. Final findings are in handoffs/UI-A5.md.

The 720×560 splash and its #0b1116 colour remain. The restrained wordmark-only
loader is an immediate, quiet bridge into the richer hall. No size or colour
contract changes, so project.godot, export_presets.cfg and the web tests remain
untouched. No new raster illustration, font, audio or third-party asset.

## Motion specification

All measurements below refer to the 540px short-side design scale.

- Entrance: 0.7 s cubic ease-out. Logo settles downward by 8 px, always at least
  90% opaque; ball moves 18 px right / 8 px up from a -0.16 rad offset. No scale
  pop, hidden waiting period or input lock.
- Idle ball: 0.075 rad/s (one revolution about 84 s), down from 0.6 rad/s.
- Hall: independent slow horizontal/vertical drift, bounded at ±3 / ±1.5 px.
  Six-pixel overscan covers the excursion; the lower shade reaches solid night
  before the artwork ends.
- Atmosphere: two very faint brass lamp pools, twelve slow ivory dust pixels
  within the window area, and a still petrol halo behind the ball. Existing
  colours only. The lamp breath changes opacity by just ±0.008.
- Prompt: smooth 3.6 s breath between 80% and 100% opacity.
- Start: 45 ms acknowledgement before the remaining 255 ms fade. A 160 ms
  single scale response peaks at +2.5% ball / +1.2% logo; no flash or added sound.

`open(true)` immediately places everything in its final static layout, resets
rotation/scale/opacity, stops title processing, freezes the atmosphere, and
skips the exit animation. Reopening kills a pending exit tween. Hidden titles
stop processing. Resize reapplies the correct normal or reduced layout.

Cost is bounded: one 64×64 radial texture shared by three small translucent
quads and twelve tiny rectangles, no particle system, shader/blur pass, dynamic
light or per-particle node. No physical-device performance claim is made.

## Reproduce the review

Use the project's pinned Godot 4.5.2, a display and writable XDG paths.
`capture_ui_a5.gd` is a standalone art-review tool, not a test-suite registration.
It runs the actual shell, records 60 frames at 12 samples/s, the tap response,
pixel-identical reduced views, all four input methods and reopen/resize checks.

```
godot --audio-driver Dummy --fixed-fps 60 --path . \
  --script res://docs/art/ui/capture_ui_a5.gd -- \
  --artifact-dir=/absolute/ignored-output --content=slice
# Repeat with --landscape. Encode motion_%03d.png at 12 fps for a five-second clip.
```

After `qa.py web`, run `node docs/art/ui/review_ui_a5.mjs` with the pinned
Playwright installation and DISPLAY. It captures actual light/dark browser tab
chrome through X11, plus browser-rendered size/mask studies. Outputs go only to
artifacts/ui-a5/icons/. The iPhone previews are visibly labelled as simulations,
using the exported 180px icon at 60 CSS px and 3× density with a rounded mask.
All captures are ignored outputs, never committed.
