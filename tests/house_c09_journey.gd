extends "res://tests/house_c08_journey.gd"
## J03C09 (E18-C09, DC-H2): the six D08 House Charms bought through the real Pro Shop
## and scored in real throws on the production slice (real targets, not Practice).
## Fixture setup (logged, as J05 does): an $8000 wallet grant after the opener (rerolls
## rise in price within a visit); offers,
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
	tag = "J03C09"
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
	lab.run.credit(8000, "fixture: C09 Charm sampling")
	# House Special is The Proprietor's first-clear reward (E22-L01); this attempt's pool gets its gate.
	if "gate.proprietor_cleared" not in lab.shop.unlocked: lab.shop.unlocked.append("gate.proprietor_cleared")
	lab._refresh_shop()
	print("J03C09 fixture: $8000 granted and gate.proprietor_cleared added to this attempt's pool after the opener; offers, rerolls and purchases follow")
	await _buy(D08)
	await _capture("c09_shop")
	await _leave_shop()
	var open := await _house_frame([LEAVE, GUTTER], "feature frame 1")
	_check(open.result.category == "open" and not _logged("Late Rally") and not open.match_over, "frame 1: Late Rally stays silent; the match goes on")
	await process_frame
	_check(not lab.motion.house_counts.rally_lit and lab.motion.house_counts.trophy_count == 0,"frame one stays dim and has no trophy")
	await _capture("c09_first_frame")
	await _focus_accept(lab.next_rack)
	_check(lab.division.match_score * 2 < lab.division.target(), "behind going into frame 2 (%d of %d)" % [lab.division.match_score, lab.division.target()])
	var strike := await _house_frame([STRIKE], "feature frame 2")
	_check(strike.result.category == "strike" and _logged("Late Rally") and _logged("House Special") and _logged("Corner Pockets") and strike.match_won,
		"frame 2: Late Rally, House Special and Corner Pockets apply to a House Ball strike, which wins the feature")
	_check(int(lab.run.charms.filter(func(e): return e.item_id == "charm.trophy_case")[0].growth) == 1, "Trophy Case earned its first trophy")
	await process_frame
	_check(lab.motion.house_counts.trophy_count == 1 and lab.motion.house_counts.landed,"trophy lands after bank")
	_check(lab.motion.house_counts.rally_lit and lab.motion.house_counts.rally_score == 120 and lab.motion.house_counts.rally_target == 500,"rally retains pre-bank score against half target")
	await _capture("c09_rally")
	await _to_shop("feature")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.has_focus(),"C09 Continue offered")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "shop","C09 restored shop")
	lab = scene.lab
	lab.trial_log_path = ""
	await process_frame
	_check(lab.motion.house_counts.shop_text.text.contains("1 trophies"),"saved Trophy Case count restores")
	_check(not lab.motion.abilities.history.any(func(e): return e.id == "charm.trophy_case"),"restored trophy does not replay growth")
	await _capture("c09_restored_trophy")
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
	await process_frame
	_check(lab.motion.house_counts.trophy_count == 1 and not lab.motion.house_counts.landed,"spare retains one trophy without new growth")
	await _capture("c09_pickup")
	var cards_type = preload("res://src/presentation/house_count_cards.gd")
	for context in [{"match_frame":1,"match_score":0,"match_target":500},{"match_frame":2,"match_score":250,"match_target":500},{"match_frame":2,"match_score":0,"match_target":0}]:
		_check(not cards_type.eligible(context),"Late Rally negative boundary/Practice")
	var projection = preload("res://src/presentation/ability_events.gd")
	for positions in [[],[7],[7,10]]:
		var fixture := {"charms":[{"item_id":"charm.corner_pockets"}],"rolls":[{"fallen_positions":positions}]}
		var cues: Array = projection.project(fixture,{"source":"charm:1","phase":"charm","op":"add_value","amount":25,"count":positions.size()})
		_check(cues[0].positions == positions,"corner projection zero/one/two positions")
	for id in ["charm.clean_pickup","charm.house_special","charm.front_line"]:
		_check(art_captures.has(id),"H2-B native cue captured: " + id)
		var heard_b: int = lab.motion.sound.played
		lab.motion.abilities.cue(id,"skip_fixture",true)
		_check(lab.motion.sound.played == heard_b,"H2-B skip silent")
		lab.motion.sound.muted = true
		lab.motion.abilities.cue(id,"mute_fixture",false)
		_check(lab.motion.sound.played == heard_b,"H2-B mute silent")
		lab.motion.sound.muted = false
	for positions in [[],[1],[1,3],[1,2,3]]:
		var fixture := {"charms":[{"item_id":"charm.front_line"}],"rolls":[{"fallen_positions":positions}]}
		var cues: Array = projection.project(fixture,{"source":"charm:1","phase":"charm","op":"add_mult","amount":2,"count":positions.size()})
		_check(cues[0].positions == positions,"front shield projection 0/1/2/3")
	var bank_before: int = lab.total_score
	for id in ["charm.trophy_case","charm.corner_pockets","charm.late_rally"]:
		var heard: int = lab.motion.sound.played
		lab.motion.abilities.cue(id,"skip_fixture",true)
		_check(lab.motion.sound.played == heard,"H2-A skipped cue silent")
		lab.motion.sound.muted = true
		lab.motion.abilities.cue(id,"mute_fixture",false)
		_check(lab.motion.sound.played == heard,"H2-A muted cue silent")
		lab.motion.sound.muted = false
	_check(lab.total_score == bank_before,"H2-A presentation does not rebank")
	for id in ["charm.trophy_case","charm.corner_pockets","charm.late_rally"]:
		_check(lab.motion.abilities.history.any(func(e): return e.id == id),"H2-A native resolver activation: " + id)
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

