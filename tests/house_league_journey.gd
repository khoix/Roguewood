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
var tag := "J22L01" # J22L02 (the Neon League) extends this journey

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
	await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)
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
		await _check_stage(division, m) # the Neon journey's waits a frame for the Charm rail
		await _play_match(division, m)
		if division == 1 and index == 0:
			await _seat_build()
		if division == 8 and boss:
			return
		await _to_shop("Division %d %s" % [division, m.kind])
		if division == 5 and index == 0:
			await _save_and_resume()
		await _leave_shop()

## The stage a match is played on: environment, HUD, and a boss's lane and surface.
func _check_stage(division: int, m: Dictionary) -> void:
	var boss: bool = m.kind == "boss"
	var expected := _stage_id(division, boss and division == 8)
	_check(lab.division.division_number() == division and lab.hud.info.text.contains("D%d/8" % division) and _environment() == expected,
		"Division %d %s: HUD and environment %s (%s)" % [division, m.kind, expected, _environment()])
	# The owner's soundtrack (2026-11-16): the House track, and the Championship's own.
	var music: AudioStreamPlayer = lab.league_theme.music if lab.league_theme != null else null
	var track := "championship.ogg" if boss and division == 8 else "house.ogg"
	_check(music != null and music.playing and music.stream.resource_path.ends_with(track), "Division %d %s: the music is %s (%s)" % [division, m.kind, track, music.stream.resource_path if music else "none"])
	if boss:
		var lane: String = m.lane_condition
		_check(lab.lane.lane_condition == lane and _lane_visual() == "lane_visual." + lane and lab.division.rival().id == m.rival,
			"Division %d boss: %s on %s with its surface (%s)" % [division, m.rival, lane, _lane_visual()])

func _resumed_ok() -> bool:
	return lab.league_theme != null

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
		print("%s D%d %s frame %d: %s banked=%d expected=%d score=%d/%d rules=%s" % [tag, division, m.kind, frame + 1, scored.result.category, scored.banked, banked,
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
	print("%s fixture: seated %s and a Ruby rack through the inventory API" % [tag, str(BUILD)])

func _save_and_resume() -> void:
	var money: int = lab.run.money
	await _focus_accept(scene.back)
	# UI-46 (owner, 2026-11-23): leaving mid-run from the menu has no slow fade; only
	# League's End and the awards fade to the Clubhouse.
	_check(not scene.transition_playing() and not scene.exiting and scene.screen == "menu", "UI-46: the menu's Clubhouse goes there at once, without the fade")
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible and scene.continue_button.has_focus(), "Continue Attempt offered")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "shop", "the attempt resumes in Division 5's shop")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.division.division_number() == 5 and lab.run.money == money and lab.run.charms.size() == BUILD.size() and _resumed_ok(),
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
	# UI-40 (owner, 2026-11-23): the sheet keeps the outcome, tiles and matches, and
	# shows the Career as a bar of rivals defeated; what was kept moves to the awards.
	var view: Control = lab.hud.result_view
	var headings: Array = view.find_children("ResultHeading", "", true, false).map(func(h): return h.text)
	var rivals: Dictionary = lab._rivals_defeated()
	var bar: Control = view.find_child("ResultRivals", true, false)
	var kept: Dictionary = lab._pending_awards.get("awards", {}).get("kept", {})
	var kept_items: Array = kept.get("items", []).map(func(i): return i.id)
	var opened: Array = kept.get("opened", []).map(func(o): return "%s:%s" % [o.kind, o.name])
	_check(view.find_children("ResultHighlight", "", true, false).is_empty() and "Goals" not in headings and "Kept" not in headings and "Rewards" not in headings
		and bar != null and int(rivals.progress) >= 5 and bar.get_child(2).text == "%d/%d" % [int(rivals.progress), int(rivals.threshold)]
		and not lab.hud.result_body.text.contains("Rule in force"),
		"UI-40: the sheet has no Kept or Goals, and a bar of rivals defeated (%s, headings %s)" % [str(rivals), str(headings)])
	# UI-44: what the run opened, as pieces for the award page: the items that join
	# the pool, and the League and kit the title opens.
	_check(["charm.house_special", "charm.wood_grain"].all(func(i): return i in kept_items) and "league:Royal League" in opened and "kit:Tournament Kit" in opened,
		"UI-44: the awards will show the unlocked items and the Royal League and Tournament Kit (%s, %s)" % [str(kept_items), str(opened)])
	await _capture("j22_title")

