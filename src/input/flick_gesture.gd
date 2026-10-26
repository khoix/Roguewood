extends RefCounted
## Hold, drag and flick recognizer. Positions are viewport-normalized (units of the
## viewport's shorter side, y down like screen space); times are microseconds.
## Only motion inside the final RELEASE_WINDOW sets direction and speed, so earlier
## sideways placement (and later E05 circling) cannot steer the release.
## Thresholds are provisional E04 values; E05 owns device tuning and sensitivity.
const RELEASE_WINDOW_USEC := 100000
const MIN_FLICK_SPEED := 0.8 # shorter sides per second
const MIN_FLICK_DISTANCE := 0.04
const MAX_FLICK_ANGLE_DEG := 60.0 # from straight up
const FULL_POWER_SPEED := 4.0 # cap: faster flicks add no power
const MAX_SAMPLES := 64

var active := false
var origin := Vector2.ZERO
var samples: Array = []

func begin(position: Vector2, usec: int) -> void:
	active = true
	origin = position
	samples = [[position, usec]]

func move(position: Vector2, usec: int) -> void:
	if not active:
		return
	samples.append([position, usec])
	if samples.size() > MAX_SAMPLES:
		samples.pop_front()

func cancel() -> void:
	active = false
	samples = []

## Current finger position; the ball follows its sideways travel from origin.
func placement() -> Vector2:
	return samples[-1][0] if active else origin

## Ends the gesture. committed=false means a safe cancel: nothing was thrown.
func release(position: Vector2, usec: int) -> Dictionary:
	if not active:
		return {"committed": false, "reason": "inactive"}
	move(position, usec)
	var last: Array = samples[-1]
	var first: Array = samples[-1]
	for index in range(samples.size() - 2, -1, -1):
		first = samples[index]
		if last[1] - samples[index][1] >= RELEASE_WINDOW_USEC:
			break
	var anchor: Vector2 = first[0]
	cancel()
	var seconds: float = (last[1] - first[1]) / 1000000.0
	if seconds <= 0.0:
		return {"committed": false, "reason": "no_motion", "anchor": anchor}
	var travel: Vector2 = last[0] - first[0]
	var velocity := travel / seconds
	var angle := rad_to_deg(atan2(velocity.x, -velocity.y))
	var result := {"committed": false, "anchor": anchor, "velocity": velocity, "speed": velocity.length(), "angle_deg": angle}
	if -travel.y < MIN_FLICK_DISTANCE:
		result.reason = "short"
	elif absf(angle) > MAX_FLICK_ANGLE_DEG:
		result.reason = "not_forward"
	elif velocity.length() < MIN_FLICK_SPEED:
		result.reason = "slow"
	else:
		result.committed = true
		result.reason = "flick"
		result.power = clampf((velocity.length() - MIN_FLICK_SPEED) / (FULL_POWER_SPEED - MIN_FLICK_SPEED), 0.0, 1.0)
	return result
