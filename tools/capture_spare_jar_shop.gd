extends "res://tests/house_c08_journey.gd"
## Native offer, reached by actual throws/rerolls. Only fixture is a logged wallet grant.
var baseline_views: Array[Resource] = []
var before_art := false

func _run() -> void:
	baseline_views = preload("res://tools/spare_jar_capture_art.gd").prepare(before_art)
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
	lab.settings_panel.use_practice()
	await process_frame
	await _focus_accept(lab.settings_panel.close)
	await _focus_accept(scene.resume)
	await _play_out()
	lab.run.credit(2000, "fixture: AV-FIX1 offer sampling")
	lab._refresh_shop()
	print("AV-FIX1 fixture: $2000 after real opener; real rerolls, no injected offers or unlocks")
	var found := -1
	for visit in 150:
		for i in lab.shop.offers.size():
			if lab.shop.offers[i].item_id == "charm.spare_jar" and not lab.shop.offers[i].sold: found = i
		if found >= 0: break
		await _tap(lab.shop_panel.reroll_button)
	_check(found >= 0, "Spare Jar naturally offered")
	if found >= 0:
		var card: Control = lab.shop_panel.button_for_offer(found)
		await _reach(card)
		card.grab_focus()
		await _action("ui_accept")
		await _wait_for(func(): return lab.shop_panel.offer_sheet.visible, "native offer preview")
		_check(lab.shop_panel.offer_card.item_id == "charm.spare_jar", "native offer uses Spare Jar art")
		for landscape in [false, true]:
			root.size = Vector2i(1280, 720) if landscape else PORTRAIT
			for i in 12: await process_frame
			await _capture("shop_" + ("landscape" if landscape else "portrait"))
	if failures.is_empty(): print("ROGUEWOOD_FIX1_SHOP_OK")
	quit(0 if failures.is_empty() else 1)
