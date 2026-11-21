extends Control
## Functional shell; visual treatment remains E11/E12 work.
const ThrowLab = preload("res://src/presentation/throw_lab.gd")
const SaveStore = preload("res://src/persistence/save_store.gd")
const Snapshot = preload("res://src/persistence/attempt_snapshot.gd")
const WebQA = preload("res://src/platform/web_qa.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const CareerProfile = preload("res://src/persistence/career_profile.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const FrameBuilder = preload("res://src/rules/frame_builder.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const UnlockGraph = preload("res://src/career/unlock_graph.gd")
const Clubhouse = preload("res://src/clubhouse/clubhouse.gd")
const MatchPanels = preload("res://src/presentation/match_panels.gd")
const TitleScreen = preload("res://src/bootstrap/title_screen.gd")
const Soundtrack = preload("res://src/presentation/soundtrack.gd")
const UiSounds = preload("res://src/presentation/ui_sounds.gd")
const ClubOptions = preload("res://src/clubhouse/clubhouse_options.gd")
const GlossaryPage = preload("res://src/clubhouse/glossary_page.gd")
const TutorialCoach = preload("res://src/presentation/tutorial_coach.gd")
## UI-13: the tutorial's practice lane always deals the same cards.
const TUTORIAL_SEED := 7
## Every new run in the real game gets its own random seed and the next run number
## from the Career (owner, 2026-11-19: before, every run entered from the board was
## run 1 with seed 1, so every player saw the same shops and draws). The seed is
## saved with the run, so a restored run carries on exactly as before. Journeys and
## the browser QA run keep seed = run number, for reproducible checks; the tutorial
## and the test Campaign keep their fixed seeds.
var random_runs := false
var session: Dictionary = {}
var screen := "menu"
var heading: Label
var details: Label
var enter: Button
var reset: Button
var back: Button
var league: OptionButton
var kit: OptionButton
var panel: VBoxContainer
## UI-5 (owner, 2026-11-10): one menu button on every match screen, beside the top
## bar, in place of a row of session buttons. Its sheet lists the entries; more can
## join through add_menu_entry.
var menu_button: Button
var session_menu: Control
var menu_list: VBoxContainer
var resume: Button
var options: Button
var _restart_armed := false
var lab: ThrowLab
## Throw settings shared by every session this run (persistence is E25).
var throw_settings: Dictionary = {}
## The owner's Clubhouse music (2026-11-16): the title and the Clubhouse between
## attempts. A League's own music takes over during an attempt.
var clubhouse_music: AudioStreamPlayer
## The owner (2026-11-16): the Clubhouse music starts at the Clubhouse menu, after the
## title's tap (which plays its own sound), never under the title.
var _awaiting_title := false
const TITLE_TAP_SOUND := "res://assets/audio/ui_title_start.wav"
var tap_sound: AudioStreamPlayer
## UI-12 (owner's play notes, 2026-11-16): button taps, and the Clubhouse's own menu.
var ui_sounds: UiSounds
var club_menu_button: Button
var sound_entry: Button # UI-15: the session menu's Sound & Effects
var _menu_page := "" # the session menu's page that is open: "throw", "sound" or ""
var club_menu: Control
var club_menu_list: VBoxContainer
var club_options: ClubOptions
## UI-24 (owner, 2026-11-19): How to Play offers a choice, the tutorial or Talk the
## Talk (the words the game uses, with pictures), on a second page of the menu sheet.
var club_how_list: VBoxContainer
var club_glossary: GlossaryPage
var music_duck := 1.0 # the Clubhouse music eases to half under its Options
## UI-23 (owner, 2026-11-19): leaving a run for the Clubhouse is a slow fade: the
## screen and the run's music fade out together (EXIT_OUT). UI-25 (owner, the same
## day): the fade follows the award ceremony, and there is no fade into the
## Clubhouse: after a moment in the dark (EXIT_HOLD) it is simply there, with its music.
const EXIT_OUT := 1.5 # UI-31 (owner, 2026-11-20): half UI-25's 3 s
const EXIT_HOLD := 0.15
var curtain_layer: CanvasLayer
var curtain: ColorRect
var exiting := false # leaving a run: its awards, then the fade out
## UI-13 (owner, 2026-11-17): "Learn to Bowl", a guided practice match (the coach).
var coach: TutorialCoach
var tutorial_first_run := false # started by a new player's first Enter League
var _tutorial_return := "" # the League choice to restore when the tutorial ends
var _coach_from := "" # the coach's first step ("" from the start)
## Career record (E09), saved apart from attempts since E10 (career.json); E15
## (ADR 010) adds the validated unlock graph, records and mastery. Restart and
## retry keep it.
var career: Dictionary = {}
var career_graph: Dictionary = {}
var career_line: Label # the full sentence (read by tools and tests); the tiles and bars show it
var career_stats: HBoxContainer
var career_goals: VBoxContainer
var following: Label # UI-9: the caption over the followed goals
var _menu_sheet: PanelContainer
var league_sets: Array = [] # content set behind each League choice
## The Clubhouse (E16): the home screen; its League Board holds the panel below.
var clubhouse: Clubhouse
## UI-7: the title screen over the Clubhouse when the game starts (null when the
## shell is embedded by a journey or tool, which opens at the Clubhouse).
var title: Control
## E10 saves: user://saves, or --save-dir=<path> for tests.
var store: RefCounted
var continue_button: Button
var notice: Label
var save_notice := ""
## The content set every attempt this run plays (E13): the slice, or --content=lab.
var content: Dictionary = {}

func _ready() -> void:
	ui_sounds = UiSounds.new()
	ui_sounds.settings = throw_settings
	add_child(ui_sounds)
	_awaiting_title = show_title_on_start()
	random_runs = show_title_on_start() and not WebQA.requested()
	# UI-2: one House theme (frame kit, Pixelify Sans) for every screen.
	theme = UiTheme.build()
	get_window().size_changed.connect(_viewport_layout)
	_viewport_layout()
	clubhouse = Clubhouse.new()
	add_child(clubhouse)
	panel = VBoxContainer.new()
	panel.name = "LeaguePanel"
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_constant_override("separation", 20)
	clubhouse.adopt_board(panel)
	# UI-9 (owner's play notes, 2026-11-15): the Clubhouse's logo names the game, so
	# the board's own "Roguewood" heading is kept for tools but hidden.
	heading = Label.new()
	heading.text = "Roguewood"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 48)
	heading.hide()
	panel.add_child(heading)
	details = Label.new()
	details.name = "BoardTagline"
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 18)
	details.text = "The lanes are waiting."
	panel.add_child(details)
	content = ContentSet.load_set(ContentSet.requested())
	if not content.errors.is_empty():
		push_error("Content set %s invalid: %s" % [content.id, str(content.errors)])
	career_graph = ContentSet.career_graph(content.unlocks)
	if not career_graph.errors.is_empty():
		push_error("Unlock graph invalid: %s" % str(career_graph.errors))
	career_line = Label.new()
	career_line.name = "CareerSummary"
	career_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	career_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	career_line.custom_minimum_size = Vector2(460, 0)
	career_line.hide()
	panel.add_child(career_line)
	# The Career at a glance: a scoreboard of four figures, then each followed goal
	# with its progress (UI-9: one plate, so the figures never look like buttons).
	var scoreboard := PanelContainer.new()
	scoreboard.name = "CareerScoreboard"
	scoreboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scoreboard.add_theme_stylebox_override("panel", Clubhouse.scoreboard_style())
	panel.add_child(scoreboard)
	var plate := VBoxContainer.new()
	plate.add_theme_constant_override("separation", 8)
	scoreboard.add_child(plate)
	career_stats = HBoxContainer.new()
	career_stats.name = "CareerStats"
	career_stats.add_theme_constant_override("separation", 0)
	plate.add_child(career_stats)
	following = Clubhouse.caption("Following", "FollowingCaption")
	plate.add_child(following)
	career_goals = VBoxContainer.new()
	career_goals.name = "CareerGoals"
	career_goals.add_theme_constant_override("separation", 6)
	plate.add_child(career_goals)
	# The play card: the choices under their captions, then the action.
	var play := PanelContainer.new()
	play.name = "PlayCard"
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color("13232a")
	play_style.border_color = Color("8a6a32")
	play_style.set_border_width_all(2)
	play_style.set_corner_radius_all(10)
	play_style.set_content_margin_all(14)
	play.add_theme_stylebox_override("panel", play_style)
	panel.add_child(play)
	var play_box := VBoxContainer.new()
	play_box.name = "PlayBox"
	play_box.add_theme_constant_override("separation", 6)
	play.add_child(play_box)
	league = OptionButton.new()
	league.name = "LeagueChoice"
	league.add_item(content.get("name", "House League"))
	league_sets = [content.id]
	if content.id == "house":
		# E22-L02: the production board lists every live League.
		league.add_item(ContentSet.load_set("neon").get("name", "Neon League"))
		league_sets.append("neon")
	if content.id == "slice":
		# The provisional seeded campaign (E14) is a test fixture, not a League: it is
		# offered only beside the test slice, for J09 (owner, 2026-11-18).
		league.add_item("House Campaign · 8 Divisions (provisional)")
		league_sets.append("campaign")
	if league_sets.size() > 1:
		league.item_selected.connect(func(index):
			content = ContentSet.load_set(league_sets[index])
			_show_menu())
	play_box.add_child(Clubhouse.caption("League", "LeagueCaption"))
	play_box.add_child(league)
	Clubhouse.selector_style(league)
	league.clip_text = true # a long name is cut, never widens the column
	var gap := Control.new()
	gap.custom_minimum_size.y = 4
	play_box.add_child(gap)
	play_box.add_child(Clubhouse.caption("Kit", "KitCaption"))
	kit = OptionButton.new()
	kit.name = "KitChoice"
	play_box.add_child(kit)
	Clubhouse.selector_style(kit)
	kit.clip_text = true
	_refresh_kits()
	var room := Control.new()
	room.custom_minimum_size.y = 8
	play_box.add_child(room)
	continue_button = _button(play_box, "Continue Run", "ContinueAttempt", 0)
	continue_button.pressed.connect(_continue_attempt)
	enter = _button(play_box, "Enter League", "EnterLeague", 0)
	for action in [continue_button, enter]:
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice = Label.new()
	notice.name = "SaveNotice"
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.custom_minimum_size = Vector2(200, 0)
	notice.add_theme_color_override("font_color", Color(1.0, 0.75, 0.5))
	play_box.add_child(notice)
	var save_dir := "user://saves"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): save_dir = arg.trim_prefix("--save-dir=")
	store = SaveStore.create(save_dir)
	_load_career()
	clubhouse.graph = career_graph
	clubhouse.career_changed.connect(_save_career)
	_build_session_menu()
	_build_club_menu()
	resized.connect(_place_menu)
	_viewport_layout()
	enter.pressed.connect(_start_session)
	_show_menu()
	if show_title_on_start():
		_open_title()
	# E26-W01: browser QA status, only in a Web build opened with ?qa=1.
	if WebQA.requested():
		var qa := WebQA.new()
		qa.name = "WebQA"
		qa.shell = self
		add_child(qa)
	if "--bootstrap-smoke" in OS.get_cmdline_user_args():
		print("ROGUEWOOD_BOOT_OK")
		get_tree().quit(0)

