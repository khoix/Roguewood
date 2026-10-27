extends RefCounted
## Physical lane units for the throw lab (E04, hook E05). Meters, kilograms, seconds.
## World axes: +x is the bowler's right, +y up, forward distance f runs along -z
## from the foul line (f = 0). Contract coordinates normalize x by LANE_HALF_WIDTH.
## Dimensions follow regulation ten-pin geometry; masses/materials are lab values.

const LANE_HALF_WIDTH := 0.52705 # 41.5 in lane
const APPROACH_LENGTH := 4.572
const HEAD_PIN_F := 18.288 # foul line to head pin center
const PIN_SPACING := 0.3048
const ROW_SPACING := 0.263965 # PIN_SPACING * cos(30 deg)
const PIT_F := 19.1564 # foul line to pit edge
const PIT_DEPTH := 0.35
const PIT_LENGTH := 0.9
const GUTTER_WIDTH := 0.235
const GUTTER_DEPTH := 0.0476
const KICKBACK_START_F := 17.6
const KICKBACK_HEIGHT := 0.75
const KICKBACK_SETBACK := 0.03
const SURFACE_FRICTION := 0.4 # lane side; the ball's friction (min-combined) sets the oil pattern
const PIN_BOUNCE := 0.25 # pin-pin restitution 0.5 under sum combine
const PIN_LINEAR_DAMP := 0.6
const PIN_ANGULAR_DAMP := 1.5
const BALL_BOUNCE := 0.4 # ball-pin restitution 0.65

## E05 oil pattern, applied as the ball's friction by forward distance. Jolt
## combines friction by minimum, so the ball's value is the lane contact value.
## The deck zone keeps E04's ball-pin/deck friction.
const OIL_END_F := 12.192 # 40 ft house pattern
const OIL_FRICTION := 0.002
const BACKEND_FRICTION := 0.2
const DECK_ZONE_F := HEAD_PIN_F - 1.0
const BALL_PIN_FRICTION := 0.12
## Positive spin is clockwise as the bowler sees it and hooks right (+x). It is
## side rotation about the travel axis on top of a true forward roll, so friction
## acts sideways only: little in the oil, strongly in the backend. Slower balls
## spend longer in the backend and hook more.
const MAX_SIDE_SPIN := 15.0 # rad/s at |spin| = 1 for the House ball
const CURVE_SPIN_THRESHOLD := 0.25 # |spin| at or above this is a curved shot

## Ball ids the lane can simulate. Lab fixture balls (E07) differ only in scoring
## effects and share the House physics; real special-ball physics is E17/E18.
const SIMULATED_BALLS := ["ball.house", "ball.lab_value", "ball.lab_mult", "ball.lab_coin"]

const BALL_RADIUS := 0.108
const BALL_MASS := 6.35 # 14 lb House ball
const BALL_START_F := 0.25
const MIN_BALL_SPEED := 4.5
const MAX_BALL_SPEED := 9.0

const PIN_HEIGHT := 0.381
const PIN_MASS := 1.55
const PIN_CENTER_OF_MASS_Y := 0.145
const PIN_BELLY_RADIUS := 0.06053
## Regulation profile, [height, radius] from base to crown.
const PIN_PROFILE := [
	[0.0, 0.02579], [0.01905, 0.03592], [0.05715, 0.04961], [0.08573, 0.05728],
	[0.11430, 0.06053], [0.14923, 0.05795], [0.18415, 0.04703], [0.21908, 0.03139],
	[0.23813, 0.02282], [0.25400, 0.02375], [0.27623, 0.02659], [0.29845, 0.03056],
	[0.34290, 0.03235], [0.36195, 0.02837], [0.37465, 0.01800], [0.38100, 0.00500],
]
const PIN_NECK_INDEX := 8

## Ring center plane: where a pocket ball first meets the head pin.
const TARGET_PLANE_F := HEAD_PIN_F - PIN_BELLY_RADIUS - BALL_RADIUS
## Provisional E04 target: right-hand 1-3 pocket with a fixed ring. E05 owns the
## contracting ring, target movement and grade tuning.
const DEFAULT_TARGET_X := 0.11
const DEFAULT_RING_RADIUS := 0.25
const PERFECT_RING := 0.08
const SWEET_RING := 0.16

const MAX_START_X := (LANE_HALF_WIDTH - BALL_RADIUS) / LANE_HALF_WIDTH

## Rack spots by stable position: 1 head pin, 7 left corner, 10 right corner.
static func spot(position: int) -> Vector2:
	var rows := [[1], [2, 3], [4, 5, 6], [7, 8, 9, 10]]
	for row in rows.size():
		var index: int = rows[row].find(position)
		if index >= 0:
			var x: float = (index - (rows[row].size() - 1) * 0.5) * PIN_SPACING
			return Vector2(x, HEAD_PIN_F + row * ROW_SPACING)
	push_error("Unknown rack position %d" % position)
	return Vector2.ZERO

static func world(x: float, f: float, y: float = 0.0) -> Vector3:
	return Vector3(x, y, -f)

static func lane_point(point: Vector3) -> Vector2:
	return Vector2(point.x, -point.z)

static func fresh_rack() -> Dictionary:
	var standing: Array = []
	for position in range(1, 11):
		var at := spot(position)
		standing.append({"position": position, "x": at.x, "f": at.y})
	return {"schema_version": 1, "standing": standing}

static func ball_speed(power: float) -> float:
	return lerpf(MIN_BALL_SPEED, MAX_BALL_SPEED, clampf(power, 0.0, 1.0))

## Simulation measures the crossing; rules award the grade once per frame.
static func grade_accuracy(crossed: bool, offset: float, ring_radius: float) -> String:
	if not crossed or absf(offset) > ring_radius:
		return "miss"
	if ring_radius <= PERFECT_RING:
		return "perfect"
	if ring_radius <= SWEET_RING:
		return "sweet"
	return "clean"

static func ball_friction(f: float) -> float:
	if f >= DECK_ZONE_F:
		return BALL_PIN_FRICTION
	return OIL_FRICTION if f < OIL_END_F else BACKEND_FRICTION

static func side_spin(spin: float) -> float:
	return clampf(spin, -1.0, 1.0) * MAX_SIDE_SPIN

static func is_curved(spin: float) -> bool:
	return absf(spin) >= CURVE_SPIN_THRESHOLD

## Lateral hook in meters where the ball crossed the target plane, relative to
## the straight launch line. NAN if the ball never reached the plane.
static func hook_at_target(launch: Dictionary, knockdown_log: Dictionary) -> float:
	if not knockdown_log.target_crossed:
		return NAN
	var straight: float = launch.start_x * LANE_HALF_WIDTH + launch.direction_x / launch.direction_forward * (TARGET_PLANE_F - BALL_START_F)
	return knockdown_log.target_offset * LANE_HALF_WIDTH - straight
