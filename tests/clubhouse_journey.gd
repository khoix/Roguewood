extends "res://tests/career_journey.gd"
## J11 Clubhouse (E16) through the real game, with touch and keyboard. Two engine
## processes share one save directory (tools/qa.py):
##   1 a fresh Career: the Binder shows Locked and Available cards (inspecting
##     Encore names the rival that unlocks it); follow a goal, which the League
##     Board then shows; play attempt 1 of the slice to a House League title (the
##     J06 path); back in the Clubhouse, cards owned in the win are Mastered, the
##     unlocks are Available, and the title, plaques and decorations are earned;
##   2 restart: everything above survived; Try Again, win the opener, buy a Charm
##     never owned before, then lose; the Clubhouse still shows every reward, the
##     new Charm is Discovered and the record counts both attempts; then return to
##     play from the Binder through the League Board.
## Shots are the deterministic J03 assist throws. Run with --fixed-fps 60.

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
		if arg.begins_with("--stage="): stage = int(arg.trim_prefix("--stage="))
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.screen == "menu" and (scene.enter.has_focus() or scene.continue_button.has_focus()), "menu focus")
	_check(scene.clubhouse.visible and scene.clubhouse.current_tab == "board", "the Clubhouse opens on the League Board")
	match stage:
		1: await _stage_one_clubhouse()
		2: await _stage_two_clubhouse()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty() and lab != null: await _capture("clubhouse_failure")
	if failures.is_empty(): print("ROGUEWOOD_J11_OK" if stage == 2 else "ROGUEWOOD_J11_STAGE%d_OK" % stage)
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	var club = scene.clubhouse
	print("J11 stage=%d %s screen=%s tab=%s counts=%s selected=%s detail=%s" % [stage, label, scene.screen, club.current_tab,
		club.binder_counts.text, club.selected_item, club.binder_detail.text.get_slice("\n", 0)])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

func _tab(tab: String, touch: bool = false) -> void:
	var button: Button = scene.clubhouse.tab_buttons[tab]
	if touch:
		await _tap(button)
	else:
		await _focus_accept(button)
	await process_frame
	_check(scene.clubhouse.current_tab == tab and scene.clubhouse.pages[tab].get_parent().visible, "the %s tab opens" % tab)

func _card(item_id: String) -> Dictionary:
	await _focus_accept(scene.clubhouse.entry_button(item_id))
	await process_frame
	for entry in scene.clubhouse.Model.binder(scene.career, scene.career_graph, scene.career_graph.catalogue):
		if entry.id == item_id:
			return entry
	return {}

func _state(item_id: String) -> String:
	for entry in scene.clubhouse.Model.binder(scene.career, scene.career_graph, scene.career_graph.catalogue):
		if entry.id == item_id:
			return entry.state
	return ""

func _shelf(id: String) -> Control:
	return scene.clubhouse.trophy_grid.get_node_or_null("Trophy_" + id.replace(".", "_"))

func _earned(id: String) -> bool:
	var box := _shelf(id)
	return box != null and not box.get_node("Name").text.ends_with("(not yet)")

func _back_to_clubhouse() -> void:
	await _focus_accept(lab.hud.menu_button)
	await _wait_for(func(): return scene.screen == "menu" and scene.lab == null and scene.clubhouse.visible, "the Clubhouse after the result")
	lab = null