## The title opens the game when this shell is the running scene (the real game,
## desktop or web; J01 and the phone tour start it the same way). A journey or tool
## that embeds the shell as a child opens at the Clubhouse, as before.
func show_title_on_start() -> bool:
	return get_tree().current_scene == self

## Plays the Clubhouse track (once started, it keeps its place) at the session's
## Music level; a browser lets it sound from the first tap, which is the title's.
func _play_clubhouse_music() -> void:
	if not Soundtrack.has("clubhouse"): return
	if clubhouse_music == null:
		clubhouse_music = AudioStreamPlayer.new()
		clubhouse_music.name = "ClubhouseMusic"
		clubhouse_music.stream = Soundtrack.stream("clubhouse")
		add_child(clubhouse_music)
	clubhouse_music.volume_db = Soundtrack.level_db(throw_settings) + linear_to_db(maxf(music_duck, 0.0001))
	if not clubhouse_music.playing:
		clubhouse_music.play()

func _stop_clubhouse_music() -> void:
	if clubhouse_music != null:
		clubhouse_music.stop()

## Lets go of the loop when the shell closes, so the audio thread holds no playback
## at exit (as LeagueTheme does).
func _exit_tree() -> void:
	if tap_sound != null:
		tap_sound.stop()
		tap_sound.stream = null
	if clubhouse_music == null and tap_sound == null and ui_sounds.played == 0: return
	if clubhouse_music != null:
		clubhouse_music.stop()
		clubhouse_music.stream = null
	if AudioServer.get_driver_name() == "Dummy":
		# As PresentationAudio: under the Dummy driver (journeys) the stopped playback
		# is retired on the next mixer pass, so wait for an actual pass (bounded).
		var stopped_at := Time.get_ticks_usec()
		while Time.get_ticks_usec() - stopped_at < 1000000:
			var sampled_at := Time.get_ticks_usec()
			var since_mix := int(AudioServer.get_time_since_last_mix() * 1000000.0)
			if sampled_at - since_mix > stopped_at: break
			OS.delay_msec(1)

