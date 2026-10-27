# E12 — Live motion review

The representative sequence runs in the playable lab from main's merged E05,
E06, E07 and E11. It is not a prerecorded background or a scripted replacement
for pinfall. `live_dressing.gd` attaches E11 material shaders to the existing
physics meshes; contacts, shapes, mass, launch records and rules are unchanged.

## Player flow

Enter League, use **Inspect**, then choose a card. Inspection shows its actual
name, category, rarity and effect. Drag the artwork with a pointer or finger to
tilt it. Finish samples demonstrate matte, metallic, border foil, full foil and
the crown reveal. They are explicitly previews: selecting Legendary neither
changes the item's rarity nor gives the player an item. Close or Escape restores
focus to the original card. Normal card taps still arm, cycle or retain using
E07's rules. Inspection locks during a throw.

The reveal uses a 450 ms cubic settle and 320 ms opacity reveal; **Skip reveal**
settles immediately. Foil is spatially stable and responds to drag, with no
idle time-based sweep. It affects only the artwork texture; labels, effect text
and buttons stay native and unfiltered. Card tilt is capped at 2.6 degrees.

Launches retain real ball rotation and the E05 hook. A bounded ten-point trail
follows the ball; real newly fallen pin IDs trigger a localized 220 ms impact
ring. E06's ordered log remains the sole source of Value × Mult and banked score;
log entries fade in over 160 ms and counters settle over 200 ms. Speed/skip still
affect presentation only. The Custodian portrait changes on impact and once per
scored frame, with a restrained 200 ms reaction fade. She never takes a turn or
changes a rule. This is one presentation study, not E21's finished rival roster
or E09's match challenge implementation.

## Reduced effects

**Options → Reduced motion** fixes camera position, ball charging presentation,
card tilt and foil direction, suppresses the trail/impact ring, removes score
fades and makes reveals immediate. The existing steady target ring remains.
Physical bowling still moves: removing meaningful ball/pin motion would hide the
outcome. **Reduced flash** separately suppresses trail/impact accents and score
color transitions. There is no full-screen flash, shake or CRT distortion.

Rival expressions and the persistent ordered calculation log preserve the same
outcome information in reduced mode. No optional effect delays input, changes
the score or grants resources. Settings retain the existing per-process lifetime;
disk persistence remains E25/E10 scope.

## Responsive layout and rendering

The app now selects a 720×1280 portrait or 1280×720 landscape reference canvas
when the window changes orientation. This fixes the prior landscape scaling of
all controls from a tall portrait canvas. Existing input uses the window/canvas
transform. The rival occupies the left margin in portrait and the header margin
in landscape, away from the lane and score panel. The inspector adjusts artwork
height to fit both orientations. Physics world coordinates are never resized.

## Evidence and performance interpretation

`python3 tools/qa.py e2e --journey J08 --rendered` runs the native journey.
`xvfb-run -a python3 tools/capture_motion.py` runs four combinations of aspect and
reduced effects, captures eight moments per combination, and records two MP4s:
portrait/full motion and landscape/reduced motion. Godot's movie writer captures
actual rendered frames at fixed simulation cadence; ffmpeg converts its AVI to
H.264. Video duration is simulated time, **not a measured device frame rate**.

The journey drives touch/mouse inspection, pointer and touch foil movement,
keyboard finish/reveal/skip/close, card selection, assist-slider input, real
throws, scoring and Next Rack. It verifies resources do not change during
inspection; modal gestures cannot throw; the rules score equals the banked score;
all ordered log steps remain; the rival reacts once; reduced camera/foil/trail
settings hold; and controls work again after scoring. Earlier J02/J03/J04 cover
gesture throws, score speed/skip and draw/cycle/retain behavior.

`metrics.json` records Godot CPU process and physics monitor p50/p95/max and draw
calls for the rolling/result/scoring phases, bounded to 3,600 samples. Capturing
movies adds overhead; the matrix includes runs without movie encoding. These are
scene-level measurements on Linux llvmpipe, not mobile/GPU budgets or a 60 FPS
claim. E26 still needs real-device frame pacing. Review raw logs alongside numbers.

## Visual acceptance

User review of the videos and both aspect ratios is the final G3 checkpoint in
Game Plan §17. E11's original bible remains the direction reference. Material
finishes on lab Wood pins and illustration samples do not advance production
asset completeness or claim new mechanics. No catalogue or six-theme expansion
is authorized by this implementation. Record acceptance or concrete revisions
in the E12 handoff before marking the visual gate DONE.
