extends "res://tests/house_league_journey.gd"
## J22L02 (E22-L02): the full eight-Division Neon League, chosen on the League Board
## and played end to end in the real game with real input (assist strikes).
## Fixture setup (logged, as J22L01 does): after the first opener the champion build
## is seated through the inventory API so assist strikes can reach the provisional
## targets; everything else is real play.
##   menu:      the production board lists House, Neon and the campaign; Neon is open
##              from the start; choosing it offers the Neon Kit (two Hook, two Glow
##              and two Spare Ball cards, $6);
##   Divisions: the HUD "Dn/8"; every match on the lane neon.json gives it (openers
##              on House Oil, features and bosses on Long Oil or Two-Tone); each
##              rival's introduction (Slick, Laser Lena and DJ Flicker recur) and its
##              rule in force (Oil Slick, Narrow Lane, Strobe; the champion plays
##              Strobe with Oil Slick); every bank equals an independent resolution;
##   save:      the attempt is left and resumed in Division 5's opener shop. The
##              board is on the House League when Continue is pressed, so the saved
##              attempt's own League is restored;
##   title:     the League victory banks the title and the first clears of all four
##              rivals; the board's Neon trophy is earned; a new Neon attempt has the
##              five gated rewards in its pool.
##   theme:     Codex's Neon theme (E22-L02-ART) is live: each Division's room and
##              the Championship stage, the Long Oil and Two-Tone finishes, the
##              music loop, the flank backdrop and the Neon frame kit; the House
##              kit returns at the Clubhouse.
## Run with --fixed-fps 60.
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const ClubModel = preload("res://src/clubhouse/clubhouse_model.gd")
const GATES := ["gate.slick_cleared", "gate.laser_lena_cleared", "gate.dj_flicker_cleared", "gate.neon_champion_cleared", "gate.neon_champion"]
const REWARDS := ["ball.oilskin", "ball.laser", "pin.tempo", "charm.neon_sign", "ball_mod.blacklight"]
const RULES := {"rival.slick": ["boss_rule.oil_slick"], "rival.laser_lena": ["boss_rule.narrow_lane"], "rival.dj_flicker": ["boss_rule.strobe"],
	"rival.dj_flicker_champion": ["boss_rule.strobe", "boss_rule.oil_slick"]}

