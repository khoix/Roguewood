extends RefCounted
## Physics lab suite: launch fixtures through real Jolt worlds. Checks contracts,
## outcome classes, hook direction/size, exact same-build repeatability, aim-delay
## invariance and JSON rack round trips; reports 0.002 start-x sensitivity
## without asserting it.
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
		"power": float(fixture.power), "spin": float(fixture.get("spin", 0.0)), "target_x": Lane.DEFAULT_TARGET_X, "ring_radius": Lane.DEFAULT_RING_RADIUS}

## Hook at the target plane (meters); 0 when the ball never reached it, so reports stay valid JSON.
static func curve_of(report: Dictionary) -> float:
	var hook := Lane.hook_at_target(report.launch, report.knockdown_log)
	return 0.0 if is_nan(hook) else hook

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _simulate(tree: SceneTree, key: String, rack: Dictionary, launch: Dictionary, idle_ticks: int, rules: Dictionary = {}, condition: String = "lane.house") -> void:
	_active += 1
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(viewport)
	var world: Node3D = LaneWorld.new()
	viewport.add_child(world)
	world.rules = rules
	world.lane_condition = condition
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
		_simulate(tree, job[0], job[1], job[2], job[3], job[4] if job.size() > 4 else {}, job[5] if job.size() > 5 else "lane.house")
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
		summary[fixture.id] = {"fallen": fallen, "standing": first.knockdown_log.standing, "gutter": first.knockdown_log.gutter, "curve_m": curve_of(first),
			"accuracy": first.roll_result.accuracy, "settle": first.knockdown_log.settle, "ticks": first.knockdown_log.ticks,
			"chain": first.knockdown_log.knockdowns.map(func(k): return [k.position, k.cause, k.source_position]),
			"digest": JSON.stringify(first.final_state, "", true, true).sha256_text()}
		if results.has(fixture.id + "+nudge"):
			nudged += 1
			var nudge: Array = results[fixture.id + "+nudge"].roll_result.fallen_positions
			summary[fixture.id].nudged_fallen = nudge
			if nudge != fallen:
				changed += 1
	_hook_relations(summary)
	for idle in [13, 97]:
		for key in COMPARED:
			_check(results.get("pocket@idle%d" % idle, {}).get(key) == results.get("pocket#0", {}).get(key), "aim delay %d ticks cannot change %s" % [idle, key])
	await _second_roll_round_trip(tree, fixtures)
	await _neon(tree, fixtures)
	await _cards(tree, fixtures)
	var report := {"engine": Engine.get_version_info().string, "physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine"),
		"ticks_per_second": Engine.physics_ticks_per_second, "simulations": results.size(), "elapsed_ms": Time.get_ticks_msec() - started,
		"sensitivity": {"start_x_delta": 0.002, "nudged": nudged, "changed_outcome": changed},
		"digest": JSON.stringify(summary, "", true, true).sha256_text(), "throws": summary, "failures": failures}
	if not report_path.is_empty():
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  ", true, true))
	print("PHYSICS simulations=%d elapsed_ms=%d sensitivity_changed=%d/%d digest=%s" % [results.size(), report.elapsed_ms, changed, nudged, report.digest])
	for id in summary:
		print("PHYSICS %s fallen=%s gutter=%s curve_m=%+.3f settle=%s ticks=%d" % [id, str(summary[id].fallen), str(summary[id].gutter), summary[id].curve_m, summary[id].settle, summary[id].ticks])
	return failures

## Hook grows with spin, mirrors exactly with its sign, and shrinks with speed.
func _hook_relations(summary: Dictionary) -> void:
	var curve := func(id: String) -> float: return summary.get(id, {}).get("curve_m", NAN)
	_check(curve.call("curve_right_25") < curve.call("curve_right_50") and curve.call("curve_right_50") < curve.call("curve_right_100"), "hook grows with spin")
	_check(absf(curve.call("curve_right_50") + curve.call("curve_left_50")) < 1e-4, "hook mirrors exactly with spin sign")
	_check(curve.call("curve_right_50_slow") > curve.call("curve_right_50") and curve.call("curve_right_50") > curve.call("curve_right_50_fast"), "faster throws hook less")
	_check(absf(summary.get("pocket", {}).get("curve_m", 1.0)) < 1e-4, "spin 0 stays straight")

