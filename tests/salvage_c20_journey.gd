extends "res://tests/neon_c13_journey.gd"
## J03C20 (E18-C20, the rules and lanes of E17-L03): the Salvage League's three boss
## rules and two lanes in the real game, on the C20 fixture League
## (--content=salvage_c20: the production catalogue, a rack with Tin pins at 7 and
## 10, three Divisions with low targets). Real input throughout, apart from two
## logged fixture steps that attach modifications before the champion.
##   Division 1, Miser Moll (Frugal House) on Warped Boards: the introduction and
##            status name the rule and the lane; two gutter balls leave both Tin
##            pins standing, and their $2 is kept by the house: the run's money is
##            unchanged and the log says so. A strike then wins.
##   Division 2, Grimewell (Dull Pins) on Grit: a strike banks every pin's Value
##            halved, and the log marks each halved step.
##   Division 3, the Salvage champion (Rust plus Dull Pins) on Grit: both rules in
##            the introduction, badge and status; a Brass Cap on pin 1 and a Bumper
##            Guard on a deck card do nothing (the scored rack has no modification,
##            the card brings nothing to the roll), and the run keeps both.
## Every bank equals an independent resolution. Run with --fixed-fps 60.

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
	_check(lab.content.id == "salvage_c20", "the C20 fixture League is loaded")
	_check(lab.lane.lane_condition in ["lane.house", "lane_condition.house_oil"] and lab.lane.rules.is_empty(), "an opener plays House Oil")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	await _moll()
	await _grimewell()
	await _scrapjack()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C20_OK")
	quit(0 if failures.is_empty() else 1)

func _moll() -> void:
	await _to_boss("Division 1")
	_check(lab.hud.intro_body.text.contains("Frugal House"), "Miser Moll's introduction names Frugal House")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "Miser Moll's match ready")
	_check(lab.division.rules() == ["boss_rule.frugal_house"] and lab.lane.lane_condition == "lane_condition.warped_boards", "Miser Moll: Frugal House on Warped Boards")
	_check(lab.status.text.contains("Frugal House: items pay no money") and lab.status.text.contains("Lane: Warped Boards"), "the status names the rule and the lane: %s" % lab.status.text)
	await _capture("c20_frugal_house")
	var money: int = lab.run.money
	var gutters := await _rule_frame([GUTTER, GUTTER], [0.0, 0.0], "Miser Moll gutter frame")
	var standing: Array = gutters.reports[-1].knockdown_log.standing
	_check(7 in standing and 10 in standing, "both Tin pins stood (standing %s)" % str(standing))
	var scored: Dictionary = lab.scored_frames[-1]
	var kept: Array = scored.steps.filter(func(s): return s.phase == "after_bank" and String(s.text).contains("kept by the house"))
	_check(kept.size() == 2 and scored.steps.any(func(s): return String(s.text).contains("Frugal House: item payouts paid nothing ($2 kept by the house)")),
		"the log marks both Tin payouts as kept by the house, and names the $2")
	_check(int(scored.income) == 0 and lab.run.money == money, "the run is paid nothing for the frame ($%d before and after)" % money)
	await _win("Miser Moll")

func _grimewell() -> void:
	await _to_boss("Division 2")
	_check(lab.hud.intro_body.text.contains("Dull Pins"), "Grimewell's introduction names Dull Pins")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "Grimewell's match ready")
	_check(lab.division.rules() == ["boss_rule.dull_pins"] and lab.lane.lane_condition == "lane_condition.grit", "Grimewell: Dull Pins on Grit")
	_check(lab.status.text.contains("Dull Pins: every pin's Value is halved") and lab.status.text.contains("Lane: Grit"), "the status names the rule and the lane: %s" % lab.status.text)
	_check(not lab.card_rules({"ball_id": "ball.house", "mod": "ball_mod.bumper_guard"}).is_empty(), "without Rust, a Bumper Guard would rebound the roll")
	await _capture("c20_dull_pins")
	await _win("Grimewell")
	var scored: Dictionary = lab.scored_frames[-1]
	_check(scored.steps.any(func(s): return String(s.text).contains("Dull Pins: half of 10")) and scored.steps.any(func(s): return String(s.text).contains("Dull Pins: every pin's Value was halved")),
		"the log marks the halved pins and the rule")

