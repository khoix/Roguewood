# UI-A1-C — faint constellation lines and visible motion

State: DONE. Follow-up to the owner's sky feedback, based on dc5877e.

Constellation strokes are now 18% alpha. Normal mode has a slow bounded drift
(about 1 px/s at 1280 wide) beneath the faster 240-star layer. Reduced mode
freezes both. The four distinct schematic constellations remain unchanged.

JUIA1 passed headless and rendered in pinned Godot 4.5.2. Its new native
process-frame sequence verifies changing normal pixels and pixel-identical
reduced output after a second. All 37 existing captures remain required; 24
motion frames bring the total to 61. A local MP4 encodes those real frames at
12 fps: artifacts/ui-a1/rendered/sky_motion.mp4. No captures are committed.
Unit and content checks also passed. No production UI or League bindings changed.

## Resume exactly here

Merge origin/claude/roguewood-build (new E05-R2 tethered-swing commits), then
continue AV-H4-A: Double Take, Called Shot, Pin Count. Read E18-C11 and the
latest J03C11. Complete identity/activation/sound and native evidence before
setting flags. AV-H4-B and the full Wave 10 closing matrix remain afterward.
