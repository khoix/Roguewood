extends SceneTree
## Drives focused native buttons through InputEventAction; no direct callbacks.
var failures: Array[String] = []

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
	var scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	if scene.screen != "menu" or not scene.enter.has_focus(): failures.append("menu missing or Enter League unfocused")
	await _accept()
	if scene.screen != "session": failures.append("Enter League input did not open session")
	var initial: Dictionary = scene.session.duplicate(true)
	if initial.get("score") != 0 or initial.get("division") != 1: failures.append("invalid session fixture")
	scene.session.score = 999 # Seed changed state; the reset action itself uses real input.
	await _accept()
	if scene.session != initial: failures.append("restart input did not reset deterministically")
	scene.back.grab_focus()
	await _accept()
	if scene.screen != "menu" or not scene.session.is_empty(): failures.append("Clubhouse input did not clear session")
	for failure in failures: printerr("FAIL: " + failure)
	if failures.is_empty(): print("ROGUEWOOD_SHELL_OK")
	quit(0 if failures.is_empty() else 1)