func _stage_one_clubhouse() -> void:
	var club = scene.clubhouse
	await _tab("binder", true)
	_check(club.binder_counts.text == "9 Locked · 51 Available · 0 Discovered · 0 Mastered", "a fresh binder: %s" % club.binder_counts.text)
	await _focus_accept(club.filter_button("charm"))
	_check(club.category == "charm" and club.binder_grid.get_child_count() == 30, "the Charms filter shows the thirty Charms")
	var encore := await _card("charm.encore")
	_check(encore.state == "locked" and club.selected_item == "charm.encore" and club.binder_detail.text.contains("Unlock: Beat The Surveyor (House League)")
		and club.binder_art.get_child(0) is TextureRect and club.binder_art.get_child(0).texture == load(encore.asset), "inspecting Encore: Locked, the rival that unlocks it, actual catalogue artwork")
	await _capture("clubhouse_locked")
	await _tab("goals")
	await _focus_accept(club.track_button("mastery.mixed_rack"))
	_check(scene.career.tracked == ["mastery.mixed_rack"] and _disk().get("tracked", []) == ["mastery.mixed_rack"]
		and club.track_button("mastery.mixed_rack").text == "Following", "following Mixed Rack is saved")
	await _capture("clubhouse_goals")
	await _tab("board", true)
	_check(scene.career_line.text.contains("Goals: Mixed Rack 0/3") and not scene.career_line.text.contains("Spare Hand"), "the League Board shows the followed goal")
	# Attempt 1: the J06 slice path to the House League title.
	scene.enter.grab_focus()
	await _enter(scene.enter)
	await _assist_on()
	await _division_one()
	await _division_two()
	await _back_to_clubhouse()
	await _tab("binder")
	_check(_state("pin.wood") == "mastered" and _state("ball.echo") == "mastered" and _state("charm.plumb_line") == "mastered", "cards owned in the win are Mastered")
	_check(_state("charm.encore") == "available" and _state("charm.standing_order") == "available" and _state("charm.gold_rush") == "available",
		"both unlocks and never-owned cards are Available")
	await _focus_accept(club.filter_button(""))
	var wood := await _card("pin.wood")
	_check(club.binder_detail.text.contains("Mastered") and club.binder_detail.text.contains("in 1 League win"), "inspecting Wood shows its win")
	await _capture("clubhouse_mastered")
	await _tab("trophies")
	_check(_earned("league.house") and _earned("rival.surveyor") and _earned("rival.custodian") and _earned("deco.club_sign") and _earned("deco.trophy_case")
		and not _earned("league.house_campaign") and not _earned("deco.lane_trim"), "the title, both plaques and two decorations are on the shelf")
	await _capture("clubhouse_trophies")

func _stage_two_clubhouse() -> void:
	var club = scene.clubhouse
	_check(scene.enter.text == "Try Again" and club.records_label.text.contains("House League · 1 attempt") and club.records_label.text.contains("1 title"),
		"after a restart the board offers Try Again and keeps the record")
	await _tab("binder")
	_check(_state("pin.wood") == "mastered" and _state("charm.encore") == "available", "Mastered and unlocked cards survive the restart")
	await _tab("board")
	scene.enter.grab_focus()
	await _enter(scene.enter)
	await _assist_on()
	_check(lab.career_attempt == 2 and lab.shop.ineligibility(_encore(), lab.run).is_empty(), "attempt 2 has Encore in its pool")
	await _strike_out()
	await _to_shop("opener")
	# Buy the first Charm never owned before, rerolling (a real tap) while none is on offer.
	var bought := ""
	for visit in 4:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			var known: bool = scene.career.items.has(offer.item_id)
			if bought.is_empty() and offer.item_id.begins_with("charm.") and not known and not offer.sold and offer.price <= lab.run.money:
				await _tap(lab.shop_panel.button_for_offer(index))
				await process_frame
				if lab.shop.offers[index].sold:
					bought = offer.item_id
		if not bought.is_empty() or lab.run.money < lab.shop.reroll_cost() + 3:
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J11 stage=2 bought %s from %s" % [bought, str(lab.shop.offers.map(func(o): return "%s $%d" % [o.item_id, o.price]))])
	_check(not bought.is_empty(), "a Charm never owned before is bought")
	await _leave_shop()
	await _lose()
	await _back_to_clubhouse()
	_check(club.current_tab == "board" and club.records_label.text.contains("House League · 2 attempts") and club.latest_label.text.contains("Encore joins the shop pool"),
		"after the loss the board counts both attempts and still lists the unlocks")
	await _tab("binder")
	_check(_state(bought) == "discovered" and _state("pin.wood") == "mastered" and _state("charm.encore") == "available", "the new Charm is Discovered; earlier rewards stay")
	await _card(bought)
	_check(club.binder_detail.text.contains("Discovered") and club.binder_detail.text.contains("Win a League with it"), "inspecting it explains how to master it")
	await _capture("clubhouse_discovered")
	await _tab("trophies")
	_check(_earned("league.house") and _earned("rival.surveyor") and _earned("deco.trophy_case"), "a loss takes nothing off the shelf")
	# Return to play: Binder -> League Board -> Try Again.
	await _tab("board", true)
	scene.enter.grab_focus()
	await _enter(scene.enter)
	_check(lab.state == "aim" and lab.career_attempt == 3, "Try Again returns to play")
	await _capture("clubhouse_return")
