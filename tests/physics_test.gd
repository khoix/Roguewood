extends RefCounted
## Physics lab suite: launch fixtures through real Jolt worlds. Checks contracts,
## outcome classes, exact same-build repeatability, aim-delay invariance and
## JSON rack round trips; reports 0.002 start-x sensitivity without asserting it.
const Contracts = preload("res://src/contracts/contracts.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const LaneWorld = preload("res://src/simulation/lane_world.gd")
const FIXTURES := "res://content/fixtures/throws/lab_throws.json"
const REPEATS := 3
const CONCURRENT := 10
const ROLL_TICK_LIMIT := 2000
const COMPARED := ["roll_result", "knockdown_log", "final_state", "rack_after"]

var failures: Array[String] = []
var results := {}
var _active := 0

static func rack_of(positions: Array) -> Dictionary:
	var standing: Array = []
	for position in positions:
		var at := Lane.spot(int(position))
		standing.append({"position": int(position), "x": at.x, "f": at.y})
	return {"schema_version": 1, "standing": standing}

static func launch_of(fixture: Dictionary, id: String, start_x: float = NAN) -> Dictionary:
	var angle := deg_to_rad(float(fixture.angle_deg))
	return {"schema_version": 1, "launch_id": id, "ball_id": "ball.house", "roll_index": 1,
		"start_x": float(fixture.start_x) if is_nan(start_x) else start_x, "direction_x": sin(angle), "direction_forward": cos(angle),
		"power": float(fixture.power), "spin": 0.0, "target_x": Lane.DEFAULT_TARGET_X, "ring_radius": Lane.DEFAULT_RING_RADIUS}

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _simulate(tree: SceneTree, key: String, rack: Dictionary, launch: Dictionary, idle_ticks: int) -> void:
	_active += 1
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var world: Node3D = LaneWorld.new()
	viewport.add_child(world)
	world.setup(rack)
	for i in idle_ticks:
		await tree.physics_frame
	var errors: Array[String] = world.commit(launch)
	_check(errors.is_empty(), key + " launch accepted " + str(errors))
	var ticks := 0
	while errors.is_empty() and world.state != "finished" and ticks < ROLL_TICK_LIMIT:
		await tree.physics_frame
		ticks += 1
	_check(world.state == "finished", key + " finished within tick limit")
	results[key] = world.report.duplicate(true)
	viewport.queue_free()
	_active -= 1

func _run_jobs(tree: SceneTree, jobs: Array) -> void:
	for job in jobs:
		while _active >= CONCURRENT:
			await tree.physics_frame
		_simulate(tree, job[0], job[1], job[2], job[3])
	while _active > 0:
		await tree.physics_frame

func run(tree: SceneTree, report_path: String) -> Array[String]:
	var started := Time.get_ticks_msec()
	var fixtures: Array = Contracts.read_json(FIXTURES).throws
	var jobs: Array = []
	for fixture in fixtures:
		for repeat in REPEATS:
			jobs.append(["%s#%d" % [fixture.id, repeat], rack_of(fixture.rack), launch_of(fixture, fixture.id), 0])
		if fixture.rack.size() == 10:
			jobs.append([fixture.id + "+nudge", rack_of(fixture.rack), launch_of(fixture, fixture.id, clampf(float(fixture.start_x) + 0.002, -Lane.MAX_START_X, Lane.MAX_START_X)), 0])
	for idle in [13, 97]:
		jobs.append(["pocket@idle%d" % idle, rack_of(fixtures[0].rack), launch_of(fixtures[0], fixtures[0].id), idle])
	await _run_jobs(tree, jobs)
	var summary := {}
	var nudged := 0
	var changed := 0
	for fixture in fixtures:
		var first: Dictionary = results.get(fixture.id + "#0", {})
		if first.is_empty():
			continue
		_check_report(fixture, first)
		for repeat in range(1, REPEATS):
			for key in COMPARED:
				_check(results.get("%s#%d" % [fixture.id, repeat], {}).get(key) == first[key], "%s repeat %d identical %s" % [fixture.id, repeat, key])
		var fallen: Array = first.roll_result.fallen_positions
		summary[fixture.id] = {"fallen": fallen, "standing": first.knockdown_log.standing, "gutter": first.knockdown_log.gutter,
			"accuracy": first.roll_result.accuracy, "settle": first.knockdown_log.settle, "ticks": first.knockdown_log.ticks,
			"chain": first.knockdown_log.knockdowns.map(func(k): return [k.position, k.cause, k.source_position]),
			"digest": JSON.stringify(first.final_state, "", true, true).sha256_text()}
		if results.has(fixture.id + "+nudge"):
			nudged += 1
			var nudge: Array = results[fixture.id + "+nudge"].roll_result.fallen_positions
			summary[fixture.id].nudged_fallen = nudge
			if nudge != fallen:
				changed += 1
	for idle in [13, 97]:
		for key in COMPARED:
			_check(results.get("pocket@idle%d" % idle, {}).get(key) == results.get("pocket#0", {}).get(key), "aim delay %d ticks cannot change %s" % [idle, key])
	await _second_roll_round_trip(tree, fixtures)
	var report := {"engine": Engine.get_version_info().string, "physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine"),
		"ticks_per_second": Engine.physics_ticks_per_second, "simulations": results.size(), "elapsed_ms": Time.get_ticks_msec() - started,
		"sensitivity": {"start_x_delta": 0.002, "nudged": nudged, "changed_outcome": changed},
		"digest": JSON.stringify(summary, "", true, true).sha256_text(), "throws": summary, "failures": failures}
	if not report_path.is_empty():
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  ", true, true))
	print("PHYSICS simulations=%d elapsed_ms=%d sensitivity_changed=%d/%d digest=%s" % [results.size(), report.elapsed_ms, changed, nudged, report.digest])
	for id in summary:
		print("PHYSICS %s fallen=%s gutter=%s settle=%s ticks=%d" % [id, str(summary[id].fallen), str(summary[id].gutter), summary[id].settle, summary[id].ticks])
	return failures

