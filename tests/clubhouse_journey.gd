extends "res://tests/career_journey.gd"
## J11 Clubhouse (E16) through the real game, with touch and keyboard. Two engine
## processes share one save directory (tools/qa.py):
##   1 a fresh Career: the Binder shows Locked and Available cards (inspecting
##     Encore names the rival that unlocks it); follow a goal, which the League
##     Board then shows; play attempt 1 of the slice to a House League title (the
##     J06 path); back in the Clubhouse, cards owned in the win are Mastered, the
##     unlocks are Available, and the title, plaques and decorations are earned;
##   2 restart: everything above survived; Try Again, win the opener, buy a Charm
##     never owned before, then lose; the Clubhouse still shows every reward, the
##     new Charm is Discovered and the record counts both attempts; then return to
##     play from the Binder through the League Board.
## Shots are the deterministic J03 assist throws. Run with --fixed-fps 60.

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
		if arg.begins_with("--stage="): stage = int(arg.trim_prefix("--stage="))
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.screen == "menu" and (scene.enter.has_focus() or scene.continue_button.has_focus()), "menu focus")
	_check(scene.clubhouse.visible and scene.clubhouse.current_tab == "board", "the Clubhouse opens on the League Board")
	# The phone layout: four tabs on one row inside the screen, and the Career as tiles.
	var tabs: Array = scene.clubhouse.tab_buttons.values()
	_check(tabs.all(func(b): return is_equal_approx(b.global_position.y, tabs[0].global_position.y) and b.get_global_rect().end.x <= scene.clubhouse.size.x and b.size.y >= 52),
		"the four tabs share one row on a phone")
	_check(scene.career_stats.get_child_count() == 4 and not scene.career_line.visible, "the League Board shows the Career as four tiles")
	_ui9_board()
	# The owner's soundtrack (2026-11-16): the Clubhouse has its own music.
	_check(scene.clubhouse_music != null and scene.clubhouse_music.playing and scene.clubhouse_music.stream.resource_path.ends_with("clubhouse.ogg"), "the Clubhouse music plays")
	if stage == 1:
		await _ui12_menu()
		await _perf1_graphics()
		await _ui24_how_to_play()
		await _ui39_practice()
	match stage:
		1: await _stage_one_clubhouse()
		2: await _stage_two_clubhouse()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty() and lab != null: await _capture("clubhouse_failure")
	if failures.is_empty(): print("ROGUEWOOD_J11_OK" if stage == 2 else "ROGUEWOOD_J11_STAGE%d_OK" % stage)
	quit(0 if failures.is_empty() else 1)

## UI-9 (owner's play notes, 2026-11-15): the logo heads the Clubhouse; the pages
## scroll without a bar; the Career is one scoreboard; the choices sit under
## captions on a play card and the action is the brass button; each League is a card.
func _ui9_board() -> void:
	var club = scene.clubhouse
	var logo: Control = club.find_child("ClubhouseLogo", true, false)
	_check(logo != null and logo.visible and logo.get_global_rect().end.y <= club.tab_buttons.board.get_global_rect().position.y and club.find_child("ClubhouseWordmark", true, false) == null,
		"the game's logo heads the Clubhouse, above the tabs")
	_check(club.pages.values().all(func(p): return p.get_parent().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER), "no page shows a scroll bar")
	var play: Control = scene.find_child("PlayCard", true, false)
	_check(play != null and play.is_ancestor_of(scene.league) and play.is_ancestor_of(scene.kit) and play.is_ancestor_of(scene.enter)
		and scene.league.get_node_or_null("BrassEdge") != null, "the League and kit choices and the action sit on the play card")
	var action: Button = scene.continue_button if scene.continue_button.visible else scene.enter
	var brass: StyleBox = action.get_theme_stylebox("normal")
	_check(brass is StyleBoxFlat and (brass as StyleBoxFlat).bg_color.is_equal_approx(Color("d8b873")), "the action to take is the brass button")
	var footer: Control = club.pages.board.get_node_or_null("BoardFooter")
	_check(footer != null and footer.get_index() == club.pages.board.get_child_count() - 1 and footer.find_child("FooterCredit", true, false).text == "Roguewood 2026 | khoix"
		and footer.find_child("FooterRule", true, false) != null, "UI-10: the board ends with a short rule and the footer line")
	_check(club.league_cards.get_child_count() == club.records_label.text.split("\n").size() and club.records_label.visible == false,
		"each League's record is a card (%d)" % club.league_cards.get_child_count())
	var offers_campaign: bool = "campaign" in scene.league_sets
	_check(club.league_sets == scene.league_sets and club.league_cards.get_child_count() == scene.league_sets.size()
		and club.records_label.text.contains("House Campaign") == offers_campaign,
		"UI-37: the League records hold only the Leagues the board offers (%s)" % ", ".join(scene.league_sets))