func _tournament() -> void:
	var kept: Dictionary = lab._pending_awards.get("awards", {}).get("kept", {})
	await _focus_accept(lab.hud.menu_button)
	# UI-40: the award page lists what the run kept, above the goals.
	var ceremony = lab.award_ceremony
	await _wait_for(func(): return ceremony.visible and ceremony.playing, "the award ceremony", 120)
	await _focus_accept(ceremony.skip_button)
	await _wait_for(func(): return ceremony.step == "done" and not ceremony.continue_button.disabled, "Skip shows the awards summary", 120)
	# UI-44 (owner, 2026-11-23: "thematically appropriate for this page--not just a
	# wall of text"): a gold banner, a framed tile with art for each unlocked item,
	# a badge for each League or kit opened, and the goals as velvet award cards.
	var tiles: Array = ceremony.goals_box.find_children("KeptItem_*", "", true, false)
	var badges: Array = ceremony.goals_box.find_children("KeptOpened_*", "", true, false)
	var header = ceremony.goals_box.find_child("KeptHeader", true, false)
	_check(header != null and header.get_child(0).text == "NEW IN THE SHOP" and tiles.size() == kept.items.size() and badges.size() == kept.opened.size()
		and tiles.all(func(t): return t.find_child("Art", true, false).texture != null) and ceremony.goals_box.find_children("KeptLine*", "", true, false).is_empty(),
		"UI-44: the award page shows %d item tiles with art and %d badges, not lines of text (header %s, kept %d/%d, missing art %s)" % [tiles.size(), badges.size(),
			str(header.get_child(0).text) if header != null else "none", kept.items.size(), kept.opened.size(),
			str(tiles.filter(func(t): return t.find_child("Art", true, false).texture == null).map(func(t): return t.name))])
	# UI-45 (owner, 2026-11-23: "a clear divide/border instead of a hidden scrollable
	# section ... one scrollable row for mobile"): a bordered panel, its pieces in one
	# row that scrolls sideways, under a gold rule below the shelf.
	var row: Control = ceremony.goals_box.find_child("KeptItems", true, false)
	var pieces: Array = row.get_children() if row != null else []
	var panel = ceremony.goals_box.get_node_or_null("KeptPanel")
	_check(panel != null and panel.get_theme_stylebox("panel").border_width_top > 0 and row is HBoxContainer and pieces.size() == tiles.size() + badges.size()
		and ceremony.kept_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and ceremony.kept_scroll.get_h_scroll_bar().max_value > ceremony.kept_scroll.size.x
		and ceremony.summary.get_node_or_null("SummaryRule") != null and panel.get_global_rect().size.y < 320.0,
		"UI-45: New in the Shop is a bordered panel with one sideways row (%d pieces, %.0f px wide in %.0f, panel %.0f px tall)" % [pieces.size(), ceremony.kept_scroll.get_h_scroll_bar().max_value, ceremony.kept_scroll.size.x, panel.get_global_rect().size.y if panel != null else 0.0])
	var goal_rows: Array = ceremony.goals_box.get_children().filter(func(n): return String(n.name).begins_with("Goal_"))
	_check(ceremony.awards.get("goals", []).is_empty() or ceremony.goals_box.get_node_or_null("GoalsHeader") is Control and ceremony.goals_box.get_node("GoalsHeader").get_child(0).text == "GOALS"
		and goal_rows.all(func(r): return r.get_theme_stylebox("panel").bg_color == ceremony.VELVET), "UI-44: the goals sit under their own banner, as velvet award cards (%d)" % goal_rows.size())
	await _capture("j22_awards_kept")
	ceremony.goals_scroll.scroll_vertical = int(ceremony.goals_scroll.get_v_scroll_bar().max_value)
	for i in 3: await process_frame
	await _capture("j22_awards_kept_end")
	await _focus_accept(ceremony.continue_button)
	await _wait_for(func(): return scene.screen == "menu", "back to the menu", 400)
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
	print("%s %s lab=%s division=%d money=%d env=%s" % [tag, label, lab.state, lab.division.division_number(), lab.run.money, _environment()])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