## E18-C13 (E17-L02): the Neon rules and lanes change the roll as written, and only
## when in force (these runs stay out of the digest, which covers the standard lane).
## E18-C14: what a thrown card brings to its own roll (LaneWorld.rules). These runs
## stay out of the digest, like the Neon ones.
## - gutter_rebound: a ball that reaches the gutter edge before any pin is turned back
##   once, and its pinfall counts; a second time it is a gutter ball; a roll that
##   stays on the lane is untouched.
## - oil_hold: the ball meets every lane as House Oil.
## - spin_scale: a modification's hook multiplier, the same arithmetic as Oil Slick's.
func _cards(tree: SceneTree, fixtures: Array) -> void:
	var by := {}
	for fixture in fixtures:
		by[fixture.id] = fixture
	var full: Dictionary = rack_of(by.pocket.rack)
	var rebound := {"gutter_rebound": true}
	# Aimed off the right edge about a third of the way down the lane.
	var stray := launch_of({"start_x": 0.45, "angle_deg": 2.4, "power": 0.6}, "stray")
	# Steep enough to cross the whole lane after the rebound, into the other gutter.
	var wild := launch_of({"start_x": 0.6, "angle_deg": 12.0, "power": 0.5}, "wild")
	await _run_jobs(tree, [
		["c14.stray", full, stray, 0],
		["c14.rebound", full, stray, 0, rebound],
		["c14.rebound#1", full, stray, 0, rebound],
		["c14.wild", full, wild, 0, rebound],
		["c14.on_lane", full, launch_of(by.pocket, "on_lane"), 0, rebound],
		["c14.hold_long", full, launch_of(by.curve_right_50, "hold_long"), 0, {"oil_hold": true}, Lane.LONG_OIL],
		["c14.hold_two_tone", full, launch_of(by.curve_left_50, "hold_tt"), 0, {"oil_hold": true}, Lane.TWO_TONE],
		["c14.spin_half", full, launch_of(by.curve_right_50, "spin_half"), 0, {"spin_scale": 0.5}],
		["c14.spin_more", full, launch_of(by.curve_right_50, "spin_more"), 0, {"spin_scale": 1.3}]])
	var log_of := func(key: String) -> Dictionary: return results.get(key, {}).get("knockdown_log", {})
	var fell := func(key: String) -> int: return results.get(key, {}).get("roll_result", {}).get("fallen_positions", []).size()
	_check(log_of.call("c14.stray").get("gutter") == true and fell.call("c14.stray") == 0 and not log_of.call("c14.stray").has("rebounded"),
		"the stray throw is a gutter ball without a rebound")
	var saved: Dictionary = log_of.call("c14.rebound")
	_check(saved.get("rebounded") == true and saved.get("gutter") == false, "Bumper Guard's rebound turns the stray throw back (it is not a gutter ball)")
	_check(fell.call("c14.rebound") > 0 and saved.get("voided_positions", [0]).is_empty(), "the rebounded ball's pinfall counts (%d down)" % fell.call("c14.rebound"))
	_check(Contracts.validate("knockdown_log", saved).is_empty(), "a rebounded roll's log passes the contract: %s" % str(Contracts.validate("knockdown_log", saved)))
	_check(results.get("c14.rebound", {}).get("final_state") == results.get("c14.rebound#1", {}).get("final_state") and not saved.is_empty(), "a rebounded roll repeats exactly")
	var twice: Dictionary = log_of.call("c14.wild")
	_check(twice.get("rebounded") == true and twice.get("gutter") == true and fell.call("c14.wild") == 0, "it rebounds once: a ball that leaves the lane again is a gutter ball")
	_check(results.get("c14.on_lane", {}).get("final_state") == results.get("pocket#0", {}).get("final_state") and not log_of.call("c14.on_lane").has("rebounded"),
		"a roll that stays on the lane is exactly the roll without the modification")
	_check(results.get("c14.hold_long", {}).get("final_state") == results.get("curve_right_50#0", {}).get("final_state"), "a ball that holds its hook rolls on Long Oil exactly as on House Oil")
	_check(results.get("c14.hold_two_tone", {}).get("final_state") == results.get("curve_left_50#0", {}).get("final_state"), "and on Two-Tone's dry half exactly as on House Oil")
	_check(results.get("c14.spin_half", {}).get("final_state") == results.get("neon.slick", {}).get("final_state") and results.has("c14.spin_half"),
		"a modification's hook scale of 0.5 rolls exactly as Oil Slick's halving")
	_check(curve_of(results.get("c14.spin_more", {})) > curve_of(results.get("curve_right_50#0", {})), "a hook scale above 1 hooks further (%.3f vs %.3f m)" % [
		curve_of(results.get("c14.spin_more", {})), curve_of(results.get("curve_right_50#0", {}))])
	print("PHYSICS cards rebound_down=%d wild_gutter=%s spin_more=%.3f" % [fell.call("c14.rebound"), str(twice.get("gutter")), curve_of(results.get("c14.spin_more", {}))])

