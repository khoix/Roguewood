extends RefCounted
## E05-R4: the held ball is a weighted body hanging from the touch point (ADR 011,
## "Revision: the ragdoll ball"). The owner's direction, with a video of a coaster
## pinned and swirled under a fingertip (2026-11-08): ragdoll physics, with gravity.
##
## The finger is a pivot inside the ball. The ball's centre hangs from it on a short,
## slightly elastic pin, under screen gravity, with real inertia: it trails a moving
## finger, swings past when the finger stops, sways under slow circles and is whipped
## round by brisk ones. How fast the ball turns about the finger is the curve charge.
## When the finger stops, the ball keeps turning on its own momentum, gravity and
## drag wind it down, and it falls back to hanging. Nothing here is scripted motion:
## positions come from integrating forces.
##
## Letting go flicks the ball: the finger's flick sets direction and power, and a
## share of the ball's own swinging velocity is added as a nudge.
## Positions are viewport-normalized (units of the shorter side, y down like screen
## space). Times are microseconds taken from the input events themselves, so a low
## frame rate does not change how a gesture reads. Values in `tuning` are
## provisional until real-phone trials and the lab's tuning page.
const Lane = preload("res://src/simulation/lane_spec.gd")

const DEFAULTS := {
	# Turning speed of the ball about the finger (rad/s) that gives full charge. A
	# whipped ball turns faster than the finger circles (about 1.3-2x, more for
	# bigger circles, and more with a longer pin). 32 put full charge at a brisk 3.5
	# finger turns a second; the owner found that a bit too easy (2026-11-08) and
	# tuned it on the phone to 50, with the longer pin and quick smoothing below.
	"full_charge_speed": 50.0,
	# Seconds for the ball to lose half its speed to drag against the world, like
	# the table under the coaster in the owner's video: it trails the finger, and
	# spins on briefly when the finger stops.
	"swirl_half_life": 0.1,
	# Seconds over which the charge follows the ball's turning (smooths the sway of
	# a pendulum so only real rotation charges). The owner's phone tuning: 0.05, so
	# the meter follows the ball almost at once (the swirl gate still stops sways).
	"spin_up_time": 0.05,
	# The ball must turn this far one way about the finger, recently, before the
	# charge counts: a sway or a single swing never curves.
	"swirl_start_deg": 200.0,
	# The pin's longest reach, normalized: the lab sets it to `pin_reach` times the
	# ball's on-screen radius when the ball is picked up.
	"orbit_cap": 0.05,
	# How far the ball hangs from the finger, in ball radii. At 0.8 the finger stays
	# inside the ball; past about 0.87 the stretched pin can carry the finger past
	# the rim, for a bigger, floppier swing. The owner's phone tuning: 1.0.
	"pin_reach": 1.0,
	# Share of the ball's own swinging velocity that the release keeps.
	"orbit_nudge": 0.2,
	# Below the curve threshold a throw is exactly straight: no sparkle, no curve.
	"curve_threshold": Lane.CURVE_SPIN_THRESHOLD,
	# Screen gravity (shorter sides per second squared), toward the bottom of the
	# screen: the ball hangs below the finger and sways back to hanging.
	"gravity": 4.0,
	# The elastic pin: its stiffness (rad/s) and damping ratio. It rests at 0.75 of
	# the reach and stretches under a fast spin up to the stretch limit.
	"spring_frequency": 60.0,
	"spring_damping": 0.5,
	# The pin may stretch to this multiple of the reach (0.8 x 1.15 = 0.92 of the
	# ball's radius, so the finger stays inside) and springs back.
	"tether_stretch": 1.15,
	# The release reads the flick over this window.
	"release_window_usec": 100000,
	# Flicks within this many degrees of straight up throw exactly straight.
	"straight_zone_deg": 2.0,
	"sensitivity": 1.0,
}
const REST_REACH := 0.75 # the pin's rest length, as a share of orbit_cap
## Shorter sides per second. Sensitivity scales the throw's power; above x1 it also
## lets gentler flicks throw, but below x1 it never turns a flick into a cancel (the
## owner's x0.4 default softens throws without refusing them, 2026-11-08).
const MIN_FLICK_SPEED := 0.8
const MIN_FLICK_DISTANCE := 0.04
const MAX_FLICK_ANGLE_DEG := 60.0 # from straight up
const FULL_POWER_SPEED := 4.0 # cap: faster flicks add no power
const SWIRL_WINDOW_USEC := 1600000
const MIN_SENSITIVITY := 0.25
const MAX_SENSITIVITY := 2.0
const MAX_STEP_USEC := 2000
const HISTORY_USEC := 400000
const TURN_BUCKET_USEC := 20000
const MIN_LAG_USEC := 12000 # the replay runs this far behind the touch stream...
const MAX_LAG_USEC := 80000 # ...up to this, following the sample interval
const MIN_SEGMENT := 0.006 # finger jitter shorter than this is ignored
const MAX_TURN_STEP_DEG := 150.0 # sharper path steps are reversals, not circling # turning is summed in 20 ms buckets for the swirl window

