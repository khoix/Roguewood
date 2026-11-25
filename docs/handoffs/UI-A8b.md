# Agent task handoff — UI-A8b, the alley's shoulders finished; the pin deck's flicker fixed (owner, 2026-11-25)

## Assignment
- **Owner:** Claude, from the owner's play notes on UI-A8 (PR #70):
  - "The alleyway shoulders need more details and definition. Shadowing, perhaps. It doesn't look done." (a phone screenshot of the House alley);
  - "The pin walls are flickering rapidly while the ball is in motion toward it." (a phone screenshot of the pin deck mid-roll).
- **State:** DONE. Not tried on a phone.
- **Paths:** `src/presentation/alley_interior.gd`; `tests/backdrop_journey.gd` (JUIA8).

## What changed
- **The floor (a shader, `FLOOR_SHADER`, one per alley):** pixel art, one colour per 3 cm texel.
  - **House:** 18 cm boards in staggered 1.4 m runs, each board its own tone, with dark seams and nails.
  - **Neon:** 60 cm dark tiles whose seams carry a little of the room's two tube colours.
  - **Shading:** darker against the lane's cap and toward the platform's edges (the stem's or the crossbar's).
  - **Shadows:** a soft blob under every column, lantern, bollard and feature.
  - **Light:** each lantern (warm), bollard (its tube colour) and the crossbar's lights pool on the floor in stepped bands, like pixel light.
  - The positions are collected as the build places things (up to 24 lights and 48 shadows); the shader is compiled once a session.
- **Every standing piece (`PART_SHADER`):** a darker edge round each face, about a pixel and a half wide however far (pixel-art outlines), and contact shade: darker toward the floor where it stands. Glowing parts (tubes, bulbs, wires, Neon's gold) stay flat colour.
- **A trim board** beside each gutter's cap: a dark line that frames the shoulder. It runs into the kickback, its faces apart from the kickback's.
- **The flicker (a UI-A8 bug):** the U surround's back wall had its front face 0.4 mm from the cushion's (the pin deck's back wall), so the two fought for depth; on a phone's depth buffer this flickered as the camera followed the ball, and the wall hid the cushion's panel art. The back wall now stands 15 cm further back, clear behind the cushion.

## Checks
- **JUIA8 (new check):** no alley face lies within 5 mm of a pin-deck wall's face (kickbacks and cushion) where they overlap, in House and Neon, headless and rendered. With UI-A8's wall back in place it fails (10 shared faces), so it guards the bug.
- **Batch, local (2026-11-25), all PASS:** unit, content, JUIA8 (headless and rendered), J02 rendered, J22L01, J22L02, J22L02ART rendered, J06.
- **Cost, JUIA8 rendered, software renderer (llvmpipe), backdrop and alley together against hidden:** House 4.4–4.7 ms, Neon 3.7–4.1 ms a frame, against 4.1 and 4.8 ms before this change on the same machine. It compares; it does not measure a phone. The lane's 3D renders at half resolution (`stretch_shrink` 2), which keeps the floor shader's per-pixel loops cheap.

## Captures (sent to the owner, not committed)
- Before and after, five rooms in each League (Divisions 1, 3, 5, 7 and the Championship): the aim view in portrait, and a raised view over the left shoulder.
- The pin deck mid-roll, before and after the flicker fix.

## Limits and follow-ups
- Not tried on a phone: the owner checks the flicker and the shoulders in play.
- The camera's near and far planes are unchanged (near 0.05 m, far default); any other close faces in the lane's own scenery are outside this change.
