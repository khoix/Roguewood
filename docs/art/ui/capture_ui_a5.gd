extends SceneTree
## Reproducible UI-A5 art review: actual shell, motion frames and input contracts.
## Run with --fixed-fps 60 --path . --script res://docs/art/ui/capture_ui_a5.gd
## -- --artifact-dir=<ignored-output> [--landscape]. Does not join the test shard.
var out := "res://artifacts/ui-a5/title"
var scene: Control
var failures: Array[String] = []
var emitted := 0
var timeline: Array = []
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func _frames(n: int) -> void:
	for i in n: await process_frame
func _capture(label: String) -> Image:
	if DisplayServer.get_name() == "headless": return null
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	_check(im.save_png(out.path_join(label + ".png")) == OK, "capture " + label)
	return im
func _reset(reduced: bool) -> void:
	scene.screen = "title"
	scene.title.open(reduced)
func _input(mode: String) -> void:
	for down in [true, false]:
		var event: InputEvent
		if mode == "touch":
			var touch := InputEventScreenTouch.new(); touch.index = 0
			touch.position = root.get_screen_transform() * scene.title.start.get_global_rect().get_center()
			touch.pressed = down; event = touch
		elif mode == "mouse":
			var mouse := InputEventMouseButton.new(); mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.position = root.get_screen_transform() * scene.title.start.get_global_rect().get_center()
			mouse.pressed = down; event = mouse
		elif mode == "gamepad":
			var pad := InputEventJoypadButton.new(); pad.button_index = JOY_BUTTON_Y
			pad.pressed = down; event = pad
		else:
			var key := InputEventKey.new(); key.keycode = KEY_Q
			key.pressed = down; event = key
		Input.parse_input_event(event)
		await process_frame
func _run() -> void:
	var landscape := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): out = arg.trim_prefix("--artifact-dir=")
		if arg == "--landscape": landscape = true
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(780, 360) if landscape else Vector2i(360, 780)
	change_scene_to_file("res://src/bootstrap/bootstrap.tscn")
	await _frames(3)
	scene = current_scene
	_check(scene.screen == "title" and scene.title.start.has_focus(), "real shell starts at title")
	scene.title.started.connect(func(): emitted += 1)
	var title_nodes: int = scene.title.get_child_count()
	var prompt_min := 1.0
	_reset(false)
	for i in 60:
		while scene.title._clock < float(i) / 12.0: await process_frame
		await _capture("motion_%03d" % i)
		prompt_min = minf(prompt_min, scene.title.prompt.modulate.a)
		timeline.append({"frame":i, "seconds":scene.title._clock})
	_check(prompt_min >= 0.79, "prompt remains legible throughout sampled idle")
	# One tap is acknowledged at once and still finishes inside the original fade.
	_reset(false)
	await _input("touch")
	_check(scene.title._leaving, "first touch accepted during entrance")
	await _capture("tap_acknowledged")
	await _frames(4)
	await _capture("tap_beat")
	await _frames(7)
	await _capture("tap_fade")
	await _frames(10)
	_check(scene.screen == "menu" and not scene.title.visible and emitted == 1, "single start finishes without extra wait")
	# Reduced motion: processing stops and actual rendered pixels stay identical.
	_reset(true)
	await _frames(3)
	var a := await _capture("reduced_early")
	var before: Vector2 = scene.title.ball.position
	await _frames(90)
	var b := await _capture("reduced_late")
	_check(not scene.title.is_processing() and scene.title.ball.rotation == 0 and scene.title.ball.position == before, "reduced motion is fully still")
	if a != null and b != null: _check(a.get_data() == b.get_data(), "reduced screenshots pixel-identical")
	for mode in ["touch", "mouse", "key", "gamepad"]:
		_reset(true)
		await _frames(1)
		var count := emitted
		await _input(mode)
		_check(scene.screen == "menu" and emitted == count + 1 and not scene.title.visible, "immediate reduced " + mode)
	# Reopening cancels an old exit rather than emitting a late duplicate start.
	_reset(false); await _input("key")
	var count := emitted
	_reset(true); await _frames(30)
	_check(scene.title.visible and emitted == count, "reopen cancels prior fade")
	root.size = Vector2i(360,780) if landscape else Vector2i(780,360)
	await _frames(5)
	_check(scene.title.ball.position == scene.title._ball_origin and scene.title.logo.scale == Vector2.ONE, "reduced resize keeps final layout")
	_check(scene.title.get_child_count() == title_nodes, "repeated opens allocate no extra title nodes")
	await _capture("reduced_rotated")
	FileAccess.open(out.path_join("review.json"), FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"timeline":timeline,"started_signals":emitted}, " "))
	for failure in failures: printerr("FAIL: ", failure)
	if failures.is_empty(): print("ROGUEWOOD_UI_A5_REVIEW_OK")
	scene.queue_free(); await _frames(3)
	quit(0 if failures.is_empty() else 1)
