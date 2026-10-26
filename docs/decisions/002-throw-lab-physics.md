# ADR 002 — E04 throw lab physics and straight-throw input

Status: accepted for E04, 2026-10-26, pending independent review. Revisit only with a concrete failing case (device feel, divergence, performance) or an E05 hook requirement.

## Engine configuration

- **Jolt Physics** (built into Godot 4.5.2), not Godot Physics. Fixed **120 Hz** tick; continuous collision on ball and pins. Same-build runs are bit-identical (evidence below).
- `jolt_physics_3d/limits/max_angular_velocity = 120` rad/s. Jolt's default (15π ≈ 47 rad/s) stops a 7–9 m/s ball (radius 0.108 m, 65–83 rad/s) from rolling, so the ball slipped and lost speed. 120 leaves headroom for E05 spin.
- Measured material combining in this build: **friction = minimum, bounce = sum**. Constants in `src/simulation/lane_spec.gd` are chosen against that. Pin–pin restitution is 0.5, ball–pin 0.65, and pin–deck friction 0.35.

## Lane model (`src/simulation/`)

- Regulation geometry in meters: 41.5 in lane, 60 ft foul line to head pin, 12 in pin spacing, pit at 62 ft 10 3/16 in, 9.25 in × 1.875 in gutters, ball r 0.108 m / 6.35 kg (House), pins use the regulation profile as two convex hulls with a 1.55 kg mass and a custom low center of mass. +x is the bowler's right; forward runs along −z.
- **One seamless lane surface**, from the approach to the pit. Abutting boxes created internal edges that bounced a rolling ball 10–20 cm into the air. Oil-zone friction for hook is **E05** work (for example, per-tick ball friction by distance). E04's straight ball rolls without slipping, so uniform surface friction does not affect it.
- **Gutters are concave arc channels** whose long faces run parallel to travel. The first flat-floored gutter let the ball ride the lane edge and knock pins over. There is a continuous low cap, and the kickbacks are set back 3 cm. A wall corner within Jolt's 2 cm speculative contact distance caused a ghost collision that launched a centred gutter ball out of the channel.
- Ball and pins are damped (pin linear 0.6 and angular 1.5, ball 0.04) so fallen pins stop instead of rolling forever.

## Roll lifecycle and determinism

- Each roll runs in a **fresh `World3D`**. Pins start frozen (static) and are released at the launch tick. Aiming moves a **visual-only ball**, and the physical ball enters the world at the launch tick. The physics history is therefore the same however long or wherever the player aimed. A kinematic ball being moved during aim also failed: Jolt's state sync overwrote the node transform.
- Pinsetter rule: after roll 1, fallen pins are swept. Survivors are re-spotted **upright at their base x/f** (rack state), with a deterministic separation if two would overlap. Roll 2 is built from that rack state, so it is a function of (rack state, launch) and survives a full-precision JSON round trip.
- Fall rules (`knockdown_tracker.gd`): a pin is credited once, at the first tick its tilt exceeds 45° or it leaves the deck (base 3 cm below the surface, beyond the lane edge or past the pit). It is never resurrected. A roll ends when the ball is in the pit or has stalled and every on-deck pin has been quiet for 0.25 s. It times out 4.5 s after first pin contact or 12 s after release. At the end, a pin leaning more than 12° counts as down (`lean`).
- Attribution is the first disturbing contact, counting only contacts that carried impulse. Jolt also reports speculative contacts up to 2 cm apart, which are near misses. The categories are ball (depth 1), pin (source pin, depth + 1) and environment. Contacts are evaluated against the disturbed set at the start of the tick, so contact order cannot change the outcome.
- **Gutter rule** (USBC illegal pinfall): a ball whose center leaves the lane before it touches any pin is a gutter ball. Any pins it disturbs are voided and re-spotted. The design did not specify this rule; it is recorded here as an E04 decision.

## Straight-throw input (`src/input/`)

- Touch-first, with samples normalized to the viewport's shorter side. Timestamps come from the frame clock, so a fixed frame rate gives deterministic tests. Mouse→touch emulation is enabled for desktop development; full mouse support is E05.
- Holding the ball and dragging sideways moves the ball at its own depth. Only the final 100 ms of motion sets the flick direction and speed. A release cancels safely if it travels less than 0.04 upward, is more than 60° from vertical or is slower than 0.8/s. An OS touch cancellation, a focus loss or an app pause also cancels. A cancel restores the ball and consumes no launch ID or roll.
- Power is linear from 0.8/s to a cap of 4.0/s, mapped to 4.5–9.0 m/s. Lane angle is 0.1 × the screen angle, clamped to ±4°. Spin is always 0, and the simulation rejects any other value until E05. All thresholds are provisional; E05 tunes them on devices.
- Accuracy uses a fixed default ring (pocket target x 0.11, radius 0.25). The simulation measures where the ball crosses the plane at which it would first meet the head pin. Grades and the contracting ring are E05 work.

## Evidence (Linux x86-64, Godot 4.5.2.stable.official.6ce3de25a)

- `qa.py physics`: 15 fixtures × 3 repeats in concurrent worlds came out identical (results, logs, final poses, racks). The suite also covers aim delays of 13 and 97 ticks and a JSON rack round trip, and two separate processes produced identical outcome digests. Outcome classes held: pocket strikes, light hits leave the far side, single corner pins convert, gutters credit 0.
- A 0.002 (≈1 mm) start nudge changed the pin set in 3 of 11 full-rack fixtures. A wider sweep in development (23 positions, two powers) changed 7–8 of 23. Bowling is chaotic, so near-identical throws can leave different pins. This is reported, not hidden. E05 and E24 will judge whether it feels fair.
- Strike window in the sweep: about ±6 cm around the head-pin/pocket line, plus scattered strikes. Head-on hits sometimes leave the 7 or 10. The values are provisional and not tuned for balance.
- Cross-machine equality: the GitHub Ubuntu 24.04 runner (CI run 40262418442) reproduced the same outcome digest `d80a9fa4…` and the same J02 roll outcomes as the development container. Equality therefore holds across x86-64 Linux machines for this official build. No ARM, mobile, iOS or Android physics evidence exists, and no cross-platform replay fidelity is promised.
