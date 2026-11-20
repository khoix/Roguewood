extends SceneTree
## J06 stage 1 (E13): the production vertical slice through the real game, with
## touch and keyboard. Attempt 1 plays both Divisions of the House League:
## - Division 1: an Echo Ball strike retriggers the first pin it hits (explained in
##   the log); Charms are bought in the Pro Shop and reordered; The Surveyor's Dead
##   Straight disables spin (the assist control is locked, and a real circle-and-
##   flick gesture that charges spin is committed as a straight launch); beating
##   the Division 1 boss banks its first-clear reward at once and the attempt
##   continues to Division 2;
## - Division 2: the targets rise; The Custodian's Clean Sweep banks an open frame
##   as 0; the build's strike still beats the boss, which wins the League and banks
##   the second first-clear reward.
## Attempt 2 (New Attempt) carries the Career: both unlocks are in the new shop
## pool. Two open frames lose the opener, the Career survives, Clubhouse returns.
## Shots are the deterministic J03 assist throws. Run with --fixed-fps 60.
const Economy = preload("res://src/rules/economy.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
const STRIKE := [0.1, 0.0, 0.7]
const LEAVE := [-0.4, 0.0, 0.6]
const GUTTER := [0.8, 2.0, 0.6]
## Charms the journey buys when offered and affordable, best first: Mult Charms its
## straight House Ball strikes use, so the build's strike alone clears The Custodian's
## 2400 (Value-only Charms such as Head Pin would fill slots without getting there).
const WANTED := ["charm.finisher", "charm.flat_bonus", "charm.plumb_line", "charm.pin_counter", "charm.front_line", "charm.house_special", "charm.hot_streak",
	"charm.turkey_club"]
## Wallet fixture (logged, as J05 does) at the first shop: content batches keep adding
## items to the pool, so the build is bought through real rerolls with a budget that
## does not depend on which items the seeded stock happens to show.
const SHOP_BUDGET := 60
var _budget_granted := false
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control
var lab: Control

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func _wait_for(predicate: Callable, label: String, frames: int = 240) -> bool:
	for i in frames:
		if predicate.call():
			return true
		await process_frame
	if predicate.call():
		return true
	_check(false, "Timeout: " + label)
	return false

func _capture(label: String) -> void:
	print("J06 %s attempt=%d lab=%s division=%d match=%s score=%d money=%d charms=%s hud=%s" % [label, scene.session.get("attempt", 0), lab.state,
		lab.division.division_number(), lab.division.current().id, lab.division.match_score, lab.run.money,
		str(lab.run.charms.map(func(e): return e.item_id)), lab.hud.info.text])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

func _action(action: String, times: int = 1) -> void:
	for i in times:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame

## UI-5: what a player does first to reach a control that sits behind another:
## open the session menu or the shop's Sell sheet, or close a sheet that is in the way.
func _reach(control: Control) -> void:
	if scene == null: return
	if scene.session_menu.is_ancestor_of(control) and not scene.session_menu.visible:
		scene.menu_button.grab_focus()
		await _action("ui_accept")
	var shop: Control = scene.lab.shop_panel if scene.lab != null else null
	if shop == null or not shop.is_visible_in_tree(): return
	if shop.sell_sheet.is_ancestor_of(control):
		if not shop.sell_sheet.visible:
			shop.sell_open.grab_focus()
			await _action("ui_accept")
			await process_frame
	elif shop.sell_sheet.visible and not shop.sell_confirm_sheet.is_ancestor_of(control):
		shop.sell_close.grab_focus()
		await _action("ui_accept")
	if shop.offer_sheet.visible and not shop.offer_sheet.is_ancestor_of(control):
		shop.offer_back.grab_focus()
		await _action("ui_accept")

## UI-5b: a tapped offer opens large; a player then presses Buy (or Back when it
## cannot be bought).
func _confirm(control) -> void: # untyped: a pressed row may already be freed
	if scene == null or scene.lab == null or not is_instance_valid(control): return
	var shop: Control = scene.lab.shop_panel
	if shop.offer_sheet.visible and control in shop.offer_buttons:
		(shop.offer_back if shop.buy_button.disabled else shop.buy_button).grab_focus()
		await _action("ui_accept")
	# UI-12: a tap on a placement or Sell tile selects it; its Confirm finishes the tap.
	var pending: Button = shop.pending_confirm(control)
	if pending != null:
		pending.grab_focus()
		await _action("ui_accept")

## UI-29: from a result sheet to the next run. With awards waiting the sheet offers
## only Continue (the awards, then the Clubhouse), and Enter League starts the run.
func _new_run_from_result() -> void:
	if lab.hud.retry_button.visible:
		await _focus_accept(lab.hud.retry_button)
		return
	await _focus_accept(lab.hud.menu_button)
	await _through_awards()
	await _wait_for(func(): return scene.screen == "menu" and scene.lab == null, "the awards end in the Clubhouse", 400)
	await _focus_accept(scene.enter)

## UI-25: leaving a result sheet plays the run's waiting award ceremony first; a
## journey that is not about it goes through as a player can (Skip, then Continue).
func _through_awards() -> void:
	for i in 4: await process_frame
	if lab == null or not is_instance_valid(lab): return
	var ceremony = lab.get("award_ceremony")
	if ceremony == null or not ceremony.visible or not ceremony.playing: return
	await _focus_accept(ceremony.skip_button)
	await _wait_for(func(): return ceremony.step == "done" and not ceremony.continue_button.disabled, "Skip shows the awards summary", 120)
	await _focus_accept(ceremony.continue_button)

func _focus_accept(control: Control) -> void:
	await _reach(control)
	control.grab_focus()
	await _action("ui_accept")
	await _confirm(control)

func _tap(control: Control) -> void:
	# A player scrolls a control into view before tapping it (UI-3's portrait shop
	# scrolls under its pinned actions).
	await _reach(control)
	var scroll: Node = control.get_parent()
	while scroll != null and not (scroll is ScrollContainer): scroll = scroll.get_parent()
	if scroll != null and not (scroll as Control).get_global_rect().encloses(control.get_global_rect()):
		(scroll as ScrollContainer).ensure_control_visible(control)
		await process_frame
		await process_frame
	var at := root.get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _confirm(control)

## A finger-like mouse drag from one control to another (UI-32's Charm row).
func _drag_between(from: Control, to: Control) -> void:
	var start := from.get_global_rect().get_center()
	var end := to.get_global_rect().get_center()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = _window(start)
	event.global_position = event.position
	Input.parse_input_event(event)
	await process_frame
	for i in range(1, 13):
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.position = _window(start.lerp(end, i / 12.0))
		motion.global_position = motion.position
		motion.relative = (end - start) / 12.0
		Input.parse_input_event(motion)
		await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = _window(end)
	release.global_position = release.position
	Input.parse_input_event(release)
	for i in 4: await process_frame

func _shift_left() -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_LEFT
		key.physical_keycode = KEY_LEFT
		key.shift_pressed = true
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame
	for i in 3: await process_frame

func _window(canvas: Vector2) -> Vector2:
	return root.get_screen_transform() * canvas

func _touch(canvas: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = _window(canvas)
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func _drag(canvas: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = _window(canvas)
	event.relative = relative
	Input.parse_input_event(event)
	await process_frame

## J02's gesture: hold the ball, circle it clockwise (charging spin), flick up.
func _circle_throw(sweep_deg: float) -> Dictionary:
	await _aim()
	var count: int = lab.history.size()
	var radius := 20.0 # a small, fast swirl: 30 degrees a frame is 5 turns a second (E05-R2)
	var at: Vector2 = lab.ball_screen_position()
	var center := at + Vector2(0.0, -radius)
	await _touch(at, true)
	for i in int(absf(sweep_deg) / 30.0):
		var angle := deg_to_rad(90.0 + signf(sweep_deg) * 30.0 * (i + 1))
		var next := center + Vector2(cos(angle), sin(angle)) * radius
		await _drag(next, next - at)
		at = next
	_check(lab.state == "holding" and lab.charged_spin() == 0.0, "while holding under Dead Straight the spin meter stays at zero")
	for i in 8:
		at += Vector2(0, -32)
		await _drag(at, Vector2(0, -32))
	await _touch(at, false)
	_check(lab.state == "rolling", "the gesture throw commits")
	await _wait_for(func(): return lab.history.size() == count + 1, "gesture roll settles", ROLL_FRAMES)
	return lab.history[-1]

func _toggle_assist() -> void:
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)

func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	if steps != 0:
		await _action("ui_right" if steps > 0 else "ui_left", absi(steps))

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	_check(scene.content.id == "slice" and scene.league.get_item_text(0) == "House League" and scene.kit.get_item_text(0) == "House Kit", "the menu offers the slice League and kit")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "throw lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)
	_check(lab.run.money == 6 and lab.run.cards.size() == 6 and lab.run.loadout().pins.values().all(func(p): return p == "pin.wood")
		and lab.run.deck_cards().values().count("ball.echo") == 2, "the House Kit: ten Wood pins, two each of Hook, Hammer and Echo, $6")
	await _division_one()
	await _division_two()
	await _second_attempt()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty() and lab != null: await _capture("slice_failure")
	if failures.is_empty(): print("ROGUEWOOD_J06_STAGE1_OK")
	quit(0 if failures.is_empty() else 1)

func _aim() -> void:
	await _wait_for(func(): return (lab.state == "aim" and lab.lane.state == "ready") or (lab.state == "intro" and lab.hud.intro.visible), "aim", ROLL_FRAMES)
	if lab.state == "intro":
		# UI-8: a boss introduction waits for the player, who presses Begin.
		await _focus_accept(lab.hud.intro_button)
		await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim after the introduction", ROLL_FRAMES)

## An assist throw; spin is left as it is unless given.
func _throw(shot: Array, spin: float = 0.0, set_spin: bool = true) -> Dictionary:
	await _aim()
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, shot[0])
	await _slide(panel.aim_slider, shot[1])
	await _slide(panel.power_slider, shot[2])
	if set_spin:
		await _slide(panel.spin_slider, spin)
	var count: int = lab.history.size()
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling", "Throw commits")
	await _wait_for(func(): return lab.history.size() == count + 1, "roll settles", ROLL_FRAMES)
	return lab.history[-1]

func _scored() -> Dictionary:
	await _wait_for(func(): return lab.state == "scoring", "scoring", ROLL_FRAMES)
	await _focus_accept(lab.score_panel)
	await _wait_for(func(): return lab.state == "frame_done", "frame done", ROLL_FRAMES)
	return lab.scored_frames[-1]

func _log_lines() -> Array:
	return lab.score_panel.log_list.get_children().map(func(c): return c.text)

## Strikes until the match is over; returns the last scored frame.
func _strike_out() -> Dictionary:
	var scored := {}
	while true:
		await _throw(STRIKE)
		scored = await _scored()
		if scored.match_over:
			return scored
		await _focus_accept(lab.next_rack)
	return scored

## Arms the first hand card of an item (a real tap on its card button).
func _arm(item_id: String) -> bool:
	for option in lab.equipment.options():
		if option.item_id == item_id:
			await _tap(lab.card_hand.button_for(option.uid))
			return lab.armed_ball_id() == item_id
	return false

## Buys wanted Charms that are on offer and affordable, by tapping their offers, and
## rerolls (real taps) while slots are free and the budget allows.
func _buy_charms() -> Array:
	if not _budget_granted:
		_budget_granted = true
		lab.run.credit(SHOP_BUDGET, "fixture: journey shop budget")
		lab._refresh_shop()
		print("J06 fixture: $%d granted at the first shop; the build is bought through real offers and rerolls" % SHOP_BUDGET)
	var bought: Array = []
	for visit in 12:
		for wanted in WANTED:
			for index in lab.shop.offers.size():
				var offer: Dictionary = lab.shop.offers[index]
				if offer.item_id == wanted and not offer.sold and offer.price <= lab.run.money and lab.run.charms.size() < 5:
					var before: int = lab.run.money
					await _tap(lab.shop_panel.button_for_offer(index))
					await process_frame
					_check(lab.shop.offers[index].sold and lab.run.money == before - offer.price, "bought %s for $%d" % [wanted, offer.price])
					bought.append(wanted)
		if lab.run.charms.size() >= 5 or lab.run.money < lab.shop.reroll_cost(lab.run) + 8:
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	return bought

func _to_shop(label: String) -> void:
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "shop", label + " shop")

