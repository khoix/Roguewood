extends SceneTree
## J04 equipment journey (E07): the experimental draw/retain/cycle deck and the
## direct-selection comparison, driven through the real lab with touch, mouse and
## keyboard on the card row and assist-control throws. Covers the first draw, arming
## and playing a ball card, cycling once, a tactical card exhausted for the run, a
## retained card, the empty draw pile reshuffling, the match-start recombine, the
## House ball when nothing is armed, and direct uses running out. Each frame's score
## is checked against an independent FrameBuilder/FrameRules resolution that names
## the played cards. The deck order comes from session seed 1. Run with --fixed-fps 60.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const FrameBuilder = preload("res://src/rules/frame_builder.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
const STRIKE := [0.1, 0.0, 0.7]
const LEAVE := [-0.4, 0.0, 0.6]
const CLEANUP := [0.0, 0.0, 0.6]
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control
var lab: Control
var catalogue: Dictionary
var tactics: Dictionary = {} # this frame's roll -> tactical ids, tracked by the journey
var tactical_uid := ""

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
	print("J04 %s lab=%s match=%d frame=%d hand=%s counts=%s" % [label, lab.state, lab.match_number, lab.frame_number,
		str(_hand_items()), str(lab.equipment.counts())])
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

func _focus_accept(control: Control) -> void:
	control.grab_focus()
	await _action("ui_accept")

func _window(canvas: Vector2) -> Vector2:
	return root.get_screen_transform() * canvas

## A finger tap: the lab must ignore it (over UI) and the button must take it.
func _tap(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = _window(at)
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func _click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = _window(at)
		event.global_position = event.position
		Input.parse_input_event(event)
		await process_frame

func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	await _action("ui_right" if steps > 0 else "ui_left", absi(steps))

func _hand_items() -> Array:
	return lab.equipment.options().map(func(o): return o.item_id)

func _card(uid: String) -> Button:
	return lab.card_hand.button_for(uid)

## First option of a kind in hand order, preferring an item id.
func _find(kind: String, prefer: String = "", skip: Array = []) -> String:
	var found := ""
	for option in lab.equipment.options():
		if option.kind != kind or option.uid in skip:
			continue
		if option.item_id == prefer:
			return option.uid
		if found.is_empty():
			found = option.uid
	return found

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	catalogue = Contracts.read_json(FrameBuilder.LAB_CATALOGUE)
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
	await _focus_accept(lab.settings_panel.practice) # E09: targets off; this journey tests its own subsystem
	await _focus_accept(lab.settings_panel.close)
	_check(lab.settings.equipment == "deck" and lab.equipment.MODEL == "deck", "draw-and-cycle deck is the default model")
	await _first_frame()
	await _second_frame()
	await _new_match()
	await _direct_model()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty(): await _capture("failure")
	if failures.is_empty(): print("ROGUEWOOD_J04_OK")
	quit(0 if failures.is_empty() else 1)

func _throw(shot: Array) -> Dictionary:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim before throw", ROLL_FRAMES)
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, shot[0])
	await _slide(panel.aim_slider, shot[1])
	await _slide(panel.power_slider, shot[2])
	await _slide(panel.spin_slider, 0.0)
	var count: int = lab.history.size()
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling", "Throw commits")
	_check(lab.card_hand.buttons.values().all(func(b): return b.disabled) and lab.card_hand.cycle_button.disabled, "cards are locked while the ball rolls")
	await _wait_for(func(): return lab.history.size() == count + 1, "roll settles", ROLL_FRAMES)
	var report: Dictionary = lab.history[-1]
	print("J04 roll ball=%s fallen=%s accuracy=%s" % [report.launch.ball_id, str(report.roll_result.fallen_positions), report.roll_result.accuracy])
	return report

func _aim() -> void:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim", ROLL_FRAMES)

