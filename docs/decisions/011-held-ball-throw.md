# ADR 011 — The held-ball throw (E05-R1)

Status: accepted by the owner on 2026-11-03 (model and both design changes). Implemented as a model in E05-R1a and made live in the lab in E05-R1b, both on 2026-11-05. All values are **provisional until real-phone trials** and the lab's tuning panel. This ADR replaces the gesture sections of [ADR 003](003-spin-curve-input.md); ADR 003's hook physics, spin sign, target ring and accessibility rules stand. It amends design §5 where noted.

## Why
The E05 gesture counted how far the finger's path turned (two loops for full spin), ignored how fast the finger moved, and locked the ball in place once circling started. The owner's verdict: it reads as drawing a circle, not as handling a ball. The owner wants the ball to behave like an object the player flings around to build charge for the curve (the familiar hold, spin and fling of mobile ball-throwing games), adapted to a bowling outcome.

## The model (`src/input/held_ball.gd`)
- **Held ball:**
  - While held, the ball follows the finger on a damped spring (40 rad/s, damping ratio 0.75), so it lags, overshoots when the finger stops and can lean into its motion (R1b draws the lean).
  - It is not locked when circling starts. Where it is at release sets the start position.
- **Charging by swinging:**
  - Each finger sample turns the path by some angle; that angle charges signed spin at `charge_gain` (0.14) per radian, scaled by the finger's pace against `reference_speed` (0.75 shorter sides per second, capped at 1).
  - Brisk circles (radius 0.06, 0.6 s a loop) reach full spin in about 1.6 loops. A lazy circle (3° a frame) charges about a quarter as fast.
  - Clockwise on screen is positive, as in ADR 003.
  - Reversals and corners sharper than 100° in one step, and jitter under 0.006, charge nothing.
  - Circling the other way first bleeds spin off, then builds the opposite spin.
- **Spin carries:** held spin fades with a 2.5 s half-life once charging stops, so the player can stop circling, line up and wait for the ring. The ball's visible rotation and the meter show the live value.
- **Curve threshold** (owner-approved change to design §5):
  - Below `curve_threshold` (0.25, ADR 003's curved-shot rule), a throw is exactly straight.
  - At or above it, the throw carries the held spin, and the lab shows the sparkle (`curve_ready()`).
  - What the player sees therefore matches the result: no sparkle, no curve.
- **The fling** (owner-approved change to design §5 and ADR 003):
  - Direction and power come from the **held ball's** velocity over the last 100 ms, so a release mid-circle flings along that motion.
  - The existing limits still apply: within 60° of straight up, at least 0.04 of forward travel, and a speed of at least 0.8, with power capped at 4.0 after sensitivity.
  - Anything else cancels safely.
  - Spin is read as it stood when the release window opened, so the flick's own corner never charges it.
  - The ball lags the finger, so the same finger flick reads somewhat slower than under E05 (a 3.0/s drag measures about 2.5/s). Power tuning on a phone may move `FULL_POWER_SPEED`.
- **Event timing:**
  - Samples carry the input event's own time, not the frame clock, and `tick()` advances the spring and the fade when the finger is still.
  - At 15 fps and at 60 fps the same gesture throws with nearly the same spin and power (unit test).
  - A lift that arrives one slow frame after the last move still throws, because the ball is still travelling. This fixes E26-W01's finding.
- **Determinism:**
  - Identical samples give identical results.
  - The launch contract (start_x, angle, power, spin) is unchanged, so physics, scoring, saves and the assist controls are unaffected.
- **Tuning:** every constant above lives in `tuning`, so R1b's lab-only panel can adjust a live model. Sensitivity still scales only measured speed.

## In the lab (E05-R1b)
- **Timing:** samples carry event time in real play. When a journey drives the game (`--script` with `--fixed-fps`), they use the frame clock, which keeps automated gestures deterministic.
- **Input accumulation stays on**, so the model receives one merged drag sample per frame. Turning it off broke keyboard focus on sliders.
- **Straight zone:** flicks within 2° of straight up throw exactly straight (`straight_zone_deg`).
- **Drawing:** the ball is drawn on the spring and lifts as the finger rises. It spins at the live charge and leans into its motion.
- **Cues:** `throw_cue` fires `throw.charge`, `throw.curve_ready` and `throw.full_charge`, with 25 ms and 45 ms vibrations at the last two (toggle in Options).
- **Meter and sparkle:** the meter dims below the threshold. The sparkle is a placeholder until AV-T01.
- **Tuning page:** Options → Throw tuning (test) adjusts the five constants live.

## Evidence
`tests/held_ball_test.gd` (in `qa.py unit`) covers:
- the follow, lag, settle and overshoot of the spring;
- brisk against lazy charging, symmetry, reversal and the half-life fade;
- straight below the threshold, and corners and zigzags staying straight;
- a mid-circle fling, and the cancels;
- 15 fps against 60 fps, and a late lift;
- sensitivity, determinism, and the launch contract.

A mutation (`charge_gain` 0) fails four of them.

J02 drives the live gesture end to end (handoffs/E05-R1b.md).

## Not yet done
- Real-phone feel is the owner's trial through the web build, using the tuning page.
- The final sparkle, sound and effects are AV-T01.