## Survivor racks persist as JSON (E10); a round trip must not change roll two.
func _second_roll_round_trip(tree: SceneTree, fixtures: Array) -> void:
	var first: Dictionary = results.get("head_on#0", {})
	if first.is_empty() or first.rack_after.standing.is_empty():
		_check(false, "head_on leaves survivors for a second roll")
		return
	var stored: Dictionary = JSON.parse_string(JSON.stringify(first.rack_after, "", true, true))
	var follow := launch_of({"start_x": 0.0, "angle_deg": 0.0, "power": 0.5}, "second")
	follow.roll_index = 2
	await _run_jobs(tree, [["second@memory", first.rack_after, follow, 0], ["second@json", stored, follow, 5]])
	for key in COMPARED:
		_check(results.get("second@memory", {}).get(key) == results.get("second@json", {}).get(key), "JSON rack round trip cannot change second roll " + key)
	var second: Dictionary = results.get("second@memory", {})
	if not second.is_empty():
		for position in second.roll_result.fallen_positions:
			_check(position in first.knockdown_log.standing, "second roll credits only survivors")

func _check_report(fixture: Dictionary, report: Dictionary) -> void:
	var id: String = fixture.id
	_check(Contracts.validate_result_for_launch(report.launch, report.roll_result).is_empty(), id + " result contract")
	_check(Contracts.validate_log_for_result(report.roll_result, report.knockdown_log).is_empty(), id + " knockdown log contract")
	var accounted: Array = report.roll_result.fallen_positions + report.knockdown_log.standing
	accounted.sort()
	var racked: Array = fixture.rack.map(func(p): return int(p))
	racked.sort()
	_check(accounted == racked, id + " every pin credited once or standing")
	var fallen: Array = report.roll_result.fallen_positions
	var expect: Dictionary = fixture.expect
	_check(fallen.size() >= int(expect.get("min_fallen", 0)), "%s at least %d down, got %s" % [id, int(expect.get("min_fallen", 0)), str(fallen)])
	_check(fallen.size() <= int(expect.get("max_fallen", 10)), "%s at most %d down, got %s" % [id, int(expect.get("max_fallen", 10)), str(fallen)])
	for position in expect.get("includes", []):
		_check(int(position) in fallen, "%s knocks pin %d, got %s" % [id, int(position), str(fallen)])
	for position in expect.get("excludes", []):
		_check(int(position) not in fallen, "%s leaves pin %d, got %s" % [id, int(position), str(fallen)])
	if expect.has("gutter"):
		_check(report.knockdown_log.gutter == expect.gutter, "%s gutter=%s" % [id, str(expect.gutter)])
	for knockdown in report.knockdown_log.knockdowns:
		_check(knockdown.cause != "environment", "%s pin %d fell without a recorded cause" % [id, knockdown.position])