## Scoring must equal an independent resolution with the cards the journey played.
func _verify_frame(label: String, expect_names: Array) -> void:
	await _wait_for(func(): return lab.state == "scoring", label + " scoring starts", ROLL_FRAMES)
	await _focus_accept(lab.score_panel.skip_button)
	await _wait_for(func(): return lab.state == "frame_done", label + " scoring finishes", ROLL_FRAMES)
	_check(lab.frame_tactics == tactics, label + " lab recorded the played tactical cards")
	var built: Dictionary = FrameBuilder.build(FrameBuilder.lab_loadout(), catalogue, lab.frame_reports, tactics)
	_check(built.ok, label + " frame builds")
	if not built.ok: return
	var expected: Dictionary = Rules.resolve(built.frame)
	_check(int(lab.scored_frames[-1].result.score) == expected.score and lab.score_panel.displayed().score == expected.score, "%s banks %d" % [label, expected.score])
	var lines: Array = lab.score_panel.log_list.get_children().map(func(child): return child.text)
	for text in expect_names:
		_check(lines.any(func(line): return line.contains(text)), "%s log names %s" % [label, text])
	print("J04 %s score=%d category=%s" % [label, expected.score, expected.category])
	tactics = {}

func _first_frame() -> void:
	var deck = lab.equipment
	_check(deck.hand.size() == 4 and deck.draw_pile.size() == 3 and lab.card_hand.buttons.size() == 4, "first frame draws four of seven")
	_check(lab.card_hand.cycle_button.visible and not lab.card_hand.cycle_button.disabled, "Cycle offered")
	await _capture("hand")
	# Arm a ball by touch; the tap must not start a throw.
	var ball := _find("ball", "ball.lab_mult")
	_check(not ball.is_empty(), "hand holds a ball card")
	await _tap(_card(ball))
	_check(lab.state == "aim" and lab.armed_ball == ball and lab.status.text.contains("Ball: " + lab._names[deck.cards[ball]]), "touch arms a ball card without throwing")
	await _tap(_card(ball))
	_check(lab.armed_ball.is_empty() and lab.status.text.contains("Ball: House"), "tapping again disarms back to House")
	await _click(_card(ball))
	_check(lab.armed_ball == ball, "mouse arms a ball card")
	# Cycle once with the keyboard: Cycle, then the card to swap.
	var swap := ""
	for uid in deck.hand:
		if uid != ball and Deck.kind(deck.cards[uid]) == "ball":
			swap = uid
	if swap.is_empty():
		swap = deck.hand[0] if deck.hand[0] != ball else deck.hand[1]
	var draw_before: int = deck.draw_pile.size()
	await _focus_accept(lab.card_hand.cycle_button)
	_check(lab.cycling and lab.card_hand.info.text.contains("Cycle"), "Cycle waits for a card")
	await _focus_accept(_card(swap))
	_check(not lab.cycling and swap in deck.discard and deck.hand.size() == 4 and deck.draw_pile.size() == draw_before - 1, "cycle discards one and draws one")
	_check(lab.card_hand.cycle_button.disabled and not deck.can_cycle(), "cycle is spent for the frame")
	await _arm_tactical()
	var ball_id: String = deck.cards[ball]
	var report := await _throw(STRIKE)
	_check(report.launch.ball_id == ball_id and ball in deck.discard and ball not in deck.hand, "the armed card is thrown and discarded")
	var names: Array = [lab._names[ball_id]]
	if tactics.has(1):
		names.append("Roll 1 Lab Focus")
	await _verify_frame("frame 1", names)
	# Keep one card for the next frame (touch), then the next rack.
	var keep: String = deck.hand[0]
	await _tap(_card(keep))
	_check(lab.keep_card == keep and _card(keep).text.contains("KEEP"), "touch marks a card to keep")
	await _capture("keep")
	var dropped: Array = deck.hand.filter(func(uid): return uid != keep)
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "aim" and lab.frame_number == 2, "frame 2", ROLL_FRAMES)
	_check(deck.hand[0] == keep and deck.hand.size() == 4, "retained card stays in hand")
	_check(dropped.all(func(uid): return uid in deck.discard or uid in deck.hand or uid in deck.draw_pile), "the other cards were discarded into the reshuffle")
	_check(deck.reshuffles == 1, "the empty draw pile reshuffled the discard (reshuffles %d)" % deck.reshuffles)
	_check(deck.can_cycle(), "cycle refreshes each frame")

## Arms the tactical card if it is in hand and not yet used (keyboard).
func _arm_tactical() -> void:
	var uid := _find("tactical")
	if uid.is_empty() or not tactical_uid.is_empty():
		return
	await _focus_accept(_card(uid))
	_check(lab.armed_tactical == uid and lab.status.text.contains("Tactic: Lab Focus"), "keyboard arms the tactical card")
	tactical_uid = uid
	tactics[lab.roll_index] = ["consumable.lab_focus"]

