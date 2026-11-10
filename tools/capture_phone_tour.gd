extends SceneTree
## GUI review tour: walks the real game at a phone-shaped window and saves a capture
## of every screen a player meets in a first attempt, for the coordinator's and the
## owner's visual review (captures are shared, never committed).
##
## Run rendered (xvfb on Linux), for example at an iPhone 13 Pro's shape:
##   xvfb-run -a -s "-screen 0 1700x3000x24" godot --audio-driver Dummy --fixed-fps 60 \
##     --path . --script res://tools/capture_phone_tour.gd -- \
##     --artifact-dir=<dir> --save-dir=<dir>/saves --size=780x1688
## Add --landscape to rotate the window. It asserts nothing; journeys do that.
const ROLL_FRAMES := 1800
const STRIKE := [0.1, 0.0, 0.7]
const LEAVE := [-0.4, 0.0, 0.6]
const GUTTER := [0.8, 2.0, 0.6]
var artifact_dir := ""
var size := Vector2i(780, 1688)
var scene: Control
var lab: Control
var count := 0

func _initialize() -> void:
	call_deferred("_run")

func _wait_for(predicate: Callable, frames: int = 240) -> bool:
	for i in frames:
		if predicate.call(): return true
		await process_frame
	return predicate.call()

func _settle(frames: int = 20) -> void:
	for i in frames: await process_frame

func _capture(label: String) -> void:
	await _settle(4)
	await RenderingServer.frame_post_draw
	count += 1
	var image := root.get_texture().get_image()
	image.save_png(artifact_dir.path_join("%02d_%s.png" % [count, label]))
	print("TOUR %02d %s" % [count, label])

func _action(action: String, times: int = 1) -> void:
	for i in times:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame

func _press(control: Control) -> void:
	control.grab_focus()
	await _action("ui_accept")

func _tap(control: Control) -> void:
	var scroll: Node = control.get_parent()
	while scroll != null and not (scroll is ScrollContainer): scroll = scroll.get_parent()
	if scroll != null and not (scroll as Control).get_global_rect().encloses(control.get_global_rect()):
		(scroll as ScrollContainer).ensure_control_visible(control)
		await _settle(2)
	var at := root.get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame

func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	await _action("ui_right" if steps > 0 else "ui_left", absi(steps))

func _aim() -> void:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", ROLL_FRAMES)

func _throw(shot: Array, capture_roll: String = "") -> void:
	await _aim()
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, shot[0])
	await _slide(panel.aim_slider, shot[1])
	await _slide(panel.power_slider, shot[2])
	await _slide(panel.spin_slider, 0.0)
	var rolls: int = lab.history.size()
	await _press(panel.throw_button)
	if not capture_roll.is_empty():
		await _settle(45)
		await _capture(capture_roll)
	await _wait_for(func(): return lab.history.size() == rolls + 1, ROLL_FRAMES)