## UI-12 (owner's play notes, 2026-11-16): the Clubhouse has a menu at its top right,
## with Options and Sound & effects on the same session settings as a match; the
## Clubhouse music eases to half under them; every button tap makes a sound.
func _ui12_menu() -> void:
	var button: Button = scene.club_menu_button
	_check(button.visible and button.get_global_rect().end.x <= scene.size.x and button.get_global_rect().position.y < scene.clubhouse.tab_buttons.board.get_global_rect().position.y,
		"the Clubhouse menu button sits at the top right, above the tabs")
	var taps: int = scene.ui_sounds.played
	await _tap(button)
	_check(scene.club_menu.visible and scene.ui_sounds.played > taps and scene.ui_sounds.last_kind == "tap", "a tap opens the Clubhouse menu, with a tap sound")
	# UI-15 (owner, 2026-11-18): the same menu as a match's, with Throw Settings and
	# Sound & Effects as sibling pages whose Back returns here.
	var entries: Array = scene.club_menu_list.get_children().filter(func(c): return c is Button).map(func(c): return c.text)
	_check(entries == ["How to Play", "Throw Settings", "Sound & Effects", "Graphics", "Close"], "UI-15: the Clubhouse menu's entries (%s)" % str(entries))
	await _tap(scene.club_menu_list.get_node("ClubOptions"))
	var options = scene.club_options
	await process_frame
	_check(not scene.club_menu.visible and options.is_open() and options.settings_panel.visible and not options.sound.panel.visible
		and options.settings_panel.get_global_rect().intersects(scene.get_global_rect()), "Throw Settings opens from the Clubhouse menu, on its own")
	_check(options.settings_panel.find_child("SoundAndEffects", true, false) == null and options.settings_panel.close.text == "Back", "Throw Settings has no Sound & Effects row, and a Back")
	var music: AudioStreamPlayer = scene.clubhouse_music
	await _wait_for(func(): return is_equal_approx(scene.music_duck, 0.5), "the Clubhouse music eases down under Throw Settings")
	_check(absf(music.volume_db - (scene.Soundtrack.level_db(scene.throw_settings) + linear_to_db(0.5))) < 0.01, "Throw Settings halves the Clubhouse music (%.1f dB)" % music.volume_db)
	options.settings_panel.sensitivity.value = 0.6
	_check(is_equal_approx(float(scene.throw_settings.sensitivity), 0.6), "a setting changed in the Clubhouse is the session's")
	await _tap(options.settings_panel.close)
	_check(not options.is_open() and scene.club_menu.visible and scene.club_menu_list.get_node("ClubOptions").has_focus() and scene.ui_sounds.last_kind == "back",
		"Back from Throw Settings returns to the Clubhouse menu, with the back sound")
	await _tap(scene.club_menu_list.get_node("ClubSound"))
	_check(not scene.club_menu.visible and options.sound.panel.visible and not options.settings_panel.visible, "Sound & Effects opens from the Clubhouse menu, on its own")
	await _wait_for(func(): return is_equal_approx(scene.music_duck, 0.5), "the Clubhouse music eases down under Sound & Effects")
	options.sound.music_slider.value = 0.5
	await process_frame
	_check(is_equal_approx(float(scene.throw_settings.music_volume), 0.5) and absf(music.volume_db - (scene.Soundtrack.level_db(scene.throw_settings) + linear_to_db(0.5))) < 0.01
		and scene.Soundtrack.level_db(scene.throw_settings) < scene.Soundtrack.MUSIC_DB - 5.0, "the music slider lowers the Clubhouse music")
	options.sound.music_slider.value = 1.0
	await _action("ui_cancel")
	_check(not options.is_open() and scene.club_menu.visible and scene.club_menu_list.get_node("ClubSound").has_focus(), "Escape on Sound & Effects goes back to the Clubhouse menu")
	await _tap(scene.club_menu_list.get_node("CloseClubMenu"))
	_check(not scene.club_menu.visible and button.has_focus(), "Close closes the Clubhouse menu, back on the menu button")
	await _wait_for(func(): return is_equal_approx(scene.music_duck, 1.0), "the Clubhouse music eases back")
	scene.throw_settings.sensitivity = 0.4
	# Escape closes the menu itself.
	await _focus_accept(button)
	await _action("ui_cancel")
	_check(not scene.club_menu.visible and button.has_focus(), "Escape closes the Clubhouse menu")
	scene.throw_settings.sound_muted = true
	taps = scene.ui_sounds.played
	await _tap(scene.clubhouse.tab_buttons.binder)
	_check(scene.ui_sounds.played == taps, "Mute silences the taps")
	scene.throw_settings.sound_muted = false
	await _tap(scene.clubhouse.tab_buttons.board)
	_check(scene.ui_sounds.played == taps + 1 and scene.ui_sounds.last_kind == "select", "a tab tap makes the select sound")

