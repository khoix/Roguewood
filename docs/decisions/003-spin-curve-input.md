# ADR 003 — E05 spin, curve and gesture feel

Status: accepted for E05 on 2026-10-26, pending the owner's review. All thresholds are **provisional until real-phone trials** ([protocol](../playtests/E05-device-trials.md)) and must not be read as tuned feel. Builds on [ADR 002](002-throw-lab-physics.md).

## Spin sign and curve threshold

- `spin` > 0 means clockwise as the bowler sees it (circling clockwise on screen), and the ball hooks **right** (+x). A conventional right-handed hook is therefore counter-clockwise and negative.
- A shot is **curved** when |spin| ≥ 0.25 (`LaneSpec.CURVE_SPIN_THRESHOLD`). Gestures produce either 0 or at least 0.278, and assist controls step in 0.25s, so the boundary is never ambiguous for input. E06/E18 use this rule for curved-shot tags.

## Gesture phases (`src/input/flick_gesture.gd`)

- **Spin** is the signed turning of the finger path's direction, so no pivot is needed:
  - Jitter shorter than 0.006 (shorter-side units) is ignored, as is any step sharper than 100°; those are reversals, so dragging back and forth adds nothing.
  - A dead zone of 200° covers the single corner of a "slide, then flick" path.
  - Two loops (720°) give full spin, and the meter shows the charge live.
- **Release**: only the final 100 ms sets direction and speed, and turning inside that window does not count toward spin. The circle's tangent can therefore never steer or spin the throw (unit tests and J02 assert both).
- **Placement**: the ball follows sideways finger travel until circling starts (|turn| ≥ 90°). It then locks at the last straight point and stays there.
- **Speed caps**: flick speed (× sensitivity) is linear from 0.8 to a cap of 4.0 shorter-sides per second, mapped to 4.5–9 m/s. Faster swipes add nothing. Sensitivity runs from ×0.5 to ×2.0 and scales measured speed only; the minimum travel stays fixed so taps cannot throw.

## Hook physics (`src/simulation/`)

- Release is a true forward roll plus side rotation about the travel axis, at `spin × 15 rad/s` for the House ball. Friction therefore acts only sideways: straight balls (spin 0) stay exactly straight, and E04's straight outcomes and ticks are unchanged.
- **Oil pattern**: the ball's friction changes by distance, and Jolt uses the ball's value because it combines friction by minimum. Up to 40 ft (12.19 m) it is 0.002 (oil); in the backend it is 0.2; within 1 m of the head pin it returns to E04's 0.12. With an oil value of 0.01, the slip was spent in the heads, so the ball drifted at a constant angle instead of breaking. At 0.002 the ball skids straight, then breaks in the backend.
- Measured hook at the ring plane (straight launch from center):

  | Power | spin 0.25 | spin 0.5 | spin 1.0 |
  |---|---|---|---|
  | 0 | 23 cm | 37 cm | 66 cm (gutters) |
  | 0.5 | 13 cm | 23 cm | 40 cm |
  | 1 | 9 cm | 16 cm | 28 cm |

  Faster throws hook less because they spend less time in the backend; this is the design's speed-versus-hook trade-off. Results are exactly mirror-symmetric in spin.
- Catalogue balls (for example Hook's "higher response") will scale `side_spin` per ball (E17/E18). Only the House ball is simulated.

## Target ring (`src/input/target_ring.gd`)

- Tapping or dragging the lane above the ball moves the target to the lane x under the finger on the ring plane, clamped to ±0.9. The default is the hand's pocket (±0.11).
- While the ball is held, the ring contracts from 0.30 to 0.06 over 1.6 s and then restarts. Assist mode cycles it while aiming. It **freezes at release**, and the launch carries it.
- Grades are unchanged: perfect ≤ 0.08, sweet ≤ 0.16, otherwise clean when inside. The ring's colour shows the grade it would award.
- Reduced motion holds the ring steady at 0.30, so it awards clean only and never pays a timing bonus. Ring timing is optional everywhere.
- Display: the true ring is a few pixels wide at 20 m. The overlay draws a magnified ellipse (240 px per unit at a 720 px shorter side) that keeps the true proportions; scoring uses only the normalized radius. A short dashed guide (4.5 m) bends qualitatively with spin and is not a forecast.

## Accessibility, devices and evidence

- Settings live in a shell-owned dictionary that survives Restart Session; saving them is E25 work. They are:
  - Handedness: sets the default pocket and the side the assist panel docks on.
  - Sensitivity.
  - Reduced motion: steady ring, no aim-ball spin.
  - Larger touch targets: 2.6× the ball's radius or 10% of the shorter side, against 1.8× or 7%.
  - Assist controls: Position, Aim (lane degrees), Power, Spin and Target sliders plus a Throw button, all usable through keyboard or gamepad focus. Gestures are paused while assist is on. Throw builds its record through `LaunchMapper.from_controls`, the same path gestures use, so identical choices give identical launches (unit test and J02).
- Mouse works through touch emulation, and trial logs tag `mouse` versus `touch`. Window stretch aspect is now `expand`, so landscape fills the screen. Gesture units are normalized by the shorter side, and J02 checks a throw after rotating to landscape.
- `user://throw_trials.jsonl` records each committed roll for device trials. It does not affect play.
- Open gates: no real-phone trials have been run (NOT RUN; protocol written) and no mobile export exists (E26). Whether accessible play should earn the same timing bonus is a balance and accessibility question for E24/E25, recorded here and not decided.