func _second_frame() -> void:
	var deck = lab.equipment
	var counts: Dictionary = deck.counts()
	var report := await _throw(LEAVE)
	_check(report.launch.ball_id == "ball.house" and deck.counts() == counts, "nothing armed throws House and spends no card")
	if report.knockdown_log.standing.is_empty():
		_check(false, "frame 2 first roll leaves pins")
		return
	await _aim()
	_check(lab.roll_index == 2 and deck.hand.size() == 4, "the hand carries into roll two")
	var ball := _find("ball")
	if not ball.is_empty():
		await _focus_accept(_card(ball))
		_check(lab.armed_ball == ball, "keyboard arms a ball for roll two")
	await _arm_tactical()
	await _throw(CLEANUP)
	await _verify_frame("frame 2", [])
	_check(lab.card_hand.buttons.values().all(func(b): return b.disabled) and lab.card_hand.info.text.contains("Match over"), "no keep at the end of a match")
	await _capture("match_over")
	await _focus_accept(lab.next_rack)
	_check(lab.state == "shop", "match end opens the Pro Shop")
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "aim" and lab.frame_number == 3, "frame 3", ROLL_FRAMES)

## Match two recombines everything except an exhausted tactical card.
func _new_match() -> void:
	var deck = lab.equipment
	_check(lab.match_number == 2 and scene.session.match == 1, "second match begins")
	_check(deck.discard.is_empty() and deck.hand.size() == 4 and deck.hand.size() + deck.draw_pile.size() == deck.cards.size() - deck.exhausted.size(), "match start recombines and redraws")
	# Dig for the tactical card with the cycle if it has not been played yet.
	if tactical_uid.is_empty() and _find("tactical").is_empty() and deck.can_cycle():
		await _focus_accept(lab.card_hand.cycle_button)
		await _focus_accept(_card(_find("ball")))
	await _arm_tactical()
	_check(not tactical_uid.is_empty(), "the tactical card reached the hand")
	if lab.armed_tactical == tactical_uid:
		await _throw(STRIKE)
		await _verify_frame("frame 3", ["Lab Focus +3 Mult"])
		await _focus_accept(lab.next_rack)
		await _wait_for(func(): return lab.state == "aim" and lab.frame_number == 4, "frame 4", ROLL_FRAMES)
	# A tactical played this match is still exhausted; one played earlier has left the run (E08).
	var gone: bool = tactical_uid in deck.exhausted or (not deck.cards.has(tactical_uid) and not lab.run.cards.has(tactical_uid))
	_check(gone and tactical_uid not in deck.hand + deck.draw_pile + deck.discard, "the tactical card is exhausted and never returns")
	await _capture("exhausted")

## Switching the model on a fresh frame starts a direct-selection match.
func _direct_model() -> void:
	await _focus_accept(scene.options)
	lab.settings_panel.equipment.grab_focus()
	await _action("ui_accept")
	await _action("ui_down")
	await _action("ui_accept")
	await _focus_accept(lab.settings_panel.close)
	var bag = lab.equipment
	_check(lab.settings.equipment == "direct" and bag.MODEL == "direct", "options switch to direct selection")
	var tacticals: int = lab.run.cards.values().filter(func(e): return e.item_id.begins_with("consumable.")).size()
	_check(not lab.card_hand.cycle_button.visible and lab.card_hand.buttons.size() == 2 + tacticals, "direct bag shows two specials and the run's unused tactical cards, no Cycle")
	await _capture("direct")
	await _focus_accept(_card("ball.lab_mult"))
	var report := await _throw(LEAVE)
	_check(report.launch.ball_id == "ball.lab_mult" and bag.uses["ball.lab_mult"] == 1, "direct special spends a use")
	await _aim()
	await _focus_accept(_card("ball.lab_mult"))
	await _throw(CLEANUP)
	await _verify_frame("direct frame", ["Roll 1 Lab Mult", "Roll 2 Lab Mult"])
	_check(lab.card_hand.button_for("ball.lab_mult") == null, "a special with no uses left leaves the bag")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "aim", "direct next rack", ROLL_FRAMES)
	_check(lab.armed_ball_id() == "ball.house" and lab.card_hand.button_for("ball.lab_mult") == null, "House stays available after the special runs out")
