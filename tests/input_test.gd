extends RefCounted
## Gesture recognition and launch mapping from synthetic timestamped samples.
const Flick = preload("res://src/input/flick_gesture.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const FRAME_USEC := 16667

## Feeds begin, one move per frame along steps, then release at the final point.
static func gesture(start: Vector2, steps: Array) -> Dictionary:
	var flick := Flick.new()
	var at := start
	var usec := 1000000
	flick.begin(at, usec)
	for step in steps:
		at += step
		usec += FRAME_USEC
		flick.move(at, usec)
	return flick.release(at, usec)

static func repeat(step: Vector2, count: int) -> Array:
	var steps: Array = []
	for i in count: steps.append(step)
	return steps

static func run() -> Array[String]:
	var failures: Array[String] = []
	var straight := gesture(Vector2(0.5, 0.9), repeat(Vector2(0.0, -0.05), 8))
	_expect(straight.committed and absf(straight.angle_deg) < 1e-6, "straight upward flick commits", failures)
	_expect(absf(straight.speed - 3.0) < 0.01 and absf(straight.power - (3.0 - 0.8) / 3.2) < 0.01, "flick speed maps to power", failures)
	_expect(gesture(Vector2(0.5, 0.9), repeat(Vector2(0.0, -0.05), 8)) == straight, "deterministic for identical samples", failures)
	_expect(gesture(Vector2(0.5, 0.9), repeat(Vector2(0.0, -0.008), 40)).reason == "slow", "slow upward drag cancels", failures)
	_expect(gesture(Vector2(0.5, 0.9), repeat(Vector2(0.03, 0.0), 10)).reason == "short", "sideways placement alone cancels", failures)
	_expect(gesture(Vector2(0.5, 0.5), repeat(Vector2(0.0, 0.05), 6)).reason == "short", "downward drag cancels", failures)
	_expect(gesture(Vector2(0.5, 0.9), repeat(Vector2(0.0, -0.01), 2)).reason == "short", "tiny flick cancels", failures)
	_expect(gesture(Vector2(0.5, 0.9), []).reason == "no_motion", "tap without motion cancels", failures)
	_expect(gesture(Vector2(0.5, 0.9), repeat(Vector2(0.06, -0.02), 8)).reason == "not_forward", "mostly sideways flick cancels", failures)
	_expect(gesture(Vector2(0.5, 0.9), repeat(Vector2(0.0, -0.2), 6)).power == 1.0, "violent flick capped at full power", failures)
	# Sideways placement and a circle first; only the final window steers.
	var circle: Array = repeat(Vector2(0.02, 0.0), 10)
	for i in 24:
		var angle := TAU * i / 24.0
		circle.append(Vector2(cos(angle), sin(angle)) * 0.02)
	circle.append_array(repeat(Vector2(0.0, -0.06), 7))
	var late := gesture(Vector2(0.4, 0.9), circle)
	_expect(late.committed and absf(late.angle_deg) < 1e-3, "final window, not circle tangent, sets direction", failures)
	_expect(absf(late.anchor.x - 0.6) < 1e-3, "placement anchor is finger x at flick start", failures)
	var angled := gesture(Vector2(0.5, 0.9), repeat(Vector2(0.05 * tan(deg_to_rad(20.0)), -0.05), 8))
	_expect(absf(angled.angle_deg - 20.0) < 0.01, "flick angle measured from straight up", failures)
	_expect(absf(Mapper.launch_angle(20.0) - 2.0) < 1e-6 and Mapper.launch_angle(-55.0) == -Mapper.MAX_LAUNCH_ANGLE_DEG, "lane angle gain and clamp", failures)
	var launch := Mapper.to_launch(straight, 2.0, "throw-1", 1)
	_expect(Contracts.validate("launch", launch).is_empty(), "mapped launch satisfies contract", failures)
	_expect(launch.spin == 0.0 and launch.start_x == Lane.MAX_START_X and launch.direction_forward == 1.0, "straight launch, ball kept on lane", failures)
	var tracking := Flick.new()
	tracking.begin(Vector2(0.5, 0.9), 0)
	tracking.move(Vector2(0.58, 0.9), FRAME_USEC)
	_expect(tracking.placement() == Vector2(0.58, 0.9) and tracking.origin == Vector2(0.5, 0.9), "ball follows finger while holding", failures)
	tracking.cancel()
	_expect(not tracking.active and tracking.release(Vector2(0.5, 0.2), 2 * FRAME_USEC).reason == "inactive", "cancelled touch cannot launch", failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