func _neon(tree: SceneTree, fixtures: Array) -> void:
	var by := {}
	for fixture in fixtures:
		by[fixture.id] = fixture
	var full: Dictionary = rack_of(by.pocket.rack)
	var narrow := {"gutter_edge": Lane.LANE_HALF_WIDTH - 2 * Lane.BOARD_WIDTH}
	# From near the right edge, drifting out: it crosses the narrowed edge before the
	# deck but would reach the real gutter only past the pit.
	var drift := launch_of({"start_x": 0.69, "angle_deg": 0.4, "power": 0.6}, "drift")
	var strobe_ring := launch_of(by.pocket, "strobe")
	strobe_ring.ring_radius = 0.075
	await _run_jobs(tree, [
		["neon.slick", full, launch_of(by.curve_right_50, "slick"), 0, {"hook_scale": 0.5}],
		["neon.slick#1", full, launch_of(by.curve_right_50, "slick"), 0, {"hook_scale": 0.5}],
		["neon.long_oil", full, launch_of(by.curve_right_50, "long"), 0, {}, Lane.LONG_OIL],
		["neon.two_tone_right", full, launch_of(by.curve_right_50, "tt_right"), 0, {}, Lane.TWO_TONE],
		["neon.two_tone_left", full, launch_of(by.curve_left_50, "tt_left"), 0, {}, Lane.TWO_TONE],
		["neon.drift", rack_of([7]), drift, 0],
		["neon.drift_narrow", rack_of([7]), drift, 0, narrow],
		["neon.strobe", full, strobe_ring, 0, {"zone_scale": 0.5}],
		["neon.strobe_off", full, strobe_ring, 0]])
	var hook := func(key: String) -> float: return curve_of(results.get(key, {})) if results.has(key) else NAN
	var base: float = hook.call("curve_right_50#0")
	var left: float = hook.call("curve_left_50#0")
	_check(hook.call("neon.slick") > 0.0 and hook.call("neon.slick") < base * 0.75, "Oil Slick bends a curve less (%.3f vs %.3f m)" % [hook.call("neon.slick"), base])
	_check(results.get("neon.slick", {}).get("final_state") == results.get("neon.slick#1", {}).get("final_state"), "Oil Slick rolls repeat exactly")
	_check(hook.call("neon.long_oil") > 0.0 and hook.call("neon.long_oil") < base, "Long Oil bends a curve less (%.3f vs %.3f m)" % [hook.call("neon.long_oil"), base])
	_check(results.get("neon.two_tone_right", {}).get("final_state") == results.get("curve_right_50#0", {}).get("final_state"), "Two-Tone leaves a ball on the right half exactly as House Oil")
	_check(hook.call("neon.two_tone_left") < left, "Two-Tone's dry left half hooks a left curve further (%.3f vs %.3f m)" % [hook.call("neon.two_tone_left"), left])
	var free: Dictionary = results.get("neon.drift", {}).get("knockdown_log", {})
	var ruled: Dictionary = results.get("neon.drift_narrow", {})
	_check(free.get("gutter") == false and ruled.get("knockdown_log", {}).get("gutter") == true and ruled.get("roll_result", {}).get("fallen_positions", [1]).is_empty(),
		"Narrow Lane makes a ball crossing its edge a gutter ball (it is not one on the standard lane)")
	_check(not ruled.is_empty() and absf(float(ruled.final_state.ball[0])) > Lane.LANE_HALF_WIDTH, "the rail carries a Narrow Lane gutter ball into the gutter")
	for key in ["neon.strobe", "neon.strobe_off"]:
		var r: Dictionary = results.get(key, {})
		var scale := 0.5 if key == "neon.strobe" else 1.0
		_check(not r.is_empty() and r.roll_result.accuracy == Lane.grade_accuracy(r.knockdown_log.target_crossed, r.knockdown_log.target_offset - r.launch.target_x, r.launch.ring_radius, scale),
			"%s grades with zone scale %.1f" % [key, scale])
	print("PHYSICS neon slick=%.3f long_oil=%.3f base=%.3f two_tone_left=%.3f left=%.3f strobe=%s off=%s" % [hook.call("neon.slick"), hook.call("neon.long_oil"), base, hook.call("neon.two_tone_left"), left,
		results.get("neon.strobe", {}).get("roll_result", {}).get("accuracy"), results.get("neon.strobe_off", {}).get("roll_result", {}).get("accuracy")])

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
	if expect.has("curve"):
		var hook := curve_of(report)
		_check(report.knockdown_log.target_crossed and hook >= float(expect.curve[0]) and hook <= float(expect.curve[1]), "%s hook %.3f m outside %s" % [id, hook, str(expect.curve)])
	if expect.has("gutter"):
		_check(report.knockdown_log.gutter == expect.gutter, "%s gutter=%s" % [id, str(expect.gutter)])
	for knockdown in report.knockdown_log.knockdowns:
		_check(knockdown.cause != "environment", "%s pin %d fell without a recorded cause" % [id, knockdown.position])