func _open_title() -> void:
	title = TitleScreen.new()
	add_child(title)
	title.started.connect(_title_done)
	screen = "title"
	title.tapped.connect(_title_tapped)
	title.open(bool(throw_settings.get("reduced_motion", false)))

## The tap's sound, at the session's sound-effects level (PresentationAudio's mix).
func _title_tapped() -> void:
	if bool(throw_settings.get("sound_muted", false)) or not ResourceLoader.exists(TITLE_TAP_SOUND): return
	if tap_sound == null:
		tap_sound = AudioStreamPlayer.new()
		tap_sound.name = "TitleTapSound"
		tap_sound.stream = load(TITLE_TAP_SOUND)
		add_child(tap_sound)
	tap_sound.volume_db = linear_to_db(maxf(0.0001, float(throw_settings.get("sound_volume", 0.65)) * 0.35 * 2.0))
	tap_sound.play()

func _title_done() -> void:
	_awaiting_title = false
	screen = "menu"
	_play_clubhouse_music()
	(continue_button if continue_button.visible else enter).grab_focus()

func _button(parent: Node, label: String, node_name: String, width: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(width, 64)
	parent.add_child(button)
	return button

func _start_session() -> void:
	if content.id == "tutorial": # Restart run within the tutorial starts it again
		_begin_tutorial()
		return
	if _offer_tutorial():
		start_tutorial(true)
		return
	_begin_attempt(1)

## A new player's first Enter League opens the tutorial (the real game only: a shell
## embedded by a journey, and the browser QA run, enter the League as before).
func _offer_tutorial() -> bool:
	return show_title_on_start() and not WebQA.requested() and int(career.get("attempts", 0)) == 0 \
		and not bool(career.get("tutorial", {}).get("seen", false))

## Plays the tutorial on its practice lane. first_run: it was the player's first
## Enter League, so its last step (and Skip) go on to the chosen League.
func start_tutorial(first_run: bool = false) -> void:
	tutorial_first_run = first_run
	if content.id != "tutorial": _tutorial_return = content.id
	var record: Dictionary = career.get("tutorial", {})
	record["seen"] = true
	career["tutorial"] = record
	_save_career()
	content = ContentSet.load_set("tutorial")
	_begin_tutorial()

func _begin_tutorial(from_step: String = "") -> void:
	_coach_from = from_step
	_begin_attempt(1)

func _attach_coach() -> void:
	if coach != null:
		coach.queue_free()
	coach = TutorialCoach.new()
	coach.name = "TutorialCoach"
	coach.lab = lab
	coach.first_run = tutorial_first_run
	coach.reduced = bool(throw_settings.get("reduced_motion", false))
	add_child(coach)
	lab.chrome = [menu_button, coach.card] # a touch on the coach's card is never a throw
	if not _coach_from.is_empty(): coach.step = maxi(coach._index(_coach_from), 0)
	coach.finished.connect(_on_coach_finished, CONNECT_DEFERRED)

func _on_coach_finished(choice: String) -> void:
	if choice in ["run", "clubhouse", "practice"]:
		career.tutorial["completed"] = true
		_save_career()
	if coach != null:
		coach.queue_free()
		coach = null
	match choice:
		"practice": pass # the practice lane plays on, unguided
		"retry": _begin_tutorial("aim")
		"run", "skip":
			if tutorial_first_run:
				_end_tutorial()
				_begin_attempt(1)
			else:
				exit_to_clubhouse()
		_: exit_to_clubhouse()

## Back to the League the player had chosen.
func _end_tutorial() -> void:
	if coach != null:
		coach.queue_free()
		coach = null
	if content.id == "tutorial":
		content = ContentSet.load_set(_tutorial_return if not _tutorial_return.is_empty() else league_sets[league.selected])

## The menu button (three bars, drawn; Codex can supply an icon by asset later) and
## its sheet: a dimmed layer over the match with a short list of large entries.
func _build_session_menu() -> void:
	menu_button = Button.new()
	menu_button.name = "SessionMenu"
	menu_button.tooltip_text = "Menu"
	_draw_bars(menu_button)
	menu_button.pressed.connect(open_menu)
	menu_button.hide()
	add_child(menu_button)
	session_menu = Control.new()
	session_menu.name = "SessionMenuSheet"
	session_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session_menu.hide()
	add_child(session_menu)
	var dim := ColorRect.new()
	dim.color = UiTheme.SCRIM # UI-35: one scrim behind every overlay
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed: close_menu())
	session_menu.add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	session_menu.add_child(centre)
	var sheet := PanelContainer.new()
	_menu_sheet = sheet
	sheet.add_theme_stylebox_override("panel", UiTheme.frame("menu", 20.0, 18.0))
	centre.add_child(sheet)
	menu_list = VBoxContainer.new()
	menu_list.name = "Entries"
	menu_list.add_theme_constant_override("separation", 10)
	sheet.add_child(menu_list)
	var title := Label.new()
	title.text = "Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	menu_list.add_child(title)
	# UI-15 (owner, 2026-11-18): the same menu as the Clubhouse's. Throw Settings and
	# Sound & Effects are sibling pages; each one's Back returns here.
	resume = add_menu_entry("Resume", "ResumeSession", func(): pass)
	options = add_menu_entry("Throw Settings", "ThrowOptions", func(): _open_page("throw"), false)
	options.pressed.connect(func(): _open_page("throw"))
	sound_entry = add_menu_entry("Sound & Effects", "SoundOptions", func(): pass, false)
	sound_entry.pressed.connect(func(): _open_page("sound"))
	back = add_menu_entry("Clubhouse", "BackToMenu", exit_to_clubhouse)
	# Restart discards the attempt, so it asks once: the first press arms it.
	reset = add_menu_entry("Restart Run", "ResetSession", func(): pass, false)
	reset.pressed.connect(func():
		if _restart_armed:
			close_menu()
			_start_session()
		else:
			_restart_armed = true
			reset.text = "Discard This Run? Press Again")

