extends SceneTree
## J06 Division journey (E09), driven through the real game with touch and keyboard:
## - attempt 1: the boss and its rule are previewed from the first frame and in every
##   shop; the opener and feature end early once their targets are crossed (and pay
##   the unused-frame bonus); the rival's introduction is skipped; its reactions
##   never block a throw; Clean Sweep banks an open frame as 0 and the boss is lost;
##   the result shows the unmet score and the rule; Retry starts attempt 2;
## - attempt 2: the shortened introduction advances on its own; two strikes defeat
##   The Custodian, and the first-clear reward is banked at once;
## - attempt 3: the reward survives (the shop pool is unlocked), an opener loss keeps
##   the Career record, and Clubhouse returns to the menu.
## Shots are the deterministic J03 assist throws. Run with --fixed-fps 60.
const Economy = preload("res://src/rules/economy.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
const STRIKE := [0.1, 0.0, 0.7]
const LEAVE := [-0.4, 0.0, 0.6]
const GUTTER := [0.8, 2.0, 0.6]
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
	print("J06 %s attempt=%d lab=%s match=%s score=%d hud=%s" % [label, scene.session.get("attempt", 0), lab.state,
		lab.division.current().id, lab.division.match_score, lab.hud.info.text])
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

func _tap(control: Control) -> void:
	var at := root.get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	await _action("ui_right" if steps > 0 else "ui_left", absi(steps))

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
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
	await _focus_accept(lab.settings_panel.close)
	_check(not lab.division.practice and lab.settings.assist, "a Division attempt with assist controls")
	await _first_attempt()
	await _second_attempt()
	await _third_attempt()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty() and lab != null: await _capture("failure")
	if failures.is_empty(): print("ROGUEWOOD_J06_OK")
	quit(0 if failures.is_empty() else 1)

func _aim() -> void:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim", ROLL_FRAMES)

func _throw(shot: Array) -> Dictionary:
	await _aim()
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, shot[0])
	await _slide(panel.aim_slider, shot[1])
	await _slide(panel.power_slider, shot[2])
	await _slide(panel.spin_slider, 0.0)
	var count: int = lab.history.size()
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling", "Throw commits")
	await _wait_for(func(): return lab.history.size() == count + 1, "roll settles", ROLL_FRAMES)
	return lab.history[-1]

## Waits for scoring, skips the reveal, returns the scored record.
func _scored() -> Dictionary:
	await _wait_for(func(): return lab.state == "scoring", "scoring", ROLL_FRAMES)
	await _focus_accept(lab.score_panel.skip_button)
	await _wait_for(func(): return lab.state == "frame_done", "frame done", ROLL_FRAMES)
	return lab.scored_frames[-1]

## Plays the strike that ends an opener or feature early, then visits the shop.
func _win_early(kind: String, target: int, preview_contains: Array) -> void:
	_check(lab.division.current().kind == kind and lab.division.target() == target and lab.hud.info.text.contains("Target %d" % target), "%s posts target %d" % [kind, target])
	await _throw(STRIKE)
	var scored := await _scored()
	_check(scored.match_over and scored.match_won and lab.division.results[-1].frames == 1, "%s won in one frame" % kind)
	_check(lab.next_rack.text == "Collect & Shop" and lab.division.frames_left() == 1, "the crossing frame ends the match")
	var held: int = lab.run.money
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "shop", "%s shop" % kind)
	_check(lab.settlement.payout == Economy.MATCH_PAYOUT + Economy.UNUSED_FRAME_BONUS and lab.settlement.interest == Economy.interest(held), "an early win pays the unused-frame bonus ($%d)" % lab.settlement.payout)
	for text in preview_contains:
		_check(lab.shop_panel.preview.text.contains(text), "shop previews: " + text)

