extends RefCounted
## E05-R2: the tethered swing (ADR 011). The held ball hangs on a short tether from
## the touch point, like a hula hoop round a waist: the finger always stays inside
## the ball. Swirling the finger sets the ball orbiting the touch point; the curve
## charge is how fast it orbits (not how many loops were drawn). When the finger
## stops, the ball keeps orbiting and winds down, and the charge falls with it.
## Letting go flicks the ball: the finger's flick sets direction and power, and the
## orbit adds a small sideways nudge.
## Positions are viewport-normalized (units of the shorter side, y down like screen
## space). Times are microseconds taken from the input events themselves, so a low
## frame rate does not change how a gesture reads. Values in `tuning` are
## provisional until real-phone trials and the lab's tuning page.
const Lane = preload("res://src/simulation/lane_spec.gd")

const DEFAULTS := {
	# Orbit speed (radians per second; 2 turns a second) that gives full charge.
	"full_charge_speed": 12.566,
	# Seconds for a coasting orbit (finger still) to halve its speed.
	"swirl_half_life": 1.2,
	# Seconds for the orbit to catch up with a faster swirl of the finger.
	"spin_up_time": 0.12,
	# Turning, in one direction within SWIRL_WINDOW, before a swirl counts at all:
	# a single corner (slide, then flick) is never a curve.
	"swirl_start_deg": 200.0,
	# Largest orbit radius, normalized: the lab sets it to 0.8 of the ball's
	# on-screen radius, so the touch point stays inside the ball.
	"orbit_cap": 0.05,
	# Share of the orbit's own sideways speed that the release keeps.
	"orbit_nudge": 0.5,
	# Below the curve threshold a throw is exactly straight: no sparkle, no curve.
	"curve_threshold": Lane.CURVE_SPIN_THRESHOLD,
	# Spring that trails the ball behind a moving finger before any swirl.
	"spring_frequency": 40.0,
	"spring_damping": 0.75,
	# The release reads the flick over this window.
	"release_window_usec": 100000,
	# Flicks within this many degrees of straight up throw exactly straight.
	"straight_zone_deg": 2.0,
	"sensitivity": 1.0,
}
const MIN_FLICK_SPEED := 0.8 # shorter sides per second, after sensitivity
const MIN_FLICK_DISTANCE := 0.04
const MAX_FLICK_ANGLE_DEG := 60.0 # from straight up
const FULL_POWER_SPEED := 4.0 # cap: faster flicks add no power
const MIN_SEGMENT := 0.006 # finger jitter shorter than this is ignored
const MAX_TURN_STEP_DEG := 100.0 # sharper steps are reversals, not swirling
const SWIRL_WINDOW_USEC := 1600000
## Path steps faster than this (shorter sides per second) are flicks or slides, not
## swirling: the finger circles small inside the ball, so a fast turn into the flick
## never pumps the orbit.
const SWIRL_MAX_SPEED := 1.5
const DRIVE_SMOOTH := 0.06 # seconds: smoothing of the finger's turning rate
const DRIVE_HOLD_USEC := 100000 # a finger that has not moved for this long is still
const MIN_SENSITIVITY := 0.5
const MAX_SENSITIVITY := 2.0
const MAX_STEP_USEC := 2000
const HISTORY_USEC := 400000

var tuning: Dictionary = DEFAULTS.duplicate()
var active := false
var origin := Vector2.ZERO
var finger := Vector2.ZERO
## The held ball: where it is drawn, and how it is moving.
var ball := Vector2.ZERO
var ball_velocity := Vector2.ZERO
## The orbit round the touch point: speed (rad/s, clockwise on screen positive),
## angle and radius. Zero speed before a swirl starts.
var orbit_speed := 0.0
var orbit_angle := 0.0
var orbit_radius := 0.0
var swirling := false
var turn_deg := 0.0 # total signed turning of the finger path, for logs
var _drive := 0.0 # the finger's smoothed turning rate, rad/s
var _usec := 0
var _last_point := Vector2.ZERO
var _last_point_usec := 0
var _last_move_usec := 0
var _last_direction := Vector2.ZERO
var _trail_velocity := Vector2.ZERO
var _turns: Array = [] # [usec, signed radians] of recent path steps
var _finger_history: Array = [] # [usec, position]
var _charge_history: Array = [] # [usec, charge]

