extends SceneTree
## J03 scoring journey (E06): strike, spare and open frames played through real
## input (focused Options toggles, keyboard steps on the assist sliders and Throw),
## then checked against an independent FrameRules resolution: banked score, ordered
## calculation log, per-roll pin attribution, speed and skip, and running totals.
## Assist steps and reduced motion (steady clean-only ring) make every launch exact;
## the outcomes come from the deterministic physics. Run with --fixed-fps 60.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const FrameBuilder = preload("res://src/rules/frame_builder.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control
var lab: Control
var running_total := 0

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
	print("J03 %s lab=%s frame=%d total=%d" % [label, lab.state if lab else "-", lab.frame_number if lab else 0, lab.total_score if lab else 0])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

func _action(action: String, times: int = 1) -> void:
	for i in times:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame

func _focus_accept(control: Control) -> void:
	control.grab_focus()
	await _action("ui_accept")

## Moves a focused slider to value with ui_left/ui_right presses only.
func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	await _action("ui_right" if steps > 0 else "ui_left", absi(steps))
	_check(is_equal_approx(slider.value, value), "%s reached %.2f" % [slider.name, value])

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "throw lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	_check(lab.settings.assist and lab.settings.reduced_motion, "assist and reduced motion on")
	await _strike_frame()
	await _spare_frame()
	await _open_frame()
	_check(scene.session.score == running_total and scene.session.frame == 4, "session fixture tracks banked total and frame")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty(): await _capture("failure")
	if failures.is_empty(): print("ROGUEWOOD_J03_OK")
	quit(0 if failures.is_empty() else 1)

func _throw(position: float, aim: float, power: float) -> Dictionary:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim before throw", ROLL_FRAMES)
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, position)
	await _slide(panel.aim_slider, aim)
	await _slide(panel.power_slider, power)
	await _slide(panel.spin_slider, 0.0)
	var count: int = lab.history.size()
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling", "Throw commits")
	await _wait_for(func(): return lab.history.size() == count + 1, "roll settles", ROLL_FRAMES)
	var report: Dictionary = lab.history[-1]
	print("J03 roll launch=%s fallen=%s standing=%s accuracy=%s" % [report.launch.launch_id, str(report.roll_result.fallen_positions), str(report.knockdown_log.standing), report.roll_result.accuracy])
	return report

## Waits for scoring, then checks it against an independent resolution.
func _verify_frame(category: String, label: String, during: Callable = Callable()) -> void:
	await _wait_for(func(): return lab.state == "scoring", label + " scoring starts", ROLL_FRAMES)
	if during.is_valid():
		await during.call()
	await _wait_for(func(): return lab.state == "frame_done", label + " scoring finishes", ROLL_FRAMES)
	var reports: Array = lab.frame_reports
	var built: Dictionary = FrameBuilder.build(FrameBuilder.lab_loadout(), Contracts.read_json(FrameBuilder.LAB_CATALOGUE), reports)
	_check(built.ok, label + " frame builds from the roll reports")
	if not built.ok: return
	var expected: Dictionary = Rules.resolve(built.frame)
	var panel: Control = lab.score_panel
	var shown: Dictionary = panel.displayed()
	_check(expected.category == category, "%s is a %s (got %s)" % [label, category, expected.category])
	_check(shown.score == expected.score and int(lab.scored_frames[-1].result.score) == expected.score, "%s panel banks the resolver's score %d" % [label, expected.score])
	var fallen: int = 0
	for report in reports:
		fallen += report.roll_result.fallen_positions.size()
	var base: Array = {"strike": [40, 4], "spare": [20, 2], "open": [0, 1]}[category]
	_check(expected.score == (base[0] + 10 * fallen) * base[1], "%s base score is (%d + 10×%d) × %d" % [label, base[0], fallen, base[1]])
	var lines: Array = panel.log_list.get_children().map(func(child): return child.text)
	_check(lines.size() == panel.steps.size() and lines[0].contains(category.capitalize()) and lines[-1].contains("Bank") and lines[-1].ends_with("= %d" % expected.score), label + " log opens with category and ends with the bank")
	var pins: Array = panel.steps.filter(func(step): return step.pin > 0).map(func(step): return step.pin)
	var sorted_pins := pins.duplicate()
	sorted_pins.sort()
	_check(pins == sorted_pins and pins.size() == fallen, label + " log credits each fallen pin once in rack order")
	_check(lines.filter(func(text): return text.contains("Accuracy")).size() == 1, label + " one accuracy award")
	for report in reports:
		for position in report.roll_result.fallen_positions:
			_check(panel._roll_of.get(int(position)) == int(report.roll_result.roll_index), "%s rack shows pin %d taken by roll %d" % [label, position, report.roll_result.roll_index])
	running_total += expected.score
	_check(lab.total_score == running_total and lab.status.text.contains("Total %d" % running_total), label + " running total")
	print("J03 %s score=%d category=%s steps=%d total=%d" % [label, expected.score, expected.category, lines.size(), running_total])

func _next_frame() -> void:
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "aim" and lab.roll_index == 1, "next rack", ROLL_FRAMES)

func _strike_frame() -> void:
	await _throw(0.1, 0.0, 0.7)
	await _verify_frame("strike", "strike", func():
		for i in 20: await process_frame
		await _capture("scoring")
		var panel: Control = lab.score_panel
		_check(panel.playing and panel.displayed().score == -1, "score counts up step by step before banking")
		await _focus_accept(panel.speed_button)
		await _focus_accept(panel.speed_button)
		_check(panel.speed == 4 and lab.settings.score_speed == 4, "speed cycles to 4× and is kept"))
	await _capture("strike")
	await _next_frame()

func _spare_frame() -> void:
	await _throw(-0.4, 0.0, 0.6)
	await _throw(0.0, 0.0, 0.6)
	await _verify_frame("spare", "spare", func():
		var panel: Control = lab.score_panel
		_check(panel.speed == 4, "speed preference carries to the next frame")
		await _focus_accept(panel.skip_button)
		_check(not panel.playing, "Skip reveals the whole calculation"))
	await _capture("spare")
	await _next_frame()

func _open_frame() -> void:
	await _throw(-0.4, 0.0, 0.6)
	var gutter: Dictionary = await _throw(0.8, 2.0, 0.6)
	_check(gutter.knockdown_log.gutter, "second roll is a gutter ball")
	await _verify_frame("open", "open")
	await _capture("open")
