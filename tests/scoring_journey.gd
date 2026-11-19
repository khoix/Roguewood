extends SceneTree
const ScoreLog = preload("res://src/rules/score_log.gd")
## J03 scoring journey (E06): strike, spare and open frames played through real
## input (focused Options toggles, keyboard steps on the assist sliders and Throw),
## then checked against an independent FrameRules resolution: banked score, ordered
## calculation log, per-roll pin attribution, finishing the reveal by tap or key, and running totals.
## Assist steps and reduced motion (steady clean-only ring) make every launch exact;
## the outcomes come from the deterministic physics. Run with --fixed-fps 60.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const FrameBuilder = preload("res://src/rules/frame_builder.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control
var lab: Control
var running_total := 0

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
	print("J03 %s lab=%s frame=%d total=%d" % [label, lab.state if lab else "-", lab.frame_number if lab else 0, lab.total_score if lab else 0])
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

func _focus_accept(control: Control) -> void:
	await _reach(control)
	control.grab_focus()
	await _action("ui_accept")
	await _confirm(control)

## Moves a focused slider to value with ui_left/ui_right presses only.
func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	await _action("ui_right" if steps > 0 else "ui_left", absi(steps))
	_check(is_equal_approx(slider.value, value), "%s reached %.2f" % [slider.name, value])

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
	await _focus_accept(lab.settings_panel.practice) # E09: targets off; this journey tests its own subsystem
	await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)
	_check(lab.settings.assist and lab.settings.reduced_motion, "assist and reduced motion on")
	# UI-20: the lab has no League art, so nothing celebrates until variants are given.
	_check(not lab.alley_screen.has_art("strike") and not lab.alley_screen.has_art("spare"), "no celebration without art (the owner: not before Codex's)")
	lab.alley_screen.variants_override = {"strike": CELEBRATIONS, "spare": CELEBRATIONS}
	await _strike_frame()
	await _spare_frame()
	await _open_frame()
	_check(scene.session.score == running_total and scene.session.frame == 4, "session fixture tracks banked total and frame")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty(): await _capture("failure")
	if failures.is_empty(): print("ROGUEWOOD_J03_OK")
	quit(0 if failures.is_empty() else 1)

func _throw(position: float, aim: float, power: float) -> Dictionary:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim before throw", ROLL_FRAMES)
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, position)
	await _slide(panel.aim_slider, aim)
	await _slide(panel.power_slider, power)
	await _slide(panel.spin_slider, 0.0)
	var count: int = lab.history.size()
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling", "Throw commits")
	await _wait_for(func(): return lab.history.size() == count + 1, "roll settles", ROLL_FRAMES)
	var report: Dictionary = lab.history[-1]
	print("J03 roll launch=%s fallen=%s standing=%s accuracy=%s" % [report.launch.launch_id, str(report.roll_result.fallen_positions), str(report.knockdown_log.standing), report.roll_result.accuracy])
	return report

## Waits for scoring, then checks it against an independent resolution.
func _verify_frame(category: String, label: String, during: Callable = Callable()) -> void:
	await _wait_for(func(): return lab.state == "scoring", label + " scoring starts", ROLL_FRAMES)
	# The owner (2026-11-18): the top bar holds the score from before the frame while its tally plays.
	var before: int = int(lab.division.match_score) - int(lab.scored_frames[-1].banked)
	_check(lab.shown_score() == before and lab.hud.score_label.text.begins_with(ScoreLog._n(before)) and (int(lab.scored_frames[-1].banked) == 0 or not lab.hud.score_label.text.begins_with(ScoreLog._n(lab.division.match_score))),
		"%s: the top bar keeps the pre-frame score %d during the tally (%s)" % [label, before, lab.hud.score_label.text])
	if during.is_valid():
		await during.call()
	await _wait_for(func(): return lab.state == "frame_done", label + " scoring finishes", ROLL_FRAMES)
	_check(lab.hud.score_label.text.begins_with(ScoreLog._n(lab.division.match_score)), "%s: the top bar shows the banked score once the tally finishes (%s)" % [label, lab.hud.score_label.text])
	var reports: Array = lab.frame_reports
	var built: Dictionary = FrameBuilder.build(FrameBuilder.lab_loadout(), Contracts.read_json(FrameBuilder.LAB_CATALOGUE), reports)
	_check(built.ok, label + " frame builds from the roll reports")
	if not built.ok: return
	var expected: Dictionary = Rules.resolve(built.frame)
	var panel: Control = lab.score_panel
	var shown: Dictionary = panel.displayed()
	_check(expected.category == category, "%s is a %s (got %s)" % [label, category, expected.category])
	_check(shown.score == expected.score and int(lab.scored_frames[-1].result.score) == expected.score, "%s panel banks the resolver's score %d" % [label, expected.score])
	var fallen: int = 0
	for report in reports:
		fallen += report.roll_result.fallen_positions.size()
	var base: Array = {"strike": [40, 4], "spare": [20, 2], "open": [0, 1]}[category]
	_check(expected.score == (base[0] + 10 * fallen) * base[1], "%s base score is (%d + 10×%d) × %d" % [label, base[0], fallen, base[1]])
	var lines: Array = panel.log_list.get_children().map(func(child): return child.text)
	_check(lines.size() == panel.steps.size() and lines[0].contains(category.capitalize()) and lines[-1].contains("Bank") and lines[-1].ends_with("= %d" % expected.score), label + " log opens with category and ends with the bank")
	var pins: Array = panel.steps.filter(func(step): return step.pin > 0).map(func(step): return step.pin)
	var sorted_pins := pins.duplicate()
	sorted_pins.sort()
	_check(pins == sorted_pins and pins.size() == fallen, label + " log credits each fallen pin once in rack order")
	_check(lines.filter(func(text): return text.contains("Accuracy")).size() == 1, label + " one accuracy award")
	for report in reports:
		for position in report.roll_result.fallen_positions:
			_check(panel._roll_of.get(int(position)) == int(report.roll_result.roll_index), "%s rack shows pin %d taken by roll %d" % [label, position, report.roll_result.roll_index])
	running_total += expected.score
	_check(lab.total_score == running_total and lab.status.text.contains("Total %d" % running_total), label + " running total")
	print("J03 %s score=%d category=%s steps=%d total=%d" % [label, expected.score, expected.category, lines.size(), running_total])