## Three drawn bars on a menu button.
static func _draw_bars(button: Button) -> void:
	button.draw.connect(func():
		var w := button.size.x
		var h := button.size.y
		for i in 3:
			var y := h * 0.5 + (i - 1) * 9.0
			button.draw_rect(Rect2(w * 0.5 - 12.0, y - 2.0, 24.0, 4.0), UiTheme.IVORY))

## A page from the session menu: the menu steps aside (the lane stays paused) and
## the page's Back brings it back.
func _open_page(page: String) -> void:
	if lab == null: return
	session_menu.hide()
	_menu_page = page
	if page == "sound":
		lab.motion.sound.open()
	else:
		lab.settings_panel.show()
		lab.settings_panel.handedness.grab_focus()

func _page_back(page: String) -> void:
	if _menu_page != page: return
	_menu_page = ""
	open_menu()
	(sound_entry if page == "sound" else options).grab_focus()

## UI-12 (owner's play notes, 2026-11-16): the Clubhouse's menu, at its top right.
## UI-15 (owner, 2026-11-18): the same entries and pages as a match's menu (Throw
## Settings and Sound & Effects, on the same session settings), each page's Back
## returning here; then Close.
func _build_club_menu() -> void:
	club_menu_button = Button.new()
	club_menu_button.name = "ClubhouseMenu"
	club_menu_button.tooltip_text = "Menu"
	club_menu_button.custom_minimum_size = Vector2(56, 56)
	_draw_bars(club_menu_button)
	club_menu_button.pressed.connect(open_club_menu)
	add_child(club_menu_button)
	club_menu = Control.new()
	club_menu.name = "ClubhouseMenuSheet"
	club_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	club_menu.hide()
	add_child(club_menu)
	var dim := ColorRect.new()
	dim.color = UiTheme.SCRIM # UI-35: one scrim behind every overlay
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed: close_club_menu())
	club_menu.add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	club_menu.add_child(centre)
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiTheme.frame("menu", 20.0, 18.0))
	centre.add_child(sheet)
	club_menu_list = VBoxContainer.new()
	club_menu_list.name = "Entries"
	club_menu_list.add_theme_constant_override("separation", 10)
	sheet.add_child(club_menu_list)
	var title_label := Label.new()
	title_label.text = "Menu"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	club_menu_list.add_child(title_label)
	# UI-13: the tutorial, any time; UI-24: beside Talk the Talk, on How to Play's page.
	var how := _button(club_menu_list, "How to Play", "ClubHowToPlay", 320)
	how.pressed.connect(show_how_to_play)
	for entry in [["Throw Settings", "ClubOptions", "throw"], ["Sound & Effects", "ClubSound", "sound"]]:
		var page: String = entry[2]
		var button := _button(club_menu_list, entry[0], entry[1], 320)
		button.pressed.connect(func():
			club_menu.hide()
			club_options.open(page))
	var close_button := _button(club_menu_list, "Close", "CloseClubMenu", 320)
	close_button.pressed.connect(close_club_menu)
	_build_how_to_play(sheet)
	club_options = ClubOptions.new()
	club_options.settings = throw_settings
	add_child(club_options)
	club_options.closed.connect(func(page: String):
		if screen != "menu": return
		club_menu.show()
		club_menu_list.get_node("ClubSound" if page == "sound" else "ClubOptions").grab_focus())

