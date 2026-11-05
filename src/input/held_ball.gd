extends RefCounted
## E05-R1a: the held-ball throw (ADR 011). The ball is an object in the hand. While
## held it follows the finger on a spring (it lags, overshoots and leans), the
## swinging path charges spin, the spin keeps going while held and fades slowly,
## and letting go flings the ball with the velocity it had in the hand.
## Positions are viewport-normalized (units of the shorter side, y down like screen
## space). Times are microseconds taken from the input events themselves, so a
## low frame rate does not change how a gesture reads. Values in `tuning` are
## provisional until real-phone trials and the lab's tuning panel (E05-R1b).
const Lane = preload("res://src/simulation/lane_spec.gd")

const DEFAULTS := {
	# Spin charged per radian of finger-path turning at or above reference speed.
	"charge_gain": 0.14,
	# Finger speed (shorter sides per second) that charges at the full rate; slower
	# circles charge proportionally less, so lazy circling builds spin slowly.
	"reference_speed": 0.75,
	# Seconds for held spin to halve once charging stops.
	"half_life": 2.5,
	# Below the curve threshold a throw is exactly straight: no sparkle, no curve.
	"curve_threshold": Lane.CURVE_SPIN_THRESHOLD,
	# Spring that carries the ball after the finger (angular frequency rad/s, damping ratio).
	"spring_frequency": 40.0,
	"spring_damping": 0.75,
	# The release reads the held ball's velocity over this window.
	"release_window_usec": 100000,
	# Flicks within this many degrees of straight up throw exactly straight; the
	# spring's leftover sideways motion never nudges an intended straight ball.
	"straight_zone_deg": 2.0,
	"sensitivity": 1.0,
}
const MIN_FLICK_SPEED := 0.8 # shorter sides per second, after sensitivity
const MIN_FLICK_DISTANCE := 0.04
const MAX_FLICK_ANGLE_DEG := 60.0 # from straight up
const FULL_POWER_SPEED := 4.0 # cap: faster flicks add no power
const MIN_SEGMENT := 0.006 # finger jitter shorter than this is ignored
const MAX_TURN_STEP_DEG := 100.0 # sharper steps are reversals, not swinging
const MIN_SENSITIVITY := 0.5
const MAX_SENSITIVITY := 2.0
const MAX_SPRING_STEP_USEC := 2000
const HISTORY_USEC := 400000

var tuning: Dictionary = DEFAULTS.duplicate()
var active := false
var origin := Vector2.ZERO
var finger := Vector2.ZERO
## The held ball: where it is drawn and the velocity it would be thrown with.
var ball := Vector2.ZERO
var ball_velocity := Vector2.ZERO
var turn_deg := 0.0 # total signed turning of the finger path, for logs
var _spin := 0.0
var _spin_usec := 0
var _usec := 0
var _last_point := Vector2.ZERO
var _last_point_usec := 0
var _last_direction := Vector2.ZERO
var _ball_history: Array = [] # [usec, position]
var _spin_history: Array = [] # [usec, spin after that event]

func begin(position: Vector2, usec: int) -> void:
	active = true
	origin = position
	finger = position
	ball = position
	ball_velocity = Vector2.ZERO
	turn_deg = 0.0
	_spin = 0.0
	_spin_usec = usec
	_usec = usec
	_last_point = position
	_last_point_usec = usec
	_last_direction = Vector2.ZERO
	_ball_history = [[usec, position]]
	_spin_history = [[usec, 0.0]]

## A finger sample. `usec` is the event's own time; samples must not go backwards.
func move(position: Vector2, usec: int) -> void:
	if not active:
		return
	usec = maxi(usec, _usec)
	_advance(usec)
	finger = position
	var segment := position - _last_point
	if segment.length() < MIN_SEGMENT:
		return
	if _last_direction != Vector2.ZERO:
		var step := _last_direction.angle_to(segment)
		if absf(rad_to_deg(step)) <= MAX_TURN_STEP_DEG:
			turn_deg += rad_to_deg(step)
			var seconds := maxf((usec - _last_point_usec) / 1000000.0, 0.001)
			var pace := clampf(segment.length() / seconds / float(tuning.reference_speed), 0.0, 1.0)
			_spin = clampf(spin_at(usec) + step * float(tuning.charge_gain) * pace, -1.0, 1.0)
			_spin_usec = usec
			_spin_history.append([usec, _spin])
	_last_direction = segment.normalized()
	_last_point = position
	_last_point_usec = usec