var tuning: Dictionary = DEFAULTS.duplicate()
var active := false
var origin := Vector2.ZERO
var finger := Vector2.ZERO # the latest finger sample
## Where the ball hangs from: the finger's path, replayed one sample interval
## behind the touch stream, so the pin always moves along real motion between
## known samples (at any frame rate, however a sample lands against the frame).
var pivot := Vector2.ZERO
## The held ball: its centre and velocity (screen-normalized).
var ball := Vector2.ZERO
var ball_velocity := Vector2.ZERO
## The ball about the finger: its smoothed turning speed (rad/s, clockwise on screen
## positive), the direction of the pin (radians) and the pin's length.
var orbit_speed := 0.0
var orbit_angle := 0.0
var orbit_radius := 0.0
## The ball body's own rotation since it was picked up (radians, clockwise positive):
## a ball pinned off-centre turns with its pin.
var body_angle := 0.0
var swirling := false
var turn_deg := 0.0 # total signed turning of the ball about the finger, for logs
var _usec := 0
var _finger_velocity := Vector2.ZERO
var _interval := 16667.0 # smoothed time between finger samples (usec)
var _turns: Array = [] # [usec, signed radians] buckets of the ball's turning
var _finger_turns: Array = [] # [usec, signed radians] of the finger path's turning
var _last_direction := Vector2.ZERO
var _finger_history: Array = [] # [usec, position]
var _charge_history: Array = [] # [usec, charge]

func begin(position: Vector2, usec: int) -> void:
	active = true
	origin = position
	finger = position
	pivot = position
	# Picked up at the touch point, the ball drops onto its pin and settles hanging.
	ball = position + Vector2(0.0, 0.2 * _rest())
	ball_velocity = Vector2.ZERO
	orbit_speed = 0.0
	orbit_angle = PI * 0.5
	orbit_radius = 0.2 * _rest()
	body_angle = 0.0
	swirling = false
	turn_deg = 0.0
	_usec = usec
	_interval = 16667.0
	_finger_velocity = Vector2.ZERO
	_turns = []
	_finger_turns = []
	_last_direction = Vector2.ZERO
	_swirl_direction = 0.0
	_finger_history = [[usec, position]]
	_charge_history = [[usec, 0.0]]

## A finger sample. `usec` is the event's own time; samples must not go backwards.
## The pivot moves in a straight line from the last sample to this one.
func move(position: Vector2, usec: int) -> void:
	if not active:
		return
	var previous: Vector2 = _finger_history[-1][1] if not _finger_history.is_empty() else finger
	var last_usec: int = _finger_history[-1][0] if not _finger_history.is_empty() else usec
	usec = maxi(usec, last_usec)
	if usec > last_usec:
		_interval += (float(usec - last_usec) - _interval) * 0.3
	finger = position
	_finger_history.append([usec, position])
	_advance(usec - _lag())
	# The finger's own circling (its path turning), so the ball only charges when it
	# turns the way the finger circles.
	var segment := position - previous
	if segment.length() >= MIN_SEGMENT:
		if _last_direction != Vector2.ZERO:
			var step := _last_direction.angle_to(segment)
			if absf(step) <= deg_to_rad(MAX_TURN_STEP_DEG):
				_finger_turns.append([usec, step])
		_last_direction = segment.normalized()
	while _finger_turns.size() > 1 and int(_finger_turns[0][0]) < usec - SWIRL_WINDOW_USEC:
		_finger_turns.pop_front()

