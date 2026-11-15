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
	# The phone layout: four tabs on one row inside the screen, and the Career as tiles.
	var tabs: Array = scene.clubhouse.tab_buttons.values()
	_check(tabs.all(func(b): return is_equal_approx(b.global_position.y, tabs[0].global_position.y) and b.get_global_rect().end.x <= scene.clubhouse.size.x and b.size.y >= 52),
		"the four tabs share one row on a phone")
	_check(scene.career_stats.get_child_count() == 4 and not scene.career_line.visible, "the League Board shows the Career as four tiles")
	_ui9_board()
	match stage:
		1: await _stage_one_clubhouse()
		2: await _stage_two_clubhouse()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty() and lab != null: await _capture("clubhouse_failure")
	if failures.is_empty(): print("ROGUEWOOD_J11_OK" if stage == 2 else "ROGUEWOOD_J11_STAGE%d_OK" % stage)
	quit(0 if failures.is_empty() else 1)

## UI-9 (owner's play notes, 2026-11-15): the logo heads the Clubhouse; the pages
## scroll without a bar; the Career is one scoreboard; the choices sit under
## captions on a play card and the action is the brass button; each League is a card.
func _ui9_board() -> void:
	var club = scene.clubhouse
	var logo: Control = club.find_child("ClubhouseLogo", true, false)
	_check(logo != null and logo.visible and logo.get_global_rect().end.y <= club.tab_buttons.board.get_global_rect().position.y and club.find_child("ClubhouseWordmark", true, false) == null,
		"the game's logo heads the Clubhouse, above the tabs")
	_check(club.pages.values().all(func(p): return p.get_parent().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER), "no page shows a scroll bar")
	var play: Control = scene.find_child("PlayCard", true, false)
	_check(play != null and play.is_ancestor_of(scene.league) and play.is_ancestor_of(scene.kit) and play.is_ancestor_of(scene.enter)
		and scene.league.get_node_or_null("BrassEdge") != null, "the League and kit choices and the action sit on the play card")
	var action: Button = scene.continue_button if scene.continue_button.visible else scene.enter
	var brass: StyleBox = action.get_theme_stylebox("normal")
	_check(brass is StyleBoxFlat and (brass as StyleBoxFlat).bg_color.is_equal_approx(Color("d8b873")), "the action to take is the brass button")
	var footer: Control = club.pages.board.get_node_or_null("BoardFooter")
	_check(footer != null and footer.get_index() == club.pages.board.get_child_count() - 1 and footer.find_child("FooterCredit", true, false).text == "Roguewood 2026 | khoix"
		and footer.find_child("FooterRule", true, false) != null, "UI-10: the board ends with a short rule and the footer line")
	_check(club.league_cards.get_child_count() == club.records_label.text.split("\n").size() and club.records_label.visible == false,
		"each League's record is a card (%d)" % club.league_cards.get_child_count())

## UI-9: on the Trophies and Goals pages a finger that lands on a row or a button
## drags the page; a Follow press that ended in a scroll follows nothing.
func _ui9_scroll() -> void:
	var club = scene.clubhouse
	await _tab("trophies")
	var stops := func(root_node: Node) -> bool:
		for node in root_node.find_children("*", "Control", true, false):
			if (node as Control).mouse_filter == Control.MOUSE_FILTER_STOP: return true
		return false
	_check(club.trophy_grid.get_child_count() > 0 and not stops.call(club.trophy_grid), "no trophy row stops a drag")
	await _tab("goals")
	_check(club.goals_list.get_child_count() > 0 and not stops.call(club.goals_list), "no goal row or button stops a drag")
	var page: ScrollContainer = club.pages.goals.get_parent()
	var first: Dictionary = {"id": ""}
	for row in club.goals_list.get_children():
		var button: Button = row.find_child("Track", true, false)
		if not button.disabled and not button.button_pressed:
			first.id = String(row.name).trim_prefix("Goal_")
			break
	var track: Button = club.goals_list.get_node("Goal_" + first.id).find_child("Track", true, false)
	var before: int = scene.career.get("tracked", []).size()
	track.button_down.emit()
	page.scroll_vertical += 200
	await process_frame
	track.pressed.emit()
	await process_frame
	_check(scene.career.get("tracked", []).size() == before, "a Follow press that ended in a scroll follows nothing")
	page.scroll_vertical = 0
	await _tab("board")

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
	return box != null and not box.find_child("Name", true, false).text.ends_with("(not yet)")