## UI-24: How to Play's page in the menu sheet: Play Tutorial (the practice lane,
## UI-13) or Talk the Talk (GlossaryPage); Back returns to the menu's entries.
func _build_how_to_play(sheet: Control) -> void:
	club_how_list = VBoxContainer.new()
	club_how_list.name = "HowToPlay"
	club_how_list.add_theme_constant_override("separation", 10)
	club_how_list.hide()
	sheet.add_child(club_how_list)
	var heading := Label.new()
	heading.text = "How to Play"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	club_how_list.add_child(heading)
	var tutorial := _button(club_how_list, "Play Tutorial", "ClubPlayTutorial", 320)
	tutorial.pressed.connect(func():
		club_menu.hide()
		_show_club_entries()
		start_tutorial(false))
	_how_caption("A guided practice lane")
	var talk := _button(club_how_list, "Talk the Talk", "ClubTalkTheTalk", 320)
	talk.pressed.connect(open_glossary)
	_how_caption("Bowling words, explained with pictures")
	var back_button := _button(club_how_list, "Back", "HowToPlayBack", 320)
	back_button.pressed.connect(how_to_play_back)
	club_glossary = GlossaryPage.new()
	add_child(club_glossary)
	club_glossary.closed.connect(func():
		if screen != "menu": return
		club_menu.show()
		show_how_to_play("ClubTalkTheTalk"))

func _how_caption(text: String) -> void:
	var caption := Label.new()
	caption.text = text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_color", Color("9aa8a6"))
	club_how_list.add_child(caption)

## How to Play's page, its focus on `focus` (Play Tutorial by default).
func show_how_to_play(focus: String = "ClubPlayTutorial") -> void:
	club_menu_list.hide()
	club_how_list.show()
	club_how_list.get_node(focus).grab_focus()

func how_to_play_back() -> void:
	_show_club_entries()
	club_menu_list.get_node("ClubHowToPlay").grab_focus()

func _show_club_entries() -> void:
	club_how_list.hide()
	club_menu_list.show()

func open_glossary() -> void:
	club_menu.hide()
	club_glossary.open(throw_settings)

func open_club_menu() -> void:
	if screen != "menu": return
	_show_club_entries()
	club_menu.show()
	club_menu_list.get_node("ClubHowToPlay").grab_focus()

func close_club_menu() -> void:
	if not club_menu.visible: return
	club_menu.hide()
	_show_club_entries()
	club_menu_button.grab_focus()

## The Clubhouse music eases to half while its Options are open (as a match's music
## does), and while Talk the Talk is (UI-24).
func _process(delta: float) -> void:
	if clubhouse_music == null or not clubhouse_music.playing: return
	var dipped := (club_options != null and club_options.is_open()) or (club_glossary != null and club_glossary.is_open())
	music_duck = move_toward(music_duck, 0.5 if dipped else 1.0, delta * 0.5 / 0.4)
	clubhouse_music.volume_db = Soundtrack.level_db(throw_settings) + linear_to_db(maxf(music_duck, 0.0001))

## Adds an entry to the session menu and returns its button. `closes` entries close
## the menu before they act, so what they open is not under the sheet.
func add_menu_entry(label: String, node_name: String, action: Callable, closes: bool = true) -> Button:
	var entry := _button(menu_list, label, node_name, 320)
	if closes:
		entry.pressed.connect(func():
			close_menu()
			action.call())
	return entry