## PERF-1 (owner, 2026-11-21): Graphics, from the Clubhouse menu: Resolution and
## Texture Detail (Low, Normal, High; Normal by default) and the Performance log, all
## saved on the device. Low texture detail draws large art from a smaller copy (only
## a rendered run draws, so the art is checked there); Normal puts the art back.
func _perf1_graphics() -> void:
	var gfx: Node = root.get_node("Graphics")
	_check(gfx.level("resolution") == "normal" and gfx.level("textures") == "normal" and not gfx.settings.perf_log and gfx.swapped == 0,
		"PERF-1: Graphics starts at Normal, Normal, log off, and changes nothing")
	await _tap(scene.club_menu_button)
	await _tap(scene.club_menu_list.get_node("ClubGraphics"))
	await process_frame
	_check(gfx.is_open() and not scene.club_menu.visible and gfx.resolution_choice.has_focus() and gfx.resolution_choice.selected == 1 and gfx.texture_choice.selected == 1,
		"PERF-1: Graphics opens from the Clubhouse menu at Normal and Normal")
	var notes: Array = [gfx.resolution_choice.get_meta("note").text, gfx.texture_choice.get_meta("note").text]
	_check(notes[0].begins_with("Normal") and notes[1].begins_with("Normal"), "PERF-1: each choice explains itself (%s)" % str(notes))
	var logo: TextureRect = scene.clubhouse.find_child("ClubLogo", true, false) if scene.clubhouse.find_child("ClubLogo", true, false) is TextureRect else null
	var big: Array = root.find_children("*", "TextureRect", true, false).filter(func(t): return t.texture != null and maxi(t.texture.get_width(), t.texture.get_height()) > gfx.TEXTURE_CAP)
	var art: TextureRect = big[0] if not big.is_empty() else logo
	var source_path: String = art.texture.resource_path if art != null else ""
	gfx.texture_choice.select(0)
	gfx.texture_choice.item_selected.emit(0)
	gfx.resolution_choice.select(0)
	gfx.resolution_choice.item_selected.emit(0)
	for i in 90: await process_frame
	var saved = JSON.parse_string(FileAccess.get_file_as_string(gfx.save_dir.path_join("graphics.json")))
	_check(saved is Dictionary and saved.resolution == "low" and saved.textures == "low" and gfx.texture_choice.get_meta("note").text.begins_with("Low"),
		"PERF-1: Low and Low are saved on the device (%s)" % str(saved))
	if DisplayServer.get_name() != "headless" and art != null:
		_check(maxi(art.texture.get_width(), art.texture.get_height()) == gfx.TEXTURE_CAP and art.texture.resource_path.is_empty() and gfx.swapped > 0,
			"PERF-1: Low draws large art from a %d px copy (%s, %d swapped)" % [gfx.TEXTURE_CAP, source_path, gfx.swapped])
		await _capture("graphics_low")
		# PERF-1b (owner: Low or High textures dropped a phone under 20 fps): once the art
		# is swapped, following it costs next to nothing a frame.
		var spent := 0
		for i in 120:
			await process_frame
			spent += gfx.sweep_usec
		_check(spent / 120.0 < 300.0 and gfx.sweep_worst_usec < 60000, "PERF-1b: the texture sweep costs %.3f ms a frame (worst %.1f ms)" % [spent / 120000.0, gfx.sweep_worst_usec / 1000.0])
	gfx.texture_choice.select(1)
	gfx.texture_choice.item_selected.emit(1)
	gfx.resolution_choice.select(1)
	gfx.resolution_choice.item_selected.emit(1)
	for i in 90: await process_frame
	if DisplayServer.get_name() != "headless" and art != null:
		_check(art.texture.resource_path == source_path, "PERF-1: Normal puts the art back (%s)" % art.texture.resource_path)
	_check(root.msaa_3d == Viewport.MSAA_DISABLED, "PERF-1: Normal resolution draws the lane as before")
	# The Performance log: a long frame is recorded with where the game was.
	await _tap(gfx.log_toggle)
	_check(gfx.settings.perf_log and gfx.readout.visible, "PERF-1: the Performance log turns on, with its corner readout")
	await process_frame
	OS.delay_msec(int(gfx.LONG_FRAME_MS) + 60)
	await process_frame
	await process_frame
	var last: Dictionary = gfx.log_entries.back() if not gfx.log_entries.is_empty() else {}
	_check(int(last.get("ms", 0)) >= int(gfx.LONG_FRAME_MS) and String(last.get("where", "")).begins_with("menu") and gfx.log_label.text.contains("ms")
		and gfx.log_text().contains("resolution normal · textures normal"), "PERF-1: a long frame is logged with where the game was (%s)" % str(last))
	await _tap(gfx.copy_button)
	_check(gfx.copy_button.text == "Copied", "PERF-1: Copy Log copies the log")
	await _tap(gfx.find_child("GraphicsClearLog", true, false))
	await _tap(gfx.log_toggle)
	_check(not gfx.settings.perf_log and not gfx.readout.visible and gfx.log_entries.is_empty(), "PERF-1: Clear empties the log; it turns off")
	await _action("ui_cancel")
	_check(not gfx.is_open() and scene.club_menu.visible and scene.club_menu_list.get_node("ClubGraphics").has_focus(), "PERF-1: Escape on Graphics goes back to the Clubhouse menu")
	await _tap(scene.club_menu_list.get_node("CloseClubMenu"))

