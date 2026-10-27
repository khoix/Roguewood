extends SceneTree
## J02 throw journey (E04 straight, E05 curve/controls). Drives the real shell and
## throw lab through Input.parse_input_event touch, drag, mouse and focused-control
## actions; no lab callbacks are invoked directly. Run with --fixed-fps 60 for
## deterministic time.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const LaneWorld = preload("res://src/simulation/lane_world.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Ring = preload("res://src/input/target_ring.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
const LANDSCAPE := Vector2i(800, 450)
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control
var lab: Control
var trials_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func _wait_for(predicate: Callable, label: String, frames: int = 240) -> bool:
	for i in frames:
		if predicate.call():
			return true
		await process_frame
	if predicate.call():
		return true
	_check(false, "Timeout: " + label)
	return false

func _capture(label: String) -> void:
	var lab_state: String = lab.state if lab else "-"
	print("J02 %s screen=%s lab=%s frame=%s roll=%s cancels=%s" % [label, scene.screen, lab_state, lab.frame_number if lab else 0, lab.roll_index if lab else 0, lab.cancels if lab else 0])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_check(false, "No rendered image: " + label)
	elif image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot save screenshot: " + label)

func _accept() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = "ui_accept"
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

## Canvas position -> window position; the viewport maps it back on delivery.
func _window(canvas: Vector2) -> Vector2:
	return root.get_screen_transform() * canvas

