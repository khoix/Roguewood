extends "res://tests/charm_c01_journey.gd"
## J03C05 (E18-C05): House Rules, House Pins, a two-rule champion and both House
## lane conditions in the real game, on the C05 fixture League (--content=house_c05:
## the production catalogue and kit; two Divisions with low targets so assist
## strikes reach both bosses). Real input throughout; one logged fixture racks a
## Ruby Pin at position 1 before Old Lou's match through the inventory API.
##   Division 1, the House champion on Dry Backend: the introduction and badge name
##            Clean Sweep and House Rules; the lane is Dry Backend; arming a ball card
##            is refused with a note; a leave and a gutter commit House Ball launches
##            and bank 0 (Clean Sweep); a strike with the House Ball wins.
##   Division 2, Old Lou on House Oil: the lane is House Oil; a strike over a rack with
##            a Ruby Pin banks exactly the Wood-rack resolution (the Ruby's +2 Mult is
##            off) and the explanation says the rack scored as plain Wood.
## Every bank equals an independent resolution with the rules' loadout and constraints.
## Run with --fixed-fps 60.
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")

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
	_check(lab.content.id == "house_c05", "the C05 fixture League is loaded")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	await _to_boss("Division 1")
	_check(lab.hud.intro_body.text.contains("Clean Sweep") and lab.hud.intro_body.text.contains("House Rules"), "the champion's introduction names both rules")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "champion match ready")
	_check(lab.division.rules() == ["boss_rule.clean_sweep", "boss_rule.house_rules"] and lab.hud.badge.text.contains("Clean Sweep") and lab.hud.badge.text.contains("House Rules"),
		"the badge shows both champion rules: %s" % lab.hud.badge.text)
	_check(lab.lane.lane_condition == "lane_condition.dry_backend", "the champion's lane is Dry Backend")
	var refused := false
	for option in lab.equipment.options():
		if option.kind == "ball":
			await _tap(lab.card_hand.button_for(option.uid))
			refused = lab.armed_ball_id() == "ball.house" and lab.status.text.contains("House Rules: that ball cannot be thrown here.")
			break
	_check(refused, "arming a ball card is refused under House Rules, with a note")
	await _capture("c05_house_rules")
	var open := await _rule_frame([LEAVE, GUTTER], "champion open frame")
	_check(open.result.category == "open" and open.banked == 0 and _logged("Clean Sweep"), "Clean Sweep banks an open frame as 0")
	await _focus_accept(lab.next_rack)
	var strike := await _rule_frame([STRIKE], "champion strike")
	_check(strike.banked > 0 and lab.division.match_score >= lab.division.target(), "a House Ball strike beats the champion (%d of %d)" % [lab.division.match_score, lab.division.target()])
	await _capture("c05_champion")
	await _focus_accept(lab.next_rack)
	if lab.state == "shop":
		await _leave_shop()
	await _to_boss("Division 2")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "Old Lou's match ready")
	_check(lab.division.rules() == ["boss_rule.house_pins"] and lab.lane.lane_condition == "lane_condition.house_oil", "Old Lou: House Pins on House Oil")
	lab.run.rack[1] = Inventory._entry("pin.ruby", 0)
	print("J03C05 fixture: a Ruby Pin racked at position 1 through the inventory API")
	var plain := await _rule_frame([STRIKE], "Old Lou strike")
	var wood_rack := {"pins": {}, "charms": [], "pin_mods": {}}
	for p in range(1, 11): wood_rack.pins[p] = "pin.wood"
	var wood := Rules.resolve(Builder.build(wood_rack, lab.content.catalogue, plain.reports, {}, plain.context).frame)
	_check(plain.banked == wood.score and _logged("House Pins: every pin was scored as plain Wood"), "the Ruby rack banks exactly the Wood resolution (%d), and the explanation says so" % wood.score)
	await _capture("c05_house_pins")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C05_OK")
	quit(0 if failures.is_empty() else 1)

## Strikes through the opener and feature (leaving each shop) until the boss's introduction.
func _to_boss(label: String) -> void:
	for i in 2:
		await _wait_for(func(): return lab.state == "aim", label + " match ready")
		await _strike_out()
		await _to_shop(label)
		await _leave_shop()
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, label + " boss introduction")

## Throws, then checks the bank and every committed launch against the rules in force.
func _rule_frame(shots: Array, label: String) -> Dictionary:
	var rules: Array = lab.division.rules()
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = RivalRules.frame_loadout(rules, lab.run.loadout())
	var before: int = lab.history.size()
	await _throw(shots[0])
	if shots.size() > 1 and lab.state != "scoring":
		await _aim()
		await _throw(shots[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	_check(reports.all(func(r): return RivalRules.ball_allowed(rules, r.launch.ball_id)), "%s: every committed launch obeys the rules (%s)" % [label, str(reports.map(func(r): return r.launch.ball_id))])
	var built := Builder.build(loadout, lab.content.catalogue, reports, {}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	var banked: int = RivalRules.bank(rules, expected).score if built.ok else -1
	print("J03C05 %s: category=%s banked=%d expected=%d rules=%s lane=%s" % [label, scored.result.category, scored.banked, banked, str(rules), lab.lane.lane_condition])
	_check(built.ok and scored.banked == banked, "%s banks the independent resolution (%d vs %d)" % [label, scored.banked, banked])
	return {"result": scored.result, "banked": int(scored.banked), "reports": reports, "context": context}

func _capture(label: String) -> void:
	print("J03C05 %s lab=%s rules=%s lane=%s score=%d" % [label, lab.state, str(lab.division.rules()), lab.lane.lane_condition, lab.division.match_score])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