func _scrapjack() -> void:
	await _to_boss("Division 3")
	_check(lab.hud.intro_body.text.contains("Rust") and lab.hud.intro_body.text.contains("Dull Pins"), "the champion's introduction names both rules")
	# Fixture (logged): a Brass Cap on pin 1 and a Bumper Guard on a deck card, as if bought.
	lab.run.rack[1].mod = "pin_mod.brass_cap"
	var card: String = lab.run.cards.keys()[0]
	lab.run.cards[card].mod = "ball_mod.bumper_guard"
	print("J03C20 fixture: Brass Cap on pin 1, Bumper Guard on %s" % card)
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "the champion's match ready")
	var rules: Array = lab.division.rules()
	_check(rules == ["boss_rule.rust", "boss_rule.dull_pins"] and lab.hud.badge.text.contains("Rust") and lab.hud.badge.text.contains("Dull Pins") and lab.lane.lane_condition == "lane_condition.grit",
		"the champion carries Rust and Dull Pins on Grit, and the badge shows both: %s" % lab.hud.badge.text)
	_check(lab.status.text.contains("Rust: every ball and pin modification is switched off") and lab.status.text.contains("Dull Pins"), "the status names both rules")
	_check(lab.card_rules({"ball_id": "ball.house", "mod": "ball_mod.bumper_guard"}).is_empty(), "under Rust the Bumper Guard brings nothing to the roll")
	_check(lab.run.loadout().pin_mods == {1: "pin_mod.brass_cap"} and RivalRules.frame_loadout(rules, lab.run.loadout()).pin_mods.is_empty(), "the rack keeps its Brass Cap; the scored rack has none")
	await _capture("c20_champion")
	await _win("the champion")
	var last: Dictionary = lab.scored_frames[-1]
	_check(last.frame.pins.all(func(p): return p.effects.all(func(e): return e.op != "add_mult")), "no pin in the scored frame carries the Brass Cap's Mult")
	_check(lab.run.rack[1].mod == "pin_mod.brass_cap" and lab.run.cards[card].mod == "ball_mod.bumper_guard", "the run keeps both modifications after the match")

## Strikes (aimed left of the usual line on Warped Boards, which pushes the ball
## right) until the boss is beaten; a frame that leaves pins is cleaned up.
const WARPED_STRIKE := [-0.12, 0.0, 0.7]

func _win(label: String) -> void:
	while true:
		await _focus_accept(lab.next_rack)
		var shot: Array = WARPED_STRIKE if lab.lane.lane_condition == Lane.WARPED_BOARDS else STRIKE
		var frame := await _rule_frame([shot, CLEANUP], [0.0, 0.0], label + " frame")
		if frame.match_over:
			break
	_check(lab.division.outcome != "lost", "%s is beaten" % label)
	await _focus_accept(lab.next_rack)
	if lab.state == "shop":
		await _leave_shop()

## Throws, then checks the bank against an independent resolution with the rules'
## loadout, context (Dull Pins) and pay (Frugal House).
func _rule_frame(shots: Array, spins: Array, label: String) -> Dictionary:
	var rules: Array = lab.division.rules()
	var context: Dictionary = RivalRules.frame_context(rules, lab.frame_context())
	var loadout: Dictionary = RivalRules.frame_loadout(rules, lab.run.loadout())
	var before: int = lab.history.size()
	await _throw(shots[0], spins[0])
	await _wait_for(func(): return lab.state == "scoring" or (lab.state == "aim" and lab.lane.state == "ready"), label + " next roll or scoring", ROLL_FRAMES)
	if shots.size() > 1 and lab.state != "scoring":
		await _aim()
		await _throw(shots[1], spins[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(loadout, lab.content.catalogue, reports, {}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	var banked: int = RivalRules.bank(rules, expected).score if built.ok else -1
	var pay: int = RivalRules.paid(rules, expected).result.get("future_effects", []).filter(func(e): return e.op == "payout").reduce(func(a, e): return a + int(e.amount), 0) if built.ok else -1
	var kept: int = int(RivalRules.paid(rules, expected).kept) if built.ok else -1
	print("J03C20 %s: category=%s banked=%d expected=%d income=%d expected_income=%d kept=%d rules=%s lane=%s fallen=%s pins=%s" % [label, scored.result.category, scored.banked, banked, int(scored.income), pay, kept, str(rules),
		lab.lane.lane_condition, str(reports.map(func(r): return r.roll_result.fallen_positions.size())), str(loadout.pins.values())])
	_check(built.ok and scored.banked == banked and int(scored.income) == pay, "%s banks and pays the independent resolution (%d vs %d, $%d vs $%d)" % [label, scored.banked, banked, int(scored.income), pay])
	return {"result": scored.result, "banked": int(scored.banked), "reports": reports, "match_over": bool(scored.match_over)}

func _capture(label: String) -> void:
	print("J03C20 %s lab=%s rules=%s lane=%s score=%d money=%d" % [label, lab.state, str(lab.division.rules()), lab.lane.lane_condition, lab.division.match_score, lab.run.money])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