func begin(position: Vector2, usec: int) -> void:
	active = true
	origin = position
	finger = position
	ball = position
	ball_velocity = Vector2.ZERO
	orbit_speed = 0.0
	orbit_angle = 0.0
	orbit_radius = 0.0
	swirling = false
	turn_deg = 0.0
	_drive = 0.0
	_usec = usec
	_last_point = position
	_last_point_usec = usec
	_last_move_usec = usec
	_last_direction = Vector2.ZERO
	_trail_velocity = Vector2.ZERO
	_turns = []
	_finger_history = [[usec, position]]
	_charge_history = [[usec, 0.0]]

## A finger sample. `usec` is the event's own time; samples must not go backwards.
func move(position: Vector2, usec: int) -> void:
	if not active:
		return
	usec = maxi(usec, _usec)
	_advance(usec)
	finger = position
	_attach()
	_finger_history.append([usec, position])
	var segment := position - _last_point
	if segment.length() < MIN_SEGMENT:
		return
	var seconds := maxf((usec - _last_point_usec) / 1000000.0, 0.001)
	if _last_direction != Vector2.ZERO:
		var step := _last_direction.angle_to(segment)
		if absf(rad_to_deg(step)) <= MAX_TURN_STEP_DEG and segment.length() / seconds <= SWIRL_MAX_SPEED:
			turn_deg += rad_to_deg(step)
			_turns.append([usec, step])
			_drive += (step / seconds - _drive) * (1.0 - exp(-seconds / DRIVE_SMOOTH))
			# A swirl starts once the path has turned far enough one way, recently.
			var recent := 0.0
			for entry in _turns:
				if entry[0] >= usec - SWIRL_WINDOW_USEC:
					recent += entry[1]
			if not swirling and absf(rad_to_deg(recent)) >= float(tuning.swirl_start_deg):
				swirling = true
				var offset := ball - finger
				orbit_angle = offset.angle() if offset.length() > 1e-5 else _last_direction.angle() + PI
				orbit_radius = minf(offset.length(), float(tuning.orbit_cap))
				orbit_speed = _drive
	_last_direction = segment.normalized()
	_last_point = position
	_last_point_usec = usec
	_last_move_usec = usec
	while _turns.size() > 1 and _turns[0][0] < usec - SWIRL_WINDOW_USEC:
		_turns.pop_front()

## Keeps the ball on its tether after the touch point moves: on the orbit while
## swirling, and never further than the cap from the finger.
func _attach() -> void:
	var cap := float(tuning.orbit_cap)
	if swirling:
		ball = finger + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
	elif ball.distance_to(finger) > cap:
		ball = finger + (ball - finger).normalized() * cap

## Moves the clock without a finger sample (the finger is held still): the orbit
## coasts and winds down. The lab calls this every frame.
func tick(usec: int) -> void:
	if active and usec > _usec:
		_advance(usec)

func cancel() -> void:
	active = false

## Signed curve charge now: the orbit's speed against full-charge speed.
func charge() -> float:
	if not swirling:
		return 0.0
	return clampf(orbit_speed / float(tuning.full_charge_speed), -1.0, 1.0)

func spin_at(usec: int) -> float:
	var at := 0.0
	for entry in _charge_history:
		if entry[0] <= usec:
			at = entry[1]
	return at

## True once the charge will curve the throw (the sparkle state).
func curve_ready() -> bool:
	return absf(charge()) >= float(tuning.curve_threshold)

## True at full charge (the stronger sparkle state).
func full_charge() -> bool:
	return absf(charge()) >= 0.99