## UI-39 (owner, 2026-11-21): How to Play's Practice: the House Ball and ten Wood
## pins, no shop, rules, cards or Charms; games of ten frames scored as normal, one
## after another. Nothing counts: the Career and the League choice are as before.
func _ui39_practice() -> void:
	var attempts: int = int(scene.career.get("attempts", 0))
	var chosen: String = scene.content.id
	var assist_was: bool = bool(scene.throw_settings.get("assist", false))
	scene.throw_settings.assist = true # the deterministic assist throws (J03)
	await _tap(scene.club_menu_button)
	await _tap(scene.club_menu_list.get_node("ClubHowToPlay"))
	await _tap(scene.club_how_list.get_node("ClubPractice"))
	await _wait_for(func(): return scene.screen == "session" and scene.lab != null and scene.content.id == "practice" and scene.lab.state == "aim", "Practice opens its lane", ROLL_FRAMES)
	lab = scene.lab
	_check(lab.practice_lane() and lab.division.practice and lab.save_store == null and lab.active_rules().is_empty(), "UI-39: Practice is a practice lane: no rules, nothing saved")
	_check(lab.equipment.options().is_empty() and lab.armed_ball_id() == "ball.house" and lab.run.charms.is_empty() and lab.run.loadout().pins.values().all(func(id): return id == "pin.wood"),
		"UI-39: the House Ball only, ten Wood pins, no cards or Charms")
	_check(not lab.hud.money.get_parent().visible and not lab.panels.rival.visible and not lab.panels.charms.visible and not lab.card_hand.visible,
		"UI-39: no money, rival, Charms or card hand on screen")
	_check(lab.hud.info.text.begins_with("Practice · Game 1"), "UI-39: the bar says Practice · Game 1 (%s)" % lab.hud.info.text)
	await _capture("practice_lane")
	# A whole game of ten frames, scored as normal.
	var banked := 0
	for frame in 10:
		await _throw(STRIKE)
		await _wait_for(func(): return lab.state in ["aim", "scoring"], "the second roll or the tally", ROLL_FRAMES)
		if lab.state == "aim": await _throw(LEAVE) # pins left standing: the second roll
		var scored: Dictionary = await _scored()
		banked += int(scored.banked)
		if frame < 9:
			_check(not scored.match_over and lab.next_rack.text == "Next Rack", "UI-39: frame %d is followed by the next rack" % (frame + 1))
			await _focus_accept(lab.next_rack)
	var first_game: int = lab.division.match_score
	_check(lab.division.match_over() and first_game == banked and first_game > 0 and lab.next_rack.text == "Next Game", "UI-39: ten frames make a game (%d), then Next Game" % first_game)
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "aim", "the next game", ROLL_FRAMES)
	_check(lab.match_number == 2 and lab.match_frame == 1 and lab.division.match_score == 0 and not lab.shop_panel.visible and lab.practice_best() == first_game
		and lab.hud.info.text.begins_with("Practice · Game 2") and lab.hud.info.text.contains("Best %d" % first_game), "UI-39: no shop; game 2 begins, with game 1 as the best (%s)" % lab.hud.info.text)
	await _focus_accept(scene.menu_button)
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "back to the Clubhouse", ROLL_FRAMES)
	_check(scene.content.id == chosen and int(scene.career.get("attempts", 0)) == attempts, "UI-39: leaving practice keeps the League choice and the Career (%s, %d attempts)" % [scene.content.id, int(scene.career.get("attempts", 0))])
	scene.throw_settings.assist = assist_was
	lab = null

