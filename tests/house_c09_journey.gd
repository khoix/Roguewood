extends "res://tests/house_c08_journey.gd"
## J03C09 (E18-C09, DC-H2): the six D08 House Charms bought through the real Pro Shop
## and scored in real throws on the production slice (real targets, not Practice).
## Fixture setup (logged, as J05 does): a wallet grant after the opener; offers,
## rerolls, purchases and the sale are real taps.
##   opener shop:  Trophy Case, Corner Pockets, Late Rally, Clean Pickup, House Special;
##   feature f1:   an open frame: Late Rally stays silent in frame 1;
##   feature f2:   behind in frame 2, a House Ball strike: Late Rally, House Special and
##                 Corner Pockets apply, and Trophy Case earns its first trophy;
##   feature shop: Late Rally is sold and Front Line bought;
##   Surveyor f1:  a straight spare under Dead Straight: Clean Pickup, Front Line and
##                 Trophy Case's +1 Mult apply.
## Every bank equals an independent resolution with the run's loadout and context.
## Run with --fixed-fps 60.
const D08 := ["charm.trophy_case", "charm.corner_pockets", "charm.late_rally", "charm.clean_pickup", "charm.house_special"]

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
	_check(not lab.division.practice, "a real match, not Practice")
	await _strike_out()
	await _to_shop("opener")
	lab.run.credit(200, "fixture: C09 Charm sampling")
	lab._refresh_shop()
	print("J03C09 fixture: $200 granted after the opener; offers, rerolls and purchases follow")
	await _buy(D08)
	await _capture("c09_shop")
	await _leave_shop()
	var open := await _house_frame([LEAVE, GUTTER], "feature frame 1")
	_check(open.result.category == "open" and not _logged("Late Rally") and not open.match_over, "frame 1: Late Rally stays silent; the match goes on")
	await _focus_accept(lab.next_rack)
	_check(lab.division.match_score * 2 < lab.division.target(), "behind going into frame 2 (%d of %d)" % [lab.division.match_score, lab.division.target()])
	var strike := await _house_frame([STRIKE], "feature frame 2")
	_check(strike.result.category == "strike" and _logged("Late Rally") and _logged("House Special") and _logged("Corner Pockets") and strike.match_won,
		"frame 2: Late Rally, House Special and Corner Pockets apply to a House Ball strike, which wins the feature")
	_check(int(lab.run.charms.filter(func(e): return e.item_id == "charm.trophy_case")[0].growth) == 1, "Trophy Case earned its first trophy")
	await _capture("c09_rally")
	await _to_shop("feature")
	var index: int = lab.run.charms.map(func(e): return e.item_id).find("charm.late_rally")
	await _tap(lab.shop_panel.owned_list.get_node("Sell_charm_%d" % (index + 1)))
	await process_frame
	_check(not lab.run.charms.any(func(e): return e.item_id == "charm.late_rally"), "Late Rally sold to free a slot")
	await _buy(["charm.front_line"])
	await _leave_shop()
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, "The Surveyor's introduction")
	await _focus_accept(lab.hud.intro_button)
	await _aim()
	_check(lab.spin_disabled(), "Dead Straight: every roll is straight")
	var spare := await _house_frame([LEAVE, CLEANUP], "Surveyor frame 1")
	_check(spare.result.category == "spare" and _logged("Clean Pickup") and _logged("Front Line") and _logged("Trophy Case"),
		"a straight spare: Clean Pickup, Front Line and Trophy Case's trophy apply")
	await _capture("c09_pickup")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C09_OK")
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	print("J03C09 %s lab=%s money=%d score=%d charms=%s" % [label, lab.state, lab.run.money, lab.division.match_score, str(lab.run.charms.map(func(e): return "%s:%d" % [e.item_id, int(e.growth)]))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
