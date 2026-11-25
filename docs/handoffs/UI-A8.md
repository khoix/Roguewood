# Agent task handoff — UI-A8, the League backdrops and the alley (owner, 2026-11-24/25)

## Assignment
- **Owner:** Claude. Moved from Codex by the owner ("Assign yourself anything you can do... I would like for backdrop to jump the queue as next"), with the brief docs/prompts/codex-wave15-ui-a8.md.
- **Shaped in preview rounds with the owner (2026-11-25):**
  - "the alley looks like it's just floating in the air";
  - "This should be the only alley... an alley floor and ceiling, but columns...";
  - "The columns should be out to the width of the alley back wall";
  - two top-down sketches of a T, whose top edge is the back wall;
  - "Remove the columns along the alleyway. And add some thematic decoration to the shoulders";
  - "Go ahead, style every Division and commit."
- **State:** DONE for House and Neon. Not tried on a phone.
- **Paths:**
  - `assets/ui/backdrops/backdrop_base.gd`, `house_night.gd`, `neon_city.gd` (new); `neon_normal.tscn` and `neon_reduced.tscn` (now `neon_city.gd`); `neon.gd` removed;
  - `src/presentation/alley_interior.gd` (new);
  - `src/presentation/throw_lab.gd`: the House night by default; `dress_stage()`; `_track_horizon()`;
  - `tools/author_neon_theme.py` (its template names `neon_city.gd`);
  - tests `tests/backdrop_journey.gd` (JUIA8, new) and `tests/neon_theme_journey.gd` (J22L02ART's drift check);
  - tools/qa.py and the workflow (art shard), add-only.

## What it is
- **The alley (3D, `alley_interior.gd`), around the one lane.** It follows the camera with the lane, because the camera follows the ball.
  - **The stem:** the floor around the lane (3.8 m wide), open to the sky, with decorations on its shoulders. A fascia drops at every outer edge, so it reads as a built platform.
  - **The crossbar:** across the far end, exactly as wide as the back wall (the room picture, 9 m, z -21), with nothing behind it. Columns stand along its front edge and at its back corners, under beams and a slatted roof.
  - **The U:** a low surround round the pin deck (kickback height), so the room picture above stays in view.
  - **The pit:** left open, so knocked pins fall into it below the floor.
  - **Cosmetic only:** no collision, physics unchanged (`physics` digest), never rebuilt by a roll. Each material's boxes are merged into one mesh, about 20 draws in all. It is built again only when the League or room changes.
- **The backdrop (2D, beyond the alley):** each League's night, painted at half resolution into its own view, scaled up crisp, and redrawn at most 20 times a second.
  - **Horizon:** it follows the camera's eye line each frame (`_track_horizon`), so the far ground meets the sky where the alley's floor says it should.
  - **House:** a sky deepening through the Divisions, stars, a moon waxing from a crescent (Division 1) to full (the Championship), drifting clouds, a pine treeline with cabin windows, and fireflies. The Championship adds soft fireworks.
  - **Neon:** a violet sky with a horizon haze and a soft colour sweep, a far skyline with lit windows, slow searchlights, near buildings carrying each room's sign, and the grid floor. The Championship turns it gold.
  - **Reduced motion and reduced flash:** one still picture. No strobe in any mode.
- **Each Division dressed (the alley):**
  - **House:**
    - lantern posts and a low brass rail throughout; bulbs swagged across the crossbar (more from Division 4);
    - planters: pines and ferns (Divisions 1–2), flowers (3–4), topiary (5–6), brass urns with pines (7–8);
    - the Championship: trophy pedestals, a red runner on each shoulder, pennant bunting and gold trim.
  - **Neon:**
    - each room its own tube colours, with glowing bollards and floor chevrons pointing to the pins;
    - a feature from its art intent: the lounge, palms; the precision gallery, light posts; the listening room and the DJ balcony, speaker stacks; the oil hall, drums; the prism salon, prisms; the colonnade, arches; the title antechamber, trophies;
    - the Championship: gold crowns between palms.

## The standard for later Leagues (Salvage, Royal, Spectral, Foundry)
- **Backdrop:** a `backdrop_base.gd` painter for the League's night or day beyond the alley. Layers far to near, motion slow (JUIA8: under 5% of the screen changes in 1.5 s), still under reduced motion or flash, and horizon from `horizon`.
- **Alley:** a branch in `alley_interior.gd` with the League's materials, lights and a shoulder feature per Division, building to the Championship. The T and its sizes stay the same, so every room's picture is its back wall.
- **Wiring:** the League's manifest names the flank backdrop. `dress_stage` builds the alley for leagues it knows.

## Checks
- **JUIA8 (both modes),** House and Neon in the real game:
  - the backdrop and the alley in place;
  - every room (Divisions 1–8 and the Championship) dresses both and looks different, captured in portrait and landscape;
  - the drift is ambient, reduced motion is still, and the alley has no collision;
  - cost: backdrop and alley together add about 5.7 ms (House) and 4.6 ms (Neon) a frame in this software renderer, mostly pixel fill. Not measured on a phone.
- **J22L02ART:** its drift check now asks for ambient motion (the old design kept the screen's centre empty).
- **Also PASS:**
  - `unit`, `content`, `integration`, `physics`;
  - J22L01 and J22L02 (both modes), J11, J06, J08, JTUT, J03, J05, JUIA9NB;
  - rendered: J02, JUIA1, J22L01ART, J22L02ART, J22L02LIVEART;
  - `web` (JW01; `index.pck` 46.5 MB, within the 55 MB budget).