## UI-24 (owner, 2026-11-19): How to Play offers Play Tutorial (JTUT plays it) or
## Talk the Talk, the words the game uses, each with its picture, tab by tab; its
## pictures of a throw follow the player's hand; Back and Escape step back a page.
func _ui24_how_to_play() -> void:
	var Glossary = load("res://src/clubhouse/glossary.gd")
	_check(Glossary.validate(Glossary.data()).is_empty(), "the glossary is valid: %s" % str(Glossary.validate(Glossary.data())))
	await _tap(scene.club_menu_button)
	var entries: Array = scene.club_menu_list.get_children().filter(func(c): return c is Button).map(func(c): return c.text)
	_check(entries == ["How to Play", "Throw Settings", "Sound & Effects", "Graphics", "Close"] and scene.club_menu_list.get_node("ClubHowToPlay").has_focus(),
		"the Clubhouse menu still leads with How to Play")
	await _tap(scene.club_menu_list.get_node("ClubHowToPlay"))
	var how: VBoxContainer = scene.club_how_list
	var choices: Array = how.get_children().filter(func(c): return c is Button).map(func(c): return c.text)
	_check(scene.club_menu.visible and how.visible and not scene.club_menu_list.visible and choices == ["Play Tutorial", "Practice", "Talk the Talk", "Back"]
		and how.get_node("ClubPlayTutorial").has_focus(), "How to Play offers Play Tutorial and Talk the Talk (%s)" % str(choices))
	await _capture("how_to_play")
	await _action("ui_cancel")
	_check(scene.club_menu.visible and scene.club_menu_list.visible and not how.visible and scene.club_menu_list.get_node("ClubHowToPlay").has_focus(),
		"Escape on How to Play returns to the menu's entries")
	await _tap(scene.club_menu_list.get_node("ClubHowToPlay"))
	await _tap(how.get_node("HowToPlayBack"))
	_check(scene.club_menu.visible and scene.club_menu_list.visible and not how.visible and scene.ui_sounds.last_kind == "back", "Back on How to Play returns to the menu, with the back sound")
	await _tap(scene.club_menu_list.get_node("ClubHowToPlay"))
	await _tap(how.get_node("ClubTalkTheTalk"))
	var page = scene.club_glossary
	await process_frame
	var screen_rect: Rect2 = scene.get_global_rect()
	_check(page.is_open() and not scene.club_menu.visible and page.section == "run" and page.tab_buttons.run.has_focus() and page.tab_buttons.run.button_pressed
		and screen_rect.encloses(page.panel.get_global_rect()), "Talk the Talk opens on The Run, inside the screen")
	await _wait_for(func(): return is_equal_approx(scene.music_duck, 0.5), "the Clubhouse music eases down under Talk the Talk")
	var sections: Array = Glossary.sections()
	var tab_names: Array = page.tabs.get_children().map(func(b): return b.text)
	var tabs: Array = page.tab_buttons.values()
	var panel_end: float = page.panel.get_global_rect().end.x
	var in_row := func(b: Button) -> bool: return is_equal_approx(b.global_position.y, tabs[0].global_position.y) and b.size.y >= 52 and b.get_global_rect().end.x <= panel_end + 1
	_check(tab_names == sections.map(func(s): return s.get("tab", s.name)) and tabs.all(in_row), "five tabs on one row inside the page (%s)" % str(tab_names))
	await _capture("glossary_run")
	# Every word of every tab, with its picture: walk on with Next, or tap a tab.
	var words := 0
	for i in sections.size():
		var section: Dictionary = sections[i]
		if i > 0:
			if i % 2 == 1: await _tap(page.next_button)
			else: await _tap(page.tab_buttons[section.id])
			await process_frame
		_check(page.section == section.id and page.tab_buttons[section.id].button_pressed and page.scroll.scroll_vertical == 0
			and page.entries.size() == section.terms.size(), "the %s tab shows its %d words, from the top" % [section.name, section.terms.size()])
		var expect_next: String = ("Next: " + String(sections[i + 1].name)) if i < sections.size() - 1 else ""
		_check((page.next_button.text if page.next_button != null else "") == expect_next, "the %s tab ends on '%s'" % [section.name, expect_next])
		for term in section.terms:
			var row: Control = page.entries[term.id]
			var picture: Control = page.diagram(term.id)
			_check(picture != null and picture.kind() == term.diagram.kind and picture.size.x >= 150 and row.find_child("Word", true, false).text == term.term
				and row.find_child("Meaning", true, false).text == term.text and row.get_global_rect().end.x <= page.panel.get_global_rect().end.x + 1,
				"%s: its picture (%s) and meaning, inside the page" % [term.term, term.diagram.kind])
			words += 1
		if section.id == "lane":
			var bar: VScrollBar = page.scroll.get_v_scroll_bar()
			_check(bar.max_value > page.scroll.size.y, "Lane & Ball's words scroll")
			await _capture("glossary_lane")
			page.scroll.ensure_control_visible(page.entries.pocket)
			await process_frame
			_check(page.diagram("pocket").handedness == "right" and page.diagram("pocket").side() > 0, "the pocket is drawn for a right-hander")
			await _capture("glossary_pocket")
			await _ui27_overlay(page)
		if section.id == "score": await _capture("glossary_scoring")
		if section.id == "cards": await _capture("glossary_cards")
	_check(words == Glossary.terms().size() and words >= 40, "every word shown (%d)" % words)
	# The pictures of a throw follow the hand in Throw Settings.
	await _action("ui_cancel")
	_check(not page.is_open() and scene.club_menu.visible and how.visible and how.get_node("ClubTalkTheTalk").has_focus(), "Escape on Talk the Talk returns to How to Play")
	scene.throw_settings.handedness = "left"
	await _tap(how.get_node("ClubTalkTheTalk"))
	page.show_section("lane")
	await process_frame
	page.scroll.ensure_control_visible(page.entries.pocket)
	await process_frame
	_check(page.diagram("pocket").handedness == "left" and page.diagram("pocket").side() < 0 and page.diagram("hook").side() < 0, "a left-hander's pocket and hook are mirrored")
	await _capture("glossary_pocket_left")
	scene.throw_settings.handedness = "right"
	# Landscape: a centred column.
	root.size = Vector2i(1280, 720)
	for i in 8: await process_frame
	var column: Rect2 = page.panel.get_global_rect()
	_check(absf(column.get_center().x - scene.get_global_rect().get_center().x) < 2.0 and column.size.x < scene.size.x * 0.75 and scene.get_global_rect().encloses(column),
		"in landscape Talk the Talk is a centred column")
	await _capture("glossary_landscape")
	root.size = PORTRAIT
	for i in 8: await process_frame
	await _tap(page.back_button)
	_check(not page.is_open() and how.visible and how.get_node("ClubTalkTheTalk").has_focus(), "Back on Talk the Talk returns to How to Play")
	await _tap(how.get_node("HowToPlayBack"))
	await _tap(scene.club_menu_list.get_node("CloseClubMenu"))
	_check(not scene.club_menu.visible and scene.club_menu_button.has_focus(), "the menu closes")
	await _wait_for(func(): return is_equal_approx(scene.music_duck, 1.0), "the Clubhouse music eases back")