func _next_frame() -> void:
	await _focus_accept(lab.next_rack)
	if lab.state == "shop": # match end (E08): leave the Pro Shop without buying
		await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "aim" and lab.roll_index == 1, "next rack", ROLL_FRAMES)

## UI-20's placeholder, listed five times as a League's five variants would be.
const CELEBRATIONS := ["res://src/presentation/alley_screen_placeholder.gd", "res://src/presentation/alley_screen_placeholder.gd",
	"res://src/presentation/alley_screen_placeholder.gd", "res://src/presentation/alley_screen_placeholder.gd", "res://src/presentation/alley_screen_placeholder.gd"]

## UI-20: the alley screen plays `event` over the magnifier's window, rendering.
func _check_celebration(event: String) -> void:
	var alley: Control = lab.alley_screen
	await _wait_for(func(): return alley.playing(), event + " celebration starts")
	_check(alley.current_event == event and alley.current_path in CELEBRATIONS and alley.visible and alley.view.render_target_update_mode == SubViewport.UPDATE_ALWAYS,
		"the %s celebration plays on the alley screen (%s)" % [event, alley.current_event])
	var window: Rect2 = lab.aim_magnifier.panel_rect(lab, lab.get_viewport_rect().size)
	_check(alley.get_global_rect().is_equal_approx(window), "it fills the magnifier's window over the top HUD")
	_check(bool(alley.current_context.reduced_motion) == bool(lab.settings.reduced_motion) and float(alley.crt.get_shader_parameter("flicker")) == (0.0 if lab.settings.get("reduced_flash", false) else 1.0),
		"it follows Reduced Motion and Reduced Flash")

func _strike_frame() -> void:
	await _throw(0.1, 0.0, 0.7)
	await _check_celebration("strike")
	for i in 6: await process_frame
	await _capture("celebration_strike")
	# A tap on the alley screen skips it; it hides and stops rendering.
	var on_screen: Vector2 = root.get_screen_transform() * lab.alley_screen.get_global_rect().get_center()
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = on_screen
		touch.pressed = pressed
		Input.parse_input_event(touch)
		await process_frame
	await process_frame
	_check(not lab.alley_screen.playing() and not lab.alley_screen.visible and lab.alley_screen.view.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"a tap skips the celebration; hidden, it renders nothing")
	await _verify_frame("strike", "strike", func():
		for i in 20: await process_frame
		await _capture("scoring")
		var panel: Control = lab.score_panel
		_check(panel.playing and panel.displayed().score == -1, "score counts up step by step before banking")
		# UI-5: no Speed or Skip buttons; a tap on the review finishes the reveal.
		_check(panel.find_child("ScoreSpeed", true, false) == null and panel.find_child("SkipScoring", true, false) == null and panel.hint.modulate.a > 0.5,
			"the review has no Speed or Skip button, and says a tap finishes it")
		var at := root.get_screen_transform() * panel.get_global_rect().get_center()
		for pressed in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.position = at
			touch.pressed = pressed
			Input.parse_input_event(touch)
			await process_frame
		_check(not panel.playing and panel.displayed().score >= 0, "a tap on the review finishes the reveal"))
	await _capture("strike")
	await _next_frame()

func _spare_frame() -> void:
	var before: int = lab.alley_screen.played.size()
	await _throw(-0.4, 0.0, 0.6)
	_check(lab.alley_screen.played.size() == before, "a first roll that leaves pins does not celebrate")
	await _throw(0.0, 0.0, 0.6)
	await _check_celebration("spare")
	await _wait_for(func(): return not lab.alley_screen.playing(), "the spare celebration ends by itself", 300)
	_check(not lab.alley_screen.visible, "the spare celebration ends by itself and hides")
	await _verify_frame("spare", "spare", func():
		var panel: Control = lab.score_panel
		_check(panel.playing, "the next frame's reveal counts step by step again")
		await _focus_accept(panel)
		_check(not panel.playing, "the accept key finishes the reveal too"))
	await _capture("spare")
	await _next_frame()

func _open_frame() -> void:
	var before: int = lab.alley_screen.played.size()
	await _throw(-0.4, 0.0, 0.6)
	var gutter: Dictionary = await _throw(0.8, 2.0, 0.6)
	_check(gutter.knockdown_log.gutter, "second roll is a gutter ball")
	await _verify_frame("open", "open")
	_check(lab.alley_screen.played.size() == before, "an open frame does not celebrate")
	await _capture("open")