func _leave_shop() -> void:
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state in ["aim", "intro"], "next match", ROLL_FRAMES)

func _division_one() -> void:
	_check(lab.hud.info.text.contains("D1/2 · Opener 1/3 · Target 300") and lab.hud.badge.text.contains("The Surveyor"), "the HUD shows Division 1 of 2 and previews its boss")
	await _tap(lab.hud.badge)
	_check(lab.hud.rule_text.text.contains("Dead Straight") and lab.hud.rule_text.text.contains("target 800") and lab.hud.rule_text.text.contains("Encore"),
		"the badge shows The Surveyor's rule, target and reward")
	await _tap(lab.hud.badge)
	await _capture("slice_preview")
	# Opener: the Echo Ball's strike retriggers the first pin it knocked down.
	_check(await _arm("ball.echo"), "an Echo Ball card arms from the hand")
	var roll := await _throw(STRIKE)
	_check(roll.launch.ball_id == "ball.echo" and roll.roll_result.fallen_positions.size() == 10, "the Echo Ball strikes")
	var echo := await _scored()
	_check(echo.banked == (40 + 100 + 10) * 4 and _log_lines().any(func(l): return l.contains("(retrigger 1 · Roll 1 Echo Ball)")),
		"Echo repeats one Wood pin: 600, explained in the log")
	_check(echo.match_over and echo.match_won and lab.next_rack.text == "Collect & Shop", "600 wins the 300 opener in one frame")
	await _capture("slice_echo")
	await _to_shop("opener")
	_check(lab.shop_panel.preview.text.contains("Next: Division 1 Feature — target 500") and lab.shop_panel.preview.text.contains("Boss later: The Surveyor (Dead Straight"),
		"the shop previews the feature and the Division's boss")
	var first: Array = await _buy_charms()
	await _leave_shop()
	await _strike_out()
	_check(lab.division.results[-1].won and lab.division.results[-1].kind == "feature", "the feature is won")
	await _to_shop("feature")
	_check(lab.shop_panel.preview.text.contains("Next: Division 1 Boss — target 800") and lab.shop_panel.preview.text.contains("The Surveyor: Dead Straight")
		and lab.shop_panel.preview.text.contains("First clear: Encore"), "the shop previews The Surveyor's rule and reward before buying")
	first.append_array(await _buy_charms())
	print("J06 bought in Division 1: %s" % str(first))
	if lab.run.charms.size() >= 2:
		# UI-32 (owner, 2026-11-20): the Inventory's Charm row reorders by drag and drop.
		var shop = lab.shop_panel
		var order: Array = lab.run.charms.map(func(e): return e.item_id)
		await _focus_accept(shop.sell_open)
		await process_frame
		_check(shop.sell_sheet.visible and shop.sell_title.text == "Inventory" and shop.charm_row.get_child_count() == order.size()
			and shop.charm_tile(1).get_meta("ref") == "charm:1" and shop.charm_tile(1).get_global_rect().end.y <= shop.owned_list.get_global_rect().position.y + 1.0,
			"Inventory opens on the Charms in scoring order, above the other items")
		var row: Rect2 = shop.charm_row.get_global_rect()
		_check(row.position.x >= shop.sell_sheet.get_global_rect().position.x and row.end.x <= shop.sell_sheet.get_global_rect().end.x,
			"every Charm fits the row (%s)" % str(row))
		await _capture("slice_inventory")
		await _drag_between(shop.charm_tile(2), shop.charm_tile(1))
		_check(lab.run.charms[0].item_id == order[1] and lab.run.charms[1].item_id == order[0] and shop.message.text.contains("Moved") and shop.sell_sheet.visible
			and not shop.sell_confirm_sheet.visible, "dragging Charm 2 onto Charm 1 swaps them, without opening it, and the Inventory stays open")
		var last := order.size()
		await _drag_between(shop.charm_tile(1), shop.charm_tile(last))
		var moved: Array = lab.run.charms.map(func(e): return e.item_id)
		_check(moved[last - 1] == order[1] and moved[0] == order[0], "a Charm dragged onto the last slot goes last; the rest close up (%s)" % str(moved))
		# Keyboard and gamepad: Shift+Left moves the focused Charm (here back to its place).
		for i in range(last, 1, -1):
			shop.charm_tile(i).grab_focus()
			await _shift_left()
		var back: Array = lab.run.charms.map(func(e): return e.item_id)
		_check(back == order.slice(1, 2) + order.slice(0, 1) + order.slice(2), "Shift+Left moves the focused Charm one slot left (%s)" % str(back))
		shop.charm_tile(2).grab_focus()
		await _shift_left()
		_check(lab.run.charms.map(func(e): return e.item_id) == order, "and back to the bought order: additions stay first")
		await _focus_accept(shop.sell_close)
	await _capture("slice_shop")
	await _leave_shop()
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, "The Surveyor's introduction")
	_check(lab.hud.intro_title.text.contains("The Surveyor") and lab.hud.intro_body.text.contains("Dead Straight") and lab.hud.intro_body.text.contains("Posted target 800"),
		"the introduction names The Surveyor, the rule and the target")
	await _focus_accept(lab.hud.intro_button)
	await _aim()
	# Dead Straight: the assist spin control is locked...
	_check(lab.spin_disabled() and not lab.assist_panel.spin_slider.editable and lab.status.text.contains("Spin is disabled"),
		"Dead Straight: the spin control is disabled and the status says so")
	await _slide(lab.assist_panel.spin_slider, 0.5)
	_check(lab.assist_panel.spin_slider.value == 0.0, "the disabled spin control ignores input")
	_check(lab.hud.info.text.contains("The Surveyor · D1/2 · Boss 3/3 · Target 800") and lab.hud.badge.text.contains("Dead Straight"), "the boss HUD shows rival, Division, target and rule")
	await _capture("slice_dead_straight")
	# ...and a real gesture that charges spin is committed straight.
	await _toggle_assist()
	var straight := await _circle_throw(720.0)
	_check(straight.launch.spin == 0.0 and absf(lab.trials[-1].input.spin) >= 0.25 and lab.trials[-1].curved == false,
		"a charged circle gesture is committed with zero spin (%.2f charged)" % lab.trials[-1].input.spin)
	await _toggle_assist()
	await _wait_for(func(): return lab.state in ["aim", "scoring"], "after the gesture roll", ROLL_FRAMES)
	# UI-20: the House League has no celebration art yet, so nothing has played. For the
	# boss win, the journey supplies The Surveyor's two (the placeholder) to check the flow.
	_check(lab.alley_screen.played.is_empty() and not lab.alley_screen.has_art("strike"), "no celebration plays before the League has art")
	var placeholder := "res://src/presentation/alley_screen_placeholder.gd"
	lab.alley_screen.variants_override = {"boss_defeated": {"rival.surveyor": [placeholder, placeholder]}}
	if lab.state == "aim":
		await _throw(STRIKE)
	var boss := await _scored()
	while not boss.match_over:
		await _focus_accept(lab.next_rack)
		await _throw(STRIKE)
		if lab.state != "scoring" and not lab.history[-1].knockdown_log.standing.is_empty():
			await _throw(STRIKE)
		boss = await _scored()
	var alley: Control = lab.alley_screen
	_check(alley.playing() and alley.current_event == "boss_defeated" and alley.current_context.rival_id == "rival.surveyor"
		and alley.current_context.rival_name == "The Surveyor" and alley.current_path == placeholder, "beating the boss plays its celebration, naming The Surveyor")
	_check(not lab.next_rack.visible, "Division Result waits for the boss celebration")
	await _capture("celebration_boss")
	await _wait_for(func(): return not alley.playing() and lab.next_rack.visible, "the boss celebration ends, then the button appears", 300)
	_check(lab.next_rack.visible and lab.next_rack.has_focus() and not alley.visible, "after the celebration, the button appears with focus")
	alley.variants_override = {}
	_check(boss.match_won and lab.division.division_cleared() and lab.division.outcome == "" and lab.next_rack.text == "Division Cleared · Shop",
		"beating The Surveyor clears Division 1; the attempt continues")
	await _to_shop("division cleared")
	_check(lab.shop_panel.message.text.contains("The Surveyor defeated — Division 1 cleared! First clear: Encore"), "the shop announces the clear and its reward")
	_check(scene.career.first_clears.has("rival.surveyor") and "gate.surveyor_cleared" in scene.career.unlocked and "gate.surveyor_cleared" not in lab.shop.unlocked,
		"the first clear is in the Career at once; this attempt's pool is unchanged")
	_check(lab.shop_panel.preview.text.contains("Next: Division 2 Opener — target 1100") and lab.shop_panel.preview.text.contains("Boss later: The Custodian (Clean Sweep"),
		"the shop previews Division 2 and its boss")
	await _capture("slice_cleared")
	# Save and resume mid-League: the shop after the clear is saved (slice content,
	# attempt v2); Clubhouse and Continue Attempt rebuild it from disk.
	var saved: Dictionary = scene.store.read("attempt")
	_check(saved.ok and saved.schema_version == 2 and saved.payload.content_set == "slice" and saved.payload.phase == "shop"
		and saved.payload.division.index == 0 and saved.payload.division.current.outcome == "won", "the cleared Division's shop is saved as a slice attempt")
	var money: int = lab.run.money
	var offers: Array = lab.shop.offers.duplicate(true)
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible and scene.continue_button.has_focus(), "Continue Attempt offered")
	_check(scene.continue_button.text == "Continue Run 1 · match 3", "the menu offers the saved slice attempt")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "shop", "the attempt resumes in the shop")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.run.money == money and lab.shop.offers == offers and lab.division.division_cleared() and lab.shop_panel.preview.text.contains("Division 2 Opener"),
		"the resumed shop has the same money, offers and next Division")
	await _buy_charms()