## UI-27 (owner, 2026-11-19): Talk the Talk scrolls from anywhere, its tabs are the
## Clubhouse's, and a tapped word opens large in an overlay.
func _ui27_overlay(page) -> void:
	var stops := func(root_node: Node) -> bool:
		for node in root_node.find_children("*", "Control", true, false):
			if (node as Control).mouse_filter == Control.MOUSE_FILTER_STOP: return true
		return false
	_check(not stops.call(page.list) and page.list.get_children().all(func(r): return (r as Control).mouse_filter == Control.MOUSE_FILTER_PASS),
		"no word's row stops a drag: a finger anywhere scrolls the list")
	_check(page.scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER, "the list scrolls by finger, with no bar, as the Clubhouse's pages")
	var tab: Button = page.tab_buttons.lane
	_check(page.tabs.get_parent().name == "GlossaryTabTrack" and tab.get_theme_stylebox("pressed") is StyleBoxFlat
		and (tab.get_theme_stylebox("pressed") as StyleBoxFlat).border_color == Color("d8b873"), "the tabs are the Clubhouse's segments in a track")
	# A press that ends in a scroll opens nothing.
	var row: Control = page.entries.hook
	page.scroll.ensure_control_visible(row)
	await process_frame
	var before: int = page.scroll.scroll_vertical
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = row.get_global_rect().get_center()
	page._row_input(press, "hook")
	page.scroll.scroll_vertical = before + 120
	var lift := press.duplicate()
	lift.pressed = false
	page._row_input(lift, "hook")
	_check(not page.overlay.visible, "a press that scrolled the list opens nothing")
	page.scroll.scroll_vertical = before
	await process_frame
	# A tap opens the word large.
	await _tap(row)
	await process_frame
	var big: Control = page.overlay_picture
	_check(page.overlay.visible and page.shown_term == "hook" and page.overlay_word.text == "Hook" and page.overlay_meaning.text == page.diagram("hook").get_parent().get_parent().find_child("Meaning", true, false).text
		and big.kind() == "lane" and big.size.x > page.diagram("hook").size.x * 1.8 and page.overlay_close.has_focus()
		and scene.get_global_rect().encloses(page.overlay.find_child("TermCard", true, false).get_global_rect()), "a tapped word opens large: picture, name and meaning, on screen")
	await _capture("glossary_overlay")
	await _tap(page.overlay_close)
	_check(not page.overlay.visible and page.is_open() and page.section == "lane", "Close returns to the list")
	page.entries.pocket.grab_focus()
	await _action("ui_accept")
	_check(page.overlay.visible and page.shown_term == "pocket", "Enter on a focused word opens it")
	var scrim := preload("res://src/presentation/house_ui_theme.gd").SCRIM # UI-35: one scrim for every overlay
	_check(page.overlay.get_child(0).color == scrim and page.dim.color == scrim, "the word overlay and the guide darken with the game's one scrim")
	await _action("ui_cancel")
	_check(not page.overlay.visible and page.is_open(), "Escape closes the open word, not the guide")

## UI-9: on the Trophies and Goals pages a finger that lands on a row or a button
## drags the page; a Follow press that ended in a scroll follows nothing.
func _ui9_scroll() -> void:
	var club = scene.clubhouse
	await _tab("trophies")
	var stops := func(root_node: Node) -> bool:
		for node in root_node.find_children("*", "Control", true, false):
			if (node as Control).mouse_filter == Control.MOUSE_FILTER_STOP: return true
		return false
	_check(club.trophy_grid.get_child_count() > 0 and not stops.call(club.trophy_grid), "no trophy row stops a drag")
	await _tab("goals")
	_check(club.goals_list.get_child_count() > 0 and not stops.call(club.goals_list), "no goal row or button stops a drag")
	var page: ScrollContainer = club.pages.goals.get_parent()
	var first: Dictionary = {"id": ""}
	for row in club.goals_list.get_children():
		var button: Button = row.find_child("Track", true, false)
		if not button.disabled and not button.button_pressed:
			first.id = String(row.name).trim_prefix("Goal_")
			break
	var track: Button = club.goals_list.get_node("Goal_" + first.id).find_child("Track", true, false)
	var before: int = scene.career.get("tracked", []).size()
	track.button_down.emit()
	page.scroll_vertical += 200
	await process_frame
	track.pressed.emit()
	await process_frame
	_check(scene.career.get("tracked", []).size() == before, "a Follow press that ended in a scroll follows nothing")
	page.scroll_vertical = 0
	await _tab("board")

func _capture(label: String) -> void:
	var club = scene.clubhouse
	print("J11 stage=%d %s screen=%s tab=%s counts=%s selected=%s detail=%s" % [stage, label, scene.screen, club.current_tab,
		club.binder_counts.text, club.selected_item, club.binder_detail.text.get_slice("\n", 0)])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

func _tab(tab: String, touch: bool = false) -> void:
	var button: Button = scene.clubhouse.tab_buttons[tab]
	if touch:
		await _tap(button)
	else:
		await _focus_accept(button)
	await process_frame
	_check(scene.clubhouse.current_tab == tab and scene.clubhouse.pages[tab].get_parent().visible, "the %s tab opens" % tab)

func _card(item_id: String) -> Dictionary:
	await _focus_accept(scene.clubhouse.entry_button(item_id))
	await process_frame
	for entry in scene.clubhouse.Model.binder(scene.career, scene.career_graph, scene.career_graph.catalogue):
		if entry.id == item_id:
			return entry
	return {}

func _state(item_id: String) -> String:
	for entry in scene.clubhouse.Model.binder(scene.career, scene.career_graph, scene.career_graph.catalogue):
		if entry.id == item_id:
			return entry.state
	return ""

