extends RefCounted
## Pure lane geometry and knockdown bookkeeping, driven by synthetic observations.
const Lane = preload("res://src/simulation/lane_spec.gd")
const Tracker = preload("res://src/simulation/knockdown_tracker.gd")
const World = preload("res://src/simulation/lane_world.gd")

static func observation(ball_f: float, ball_x: float = 0.0, changes: Dictionary = {}, speed: float = 7.0) -> Dictionary:
	var pins := {}
	for position in range(1, 11):
		var at := Lane.spot(position)
		pins[position] = {"tilt": 0.0, "x": at.x, "y": 0.0, "f": at.y, "linear": 0.0, "angular": 0.0, "contacts": []}
		if changes.has(position):
			pins[position].merge(changes[position], true)
	return {"ball": {"x": ball_x, "y": Lane.BALL_RADIUS, "f": ball_f, "speed": speed}, "pins": pins}

static func run() -> Array[String]:
	var failures: Array[String] = []
	_geometry(failures)
	_attribution(failures)
	_settle_and_timeout(failures)
	_gutter(failures)
	_overlaps(failures)
	return failures

static func _geometry(failures: Array[String]) -> void:
	var adjacent := [[1, 2], [1, 3], [2, 3], [2, 4], [2, 5], [3, 5], [3, 6], [4, 7], [4, 8], [5, 8], [5, 9], [6, 9], [6, 10], [7, 8], [9, 10]]
	for pair in adjacent:
		_expect(absf(Lane.spot(pair[0]).distance_to(Lane.spot(pair[1])) - Lane.PIN_SPACING) < 1e-5, "regulation spacing %s" % str(pair), failures)
	_expect(Lane.spot(1) == Vector2(0.0, Lane.HEAD_PIN_F), "head pin spot", failures)
	_expect(absf(Lane.spot(7).x + 0.4572) < 1e-6 and absf(Lane.spot(10).x - 0.4572) < 1e-6, "corner pins left/right", failures)
	_expect(Lane.spot(2).x < 0.0 and Lane.spot(3).x > 0.0, "2 pin left of 3 pin from bowler", failures)
	_expect(Lane.fresh_rack().standing.size() == 10, "fresh rack has ten pins", failures)
	_expect(Lane.world(0.3, 5.0) == Vector3(0.3, 0.0, -5.0), "forward runs along -z", failures)
	_expect(Lane.ball_speed(-1.0) == Lane.MIN_BALL_SPEED and Lane.ball_speed(2.0) == Lane.MAX_BALL_SPEED, "ball speed clamps", failures)
	_expect(Lane.grade_accuracy(false, 0.0, 0.05) == "miss", "uncrossed target misses", failures)
	_expect(Lane.grade_accuracy(true, 0.3, 0.25) == "miss", "outside ring misses", failures)
	_expect(Lane.grade_accuracy(true, 0.2, 0.25) == "clean", "wide ring clean", failures)
	_expect(Lane.grade_accuracy(true, 0.1, 0.12) == "sweet", "narrow ring sweet", failures)
	_expect(Lane.grade_accuracy(true, -0.05, 0.06) == "perfect", "narrowest ring perfect", failures)
	var points := World.hull_points(0, Lane.PIN_NECK_INDEX)
	_expect(points.size() == (Lane.PIN_NECK_INDEX + 1) * World.HULL_SEGMENTS, "pin hull ring count", failures)

static func _attribution(failures: Array[String]) -> void:
	var tracker := Tracker.new(range(1, 11))
	tracker.step(observation(18.0))
	tracker.step(observation(18.1, 0.0, {1: {"contacts": ["ball"], "linear": 2.0}}))
	# Same tick: 2 touches 1, but 1 only became disturbed this tick.
	tracker.step(observation(18.2, 0.0, {1: {"tilt": 50.0, "contacts": [2]}, 2: {"contacts": [1, "static"]}, 4: {"contacts": [2]}}))
	_expect(tracker.pins[2].depth == 2 and tracker.pins[2].source == 1, "pin chain attribution", failures)
	_expect(tracker.pins[4].depth == 0, "chain uses tick-start disturbed set", failures)
	tracker.step(observation(18.3, 0.0, {1: {"tilt": 0.0}, 2: {"y": -0.1}, 4: {"contacts": [3, 2]}, 3: {"contacts": ["ball", 1]}}))
	_expect(tracker.pins[3].cause == "ball", "ball contact outranks pin contact", failures)
	_expect(tracker.pins[4].source == 2 and tracker.pins[4].depth == 3, "lowest-depth disturbed source wins", failures)
	tracker.step(observation(18.4, 0.0, {1: {"tilt": 80.0}, 7: {"tilt": 60.0}}))
	var knocked: Array = tracker.knockdowns()
	_expect(knocked.map(func(k): return k.position) == [1, 2, 7], "fall order by tick then position", failures)
	_expect(knocked[0].cause == "ball" and knocked[0].reason == "tilt" and knocked[0].tick == 3, "ball knockdown record", failures)
	_expect(knocked[1].reason == "off_deck" and knocked[1].cause == "pin", "off deck knockdown", failures)
	_expect(knocked[2].cause == "environment" and knocked[2].chain_depth == 0, "uncaused fall is environment", failures)
	_expect(tracker.sequence.size() == 3, "upright again is never resurrected or recredited", failures)
	var swapped := Tracker.new(range(1, 11))
	var plain := Tracker.new(range(1, 11))
	swapped.step(observation(18.0, 0.0, {5: {"contacts": [3, "ball"], "tilt": 70.0}}))
	plain.step(observation(18.0, 0.0, {5: {"contacts": ["ball", 3], "tilt": 70.0}}))
	_expect(swapped.knockdowns() == plain.knockdowns(), "contact order cannot change attribution", failures)