func _touch(canvas: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = _window(canvas)
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	await process_frame

func _drag(canvas: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = _window(canvas)
	event.relative = relative
	Input.parse_input_event(event)
	await process_frame

## Holds the ball, slides sideways, then flicks along step; returns the release point.
func _gesture(slide: Vector2, slide_frames: int, step: Vector2, step_frames: int, release: bool = true) -> Vector2:
	var at: Vector2 = lab.ball_screen_position()
	await _touch(at, true)
	for i in slide_frames:
		at += slide / slide_frames
		await _drag(at, slide / slide_frames)
	for i in step_frames:
		at += step
		await _drag(at, step)
	if release:
		await _touch(at, false)
	return at

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	# Device profile: phone portrait (450x800 window -> 720x1280 canvas) in both
	# headless and rendered runs, so the same gestures mean the same thing.
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _accept()
	await _wait_for(func(): return scene.screen == "session" and scene.lab != null, "session with throw lab")
	lab = scene.lab
	# Fixture: keep the device-trial log as evidence instead of in user://.
	trials_path = artifact_dir.path_join("trials.jsonl") if not artifact_dir.is_empty() else ""
	if not trials_path.is_empty():
		DirAccess.remove_absolute(trials_path)
	lab.trial_log_path = trials_path
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim state")
	for i in 3: await process_frame
	await _capture("aim")
	var lane_before: Node = lab.lane
	var ball_home: Vector3 = lab.lane.ball_position()
	await _cancellations(lane_before, ball_home)
	var frame := await _two_roll_frame()
	await _gutter_frame()
	await _replays(frame)
	await _curves_and_target()
	await _mouse_throw()
	await _assist_throw()
	await _landscape_throw()
	_check_trial_log()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty(): await _capture("failure")
	if failures.is_empty(): print("ROGUEWOOD_J02_OK")
	quit(0 if failures.is_empty() else 1)

func _cancellations(lane_before: Node, ball_home: Vector3) -> void:
	# Sideways placement released without a flick.
	await _gesture(Vector2(90, 0), 6, Vector2.ZERO, 0, false)
	_check(lab.state == "holding", "touch on ball starts hold")
	_check(lab.lane.ball_position().x > ball_home.x + 0.05, "ball follows sideways drag")
	await _touch(lab.ball_screen_position(), false)
	_check(lab.state == "aim" and lab.cancels == 1 and lab.last_cancel == "short", "sideways-only release cancels")
	# Slow upward drag, then an OS-cancelled touch.
	await _gesture(Vector2.ZERO, 0, Vector2(0, -8), 30)
	_check(lab.cancels == 2 and lab.last_cancel == "slow", "slow drag cancels")
	await _gesture(Vector2.ZERO, 0, Vector2(0, -40), 3, false)
	await _touch(lab.ball_screen_position(), false, true)
	_check(lab.cancels == 3 and lab.last_cancel == "touch_canceled", "OS touch cancel cancels")
	# Touching the lane away from the ball moves the target and never throws.
	var target_before: float = lab.target_x
	await _touch(Vector2(60, 400), true)
	await _touch(Vector2(60, 300), false)
	_check(lab.state == "aim" and lab.cancels == 3 and lab.history.is_empty(), "touch off the ball does not throw")
	_check(lab.target_x < target_before, "tap on the lane moves the target")
	_check(lab.lane == lane_before and lab.lane.state == "ready" and lab.lane.launch.is_empty(), "cancellations consume no launch")
	_check(lab.history.is_empty() and lab.roll_index == 1 and lab.frame_number == 1, "cancellations consume no roll")
	_check(lab.lane.ball_position().is_equal_approx(ball_home), "ball returned after cancel")
	await _capture("cancelled")

## Throws until a frame needs a second roll (a strike ends a frame at once).
func _two_roll_frame() -> Array:
	for attempt in 3:
		var launch_index: int = lab.history.size()
		await _gesture(Vector2(attempt * 24, 0), 4, Vector2(0, -32), 8)
		_check(lab.state == "rolling", "straight flick commits a roll")
		var launch: Dictionary = lab.lane.launch.duplicate(true)
		_check(launch.launch_id == "lab-%d" % (launch_index + 1), "launch ids ignore cancelled gestures")
		_check(launch.roll_index == 1 and launch.spin == 0.0 and launch.direction_x == 0.0, "straight first-roll launch")
		for i in 40: await process_frame
		await _capture("rolling")
		if not await _wait_for(func(): return lab.state == "result", "roll 1 settles", ROLL_FRAMES): return []
		await _capture("roll1")
		var first: Dictionary = lab.history[-1]
		_check_report(first, Lane.fresh_rack())
		_check(not first.knockdown_log.gutter and not first.roll_result.fallen_positions.is_empty(), "straight throw reaches the rack")
		if first.knockdown_log.standing.is_empty():
			await _wait_for(func(): return lab.state == "frame_done", "strike ends frame", ROLL_FRAMES)
			_check(lab.roll_index == 1, "strike has no second roll")
			await _accept()
			continue
		await _wait_for(func(): return lab.state == "aim" and lab.roll_index == 2, "second roll ready")
		var racked: Array = lab.lane.pins.keys()
		racked.sort()
		_check(racked == first.knockdown_log.standing, "only survivors respotted for roll 2")
		_check(not lab.status.text.contains("No throw"), "committed throw clears the cancel note")
		await _capture("roll2_aim")
		# Line up on the lowest standing pin using the lab's own camera projection.
		var target: int = first.knockdown_log.standing[0]
		var aim: Vector2 = lab.get_global_transform() * lab._screen(Lane.world(Lane.spot(target).x, Lane.BALL_START_F, Lane.BALL_RADIUS))
		await _gesture(Vector2(aim.x - lab.ball_screen_position().x, 0), 4, Vector2(0, -32), 8)
		_check(lab.state == "rolling" and lab.lane.launch.roll_index == 2, "second roll commits")
		if not await _wait_for(func(): return lab.state == "result", "roll 2 settles", ROLL_FRAMES): return []
		var second: Dictionary = lab.history[-1]
		_check_report(second, first.rack_after)
		for position in second.roll_result.fallen_positions:
			_check(position in first.knockdown_log.standing and position not in first.roll_result.fallen_positions, "no pin credited in both rolls")
		var wood: Array = []
		for position in range(1, 11):
			wood.append({"position": position, "item_id": "pin.wood", "effects": []})
		var rolls: Array = []
		for report in [first, second]:
			rolls.append(report.roll_result.duplicate(true).merged({"effects": []}))
		for roll in rolls:
			roll.erase("schema_version")
			roll.erase("launch_id")
		var frame := {"schema_version": 1, "pins": wood, "rolls": rolls, "charms": []}
		_check(Rules.validate(frame).is_empty(), "two-roll frame accepted by E02 frame rules")
		await _wait_for(func(): return lab.state == "frame_done", "frame completes", ROLL_FRAMES)
		await _capture("frame")
		return [first, second]
	_check(false, "three consecutive strikes; second roll not exercised")
	return []

func _gutter_frame() -> void:
	if lab.state == "frame_done":
		await _accept()
	await _wait_for(func(): return lab.state == "aim" and lab.roll_index == 1 and lab.lane.pins.size() == 10, "fresh rack after Next Rack")
	await _gesture(Vector2(260, 0), 6, Vector2(10, -30), 8)
	_check(lab.state == "rolling" and lab.lane.launch.direction_x > 0.0, "angled flick commits")
	if not await _wait_for(func(): return lab.state == "result", "gutter roll settles", ROLL_FRAMES): return
	await _capture("gutter")
	var report: Dictionary = lab.history[-1]
	_check_report(report, Lane.fresh_rack())
	_check(report.knockdown_log.gutter and report.roll_result.fallen_positions.is_empty(), "gutter ball credits no pinfall")
	_check(report.rack_after.standing.size() == 10, "gutter respots the full rack")
	await _wait_for(func(): return lab.state == "aim" and lab.roll_index == 2 and lab.lane.pins.size() == 10, "roll 2 after gutter keeps ten pins")

## Committed records replay to identical outcomes in fresh worlds (E10 basis).
func _replays(frame: Array) -> void:
	if frame.is_empty(): return
	var racks: Array = [Lane.fresh_rack(), JSON.parse_string(JSON.stringify(frame[0].rack_after, "", true, true))]
	for index in 2:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		root.add_child(viewport)
		var world: Node3D = LaneWorld.new()
		viewport.add_child(world)
		world.setup(racks[index])
		_check(world.commit(frame[index].launch).is_empty(), "replay launch accepted")
		await _wait_for(func(): return world.state == "finished", "replay settles", ROLL_FRAMES)
		for key in ["roll_result", "knockdown_log", "final_state", "rack_after"]:
			_check(world.report.get(key) == frame[index][key], "replay roll %d identical %s" % [index + 1, key])
		viewport.queue_free()
	print("J02 replay rolls=2 checked")

func _check_report(report: Dictionary, rack_in: Dictionary) -> void:
	_check(Contracts.validate_result_for_launch(report.launch, report.roll_result).is_empty(), "result matches launch contract")
	_check(Contracts.validate_log_for_result(report.roll_result, report.knockdown_log).is_empty(), "knockdown log matches result")
	var racked: Array = rack_in.standing.map(func(entry): return int(entry.position))
	var accounted: Array = report.roll_result.fallen_positions + report.knockdown_log.standing
	accounted.sort()
	racked.sort()
	_check(accounted == racked, "every racked pin is either credited once or standing")
	_check(report.rack_after.standing.map(func(entry): return int(entry.position)) == report.knockdown_log.standing, "rack after matches standing")
	print("J02 report launch=%s roll=%d fallen=%s standing=%s gutter=%s accuracy=%s settle=%s ticks=%d" % [report.launch.launch_id, report.launch.roll_index,
		str(report.roll_result.fallen_positions), str(report.knockdown_log.standing), str(report.knockdown_log.gutter), report.roll_result.accuracy,
		report.knockdown_log.settle, report.knockdown_log.ticks])

## Waits for the next throwable aim state, pressing Next Rack when a frame is done
## and Next Match in the shop.
func _ready_to_throw() -> void:
	await _wait_for(func(): return lab.state in ["aim", "frame_done"], "aim or frame done", ROLL_FRAMES)
	if lab.state == "frame_done":
		lab.next_rack.grab_focus()
		await _accept()
	if lab.state == "shop": # match end (E08): leave the Pro Shop without buying
		lab.shop_panel.continue_button.grab_focus()
		await _accept()
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim before throw")

## Holds the ball, circles sweep_deg (clockwise positive on screen) starting at the
## circle's bottom (the ball), then flicks straight up. Captures mid-hold if asked.
func _circle_throw(sweep_deg: float, hold_capture: String = "") -> void:
	var radius := 60.0
	var at: Vector2 = lab.ball_screen_position()
	var center := at + Vector2(0.0, -radius)
	await _touch(at, true)
	for i in int(absf(sweep_deg) / 10.0):
		var angle := deg_to_rad(90.0 + signf(sweep_deg) * 10.0 * (i + 1))
		var next := center + Vector2(cos(angle), sin(angle)) * radius
		await _drag(next, next - at)
		at = next
	if not hold_capture.is_empty():
		await _capture(hold_capture)
	for i in 8:
		at += Vector2(0, -32)
		await _drag(at, Vector2(0, -32))
	await _touch(at, false)

func _await_result(label: String) -> Dictionary:
	if not await _wait_for(func(): return lab.state == "result", label + " settles", ROLL_FRAMES):
		return {}
	var report: Dictionary = lab.history[-1]
	_check_report(report, lab.rack)
	var crossed: bool = report.knockdown_log.target_crossed
	var grade := Lane.grade_accuracy(crossed, report.knockdown_log.target_offset - report.launch.target_x, report.launch.ring_radius)
	_check(grade == report.roll_result.accuracy, label + " accuracy uses the frozen ring and target")
	return report

func _curves_and_target() -> void:
	await _ready_to_throw()
	# Move the target to just right of the head pin by tapping the lane there.
	var pocket := 0.08
	var tap: Vector2 = lab.get_global_transform() * lab.screen_point(Lane.world(pocket, Lane.TARGET_PLANE_F, 0.0))
	await _touch(tap, true)
	await _touch(tap, false)
	_check(absf(lab.target_x - pocket / Lane.LANE_HALF_WIDTH) < 0.01, "tap moves the target ring under the finger")
	await _capture("target")
	# Short flick: too little travel to throw.
	var cancels: int = lab.cancels
	await _gesture(Vector2.ZERO, 0, Vector2(0, -6), 3)
	_check(lab.cancels == cancels + 1 and lab.last_cancel == "short", "short flick cancels")
	for sweep in [450.0, -450.0]:
		await _ready_to_throw()
		var label := "curve_right" if sweep > 0.0 else "curve_left"
		await _circle_throw(sweep, label + "_hold" if sweep > 0.0 else "")
		_check(lab.state == "rolling", label + " commits")
		var launch: Dictionary = lab.lane.launch
		_check(signf(launch.spin) == signf(sweep) and Lane.is_curved(launch.spin) and absf(absf(launch.spin) - 450.0 / 720.0) < 0.05, label + " gesture charges matching spin")
		_check(absf(launch.direction_x) < 0.01, label + " circle does not steer the flick")
		_check(absf(launch.target_x - pocket / Lane.LANE_HALF_WIDTH) < 0.01, label + " launch carries the moved target")
		_check(launch.ring_radius < Ring.RING_MAX and launch.ring_radius >= Ring.RING_MIN, label + " ring contracted while held and froze at release")
		for i in 50: await process_frame
		await _capture(label)
		var report := await _await_result(label)
		if report.is_empty(): return
		var hook := Lane.hook_at_target(report.launch, report.knockdown_log)
		_check(not is_nan(hook) and signf(hook) == signf(sweep) and absf(hook) > 0.05, "%s hooks %+.3f m the matching way" % [label, hook])
		print("J02 %s spin=%+.3f hook_m=%+.3f ring=%.3f accuracy=%s fallen=%s" % [label, launch.spin, hook, launch.ring_radius, report.roll_result.accuracy, str(report.roll_result.fallen_positions)])

func _mouse_button(canvas: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = _window(canvas)
	event.global_position = event.position
	Input.parse_input_event(event)
	await process_frame

func _mouse_move(canvas: Vector2, relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = _window(canvas)
	event.global_position = event.position
	event.relative = relative
	Input.parse_input_event(event)
	await process_frame

## A desktop mouse drives the same gesture through touch emulation.
func _mouse_throw() -> void:
	await _ready_to_throw()
	var at: Vector2 = lab.ball_screen_position()
	await _mouse_button(at, true)
	_check(lab.state == "holding", "mouse press on the ball holds it")
	for i in 8:
		at += Vector2(0, -32)
		await _mouse_move(at, Vector2(0, -32))
	await _mouse_button(at, false)
	_check(lab.state == "rolling" and lab.last_source == "mouse", "mouse flick commits a throw")
	await _await_result("mouse")

func _focus_accept(control: Control) -> void:
	control.grab_focus()
	await _accept()

func _ui(action: String, times: int) -> void:
	for i in times:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame

## Settings through focused controls, then a throw with no gesture at all.
func _assist_throw() -> void:
	await _ready_to_throw()
	await _focus_accept(scene.options)
	_check(lab.settings_panel.visible, "Options opens throw settings")
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	_check(lab.settings.reduced_motion and lab.settings.assist and lab.assist_panel.visible, "settings toggle reduced motion and assist controls")
	await _focus_accept(lab.settings_panel.close)
	_check(not lab.settings_panel.visible, "settings close")
	var panel: Control = lab.assist_panel
	panel.spin_slider.grab_focus()
	await _ui("ui_right", 2)
	panel.position_slider.grab_focus()
	await _ui("ui_left", 4)
	panel.aim_slider.grab_focus()
	await _ui("ui_right", 1)
	var controls: Dictionary = panel.values()
	_check(controls.spin == 0.5 and absf(controls.start_x + 0.2) < 1e-6 and controls.angle_deg == 0.25, "keyboard adjusts assist sliders")
	_check(absf(lab.lane.ball_position().x + 0.2 * Lane.LANE_HALF_WIDTH) < 1e-4, "assist position previews the ball")
	await _capture("assist")
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling" and lab.last_source == "assist", "assist Throw commits")
	var expected := Mapper.from_controls(controls, lab.lane.launch.launch_id, lab.lane.launch.roll_index, controls.target_x, Ring.RING_MAX)
	_check(lab.lane.launch == expected, "assist launch equals the gesture-equivalent record (steady ring under reduced motion)")
	var report := await _await_result("assist")
	if not report.is_empty():
		_check(Lane.hook_at_target(report.launch, report.knockdown_log) > 0.05, "assist spin hooks right")
	# Back to gestures for the remaining checks.
	await _ready_to_throw()
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	_check(not lab.settings.assist and not lab.assist_panel.visible, "assist controls turn off")

## Rotating to landscape keeps hit-testing and gesture units correct.
func _landscape_throw() -> void:
	await _ready_to_throw()
	root.size = LANDSCAPE
	for i in 4: await process_frame
	_check(lab.size.x > lab.size.y, "lab fills a landscape viewport")
	var at: Vector2 = lab.ball_screen_position()
	_check(Rect2(Vector2.ZERO, lab.size).has_point(at - lab.get_global_transform().origin), "ball visible after resize")
	await _gesture(Vector2.ZERO, 0, Vector2(0, -40), 8)
	_check(lab.state == "rolling" and lab.lane.launch.power > 0.0, "flick works after resize")
	for i in 30: await process_frame
	await _capture("landscape")
	await _await_result("landscape")
	root.size = PORTRAIT
	for i in 4: await process_frame
	_check(lab.size.y > lab.size.x, "back to portrait")

func _check_trial_log() -> void:
	_check(lab.trials.size() == lab.history.size(), "one trial entry per committed roll")
	if trials_path.is_empty():
		return
	var lines := FileAccess.get_file_as_string(trials_path).strip_edges().split("\n")
	_check(lines.size() == lab.history.size(), "trial log file has one line per roll")
	var sources := {}
	for line in lines:
		var entry = JSON.parse_string(line)
		_check(entry is Dictionary and entry.has("launch") and entry.has("input") and entry.has("fallen"), "trial log line is a complete record")
		if entry is Dictionary:
			sources[entry.input.get("source", "?")] = true
	for source in ["touch", "mouse", "assist"]:
		_check(sources.has(source), "trial log records %s throws" % source)
	print("J02 trials=%d sources=%s" % [lines.size(), str(sources.keys())])