func _shelf(id: String) -> Control:
	return scene.clubhouse.trophy_grid.get_node_or_null("Trophy_" + id.replace(".", "_"))

func _earned(id: String) -> bool:
	var box := _shelf(id)
	return box != null and not box.find_child("Name", true, false).text.ends_with("(not yet)")

func _back_to_clubhouse() -> void:
	await _focus_accept(lab.hud.menu_button)
	await _through_awards()
	await _wait_for(func(): return scene.screen == "menu" and scene.lab == null and scene.clubhouse.visible, "the Clubhouse after the result", 400)
	lab = null

func _stage_one_clubhouse() -> void:
	var club = scene.clubhouse
	await _tab("binder", true)
	_check(club.binder_counts.text == "25 Locked · 82 Available · 0 Discovered · 0 Mastered", "a fresh binder: %s" % club.binder_counts.text)
	var tiles: Array = club.binder_stats.get_children().map(func(t): return t.get_child(0).get_child(0).text + " " + t.get_child(0).get_child(1).text)
	_check(" · ".join(tiles) == club.binder_counts.text, "the binder's tiles show the same counts: %s" % str(tiles))
	var cards: Array = club.binder_grid.get_children()
	_check(is_equal_approx(cards[2].global_position.y, cards[0].global_position.y) and not is_equal_approx(cards[3].global_position.y, cards[0].global_position.y)
		and cards[2].get_global_rect().end.x <= club.size.x, "a phone's binder is three cards across")
	# Owner (2026-11-17): in landscape the category tabs and the cards are centred.
	root.size = Vector2i(1000, 506)
	for i in 6: await process_frame
	var page: Rect2 = club.pages.binder.get_global_rect()
	var shown: Array = club.binder_grid.get_children().filter(func(c): return c.visible and not c.is_queued_for_deletion()) # the grid is rebuilt for the new width
	var row: Array = shown.filter(func(c): return is_equal_approx(c.global_position.y, shown[0].global_position.y))
	var strip: Rect2 = club.binder_tabs.get_global_rect()
	var tabs: Array = club.binder_filters.get_children().filter(func(c): return not c.is_queued_for_deletion())
	var gaps := [row[0].global_position.x - page.position.x, page.end.x - row[-1].get_global_rect().end.x,
		tabs[0].global_position.x - strip.position.x, strip.end.x - tabs[-1].get_global_rect().end.x]
	_check(row.size() > 3 and absf(gaps[0] - gaps[1]) <= 4.0 and gaps[2] > 40.0 and absf(gaps[2] - gaps[3]) <= 4.0,
		"in landscape the Binder's cards and tabs are centred (gaps %s)" % str(gaps.map(func(g): return roundi(g))))
	root.size = PORTRAIT
	for i in 6: await process_frame
	await _focus_accept(club.filter_button("charm"))
	_check(club.category == "charm" and club.binder_grid.get_child_count() == 52, "the Charms filter shows the fifty-two Charms")
	var encore := await _card("charm.encore")
	_check(encore.state == "locked" and club.selected_item == "charm.encore" and club.binder_detail.text.contains("Unlock: Beat The Surveyor (House League)")
		and club.binder_art.get_child(0) is TextureRect and club.binder_art.get_child(0).texture == load(encore.asset), "inspecting Encore: Locked, the rival that unlocks it, actual catalogue artwork")
	# UI-8: a tapped card opens in a preview over the page; Close returns to the grid,
	# which has not moved. The categories are tabs above the scrolling page.
	var scroll: ScrollContainer = club.pages.binder.get_parent()
	var grid_y: float = club.binder_grid.global_position.y - scroll.scroll_vertical
	var chosen: Control = club.entry_button("charm.encore")
	_check(club.binder_preview.visible and club.binder_preview.is_ancestor_of(club.binder_detail) and club.binder_preview.is_ancestor_of(club.binder_art)
		and club.preview_close.has_focus(), "the tapped card opens in the preview, its picture and history over the page")
	_check(club.binder_tabs.visible and club.binder_tabs.get_global_rect().end.y <= scroll.global_position.y + 1.0 and club.filter_button("charm").button_pressed,
		"the categories are tabs above the scrolling page, Charms chosen")
	_check(chosen.global_position.x - 3.0 >= scroll.global_position.x and chosen.get_global_rect().end.x + 3.0 <= scroll.get_global_rect().end.x,
		"the page's edges leave room for the chosen card's ring: %s in %s" % [str(chosen.get_global_rect()), str(scroll.get_global_rect())])
	_check(club.binder_preview.get_child(0).color == preload("res://src/presentation/house_ui_theme.gd").SCRIM, "the Binder preview darkens with the game's one scrim (UI-35)")
	await _capture("clubhouse_preview")
	await _focus_accept(club.preview_close)
	_check(not club.binder_preview.visible and chosen.has_focus(), "Close returns to the chosen card")
	var other: Dictionary = await _card("charm.flat_bonus")
	_check(other.state != "locked" and club.selected_item == "charm.flat_bonus" and club.binder_detail.text != "" and club.binder_preview.visible,
		"choosing another card opens its preview")
	_check(is_equal_approx(club.binder_grid.global_position.y - scroll.scroll_vertical, grid_y), "the grid does not move")
	await _focus_accept(club.preview_close)
	# A finger that lands on a card and drags scrolls the page: the cards pass the drag
	# on, never tilt, and a press that ended in a scroll opens nothing.
	var card: Control = club.entry_button("charm.flat_bonus")
	_check(card.mouse_filter == Control.MOUSE_FILTER_PASS and not card.tilt_enabled, "binder cards pass a drag to the page and do not tilt")
	card.button_down.emit()
	scroll.scroll_vertical += 120
	card.pressed.emit()
	_check(not club.binder_preview.visible and club.selected_item == "charm.flat_bonus", "a press that turned into a scroll opens no preview")
	scroll.scroll_vertical = 0
	encore = await _card("charm.encore")
	await _capture("clubhouse_locked")
	await _tab("goals")
	await _focus_accept(club.track_button("mastery.mixed_rack"))
	_check(scene.career.tracked == ["mastery.mixed_rack"] and _disk().get("tracked", []) == ["mastery.mixed_rack"]
		and club.track_button("mastery.mixed_rack").text == "Following", "following Mixed Rack is saved")
	await _capture("clubhouse_goals")
	await _tab("board", true)
	_check(scene.career_line.text.contains("Goals: Mixed Rack 0/3") and not scene.career_line.text.contains("Spare Hand"), "the League Board shows the followed goal")
	# Attempt 1: the J06 slice path to the House League title.
	scene.enter.grab_focus()
	await _enter(scene.enter)
	await _assist_on()
	await _division_one()
	await _division_two()
	await _back_to_clubhouse()
	await _tab("binder")
	_check(_state("pin.wood") == "mastered" and _state("ball.echo") == "mastered" and _state("charm.plumb_line") == "mastered", "cards owned in the win are Mastered")
	_check(_state("charm.encore") == "available" and _state("charm.standing_order") == "available" and _state("charm.gold_rush") == "available",
		"both unlocks and never-owned cards are Available")
	await _focus_accept(club.filter_button(""))
	var wood := await _card("pin.wood")
	_check(club.binder_detail.text.contains("Mastered") and club.binder_detail.text.contains("in 1 League win"), "inspecting Wood shows its win")
	await _capture("clubhouse_mastered")
	await _tab("trophies")
	_check(_earned("league.house") and _earned("rival.surveyor") and _earned("rival.custodian") and _earned("deco.club_sign") and _earned("deco.trophy_case")
		and not _earned("league.house_campaign") and not _earned("deco.lane_trim"), "the title, both plaques and two decorations are on the shelf")
	await _capture("clubhouse_trophies")
	await _ui9_scroll()

