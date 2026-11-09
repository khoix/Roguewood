extends "res://tests/throw_journey.gd"
## AV-T01: real touch input at phone size; no synthetic charge assignments.
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = Vector2i(540, 960)
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu")
	await _accept()
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "lab")
	lab = scene.lab
	lab.throw_cue.connect(func(id, charge): cues.append([id, charge]))
	for view in ["depth", "flat"]:
		for reduction in ["normal", "motion", "flash"]:
			lab.settings.spin_view = view
			lab.settings.reduced_motion = reduction == "motion"
			lab.settings.reduced_flash = reduction == "flash"
			await _hold_states(view + "_" + reduction)
	# Select the existing slice boss as an art fixture, then drive the hold normally.
	lab.division.active.match_index = 2
	_check(lab.spin_disabled(), "fixture has Dead Straight")
	cues.clear()
	var at: Vector2 = lab.ball_screen_position()
	await _touch(at, true)
	for i in 90:
		var next := at + Vector2.from_angle(i * TAU / 12) * 2
		await _drag(next, next-at)
		at = next
	_check(lab.get_node("AimOverlay").charge_pose().state == "disabled" and cues.is_empty(), "Dead Straight has no lit charge or sounds")
	await _capture("disabled")
	await _touch(at, false, true)
	var sound: Node = lab.get_node("MotionDirector/PresentationAudio")
	var before: int = sound.played
	sound.mute_button.button_pressed = true
	lab.throw_cue.emit("throw.full_charge", 1.0)
	_check(sound.played == before, "Sound & effects mute suppresses throw sound")
	sound.mute_button.button_pressed = false
	sound.volume_slider.value = 0.0
	lab.throw_cue.emit("throw.curve_ready", 0.5)
	_check(sound.played == before, "zero volume suppresses throw sound")
	_check(before > 0, "real held input played presentation sounds")
	if failures.is_empty(): print("ROGUEWOOD_THROW_CHARGE_ART_OK")
	quit(0 if failures.is_empty() else 1)

func _hold_states(label: String) -> void:
	cues.clear()
	var at: Vector2 = lab.ball_screen_position()
	await _touch(at, true)
	_check(lab.state == "holding", "real touch holds the ball")
	var overlay: Control = lab.get_node("AimOverlay")
	_check(overlay.charge_pose().state == "charging", "dim charging collar")
	await _capture(label + "_charging")
	var center := at + Vector2(0,-30)
	var angle := PI/2
	var captured := {}
	for i in 180:
		# Ramp from gentle to brisk, then keep swirling after full charge.
		angle += TAU * (1.5 if i < 60 else 5.0) / 60.0
		var next := center + Vector2.from_angle(angle) * 30
		await _drag(next, next-at)
		at = next
		var pose: Dictionary = overlay.charge_pose()
		_check((overlay.get_global_transform() * pose.center).distance_to(lab.ball_screen_position()) < 0.01, "effect tracks screen ball")
		_check(absf(pose.radius - lab._ball_screen_radius()) < 0.01, "effect uses rendered radius")
		_check(pose.reduced == (lab.settings.reduced_motion or lab.settings.reduced_flash), "either reduction freezes decoration")
		if pose.state in ["ready", "full"] and not captured.has(pose.state):
			captured[pose.state] = true
			await _capture(label + "_" + pose.state)
	_check(captured.has("ready") and captured.has("full"), label + " reaches both charge levels")
	for id in ["throw.charge", "throw.curve_ready", "throw.full_charge"]:
		_check(cues.filter(func(c): return c[0] == id).size() == 1, label + " once per hold: " + id)
	await _touch(at, false, true)
	_check(lab.state == "aim", "cancel returns to aim")
