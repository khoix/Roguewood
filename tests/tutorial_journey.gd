extends SceneTree
## JTUT (UI-13): "Learn to Bowl" through the real game with touch input, from the
## Clubhouse menu's How to Play to the last card:
##   welcome -> aim (a tap on the lane) -> throw (hold, swirl, flick) -> scoring ->
##   Next Rack -> cards (a tap on a card) -> the match target -> a second throw ->
##   collect -> the Pro Shop -> buy the fixed pin modification -> place it on the
##   rack map and Confirm -> Sell and Done -> the boss badge -> "You're ready".
## Checks that each step spotlights what it teaches and shows the hand where the
## gesture goes, that explain-only steps keep the lane still, that the practice
## lane is fixed (kit, cards, first shop) and that nothing reaches the Career or
## the saves. Then Skip from a second How to Play, and reduced motion's still hand.
## Run with --fixed-fps 60 (tools/qa.py).
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control
var lab: Control
var coach: CanvasLayer

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func _wait_for(predicate: Callable, label: String, frames: int = 300) -> bool:
	for i in frames:
		if predicate.call(): return true
		await process_frame
	if predicate.call(): return true
	_check(false, "Timeout: " + label)
	return false

func _capture(label: String) -> void:
	print("JTUT %s screen=%s step=%s lab=%s" % [label, scene.screen, coach.current_id() if is_instance_valid(coach) else "-", lab.state if is_instance_valid(lab) else "-"])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot save screenshot: " + label)

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

func _tap_at(canvas: Vector2) -> void:
	await _touch(canvas, true)
	await _touch(canvas, false)
	await process_frame

func _tap(control: Control) -> void:
	_check(control != null and control.is_visible_in_tree(), "tap target visible: %s" % (control.name if control != null else "null"))
	if control == null: return
	await _tap_at(control.get_global_rect().get_center())

func _px() -> float:
	return minf(lab.size.x, lab.size.y) / 720.0

## Holds the ball, swirls one turn about it, then flicks up (the tutorial's gesture).
func _swirl_throw() -> void:
	var radius := 40.0 * _px()
	var at: Vector2 = lab.ball_screen_position()
	var center := at + Vector2(0.0, -radius)
	await _touch(at, true)
	for i in int(360.0 / 21.0):
		var angle := deg_to_rad(90.0 + 21.0 * (i + 1))
		var next := center + Vector2(cos(angle), sin(angle)) * radius
		await _drag(next, next - at)
		at = next
	# Owner (2026-11-17): while the player swirls, the lane is clear: no dimming, no hand.
	if is_instance_valid(coach) and coach.current_id() == "throw":
		_check(lab.state == "holding" and coach.dims.all(func(d): return not d.visible) and coach._quiet(coach.steps[coach.step]),
			"while the ball is held the lane is clear (no dimming, no hand)")
	for i in 8:
		at += Vector2(0, -32) * _px()
		await _drag(at, Vector2(0, -32) * _px())
	await _touch(at, false)

## A straight flick from the ball.
func _flick() -> void:
	var at: Vector2 = lab.ball_screen_position()
	await _touch(at, true)
	for i in 8:
		at += Vector2(0, -32) * _px()
		await _drag(at, Vector2(0, -32) * _px())
	await _touch(at, false)

## After a roll that leaves pins, the coach asks for the second roll (no dimming);
## after a strike it skips that step.
func _second_roll(id: String) -> void:
	await _wait_for(func(): return lab.state in ["scoring", "frame_done"] or (lab.state == "aim" and lab.roll_index == 2 and lab.lane.state == "ready"), "the roll settles", ROLL_FRAMES)
	if lab.state == "aim":
		await _step(id)
		_check(coach.dims.all(func(d): return not d.visible) and not lab.input_paused, "%s: the second roll is the player's, no dimming" % id)
		if id == "spare": await _capture("tut_spare")
		await _flick()
		await _wait_for(func(): return lab.state in ["scoring", "frame_done"], "the second roll scores", ROLL_FRAMES)