func _division_two() -> void:
	await _leave_shop()
	_check(not lab.spin_disabled() and lab.assist_panel.spin_slider.editable and lab.division.division_number() == 2
		and lab.hud.info.text.contains("D2/2 · Opener 1/3 · Target 1100"), "Division 2 starts with spin restored")
	await _strike_out()
	_check(lab.division.results[-1].won, "Division 2's opener is won with strikes")
	await _to_shop("division 2 opener")
	await _buy_charms()
	await _leave_shop()
	var feature := await _strike_out()
	print("J06 Division 2 feature: %s %d/%d" % ["won" if feature.match_won else "lost", lab.division.match_score, lab.division.target()])
	_check(feature.match_won, "Division 2's feature is won with the bought Charms")
	await _to_shop("division 2 feature")
	_check(lab.shop_panel.preview.text.contains("The Custodian: Clean Sweep") and lab.shop_panel.preview.text.contains("target 2400"), "the shop previews The Custodian")
	await _buy_charms()
	await _leave_shop()
	await _wait_for(func(): return lab.state == "intro", "The Custodian's introduction")
	await _focus_accept(lab.hud.intro_button)
	_check(lab.hud.info.text.contains("The Custodian · D2/2 · Boss 3/3 · Target 2400"), "the Custodian's boss HUD")
	var leave := await _throw(LEAVE)
	_check(not leave.knockdown_log.standing.is_empty(), "the leave leaves pins")
	await _aim()
	await _throw(GUTTER)
	var open := await _scored()
	_check(open.result.category == "open" and open.result.score > 0 and open.banked == 0 and _log_lines().any(func(l): return l.contains("Clean Sweep: An open frame banks nothing")),
		"Clean Sweep banks the open frame as 0 and says so")
	await _capture("slice_clean_sweep")
	await _focus_accept(lab.next_rack)
	await _throw(STRIKE)
	var last := await _scored()
	print("J06 Custodian: %d/%d" % [lab.division.match_score, lab.division.target()])
	_check(last.match_over and last.match_won and lab.division.outcome == "won" and lab.next_rack.text == "Division Result",
		"the bought build's strike alone beats The Custodian's 2400")
	# UI-22: the award ceremony, in full motion (the journey plays with Reduced Motion on).
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "victory screen")
	# UI-25 (owner, 2026-11-19): the result sheet comes first; the ceremony waits for
	# the player to leave it.
	for i in 30: await process_frame
	_check(not lab.award_ceremony.visible and lab.awards_pending(), "the result sheet comes first, the awards waiting")
	# UI-29 (owner, 2026-11-19): the award screen ends in the Clubhouse, so the sheet
	# offers one way on, Continue; no New Run that would skip past it into a run.
	_check(not lab.hud.retry_button.visible and lab.hud.menu_button.visible and lab.hud.menu_button.text == "Continue" and lab.hud.menu_button.has_focus(),
		"with awards waiting the sheet offers only Continue")
	_check(lab.hud.result_title.text.contains("The Custodian defeated — House League cleared!") and lab.hud.result_body.text.contains("First clear: Standing Order")
		and lab.hud.result_body.text.contains("D1 Boss") and lab.hud.result_body.text.contains("D2 Boss"), "the League victory lists both Divisions and banks the reward")
	_check(scene.career.first_clears.has("rival.custodian") and scene.career.first_clears.has("rival.surveyor") and scene.session.outcome == "won"
		, "both first clears are in the Career")
	await _capture("slice_won")

