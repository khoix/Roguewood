# UI-A7 — living House hall and pixel 3D ball

Source plan: preserve the authored House environment atlas, House ball material,
and UI-A4 logo. No new external imagery or catalogue slots. Add an original
local-motion shader and a bounded 96×96 3D viewport. Loader sprites remain UI-10's
existing art; its element IDs and window.rwLoaderStart remain untouched.

The hall is stationary. Four foliage regions in the first House atlas panel bend
horizontally by at most 1.6 source pixels, weighted quadratically toward their
leaf tips, with distinct phases. Green-pixel gating keeps nearby timber stable.
Existing bright sky pixels twinkle with sparse phase groups at different rates;
the moon is excluded. Two faint lamp pools retain their slow breath. Moving dust
and parallax are removed. This is a localized material treatment of existing
foliage, not an additional illustrated plant layer.

The hero uses the actual House ball presentation mesh/material and three dark
finger-hole meshes, a fixed orthographic camera, ambient fill and one directional
light. One Y-axis revolution takes 18 seconds. Its transparent 96×96 SubViewport
is displayed with nearest filtering. No Z-axis sprite spin remains. The original
brief entrance and tap beat remain; first input is accepted immediately.

Reduced motion resets the Y angle and material clock, stops title processing,
and renders the ball viewport once. Leaving the title disables its viewport.
No per-frame node/resource creation, growing pools or image uploads. Motion
updates scalar parameters and existing transforms. Geometry has no collision or
physics bodies; no gameplay logic changes.

Review: docs/art/ui/capture_ui_a7.gd runs the real shell, samples 37 frames over a
full revolution in each orientation, checks the fixed backdrop/no flat spin,
identical reduced screenshots, all four input methods and repeated opens/resizes.
Loader review: capture_ui_a7_loader.mjs uses exported page markup with engine
scripts removed to hold actual loader DOM at controlled 50% and 100% progress;
qa.py web separately checks the real exported game and loader.

Captures live only under artifacts/ui-a7/. No rendered images are source assets.
