# ADR 011 — The held-ball throw (E05-R1) and the tethered swing (E05-R2)

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

## Revision: the tethered swing (E05-R2, owner decision 2026-11-05)
After seeing R1, the owner asked for the ragdoll fling: the ball should swing round the touch point like a hula hoop round a waist, not just follow the finger. R2 replaces R1's charge-per-radian model. The release window, curve threshold, cancels, cues, vibration and the launch contract are unchanged.
- **Tether:**
  - The ball's centre orbits the touch point. Its radius is capped at `orbit_cap`, which the lab sets to 0.8 of the ball's on-screen radius, so the finger always stays inside the ball.
  - Before any swirl, the ball trails the finger on R1's stiff spring, clamped to the same cap.
  - While held, the ball floats one orbit above the lane in the lab, so the lower half of its swirl never clips into the boards.
- **A swirl must start:** the finger path has to turn `swirl_start_deg` (200°) one way within 1.6 s. A single corner, a part arc or sideways jiggling never curves.
  - Path steps sharper than 100° are reversals and never count.
  - Steps faster than 1.5 shorter sides a second are flicks or slides, and never count either. This keeps the turn into a fast flick from pumping a weak swirl.
- **Orbit speed is the charge:**
  - While the finger swirls, the orbit follows the finger's turning rate (`spin_up_time` 0.12 s).
  - The charge is orbit speed divided by `full_charge_speed` (12.57 rad/s, two turns a second). It is proportional to speed and does not depend on how many loops were drawn. Measured: 2, 1 and 0.5 turns a second give charges of 1.00, 0.50 and 0.25.
  - Clockwise on screen is positive, as before.
- **Momentum:** with the finger still or moving straight, the orbit coasts and halves its speed every `swirl_half_life` (1.2 s); the ball keeps visibly orbiting. Swirling the other way slows the orbit through zero before it builds the opposite spin.
- **Release:** direction and power come from the finger's flick over the last 100 ms. To that the orbit adds `orbit_nudge` (50%) of its own tangential velocity at release: a sloppy release drifts a little, never far. The spin is the charge when the window opened.
- **Tuning page** (Options → Throw tuning): full-charge swirl speed, wind-down half-life, catch-up time, turn before a swirl counts, and orbit nudge.
- **Evidence:**
  - tests/held_ball_test.gd covers:
    - speed-proportional charge, and the mirror;
    - the cap held throughout;
    - a corner, a part arc and a zigzag staying straight;
    - coasting, and the stop;
    - reversal;
    - flick plus nudge, and zero nudge;
    - a slow swirl below the threshold, and a turn into a fast flick;
    - 15 fps against 60 fps, and a late lift;
    - the cancels.
  - J02 checks a brisk 450° swirl (charge ±0.83, a strike each way), the tether inside the cap, a slow 0.4 turns-a-second swirl that throws straight, the tuning page, and the trial-log fields.
  - The swirl clip for the owner is in docs/handoffs/E05-R2.md.

### Owner adjustments (2026-11-06)
- **Full charge** now needs **6 turns a second** (`full_charge_speed` 37.7 rad/s), three times R2's first 2 turns a second. The charge stays proportional: 3 turns a second gives 0.50 and 2 turns a second gives 0.33.
- **Slower swirling lowers the bar:** while the finger is still swirling, the orbit follows its speed down as well as up (`spin_up_time` 0.12 s each way). It only coasts and winds down (`swirl_half_life` 1.2 s) when the finger stops or flicks.
- **A more elastic tether:**
  - the trailing spring is softer (24 rad/s, damping ratio 0.45);
  - the orbit radius springs to its target, under-damped (14 rad/s, damping ratio 0.35), and reaches the cap at 1.5 turns a second;
  - the tether may stretch to 1.15× the cap (0.92 of the ball's radius, so the finger stays inside the ball) and springs back.
- **Fast swirls count:** sharper path steps (up to 150°) and faster swirl motion (up to 2 shorter sides a second) now register, so a 6 turns-a-second swirl reads the same at 15 fps.
- **Owner demo:** a speed-ramp clip (1 → 6 → 2 → 6 turns a second, with the charge on screen).

## Revision: the phone trial (E05-R3, owner trial 2026-11-08)
The owner played the web build on a phone and found the swing "extremely stiff, almost non-functional", and the swirl confined above the foul line.
- **Why it was stiff:**
  - R2 ignored any path step faster than 2 shorter sides a second, to keep a corner into a flick from pumping the orbit. At 6 turns a second that allows only a circle about 1 cm across; the brisk 2–3 cm circles people draw were thrown away.
  - Full charge at 6 turns a second is near the fastest a finger can circle.
- **Changes:**
  - **Full charge at 3.5 turns a second** (`full_charge_speed` 22.0 rad/s; owner, 2026-11-08). The charge stays proportional: 1.75 turns a second gives 0.50. Still tunable; Reset on the tuning page brings back this default.
  - **Steady-turn swirl detection:** a step swirls only after three consecutive steps turn the same way by similar amounts (within 3×, each at least 2°). Circles of any size and speed qualify; a corner into a flick is one or two sharp steps between straight ones and never does. The finger-speed cap is gone.
  - **Below the start point:** the held ball no longer stops at the foul line. Above the touch point it lifts, as before; below it, it comes back toward the player over the approach (up to 1.3 m), so it follows the finger down the screen.
- **Evidence:** tests/held_ball_test.gd (speed-proportional charge at the new scale, a brisk wide circle 0.16 across reaching full charge, the corner-into-flick and zigzag cases still straight, 15 fps against 60 fps); J02 checks the ball following the finger below its start point.