func _second_attempt() -> void:
	await _focus_accept(lab.hud.menu_button)
	# UI-25 and UI-29: Continue plays the award ceremony; it then fades out to the
	# Clubhouse (never straight into a run), and Enter League starts the next run.
	await _award_ceremony()
	await _wait_for(func(): return scene.transition_playing(), "the fade out after the awards", 30)
	await _wait_for(func(): return scene.screen == "menu" and scene.lab == null, "the awards end in the Clubhouse", 400)
	_check(scene.clubhouse.visible and not scene.transition_playing(), "after the award screen the Clubhouse, not a new run")
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "Enter League starts attempt 2")
	lab = scene.lab
	_check(lab.career_attempt == 2 and lab.division.division_number() == 1 and lab.run.money == Economy.STARTING_MONEY and lab.run.charms.is_empty(), "attempt 2 starts over at Division 1")
	_check("gate.surveyor_cleared" in lab.shop.unlocked and "gate.custodian_cleared" in lab.shop.unlocked and lab.hud.rule_text.text.contains("already cleared"),
		"both unlocks join attempt 2's shop pool")
	for frame in 2:
		await _throw(LEAVE)
		await _aim()
		await _throw(GUTTER)
		await _scored()
		if frame == 0:
			await _focus_accept(lab.next_rack)
	_check(lab.division.outcome == "lost" and lab.division.results[0].score < 300, "two open frames lose the opener")
	# UI-22: Reduced Motion back on (as the journey plays) for the loss's ceremony.
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "loss screen")
	var ceremony: Control = lab.award_ceremony
	for i in 30: await process_frame
	var pending: bool = lab.awards_pending()
	_check(not ceremony.visible, "the loss's result sheet comes first (UI-25)")
	print("J06 loss ceremony: %s" % ("waiting" if pending else "none"))
	_check(lab.hud.result_body.text.contains("Career progress kept: 2 rival(s) cleared") and lab.hud.retry_button.text == "Retry League", "a later loss keeps both first clears")
	await _capture("slice_lost_again")
	# UI-25 (owner, 2026-11-19): Clubhouse leaves the result sheet; the ceremony plays
	# first, then the run fades out (UI-23), and the Clubhouse appears without a fade.
	await _focus_accept(lab.hud.menu_button)
	if pending:
		await _wait_for(func(): return ceremony.visible and ceremony.playing, "Clubhouse opens the waiting ceremony")
		_check(scene.exiting and not scene.transition_playing() and not scene.menu_button.visible, "the ceremony plays before any fade, the menu out of reach")
		# Only goal progress: a quieter PROGRESS ceremony, and under Reduced Motion no
		# travelling effects at all.
		_check(ceremony.awards.trophies.is_empty() and ceremony.title.text == "PROGRESS", "a run that only moved goals opens on PROGRESS")
		await _wait_for(func(): return ceremony.step == "done", "the progress ceremony ends", 600)
		_check(not ceremony.cues.has("drumroll") and not ceremony.cues.has("launch") and ceremony.fx.bursts == 0 and ceremony.fx.confetti_shots == 0
			and ceremony.fx.airborne() == 0 and ceremony.fx.shells == 0 and ceremony.show_cues.is_empty(), "no travelling effects under Reduced Motion, the show included (%s)" % str(ceremony.cues))
		_check(ceremony.awards.goals.all(func(g): return g.completed or g.scope == "career"), "UI-31: only real progress (no within-run goal that starts over)")
		await _focus_accept(ceremony.continue_button)
	var start := Engine.get_process_frames()
	await _wait_for(func(): return scene.transition_playing(), "the fade out starts", 30)
	_check(scene.exiting and scene.curtain.mouse_filter == Control.MOUSE_FILTER_STOP and lab.input_paused and (ceremony.visible == pending),
		"the run fades out after the ceremony, which stays under the fade, and takes no input")
	for i in 45: await process_frame
	_check(scene.curtain.color.a > 0.3 and scene.curtain.color.a < 0.75 and lab.motion.sound.fade < 0.75 and lab.motion.sound.fade > 0.25,
		"the screen and the run's music fade out together (%.2f, %.2f)" % [scene.curtain.color.a, lab.motion.sound.fade])
	if pending:
		_check(ceremony.has_music() and ceremony.music.volume_db < scene.Soundtrack.level_db(lab.settings) - 3.0, "the awards music fades with it (%.1f dB)" % ceremony.music.volume_db)
	await _wait_for(func(): return scene.screen == "menu" and scene.lab == null, "Clubhouse returns to the menu", 400)
	var seconds := float(Engine.get_process_frames() - start) / 60.0
	_check(not scene.transition_playing() and scene.curtain.color.a == 0.0 and not scene.exiting, "no fade into the Clubhouse: it is there at once")
	_check(scene.clubhouse_music == null or (scene.clubhouse_music.playing and absf(scene.clubhouse_music.volume_db - scene.Soundtrack.level_db(scene.throw_settings)) < 0.01),
		"the Clubhouse music starts at its level")
	_check(seconds >= 1.5 and seconds <= 1.95, "the fade out takes %.2f s (UI-31: 1.65, half of 3.3)" % seconds)
	_check(scene.career.first_clears.has("rival.surveyor"), "the Career outlives the session")
	lab = null

