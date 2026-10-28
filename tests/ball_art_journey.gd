extends "res://tests/slice_journey.gd"
const Assets = preload("res://src/presentation/item_assets.gd")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "slice ready")
	lab = scene.lab
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	var found := false
	for uid in lab.card_hand.card_data:
		var data: Dictionary = lab.card_hand.card_data[uid]
		var id: String = data.get("item_id", "")
		_check(not id.is_empty(), "production card resolves stable asset ID")
		_check(lab.card_hand.button_for(uid).icon == Assets.slot(id, "icon"), "hand uses production icon")
		if id == "ball.echo" and not found:
			found = true
			var before: Dictionary = lab.run.to_dict()
			await _focus_accept(lab.card_hand.inspect_button)
			await _tap(lab.card_hand.button_for(uid))
			_check(lab.inspector.visible and lab.inspector.art.texture == Assets.slot(id, "card"), "native inspect shows Echo identity")
			await _capture("ball_inspect")
			await _focus_accept(lab.inspector.close_button)
			_check(lab.run.to_dict() == before, "inspection preserves all inventory and wallet state")
	_check(found, "Echo inspection fixture available")
	await _arm("ball.echo")
	for i in range(3): await process_frame
	_check(lab.lane.aim_ball.get_meta("art_item_id", "") == "ball.echo", "armed mesh has Echo material")
	await _capture("ball_aim")
	await _throw(STRIKE)
	await _scored()
	_check(lab.lane.ball.get_meta("art_item_id", "") == "ball.echo", "rolling physical mesh keeps committed identity")
	await _capture("ball_scored")
	root.size = Vector2i(800, 450)
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	for i in range(12): await process_frame
	await _capture("ball_reduced")
	if failures.is_empty(): print("ROGUEWOOD_BALL_ART_OK")
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	for i in range(12): await process_frame
	await super._capture(label)
