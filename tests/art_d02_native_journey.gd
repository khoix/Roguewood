extends "res://tests/slice_journey.gd"
## Real shop offers, purchases, hand-free inventory and binder. Only wallet and
## offer eligibility are fixture inputs; no item is inserted directly into inventory.
const Assets = preload("res://src/presentation/item_assets.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
var batch := "E19-A13"
var wanted: Array = []
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	for part in artifact_dir.split("/"):
		if part.begins_with("e19-a"): batch = part.to_upper()
	var ids: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/d02/batches.json"))[batch]
	Assets._ensure()
	wanted = ids.filter(func(id): return Assets._items.has(id))
	_check(not wanted.is_empty(),"this native batch has playable entries")
	root.size = Vector2i(720,1280)
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim","slice ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _toggle_assist()
	await _arm("ball.echo")
	await _throw(STRIKE)
	await _scored()
	await _to_shop("D02 art")
	lab.run.credit(10000,"fixture: bounded D02 art offer sampling")
	lab.shop.division = 2
	for id in wanted:
		for gate in lab.run.item(id).unlock.prerequisites:
			if gate not in lab.shop.unlocked: lab.shop.unlocked.append(gate)
	print("D02 art fixture: wallet grant, Division 2 shop eligibility and required unlock gates; actual offers and purchases follow")
	lab._refresh_shop()
	var bought := {}
	for attempt in 100:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			var id: String = offer.item_id
			if id not in wanted or bought.has(id) or offer.sold: continue
			var button: Button = lab.shop_panel.button_for_offer(index)
			_check(button.icon != null and button.icon == Assets.slot(id,"icon"),"shop icon "+id)
			await _capture(id.replace(".","_")+"_shop")
			var before: int = lab.run.money
			await _focus_accept(button)
			await process_frame
			_check(lab.shop.offers[index].sold and lab.run.money == before-int(offer.price),"real purchase "+id)
			_check(lab.run.charms.any(func(e): return e.item_id == id),"real equipped ownership "+id)
			bought[id] = true
		if bought.size() == wanted.size(): break
		await _focus_accept(lab.shop_panel.reroll_button)
		await process_frame
	_check(bought.size()==wanted.size(),"seeded offers cover every landed batch item")
	await _leave_shop()
	await _wait_for(func(): return lab.motion.equipment_art.visible,"visible hand-free inventory")
	for id in wanted:
		var panel: Node = lab.motion.equipment_art.get_node_or_null(id.replace(".","_"))
		_check(panel != null and panel.get_node("Body/Identity").texture == Assets.slot(id,"icon"),"inventory icon uses declared ID "+id)
	await _capture("inventory")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	await _capture("reduced")
	root.size = Vector2i(1280,720)
	await _capture("landscape")
	root.size = Vector2i(720,1280)
	# A real subsequent throw proves presentation did not change scoring.
	var before_count: int = lab.history.size()
	var context := {"match_frame":lab.match_frame,"strike_streak":lab.run.strike_streak}
	await _throw(STRIKE)
	var scored := await _scored()
	var built := Builder.build(lab.run.loadout(),lab.content.catalogue,lab.history.slice(before_count),{},context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score":-1}
	_check(built.ok and scored.banked==expected.score,"bank equals independent rule resolution")
	await _capture("scored")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen=="menu","binder return")
	await _focus_accept(scene.clubhouse.tab_buttons.binder)
	await _focus_accept(scene.clubhouse.filter_button("charm"))
	for id in wanted:
		await _focus_accept(scene.clubhouse.entry_button(id))
		for i in 8: await process_frame
		var holder: Control = scene.clubhouse.binder_art
		_check(holder.get_child_count()==1 and holder.get_child(0) is TextureRect and holder.get_child(0).texture==Assets.slot(id,"card"),"native binder illustration "+id)
		_check(scene.clubhouse.entry_button(id).icon==Assets.slot(id,"card"),"native binder card icon "+id)
		await _capture_menu(id.replace(".","_")+"_binder")
	if failures.is_empty(): print("ROGUEWOOD_D02_NATIVE_ART_OK "+batch)
	for i in 6: await process_frame
	quit(0 if failures.is_empty() else 1)
func _capture(label: String) -> void:
	for i in 12: await process_frame
	await super._capture(label)
func _capture_menu(label: String) -> void:
	if artifact_dir.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(artifact_dir.path_join(label+".png"))==OK,"binder capture")