func open_menu() -> void:
	if screen != "session": return
	_restart_armed = false
	reset.text = "Restart Run"
	session_menu.show()
	if lab: lab.input_paused = true
	resume.grab_focus()

func close_menu() -> void:
	if not session_menu.visible: return
	session_menu.hide()
	if lab: lab.input_paused = false
	if menu_button.visible: menu_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	# UI-15: Escape on a page goes back to its menu; on a menu, closes it.
	if _menu_page != "" and lab != null and event.is_action_pressed("ui_cancel"):
		if _menu_page == "sound": lab.motion.sound.go_back()
		else: lab.settings_panel.go_back()
		get_viewport().set_input_as_handled()
	elif session_menu != null and session_menu.visible and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()
	elif club_menu != null and club_menu.visible and club_how_list.visible and event.is_action_pressed("ui_cancel"):
		how_to_play_back() # UI-24: How to Play's page goes back to the menu's entries
		get_viewport().set_input_as_handled()
	elif club_menu != null and club_menu.visible and event.is_action_pressed("ui_cancel"):
		close_club_menu()
		get_viewport().set_input_as_handled()
	elif club_glossary != null and club_glossary.is_open() and event.is_action_pressed("ui_cancel"):
		club_glossary.go_back()
		get_viewport().set_input_as_handled()
	elif club_options != null and club_options.is_open() and event.is_action_pressed("ui_cancel"):
		club_options.go_back()
		get_viewport().set_input_as_handled()

## Beside the top bar, where MatchPanels leaves room for it.
func _place_menu() -> void:
	if menu_button == null: return
	var rect := MatchPanels.menu_rect(size)
	menu_button.position = rect.position
	menu_button.size = rect.size
	if club_menu_button != null:
		club_menu_button.size = Vector2(56, 56)
		club_menu_button.position = Vector2(size.x - 16.0 - 56.0, 16.0)

## The board's Career summary and followed goals.
func _refresh_career_line() -> void:
	career_line.text = CareerProfile.summary(career, career_graph.get("objectives", []))
	var goals: Array = CareerProfile.goals(career, career_graph.get("objectives", []), 0) # attempt-scoped goals start over
	if not goals.is_empty():
		career_line.text += "\nGoals: " + " · ".join(goals.map(func(g): return "%s %d/%d" % [g.name, mini(g.progress, g.threshold), g.threshold]))
	for box in [career_stats, career_goals]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	var stats: Dictionary = CareerProfile.stats(career, career_graph.get("objectives", []))
	var tiles := [[str(stats.rivals), "Rivals beaten"], [str(stats.titles), "Titles"], ["%d/%d" % [stats.mastered, stats.goals], "Mastery"], [str(stats.attempts), "Runs"]]
	for i in tiles.size():
		career_stats.add_child(Clubhouse.score_column(tiles[i][0], tiles[i][1], i == 0))
	following.visible = not goals.is_empty()
	for goal in goals:
		var row := HBoxContainer.new()
		row.name = "Goal_" + String(goal.get("id", goal.name)).replace(".", "_")
		row.add_theme_constant_override("separation", 10)
		var title := Label.new()
		title.text = goal.name
		title.add_theme_font_size_override("font_size", 18)
		title.custom_minimum_size = Vector2(150, 0)
		row.add_child(title)
		var bar := Clubhouse.progress_row(int(goal.progress), int(goal.threshold))
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)
		career_goals.add_child(row)

## Saves the Career after a Clubhouse change (tracked goals).
func _save_career() -> void:
	_refresh_career_line()
	var errors: Array[String] = store.write("career", CareerProfile.normalized(career))
	if not errors.is_empty():
		push_warning("Career not saved: " + str(errors))

func _load_career() -> void:
	var read: Dictionary = store.read("career")
	career = CareerProfile.normalized(read.payload) if read.ok else CareerProfile.fresh()
	if not read.notice.is_empty():
		save_notice = read.notice
	var unknown: Array = CareerProfile.unknown_ids(career, career_graph)
	if not unknown.is_empty():
		save_notice = ("%s\n" % save_notice if not save_notice.is_empty() else "") + "Your Career holds %d unlock(s) this version does not use; they are kept." % unknown.size()

## The saved attempt, if it can be resumed: {ok, payload, notice}.
func _saved_attempt() -> Dictionary:
	var read: Dictionary = store.read("attempt")
	if not read.ok:
		return read
	# An attempt saved in another League on the board is continued in that League.
	var saved_set := String(read.payload.get("content_set", "lab"))
	var target: Dictionary = content
	if saved_set != content.id and saved_set in league_sets:
		target = ContentSet.load_set(saved_set, int(read.payload.get("seed", 1)))
	var problems := Snapshot.validate(read.payload, target.catalogue, target.id)
	if not problems.is_empty():
		return {"ok": false, "notice": "The saved attempt no longer fits this version's content (%s); start a new run." % problems[0]}
	if read.payload.phase == "division_over" and not (target.id == "campaign" and read.payload.division.current.outcome == "won"):
		return {"ok": false, "notice": read.notice}
	read["content_set"] = target.id
	return read