## UI-22: the League win's award ceremony: each new trophy with its own Clubhouse
## art, the effects and their sounds, the goals, Skip and Continue. UI-25: it plays
## when the player leaves the result sheet (here by New Run).
func _award_ceremony() -> void:
	var ceremony: Control = lab.award_ceremony
	var Art = preload("res://src/clubhouse/clubhouse_art.gd")
	await _wait_for(func(): return ceremony.visible and ceremony.playing, "Continue opens the waiting ceremony")
	_check(ceremony.visible and ceremony.playing and not lab.settings.reduced_motion and lab.hud.result.visible, "the award ceremony opens over the result sheet, in full motion")
	var ids: Array = ceremony.awards.trophies.map(func(t): return t.id)
	_check(ids.slice(0, 3) == ["league.house", "rival.custodian", "rival.surveyor"] or ids.slice(0, 3) == ["league.house", "rival.surveyor", "rival.custodian"],
		"it presents the House title first, then both rivals' plaques (%s)" % str(ids))
	_check(ceremony.title.text == "AWARDS", "a run that earned trophies opens on AWARDS")
	# The owner's awards track loops under the ceremony; the League's music steps aside.
	_check(ceremony.has_music() and ceremony.music.stream.resource_path == "res://assets/audio/music/awards.ogg" and ceremony.music.stream.loop,
		"the ceremony plays the owner's looping awards track")
	await _wait_for(func(): return lab.motion.sound.duck < 0.2, "the League's music steps aside for it", 120)
	# The first trophy: a drumroll under the gathering sunburst, then the reveal.
	await _wait_for(func(): return ceremony.step == "trophy" and "reveal" in ceremony.cues, "the first trophy is revealed", 600)
	var first: Dictionary = ceremony.awards.trophies[0]
	_check(ceremony.stage_art.texture != null and ceremony.stage_art.texture.resource_path == Art.path_for(first.asset) and Art.has_art(first.asset),
		"the trophy shown is its own Clubhouse art (%s)" % first.asset)
	_check(ceremony.stage_kicker.text == "LEAGUE CHAMPION!" and ceremony.stage_name.text == first.name, "the title is announced by name")
	_check(ceremony.cues.slice(0, 3) == ["whoosh", "rocket", "rocket"] and "drumroll" in ceremony.cues, "the opening whoosh and bottle rockets, then a drumroll (%s)" % str(ceremony.cues))
	await _wait_for(func(): return ceremony.fx.bursts > 0 and "burst" in ceremony.cues and ceremony.fx.confetti_shots > 0, "fireworks and confetti, with their sounds", 300)
	# UI-31: the show runs from the start: shells of several kinds, confetti falling
	# from the top and streamers, with their own sounds.
	await _wait_for(func(): return ceremony.fx.shells >= 3 and "burst" in ceremony.show_cues, "the continuous show is under way", 600)
	_check(ceremony.fx.show_on and ceremony.fx._stream != null and ceremony.fx._stream.emitting and ceremony.fx._streamers.size() == ceremony.fx.STREAMERS,
		"confetti falls from the top and streamers drift the whole time")
	for i in 6: await process_frame
	await _capture("awards_trophy")
	# A tap hurries the moment along; Skip goes straight to the summary.
	var at: Vector2 = root.get_screen_transform() * ceremony.get_global_rect().get_center()
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = at
		touch.pressed = pressed
		Input.parse_input_event(touch)
		await process_frame
	await _wait_for(func(): return ceremony.shown_trophies.size() >= 2, "a tap moves on to the next trophy", 240)
	await _focus_accept(ceremony.skip_button)
	_check(ceremony.step == "done" and ceremony.continue_button.has_focus() and not ceremony.skip_button.visible, "Skip goes to the summary, with Continue ready")
	for t in ceremony.awards.trophies:
		_check(ceremony.shelf.get_node_or_null("Shelf_" + String(t.id).replace(".", "_")) != null, "the shelf holds %s" % t.name)
	for g in ceremony.awards.goals:
		var row: Dictionary = ceremony.goal_rows.get(g.id, {})
		_check(not row.is_empty() and is_equal_approx(row.bar.value, float(g.after)) and row.stamp.visible == g.completed,
			"the goal %s stands at %d of %d" % [g.name, g.after, g.threshold])
	_check(ceremony.awards.goals.all(func(g): return g.completed or g.scope == "career"), "UI-31: only real progress (no within-run goal that starts over)")
	# UI-31: the fireworks keep going on the summary, for as long as it is up.
	var shells: int = ceremony.fx.shells
	var heard: int = ceremony.show_cues.size()
	for i in 150: await process_frame
	_check(ceremony.fx.show_on and ceremony.fx.shells >= shells + 3 and ceremony.show_cues.size() > heard and ceremony.fx.alive_bursts() > 0,
		"the fireworks keep going on the summary (%d → %d shells)" % [shells, ceremony.fx.shells])
	await _capture("awards_summary")
	await _focus_accept(ceremony.continue_button)
	_check(not ceremony.playing and ceremony.hold, "Continue ends the ceremony; its last screen stays under the fade")
	_check(ceremony.fx.show_on, "the show goes on under the fade")
