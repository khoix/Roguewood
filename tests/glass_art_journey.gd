extends "res://tests/glass_c02_journey.gd"
## E19-A16: actual offer/purchase/placement/binder, then C02's declared Glass
## rack fixture and real physics. No invented roll reports or break outcomes.
const Assets = preload("res://src/presentation/item_assets.gd")
var physics_before := {}

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = Vector2i(720,1280)
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _toggle_assist()
	await _arm("ball.echo")
	await _throw(STRIKE)
	await _scored()
	await _to_shop("Glass identity")
	lab.run.credit(2000, "fixture: bounded Glass offer sampling")
	lab.shop.division = 2
	print("A16 fixture: wallet and shop eligibility only; real purchase/placement follows")
	lab._refresh_shop()
	var bought := false
	for attempt in 80:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if offer.item_id != "pin.glass" or offer.sold: continue
			var button: Button = lab.shop_panel.button_for_offer(index)
			_check(button.icon == Assets.slot("pin.glass", "icon"), "Glass offer icon")
			await _capture("glass_shop")
			await _focus_accept(button)
			_check(lab.shop_panel.choice_sheet.visible, "real rack placement choice")
			var money: int = lab.run.money
			await _focus_accept(lab.shop_panel.choice_button(0))
			await process_frame
			_check(lab.run.rack[1].item_id == "pin.glass" and lab.run.money == money - int(offer.price), "Glass purchased into slot one")
			_check(lab.shop_panel.rack_label.text.contains("1 Glass Pin"), "real inventory summary names owned Glass")
			await _capture("glass_inventory")
			bought = true
			break
		if bought: break
		await _focus_accept(lab.shop_panel.reroll_button)
	_check(bought, "seeded offers include Glass")
	await _leave_shop()
	await _aim()
	_check_body(1, "pin.glass")
	await _capture("glass_rack")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "binder return")
	await _focus_accept(scene.clubhouse.tab_buttons.binder)
	await _focus_accept(scene.clubhouse.filter_button("pin"))
	await _focus_accept(scene.clubhouse.entry_button("pin.glass"))
	var holder: Control = scene.clubhouse.binder_art
	_check(holder.get_child_count() == 1 and holder.get_child(0).texture == Assets.slot("pin.glass", "card"), "purchased Glass binder illustration")
	await _capture("glass_binder")
	await _focus_accept(scene.clubhouse.tab_buttons.board)
	await _focus_accept(scene.continue_button)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "continue purchased rack")
	lab = scene.lab
	lab.trial_log_path = ""
	# Match the logged C02 fixture to guarantee deterministic break/non-break
	# coverage. The purchase and binder above used no inserted owned item.
	for position in range(1, 11): lab.run.rack[position] = Inventory._entry("pin.glass", 0)
	_check(lab.run.place("charm.glass_cutter", 0, "charm:new").is_empty(), "C02 fixture Glass Cutter")
	print("A16 C02 fixture: ten Glass pins and Glass Cutter; seeded physical throw")
	lab._new_roll(false)
	await _aim()
	for position in lab.lane.pins:
		_check_body(position, "pin.glass")
		physics_before[position] = _physical(lab.lane.pins[position])
	var camera: Transform3D = lab._camera.transform
	lab._camera.position = Vector3(0.15, 0.85, -16.1)
	lab._camera.look_at(Vector3(0, 0.12, -18.5))
	await _capture("glass_rack_detail")
	lab._camera.transform = camera
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	await _capture("glass_reduced")
	root.size = Vector2i(1280,720)
	await _capture("glass_landscape")
	root.size = Vector2i(720,1280)
	var broken := await _glass_frame("A16")
	_check(not broken.is_empty() and broken.size() < 10, "both broken and unbroken Glass outcomes")
	for position in lab.lane.pins:
		_check_body(position, "pin.wood" if position in broken else "pin.glass")
		_check(_physical(lab.lane.pins[position]) == physics_before[position], "identity keeps body/collision/mass at %d" % position)
	await _capture("glass_break")
	lab._camera.position = Vector3(0.15, 0.85, -16.1)
	lab._camera.look_at(Vector3(0, 0.12, -18.5))
	await _capture("glass_break_detail")
	lab._camera.transform = camera
	var rack := _rack()
	var effects: int = lab.run.effects_state
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "restore menu")
	await _focus_accept(scene.continue_button)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "frame_done", "restored bank")
	lab = scene.lab
	_check(_rack() == rack and lab.run.effects_state == effects, "visual reload never rerolls breaks")
	for position in lab.lane.pins: _check_body(position, lab.run.rack[position].item_id)
	await _capture("glass_restored")
	await _to_shop("Glass after-break rack")
	await _leave_shop()
	await _aim()
	_check(lab.lane.pins.size() == 10, "next frame keeps all ten rack slots")
	for position in lab.lane.pins: _check_body(position, "pin.wood" if position in broken else "pin.glass")
	lab._camera.position = Vector3(0.15, 0.85, -16.1)
	lab._camera.look_at(Vector3(0, 0.12, -18.5))
	await _capture("glass_next_rack")
	if failures.is_empty(): print("ROGUEWOOD_GLASS_ART_OK")
	for i in 8: await process_frame
	quit(0 if failures.is_empty() else 1)

func _physical(body: RigidBody3D) -> Dictionary:
	var shapes := []
	for child in body.get_children():
		if child is CollisionShape3D: shapes.append([child.get_instance_id(), child.shape.get_rid(), child.transform, child.disabled])
	return {"id":body.get_instance_id(), "mass":body.mass, "layer":body.collision_layer, "mask":body.collision_mask, "shapes":shapes}

func _check_body(position: int, id: String) -> void:
	var body: RigidBody3D = lab.lane.pins[position]
	_check(body.get_meta("art_item_id", "") == id, "live body art %d %s" % [position,id])
	var identity := body.get_node_or_null("CatalogueIdentity")
	if id == "pin.glass":
		_check(identity != null and identity.scene_file_path == Assets.slot(id,"in_play").resource_path, "exact Glass scene under body")
		if identity != null: _check(identity.find_children("*", "CollisionObject3D", true, false).is_empty(), "cosmetic scene has no bodies")
	else:
		_check(identity == null, "no stale Glass scene after break")
		for child in body.get_children():
			if child is MeshInstance3D: _check(child.visible and child.material_override == Assets.slot(id,"in_play"), "Wood mesh restored in place")

func _capture(label: String) -> void:
	for i in 12: await process_frame
	if scene.screen == "menu":
		if not artifact_dir.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			_check(root.get_texture().get_image().save_png(artifact_dir.path_join(label+".png")) == OK, "binder capture")
		return
	await super._capture(label)