## Moves the clock without a finger sample (the finger is held still): the ball
## keeps swinging under its own momentum and gravity. The lab calls this every frame.
func tick(usec: int) -> void:
	if active:
		_advance(usec - _lag())

func cancel() -> void:
	active = false

## Signed curve charge now: the ball's turning about the finger against full charge.
func charge() -> float:
	if not swirling or signf(orbit_speed) != signf(_swirl_sign()):
		return 0.0
	return clampf(orbit_speed / float(tuning.full_charge_speed), -1.0, 1.0)

## The way the ball went round when the swirl started (+1 clockwise on screen).
func _swirl_sign() -> float:
	return _swirl_direction

var _swirl_direction := 0.0

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

## Where the ball is drawn: its centre, hanging from the touch point.
func placement() -> Vector2:
	return ball if active else origin

## Ends the gesture. committed=false means a safe cancel: nothing was thrown.
func release(position: Vector2, usec: int) -> Dictionary:
	if not active:
		return {"committed": false, "reason": "inactive"}
	move(position, usec)
	usec = int(_finger_history[-1][0]) # the touch's own time (the replay runs behind it)
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
	# The ball's own swing at release, relative to the finger, scaled down: a nudge.
	var nudge := (ball_velocity - _finger_velocity) * float(tuning.orbit_nudge) if swirling else Vector2.ZERO
	cancel()
	var seconds: float = (usec - start[0]) / 1000000.0
	var result := {"committed": false, "anchor": start[1], "placement": place, "turn_deg": turn_deg, "spin": spin, "charge": raw}
	if seconds <= 0.0:
		result.reason = "no_motion"
		return result
	var travel: Vector2 = finger - start[1]
	var gain := clampf(float(tuning.sensitivity), MIN_SENSITIVITY, MAX_SENSITIVITY)
	var flicked := travel / seconds + nudge
	var velocity := flicked * gain
	result.velocity = velocity
	result.speed = velocity.length()
	result.angle_deg = rad_to_deg(atan2(velocity.x, -velocity.y))
	if absf(result.angle_deg) < float(tuning.straight_zone_deg):
		result.angle_deg = 0.0
	if -travel.y < MIN_FLICK_DISTANCE:
		result.reason = "short"
	elif absf(result.angle_deg) > MAX_FLICK_ANGLE_DEG:
		result.reason = "not_forward"
	elif flicked.length() * maxf(gain, 1.0) < MIN_FLICK_SPEED:
		result.reason = "slow"
	else:
		result.committed = true
		result.reason = "flick"
		result.power = clampf((result.speed - MIN_FLICK_SPEED) / (FULL_POWER_SPEED - MIN_FLICK_SPEED), 0.0, 1.0)
	return result

func _rest() -> float:
	return float(tuning.orbit_cap) * REST_REACH

func _lag() -> int:
	return clampi(int(_interval * 1.2), MIN_LAG_USEC, MAX_LAG_USEC)

## The finger's path at `usec`: straight lines between its samples, held after the last.
func _finger_at(usec: int) -> Vector2:
	var count := _finger_history.size()
	if count == 0: return finger
	if usec >= int(_finger_history[-1][0]): return _finger_history[-1][1]
	for i in range(count - 1, 0, -1):
		var a: Array = _finger_history[i - 1]
		if usec >= int(a[0]):
			var b: Array = _finger_history[i]
			var span := float(int(b[0]) - int(a[0]))
			return (a[1] as Vector2).lerp(b[1], 0.0 if span <= 0.0 else float(usec - int(a[0])) / span)
	return _finger_history[0][1]

