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
## Career record (E09), saved apart from attempts since E10 (career.json); E15
## (ADR 010) adds the validated unlock graph, records and mastery. Restart and
## retry keep it.
var career: Dictionary = {}
var career_graph: Dictionary = {}
var career_line: Label # the full sentence (read by tools and tests); the tiles and bars show it
var career_stats: HBoxContainer
var career_goals: VBoxContainer
var _menu_sheet: PanelContainer
var league_sets: Array = [] # content set behind each League choice
## The Clubhouse (E16): the home screen; its League Board holds the panel below.
var clubhouse: Clubhouse
## E10 saves: user://saves, or --save-dir=<path> for tests.
var store: RefCounted
var continue_button: Button
var notice: Label
var save_notice := ""
## The content set every attempt this run plays (E13): the slice, or --content=lab.
var content: Dictionary = {}

func _ready() -> void:
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
	heading = Label.new()
	heading.text = "Roguewood"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 48)
	panel.add_child(heading)
	details = Label.new()
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	# The Career at a glance: four tiles, then each followed goal with its progress.
	career_stats = HBoxContainer.new()
	career_stats.name = "CareerStats"
	career_stats.add_theme_constant_override("separation", 8)
	panel.add_child(career_stats)
	career_goals = VBoxContainer.new()
	career_goals.name = "CareerGoals"
	career_goals.add_theme_constant_override("separation", 6)
	panel.add_child(career_goals)
	league = OptionButton.new()
	league.name = "LeagueChoice"
	league.add_item(content.get("name", "House League"))
	league_sets = [content.id]
	if content.id == "house":
		# E22-L02: the production board lists every live League, then the campaign.
		league.add_item(ContentSet.load_set("neon").get("name", "Neon League"))
		league_sets.append("neon")
	if content.id in ["house", "slice"]:
		league.add_item("House Campaign · 8 Divisions (provisional)")
		league_sets.append("campaign")
	if league_sets.size() > 1:
		league.item_selected.connect(func(index):
			content = ContentSet.load_set(league_sets[index])
			_show_menu())
	panel.add_child(league)
	kit = OptionButton.new()
	kit.name = "KitChoice"
	panel.add_child(kit)
	_refresh_kits()
	continue_button = _button(panel, "Continue Attempt", "ContinueAttempt", 460)
	continue_button.pressed.connect(_continue_attempt)
	enter = _button(panel, "Enter League", "EnterLeague", 460)
	notice = Label.new()
	notice.name = "SaveNotice"
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.custom_minimum_size = Vector2(460, 0)
	notice.add_theme_color_override("font_color", Color(1.0, 0.75, 0.5))
	panel.add_child(notice)
	var save_dir := "user://saves"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): save_dir = arg.trim_prefix("--save-dir=")
	store = SaveStore.create(save_dir)
	_load_career()
	clubhouse.graph = career_graph
	clubhouse.career_changed.connect(_save_career)
	_build_session_menu()
	resized.connect(_place_menu)
	_viewport_layout()
	enter.pressed.connect(_start_session)
	_show_menu()
	# E26-W01: browser QA status, only in a Web build opened with ?qa=1.
	if WebQA.requested():
		var qa := WebQA.new()
		qa.name = "WebQA"
		qa.shell = self
		add_child(qa)
	if "--bootstrap-smoke" in OS.get_cmdline_user_args():
		print("ROGUEWOOD_BOOT_OK")
		get_tree().quit(0)

func _button(parent: Node, label: String, node_name: String, width: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(width, 64)
	parent.add_child(button)
	return button

func _start_session() -> void:
	_begin_attempt(1)

## The menu button (three bars, drawn; Codex can supply an icon by asset later) and
## its sheet: a dimmed layer over the match with a short list of large entries.
func _build_session_menu() -> void:
	menu_button = Button.new()
	menu_button.name = "SessionMenu"
	menu_button.tooltip_text = "Menu"
	menu_button.draw.connect(func():
		var ink := UiTheme.IVORY
		var w := menu_button.size.x
		var h := menu_button.size.y
		for i in 3:
			var y := h * 0.5 + (i - 1) * 9.0
			menu_button.draw_rect(Rect2(w * 0.5 - 12.0, y - 2.0, 24.0, 4.0), ink))
	menu_button.pressed.connect(open_menu)
	menu_button.hide()
	add_child(menu_button)
	session_menu = Control.new()
	session_menu.name = "SessionMenuSheet"
	session_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session_menu.hide()
	add_child(session_menu)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.08, 0.72)
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
	resume = add_menu_entry("Resume", "ResumeSession", func(): pass)
	options = add_menu_entry("Options", "ThrowOptions", func(): if lab: lab.toggle_settings())
	back = add_menu_entry("Clubhouse", "BackToMenu", _show_menu)
	# Restart discards the attempt, so it asks once: the first press arms it.
	reset = add_menu_entry("Restart attempt", "ResetSession", func(): pass, false)
	reset.pressed.connect(func():
		if _restart_armed:
			close_menu()
			_start_session()
		else:
			_restart_armed = true
			reset.text = "Discard this attempt? Press again")

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
	reset.text = "Restart attempt"
	session_menu.show()
	if lab: lab.input_paused = true
	resume.grab_focus()