## A ball slid to the right edge and flicked: a gutter (J02's gesture).
func _gutter() -> void:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready" and not lab.input_paused, "ready for a gutter ball", ROLL_FRAMES)
	var at: Vector2 = lab.ball_screen_position()
	await _touch(at, true)
	for i in 6:
		at += Vector2(260, 0) * _px() / 6.0
		await _drag(at, Vector2(260, 0) * _px() / 6.0)
	for i in 8:
		at += Vector2(10, -30) * _px()
		await _drag(at, Vector2(10, -30) * _px())
	await _touch(at, false)
	await _wait_for(func(): return lab.state != "rolling" and lab.state != "aim" or (lab.state == "aim" and lab.roll_index == 2 and lab.lane.state == "ready"), "the gutter ball settles", ROLL_FRAMES)

## Losing the practice opener: the coach offers a fresh lane, which starts again at Aim.
func _lose_and_retry() -> void:
	await _tap(scene.club_menu_button)
	await _tap(scene.club_menu_list.get_node("ClubTutorial"))
	await _wait_for(func(): return scene.coach != null and scene.coach.card_ready(), "How to Play, to lose")
	coach = scene.coach
	lab = scene.lab
	await _tap(coach.next_button) # welcome
	await _step("target")
	await _tap(coach.next_button)
	await _step("cards")
	await _tap(coach.next_button)
	await _step("aim")
	await _tap_at(coach._aim_point())
	await _step("throw")
	for frame in 2:
		await _gutter()
		await _gutter()
		await _wait_for(func(): return lab.state in ["scoring", "frame_done"], "a gutter frame scores", ROLL_FRAMES)
		if frame == 0:
			await _step("scoring")
			await _tap(coach.next_button)
			await _step("next_rack")
			await _tap(lab.next_rack)
	await _wait_for(func(): return coach.current_id() == "lost" and coach.card_ready(), "losing the opener offers a fresh lane", ROLL_FRAMES)
	_check(lab.division.outcome == "lost" and coach.next_button.text == "Try Again" and coach.skip_button.visible, "the lost card offers Try again or Skip (%d of %d)" % [lab.division.match_score, lab.division.target()])
	await _capture("tut_lost")
	await _tap(coach.next_button)
	await _wait_for(func(): return scene.coach != null and scene.coach != coach and scene.lab != lab and scene.coach.card_ready(), "Try again deals a fresh practice lane")
	coach = scene.coach
	lab = scene.lab
	_check(coach.current_id() == "aim" and scene.content.id == "tutorial" and lab.division.match_score == 0 and lab.division.outcome == "", "the fresh lane starts again at Aim (%s)" % coach.current_id())
	await _tap(coach.skip_button)
	await _wait_for(func(): return scene.screen == "menu" and scene.coach == null, "Skip after a retry returns to the Clubhouse")

func _step(id: String) -> bool:
	return await _wait_for(func(): return is_instance_valid(coach) and coach.current_id() == id and coach.card_ready(), "the tutorial shows step " + id, ROLL_FRAMES)

