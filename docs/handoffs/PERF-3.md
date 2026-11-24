# Agent task handoff — PERF-3, the hitch at every new aim; a truer log (owner, 2026-11-24)

## Assignment
- **Owner:** Claude, from the owner's phone log (Web; Resolution Low, Textures Normal, density 2.0; 2026-11-23, several sessions).
- **State:** DONE (implementation and checks). Not tried on a phone.
- **Branch:** `claude/roguewood-build`.
- **Paths:** `src/presentation/live_dressing.gd`, `src/presentation/lane_dressing.gd`, `src/platform/graphics.gd`; test `tests/clubhouse_journey.gd` (J11).

## What the log showed
- **Better than before:** no reload and no lost context. GPU memory stayed between 200 and 295 MB through a 36-roll run.
- **The hitch:** almost every new aim had a 250–470 ms frame (often two long frames). The first aim of a match had 0.7–1.3 s.
- **Not hitches:** entries of 14 s to 2,199 s were time spent away from the app.
- **The log misled:** its "cpu" figure was the engine's TIME_PROCESS monitor, a periodic sample, not that frame's. Its low values did not mean the GPU was the cause.

## Cause (native House League, probes not committed)
- **Where the time goes:** leaving the shop for a new aim took 150–270 ms on desktop, of which `_process` scripts took 1–3 ms and the renderer 5–12 ms. The rest was the button's own handler: `_start_next_match` → `_new_roll`, which runs before every aim.
- **`_new_roll`** rebuilds the lane's world for every roll (fresh physics, ADR 002, kept). The lane dressing then made everything new each time:
  - a **new `Shader`** for the lane mural, compiled again by the GPU before every aim (slow on a phone's WebGL);
  - a new material for every pin and the lane surface;
  - new box, marking and gutter meshes.
  - On desktop this was about 50 ms of `lane.setup`.
- **Also in `_new_roll`:** refreshing the hand took 40–150 ms when it dealt cards whose art had not been loaded yet (17–39 ms per card). That is a first-time load. A cache of recent item art was tried and did not change the timing in the probe, so it was not kept.

## Changes
- **The dressing makes each piece once per session and hands it to every roll:** the mural's shader, material and mesh; the rail lights; one material per pin finish; the box, marking and gutter meshes. The roll's own nodes (bodies and mesh instances) are still new. Physics is untouched.
- **On desktop**, `lane.setup` fell from about 50 ms to 13 ms per roll.
- **Log:**
  - Time away from the app (focus lost, paused, or a gap of 10 s or more) is no longer logged.
  - Each entry shows the frame's **script** time (its `_process` calls, first to last) and the renderer's **render** CPU time, beside the draw calls. Logs saved before still read.

## Not changed (follow-ups)
- **First-time card art loads** when a new card is drawn or offered.
- **Codex's ball-modification overlay** (`assets/items/d04/overlay.gd`) still writes a new `Shader` for each decal; a shared one would avoid compiles. Noted for Codex.
- **A match's first aim** still builds its stage and first shaders, about 1 s on the phone.

## Checks
- **PASS:** `unit`; J02, J11, J22L01 and JAVN4 (headless and rendered); J03, J08, J22L02. The dressing looks the same in J02's and J22L01's rendered captures.
- **J11:** checks the new log fields, and that a gap while away is not logged.