static func _settle_and_timeout(failures: Array[String]) -> void:
	var tracker := Tracker.new(range(1, 11))
	var f := 17.9
	while not tracker.finished and tracker.tick < 200:
		f += 0.06
		tracker.step(observation(f, 0.03))
	_expect(tracker.finished and tracker.settle == "settled", "quiet rack settles after ball reaches pit", failures)
	_expect(tracker.target_crossed and absf(tracker.target_offset() - 0.03 / Lane.LANE_HALF_WIDTH) < 1e-6, "target crossing measured", failures)
	_expect(tracker.standing().size() == 10 and tracker.knockdowns().is_empty(), "untouched rack stands", failures)
	var busy := Tracker.new(range(1, 11))
	busy.step(observation(18.2, 0.0, {1: {"contacts": ["ball"], "linear": 1.0}}))
	while not busy.finished and busy.tick < Tracker.MAX_TICKS + 5:
		busy.step(observation(20.0, 0.0, {1: {"linear": 1.0}, 6: {"tilt": 20.0, "linear": 1.0}}))
	_expect(busy.settle == "timeout" and busy.tick == Tracker.PIN_ACTION_TICKS + 1, "pin action timeout", failures)
	_expect(busy.knockdowns().map(func(k): return [k.position, k.reason]) == [[6, "lean"]], "leaning pin at timeout counts down", failures)
	var stuck := Tracker.new(range(1, 11))
	while not stuck.finished and stuck.tick < Tracker.MAX_TICKS + 5:
		stuck.step(observation(10.0, 0.0, {}, 0.0))
	_expect(stuck.ball_done and stuck.settle == "settled" and stuck.tick == Tracker.BALL_STALL_TICKS + Tracker.SETTLE_TICKS - 1, "stalled ball ends roll", failures)
	var never := Tracker.new(range(1, 11))
	while not never.finished and never.tick < Tracker.MAX_TICKS + 5:
		never.step(observation(10.0, 0.0, {}, 3.0))
	_expect(never.settle == "timeout" and never.tick == Tracker.MAX_TICKS, "hard roll timeout", failures)
	var partial := Tracker.new([3, 6, 10])
	partial.step(observation(18.5, 0.0, {3: {"contacts": ["ball"], "tilt": 90.0}}))
	_expect(partial.knockdowns().size() == 1 and partial.standing() == [6, 10], "second roll tracks only standing pins", failures)

static func _gutter(failures: Array[String]) -> void:
	var tracker := Tracker.new(range(1, 11))
	tracker.step(observation(5.0, Lane.LANE_HALF_WIDTH + 0.05))
	tracker.step(observation(19.0, 0.4, {10: {"tilt": 90.0}}))
	while not tracker.finished:
		tracker.step(observation(20.0, 0.4))
	_expect(tracker.gutter and tracker.knockdowns().is_empty() and tracker.voided == [10], "gutter voids and respots pinfall", failures)
	_expect(tracker.standing().size() == 10, "gutter rack all standing", failures)
	var late := Tracker.new(range(1, 11))
	late.step(observation(18.9, 0.45, {10: {"contacts": ["ball"], "tilt": 70.0}}))
	late.step(observation(19.0, Lane.LANE_HALF_WIDTH + 0.05))
	_expect(not late.gutter and late.knockdowns().size() == 1, "leaving lane after reaching pins is not a gutter", failures)

static func _overlaps(failures: Array[String]) -> void:
	var rack: Array = [{"position": 2, "x": 0.0, "f": 18.5}, {"position": 1, "x": 0.01, "f": 18.5}]
	var resolved: Array = World.resolve_overlaps(rack)
	var gap := Vector2(resolved[0].x, resolved[0].f).distance_to(Vector2(resolved[1].x, resolved[1].f))
	_expect(resolved[0].position == 1 and gap >= World.SEPARATION - 1e-5, "respotted survivors separated", failures)
	_expect(rack[0].x == 0.0, "overlap resolution copies input", failures)
	_expect(World.resolve_overlaps(Lane.fresh_rack().standing) == Lane.fresh_rack().standing, "fresh rack unchanged", failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