## Integrates the hanging ball from the last time to `usec` in steps of at most 2 ms,
## with the pin moving along the finger's path.
func _advance(usec: int) -> void:
	var total := usec - _usec
	if total <= 0:
		return
	var reach := float(tuning.orbit_cap) * float(tuning.tether_stretch)
	var rest := _rest()
	var k := float(tuning.spring_frequency)
	var zeta := float(tuning.spring_damping)
	var gravity := Vector2(0.0, float(tuning.gravity))
	var smooth := maxf(float(tuning.spin_up_time), 0.001)
	var half_life := maxf(float(tuning.swirl_half_life), 0.01)
	var turned := 0.0
	var now := _usec
	while now < usec:
		var step := mini(MAX_STEP_USEC, usec - now)
		var dt := step / 1000000.0
		now += step
		var before_pivot := pivot
		pivot = _finger_at(now)
		_finger_velocity = (pivot - before_pivot) / dt
		var rel := ball - pivot
		var length := maxf(rel.length(), 1e-6)
		var n := rel / length
		var rel_velocity := ball_velocity - _finger_velocity
		var radial := rel_velocity.dot(n)
		# Gravity and the elastic pin (spring plus damping along it).
		var accel := gravity - n * (k * k * (length - rest) + 2.0 * zeta * k * radial)
		ball_velocity += accel * dt
		# Drag against the world (the air, or the table under the coaster in the
		# owner's video), not against the finger: a dragged ball trails the way the
		# finger moves, so a circling finger whips it round the same way.
		ball_velocity *= pow(0.5, dt / half_life)
		var before_angle := rel.angle()
		ball += ball_velocity * dt
		# The pin never reaches past the stretch limit: the finger stays inside the ball.
		rel = ball - pivot
		if rel.length() > reach:
			n = rel.normalized()
			ball = pivot + n * reach
			var outward := (ball_velocity - _finger_velocity).dot(n)
			if outward > 0.0:
				ball_velocity -= n * outward
			rel = ball - pivot
		var d_angle := wrapf(rel.angle() - before_angle, -PI, PI)
		turned += d_angle
		body_angle += d_angle
		# The charge follows the ball's turning about the finger, smoothed so a sway
		# (back and forth) cancels out and only rotation builds it.
		orbit_speed += (d_angle / dt - orbit_speed) * (1.0 - exp(-dt / smooth))
	orbit_angle = (ball - pivot).angle()
	orbit_radius = (ball - pivot).length()
	turn_deg += rad_to_deg(turned)
	# Swirl gate: the ball has gone round far enough one way, recently.
	if _turns.is_empty() or usec - int(_turns[-1][0]) >= TURN_BUCKET_USEC or signf(_turns[-1][1]) != signf(turned):
		_turns.append([usec, turned])
	else:
		_turns[-1][1] += turned
	while _turns.size() > 1 and int(_turns[0][0]) < usec - SWIRL_WINDOW_USEC:
		_turns.pop_front()
	var recent := 0.0
	for entry in _turns:
		recent += float(entry[1])
	var circled := 0.0
	for entry in _finger_turns:
		circled += float(entry[1])
	# A swirl: the ball has gone round far enough one way, recently, the same way the
	# finger circles. A sway, a single swing or a corner never curves.
	if absf(rad_to_deg(recent)) >= float(tuning.swirl_start_deg) and signf(circled) == signf(recent) and absf(rad_to_deg(circled)) >= 0.5 * float(tuning.swirl_start_deg):
		_swirl_direction = signf(recent) # circled the other way, the swirl follows
		swirling = true
	elif swirling and absf(orbit_speed) < 0.03 * float(tuning.full_charge_speed) and absf(rad_to_deg(recent)) < 90.0:
		swirling = false # wound down: hanging and swaying again
	_usec = usec
	_charge_history.append([usec, charge()])
	while _charge_history.size() > 2 and _charge_history[1][0] < usec - HISTORY_USEC - int(tuning.release_window_usec):
		_charge_history.pop_front()
	while _finger_history.size() > 2 and _finger_history[1][0] < usec - HISTORY_USEC - MAX_LAG_USEC:
		_finger_history.pop_front()
