extends "res://tests/charm_c01_journey.gd"
## J03C13 (E18-C13, the rules and lanes of E17-L02): the Neon League's three boss
## rules and two lanes in the real game, on the C13 fixture League
## (--content=neon_c13: the production catalogue and House Kit; three Divisions with
## low targets so assist strikes reach every boss). Real input throughout.
##   Division 1, Slick (Oil Slick) on Long Oil: the introduction and status name
##            the rule and the lane; the lane's rules halve the hook; a curved throw
##            commits its spin unchanged (it still counts as curved).
##   Division 2, Laser Lena (Narrow Lane) on Two-Tone: a start at the edge is
##            committed inside the new edges, and a throw drifting across them is a
##            gutter ball; a strike still wins.
##   Division 3, the Neon champion (Strobe plus Oil Slick) on Two-Tone: both rules
##            in the introduction, badge and status; the ring grades with halved
##            zones, and every roll's grade is the halved-zone grade of its crossing.
## Every bank equals an independent resolution. Run with --fixed-fps 60.
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Ring = preload("res://src/input/target_ring.gd")
const CURVE := [-0.4, 0.0, 0.5]
const EDGE := [0.95, 0.0, 0.6]
const DRIFT := [0.95, 0.4, 0.6]

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
	_check(lab.content.id == "neon_c13", "the C13 fixture League is loaded")
	_check(lab.lane.rules.is_empty() and lab.lane.gutter_edge() == Lane.LANE_HALF_WIDTH, "an opener plays the standard lane")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	await _slick()
	await _lena()
	await _champion()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C13_OK")
	quit(0 if failures.is_empty() else 1)

func _slick() -> void:
	await _to_boss("Division 1")
	_check(lab.hud.intro_body.text.contains("Oil Slick"), "Slick's introduction names Oil Slick")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "Slick's match ready")
	_check(lab.division.rules() == ["boss_rule.oil_slick"] and lab.lane.lane_condition == "lane_condition.long_oil", "Slick: Oil Slick on Long Oil")
	_check(lab.lane.rules == {"hook_scale": 0.5} and lab.hook_scale() == 0.5, "the lane halves the hook: %s" % str(lab.lane.rules))
	_check(lab.status.text.contains("Oil Slick: every hook is halved") and lab.status.text.contains("Lane: Long Oil"), "the status names the rule and the lane: %s" % lab.status.text)
	await _capture("c13_oil_slick")
	var curved := await _rule_frame([CURVE, CLEANUP], [0.5, 0.0], "Slick curved frame")
	var first: Dictionary = curved.reports[0]
	_check(is_equal_approx(float(first.launch.spin), 0.5) and Lane.is_curved(float(first.launch.spin)), "the curved throw commits its spin unchanged (%.2f)" % float(first.launch.spin))
	await _win("Slick")

func _lena() -> void:
	await _to_boss("Division 2")
	_check(lab.hud.intro_body.text.contains("Narrow Lane"), "Laser Lena's introduction names Narrow Lane")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "Laser Lena's match ready")
	var edge := Lane.LANE_HALF_WIDTH - 2.0 * Lane.BOARD_WIDTH
	_check(lab.division.rules() == ["boss_rule.narrow_lane"] and lab.lane.lane_condition == "lane_condition.two_tone", "Laser Lena: Narrow Lane on Two-Tone")
	_check(is_equal_approx(lab.lane.gutter_edge(), edge) and lab.status.text.contains("Narrow Lane: each gutter edge is two boards in") and lab.status.text.contains("Lane: Two-Tone"),
		"the edges are two boards in, and the status says so: %s" % lab.status.text)
	await _capture("c13_narrow_lane")
	var drifted := await _rule_frame([DRIFT, STRIKE], [0.0, 0.0], "Laser Lena drift frame")
	var gutter: Dictionary = drifted.reports[0]
	_check(is_equal_approx(float(gutter.launch.start_x), Lane.max_start_x(edge)), "a start at the edge is committed inside the new edges (%.3f)" % float(gutter.launch.start_x))
	_check(gutter.knockdown_log.gutter and gutter.roll_result.fallen_positions.is_empty(), "a throw drifting across the new edge is a gutter ball")
	await _win("Laser Lena")