func _back_to_clubhouse() -> void:
	await _focus_accept(lab.hud.menu_button)
	await _wait_for(func(): return scene.screen == "menu" and scene.lab == null and scene.clubhouse.visible, "the Clubhouse after the result")
	lab = null

func _stage_one_clubhouse() -> void:
	var club = scene.clubhouse
	await _tab("binder", true)
	_check(club.binder_counts.text == "25 Locked · 82 Available · 0 Discovered · 0 Mastered", "a fresh binder: %s" % club.binder_counts.text)
	var tiles: Array = club.binder_stats.get_children().map(func(t): return t.get_child(0).get_child(0).text + " " + t.get_child(0).get_child(1).text)
	_check(" · ".join(tiles) == club.binder_counts.text, "the binder's tiles show the same counts: %s" % str(tiles))
	var cards: Array = club.binder_grid.get_children()
	_check(is_equal_approx(cards[2].global_position.y, cards[0].global_position.y) and not is_equal_approx(cards[3].global_position.y, cards[0].global_position.y)
		and cards[2].get_global_rect().end.x <= club.size.x, "a phone's binder is three cards across")
	await _focus_accept(club.filter_button("charm"))
	_check(club.category == "charm" and club.binder_grid.get_child_count() == 52, "the Charms filter shows the fifty-two Charms")
	var encore := await _card("charm.encore")
	_check(encore.state == "locked" and club.selected_item == "charm.encore" and club.binder_detail.text.contains("Unlock: Beat The Surveyor (House League)")
		and club.binder_art.get_child(0) is TextureRect and club.binder_art.get_child(0).texture == load(encore.asset), "inspecting Encore: Locked, the rival that unlocks it, actual catalogue artwork")
	# UI-8: a tapped card opens in a preview over the page; Close returns to the grid,
	# which has not moved. The categories are tabs above the scrolling page.
	var scroll: ScrollContainer = club.pages.binder.get_parent()
	var grid_y: float = club.binder_grid.global_position.y - scroll.scroll_vertical
	var chosen: Control = club.entry_button("charm.encore")
	_check(club.binder_preview.visible and club.binder_preview.is_ancestor_of(club.binder_detail) and club.binder_preview.is_ancestor_of(club.binder_art)
		and club.preview_close.has_focus(), "the tapped card opens in the preview, its picture and history over the page")
	_check(club.binder_tabs.visible and club.binder_tabs.get_global_rect().end.y <= scroll.global_position.y + 1.0 and club.filter_button("charm").button_pressed,
		"the categories are tabs above the scrolling page, Charms chosen")
	_check(chosen.global_position.x - 3.0 >= scroll.global_position.x and chosen.get_global_rect().end.x + 3.0 <= scroll.get_global_rect().end.x,
		"the page's edges leave room for the chosen card's ring: %s in %s" % [str(chosen.get_global_rect()), str(scroll.get_global_rect())])
	await _capture("clubhouse_preview")
	await _focus_accept(club.preview_close)
	_check(not club.binder_preview.visible and chosen.has_focus(), "Close returns to the chosen card")
	var other: Dictionary = await _card("charm.flat_bonus")
	_check(other.state != "locked" and club.selected_item == "charm.flat_bonus" and club.binder_detail.text != "" and club.binder_preview.visible,
		"choosing another card opens its preview")
	_check(is_equal_approx(club.binder_grid.global_position.y - scroll.scroll_vertical, grid_y), "the grid does not move")
	await _focus_accept(club.preview_close)
	# A finger that lands on a card and drags scrolls the page: the cards pass the drag
	# on, never tilt, and a press that ended in a scroll opens nothing.
	var card: Control = club.entry_button("charm.flat_bonus")
	_check(card.mouse_filter == Control.MOUSE_FILTER_PASS and not card.tilt_enabled, "binder cards pass a drag to the page and do not tilt")
	card.button_down.emit()
	scroll.scroll_vertical += 120
	card.pressed.emit()
	_check(not club.binder_preview.visible and club.selected_item == "charm.flat_bonus", "a press that turned into a scroll opens no preview")
	scroll.scroll_vertical = 0
	encore = await _card("charm.encore")
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
	await _ui9_scroll()

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