func _run() -> void:
	tag = "J22L02"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leagues/neon/manifest.json"))
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	_check(scene.content.id == "house" and scene.league.item_count == 3 and scene.league.get_item_text(1) == "Neon League" and not scene.league.is_item_disabled(1),
		"the board lists the Neon League after the House League, open from the start")
	await _choose_neon()
	_check(scene.content.id == "neon" and scene.content.divisions.size() == 8 and scene.kit.item_count == 1 and scene.kit.get_item_text(0) == "Neon Kit"
		and not scene.kit.is_item_disabled(0) and scene.enter.text == "Enter League", "choosing it offers the eight-Division League and the Neon Kit")
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "throw lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	var deck: Array = lab.run.cards.values().map(func(c): return c.item_id)
	deck.sort()
	_check(scene.session.league_id == "league.neon" and scene.session.kit_id == "kit.neon" and lab.run.money == 6
		and deck == ["ball.glow", "ball.glow", "ball.hook", "ball.hook", "ball.spare_ball", "ball.spare_ball"], "the attempt starts with the Neon Kit: %s and $%d" % [str(deck), lab.run.money])
	_check(REWARDS.all(func(id): return not _in_pool(id)), "the five rival rewards are not in a first attempt's pool")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	# The Neon theme (E22-L02-ART) is live: music, the flank backdrop behind the lane
	# (still, since reduced motion is on) and the Neon frame kit on the attempt's screens.
	_check(lab.league_theme != null and lab.league_theme.music != null and lab.league_theme.music.playing
		and lab.league_theme.music.stream.resource_path == manifest.assets[manifest.music.asset_id], "the Neon League's music loop is playing")
	_check(lab.backdrop.get_meta("backdrop_id", "") == manifest.flank.normal and lab.backdrop.reduced and lab.backdrop.get_index() == 0
		and lab.backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the Neon flank backdrop is behind the lane, still under reduced motion")
	_check(UiTheme.kit_id() == "neon" and _frame(lab.hud.bar) == "res://assets/ui/neon/hud.svg" and _frame(lab.score_panel) == "res://assets/ui/neon/menu.svg"
		and _frame(lab.panels.slip) == "res://assets/ui/neon/slip.svg" and _frame(lab.card_hand) == "res://assets/ui/neon/panel.svg"
		and lab.next_rack.get_theme_stylebox("normal").texture.resource_path == "res://assets/ui/neon/shop.svg",
		"the attempt's bar, review, slip, hand and buttons wear the Neon frames (%s, %s)" % [_frame(lab.hud.bar), _frame(lab.card_hand)])
	for division in range(1, 9):
		await _division(division)
	await _title()
	await _next_attempt()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if lab.league_theme != null and lab.league_theme.music != null:
		lab.league_theme.music.stop() # the audio thread lets go of a playing loop after a few frames
	for i in 5: await process_frame
	if failures.is_empty(): print("ROGUEWOOD_J22L02_OK")
	quit(0 if failures.is_empty() else 1)

func _choose_neon() -> void:
	scene.league.grab_focus()
	await _action("ui_accept")
	await _action("ui_down")
	await _action("ui_accept")
	await _wait_for(func(): return scene.league.selected == 1 and scene.content.id == "neon", "the Neon League chosen")

func _in_pool(id: String) -> bool:
	for item in lab.content.catalogue.items:
		if item.id == id:
			return item.unlock.kind == "initial" or item.unlock.prerequisites.all(func(p): return p in lab.shop.unlocked)
	return false

func _frame(control: Control) -> String:
	var style := control.get_theme_stylebox("panel") as StyleBoxTexture
	return style.texture.resource_path if style != null and style.texture != null else ""

func _check_stage(division: int, m: Dictionary) -> void:
	var lane: String = m.get("lane_condition", "lane.house") # no listed lane: the standard House Oil lane
	_check(lab.division.division_number() == division and lab.hud.info.text.contains("D%d/8" % division) and lab.lane.lane_condition == lane,
		"Division %d %s: HUD and lane %s (%s)" % [division, m.kind, lane, lab.lane.lane_condition])
	# The theme: each Division's room, the Championship stage for the final boss,
	# and the listed lane's finish.
	var expected := _stage_id(division, m.kind == "boss" and division == 8)
	_check(not expected.is_empty() and _environment() == expected, "Division %d %s: environment %s (%s)" % [division, m.kind, expected, _environment()])
	if m.has("lane_condition"):
		_check(_lane_visual() == "lane_visual." + lane, "Division %d %s: the %s finish (%s)" % [division, m.kind, lane, _lane_visual()])
	if m.kind == "opener":
		_check(lane == "lane.house", "Division %d's opener keeps House Oil" % division)
	if m.kind == "boss":
		var rules: Array = lab.active_rules()
		_check(lab.division.rival().id == m.rival and RULES[m.rival].all(func(r): return r in rules),
			"Division %d boss: %s under %s (%s)" % [division, m.rival, str(RULES[m.rival]), str(rules)])

func _resumed_ok() -> bool:
	return scene.content.id == "neon" and scene.league.selected == 1 and scene.session.league_id == "league.neon" and lab.league_theme != null and UiTheme.kit_id() == "neon"

## The board is put back on the House League before Continue, so the saved attempt
## must bring its own League with it.
func _save_and_resume() -> void:
	var money: int = lab.run.money
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible, "Continue Attempt offered")
	scene.league.grab_focus()
	await _action("ui_accept")
	await _action("ui_up")
	await _action("ui_accept")
	await _wait_for(func(): return scene.content.id == "house" and scene.continue_button.visible, "the board on the House League, Continue still offered")
	_check(UiTheme.kit_id() == "house" and scene.clubhouse.visible, "back at the Clubhouse the House frames return")
	await _focus_accept(scene.continue_button)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "shop", "the attempt resumes in Division 5's shop")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.division.division_number() == 5 and lab.run.money == money and lab.run.charms.size() == BUILD.size() and _resumed_ok(),
		"the resumed attempt is the Neon League's, in Division 5 with its build")

func _title() -> void:
	_check(lab.division.outcome == "won" and lab.next_rack.text == "Division Result", "the Neon champion is beaten: the League is won")
	await _capture("j22n_champion")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "victory screen")
	var career: Dictionary = scene.career
	_check(lab.hud.result_title.text.contains("Neon League cleared") and lab.hud.result_body.text.contains("D8 Boss"), "the victory lists the League's Divisions")
	_check(RULES.keys().all(func(r): return career.first_clears.has(r)), "Slick, Laser Lena, DJ Flicker and the champion are first clears")
	_check(GATES.all(func(g): return g in career.unlocked) and int(career.championships.get("league.neon", {}).get("wins", 0)) == 1
		and not career.championships.has("league.house"), "the four rival gates and the Neon title are in the Career; the House title is not")
	await _capture("j22n_title")

func _next_attempt() -> void:
	await _focus_accept(lab.hud.menu_button)
	await _wait_for(func(): return scene.screen == "menu", "back to the menu")
	_check(scene.content.id == "neon" and scene.enter.text == "Try Again", "the board stays on the Neon League")
	var trophy: Array = ClubModel.trophies(scene.career, scene.career_graph).filter(func(t): return t.id == "league.neon")
	_check(trophy.size() == 1 and trophy[0].earned, "the Neon League trophy is on the shelf")
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "attempt 2")
	lab = scene.lab
	_check(GATES.all(func(g): return g in lab.shop.unlocked) and REWARDS.all(func(id): return _in_pool(id)),
		"Oilskin Ball, Laser Ball, Tempo Pin, Neon Sign and Blacklight join this attempt's pool")
	await _capture("j22n_attempt2")
