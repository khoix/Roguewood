extends "res://tests/charm_c01_journey.gd"
## J22L01 (E22-L01): the full eight-Division House League, the game's default content,
## played end to end in the real game with real input (assist strikes).
## Fixture setup (logged, as J05 and J03C01 do): after the first opener a champion
## build is seated through the inventory API (Trophy Case, then Opening Act, Finisher,
## Turkey Club and House Special; a rack of Ruby Pins) so assist strikes can reach the
## provisional targets (60000 for the champion); everything else is real play.
##   menu:      the House League, its Clubhouse board, and the Tournament Kit listed
##              but locked until the title;
##   Divisions: every Division's environment from the theme manifest, the HUD "Dn/8",
##              its rival's introduction (Surveyor, Proprietor and Old Lou recur), each
##              boss on its lane with that lane's surface, the Championship stage for
##              the final boss, and the music loop; every bank equals an independent
##              resolution under the rules in force (House Pins scores the rack as Wood);
##   save:      the attempt is left and resumed in Division 5's opener shop;
##   title:     the League victory banks the title, the first clears of The Proprietor
##              and Old Lou (House Special and Wood Grain join the pool) and the
##              Tournament Kit, which the menu then offers; a new attempt with it starts
##              with four ball cards and $10.
## Run with --fixed-fps 60.
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
## Additions before multipliers (Charms resolve left to right): Trophy Case first.
const BUILD := ["charm.trophy_case", "charm.opening_act", "charm.finisher", "charm.turkey_club", "charm.house_special"]

var manifest: Dictionary = {}

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leagues/house/manifest.json"))
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	_check(scene.content.id == "house" and scene.content.divisions.size() == 8 and scene.league.get_item_text(0) == "House League", "the menu offers the eight-Division House League")
	_check(scene.kit.item_count == 2 and scene.kit.get_item_text(0) == "House Kit" and scene.kit.is_item_disabled(1) and scene.kit.get_item_text(1).contains("win the House League title"),
		"the Tournament Kit is listed but locked until the title")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "throw lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	_check(lab.league_theme != null and lab.league_theme.music != null and lab.league_theme.music.playing, "the League's music loop is playing")
	for division in range(1, 9):
		await _division(division)
	await _title()
	await _tournament()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	# The audio thread releases a playing loop's playback only after a few frames.
	if lab.league_theme != null and lab.league_theme.music != null:
		lab.league_theme.music.stop()
	for i in 5: await process_frame
	if failures.is_empty(): print("ROGUEWOOD_J22L01_OK")
	quit(0 if failures.is_empty() else 1)

func _stage_id(division: int, championship: bool) -> String:
	for s in manifest.stages:
		if int(s.division) == division and bool(s.championship) == championship:
			return s.environment_id
	return ""

func _environment() -> String:
	var node: Node = lab._viewport.get_node_or_null("LeagueEnvironment")
	return node.get_meta("environment_id") if node != null else ""

func _lane_visual() -> String:
	var body: Node = lab.lane.get_node_or_null("Lane")
	if body == null: return ""
	for child in body.get_children():
		if child.has_meta("lane_visual"): return child.get_meta("lane_visual")
	return ""

func _division(division: int) -> void:
	var spec: Dictionary = lab.content.divisions[division - 1]
	for index in 3:
		var m: Dictionary = spec.matches[index]
		await _wait_for(func(): return lab.state in ["aim", "intro"], "Division %d %s" % [division, m.kind], ROLL_FRAMES)
		if lab.state == "intro":
			var rival: Dictionary = lab.division.rival()
			_check(lab.hud.intro_title.text.contains(rival.name), "Division %d: %s's introduction" % [division, rival.name])
			await _focus_accept(lab.hud.intro_button)
			await _aim()
		var boss: bool = m.kind == "boss"
		var expected := _stage_id(division, boss and division == 8)
		_check(lab.division.division_number() == division and lab.hud.info.text.contains("D%d/8" % division) and _environment() == expected,
			"Division %d %s: HUD and environment %s (%s)" % [division, m.kind, expected, _environment()])
		if boss:
			var lane: String = m.lane_condition
			_check(lab.lane.lane_condition == lane and _lane_visual() == "lane_visual." + lane and lab.division.rival().id == m.rival,
				"Division %d boss: %s on %s with its surface (%s)" % [division, m.rival, lane, _lane_visual()])
		await _play_match(division, m)
		if division == 1 and index == 0:
			await _seat_build()
		if division == 8 and boss:
			return
		await _to_shop("Division %d %s" % [division, m.kind])
		if division == 5 and index == 0:
			await _save_and_resume()
		await _leave_shop()