## The spotlight: the hole frames the control, and the panes leave it uncovered.
func _spotlit(control: Control, label: String) -> void:
	var hole: Rect2 = coach._hole
	_check(control != null and hole.has_area() and hole.grow(2.0).encloses(control.get_global_rect().intersection(Rect2(Vector2.ZERO, lab.size))),
		"%s: the spotlight frames it (%s around %s)" % [label, str(hole), str(control.get_global_rect()) if control != null else "-"])
	_check(coach.dims.filter(func(d): return d.visible).size() == 4 and not coach.dims.any(func(d): return d.visible and d.get_global_rect().intersects(hole.grow(-2.0))),
		"%s: the screen is dimmed around it, not over it" % label)

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.screen == "menu" and scene.enter.has_focus(), "menu focus")
	var career_before: Dictionary = scene.career.duplicate(true)
	# How to Play, from the Clubhouse menu.
	await _tap(scene.club_menu_button)
	_check(scene.club_menu.visible and scene.club_menu_list.get_node("ClubTutorial").text == "How to Play", "the Clubhouse menu offers How to Play")
	await _tap(scene.club_menu_list.get_node("ClubTutorial"))
	await _wait_for(func(): return scene.screen == "session" and scene.coach != null, "the tutorial opens")
	lab = scene.lab
	coach = scene.coach
	lab.trial_log_path = ""
	_check(scene.content.id == "tutorial" and lab.content.id == "tutorial" and lab.save_store == null and lab.career != scene.career
		and lab.content.kit.deck.count("ball.hook") == 2 and lab.run.money == 10,
		"the practice lane: the tutorial set, its fixed kit, a throwaway Career and no saves")
	_check(lab.league_theme != null, "the practice lane wears the House theme")
	await _step("welcome")
	_check(coach.counter.text == "Step 1 of 13", "the main steps are numbered (%s)" % coach.counter.text)
	_check(coach.next_button.visible and coach.skip_button.visible and coach.dims.filter(func(d): return d.visible).size() == 1 and lab.input_paused,
		"the welcome dims the whole screen, offers Next and Skip, and holds the lane still")
	await _capture("tut_welcome")
	await _tap(coach.next_button)
	# The match's target, then the cards, before the first throw.
	await _step("target")
	_spotlit(lab.hud.bar, "target")
	_check(coach.body.text.contains("%d points in %d frames" % [lab.division.target(), lab.division.frames_per_match()]), "the target step names this match's target and frames")
	await _capture("tut_target")
	await _tap(coach.next_button)
	await _step("cards")
	_spotlit(lab.card_hand, "cards")
	_check(lab.input_paused, "the lane stays still while the cards are explained")
	await _capture("tut_cards")
	var card: Control = null
	for button in lab.card_hand.buttons.values():
		if button.is_visible_in_tree():
			card = button
			break
	await _tap(card)
	_check(not String(lab.armed_ball).is_empty(), "a tap on a card arms it")
	# Aim: a tap on the lane moves the target.
	await _step("aim")
	_check(coach._hole.grow(1.0).encloses(coach._lane_rect().intersection(Rect2(Vector2.ZERO, lab.size))) and coach._hole.has_point(coach._aim_point()), "aim: the spotlight is the lane, with the tap inside it")
	_check(not lab.input_paused and coach.steps[coach.step].gesture == "tap", "the aim step lets the lane take a tap, and the hand taps")
	coach._time = 0.55 * coach.PERIOD
	await process_frame
	await _capture("tut_aim")
	var before: float = lab.target_x
	await _tap_at(coach._aim_point())
	_check(absf(lab.target_x - before) > 0.02, "a tap on the lane moves the target (%.2f -> %.2f)" % [before, lab.target_x])
	# Throw: hold, swirl, flick.
	await _step("throw")
	_check(coach._hole.has_point(lab.ball_screen_position()) and coach.steps[coach.step].gesture == "swirl_flick", "the throw step frames the ball and shows the swirl and flick")
	var screen: Vector2 = coach.root.get_viewport_rect().size
	var ball := Rect2(lab.ball_screen_position() - Vector2(40, 40), Vector2(80, 80))
	_check(absf(coach.card.get_global_rect().end.y - (screen.y - 12.0)) <= 2.0 and not coach.card.get_global_rect().intersects(ball),
		"portrait: the throw card is pinned to the bottom, clear of the ball (%s)" % str(coach.card.get_global_rect()))
	# Landscape: pinned beside the lane instead.
	root.size = Vector2i(800, 450)
	for i in 8: await process_frame
	screen = coach.root.get_viewport_rect().size
	ball = Rect2(lab.ball_screen_position() - Vector2(30, 30), Vector2(60, 60))
	var side: Rect2 = coach.card.get_global_rect()
	_check(side.end.x >= screen.x - 14.0 and side.size.x <= screen.x * 0.3 + 1.0 and not side.intersects(ball),
		"landscape: the throw card is a column at the side, clear of the ball (%s in %s)" % [str(side), str(screen)])
	await _capture("tut_throw_landscape")
	root.size = PORTRAIT
	for i in 8: await process_frame
	coach._time = 0.4 * coach.PERIOD
	await process_frame
	await _capture("tut_throw")
	await _swirl_throw()
	await _wait_for(func(): return lab.state == "rolling" and not coach.card.visible, "the coach steps aside while the ball rolls", ROLL_FRAMES)
	await _second_roll("spare")
	# Scoring.
	await _step("scoring")
	_spotlit(lab.score_panel, "scoring")
	await _capture("tut_scoring")
	await _tap(coach.next_button)
	# A second frame unless the first already won the match.
	await _wait_for(func(): return lab.state == "frame_done", "frame 1 done", ROLL_FRAMES)
	if not lab.division.match_over():
		await _step("next_rack")
		_spotlit(lab.next_rack, "next rack")
		await _tap(lab.next_rack)
		await _step("throw_again")
		_check(coach.dims.all(func(d): return not d.visible) and not lab.input_paused, "the second frame is the player's own: no dimming, the lane live")
		await _flick()
		await _wait_for(func(): return lab.state == "rolling", "frame 2 rolls", ROLL_FRAMES)
		await _second_roll("spare_again")
		await _wait_for(func(): return lab.state == "frame_done", "frame 2 done", ROLL_FRAMES)
	print("JTUT opener %d of %d in %d frame(s)" % [lab.division.match_score, lab.division.target(), lab.match_frame])
	if lab.division.outcome == "lost" or lab.division.match_score < lab.division.target():
		_check(false, "the practice opener is won by the journey's throws (%d of %d)" % [lab.division.match_score, lab.division.target()])
		return _end()
	await _step("collect")
	await _tap(lab.next_rack)
	# The Pro Shop: its first visit sells the fixed offers.
	await _step("shop")
	var shop = lab.shop_panel
	_check(lab.shop.offers.slice(0, 5).map(func(o): return o.item_id) == lab.content.tutorial_offers, "the first shop sells the tutorial's fixed offers")
	# Owner (2026-11-18): the shop step points straight at the item to buy, and the rest
	# of the shop stays readable under a light dim that takes no taps.
	var offer: Control = coach._workshop_offer()
	_check(lab.shop.offers[coach._workshop_index()].item_id == "pin_mod.brass_cap" and coach.body.text.contains(lab.run.item("pin_mod.brass_cap").name)
		and not coach.next_button.visible and coach.steps[coach.step].gesture == "tap", "the shop step points at the Brass Cap, with no Next")
	_spotlit(offer, "shop")
	_check(coach.dims.all(func(d): return not d.visible or is_equal_approx(d.color.a, 0.45)), "the shop is dimmed lightly, so it stays readable")
	var other: Control = lab.shop_panel.button_for_offer(0)
	await _tap(other)
	_check(not shop.offer_sheet.visible and coach.current_id() == "shop", "another offer cannot be tapped during the shop step")
	_check(not coach.card.get_global_rect().intersects(shop.offers_grid.get_global_rect()), "the coach's card leaves the shop's offers in view")
	await _capture("tut_shop")
	await _tap(offer)
	await _step("confirm_buy")
	_spotlit(shop.buy_button, "confirm buy")
	await _tap(shop.buy_button)
	await _step("place")
	_check(shop.choice_map.visible and shop.choice_count() > 0, "the rack map asks where to attach it")
	coach._time = 0.55 * coach.PERIOD
	await process_frame
	await _capture("tut_place")
	_check(coach._pin_point() == shop.choice_button(0).get_global_rect().get_center(), "the hand first points at a pin, not Confirm")
	_check(shop._choice_selected == -1 and shop.choice_confirm.disabled and String(shop.choice_button(0).get_meta("previewing", "")).is_empty(),
		"the map opens with nothing picked and nothing previewed")
	var pin1: Button = shop.choice_button(0)
	var pin2: Button = shop.choice_button(1)
	await _tap(pin2)
	_check(pin2.get_meta("previewing", "") == "pin_mod.brass_cap" and pin2.get_node("ModificationBadge").visible
		and pin2.get_node("ModificationBadge").get_meta("item_id") == "pin_mod.brass_cap", "a touched pin shows the Brass Cap on it")
	await _capture("tut_place_preview")
	await _tap(pin1)
	var badge: Node = pin2.get_node_or_null("ModificationBadge")
	_check(String(pin2.get_meta("previewing", "")).is_empty() and (badge == null or not badge.visible) and pin1.get_meta("previewing", "") == "pin_mod.brass_cap",
		"touching another pin moves the preview there; the first goes back as it was")
	await _tap(shop.choice_button(0))
	await _wait_for(func(): return shop._choice_selected == 0 and coach._pin_point() == shop.choice_confirm.get_global_rect().get_center(), "once a pin is picked, the hand moves to Confirm")
	await _capture("tut_place_confirm")
	await _tap(shop.choice_confirm)
	await _step("sell")
	_check(lab.run.entries().any(func(e): return e.ref.begins_with("rack:") and String(e.entry.get("mod", "")) == "pin_mod.brass_cap"), "the Brass Cap is on the rack")
	await _tap(shop.sell_open)
	await _step("sell_sheet")
	_check(coach._hole.grow(1.0).encloses(shop.sell_sheet.get_global_rect()), "the Sell step spotlights the whole Sell sheet, not only Done")
	await _capture("tut_sell")
	await _tap(shop.sell_close)
	await _step("rival")
	_spotlit(lab.hud.badge, "rival")
	await _capture("tut_rival")
	await _tap(coach.next_button)
	await _step("ready")
	_check(coach.next_button.text == "Back to the Clubhouse" and coach.extra_button.visible and coach.extra_button.text == "Keep Practising", "the last card offers the Clubhouse or more practice")
	await _capture("tut_ready")
	await _tap(coach.next_button)
	await _wait_for(func(): return scene.screen == "menu" and scene.coach == null and scene.content.id != "tutorial", "back in the Clubhouse")
	# Nothing reached the Career or the saves but the tutorial's own note.
	var after: Dictionary = scene.career.duplicate(true)
	_check(bool(after.tutorial.get("completed", false)) and bool(after.tutorial.get("seen", false)), "the Career notes the tutorial as seen and completed")
	after.erase("tutorial")
	var was: Dictionary = career_before.duplicate(true)
	was.erase("tutorial")
	_check(after == was, "the practice changed nothing else in the Career")
	_check(not scene.store.read("attempt").ok and not scene.continue_button.visible, "the practice left no saved run")
	await _lose_and_retry()
	# Skip, from a second How to Play; then reduced motion's still hand.
	await _tap(scene.club_menu_button)
	await _tap(scene.club_menu_list.get_node("ClubTutorial"))
	await _wait_for(func(): return scene.coach != null and scene.coach.card_ready(), "How to Play again")
	coach = scene.coach
	await _tap(coach.skip_button)
	await _wait_for(func(): return scene.screen == "menu" and scene.coach == null, "Skip returns to the Clubhouse")
	scene.throw_settings.reduced_motion = true
	await _tap(scene.club_menu_button)
	await _tap(scene.club_menu_list.get_node("ClubTutorial"))
	await _wait_for(func(): return scene.coach != null and scene.coach.card_ready(), "How to Play, reduced motion")
	coach = scene.coach
	lab = scene.lab
	_check(coach.reduced, "the coach follows reduced motion")
	await _tap(coach.next_button)
	await _step("target")
	await _tap(coach.next_button)
	await _step("cards")
	var still: Vector2 = coach._card_point()
	coach._time = 0.1 * coach.PERIOD
	await process_frame
	_check(coach.reduced and is_equal_approx(fmod(coach._time, coach.PERIOD), coach._time), "reduced motion: the hand holds one pose")
	await _capture("tut_cards_reduced")
	scene.throw_settings.reduced_motion = false
	await _tap(coach.skip_button)
	await _wait_for(func(): return scene.screen == "menu", "Skip again")
	_end()

func _end() -> void:
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_JTUT_OK")
	quit(0 if failures.is_empty() else 1)
