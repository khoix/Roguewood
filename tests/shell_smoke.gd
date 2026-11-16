extends SceneTree
## Drives focused native buttons through InputEventAction; no direct callbacks.
## UI-7: the game is started as the engine starts it (the shell becomes the current
## scene), so the title screen comes first and is passed with real input.
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
	change_scene_to_file("res://src/bootstrap/bootstrap.tscn")
	await process_frame
	await process_frame
	scene = current_scene
	await _wait_for(func(): return scene.screen == "title" and scene.title.visible and scene.title.start.has_focus(), "title screen with Start focused")
	# The owner (2026-11-16): "Tap to Play"; no Clubhouse music under the title.
	if not scene.title.prompt.text.ends_with("to Play"): failures.append("the title says Tap to Play (%s)" % scene.title.prompt.text)
	if scene.clubhouse_music != null and scene.clubhouse_music.playing: failures.append("the Clubhouse music waits for the menu")
	await _capture("title")
	if scene.title == null or scene.title.wordmark.text != "ROGUEWOOD" or not scene.title.prompt.visible: failures.append("the title screen lacks its wordmark or prompt")
	if scene.enter.has_focus(): failures.append("Enter League has focus behind the title")
	await _accept()
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	if scene.title.visible or scene.screen != "menu": failures.append("accept did not leave the title for the Clubhouse")
	if scene.tap_sound == null or scene.tap_sound.stream == null: failures.append("the title's tap plays its sound")
	if scene.clubhouse_music == null or not scene.clubhouse_music.playing: failures.append("the Clubhouse music starts at the menu")
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
	# UI-5: the menu button has focus; Restart is in its menu and asks once.
	if not scene.menu_button.has_focus(): failures.append("the session menu button is not focused")
	await _accept()
	if not scene.session_menu.visible or not scene.resume.has_focus(): failures.append("the menu did not open on Resume")
	scene.reset.grab_focus()
	await _accept()
	if scene.session.get("score") != 999 or not scene.session_menu.visible: failures.append("the first Restart press must only ask")
	await _accept()
	await _wait_for(func(): return scene.session == initial, "reset")
	await _capture("reset")
	if scene.session != initial: failures.append("restart input did not reset deterministically")
	if scene.session_menu.visible: failures.append("the menu stayed open after Restart")
	scene.menu_button.grab_focus()
	await _accept()
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