func _continue_attempt() -> void:
	var saved := _saved_attempt()
	if saved.ok:
		if saved.content_set != content.id:
			content = ContentSet.load_set(saved.content_set, int(saved.payload.get("seed", 1)))
			league.select(league_sets.find(saved.content_set))
		_begin_attempt(int(saved.payload.attempt), saved.payload)
## A fresh seed for a new run (random_runs).
func new_run_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 2147483646)

## Attempt n of the content set's League (seed n; random_runs draws a fresh seed and
## numbers the run from the Career). Restart Session begins
## attempt 1 again; Retry and New Attempt begin the next one.
## A saved payload resumes that attempt instead of starting fresh.
func _begin_attempt(attempt: int, saved: Dictionary = {}) -> void:
	_stop_clubhouse_music()
	var run_seed := attempt
	if saved.is_empty() and random_runs and content.id not in ["campaign", "tutorial"]:
		attempt = int(career.get("attempts", 0)) + 1
		run_seed = new_run_seed()
	if content.id == "campaign": content = ContentSet.load_set("campaign", int(saved.get("seed", attempt)))
	if saved.is_empty():
		content.kit = _chosen_kit()
	session = {"schema_version": 1, "seed": run_seed, "attempt": attempt, "league_id": String(content.get("league_id", "league.house")) if content.id != "campaign" else "league.house", "kit_id": content.kit.get("id", "kit.house"),
		"content": content.id, "division": 1, "match": 1, "frame": 1, "score": 0, "money": int(content.kit.get("money", 6))}
	if not saved.is_empty():
		session.seed = int(saved.seed)
		session.score = int(saved.lab.total_score)
		session.frame = int(saved.lab.frame_number)
		session.match = int(saved.lab.match_number)
		session.money = int(saved.run.money)
	screen = "session"
	details.text = "%s · %d Division%s" % [content.get("name", "House League"), content.divisions.size(), "" if content.divisions.size() == 1 else "s"]
	if content.id == "campaign": details.text += " · Seed %d" % int(session.seed)
	clubhouse.hide()
	club_menu_button.hide()
	club_menu.hide()
	club_options.close()
	club_glossary.close()
	_clear_lab()
	# E22-L02: the League's frame kit for everything the attempt builds, and for the
	# session menu over it. The lab's own Theme carries the kit to its buttons.
	UiTheme.use_kit(String(content.get("league_id", "")) if content.id in ["house", "neon"] else "")
	_menu_sheet.add_theme_stylebox_override("panel", UiTheme.frame("menu", 20.0, 18.0))
	# Throw lab (E04–E09); the lane draws beneath the session controls.
	lab = ThrowLab.new()
	lab.name = "ThrowLab"
	if UiTheme.kit != UiTheme.KIT:
		lab.theme = UiTheme.build()
	menu_button.theme = lab.theme
	session_menu.theme = lab.theme
	lab.settings = throw_settings
	lab.content = content
	lab.equipment_seed = session.seed
	lab.career = career
	lab.career_graph = career_graph
	lab.attempt = attempt
	lab.save_store = store
	lab.restore_from = saved
	if content.id == "tutorial":
		# UI-13: a practice lane. A throwaway Career and no saves, so nothing counts;
		# the same seed every time, so the cards and the first shop never change.
		lab.career = CareerProfile.fresh()
		lab.save_store = null
		lab.equipment_seed = TUTORIAL_SEED
		lab.restore_from = {}
	lab.attempt_finished.connect(func(outcome): session.outcome = outcome)
	lab.retry_requested.connect(func(): _begin_attempt(int(session.attempt) + 1), CONNECT_DEFERRED)
	lab.menu_requested.connect(exit_to_clubhouse, CONNECT_DEFERRED)
	lab.frame_scored.connect(_on_frame_scored)
	lab.money_changed.connect(func(money): session.money = money)
	lab.chrome = [menu_button]
	add_child(lab)
	move_child(lab, 0)
	_menu_page = ""
	lab.settings_panel.back.connect(_page_back.bind("throw"))
	lab.motion.sound.back.connect(_page_back.bind("sound"))
	session_menu.hide()
	menu_button.show()
	_place_menu()
	menu_button.grab_focus()
	if content.id == "tutorial" and (attempt == 1 or coach != null):
		_attach_coach()

## The session fixture tracks the lab's banked total and current frame.
func _on_frame_scored(scored: Dictionary) -> void:
	session.score = int(session.score) + int(scored.get("banked", scored.result.score))
	session.frame = int(scored.frame_number) + 1
	session.match = int(scored.get("match_number", session.match))
	if lab != null:
		session.division = lab.division.division_number()

## UI-23: from a run to the Clubhouse, slowly. UI-25: a run's awards come first
## (after its result sheet); the run then fades out, taking no input, and the
## Clubhouse appears without a fade, taking input at once.
func exit_to_clubhouse() -> void:
	if exiting:
		return
	if lab == null:
		_show_menu()
		return
	exiting = true
	session_menu.hide()
	menu_button.hide()
	if lab.has_method("awards_pending") and lab.awards_pending():
		await lab.present_pending_awards()
		if lab == null or screen != "session":
			exiting = false
			return
	lab.input_paused = true
	if lab.motion != null and lab.motion.get("sound") != null:
		lab.motion.sound.fade_music(EXIT_OUT)
	if lab.get("award_ceremony") != null:
		lab.award_ceremony.fade_music(EXIT_OUT)
	_curtain()
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain_layer.show()
	var out := create_tween()
	out.tween_property(curtain, "color:a", 1.0, EXIT_OUT * (1.0 - curtain.color.a))
	out.tween_interval(EXIT_HOLD)
	await out.finished
	# The Clubhouse, at once: no fade in (UI-25).
	exiting = false
	_show_menu()
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.color.a = 0.0
	curtain_layer.hide()

