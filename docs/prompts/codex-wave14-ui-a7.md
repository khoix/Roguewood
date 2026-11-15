UI-A7 (Wave 14, the owner's play notes of 2026-11-15; continue in your Wave 14 session, after AV-T03): the title's motion, done the way the owner meant "dynamic", and the loader's sprites.
Recommended effort: Medium–High.

First, merge `origin/claude/roguewood-build` (the UI-10 commit or later) into `codex/roguewood-build` with a merge commit.

The owner's note on UI-A5's title:
> "The background shouldn't just shift and shake, that's not what I meant by dynamic. Maybe the stars in the background can twinkle and the plants can shift like they're being rustled by light wind. And instead of the ball turning clockwise, maybe it should be a 3D object slowly rotating on the Y axis — but still keeping with the pixelated style."

Do:
1. **No shifting or shaking:** remove the backdrop's parallax drift and any shake. The scene itself stays still.
2. **Life in the scene:**
   - The stars in the night sky twinkle, a few at a time at different rates.
   - The plants sway gently, as if in a light wind: a slow, small bend from the base, offset per plant.
   - Keep the lamp light's breathing if it still suits; drop it if it now reads as busy.
3. **The ball** becomes a 3D bowling ball turning slowly about its vertical (Y) axis, so its finger holes come round. It is rendered in the pixel style: low resolution with nearest filtering, or a pre-rendered pixel sprite sheet of the turn.
4. **Keep the entrance and the tap beat** if they still suit the new motion; adjust them if not.
5. **The loader's sprites** (optional; Claude made the web loading bar in UI-10):
   - It is a pixel bowling ball rolling along a short lane toward a pin, which tips over at 100%.
   - Its sprites are provisional pixel SVGs drawn in tools/author_loader.py (`BALL`, `PIN` and their palettes).
   - Redraw them to match the brand if you like, keeping them as data in that script; run it to rewrite export_presets.cfg's head include. That is the one exception to the file being the coordinator's.
   - Keep the element ids, and keep `window.rwLoaderStart`: the web journey runs it.

Keep (as in UI-A5):
- No subtitle. One action: any tap, click, key or gamepad button starts the game.
- The names the journeys use: `title`, `TitleStart`, `wordmark`, `prompt`, `started` and `open()`.
- **Reduced motion:** everything still (`title.open(reduced)`).
- **Cheap on a phone and in the single-threaded web build:** no per-frame allocation, and a bounded number of animated nodes.
- **The checks:** J01 (headless and rendered), `qa.py web` (it now checks the loader too), JUIA1, JUIA2 and both phone tours pass.

Paths:
- src/bootstrap/title_screen.gd;
- assets/brand/ (and any title art);
- tools/author_brand.py;
- tools/author_loader.py (the sprites only);
- docs/art/ (docs/art/ui/UI-A7.md);
- docs/art/ASSET-LEDGER.md.

When done:
- **Captures:**
  - the title in portrait and landscape;
  - a short frame sequence showing the twinkle, the sway and a full turn of the ball;
  - reduced motion;
  - the web loading page at about half and at 100%.
- Write docs/handoffs/UI-A7.md and add it to WAVE14-CODEX.md.
- Push, verify the remote SHA and a clean tree, and report the SHA to the coordinator.
