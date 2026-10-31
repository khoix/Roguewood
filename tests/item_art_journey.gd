extends "res://tests/slice_journey.gd"
## Native Wave 1 art regression. Fixture-only wallet/unlock grants bound sampling;
## purchases, placement, rolls, reduced mode and collection use actual game UI.
const Assets = preload("res://src/presentation/item_assets.gd")
var batch := "E19-A03"
var ids: Array = []

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	for part in artifact_dir.split("/"):
		if part.begins_with("e19-a"): batch = part.to_upper()
	ids = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/batches.json"))[batch]
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "slice ready")
	lab = scene.lab
	await _toggle_assist()
	await _arm("ball.echo")
	await _throw(STRIKE)
	await _scored()
	await _to_shop("item art")
	lab.run.credit(10000, "fixture: bounded art offer sampling") # the House batches grew the pool (Wave 7)
	# Reward-only identities are tested in the real shop after a fixture unlock;
	# J06 independently verifies earning both gates and next-attempt availability.
	for gate in ["gate.surveyor_cleared", "gate.custodian_cleared"]:
		if gate not in lab.shop.unlocked: lab.shop.unlocked.append(gate)
	lab._refresh_shop()
	var wanted: Array = ids.filter(func(id): return String(id).begins_with("pin.") or String(id).begins_with("charm."))
	var bought := {}
	var pin_count := 0
	for attempt in range(150):
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			var id: String = offer.item_id
			if id not in wanted or bought.has(id) or offer.sold: continue
			var button: Button = lab.shop_panel.button_for_offer(index)
			_check(button.icon == Assets.slot(id, "icon"), "shop identity: " + id)
			await _capture(id.replace(".", "_") + "_shop")
			var before: int = lab.run.money
			await _focus_accept(button)
			if id.begins_with("pin."):
				await _focus_accept(lab.shop_panel.choice_button(pin_count))
				pin_count += 1
				await process_frame
				_check(lab.run.rack[pin_count].item_id == id, "pin placed in actual rack")
			else:
				await process_frame
				_check(lab.run.charms.any(func(entry): return entry.item_id == id), "charm equipped by purchase")
			_check(lab.run.money == before - int(offer.price), "actual price paid")
			bought[id] = true
			var reserve: Button = lab.shop_panel.sell_button("reserve:1")
			if reserve:
				await _focus_accept(reserve)
				await process_frame
		if bought.size() == wanted.size(): break
		await _focus_accept(lab.shop_panel.reroll_button)
		await process_frame
	_check(bought.size() == wanted.size(), "seeded offers cover entire art batch")
	await _leave_shop()
	for i in range(12): await process_frame
	for id in wanted:
		if id.begins_with("charm."):
			var panel: Node = lab.motion.equipment_art.get_node_or_null(id.replace(".", "_"))
			_check(panel != null and panel.get_node("Body/Identity").texture == Assets.slot(id, "in_play"), "equipped charm identity: " + id)
	for id in ids:
		if String(id).begins_with("kit."):
			var marker: Node = lab.motion.equipment_art.get_node_or_null(String(id).replace(".", "_"))
			_check(marker != null and marker.get_node("Body/Identity").texture == Assets.slot(id, "in_play"), "actual starting-kit marker")
	for position in lab.lane.pins:
		var id: String = lab.run.rack[position].item_id
		_check(lab.lane.pins[position].get_meta("art_item_id", "") == id, "actual physical pin identity")
	await _capture("equipped")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	await _capture("reduced")
	if pin_count > 0:
		var player_camera: Transform3D = lab._camera.transform
		lab._camera.position = Vector3(0.15,0.85,-16.1)
		lab._camera.look_at(Vector3(0,0.12,-18.5))
		await _capture("rack_detail")
		lab._camera.transform = player_camera
	await _throw(STRIKE)
	await _scored()
	await _capture("scored")
	root.size = Vector2i(800,450)
	await _capture("landscape")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "binder return")
	await _focus_accept(scene.clubhouse.tab_buttons.binder)
	for id in ids:
		if String(id).begins_with("boss_rule."): continue # J06/E21 owns actual boss rule UI
		await _focus_accept(scene.clubhouse.filter_button(String(id).get_slice(".",0)))
		await _focus_accept(scene.clubhouse.entry_button(id))
		for i in range(12): await process_frame
		var holder: Control = scene.clubhouse.binder_art
		_check(holder.get_child_count() == 1 and holder.get_child(0) is TextureRect and holder.get_child(0).texture == Assets.slot(id,"card"), "binder illustration: " + id)
		await _capture_menu(id.replace(".","_") + "_binder")
	if failures.is_empty(): print("ROGUEWOOD_ITEM_ART_OK")
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	for i in range(12): await process_frame
	await super._capture(label)

func _capture_menu(label: String) -> void:
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(artifact_dir.path_join(label + ".png")) == OK, "binder capture")
