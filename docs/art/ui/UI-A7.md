# UI-A7 — living House hall and pixel 3D ball

Source plan: preserve the authored House environment atlas, House ball material,
and UI-A4 logo. No new external imagery or catalogue slots. Add an original
local-motion shader and a bounded 192×192 3D viewport (owner-corrected hero). Loader sprites remain UI-10's
existing art; its element IDs and window.rwLoaderStart remain untouched.

The hall is stationary. Four foliage regions in the first House atlas panel bend
horizontally by at most 1.6 source pixels, weighted quadratically toward their
leaf tips, with distinct phases. Green-pixel gating keeps nearby timber stable.
Existing bright sky pixels twinkle with sparse phase groups at different rates;
the moon is excluded. Two faint lamp pools retain their slow breath. Moving dust
and parallax are removed. This is a localized material treatment of existing
foliage, not an additional illustrated plant layer.

The hero uses the original title illustration (House ball crop in a01-source.png),
projected onto a sphere through title_ball.gdshader. The front pose matches the
owner's screenshot: holes upper-right, the diamond below center, teal/gold veining
and bright top/cyan rim reflections. A camera size of 0.22 fills the title's ball
box instead of the prior 0.28 framing. A 192×192 transparent viewport with nearest
filtering retains the illustration's finish. No extra finger-hole meshes remain.
The rear is reconstructed from an unmarked enamel field in that same illustration,
with an angle-dependent blend; the single source image does not define a rear.
The broad lamp highlight and cyan rim stay in view space while surface details
turn. This is a stylized illustration-derived material, not an environment-map
render. No source bitmap is edited or replaced.

One Y-axis revolution still takes 18 seconds. The original entrance/tap beat remain;
first input is accepted immediately. Prompt placement now reserves clearance below
the larger ball on shorter screens.

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