func close_menu() -> void:
	if not session_menu.visible: return
	session_menu.hide()
	if lab: lab.input_paused = false
	if menu_button.visible: menu_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if session_menu != null and session_menu.visible and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

## Beside the top bar, where MatchPanels leaves room for it.
func _place_menu() -> void:
	if menu_button == null: return
	var rect := MatchPanels.menu_rect(size)
	menu_button.position = rect.position
	menu_button.size = rect.size

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
	for tile in [[str(stats.rivals), "Rivals beaten"], [str(stats.titles), "Titles"], ["%d/%d" % [stats.mastered, stats.goals], "Mastery"], [str(stats.attempts), "Attempts"]]:
		career_stats.add_child(Clubhouse.stat_tile(tile[0], tile[1]))
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
		return {"ok": false, "notice": "The saved attempt no longer fits this version's content (%s); start a new attempt." % problems[0]}
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
## Attempt n of the content set's League (seed n). Restart Session begins
## attempt 1 again; Retry and New Attempt begin the next one.
## A saved payload resumes that attempt instead of starting fresh.
func _begin_attempt(attempt: int, saved: Dictionary = {}) -> void:
	if content.id == "campaign": content = ContentSet.load_set("campaign", int(saved.get("seed", attempt)))
	if saved.is_empty():
		content.kit = _chosen_kit()
	session = {"schema_version": 1, "seed": attempt, "attempt": attempt, "league_id": String(content.get("league_id", "league.house")) if content.id != "campaign" else "league.house", "kit_id": content.kit.get("id", "kit.house"),
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
	lab.attempt_finished.connect(func(outcome): session.outcome = outcome)
	lab.retry_requested.connect(func(): _begin_attempt(int(session.attempt) + 1), CONNECT_DEFERRED)
	lab.menu_requested.connect(_show_menu, CONNECT_DEFERRED)
	lab.frame_scored.connect(_on_frame_scored)
	lab.money_changed.connect(func(money): session.money = money)
	lab.chrome = [menu_button]
	add_child(lab)
	move_child(lab, 0)
	session_menu.hide()
	menu_button.show()
	_place_menu()
	menu_button.grab_focus()

## The session fixture tracks the lab's banked total and current frame.
func _on_frame_scored(scored: Dictionary) -> void:
	session.score = int(session.score) + int(scored.get("banked", scored.result.score))
	session.frame = int(scored.frame_number) + 1
	session.match = int(scored.get("match_number", session.match))
	if lab != null:
		session.division = lab.division.division_number()

func _show_menu() -> void:
	screen = "menu"
	session = {}
	details.text = "The lanes are waiting."
	_clear_lab()
	_refresh_career_line()
	# League access from the unlock graph: a locked League is shown but cannot be entered.
	enter.disabled = false
	var played := int(career.records.get(career_graph.get("league_of_set", {}).get(league_sets[league.selected], ""), {}).get("attempts", 0)) > 0
	enter.text = "Try Again" if played else "Enter League" # design §16 button words
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
		continue_button.text = "Continue Attempt %d · match %d" % [int(saved.payload.attempt), int(saved.payload.lab.match_number)]
	var notes: Array = [save_notice, saved.get("notice", "")].filter(func(n): return not n.is_empty())
	notice.text = "\n".join(notes)
	save_notice = ""
	clubhouse.career = career
	clubhouse.show()
	clubhouse.show_tab("board")
	session_menu.hide()
	menu_button.hide()
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