## True while the screen is fading out of a run.
func transition_playing() -> bool:
	return curtain_layer != null and curtain_layer.visible

func _curtain() -> void:
	if curtain_layer != null: return
	curtain_layer = CanvasLayer.new()
	curtain_layer.name = "ExitCurtain"
	curtain_layer.layer = 50 # over the run's top-level views and the Clubhouse
	add_child(curtain_layer)
	curtain = ColorRect.new()
	curtain.name = "Curtain"
	curtain.color = Color(0.02, 0.02, 0.05, 0.0)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain_layer.add_child(curtain)

func _show_menu() -> void:
	_end_tutorial()
	if not _awaiting_title: # under the title at start-up the menu is built, not yet seen
		_play_clubhouse_music()
	screen = "menu"
	session = {}
	details.text = "The lanes are waiting."
	_clear_lab()
	_refresh_career_line()
	# League access from the unlock graph: a locked League is shown but cannot be entered.
	enter.disabled = false
	var played := int(career.records.get(career_graph.get("league_of_set", {}).get(league_sets[league.selected], ""), {}).get("attempts", 0)) > 0
	enter.text = "New Run" if played else "Enter League" # design §16 button words
	for i in league.item_count:
		var reason := UnlockGraph.league_access(career_graph, career, career_graph.get("league_of_set", {}).get(league_sets[i], ""))
		league.set_item_disabled(i, not reason.is_empty())
		if i == league.selected and not reason.is_empty():
			details.text = reason
			enter.disabled = true
	_refresh_kits()
	var saved := _saved_attempt()
	continue_button.visible = saved.ok
	if saved.ok:
		continue_button.text = "Continue Run %d · match %d" % [int(saved.payload.attempt), int(saved.payload.lab.match_number)]
	var notes: Array = [save_notice, saved.get("notice", "")].filter(func(n): return not n.is_empty())
	notice.text = "\n".join(notes)
	notice.visible = not notice.text.is_empty() # UI-9: no empty gap under the action
	save_notice = ""
	clubhouse.career = career
	clubhouse.league_sets = league_sets
	clubhouse.show()
	clubhouse.show_tab("board")
	session_menu.hide()
	menu_button.hide()
	club_menu_button.show()
	# UI-9: the action to take is the brass one: Continue when an attempt is saved.
	Clubhouse.primary_style(continue_button if saved.ok else enter)
	Clubhouse.secondary_style(enter if saved.ok else continue_button)
	for action in [continue_button, enter]:
		action.custom_minimum_size.y = 68 if action == (continue_button if saved.ok else enter) else 56
	details.add_theme_color_override("font_color", Color("9aa8a6") if details.text == "The lanes are waiting." else Color(1.0, 0.75, 0.5))
	(continue_button if saved.ok else enter).grab_focus()

## E22-L01: the League's kits; one that waits for a gate (the Tournament Kit, the
## House title) is listed but disabled until the Career has earned it.
func _refresh_kits() -> void:
	var chosen: int = maxi(kit.selected, 0)
	kit.clear()
	var kits: Array = content.get("kits", [content.kit])
	for i in kits.size():
		var entry: Dictionary = kits[i]
		var open := _kit_open(entry)
		kit.add_item(entry.get("name", "House Kit") + ("" if open else " · win the House League title"))
		kit.set_item_disabled(i, not open)
	kit.select(chosen if chosen < kits.size() and not kit.is_item_disabled(chosen) else 0)

func _kit_open(entry: Dictionary) -> bool:
	var unlock: String = str(entry.get("unlock", "initial"))
	return unlock == "initial" or unlock in career.get("unlocked", [])

func _chosen_kit() -> Dictionary:
	var kits: Array = content.get("kits", [content.kit])
	var index: int = kit.selected if kit.selected >= 0 and kit.selected < kits.size() else 0
	return kits[index] if _kit_open(kits[index]) else kits[0]

func _clear_lab() -> void:
	if lab:
		remove_child(lab)
		lab.free()
		lab = null
		_menu_page = ""
	UiTheme.use_kit("") # the shell and the Clubhouse are always the House kit
	if menu_button != null:
		menu_button.theme = null
		session_menu.theme = null
		_menu_sheet.add_theme_stylebox_override("panel", UiTheme.frame("menu", 20.0, 18.0))

## Preserve native reference typography in both orientations.
func _viewport_layout() -> void:
	var window := get_window()
	# UI-3 (owner phone trial, 2026-11-08): portrait lays out 540 wide, so every
	# label reads about a third larger on a phone; the screens are re-fitted for it.
	window.content_scale_size = Vector2i(1280,720) if window.size.x > window.size.y else Vector2i(540,960)
	_place_menu.call_deferred()
