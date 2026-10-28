extends "res://tests/slice_journey.gd"
## J03C01 (E18-C01): the five C01 Charms that need no special shot score in the real
## game. Fixture setup seats Pin Counter, Plumb Line, Hot Streak, Last Stand and Tip
## Jar through the inventory API (logged, as J05 does); everything else is real
## input on the production slice in Practice (no targets):
##   frame 1 strike: Pin Counter (+10) and Plumb Line (+5) apply; Hot Streak waits;
##   frame 2 strike: Hot Streak applies on the second strike in a row;
##   frame 3 spare: Tip Jar pays $1 with the frame income; the streak resets;
##   frame 4 open: Last Stand adds +2 Mult per standing pin.
## Each banked score must equal an independent FrameBuilder + FrameRules resolution
## of the same reports, loadout and context. Banana Ball (a curved strike) is
## covered by rule tests; a reliable curved strike through input is not assumed.
## Run with --fixed-fps 60.
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const CLEANUP := [0.0, 0.0, 0.6]
const SEATED := ["charm.pin_counter", "charm.plumb_line", "charm.hot_streak", "charm.last_stand", "charm.tip_jar"]

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
	await _focus_accept(lab.settings_panel.practice)
	await _focus_accept(lab.settings_panel.close)
	_check(lab.division.practice, "Practice is on before the first throw")
	for id in SEATED:
		_check(lab.run.place(id, 0, "charm:new").is_empty(), "fixture: seat " + id)
	print("J03C01 fixture: seated %s through the inventory API" % str(lab.run.charms.map(func(e): return e.item_id)))
	var first := await _checked_frame([STRIKE], "strike 1")
	_check(_logged("Pin Counter") and _logged("Plumb Line") and not _logged("Hot Streak") and not _logged("Last Stand"), "frame 1: Pin Counter and Plumb Line apply; Hot Streak waits")
	_check(first.income == 0, "no payout on a strike")
	await _capture("c01_strike")
	await _next()
	await _checked_frame([STRIKE], "strike 2")
	_check(_logged("Hot Streak"), "frame 2: Hot Streak applies on the second strike in a row")
	await _capture("c01_streak")
	await _next()
	var spare := await _checked_frame([LEAVE, CLEANUP], "spare")
	_check(spare.result.category == "spare" and spare.income == 1 and not _logged("Hot Streak") and lab.run.strike_streak == 0,
		"frame 3: Tip Jar pays $1 on the spare; the streak resets")
	await _capture("c01_spare")
	await _next()
	var open := await _checked_frame([LEAVE, GUTTER], "open")
	var standing: int = 10 - open.frame.rolls.reduce(func(n, r): return n + r.fallen_positions.size(), 0)
	_check(open.result.category == "open" and standing > 0 and _logged("Last Stand"), "frame 4: Last Stand counts %d standing pins" % standing)
	await _capture("c01_open")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C01_OK")
	quit(0 if failures.is_empty() else 1)

func _logged(name: String) -> bool:
	return _log_lines().any(func(l): return l.contains(name))

## Practice plays each match's whole budget; after a match the shop opens.
func _next() -> void:
	await _focus_accept(lab.next_rack)
	if lab.state == "shop":
		await _leave_shop()

## Throws the shots (roll 2 only if pins stand), then checks the banked score
## against an independent resolution with the run's loadout and context.
func _checked_frame(shots: Array, label: String) -> Dictionary:
	var streak: int = lab.run.strike_streak
	var match_frame: int = lab.match_frame
	var before: int = lab.history.size()
	await _throw(shots[0])
	if shots.size() > 1:
		await _aim()
		await _throw(shots[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(lab.run.loadout(), lab.content.catalogue, reports, {}, {"match_frame": match_frame, "strike_streak": streak})
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	print("J03C01 %s: category=%s banked=%d expected=%d income=%d streak_before=%d" % [label, scored.result.category, scored.banked, expected.score, scored.income, streak])
	_check(built.ok and scored.banked == expected.score, "%s banks the independent resolution (%d vs %d)" % [label, scored.banked, expected.score])
	return scored

func _capture(label: String) -> void:
	print("J03C01 %s lab=%s score=%d money=%d charms=%s" % [label, lab.state, lab.division.match_score, lab.run.money, str(lab.run.charms.map(func(e): return e.item_id))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