func _run() -> void:
	var landscape := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
		if arg.begins_with("--size="):
			var parts := arg.trim_prefix("--size=").split("x")
			size = Vector2i(int(parts[0]), int(parts[1]))
		if arg == "--landscape": landscape = true
	if landscape: size = Vector2i(size.y, size.x)
	DirAccess.make_dir_recursive_absolute(artifact_dir)
	root.size = size
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await _settle(30)
	# The Clubhouse: every tab, top and bottom.
	await _capture("board")
	var club: Control = scene.clubhouse
	var board_scroll: ScrollContainer = club.pages.board.get_parent()
	board_scroll.scroll_vertical = 100000
	await _capture("board_end")
	board_scroll.scroll_vertical = 0
	for tab in ["binder", "trophies", "goals"]:
		await _tap(club.tab_buttons[tab])
		await _settle()
		await _capture(tab)
		var scroll: ScrollContainer = club.pages[tab].get_parent()
		if scroll.get_v_scroll_bar().max_value > scroll.size.y + 40:
			scroll.scroll_vertical = int(scroll.size.y * 0.8)
			await _capture(tab + "_scrolled")
			scroll.scroll_vertical = 0
	await _tap(club.tab_buttons.board)
	await _settle()
	# A first attempt.
	await _press(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim")
	lab = scene.lab
	lab.trial_log_path = ""
	await _settle(90)
	await _capture("aim")
	await _tap(lab.hud.badge)
	await _capture("rule_panel")
	await _tap(lab.hud.badge)
	if lab.card_hand.inspect_button.visible and not lab.card_hand.buttons.is_empty():
		await _tap(lab.card_hand.inspect_button)
		await _capture("inspect_pick")
		await _tap(lab.card_hand.buttons.values()[0])
		await _settle(30)
		await _capture("inspector")
		await _action("ui_cancel")
		await _settle(10)
		if lab.card_hand.inspecting: await _tap(lab.card_hand.inspect_button)
	await _press(scene.options)
	await _settle()
	await _capture("options")
	var options_scroll: Node = lab.settings_panel.close.get_parent()
	while options_scroll != null and not (options_scroll is ScrollContainer): options_scroll = options_scroll.get_parent()
	if options_scroll != null:
		(options_scroll as ScrollContainer).scroll_vertical = 100000
		await _capture("options_end")
		(options_scroll as ScrollContainer).scroll_vertical = 0
	await _tap(lab.settings_panel.tuning_button)
	await _settle()
	await _capture("tuning")
	await _tap(lab.settings_panel.tuning_box.get_node("CloseTuning"))
	await _press(lab.settings_panel.assist)
	await _press(lab.settings_panel.close)
	await _settle()
	await _capture("aim_assist")
	await _throw(STRIKE, "rolling")
	await _wait_for(func(): return lab.state == "scoring", ROLL_FRAMES)
	await _settle(50)
	await _capture("scoring")
	await _press(lab.score_panel.skip_button)
	await _wait_for(func(): return lab.state == "frame_done", ROLL_FRAMES)
	await _settle()
	await _capture("frame_done")
	await _press(lab.next_rack)
	if await _wait_for(func(): return lab.state == "shop", 120):
		await _settle(30)
		await _capture("shop")
		lab.shop_panel._scroll.scroll_vertical = 100000
		await _capture("shop_end")
		await _tap(lab.shop_panel.details_button)
		await _settle()
		lab.shop_panel._scroll.scroll_vertical = 100000
		await _capture("shop_details")
		lab.shop_panel._scroll.scroll_vertical = 0
		if lab.shop_panel.offer_buttons.size() > 0:
			await _tap(lab.shop_panel.button_for_offer(0))
			await _settle()
			await _capture("shop_after_buy")
			if lab.shop_panel.choice_sheet.visible:
				await _press(lab.shop_panel.cancel_choice)
		await _press(lab.shop_panel.continue_button)
	# An open frame in the next match: two-roll review.
	await _aim()
	await _settle(30)
	await _capture("match2_aim")
	await _throw(LEAVE)
	await _aim()
	await _settle(20)
	await _capture("roll2_aim")
	await _throw(GUTTER)
	await _wait_for(func(): return lab.state == "scoring", ROLL_FRAMES)
	await _press(lab.score_panel.skip_button)
	await _wait_for(func(): return lab.state == "frame_done", ROLL_FRAMES)
	await _settle()
	await _capture("open_frame")
	# Play gutters until the match is lost, for the result sheet.
	for i in 12:
		if lab.hud.result.visible or lab.state == "shop": break
		await _press(lab.next_rack)
		await _settle(10)
		if lab.hud.result.visible or lab.state != "aim": break
		await _throw(GUTTER)
		await _aim()
		if lab.state == "aim" and lab.roll_index == 2: await _throw(GUTTER)
		await _wait_for(func(): return lab.state == "scoring", ROLL_FRAMES)
		await _press(lab.score_panel.skip_button)
		await _wait_for(func(): return lab.state == "frame_done", ROLL_FRAMES)
	await _wait_for(func(): return lab.hud.result.visible, 120)
	await _settle(30)
	await _capture("result")
	print("ROGUEWOOD_TOUR_OK %d captures" % count)
	quit(0)