func _first_attempt() -> void:
	# The boss, its rule and its reward are inspectable from the first frame.
	_check(lab.hud.badge.visible and lab.hud.badge.text.contains("The Custodian") and not lab.hud.rule_panel.visible, "the boss badge shows from the start")
	await _tap(lab.hud.badge)
	_check(lab.hud.rule_panel.visible and lab.hud.rule_text.text.contains("Clean Sweep") and lab.hud.rule_text.text.contains("target 800")
		and lab.hud.rule_text.text.contains("First clear"), "the badge opens the rival's rule, target and reward")
	_check(lab.state == "aim" and lab.history.is_empty(), "inspecting the rule throws nothing")
	await _capture("preview")
	await _tap(lab.hud.badge)
	_check(not lab.hud.rule_panel.visible, "the rule panel closes")
	await _win_early("opener", 300, ["Next: Feature — target 500", "Boss later: The Custodian"])
	await _capture("shop_preview")
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "aim", "feature starts", ROLL_FRAMES)
	await _win_early("feature", 500, ["Next: Boss — target 800", "The Custodian: Clean Sweep", "First clear:"])
	await _focus_accept(lab.shop_panel.continue_button)
	# The rival's entrance: modal, skippable.
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, "boss introduction")
	_check(lab.hud.intro_title.text.contains("The Custodian") and lab.hud.intro_body.text.contains("Posted target 800") and lab.hud.intro_body.text.contains("Clean Sweep")
		and lab.hud.intro_body.text.contains(lab.division.rival().intro), "the introduction names the rival, target, rule and reward")
	_check(lab.hud.reduced_motion and is_equal_approx(lab.hud.intro.modulate.a, 1.0), "reduced motion: the introduction appears without a fade")
	await _capture("intro")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim" and not lab.hud.intro.visible, "intro skipped")
	_check(lab.hud.reaction.visible and lab.hud.reaction_text.text.contains(lab.division.rival().reactions.entrance), "the rival's entrance reaction")
	# Reactions are visual only and sit clear of the ball and the rack.
	var bubble: Rect2 = lab.hud.reaction.get_global_rect()
	var head_pin: Vector2 = lab.get_global_transform() * lab.screen_point(Vector3(0.0, 0.0, -18.288))
	_check(lab.hud.reaction.mouse_filter == Control.MOUSE_FILTER_IGNORE and not bubble.has_point(lab.ball_screen_position()) and not bubble.has_point(head_pin),
		"the reaction takes no input and covers neither the ball nor the rack")
	_check(lab.hud.badge.text.contains("Clean Sweep") and lab.hud.info.text.contains("The Custodian · Boss 3/3 · Target 800"), "the boss HUD shows rival, target and rule badge")
	await _capture("boss")
	await _throw(STRIKE) # thrown while the reaction is on screen
	var first := await _scored()
	_check(first.banked == 560 and not first.match_over and lab.division.target() == 800, "a boss strike banks in full; the target stays 800")
	await _focus_accept(lab.next_rack)
	var leave := await _throw(LEAVE)
	_check(not leave.knockdown_log.standing.is_empty(), "the leave leaves pins")
	await _aim()
	await _throw(GUTTER)
	var open := await _scored()
	var lines: Array = lab.score_panel.log_list.get_children().map(func(c): return c.text)
	_check(open.result.category == "open" and open.result.score > 0 and open.banked == 0 and lines.any(func(l): return l.contains("Clean Sweep: an open frame banks nothing")),
		"Clean Sweep banks the open frame as 0 and says so")
	_check(open.match_over and not open.match_won and lab.division.outcome == "lost" and lab.next_rack.text == "See Result", "560 of 800: the boss is lost")
	_check(lab.hud.reaction_text.text.contains(lab.division.rival().reactions.victorious), "the rival reacts to winning")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "result screen")
	_check(lab.hud.result_title.text.contains("Boss lost") and lab.hud.result_body.text.contains("Scored 560 of the 800 target")
		and lab.hud.result_body.text.contains("Rule in force: Clean Sweep"), "the loss shows the unmet score and the rule")
	_check(scene.career.first_clears.is_empty() and scene.session.outcome == "lost", "no reward for a loss")
	await _capture("lost")
	var old_id: int = lab.get_instance_id() # never capture the freed lab itself
	await _focus_accept(lab.hud.retry_button)
	await _wait_for(func(): return scene.lab != null and scene.lab.get_instance_id() != old_id and scene.lab.state == "aim", "retry starts a new attempt")
	lab = scene.lab
	_check(scene.session.attempt == 2 and lab.attempt == 2 and lab.total_score == 0 and lab.run.money == Economy.STARTING_MONEY and lab.division.current().kind == "opener",
		"Retry begins attempt 2 from the opener")
	_check(lab.settings.assist and not lab.division.practice, "settings carry into the retry")

func _second_attempt() -> void:
	await _win_early("opener", 300, ["Next: Feature"])
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "aim", "feature starts", ROLL_FRAMES)
	await _win_early("feature", 500, ["The Custodian"])
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "intro", "boss introduction again")
	_check(lab.hud.intro_remaining <= 2.0 and not lab.hud.intro_body.text.contains(lab.division.rival().intro), "a repeat introduction is shortened")
	await _wait_for(func(): return lab.state == "aim" and not lab.hud.intro.visible, "the short introduction advances on its own", 300)
	await _throw(STRIKE)
	await _scored()
	await _focus_accept(lab.next_rack)
	await _throw(STRIKE)
	var win := await _scored()
	_check(win.match_over and win.match_won and lab.division.outcome == "won" and lab.division.match_score == 1120 and lab.next_rack.text == "Division Result", "two strikes defeat the boss")
	_check(lab.hud.reaction_text.text.contains(lab.division.rival().reactions.defeated), "the rival concedes")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "victory screen")
	_check(lab.hud.result_title.text.contains("The Custodian defeated") and lab.hud.result_body.text.contains("First clear: Lab Lead"), "victory banks the first-clear reward")
	_check(scene.career.first_clears.has("rival.lab_custodian") and "gate.lab_rival" in scene.career.unlocked and scene.session.outcome == "won", "the reward is in the Career record at once")
	await _capture("won")
	var old_id: int = lab.get_instance_id() # never capture the freed lab itself
	await _focus_accept(lab.hud.retry_button) # "New Attempt"
	await _wait_for(func(): return scene.lab != null and scene.lab.get_instance_id() != old_id and scene.lab.state == "aim", "a new attempt")
	lab = scene.lab

func _third_attempt() -> void:
	_check(scene.session.attempt == 3 and "gate.lab_rival" in lab.shop.unlocked and lab.hud.rule_text.text.contains("already cleared"), "the first clear carries into the next attempt")
	for frame in 2:
		await _throw(LEAVE)
		await _aim()
		await _throw(GUTTER)
		await _scored()
		if frame == 0:
			_check(lab.next_rack.text == "Next Rack", "a short opener continues")
			await _focus_accept(lab.next_rack)
	_check(lab.division.outcome == "lost" and lab.division.results[0].score == 140, "two open frames lose the opener (140 of 300)")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "loss screen")
	_check(lab.hud.result_body.text.contains("Career progress kept: 1 rival(s) cleared") and scene.career.first_clears.has("rival.lab_custodian"), "a later loss keeps the first clear")
	await _capture("lost_again")
	await _focus_accept(lab.hud.menu_button)
	await _wait_for(func(): return scene.screen == "menu" and scene.lab == null, "Clubhouse returns to the menu")
	_check(scene.career.first_clears.has("rival.lab_custodian"), "the Career record outlives the session")
	lab = null
