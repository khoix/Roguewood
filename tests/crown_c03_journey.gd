extends "res://tests/charm_c01_journey.gd"
## J03C03 (E18-C03): Crown Pin and the five C03 Charms in the real game, on the
## production slice with real match targets (not Practice). Fixture setup (logged,
## as J05 does) racks Crown pins at 6 and 8 and seats Underdog, Back Row, Crown
## Jewel, Split Specialist and Sweet Spot through the inventory API; everything else
## is real input.
##   frame 1 split and conversion (the first roll leaves 1, 3, 8 and 10; the second
##            clears them): Split Specialist triples the spare; Underdog doubles at 0
##            of the target;
##   frame 2 strike: Back Row counts the back row.
## On both frames Underdog applies exactly when the lab's match score is below half
## its target; each Crown pays +40 only if it fell last in the real knockdown log,
## else shows +0; Crown Jewel follows the same test; Sweet Spot follows the grades.
## These shots end on pin 8 (frame 1) and pin 6 (frame 2), so each frame shows one
## Crown's +40 with Crown Jewel and the other Crown's clear 0. Underdog's "not behind"
## branch is covered by rule tests: every frame here starts a match at 0.
## Every bank equals an independent FrameBuilder + FrameRules resolution with the
## lab's own frame context (match score and target). Run with --fixed-fps 60.
const SEATED_C03 := ["charm.underdog", "charm.back_row", "charm.crown_jewel", "charm.split_specialist", "charm.sweet_spot"]
const Inventory = preload("res://src/rules/run_inventory.gd")
const CROWNS := [6, 8]
const SPLIT := [-0.5, 0.0, 0.6]
const CONVERT := [0.3, 0.0, 0.6]

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
	_check(not lab.division.practice and lab.division.target() > 0, "a real match with a target")
	for position in CROWNS:
		lab.run.rack[position] = Inventory._entry("pin.crown", 0)
	for id in SEATED_C03:
		_check(lab.run.place(id, 0, "charm:new").is_empty(), "fixture: seat " + id)
	print("J03C03 fixture: Crown pins at %s and %s seated through the inventory API" % [str(CROWNS), str(lab.run.charms.map(func(e): return e.item_id))])
	var first := await _c03_frame([SPLIT, CONVERT], "frame 1")
	var leave: int = 10 - first.frame.rolls[0].fallen_positions.size()
	_check(first.result.category == "spare" and leave >= 4 and _logged("Split Specialist") and _logged("first roll left %d, needs 4+" % leave),
		"frame 1: Split Specialist triples a spare after a leave of %d (%s)" % [leave, first.result.category])
	_underdog(first)
	_crowns(first)
	await _capture("c03_split")
	await _next()
	var second := await _c03_frame([STRIKE], "frame 2")
	_check(second.result.category == "strike" and _logged("Back Row") and _logged("per back-row pin down"), "frame 2: Back Row counts the back row")
	_check(not _logged("Split Specialist"), "frame 2: Split Specialist skips a strike")
	_underdog(second)
	_crowns(second)
	await _capture("c03_strike")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C03_OK")
	quit(0 if failures.is_empty() else 1)

## Throws, then checks the bank against an independent resolution with the lab's context.
func _c03_frame(shots: Array, label: String) -> Dictionary:
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	var before: int = lab.history.size()
	await _throw(shots[0])
	if shots.size() > 1 and lab.state != "scoring":
		await _aim()
		await _throw(shots[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(loadout, lab.content.catalogue, reports, {}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	print("J03C03 %s: category=%s banked=%d expected=%d context=%s" % [label, scored.result.category, scored.banked, expected.score, str(context)])
	_check(built.ok and scored.banked == expected.score, "%s banks the independent resolution (%d vs %d)" % [label, scored.banked, expected.score])
	return {"result": scored.result, "frame": built.frame if built.ok else {}, "context": context, "reports": reports}

## Underdog follows the lab's own context: below half the target, it doubles and says so.
func _underdog(played: Dictionary) -> void:
	var c: Dictionary = played.context
	var behind: bool = c.match_target > 0 and c.match_score * 2 < c.match_target
	_check(_logged("Underdog") == behind and (not behind or _logged("behind: %d vs half of %d" % [c.match_score, c.match_target])),
		"Underdog %s at %d of %d" % ["doubles" if behind else "stays off", c.match_score, c.match_target])

## Each fallen Crown pays +40 only if it was the frame's last knockdown (from the real
## knockdown log, read independently here); Crown Jewel and Sweet Spot follow their tests.
func _crowns(played: Dictionary) -> void:
	var last := 0
	var fallen := {}
	for report in played.reports:
		for entry in report.knockdown_log.knockdowns:
			fallen[int(entry.position)] = true
		if not report.knockdown_log.knockdowns.is_empty():
			last = int(report.knockdown_log.knockdowns.back().position)
	print("J03C03 last knockdown: pin %d; Crowns down: %s" % [last, str(CROWNS.filter(func(p): return fallen.has(p)))])
	for position in CROWNS:
		if not fallen.has(position):
			continue
		var paid := "Pin %d Crown Pin +40 Value (fell last)" % position
		var zero := "Pin %d Crown Pin +0 Value (did not fall last)" % position
		_check(_logged(paid) == (position == last) and _logged(zero) == (position != last), "Crown at %d: %s" % [position, "+40, it fell last" if position == last else "a clear 0"])
	_check(_logged("Crown Jewel") == (last in CROWNS), "Crown Jewel applies exactly when a Crown fell last")
	_check(last in CROWNS, "this shot's last knockdown is a Crown (pin %d), so the +40 is shown natively" % last)
	var graded: int = played.reports.filter(func(r): return r.roll_result.accuracy in ["sweet", "perfect"]).size()
	_check(_logged("Sweet Spot") == (graded > 0), "Sweet Spot follows the ring grades (%d graded)" % graded)

func _capture(label: String) -> void:
	print("J03C03 %s lab=%s score=%d charms=%s" % [label, lab.state, lab.division.match_score, str(lab.run.charms.map(func(e): return e.item_id))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
