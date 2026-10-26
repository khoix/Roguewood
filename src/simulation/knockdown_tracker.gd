extends RefCounted
## Pure per-tick knockdown bookkeeping for one roll. No scene or physics access:
## the lane world feeds observations; identical observations give identical reports.
## A pin is credited once, at the first tick it exceeds the fall tilt or leaves the
## deck, and is never resurrected. Attribution is the first disturbing contact.
## Gutter rule (USBC illegal pinfall): a ball that leaves the lane before touching
## any pin is a gutter ball; pins it disturbs are voided and respotted, not credited.
const Lane = preload("res://src/simulation/lane_spec.gd")

const TICKS_PER_SECOND := 120
const FALL_TILT_DEG := 45.0
const LEAN_TILT_DEG := 12.0 # at rest beyond this a pin cannot stand unsupported
const OFF_DECK_DROP := 0.03
const QUIET_LINEAR := 0.03
const QUIET_ANGULAR := 0.35
const SETTLE_TICKS := 30
const BALL_STALL_TICKS := 60
const PIN_ACTION_TICKS := 540 # 4.5 s after first pin contact
const MAX_TICKS := 1440 # 12 s after release

var tick := 0
var pins: Dictionary = {}
var positions: Array[int] = []
var sequence: Array[int] = []
var gutter := false
var voided: Array[int] = []
var ball_touched_pins := false
var ball_done := false
var target_crossed := false
var target_offset_m := 0.0
var first_contact_tick := -1
var finished := false
var settle := ""
var _quiet := 0
var _stalled := 0
var _last_ball: Variant = null

func _init(standing_positions: Array) -> void:
	for position in standing_positions:
		positions.append(int(position))
	positions.sort()
	for position in positions:
		pins[position] = {"cause": "", "source": 0, "depth": 0, "fallen": false, "reason": "", "tick": -1, "tilt": 0.0}

## observation = {"ball": {x, y, f, speed}, "pins": {position: {tilt, x, y, f, linear, angular, contacts}}}
## contacts lists "ball", other rack positions (int) or "static". Returns true once finished.
func step(observation: Dictionary) -> bool:
	if finished:
		return true
	tick += 1
	for position in positions:
		if "ball" in observation.pins[position].contacts:
			ball_touched_pins = true
	_track_ball(observation.ball)
	var disturbed := {}
	for position in positions:
		if pins[position].depth > 0:
			disturbed[position] = pins[position].depth
	var quiet := true
	for position in positions:
		var pin: Dictionary = pins[position]
		var seen: Dictionary = observation.pins[position]
		pin.tilt = float(seen.tilt)
		if pin.depth == 0:
			_attribute(pin, seen.contacts, disturbed)
		if not pin.fallen:
			if _off_deck(seen):
				_fall(position, "off_deck")
			elif pin.tilt > FALL_TILT_DEG:
				_fall(position, "tilt")
		if pin.reason != "off_deck" and (seen.linear > QUIET_LINEAR or seen.angular > QUIET_ANGULAR):
			quiet = false
	_quiet = _quiet + 1 if quiet and ball_done else 0
	if _quiet >= SETTLE_TICKS:
		_finish("settled")
	elif tick >= MAX_TICKS or (first_contact_tick >= 0 and tick - first_contact_tick >= PIN_ACTION_TICKS):
		_finish("timeout")
	return finished

func _track_ball(ball: Dictionary) -> void:
	var x := float(ball.x)
	var f := float(ball.f)
	if not ball_touched_pins and f > 0.0 and f < Lane.PIT_F and absf(x) > Lane.LANE_HALF_WIDTH:
		gutter = true
	if _last_ball != null and not target_crossed and _last_ball.f < Lane.TARGET_PLANE_F and f >= Lane.TARGET_PLANE_F:
		var t: float = (Lane.TARGET_PLANE_F - _last_ball.f) / (f - _last_ball.f)
		target_crossed = true
		target_offset_m = lerpf(_last_ball.x, x, t)
	_last_ball = {"x": x, "f": f}
	_stalled = _stalled + 1 if float(ball.speed) < 0.05 else 0
	if f > Lane.PIT_F + Lane.BALL_RADIUS or float(ball.y) < -0.15 or _stalled >= BALL_STALL_TICKS:
		ball_done = true

func _attribute(pin: Dictionary, contacts: Array, disturbed: Dictionary) -> void:
	if "ball" in contacts:
		pin.cause = "ball"
		pin.depth = 1
	else:
		var best := 0
		for other in contacts:
			if typeof(other) == TYPE_INT and disturbed.has(other):
				if best == 0 or disturbed[other] < disturbed[best] or (disturbed[other] == disturbed[best] and other < best):
					best = other
		if best == 0:
			return
		pin.cause = "pin"
		pin.source = best
		pin.depth = disturbed[best] + 1
	if first_contact_tick < 0:
		first_contact_tick = tick

func _off_deck(seen: Dictionary) -> bool:
	return float(seen.y) < -OFF_DECK_DROP or absf(float(seen.x)) > Lane.LANE_HALF_WIDTH + 0.01 or float(seen.f) > Lane.PIT_F

func _fall(position: int, reason: String) -> void:
	var pin: Dictionary = pins[position]
	pin.fallen = true
	pin.reason = reason
	pin.tick = tick
	if pin.cause.is_empty():
		pin.cause = "environment"
	sequence.append(position)

func _finish(kind: String) -> void:
	for position in positions:
		if not pins[position].fallen and pins[position].tilt > LEAN_TILT_DEG:
			_fall(position, "lean")
	if gutter:
		voided = sequence.duplicate()
		voided.sort()
		sequence.clear()
		for position in positions:
			pins[position].fallen = false
	settle = kind
	finished = true

func standing() -> Array[int]:
	var result: Array[int] = []
	for position in positions:
		if not pins[position].fallen:
			result.append(position)
	return result

func knockdowns() -> Array:
	var result: Array = []
	for index in sequence.size():
		var pin: Dictionary = pins[sequence[index]]
		result.append({"position": sequence[index], "sequence": index + 1, "tick": pin.tick, "cause": pin.cause,
			"source_position": pin.source, "chain_depth": pin.depth, "reason": pin.reason})
	return result

func target_offset() -> float:
	return target_offset_m / Lane.LANE_HALF_WIDTH