## Where the ball is drawn: on its tether round the touch point.
func placement() -> Vector2:
	return ball if active else origin

## Ends the gesture. committed=false means a safe cancel: nothing was thrown.
func release(position: Vector2, usec: int) -> Dictionary:
	if not active:
		return {"committed": false, "reason": "inactive"}
	move(position, usec)
	usec = _usec
	var window := int(tuning.release_window_usec)
	# Charge as it stood when the release window opened: the flick never charges it.
	var raw := spin_at(usec - window)
	var spin := raw if absf(raw) >= float(tuning.curve_threshold) else 0.0
	# The flick: the finger's motion over the release window.
	var start: Array = _finger_history[0]
	for entry in _finger_history:
		if entry[0] <= usec - window:
			start = entry
	var place := ball
	# The orbit's own sideways motion at release, scaled down: a nudge, never the aim.
	var nudge := Vector2(-sin(orbit_angle), cos(orbit_angle)) * orbit_speed * orbit_radius * float(tuning.orbit_nudge) if swirling else Vector2.ZERO
	cancel()
	var seconds: float = (usec - start[0]) / 1000000.0
	var result := {"committed": false, "anchor": start[1], "placement": place, "turn_deg": turn_deg, "spin": spin, "charge": raw}
	if seconds <= 0.0:
		result.reason = "no_motion"
		return result
	var travel: Vector2 = finger - start[1]
	var velocity := (travel / seconds + nudge) * clampf(float(tuning.sensitivity), MIN_SENSITIVITY, MAX_SENSITIVITY)
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

## Steps the ball from the last time to `usec` in steps of at most 2 ms.
func _advance(usec: int) -> void:
	var cap := float(tuning.orbit_cap)
	var full := float(tuning.full_charge_speed)
	var now := _usec
	var before := ball
	while now < usec:
		var step := mini(MAX_STEP_USEC, usec - now)
		var dt := step / 1000000.0
		now += step
		if swirling:
			var driving := now - _last_move_usec <= DRIVE_HOLD_USEC
			var same_way := signf(_drive) == signf(orbit_speed) or orbit_speed == 0.0
			if driving and ((same_way and absf(_drive) > absf(orbit_speed)) or (not same_way and absf(_drive) > 0.15 * full)):
				# The finger swirls faster (or the other way): the orbit follows it.
				orbit_speed += (_drive - orbit_speed) * (1.0 - exp(-dt / float(tuning.spin_up_time)))
			else:
				# Coasting: the orbit winds down on its own.
				orbit_speed *= pow(0.5, dt / float(tuning.swirl_half_life))
			orbit_angle += orbit_speed * dt
			var target := cap * clampf(absf(orbit_speed) / (0.5 * full), 0.0, 1.0)
			orbit_radius += (target - orbit_radius) * (1.0 - exp(-dt / 0.1))
			ball = finger + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
			if absf(orbit_speed) < 0.03 * full and not driving:
				swirling = false
				orbit_speed = 0.0
				_trail_velocity = Vector2.ZERO
		else:
			# Before a swirl: the ball trails the finger on a stiff spring, tethered.
			var omega := float(tuning.spring_frequency)
			var accel := (finger - ball) * omega * omega - _trail_velocity * 2.0 * float(tuning.spring_damping) * omega
			_trail_velocity += accel * dt
			ball += _trail_velocity * dt
			var offset := ball - finger
			if offset.length() > cap:
				ball = finger + offset.normalized() * cap
	var seconds := (usec - _usec) / 1000000.0
	if seconds > 0.0:
		ball_velocity = (ball - before) / seconds
	_usec = usec
	_charge_history.append([usec, charge()])
	while _charge_history.size() > 2 and _charge_history[1][0] < usec - HISTORY_USEC - int(tuning.release_window_usec):
		_charge_history.pop_front()
	while _finger_history.size() > 2 and _finger_history[1][0] < usec - HISTORY_USEC:
		_finger_history.pop_front()
