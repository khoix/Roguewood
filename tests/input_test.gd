extends RefCounted
## Gesture recognition and launch mapping from synthetic timestamped samples.
const Flick = preload("res://src/input/flick_gesture.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Ring = preload("res://src/input/target_ring.gd")
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

## Steps tracing sweep_deg of a circle (positive = clockwise on screen, y down)
## that starts at the circle's bottom, i.e. on the ball, 10 degrees per frame.
static func circle(radius: float, sweep_deg: float) -> Array:
	var steps: Array = []
	var center := Vector2(0.0, -radius)
	var at := Vector2.ZERO
	var count := int(absf(sweep_deg) / 10.0)
	for i in count:
		var angle := deg_to_rad(90.0 + signf(sweep_deg) * 10.0 * (i + 1))
		var next := center + Vector2(cos(angle), sin(angle)) * radius
		steps.append(next - at)
		at = next
	return steps

static func run() -> Array[String]:
	var failures: Array[String] = []
	_spin_cases(failures)
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
	var flick := {"angle_deg": 15.0, "power": 0.4, "spin": -0.5}
	var gestured := Mapper.to_launch(flick, 0.3, "same", 2, -0.2, 0.12)
	var assisted := Mapper.from_controls({"start_x": 0.3, "angle_deg": Mapper.launch_angle(15.0), "power": 0.4, "spin": -0.5}, "same", 2, -0.2, 0.12)
	_expect(gestured == assisted and Contracts.validate("launch", assisted).is_empty(), "accessible controls emit the identical launch", failures)
	_expect(Mapper.from_controls({"start_x": -3.0, "angle_deg": 9.0, "power": 2.0, "spin": -4.0}, "c", 1).spin == -1.0, "control values clamp to contract", failures)
	_expect(Ring.radius(0, false) == Ring.RING_MAX and Ring.radius(Ring.PERIOD_USEC / 2, false) < Ring.RING_MAX, "ring contracts while held", failures)
	_expect(Ring.radius(Ring.PERIOD_USEC - 1, false) >= Ring.RING_MIN and Ring.radius(Ring.PERIOD_USEC, false) == Ring.RING_MAX, "ring restarts each period", failures)
	_expect(Ring.radius(Ring.PERIOD_USEC / 2, true) == Ring.RING_MAX and Ring.grade(Ring.RING_MAX) == "clean", "steady ring is widest and clean-only", failures)
	_expect(Ring.grade(Ring.RING_MIN) == "perfect" and Ring.default_target("left") == -Ring.default_target("right"), "narrow ring perfect; handed pockets mirror", failures)
	return failures

static func _spin_cases(failures: Array[String]) -> void:
	var up := repeat(Vector2(0.0, -0.05), 8)
	var clockwise := gesture(Vector2(0.5, 0.9), circle(0.08, 450.0) + up)
	_expect(clockwise.committed and absf(clockwise.spin - 450.0 / 720.0) < 0.03, "clockwise circle charges positive spin", failures)
	_expect(absf(clockwise.angle_deg) < 1.0, "circle tangent never steers the flick", failures)
	var counter := gesture(Vector2(0.5, 0.9), circle(0.08, -450.0) + up)
	_expect(counter.committed and absf(counter.spin + 450.0 / 720.0) < 0.03, "counter-clockwise circle charges negative spin", failures)
	_expect(gesture(Vector2(0.5, 0.9), circle(0.08, 1260.0) + up).spin == 1.0, "spin capped at two loops", failures)
	_expect(gesture(Vector2(0.5, 0.9), circle(0.08, 150.0) + up).spin == 0.0, "partial arc stays inside dead zone", failures)
	var corner := gesture(Vector2(0.5, 0.9), repeat(Vector2(0.03, 0.0), 6) + up)
	_expect(corner.committed and corner.spin == 0.0, "placement then flick is straight", failures)
	var zigzag := gesture(Vector2(0.5, 0.9), repeat(Vector2(0.03, 0.0), 4) + repeat(Vector2(-0.03, 0.0), 4) + repeat(Vector2(0.03, 0.0), 4) + up)
	_expect(zigzag.spin == 0.0 and absf(zigzag.turn_deg) <= 91.0, "sideways reversals add no turning (only the flick corner)", failures)
	# Placement follows the finger, then locks once circling starts.
	var holding := Flick.new()
	holding.begin(Vector2(0.5, 0.9), 0)
	var at := Vector2(0.5, 0.9)
	var usec := 0
	for step in repeat(Vector2(0.03, 0.0), 3) + circle(0.08, 360.0):
		at += step
		usec += FRAME_USEC
		holding.move(at, usec)
	_expect(holding.locked != null and absf(holding.placement().x - 0.59) < 1e-5 and holding.placement() != at, "ball stops following once circling begins", failures)
	_expect(absf(holding.charge() - 0.5) < 0.03, "live meter shows charged spin", failures)
	# Sensitivity scales flick speed: a slow drag commits when sensitivity is raised.
	var slow := repeat(Vector2(0.0, -0.008), 40)
	var sensitive := Flick.new()
	sensitive.sensitivity = 2.0
	var t := 0
	var point := Vector2(0.5, 0.9)
	sensitive.begin(point, t)
	for step in slow:
		point += step
		t += FRAME_USEC
		sensitive.move(point, t)
	var boosted := sensitive.release(point, t)
	_expect(gesture(Vector2(0.5, 0.9), slow).reason == "slow" and boosted.committed, "sensitivity scales flick speed", failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