## Moves the clock without a finger sample (the finger is held still): the spring
## settles and the spin fades. The lab calls this every frame.
func tick(usec: int) -> void:
	if active and usec > _usec:
		_advance(usec)

func cancel() -> void:
	active = false

## Signed held spin at `usec` (clockwise on screen is positive), faded since it was
## last charged. The raw value, for the live meter and the ball's visible rotation.
func spin_at(usec: int) -> float:
	var seconds := maxf(usec - _spin_usec, 0) / 1000000.0
	return _spin * pow(0.5, seconds / float(tuning.half_life))

func charge() -> float:
	return spin_at(_usec)

## True once the held spin is at full charge (the stronger sparkle state).
func full_charge() -> bool:
	return absf(charge()) >= 0.99

## True once the held spin will curve the throw (the sparkle state).
func curve_ready() -> bool:
	return absf(charge()) >= float(tuning.curve_threshold)

## Where the ball is drawn: it follows the finger on the spring.
func placement() -> Vector2:
	return ball if active else origin

## Ends the gesture. committed=false means a safe cancel: nothing was thrown.
func release(position: Vector2, usec: int) -> Dictionary:
	if not active:
		return {"committed": false, "reason": "inactive"}
	move(position, usec)
	usec = _usec
	var window := int(tuning.release_window_usec)
	# Spin as it stood when the release window opened: the flick's own corner never charges it.
	var held := 0.0
	var at := _spin_history[0][0] as int
	for entry in _spin_history:
		if entry[0] <= usec - window:
			held = entry[1]
			at = entry[0]
	var raw := held * pow(0.5, maxf(usec - at, 0) / 1000000.0 / float(tuning.half_life))
	var spin := raw if absf(raw) >= float(tuning.curve_threshold) else 0.0
	# Velocity of the held ball over the release window.
	var start: Array = _ball_history[0]
	for entry in _ball_history:
		if entry[0] <= usec - window:
			start = entry
	var place := ball
	cancel()
	var seconds: float = (usec - start[0]) / 1000000.0
	var result := {"committed": false, "anchor": start[1], "placement": place, "turn_deg": turn_deg, "spin": spin, "charge": raw}
	if seconds <= 0.0:
		result.reason = "no_motion"
		return result
	var travel: Vector2 = place - start[1]
	var velocity := travel / seconds * clampf(float(tuning.sensitivity), MIN_SENSITIVITY, MAX_SENSITIVITY)
	result.velocity = velocity
	result.speed = velocity.length()
	result.angle_deg = rad_to_deg(atan2(velocity.x, -velocity.y))
	if absf(result.angle_deg) < float(tuning.straight_zone_deg):
		result.angle_deg = 0.0
	if -travel.y < MIN_FLICK_DISTANCE:
		result.reason = "short"
	elif absf(result.angle_deg) > MAX_FLICK_ANGLE_DEG:
		result.reason = "not_forward"
	elif result.speed < MIN_FLICK_SPEED:
		result.reason = "slow"
	else:
		result.committed = true
		result.reason = "flick"
		result.power = clampf((result.speed - MIN_FLICK_SPEED) / (FULL_POWER_SPEED - MIN_FLICK_SPEED), 0.0, 1.0)
	return result

## Steps the spring from the last time to `usec` in sub-steps of at most 2 ms,
## pulling the ball toward the finger's position as of the last sample.
func _advance(usec: int) -> void:
	var omega := float(tuning.spring_frequency)
	var damping := 2.0 * float(tuning.spring_damping) * omega
	var now := _usec
	while now < usec:
		var step := mini(MAX_SPRING_STEP_USEC, usec - now)
		var dt := step / 1000000.0
		var accel := (finger - ball) * omega * omega - ball_velocity * damping
		ball_velocity += accel * dt
		ball += ball_velocity * dt
		now += step
	_usec = usec
	_ball_history.append([usec, ball])
	while _ball_history.size() > 2 and _ball_history[1][0] < usec - HISTORY_USEC:
		_ball_history.pop_front()
	while _spin_history.size() > 2 and _spin_history[1][0] < usec - HISTORY_USEC - int(tuning.release_window_usec):
		_spin_history.pop_front()
