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
	var seen := {}
	for uid in lab.card_hand.card_data:
		var id: String = lab.card_hand.card_data[uid].item_id
		if seen.has(id): continue
		seen[id] = true
		await _tap(lab.card_hand.button_for(uid))
		for i in range(3): await process_frame
		_check(lab.lane.aim_ball.get_meta("art_item_id", "") == id, "native hand switches in-play identity: " + id)
		if id != "ball.echo": await _capture(id.replace(".", "_"))
		await _tap(lab.card_hand.button_for(uid))
	for i in range(3): await process_frame
	_check(lab.lane.aim_ball.get_meta("art_item_id", "") == "ball.house", "House fallback material restored")
	await _capture("ball_house_aim")
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
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "shop", "ball shop")
	# The starting kit owns both copies of each special. Sell one of each through
	# real controls so their category can legally appear in a later seeded offer.
	for ball_name in ["Hook", "Hammer", "Echo"]:
		for button in lab.shop_panel.owned_list.get_children():
			if button is Button and ball_name in button.text:
				await _focus_accept(button)
				await process_frame
				break
	var offered := false
	for reroll in range(6):
		for index in range(lab.shop.offers.size()):
			var offer: Dictionary = lab.shop.offers[index]
			if String(offer.get("item_id", "")).begins_with("ball.") and not offer.sold:
				var button: Button = lab.shop_panel.button_for_offer(index)
				_check(button.icon == Assets.slot(offer.item_id, "icon"), "live shop resolves stable ID to the right icon")
				offered = true
				while lab.run.money < int(offer.price):
					var sale: Button = null
					for owned in lab.shop_panel.owned_list.get_children():
						if owned is Button and "Ball" in owned.text:
							sale = owned
							break
					if sale == null: break
					await _focus_accept(sale)
					await process_frame
				_check(not button.disabled, "art offer affordable after actual sale")
				await _capture("ball_shop")
				if not button.disabled:
					var money_before: int = lab.run.money
					await _focus_accept(button)
					await process_frame
					_check(lab.shop.offers[index].sold and lab.run.money == money_before - int(offer.price), "art offer purchase retains actual economy")
				break
		if offered or lab.shop_panel.reroll_button.disabled: break
		await _focus_accept(lab.shop_panel.reroll_button)
		await process_frame
	_check(offered, "seeded shop offers a production ball")
	await _leave_shop()
	await _capture("ball_reduced_aim")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "binder return")
	await _focus_accept(scene.clubhouse.tab_buttons.binder)
	await _focus_accept(scene.clubhouse.entry_button("ball.house"))
	for i in range(12): await process_frame
	var holder: Control = scene.clubhouse.binder_art
	_check(holder.get_child_count() == 1 and holder.get_child(0) is TextureRect and holder.get_child(0).texture == Assets.slot("ball.house", "card"), "House illustration reachable outside deck in binder")
	await _capture_menu("ball_house")
	if failures.is_empty(): print("ROGUEWOOD_BALL_ART_OK")
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	for i in range(12): await process_frame
	await super._capture(label)

func _capture_menu(label: String) -> void:
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(artifact_dir.path_join(label + ".png")) == OK, "save binder capture")
