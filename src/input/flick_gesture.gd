extends RefCounted
## Hold, circle and flick recognizer. Positions are viewport-normalized (units of the
## viewport's shorter side, y down like screen space); times are microseconds.
## Two separate phases share one gesture: circling the finger charges signed spin
## from how far the path's direction turns, and only motion inside the final
## RELEASE_WINDOW sets direction and speed. Turning inside that window is ignored,
## so the tangent of a circle can never steer the release. Thresholds are
## provisional (ADR 003) pending real-phone trials.
const RELEASE_WINDOW_USEC := 100000
const MIN_FLICK_SPEED := 0.8 # shorter sides per second, after sensitivity
const MIN_FLICK_DISTANCE := 0.04
const MAX_FLICK_ANGLE_DEG := 60.0 # from straight up
const FULL_POWER_SPEED := 4.0 # cap: faster flicks add no power
const MAX_SAMPLES := 64
## Spin: clockwise on screen is positive. One corner (placement then flick) turns at
## most ~180 degrees, so a dead zone above that separates deliberate circling.
const SPIN_DEAD_ZONE_DEG := 200.0
const FULL_SPIN_DEG := 720.0 # two loops charge full spin
const MAX_TURN_STEP_DEG := 100.0 # sharper steps are reversals, not circling
const MIN_SEGMENT := 0.006 # ignore jitter shorter than this
const PLACEMENT_LOCK_DEG := 90.0 # once circling starts the ball stops following
const STEADY_TURN_DEG := 30.0
const STRAIGHT_STEP_DEG := 5.0
const MIN_SENSITIVITY := 0.5
const MAX_SENSITIVITY := 2.0

var active := false
var origin := Vector2.ZERO
var samples: Array = []
var sensitivity := 1.0
var turn_deg := 0.0
var locked: Variant = null
var _turns: Array = []
var _last_point := Vector2.ZERO
var _last_direction := Vector2.ZERO
var _steady := Vector2.ZERO

func begin(position: Vector2, usec: int) -> void:
	active = true
	origin = position
	samples = [[position, usec]]
	turn_deg = 0.0
	locked = null
	_turns = [[usec, 0.0]]
	_last_point = position
	_last_direction = Vector2.ZERO
	_steady = position

func move(position: Vector2, usec: int) -> void:
	if not active:
		return
	samples.append([position, usec])
	if samples.size() > MAX_SAMPLES:
		samples.pop_front()
	var segment := position - _last_point
	if segment.length() < MIN_SEGMENT:
		return
	# Placement locks where straight motion last happened before circling.
	var straight := true
	if _last_direction != Vector2.ZERO:
		var step := rad_to_deg(_last_direction.angle_to(segment))
		straight = absf(step) <= STRAIGHT_STEP_DEG
		if absf(step) <= MAX_TURN_STEP_DEG:
			turn_deg += step
	_last_direction = segment.normalized()
	_last_point = position
	_turns.append([usec, turn_deg])
	if straight and absf(turn_deg) < STEADY_TURN_DEG:
		_steady = position
	elif locked == null and absf(turn_deg) >= PLACEMENT_LOCK_DEG:
		locked = _steady

func cancel() -> void:
	active = false
	samples = []

## Where the ball should sit: it follows the finger until circling begins.
func placement() -> Vector2:
	if not active:
		return origin
	return locked if locked != null else samples[-1][0]

## Spin charged so far, for the live meter; release() excludes the final window.
func charge() -> float:
	return spin_for(turn_deg)

static func spin_for(turn: float) -> float:
	if absf(turn) < SPIN_DEAD_ZONE_DEG:
		return 0.0
	return signf(turn) * minf(absf(turn) / FULL_SPIN_DEG, 1.0)

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
	var turn := 0.0
	for entry in _turns:
		if entry[0] <= first[1]:
			turn = entry[1]
	var place: Vector2 = locked if locked != null else anchor
	cancel()
	var seconds: float = (last[1] - first[1]) / 1000000.0
	if seconds <= 0.0:
		return {"committed": false, "reason": "no_motion", "anchor": anchor, "placement": place}
	var travel: Vector2 = last[0] - first[0]
	var velocity := travel / seconds * clampf(sensitivity, MIN_SENSITIVITY, MAX_SENSITIVITY)
	var angle := rad_to_deg(atan2(velocity.x, -velocity.y))
	var result := {"committed": false, "anchor": anchor, "placement": place, "velocity": velocity, "speed": velocity.length(),
		"angle_deg": angle, "turn_deg": turn, "spin": spin_for(turn)}
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
