extends RefCounted
## Launch mapping and the target ring. The gesture itself is the held-ball model,
## tested in held_ball_test.gd (E05-R1, ADR 011); E05's path-turn gesture is retired.
const Mapper = preload("res://src/input/launch_mapper.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Ring = preload("res://src/input/target_ring.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var straight := {"angle_deg": 0.0, "power": 0.6875, "spin": 0.0}
	_expect(absf(Mapper.launch_angle(20.0) - 2.0) < 1e-6 and Mapper.launch_angle(-55.0) == -Mapper.MAX_LAUNCH_ANGLE_DEG, "lane angle gain and clamp", failures)
	var launch := Mapper.to_launch(straight, 2.0, "throw-1", 1)
	_expect(Contracts.validate("launch", launch).is_empty(), "mapped launch satisfies contract", failures)
	_expect(launch.spin == 0.0 and launch.start_x == Lane.MAX_START_X and launch.direction_forward == 1.0, "straight launch, ball kept on lane", failures)
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

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