func _champion() -> void:
	await _to_boss("Division 3")
	_check(lab.hud.intro_body.text.contains("Strobe") and lab.hud.intro_body.text.contains("Oil Slick"), "the champion's introduction names both rules")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "the champion's match ready")
	_check(lab.division.rules() == ["boss_rule.strobe", "boss_rule.oil_slick"] and lab.hud.badge.text.contains("Strobe") and lab.hud.badge.text.contains("Oil Slick"),
		"the champion carries Strobe and Oil Slick, and the badge shows both: %s" % lab.hud.badge.text)
	# A two-rule badge stacks on a phone: the bar is a line taller, stays inside its
	# region (clear of the session menu button) and above the info row.
	await process_frame
	await process_frame
	var bar: Rect2 = lab.hud.bar.get_global_rect()
	_check(lab.hud.badge.text.contains("\n") and bar.end.x <= lab.regions.top_bar.end.x + 0.5 and not bar.intersects(scene.menu_button.get_global_rect())
		and bar.end.y <= lab.panels.slip.get_global_rect().position.y, "the two-rule bar stays clear of the menu button and the info row (%s)" % str(bar))
	# The badge's ⓘ can fall back to a taller system font on another machine (Codex
	# measured a 70 px badge). A logged fixture makes the badge taller here: the bar
	# and the rows under it follow its real height.
	lab.hud.badge.add_theme_constant_override("line_spacing", 14)
	lab._update_status()
	await process_frame
	await process_frame
	bar = lab.hud.bar.get_global_rect()
	print("J03C13 fixture: badge line spacing +14 (badge %s, bar %s, slip at %d)" % [str(lab.hud.badge.size), str(bar), int(lab.panels.slip.get_global_rect().position.y)])
	_check(lab.hud.badge.size.y >= 66.0 and bar.end.x <= lab.regions.top_bar.end.x + 0.5 and bar.end.y <= lab.panels.slip.get_global_rect().position.y,
		"a taller badge still leaves the bar above the info row (%s)" % str(bar))
	lab.hud.badge.remove_theme_constant_override("line_spacing")
	lab._update_status()
	await process_frame
	_check(lab.lane.rules == {"zone_scale": 0.5, "hook_scale": 0.5} and lab.zone_scale() == 0.5, "the lane halves the ring zones and the hook")
	_check(lab.status.text.contains("Strobe: the ring's sweet and perfect zones are half their size") and lab.status.text.contains("Oil Slick"), "the status names both rules")
	_check(Ring.grade(0.075, lab.zone_scale()) == "sweet" and Ring.grade(0.075) == "perfect", "under Strobe the ring at 0.075 grades sweet, not perfect")
	await _capture("c13_champion")
	var before: int = lab.history.size()
	await _win("the champion")
	for report in lab.history.slice(before):
		var log: Dictionary = report.knockdown_log
		_check(report.roll_result.accuracy == Lane.grade_accuracy(log.target_crossed, log.target_offset - report.launch.target_x, report.launch.ring_radius, 0.5),
			"%s grades with Strobe's halved zones (%s)" % [report.launch.launch_id, report.roll_result.accuracy])

## Strikes until the boss is beaten, each frame checked against its resolution.
func _win(label: String) -> void:
	while true:
		await _focus_accept(lab.next_rack)
		var strike := await _rule_frame([STRIKE], [0.0], label + " strike")
		if strike.match_over:
			break
	_check(lab.division.match_score >= lab.division.target() or lab.state in ["shop", "division_over"], "a strike beats %s" % label)
	await _focus_accept(lab.next_rack)
	if lab.state == "shop":
		await _leave_shop()

## Strikes through the opener and feature (leaving each shop) until the boss's introduction.
func _to_boss(label: String) -> void:
	for i in 2:
		await _wait_for(func(): return lab.state == "aim", label + " match ready")
		await _strike_out()
		await _to_shop(label)
		await _leave_shop()
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, label + " boss introduction")

## Throws (with the given spins), then checks the bank against an independent resolution.
func _rule_frame(shots: Array, spins: Array, label: String) -> Dictionary:
	var rules: Array = lab.division.rules()
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = RivalRules.frame_loadout(rules, lab.run.loadout())
	var before: int = lab.history.size()
	await _throw(shots[0], spins[0])
	_check(lab.lane.rules == RivalRules.lane_rules(rules), "%s: the roll's lane carries the rules in force" % label)
	if shots.size() > 1 and lab.state != "scoring":
		await _aim()
		await _throw(shots[1], spins[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(loadout, lab.content.catalogue, reports, {}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	var banked: int = RivalRules.bank(rules, expected).score if built.ok else -1
	print("J03C13 %s: category=%s banked=%d expected=%d rules=%s lane=%s launches=%s" % [label, scored.result.category, scored.banked, banked, str(rules), lab.lane.lane_condition,
		str(reports.map(func(r): return [snappedf(float(r.launch.start_x), 0.001), snappedf(float(r.launch.spin), 0.01), r.knockdown_log.gutter, r.roll_result.accuracy]))])
	_check(built.ok and scored.banked == banked, "%s banks the independent resolution (%d vs %d)" % [label, scored.banked, banked])
	return {"result": scored.result, "banked": int(scored.banked), "reports": reports, "match_over": bool(scored.match_over)}

func _capture(label: String) -> void:
	print("J03C13 %s lab=%s rules=%s lane=%s score=%d" % [label, lab.state, str(lab.division.rules()), lab.lane.lane_condition, lab.division.match_score])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
