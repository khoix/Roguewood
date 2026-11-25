# Agent task handoff — UI-A8c, the House moon arches across the sky (owner, 2026-11-25)

## Assignment
- **Owner:** Claude, from the owner: "House backdrop: Have the moon arch across the sky."
- **State:** DONE. Not tried on a phone.
- **Paths:** `assets/ui/backdrops/house_night.gd`, `assets/ui/backdrops/backdrop_base.gd`, `src/presentation/throw_lab.gd` (`_track_horizon`), `tests/backdrop_journey.gd` (JUIA8).

## What changed
- **The arch:**
  - The moon rises from behind the trees at the left edge and climbs to its peak mid-sky.
  - It sets behind the trees at the right edge. The crossing takes `MOON_CROSSING` (180 s).
  - It stays down for `MOON_BELOW` (20 s), then rises again.
  - It is drawn before the hills and pines, so it rises and sets behind them.
- **The start:** a match starts with the moon a fifth of the way up (`MOON_START`). Reduced motion holds it there.
- **Waxing:** it still waxes by Division, from a crescent to full at the Championship. Its dark side now takes the sky's colour at the moon's height, so the crescent reads true low in the dusk.
- **Below the HUD:**
  - The backdrop has a new `sky_top`, the top of the sky the player can see. `throw_lab._track_horizon` sets it each frame from the layout, where the lane's region starts below the top bar and info row.
  - The arch keeps the whole moon below that line where the sky allows, and always rises well clear of the trees.
- **Where it shows:**
  - **iPhone-shaped portrait (390 × 844):** the moon shows in the sky beside the alley as it rises and sets. At its peak it passes behind the alley's roof.
  - **Landscape and 540 × 960 portrait:** the camera's eye line sits right under the HUD, so little or no sky shows in the aim view, and the moon is mostly hidden there.

## Checks
- **JUIA8 (new checks):**
  - A match starts with the moon partway up.
  - It rises and sets behind the trees at the edges and peaks mid-sky.
  - It moves steadily left to right, stays down for a while, then rises again.
  - Under a HUD it peaks below it, clear of the trees.
  - The backdrop knows where the HUD ends.
  - Rendered: the picture changes as it crosses.
- **Captures (not committed):** rising, high and setting at 1280 × 720, 844 × 390, 390 × 844 and 540 × 960.
- **Batch, local (2026-11-25), all PASS:** unit, content, JUIA8 (headless and rendered), J22L01, J22L02ART rendered, J02 rendered.

## Limits
- In landscape and 16:9 portrait, the aim view shows almost no sky. Lowering the camera's eye line to show more would be a framing change, not made here.
