extends "res://tests/slice_journey.gd"
## Real purchase -> placement -> physical roll -> collection. Only fixture is a
## logged wallet grant to bound shop rerolls; every purchase/placement uses UI.
const Assets = preload("res://src/presentation/item_assets.gd")
const IDS := ["pin.wood", "pin.ruby", "pin.gold", "pin.anchor"]

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
	await _toggle_assist()
	_check_rack()
	await _arm("ball.echo")
	await _throw(STRIKE)
	await _scored()
	await _to_shop("pin art")
	lab.run.credit(400, "fixture: pin art bounded shop coverage")
	lab._refresh_shop()
	var bought := {}
	for attempt in range(20):
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			var id: String = offer.item_id
			if id not in IDS or id == "pin.wood" or bought.has(id) or offer.sold: continue
			var button: Button = lab.shop_panel.button_for_offer(index)
			_check(button.icon == Assets.slot(id, "icon"), "shop icon matches stable ID: " + id)
			await _capture(id.replace(".", "_") + "_shop")
			await _focus_accept(button)
			_check(lab.shop_panel.choice_sheet.visible, "pin asks for actual rack position")
			var position := bought.size() + 1
			var before: int = lab.run.money
			await _focus_accept(lab.shop_panel.choice_button(position - 1))
			await process_frame
			_check(lab.run.rack[position].item_id == id and lab.run.money == before - int(offer.price), "purchase places identity and charges exact price")
			bought[id] = position
			# Free the displaced Wood reserve through the actual sell control.
			var reserve: Button = lab.shop_panel.sell_button("reserve:1")
			if reserve != null:
				await _focus_accept(reserve)
				await process_frame
		if bought.size() == 3: break
		await _focus_accept(lab.shop_panel.reroll_button)
		await process_frame
	_check(bought.size() == 3, "seeded shop covers Ruby, Gold and Anchor")
	await _leave_shop()
	_check_rack()
	await _capture("pin_rack")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	await _capture("pin_reduced")
	# Diagnostic close view of the same live bodies, labelled separately from the
	# normal player camera. Only this test changes the camera transform.
	var player_camera: Transform3D = lab._camera.transform
	lab._camera.position = Vector3(0.15, 0.85, -16.1)
	lab._camera.look_at(Vector3(0.0, 0.12, -18.5))
	await _capture("pin_rack_detail")
	await _aim()
	await _slide(lab.assist_panel.position_slider, STRIKE[0])
	await _slide(lab.assist_panel.aim_slider, STRIKE[1])
	await _slide(lab.assist_panel.power_slider, STRIKE[2])
	var rolls: int = lab.history.size()
	await _focus_accept(lab.assist_panel.throw_button)
	await _wait_for(func(): return lab.lane.tracker.sequence.size() > 0, "mixed rack impact", ROLL_FRAMES)
	await _capture("pin_impact_detail")
	await _wait_for(func(): return lab.history.size() == rolls + 1, "mixed roll settles", ROLL_FRAMES)
	_check_rack()
	_check(lab.history[-1].roll_result.fallen_positions.size() > 0, "mixed rack has physically fallen pins")
	lab._camera.transform = player_camera
	await _capture("pin_fallen")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "binder return")
	await _focus_accept(scene.clubhouse.tab_buttons.binder)
	await _focus_accept(scene.clubhouse.filter_button("pin"))
	for id in IDS:
		await _focus_accept(scene.clubhouse.entry_button(id))
		for i in range(12): await process_frame
		var holder: Control = scene.clubhouse.binder_art
		_check(holder.get_child_count() == 1 and holder.get_child(0) is TextureRect and holder.get_child(0).texture == Assets.slot(id, "card"), "binder displays purchased pin: " + id)
		if not artifact_dir.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			_check(root.get_texture().get_image().save_png(artifact_dir.path_join(id.replace(".", "_") + "_binder.png")) == OK, "binder capture")
	if failures.is_empty(): print("ROGUEWOOD_PIN_ART_OK")
	quit(0 if failures.is_empty() else 1)

func _check_rack() -> void:
	for position in lab.lane.pins:
		var body: RigidBody3D = lab.lane.pins[position]
		var id: String = lab.run.rack[position].item_id
		_check(body.get_meta("art_item_id", "") == id, "physical pin retains purchased identity: " + id)
		for child in body.get_children():
			if child is MeshInstance3D:
				_check(child.material_override == Assets.slot(id, "in_play"), "actual body uses catalogue material")
		_check(body.has_node("AnchorCollar") == (id == "pin.anchor"), "only Anchor has reinforced silhouette")

func _capture(label: String) -> void:
	for i in range(12): await process_frame
	await super._capture(label)
