extends RefCounted
## Contracting target ring (E05). While the ball is held the ring shrinks from
## RING_MAX to RING_MIN over one period, then restarts; its radius freezes at
## release. Radii are normalized to the lane half-width, like the launch contract.
## Steady mode (reduced motion or no timing) holds the widest, clean-only ring,
## so it never pays a timing bonus. Values are provisional pending trials.
const Lane = preload("res://src/simulation/lane_spec.gd")
const RING_MAX := 0.30
const RING_MIN := 0.06
const PERIOD_USEC := 1600000
const MAX_TARGET_X := 0.9

static func radius(held_usec: int, steady: bool) -> float:
	if steady or held_usec <= 0:
		return RING_MAX
	return lerpf(RING_MAX, RING_MIN, float(held_usec % PERIOD_USEC) / PERIOD_USEC)

## Grade the ring would award if the ball crossed inside it now.
static func grade(ring_radius: float) -> String:
	return Lane.grade_accuracy(true, 0.0, ring_radius)

static func default_target(handedness: String) -> float:
	return -Lane.DEFAULT_TARGET_X if handedness == "left" else Lane.DEFAULT_TARGET_X

static func clamp_target(x: float) -> float:
	return clampf(x, -MAX_TARGET_X, MAX_TARGET_X)