# AV-H2-A native resource evidence. Stateful displays remain a separate checkpoint.
func _scored() -> Dictionary:
	for tick in ROLL_FRAMES * 3:
		if lab.state in ["scoring","frame_done"]:
			var glyph: Control = lab.motion.abilities.glyph
			if glyph.style != null and glyph.age < glyph.style.duration:
				var id: String = glyph.style.item_id
				if id in ["charm.trophy_case","charm.corner_pockets","charm.late_rally"]:
					var key := id + "_" + str(glyph.details.get("phase",""))
					if not art_captures.has(key):
						art_captures[key] = true
						_check(glyph.still,"H2-A cue follows reduced motion")
						if id == "charm.corner_pockets":
							var frame: Dictionary = lab.scored_frames[-1].frame
							var expected := [7,10].filter(func(p): return frame.rolls.any(func(r): return p in r.fallen_positions))
							_check(lab.motion.abilities.counted_rack_positions() == expected,"actual counted corner pockets")
						if id == "charm.trophy_case" and glyph.details.phase == "after_bank":
							_check(lab.motion.house_counts.landed,"trophy cue only after growth row")
						await _capture(key.replace(".","_") + "_cue")
		await _capture_h2b()
		if lab.state == "frame_done": return lab.scored_frames[-1]
		await process_frame
	_check(false,"H2-A native explanation timeout")
	return lab.scored_frames[-1]

func _capture_h2b() -> void:
	if lab.state not in ["scoring","frame_done"]: return
	var glyph: Control = lab.motion.abilities.glyph
	if glyph.style == null or glyph.age >= glyph.style.duration: return
	var id: String = glyph.style.item_id
	if id not in ["charm.clean_pickup","charm.house_special","charm.front_line"] or art_captures.has(id): return
	art_captures[id] = true
	var scored: Dictionary = lab.scored_frames[-1]
	_check(glyph.still,"H2-B reduced cue is static")
	if id == "charm.clean_pickup":
		_check(scored.result.category == "spare" and not glyph.details.curved and glyph.details.roll_count == 2,"dustpan marks two straight rolls")
	if id == "charm.house_special":
		_check(scored.result.category == "strike" and glyph.details.all_house and scored.frame.rolls.all(func(r): return r.ball_id == "ball.house"),"chalkboard identifies all-House strike")
	if id == "charm.front_line":
		var expected := [1,2,3].filter(func(p): return scored.frame.rolls.any(func(r): return p in r.fallen_positions))
		_check(lab.motion.abilities.counted_rack_positions() == expected and int(glyph.details.count) == expected.size(),"shields match counted front positions")
	await _capture(id.replace(".","_")+"_cue")