## Throws until the match is won, checking every bank against the rules in force.
func _play_match(division: int, m: Dictionary) -> void:
	for frame in 2:
		var rules: Array = lab.active_rules()
		var context: Dictionary = lab.frame_context()
		var loadout: Dictionary = RivalRules.frame_loadout(rules, lab.run.loadout())
		var before: int = lab.history.size()
		await _throw(STRIKE)
		if await _second_roll():
			await _throw(STRIKE)
		var scored := await _scored()
		var built := Builder.build(loadout, lab.content.catalogue, lab.history.slice(before), {}, context)
		var banked: int = RivalRules.bank(rules, Rules.resolve(built.frame)).score if built.ok else -1
		print("J22L01 D%d %s frame %d: %s banked=%d expected=%d score=%d/%d rules=%s" % [division, m.kind, frame + 1, scored.result.category, scored.banked, banked,
			lab.division.match_score, lab.division.target(), str(rules)])
		_check(built.ok and scored.banked == banked, "D%d %s frame %d banks the independent resolution (%d vs %d)" % [division, m.kind, frame + 1, scored.banked, banked])
		if scored.match_over:
			_check(scored.match_won, "D%d %s is won (%d of %d)" % [division, m.kind, lab.division.match_score, lab.division.target()])
			return
		await _focus_accept(lab.next_rack)
	_check(false, "D%d %s did not finish in two frames" % [division, m.kind])

func _second_roll() -> bool:
	await _wait_for(func(): return lab.state == "scoring" or (lab.state == "aim" and lab.lane.state == "ready"), "roll 2 or scoring", ROLL_FRAMES)
	return lab.state == "aim"

func _seat_build() -> void:
	for id in BUILD:
		lab.run.place(id, 0, "charm:new")
	for position in range(1, 11):
		lab.run.rack[position] = Inventory._entry("pin.ruby", 0)
	print("J22L01 fixture: seated %s and a Ruby rack through the inventory API" % str(BUILD))

func _save_and_resume() -> void:
	var money: int = lab.run.money
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible and scene.continue_button.has_focus(), "Continue Attempt offered")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "shop", "the attempt resumes in Division 5's shop")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.division.division_number() == 5 and lab.run.money == money and lab.run.charms.size() == BUILD.size() and lab.league_theme != null,
		"the resumed attempt is in Division 5 with its build and theme")

func _title() -> void:
	_check(lab.division.outcome == "won" and lab.next_rack.text == "Division Result", "the House champion is beaten: the League is won")
	await _capture("j22_champion")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "victory screen")
	var career: Dictionary = scene.career
	_check(lab.hud.result_title.text.contains("House League cleared") and lab.hud.result_body.text.contains("D8 Boss"), "the victory lists the League's Divisions")
	_check(["rival.surveyor", "rival.custodian", "rival.proprietor", "rival.old_lou", "rival.custodian_champion"].all(func(r): return career.first_clears.has(r)),
		"all five House rivals are first clears")
	_check(["gate.proprietor_cleared", "gate.old_lou_cleared", "gate.house_champion"].all(func(g): return g in career.unlocked)
		and int(career.championships.get("league.house", {}).get("wins", 0)) == 1, "the rival rewards and the title are in the Career")
	await _capture("j22_title")

func _tournament() -> void:
	await _focus_accept(lab.hud.menu_button)
	await _wait_for(func(): return scene.screen == "menu", "back to the menu")
	_check(not scene.kit.is_item_disabled(1) and scene.kit.get_item_text(1) == "Tournament Kit", "the title opens the Tournament Kit")
	scene.kit.grab_focus()
	await _action("ui_accept")
	await _action("ui_down")
	await _action("ui_accept")
	_check(scene.kit.selected == 1, "the Tournament Kit is chosen")
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "attempt 2 with the Tournament Kit")
	lab = scene.lab
	_check(lab.run.cards.size() == 4 and lab.run.money == 10 and scene.session.kit_id == "kit.tournament", "it starts with four ball cards and $10")
	_check(["gate.proprietor_cleared", "gate.old_lou_cleared"].all(func(g): return g in lab.shop.unlocked), "House Special and Wood Grain join this attempt's pool")
	await _capture("j22_tournament")

func _capture(label: String) -> void:
	print("J22L01 %s lab=%s division=%d money=%d env=%s" % [label, lab.state, lab.division.division_number(), lab.run.money, _environment()])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
