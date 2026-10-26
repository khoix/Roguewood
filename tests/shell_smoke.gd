extends SceneTree
## Drives focused native buttons through InputEventAction; no direct callbacks.
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control

func _wait_for(predicate: Callable, label: String) -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not predicate.call(): failures.append("Timeout: " + label)

func _capture(label: String) -> void:
	print("J01 " + label + " screen=" + scene.screen + " state=" + JSON.stringify(scene.session))
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("No rendered image: " + label)
	elif image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		failures.append("Cannot save screenshot: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _accept() -> void:
	var event := InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _capture("menu")
	if scene.screen != "menu" or not scene.enter.has_focus(): failures.append("menu missing or Enter League unfocused")
	await _accept()
	await _wait_for(func(): return scene.screen == "session", "session entry")
	await _capture("session")
	if scene.session.get("kit_id") != "kit.house": failures.append("kit fixture missing")
	if scene.screen != "session": failures.append("Enter League input did not open session")
	var initial: Dictionary = scene.session.duplicate(true)
	if initial.get("score") != 0 or initial.get("division") != 1: failures.append("invalid session fixture")
	scene.session.score = 999 # Seed changed state; the reset action itself uses real input.
	await _accept()
	await _wait_for(func(): return scene.session == initial, "reset")
	await _capture("reset")
	if scene.session != initial: failures.append("restart input did not reset deterministically")
	scene.back.grab_focus()
	await _accept()
	await _wait_for(func(): return scene.screen == "menu", "return")
	await _capture("returned")
	if "--inject-failure" in OS.get_cmdline_user_args(): failures.append("Injected diagnostic failure")
	if scene.screen != "menu" or not scene.session.is_empty(): failures.append("Clubhouse input did not clear session")
	if not failures.is_empty(): await _capture("failure")
	for failure in failures: printerr("FAIL: " + failure)
	if failures.is_empty(): print("ROGUEWOOD_SHELL_OK")
	quit(0 if failures.is_empty() else 1)