func _stage_two_clubhouse() -> void:
	var club = scene.clubhouse
	_check(scene.enter.text == "New Run" and club.records_label.text.contains("House League · 1 run") and club.records_label.text.contains("1 title"),
		"after a restart the board offers New Run and keeps the record")
	await _tab("binder")
	_check(_state("pin.wood") == "mastered" and _state("charm.encore") == "available", "Mastered and unlocked cards survive the restart")
	await _tab("board")
	scene.enter.grab_focus()
	await _enter(scene.enter)
	_check(not scene.clubhouse_music.playing, "the Clubhouse music stops when an attempt begins")
	await _assist_on()
	_check(lab.career_attempt == 2 and lab.shop.ineligibility(_encore(), lab.run).is_empty(), "attempt 2 has Encore in its pool")
	await _strike_out()
	await _to_shop("opener")
	# Buy the first Charm never owned before, rerolling (a real tap) while none is on offer.
	var bought := ""
	for visit in 4:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			var known: bool = scene.career.items.has(offer.item_id)
			if bought.is_empty() and offer.item_id.begins_with("charm.") and not known and not offer.sold and offer.price <= lab.run.money:
				await _tap(lab.shop_panel.button_for_offer(index))
				await process_frame
				if lab.shop.offers[index].sold:
					bought = offer.item_id
		if not bought.is_empty() or lab.run.money < lab.shop.reroll_cost() + 3:
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J11 stage=2 bought %s from %s" % [bought, str(lab.shop.offers.map(func(o): return "%s $%d" % [o.item_id, o.price]))])
	_check(not bought.is_empty(), "a Charm never owned before is bought")
	await _leave_shop()
	await _lose()
	await _back_to_clubhouse()
	_check(club.current_tab == "board" and club.records_label.text.contains("House League · 2 runs") and club.latest_label.text.contains("Encore joins the shop pool"),
		"after the loss the board counts both attempts and still lists the unlocks")
	await _tab("binder")
	_check(_state(bought) == "discovered" and _state("pin.wood") == "mastered" and _state("charm.encore") == "available", "the new Charm is Discovered; earlier rewards stay")
	await _card(bought)
	_check(club.binder_detail.text.contains("Discovered") and club.binder_detail.text.contains("Win a League with it"), "inspecting it explains how to master it")
	await _capture("clubhouse_discovered")
	await _tab("trophies")
	_check(_earned("league.house") and _earned("rival.surveyor") and _earned("deco.trophy_case"), "a loss takes nothing off the shelf")
	# Return to play: Binder -> League Board -> Try Again.
	await _tab("board", true)
	scene.enter.grab_focus()
	await _enter(scene.enter)
	_check(lab.state == "aim" and lab.career_attempt == 3, "Try Again returns to play")
	await _capture("clubhouse_return")
